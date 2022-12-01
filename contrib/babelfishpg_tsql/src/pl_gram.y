%{
/*----------------------------------------------------------------------------------
 *
 * gram.y	Parser for the PL/TSQL procedural language
 *
 * Copyright (c) 1996-2011, PostgreSQL Global Development Group
 * Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/gram.y
 *
 *-----------------------------------------------------------------------------------
 */

#include "postgres.h"
#include "pltsql.h"
#include "pltsql-2.h"

#include "catalog/namespace.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "parser/parser.h"
#include "parser/parse_type.h"
#include "parser/scanner.h"
#include "parser/scansup.h"
#include "pltsql_instr.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"
#include "utils/builtins.h"

#include "multidb.h"

/* Location tracking support --- simpler than bison's default */
#define YYLLOC_DEFAULT(Current, Rhs, N) \
	do { \
		if (N) \
			(Current) = (Rhs)[1]; \
		else \
			(Current) = (Rhs)[0]; \
	} while (0)

#define YY_LOCATION_PRINT(File, Loc) \
	do { \
		YYFPRINTF(File, "@%d", Loc); \
    } while (0)
/*
 * Bison doesn't allocate anything that needs to live across parser calls,
 * so we can easily have it use palloc instead of malloc.  This prevents
 * memory leaks if we error out during parsing.  Note this only works with
 * bison >= 2.0.  However, in bison 1.875 the default is to use alloca()
 * if possible, so there's not really much problem anyhow, at least if
 * you're building with gcc.
 */
#define YYMALLOC palloc
#define YYFREE   pfree

#define TEMPOBJ_QUALIFIER "TEMPORARY "

typedef struct
{
	int			location;
	int			leaderlen;
} sql_error_callback_arg;

typedef struct
{
	int			location;
	char		*ident;
	int			dno;
	int			length; /* actual length of token from input text. can be different from strlen(ident) if ident is truncated */
} tsql_ident_ref;


/*
 * execsql_ctx
 *
 *  A structure of type execsql_ctx is used to keep track
 *  of the progress of the make_execsql_stmt() function.
 */
typedef struct
{
	int					location;
	StringInfoData		ds;
	IdentifierLookup	save_IdentifierLookup;
	PLtsql_expr			*expr;
	PLtsql_variable		*target;
	int					tok;
	int					prev_tok;
	bool				have_into;
	bool                have_values;
	bool				have_strict;
	bool				have_temptbl;
	bool				have_insert_select;
	bool				have_insert_exec;
	bool				is_prev_tok_create;
	bool				is_update_with_variables;
	char				*select_into_table_name;
	int					into_start_loc;
	int					into_end_loc;
	int					temptbl_loc;
	List				*tsql_idents;
	int					startlocation;
	int					parenlevel;
	int					caselevel;
	bool 				have_output;
} execsql_ctx;


#define parser_errposition(pos)  pltsql_scanner_errposition(pos)

union YYSTYPE;					/* need forward reference for tok_is_keyword */

static	bool			tok_is_keyword(int token, union YYSTYPE *lval,
									   int kw_token, const char *kw_str);
static	void			word_is_not_variable(PLword *word, int location);
static	void			cword_is_not_variable(PLcword *cword, int location);
static	void			current_token_is_not_variable(int tok);
static	char *			quote_tsql_identifiers(const StringInfo src,
											const List *tsql_word_list);
static	char *			generate_itvf_query(char *src,
											const List *tsql_word_list);
static List * append_if_tsql_identifier(int tok, int start_len, int start_loc,
											List *tsql_idents);
static	PLtsql_expr	*read_sql_construct(int until,
											int until2,
											int until3,
											const char *expected,
											const char *sqlstart,
											bool isexpression,
											bool valid_sql,
											bool trim,
											int *startloc,
											int *endtoken);
static	PLtsql_expr	*read_sql_construct_bos(int until,
											int until2,
											int until3,
											const char *expected,
											const char *sqlstart,
											bool isexpression,
											bool valid_sql,
											bool trim,
											int *startloc,
											int *endtoken,
											bool untilbostok,
											List **tokens,
											bool permit_empty);
static	PLtsql_expr	*read_sql_bos(int until,
											int until2,
											int until3,
											int until4,
											int until5,
											const char *expected,
											const char *sqlstart,
											bool isexpression,
											bool valid_sql,
											bool trim,
											int *startloc,
											int *endtoken,
											bool untilbostok,
											List **tokens,
											bool permit_empty);

static char *read_tokens_bos(int until, const char *expected);

static	PLtsql_expr	*read_sql_expression(int until,
											 const char *expected);
static	PLtsql_expr	*read_sql_expression_bos(int until,
											 const char *expected,
											 bool permit_empty);
static	PLtsql_expr	*read_sql_expression2(int until, int until2,
											  const char *expected,
											  int *endtoken);
static bool is_terminator(int tok, bool first, int start_loc, int cur_loc,
                          const char *sql_start, const List *tsql_idents);
static bool is_terminator_proc(int tok, bool first);
static bool string_matches(const char *str, const char *pattern);
static bool word_matches(int tok, const char *pattern);
static	PLtsql_expr	*read_sql_stmt_bos(const char *sqlstart);
static	PLtsql_type	*read_datatype(int tok);
static	PLtsql_stmt	*make_execsql_stmt(int firsttoken, int location,
										 PLword *firstword, PLtsql_expr *with_clauses);
static	PLtsql_stmt	*make_select_stmt(int firsttoken, int location,
										 PLword *firstword, PLtsql_expr *with_clauses);
static	PLtsql_stmt	*make_update_stmt(int firsttoken, int location,
										 PLword *firstword, PLtsql_expr *with_clauses);
static PLtsql_stmt * make_create_stmt(int firsttoken, int location,
									  PLword *firstword);
static bool must_be_only_stmt(execsql_ctx *ctx);
static void parse_and_build_select_expr(execsql_ctx *ctx, PLtsql_expr *with_clauses, PLtsql_row **target_row, bool *has_destination);
static PLtsql_expr *parse_select_stmt_for_decl_cursor(void);

static	PLtsql_stmt_fetch *read_fetch_direction(void);
static	void			 complete_direction(PLtsql_stmt_fetch *fetch,
											bool *check_FROM);
static	PLtsql_stmt	*make_return_stmt(int location);
static	PLtsql_stmt	*make_return_next_stmt(int location);
static	PLtsql_stmt	*make_return_query_stmt(int location, PLtsql_expr *with_clauses);
static	char			*NameOfDatum(const PLwdatum *wdatum);
static	void			 check_assignable(PLtsql_datum *datum, int location);
static	void			 read_into_target(PLtsql_variable **target,
										  bool *strict, char **select_into_table_name,
										  bool *temp_table);
static	PLtsql_row		*read_into_scalar_list(char *initial_name,
											   PLtsql_datum *initial_datum,
											   int initial_location);
static	PLtsql_row		*make_scalar_list1(char *initial_name,
										   PLtsql_datum *initial_datum,
										   int lineno, int location);
static	void			 check_sql_expr(const char *stmt, int location,
										int leaderlen);
static	void			 pltsql_sql_error_callback(void *arg);
 PLtsql_type	*parse_datatype(const char *string, int location);
static	void			 check_labels(const char *start_label,
									  const char *end_label,
									  int end_location);
static	PLtsql_expr	*read_cursor_args(PLtsql_var *cursor,
										  int until, const char *expected);
static	int	read_tsql_extended_cursor_options(void);
static	List			*read_raise_options(void);

static	tsql_exec_param *parse_sp_proc_param(int *endtoken, bool *flag);

static	bool word_matches_sp_proc(int tok);
static	PLtsql_stmt *parse_sp_proc(int tok, int lineno, int return_dno);
static	void parse_sp_cursor_value(StringInfoData* pbuffer, int *pterm);

#define ereport_syntax_error(pos, msg, ...) \
	ereport(ERROR, \
		(errcode(ERRCODE_SYNTAX_ERROR), \
		 errmsg(msg, ##__VA_ARGS__) , \
		 parser_errposition(pos)))

static FILE *yyo = NULL;  /* yyo is not defined in Bison 2.4.1 */

%}

%expect 2
%name-prefix="pltsql_yy"
%locations

%debug
%verbose

%printer { fprintf(yyo, "%s", $$.ident); } T_WORD;
%printer { fprintf(yyo, "%s", NameListToString($$.idents)); } T_CWORD;
%printer { fprintf(yyo, "%s", NameOfDatum(&$$)); } T_DATUM;
%printer { fprintf(yyo, "%s", $$.name); } decl_varname;
%printer { fprintf(yyo, "%s", $$->typname); } decl_datatype;
%printer { fprintf(yyo, "%d", $$); } ICONST;
%printer { fprintf(yyo, "%s", $$); } IDENT;

%initial-action 
{ 
	extern bool pltsql_debug_parser;

	if (pltsql_debug_parser)
	{
	    yyo = stderr;
		yydebug = true;

		YYDPRINTF((yyo, "starting PL/tsql parser\n"));
	}
	else
		yydebug = false;
}

%union {
		core_YYSTYPE			core_yystype;
		/* these fields must match core_YYSTYPE: */
		int						ival;
		char					*str;
		const char				*keyword;

		PLword					word;
		PLcword					cword;
		PLwdatum				wdatum;
		bool					boolean;
		Oid						oid;
		struct
		{
			char *name;
			int  lineno;
		}						varname;
		struct
		{
			char		 *name;
			int			  lineno;
			PLtsql_datum *scalar;
			PLtsql_datum *row;
		}						forvariable;
		struct
		{
			char *label;
			int  n_initvars;
			int  *initvarnos;
		}						declhdr;
		struct
		{
			List *stmts;
			char *end_label;
			int   end_label_location;
		}						loop_body;
		List					*list;
		PLtsql_type			*dtype;
		PLtsql_datum			*datum;
		PLtsql_var				*var;
		PLtsql_expr			*expr;
		PLtsql_stmt			*stmt;
		PLtsql_condition		*condition;
		PLtsql_exception		*exception;
		PLtsql_exception_block	*exception_block;
		PLtsql_nsitem			*nsitem;
		PLtsql_diag_item		*diagitem;
		PLtsql_stmt_fetch		*fetch;
}

%type <varname> decl_varname
%type <boolean>	decl_const decl_notnull exit_type
%type <expr>	decl_defval decl_cursor_query
%type <dtype>	decl_datatype
%type <oid>		decl_collate
%type <datum>	decl_cursor_args
%type <list>	decl_cursor_arglist
%type <nsitem>	decl_aliasitem

%type <expr>	expr_until_semi expr_until_semi_or_bos expr_until_rightbracket
%type <expr>	expr_until_comma
%type <expr>	expr_until_loop
%type <str>     tokens_until_semi_or_bos
%type <expr>	opt_exitcond expr_until_bos

%type <datum>	assign_var
%type <ival>	foreach_slice
%type <var>		cursor_variable
%type <datum>	decl_cursor_arg
%type <forvariable>	for_variable
%type <stmt>	for_control stmt_foreach_a

%type <str>		any_identifier opt_block_label opt_label

%type <list>	proc_sect proc_stmts
%type <loop_body>	loop_body
%type <stmt>	proc_stmt pl_block
%type <stmt>    try_catch_block stmt_goto stmt_label try_block catch_block
%type <stmt>	stmt_assign stmt_if stmt_loop stmt_while stmt_exit
%type <stmt>	stmt_return stmt_raise stmt_execsql
%type <stmt>	stmt_for stmt_perform stmt_getdiag
%type <stmt>	stmt_open stmt_fetch stmt_move stmt_close stmt_null
%type <stmt>    pltsql_only_stmt plpgsql_only_stmt common_stmt stmt_exec
%type <stmt>	stmt_deallocate
%type <stmt>    stmt_use_db

%type <list>	proc_exceptions
%type <exception_block> exception_sect
%type <exception>	proc_exception
%type <condition>	proc_conditions proc_condition

%type <boolean>	getdiag_area_opt
%type <list>	getdiag_list
%type <diagitem> getdiag_list_item
%type <ival>	getdiag_item getdiag_target

%type <ival>	opt_scrollable
%type <fetch>	opt_fetch_direction
%type <ival>	opt_global_or_local

%type <keyword>	unreserved_keyword
%type <stmt>	stmt_print

%type <list>	decl_list
%type <stmt>    stmt_declare decl_statement
%type <stmt>	stmt_raiserror stmt_throw

/*
 * Basic non-keyword token types.  These are hard-wired into the core lexer.
 * They must be listed first so that their numeric codes do not depend on
 * the set of keywords.  Keep this list in sync with backend/parser/gram.y!
 *
 * Some of these are not directly referenced in this file, but they must be
 * here anyway.
 */
%token <str>	IDENT FCONST SCONST BCONST XCONST Op
%token <ival>	ICONST PARAM
%token			TYPECAST DOT_DOT COLON_EQUALS EQUALS_GREATER
%token			LESS_EQUALS GREATER_EQUALS NOT_EQUALS

/* Non-keyword TSQL tokens. They need to be appear after the common ones above. */
%token          DIALECT_TSQL
%token <str>	TSQL_XCONST TSQL_LABEL

/*
 * Other tokens recognized by pltsql's lexer interface layer (pl_scanner.c).
 */
%token <word>		T_WORD		/* unrecognized simple identifier */
%token <cword>		T_CWORD		/* unrecognized composite identifier */
%token <wdatum>		T_DATUM		/* a VAR, ROW, REC, or RECFIELD variable */
%token				LESS_LESS
%token				GREATER_GREATER

%token    			K_END_TRY
%token    			K_END_CATCH

/*
 * Keyword tokens.  Some of these are reserved and some are not;
 * see pl_scanner.c for info.  Be sure unreserved keywords are listed
 * in the "unreserved_keyword" production below.
 */
%token <keyword>	K_ABSOLUTE
%token <keyword>	K_ALIAS
%token <keyword>	K_ALL
%token <keyword>	K_AND
%token <keyword>	K_ARRAY
%token <keyword>	K_AS
%token <keyword>	K_ASSERT
%token <keyword>	K_BACKWARD
%token <keyword>	K_BEGIN
%token <keyword>    K_BREAK
%token <keyword>	K_BY
%token <keyword>	K_CALL
%token <keyword>	K_CASE
%token <keyword>    K_CATCH
%token <keyword>	K_CHAIN
%token <keyword>	K_CLOSE
%token <keyword>	K_COLLATE
%token <keyword>	K_COLUMN
%token <keyword>	K_COLUMN_NAME
%token <keyword>	K_COMMIT
%token <keyword>	K_CONSTANT
%token <keyword>	K_CONSTRAINT
%token <keyword>	K_CONSTRAINT_NAME
%token <keyword>	K_CONTINUE
%token <keyword>	K_CURRENT
%token <keyword>	K_CURSOR
%token <keyword>	K_DATATYPE
%token <keyword>	K_DEALLOCATE
%token <keyword>	K_DEBUG
%token <keyword>	K_DECLARE
%token <keyword>	K_DEFAULT
%token <keyword>	K_DETAIL
%token <keyword>	K_DIAGNOSTICS
%token <keyword>	K_DO
%token <keyword>	K_DUMP
%token <keyword>	K_DYNAMIC
%token <keyword>	K_ELSE
%token <keyword>	K_ELSIF
%token <keyword>	K_END
%token <keyword>	K_ERRCODE
%token <keyword>	K_ERROR
%token <keyword>	K_EXCEPTION
%token <keyword>	K_EXECUTE
%token <keyword>    K_EXEC
%token <keyword>	K_EXIT
%token <keyword>	K_FAST_FORWARD
%token <keyword>	K_FETCH
%token <keyword>	K_FIRST
%token <keyword>	K_FOR
%token <keyword>	K_FOREACH
%token <keyword>	K_FORWARD
%token <keyword>	K_FORWARD_ONLY
%token <keyword>	K_FROM
%token <keyword>	K_GET
%token <keyword>	K_GLOBAL
%token <keyword>	K_GOTO
%token <keyword>	K_HINT
%token <keyword>	K_IF
%token <keyword>	K_IMPORT
%token <keyword>	K_IN
%token <keyword>	K_INFO
%token <keyword>	K_INSERT
%token <keyword>	K_INTO
%token <keyword>	K_IS
%token <keyword>	K_KEYSET
%token <keyword>	K_LAST
%token <keyword>	K_LOCAL
%token <keyword>	K_LOG
%token <keyword>	K_LOOP
%token <keyword>	K_MESSAGE
%token <keyword>	K_MESSAGE_TEXT
%token <keyword>	K_MOVE
%token <keyword>	K_NEXT
%token <keyword>	K_NO
%token <keyword>	K_NOT
%token <keyword>	K_NOTICE
%token <keyword>	K_NULL
%token <keyword>	K_OPEN
%token <keyword>	K_OPTION
%token <keyword>	K_OR
%token <keyword>	K_OPTIMISTIC
%token <keyword>	K_OUT
%token <keyword>	K_OUTPUT
%token <keyword>	K_PERFORM
%token <keyword>	K_PG_CONTEXT
%token <keyword>	K_PG_DATATYPE_NAME
%token <keyword>	K_PG_EXCEPTION_CONTEXT
%token <keyword>	K_PG_EXCEPTION_DETAIL
%token <keyword>	K_PG_EXCEPTION_HINT
%token <keyword>	K_PRINT_STRICT_PARAMS
%token <keyword>	K_PRIOR
%token <keyword>	K_QUERY
%token <keyword>	K_RAISE
%token <keyword>	K_RAISERROR
%token <keyword>	K_READ_ONLY
%token <keyword>	K_RELATIVE
%token <keyword>	K_RESET
%token <keyword>	K_RETURN
%token <keyword>	K_RETURNED_SQLSTATE
%token <keyword>	K_REVERSE
%token <keyword>	K_ROLLBACK
%token <keyword>	K_ROW_COUNT
%token <keyword>	K_ROWTYPE
%token <keyword>	K_SCHEMA
%token <keyword>	K_SCHEMA_NAME
%token <keyword>	K_SCROLL
%token <keyword>	K_SCROLL_LOCKS
%token <keyword>	K_SET
%token <keyword>	K_SLICE
%token <keyword>	K_SQLSTATE
%token <keyword>	K_STACKED
%token <keyword>	K_STATIC
%token <keyword>	K_STRICT
%token <keyword>	K_TABLE
%token <keyword>	K_TABLE_NAME
%token <keyword>	K_THEN
%token <keyword>	K_THROW
%token <keyword>	K_TO
%token <keyword>    K_TRY
%token <keyword>	K_TYPE
%token <keyword>	K_UNION
%token <keyword>	K_USE
%token <keyword>	K_USE_COLUMN
%token <keyword>	K_USE_VARIABLE
%token <keyword>	K_USING
%token <keyword>	K_VARIABLE_CONFLICT
%token <keyword>	K_WARNING
%token <keyword>	K_WHEN
%token <keyword>	K_WHERE
%token <keyword>	K_WHILE
%token <keyword>	K_PRINT
%token <keyword>	K_RESULT_OID

%nonassoc LOWER_THAN_ELSE
%nonassoc K_ELSE

%%

pl_function		: comp_options proc_sect
					{
						if ($2 == NIL)
                        {
                            PLtsql_stmt_block *block = palloc0(sizeof(PLtsql_stmt_block));

                            block->cmd_type	  = PLTSQL_STMT_BLOCK;
                            block->lineno	  = 0;
                            block->label	  = NULL;
                            block->body		  = NULL;
                            block->exceptions = NULL;

                            pltsql_parse_result = block;
                        }
                        else
                        {
                            PLtsql_stmt *first = linitial($2);

                            /* 
                             * Make sure that we have a BEGIN/END block surrounding the
                             * body, even if we have to fake one here
                             */
                            if (first == NULL)
                                pltsql_parse_result = NULL;
                            else if (first->cmd_type == PLTSQL_STMT_BLOCK)
                                pltsql_parse_result = (PLtsql_stmt_block *) first;
                            else 
                            {
                                PLtsql_stmt_block *block = palloc0(sizeof(PLtsql_stmt_block));

                                block->cmd_type	  = PLTSQL_STMT_BLOCK;
                                block->lineno	  = pltsql_location_to_lineno(@2);
                                block->label	  = NULL;
                                block->body		  = $2;
                                block->exceptions = NULL;

                                pltsql_parse_result = block;
                            }
                        }
					}
				;

comp_options	:
				| comp_options comp_option
				;

comp_option		: '#' K_OPTION K_DUMP
					{
						pltsql_DumpExecTree = true;
					}
				| '#' K_VARIABLE_CONFLICT K_ERROR
					{
						pltsql_curr_compile->resolve_option = PLTSQL_RESOLVE_ERROR;
					}
				| '#' K_VARIABLE_CONFLICT K_USE_VARIABLE
					{
						pltsql_curr_compile->resolve_option = PLTSQL_RESOLVE_VARIABLE;
					}
				| '#' K_VARIABLE_CONFLICT K_USE_COLUMN
					{
						pltsql_curr_compile->resolve_option = PLTSQL_RESOLVE_COLUMN;
					}
				;

opt_semi		:
				| ';'
				;

opt_semi_or_commma :
				| ','
				| ';'
				;

pl_block		: opt_block_label K_BEGIN proc_sect exception_sect K_END
					{
						PLtsql_stmt_block *new;
						int				  tok1;
						int				  tok2;

						new = palloc0(sizeof(PLtsql_stmt_block));

						new->cmd_type	= PLTSQL_STMT_BLOCK;
						new->lineno		= pltsql_location_to_lineno(@3);
						new->label		= $1;
						new->body		= $3;
						new->exceptions	= $4;

						pltsql_peek2(&tok1, &tok2, NULL, NULL);

						if (tok1 == IDENT && tok2 == ';')
						{
							tok1 = yylex();
#if 0
							label = yylval.word.ident;
							check_labels($1.label, label, yylloc);
#endif
							tok2 = yylex(); /* consume optional semicolon */
						}
						else if (tok1 == ';')
						{
							tok1 = yylex(); /* consume optional semicolon */
						}

						pltsql_ns_pop();

						$$ = (PLtsql_stmt *)new;
					}
				;

try_catch_block : opt_block_label try_block catch_block
                    { 
						PLtsql_stmt_try_catch *new;

						new = palloc0(sizeof(PLtsql_stmt_try_catch));

						TSQLInstrumentation(INSTR_TSQL_TRY_CATCH_BLOCK);

						new->cmd_type = PLTSQL_STMT_TRY_CATCH;
						new->lineno	  = pltsql_location_to_lineno(@2);
						new->label	  = $1;
						new->body	  = $2;
						new->handler  = $3;

						$$ = (PLtsql_stmt *) new;
					}
                ;

try_block : K_BEGIN K_TRY opt_semi proc_sect K_END_TRY
                    {
						TSQLInstrumentation(INSTR_TSQL_TRY_BLOCK);
                        if (list_length($4) == 0)
                            $$ = NULL;  /* empty catch block */
                        if (list_length($4) == 1)
                            $$ = (PLtsql_stmt *) lfirst(list_head($4));  /* single stmt */
                        else
                        {
                            PLtsql_stmt_block *new;
                            new = palloc0(sizeof(PLtsql_stmt_block));

                            new->cmd_type	= PLTSQL_STMT_BLOCK;
                            new->lineno		= pltsql_location_to_lineno(@1);
                            new->label		= NULL;
                            new->body		= $4;
                            new->exceptions	= NULL;

                            $$ = (PLtsql_stmt *) new;
                        }
					}
                ; 

catch_block: K_BEGIN K_CATCH opt_semi proc_sect K_END_CATCH opt_semi
                    {
						TSQLInstrumentation(INSTR_TSQL_CATCH_BLOCK);
                        if (list_length($4) == 0)
                            $$ = NULL;  /* empty catch block */
                        if (list_length($4) == 1)
                            $$ = (PLtsql_stmt *) lfirst(list_head($4));  /* single stmt */
                        else
                        {
                            PLtsql_stmt_block *new;
                            new = palloc0(sizeof(PLtsql_stmt_block));

                            new->cmd_type	= PLTSQL_STMT_BLOCK;
                            new->lineno		= pltsql_location_to_lineno(@1);
                            new->label		= NULL;
                            new->body		= $4;
                            new->exceptions	= NULL;

                            $$ = (PLtsql_stmt *) new;
                        }
					}
                ; 

stmt_goto : K_GOTO T_WORD opt_semi
          {
              PLtsql_stmt_goto * stmt_goto = palloc0(sizeof(PLtsql_stmt_goto));
			  TSQLInstrumentation(INSTR_TSQL_GOTO_STMT);
              stmt_goto->cmd_type = PLTSQL_STMT_GOTO;
              stmt_goto->lineno = pltsql_location_to_lineno(@1);
              stmt_goto->cond = NULL;
              stmt_goto->target_pc = -1;
              stmt_goto->target_label = $2.ident;
              $$ = (PLtsql_stmt *) stmt_goto;
          }
          ;

stmt_label : TSQL_LABEL
            {
                PLtsql_stmt_label *label = palloc0(sizeof(PLtsql_stmt_label));
                label->cmd_type = PLTSQL_STMT_LABEL;
                label->lineno = pltsql_location_to_lineno(@1);
                label->label = pnstrdup($1, strlen($1) - 1 );  // exclude last :
                $$ = (PLtsql_stmt *) label;
            }
            ;

stmt_raiserror	: K_RAISERROR '('
					{
						PLtsql_stmt_raiserror *new;
						int tok;
						int term;
						PLtsql_expr	*expr;

						new = palloc(sizeof(PLtsql_stmt_raiserror));

						new->cmd_type	= PLTSQL_STMT_RAISERROR;
						new->lineno		= pltsql_location_to_lineno(@1);
						new->params		= NIL;
						new->paramno	= 3;
						new->log		= false;
						new->nowait		= false;
						new->seterror	= false;

						/* msg_id, msg_str or @local_variable */
						expr = read_sql_expression2(',', 0, ",", &term);
						new->params = lappend(new->params, expr);
						if (term != ',')
							ereport_syntax_error(yylloc, "invalid syntax");

						/* severity */
						expr = read_sql_expression2(',', 0, ",", &term);
						new->params = lappend(new->params, expr);
						if (term != ',')
							ereport_syntax_error(yylloc, "invalid syntax");

						/* state */
						expr = read_sql_expression2(')', ',', ") or ,", &term);
						new->params = lappend(new->params, expr);

						/* argument [ ,...n ] */
						while (term == ',')
						{
							if (new->paramno >= 23)
							{
								ereport_syntax_error(yylloc, 
													 "Too many substitution "
													 "parameters for RAISERROR. "
													 "Cannot exceed 20 "
													 "substitution parameters.");
							}
							expr = read_sql_expression2(')', ',', ") or ,", &term);
							new->params = lappend(new->params, expr);
							new->paramno++;
						}

						if (term != ')')
							ereport_syntax_error(yylloc, "invalid syntax");

						tok = yylex();
						/* WITH option [, ...n] */
						if (word_matches(tok, "with"))
						{
							term = ',';
							while (term == ',')
							{
								tok = yylex();
								if (tok_is_keyword(tok, &yylval, K_LOG, "log"))
								{
									new->log = true;
									ereport(NOTICE,
											(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
											 errmsg("The LOG option is currently ignored.")));
								}
								else if (word_matches(tok, "nowait"))
									new->nowait = true;
								else if (word_matches(tok, "seterror"))
									new->seterror = true;
								else
									ereport_syntax_error(yylloc, "invalid syntax");
								term = yylex();
							}
							tok = term;
						}

						if (!is_terminator_proc(tok, false))
							ereport_syntax_error(yylloc, "invalid syntax");

						$$ = (PLtsql_stmt *) new;
					}
				;

stmt_throw		: K_THROW 
					{
						PLtsql_stmt_throw *new;
						int tok;
						int term;
						PLtsql_expr *expr;

						new = palloc(sizeof(PLtsql_stmt_throw));

						new->cmd_type	= PLTSQL_STMT_THROW;
						new->lineno		= pltsql_location_to_lineno(@1);
						new->params		= NIL;

						tok = yylex();

						/* Check if THROW has parameter */
						if (!is_terminator_proc(tok, false))
						{
							pltsql_push_back_token(tok);

							/* error number */
							expr = read_sql_expression2(',', 0, ",", &term);
							new->params = lappend(new->params, expr);
							if (term != ',')
								ereport_syntax_error(yylloc, "invalid syntax");

							/* message */
							expr = read_sql_expression2(',', 0, ",", &term);
							new->params = lappend(new->params, expr);
							if (term != ',')
								ereport_syntax_error(yylloc, "invalid syntax");

							/* state */
							expr = read_sql_expression2(';', 0, "; or <stmt>`", &term);
							new->params = lappend(new->params, expr);
						}
						$$ = (PLtsql_stmt *) new;
					}
				;

stmt_use_db : K_USE T_WORD opt_semi
			{
				PLtsql_stmt_usedb *use_db = palloc0(sizeof(PLtsql_stmt_usedb));
				use_db->cmd_type = PLTSQL_STMT_USEDB;
				use_db->lineno = pltsql_location_to_lineno(@1);
				use_db->db_name = pstrdup($2.ident);
				$$ = (PLtsql_stmt *) use_db;
			}

opt_as:
      K_AS          {}
      | /* EMPTY */ {}

decl_statement	: decl_varname opt_as decl_const decl_datatype decl_collate decl_notnull decl_defval
					{
						PLtsql_variable	*var;

						/*
						 * If a collation is supplied, insert it into the
						 * datatype.  We assume decl_datatype always returns
						 * a freshly built struct not shared with other
						 * variables.
						 */
						if (OidIsValid($5))
						{
							if (!OidIsValid($4->collation))
								ereport(ERROR,
										(errcode(ERRCODE_DATATYPE_MISMATCH),
										 errmsg("collations are not supported by type %s",
												format_type_be($4->typoid)),
										 parser_errposition(@5)));
							$4->collation = $5;
						}

						var = pltsql_build_variable($1.name, $1.lineno,
													 $4, true);
						if ($3)
						{
							if (var->dtype == PLTSQL_DTYPE_VAR)
								((PLtsql_var *) var)->isconst = $3;
							else
								ereport(ERROR,
										(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
										 errmsg("row, record or table variable cannot be CONSTANT"),
										 parser_errposition(@3)));
						}

						if ($6)
						{
							if (var->dtype == PLTSQL_DTYPE_VAR)
								((PLtsql_var *) var)->notnull = $6;
							else
								ereport(ERROR,
										(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
										 errmsg("row, record or table variable cannot be NOT NULL"),
										 parser_errposition(@5)));
						}

						if ($7 != NULL)
						{
							if (var->dtype == PLTSQL_DTYPE_VAR)
								((PLtsql_var *) var)->default_val = $7;
							else
								ereport(ERROR,
										(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
										 errmsg("default value for row, record or table variable is not supported"),
										 parser_errposition(@5)));
						}

						if ($7 != NULL)
						{
							PLtsql_stmt_assign *init = palloc0(sizeof(*init));

							init->cmd_type = PLTSQL_STMT_ASSIGN;
							init->lineno = pltsql_location_to_lineno(@7);
							init->varno = var->dno;
							init->expr = $7;
							$$ = (PLtsql_stmt *) init;
						}
						else
						{
							if (var->dtype == PLTSQL_DTYPE_TBL)
							{
								PLtsql_stmt_decl_table *decl = palloc0(sizeof(*decl));
								decl->cmd_type = PLTSQL_STMT_DECL_TABLE;
								decl->lineno = pltsql_location_to_lineno(@1);
								decl->dno = var->dno;
								/*
								 * There are two ways of declaring a table variable:
								 * 1. with a pre-defined table type, e.g. DECLARE @tableVar tableType
								 */
								if ($4->origtypname && $4->origtypname->names)
									decl->tbltypname = pstrdup(NameListToQuotedString($4->origtypname->names));
								else
									decl->tbltypname = NULL;

								/* 2. without a pre-defined table type, e.g. DECLARE @tableVar table(a int, b int) */
								if ($4->coldef)
									decl->coldef = pstrdup($4->coldef);
								else
									decl->coldef = NULL;

								$$ = (PLtsql_stmt *) decl;
							}
							else
								$$ = NULL;
						}
					}
				| decl_varname K_ALIAS K_FOR decl_aliasitem opt_semi_or_commma
					{
						pltsql_ns_additem($4->itemtype,
										   $4->itemno, $1.name);
						$$ = NULL;
					}
				| decl_varname opt_scrollable K_CURSOR
					{
						PLtsql_stmt_decl_cursor *new_stmt;
						PLtsql_var *new;
						PLtsql_expr *curname_def;
						char		buf[1024];
						char		*cp1;
						char		*cp2;
						int tok;
						PLtsql_expr *query = NULL;
						int	extended_cursor_options = 0;

						extended_cursor_options = read_tsql_extended_cursor_options();

						tok = yylex();
						if (tok == K_FOR)
						{
							pltsql_ns_push($1.name, PLTSQL_LABEL_OTHER);
							query = parse_select_stmt_for_decl_cursor();
							/* pop local namespace for cursor args */
							pltsql_ns_pop();
						}
						else
						{
							pltsql_push_back_token(tok);
						}

						if ($2 != 0 && extended_cursor_options != 0)
						{
							/* customer cannot use the mixture of ISO syntax and T-SQL extended syntax */
							ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("mixture of ISO syntax and T-SQL extended syntax"),
								 parser_errposition(@2)));
						}

						new = (PLtsql_var *)
							pltsql_build_variable($1.name, $1.lineno,
												   pltsql_build_datatype(REFCURSOROID,
																		  -1,
																		 InvalidOid,
																		 NULL),
												   true);

						curname_def = palloc0(sizeof(PLtsql_expr));
