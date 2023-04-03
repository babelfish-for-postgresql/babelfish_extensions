/*-------------------------------------------------------------------------
 *
 * pl_funcs.c		- Misc functions for the PL/tsql
 *			  procedural language
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/pl/pltsql/src/pl_funcs.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "utils/memutils.h"

#include "pltsql.h"

#include "pl_funcs-2.h"
#include "iterative_exec.h"

/* ----------
 * Local variables for namespace handling
 *
 * The namespace structure actually forms a tree, of which only one linear
 * list or "chain" (from the youngest item to the root) is accessible from
 * any one pltsql statement.  During initial parsing of a function, ns_top
 * points to the youngest item accessible from the block currently being
 * parsed.  We store the entire tree, however, since at runtime we will need
 * to access the chain that's relevant to any one statement.
 *
 * Block boundaries in the namespace chain are marked by PLTSQL_NSTYPE_LABEL
 * items.
 * ----------
 */
static PLtsql_nsitem *ns_top = NULL;


/* ----------
 * pltsql_ns_init			Initialize namespace processing for a new function
 * ----------
 */
void
pltsql_ns_init(void)
{
	ns_top = NULL;
}


/* ----------
 * pltsql_ns_push			Create a new namespace level
 * ----------
 */
void
pltsql_ns_push(const char *label, PLtsql_label_type label_type)
{
	if (label == NULL)
		label = "";
	pltsql_ns_additem(PLTSQL_NSTYPE_LABEL, (int) label_type, label);
}


/* ----------
 * pltsql_ns_pop			Pop entries back to (and including) the last label
 * ----------
 */
void
pltsql_ns_pop(void)
{
	Assert(ns_top != NULL);
	while (ns_top->itemtype != PLTSQL_NSTYPE_LABEL)
		ns_top = ns_top->prev;
	ns_top = ns_top->prev;
}


/* ----------
 * pltsql_ns_top			Fetch the current namespace chain end
 * ----------
 */
PLtsql_nsitem *
pltsql_ns_top(void)
{
	return ns_top;
}


/* ----------
 * pltsql_ns_additem		Add an item to the current namespace chain
 * ----------
 */
void
pltsql_ns_additem(PLtsql_nsitem_type itemtype, int itemno, const char *name)
{
	PLtsql_nsitem *nse;

	Assert(name != NULL);
	/* first item added must be a label */
	Assert(ns_top != NULL || itemtype == PLTSQL_NSTYPE_LABEL);

	nse = palloc0(offsetof(PLtsql_nsitem, name) + strlen(name) + 1);
	nse->itemtype = itemtype;
	nse->itemno = itemno;
	nse->prev = ns_top;
	memcpy(nse->name, name, strlen(name));
	ns_top = nse;
}


/* ----------
 * pltsql_ns_lookup		Lookup an identifier in the given namespace chain
 *
 * Note that this only searches for variables, not labels.
 *
 * If localmode is true, only the topmost block level is searched.
 *
 * name1 must be non-NULL.  Pass NULL for name2 and/or name3 if parsing a name
 * with fewer than three components.
 *
 * If names_used isn't NULL, *names_used receives the number of names
 * matched: 0 if no match, 1 if name1 matched an unqualified variable name,
 * 2 if name1 and name2 matched a block label + variable name.
 *
 * Note that name3 is never directly matched to anything.  However, if it
 * isn't NULL, we will disregard qualified matches to scalar variables.
 * Similarly, if name2 isn't NULL, we disregard unqualified matches to
 * scalar variables.
 * ----------
 */
PLtsql_nsitem *
pltsql_ns_lookup(PLtsql_nsitem *ns_cur, bool localmode,
				 const char *name1, const char *name2, const char *name3,
				 int *names_used)
{
	/* Outer loop iterates once per block level in the namespace chain */
	while (ns_cur != NULL)
	{
		PLtsql_nsitem *nsitem;

		/* Check this level for unqualified match to variable name */
		for (nsitem = ns_cur;
			 nsitem->itemtype != PLTSQL_NSTYPE_LABEL;
			 nsitem = nsitem->prev)
		{
			if (pg_strcasecmp(nsitem->name, name1) == 0)
			{
				if (name2 == NULL ||
					nsitem->itemtype != PLTSQL_NSTYPE_VAR)
				{
					if (names_used)
						*names_used = 1;
					return nsitem;
				}
			}
		}

		/* Check this level for qualified match to variable name */
		if (name2 != NULL &&
			strcmp(nsitem->name, name1) == 0)
		{
			for (nsitem = ns_cur;
				 nsitem->itemtype != PLTSQL_NSTYPE_LABEL;
				 nsitem = nsitem->prev)
			{
				if (pg_strcasecmp(nsitem->name, name2) == 0)
				{
					if (name3 == NULL ||
						nsitem->itemtype != PLTSQL_NSTYPE_VAR)
					{
						if (names_used)
							*names_used = 2;
						return nsitem;
					}
				}
			}
		}

		if (localmode)
			break;				/* do not look into upper levels */

		ns_cur = nsitem->prev;
	}

	/* This is just to suppress possibly-uninitialized-variable warnings */
	if (names_used)
		*names_used = 0;
	return NULL;				/* No match found */
}


/* ----------
 * pltsql_ns_lookup_label		Lookup a label in the given namespace chain
 * ----------
 */
PLtsql_nsitem *
pltsql_ns_lookup_label(PLtsql_nsitem *ns_cur, const char *name)
{
	while (ns_cur != NULL)
	{
		if (ns_cur->itemtype == PLTSQL_NSTYPE_LABEL &&
			strcmp(ns_cur->name, name) == 0)
			return ns_cur;
		ns_cur = ns_cur->prev;
	}

	return NULL;				/* label not found */
}


/* ----------
 * pltsql_ns_find_nearest_loop		Find innermost loop label in namespace chain
 * ----------
 */
PLtsql_nsitem *
pltsql_ns_find_nearest_loop(PLtsql_nsitem *ns_cur)
{
	while (ns_cur != NULL)
	{
		if (ns_cur->itemtype == PLTSQL_NSTYPE_LABEL &&
			ns_cur->itemno == PLTSQL_LABEL_LOOP)
			return ns_cur;
		ns_cur = ns_cur->prev;
	}

	return NULL;				/* no loop found */
}


/*
 * Statement type as a string, for use in error messages etc.
 */
