
#include "pltsql-2.h"

#include "funcapi.h"

#include "access/table.h"
#include "access/tableam.h"
#include "access/attmap.h"
#include "access/nbtree.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_attribute.h"
#include "catalog/pg_language.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_proc.h"
#include "commands/proclang.h"
#include "commands/trigger.h"
#include "executor/tstoreReceiver.h"
#include "executor/tuptable.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/parsenodes.h"
#include "parser/parse_coerce.h"
#include "utils/acl.h"
#include "utils/lsyscache.h"
#include "storage/lmgr.h"
#include "storage/procarray.h"
#include "pltsql_bulkcopy.h"
#include "pltsql_partition.h"
#include "table_variable_mvcc.h"

#include "catalog.h"
#include "dbcmds.h"
#include "err_handler.h"
#include "multidb.h"
#include "rolecmds.h"
#include "pl_explain.h"
#include "pltsql.h"
#include "pltsql_permissions.h"
#include "rolecmds.h"
#include "session.h"
#include "parser/scansup.h"
#include "parser/parse_oper.h"
#include "src/include/lib/qunique.h"
#include "utils/varlena.h"

/*
 * Helper function to clean up type strings from format_type().
 * 
 * PostgreSQL's format_type() can return type strings with suffixes like
 * "without time zone" for certain datetime types (e.g., "smalldatetime(0) without time zone").
 * These suffixes are not valid in CREATE TABLE statements, so we need to strip them.
 * 
 * Returns a newly allocated string with the suffix removed, or a copy of the
 * original string if no suffix is found.
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
	
	return result;
}

/*
 * INSERT EXEC DestReceiver implementation
 * 
 * This DestReceiver writes tuples to a temp table for INSERT EXEC buffering.
 * Modeled after CreateTransientRelDestReceiver in matview.c but without
 * TABLE_INSERT_FROZEN flag to preserve MVCC semantics.
 */

/* Global context for INSERT EXEC - needed for nested procedure calls */
static Oid insert_exec_temp_table_oid = InvalidOid;
static char *insert_exec_target_table = NULL;
static char *insert_exec_column_list = NULL;
static int insert_exec_base_tran_count = 0;  /* NestedTranCount when INSERT EXEC started */
static int insert_exec_saved_nested_tran_count = 0;  /* Original NestedTranCount to restore on cleanup */
static bool insert_exec_flush_in_progress = false;  /* True during flush phase to block commit_stmt */
static int insert_exec_call_stack_depth = 0;  /* Call stack depth when INSERT EXEC was started */
static bool insert_exec_incremented_tran_count = false;  /* True if INSERT EXEC incremented NestedTranCount */
static bool insert_exec_had_error = false;  /* True if INSERT EXEC had an error - used to skip trancount mismatch check */
static bool insert_exec_pending_drop = false;  /* True if temp table needs to be dropped when SPI is available */
static Oid insert_exec_target_rel_oid = InvalidOid;  /* OID of target table - lock held to detect schema changes */

/*
 * Schema signature for detecting schema changes during INSERT EXEC.
 * We store the column count and column type OIDs at the start of INSERT EXEC,
 * then verify they haven't changed before flushing data to the target table.
 * This detects ALTER TABLE operations that would cause SQL Server error 556.
 */
typedef struct InsertExecSchemaSignature
{
	int			natts;			/* Number of columns */
	Oid		   *atttypids;		/* Array of column type OIDs */
	int32	   *atttypmods;		/* Array of column type modifiers */
} InsertExecSchemaSignature;

static InsertExecSchemaSignature *insert_exec_schema_sig = NULL;

/* DestReceiver struct for INSERT EXEC */
typedef struct
{
	DestReceiver pub;			/* public fields */
	Oid			temp_table_oid;	/* OID of temp table to insert into */
	TupleDesc	typeinfo;		/* tuple descriptor from startup */
	uint64		rows_inserted;	/* count of rows inserted */
} DR_insertexec;

/* Forward declarations for DestReceiver callbacks */
static void insertexec_startup(DestReceiver *self, int operation, TupleDesc typeinfo);
static bool insertexec_receive(TupleTableSlot *slot, DestReceiver *self);
static void insertexec_shutdown(DestReceiver *self);
static void insertexec_destroy(DestReceiver *self);

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
	PLExecStateCallStack *cur;
	int depth = 0;
	
	/* Clear any previous context */
	if (insert_exec_target_table)
	{
		pfree(insert_exec_target_table);
		insert_exec_target_table = NULL;
	}
	if (insert_exec_column_list)
	{
		pfree(insert_exec_column_list);
		insert_exec_column_list = NULL;
	}
	
	/* Allocate in TopMemoryContext so strings survive error handling */
	oldcontext = MemoryContextSwitchTo(TopMemoryContext);
	insert_exec_target_table = target_table ? pstrdup(target_table) : NULL;
	insert_exec_column_list = column_list ? pstrdup(column_list) : NULL;
	MemoryContextSwitchTo(oldcontext);
	
	/* Record the call stack depth when INSERT EXEC was started */
	cur = exec_state_call_stack;
	while (cur != NULL)
	{
		depth++;
		cur = cur->next;
	}
	insert_exec_call_stack_depth = depth;
	
	/*
	 * Record the NestedTranCount when INSERT EXEC started.
	 * In SQL Server, INSERT EXEC implicitly starts a transaction, so @@TRANCOUNT=1.
	 * When the procedure does BEGIN TRAN, it becomes @@TRANCOUNT=2, allowing COMMIT.
	 * 
	 * Save the original NestedTranCount so we can restore it on cleanup.
	 * This is needed because during INSERT EXEC, BEGIN TRAN increments NestedTranCount
	 * but doesn't start a real transaction. If an error occurs, we need to restore
	 * NestedTranCount to its original value.
	 */
	insert_exec_saved_nested_tran_count = NestedTranCount;
	
	/*
	 * In SQL Server, INSERT EXEC implicitly starts a transaction if there isn't one already.
	 * - If @@TRANCOUNT=0 before INSERT EXEC, it becomes 1 (implicit transaction)
	 * - If @@TRANCOUNT>=1 before INSERT EXEC, it stays the same (already in a transaction)
	 * 
	 * We simulate this by only incrementing NestedTranCount if it's currently 0.
	 * The base_tran_count is the @@TRANCOUNT value that the procedure sees at start.
	 */
	insert_exec_incremented_tran_count = false;
	if (NestedTranCount == 0)
	{
		NestedTranCount = 1;
		insert_exec_incremented_tran_count = true;
		
		/* Update the protocol plugin with the new NestedTranCount */
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_at_at_stat_var)
			(*pltsql_protocol_plugin_ptr)->set_at_at_stat_var(TRANCOUNT_TYPE, NestedTranCount, 0);
	}
	
	insert_exec_base_tran_count = NestedTranCount;
}

/*
 * Set the global INSERT EXEC context with temp table OID.
 * Called when temp table is created in exec_stmt_exec.
 */
void
pltsql_set_insert_exec_context(Oid temp_table_oid)
{
	insert_exec_temp_table_oid = temp_table_oid;
}

/*
 * Clear the global INSERT EXEC context.
 * Called when exiting INSERT EXEC context.
 * 
 * We only restore NestedTranCount if INSERT EXEC incremented it (from 0 to 1).
 * If COMMIT was called inside INSERT EXEC (and allowed because @@TRANCOUNT > 1),
 * the decrement should persist so that the transaction count mismatch warning
 * is generated.
 */
void
pltsql_clear_insert_exec_context(void)
{
	/*
	 * Only restore NestedTranCount if INSERT EXEC incremented it.
	 * This handles the case where INSERT EXEC started with @@TRANCOUNT=0
	 * and we incremented it to 1 for the implicit transaction.
	 * 
	 * If INSERT EXEC started with @@TRANCOUNT>=1, we don't restore because:
	 * 1. We didn't increment it
	 * 2. If COMMIT was called inside, the decrement should persist
	 */
	if (insert_exec_target_table != NULL && insert_exec_incremented_tran_count)
	{
		NestedTranCount = insert_exec_saved_nested_tran_count;
		
		/* Update the protocol plugin with the restored NestedTranCount */
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_at_at_stat_var)
			(*pltsql_protocol_plugin_ptr)->set_at_at_stat_var(TRANCOUNT_TYPE, NestedTranCount, 0);
	}
	
	insert_exec_temp_table_oid = InvalidOid;
	insert_exec_base_tran_count = 0;  /* Reset base transaction count */
	insert_exec_saved_nested_tran_count = 0;  /* Reset saved nested tran count */
	insert_exec_call_stack_depth = 0;  /* Reset call stack depth */
	insert_exec_incremented_tran_count = false;  /* Reset incremented flag */
	/* Note: We do NOT reset insert_exec_had_error here - it's reset by pltsql_insert_exec_clear_error_flag() */
	if (insert_exec_target_table)
	{
		pfree(insert_exec_target_table);
		insert_exec_target_table = NULL;
	}
	if (insert_exec_column_list)
	{
		pfree(insert_exec_column_list);
		insert_exec_column_list = NULL;
	}
}

/*
 * Set the INSERT EXEC error flag.
 * Called when an error occurs during INSERT EXEC.
 * This flag is used to skip the transaction count mismatch check.
 */
void
pltsql_insert_exec_set_error_flag(void)
{
	insert_exec_had_error = true;
}

/*
 * Check if INSERT EXEC had an error.
 * Used to skip the transaction count mismatch check.
 */
bool
pltsql_insert_exec_had_error(void)
{
	return insert_exec_had_error;
}

/*
 * Clear the INSERT EXEC error flag.
 * Called after the error has been handled.
 */
void
pltsql_insert_exec_clear_error_flag(void)
{
	insert_exec_had_error = false;
}

/*
 * Set the pending drop flag.
 * Called when an error occurs and we can't drop the temp table immediately.
 */
void
pltsql_insert_exec_set_pending_drop(void)
{
	insert_exec_pending_drop = true;
}

/*
 * Check and drop the pending temp table if needed.
 * Called at the start of each INSERT EXEC to clean up any leftover temp table.
 * This handles the case where a previous INSERT EXEC failed and couldn't
 * drop its temp table because SPI wasn't available in the error context.
 */
void
pltsql_insert_exec_check_pending_drop(void)
{
	if (insert_exec_pending_drop)
	{
		char		temp_table_name[NAMEDATALEN];
		StringInfoData drop_stmt;
		int			rc;

		snprintf(temp_table_name, sizeof(temp_table_name),
				 "#insert_exec_buf_%d", MyProcPid);

		initStringInfo(&drop_stmt);
		appendStringInfo(&drop_stmt, "DROP TABLE IF EXISTS %s", temp_table_name);

		rc = SPI_execute(drop_stmt.data, false, 0);
		if (rc != SPI_OK_UTILITY)
			elog(WARNING, "failed to drop pending INSERT EXEC temp table: %s",
				 SPI_result_code_string(rc));

		pfree(drop_stmt.data);
		insert_exec_pending_drop = false;
	}
}

/*
 * Open and hold the target table during INSERT EXEC execution.
 * 
 * This function captures the schema signature (column count and types) of the
 * target table at the start of INSERT EXEC. Before flushing data to the target,
 * we verify the schema hasn't changed. If it has, we raise SQL Server error 556:
 * "INSERT EXEC failed because the stored procedure altered the schema of the target table."
 * 
 * IMPORTANT: We only acquire a lock, not hold the Relation pointer open.
 * Holding a Relation pointer across subtransaction boundaries causes issues
 * with resource owners and relcache invalidation, especially in upgrade tests
 * where table OIDs may change.
 * 
 * For temp tables and table variables (starting with # or @), we don't need
 * to lock them because they're session-local and can't be modified by
 * other sessions.
 */
void
pltsql_insert_exec_open_target_table(const char *target_table)
{
	RangeVar   *rv;
	Oid			relid;
	char	   *schema_name = NULL;
	char	   *table_name = NULL;
	char	   *physical_schema = NULL;
	char	   *target_copy;
	char	   *dot_pos;
	char	   *second_dot;
	Relation	rel;
	TupleDesc	tupdesc;
	int			i;
	MemoryContext oldcontext;

	elog(DEBUG1, "INSERT-EXEC: open_target_table called with target='%s'", 
		 target_table ? target_table : "NULL");

	/* Skip for temp tables and table variables */
	if (target_table == NULL || target_table[0] == '#' || target_table[0] == '@')
	{
		elog(DEBUG1, "INSERT-EXEC: Skipping schema capture for temp table or table variable");
		return;
	}

	/* Parse schema and table name from target_table */
	target_copy = pstrdup(target_table);
	
	/* Find the last dot to separate schema from table */
	dot_pos = strrchr(target_copy, '.');
	if (dot_pos != NULL)
	{
		*dot_pos = '\0';
		table_name = pstrdup(dot_pos + 1);
		
		/* Check if there's another dot (db.schema.table) */
		second_dot = strrchr(target_copy, '.');
		if (second_dot != NULL)
		{
			/* db.schema.table - schema is after the second dot */
			schema_name = pstrdup(second_dot + 1);
		}
		else
		{
			/* schema.table */
			schema_name = pstrdup(target_copy);
		}
	}
	else
	{
		/* Just table name, use dbo as default */
		table_name = pstrdup(target_copy);
		schema_name = pstrdup("dbo");
	}
	pfree(target_copy);
	
	/* Convert logical schema name to physical schema name */
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
	 * This lock will be held until the end of the transaction (or until
	 * explicitly released).
	 */
	LockRelationOid(relid, RowExclusiveLock);
	insert_exec_target_rel_oid = relid;
	
	/*
	 * Capture the schema signature of the target table.
	 * We open the relation briefly to get the tuple descriptor, then close it.
	 * The lock we acquired above will remain held.
	 */
	rel = table_open(relid, NoLock);  /* Already have RowExclusiveLock */
	tupdesc = RelationGetDescr(rel);
	
	/* Allocate schema signature in TopMemoryContext so it survives error handling */
	oldcontext = MemoryContextSwitchTo(TopMemoryContext);
	
	/* Free any previous schema signature */
	if (insert_exec_schema_sig != NULL)
	{
		if (insert_exec_schema_sig->atttypids)
			pfree(insert_exec_schema_sig->atttypids);
		if (insert_exec_schema_sig->atttypmods)
			pfree(insert_exec_schema_sig->atttypmods);
		pfree(insert_exec_schema_sig);
		insert_exec_schema_sig = NULL;
	}
	
	insert_exec_schema_sig = palloc(sizeof(InsertExecSchemaSignature));
	insert_exec_schema_sig->natts = tupdesc->natts;
	insert_exec_schema_sig->atttypids = palloc(tupdesc->natts * sizeof(Oid));
	insert_exec_schema_sig->atttypmods = palloc(tupdesc->natts * sizeof(int32));
	
	for (i = 0; i < tupdesc->natts; i++)
	{
		Form_pg_attribute attr = TupleDescAttr(tupdesc, i);
		insert_exec_schema_sig->atttypids[i] = attr->atttypid;
		insert_exec_schema_sig->atttypmods[i] = attr->atttypmod;
	}
	
	elog(DEBUG1, "INSERT-EXEC: Captured schema signature for target table OID %u with %d columns",
		 relid, insert_exec_schema_sig->natts);
	
	MemoryContextSwitchTo(oldcontext);
	
	table_close(rel, NoLock);  /* Keep the lock */
}

/*
 * Close the target table that was held open during INSERT EXEC.
 * Called after the flush completes or on error cleanup.
 * 
 * Note: We only release the lock if we're not in an aborted transaction state.
 * If the transaction was aborted (e.g., due to COMMIT without BEGIN TRAN error),
 * the lock has already been released by the transaction abort, and trying to
 * unlock it would cause an error.
 * 
 * In major version upgrade scenarios, the OID may be stale, so we wrap the
 * unlock in a PG_TRY block to handle errors gracefully.
 */
void
pltsql_insert_exec_close_target_table(void)
{
	if (OidIsValid(insert_exec_target_rel_oid))
	{
		/*
		 * Only release the lock if we're not in an aborted transaction state.
		 * In an aborted transaction, all locks have already been released.
		 */
		if (!IsAbortedTransactionBlockState())
		{
			MemoryContext oldcontext = CurrentMemoryContext;
			PG_TRY();
			{
				UnlockRelationOid(insert_exec_target_rel_oid, RowExclusiveLock);
			}
			PG_CATCH();
			{
				/* 
				 * Could not unlock - likely stale OID from upgrade scenario
				 * or relation was dropped. Just ignore the error.
				 */
				MemoryContextSwitchTo(oldcontext);
				FlushErrorState();
				elog(DEBUG1, "INSERT-EXEC: Could not unlock target table OID %u, ignoring",
					 insert_exec_target_rel_oid);
			}
			PG_END_TRY();
		}
		insert_exec_target_rel_oid = InvalidOid;
	}
	
	/* Free the schema signature */
	if (insert_exec_schema_sig != NULL)
	{
		if (insert_exec_schema_sig->atttypids)
			pfree(insert_exec_schema_sig->atttypids);
		if (insert_exec_schema_sig->atttypmods)
			pfree(insert_exec_schema_sig->atttypmods);
		pfree(insert_exec_schema_sig);
		insert_exec_schema_sig = NULL;
	}
}

/*
 * Verify that the target table schema hasn't changed since INSERT EXEC started.
 * Returns true if schema is unchanged, false if it has changed.
 * 
 * This is called before flushing data to the target table to detect if the
 * executed procedure altered the target table's schema (SQL Server error 556).
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
	if (insert_exec_schema_sig == NULL || !OidIsValid(insert_exec_target_rel_oid))
		return true;
	
	/*
	 * Try to open the relation. In major version upgrade scenarios, the OID
	 * may be stale (table was recreated with a different OID). In that case,
	 * we skip the schema check - the actual INSERT will validate the data.
	 */
	oldcontext = CurrentMemoryContext;
	PG_TRY();
	{
		rel = table_open(insert_exec_target_rel_oid, NoLock);  /* Already have lock */
	}
	PG_CATCH();
	{
		/* 
		 * Could not open relation - likely stale OID from upgrade scenario.
		 * Skip the schema check and let the INSERT validate the data.
		 */
		MemoryContextSwitchTo(oldcontext);
		FlushErrorState();
		elog(DEBUG1, "INSERT-EXEC: Could not open target table OID %u for schema verification, skipping check",
			 insert_exec_target_rel_oid);
		return true;
	}
	PG_END_TRY();
	
	tupdesc = RelationGetDescr(rel);
	
	/* Check if column count changed */
	if (tupdesc->natts != insert_exec_schema_sig->natts)
	{
		elog(DEBUG1, "INSERT-EXEC: Schema changed - column count: original=%d, current=%d",
			 insert_exec_schema_sig->natts, tupdesc->natts);
		schema_changed = true;
	}
	else
	{
		/* Check if any column type changed */
		for (i = 0; i < tupdesc->natts; i++)
		{
			Form_pg_attribute attr = TupleDescAttr(tupdesc, i);
			if (attr->atttypid != insert_exec_schema_sig->atttypids[i] ||
				attr->atttypmod != insert_exec_schema_sig->atttypmods[i])
			{
				elog(DEBUG1, "INSERT-EXEC: Schema changed - column %d type: original=%u, current=%u",
					 i, insert_exec_schema_sig->atttypids[i], attr->atttypid);
				schema_changed = true;
				break;
			}
		}
	}
	
	if (!schema_changed)
		elog(DEBUG1, "INSERT-EXEC: Schema unchanged, %d columns verified", tupdesc->natts);
	
	table_close(rel, NoLock);  /* Keep the lock */
	
	return !schema_changed;
}

/*
 * Check if INSERT EXEC context is active (target table info is set).
 * This returns true even before temp table is created.
 */
bool
pltsql_insert_exec_active(void)
{
	return (insert_exec_target_table != NULL);
}

/*
 * Check if INSERT EXEC flush is in progress.
 * During flush, we temporarily clear the INSERT EXEC context to allow
 * INSTEAD OF triggers to fire, but we still need to block commit_stmt.
 */
bool
pltsql_insert_exec_flush_in_progress(void)
{
	return insert_exec_flush_in_progress;
}

/*
 * Get the base transaction count for INSERT EXEC.
 * This is the NestedTranCount + 1 when INSERT EXEC started.
 * Used to determine if COMMIT is allowed during INSERT EXEC.
 */
int
pltsql_get_insert_exec_base_tran_count(void)
{
	return insert_exec_base_tran_count;
}

/*
 * Get the temp table OID for INSERT EXEC buffering.
 */
Oid
pltsql_get_insert_exec_temp_table_oid(void)
{
	return insert_exec_temp_table_oid;
}

/*
 * Get the target table name for INSERT EXEC.
 */
const char *
pltsql_get_insert_exec_target_table(void)
{
	return insert_exec_target_table;
}

/*
 * Get the column list for INSERT EXEC.
 */
const char *
pltsql_get_insert_exec_column_list(void)
{
	return insert_exec_column_list;
}

/*
 * Increment TRY-CATCH depth when entering a TRY block during INSERT EXEC.
 * NOTE: This function is now a no-op. TRY-CATCH detection is done via err_ctx_stack.
 * Kept for API compatibility but does nothing.
 */
void
pltsql_insert_exec_enter_trycatch(void)
{
	/* No-op: TRY-CATCH detection is done via err_ctx_stack in pltsql_insert_exec_in_trycatch() */
}

/*
 * Decrement TRY-CATCH depth when exiting a TRY block during INSERT EXEC.
 * NOTE: This function is now a no-op. TRY-CATCH detection is done via err_ctx_stack.
 * Kept for API compatibility but does nothing.
 */
void
pltsql_insert_exec_exit_trycatch(void)
{
	/* No-op: TRY-CATCH detection is done via err_ctx_stack in pltsql_insert_exec_in_trycatch() */
}

/*
 * Check if we're inside a TRY-CATCH block during INSERT EXEC.
 * This checks the exec_state_call_stack to see if any estate has a TRY-CATCH block active.
 */
bool
pltsql_insert_exec_in_trycatch(void)
{
	PLExecStateCallStack *cur;
	
	if (insert_exec_target_table == NULL)
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
 * Check if we should clean up INSERT EXEC context when a TRY-CATCH catches an error.
 * 
 * This is used in the sigsetjmp handler to determine if we should clean up the
 * INSERT EXEC context. We should only clean up if the TRY-CATCH that catches
 * the error is at the same level or higher than where INSERT EXEC was started.
 * 
 * If the TRY-CATCH is inside the procedure being executed (deeper call stack),
 * we should NOT clean up because the INSERT EXEC is still in progress.
 * 
 * Returns true if we should clean up, false otherwise.
 */
bool
pltsql_insert_exec_should_cleanup_on_trycatch(void)
{
	PLExecStateCallStack *cur;
	int current_depth = 0;
	
	if (insert_exec_target_table == NULL)
		return false;
	
	/* Get current call stack depth */
	cur = exec_state_call_stack;
	while (cur != NULL)
	{
		current_depth++;
		cur = cur->next;
	}
	
	/*
	 * If current depth is greater than INSERT EXEC depth, the TRY-CATCH
	 * is inside the procedure being executed, so don't clean up.
	 * 
	 * If current depth is equal to or less than INSERT EXEC depth, the
	 * TRY-CATCH is at the same level or higher, so clean up.
	 */
	return current_depth <= insert_exec_call_stack_depth;
}

/*
 * Get and clear the temp table OID for INSERT EXEC cleanup.
 * Called from iterative_exec.c after TRY-CATCH catches an error.
 * Returns the temp table OID that needs to be dropped, or InvalidOid if none.
 * 
 * This is used when an error occurs during INSERT EXEC and is caught by TRY-CATCH.
 * The PG_CATCH in exec_stmt_exec clears the INSERT EXEC context but leaves the
 * temp table OID for iterative_exec.c to drop.
 */
Oid
pltsql_get_and_clear_insert_exec_temp_table_for_cleanup(void)
{
	Oid temp_oid = insert_exec_temp_table_oid;
	insert_exec_temp_table_oid = InvalidOid;
	return temp_oid;
}

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
 * We do NOT open the relation here. Instead, we open/close it for each
 * tuple in insertexec_receive. This ensures the relation handle doesn't
 * become invalid if a subtransaction rollback happens during procedure
 * execution (e.g., inner TRY/CATCH blocks).
 * 
 * We DO validate that the number of columns in the result set matches
 * the temp table structure. If there's a mismatch, we raise an error
 * similar to SQL Server's error 213.
 */
static void
insertexec_startup(DestReceiver *self, int operation, TupleDesc typeinfo)
{
	DR_insertexec *myState = (DR_insertexec *) self;
	Relation	temp_rel;
	TupleDesc	temp_tupdesc;
	int			result_natts;
	int			temp_natts;

	/* Just store the tuple descriptor for later use */
	myState->typeinfo = typeinfo;
	myState->rows_inserted = 0;

	/*
	 * Validate column count: the number of columns in the result set
	 * must match the number of columns in the temp table.
	 * 
	 * SQL Server error 213: "Column name or number of supplied values 
	 * does not match table definition."
	 */
	result_natts = typeinfo->natts;
	
	/* Open temp table to get its tuple descriptor */
	temp_rel = table_open(myState->temp_table_oid, AccessShareLock);
	temp_tupdesc = RelationGetDescr(temp_rel);
	temp_natts = temp_tupdesc->natts;
	table_close(temp_rel, AccessShareLock);
	
	if (result_natts != temp_natts)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Column name or number of supplied values does not match table definition.")));
	}
}

/*
 * insertexec_receive --- receive one tuple and insert into temp table
 * 
 * Opens the relation, inserts the tuple, and closes the relation for each
 * tuple. This is less efficient than keeping the relation open, but it
 * ensures we don't hold relation handles across subtransaction boundaries.
 * 
 * Performs type coercion when source and target types differ. This is needed
 * because SQL Server implicitly converts types during INSERT EXEC (e.g., INT
 * to VARCHAR), but PostgreSQL's table_tuple_insert doesn't do this.
 */
