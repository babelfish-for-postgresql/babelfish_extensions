#include "postgres.h"

#include "catalog/pg_type.h"
#include "executor/spi.h"
#include "executor/spi_priv.h"
#include "funcapi.h"
#include "nodes/nodeFuncs.h"
#include "parser/parse_func.h"
#include "parser/parser.h"

#include "pltsql.h"
#include "pltsql-2.h"
#include "iterative_exec.h"
#include "multidb.h"

SPIPlanPtr prepare_stmt_execsql(PLtsql_execstate *estate, PLtsql_function *func,
								PLtsql_stmt_execsql *stmt, bool keepplan);
SPIPlanPtr prepare_stmt_exec(PLtsql_execstate *estate, PLtsql_function *func,
							PLtsql_stmt_exec *stmt, bool keepplan);

void exec_prepare_plan(PLtsql_execstate *estate, PLtsql_expr *expr, int cursorOptions, bool keepplan);
void exec_save_simple_expr(PLtsql_expr *expr, CachedPlan *cplan);
SPIPlanPtr prepare_exec_codes(PLtsql_function *func, ExecCodes *exec_codes);
void cleanup_temporal_plan(ExecCodes *exec_codes);

static void prepare_select_plan_for_scalar_func(PLtsql_execstate *estate, PLtsql_expr *expr,
												int first_arg_location, const char *new_params);
static bool is_exec_stmt_on_scalar_func(const char *stmt, int *first_arg_location, const char **new_params);
static char *rewrite_exec_scalar_func_params(const char *stmt, List *raw_parsetree_list, int first_arg_location);
static List* get_func_info_from_raw_parsetree(List *raw_parsetree_list, int* nargs,
											  bool* func_variadic, int* first_arg_location);
static void exec_simple_check_plan(PLtsql_execstate *estate, PLtsql_expr *expr);

extern void pltsql_estate_setup(PLtsql_execstate *estate, PLtsql_function *func,
					 			ReturnSetInfo *rsi, EState *simple_eval_estate);
extern void pltsql_destroy_econtext(PLtsql_execstate *estate);
extern void exec_eval_cleanup(PLtsql_execstate *estate);
extern void copy_pltsql_datums(PLtsql_execstate *estate, PLtsql_function *func);
extern void pltsql_estate_cleanup(void);
/*
 * On the first call for this statement generate the plan, and detect
 * whether the statement is INSERT/UPDATE/DELETE
 */
SPIPlanPtr 
prepare_stmt_execsql(PLtsql_execstate *estate, PLtsql_function *func, PLtsql_stmt_execsql *stmt, bool keepplan)
{
	PLtsql_expr *expr = stmt->sqlstmt;
	ListCell   *l;

	exec_prepare_plan(estate, expr, CURSOR_OPT_PARALLEL_OK, keepplan);
	stmt->mod_stmt = false;
	foreach(l, SPI_plan_get_plan_sources(expr->plan))
	{
		CachedPlanSource *plansource = (CachedPlanSource *) lfirst(l);
		if (IsA(plansource->raw_parse_tree->stmt, TransactionStmt))
		{
			pltsql_eval_txn_data(estate, stmt, plansource);
			break;
		}

		/*
		 * We could look at the raw_parse_tree, but it seems simpler to
		 * check the command tag.  Note we should *not* look at the Query
		 * tree(s), since those are the result of rewriting and could have
		 * been transmogrified into something else entirely.
		 */
		if (plansource->commandTag &&
			(plansource->commandTag == CMDTAG_INSERT ||
			 plansource->commandTag == CMDTAG_UPDATE ||
			 plansource->commandTag == CMDTAG_DELETE))
		{
			ListCell 	*lc;
			int 		n;
			PLtsql_tbl 	*tbl;
			const char 	*relname;

			stmt->mod_stmt = true;

			/* Check if the statement's relation is a table variable */
			switch(nodeTag(plansource->raw_parse_tree->stmt))
			{
				case T_InsertStmt:
					relname = ((InsertStmt *)plansource->raw_parse_tree->stmt)->relation->relname;
					break;
				case T_UpdateStmt:
					relname = ((UpdateStmt *)plansource->raw_parse_tree->stmt)->relation->relname;
					break;
				case T_DeleteStmt:
					relname = ((DeleteStmt *)plansource->raw_parse_tree->stmt)->relation->relname;
					break;
				default:
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							 errmsg("unexpected parse node type: %d",
								 	(int) nodeTag(plansource->raw_parse_tree->stmt))));
					break;
			}

			/* estate not set up, or not a table variable */
			if (!estate || strncmp(relname, "@", 1) != 0)
				break;
			foreach (lc, estate->func->table_varnos)
			{
				n = lfirst_int(lc);
				if (estate->datums[n]->dtype != PLTSQL_DTYPE_TBL)
					continue;

				tbl = (PLtsql_tbl *) estate->datums[n];
				if (strcmp(relname, tbl->refname) == 0)
				{
					stmt->mod_stmt_tablevar = true;
					break;
				}
			}

			break;
		}
	}

	return expr->plan;
}