const char *
pltsql_stmt_typename(PLtsql_stmt *stmt)
{
	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_BLOCK:
			return _("statement block");
		case PLTSQL_STMT_ASSIGN:
			return _("assignment");
		case PLTSQL_STMT_IF:
			return "IF";
		case PLTSQL_STMT_CASE:
			return "CASE";
		case PLTSQL_STMT_LOOP:
			return "LOOP";
		case PLTSQL_STMT_WHILE:
			return "WHILE";
		case PLTSQL_STMT_FORI:
			return _("FOR with integer loop variable");
		case PLTSQL_STMT_FORS:
			return _("FOR over SELECT rows");
		case PLTSQL_STMT_FORC:
			return _("FOR over cursor");
		case PLTSQL_STMT_FOREACH_A:
			return _("FOREACH over array");
		case PLTSQL_STMT_EXIT:
			return ((PLtsql_stmt_exit *) stmt)->is_exit ? "EXIT" : "CONTINUE";
		case PLTSQL_STMT_RETURN:
			return "RETURN";
		case PLTSQL_STMT_RETURN_NEXT:
			return "RETURN NEXT";
		case PLTSQL_STMT_RETURN_QUERY:
			return "RETURN QUERY";
		case PLTSQL_STMT_RAISE:
			return "RAISE";
		case PLTSQL_STMT_ASSERT:
			return "ASSERT";
		case PLTSQL_STMT_EXECSQL:
			return _("SQL statement");
		case PLTSQL_STMT_DYNEXECUTE:
			return "EXECUTE";
		case PLTSQL_STMT_DYNFORS:
			return _("FOR over EXECUTE statement");
		case PLTSQL_STMT_GETDIAG:
			return ((PLtsql_stmt_getdiag *) stmt)->is_stacked ?
				"GET STACKED DIAGNOSTICS" : "GET DIAGNOSTICS";
		case PLTSQL_STMT_OPEN:
			return "OPEN";
		case PLTSQL_STMT_FETCH:
			return ((PLtsql_stmt_fetch *) stmt)->is_move ? "MOVE" : "FETCH";
		case PLTSQL_STMT_CLOSE:
			return "CLOSE";
		case PLTSQL_STMT_PERFORM:
			return "PERFORM";
		case PLTSQL_STMT_CALL:
			return ((PLtsql_stmt_call *) stmt)->is_call ? "CALL" : "DO";
		case PLTSQL_STMT_COMMIT:
			return "COMMIT";
		case PLTSQL_STMT_ROLLBACK:
			return "ROLLBACK";
		case PLTSQL_STMT_SET:
			return "SET";

			/* TSQL-only statement types follow */
		case PLTSQL_STMT_GOTO:
			return "GOTO";
		case PLTSQL_STMT_PRINT:
			return "PRINT";
		case PLTSQL_STMT_INIT:
			return "(init)";
		case PLTSQL_STMT_QUERY_SET:
			return "SELECT-SET";
		case PLTSQL_STMT_TRY_CATCH:
			return "TRY_CATCH";
		case PLTSQL_STMT_PUSH_RESULT:
			return "PUSH_RESULT";
		case PLTSQL_STMT_EXEC:
			return "EXEC";
		case PLTSQL_STMT_EXEC_BATCH:
			return "EXEC_BATCH";
		case PLTSQL_STMT_EXEC_SP:
			return "EXEC_SP";
		case PLTSQL_STMT_DECL_TABLE:
			return "DECLARE TABLE VARIABLE";
		case PLTSQL_STMT_RETURN_TABLE:
			return "RETURN TABLE VARIABLE";
		case PLTSQL_STMT_DEALLOCATE:
			return "DEALLOCATE";
		case PLTSQL_STMT_DECL_CURSOR:
			return "DECLARE CURSOR";
		case PLTSQL_STMT_LABEL:
			return "LABEL";
		case PLTSQL_STMT_RAISERROR:
			return "RAISERROR";
		case PLTSQL_STMT_THROW:
			return "THROW";
		case PLTSQL_STMT_USEDB:
			return "USE";
		case PLTSQL_STMT_INSERT_BULK:
			return "INSERT BULK";
		case PLTSQL_STMT_SET_EXPLAIN_MODE:
			return "SET EXPLAIN MODE";
		case PLTSQL_STMT_GRANTDB:
			return ((PLtsql_stmt_grantdb *) stmt)->is_grant ?
				"GRANT CONNECT TO" : "REVOKE CONNECT FROM";
			/* TSQL-only executable node */
		case PLTSQL_STMT_SAVE_CTX:
			return "SAVE_CONTEXT";
		case PLTSQL_STMT_RESTORE_CTX_FULL:
			return "RESTORE_CONTEXT_FULL";
		case PLTSQL_STMT_RESTORE_CTX_PARTIAL:
			return "RESTORE_CONTEXT_PARTIAL";
		default:
			return "Add try catch";
	}

	return "unknown";
}

/*
 * GET DIAGNOSTICS item name as a string, for use in error messages etc.
 */
const char *
pltsql_getdiag_kindname(PLtsql_getdiag_kind kind)
{
	switch (kind)
	{
		case PLTSQL_GETDIAG_ROW_COUNT:
			return "ROW_COUNT";
		case PLTSQL_GETDIAG_RESULT_OID:
			return "RESULT_OID";
		case PLTSQL_GETDIAG_CONTEXT:
			return "PG_CONTEXT";
		case PLTSQL_GETDIAG_ERROR_CONTEXT:
			return "PG_EXCEPTION_CONTEXT";
		case PLTSQL_GETDIAG_ERROR_DETAIL:
			return "PG_EXCEPTION_DETAIL";
		case PLTSQL_GETDIAG_ERROR_HINT:
			return "PG_EXCEPTION_HINT";
		case PLTSQL_GETDIAG_RETURNED_SQLSTATE:
			return "RETURNED_SQLSTATE";
		case PLTSQL_GETDIAG_COLUMN_NAME:
			return "COLUMN_NAME";
		case PLTSQL_GETDIAG_CONSTRAINT_NAME:
			return "CONSTRAINT_NAME";
		case PLTSQL_GETDIAG_DATATYPE_NAME:
			return "PG_DATATYPE_NAME";
		case PLTSQL_GETDIAG_MESSAGE_TEXT:
			return "MESSAGE_TEXT";
		case PLTSQL_GETDIAG_TABLE_NAME:
			return "TABLE_NAME";
		case PLTSQL_GETDIAG_SCHEMA_NAME:
			return "SCHEMA_NAME";
	}

	return "unknown";
}


/**********************************************************************
 * Release memory when a PL/tsql function is no longer needed
 *
 * The code for recursing through the function tree is really only
 * needed to locate PLtsql_expr nodes, which may contain references
 * to saved SPI Plans that must be freed.  The function tree itself,
 * along with subsidiary data, is freed in one swoop by freeing the
 * function's permanent memory context.
 **********************************************************************/
