/*-------------------------------------------------------------------------
 *
 * procedures.c
 *   Built-in Procedures for Babel
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/tupdesc.h"
#include "access/printtup.h"
#include "access/relation.h"
#include "access/table.h"
#include "access/xact.h"
#include "access/heapam.h"
#include "catalog/pg_type.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_foreign_server.h"
#include "catalog/indexing.h"
#include "commands/defrem.h"
#include "commands/prepare.h"
#include "common/string.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "funcapi.h"
#include "hooks.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/value.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/fmgroids.h"
#include "pltsql_instr.h"
#include "pltsql.h"
#include "parser/parser.h"
#include "parser/parse_relation.h"
#include "parser/parse_target.h"
#include "parser/parse_relation.h"
#include "parser/scansup.h"
#include "tcop/pquery.h"
#include "tcop/tcopprot.h"
#include "tcop/utility.h"
#include "tsearch/ts_locale.h"

#include "catalog.h"
#include "multidb.h"
#include "pltsql.h"
#include "session.h"
#include "pltsql.h"

PG_FUNCTION_INFO_V1(sp_unprepare);
PG_FUNCTION_INFO_V1(sp_prepare);
PG_FUNCTION_INFO_V1(sp_babelfish_configure);
PG_FUNCTION_INFO_V1(sp_describe_first_result_set_internal);
PG_FUNCTION_INFO_V1(sp_describe_undeclared_parameters_internal);
PG_FUNCTION_INFO_V1(xp_qv_internal);
PG_FUNCTION_INFO_V1(create_xp_qv_in_master_dbo_internal);
PG_FUNCTION_INFO_V1(xp_instance_regread_internal);
PG_FUNCTION_INFO_V1(create_xp_instance_regread_in_master_dbo_internal);
PG_FUNCTION_INFO_V1(sp_addrole);
PG_FUNCTION_INFO_V1(sp_droprole);
PG_FUNCTION_INFO_V1(sp_addrolemember);
PG_FUNCTION_INFO_V1(sp_droprolemember);
PG_FUNCTION_INFO_V1(sp_addlinkedserver_internal);
PG_FUNCTION_INFO_V1(sp_addlinkedsrvlogin_internal);
PG_FUNCTION_INFO_V1(sp_droplinkedsrvlogin_internal);
PG_FUNCTION_INFO_V1(sp_dropserver_internal);
PG_FUNCTION_INFO_V1(sp_serveroption_internal);
PG_FUNCTION_INFO_V1(sp_babelfish_volatility);
PG_FUNCTION_INFO_V1(sp_rename_internal);

extern void delete_cached_batch(int handle);
extern InlineCodeBlockArgs *create_args(int numargs);
extern void read_param_def(InlineCodeBlockArgs *args, const char *paramdefstr);
extern int	execute_batch(PLtsql_execstate *estate, char *batch, InlineCodeBlockArgs *args, List *params);
extern PLtsql_execstate *get_current_tsql_estate(void);
static List *gen_sp_addrole_subcmds(const char *user);
static List *gen_sp_droprole_subcmds(const char *user);
static List *gen_sp_addrolemember_subcmds(const char *user, const char *member);
static List *gen_sp_droprolemember_subcmds(const char *user, const char *member);
static List *gen_sp_rename_subcmds(const char *objname, const char *newname, const char *schemaname, ObjectType objtype, const char *curr_relname);
static void update_bbf_server_options(char *servername, char *optname, char *optvalue, bool isInsert);
static void clean_up_bbf_server_option(char *servername);
static void remove_delimited_identifer(char *str);

List	   *handle_bool_expr_rec(BoolExpr *expr, List *list);
List	   *handle_where_clause_attnums(ParseState *pstate, Node *w_clause, List *target_attnums);
List	   *handle_where_clause_restargets_left(ParseState *pstate, Node *w_clause, List *extra_restargets);
List	   *handle_where_clause_restargets_right(ParseState *pstate, Node *w_clause, List *extra_restargets);

char	   *sp_describe_first_result_set_view_name = NULL;

bool		sp_describe_first_result_set_inprogress = false;
char	   *orig_proc_funcname = NULL;

Datum
sp_unprepare(PG_FUNCTION_ARGS)
{
	int32_t		handle;

	TSQLInstrumentation(INSTR_TSQL_SP_UNPREPARE);
	if (PG_ARGISNULL(0))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("expect handle as integer")));

	handle = PG_GETARG_INT32(0);

	delete_cached_batch(handle);

	PG_RETURN_VOID();
}

Datum
sp_prepare(PG_FUNCTION_ARGS)
{
	char	   *params = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));
	char	   *batch = PG_ARGISNULL(2) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(2));

	/* int  options = PG_GETARG_INT32(3); */
	InlineCodeBlockArgs *args;
	HeapTuple	tuple;
	HeapTupleHeader result;
	TupleDesc	tupdesc;
	bool		isnull = false;
	Datum		values[1];
	const char *old_dialect;

	if (!batch)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
						errmsg("query argument of sp_prepare is null")));

	old_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);
	set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION,
					  GUC_ACTION_SAVE,
					  true,
					  0,
					  false);

	args = create_args(0);
	if (params)
		read_param_def(args, params);

	args->options = (BATCH_OPTION_CACHE_PLAN |
					 BATCH_OPTION_PREPARE_PLAN |
					 BATCH_OPTION_SEND_METADATA |
					 BATCH_OPTION_NO_EXEC);

	PG_TRY();
	{
		PLtsql_execstate *estate = get_current_tsql_estate();

		execute_batch(estate, batch, args, NULL);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", old_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION,
						  GUC_ACTION_SAVE,
						  true,
						  0,
						  false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	set_config_option("babelfishpg_tsql.sql_dialect", old_dialect,
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION,
					  GUC_ACTION_SAVE,
					  true,
					  0,
					  false);

	values[0] = Int32GetDatum(args->handle);

	/* 5. Return back handle */
	tupdesc = CreateTemplateTupleDesc(1);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "prep_handle", INT4OID, -1, 0);
	tupdesc = BlessTupleDesc(tupdesc);
	tuple = heap_form_tuple(tupdesc, values, &isnull);

	result = (HeapTupleHeader) palloc(tuple->t_len);

	memcpy(result, tuple->t_data, tuple->t_len);

	heap_freetuple(tuple);
	ReleaseTupleDesc(tupdesc);

	PG_RETURN_HEAPTUPLEHEADER(result);
}

Datum
sp_babelfish_configure(PG_FUNCTION_ARGS)
{
	int			rc;
	int			nargs;
	MemoryContext savedPortalCxt;

	/* SPI call input */
	const char *query = "SELECT name, setting, short_desc FROM sys.babelfish_configurations_view WHERE name like $1";
	Datum		arg;
	Oid			argoid = TEXTOID;
	char		nulls = 0;

	SPIPlanPtr	plan;
	Portal		portal;
	DestReceiver *receiver;

	nargs = PG_NARGS();
	if (nargs == 0)
	{
		arg = PointerGetDatum(cstring_to_text("%"));
	}
	else if (nargs == 1)
	{
		const char *common_prefix = "babelfishpg_tsql.";

		char	   *arg0 = PG_ARGISNULL(0) ? "%" : TextDatumGetCString(PG_GETARG_TEXT_PP(0));

		if (strncmp(arg0, common_prefix, strlen(common_prefix)) == 0)
			arg = PointerGetDatum(cstring_to_text(arg0));
		else
		{
			char		buf[1024];

			snprintf(buf, 1024, "%s%s", common_prefix, arg0);
			arg = PointerGetDatum(cstring_to_text(buf));
		}
	}
	else
	{
		elog(ERROR, "unexpected number of arguments: %d", nargs);
	}

	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	if ((plan = SPI_prepare(query, 1, &argoid)) == NULL)
		elog(ERROR, "SPI_prepare(\"%s\") failed", query);

	if ((portal = SPI_cursor_open(NULL, plan, &arg, &nulls, true)) == NULL)
		elog(ERROR, "SPI_cursor_open(\"%s\") failed", query);

	/*
	 * According to specifictation, sp_babelfish_configure returns a
	 * result-set. If there is no destination, it will send the result-set to
	 * client, which is not allowed behavior of PG procedures. To implement
	 * this behavior, we added a code to push the result.
	 */
	receiver = CreateDestReceiver(DestRemote);
	SetRemoteDestReceiverParams(receiver, portal);

	/* fetch the result and return the result-set */
	PortalRun(portal, FETCH_ALL, true, true, receiver, receiver, NULL);

	receiver->rDestroy(receiver);

	SPI_cursor_close(portal);

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	PG_RETURN_VOID();
}

/*
 * Structure used to store state in the SRF (Set-Returning-Function)
 * sp_describe_undeclared_parameters_internal
 */
typedef struct UndeclaredParams
{
	/* Names of the undeclared parameters */
	char	  **paramnames;

	/* Indexes of the undeclared parameters in the targetattnums array */
	int		   *paramindexes;

	/*
	 * The relevant attnums in the target table. For 'INSERT INTO t1 ...' it
	 * is all the attnums in the target table t1; for 'INSERT INTO t1 (a, c)
	 * ...' it is the attnums of columns a and c in the target table t1.
	 */
	int		   *targetattnums;

	/* The relevant colume names in the target table. */
	char	  **targetcolnames;

	/* Name of the target table */
	char	   *tablename;

	/* The Oid of the table's schema */
	Oid			schemaoid;
} UndeclaredParams;

static char *
sp_describe_first_result_set_query(char *viewName)
{
	return
		psprintf(
				 "SELECT "
				 "CAST(0 AS sys.bit) AS is_hidden, "
				 "CAST(t3.\"ORDINAL_POSITION\" AS int) AS column_ordinal, "
				 "CAST(t3.\"COLUMN_NAME\" AS sys.sysname) AS name, "
				 "case "
				 "when t1.is_nullable collate sys.database_default = \'YES\' AND t3.\"DATA_TYPE\" collate sys.database_default <> \'timestamp\' then CAST(1 AS sys.bit) "
				 "else CAST(0 AS sys.bit) "
				 "end as is_nullable, "
				 "t4.system_type_id::int as system_type_id, "
				 "CAST(t3.\"DATA_TYPE\" as sys.nvarchar(256)) as system_type_name, "
				 "CAST(CASE WHEN t3.\"DATA_TYPE\" collate sys.database_default IN (\'text\', \'ntext\', \'image\') THEN -1 ELSE t4.max_length END AS smallint) AS max_length, "
				 "CAST(t4.precision AS sys.tinyint) AS precision, "
				 "CAST(t4.scale AS sys.tinyint) AS scale, "
				 "CAST(t4.collation_name AS sys.sysname) as collation_name, "
				 "CAST(CASE WHEN t4.system_type_id = t4.user_type_id THEN NULL "
				 "ELSE t4.user_type_id END as int) as user_type_id, "
				 "CAST(NULL as sys.sysname) as user_type_database, "
				 "CAST(NULL as sys.sysname) as user_type_schema, "
				 "CAST(CASE WHEN t4.system_type_id = t4.user_type_id THEN NULL "
				 "ELSE sys.OBJECT_NAME(t4.user_type_id::int) END as sys.sysname) as user_type_name, "
				 "CAST(NULL as sys.nvarchar(4000)) as assembly_qualified_type_name, "
				 "CAST(NULL as int) as xml_collection_id, "
				 "CAST(NULL as sys.sysname) as xml_collection_database, "
				 "CAST(NULL as sys.sysname) as xml_collection_schema, "
				 "CAST(NULL as sys.sysname) as xml_collection_name, "
				 "case "
				 "when t3.\"DATA_TYPE\" collate sys.database_default = \'xml\' then CAST(1 AS sys.bit) "
				 "else CAST(0 AS sys.bit) "
				 "end as is_xml_document, "
				 "0::sys.bit as is_case_sensitive, "
				 "CAST(0 as sys.bit) as is_fixed_length_clr_type, "
				 "CAST(NULL as sys.sysname) as source_server,  "
				 "CAST(NULL as sys.sysname) as source_database, "
				 "CAST(NULL as sys.sysname) as source_schema, "
				 "CAST(NULL as sys.sysname) as source_table, "
				 "CAST(NULL as sys.sysname) as source_column, "
				 "case "
				 "when t1.is_identity collate sys.database_default = \'YES\' then CAST(1 AS sys.bit) "
				 "else CAST(0 AS sys.bit) "
				 "end as is_identity_column, "
				 "CAST(NULL as sys.bit) as is_part_of_unique_key, " /* pg_constraint */
				 "case  "
				 "when t1.is_updatable collate sys.database_default = \'YES\' AND t1.is_generated collate sys.database_default = \'NEVER\' AND t1.is_identity collate sys.database_default = \'NO\' AND t3.\"DATA_TYPE\" collate sys.database_default <> \'timestamp\' then CAST(1 AS sys.bit) "
				 "else CAST(0 AS sys.bit) "
				 "end as is_updateable, "
				 "case "
				 "when t1.is_generated collate sys.database_default = \'NEVER\' then CAST(0 AS sys.bit) "
				 "else CAST(1 AS sys.bit) "
				 "end as is_computed_column, "
				 "CAST(0 as sys.bit) as is_sparse_column_set, "
				 "CAST(NULL as smallint) ordinal_in_order_by_list, "
				 "CAST(NULL as smallint) order_by_list_length, "
				 "CAST(NULL as smallint) order_by_is_descending, "
	/* below are for internal usage */
				 "CAST(sys.get_tds_id(t3.\"DATA_TYPE\") as int) as tds_type_id, "
				 "CAST( "
				 "CASE "
				 "WHEN t3.\"DATA_TYPE\" collate sys.database_default = \'xml\' THEN 8100 "
				 "WHEN t3.\"DATA_TYPE\" collate sys.database_default = \'sql_variant\' THEN 8009 "
				 "WHEN t3.\"DATA_TYPE\" collate sys.database_default = \'numeric\' THEN 17 "
				 "WHEN t3.\"DATA_TYPE\" collate sys.database_default = \'decimal\' THEN 17 "
				 "ELSE t4.max_length END as int) "
				 "as tds_length, "
				 "CAST(COLLATIONPROPERTY(t4.collation_name, 'CollationId') as int) as tds_collation_id, "
				 "CAST(COLLATIONPROPERTY(t4.collation_name, 'SortId') as int) AS tds_collation_sort_id "
				 "FROM information_schema.columns t1, information_schema_tsql.columns t3, "
				 "sys.columns t4, pg_class t5 "
				 "LEFT OUTER JOIN (sys.babelfish_namespace_ext ext JOIN sys.pg_namespace_ext t6 ON t6.nspname = ext.nspname collate sys.database_default) "
				 "on t5.relnamespace = t6.oid "
				 "WHERE (t1.table_name = \'%s\' collate sys.database_default AND t1.table_schema = ext.nspname collate sys.database_default) "
				 "AND (t3.\"TABLE_NAME\" = t1.table_name collate sys.database_default AND t3.\"TABLE_SCHEMA\" = ext.orig_name collate sys.database_default) "
				 "AND t5.relname = t1.table_name collate sys.database_default "
				 "AND (t5.oid = t4.object_id AND t3.\"ORDINAL_POSITION\" = t4.column_id) "
				 "AND ext.dbid = cast(sys.db_id() as oid) "
				 "AND t1.dtd_identifier::int = t3.\"ORDINAL_POSITION\";", viewName);
}