SPIPlanPtr 
prepare_stmt_exec(PLtsql_execstate *estate, PLtsql_function *func, PLtsql_stmt_exec *stmt, bool keepplan)
{
	int first_arg_location;
	const char *new_params = NULL;
	PLtsql_expr *expr = stmt->expr;

	if (is_exec_stmt_on_scalar_func(expr->query, &first_arg_location, &new_params))
	{
		prepare_select_plan_for_scalar_func(estate, expr, first_arg_location, new_params);
	}
	else
	{
		/*
		* Don't save the plan if not in atomic context.  Otherwise,
		* transaction ends would cause errors about plancache leaks.
		*
		* XXX This would be fixable with some plancache/resowner surgery
		* elsewhere, but for now we'll just work around this here.
		*/
		exec_prepare_plan(estate, expr, 0, keepplan);
	}

	/*
	 * The procedure call could end transactions, which would upset
	 * the snapshot management in SPI_execute*, so don't let it do it.
	 * Instead, we set the snapshots ourselves below.
	 */
	expr->plan->no_snapshots = true;

	/*
	 * Force target to be recalculated whenever the plan changes, in
	 * case the procedure's argument list has changed.
	 */
	stmt->target = NULL;

	return expr->plan;
}

static bool
is_exec_stmt_on_scalar_func(const char *stmt, int *first_arg_location, const char **new_params)
{
	List *raw_parsetree_list;
	List *funcname;
	int nargs;
	bool func_variadic;
	Oid arg_types[FUNC_MAX_ARGS];
	FuncDetailCode fdresult;
	Oid funcid;
	Oid rettype; /* not used */
	bool retset; /* not used */
	int nvargs; /* not used */
	Oid vatype; /* not used */
	Oid *typeids; /* not used */
	int i;

	/* Stmt should be syntactically vaild since it was verified during compiliation */
	raw_parsetree_list = raw_parser(stmt);
	funcname = get_func_info_from_raw_parsetree(raw_parsetree_list, &nargs, &func_variadic, first_arg_location);

	if (!funcname)
		return false;

	for (i = 0; i < nargs; ++i)
	{
		/* We really don't care of the exact argument datatypes */
		arg_types[i] = UNKNOWNOID;
	}

	fdresult = func_get_detail(funcname,
	                           NIL, NIL,
	                           nargs, arg_types,
	                           func_variadic, true,
	                           &funcid, &rettype, &retset,
	                           &nvargs, &vatype,
	                           &typeids, NULL);

	if (fdresult != FUNCDETAIL_NORMAL)
		return false;

	if (get_func_result_type(funcid, NULL, NULL) != TYPEFUNC_SCALAR)
		return false;

	if (nargs > 0)
		*new_params = rewrite_exec_scalar_func_params(stmt, raw_parsetree_list, *first_arg_location);

	return true;
}

