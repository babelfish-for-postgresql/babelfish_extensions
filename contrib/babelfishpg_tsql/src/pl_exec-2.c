
#include "pltsql-2.h"

#include "funcapi.h"

#include "access/table.h"
#include "access/attmap.h"
#include "catalog/namespace.h"
#include "catalog/pg_attribute.h"
#include "catalog/pg_language.h"
#include "commands/proclang.h"
#include "executor/tstoreReceiver.h"
#include "nodes/parsenodes.h"
#include "utils/acl.h"
#include "storage/lmgr.h"
#include "storage/procarray.h"
#include "pltsql_bulkcopy.h"
#include "table_variable_mvcc.h"

#include "catalog.h"
#include "dbcmds.h"
#include "pl_explain.h"
#include "rolecmds.h"
#include "session.h"

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

	/*
	 * Execute the statements in the block's body inside a sub-transaction
	 */
	MemoryContext oldcontext = CurrentMemoryContext;
	ResourceOwner oldowner = CurrentResourceOwner;
	ExprContext *old_eval_econtext = estate->eval_econtext;
	ErrorData  *save_cur_error = estate->cur_error->error;

	MemoryContext stmt_mcontext;

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
/* 		ErrorData  *edata; */

		estate->err_text = gettext_noop("during exception cleanup");

		/* Save error info in our stmt_mcontext */
		MemoryContextSwitchTo(stmt_mcontext);