/*
 * Internal function used by procedure sys.sp_describe_first_result_set.
 */
Datum
sp_describe_first_result_set_internal(PG_FUNCTION_ARGS)
{
	/* SRF related things to keep enough state between calls */
	FuncCallContext *funcctx;
	int			call_cntr = 0;
	int			max_calls = 0;
	TupleDesc	tupdesc;
	AttInMetadata *attinmeta;

	SPITupleTable *tuptable;
	char	   *batch;
	char	   *query;
	int			rc;
	ANTLR_result result;
	char	   *parsedbatch = NULL;

	/* stuff done only on the first call of the function */
	if (SRF_IS_FIRSTCALL())
	{
		MemoryContext oldcontext;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		batch = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));

		/*
		 * TODO: params and browseMode has to be still implemented in this
		 * C-type function
		 */
		sp_describe_first_result_set_view_name = psprintf("sp_describe_first_result_set_view_%d", rand());

		get_call_result_type(fcinfo, NULL, &tupdesc);
		attinmeta = TupleDescGetAttInMetadata(tupdesc);
		funcctx->attinmeta = attinmeta;

		/* First, pass the batch to the ANTLR parser. */
		if (batch)
		{
			result = antlr_parser_cpp(batch);

			if (!result.success)
				report_antlr_error(result);

			/* Skip if NULL query was passed. */
			if (pltsql_parse_result->body)
				parsedbatch = ((PLtsql_stmt_execsql *) lsecond(pltsql_parse_result->body))->sqlstmt->query;
		}

		/*
		 * If TSQL Query is NULL string or a non-select query then send no
		 * rows.
		 */
		if (parsedbatch && strncasecmp(parsedbatch, "select", 6) == 0)
		{
			sp_describe_first_result_set_inprogress = true;
			query = psprintf("CREATE VIEW %s as %s", sp_describe_first_result_set_view_name, parsedbatch);

			/*
			 * Switch Dialect so that SPI_execute creates a TSQL View, obeying
			 * TSQL Syntax.
			 */
			set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
							  GUC_CONTEXT_CONFIG,
							  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
			if ((rc = SPI_execute(query, false, 1)) < 0)
			{
				sp_describe_first_result_set_inprogress = false;
				set_config_option("babelfishpg_tsql.sql_dialect", "postgres",
								  GUC_CONTEXT_CONFIG,
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));
			}

			sp_describe_first_result_set_inprogress = false;

			set_config_option("babelfishpg_tsql.sql_dialect", "postgres",
							  GUC_CONTEXT_CONFIG,
							  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
			pfree(query);

			/*
			 * Execute the Select statement in try/catch so that we drop the
			 * view in case of an error.
			 */
			PG_TRY();
			{
				/* Now execute the actual query which fetches us the result. */
				query = sp_describe_first_result_set_query(sp_describe_first_result_set_view_name);
				if ((rc = SPI_execute(query, false, 0)) != SPI_OK_SELECT)
					elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

				if (SPI_processed == 0)
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							 errmsg("SPI_execute returned no rows: %s", query)));
				pfree(query);
			}
			PG_CATCH();
			{
				query = psprintf("DROP VIEW %s", sp_describe_first_result_set_view_name);

				if ((rc = SPI_execute(query, false, 1)) < 0)
					elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

				pfree(query);
				pfree(sp_describe_first_result_set_view_name);
				SPI_finish();
				PG_RE_THROW();
			}
			PG_END_TRY();
			funcctx->user_fctx = (void *) SPI_tuptable;
			funcctx->max_calls = SPI_processed;
		}
		else
			funcctx->max_calls = 0;

		MemoryContextSwitchTo(oldcontext);

	}


	funcctx = SRF_PERCALL_SETUP();
	call_cntr = funcctx->call_cntr;
	max_calls = funcctx->max_calls;
	attinmeta = funcctx->attinmeta;
	tuptable = funcctx->user_fctx;

	if (call_cntr < max_calls)
	{
		char	  **values;
		HeapTuple	tuple;
		Datum result;
		int			col;
		int			numCols = 39;

		values = (char **) palloc(numCols * sizeof(char *));

		for (col = 0; col < numCols; col++)
			values[col] = SPI_getvalue(tuptable->vals[call_cntr],
									   tuptable->tupdesc, col + 1);

		tuple = BuildTupleFromCStrings(attinmeta, values);
		result = HeapTupleGetDatum(tuple);

		SRF_RETURN_NEXT(funcctx, result);
	}
	else
	{
		if (max_calls != 0)
		{
			SPI_freetuptable(tuptable);
			query = psprintf("DROP VIEW %s", sp_describe_first_result_set_view_name);
			if ((rc = SPI_execute(query, false, 0)) < 0)
				elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));
			pfree(query);
		}
		pfree(sp_describe_first_result_set_view_name);
		SRF_RETURN_DONE(funcctx);
	}
}

/*
 * Recurse down the BoolExpr if needed, and append all relevant ColumnRef->fields
 * to the list.
 */
List *
handle_bool_expr_rec(BoolExpr *expr, List *list)
{
	List	   *args = expr->args;
	ListCell   *lc;
	A_Expr	   *xpr;
	ColumnRef  *ref;

	foreach(lc, args)
	{
		Expr	   *arg = (Expr *) lfirst(lc);

		switch (arg->type)
		{
			case T_A_Expr:
				xpr = (A_Expr *) arg;

				if (nodeTag(xpr->rexpr) != T_ColumnRef)
				{
					ereport(WARNING,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
				}
				ref = (ColumnRef *) xpr->rexpr;
				list = list_concat(list, ref->fields);
				break;
			case T_BoolExpr:
				list = handle_bool_expr_rec((BoolExpr *) arg, list);
				break;
			default:
				break;
		}
	}
	return list;
}

/*
 * Returns a list of attnums constructed from the where clause provided, using
 * the column names given on the left hand side of the assignments
 */
List *
handle_where_clause_attnums(ParseState *pstate, Node *w_clause, List *target_attnums)
{
	/*
	 * Append attnos from WHERE clause into target_attnums
	 */
	ColumnRef  *ref;
	String	   *field;
	char	   *name;
	int			attrno;

	if (nodeTag(w_clause) == T_A_Expr)
	{
		A_Expr	   *where_clause = (A_Expr *) w_clause;

		if (nodeTag(where_clause->lexpr) != T_ColumnRef)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		ref = (ColumnRef *) where_clause->lexpr;
		field = linitial(ref->fields);
		name = field->sval;
		attrno = attnameAttNum(pstate->p_target_relation, name, false);
		if (attrno == InvalidAttrNumber)
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_COLUMN),
					 errmsg("column \"%s\" of relation \"%s\" does not exist",
							name,
							RelationGetRelationName(pstate->p_target_relation))));
		}

		return lappend_int(target_attnums, attrno);
	}
	else if (nodeTag(w_clause) == T_BoolExpr)
	{
		BoolExpr   *where_clause = (BoolExpr *) w_clause;
		ListCell   *lc;

		foreach(lc, where_clause->args)
		{
			Expr	   *arg = (Expr *) lfirst(lc);
			A_Expr	   *xpr;

			switch (arg->type)
			{
				case T_A_Expr:
					{
						xpr = (A_Expr *) arg;

						if (nodeTag(xpr->lexpr) != T_ColumnRef)
						{
							ereport(WARNING,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
						}
						ref = (ColumnRef *) xpr->lexpr;
						field = linitial(ref->fields);
						name = field->sval;
						attrno = attnameAttNum(pstate->p_target_relation, name, false);
						if (attrno == InvalidAttrNumber)
						{
							ereport(ERROR,
									(errcode(ERRCODE_UNDEFINED_COLUMN),
									 errmsg("column \"%s\" of relation \"%s\" does not exist",
											name,
											RelationGetRelationName(pstate->p_target_relation))));
						}
						target_attnums = lappend_int(target_attnums, attrno);
						break;
					}
				case T_BoolExpr:
					target_attnums = handle_where_clause_attnums(pstate, (Node *) arg, target_attnums);
					break;
				default:
					break;
			}
		}
		return target_attnums;
	}
	else
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
	}
	return target_attnums;
}

/*
 * Returns a list of ResTargets constructed from the where clause provided, using
 * the left hand side of the assignment (assumed to be intended as column names).
 */
List *
handle_where_clause_restargets_left(ParseState *pstate, Node *w_clause, List *extra_restargets)
{
	/*
	 * Construct a ResTarget and append it to the list.
	 */
	ColumnRef  *ref;
	String	   *field;
	char	   *name;
	int			attrno;

	if (nodeTag(w_clause) == T_A_Expr)
	{
		A_Expr	   *where_clause = (A_Expr *) w_clause;
		ResTarget  *res;

		if (nodeTag(where_clause->lexpr) != T_ColumnRef)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		ref = (ColumnRef *) where_clause->lexpr;
		field = linitial(ref->fields);
		name = field->sval;
		attrno = attnameAttNum(pstate->p_target_relation, name, false);
		if (attrno == InvalidAttrNumber)
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_COLUMN),
					 errmsg("column \"%s\" of relation \"%s\" does not exist",
							name,
							RelationGetRelationName(pstate->p_target_relation))));
		}
		res = (ResTarget *) palloc(sizeof(ResTarget));
		res->type = ref->type;
		res->name = field->sval;
		res->indirection = NIL; /* Unused for now */
		res->val = (Node *) ref;	/* Store the ColumnRef here if needed */
		res->location = ref->location;

		return lappend(extra_restargets, res);
	}
	else if (nodeTag(w_clause) == T_BoolExpr)
	{
		BoolExpr   *where_clause = (BoolExpr *) w_clause;
		ListCell   *lc;

		foreach(lc, where_clause->args)
		{
			Expr	   *arg = (Expr *) lfirst(lc);
			A_Expr	   *xpr;
			ResTarget  *res;

			switch (arg->type)
			{
				case T_A_Expr:
					{
						xpr = (A_Expr *) arg;

						if (nodeTag(xpr->lexpr) != T_ColumnRef)
						{
							ereport(WARNING,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
						}
						ref = (ColumnRef *) xpr->lexpr;
						field = linitial(ref->fields);
						name = field->sval;
						attrno = attnameAttNum(pstate->p_target_relation, name, false);
						if (attrno == InvalidAttrNumber)
						{
							ereport(ERROR,
									(errcode(ERRCODE_UNDEFINED_COLUMN),
									 errmsg("column \"%s\" of relation \"%s\" does not exist",
											name,
											RelationGetRelationName(pstate->p_target_relation))));
						}
						res = (ResTarget *) palloc(sizeof(ResTarget));
						res->type = ref->type;
						res->name = field->sval;
						res->indirection = NIL; /* Unused for now */
						res->val = (Node *) ref;	/* Store the ColumnRef
													 * here if needed */
						res->location = ref->location;

						extra_restargets = lappend(extra_restargets, res);
						break;
					}
				case T_BoolExpr:
					extra_restargets = handle_where_clause_restargets_left(pstate, (Node *) arg, extra_restargets);
					break;
				default:
					break;
			}
		}
		return extra_restargets;
	}
	else
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
	}
	return extra_restargets;
}