#if 0
						curname_def->dtype = PLTSQL_DTYPE_EXPR;
#endif
						strncpy(buf, "SELECT ", 7);
						cp1 = new->refname;
						cp2 = buf + strlen(buf);
						/*
						 * Don't trust standard_conforming_strings here;
						 * it might change before we use the string.
						 */
						if (strchr(cp1, '\\') != NULL)
							*cp2++ = ESCAPE_STRING_SYNTAX;
						*cp2++ = '\'';
						while (*cp1)
						{
							if (SQL_STR_DOUBLE(*cp1, true))
								*cp2++ = *cp1;
							*cp2++ = *cp1++;
						}
						strncpy(cp2, "'::pg_catalog.refcursor", 23);
						curname_def->query = pstrdup(buf);
						new->default_val = curname_def;

						new->cursor_explicit_expr = query;
						if (query != NULL)
							new->cursor_explicit_argrow = -1;
						new->cursor_options = CURSOR_OPT_FAST_PLAN | $2 | extended_cursor_options;

						/*
						 * Other than pl/pgsql, T-SQL can distinguish a constant cursor (DECLARE CURSOR FOR QUERY)
						 * from a cursor variable (DECLARE CURSOR @curvar; SET @curvar = CURSOR FOR query).
						 * if query is given at declaration, mark it as constant.
						 * It is not assignable and it will affect cursor system function such as CURSOR_STATUS
						 */
						if (query != NULL)
							new->isconst = true;

						new_stmt = palloc0(sizeof(PLtsql_stmt_decl_cursor));
						new_stmt->cmd_type = PLTSQL_STMT_DECL_CURSOR;
						new_stmt->lineno = pltsql_location_to_lineno(@1);
						new_stmt->curvar = new->dno;
						new_stmt->cursor_explicit_expr = query;
						new_stmt->cursor_options = CURSOR_OPT_FAST_PLAN | $2 | extended_cursor_options;

						$$ = (PLtsql_stmt *) new_stmt;
					}
				| T_DATUM opt_scrollable K_CURSOR
					{
						/*
						 * It is allowed to re-declare constant cursor with the same name once the prior cursor is deallocated
						 * Currently, babelfishpg_tsq; parser scanner returns T_DATUM once the variable already exists in the namespace.
						 * To handle re-declation, we will update the variable information instead.
						 */
						PLtsql_stmt_decl_cursor *new;
						PLtsql_expr *query;
						int	extended_cursor_options;
						int tok;

						if ($1.datum->dtype != PLTSQL_DTYPE_VAR)
							ereport(ERROR,
								(errcode(ERRCODE_DATATYPE_MISMATCH),
								 errmsg("cursor variable must be a simple variable"),
								 parser_errposition(@1)));

						if (!is_cursor_datatype(((PLtsql_var *) $1.datum)->datatype->typoid))
							ereport(ERROR,
								(errcode(ERRCODE_DATATYPE_MISMATCH),
								 errmsg("variable \"%s\" must be of type cursor or refcursor",
										((PLtsql_var *) $1.datum)->refname),
								 parser_errposition(@1)));

						if (!(((PLtsql_var *) $1.datum)->isconst))
							ereport(ERROR,
								(errcode(ERRCODE_DATATYPE_MISMATCH),
								 errmsg("cursor variable \"%s\" cannot be re-declared",
										((PLtsql_var *) $1.datum)->refname),
								 parser_errposition(@1)));

						extended_cursor_options = read_tsql_extended_cursor_options();

						tok = yylex();
						if (tok == K_FOR)
						{
							pltsql_ns_push(((PLtsql_var *) $1.datum)->refname, PLTSQL_LABEL_OTHER);
							query = read_sql_stmt_bos("");
							/* pop local namespace for cursor args */
							pltsql_ns_pop();
						}
						else
						{
							yyerror("syntax error, expected \"FOR\"");
						}

						new = palloc0(sizeof(PLtsql_stmt_decl_cursor));
						new->cmd_type = PLTSQL_STMT_DECL_CURSOR;
						new->lineno = pltsql_location_to_lineno(@1);
						new->curvar = $1.datum->dno;
						new->cursor_explicit_expr = query;
						new->cursor_options = CURSOR_OPT_FAST_PLAN | $2 | extended_cursor_options;

						$$ = (PLtsql_stmt *) new;
					}
				;


opt_scrollable :
					{
						$$ = 0;
					}
				| K_NO K_SCROLL
					{
						$$ = CURSOR_OPT_NO_SCROLL;
					}
				| K_SCROLL
					{
						$$ = CURSOR_OPT_SCROLL;
					}
				;

decl_cursor_query :
					{
						$$ = read_sql_stmt_bos("");
					}
				;

decl_cursor_args :
					{
						$$ = NULL;
					}
				| '(' decl_cursor_arglist ')'
					{
						PLtsql_row *new;
						int i;
						ListCell *l;

						new = palloc0(sizeof(PLtsql_row));
						new->dtype = PLTSQL_DTYPE_ROW;
						new->lineno = pltsql_location_to_lineno(@1);
						new->rowtupdesc = NULL;
						new->nfields = list_length($2);
						new->fieldnames = palloc(new->nfields * sizeof(char *));
						new->varnos = palloc(new->nfields * sizeof(int));

						i = 0;
						foreach (l, $2)
						{
							PLtsql_variable *arg = (PLtsql_variable *) lfirst(l);
							new->fieldnames[i] = arg->refname;
							new->varnos[i] = arg->dno;
							i++;
						}
						list_free($2);

						pltsql_adddatum((PLtsql_datum *) new);
						$$ = (PLtsql_datum *) new;
					}
				;

decl_cursor_arglist : decl_cursor_arg
					{
						$$ = list_make1($1);
					}
				| decl_cursor_arglist ',' decl_cursor_arg
					{
						$$ = lappend($1, $3);
					}
				;

decl_cursor_arg : decl_varname decl_datatype
					{
						$$ = (PLtsql_datum *)
							pltsql_build_variable($1.name, $1.lineno,
												   $2, true);
					}
				;

decl_is_for		:	K_IS |		/* Oracle */
					K_FOR;		/* SQL standard */

decl_aliasitem	: T_WORD
					{
						PLtsql_nsitem *nsi;

						nsi = pltsql_ns_lookup(pltsql_ns_top(), false,
												$1.ident, NULL, NULL,
												NULL);
						if (nsi == NULL)
							ereport(ERROR,
									(errcode(ERRCODE_UNDEFINED_OBJECT),
									 errmsg("variable \"%s\" does not exist",
											$1.ident),
									 parser_errposition(@1)));
						$$ = nsi;
					}
				| T_CWORD
					{
						PLtsql_nsitem *nsi;

						if (list_length($1.idents) == 2)
							nsi = pltsql_ns_lookup(pltsql_ns_top(), false,
													strVal(linitial($1.idents)),
													strVal(lsecond($1.idents)),
													NULL,
													NULL);
						else if (list_length($1.idents) == 3)
							nsi = pltsql_ns_lookup(pltsql_ns_top(), false,
													strVal(linitial($1.idents)),
													strVal(lsecond($1.idents)),
													strVal(lthird($1.idents)),
													NULL);
						else
							nsi = NULL;
						if (nsi == NULL)
							ereport(ERROR,
									(errcode(ERRCODE_UNDEFINED_OBJECT),
									 errmsg("variable \"%s\" does not exist",
											NameListToString($1.idents)),
									 parser_errposition(@1)));
						$$ = nsi;
					}
				;

decl_varname	: T_WORD
					{
						$$.name = $1.ident;
						$$.lineno = pltsql_location_to_lineno(@1);
						/*
						 * Check to make sure name isn't already declared
						 * in the current block.
						 */
						if (pltsql_ns_lookup(pltsql_ns_top(), true,
											  $1.ident, NULL, NULL,
											  NULL) != NULL)
							yyerror("duplicate declaration");
					}
				| unreserved_keyword
					{
						$$.name = pstrdup($1);
						$$.lineno = pltsql_location_to_lineno(@1);
						/*
						 * Check to make sure name isn't already declared
						 * in the current block.
						 */
						if (pltsql_ns_lookup(pltsql_ns_top(), true,
											  $1, NULL, NULL,
											  NULL) != NULL)
							yyerror("duplicate declaration");
					}
				;

decl_const		:
					{ $$ = false; }
				| K_CONSTANT
					{ $$ = true; }
				;

decl_datatype	:
					{
						/*
						 * If there's a lookahead token, read_datatype
						 * should consume it.
						 */
						$$ = read_datatype(yychar);
						yyclearin;
					}
				;

decl_collate	:
					{ $$ = InvalidOid; }
				| K_COLLATE T_WORD
					{
						$$ = get_collation_oid(list_make1(makeString($2.ident)),
											   false);
					}
				| K_COLLATE T_CWORD
					{
						$$ = get_collation_oid($2.idents, false);
					}
				;

decl_notnull	:
					{ $$ = false; }
				| K_NOT K_NULL
					{ $$ = true; }
				;

decl_defval		:  
                    { $$ = NULL; }
                | assign_operator
					{
						int term;

						$$ = read_sql_construct_bos(',', ';', 0, "comma or <stmt>",  
													"SELECT ",
													true, true, true, 
													NULL, &term, true, NULL, false);
						if (term == ',')
							pltsql_push_back_token(term);
					}
				;

stmt_declare	: K_DECLARE decl_list
					{
						/*
						 * A DECLARE statement may declare one or more variables,
						 * each of which may have a default value (an initializer).
						 *
						 * To implement variable initialization, we build a 
						 * statement of type PLtsql_stmt_init.  This statement
						 * contains a List of PLtsql_stmt_assign statements, each
						 * of which assigns the default value to the corresponding
						 * variable.
						 *
						 * At execution time, we execute each of these assignment
						 * statements, in order.
						 */
						PLtsql_stmt_init *new = palloc0(sizeof *new);

						new->cmd_type = PLTSQL_STMT_INIT;
						new->lineno	  = pltsql_location_to_lineno(@1);
						new->label	  = NULL;
						new->inits	  = $2;
						
						$$ = (PLtsql_stmt *) new;
					}
				;

decl_list       : decl_statement 
                    {
						if ($1)
							$$ = list_make1($1);
						else
							$$ = NULL;
					}
                | decl_list ',' decl_statement
				    {
						if ($3)
							$$ = lappend($1, $3);
						else
							$$ = $1;
					}
				;

assign_operator	: '='
				| COLON_EQUALS
				;

proc_sect		:
					{ $$ = NIL; }
				| proc_stmts
					{ $$ = $1; }
				;

proc_stmts		: proc_stmts proc_stmt
						{
							if ($2 == NULL)
								$$ = $1;
							else
								$$ = lappend($1, $2);
						}
				| proc_stmt
						{
							if ($1 == NULL)
								$$ = NIL;
							else
								$$ = list_make1($1);
						}
				;

proc_stmt		: common_stmt |
				  plpgsql_only_stmt |
				  pltsql_only_stmt
				;

common_stmt	    : pl_block
						{ $$ = $1; }
				| stmt_assign
						{ $$ = $1; }
				| stmt_if
						{ $$ = $1; }
				| stmt_while
						{ $$ = $1; }
				| stmt_for
						{ $$ = $1; }
				| stmt_foreach_a
						{ $$ = $1; }
				| stmt_exit
						{ $$ = $1; }
				| stmt_return
						{ $$ = $1; }
				| stmt_raise
						{ $$ = $1; }
				| stmt_exec
						{ $$ = $1; }
				| stmt_execsql
						{ $$ = $1; }
				| stmt_perform
						{ $$ = $1; }
				| stmt_getdiag
						{ $$ = $1; }
				| stmt_open
						{ $$ = $1; }
				| stmt_fetch
						{ $$ = $1; }
				| stmt_move
						{ $$ = $1; }
				| stmt_close
						{ $$ = $1; }
				| stmt_null
						{ $$ = $1; }
				| stmt_declare opt_semi
						{ $$ = $1; }
				| stmt_deallocate
						{ $$ = $1; }
					;

plpgsql_only_stmt	:	stmt_loop
						{ $$ = $1; }
					;

pltsql_only_stmt	:	stmt_print
						{ $$ = $1; }
                    |   try_catch_block
						{ $$ = $1; }
                    |   stmt_goto
						{ $$ = $1; }
                    |   stmt_label
						{ $$ = $1; }
					|	stmt_raiserror
						{ $$ = $1; }
					|	stmt_throw
						{ $$ = $1; }
					|   stmt_use_db
					    { $$ = $1; }
					;

stmt_perform	: K_PERFORM expr_until_semi_or_bos
					{
						PLtsql_stmt_perform *new;

						new = palloc0(sizeof(PLtsql_stmt_perform));
						new->cmd_type = PLTSQL_STMT_PERFORM;
						new->lineno   = pltsql_location_to_lineno(@1);
						new->expr  = $2;

						$$ = (PLtsql_stmt *)new;
					}
				;

stmt_exec		: exec_keyword
					{
						/* 
						 * Use the first token after EXEC/EXECUTE to tell between
						 * different EXEC functionalities.
						 */
						int tok1 = yylex();

						if (tok1 == '(')
						{
							PLtsql_stmt_exec_batch *new_batch;

							new_batch = palloc0(sizeof(PLtsql_stmt_exec_batch));
							new_batch->cmd_type = PLTSQL_STMT_EXEC_BATCH;
							new_batch->lineno = pltsql_location_to_lineno(@1);
							new_batch->expr = read_sql_expression(')', ")");

							$$ = (PLtsql_stmt *) new_batch;
						}
						else
						{
							int return_code_dno = -1;
							int sp_proc_tok = -1;

							if (word_matches_sp_proc(tok1))
							{
								sp_proc_tok = tok1;
							}
							else if (tok1 == T_DATUM)
							{
								YYSTYPE lval = pltsql_yylval;
								int	tok2;
								int tok3;

								return_code_dno = ((PLtsql_var *) lval.wdatum.datum)->dno;
								if ((tok2 = yylex()) != '=')
								{
									pltsql_push_back_token(tok2);
									pltsql_push_back_token(tok1);
								}
								else if (word_matches_sp_proc(tok3 = yylex()))
								{
									sp_proc_tok = tok3;
								}
								else
								{
									pltsql_push_back_token(tok3);
								}
							}
							else
							{
								pltsql_push_back_token(tok1);
							}

							if (sp_proc_tok != -1)
							{
								$$ = parse_sp_proc(sp_proc_tok, @1, return_code_dno);
							}
							else
							{
								PLtsql_stmt_exec *new;

								new = palloc0(sizeof(PLtsql_stmt_exec));
								new->cmd_type = PLTSQL_STMT_EXEC;
								new->lineno = pltsql_location_to_lineno(@1);
								new->expr = read_sql_stmt_bos("EXEC ");
								new->is_call = true;
								new->return_code_dno = return_code_dno;

								/* we will evaluate this later. */
								new->is_scalar_func = false;

								$$ = (PLtsql_stmt *) new;
							}
						}
						/* consume the optional semicolon at the end of the
						 * execute statement */
						if (pltsql_peek() == ';') {
							yylex();
						}
					}
			;

exec_keyword:		K_EXEC
			| K_EXECUTE
			;

/*
 * NOTE: the TSQL SET (local_variable) command supports the usual simple
 *       assignment operator (=) as well as a set of complex operators
 *       (+=. -=, *=, &=, etc.).
 * 
 *       The lexer will return the simple assignment operator as a single
 *       character (=) but will return the two-character operators as an
 *       Op token
 *
 *       Therefore, we have two different rules for SET
 */
stmt_assign		: K_SET assign_var '='
                    {
						PLtsql_stmt_assign *new;
						int tok;

						tok = yylex();

						if (tok_is_keyword(tok, &yylval, K_CURSOR, "cursor"))
						{
							/* T-SQL specific syntax. Declare anonymous cursor and assign it to assign_var. */
							int cursor_options;
							PLtsql_expr *query;
							PLtsql_var *new_curvar;
							char varname[NAMEDATALEN];

							PLtsql_expr *curname_def;
							PLtsql_expr *new_curvar_expr;
							char buf[1024];
							char *cp1;
							char *cp2;
							int tokloc = yylloc;

							if ($2->dtype != PLTSQL_DTYPE_VAR)
								ereport(ERROR,
									(errcode(ERRCODE_DATATYPE_MISMATCH),
									 errmsg("cursor variable must be a simple variable"),
									 parser_errposition(@1)));

							if (!is_cursor_datatype(((PLtsql_var *) $2)->datatype->typoid))
								ereport(ERROR,
									(errcode(ERRCODE_DATATYPE_MISMATCH),
									 errmsg("variable \"%s\" must be of type cursor or refcursor",
											((PLtsql_var *) $2)->refname),
									 parser_errposition(@1)));

							if (((PLtsql_var *) $2)->isconst)
								ereport(ERROR,
									(errcode(ERRCODE_DATATYPE_MISMATCH),
									 errmsg("constant cursor \"%s\" is not assignable",
											((PLtsql_var *) $2)->refname),
									 parser_errposition(@1)));

							cursor_options = read_tsql_extended_cursor_options();

							tok = yylex();
							if (tok != K_FOR)
								yyerror("syntax error, expected \"FOR\"");

							query = read_sql_stmt_bos("");

							/* Start to build anonymous constant cursor. similar with DECLARE CURSOR */

							/* Generate cursor name based on pointer of PLtsql_stmt_assign since it is unique until procedure is dropped */
							new = palloc0(sizeof(PLtsql_stmt_assign));

							snprintf(varname, NAMEDATALEN, "%s##sys_gen##%p", ((PLtsql_var *) $2)->refname, (void *) new);
							new_curvar = (PLtsql_var *)
								pltsql_build_variable(pstrdup(varname), tokloc,
								                      pltsql_build_datatype(REFCURSOROID, -1, InvalidOid, NULL),
								                      true);

							curname_def = palloc0(sizeof(PLtsql_expr));
#if 0
							curname_def->dtype = PLTSQL_DTYPE_EXPR;
#endif
							strncpy(buf, "SELECT ", 7);
							cp1 = new_curvar->refname;
							cp2 = buf + strlen(buf);
							/*
							 * Don't trust standard_conforming_strings here;
							* it might change before we use the string.
							*/
							if (strchr(cp1, '\\') != NULL)
								*cp2++ = ESCAPE_STRING_SYNTAX;
							*cp2++ = '\'';
							while (*cp1)
							{
								if (SQL_STR_DOUBLE(*cp1, true))
									*cp2++ = *cp1;
								*cp2++ = *cp1++;
							}
							strncpy(cp2, "'::pg_catalog.refcursor", 23);
							curname_def->query = pstrdup(buf);
							new_curvar->default_val = curname_def;

							new_curvar->cursor_explicit_expr = query;
							new_curvar->cursor_explicit_argrow = -1;
							new_curvar->cursor_options = CURSOR_OPT_FAST_PLAN | cursor_options | PGTSQL_CURSOR_ANONYMOUS;
							new_curvar->isconst = true;

							/* Start of assignment part */

							new_curvar_expr = palloc0(sizeof(PLtsql_expr));
							snprintf(buf, 1024, "SELECT \"%s\"", varname);
							new_curvar_expr->query = pstrdup(buf);
							new_curvar_expr->ns = pltsql_ns_top();

							new->cmd_type = PLTSQL_STMT_ASSIGN;
							new->lineno   = pltsql_location_to_lineno(@2);
							new->varno    = $2->dno;
							new->expr     = new_curvar_expr;

							$$ = (PLtsql_stmt *) new;
						}
						else
						{
							pltsql_push_back_token(tok);

							new = palloc0(sizeof(PLtsql_stmt_assign));
							new->cmd_type = PLTSQL_STMT_ASSIGN;
							new->lineno   = pltsql_location_to_lineno(@2);
							new->varno    = $2->dno;
							new->expr     = read_sql_expression_bos(';', ";", false);

							$$ = (PLtsql_stmt *) new;
						}
					}
                | K_SET assign_var Op expr_until_semi_or_bos
					{
						PLtsql_stmt_assign *new;
						int operator_len = strlen($3);

						if ((operator_len == 2) && ($3[1] == '='))
						{
							/*
							 * We have a statement such as:
							 *    SET @result *= (@val + 1)
							 * Convert that into:
							 *    SET @result = @result * (@val + 1)
							 */
							StringInfoData new_query;
							char *varname = ((PLtsql_variable *) (pltsql_Datums[$2->dno]))->refname;
							char operator;

							/*
							 * Figure out which operator we should use.  TSQL and Postgres agree
							 * on the semantics of most operators, but spell XOR differently. 
							 * That means that we have to translate the TSQL XOR spelling from
							 * '^' into the PostgreSQL spelling, '#'
							 */
							switch ($3[0])
							{
							    case '+':    /* addition */
							    case '-':    /* subtraction */
							    case '/':    /* division */
							    case '*':    /* multiplication */
							    case '%':    /* modulus */
							    case '|':    /* bitwise OR */
							    case '&':    /* bitwise AND */
									operator = $3[0];
									break;

								/*
								 * TSQL uses ^ to represent bitwise XOR, but
								 * Postgres uses #
								 */
							    case '^':
									operator = '#';
									break;

							    default:
								{
									ereport(ERROR,
											(errcode(ERRCODE_SYNTAX_ERROR),
											 errmsg("invalid operator"),
											 parser_errposition(@3)));
									break;
								}
							}
							
							new = palloc0(sizeof(PLtsql_stmt_assign));
							new->cmd_type = PLTSQL_STMT_ASSIGN;
							new->lineno   = pltsql_location_to_lineno(@2);
							new->varno = $2->dno;
							new->expr  = $4;

							/*
							 * Now replace the query (new->expr->query) with a new
							 * form that eliminates the complex assignment operator.
							 *
							 * In other words, change the query from:
							 *    SET @var ^= 5 - 1
							 * to
							 *    SELECT @var ^ (5 -1)
							 */
							initStringInfo(&new_query);

							appendStringInfo(&new_query, "SELECT \"%s\" %c (%s)", varname, operator, $4->query + sizeof("SELECT"));

							new->expr->query = new_query.data;

							$$ = (PLtsql_stmt *) new;
						}
						else
						{
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("invalid operator"),
									 parser_errposition(@3)));

							$$ = (PLtsql_stmt *) NULL;
						}
						
					}
                | K_SET T_WORD tokens_until_semi_or_bos
					{
						/*
						 * This is a SET command that modifies a GUC (as 
						 * opposed to other SET commands that assign a 
						 * value to a @local_variable).
						 *
						 * For now, we call on the main parser/executor
						 * to handle this statement so we just build a
						 * PLtsql_stmt_execsql statement here at parse
						 * time and treat it like an SQL statement at 
						 * execute time (just like an INSERT or DELETE or
						 * other SQL command)
						 */
						PLtsql_stmt_execsql *stmt = palloc(sizeof(*stmt));
						PLtsql_expr			*expr = palloc(sizeof(*expr));
						StringInfoData       cmd;

						initStringInfo(&cmd);

						appendStringInfo(&cmd, "SET %s %s", $2.ident, $3);

						expr->query	   = cmd.data;
						expr->plan	   = NULL;
						expr->paramnos = NULL;
						expr->rwparam  = -1;
						expr->ns	   = pltsql_ns_top();
						
						stmt->cmd_type = PLTSQL_STMT_EXECSQL;
						stmt->lineno   = pltsql_location_to_lineno(@2);
						stmt->sqlstmt  = expr;
						stmt->into     = false;
						stmt->strict   = false;
						stmt->target   = NULL;
						stmt->mod_stmt_tablevar = false;
						stmt->need_to_push_result = false;
						stmt->is_tsql_select_assign_stmt = false;
							
						$$ = (PLtsql_stmt *) stmt;
					}
 				;

stmt_getdiag	: K_GET getdiag_area_opt K_DIAGNOSTICS getdiag_list opt_semi
					{
						PLtsql_stmt_getdiag	 *new;
						ListCell		*lc;

						new = palloc0(sizeof(PLtsql_stmt_getdiag));
						new->cmd_type = PLTSQL_STMT_GETDIAG;
						new->lineno   = pltsql_location_to_lineno(@1);
						new->is_stacked = $2;
						new->diag_items = $4;

						/*
						 * Check information items are valid for area option.
						 */
						foreach(lc, new->diag_items)
						{
							PLtsql_diag_item *ditem = (PLtsql_diag_item *) lfirst(lc);

							switch (ditem->kind)
							{
								/* these fields are disallowed in stacked case */
								case PLTSQL_GETDIAG_ROW_COUNT:
									if (new->is_stacked)
										ereport(ERROR,
												(errcode(ERRCODE_SYNTAX_ERROR),
												 errmsg("diagnostics item %s is not allowed in GET STACKED DIAGNOSTICS",
														pltsql_getdiag_kindname(ditem->kind)),
												 parser_errposition(@1)));
									break;
								/* these fields are disallowed in current case */
								case PLTSQL_GETDIAG_ERROR_CONTEXT:
								case PLTSQL_GETDIAG_ERROR_DETAIL:
								case PLTSQL_GETDIAG_ERROR_HINT:
								case PLTSQL_GETDIAG_RETURNED_SQLSTATE:
								case PLTSQL_GETDIAG_MESSAGE_TEXT:
									if (!new->is_stacked)
										ereport(ERROR,
												(errcode(ERRCODE_SYNTAX_ERROR),
												 errmsg("diagnostics item %s is not allowed in GET CURRENT DIAGNOSTICS",
														pltsql_getdiag_kindname(ditem->kind)),
												 parser_errposition(@1)));
									break;
								default:
									elog(ERROR, "unrecognized diagnostic item kind: %d",
										 ditem->kind);
									break;
							}
						}

						$$ = (PLtsql_stmt *)new;
					}
				;

getdiag_area_opt :
					{
						$$ = false;
					}
				| K_CURRENT
					{
						$$ = false;
					}
				| K_STACKED
					{
						$$ = true;
					}
				;

getdiag_list : getdiag_list ',' getdiag_list_item
					{
						$$ = lappend($1, $3);
					}
				| getdiag_list_item
					{
						$$ = list_make1($1);
					}
				;

getdiag_list_item : getdiag_target assign_operator getdiag_item
					{
						PLtsql_diag_item *new;

						new = palloc(sizeof(PLtsql_diag_item));
						new->target = $1;
						new->kind = $3;

						$$ = new;
					}
				;

getdiag_item :
					{
						int	tok = yylex();

						if (tok_is_keyword(tok, &yylval,
										   K_ROW_COUNT, "row_count"))
							$$ = PLTSQL_GETDIAG_ROW_COUNT;
						else if (tok_is_keyword(tok, &yylval,
												K_PG_EXCEPTION_DETAIL, "pg_exception_detail"))
							$$ = PLTSQL_GETDIAG_ERROR_DETAIL;
						else if (tok_is_keyword(tok, &yylval,
												K_PG_EXCEPTION_HINT, "pg_exception_hint"))
							$$ = PLTSQL_GETDIAG_ERROR_HINT;
						else if (tok_is_keyword(tok, &yylval,
												K_PG_EXCEPTION_CONTEXT, "pg_exception_context"))
							$$ = PLTSQL_GETDIAG_ERROR_CONTEXT;
						else if (tok_is_keyword(tok, &yylval,
												K_MESSAGE_TEXT, "message_text"))
							$$ = PLTSQL_GETDIAG_MESSAGE_TEXT;
						else if (tok_is_keyword(tok, &yylval,
												K_RETURNED_SQLSTATE, "returned_sqlstate"))
							$$ = PLTSQL_GETDIAG_RETURNED_SQLSTATE;
						else
							yyerror("unrecognized GET DIAGNOSTICS item");
					}
				;

getdiag_target	: T_DATUM
					{
						check_assignable($1.datum, @1);
						if ($1.datum->dtype == PLTSQL_DTYPE_ROW ||
							$1.datum->dtype == PLTSQL_DTYPE_REC)
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("\"%s\" is not a scalar variable",
											NameOfDatum(&($1))),
									 parser_errposition(@1)));
						$$ = $1.datum->dno;
					}
				| T_WORD
					{
						/* just to give a better message than "syntax error" */
						word_is_not_variable(&($1), @1);
					}
				| T_CWORD
					{
						/* just to give a better message than "syntax error" */
						cword_is_not_variable(&($1), @1);
					}
				;


assign_var		: T_DATUM
					{
						check_assignable($1.datum, @1);
						$$ = $1.datum;
					}
				| assign_var '[' expr_until_rightbracket
					{
						PLtsql_arrayelem *new;

						new				   = palloc0(sizeof(PLtsql_arrayelem));
						new->dtype		   = PLTSQL_DTYPE_ARRAYELEM;
						new->subscript	   = $3;
						new->arrayparentno = $1->dno;
						/* initialize cached type data to "not valid" */
						new->parenttypoid  = InvalidOid;

						pltsql_adddatum((PLtsql_datum *) new);

						$$ = (PLtsql_datum *)new;
					}
				;

stmt_if			: K_IF expr_until_bos proc_stmt %prec LOWER_THAN_ELSE
				{
						PLtsql_stmt_if *new;

						new = palloc0(sizeof(PLtsql_stmt_if));
						new->cmd_type = PLTSQL_STMT_IF;
						new->lineno	  = pltsql_location_to_lineno(@1);
						new->cond	  = $2;
						new->then_body	= $3;

						$$ = (PLtsql_stmt *)new;
				}
				| K_IF expr_until_bos proc_stmt K_ELSE proc_stmt
				{
						PLtsql_stmt_if *new;

						new = palloc0(sizeof(PLtsql_stmt_if));
						new->cmd_type = PLTSQL_STMT_IF;
						new->lineno	  = pltsql_location_to_lineno(@1);
						new->cond	  = $2;
						new->then_body	= $3;
						new->else_body  = $5;

						$$ = (PLtsql_stmt *)new;
				}
				;

stmt_loop		: opt_block_label K_LOOP loop_body
					{
						PLtsql_stmt_loop *new;

						new = palloc0(sizeof(PLtsql_stmt_loop));
						new->cmd_type = PLTSQL_STMT_LOOP;
						new->lineno   = pltsql_location_to_lineno(@2);
						new->label	  = $1;
						new->body	  = $3.stmts;

						check_labels($1, $3.end_label, $3.end_label_location);
						pltsql_ns_pop();

						$$ = (PLtsql_stmt *)new;
					}
				;

