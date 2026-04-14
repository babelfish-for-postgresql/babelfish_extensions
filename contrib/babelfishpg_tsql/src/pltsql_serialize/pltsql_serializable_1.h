/*-------------------------------------------------------------------------
 *
 * pltsql_serializable_1.h
 *    Annotated copy of pltsql.h for antlr parse cache code generation.
 *
 * Structs here mirror pltsql.h with pg_node_attr() annotations added.
 * Read by gen_pltsql_node_support.pl to generate serialization,
 * deserialization, and equality functions in order to support routine 
 * ANTLR parse tree caching.
 * Refer: GUCs `enable_antlr_parse_cache` and `validate_antlr_parse_cache`
 *
 * NOTES:
 *  - This file is NOT compiled by the C compiler.
 *  - Annotations follow PostgreSQL's gen_node_support.pl pattern.
 *  - When pltsql.h struct definitions change, this file must be updated
 *    to match (keeping the pg_node_attr annotations).
 *
 * IDENTIFICATION
 *    contrib/babelfishpg_tsql/src/pltsql_serialize/pltsql_serializable_1.h 
 *    (mirrors babelfish_extensions/contrib/babelfishpg_tsql/src/pltsql.h)
 *
 *-------------------------------------------------------------------------
 */

/*
 * Annotation Guide:
 * 
 * Struct-level attributes (placed after opening brace):
 *   - custom_read_write: Struct has custom serialization/deserialization logic
 *   - no_copy: Don't generate copy support
 *   - no_equal: Don't generate equal support
 *   - special_read_write: Special handling for read/write
 *
 * Field-level attributes (placed after field declaration):
 *   - read_write_ignore: Skip this field during serialization/deserialization
 *   - array_size(field): Specifies the field that contains array size
 *   - copy_as(expr): Use custom expression for copying
 *   - read_as(expr): Use custom expression for reading
 *   - equal_ignore: Skip this field during equality comparison
 *
 * Special handling notes:
 *   - PLtsql_variable* references: Store dno (datum number) instead of pointer
 *   - PLtsql_expr*: Serialize query string, paramnos, and other metadata
 *   - List*: Serialize list length and elements
 *   - Flexible arrays: Use array_size() annotation
 */

/* Note:
 * Most nodes in this file are annotated with pg_node_attr(no_copy, no_query_jumble) 
 *
 * Reason:
 * pg_node_attr(no_copy, no_query_jumble) tells the generator: don't generate copy or jumble functions for this struct. Only generate _out, _read and _equal.
 * PLtsql nodes are never used in PG's query planner/optimizer, so _copy is never called on them by PG internals.
 * Query jumbling is for PG's prepared statement cache, not relevant to PLtsql nodes.
 * Deep copy is not needed because serialize/deserialize into a separate memory context achieves the same result.
 * _out functions ARE generated and used for serializing PLtsql parse trees into string representation for caching.
 * _read functions ARE generated and used for deserializing cached string representation back into PLtsql parse trees.
 * _equal functions ARE generated and used for parse tree validation (comparing cached vs ANTLR-compiled trees).
*/

/*
 * Forward declarations for PLtsql types referenced before their definition.
 */
// typedef struct PLtsql_expr PLtsql_expr;
// typedef struct PLtsql_exception_block PLtsql_exception_block;
// typedef struct PLtsql_condition PLtsql_condition;
// typedef struct PLtsql_type PLtsql_type;
// typedef struct PLtsql_variable PLtsql_variable;
// typedef struct PLtsql_txn_data PLtsql_txn_data;

/*
 * Forward declarations for external PG types referenced in struct fields.
 * These are all pointer fields, so the compiler only needs to know they exist.
 */
typedef struct SPIPlanData *SPIPlanPtr;
typedef struct ExpandedRecordHeader ExpandedRecordHeader;
#include "utils/expandedrecord.h"  /* needed for ExpandedRecordFieldInfo (inline struct in PLtsql_recfield) */
struct TypeCacheEntry;
typedef struct TypeCacheEntry TypeCacheEntry;
typedef struct TupleDescData *TupleDesc;
typedef struct ExprState ExprState;  /* from nodes/execnodes.h - too heavy to include */

/*
 * Prototypes for custom_read_write functions in pltsql_outfuncs_stubs.c / pltsql_readfuncs_stubs.c.
 * These are called by the generated outfuncs.switch.c / readfuncs.switch.c.
 */
struct PLtsql_nsitem;
struct PLtsql_row;
struct PLtsql_recfield;