/*
 * Returns a list of ResTargets constructed from the where clause provided, using
 * the right hand side of the assignment (assumed to be values/parameters).
 */
List *
handle_where_clause_restargets_right(ParseState *pstate, Node *w_clause, List *extra_restargets)
{
	/*
	 * Construct a ResTarget and append it to the list.
	 */
	ColumnRef  *ref;
	String	   *field;
	ResTarget  *res;

	if (nodeTag(w_clause) == T_A_Expr)
	{
		A_Expr	   *where_clause = (A_Expr *) w_clause;

		if (nodeTag(where_clause->rexpr) != T_ColumnRef)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		ref = (ColumnRef *) where_clause->rexpr;
		field = linitial(ref->fields);
		res = (ResTarget *) palloc(sizeof(ResTarget));
		res->type = ref->type;
		res->name = field->sval;
		res->indirection = NIL; /* Unused for now */
		res->val = (Node *) ref;	/* Store the ColumnRef here if needed */
		res->location = ref->location;

		return lappend(extra_restargets, res);
	}
	else if (nodeTag(w_clause) == T_BoolExpr)
	{
		BoolExpr   *where_clause = (BoolExpr *) w_clause;
		ListCell   *lc;

		foreach(lc, where_clause->args)
		{
			Expr	   *arg = (Expr *) lfirst(lc);
			A_Expr	   *xpr;

			switch (arg->type)
			{
				case T_A_Expr:
					{
						xpr = (A_Expr *) arg;

						if (nodeTag(xpr->rexpr) != T_ColumnRef)
						{
							ereport(WARNING,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
						}
						ref = (ColumnRef *) xpr->rexpr;
						field = linitial(ref->fields);
						res = (ResTarget *) palloc(sizeof(ResTarget));
						res->type = ref->type;
						res->name = field->sval;
						res->indirection = NIL; /* Unused for now */
						res->val = (Node *) ref;	/* Store the ColumnRef
													 * here if needed */
						res->location = ref->location;

						extra_restargets = lappend(extra_restargets, res);
						break;
					}
				case T_BoolExpr:
					extra_restargets = handle_where_clause_restargets_right(pstate, (Node *) arg, extra_restargets);
					break;
				default:
					break;
			}
		}
		return extra_restargets;
	}
	else
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
	}
	return extra_restargets;
}

/*
 * Internal function used by procedure sys.sp_describe_undeclared_parameters
 * Currently only support the use case of 'INSERT ... VALUES (@P1, @P2, ...)'.
 */
