/*-------------------------------------------------------------------------
 * pl_insert_exec.c
 *	INSERT EXECUTE implementation for Babelfish PL/tsql
 *	It implements:
 *	- Temp table lifecycle: creation, flush, and drop
 *	- Dest Receiver callback functions implementation
 *	- InsertExecContext: global state tracking for an active INSERT EXEC
 *-------------------------------------------------------------------------
 */

/* Include pltsql.h first to define types used by pltsql-2.h */
#include "pltsql.h"
#include "pltsql-2.h"

#include "funcapi.h"

#include "access/parallel.h"
#include "access/table.h"
#include "access/heapam.h"
#include "parser/parser.h"
#include "access/tableam.h"
#include "access/attmap.h"
#include "access/tupconvert.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_attribute.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_proc.h"
#include "commands/defrem.h"
#include "executor/executor.h"
#include "executor/spi_priv.h"
#include "executor/tstoreReceiver.h"
#include "executor/tuptable.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/parsenodes.h"
#include "optimizer/optimizer.h"
#include "parser/parse_coerce.h"
#include "parser/scansup.h"
#include "parser/parse_oper.h"
#include "tcop/dest.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "storage/lmgr.h"

#include "catalog.h"
#include "multidb.h"
#include "pltsql_permissions.h"
#include "session.h"

/*
 * DestReceiver struct for INSERT EXEC - captures procedure output into a temp table.
 */
typedef struct
{
	DestReceiver pub;			/* public fields */
	/* Projection infrastructure — coerce_to_target_type is a no-op when types already match */
	ExprContext *econtext;		/* expression context for projection */
	ProjectionInfo *proj_info;	/* projection info for coercion */
	TupleTableSlot *proj_slot;	/* result slot for projection */
	/*
	 * temp_rel and cid removed: rows now go directly into
	 * insert_exec_ctx->row_buffer (a TopMemoryContext tuplestore) which
	 * survives transaction aborts, making TRY/CATCH-inside-EXEC safe.
	 */
} DR_insertexec;

/* Forward declarations for DestReceiver callbacks */
static void insertexec_startup(DestReceiver *self, int operation, TupleDesc typeinfo);
static bool insertexec_receive(TupleTableSlot *slot, DestReceiver *self);
static void insertexec_shutdown(DestReceiver *self);
static void insertexec_destroy(DestReceiver *self);

/*
 * Global INSERT EXEC context pointer - defined in pltsql.h, declared here.
 */
InsertExecContext *insert_exec_ctx = NULL;
PLtsql_execstate *insert_exec_flush_estate = NULL;
/*
 * The flush INSERT is routed through execute_batch (the top-level batch entry
 * point). It runs through the same econtext setup as a normal T-SQL batch.
 */
extern int	execute_batch(PLtsql_execstate *estate, char *batch, InlineCodeBlockArgs *args, List *params);
extern InlineCodeBlockArgs *create_args(int numargs);

/*
 * Build a comma-separated list of quoted column identifiers from the parser's
 * List of column-name strings, for use in the temp table CREATE and the flush
 * INSERT. Returns NULL (no explicit column list) when columns is NIL. The
 * caller is responsible for pfree'ing the returned string.
 */
static char *
build_quoted_column_list(List *columns)
{
	StringInfoData	cols;
	ListCell	   *lc;
	bool			first = true;

	if (columns == NIL)
		return NULL;

	initStringInfo(&cols);
	foreach(lc, columns)
	{
		if (!first)
			appendStringInfoString(&cols, ", ");
		first = false;
		appendStringInfoString(&cols, quote_identifier((char *) lfirst(lc)));
	}
	return cols.data;
}

/*
 * Resolve the logical T-SQL schema name for an INSERT EXEC target when the
 * statement did not qualify it.
 */
static char *
resolve_insert_exec_schema_name(const char *schema_name_in, const char *db_name_in)
{
	const char *db;
	char	   *user;
	char	   *default_schema;
	char	   *result;

	if (schema_name_in != NULL)
		return pstrdup(schema_name_in);

	db = (db_name_in != NULL) ? db_name_in : get_cur_db_name();
	user = get_user_for_database(db);
	default_schema = user ? get_authid_user_ext_schema_name(db, user) : NULL;

	result = pstrdup(default_schema ? default_schema : "dbo");

	if (default_schema)
		pfree(default_schema);
	if (user)
		pfree(user);

	return result;
}

/*
 * Get a comma-separated list of non-IDENTITY, non-computed column names
 * for a table by opening the relation and iterating over its tuple descriptor.
 */