extern void _outPLtsql_nsitem(StringInfo str, const struct PLtsql_nsitem *node);
extern struct PLtsql_nsitem *_readPLtsql_nsitem(void);
extern void _outPLtsql_row(StringInfo str, const struct PLtsql_row *node);
extern struct PLtsql_row *_readPLtsql_row(void);
extern void _outPLtsql_recfield(StringInfo str, const struct PLtsql_recfield *node);
extern struct PLtsql_recfield *_readPLtsql_recfield(void);
#include "nodes/lockoptions.h"     /* for LockClauseStrength etc */
#include "nodes/parsenodes.h"      /* for FetchDirection, TransactionStmtKind, TypeName */


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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	TypeCacheEntry *tcache pg_node_attr(read_write_ignore, read_as(NULL));		/* typcache entry for composite type */
	uint64		tupdesc_id pg_node_attr(read_write_ignore, read_as(0));		/* last-seen tupdesc identifier */
} PLtsql_type;

/*
 * SQL Query to plan and execute
 */
typedef struct PLtsql_expr
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	char	   *query pg_node_attr(equal_ignore);  /* contains embedded dno values that differ between CREATE/EXEC */
	SPIPlanPtr	plan pg_node_attr(read_write_ignore, read_as(NULL));
	Bitmapset  *paramnos pg_node_attr(equal_ignore);  /* all dnos referenced by this query */ /* dno-based bitmapset, differs between CREATE/EXEC */
	int			rwparam pg_node_attr(equal_ignore);    /* dno of read/write param, or -1 if none*/ /* differs between CREATE/EXEC */

	/* function containing this expr (not set until we first parse query) */
	struct PLtsql_function *func pg_node_attr(read_write_ignore, read_as(NULL));

	/* namespace chain visible to this expr — chain length differs between CREATE/EXEC */
	struct PLtsql_nsitem *ns pg_node_attr(equal_ignore);

	/* fields for "simple expression" fast-path execution (all runtime-only): */
	Expr	   *expr_simple_expr pg_node_attr(read_write_ignore, equal_ignore, read_as(NULL)); /* NULL means not a simple expr */
	int			expr_simple_generation pg_node_attr(read_write_ignore, equal_ignore, read_as(0));  /* plancache generation we checked */
	Oid			expr_simple_type pg_node_attr(read_write_ignore, equal_ignore, read_as(0)); /* result type Oid, if simple */ /* read_as(InvalidOid) */
	int32		expr_simple_typmod pg_node_attr(read_write_ignore, equal_ignore, read_as(0)); /* result typmod, if simple */
	bool		expr_simple_mutable pg_node_attr(read_write_ignore, equal_ignore, read_as(false)); /* true if simple expr is mutable */

	/*
	 * if expr is simple AND prepared in current transaction,
	 * expr_simple_state and expr_simple_in_use are valid. Test validity by
	 * seeing if expr_simple_lxid matches current LXID.  (If not,
	 * expr_simple_state probably points at garbage!)
	 */
	ExprState  *expr_simple_state pg_node_attr(read_write_ignore, equal_ignore, read_as(NULL));	   /* eval tree for expr_simple_expr */
	bool		expr_simple_in_use pg_node_attr(read_write_ignore, equal_ignore, read_as(false));  /* true if eval tree is active */
	LocalTransactionId expr_simple_lxid pg_node_attr(read_write_ignore, equal_ignore, read_as(0)); /* lxid of cur. transaction */ /* read_as(InvalidLocalTransactionId)*/

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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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

	Datum		value pg_node_attr(read_write_ignore, read_as(0));
	bool		isnull pg_node_attr(read_write_ignore, read_as(true));
	bool		freeval pg_node_attr(read_write_ignore, read_as(false));

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
	pg_node_attr(custom_read_write, no_copy, no_query_jumble)
	NodeTag		type;
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
	TupleDesc	rowtupdesc pg_node_attr(read_write_ignore, read_as(NULL));

	int			nfields;
	char	  **fieldnames pg_node_attr(array_size(nfields));
	int		   *varnos pg_node_attr(array_size(nfields));
} PLtsql_row;

/*
 * Record variable (any composite type, including RECORD)
 */
typedef struct PLtsql_rec
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	ExpandedRecordHeader *erh pg_node_attr(read_write_ignore, read_as(NULL));
} PLtsql_rec;

/*
 * Table variable
 */
typedef struct PLtsql_tbl
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(custom_read_write, no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
    pg_node_attr(custom_read_write, no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
} PLtsql_stmt;

/*
 * One EXCEPTION condition name
 */
typedef struct PLtsql_condition
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	int			sqlerrstate;	/* SQLSTATE code */
	char	   *condname;		/* condition name (for debugging) */
	struct PLtsql_condition *next;
} PLtsql_condition;

/*
 * EXCEPTION block
 */
typedef struct PLtsql_exception_block
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	int			sqlstate_varno;
	int			sqlerrm_varno;
	List	   *exc_list;		/* List of WHEN clauses */
} PLtsql_exception_block;

/*
 * One EXCEPTION ... WHEN clause
 */
typedef struct PLtsql_exception
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	int			lineno;
	PLtsql_condition *conditions;
	List	   *action;			/* List of statements */
} PLtsql_exception;

/*
 * Block of statements
 */