static List*
get_func_info_from_raw_parsetree(List *raw_parsetree_list, int* nargs, bool* func_variadic, int* first_arg_location)
{
	RawStmt *rstmt;
	CallStmt *cstmt;
	FuncCall *funccall;

	if (!raw_parsetree_list)
		return NIL;
	if (list_length(raw_parsetree_list) != 1)
		return NIL;

	rstmt = (RawStmt *) linitial(raw_parsetree_list);
	if (!rstmt)
		return NIL;
	if (!rstmt->stmt)
		return NIL;
	if (!IsA(rstmt->stmt, CallStmt))
		return NIL;

	cstmt = (CallStmt *) rstmt->stmt;
	if (!cstmt->funccall)
		return NIL;

	/* resolve crossdb reference */
	if (enable_schema_mapping())
		rewrite_object_refs(rstmt->stmt);

	funccall = cstmt->funccall;

	if (nargs)
		*nargs = list_length(funccall->args);
	if (func_variadic)
		*func_variadic = funccall->func_variadic;

	Assert(first_arg_location != NULL);
	if (*nargs > 0)
		*first_arg_location = exprLocation((Node *) linitial(funccall->args));
	else
		*first_arg_location = -1;

	return funccall->funcname;
}

/*
 * When dealing with EXEC on scalar function, we will later rewrite it to a
 * SELECT on the scalar function before passing to the main parser. There are
 * differences in syntax when passing arguments between EXEC and SELECT. For
 * example, EXEC allows "<param1> = <value1>, <param2> = <value2>", whereas
 * SELECT only allows ":=" or "=>" for such.
 *
 * This function returns the rewritten parameters portion of the stmt, or
 * NULL if no rewriting is necessary.
 */
static char *
rewrite_exec_scalar_func_params(const char *stmt, List *raw_parsetree_list, int first_arg_location)
{
	ListCell 		*lc;
	RawStmt 		*rstmt;
	CallStmt 		*cstmt;
	FuncCall 		*funccall;
	StringInfoData	dest;
	int 			prev = first_arg_location;

	if (first_arg_location == -1)
		return NULL;

	rstmt = (RawStmt *) linitial(raw_parsetree_list);
	if (!rstmt)
		return NULL;
	if (!rstmt->stmt)
		return NULL;
	if (!IsA(rstmt->stmt, CallStmt))
		return NULL;

	cstmt = (CallStmt *) rstmt->stmt;
	if (!cstmt->funccall)
		return NULL;

	initStringInfo(&dest);
	funccall = cstmt->funccall;
	foreach (lc, funccall->args)
	{
		Node *expr = lfirst(lc);
		switch(nodeTag(expr))
		{
			case T_NamedArgExpr:
				{
					/*
					 * For NamedArgExpr we want to rewrite it from
					 * "<name> = <arg>"
					 * to
					 * "<name> => <arg>"
					 */
					const NamedArgExpr *na = (const NamedArgExpr *) expr;
					/*
					 * Append the part of stmt appearing before the NamedArgExpr
					 * that we haven't inserted already.
					 */
					appendBinaryStringInfo(&dest, &(stmt[prev]),
										   na->location - prev);
					appendStringInfo(&dest, "\"%s\" => ", na->name);
					prev = exprLocation((Node *) na->arg);
				}
				break;
			default:
				break;
		}
	}

	if (prev == first_arg_location) /* no NamedArgExpr found */
		return NULL;

	appendStringInfoString(&dest, &(stmt[prev]));
	return dest.data;
}