static char *
get_insertable_column_list(const char *table_name, const char *physical_schema)
{
	StringInfoData col_list;
	Oid			relid;
	Relation	rel;
	TupleDesc	tupdesc;
	int			i;
	bool		first_col = true;
	char		*lower_table_name;
	RangeVar	*rv;

	initStringInfo(&col_list);

	lower_table_name = downcase_identifier(table_name, strlen(table_name), false, false);

	/* Resolve the relation OID using RangeVar - works for both regular and temp tables */
	rv = makeRangeVar(physical_schema ? pstrdup(physical_schema) : NULL,
					  pstrdup(lower_table_name), -1);
	relid = RangeVarGetRelid(rv, NoLock, true);

	pfree(lower_table_name);

	if (!OidIsValid(relid))
		elog(ERROR, "INSERT EXEC failed due to missing relation for target table \"%s\"",
			table_name);

	/* Open the relation */
	rel = table_open(relid, AccessShareLock);
	tupdesc = RelationGetDescr(rel);

	/* Iterate over columns and build the list */
	for (i = 0; i < tupdesc->natts; i++)
	{
		Form_pg_attribute attr = TupleDescAttr(tupdesc, i);

		/* Skip dropped columns */
		if (attr->attisdropped)
			continue;

		/* Skip identity columns */
		if (attr->attidentity != '\0')
			continue;

		/* Skip generated/computed columns */
		if (attr->attgenerated != '\0')
			continue;

		/* Add column name to the list */
		if (!first_col)
			appendStringInfoString(&col_list, ", ");
		appendStringInfoString(&col_list, quote_identifier(NameStr(attr->attname)));
		first_col = false;
	}

	/* release the lock acquired by RangeVarGetRelid */
	table_close(rel, AccessShareLock);

	/* Error if no insertable columns found */
	if (first_col)
	{
		pfree(col_list.data);
		elog(ERROR, "INSERT EXEC failed due to no insertable columns in target table \"%s\"",
			table_name);
	}

	return col_list.data;
}



/*
 * Set the global INSERT EXEC context with target table info.
 * This is called BEFORE temp table creation - just stores the target info.
 */
void
pltsql_set_insert_exec_context_info(const char *target_table)
{
	Assert(insert_exec_ctx == NULL);
	insert_exec_ctx = MemoryContextAllocZero(TopMemoryContext,
											 sizeof(InsertExecContext));

	insert_exec_ctx->target_table = target_table
		? MemoryContextStrdup(TopMemoryContext, target_table)
		: NULL;
	/*
	 * Snapshot the call stack entry at INSERT EXEC start. Comparing this
	 * pointer later tells us whether an error occurred at the INSERT EXEC
	 * level or inside the executed procedure.
	 */
	insert_exec_ctx->call_stack_entry = exec_state_call_stack;
	/*
	 * Snapshot the transaction nesting depth so the COMMIT/ROLLBACK guard in
	 * error_if_xact_stmt_blocked_by_insert_exec can correctly detect whether a
	 * BEGIN TRANSACTION was issued inside the INSERT EXEC body (rather than
	 * hard-coding the threshold of 1, which breaks the dynamic-SQL path where
	 * no implicit transaction is started before entry).
	 */
	insert_exec_ctx->nested_tran_count_at_start = NestedTranCount;
}

/*
 * Reset the global INSERT EXEC context to a clean state.
 * Frees the row buffer and cached TupleDesc before releasing the struct.
 */
void
pltsql_insert_exec_reset_all(void)
{
	InsertExecContext *ctx = insert_exec_ctx;

	if (ctx == NULL)
		return;

	insert_exec_ctx = NULL;

	if (ctx->target_table)
		pfree(ctx->target_table);

	/* Release the cross-transaction row buffer and its cached schema. */
	if (ctx->row_buffer)
		tuplestore_end(ctx->row_buffer);

	if (ctx->buf_tupdesc)
		FreeTupleDesc(ctx->buf_tupdesc);

	pfree(ctx);
}

/*
 * Capture target table OID for change detection
 */