stmt_while		: opt_block_label K_WHILE expr_until_bos K_LOOP loop_body
					{
						PLtsql_stmt_while *new;

						new = palloc0(sizeof(PLtsql_stmt_while));
						new->cmd_type = PLTSQL_STMT_WHILE;
						new->lineno   = pltsql_location_to_lineno(@2);
						new->label	  = $1;
						new->cond	  = $3;
						new->body	  = $5.stmts;

						check_labels($1, $5.end_label, $5.end_label_location);
						pltsql_ns_pop();

						$$ = (PLtsql_stmt *)new;
					}
				| opt_block_label K_WHILE expr_until_bos common_stmt
					{
						PLtsql_stmt_while *new;

						new = palloc0(sizeof(PLtsql_stmt_while));
						new->cmd_type = PLTSQL_STMT_WHILE;
						new->lineno   = pltsql_location_to_lineno(@2);
						new->label	  = $1;
						new->cond	  = $3;
						new->body	  = list_make1($4);

						pltsql_ns_pop();

						$$ = (PLtsql_stmt *)new;
					}
				;



stmt_for		: opt_block_label K_FOR for_control loop_body
					{
						/* This runs after we've scanned the loop body */
						if ($3->cmd_type == PLTSQL_STMT_FORI)
						{
							PLtsql_stmt_fori *new;

							new = (PLtsql_stmt_fori *) $3;
							new->lineno = pltsql_location_to_lineno(@2);
							new->label	= $1;
							new->body	= $4.stmts;
							$$			= (PLtsql_stmt *) new;
						}
						else
						{
							PLtsql_stmt_forq *new;

							Assert($3->cmd_type == PLTSQL_STMT_FORS ||
								   $3->cmd_type == PLTSQL_STMT_FORC ||
								   $3->cmd_type == PLTSQL_STMT_DYNFORS);
							/* forq is the common supertype of all three */
							new = (PLtsql_stmt_forq *) $3;
							new->lineno			 = pltsql_location_to_lineno(@2);
							new->label			 = $1;
							new->body			 = $4.stmts;
							$$ = (PLtsql_stmt *) new;
						}

						check_labels($1, $4.end_label, $4.end_label_location);
						/* close namespace started in opt_block_label */
						pltsql_ns_pop();
					}
				;

for_control		: for_variable K_IN
					{
						int	tok	   = yylex();
						int	tokloc = yylloc;

						if (tok == K_EXECUTE)
						{
							/* EXECUTE means it's a dynamic FOR loop */
							PLtsql_stmt_dynfors	*new;
							PLtsql_expr			*expr;
							int					 term;

							expr = read_sql_expression2(K_LOOP, K_USING,
														"LOOP or USING",
														&term);

							new = palloc0(sizeof(PLtsql_stmt_dynfors));
							new->cmd_type = PLTSQL_STMT_DYNFORS;

							if ($1.row)
							{
								new->var = (PLtsql_variable *) $1.row;
								check_assignable($1.row, @1);
							}
							else if ($1.scalar)
							{
								/* convert single scalar to list */
								new->var = (PLtsql_variable *)
									make_scalar_list1($1.name, $1.scalar,
													  $1.lineno, @1);
								/* make_scalar_list1 did check_assignable */
							}
							else
							{
								ereport(ERROR,
										(errcode(ERRCODE_DATATYPE_MISMATCH),
										 errmsg("loop variable of loop over rows must be a record variable or list of scalar variables"),
										 parser_errposition(@1)));
							}
							new->query = expr;

							if (term == K_USING)
							{
								do
								{
									expr	   = read_sql_expression2(',', K_LOOP,
																", or LOOP",
																&term);
									new->params = lappend(new->params, expr);
								} while (term == ',');
							}

							$$ = (PLtsql_stmt *) new;
						}
						else if (tok													== T_DATUM			&&
								 yylval.wdatum.datum->dtype								== PLTSQL_DTYPE_VAR &&
								 is_cursor_datatype(((PLtsql_var *) yylval.wdatum.datum)->datatype->typoid))
						{
							/* It's FOR var IN cursor */
							PLtsql_stmt_forc *new;
							PLtsql_var		 *cursor = (PLtsql_var *) yylval.wdatum.datum;

							new = (PLtsql_stmt_forc *) palloc0(sizeof(PLtsql_stmt_forc));
							new->cmd_type = PLTSQL_STMT_FORC;
							new->curvar = cursor->dno;

							/* Should have had a single variable name */
							if ($1.scalar && $1.row)
								ereport(ERROR,
										(errcode(ERRCODE_SYNTAX_ERROR),
										 errmsg("cursor FOR loop must have only one target variable"),
										 parser_errposition(@1)));

							/* can't use an unbound cursor this way */
							if (cursor->cursor_explicit_expr == NULL)
								ereport(ERROR,
										(errcode(ERRCODE_SYNTAX_ERROR),
										 errmsg("cursor FOR loop must use a bound cursor variable"),
										 parser_errposition(tokloc)));

							/* collect cursor's parameters if any */
							new->argquery = read_cursor_args(cursor,
															 K_LOOP,
															 "LOOP");

							/* create loop's private RECORD variable */
							new->var = (PLtsql_variable *)
								pltsql_build_record($1.name,
													$1.lineno,
													NULL,
													RECORDOID,
													true);

							$$ = (PLtsql_stmt *) new;
						}
						else
						{
							PLtsql_expr	*expr1;
							int			 expr1loc;
							bool		 reverse = false;

							/*
							 * We have to distinguish between two
							 * alternatives: FOR var IN a .. b and FOR
							 * var IN query. Unfortunately this is
							 * tricky, since the query in the second
							 * form needn't start with a SELECT
							 * keyword.  We use the ugly hack of
							 * looking for two periods after the first
							 * token. We also check for the REVERSE
							 * keyword, which means it must be an
							 * integer loop.
							 */
							if (tok_is_keyword(tok, &yylval,
											   K_REVERSE, "reverse"))
								reverse = true;
							else
								pltsql_push_back_token(tok);

							/*
							 * Read tokens until we see either a ".."
							 * or a LOOP. The text we read may not
							 * necessarily be a well-formed SQL
							 * statement, so we need to invoke
							 * read_sql_construct directly.
							 */
							expr1 = read_sql_construct(DOT_DOT,
													   K_LOOP,
													   0,
													   "LOOP",
													   "SELECT ",
													   true,
													   false,
													   true,
													   &expr1loc,
													   &tok);

							if (tok == DOT_DOT)
							{
								/* Saw "..", so it must be an integer loop */
								PLtsql_expr		 *expr2;
								PLtsql_expr		 *expr_by;
								PLtsql_var		 *fvar;
								PLtsql_stmt_fori *new;

								/* Check first expression is well-formed */
								check_sql_expr(expr1->query, expr1loc, 7);

								/* Read and check the second one */
								expr2 = read_sql_expression2(K_LOOP, K_BY,
															 "LOOP",
															 &tok);

								/* Get the BY clause if any */
								if (tok		== K_BY)
									expr_by	 = read_sql_expression(K_LOOP,
																  "LOOP");
								else
									expr_by = NULL;

								/* Should have had a single variable name */
								if ($1.scalar && $1.row)
									ereport(ERROR,
											(errcode(ERRCODE_SYNTAX_ERROR),
											 errmsg("integer FOR loop must have only one target variable"),
											 parser_errposition(@1)));

								/* create loop's private variable */
								fvar = (PLtsql_var *)
									pltsql_build_variable($1.name,
														   $1.lineno,
														   pltsql_build_datatype(INT4OID,
																				  -1,
																				 InvalidOid,
																				 NULL),
														   true);

								new = palloc0(sizeof(PLtsql_stmt_fori));
								new->cmd_type = PLTSQL_STMT_FORI;
								new->var	  = fvar;
								new->reverse  = reverse;
								new->lower	  = expr1;
								new->upper	  = expr2;
								new->step	  = expr_by;

								$$ = (PLtsql_stmt *) new;
							}
							else
							{
								/*
								 * No "..", so it must be a query loop. We've
								 * prefixed an extra SELECT to the query text,
								 * so we need to remove that before performing
								 * syntax checking.
								 */
								char				*tmp_query;
								PLtsql_stmt_fors	*new;

								if (reverse)
									ereport(ERROR,
											(errcode(ERRCODE_SYNTAX_ERROR),
											 errmsg("cannot specify REVERSE in query FOR loop"),
											 parser_errposition(tokloc)));

								Assert(strncmp(expr1->query, "SELECT ", 7) == 0);
								tmp_query = pstrdup(expr1->query + 7);
								pfree(expr1->query);
								expr1->query = tmp_query;

								check_sql_expr(expr1->query, expr1loc, 0);

								new = palloc0(sizeof(PLtsql_stmt_fors));
								new->cmd_type = PLTSQL_STMT_FORS;
								if ($1.row)
								{
									new->var = (PLtsql_variable *) $1.row;
									check_assignable($1.row, @1);
								}
								else if ($1.scalar)
								{
									/* convert single scalar to list */
									new->var = (PLtsql_variable *) make_scalar_list1($1.name, $1.scalar,
																					 $1.lineno, @1);
									/* no need for check_assignable */
								}
								else
								{
									ereport(ERROR,
											(errcode(ERRCODE_SYNTAX_ERROR),
											 errmsg("loop variable of loop over rows must be a record or row variable or list of scalar variables"),
											 parser_errposition(@1)));
								}

								new->query = expr1;
								$$ = (PLtsql_stmt *) new;
							}
						}
					}
				;

/*
 * Processing the for_variable is tricky because we don't yet know if the
 * FOR is an integer FOR loop or a loop over query results.  In the former
 * case, the variable is just a name that we must instantiate as a loop
 * local variable, regardless of any other definition it might have.
 * Therefore, we always save the actual identifier into $$.name where it
 * can be used for that case.  We also save the outer-variable definition,
 * if any, because that's what we need for the loop-over-query case.  Note
 * that we must NOT apply check_assignable() or any other semantic check
 * until we know what's what.
 *
 * However, if we see a comma-separated list of names, we know that it
 * can't be an integer FOR loop and so it's OK to check the variables
 * immediately.  In particular, for T_WORD followed by comma, we should
 * complain that the name is not known rather than say it's a syntax error.
 * Note that the non-error result of this case sets *both* $$.scalar and
 * $$.row; see the for_control production.
 */
for_variable	: T_DATUM
					{
						$$.name = NameOfDatum(&($1));
						$$.lineno = pltsql_location_to_lineno(@1);
						if ($1.datum->dtype == PLTSQL_DTYPE_ROW ||
							$1.datum->dtype == PLTSQL_DTYPE_REC)
						{
							$$.scalar = NULL;
							$$.row = $1.datum;
						}
						else
						{
							int			tok;

							$$.scalar = $1.datum;
							$$.row = NULL;
							/* check for comma-separated list */
							tok = yylex();
							pltsql_push_back_token(tok);
							if (tok == ',')
								$$.row = (PLtsql_datum *)
									read_into_scalar_list($$.name,
														  $$.scalar,
														  @1);
						}
					}
				| T_WORD
					{
						int			tok;

						$$.name = $1.ident;
						$$.lineno = pltsql_location_to_lineno(@1);
						$$.scalar = NULL;
						$$.row = NULL;
						/* check for comma-separated list */
						tok = yylex();
						pltsql_push_back_token(tok);
						if (tok == ',')
							word_is_not_variable(&($1), @1);
					}
				| T_CWORD
					{
						/* just to give a better message than "syntax error" */
						cword_is_not_variable(&($1), @1);
					}
				;

stmt_foreach_a	: opt_block_label K_FOREACH for_variable foreach_slice K_IN K_ARRAY expr_until_loop loop_body
					{
						PLtsql_stmt_foreach_a *new;

						new = palloc0(sizeof(PLtsql_stmt_foreach_a));
						new->cmd_type = PLTSQL_STMT_FOREACH_A;
						new->lineno = pltsql_location_to_lineno(@2);
						new->label = $1;
						new->slice = $4;
						new->expr = $7;
						new->body = $8.stmts;

						if ($3.row)
						{
							new->varno = $3.row->dno;
							check_assignable($3.row, @3);
						}
						else if ($3.scalar)
						{
							new->varno = $3.scalar->dno;
							check_assignable($3.scalar, @3);
						}
						else
						{
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("loop variable of FOREACH must be a known variable or list of variables"),
											 parser_errposition(@3)));
						}

						check_labels($1, $8.end_label, $8.end_label_location);
						pltsql_ns_pop();

						$$ = (PLtsql_stmt *) new;
					}
				;

foreach_slice	:
					{
						$$ = 0;
					}
				| K_SLICE ICONST
					{
						$$ = $2;
					}
				;

stmt_exit		: exit_type opt_semi
					{
						PLtsql_stmt_exit *new;

						new = palloc0(sizeof(PLtsql_stmt_exit));
						new->cmd_type = PLTSQL_STMT_EXIT;
						new->is_exit  = $1;
						new->lineno	  = pltsql_location_to_lineno(@1);
						new->label	  = NULL;
						new->cond	  = NULL;

						$$ = (PLtsql_stmt *)new;
					}
				;

exit_type		: K_BREAK
					{
						$$ = true;
					}
				| K_CONTINUE
					{
						$$ = false;
					}
				;

stmt_return		: K_RETURN
					{
						int	tok;

						tok = yylex();

						if (tok == 0)
						{
							$$ = make_return_stmt(@1);
						}
						else if (tok_is_keyword(tok, &yylval,
										   K_NEXT, "next"))
						{
							$$ = make_return_next_stmt(@1);
						}
						else if (tok_is_keyword(tok, &yylval,
												K_QUERY, "query"))
						{
							$$ = make_return_query_stmt(@1, NULL);
						}
						else if (pltsql_curr_compile->is_itvf &&
								 (word_matches(tok, "select") ||
								  word_matches(tok, "with") ||
								  (tok == '(' &&
								 	(pltsql_peek_word_matches("select") ||
								 	 pltsql_peek_word_matches("with")))))
						{
							/*
							 * TSQL inline table-valued functions have a RETURN
							 * followed by a SELECT statement or CTE, with
							 * optional parentheses around it.
							 */
							if (word_matches(tok, "with"))
							{
								/*
								 * For CTE without parentheses around it, normal
								 * parsing will stop before the main SELECT. So,
								 * we need to parse the WITH clause first, and
								 * pass it into the main SELECT.
								 */
								PLtsql_expr *with_clauses = read_sql_construct_bos(
									';', 0, 0, ";", "WITH ", false, false, true,
									NULL, NULL, true, NULL, false);
								$$ = make_return_query_stmt(@1, with_clauses);
							}
							else
							{
								pltsql_push_back_token(tok);
								$$ = make_return_query_stmt(@1, NULL);
							}
						}
						else
						{
							pltsql_push_back_token(tok);
							$$ = make_return_stmt(@1);
						}
					}
				;

stmt_raise		: K_RAISE
					{
						PLtsql_stmt_raise		*new;
						int	tok;

						new = palloc(sizeof(PLtsql_stmt_raise));

						new->cmd_type	= PLTSQL_STMT_RAISE;
						new->lineno		= pltsql_location_to_lineno(@1);
						new->elog_level = ERROR;	/* default */
						new->condname	= NULL;
						new->message	= NULL;
						new->params		= NIL;
						new->options	= NIL;

						tok = yylex();
						if (tok == 0)
							yyerror("unexpected end of function definition");

						/*
						 * We could have just RAISE, meaning to re-throw
						 * the current error.
						 */
						if (tok != ';')
						{
							/*
							 * First is an optional elog severity level.
							 */
							if (tok_is_keyword(tok, &yylval,
											   K_EXCEPTION, "exception"))
							{
								new->elog_level = ERROR;
								tok = yylex();
							}
							else if (tok_is_keyword(tok, &yylval,
													K_WARNING, "warning"))
							{
								new->elog_level = WARNING;
								tok = yylex();
							}
							else if (tok_is_keyword(tok, &yylval,
													K_NOTICE, "notice"))
							{
								new->elog_level = NOTICE;
								tok = yylex();
							}
							else if (tok_is_keyword(tok, &yylval,
													K_INFO, "info"))
							{
								new->elog_level = INFO;
								tok = yylex();
							}
							else if (tok_is_keyword(tok, &yylval,
													K_LOG, "log"))
							{
								new->elog_level = LOG;
								tok = yylex();
							}
							else if (tok_is_keyword(tok, &yylval,
													K_DEBUG, "debug"))
							{
								new->elog_level = DEBUG1;
								tok = yylex();
							}
							if (tok == 0)
								yyerror("unexpected end of function definition");

							/*
							 * Next we can have a condition name, or
							 * equivalently SQLSTATE 'xxxxx', or a string
							 * literal that is the old-style message format,
							 * or USING to start the option list immediately.
							 */
							if (tok == SCONST)
							{
								/* old style message and parameters */
								new->message = yylval.str;
								/*
								 * We expect either a semi-colon, which
								 * indicates no parameters, or a comma that
								 * begins the list of parameter expressions,
								 * or USING to begin the options list.
								 */
								tok = yylex();
								if (tok != ',' && tok != ';' && tok != K_USING)
									yyerror("syntax error");

								while (tok == ',')
								{
									PLtsql_expr *expr;

									expr = read_sql_construct(',', ';', K_USING,
															  ", or ; or USING",
															  "SELECT ",
															  true, true, true,
															  NULL, &tok);
									new->params = lappend(new->params, expr);
								}
							}
							else if (tok != K_USING)
							{
								/* must be condition name or SQLSTATE */
								if (tok_is_keyword(tok, &yylval,
												   K_SQLSTATE, "sqlstate"))
								{
									/* next token should be a string literal */
									char   *sqlstatestr;

									if (yylex() != SCONST)
										yyerror("syntax error");
									sqlstatestr = yylval.str;

									if (strlen(sqlstatestr) != 5)
										yyerror("invalid SQLSTATE code");
									if (strspn(sqlstatestr, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ") != 5)
										yyerror("invalid SQLSTATE code");
									new->condname = sqlstatestr;
								}
								else
								{
									if (tok != T_WORD)
										yyerror("syntax error");
									new->condname = yylval.word.ident;
									pltsql_recognize_err_condition(new->condname,
																	false);
								}
								tok = yylex();
								if (tok != ';' && tok != K_USING)
									yyerror("syntax error");
							}

							if (tok == K_USING)
								new->options = read_raise_options();
						}

						$$ = (PLtsql_stmt *)new;
					}
				;

stmt_print	    : K_PRINT expr_until_semi_or_bos
                    {
						PLtsql_stmt_print *new;

						new = palloc(sizeof(*new));

						new->cmd_type	= PLTSQL_STMT_PRINT;
						new->lineno		= pltsql_location_to_lineno(@1);
						new->exprs		= list_make1($2);

						$$ = (PLtsql_stmt *)new;
					}
                ;

loop_body		: proc_sect K_END K_LOOP opt_label ';'
					{
						$$.stmts = $1;
						$$.end_label = $4;
						$$.end_label_location = @4;
					}
				;

/*
 * T_WORD+T_CWORD match any initial identifier that is not a known pltsql
 * variable.  (The composite case is probably a syntax error, but we'll let
 * the core parser decide that.)  Normally, we should assume that such a
 * word is a SQL statement keyword that isn't also a pltsql keyword.
 * However, if the next token is assignment or '[', it can't be a valid
 * SQL statement, and what we're probably looking at is an intended variable
 * assignment.  Give an appropriate complaint for that, instead of letting
 * the core parser throw an unhelpful "syntax error".
 */
stmt_execsql	: K_INSERT
					{
						$$ = make_execsql_stmt(K_INSERT, @1, NULL, NULL);
					}
				| T_WORD
					{
						if (word_matches(T_WORD, "SELECT"))
							$$ = make_select_stmt(T_WORD, @1, &($1), NULL);
						else if (word_matches(T_WORD, "UPDATE"))
							$$ = make_update_stmt(T_WORD, @1, &($1), NULL);
						else if (word_matches(T_WORD, "WITH"))
						{
							PLtsql_expr *with_clauses;
							int tok;
							PLword firstword;
							with_clauses = read_sql_construct_bos(';', 0, 0, ";", "WITH ", false, false, true, NULL, NULL, true, NULL, false);
							tok = yylex();
							firstword.ident = pltsql_yylval.word.ident;
							firstword.quoted = pltsql_yylval.word.quoted;

							if (tok == K_INSERT || word_matches(tok, "DELETE"))
								$$ = make_execsql_stmt(tok, pltsql_yylloc, &firstword, with_clauses);
							else if (word_matches(tok, "SELECT"))
								$$ = make_select_stmt(T_WORD, @1, &firstword, with_clauses);
							else if (word_matches(tok, "UPDATE"))
								$$ = make_update_stmt(T_WORD, @1, &firstword, with_clauses);
							else /* no other cases supported */
								Assert(0);
						}
						else if (word_matches(T_WORD, "CREATE"))
							$$ = make_create_stmt(T_WORD, @1, &($1));
						else
						{
							int			tok;

							tok = yylex();
							pltsql_push_back_token(tok);
							if (tok == '=' || tok == COLON_EQUALS || tok == '[')
								yyerror("syntax error");

							$$ = make_execsql_stmt(T_WORD, @1, &($1), NULL);
						}
					}
				| T_CWORD
					{
						int			tok;

						tok = yylex();
						pltsql_push_back_token(tok);
						if (tok == '=' || tok == COLON_EQUALS || tok == '[')
							cword_is_not_variable(&($1), @1);
						$$ = make_execsql_stmt(T_CWORD, @1, NULL, NULL);
					}
				;

opt_global_or_local	:
					  { $$ = 0; }
					| K_GLOBAL { $$ = K_GLOBAL; }
					| K_LOCAL { $$ = K_LOCAL; }
					;

stmt_open		: K_OPEN opt_global_or_local cursor_variable opt_semi
					/* As T-SQL supports bounded cursor only, we don't need 'FOR <query>' case. */
					{
						PLtsql_stmt_open *new;

						if ($2 == K_GLOBAL)
						{
							ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("GLOBAL CURSOR is not supported yet"),
								 parser_errposition(@1)));
						}

						new = palloc0(sizeof(PLtsql_stmt_open));
						new->cmd_type = PLTSQL_STMT_OPEN;
						new->lineno = pltsql_location_to_lineno(@1);
						new->curvar = $3->dno;
						new->cursor_options = CURSOR_OPT_FAST_PLAN;

						$$ = (PLtsql_stmt *)new;
					}
				;

stmt_fetch		: K_FETCH opt_fetch_direction cursor_variable K_INTO
					{
						int tok;
						PLtsql_stmt_fetch *fetch = $2;
						PLtsql_variable *target;

						/* We have already parsed everything through the INTO keyword */
						read_into_target(&target, NULL, NULL, NULL);

						tok = yylex();
						if (tok != ';')
							pltsql_push_back_token(tok);

						/*
						 * We don't allow multiple rows in PL/TSQL's FETCH
						 * statement, only in MOVE.
						 */
						if (fetch->returns_multiple_rows)
							ereport(ERROR,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("FETCH statement cannot return multiple rows"),
									 parser_errposition(@1)));

						fetch->lineno = pltsql_location_to_lineno(@1);
						fetch->target   = target;
						fetch->curvar	= $3->dno;
						fetch->is_move	= false;

						$$ = (PLtsql_stmt *)fetch;
					}
				;

stmt_move		: K_MOVE opt_fetch_direction cursor_variable opt_semi
					{
						PLtsql_stmt_fetch *fetch = $2;

						fetch->lineno = pltsql_location_to_lineno(@1);
						fetch->curvar	= $3->dno;
						fetch->is_move	= true;

						$$ = (PLtsql_stmt *)fetch;
					}
				;

opt_fetch_direction	:
					{
						$$ = read_fetch_direction();
					}
				;

stmt_close		: K_CLOSE opt_global_or_local cursor_variable opt_semi
					{
						PLtsql_stmt_close *new;

						if ($2 == K_GLOBAL)
						{
							ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("GLOBAL CURSOR is not supported yet"),
								 parser_errposition(@1)));
						}

						new = palloc(sizeof(PLtsql_stmt_close));
						new->cmd_type = PLTSQL_STMT_CLOSE;
						new->lineno = pltsql_location_to_lineno(@1);
						new->curvar = $3->dno;

						$$ = (PLtsql_stmt *)new;
					}
				;

stmt_null		: K_NULL ';'
					{
						/* We do not bother building a node for NULL */
						$$ = NULL;
					}
				;

stmt_deallocate : K_DEALLOCATE opt_global_or_local cursor_variable opt_semi
					{
						PLtsql_stmt_deallocate *new;

						if ($2 == K_GLOBAL)
						{
							ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("GLOBAL CURSOR is not supported yet"),
								 parser_errposition(@1)));
						}

						new = palloc0(sizeof(PLtsql_stmt_deallocate));
						new->cmd_type = PLTSQL_STMT_DEALLOCATE;
						new->lineno = pltsql_location_to_lineno(@1);
						new->curvar = $3->dno;

						$$ = (PLtsql_stmt *)new;
					}
				;

cursor_variable	: T_DATUM
					{
						if ($1.datum->dtype != PLTSQL_DTYPE_VAR)
							ereport(ERROR,
									(errcode(ERRCODE_DATATYPE_MISMATCH),
									 errmsg("cursor variable must be a simple variable"),
									 parser_errposition(@1)));

						if (!is_cursor_datatype(((PLtsql_var *) $1.datum)->datatype->typoid))
							ereport(ERROR,
									(errcode(ERRCODE_DATATYPE_MISMATCH),
									 errmsg("variable \"%s\" must be of type cursor or refcursor",
											((PLtsql_var *) $1.datum)->refname),
									 parser_errposition(@1)));
						$$ = (PLtsql_var *) $1.datum;
					}
				| T_WORD
					{
						/* just to give a better message than "syntax error" */
						word_is_not_variable(&($1), @1);
					}
				| T_CWORD
					{
						/* just to give a better message than "syntax error" */
						cword_is_not_variable(&($1), @1);
					}
				;

exception_sect	:
					{ $$ = NULL; }
				| K_EXCEPTION
					{
						/*
						 * We use a mid-rule action to add these
						 * special variables to the namespace before
						 * parsing the WHEN clauses themselves.  The
						 * scope of the names extends to the end of the
						 * current block.
						 */
						int			lineno = pltsql_location_to_lineno(@1);
						PLtsql_exception_block *new = palloc(sizeof(PLtsql_exception_block));
						PLtsql_variable *var;

						var = pltsql_build_variable("sqlstate", lineno,
													 pltsql_build_datatype(TEXTOID,
																			-1,
																		   pltsql_curr_compile->fn_input_collation,
																		   NULL),
													 true);
						((PLtsql_var *) var)->isconst = true;
						new->sqlstate_varno = var->dno;

						var = pltsql_build_variable("sqlerrm", lineno,
													 pltsql_build_datatype(TEXTOID,
																			-1,
																		   pltsql_curr_compile->fn_input_collation,
																		   NULL),
													 true);
						((PLtsql_var *) var)->isconst = true;
						new->sqlerrm_varno = var->dno;

						$<exception_block>$ = new;
					}
					proc_exceptions
					{
						PLtsql_exception_block *new = $<exception_block>2;
						new->exc_list = $3;

						$$ = new;
					}
				;

proc_exceptions	: proc_exceptions proc_exception
						{
							$$ = lappend($1, $2);
						}
				| proc_exception
						{
							$$ = list_make1($1);
						}
				;

proc_exception	: K_WHEN proc_conditions K_THEN proc_sect
					{
						PLtsql_exception *new;

						new = palloc0(sizeof(PLtsql_exception));
						new->lineno = pltsql_location_to_lineno(@1);
						new->conditions = $2;
						new->action = $4;

						$$ = new;
					}
				;

proc_conditions	: proc_conditions K_OR proc_condition
						{
							PLtsql_condition	*old;

							for (old = $1; old->next != NULL; old = old->next)
								/* skip */ ;
							old->next = $3;
							$$ = $1;
						}
				| proc_condition
						{
							$$ = $1;
						}
				;

