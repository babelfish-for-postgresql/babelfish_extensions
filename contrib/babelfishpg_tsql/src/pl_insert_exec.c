/*-------------------------------------------------------------------------
 *
 * pl_insert_exec.c
 *	  INSERT EXECUTE implementation for Babelfish PL/tsql
 *
 * This file contains all logic for the INSERT INTO <target> EXEC <proc>
 * statement redesign. It implements:
 *   - InsertExecContext: global state tracking for an active INSERT EXEC
 *   - DestReceiver (DR_insertexec): captures procedure output into a
 *     session-local temp table
 *   - Temp table lifecycle: creation, schema inference, flush, and drop
 *   - Context management accessors used across pl_exec.c, hooks.c, and
 *     the TDS layer
 *
 *-------------------------------------------------------------------------
 */

/* Include pltsql.h first to define types used by pltsql-2.h */
#include "pltsql.h"
#include "pltsql-2.h"

#include "funcapi.h"

#include "access/parallel.h"
#include "access/table.h"
#include "parser/parser.h"
#include "access/tableam.h"
#include "access/attmap.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_attribute.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_proc.h"
#include "executor/executor.h"
#include "executor/spi_priv.h"
#include "executor/tstoreReceiver.h"
#include "executor/tuptable.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/parsenodes.h"
#include "optimizer/optimizer.h"
#include "parser/parse_coerce.h"
#include "tcop/dest.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "storage/lmgr.h"

#include "catalog.h"
#include "multidb.h"
#include "pltsql_permissions.h"
#include "session.h"
#include "parser/scansup.h"
#include "parser/parse_oper.h"
#include "utils/builtins.h"
#include "utils/varlena.h"

/* Forward declaration for exec_stmt_execsql from pl_exec.c */
extern int exec_stmt_execsql(PLtsql_execstate *estate, PLtsql_stmt_execsql *stmt);

/*
 * Strip timezone suffixes from format_type() output that are invalid in
 * CREATE TABLE statements (e.g., "without time zone").
 */
static char *
clean_format_type_string(const char *coltype)
{
	char *result;
	char *suffix_pos;

	if (coltype == NULL)
		return NULL;

	result = pstrdup(coltype);

	/* Strip " without time zone" suffix if present */
	suffix_pos = strstr(result, " without time zone");
	if (suffix_pos != NULL)
		*suffix_pos = '\0';

	/* Also strip " with time zone" suffix if present (for completeness) */
	suffix_pos = strstr(result, " with time zone");
	if (suffix_pos != NULL)
		*suffix_pos = '\0';

	/*
	 * Append "(max)" for varchar/nvarchar/varbinary without length modifier.
	 */
	if (strchr(result, '(') == NULL &&
		(strcmp(result, "sys.varchar") == 0 ||
		 strcmp(result, "sys.\"varchar\"") == 0 ||
		 strcmp(result, "varchar") == 0 ||
		 strcmp(result, "\"varchar\"") == 0 ||
		 strcmp(result, "sys.nvarchar") == 0 ||
		 strcmp(result, "sys.\"nvarchar\"") == 0 ||
		 strcmp(result, "nvarchar") == 0 ||
		 strcmp(result, "\"nvarchar\"") == 0 ||
		 strcmp(result, "sys.varbinary") == 0 ||
		 strcmp(result, "sys.\"varbinary\"") == 0 ||
		 strcmp(result, "varbinary") == 0 ||
		 strcmp(result, "\"varbinary\"") == 0))
	{
		char *new_result = psprintf("%s(max)", result);
		pfree(result);
		result = new_result;
	}

	return result;
}

/*
 * DestReceiver struct for INSERT EXEC - captures procedure output into a temp table.
 */
typedef struct
{
	DestReceiver pub;			/* public fields */
	Oid			temp_table_oid;	/* OID of temp table to insert into */
	TupleDesc	typeinfo;		/* tuple descriptor from startup */
	uint64		rows_inserted;	/* count of rows inserted */
	/* Coercion infrastructure using ExecProject */
	ExprContext *econtext;		/* expression context for projection */
	ProjectionInfo *proj_info;	/* projection info for type coercion (NULL if no coercion needed) */
	TupleTableSlot *proj_slot;	/* result slot for projection */
	int			natts;			/* number of attributes */
	bool		needs_coercion;	/* true if any column needs coercion */
} DR_insertexec;

/* Forward declarations for DestReceiver callbacks */
static void insertexec_startup(DestReceiver *self, int operation, TupleDesc typeinfo);
static bool insertexec_receive(TupleTableSlot *slot, DestReceiver *self);
static void insertexec_shutdown(DestReceiver *self);
static void insertexec_destroy(DestReceiver *self);

/*
 * Schema signature (column count and types) captured at INSERT EXEC start,
 * used to detect ALTER TABLE operations before flushing to the target.
 */
typedef struct InsertExecSchemaSignature
{
	int			natts;			/* Number of columns */
	Oid		   *atttypids;		/* Array of column type OIDs */
	int32	   *atttypmods;		/* Array of column type modifiers */
} InsertExecSchemaSignature;

/*
 * Global context for INSERT EXEC - bundled into a single struct for cleaner code.
 * This context is needed for nested procedure calls during INSERT EXEC.
 */
typedef struct InsertExecContext
{
	Oid			temp_table_oid;			/* OID of temp table for buffering */
	char	   *temp_table_name;		/* Name of temp table for buffering (dynamically chosen) */
	char	   *target_table;			/* Target table name */
	char	   *column_list;			/* Column list for INSERT */
	bool		flush_in_progress;		/* True during flush phase to block commit_stmt */
	PLExecStateCallStack *call_stack_entry;	/* Call stack entry when INSERT EXEC started */
	bool		had_error;				/* True if INSERT EXEC had an error */
	Oid			target_rel_oid;			/* OID of target table - lock held to detect schema changes */
	InsertExecSchemaSignature *schema_sig;	/* Schema signature for detecting changes */
	bool		started_implicit_txn;	/* True if INSERT EXEC started an implicit transaction */
} InsertExecContext;

/* Initialize the global INSERT EXEC context */
static InsertExecContext insert_exec_ctx = {
	.temp_table_oid = InvalidOid,
	.temp_table_name = NULL,
	.target_table = NULL,
	.column_list = NULL,
	.flush_in_progress = false,
	.call_stack_entry = NULL,
	.had_error = false,
	.target_rel_oid = InvalidOid,
	.schema_sig = NULL,
	.started_implicit_txn = false
};

/*
 * Set the global INSERT EXEC context with target table info.
 * Called from the executor when an INSERT EXEC statement begins.
 * This is called BEFORE temp table creation - just stores the target info.
 *
 * IMPORTANT: We allocate in TopMemoryContext so the strings survive
 * error handling (PG_CATCH blocks). The current memory context may be
 * reset during error processing, which would corrupt these pointers.
 */
