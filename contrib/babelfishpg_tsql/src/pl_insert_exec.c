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

extern void exec_set_rowcount(uint64 rowno);
extern void exec_set_found(PLtsql_execstate *estate, bool state);

/* Forward declaration for called_from_tsql_insert_exec - used by hooks.c */
bool		called_from_tsql_insert_exec(void);

/*
 * Flag to indicate we're inside INSERT EXEC tuple conversion.
 * This is used by the hook in attmap.c to skip type checking and
 * by tupconvert.c to perform type coercion via exec_tsql_cast_value_hook.
 */
bool		called_from_tsql_insert_execute = false;

/*
 * Hook function for attmap.c/tupconvert.c to check if we're in INSERT EXEC.
 * When this returns true:
 *   - build_attrmap_by_position() skips the type mismatch error
 *   - execute_attr_map_tuple() calls exec_tsql_cast_value_hook for type coercion
 */
bool
called_from_tsql_insert_exec(void)
{
	if (sql_dialect != SQL_DIALECT_TSQL)
		return false;
	return called_from_tsql_insert_execute;
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
	char	   *lower_table_name;

	initStringInfo(&col_list);

	lower_table_name = downcase_identifier(table_name, strlen(table_name), false, false);

	/* Resolve the relation OID using RangeVar - works for both regular and temp tables */
	{
		RangeVar *rv = makeRangeVar(physical_schema ? pstrdup(physical_schema) : NULL,
									pstrdup(lower_table_name), -1);
		relid = RangeVarGetRelid(rv, AccessShareLock, true);
	}

	pfree(lower_table_name);

	if (!OidIsValid(relid))
		elog(ERROR, "could not find relation for INSERT EXEC target table: %s",
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

	table_close(rel, AccessShareLock);

	/* Error if no insertable columns found */
	if (first_col)
	{
		pfree(col_list.data);
		elog(ERROR, "no insertable columns found for INSERT EXEC target table: %s",
			table_name);
	}

	return col_list.data;
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
	/* Projection infrastructure - always used */
	ExprContext *econtext;		/* expression context for projection */
	ProjectionInfo *proj_info;	/* projection info for coercion */
	TupleTableSlot *proj_slot;	/* result slot for projection */
	CommandId	cid;			/* command ID obtained once in startup, shared across all tuples */
} DR_insertexec;

/* Forward declarations for DestReceiver callbacks */
static void insertexec_startup(DestReceiver *self, int operation, TupleDesc typeinfo);
static bool insertexec_receive(TupleTableSlot *slot, DestReceiver *self);
static void insertexec_shutdown(DestReceiver *self);
static void insertexec_destroy(DestReceiver *self);

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
	bool		is_target_relation_modified;	/* Set by ObjectPostAlterHook when target is altered */
	bool		started_implicit_txn;	/* True if INSERT EXEC started an implicit transaction */
} InsertExecContext;

/* Global INSERT EXEC context - reset via memset in pltsql_insert_exec_reset_all() */
static InsertExecContext insert_exec_ctx;

/*
 * Set the global INSERT EXEC context with target table info.
 * Called from ANTLR parser when INSERT EXEC is detected.
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
	 * This pointer comparison replaces depth counting for determining
	 * if an error occurred at the INSERT EXEC level or inside the
	 * executed procedure.
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
 * Note: Does not clear had_error or started_implicit_txn flags, which are
 * needed for post-cleanup transaction count mismatch checks.
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
	/* Release target table lock */
	pltsql_insert_exec_close_target_table();

	/* Free any allocated strings before memset */
	if (insert_exec_ctx.target_table)
		pfree(insert_exec_ctx.target_table);
	if (insert_exec_ctx.column_list)
		pfree(insert_exec_ctx.column_list);
	if (insert_exec_ctx.temp_table_name)
		pfree(insert_exec_ctx.temp_table_name);

	/* Reset all fields to zero/NULL */
	memset(&insert_exec_ctx, 0, sizeof(InsertExecContext));
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
	elog(DEBUG4, "TSQL TXN Setting implicit txn flag for INSERT EXEC (was %d, setting to true)",
		 insert_exec_ctx.started_implicit_txn);
	insert_exec_ctx.started_implicit_txn = true;
	elog(DEBUG4, "TSQL TXN After setting implicit txn flag: %d", insert_exec_ctx.started_implicit_txn);
}