static void
prepare_select_plan_for_scalar_func(PLtsql_execstate *estate, PLtsql_expr *expr, int first_arg_location, const char *new_params)
{
	StringInfoData new_query;
	char *saved_expr_query;
	const char *start_command = "EXEC";

	/* expr->query should start with EXEC */
	Assert(strlen(start_command) < strlen(expr->query));
	Assert(strstr(expr->query, start_command) == expr->query);

	initStringInfo(&new_query);
	if (first_arg_location >= 0)
		if (new_params)
			appendStringInfo(&new_query, "SELECT %.*s (%s )", first_arg_location - (int) strlen(start_command), expr->query + strlen(start_command), new_params);
		else
			appendStringInfo(&new_query, "SELECT %.*s (%s )", first_arg_location - (int) strlen(start_command), expr->query + strlen(start_command), expr->query + first_arg_location);
	else
		appendStringInfo(&new_query, "SELECT %s ()", expr->query + strlen(start_command));

	/* Now we got SELECT statement. Replace query string temporarily and prepare a SELECT plan */
	saved_expr_query = expr->query;
	expr->query = new_query.data;

	/* 'SELECT udf' will use simple_expr path. pass keepplan with true */
	exec_prepare_plan(estate, expr, 0, true);

	expr->query = saved_expr_query;
}
/* ----------
 * Generate a prepared plan
 * ----------
 */
void
exec_prepare_plan(PLtsql_execstate *estate,
				  PLtsql_expr *expr, int cursorOptions,
				  bool keepplan)
{
	SPIPlanPtr	plan;

	/*
	 * The grammar can't conveniently set expr->func while building the parse
	 * tree, so make sure it's set before parser hooks need it.
	 */
	expr->func = estate->func;

	/*
	 * Generate and save the plan
	 */
	plan = SPI_prepare_params(expr->query,
							  (ParserSetupHook) pltsql_parser_setup,
							  (void *) expr,
							  cursorOptions);
	if (plan == NULL)
		elog(ERROR, "SPI_prepare_params failed for \"%s\": %s",
			 expr->query, SPI_result_code_string(SPI_result));
	if (keepplan)
		SPI_keepplan(plan);
	expr->plan = plan;

	/* Check to see if it's a simple expression */
	/* Skip simple expression checking when estate is not available during SP_PREPARE call */
	exec_simple_check_plan(estate, expr);

	/*
	 * Mark expression as not using a read-write param.  exec_assign_value has
	 * to take steps to override this if appropriate; that seems cleaner than
	 * adding parameters to all other callers.
	 */
	expr->rwparam = -1;
}

/* ----------
 * exec_simple_check_plan -		Check if a plan is simple enough to
 *								be evaluated by ExecEvalExpr() instead
 *								of SPI.
 * ----------
 */