void
pltsql_set_insert_exec_context_info(const char *target_table, const char *column_list)
{
	MemoryContext oldcontext;

	/* Clear any previous context */
	if (insert_exec_ctx.target_table)
	{
		pfree(insert_exec_ctx.target_table);
		insert_exec_ctx.target_table = NULL;
	}
	if (insert_exec_ctx.column_list)
	{
		pfree(insert_exec_ctx.column_list);
		insert_exec_ctx.column_list = NULL;
	}

	/* Allocate in TopMemoryContext so strings survive error handling */
	oldcontext = MemoryContextSwitchTo(TopMemoryContext);
	insert_exec_ctx.target_table = target_table ? pstrdup(target_table) : NULL;
	insert_exec_ctx.column_list = column_list ? pstrdup(column_list) : NULL;
	MemoryContextSwitchTo(oldcontext);

	/*
	 * Snapshot the call stack entry when INSERT EXEC starts.
	 * This pointer comparison determines if an error occurred 
	 * at the INSERT EXEC level or inside the executed procedure.
	 */
	insert_exec_ctx.call_stack_entry = exec_state_call_stack;
}

/*
 * Set the global INSERT EXEC context with temp table OID.
 * Called when temp table is created in exec_stmt_exec.
 */
void
pltsql_set_insert_exec_context(Oid temp_table_oid)
{
	insert_exec_ctx.temp_table_oid = temp_table_oid;
}

/*
 * Clear the global INSERT EXEC context.
 * Called when exiting INSERT EXEC context normally.
 *
 * Note: Does not clear had_error, started_implicit_txn, schema_sig, or
 * target_rel_oid. Call pltsql_insert_exec_close_target_table() first to
 * release the lock and free schema_sig before calling this function.
 */
void
pltsql_clear_insert_exec_context(void)
{
	insert_exec_ctx.temp_table_oid = InvalidOid;
	insert_exec_ctx.call_stack_entry = NULL;
	insert_exec_ctx.flush_in_progress = false;
	if (insert_exec_ctx.target_table)
	{
		pfree(insert_exec_ctx.target_table);
		insert_exec_ctx.target_table = NULL;
	}
	if (insert_exec_ctx.column_list)
	{
		pfree(insert_exec_ctx.column_list);
		insert_exec_ctx.column_list = NULL;
	}
	if (insert_exec_ctx.temp_table_name)
	{
		pfree(insert_exec_ctx.temp_table_name);
		insert_exec_ctx.temp_table_name = NULL;
	}
}

/*
 * Full reset of INSERT EXEC context for safety net cleanup paths.
 * Called when stale context is detected (e.g., empty call stack, batch end).
 * Unlike pltsql_clear_insert_exec_context(), this also clears the error and
 * implicit transaction flags, and releases target table resources.
 */
void
pltsql_insert_exec_reset_all(void)
{
	/* Release target table lock and free schema signature */
	pltsql_insert_exec_close_target_table();

	/* Clear all context fields including flags */
	pltsql_clear_insert_exec_context();
	insert_exec_ctx.had_error = false;
	insert_exec_ctx.started_implicit_txn = false;
}

/*
 * Set the INSERT EXEC error flag.
 * Called when an error occurs during INSERT EXEC.
 * This flag is used to skip the transaction count mismatch check.
 */
void
pltsql_insert_exec_set_error_flag(void)
{
	insert_exec_ctx.had_error = true;
}

/*
 * Check if INSERT EXEC had an error.
 * Used to skip the transaction count mismatch check.
 */
bool
pltsql_insert_exec_had_error(void)
{
	return insert_exec_ctx.had_error;
}

/*
 * Clear the INSERT EXEC error flag.
 * Called after the error has been handled.
 */
void
pltsql_insert_exec_clear_error_flag(void)
{
	insert_exec_ctx.had_error = false;
}

/*
 * Set the flag indicating INSERT EXEC started an implicit transaction.
 * This flag persists even after the INSERT EXEC context is cleared,
 * so it can be used to skip the transaction count mismatch check.
 */
void
pltsql_insert_exec_set_implicit_txn_flag(void)
{
	insert_exec_ctx.started_implicit_txn = true;
}

/*
 * Check if INSERT EXEC started an implicit transaction.
 * Used to skip the transaction count mismatch check.
 */
bool
pltsql_insert_exec_started_implicit_txn(void)
{
	return insert_exec_ctx.started_implicit_txn;
}

/*
 * Clear the flag indicating INSERT EXEC started an implicit transaction.
 * Called after the transaction count mismatch check has been skipped.
 */
void
pltsql_insert_exec_clear_implicit_txn_flag(void)
{
	insert_exec_ctx.started_implicit_txn = false;
}

/*
 * Capture schema signature and lock target table for schema change detection.
 * We record column count and types at INSERT EXEC start, then verify they
 * haven't changed before flushing. Regular tables get RowExclusiveLock to
 * block concurrent DDL; temp tables only get schema captured (session-local).
 */
void
pltsql_insert_exec_open_target_table(const char *target_table,
                                     const char *schema_name_in,
                                     const char *db_name_in)
{
	RangeVar   *rv;
	Oid			relid;
	char	   *schema_name = NULL;
	char	   *table_name = NULL;
	char	   *physical_schema = NULL;
	Relation	rel;
	TupleDesc	tupdesc;
	int			i;
	MemoryContext oldcontext;
	bool		is_temp_table;

	if (target_table == NULL)
		return;

	oldcontext = CurrentMemoryContext;
	is_temp_table = (target_table[0] == '#' || target_table[0] == '@');

	if (is_temp_table)
	{
		/*
		 * Temp table or table variable - resolve using RangeVarGetRelid.
		 * We don't need to lock because they're session-local.
		 */
		rv = makeRangeVar(NULL, pstrdup(target_table), -1);
		relid = RangeVarGetRelid(rv, NoLock, true);

		if (!OidIsValid(relid))
			return;

		/* Store the OID for schema verification (no lock for temp tables) */
		insert_exec_ctx.target_rel_oid = relid;
	}
	else
	{
		table_name = pstrdup(target_table);
		if (schema_name_in != NULL)
			schema_name = pstrdup(schema_name_in);
		else
			schema_name = pstrdup("dbo");  /* default schema */
		physical_schema = get_physical_schema_name(get_cur_db_name(), schema_name);

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

		/*
		 * Acquire RowExclusiveLock on the target table.
		 * This lock will be held until the end of the transaction.
		 * It blocks concurrent sessions from modifying the table.
		 * Note: Same-session DROP/ALTER is still allowed by PostgreSQL,
		 * but we detect it via schema verification at flush time.
		 */
		PG_TRY();
		{
			LockRelationOid(relid, RowExclusiveLock);
		}
		PG_CATCH();
		{
			MemoryContextSwitchTo(oldcontext);
			FlushErrorState();
			return;
		}
		PG_END_TRY();

		insert_exec_ctx.target_rel_oid = relid;
	}

	/*
	 * Capture the schema signature of the target table.
	 * This is used to detect DROP/ALTER at flush time.
	 */
	PG_TRY();
	{
		rel = table_open(relid, NoLock);
	}
	PG_CATCH();
	{
		MemoryContextSwitchTo(oldcontext);
		FlushErrorState();
		insert_exec_ctx.target_rel_oid = InvalidOid;
		return;
	}
	PG_END_TRY();

	tupdesc = RelationGetDescr(rel);

	/* Allocate schema signature in TopMemoryContext so it survives error handling */
	oldcontext = MemoryContextSwitchTo(TopMemoryContext);

	/* Free any previous schema signature */
	if (insert_exec_ctx.schema_sig != NULL)
	{
		if (insert_exec_ctx.schema_sig->atttypids)
			pfree(insert_exec_ctx.schema_sig->atttypids);
		if (insert_exec_ctx.schema_sig->atttypmods)
			pfree(insert_exec_ctx.schema_sig->atttypmods);
		pfree(insert_exec_ctx.schema_sig);
		insert_exec_ctx.schema_sig = NULL;
	}

	insert_exec_ctx.schema_sig = palloc(sizeof(InsertExecSchemaSignature));
	insert_exec_ctx.schema_sig->natts = tupdesc->natts;
	insert_exec_ctx.schema_sig->atttypids = palloc(tupdesc->natts * sizeof(Oid));
	insert_exec_ctx.schema_sig->atttypmods = palloc(tupdesc->natts * sizeof(int32));

	for (i = 0; i < tupdesc->natts; i++)
	{
		Form_pg_attribute attr = TupleDescAttr(tupdesc, i);
		insert_exec_ctx.schema_sig->atttypids[i] = attr->atttypid;
		insert_exec_ctx.schema_sig->atttypmods[i] = attr->atttypmod;
	}

	MemoryContextSwitchTo(oldcontext);

	table_close(rel, NoLock);  /* Keep the lock */
}