proc_condition	: any_identifier
						{
							if (strcmp($1, "sqlstate") != 0)
							{
								$$ = pltsql_parse_err_condition($1);
							}
							else
							{
								PLtsql_condition *new;
								char   *sqlstatestr;

								/* next token should be a string literal */
								if (yylex() != SCONST)
									yyerror("syntax error");
								sqlstatestr = yylval.str;

								if (strlen(sqlstatestr) != 5)
									yyerror("invalid SQLSTATE code");
								if (strspn(sqlstatestr, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ") != 5)
									yyerror("invalid SQLSTATE code");

								new = palloc(sizeof(PLtsql_condition));
								new->sqlerrstate =
									MAKE_SQLSTATE(sqlstatestr[0],
												  sqlstatestr[1],
												  sqlstatestr[2],
												  sqlstatestr[3],
												  sqlstatestr[4]);
								new->condname = sqlstatestr;
								new->next = NULL;

								$$ = new;
							}
						}
				;

tokens_until_semi_or_bos : 
					{ $$ = read_tokens_bos(';', ";"); }
					;

expr_until_semi	:
				{ $$ = read_sql_expression(';', ";"); }
				;

expr_until_semi_or_bos :
				{ $$ = read_sql_expression_bos(';', ";", false); }
				;

expr_until_bos :
				{ $$ = read_sql_expression_bos(0, "", false); }
				;

expr_until_rightbracket :
					{ $$ = read_sql_expression(']', "]"); }
				;

expr_until_loop :
					{ $$ = read_sql_expression(K_LOOP, "LOOP"); }
				;

expr_until_comma: 
                    {
						int term;

						$$ = read_sql_construct_bos(',', ';', 0, "comma or <stmt>",  
													"SELECT ",
													true, true, true, 
													NULL, &term, true, NULL, false);

						if (term == ',')
							pltsql_push_back_token(term);
					} 
				;


opt_block_label	:
					{
						pltsql_ns_push(NULL, PLTSQL_LABEL_BLOCK);
						$$ = NULL;
					}
				| LESS_LESS any_identifier GREATER_GREATER
					{
						pltsql_ns_push($2, PLTSQL_LABEL_BLOCK);
						$$ = $2;
					}
				;

opt_label	:
					{
						$$ = NULL;
					}
				| any_identifier
					{
						if (pltsql_ns_lookup_label(pltsql_ns_top(), $1) == NULL)
							yyerror("label does not exist");
						$$ = $1;
					}
				;

opt_exitcond	: ';'
					{ $$ = NULL; }
				| K_WHEN expr_until_semi
					{ $$ = $2; }
				;

/*
 * need both options because scanner will have tried to resolve as variable
 */
any_identifier	: T_WORD
					{
						$$ = $1.ident;
					}
				| T_DATUM
					{
						if ($1.ident == NULL) /* composite name not OK */
							yyerror("syntax error");
						$$ = $1.ident;
					}
				;

unreserved_keyword	:
				K_ABSOLUTE
				| K_ALIAS
				| K_ARRAY
				| K_BACKWARD
				| K_CONSTANT
				| K_CURRENT
				| K_CURSOR
				| K_DEBUG
				| K_DETAIL
				| K_DUMP
				| K_ERRCODE
				| K_ERROR
				| K_EXEC
				| K_FIRST
				| K_FORWARD
				| K_GLOBAL
				| K_HINT
				| K_INFO
				| K_IS
				| K_LAST
				| K_LOG
				| K_LOCAL
				| K_MESSAGE
				| K_MESSAGE_TEXT
				| K_NEXT
				| K_NO
				| K_NOTICE
				| K_OPTION
				| K_OUT
				| K_OUTPUT
				| K_PG_EXCEPTION_CONTEXT
				| K_PG_EXCEPTION_DETAIL
				| K_PG_EXCEPTION_HINT
				| K_PRIOR
				| K_QUERY
				| K_RELATIVE
				| K_RESULT_OID
				| K_RETURNED_SQLSTATE
				| K_REVERSE
				| K_ROW_COUNT
				| K_ROWTYPE
				| K_SCROLL
				| K_SET
				| K_SLICE
				| K_SQLSTATE
				| K_STACKED
				| K_TYPE
				| K_UNION
				| K_USE
				| K_USE_COLUMN
				| K_USE_VARIABLE
				| K_VARIABLE_CONFLICT
				| K_WARNING
				;

%%

/*
 * Check whether a token represents an "unreserved keyword".
 * We have various places where we want to recognize a keyword in preference
 * to a variable name, but not reserve that keyword in other contexts.
 * Hence, this kluge.
 */
static bool
tok_is_keyword(int token, union YYSTYPE *lval,
			   int kw_token, const char *kw_str)
{
	if (token == kw_token)
	{
		/* Normal case, was recognized by scanner (no conflicting variable) */
		return true;
	}
	else if (token == T_DATUM)
	{
		/*
		 * It's a variable, so recheck the string name.  Note we will not
		 * match composite names (hence an unreserved word followed by "."
		 * will not be recognized).
		 */
		if (!lval->wdatum.quoted && lval->wdatum.ident != NULL &&
			strcmp(lval->wdatum.ident, kw_str) == 0)
			return true;
	}
	return false;				/* not the keyword */
}

/*
 * Convenience routine to complain when we expected T_DATUM and got T_WORD,
 * ie, unrecognized variable.
 */
static void
word_is_not_variable(PLword *word, int location)
{
	ereport(ERROR,
			(errcode(ERRCODE_SYNTAX_ERROR),
			 errmsg("\"%s\" is not a known variable",
					word->ident),
			 parser_errposition(location)));
}

/* Same, for a CWORD */
static void
cword_is_not_variable(PLcword *cword, int location)
{
	ereport(ERROR,
			(errcode(ERRCODE_SYNTAX_ERROR),
			 errmsg("\"%s\" is not a known variable",
					NameListToString(cword->idents)),
			 parser_errposition(location)));
}

/*
 * Convenience routine to complain when we expected T_DATUM and got
 * something else.  "tok" must be the current token, since we also
 * look at yylval and yylloc.
 */
static void
current_token_is_not_variable(int tok)
{
	if (tok == T_WORD)
		word_is_not_variable(&(yylval.word), yylloc);
	else if (tok == T_CWORD)
		cword_is_not_variable(&(yylval.cword), yylloc);
	else
		yyerror("syntax error");
}

/* Convenience routine to read an expression with one possible terminator */
static PLtsql_expr *
read_sql_expression(int until, const char *expected)
{
	return read_sql_construct(until, 0, 0, expected,
							  "SELECT ", true, true, true, NULL, NULL);
}

/* Convenience routine to read an expression with two possible terminators */
static PLtsql_expr *
read_sql_expression2(int until, int until2, const char *expected,
					 int *endtoken)
{
	return read_sql_construct(until, until2, 0, expected,
							  "SELECT ", true, true, true, NULL, endtoken);
}

/*
 * Convenience routine to read an expression with an explicit or
 * beginning-of-statement token.
 */
static PLtsql_expr *
read_sql_expression_bos(int until, const char *expected, bool permit_empty)
{
	return read_sql_construct_bos(until, 0, 0, expected,
								  "SELECT ", true, true, true, NULL, NULL, true, NULL, permit_empty);
}

/*
 * Reads a sequence of tokens terminated with an explicit terminator
 * (a semicolon) or a beginning-of-statement token.
 */
static char *
read_tokens_bos(int until, const char *expected)
{
        PLtsql_expr *expr = read_sql_construct_bos(until, 0, 0, expected,
												   "", true, false, true, NULL, NULL, true, NULL, false);

	return expr->query;
}

/*
 * Convenience routine to read a SQL statement that must end with ';' or at
 * a beginning-of-statement token.
 */
static PLtsql_expr *
read_sql_stmt_bos(const char *sqlstart)
{
	return read_sql_construct_bos(';', 0, 0, ";",
                                  sqlstart, false, true, true, NULL, NULL, true, NULL, false);
}

/*
 * Read a SQL construct and build a PLtsql_expr for it.
 *
 * until:		token code for expected terminator
 * until2:		token code for alternate terminator (pass 0 if none)
 * until3:		token code for another alternate terminator (pass 0 if none)
 * expected:	text to use in complaining that terminator was not found
 * sqlstart:	text to prefix to the accumulated SQL text
 * isexpression: whether to say we're reading an "expression" or a "statement"
 * valid_sql:   whether to check the syntax of the expr (prefixed with sqlstart)
 * trim:		trim trailing whitespace
 * startloc:	if not NULL, location of first token is stored at *startloc
 * endtoken:	if not NULL, ending token is stored at *endtoken
 *				(this is only interesting if until2 or until3 isn't zero)
 */
static PLtsql_expr *
read_sql_construct(int until,
				   int until2,
				   int until3,
				   const char *expected,
				   const char *sqlstart,
				   bool isexpression,
				   bool valid_sql,
				   bool trim,
				   int *startloc,
				   int *endtoken)
{
	return read_sql_construct_bos(until, until2, until3, expected, sqlstart,
							  isexpression, valid_sql, trim, startloc, endtoken,
								  false, NULL, false);
}

/*
 * Read a SQL construct and build a PLtsql_expr for it, read until one of the
 * terminator tokens is encountered or optionally until the end of the line.
 *
 * until:		token code for expected terminator
 * until2:		token code for alternate terminator (pass 0 if none)
 * until3:		token code for another alternate terminator (pass 0 if none)
 * expected:	text to use in complaining that terminator was not found
 * sqlstart:	text to prefix to the accumulated SQL text
 * isexpression: whether to say we're reading an "expression" or a "statement"
 * valid_sql:   whether to check the syntax of the expr (prefixed with sqlstart)
 * trim:		trim trailing whitespace
 * startloc:	if not NULL, location of first token is stored at *startloc
 * endtoken:	if not NULL, ending token is stored at *endtoken
 *				(this is only interesting if until2 or until3 isn't zero)
 * untilbostok:	whether a beginning-of-statement token is a terminator
 */

typedef struct
{
	int     token;	/* token ID */
	YYSTYPE	lval;	/* semantic information */
	YYLTYPE lloc;	/* location (offset into scanbuf) */
} token_info;

static PLtsql_expr *
read_sql_construct_bos(int until,
					   int until2,
					   int until3,
					   const char *expected,
					   const char *sqlstart,
					   bool isexpression,
					   bool valid_sql,
					   bool trim,
					   int *startloc,
					   int *endtoken,
					   bool untilbostok,
					   List **tokens,
					   bool permit_empty)
{
	return read_sql_bos(until, until2, until3, 0, 0,
			    expected, sqlstart, isexpression,
			    valid_sql, trim, startloc, endtoken,
			    untilbostok, tokens, permit_empty);
}

/*
 * This is the same as read_sql_constuct_bos, only accepting more terminator
 * tokens. XXX would int array be a better argument?
 */
static PLtsql_expr *
read_sql_bos(int until,
					   int until2,
					   int until3,
					   int until4,
					   int until5,
					   const char *expected,
					   const char *sqlstart,
					   bool isexpression,
					   bool valid_sql,
					   bool trim,
					   int *startloc,
					   int *endtoken,
					   bool untilbostok,
					   List **tokens,
					   bool permit_empty)
{
	int					tok;
	StringInfoData		ds;
	IdentifierLookup	save_IdentifierLookup;
	int					startlocation = -1;
	int					parenlevel = 0;
	int 				caselevel = 0;
	int					sqlstartlen = strlen(sqlstart);
	PLtsql_expr			*expr;
	List				*tsql_idents = NIL;

	initStringInfo(&ds);
	appendStringInfoString(&ds, sqlstart);

	/* special lookup mode for identifiers within the SQL text */
	save_IdentifierLookup = pltsql_IdentifierLookup;
	pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_EXPR;

	YYDPRINTF((stderr, "&&& read_sql_construct_bos - %d %d %d %s\n", 
			   until, until2, until3, untilbostok ? "or BOS" : ""));

	for (;;)
	{
		tok = yylex();
		if (startlocation < 0)			/* remember loc of first token */
			startlocation = yylloc;

		YY_SYMBOL_PRINT ("&&& next token", YYTRANSLATE(tok), &yylval, &yylloc);

		if (parenlevel == 0)
		{
			if (tok == until || tok == until2 || tok == until3 || tok == until4 || tok == until5)
			{
				YYDPRINTF((stderr, "&&& matched, terminating loop\n"));
				break;
			}

			if (untilbostok)
			{
				if (is_terminator(tok, (startlocation == yylloc), startlocation, yylloc, sqlstart, tsql_idents))
				{

					YYDPRINTF((stderr, "&&& found terminator, terminating loop\n"));
					pltsql_push_back_token(tok);
					break;
				}
			}
		}

		/*
		 * If we encounter a CASE, increment caselevel so we know that we are 
		 * scanning a CASE expression.  We decrement caselevel when we encounter
		 * an END.  We need to know if we are in a CASE expression because that
		 * changes the meaning of END and ELSE tokens
		 */
		if (tok == K_CASE)
			caselevel++;

		if (tok == K_ELSE && caselevel == 0)
		{
			pltsql_push_back_token(tok);
			break;
		}

		if (tok == K_END)
		{
			if (caselevel)
				caselevel--;
			else
			{
				pltsql_push_back_token(tok);
				break;
			}
		}

		if (tok == '(' || tok == '[')
			parenlevel++;
		else if (tok == ')' || tok == ']')
		{
			parenlevel--;
			if (parenlevel < 0)
				yyerror("mismatched parentheses");
		}

		tsql_idents = append_if_tsql_identifier(tok, sqlstartlen, startlocation,
		                                     tsql_idents);

		/*
		 * End of function definition is an error, and we don't expect to
		 * hit a semicolon either (unless it's the until symbol, in which
		 * case we should have fallen out above).
		 */
		if (tok == 0 || tok == ';')
		{
			if (parenlevel != 0)
				yyerror("mismatched parentheses");
			if (isexpression)
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("missing \"%s\" at end of SQL expression",
								expected),
						 parser_errposition(yylloc)));
			else
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("missing \"%s\" at end of SQL statement",
								expected),
						 parser_errposition(yylloc)));
		}

		if (tokens)
		{
			token_info *info = palloc(sizeof(*info));
			
			info->token = tok;
			info->lval	= yylval;
			info->lloc	= yylloc;

			*tokens = lappend(*tokens, info);
		}
	}

	pltsql_IdentifierLookup = save_IdentifierLookup;

	if (startloc)
		*startloc = startlocation;
	if (endtoken)
		*endtoken = tok;

	/* give helpful complaint about empty input */
	if (permit_empty == false)
	{
		if (startlocation >= yylloc)
		{
			if (isexpression)
				yyerror("missing expression");
			else
				yyerror("missing SQL statement");
		}
	}

	/*
	 * If no tokens found in this construct and the caller
	 * has told us that an empty construct is acceptable,
	 * just return NULL.
	 */
	if ((tokens) && (list_length(*tokens) == 0))
		return NULL;
	
	pltsql_append_source_text(&ds, startlocation, yylloc);

	/* trim any trailing whitespace, for neatness */
	if (trim)
	{
		while (ds.len > 0 && scanner_isspace(ds.data[ds.len - 1]))
			ds.data[--ds.len] = '\0';
	}

	expr = palloc0(sizeof(PLtsql_expr));
#if 0
	expr->dtype			= PLTSQL_DTYPE_EXPR;
#endif
	expr->query			= pstrdup(quote_tsql_identifiers(&ds, tsql_idents));
	expr->plan			= NULL;
	expr->paramnos		= NULL;
	expr->rwparam		= -1;
	expr->ns			= pltsql_ns_top();
	if (pltsql_curr_compile->is_itvf)
		expr->itvf_query = pstrdup(generate_itvf_query(expr->query, tsql_idents));
	else
		expr->itvf_query = NULL;
	pfree(ds.data);

	if (valid_sql)
		check_sql_expr(expr->query, startlocation, strlen(sqlstart));
	return expr;
}

static List *
append_if_tsql_identifier(int tok, int start_len, int start_loc,
						List *tsql_idents)
{
	char				*ident;
	tsql_ident_ref		*tident_ref;
	int					tsql_ident_len;
	bool				is_ident_quoted;

	ident = NULL;
	
	if (tok == T_WORD)
	{
		ident = yylval.word.ident;
		is_ident_quoted = yylval.word.quoted;
	}
	else if (tok == T_DATUM)
	{
		ident = NameOfDatum(&(yylval.wdatum));
		is_ident_quoted = yylval.wdatum.quoted;
	}

	/*
	 * Create and append a reference to this word if it is a TSQL (at-prefixed)
	 * identifier.
	 */
	if (ident && !is_ident_quoted)
	{
		tsql_ident_len = strlen(ident);

		if ((tsql_ident_len > 0 && (ident[0] == '@' || ident[0] == '#'))
           || ( tsql_ident_len > 2 && strcasecmp(ident, "@@error") ==0 ))
		{
			tident_ref = palloc(sizeof(tsql_ident_ref));
			tident_ref->location = (start_len - 1) +
				(yylloc - start_loc);
			tident_ref->ident = pstrdup(ident);
			/* Record dno so that we can look up the type name */
			tident_ref->dno = tok == T_DATUM ? yylval.wdatum.datum->dno : -1;
			/* Record original token length. ident might be already touched by scanner (i.e. truncation) */
			tident_ref->length = pltsql_get_yyleng();
			
			tsql_idents = lappend(tsql_idents, tident_ref);
		}
	}

	return tsql_idents;
}

static char *
quote_tsql_identifiers(const StringInfo src, const List *tsql_idents)
{
	StringInfoData	dest;
	ListCell		*lc;
	int				prev = 0;
	int				quoted = 0;

	if (list_length(tsql_idents) == 0)
		return src->data;

	initStringInfo(&dest);

	foreach(lc, tsql_idents)
	{
		tsql_ident_ref *tword = (tsql_ident_ref *) lfirst(lc);

		/*
		 * Append the part of the source text appearing before the identifier
		 * that we haven't inserted already.
		 */
		appendBinaryStringInfo(&dest, &(src->data[prev]),
							   tword->location - prev + 1);
		appendStringInfo(&dest, "\"%s\"", tword->ident);
		prev = tword->location + 1 + tword->length;

		/* Keep location up to date for all idents, for itvf_query */
		tword->location += quoted * 2;
		quoted += 1;
	}

	appendStringInfoString(&dest, &(src->data[prev]));
	return dest.data;
}

/*
 * For inline table-valued function, we need to save an version of the query
 * statement that we can call SPI_prepare to generate a plan, in order to figure
 * out the column definition list. So, we replace all variable references by
 * "CAST(NULL AS <type>)" in order to get the correct columnn list from
 * planning.
 */
static char *
generate_itvf_query(char *src, const List *tsql_idents)
{
	StringInfoData	dest;
	ListCell		*lc;
	int				prev = 0;
	PLtsql_var 		*var;

	if (list_length(tsql_idents) == 0)
		return src;

	initStringInfo(&dest);

	foreach(lc, tsql_idents)
	{
		tsql_ident_ref *tword = (tsql_ident_ref *) lfirst(lc);
		if (tword->dno == -1)
			continue;
		var = (PLtsql_var *) pltsql_Datums[tword->dno];

		appendBinaryStringInfo(&dest, &(src[prev]),
							   tword->location - prev + 1);
		appendStringInfo(&dest, "CAST(NULL AS %s)", var->datatype->typname);
		prev = tword->location + 1 + strlen(tword->ident) + 2;
	}

	appendStringInfoString(&dest, &(src[prev]));
	return dest.data;
}

/*
 * Determines whether there the specified token is a statement terminator.
 *
 * "tok" must be the current token, since we also look at yylval.
 */
static bool
is_terminator(int tok, bool first, int start_loc, int cur_loc,
			  const char *sql_start, const List *tsql_idents)
{
	switch (tok)
	{
		/* Ambiguous tokens not included: NULL */
    	case 0:            /* End of input */
	    case ';':
		case K_BEGIN:
		case K_CLOSE:
		case K_DECLARE:
		case K_EXIT:
		case K_FETCH:
			return true;
		case K_FOREACH:
		case K_GET:
		case K_IF:
		case K_INSERT:
		case K_MOVE:
		case K_OPEN:
		case K_PERFORM:
		case K_PRINT:
		case K_RAISE:
		case K_RETURN:
		case K_WHILE:
		case LESS_LESS:			/* Optional label for many statements */
		case K_GOTO:
		case K_RAISERROR:
		case K_THROW:
#if 0
		case K_ALTER:
		case K_CREATE:
		case K_DROP:
		case K_EXEC:
#endif
		case K_BREAK:
		case K_EXECUTE:
		case K_EXEC:
		case K_CONTINUE:
		case K_DEALLOCATE:
		/*
		 * These are not core TSQL statements but are needed to support dual
		 * syntax, in particular, the PL/pgSQL syntax for their respective
		 * statements.
		 */
		case K_LOOP:
			return true;
		/*
		 * We work harder in the ambiguous cases and perform a basic syntax
		 * analysis to guide us.
		 */
		case K_SET:				/* Ambiguous: may be an assignment or part of an UPDATE */
			return true;

		case K_END_CATCH:
		case K_END_TRY:
			return true;
        case TSQL_LABEL:
            return true;

		default:
			break;
	}

	if (word_matches(tok, "DROP")) {
		int			tok1 = pltsql_peek();

		/*
		 * If "DROP CONSTRAINT / DROP COLUMN", this can happen in the middle of ALTER TABLE statement.
		 * Otherwise, mark the DROP as the beginning of a new statement.
		 */
		if (tok1 == K_CONSTRAINT || tok1 == K_COLUMN)
			return false;
		else if (pltsql_peek_word_matches("MEMBER")) /* ALTER SERVER ROLE .. DROP MEMBER .. */
			return false;
		else if (pltsql_peek_word_matches("CREDENTIAL")) /* ALTER LOGIN .. DROP CREDENTIAL .. */
			return false;
		else
			return true;
	}

	if (word_matches(tok, "UPDATE")) {
		int tok1 = pltsql_peek();
		if (tok1 == '(')
			return false;
		else
			return true;
	}


	/* List of words that are not tokens but mark the beginning of a statement. */
	return word_matches(tok, "DELETE") ||
		   word_matches(tok, "CREATE") ||
		   word_matches(tok, "TRUNCATE") ||
		   (!first && word_matches(tok, "WITH")) || 
		   (!first && word_matches(tok, "SELECT")) ||
		   word_matches(tok, "BEGIN") || /* BEGIN is returned as T_WORD instead of K_BEGIN for "BEGIN TRANSACTION" in scanner. need special handling */
		   word_matches(tok, "COMMIT") || /* COMMIT is not a keyword in pgtsql (other than pl/pgsql) */
		   word_matches(tok, "ROLLBACK"); /* ROLLBACK is not a keyword in pgtsql (other than pl/pgsql) */
}


/*
 * Determines whether the specified token is a statement terminator or procedure
 * ending.
 */
static bool
is_terminator_proc(int tok, bool first)
{
	if (tok == ';')
	{
		return true;
	}
	else if (is_terminator(tok, first, 0, yylloc, NULL, NULL) || tok == K_END)
	{
		pltsql_push_back_token(tok);
		return true;
	}
	return false;
}

static bool
string_matches(const char *str, const char *pattern)
{
	if (pg_strcasecmp(str, pattern) == 0)
		return true;
	else
		return false;
}

static bool
word_matches(int tok, const char *pattern)
{
	return ((tok == T_WORD) && string_matches(yylval.word.ident, pattern));
}

static PLtsql_type *
read_datatype(int tok)
{
	static int callCount = 0;
	StringInfoData		ds;
	char			   *type_name;
	int					startlocation;
	PLtsql_type		*result;
	int					parenlevel = 0;

	YYDPRINTF((stderr, "::: read_datatype (call %d)\n", callCount++));

	/* Should only be called while parsing DECLARE sections */
	//Assert(pltsql_IdentifierLookup == IDENTIFIER_LOOKUP_DECLARE);

	/* Often there will be a lookahead token, but if not, get one */
	if (tok == YYEMPTY)
		tok = yylex();

	YY_SYMBOL_PRINT("::: first token in data type", YYTRANSLATE(tok), &yylval, &yylloc);

	startlocation = yylloc;

	/*
	 * If we have a simple or composite identifier, check for %TYPE
	 * and %ROWTYPE constructs.
	 */
	if (tok == T_WORD)
	{
		char   *dtname = yylval.word.ident;

		tok = yylex();

		YY_SYMBOL_PRINT("::: next token", YYTRANSLATE(tok), &yylval, &yylloc);

		if (tok == '%')
		{
			tok = yylex();
			if (tok_is_keyword(tok, &yylval,
							   K_TYPE, "type"))
			{
				result = pltsql_parse_wordtype(dtname);
				if (result)
					return result;
			}
			else if (tok_is_keyword(tok, &yylval,
									K_ROWTYPE, "rowtype"))
			{
				result = pltsql_parse_wordrowtype(dtname);
				if (result)
					return result;
			}
		}
	}
	else if (tok == T_CWORD)
	{
		List   *dtnames = yylval.cword.idents;

		tok = yylex();

		YY_SYMBOL_PRINT("::: next token", YYTRANSLATE(tok), &yylval, &yylloc);

		if (tok == '%')
		{
			tok = yylex();
			if (tok_is_keyword(tok, &yylval,
							   K_TYPE, "type"))
			{
				result = pltsql_parse_cwordtype(dtnames);
				if (result)
					return result;
			}
			else if (tok_is_keyword(tok, &yylval,
									K_ROWTYPE, "rowtype"))
			{
				result = pltsql_parse_cwordrowtype(dtnames);
				if (result)
					return result;
			}
		}
	}

	while (tok != ';')
	{
		/* Should not encounter a @local_variable in a data type */
		if (tok == T_WORD && yylval.word.ident[0] == '@')
		{
			YYDPRINTF((stderr, "::: found '%s', terminating loop\n", yylval.word.ident));
			break;
		}

		/* Possible followers for datatype in a declaration */
		if ((tok == K_COLLATE || tok == K_NOT ||
		     tok == '=' || tok == COLON_EQUALS || tok == K_DEFAULT) &&
		    parenlevel == 0)
		{
			YYDPRINTF((stderr, "::: found follower, terminating loop\n"));
			break;
		}

		/* Possible followers for datatype in a cursor_arg list */
		if ((tok == ',' || tok == ')') && parenlevel == 0)
		{
			YYDPRINTF((stderr, "::: found '%c', terminating loop\n", tok));
			break;
		}

		if (tok == '(')
			parenlevel++;
		else if (tok == ')')
			parenlevel--;

		/*
		 * When DECLARE statement is packed in BEGIN...END, we need to
		 * take K_END like a terminator. For example:
		 * CREATE PROC p1 AS
		 * BEGIN
		 *	DECLARE @a INT
		 * END
		 */
		if (is_terminator(tok, (startlocation == yylloc), startlocation, yylloc, NULL, NIL) ||
			tok == K_END)
		{
			if (parenlevel == 0)
			{
				YYDPRINTF((stderr, "::: found terminator, terminating loop\n"));
				break;
			}
			else
				yyerror("mismatched parentheses");
		}

		tok = yylex();

		YY_SYMBOL_PRINT("::: next token", YYTRANSLATE(tok), &yylval, &yylloc);
	}

	/* set up ds to contain complete typename text */
	initStringInfo(&ds);
	pltsql_append_source_text(&ds, startlocation, yylloc);

	/* trim any trailing whitespace, for neatness */
	while (ds.len > 0 && scanner_isspace(ds.data[ds.len - 1]))
		ds.data[--ds.len] = '\0';

	type_name = ds.data;

	if (type_name[0] == '\0')
		yyerror("missing data type declaration");

	result = parse_datatype(type_name, startlocation);

	pfree(ds.data);

	pltsql_push_back_token(tok);

	return result;
}

/*
 * init_execsql_ctx()
 *
 *  This function initializes the given execsql_ctx object
 */
static void
init_execsql_ctx(execsql_ctx *ctx, int firsttoken, int location, PLword *firstword)
{
	initStringInfo(&ctx->ds);

	ctx->location			= location;
	ctx->target				= NULL;
	ctx->have_values        = false;
	ctx->have_into			= false;
	ctx->have_strict		= false;
	ctx->have_temptbl		= false;
	ctx->have_insert_select = false;
	ctx->have_insert_exec = false;
	ctx->is_prev_tok_create = false;
	ctx->is_update_with_variables = false;
	ctx->into_start_loc		= -1;
	ctx->into_end_loc		= -1;
	ctx->temptbl_loc		= -1;
	ctx->select_into_table_name	= NULL;
	ctx->tsql_idents		= NIL;
	ctx->startlocation		= location; /* do not use yylloc here because it doesn't work if token was pushed back */
	ctx->parenlevel			= 0;
	ctx->caselevel          = 0;
	ctx->have_output		= false;

	/* special lookup mode for identifiers within the SQL text */
	ctx->save_IdentifierLookup = pltsql_IdentifierLookup;
	pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_EXPR;

	/*
	 * We have to special-case the sequence INSERT INTO, because we don't want
	 * that to be taken as an INTO-variables clause.  Fortunately, this is the
	 * only valid use of INTO in a pl/pgsql SQL command, and INTO is already a
	 * fully reserved word in the main grammar.  We have to treat it that way
	 * anywhere in the string, not only at the start; consider CREATE RULE
	 * containing an INSERT statement.
	 */
	ctx->tok = firsttoken;
	ctx->prev_tok = YYEMPTY;

	if (firstword && string_matches(firstword->ident, "CREATE"))
		ctx->is_prev_tok_create = true;
	else
		ctx->is_prev_tok_create = false;
}

/*
 * manage_paren_level()
 *
 *  If the current token is an open- or close-paren or an 
 *  open- or close-square bracket, this function adjusts
 *  the nesting level (ctx->parenlevel).
 */
static void
manage_paren_level(execsql_ctx *ctx)
{
	/*
	 * if we find an open paren (or square brakcket) we increase
	 * our nesting level.
	 *
	 * if we find a close paren (or square bracket) we decrease
	 * the nesting level
	 *
	 * if the nesting level goes negative, we have a mismatch 
	 * and report an error
	 */
	if (ctx->tok == '(' || ctx->tok == '[')
		ctx->parenlevel++;
	else if (ctx->tok == ')' || ctx->tok == ']')
	{
		ctx->parenlevel--;

		if (ctx->parenlevel < 0)
			yyerror("mismatched parentheses");
	}
}

