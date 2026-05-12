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
 * DestReceiver that writes tuples to a temp table for INSERT EXEC buffering.
 */

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

	/*
	 * Capture the schema signature of the target table.
	 * This is used to detect DROP/ALTER at flush time.
	 */
	oldcontext = CurrentMemoryContext;
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

	table_close(rel, NoLock);  /* Keep the lock (if any) */
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
 * =============================================================================
 * STUB FUNCTIONS - To be implemented in subsequent PRs
 * =============================================================================
 * These functions are placeholders that allow the code to compile.
 * They will be replaced with real implementations in later PRs:
 *   - PR3: CreateInsertExecDestReceiver (DestReceiver implementation)
 *   - PR4: create_insert_exec_temp_table, drop_insert_exec_temp_table
 *   - PR5: flush_insert_exec_temp_table, insert_exec_setup,
 *          insert_exec_error_cleanup, insert_exec_success_cleanup
 * =============================================================================
 */

/*
 * STUB: Create a DestReceiver for INSERT EXEC that writes to a temp table.
 * Real implementation in PR3 (DestReceiver).
 */
DestReceiver *
CreateInsertExecDestReceiver(Oid temp_table_oid)
{
	/* STUB: Returns NULL - real implementation in PR3 */
	return NULL;
}

/*
 * STUB: Create a temp table for INSERT EXEC buffering.
 * Real implementation in PR4 (Temp Table Create/Drop).
 */
Oid
create_insert_exec_temp_table(const char *target_table, const char *column_list, const char *schema_name_in)
{
	/* STUB: Returns InvalidOid - real implementation in PR4 */
	return InvalidOid;
}

/*
 * STUB: Drop the temp table used for INSERT EXEC buffering.
 * Real implementation in PR4 (Temp Table Create/Drop).
 */
void
drop_insert_exec_temp_table(Oid temp_table_oid)
{
	/* STUB: Does nothing - real implementation in PR4 */
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