/*
 * Close the target table that was held open during INSERT EXEC.
 * Called after the flush completes or on error cleanup.
 *
 * For regular tables: Release the RowExclusiveLock we acquired.
 * For temp tables: Just clear the OID (no lock was acquired).
 *
 * Note: We only release the lock if we're not in an aborted transaction state.
 * If the transaction was aborted, the lock has already been released.
 */
void
pltsql_insert_exec_close_target_table(void)
{
	if (OidIsValid(insert_exec_ctx.target_rel_oid))
	{
		const char *target = insert_exec_ctx.target_table;
		bool is_temp_table = (target != NULL && (target[0] == '#' || target[0] == '@'));

		/*
		 * Only release the lock for regular tables (not temp tables).
		 * Temp tables don't have locks to release.
		 */
		if (!is_temp_table && !IsAbortedTransactionBlockState())
		{
			MemoryContext oldcontext = CurrentMemoryContext;
			PG_TRY();
			{
				UnlockRelationOid(insert_exec_ctx.target_rel_oid, RowExclusiveLock);
			}
			PG_CATCH();
			{
				MemoryContextSwitchTo(oldcontext);
				FlushErrorState();
				/* Ignore unlock failures - table may have been dropped */
			}
			PG_END_TRY();
		}
		insert_exec_ctx.target_rel_oid = InvalidOid;
	}

	/* Free the schema signature */
	if (insert_exec_ctx.schema_sig != NULL)
	{
		if (insert_exec_ctx.schema_sig->atttypids)
			pfree(insert_exec_ctx.schema_sig->atttypids);
		if (insert_exec_ctx.schema_sig->atttypmods)
			pfree(insert_exec_ctx.schema_sig->atttypmods);
		pfree(insert_exec_ctx.schema_sig);
		insert_exec_ctx.schema_sig = NULL;
	}
}

/*
 * Verify that the target table schema hasn't changed since INSERT EXEC started.
 * Returns true if schema is unchanged, false if it has changed.
 *
 * This is called before flushing data to the target table to detect if the
 * executed procedure altered the target table's schema.
 *
 * Note: In major version upgrade scenarios, the OID captured at INSERT EXEC start
 * may become stale. We handle this gracefully by skipping the check if we can't
 * open the relation - the actual INSERT will validate the data anyway.
 */
bool
pltsql_insert_exec_verify_schema(void)
{
	Relation	rel;
	TupleDesc	tupdesc;
	int			i;
	bool		schema_changed = false;
	MemoryContext oldcontext;

	/* If no schema signature was captured, skip the check */
	if (insert_exec_ctx.schema_sig == NULL || !OidIsValid(insert_exec_ctx.target_rel_oid))
		return true;

	/*
	 * Try to open the relation. If we can't open it, the table was likely
	 * dropped by the executed procedure - this is a schema change error.
	 */
	oldcontext = CurrentMemoryContext;
	PG_TRY();
	{
		rel = table_open(insert_exec_ctx.target_rel_oid, NoLock);  /* Already have lock */
	}
	PG_CATCH();
	{
		/*
		 * Could not open relation - table was dropped or OID is stale.
		 * This is a schema change, return false to trigger the error.
		 */
		MemoryContextSwitchTo(oldcontext);
		FlushErrorState();
		return false;  /* Schema changed - table no longer exists */
	}
	PG_END_TRY();

	tupdesc = RelationGetDescr(rel);

	/* Check if column count changed */
	if (tupdesc->natts != insert_exec_ctx.schema_sig->natts)
	{
		schema_changed = true;
	}
	else
	{
		/* Check if any column type changed */
		for (i = 0; i < tupdesc->natts; i++)
		{
			Form_pg_attribute attr = TupleDescAttr(tupdesc, i);
			if (attr->atttypid != insert_exec_ctx.schema_sig->atttypids[i] ||
				attr->atttypmod != insert_exec_ctx.schema_sig->atttypmods[i])
			{
				schema_changed = true;
				break;
			}
		}
	}

	table_close(rel, NoLock);  /* Keep the lock */

	return !schema_changed;
}

/*
 * Helper function to check if a target list contains SELECT * (star expansion).
 * Returns true if any target contains a star, false otherwise.
 */
static bool
target_list_contains_star(List *targetList)
{
	ListCell *lc;

	foreach(lc, targetList)
	{
		ResTarget *rt = (ResTarget *) lfirst(lc);

		if (rt == NULL || !IsA(rt, ResTarget))
			continue;

		/* Check if the value is a ColumnRef with A_Star */
		if (rt->val != NULL && IsA(rt->val, ColumnRef))
		{
			ColumnRef *cref = (ColumnRef *) rt->val;
			ListCell *field_lc;

			foreach(field_lc, cref->fields)
			{
				Node *field = (Node *) lfirst(field_lc);
				if (IsA(field, A_Star))
					return true;
			}
		}
	}

	return false;
}

/*
 * Helper function to count target list columns in a SelectStmt.
 * Handles UNION/INTERSECT/EXCEPT by recursively checking the left branch.
 * Returns -1 if the statement is not a SELECT, if column count cannot be determined,
 * or if the SELECT uses * (star expansion) which requires table resolution.
 */