static PLtsql_stmt *
make_execsql_stmt(int firsttoken, int location, PLword *firstword, PLtsql_expr *with_clauses )
{
	static int callCount = 0;
	execsql_ctx ctx;
	PLtsql_stmt_execsql *execsql;
	StringInfoData query;

	YYDPRINTF((stderr, "!!! make_execsql_stmt(%d)\n", callCount++));

	init_execsql_ctx(&ctx, firsttoken, location, firstword);

	for (;;)
	{
		if (ctx.prev_tok != YYEMPTY && ctx.tok == 0) /* EOF */
		{
			if (ctx.parenlevel > 0)
				yyerror("missing closing parentheses");
			else
				yyerror("unexpected end of input");
		}

		ctx.prev_tok = ctx.tok;
		ctx.tok = yylex();

		YY_SYMBOL_PRINT ("!!! next token", YYTRANSLATE(ctx.tok), &yylval, &yylloc);

		manage_paren_level(&ctx);

		if (ctx.have_into && ctx.into_end_loc < 0)
			ctx.into_end_loc = yylloc;		/* token after the INTO part */

		if (ctx.tok == ';')
		{
			YYDPRINTF((stderr, "!!! found a semicolon, terminating loop\n"));
			break;
		}

		if (ctx.tok == K_CASE)
			ctx.caselevel++;

		if (word_matches(ctx.tok, "values"))
			ctx.have_values = true;
		
		if (ctx.tok == K_END)
		{
			if (ctx.caselevel)
				ctx.caselevel--;
			else
			{
				pltsql_push_back_token(ctx.tok);
				break;
			}
		}

		if (ctx.tok == K_OUTPUT)
			ctx.have_output = true;

		/*
		 * We have some special handling for "UNION", which is followed by
		 * "SELECT" which should be treated as part of the current statement,
		 * instead of the start of the next one. To utilize it, we treat "UNION
		 * ALL" just like "UNION" by skipping the "ALL" here.
		 */
		if (ctx.tok == K_ALL && ctx.prev_tok == K_UNION)
		{
			ctx.tok = K_UNION;
			continue;
		}

		/*
		 * Determine whether the new token introduces a new statement, but 
		 * only only if this token is not found within an unclosed set of 
		 * parentheses.
		 *
		 * Consider, for example: 
		 *
		 *    SELECT * FROM customer WHERE id = (SELECT 2) LIMIT 1;
		 *
		 * The second SELECT does NOT introduce a new statement.
		 */ 
		if (ctx.parenlevel == 0)
		{

			if (firsttoken == K_INSERT && word_matches(ctx.tok, "SELECT"))
			{
				/*
				 * We have seen INSERT...SELECT.  This could be either of
				 * the following:
				 * 
				 *  INSERT INTO foo VALUES(42) SELECT * from foo
				 *  INSERT INTO foo SELECT * from bar
				 *
				 * In the first case, the SELECT token introduces a
				 * new statement (SELECT * FROM foo is NOT part of
				 * the INSERT statement).
				 *
				 * In the second coae, the SELECT token introduces
				 * a new clause (SELECT...INSERT) but not a new 
				 * statement.
				 *
				 * We can distinguish between the two forms by paying
				 * attention to whether we have seen a VALUES clause.
				 */
				
				if (ctx.have_values)
				{
					/* 
					 * We've already seen a VALUES clause so this SELECT
					 * must be introducing a new statement.
					 */
					pltsql_push_back_token(ctx.tok);					
					break;
				}
				else if (ctx.have_insert_select || ctx.have_insert_exec)
				{
					/*
					 * is_terminator() returns TRUE for "SELECT" that does not appear
					 * first. This doesn't work for statements like:
					 *   INSERT ... SELECT ... UNION (ALL) SELECT ...
					 * So, we add an additional check to catch cases like this.
					 */
					if (ctx.prev_tok == K_UNION)
						continue;
					/*
					 * Variation of the first case like 'INSERT INTO foo SELECT * from foo SELECT * from foo
					 * the first SELECT * from foo is the part of INSERT
					 * but the second SELECT * from foo should make anoter statement
					 */
					pltsql_push_back_token(ctx.tok);
					break;
				}
				else
				{
					/*
					 * We have not seen a VALUES clause in this statement
					 * so this SELECT is forming an INSERT...SELECT clause.
					 */
					ctx.have_insert_select = true;
					continue;
				}
			}
			/* Do a similar thing with ctx.have_insert_exec here */
			else if (firsttoken == K_INSERT &&
					 (ctx.tok == K_EXEC || ctx.tok == K_EXECUTE))
			{
				/*
				 * We have seen INSERT...EXEC.  This could be either of
				 * the following:
				 * 
				 *  INSERT INTO foo VALUES(42) EXEC sp_foo
				 *  INSERT INTO foo EXEC sp_bar
				 *
				 * In the first case, the EXEC token introduces a
				 * new statement (EXEC sp_foo is NOT part of
				 * the INSERT statement).
				 *
				 * In the second coae, the EXEC token introduces
				 * a new clause (INSERT...EXEC) but not a new
				 * statement.
				 *
				 * We can distinguish between the two forms by paying
				 * attention to whether we have seen a VALUES clause.
				 */
				
				if (ctx.have_values)
				{
					/* 
					 * We've already seen a VALUES clause so this SELECT
					 * must be introducing a new statement.
					 */
					pltsql_push_back_token(ctx.tok);					
					break;
				}
				else if (ctx.have_insert_select || ctx.have_insert_exec)
				{
					/*
					 * Variation of the first case like 'INSERT INTO foo EXEC sp_foo EXEC sp_foo'
					 * the first EXEC sp_foo is the part of INSERT
					 * but the second EXEC sp_foo should make anoter statement
					 */
					pltsql_push_back_token(ctx.tok);
					break;
				}
				else
				{
					/*
					 * We have not seen a VALUES clause in this statement
					 * so this SELECT is forming an INSERT...EXEC clause.
					 */
					ctx.have_insert_exec = true;
					continue;
				}
			}

			/*
			 * is_terminator() returns TRUE for "WITH", which will cause the
			 * next parse to do make_select_cte(). This is not always desirable
			 * because we might have statements like:
			 *   INSERT ... SELECT count(*) from pg_type with (tablockx);
			 * So, we add an additional check to catch cases like this.
			 */
			if (word_matches(ctx.tok, "WITH"))
			{
				ctx.tok = yylex();
				if (ctx.tok == '(')
				{
					pltsql_push_back_token(ctx.tok);
					continue;
				}
				pltsql_push_back_token(ctx.tok);
			}

			if (is_terminator(ctx.tok, (ctx.startlocation == yylloc),
							  ctx.startlocation, yylloc, NULL, ctx.tsql_idents))
			{
				YY_SYMBOL_PRINT ("!!! found a terminator, pushing back", YYTRANSLATE(ctx.tok), &yylval, &yylloc);
				pltsql_push_back_token(ctx.tok);
				break;
			}
		}
		else
		{
			if (firsttoken == K_INSERT && word_matches(ctx.tok, "SELECT"))
			{
				/*
				 * regardless of parenthesis level, we have to mark have_insert_select
				 * to handle a query such as `INSERT INTO ... (SELECT ...) SELECT`.
				 * the second SELECT should be a terminator.
				 */
				 ctx.have_insert_select = true;
			}
			if (firsttoken == K_INSERT && (ctx.tok == K_EXEC || ctx.tok == K_EXECUTE))
			{
				/*
				 * regardless of parenthesis level, we have to mark have_insert_select
				 * to handle a query such as `INSERT INTO ... (EXEC ...) EXEC`.
				 * the second EXEC should be a terminator.
				 */
				 ctx.have_insert_exec = true;
			}
		}

		ctx.tsql_idents = append_if_tsql_identifier(ctx.tok,
		                                        (ctx.have_temptbl ?
		                                         strlen(TEMPOBJ_QUALIFIER) : 0),
		                                        ctx.location, ctx.tsql_idents);

		/* 
		* We check for OUTPUT keyword and do not error out if present. 
		* This code may be broken by columns/inputs with the word OUTPUT, but that
		* is okay because this is a temporary fix until the ANTLR parser starts 
		* being used.
		*/
		if (ctx.tok == K_INTO && ctx.prev_tok != K_INSERT && !ctx.have_output)
		{
			if (ctx.have_into)
				yyerror("INTO specified more than once");

			ctx.have_into = true;
			ctx.into_start_loc = yylloc;

			pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_NORMAL;
			read_into_target(&ctx.target, &ctx.have_strict, &ctx.select_into_table_name, &ctx.have_temptbl);
			pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_EXPR;
		}

		/*
		 * We need to identify CREATE TABLE <#ident> as a local temporary table
		 * so we can translate it to a CREATE TEMPORARY TABLE statement later.
		 */
		if (ctx.is_prev_tok_create && ctx.tok == K_TABLE)
		{
			ctx.temptbl_loc = yylloc;

			ctx.tok = yylex();
			if (ctx.tok == T_WORD && (!yylval.word.quoted) && (yylval.word.ident[0] == '#'))
				ctx.have_temptbl = true;

			pltsql_push_back_token(ctx.tok);
		}
		/* See the call to check_sql_expr below if you change this */
		ctx.is_prev_tok_create = false;
	}

	pltsql_IdentifierLookup = ctx.save_IdentifierLookup;

	if (ctx.have_into)
	{
		/*
		 * Insert an appropriate number of spaces corresponding to the
		 * INTO text, so that locations within the redacted SQL statement
		 * still line up with those in the original source text.
		 */
		pltsql_append_source_text(&ctx.ds, ctx.location, ctx.into_start_loc);
		appendStringInfoSpaces(&ctx.ds, ctx.into_end_loc - ctx.into_start_loc);
		pltsql_append_source_text(&ctx.ds, ctx.into_end_loc, yylloc);
	}
	else
	{
		if (ctx.have_temptbl)
		{
			/*
			 * We have a local temporary table identifier after the CREATE
			 * TABLE tokens, we need to transform CREATE TABLE -> CREATE
			 * TEMPORARY TABLE in this case.
			 */
			Assert(!with_clauses);  /* create table statement cannot have with clase */
			pltsql_append_source_text(&ctx.ds, ctx.location, ctx.temptbl_loc);
			appendStringInfoString(&ctx.ds, TEMPOBJ_QUALIFIER);
			pltsql_append_source_text(&ctx.ds, ctx.temptbl_loc, yylloc);
		}
		else
		{
			pltsql_append_source_text(&ctx.ds, ctx.location, yylloc);
		}
	}

	/* trim any trailing whitespace, for neatness */
	while (ctx.ds.len > 0 && scanner_isspace(ctx.ds.data[ctx.ds.len - 1]))
		ctx.ds.data[--ctx.ds.len] = '\0';

	initStringInfo(&query);
	if (with_clauses)
		appendStringInfo(&query, "%s %s", with_clauses->query, quote_tsql_identifiers(&ctx.ds, ctx.tsql_idents));
	else
		appendStringInfoString(&query, quote_tsql_identifiers(&ctx.ds, ctx.tsql_idents));


	ctx.expr = palloc0(sizeof(PLtsql_expr));
#if 0
	ctx.expr->dtype	= PLTSQL_DTYPE_EXPR;
#endif
	ctx.expr->query = pstrdup(query.data);
	ctx.expr->plan	   = NULL;
	ctx.expr->paramnos = NULL;
	ctx.expr->rwparam  = -1;
	ctx.expr->ns	   = pltsql_ns_top();
	pfree(ctx.ds.data);

	/*
	 * If have_temptbl is true, the first two tokens were valid so we expect
	 * that check_sql_expr will raise errors from a location occurring after
	 * the TEMPORARY token.  Because the original statement did not include it,
	 * we offset the error location with its length so it points back to the
	 * correct location in the original source.
	 */
	check_sql_expr(ctx.expr->query, ctx.location, (ctx.have_temptbl ?
	                                       strlen(TEMPOBJ_QUALIFIER) : 0));

	execsql			  = palloc(sizeof(PLtsql_stmt_execsql));
	execsql->cmd_type = PLTSQL_STMT_EXECSQL;
	execsql->lineno   = pltsql_location_to_lineno(location);
	execsql->sqlstmt  = ctx.expr;
	execsql->into	  = ctx.have_into;
	execsql->strict   = ctx.have_strict;
	execsql->target   = ctx.target;
	execsql->mod_stmt_tablevar = false;
	execsql->need_to_push_result = false;
	execsql->is_tsql_select_assign_stmt = false;

	return (PLtsql_stmt *) execsql;
}

typedef struct
{
	int			 dno;
	int			 operator;
	PLtsql_expr *src;
} query_target;

/*
 * read_query_targets2()
 *
 *  Reads the next SELECT target - this function assumes that
 *  a caller has set pltsql_IdentifierLookup properly and that
 *  a caller will restore the original pltsql_IdentifierLookup
 *  after we return
 *  In normal cases like @a = b, we return a list containing one
 *  query_target.
 *  in some other cases like @a = b = 3, we need to return two
 *  targets as a list: @a = 3, b = 3
 */
static List *
read_query_targets2()
{
	List * result = NIL;
	query_target *target;
	PLtsql_expr *src;
	int tok = yylex();
	int term;
	List *tokens = NIL;

	pltsql_push_back_token(tok);
	
    /* Seeing K_FROM indicates start of from clause in curren stmt
     * Seeing K_INTO indicates we are in a SELECT ... INTO stmt, 
     *        so we should stop reading target here.
	 * Seeing K_WHERE indicates we are in a UPDATE ... WHERE stmt, 
     *        so we should stop reading target here.
     * Seeing Terminators indicates end of current stmt,
     *        current stmt has no from clause. e.g. select expr, expr 
     * Seeing K_END indicates end of BEGIN-END block
     *        current stmt has no from clause
     *        current stmt not ended with a delimiter ';'
     *        e.g 
     *        BEGIN select expr, expr END
     *        Note: K_END is not a terminator due to case expression
     *              But read_query_targets would read entire case expression
     *              So current K_END could not be part of it
     */
	if ((tok == K_FROM) || (tok == K_INTO) || (tok == K_WHERE) || (is_terminator(tok, false, 0, yylloc, NULL, NULL))
        || (tok == K_END))
		return NULL;

	/*
	 * SELECT @pages = relpages * 2, @natts = relnatts FROM pg_class WHERE relname = 'pg_proc';
	 * SELECT @foo, relnatts FROM pg_class WHERE relname = 'pg_proc';
	 * SELECT 42, 
	 */
	src = read_sql_bos(',', K_FROM, K_INTO, K_WHERE, 0, "comma or FROM or INTO or WHERE",
								 "",
								 true, false, true, NULL, &term, true, &tokens, true);

	if (list_length(tokens) == 0)
		return NULL;

	target = palloc(sizeof(*target));
	target->dno		 = -1;
	target->operator = -1;
	target->src		 = src;

	/*
	 * We have read all of the tokens in this target list entry,
	 * so result->src->query will look like one of the following:
	 *
	 *	  @pages = relpages * 2
	 * or
	 *	  @pages
	 * or
	 *    relpages * 2 
	 *
	 * Now figure out if this entry represents an assignment, or
	 * is just a plain target entry. We consider it an assignment
	 * if all of the following are true:
	 *	1) There are at least three tokens in the expression
	 *  2) The first token is a T_DATUM (PL/tsql local variable)
	 *  3) The second token is an assignment operator ('=')
	 */

	if (list_length(tokens) >= 3)
	{
		token_info *first  = list_nth(tokens, 0);
		token_info *second = list_nth(tokens, 1);

		if (first->token == T_DATUM && second->token == '=')
		{
			ListCell *third_cell = list_nth_cell(tokens, 2);
			ListCell *it;
			StringInfoData revised_query;
			int caselevel = 0;
			int parenlevel = 0;
			/*
			 * This is an assignment target (@var = expr), so
			 * change the result->dno (it was initialized to
			 * -1) and increment the query pointer past the
			 * assignment operator
			 */
			target->dno = first->lval.wdatum.datum->dno;
            /* 
             * alraedy checked there is three tokens and '=' is the 2nd token
             * set query as next token after '='
             */
            target->src->query = strchr(target->src->query, '=') + 1;

			/*
			 * Check if we have a second '=' in the query.
			 * e.g. @v = column = expression. if that happens,
			 * the target will be split into two targets:
			 * target1 -> @v = expression
			 * target2 -> column = expression
			 */
			for_each_cell(it, tokens, third_cell)
			{
				token_info *tok = (token_info*) lfirst(it);

				switch (tok->token)
				{
					case K_CASE:
						caselevel++;
						break;
					case K_END:
						caselevel--;
						break;
					case '(':
					case '[':
						parenlevel++;
						break;
					case ')':
					case ']':
						if (--parenlevel < 0)
							yyerror("mismatched parentheses");
						break;
					default:
						break;
				}

				if (tok->token == '=' && caselevel == 0 && parenlevel == 0)
				{
					query_target *target2 = palloc(sizeof(*target2));
					PLtsql_expr *target2_expr = palloc0(sizeof(*target2_expr));
					target2->dno		= -1;
					target2->operator	= -1;
					target2_expr->plan = NULL;
					target2_expr->paramnos = NULL;
					target2_expr->rwparam = -1;
					target2_expr->ns = pltsql_ns_top();
					target2_expr->query = pstrdup(target->src->query);
					target2->src = target2_expr;
					result = lappend(result, target2);

					/* need to update target1's expression */
					initStringInfo(&revised_query);
					pltsql_append_source_text(&revised_query, tok->lloc+1, yylloc);
					target->src->query = revised_query.data;

					break;
				}
			}
		}
	}

	if (term == K_FROM || term == K_INTO || term == K_WHERE)
		pltsql_push_back_token(term);

	result = lappend(result, target);
	return result;
}

/*
 * read_query_targets()
 *
 *	This function reads a SELECT target in 
 *  IDENTIFIER_LOOKUP_NORMAL mode, making 
 *  sure to preserve the current identifier
 *  lookup mode.
 */
static List * 
read_query_targets()
{
	IdentifierLookup save = pltsql_IdentifierLookup;
	List *result;

	pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_NORMAL;
	result = read_query_targets2();
	pltsql_IdentifierLookup = save;

	return result;
}

static PLtsql_expr *
make_target_expr(List *fields, int location)
{
	PLtsql_expr *result = palloc0(sizeof(*result));
	const char *separator = "";
	StringInfoData src;
	ListCell *it;

	result->plan = NULL;
	result->paramnos = NULL;
	result->rwparam = -1;
	result->ns = pltsql_ns_top();

	initStringInfo(&src);

	foreach (it, fields)
	{
		query_target *target = (query_target *) lfirst(it);
		appendStringInfoString(&src, separator);
		appendStringInfoString(&src, target->src->query);

		separator = ", ";
	}

	result->query = src.data;

	return result;
}

static PLtsql_row *
make_target_row(List *fields, int location)
{
	PLtsql_row *result = palloc0(sizeof(*result));
	ListCell *it;
	int i;

	result->dtype	   = PLTSQL_DTYPE_ROW;
	result->refname	   = "(select target)";
	result->lineno	   = pltsql_location_to_lineno(location);
	result->rowtupdesc = NULL;
	result->nfields	   = list_length(fields);
	result->fieldnames = palloc(sizeof(char *) * result->nfields);
	result->varnos	   = palloc(sizeof(int) * result->nfields);

	i = 0;

	foreach (it, fields)
	{
		query_target *field = lfirst(it);
        result->varnos[i] = field->dno;

		/* pass variables into row fields */
        if (field->dno >= 0 && field->dno < pltsql_nDatums )
        {
		    PLtsql_var *var = (PLtsql_var *) pltsql_Datums[field->dno];
            result->fieldnames[i] = var->refname;
        }
        else
            result->fieldnames[i] = NULL;

		i++;
	}

	pltsql_adddatum((PLtsql_datum *) result);

	return result;
}

/*
 * read_top_clause()
 *
 *  This function will scan through the tokens that make up a TOP
 *  clause (within a SELECT).  We expect to find the following 
 *  forms:
 *		TOP integer
 *      TOP integer PERCENT
 *      TOP float PERCENT
 *      TOP (expression)
 *      TOP (expression) PERCENT
 *
 *  Note that we don't check for syntax errors here; we leave that
 *  to the SQL parser.
 *
 *  This function returns a null-terminated string containing the
 *  entire TOP clause.  
 */
static char *
read_top_clause(execsql_ctx *ctx)
{
	int length = 4; /* length of "TOP " */
	int start = yylloc;

	/*
	 * We just read TOP; this could be followed by a parenthesized 
	 * expression or a numeric literal (either float or int)
	 */

	while ((ctx->tok = yylex()) != 0)
	{
		YYDPRINTF((stderr, "read_top_clause - tok (%d) loc(%d) len(%d)\n", 
				  ctx->tok, pltsql_yylloc, pltsql_get_yyleng()));

		if (ctx->tok == ICONST)
			length += pltsql_get_yyleng();
		else if (ctx->tok == FCONST)
			length += pltsql_get_yyleng();
		else if (word_matches(ctx->tok, "PERCENT"))
			length += pltsql_get_yyleng();
		else if (ctx->tok == '(')
		{
			int paren_level = 1;

			/*
			 * We saw an open paren, this must be a parenthesized
			 * expression:
			 *    SELECT TOP (@count + 2) PERCENT
			 * scan for the matching close paren
			 */

			while (paren_level)
			{
				ctx->tok = yylex();

				if (ctx->tok == ')')
					paren_level--;
				else if (ctx->tok == '(')
					paren_level++;
				else if (ctx->tok == 0)
					yyerror("syntax error - matching ')' not found");
			}

			return pltsql_get_source(start, (yylloc - start) + 1);

		}
		else
		{
			/*
			 * We've just scanned a token that does not belong in 
			 * the TOP clause - return the text of the clause
			 * to the caller
			 */
			pltsql_push_back_token(ctx->tok);
			return pltsql_get_source(start, yylloc - start);
		}
	}

	return NULL; /* Keep compiler happy */
}

/*
 * read_select_modifiers2()
 *
 *  Scans for tokens that may appear (in a SELECT statement) between the SELECT 
 *  and the select list.
 *
 *  TSQL allows ALL, DISTINCT, or a TOP clause
 *
 *  NOTE: the caller should save and restore pltsql_IdentifierLookup 'cuz we
 *        don't bother
 */
static char *
read_select_modifiers2(execsql_ctx *ctx)
{
	StringInfoData result;

	initStringInfo(&result);

	while ((ctx->tok = yylex()) != -1)
	{
		if (word_matches(ctx->tok, "TOP"))
			appendStringInfoString(&result, read_top_clause(ctx));
		else if(word_matches(ctx->tok, "ALL"))
			appendStringInfoString(&result, "ALL ");
		else if (word_matches(ctx->tok, "DISTINCT"))
			appendStringInfoString(&result, "DISTINCT ");
		else
		{
			pltsql_push_back_token(ctx->tok);
			return result.data;
		}
	}

	return NULL; /* Keep compiler happy */
}

/* 
 * read_select_modifiers()
 *
 *  This is a wrapper around read_select_modifiers2(); we
 *  save pltsql_IdentifierLookup, set it as desired, call
 *  read_select_modifiers2(), and then restores the original
 *  value of pltsql_IdentifierLookup.
 */
static char *
read_select_modifiers(execsql_ctx *ctx)
{
	IdentifierLookup save = pltsql_IdentifierLookup;
	char *result;

	pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_NORMAL;
	result = read_select_modifiers2(ctx);
	pltsql_IdentifierLookup = save;

	YYDPRINTF((stderr, "result{%s}\n", result));

	return result;
}

static List *
read_target_list(execsql_ctx *ctx)
{
	List *result = NIL;
	List * targets;
	query_target *target;
	ListCell *it;

	/*
	 *  SELECT @a = balance / 2, @name = cust_name FROM customer
	 *  SELECT balance, cust_name FROM customer
	 *	SELECT @name_upper = upper(@name) PRINT @name_upper
	 */

	while ((targets = read_query_targets()) != NULL)
		result = list_concat(result, targets);

	YYDPRINTF((stderr, "--------------------\n"));
	YYDPRINTF((stderr, "%d targets:\n", list_length(result)));

	foreach (it, result)
	{
		target = (query_target *) lfirst(it);
		YYDPRINTF((stderr, "dno = %d : expr = {%s}\n", target->dno, target->src->query));

	}

	YYDPRINTF((stderr, "--------------------\n"));

	/*
	 * FIXME: if any target has both a dno and a src, all
	 *        targets must have both (I think)
	 */

	return result;
}


/*
 * Takes in a target list, and split them by appending to given target list, if they are query target or variable target.
 * The source list will be removed.
 * e.g. in statement "UPDATE t SET @v = 1, column = 2"
 * @v = 1 is a variable target, column = 2 is a query target
 */
static void
split_target_list(List *source_list, List **query_target_list, List **variable_target_list)
{
	ListCell *it;
	foreach (it, source_list)
	{
		query_target *target = (query_target *) lfirst(it);
		if	(target->dno == -1)
			*query_target_list = lappend(*query_target_list, target);
		else
			*variable_target_list = lappend(*variable_target_list, target);
	}
	list_free(source_list);
}

static bool
check_target_list(List *targets)
{
	int into_count = 0, return_count = 0;
	ListCell *t;
	int tok = yylex();

	pltsql_push_back_token(tok);

	if (tok == K_INTO)
		return true;

	foreach (t, targets)
	{
		query_target *target = lfirst(t);

		if (target->dno == -1)
			return_count++;
		else
			into_count++;

	}

	if (into_count && return_count)
		yyerror("all targets must be of the same form");

	if (into_count)
		return true;
	else
		return false;
}

/*
 * Tsql constrains certain CREATE statements such that
 * those statements must be the only statement within a batch.
 *
 * This function (must_be_only_stmt()) returns true if the 
 * current token specifies one of those object types.  Presumably
 * the caller has already detected the CREATE (and optional OR 
 * ALTER keywords) and the current token (found in ctx->tox) 
 * specifies an object type.
 */ 
static bool
must_be_only_stmt(execsql_ctx *ctx)
{
	switch (ctx->tok)
	{
	    case K_DEFAULT:
	    case K_SCHEMA:
			return true;

	    case T_WORD:
		{
			if (word_matches(T_WORD, "FUNCTION"))
				return true;
			if (word_matches(T_WORD, "PROCEDURE"))
				return true;
			if (word_matches(T_WORD, "PROC"))
				return true;
			if (word_matches(T_WORD, "RULE"))
				return true;
			if (word_matches(T_WORD, "TRIGGER"))
				return true;
			if (word_matches(T_WORD, "VIEW"))
				return true;

			return false;
		}
		
	    default:
			return false;
	}
}

/*
 * This function (make_create_stmt()) will determine whether
 * the current CREATE statement must be the only statement
 * within a batch (see the must_be_only_stmt() function), and,
 * if so, will read the entire batch and convert it into an execsql
 * statement (which we simply hand off to the SQL parser).
 *
 * If the CREATE statement specifies some other type of
 * object (such as CREATE USER...), we had the work off 
 * to make_execsql_stmt()
 *
 * The difference is that CREATE FUNCTION/PROCEDURE/... extends
 * to the last token in the batch, whereas CREATE USER/TABLE/...
 * extends to the beginning of the next statement.
 */

static PLtsql_stmt *
make_create_stmt(int firsttoken, int location, PLword *firstword)
{
	execsql_ctx ctx;
	PLtsql_stmt_execsql *execsql;
	
	YYDPRINTF((stderr, "*** make_create_stmt()\n"));

	Assert(word_matches(firsttoken, "CREATE"));

	init_execsql_ctx(&ctx, firsttoken, location, firstword);

	if ((ctx.tok = yylex()) == K_OR)
	{
		ctx.tok = yylex();
		ctx.tok = yylex();
	}
	else
		pltsql_push_back_token(ctx.tok);

	/*
	 * According to:
	 *    https://tinyurl.com/first-stmt-in-batch
	 * 
	 * the following statements must be the only statement in a batch:
	 *  CREATE DEFAULT
	 *  CREATE FUNCTION
	 *  CREATE PROCEDURE
	 *  CREATE RULE
	 *  CREATE SCHEMA
	 *  CREATE TRIGGER
	 *  CREATE VIEW
	 */
	if (must_be_only_stmt(&ctx))
	{
		while ((ctx.tok = yylex()) != 0)
			YY_SYMBOL_PRINT ("*** next token", YYTRANSLATE(ctx.tok), &yylval, &yylloc);

		pltsql_append_source_text(&ctx.ds, ctx.location, yylloc);

		ctx.expr = palloc0(sizeof(PLtsql_expr));
		ctx.expr->query	   = pstrdup(quote_tsql_identifiers(&ctx.ds, ctx.tsql_idents));
		ctx.expr->plan	   = NULL;
		ctx.expr->paramnos = NULL;
		ctx.expr->rwparam  = -1;
		ctx.expr->ns	   = pltsql_ns_top();
		pfree(ctx.ds.data);
	
		execsql			  = palloc(sizeof(PLtsql_stmt_execsql));
		execsql->cmd_type = PLTSQL_STMT_EXECSQL;
		execsql->lineno   = pltsql_location_to_lineno(location);
		execsql->sqlstmt  = ctx.expr;
		execsql->into	  = false;
		execsql->strict   = false;
		execsql->target   = NULL;
		execsql->mod_stmt_tablevar = false;
		execsql->need_to_push_result = false;
		execsql->is_tsql_select_assign_stmt = false;

		return (PLtsql_stmt *) execsql;
	}
	else
	{
		pltsql_IdentifierLookup = ctx.save_IdentifierLookup;
		return make_execsql_stmt(T_WORD, location, firstword, NULL);
	}
}

/* used by make_select_stmt() and make_update_stmt() to process common statement components.
 */
static void process_common_stmt_component(execsql_ctx *ctx)
{
	for (;;)
	{
		ctx->prev_tok = ctx->tok;
		ctx->tok = yylex();

		YY_SYMBOL_PRINT ("*** next token", YYTRANSLATE(ctx->tok), &yylval, &yylloc);

		manage_paren_level(ctx);

		if (ctx->have_into && ctx->into_end_loc < 0)
			ctx->into_end_loc = yylloc;		/* token after the INTO part */

		if (ctx->tok == ';')
		{
			YYDPRINTF((stderr, "*** found a semicolon, terminating loop\n"));
			break;
		}

		if (ctx->tok == 0)
		{
			YYDPRINTF((stderr, "*** found end-of-input, terminating loop\n"));
			break;
		}

		/*
			* If we encounter a CASE, increment caselevel so we know that we are 
			* scanning a CASE expression.  We decrement caselevel when we encounter
			* an END.  We need to know if we are in a CASE expression because that
			* changes the meaning of END and ELSE tokens
			*/
		if (ctx->tok == K_CASE)
			ctx->caselevel++;

		if (ctx->tok == K_ELSE && ctx->caselevel == 0)
		{
			pltsql_push_back_token(ctx->tok);
			break;
		}

		if (ctx->tok == K_END)
		{
			if (ctx->caselevel)
				ctx->caselevel--;
			else
			{
				pltsql_push_back_token(ctx->tok);
				break;
			}
		}

		/*
			* We have some special handling for "UNION", which is followed by
			* "SELECT" which should be treated as part of the current statement,
			* instead of the start of the next one. To utilize it, we treat "UNION
			* ALL" just like "UNION" by skipping the "ALL" here.
			*/
		if (ctx->tok == K_ALL && ctx->prev_tok == K_UNION)
		{
			ctx->tok = K_UNION;
			continue;
		}

		if (ctx->tok == K_OUTPUT && ctx->is_update_with_variables)
			yyerror("UPDATE statement with variables with OUTPUT clause is not yet supported");
		/*
			* Determine whether the new token introduces a new statement, but 
			* only only if this token is not found within an unclosed set of 
			* parentheses.
			*
			* Consider, for example: 
			*
			*    SELECT * FROM customer WHERE id = (SELECT 2) LIMIT 1;
			*
			* The second SELECT does NOT introduce a new statement.
			*/ 
		if (ctx->parenlevel == 0)
		{

			/*
				* is_terminator() returns TRUE for "WITH", which will cause the
				* next parse to do make_select_cte(). This is not always desirable
				* because we might have statements like:
				*   SELECT count(*) from pg_type with (tablockx);
				* So, we add an additional check to catch cases like this.
				*/
			if (word_matches(ctx->tok, "WITH"))
			{
				ctx->tok = yylex();
				if (ctx->tok == '(')
				{
					pltsql_push_back_token(ctx->tok);
					continue;
				}
				pltsql_push_back_token(ctx->tok);
			}

			/*
				* is_terminator() returns TRUE for "SELECT" that does not appear
				* first. This doesn't work for statements like:
				*   SELECT ... UNION (ALL) SELECT ...
				* So, we add an additional check to catch cases like this.
				*/
			if (word_matches(ctx->tok, "SELECT") && ctx->prev_tok == K_UNION)
				continue;

			if (is_terminator(ctx->tok, (ctx->startlocation == yylloc),
								ctx->startlocation, yylloc, NULL, ctx->tsql_idents))
			{
				YY_SYMBOL_PRINT ("*** found a terminator, pushing back", YYTRANSLATE(ctx->tok), &yylval, &yylloc);
				pltsql_push_back_token(ctx->tok);
				break;
			}
		}

		ctx->tsql_idents = append_if_tsql_identifier(ctx->tok, 0, ctx->location, ctx->tsql_idents);
		if (ctx->tok == 0)
			yyerror("unexpected end of function definition");

		if (ctx->tok == K_INTO && ctx->prev_tok != K_INSERT)
		{
			if (ctx->have_into)
				yyerror("INTO specified more than once");

			ctx->have_into = true;
			ctx->into_start_loc = yylloc;

			pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_NORMAL;
			read_into_target(&ctx->target, &ctx->have_strict, &ctx->select_into_table_name, &ctx->have_temptbl);
			pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_EXPR;
		}
	}

	pltsql_IdentifierLookup = ctx->save_IdentifierLookup;
}


static PLtsql_stmt *
make_select_stmt(int firsttoken, int location, PLword *firstword, PLtsql_expr *with_clauses)
{
	static int callCount = 0;
	execsql_ctx ctx;
	PLtsql_row *target_row;
	bool into;

	YYDPRINTF((stderr, "*** make_select_stmt(call %d)\n", callCount++));

	Assert(word_matches(firsttoken, "SELECT"));

	init_execsql_ctx(&ctx, firsttoken, location, firstword);

	parse_and_build_select_expr(&ctx, with_clauses, &target_row, &into);

	/*
	 * If have_temptbl is true, the first two tokens were valid so we expect
	 * that check_sql_expr will raise errors from a location occurring after
	 * the TEMPORARY token.  Because the original statement did not include it,
	 * we offset the error location with its length so it points back to the
	 * correct location in the original source.
	 */
	check_sql_expr(ctx.expr->query, ctx.location, (ctx.have_temptbl ?
												   strlen(TEMPOBJ_QUALIFIER) : 0));

	if (into)
	{
		/* 
		 * We've converted 'SELECT ... INTO' to 'CREATE TABLE AS...', so
		 * need to create execsql stmt instead of select set stmt for it.
		 */
		if (ctx.select_into_table_name != NULL) {
			PLtsql_stmt_execsql *result = palloc(sizeof(*result));
			result->cmd_type = PLTSQL_STMT_EXECSQL;
			result->lineno   = pltsql_location_to_lineno(location);
			result->sqlstmt  = ctx.expr;
			/* Need to explicitly make this false */
			result->into     = false;
			result->mod_stmt_tablevar = false;
			result->need_to_push_result = false;
			result->is_tsql_select_assign_stmt = false;

			return (PLtsql_stmt *) result;
		}
		else
		{
			PLtsql_stmt_query_set *result = palloc(sizeof(*result));

			result->cmd_type = PLTSQL_STMT_QUERY_SET;
			result->lineno   = pltsql_location_to_lineno(location);
			result->sqlstmt  = ctx.expr;
			result->target   = (PLtsql_variable *) target_row;

			return (PLtsql_stmt *) result;
		}
	}
	else
	{
		/*
		 * This SELECT does not specify any destination so we will
		 * treat it like a RETURN QUERY statement. This will return
		 * the result set to the caller.
		 *
		 * See https://stackoverflow.com/questions/11907563/declaring-the-tuple-structure-of-a-record-in-pl-pgsql
		 *
		 * FIXME: this leaves the following problems:
		 *	1) T-SQL procedures (and functions?) can return multiple result sets
		 *  2) T-SQL does not require the caller to declare the record format 
		 */

		PLtsql_stmt_push_result *result = palloc(sizeof(*result));

		result->cmd_type = PLTSQL_STMT_PUSH_RESULT;
		result->lineno	 = pltsql_location_to_lineno(location);
		result->query	 = ctx.expr;

		return (PLtsql_stmt *)result;
	}
}

