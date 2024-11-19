/*-------------------------------------------------------------------------
 *
 * pltsql.h		- Definitions for the PL/tsql
 *			  procedural language
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/pl/pltsql/src/pltsql.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef PLTSQL_H
#define PLTSQL_H

#include "postgres.h"
#include "access/xact.h"
#include "catalog/pg_collation.h"
#include "commands/defrem.h"
#include "parser/parse_func.h"
#include "commands/event_trigger.h"
#include "commands/sequence.h"
#include "commands/trigger.h"
#include "collation.h"
#include "executor/spi.h"
#include "optimizer/planner.h"
#include "utils/expandedrecord.h"
#include "utils/plancache.h"
#include "utils/portal.h"
#include "utils/typcache.h"
#include "tcop/utility.h"

#include "dynavec.h"
#include "dynastack.h"
#include "../../babelfishpg_common/src/babelfishpg_common.h"

/**********************************************************************
 * Definitions
 **********************************************************************/

/* define our text domain for translations */
#undef TEXTDOMAIN
#define TEXTDOMAIN PG_TEXTDOMAIN("pltsql")

#undef _
#define _(x) dgettext(TEXTDOMAIN, x)

#define PLTSQL_INSTR_ENABLED() \
       (pltsql_instr_plugin_ptr && (*pltsql_instr_plugin_ptr) && \
        (*pltsql_instr_plugin_ptr)->pltsql_instr_increment_metric)

#define TSQLInstrumentation(metric)                                                                                            \
({     if ((pltsql_instr_plugin_ptr && (*pltsql_instr_plugin_ptr) && (*pltsql_instr_plugin_ptr)->pltsql_instr_increment_metric))               \
               (*pltsql_instr_plugin_ptr)->pltsql_instr_increment_metric(metric);              \
})

#define TSQL_TXN_NAME_LIMIT 64	/* Transaction name limit */

/* Max number of Args allowed for Prepared stmts. */
#define PREPARE_STMT_MAX_ARGS 2100

#define TRIGGER_MAX_NEST_LEVEL 32 /* Maximum allowed trigger nesting level*/


/*
 * Compiler's namespace item types
 */
typedef enum PLtsql_nsitem_type
{
	PLTSQL_NSTYPE_LABEL,		/* block label */
	PLTSQL_NSTYPE_VAR,			/* scalar variable */
	PLTSQL_NSTYPE_REC,			/* composite variable */
	PLTSQL_NSTYPE_TBL			/* table variable */
} PLtsql_nsitem_type;

/*
 * A PLTSQL_NSTYPE_LABEL stack entry must be one of these types
 */
typedef enum PLtsql_label_type
{
	PLTSQL_LABEL_BLOCK,			/* DECLARE/BEGIN block */
	PLTSQL_LABEL_LOOP,			/* looping construct */
	PLTSQL_LABEL_OTHER			/* anything else */
} PLtsql_label_type;

/*
 * Datum array node types
 */
typedef enum PLtsql_datum_type
{
	PLTSQL_DTYPE_VAR,
	PLTSQL_DTYPE_ROW,
	PLTSQL_DTYPE_REC,
	PLTSQL_DTYPE_TBL,
	PLTSQL_DTYPE_RECFIELD,
	PLTSQL_DTYPE_ARRAYELEM,
	PLTSQL_DTYPE_PROMISE
} PLtsql_datum_type;

/*
 * DTYPE_PROMISE datums have these possible ways of computing the promise
 */
typedef enum PLtsql_promise_type
{
	PLTSQL_PROMISE_NONE = 0,	/* not a promise, or promise satisfied */
	PLTSQL_PROMISE_TG_NAME,
	PLTSQL_PROMISE_TG_WHEN,
	PLTSQL_PROMISE_TG_LEVEL,
	PLTSQL_PROMISE_TG_OP,
	PLTSQL_PROMISE_TG_RELID,
	PLTSQL_PROMISE_TG_TABLE_NAME,
	PLTSQL_PROMISE_TG_TABLE_SCHEMA,
	PLTSQL_PROMISE_TG_NARGS,
	PLTSQL_PROMISE_TG_ARGV,
	PLTSQL_PROMISE_TG_EVENT,
	PLTSQL_PROMISE_TG_TAG
} PLtsql_promise_type;


typedef enum PLtsql_dbcc_stmt_type
{
	PLTSQL_DBCC_CHECKIDENT
} PLtsql_dbcc_stmt_type;

/*
 * Variants distinguished in PLtsql_type structs
 */
typedef enum PLtsql_type_type
{
	PLTSQL_TTYPE_SCALAR,		/* scalar types and domains */
	PLTSQL_TTYPE_REC,			/* composite types, including RECORD */
	PLTSQL_TTYPE_PSEUDO,		/* pseudotypes */
	PLTSQL_TTYPE_TBL			/* table types */
} PLtsql_type_type;

/*
 * Execution tree node types
 */
typedef enum PLtsql_stmt_type
{
	PLTSQL_STMT_BLOCK,
	PLTSQL_STMT_ASSIGN,
	PLTSQL_STMT_IF,
	PLTSQL_STMT_CASE,			/* PLPGSQL */
	PLTSQL_STMT_LOOP,			/* PLPGSQL */
	PLTSQL_STMT_WHILE,
	PLTSQL_STMT_FORI,			/* PLPGSQL */
	PLTSQL_STMT_FORS,			/* PLPGSQL */
	PLTSQL_STMT_FORC,			/* PLPGSQL */
	PLTSQL_STMT_FOREACH_A,		/* PLPGSQL */
	PLTSQL_STMT_EXIT,
	PLTSQL_STMT_RETURN,
	PLTSQL_STMT_RETURN_NEXT,	/* PLPGSQL */
	PLTSQL_STMT_RETURN_QUERY,	/* PLPGSQL */
	PLTSQL_STMT_RAISE,			/* PLPGSQL */
	PLTSQL_STMT_ASSERT,			/* PLPGSQL */
	PLTSQL_STMT_EXECSQL,
	PLTSQL_STMT_DYNEXECUTE,		/* PLPGSQL */
	PLTSQL_STMT_DYNFORS,		/* PLPGSQL */
	PLTSQL_STMT_GETDIAG,		/* PLPGSQL */
	PLTSQL_STMT_OPEN,
	PLTSQL_STMT_FETCH,
	PLTSQL_STMT_CLOSE,
	PLTSQL_STMT_PERFORM,		/* PLPGSQL */
	PLTSQL_STMT_CALL,			/* PLPGSQL */
	PLTSQL_STMT_COMMIT,
	PLTSQL_STMT_ROLLBACK,
	PLTSQL_STMT_SET,			/* PLPGSQL */
	/* TSQL-only statement types follow */
	PLTSQL_STMT_GOTO,
	PLTSQL_STMT_PRINT,
	PLTSQL_STMT_INIT,
	PLTSQL_STMT_QUERY_SET,
	PLTSQL_STMT_TRY_CATCH,
	PLTSQL_STMT_PUSH_RESULT,
	PLTSQL_STMT_EXEC,
	PLTSQL_STMT_EXEC_BATCH,
	PLTSQL_STMT_EXEC_SP,
	PLTSQL_STMT_DECL_TABLE,
	PLTSQL_STMT_RETURN_TABLE,
	PLTSQL_STMT_DEALLOCATE,
	PLTSQL_STMT_DECL_CURSOR,
	PLTSQL_STMT_LABEL,
	PLTSQL_STMT_RAISERROR,
	PLTSQL_STMT_THROW,
	PLTSQL_STMT_USEDB,
	PLTSQL_STMT_SET_EXPLAIN_MODE,
	PLTSQL_STMT_KILL, 
	/* TSQL-only executable node */
	PLTSQL_STMT_SAVE_CTX,
	PLTSQL_STMT_RESTORE_CTX_FULL,
	PLTSQL_STMT_RESTORE_CTX_PARTIAL,
	PLTSQL_STMT_INSERT_BULK,
	PLTSQL_STMT_GRANTDB,
	PLTSQL_STMT_CHANGE_DBOWNER,
	PLTSQL_STMT_DBCC,
	PLTSQL_STMT_ALTER_DB,
	PLTSQL_STMT_FULLTEXTINDEX,
	PLTSQL_STMT_GRANTSCHEMA,
	PLTSQL_STMT_PARTITION_FUNCTION,
	PLTSQL_STMT_PARTITION_SCHEME
} PLtsql_stmt_type;

/*
 * Execution node return codes
 */
enum
{
	PLTSQL_RC_OK,
	PLTSQL_RC_EXIT,
	PLTSQL_RC_RETURN,
	PLTSQL_RC_CONTINUE
};

/*
 * GET DIAGNOSTICS information items
 */
typedef enum PLtsql_getdiag_kind
{
	PLTSQL_GETDIAG_ROW_COUNT,
	PLTSQL_GETDIAG_RESULT_OID,
	PLTSQL_GETDIAG_CONTEXT,
	PLTSQL_GETDIAG_ERROR_CONTEXT,
	PLTSQL_GETDIAG_ERROR_DETAIL,
	PLTSQL_GETDIAG_ERROR_HINT,
	PLTSQL_GETDIAG_RETURNED_SQLSTATE,
	PLTSQL_GETDIAG_COLUMN_NAME,
	PLTSQL_GETDIAG_CONSTRAINT_NAME,
	PLTSQL_GETDIAG_DATATYPE_NAME,
	PLTSQL_GETDIAG_MESSAGE_TEXT,
	PLTSQL_GETDIAG_TABLE_NAME,
	PLTSQL_GETDIAG_SCHEMA_NAME
} PLtsql_getdiag_kind;

/*
 * RAISE statement options
 */
typedef enum PLtsql_raise_option_type
{
	PLTSQL_RAISEOPTION_ERRCODE,
	PLTSQL_RAISEOPTION_MESSAGE,
	PLTSQL_RAISEOPTION_DETAIL,
	PLTSQL_RAISEOPTION_HINT,
	PLTSQL_RAISEOPTION_COLUMN,
	PLTSQL_RAISEOPTION_CONSTRAINT,
	PLTSQL_RAISEOPTION_DATATYPE,
	PLTSQL_RAISEOPTION_TABLE,
	PLTSQL_RAISEOPTION_SCHEMA
} PLtsql_raise_option_type;