static int
count_select_target_columns(SelectStmt *stmt)
{
	if (stmt == NULL)
		return -1;

	/* For set operations (UNION, INTERSECT, EXCEPT), check the left branch */
	if (stmt->op != SETOP_NONE)
	{
		return count_select_target_columns(stmt->larg);
	}

	/* For a simple SELECT, count the target list */
	if (stmt->targetList != NULL)
	{
		/*
		 * If the target list contains SELECT *, we can't determine the
		 * actual column count without resolving the table reference.
		 * Return -1 to skip early validation and let the normal path handle it.
		 */
		if (target_list_contains_star(stmt->targetList))
			return -1;

		return list_length(stmt->targetList);
	}

	return -1;
}

/*
 * Validate column count from query string BEFORE plan preparation.
 *
 * tsql requires column mismatch errors to take priority over runtime errors
 * like division by zero. PostgreSQL's plan preparation evaluates constant
 * expressions, so we parse and count columns here without evaluation.
 *
 * This is an OPTIMIZATION for early error detection, not a correctness
 * requirement. If we can't determine the column count (SELECT *, complex
 * queries, parse errors), we skip early validation and let the normal
 * execution path handle it - the DestReceiver will still catch mismatches.
 *
 * Returns true if validation passes OR cannot be performed (defer to normal path).
 * Returns false only if column count mismatch is definitively detected.
 */
bool
pltsql_insert_exec_validate_column_count_from_query(const char *query_string)
{
	List		*parsetree_list;
	RawStmt		*raw_stmt;
	Node		*stmt;
	int			query_natts;
	Oid			temp_table_oid;
	Relation	temp_rel;
	int			temp_natts;
	MemoryContext oldcontext;

	/* Caller must ensure INSERT EXEC is active before calling */
	Assert(pltsql_insert_exec_active());

	/*
	 * Assert temp table OID is valid - this function must only be called
	 * after the temp table is created (pltsql_insert_exec_in_execution() is true).
	 */
	temp_table_oid = pltsql_get_insert_exec_temp_table_oid();
	Assert(OidIsValid(temp_table_oid));

	/* Parse the query string - if parsing fails, defer to normal execution */
	oldcontext = CurrentMemoryContext;
	PG_TRY();
	{
		parsetree_list = raw_parser(query_string, RAW_PARSE_DEFAULT);
	}
	PG_CATCH();
	{
		MemoryContextSwitchTo(oldcontext);
		FlushErrorState();
		return true;  /* Parse error - normal path will report it */
	}
	PG_END_TRY();

	/* Only handle single-statement queries */
	if (list_length(parsetree_list) != 1)
		return true;  /* Multiple statements, defer to runtime */

	raw_stmt = (RawStmt *) linitial(parsetree_list);
	stmt = raw_stmt->stmt;

	/* Only validate SELECT statements */
	if (!IsA(stmt, SelectStmt))
		return true;  /* Not a SELECT (e.g., EXEC), defer to runtime */

	/*
	 * Count target list columns. Returns -1 for SELECT *, complex queries,
	 * or when column count can't be determined statically. In those cases,
	 * skip early validation - the DestReceiver will catch mismatches at runtime.
	 */
	query_natts = count_select_target_columns((SelectStmt *) stmt);
	if (query_natts < 0)
		return true;  /* Can't determine count statically, defer to runtime */

	/* Get temp table column count */
	PG_TRY();
	{
		temp_rel = table_open(temp_table_oid, AccessShareLock);
		temp_natts = RelationGetDescr(temp_rel)->natts;
		table_close(temp_rel, AccessShareLock);
	}
	PG_CATCH();
	{
		/* If we can't open the temp table, let normal path handle it */
		MemoryContextSwitchTo(oldcontext);
		FlushErrorState();
		return true;
	}
	PG_END_TRY();

	/* Check for column count mismatch */
	if (query_natts != temp_natts)
	{
		/*
		 * Set the error flag BEFORE throwing the error. This ensures that
		 * even if TRY-CATCH catches the error, the flush will be skipped.
		 *
		 * Expected behavior: Column mismatch errors cause all rows to be
		 * rolled back, even if caught by TRY-CATCH. This is different from
		 * data-level errors like division by zero, which only affect the
		 * current row and allow previously inserted rows to be kept.
		 */
		pltsql_insert_exec_set_error_flag();

		/*
		 * Use ERRCODE_DATATYPE_MISMATCH to avoid the error mapping in
		 * error_mapping.txt. We want to keep the internal error code for
		 * test compatibility.
		 */
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Column name or number of supplied values does not match table definition.")));
	}

	return true;
}

/*
 * Check if INSERT EXEC context is active (target table info is set).
 * This returns true even before temp table is created.
 */
bool
pltsql_insert_exec_active(void)
{
	return (insert_exec_ctx.target_table != NULL);
}

/*
 * Stricter check than pltsql_insert_exec_active() - also verifies the temp
 * table OID is valid. Returns false if context is stale or if temp table
 * hasn't been created yet. Stale context is prevented by
 * pltsql_clear_insert_exec_context() on every exit path.
 */
bool
pltsql_insert_exec_in_execution(void)
{
	/*
	 * call_stack_entry non-NULL + target_table non-NULL = INSERT EXEC is live.
	 * Stale context is prevented by pltsql_clear_insert_exec_context() on
	 * every exit path.
	 */
	if (insert_exec_ctx.target_table == NULL)
		return false;

	if (insert_exec_ctx.call_stack_entry == NULL)
		return false;

	/*
	 * Check if the temp table OID is valid. Returns false early in INSERT EXEC
	 * before temp table is created, which is fine.
	 */
	if (!OidIsValid(insert_exec_ctx.temp_table_oid))
		return false;

	return true;
}

/*
 * Check if INSERT EXEC flush is in progress.
 * During flush, we temporarily clear the INSERT EXEC context to allow
 * INSTEAD OF triggers to fire, but we still need to block commit_stmt.
 */
bool
pltsql_insert_exec_flush_in_progress(void)
{
	return insert_exec_ctx.flush_in_progress;
}

/*
 * Set the INSERT EXEC flush in progress flag.
 * Called when starting/ending the flush operation.
 */
void
pltsql_insert_exec_set_flush_in_progress(bool in_progress)
{
	insert_exec_ctx.flush_in_progress = in_progress;
}

/*
 * Set the INSERT EXEC target table pointer.
 * Used during flush to temporarily clear and restore the target table.
 */
void
pltsql_insert_exec_set_target_table(const char *target_table)
{
	/* Free old value if setting to a new value */
	if (insert_exec_ctx.target_table != NULL && target_table != insert_exec_ctx.target_table)
	{
		pfree(insert_exec_ctx.target_table);
	}

	if (target_table != NULL)
	{
		MemoryContext oldcontext = MemoryContextSwitchTo(TopMemoryContext);
		insert_exec_ctx.target_table = pstrdup(target_table);
		MemoryContextSwitchTo(oldcontext);
	}
	else
	{
		insert_exec_ctx.target_table = NULL;
	}
}

/*
 * Get the temp table OID for INSERT EXEC buffering.
 */
Oid
pltsql_get_insert_exec_temp_table_oid(void)
{
	return insert_exec_ctx.temp_table_oid;
}