static void free_stmt(PLtsql_stmt *stmt);
static void free_block(PLtsql_stmt_block *block);
static void free_assign(PLtsql_stmt_assign *stmt);
static void free_if(PLtsql_stmt_if *stmt);
static void free_case(PLtsql_stmt_case *stmt);
static void free_loop(PLtsql_stmt_loop *stmt);
static void free_while(PLtsql_stmt_while *stmt);
static void free_fori(PLtsql_stmt_fori *stmt);
static void free_fors(PLtsql_stmt_fors *stmt);
static void free_forc(PLtsql_stmt_forc *stmt);
static void free_foreach_a(PLtsql_stmt_foreach_a *stmt);
static void free_exit(PLtsql_stmt_exit *stmt);
static void free_return(PLtsql_stmt_return *stmt);
static void free_return_next(PLtsql_stmt_return_next *stmt);
static void free_return_query(PLtsql_stmt_return_query *stmt);
static void free_raise(PLtsql_stmt_raise *stmt);
static void free_assert(PLtsql_stmt_assert *stmt);
static void free_execsql(PLtsql_stmt_execsql *stmt);
static void free_dynexecute(PLtsql_stmt_dynexecute *stmt);
static void free_dynfors(PLtsql_stmt_dynfors *stmt);
static void free_getdiag(PLtsql_stmt_getdiag *stmt);
static void free_open(PLtsql_stmt_open *stmt);
static void free_fetch(PLtsql_stmt_fetch *stmt);
static void free_close(PLtsql_stmt_close *stmt);
static void free_perform(PLtsql_stmt_perform *stmt);
static void free_call(PLtsql_stmt_call *stmt);
static void free_commit(PLtsql_stmt_commit *stmt);
static void free_rollback(PLtsql_stmt_rollback *stmt);
static void free_set(PLtsql_stmt_set *stmt);
static void free_expr(PLtsql_expr *expr);

static void
free_stmt(PLtsql_stmt *stmt)
{
	if (stmt == NULL)
		return;

	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_BLOCK:
			free_block((PLtsql_stmt_block *) stmt);
			break;
		case PLTSQL_STMT_ASSIGN:
			free_assign((PLtsql_stmt_assign *) stmt);
			break;
		case PLTSQL_STMT_IF:
			free_if((PLtsql_stmt_if *) stmt);
			break;
		case PLTSQL_STMT_CASE:
			free_case((PLtsql_stmt_case *) stmt);
			break;
		case PLTSQL_STMT_LOOP:
			free_loop((PLtsql_stmt_loop *) stmt);
			break;
		case PLTSQL_STMT_WHILE:
			free_while((PLtsql_stmt_while *) stmt);
			break;
		case PLTSQL_STMT_FORI:
			free_fori((PLtsql_stmt_fori *) stmt);
			break;
		case PLTSQL_STMT_FORS:
			free_fors((PLtsql_stmt_fors *) stmt);
			break;
		case PLTSQL_STMT_FORC:
			free_forc((PLtsql_stmt_forc *) stmt);
			break;
		case PLTSQL_STMT_FOREACH_A:
			free_foreach_a((PLtsql_stmt_foreach_a *) stmt);
			break;
		case PLTSQL_STMT_EXIT:
			free_exit((PLtsql_stmt_exit *) stmt);
			break;
		case PLTSQL_STMT_RETURN:
			free_return((PLtsql_stmt_return *) stmt);
			break;
		case PLTSQL_STMT_RETURN_NEXT:
			free_return_next((PLtsql_stmt_return_next *) stmt);
			break;
		case PLTSQL_STMT_RETURN_QUERY:
			free_return_query((PLtsql_stmt_return_query *) stmt);
			break;
		case PLTSQL_STMT_RAISE:
			free_raise((PLtsql_stmt_raise *) stmt);
			break;
		case PLTSQL_STMT_ASSERT:
			free_assert((PLtsql_stmt_assert *) stmt);
			break;
		case PLTSQL_STMT_EXECSQL:
			free_execsql((PLtsql_stmt_execsql *) stmt);
			break;
		case PLTSQL_STMT_DYNEXECUTE:
			free_dynexecute((PLtsql_stmt_dynexecute *) stmt);
			break;
		case PLTSQL_STMT_DYNFORS:
			free_dynfors((PLtsql_stmt_dynfors *) stmt);
			break;
		case PLTSQL_STMT_GETDIAG:
			free_getdiag((PLtsql_stmt_getdiag *) stmt);
			break;
		case PLTSQL_STMT_OPEN:
			free_open((PLtsql_stmt_open *) stmt);
			break;
		case PLTSQL_STMT_FETCH:
			free_fetch((PLtsql_stmt_fetch *) stmt);
			break;
		case PLTSQL_STMT_CLOSE:
			free_close((PLtsql_stmt_close *) stmt);
			break;
		case PLTSQL_STMT_PERFORM:
			free_perform((PLtsql_stmt_perform *) stmt);
			break;
		case PLTSQL_STMT_CALL:
			free_call((PLtsql_stmt_call *) stmt);
			break;
		case PLTSQL_STMT_COMMIT:
			free_commit((PLtsql_stmt_commit *) stmt);
			break;
		case PLTSQL_STMT_ROLLBACK:
			free_rollback((PLtsql_stmt_rollback *) stmt);
			break;
		case PLTSQL_STMT_SET:
			free_set((PLtsql_stmt_set *) stmt);
			break;
		default:
			free_stmt2(stmt);
			break;
	}
}

static void
free_stmts(List *stmts)
{
	ListCell   *s;

	foreach(s, stmts)
	{
		free_stmt((PLtsql_stmt *) lfirst(s));
	}
}

static void
free_block(PLtsql_stmt_block *block)
{
	free_stmts(block->body);
	if (block->exceptions)
	{
		ListCell   *e;

		foreach(e, block->exceptions->exc_list)
		{
			PLtsql_exception *exc = (PLtsql_exception *) lfirst(e);

			free_stmts(exc->action);
		}
	}
}

static void
free_assign(PLtsql_stmt_assign *stmt)
{
	free_expr(stmt->expr);
}

static void
free_if(PLtsql_stmt_if *stmt)
{
	ListCell   *l;

	free_expr(stmt->cond);
	free_stmt(stmt->then_body);
	foreach(l, stmt->elsif_list)
	{
		PLtsql_if_elsif *elif = (PLtsql_if_elsif *) lfirst(l);

		free_expr(elif->cond);
		free_stmts(elif->stmts);
	}
	if (stmt->else_body)
		free_stmt(stmt->else_body);
}