/*
 * Check if INSERT EXEC started an implicit transaction.
 * Used to skip the transaction count mismatch check.
 */
bool
pltsql_insert_exec_started_implicit_txn(void)
{
	elog(DEBUG4, "TSQL TXN Checking implicit txn flag: %d", insert_exec_ctx.started_implicit_txn);
	return insert_exec_ctx.started_implicit_txn;
}

/*
 * Clear the flag indicating INSERT EXEC started an implicit transaction.
 * Called after the transaction count mismatch check has been skipped.
 */
void
pltsql_insert_exec_clear_implicit_txn_flag(void)
{
	elog(DEBUG4, "TSQL TXN Clearing implicit txn flag (was %d)", insert_exec_ctx.started_implicit_txn);
	insert_exec_ctx.started_implicit_txn = false;
}

/*
 * Capture target table OID and lock for change detection.
 * Regular tables get RowExclusiveLock to block concurrent DDL;
 * temp tables only get OID captured (session-local).
 *
 * Schema changes are detected via is_target_relation_modified flag,
 * which is set by the ObjectPostAlterHook when the target table is altered.
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
	MemoryContext oldcontext;
	bool		is_temp_table;

	if (target_table == NULL)
		return;

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
		 * but we detect it via is_target_relation_modified flag set by
		 * ObjectPostAlterHook.
		 */
		oldcontext = CurrentMemoryContext;
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

	/* Initialize the modification flag to false */
	insert_exec_ctx.is_target_relation_modified = false;
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

	/* Reset the modification flag */
	insert_exec_ctx.is_target_relation_modified = false;
}

/*
 * Verify that the target table schema hasn't changed since INSERT EXEC started.
 * Returns true if schema is unchanged, false if it has changed.
 *
 * This is called before flushing data to the target table to detect if the
 * executed procedure altered the target table's schema.
 *
 * The is_target_relation_modified flag is set by the ObjectPostAlterHook
 * when the target table is altered during INSERT EXEC execution.
 */
bool
pltsql_insert_exec_verify_schema(void)
{
	/*
	 * If the target relation OID is not valid, we can't verify.
	 * This shouldn't happen in normal operation.
	 */
	if (!OidIsValid(insert_exec_ctx.target_rel_oid))
		return true;

	/*
	 * Check if the target relation was modified during INSERT EXEC.
	 * This flag is set by the ObjectPostAlterHook.
	 */
	return !insert_exec_ctx.is_target_relation_modified;
}

/*
 * Set the flag indicating the target relation was modified.
 * Called from ObjectPostAlterHook when the target table is altered.
 */
void
pltsql_insert_exec_set_target_modified(void)
{
	insert_exec_ctx.is_target_relation_modified = true;
}

/*
 * Get the target relation OID for INSERT EXEC.
 * Used by ObjectPostAlterHook to check if the altered relation is the target.
 */