/*
 * Check if we're inside a TRY-CATCH block during INSERT EXEC.
 * This checks the exec_state_call_stack to see if any estate has a TRY-CATCH block active.
 */
bool
pltsql_insert_exec_in_trycatch(void)
{
	PLExecStateCallStack *cur;

	if (insert_exec_ctx.target_table == NULL)
		return false;

	/* Check the call stack for any active TRY-CATCH blocks */
	cur = exec_state_call_stack;
	while (cur != NULL)
	{
		/* There is at-least one try block active for sure */
		if (vec_size(cur->estate->err_ctx_stack) > 1)
			return true;
		/* Either try or catch block is active */
		if (vec_size(cur->estate->err_ctx_stack) == 1)
		{
			PLtsql_errctx *err_ctx = *(PLtsql_errctx **) vec_at(cur->estate->err_ctx_stack, 0);

			/* Make sure that we are not inside the catch block */
			if (!err_ctx->partial_restored)
				return true;
		}
		cur = cur->next;
	}

	return false;
}

/*
 * Called from sigsetjmp handler when TRY-CATCH catches an error.
 * Returns true if we should clean up INSERT EXEC context - only when the
 * TRY-CATCH is at the INSERT EXEC level. If the TRY-CATCH is inside
 * the executed procedure (deeper stack), INSERT EXEC is still in progress.
 */
bool
pltsql_insert_exec_should_cleanup_on_trycatch(void)
{
	if (insert_exec_ctx.target_table == NULL)
		return false;

	/*
	 * If the call stack head is the same node as when INSERT EXEC started,
	 * the error is at the INSERT EXEC level → clean up.
	 * If it's a different (deeper) node, the error is inside the called
	 * procedure → INSERT EXEC stays live.
	 */
	return exec_state_call_stack == insert_exec_ctx.call_stack_entry;
}


/*
 * =============================================================================
 * STUB FUNCTIONS - To be implemented in subsequent PRs
 * =============================================================================
 * These functions are placeholders that allow the code to compile.
 * They will be replaced with real implementations in later PRs:
 *   - PR5: flush_insert_exec_temp_table, insert_exec_setup,
 *          insert_exec_error_cleanup, insert_exec_success_cleanup
 * =============================================================================
 */

/*
 * Create a DestReceiver for INSERT EXEC that writes to a temp table.
 */
DestReceiver *
CreateInsertExecDestReceiver(Oid temp_table_oid)
{
	DR_insertexec *self = (DR_insertexec *) palloc0(sizeof(DR_insertexec));

	self->pub.receiveSlot = insertexec_receive;
	self->pub.rStartup = insertexec_startup;
	self->pub.rShutdown = insertexec_shutdown;
	self->pub.rDestroy = insertexec_destroy;
	self->pub.mydest = DestTransientRel;  /* reuse existing dest type */
	self->temp_table_oid = temp_table_oid;

	return (DestReceiver *) self;
}

/*
 * insertexec_startup --- executor startup for INSERT EXEC receiver
 *
 * Relation is opened/closed per-tuple in insertexec_receive to avoid
 * invalid handles after subtransaction rollbacks (e.g., TRY/CATCH).
 *
 * Validates column count matches the temp table and builds coercion
 * expressions for type conversion using PostgreSQL's ExecInitExpr/ExecEvalExpr.
 */

static void
insertexec_startup(DestReceiver *self, int operation, TupleDesc typeinfo)
{
	DR_insertexec *myState = (DR_insertexec *) self;
	Relation	temp_rel;
	TupleDesc	temp_tupdesc;
	int			result_natts;
	int			temp_natts;
	int			i;
	List	   *target_list = NIL;

	/* Just store the tuple descriptor for later use */
	myState->typeinfo = typeinfo;
	myState->rows_inserted = 0;
	myState->proj_info = NULL;
	myState->proj_slot = NULL;

	/*
	 * Validate column count: the number of columns in the result set
	 * must match the number of columns in the temp table.
	 * "Column name or number of supplied values does not match table definition."
	 */
	result_natts = typeinfo->natts;

	/* Open temp table to get its tuple descriptor */
	temp_rel = table_open(myState->temp_table_oid, AccessShareLock);
	temp_tupdesc = RelationGetDescr(temp_rel);
	temp_natts = temp_tupdesc->natts;

	if (result_natts != temp_natts)
	{
		table_close(temp_rel, AccessShareLock);
	/*
 	 * Set error flag BEFORE throwing to skip flush and re-throw even if
 	 * TRY-CATCH catches it. Column mismatch errors roll back all rows,
 	 * unlike data errors (e.g., divide by zero) which only affect current row.
 	*/

		pltsql_insert_exec_set_error_flag();
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Column name or number of supplied values does not match table definition.")));
	}

	/* Build target list for projection with type coercion */
	myState->natts = temp_natts;
	myState->needs_coercion = false;

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

		expr = (Node *) var;

		/* Check if coercion is needed for this column */
		if (src_att->atttypid != tgt_att->atttypid ||
			(src_att->atttypmod != tgt_att->atttypmod && tgt_att->atttypmod != -1))
		{
			Node	   *cast_expr;

			myState->needs_coercion = true;

			/* Build coercion expression using ASSIGNMENT coercion (matches tsql INSERT behavior) */
			cast_expr = coerce_to_target_type(NULL,
											  expr,
											  src_att->atttypid,
											  tgt_att->atttypid,
											  tgt_att->atttypmod,
											  COERCION_ASSIGNMENT,
											  COERCE_IMPLICIT_CAST,
											  -1);

			/* If no direct coercion, fall back to I/O coercion (text round-trip) */
			if (cast_expr == NULL)
			{
				CoerceViaIO *iocoerce = makeNode(CoerceViaIO);

				iocoerce->arg = (Expr *) expr;
				iocoerce->resulttype = tgt_att->atttypid;
				iocoerce->resultcollid = InvalidOid;
				iocoerce->coerceformat = COERCE_IMPLICIT_CAST;
				iocoerce->location = -1;
				cast_expr = (Node *) iocoerce;

				/* Apply typmod coercion if needed */
				if (tgt_att->atttypmod != -1)
					cast_expr = coerce_to_target_type(NULL,
													  cast_expr,
													  tgt_att->atttypid,
													  tgt_att->atttypid,
													  tgt_att->atttypmod,
													  COERCION_ASSIGNMENT,
													  COERCE_IMPLICIT_CAST,
													  -1);
			}

			if (cast_expr == NULL)
			{
				table_close(temp_rel, AccessShareLock);
				ereport(ERROR,
						(errcode(ERRCODE_CANNOT_COERCE),
						 errmsg("cannot convert type %s to %s",
								format_type_be(src_att->atttypid),
								format_type_be(tgt_att->atttypid))));
			}

			expr = cast_expr;
		}

		/* Create TargetEntry for this column */
		tle = makeTargetEntry((Expr *) expr,
							  i + 1,		/* resno is 1-based */
							  NULL,			/* resname */
							  false);		/* resjunk */
		target_list = lappend(target_list, tle);
	}

	/* Create expression context and projection info if coercion needed */
	if (myState->needs_coercion)
	{
		TupleDesc	proj_tupdesc;

		myState->econtext = CreateStandaloneExprContext();

		/* Create a copy of the temp table's tuple descriptor for the result slot */
		proj_tupdesc = CreateTupleDescCopy(temp_tupdesc);

		/* Create the result slot for projection */
		myState->proj_slot = MakeSingleTupleTableSlot(proj_tupdesc, &TTSOpsVirtual);

		/* Build the projection info */
		myState->proj_info = ExecBuildProjectionInfo(target_list,
													 myState->econtext,
													 myState->proj_slot,
													 NULL,		/* no parent PlanState */
													 typeinfo);	/* input descriptor */
	}

	table_close(temp_rel, AccessShareLock);

	/*
 	 * Pre-assign XID before parallel mode starts. table_tuple_insert() calls
 	 * GetCurrentTransactionId() which fails in parallel mode if no XID exists.
 	 * rStartup runs before EnterParallelMode, so assigning here avoids the error.
 	*/

	(void) GetCurrentTransactionId();  /* Ensure XID is assigned before parallel mode */
}