/*
 * Behavioral modes for pltsql variable resolution
 */
typedef enum PLtsql_resolve_option
{
	PLTSQL_RESOLVE_ERROR,		/* throw error if ambiguous */
	PLTSQL_RESOLVE_VARIABLE,	/* prefer pltsql var to table column */
	PLTSQL_RESOLVE_COLUMN		/* prefer table column to pltsql var */
} PLtsql_resolve_option;

/*
 * Schema mapping for pltsql databases
 */
typedef enum PLtsql_schema_mapping
{
	PLTSQL_DB_SCHEMA,
	PLTSQL_DB,
	PLTSQL_SCHEMA
}			PLtsql_schema_mapping;

#define TSQL_TRIGGER_STARTED 0x1
#define TSQL_TRAN_STARTED 0x2

/**********************************************************************
 * Node and structure definitions
 **********************************************************************/

/*
 * Postgres data type
 */
typedef struct PLtsql_type
{
	char	   *typname;		/* (simple) name of the type */
	Oid			typoid;			/* OID of the data type */
	PLtsql_type_type ttype;		/* PLTSQL_TTYPE_ code */
	int16		typlen;			/* stuff copied from its pg_type entry */
	bool		typbyval;
	char		typtype;
	Oid			collation;		/* from pg_type, but can be overridden */
	bool		typisarray;		/* is "true" array, or domain over one */
	int32		atttypmod;		/* typmod (taken from someplace else) */

	/*
	 * This field is only used when a table variable does not have a
	 * pre-defined type, e.g. DECLARE @tableVar TABLE (a int, b int)
	 */
	char	   *coldef;

	/*
	 * Remaining fields are used only for named composite types (not RECORD)
	 * and table types
	 */
	TypeName   *origtypname;	/* type name as written by user */
	TypeCacheEntry *tcache;		/* typcache entry for composite type */
	uint64		tupdesc_id;		/* last-seen tupdesc identifier */
} PLtsql_type;

/*
 * SQL Query to plan and execute
 */
typedef struct PLtsql_expr
{
	char	   *query;
	SPIPlanPtr	plan;
	Bitmapset  *paramnos;		/* all dnos referenced by this query */
	int			rwparam;		/* dno of read/write param, or -1 if none */

	/* function containing this expr (not set until we first parse query) */
	struct PLtsql_function *func;

	/* namespace chain visible to this expr */
	struct PLtsql_nsitem *ns;

	/* fields for "simple expression" fast-path execution: */
	Expr	   *expr_simple_expr;	/* NULL means not a simple expr */
	int			expr_simple_generation; /* plancache generation we checked */
	Oid			expr_simple_type;	/* result type Oid, if simple */
	int32		expr_simple_typmod; /* result typmod, if simple */
	bool		expr_simple_mutable;	/* true if simple expr is mutable */

	/*
	 * if expr is simple AND prepared in current transaction,
	 * expr_simple_state and expr_simple_in_use are valid. Test validity by
	 * seeing if expr_simple_lxid matches current LXID.  (If not,
	 * expr_simple_state probably points at garbage!)
	 */
	ExprState  *expr_simple_state;	/* eval tree for expr_simple_expr */
	bool		expr_simple_in_use; /* true if eval tree is active */
	LocalTransactionId expr_simple_lxid;

	/* here for itvf? queries with all idents replaced with NULLs */
	char	   *itvf_query;
	/* make sure always set to NULL */
} PLtsql_expr;

/*
 * Generic datum array item
 *
 * PLtsql_datum is the common supertype for PLtsql_var, PLtsql_row,
 * PLtsql_rec, PLtsql_recfield, and PLtsql_arrayelem.
 */
typedef struct PLtsql_datum
{
	PLtsql_datum_type dtype;
	int			dno;
} PLtsql_datum;

/*
 * Scalar or composite variable
 *
 * The variants PLtsql_var, PLtsql_row, and PLtsql_rec share these
 * fields.
 */
typedef struct PLtsql_variable
{
	PLtsql_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLtsql_expr *default_val;
} PLtsql_variable;

/*
 * Scalar variable
 *
 * DTYPE_VAR and DTYPE_PROMISE datums both use this struct type.
 * A PROMISE datum works exactly like a VAR datum for most purposes,
 * but if it is read without having previously been assigned to, then
 * a special "promised" value is computed and assigned to the datum
 * before the read is performed.  This technique avoids the overhead of
 * computing the variable's value in cases where we expect that many
 * functions will never read it.
 */
typedef struct PLtsql_var
{
	PLtsql_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLtsql_expr *default_val;
	/* end of PLtsql_variable fields */

	PLtsql_type *datatype;

	/*
	 * Variables declared as CURSOR FOR <query> are mostly like ordinary
	 * scalar variables of type refcursor, but they have these additional
	 * properties:
	 */
	PLtsql_expr *cursor_explicit_expr;
	int			cursor_explicit_argrow;
	int			cursor_options;

	/* to identify if variable is getting used for babelfish GUC */
	bool is_babelfish_guc;

	/* Fields below here can change at runtime */

	Datum		value;
	bool		isnull;
	bool		freeval;

	/*
	 * The promise field records which "promised" value to assign if the
	 * promise must be honored.  If it's a normal variable, or the promise has
	 * been fulfilled, this is PLTSQL_PROMISE_NONE.
	 */
	PLtsql_promise_type promise;
} PLtsql_var;

/*
 * Row variable - this represents one or more variables that are listed in an
 * INTO clause, FOR-loop targetlist, cursor argument list, etc.  We also use
 * a row to represent a function's OUT parameters when there's more than one.
 *
 * Note that there's no way to name the row as such from PL/tsql code,
 * so many functions don't need to support these.
 *
 * That also means that there's no real name for the row variable, so we
 * conventionally set refname to "(unnamed row)".  We could leave it NULL,
 * but it's too convenient to be able to assume that refname is valid in
 * all variants of PLtsql_variable.
 *
 * isconst, notnull, and default_val are unsupported (and hence
 * always zero/null) for a row.  The member variables of a row should have
 * been checked to be writable at compile time, so isconst is correctly set
 * to false.  notnull and default_val aren't applicable.
 */
typedef struct PLtsql_row
{
	PLtsql_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLtsql_expr *default_val;
	/* end of PLtsql_variable fields */

	/*
	 * rowtupdesc is only set up if we might need to convert the row into a
	 * composite datum, which currently only happens for OUT parameters.
	 * Otherwise it is NULL.
	 */
	TupleDesc	rowtupdesc;

	int			nfields;
	char	  **fieldnames;
	int		   *varnos;
} PLtsql_row;

/*
 * Record variable (any composite type, including RECORD)
 */
typedef struct PLtsql_rec
{
	PLtsql_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLtsql_expr *default_val;
	/* end of PLtsql_variable fields */

	/*
	 * Note: for non-RECORD cases, we may from time to time re-look-up the
	 * composite type, using datatype->origtypname.  That can result in
	 * changing rectypeid.
	 */

	PLtsql_type *datatype;		/* can be NULL, if rectypeid is RECORDOID */
	Oid			rectypeid;		/* declared type of variable */
	/* RECFIELDs for this record are chained together for easy access */
	int			firstfield;		/* dno of first RECFIELD, or -1 if none */

	/* Fields below here can change at runtime */

	/* We always store record variables as "expanded" records */
	ExpandedRecordHeader *erh;
} PLtsql_rec;

/*
 * Table variable
 */
typedef struct PLtsql_tbl
{
	PLtsql_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLtsql_expr *default_val;
	/* end of PLtsql_variable fields */

	PLtsql_type *datatype;
	Oid			tbltypeid;		/* declared type of variable */
	char	   *tblname;		/* name of the underlying table */

	/*
	 * If a table variable is declared inside a function, then we need to drop
	 * its underlying table at the end of execution. If a table variable is
	 * passed in as a table-valued parameter, then we don't need to drop its
	 * underlying table - it's the caller's responsibility.
	 */
	bool		need_drop;
} PLtsql_tbl;

/*
 * Field in record
 */
typedef struct PLtsql_recfield
{
	PLtsql_datum_type dtype;
	int			dno;
	/* end of PLtsql_datum fields */

	char	   *fieldname;		/* name of field */
	int			recparentno;	/* dno of parent record */
	int			nextfield;		/* dno of next child, or -1 if none */
	uint64		rectupledescid; /* record's tupledesc ID as of last lookup */
	ExpandedRecordFieldInfo finfo;	/* field's attnum and type info */
	/* if rectupledescid == INVALID_TUPLEDESC_IDENTIFIER, finfo isn't valid */
} PLtsql_recfield;

/*
 * Element of array variable
 */
typedef struct PLtsql_arrayelem
{
	PLtsql_datum_type dtype;
	int			dno;
	/* end of PLtsql_datum fields */

	PLtsql_expr *subscript;
	int			arrayparentno;	/* dno of parent array variable */

	/* Remaining fields are cached info about the array variable's type */
	Oid			parenttypoid;	/* type of array variable; 0 if not yet set */
	int32		parenttypmod;	/* typmod of array variable */
	Oid			arraytypoid;	/* OID of actual array type */
	int32		arraytypmod;	/* typmod of array (and its elements too) */
	int16		arraytyplen;	/* typlen of array type */
	Oid			elemtypoid;		/* OID of array element type */
	int16		elemtyplen;		/* typlen of element type */
	bool		elemtypbyval;	/* element type is pass-by-value? */
	char		elemtypalign;	/* typalign of element type */
} PLtsql_arrayelem;

/*
 * Item in the compilers namespace tree
 */
typedef struct PLtsql_nsitem
{
	PLtsql_nsitem_type itemtype;

	/*
	 * For labels, itemno is a value of enum PLtsql_label_type. For other
	 * itemtypes, itemno is the associated PLtsql_datum's dno.
	 */
	int			itemno;
	struct PLtsql_nsitem *prev;
	char		name[FLEXIBLE_ARRAY_MEMBER];	/* nul-terminated string */
} PLtsql_nsitem;

typedef enum PLtsql_impl_txn_type
{
	PLTSQL_IMPL_TRAN_OFF,
	PLTSQL_IMPL_TRAN_ON,
	PLTSQL_IMPL_TRAN_START
} PLtsql_impl_txn_type;