void
pltsql_insert_exec_open_target_table(const char *target_table,
									 const char *schema_name_in,
									 const char *db_name_in)
{
	RangeVar		*rv;
	Oid				relid;
	char			*schema_name = NULL;
	char			*table_name = NULL;
	char			*physical_schema = NULL;
	char			*db = NULL;

	if (target_table == NULL)
		return;

	table_name = pstrdup(target_table);
	db = (db_name_in != NULL) ? pstrdup(db_name_in) : get_cur_db_name();
	if (db != NULL && db[0] != '\0')
	{
		schema_name = resolve_insert_exec_schema_name(schema_name_in, db);
		physical_schema = get_physical_schema_name(db, schema_name);
	}
	if (db != NULL)
		pfree(db);

	/* Create RangeVar and get the relation OID */
	rv = makeRangeVar(physical_schema, table_name, -1);
	relid = RangeVarGetRelid(rv, NoLock, true);

	if (schema_name)
		pfree(schema_name);
	if (table_name)
		pfree(table_name);
	if (physical_schema)
		pfree(physical_schema);

	if (!OidIsValid(relid))
	{
		/* Table doesn't exist - will be caught later during flush */
		return;
	}

	insert_exec_ctx->target_rel_oid = relid;

	/* Initialize the modification flag to false */
	insert_exec_ctx->is_target_relation_modified = false;
}

/*
 * Validate column count from query string BEFORE plan preparation
 */
void
pltsql_insert_exec_validate_column_count(PLtsql_execstate *estate, PLtsql_stmt_execsql *stmt)
{
	PLtsql_expr	   *expr = stmt->sqlstmt;
	SPIPlanPtr		plan;
	List		   *plansources;
	CachedPlanSource *plansource;
	TupleDesc		result_desc;
	int				query_natts;
	int				temp_natts;

	/* Caller must ensure INSERT EXEC is active before calling */
	Assert(pltsql_insert_exec_active());

	/*
	 * Use the cached TupleDesc (TopMemoryContext) instead of opening the
	 * staging temp table -- the table may have been destroyed by a
	 * TRY/CATCH abort, but buf_tupdesc always reflects the column layout.
	 */
	if (insert_exec_ctx->buf_tupdesc == NULL)
		return;

	temp_natts = insert_exec_ctx->buf_tupdesc->natts;

	if (expr == NULL || expr->query == NULL)
		return;

	/*
	 * Parse-analyze the statement just to read its result shape.
	 */
	expr->func = estate->func;
	plan = SPI_prepare_params(expr->query,
							  (ParserSetupHook) pltsql_parser_setup,
							  (void *) expr,
							  CURSOR_OPT_PARALLEL_OK);
	if (plan == NULL)
		return;

	plansources = SPI_plan_get_plan_sources(plan);

	/* Expect exactly one analyzed statement with a known result shape */
	if (list_length(plansources) != 1)
	{
		SPI_freeplan(plan);
		return;
	}

	plansource = (CachedPlanSource *) linitial(plansources);
	result_desc = plansource->resultDesc;

	if (result_desc == NULL)
	{
		SPI_freeplan(plan);
		return;
	}

	query_natts = result_desc->natts;

	/* Done reading the shape; drop the throwaway plan. */
	SPI_freeplan(plan);

	/* Column count mismatch: raise before execution so it wins over 1/0 etc. */
	if (query_natts != temp_natts)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("structure of query does not match function result type")));
}

/*
 * Check if INSERT EXEC context is active (target table info is set).
 * This returns true even before temp table is created.
 */
bool
pltsql_insert_exec_active(void)
{
	return (insert_exec_ctx != NULL);
}

/*
 * Called from the sigsetjmp handler when a TRY-CATCH catches an error during
 * INSERT EXEC. Returns true if the error surfaced at the INSERT EXEC level
 * false if the catching TRY-CATCH is deeper inside the executed procedure
 */
bool
pltsql_insert_exec_error_at_trycatch_level(void)
{
	if (insert_exec_ctx == NULL)
		return false;

	/*
	 * Same call-stack head as when INSERT EXEC started → error is at the
	 * INSERT EXEC level. A deeper node → error is inside the called procedure.
	 */
	return exec_state_call_stack == insert_exec_ctx->call_stack_entry;
}

/*
 * Create a temp table for INSERT EXEC buffering.
 *
 * Creates a PostgreSQL temp table with schema matching the target table.
 * Uses ChooseRelationName to generate a unique name and ON COMMIT DROP
 * for automatic cleanup. Column types are inferred from the target table
 * via SELECT ... WITH NO DATA. The caller must have SELECT permission on
 * the target table for this to succeed.
 */