static void
parse_and_build_select_expr(execsql_ctx *ctx, PLtsql_expr *with_clauses, PLtsql_row **target_row, bool *has_destination)
{
	List *target_list;
	char *modifiers;
	PLtsql_expr *target_expr;
	StringInfoData query;
	int i;

	/*
	 * scan for any modifiers that may appear between SELECT and
	 * the target list (specifically, ALL, DISTINCT, or a TOP clause)
	 */
	modifiers = read_select_modifiers(ctx);
	target_list = read_target_list(ctx);

	if (has_destination)
		(*has_destination) = check_target_list(target_list);
	if (target_row)
		(*target_row) = make_target_row(target_list, yylloc);
	target_expr = make_target_expr(target_list, yylloc);

	YYDPRINTF((stderr, "*** target_expr {%s}\n", target_expr->query));

	if (target_row)
	{
		YYDPRINTF((stderr, "*** target_row \n"));

		for (i = 0; i < (*target_row)->nfields; i++)
			YYDPRINTF((stderr, "*** %d - %s (varno %d)\n", i, (*target_row)->fieldnames[i], (*target_row)->varnos[i]));
	}

	ctx->location = yylloc;

	process_common_stmt_component(ctx);

	if (ctx->have_into)
	{
		/*
		 * Insert an appropriate number of spaces corresponding to the
		 * INTO text, so that locations within the redacted SQL statement
		 * still line up with those in the original source text.
		 */
		pltsql_append_source_text(&ctx->ds, ctx->location, ctx->into_start_loc);
		appendStringInfoSpaces(&ctx->ds, ctx->into_end_loc - ctx->into_start_loc);
		pltsql_append_source_text(&ctx->ds, ctx->into_end_loc, yylloc);
	}
	else
	{
		pltsql_append_source_text(&ctx->ds, ctx->location, yylloc);
	}

	/* trim any trailing whitespace, for neatness */
	while (ctx->ds.len > 0 && scanner_isspace(ctx->ds.data[ctx->ds.len - 1]))
		ctx->ds.data[--ctx->ds.len] = '\0';

	initStringInfo(&query);
	if (ctx->select_into_table_name != NULL)
	{
		if (with_clauses)
			appendStringInfo(&query, "CREATE %s TABLE %s AS (%s SELECT %s %s %s)",
						ctx->have_temptbl ? TEMPOBJ_QUALIFIER : "",
						ctx->select_into_table_name,
						with_clauses->query,
						modifiers,
						target_expr->query,
						quote_tsql_identifiers(&ctx->ds, ctx->tsql_idents));
		else
			appendStringInfo(&query, "CREATE %s TABLE %s AS (SELECT %s %s %s)",
						ctx->have_temptbl ? TEMPOBJ_QUALIFIER : "",
						ctx->select_into_table_name,
						modifiers,
						target_expr->query,
						quote_tsql_identifiers(&ctx->ds, ctx->tsql_idents));
	}
	else
	{
		if (with_clauses)
			appendStringInfo(&query, "%s SELECT %s %s %s", with_clauses->query, modifiers, target_expr->query, quote_tsql_identifiers(&ctx->ds, ctx->tsql_idents));
		else
			appendStringInfo(&query, "SELECT %s %s %s", modifiers, target_expr->query, quote_tsql_identifiers(&ctx->ds, ctx->tsql_idents));
	}

	YYDPRINTF((stderr, "*** final query\n    %s\n", query.data));

	ctx->expr = palloc0(sizeof(PLtsql_expr));
#if 0
	ctx->expr->dtype	= PLTSQL_DTYPE_EXPR;
#endif
	ctx->expr->query	   = pstrdup(query.data);
	ctx->expr->plan	   = NULL;
	ctx->expr->paramnos = NULL;
	ctx->expr->rwparam  = -1;
	ctx->expr->ns	   = pltsql_ns_top();
	pfree(ctx->ds.data);
}

static PLtsql_stmt *
make_update_stmt(int firsttoken, int location, PLword *firstword, PLtsql_expr *with_clauses)
{
	static int callCount = 0;
	execsql_ctx ctx;
	List *target_list;
	List *query_target_list = NIL;
	List *output_target_list = NIL;
	PLtsql_row *target_row;
	PLtsql_expr *target_expr;
	PLtsql_expr *variable_output_expr;
	PLtsql_expr *update_query_expr;
	StringInfoData query;
	bool into;
	int i;

	YYDPRINTF((stderr, "*** make_update_stmt(call %d)\n", callCount++));

	Assert(word_matches(firsttoken, "UPDATE"));

	init_execsql_ctx(&ctx, firsttoken, location, firstword);

	/*
	 * FIXME: UPDATE with modifiers is forbidden at parser level
	 * in Babel afm, so read_select_modifiers function call will
	 * never read anything.
	 * For now it is kept here in case we want to work on it again.

	 */
	/* modifiers = read_select_modifiers(&ctx); */

	update_query_expr = read_sql_construct_bos(K_SET, 0, 0, "SET ",
                                  "", true, false, true, NULL, NULL, false, NULL, false);

	target_list = read_target_list(&ctx);

	split_target_list(target_list, &query_target_list, &output_target_list);

	into = (output_target_list != NIL);

	target_row = make_target_row(output_target_list, yylloc);
	target_expr = make_target_expr(query_target_list, yylloc);
	variable_output_expr = make_target_expr(output_target_list, yylloc);

	if (query_target_list == NIL && output_target_list != NIL)
		yyerror("UPDATE statement with variables without table update is not yet supported");

	if (output_target_list != NIL)
		ctx.is_update_with_variables = true;

	YYDPRINTF((stderr, "*** target_expr {%s}\n", target_expr->query));
	YYDPRINTF((stderr, "*** target_row \n"));

	for (i = 0; i < target_row->nfields; i++)
	YYDPRINTF((stderr, "*** %d - %s (varno %d)\n", i, target_row->fieldnames[i], target_row->varnos[i]));

	ctx.location = yylloc;

	process_common_stmt_component(&ctx);

	pltsql_append_source_text(&ctx.ds, ctx.location, yylloc);

	/* trim any trailing whitespace, for neatness */
	while (ctx.ds.len > 0 && scanner_isspace(ctx.ds.data[ctx.ds.len - 1]))
		ctx.ds.data[--ctx.ds.len] = '\0';

	initStringInfo(&query);
	if (with_clauses)
		appendStringInfo(&query, "%s UPDATE %s SET %s %s", with_clauses->query, update_query_expr->query, target_expr->query, quote_tsql_identifiers(&ctx.ds, ctx.tsql_idents));
	else
		appendStringInfo(&query, " UPDATE %s SET %s %s", update_query_expr->query, target_expr->query, quote_tsql_identifiers(&ctx.ds, ctx.tsql_idents));
	if (into)
		appendStringInfo(&query, " RETURNING %s", variable_output_expr->query);

	YYDPRINTF((stderr, "*** final query\n    %s\n", query.data));

	ctx.expr = palloc0(sizeof(PLtsql_expr));
#if 0
	ctx.expr->dtype	= PLTSQL_DTYPE_EXPR;
#endif
	ctx.expr->query	   = pstrdup(query.data); 
	ctx.expr->plan	   = NULL;
	ctx.expr->paramnos = NULL;
	ctx.expr->rwparam  = -1;
	ctx.expr->ns	   = pltsql_ns_top();
	pfree(ctx.ds.data);

	/*
	 * If have_temptbl is true, the first two tokens were valid so we expect
	 * that check_sql_expr will raise errors from a location occurring after
	 * the TEMPORARY token.  Because the original statement did not include it,
	 * we offset the error location with its length so it points back to the
	 * correct location in the original source.
	 */
	check_sql_expr(ctx.expr->query, ctx.location, (ctx.have_temptbl ?
												   strlen(TEMPOBJ_QUALIFIER) : 0));

	if (into)
	{
		/*
		 * UPDATE with variables will use query_set
		 */
		PLtsql_stmt_query_set *result = palloc(sizeof(*result));

		result->cmd_type = PLTSQL_STMT_QUERY_SET;
		result->lineno   = pltsql_location_to_lineno(location);
		result->sqlstmt  = ctx.expr;
		result->target   = (PLtsql_variable *) target_row;

		return (PLtsql_stmt *) result;
	}
	else
	{
		/*
		 * UPDATE with no variables
		 */
		PLtsql_stmt_execsql *result = palloc(sizeof(*result));

		result->cmd_type = PLTSQL_STMT_EXECSQL;
		result->lineno	 = pltsql_location_to_lineno(location);
		result->sqlstmt	 = ctx.expr;
		result->into	 = false;
		result->strict   = ctx.have_strict;
		result->target   = ctx.target;
		result->mod_stmt_tablevar = false;
		result->need_to_push_result = false;
		result->is_tsql_select_assign_stmt = false;

		return (PLtsql_stmt *)result;
	}
}

/*
 * Read FETCH or MOVE direction clause (everything through FROM/IN).
 */
static PLtsql_stmt_fetch *
read_fetch_direction(void)
{
	PLtsql_stmt_fetch *fetch;
	int			tok;
	bool		check_FROM = true;

	/*
	 * We create the PLtsql_stmt_fetch struct here, but only fill in
	 * the fields arising from the optional direction clause
	 */
	fetch = (PLtsql_stmt_fetch *) palloc0(sizeof(PLtsql_stmt_fetch));
	fetch->cmd_type = PLTSQL_STMT_FETCH;
	/* set direction defaults: */
	fetch->direction = FETCH_FORWARD;
	fetch->how_many  = 1;
	fetch->expr		 = NULL;
	fetch->returns_multiple_rows = false;

	tok = yylex();
	if (tok == 0)
		yyerror("unexpected end of function definition");

	if (tok_is_keyword(tok, &yylval,
					   K_NEXT, "next"))
	{
		/* use defaults */
	}
	else if (tok_is_keyword(tok, &yylval,
							K_PRIOR, "prior"))
	{
		fetch->direction = FETCH_BACKWARD;
	}
	else if (tok_is_keyword(tok, &yylval,
							K_FIRST, "first"))
	{
		fetch->direction = FETCH_ABSOLUTE;
	}
	else if (tok_is_keyword(tok, &yylval,
							K_LAST, "last"))
	{
		fetch->direction = FETCH_ABSOLUTE;
		fetch->how_many  = -1;
	}
	else if (tok_is_keyword(tok, &yylval,
							K_ABSOLUTE, "absolute"))
	{
		fetch->direction = FETCH_ABSOLUTE;
		fetch->expr = read_sql_expression2(K_FROM, K_IN,
										   "FROM or IN",
										   NULL);
		check_FROM = false;
	}
	else if (tok_is_keyword(tok, &yylval,
							K_RELATIVE, "relative"))
	{
		fetch->direction = FETCH_RELATIVE;
		fetch->expr = read_sql_expression2(K_FROM, K_IN,
										   "FROM or IN",
										   NULL);
		check_FROM = false;
	}
	else if (tok_is_keyword(tok, &yylval,
							K_ALL, "all"))
	{
		fetch->how_many = FETCH_ALL;
		fetch->returns_multiple_rows = true;
	}
	else if (tok_is_keyword(tok, &yylval,
							K_FORWARD, "forward"))
	{
		complete_direction(fetch, &check_FROM);
	}
	else if (tok_is_keyword(tok, &yylval,
							K_BACKWARD, "backward"))
	{
		fetch->direction = FETCH_BACKWARD;
		complete_direction(fetch, &check_FROM);
	}
	else if (tok == K_FROM || tok == K_IN)
	{
		/* empty direction */
		check_FROM = false;
	}
	else if (tok == T_DATUM)
	{
		/* Assume there's no direction clause and tok is a cursor name */
		pltsql_push_back_token(tok);
		check_FROM = false;
	}
	else
	{
		/*
		 * Assume it's a count expression with no preceding keyword.
		 * Note: we allow this syntax because core SQL does, but we don't
		 * document it because of the ambiguity with the omitted-direction
		 * case.  For instance, "MOVE n IN c" will fail if n is a variable.
		 * Perhaps this can be improved someday, but it's hardly worth a
		 * lot of work.
		 */
		pltsql_push_back_token(tok);
		fetch->expr = read_sql_expression2(K_FROM, K_IN,
										   "FROM or IN",
										   NULL);
		fetch->returns_multiple_rows = true;
		check_FROM = false;
	}

	/* check FROM or IN keyword after direction's specification */
	if (check_FROM)
	{
		tok = yylex();
		if (tok != K_FROM && tok != K_IN)
			yyerror("expected FROM or IN");
	}

	return fetch;
}

/*
 * Process remainder of FETCH/MOVE direction after FORWARD or BACKWARD.
 * Allows these cases:
 *   FORWARD expr,  FORWARD ALL,  FORWARD
 *   BACKWARD expr, BACKWARD ALL, BACKWARD
 */
static void
complete_direction(PLtsql_stmt_fetch *fetch,  bool *check_FROM)
{
	int			tok;

	tok = yylex();
	if (tok == 0)
		yyerror("unexpected end of function definition");

	if (tok == K_FROM || tok == K_IN)
	{
		*check_FROM = false;
		return;
	}

	if (tok == K_ALL)
	{
		fetch->how_many = FETCH_ALL;
		fetch->returns_multiple_rows = true;
		*check_FROM = true;
		return;
	}

	pltsql_push_back_token(tok);
	fetch->expr = read_sql_expression2(K_FROM, K_IN,
									   "FROM or IN",
									   NULL);
	fetch->returns_multiple_rows = true;
	*check_FROM = false;
}


static PLtsql_stmt *
make_return_stmt(int location)
{
	int tok = 0;
	PLtsql_stmt_return *new;

	new = palloc0(sizeof(PLtsql_stmt_return));
	new->cmd_type = PLTSQL_STMT_RETURN;
	new->lineno   = pltsql_location_to_lineno(location);
	new->expr	  = NULL;
	new->retvarno = -1;

	if (pltsql_curr_compile->fn_prokind == PROKIND_PROCEDURE)
	{
		tok = yylex();
		if (!is_terminator(tok, false, yylloc, yylloc, NULL, NIL) &&
			(tok != K_END) && (tok != K_ELSE))
		{
			/* 
			 * If we run into a "naked" RETURN statement (that is, a
			 * RETURN statement with no arguments), the following call
			 * to read_sql_expression_bos() will return an incomplete
			 * query (just the word "SELECT"). We just set expr->query
			 * to NULL (above) for a naked RETURN
			 */
			PLtsql_expr *expr;

			pltsql_push_back_token(tok);
			tok = 0;

			expr = read_sql_expression_bos(';', ";", true);

			if (strcmp(expr->query, "SELECT") != 0)
				new->expr = expr;
		}

		/*
		 * If we have any OUT parameters, remember which variable
		 * will hold the output tuple.
		 */
		if (pltsql_curr_compile->out_param_varno >= 0)
			new->retvarno = pltsql_curr_compile->out_param_varno;
		
	}
	else if (pltsql_curr_compile->fn_retset)
	{
		tok = yylex();
		if (!is_terminator(tok, false, yylloc, yylloc, NULL, NIL) &&
			(tok != K_END) && (tok != K_ELSE))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("RETURN cannot have a parameter in function returning set"),
					 errhint("Use RETURN NEXT or RETURN QUERY."),
					 parser_errposition(yylloc)));
	}
	else if (pltsql_curr_compile->out_param_varno >= 0)
	{
		tok = yylex();
		if (!is_terminator(tok, false, yylloc, yylloc, NULL, NIL) &&
			(tok != K_END) && (tok != K_ELSE))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("RETURN cannot have a parameter in function with OUT parameters"),
					 parser_errposition(yylloc)));
		new->retvarno = pltsql_curr_compile->out_param_varno;
	}
	else if (pltsql_curr_compile->fn_rettype == VOIDOID)
	{
		tok = yylex();
		if (!is_terminator(tok, false, yylloc, yylloc, NULL, NIL) &&
			(tok != K_END) && (tok != K_ELSE))
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("RETURN cannot have a parameter in function returning void"),
					 parser_errposition(yylloc)));
	}
	else if (pltsql_curr_compile->fn_retistuple)
	{
		int tok1 = yylex();
		switch (tok1)
		{
			case K_NULL:
				/* we allow this to support RETURN NULL in triggers */
				break;

			case T_DATUM:
				if (yylval.wdatum.datum->dtype == PLTSQL_DTYPE_ROW ||
					yylval.wdatum.datum->dtype == PLTSQL_DTYPE_REC)
					new->retvarno = yylval.wdatum.datum->dno;
				else
					ereport(ERROR,
							(errcode(ERRCODE_DATATYPE_MISMATCH),
							 errmsg("RETURN must specify a record or row variable in function returning row"),
							 parser_errposition(yylloc)));
				break;

			default:
				/* For TSQL DML triggers, allow empty return, which is equivalent of
				 * return NULL */
				if (pltsql_curr_compile->fn_is_trigger == PLTSQL_DML_TRIGGER) {
					 pltsql_push_back_token(tok1);
					break;
				}
				ereport(ERROR,
						(errcode(ERRCODE_DATATYPE_MISMATCH),
						 errmsg("RETURN must specify a record or row variable in function returning row"),
						 parser_errposition(yylloc)));
				break;
		}
		tok = yylex();
		if (!is_terminator(tok, false, yylloc, yylloc, NULL, NIL) &&
			(tok != K_END) && (tok != K_ELSE))
			yyerror("syntax error");
	}
	else
	{
		/*
		 * Note that a well-formed expression is _required_ here;
		 * anything else is a compile-time error.
		 */
		new->expr = read_sql_expression_bos(';', ";", false);
	}

	if ((tok != 0) && (tok != ';'))
		pltsql_push_back_token(tok);

	return (PLtsql_stmt *) new;
}


static PLtsql_stmt *
make_return_next_stmt(int location)
{
	PLtsql_stmt_return_next *new;

	if (!pltsql_curr_compile->fn_retset)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("cannot use RETURN NEXT in a non-SETOF function"),
				 parser_errposition(location)));

	new = palloc0(sizeof(PLtsql_stmt_return_next));
	new->cmd_type	= PLTSQL_STMT_RETURN_NEXT;
	new->lineno		= pltsql_location_to_lineno(location);
	new->expr		= NULL;
	new->retvarno	= -1;

	if (pltsql_curr_compile->out_param_varno >= 0)
	{
		if (yylex() != ';')
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("RETURN NEXT cannot have a parameter in function with OUT parameters"),
					 parser_errposition(yylloc)));
		new->retvarno = pltsql_curr_compile->out_param_varno;
	}
	else if (pltsql_curr_compile->fn_retistuple)
	{
		switch (yylex())
		{
			case T_DATUM:
				if (yylval.wdatum.datum->dtype == PLTSQL_DTYPE_ROW ||
					yylval.wdatum.datum->dtype == PLTSQL_DTYPE_REC)
					new->retvarno = yylval.wdatum.datum->dno;
				else
					ereport(ERROR,
							(errcode(ERRCODE_DATATYPE_MISMATCH),
							 errmsg("RETURN NEXT must specify a record or row variable in function returning row"),
							 parser_errposition(yylloc)));
				break;

			default:
				ereport(ERROR,
						(errcode(ERRCODE_DATATYPE_MISMATCH),
						 errmsg("RETURN NEXT must specify a record or row variable in function returning row"),
						 parser_errposition(yylloc)));
				break;
		}
		if (yylex() != ';')
			yyerror("syntax error");
	}
	else
		new->expr = read_sql_expression(';', ";");

	return (PLtsql_stmt *) new;
}


static PLtsql_stmt *
make_return_query_stmt(int location, PLtsql_expr *with_clauses)
{
	PLtsql_stmt_return_query *new;
	int			tok;
	StringInfoData query;
	StringInfoData itvf_query;

	if (!pltsql_curr_compile->fn_retset)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("cannot use RETURN QUERY in a non-SETOF function"),
				 parser_errposition(location)));

	new = palloc0(sizeof(PLtsql_stmt_return_query));
	new->cmd_type = PLTSQL_STMT_RETURN_QUERY;
	new->lineno = pltsql_location_to_lineno(location);

	/* check for RETURN QUERY EXECUTE */
	if ((tok = yylex()) != K_EXECUTE)
	{
		/* ordinary static query */
		pltsql_push_back_token(tok);
		new->query = read_sql_stmt_bos("");
		if (with_clauses)
		{
			initStringInfo(&query);
			appendStringInfo(&query, "%s %s", with_clauses->query,
			new->query->query);
			new->query->query = pstrdup(query.data);

			initStringInfo(&itvf_query);
			appendStringInfo(&itvf_query, "%s %s", with_clauses->itvf_query,
			new->query->itvf_query);
			new->query->itvf_query = pstrdup(itvf_query.data);
		}
	}
	else
	{
		/* dynamic SQL */
		int		term;

		new->dynquery = read_sql_expression2(';', K_USING, "; or USING",
											 &term);
		if (with_clauses)
		{
			initStringInfo(&query);
			appendStringInfo(&query, "%s %s", with_clauses->query,
			new->dynquery->query);
			new->dynquery->query = pstrdup(query.data);

			initStringInfo(&itvf_query);
			appendStringInfo(&itvf_query, "%s %s", with_clauses->itvf_query,
			new->dynquery->itvf_query);
			new->dynquery->itvf_query = pstrdup(itvf_query.data);
		}
		if (term == K_USING)
		{
			do
			{
				PLtsql_expr *expr;

				expr = read_sql_expression2(',', ';', ", or ;", &term);
				new->params = lappend(new->params, expr);
			} while (term == ',');
		}
	}

	return (PLtsql_stmt *) new;
}


/* convenience routine to fetch the name of a T_DATUM */
static char *
NameOfDatum(const PLwdatum *wdatum)
{
	if (wdatum->ident)
		return wdatum->ident;
	Assert(wdatum->idents != NIL);
	return NameListToString(wdatum->idents);
}

static void
check_assignable(PLtsql_datum *datum, int location)
{
	switch (datum->dtype)
	{
		case PLTSQL_DTYPE_VAR:
			if (((PLtsql_var *) datum)->isconst)
				ereport(ERROR,
						(errcode(ERRCODE_ERROR_IN_ASSIGNMENT),
						 errmsg("\"%s\" is declared CONSTANT",
								((PLtsql_var *) datum)->refname),
						 parser_errposition(location)));
			break;
		case PLTSQL_DTYPE_ROW:
			/* always assignable? */
			break;
		case PLTSQL_DTYPE_REC:
			/* always assignable?  What about NEW/OLD? */
			break;
		case PLTSQL_DTYPE_RECFIELD:
			/* always assignable? */
			break;
		case PLTSQL_DTYPE_ARRAYELEM:
			/* always assignable? */
			break;
		default:
			elog(ERROR, "unrecognized dtype: %d", datum->dtype);
			break;
	}
}
#if 1
/*
 * Read the argument of an INTO clause.  On entry, we have just read the
 * INTO keyword.
 */
static void
read_into_target(PLtsql_variable **target, bool *strict, char **select_into_table_name, bool *temp_table)
{
	int			tok;

	/* Set default results */
	*target = NULL;
	if (strict)
		*strict = false;

	tok = yylex();
	if (strict && tok == K_STRICT)
	{
		*strict = true;
		tok = yylex();
	}

	/*
	 * Currently, a row or record variable can be the single INTO target,
	 * but not a member of a multi-target list.  So we throw error if there
	 * is a comma after it, because that probably means the user tried to
	 * write a multi-target list.  If this ever gets generalized, we should
	 * probably refactor read_into_scalar_list so it handles all cases.
	 */
	switch (tok)
	{
		case T_DATUM:
			if (yylval.wdatum.datum->dtype == PLTSQL_DTYPE_ROW ||
				yylval.wdatum.datum->dtype == PLTSQL_DTYPE_REC)
			{
				check_assignable(yylval.wdatum.datum, yylloc);
				*target = (PLtsql_variable *) yylval.wdatum.datum;

				if ((tok = yylex()) == ',')
					ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							 errmsg("record variable cannot be part of multiple-item INTO list"),
							 parser_errposition(yylloc)));
				pltsql_push_back_token(tok);
			}
			else
			{
				*target = (PLtsql_variable *)
					read_into_scalar_list(NameOfDatum(&(yylval.wdatum)),
										  yylval.wdatum.datum, yylloc);
			}
			break;
		case T_WORD:
			/* If the caller doesn't expect any table name, just push back and return */
			if (!select_into_table_name)
			{
				pltsql_push_back_token(tok);
			}
			else
			{
				if (strncmp(yylval.word.ident, "#", 1) == 0)
					*temp_table = true;
				*select_into_table_name = yylval.word.ident;
			}
			break;

		default:
			/* just to give a better message than "syntax error" */
			current_token_is_not_variable(tok);
	}
}
#else
/*
 * Read the argument of an INTO clause.  On entry, we have just read the
 * INTO keyword.
 */
static void
read_into_target(PLtsql_rec **rec, PLtsql_row **row, bool *strict)
{
	int			tok;

	/* Set default results */
	*rec = NULL;
	*row = NULL;
	if (strict)
		*strict = false;

	tok = yylex();
	if (strict && tok == K_STRICT)
	{
		*strict = true;
		tok = yylex();
	}

	/*
	 * Currently, a row or record variable can be the single INTO target,
	 * but not a member of a multi-target list.  So we throw error if there
	 * is a comma after it, because that probably means the user tried to
	 * write a multi-target list.  If this ever gets generalized, we should
	 * probably refactor read_into_scalar_list so it handles all cases.
	 */
	switch (tok)
	{
		case T_DATUM:
			if (yylval.wdatum.datum->dtype == PLTSQL_DTYPE_ROW)
			{
				check_assignable(yylval.wdatum.datum, yylloc);
				*row = (PLtsql_row *) yylval.wdatum.datum;

				if ((tok = yylex()) == ',')
					ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							 errmsg("record or row variable cannot be part of multiple-item INTO list"),
							 parser_errposition(yylloc)));
				pltsql_push_back_token(tok);
			}
			else if (yylval.wdatum.datum->dtype == PLTSQL_DTYPE_REC)
			{
				check_assignable(yylval.wdatum.datum, yylloc);
				*rec = (PLtsql_rec *) yylval.wdatum.datum;

				if ((tok = yylex()) == ',')
					ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							 errmsg("record or row variable cannot be part of multiple-item INTO list"),
							 parser_errposition(yylloc)));
				pltsql_push_back_token(tok);
			}
			else
			{
				*row = read_into_scalar_list(NameOfDatum(&(yylval.wdatum)),
											 yylval.wdatum.datum, yylloc);
			}
			break;

		default:
			/* just to give a better message than "syntax error" */
			current_token_is_not_variable(tok);
	}
}
#endif
/*
 * Given the first datum and name in the INTO list, continue to read
 * comma-separated scalar variables until we run out. Then construct
 * and return a fake "row" variable that represents the list of
 * scalars.
 */
static PLtsql_row *
read_into_scalar_list(char *initial_name,
					  PLtsql_datum *initial_datum,
					  int initial_location)
{
	int				 nfields;
	char			*fieldnames[1024];
	int				 varnos[1024];
	PLtsql_row		*row;
	int				 tok;

	check_assignable(initial_datum, initial_location);
	fieldnames[0] = initial_name;
	varnos[0]	  = initial_datum->dno;
	nfields		  = 1;

	while ((tok = yylex()) == ',')
	{
		/* Check for array overflow */
		if (nfields >= 1024)
			ereport(ERROR,
					(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
					 errmsg("too many INTO variables specified"),
					 parser_errposition(yylloc)));

		tok = yylex();
		switch (tok)
		{
			case T_DATUM:
				check_assignable(yylval.wdatum.datum, yylloc);
				if (yylval.wdatum.datum->dtype == PLTSQL_DTYPE_ROW ||
					yylval.wdatum.datum->dtype == PLTSQL_DTYPE_REC)
					ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							 errmsg("\"%s\" is not a scalar variable",
									NameOfDatum(&(yylval.wdatum))),
							 parser_errposition(yylloc)));
				fieldnames[nfields] = NameOfDatum(&(yylval.wdatum));
				varnos[nfields++]	= yylval.wdatum.datum->dno;
				break;

			default:
				/* just to give a better message than "syntax error" */
				current_token_is_not_variable(tok);
		}
	}

	/*
	 * We read an extra, non-comma token from yylex(), so push it
	 * back onto the input stream
	 */
	pltsql_push_back_token(tok);

	row = palloc(sizeof(PLtsql_row));
	row->dtype = PLTSQL_DTYPE_ROW;
	row->refname = pstrdup("*internal*");
	row->lineno = pltsql_location_to_lineno(initial_location);
	row->rowtupdesc = NULL;
	row->nfields = nfields;
	row->fieldnames = palloc(sizeof(char *) * nfields);
	row->varnos = palloc(sizeof(int) * nfields);
	while (--nfields >= 0)
	{
		row->fieldnames[nfields] = fieldnames[nfields];
		row->varnos[nfields] = varnos[nfields];
	}

	pltsql_adddatum((PLtsql_datum *)row);

	return row;
}

/*
 * Convert a single scalar into a "row" list.  This is exactly
 * like read_into_scalar_list except we never consume any input.
 *
 * Note: lineno could be computed from location, but since callers
 * have it at hand already, we may as well pass it in.
 */
static PLtsql_row *
make_scalar_list1(char *initial_name,
				  PLtsql_datum *initial_datum,
				  int lineno, int location)
{
	PLtsql_row		*row;

	check_assignable(initial_datum, location);

	row = palloc(sizeof(PLtsql_row));
	row->dtype = PLTSQL_DTYPE_ROW;
	row->refname = pstrdup("*internal*");
	row->lineno = lineno;
	row->rowtupdesc = NULL;
	row->nfields = 1;
	row->fieldnames = palloc(sizeof(char *));
	row->varnos = palloc(sizeof(int));
	row->fieldnames[0] = initial_name;
	row->varnos[0] = initial_datum->dno;

	pltsql_adddatum((PLtsql_datum *)row);

	return row;
}

/*
 * Increment all the main parser metrics here.
 * Most/all of the TSQL statements differ in grammar w.r.t PG statements
 * But since our TSQL grammar is not complete, we go to PG grammar for a few
 * statements. All the metrics for such statements should be incremented
 * in this function since we can't directly collect metrics from the main
 * backend parser.
 * How to collect metrics for unsupported grammar is still a question ?
 * Mostly, we will have to identify such syntax by adding grammar rules or
 * Plugin instrumentation to Antlr parser once it is done.
 */
