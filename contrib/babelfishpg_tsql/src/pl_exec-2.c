
#include "pltsql-2.h"

#include "funcapi.h"

#include "catalog/namespace.h"
#include "catalog/pg_language.h"
#include "commands/proclang.h"
#include "executor/tstoreReceiver.h"
#include "nodes/parsenodes.h"

#include "catalog.h"
#include "session.h"

/* helper function to get current T-SQL estate */
PLtsql_execstate *get_current_tsql_estate(void);

/*
 * NOTE:
 *	A SET...(SELECT) statement that returns more than one row will raise an error
 *  A SELECT statement that returns more than one row will assign the values in the last row
 *
 *  A SET...(SELECT) statement that returns zero rows will set the target(s) to NULL
 *  A SELECT statement that returns zero rows will leave the target(s) unchanged
 */

static int exec_tsql_stmt(PLtsql_execstate *estate, PLtsql_stmt *stmt, PLtsql_stmt *save_estmt);
static int exec_stmt_print(PLtsql_execstate *estate, PLtsql_stmt_print *stmt);
static int exec_stmt_query_set(PLtsql_execstate *estate, PLtsql_stmt_query_set *stmt);
static int exec_stmt_try_catch(PLtsql_execstate *estate, PLtsql_stmt_try_catch *stmt);
static int exec_stmt_push_result(PLtsql_execstate *estate, PLtsql_stmt_push_result *stmt);
static int exec_stmt_exec(PLtsql_execstate *estate, PLtsql_stmt_exec *stmt);
static int exec_stmt_decl_table(PLtsql_execstate *estate, PLtsql_stmt_decl_table *stmt);
static int exec_stmt_return_table(PLtsql_execstate *estate, PLtsql_stmt_return_query *stmt);
static int exec_stmt_exec_batch(PLtsql_execstate *estate, PLtsql_stmt_exec_batch *stmt);
static int exec_stmt_exec_sp(PLtsql_execstate *estate, PLtsql_stmt_exec_sp *stmt);
static int exec_stmt_deallocate(PLtsql_execstate *estate, PLtsql_stmt_deallocate *stmt);
static int exec_stmt_decl_cursor(PLtsql_execstate *estate, PLtsql_stmt_decl_cursor *stmt);
static int exec_run_dml_with_output(PLtsql_execstate *estate, PLtsql_stmt_push_result *stmt, 
									Portal portal, PLtsql_expr *expr, CmdType cmd, ParamListInfo paramLI);
static int exec_stmt_usedb(PLtsql_execstate *estate, PLtsql_stmt_usedb *stmt);
static int exec_stmt_insert_execute_select(PLtsql_execstate *estate, PLtsql_expr *expr);
static int exec_stmt_insert_bulk(PLtsql_execstate *estate, PLtsql_stmt_insert_bulk *expr);
extern Datum pltsql_inline_handler(PG_FUNCTION_ARGS);

static char *transform_tsql_temp_tables(char * dynstmt);
static char *next_word(char *dyntext);
static bool is_next_temptbl(char *dyntext);
static bool is_char_identstart(char c);
static bool is_char_identpart(char c);

void read_param_def(InlineCodeBlockArgs * args, const char *paramdefstr);
void cache_inline_args(PLtsql_function *func, InlineCodeBlockArgs *args);
InlineCodeBlockArgs *create_args(int numargs);
InlineCodeBlockArgs *clone_inline_args(InlineCodeBlockArgs *args);
static void read_param_val(PLtsql_execstate *estate, List *params, InlineCodeBlockArgs *args,
							FunctionCallInfo fcinfo, PLtsql_row *row);
static bool check_spexecutesql_param(char *defmode, tsql_exec_param *p);

static int exec_eval_int(PLtsql_execstate *estate, PLtsql_expr *expr, bool *isNull);

int
execute_plan_and_push_result(PLtsql_execstate *estate, PLtsql_expr *expr, ParamListInfo paramLI);

static void get_param_mode(List *params, int paramno, char **modes);

extern void pltsql_update_cursor_row_count(char *curname, int64 row_count);
extern void pltsql_update_cursor_last_operation(char *curname, int last_operation);
extern bool pltsql_declare_cursor(PLtsql_execstate *estate, PLtsql_var *var, PLtsql_expr* explicit_expr, int cursor_options);
extern char *pltsql_demangle_curname(char *curname);

extern void enable_sp_cursor_find_param_hook(void);
extern void disable_sp_cursor_find_param_hook(void);
extern void add_sp_cursor_param(char *name);
extern void reset_sp_cursor_params();

extern void pltsql_commit_not_required_impl_txn(PLtsql_execstate *estate);

int execute_batch(PLtsql_execstate *estate, char *batch, InlineCodeBlockArgs *args, List *params);

extern PLtsql_function 	*find_cached_batch(int handle);