Oid
create_insert_exec_temp_table(const char *target_table, const char *column_list, const char *schema_name_in, const char *db_name_in)
{
	StringInfoData create_stmt;
	int			rc;
	Oid			temp_table_oid;
	char		*temp_table_name;
	char		*physical_schema = NULL;
	Oid			temp_nsp_oid;
	const char	*select_cols;
	char		*cols_to_free = NULL;
	char		*qualified_target;

	/*
	 * Generate a unique temp table name using ChooseRelationName.
	 */
	temp_nsp_oid = LookupNamespaceNoError("pg_temp");

	temp_table_name = ChooseRelationName("__insert_exec_buf", NULL, "tmp",
										 temp_nsp_oid, false);

	/*
	 * Resolve the physical schema for the target table reference.
	 *
	 * Three cases per T-SQL semantics:
	 *	1. Temp table (#) — always in pg_temp
	 *	2. Schema explicitly specified — resolve to physical schema name
	 *	3. No schema specified — leave NULL, let search_path handle resolution
	 */
	if (!(target_table[0] == '#' || target_table[0] == '@'))
	{
		char *db = (db_name_in != NULL) ? pstrdup(db_name_in) : get_cur_db_name();
		/*
		 * On the PostgreSQL endpoint a T-SQL procedure runs without logical
		 * database context (fn_dbid is InvalidDbid for non-TDS connections),
		 * so the current database name can be empty. With no DB context, leave
		 * physical_schema NULL and reference the target by its bare name, so
		 * search_path resolves it - exactly as a plain INSERT does.
		 */
		if (db != NULL && db[0] != '\0')
		{
			char *sname = resolve_insert_exec_schema_name(schema_name_in, db);
			physical_schema = get_physical_schema_name(db, sname);
			pfree(sname);
			if (physical_schema == NULL)
				elog(ERROR, "INSERT EXEC failed due to unresolvable schema for target table \"%s\"",
					target_table);
		}
		if (db != NULL)
			pfree(db);
	}

	/*
	 * Determine the column list to SELECT.
	 *
	 * If the user specified columns, use them directly.
	 * Otherwise, query the relation to get all non-IDENTITY,
	 * non-computed column names.
	 */
	if (column_list != NULL)
		select_cols = column_list;
	else
		select_cols = cols_to_free = get_insertable_column_list(target_table, physical_schema);


	/*
	 * Build a fully qualified reference for the source table.
	 */
	qualified_target = quote_qualified_identifier(physical_schema, target_table);

	/*
	 * Create the temp buffer table by selecting the desired columns
	 * with no rows. PostgreSQL infers column types from the SELECT.
	 *
	 * We use ON COMMIT PRESERVE ROWS (not ON COMMIT DROP) because the
	 * implicit transaction started by insert_exec_setup may be committed
	 * inside the inner batch (e.g. PLTsqlCommitTransaction between
	 * statements). ON COMMIT DROP would fire at that point and silently
	 * destroy the buffer table before flush_insert_exec_temp_table has a
	 * chance to read it. The table is instead dropped explicitly in
	 * insert_exec_flush_and_cleanup after the flush completes.
	 *
	 * This CREATE TABLE goes through heap_create_with_catalog, which takes
	 * AccessExclusiveLock on the new relation and holds it until end of transaction.
	 */
	initStringInfo(&create_stmt);
	appendStringInfo(&create_stmt,
		"CREATE TEMP TABLE %s ON COMMIT PRESERVE ROWS AS SELECT %s FROM %s WITH NO DATA",
		quote_identifier(temp_table_name), select_cols, qualified_target);

	if (cols_to_free)
		pfree(cols_to_free);
	pfree(qualified_target);

	/* Clean up parsed names */
	if (physical_schema)
		pfree(physical_schema);

	rc = SPI_execute(create_stmt.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		elog(ERROR, "INSERT EXEC failed due to temp table creation error: %s",
			 SPI_result_code_string(rc));

	pfree(create_stmt.data);

	/* Get the OID of the created temp table */
	temp_table_oid = RelnameGetRelid(temp_table_name);
	if (!OidIsValid(temp_table_oid))
		elog(ERROR, "INSERT EXEC failed due to missing temp table \"%s\"", temp_table_name);

	return temp_table_oid;
}

/*
 * Flush data from temp table to target table.
 *
 * Executes INSERT INTO target SELECT * FROM temp_table.
 * Uses SPI_execute for the flush INSERT.
 * The flush is called while still inside the procedure's execution context.
 */
static void
flush_insert_exec_temp_table(PLtsql_execstate *estate, const char *target_schema,
							 const char *target_db, const char *column_list_str)
{
	StringInfoData	flush_query;
	int				rc;
	Oid				temp_oid;
	const char	   *target_table;
	const char	   *temp_name;
	Relation		temp_rel;
	char		   *qualified_target;
	InlineCodeBlockArgs	*flush_args;

	if (insert_exec_ctx == NULL)
		return;

	temp_oid = insert_exec_ctx->temp_table_oid;
	target_table = insert_exec_ctx->target_table;

	if (!OidIsValid(temp_oid) || target_table == NULL)
		return;

	if (insert_exec_ctx->is_target_relation_modified)
		ereport(ERROR,
				(errcode(ERRCODE_OBJECT_IN_USE),
				 errmsg("cannot %s \"%s\" because it is being used by active queries in this session",
						"DROP TABLE", target_table)));

	/*
	 * Get the temp table name from its OID. Reference it by bare (unqualified)
	 * name and let search_path resolve it - the physical temp namespace name
	 * (e.g. pg_temp_0) is not resolvable as a schema under the T-SQL dialect.
	 */
	temp_rel = table_open(temp_oid, NoLock);
	temp_name = quote_identifier(pstrdup(RelationGetRelationName(temp_rel)));
	table_close(temp_rel, NoLock);

	initStringInfo(&flush_query);

	/*
	 * For a cross-DB target (db..table), build the logical T-SQL name
	 * (db.schema.table) and let Babelfish's normal cross-DB name rewriting
	 * resolve it - the same path a plain "INSERT INTO db..table" takes.
	 * Resolving the physical schema ourselves does not work because the
	 * physical schema of another logical database is not visible as an
	 * INSERT target under the T-SQL dialect. Same-DB targets are schema-
	 * qualified (the caller always resolves the schema) so the flush does not
	 * depend on search_path. Temp tables/table variables have no schema and
	 * are referenced by bare name (resolved via the session temp namespace).
	 */
	if (target_db != NULL)
		qualified_target = psprintf("%s.%s.%s",
									quote_identifier(target_db),
									quote_identifier(target_schema ? target_schema : "dbo"),
									quote_identifier(target_table));
	else if (target_schema != NULL)
		qualified_target = psprintf("%s.%s",
									quote_identifier(target_schema),
									quote_identifier(target_table));
	else
		qualified_target = pstrdup(quote_identifier(target_table));

	appendStringInfo(&flush_query,
		"INSERT INTO %s%s SELECT * FROM %s",
		qualified_target,
		column_list_str ? psprintf(" (%s)", column_list_str) : "",
		temp_name);

	pfree(qualified_target);

	/*
	 * Run the flush through execute_batch, publishing the caller's estate via
	 * insert_exec_flush_estate for the duration so the inline handler's own
	 * empty estate does not shadow it.
	 */
	flush_args = create_args(0);

	if (insert_exec_flush_estate != NULL)
		elog(ERROR, "insert_exec_flush_estate is already set; INSERT EXEC flush must not nest");

	insert_exec_flush_estate = estate;
	PG_TRY();
	{
		rc = execute_batch(estate, flush_query.data, flush_args, NULL);
	}
	PG_CATCH();
	{
		insert_exec_flush_estate = NULL;
		PG_RE_THROW();
	}
	PG_END_TRY();
	insert_exec_flush_estate = NULL;

	pfree(flush_query.data);

	if (rc != PLTSQL_RC_OK)
		elog(ERROR, "INSERT EXEC failed due to error while flushing temp table to target table");

	/*
	 * Report rows-affected from the DestReceiver's captured-row count
	 */
	estate->eval_processed = insert_exec_ctx->rows_processed;
}

/*
 * Create a DestReceiver for INSERT EXEC that writes to a temp table.
 */
DestReceiver *
CreateInsertExecDestReceiver(void)
{
	DR_insertexec *self = palloc0_object(DR_insertexec);

	self->pub.receiveSlot = insertexec_receive;
	self->pub.rStartup = insertexec_startup;
	self->pub.rShutdown = insertexec_shutdown;
	self->pub.rDestroy = insertexec_destroy;

	return (DestReceiver *) self;
}

/*
 * insertexec_startup - executor startup for INSERT EXEC receiver
 *
 * Validates column count and builds coercion expressions for type
 * conversion using PostgreSQL's ExecBuildProjectionInfo/ExecProject.
 * Uses insert_exec_ctx->buf_tupdesc (a TopMemoryContext copy) so startup
 * works after a TRY/CATCH abort destroyed the original staging temp table.
 */
static void
insertexec_startup(DestReceiver *self, int operation, TupleDesc typeinfo)
{
	DR_insertexec *myState = (DR_insertexec *) self;
	TupleDesc	temp_tupdesc;
	TupleDesc	proj_tupdesc;
	int			result_natts;
	int			temp_natts;
	int			i;
	List	   *target_list = NIL;

	/*
	 * Validate column count against the cached TupleDesc. This descriptor
	 * was copied to TopMemoryContext in insert_exec_setup so it survives any
	 * transaction abort that may have dropped the original staging table.
	 */
	result_natts = typeinfo->natts;

	if (insert_exec_ctx->buf_tupdesc == NULL)
		elog(ERROR, "INSERT EXEC failed due to missing buffer descriptor");

	temp_tupdesc = insert_exec_ctx->buf_tupdesc;
	temp_natts = temp_tupdesc->natts;

	if (result_natts != temp_natts)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("structure of query does not match function result type")));
	}

	for (i = 0; i < temp_natts; i++)
	{
		Form_pg_attribute src_att = TupleDescAttr(typeinfo, i);
		Form_pg_attribute tgt_att = TupleDescAttr(temp_tupdesc, i);
		Var		   *var;
		Node	   *expr;
		TargetEntry *tle;

		/* Create Var node referencing input tuple column (OUTER_VAR for ecxt_outertuple) */
		var = makeVar(OUTER_VAR,
					  i + 1,				/* attnum is 1-based */
					  src_att->atttypid,
					  src_att->atttypmod,
					  src_att->attcollation,
					  0);					/* varlevelsup */

		/*
		 * coerce_to_target_type returns the Var unchanged when types match,
		 * so we call it unconditionally.
		 */
		expr = coerce_to_target_type(NULL,
									 (Node *) var,
									 src_att->atttypid,
									 tgt_att->atttypid,
									 tgt_att->atttypmod,
									 COERCION_ASSIGNMENT,
									 COERCE_IMPLICIT_CAST,
									 -1);

		if (expr == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_CANNOT_COERCE),
					 errmsg("cannot convert type %s to %s",
							format_type_be(src_att->atttypid),
							format_type_be(tgt_att->atttypid))));


		/* Create TargetEntry for this column */
		tle = makeTargetEntry((Expr *) expr,
							  i + 1,		/* resno is 1-based */
							  NULL,			/* resname */
							  false);		/* resjunk */
		target_list = lappend(target_list, tle);
	}

	/*
	 * Copy the cached descriptor for the projection result slot.
	 */
	proj_tupdesc = CreateTupleDescCopy(temp_tupdesc);

	/* Create expression context and projection info */
	myState->econtext = CreateStandaloneExprContext();
	myState->proj_slot = MakeSingleTupleTableSlot(proj_tupdesc, &TTSOpsVirtual);

	/* Build the projection info */
	myState->proj_info = ExecBuildProjectionInfo(target_list,
												 myState->econtext,
												 myState->proj_slot,
												 NULL,		/* no parent PlanState */
												 typeinfo);	/* input descriptor */
}

