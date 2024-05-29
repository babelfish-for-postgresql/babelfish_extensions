#include "postgres.h"
#include "executor/spi.h"
#include "pltsql.h"

PLtsql_stmt_print *makePrintStmt(PLtsql_expr *expr);
PLtsql_expr *makeTsqlExpr(const char *src);
PLtsql_stmt_while *makeWhileStmt(PLtsql_expr *expr);