static bool
insertexec_receive(TupleTableSlot *slot, DestReceiver *self)
{
	DR_insertexec *myState = (DR_insertexec *) self;
	Relation	temp_rel;
	CommandId	cid;
	TupleDesc	temp_tupdesc;
	TupleDesc	src_tupdesc;
	int			natts;
	int			i;
	bool		needs_coercion = false;
	TupleTableSlot *insert_slot;

	/*
	 * Open the temp table fresh for each tuple.
	 * This ensures we don't hold a stale relation handle if a subtransaction
	 * was rolled back since the last insert.
	 */
	temp_rel = table_open(myState->temp_table_oid, RowExclusiveLock);
	cid = GetCurrentCommandId(true);
	
	temp_tupdesc = RelationGetDescr(temp_rel);
	src_tupdesc = myState->typeinfo;
	natts = temp_tupdesc->natts;
	
	/*
	 * Check if any column needs type coercion.
	 * We compare the type OIDs and typmods of source and target columns.
	 * Even if types are the same, we need coercion if typmods differ
	 * (e.g., varchar(max) to varchar(10)) to enforce length constraints.
	 */
	for (i = 0; i < natts; i++)
	{
		Form_pg_attribute src_att = TupleDescAttr(src_tupdesc, i);
		Form_pg_attribute tgt_att = TupleDescAttr(temp_tupdesc, i);
		
		if (src_att->atttypid != tgt_att->atttypid ||
			(src_att->atttypmod != tgt_att->atttypmod && tgt_att->atttypmod != -1))
		{
			needs_coercion = true;
			break;
		}
	}
	
	if (needs_coercion)
	{
		/*
		 * Create a new slot with the temp table's tuple descriptor and
		 * copy values with type coercion where needed.
		 */
		Datum	   *values;
		bool	   *nulls;
		
		values = (Datum *) palloc(natts * sizeof(Datum));
		nulls = (bool *) palloc(natts * sizeof(bool));
		
		/* Make sure the source slot is materialized */
		slot_getallattrs(slot);
		
		for (i = 0; i < natts; i++)
		{
			Form_pg_attribute src_att = TupleDescAttr(src_tupdesc, i);
			Form_pg_attribute tgt_att = TupleDescAttr(temp_tupdesc, i);
			
			if (slot->tts_isnull[i])
			{
				values[i] = (Datum) 0;
				nulls[i] = true;
			}
			else if (src_att->atttypid == tgt_att->atttypid &&
					 (src_att->atttypmod == tgt_att->atttypmod || tgt_att->atttypmod == -1))
			{
				/* Same type and compatible typmod, no coercion needed */
				values[i] = slot->tts_values[i];
				nulls[i] = false;
			}
			else if (src_att->atttypid == tgt_att->atttypid)
			{
				/*
				 * Same type but different typmod - need to apply length/precision constraint.
				 * Use find_typmod_coercion_function to get the typmod coercion function.
				 */
				Oid			funcid;
				CoercionPathType pathtype;
				
				pathtype = find_typmod_coercion_function(tgt_att->atttypid, &funcid);
				
				if (pathtype == COERCION_PATH_FUNC && OidIsValid(funcid))
				{
					/* Apply the typmod coercion function */
					int nargs = get_func_nargs(funcid);
					switch (nargs)
					{
						case 2:
							values[i] = OidFunctionCall2Coll(funcid,
															 tgt_att->attcollation,
															 slot->tts_values[i],
															 Int32GetDatum(tgt_att->atttypmod));
							break;
						case 3:
							values[i] = OidFunctionCall3Coll(funcid,
															 tgt_att->attcollation,
															 slot->tts_values[i],
															 Int32GetDatum(tgt_att->atttypmod),
															 BoolGetDatum(false));
							break;
						default:
							/* Unexpected - just copy the value */
							values[i] = slot->tts_values[i];
					}
				}
				else
				{
					/* No typmod coercion function - just copy the value */
					values[i] = slot->tts_values[i];
				}
				nulls[i] = false;
			}
			else
			{
				/*
				 * Different types - use PostgreSQL's coercion system.
				 * This properly handles SQL Server's implicit type conversions
				 * (e.g., INT to DATETIME, VARCHAR to INT, etc.)
				 */
				Oid			funcid;
				CoercionPathType pathtype;
				Oid			typioparam;
				bool		isVarlena;
				int			nargs;
				
				pathtype = find_coercion_pathway(tgt_att->atttypid, src_att->atttypid,
												 COERCION_ASSIGNMENT, &funcid);
				
				switch (pathtype)
				{
					case COERCION_PATH_FUNC:
						/* Use the cast function */
						nargs = get_func_nargs(funcid);
						switch (nargs)
						{
							case 1:
								values[i] = OidFunctionCall1Coll(funcid, 
																 tgt_att->attcollation,
																 slot->tts_values[i]);
								break;
							case 2:
								values[i] = OidFunctionCall2Coll(funcid,
																 tgt_att->attcollation,
																 slot->tts_values[i],
																 Int32GetDatum(tgt_att->atttypmod));
								break;
							case 3:
								values[i] = OidFunctionCall3Coll(funcid,
																 tgt_att->attcollation,
																 slot->tts_values[i],
																 Int32GetDatum(tgt_att->atttypmod),
																 BoolGetDatum(false));
								break;
							default:
								elog(ERROR, "unsupported number of arguments (%d) for cast function", nargs);
						}
						break;
						
					case COERCION_PATH_COERCEVIAIO:
						/* Convert via I/O functions (text representation) */
						{
							Oid			src_typoutput;
							Oid			tgt_typinput;
							char	   *str_value;
							
							getTypeOutputInfo(src_att->atttypid, &src_typoutput, &isVarlena);
							str_value = OidOutputFunctionCall(src_typoutput, slot->tts_values[i]);
							
							getTypeInputInfo(tgt_att->atttypid, &tgt_typinput, &typioparam);
							values[i] = OidInputFunctionCall(tgt_typinput, str_value,
															 typioparam, tgt_att->atttypmod);
							pfree(str_value);
						}
						break;
						
					case COERCION_PATH_RELABELTYPE:
						/* Binary compatible - just copy the value */
						values[i] = slot->tts_values[i];
						break;
						
					case COERCION_PATH_ARRAYCOERCE:
						/* Array coercion - not expected for INSERT EXEC */
						elog(ERROR, "array coercion not supported in INSERT EXEC");
						break;
						
					case COERCION_PATH_NONE:
					default:
						ereport(ERROR,
								(errcode(ERRCODE_CANNOT_COERCE),
								 errmsg("cannot convert type %s to %s",
										format_type_be(src_att->atttypid),
										format_type_be(tgt_att->atttypid))));
				}
				nulls[i] = false;
			}
		}
		
		/* Create a slot for the temp table and store the converted values */
		insert_slot = MakeSingleTupleTableSlot(temp_tupdesc, &TTSOpsVirtual);
		ExecStoreVirtualTuple(insert_slot);
		
		/* Copy values into the slot */
		for (i = 0; i < natts; i++)
		{
			insert_slot->tts_values[i] = values[i];
			insert_slot->tts_isnull[i] = nulls[i];
		}
		
		/* Insert the coerced tuple */
		table_tuple_insert(temp_rel,
						   insert_slot,
						   cid,
						   0,
						   NULL);
		
		ExecDropSingleTupleTableSlot(insert_slot);
		pfree(values);
		pfree(nulls);
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
 * Nothing to do here since we close the relation after each tuple.
 */
static void
insertexec_shutdown(DestReceiver *self)
{
	/* Nothing to clean up - relation is closed after each tuple */
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
 * The temp table structure is based on the target table.
 * IDENTITY and computed columns are excluded since procedure results
 * won't include them.
 * Returns the OID of the created temp table.
 * 
 * OWNERSHIP CHAINING FIX:
 * We use catalog queries (pg_attribute) to get column definitions instead of
 * SELECT ... INTO ... FROM target_table. This avoids requiring SELECT permission
 * on the target table, which the caller may not have (only the procedure owner does).
 * The catalog is readable by everyone, so this approach works with ownership chaining.
 */
Oid
create_insert_exec_temp_table(const char *target_table, const char *column_list)
{
	StringInfoData create_stmt;
	StringInfoData col_query;
	StringInfoData drop_stmt;
	int			rc;
	Oid			temp_table_oid;
	char		temp_table_name[NAMEDATALEN];
	char	   *schema_name = NULL;
	char	   *table_name = NULL;
	char	   *physical_schema = NULL;
	char	   *dot_pos;
	char	   *second_dot;
	char	   *target_copy;

	elog(DEBUG1, "INSERT-EXEC: create_insert_exec_temp_table called with target='%s'",
		 target_table ? target_table : "NULL");

	/* Generate unique temp table name using backend PID */
	snprintf(temp_table_name, sizeof(temp_table_name),
			 "#insert_exec_buf_%d", MyProcPid);

	/*
	 * Always try to drop any existing temp table with this name first.
	 * This handles the case where a previous INSERT EXEC failed and couldn't
	 * clean up its temp table (e.g., error during type coercion in insertexec_receive).
	 * Using DROP TABLE IF EXISTS is safe and ensures we start with a clean slate.
	 */
	initStringInfo(&drop_stmt);
	appendStringInfo(&drop_stmt, "DROP TABLE IF EXISTS %s", temp_table_name);
	rc = SPI_execute(drop_stmt.data, false, 0);
	pfree(drop_stmt.data);
	if (rc != SPI_OK_UTILITY)
		elog(WARNING, "failed to drop existing INSERT EXEC temp table: %s",
			 SPI_result_code_string(rc));

	/* Reset the pending drop flag since we just cleaned up */
	insert_exec_pending_drop = false;

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
	}
	else
	{
		target_copy = pstrdup(target_table);
		
		/* Find the last dot to separate schema from table */
		dot_pos = strrchr(target_copy, '.');
		if (dot_pos != NULL)
		{
			*dot_pos = '\0';
			table_name = pstrdup(dot_pos + 1);
			
			/* Check if there's another dot (db.schema.table) */
			second_dot = strrchr(target_copy, '.');
			if (second_dot != NULL)
			{
				/* db.schema.table - schema is after the second dot */
				schema_name = pstrdup(second_dot + 1);
			}
			else
			{
				/* schema.table */
				schema_name = pstrdup(target_copy);
			}
		}
		else
		{
			/* Just table name, use dbo as default */
			table_name = pstrdup(target_copy);
			schema_name = pstrdup("dbo");
		}
		pfree(target_copy);
		
		/* Convert logical schema name to physical schema name */
		physical_schema = get_physical_schema_name(get_cur_db_name(), schema_name);
	}

	initStringInfo(&create_stmt);
	
	if (column_list != NULL)
	{
		/*
		 * User specified columns - create temp table with only those columns.
		 * 
		 * For temp tables and table variables (physical_schema == NULL), we can
		 * use SELECT ... INTO because they're always owned by the current user.
		 * 
		 * For regular tables, we need to use pg_attribute to get column definitions
		 * to avoid needing SELECT permission (ownership chaining fix).
		 */
		if (physical_schema == NULL)
		{
			/* Temp table or table variable - use SELECT ... INTO */
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
			
			elog(DEBUG1, "INSERT-EXEC: Column query for column_list: %s", col_query.data);
			
			rc = SPI_execute(col_query.data, false, 0);
			if (rc != SPI_OK_SELECT)
			{
				pfree(col_query.data);
				pfree(col_defs.data);
				elog(ERROR, "failed to query target table columns for INSERT EXEC: %s",
					 SPI_result_code_string(rc));
			}
			
			proc_count = SPI_processed;
			elog(DEBUG1, "INSERT-EXEC: Column query returned %d rows", proc_count);
			
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
		 * 
		 * For temp tables (target starts with #) and table variables (start with @),
		 * use SELECT * INTO ... FROM ... WHERE 1=0 because they are always owned by
		 * the current user and we don't need to worry about SELECT permission.
		 * Also, querying pg_attribute for temp tables can be unreliable in some SPI contexts.
		 * 
		 * For regular tables, query pg_attribute for column definitions to avoid
		 * needing SELECT permission on the target table (ownership chaining fix).
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
				/* Fall back to SELECT * INTO */
				appendStringInfo(&create_stmt, 
					"SELECT * INTO %s FROM %s WHERE 1=0",
					temp_table_name, target_table);
			}
			else
			{
				proc_count = SPI_processed;
				
				if (proc_count == 0)
				{
					/* No columns found, fall back to SELECT * INTO */
					pfree(col_query.data);
					pfree(non_identity_cols.data);
					appendStringInfo(&create_stmt, 
						"SELECT * INTO %s FROM %s WHERE 1=0",
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
						"SELECT %s INTO %s FROM %s WHERE 1=0",
						non_identity_cols.data, temp_table_name, target_table);
					
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
			
			elog(DEBUG1, "INSERT-EXEC: Column query: %s", col_query.data);
			
			rc = SPI_execute(col_query.data, false, 0);
			if (rc != SPI_OK_SELECT)
			{
				pfree(col_query.data);
				pfree(col_defs.data);
				elog(ERROR, "failed to query target table columns: %s",
					 SPI_result_code_string(rc));
			}
			
			proc_count = SPI_processed;
			elog(DEBUG1, "INSERT-EXEC: Column query returned %d rows", proc_count);
			
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

	elog(DEBUG1, "INSERT-EXEC: Creating temp table: %s", create_stmt.data);

	/* 
	 * Execute the statement to create temp table.
	 * For temp tables, we use SELECT ... INTO which returns SPI_OK_SELINTO.
	 * For regular tables, we use CREATE TEMP TABLE which returns SPI_OK_UTILITY.
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
 */
void
drop_insert_exec_temp_table(Oid temp_table_oid)
{
	char		temp_table_name[NAMEDATALEN];
	StringInfoData drop_stmt;
	int			rc;

	/* Get the table name from OID */
	snprintf(temp_table_name, sizeof(temp_table_name),
			 "#insert_exec_buf_%d", MyProcPid);

	initStringInfo(&drop_stmt);
	appendStringInfo(&drop_stmt, "DROP TABLE IF EXISTS %s", temp_table_name);

	rc = SPI_execute(drop_stmt.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		elog(WARNING, "failed to drop INSERT EXEC temp table: %s",
			 SPI_result_code_string(rc));

	pfree(drop_stmt.data);
}

/*
 * Flush all rows from the temp table to the target table using global context.
 * This version is called from exec_stmt_exec when INSERT EXEC context is active.
 * It uses the global insert_exec_target_table and insert_exec_column_list.
 *
 * CRITICAL: The flush is wrapped in its own subtransaction that commits
 * immediately. This ensures that if an error occurs AFTER INSERT EXEC completes
 * (e.g., SELECT 1/0 in the same TRY block), the TRY-CATCH rollback won't undo
 * the already-flushed data. This matches SQL Server behavior where INSERT EXEC
 * data is preserved even when subsequent errors occur in the same TRY block.
 */
void
flush_insert_exec_temp_table(PLtsql_execstate *estate)
{
	char			temp_table_name[NAMEDATALEN];
	StringInfoData	flush_query;
	int				rc;
	const char		*target_table = pltsql_get_insert_exec_target_table();
	const char		*column_list = pltsql_get_insert_exec_column_list();
	Oid				temp_oid = pltsql_get_insert_exec_temp_table_oid();
	MemoryContext	oldcontext = CurrentMemoryContext;
	ResourceOwner	oldowner = CurrentResourceOwner;
	volatile bool	subtxn_started = false;
	volatile bool	composite_triggers_started = false;
	uint64			rows_inserted = 0;
	
	/* Save INSERT EXEC context to restore after flush */
	char		   *saved_target_table = NULL;
	char		   *saved_column_list = NULL;
	
	/* Security context for ownership chaining */
	Oid				flush_save_userid = InvalidOid;
	int				flush_save_sec_context = 0;
	volatile bool	flush_switched_context = false;

	if (!OidIsValid(temp_oid) || target_table == NULL)
	{
		return;
	}
	
	/*
	 * Verify that the target table schema hasn't changed since INSERT EXEC started.
	 * If the executed procedure altered the target table's schema (e.g., ALTER TABLE
	 * ADD COLUMN), we must raise SQL Server error 556:
	 * "INSERT EXEC failed because the stored procedure altered the schema of the target table."
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
	saved_target_table = pstrdup(target_table);
	if (column_list)
		saved_column_list = pstrdup(column_list);

	snprintf(temp_table_name, sizeof(temp_table_name),
			 "#insert_exec_buf_%d", MyProcPid);

	initStringInfo(&flush_query);
	
	if (column_list != NULL)
	{
		/* User specified columns - use them directly */
		appendStringInfo(&flush_query,
			"INSERT INTO %s (%s) SELECT * FROM %s",
			target_table,
			column_list,
			temp_table_name);
	}
	else
	{
		/*
		 * No column list specified - we need to build one excluding
		 * IDENTITY and computed columns to match the temp table structure.
		 * 
		 * Parse the target table name to get the physical schema and table name
		 * for the catalog query.
		 */
		StringInfoData col_query;
		StringInfoData non_identity_cols;
		bool		first_col = true;
		int			proc_count;
		uint64		i;
		char	   *flush_schema_name = NULL;
		char	   *flush_table_name = NULL;
		char	   *flush_physical_schema = NULL;
		char	   *pg_table_ref;
		char	   *target_copy;
		char	   *dot_pos;
		char	   *second_dot;
		
		initStringInfo(&col_query);
		initStringInfo(&non_identity_cols);
		
		/*
		 * Parse schema and table name from target_table.
		 * Format can be: "table", "schema.table", or "db.schema.table"
		 * For temp tables, use pg_class join since regclass cast may not
		 * resolve temp tables correctly in all contexts.
		 */
		if (target_table[0] == '#')
		{
			/* 
			 * Temp table - use pg_class join to find the table.
			 * This is more reliable than regclass cast for temp tables
			 * because it doesn't depend on search_path resolution.
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
				target_table);
		}
		else
		{
			target_copy = pstrdup(target_table);
			
			/* Find the last dot to separate schema from table */
			dot_pos = strrchr(target_copy, '.');
			if (dot_pos != NULL)
			{
				*dot_pos = '\0';
				flush_table_name = pstrdup(dot_pos + 1);
				
				/* Check if there's another dot (db.schema.table) */
				second_dot = strrchr(target_copy, '.');
				if (second_dot != NULL)
				{
					/* db.schema.table - schema is after the second dot */
					flush_schema_name = pstrdup(second_dot + 1);
				}
				else
				{
					/* schema.table */
					flush_schema_name = pstrdup(target_copy);
				}
			}
			else
			{
				/* Just table name, use dbo as default */
				flush_table_name = pstrdup(target_copy);
				flush_schema_name = pstrdup("dbo");
			}
			pfree(target_copy);
			
			/* Convert logical schema name to physical schema name */
			flush_physical_schema = get_physical_schema_name(get_cur_db_name(), flush_schema_name);
			
			/* Build the PostgreSQL table reference */
			pg_table_ref = psprintf("%s.%s", flush_physical_schema, flush_table_name);
			
			if (flush_schema_name)
				pfree(flush_schema_name);
			if (flush_table_name)
				pfree(flush_table_name);
			if (flush_physical_schema)
				pfree(flush_physical_schema);
			
			appendStringInfo(&col_query,
				"SELECT a.attname "
				"FROM pg_attribute a "
				"WHERE a.attrelid = '%s'::regclass "
				"AND a.attnum > 0 "
				"AND NOT a.attisdropped "
				"AND a.attidentity = '' "
				"AND a.attgenerated = '' "
				"ORDER BY a.attnum",
				pg_table_ref);
			
			pfree(pg_table_ref);
		}
		
		rc = SPI_execute(col_query.data, true, 0);
		if (rc != SPI_OK_SELECT)
		{
			pfree(col_query.data);
			pfree(non_identity_cols.data);
			/* Fall back to simple INSERT */
			appendStringInfo(&flush_query,
				"INSERT INTO %s SELECT * FROM %s",
				target_table,
				temp_table_name);
		}
		else
		{
			proc_count = SPI_processed;
			
			if (proc_count == 0)
			{
				/* No columns found, fall back */
				pfree(col_query.data);
				pfree(non_identity_cols.data);
				appendStringInfo(&flush_query,
					"INSERT INTO %s SELECT * FROM %s",
					target_table,
					temp_table_name);
			}
			else
			{
				/* Build column list */
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
				
				appendStringInfo(&flush_query,
					"INSERT INTO %s (%s) SELECT * FROM %s",
					target_table,
					non_identity_cols.data,
					temp_table_name);
				
				pfree(non_identity_cols.data);
			}
		}
	}

	elog(DEBUG1, "INSERT-EXEC: Flushing temp table to target: %s", flush_query.data);

	/*
	 * Execute the flush INSERT in its own subtransaction that commits
	 * immediately. This is critical for TRY-CATCH behavior:
	 *
	 * Without this subtransaction:
	 * 1. INSERT EXEC runs inside TRY-CATCH subtransaction (level N+1)
	 * 2. Flush INSERT happens at level N+1
	 * 3. SELECT 1/0 throws error
	 * 4. TRY-CATCH rolls back level N+1, undoing the flush
	 * 5. Result: 0 rows in target table
	 *
	 * With this subtransaction:
	 * 1. INSERT EXEC runs inside TRY-CATCH subtransaction (level N+1)
	 * 2. Flush INSERT starts its own subtransaction (level N+2)
	 * 3. Flush INSERT commits (ReleaseCurrentSubTransaction)
	 * 4. Data is now "committed" at level N+1
	 * 5. SELECT 1/0 throws error
	 * 6. TRY-CATCH rolls back level N+1
	 * 7. But the flush was already committed, so data survives
	 * 8. Result: 3 rows in target table (matches SQL Server)
	 *
	 * This matches the QTM branch behavior where each INSERT is wrapped
	 * in its own subtransaction that commits immediately.
	 *
	 * INSTEAD OF Trigger Support:
	 * We temporarily clear the INSERT EXEC context before the flush INSERT
	 * so that the INSERT behaves like a normal INSERT and fires INSTEAD OF
	 * triggers properly. We set insert_exec_flush_in_progress to block
	 * commit_stmt inside triggers during the flush.
	 * We also use BeginCompositeTriggers/EndCompositeTriggers to ensure
	 * trigger events are properly queued and fired.
	 */
	PG_TRY();
	{
		BeginInternalSubTransaction("insert_exec_flush");
		subtxn_started = true;
		MemoryContextSwitchTo(oldcontext);

		/*
		 * Set the flush flag BEFORE clearing the target table pointer.
		 * This ensures commit_stmt is still blocked inside triggers
		 * even though pltsql_insert_exec_active() will return false.
		 */
		insert_exec_flush_in_progress = true;
		
		/*
		 * Temporarily clear just the target table pointer so that
		 * pltsql_insert_exec_active() returns false. This allows the
		 * flush INSERT to behave like a normal INSERT and fire INSTEAD OF
		 * triggers properly.
		 * 
		 * IMPORTANT: We do NOT call pltsql_clear_insert_exec_context() here
		 * because that would reset NestedTranCount, causing error 3609
		 * "The transaction ended in the trigger" at the end of trigger execution.
		 * 
		 * We save the pointer and restore it after the flush.
		 */
		insert_exec_target_table = NULL;
		
		/*
		 * Open a composite trigger nesting level to properly handle
		 * INSTEAD OF triggers. This ensures trigger events are queued
		 * and fired correctly.
		 */
		BeginCompositeTriggers(CurrentMemoryContext);
		composite_triggers_started = true;

		/*
		 * OWNERSHIP CHAINING FIX:
		 * Switch to the procedure owner's identity before executing the flush INSERT.
		 * This ensures the INSERT has the same permissions as the procedure owner,
		 * which is required for ownership chaining to work correctly.
		 * 
		 * Only switch context if we're inside a procedure (estate->func->fn_oid is valid).
		 * For top-level batches, no ownership chaining is needed.
		 * 
		 * IMPORTANT: Use get_func_owner() to get the procedure owner's OID, not the
		 * procedure OID itself. The security context switch needs the user OID.
		 */
		if (estate && estate->func && OidIsValid(estate->func->fn_oid))
		{
			GetUserIdAndSecContext(&flush_save_userid, &flush_save_sec_context);
			SetUserIdAndSecContext(get_func_owner(estate->func->fn_oid),
								   flush_save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
			flush_switched_context = true;
		}

		rc = SPI_execute(flush_query.data, false, 0);
		
		/* Restore security context immediately after SPI_execute */
		if (flush_switched_context)
		{
			SetUserIdAndSecContext(flush_save_userid, flush_save_sec_context);
			flush_switched_context = false;
		}
		
		/*
		 * Accept both SPI_OK_INSERT and SPI_OK_INSERT_RETURNING.
		 * The latter is returned when IDENTITY_INSERT is ON because
		 * the INSERT has a RETURNING clause for the identity column.
		 */
		if (rc != SPI_OK_INSERT && rc != SPI_OK_INSERT_RETURNING)
			elog(ERROR, "INSERT-EXEC: Failed to flush temp table to target: %s",
				 SPI_result_code_string(rc));

		rows_inserted = SPI_processed;
		SPI_freetuptable(SPI_tuptable);
		
		/*
		 * End the composite trigger level and fire any queued trigger events.
		 * Pass false to indicate no error occurred.
		 */
		EndCompositeTriggers(false);
		composite_triggers_started = false;
		
		/* Clear the flush flag after successful flush */
		insert_exec_flush_in_progress = false;
		
		/*
		 * Restore the target table pointer. This is needed because after
		 * the flush, the caller will call pltsql_clear_insert_exec_context()
		 * which expects insert_exec_target_table to be set.
		 */
		insert_exec_target_table = saved_target_table;
		saved_target_table = NULL;  /* Don't free it, we're using it */

		/* Commit the flush subtransaction - this "locks in" the data */
		ReleaseCurrentSubTransaction();
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;

		elog(DEBUG1, "INSERT-EXEC: Flush committed, %lu rows inserted", 
			 (unsigned long) rows_inserted);
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
		insert_exec_flush_in_progress = false;
		
		/* Restore the target table pointer on error */
		insert_exec_target_table = saved_target_table;
		saved_target_table = NULL;  /* Don't free it, we're using it */
		
		/*
		 * End composite triggers with error flag if started.
		 * This cleans up without firing the queued events.
		 */
		if (composite_triggers_started)
			EndCompositeTriggers(true);
		
		/* Roll back the flush subtransaction on error */
		if (subtxn_started)
		{
			RollbackAndReleaseCurrentSubTransaction();
		}
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;

		pfree(flush_query.data);
		if (saved_column_list)
			pfree(saved_column_list);
		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Update rowcount */
	if (estate)
	{
		estate->eval_processed = rows_inserted;
		exec_set_rowcount(rows_inserted);
		exec_set_found(estate, rows_inserted > 0);
	}

	pfree(flush_query.data);
	if (saved_column_list)
		pfree(saved_column_list);
}

/*
 * Flush all rows from the temp table to the target table.
 * This is the final step of INSERT EXEC - move data from buffer to target.
 * When no column list is specified, we need to explicitly list non-IDENTITY
 * columns to avoid column count mismatch.
 */
void
flush_temp_table_to_target(PLtsql_execstate *estate)
{
	char			temp_table_name[NAMEDATALEN];
	StringInfoData	flush_query;
	int				rc;

	if (!OidIsValid(estate->insert_exec_temp_table_oid) ||
		estate->insert_exec_target_table == NULL)
	{
		return;
	}

	snprintf(temp_table_name, sizeof(temp_table_name),
			 "#insert_exec_buf_%d", MyProcPid);

	initStringInfo(&flush_query);
	
	if (estate->insert_exec_column_list != NULL)
	{
		/* User specified columns - use them directly */
		appendStringInfo(&flush_query,
			"INSERT INTO %s (%s) SELECT * FROM %s",
			estate->insert_exec_target_table,
			estate->insert_exec_column_list,
			temp_table_name);
	}
	else
	{
		/*
		 * No column list specified - we need to build one excluding
		 * IDENTITY and computed columns to match the temp table structure.
		 */
		StringInfoData col_query;
		StringInfoData non_identity_cols;
		bool		first_col = true;
		int			proc_count;
		uint64		i;
		
		initStringInfo(&col_query);
		initStringInfo(&non_identity_cols);
		
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
			estate->insert_exec_target_table);
		
		rc = SPI_execute(col_query.data, true, 0);
		if (rc != SPI_OK_SELECT)
		{
			pfree(col_query.data);
			pfree(non_identity_cols.data);
			/* Fall back to simple INSERT */
			appendStringInfo(&flush_query,
				"INSERT INTO %s SELECT * FROM %s",
				estate->insert_exec_target_table,
				temp_table_name);
		}
		else
		{
			proc_count = SPI_processed;
			
			if (proc_count == 0)
			{
				/* No columns found, fall back */
				pfree(col_query.data);
				pfree(non_identity_cols.data);
				appendStringInfo(&flush_query,
					"INSERT INTO %s SELECT * FROM %s",
					estate->insert_exec_target_table,
					temp_table_name);
			}
			else
			{
				/* Build column list */
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
				
				appendStringInfo(&flush_query,
					"INSERT INTO %s (%s) SELECT * FROM %s",
					estate->insert_exec_target_table,
					non_identity_cols.data,
					temp_table_name);
				
				pfree(non_identity_cols.data);
			}
		}
	}

	elog(DEBUG1, "INSERT-EXEC: Flushing temp table to target: %s", flush_query.data);

	rc = SPI_execute(flush_query.data, false, 0);
	if (rc != SPI_OK_INSERT)
		elog(ERROR, "INSERT-EXEC: Failed to flush temp table to target: %s",
			 SPI_result_code_string(rc));

	/* Update rowcount */
	estate->eval_processed = SPI_processed;
	exec_set_rowcount(SPI_processed);
	exec_set_found(estate, SPI_processed > 0);

	pfree(flush_query.data);
	SPI_freetuptable(SPI_tuptable);
}

/* helper function to get current T-SQL estate */
PLtsql_execstate *get_current_tsql_estate(void);
PLtsql_execstate *get_outermost_tsql_estate(int *nestlevel);

/*
 * NOTE:
 *	A SET...(SELECT) statement that returns more than one row will raise an error
 *  A SELECT statement that returns more than one row will assign the values in the last row
 *
 *  A SET...(SELECT) statement that returns zero rows will set the target(s) to NULL
 *  A SELECT statement that returns zero rows will leave the target(s) unchanged
 */

static int	exec_tsql_stmt(PLtsql_execstate *estate, PLtsql_stmt *stmt, PLtsql_stmt *save_estmt);
static int	exec_stmt_print(PLtsql_execstate *estate, PLtsql_stmt_print *stmt);
static int	exec_stmt_kill(PLtsql_execstate *estate, PLtsql_stmt_kill *stmt);
static int	exec_stmt_query_set(PLtsql_execstate *estate, PLtsql_stmt_query_set *stmt);
static int	exec_stmt_try_catch(PLtsql_execstate *estate, PLtsql_stmt_try_catch *stmt);
static int	exec_stmt_push_result(PLtsql_execstate *estate, PLtsql_stmt_push_result *stmt);
static int	exec_stmt_exec(PLtsql_execstate *estate, PLtsql_stmt_exec *stmt);
static int	exec_stmt_decl_table(PLtsql_execstate *estate, PLtsql_stmt_decl_table *stmt);
static int	exec_stmt_return_table(PLtsql_execstate *estate, PLtsql_stmt_return_query *stmt);
static int	exec_stmt_exec_batch(PLtsql_execstate *estate, PLtsql_stmt_exec_batch *stmt);
static int	exec_stmt_exec_sp(PLtsql_execstate *estate, PLtsql_stmt_exec_sp *stmt);
static int	exec_stmt_deallocate(PLtsql_execstate *estate, PLtsql_stmt_deallocate *stmt);
static int	exec_stmt_decl_cursor(PLtsql_execstate *estate, PLtsql_stmt_decl_cursor *stmt);
static int	exec_run_dml_with_output(PLtsql_execstate *estate, PLtsql_stmt_push_result *stmt,
									 Portal portal, PLtsql_expr *expr, CmdType cmd, ParamListInfo paramLI);
static int	exec_stmt_usedb(PLtsql_execstate *estate, PLtsql_stmt_usedb *stmt);
static int	exec_stmt_usedb_explain(PLtsql_execstate *estate, PLtsql_stmt_usedb *stmt, bool shouldRestoreDb);
static int	exec_stmt_grantdb(PLtsql_execstate *estate, PLtsql_stmt_grantdb *stmt);
static int	exec_stmt_fulltextindex(PLtsql_execstate *estate, PLtsql_stmt_fulltextindex *stmt);
static int	exec_stmt_grantschema(PLtsql_execstate *estate, PLtsql_stmt_grantschema *stmt);
static int	exec_stmt_partition_function(PLtsql_execstate *estate, PLtsql_stmt_partition_function *stmt);
static int	exec_stmt_partition_scheme(PLtsql_execstate *estate, PLtsql_stmt_partition_scheme *stmt);
static int	exec_stmt_insert_execute_select(PLtsql_execstate *estate, PLtsql_expr *expr);
static int	exec_stmt_insert_bulk(PLtsql_execstate *estate, PLtsql_stmt_insert_bulk *expr);
static int	exec_stmt_dbcc(PLtsql_execstate *estate, PLtsql_stmt_dbcc *stmt);
extern Datum pltsql_inline_handler(PG_FUNCTION_ARGS);

static char *transform_tsql_temp_tables(char *dynstmt);
static char *next_word(char *dyntext);
static bool is_next_temptbl(char *dyntext);
static bool is_char_identstart(char c);
static bool is_char_identpart(char c);

void		read_param_def(InlineCodeBlockArgs *args, const char *paramdefstr);
bool  		called_from_tsql_insert_exec(void);
void		cache_inline_args(PLtsql_function *func, InlineCodeBlockArgs *args);
InlineCodeBlockArgs *create_args(int numargs);
InlineCodeBlockArgs *clone_inline_args(InlineCodeBlockArgs *args);
static void read_param_val(PLtsql_execstate *estate, List *params, InlineCodeBlockArgs *args,
						   FunctionCallInfo fcinfo, PLtsql_row *row);
static bool check_spexecutesql_param(char *defmode, tsql_exec_param *p);

static int	exec_eval_int(PLtsql_execstate *estate, PLtsql_expr *expr, bool *isNull);

int
			execute_plan_and_push_result(PLtsql_execstate *estate, PLtsql_expr *expr, ParamListInfo paramLI);

static void get_param_mode(List *params, int paramno, char **modes);

extern void pltsql_update_cursor_row_count(char *curname, int64 row_count);
extern void pltsql_update_cursor_last_operation(char *curname, int last_operation);
extern bool pltsql_declare_cursor(PLtsql_execstate *estate, PLtsql_var *var, PLtsql_expr *explicit_expr, int cursor_options);
extern char *pltsql_demangle_curname(char *curname);

extern void enable_sp_cursor_find_param_hook(void);
extern void disable_sp_cursor_find_param_hook(void);
extern void add_sp_cursor_param(char *name);
extern void reset_sp_cursor_params();
extern char *construct_unique_index_name(char *index_name, char *relation_name);
extern const char *gen_schema_name_for_fulltext_index(const char *schema_name);

extern void pltsql_commit_not_required_impl_txn(PLtsql_execstate *estate);

int			execute_batch(PLtsql_execstate *estate, char *batch, InlineCodeBlockArgs *args, List *params);
Oid			get_role_oid(const char *rolename, bool missing_ok);
bool		is_member_of_role(Oid member, Oid role);
void		exec_stmt_dbcc_checkident(PLtsql_stmt_dbcc *stmt);
extern PLtsql_function *find_cached_batch(int handle);

extern SPIPlanPtr prepare_stmt_exec(PLtsql_execstate *estate, PLtsql_function *func, PLtsql_stmt_exec *stmt, bool keepplan);

extern int	sp_prepare_count;

BulkCopyStmt *cstmt = NULL;
bool		called_from_tsql_insert_execute = false;

int			insert_bulk_rows_per_batch = DEFAULT_INSERT_BULK_ROWS_PER_BATCH;
int			insert_bulk_kilobytes_per_batch = DEFAULT_INSERT_BULK_PACKET_SIZE;
bool		insert_bulk_keep_nulls = false;
bool		insert_bulk_check_constraints = false;

static int	prev_insert_bulk_rows_per_batch = DEFAULT_INSERT_BULK_ROWS_PER_BATCH;
static int	prev_insert_bulk_kilobytes_per_batch = DEFAULT_INSERT_BULK_PACKET_SIZE;
static bool prev_insert_bulk_keep_nulls = false;
static bool prev_insert_bulk_check_constraints = false;

/* return a underlying node if n is implicit casting and underlying node is a certain type of node */
static Node *get_underlying_node_from_implicit_casting(Node *n, NodeTag underlying_nodetype);

/* Enclose a user-defined @@var or @var# name in delimiters */
static char *delimit_tsql_atatuservar(const char *src);
static void set_search_path_for_sp_procs(char *schema);
 
/*
 * The pltsql_proc_return_code global variable is used to record the
 * return code (RETURN 41 + 1) of the most recently completed procedure
 *
 * Although unsatisfying, we keep the return code here instead of in the
 * tuple that holds the OUT parameter values because a procedure needs to
 * deliver a return code *and* OUT values. It would be possible to add an
 * extra attribute to the OUT value tuple (the new attribute would hold
 * the return code), but this mechanism seems less intrusive.
 *
 * pltsql_proc_return_code is set when a procedure executes a RETURN
 * statement and is read when we execute an EXEC statement.
 */

int			pltsql_proc_return_code;

PLtsql_execstate *
get_current_tsql_estate()
{
	ErrorContextCallback *plerrcontext = error_context_stack;

	while (plerrcontext != NULL)
	{
		/* Check plerrcontext was created in T-SQL */
		if (plerrcontext->callback == pltsql_exec_error_callback)
		{
			return (PLtsql_execstate *) plerrcontext->arg;
		}
		plerrcontext = plerrcontext->previous;
	}

	/* Couldn't find any T-SQL estate */
	return NULL;
}

PLtsql_execstate *
get_outermost_tsql_estate(int *nestlevel)
{
	PLtsql_execstate *estate = NULL;
	ErrorContextCallback *plerrcontext = error_context_stack;

	*nestlevel = 0;
	while (plerrcontext != NULL)
	{
		/* Check plerrcontext was created in T-SQL */
		if (plerrcontext->callback == pltsql_exec_error_callback)
		{
			estate = (PLtsql_execstate *) plerrcontext->arg;
			(*nestlevel)++;
		}
		plerrcontext = plerrcontext->previous;
	}

	return estate;
}

static int
exec_tsql_stmt(PLtsql_execstate *estate, PLtsql_stmt *stmt, PLtsql_stmt *save_estmt)
{
	int			rc;

	switch ((int) stmt->cmd_type)
	{
		case PLTSQL_STMT_PRINT:
			rc = exec_stmt_print(estate, (PLtsql_stmt_print *) stmt);
			break;

		case PLTSQL_STMT_KILL:
			rc = exec_stmt_kill(estate, (PLtsql_stmt_kill *) stmt);
			break;

		case PLTSQL_STMT_INIT:

			/*
			 * This stmt contains a (possibly nil) list of assignment
			 * statements, each of which initializes a particular variable.
			 */
			rc = exec_stmts(estate, ((PLtsql_stmt_init *) stmt)->inits);
			break;

		case PLTSQL_STMT_QUERY_SET:
			rc = exec_stmt_query_set(estate, (PLtsql_stmt_query_set *) stmt);
			break;

		case PLTSQL_STMT_TRY_CATCH:
			rc = exec_stmt_try_catch(estate, (PLtsql_stmt_try_catch *) stmt);
			break;

		case PLTSQL_STMT_PUSH_RESULT:
			rc = exec_stmt_push_result(estate, (PLtsql_stmt_push_result *) stmt);
			break;

		case PLTSQL_STMT_EXEC:
			rc = exec_stmt_exec(estate, (PLtsql_stmt_exec *) stmt);
			break;

		case PLTSQL_STMT_EXEC_BATCH:
			rc = exec_stmt_exec_batch(estate, (PLtsql_stmt_exec_batch *) stmt);
			break;

		case PLTSQL_STMT_EXEC_SP:
			rc = exec_stmt_exec_sp(estate, (PLtsql_stmt_exec_sp *) stmt);
			break;

		case PLTSQL_STMT_DEALLOCATE:
			rc = exec_stmt_deallocate(estate, (PLtsql_stmt_deallocate *) stmt);
			break;

		case PLTSQL_STMT_DECL_CURSOR:
			rc = exec_stmt_decl_cursor(estate, (PLtsql_stmt_decl_cursor *) stmt);
			break;

		case PLTSQL_STMT_DECL_TABLE:
			rc = exec_stmt_decl_table(estate, (PLtsql_stmt_decl_table *) stmt);
			break;

		case PLTSQL_STMT_RETURN_TABLE:
			rc = exec_stmt_return_table(estate, (PLtsql_stmt_return_query *) stmt);
			break;

		case PLTSQL_STMT_INSERT_BULK:
			rc = exec_stmt_insert_bulk(estate, (PLtsql_stmt_insert_bulk *) stmt);
			break;

		case PLTSQL_STMT_DBCC:
			rc = exec_stmt_dbcc(estate, (PLtsql_stmt_dbcc *) stmt);
			break;
		default:
			estate->err_stmt = save_estmt;
			elog(ERROR, "unrecognized cmd_type: %d", stmt->cmd_type);
	}

	return rc;
}

static int
exec_stmt_kill(PLtsql_execstate *estate, PLtsql_stmt_kill *stmt)
{
	PGPROC *proc;    	
	Oid	sysadmin_oid = get_role_oid("sysadmin", false);  /* We should really use BABELFISH_SYSADMIN in tds_int.h . */
	int spid = -1;
	Assert(stmt->spid);     
	spid = stmt->spid;

	if (pltsql_explain_only)
	{
		StringInfoData query;

		initStringInfo(&query);
		appendStringInfo(&query, "KILL ");
		appendStringInfoString(&query, psprintf("%d", spid));
		append_explain_info(NULL, query.data);
		pfree(query.data);
		return PLTSQL_RC_OK;
	}

	/* Do not allow to run KILL inside a transaction. */
	if (IsTransactionBlockActive())
	{
		ereport(ERROR,
			(errcode(ERRCODE_ACTIVE_SQL_TRANSACTION),
				errmsg("%s command cannot be used inside user transactions.", "KILL")));
	}

	/* Require that the user has 'sysadmin' role. */
	if (!has_privs_of_role(GetSessionUserId(), sysadmin_oid)) 
		{	       
		ereport(ERROR,
			(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				errmsg("User does not have permission to use the KILL statement")));
	}

	/*
	 * SPID value must be a positive number; the T-SQL grammar allows only a non-negative number to be specified.
	 * Yet, play it safe and test for it.
	 * A variable or expression is not allowed and caught in the parser.
	 * All other variants of T-SQL KILL are not supported, this is caught in the parser.
	 */
	if (spid <= 0)
	{
		ereport(ERROR,
			(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				errmsg("Session ID %d is not valid", spid)));
	}

	/* Verify it is an actually existing process; otherwise we might just be killing any process on the host. */
	proc = BackendPidGetProc(spid);
	if (proc == NULL)
	{
		ereport(ERROR,
			errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				errmsg("Process ID %d is not an active process ID", spid));
	}

	/* Do not kill ourselves. */
	if (spid == MyProcPid)
	{
		ereport(ERROR,
			(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				errmsg("Cannot use KILL to kill your own process.")));
	}		

	/*
	 * Verify this is a TDS connection, not a PG connection: we should not kill PG connections from T-SQL.
	 * This can be verified by checking the session to be present in sys.dm_exec_sessions or 
	 * sys.dm_exec_connections, which contains T-SQL connections only
	 * (unlike sys.syprocesses which also contains PG connections since this view is also 
	 *  based on pg_locks and pg_stat_activity).
	 */
	{
		uint64 nrRows = 0;
		char *query = psprintf("SELECT DISTINCT 1 FROM sys.dm_exec_sessions WHERE session_id = %d ", spid);
		int rc = SPI_execute(query, true, 1);
		pfree(query);
	
		/* Copy #rows before cleaning up below. */
		nrRows = SPI_processed;
	
		/* 
		 * We're only interested in the #rows found: 0 or non-zero; we don't care about 
		 * the actual result set. So we can clean up already now.
		 */
		SPI_freetuptable(SPI_tuptable);		

		if (rc != SPI_OK_SELECT)
		{
			ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("SPI_execute failed: %s", SPI_result_code_string(rc))));
		}

		/*
		 * 1 row found: TDS connection	 		
		 * 0 rows found: PG connection (since the connection was found to exist above)
		 */
		if (nrRows == 0) 
		{
			ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
					errmsg("Process ID %d is not an active process ID for a TDS connection", spid)));
		}
	}

	/*
	 * All validations passed, send the signal to the backend process.
	 * This is basically the same as what pg_terminate_backend() does..
	 */
	if (kill(spid, SIGTERM))
	{
		/* KILL is a best-effort attempt, so proceed rather than abort in case it does not work out. */
		ereport(WARNING,
			(errmsg("Could not send signal to process %d: %m", spid)));
	}

	/* Send no further message to the client, irrespective of the result. */
	/* KILL resets the rowcount. */
	exec_set_rowcount(0);

	return PLTSQL_RC_OK;
}

static int
exec_stmt_print(PLtsql_execstate *estate, PLtsql_stmt_print *stmt)
{
	Datum		formatdatum;
	bool		formatisnull;
	Oid			formattypeid;
	int32		formattypmod;
	char	   *extval;
	StringInfoData query;
	const char *print_text;

	if (pltsql_explain_only)
	{
		PLtsql_expr *expr_temp = (PLtsql_expr *) linitial(stmt->exprs);

		initStringInfo(&query);
		appendStringInfo(&query, "PRINT ");
		print_text = strip_select_from_expr(expr_temp);
		appendStringInfoString(&query, print_text);
		append_explain_info(NULL, query.data);
		return PLTSQL_RC_OK;
	}
	formatdatum = exec_eval_expr(estate,
								 (PLtsql_expr *) linitial(stmt->exprs),
								 &formatisnull,
								 &formattypeid,
								 &formattypmod);

	if (formatisnull)
	{
		// Printing NULL prints a single space in T-SQL 
		extval = " ";
	}
	else
	{
		extval = convert_value_to_string(estate,
										 formatdatum,
										 formattypeid);
	}

	if (strlen(extval) == 0)
	{
		// Printing an empty string prints a single space in T-SQL
		extval = " ";
	}

	ereport(INFO, errmsg_internal("%s", extval));

	exec_set_rowcount(0);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
		((*pltsql_protocol_plugin_ptr)->send_info) (0,
													1,
													0,
													extval,
													0);
	return PLTSQL_RC_OK;
}

/* ----------
 * exec_stmt_query_set		Evaluate a query and assign the results to
 *							the target specified by the user. This stmt
 *							implements TSQL semantics - a query that
 *							returns no rows leaves the target(s) untouched;
 *							a query that returns more than one row will
 *							assign the values found in the *last* row
 * ----------
 */

static int
exec_stmt_query_set(PLtsql_execstate *estate,
					PLtsql_stmt_query_set *stmt)
{
	int			rc;

	/*
	 * On the first call for this statement generate the plan, and detect
	 * whether the statement is INSERT/UPDATE/DELETE
	 */
	if (stmt->sqlstmt->plan == NULL)
		exec_prepare_plan(estate, stmt->sqlstmt, CURSOR_OPT_PARALLEL_OK, true);

	/*
	 * If we started an implicit_transaction for this statement but the
	 * statement has a simple expression associated with them, we no longer
	 * require an implicit transaction
	 */
	if (estate->impl_txn_type == PLTSQL_IMPL_TRAN_START)
	{
		if (stmt->sqlstmt->expr_simple_expr != NULL)
			pltsql_commit_not_required_impl_txn(estate);
		else
			estate->impl_txn_type = PLTSQL_IMPL_TRAN_ON;
	}

	/*
	 * Execute the plan
	 */
	rc = SPI_execute_plan_with_paramlist(stmt->sqlstmt->plan,
										 setup_param_list(estate, stmt->sqlstmt),
										 estate->readonly_func, 0);

	switch (rc)
	{
		case SPI_OK_SELECT:
			exec_set_found(estate, (SPI_processed != 0));
			exec_set_found(estate, (SPI_processed == 0 ? 1 : 0));
			exec_set_rowcount(SPI_processed);
			break;
		case SPI_OK_UPDATE_RETURNING:
			exec_set_found(estate, (SPI_processed != 0));
			exec_set_found(estate, (SPI_processed == 0 ? 1 : 0));
			exec_set_rowcount(SPI_processed);
			break;
		case SPI_ERROR_TRANSACTION:
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("unsupported transaction command in PL/tsql")));
			break;

		default:
			elog(ERROR, "SPI_execute_plan_with_paramlist failed executing query \"%s\": %s",
				 stmt->sqlstmt->query, SPI_result_code_string(rc));
			break;
	}

	/* If the statement did not return a tuple table, complain */
	if (SPI_tuptable == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("SELECT used with a command that cannot return data")));

	/*
	 * A SELECT statement that returns zero rows will leave the target(s)
	 * unchanged
	 *
	 * A SELECT statement that returns more than one row will assign the
	 * values in the *last* row.
	 */

	if (SPI_processed > 0)
	{
		PLtsql_variable *target = (PLtsql_variable *) estate->datums[stmt->target->dno];

		/* Put the last result row into the target */
		exec_move_row(estate, target, SPI_tuptable->vals[SPI_processed - 1], SPI_tuptable->tupdesc);
	}

	/* Clean up */
	exec_eval_cleanup(estate);
	SPI_freetuptable(SPI_tuptable);

	return PLTSQL_RC_OK;
}

static int
exec_stmt_try_catch(PLtsql_execstate *estate, PLtsql_stmt_try_catch *stmt)
{
	volatile int rc = -1;
	int nest_level_before_subtxn;
	volatile bool insert_exec_was_active = false;

	/*
	 * Execute the statements in the block's body inside a sub-transaction
	 */
	MemoryContext oldcontext = CurrentMemoryContext;
	ResourceOwner oldowner = CurrentResourceOwner;
	ExprContext *old_eval_econtext = estate->eval_econtext;
	ErrorData  *save_cur_error = estate->cur_error->error;

	MemoryContext stmt_mcontext;

	/*
	 * Track TRY-CATCH depth for INSERT EXEC.
	 * This is used as a fallback when exec_state_call_stack is NULL.
	 */
	pltsql_insert_exec_enter_trycatch();

	/*
	 * Check if INSERT EXEC is active at the start of the TRY block.
	 * If so, we need special handling to preserve INSERT EXEC data
	 * when a statement-terminating error occurs.
	 */
	insert_exec_was_active = pltsql_insert_exec_active();

	nest_level_before_subtxn = GetCurrentTransactionNestLevel();

	estate->err_text = gettext_noop("during statement block entry");

	/*
	 * We will need a stmt_mcontext to hold the error data if an error occurs.
	 * It seems best to force it to exist before entering the subtransaction,
	 * so that we reduce the risk of out-of-memory during error recovery, and
	 * because this greatly simplifies restoring the stmt_mcontext stack to
	 * the correct state after an error.  We can ameliorate the cost of this
	 * by allowing the called statements to use this mcontext too; so we don't
	 * push it down here.
	 */
	stmt_mcontext = get_stmt_mcontext(estate);

	BeginInternalSubTransaction(NULL);
	/* Want to run statements inside function's memory context */
	MemoryContextSwitchTo(oldcontext);

	PG_TRY();
	{
		/*
		 * We need to run the block's statements with a new eval_econtext that
		 * belongs to the current subtransaction; if we try to use the outer
		 * econtext then ExprContext shutdown callbacks will be called at the
		 * wrong times.
		 */
		pltsql_create_econtext(estate);

		estate->err_text = NULL;

		/* Run the block's statements */
		rc = exec_stmt(estate, stmt->body);

		estate->err_text = gettext_noop("during statement block exit");

		/*
		 * If the block ended with RETURN, we may need to copy the return
		 * value out of the subtransaction eval_context.  We can avoid a
		 * physical copy if the value happens to be a R/W expanded object.
		 */
		if (rc == PLTSQL_RC_RETURN &&
			!estate->retisset &&
			!estate->retisnull)
		{
			int16		resTypLen;
			bool		resTypByVal;

			get_typlenbyval(estate->rettype, &resTypLen, &resTypByVal);
			estate->retval = datumTransfer(estate->retval,
										   resTypByVal, resTypLen);
		}

		/* Commit the inner transaction, return to outer xact context */
		ReleaseCurrentSubTransaction();
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;

		/* Assert that the stmt_mcontext stack is unchanged */
		Assert(stmt_mcontext == estate->stmt_mcontext);

		/*
		 * Revert to outer eval_econtext.  (The inner one was automatically
		 * cleaned up during subxact exit.)
		 */
		estate->eval_econtext = old_eval_econtext;
	}
	PG_CATCH();
	{
		ErrorData  *edata;
		int			last_error;
		bool		is_stmt_terminating;

		estate->err_text = gettext_noop("during exception cleanup");

		/* Save error info in our stmt_mcontext */
		MemoryContextSwitchTo(stmt_mcontext);
		edata = CopyErrorData();
		FlushErrorState();

		/*
		 * Check if this is a statement-terminating error.
		 * Statement-terminating errors (like division by zero) should NOT
		 * roll back previous statements' work in the TRY block.
		 * This matches SQL Server behavior.
		 */
		(void) get_tsql_error_code(edata, &last_error);
		is_stmt_terminating = is_ignorable_error(edata->sqlerrcode, 0);

		/*
		 * For statement-terminating errors when INSERT EXEC was active,
		 * we want to preserve the INSERT EXEC data. To do this, we:
		 * 1. Release (commit) the TRY-CATCH subtransaction instead of rolling back
		 * 2. This preserves all work done before the error
		 * 3. The CATCH block still runs to handle the error
		 *
		 * This matches SQL Server behavior where INSERT EXEC data is preserved
		 * even when a subsequent statement-terminating error occurs in the
		 * same TRY block.
		 *
		 * NOTE: We can only do this if the subtransaction is still at the
		 * expected nesting level. If nested subtransactions were started
		 * and not properly cleaned up, we must roll back.
		 */
		if (is_stmt_terminating && insert_exec_was_active &&
			GetCurrentTransactionNestLevel() == nest_level_before_subtxn + 1)
		{
			/*
			 * Release the subtransaction to commit all work done before the error.
			 * This is safe because:
			 * 1. The error has already been caught and saved
			 * 2. The internal savepoint for the failed statement was already
			 *    rolled back in dispatch_stmt_handle_error
			 * 3. We're just committing the successful work from before the error
			 */
			ReleaseCurrentSubTransaction();
		}
		else
		{
			/* Abort the inner transaction */
			RollbackAndReleaseCurrentSubTransaction();
		}

		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;

		elog(LOG, "INSERT-EXEC TRY-CATCH cleanup: checking if active, is_stmt_terminating=%d, insert_exec_was_active=%d",
			 is_stmt_terminating, insert_exec_was_active);

		/*
		 * Clean up INSERT EXEC context if it is currently active.
		 * This is necessary because the error may have been thrown from inside
		 * the procedure being executed, and the INSERT EXEC context was not
		 * properly cleaned up. We need to:
		 * 1. Clear the INSERT EXEC context (target table, column list, temp table OID)
		 * 2. Drop the temp table if it still exists
		 *
		 * When the subtransaction is rolled back, the temp table should be
		 * automatically dropped by ENRRollbackSubtransaction. But we still
		 * need to clear the global INSERT EXEC context.
		 *
		 * When the subtransaction is released (for statement-terminating errors),
		 * we need to explicitly drop the temp table.
		 */
		if (pltsql_insert_exec_active())
		{
			Oid temp_oid = pltsql_get_insert_exec_temp_table_oid();
			
			elog(LOG, "INSERT-EXEC TRY-CATCH cleanup: is_stmt_terminating=%d, insert_exec_was_active=%d, temp_oid=%u",
				 is_stmt_terminating, insert_exec_was_active, temp_oid);
			
			/* Clear the INSERT EXEC context */
			pltsql_clear_insert_exec_context();
			
			/*
			 * If subtransaction was released (not rolled back), drop the temp table.
			 * When rolled back, the temp table is already gone.
			 */
			if (is_stmt_terminating && insert_exec_was_active && OidIsValid(temp_oid))
			{
				elog(LOG, "INSERT-EXEC TRY-CATCH cleanup: dropping temp table");
				drop_insert_exec_temp_table(temp_oid);
			}
		}
		else
		{
			elog(LOG, "INSERT-EXEC TRY-CATCH cleanup: INSERT EXEC not active");
		}

		/*
		 * Set up the stmt_mcontext stack as though we had restored our
		 * previous state and then done push_stmt_mcontext().  The push is
		 * needed so that statements in the exception handler won't clobber
		 * the error data that's in our stmt_mcontext.
		 */
		estate->stmt_mcontext_parent = stmt_mcontext;
		estate->stmt_mcontext = NULL;

		/*
		 * Now we can delete any nested stmt_mcontexts that might have been
		 * created as children of ours.  (Note: we do not immediately release
		 * any statement-lifespan data that might have been left behind in
		 * stmt_mcontext itself.  We could attempt that by doing a
		 * MemoryContextReset on it before collecting the error data above,
		 * but it seems too risky to do any significant amount of work before
		 * collecting the error.)
		 */
		MemoryContextDeleteChildren(stmt_mcontext);

		/* Revert to outer eval_econtext */
		estate->eval_econtext = old_eval_econtext;

		/*
		 * Must clean up the econtext too.  However, any tuple table made in
		 * the subxact will have been thrown away by SPI during subxact abort,
		 * so we don't need to (and mustn't try to) free the eval_tuptable.
		 */
		estate->eval_tuptable = NULL;
		exec_eval_cleanup(estate);

		/* Free the error data now that we've extracted what we need */
		FreeErrorData(edata);

		rc = exec_stmt(estate, stmt->handler);

		/*
		 * Restore previous state of cur_error, whether or not we executed a
		 * handler.  This is needed in case an error got thrown from some
		 * inner block's exception handler.
		 */
		estate->cur_error->error = save_cur_error;

		/* Restore stmt_mcontext stack and release the error data */
		pop_stmt_mcontext(estate);
		MemoryContextReset(stmt_mcontext);
	}
	PG_END_TRY();

	Assert(save_cur_error == estate->cur_error->error);

	/*
	 * Decrement TRY-CATCH depth for INSERT EXEC tracking.
	 */
	pltsql_insert_exec_exit_trycatch();

	estate->err_text = NULL;

	/*
	 * Handle the return code.  This is intentionally different from
	 * LOOP_RC_PROCESSING(): CONTINUE never matches a block, and EXIT matches
	 * a block only if there is a label match.
	 */
	switch (rc)
	{
		case PLTSQL_RC_OK:
		case PLTSQL_RC_RETURN:
		case PLTSQL_RC_CONTINUE:
			return rc;

		case PLTSQL_RC_EXIT:
			if (estate->exitlabel == NULL)
				return PLTSQL_RC_EXIT;
			if (stmt->label == NULL)
				return PLTSQL_RC_EXIT;
			if (strcmp(stmt->label, estate->exitlabel) != 0)
				return PLTSQL_RC_EXIT;
			estate->exitlabel = NULL;
			return PLTSQL_RC_OK;

		default:
			elog(ERROR, "unrecognized rc: %d", rc);
	}

	return PLTSQL_RC_OK;
}

static int
exec_stmt_push_result(PLtsql_execstate *estate,
					  PLtsql_stmt_push_result *stmt)
{
	Portal		portal;
	uint64		processed = 0;
	DestReceiver *receiver;
	QueryCompletion qc;

	Assert(stmt->query != NULL);

	/* Handle naked SELECT stmt differently for INSERT ... EXECUTE */
	if (estate->insert_exec)
		return exec_stmt_insert_execute_select(estate, stmt->query);

	exec_run_select(estate, stmt->query, &portal);

	receiver = CreateDestReceiver(DestRemote);
	SetRemoteDestReceiverParams(receiver, portal);

	if (PortalRun(portal,
				  FETCH_ALL,
				  true,			/* always top level */
				  true,
				  receiver,
				  receiver,
				  &qc))
		processed = portal->portalPos;

	receiver->rDestroy(receiver);

	SPI_freetuptable(SPI_tuptable);
	SPI_cursor_close(portal);

	exec_eval_cleanup(estate);

	estate->eval_processed = processed;
	exec_set_rowcount(processed);
	exec_set_found(estate, processed != 0);

	return PLTSQL_RC_OK;
}

static int
exec_run_dml_with_output(PLtsql_execstate *estate, PLtsql_stmt_push_result *stmt,
						 Portal portal, PLtsql_expr *expr, CmdType cmd, ParamListInfo paramLI)
{
	uint64		processed = 0;
	DestReceiver *receiver;
	QueryCompletion qc;
	bool		success = false;
	int			rc = 0;

	Assert(stmt->query != NULL);

	/*
	 * Put the query and paramlist into the portal
	 */
	portal = SPI_cursor_open_with_paramlist(NULL, expr->plan,
											paramLI,
											estate->readonly_func);
	if (portal == NULL)
		elog(ERROR, "could not open implicit cursor for query \"%s\": %s",
			 expr->query, SPI_result_code_string(SPI_result));

	/*
	 * INSERT EXEC context check - redirect OUTPUT clause results to temp table
	 * instead of sending to client.
	 */
	if (pltsql_insert_exec_active())
	{
		Oid temp_table_oid = pltsql_get_insert_exec_temp_table_oid();
		receiver = CreateInsertExecDestReceiver(temp_table_oid);
		receiver->rStartup(receiver, CMD_SELECT, portal->tupDesc);
	}
	else
	{
		receiver = CreateDestReceiver(DestRemote);
		SetRemoteDestReceiverParams(receiver, portal);
	}

	success = PortalRun(portal,
						FETCH_ALL,
						true,
						true,
						receiver,
						receiver,
						&qc);
	if (success)
	{
		processed = (portal)->portalPos;
		estate->eval_processed = processed;
		exec_set_rowcount(processed);
		exec_set_found(estate, processed != 0);
		if (cmd == CMD_INSERT)
			rc = SPI_OK_INSERT_RETURNING;
		else if (cmd == CMD_DELETE)
			rc = SPI_OK_DELETE_RETURNING;
		else if (cmd == CMD_UPDATE)
			rc = SPI_OK_UPDATE_RETURNING;
	}

	receiver->rDestroy(receiver);
	exec_eval_cleanup(estate);
	SPI_cursor_close(portal);

	return rc;
}

/*
 * Execute an EXEC statement (equivalent to CALL)
 */
static int
exec_stmt_exec(PLtsql_execstate *estate, PLtsql_stmt_exec *stmt)
{
	PLtsql_expr *expr = stmt->expr;
	volatile LocalTransactionId before_lxid;
	LocalTransactionId after_lxid;
	volatile int rc;
	SimpleEcontextStackEntry *topEntry;
	SPIExecuteOptions options;
	char 	*save_db_name = get_cur_db_name();

	/* whether procedure was created WITH RECOMPILE */
	bool created_with_recompile = false;
	
	/* INSERT EXEC handling - temp table lifecycle */
	bool insert_exec_setup_done = false;
	Oid insert_exec_temp_oid = InvalidOid;

	/*
	 * We need to disable the explain gucs incase of sp_reset_connection
	 * execution otherwise we will get explain output for it which is
	 * not intended.
	 */
	if (strcmp(stmt->proc_name, "sp_reset_connection") == 0)
	{
		pltsql_explain_only = false;
		pltsql_explain_analyze = false;
	}

	/* PG_TRY to ensure we clear the plan link, if needed, on failure */
	PG_TRY();
	{
		SPIPlanPtr	plan = expr->plan;
		ParamListInfo paramLI;
		PLtsql_var *return_code;
		Query	   *query;
		TargetEntry *target;	/* used for scalar function */
		Oid			rettype;	/* used for scalar function */
		int32		rettypmod;	/* used for scalar function */
		bool		is_scalar_func;

		/* for EXEC as part of inline code under INSERT ... EXECUTE */
		Tuplestorestate *tss;
		DestReceiver *dest;

		/*
		 * INSERT EXEC DestReceiver approach:
		 * If this is an INSERT EXEC statement (set by parser), create temp table here.
		 * The DestReceiver will redirect procedure output to this temp table.
		 * After procedure completes, we flush temp table to target and cleanup.
		 * 
		 * This is inside PG_TRY so that errors (including nested INSERT EXEC)
		 * can be caught by T-SQL TRY/CATCH.
		 * 
		 * IMPORTANT: We create the temp table in a subtransaction and immediately
		 * release it. This ensures the temp table's storage files are "committed"
		 * at the subtransaction level, so they won't be cleaned up if a nested
		 * subtransaction (e.g., inner TRY/CATCH) rolls back.
		 */
		elog(DEBUG1, "INSERT-EXEC: exec_stmt_exec - insert_exec=%d, insert_exec_target='%s'",
			 stmt->insert_exec, stmt->insert_exec_target ? stmt->insert_exec_target : "NULL");
		if (stmt->insert_exec && stmt->insert_exec_target != NULL)
		{
			/*
			 * Check for nested INSERT EXEC - SQL Server error 8164.
			 * If INSERT EXEC context is already active, this is a nested call.
			 * Use same error code and message as old code path for consistency.
			 */
			if (pltsql_insert_exec_active())
			{
				ereport(ERROR,
						(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
						 errmsg("nested INSERT ... EXECUTE statements are not allowed")));
			}
			
			/* Set global context info for flush function */
			pltsql_set_insert_exec_context_info(stmt->insert_exec_target, stmt->insert_exec_columns);
			
			/*
			 * Open and hold the target table during INSERT EXEC execution.
			 * This is critical for detecting schema alterations (SQL Server error 556).
			 * By holding the target table open, PostgreSQL's CheckTableNotInUse()
			 * will detect if the procedure tries to ALTER TABLE on the target.
			 */
			pltsql_insert_exec_open_target_table(stmt->insert_exec_target);
			
			/* Create temp table based on target table structure - NO subtransaction wrapper */
			insert_exec_temp_oid = create_insert_exec_temp_table(stmt->insert_exec_target, 
																 stmt->insert_exec_columns);
			
			/* Set global context so DestReceiver knows where to write */
			pltsql_set_insert_exec_context(insert_exec_temp_oid);
			
			insert_exec_setup_done = true;
		}

		if (IS_TDS_CONN())
		{
			if (strncmp(stmt->proc_name, "sp_", 3) == 0 &&
				(stmt->schema_name == NULL || strcmp(stmt->schema_name, "dbo") == 0))
			{

				if (stmt->db_name != NULL)
					set_cur_user_db_and_path(stmt->db_name, false);

				set_search_path_for_sp_procs(stmt->schema_name);
			}
			else if (stmt->db_name != NULL && strcmp(stmt->db_name, save_db_name) != 0 &&
					 stmt->schema_name != NULL && strcmp(stmt->schema_name, "sys") == 0)
			{
				/*
				 * For sys pltsql routines and sp_ procs switch to
				 * the database specified while calling it.
				 */
				set_cur_user_db_and_path(stmt->db_name, false);
			}
		}

		if (plan == NULL)
			plan = prepare_stmt_exec(estate, estate->func, stmt, estate->atomic);

		/*
		 * If we will deal with scalar function, we need to know the correct
		 * return-type.
		 */
		query = linitial_node(Query, ((CachedPlanSource *) linitial(plan->plancache_list))->query_list);

		if (query->commandType == CMD_SELECT)
		{
			Node	   *node;
			FuncExpr   *funcexpr;
			HeapTuple	func_tuple;

			if (query->targetList == NULL || list_length(query->targetList) != 1)
				elog(ERROR, "scalar function on EXEC statement does not have exactly 1 target");
			node = linitial(query->targetList);
			if (node == NULL || !IsA(node, TargetEntry))
				elog(ERROR, "scalar function on EXEC statement does not have target entry");
			target = (TargetEntry *) node;
			if (target->expr == NULL || !IsA(target->expr, FuncExpr))
				elog(ERROR, "scalar function on EXEC statement does not have scalar function target");

			funcexpr = (FuncExpr *) target->expr;

			func_tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcexpr->funcid));
			if (!HeapTupleIsValid(func_tuple))
				elog(ERROR, "cache lookup failed for function %u", funcexpr->funcid);

			rettype = exprType((Node *) funcexpr);
			rettypmod = exprTypmod((Node *) funcexpr);

			ReleaseSysCache(func_tuple);

			is_scalar_func = true;
		}
		else
		{
			is_scalar_func = false;
		}

		stmt->is_scalar_func = is_scalar_func;

		/*
		 * T-SQL doesn't allow procedure calls in a function, EXCEPT when
		 * the procedure is being called as part of INSERT EXEC. In that case,
		 * the procedure's output is captured into a table variable, which is
		 * allowed in T-SQL functions.
		 */
		if (estate->func && estate->func->fn_oid != InvalidOid && estate->func->fn_prokind == PROKIND_FUNCTION && estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER /* check EXEC is running
																																									 * in the body of
																																									 * function */
			&& !is_scalar_func /* in case of EXEC on scalar function, it is
								 * allowed in T-SQL. do not throw an error */
			&& !stmt->insert_exec) /* INSERT EXEC into table variable is allowed in functions */
		{
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
					 errmsg("Only functions can be executed within a function")));
		}

		/*
		 * We construct a DTYPE_ROW datum representing the pltsql variables
		 * associated with the procedure's output arguments.  Then we can use
		 * exec_move_row() to do the assignments.
		 */
		if (stmt->is_call && stmt->target == NULL)
		{
			Node	   *node;
			FuncExpr   *funcexpr;
			HeapTuple	func_tuple;
			List	   *funcargs;
			Oid		   *argtypes;
			char	  **argnames;
			char	   *argmodes;
			char	   *parammodes;
			MemoryContext oldcontext;
			PLtsql_row *row;
			int			nfields;
			int			i;
			int			relativeArgIndex;
			ListCell		*lc;

			if (is_scalar_func)
			{
				funcexpr = (FuncExpr *) target->expr;
			}
			else
			{
				/*
				 * Get the parsed CallStmt, and look up the called procedure
				 */
				node = query->utilityStmt;
				if (node == NULL || !IsA(node, CallStmt))
					elog(ERROR, "query for CALL statement is not a CallStmt");

				funcexpr = ((CallStmt *) node)->funcexpr;
			}

			/* Mark the procedure outside the view since procedure can never be called inside a view */
			funcexpr->insideView = PNODE_OUTSIDE_VIEW;

			func_tuple = SearchSysCache1(PROCOID,
										 ObjectIdGetDatum(funcexpr->funcid));
			if (!HeapTupleIsValid(func_tuple))
				elog(ERROR, "cache lookup failed for function %u",
					 funcexpr->funcid);

			/*
			 * Extract function arguments, and expand any named-arg notation
			 */
			funcargs = expand_function_arguments(funcexpr->args,
												 false,
												 funcexpr->funcresulttype,
												 func_tuple);

			/*
			 * Get the argument names and modes, too
			 */
			get_func_arg_info(func_tuple, &argtypes, &argnames, &argmodes);
			get_param_mode(stmt->params, stmt->paramno, &parammodes);

			ReleaseSysCache(func_tuple);
			
			/* handle RECOMPILE */
			created_with_recompile = is_created_with_recompile(funcexpr->funcid);	
			if (stmt->exec_with_recompile || created_with_recompile)
			{
				/*
				 * Note: it appears not to be necessary to restore the previous value
				 * of plan_cache_mode
				 */
				(void) set_config_option("plan_cache_mode", "force_custom_plan",
								  GUC_CONTEXT_CONFIG,
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);			
			}			

			/*
			 * Begin constructing row Datum
			 */
			oldcontext = MemoryContextSwitchTo(estate->func->fn_cxt);

			row = (PLtsql_row *) palloc0(sizeof(PLtsql_row));
			row->dtype = PLTSQL_DTYPE_ROW;
			row->refname = "(unnamed row)";
			row->lineno = -1;
			row->varnos = (int *) palloc0(sizeof(int) * list_length(funcargs));

			MemoryContextSwitchTo(oldcontext);

			/*
			 * Examine procedure's argument list.  Each output arg position
			 * should be an unadorned pltsql variable (Datum), which we can
			 * insert into the row Datum.
			 */
			nfields = 0;
			i = 0;
			foreach(lc, funcargs)
			{
				Node 	*n = lfirst(lc);

				if (argmodes &&
					(argmodes[i] == PROARGMODE_INOUT ||
					 argmodes[i] == PROARGMODE_OUT))
				{
					ListCell *paramcell;
					relativeArgIndex = 0;

					/*
					 * The order of arguments in procedure call might be different from the order of 
					 * arguments in the funcargs. 
					 * For each argument in funcargs, find corresponding argument in stmt->params.	
					 */
					foreach(paramcell, stmt->params)
					{
						tsql_exec_param *p = (tsql_exec_param *) lfirst(paramcell);
						if (argnames[i] && p->name && pg_strcasecmp(argnames[i], p->name) == 0)
							break;
						relativeArgIndex++;
					}

					/*
					 * If argnames[i] is not found in stmt->params, i th parameter is passed in 
					 * 'value' format instead of '@name = value'. In this case, argnames[i] should be mapped
					 * to i th element in stmt->params. 
					 */
					if (relativeArgIndex >= stmt->paramno) 
						relativeArgIndex = i;

					if (parammodes &&
						parammodes[relativeArgIndex] != PROARGMODE_INOUT &&
						parammodes[relativeArgIndex] != PROARGMODE_OUT)
					{
						/*
						 * If an INOUT arg is called without OUTPUT, it should
						 * be treated like an IN param. Put -1 to param id. We
						 * can skip assigning actual value.
						 */
						row->varnos[nfields++] = -1;
					}
					else if (IsA(n, Param))
					{
						Param	   *param = (Param *) n;

						/* paramid is offset by 1 (see make_datum_param()) */
						row->varnos[nfields++] = param->paramid - 1;
					}
					else if (get_underlying_node_from_implicit_casting(n, T_Param) != NULL)
					{
						/*
						 * Other than PL/pgsql, T-SQL allows implicit casting
						 * in INOUT and OUT params.
						 *
						 * In PG, if implcit casting is added (i.e.
						 * int->bigint), it throws an error "corresponding
						 * argument is not writable" (see the else-clause)
						 *
						 * In T-SQL, if arg node is an implicit casting, we
						 * will strip the casting. Actual casting will be done
						 * at value assignement with validity check.
						 */

						Param	   *param = (Param *) get_underlying_node_from_implicit_casting(n, T_Param);

						/* paramid is offset by 1 (see make_datum_param()) */
						row->varnos[nfields++] = param->paramid - 1;
					}
					else if (argmodes[i] == PROARGMODE_INOUT && IsA(n, Const))
					{
						/*
						 * T-SQL allows to pass constant value as an output
						 * parameter. Put -1 to param id. We can skip
						 * assigning actual value.
						 */
						row->varnos[nfields++] = -1;
					}
					else if (argmodes[i] == PROARGMODE_INOUT && get_underlying_node_from_implicit_casting(n, T_Const) != NULL)
					{
						/*
						 * mixture case of implicit casting + CONST. We can
						 * skip assigning actual value.
						 */
						row->varnos[nfields++] = -1;
					}
					else
					{
						/* report error using parameter name, if available */
						if (argnames && argnames[i] && argnames[i][0])
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("procedure parameter \"%s\" is an output parameter but corresponding argument is not writable",
											argnames[i])));
						else
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("procedure parameter %d is an output parameter but corresponding argument is not writable",
											i + 1)));
					}
				}
				i++;
			}

			row->nfields = nfields;

			stmt->target = (PLtsql_variable *) row;
		}

		if (estate->insert_exec)
		{
			/*
			 * For EXEC under INSERT ... EXECUTE, get the expected TupleDesc,
			 * create a DestReceiver and pass both to the CallStmt so that it
			 * will know to accumulate result rows and send them back here.
			 */

			Node	   *node;
			CallStmt   *callstmt;

			/*
			 * Get the parsed CallStmt
			 */
			node = linitial_node(Query,
								 ((CachedPlanSource *) linitial(plan->plancache_list))->query_list)->utilityStmt;
			if (node == NULL || !IsA(node, CallStmt))
				elog(ERROR, "query for CALL statement is not a CallStmt");

			tss = tuplestore_begin_heap(false, false, work_mem);
			dest = CreateTuplestoreDestReceiver();
			SetTuplestoreDestReceiverParams(dest, tss, CurrentMemoryContext, false, NULL, NULL);
			dest->rStartup(dest, -1, estate->rsi->expectedDesc);

			callstmt = (CallStmt *) node;
			callstmt->relation = InvalidOid;
			callstmt->attrnos = NULL;
			callstmt->retdesc = (void *) estate->rsi->expectedDesc;
			callstmt->dest = (void *) dest;
		}

		paramLI = setup_param_list(estate, expr);

		before_lxid = MyProc->vxid.lxid;
		topEntry = simple_econtext_stack;

		memset(&options, 0, sizeof(options));
		options.params = paramLI;
		options.read_only = estate->readonly_func;
		options.allow_nonatomic = true;

		/*
		 * For INSERT EXEC, wrap the procedure execution in a subtransaction.
		 * This ensures that if an error occurs (e.g., COMMIT without BEGIN TRAN),
		 * all changes made by the procedure are rolled back.
		 * 
		 * In SQL Server, INSERT EXEC runs in an implicit transaction context,
		 * so if COMMIT is called without BEGIN TRAN, error 3916 is thrown and
		 * all changes are rolled back.
		 * 
		 * OWNERSHIP CHAINING FIX:
		 * We also switch the security context to the procedure owner's identity
		 * before executing the inner procedure. This ensures that the EXECUTE
		 * permission check for the inner procedure uses the procedure owner's
		 * identity, which is required for ownership chaining to work correctly.
		 */
		if (insert_exec_setup_done)
		{
			MemoryContext oldcontext = CurrentMemoryContext;
			ResourceOwner oldowner = CurrentResourceOwner;
			volatile bool subtxn_started = false;
			volatile int subtxn_rc = 0;
			Oid ie_save_userid = InvalidOid;
			int ie_save_sec_context = 0;
			volatile bool ie_switched_context = false;

			PG_TRY(insert_exec_subtxn);
			{
				BeginInternalSubTransaction("insert_exec_proc");
				subtxn_started = true;
				MemoryContextSwitchTo(oldcontext);

				/*
				 * OWNERSHIP CHAINING FIX:
				 * Switch to the procedure owner's identity before executing the inner procedure.
				 * This ensures the EXECUTE permission check uses the procedure owner's identity.
				 * 
				 * Only switch context if we're inside a procedure (estate->func->fn_oid is valid).
				 * For top-level batches, no ownership chaining is needed.
				 */
				if (estate->func && OidIsValid(estate->func->fn_oid))
				{
					GetUserIdAndSecContext(&ie_save_userid, &ie_save_sec_context);
					SetUserIdAndSecContext(get_func_owner(estate->func->fn_oid),
										   ie_save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
					ie_switched_context = true;
				}

				subtxn_rc = SPI_execute_plan_extended(expr->plan, &options);

				/* Restore security context immediately after SPI call */
				if (ie_switched_context)
				{
					SetUserIdAndSecContext(ie_save_userid, ie_save_sec_context);
					ie_switched_context = false;
				}

				/* Procedure completed successfully - release (commit) the subtransaction */
				ReleaseCurrentSubTransaction();
				MemoryContextSwitchTo(oldcontext);
				CurrentResourceOwner = oldowner;
			}
			PG_CATCH(insert_exec_subtxn);
			{
				/* Restore security context on error if it was switched */
				if (ie_switched_context)
				{
					SetUserIdAndSecContext(ie_save_userid, ie_save_sec_context);
					ie_switched_context = false;
				}

				/* Roll back the subtransaction - this undoes the INSERT inside the procedure */
				if (subtxn_started)
				{
					RollbackAndReleaseCurrentSubTransaction();
				}
				MemoryContextSwitchTo(oldcontext);
				CurrentResourceOwner = oldowner;

				PG_RE_THROW();
			}
			PG_END_TRY(insert_exec_subtxn);

			rc = subtxn_rc;
		}
		else
		{
			rc = SPI_execute_plan_extended(expr->plan, &options);
		}

		after_lxid = MyProc->vxid.lxid;

		if (before_lxid != after_lxid ||
			simple_econtext_stack == NULL ||
			topEntry != simple_econtext_stack)
		{
			/*
			 * If we are in a new transaction after the call, we need to build
			 * new simple-expression infrastructure.
			 */
			if (estate->use_shared_simple_eval_state)
				estate->simple_eval_estate = NULL;
			pltsql_create_econtext(estate);
		}

		/*
		 * Copy the procedure's return code into the specified variable
		 *
		 * Note that the procedure stores its return code in the global
		 * variable named pltsql_proc_return_code.
		 */
		if (stmt->return_code_dno >= 0)
		{
			return_code = (PLtsql_var *) estate->datums[stmt->return_code_dno];

			if (is_scalar_func)
			{
				/*
				 * In case of scalar function, we should have 1-row/1-column
				 * result. Get the result data and assign into return_code. We
				 * should use exec_assign_value() to handle implicit casting
				 * correctly.
				 */
				Datum		retval;
				bool		isnull;

				if (SPI_processed != 1)
					elog(ERROR, "scalar function result does not return exactly one row");

				retval = SPI_getbinval(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1, &isnull);
				exec_assign_value(estate, (PLtsql_datum *) return_code, retval, isnull, rettype, rettypmod);
			}
			else
			{
				exec_assign_value(estate, (PLtsql_datum *) return_code, Int32GetDatum(pltsql_proc_return_code), false, INT4OID, 0);
			}
		}

		if (estate->insert_exec)
		{
			/*
			 * For EXEC under INSERT ... EXECUTE, get the rows sent back by
			 * the CallStmt, and store them into estate->tuple_store so that
			 * at the end of function execution they will be sent to the right
			 * place.
			 */
			TupleTableSlot *slot = MakeSingleTupleTableSlot(estate->rsi->expectedDesc,
															&TTSOpsMinimalTuple);

			if (estate->tuple_store == NULL)
				exec_init_tuple_store(estate);

			for (;;)
			{
				if (!tuplestore_gettupleslot(tss, true, false, slot))
					break;
				tuplestore_puttupleslot(estate->tuple_store, slot);
				ExecClearTuple(slot);
			}
			ExecDropSingleTupleTableSlot(slot);

			dest->rShutdown(dest);
			dest->rDestroy(dest);
		}
	}
	PG_CATCH();
	{
		/* 
		 * Cleanup INSERT EXEC state on error.
		 * 
		 * We set the error flag and clear the INSERT EXEC context. The error flag
		 * is used to skip the transaction count mismatch check in iterative_exec.c.
		 * 
		 * We cannot call drop_insert_exec_temp_table() here because SPI_execute
		 * cannot be used in an error context (transaction is aborted).
		 * We set the pending drop flag so the temp table will be dropped at the
		 * next opportunity when SPI is available.
		 * 
		 * IMPORTANT: We MUST clear the INSERT EXEC context even if other cleanup
		 * fails. Otherwise, subsequent queries will see pltsql_insert_exec_active()
		 * as true and try to use the stale temp table OID.
		 */
		if (insert_exec_setup_done)
		{
			pltsql_insert_exec_set_error_flag();
			pltsql_insert_exec_set_pending_drop();
			
			/*
			 * Close target table. This function already checks
			 * IsAbortedTransactionBlockState() and skips the unlock if
			 * the transaction is aborted.
			 */
			pltsql_insert_exec_close_target_table();
			
			/* Always clear the context, even if close_target_table failed */
			pltsql_clear_insert_exec_context();
		}
		
		if (strcmp(get_current_pltsql_db_name(), save_db_name) != 0)
			set_cur_user_db_and_path(save_db_name, false);

		pfree(save_db_name);

		/*
		 * If we aren't saving the plan, unset the pointer.  Note that it
		 * could have been unset already, in case of a recursive call.
		 */
		if (expr->plan && !expr->plan->saved)
		{
			SPIPlanPtr	plan = expr->plan;

			expr->plan = NULL;
			SPI_freeplan(plan);
		}
		
		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Cleanup that was in PG_FINALLY - runs on success path */
	if (strcmp(get_current_pltsql_db_name(), save_db_name) != 0)
		set_cur_user_db_and_path(save_db_name, false);

	pfree(save_db_name);

	/*
	 * If we aren't saving the plan, unset the pointer.  Note that it
	 * could have been unset already, in case of a recursive call.
	 */
	if (expr->plan && !expr->plan->saved)
	{
		SPIPlanPtr	plan = expr->plan;

		expr->plan = NULL;
		SPI_freeplan(plan);
	}

	if (rc < 0)
		elog(ERROR, "SPI_execute_plan_with_paramlist failed executing query \"%s\": %s",
			 expr->query, SPI_result_code_string(rc));

	/*
	 * Check result rowcount; if there's one row, assign procedure's output
	 * values back to the appropriate variables.
	 */
	if (SPI_processed == 1)
	{
		SPITupleTable *tuptab = SPI_tuptable;

		if (!stmt->target)
			elog(ERROR, "DO statement returned a row");

		if (tuptab != NULL)
			exec_move_row(estate, stmt->target, tuptab->vals[0], tuptab->tupdesc);
	}
	else if (SPI_processed > 1)
		elog(ERROR, "procedure call returned more than one row");

	exec_eval_cleanup(estate);
	SPI_freetuptable(SPI_tuptable);

	/*
	 * INSERT EXEC DestReceiver approach: Flush temp table to target
	 * and cleanup after procedure execution completes.
	 * 
	 * Execute the flush INSERT directly without a subtransaction wrapper.
	 * This matches the QTM branch behavior and ensures that:
	 * 1. Data flushed to the target table is committed at the current
	 *    transaction level (not nested in a subtransaction)
	 * 2. If an error occurs AFTER INSERT EXEC completes (e.g., SELECT 1/0),
	 *    the TRY-CATCH rollback won't undo the already-flushed data
	 * 
	 * NOTE: We must NOT clear the INSERT EXEC context before the flush,
	 * because flush_insert_exec_temp_table needs the target table info.
	 * We clear it AFTER the flush completes.
	 */
	if (insert_exec_setup_done)
	{
		MemoryContext oldcontext = CurrentMemoryContext;
		ResourceOwner oldowner = CurrentResourceOwner;
		
		PG_TRY();
		{
			/* Flush temp table to target table */
			flush_insert_exec_temp_table(estate);
			
			/*
			 * Close the target table that was held open during INSERT EXEC.
			 * This must be done AFTER the flush completes.
			 */
			pltsql_insert_exec_close_target_table();
			
			/*
			 * Clear the INSERT EXEC context AFTER the flush completes.
			 * This ensures the flush INSERT has access to target table info.
			 */
			pltsql_clear_insert_exec_context();
		}
		PG_CATCH();
		{
			/* Close target table and clear context before re-throwing */
			pltsql_insert_exec_close_target_table();
			pltsql_clear_insert_exec_context();
			drop_insert_exec_temp_table(insert_exec_temp_oid);
			PG_RE_THROW();
		}
		PG_END_TRY();
		
		/*
		 * Drop temp table in separate subtransaction.
		 * This isolates DROP failures from the main transaction.
		 */
		BeginInternalSubTransaction(NULL);
		MemoryContextSwitchTo(oldcontext);
		
		PG_TRY();
		{
			drop_insert_exec_temp_table(insert_exec_temp_oid);
			ReleaseCurrentSubTransaction();
			MemoryContextSwitchTo(oldcontext);
			CurrentResourceOwner = oldowner;
		}
		PG_CATCH();
		{
			/* DROP failed - rollback but don't propagate error */
			RollbackAndReleaseCurrentSubTransaction();
			MemoryContextSwitchTo(oldcontext);
			CurrentResourceOwner = oldowner;
			FlushErrorState();
			elog(DEBUG1, "INSERT-EXEC: Failed to drop temp table, will be cleaned up at transaction end");
		}
		PG_END_TRY();
	}

	return PLTSQL_RC_OK;
}