/*
 * insertexec_receive - receive each tuple and store in the tuplestore row buffer.
 *
 * Rows are written to insert_exec_ctx->row_buffer (a Tuplestorestate in
 * TopMemoryContext with interXact=true).  This buffer survives both savepoint
 * rollbacks and full transaction aborts, so TRY/CATCH inside EXEC(@sql) no
 * longer loses rows written before the error, and the CATCH block can still
 * route its output here even after the transaction was reset.
 */
static bool
insertexec_receive(TupleTableSlot *slot, DestReceiver *self)
{
	DR_insertexec *myState = (DR_insertexec *) self;
	TupleTableSlot *insert_slot;

	Assert(myState->proj_info != NULL);
	Assert(myState->econtext != NULL);

	/* Reset per-tuple memory context for expression evaluation */
	ResetExprContext(myState->econtext);

	/* Set up the input slot for projection */
	myState->econtext->ecxt_outertuple = slot;

	/* Project tuple with type coercion */
	insert_slot = ExecProject(myState->proj_info);

	/*
	 * Store the projected tuple in the cross-transaction row buffer.
	 * tuplestore_puttupleslot copies the tuple into TopMemoryContext (the
	 * context the tuplestore was created in) so the data survives any
	 * subsequent transaction abort inside the executed procedure.
	 */
	tuplestore_puttupleslot(insert_exec_ctx->row_buffer, insert_slot);

	/* INSERT EXEC rows-affected count */
	insert_exec_ctx->rows_processed++;

	return true;
}