static void
free_case(PLtsql_stmt_case *stmt)
{
	ListCell   *l;

	free_expr(stmt->t_expr);
	foreach(l, stmt->case_when_list)
	{
		PLtsql_case_when *cwt = (PLtsql_case_when *) lfirst(l);

		free_expr(cwt->expr);
		free_stmts(cwt->stmts);
	}
	free_stmts(stmt->else_stmts);
}

static void
free_loop(PLtsql_stmt_loop *stmt)
{
	free_stmts(stmt->body);
}

static void
free_while(PLtsql_stmt_while *stmt)
{
	free_expr(stmt->cond);
	free_stmts(stmt->body);
}

static void
free_fori(PLtsql_stmt_fori *stmt)
{
	free_expr(stmt->lower);
	free_expr(stmt->upper);
	free_expr(stmt->step);
	free_stmts(stmt->body);
}

static void
free_fors(PLtsql_stmt_fors *stmt)
{
	free_stmts(stmt->body);
	free_expr(stmt->query);
}

static void
free_forc(PLtsql_stmt_forc *stmt)
{
	free_stmts(stmt->body);
	free_expr(stmt->argquery);
}

static void
free_foreach_a(PLtsql_stmt_foreach_a *stmt)
{
	free_expr(stmt->expr);
	free_stmts(stmt->body);
}

static void
free_open(PLtsql_stmt_open *stmt)
{
	ListCell   *lc;

	free_expr(stmt->argquery);
	free_expr(stmt->query);
	free_expr(stmt->dynquery);
	foreach(lc, stmt->params)
	{
		free_expr((PLtsql_expr *) lfirst(lc));
	}
}

static void
free_fetch(PLtsql_stmt_fetch *stmt)
{
	free_expr(stmt->expr);
}

static void
free_close(PLtsql_stmt_close *stmt)
{
}

static void
free_perform(PLtsql_stmt_perform *stmt)
{
	free_expr(stmt->expr);
}

static void
free_call(PLtsql_stmt_call *stmt)
{
	free_expr(stmt->expr);
}

static void
free_commit(PLtsql_stmt_commit *stmt)
{
}

static void
free_rollback(PLtsql_stmt_rollback *stmt)
{
}

static void
free_set(PLtsql_stmt_set *stmt)
{
	free_expr(stmt->expr);
}

static void
free_exit(PLtsql_stmt_exit *stmt)
{
	free_expr(stmt->cond);
}

static void
free_return(PLtsql_stmt_return *stmt)
{
	free_expr(stmt->expr);
}

static void
free_return_next(PLtsql_stmt_return_next *stmt)
{
	free_expr(stmt->expr);
}

static void
free_return_query(PLtsql_stmt_return_query *stmt)
{
	ListCell   *lc;

	free_expr(stmt->query);
	free_expr(stmt->dynquery);
	foreach(lc, stmt->params)
	{
		free_expr((PLtsql_expr *) lfirst(lc));
	}
}

static void
free_raise(PLtsql_stmt_raise *stmt)
{
	ListCell   *lc;

	foreach(lc, stmt->params)
	{
		free_expr((PLtsql_expr *) lfirst(lc));
	}
	foreach(lc, stmt->options)
	{
		PLtsql_raise_option *opt = (PLtsql_raise_option *) lfirst(lc);

		free_expr(opt->expr);
	}
}

static void
free_assert(PLtsql_stmt_assert *stmt)
{
	free_expr(stmt->cond);
	free_expr(stmt->message);
}

static void
free_execsql(PLtsql_stmt_execsql *stmt)
{
	free_expr(stmt->sqlstmt);
}

static void
free_dynexecute(PLtsql_stmt_dynexecute *stmt)
{
	ListCell   *lc;

	free_expr(stmt->query);
	foreach(lc, stmt->params)
	{
		free_expr((PLtsql_expr *) lfirst(lc));
	}
}

static void
free_dynfors(PLtsql_stmt_dynfors *stmt)
{
	ListCell   *lc;

	free_stmts(stmt->body);
	free_expr(stmt->query);
	foreach(lc, stmt->params)
	{
		free_expr((PLtsql_expr *) lfirst(lc));
	}
}

static void
free_getdiag(PLtsql_stmt_getdiag *stmt)
{
}

static void
free_expr(PLtsql_expr *expr)
{
	if (expr && expr->plan)
	{
		SPI_freeplan(expr->plan);
		expr->plan = NULL;
	}
}

void
pltsql_free_function_memory(PLtsql_function *func)
{
	int			i;

	/* Better not call this on an in-use function */
	Assert(func->use_count == 0);

	/* Release plans associated with variable declarations */
	for (i = 0; i < func->ndatums; i++)
	{
		PLtsql_datum *d = func->datums[i];

		switch (d->dtype)
		{
			case PLTSQL_DTYPE_VAR:
			case PLTSQL_DTYPE_PROMISE:
				{
					PLtsql_var *var = (PLtsql_var *) d;

					free_expr(var->default_val);
					free_expr(var->cursor_explicit_expr);
				}
				break;
			case PLTSQL_DTYPE_ROW:
				break;
			case PLTSQL_DTYPE_REC:
				{
					PLtsql_rec *rec = (PLtsql_rec *) d;

					free_expr(rec->default_val);
				}
				break;
			case PLTSQL_DTYPE_RECFIELD:
				break;
			case PLTSQL_DTYPE_ARRAYELEM:
				free_expr(((PLtsql_arrayelem *) d)->subscript);
				break;
			case PLTSQL_DTYPE_TBL:
				/* Nothing to free */
				break;
			default:
				elog(ERROR, "unrecognized data type: %d", d->dtype);
		}
	}
	func->ndatums = 0;

	/*
	 * free exec codes It is called before free_block because exec_code shares
	 * same nodes with the tree. Shared nodes will be skipped and only nodes
	 * generated by codegen will be freed.
	 */

	if (func->exec_codes)
	{
		free_exec_codes(func->exec_codes);
		func->exec_codes = NULL;
	}

	/* Release plans in statement tree */
	if (func->action)
		free_block(func->action);
	func->action = NULL;

	/*
	 * And finally, release all memory except the PLtsql_function struct
	 * itself (which has to be kept around because there may be multiple
	 * fn_extra pointers to it).
	 */
	if (func->fn_cxt)
		MemoryContextDelete(func->fn_cxt);
	func->fn_cxt = NULL;
}


/**********************************************************************
 * Debug functions for analyzing the compiled code
 **********************************************************************/
static int	dump_indent;