/*
 * Generic execution node
 */
typedef struct PLtsql_stmt
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
} PLtsql_stmt;

/*
 * One EXCEPTION condition name
 */
typedef struct PLtsql_condition
{
	int			sqlerrstate;	/* SQLSTATE code */
	char	   *condname;		/* condition name (for debugging) */
	struct PLtsql_condition *next;
} PLtsql_condition;

/*
 * EXCEPTION block
 */
typedef struct PLtsql_exception_block
{
	int			sqlstate_varno;
	int			sqlerrm_varno;
	List	   *exc_list;		/* List of WHEN clauses */
} PLtsql_exception_block;

/*
 * One EXCEPTION ... WHEN clause
 */
typedef struct PLtsql_exception
{
	int			lineno;
	PLtsql_condition *conditions;
	List	   *action;			/* List of statements */
} PLtsql_exception;

/*
 * Block of statements
 */
typedef struct PLtsql_stmt_block
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	List	   *body;			/* List of statements */
	int			n_initvars;		/* Length of initvarnos[] */
	int		   *initvarnos;		/* dnos of variables declared in this block */
	PLtsql_exception_block *exceptions;
} PLtsql_stmt_block;

/*
 * Assign statement
 */
typedef struct PLtsql_stmt_assign
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	int			varno;
	PLtsql_expr *expr;
} PLtsql_stmt_assign;

/*
 * PERFORM statement
 */
typedef struct PLtsql_stmt_perform
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *expr;
} PLtsql_stmt_perform;

/*
 * CALL statement
 */
typedef struct PLtsql_stmt_call
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *expr;
	bool		is_call;
	PLtsql_variable *target;
} PLtsql_stmt_call;

/*
 * COMMIT statement
 */
typedef struct PLtsql_stmt_commit
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
} PLtsql_stmt_commit;

/*
 * ROLLBACK statement
 */
typedef struct PLtsql_stmt_rollback
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
} PLtsql_stmt_rollback;

/*
 * SET statement
 */
typedef struct PLtsql_stmt_set
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *expr;
} PLtsql_stmt_set;

/*
 * GET DIAGNOSTICS item
 */
typedef struct PLtsql_diag_item
{
	PLtsql_getdiag_kind kind;	/* id for diagnostic value desired */
	int			target;			/* where to assign it */
} PLtsql_diag_item;

/*
 * GET DIAGNOSTICS statement
 */
typedef struct PLtsql_stmt_getdiag
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	bool		is_stacked;		/* STACKED or CURRENT diagnostics area? */
	List	   *diag_items;		/* List of PLtsql_diag_item */
} PLtsql_stmt_getdiag;

/*
 * IF statement
 */
typedef struct PLtsql_stmt_if
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *cond;			/* boolean expression for THEN */
	PLtsql_stmt *then_body;		/* List of statements */
	List	   *elsif_list;		/* List of PLtsql_if_elsif structs */
	PLtsql_stmt *else_body;		/* List of statements */
} PLtsql_stmt_if;

/*
 * one ELSIF arm of IF statement
 */
typedef struct PLtsql_if_elsif
{
	int			lineno;
	PLtsql_expr *cond;			/* boolean expression for this case */
	List	   *stmts;			/* List of statements */
} PLtsql_if_elsif;

/*
 * CASE statement
 */
typedef struct PLtsql_stmt_case
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *t_expr;		/* test expression, or NULL if none */
	int			t_varno;		/* var to store test expression value into */
	List	   *case_when_list; /* List of PLtsql_case_when structs */
	bool		have_else;		/* flag needed because list could be empty */
	List	   *else_stmts;		/* List of statements */
} PLtsql_stmt_case;

/*
 * one arm of CASE statement
 */
typedef struct PLtsql_case_when
{
	int			lineno;
	PLtsql_expr *expr;			/* boolean expression for this case */
	List	   *stmts;			/* List of statements */
} PLtsql_case_when;

/*
 * Unconditional LOOP statement
 */
typedef struct PLtsql_stmt_loop
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	List	   *body;			/* List of statements */
} PLtsql_stmt_loop;

/*
 * WHILE cond LOOP statement
 */
typedef struct PLtsql_stmt_while
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	PLtsql_expr *cond;
	List	   *body;			/* List of statements */
} PLtsql_stmt_while;

/*
 * FOR statement with integer loopvar
 */
typedef struct PLtsql_stmt_fori
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	PLtsql_var *var;
	PLtsql_expr *lower;
	PLtsql_expr *upper;
	PLtsql_expr *step;			/* NULL means default (ie, BY 1) */
	int			reverse;
	List	   *body;			/* List of statements */
} PLtsql_stmt_fori;

/*
 * PLtsql_stmt_forq represents a FOR statement running over a SQL query.
 * It is the common supertype of PLtsql_stmt_fors, PLtsql_stmt_forc
 * and PLtsql_dynfors.
 */
typedef struct PLtsql_stmt_forq
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	PLtsql_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
} PLtsql_stmt_forq;

/*
 * FOR statement running over SELECT
 */
typedef struct PLtsql_stmt_fors
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	PLtsql_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
	/* end of fields that must match PLtsql_stmt_forq */
	PLtsql_expr *query;
} PLtsql_stmt_fors;

/*
 * FOR statement running over cursor
 */
typedef struct PLtsql_stmt_forc
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	PLtsql_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
	/* end of fields that must match PLtsql_stmt_forq */
	int			curvar;
	PLtsql_expr *argquery;		/* cursor arguments if any */
} PLtsql_stmt_forc;

/*
 * FOR statement running over EXECUTE
 */
typedef struct PLtsql_stmt_dynfors
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	PLtsql_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
	/* end of fields that must match PLtsql_stmt_forq */
	PLtsql_expr *query;
	List	   *params;			/* USING expressions */
} PLtsql_stmt_dynfors;

/*
 * FOREACH item in array loop
 */
typedef struct PLtsql_stmt_foreach_a
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	int			varno;			/* loop target variable */
	int			slice;			/* slice dimension, or 0 */
	PLtsql_expr *expr;			/* array expression */
	List	   *body;			/* List of statements */
} PLtsql_stmt_foreach_a;

/*
 * OPEN a curvar
 */
typedef struct PLtsql_stmt_open
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	int			curvar;
	int			cursor_options;
	PLtsql_expr *argquery;
	PLtsql_expr *query;
	PLtsql_expr *dynquery;
	List	   *params;			/* USING expressions */
} PLtsql_stmt_open;

/*
 * FETCH or MOVE statement
 */
typedef struct PLtsql_stmt_fetch
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_variable *target;	/* target (record or row) */
	int			curvar;			/* cursor variable to fetch from */
	FetchDirection direction;	/* fetch direction */
	long		how_many;		/* count, if constant (expr is NULL) */
	PLtsql_expr *expr;			/* count, if expression */
	bool		is_move;		/* is this a fetch or move? */
	bool		returns_multiple_rows;	/* can return more than one row? */
} PLtsql_stmt_fetch;

/*
 * CLOSE curvar
 */
typedef struct PLtsql_stmt_close
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	int			curvar;
} PLtsql_stmt_close;

/*
 * EXIT or CONTINUE statement
 */
typedef struct PLtsql_stmt_exit
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	bool		is_exit;		/* Is this an exit or a continue? */
	char	   *label;			/* NULL if it's an unlabelled EXIT/CONTINUE */
	PLtsql_expr *cond;
} PLtsql_stmt_exit;

/*
 * INSERT BULK statement
 */
typedef struct PLtsql_stmt_insert_bulk
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *table_name;
	char	   *schema_name;
	char	   *db_name;
	List	   *column_refs;

	/* Insert Bulk Options. */
	char	   *kilobytes_per_batch;
	char	   *rows_per_batch;
	bool		keep_nulls;
	bool		check_constraints;
} PLtsql_stmt_insert_bulk;

/*
 * DBCC statement type
 */
typedef union PLtsql_dbcc_stmt_data
{
	struct dbcc_checkident
	{
		char	*db_name;
		char	*schema_name;
		char	*table_name;
		bool	is_reseed;
		char	*new_reseed_value;
		bool	no_infomsgs;
	} dbcc_checkident;

} PLtsql_dbcc_stmt_data;

/*
 * DBCC statement
 */
typedef struct PLtsql_stmt_dbcc
{
	PLtsql_stmt_type	cmd_type;
	int	lineno;
	PLtsql_dbcc_stmt_type	dbcc_stmt_type;
	PLtsql_dbcc_stmt_data	dbcc_stmt_data;
} PLtsql_stmt_dbcc;

/*
 * RETURN statement
 */
typedef struct PLtsql_stmt_return
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *expr;
	int			retvarno;
} PLtsql_stmt_return;

/*
 * RETURN NEXT statement
 */
typedef struct PLtsql_stmt_return_next
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *expr;
	int			retvarno;
} PLtsql_stmt_return_next;

/*
 * RETURN QUERY statement
 */
typedef struct PLtsql_stmt_return_query
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *query;			/* if static query */
	PLtsql_expr *dynquery;		/* if dynamic query (RETURN QUERY EXECUTE) */
	List	   *params;			/* USING arguments for dynamic query */
} PLtsql_stmt_return_query;

/*
 * RAISE statement
 */
typedef struct PLtsql_stmt_raise
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	int			elog_level;
	char	   *condname;		/* condition name, SQLSTATE, or NULL */
	char	   *message;		/* old-style message format literal, or NULL */
	List	   *params;			/* list of expressions for old-style message */
	List	   *options;		/* list of PLtsql_raise_option */
} PLtsql_stmt_raise;

/*
 * RAISE statement option
 */
typedef struct PLtsql_raise_option
{
	PLtsql_raise_option_type opt_type;
	PLtsql_expr *expr;
} PLtsql_raise_option;

/*
 *	Grant Connect stmt
 */
typedef struct PLtsql_stmt_grantdb
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	bool		is_grant;
	List	   *grantees;		/* list of users */
} PLtsql_stmt_grantdb;

/*
 *	ALTER AUTHORIZATION ON DATABASE::<dbname> TO <login>
 */
typedef struct PLtsql_stmt_change_dbowner
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *db_name;
	char	   *new_owner_name;  /* Login name for new owner */
} PLtsql_stmt_change_dbowner;