static void
exec_simple_check_plan(PLtsql_execstate *estate, PLtsql_expr *expr)
{
	List	   *plansources;
	CachedPlanSource *plansource;
	Query	   *query;
	CachedPlan *cplan;
	MemoryContext oldcontext;

	/*
	 * Initialize to "not simple".
	 */
	expr->expr_simple_expr = NULL;

	/*
	 * Check the analyzed-and-rewritten form of the query to see if we will be
	 * able to treat it as a simple expression.  Since this function is only
	 * called immediately after creating the CachedPlanSource, we need not
	 * worry about the query being stale.
	 */

	/*
	 * We can only test queries that resulted in exactly one CachedPlanSource
	 */
	plansources = SPI_plan_get_plan_sources(expr->plan);
	if (list_length(plansources) != 1)
		return;
	plansource = (CachedPlanSource *) linitial(plansources);

	/*
	 * 1. There must be one single querytree.
	 */
	if (list_length(plansource->query_list) != 1)
		return;
	query = (Query *) linitial(plansource->query_list);

	/*
	 * 2. It must be a plain SELECT query without any input tables
	 */
	if (!IsA(query, Query))
		return;
	if (query->commandType != CMD_SELECT)
		return;
	if (query->rtable != NIL)
		return;

	/*
	 * 3. Can't have any subplans, aggregates, qual clauses either.  (These
	 * tests should generally match what inline_function() checks before
	 * inlining a SQL function; otherwise, inlining could change our
	 * conclusion about whether an expression is simple, which we don't want.)
	 */
	if (query->hasAggs ||
		query->hasWindowFuncs ||
		query->hasTargetSRFs ||
		query->hasSubLinks ||
		query->cteList ||
		query->jointree->fromlist ||
		query->jointree->quals ||
		query->groupClause ||
		query->groupingSets ||
		query->havingQual ||
		query->windowClause ||
		query->distinctClause ||
		query->sortClause ||
		query->limitOffset ||
		query->limitCount ||
		query->setOperations)
		return;

	/*
	 * 4. The query must have a single attribute as result
	 */
	if (list_length(query->targetList) != 1)
		return;

	/*
	 * OK, we can treat it as a simple plan.
	 *
	 * Get the generic plan for the query.  If replanning is needed, do that
	 * work in the eval_mcontext.
	 */
	oldcontext = MemoryContextSwitchTo((estate)->eval_econtext->ecxt_per_tuple_memory);
	cplan = SPI_plan_get_cached_plan(expr->plan);
	MemoryContextSwitchTo(oldcontext);

	/* Can't fail, because we checked for a single CachedPlanSource above */
	Assert(cplan != NULL);

	/* Share the remaining work with replan code path */
	exec_save_simple_expr(expr, cplan);

	/* Release our plan refcount */
	ReleaseCachedPlan(cplan, true);
}

/*
 * exec_save_simple_expr --- extract simple expression from CachedPlan
 */
void
exec_save_simple_expr(PLtsql_expr *expr, CachedPlan *cplan)
{
	PlannedStmt *stmt;
	Plan	   *plan;
	Expr	   *tle_expr;

	/*
	 * Given the checks that exec_simple_check_plan did, none of the Asserts
	 * here should ever fail.
	 */

	/* Extract the single PlannedStmt */
	Assert(list_length(cplan->stmt_list) == 1);
	stmt = linitial_node(PlannedStmt, cplan->stmt_list);
	Assert(stmt->commandType == CMD_SELECT);

	/*
	 * Ordinarily, the plan node should be a simple Result.  However, if
	 * force_parallel_mode is on, the planner might've stuck a Gather node
	 * atop that.  The simplest way to deal with this is to look through the
	 * Gather node.  The Gather node's tlist would normally contain a Var
	 * referencing the child node's output, but it could also be a Param, or
	 * it could be a Const that setrefs.c copied as-is.
	 */
	plan = stmt->planTree;
	for (;;)
	{
		/* Extract the single tlist expression */
		Assert(list_length(plan->targetlist) == 1);
		tle_expr = castNode(TargetEntry, linitial(plan->targetlist))->expr;

		if (IsA(plan, Result))
		{
			Assert(plan->lefttree == NULL &&
				   plan->righttree == NULL &&
				   plan->initPlan == NULL &&
				   plan->qual == NULL &&
				   ((Result *) plan)->resconstantqual == NULL);
			break;
		}
		else if (IsA(plan, Gather))
		{
			Assert(plan->lefttree != NULL &&
				   plan->righttree == NULL &&
				   plan->initPlan == NULL &&
				   plan->qual == NULL);
			/* If setrefs.c copied up a Const, no need to look further */
			if (IsA(tle_expr, Const))
				break;
			/* Otherwise, it had better be a Param or an outer Var */
			Assert(IsA(tle_expr, Param) ||(IsA(tle_expr, Var) &&
										   ((Var *) tle_expr)->varno == OUTER_VAR));
			/* Descend to the child node */
			plan = plan->lefttree;
		}
		else
			elog(ERROR, "unexpected plan node type: %d",
				 (int) nodeTag(plan));
	}

	/*
	 * Save the simple expression, and initialize state to "not valid in
	 * current transaction".
	 */
	expr->expr_simple_expr = tle_expr;
	expr->expr_simple_generation = cplan->generation;
	expr->expr_simple_state = NULL;
	expr->expr_simple_in_use = false;
	expr->expr_simple_lxid = InvalidLocalTransactionId;
	/* Also stash away the expression result type */
	expr->expr_simple_type = exprType((Node *) tle_expr);
	expr->expr_simple_typmod = exprTypmod((Node *) tle_expr);
}