static void dump_ind(void);
static void dump_stmt(PLtsql_stmt *stmt);
static void dump_block(PLtsql_stmt_block *block);
static void dump_assign(PLtsql_stmt_assign *stmt);
static void dump_if(PLtsql_stmt_if *stmt);
static void dump_case(PLtsql_stmt_case *stmt);
static void dump_loop(PLtsql_stmt_loop *stmt);
static void dump_while(PLtsql_stmt_while *stmt);
static void dump_fori(PLtsql_stmt_fori *stmt);
static void dump_fors(PLtsql_stmt_fors *stmt);
static void dump_forc(PLtsql_stmt_forc *stmt);
static void dump_foreach_a(PLtsql_stmt_foreach_a *stmt);
static void dump_exit(PLtsql_stmt_exit *stmt);
static void dump_return(PLtsql_stmt_return *stmt);
static void dump_return_next(PLtsql_stmt_return_next *stmt);
static void dump_return_query(PLtsql_stmt_return_query *stmt);
static void dump_raise(PLtsql_stmt_raise *stmt);
static void dump_assert(PLtsql_stmt_assert *stmt);
static void dump_execsql(PLtsql_stmt_execsql *stmt);
static void dump_set_explain_mode(PLtsql_stmt_set_explain_mode *stmt);
static void dump_dynexecute(PLtsql_stmt_dynexecute *stmt);
static void dump_dynfors(PLtsql_stmt_dynfors *stmt);
static void dump_getdiag(PLtsql_stmt_getdiag *stmt);
static void dump_open(PLtsql_stmt_open *stmt);
static void dump_fetch(PLtsql_stmt_fetch *stmt);
static void dump_cursor_direction(PLtsql_stmt_fetch *stmt);
static void dump_close(PLtsql_stmt_close *stmt);
static void dump_perform(PLtsql_stmt_perform *stmt);
static void dump_call(PLtsql_stmt_call *stmt);
static void dump_commit(PLtsql_stmt_commit *stmt);
static void dump_rollback(PLtsql_stmt_rollback *stmt);
static void dump_set(PLtsql_stmt_set *stmt);
static void dump_expr(PLtsql_expr *expr);

static void
dump_ind(void)
{
	int			i;

	for (i = 0; i < dump_indent; i++)
		printf(" ");
}

static void
dump_stmt(PLtsql_stmt *stmt)
{
	printf("%3d:", stmt->lineno);
	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_BLOCK:
			dump_block((PLtsql_stmt_block *) stmt);
			break;
		case PLTSQL_STMT_ASSIGN:
			dump_assign((PLtsql_stmt_assign *) stmt);
			break;
		case PLTSQL_STMT_IF:
			dump_if((PLtsql_stmt_if *) stmt);
			break;
		case PLTSQL_STMT_CASE:
			dump_case((PLtsql_stmt_case *) stmt);
			break;
		case PLTSQL_STMT_LOOP:
			dump_loop((PLtsql_stmt_loop *) stmt);
			break;
		case PLTSQL_STMT_WHILE:
			dump_while((PLtsql_stmt_while *) stmt);
			break;
		case PLTSQL_STMT_FORI:
			dump_fori((PLtsql_stmt_fori *) stmt);
			break;
		case PLTSQL_STMT_FORS:
			dump_fors((PLtsql_stmt_fors *) stmt);
			break;
		case PLTSQL_STMT_FORC:
			dump_forc((PLtsql_stmt_forc *) stmt);
			break;
		case PLTSQL_STMT_FOREACH_A:
			dump_foreach_a((PLtsql_stmt_foreach_a *) stmt);
			break;
		case PLTSQL_STMT_EXIT:
			dump_exit((PLtsql_stmt_exit *) stmt);
			break;
		case PLTSQL_STMT_RETURN:
			dump_return((PLtsql_stmt_return *) stmt);
			break;
		case PLTSQL_STMT_RETURN_NEXT:
			dump_return_next((PLtsql_stmt_return_next *) stmt);
			break;
		case PLTSQL_STMT_RETURN_QUERY:
			dump_return_query((PLtsql_stmt_return_query *) stmt);
			break;
		case PLTSQL_STMT_RAISE:
			dump_raise((PLtsql_stmt_raise *) stmt);
			break;
		case PLTSQL_STMT_ASSERT:
			dump_assert((PLtsql_stmt_assert *) stmt);
			break;
		case PLTSQL_STMT_EXECSQL:
			dump_execsql((PLtsql_stmt_execsql *) stmt);
			break;
		case PLTSQL_STMT_SET_EXPLAIN_MODE:
			dump_set_explain_mode((PLtsql_stmt_set_explain_mode *) stmt);
			break;
		case PLTSQL_STMT_DYNEXECUTE:
			dump_dynexecute((PLtsql_stmt_dynexecute *) stmt);
			break;
		case PLTSQL_STMT_DYNFORS:
			dump_dynfors((PLtsql_stmt_dynfors *) stmt);
			break;
		case PLTSQL_STMT_GETDIAG:
			dump_getdiag((PLtsql_stmt_getdiag *) stmt);
			break;
		case PLTSQL_STMT_OPEN:
			dump_open((PLtsql_stmt_open *) stmt);
			break;
		case PLTSQL_STMT_FETCH:
			dump_fetch((PLtsql_stmt_fetch *) stmt);
			break;
		case PLTSQL_STMT_CLOSE:
			dump_close((PLtsql_stmt_close *) stmt);
			break;
		case PLTSQL_STMT_PERFORM:
			dump_perform((PLtsql_stmt_perform *) stmt);
			break;
		case PLTSQL_STMT_CALL:
			dump_call((PLtsql_stmt_call *) stmt);
			break;
		case PLTSQL_STMT_COMMIT:
			dump_commit((PLtsql_stmt_commit *) stmt);
			break;
		case PLTSQL_STMT_ROLLBACK:
			dump_rollback((PLtsql_stmt_rollback *) stmt);
			break;
		case PLTSQL_STMT_SET:
			dump_set((PLtsql_stmt_set *) stmt);
			break;
		default:
			dump_stmt2(stmt);
			break;
	}
}

static void
dump_stmts(List *stmts)
{
	ListCell   *s;

	dump_indent += 2;
	foreach(s, stmts)
		dump_stmt((PLtsql_stmt *) lfirst(s));
	dump_indent -= 2;
}

static void
dump_block(PLtsql_stmt_block *block)
{
	char	   *name;

	if (block->label == NULL)
		name = "*unnamed*";
	else
		name = block->label;

	dump_ind();
	printf("BLOCK <<%s>>\n", name);

	dump_stmts(block->body);

	if (block->exceptions)
	{
		ListCell   *e;

		foreach(e, block->exceptions->exc_list)
		{
			PLtsql_exception *exc = (PLtsql_exception *) lfirst(e);
			PLtsql_condition *cond;

			dump_ind();
			printf("    EXCEPTION WHEN ");
			for (cond = exc->conditions; cond; cond = cond->next)
			{
				if (cond != exc->conditions)
					printf(" OR ");
				printf("%s", cond->condname);
			}
			printf(" THEN\n");
			dump_stmts(exc->action);
		}
	}

	dump_ind();
	printf("    END -- %s\n", name);
}