/*
 * insertexec_receive --- receive one tuple and insert into temp table
*/
static bool
insertexec_receive(TupleTableSlot *slot, DestReceiver *self)
{
	DR_insertexec *myState = (DR_insertexec *) self;
	Relation	temp_rel;
	CommandId	cid;
	TupleTableSlot *insert_slot;

	/* Open temp table fresh for each tuple */
	temp_rel = table_open(myState->temp_table_oid, RowExclusiveLock);
	cid = GetCurrentCommandId(true);

	if (myState->needs_coercion)
	{
		ExprContext *econtext = myState->econtext;

		/* Reset per-tuple memory context for expression evaluation */
		ResetExprContext(econtext);

		/*
		 * Set up the input slot for projection.
		 * ExecProject will read from ecxt_outertuple (we used OUTER_VAR in the Var nodes).
		 */
		econtext->ecxt_outertuple = slot;

		/* Project tuple with type coercion */
		insert_slot = ExecProject(myState->proj_info);

		/* Insert the projected tuple */
		table_tuple_insert(temp_rel,
						   insert_slot,
						   cid,
						   0,
						   NULL);
	}
	else
	{
		/*
		 * No coercion needed - insert directly.
		 * table_tuple_insert handles slot type conversion if needed.
		 */
		table_tuple_insert(temp_rel,
						   slot,
						   cid,
						   0,  /* no special options - preserve MVCC */
						   NULL);  /* no bulk insert state */
	}

	/* Close relation immediately - don't hold across subtransaction boundaries */
	table_close(temp_rel, NoLock);

	myState->rows_inserted++;

	return true;
}

/*
 * insertexec_shutdown --- executor end for INSERT EXEC receiver
 *
 * Clean up the expression context and projection slot used for type coercion.
 */
static void
insertexec_shutdown(DestReceiver *self)
{
	DR_insertexec *myState = (DR_insertexec *) self;

	/* Free the projection slot if we created one */
	if (myState->proj_slot != NULL)
	{
		ExecDropSingleTupleTableSlot(myState->proj_slot);
		myState->proj_slot = NULL;
	}

	/* Free the expression context if we created one */
	if (myState->econtext != NULL)
	{
		FreeExprContext(myState->econtext, true);
		myState->econtext = NULL;
	}
}

/*
 * insertexec_destroy --- release DestReceiver object
 */
static void
insertexec_destroy(DestReceiver *self)
{
	DR_insertexec *myState = (DR_insertexec *) self;

	/* proj_info is allocated in the expression context, no need to free separately */
	myState->proj_info = NULL;

	pfree(self);
}

/*
 * Create a temp table for INSERT EXEC buffering.
 *
 * Creates a PostgreSQL temp table with schema matching
 * the target table. Uses a unique name pattern __insert_exec_buf_PID_N to avoid
 * conflicts. For regular tables, queries pg_attribute to get column definitions
 * (avoids needing SELECT permission for ownership chaining).
 */