/*
 * Execute a DECLARE TABLE VARIABLE statement
 * Create an underlying temporary table for the table variable, with name
 * "<varname>_<@@NESTLEVEL>", and record the name and type in the variable
 * in estate.
 * If the table already exists, the just use it.
 */
static int
exec_stmt_decl_table(PLtsql_execstate *estate, PLtsql_stmt_decl_table *stmt)
{
	char	   *tblname;
	char	   *tblname_create;
	char	   *query;
	PLtsql_tbl *var = (PLtsql_tbl *) (estate->datums[stmt->dno]);
	int			rc;
	bool		isnull;
	int			old_client_min_messages;
	bool		old_pltsql_explain_only = pltsql_explain_only;

	pltsql_explain_only = false;	/* Create temporary table even in EXPLAIN
									 * ONLY mode */

	PG_TRY();
	{
		if (estate->nestlevel == -1)
		{
			rc = SPI_execute("SELECT @@nestlevel", true, 0);
			if (rc != SPI_OK_SELECT || SPI_processed != 1)
				elog(ERROR, "Failed to get @@NESTLEVEL when declaring table variable %s", var->refname);
			estate->nestlevel = DatumGetInt32(SPI_getbinval(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1, &isnull));
		}

		tblname = psprintf("%s_%d", var->refname, estate->nestlevel);

		/*
		 * If the original refname was already >=63 characters (the max limit of PG identifiers),
		 * then the above construction of tblname will be >63 characters, which will exceed the
		 * max length of PG identifiers and cause issues down the road. Fix this by truncating
		 * tblname so that adding the "_<@@nestlevel>" suffix will be exactly 63 characters.
		 */
		if (strlen(tblname) >= NAMEDATALEN)
		{
			// truncate tblname to fit the "_#" nestlevel suffix
			tblname[(NAMEDATALEN-1)-(strlen(tblname)-(NAMEDATALEN-1))] = '\0';
			// previous palloc of tblname will be cleaned up with the memory context
			tblname = psprintf("%s_%d", tblname, estate->nestlevel);
		}
		
		/*
		 * Add delimiters for valid T-SQL variable names like @@var or @var#
		 */
		if (is_tsql_atatuservar(tblname))
			tblname_create = psprintf("[%s]", tblname);
		else
			tblname_create = psprintf("%s", tblname);			
					
		if (stmt->tbltypname)
			query = psprintf("CREATE TEMPORARY TABLE IF NOT EXISTS %s (like %s including all)",
							 tblname_create, stmt->tbltypname);
		else
			query = psprintf("CREATE TEMPORARY TABLE IF NOT EXISTS %s%s",
							 tblname_create, stmt->coldef);

		/*
		 * If a table with the same name already exists, we should just use
		 * that table, and ignore the NOTICE of "relation already exists,
		 * skipping".
		 */
		old_client_min_messages = client_min_messages;
		client_min_messages = WARNING;
		rc = SPI_execute(query, false, 0);
		client_min_messages = old_client_min_messages;
		if (rc != SPI_OK_UTILITY)
			elog(ERROR, "Failed to create the underlying table for table variable %s", var->refname);

		if (old_pltsql_explain_only)
		{
			/* Restore EXPLAIN ONLY mode and append explain info */
			StringInfo	strinfo = makeStringInfo();

			appendStringInfo(strinfo, "DECLARE TABLE %s", var->refname);

			pltsql_explain_only = true;

			append_explain_info(NULL, strinfo->data);
			increment_explain_indent();
			append_explain_info(NULL, query);
			decrement_explain_indent();
		}

		var->tblname = tblname;
		if (var->tbltypeid == InvalidOid)
			var->tbltypeid = TypenameGetTypid(tblname);
		var->need_drop = true;

		init_failed_transactions_map();
	}
	PG_CATCH();
	{
		pltsql_explain_only = old_pltsql_explain_only;	/* Recover EXPLAIN ONLY
														 * mode */
		PG_RE_THROW();
	}
	PG_END_TRY();

	return PLTSQL_RC_OK;
}