static void
dump_assign(PLtsql_stmt_assign *stmt)
{
	dump_ind();
	printf("ASSIGN var %d := ", stmt->varno);
	dump_expr(stmt->expr);
	printf("\n");
}

static void
dump_if(PLtsql_stmt_if *stmt)
{
	ListCell   *l;

	dump_ind();
	printf("IF ");
	dump_expr(stmt->cond);
	printf(" THEN\n");
	dump_stmt(stmt->then_body);
	foreach(l, stmt->elsif_list)
	{
		PLtsql_if_elsif *elif = (PLtsql_if_elsif *) lfirst(l);

		dump_ind();
		printf("    ELSIF ");
		dump_expr(elif->cond);
		printf(" THEN\n");
		dump_stmts(elif->stmts);
	}
	if (stmt->else_body != NULL)
	{
		dump_ind();
		printf("    ELSE\n");
		dump_stmt(stmt->else_body);
	}
	dump_ind();
	printf("    ENDIF\n");
}

static void
dump_case(PLtsql_stmt_case *stmt)
{
	ListCell   *l;

	dump_ind();
	printf("CASE %d ", stmt->t_varno);
	if (stmt->t_expr)
		dump_expr(stmt->t_expr);
	printf("\n");
	dump_indent += 6;
	foreach(l, stmt->case_when_list)
	{
		PLtsql_case_when *cwt = (PLtsql_case_when *) lfirst(l);

		dump_ind();
		printf("WHEN ");
		dump_expr(cwt->expr);
		printf("\n");
		dump_ind();
		printf("THEN\n");
		dump_indent += 2;
		dump_stmts(cwt->stmts);
		dump_indent -= 2;
	}
	if (stmt->have_else)
	{
		dump_ind();
		printf("ELSE\n");
		dump_indent += 2;
		dump_stmts(stmt->else_stmts);
		dump_indent -= 2;
	}
	dump_indent -= 6;
	dump_ind();
	printf("    ENDCASE\n");
}

static void
dump_loop(PLtsql_stmt_loop *stmt)
{
	dump_ind();
	printf("LOOP\n");

	dump_stmts(stmt->body);

	dump_ind();
	printf("    ENDLOOP\n");
}

static void
dump_while(PLtsql_stmt_while *stmt)
{
	dump_ind();
	printf("WHILE ");
	dump_expr(stmt->cond);
	printf("\n");

	dump_stmts(stmt->body);

	dump_ind();
	printf("    ENDWHILE\n");
}

static void
dump_fori(PLtsql_stmt_fori *stmt)
{
	dump_ind();
	printf("FORI %s %s\n", stmt->var->refname, (stmt->reverse) ? "REVERSE" : "NORMAL");

	dump_indent += 2;
	dump_ind();
	printf("    lower = ");
	dump_expr(stmt->lower);
	printf("\n");
	dump_ind();
	printf("    upper = ");
	dump_expr(stmt->upper);
	printf("\n");
	if (stmt->step)
	{
		dump_ind();
		printf("    step = ");
		dump_expr(stmt->step);
		printf("\n");
	}
	dump_indent -= 2;

	dump_stmts(stmt->body);

	dump_ind();
	printf("    ENDFORI\n");
}

static void
dump_fors(PLtsql_stmt_fors *stmt)
{
	dump_ind();
	printf("FORS %s ", stmt->var->refname);
	dump_expr(stmt->query);
	printf("\n");

	dump_stmts(stmt->body);

	dump_ind();
	printf("    ENDFORS\n");
}

static void
dump_forc(PLtsql_stmt_forc *stmt)
{
	dump_ind();
	printf("FORC %s ", stmt->var->refname);
	printf("curvar=%d\n", stmt->curvar);

	dump_indent += 2;
	if (stmt->argquery != NULL)
	{
		dump_ind();
		printf("  arguments = ");
		dump_expr(stmt->argquery);
		printf("\n");
	}
	dump_indent -= 2;

	dump_stmts(stmt->body);

	dump_ind();
	printf("    ENDFORC\n");
}

static void
dump_foreach_a(PLtsql_stmt_foreach_a *stmt)
{
	dump_ind();
	printf("FOREACHA var %d ", stmt->varno);
	if (stmt->slice != 0)
		printf("SLICE %d ", stmt->slice);
	printf("IN ");
	dump_expr(stmt->expr);
	printf("\n");

	dump_stmts(stmt->body);

	dump_ind();
	printf("    ENDFOREACHA");
}

static void
dump_open(PLtsql_stmt_open *stmt)
{
	dump_ind();
	printf("OPEN curvar=%d\n", stmt->curvar);

	dump_indent += 2;
	if (stmt->argquery != NULL)
	{
		dump_ind();
		printf("  arguments = '");
		dump_expr(stmt->argquery);
		printf("'\n");
	}
	if (stmt->query != NULL)
	{
		dump_ind();
		printf("  query = '");
		dump_expr(stmt->query);
		printf("'\n");
	}
	if (stmt->dynquery != NULL)
	{
		dump_ind();
		printf("  execute = '");
		dump_expr(stmt->dynquery);
		printf("'\n");

		if (stmt->params != NIL)
		{
			ListCell   *lc;
			int			i;

			dump_indent += 2;
			dump_ind();
			printf("    USING\n");
			dump_indent += 2;
			i = 1;
			foreach(lc, stmt->params)
			{
				dump_ind();
				printf("    parameter $%d: ", i++);
				dump_expr((PLtsql_expr *) lfirst(lc));
				printf("\n");
			}
			dump_indent -= 4;
		}
	}
	dump_indent -= 2;
}

static void
dump_fetch(PLtsql_stmt_fetch *stmt)
{
	dump_ind();

	if (!stmt->is_move)
	{
		printf("FETCH curvar=%d\n", stmt->curvar);
		dump_cursor_direction(stmt);

		dump_indent += 2;
		if (stmt->target != NULL)
		{
			dump_ind();
			printf("    target = %d %s\n",
				   stmt->target->dno, stmt->target->refname);
		}
		dump_indent -= 2;
	}
	else
	{
		printf("MOVE curvar=%d\n", stmt->curvar);
		dump_cursor_direction(stmt);
	}
}