static void
IncrementInstr(List *raw_parsetree_list)
{
	ListCell   *parsetree_item;
	PgTsqlInstrMetricType metric = -1;

	if (!PLTSQL_INSTR_ENABLED())
		return;

	foreach(parsetree_item, raw_parsetree_list)
	{
		Node	*parsetree = (lfirst_node(RawStmt, parsetree_item))->stmt;

		switch (nodeTag(parsetree))
		{
			/* raw plannable queries */
			case T_InsertStmt:
				metric = INSTR_TSQL_INSERT_STMT;
				break;

			case T_DeleteStmt:
				metric = INSTR_TSQL_DELETE_STMT;
				break;

			case T_UpdateStmt:
				metric = INSTR_TSQL_UPDATE_STMT;
				break;

			case T_SelectStmt:
				metric = INSTR_TSQL_SELECT_STMT;
				break;

				/* utility statements --- same whether raw or cooked */
			case T_TransactionStmt:
				{
					TransactionStmt *stmt = (TransactionStmt *) parsetree;
					ListCell   *lc;

					switch (stmt->kind)
					{
						case TRANS_STMT_BEGIN:
						case TRANS_STMT_START:
							foreach(lc, stmt->options)
							{
								DefElem    *item = (DefElem *) lfirst(lc);
								if (item != NULL && (strcmp(item->defname, "transaction_isolation") == 0))
								{
									A_Const *n = (A_Const *) item->arg;
									if (n != NULL)
									{
										if (strcmp(n->val.sval.sval, "read uncommitted"))
											TSQLInstrumentation(INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_READ_UNCOMMITTED);
										if (strcmp(n->val.sval.sval, "read committed"))
											TSQLInstrumentation(INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_READ_COMMITTED);
										if (strcmp(n->val.sval.sval, "repeatable read"))
											TSQLInstrumentation(INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_REPEATABLE_READ);
										if (strcmp(n->val.sval.sval, "serializable"))
											TSQLInstrumentation(INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_LEVEL_SERIALIZABLE);
										}
									}
								}
								metric = INSTR_TSQL_TRANS_STMT_START;
								break;

						case TRANS_STMT_COMMIT:
							metric = INSTR_TSQL_TRANS_STMT_COMMIT;
							break;

						case TRANS_STMT_ROLLBACK:
						case TRANS_STMT_ROLLBACK_TO:
							metric = INSTR_TSQL_TRANS_STMT_ROLLBACK;
							break;

						case TRANS_STMT_SAVEPOINT:
							metric = INSTR_TSQL_TRANS_STMT_SAVEPOINT;
							break;

						case TRANS_STMT_RELEASE:
							metric = INSTR_TSQL_TRANS_STMT_RELEASE;
							break;

						case TRANS_STMT_PREPARE:
							metric = INSTR_TSQL_TRANS_STMT_PREPARE;
							break;

						case TRANS_STMT_COMMIT_PREPARED:
							metric = INSTR_TSQL_TRANS_STMT_COMMIT_PREPARED;
							break;

						case TRANS_STMT_ROLLBACK_PREPARED:
							metric = INSTR_TSQL_TRANS_STMT_ROLLBACK_PREPARED;
							break;

						default:
							break;
					}
				}
				break;

			case T_DeclareCursorStmt:
				metric = INSTR_TSQL_DECLARE_CURSOR;
				break;

			case T_ClosePortalStmt:
				{
					ClosePortalStmt *stmt = (ClosePortalStmt *) parsetree;

					if (stmt->portalname == NULL)
						metric = INSTR_TSQL_CLOSE_CURSOR_ALL;
					else
						metric = INSTR_TSQL_CLOSE_CURSOR;
				}
				break;

			case T_FetchStmt:
				{
					FetchStmt  *stmt = (FetchStmt *) parsetree;

					metric = (stmt->ismove) ? INSTR_TSQL_MOVE_CURSOR : INSTR_TSQL_FETCH_CURSOR;
				}
				break;

			case T_CreateDomainStmt:
				metric = INSTR_TSQL_CREATE_DOMAIN;
				break;

			case T_CreateSchemaStmt:
				metric = INSTR_TSQL_CREATE_SCHEMA;
				break;

			case T_CreateStmt:
				if (((CreateStmt *) parsetree)->if_not_exists)
				{
					metric = INSTR_TSQL_CREATE_TABLE_IF_NOT_EXISTS;
				}
				else
				{
					metric = INSTR_TSQL_CREATE_TABLE;
				}
				break;

			case T_CreateTableSpaceStmt:
				metric = INSTR_TSQL_CREATE_TABLESPACE;
				break;

			case T_DropTableSpaceStmt:
				metric = INSTR_TSQL_DROP_TABLESPACE;
				break;

			case T_AlterTableSpaceOptionsStmt:
				metric = INSTR_TSQL_ALTER_TABLESPACE;
				break;

			case T_CreateExtensionStmt:
				metric = INSTR_TSQL_CREATE_EXTENSION;
				break;

			case T_AlterExtensionStmt:
				metric = INSTR_TSQL_ALTER_EXTENSION;
				break;

			case T_AlterExtensionContentsStmt:
				metric = INSTR_TSQL_ALTER_EXTENSION_CONTENTS_STMT;
				break;

			case T_CreateFdwStmt:
				metric = INSTR_TSQL_CREATE_FOREIGN_DATA_WRAPPER;
				break;

			case T_AlterFdwStmt:
				metric = INSTR_TSQL_ALTER_FOREIGN_DATA_WRAPPER;
				break;

			case T_CreateForeignServerStmt:
				metric = INSTR_TSQL_CREATE_SERVER;
				break;

			case T_AlterForeignServerStmt:
				metric = INSTR_TSQL_ALTER_SERVER;
				break;

			case T_CreateUserMappingStmt:
				metric = INSTR_TSQL_CREATE_USER_MAPPING;
				break;

			case T_AlterUserMappingStmt:
				metric = INSTR_TSQL_ALTER_USER_MAPPING;
				break;

			case T_DropUserMappingStmt:
				metric = INSTR_TSQL_DROP_USER_MAPPING;
				break;

			case T_CreateForeignTableStmt:
				metric = INSTR_TSQL_CREATE_FOREIGN_TABLE;
				break;

			case T_ImportForeignSchemaStmt:
				metric = INSTR_TSQL_IMPORT_FOREIGN_SCHEMA;
				break;

			case T_DropStmt:
				switch (((DropStmt *) parsetree)->removeType)
				{
					case OBJECT_TABLE:
						metric = INSTR_TSQL_DROP_TABLE;
						break;
					case OBJECT_SEQUENCE:
						metric = INSTR_TSQL_DROP_SEQUENCE;
						break;
					case OBJECT_VIEW:
						metric = INSTR_TSQL_DROP_VIEW;
						break;
					case OBJECT_MATVIEW:
						metric = INSTR_TSQL_DROP_MATERIALIZED_VIEW;
						break;
					case OBJECT_INDEX:
						metric = INSTR_TSQL_DROP_INDEX;
						break;
					case OBJECT_TYPE:
						metric = INSTR_TSQL_DROP_TYPE;
						break;
					case OBJECT_DOMAIN:
						metric = INSTR_TSQL_DROP_DOMAIN;
						break;
					case OBJECT_COLLATION:
						metric = INSTR_TSQL_DROP_COLLATION;
						break;
					case OBJECT_CONVERSION:
						metric = INSTR_TSQL_DROP_CONVERSION;
						break;
					case OBJECT_SCHEMA:
						metric = INSTR_TSQL_DROP_SCHEMA;
						break;
					case OBJECT_TSPARSER:
						metric = INSTR_TSQL_DROP_TEXT_SEARCH_PARSER;
						break;
					case OBJECT_TSDICTIONARY:
						metric = INSTR_TSQL_DROP_TEXT_SEARCH_DICTIONARY;
						break;
					case OBJECT_TSTEMPLATE:
						metric = INSTR_TSQL_DROP_TEXT_SEARCH_TEMPLATE;
						break;
					case OBJECT_TSCONFIGURATION:
						metric = INSTR_TSQL_DROP_TEXT_SEARCH_CONFIGURATION;
						break;
					case OBJECT_FOREIGN_TABLE:
						metric = INSTR_TSQL_DROP_FOREIGN_TABLE;
						break;
					case OBJECT_EXTENSION:
						metric = INSTR_TSQL_DROP_EXTENSION;
						break;
					case OBJECT_FUNCTION:
						metric = INSTR_TSQL_DROP_FUNCTION;
						break;
					case OBJECT_PROCEDURE:
						metric = INSTR_TSQL_DROP_PROCEDURE;
						break;
					case OBJECT_ROUTINE:
						metric = INSTR_TSQL_DROP_ROUTINE;
						break;
					case OBJECT_AGGREGATE:
						metric = INSTR_TSQL_DROP_AGGREGATE;
						break;
					case OBJECT_OPERATOR:
						metric = INSTR_TSQL_DROP_OPERATOR;
						break;
					case OBJECT_LANGUAGE:
						metric = INSTR_TSQL_DROP_LANGUAGE;
						break;
					case OBJECT_CAST:
						metric = INSTR_TSQL_DROP_CAST;
						break;
					case OBJECT_TRIGGER:
						metric = INSTR_TSQL_DROP_TRIGGER;
						break;
					case OBJECT_EVENT_TRIGGER:
						metric = INSTR_TSQL_DROP_EVENT_TRIGGER;
						break;
					case OBJECT_RULE:
						metric = INSTR_TSQL_DROP_RULE;
						break;
					case OBJECT_FDW:
						metric = INSTR_TSQL_DROP_FOREIGN_DATA_WRAPPER;
						break;
					case OBJECT_FOREIGN_SERVER:
						metric = INSTR_TSQL_DROP_SERVER;
						break;
					case OBJECT_OPCLASS:
						metric = INSTR_TSQL_DROP_OPERATOR_CLASS;
						break;
					case OBJECT_OPFAMILY:
						metric = INSTR_TSQL_DROP_OPERATOR_FAMILY;
						break;
					case OBJECT_POLICY:
						metric = INSTR_TSQL_DROP_POLICY;
						break;
					case OBJECT_TRANSFORM:
						metric = INSTR_TSQL_DROP_TRANSFORM;
						break;
					case OBJECT_ACCESS_METHOD:
						metric = INSTR_TSQL_DROP_ACCESS_METHOD;
						break;
					case OBJECT_PUBLICATION:
						metric = INSTR_TSQL_DROP_PUBLICATION;
						break;
					case OBJECT_STATISTIC_EXT:
						metric = INSTR_TSQL_DROP_STATISTICS;
						break;
					default:
						break;
				}
				break;

			case T_TruncateStmt:
				metric = INSTR_TSQL_TRUNCATE_TABLE;
				break;

			case T_CommentStmt:
				metric = INSTR_TSQL_COMMENT_STMT;
				break;

			case T_SecLabelStmt:
				metric = INSTR_TSQL_SECURITY_LABEL;
				break;

			case T_CopyStmt:
				metric = INSTR_TSQL_COPY_STMT;
				break;

			case T_RenameStmt:
				metric = INSTR_TSQL_RENAME_STMT;
				break;

			case T_AlterObjectDependsStmt:
				metric = INSTR_TSQL_ALTER_OBJECT_DEPENDS_STMT;
				break;

			case T_AlterObjectSchemaStmt:
				metric = INSTR_TSQL_ALTER_OBJECT_SCHEMA_STMT;
				break;

			case T_AlterOwnerStmt:
				metric = INSTR_TSQL_ALTER_OWNER_STMT;
				break;

			case T_AlterTableMoveAllStmt:
				metric = INSTR_TSQL_ALTER_TABLE_MOVE_ALL_STMT;
				break;

			case T_AlterTableStmt:
				metric = INSTR_TSQL_ALTER_TABLE_STMT;
				break;

			case T_AlterDomainStmt:
				metric = INSTR_TSQL_ALTER_DOMAIN;
				break;

			case T_AlterFunctionStmt:
				switch (((AlterFunctionStmt *) parsetree)->objtype)
				{
					case OBJECT_FUNCTION:
						metric = INSTR_TSQL_ALTER_FUNCTION;
						break;
					case OBJECT_PROCEDURE:
						metric = INSTR_TSQL_ALTER_PROCEDURE;
						break;
					case OBJECT_ROUTINE:
						metric = INSTR_TSQL_ALTER_ROUTINE;
						break;
					default:
						break;
				}
				break;

			case T_GrantStmt:
				{
					GrantStmt  *stmt = (GrantStmt *) parsetree;

					metric = (stmt->is_grant) ? INSTR_UNSUPPORTED_TSQL_GRANT_STMT : INSTR_UNSUPPORTED_TSQL_REVOKE_STMT;
				}
				break;

			case T_GrantRoleStmt:
				{
					GrantRoleStmt *stmt = (GrantRoleStmt *) parsetree;

					metric = (stmt->is_grant) ? INSTR_UNSUPPORTED_TSQL_GRANT_ROLE : INSTR_UNSUPPORTED_TSQL_REVOKE_ROLE;
				}
				break;

			case T_AlterDefaultPrivilegesStmt:
				metric = INSTR_TSQL_ALTER_DEFAULT_PRIVILEGES;
				break;

			case T_DefineStmt:
				switch (((DefineStmt *) parsetree)->kind)
				{
					case OBJECT_AGGREGATE:
						metric = INSTR_TSQL_CREATE_AGGREGATE;
						break;
					case OBJECT_OPERATOR:
						metric = INSTR_TSQL_CREATE_OPERATOR;
						break;
					case OBJECT_TYPE:
						metric = INSTR_TSQL_CREATE_TYPE;
						break;
					case OBJECT_TSPARSER:
						metric = INSTR_TSQL_CREATE_TEXT_SEARCH_PARSER;
						break;
					case OBJECT_TSDICTIONARY:
						metric = INSTR_TSQL_CREATE_TEXT_SEARCH_DICTIONARY;
						break;
					case OBJECT_TSTEMPLATE:
						metric = INSTR_TSQL_CREATE_TEXT_SEARCH_TEMPLATE;
						break;
					case OBJECT_TSCONFIGURATION:
						metric = INSTR_TSQL_CREATE_TEXT_SEARCH_CONFIGURATION;
						break;
					case OBJECT_COLLATION:
						metric = INSTR_TSQL_CREATE_COLLATION;
						break;
					case OBJECT_ACCESS_METHOD:
						metric = INSTR_TSQL_CREATE_ACCESS_METHOD;
						break;
					default:
						break;
				}
				break;

			case T_CompositeTypeStmt:
				metric = INSTR_TSQL_CREATE_COMPOSITE_TYPE;
				break;

			case T_CreateEnumStmt:
				metric = INSTR_TSQL_CREATE_ENUM_STMT;
				break;

			case T_CreateRangeStmt:
				metric = INSTR_TSQL_CREATE_RANGE_STMT;
				break;

			case T_AlterEnumStmt:
				metric = INSTR_TSQL_ALTER_ENUM;
				break;

			case T_ViewStmt:
				metric = INSTR_TSQL_CREATE_VIEW;
				break;

			case T_CreateFunctionStmt:
				if (((CreateFunctionStmt *) parsetree)->is_procedure)
					metric = INSTR_TSQL_CREATE_PROCEDURE;
				else
					metric = INSTR_TSQL_CREATE_FUNCTION;
				break;

			case T_IndexStmt:
				metric = INSTR_TSQL_CREATE_INDEX;
				break;

			case T_RuleStmt:
				metric = INSTR_TSQL_CREATE_RULE;
				break;

			case T_CreateSeqStmt:
				metric = INSTR_TSQL_CREATE_SEQUENCE;
				break;

			case T_AlterSeqStmt:
				metric = INSTR_TSQL_ALTER_SEQUENCE;
				break;

			case T_DoStmt:
				metric = INSTR_TSQL_DO_STMT;
				break;

			case T_CreatedbStmt:
				metric = INSTR_TSQL_CREATE_DATABASE;
				break;

			case T_AlterDatabaseStmt:
				metric = INSTR_UNSUPPORTED_TSQL_ALTER_DATABASE;
				break;

			case T_AlterDatabaseSetStmt:
				metric = INSTR_UNSUPPORTED_TSQL_ALTER_DATABASE;
				break;

			case T_DropdbStmt:
				metric = INSTR_TSQL_DROP_DATABASE;
				break;

			case T_NotifyStmt:
				metric = INSTR_TSQL_NOTIFY_STMT;
				break;

			case T_ListenStmt:
				metric = INSTR_TSQL_LISTEN_STMT;
				break;

			case T_UnlistenStmt:
				metric = INSTR_TSQL_UNLISTEN_STMT;
				break;

			case T_LoadStmt:
				metric = INSTR_TSQL_LOAD_STMT;
				break;

			case T_CallStmt:
				metric = INSTR_TSQL_CALL_STMT;
				break;

			case T_ClusterStmt:
				metric = INSTR_TSQL_CLUSTER_STMT;
				break;

			case T_VacuumStmt:
				if (((VacuumStmt *) parsetree)->is_vacuumcmd)
					metric = INSTR_TSQL_VACUUM_STMT;
				else
					metric = INSTR_TSQL_ANALYZE_STMT;
				break;

			case T_ExplainStmt:
				metric = INSTR_TSQL_EXPLAIN_STMT;
				break;

			case T_CreateTableAsStmt:
				switch (((CreateTableAsStmt *) parsetree)->objtype)
				{
					case OBJECT_TABLE:
						if (((CreateTableAsStmt *) parsetree)->is_select_into)
							metric = INSTR_TSQL_SELECT_INTO;
						else
							metric = INSTR_TSQL_CREATE_TABLE_AS;
						break;
					case OBJECT_MATVIEW:
						metric = INSTR_TSQL_CREATE_MATERIALIZED_VIEW;
						break;
					default:
						break;
				}
				break;

			case T_RefreshMatViewStmt:
				metric = INSTR_TSQL_REFRESH_MATERIALIZED_VIEW;
				break;

			case T_AlterSystemStmt:
				metric = INSTR_TSQL_ALTER_SYSTEM;
				break;

			case T_VariableSetStmt:
				switch (((VariableSetStmt *) parsetree)->kind)
				{
					case VAR_SET_VALUE:
					case VAR_SET_CURRENT:
					case VAR_SET_DEFAULT:
					case VAR_SET_MULTI:
						metric = INSTR_TSQL_SET;
						break;
					case VAR_RESET:
					case VAR_RESET_ALL:
						metric = INSTR_TSQL_RESET;
						break;
					default:
						break;
				}
				break;

			case T_VariableShowStmt:
				metric = INSTR_TSQL_VARIABLE_SHOW_STMT;
				break;

			case T_DiscardStmt:
				switch (((DiscardStmt *) parsetree)->target)
				{
					case DISCARD_ALL:
						metric = INSTR_TSQL_DISCARD_ALL;
						break;
					case DISCARD_PLANS:
						metric = INSTR_TSQL_DISCARD_PLANS;
						break;
					case DISCARD_TEMP:
						metric = INSTR_TSQL_DISCARD_TEMP;
						break;
					case DISCARD_SEQUENCES:
						metric = INSTR_TSQL_DISCARD_SEQUENCES;
						break;
				}
				break;

			case T_CreateTransformStmt:
				metric = INSTR_TSQL_CREATE_TRANSFORM;
				break;

			case T_CreateTrigStmt:
				metric = INSTR_TSQL_CREATE_TRIGGER;
				break;

			case T_CreateEventTrigStmt:
				metric = INSTR_TSQL_CREATE_EVENT_TRIGGER;
				break;

			case T_AlterEventTrigStmt:
				metric = INSTR_TSQL_ALTER_EVENT_TRIGGER;
				break;

			case T_CreatePLangStmt:
				metric = INSTR_TSQL_CREATE_LANGUAGE;
				break;

			case T_CreateRoleStmt:
				metric = INSTR_TSQL_CREATE_ROLE;
				break;

			case T_AlterRoleStmt:
				metric = INSTR_TSQL_ALTER_ROLE;
				break;

			case T_AlterRoleSetStmt:
				metric = INSTR_TSQL_ALTER_ROLE;
				break;

			case T_DropRoleStmt:
				metric = INSTR_TSQL_DROP_ROLE;
				break;

			case T_DropOwnedStmt:
				metric = INSTR_TSQL_DROP_OWNED;
				break;

			case T_ReassignOwnedStmt:
				metric = INSTR_TSQL_REASSIGN_OWNED;
				break;

			case T_LockStmt:
				metric = INSTR_TSQL_LOCK_TABLE;
				break;

			case T_ConstraintsSetStmt:
				metric = INSTR_TSQL_SET_CONSTRAINTS;
				break;

			case T_CheckPointStmt:
				metric = INSTR_TSQL_CHECKPOINT;
				break;

			case T_ReindexStmt:
				metric = INSTR_TSQL_REINDEX;
				break;

			case T_CreateConversionStmt:
				metric = INSTR_TSQL_CREATE_CONVERSION;
				break;

			case T_CreateCastStmt:
				metric = INSTR_TSQL_CREATE_CAST;
				break;

			case T_CreateOpClassStmt:
				metric = INSTR_TSQL_CREATE_OPERATOR_CLASS;
				break;

			case T_CreateOpFamilyStmt:
				metric = INSTR_TSQL_CREATE_OPERATOR_FAMILY;
				break;

			case T_AlterOpFamilyStmt:
				metric = INSTR_TSQL_ALTER_OPERATOR_FAMILY;
				break;

			case T_AlterOperatorStmt:
				metric = INSTR_TSQL_ALTER_OPERATOR;
				break;

			case T_AlterTSDictionaryStmt:
				metric = INSTR_TSQL_ALTER_TEXT_SEARCH_DICTIONARY;
				break;

			case T_AlterTSConfigurationStmt:
				metric = INSTR_TSQL_ALTER_TEXT_SEARCH_CONFIGURATION;
				break;

			case T_CreatePolicyStmt:
				metric = INSTR_TSQL_CREATE_POLICY;
				break;

			case T_AlterPolicyStmt:
				metric = INSTR_TSQL_ALTER_POLICY;
				break;

			case T_CreateAmStmt:
				metric = INSTR_TSQL_CREATE_ACCESS_METHOD;
				break;

			case T_CreatePublicationStmt:
				metric = INSTR_TSQL_CREATE_PUBLICATION;
				break;

			case T_AlterPublicationStmt:
				metric = INSTR_TSQL_ALTER_PUBLICATION;
				break;

			case T_CreateSubscriptionStmt:
				metric = INSTR_TSQL_CREATE_SUBSCRIPTION;
				break;

			case T_AlterSubscriptionStmt:
				metric = INSTR_TSQL_ALTER_SUBSCRIPTION;
				break;

			case T_DropSubscriptionStmt:
				metric = INSTR_TSQL_DROP_SUBSCRIPTION;
				break;

			case T_AlterCollationStmt:
				metric = INSTR_TSQL_ALTER_COLLATION;
				break;

			case T_PrepareStmt:
				metric = INSTR_TSQL_PREPARE;;
				break;

			case T_ExecuteStmt:
				metric = INSTR_TSQL_EXECUTE;
				break;

			case T_CreateStatsStmt:
				metric = INSTR_TSQL_CREATE_STATISTICS;
				break;

			case T_DeallocateStmt:
				{
					DeallocateStmt *stmt = (DeallocateStmt *) parsetree;

					if (stmt->name == NULL)
						metric = INSTR_TSQL_DEALLOCATE_ALL;
					else
						metric = INSTR_TSQL_DEALLOCATE;
				}
				break;

				/* already-planned queries */
			case T_PlannedStmt:
				{
					PlannedStmt *stmt = (PlannedStmt *) parsetree;

					switch (stmt->commandType)
					{
						case CMD_SELECT:

							/*
							 * We take a little extra care here so that the result
							 * will be useful for complaints about read-only
							 * statements
							 */
							if (stmt->rowMarks != NIL)
							{
								/* not 100% but probably close enough */
								switch (((PlanRowMark *) linitial(stmt->rowMarks))->strength)
								{
									case LCS_FORKEYSHARE:
										metric = INSTR_TSQL_SELECT_FOR_KEY_SHARE;
										break;
									case LCS_FORSHARE:
										metric = INSTR_TSQL_SELECT_FOR_SHARE;
										break;
									case LCS_FORNOKEYUPDATE:
										metric = INSTR_TSQL_SELECT_FOR_SHARE;
										break;
									case LCS_FORUPDATE:
										metric = INSTR_TSQL_SELECT_FOR_UPDATE;
										break;
									default:
										metric = INSTR_TSQL_SELECT_STMT;
										break;
								}
							}
							else
								metric = INSTR_TSQL_SELECT_STMT;
							break;
						case CMD_UPDATE:
							metric = INSTR_TSQL_UPDATE_STMT;
							break;
						case CMD_INSERT:
							metric = INSTR_TSQL_INSERT_STMT;
							break;
						case CMD_DELETE:
							metric = INSTR_TSQL_DELETE_STMT;
							break;
						case CMD_UTILITY:
						default:
							break;
					}
				}
				break;

				/* parsed-and-rewritten-but-not-planned queries */
			case T_Query:
				{
					Query	   *stmt = (Query *) parsetree;

					switch (stmt->commandType)
					{
						case CMD_SELECT:

							/*
							 * We take a little extra care here so that the result
							 * will be useful for complaints about read-only
							 * statements
							 */
							if (stmt->rowMarks != NIL)
							{
								/* not 100% but probably close enough */
								switch (((RowMarkClause *) linitial(stmt->rowMarks))->strength)
								{
									case LCS_FORKEYSHARE:
										metric = INSTR_TSQL_SELECT_FOR_KEY_SHARE;
										break;
									case LCS_FORSHARE:
										metric = INSTR_TSQL_SELECT_FOR_SHARE;
										break;
									case LCS_FORNOKEYUPDATE:
										metric = INSTR_TSQL_SELECT_FOR_NO_KEY_UPDATE;
										break;
									case LCS_FORUPDATE:
										metric = INSTR_TSQL_SELECT_FOR_UPDATE;
										break;
									default:
										break;
								}
							}
							else
								metric = INSTR_TSQL_SELECT_STMT;
							break;
						case CMD_UPDATE:
							metric = INSTR_TSQL_UPDATE_STMT;
							break;
						case CMD_INSERT:
							metric = INSTR_TSQL_INSERT_STMT;
							break;
						case CMD_DELETE:
							metric = INSTR_TSQL_DELETE_STMT;
							break;
						case CMD_UTILITY:
							break;
						default:
							break;
					}
				}
				break;

			default:
				break;
		}
		if (metric != -1)
			TSQLInstrumentation(metric);
	}
}

/*
 * When the PL/TSQL parser expects to see a SQL statement, it is very
 * liberal in what it accepts; for example, we often assume an
 * unrecognized keyword is the beginning of a SQL statement. This
 * avoids the need to duplicate parts of the SQL grammar in the
 * PL/TSQL grammar, but it means we can accept wildly malformed
 * input. To try and catch some of the more obviously invalid input,
 * we run the strings we expect to be SQL statements through the main
 * SQL parser.
 *
 * We only invoke the raw parser (not the analyzer); this doesn't do
 * any database access and does not check any semantic rules, it just
 * checks for basic syntactic correctness. We do this here, rather
 * than after parsing has finished, because a malformed SQL statement
 * may cause the PL/TSQL parser to become confused about statement
 * borders. So it is best to bail out as early as we can.
 *
 * It is assumed that "stmt" represents a copy of the function source text
 * beginning at offset "location", with leader text of length "leaderlen"
 * (typically "SELECT ") prefixed to the source text.  We use this assumption
 * to transpose any error cursor position back to the function source text.
 * If no error cursor is provided, we'll just point at "location".
 */
static void
check_sql_expr(const char *stmt, int location, int leaderlen)
{
	sql_error_callback_arg cbarg;
	ErrorContextCallback  syntax_errcontext;
	MemoryContext oldCxt;

	if (!pltsql_check_syntax)
		return;

	cbarg.location = location;
	cbarg.leaderlen = leaderlen;

	syntax_errcontext.callback = pltsql_sql_error_callback;
	syntax_errcontext.arg = &cbarg;
	syntax_errcontext.previous = error_context_stack;
	error_context_stack = &syntax_errcontext;

	oldCxt = MemoryContextSwitchTo(pltsql_compile_tmp_cxt);

	IncrementInstr(raw_parser(stmt, RAW_PARSE_DEFAULT));

	MemoryContextSwitchTo(oldCxt);

	/* Restore former ereport callback */
	error_context_stack = syntax_errcontext.previous;
}

static void
pltsql_sql_error_callback(void *arg)
{
	sql_error_callback_arg *cbarg = (sql_error_callback_arg *) arg;
	int			errpos;

	/*
	 * First, set up internalerrposition to point to the start of the
	 * statement text within the function text.  Note this converts
	 * location (a byte offset) to a character number.
	 */
	parser_errposition(cbarg->location);

	/*
	 * If the core parser provided an error position, transpose it.
	 * Note we are dealing with 1-based character numbers at this point.
	 */
	errpos = geterrposition();
	if (errpos > cbarg->leaderlen)
	{
		int		myerrpos = getinternalerrposition();

		if (myerrpos > 0)		/* safety check */
			internalerrposition(myerrpos + errpos - cbarg->leaderlen - 1);
	}

	/* In any case, flush errposition --- we want internalerrpos only */
	errposition(0);
}

/*
 * Parse a SQL datatype name and produce a PLtsql_type structure.
 *
 * The heavy lifting is done elsewhere.  Here we are only concerned
 * with setting up an errcontext link that will let us give an error
 * cursor pointing into the pltsql function source, if necessary.
 * This is handled the same as in check_sql_expr(), and we likewise
 * expect that the given string is a copy from the source text.
 */
PLtsql_type *
parse_datatype(const char *string, int location)
{
	TypeName   *typeName;
	Oid			type_id;
	int32		typmod;
	sql_error_callback_arg cbarg;
	ErrorContextCallback  syntax_errcontext;

	cbarg.location = location;
	cbarg.leaderlen = 0;

	syntax_errcontext.callback = pltsql_sql_error_callback;
	syntax_errcontext.arg = &cbarg;
	syntax_errcontext.previous = error_context_stack;
	error_context_stack = &syntax_errcontext;

	/*
	 * If the datatype is TABLE without a pre-defined table type, we save the
	 * column definition list and use it to create the underlying table of a
	 * table variable in exec_stmt_decl_table.
	 */
	if (pg_strncasecmp(string, "table", 5) == 0 &&
		(scanner_isspace(string[5]) || string[5] == '('))
	{
		/* Restore former ereport callback */
		error_context_stack = syntax_errcontext.previous;

		/* Build a simple table datatype */
		return pltsql_build_table_datatype_coldef(&string[5]);
	}

	/* Let the main parser try to parse it under standard SQL rules */
	typeName = typeStringToTypeName(string);
	rewrite_plain_name(typeName->names);
	typenameTypeIdAndMod(NULL, typeName, &type_id, &typmod);

	/* Restore former ereport callback */
	error_context_stack = syntax_errcontext.previous;

	/* Okay, build a PLtsql_type data structure for it */
	return pltsql_build_datatype(type_id, typmod,
								 pltsql_curr_compile->fn_input_collation,
								 typeName);
}

/*
 * Check block starting and ending labels match.
 */
static void
check_labels(const char *start_label, const char *end_label, int end_location)
{
	if (end_label)
	{
		if (!start_label)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("end label \"%s\" specified for unlabelled block",
							end_label),
					 parser_errposition(end_location)));

		if (strcmp(start_label, end_label) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("end label \"%s\" differs from block's label \"%s\"",
							end_label, start_label),
					 parser_errposition(end_location)));
	}
}

/*
 * Read the arguments (if any) for a cursor, followed by the until token
 *
 * If cursor has no args, just swallow the until token and return NULL.
 * If it does have args, we expect to see "( arg [, arg ...] )" followed
 * by the until token, where arg may be a plain expression, or a named
 * parameter assignment of the form argname := expr. Consume all that and
 * return a SELECT query that evaluates the expression(s) (without the outer
 * parens).
 */