/*
 * insertexec_shutdown - executor end for INSERT EXEC receiver.
 *
 * Frees the expression context and projection slot.  The row buffer
 * (tuplestore) is owned by InsertExecContext and outlives the receiver.
 */
static void
insertexec_shutdown(DestReceiver *self)
{
	DR_insertexec *myState = (DR_insertexec *) self;

	Assert(myState->proj_slot != NULL);
	ExecDropSingleTupleTableSlot(myState->proj_slot);
	myState->proj_slot = NULL;

	Assert(myState->econtext != NULL);
	FreeExprContext(myState->econtext, true);
	myState->econtext = NULL;
}

/*
 * insertexec_destroy - release DestReceiver object
 */
static void
insertexec_destroy(DestReceiver *self)
{
	pfree(self);
}

/*
 * insert_exec_setup - set up INSERT EXEC context and create the
 * buffering temp table from parser-provided info. Returns false (no-op) when
 * there is no INSERT EXEC info; otherwise sets up context, optionally starts
 * an implicit transaction (stored procedure calls only).
 */
bool
insert_exec_setup(PLtsql_execstate *estate,
							 InsertExecInfo *info,
							 bool start_implicit_txn)
{
	char	   *column_list = NULL;

	if (info == NULL || info->target == NULL)
		return false;

	/* Check for nested INSERT EXEC */
	if (pltsql_insert_exec_active())
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("nested INSERT ... EXECUTE statements are not allowed")));

	/*
	 * T-SQL does not allow INSERT EXEC inside a function. The parser blocks
	 * the common cases at CREATE FUNCTION time; this catches anything that
	 * still reaches runtime (e.g. a table-variable target).
	 */
	if (estate->func &&
		estate->func->fn_oid != InvalidOid &&
		estate->func->fn_prokind == PROKIND_FUNCTION &&
		estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
				 errmsg("'INSERT EXEC' cannot be used within a function")));

	/* Build the quoted column list (if any) for temp table creation */
	column_list = build_quoted_column_list(info->columns);

	/*
	 * Start implicit transaction for INSERT EXEC if requested and not already in one.
	 * This is used for stored procedure calls (exec_stmt_exec) but not for
	 * dynamic SQL (exec_stmt_exec_batch) which has different transaction semantics.
	 */
	if (start_implicit_txn)
	{
		if (!pltsql_disable_batch_auto_commit &&
			pltsql_support_tsql_transactions() &&
			!IsTransactionBlockActive())
		{
			elog(DEBUG4, "TSQL TXN Start internal transaction for INSERT EXEC");
			pltsql_start_txn();
			estate->tsql_trigger_flags |= TSQL_TRAN_STARTED;
		}
	}

	/* Record that INSERT EXEC is active (stores target name + call stack) */
	pltsql_set_insert_exec_context_info(info->target);

	/* Hold target table open to detect schema alterations during execution */
	pltsql_insert_exec_open_target_table(info->target, info->schema, info->db_name);

	/* Create staging temp table whose schema matches the target's column list */
	insert_exec_ctx->temp_table_oid = create_insert_exec_temp_table(info->target, column_list,
												   info->schema, info->db_name);

	/*
	 * Copy the staging table TupleDesc to TopMemoryContext and create a
	 * cross-transaction row buffer (tuplestore) there.  Both survive
	 * AbortCurrentTransaction() so TRY/CATCH inside the executed batch
	 * cannot lose buffered rows or prevent the CATCH block from routing
	 * its output back to DR_insertexec.
	 */
	{
		Relation		temp_rel;
		MemoryContext	old_ctx;

		old_ctx = MemoryContextSwitchTo(TopMemoryContext);

		/* interXact=true: survives transaction boundaries */
		insert_exec_ctx->row_buffer =
			tuplestore_begin_heap(false, true, work_mem);

		/* Cache column layout so insertexec_startup needs no open relation */
		temp_rel = table_open(insert_exec_ctx->temp_table_oid, NoLock);
		insert_exec_ctx->buf_tupdesc =
			CreateTupleDescCopy(RelationGetDescr(temp_rel));
		table_close(temp_rel, NoLock);

		MemoryContextSwitchTo(old_ctx);
	}

	if (column_list != NULL)
		pfree(column_list);

	return true;
}