Oid
pltsql_insert_exec_get_target_rel_oid(void)
{
	return insert_exec_ctx.target_rel_oid;
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
 * T-SQL requires column mismatch errors to take priority over runtime errors
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
	TupleDesc	temp_tupdesc;
	int			temp_natts;
	MemoryContext oldcontext;

	/* Caller must ensure INSERT EXEC is active before calling */
	Assert(pltsql_insert_exec_active());

	/* Temp table must exist - caller checks pltsql_insert_exec_in_execution() */
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
		temp_tupdesc = RelationGetDescr(temp_rel);
		temp_natts = temp_tupdesc->natts;
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
		return false;  /* Not reached, but for clarity */
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
 * TRY-CATCH is at or above the INSERT EXEC level. If TRY-CATCH is inside
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
 * Create a DestReceiver for INSERT EXEC that writes to a temp table.
 */
DestReceiver *
CreateInsertExecDestReceiver(Oid temp_table_oid)
{
	DR_insertexec *self = palloc0_object(DR_insertexec);

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
 * expressions for type conversion using PostgreSQL's ExecBuildProjectionInfo/ExecProject.
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

	/* Create expression context and projection info */
	{
		TupleDesc	proj_tupdesc;

		myState->econtext = CreateStandaloneExprContext();

		/* Copy descriptor - temp_rel is closed after startup, copy keeps it valid */
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

	/* Obtain command ID once - all tuples share the same cid for MVCC consistency */
	myState->cid = GetCurrentCommandId(true);
}

/*
 * insertexec_receive --- receive one tuple and insert into temp table
*/
static bool
insertexec_receive(TupleTableSlot *slot, DestReceiver *self)
{
	DR_insertexec *myState = (DR_insertexec *) self;
	Relation	temp_rel;
	TupleTableSlot *insert_slot;

	/* Open temp table fresh for each tuple */
	temp_rel = table_open(myState->temp_table_oid, RowExclusiveLock);

	ResetExprContext(myState->econtext);
	myState->econtext->ecxt_outertuple = slot;
	insert_slot = ExecProject(myState->proj_info);
	table_tuple_insert(temp_rel, insert_slot, myState->cid, 0, NULL);

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

	Assert(myState->proj_slot != NULL);
	ExecDropSingleTupleTableSlot(myState->proj_slot);
	myState->proj_slot = NULL;

	Assert(myState->econtext != NULL);
	FreeExprContext(myState->econtext, true);
	myState->econtext = NULL;
}

/*
 * insertexec_destroy --- release DestReceiver object
 */
static void
insertexec_destroy(DestReceiver *self)
{
	pfree(self);
}

/*
 * Create a temp table for INSERT EXEC buffering.
 *
 * Creates a PostgreSQL temp table with schema matching
 * the target table. Uses ChooseRelationName to generate a unique name
 * that avoids conflicts. For regular tables, queries pg_attribute to get
 * column definitions (avoids needing SELECT permission for ownership chaining).
 */
Oid
create_insert_exec_temp_table(const char *target_table, const char *column_list, const char *schema_name_in)
{
	StringInfoData create_stmt;
	int			rc;
	Oid			temp_table_oid;
	char	   *physical_schema = NULL;
	MemoryContext oldcontext;
	const char *select_cols;
	char	   *cols_to_free = NULL;
	char	   *qualified_target;
	Oid			temp_nsp_oid;

	/*
	 * Generate a unique temp table name using ChooseRelationName.
	 * This function checks pg_class for conflicts and appends a numeric
	 * suffix if needed, ensuring uniqueness in the pg_temp namespace.
	 */
	temp_nsp_oid = LookupNamespaceNoError("pg_temp");
	oldcontext = MemoryContextSwitchTo(TopMemoryContext);
	insert_exec_ctx.temp_table_name = ChooseRelationName("__insert_exec_buf",
														 NULL,
														 "tmp",
														 temp_nsp_oid,
														 false);
	MemoryContextSwitchTo(oldcontext);

	if (insert_exec_ctx.temp_table_name == NULL)
		elog(ERROR, "INSERT-EXEC: ChooseRelationName returned NULL");

	/*
	 * Parse schema and table name from target_table.
	 * For temp tables (starting with #) and table variables (@),
	 * no schema resolution is needed.
	 */
	if (!(target_table[0] == '#' || target_table[0] == '@'))
	{
		const char *sname = (schema_name_in != NULL) ? schema_name_in : "dbo";
		physical_schema = get_physical_schema_name(get_cur_db_name(), sname);
		if (physical_schema == NULL)
			elog(ERROR, "INSERT-EXEC: Failed to resolve schema for target table: %s",
				 target_table);
	}

	/*
	 * Determine the column list to SELECT.
	 *
	 * If the user specified columns, use them directly.
	 * Otherwise, query the relation to get all non-IDENTITY,
	 * non-computed column names.
	 */
	if (column_list != NULL)
	{
		select_cols = column_list;
	}
	else
	{
		cols_to_free = get_insertable_column_list(target_table, physical_schema);
		select_cols = cols_to_free;
	}

	/*
	 * Build a fully qualified reference for the source table.
	 * For temp tables and table variables, use the name directly.
	 */
	if (physical_schema != NULL)
		qualified_target = psprintf("%s.%s",
									quote_identifier(physical_schema),
									quote_identifier(target_table));
	else
		qualified_target = pstrdup(quote_identifier(target_table));

	/*
	 * Create the temp buffer table by selecting the desired columns
	 * with no rows. PostgreSQL infers column types from the SELECT.
	 */
	initStringInfo(&create_stmt);
	appendStringInfo(&create_stmt,
					 "CREATE TEMP TABLE %s AS SELECT %s FROM %s WITH NO DATA",
					 quote_identifier(insert_exec_ctx.temp_table_name),
					 select_cols, qualified_target);

	if (cols_to_free)
		pfree(cols_to_free);
	pfree(qualified_target);

	/* Clean up parsed names */
	if (physical_schema)
		pfree(physical_schema);

	rc = SPI_execute(create_stmt.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		elog(ERROR, "failed to create INSERT EXEC temp table: %s",
			 SPI_result_code_string(rc));

	pfree(create_stmt.data);

	/* Get the OID of the created temp table */
	temp_table_oid = RelnameGetRelid(insert_exec_ctx.temp_table_name);
	if (!OidIsValid(temp_table_oid))
		elog(ERROR, "could not find INSERT EXEC temp table %s",
			 insert_exec_ctx.temp_table_name);

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
	appendStringInfo(&drop_stmt, "DROP TABLE IF EXISTS %s",
					 quote_identifier(insert_exec_ctx.temp_table_name));

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
 * Flush data from temp table to target table.
 *
 * Executes INSERT INTO target SELECT * FROM temp_table in a subtransaction.
 * Uses SPI_execute for the flush INSERT.
 * Switches to procedure owner's identity for ownership chaining.
 */
void
flush_insert_exec_temp_table(PLtsql_execstate *estate)
{
	const char		*temp_table_name;
	StringInfoData	flush_query;
	int				rc;
	const char		*target_table = insert_exec_ctx.target_table;
	const char		*column_list = insert_exec_ctx.column_list;
	Oid				temp_oid = pltsql_get_insert_exec_temp_table_oid();
	MemoryContext	oldcontext = CurrentMemoryContext;
	ResourceOwner	oldowner = CurrentResourceOwner;
	volatile bool	subtxn_started = false;

	/* Security context for ownership chaining */
	Oid				flush_save_userid = InvalidOid;
	int				flush_save_sec_context = 0;
	volatile bool	flush_switched_context = false;

	if (!OidIsValid(temp_oid) || target_table == NULL)
	{
		return;
	}

	/*
	 * Check if an error occurred during INSERT EXEC that should prevent flush.
	 * Column mismatch errors cause all rows to be rolled back, even if caught
	 * by TRY-CATCH.
	 */
	if (pltsql_insert_exec_had_error())
		return;

	/*
	 * Verify target table schema hasn't changed since INSERT EXEC started.
	 */
	if (!pltsql_insert_exec_verify_schema())
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("INSERT EXEC failed because the stored procedure altered the schema of the target table.")));
	}

	/*
	 * Save the INSERT EXEC context info before clearing it.
	 * We need to temporarily clear the context so that the flush INSERT
	 * behaves like a normal INSERT and fires INSTEAD OF triggers properly.
	 */

	/* Get the dynamically chosen temp table name from the context */
	temp_table_name = insert_exec_ctx.temp_table_name;
	if (temp_table_name == NULL)
	{
		elog(ERROR, "INSERT-EXEC: No temp table name stored, cannot flush");
	}

	initStringInfo(&flush_query);

	if (column_list != NULL)
	{
		/*
		 * User specified columns - use them directly.
		 * The temp table was created with columns in the same order as the
		 * user's column list, so SELECT * gives values in the correct order.
		 */
		appendStringInfo(&flush_query,
			"INSERT INTO %s (%s) SELECT * FROM %s",
			target_table,
			column_list,
			quote_identifier(temp_table_name));
	}
	else
	{
		appendStringInfo(&flush_query,
			"INSERT INTO %s SELECT * FROM %s",
			target_table,
			quote_identifier(temp_table_name));
	}

	/*
	 * Execute the flush INSERT in its own subtransaction that commits
	 * immediately. This is critical for TRY-CATCH behavior.
	 *
	 * We route through exec_stmt_execsql to reuse the standard SQL execution
	 * path which handles triggers, rowcount, and FOUND properly.
	 */
	PG_TRY();
	{
		BeginInternalSubTransaction("insert_exec_flush");
		subtxn_started = true;
		MemoryContextSwitchTo(oldcontext);

		pltsql_insert_exec_set_flush_in_progress(true);

		/* Switch to procedure owner for ownership chaining */
		if (estate && estate->func && OidIsValid(estate->func->fn_oid))
		{
			GetUserIdAndSecContext(&flush_save_userid, &flush_save_sec_context);
			SetUserIdAndSecContext(get_func_owner(estate->func->fn_oid),
								   flush_save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
			flush_switched_context = true;
		}

		/* Execute the flush INSERT using SPI */
		rc = SPI_execute(flush_query.data, false, 0);

		/* Restore security context immediately after execution */
		if (flush_switched_context)
		{
			SetUserIdAndSecContext(flush_save_userid, flush_save_sec_context);
			flush_switched_context = false;
		}

		if (rc != SPI_OK_INSERT && rc != SPI_OK_INSERT_RETURNING)
			elog(ERROR, "INSERT-EXEC: Failed to flush temp table to target");

		/* Update rowcount and FOUND for T-SQL compatibility */
		estate->eval_processed = SPI_processed;
		exec_set_rowcount(SPI_processed);
		exec_set_found(estate, SPI_processed != 0);

		/* Clear the flush flag after successful flush */
		pltsql_insert_exec_set_flush_in_progress(false);

		/* Commit the flush subtransaction - this "locks in" the data */
		ReleaseCurrentSubTransaction();
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;
	}
	PG_CATCH();
	{
		/* Restore security context on error if it was switched */
		if (flush_switched_context)
		{
			SetUserIdAndSecContext(flush_save_userid, flush_save_sec_context);
			flush_switched_context = false;
		}

		/* Clear the flush flag on error */
		pltsql_insert_exec_set_flush_in_progress(false);

		/* Roll back the flush subtransaction on error */
		if (subtxn_started)
		{
			RollbackAndReleaseCurrentSubTransaction();
		}
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;

		pfree(flush_query.data);
		PG_RE_THROW();
	}
	PG_END_TRY();

	pfree(flush_query.data);
}

/*
 * insert_exec_setup - Initialize INSERT EXEC context and create temp table.
 *
 * If start_implicit_txn is true, starts an implicit transaction for stored
 * procedure calls. Returns the temp table OID via temp_table_oid_out.
 * Throws an error if nested INSERT EXEC is detected.
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
	Oid temp_table_oid;

	/* Initialize output */
	*temp_table_oid_out = InvalidOid;

	/* Check for nested INSERT EXEC */
	if (pltsql_insert_exec_active())
	{
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("nested INSERT ... EXECUTE statements are not allowed")));
	}

	/*
	 * Start implicit transaction for INSERT EXEC if requested and not already in one.
	 * This is used for stored procedure calls (exec_stmt_exec) but not for
	 * dynamic SQL (exec_stmt_exec_batch) which has different transaction semantics.
	 */
	if (start_implicit_txn)
	{
		bool in_function = (estate->func &&
							estate->func->fn_oid != InvalidOid &&
							estate->func->fn_prokind == PROKIND_FUNCTION &&
							estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER);

		if (!pltsql_disable_batch_auto_commit &&
			pltsql_support_tsql_transactions() &&
			!IsTransactionBlockActive() &&
			!in_function)
		{
			elog(DEBUG4, "TSQL TXN Start internal transaction for INSERT EXEC");
			pltsql_start_txn();
			pltsql_insert_exec_set_implicit_txn_flag();
			estate->tsql_trigger_flags |= TSQL_TRAN_STARTED;
		}
	}

	/* Set global context info for flush function */
	pltsql_set_insert_exec_context_info(target_table, column_list);

	/* Hold target table open to detect schema alterations during execution */
	pltsql_insert_exec_open_target_table(target_table, schema_name, db_name);

	/* Create temp table based on target table structure */
	temp_table_oid = create_insert_exec_temp_table(target_table, column_list, schema_name);

	/* Set global context so DestReceiver knows where to write */
	pltsql_set_insert_exec_context(temp_table_oid);

	*temp_table_oid_out = temp_table_oid;
	return true;
}