/*
 * Execute a RETURN TABLE statement
 * Returns the output table variable in a Multi-Statement Table-Valued function.
 * This is a wrapper of the RETURN QUERY statement. Here it fills in the query
 * with a SELECT statement from the output table variable's underlying table,
 * and calls exec_stmt_return_query().
 */
static int
exec_stmt_return_table(PLtsql_execstate *estate, PLtsql_stmt_return_query *stmt)
{
	PLtsql_expr *expr;
	PLtsql_tbl *tbl;
	MemoryContext oldcontext;

	tbl = (PLtsql_tbl *) (estate->datums[estate->func->out_param_varno]);

	/*
	 * Begin constructing query expr
	 */
	oldcontext = MemoryContextSwitchTo(estate->func->fn_cxt);

	expr = palloc0(sizeof(PLtsql_expr));
	
	/*
	 * Add delimiters for valid T-SQL variable names like @@var or @var#
	 */	
	if (is_tsql_atatuservar(tbl->tblname))
		expr->query = psprintf("select * from [%s]", tbl->tblname);
	else
		expr->query = psprintf("select * from %s", tbl->tblname);

	expr->plan = NULL;
	expr->paramnos = NULL;
	expr->rwparam = -1;
	expr->ns = pltsql_ns_top();

	MemoryContextSwitchTo(oldcontext);

	stmt->query = expr;

	return exec_stmt_return_query(estate, stmt);
}

