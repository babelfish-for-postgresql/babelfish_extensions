#include "stmt_walker.h"
#include "miscadmin.h"

/***********************************************************************************
 *                              BASIC APIS
 **********************************************************************************/

bool
stmt_walker(PLtsql_stmt *stmt, WalkerFunc walker, void *context)
{
	ListCell   *s;

	if (!stmt)
		return false;

	check_stack_depth();

	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_BLOCK:
			{
				PLtsql_stmt_block *stmt_block = (PLtsql_stmt_block *) stmt;

				foreach(s, stmt_block->body)
					if (walker((PLtsql_stmt *) lfirst(s), context))
					return true;
				break;
			}
		case PLTSQL_STMT_ASSIGN:
			break;
		case PLTSQL_STMT_IF:
			{
				PLtsql_stmt_if *stmt_if = (PLtsql_stmt_if *) stmt;

				if (walker(stmt_if->then_body, context))
					return true;

				if (stmt_if->else_body &&
					walker(stmt_if->else_body, context))
					return true;

				break;
			}
		case PLTSQL_STMT_WHILE:
			{
				PLtsql_stmt_while *stmt_while = (PLtsql_stmt_while *) stmt;

				foreach(s, stmt_while->body)
					if (walker((PLtsql_stmt *) lfirst(s), context))
					return true;

				break;
			}
		case PLTSQL_STMT_EXIT:
		case PLTSQL_STMT_RETURN:
		case PLTSQL_STMT_RETURN_QUERY:
		case PLTSQL_STMT_EXECSQL:
		case PLTSQL_STMT_OPEN:
		case PLTSQL_STMT_FETCH:
		case PLTSQL_STMT_CLOSE:
		case PLTSQL_STMT_COMMIT:
		case PLTSQL_STMT_ROLLBACK:
			break;

			/* TSQL-only statement types follow */
		case PLTSQL_STMT_GOTO:
		case PLTSQL_STMT_PRINT:
			break;
		case PLTSQL_STMT_INIT:
			{
				PLtsql_stmt_init *stmt_init = (PLtsql_stmt_init *) stmt;

				foreach(s, stmt_init->inits)
					if (walker((PLtsql_stmt *) lfirst(s), context))
					return true;

				break;
			}
		case PLTSQL_STMT_QUERY_SET:
			break;
		case PLTSQL_STMT_TRY_CATCH:
			{
				PLtsql_stmt_try_catch *stmt_try_catch = (PLtsql_stmt_try_catch *) stmt;

				if (walker(stmt_try_catch->body, context))
					return true;

				if (walker(stmt_try_catch->handler, context))
					return true;

				break;
			}
		case PLTSQL_STMT_PUSH_RESULT:
		case PLTSQL_STMT_EXEC:
		case PLTSQL_STMT_EXEC_BATCH:
		case PLTSQL_STMT_EXEC_SP:
		case PLTSQL_STMT_DECL_TABLE:
		case PLTSQL_STMT_RETURN_TABLE:
		case PLTSQL_STMT_DEALLOCATE:
		case PLTSQL_STMT_DECL_CURSOR:
		case PLTSQL_STMT_LABEL:
		case PLTSQL_STMT_RAISERROR:
		case PLTSQL_STMT_THROW:
		case PLTSQL_STMT_USEDB:
		case PLTSQL_STMT_INSERT_BULK:
		case PLTSQL_STMT_SET_EXPLAIN_MODE:
		case PLTSQL_STMT_GRANTDB:
			break;
			/* TSQL-only executable node */
		case PLTSQL_STMT_SAVE_CTX:
		case PLTSQL_STMT_RESTORE_CTX_FULL:
		case PLTSQL_STMT_RESTORE_CTX_PARTIAL:
			/* no child child statement */
			break;
		default:
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("Unsupported statment type %s when adding child node",
								   pltsql_stmt_typename(stmt))));
	}
	return false;
}

/***********************************************************************************
 *                 General Walker Function and Template Context
 **********************************************************************************/

/* get template context */
Walker_context *
make_template_context(void)
{
	return palloc0(sizeof(Walker_context));
}

void
destroy_template_context(Walker_context *ctx)
{
	/* destroy extra context first */
	if (ctx->destroy_extra_ctx)
		ctx->destroy_extra_ctx(ctx->extra_ctx);

	pfree(ctx);
}

#define DISPATCH(T, f) \
    case PLTSQL_STMT_##T:\
    {\
        if (ctx->f##_act) \
            return ctx->f##_act(ctx, (PLtsql_stmt_##f *) stmt); \
        break; \
    }

/* dispatch each statement to its action defined in context */
bool
general_walker_func(PLtsql_stmt *stmt, void *context)
{
	Walker_context *ctx = (Walker_context *) context;

#if 1
	if (stmt == NULL)
		return false;
#endif

	switch (stmt->cmd_type)
	{
			DISPATCH(BLOCK, block)
				DISPATCH(ASSIGN, assign)
				DISPATCH(IF, if)
				DISPATCH(WHILE, while)
					DISPATCH(EXIT, exit)
						DISPATCH(RETURN, return)
						DISPATCH(RETURN_QUERY, return_query)
						DISPATCH(EXECSQL, execsql)
						DISPATCH(OPEN, open)
						DISPATCH(FETCH, fetch)
						DISPATCH(CLOSE, close)
						DISPATCH(COMMIT, commit)
						DISPATCH(ROLLBACK, rollback)

					/* TSQL-only statement types follow */
						DISPATCH(GOTO, goto)
						DISPATCH(PRINT, print)
						DISPATCH(INIT, init)
						DISPATCH(QUERY_SET, query_set)
						DISPATCH(TRY_CATCH, try_catch)
						DISPATCH(PUSH_RESULT, push_result)
						DISPATCH(EXEC, exec)
						DISPATCH(EXEC_BATCH, exec_batch)
						DISPATCH(EXEC_SP, exec_sp)
						DISPATCH(DECL_TABLE, decl_table)
		case PLTSQL_STMT_RETURN_TABLE:
				{
					if (ctx->return_table_act)
						return ctx->return_table_act(ctx, (PLtsql_stmt_return_query *) stmt);
					break;
				}
			DISPATCH(DEALLOCATE, deallocate)
				DISPATCH(DECL_CURSOR, decl_cursor)
				DISPATCH(LABEL, label)
				DISPATCH(RAISERROR, raiserror)
				DISPATCH(THROW, throw)
				DISPATCH(USEDB, usedb)
				DISPATCH(INSERT_BULK, insert_bulk)
				DISPATCH(SET_EXPLAIN_MODE, set_explain_mode)
				DISPATCH(GRANTDB, grantdb)

			/* TSQL-only executable node */
				DISPATCH(SAVE_CTX, save_ctx)
				DISPATCH(RESTORE_CTX_FULL, restore_ctx_full)
				DISPATCH(RESTORE_CTX_PARTIAL, restore_ctx_partial)
		default:
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported statment type %d", stmt->cmd_type)));
	}
	if (ctx->default_act)
		return ctx->default_act(ctx, stmt);

	return stmt_walker(stmt, general_walker_func, context);
}