/*
 * insert_exec_error_cleanup - Clean up INSERT EXEC state on error.
 *
 * Sets error flag, clears implicit transaction flag, closes target table,
 * and clears the context.
 */
void
insert_exec_error_cleanup(bool setup_done)
{
	if (setup_done)
	{
		pltsql_insert_exec_set_error_flag();
		pltsql_insert_exec_clear_implicit_txn_flag();
		pltsql_insert_exec_close_target_table();
		pltsql_clear_insert_exec_context();
	}
	else if (pltsql_insert_exec_active())
	{
		/* Cleanup partially initialized context from setup failure */
		pltsql_insert_exec_set_error_flag();
		pltsql_insert_exec_clear_implicit_txn_flag();
		pltsql_insert_exec_close_target_table();
		pltsql_clear_insert_exec_context();
	}
}

/*
 * insert_exec_success_cleanup - Clean up INSERT EXEC after successful execution.
 *
 * Flushes temp table to target, drops temp table, clears context,
 * and commits the implicit transaction if one was started.
 */
void
insert_exec_success_cleanup(PLtsql_execstate *estate, Oid temp_table_oid)
{
	MemoryContext oldcontext = CurrentMemoryContext;
	ResourceOwner oldowner = CurrentResourceOwner;

	/*
	 * Flush temp table to target table and cleanup after procedure completes.
	 */
	PG_TRY();
	{
		/* Flush temp table to target table */
		flush_insert_exec_temp_table(estate);

		/* Close target table after flush completes */
		pltsql_insert_exec_close_target_table();
	}
	PG_CATCH();
	{
		/*
		 * Close target table and drop temp table before clearing context.
		 * Also clear the implicit transaction flag since the transaction
		 * will be rolled back due to the flush error.
		 */
		pltsql_insert_exec_close_target_table();
		drop_insert_exec_temp_table(temp_table_oid);
		pltsql_insert_exec_clear_implicit_txn_flag();
		pltsql_clear_insert_exec_context();
		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Drop temp table in separate subtransaction */
	BeginInternalSubTransaction(NULL);
	MemoryContextSwitchTo(oldcontext);

	PG_TRY();
	{
		drop_insert_exec_temp_table(temp_table_oid);
		ReleaseCurrentSubTransaction();
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;
	}
	PG_CATCH();
	{
		/* DROP failed - log warning but don't fail the INSERT EXEC */
		RollbackAndReleaseCurrentSubTransaction();
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;
		elog(WARNING, "INSERT EXEC: failed to drop temp table, will be cleaned up at transaction end");
		FlushErrorState();
	}
	PG_END_TRY();

	/*
	 * Clear the INSERT EXEC context AFTER the drop completes.
	 * This must be last because it frees temp_table_name which drop needs.
	 */
	pltsql_clear_insert_exec_context();

	/*
	 * Commit the implicit transaction that was started for INSERT EXEC.
	 */
	if (pltsql_insert_exec_started_implicit_txn())
	{
		elog(DEBUG4, "TSQL TXN Commit implicit transaction for INSERT EXEC");
		commit_stmt(estate, true);
		pltsql_insert_exec_clear_implicit_txn_flag();
	}

	/* Clear the TSQL_TRAN_STARTED flag */
	estate->tsql_trigger_flags &= ~TSQL_TRAN_STARTED;
}