/*
 * Execute an EXEC statement of a character string
 */
static int
exec_stmt_exec_batch(PLtsql_execstate *estate, PLtsql_stmt_exec_batch *stmt)
{
	Datum		query;
	bool		isnull;
	Oid			restype;
	int32		restypmod;
	char	   *querystr;
	InlineCodeBlock *codeblock;
	volatile LocalTransactionId before_lxid = 0;
	LocalTransactionId after_lxid;
	SimpleEcontextStackEntry *topEntry = NULL;
	volatile int save_nestlevel = 0;
	volatile int scope_level = 0;
	char	   *old_db_name;
	char	   *cur_db_name = NULL;
	MemoryContext saved_context;
	
	/* INSERT EXEC handling - temp table lifecycle */
	bool insert_exec_setup_done = false;
	Oid insert_exec_temp_oid = InvalidOid;

	LOCAL_FCINFO(fcinfo, 1);
	
	/*
	 * Allocate old_db_name in TopMemoryContext so it survives any memory
	 * context switches during nested EXECUTE calls.
	 */
	saved_context = MemoryContextSwitchTo(TopMemoryContext);
	old_db_name = get_cur_db_name();
	MemoryContextSwitchTo(saved_context);

	/*
	 * First we evaluate the string expression. Its result is the
	 * querystring we have to execute.
	 */
	query = exec_eval_expr(estate, stmt->expr, &isnull, &restype, &restypmod);
	if (isnull)
	{
		/* Free old_db_name which was allocated in TopMemoryContext */
		pfree(old_db_name);
		return PLTSQL_RC_OK;
	}
	save_nestlevel = pltsql_new_guc_nest_level();
	scope_level = pltsql_new_scope_identity_nest_level();

	PG_TRY();
	{
		/*
		 * INSERT EXEC handling:
		 * If this is an INSERT EXEC statement (set by parser), create temp table here.
		 * The procedure output will be redirected to this temp table.
		 * After procedure completes, we flush temp table to target and cleanup.
		 * 
		 * This is inside PG_TRY so that errors (including nested INSERT EXEC)
		 * can be caught by T-SQL TRY/CATCH.
		 */
		if (stmt->insert_exec && stmt->insert_exec_target != NULL)
		{
			/*
			 * Check for nested INSERT EXEC - SQL Server error 8164.
			 * If INSERT EXEC context is already active, this is a nested call.
			 * Use same error code and message as old code path for consistency.
			 */
			if (pltsql_insert_exec_active())
			{
				ereport(ERROR,
						(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
						 errmsg("nested INSERT ... EXECUTE statements are not allowed")));
			}
			
			/* Set global context info for flush function */
			pltsql_set_insert_exec_context_info(stmt->insert_exec_target, stmt->insert_exec_columns);
			
			/*
			 * Open and hold the target table during INSERT EXEC execution.
			 * This is critical for detecting schema alterations (SQL Server error 556).
			 * By holding the target table open, PostgreSQL's CheckTableNotInUse()
			 * will detect if the procedure tries to ALTER TABLE on the target.
			 */
			pltsql_insert_exec_open_target_table(stmt->insert_exec_target);
			
			/* Create temp table based on target table structure */
			insert_exec_temp_oid = create_insert_exec_temp_table(stmt->insert_exec_target, 
																 stmt->insert_exec_columns);
			
			/* Set global context so DestReceiver knows where to write */
			pltsql_set_insert_exec_context(insert_exec_temp_oid);
			
			insert_exec_setup_done = true;
		}

		/* Get the C-String representation */
		querystr = convert_value_to_string(estate, query, restype);

		codeblock = makeNode(InlineCodeBlock);

		codeblock->source_text = querystr;
		codeblock->langOid = 0;
		codeblock->langIsTrusted = true;
		codeblock->atomic = false;
		MemSet(fcinfo, 0, SizeForFunctionCallInfo(1));
		fcinfo->args[0].value = PointerGetDatum(codeblock);
		fcinfo->args[0].isnull = false;
		before_lxid = MyProc->vxid.lxid;
		topEntry = simple_econtext_stack;

		/* Pass the control the inline handler */
		pltsql_inline_handler(fcinfo);

		if (fcinfo->isnull)
			elog(ERROR, "pltsql_inline_handler failed");
	}
	PG_CATCH();
	{
		/* 
		 * Cleanup INSERT EXEC state on error.
		 * 
		 * IMPORTANT: We MUST clear the INSERT EXEC context immediately, even if
		 * we're inside a TRY-CATCH block. This is because:
		 * 1. The temp table may have been dropped due to transaction abort
		 * 2. Between this PG_CATCH and the TRY-CATCH handler, other code might
		 *    check pltsql_insert_exec_active() and try to use the stale temp table OID
		 * 3. This leads to "could not open relation with OID" errors
		 * 
		 * We cannot call drop_insert_exec_temp_table() here because SPI_execute
		 * cannot be used in an error context (transaction is aborted).
		 * We set the pending drop flag so the temp table will be dropped at the
		 * next opportunity when SPI is available.
		 */
		if (insert_exec_setup_done)
		{
			pltsql_insert_exec_set_error_flag();
			pltsql_insert_exec_set_pending_drop();
			
			/*
			 * Close target table. This function already checks
			 * IsAbortedTransactionBlockState() and skips the unlock if
			 * the transaction is aborted.
			 */
			pltsql_insert_exec_close_target_table();
			
			/* Always clear the context to prevent stale state */
			pltsql_clear_insert_exec_context();
		}
		
		/* Restore GUC and scope identity settings before re-throwing */
		pltsql_revert_guc(save_nestlevel);
		pltsql_revert_last_scope_identity(scope_level);
		
		/*
		 * Restore database context on error. This ensures that when an error
		 * occurs inside a nested EXECUTE, the database context is properly
		 * restored to what it was before this EXECUTE started.
		 */
		cur_db_name = get_cur_db_name();
		if (strcmp(cur_db_name, old_db_name) != 0)
		{
			set_cur_user_db_and_path(old_db_name, false);
		}
		
		/* Free old_db_name which was allocated in TopMemoryContext */
		pfree(old_db_name);
		
		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Restore past settings */
	pltsql_revert_guc(save_nestlevel);
	pltsql_revert_last_scope_identity(scope_level);

	cur_db_name = get_cur_db_name();
	if (strcmp(cur_db_name, old_db_name) != 0)
	{
		set_cur_user_db_and_path(old_db_name, false);
	}

	after_lxid = MyProc->vxid.lxid;

	/*
	 * This logic is similar to what we do in exec_stmt_exec_spexecutesql().
	 * If we are in a different transaction here, we need to build new
	 * simple-expression infrastructure.
	 */
	if (before_lxid != after_lxid ||
		simple_econtext_stack == NULL ||
		topEntry != simple_econtext_stack)
	{
		if (estate->use_shared_simple_eval_state)
			estate->simple_eval_estate = NULL;
		pltsql_create_econtext(estate);
	}
	exec_eval_cleanup(estate);
	
	/*
	 * INSERT EXEC: Flush temp table to target and cleanup after 
	 * dynamic SQL execution completes.
	 * 
	 * Execute the flush INSERT directly without a subtransaction wrapper.
	 * Clear the INSERT EXEC context BEFORE the flush so that subsequent
	 * statements don't see the INSERT EXEC as active.
	 */
	if (insert_exec_setup_done)
	{
		MemoryContext oldcontext = CurrentMemoryContext;
		ResourceOwner oldowner = CurrentResourceOwner;
		
		PG_TRY();
		{
			/* Flush temp table to target table - no subtransaction wrapper */
			flush_insert_exec_temp_table(estate);
			
			/*
			 * Close the target table that was held open during INSERT EXEC.
			 * This must be done AFTER the flush completes.
			 */
			pltsql_insert_exec_close_target_table();
			
			/*
			 * Clear the INSERT EXEC context AFTER the flush completes.
			 * This ensures the flush INSERT has access to target table info.
			 */
			pltsql_clear_insert_exec_context();
		}
		PG_CATCH();
		{
			/* Close target table and clear context before re-throwing */
			pltsql_insert_exec_close_target_table();
			pltsql_clear_insert_exec_context();
			drop_insert_exec_temp_table(insert_exec_temp_oid);
			PG_RE_THROW();
		}
		PG_END_TRY();
		
		/* Drop temp table in separate subtransaction */
		BeginInternalSubTransaction(NULL);
		MemoryContextSwitchTo(oldcontext);
		
		PG_TRY();
		{
			drop_insert_exec_temp_table(insert_exec_temp_oid);
			ReleaseCurrentSubTransaction();
			MemoryContextSwitchTo(oldcontext);
			CurrentResourceOwner = oldowner;
		}
		PG_CATCH();
		{
			RollbackAndReleaseCurrentSubTransaction();
			MemoryContextSwitchTo(oldcontext);
			CurrentResourceOwner = oldowner;
			FlushErrorState();
		}
		PG_END_TRY();
		
	}
	
	/* Free old_db_name which was allocated in TopMemoryContext */
	pfree(old_db_name);
	
	return PLTSQL_RC_OK;
}

int
execute_batch(PLtsql_execstate *estate, char *batch, InlineCodeBlockArgs *args, List *params)
{
	Datum		retval;
	volatile LocalTransactionId before_lxid;
	LocalTransactionId after_lxid;
	SimpleEcontextStackEntry *topEntry;
	PLtsql_row *row = NULL;
	FmgrInfo	flinfo;
	InlineCodeBlock *codeblock = makeNode(InlineCodeBlock);

	/*
	 * In case of SP_PREPARE via RPC numargs will be 0 so we only need to
	 * allocate 2 indexes of memory.
	 */
	FunctionCallInfo fcinfo = palloc0(SizeForFunctionCallInfo((args) ? args->numargs + 2 : 2));

	/*
	 * 1. Build code block to store SQL query
	 */
	codeblock->source_text = batch;
	codeblock->atomic = false;	/* sp_executesql could not be top level */

	/*
	 * 2. Build fcinfo to pack all function info
	 */
	MemSet(&flinfo, 0, sizeof(flinfo));
	fcinfo->flinfo = &flinfo;
	flinfo.fn_oid = InvalidOid;
	flinfo.fn_mcxt = CurrentMemoryContext;
	fcinfo->args[0].value = PointerGetDatum(codeblock);
	fcinfo->args[0].isnull = false;
	fcinfo->nargs = 1;

	if (args)
	{
		/*
		 * We have to assign the param declaration info at the last because we
		 * may need to change the param mode in the above process.
		 */
		fcinfo->nargs += 1;
		fcinfo->args[1].value = PointerGetDatum(args);
		fcinfo->args[1].isnull = false;

		if (params)
		{
			/* SP_PREPAR may pass NULL, but it could not have params */
			Assert(estate);

			/*
			 * 3. Read parameter values, insert OUT parameter info in the row
			 * Datum.
			 */
			row = (PLtsql_row *) palloc0(sizeof(PLtsql_row));
			row->dtype = PLTSQL_DTYPE_ROW;
			row->refname = "(unnamed row)";
			row->lineno = -1;
			row->varnos = (int *) palloc(sizeof(int) * args->numargs);

			/*
			 * Load in the param definition
			 */

			/* Safety check */
			if (fcinfo->nargs > list_length(params) + 2)
				ereport(ERROR, (errcode(ERRCODE_TOO_MANY_ARGUMENTS),
								errmsg("cannot pass more than %d arguments to a procedure",
									   list_length(params))));

			read_param_val(estate, params, args, fcinfo, row);
		}
	}

	before_lxid = MyProc->vxid.lxid;
	topEntry = simple_econtext_stack;

	/*
	 * 4. Call inline handler to execute the whole statement
	 */
	fcinfo->isnull = true;
	PG_TRY();
	{
		create_queryEnv2(CacheMemoryContext, false);
		retval = pltsql_inline_handler(fcinfo);
		if (fcinfo->isnull)
			elog(ERROR, "pltsql_inline_handler failed");
	}
	PG_CATCH();
	{
		/* Delete temporary tables as ENR */
		pltsql_remove_current_query_env();

		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Delete temporary tables as ENR */
	pltsql_remove_current_query_env();

	after_lxid = MyProc->vxid.lxid;

	/* SP_PREPAR may pass NULL */
	if (!estate)
		return PLTSQL_RC_OK;

	if (before_lxid != after_lxid ||
		simple_econtext_stack == NULL ||
		topEntry != simple_econtext_stack)
	{
		/*
		 * If we are in a new transaction after the call, we need to build new
		 * simple-expression infrastructure.
		 */
		if (estate->use_shared_simple_eval_state)
			estate->simple_eval_estate = NULL;
		pltsql_create_econtext(estate);
	}

	exec_eval_cleanup(estate);

	/*
	 * 5. Got return value, make assignment to target variables
	 */
	if (row)
	{
		if (retval)
			exec_move_row_from_datum(estate, (PLtsql_variable *) row, retval);
		else
			exec_move_row(estate, (PLtsql_variable *) row, NULL, NULL);

		/* Cleanup after move row */
		exec_eval_cleanup(estate);
	}

	return PLTSQL_RC_OK;
}

static InlineCodeBlockArgs *
evaluate_sp_cursor_param_def(PLtsql_execstate *estate, PLtsql_expr *stmt_param_def, const char *proc_name)
{
	InlineCodeBlockArgs *args = NULL;
	Datum		paramdef;
	char	   *paramdefstr;
	bool		isnull;
	Oid			restype;
	int32		restypmod;

	args = create_args(0);

	if (stmt_param_def == NULL)
		return args;

	/* Evaluate the parameter definition */
	paramdef = exec_eval_expr(estate, stmt_param_def, &isnull, &restype, &restypmod);
	if (!isnull)
	{
		paramdefstr = convert_value_to_string(estate, paramdef, restype);
		if (strlen(paramdefstr) > 0)	/* empty string should be treated as
										 * same as NULL */
		{
			read_param_def(args, paramdefstr);

			reset_sp_cursor_params();
			for (int i = 0; i < args->numargs; ++i)
			{
				if (args->argmodes[i] != FUNC_PARAM_IN)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("output argument is not supported in %s yet", proc_name)));

				add_sp_cursor_param(args->argnames[i]);
			}
		}
	}

	return args;
}

static void
evaluate_sp_cursor_param_values(PLtsql_execstate *estate, int paramno, List *params, Datum **values, char **nulls)
{
	Oid			rettype;
	int32		rettypmod;
	ListCell   *lc;
	int			i = 0;
	bool		isnull;

	if (paramno <= 0)
		return;

	Assert(values);				/* should be provided by caller */
	Assert(nulls);				/* should be provided by caller */

	(*values) = (Datum *) palloc0(sizeof(Datum) * paramno);
	(*nulls) = (char *) palloc0(sizeof(char) * paramno);

	foreach(lc, params)
	{
		tsql_exec_param *p = (tsql_exec_param *) lfirst(lc);
		PLtsql_expr *expr = p->expr;

		if (p->name != NULL)
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("named argument is not supported in sp_cursoropen yet")));
		if (p->mode != FUNC_PARAM_IN)
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("output argument is not supported in sp_cursoropen yet")));

		(*values)[i] = exec_eval_expr(estate, expr, &isnull, &rettype, &rettypmod);
		if (isnull)
			(*nulls)[i] = 'n';
		++i;
	}
	Assert(i == paramno);
}

static int
exec_stmt_exec_sp(PLtsql_execstate *estate, PLtsql_stmt_exec_sp *stmt)
{
	int			cursor_handle;
	int			prepared_handle;
	Datum		val;
	bool		isnull;
	Oid			restype;
	int32		restypmod;
	char	   *querystr;
	int			ret = 0;

	/* T-SQL doesn't allow procedure calls in a function */
	if (estate->func && estate->func->fn_oid != InvalidOid && estate->func->fn_prokind == PROKIND_FUNCTION && estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER)
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
				 errmsg("Only functions can be executed within a function")));
	}

	switch (stmt->sp_type_code)
	{
		case PLTSQL_EXEC_SP_CURSOR:
			{
				int			opttype;
				int			rownum;
				char	   *tablename;

				cursor_handle = exec_eval_int(estate, stmt->handle, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("cursor argument of sp_cursor is null")));

				opttype = exec_eval_int(estate, stmt->opt1, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("opttype argument of sp_cursor is null")));

				rownum = exec_eval_int(estate, stmt->opt2, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("rownum argument of sp_cursor is null")));

				val = exec_eval_expr(estate, stmt->opt3, &isnull, &restype, &restypmod);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("table argument of sp_cursor is null")));
				tablename = convert_value_to_string(estate, val, restype);

				ret = execute_sp_cursor(cursor_handle, opttype, rownum, tablename, stmt->stropt);
				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursor failed: %d", ret)));

				break;
			}
		case PLTSQL_EXEC_SP_CURSOROPEN:
			{
				int			scrollopt;
				int			ccopt;
				int			rowcount;
				bool		scrollopt_null = true;
				bool		ccopt_null = true;
				bool		rowcount_null = true;
				InlineCodeBlockArgs *args = NULL;
				int			paramno = stmt->paramno;
				Datum	   *values = NULL;
				char	   *nulls = NULL;

				/* evaulate query string */
				val = exec_eval_expr(estate, stmt->query, &isnull, &restype, &restypmod);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("stmt argument of sp_cursoropen is null")));
				querystr = convert_value_to_string(estate, val, restype);

				if (stmt->opt1 != NULL)
					scrollopt = exec_eval_int(estate, stmt->opt1, &scrollopt_null);
				if (stmt->opt2 != NULL)
					ccopt = exec_eval_int(estate, stmt->opt2, &ccopt_null);
				if (stmt->opt3 != NULL)
					rowcount = exec_eval_int(estate, stmt->opt3, &rowcount_null);

				/* evalaute parameter definition */
				args = evaluate_sp_cursor_param_def(estate, stmt->param_def, "sp_cursoropen");
				if (args->numargs != stmt->paramno)
					ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
									errmsg("param definition mismatches with inputs")));

				/* evaluate parameter values */
				evaluate_sp_cursor_param_values(estate, paramno, stmt->params, &values, &nulls);

				enable_sp_cursor_find_param_hook();
				PG_TRY();
				{
					ret = execute_sp_cursoropen(&cursor_handle,
												querystr,
												(scrollopt_null ? NULL : &scrollopt),
												(ccopt_null ? NULL : &ccopt),
												(rowcount_null ? NULL : &rowcount),
												paramno, args->numargs, args->argtypes,
												values, nulls);
				}
				PG_CATCH();
				{
					disable_sp_cursor_find_param_hook();
					PG_RE_THROW();
				}
				PG_END_TRY();
				disable_sp_cursor_find_param_hook();

				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursoropen failed: %d", ret)));

				assign_simple_var(estate, (PLtsql_var *) estate->datums[stmt->cursor_handleno], Int32GetDatum(cursor_handle), false, false);
				break;
			}
		case PLTSQL_EXEC_SP_CURSORPREPARE:
			{
				int			options;
				int			scrollopt;
				int			ccopt;
				bool		scrollopt_null = true;
				bool		ccopt_null = true;
				InlineCodeBlockArgs *args = NULL;

				/* evaulate query string */
				val = exec_eval_expr(estate, stmt->query, &isnull, &restype, &restypmod);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("query string argument of sp_cursorprepare is null")));
				querystr = convert_value_to_string(estate, val, restype);

				if (stmt->opt1 != NULL)
					scrollopt = exec_eval_int(estate, stmt->opt1, &scrollopt_null);
				if (stmt->opt2 != NULL)
					ccopt = exec_eval_int(estate, stmt->opt2, &ccopt_null);
				Assert(stmt->opt3);
				options = exec_eval_int(estate, stmt->opt3, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("options argument of sp_cursorprepare is null")));

				/* evalaute parameter definition */
				args = evaluate_sp_cursor_param_def(estate, stmt->param_def, "sp_cursorprepare");

				enable_sp_cursor_find_param_hook();
				PG_TRY();
				{
					ret = execute_sp_cursorprepare(&prepared_handle,
												   querystr,
												   options,
												   (scrollopt_null ? NULL : &scrollopt),
												   (ccopt_null ? NULL : &ccopt),
												   args->numargs, args->argtypes);
				}
				PG_CATCH();
				{
					disable_sp_cursor_find_param_hook();
					PG_RE_THROW();
				}
				PG_END_TRY();
				disable_sp_cursor_find_param_hook();

				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursorprepare failed: %d", ret)));

				assign_simple_var(estate, (PLtsql_var *) estate->datums[stmt->prepared_handleno], Int32GetDatum(prepared_handle), false, false);
				break;
			}
		case PLTSQL_EXEC_SP_CURSOREXECUTE:
			{
				int			scrollopt;
				int			ccopt;
				int			rowcount;
				bool		scrollopt_null = true;
				bool		ccopt_null = true;
				bool		rowcount_null = true;
				int			paramno = stmt->paramno;
				Datum	   *values = NULL;
				char	   *nulls = NULL;

				prepared_handle = exec_eval_int(estate, stmt->handle, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("prepared_handle argument of sp_cursorexecute is null")));

				if (stmt->opt1 != NULL)
					scrollopt = exec_eval_int(estate, stmt->opt1, &scrollopt_null);
				if (stmt->opt2 != NULL)
					ccopt = exec_eval_int(estate, stmt->opt2, &ccopt_null);
				if (stmt->opt3 != NULL)
					rowcount = exec_eval_int(estate, stmt->opt3, &rowcount_null);

				/* evaluate parameter values */
				evaluate_sp_cursor_param_values(estate, paramno, stmt->params, &values, &nulls);

				ret = execute_sp_cursorexecute(prepared_handle,
											   &cursor_handle,
											   (scrollopt_null ? NULL : &scrollopt),
											   (ccopt_null ? NULL : &ccopt),
											   (rowcount_null ? NULL : &rowcount),
											   paramno, values, nulls);
				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursorexecute failed: %d", ret)));

				assign_simple_var(estate, (PLtsql_var *) estate->datums[stmt->cursor_handleno], Int32GetDatum(cursor_handle), false, false);
				break;
			}
		case PLTSQL_EXEC_SP_CURSORPREPEXEC:
			{
				int			scrollopt;
				int			ccopt;
				int			rowcount;
				bool		scrollopt_null = true;
				bool		ccopt_null = true;
				bool		rowcount_null = true;
				InlineCodeBlockArgs *args = NULL;
				int			paramno = stmt->paramno;
				Datum	   *values = NULL;
				char	   *nulls = NULL;

				/* evaulate query string */
				val = exec_eval_expr(estate, stmt->query, &isnull, &restype, &restypmod);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("stmt argument of sp_cursorprepexec is null")));
				querystr = convert_value_to_string(estate, val, restype);

				if (stmt->opt1 != NULL)
					scrollopt = exec_eval_int(estate, stmt->opt1, &scrollopt_null);
				if (stmt->opt2 != NULL)
					ccopt = exec_eval_int(estate, stmt->opt2, &ccopt_null);
				if (stmt->opt3 != NULL)
					rowcount = exec_eval_int(estate, stmt->opt3, &rowcount_null);

				/* evalaute parameter definition */
				args = evaluate_sp_cursor_param_def(estate, stmt->param_def, "sp_cursorprepexec");
				if (args->numargs != stmt->paramno)
					ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
									errmsg("param definition mismatches with inputs")));

				/* evaluate parameter values */
				evaluate_sp_cursor_param_values(estate, paramno, stmt->params, &values, &nulls);

				enable_sp_cursor_find_param_hook();
				PG_TRY();
				{
					ret = execute_sp_cursorprepexec(&prepared_handle,
													&cursor_handle,
													querystr,
													1,	/* options: unlike
														 * documenation,
														 * sp_cursorprepexec
														 * doens't take an
														 * option value */
													(scrollopt_null ? NULL : &scrollopt),
													(ccopt_null ? NULL : &ccopt),
													(rowcount_null ? NULL : &rowcount),
													paramno, args->numargs,
													args->argtypes, values, nulls);
				}
				PG_CATCH();
				{
					disable_sp_cursor_find_param_hook();
					PG_RE_THROW();
				}
				PG_END_TRY();
				disable_sp_cursor_find_param_hook();

				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursorprepexec failed: %d", ret)));

				assign_simple_var(estate, (PLtsql_var *) estate->datums[stmt->prepared_handleno], Int32GetDatum(prepared_handle), false, false);
				assign_simple_var(estate, (PLtsql_var *) estate->datums[stmt->cursor_handleno], Int32GetDatum(cursor_handle), false, false);
				break;
			}
		case PLTSQL_EXEC_SP_CURSORUNPREPARE:
			{
				prepared_handle = exec_eval_int(estate, stmt->handle, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("prepared_handle argument of sp_cursorunprepare is null")));

				ret = execute_sp_cursorunprepare(prepared_handle);

				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursorunprepare failed: %d", ret)));
				break;
			}
		case PLTSQL_EXEC_SP_CURSORFETCH:
			{
				int			fetchtype;
				int			rownum;
				int			nrows;
				bool		fetchtype_null = true;
				bool		rownum_null = true;
				bool		nrows_null = true;

				cursor_handle = exec_eval_int(estate, stmt->handle, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("cursor argument of sp_cursorfetch is null")));

				if (stmt->opt1 != NULL)
					fetchtype = exec_eval_int(estate, stmt->opt1, &fetchtype_null);
				if (stmt->opt2 != NULL)
					rownum = exec_eval_int(estate, stmt->opt2, &rownum_null);
				if (stmt->opt3 != NULL)
					nrows = exec_eval_int(estate, stmt->opt3, &nrows_null);

				ret = execute_sp_cursorfetch(cursor_handle,
											 (fetchtype_null ? NULL : &fetchtype),
											 (rownum_null ? NULL : &rownum),
											 (nrows_null ? NULL : &nrows));
				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursorfetch failed: %d", ret)));
				break;
			}
		case PLTSQL_EXEC_SP_CURSOROPTION:
			{
				int			code;
				int			ivalue;
				char	   *cvalue;

				cursor_handle = exec_eval_int(estate, stmt->handle, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("cursor argument of sp_cursoroption is null")));

				code = exec_eval_int(estate, stmt->opt1, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("code argument of sp_cursoroption is null")));

				if (code == 0x2)	/* special case */
				{
					val = exec_eval_expr(estate, stmt->opt2, &isnull, &restype, &restypmod);
					if (isnull)
						ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
										errmsg("value argument of sp_cursoroption is null")));
					cvalue = convert_value_to_string(estate, val, restype);

					ret = execute_sp_cursoroption2(cursor_handle, code, cvalue);
				}
				else
				{
					ivalue = exec_eval_int(estate, stmt->opt2, &isnull);
					if (isnull)
						ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
										errmsg("value argument of sp_cursoroption is null")));

					ret = execute_sp_cursoroption(cursor_handle, code, ivalue);
				}

				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursoroption failed: %d", ret)));
				break;
			}
		case PLTSQL_EXEC_SP_CURSORCLOSE:
			{
				cursor_handle = exec_eval_int(estate, stmt->handle, &isnull);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("cursor argument of sp_cursorfetch is null")));

				ret = execute_sp_cursorclose(cursor_handle);

				if (ret > 0)
					ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("sp_cursorclose failed: %d", ret)));
				break;
			}
		case PLTSQL_EXEC_SP_EXECUTESQL:
			{
				Datum		batch;
				char	   *batchstr;
				bool		isnull1;
				Oid			restype1;
				int32		restypmod1;
				int			save_nestlevel;
				int			scope_level;
				InlineCodeBlockArgs *args = NULL;
				
				/* INSERT EXEC handling - temp table lifecycle */
				bool insert_exec_setup_done = false;
				Oid insert_exec_temp_oid = InvalidOid;
				
				batch = exec_eval_expr(estate, stmt->query, &isnull1, &restype1, &restypmod1);
				if (isnull1)
				{
					/* When called with a NULL argument, sp_executesql should take no action at all */
					break;
				}

				batchstr = convert_value_to_string(estate, batch, restype1);

				args = create_args(0);
				if (stmt->param_def)
				{
					Datum		paramdef;
					Oid			restype2;
					int32		restypmod2;
					char	   *paramdefstr;
					bool		isnull2;

					/*
					 * Evaluate the parameter definition
					 */
					paramdef = exec_eval_expr(estate, stmt->param_def, &isnull2, &restype2, &restypmod2);

					if (isnull2)
						ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
										errmsg("NULL param definition")));

					paramdefstr = convert_value_to_string(estate, paramdef, restype2);

					if (strcmp(paramdefstr, "") != 0)	/* check edge cases for
														 * sp_executesql */
					{
						read_param_def(args, paramdefstr);

						if (args->numargs != stmt->paramno)
							ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
											errmsg("param definition mismatches with inputs")));
					}
				}

				save_nestlevel = pltsql_new_guc_nest_level();
				scope_level = pltsql_new_scope_identity_nest_level();

				PG_TRY();
				{
					/*
					 * INSERT EXEC handling:
					 * If this is an INSERT EXEC statement (set by parser), create temp table here.
					 * The procedure output will be redirected to this temp table.
					 * After procedure completes, we flush temp table to target and cleanup.
					 * 
					 * This is inside PG_TRY so that errors (including nested INSERT EXEC)
					 * can be caught by T-SQL TRY/CATCH.
					 */
					if (stmt->insert_exec && stmt->insert_exec_target != NULL)
					{
						/*
						 * Check for nested INSERT EXEC - SQL Server error 8164.
						 * If INSERT EXEC context is already active, this is a nested call.
						 * Use same error code and message as old code path for consistency.
						 */
						if (pltsql_insert_exec_active())
						{
							ereport(ERROR,
									(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
									 errmsg("nested INSERT ... EXECUTE statements are not allowed")));
						}
						
						/* Set global context info for flush function */
						pltsql_set_insert_exec_context_info(stmt->insert_exec_target, stmt->insert_exec_columns);
						
						/*
						 * Open and hold the target table during INSERT EXEC execution.
						 * This is critical for detecting schema alterations (SQL Server error 556).
						 * By holding the target table open, PostgreSQL's CheckTableNotInUse()
						 * will detect if the procedure tries to ALTER TABLE on the target.
						 */
						pltsql_insert_exec_open_target_table(stmt->insert_exec_target);
						
						/* Create temp table based on target table structure */
						insert_exec_temp_oid = create_insert_exec_temp_table(stmt->insert_exec_target, 
																			 stmt->insert_exec_columns);
						
						/* Set global context so DestReceiver knows where to write */
						pltsql_set_insert_exec_context(insert_exec_temp_oid);
						
						insert_exec_setup_done = true;
					}

					if (strcmp(batchstr, "") != 0)	/* check edge cases for
													 * sp_executesql */
					{
						ret = execute_batch(estate, batchstr, args, stmt->params);
					}

					if (stmt->return_code_dno != -1)
					{
						exec_assign_value(estate, estate->datums[stmt->return_code_dno], Int32GetDatum(ret), false, INT4OID, 0);
					}
				}
				PG_CATCH();
				{
					/* 
					 * Cleanup INSERT EXEC state on error.
					 * 
					 * IMPORTANT: We MUST clear the INSERT EXEC context immediately, even if
					 * we're inside a TRY-CATCH block. This is because:
					 * 1. The temp table may have been dropped due to transaction abort
					 * 2. Between this PG_CATCH and the TRY-CATCH handler, other code might
					 *    check pltsql_insert_exec_active() and try to use the stale temp table OID
					 * 3. This leads to "could not open relation with OID" errors
					 * 
					 * We cannot call drop_insert_exec_temp_table() here because SPI_execute
					 * cannot be used in an error context (transaction is aborted).
					 * The temp table will be automatically cleaned up when the transaction
					 * rolls back.
					 */
					if (insert_exec_setup_done)
					{
						pltsql_insert_exec_set_error_flag();
						pltsql_insert_exec_set_pending_drop();
						
						/*
						 * Close target table. This function already checks
						 * IsAbortedTransactionBlockState() and skips the unlock if
						 * the transaction is aborted.
						 */
						pltsql_insert_exec_close_target_table();
						
						/* Always clear the context to prevent stale state */
						pltsql_clear_insert_exec_context();
					}
					pltsql_revert_guc(save_nestlevel);
					pltsql_revert_last_scope_identity(scope_level);
					PG_RE_THROW();
				}
				PG_END_TRY();
				
				pltsql_revert_guc(save_nestlevel);
				pltsql_revert_last_scope_identity(scope_level);
				
				/*
				 * INSERT EXEC: Flush temp table to target and cleanup after 
				 * sp_executesql execution completes.
				 * 
				 * Execute the flush INSERT directly without a subtransaction wrapper.
				 * Clear the INSERT EXEC context AFTER the flush so that the flush
				 * has access to target table info.
				 */
				if (insert_exec_setup_done)
				{
					MemoryContext oldcontext = CurrentMemoryContext;
					ResourceOwner oldowner = CurrentResourceOwner;
					
					PG_TRY();
					{
						/* Flush temp table to target table - no subtransaction wrapper */
						flush_insert_exec_temp_table(estate);
						
						/*
						 * Close the target table that was held open during INSERT EXEC.
						 * This must be done AFTER the flush completes.
						 */
						pltsql_insert_exec_close_target_table();
						
						/*
						 * Clear the INSERT EXEC context AFTER the flush completes.
						 * This ensures the flush INSERT has access to target table info.
						 */
						pltsql_clear_insert_exec_context();
					}
					PG_CATCH();
					{
						/* Close target table and clear context before re-throwing */
						pltsql_insert_exec_close_target_table();
						pltsql_clear_insert_exec_context();
						drop_insert_exec_temp_table(insert_exec_temp_oid);
						PG_RE_THROW();
					}
					PG_END_TRY();
					
					/* Drop temp table in separate subtransaction */
					BeginInternalSubTransaction(NULL);
					MemoryContextSwitchTo(oldcontext);
					
					PG_TRY();
					{
						drop_insert_exec_temp_table(insert_exec_temp_oid);
						ReleaseCurrentSubTransaction();
						MemoryContextSwitchTo(oldcontext);
						CurrentResourceOwner = oldowner;
					}
					PG_CATCH();
					{
						RollbackAndReleaseCurrentSubTransaction();
						MemoryContextSwitchTo(oldcontext);
						CurrentResourceOwner = oldowner;
						FlushErrorState();
					}
					PG_END_TRY();
				}
				
				break;
			}
		case PLTSQL_EXEC_SP_EXECUTE:
			{
				int			handle = exec_eval_int(estate, stmt->handle, &isnull);
				InlineCodeBlockArgs *args;
				PLtsql_function *func;

				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("handle argument of sp_execute is null")));

				func = find_cached_batch(handle);
				if (!func)
					ereport(ERROR, (errcode(ERRCODE_UNDEFINED_OBJECT),
									errmsg("Prepared statement not found: %d", handle)));

				Assert(func->inline_args);
				args = clone_inline_args(func->inline_args);
				args->options = (BATCH_OPTION_EXEC_CACHED_PLAN |
								 BATCH_OPTION_NO_FREE);
				args->handle = handle;

				ret = execute_batch(estate, NULL, args, stmt->params);
				break;
			}
		case PLTSQL_EXEC_SP_PREPEXEC:
			{
				Datum		batch;
				char	   *batchstr;
				bool		isnull3;
				Oid			restype3;
				int32		restypmod3;
				InlineCodeBlockArgs *args = NULL;
				Datum		paramdef;
				char	   *paramdefstr;

				batch = exec_eval_expr(estate, stmt->query, &isnull3, &restype3, &restypmod3);
				if (isnull3)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("batch string argument of sp_prepexec is null")));

				batchstr = convert_value_to_string(estate, batch, restype3);

				args = create_args(0);

				/*
				 * Evaluate the parameter definition
				 */
				paramdef = exec_eval_expr(estate, stmt->param_def, &isnull3, &restype3, &restypmod3);

				if (!isnull3)
				{
					paramdefstr = convert_value_to_string(estate, paramdef, restype3);

					read_param_def(args, paramdefstr);

					if (args->numargs != stmt->paramno)
						ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
										errmsg("param definition mismatches with inputs")));
				}

				args->options = (BATCH_OPTION_CACHE_PLAN |
								 BATCH_OPTION_NO_FREE);

				ret = execute_batch(estate, batchstr, args, stmt->params);

				assign_simple_var(estate, (PLtsql_var *) estate->datums[stmt->prepared_handleno],
								  Int32GetDatum(args->handle), false, false);
				break;

			}
		default:
			break;
	}

	return PLTSQL_RC_OK;
}