typedef struct PLtsql_stmt_alter_db
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *old_db_name;
	char	   *new_db_name;
} PLtsql_stmt_alter_db;

/*
 *	Fulltext Index stmt
 */
typedef struct PLtsql_stmt_fulltextindex
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char        *table_name;   /* table name */
	List		*column_name;  /* column name */
	char		*index_name;   /* index name */
	char		*schema_name;  /* schema name */
	char		*db_name;      /* database name */
	bool		is_create;     /* flag for create index */		
} PLtsql_stmt_fulltextindex;

/*
 *	Grant on schema stmt
 */
typedef struct PLtsql_stmt_grantschema
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	bool		is_grant;
	int		privileges;
	List		*grantees;		/* list of users */
	bool 		with_grant_option;
	char		*schema_name;	/* schema name */
} PLtsql_stmt_grantschema;


/*
 * Partition Function
 */
typedef struct PLtsql_stmt_partition_function
{
	PLtsql_stmt_type	cmd_type;
	int			lineno;
	char			*function_name;
	bool			is_create;
	bool			is_right;
	PLtsql_type		*datatype;
	List			*args;		/* the arguments (list of exprs) */
} PLtsql_stmt_partition_function;

/*
 * Partition Scheme
 */
typedef struct PLtsql_stmt_partition_scheme
{
	PLtsql_stmt_type	cmd_type;
	int			lineno;
	char			*scheme_name;
	bool			is_create;
	char			*function_name;
	int			filegroups;	/* filegroups count, -1 indicates ALL is specified */
} PLtsql_stmt_partition_scheme;

/*
 * ASSERT statement
 */
typedef struct PLtsql_stmt_assert
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *cond;
	PLtsql_expr *message;
} PLtsql_stmt_assert;

typedef struct PLtsql_txn_data
{
	TransactionStmtKind stmt_kind;	/* Commit or rollback */
	char	   *txn_name;		/* Transaction name */
	PLtsql_expr *txn_name_expr; /* Transaction name variable */
} PLtsql_txn_data;

/*
 * Generic SQL statement to execute
 */
typedef struct PLtsql_stmt_execsql
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *sqlstmt;
	bool		mod_stmt;		/* is the stmt INSERT/UPDATE/DELETE?  Note:
								 * mod_stmt is set when we plan the query */
	bool		into;			/* INTO supplied? */
	bool		strict;			/* INTO STRICT flag */
	PLtsql_txn_data *txn_data;	/* Transaction data */
	PLtsql_variable *target;	/* INTO target (record or row) */
	bool		mod_stmt_tablevar;	/* is the stmt INSERT/UPDATE/DELETE on a
									 * table variable?  Note:
									 * mod_stmt_tablevar is set when we plan
									 * the query */
	bool		need_to_push_result;	/* push result to client */
	bool		is_tsql_select_assign_stmt; /* T-SQL SELECT-assign (i.e.
											 * SELECT @a=1) */
	bool		insert_exec;	/* INSERT-EXEC stmt? */
	bool		is_cross_db;	/* cross database reference */
	bool		is_dml;			/* DML statement? */
	bool		is_ddl;			/* DDL statement? */
	bool		func_call;		/* Function call? */
	char	   *schema_name;	/* Schema specified */
	char	   *db_name;		/* db_name: only for cross db query */
	bool		is_schema_specified;	/* is schema name specified? */
	bool		is_create_view; /* CREATE VIEW? */
	bool		is_set_tran_isolation; /* SET TRANSACTION ISOLATION? */
	char	   *original_query; /* Only for batch level statement. */
} PLtsql_stmt_execsql;

/*
 * SET statement to change EXPLAIN MODE
 * The main reason for this PLtsql statement is
 * to turn off EXPLAIN ONLY MODE while it is on.
 */
typedef struct PLtsql_stmt_set_explain_mode
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *query;
	bool		is_explain_only;
	bool		is_explain_analyze;
	bool		val;
} PLtsql_stmt_set_explain_mode;

/*
 * Dynamic SQL string to execute
 */
typedef struct PLtsql_stmt_dynexecute
{
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *query;			/* string expression */
	bool		into;			/* INTO supplied? */
	bool		strict;			/* INTO STRICT flag */
	PLtsql_variable *target;	/* INTO target (record or row) */
	List	   *params;			/* USING expressions */
} PLtsql_stmt_dynexecute;

/*
 * Hash lookup key for functions
 */
typedef struct PLtsql_func_hashkey
{
	/*
	 * lower 32bit for stored procedure's OID, upper 32bit for prepared
	 * batch's handle
	 */
	uint64_t	funcOid;

	bool		isTrigger;		/* true if called as a DML trigger */
	bool		isEventTrigger; /* true if called as an event trigger */

	/* be careful that pad bytes in this struct get zeroed! */

	/*
	 * For a trigger function, the OID of the trigger is part of the hash key
	 * --- we want to compile the trigger function separately for each trigger
	 * it is used with, in case the rowtype or transition table names are
	 * different.  Zero if not called as a DML trigger.
	 */
	Oid			trigOid;

	/*
	 * We must include the input collation as part of the hash key too,
	 * because we have to generate different plans (with different Param
	 * collations) for different collation settings.
	 */
	Oid			inputCollation;

	/*
	 * We include actual argument types in the hash key to support polymorphic
	 * Pltsql functions.  Be careful that extra positions are zeroed!
	 */
	Oid			argtypes[FUNC_MAX_ARGS];
} PLtsql_func_hashkey;

/*
 * Trigger type
 */
typedef enum PLtsql_trigtype
{
	PLTSQL_DML_TRIGGER,
	PLTSQL_EVENT_TRIGGER,
	PLTSQL_NOT_TRIGGER
} PLtsql_trigtype;

#define BATCH_OPTION_CACHE_PLAN       		0x1
#define BATCH_OPTION_PREPARE_PLAN       	0x2
#define BATCH_OPTION_SEND_METADATA       	0x4
#define BATCH_OPTION_NO_EXEC				0x8
#define BATCH_OPTION_EXEC_CACHED_PLAN 		0x10
#define BATCH_OPTION_NO_FREE 				0x20

typedef struct InlineCodeBlockArgs
{
	int			numargs;
	Oid		   *argtypes;
	int32	   *argtypmods;
	char	  **argnames;
	char	   *argmodes;
	int		   *varnos;
	unsigned long options;
	int			handle;
} InlineCodeBlockArgs;