typedef struct PLtsql_stmt_block
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *label;
	List	   *body;			/* List of statements */
	int			n_initvars;		/* Length of initvarnos[] */
	int		   *initvarnos pg_node_attr(array_size(n_initvars));		/* dnos of variables declared in this block */
	PLtsql_exception_block *exceptions;
} PLtsql_stmt_block;

/*
 * Assign statement
 */
typedef struct PLtsql_stmt_assign
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *expr;
} PLtsql_stmt_perform;

/*
 * CALL statement
 */
typedef struct PLtsql_stmt_call
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
} PLtsql_stmt_commit;

/*
 * ROLLBACK statement
 */
typedef struct PLtsql_stmt_rollback
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
} PLtsql_stmt_rollback;

/*
 * SET statement
 */
typedef struct PLtsql_stmt_set
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *expr;
} PLtsql_stmt_set;

/*
 * GET DIAGNOSTICS item
 */
typedef struct PLtsql_diag_item
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_getdiag_kind kind;	/* id for diagnostic value desired */
	int			target;			/* where to assign it */
} PLtsql_diag_item;

/*
 * GET DIAGNOSTICS statement
 */
typedef struct PLtsql_stmt_getdiag
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	int			lineno;
	PLtsql_expr *cond;			/* boolean expression for this case */
	List	   *stmts;			/* List of statements */
} PLtsql_if_elsif;

/*
 * CASE statement
 */
typedef struct PLtsql_stmt_case
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	int			lineno;
	PLtsql_expr *expr;			/* boolean expression for this case */
	List	   *stmts;			/* List of statements */
} PLtsql_case_when;

/*
 * Unconditional LOOP statement
 */
typedef struct PLtsql_stmt_loop
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
	int			curvar;
} PLtsql_stmt_close;

/*
 * EXIT or CONTINUE statement
 */
typedef struct PLtsql_stmt_exit
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
 * DBCC statement — nodetag_only because PLtsql_dbcc_stmt_data is a union
 * that gen_node_support.pl cannot parse. Only the NodeTag enum is generated.
 * Procedures containing DBCC will fall back to ANTLR parse.
 */
typedef struct PLtsql_stmt_dbcc
{
	pg_node_attr(nodetag_only)
	NodeTag		type;
	PLtsql_stmt_type	cmd_type;
	int	lineno;
	PLtsql_dbcc_stmt_type	dbcc_stmt_type;
} PLtsql_stmt_dbcc;

/*
 * RETURN statement
 */
typedef struct PLtsql_stmt_return
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_raise_option_type opt_type;
	PLtsql_expr *expr;
} PLtsql_raise_option;

/*
 *	Grant Connect stmt
 */
typedef struct PLtsql_stmt_grantdb
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
	char	   *db_name;
	char	   *new_owner_name;  /* Login name for new owner */
} PLtsql_stmt_change_dbowner;

typedef struct PLtsql_stmt_alter_db
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type	cmd_type;
	int			lineno;
	char			*function_name;
	bool			is_create;
	bool			is_right;
	PLtsql_type		*datatype;
	List			*args;		/* the arguments (list of exprs) */
	char			*collation;
} PLtsql_stmt_partition_function;

/*
 * Partition Scheme
 */
typedef struct PLtsql_stmt_partition_scheme
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *cond;
	PLtsql_expr *message;
} PLtsql_stmt_assert;

typedef struct PLtsql_txn_data
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	TransactionStmtKind stmt_kind;	/* Commit or rollback */ /*TODO: is it exec only?*/
	char	   *txn_name;		/* Transaction name */
	PLtsql_expr *txn_name_expr; /* Transaction name variable */
} PLtsql_txn_data;

/*
 * Generic SQL statement to execute
 */
typedef struct PLtsql_stmt_execsql
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	bool		is_ddl;			/* DDL statement? */
	char	   *schema_name;	/* Schema specified */
	char	   *db_name;		/* db_name: only for cross db query */
	bool		is_create_view; /* CREATE VIEW? */
	bool		is_set_tran_isolation; /* SET TRANSACTION ISOLATION? */
	char	   *original_query; /* Only for batch level statement. */
	bool        is_schemabinding; /* Is schema binding? */
} PLtsql_stmt_execsql;

/*
 * SET statement to change EXPLAIN MODE
 * The main reason for this PLtsql statement is
 * to turn off EXPLAIN ONLY MODE while it is on.
 */
typedef struct PLtsql_stmt_set_explain_mode
{
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
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
	pg_node_attr(no_copy, no_query_jumble)
	NodeTag		type;
	PLtsql_stmt_type cmd_type;
	int			lineno;
	PLtsql_expr *query;			/* string expression */
	bool		into;			/* INTO supplied? */
	bool		strict;			/* INTO STRICT flag */
	PLtsql_variable *target;	/* INTO target (record or row) */
	List	   *params;			/* USING expressions */
} PLtsql_stmt_dynexecute;