Datum
sp_describe_undeclared_parameters_internal(PG_FUNCTION_ARGS)
{
	/* SRF related things to keep enough state between calls */
	FuncCallContext *funcctx;
	int			call_cntr;
	int			max_calls;
	TupleDesc	tupdesc;
	AttInMetadata *attinmeta;

	ANTLR_result result;
	List	   *raw_parsetree_list;
	ListCell   *list_item;
	InlineCodeBlockArgs *args;
	UndeclaredParams *undeclaredparams;

	if (SRF_IS_FIRSTCALL())
	{
		/*
		 * In the first call of the SRF, we do all the processing, and store
		 * the result and state information in a UndeclaredParams struct in
		 * funcctx->user_fctx
		 */
		MemoryContext oldcontext;
		char	   *batch;
		char	   *parsedbatch;
		char	   *params;
		int			sql_dialect_value_old;

		SelectStmt *select_stmt;
		List	   *values_list;
		ListCell   *lc;
		int			numresults = 0;
		int			num_target_attnums = 0;
		RawStmt    *parsetree;
		InsertStmt *insert_stmt = NULL;
		UpdateStmt *update_stmt = NULL;
		DeleteStmt *delete_stmt = NULL;
		RangeVar   *relation;
		Oid			relid;
		Relation	r;
		List	   *target_attnums = NIL;
		List	   *extra_restargets = NIL;
		ParseState *pstate;
		int			relname_len;
		List	   *cols;
		int			target_attnum_i;
		int			target_attnums_len;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		get_call_result_type(fcinfo, NULL, &tupdesc);
		attinmeta = TupleDescGetAttInMetadata(tupdesc);
		funcctx->attinmeta = attinmeta;

		undeclaredparams = (UndeclaredParams *) palloc0(sizeof(UndeclaredParams));
		funcctx->user_fctx = (void *) undeclaredparams;

		batch = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		params = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));

		/* First, pass the batch to the ANTLR parser */
		result = antlr_parser_cpp(batch);

		if (!result.success)
			report_antlr_error(result);

		/*
		 * For the currently supported use case, the parse result should
		 * contain two statements, INIT and EXECSQL. The EXECSQL statement
		 * should be an INSERT statement with VALUES clause.
		 */
		if (!pltsql_parse_result ||
			list_length(pltsql_parse_result->body) != 2 ||
			((PLtsql_stmt *) lsecond(pltsql_parse_result->body))->cmd_type != PLTSQL_STMT_EXECSQL)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		parsedbatch = ((PLtsql_stmt_execsql *) lsecond(pltsql_parse_result->body))->sqlstmt->query;

		args = create_args(0);
		if (params)
			read_param_def(args, params);

		/* Next, pass the ANTLR-parsed batch to the backend parser */
		sql_dialect_value_old = sql_dialect;
		sql_dialect = SQL_DIALECT_TSQL;
		raw_parsetree_list = pg_parse_query(parsedbatch);
		if (list_length(raw_parsetree_list) != 1)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		list_item = list_head(raw_parsetree_list);
		parsetree = lfirst_node(RawStmt, list_item);

		/*
		 * Analyze the parsed statement to suggest types for undeclared
		 * parameters
		 */
		switch (nodeTag(parsetree->stmt))
		{
			case T_InsertStmt:
				rewrite_object_refs(parsetree->stmt);
				sql_dialect = sql_dialect_value_old;
				insert_stmt = (InsertStmt *) parsetree->stmt;
				relation = insert_stmt->relation;
				relid = RangeVarGetRelid(relation, NoLock, false);
				r = relation_open(relid, AccessShareLock);
				pstate = (ParseState *) palloc0(sizeof(ParseState));
				pstate->p_target_relation = r;
				cols = checkInsertTargets(pstate, insert_stmt->cols, &target_attnums);
				break;
			case T_UpdateStmt:
				rewrite_object_refs(parsetree->stmt);
				sql_dialect = sql_dialect_value_old;
				update_stmt = (UpdateStmt *) parsetree->stmt;
				relation = update_stmt->relation;
				relid = RangeVarGetRelid(relation, NoLock, false);
				r = relation_open(relid, AccessShareLock);
				pstate = (ParseState *) palloc0(sizeof(ParseState));
				pstate->p_target_relation = r;
				cols = list_copy(update_stmt->targetList);

				/*
				 * Add attnums to cols based on targetList
				 */
				foreach(lc, cols)
				{
					ResTarget  *col = (ResTarget *) lfirst(lc);
					char	   *name = col->name;
					int			attrno;

					attrno = attnameAttNum(pstate->p_target_relation, name, false);
					if (attrno == InvalidAttrNumber)
					{
						ereport(ERROR,
								(errcode(ERRCODE_UNDEFINED_COLUMN),
								 errmsg("column \"%s\" of relation \"%s\" does not exist",
										name,
										RelationGetRelationName(pstate->p_target_relation))));
					}
					target_attnums = lappend_int(target_attnums, attrno);
				}
				target_attnums = handle_where_clause_attnums(pstate, update_stmt->whereClause, target_attnums);
				extra_restargets = handle_where_clause_restargets_left(pstate, update_stmt->whereClause, extra_restargets);

				cols = list_concat_copy(cols, extra_restargets);
				break;
			case T_DeleteStmt:
				rewrite_object_refs(parsetree->stmt);
				sql_dialect = sql_dialect_value_old;
				delete_stmt = (DeleteStmt *) parsetree->stmt;
				relation = delete_stmt->relation;
				relid = RangeVarGetRelid(relation, NoLock, false);
				r = relation_open(relid, AccessShareLock);
				pstate = (ParseState *) palloc0(sizeof(ParseState));
				pstate->p_target_relation = r;
				cols = NIL;

				/*
				 * Add attnums to cols based on targetList
				 */
				foreach(lc, cols)
				{
					ResTarget  *col = (ResTarget *) lfirst(lc);
					char	   *name = col->name;
					int			attrno;

					attrno = attnameAttNum(pstate->p_target_relation, name, false);
					if (attrno == InvalidAttrNumber)
					{
						ereport(ERROR,
								(errcode(ERRCODE_UNDEFINED_COLUMN),
								 errmsg("column \"%s\" of relation \"%s\" does not exist",
										name,
										RelationGetRelationName(pstate->p_target_relation))));
					}
					target_attnums = lappend_int(target_attnums, attrno);
				}
				target_attnums = handle_where_clause_attnums(pstate, delete_stmt->whereClause, target_attnums);
				extra_restargets = handle_where_clause_restargets_left(pstate, delete_stmt->whereClause, extra_restargets);

				cols = list_concat_copy(cols, extra_restargets);
				break;
			default:
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
				break;
		}

		undeclaredparams->tablename = (char *) palloc(NAMEDATALEN);
		relname_len = strlen(relation->relname);
		strncpy(undeclaredparams->tablename, relation->relname, NAMEDATALEN);
		undeclaredparams->tablename[relname_len] = '\0';
		undeclaredparams->schemaoid = RelationGetNamespace(r);
		undeclaredparams->targetattnums = (int *) palloc(sizeof(int) * list_length(target_attnums));
		undeclaredparams->targetcolnames = (char **) palloc(sizeof(char *) * list_length(target_attnums));

		/* Record attnums and column names of the target table */
		target_attnum_i = 0;
		target_attnums_len = list_length(target_attnums);
		while (target_attnum_i < target_attnums_len)
		{
			ListCell   *lc;
			ResTarget  *col;
			int			colname_len;

			lc = list_nth_cell(target_attnums, target_attnum_i);
			undeclaredparams->targetattnums[num_target_attnums] = lfirst_int(lc);

			col = (ResTarget *) list_nth(cols, target_attnum_i);
			colname_len = strlen(col->name);
			undeclaredparams->targetcolnames[num_target_attnums] = (char *) palloc(NAMEDATALEN);
			strncpy(undeclaredparams->targetcolnames[num_target_attnums], col->name, NAMEDATALEN);
			undeclaredparams->targetcolnames[num_target_attnums][colname_len] = '\0';

			target_attnum_i += 1;
			num_target_attnums += 1;
		}

		relation_close(r, AccessShareLock);
		pfree(pstate);

		/*
		 * Parse the list of parameters, and determine which and how many are
		 * undeclared.
		 */
		switch (nodeTag(parsetree->stmt))
		{
			case T_InsertStmt:
				select_stmt = (SelectStmt *) insert_stmt->selectStmt;
				values_list = select_stmt->valuesLists;
				break;
			case T_UpdateStmt:

				/*
				 * In an UPDATE statement, we could have both SET and WHERE
				 * with undeclared parameters. That's targetList (SET ...) and
				 * whereClause (WHERE ...)
				 */
				values_list = list_make1(handle_where_clause_restargets_right(pstate, update_stmt->whereClause, update_stmt->targetList));
				break;
			case T_DeleteStmt:
				values_list = list_make1(handle_where_clause_restargets_right(pstate, delete_stmt->whereClause, NIL));
				break;
			default:
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
				break;
		}

		if (list_length(values_list) > 1)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		foreach(lc, values_list)
		{
			List	   *sublist = lfirst(lc);
			ListCell   *sublc;
			int			numvalues = 0;
			int			numtotalvalues = list_length(sublist);

			undeclaredparams->paramnames = (char **) palloc(sizeof(char *) * numtotalvalues);
			undeclaredparams->paramindexes = (int *) palloc(sizeof(int) * numtotalvalues);
			if (list_length(sublist) != num_target_attnums)
			{
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Column name or number of supplied values does not match table definition.")));
			}
			foreach(sublc, sublist)
			{
				ColumnRef  *columnref = NULL;
				ResTarget  *res;
				List	   *fields;
				ListCell   *fieldcell;

				/*
				 * Tack on WHERE clause for the same as above, for UPDATE and
				 * DELETE statements.
				 */
				switch (nodeTag(parsetree->stmt))
				{
					case T_InsertStmt:
						columnref = lfirst(sublc);
						break;
					case T_UpdateStmt:
					case T_DeleteStmt:
						res = lfirst(sublc);
						if (nodeTag(res->val) != T_ColumnRef)
						{
							ereport(ERROR,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
						}
						columnref = (ColumnRef *) res->val;
						break;
					default:
						break;
				}
				fields = columnref->fields;
				if (nodeTag(columnref) != T_ColumnRef && nodeTag(parsetree->stmt) != T_DeleteStmt)
				{
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
				}

				foreach(fieldcell, fields)
				{
					String	   *field = lfirst(fieldcell);

					/* Make sure it's a parameter reference */
					if (field->sval && field->sval[0] == '@')
					{
						int			i;
						bool		undeclared = true;

						/* Make sure it is not declared in @params */
						for (i = 0; i < args->numargs; ++i)
						{
							if (args->argnames && args->argnames[i] &&
								(strcmp(args->argnames[i], field->sval) == 0))
							{
								undeclared = false;
								break;
							}
						}
						if (undeclared)
						{
							int			paramname_len = strlen(field->sval);

							undeclaredparams->paramnames[numresults] = (char *) palloc(NAMEDATALEN);
							strncpy(undeclaredparams->paramnames[numresults], field->sval, NAMEDATALEN);
							undeclaredparams->paramnames[numresults][paramname_len] = '\0';
							undeclaredparams->paramindexes[numresults] = numvalues;
							numresults += 1;
						}
					}
				}
				numvalues += 1;
			}
		}

		funcctx->max_calls = numresults;
		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	call_cntr = funcctx->call_cntr;
	max_calls = funcctx->max_calls;
	attinmeta = funcctx->attinmeta;
	undeclaredparams = funcctx->user_fctx;

	/*
	 * This is the main recursive work, to determine the appropriate parameter
	 * type for each parameter.
	 */
	if (call_cntr < max_calls)
	{
		char	  **values;
		HeapTuple	tuple;
		Datum result;
		int			col;
		int			numresultcols = 24;
		char	   *tempq =
		" SELECT "
		"CAST( 0 AS INT ) "		/* AS "parameter_ordinal"  -- Need to get
								 * correct ordinal number in code. */
		", CAST( NULL AS sysname ) "	/* AS "name"  -- Need to get correct
										 * parameter name in code. */
		", CASE "
		"WHEN T2.name COLLATE sys.database_default = \'bigint\' THEN 127 "
		"WHEN T2.name COLLATE sys.database_default = \'binary\' THEN 173 "
		"WHEN T2.name COLLATE sys.database_default = \'bit\' THEN 104 "
		"WHEN T2.name COLLATE sys.database_default = \'char\' THEN 175 "
		"WHEN T2.name COLLATE sys.database_default = \'date\' THEN 40 "
		"WHEN T2.name COLLATE sys.database_default = \'datetime\' THEN 61 "
		"WHEN T2.name COLLATE sys.database_default = \'datetime2\' THEN 42 "
		"WHEN T2.name COLLATE sys.database_default = \'datetimeoffset\' THEN 43 "
		"WHEN T2.name COLLATE sys.database_default = \'decimal\' THEN 106 "
		"WHEN T2.name COLLATE sys.database_default = \'float\' THEN 62 "
		"WHEN T2.name COLLATE sys.database_default = \'image\' THEN 34 "
		"WHEN T2.name COLLATE sys.database_default = \'int\' THEN 56 "
		"WHEN T2.name COLLATE sys.database_default = \'money\' THEN 60 "
		"WHEN T2.name COLLATE sys.database_default = \'nchar\' THEN 239 "
		"WHEN T2.name COLLATE sys.database_default = \'ntext\' THEN 99 "
		"WHEN T2.name COLLATE sys.database_default = \'numeric\' THEN 108 "
		"WHEN T2.name COLLATE sys.database_default = \'nvarchar\' THEN 231 "
		"WHEN T2.name COLLATE sys.database_default = \'real\' THEN 59 "
		"WHEN T2.name COLLATE sys.database_default = \'smalldatetime\' THEN 58 "
		"WHEN T2.name COLLATE sys.database_default = \'smallint\' THEN 52 "
		"WHEN T2.name COLLATE sys.database_default = \'smallmoney\' THEN 122 "
		"WHEN T2.name COLLATE sys.database_default = \'text\' THEN 35 "
		"WHEN T2.name COLLATE sys.database_default = \'time\' THEN 41 "
		"WHEN T2.name COLLATE sys.database_default = \'tinyint\' THEN 48 "
		"WHEN T2.name COLLATE sys.database_default = \'uniqueidentifier\' THEN 36 "
		"WHEN T2.name COLLATE sys.database_default = \'varbinary\' THEN 165 "
		"WHEN T2.name COLLATE sys.database_default = \'varchar\' THEN 167 "
		"WHEN T2.name COLLATE sys.database_default =  \'xml\' THEN 241 "
		"ELSE C.system_type_id "
		"END "					/* AS "suggested_system_type_id" */
		", CASE "
		"WHEN T2.name COLLATE sys.database_default = \'decimal\' THEN \'decimal(\' + CAST( C.precision AS sys.VARCHAR(10) ) + \',\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'numeric\' THEN \'numeric(\' + CAST( C.precision AS sys.VARCHAR(10) ) + \',\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'char\' THEN \'char(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'nchar\' THEN \'nchar(\' + CAST( C.max_length/2 AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'binary\' THEN \'binary(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'datetime2\' THEN \'datetime2(\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'datetimeoffset\' THEN \'datetimeoffset(\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'time\' THEN \'time(\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name COLLATE sys.database_default = \'varchar\' THEN "
		"CASE WHEN C.max_length = -1 THEN \'varchar(max)\' "
		"ELSE \'varchar(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
		"END "
		"WHEN T2.name COLLATE sys.database_default = \'nvarchar\' THEN "
		"CASE WHEN C.max_length = -1 THEN \'nvarchar(max)\' "
		"ELSE \'nvarchar(\' + CAST( C.max_length/2 AS sys.VARCHAR(10) ) + \')\' "
		"END "
		"WHEN T2.name COLLATE sys.database_default = \'varbinary\' THEN "
		"CASE WHEN C.max_length = -1 THEN \'varbinary(max)\' "
		"ELSE \'varbinary(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
		"END "
		"ELSE T2.name "
		"END "					/* AS "suggested_system_type_name" */
		", CASE "
		"WHEN T2.name COLLATE sys.database_default IN (\'image\', \'ntext\',\'text\') THEN -1 "
		"ELSE C.max_length "
		"END  "					/* AS "suggested_max_length" */
		", C.precision "		/* AS "suggested_precision" */
		", C.scale "			/* AS "suggested_scale" */
		", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS INT ) ELSE T.user_type_id END "	/* AS
																											 * "suggested_user_type_id" */
		", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS sysname) ELSE DB_NAME() END " /* AS
																										 * "suggested_user_type_database" */
		", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS sysname) ELSE SCHEMA_NAME( T.schema_id ) END "	/* AS
																															 * "suggested_user_type_schema" */
		", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS sysname) ELSE T.name END "	/* AS
																										 * "suggested_user_type_name" */
		", CAST( NULL AS NVARCHAR(4000) ) " /* AS
											 * "suggested_assembly_qualified_type_name" */
		", CASE "
		"WHEN C.xml_collection_id = 0 THEN CAST( NULL AS INT ) "
		"ELSE C.xml_collection_id "
		"END "					/* AS "suggested_xml_collection_id" */
		", CAST( NULL AS sysname ) "	/* AS
										 * "suggested_xml_collection_database" */
		", CAST( NULL AS sysname ) "	/* AS
										 * "suggested_xml_collection_schema" */
		", CAST( NULL AS sysname ) "	/* AS "suggested_xml_collection_name" */
		", C.is_xml_document "	/* AS "suggested_is_xml_document" */
		", CAST( 0 AS BIT ) "	/* AS "suggested_is_case_sensitive" */
		", CAST( 0 AS BIT ) "	/* AS "suggested_is_fixed_length_clr_type" */
		", CAST( 1 AS BIT ) "	/* AS "suggested_is_input" */
		", CAST( 0 AS BIT ) "	/* AS "suggested_is_output" */
		", CAST( NULL AS sysname ) "	/* AS "formal_parameter_name" */
		", CASE "
		"WHEN T2.name COLLATE sys.database_default IN (\'tinyint\', \'smallint\', \'int\', \'bigint\') THEN 38 "
		"WHEN T2.name COLLATE sys.database_default IN (\'float\', \'real\') THEN 109 "
		"WHEN T2.name COLLATE sys.database_default IN (\'smallmoney\', \'money\') THEN 110 "
		"WHEN T2.name COLLATE sys.database_default IN (\'smalldatetime\', \'datetime\') THEN 111 "
		"WHEN T2.name COLLATE sys.database_default = \'binary\' THEN 173 "
		"WHEN T2.name COLLATE sys.database_default = \'bit\' THEN 104 "
		"WHEN T2.name COLLATE sys.database_default = \'char\' THEN 175 "
		"WHEN T2.name COLLATE sys.database_default = \'date\' THEN 40 "
		"WHEN T2.name COLLATE sys.database_default = \'datetime2\' THEN 42 "
		"WHEN T2.name COLLATE sys.database_default = \'datetimeoffset\' THEN 43 "
		"WHEN T2.name COLLATE sys.database_default = \'decimal\' THEN 106 "
		"WHEN T2.name COLLATE sys.database_default = \'image\' THEN 34 "
		"WHEN T2.name COLLATE sys.database_default = \'nchar\' THEN 239 "
		"WHEN T2.name COLLATE sys.database_default = \'ntext\' THEN 99 "
		"WHEN T2.name COLLATE sys.database_default = \'numeric\' THEN 108 "
		"WHEN T2.name COLLATE sys.database_default = \'nvarchar\' THEN 231 "
		"WHEN T2.name COLLATE sys.database_default = \'text\' THEN 35 "
		"WHEN T2.name COLLATE sys.database_default = \'time\' THEN 41 "
		"WHEN T2.name COLLATE sys.database_default = \'uniqueidentifier\' THEN 36 "
		"WHEN T2.name COLLATE sys.database_default= \'varbinary\' THEN 165 "
		"WHEN T2.name COLLATE sys.database_default = \'varchar\' THEN 167 "
		"WHEN T2.name COLLATE sys.database_default =  \'xml\' THEN 241 "
		"ELSE C.system_type_id "
		"END "					/* AS "suggested_tds_type_id" */
		", CASE "
		"WHEN T2.name COLLATE sys.database_default = \'nvarchar\' AND C.max_length = -1 THEN 65535 "
		"WHEN T2.name COLLATE sys.database_default = \'varbinary\' AND C.max_length = -1 THEN 65535 "
		"WHEN T2.name COLLATE sys.database_default = \'varchar\' AND C.max_length = -1 THEN 65535 "
		"WHEN T2.name COLLATE sys.database_default IN (\'decimal\', \'numeric\') THEN 17 "
		"WHEN T2.name COLLATE sys.database_default = \'xml\' THEN 8100 "
		"WHEN T2.name COLLATE sys.database_default in (\'image\', \'text\') THEN 2147483647 "
		"WHEN T2.name COLLATE sys.database_default = \'ntext\' THEN 2147483646 "
		"ELSE CAST( C.max_length AS INT ) "
		"END "					/* AS "suggested_tds_length" */
		"FROM sys.objects O, sys.columns C, sys.types T, sys.types T2 "
		"WHERE O.object_id = C.object_id "
		"AND C.user_type_id = T.user_type_id "
		"AND C.name = \'%s\' COLLATE sys.database_default " /* -- INPUT column name */
		"AND T.system_type_id = T2.user_type_id "	/* -- To get system dt
													 * name. */
		"AND O.name = \'%s\' COLLATE sys.database_default " /* -- INPUT table name */
		"AND O.schema_id = %d " /* -- INPUT schema Oid */
		"AND O.type = \'U\'";	/* -- User tables only for the time being */

		char	   *query = psprintf(tempq,
									 undeclaredparams->targetcolnames[undeclaredparams->paramindexes[call_cntr]],
									 undeclaredparams->tablename,
									 undeclaredparams->schemaoid);

		int			rc = SPI_execute(query, true, 1);

		if (rc != SPI_OK_SELECT)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("SPI_execute failed: %s", SPI_result_code_string(rc))));
		if (SPI_processed == 0)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("SPI_execute returned no rows: %s", query)));

		values = (char **) palloc(numresultcols * sizeof(char *));

		/*
		 * This sets the parameter ordinal attribute correctly, since the
		 * above query can't infer that information
		 */
		values[0] = psprintf("%d", call_cntr + 1);
		/* Then, pull the appropriate parameter name from the data type */
		values[1] = undeclaredparams->paramnames[call_cntr];
		for (col = 2; col < numresultcols; col++)
		{
			values[col] = SPI_getvalue(SPI_tuptable->vals[0],
									   SPI_tuptable->tupdesc, col + 1);
		}

		tuple = BuildTupleFromCStrings(attinmeta, values);
		result = HeapTupleGetDatum(tuple);

		SPI_freetuptable(SPI_tuptable);
		SRF_RETURN_NEXT(funcctx, result);
	}
	else
	{
		SRF_RETURN_DONE(funcctx);
	}
}

/*
 * Internal function used by procedure xp_qv.
 * The xp_qv procedure is called by SSMS. Only the minimum implementation is required.
 */