#define OPTION_ENABLED(args, option) \
		(args && (args->options & BATCH_OPTION_##option))

/*
 * Complete compiled function
 */
typedef struct PLtsql_function
{
	char	   *fn_signature;
	Oid			fn_oid;
	TransactionId fn_xmin;
	ItemPointerData fn_tid;
	PLtsql_trigtype fn_is_trigger;
	Oid			fn_input_collation;
	PLtsql_func_hashkey *fn_hashkey;	/* back-link to hashtable key */
	MemoryContext fn_cxt;

	Oid			fn_rettype;
	int			fn_rettyplen;
	bool		fn_retbyval;
	bool		fn_retistuple;
	bool		fn_retisdomain;
	bool		fn_retset;
	bool		fn_readonly;
	char		fn_prokind;

	int			fn_nargs;
	int			fn_argvarnos[PREPARE_STMT_MAX_ARGS];
	int			out_param_varno;
	int			found_varno;
	int			fetch_status_varno;
	int			new_varno;
	int			old_varno;

	TupleDesc	fn_tupdesc;		/* tuple descriptor for return info */

	/* table variables */
	List	   *table_varnos;

	bool		is_itvf;
	bool		is_mstvf;

	PLtsql_resolve_option resolve_option;

	bool		print_strict_params;

	/* extra checks */
	int			extra_warnings;
	int			extra_errors;

	/* the datums representing the function's local variables */
	int			ndatums;
	PLtsql_datum **datums;
	Size		copiable_size;	/* space for locally instantiated datums */

	/* function body parsetree */
	PLtsql_stmt_block *action;

	/* these fields change when the function is used */
	struct PLtsql_execstate *cur_estate;
	unsigned long use_count;

	/* execution codes for new executor */
	struct ExecCodes *exec_codes;
	bool		exec_codes_valid;

	/* arguments for inline code block */
	InlineCodeBlockArgs *inline_args;
} PLtsql_function;

/*
 * Runtime execution data
 */

/*
 *  ERROR (exception) handling in iterative executor
 *
 *  A typical try catch block looks like
 *  BEGIN TRY
 *    STMT_BLOCK1
 *  END TRY
 *  BEGIN CATCH
 *    STMT_BLOCK2
 *  END CATCH
 *
 *  1. Preparation (before entering STMT_BLOCK1)
 *     1.1 Save context before entering STMT_BLOCK1, including
 *         a) stack for error signal handling (setjmp longjmp)
 *         b) program counter to STMT_BLOCK2
 *         c) various execution states (memory, eval context ....)
 *     1.2 Save into new_err_ctx_stack
 *  2. Execute STMT_BLOCK1.
 *     2.1 after execution retrieve error context and restore execution states
 *     2.2 destroy current error context
 *  3. Error handling (if error is raised from STMT_BLOCK1)
 *     3.1 retrieve error context and restore partially
 *     3.2 handle inactive error contexts (hint: read this step after 3.2 and 3.4)
 *     3.3 move error context to active_err_ctx_stack before entering STMT_BLOCK2
 *         a) this is needed because STMT_BLOCK2 could also be a try-catch block
 *            and it may also raise error
 *     3.4 retrieve active error context and restore the remaining
 *         save_cur_error : error data existed before entering try catch
 *         stmt_mcontext : memory containing current error
 *
 *     3.2 handle inactive error contexts:
 *         destory any error contexts unknown in this prepration phase (based on n_active_errors)
 *         if there is any, it means some STMT_BLOCK2s raised errors,
 *         and thus 3.4 was not executed for them. one possible scenario:
 *         BEGIN TRY
 *           BEGIN TRY STMT_BLOCK_X END TRY          -- raise error1
 *           BEGIN CATCH                             -- handling error1
 *               BEGIN TRY STMT_BLOCK_Y END TRY      -- raise error2
 *               BEGIN CATCH STMT_BLOCK_Z END CATCH  -- handling error2 and raise error3
 *           END CATCH
 *         END TRY
 *         BEGIN CATCH STMT_BLOCK_A END CATCH        -- handling error3
 *         Before entering STMT_BLOCK_A, one unknown active error context will be found,
 *         which was pushed into stack before entering STMT_BLOCK_Z.
 *         It contains error1 and stmt_mcontext for STMT_BLOCK_Y for saving its error (error2)
 *         memory will be reclaimed through top level memory context deallocation
 *         We could destory it bacause, STMT_BLOCK_A is handling error3
 */

typedef struct PLtsql_estate_err
{
	ErrorData  *error;
	char	   *procedure;
	int			number;
	int			severity;
	int			state;
} PLtsql_estate_err;

typedef struct
{
	/* for error handling */
	sigjmp_buf *save_exception_stack;
	ErrorContextCallback *save_context_stack;
	sigjmp_buf	local_sigjmp_buf;

	/* location of error handling statements */
	int			target_pc;

	/* various contexts */
	MemoryContext oldcontext;
	ResourceOwner oldowner;
	ExprContext *old_eval_econtext;

	PLtsql_estate_err *save_cur_error;

	MemoryContext stmt_mcontext;

	bool		partial_restored;	/* set true before executing catch block */
} PLtsql_errctx;

typedef struct ExplainInfo
{
	/* Estimated (or Actual) Query Execution Plan for a single statement */
	char	   *data;

	/* indent for the next ExplainInfo */
	size_t		next_indent;

	/* used to restore session to original schema if "use db" is invoked */
	const char *initial_database;
} ExplainInfo;

typedef struct PLtsql_execstate
{
	PLtsql_function *func;		/* function being executed */

	TriggerData *trigdata;		/* if regular trigger, data about firing */
	EventTriggerData *evtrigdata;	/* if event trigger, data about firing */

	Datum		retval;
	bool		retisnull;
	Oid			rettype;		/* type of current retval */

	Oid			fn_rettype;		/* info about declared function rettype */
	bool		retistuple;
	bool		retisset;

	bool		readonly_func;
	bool		atomic;
	PLtsql_impl_txn_type impl_txn_type; /* status of implicit transaction
										 * associated */

	char	   *exitlabel;		/* the "target" label of the current EXIT or
								 * CONTINUE stmt, if any */
	PLtsql_estate_err *cur_error;	/* current exception handler's error */

	Tuplestorestate *tuple_store;	/* SRFs accumulate results here */
	TupleDesc	tuple_store_desc;	/* descriptor for tuples in tuple_store */
	MemoryContext tuple_store_cxt;
	ResourceOwner tuple_store_owner;
	ReturnSetInfo *rsi;

	int			found_varno;
	int			fetch_status_varno;

	/*
	 * The datums representing the function's local variables.  Some of these
	 * are local storage in this execstate, but some just point to the shared
	 * copy belonging to the PLtsql_function, depending on whether or not we
	 * need any per-execution state for the datum's dtype.
	 */
	int			ndatums;
	PLtsql_datum **datums;
	/* context containing variable values (same as func's SPI_proc context) */
	MemoryContext datum_context;

	/*
	 * paramLI is what we use to pass local variable values to the executor.
	 * It does not have a ParamExternData array; we just dynamically
	 * instantiate parameter data as needed.  By convention, PARAM_EXTERN
	 * Params have paramid equal to the dno of the referenced local variable.
	 */
	ParamListInfo paramLI;

	/* EState to use for "simple" expression evaluation */
	EState	   *simple_eval_estate;
	bool		use_shared_simple_eval_state;

	/* lookup table to use for executing type casts */
	HTAB	   *cast_hash;
	MemoryContext cast_hash_context;

	/* memory context for statement-lifespan temporary values */
	MemoryContext stmt_mcontext;	/* current stmt context, or NULL if none */
	MemoryContext stmt_mcontext_parent; /* parent of current context */

	/* temporary state for results from evaluation of query or expr */
	SPITupleTable *eval_tuptable;
	uint64		eval_processed;
	Oid			eval_lastoid;
	ExprContext *eval_econtext; /* for executing simple expressions */

	/* status information for error context reporting */
	PLtsql_stmt *err_stmt;		/* current stmt */
	const char *err_text;		/* additional state info */

	void	   *plugin_info;	/* reserved for use by optional plugin */

	/*
	 * @@NESTLEVEL is needed to determine the name of underlying tables that
	 * need to be created for table variables. So we cache it here so that
	 * when there are multiple table variable declarations, we only need to
	 * calculate it once.
	 */
	int			nestlevel;
	/* iterative executor status */
	size_t		pc;				/* programe counter to current stmt in
								 * exec_code_buf */
	DynaVec    *err_ctx_stack;	/* stack for nested try catch block */
	size_t		cur_err_ctx_idx;

	int			tsql_trigger_flags;

	/*
	 * A same procedure can be invoked by either normal EXECUTE or INSERT ...
	 * EXECUTE, and can behave differently.
	 */
	bool		insert_exec;

	List	   *explain_infos;
	char	   *schema_name;
	const char *db_name;
	instr_time	planning_start;
	instr_time	planning_end;
	instr_time	execution_start;
	instr_time	execution_end;
} PLtsql_execstate;

/*
 * A PLtsql_plugin structure represents an instrumentation plugin.
 * To instrument PL/tsql, a plugin library must access the rendezvous
 * variable "PLtsql_plugin" and set it to point to a PLtsql_plugin struct.
 * Typically the struct could just be static data in the plugin library.
 * We expect that a plugin would do this at library load time (_PG_init()).
 * It must also be careful to set the rendezvous variable back to NULL
 * if it is unloaded (_PG_fini()).
 *
 * This structure is basically a collection of function pointers --- at
 * various interesting points in pl_exec.c, we call these functions
 * (if the pointers are non-NULL) to give the plugin a chance to watch
 * what we are doing.
 *
 * func_setup is called when we start a function, before we've initialized
 * the local variables defined by the function.
 *
 * func_beg is called when we start a function, after we've initialized
 * the local variables.
 *
 * func_end is called at the end of a function.
 *
 * stmt_beg and stmt_end are called before and after (respectively) each
 * statement.
 *
 * Also, immediately before any call to func_setup, PL/tsql fills in the
 * error_callback and assign_expr fields with pointers to its own
 * pltsql_exec_error_callback and exec_assign_expr functions.  This is
 * a somewhat ad-hoc expedient to simplify life for debugger plugins.
 */
typedef struct PLtsql_plugin
{
	/* Function pointers set up by the plugin */
	void		(*func_setup) (PLtsql_execstate *estate, PLtsql_function *func);
	void		(*func_beg) (PLtsql_execstate *estate, PLtsql_function *func);
	void		(*func_end) (PLtsql_execstate *estate, PLtsql_function *func);
	void		(*stmt_beg) (PLtsql_execstate *estate, PLtsql_stmt *stmt);
	void		(*stmt_end) (PLtsql_execstate *estate, PLtsql_stmt *stmt);

	/* Function pointers set by PL/tsql itself */
	void		(*error_callback) (void *arg);
	void		(*assign_expr) (PLtsql_execstate *estate, PLtsql_datum *target,
								PLtsql_expr *expr);
} PLtsql_plugin;

/*
 * When we load instrumentation extension, we create a rendezvous variable named
 * "PLtsql_instr_plugin" that points to an instance of type PLtsql_instr_plugin.
 *
 * We use this rendezvous variable to safely share information with
 * the engine even before the extension is loaded.  If you call
 * find_rendezvous_variable("PLtsql_config") and find  that *result
 * is NULL, then the extension has not been loaded.  If you find
 * that *result is non-NULL, it points to an instance of the
 * PLtsql_config struct shown here.
 */
typedef struct PLtsql_instr_plugin
{
	/* Function pointers set up by the plugin */
	void		(*pltsql_instr_increment_metric) (int metric);
	bool		(*pltsql_instr_increment_func_metric) (const char *funcName);
} PLtsql_instr_plugin;

typedef struct error_map_details_t
{
	char		sql_state[5];
	const char *error_message;
	int			tsql_error_code;
	int			tsql_error_severity;
	char	   *error_msg_keywords;
} error_map_details_t;

/*
 * A PLtsql_protocol_plugin structure represents a protocol plugin that can be
 * used with this extension.
 *
 * A protocol plugin library must access the rendezvous variable
 * "PLtsql_protocol_plugin" and set it to point to a PLtsql_protocol_plugin
 * struct.  Typically the struct could just be static data in the plugin
 * library.  We expect that a plugin would do this at library load time
 * (_PG_init()).  It must also be careful to set the rendezvous variable back
 * to NULL if it is unloaded (_PG_fini()).
 *
 * This structure is basically a collection of function pointers --- at
 * various interesting points in this extension, we call these functions
 * (if the pointers are non-NULL) to send any protocol information if
 * required.
 *
 * send_info - send INFO token
 * send_done - send DONE token
 * get_tsql_error - to get tsql error details from PG error
 *
 * Also when pltsql extension is loaded, we initialize the following callbacks
 * that is used to execute different protocol requests directly through this
 * extension.
 *
 * sql_batch_callback
 * sp_executesql_callback
 *
 * Additionally, it initializes the following two callbacks to declare
 * TSQL parameters and retrieve OUT parameters.
 *
 * pltsql_declare_var_callback
 * pltsql_read_out_param_callback
 */
typedef struct PLtsql_protocol_plugin
{
	/* True if Protocol being used by client is TDS. */
	bool		is_tds_client;

	/*
	 * List of GUCs used/set by protocol plugin.  We can always use this
	 * pointer to read the GUC value directly.  We've declared volatile so
	 * that the compiler always reads the value from the memory location
	 * instead of the register. We should be careful while setting data using
	 * this pointer - as the value will not be verified and changes can't be
	 * rolled back automatically in case of an error.
	 */
	volatile bool *pltsql_nocount_addr;

	/*
	 * stmt_need_logging checks whether stmt needs to be logged at
	 * babelfishpg_tsql parser and logs the statement at the end of statement
	 * execution on TDS
	 */
	bool		stmt_needs_logging;
	/* Function pointers set up by the plugin */
	void		(*send_info) (int number, int state, int info_class,
							  char *message, int line_no);
	void		(*send_done) (int tag, int status,
							  int curcmd, uint64_t nprocessed);
	void		(*send_env_change) (int envid, const char *new_val, const char *old_val);
	void		(*send_env_change_binary) (int envid, void *newValue, int newNbytes, void *oldValue, int oldNbytes);
	bool		(*get_tsql_error) (ErrorData *edata,
								   int *tsql_error_code,
								   int *tsql_error_severity,
								   int *tsql_error_state,
								   char *error_context);
	void		(*stmt_beg) (PLtsql_execstate *estate, PLtsql_stmt *stmt);
	void		(*stmt_end) (PLtsql_execstate *estate, PLtsql_stmt *stmt);
	void		(*stmt_exception) (PLtsql_execstate *estate, PLtsql_stmt *stmt,
								   bool terminate_batch);
	char	       *(*get_login_domainname) (void);
	void		(*set_guc_stat_var) (const char *guc, bool boolVal, const char *strVal, int intVal);
	void		(*set_at_at_stat_var) (TdsAtAtVarType at_at_var, int intVal, uint64 bigintVal);
	void		(*set_db_stat_var) (int16 db_id);
	bool		(*get_tds_database_backend_count) (int16 db_id, bool ignore_current_connection);
	bool		(*get_stat_values) (Datum *values, bool *nulls, int len, int pid, int curr_backend);
	void		(*invalidate_stat_view) (void);
	int		(*get_tds_numbackends) (void);
	char	       *(*get_host_name) (void);
	uint32_t        (*get_client_pid) (void);
	Datum		(*get_datum_from_byte_ptr) (StringInfo buf, int datatype, int scale);
	Datum		(*get_datum_from_date_time_struct) (uint64 time, int32 date, int datatype, int optional_attr);
	Datum		(*get_context_info) (void);
	void		(*set_context_info) (bytea *context_info);

	/* Function pointers set by PL/tsql itself */
	Datum		(*sql_batch_callback) (PG_FUNCTION_ARGS);
	Datum		(*sp_executesql_callback) (PG_FUNCTION_ARGS);
	Datum		(*sp_prepare_callback) (PG_FUNCTION_ARGS);
	Datum		(*sp_execute_callback) (PG_FUNCTION_ARGS);
	Datum		(*sp_prepexec_callback) (PG_FUNCTION_ARGS);
	Datum		(*sp_unprepare_callback) (PG_FUNCTION_ARGS);

	void		(*reset_session_properties) (void);

	void		(*sqlvariant_set_metadata) (bytea *result, int pgBaseType, int scale, int precision, int maxLen);
	void		(*sqlvariant_get_metadata) (bytea *result, int pgBaseType, int *scale,
											int *precision, int *maxLen);
	int			(*sqlvariant_inline_pg_base_type) (bytea *vlena);
	void		(*sqlvariant_get_pg_base_type) (uint8 variantBaseType, int *pgBaseType, int tempLen,
												int *dataLen, int *variantHeaderLen);
	void		(*sqlvariant_get_variant_base_type) (int pgBaseType, int *variantBaseType,
													 bool *isBaseNum, bool *isBaseChar,
													 bool *isBaseDec, bool *isBaseBin, bool *isBaseDate, int *variantHeaderLen);

	void		(*pltsql_declare_var_callback) (Oid type, int32 typmod, char *name,
												char mode, Datum value, bool isnull,
												int index, InlineCodeBlockArgs **args,
												FunctionCallInfo *fcinfo);
	void		(*pltsql_read_out_param_callback) (Datum comp_value, Datum **values,
												   bool **nulls);
	int			(*sp_cursoropen_callback) (int *cursor_handle, const char *stmt, int *scrollopt, int *ccopt,
										   int *row_count, int nparams, Datum *values, const char *nulls);
	int			(*sp_cursorprepare_callback) (int *stmt_handle, const char *stmt, int options, int *scrollopt, int *ccopt,
											  int nBindParams, Oid *boundParamsOidList);
	int			(*sp_cursorexecute_callback) (int stmt_handle, int *cursor_handle, int *scrollopt, int *ccopt,
											  int *rowcount, int nparams, Datum *values, const char *nulls);
	int			(*sp_cursorprepexec_callback) (int *stmt_handle, int *cursor_handle, const char *stmt, int options, int *scrollopt, int *ccopt,
											   int *row_count, int nparams, int nBindParams, Oid *boundParamsOidList, Datum *values, const char *nulls);
	int			(*sp_cursorunprepare_callback) (int stmt_handle);
	int			(*sp_cursoroption_callback) (int cursor_handle, int code, int value);
	int			(*sp_cursor_callback) (int cursor_handle, int opttype, int rownum, const char *tablename, List *values);
	int			(*sp_cursorfetch_callback) (int cursor_handle, int *fetchtype, int *rownum, int *nrows);
	int			(*sp_cursorclose_callback) (int cursor_handle);

	int		   *pltsql_read_proc_return_status;

	void		(*send_column_metadata) (TupleDesc typeinfo, List *targetlist, int16 *formats);
	void		(*pltsql_read_procedure_info) (StringInfo inout_str,
											   bool *is_proc,
											   Oid *atttypid,
											   Oid *atttypmod,
											   int *attcollation);

	int		   *pltsql_current_lineno;

	int			(*pltsql_read_numeric_typmod) (Oid funcid, int nargs, Oid declared_oid);

	bool		(*pltsql_get_errdata) (int *tsql_error_code, int *tsql_error_severity, int *tsql_error_state);

	int16		(*pltsql_get_database_oid) (const char *dbname);

	bool		(*pltsql_is_login) (Oid role_oid);

	char	   *(*pltsql_get_login_default_db) (char *login_name);

	void	   *(*get_mapped_error_list) (void);

	int		   *(*get_mapped_tsql_error_code_list) (void);

	uint64		(*bulk_load_callback) (int ncol, int nrow,
									   Datum *Values, bool *Nulls);

	void 		(*pltsql_rollback_txn_callback) (void);

	void		(*pltsql_abort_any_transaction_callback) (void);

	int			(*pltsql_get_generic_typmod) (Oid funcid, int nargs, Oid declared_oid);

	const char *(*pltsql_get_logical_schema_name) (const char *physical_schema_name, bool missingOk);

	bool	   *pltsql_is_fmtonly_stmt;

	char	   *(*pltsql_get_user_for_database) (const char *db_name);

	char	   *(*TsqlEncodingConversion) (const char *s, int len, int encoding, int *encodedByteLen);

	int			(*TdsGetEncodingFromLcid) (int32_t lcid);

	int			(*get_insert_bulk_rows_per_batch) ();

	int			(*get_insert_bulk_kilobytes_per_batch) ();

	void	   *(*tsql_varchar_input) (const char *s, size_t len, int32 atttypmod);

	void	   *(*tsql_char_input) (const char *s, size_t len, int32 atttypmod);

	char	   *(*get_cur_db_name) ();

	char	   *(*get_physical_schema_name) (char *db_name, const char *schema_name);

	void		(*set_reset_tds_connection_flag) ();

	bool		(*get_reset_tds_connection_flag) ();

	/* Session level GUCs */
	bool		quoted_identifier;
	bool		arithabort;
	bool		ansi_null_dflt_on;
	bool		ansi_defaults;
	bool		ansi_warnings;
	bool		ansi_padding;
	bool		ansi_nulls;
	bool		concat_null_yields_null;
	int			textsize;
	int			datefirst;
	int			lock_timeout;
	const char *language;
} PLtsql_protocol_plugin;

/*
 * Struct types used during parsing
 */

typedef struct PLword
{
	char	   *ident;			/* palloc'd converted identifier */
	bool		quoted;			/* Was it double-quoted? */
} PLword;

typedef struct PLcword
{
	List	   *idents;			/* composite identifiers (list of String) */
} PLcword;

typedef struct PLwdatum
{
	PLtsql_datum *datum;		/* referenced variable */
	char	   *ident;			/* valid if simple name */
	bool		quoted;
	List	   *idents;			/* valid if composite name */
} PLwdatum;

/**********************************************************************
 * Global variable declarations
 **********************************************************************/

typedef enum
{
	IDENTIFIER_LOOKUP_NORMAL,	/* normal processing of var names */
	IDENTIFIER_LOOKUP_DECLARE,	/* In DECLARE --- don't look up names */
	IDENTIFIER_LOOKUP_EXPR		/* In SQL expression --- special case */
} IdentifierLookup;

typedef struct
{
	AttrNumber	x_attnum;
	int			trigger_depth;
	int			total_columns;
	char	   *column_name;
} UpdatedColumn;

extern IdentifierLookup pltsql_IdentifierLookup;

typedef struct tsql_identity_insert_fields
{
	bool		valid;
	Oid			rel_oid;
	Oid			schema_oid;
} tsql_identity_insert_fields;

/* 
 * It is modified version of compare_context, which is used to
 * provide extra arg during sort operation to compare function.
 * Please check tsql_compare_values() and exec_stmt_partition_function()
 * for more details.
 */
typedef struct tsql_compare_context
{
	Oid function_oid; /* oid of comparator operator */
	Oid colloid; /* collation which needs to used during comparison */
	bool contains_duplicate; /* true if the array contains duplicate values */
} tsql_compare_context;

extern int tsql_compare_values(const void *a, const void *b, void *arg);

extern tsql_identity_insert_fields tsql_identity_insert;
extern check_lang_as_clause_hook_type check_lang_as_clause_hook;
extern write_stored_proc_probin_hook_type write_stored_proc_probin_hook;
extern make_fn_arguments_from_stored_proc_probin_hook_type make_fn_arguments_from_stored_proc_probin_hook;

extern plansource_complete_hook_type prev_plansource_complete_hook;
extern plansource_revalidate_hook_type prev_plansource_revalidate_hook;
extern pltsql_nextval_hook_type prev_pltsql_nextval_hook;
extern pltsql_resetcache_hook_type prev_pltsql_resetcache_hook;

extern int	pltsql_variable_conflict;

/* extra compile-time checks */
#define PLTSQL_XCHECK_NONE			0
#define PLTSQL_XCHECK_SHADOWVAR	1
#define PLTSQL_XCHECK_ALL			((int) ~0)

extern bool pltsql_check_syntax;
extern bool pltsql_DumpExecTree;

extern PLtsql_stmt_block *pltsql_parse_result;

extern int	pltsql_nDatums;
extern PLtsql_datum **pltsql_Datums;

extern char *pltsql_error_funcname;

extern PLtsql_function *pltsql_curr_compile;
extern MemoryContext pltsql_compile_tmp_cxt;

extern PLtsql_plugin **pltsql_plugin_ptr;
extern PLtsql_instr_plugin **pltsql_instr_plugin_ptr;
extern PLtsql_protocol_plugin **pltsql_protocol_plugin_ptr;
extern common_utility_plugin *common_utility_plugin_ptr;

#define IS_TDS_CLIENT() (*pltsql_protocol_plugin_ptr && \
						 (*pltsql_protocol_plugin_ptr)->is_tds_client)

extern Oid	procid_var;
extern uint64 rowcount_var;
extern List *columns_updated_list;
extern int	pltsql_trigger_depth;
extern int	latest_error_code;
extern int	latest_pg_error_code;
extern bool last_error_mapping_failed;

extern int	fetch_status_var;
extern int	pltsql_proc_return_code;

extern char *pltsql_version;

typedef struct PLtsqlErrorData
{
	bool		xact_abort_on;
	bool		rethrow_error;
	bool		trigger_error;
	PLtsql_execstate *error_estate;
	char	   *error_procedure;
	int			error_number;
	int			error_severity;
	int			error_state;
} PLtsqlErrorData;

typedef struct PLExecStateCallStack
{
	PLtsql_execstate *estate;
	PLtsqlErrorData error_data;
	struct PLExecStateCallStack *next;
} PLExecStateCallStack;

extern PLExecStateCallStack *exec_state_call_stack;

extern bool pltsql_xact_abort;
extern bool pltsql_implicit_transactions;
extern bool pltsql_cursor_close_on_commit;
extern bool pltsql_disable_batch_auto_commit;
extern bool pltsql_disable_internal_savepoint;
extern bool pltsql_disable_txn_in_triggers;
extern bool pltsql_recursive_triggers;

extern int	text_size;
extern int	pltsql_rowcount;
extern int	pltsql_lock_timeout;
extern Portal pltsql_snapshot_portal;
extern int	pltsql_non_tsql_proc_entry_count;
extern int	pltsql_sys_func_entry_count;
extern bool current_query_is_create_tbl_check_constraint;

extern char *bulk_load_table_name;

/* Insert Bulk Options */
#define DEFAULT_INSERT_BULK_ROWS_PER_BATCH 1000
#define DEFAULT_INSERT_BULK_PACKET_SIZE 8

extern int	insert_bulk_rows_per_batch;
extern int	insert_bulk_kilobytes_per_batch;
extern bool insert_bulk_keep_nulls;
extern bool insert_bulk_check_constraints;

/**********************************************************************
 * Function declarations
 **********************************************************************/

/*
 * Functions in pl_comp.c
 */
extern PLtsql_function *pltsql_compile(FunctionCallInfo fcinfo,
									   bool forValidator);
extern PLtsql_function *pltsql_compile_inline(char *proc_source,
											  InlineCodeBlockArgs *args);
extern void pltsql_parser_setup(struct ParseState *pstate,
								PLtsql_expr *expr);
extern bool pltsql_parse_word(char *word1, const char *yytxt,
							  PLwdatum *wdatum, PLword *word);
extern bool pltsql_parse_dblword(char *word1, char *word2,
								 PLwdatum *wdatum, PLcword *cword);
extern bool pltsql_parse_tripword(char *word1, char *word2, char *word3,
								  PLwdatum *wdatum, PLcword *cword);
extern PLtsql_type *pltsql_parse_wordtype(char *ident);
extern PLtsql_type *pltsql_parse_cwordtype(List *idents);
extern PLtsql_type *pltsql_parse_wordrowtype(char *ident);
extern PLtsql_type *pltsql_parse_cwordrowtype(List *idents);
extern PLtsql_type *pltsql_build_datatype(Oid typeOid, int32 typmod,
										  Oid collation, TypeName *origtypname);
extern PLtsql_type *pltsql_build_table_datatype_coldef(const char *coldef);
extern PLtsql_variable *pltsql_build_variable(const char *refname, int lineno,
											  PLtsql_type *dtype,
											  bool add2namespace);
extern PLtsql_rec *pltsql_build_record(const char *refname, int lineno,
									   PLtsql_type *dtype, Oid rectypeid,
									   bool add2namespace);
extern PLtsql_tbl *pltsql_build_table(const char *refname, int lineno,
									  PLtsql_type *dtype, Oid tbltypeid,
									  bool add2namespace);
extern PLtsql_recfield *pltsql_build_recfield(PLtsql_rec *rec,
											  const char *fldname);
extern int	pltsql_recognize_err_condition(const char *condname,
										   bool allow_sqlstate);
extern PLtsql_condition *pltsql_parse_err_condition(char *condname);
extern void pltsql_adddatum(PLtsql_datum *newdatum);
extern int	pltsql_add_initdatums(int **varnos);
extern void pltsql_HashTableInit(void);
extern void reset_cache(void);

/*
 * Functions in pl_handler.c
 */
extern void _PG_init(void);
extern Datum sp_prepare(PG_FUNCTION_ARGS);
extern Datum sp_unprepare(PG_FUNCTION_ARGS);
extern bool pltsql_support_tsql_transactions(void);
extern bool pltsql_sys_function_pop(void);
extern uint64 execute_bulk_load_insert(int ncol, int nrow,
									   Datum *Values, bool *Nulls);

/*
 * Functions in pl_exec.c
 */
extern Datum pltsql_exec_function(PLtsql_function *func,
								  FunctionCallInfo fcinfo,
								  EState *simple_eval_estate,
								  bool atomic);
extern HeapTuple pltsql_exec_trigger(PLtsql_function *func,
									 TriggerData *trigdata);
extern void pltsql_exec_event_trigger(PLtsql_function *func,
									  EventTriggerData *trigdata);
extern void pltsql_xact_cb(XactEvent event, void *arg);
extern void pltsql_subxact_cb(SubXactEvent event, SubTransactionId mySubid,
							  SubTransactionId parentSubid, void *arg);
extern Oid	pltsql_exec_get_datum_type(PLtsql_execstate *estate,
									   PLtsql_datum *datum);
extern void pltsql_exec_get_datum_type_info(PLtsql_execstate *estate,
											PLtsql_datum *datum,
											Oid *typeId, int32 *typMod, Oid *collation);

extern int	get_insert_bulk_rows_per_batch(void);
extern int	get_insert_bulk_kilobytes_per_batch(void);
extern char *get_original_query_string(void);
extern AclMode string_to_privilege(const char *privname);
extern const char *privilege_to_string(AclMode privilege);
extern Oid get_owner_of_schema(const char *schema);

/*
 * Functions for namespace handling in pl_funcs.c
 */
extern void pltsql_ns_init(void);
extern void pltsql_ns_push(const char *label,
						   PLtsql_label_type label_type);
extern void pltsql_ns_pop(void);
extern PLtsql_nsitem *pltsql_ns_top(void);
extern void pltsql_ns_additem(PLtsql_nsitem_type itemtype, int itemno, const char *name);
extern PLtsql_nsitem *pltsql_ns_lookup(PLtsql_nsitem *ns_cur, bool localmode,
									   const char *name1, const char *name2,
									   const char *name3, int *names_used);
extern PLtsql_nsitem *pltsql_ns_lookup_label(PLtsql_nsitem *ns_cur,
											 const char *name);
extern PLtsql_nsitem *pltsql_ns_find_nearest_loop(PLtsql_nsitem *ns_cur);

/*
 * Other functions in pl_funcs.c
 */
extern const char *pltsql_stmt_typename(PLtsql_stmt *stmt);
extern const char *pltsql_getdiag_kindname(PLtsql_getdiag_kind kind);
extern void pltsql_free_function_memory(PLtsql_function *func);
extern void pltsql_dumptree(PLtsql_function *func);
extern void pre_function_call_hook_impl(const char *funcName);
extern int32 coalesce_typmod_hook_impl(const CoalesceExpr *cexpr);
extern void check_restricted_stored_procedure(Oid proc_id);
extern bool is_tsql_atatglobalvar(const char *varname);
extern bool is_tsql_atatuservar(const char *varname);

/*
 * Scanner functions in pl_scanner.c
 */
extern int	pltsql_base_yylex(void);
extern int	pltsql_yylex(void);
extern void pltsql_push_back_token(int token);
extern bool pltsql_token_is_unreserved_keyword(int token);
extern void pltsql_append_source_text(StringInfo buf,
									  int startlocation, int endlocation);
extern int	pltsql_get_yyleng(void);
extern char *pltsql_get_source(int startlocation, int len);
extern int	pltsql_peek(void);
extern void pltsql_peek2(int *tok1_p, int *tok2_p, int *tok1_loc,
						 int *tok2_loc);
extern bool pltsql_peek_word_matches(const char *pattern);
extern int	pltsql_scanner_errposition(int location);
extern void pltsql_yyerror(const char *message) pg_attribute_noreturn();
extern int	pltsql_location_to_lineno(int location);
extern int	pltsql_latest_lineno(void);
extern void pltsql_scanner_init(const char *str);
extern void pltsql_scanner_finish(void);

/*
 * Externs in gram.y
 */
extern int	pltsql_yyparse(void);

/* functions in hooks.c */
extern char *extract_identifier(const char *start, int *last_pos);

/* functions in pltsql_utils.c */
extern char *gen_createfulltextindex_cmds(const char *table_name, const char *schema_name, const List *column_name, const char *index_name);
extern char *gen_dropfulltextindex_cmds(const char *index_name, const char *schema_name);
extern char *get_fulltext_index_name(Oid relid, const char *table_name);
extern const char *gen_schema_name_for_fulltext_index(const char *schema_name);
extern bool check_fulltext_exist(const char *schema_name, const char *table_name);
extern char *replace_special_chars_fts_impl(char *input_str);
extern bool is_unique_index(Oid relid, const char *index_name);
extern void exec_grantschema_subcmds(const char *schema, const char *rolname, bool is_grant, bool with_grant_option, AclMode privilege, bool is_create_schema);
extern int	TsqlUTF8LengthInUTF16(const void *vin, int len);
extern void TsqlCheckUTF16Length_bpchar(const char *s, int32 len, int32 maxlen, int charlen, bool isExplicit);
extern void TsqlCheckUTF16Length_varchar(const char *s, int32 len, int32 maxlen, bool isExplicit);
extern void TsqlCheckUTF16Length_varchar_input(const char *s, int32 len, int32 maxlen);
extern void TsqlCheckUTF16Length_bpchar_input(const char *s, int32 len, int32 maxlen, int charlen);
extern void pltsql_declare_variable(Oid type, int32 typmod, char *name, char mode, Datum value,
									bool isnull, int index, InlineCodeBlockArgs **args,
									FunctionCallInfo *fcinfo);
extern void pltsql_read_composite_out_param(Datum comp_value, Datum **values, bool **nulls);
extern void pltsql_read_procedure_info(StringInfo inout_str,
									   bool *is_proc,
									   Oid *atttypid,
									   Oid *atttypmod,
									   int *attcollation);
void PLTsqlProcessTransaction(Node *parsetree,
						            ParamListInfo params,
						 			QueryCompletion *qc);


extern void PLTsqlStartTransaction(char *txnName);
extern void PLTsqlCommitTransaction(QueryCompletion *qc, bool chain);
extern void PLTsqlRollbackTransaction(char *txnName, QueryCompletion *qc, bool chain);
extern void pltsql_start_txn(void);
extern void pltsql_commit_txn(void);
extern void pltsql_rollback_txn(void);
extern void pltsql_abort_any_transaction(void);
extern bool pltsql_get_errdata(int *tsql_error_code, int *tsql_error_severity, int *tsql_error_state);
extern void pltsql_eval_txn_data(PLtsql_execstate *estate, PLtsql_stmt_execsql *stmt, CachedPlanSource *cachedPlanSource);
extern bool is_sysname_column(ColumnDef *coldef);
extern bool have_null_constr(List *constr_list);
extern Node *parsetree_nth_stmt(List *parsetree, int n);
extern void update_AlterTableStmt(Node *n, const char *tbl_schema, const char *newowner);
extern void update_CreateRoleStmt(Node *n, const char *role, const char *member, const char *addto);
extern void update_AlterRoleStmt(Node *n, RoleSpec *role);
extern void update_CreateSchemaStmt(Node *n, const char *schemaname, const char *authrole);
extern void update_DropOwnedStmt(Node *n, List *role_list);
extern void update_DropRoleStmt(Node *n, const char *role);
extern void update_DropStmt(Node *n, const char *object);
extern void update_GrantRoleStmt(Node *n, List *privs, List *roles, const char *grantor);
extern void update_GrantStmt(Node *n, const char *object, const char *obj_schema, const char *grantee, const char *priv);
extern void update_RenameStmt(Node *n, const char *old_name, const char *new_name);
extern void update_ViewStmt(Node *n, const char *view_schema);
extern void update_AlterDefaultPrivilegesStmt(Node *n, const char *schema, const char *role1, const char *role2, const char *grantee, const char *priv);
extern AccessPriv *make_accesspriv_node(const char *priv_name);
extern RoleSpec   *make_rolespec_node(const char *rolename);
extern void pltsql_check_or_set_default_typmod_helper(TypeName *typeName, int32 *typmod, bool is_cast, bool is_procedure_or_func);
extern void pltsql_check_or_set_default_typmod(TypeName *typeName, int32 *typmod, bool is_cast);
extern bool TryLockLogicalDatabaseForSession(int16 dbid, LOCKMODE lockmode);
extern void UnlockLogicalDatabaseForSession(int16 dbid, LOCKMODE lockmode, bool force);
extern char *bpchar_to_cstring(const BpChar *bpchar);
extern char *varchar_to_cstring(const VarChar *varchar);
extern char *flatten_search_path(List *oid_list);
extern char *get_pltsql_function_signature_internal(const char *funcname, int nargs, const Oid *argtypes);
extern void report_info_or_warning(int elevel, char *message);
extern void init_and_check_common_utility(void);
extern Oid	tsql_get_trigger_oid(char *tgname, Oid tgnamespace, Oid user_id);
extern Oid	tsql_get_constraint_oid(char *conname, Oid connamespace, Oid user_id);
extern Oid	tsql_get_proc_oid(char *proname, Oid pronamespace, Oid user_id);
extern char **split_object_name(char *name);
extern bool is_schema_from_db(Oid schema_oid, Oid db_id);
extern void remove_trailing_spaces(char *name);
extern Oid	tsql_get_proc_nsp_oid(Oid object_id);
extern Oid	tsql_get_constraint_nsp_oid(Oid object_id, Oid user_id);
extern Oid	tsql_get_trigger_rel_oid(Oid object_id);
extern bool pltsql_createFunction(ParseState *pstate, PlannedStmt *pstmt, const char *queryString, ProcessUtilityContext context, 
                          ParamListInfo params);
extern Oid get_sys_varcharoid(void);
extern Oid get_sysadmin_oid(void);
extern bool is_tsql_varchar_or_char_datatype(Oid oid); /* sys.char / sys.varchar */
extern bool is_tsql_nchar_or_nvarchar_datatype(Oid oid); /* sys.nchar / sys.nvarchar */
extern bool is_tsql_binary_or_varbinary_datatype(Oid oid); /* sys.binary / sys.varbinary */
extern bool is_tsql_datatype_with_max_scale_expr_allowed(Oid oid); /* sys.varchar(max), sys.nvarchar(max), sys.varbinary(max) */
extern bool is_tsql_text_ntext_or_image_datatype(Oid oid); /* sys.text, sys.ntext, sys.image */

typedef struct
{
	bool		success;
	bool		parseTreeCreated;	/* used to determine if on error should
									 * retry with a different parse mode */
	size_t		errpos;
	int			errcod;
	const char *errfmt;
	size_t		n_errargs;
	const void *errargs[5];		/* support up to 5 args */
} ANTLR_result;

extern ANTLR_result antlr_parser_cpp(const char *sourceText);
extern void report_antlr_error(ANTLR_result result);

/*
 *  Configurations for iterative executor
 */
extern bool pltsql_trace_tree;
extern bool pltsql_trace_exec_codes;
extern bool pltsql_trace_exec_counts;
extern bool pltsql_trace_exec_time;

/*
 * Functions in cursor.c
 */
int			execute_sp_cursor(int cursor_handle, int opttype, int rownum, const char *tablename, List *values);
int			execute_sp_cursoropen_old(int *cursor_handle, const char *stmt, int *scrollopt, int *ccopt, int *row_count, int nparams, Datum *values, const char *nulls); /* old interface to be
																																										 * compatabile with TDS */
int			execute_sp_cursoropen(int *cursor_handle, const char *stmt, int *scrollopt, int *ccopt, int *row_count, int nparams, int nBindParams, Oid *boundParamsOidList, Datum *values, const char *nulls);
int			execute_sp_cursorprepare(int *stmt_handle, const char *stmt, int options, int *scrollopt, int *ccopt, int nBindParams, Oid *boundParamsOidList);
int			execute_sp_cursorexecute(int stmt_handle, int *cursor_handle, int *scrollopt, int *ccopt, int *rowcount, int nparams, Datum *values, const char *nulls);
int			execute_sp_cursorprepexec(int *stmt_handle, int *cursor_handle, const char *stmt, int options, int *scrollopt, int *ccopt, int *row_count, int nparams, int nBindParams, Oid *boundParamsOidList, Datum *values, const char *nulls);
int			execute_sp_cursorunprepare(int stmt_handle);
int			execute_sp_cursorfetch(int cursor_handle, int *fetchtype, int *rownum, int *nrows);
int			execute_sp_cursoroption(int cursor_handle, int code, int value);
int			execute_sp_cursoroption2(int cursor_handle, int code, const char *value);
int			execute_sp_cursorclose(int cursor_handle);
void		reset_cached_cursor(void);

/*
 * Functions in string.c
 */
void		prepare_format_string(StringInfo buf, char *msg_string, int nargs,
								  Datum *args, Oid *argtypes, bool *argisnull);

/*
 * Functions in pltsql_function_probin_handler.c
 */
void		probin_read_args_typmods(HeapTuple procTup, int nargs, Oid *argtypes, int **typmods);
int			probin_read_ret_typmod(Oid funcid, int nargs, Oid declared_oid);
bool		pltsql_function_as_checker(const char *lang, List *as, char **prosrc_str_p, char **probin_str_p);
void		pltsql_function_probin_writer(CreateFunctionStmt *stmt, Oid languageOid, char **probin_str_p);
void		pltsql_function_probin_reader(ParseState *pstate,
										  List *fargs, Oid *actual_arg_types, Oid *declared_arg_types, Oid funcid);
extern void probin_json_reader(text *probin, int **typmod_arr_p, int typmod_arr_len);

/*
 * This variable is set to true, if setval should behave in T-SQL way, i.e.,
 * setval sets the max/min(current identity value, new identity value to be
 * inserted.  By default, it is set to fale which means setval should behave
 * PG way irrespective of the dialect - reset identity seed.
 */
extern bool pltsql_setval_identity_mode;

/*
 * Functions in pltsql_identity.c
 */
extern void pltsql_update_last_identity(Oid seqid, int64 val);
extern int64 last_identity_value(void);
extern void pltsql_nextval_identity(Oid seqid, int64 val);
extern void pltsql_resetcache_identity(void);
extern int64 pltsql_setval_identity(Oid seqid, int64 val, int64 last_val);
extern int64 last_scope_identity_value(void);

/*
 * Functions in linked_servers.c
 */
void		GetOpenqueryTupdescFromMetadata(char *linked_server, char *query, TupleDesc *tupdesc);
extern void 	exec_utility_cmd_helper(char *query_str);
extern void	exec_alter_role_cmd(char *query_str, RoleSpec *role);

/*
 * Functions in pltsql_coerce.c
 */
extern bool validate_special_function(char *proc_nsname, char *proc_name,  List* fargs, int nargs, Oid *input_typeids, bool num_args_match);
extern void init_special_function_list(void);

#endif							/* PLTSQL_H */