static void
dump_cursor_direction(PLtsql_stmt_fetch *stmt)
{
	dump_indent += 2;
	dump_ind();
	switch (stmt->direction)
	{
		case FETCH_FORWARD:
			printf("    FORWARD ");
			break;
		case FETCH_BACKWARD:
			printf("    BACKWARD ");
			break;
		case FETCH_ABSOLUTE:
			printf("    ABSOLUTE ");
			break;
		case FETCH_RELATIVE:
			printf("    RELATIVE ");
			break;
		default:
			printf("??? unknown cursor direction %d", stmt->direction);
	}

	if (stmt->expr)
	{
		dump_expr(stmt->expr);
		printf("\n");
	}
	else
		printf("%ld\n", stmt->how_many);

	dump_indent -= 2;
}

static void
dump_close(PLtsql_stmt_close *stmt)
{
	dump_ind();
	printf("CLOSE curvar=%d\n", stmt->curvar);
}

static void
dump_perform(PLtsql_stmt_perform *stmt)
{
	dump_ind();
	printf("PERFORM expr = ");
	dump_expr(stmt->expr);
	printf("\n");
}

static void
dump_call(PLtsql_stmt_call *stmt)
{
	dump_ind();
	printf("%s expr = ", stmt->is_call ? "CALL" : "DO");
	dump_expr(stmt->expr);
	printf("\n");
}

static void
dump_commit(PLtsql_stmt_commit *stmt)
{
	dump_ind();
	printf("COMMIT\n");
}

static void
dump_rollback(PLtsql_stmt_rollback *stmt)
{
	dump_ind();
	printf("ROLLBACK\n");
}

static void
dump_set(PLtsql_stmt_set *stmt)
{
	dump_ind();
	printf("%s\n", stmt->expr->query);
}

static void
dump_exit(PLtsql_stmt_exit *stmt)
{
	dump_ind();
	printf("%s", stmt->is_exit ? "EXIT" : "CONTINUE");
	if (stmt->label != NULL)
		printf(" label='%s'", stmt->label);
	if (stmt->cond != NULL)
	{
		printf(" WHEN ");
		dump_expr(stmt->cond);
	}
	printf("\n");
}

static void
dump_return(PLtsql_stmt_return *stmt)
{
	dump_ind();
	printf("RETURN ");
	if (stmt->retvarno >= 0)
		printf("variable %d", stmt->retvarno);
	else if (stmt->expr != NULL)
		dump_expr(stmt->expr);
	else
		printf("NULL");
	printf("\n");
}

static void
dump_return_next(PLtsql_stmt_return_next *stmt)
{
	dump_ind();
	printf("RETURN NEXT ");
	if (stmt->retvarno >= 0)
		printf("variable %d", stmt->retvarno);
	else if (stmt->expr != NULL)
		dump_expr(stmt->expr);
	else
		printf("NULL");
	printf("\n");
}

static void
dump_return_query(PLtsql_stmt_return_query *stmt)
{
	dump_ind();
	if (stmt->query)
	{
		printf("RETURN QUERY ");
		dump_expr(stmt->query);
		printf("\n");
	}
	else
	{
		printf("RETURN QUERY EXECUTE ");
		dump_expr(stmt->dynquery);
		printf("\n");
		if (stmt->params != NIL)
		{
			ListCell   *lc;
			int			i;

			dump_indent += 2;
			dump_ind();
			printf("    USING\n");
			dump_indent += 2;
			i = 1;
			foreach(lc, stmt->params)
			{
				dump_ind();
				printf("    parameter $%d: ", i++);
				dump_expr((PLtsql_expr *) lfirst(lc));
				printf("\n");
			}
			dump_indent -= 4;
		}
	}
}

static void
dump_raise(PLtsql_stmt_raise *stmt)
{
	ListCell   *lc;
	int			i = 0;

	dump_ind();
	printf("RAISE level=%d", stmt->elog_level);
	if (stmt->condname)
		printf(" condname='%s'", stmt->condname);
	if (stmt->message)
		printf(" message='%s'", stmt->message);
	printf("\n");
	dump_indent += 2;
	foreach(lc, stmt->params)
	{
		dump_ind();
		printf("    parameter %d: ", i++);
		dump_expr((PLtsql_expr *) lfirst(lc));
		printf("\n");
	}
	if (stmt->options)
	{
		dump_ind();
		printf("    USING\n");
		dump_indent += 2;
		foreach(lc, stmt->options)
		{
			PLtsql_raise_option *opt = (PLtsql_raise_option *) lfirst(lc);

			dump_ind();
			switch (opt->opt_type)
			{
				case PLTSQL_RAISEOPTION_ERRCODE:
					printf("    ERRCODE = ");
					break;
				case PLTSQL_RAISEOPTION_MESSAGE:
					printf("    MESSAGE = ");
					break;
				case PLTSQL_RAISEOPTION_DETAIL:
					printf("    DETAIL = ");
					break;
				case PLTSQL_RAISEOPTION_HINT:
					printf("    HINT = ");
					break;
				case PLTSQL_RAISEOPTION_COLUMN:
					printf("    COLUMN = ");
					break;
				case PLTSQL_RAISEOPTION_CONSTRAINT:
					printf("    CONSTRAINT = ");
					break;
				case PLTSQL_RAISEOPTION_DATATYPE:
					printf("    DATATYPE = ");
					break;
				case PLTSQL_RAISEOPTION_TABLE:
					printf("    TABLE = ");
					break;
				case PLTSQL_RAISEOPTION_SCHEMA:
					printf("    SCHEMA = ");
					break;
			}
			dump_expr(opt->expr);
			printf("\n");
		}
		dump_indent -= 2;
	}
	dump_indent -= 2;
}

static void
dump_assert(PLtsql_stmt_assert *stmt)
{
	dump_ind();
	printf("ASSERT ");
	dump_expr(stmt->cond);
	printf("\n");

	dump_indent += 2;
	if (stmt->message != NULL)
	{
		dump_ind();
		printf("    MESSAGE = ");
		dump_expr(stmt->message);
		printf("\n");
	}
	dump_indent -= 2;
}

static void
dump_execsql(PLtsql_stmt_execsql *stmt)
{
	dump_ind();
	printf("EXECSQL ");
	dump_expr(stmt->sqlstmt);
	printf("\n");

	dump_indent += 2;
	if (stmt->target != NULL)
	{
		dump_ind();
		printf("    INTO%s target = %d %s\n",
			   stmt->strict ? " STRICT" : "",
			   stmt->target->dno, stmt->target->refname);
	}
	dump_indent -= 2;
}