Datum
xp_qv_internal(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

/*
 * Internal function to create the xp_qv procedure in master.dbo schema.
 * Some applications invoke this referencing master.dbo.xp_qv
 */
Datum
create_xp_qv_in_master_dbo_internal(PG_FUNCTION_ARGS)
{
	char	   *query = NULL;
	int			rc = -1;

	char	   *tempq = "CREATE OR REPLACE PROCEDURE %s.xp_qv(IN SYS.NVARCHAR(256), IN SYS.NVARCHAR(256))"
	"AS \'babelfishpg_tsql\', \'xp_qv_internal\' LANGUAGE C";

	const char *dbo_scm = get_dbo_schema_name("master");

	if (dbo_scm == NULL)
		elog(ERROR, "Failed to retrieve dbo schema name");

	query = psprintf(tempq, dbo_scm);

	PG_TRY();
	{
		if ((rc = SPI_connect()) != SPI_OK_CONNECT)
			elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));

		if ((rc = SPI_execute(query, false, 1)) < 0)
			elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

		if ((rc = SPI_finish()) != SPI_OK_FINISH)
			elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));
	}
	PG_CATCH();
	{
		SPI_finish();
		PG_RE_THROW();
	}
	PG_END_TRY();

	PG_RETURN_INT32(0);
}

/*
 * Internal function used by procedure xp_instance_regread.
 * The xp_instance_regread procedure is called by SSMS. Only the minimum implementation is required.
 */
Datum
xp_instance_regread_internal(PG_FUNCTION_ARGS)
{
	int			nargs = PG_NARGS() - 1;

	/* Get data type OID of last parameter, which should be the OUT parameter. */
	Oid			argtypeid = get_fn_expr_argtype(fcinfo->flinfo, nargs);

	HeapTuple	tuple;
	HeapTupleHeader result;
	TupleDesc	tupdesc;
	bool		isnull = true;
	Datum		values[1];

	tupdesc = CreateTemplateTupleDesc(1);

	if (argtypeid == INT4OID)
	{
		values[0] = Int32GetDatum(NULL);
		TupleDescInitEntry(tupdesc, (AttrNumber) 1, "out_param", INT4OID, -1, 0);
	}

	else
	{
		values[0] = CStringGetDatum(NULL);
		TupleDescInitEntry(tupdesc, (AttrNumber) 1, "out_param", CSTRINGOID, -1, 0);
	}

	tupdesc = BlessTupleDesc(tupdesc);
	tuple = heap_form_tuple(tupdesc, values, &isnull);

	result = (HeapTupleHeader) palloc(tuple->t_len);

	memcpy(result, tuple->t_data, tuple->t_len);

	heap_freetuple(tuple);
	ReleaseTupleDesc(tupdesc);

	PG_RETURN_HEAPTUPLEHEADER(result);
}

/*
 * Internal function to create the xp_instance_regread procedure in master.dbo schema.
 * Some applications invoke this referencing master.dbo.xp_instance_regread
 */
Datum
create_xp_instance_regread_in_master_dbo_internal(PG_FUNCTION_ARGS)
{
	char	   *query = NULL;
	char	   *query2 = NULL;
	int			rc = -1;

	char	   *tempq = "CREATE OR REPLACE PROCEDURE %s.xp_instance_regread(IN p1 sys.nvarchar(512), IN p2 sys.sysname, IN p3 sys.nvarchar(512), INOUT out_param int)"
	"AS \'babelfishpg_tsql\', \'xp_instance_regread_internal\' LANGUAGE C";

	char	   *tempq2 = "CREATE OR REPLACE PROCEDURE %s.xp_instance_regread(IN p1 sys.nvarchar(512), IN p2 sys.sysname, IN p3 sys.nvarchar(512), INOUT out_param sys.nvarchar(512))"
	"AS \'babelfishpg_tsql\', \'xp_instance_regread_internal\' LANGUAGE C";

	const char *dbo_scm = get_dbo_schema_name("master");

	if (dbo_scm == NULL)
		elog(ERROR, "Failed to retrieve dbo schema name");

	query = psprintf(tempq, dbo_scm);
	query2 = psprintf(tempq2, dbo_scm);

	PG_TRY();
	{
		if ((rc = SPI_connect()) != SPI_OK_CONNECT)
			elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));

		if ((rc = SPI_execute(query, false, 1)) < 0)
			elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

		if ((rc = SPI_execute(query2, false, 1)) < 0)
			elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

		if ((rc = SPI_finish()) != SPI_OK_FINISH)
			elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));
	}
	PG_CATCH();
	{
		SPI_finish();
		PG_RE_THROW();
	}
	PG_END_TRY();

	PG_RETURN_INT32(0);
}

Datum
sp_addrole(PG_FUNCTION_ARGS)
{
	char	   *rolname,
			   *lowercase_rolname,
			   *ownername;
	size_t		len;
	char	   *physical_role_name;
	Oid			role_oid;
	List	   *parsetree_list;
	ListCell   *parsetree_item;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		rolname = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		ownername = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));

		/* Role name is not NULL */
		if (rolname == NULL)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/*
		 * Ensure the database name input argument is lower-case, as all Babel
		 * role names are lower-case
		 */
		lowercase_rolname = lowerstr(rolname);

		/* Remove trailing whitespaces */
		len = strlen(lowercase_rolname);
		while (isspace(lowercase_rolname[len - 1]))
			lowercase_rolname[--len] = 0;

		/* check if role name is empty after removing trailing spaces */
		if (strlen(lowercase_rolname) == 0)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/*
		 * @ownername is not yet supported in babelfish. Throw an error if
		 * @ownername is passed either as an empty string or contains value
		 */
		if (ownername)
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("The @ownername argument is not yet supported in Babelfish.")));

		/* Role name cannot contain '\' */
		if (strchr(lowercase_rolname, '\\') != NULL)
			ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							errmsg("'%s' is not a valid name because it contains invalid characters.", rolname)));

		/* Map the logical role name to its physical name in the database. */
		physical_role_name = get_physical_user_name(get_cur_db_name(), lowercase_rolname);
		role_oid = get_role_oid(physical_role_name, true);

		/* Check if the user, group or role already exists */
		if (role_oid)
			ereport(ERROR,
					(errcode(ERRCODE_DUPLICATE_OBJECT),
					 errmsg("User, group, or role '%s' already exists in the current database.", rolname)));

		/* Remove trailing whitespaces */
		len = strlen(rolname);
		while (isspace(rolname[len - 1]))
			rolname[--len] = 0;

		/* Advance cmd counter to make the delete visible */
		CommandCounterIncrement();

		parsetree_list = gen_sp_addrole_subcmds(rolname);

		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 16;

			/* do this step */
			ProcessUtility(wrapper,
						   "(CREATE ROLE )",
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		PG_RE_THROW();
	}
	PG_END_TRY();
	set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	PG_RETURN_VOID();
}

static List *
gen_sp_addrole_subcmds(const char *user)
{
	StringInfoData query;
	List	   *res;
	Node	   *stmt;
	CreateRoleStmt *rolestmt;
	List	   *user_options = NIL;

	initStringInfo(&query);
	appendStringInfo(&query, "CREATE ROLE dummy; ");
	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if (list_length(res) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing", list_length(res))));

	stmt = parsetree_nth_stmt(res, 0);

	rolestmt = (CreateRoleStmt *) stmt;
	if (!IsA(rolestmt, CreateRoleStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a CreateRoleStmt")));

	rolestmt->role = pstrdup(lowerstr(user));
	rewrite_object_refs(stmt);

	/*
	 * Add original_user_name before hand because placeholder query "(CREATE
	 * ROLE )" is being passed that doesn't contain the user name.
	 */
	user_options = lappend(user_options,
						   makeDefElem("original_user_name",
									   (Node *) makeString((char *) user),
									   -1));
	rolestmt->options = list_concat(rolestmt->options, user_options);

	return res;
}

Datum
sp_droprole(PG_FUNCTION_ARGS)
{
	char	   *rolname,
			   *lowercase_rolname;
	size_t		len;
	char	   *physical_role_name;
	Oid			role_oid;
	List	   *parsetree_list;
	ListCell   *parsetree_item;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		rolname = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));

		/* Role name is not NULL */
		if (rolname == NULL)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/*
		 * Ensure the database name input argument is lower-case, as all Babel
		 * role names are lower-case
		 */
		lowercase_rolname = lowerstr(rolname);

		/* Remove trailing whitespaces */
		len = strlen(lowercase_rolname);
		while (isspace(lowercase_rolname[len - 1]))
			lowercase_rolname[--len] = 0;

		/* check if role name is empty after removing trailing spaces */
		if (strlen(lowercase_rolname) == 0)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/* Map the logical role name to its physical name in the database. */
		physical_role_name = get_physical_user_name(get_cur_db_name(), lowercase_rolname);
		role_oid = get_role_oid(physical_role_name, true);

		/* Check if the role does not exists */
		if (role_oid == InvalidOid || !is_role(role_oid))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("Cannot drop the role '%s', because it does not exist or you do not have permission.", rolname)));

		/* Advance cmd counter to make the delete visible */
		CommandCounterIncrement();

		parsetree_list = gen_sp_droprole_subcmds(lowercase_rolname);

		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 16;

			/* do this step */
			ProcessUtility(wrapper,
						   "(DROP ROLE )",
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		PG_RE_THROW();
	}
	PG_END_TRY();
	set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	PG_RETURN_VOID();
}

static List *
gen_sp_droprole_subcmds(const char *user)
{
	StringInfoData query;
	List	   *res;
	Node	   *stmt;
	DropRoleStmt *dropstmt;

	initStringInfo(&query);
	appendStringInfo(&query, "DROP ROLE dummy; ");
	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if (list_length(res) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing", list_length(res))));

	stmt = parsetree_nth_stmt(res, 0);
	dropstmt = (DropRoleStmt *) stmt;

	if (!IsA(dropstmt, DropRoleStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a DropRoleStmt")));

	if (user && dropstmt->roles)
	{
		RoleSpec   *tmp;

		/* Update the statement with given role name */
		tmp = (RoleSpec *) llast(dropstmt->roles);
		tmp->rolename = pstrdup(user);
	}
	return res;
}

Datum
sp_addrolemember(PG_FUNCTION_ARGS)
{
	char	   *rolname,
			   *lowercase_rolname;
	char	   *membername,
			   *lowercase_membername;
	size_t		len;
	char	   *physical_member_name;
	char	   *physical_role_name;
	Oid			role_oid,
				member_oid;
	List	   *parsetree_list;
	ListCell   *parsetree_item;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		rolname = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		membername = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));

		/* Role name, member name is not NULL */
		if (rolname == NULL || membername == NULL)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/*
		 * Ensure the database name input argument is lower-case, as all Babel
		 * role names, user names are lower-case
		 */
		lowercase_rolname = lowerstr(rolname);
		lowercase_membername = lowerstr(membername);

		/* Remove trailing whitespaces in rolename and membername */
		len = strlen(lowercase_rolname);
		while (isspace(lowercase_rolname[len - 1]))
			lowercase_rolname[--len] = 0;
		len = strlen(lowercase_membername);
		while (isspace(lowercase_membername[len - 1]))
			lowercase_membername[--len] = 0;

		/*
		 * check if rolename/membername is empty after removing trailing
		 * spaces
		 */
		if (strlen(lowercase_rolname) == 0 || strlen(lowercase_membername) == 0)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/* Throws an error if role name and member name are same */
		if (strcmp(lowercase_rolname, lowercase_membername) == 0)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("Cannot make a role a member of itself.")));

		/* Map the logical member name to its physical name in the database. */
		physical_member_name = get_physical_user_name(get_cur_db_name(), lowercase_membername);
		member_oid = get_role_oid(physical_member_name, true);

		/*
		 * Check if the user, group or role does not exists and given member
		 * name is an role or user
		 */
		if (member_oid == InvalidOid || (!is_role(member_oid) && !is_user(member_oid)))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("User or role '%s' does not exist in this database.", membername)));

		/* Map the logical role name to its physical name in the database. */
		physical_role_name = get_physical_user_name(get_cur_db_name(), lowercase_rolname);
		role_oid = get_role_oid(physical_role_name, true);

		/* Check if the role does not exists and given role name is an role */
		if (role_oid == InvalidOid || !is_role(role_oid))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("Cannot alter the role '%s', because it does not exist or you do not have permission.", rolname)));

		/* Check if the member oid is already a member of given role oid */
		if (is_member_of_role_nosuper(role_oid, member_oid))
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("Cannot make a role a member of itself.")));

		/* Advance cmd counter to make the delete visible */
		CommandCounterIncrement();

		parsetree_list = gen_sp_addrolemember_subcmds(lowercase_rolname, lowercase_membername);

		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 16;

			/* do this step */
			ProcessUtility(wrapper,
						   "(ALTER ROLE )",
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		PG_RE_THROW();
	}
	PG_END_TRY();
	set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	PG_RETURN_VOID();
}

