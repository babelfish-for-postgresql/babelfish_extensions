#include "postgres.h"
#include "executor/spi.h"
#include "pltsql.h"

#if 0
typedef enum pltsql_stmt_type
{
	PLTSQL_STMT_BLOCK,
	PLTSQL_STMT_ASSIGN,
	PLTSQL_STMT_IF,
	PLTSQL_STMT_CASE,
	PLTSQL_STMT_LOOP,
	PLTSQL_STMT_WHILE,
	PLTSQL_STMT_FORI,
	PLTSQL_STMT_FORS,
	PLTSQL_STMT_FORC,
	PLTSQL_STMT_FOREACH_A,
	PLTSQL_STMT_EXIT,
	PLTSQL_STMT_RETURN,
	PLTSQL_STMT_RETURN_NEXT,
	PLTSQL_STMT_RETURN_QUERY,
	PLTSQL_STMT_RAISE,
	PLTSQL_STMT_ASSERT,
	PLTSQL_STMT_EXECSQL,
	PLTSQL_STMT_DYNEXECUTE,
	PLTSQL_STMT_DYNFORS,
	PLTSQL_STMT_GETDIAG,
	PLTSQL_STMT_OPEN,
	PLTSQL_STMT_FETCH,
	PLTSQL_STMT_CLOSE,
	PLTSQL_STMT_PERFORM,
	PLTSQL_STMT_CALL,
	PLTSQL_STMT_COMMIT,
	PLTSQL_STMT_ROLLBACK,
	PLTSQL_STMT_SET,
	/* TSQL-only statement types follow */
	PLTSQL_STMT_GOTO,
	PLTSQL_STMT_PRINT,
	PLTSQL_STMT_INIT,
	PLTSQL_STMT_SELECT_SET,
	PLTSQL_STMT_TRY_CATCH,
	PLTSQL_STMT_PUSH_RESULT,
	PLTSQL_STMT_EXEC,
	PLTSQL_STMT_DECL_TABLE,
	PLTSQL_STMT_RETURN_TABLE,
	PLTSQL_STMT_EXEC_BATCH,
	PLTSQL_STMT_EXEC_SPEXECUTESQL,
	PLTSQL_STMT_ASSIGN_CURVAR,
	PLTSQL_STMT_DEALLOCATE,
	PLTSQL_STMT_INSERT_BULK,
	PLTSQL_STMT_GRANTDB
} PLtsql_stmt_type;

typedef struct PLtsql_expr
{
	char	   *query;
	SPIPlanPtr	plan;
	Bitmapset  *paramnos;		/* all dnos referenced by this query */
	int			rwparam;		/* dno of read/write param, or -1 if none */

	/* function containing this expr (not set until we first parse query) */
	struct PLpgSQL_function *func;

	/* namespace chain visible to this expr */
	struct PLpgSQL_nsitem *ns;

	/* fields for "simple expression" fast-path execution: */
	Expr	   *expr_simple_expr;	/* NULL means not a simple expr */
	int			expr_simple_generation; /* plancache generation we checked */
	Oid			expr_simple_type;	/* result type Oid, if simple */
	int32		expr_simple_typmod; /* result typmod, if simple */

	/*
	 * if expr is simple AND prepared in current transaction,
	 * expr_simple_state and expr_simple_in_use are valid. Test validity by
	 * seeing if expr_simple_lxid matches current LXID.  (If not,
	 * expr_simple_state probably points at garbage!)
	 */
	ExprState  *expr_simple_state;	/* eval tree for expr_simple_expr */
	bool		expr_simple_in_use; /* true if eval tree is active */
	LocalTransactionId expr_simple_lxid;

	/* tsql table variables */
	List	   *tsql_tablevars;
	/* here for itvf? queries with all idents replaced with NULLs */
	char	   *itvf_query;
	/* make sure always set to NULL */
} PLtsql_expr;

typedef struct
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *cond;
	List	   *then_body;
	List	   *elsif_list;
	List	   *else_body;
} PLtsql_stmt_if;

/* ////////////////////////////////////////////////////////////////////////////// */
#endif

PLtsql_stmt_print *makePrintStmt(PLtsql_expr *expr);
PLtsql_expr *makeTsqlExpr(const char *src);
PLtsql_stmt_while *makeWhileStmt(PLtsql_expr *expr);