SPIPlanPtr prepare_exec_codes(PLtsql_function *func, ExecCodes *exec_codes)
{
	PLtsql_stmt *stmt;
	PLtsql_execstate estate;
	SPIPlanPtr plan = NULL;
	
	if (vec_size(exec_codes->codes) != 3)
		return false;

	/* stmt 3 */
	stmt = *(PLtsql_stmt **) vec_at(exec_codes->codes, 2);
	if (stmt->cmd_type != PLTSQL_STMT_GOTO)
		return false;

	/* stmt 2 */
	stmt = *(PLtsql_stmt **) vec_at(exec_codes->codes, 1);
	if (stmt->cmd_type != PLTSQL_STMT_RETURN)
		return false;

	/* stmt 1 */
	stmt = *(PLtsql_stmt **) vec_at(exec_codes->codes, 0);
	switch(stmt->cmd_type)
	{
		case PLTSQL_STMT_EXECSQL:
		{
			pltsql_estate_setup(&estate, func, NULL, NULL);
			copy_pltsql_datums(&estate, func);
			PG_TRY();
			{
				plan = prepare_stmt_execsql(&estate, func, (PLtsql_stmt_execsql *) stmt, true);
				/* Clean up any leftover temporary memory */
				pltsql_destroy_econtext(&estate);
				exec_eval_cleanup(&estate);
			}
			PG_CATCH();
			{
				pltsql_estate_cleanup();
				PG_RE_THROW();
			}
			PG_END_TRY();
			pltsql_estate_cleanup();
			break;
		}
		case PLTSQL_STMT_EXEC:
		{
			pltsql_estate_setup(&estate, func, NULL, NULL);
			copy_pltsql_datums(&estate, func);
			PG_TRY();
			{
				plan = prepare_stmt_exec(&estate, func, (PLtsql_stmt_exec *) stmt, false);
				/* Clean up any leftover temporary memory */
				pltsql_destroy_econtext(&estate);
				exec_eval_cleanup(&estate);
			}
			PG_CATCH();
			{
				pltsql_estate_cleanup();
				PG_RE_THROW();
			}
			PG_END_TRY();
			pltsql_estate_cleanup();
			break;
		}
		case PLTSQL_STMT_PUSH_RESULT:
		{
			PLtsql_stmt_push_result *push_result = (PLtsql_stmt_push_result *) stmt;
			pltsql_estate_setup(&estate, func, NULL, NULL);
			copy_pltsql_datums(&estate, func);
			PG_TRY();
			{
				exec_prepare_plan(&estate, push_result->query, 0, true);
				plan = push_result->query->plan;
				/* Clean up any leftover temporary memory */
				pltsql_destroy_econtext(&estate);
				exec_eval_cleanup(&estate);
			}
			PG_CATCH();
			{
				pltsql_estate_cleanup();
				PG_RE_THROW();
			}
			PG_END_TRY();

			pltsql_estate_cleanup();
			break;
		}
		default:
			break;
	}
	return plan;
}

void cleanup_temporal_plan(ExecCodes *exec_codes)
{
	PLtsql_stmt *stmt;
	stmt = *(PLtsql_stmt **) vec_at(exec_codes->codes, 0);
	if (stmt->cmd_type == PLTSQL_STMT_EXEC)
	{
		PLtsql_stmt_exec *stmt_exec = (PLtsql_stmt_exec *) stmt;
		if (stmt_exec->expr->plan && !stmt_exec->expr->plan->saved)
			stmt_exec->expr->plan = NULL;
	}
}