static List *
gen_sp_addrolemember_subcmds(const char *user, const char *member)
{
	StringInfoData query;
	List	   *res;
	Node	   *stmt;
	AccessPriv *granted;
	RoleSpec   *grantee;
	GrantRoleStmt *grant_role;

	initStringInfo(&query);
	appendStringInfo(&query, "ALTER ROLE dummy ADD MEMBER dummy; ");
	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if (list_length(res) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing", list_length(res))));

	stmt = parsetree_nth_stmt(res, 0);
	grant_role = (GrantRoleStmt *) stmt;
	granted = (AccessPriv *) linitial(grant_role->granted_roles);

	/* This is ALTER ROLE statement */
	grantee = (RoleSpec *) linitial(grant_role->grantee_roles);

	/* Rewrite granted and grantee roles */
	pfree(granted->priv_name);
	granted->priv_name = (char *) user;

	pfree(grantee->rolename);
	grantee->rolename = (char *) member;

	rewrite_object_refs(stmt);

	return res;
}

Datum
sp_droprolemember(PG_FUNCTION_ARGS)
{
	char	   *rolname,
			   *lowercase_rolname;
	char	   *membername,
			   *lowercase_membername;
	size_t		len;
	char	   *physical_name;
	Oid			role_oid;
	List	   *parsetree_list;
	ListCell   *parsetree_item;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		rolname = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		membername = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));

		/* Role name, member name is not NULL */
		if (rolname == NULL || membername == NULL)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/*
		 * Ensure the database name input argument is lower-case, as all Babel
		 * role names, user names are lower-case
		 */
		lowercase_rolname = lowerstr(rolname);
		lowercase_membername = lowerstr(membername);

		/* Remove trailing whitespaces in rolename and membername */
		len = strlen(lowercase_rolname);
		while (isspace(lowercase_rolname[len - 1]))
			lowercase_rolname[--len] = 0;
		len = strlen(lowercase_membername);
		while (isspace(lowercase_membername[len - 1]))
			lowercase_membername[--len] = 0;

		/*
		 * check if rolename/membername is empty after removing trailing
		 * spaces
		 */
		if (strlen(lowercase_rolname) == 0 || strlen(lowercase_membername) == 0)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Name cannot be NULL.")));

		/* Map the logical role name to its physical name in the database. */
		physical_name = get_physical_user_name(get_cur_db_name(), lowercase_rolname);
		role_oid = get_role_oid(physical_name, true);

		/* Throw an error id the given role name doesn't exist or isn't a role */
		if (role_oid == InvalidOid || !is_role(role_oid))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("Cannot alter the role '%s', because it does not exist or you do not have permission.", rolname)));

		/* Map the logical member name to its physical name in the database. */
		physical_name = get_physical_user_name(get_cur_db_name(), lowercase_membername);
		role_oid = get_role_oid(physical_name, true);

		/*
		 * Throw an error id the given member name doesn't exist or isn't a
		 * role or user
		 */
		if (role_oid == InvalidOid || (!is_role(role_oid) && !is_user(role_oid)))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("Cannot drop the principal '%s', because it does not exist or you do not have permission.", membername)));

		/* Advance cmd counter to make the delete visible */
		CommandCounterIncrement();

		parsetree_list = gen_sp_droprolemember_subcmds(lowercase_rolname, lowercase_membername);

		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 16;

			/* do this step */
			ProcessUtility(wrapper,
						   "(ALTER ROLE )",
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		PG_RE_THROW();
	}
	PG_END_TRY();
	set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	PG_RETURN_VOID();
}

static List *
gen_sp_droprolemember_subcmds(const char *user, const char *member)
{
	StringInfoData query;
	List	   *res;
	Node	   *stmt;
	AccessPriv *granted;
	RoleSpec   *grantee;
	GrantRoleStmt *grant_role;

	initStringInfo(&query);
	appendStringInfo(&query, "ALTER ROLE dummy DROP MEMBER dummy; ");
	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if (list_length(res) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing", list_length(res))));

	stmt = parsetree_nth_stmt(res, 0);
	grant_role = (GrantRoleStmt *) stmt;
	granted = (AccessPriv *) linitial(grant_role->granted_roles);

	/* This is ALTER ROLE statement */
	grantee = (RoleSpec *) linitial(grant_role->grantee_roles);

	/* Rewrite granted and grantee roles */
	pfree(granted->priv_name);
	granted->priv_name = (char *) user;

	pfree(grantee->rolename);
	grantee->rolename = (char *) member;

	rewrite_object_refs(stmt);
	return res;
}

static void 
update_bbf_server_options(char *servername, char *optname, char *optvalue, bool isInsert)
{
	Relation	bbf_servers_def_rel;
	TupleDesc	bbf_servers_def_rel_dsc;
	Datum		new_record[BBF_SERVERS_DEF_NUM_COLS];
	bool		new_record_nulls[BBF_SERVERS_DEF_NUM_COLS];
	bool		new_record_repl[BBF_SERVERS_DEF_NUM_COLS];
	ScanKeyData		key;
	HeapTuple		tuple, old_tuple;
	TableScanDesc	tblscan;

	if (optname != NULL && strlen(optname) == 13 && strncmp(optname, "query timeout", 13) == 0)
	{
		int32		query_timeout;
		
		if (optvalue == NULL || strspn(optvalue, "0123456789") != strlen(optvalue))
			ereport(ERROR,
					(errcode(ERRCODE_FDW_ERROR),
					 errmsg("Invalid option value for query timeout")));
		else
			query_timeout = atoi(optvalue);

		if (query_timeout < 0)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_ERROR),
					 errmsg("Query timeout value provided is out of range")));

		bbf_servers_def_rel = table_open(get_bbf_servers_def_oid(),
									 	RowExclusiveLock);
		bbf_servers_def_rel_dsc = RelationGetDescr(bbf_servers_def_rel);

		MemSet(new_record_nulls, false, sizeof(new_record_nulls));
		MemSet(new_record_repl, false, sizeof(new_record_repl));

		new_record[Anum_bbf_servers_def_servername - 1] = CStringGetTextDatum(servername);
		new_record[Anum_bbf_servers_def_query_timeout - 1] = Int32GetDatum(query_timeout);

		if(isInsert)
		{
			tuple = heap_form_tuple(bbf_servers_def_rel_dsc,
									new_record, new_record_nulls);
			CatalogTupleInsert(bbf_servers_def_rel, tuple);
		}
		else
		{
			/* Search and obtain the tuple based on the server_id */	
			ScanKeyInit(&key,
						Anum_bbf_servers_def_servername,
						BTEqualStrategyNumber, F_TEXTEQ,
						CStringGetTextDatum(servername));
			tblscan = table_beginscan_catalog(bbf_servers_def_rel, 1, &key);
			old_tuple = heap_getnext(tblscan, ForwardScanDirection);

			if (!old_tuple)
			{
				table_endscan(tblscan);
				table_close(bbf_servers_def_rel, RowExclusiveLock);
				ereport(ERROR,
						(errcode(ERRCODE_FDW_ERROR),
				 		errmsg("server \"%s\" does not exist", servername)));
			}
			new_record_repl[Anum_bbf_servers_def_query_timeout - 1] = true;
			tuple = heap_modify_tuple(old_tuple, bbf_servers_def_rel_dsc,
									new_record, new_record_nulls, new_record_repl);
			
			CatalogTupleUpdate(bbf_servers_def_rel, &tuple->t_self, tuple);
			table_endscan(tblscan);
		}

		heap_freetuple(tuple);

		table_close(bbf_servers_def_rel, RowExclusiveLock);
	}
}

static void 
clean_up_bbf_server_option(char *servername)
{
	Relation		bbf_servers_def_rel;
	HeapTuple		scantup;
	ScanKeyData		key;
	TableScanDesc		tblscan;

	/* Fetch the relation */
	bbf_servers_def_rel = table_open(get_bbf_servers_def_oid(), RowExclusiveLock);

	/* Search and drop the definition */
	ScanKeyInit(&key,
				Anum_bbf_servers_def_servername,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(servername));

	tblscan = table_beginscan_catalog(bbf_servers_def_rel, 1, &key);
	scantup = heap_getnext(tblscan, ForwardScanDirection);
	if (HeapTupleIsValid(scantup))
	{
		CatalogTupleDelete(bbf_servers_def_rel, &scantup->t_self);
	}
	table_endscan(tblscan);
	table_close(bbf_servers_def_rel, RowExclusiveLock);
}

Datum
sp_addlinkedserver_internal(PG_FUNCTION_ARGS)
{
	char	   *linked_server = PG_ARGISNULL(0) ? NULL : lowerstr(text_to_cstring(PG_GETARG_TEXT_P(0)));
	char	   *srv_product = PG_ARGISNULL(1) ? NULL : lowerstr(text_to_cstring(PG_GETARG_TEXT_P(1)));
	char	   *provider = PG_ARGISNULL(2) ? NULL : lowerstr(text_to_cstring(PG_GETARG_TEXT_P(2)));
	char	   *data_src = PG_ARGISNULL(3) ? NULL : text_to_cstring(PG_GETARG_TEXT_P(3));
	char	   *provstr = PG_ARGISNULL(5) ? NULL : text_to_cstring(PG_GETARG_TEXT_P(5));
	char	   *catalog = PG_ARGISNULL(6) ? NULL : text_to_cstring(PG_GETARG_TEXT_P(6));

	StringInfoData query;

	bool		provider_warning = false,
				provstr_warning = false;

	if (!pltsql_enable_linked_servers)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("'sp_addlinkedserver' is not currently supported in Babelfish")));

	if (linked_server == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("@server parameter cannot be NULL")));

	if (srv_product && (strlen(srv_product) == 10) && (strncmp(srv_product, "sql server", 10) == 0))
	{
		/*
		 * if server product is "SQL Server", rest of the arguments need not
		 * be specified except the linked server name. The linked server name
		 * in such a case, also doubles up as the linked server data source.
		 */
		data_src = pstrdup(linked_server);
	}
	else
	{
		if (provider && (((strlen(provider) == 7) && (strncmp(provider, "sqlncli", 7) == 0)) ||
						 ((strlen(provider) == 10) && (strncmp(provider, "msoledbsql", 10) == 0)) ||
						 ((strlen(provider) == 8) && (strncmp(provider, "sqloledb", 8) == 0))))
		{
			/*
			 * if provider is a valid T-SQL provider, we throw a warning
			 * indicating internally, we will be using tds_fdw
			 */
			provider_warning = true;
		}
		else if (!provider || (strlen(provider) != 7) || (strncmp(provider, "tds_fdw", 7) != 0))
			ereport(ERROR,
					(errcode(ERRCODE_FDW_ERROR),
					 errmsg("Unsupported provider '%s'. Supported provider is 'tds_fdw'", provider)));

		if (provstr != NULL)
		{
			/* we ignore provider string in any case */
			provstr_warning = true;
		}
	}

	initStringInfo(&query);

	/*
	 * We prepare the following query to create a foreign server. This will be
	 * executed using ProcessUtility():
	 *
	 * CREATE SERVER <server name> FOREIGN DATA WRAPPER tds_fdw OPTIONS
	 * (servername '<remote data source endpoint>', database '<catalog name>')
	 *
	 */
	appendStringInfo(&query, "CREATE SERVER \"%s\" FOREIGN DATA WRAPPER tds_fdw ", linked_server);

	/* Add the relevant options */
	if (data_src || catalog)
	{
		appendStringInfoString(&query, "OPTIONS ( ");

		/*
		 * The servername option is required for foreign server creation, but
		 * we leave it to the FDW's validator function to check for that
		 */
		if (data_src)
			appendStringInfo(&query, "servername '%s' ", data_src);

		if (catalog)
		{
			if (data_src)
				appendStringInfoString(&query, ", ");

			appendStringInfo(&query, "database '%s' ", catalog);
		}

		appendStringInfoString(&query, ")");
	}

	exec_utility_cmd_helper(query.data);

	update_bbf_server_options(linked_server, "query timeout", "0", true);

	/* We throw warnings only if foreign server object creation succeeds */
	if (provider_warning)
		report_info_or_warning(WARNING, "Warning: Using the TDS Foreign data wrapper (tds_fdw) as provider");

	if (provstr_warning)
		report_info_or_warning(WARNING, "Warning: Ignoring @provstr argument value");

	if (linked_server)
		pfree(linked_server);

	if (srv_product)
		pfree(srv_product);

	if (provider)
		pfree(provider);

	if (data_src)
		pfree(data_src);

	if (provstr)
		pfree(provstr);

	if (catalog)
		pfree(catalog);

	pfree(query.data);

	return (Datum) 0;
}

Datum
sp_addlinkedsrvlogin_internal(PG_FUNCTION_ARGS)
{
	char	   *servername = PG_ARGISNULL(0) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(0)));
	char	   *useself = PG_ARGISNULL(1) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(1)));
	char	   *locallogin = PG_ARGISNULL(2) ? NULL : text_to_cstring(PG_GETARG_VARCHAR_PP(2));
	char	   *username = PG_ARGISNULL(3) ? NULL : text_to_cstring(PG_GETARG_VARCHAR_PP(3));
	char	   *password = PG_ARGISNULL(4) ? NULL : text_to_cstring(PG_GETARG_VARCHAR_PP(4));

	StringInfoData query;

	if (!pltsql_enable_linked_servers)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("'sp_addlinkedsrvlogin' is not currently supported in Babelfish")));

	if (servername == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("@rmtsrvname parameter cannot be NULL")));

	/* We do not support login using user's self credentials */
	if ((useself == NULL) || (strlen(useself) != 5) || (strncmp(useself, "false", 5) != 0))
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("Only @useself = FALSE is supported. Remote login using user's self credentials is not supported.")));

	if (locallogin != NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Only @locallogin = NULL is supported. Configuring remote server access specific to local login is not yet supported")));

	initStringInfo(&query);

	/*
	 * We prepare the following query to create a user mapping. This will be
	 * executed using ProcessUtility():
	 *
	 * CREATE USER MAPPING FOR CURRENT_USER SERVER <servername> OPTIONS
	 * (username '<remote server user name>', password '<remote server user
	 * password>')
	 *
	 */
	appendStringInfo(&query, "CREATE USER MAPPING FOR CURRENT_USER SERVER \"%s\" ", servername);

	/*
	 * Add the relevant options
	 *
	 * The username and password options are required for user mapping
	 * creation, (according to tds_fdw documentation) but we leave it to the
	 * FDW's validator function to check for that
	 */
	if (username || password)
	{
		appendStringInfoString(&query, "OPTIONS ( ");

		if (username)
			appendStringInfo(&query, "username '%s' ", username);

		if (password)
		{
			if (username)
				appendStringInfoString(&query, ", ");

			appendStringInfo(&query, "password '%s' ", password);
		}

		appendStringInfoString(&query, ")");
	}

	exec_utility_cmd_helper(query.data);

	if (servername)
		pfree(servername);

	if (useself)
		pfree(useself);

	if (username)
		pfree(username);

	if (password)
		pfree(password);

	pfree(query.data);

	return (Datum) 0;
}