/* ----------
 * exec_stmt_deallocate  DEALLOCATE curvar
 * ----------
 */
static int
exec_stmt_deallocate(PLtsql_execstate *estate, PLtsql_stmt_deallocate *stmt)
{
	PLtsql_var *curvar;
	Portal		portal;
	char	   *curname = NULL;
	MemoryContext oldcontext;

	Assert(estate->datums[stmt->curvar]->dtype == PLTSQL_DTYPE_VAR);

	curvar = (PLtsql_var *) estate->datums[stmt->curvar];
	Assert(is_cursor_datatype(curvar->datatype->typoid));

	if (curvar->isnull)
	{
		elog(ERROR, "cursor variable does not have a cursor allocated to it.");
	}

	/* if cursor is already opened, call close to release all resources */
	if (!curvar->isnull)
	{
		/* Use eval_mcontext for short-lived string */
		oldcontext = MemoryContextSwitchTo(get_eval_mcontext(estate));
		curname = TextDatumGetCString(curvar->value);
		MemoryContextSwitchTo(oldcontext);

		portal = SPI_cursor_find(curname);
		if (portal)
		{
			if (IS_TDS_CLIENT() && portal->portalPinned)

				UnpinPortal(portal);

			SPI_cursor_close(portal);
		}
	}

	/* if cursor expr holds a plan, release it */
	if (curvar->cursor_explicit_expr)
	{
		if (curvar->cursor_explicit_expr->plan)
			SPI_freeplan(curvar->cursor_explicit_expr->plan);
		curvar->cursor_explicit_expr->plan = NULL;
	}

	/* remove all association from curvar */
	if (!curvar->isconst)
		curvar->isnull = true;

	exec_set_rowcount(0);

	pltsql_update_cursor_row_count(curname, 0);
	pltsql_update_cursor_last_operation(curname, 7);

	return PLTSQL_RC_OK;
}

/* ----------
 * exec_stmt_decl_cursor  ECLARE cursor
 * ----------
 */
static int
exec_stmt_decl_cursor(PLtsql_execstate *estate, PLtsql_stmt_decl_cursor *stmt)
{
	PLtsql_var *curvar;
	char	   *curname;
	MemoryContext oldcontext;

	Assert(estate->datums[stmt->curvar]->dtype == PLTSQL_DTYPE_VAR);

	curvar = (PLtsql_var *) estate->datums[stmt->curvar];
	Assert(is_cursor_datatype(curvar->datatype->typoid));
	if (!curvar->isconst)
		return PLTSQL_RC_OK;	/* cursor variable. nothing to do here */

	if (!pltsql_declare_cursor(estate, curvar, stmt->cursor_explicit_expr, stmt->cursor_options))
	{
		/* Use eval_mcontext for short-lived string */
		oldcontext = MemoryContextSwitchTo(get_eval_mcontext(estate));
		curname = TextDatumGetCString(curvar->value);
		MemoryContextSwitchTo(oldcontext);

		elog(ERROR, "cursor %s already exists", pltsql_demangle_curname(curname));
	}

	return PLTSQL_RC_OK;
}

static char *
transform_tsql_temp_tables(char *dynstmt)
{
	StringInfoData ds;
	char	   *cp;
	char	   *word;
	char	   *prev_word;

	initStringInfo(&ds);
	prev_word = NULL;

	for (cp = dynstmt; *cp; cp++)
	{
		if (cp[0] == '#' && is_char_identstart(cp[1]))
		{
			/*
			 * Quote this local temporary table identifier.  next_word stops
			 * as soon as it encounters a non-ident character such as '#', we
			 * point it to the next character as the start of word while
			 * specifying the '#' prefix explicitly in the format string.
			 */
			word = next_word(cp + 1);
			appendStringInfo(&ds, "\"#%s\"", word);
			cp += strlen(word);
		}
		else if (is_char_identstart(cp[0]))
		{
			word = next_word(cp);
			cp += (strlen(word) - 1);

			/* CREATE TABLE #<ident> -> CREATE TEMPORARY TABLE #<ident> */
			if ((prev_word && (pg_strcasecmp(prev_word, "CREATE") == 0)) &&
				(pg_strcasecmp(word, "TABLE") == 0) &&
				is_next_temptbl(cp))
			{
				appendStringInfo(&ds, "TEMPORARY %s", word);
			}
			else
				appendStringInfoString(&ds, word);

			prev_word = word;
		}
		else
			appendStringInfoChar(&ds, *cp);
	}

	return ds.data;
}

static char *
next_word(char *dyntext)
{
	StringInfoData ds;

	initStringInfo(&ds);

	while (*dyntext && is_char_identpart(*dyntext))
		appendStringInfoChar(&ds, *(dyntext++));

	return ds.data;
}

static bool
is_next_temptbl(char *dyntext)
{
	while (*++dyntext && scanner_isspace(*dyntext));	/* skip whitespace */

	return (dyntext[0] == '#' && is_char_identstart(dyntext[1]));
}

static bool
is_char_identstart(char c)
{
	return ((c == '_') ||
			(c >= 'A' && c <= 'Z') ||
			(c >= 'a' && c <= 'z') ||
			(c >= '\200' && c <= '\377'));
}

static bool
is_char_identpart(char c)
{
	return ((is_char_identstart(c)) ||
			(c >= '0' && c <= '9'));
}

/*
 * Check for allowed chars in @variable name
 * ToDo: support non-standard ASCII chars (Unicode ranges)
 * and align with is_identifier_char()
 */
static inline bool
is_variable_name_char(unsigned char c)
{
	bool valid = (
					isalpha(c) ||
					isdigit(c) ||
					c == '_' || 
					c == '@' || 
					c == '$' || 
					c == '#'
				);

	return valid;	
}

/*
 * Put delimiters around a T-SQL variable/parameter that is
 * named '@@var' or contains a hash, e.g. '@var#'.
 * Without delimiters, the backend will raise an error.
 * This is used for the parameter argument of sp_executesql, so the input
 * string may contain multiple names, e.g.: @par1 int, @par2 varchar(20), ...
 * This function calls palloc() to allocate a new string and returns a pointer
 * to this string.
 */
static char *
delimit_tsql_atatuservar(const char *src)
{
	char *s = (char *) src;
	char *varname_start = NULL;
	bool add_delimiter = false;
	
	/* 
	 * Reserving twice the amount of space of the input string: since the shortest possible
	 * parameter definition is 5 characters ('@@p x' , where x would be the type), this will 
	 * always be enough for adding delimiters.
	 * Note that there can be multiple parameter names in the input string.
	 */
	char *result = (char *) palloc(sizeof(char)*strlen(src)*2);	
	char *tgt = result;

	while (*s)
	{
		/* Look for start of variable name, which is always '@' */
		if (*s != '@')
		{
			*tgt++ = *s++;
			continue;
		}

		/* Start of variable name found */
		add_delimiter = false;

		varname_start = s;

		/* Name starting with @@ */
		if (*(s+1))
		{
			if (*(s+1) == '@')
			{
				add_delimiter = true;
			}
		}

		/* Find end of variable name */
		while (*s)
		{
			/* Check for allowed chars in @variable name */
			if (is_variable_name_char(*s))
			{
				/* Name contains # */
				if (*s == '#')
				{
					add_delimiter = true;
				}

				s++;
			}
			else
			{
				break;
			}
		}

		if (varname_start != src)
		{
			/* 
			 * Do not add delimiters if the name is already delimited.
			 * Both square brackets and double quotes are used as delimiters for variable names.
			 */
			if ((*(varname_start-1) == '[') || (*(varname_start-1) == '"'))
			{
				add_delimiter = false;
			}
		}

		// Add delimiters to the name if required
		if (add_delimiter) *tgt++ = '[';
		while (varname_start != s)
		{
			*tgt++ = *varname_start++;
		}
		if (add_delimiter) *tgt++ = ']';
	} /* while */

	*tgt = '\0';
	return result;
}

/*
 * Determine whether the passed name is a T-SQL variable/parameter name that is
 * named '@@var' or contains a hash, e.g. '@var#'.
 */
bool
is_tsql_atatuservar(const char *varname)
{
	char *s = (char *) varname;
	bool is_atatuservar = false;

	/* The variable names we're looking for are at least 3 chars */
	if (strlen(varname) <= 2)
	{
		return false;
	} 
	
	/* Variable name must start with '@' */
	if (*s != '@')
	{
		return false;
	}
	
	/* Starts with '@@' ? */
	s++;
	if (*s == '@')
	{
		is_atatuservar = true;
	}	

	while (*s)
	{
		/* Check for allowed chars in @variable name */
		if (is_variable_name_char(*s))
		{
			/* Name contains # */
			if (*s == '#')
			{
				is_atatuservar = true;
			}

			s++;
		}
		else
		{
			return false;
		}
	} /* while */
	
	/* 
	 * The variable name should continue until end of string; if not, 
	 * something is wrong
	 *
	 * NB: The assertion below is logically true given the loop above,
	 * but kept in the code for clarity.
	 */
	Assert(*s == '\0');  
	
	return is_atatuservar;
}

/*
 * Read parameter definitions
 */
void
read_param_def(InlineCodeBlockArgs *args, const char *paramdefstr)
{
	List	   *parsetree;
	List	   *params;
	ListCell   *lc;
	int			i = 0;
	const char *str1 = "CREATE PROC p_tmp_spexecutesql (";
	const char *str2 = ") AS BEGIN END; DROP PROC p_tmp_spexecutesql;";
	StringInfoData proc_stmt;

	Assert(args);

	if (!paramdefstr)
	{
		args->numargs = 0;
		return;
	}

	/*
	 * Create a fake CREATE PROCEDURE statement to get the param definition
	 * parse tree.
	 * Delimiters will be applied around parameter names like @@par or @par#.
	 */
	initStringInfo(&proc_stmt);
	appendStringInfoString(&proc_stmt, str1);
	appendStringInfoString(&proc_stmt, delimit_tsql_atatuservar(paramdefstr));
	appendStringInfoString(&proc_stmt, str2);

	parsetree = raw_parser(proc_stmt.data, RAW_PARSE_DEFAULT);

	/*
	 * Seperate each param definition, and calculate the total number of
	 * definitions.
	 */
	params = ((CreateFunctionStmt *) (((RawStmt *) linitial(parsetree))->stmt))->parameters;

	/*
	 * Throw error if the provided number of arguments are more than the max
	 * allowed limit.
	 */
	if (list_length(params) > PREPARE_STMT_MAX_ARGS)
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("Too many arguments were provided: %d. The maximum allowed limit is %d",
						list_length(params), PREPARE_STMT_MAX_ARGS)));

	args->numargs = list_length(params);
	args->argtypes = (Oid *) palloc(sizeof(Oid) * args->numargs);
	args->argtypmods = (int32 *) palloc(sizeof(int32) * args->numargs);
	args->argnames = (char **) palloc(sizeof(char *) * args->numargs);
	args->argmodes = (char *) palloc(sizeof(char) * args->numargs);

	foreach(lc, params)
	{
		FunctionParameter *p;

		p = (FunctionParameter *) lfirst(lc);
		args->argnames[i] = p->name;
		args->argmodes[i] = p->mode;

		/*
		 * Handle User defined types with schema qualifiers. Convert logical
		 * Schema Name to Physical Schema Name. Note: The list length can not
		 * be more than 2 since db name can not be a qualifier for a UDT and
		 * error will be thrown in the parser itself.
		 */
		p->argType->names = rewrite_plain_name(p->argType->names);

		typenameTypeIdAndMod(NULL, p->argType, &(args->argtypes[i]), &(args->argtypmods[i]));
		i++;
	}
}

InlineCodeBlockArgs *
create_args(int numargs)
{
	InlineCodeBlockArgs *args;

	args = (InlineCodeBlockArgs *) palloc0(sizeof(InlineCodeBlockArgs));
	args->numargs = numargs;
	args->argtypes = (Oid *) palloc(sizeof(Oid) * numargs);
	args->argtypmods = (int32 *) palloc(sizeof(int32) * numargs);
	args->argnames = (char **) palloc(sizeof(char *) * numargs);
	args->argmodes = (char *) palloc(sizeof(char) * numargs);
	args->options = 0;
	return args;
}

void
cache_inline_args(PLtsql_function *func, InlineCodeBlockArgs *args)
{
	MemoryContext oldcontext;

	/* keep arg def's life cycle same as tree */
	oldcontext = MemoryContextSwitchTo(func->fn_cxt);
	func->inline_args = clone_inline_args(args);
	MemoryContextSwitchTo(oldcontext);
}

InlineCodeBlockArgs *
clone_inline_args(InlineCodeBlockArgs *args)
{
	InlineCodeBlockArgs *clone;

	clone = create_args(args->numargs);
	memcpy(clone->argtypes, args->argtypes, sizeof(Oid) * args->numargs);
	memcpy(clone->argtypmods, args->argtypmods, sizeof(int32) * args->numargs);
	memcpy(clone->argnames, args->argnames, sizeof(char *) * args->numargs);
	memcpy(clone->argmodes, args->argmodes, sizeof(char) * args->numargs);

	return clone;
}

/*
 * Read parameter values, prepare fcinfo and the row Datum.
 */
static void
read_param_val(PLtsql_execstate *estate, List *params, InlineCodeBlockArgs *args,
			   FunctionCallInfo fcinfo, PLtsql_row *row)
{
	ListCell   *lc;
	bool	   *assigned;
	int			i = 0;
	int			j = 0;
	int			nfields = 0;
	int			n_extra_args = fcinfo->nargs;

	/*
	 * An array to record which parameters have already been given a value
	 */
	assigned = (bool *) palloc0(args->numargs * sizeof(bool));

	fcinfo->nargs += args->numargs;

	foreach(lc, params)
	{
		tsql_exec_param *p;
		Datum		paramval;
		Oid			restype;
		int32		restypmod;
		bool		isnull;

		p = (tsql_exec_param *) lfirst(lc);

		/*
		 * Assign the unnamed parameters according to the input order
		 */
		if (p->name == NULL)
		{
			/* Check if the param's declared mode matches called mode */
			if (!check_spexecutesql_param(&(args->argmodes[i]), p))
				ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
								errmsg("param %d defined as mode %c but received mode %c",
									   i + 1, args->argmodes[i], p->mode)));

			/* Evaluate expression for IN/INOUT param */
			paramval = exec_eval_expr(estate, p->expr, &isnull, &restype, &restypmod);

			/* Insert param info into fcinfo */
			if (isnull)
			{
				fcinfo->args[i + n_extra_args].value = (Datum) 0;
				fcinfo->args[i + n_extra_args].isnull = true;
			}
			else
			{
				/* Do type cast if needed */
				paramval = exec_cast_value(estate, paramval, &isnull, restype, restypmod,
										   args->argtypes[i], args->argtypmods[i]);

				fcinfo->args[i + n_extra_args].value = paramval;
				fcinfo->args[i + n_extra_args].isnull = false;
			}

			/* For OUT params, build row Datum */
			if (p->mode == FUNC_PARAM_INOUT)
				row->varnos[nfields++] = p->varno;

			/* The first i + 1 params have already been assigned */
			assigned[i++] = true;
		}

		/*
		 * Assign the named parameters according to the param name
		 */
		else
		{
			for (j = i; j < args->numargs; j++)
			{
				/* Case insensitive param names can be used. */
				if (pg_strcasecmp(p->name, args->argnames[j]) == 0)
				{
					/* Check if the param's declared mode matches called mode */
					if (!check_spexecutesql_param(&(args->argmodes[j]), p))
						ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
										errmsg("param %s defined as mode %c but received mode %c",
											   p->name, args->argmodes[j], p->mode)));

					/* Evaluate expression for IN/INOUT param */
					paramval = exec_eval_expr(estate, p->expr, &isnull, &restype, &restypmod);

					/* Insert param info into fcinfo */
					if (isnull)
					{
						fcinfo->args[j + n_extra_args].value = (Datum) 0;
						fcinfo->args[j + n_extra_args].isnull = true;
					}
					else
					{
						/* Do type cast if needed */
						paramval = exec_cast_value(estate, paramval, &isnull, restype, restypmod,
												   args->argtypes[j], args->argtypmods[j]);

						fcinfo->args[j + n_extra_args].value = paramval;
						fcinfo->args[j + n_extra_args].isnull = false;
					}

					/* For OUT params, build row Datum */
					if (p->mode == FUNC_PARAM_INOUT)
						row->varnos[nfields++] = p->varno;

					assigned[j] = true;

					break;
				}
				if (j == args->numargs - 1)
					ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
									errmsg("param \"%s\" not defined", p->name)));
			}
		}
	}

	/*
	 * Check if all defined params are assigned
	 */
	for (j = 0; j < args->numargs; j++)
		if (!assigned[j])
			ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("missing argument value for param %d", j)));


	row->nfields = nfields;
}

/*
 * Check the parameter's mode.
 * A parameter can be declared as IN and called as IN.
 * A parameter can also be declared as INOUT and called as IN/INOUT.
 */
static bool
check_spexecutesql_param(char *defmode, tsql_exec_param *p)
{
	if (*defmode == FUNC_PARAM_IN)
	{
		if (p->mode != FUNC_PARAM_IN)
			return false;
	}
	else if (*defmode == FUNC_PARAM_INOUT)
	{
		if (p->mode == FUNC_PARAM_IN)
			*defmode = FUNC_PARAM_IN;
		else if (p->mode != FUNC_PARAM_INOUT)
			return false;
	}
	else
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
						errmsg("unexpected parameter mode %c", *defmode)));

	return true;
}

static int
exec_eval_int(PLtsql_execstate *estate,
			  PLtsql_expr *expr,
			  bool *isNull)
{
	Datum		exprdatum;
	Oid			exprtypeid;
	int32		exprtypmod;

	exprdatum = exec_eval_expr(estate, expr, isNull, &exprtypeid, &exprtypmod);
	exprdatum = exec_cast_value(estate, exprdatum, isNull,
								exprtypeid, exprtypmod,
								INT4OID, -1);
	return DatumGetInt32(exprdatum);
}