static PLtsql_expr *
read_cursor_args(PLtsql_var *cursor, int until, const char *expected)
{
	PLtsql_expr *expr;
	PLtsql_row *row;
	int			tok;
	int			argc;
	char	  **argv;
	StringInfoData ds;
	char	   *sqlstart = "SELECT ";
	bool		any_named = false;

	tok = yylex();
	if (cursor->cursor_explicit_argrow < 0)
	{
		/* No arguments expected */
		if (tok == '(')
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("cursor \"%s\" has no arguments",
							cursor->refname),
					 parser_errposition(yylloc)));

		if (tok != until)
			yyerror("syntax error");

		return NULL;
	}

	/* Else better provide arguments */
	if (tok != '(')
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("cursor \"%s\" has arguments",
						cursor->refname),
				 parser_errposition(yylloc)));

	/*
	 * Read the arguments, one by one.
	 */
	row = (PLtsql_row *) pltsql_Datums[cursor->cursor_explicit_argrow];
	argv = (char **) palloc0(row->nfields * sizeof(char *));

	for (argc = 0; argc < row->nfields; argc++)
	{
		PLtsql_expr *item;
		int		endtoken;
		int		argpos;
		int		tok1,
			tok2;
		int		arglocation;

		/* Check if it's a named parameter: "param := value" */
		pltsql_peek2(&tok1, &tok2, &arglocation, NULL);
		if (tok1 == IDENT && tok2 == COLON_EQUALS)
		{
			char   *argname;
			IdentifierLookup save_IdentifierLookup;

			/* Read the argument name, ignoring any matching variable */
			save_IdentifierLookup = pltsql_IdentifierLookup;
			pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_DECLARE;
			yylex();
			argname = yylval.str;
			pltsql_IdentifierLookup = save_IdentifierLookup;

			/* Match argument name to cursor arguments */
			for (argpos = 0; argpos < row->nfields; argpos++)
			{
				if (strcmp(row->fieldnames[argpos], argname) == 0)
					break;
			}
			if (argpos == row->nfields)
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("cursor \"%s\" has no argument named \"%s\"",
								cursor->refname, argname),
						 parser_errposition(yylloc)));

			/*
			 * Eat the ":=". We already peeked, so the error should never
			 * happen.
			 */
			tok2 = yylex();
			if (tok2 != COLON_EQUALS)
				yyerror("syntax error");

			any_named = true;
		}
		else
			argpos = argc;

		if (argv[argpos] != NULL)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("duplicate value for cursor \"%s\" parameter \"%s\"",
							cursor->refname, row->fieldnames[argpos]),
					 parser_errposition(arglocation)));

		/*
		 * Read the value expression. To provide the user with meaningful
		 * parse error positions, we check the syntax immediately, instead of
		 * checking the final expression that may have the arguments
		 * reordered. Trailing whitespace must not be trimmed, because
		 * otherwise input of the form (param -- comment\n, param) would be
		 * translated into a form where the second parameter is commented
		 * out.
		 */
		item = read_sql_construct(',', ')', 0,
								  ",\" or \")",
								  sqlstart,
								  true, true,
								  false, /* do not trim */
								  NULL, &endtoken);

		argv[argpos] = item->query + strlen(sqlstart);

		if (endtoken == ')' && !(argc == row->nfields - 1))
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("not enough arguments for cursor \"%s\"",
							cursor->refname),
					 parser_errposition(yylloc)));

		if (endtoken == ',' && (argc == row->nfields - 1))
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("too many arguments for cursor \"%s\"",
							cursor->refname),
					 parser_errposition(yylloc)));
	}

	/* Make positional argument list */
	initStringInfo(&ds);
	appendStringInfoString(&ds, sqlstart);
	for (argc = 0; argc < row->nfields; argc++)
	{
		Assert(argv[argc] != NULL);

		/*
		 * Because named notation allows permutated argument lists, include
		 * the parameter name for meaningful runtime errors.
		 */
		appendStringInfoString(&ds, argv[argc]);
		if (any_named)
			appendStringInfo(&ds, " AS %s",
							 quote_identifier(row->fieldnames[argc]));
		if (argc < row->nfields - 1)
			appendStringInfoString(&ds, ", ");
	}
	appendStringInfoChar(&ds, ';');

	expr = palloc0(sizeof(PLtsql_expr));
#if 0
	expr->dtype			= PLTSQL_DTYPE_EXPR;
#endif
	expr->query			= pstrdup(ds.data);
	expr->plan			= NULL;
	expr->paramnos		= NULL;
	expr->rwparam		= -1;
	expr->ns            = pltsql_ns_top();
	pfree(ds.data);

	/* Next we'd better find the until token */
	tok = yylex();
	if (tok != until)
		yyerror("syntax error");

	return expr;
}

static int
read_tsql_extended_cursor_options(void)
{
	int tok;
	int extended_cursor_options = 0;

	/* [ GLOBAL | LOCAL ] */
	tok = yylex();
	if (tok_is_keyword(tok, &yylval, K_GLOBAL, "global"))
	{
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
			 errmsg("GLOBAL CURSOR is not supported yet"),
			 parser_errposition(yylloc)));
	}
	else if (tok_is_keyword(tok, &yylval, K_LOCAL, "local"))
	{
		extended_cursor_options |= TSQL_CURSOR_OPT_LOCAL;
	}
	else
	{
		pltsql_push_back_token(tok);
	}

	/* [ FORWARD_ONLY | SCROLL ] */
	tok = yylex();
	if (tok_is_keyword(tok, &yylval, K_FORWARD_ONLY, "forward_only"))
	{
		/* just mark TSQL_CURSOR_OPT_FORWARD_ONLY to indicate query explicitly specifies the option */
		extended_cursor_options |= (CURSOR_OPT_NO_SCROLL | TSQL_CURSOR_OPT_FORWARD_ONLY);
	}
	else if (tok_is_keyword(tok, &yylval, K_SCROLL, "scroll"))
	{
		/* just mark TSQL_CURSOR_OPT_SCROLL to indicate query explicitly specifies the option */
		extended_cursor_options |= (CURSOR_OPT_SCROLL | TSQL_CURSOR_OPT_SCROLL);
	}
	else
	{
		pltsql_push_back_token(tok);
	}

	/* [ STATIC | KEYSET | DYNAMIC | FAST_FORWARD ] */
	tok = yylex();
	if (tok_is_keyword(tok, &yylval, K_STATIC, "static"))
	{
		/*
		 * STATIC is equivalent to INSENSITIVE which is default PG cursor option.
		 * just mark K_STATIC to indicate query explicitly specifies that option.
		 */
		extended_cursor_options |= K_STATIC;
	}
	else if (tok_is_keyword(tok, &yylval, K_KEYSET, "keyset"))
	{
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
			 errmsg("KEYSET CURSOR is not supported"),
			 parser_errposition(yylloc)));
	}
	else if (tok_is_keyword(tok, &yylval, K_DYNAMIC, "dynamic"))
	{
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
			 errmsg("DYNAMIC CURSOR is not supported"),
			 parser_errposition(yylloc)));
	}
	else if (tok_is_keyword(tok, &yylval, K_FAST_FORWARD, "fast_forward"))
	{
		if ((extended_cursor_options & TSQL_CURSOR_OPT_SCROLL) != 0)
		{
			ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("cannot specify both FAST_FORWARD and SCROLL"),
				 parser_errposition(yylloc)));
		}

		/* FAST_FORWARD specifies FORWARD_ONLY and READ_ONLY) */
		extended_cursor_options |= (CURSOR_OPT_NO_SCROLL | TSQL_CURSOR_OPT_FORWARD_ONLY | TSQL_CURSOR_OPT_READ_ONLY);
	}
	else
	{
		pltsql_push_back_token(tok);
	}

	/* [ READ_ONLY | SCROLL_LOCKS | OPTIMISTIC ] */
	tok = yylex();
	if (tok_is_keyword(tok, &yylval, K_READ_ONLY, "read_only"))
	{
		/*
		 * TODO:
		 * All the PG curosr is updatable. As READ_ONLY is one of commonly used options,
		 * let babel allow and ignore it. We may need to throw an error if the update/delete
		 * statement is running with 'where current of' clause.
		 */
		extended_cursor_options |= TSQL_CURSOR_OPT_READ_ONLY;
	}
	else if (tok_is_keyword(tok, &yylval, K_SCROLL_LOCKS, "scroll_locks"))
	{
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
			 errmsg("SCROLL LOCKS is not supported"),
			 parser_errposition(yylloc)));
	}
	else if (tok_is_keyword(tok, &yylval, K_OPTIMISTIC, "optimistic"))
	{
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
			 errmsg("OPTIMISTIC is not supported"),
			 parser_errposition(yylloc)));
	}
	else
	{
		pltsql_push_back_token(tok);
	}

	return extended_cursor_options;
}

/*
 * Parse RAISE ... USING options
 */
static List *
read_raise_options(void)
{
	List	   *result = NIL;

	for (;;)
	{
		PLtsql_raise_option *opt;
		int		tok;

		if ((tok = yylex()) == 0)
			yyerror("unexpected end of function definition");

		opt = (PLtsql_raise_option *) palloc(sizeof(PLtsql_raise_option));

		if (tok_is_keyword(tok, &yylval,
						   K_ERRCODE, "errcode"))
			opt->opt_type = PLTSQL_RAISEOPTION_ERRCODE;
		else if (tok_is_keyword(tok, &yylval,
								K_MESSAGE, "message"))
			opt->opt_type = PLTSQL_RAISEOPTION_MESSAGE;
		else if (tok_is_keyword(tok, &yylval,
								K_DETAIL, "detail"))
			opt->opt_type = PLTSQL_RAISEOPTION_DETAIL;
		else if (tok_is_keyword(tok, &yylval,
								K_HINT, "hint"))
			opt->opt_type = PLTSQL_RAISEOPTION_HINT;
		else
			yyerror("unrecognized RAISE statement option");

		tok = yylex();
		if (tok != '=' && tok != COLON_EQUALS)
			yyerror("syntax error, expected \"=\"");

		opt->expr = read_sql_expression2(',', ';', ", or ;", &tok);

		result = lappend(result, opt);

		if (tok == ';')
			break;
	}

	return result;
}

/*
 * Parse and read the parameter value in sp_executesql statement.
 * The parameter can either be a named param or an unamed one. Note that unnamed
 * parameters are supposed to appear ahead of named ones. Once there is a named
 * parameter, all the following parameters must be named. The flag argument is
 * to indicate whether the named param list has begun.
 */
static tsql_exec_param *
parse_sp_proc_param(int *endtoken, bool *flag)
{
	tsql_exec_param *p;
	YYSTYPE		lval;
	int		tok;
	int		term;

	p = palloc0(sizeof(tsql_exec_param));

	/* Initialize the param with the default setting */
	p->name = NULL;
	p->varno = -1;
	p->mode = FUNC_PARAM_IN;

	/* 
	 * Here it can be one of the following syntaxes.
	 * 1. @param = <expression> [OUT | OUTPUT] (named param)
	 * 2. <expression> [OUT | OUTPUT] (unnamed param)
	 * For IN param the expression can be value, variable, function call,
	 * etc. For OUT param the expression can only be a declared variable.
	 * Here we record the first token's value in case we need it later.
	 */
	tok = yylex();
	lval = pltsql_yylval;

	pltsql_push_back_token(tok);

	p->expr = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT, 
			       "comma or terminator", "SELECT ", 
			       true, true, true, NULL, &term,
			       true, NULL, false);

	/* 
	 * Named parameter 
	 */
	if (term == '=')
	{
		*flag = true;

		/* 
		 * Note that the name of a sp_executesql parameter can either be
		 * an undeclared brand-new name, or the same name as a
		 * declared/assigned variable, i.e. it can be a T_DATUM or
		 * a T_WORD.
		 * Now we know tok is the name of this parameter. Fetch the name
		 * string.
		 */
		if (tok == T_DATUM)
			p->name = NameOfDatum(&(lval.wdatum));
		else if (tok == T_WORD)
			p->name = lval.word.ident;
		else
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("invalid param name"),
					 parser_errposition(yylloc)));

		/* Again, record the next token after param name */
		tok = yylex();
		lval = pltsql_yylval;

		pltsql_push_back_token(tok);

		p->expr = read_sql_bos(',', ';', K_OUT, K_OUTPUT, 0,
				       "comma or terminator", "SELECT ",
					true, true, true, NULL, &term,
					true, NULL, false);
	}
	/* 
	 * Unamed parameter
	 * Expression has been read before IF statement, no other action needed
	 * except to check the flag. If flag = true, the last parameter is a
	 * named param and the current param should also be named.
	 */
	else if (*flag)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("after a named param is passed, all subsequent params must be named"),
				 parser_errposition(yylloc)));

	/*
	 * OUT param
	 */
	if (term == K_OUT || term == K_OUTPUT)
	{
		/*
		 * The expression for OUT param can only be a declared variable.
		 */
		if (tok != T_DATUM)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("invalid output param"),
					 parser_errposition(yylloc)));

		/*
		 * Check if the variable is assignable. We then record the
		 * variable's dno so that we can assign the return value back to
		 * it later.
		 */
		check_assignable(lval.wdatum.datum, yylloc);
		p->mode = FUNC_PARAM_INOUT;
		p->varno = ((PLtsql_var *) lval.wdatum.datum)->dno;
		term = yylex();

		/*
		 * Also need to check if there's any illegal token after OUT
		 * keyword (should only be comma or terminators).
		 * Note that we only push back a terminator if it's a bos. We
		 * don't want to push back a semicolon.
		 */
		if (term != ';' && is_terminator(term, false, yylloc, yylloc, NULL, NIL))
		{
			pltsql_push_back_token(term);
			*endtoken = term;
			return p;
		}
		else if (term != ',' && term != ';')
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("expecting a comma or terminator after OUT/OUTPUT keyword"),
					 parser_errposition(yylloc)));
	}

	*endtoken = term;
	return p;
}

static bool
word_matches_sp_proc(int tok)
{
	return word_matches(tok, "sp_cursor")
	    || word_matches(tok, "sp_cursoropen")
	    || word_matches(tok, "sp_cursorprepare")
	    || word_matches(tok, "sp_cursorexecute")
	    || word_matches(tok, "sp_cursorprepexec")
	    || word_matches(tok, "sp_cursorunprepare")
	    || word_matches(tok, "sp_cursorfetch")
	    || word_matches(tok, "sp_cursoroption")
	    || word_matches(tok, "sp_cursorclose")
	    || word_matches(tok, "sp_executesql")
		|| word_matches(tok, "sp_execute")
		|| word_matches(tok, "sp_prepexec");
}

static PLtsql_stmt *
parse_sp_proc(int tok, int lineno, int return_dno)
{
	int term;
	PLtsql_stmt_exec_sp *new_sp;
	StringInfoData buffer;

	new_sp = palloc0(sizeof(PLtsql_stmt_exec_sp));
	new_sp->cmd_type = PLTSQL_STMT_EXEC_SP;
	new_sp->lineno = lineno;
	new_sp->return_code_dno = return_dno;

	if (word_matches(tok, "sp_cursor"))
	{
		/* sp_cursor cursor, optype, rownum, table [ , value[...n]] */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSOR;

		/* cursor, */
		new_sp->handle = read_sql_expression2(',', ';', ", or ;", &term);

		/* , opttype */
		if (term != ',')
			ereport_syntax_error(yylloc, "invalid syntax");
		new_sp->opt1 = read_sql_expression2(',', ';', ", or ;", &term);

		/* , rownum */
		if (term != ',')
			ereport_syntax_error(yylloc, "invalid syntax");
		new_sp->opt2 = read_sql_expression2(',', ';', ", or ;", &term);

		/*, table */
		if (term != ',')
			ereport_syntax_error(yylloc, "invalid syntax");
		new_sp->opt3 = read_sql_expression2(',', ';', ", or ;", &term);

		/* [ , value[...n]] */
		initStringInfo(&buffer);
		while (term == ',')
		{
			parse_sp_cursor_value(&buffer, &term);
			new_sp->stropt = lappend(new_sp->stropt, pstrdup(buffer.data));
			resetStringInfo(&buffer);
		}
	}
	else if (word_matches(tok, "sp_cursoropen"))
	{
		/*
		 * sp_cursoropen cursor OUTPUT, stmt
		 * [, scrollopt [ OUTPUT ] [ , ccopt[ OUTPUT ]
		 * [ ,rowcount OUTPUT [ ,boundparam][,...n]]] ]]
		 */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSOROPEN;

		/* cursor OUTPUT */
		tok = yylex();
		if (tok != T_DATUM || yylval.wdatum.datum->dtype != PLTSQL_DTYPE_VAR)
			ereport_syntax_error(yylloc, "invalid cursor param");
		if (((PLtsql_var *) yylval.wdatum.datum)->datatype->typoid != INT4OID)
			ereport_syntax_error(yylloc, "invalid cursor param datatype");
		check_assignable(yylval.wdatum.datum, yylloc);
		new_sp->cursor_handleno = ((PLtsql_var *) yylval.wdatum.datum)->dno;

		tok = yylex();
		if (tok != K_OUT && tok != K_OUTPUT)
			ereport_syntax_error(yylloc, "cursor param is not specified as OUTPUT");

		/* , stmt */
		tok = yylex();
		if (tok != ',')
			ereport_syntax_error(yylloc, "invalid syntax");

		new_sp->query = read_sql_construct_bos(',', ';', 0, "comma or <stmt>",
		                 "SELECT ", true, true, true, NULL,
		                 &term, true, NULL, false);
		new_sp->paramno = 0;

		/* [, scrollopt [ OUTPUT ] */
		if (term == ',')
		{
			new_sp->opt1 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else
			term = 0;

		/* [, ccopt [ OUTPUT ] */
		if (term == ',')
		{
			new_sp->opt2 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else
			term = 0;

		/* TOOD: rowcount handling */
		/* TODO: parameter handling */
	}
	else if (word_matches(tok, "sp_cursorprepare"))
	{
		/*
		 * sp_cursorprepare prepared_handle OUTPUT, params , stmt , options
		 * [ , scrollopt[ , ccopt]]
		 */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSORPREPARE;

		/* prepare_handle OUTPUT */
		tok = yylex();
		if (tok != T_DATUM || yylval.wdatum.datum->dtype != PLTSQL_DTYPE_VAR)
			ereport_syntax_error(yylloc, "invalid prepared_handle param");
		if (((PLtsql_var *) yylval.wdatum.datum)->datatype->typoid != INT4OID)
			ereport_syntax_error(yylloc, "invalid prepared_handle param datatype");
		check_assignable(yylval.wdatum.datum, yylloc);
		new_sp->prepared_handleno = ((PLtsql_var *) yylval.wdatum.datum)->dno;

		tok = yylex();
		if (tok != K_OUT && tok != K_OUTPUT)
			ereport_syntax_error(yylloc, "prepared param is not specified as OUTPUT");

		/* TODO: param handling */
		tok = yylex();
		if (tok != ',')
			ereport_syntax_error(yylloc, "invalid syntax");
		read_sql_construct_bos(',', ';', 0, "comma or <stmt>", "SELECT ", true,
							   true, true, NULL, &term, true, NULL, false);

		/* stmt */
		if (tok != ',')
			ereport_syntax_error(yylloc, "invalid syntax");

		new_sp->query = read_sql_construct_bos(',', ';', 0, "comma or <stmt>",
		                 "SELECT ", true, true, true, NULL,
		                 &term, true, NULL, false);
		new_sp->paramno = 0;

		/* options */
		if (term != ',')
			ereport_syntax_error(yylloc, "invalid syntax");

		new_sp->opt3 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			              "comma or terminator", "SELECT ",
			              true, true, true, NULL, &term,
			              true, NULL, false);

		/* [, scrollopt [ OUTPUT ] */
		if (term == ',')
		{
			new_sp->opt1 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else
			term = 0;

		/* [, ccopt [ OUTPUT ] */
		if (term == ',')
		{
			new_sp->opt2 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else
			term = 0;
	}
	else if (word_matches(tok, "sp_cursorexecute"))
	{
		/*
		 * sp_cursorexecute prepared_handle, cursor OUTPUT
     * [ , scrollopt[ OUTPUT ] [ , ccopt[ OUTPUT ]
     * [ ,rowcount OUTPUT [ ,bound param][,...n]]]]]
		 */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSOREXECUTE;

		/* prepared_handle */
		new_sp->handle = read_sql_expression2(',', ';', ", or ;", &term);

		/* cursor OUTPUT */
		tok = yylex();
		if (tok != T_DATUM || yylval.wdatum.datum->dtype != PLTSQL_DTYPE_VAR)
			ereport_syntax_error(yylloc, "invalid cursor param");
		if (((PLtsql_var *) yylval.wdatum.datum)->datatype->typoid != INT4OID)
			ereport_syntax_error(yylloc, "invalid cursor param datatype");
		check_assignable(yylval.wdatum.datum, yylloc);
		new_sp->cursor_handleno = ((PLtsql_var *) yylval.wdatum.datum)->dno;

		tok = yylex();
		if (tok != K_OUT && tok != K_OUTPUT)
			ereport_syntax_error(yylloc, "cursor param is not specified as OUTPUT");

		/* [ , scrollopt[ OUTPUT ] */
		tok = yylex();
		if (tok == ',')
		{
			new_sp->opt1 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else {
			pltsql_push_back_token(tok);
			term = 0;
		}

		/* [, ccopt [ OUTPUT ] */
		if (term == ',')
		{
			new_sp->opt2 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else
			term = 0;

		/* TOOD: rowcount handling */
		/* TODO: parameter handling */
	}
	else if (word_matches(tok, "sp_cursorprepexec"))
	{
		/*
		 * sp_cursorprepexec prepared_handle OUTPUT , cursor OUTPUT , params , statement , options
		 * [ , scrollopt [ , ccopt [ , rowcount ] ] ]
		 * [, '@parameter_name[,...n ]']
		 */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSORPREPEXEC;

		/* prepared_handle OUTPUT */
		tok = yylex();
		if (tok != T_DATUM || yylval.wdatum.datum->dtype != PLTSQL_DTYPE_VAR)
			ereport_syntax_error(yylloc, "invalid prepared_handle param");
		if (((PLtsql_var *) yylval.wdatum.datum)->datatype->typoid != INT4OID)
			ereport_syntax_error(yylloc, "invalid prepared_handle param datatype");
		check_assignable(yylval.wdatum.datum, yylloc);
		new_sp->prepared_handleno = ((PLtsql_var *) yylval.wdatum.datum)->dno;

		tok = yylex();
		if (tok != K_OUT && tok != K_OUTPUT)
			ereport_syntax_error(yylloc, "prepared_handle param is not specified as OUTPUT");

		tok = yylex();
		if (tok != ',')
			ereport_syntax_error(yylloc, "invalid syntax");

		/* cursor OUTPUT */
		tok = yylex();
		if (tok != T_DATUM || yylval.wdatum.datum->dtype != PLTSQL_DTYPE_VAR)
			ereport_syntax_error(yylloc, "invalid cursor param");
		if (((PLtsql_var *) yylval.wdatum.datum)->datatype->typoid != INT4OID)
			ereport_syntax_error(yylloc, "invalid cursor param datatype");
		check_assignable(yylval.wdatum.datum, yylloc);
		new_sp->cursor_handleno = ((PLtsql_var *) yylval.wdatum.datum)->dno;

		tok = yylex();
		if (tok != K_OUT && tok != K_OUTPUT)
			ereport_syntax_error(yylloc, "cursor param is not specified as OUTPUT");

		/* TODO: param handling */
		tok = yylex();
		if (tok != ',')
			ereport_syntax_error(yylloc, "invalid syntax");
		read_sql_construct_bos(',', ';', 0, "comma or <stmt>", "SELECT ", true,
							   true, true, NULL, &term, true, NULL, false);

		/* stmt */
		if (tok != ',')
			ereport_syntax_error(yylloc, "invalid syntax");

		new_sp->query = read_sql_construct_bos(',', ';', 0, "comma or <stmt>",
		                 "SELECT ", true, true, true, NULL,
		                 &term, true, NULL, false);
		new_sp->paramno = 0;

		/* options */
		if (term != ',')
			ereport_syntax_error(yylloc, "invalid syntax");

		new_sp->opt3 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			              "comma or terminator", "SELECT ",
			              true, true, true, NULL, &term,
			              true, NULL, false);

		/* [, scrollopt [ OUTPUT ] */
		if (term == ',')
		{
			new_sp->opt1 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else
			term = 0;

		/* [, ccopt [ OUTPUT ] */
		if (term == ',')
		{
			new_sp->opt2 = read_sql_bos(',', ';', '=', K_OUT, K_OUTPUT,
			                "comma or terminator", "SELECT ",
			                true, true, true, NULL, &term,
			                true, NULL, false);
		}
		else
			term = 0;

		/* TOOD: rowcount handling */
		/* TODO: parameter handling */
	}
	else if (word_matches(tok, "sp_cursorunprepare"))
	{
		/* sp_cursorunprepare prepared_handle */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSORUNPREPARE;

		/* prepared_handle */
		new_sp->handle = read_sql_expression2(',', ';', ", or ;", &term);
	}
	else if (word_matches(tok, "sp_cursorfetch"))
	{
		/* sp_cursorfetch cursor [ , fetchtype [ , rownum [ , nrows ] ] ] */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSORFETCH;

		/* cursor */
		new_sp->handle = read_sql_expression2(',', ';', ", or ;", &term);

		/* [ , fetchtype */
		if (term == ',')
		{
			new_sp->opt1 = read_sql_expression2(',', ';', ", or ;", &term);
		}
		else
			term = 0;

		/* [ , rownum */
		if (term == ',')
		{
			new_sp->opt2 = read_sql_expression2(',', ';', ", or ;", &term);
		}
		else
			term = 0;

		/* [ , nrows ] ] ] */
		if (term == ',')
			new_sp->opt3 = read_sql_expression2(',', ';', ", or ;", &term);
		else
			term = 0;
	}
	else if (word_matches(tok, "sp_cursoroption"))
	{
		/* sp_cursoroption cursor, code, value */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSOROPTION;

		/* cursor */
		new_sp->handle = read_sql_expression2(',', ';', ", or ;", &term);

		/* , code */
		if (term != ',')
			ereport_syntax_error(yylloc, "invalid syntax");
		new_sp->opt1 = read_sql_expression2(',', ';', ", or ;", &term);

		/* , value */
		if (term != ',')
			ereport_syntax_error(yylloc, "invalid syntax");
		new_sp->opt2 = read_sql_expression2(',', ';', ", or ;", &term);
	}
	else if (word_matches(tok, "sp_cursorclose"))
	{
		/* sp_cursorclose cursor */
		new_sp->sp_type_code = PLTSQL_EXEC_SP_CURSORCLOSE;

		/* cursor */
		new_sp->handle = read_sql_expression2(',', ';', ", or ;", &term);
	}
	else if (word_matches(tok, "sp_executesql"))
	{
		/* sp_executesql batch [, param_def,  params] */
		int		term1;
		int		term2;
		bool 	flag = false;

		new_sp->sp_type_code = PLTSQL_EXEC_SP_EXECUTESQL;

		TSQLInstrumentation(INSTR_TSQL_SP_EXECUTESQL);
		new_sp->query = read_sql_construct_bos(',', ';', 0, "comma or <stmt>", 
											   "SELECT ", true, true, true, NULL,
											   &term1, true, NULL, false);
		new_sp->paramno = 0;

		/* Comma means there exist second and third parts */
		if (term1 == ',')
		{
			/* Second part -- parameter definition */
			new_sp->param_def = read_sql_construct_bos(',', ';', 0, 
								   "comma or <stmt>", 
								   "SELECT ", true,
								   true, true,
								   NULL, &term2,
								   true, NULL,
								   false);

			/* Error if there is only the second part */
			if (term2 != ',')
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("missing parameter value"),
						 parser_errposition(yylloc)));

			/* Third part -- parameter values */
			while (term2 == ',')
			{
				tsql_exec_param *p;
				p = parse_sp_proc_param(&term2, &flag);

				new_sp->params = lappend(new_sp->params, p);
				new_sp->paramno++;	
			}
		}
	}
	else if (word_matches(tok, "sp_execute"))
	{
		int		term1;
		bool	flag = false;

		new_sp->sp_type_code = PLTSQL_EXEC_SP_EXECUTE;
		new_sp->handle = read_sql_construct_bos(',', ';', 0, "comma or <stmt>", 
											   "SELECT ", true, true, true, NULL,
											   &term1, true, NULL, false);
		while (term1 == ',')
		{
			tsql_exec_param *p;
			p = parse_sp_proc_param(&term1, &flag);

			new_sp->params = lappend(new_sp->params, p);
			new_sp->paramno++;	
		}
	}
	else if (word_matches(tok, "sp_prepexec"))
	{
		int		term1;
		bool	flag = false;

		new_sp->sp_type_code = PLTSQL_EXEC_SP_PREPEXEC;

		tok = yylex();
		if (tok != T_DATUM || yylval.wdatum.datum->dtype != PLTSQL_DTYPE_VAR)
			ereport_syntax_error(yylloc, "invalid prepared_handle param");
		if (((PLtsql_var *) yylval.wdatum.datum)->datatype->typoid != INT4OID)
			ereport_syntax_error(yylloc, "invalid prepared_handle param datatype");
		check_assignable(yylval.wdatum.datum, yylloc);
		new_sp->prepared_handleno = ((PLtsql_var *) yylval.wdatum.datum)->dno;

		tok = yylex();
		if (tok != K_OUT && tok != K_OUTPUT)
			ereport_syntax_error(yylloc, "handle is not specified as OUTPUT");

		tok = yylex();
		if (tok != ',')
			ereport_syntax_error(yylloc, "invalid syntax");

		new_sp->param_def = read_sql_construct_bos(',', ';', 0, "comma or <stmt>", 
												  	"SELECT ", true, true, true,
							  						NULL, &term1, true, NULL, false);
		new_sp->query = read_sql_construct_bos(',', ';', 0, "comma or <stmt>", 
											   "SELECT ", true, true, true, NULL,
											   &term1, true, NULL, false);
		new_sp->paramno = 0;
		while (term1 == ',')
		{
			tsql_exec_param *p;
			p = parse_sp_proc_param(&term1, &flag);

			new_sp->params = lappend(new_sp->params, p);
			new_sp->paramno++;	
		}
	}
	else
	{
		Assert(0);
	}

	return (PLtsql_stmt *) new_sp;
}

static void
parse_sp_cursor_value(StringInfoData* pbuffer, int *pterm)
{
	/* Currently, we support @ColName = <sql_expressioin> only */
	int tok;
	char *colname;
	PLtsql_expr *expr;
	IdentifierLookup save_IdentifierLookup;

	save_IdentifierLookup = pltsql_IdentifierLookup;
	pltsql_IdentifierLookup = IDENTIFIER_LOOKUP_DECLARE;
	yylex();
	colname = yylval.str;
	if (strlen(colname) == 0 || colname[0] != '@') {
		/* not supported case yet */
		ereport_syntax_error(yylloc, "invalid syntax");
	}

	appendStringInfoString(pbuffer, colname);
	pltsql_IdentifierLookup = save_IdentifierLookup;

	tok = yylex();
	if (tok != '=')
		ereport_syntax_error(yylloc, "invalid syntax");
	appendStringInfoString(pbuffer, "=");

	expr = read_sql_expression2(',', ';', ", or ;", pterm);
	appendStringInfoString(pbuffer, expr->query+strlen("SELECT "));
}

static PLtsql_expr *
parse_select_stmt_for_decl_cursor()
{
	execsql_ctx ctx;
	PLword firstword;
	int paren_level = 0;
	int tok;

	tok = yylex();

	/* between FOR and <query>, T-SQL allows the arbitrary number of parenthesis */
	while (tok == '(')
	{
		++paren_level;
		tok = yylex();
	}

	/* in decl cursor, only select statment is allowed */
	if (word_matches(tok, "SELECT"))
	{
		firstword.ident = pltsql_yylval.word.ident;
		firstword.quoted = pltsql_yylval.word.quoted;
		init_execsql_ctx(&ctx, tok, pltsql_yylloc, &firstword);
		ctx.parenlevel = paren_level; // update parenlevel
		parse_and_build_select_expr(&ctx, NULL, NULL, NULL);
	}
	else if (word_matches(tok, "WITH") && paren_level == 0) /* interstingly, other than normal select, t-sql doesn't allow any parenthsis before with-clause */
	{
		PLtsql_expr *with_clauses;
		with_clauses = read_sql_construct_bos(';', 0, 0, ";", "WITH ", false, false, true, NULL, NULL, true, NULL, false);
		tok = yylex();
		firstword.ident = pltsql_yylval.word.ident;
		firstword.quoted = pltsql_yylval.word.quoted;

		if (word_matches(tok, "SELECT"))
		{
			init_execsql_ctx(&ctx, tok, pltsql_yylloc, &firstword);
			ctx.parenlevel = paren_level; // update parenlevel
			parse_and_build_select_expr(&ctx, with_clauses, NULL, NULL);
		}
		else
			yyerror("syntax error");
	}
	else
		yyerror("syntax error");

	/*
	 * As we increased the parenelevel outside of parse_and_build_select_expr,
	 * parser read all the parenthesis and it is already part of query string.
	 * manually erase them.
	 */
	if (paren_level > 0)
	{
		int pos = strlen(ctx.expr->query);
		for (; pos > 0 ; --pos)
		{
			if (ctx.expr->query[pos] == ')')
				--paren_level;
			if (paren_level == 0)
			{
				ctx.expr->query[pos] = '\0';
				break;
			}
		}
		Assert(pos > 0); /* should find the last ')' */
	}

	check_sql_expr(ctx.expr->query, ctx.location, 0);

	return ctx.expr;
}