Datum
sp_droplinkedsrvlogin_internal(PG_FUNCTION_ARGS)
{
	char	   *servername = PG_ARGISNULL(0) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(0)));
	char	   *locallogin = PG_ARGISNULL(1) ? NULL : text_to_cstring(PG_GETARG_VARCHAR_PP(1));

	StringInfoData query;

	if (!pltsql_enable_linked_servers)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("'sp_droplinkedsrvlogin' is not currently supported in Babelfish")));

	if (servername == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("@servername cannot be NULL")));

	if (locallogin != NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Only @locallogin = NULL is supported. Configuring remote server access specific to local login is not yet supported")));

	initStringInfo(&query);

	/*
	 * We prepare the following query to drop a linked server login. This will
	 * be executed using ProcessUtility():
	 *
	 * DROP USER MAPPING FOR CURRENT_USER SERVER @SERVERNAME
	 *
	 */
	appendStringInfo(&query, "DROP USER MAPPING FOR CURRENT_USER SERVER \"%s\"", servername);

	exec_utility_cmd_helper(query.data);

	if (locallogin)
		pfree(locallogin);

	if (servername)
		pfree(servername);

	return (Datum) 0;
}

Datum
sp_dropserver_internal(PG_FUNCTION_ARGS)
{
	char	   *linked_srv = PG_ARGISNULL(0) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(0)));
	char	   *droplogins = PG_ARGISNULL(1) ? NULL : lowerstr(text_to_cstring(PG_GETARG_BPCHAR_PP(1)));

	StringInfoData query;

	if (!pltsql_enable_linked_servers)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("'sp_dropserver' is not currently supported in Babelfish")));

	if (linked_srv == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("@server parameter cannot be NULL")));

	initStringInfo(&query);

	/*
	 * We prepare the following query to drop foreign server. This will be
	 * executed using ProcessUtility():
	 *
	 * DROP SERVER <servername> CASCADE
	 *
	 * linked logins along with server are dropped if @droplogins = 'NULL' or
	 * @droplogins = 'droplogins' so we add CASCADE.
	 */
	if ((droplogins == NULL) || ((strlen(droplogins) == 10) && (strncmp(droplogins, "droplogins", 10) == 0)))
	{
		/* Remove the server entry from sys.babelfish_server_options catalog */
		appendStringInfo(&query, "DROP SERVER \"%s\" CASCADE", linked_srv);

		exec_utility_cmd_helper(query.data);
		clean_up_bbf_server_option(linked_srv);
		pfree(query.data);

		if (linked_srv)
			pfree(linked_srv);

		if (droplogins)
			pfree(droplogins);

	}
	else
	{
		pfree(query.data);

		if (linked_srv)
			pfree(linked_srv);

		if (droplogins)
			pfree(droplogins);

		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("Invalid parameter value for @droplogins specified in procedure 'sys.sp_dropserver', acceptable values are 'droplogins' or NULL.")));
	}

	return (Datum) 0;
}

Datum
sp_serveroption_internal(PG_FUNCTION_ARGS)
{
	char *servername = PG_ARGISNULL(0) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(0)));
	char *optionname = PG_ARGISNULL(1) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(1)));
	char *optionvalue = PG_ARGISNULL(2) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(2)));

	if(!pltsql_enable_linked_servers)
		ereport(ERROR,
			(errcode(ERRCODE_FDW_ERROR),
				errmsg("'sp_serveroption' is not currently supported in Babelfish")));

	if (servername == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("@server parameter cannot be NULL")));

	if (optionname == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("@optname parameter cannot be NULL")));

	if (optionvalue == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("@optvalue parameter cannot be NULL")));

	if (optionname && strlen(optionname) == 13 && strncmp(optionname, "query timeout", 13) == 0)
		update_bbf_server_options(servername, optionname, optionvalue, false);
	else
		ereport(ERROR,
			(errcode(ERRCODE_FDW_ERROR),
				errmsg("Invalid option provided for sp_serveroption")));

	if(servername)
		pfree(servername);

	if(optionname)
		pfree(optionname);

	if(optionvalue)
		pfree(optionvalue);

	return (Datum) 0;
}

Datum
sp_babelfish_volatility(PG_FUNCTION_ARGS)
{
	int			rc;
	int			i;
	char	   *db_name = get_cur_db_name();
	char	   *function_signature = NULL;
	char	   *query = NULL;
	char	   *function_name = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
	char	   *volatility = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));
	Oid			function_id;
	Oid			user_id = GetUserId();

	if (function_name != NULL)
	{
		/* strip trailing whitespace */
		remove_trailing_spaces(function_name);

		/* if function name is empty */
		i = strlen(function_name);
		if (i == 0)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("function name is not valid")));

		/* length should be restricted to 4000 */
		if (i > 4000)
			ereport(ERROR,
					(errcode(ERRCODE_STRING_DATA_LENGTH_MISMATCH),
					 errmsg("input value is too long for function name")));
	}
	if (volatility != NULL)
	{
		/* strip trailing whitespace */
		remove_trailing_spaces(volatility);

		/* if volatility is empty */
		i = strlen(volatility);
		if (i == 0)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("volatility is not valid")));

		/* its length is greater than 9 (len of immutable) */
		if (i > 9)
			ereport(ERROR,
					(errcode(ERRCODE_STRING_DATA_LENGTH_MISMATCH),
					 errmsg("input value is too long for volatility")));
	}
	if (function_name == NULL && volatility != NULL)
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("function name cannot be NULL")));

	if (function_name != NULL)
	{
		List	   *function_name_list;
		FuncCandidateList candidates = NULL;
		char	   *full_function_name = NULL;
		char	   *logical_schema_name = NULL;
		char	   *physical_schema_name = NULL;
		char	  **splited_object_name;

		/* get physical schema name */
		splited_object_name = split_object_name(function_name);

		if (strcmp(splited_object_name[0], "") || strcmp(splited_object_name[1], ""))
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("function \"%s\" is not a valid two part name", function_name)));

		pfree(function_name);
		logical_schema_name = splited_object_name[2];
		function_name = splited_object_name[3];

		/* downcase identifier */
		if (pltsql_case_insensitive_identifiers)
		{
			logical_schema_name = downcase_identifier(logical_schema_name, strlen(logical_schema_name), false, false);
			function_name = downcase_identifier(function_name, strlen(function_name), false, false);
			for (int i = 0; i < 4; i++)
				pfree(splited_object_name[i]);
		}
		else
		{
			pfree(splited_object_name[0]);
			pfree(splited_object_name[1]);
		}
		pfree(splited_object_name);

		/* truncate identifiers if needed */
		truncate_tsql_identifier(logical_schema_name);
		truncate_tsql_identifier(function_name);

		if (!strcmp(function_name, ""))
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("function name is not valid")));

		/* find the default schema for current user */
		if (!strcmp(logical_schema_name, ""))
		{
			const char *user = get_user_for_database(db_name);
			const char *guest_role_name = get_guest_role_name(db_name);

			if (!user)
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_OBJECT),
						 errmsg("user does not exist")));

			pfree(logical_schema_name);
			if ((guest_role_name && strcmp(user, guest_role_name) == 0))
			{
				physical_schema_name = pstrdup(get_guest_schema_name(db_name));
			}
			else
			{
				logical_schema_name = get_authid_user_ext_schema_name((const char *) db_name, user);
				physical_schema_name = get_physical_schema_name(db_name, logical_schema_name);
				pfree(logical_schema_name);
			}
		}
		else
		{
			physical_schema_name = get_physical_schema_name(db_name, logical_schema_name);
			pfree(logical_schema_name);
		}

		/* get function id from function name */
		function_name_list = list_make2(makeString(physical_schema_name), makeString(function_name));
		candidates = FuncnameGetCandidates(function_name_list, -1, NIL, false, false, false, true);

		/* if no function is found */
		if (candidates == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("function does not exist")));

		/* check if the current user has priviledge on the function */
		if (pg_proc_aclcheck(candidates->oid, user_id, ACL_EXECUTE) != ACLCHECK_OK)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("current user does not have priviledges on the function")));

		/* check if multiple function with same function name exits */
		if (candidates->next != NULL)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("multiple functions with same function name exits")));

		function_id = candidates->oid;
		full_function_name = psprintf("\"%s\".\"%s\"", physical_schema_name, function_name);
		function_signature = (char *) get_pltsql_function_signature_internal(full_function_name, candidates->nargs, candidates->args);

		list_free(function_name_list);
		pfree(candidates);
		pfree(full_function_name);
		pfree(physical_schema_name);
	}

	/*
	 * If both volatility and function name is not provided then it will
	 * return a list of functions present in current database. else if only
	 * volatility is not provided the it will return the volatility of the
	 * specified function. If both volatility and function name is provided it
	 * will set the function volatility to the specified volatility
	 */
	if (volatility == NULL)
	{
		if (function_name == NULL)
		{
			query = psprintf(
							 "SELECT t3.orig_name as SchemaName, t1.proname as FunctionName, "
							 "CASE "
							 "WHEN t1.provolatile = 'v' THEN 'volatile' "
							 "WHEN t1.provolatile = 's' THEN 'stable' "
							 "ELSE 'immutable' "
							 "END AS Volatility "
							 "from pg_proc t1 "
							 "JOIN pg_namespace t2 ON t1.pronamespace = t2.oid "
							 "JOIN sys.babelfish_namespace_ext t3 ON t3.nspname = t2.nspname "
							 "where has_function_privilege(t1.oid, CAST('EXECUTE' as text)) "
							 "AND t3.dbid = sys.db_id() AND prokind = 'f' "
							 "ORDER BY t3.orig_name, t1.proname"
				);
		}
		else
		{
			query = psprintf(
							 "SELECT t3.orig_name as SchemaName, CAST('%s' as sys.varchar) as FunctionName, "
							 "CASE "
							 "WHEN provolatile = 'v' THEN 'volatile' "
							 "WHEN provolatile = 's' THEN 'stable' "
							 "ELSE 'immutable' "
							 "END AS Volatility from pg_proc t1 "
							 "JOIN pg_namespace t2 ON t1.pronamespace = t2.oid "
							 "JOIN sys.babelfish_namespace_ext t3 ON t3.nspname = t2.nspname "
							 "where t1.oid = %u", function_name, function_id
				);
		}

		PG_TRY();
		{
			char		nulls = 0;
			MemoryContext savedPortalCxt;
			SPIPlanPtr	plan;
			Portal		portal;
			DestReceiver *receiver;

			savedPortalCxt = PortalContext;
			if (PortalContext == NULL)
				PortalContext = MessageContext;
			if ((rc = SPI_connect()) != SPI_OK_CONNECT)
			{
				PortalContext = savedPortalCxt;
				elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
			}
			PortalContext = savedPortalCxt;

			if ((plan = SPI_prepare(query, 0, NULL)) == NULL)
				elog(ERROR, "SPI_prepare(\"%s\") failed", query);

			if ((portal = SPI_cursor_open(NULL, plan, NULL, &nulls, true)) == NULL)
				elog(ERROR, "SPI_cursor_open(\"%s\") failed", query);

			/*
			 * According to specifictation, sp_babelfish_volatility returns a
			 * result-set. If there is no destination, it will send the
			 * result-set to client, which is not allowed behavior of PG
			 * procedures. To implement this behavior, we added a code to push
			 * the result.
			 */
			receiver = CreateDestReceiver(DestRemote);
			SetRemoteDestReceiverParams(receiver, portal);

			/* fetch the result and return the result-set */
			PortalRun(portal, FETCH_ALL, true, true, receiver, receiver, NULL);

			receiver->rDestroy(receiver);
			SPI_cursor_close(portal);

			if ((rc = SPI_finish()) != SPI_OK_FINISH)
				elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));
		}
		PG_CATCH();
		{
			SPI_finish();
			PG_RE_THROW();
		}
		PG_END_TRY();
	}
	else
	{
		/* downcase identifier if needed */
		volatility = downcase_identifier(volatility, strlen(volatility), false, false);

		if (strcmp(volatility, "volatile") && strcmp(volatility, "stable") && strcmp(volatility, "immutable"))
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("\"%s\" is not a valid volatility", volatility)));

		query = psprintf("ALTER FUNCTION %s %s;", function_signature, volatility);

		PG_TRY();
		{
			if ((rc = SPI_connect()) != SPI_OK_CONNECT)
				elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));

			if ((rc = SPI_execute(query, false, 1)) < 0)
				elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

			if ((rc = SPI_finish()) != SPI_OK_FINISH)
				elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));
		}
		PG_CATCH();
		{
			SPI_finish();
			PG_RE_THROW();
		}
		PG_END_TRY();
	}

	if (function_name)
	{
		pfree(function_name);
		pfree(function_signature);
	}
	if (volatility)
		pfree(volatility);
	if (query)
		pfree(query);
	pfree(db_name);

	PG_RETURN_VOID();
}