/*
 * populate_staging_table_from_tuplestore
 *
 * Write all rows from the cross-transaction row buffer into the staging
 * temp table so flush_insert_exec_temp_table can SELECT from it. If the
 * original staging table was destroyed by a TRY/CATCH transaction abort
 * it is transparently re-created from the same target schema first.
 */
static void
populate_staging_table_from_tuplestore(const char *target_table,
										  const char *column_list,
										  const char *schema_name_in,
										  const char *db_name_in)
{
	Tuplestorestate *tuplestore = insert_exec_ctx->row_buffer;
	Relation		staging_rel;
	TupleTableSlot *slot;
	CommandId		cid;
	char		   *tname;

	if (tuplestore == NULL || insert_exec_ctx->buf_tupdesc == NULL)
		return;						/* nothing buffered */

	/*
	 * If the staging table was rolled back by a TRY/CATCH abort, re-create
	 * it now. get_rel_name returns NULL when the OID is no longer live.
	 */
	tname = OidIsValid(insert_exec_ctx->temp_table_oid)
		? get_rel_name(insert_exec_ctx->temp_table_oid)
		: NULL;

	if (tname == NULL)
		insert_exec_ctx->temp_table_oid =
			create_insert_exec_temp_table(target_table, column_list,
										   schema_name_in, db_name_in);

	/*
	 * Write buffered rows into the staging table via direct heap inserts.
	 * The tuplestore holds MinimalTuples already coerced to the target
	 * column layout by insertexec_receive, so no further coercion is needed.
	 */
	staging_rel = table_open(insert_exec_ctx->temp_table_oid, RowExclusiveLock);
	slot = MakeSingleTupleTableSlot(RelationGetDescr(staging_rel),
									 &TTSOpsMinimalTuple);
	cid = GetCurrentCommandId(true);

	tuplestore_rescan(tuplestore);
	while (tuplestore_gettupleslot(tuplestore, true, false, slot))
	{
		table_tuple_insert(staging_rel, slot, cid, 0, NULL);
		ExecClearTuple(slot);
	}

	ExecDropSingleTupleTableSlot(slot);
	table_close(staging_rel, RowExclusiveLock);

	/*
	 * Make the freshly inserted rows visible to the subsequent
	 * flush_insert_exec_temp_table query (runs as a new command).
	 */
	CommandCounterIncrement();
}