static Node *
get_underlying_node_from_implicit_casting(Node *n, NodeTag underlying_nodetype)
{
	FuncExpr   *funcexpr = NULL;

	if (nodeTag(n) == underlying_nodetype)
		return n;

	if (IsA(n, FuncExpr))
		funcexpr = (FuncExpr *) n;
	else if (IsA(n, CoerceToDomain))
	{
		/*
		 * coerce-to-domain can be added before actual casting. It is already
		 * handled and we don't need this to handle output param. ignoring it.
		 */
		CoerceToDomain *c = (CoerceToDomain *) n;

		if (c->coercionformat == COERCE_IMPLICIT_CAST)
			return get_underlying_node_from_implicit_casting((Node *) c->arg, underlying_nodetype);
		else
			return NULL;		/* not an implicit-casting. stop */
	}
	else if (IsA(n, CoerceViaIO))
	{
		/* no casting function. cocerce-via-io used instead */
		CoerceViaIO *c = (CoerceViaIO *) n;

		if (c->coerceformat == COERCE_IMPLICIT_CAST)
			return get_underlying_node_from_implicit_casting((Node *) c->arg, underlying_nodetype);
		else
			return NULL;		/* not an implicit-casting. stop */
	}

	if (!funcexpr)
		return NULL;
	if (funcexpr->funcformat != COERCE_IMPLICIT_CAST)
		return NULL;
	if (funcexpr->args == NULL)
		return NULL;
	/* implicit casting can have 1~3 arguments */
	if (list_length(funcexpr->args) < 1)
		return NULL;
	if (list_length(funcexpr->args) > 3)
		return NULL;

	if (nodeTag(linitial(funcexpr->args)) == underlying_nodetype)
		return linitial(funcexpr->args);

	/*
	 * up to two implict castings are nested consecutively. inner is about
	 * type casting (i.e. int4->numeric) and outer is for typmod handling
	 * (numeric->numeric with different typmod) check one-level more here
	 */
	if (!IsA(linitial(funcexpr->args), FuncExpr))
		return NULL;
	funcexpr = (FuncExpr *) linitial(funcexpr->args);
	if (funcexpr->funcformat != COERCE_IMPLICIT_CAST)
		return NULL;
	if (funcexpr->args == NULL)
		return NULL;
	/* implicit casting can have 1~3 arguments */
	if (list_length(funcexpr->args) < 1)
		return NULL;
	if (list_length(funcexpr->args) > 3)
		return NULL;

	if (nodeTag(linitial(funcexpr->args)) == underlying_nodetype)
		return linitial(funcexpr->args);

	return NULL;
}

static int
exec_stmt_usedb(PLtsql_execstate *estate, PLtsql_stmt_usedb *stmt)
{
	char		message[128];
	char	   *old_db_name;
	int16		old_db_id;
	int16		new_db_id;
	PLExecStateCallStack *top_es_entry;

	if (pltsql_explain_only)
	{
		return exec_stmt_usedb_explain(estate, stmt, false /* shouldRestoreDb */ );
	}
	old_db_name = get_cur_db_name();
	old_db_id = get_cur_db_id();
	new_db_id = get_db_id(stmt->db_name);

	if (!DbidIsValid(new_db_id))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist", stmt->db_name)));

	/* Raise an error if the login does not have access to the database */
	check_session_db_access(stmt->db_name);

	/* Release the session-level shared lock on the old logical db */
	UnlockLogicalDatabaseForSession(old_db_id, ShareLock, false);

	/*
	 * Get a session-level shared lock on the new logical db we are about to
	 * use
	 */
	if (!TryLockLogicalDatabaseForSession(new_db_id, ShareLock))
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Cannot use database \"%s\", failed to obtain lock. "
						"\"%s\" is probably undergoing DDL statements in another session.",
						stmt->db_name, stmt->db_name)));

	set_cur_user_db_and_path(stmt->db_name, false);

	top_es_entry = exec_state_call_stack->next;
	while (top_es_entry != NULL)
	{
		/*
		 * traverse through the estate stack. If the occurrence of execute()
		 * is found in the stack, suppress the database context message and
		 * avoid sending env token and message to user.
		 */
		if (top_es_entry->estate && top_es_entry->estate->err_stmt &&
			(top_es_entry->estate->err_stmt->cmd_type == PLTSQL_STMT_EXEC_BATCH))
			return PLTSQL_RC_OK;
		else
			top_es_entry = top_es_entry->next;
	}

	/*
	 * In case of reset-connection we do not need to send the environment change token.
	 */
	if (!((*pltsql_protocol_plugin_ptr) && (*pltsql_protocol_plugin_ptr)->get_reset_tds_connection_flag()))
	{
		snprintf(message, sizeof(message), "Changed database context to '%s'.", stmt->db_name);
		/* send env change token to user */
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_env_change)
			((*pltsql_protocol_plugin_ptr)->send_env_change) (1, stmt->db_name, old_db_name);
		/* send message to user */
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
			((*pltsql_protocol_plugin_ptr)->send_info) (0, 1, 0, message, 0);
	}
	return PLTSQL_RC_OK;
}

/* This function will change databases to a given target database for use in explain functions
* It will maintain the lock on the initial database and supress any log messages to the user
* otherwise this function will be functionally the same as exec_stmt_usedb
*/
static int
exec_stmt_usedb_explain(PLtsql_execstate *estate, PLtsql_stmt_usedb *stmt, bool shouldRestoreDb)
{
	const char *old_db_name;
	const char *initial_database_name;
	const char *queryText;
	int16		old_db_id;
	int16		new_db_id;
	int16		initial_database_id;

	if (!pltsql_explain_only)
		return PLTSQL_RC_OK;

	old_db_name = get_cur_db_name();
	old_db_id = get_cur_db_id();
	new_db_id = get_db_id(stmt->db_name);

	/* append query information */
	if (!shouldRestoreDb)
	{
		queryText = psprintf("USE DATABASE %s", stmt->db_name);
		append_explain_info(NULL, queryText);
	}

	/* Gather name and id of the original database the user was connected to */
	initial_database_name = get_explain_database();
	if (initial_database_name == NULL)
	{
		set_explain_database(old_db_name);
		initial_database_name = old_db_name;
	}
	initial_database_id = get_db_id(initial_database_name);

	/* error if new db is not valid and restore original db */
	if (!DbidIsValid(new_db_id))
	{
		set_cur_user_db_and_path(initial_database_name, true);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist", stmt->db_name)));

	}
	check_session_db_access(stmt->db_name);

	/*
	 * Release the session-level shared lock on the old logical db if its not
	 * the user's original database
	 */
	if (old_db_id != initial_database_id)
		UnlockLogicalDatabaseForSession(old_db_id, ShareLock, false);

	/*
	 * Get a session-level shared lock on the new logical db we are about to
	 * use.  If Restoring the original DB, its There is no need to reacquire a
	 * lock since we never released the lock in the the initial db
	 */
	if (!TryLockLogicalDatabaseForSession(new_db_id, ShareLock) && !shouldRestoreDb)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Cannot use database \"%s\", failed to obtain lock. "
						"\"%s\" is probably undergoing DDL statements in another session.",
						stmt->db_name, stmt->db_name)));

	set_cur_user_db_and_path(stmt->db_name, false);

	return PLTSQL_RC_OK;
}

static int
exec_stmt_grantdb(PLtsql_execstate *estate, PLtsql_stmt_grantdb *stmt)
{
	char	   *dbname = get_cur_db_name();
	char	   *login = GetUserNameFromId(GetSessionUserId(), false);
	bool		login_is_db_owner;
	Oid			datdba;
	ListCell   *lc;

	/*
	 * If the login is not the db owner or the login is not the member of
	 * sysadmin or securityadmin, then it doesn't have the permission to GRANT/REVOKE.
	 */
	login_is_db_owner = 0 == strncmp(login, get_owner_of_db(dbname), NAMEDATALEN);
	datdba = get_role_oid("sysadmin", false);
	if (!is_member_of_role(GetSessionUserId(), datdba) && !login_is_db_owner
					&& !is_member_of_role(GetSessionUserId(), get_securityadmin_oid()))
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Grantor does not have GRANT permission.")));

	foreach(lc, stmt->grantees)
	{
		char	   *grantee_name = (char *) lfirst(lc);

		if (strcmp(grantee_name, "dbo") == 0 || strcmp(grantee_name, "db_owner") == 0
			|| strcmp(grantee_name, login) == 0)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Cannot grant or revoke permissions to dbo, db_owner or yourself.")));
		if (!stmt->is_grant && strcmp(grantee_name, "guest") == 0
			&& (strcmp(dbname, "master") == 0 || strcmp(dbname, "tempdb") == 0))
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Cannot disable access to the guest user in master or tempdb.")));
		/*
		 * Adding entries for user_can_connect might involve TOAST table access, so ensure we
		 * have a valid snapshot.
		 */
		PushActiveSnapshot(GetTransactionSnapshot());
		alter_user_can_connect(stmt->is_grant, grantee_name, dbname);
		PopActiveSnapshot();
	}
	return PLTSQL_RC_OK;
}

bool called_from_tsql_insert_exec()
{
	if (sql_dialect != SQL_DIALECT_TSQL)
		return false;
	return called_from_tsql_insert_execute;
}

/*
 * For naked SELECT stmt in INSERT ... EXECUTE, instead of pushing the result to
 * the client, we accumulate the result in estate->tuple_store (similar to
 * exec_stmt_return_query). Finally the EXECUTE stmt will return the result to
 * the INSERT stmt as rows to insert.
 */
static int
exec_stmt_insert_execute_select(PLtsql_execstate *estate, PLtsql_expr *query)
{
	Portal		portal;
	uint64		processed = 0;
	TupleConversionMap *tupmap;
	MemoryContext oldcontext;

	if (estate->tuple_store == NULL)
		exec_init_tuple_store(estate);

	Assert(query != NULL);
	exec_run_select(estate, query, &portal);

	/* Use eval_mcontext for tuple conversion work */
	oldcontext = MemoryContextSwitchTo(get_eval_mcontext(estate));

	called_from_tsql_insert_execute = true;
	tupmap = convert_tuples_by_position(portal->tupDesc,
										estate->tuple_store_desc,
										gettext_noop("structure of query does not match function result type"));
	called_from_tsql_insert_execute = false;
	while (true)
	{
		uint64		i;

		SPI_cursor_fetch(portal, true, 50);

		/* SPI will have changed CurrentMemoryContext */
		MemoryContextSwitchTo(get_eval_mcontext(estate));

		if (SPI_processed == 0)
			break;

		for (i = 0; i < SPI_processed; i++)
		{
			HeapTuple	tuple = SPI_tuptable->vals[i];

			if (tupmap)
			{
				called_from_tsql_insert_execute = true;
				tuple = execute_attr_map_tuple(tuple, tupmap);
				called_from_tsql_insert_execute = false;
			}
			tuplestore_puttuple(estate->tuple_store, tuple);
			if (tupmap)
				heap_freetuple(tuple);
			processed++;
		}

		SPI_freetuptable(SPI_tuptable);
	}

	SPI_freetuptable(SPI_tuptable);
	SPI_cursor_close(portal);

	MemoryContextSwitchTo(oldcontext);
	exec_eval_cleanup(estate);

	return PLTSQL_RC_OK;
}

int
exec_stmt_insert_bulk(PLtsql_execstate *estate, PLtsql_stmt_insert_bulk *stmt)
{
	MemoryContext oldContext;
	Oid			schema_oid = InvalidOid;

	oldContext = MemoryContextSwitchTo(TopMemoryContext);

	/*
	 * We use a global variable so that we do not need to call BeginBulkCopy
	 * in case of implicit batching, which saves time.
	 */
	cstmt = (BulkCopyStmt *) palloc0(sizeof(BulkCopyStmt));
	cstmt->relation = makeNode(RangeVar);
	cstmt->attlist = NIL;
	cstmt->cur_batch_num = 1;

	if (!stmt->db_name || stmt->db_name[0] == (char) '\0')
		stmt->db_name = get_cur_db_name();
	if (stmt->schema_name && stmt->db_name)
	{
		cstmt->relation->schemaname = get_physical_schema_name(stmt->db_name,
															   stmt->schema_name);
		schema_oid = LookupExplicitNamespace(cstmt->relation->schemaname, true);
		if (!OidIsValid(schema_oid))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_SCHEMA),
					 errmsg("schema \"%s\" does not exist",
							stmt->schema_name)));
	}

	/* save the table name for the next Bulk load Request */
	cstmt->relation->relname = pstrdup(stmt->table_name);

	/*
	 * if columns to be inserted into are explicitly mentioned then update the
	 * table name with them
	 */
	if (stmt->column_refs)
	{
		ListCell   *lc;

		foreach(lc, stmt->column_refs)
		{
			char	   *temp = pstrdup((char *) lfirst(lc));

			cstmt->attlist = lappend(cstmt->attlist, temp);
		}
	}

	MemoryContextSwitchTo(oldContext);

	/* Set the Insert Bulk Options for the session. */
	if (stmt->rows_per_batch)
	{
		prev_insert_bulk_rows_per_batch = insert_bulk_rows_per_batch;
		insert_bulk_rows_per_batch = atoi(stmt->rows_per_batch);
	}
	if (stmt->kilobytes_per_batch)
	{
		prev_insert_bulk_kilobytes_per_batch = insert_bulk_kilobytes_per_batch;
		insert_bulk_kilobytes_per_batch = atoi(stmt->kilobytes_per_batch);
	}
	if (stmt->keep_nulls)
	{
		prev_insert_bulk_keep_nulls = insert_bulk_keep_nulls;
		insert_bulk_keep_nulls = true;
	}
	if (stmt->check_constraints)
	{
		prev_insert_bulk_check_constraints = insert_bulk_check_constraints;
		insert_bulk_check_constraints = true;
	}
	return PLTSQL_RC_OK;
}

int exec_stmt_dbcc(PLtsql_execstate *estate, PLtsql_stmt_dbcc *stmt)
{
	switch (stmt->dbcc_stmt_type)
	{
		case PLTSQL_DBCC_CHECKIDENT:
			exec_stmt_dbcc_checkident(stmt);
			break;
		default:
			Assert(0);
	}
	return PLTSQL_RC_OK;
}

void exec_stmt_dbcc_checkident(PLtsql_stmt_dbcc *stmt)
{
	struct	dbcc_checkident dbcc_stmt = stmt->dbcc_stmt_data.dbcc_checkident;
	Relation	rel;
	TupleDesc	tupdesc;
	char		*db_name = NULL;
	char		*max_identity_value_str = NULL;
	char		*query = NULL;
	char		*attname;
	char		*token;
	const char	*schema_name;
	char		*nsp_name;
	const char	*user;
	const char	*login;
	int64		max_identity_value = 0;
	int64		cur_identity_value = 0;
	int		attnum;
	int		rc = 0;
	int64		reseed_value = 0;
	Oid		nsp_oid;
	Oid		table_oid;
	Oid		seqid = InvalidOid;
	Oid		current_user_id = GetUserId();
	volatile bool	cur_value_is_null = true;
	bool		login_is_db_owner;
	StringInfoData msg;
	bool		is_float_value;
	bool		is_cross_db = false;


	if(dbcc_stmt.new_reseed_value)
	{
		/* If float value is passed as reseed_value, only part before decimal is considered */
		is_float_value = strchr(dbcc_stmt.new_reseed_value, '.') != NULL;

		if (is_float_value)
		{
			if (dbcc_stmt.new_reseed_value[0] == '.' || 
				(dbcc_stmt.new_reseed_value[0] == '-' && dbcc_stmt.new_reseed_value[1] == '.'))
				reseed_value = 0;
			else
			{
				token = strtok(dbcc_stmt.new_reseed_value, ".");
				reseed_value = pg_strtoint64(token);
				pfree(token);
			}
		}
		else
			reseed_value = pg_strtoint64(dbcc_stmt.new_reseed_value);
	}
	
	db_name = get_cur_db_name();
	if (dbcc_stmt.db_name)
	{
		if (!DbidIsValid(get_db_id(dbcc_stmt.db_name)))
		{
			ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_DATABASE),
				errmsg("database \"%s\" does not exist", dbcc_stmt.db_name)));
		}
		if (pg_strncasecmp(db_name, dbcc_stmt.db_name, NAMEDATALEN) != 0)
		{
			is_cross_db = true;
			pfree(db_name);
			db_name = pstrdup(dbcc_stmt.db_name);
		}
	}

	user = get_user_for_database(db_name);
	login_is_db_owner = 0 == strncmp(GetUserNameFromId(GetSessionUserId(), false),
										get_owner_of_db(db_name), NAMEDATALEN);

	/* Raise an error if the login does not have access to the database */
	if(is_cross_db)
	{
		if (user)
			SetCurrentRoleId(GetSessionUserId(), false);
		else
		{
			login = GetUserNameFromId(GetSessionUserId(), false);
			pfree(db_name);
			ereport(ERROR,
                    	(errcode(ERRCODE_UNDEFINED_DATABASE),
                    		errmsg("The server principal \"%s\" is not able to access "
                            	"the database \"%s\" under the current security context",
                           	 login, dbcc_stmt.db_name)));
		}
	}

	/* get physical schema name from logical schema name */
	if (dbcc_stmt.schema_name)
	{
		schema_name = dbcc_stmt.schema_name;
		nsp_name = get_physical_schema_name(db_name, dbcc_stmt.schema_name);
	}
	else
	{
		/* 
		 * If schema_name is not provided, find default schema for current user
		 * and get physical schema name
		 */
		char		*guest_role_name = get_guest_role_name(db_name);
		char		*dbo_role_name = get_dbo_role_name(db_name);
		
		/* user will never be null here as cross-db calls are already handled */
		Assert(user != NULL);

		schema_name = get_authid_user_ext_schema_name((const char *) db_name, user);
		if ((dbo_role_name && strcmp(user, dbo_role_name) == 0))
		{
			nsp_name = get_dbo_schema_name(db_name);
		}
		else if ((guest_role_name && strcmp(user, guest_role_name) == 0))
		{
			nsp_name = get_guest_schema_name(db_name);
		}
		else
		{
			nsp_name = get_physical_schema_name(db_name, schema_name);
		}

		pfree(guest_role_name);
		pfree(dbo_role_name);
	}
	pfree(db_name);

	/*
	 * get schema oid from physical schema name, it will return InvalidOid if
	 * user don't have lookup access
	 */
	nsp_oid = get_namespace_oid(nsp_name, false);

	if(!OidIsValid(nsp_oid))
	{
		ereport(ERROR,
		(errcode(ERRCODE_UNDEFINED_SCHEMA),
			errmsg("schema \"%s\" does not exist", schema_name)));
	}

	/* Permission check */
	if (!(object_ownercheck(NamespaceRelationId, nsp_oid, GetUserId()) ||
			has_privs_of_role(GetSessionUserId(), get_role_oid("sysadmin", false)) ||
				login_is_db_owner))
		aclcheck_error(ACLCHECK_NOT_OWNER, OBJECT_SCHEMA, nsp_name);

	table_oid = get_relname_relid(dbcc_stmt.table_name, nsp_oid);
	if(!OidIsValid(table_oid))
	{
		ereport(ERROR,
		(errcode(ERRCODE_UNDEFINED_TABLE),
			errmsg("relation \"%s\" does not exist", dbcc_stmt.table_name)));
	}

	rel = RelationIdGetRelation(table_oid);
	tupdesc = RelationGetDescr(rel);

	/* Find Identity column in table and associated sequence */
	for (attnum = 0; attnum < tupdesc->natts; attnum++)
	{
		Form_pg_attribute attr = TupleDescAttr(tupdesc, attnum);

		if (attr->attidentity)
		{
			attname = NameStr(attr->attname);
			seqid = getIdentitySequence(rel, attnum + 1, false);
			break;
		}
	}

	RelationClose(rel);

	if (!OidIsValid(seqid))
	{
		ereport(ERROR,
		(errcode(ERRCODE_UNDEFINED_COLUMN),
			errmsg("'%s.%s' does not contain an identity column.",
				nsp_name, dbcc_stmt.table_name)));
	}
	
	pfree(nsp_name);

	PG_TRY();
	{
		cur_identity_value = DirectFunctionCall1(pg_sequence_last_value,
									ObjectIdGetDatum(seqid));
		cur_value_is_null = false;
	}
	PG_CATCH();
	{
		FlushErrorState();
	}
	PG_END_TRY();

	if (!dbcc_stmt.no_infomsgs)
		initStringInfo(&msg);

	PG_TRY();
	{
		/*
		 * Acquiring an AccessExclusiveLock on the table is essential when
		 * reseeding the identity current value to new_ressed_value to
		 * ensure concurrency control.
		 */
		if(dbcc_stmt.new_reseed_value)
		{
			LockRelationOid(table_oid, AccessExclusiveLock);
		}
		else
		{
			LockRelationOid(table_oid, ShareLock);
		}

		/* 
		 * If cur_value_is_null is true, then the function pg_sequence_last_value
		 * has returned a NULL value, which means either no rows have been 
		 * inserted into the table yet, or TRUNCATE TABLE command has been used
		 * to delete all rows. In this case, after DBCC CHECKIDENT the next
		 * row inserted will have new_reseed_value as the identity value.
		 */
		if (cur_value_is_null)
		{
			if (dbcc_stmt.new_reseed_value)
			{
				if (!dbcc_stmt.no_infomsgs)
					appendStringInfo(&msg, "Checking identity information: current identity value 'NULL'.\n");
				DirectFunctionCall3(setval3_oid,
					ObjectIdGetDatum(seqid),
					Int64GetDatum(reseed_value),
					BoolGetDatum(false));
			}
			else
			{
				if (!dbcc_stmt.no_infomsgs)
					appendStringInfo(&msg, "Checking identity information: current identity value 'NULL', current column value 'NULL'.\n");
			}
		}

		else
		{
			if (dbcc_stmt.new_reseed_value)
			{
				/* 
				* Print informational messages if NO_INFOMSGS is not passed as a
				* DBCC command option.
				*/
				if (!dbcc_stmt.no_infomsgs)
					appendStringInfo(&msg, "Checking identity information: current identity value '%ld'.\n", cur_identity_value);

				DirectFunctionCall2(setval_oid,
					ObjectIdGetDatum(seqid),
					Int64GetDatum(reseed_value));
			}
			else
			{	
				SPI_connect();
				query = psprintf("SELECT MAX(%s) FROM %s.%s", attname,
								schema_name, dbcc_stmt.table_name);
				rc = SPI_execute(query, true, 0);

				if (rc != SPI_OK_SELECT)
					elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

				max_identity_value_str = SPI_getvalue(SPI_tuptable->vals[0],
										SPI_tuptable->tupdesc, 1);
				
				SPI_freetuptable(SPI_tuptable);
				
				if(max_identity_value_str)
					max_identity_value = pg_strtoint64(max_identity_value_str);

				if (!dbcc_stmt.no_infomsgs)
				{
					appendStringInfo(&msg, "Checking identity information: current identity value '%ld', current column value '%s'.\n",
														cur_identity_value,
														max_identity_value_str ? max_identity_value_str : "NULL");
				}

				/*
				* RESEED option only resets the identity column value if the 
				* current identity value for a table is less than the maximum 
				* identity value stored in the identity column.
				*/
				if (dbcc_stmt.is_reseed && max_identity_value_str &&
					cur_identity_value < max_identity_value)
				{
					DirectFunctionCall2(setval_oid,
						ObjectIdGetDatum(seqid),
						Int64GetDatum(max_identity_value));
				}
			}
		}
		
		if (is_cross_db)
            		SetCurrentRoleId(current_user_id, false);
	}
	PG_CATCH();
	{
		if (is_cross_db)
           		 SetCurrentRoleId(current_user_id, false);
		
		if(query)
			pfree(query);
		if (max_identity_value_str)
			pfree(max_identity_value_str);

		if(rc != 0)
		{ 
			SPI_finish();
			/* running 'SELECT MAX' query above holds a AccessShareLock on table, we want to unlock that as well */
			UnlockRelationOid(table_oid, AccessShareLock);
		}
		if(!dbcc_stmt.new_reseed_value)
		{
			UnlockRelationOid(table_oid, ShareLock);
		}
		if(msg.data)
		{
			pfree(msg.data);
		}

		PG_RE_THROW();
	}
	PG_END_TRY();
	
	if(query)
		pfree(query);
	if (max_identity_value_str)
		pfree(max_identity_value_str);
	if(rc != 0)
	{
		SPI_finish();
		/* running 'SELECT MAX' query above holds a AccessShareLock on table, we want to unlock that as well */
		UnlockRelationOid(table_oid, AccessShareLock);
	}
	
	if(!dbcc_stmt.new_reseed_value)
	{
		UnlockRelationOid(table_oid, ShareLock);
	}

	if (!dbcc_stmt.no_infomsgs)
	{
		appendStringInfo(&msg, "DBCC execution completed. If DBCC printed error messages, contact your system administrator.");
		/* send message to user */
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
			((*pltsql_protocol_plugin_ptr)->send_info) (0, 1, 0, msg.data, 0);
		pfree(msg.data);
	}

}


uint64
execute_bulk_load_insert(int ncol, int nrow,
						 Datum *Values, bool *Nulls)
{
	uint64		retValue = -1;
	Snapshot	snap;

	/*
	 * Bulk Copy can be triggered with 0 rows. We can also use this to cleanup
	 * after all rows are inserted.
	 */
	if (nrow == 0 && ncol == 0)
	{
		/* Cleanup all the pointers. */
		if (cstmt)
		{
			EndBulkCopy(cstmt->cstate, false);
			if (cstmt->attlist)
				list_free_deep(cstmt->attlist);
			if (cstmt->relation)
			{
				if (cstmt->relation->schemaname)
					pfree(cstmt->relation->schemaname);
				if (cstmt->relation->relname)
					pfree(cstmt->relation->relname);
				pfree(cstmt->relation);
			}
			pfree(cstmt);
			cstmt = NULL;
		}

		/* Reset Insert-Bulk Options. */
		insert_bulk_keep_nulls = prev_insert_bulk_keep_nulls;
		insert_bulk_check_constraints = prev_insert_bulk_check_constraints;
		insert_bulk_rows_per_batch = prev_insert_bulk_rows_per_batch;
		insert_bulk_kilobytes_per_batch = prev_insert_bulk_kilobytes_per_batch;

		return 0;
	}


	PG_TRY();
	{
		cstmt->nrow = nrow;
		cstmt->ncol = ncol;
		cstmt->Values = Values;
		cstmt->Nulls = Nulls;

		snap = GetTransactionSnapshot();
		PushActiveSnapshot(snap);

		BulkCopy(cstmt, &retValue);

		PopActiveSnapshot();
		cstmt->cur_batch_num++;
	}
	PG_CATCH();
	{
		/*
		 * In an error condition, the caller calls the function again to do
		 * the cleanup.
		 */
		/* Cleanup cstate. */
		EndBulkCopy(cstmt->cstate, true);

		if (ActiveSnapshotSet() && GetActiveSnapshot() == snap)
			PopActiveSnapshot();

		/* Reset Insert-Bulk Options. */
		insert_bulk_keep_nulls = prev_insert_bulk_keep_nulls;
		insert_bulk_check_constraints = prev_insert_bulk_check_constraints;
		insert_bulk_rows_per_batch = prev_insert_bulk_rows_per_batch;
		insert_bulk_kilobytes_per_batch = prev_insert_bulk_kilobytes_per_batch;

		PG_RE_THROW();
	}
	PG_END_TRY();

	return retValue;
}

int
execute_plan_and_push_result(PLtsql_execstate *estate, PLtsql_expr *expr, ParamListInfo paramLI)
{
	Portal		portal;
	bool		success;
	uint64		processed = 0;
	DestReceiver *receiver;
	QueryCompletion qc;

	Assert(expr->plan != NULL); /* should be prepared already */
	portal = SPI_cursor_open_with_paramlist(NULL, expr->plan, paramLI, estate->readonly_func);

	if (portal == NULL)
		elog(ERROR, "could not open implicit cursor for query \"%s\": %s",
			 expr->query, SPI_result_code_string(SPI_result));

	if (pltsql_explain_only)
	{
		receiver = None_Receiver;
	}
	else if (pltsql_insert_exec_active())
	{
		/*
		 * INSERT EXEC context is active - redirect results to temp table
		 * instead of sending to client.
		 */
		Oid temp_table_oid = pltsql_get_insert_exec_temp_table_oid();
		receiver = CreateInsertExecDestReceiver(temp_table_oid);
		receiver->rStartup(receiver, CMD_SELECT, portal->tupDesc);
	}
	else
	{
		receiver = CreateDestReceiver(DestRemote);
		SetRemoteDestReceiverParams(receiver, portal);
	}

	success = PortalRun(portal,
						FETCH_ALL,
						true,
						true,
						receiver,
						receiver,
						&qc);

	if (success)
	{
		processed = portal->portalPos;
		estate->eval_processed = processed;
		exec_set_rowcount(processed);
		exec_set_found(estate, processed != 0);
	}

	receiver->rDestroy(receiver);
	exec_eval_cleanup(estate);
	SPI_cursor_close(portal);

	return SPI_OK_SELECT;
}

static void
get_param_mode(List *params, int paramno, char **modes)
{
	ListCell   *lc;
	int			i = 0;

	if (paramno == 0)
	{
		*modes = NULL;
		return;
	}

	Assert(paramno == list_length(params));
	*modes = (char *) palloc(paramno * sizeof(char));

	foreach(lc, params)
	{
		tsql_exec_param *p;

		p = (tsql_exec_param *) lfirst(lc);
		(*modes)[i++] = p->mode;
	}
}

int
get_insert_bulk_rows_per_batch()
{
	return insert_bulk_rows_per_batch;
}

int
get_insert_bulk_kilobytes_per_batch()
{
	return insert_bulk_kilobytes_per_batch;
}