extern bool pltsql_quoted_identifier;

Datum
sp_rename_internal(PG_FUNCTION_ARGS)
{
	char	   *obj_name,
			   *new_name,
			   *schema_name,
			   *objtype,
			   *curr_relname,
			   *process_util_querystr;
	ObjectType	objtype_code;
	size_t		len;
	List	   *parsetree_list;
	ListCell   *parsetree_item;
	const char *saved_dialect = GetConfigOption("babelfish_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		/* 1. set dialect to TSQL */
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		/* 2. read the input arguments */
		obj_name = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		new_name = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));
		schema_name = PG_ARGISNULL(2) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(2));
		objtype = PG_ARGISNULL(3) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(3));
		curr_relname = PG_ARGISNULL(4) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(4));

		/* 3. check if the input arguments are valid, and parse the objname */
		/* objname can have at most 3 parts */
		if (obj_name == NULL)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Procedure or function 'sp_rename' expects parameter '@objname', which was not supplied.")));
		if (new_name == NULL)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Procedure or function 'sp_rename' expects parameter '@newname', which was not supplied.")));
		if (objtype == NULL)
			objtype = "OBJECT";

		/* remove trailing whitespaces for both input */
		len = strlen(obj_name);
		while (isspace(obj_name[len - 1]))
			obj_name[--len] = 0;
		len = strlen(schema_name);
		while (isspace(schema_name[len - 1]))
			schema_name[--len] = 0;
		len = strlen(new_name);
		while (isspace(new_name[len - 1]))
			new_name[--len] = 0;
		len = strlen(objtype);
		while (isspace(objtype[len - 1]))
			objtype[--len] = 0;
		if (curr_relname != NULL) {
			len = strlen(curr_relname);
			while(isspace(curr_relname[len - 1]))
				curr_relname[--len] = 0;
		}

		/* remove delimited identifiers if quoted_identifier is on */
		if (pltsql_quoted_identifier)
		{
			remove_delimited_identifer(obj_name);
			remove_delimited_identifer(schema_name);
			if (curr_relname != NULL) {
				remove_delimited_identifer(curr_relname);
			}
		}

		/* check if inputs are empty after removing trailing spaces */
		if (obj_name == NULL)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Procedure or function 'sp_rename' expects parameter '@objname', which was not supplied.")));
		if (new_name == NULL || strlen(new_name) == 0)
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("Procedure or function 'sp_rename' expects parameter '@newname', which was not supplied.")));

		/* 4. for each obj type, generate the corresponding RenameStmt */
		/* update variables based on the target objtype */
		if (strcmp(objtype, "U") == 0 || strcmp(objtype, "IT") == 0 || strcmp(objtype, "S") == 0 ||
			strcmp(objtype, "ET") == 0 || strcmp(objtype, "TT") == 0)
		{
			objtype_code = OBJECT_TABLE;
			process_util_querystr = "(ALTER TABLE )";
		}
		else if (strcmp(objtype, "V") == 0)
		{
			objtype_code = OBJECT_VIEW;
			process_util_querystr = "(ALTER VIEW )";
		}
		else if (strcmp(objtype, "P") == 0 || strcmp(objtype, "PC") == 0 || strcmp(objtype, "RF") == 0 ||
				 strcmp(objtype, "X") == 0)
		{
			objtype_code = OBJECT_PROCEDURE;
			process_util_querystr = "(ALTER PROCEDURE )";
		}
		else if (strcmp(objtype, "AF") == 0 || strcmp(objtype, "FN") == 0 || strcmp(objtype, "FS") == 0 ||
				 strcmp(objtype, "FT") == 0 || strcmp(objtype, "IF") == 0 || strcmp(objtype, "TF") == 0)
		{
			objtype_code = OBJECT_FUNCTION;
			process_util_querystr = "(ALTER FUNCTION )";
		}
		else if (strcmp(objtype, "SO") == 0)
		{
			objtype_code = OBJECT_SEQUENCE;
			process_util_querystr = "(ALTER SEQUENCE )";
		}
		else if (strcmp(objtype, "TA") == 0 || strcmp(objtype, "TR") == 0)
		{
			/* TRIGGER */
			objtype_code = OBJECT_TRIGGER;
			process_util_querystr = "(ALTER TRIGGER )";
		}
		else if (strcmp(objtype, "C") == 0 || strcmp(objtype, "D") == 0 || strcmp(objtype, "PK") == 0 ||
				 strcmp(objtype, "UQ") == 0 || strcmp(objtype, "EC") == 0)
		{
			/* CONSTRAINT */
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("Feature not supported: renaming object type Constraint")));
		}
		else if (strcmp(objtype, "AL") == 0)
		{
			/* USER DEFINED TYPES ALIAS*/
			objtype_code = OBJECT_TYPE;
			process_util_querystr = "(ALTER TYPE )";
		}
		else if (strcmp(objtype, "CO") == 0)
		{
			objtype_code = OBJECT_COLUMN;
			process_util_querystr = "(ALTER TABLE )";
		}
		else
		{
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("Provided '@objtype' is currently not supported in Babelfish.")));
		}


		/* Advance cmd counter to make the delete visible */
		CommandCounterIncrement();

		parsetree_list = gen_sp_rename_subcmds(obj_name, new_name, schema_name, objtype_code, curr_relname);

		/* 5. run all commands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 16;

			/* do this step */
			ProcessUtility(wrapper,
						   pstrdup(process_util_querystr),
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		PG_RE_THROW();
	}
	PG_END_TRY();
	set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	PG_RETURN_VOID();
}

extern const char *ATTOPTION_BBF_ORIGINAL_NAME;

static List *
gen_sp_rename_subcmds(const char *objname, const char *newname, const char *schemaname, ObjectType objtype, const char *curr_relname)
{
	StringInfoData query;
	List	   *res;
	Node	   *stmt;
	RenameStmt *renamestmt;

	initStringInfo(&query);
	switch (objtype)
	{
		case OBJECT_TABLE:
			appendStringInfo(&query, "ALTER TABLE dummy RENAME TO dummy; ");
			break;
		case OBJECT_VIEW:
			appendStringInfo(&query, "ALTER VIEW dummy RENAME TO dummy; ");
			break;
		case OBJECT_PROCEDURE:
			appendStringInfo(&query, "ALTER PROCEDURE dummy RENAME TO dummy; ");
			break;
		case OBJECT_FUNCTION:
			appendStringInfo(&query, "ALTER FUNCTION dummy RENAME TO dummy; ");
			break;
		case OBJECT_SEQUENCE:
			appendStringInfo(&query, "ALTER SEQUENCE dummy RENAME TO dummy; ");
			break;
		case OBJECT_TRIGGER:
			appendStringInfo(&query, "ALTER TRIGGER dummy ON dummy RENAME TO dummy; ");
			appendStringInfo(&query, "ALTER FUNCTION dummy RENAME TO dummy; ");
			break;
		case OBJECT_COLUMN:
			appendStringInfo(&query, "ALTER TABLE dummy RENAME COLUMN dummy TO dummy; ");
			appendStringInfo(&query, "ALTER TABLE dummy ALTER COLUMN dummy SET (dummy = 'dummy'); ");
			break;
		case OBJECT_TYPE:
			appendStringInfo(&query, "ALTER TYPE dummy RENAME TO dummy; ");
			break;
		default:
			ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Provided objtype is not supported for sp_rename")));
			break;
	}
	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if ((objtype != OBJECT_COLUMN) && (objtype != OBJECT_TRIGGER) && (list_length(res) != 1))
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing", list_length(res))));

	stmt = parsetree_nth_stmt(res, 0);

	renamestmt = (RenameStmt *) stmt;
	if (!IsA(renamestmt, RenameStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a RenameStmt")));

	if ((objtype == OBJECT_TABLE) || (objtype == OBJECT_VIEW) || (objtype == OBJECT_SEQUENCE))
	{
		renamestmt->renameType = objtype;
		renamestmt->subname = pstrdup(lowerstr(objname));
		renamestmt->newname = pstrdup(lowerstr(newname));
		renamestmt->relation->schemaname = pstrdup(lowerstr(schemaname));
		renamestmt->relation->relname = pstrdup(lowerstr(objname));
	}
	else if ((objtype == OBJECT_PROCEDURE) || (objtype == OBJECT_FUNCTION))
	{
		ObjectWithArgs *objwargs = (ObjectWithArgs *) renamestmt->object;

		renamestmt->renameType = objtype;
		objwargs->objname = list_make2(makeString(pstrdup(lowerstr(schemaname))), makeString(pstrdup(lowerstr(objname))));
		orig_proc_funcname = pstrdup(newname);
		renamestmt->subname = pstrdup(lowerstr(objname));
		renamestmt->newname = pstrdup(lowerstr(newname));
	}
	else if ((objtype == OBJECT_TRIGGER))
	{
		ObjectWithArgs *objwargs;
		renamestmt->renameType = objtype;
		renamestmt->relation->schemaname = pstrdup(lowerstr(schemaname));
		renamestmt->relation->relname = pstrdup(lowerstr(curr_relname));
		renamestmt->subname = pstrdup(lowerstr(objname));
		renamestmt->newname = pstrdup(lowerstr(newname));
		rewrite_object_refs(stmt);

		// extra query nodes for ALTER FUNCTION
		stmt = parsetree_nth_stmt(res, 1);
		renamestmt = (RenameStmt *) stmt;
		if (!IsA(renamestmt, RenameStmt))
			ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a RenameStmt")));
		objwargs = (ObjectWithArgs *) renamestmt->object;
		renamestmt->renameType = OBJECT_FUNCTION;
		objwargs->objname = list_make2(makeString(pstrdup(lowerstr(schemaname))), makeString(pstrdup(lowerstr(objname))));
		renamestmt->subname = pstrdup(lowerstr(objname));
		renamestmt->newname = pstrdup(lowerstr(newname));
	}
	else if (objtype == OBJECT_TYPE)
	{
		renamestmt->renameType = objtype;
		renamestmt->object = (Node *)list_make2(makeString(pstrdup(lowerstr(schemaname))), makeString(pstrdup(lowerstr(objname))));
		renamestmt->subname = pstrdup(lowerstr(objname));
		renamestmt->newname = pstrdup(lowerstr(newname));
	}
	else
	{
		/* COLUMN */
		AlterTableStmt *altertablestmt;
		AlterTableCmd *cmd;
		ListCell *lc = NULL;

		renamestmt->renameType = objtype;
		renamestmt->relationType = OBJECT_TABLE;
		renamestmt->subname = pstrdup(lowerstr(objname));
		renamestmt->newname = pstrdup(lowerstr(newname));
		renamestmt->relation->schemaname = pstrdup(lowerstr(schemaname));
		renamestmt->relation->relname = pstrdup(lowerstr(curr_relname));
		rewrite_object_refs(stmt);

		/* extra query nodes for modifying attoption column */
		stmt = parsetree_nth_stmt(res, 1);
		altertablestmt = (AlterTableStmt *) stmt;
		if (!IsA(altertablestmt, AlterTableStmt))
			ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a AlterTableStmt")));

		altertablestmt->relation->schemaname = pstrdup(lowerstr(schemaname));
		altertablestmt->relation->relname = pstrdup(lowerstr(curr_relname));
		altertablestmt->objtype = OBJECT_TABLE;
		/* get data of the first node */
		lc = list_head(altertablestmt->cmds);
		cmd = (AlterTableCmd *) lfirst(lc);
		cmd->subtype = AT_SetOptions;
		cmd->name = pstrdup(lowerstr(newname));
		cmd->def = (Node *) list_make1(makeDefElem(pstrdup(ATTOPTION_BBF_ORIGINAL_NAME), (Node *) makeString(pstrdup(newname)), -1)); //column->location));
	}
	/* name mapping */
	rewrite_object_refs(stmt);

	return res;
}

static void 
remove_delimited_identifer(char *str)
{
	size_t len = strlen(str);
	if ((str[0] == '"' && str[len - 1] == '"') || (str[0] == '[' && str[len - 1] == ']'))
	{
		memmove(str, &str[1], len - 1);
		str[len - 2] = '\0';
	}
	if isspace(str[0])
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
						errmsg("Either the parameter @objname is ambiguous or the claimed @objtype (COLUMN) is wrong.")));
	len = strlen(str);
	while (isspace(str[len - 1]))
		str[--len] = 0;
}