/*
 * insert_exec_flush_and_cleanup - flush buffered rows to the target table.
 *
 * 1. populate_staging_table_from_tuplestore transfers the row buffer into
 *    the staging temp table (re-creating it if a TRY/CATCH abort killed it).
 * 2. flush_insert_exec_temp_table runs INSERT INTO target SELECT * FROM staging.
 * 3. The staging table is dropped and the INSERT EXEC context freed.
 * 4. The implicit transaction (if any) is committed.
 */
void
insert_exec_flush_and_cleanup(PLtsql_execstate *estate, InsertExecInfo *info)
{
	char	   *column_list = build_quoted_column_list(info->columns);
	const char *flush_schema = (info->db_name != NULL || info->schema != NULL) ? info->schema : NULL;

	/*
	 * Transfer all buffered rows into the staging temp table.
	 * If the table was destroyed by a TRY/CATCH abort it is transparently
	 * re-created here from the same target schema.
	 */
	populate_staging_table_from_tuplestore(info->target, column_list,
											   info->schema, info->db_name);

	/* INSERT INTO target SELECT * FROM staging */
	flush_insert_exec_temp_table(estate, flush_schema, info->db_name, column_list);

	/*
	 * Drop the staging temp table.  Done before pltsql_insert_exec_reset_all()
	 * so insert_exec_ctx is still valid for the OID lookup.
	 */
	if (insert_exec_ctx != NULL && OidIsValid(insert_exec_ctx->temp_table_oid))
	{
		char	   *tname = get_rel_name(insert_exec_ctx->temp_table_oid);

		if (tname != NULL)
		{
			StringInfoData drop_q;

			initStringInfo(&drop_q);
			appendStringInfo(&drop_q, "DROP TABLE IF EXISTS %s",
							 quote_identifier(tname));
			SPI_execute(drop_q.data, false, 0);
			pfree(drop_q.data);
		}
	}

	if (column_list != NULL)
		pfree(column_list);

	/*
	 * Reset the context (frees tuplestore and buf_tupdesc). Done before the
	 * optional commit so a commit failure cannot leave a dangling context.
	 */
	pltsql_insert_exec_reset_all();

	/*
	 * Commit the implicit transaction that was started for INSERT EXEC.
	 * TSQL_TRAN_STARTED marks that insert_exec_setup() opened it.
	 */
	if (estate->tsql_trigger_flags & TSQL_TRAN_STARTED)
	{
		estate->tsql_trigger_flags &= ~TSQL_TRAN_STARTED;

		if (!pltsql_implicit_transactions)
			commit_stmt(estate, true);
	}
}