extern SPIPlanPtr	prepare_stmt_exec(PLtsql_execstate *estate, PLtsql_function *func, PLtsql_stmt_exec *stmt, bool keepplan);

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

int pltsql_proc_return_code;

char *bulk_load_table_name = NULL;

PLtsql_execstate *get_current_tsql_estate()
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

static int
exec_tsql_stmt(PLtsql_execstate *estate, PLtsql_stmt *stmt, PLtsql_stmt *save_estmt)
{
	int rc;

	switch ((int) stmt->cmd_type)
	{
		case PLTSQL_STMT_PRINT:
			rc = exec_stmt_print(estate, (PLtsql_stmt_print *) stmt);
			break;

		case PLTSQL_STMT_INIT:
			/* 
			 * This stmt contains a (possibly nil) list of assignment
			 * statements, each of which initializes a particular
			 * variable.
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

		default:
			estate->err_stmt = save_estmt;
			elog(ERROR, "unrecognized cmd_type: %d", stmt->cmd_type);
	}
	
	return rc;
}

static int
exec_stmt_print(PLtsql_execstate *estate, PLtsql_stmt_print *stmt)
{
	Datum	formatdatum;
	bool	formatisnull;
	Oid		formattypeid;
	int32	formattypmod;
	char   *extval;
	formatdatum = exec_eval_expr(estate,
								 (PLtsql_expr *) linitial(stmt->exprs),
								 &formatisnull,
								 &formattypeid,
								 &formattypmod);

	if (formatisnull)
		extval = "<NULL>";
	else
		extval = convert_value_to_string(estate,
										 formatdatum,
										 formattypeid);

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
	int	rc;

	/*
	 * On the first call for this statement generate the plan, and detect
	 * whether the statement is INSERT/UPDATE/DELETE
	 */
	if (stmt->sqlstmt->plan == NULL)
		exec_prepare_plan(estate, stmt->sqlstmt, CURSOR_OPT_PARALLEL_OK, true);

	/*
	 * If we started an implicit_transaction for this statement but
	 * the statement has a simple expression associated with them,
	 * we no longer require an implicit transaction
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
	 * A SELECT statement that returns zero rows will leave the 
	 * target(s) unchanged
	 *
	 * A SELECT statement that returns more than one row will assign 
	 * the values in the *last* row.
	 */

	if (SPI_processed > 0)
	{
		PLtsql_variable *target = (PLtsql_variable *) estate->datums[stmt->target->dno];

		/* Put the last result row into the target */
		exec_move_row(estate, target, SPI_tuptable->vals[SPI_processed-1], SPI_tuptable->tupdesc);
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
	ErrorData *save_cur_error = estate->cur_error->error;

	MemoryContext stmt_mcontext;

	estate->err_text = gettext_noop("during statement block entry");

	/*
	 * We will need a stmt_mcontext to hold the error data if an error
	 * occurs.  It seems best to force it to exist before entering the
	 * subtransaction, so that we reduce the risk of out-of-memory during
	 * error recovery, and because this greatly simplifies restoring the
	 * stmt_mcontext stack to the correct state after an error.  We can
	 * ameliorate the cost of this by allowing the called statements to
	 * use this mcontext too; so we don't push it down here.
	 */
	stmt_mcontext = get_stmt_mcontext(estate);

	BeginInternalSubTransaction(NULL);
	/* Want to run statements inside function's memory context */
	MemoryContextSwitchTo(oldcontext);

	PG_TRY();
	{
		/*
		 * We need to run the block's statements with a new eval_econtext
		 * that belongs to the current subtransaction; if we try to use
		 * the outer econtext then ExprContext shutdown callbacks will be
		 * called at the wrong times.
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
		 * Revert to outer eval_econtext.  (The inner one was
		 * automatically cleaned up during subxact exit.)
		 */
		estate->eval_econtext = old_eval_econtext;
	}
	PG_CATCH();
	{
//		ErrorData  *edata;

		estate->err_text = gettext_noop("during exception cleanup");

		/* Save error info in our stmt_mcontext */
		MemoryContextSwitchTo(stmt_mcontext);
//		edata = CopyErrorData();
		FlushErrorState();

		/* Abort the inner transaction */
		RollbackAndReleaseCurrentSubTransaction();
		MemoryContextSwitchTo(oldcontext);
		CurrentResourceOwner = oldowner;

		/*
		 * Set up the stmt_mcontext stack as though we had restored our
		 * previous state and then done push_stmt_mcontext().  The push is
		 * needed so that statements in the exception handler won't
		 * clobber the error data that's in our stmt_mcontext.
		 */
		estate->stmt_mcontext_parent = stmt_mcontext;
		estate->stmt_mcontext = NULL;

		/*
		 * Now we can delete any nested stmt_mcontexts that might have
		 * been created as children of ours.  (Note: we do not immediately
		 * release any statement-lifespan data that might have been left
		 * behind in stmt_mcontext itself.  We could attempt that by doing
		 * a MemoryContextReset on it before collecting the error data
		 * above, but it seems too risky to do any significant amount of
		 * work before collecting the error.)
		 */
		MemoryContextDeleteChildren(stmt_mcontext);

		/* Revert to outer eval_econtext */
		estate->eval_econtext = old_eval_econtext;

		/*
		 * Must clean up the econtext too.  However, any tuple table made
		 * in the subxact will have been thrown away by SPI during subxact
		 * abort, so we don't need to (and mustn't try to) free the
		 * eval_tuptable.
		 */
		estate->eval_tuptable = NULL;
		exec_eval_cleanup(estate);

		rc = exec_stmt(estate, stmt->handler);

		/*
		 * Restore previous state of cur_error, whether or not we executed
		 * a handler.  This is needed in case an error got thrown from
		 * some inner block's exception handler.
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
					 true,	/* always top level */
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
	bool 		success = false;
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

	/* PG_TRY to ensure we clear the plan link, if needed, on failure */
	PG_TRY();
	{
		SPIPlanPtr	plan = expr->plan;
		ParamListInfo paramLI;
		PLtsql_var *return_code;
		Query* query;
		TargetEntry *target; /* used for scalar function */
		Oid rettype; /* used for scalar function */
		int32 rettypmod; /* used for scalar function */
		bool is_scalar_func;
		/* for EXEC as part of inline code under INSERT ... EXECUTE */
		Tuplestorestate *tss;
		DestReceiver *dest;
		
		if (plan == NULL)
			plan = prepare_stmt_exec(estate, estate->func, stmt, estate->atomic);

		/*
		 * If we will deal with scalar function, we need to know the correct return-type.
		 */
		query = linitial_node(Query, ((CachedPlanSource *) linitial(plan->plancache_list))->query_list);

		if (query->commandType == CMD_SELECT)
		{
			Node* node;
			FuncExpr *funcexpr;
			HeapTuple func_tuple;

			if (query->targetList == NULL || list_length(query->targetList) != 1)
				elog(ERROR, "scalar function on EXEC statement does not have exactly 1 target");
			node = linitial(query->targetList);
			if (node == NULL || !IsA(node, TargetEntry))
				elog(ERROR, "scalar function on EXEC statement does not have target entry");
			target = (TargetEntry *) node;
			if (target->expr == NULL || !IsA(target->expr, FuncExpr))
				elog(ERROR, "scalar function on EXEC statement does not have scalar function target");

			funcexpr = (FuncExpr*) target->expr;

			func_tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcexpr->funcid));
			if (!HeapTupleIsValid(func_tuple))
				elog(ERROR, "cache lookup failed for function %u", funcexpr->funcid);

			rettype = exprType((Node*) funcexpr);
			rettypmod = exprTypmod((Node*) funcexpr);

			ReleaseSysCache(func_tuple);

			is_scalar_func = true;
		}
		else
		{
			is_scalar_func = false;
		}

		stmt->is_scalar_func = is_scalar_func;

		/* T-SQL doens't allow call prcedure in function */
		if (estate->func && estate->func->fn_oid != InvalidOid && estate->func->fn_prokind == PROKIND_FUNCTION && estate->func->fn_is_trigger == PLTSQL_NOT_TRIGGER /* check EXEC is running in the body of function */
		   && !is_scalar_func) /* in case of EXEC on scalar function, it is allowed in T-SQL. do not throw an error */
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
			ListCell   *lc;

			if (is_scalar_func)
			{
				funcexpr = (FuncExpr*) target->expr;
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
				Node	   *n = lfirst(lc);

				if (argmodes &&
					(argmodes[i] == PROARGMODE_INOUT ||
					 argmodes[i] == PROARGMODE_OUT))
				{
					if (parammodes &&
						parammodes[i] != PROARGMODE_INOUT &&
						parammodes[i] != PROARGMODE_OUT)
					{
						/* 
						 * If an INOUT arg is called without OUTPUT, it should be treated like an 
						 * IN param. Put -1 to param id. We can skip assigning actual value.
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
						 * Other than PL/pgsql, T-SQL allows implicit casting in INOUT and OUT params.
						 *
						 * In PG, if implcit casting is added (i.e. int->bigint), it throws an error
						 * "corresponding argument is not writable" (see the else-clause)
						 *
						 * In T-SQL, if arg node is an implicit casting, we will strip the casting.
						 * Actual casting will be done at value assignement with validity check.
						 */

						Param *param = (Param *) get_underlying_node_from_implicit_casting(n, T_Param);

						/* paramid is offset by 1 (see make_datum_param()) */
						row->varnos[nfields++] = param->paramid - 1;
					}
					else if (argmodes[i] == PROARGMODE_INOUT && IsA(n, Const))
					{
						/*
						 * T-SQL allows to pass constant value as an output parameter.
						 * Put -1 to param id. We can skip assigning actual value.
						 */
						row->varnos[nfields++] = -1;
					}
					else if (argmodes[i] == PROARGMODE_INOUT && get_underlying_node_from_implicit_casting(n, T_Const) != NULL)
					{
						/* mixture case of implicit casting + CONST. We can skip assigning actual value. */
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
			SetTuplestoreDestReceiverParams(dest, tss, CurrentMemoryContext, false);
			dest->rStartup(dest, -1, estate->rsi->expectedDesc);

			callstmt = (CallStmt *)node;
			callstmt->relation = InvalidOid;
			callstmt->attrnos = NULL;
			callstmt->retdesc = (void *)estate->rsi->expectedDesc;
			callstmt->dest = (void *)dest;
		}

		paramLI = setup_param_list(estate, expr);

		before_lxid = MyProc->lxid;
		topEntry = simple_econtext_stack;

		rc = SPI_execute_plan_with_paramlist(expr->plan, paramLI,
											 estate->readonly_func, 0);

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
				 * In case of scalar function, we should have 1-row/1-column result.
				 * Get the result data and assign into return_code. We should use exec_assign_value()
				 * to handle implicit casting correctly.
				 */
				Datum retval;
				bool isnull;

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
			 * For EXEC under INSERT ... EXECUTE, get the rows sent back by the
			 * CallStmt, and store them into estate->tuple_store so that at the
			 * end of function execution they will be sent to the right place.
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
		 * If we aren't saving the plan, unset the pointer.  Note that it
		 * could have been unset already, in case of a recursive call.
		 */
		if (expr->plan && !expr->plan->saved)
			expr->plan = NULL;
		PG_RE_THROW();
	}
	PG_END_TRY();

	if (expr->plan && !expr->plan->saved)
		expr->plan = NULL;

	if (rc < 0)
		elog(ERROR, "SPI_execute_plan_with_paramlist failed executing query \"%s\": %s",
			 expr->query, SPI_result_code_string(rc));

	after_lxid = MyProc->lxid;

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
	char *tblname;
	char *query;
	PLtsql_tbl *var = (PLtsql_tbl *) (estate->datums[stmt->dno]);
	int rc;
	bool isnull;
	int old_client_min_messages;

	if (estate->nestlevel == -1)
	{
		rc = SPI_execute("SELECT @@nestlevel", true, 0);
		if (rc != SPI_OK_SELECT || SPI_processed != 1)
			elog(ERROR, "Failed to get @@NESTLEVEL when declaring table variable %s", var->refname);
		estate->nestlevel = DatumGetInt32(SPI_getbinval(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1, &isnull));
	}

	tblname = psprintf("%s_%d", var->refname, estate->nestlevel);
	if (stmt->tbltypname)
		query = psprintf("CREATE TEMPORARY TABLE IF NOT EXISTS %s (like %s including all)",
						 tblname, stmt->tbltypname);
	else
		query = psprintf("CREATE TEMPORARY TABLE IF NOT EXISTS %s%s",
						 tblname, stmt->coldef);

	/*
	 * If a table with the same name already exists, we should just use that
	 * table, and ignore the NOTICE of "relation already exists, skipping".
	 */
	old_client_min_messages = client_min_messages;
	client_min_messages = WARNING;
	rc = SPI_execute(query, false, 0);
	client_min_messages = old_client_min_messages;
	if (rc != SPI_OK_UTILITY)
		elog(ERROR, "Failed to create the underlying table for table variable %s", var->refname);

	var->tblname = tblname;
	if (var->tbltypeid == InvalidOid)
		var->tbltypeid = TypenameGetTypid(tblname);
	var->need_drop = true;

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
	PLtsql_tbl  *tbl;
	MemoryContext oldcontext;

	tbl = (PLtsql_tbl *) (estate->datums[estate->func->out_param_varno]);

	/*
	 * Begin constructing query expr
	 */
	oldcontext = MemoryContextSwitchTo(estate->func->fn_cxt);

	expr = palloc0(sizeof(PLtsql_expr));
	expr->query			= psprintf("select * from %s", tbl->tblname);
	expr->plan			= NULL;
	expr->paramnos		= NULL;
	expr->rwparam		= -1;
	expr->ns			= pltsql_ns_top();

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
	Datum	      query;
	bool	      isnull;
	Oid	      restype;
	int32	      restypmod;
	char	      *querystr;
	InlineCodeBlock *codeblock;
	volatile LocalTransactionId before_lxid;
	LocalTransactionId after_lxid;
	SimpleEcontextStackEntry *topEntry;
	LOCAL_FCINFO(fcinfo,1);

	PG_TRY();
	{
		/*
		* First we evaluate the string expression. Its result is the
		* querystring we have to execute.
		*/
		query = exec_eval_expr(estate, stmt->expr, &isnull, &restype, &restypmod);
		if (isnull) {
			/* No op in case of null */
			return PLTSQL_RC_OK;
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
		before_lxid = MyProc->lxid;
		topEntry = simple_econtext_stack;

		/* Pass the control the inline handler */
		pltsql_inline_handler(fcinfo);

		if (fcinfo->isnull)
			elog(ERROR, "pltsql_inline_handler failed");
	}
	PG_CATCH();
	{
		PG_RE_THROW();
	}
	PG_END_TRY();

	after_lxid = MyProc->lxid;

	/*
	 * This logic is similar to what we do in exec_stmt_exec_spexecutesql().
	 * If we are in a different transaction here, we need to build
	 * new simple-expression infrastructure.
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
	Datum			retval;
	volatile LocalTransactionId before_lxid;
	LocalTransactionId after_lxid;
	SimpleEcontextStackEntry *topEntry;
	PLtsql_row * row = NULL;
	FmgrInfo		flinfo;
	LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);
	InlineCodeBlock		*codeblock = makeNode(InlineCodeBlock);

	/* 
	 * 1. Build code block to store SQL query 
	 */
	codeblock->source_text = batch;
	codeblock->atomic = false;  /* sp_executesql could not be top level */

	/*
	 * 2. Build fcinfo to pack all function info
	 */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(FUNC_MAX_ARGS));
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
		 * We have to assign the param declaration info at the last because we may
		 * need to change the param mode in the above process.
		 */
		fcinfo->nargs += 1;
		fcinfo->args[1].value = PointerGetDatum(args);
		fcinfo->args[1].isnull = false;

		if (params)
		{
			/* SP_PREPAR may pass NULL, but it could not have params */
			Assert(estate);
			/*
			 * 3. Read parameter values, insert OUT parameter info in
			 * the row Datum.
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
			if (fcinfo->nargs > FUNC_MAX_ARGS)
				ereport(ERROR, (errcode(ERRCODE_TOO_MANY_ARGUMENTS),
						errmsg("cannot pass more than %d arguments to a procedure",
							   FUNC_MAX_ARGS)));

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
		ENRDropTempTables(currentQueryEnv);
		remove_queryEnv();
		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Delete temporary tables as ENR */
	ENRDropTempTables(currentQueryEnv);
	remove_queryEnv();

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
evaluate_sp_cursor_param_def(PLtsql_execstate *estate, PLtsql_expr *stmt_param_def, const char* proc_name)
{
	InlineCodeBlockArgs *args = NULL;
	Datum	paramdef;
	char	*paramdefstr;
	bool	isnull;
	Oid	restype;
	int32	restypmod;

	args = create_args(0);

	if (stmt_param_def == NULL)
		return args;

	/* Evaluate the parameter definition */
	paramdef = exec_eval_expr(estate, stmt_param_def, &isnull, &restype, &restypmod);
	if (!isnull)
	{
		paramdefstr = convert_value_to_string(estate, paramdef, restype);
		if (strlen(paramdefstr) > 0) /* empty string should be treated as same as NULL */
		{
			read_param_def(args, paramdefstr);

			reset_sp_cursor_params();
			for (int i=0; i<args->numargs; ++i)
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
	Oid rettype;
	int32 rettypmod;
	ListCell *lc;
	int i = 0;
	bool isnull;

	if (paramno <= 0)
		return;

	Assert(values); /* should be provided by caller */
	Assert(nulls); /* should be provided by caller */

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
	int cursor_handle;
	int prepared_handle;
	Datum val;
	bool isnull;
	Oid restype;
	int32 restypmod;
	char *querystr;
	int ret;

	switch(stmt->sp_type_code)
	{
		case PLTSQL_EXEC_SP_CURSOR:
		{
			int opttype;
			int rownum;
			char *tablename;

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
			int scrollopt;
			int ccopt;
			int rowcount;
			bool scrollopt_null = true;
			bool ccopt_null = true;
			bool rowcount_null = true;
			InlineCodeBlockArgs *args = NULL;
			int paramno = stmt->paramno;
			Datum *values = NULL;
			char *nulls = NULL;

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
			int options;
			int scrollopt;
			int ccopt;
			bool scrollopt_null = true;
			bool ccopt_null = true;
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
			int scrollopt;
			int ccopt;
			int rowcount;
			bool scrollopt_null = true;
			bool ccopt_null = true;
			bool rowcount_null = true;
			int paramno = stmt->paramno;
			Datum *values = NULL;
			char *nulls = NULL;

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
			int scrollopt;
			int ccopt;
			int rowcount;
			bool scrollopt_null = true;
			bool ccopt_null = true;
			bool rowcount_null = true;
			InlineCodeBlockArgs *args = NULL;
			int paramno = stmt->paramno;
			Datum *values = NULL;
			char *nulls = NULL;

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
				                               1, /* options: unlike documenation, sp_cursorprepexec doens't take an option value*/
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
			int fetchtype;
			int rownum;
			int nrows;
			bool fetchtype_null = true;
			bool rownum_null = true;
			bool nrows_null = true;

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
			int code;
			int ivalue;
			char *cvalue;

			cursor_handle = exec_eval_int(estate, stmt->handle, &isnull);
			if (isnull)
				ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("cursor argument of sp_cursoroption is null")));

			code = exec_eval_int(estate, stmt->opt1, &isnull);
			if (isnull)
				ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("code argument of sp_cursoroption is null")));

			if (code == 0x2) /* special case */
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
			Datum	batch;
			char    *batchstr;
			bool	isnull;
			Oid		restype;
			int32	restypmod;
			InlineCodeBlockArgs *args = NULL;

			batch = exec_eval_expr(estate, stmt->query, &isnull, &restype, &restypmod);
			if (isnull)
				ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
						errmsg("batch string argument of sp_executesql is null")));

			batchstr = convert_value_to_string(estate, batch, restype);

			args = create_args(0);
			if (stmt->param_def)
			{
				Datum	paramdef;
				Oid	   	restype;
				int32	restypmod;
				char	*paramdefstr;
				bool	isnull;

				/* 
				 * Evaluate the parameter definition 
				 */
				paramdef = exec_eval_expr(estate, stmt->param_def, &isnull, &restype, &restypmod);

				if (isnull)
					ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("NULL param definition")));

				paramdefstr = convert_value_to_string(estate, paramdef, restype);

				read_param_def(args, paramdefstr);

				if (args->numargs != stmt->paramno)
					ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("param definition mismatches with inputs")));
			}
			ret = execute_batch(estate, batchstr, args, stmt->params);

			if (stmt->return_code_dno != -1)
			{
				exec_assign_value(estate, estate->datums[stmt->return_code_dno], Int32GetDatum(ret), false, INT4OID, 0);
			}
			break;
		}
		case PLTSQL_EXEC_SP_EXECUTE:
		{
			int handle = exec_eval_int(estate, stmt->handle, &isnull);
			InlineCodeBlockArgs *args;
			PLtsql_function		*func;

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
			Datum	batch;
			char    *batchstr;
			bool	isnull;
			Oid		restype;
			int32	restypmod;
			InlineCodeBlockArgs *args = NULL;
			Datum	paramdef;
			char	*paramdefstr;

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
	Portal portal;
	char *curname;
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
			if(IS_TDS_CLIENT() && portal->portalPinned)

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
	char *curname;
	MemoryContext oldcontext;

	Assert(estate->datums[stmt->curvar]->dtype == PLTSQL_DTYPE_VAR);

	curvar = (PLtsql_var *) estate->datums[stmt->curvar];
	Assert(is_cursor_datatype(curvar->datatype->typoid));
	if (!curvar->isconst)
		return PLTSQL_RC_OK; /* cursor variable. nothing to do here */

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
transform_tsql_temp_tables(char * dynstmt)
{
	StringInfoData ds;
	char		   *cp;
	char		   *word;
	char		   *prev_word;

	initStringInfo(&ds);
	prev_word = NULL;

	for (cp = dynstmt; *cp; cp++)
	{
		if (cp[0] == '#' && is_char_identstart(cp[1]))
		{
			/*
			 * Quote this local temporary table identifier.  next_word stops as
			 * soon as it encounters a non-ident character such as '#', we point
			 * it to the next character as the start of word while specifying
			 * the '#' prefix explicitly in the format string.
			 */
			word = next_word(cp+1);
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
	while (*++dyntext && scanner_isspace(*dyntext)); /* skip whitespace */

	return (dyntext[0] == '#' && is_char_identstart(dyntext[1]));
}

static bool
is_char_identstart(char c)
{
	return ((c == '_')             ||
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
	List	    *parsetree;
	List	    *params;
	ListCell    *lc;
	int	    i = 0;
	const char  *str1 = "CREATE PROC p_tmp_spexecutesql (";
	const char  *str2 = ") AS BEGIN END; DROP PROC p_tmp_spexecutesql;";
	char	    *proc_stmt;

	Assert(args);

	if (!paramdefstr)
	{
		args->numargs = 0;
		return;
	}

	/*
	 * Create a fake CREATE PROCEDURE statement to get the param
	 * definition parse tree.
	 */
	proc_stmt = palloc(strlen(paramdefstr) + strlen(str1) + strlen(str2) + 1);
	strcpy(proc_stmt, str1);
	strcat(proc_stmt, paramdefstr);
	strcat(proc_stmt, str2);

	parsetree = raw_parser(proc_stmt);
	
	/* 
	 * Seperate each param definition, and calculate the total number of
	 * definitions.
	 */
	params = ((CreateFunctionStmt *) (((RawStmt *) linitial(parsetree))->stmt))->parameters;

	args->numargs = list_length(params);
	args->argtypes = (Oid *) palloc(sizeof(Oid) * args->numargs);
	args->argtypmods = (int32 *) palloc(sizeof(int32) * args->numargs);
	args->argnames = (char **) palloc(sizeof(char *) * args->numargs);
	args->argmodes = (char *) palloc(sizeof(char) * args->numargs);

	foreach(lc, params)
	{
		FunctionParameter   *p;

		p = (FunctionParameter *) lfirst(lc);
		args->argnames[i] = p->name;
		args->argmodes[i] = p->mode;
		typenameTypeIdAndMod(NULL, p->argType, &(args->argtypes[i]), &(args->argtypmods[i]));
		i++;
	}
}

InlineCodeBlockArgs *create_args(int numargs)
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

void cache_inline_args(PLtsql_function *func, InlineCodeBlockArgs *args)
{
	MemoryContext oldcontext;

	/* keep arg def's life cycle same as tree */
	oldcontext = MemoryContextSwitchTo(func->fn_cxt);
	func->inline_args = clone_inline_args(args);
	MemoryContextSwitchTo(oldcontext);
}

InlineCodeBlockArgs *clone_inline_args(InlineCodeBlockArgs *args)
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
	ListCell	*lc;
	bool		*assigned;
	int		i = 0;
	int		j = 0;
	int		nfields = 0;
	int  	n_extra_args = fcinfo->nargs;

	/* 
	 * An array to record which parameters have already been given a value
	 */
	assigned = (bool *) palloc0(args->numargs * sizeof(bool));

	fcinfo->nargs += args->numargs;

	foreach(lc, params)
	{
		tsql_exec_param *p;
		Datum		paramval;
		Oid		restype;
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
				if (strcmp(p->name, args->argnames[j]) == 0)
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

static Node *get_underlying_node_from_implicit_casting(Node *n, NodeTag underlying_nodetype)
{
	FuncExpr* funcexpr = NULL;

	if (nodeTag(n) == underlying_nodetype)
		return n;

	if (IsA(n, FuncExpr))
		funcexpr = (FuncExpr *) n;
	else if (IsA(n, CoerceToDomain))
	{
		/* coerce-to-domain can be added before actual casting. It is already handled and we don't need this to handle output param. ignoring it.*/
		CoerceToDomain *c = (CoerceToDomain *) n;
		if (c->coercionformat == COERCE_IMPLICIT_CAST)
			return get_underlying_node_from_implicit_casting((Node *) c->arg, underlying_nodetype);
		else
			return NULL; /* not an implicit-casting. stop */
	}
	else if (IsA(n, CoerceViaIO))
	{
		/* no casting function. cocerce-via-io used instead */
		CoerceViaIO *c = (CoerceViaIO *) n;
		if (c->coerceformat == COERCE_IMPLICIT_CAST)
			return get_underlying_node_from_implicit_casting((Node *) c->arg, underlying_nodetype);
		else
			return NULL; /* not an implicit-casting. stop */
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
	 * up to two implict castings are nested consecutively.
	 * inner is about type casting (i.e. int4->numeric) and outer is for typmod handling (numeric->numeric with different typmod)
	 * check one-level more here
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
	char * old_db_name = get_cur_db_name();
	char message[128];
	int16 old_db_id = get_cur_db_id();
	int16 new_db_id = get_db_id(stmt->db_name);

	if (!DbidIsValid(new_db_id))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist", stmt->db_name)));

	/* Release the session-level shared lock on the old logical db */
	UnlockLogicalDatabaseForSession(old_db_id, ShareLock, false);

	/* Get a session-level shared lock on the new logical db we are about to use */
	if (!TryLockLogicalDatabaseForSession(new_db_id, ShareLock))
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Cannot use database \"%s\", failed to obtain lock. "
						"\"%s\" is probably undergoing DDL statements in another session.", 
						stmt->db_name, stmt->db_name)));

	set_session_properties(stmt->db_name);
	snprintf(message, sizeof(message), "Changed database context to '%s'.", stmt->db_name);
	/* send env change token to user */
	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_env_change)
		((*pltsql_protocol_plugin_ptr)->send_env_change) (1, stmt->db_name, old_db_name);
	/* send message to user */
	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
		((*pltsql_protocol_plugin_ptr)->send_info) (0, 1, 0, message, 0);
	return PLTSQL_RC_OK;
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

	tupmap = convert_tuples_by_position(portal->tupDesc,
										estate->tuple_store_desc,
										gettext_noop("structure of query does not match function result type"));

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
				tuple = execute_attr_map_tuple(tuple, tupmap);
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

int exec_stmt_insert_bulk(PLtsql_execstate *estate, PLtsql_stmt_insert_bulk *stmt)
{
	char *bulk_load_schema_name = NULL;
	MemoryContext	oldContext;
	Oid rel_oid = InvalidOid;
	Oid schema_oid = InvalidOid;

	if (!stmt->db_name || stmt->db_name[0] == '\0')
		stmt->db_name = get_cur_db_name();
	if (stmt->schema_name && stmt->db_name)
	{
		bulk_load_schema_name = get_physical_schema_name(stmt->db_name,
													   stmt->schema_name);
		schema_oid = LookupExplicitNamespace(bulk_load_schema_name, true);
		if (!OidIsValid(schema_oid))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_SCHEMA),
						errmsg("schema \"%s\" does not exist",
							stmt->schema_name)));
	}


	oldContext = MemoryContextSwitchTo(TopMemoryContext);

	/* save the table name for the next Bulk load Request */
	if (bulk_load_schema_name)
	{
		rel_oid = get_relname_relid(stmt->table_name, schema_oid);
		bulk_load_table_name = psprintf("\"%s\".\"%s\"", bulk_load_schema_name, stmt->table_name);
		pfree(bulk_load_schema_name);
	}
	else
	{
		rel_oid = RelnameGetRelid(stmt->table_name);
		bulk_load_table_name = pstrdup(stmt->table_name);
	}

	MemoryContextSwitchTo(oldContext);

	if (!OidIsValid(rel_oid))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_TABLE),
						errmsg("relation \"%s\" does not exist",
							stmt->table_name)));

	return PLTSQL_RC_OK;
}