static int
exec_stmt_grantschema(PLtsql_execstate *estate, PLtsql_stmt_grantschema *stmt)
{
	char		*dbname = get_cur_db_name();
	char		*login = GetUserNameFromId(GetSessionUserId(), false);
	bool		login_is_db_owner;
	char		*schema_name;
	ListCell	*lc;
	Oid		schemaOid;
	char		*user = GetUserNameFromId(GetUserId(), false);
	const char	*db_owner = get_owner_of_db(dbname);

	login_is_db_owner = 0 == strcmp(login, db_owner);
	schema_name = get_physical_schema_name(dbname, stmt->schema_name);

	if(schema_name)
	{
		/* Return immediately for shared schema. */
		if(is_shared_schema(schema_name))
			return PLTSQL_RC_OK;

		schemaOid = LookupExplicitNamespace(schema_name, false);
	}
	else
	{
		ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_SCHEMA),
					 errmsg("An object or column name is missing or empty. For SELECT INTO statements, verify each column has a name. For other statements, look for empty alias names. Aliases defined as \"\" or [] are not allowed. Change the alias to a valid name.")));
	}

	foreach(lc, stmt->grantees)
	{
		int i;
		char	*rolname = NULL;
		char	*grantee_name = (char *) lfirst(lc);
		Oid	role_oid;
		bool	is_public = 0 == strcmp(grantee_name, PUBLIC_ROLE_NAME);
		if (!is_public)
			rolname	= get_physical_user_name(dbname, grantee_name, false, true);
		else
			rolname = pstrdup(PUBLIC_ROLE_NAME);
		role_oid = get_role_oid(rolname, true);

		if (!is_public && !OidIsValid(role_oid))
		{
			/* sys or information_schema roles should throw an error. */
			if ((strcmp(grantee_name, "sys") == 0) || (strcmp(grantee_name, "information_schema") == 0))
				ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
						errmsg("Cannot grant, deny, or revoke permissions to sa, dbo, entity owner, information_schema, sys, or yourself.")));
			else
				ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
						errmsg("Cannot find the principal '%s', because it does not exist or you do not have permission.", grantee_name)));
		}

		if ((strcmp(rolname, user) == 0) || (!is_public && object_ownercheck(NamespaceRelationId, schemaOid, role_oid)) || is_member_of_role(role_oid, get_sysadmin_oid()))
			ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					errmsg("Cannot grant, deny, or revoke permissions to sa, dbo, entity owner, information_schema, sys, or yourself.")));

		/* Special database roles should throw an error. */
		if (IS_FIXED_DB_PRINCIPAL(grantee_name))
			ereport(ERROR, (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				errmsg("Cannot grant, deny or revoke permissions to or from special roles.")));

		/*
		 * If the login is not the db owner or the login is not the member of
		 * sysadmin or login is not the schema owner,
		 * or current_user is not member of db_securityadmin fixed role
		 * then it doesn't have the permission to GRANT/REVOKE.
		 */
		if (!is_member_of_role(GetSessionUserId(), get_sysadmin_oid()) &&
			!login_is_db_owner &&
			!object_ownercheck(NamespaceRelationId, schemaOid, GetUserId()) &&
			!has_privs_of_role(GetUserId(), get_db_securityadmin_oid(dbname, false)))
			ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					errmsg("Cannot find the schema \"%s\", because it does not exist or you do not have permission.", stmt->schema_name)));

		/*
		 * Executing GRANT ON SCHEMA might involve TOAST table access, so ensure we
		 * have a valid snapshot.
		 */
		PushActiveSnapshot(GetTransactionSnapshot());

		/* Execute the GRANT SCHEMA subcommands. */
		for (i = 0; i < NUMBER_OF_PERMISSIONS; i++)
		{
			if (stmt->privileges & permissions[i])
				exec_grantschema_subcmds(schema_name, rolname, stmt->is_grant, stmt->with_grant_option, permissions[i]);
		}

		if (stmt->is_grant)
		{
			/* For GRANT statement, add or update privileges in the catalog. */
			add_or_update_object_in_bbf_schema(stmt->schema_name, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, stmt->privileges, rolname, OBJ_SCHEMA, true, NULL);
		}
		else
		{
			/* For REVOKE statement, update privileges in the catalog. */
			if (privilege_exists_in_bbf_schema_permissions(stmt->schema_name, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, rolname, OBJ_SCHEMA, INVALID_PERMISSION))
			{
				/* If any object in the schema has the OBJECT level permission. Then, internally grant that permission back. */
				for (i = 0; i < NUMBER_OF_PERMISSIONS; i++)
				{
					if (stmt->privileges & permissions[i])
						grant_perms_to_objects_in_schema(stmt->schema_name, permissions[i], rolname);
				}
				update_privileges_of_object(stmt->schema_name, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, stmt->privileges, rolname, OBJ_SCHEMA, false);
			}
		}
		PopActiveSnapshot();
		pfree(rolname);
	}
	pfree(user);
	pfree(schema_name);
	pfree(dbname);
	pfree(login);
	return PLTSQL_RC_OK;
}

/*
 * ALTER AUTHORIZATION ON DATABASE::dbname TO loginname
 */
static int
exec_stmt_change_dbowner(PLtsql_execstate *estate, PLtsql_stmt_change_dbowner *stmt)
{
	char *new_owner_is_user;
	Oid 		save_userid;
	int 		save_sec_context;
	
	/* Verify target database exists. */
	if (!DbidIsValid(get_db_id(stmt->db_name)))
	{
		ereport(ERROR, (errcode(ERRCODE_UNDEFINED_DATABASE),	
						errmsg("Cannot find the database '%s', because it does not exist or you do not have permission.", stmt->db_name)));
	}

	/* Throw error if it's a Babelfish fixed server role or "bbf_role_admin". */
	if (IS_BBF_FIXED_SERVER_ROLE(stmt->new_owner_name) || IS_ROLENAME_BABELFISHROLEADMIN(stmt->new_owner_name))
	{
		ereport(ERROR, (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
						errmsg("An entity of type database cannot be owned by a role, a group, an approle, or by principals mapped to certificates or asymmetric keys.")));
	}

	/* Verify new owner exists as a login. */
	if (!is_login_name(stmt->new_owner_name))
	{
		ereport(ERROR, (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
						errmsg("Cannot find the principal '%s', because it does not exist or you do not have permission.", stmt->new_owner_name)));
	}
	
	/* T-SQL allows granting ownership to yourself when you are owner already, even without having sysadmin role. */
	if (get_role_oid(stmt->new_owner_name, true) == GetSessionUserId())  // Granting ownership to myself?
	{
		/* Is the current login already DB owner? */
		if (get_role_oid(get_owner_of_db(stmt->db_name), true) == GetSessionUserId())
		{
			/*
			 * Update the owner of a database might involve TOAST table access, so ensure we
			 * have a valid snapshot.
			 */
			PushActiveSnapshot(GetTransactionSnapshot());
			/* Current login is DB owner, so perform the update */
			update_db_owner(stmt->new_owner_name, stmt->db_name);
			PopActiveSnapshot();
			return PLTSQL_RC_OK;	
		}			
	}		

	/* 
	 * The executing login must have sysadmin role: even when the current session is the owner, but has no sysadmin role, 
	 * T-SQL does not allow the owner to grant ownership to another login -- not even to 'sa'.
	 */
	if (!has_privs_of_role(GetSessionUserId(), get_role_oid("sysadmin", false)))
	{
		ereport(ERROR, (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
						errmsg("Cannot find the principal '%s', because it does not exist or you do not have permission.", stmt->new_owner_name)));
	}			
	
	/* The new owner cannot be a user in the database already (but 'guest' user is fine). */
	new_owner_is_user = get_authid_user_ext_physical_name(stmt->db_name, stmt->new_owner_name);
	if (!new_owner_is_user) 
	{
		// OK to proceed
	}
	else if (new_owner_is_user && pg_strcasecmp(new_owner_is_user, "guest") == 0)
	{
		// OK to proceed		
	}
	else
	{
		ereport(ERROR, (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
						errmsg("The proposed new database owner is already a user or aliased in the database.")));				
	}

	/* Save the previous user to be restored after granting dbo role to the login. */
	GetUserIdAndSecContext(&save_userid, &save_sec_context);

	PG_TRY();
	{
		/*
		* Set current user to bbf_role_admin to grant roles.
		*/
		SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
		
		/* Revoke dbo role from the previous owner */
		grant_revoke_role_to_login(get_owner_of_db(stmt->db_name), get_dbo_role_name(stmt->db_name), NULL, false);

		/* Grant dbo role to the new owner */
		grant_revoke_role_to_login(stmt->new_owner_name, get_dbo_role_name(stmt->db_name), NULL, true);

		/*
		 * Update the owner of a database might involve TOAST table access, so ensure we
		 * have a valid snapshot.
		 */
		PushActiveSnapshot(GetTransactionSnapshot());
		update_db_owner(stmt->new_owner_name, stmt->db_name);
		PopActiveSnapshot();
	}
	PG_FINALLY();
	{
		SetUserIdAndSecContext(save_userid, save_sec_context);
	}
	PG_END_TRY();
	return PLTSQL_RC_OK;
}

static int
exec_stmt_alter_db(PLtsql_execstate *estate, PLtsql_stmt_alter_db *stmt)
{
	/* Alter database is not allowed inside a transaction. */
	PreventInTransactionBlock(true, "ALTER DATABASE");
	/*
	 * Executing RENAME DATABASE might involve TOAST table access, so ensure we
	 * have a valid snapshot.
	 */
	PushActiveSnapshot(GetTransactionSnapshot());

	/*
	 * Currently Babelfish only support rename, when we extend
	 * the support at that time we can add a boolean to the stmt
	 * to identify for rename and conditionally call rename_tsql_db
	 */
	rename_tsql_db(stmt->old_db_name, stmt->new_db_name);
	PopActiveSnapshot();
	return PLTSQL_RC_OK;
}

static int
exec_stmt_fulltextindex(PLtsql_execstate *estate, PLtsql_stmt_fulltextindex *stmt)
{
	char		*table_name;
	char		*ft_index_name;
	char		*query_str;
	char		*old_ft_index_name;	// existing fulltext index name
	char		*uniq_index_name;
	const char	*schema_name;
	Oid			schemaOid;
	Oid			relid;
	List		*column_name;
	char	    *dbname = get_cur_db_name();
	char		*login = GetUserNameFromId(GetSessionUserId(), false);
	Oid			datdba;
	bool		login_is_db_owner;
	bool		is_create;
	List		*res;
	Node	   	*res_stmt;
	PlannedStmt *wrapper;

	Assert(stmt->schema_name != NULL);

	/*
	 * If the login is not the db owner or the login is not the member of
	 * sysadmin or login is not the schema owner, then it doesn't have the permission to CREATE/DROP FULLTEXT INDEX.
	 */
	login_is_db_owner = 0 == strncmp(login, get_owner_of_db(dbname), NAMEDATALEN);
	datdba = get_role_oid("sysadmin", false);
	schema_name = gen_schema_name_for_fulltext_index((char *)stmt->schema_name);
	schemaOid = LookupExplicitNamespace(schema_name, true);						
	table_name = stmt->table_name;
	is_create = stmt->is_create;

	// Check if schema exists
	if (!OidIsValid(schemaOid))
		ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_SCHEMA),
				errmsg("schema \"%s\" does not exist",
					stmt->schema_name)));

	// Check if the user has necessary permissions for CREATE/DROP FULLTEXT INDEX
	if (!is_member_of_role(GetSessionUserId(), datdba) && !login_is_db_owner && !object_ownercheck(NamespaceRelationId, schemaOid, GetUserId()))
	{
		const char *error_msg = is_create ? "A default full-text catalog does not exist in the database or user does not have permission to perform this action" : "Cannot drop the full-text index, because it does not exist or you do not have permission";
    	ereport(ERROR, 
			(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE), 
				errmsg("%s", error_msg)));	
	}

	relid = get_relname_relid((const char *) table_name, schemaOid);

	// Check if table exists
	if (!OidIsValid(relid))
		ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_TABLE),
				errmsg("relation \"%s\" does not exist",
					table_name)));

	// Get the existing fulltext index name
	old_ft_index_name = get_fulltext_index_name(relid, table_name);

	if (is_create)
	{
		uniq_index_name = construct_unique_index_name((char *) stmt->index_name, table_name);
		if(is_unique_index(relid, (const char *) uniq_index_name) || is_unique_index(relid, (const char *)stmt->index_name))
		{
			column_name = stmt->column_name;
			ft_index_name = construct_unique_index_name("ft_index", table_name);
			if (old_ft_index_name)
				ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
						errmsg("A full-text index for table or indexed view \"%s\" has already been created.",
							table_name)));
			else
				query_str = gen_createfulltextindex_cmds(table_name, schema_name, column_name, ft_index_name);
		}
		else
			ereport(ERROR,
				(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					errmsg("'\"%s\"' is not a valid index to enforce a full-text search key. A full-text search key must be a unique, non-nullable, single-column index which is not offline, is not defined on a non-deterministic or imprecise nonpersisted computed column, does not have a filter, and has maximum size of 900 bytes. Choose another index for the full-text key.",
						stmt->index_name)));
	}
	else
	{
		if (old_ft_index_name)					
			query_str = gen_dropfulltextindex_cmds(old_ft_index_name, schema_name);
		else
			ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
					errmsg("Table or indexed view \"%s\" does not have a full-text index or user does not have permission to perform this action.",
						table_name))); 
	}

	/* The above query will be
	 * executed using ProcessUtility()
	 */
	res = raw_parser(query_str, RAW_PARSE_DEFAULT);
	res_stmt = ((RawStmt *) linitial(res))->stmt;

	/* need to make a wrapper PlannedStmt */
	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = res_stmt;
	wrapper->stmt_location = 0;
	wrapper->stmt_len = 1;

	/* do this step */
	ProcessUtility(wrapper,
				is_create ? CREATE_FULLTEXT_INDEX : DELETE_FULLTEXT_INDEX,
				false,
				PROCESS_UTILITY_QUERY,
				NULL,
				NULL,
				None_Receiver,
				NULL);

	/* make sure later steps can see the object created here */
	CommandCounterIncrement();

	return PLTSQL_RC_OK;
}

/*
 * tsql_compare_values
 *		Note: This function is used to sort the values in the array.
 *		It compare two datum values using the function oid of comparator provided in arg,
 *		it also sets the contains_duplicate flag in the context if duplicate
 *		values are found.
 *		Returns -1 if a < b, 1 if a > b and 0 if a == b.
 */
int
tsql_compare_values(const void *a, const void *b, void *arg)
{
	Datum		*da = (Datum *) a;
	Datum		*db = (Datum *) b;
	int		result;

	tsql_compare_context *cxt = (tsql_compare_context *) arg;

	result = DatumGetInt32(OidFunctionCall2Coll(cxt->function_oid, cxt->colloid, *da, *db));
	if (result == 0)
		cxt->contains_duplicate = true;
	return result;
}

/*
 * check_create_or_drop_permission_for_partition_specifier
 *	Checks if the current user has permission to create or drop a partition 
 *	function or partition scheme. It allows only those logins that is either 
 *	db owner or member of sysadmin.
 */
static void
check_create_or_drop_permission_for_partition_specifier(const char *name, bool is_create, bool is_function)
{
	char		*dbname = get_cur_db_name();
	Oid		session_user_id = GetSessionUserId();
	char		*login = GetUserNameFromId(session_user_id, false);
	bool		login_is_db_owner = false;

	if (strncmp(login, get_owner_of_db(dbname), NAMEDATALEN) == 0)
		login_is_db_owner = true;

	if (!login_is_db_owner && !is_member_of_role(session_user_id, get_role_oid("sysadmin", false)) &&
		!has_privs_of_role(GetUserId(), get_db_ddladmin_oid(dbname, false)))
	{
		if (is_create)
			ereport(ERROR, 
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE), 
					errmsg("User does not have permission to perform this action.")));
		else
			ereport(ERROR, 
				(errcode(ERRCODE_UNDEFINED_OBJECT), 
					errmsg("Cannot drop the partition %s '%s', because it does not exist or you do not have permission.", 
							(is_function? "function": "scheme"), name)));
	}

	pfree(dbname);
	pfree(login);
}

/*
 * exec_stmt_partition_scheme
 * 	 Handles the CREATE/DROP PARTITION FUNCTION statement.
 */
static int
exec_stmt_partition_function(PLtsql_execstate *estate, PLtsql_stmt_partition_function *stmt)
{
	const char		*partition_function_name = stmt->function_name;
	PLtsql_type		*typ = stmt->datatype;
	List 			*arg = stmt->args;
	bool 			isnull;
	Oid			valtype;
	int32			valtypmod;
	Datum			tsql_type_datum;
	char			*tsql_typename = NULL;
	char			*collation = NULL;
	Oid			collation_oid = InvalidOid;
	bool			type_is_collatable;
	Datum			*input_values;
	Datum			*sql_variant_values;
	ArrayType		*arr_value = NULL;
	Oid			sql_variant_oid;
	Oid			basetype_oid;
	Oid			opclass_oid;
	Oid			opfamily_oid;
	Oid			cmpfunction_oid;
	int			nargs;
	HeapTuple		tuple;
	Form_pg_type		typform;
	int16			dbid = get_cur_db_id();
	tsql_compare_context	cxt;
	LOCAL_FCINFO(fcinfo, 1);

	/* check if the login has necessary permissions for CREATE/DROP */
	check_create_or_drop_permission_for_partition_specifier(partition_function_name, stmt->is_create, true);

	if (!stmt->is_create) /* drop command */
	{
		/*
		 * DROP PARTITION FUNCTION might involve TOAST table access, so ensure we
		 * have a valid snapshot.
		 */
		PushActiveSnapshot(GetTransactionSnapshot());
		/* delete entry from the sys.babelfish_partition_scheme catalog */
		remove_entry_from_bbf_partition_function(dbid, partition_function_name);
		PopActiveSnapshot();
		/* make sure later statements in batch can see the updated catalog entry */
		CommandCounterIncrement();
		return PLTSQL_RC_OK;
	}

	/*
	 * Otherwise, Create Command.
	 */

	/* check if given name is exceeding the allowed limit */
	if (strlen(partition_function_name) > 128)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The identifier that starts with '%.128s' is too long. Maximum length is 128.", partition_function_name)));
	}

	/*
	 * Get collation oid if collation is specified.
	 */
	if (stmt->collation)
	{
		collation_oid = tsql_get_oid_from_collidx(tsql_find_collation_internal(tsql_translate_tsql_collation_to_bbf_collation(stmt->collation)));
	
		/* raise an error if specified collation is invalid */
		if (!OidIsValid(collation_oid))
			ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
					errmsg("Invalid collation '%s'.", stmt->collation)));
	}

	/* check if there is existing partition function with the given name in the current database */
	if (partition_function_exists(dbid, partition_function_name))
	{
		ereport(ERROR, 
			(errcode(ERRCODE_DUPLICATE_FUNCTION),
				errmsg("There is already an object named '%s' in the database.", partition_function_name)));
	}

	/*
	 * Try to find the TSQL type name for the input type and if it fails
	 * and input type is DOMAIN type created in sys schema then
	 * find the TSQL type name using the base type of DOMAIN.
	 */
	InitFunctionCallInfoData(*fcinfo, NULL, 0, InvalidOid, NULL, NULL);
	fcinfo->args[0].value = ObjectIdGetDatum(typ->typoid);
	fcinfo->args[0].isnull = false;
	tsql_type_datum = (*common_utility_plugin_ptr->translate_pg_type_to_tsql) (fcinfo);
	if (tsql_type_datum)
	{
		tsql_typename = text_to_cstring(DatumGetTextPP(tsql_type_datum));
	}
	else
	{
		tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(typ->typoid));
		typform = (Form_pg_type) GETSTRUCT(tuple);
		if (OidIsValid(typform->typbasetype) && typform->typnamespace == get_namespace_oid("sys", false))
		{
			/* Input type is DOMAIN type created in sys schema. */
			InitFunctionCallInfoData(*fcinfo, NULL, 0, InvalidOid, NULL, NULL);
			fcinfo->args[0].value = ObjectIdGetDatum(typform->typbasetype);
			fcinfo->args[0].isnull = false;
			tsql_type_datum = (*common_utility_plugin_ptr->translate_pg_type_to_tsql) (fcinfo);
			if (tsql_type_datum)
			{
				tsql_typename = text_to_cstring(DatumGetTextPP(tsql_type_datum));
			}
		}
		ReleaseSysCache(tuple);
	}
	
	/*
	 * Check if datatype is supported or not, if tsql_typename is NULL
	 * then it implies that type is User Defined Type.
	 */
	if (!tsql_typename || is_tsql_text_ntext_or_image_datatype(typ->typoid) ||
		(*common_utility_plugin_ptr->is_tsql_geometry_datatype) (typ->typoid) ||
		(*common_utility_plugin_ptr->is_tsql_geography_datatype) (typ->typoid) ||
		(*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (typ->typoid) ||
		typ->typoid == XMLOID) /* we don't have XML type specific to TSQL */
	{
		ereport(ERROR, 
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The type '%s' is not valid for this operation.", typ->typname)));
	}
	/*
	 * Types varchar(max), nvarchar(max), varbinary(max) are also not supported.
	 */
	else if (typ->atttypmod == -1 && is_tsql_datatype_with_max_scale_expr_allowed(typ->typoid))
	{
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The type '%s(max)' is not valid for this operation.", tsql_typename)));
	}
	else if ((*common_utility_plugin_ptr->is_tsql_sqlvariant_datatype) (typ->typoid))
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("The type '%s' is not yet supported for partition function in Babelfish.", tsql_typename)));

	type_is_collatable = OidIsValid(typ->collation);

	/*
	 * Raise an error if collate clause is specified and datatype is not collatable.
	 */
	if (stmt->collation && !type_is_collatable)
	{
		
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
			 	errmsg("Expression type '%s' is invalid for COLLATE clause.", tsql_typename)));
	}
	/*
	 * Use default database collation if collate clause is not specified and datatype is collatable.
	 */
	else if (stmt->collation == NULL && type_is_collatable)
		collation_oid = tsql_get_database_or_server_collation_oid_internal(false);
	
	/* get collation name from collation oid when type is collatable */
	if (type_is_collatable)
		collation = get_collation_name(collation_oid);
	
	/* check if the given number of boundaries are exceeding allowed limit */
	nargs = list_length(arg);
	if (nargs >= MAX_PARTITIONS_LIMIT)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("CREATE/ALTER partition function failed as only a "
					"maximum of %d partitions can be created.", MAX_PARTITIONS_LIMIT)));
	}

	input_values = palloc(nargs * sizeof(Datum));

	for (volatile int i = 0; i < nargs; i++)
	{
		Datum val;

		/* evaluate the value from the expr */
		val = exec_eval_expr(estate, list_nth(arg, i), &isnull, &valtype, &valtypmod);

		/* raise error for null value */
		if (isnull)
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					errmsg("NULL values are not allowed in partition function boundary values list.")));

		/* 
		 * implicitly convert range values to specified parameter type
		 * and raise error with ordinal position if conversion fails
		 */
		PG_TRY();
		{
			input_values[i] = exec_cast_value(estate, val, &isnull,
							valtype, valtypmod,
							typ->typoid, typ->atttypmod);
		}
		PG_CATCH();
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					errmsg("Could not implicitly convert range values type specified at ordinal %d to partition function parameter type.",
						i+1)));
		}
		PG_END_TRY();
	}

	/*
	 * Find oid of comparator function for input type, which will be used during the sorting.
	 * Here, we are first finding the default operator class for the input type then using that
	 * we are finding the operator family for that operator class and finally using that we are
	 * finding the defined comparator function for that operator family.
	 */
	basetype_oid = getBaseType(typ->typoid);
	opclass_oid = GetDefaultOpClass(basetype_oid, BTREE_AM_OID);
	opfamily_oid = get_opclass_family(opclass_oid);
	cmpfunction_oid = get_opfamily_proc(opfamily_oid, basetype_oid, basetype_oid,
						BTORDER_PROC);

	/* set the function oid of operator in tsql comparator context */
	cxt.function_oid = cmpfunction_oid;
	cxt.colloid = collation_oid;
	cxt.contains_duplicate = false;

	/* 
	 * sort the datum values using quick sort, we don't need to worry about worst case
	 * of quick sort here when the array is already sorted, the function qsort_arg()
	 * itself first checks and returns the same array if values already sorted.
	 */
	qsort_arg(input_values, nargs, sizeof(Datum), tsql_compare_values, &cxt);

	/* raise error if input contains duplicate value */
	if (cxt.contains_duplicate)
	{
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("Duplicate values are not allowed in partition function boundary values list.")));
	}

	sql_variant_oid = (*common_utility_plugin_ptr->get_tsql_datatype_oid) ("sql_variant");
	sql_variant_values = palloc(nargs * sizeof(Datum));
	/* cast each value to sql_variant datatype */
	for (int i = 0; i < nargs; i++)
	{
		sql_variant_values[i] = exec_cast_value(estate, input_values[i], &isnull,
							typ->typoid, typ->atttypmod,
							sql_variant_oid,
							-1);
	}

	/* construct array object from the values which needs to inserted in the catalog */
	arr_value = construct_array(sql_variant_values, nargs, sql_variant_oid,
					-1, false, 'i');

	/* add entry in the sys.babelfish_partition_function catalog */
	add_entry_to_bbf_partition_function(dbid, partition_function_name, tsql_typename, stmt->is_right, arr_value, collation);

	pfree(tsql_typename);
	pfree(input_values);
	pfree(sql_variant_values);
	pfree(arr_value);
	if (collation)
		pfree(collation);

	/* cleanup estate */
	exec_eval_cleanup(estate);
	
	/* make sure later statements in batch can see the updated catalog entry */
	CommandCounterIncrement();
	return PLTSQL_RC_OK;
}

/*
 * exec_stmt_partition_scheme
 * 	 Handles the CREATE/DROP PARTITION SCHEME statement.
 */
static int
exec_stmt_partition_scheme(PLtsql_execstate *estate, PLtsql_stmt_partition_scheme *stmt)
{
	const char *partition_scheme_name = stmt->scheme_name;
	bool		next_used = false;
	int		filegroups = stmt->filegroups;
	char		*partition_func_name = stmt->function_name;
	int16		dbid = get_cur_db_id();

	/* check if the login has necessary permissions for CREATE/DROP */
	check_create_or_drop_permission_for_partition_specifier(partition_scheme_name, stmt->is_create, false);

	if (!stmt->is_create) /* drop command */
	{
		/*
		 * DROP PARTITION SCHEME might involve TOAST table access, so ensure we
		 * have a valid snapshot.
		 */
		PushActiveSnapshot(GetTransactionSnapshot());
		/* delete entry from the sys.babelfish_partition_scheme catalog */
		remove_entry_from_bbf_partition_scheme(dbid, partition_scheme_name);
		PopActiveSnapshot();
		/* make sure later statements in batch can see the updated catalog entry */
		CommandCounterIncrement();
		return PLTSQL_RC_OK;
	}
	
	/*
	 * Otherwise, Create Command.
	 */

	/* check if given name is exceeding the allowed limit */
	if (strlen(partition_scheme_name) > 128)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("The identifier that starts with '%.128s' is too long. Maximum length is 128.",
						partition_scheme_name)));
	}

	/* raise error if provided partition function doesn't exists in the current database */
	if (!partition_function_exists(dbid, partition_func_name))
	{
		ereport(ERROR, 
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("Invalid object name '%s'.", partition_func_name)));
	}

	/* 
	 * perform next_used calculation check if it is specified
	 * filegroups are sufficient for the partitions which 
	 * will be created using the given partition function
	 */
	if (filegroups == -1) /* implies that ALL option was used */
	{
		next_used = true;
	}
	else
	{
		int	partition_count = get_partition_count(dbid, partition_func_name);
		if (filegroups < partition_count)
		{
			ereport(ERROR, 
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					errmsg("The associated partition function '%s' generates more partitions than there are file groups mentioned in the scheme '%s'.", 
							partition_func_name, partition_scheme_name)));
		}
		else if (filegroups > partition_count)
		{
			next_used = true;
		}
	}

	/* check if there is existing partition scheme with the given name in the current database */
	if (partition_scheme_exists(dbid, partition_scheme_name))
	{
		ereport(ERROR, 
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("There is already an object named '%s' in the database.", partition_scheme_name)));
	}
	/*
	 * Adding entries for Partition Scheme might involve TOAST table access, so ensure we
	 * have a valid snapshot.
	 */
	PushActiveSnapshot(GetTransactionSnapshot());
	/* add entry in the sys.babelfish_partition_scheme catalog */
	add_entry_to_bbf_partition_scheme(dbid, partition_scheme_name, partition_func_name, next_used);

	PopActiveSnapshot();

	/* make sure later statements in batch can see the updated catalog entry */
	CommandCounterIncrement();
	return PLTSQL_RC_OK;
}

static void
set_search_path_for_sp_procs(char *schema)
{
	char 		*dbo_schema = get_dbo_schema_name(get_current_pltsql_db_name());
	char 		*new_search_path;

	if (schema != NULL && strcmp(schema, "dbo") == 0)
		new_search_path = psprintf("%s, sys, pg_catalog, %s",
						quote_identifier(dbo_schema), "master_dbo");
	else
		new_search_path = psprintf("%s, sys, pg_catalog, %s",
						get_current_db_search_path(), "master_dbo");

	SetConfigOption("search_path", new_search_path,
					PGC_SUSET, PGC_S_SESSION);

	pfree(new_search_path);
	pfree(dbo_schema);
}
