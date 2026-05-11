#ifndef PLTSQL_2_H
#define PLTSQL_2_H
#include "pg_config_manual.h"

/*
 * This file contains pg_node_attr() annotations for ANTLR parse tree
 * serialization (used by gen_pltsql_node_support.pl to generate
 * serialization/deserialization code for procedure caching when
 * babelfishpg_tsql.enable_antlr_parse_cache is enabled).
 */

/*
 * PRINT statement
 */
typedef struct PLtsql_stmt_print
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *label;
	List	   *exprs;
} PLtsql_stmt_print;

/*
 * KILL statement
 */
typedef struct PLtsql_stmt_kill
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *label;
	int	    spid;
} PLtsql_stmt_kill;

/*
 * init statement
 */
typedef struct PLtsql_stmt_init
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *label;
	List	   *inits;
} PLtsql_stmt_init;

/*
 * BEGIN TRY...END TRY  BEGIN CATCH...END CATCH block
 */
typedef struct PLtsql_stmt_try_catch
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *label;
	PLtsql_stmt *body;			/* List of statements */
	PLtsql_stmt *handler;
} PLtsql_stmt_try_catch;

/*
 * SELECT-SET statement (this represents a SELECT
 * statement that assignes variables to a set of
 * target variables, such as:
 *    SELECT @balance = cust_balance FROM customer ...
 */
typedef struct PLtsql_stmt_query_set
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	uint32		stmtid;
	PLtsql_expr *sqlstmt;
	PLtsql_variable *target;	/* INTO target (record or row) */
} PLtsql_stmt_query_set;

typedef struct PLtsql_stmt_push_result
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *label;
	PLtsql_expr *query;
} PLtsql_stmt_push_result;

/*
 * EXEC statement
 */
typedef struct PLtsql_stmt_exec
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	PLtsql_expr *expr;
	bool		is_call;
	PLtsql_variable *target;
	int			return_code_dno;
	int			paramno;
	List	   *params;

	/* indicates whether we're executing a scalar UDF using EXEC keyword */
	bool		is_scalar_func;
	bool		is_cross_db;	/* cross database reference */
	char	   *db_name;
	char	   *proc_name;
	char	   *schema_name;

	InsertExecInfo insert_exec;
		
	bool		exec_with_recompile; /* forced recompile through EXECUTE */	
} PLtsql_stmt_exec;

typedef struct tsql_exec_param
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	const char *name;
	PLtsql_expr *expr;
	char		mode;
	int			varno;			/* dno of the output variable */
} tsql_exec_param;

/*
 * T-SQL provides variadic system procedures which are used for RPC.
 * We cannot use "CREATE PROCEUDRE" to define those procedures since they can be variadic.
 * PLtsql_stmt_exec_sp is a general stmt wrapper to call those procedures.
 * TODO: integrate with other system procedures such as sp_executesql
 */
typedef enum PLtsql_exec_sp_type_code
{
	PLTSQL_EXEC_SP_CURSOR,
	PLTSQL_EXEC_SP_CURSOROPEN,
	PLTSQL_EXEC_SP_CURSORPREPARE,
	PLTSQL_EXEC_SP_CURSOREXECUTE,
	PLTSQL_EXEC_SP_CURSORPREPEXEC,
	PLTSQL_EXEC_SP_CURSORUNPREPARE,
	PLTSQL_EXEC_SP_CURSORFETCH,
	PLTSQL_EXEC_SP_CURSOROPTION,
	PLTSQL_EXEC_SP_CURSORCLOSE,
	PLTSQL_EXEC_SP_EXECUTESQL,
	PLTSQL_EXEC_SP_EXECUTE,
	PLTSQL_EXEC_SP_PREPEXEC
} PLtsql_sp_type_code;

typedef struct PLtsql_stmt_exec_sp
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);

	PLtsql_sp_type_code sp_type_code;
	int			prepared_handleno;
	int			cursor_handleno;
	int			return_code_dno;

	PLtsql_expr *handle;

	PLtsql_expr *query;			/* stmt */
	int			paramno;
	PLtsql_expr *param_def;
	List	   *params;

	PLtsql_expr *opt1;
	PLtsql_expr *opt2;
	PLtsql_expr *opt3;
	List	   *stropt;

	InsertExecInfo insert_exec;
} PLtsql_stmt_exec_sp;

/*
 * DECLARE table variable statement
 */