Oid
create_insert_exec_temp_table(const char *target_table, const char *column_list, const char *schema_name_in)
{
	StringInfoData create_stmt;
	StringInfoData col_query;
	int			rc;
	Oid			temp_table_oid;
	char		temp_table_name[NAMEDATALEN];
	char	   *schema_name = NULL;
	char	   *table_name = NULL;
	char	   *physical_schema = NULL;
	Oid			temp_nsp_oid;
	int			suffix = 1;
	MemoryContext oldcontext;

	/*
	 * Generate a unique temp table name using backend PID and a suffix.
	*/
	temp_nsp_oid = LookupNamespaceNoError("pg_temp");

	for (;;)
	{
		Oid existing_relid;

		snprintf(temp_table_name, sizeof(temp_table_name),
				 "__insert_exec_buf_%d_%d", MyProcPid, suffix);

		/*
		 * Check if a table with this name already exists in pg_temp.
		 * If temp namespace doesn't exist yet, the name is definitely available.
		 */
		if (!OidIsValid(temp_nsp_oid))
			break;

		existing_relid = get_relname_relid(temp_table_name, temp_nsp_oid);
		if (!OidIsValid(existing_relid))
			break;  /* Name is available */

		/* Name is taken, try the next suffix */
		suffix++;

		/* Safety check to prevent infinite loop */
		if (suffix > 10000)
			elog(ERROR, "INSERT-EXEC: Could not find available temp table name after 10000 attempts");
	}

	/* Store the temp table name in the context for later cleanup */
	oldcontext = MemoryContextSwitchTo(TopMemoryContext);
	if (insert_exec_ctx.temp_table_name != NULL)
		pfree(insert_exec_ctx.temp_table_name);
	insert_exec_ctx.temp_table_name = pstrdup(temp_table_name);
	MemoryContextSwitchTo(oldcontext);

	/*
	 * Drop any existing temp table with this name. This handles catalog cache
	 * issues where get_relname_relid didn't find the table but it exists.
	 */
	initStringInfo(&create_stmt);
	appendStringInfo(&create_stmt, "DROP TABLE IF EXISTS %s", temp_table_name);
	rc = SPI_execute(create_stmt.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		elog(WARNING, "failed to drop existing INSERT EXEC temp table: %s",
			 SPI_result_code_string(rc));
	pfree(create_stmt.data);

	/* Reset the pending drop flag */
	insert_exec_ctx.pending_drop = false;

	/*
	 * Parse schema and table name from target_table.
	 * Format can be: "table", "schema.table", or "db.schema.table"
	 * For temp tables (starting with #), we don't need schema parsing.
	 */
	if (target_table[0] == '#' || target_table[0] == '@')
	{
		/* Temp table or table variable - no schema needed */
		table_name = pstrdup(target_table);
		schema_name = NULL;
		physical_schema = NULL;
	}
	else
	{
		if (!parse_insert_exec_table_name(target_table, &schema_name, &table_name,
										  &physical_schema, true))
		{
			elog(ERROR, "INSERT-EXEC: Failed to parse target table name: %s", target_table);
		}
	}

	initStringInfo(&create_stmt);

	if (column_list != NULL)
	{
		/*
		 * User specified columns - create temp table with only those columns.
		 * For temp tables, use SELECT INTO. For regular tables, query pg_attribute
		 * to avoid needing SELECT permission (ownership chaining fix).
		 */
		if (physical_schema == NULL)
		{
			/*
			 * Temp table or table variable target - use SELECT INTO.
			 * Quote identifiers to prevent SQL injection.
			 */
			appendStringInfo(&create_stmt,
				"SELECT %s INTO %s FROM %s WHERE 1=0",
				column_list, temp_table_name, target_table);
		}
		else
		{
			/*
			 * Regular table - query pg_attribute for column definitions.
			 * Parse the column_list to get individual column names, then
			 * query their types from pg_attribute.
			 */
			StringInfoData col_defs;
			bool		first_col = true;
			int			proc_count;
			uint64		i;
			char	   *pg_table_ref;
			char	   *col_list_copy;
			char	   *col_name;
			char	   *saveptr;
			StringInfoData col_names_sql;

			initStringInfo(&col_query);
			initStringInfo(&col_defs);
			initStringInfo(&col_names_sql);

			pg_table_ref = psprintf("%s.%s", physical_schema, table_name);

			/*
			 * Parse the column_list to build a SQL IN clause.
			 * column_list is like "c, a" - we need to convert to ('c', 'a')
			 *
			 * IMPORTANT: We lowercase the column names because pg_attribute stores
			 * column names in lowercase (for unquoted identifiers), and we compare
			 * using lower(a.attname) IN (...). Both sides must be lowercase.
			 */
			col_list_copy = pstrdup(column_list);
			first_col = true;
			appendStringInfoChar(&col_names_sql, '(');
			col_name = strtok_r(col_list_copy, ", ", &saveptr);
			while (col_name != NULL)
			{
				/* Skip leading/trailing whitespace */
				while (*col_name == ' ' || *col_name == '\t')
					col_name++;
				if (*col_name != '\0')
				{
					char *lower_col_name;
					if (!first_col)
						appendStringInfoString(&col_names_sql, ", ");
					/* Lowercase the column name to match pg_attribute storage */
					lower_col_name = downcase_identifier(col_name, strlen(col_name), false, false);
					appendStringInfo(&col_names_sql, "'%s'", lower_col_name);
					pfree(lower_col_name);
					first_col = false;
				}
				col_name = strtok_r(NULL, ", ", &saveptr);
			}
			appendStringInfoChar(&col_names_sql, ')');
			pfree(col_list_copy);

			/*
			 * Query to get column definitions for the specified columns.
			 * We use CASE to preserve the order from the column_list.
			 */
			appendStringInfo(&col_query,
				"SELECT a.attname, format_type(a.atttypid, a.atttypmod) as coltype "
				"FROM pg_attribute a "
				"WHERE a.attrelid = '%s'::regclass "
				"AND a.attnum > 0 "
				"AND NOT a.attisdropped "
				"AND lower(a.attname) IN %s "
				"ORDER BY a.attnum",
				pg_table_ref, col_names_sql.data);

			pfree(pg_table_ref);
			pfree(col_names_sql.data);

			rc = SPI_execute(col_query.data, false, 0);
			if (rc != SPI_OK_SELECT)
			{
				pfree(col_query.data);
				pfree(col_defs.data);
				elog(ERROR, "failed to query target table columns for INSERT EXEC: %s",
					 SPI_result_code_string(rc));
			}

			proc_count = SPI_processed;

			if (proc_count == 0)
			{
				pfree(col_query.data);
				pfree(col_defs.data);
				elog(ERROR, "no columns found for INSERT EXEC temp table");
			}
			else
			{
				/* Build column definitions from query results */
				first_col = true;
				for (i = 0; i < proc_count; i++)
				{
					char *colname = SPI_getvalue(SPI_tuptable->vals[i],
												 SPI_tuptable->tupdesc, 1);
					char *coltype_raw = SPI_getvalue(SPI_tuptable->vals[i],
												 SPI_tuptable->tupdesc, 2);
					if (colname != NULL && coltype_raw != NULL)
					{
						char *coltype = clean_format_type_string(coltype_raw);
						if (!first_col)
							appendStringInfoString(&col_defs, ", ");
						appendStringInfo(&col_defs, "%s %s", colname, coltype);
						first_col = false;
						pfree(coltype);
					}
				}

				SPI_freetuptable(SPI_tuptable);
				pfree(col_query.data);

				/* Create temp table with explicit column definitions */
				appendStringInfo(&create_stmt,
					"CREATE TEMP TABLE %s (%s)",
					temp_table_name, col_defs.data);

				pfree(col_defs.data);
			}
		}
	}
	else
	{
		/*
 		 * Create temp table excluding IDENTITY and computed columns.
 		 * Temp tables (#) and table variables (@) use SELECT INTO (owned by current user).
 		 * Regular tables query pg_attribute to avoid needing SELECT permission.
 		*/

		if (physical_schema == NULL)
		{
			/*
			 * Temp table or table variable - use SELECT * INTO to copy structure.
			 * This is simpler and more reliable for temp tables.
			 * We need to exclude IDENTITY and computed columns, so we query
			 * for non-identity column names first, then use those in SELECT.
			 */
			StringInfoData non_identity_cols;
			bool		first_col = true;
			int			proc_count;
			uint64		i;

			initStringInfo(&col_query);
			initStringInfo(&non_identity_cols);

			/*
			 * Query to get non-IDENTITY, non-computed column names.
			 * Use pg_class join to find the temp table.
			 */
			appendStringInfo(&col_query,
				"SELECT a.attname "
				"FROM pg_attribute a "
				"JOIN pg_class c ON a.attrelid = c.oid "
				"WHERE c.relname = '%s' "
				"AND a.attnum > 0 "
				"AND NOT a.attisdropped "
				"AND a.attidentity = '' "
				"AND a.attgenerated = '' "
				"ORDER BY a.attnum",
				table_name);

			rc = SPI_execute(col_query.data, false, 0);
			if (rc != SPI_OK_SELECT)
			{
				pfree(col_query.data);
				pfree(non_identity_cols.data);
				/* Fall back to CREATE TEMP TABLE AS SELECT */
				appendStringInfo(&create_stmt,
					"CREATE TEMP TABLE %s AS SELECT * FROM %s WHERE 1=0",
					temp_table_name, target_table);
			}
			else
			{
				proc_count = SPI_processed;

				if (proc_count == 0)
				{
					/* No columns found, fall back to CREATE TEMP TABLE AS SELECT */
					pfree(col_query.data);
					pfree(non_identity_cols.data);
					appendStringInfo(&create_stmt,
						"CREATE TEMP TABLE %s AS SELECT * FROM %s WHERE 1=0",
						temp_table_name, target_table);
				}
				else
				{
					/* Build column list from query results */
					for (i = 0; i < proc_count; i++)
					{
						char *colname = SPI_getvalue(SPI_tuptable->vals[i],
													 SPI_tuptable->tupdesc, 1);
						if (colname != NULL)
						{
							if (!first_col)
								appendStringInfoString(&non_identity_cols, ", ");
							appendStringInfoString(&non_identity_cols, colname);
							first_col = false;
						}
					}

					SPI_freetuptable(SPI_tuptable);
					pfree(col_query.data);

					appendStringInfo(&create_stmt,
						"CREATE TEMP TABLE %s AS SELECT %s FROM %s WHERE 1=0",
						temp_table_name, non_identity_cols.data, target_table);

					pfree(non_identity_cols.data);
				}
			}
		}
		else
		{
			/*
			 * Regular table - query pg_attribute for column definitions.
			 * This avoids needing SELECT permission on the target table.
			 */
			StringInfoData col_defs;
			bool		first_col = true;
			int			proc_count;
			uint64		i;
			char	   *pg_table_ref;

			initStringInfo(&col_query);
			initStringInfo(&col_defs);

			pg_table_ref = psprintf("%s.%s", physical_schema, table_name);

			/*
			 * Query to get non-IDENTITY, non-computed column definitions.
			 * attidentity = '' means not an identity column
			 * attgenerated = '' means not a generated/computed column
			 *
			 * Use regclass cast to properly resolve the table.
			 */
			appendStringInfo(&col_query,
				"SELECT a.attname, format_type(a.atttypid, a.atttypmod) as coltype "
				"FROM pg_attribute a "
				"WHERE a.attrelid = '%s'::regclass "
				"AND a.attnum > 0 "
				"AND NOT a.attisdropped "
				"AND a.attidentity = '' "
				"AND a.attgenerated = '' "
				"ORDER BY a.attnum",
				pg_table_ref);

			pfree(pg_table_ref);

			rc = SPI_execute(col_query.data, false, 0);
			if (rc != SPI_OK_SELECT)
			{
				pfree(col_query.data);
				pfree(col_defs.data);
				elog(ERROR, "failed to query target table columns: %s",
					 SPI_result_code_string(rc));
			}

			proc_count = SPI_processed;

			if (proc_count == 0)
			{
				/* No non-identity columns found - this shouldn't happen normally */
				pfree(col_query.data);
				pfree(col_defs.data);
				elog(ERROR, "no columns found for INSERT EXEC temp table");
			}
			else
			{
				/* Build column definitions from query results */
				for (i = 0; i < proc_count; i++)
				{
					char *colname = SPI_getvalue(SPI_tuptable->vals[i],
												 SPI_tuptable->tupdesc, 1);
					char *coltype_raw = SPI_getvalue(SPI_tuptable->vals[i],
												 SPI_tuptable->tupdesc, 2);
					if (colname != NULL && coltype_raw != NULL)
					{
						char *coltype = clean_format_type_string(coltype_raw);
						if (!first_col)
							appendStringInfoString(&col_defs, ", ");
						appendStringInfo(&col_defs, "%s %s", colname, coltype);
						first_col = false;
						pfree(coltype);
					}
				}

				SPI_freetuptable(SPI_tuptable);
				pfree(col_query.data);

				/* Create temp table with explicit column definitions */
				appendStringInfo(&create_stmt,
					"CREATE TEMP TABLE %s (%s)",
					temp_table_name, col_defs.data);

				pfree(col_defs.data);
			}
		}
	}

	/* Clean up parsed names */
	if (table_name)
		pfree(table_name);
	if (schema_name)
		pfree(schema_name);
	if (physical_schema)
		pfree(physical_schema);

	/*
	 * Execute the statement to create temp table.
	 * We use CREATE TEMP TABLE AS SELECT which returns SPI_OK_SELINTO.
	 * For regular tables with explicit column definitions, we use
	 * CREATE TEMP TABLE which returns SPI_OK_UTILITY.
	 */
	rc = SPI_execute(create_stmt.data, false, 0);
	if (rc != SPI_OK_UTILITY && rc != SPI_OK_SELINTO)
		elog(ERROR, "failed to create INSERT EXEC temp table: %s",
			 SPI_result_code_string(rc));

	pfree(create_stmt.data);

	/* Get the OID of the created temp table */
	temp_table_oid = RelnameGetRelid(temp_table_name);
	if (!OidIsValid(temp_table_oid))
		elog(ERROR, "could not find INSERT EXEC temp table %s", temp_table_name);

	return temp_table_oid;
}

/*
 * Drop the INSERT EXEC temp table.
 * Uses the stored temp table name from the INSERT EXEC context.
 */
void
drop_insert_exec_temp_table(Oid temp_table_oid)
{
	StringInfoData drop_stmt;
	int			rc;

	/* Use the stored temp table name from the context */
	if (insert_exec_ctx.temp_table_name == NULL)
	{
		elog(DEBUG1, "INSERT-EXEC: No temp table name stored, cannot drop");
		return;
	}

	initStringInfo(&drop_stmt);
	appendStringInfo(&drop_stmt, "DROP TABLE IF EXISTS %s", insert_exec_ctx.temp_table_name);

	rc = SPI_execute(drop_stmt.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		elog(WARNING, "failed to drop INSERT EXEC temp table %s: %s",
			 insert_exec_ctx.temp_table_name, SPI_result_code_string(rc));

	pfree(drop_stmt.data);

	/* Clear the stored temp table name and OID */
	pfree(insert_exec_ctx.temp_table_name);
	insert_exec_ctx.temp_table_name = NULL;
	insert_exec_ctx.temp_table_oid = InvalidOid;
}

/*
 * STUB: Flush data from temp table to target table.
 * Real implementation in PR5 (Flush Logic + Executor Integration).
 */
void
flush_insert_exec_temp_table(PLtsql_execstate *estate)
{
	/* STUB: Does nothing - real implementation in PR5 */
}

/*
 * STUB: Set up INSERT EXEC execution context.
 * Real implementation in PR5 (Flush Logic + Executor Integration).
 */
bool
insert_exec_setup(PLtsql_execstate *estate,
                  const char *target_table,
                  const char *schema_name,
                  const char *db_name,
                  const char *column_list,
                  bool start_implicit_txn,
                  Oid *temp_table_oid_out)
{
	/* STUB: Returns false (setup not done) - real implementation in PR5 */
	return false;
}

/*
 * STUB: Clean up INSERT EXEC context on error.
 * Real implementation in PR5 (Flush Logic + Executor Integration).
 */
void
insert_exec_error_cleanup(bool setup_done)
{
	/* STUB: Does nothing - real implementation in PR5 */
}

/*
 * STUB: Clean up INSERT EXEC context on success.
 * Real implementation in PR5 (Flush Logic + Executor Integration).
 */
void
insert_exec_success_cleanup(PLtsql_execstate *estate, Oid temp_table_oid)
{
	/* STUB: Does nothing - real implementation in PR5 */
}