int
execute_bulk_load_insert(int ncol, int nrow, Oid *argtypes,
				Datum *Values, const char *Nulls)
{
	int rc;
	int retValue = -1;
	StringInfo src = makeStringInfo();
	StringInfo bindParams = makeStringInfo();
	int count = 1;

	elog(DEBUG2, "Insert Bulk operation on destination table: %s", bulk_load_table_name);
	appendStringInfo(src, "Insert into %s values ", bulk_load_table_name);
	for (int i = 0; i < nrow; i++)
	{
		for (int j = 0; j < ncol; j++)
			appendStringInfo(bindParams, ",$%d", count++);

		bindParams->data[0] = ' ';
		appendStringInfo(src, "(%s),", bindParams->data);
		resetStringInfo(bindParams);
	}
	src->data[src->len - 1] = ' '; /* Taking care of the last ',' */

	set_config_option("babelfishpg_tsql.sql_dialect", "postgres",
						  (superuser() ? PGC_SUSET : PGC_USERSET),
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

	PushActiveSnapshot(GetTransactionSnapshot());

	PG_TRY();
	{
		if ((rc = SPI_connect()) < 0)
			elog(ERROR, "SPI_connect() failed with return code %d", rc);

		rc = SPI_execute_with_args(src->data,
				ncol * nrow, argtypes,
				Values, Nulls,
				false, 1);

		retValue = SPI_processed;

		SPI_finish();
		PopActiveSnapshot();

		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
									(superuser() ? PGC_SUSET :  PGC_USERSET),
										PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_CATCH();
	{
		MemoryContext oldcontext;
		SPI_finish();
		PopActiveSnapshot();
		oldcontext = CurrentMemoryContext;

		/*
		 * If a transaction block is already in progress then abort it,
		 * else rollback entire transaction.
		 */
		if (!IsTransactionBlockActive())
		{
			AbortCurrentTransaction();
			StartTransactionCommand();
		}
		else
			pltsql_rollback_txn();
		MemoryContextSwitchTo(oldcontext);

		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
									(superuser() ? PGC_SUSET : PGC_USERSET),
										PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		PG_RE_THROW();
	}
	PG_END_TRY();

	if (rc != SPI_OK_INSERT)
		ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
			errmsg("Failed to insert in the table %s for bulk load", bulk_load_table_name)));

	/* Cleanup all the pointers. */
	if (bulk_load_table_name)
		pfree(bulk_load_table_name);
	if (bindParams)
	{
		if (bindParams->data)
			pfree(bindParams->data);
		pfree(bindParams);
	}
	if (src)
	{
		if (src->data)
			pfree(src->data);
		pfree(src);
	}
	bulk_load_table_name = NULL;
	return retValue;
}

int
execute_plan_and_push_result(PLtsql_execstate *estate, PLtsql_expr *expr, ParamListInfo paramLI)
{
	Portal portal;
	bool success;
	uint64 processed = 0;
	DestReceiver *receiver;
	QueryCompletion qc;

	Assert(expr->plan != NULL); /* should be prepared already */
	portal = SPI_cursor_open_with_paramlist(NULL, expr->plan, paramLI, estate->readonly_func);

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
	ListCell	*lc;
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
		tsql_exec_param	*p;

		p = (tsql_exec_param *) lfirst(lc);
		(*modes)[i++] = p->mode;
	}
}