typedef struct PLtsql_stmt_decl_table
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	int			dno;			/* dno of the table variable */
	/* One and only one of the remaining two fields should be used */
	char	   *tbltypname;		/* name of the table type */
	char	   *coldef;			/* column definition list */
} PLtsql_stmt_decl_table;

typedef struct PLtsql_stmt_exec_batch
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	PLtsql_expr *expr;

	InsertExecInfo insert_exec;
} PLtsql_stmt_exec_batch;

typedef struct PLtsql_stmt_raiserror
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	List	   *params;
	int			paramno;
	bool		log;
	bool		nowait;
	bool		seterror;
} PLtsql_stmt_raiserror;

typedef struct PLtsql_stmt_throw
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	List	   *params;
} PLtsql_stmt_throw;

/*
 * TSQL string format GUC
 */
#define TSQL_MAX_MESSAGE_LEN		2047

/*
 * TSQL extended cursor options
 * Note: low bits are already used for PG. (see CURSOR_OPT in parsenodes.h)
 */
#define TSQL_CURSOR_OPT_GLOBAL       (1<<16)
#define TSQL_CURSOR_OPT_LOCAL        (1<<17)
#define TSQL_CURSOR_OPT_FORWARD_ONLY (1<<18)
#define TSQL_CURSOR_OPT_SCROLL       (1<<19)
#define TSQL_CURSOR_OPT_STATIC       (1<<20)
#define TSQL_CURSOR_OPT_KEYSET       (1<<21)
#define TSQL_CURSOR_OPT_DYNAMIC      (1<<22)
#define TSQL_CURSOR_OPT_READ_ONLY    (1<<23)
#define TSQL_CURSOR_OPT_SCROLL_LOCKS (1<<24)
#define TSQL_CURSOR_OPT_OPTIMISTIC   (1<<25)
#define TSQL_CURSOR_OPT_TYPE_WARNING (1<<26)
#define TSQL_CURSOR_OPT_AUTO_CLOSE   (1<<27)	/* only used in API cursor */

/*
 * Speical flag to indicate the cursor is made anonymously via 'SET @cur = CURSOR FOR ...'.
 * babelfishpg_tsql executor internally creates constant cursor and it will be assigned to refcursor
 * but it should be invisible to user through sp_cursor_list.
 */
#define PGTSQL_CURSOR_ANONYMOUS      (1u<<31)

/*
 * DEALLOCATE curvar
 */
typedef struct PLtsql_stmt_deallocate
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	int			curvar;
} PLtsql_stmt_deallocate;

/*
 * (re)DECLARE cur CURSOR ...
 */
typedef struct PLtsql_stmt_decl_cursor
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	int			curvar;
	PLtsql_expr *cursor_explicit_expr;
	int			cursor_options;
} PLtsql_stmt_decl_cursor;

extern bool is_cursor_datatype(Oid oid);

/*
 * GOTO statement
 */
typedef struct PLtsql_stmt_goto
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *label;
	PLtsql_expr *cond;			/* conditional GOTO */
	int32		target_pc pg_node_attr(equal_ignore);
	char	   *target_label;
} PLtsql_stmt_goto;

/*
 *  Label
 */
#define INTERNAL_LABEL_FORMAT "LABEL-0x%lX"
typedef struct PLtsql_stmt_label
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *label;
} PLtsql_stmt_label;

/*
 *   Use DB statement
 */
typedef struct PLtsql_stmt_usedb
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	char	   *db_name;
} PLtsql_stmt_usedb;

/*
 *   Save error handling context
 */
typedef struct PLtsql_stmt_save_ctx
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
	int32		target_pc pg_node_attr(equal_ignore);
	char	   *target_label;
} PLtsql_stmt_save_ctx;

/*
 *   Delete exception handling context
 */
typedef struct PLtsql_stmt_restore_ctx_full
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
} PLtsql_stmt_restore_ctx_full;

/*
 *  Post-exception handling block
 */
typedef struct PLtsql_stmt_restore_ctx_partial
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno pg_node_attr(equal_ignore);
} PLtsql_stmt_restore_ctx_partial;

extern char *yytext;

/*
 * FIXME: implement pltsql_scanner_lineno() in a better way */
#define pltsql_scanner_lineno pltsql_latest_lineno

extern void pltsql_convert_ident(const char *s, char **output, int numidents);
extern PLtsql_expr *pltsql_read_expression(int until, const char *expected);
extern RangeVar *pltsqlMakeRangeVarFromName(const char *identifier_val);

#endif