/* 		edata = CopyErrorData(); */
		FlushErrorState();

		/* Abort the inner transaction */
		RollbackAndReleaseCurrentSubTransaction();
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;

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

	exec_run_select(estate, stmt->query, 0, &portal);

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

	receiver = CreateDestReceiver(DestRemote);
	SetRemoteDestReceiverParams(receiver, portal);

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
	bool		need_path_reset = false;

	char	   *cur_dbname = get_cur_db_name();

	/* fetch current search_path */
	char	   *old_search_path = NULL;
	char	   *new_search_path;

	estate->db_name = NULL;
	if (stmt->proc_name == NULL)
		stmt->proc_name = "";

	if (stmt->is_cross_db)
	{
		estate->db_name = stmt->db_name;
	}

	/*
	 * "sp_describe_first_result_set" needs special handling. It is a sys
	 * function and satisfies the below condition and it appends "master_dbo"
	 * to the search path which is not required for sys functions.
	 */
	if (strcmp(stmt->proc_name, "sp_describe_first_result_set") != 0)
	{
		if (strncmp(stmt->proc_name, "sp_", 3) == 0 && strcmp(cur_dbname, "master") != 0
			&& ((stmt->schema_name == NULL || stmt->schema_name[0] == (char) '\0') || strcmp(stmt->schema_name, "dbo") == 0))
		{
			if (!old_search_path)
			{
				List	   *path_oids = fetch_search_path(false);

				old_search_path = flatten_search_path(path_oids);
				list_free(path_oids);
			}
			new_search_path = psprintf("%s, master_dbo", old_search_path);

			/* Add master_dbo to the new search path */
			(void) set_config_option("search_path", new_search_path,
									 PGC_USERSET, PGC_S_SESSION,
									 GUC_ACTION_SAVE, true, 0, false);
			need_path_reset = true;
		}
	}
	if (stmt->schema_name != NULL && stmt->schema_name[0] != (char) '\0')
		estate->schema_name = stmt->schema_name;
	else
		estate->schema_name = NULL;

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

		/* T-SQL doesn't allow call procedure in function */
		if (estate->func && estate->func->fn_oid != InvalidOid && estate->func->fn_prokind == PROKIND_FUNCTION && estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER /* check EXEC is running
																																									 * in the body of
																																									 * function */
			&& !is_scalar_func) /* in case of EXEC on scalar function, it is
								 * allowed in T-SQL. do not throw an error */
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

		before_lxid = MyProc->lxid;
		topEntry = simple_econtext_stack;

		memset(&options, 0, sizeof(options));
		options.params = paramLI;
		options.read_only = estate->readonly_func;
		options.allow_nonatomic = true;

		rc = SPI_execute_plan_extended(expr->plan, &options);

		after_lxid = MyProc->lxid;

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
		if (need_path_reset)
		{
			(void) set_config_option("search_path", old_search_path,
									 PGC_USERSET, PGC_S_SESSION,
									 GUC_ACTION_SAVE, true, 0, false);
		}

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

	if (need_path_reset)
	{
		(void) set_config_option("search_path", old_search_path,
								 PGC_USERSET, PGC_S_SESSION,
								 GUC_ACTION_SAVE, true, 0, false);
	}

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
		 * then the above construction of tblname will be >63 characters, which will violate the
		 * max length of PG identiefiers and cause issues down the road. Fix this by truncating
		 * tblname so that adding the "_<@@nestlevel>" suffix will be exactly 63 characters.
		 */
		if (strlen(tblname) >= NAMEDATALEN)
		{
			// truncate tblname to fit the "_#" nestlevel suffix
			tblname[(NAMEDATALEN-1)-(strlen(tblname)-(NAMEDATALEN-1))] = '\0';
			// previous palloc of tblname will be cleaned up with the memory context
			tblname = psprintf("%s_%d", tblname, estate->nestlevel);
		}
		
		if (stmt->tbltypname)
			query = psprintf("CREATE TEMPORARY TABLE IF NOT EXISTS %s (like %s including all)",
							 tblname, stmt->tbltypname);
		else
			query = psprintf("CREATE TEMPORARY TABLE IF NOT EXISTS %s%s",
							 tblname, stmt->coldef);

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
	char	   *old_db_name = get_cur_db_name();
	char	   *cur_db_name = NULL;

	LOCAL_FCINFO(fcinfo, 1);

	/*
	 * First we evaluate the string expression. Its result is the
	 * querystring we have to execute.
	 */
	query = exec_eval_expr(estate, stmt->expr, &isnull, &restype, &restypmod);
	if (isnull)
	{
		/* No op in case of null */
		return PLTSQL_RC_OK;
	}
	save_nestlevel = pltsql_new_guc_nest_level();
	scope_level = pltsql_new_scope_identity_nest_level();

	PG_TRY();
	{
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
		before_lxid = MyProc->lxid;
		topEntry = simple_econtext_stack;

		/* Pass the control the inline handler */
		pltsql_inline_handler(fcinfo);

		if (fcinfo->isnull)
			elog(ERROR, "pltsql_inline_handler failed");
	}
	PG_FINALLY();
	{
		/* Restore past settings */
		pltsql_revert_guc(save_nestlevel);
		pltsql_revert_last_scope_identity(scope_level);

		cur_db_name = get_cur_db_name();
		if (strcmp(cur_db_name, old_db_name) != 0)
			set_session_properties(old_db_name);
	}
	PG_END_TRY();

	after_lxid = MyProc->lxid;

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

	before_lxid = MyProc->lxid;
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

	after_lxid = MyProc->lxid;

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
				bool		isnull;
				Oid			restype;
				int32		restypmod;
				int			save_nestlevel;
				int			scope_level;
				InlineCodeBlockArgs *args = NULL;
				
				batch = exec_eval_expr(estate, stmt->query, &isnull, &restype, &restypmod);
				if (isnull)
				{
					// When called with a NULL argument, sp_executesql should take no action at all
					break;
				}

				batchstr = convert_value_to_string(estate, batch, restype);

				args = create_args(0);
				if (stmt->param_def)
				{
					Datum		paramdef;
					Oid			restype;
					int32		restypmod;
					char	   *paramdefstr;
					bool		isnull;

					/*
					 * Evaluate the parameter definition
					 */
					paramdef = exec_eval_expr(estate, stmt->param_def, &isnull, &restype, &restypmod);

					if (isnull)
						ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
										errmsg("NULL param definition")));

					paramdefstr = convert_value_to_string(estate, paramdef, restype);

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
				PG_FINALLY();
				{
					pltsql_revert_guc(save_nestlevel);
					pltsql_revert_last_scope_identity(scope_level);
				}
				PG_END_TRY();
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
				bool		isnull;
				Oid			restype;
				int32		restypmod;
				InlineCodeBlockArgs *args = NULL;
				Datum		paramdef;
				char	   *paramdefstr;

				batch = exec_eval_expr(estate, stmt->query, &isnull, &restype, &restypmod);
				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
									errmsg("batch string argument of sp_prepexec is null")));

				batchstr = convert_value_to_string(estate, batch, restype);

				args = create_args(0);

				/*
				 * Evaluate the parameter definition
				 */
				paramdef = exec_eval_expr(estate, stmt->param_def, &isnull, &restype, &restypmod);

				if (!isnull)
				{
					paramdefstr = convert_value_to_string(estate, paramdef, restype);

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
	 */
	initStringInfo(&proc_stmt);
	appendStringInfoString(&proc_stmt, str1);
	appendStringInfoString(&proc_stmt, paramdefstr);
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

	/*
	 * Same as set_session_properties() but skips checks as they were done
	 * before locking
	 */
	set_cur_user_db_and_path(stmt->db_name);

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
		set_session_properties(initial_database_name);
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

	set_cur_user_db_and_path(stmt->db_name);

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
	 * sysadmin, then it doesn't have the permission to GRANT/REVOKE.
	 */
	login_is_db_owner = 0 == strncmp(login, get_owner_of_db(dbname), NAMEDATALEN);
	datdba = get_role_oid("sysadmin", false);
	if (!is_member_of_role(GetSessionUserId(), datdba) && !login_is_db_owner)
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
		alter_user_can_connect(stmt->is_grant, grantee_name, dbname);
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
	exec_run_select(estate, query, 0, &portal);

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
	if (!(pg_namespace_ownercheck(nsp_oid, GetUserId()) ||
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
			seqid = getIdentitySequence(table_oid, attnum + 1, false);
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
			rolname	= get_physical_user_name(dbname, grantee_name, true);
		else
			rolname = pstrdup(PUBLIC_ROLE_NAME);
		role_oid = get_role_oid(rolname, true);

		/* Special database roles should throw an error. */
		if (strcmp(grantee_name, "db_owner") == 0)
			ereport(ERROR, (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				errmsg("Cannot grant, deny or revoke permissions to or from special roles.")));

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

		if ((strcmp(rolname, user) == 0) || (!is_public && pg_namespace_ownercheck(schemaOid, role_oid)) || is_member_of_role(role_oid, get_sysadmin_oid()))
			ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					errmsg("Cannot grant, deny, or revoke permissions to sa, dbo, entity owner, information_schema, sys, or yourself.")));

		/*
		 * If the login is not the db owner or the login is not the member of
		 * sysadmin or login is not the schema owner, then it doesn't have the permission to GRANT/REVOKE.
		 */
		if (!is_member_of_role(GetSessionUserId(), get_sysadmin_oid()) && !login_is_db_owner && !pg_namespace_ownercheck(schemaOid, GetUserId()))
			ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					errmsg("Cannot find the schema \"%s\", because it does not exist or you do not have permission.", stmt->schema_name)));

		/* Execute the GRANT SCHEMA subcommands. */
		for (i = 0; i < NUMBER_OF_PERMISSIONS; i++)
		{
			if (stmt->privileges & permissions[i])
				exec_grantschema_subcmds(schema_name, rolname, stmt->is_grant, stmt->with_grant_option, permissions[i], false);
		}

		if (stmt->is_grant)
		{
			/* For GRANT statement, add or update privileges in the catalog. */
			add_or_update_object_in_bbf_schema(stmt->schema_name, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, stmt->privileges, rolname, OBJ_SCHEMA, true, NULL);
		}
		else
		{
			/* For REVOKE statement, update privileges in the catalog. */
			if (privilege_exists_in_bbf_schema_permissions(stmt->schema_name, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, rolname))
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
	
	/* Verify target database exists. */
	if (!DbidIsValid(get_db_id(stmt->db_name)))
	{
		ereport(ERROR, (errcode(ERRCODE_UNDEFINED_DATABASE),	
						errmsg("Cannot find the database '%s', because it does not exist or you do not have permission.", stmt->db_name)));
	}

	/* Verify new owner exists as a login. */
	if (get_role_oid(stmt->new_owner_name, true) == InvalidOid)
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
			/* Current login is DB owner, so perform the update */
			update_db_owner(stmt->new_owner_name, stmt->db_name);	
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

	/* Revoke dbo role from the previous owner */
	grant_revoke_role_to_login(get_owner_of_db(stmt->db_name), get_dbo_role_name(stmt->db_name), false);

	/* Grant dbo role to the new owner */
	grant_revoke_role_to_login(stmt->new_owner_name, get_dbo_role_name(stmt->db_name), true);
	update_db_owner(stmt->new_owner_name, stmt->db_name);

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
	if (!is_member_of_role(GetSessionUserId(), datdba) && !login_is_db_owner && !pg_namespace_ownercheck(schemaOid, GetUserId()))
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
				is_create ? "(CREATE FULLTEXT INDEX STATEMENT )" : "(DELETE FULLTEXT INDEX STATEMENT )",
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