static void
dump_set_explain_mode(PLtsql_stmt_set_explain_mode *stmt)
{
	dump_ind();
	printf("SET EXPLAIN MODE ");
	printf("\n");

	dump_indent += 2;
	dump_ind();
	printf("    IS_EXPLAIN_ONLY = %s\n", stmt->is_explain_only ? "true" : "false");
	dump_ind();
	printf("    IS_EXPLAIN_ANALYZE = %s\n", stmt->is_explain_analyze ? "true" : "false");
	dump_ind();
	printf("    VALUE = %s\n", stmt->val ? "true" : "false");
	dump_indent -= 2;
}

static void
dump_dynexecute(PLtsql_stmt_dynexecute *stmt)
{
	dump_ind();
	printf("EXECUTE ");
	dump_expr(stmt->query);
	printf("\n");

	dump_indent += 2;
	if (stmt->target != NULL)
	{
		dump_ind();
		printf("    INTO%s target = %d %s\n",
			   stmt->strict ? " STRICT" : "",
			   stmt->target->dno, stmt->target->refname);
	}
	if (stmt->params != NIL)
	{
		ListCell   *lc;
		int			i;

		dump_ind();
		printf("    USING\n");
		dump_indent += 2;
		i = 1;
		foreach(lc, stmt->params)
		{
			dump_ind();
			printf("    parameter %d: ", i++);
			dump_expr((PLtsql_expr *) lfirst(lc));
			printf("\n");
		}
		dump_indent -= 2;
	}
	dump_indent -= 2;
}

static void
dump_dynfors(PLtsql_stmt_dynfors *stmt)
{
	dump_ind();
	printf("FORS %s EXECUTE ", stmt->var->refname);
	dump_expr(stmt->query);
	printf("\n");
	if (stmt->params != NIL)
	{
		ListCell   *lc;
		int			i;

		dump_indent += 2;
		dump_ind();
		printf("    USING\n");
		dump_indent += 2;
		i = 1;
		foreach(lc, stmt->params)
		{
			dump_ind();
			printf("    parameter $%d: ", i++);
			dump_expr((PLtsql_expr *) lfirst(lc));
			printf("\n");
		}
		dump_indent -= 4;
	}
	dump_stmts(stmt->body);
	dump_ind();
	printf("    ENDFORS\n");
}

static void
dump_getdiag(PLtsql_stmt_getdiag *stmt)
{
	ListCell   *lc;

	dump_ind();
	printf("GET %s DIAGNOSTICS ", stmt->is_stacked ? "STACKED" : "CURRENT");
	foreach(lc, stmt->diag_items)
	{
		PLtsql_diag_item *diag_item = (PLtsql_diag_item *) lfirst(lc);

		if (lc != list_head(stmt->diag_items))
			printf(", ");

		printf("{var %d} = %s", diag_item->target,
			   pltsql_getdiag_kindname(diag_item->kind));
	}
	printf("\n");
}

static void
dump_expr(PLtsql_expr *expr)
{
	printf("'%s'", expr->query);
}

void
pltsql_dumptree(PLtsql_function *func)
{
	int			i;
	PLtsql_datum *d;

	printf("\nExecution tree of successfully compiled PL/tsql function %s:\n",
		   func->fn_signature);

	printf("\nFunction's data area:\n");
	for (i = 0; i < func->ndatums; i++)
	{
		d = func->datums[i];

		printf("    entry %d: ", i);
		switch (d->dtype)
		{
			case PLTSQL_DTYPE_VAR:
			case PLTSQL_DTYPE_PROMISE:
				{
					PLtsql_var *var = (PLtsql_var *) d;

					printf("VAR %-16s type %s (typoid %u) atttypmod %d\n",
						   var->refname, var->datatype->typname,
						   var->datatype->typoid,
						   var->datatype->atttypmod);
					if (var->isconst)
						printf("                                  CONSTANT\n");
					if (var->notnull)
						printf("                                  NOT NULL\n");
					if (var->default_val != NULL)
					{
						printf("                                  DEFAULT ");
						dump_expr(var->default_val);
						printf("\n");
					}
					if (var->cursor_explicit_expr != NULL)
					{
						if (var->cursor_explicit_argrow >= 0)
							printf("                                  CURSOR argument row %d\n", var->cursor_explicit_argrow);

						printf("                                  CURSOR IS ");
						dump_expr(var->cursor_explicit_expr);
						printf("\n");
					}
					if (var->promise != PLTSQL_PROMISE_NONE)
						printf("                                  PROMISE %d\n",
							   (int) var->promise);
				}
				break;
			case PLTSQL_DTYPE_ROW:
				{
					PLtsql_row *row = (PLtsql_row *) d;
					int			i;

					printf("ROW %-16s fields", row->refname);
					for (i = 0; i < row->nfields; i++)
					{
						printf(" %s=var %d", (row->fieldnames[i] != NULL) ? row->fieldnames[i] : "",
							   row->varnos[i]);
					}
					printf("\n");
				}
				break;
			case PLTSQL_DTYPE_REC:
				printf("REC %-16s typoid %u\n",
					   ((PLtsql_rec *) d)->refname,
					   ((PLtsql_rec *) d)->rectypeid);
				if (((PLtsql_rec *) d)->isconst)
					printf("                                  CONSTANT\n");
				if (((PLtsql_rec *) d)->notnull)
					printf("                                  NOT NULL\n");
				if (((PLtsql_rec *) d)->default_val != NULL)
				{
					printf("                                  DEFAULT ");
					dump_expr(((PLtsql_rec *) d)->default_val);
					printf("\n");
				}
				break;
			case PLTSQL_DTYPE_RECFIELD:
				printf("RECFIELD %-16s of REC %d\n",
					   ((PLtsql_recfield *) d)->fieldname,
					   ((PLtsql_recfield *) d)->recparentno);
				break;
			case PLTSQL_DTYPE_ARRAYELEM:
				printf("ARRAYELEM of VAR %d subscript ",
					   ((PLtsql_arrayelem *) d)->arrayparentno);
				dump_expr(((PLtsql_arrayelem *) d)->subscript);
				printf("\n");
				break;
			case PLTSQL_DTYPE_TBL:
				printf("TABLE VARIABLE %s\n", ((PLtsql_tbl *) d)->refname);
				if (((PLtsql_tbl *) d)->tblname)
				{
					printf("                                  UNDERLYING TABLE %s\n",
						   ((PLtsql_tbl *) d)->tblname);
				}
				break;
			default:
				printf("??? unknown data type %d\n", d->dtype);
		}
	}
	printf("\nFunction's statements:\n");

	dump_indent = 0;
	printf("%3d:", func->action->lineno);
	dump_block(func->action);
	printf("\nEnd of execution tree of function %s\n\n", func->fn_signature);
	fflush(stdout);
}

#include "pl_funcs-2.c"
