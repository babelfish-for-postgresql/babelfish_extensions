#include "pltsql.h"
#include "pltsql-2.h"
#include "tsqlNodes.h"

PLtsql_expr *
makeTsqlExpr(const char *fragment)
{
	PLtsql_expr *result = (PLtsql_expr *) palloc0(sizeof(*result));

	result	  ->query = pstrdup(fragment);
	result	  ->plan = NULL;
	result	  ->paramnos = NULL;
	result	  ->rwparam = -1;
	result	  ->ns = pltsql_ns_top();

	return result;
}


PLtsql_stmt_while *
makeWhileStmt(PLtsql_expr *cond)
{
	PLtsql_stmt_while *result = (PLtsql_stmt_while *) palloc0(sizeof(*result));

	result	  ->cmd_type = PLTSQL_STMT_WHILE;
	result	  ->cond = cond;

	return result;
}

PLtsql_stmt_print *
makePrintStmt(PLtsql_expr *expr)
{

	PLtsql_stmt_print *result = (PLtsql_stmt_print *) palloc0(sizeof(*result));

	result	  ->cmd_type = PLTSQL_STMT_PRINT;
	result	  ->exprs = list_make1(expr);

	return result;
}
