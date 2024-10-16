/*
 *
 * pltsql_ruleutils.c
 *    Functions to de-parse TSQL object definition from
 *    stored expressions/querytrees
 *
 */

#include "postgres.h"

#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>
#include "pltsql.h"

#include "access/amapi.h"
#include "access/htup_details.h"
#include "access/relation.h"
#include "access/sysattr.h"
#include "access/table.h"
#include "catalog/pg_aggregate.h"
#include "catalog/pg_am.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_constraint.h"
#include "catalog/pg_depend.h"
#include "catalog/pg_language.h"
#include "catalog/pg_opclass.h"
#include "catalog/pg_operator.h"
#include "catalog/pg_partitioned_table.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_statistic_ext.h"
#include "catalog/pg_trigger.h"
#include "catalog/pg_type.h"
#include "commands/defrem.h"
#include "commands/tablespace.h"
#include "common/keywords.h"
#include "executor/spi.h"
#include "funcapi.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "nodes/pathnodes.h"
#include "optimizer/optimizer.h"
#include "parser/parse_agg.h"
#include "parser/parse_func.h"
#include "parser/parse_node.h"
#include "parser/parse_oper.h"
#include "parser/parser.h"
#include "parser/parsetree.h"
#include "rewrite/rewriteHandler.h"
#include "rewrite/rewriteManip.h"
#include "rewrite/rewriteSupport.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/guc.h"
#include "utils/hsearch.h"
#include "utils/lsyscache.h"
#include "utils/partcache.h"
#include "utils/rel.h"
#include "utils/ruleutils.h"
#include "utils/snapmgr.h"
#include "utils/syscache.h"
#include "utils/typcache.h"
#include "utils/varlena.h"
#include "utils/xml.h"

#include "catalog.h"
#include "pltsql.h"

/* ----------
 * Pretty formatting constants
 * ----------
 */

/* Indent counts */
#define PRETTYINDENT_STD		8
#define PRETTYINDENT_JOIN		4
#define PRETTYINDENT_VAR		4

#define PRETTYINDENT_LIMIT		40	/* wrap limit */

/* Pretty flags */
#define PRETTYFLAG_PAREN		0x0001
#define PRETTYFLAG_INDENT		0x0002
#define PRETTYFLAG_SCHEMA		0x0004

/* Default line length for pretty-print wrapping: 0 means wrap always */
#define WRAP_COLUMN_DEFAULT		0

/* macros to test if pretty action needed */
#define PRETTY_PAREN(context)	((context)->prettyFlags & PRETTYFLAG_PAREN)
#define PRETTY_INDENT(context)	((context)->prettyFlags & PRETTYFLAG_INDENT)
#define PRETTY_SCHEMA(context)	((context)->prettyFlags & PRETTYFLAG_SCHEMA)

/* ----------
 * Local data types
 * ----------
 */

/* Context info needed for invoking a recursive querytree display routine */
typedef struct
{
	StringInfo	buf;			/* output buffer to append to */
	List	   *namespaces;		/* List of deparse_namespace nodes */
	List	   *windowClause;	/* Current query level's WINDOW clause */
	List	   *windowTList;	/* targetlist for resolving WINDOW clause */
	int			prettyFlags;	/* enabling of pretty-print functions */
	int			wrapColumn;		/* max line length, or -1 for no limit */
	int			indentLevel;	/* current indent level for pretty-print */
	bool		varprefix;		/* true to print prefixes on Vars */
	ParseExprKind special_exprkind; /* set only for exprkinds needing special
									 * handling */
	Bitmapset  *appendparents;	/* if not null, map child Vars of these relids
								 * back to the parent rel */
} deparse_context;

/*
 * Each level of query context around a subtree needs a level of Var namespace.
 * A Var having varlevelsup=N refers to the N'th item (counting from 0) in
 * the current context's namespaces list.
 *
 * rtable is the list of actual RTEs from the Query or PlannedStmt.
 * rtable_names holds the alias name to be used for each RTE (either a C
 * string, or NULL for nameless RTEs such as unnamed joins).
 * rtable_columns holds the column alias names to be used for each RTE.
 *
 * subplans is a list of Plan trees for SubPlans and CTEs (it's only used
 * in the PlannedStmt case).
 * ctes is a list of CommonTableExpr nodes (only used in the Query case).
 * appendrels, if not null (it's only used in the PlannedStmt case), is an
 * array of AppendRelInfo nodes, indexed by child relid.  We use that to map
 * child-table Vars to their inheritance parents.
 *
 * In some cases we need to make names of merged JOIN USING columns unique
 * across the whole query, not only per-RTE.  If so, unique_using is true
 * and using_names is a list of C strings representing names already assigned
 * to USING columns.
 *
 * When deparsing plan trees, there is always just a single item in the
 * deparse_namespace list (since a plan tree never contains Vars with
 * varlevelsup > 0).  We store the Plan node that is the immediate
 * parent of the expression to be deparsed, as well as a list of that
 * Plan's ancestors.  In addition, we store its outer and inner subplan nodes,
 * as well as their targetlists, and the index tlist if the current plan node
 * might contain INDEX_VAR Vars.  (These fields could be derived on-the-fly
 * from the current Plan node, but it seems notationally clearer to set them
 * up as separate fields.)
 */
typedef struct
{
	List	   *rtable;			/* List of RangeTblEntry nodes */
	List	   *rtable_names;	/* Parallel list of names for RTEs */
	List	   *rtable_columns; /* Parallel list of deparse_columns structs */
	List	   *subplans;		/* List of Plan trees for SubPlans */
	List	   *ctes;			/* List of CommonTableExpr nodes */
	AppendRelInfo **appendrels; /* Array of AppendRelInfo nodes, or NULL */
	/* Workspace for column alias assignment: */
	bool		unique_using;	/* Are we making USING names globally unique */
	List	   *using_names;	/* List of assigned names for USING columns */
	/* Remaining fields are used only when deparsing a Plan tree: */
	Plan	   *plan;			/* immediate parent of current expression */
	List	   *ancestors;		/* ancestors of plan */
	Plan	   *outer_plan;		/* outer subnode, or NULL if none */
	Plan	   *inner_plan;		/* inner subnode, or NULL if none */
	List	   *outer_tlist;	/* referent for OUTER_VAR Vars */
	List	   *inner_tlist;	/* referent for INNER_VAR Vars */
	List	   *index_tlist;	/* referent for INDEX_VAR Vars */
	/* Special namespace representing a function signature: */
	char	   *funcname;
	int			numargs;
	char	  **argnames;
} deparse_namespace;

/*
 * Per-relation data about column alias names.
 *
 * Selecting aliases is unreasonably complicated because of the need to dump
 * rules/views whose underlying tables may have had columns added, deleted, or
 * renamed since the query was parsed.  We must nonetheless print the rule/view
 * in a form that can be reloaded and will produce the same results as before.
 *
 * For each RTE used in the query, we must assign column aliases that are
 * unique within that RTE.  SQL does not require this of the original query,
 * but due to factors such as *-expansion we need to be able to uniquely
 * reference every column in a decompiled query.  As long as we qualify all
 * column references, per-RTE uniqueness is sufficient for that.
 *
 * However, we can't ensure per-column name uniqueness for unnamed join RTEs,
 * since they just inherit column names from their input RTEs, and we can't
 * rename the columns at the join level.  Most of the time this isn't an issue
 * because we don't need to reference the join's output columns as such; we
 * can reference the input columns instead.  That approach can fail for merged
 * JOIN USING columns, however, so when we have one of those in an unnamed
 * join, we have to make that column's alias globally unique across the whole
 * query to ensure it can be referenced unambiguously.
 *
 * Another problem is that a JOIN USING clause requires the columns to be
 * merged to have the same aliases in both input RTEs, and that no other
 * columns in those RTEs or their children conflict with the USING names.
 * To handle that, we do USING-column alias assignment in a recursive
 * traversal of the query's jointree.  When descending through a JOIN with
 * USING, we preassign the USING column names to the child columns, overriding
 * other rules for column alias assignment.  We also mark each RTE with a list
 * of all USING column names selected for joins containing that RTE, so that
 * when we assign other columns' aliases later, we can avoid conflicts.
 *
 * Another problem is that if a JOIN's input tables have had columns added or
 * deleted since the query was parsed, we must generate a column alias list
 * for the join that matches the current set of input columns --- otherwise, a
 * change in the number of columns in the left input would throw off matching
 * of aliases to columns of the right input.  Thus, positions in the printable
 * column alias list are not necessarily one-for-one with varattnos of the
 * JOIN, so we need a separate new_colnames[] array for printing purposes.
 */
typedef struct
{
	/*
	 * colnames is an array containing column aliases to use for columns that
	 * existed when the query was parsed.  Dropped columns have NULL entries.
	 * This array can be directly indexed by varattno to get a Var's name.
	 *
	 * Non-NULL entries are guaranteed unique within the RTE, *except* when
	 * this is for an unnamed JOIN RTE.  In that case we merely copy up names
	 * from the two input RTEs.
	 *
	 * During the recursive descent in set_using_names(), forcible assignment
	 * of a child RTE's column name is represented by pre-setting that element
	 * of the child's colnames array.  So at that stage, NULL entries in this
	 * array just mean that no name has been preassigned, not necessarily that
	 * the column is dropped.
	 */
	int			num_cols;		/* length of colnames[] array */
	char	  **colnames;		/* array of C strings and NULLs */


	/*
	 * new_colnames is an array containing column aliases to use for columns
	 * that would exist if the query was re-parsed against the current
	 * definitions of its base tables.  This is what to print as the column
	 * alias list for the RTE.  This array does not include dropped columns,
	 * but it will include columns added since original parsing.  Indexes in
	 * it therefore have little to do with current varattno values.  As above,
	 * entries are unique unless this is for an unnamed JOIN RTE.  (In such an
	 * RTE, we never actually print this array, but we must compute it anyway
	 * for possible use in computing column names of upper joins.) The
	 * parallel array is_new_col marks which of these columns are new since
	 * original parsing.  Entries with is_new_col false must match the
	 * non-NULL colnames entries one-for-one.
	 */
	int			num_new_cols;	/* length of new_colnames[] array */
	char	  **new_colnames;	/* array of C strings */
	bool	   *is_new_col;		/* array of bool flags */

	/* This flag tells whether we should actually print a column alias list */
	bool		printaliases;

	/* This list has all names used as USING names in joins above this RTE */
	List	   *parentUsing;	/* names assigned to parent merged columns */

	/*
	 * If this struct is for a JOIN RTE, we fill these fields during the
	 * set_using_names() pass to describe its relationship to its child RTEs.
	 *
	 * leftattnos and rightattnos are arrays with one entry per existing
	 * output column of the join (hence, indexable by join varattno).  For a
	 * simple reference to a column of the left child, leftattnos[i] is the
	 * child RTE's attno and rightattnos[i] is zero; and conversely for a
	 * column of the right child.  But for merged columns produced by JOIN
	 * USING/NATURAL JOIN, both leftattnos[i] and rightattnos[i] are nonzero.
	 * Note that a simple reference might be to a child RTE column that's been
	 * dropped; but that's OK since the column could not be used in the query.
	 *
	 * If it's a JOIN USING, usingNames holds the alias names selected for the
	 * merged columns (these might be different from the original USING list,
	 * if we had to modify names to achieve uniqueness).
	 */
	int			leftrti;		/* rangetable index of left child */
	int			rightrti;		/* rangetable index of right child */
	int		   *leftattnos;		/* left-child varattnos of join cols, or 0 */
	int		   *rightattnos;	/* right-child varattnos of join cols, or 0 */
	List	   *usingNames;		/* names assigned to merged columns */
} deparse_columns;

/* This macro is analogous to rt_fetch(), but for deparse_columns structs */
#define deparse_columns_fetch(rangetable_index, dpns) \
	((deparse_columns *) list_nth((dpns)->rtable_columns, (rangetable_index)-1))

/* Callback signature for resolve_special_varno() */
typedef void (*rsv_callback) (Node *node, deparse_context *context,
							  void *callback_arg);

/* ----------
 * Local functions
 *
 * Most of these functions used to use fixed-size buffers to build their
 * results.  Now, they take an (already initialized) StringInfo object
 * as a parameter, and append their text output to its contents.
 * ----------
 */

static char *deparse_expression_pretty(Node *expr, List *dpcontext,
									   bool forceprefix, bool showimplicit,
									   int prettyFlags, int startIndent);
static char *generate_qualified_relation_name(Oid relid);
static char *generate_qualified_type_name(Oid typid);
static void get_rule_expr(Node *node, deparse_context *context,
						  bool showimplicit);
static char *get_variable(Var *var, int levelsup, bool istoplevel,
						  deparse_context *context);
static void get_special_variable(Node *node, deparse_context *context,
								 void *callback_arg);
static void resolve_special_varno(Node *node, deparse_context *context,
								  rsv_callback callback, void *callback_arg);
static void simple_quote_literal(StringInfo buf, const char *val);
static void get_const_expr(Const *constval, deparse_context *context,
						   int showtype);
static void get_const_collation(Const *constval, deparse_context *context);
static void get_coercion_expr(Node *arg, deparse_context *context,
							  Oid resulttype, int32 resulttypmod,
							  Node *parentNode);
static void set_deparse_plan(deparse_namespace *dpns, Plan *plan);
static void get_oper_expr(OpExpr *expr, deparse_context *context);
static void get_func_expr(FuncExpr *expr, deparse_context *context,
						  bool showimplicit);
static char *get_relation_name(Oid relid);
static char *generate_operator_name(Oid operid, Oid arg1, Oid arg2);
static char *generate_function_name(Oid funcid, int nargs,
									List *argnames, Oid *argtypes,
									bool has_variadic, bool *use_variadic_p,
									ParseExprKind special_exprkind);
static void push_child_plan(deparse_namespace *dpns, Plan *plan,
							deparse_namespace *save_dpns);
static void pop_child_plan(deparse_namespace *dpns,
						   deparse_namespace *save_dpns);
static const char *get_simple_binary_op_name(OpExpr *expr);
static bool isSimpleNode(Node *node, Node *parentNode, int prettyFlags);
static Plan *find_recursive_union(deparse_namespace *dpns,
								  WorkTableScan *wtscan);
static text *string_to_text(char *str);
static char *tsql_get_constraintdef_worker(Oid constraintId, bool fullCommand,
										   int prettyFlags, bool missing_ok);
static text *tsql_get_expr_worker(text *expr, Oid relid, const char *relname,
								  int prettyFlags);
static char *tsql_printTypmod(const char *typname, int32 typmod, Oid typmodout);
int			tsql_print_function_arguments(StringInfo buf, HeapTuple proctup,
										  bool print_table_args, bool print_defaults, int **typmod_arr_arg, bool *has_tvp);
char	   *tsql_quote_qualified_identifier(const char *qualifier, const char *ident);
const char *tsql_quote_identifier(const char *ident);
char	   *generate_tsql_collation_name(Oid collOid);
int			adjustTypmod(Oid oid, int typmod);
static void tsql_print_function_rettype(StringInfo buf, HeapTuple proctup,
										int **typmod_arr_ret, int number_args);
extern void probin_json_reader(text *probin, int **typmod_arr_p, int typmod_arr_len);

PG_FUNCTION_INFO_V1(tsql_get_constraintdef);
/*
 * tsql_get_constraintdef
 *
 * Returns the definition for the constraint, ie, everything that needs to
 * appear after "ALTER TABLE ... ADD CONSTRAINT <constraintname>".
 */
Datum
tsql_get_constraintdef(PG_FUNCTION_ARGS)
{
	Oid			constraintId = PG_GETARG_OID(0);
	int			prettyFlags;
	char	   *res;

	prettyFlags = PRETTYFLAG_INDENT;

	res = tsql_get_constraintdef_worker(constraintId, false, prettyFlags, true);

	if (res == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(string_to_text(res));
}

PG_FUNCTION_INFO_V1(tsql_get_expr);

/* ----------
 * tsql_get_expr          - Decompile an expression tree
 *
 * Input: an expression tree in nodeToString form, and a relation OID
 *
 * Output: reverse-listed expression
 *
 * Currently, the expression can only refer to a single relation, namely
 * the one specified by the second parameter.  This is sufficient for
 * partial indexes, column default expressions, etc.  We also support
 * Var-free expressions, for which the OID can be InvalidOid.
 * ----------
 */

Datum
tsql_get_expr(PG_FUNCTION_ARGS)
{
	text	   *expr = PG_GETARG_TEXT_PP(0);
	Oid			relid = PG_GETARG_OID(1);
	int			prettyFlags;
	char	   *relname;

	prettyFlags = PRETTYFLAG_INDENT;

	if (OidIsValid(relid))
	{
		/* Get the name for the relation */
		relname = get_rel_name(relid);
	}
	else
	{
		relname = NULL;
	}

	/*
	 * If the relname is NULL, don't throw an error, just return NULL.  This
	 * is a bit questionable, but it's what we've done historically, and it
	 * can help avoid unwanted failures when examining catalog entries for
	 * just-deleted relations.
	 */
	if (relname == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(tsql_get_expr_worker(expr, relid, relname, prettyFlags));
}

static text *
tsql_get_expr_worker(text *expr, Oid relid, const char *relname, int prettyFlags)
{
	Node	   *node;
	List	   *context;
	char	   *exprstr;

	/* Convert input TEXT object to C string */
	exprstr = text_to_cstring(expr);

	/* Convert expression to node tree */
	node = (Node *) stringToNode(exprstr);

	pfree(exprstr);

	/* Prepare deparse context if needed */
	if (OidIsValid(relid))
		context = deparse_context_for(relname, relid);
	else
		context = NIL;
	/* Deparse */
	return string_to_text(deparse_expression_pretty(node, context, false, false, prettyFlags, 0));
}

/*
 * tsql_get_functiondef
 *		Returns the complete "CREATE OR REPLACE FUNCTION ..." statement for
 *		the specified function.
 *
 * Note: if you change the output format of this function, be careful not
 * to break psql's rules (in \ef and \sf) for identifying the start of the
 * function body.  To wit: the function body starts on a line that begins
 * with "AS ", and no preceding line will look like that.
 */
PG_FUNCTION_INFO_V1(tsql_get_functiondef);

Datum
tsql_get_functiondef(PG_FUNCTION_ARGS)
{
	Oid			funcid = PG_GETARG_OID(0);
	StringInfoData buf;
	HeapTuple	proctup;
	Form_pg_proc proc;
	bool		isfunction;
	Datum		tmp;
	bool		isnull;
	const char *prosrc;
	const char *name;
	const char *nsp;
	const char *nnsp;
	bool		has_tvp = false;
	int		   *typmod_arr = NULL;
	int			number_args;
	char	   *probin_c = NULL;

	/* Look up the function */
	proctup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcid));
	if (!HeapTupleIsValid(proctup))
		PG_RETURN_NULL();

	initStringInfo(&buf);

	proc = (Form_pg_proc) GETSTRUCT(proctup);
	if (strcmp(get_language_name(proc->prolang, false), "pltsql") != 0)
	{
		ReleaseSysCache(proctup);
		PG_RETURN_NULL();
	}
	name = NameStr(proc->proname);

	isfunction = (proc->prokind != PROKIND_PROCEDURE);

	/*
	 * We always qualify the function name, to ensure the right function gets
	 * replaced.
	 */
	nsp = get_namespace_name(proc->pronamespace);
	nnsp = get_logical_schema_name(nsp, true);
	appendStringInfo(&buf, "CREATE %s %s",
					 isfunction ? "FUNCTION" : "PROCEDURE",
					 tsql_quote_qualified_identifier(nnsp, name));
	if (isfunction || proc->pronargs > 0)
		appendStringInfoString(&buf, "(");

	/*
	 * we will not pfree name because as we can see name =
	 * NameStr(proc->proname) here we are not allocating extra space for name,
	 * we’re just using proc-> proname. also at the end, we’re releasing
	 * proctup (that will free proc->proname).
	 */
	pfree((char *) nsp);
	if (nnsp)
		pfree((char *) nnsp);

	tmp = SysCacheGetAttr(PROCOID, proctup, Anum_pg_proc_probin, &isnull);

	if (!isnull)
		probin_c = TextDatumGetCString(tmp);
	if (!probin_c || probin_c[0] != '{')
		PG_RETURN_NULL();

	number_args = proc->pronargs;
	if (isfunction)
		number_args++;

	probin_json_reader(cstring_to_text(probin_c), &typmod_arr, number_args);
	pfree(probin_c);
	(void) tsql_print_function_arguments(&buf, proctup, false, true, &typmod_arr, &has_tvp);
	/* TODO: In case of Table Valued Functions, return NULL. */
	if (has_tvp)
		PG_RETURN_NULL();

	if (isfunction || proc->pronargs > 0)
		appendStringInfoString(&buf, ")");
	if (isfunction)
	{
		appendStringInfoString(&buf, " RETURNS ");
		tsql_print_function_rettype(&buf, proctup, &typmod_arr, number_args);
	}
	if (typmod_arr)
		pfree(typmod_arr);

	/* Emit some miscellaneous options on one line */
	if (proc->proisstrict)
		appendStringInfoString(&buf, " WITH RETURNS NULL ON NULL INPUT");

	/* And finally the function definition ... */
	(void) SysCacheGetAttr(PROCOID, proctup, Anum_pg_proc_prosqlbody, &isnull);

	appendStringInfoString(&buf, " AS ");
	tmp = SysCacheGetAttr(PROCOID, proctup, Anum_pg_proc_prosrc, &isnull);
	prosrc = TextDatumGetCString(tmp);
	appendStringInfoString(&buf, prosrc);

	ReleaseSysCache(proctup);

	pfree((char *) prosrc);

	PG_RETURN_TEXT_P(string_to_text(buf.data));
}

PG_FUNCTION_INFO_V1(tsql_get_returnTypmodValue);
/*
 * function that will return the typmod value of return type
 */
Datum
tsql_get_returnTypmodValue(PG_FUNCTION_ARGS)
{
	Oid			funcid = PG_GETARG_OID(0);
	HeapTuple	proctup;
	Form_pg_proc proc;
	bool		isfunction;
	Datum		tmp;
	bool		isnull;
	char	   *probin_c = NULL;
	int		   *typmod_arr = NULL;
	int			number_args;

	proctup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcid));
	if (!HeapTupleIsValid(proctup))
		PG_RETURN_INT32(-1);

	proc = (Form_pg_proc) GETSTRUCT(proctup);

	isfunction = (proc->prokind != PROKIND_PROCEDURE);

	if (!isfunction)
	{
		ReleaseSysCache(proctup);
		PG_RETURN_INT32(-1);
	}

	tmp = SysCacheGetAttr(PROCOID, proctup, Anum_pg_proc_probin, &isnull);

	if (!isnull)
		probin_c = TextDatumGetCString(tmp);
	if (!probin_c || probin_c[0] != '{')
		PG_RETURN_INT32(-1);

	number_args = proc->pronargs;
	number_args++;

	probin_json_reader(cstring_to_text(probin_c), &typmod_arr, number_args);
	pfree(probin_c);
	if (typmod_arr[number_args - 1] != -1)
		typmod_arr[number_args - 1] += adjustTypmod(proc->prorettype, typmod_arr[number_args - 1]);

	ReleaseSysCache(proctup);
	PG_RETURN_INT32(typmod_arr[number_args - 1]);

}

/*
 * As of 9.4, we now use an MVCC snapshot for this.
 */
static char *
tsql_get_constraintdef_worker(Oid constraintId, bool fullCommand,
							  int prettyFlags, bool missing_ok)
{
	HeapTuple	tup;
	Form_pg_constraint conForm;
	StringInfoData buf;
	SysScanDesc scandesc;
	ScanKeyData scankey[1];
	Snapshot	snapshot = RegisterSnapshot(GetTransactionSnapshot());
	Relation	relation = table_open(ConstraintRelationId, AccessShareLock);

	ScanKeyInit(&scankey[0],
				Anum_pg_constraint_oid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(constraintId));

	scandesc = systable_beginscan(relation,
								  ConstraintOidIndexId,
								  true,
								  snapshot,
								  1,
								  scankey);

	/*
	 * We later use the tuple with SysCacheGetAttr() as if we had obtained it
	 * via SearchSysCache, which works fine.
	 */
	tup = systable_getnext(scandesc);

	UnregisterSnapshot(snapshot);

	if (!HeapTupleIsValid(tup))
	{
		if (missing_ok)
		{
			systable_endscan(scandesc);
			table_close(relation, AccessShareLock);
			return NULL;
		}
		elog(ERROR, "could not find tuple for constraint %u", constraintId);
	}

	conForm = (Form_pg_constraint) GETSTRUCT(tup);

	initStringInfo(&buf);

	if (fullCommand)
	{
		if (OidIsValid(conForm->conrelid))
		{
			/*
			 * Currently, callers want ALTER TABLE (without ONLY) for CHECK
			 * constraints, and other types of constraints don't inherit
			 * anyway so it doesn't matter whether we say ONLY or not. Someday
			 * we might need to let callers specify whether to put ONLY in the
			 * command.
			 */
			appendStringInfo(&buf, "ALTER TABLE %s ADD CONSTRAINT %s ",
							 generate_qualified_relation_name(conForm->conrelid),
							 tsql_quote_identifier(NameStr(conForm->conname)));
		}
		else
		{
			/* Must be a domain constraint */
			Assert(OidIsValid(conForm->contypid));
			appendStringInfo(&buf, "ALTER DOMAIN %s ADD CONSTRAINT %s ",
							 generate_qualified_type_name(conForm->contypid),
							 tsql_quote_identifier(NameStr(conForm->conname)));
		}
	}

	switch (conForm->contype)
	{
		case CONSTRAINT_CHECK:
			{
				Datum		val;
				bool		isnull;
				char	   *conbin;
				char	   *consrc;
				Node	   *expr;
				List	   *context;

				/* Fetch constraint expression in parsetree form */
				val = SysCacheGetAttr(CONSTROID, tup,
									  Anum_pg_constraint_conbin, &isnull);
				if (isnull)
					elog(ERROR, "null conbin for constraint %u",
						 constraintId);

				conbin = TextDatumGetCString(val);
				expr = stringToNode(conbin);

				/* Set up deparsing context for Var nodes in constraint */
				if (conForm->conrelid != InvalidOid)
				{
					/* relation constraint */
					context = deparse_context_for(get_relation_name(conForm->conrelid),
												  conForm->conrelid);
				}
				else
				{
					/* domain constraint --- can't have Vars */
					context = NIL;
				}

				consrc = deparse_expression_pretty(expr, context, false, false,
												   prettyFlags, 0);

				/*
				 * Now emit the constraint definition, adding NO INHERIT if
				 * necessary.
				 *
				 * There are cases where the constraint expression will be
				 * fully parenthesized and we don't need the outer parens ...
				 * but there are other cases where we do need 'em.  Be
				 * conservative for now.
				 *
				 * Note that simply checking for leading '(' and trailing ')'
				 * would NOT be good enough, consider "(x > 0) AND (y > 0)".
				 */
				appendStringInfo(&buf, "(%s)%s",
								 consrc,
								 conForm->connoinherit ? " NO INHERIT" : "");
				break;
			}
		default:
			elog(ERROR, "invalid constraint type \"%c\"", conForm->contype);
			break;
	}

	/* Cleanup */
	systable_endscan(scandesc);
	table_close(relation, AccessShareLock);

	return buf.data;
}

/*
 * Guts of pg_get_function_result: append the function's return type
 * to the specified buffer.
 */
static void
tsql_print_function_rettype(StringInfo buf, HeapTuple proctup, int **typmod_arr_ret, int number_args)
{
	Form_pg_proc proc = (Form_pg_proc) GETSTRUCT(proctup);
	int			ntabargs = 0;
	StringInfoData rbuf;
	bool		has_tvp = false;

	initStringInfo(&rbuf);

	if (proc->proretset)
	{
		/* It might be a table function; try to print the arguments */
		appendStringInfoString(&rbuf, "TABLE(");
		ntabargs = tsql_print_function_arguments(&rbuf, proctup, true, false, NULL, &has_tvp);
		if (ntabargs > 0)
			appendStringInfoChar(&rbuf, ')');
		else
			resetStringInfo(&rbuf);
	}

	if (ntabargs == 0)
	{
		/* Not a table function, so do the normal thing */
		if (proc->proretset)
			appendStringInfoString(&rbuf, "SETOF ");
		if ((*typmod_arr_ret)[number_args - 1] != -1)
			(*typmod_arr_ret)[number_args - 1] += adjustTypmod(proc->prorettype, (*typmod_arr_ret)[number_args - 1]);
		appendStringInfoString(&rbuf, tsql_format_type_extended(proc->prorettype, (*typmod_arr_ret)[number_args - 1], FORMAT_TYPE_TYPEMOD_GIVEN));
	}

	appendBinaryStringInfo(buf, rbuf.data, rbuf.len);
	pfree(rbuf.data);
}

/*
 * append the desired subset of arguments to buf.  We print only TABLE
 * arguments when print_table_args is true, and all the others when it's false.
 * We print argument defaults only if print_defaults is true.
 * Function return value is the number of arguments printed.
 */
int
tsql_print_function_arguments(StringInfo buf, HeapTuple proctup,
							  bool print_table_args, bool print_defaults, int **typmod_arr_arg, bool *has_tvp)
{
	Form_pg_proc proc = (Form_pg_proc) GETSTRUCT(proctup);
	HeapTuple	bbffunctuple = NULL;
	int			numargs;
	Oid		   *argtypes;
	char	  **argnames;
	char	   *argmodes;
	int			insertorderbyat = -1;
	int			argsprinted;
	int			inputargno;
	bool		default_positions_available = false;
	int			nlackdefaults;
	List	   *argdefaults = NIL;
	List	   *defaultpositions = NIL;
	ListCell   *nextargdefault = NULL;
	ListCell   *nextdefaultposition = NULL;
	int			i;

	numargs = get_func_arg_info(proctup,
								&argtypes, &argnames, &argmodes);

	nlackdefaults = numargs;
	if (print_defaults && proc->pronargdefaults > 0)
	{
		Datum		proargdefaults;
		bool		isnull;

		proargdefaults = SysCacheGetAttr(PROCOID, proctup,
										 Anum_pg_proc_proargdefaults,
										 &isnull);
		if (!isnull)
		{
			char	   *str;

			str = TextDatumGetCString(proargdefaults);
			argdefaults = castNode(List, stringToNode(str));
			pfree(str);
			nextargdefault = list_head(argdefaults);
			/* nlackdefaults counts only *input* arguments lacking defaults */
			nlackdefaults = proc->pronargs - list_length(argdefaults);
		}

		bbffunctuple = get_bbf_function_tuple_from_proctuple(proctup);

		if (HeapTupleIsValid(bbffunctuple))
		{
			Datum		arg_default_positions;
			char	   *str;

			/* Fetch default positions */
			arg_default_positions = SysCacheGetAttr(PROCNAMENSPSIGNATURE,
													bbffunctuple,
													Anum_bbf_function_ext_default_positions,
													&isnull);

			if (!isnull)
			{
				str = TextDatumGetCString(arg_default_positions);
				defaultpositions = castNode(List, stringToNode(str));
				nextdefaultposition = list_head(defaultpositions);
				default_positions_available = true;
				pfree(str);
			}
			else
				heap_freetuple(bbffunctuple);
		}
	}

	argsprinted = 0;
	inputargno = 0;
	for (i = 0; i < numargs; i++)
	{
		Oid			argtype = argtypes[i];
		char	   *argname = argnames ? argnames[i] : NULL;
		char		argmode = argmodes ? argmodes[i] : PROARGMODE_IN;
		const char *modename;
		bool		isinput;

		switch (argmode)
		{
			case PROARGMODE_IN:
				modename = "";
				isinput = true;
				break;
			case PROARGMODE_INOUT:
				modename = "OUTPUT ";
				isinput = true;
				break;
			case PROARGMODE_OUT:
				modename = "OUT ";
				isinput = false;
				break;
			case PROARGMODE_TABLE:
				*has_tvp = true;
				break;
			default:
				elog(ERROR, "invalid parameter mode '%c'", argmode);
				modename = NULL;	/* keep compiler quiet */
				isinput = false;
				break;
		}
		if (*has_tvp)
			break;

		if (isinput)
			inputargno++;		/* this is a 1-based counter */

		if (print_table_args != (argmode == PROARGMODE_TABLE))
			continue;

		if (argsprinted == insertorderbyat)
		{
			if (argsprinted)
				appendStringInfoChar(buf, ' ');
			appendStringInfoString(buf, "ORDER BY ");
		}
		else if (argsprinted)
			appendStringInfoString(buf, ", ");

		if (argname && argname[0])
			appendStringInfo(buf, "%s ", tsql_quote_identifier(argname));
		if ((*typmod_arr_arg)[i] != -1)
			(*typmod_arr_arg)[i] += adjustTypmod(argtype, (*typmod_arr_arg)[i]);
		appendStringInfoString(buf, tsql_format_type_extended(argtype, (*typmod_arr_arg)[i], FORMAT_TYPE_TYPEMOD_GIVEN));

		if (modename && strcmp(modename, "") != 0)
			appendStringInfo(buf, " %s", modename);

		if (print_defaults && isinput && default_positions_available)
		{
			if (nextdefaultposition != NULL)
			{
				int			position = intVal((Node *) lfirst(nextdefaultposition));
				Node	   *expr;

				Assert(nextargdefault != NULL);
				expr = (Node *) lfirst(nextargdefault);

				if (position == (inputargno - 1))
				{
					appendStringInfo(buf, "= %s",
									 deparse_expression(expr, NIL, false, false));
					nextdefaultposition = lnext(defaultpositions, nextdefaultposition);
					nextargdefault = lnext(argdefaults, nextargdefault);
				}
			}
		}
		else if (print_defaults && isinput && inputargno > nlackdefaults)
		{
			Node	   *expr;

			Assert(nextargdefault != NULL);
			expr = (Node *) lfirst(nextargdefault);
			nextargdefault = lnext(argdefaults, nextargdefault);

			appendStringInfo(buf, "= %s",
							 deparse_expression(expr, NIL, false, false));
		}
		argsprinted++;

		/* nasty hack: print the last arg twice for variadic ordered-set agg */
		if (argsprinted == insertorderbyat && i == numargs - 1)
		{
			i--;
			/* aggs shouldn't have defaults anyway, but just to be sure ... */
			print_defaults = false;
		}
	}

	if (default_positions_available)
		heap_freetuple(bbffunctuple);

	return argsprinted;
}

/*
 * generate_qualified_relation_name
 *		Compute the name to display for a relation specified by OID
 *
 * As above, but unconditionally schema-qualify the name.
 */
static char *
generate_qualified_relation_name(Oid relid)
{
	HeapTuple	tp;
	Form_pg_class reltup;
	char	   *relname;
	char	   *nspname;
	char	   *result;

	tp = SearchSysCache1(RELOID, ObjectIdGetDatum(relid));
	if (!HeapTupleIsValid(tp))
		elog(ERROR, "cache lookup failed for relation %u", relid);
	reltup = (Form_pg_class) GETSTRUCT(tp);
	relname = NameStr(reltup->relname);

	nspname = get_namespace_name(reltup->relnamespace);
	if (!nspname)
		elog(ERROR, "cache lookup failed for namespace %u",
			 reltup->relnamespace);

	result = tsql_quote_qualified_identifier(nspname, relname);

	ReleaseSysCache(tp);

	return result;
}

/*
 * generate_operator_name
 *		Compute the name to display for an operator specified by OID,
 *		given that it is being called with the specified actual arg types.
 *		(Arg types matter because of ambiguous-operator resolution rules.
 *		Pass InvalidOid for unused arg of a unary operator.)
 *
 * The result includes all necessary quoting and schema-prefixing,
 * plus the OPERATOR() decoration needed to use a qualified operator name
 * in an expression.
 */
static char *
generate_operator_name(Oid operid, Oid arg1, Oid arg2)
{
	StringInfoData buf;
	HeapTuple	opertup;
	Form_pg_operator operform;
	char	   *oprname;
	Operator	p_result;

	initStringInfo(&buf);

	opertup = SearchSysCache1(OPEROID, ObjectIdGetDatum(operid));
	if (!HeapTupleIsValid(opertup))
		elog(ERROR, "cache lookup failed for operator %u", operid);
	operform = (Form_pg_operator) GETSTRUCT(opertup);
	oprname = NameStr(operform->oprname);

	if (strcmp(oprname, "~~") == 0)
		oprname = "LIKE";


	/*
	 * The idea here is to schema-qualify only if the parser would fail to
	 * resolve the correct operator given the unqualified op name with the
	 * specified argtypes.
	 */
	switch (operform->oprkind)
	{
		case 'b':
			p_result = oper(NULL, list_make1(makeString(oprname)), arg1, arg2,
							true, -1);
			break;
		case 'l':
			p_result = left_oper(NULL, list_make1(makeString(oprname)), arg2,
								 true, -1);
			break;
		default:
			elog(ERROR, "unrecognized oprkind: %d", operform->oprkind);
			p_result = NULL;	/* keep compiler quiet */
			break;
	}

	appendStringInfoString(&buf, oprname);

	if (p_result != NULL)
		ReleaseSysCache(p_result);

	ReleaseSysCache(opertup);

	return buf.data;
}

/*
 * generate_qualified_type_name
 *		Compute the name to display for a type specified by OID
 *
 * This is different from format_type_be() in that we unconditionally
 * schema-qualify the name.  That also means no special syntax for
 * SQL-standard type names ... although in current usage, this should
 * only get used for domains, so such cases wouldn't occur anyway.
 */
static char *
generate_qualified_type_name(Oid typid)
{
	HeapTuple	tp;
	Form_pg_type typtup;
	char	   *typname;
	char	   *nspname;
	char	   *result;

	tp = SearchSysCache1(TYPEOID, ObjectIdGetDatum(typid));
	if (!HeapTupleIsValid(tp))
		elog(ERROR, "cache lookup failed for type %u", typid);
	typtup = (Form_pg_type) GETSTRUCT(tp);
	typname = NameStr(typtup->typname);

	nspname = get_namespace_name(typtup->typnamespace);
	if (!nspname)
		elog(ERROR, "cache lookup failed for namespace %u",
			 typtup->typnamespace);

	result = tsql_quote_qualified_identifier(nspname, typname);

	ReleaseSysCache(tp);

	return result;
}

/* ----------
 * deparse_expression_pretty	- General utility for deparsing expressions
 *
 * expr is the node tree to be deparsed.  It must be a transformed expression
 * tree (ie, not the raw output of gram.y).
 *
 * dpcontext is a list of deparse_namespace nodes representing the context
 * for interpreting Vars in the node tree.  It can be NIL if no Vars are
 * expected.
 *
 * forceprefix is true to force all Vars to be prefixed with their table names.
 *
 * showimplicit is true to force all implicit casts to be shown explicitly.
 *
 * Tries to pretty up the output according to prettyFlags and startIndent.
 *
 * The result is a palloc'd string.
 * ----------
 */
static char *
deparse_expression_pretty(Node *expr, List *dpcontext,
						  bool forceprefix, bool showimplicit,
						  int prettyFlags, int startIndent)
{
	StringInfoData buf;
	deparse_context context;

	initStringInfo(&buf);
	context.buf = &buf;
	context.namespaces = dpcontext;
	context.windowClause = NIL;
	context.windowTList = NIL;
	context.varprefix = forceprefix;
	context.prettyFlags = prettyFlags;
	context.wrapColumn = WRAP_COLUMN_DEFAULT;
	context.indentLevel = startIndent;
	context.special_exprkind = EXPR_KIND_NONE;
	context.appendparents = NULL;

	get_rule_expr(expr, &context, showimplicit);

	return buf.data;
}

/*
 * get_rule_expr_paren	- deparse expr using get_rule_expr,
 * embracing the string with parentheses if necessary for prettyPrint.
 *
 * Never embrace if prettyFlags=0, because it's done in the calling node.
 *
 * Any node that does *not* embrace its argument node by sql syntax (with
 * parentheses, non-operator keywords like CASE/WHEN/ON, or comma etc) should
 * use get_rule_expr_paren instead of get_rule_expr so parentheses can be
 * added.
 */
static void
get_rule_expr_paren(Node *node, deparse_context *context,
					bool showimplicit, Node *parentNode)
{
	bool		need_paren;

	need_paren = PRETTY_PAREN(context) &&
		!isSimpleNode(node, parentNode, context->prettyFlags);

	if (need_paren)
		appendStringInfoChar(context->buf, '(');

	get_rule_expr(node, context, showimplicit);

	if (need_paren)
		appendStringInfoChar(context->buf, ')');
}

/* ----------
 * get_rule_expr			- Parse back an expression
 *
 * Note: showimplicit determines whether we display any implicit cast that
 * is present at the top of the expression tree.  It is a passed argument,
 * not a field of the context struct, because we change the value as we
 * recurse down into the expression.  In general we suppress implicit casts
 * when the result type is known with certainty (eg, the arguments of an
 * OR must be boolean).  We display implicit casts for arguments of functions
 * and operators, since this is needed to be certain that the same function
 * or operator will be chosen when the expression is re-parsed.
 * ----------
 */
static void
get_rule_expr(Node *node, deparse_context *context,
			  bool showimplicit)
{
	StringInfo	buf = context->buf;

	if (node == NULL)
		return;

	/* Guard against excessively long or deeply-nested queries */
	CHECK_FOR_INTERRUPTS();
	check_stack_depth();

	/*
	 * Each level of get_rule_expr must emit an indivisible term
	 * (parenthesized if necessary) to ensure result is reparsed into the same
	 * expression tree.  The only exception is that when the input is a List,
	 * we emit the component items comma-separated with no surrounding
	 * decoration; this is convenient for most callers.
	 */
	switch (nodeTag(node))
	{
		case T_Var:
			(void) get_variable((Var *) node, 0, false, context);
			break;

		case T_Const:
			get_const_expr((Const *) node, context, 0);
			break;

		case T_FuncExpr:
			get_func_expr((FuncExpr *) node, context, showimplicit);
			break;

		case T_OpExpr:
			get_oper_expr((OpExpr *) node, context);
			break;

		case T_NullTest:
			{
				NullTest   *ntest = (NullTest *) node;

				if (!PRETTY_PAREN(context))
					appendStringInfoChar(buf, '(');
				get_rule_expr_paren((Node *) ntest->arg, context, true, node);

				/*
				 * For scalar inputs, we prefer to print as IS [NOT] NULL,
				 * which is shorter and traditional.  If it's a rowtype input
				 * but we're applying a scalar test, must print IS [NOT]
				 * DISTINCT FROM NULL to be semantically correct.
				 */
				if (ntest->argisrow ||
					!type_is_rowtype(exprType((Node *) ntest->arg)))
				{
					switch (ntest->nulltesttype)
					{
						case IS_NULL:
							appendStringInfoString(buf, " IS NULL");
							break;
						case IS_NOT_NULL:
							appendStringInfoString(buf, " IS NOT NULL");
							break;
						default:
							elog(ERROR, "unrecognized nulltesttype: %d",
								 (int) ntest->nulltesttype);
					}
				}
				if (!PRETTY_PAREN(context))
					appendStringInfoChar(buf, ')');
			}
			break;

		case T_ScalarArrayOpExpr:
			{
				ScalarArrayOpExpr *expr = (ScalarArrayOpExpr *) node;
				List	   *args = expr->args;
				Node	   *arg1 = (Node *) linitial(args);
				Node	   *arg2 = (Node *) lsecond(args);
				char	   *opername;

				if (!PRETTY_PAREN(context))
					appendStringInfoChar(buf, '(');
				get_rule_expr_paren(arg1, context, true, node);
				opername = generate_operator_name(expr->opno, exprType(arg1),
												  get_base_element_type(exprType(arg2)));
				if (strcmp(opername, "=") == 0)
					appendStringInfoString(buf, " IN (");
				else if (strcmp(opername, "<>") == 0)
					appendStringInfoString(buf, " NOT IN (");

				get_rule_expr_paren(arg2, context, true, node);

				appendStringInfoChar(buf, ')');
				if (!PRETTY_PAREN(context))
					appendStringInfoChar(buf, ')');
			}
			break;

		case T_BoolExpr:
			{
				BoolExpr   *expr = (BoolExpr *) node;
				Node	   *first_arg = linitial(expr->args);
				ListCell   *arg;

				switch (expr->boolop)
				{
					case AND_EXPR:
						if (!PRETTY_PAREN(context))
							appendStringInfoChar(buf, '(');
						get_rule_expr_paren(first_arg, context,
											false, node);
						for_each_from(arg, expr->args, 1)
						{
							appendStringInfoString(buf, " AND ");
							get_rule_expr_paren((Node *) lfirst(arg), context,
												false, node);
						}
						if (!PRETTY_PAREN(context))
							appendStringInfoChar(buf, ')');
						break;

					case OR_EXPR:
						if (!PRETTY_PAREN(context))
							appendStringInfoChar(buf, '(');
						get_rule_expr_paren(first_arg, context,
											false, node);
						for_each_from(arg, expr->args, 1)
						{
							appendStringInfoString(buf, " OR ");
							get_rule_expr_paren((Node *) lfirst(arg), context,
												false, node);
						}
						if (!PRETTY_PAREN(context))
							appendStringInfoChar(buf, ')');
						break;

					case NOT_EXPR:
						if (!PRETTY_PAREN(context))
							appendStringInfoChar(buf, '(');
						appendStringInfoString(buf, "NOT ");
						get_rule_expr_paren(first_arg, context,
											false, node);
						if (!PRETTY_PAREN(context))
							appendStringInfoChar(buf, ')');
						break;

					default:
						elog(ERROR, "unrecognized boolop: %d",
							 (int) expr->boolop);
				}
			}
			break;

		case T_RelabelType:
			{
				RelabelType *relabel = (RelabelType *) node;
				Node	   *arg = (Node *) relabel->arg;

				get_rule_expr_paren(arg, context, false, node);
			}
			break;

		case T_ArrayExpr:
			{
				ArrayExpr  *arrayexpr = (ArrayExpr *) node;

				get_rule_expr((Node *) arrayexpr->elements, context, true);
			}
			break;

		case T_List:
			{
				char	   *sep;
				ListCell   *l;

				sep = "";
				foreach(l, (List *) node)
				{
					appendStringInfoString(buf, sep);
					get_rule_expr((Node *) lfirst(l), context, showimplicit);
					sep = ", ";
				}
			}
			break;

		case T_CoerceViaIO:
			{
				CoerceViaIO *iocoerce = (CoerceViaIO *) node;
				Node	   *arg = (Node *) iocoerce->arg;

				if (iocoerce->coerceformat == COERCE_IMPLICIT_CAST &&
					!showimplicit)
				{
					/* don't show the implicit cast */
					get_rule_expr_paren(arg, context, false, node);
				}
				else
				{
					get_coercion_expr(arg, context,
									  iocoerce->resulttype,
									  -1,
									  node);
				}
			}
			break;

		case T_CoerceToDomain:
			{
				CoerceToDomain *ctest = (CoerceToDomain *) node;
				Node	   *arg = (Node *) ctest->arg;

				if (ctest->coercionformat == COERCE_IMPLICIT_CAST &&
					!showimplicit)
				{
					/* don't show the implicit cast */
					get_rule_expr(arg, context, false);
				}
				else
				{
					get_coercion_expr(arg, context,
									  ctest->resulttype,
									  ctest->resulttypmod,
									  node);
				}
			}
			break;

		case T_CollateExpr:
			{
				CollateExpr *collate = (CollateExpr *) node;
				Node	   *arg = (Node *) collate->arg;

				if (!PRETTY_PAREN(context))
					appendStringInfoChar(buf, '(');
				get_rule_expr_paren(arg, context, showimplicit, node);
				appendStringInfo(buf, " COLLATE %s",
								 generate_tsql_collation_name(collate->collOid));
				if (!PRETTY_PAREN(context))
					appendStringInfoChar(buf, ')');
			}
			break;

		case T_SetToDefault:
			appendStringInfoString(buf, "DEFAULT");
			break;

		default:
			elog(ERROR, "unrecognized node type: %d", (int) nodeTag(node));
			break;
	}
}

/*
 * Given a C string, produce a TEXT datum.
 *
 * We assume that the input was palloc'd and may be freed.
 */
static text *
string_to_text(char *str)
{
	text	   *result;

	result = cstring_to_text(str);

	pfree(str);
	return result;
}

/*
 * Display a Var appropriately.
 *
 * In some cases (currently only when recursing into an unnamed join)
 * the Var's varlevelsup has to be interpreted with respect to a context
 * above the current one; levelsup indicates the offset.
 *
 * If istoplevel is true, the Var is at the top level of a SELECT's
 * targetlist, which means we need special treatment of whole-row Vars.
 * Instead of the normal "tab.*", we'll print "tab.*::typename", which is a
 * dirty hack to prevent "tab.*" from being expanded into multiple columns.
 * (The parser will strip the useless coercion, so no inefficiency is added in
 * dump and reload.)  We used to print just "tab" in such cases, but that is
 * ambiguous and will yield the wrong result if "tab" is also a plain column
 * name in the query.
 *
 * Returns the attname of the Var, or NULL if the Var has no attname (because
 * it is a whole-row Var or a subplan output reference).
 */
static char *
get_variable(Var *var, int levelsup, bool istoplevel, deparse_context *context)
{
	StringInfo	buf = context->buf;
	RangeTblEntry *rte;
	AttrNumber	attnum;
	int			netlevelsup;
	deparse_namespace *dpns;
	Index		varno;
	AttrNumber	varattno;
	deparse_columns *colinfo;
	char	   *refname;
	char	   *attname;

	/* Find appropriate nesting depth */
	netlevelsup = var->varlevelsup + levelsup;
	if (netlevelsup >= list_length(context->namespaces))
		elog(ERROR, "bogus varlevelsup: %d offset %d",
			 var->varlevelsup, levelsup);
	dpns = (deparse_namespace *) list_nth(context->namespaces,
										  netlevelsup);

	/*
	 * If we have a syntactic referent for the Var, and we're working from a
	 * parse tree, prefer to use the syntactic referent.  Otherwise, fall back
	 * on the semantic referent.  (Forcing use of the semantic referent when
	 * printing plan trees is a design choice that's perhaps more motivated by
	 * backwards compatibility than anything else.  But it does have the
	 * advantage of making plans more explicit.)
	 */
	if (var->varnosyn > 0 && dpns->plan == NULL)
	{
		varno = var->varnosyn;
		varattno = var->varattnosyn;
	}
	else
	{
		varno = var->varno;
		varattno = var->varattno;
	}

	/*
	 * Try to find the relevant RTE in this rtable.  In a plan tree, it's
	 * likely that varno is OUTER_VAR or INNER_VAR, in which case we must dig
	 * down into the subplans, or INDEX_VAR, which is resolved similarly. Also
	 * find the aliases previously assigned for this RTE.
	 */
	if (varno >= 1 && varno <= list_length(dpns->rtable))
	{
		/*
		 * We might have been asked to map child Vars to some parent relation.
		 */
		if (context->appendparents && dpns->appendrels)
		{
			Index		pvarno = varno;
			AttrNumber	pvarattno = varattno;
			AppendRelInfo *appinfo = dpns->appendrels[pvarno];
			bool		found = false;

			/* Only map up to inheritance parents, not UNION ALL appendrels */
			while (appinfo &&
				   rt_fetch(appinfo->parent_relid,
							dpns->rtable)->rtekind == RTE_RELATION)
			{
				found = false;
				if (pvarattno > 0)	/* system columns stay as-is */
				{
					if (pvarattno > appinfo->num_child_cols)
						break;	/* safety check */
					pvarattno = appinfo->parent_colnos[pvarattno - 1];
					if (pvarattno == 0)
						break;	/* Var is local to child */
				}

				pvarno = appinfo->parent_relid;
				found = true;

				/* If the parent is itself a child, continue up. */
				Assert(pvarno > 0 && pvarno <= list_length(dpns->rtable));
				appinfo = dpns->appendrels[pvarno];
			}

			/*
			 * If we found an ancestral rel, and that rel is included in
			 * appendparents, print that column not the original one.
			 */
			if (found && bms_is_member(pvarno, context->appendparents))
			{
				varno = pvarno;
				varattno = pvarattno;
			}
		}

		rte = rt_fetch(varno, dpns->rtable);
		refname = (char *) list_nth(dpns->rtable_names, varno - 1);
		colinfo = deparse_columns_fetch(varno, dpns);
		attnum = varattno;
	}
	else
	{
		resolve_special_varno((Node *) var, context,
							  get_special_variable, NULL);
		return NULL;
	}

	/*
	 * The planner will sometimes emit Vars referencing resjunk elements of a
	 * subquery's target list (this is currently only possible if it chooses
	 * to generate a "physical tlist" for a SubqueryScan or CteScan node).
	 * Although we prefer to print subquery-referencing Vars using the
	 * subquery's alias, that's not possible for resjunk items since they have
	 * no alias.  So in that case, drill down to the subplan and print the
	 * contents of the referenced tlist item.  This works because in a plan
	 * tree, such Vars can only occur in a SubqueryScan or CteScan node, and
	 * we'll have set dpns->inner_plan to reference the child plan node.
	 */
	if ((rte->rtekind == RTE_SUBQUERY || rte->rtekind == RTE_CTE) &&
		attnum > list_length(rte->eref->colnames) &&
		dpns->inner_plan)
	{
		TargetEntry *tle;
		deparse_namespace save_dpns;

		tle = get_tle_by_resno(dpns->inner_tlist, attnum);
		if (!tle)
			elog(ERROR, "invalid attnum %d for relation \"%s\"",
				 attnum, rte->eref->aliasname);

		Assert(netlevelsup == 0);
		push_child_plan(dpns, dpns->inner_plan, &save_dpns);

		/*
		 * Force parentheses because our caller probably assumed a Var is a
		 * simple expression.
		 */
		if (!IsA(tle->expr, Var))
			appendStringInfoChar(buf, '(');
		get_rule_expr((Node *) tle->expr, context, true);
		if (!IsA(tle->expr, Var))
			appendStringInfoChar(buf, ')');

		pop_child_plan(dpns, &save_dpns);
		return NULL;
	}

	/*
	 * If it's an unnamed join, look at the expansion of the alias variable.
	 * If it's a simple reference to one of the input vars, then recursively
	 * print the name of that var instead.  When it's not a simple reference,
	 * we have to just print the unqualified join column name.  (This can only
	 * happen with "dangerous" merged columns in a JOIN USING; we took pains
	 * previously to make the unqualified column name unique in such cases.)
	 *
	 * This wouldn't work in decompiling plan trees, because we don't store
	 * joinaliasvars lists after planning; but a plan tree should never
	 * contain a join alias variable.
	 */
	if (rte->rtekind == RTE_JOIN && rte->alias == NULL)
	{
		if (rte->joinaliasvars == NIL)
			elog(ERROR, "cannot decompile join alias var in plan tree");
		if (attnum > 0)
		{
			Var		   *aliasvar;

			aliasvar = (Var *) list_nth(rte->joinaliasvars, attnum - 1);
			/* we intentionally don't strip implicit coercions here */
			if (aliasvar && IsA(aliasvar, Var))
			{
				return get_variable(aliasvar, var->varlevelsup + levelsup,
									istoplevel, context);
			}
		}

		/*
		 * Unnamed join has no refname.  (Note: since it's unnamed, there is
		 * no way the user could have referenced it to create a whole-row Var
		 * for it.  So we don't have to cover that case below.)
		 */
		Assert(refname == NULL);
	}

	if (attnum == InvalidAttrNumber)
		attname = NULL;
	else if (attnum > 0)
	{
		/* Get column name to use from the colinfo struct */
		if (attnum > colinfo->num_cols)
			elog(ERROR, "invalid attnum %d for relation \"%s\"",
				 attnum, rte->eref->aliasname);
		attname = colinfo->colnames[attnum - 1];
		if (attname == NULL)	/* dropped column? */
			elog(ERROR, "invalid attnum %d for relation \"%s\"",
				 attnum, rte->eref->aliasname);
	}
	else
	{
		/* System column - name is fixed, get it from the catalog */
		attname = get_rte_attribute_name(rte, attnum);
	}

	if (istoplevel && !attname)
	{
		appendStringInfoString(buf, "CAST(");
	}
	if (refname && (context->varprefix || attname == NULL))
	{
		appendStringInfoString(buf, tsql_quote_identifier(refname));
		appendStringInfoChar(buf, '.');
	}
	if (attname)
		appendStringInfoString(buf, tsql_quote_identifier(attname));
	else
	{
		appendStringInfoChar(buf, '*');
		if (istoplevel)
			appendStringInfo(buf, " AS %s)",
							 tsql_format_type_extended(var->vartype,
													   var->vartypmod,
													   FORMAT_TYPE_TYPEMOD_GIVEN));
	}

	return attname;
}

/* ----------
 * get_const_expr
 *
 *	Make a string representation of a Const
 *
 * showtype can be -1 to never show "CAST(%s AS typename)" decoration, or +1 to always
 * show it, or 0 to show it only if the constant wouldn't be assumed to be
 * the right type by default.
 *
 * If the Const's collation isn't default for its type, show that too.
 * We mustn't do this when showtype is -1 (since that means the caller will
 * print "CAST(%s AS typename)", and we can't put a COLLATE clause in between).  It's
 * caller's responsibility that collation isn't missed in such cases.
 * ----------
 */
static void
get_const_expr(Const *constval, deparse_context *context, int showtype)
{
	StringInfo	buf = context->buf;
	StringInfo	valbuf;
	Oid			typoutput;
	bool		typIsVarlena;
	char	   *extval;
	bool		needlabel = false;

	valbuf = makeStringInfo();

	if (constval->constisnull)
	{
		/*
		 * Always label the type of a NULL constant to prevent misdecisions
		 * about type when reparsing.
		 */
		appendStringInfoString(valbuf, "NULL");
		if (showtype >= 0)
		{
			appendStringInfo(buf, "CAST(%s AS %s)", valbuf->data,
							 tsql_format_type_extended(constval->consttype,
													   constval->consttypmod,
													   FORMAT_TYPE_TYPEMOD_GIVEN));
			get_const_collation(constval, context);
		}
		else
		{
			appendStringInfoString(buf, valbuf->data);
		}
		pfree(valbuf->data);
		return;
	}

	getTypeOutputInfo(constval->consttype,
					  &typoutput, &typIsVarlena);

	extval = OidOutputFunctionCall(typoutput, constval->constvalue);

	switch (constval->consttype)
	{
		case INT4OID:

			/*
			 * INT4 can be printed without any decoration, unless it is
			 * negative; in that case print it as '-nnn'::integer to ensure
			 * that the output will re-parse as a constant, not as a constant
			 * plus operator.  In most cases we could get away with printing
			 * (-nnn) instead, because of the way that gram.y handles negative
			 * literals; but that doesn't work for INT_MIN, and it doesn't
			 * seem that much prettier anyway.
			 */
			if (extval[0] != '-')
				appendStringInfoString(valbuf, extval);
			else
			{
				appendStringInfo(valbuf, "'%s'", extval);
				needlabel = true;	/* we must attach a cast */
			}
			break;

		case NUMERICOID:

			/*
			 * NUMERIC can be printed without quotes if it looks like a float
			 * constant (not an integer, and not Infinity or NaN) and doesn't
			 * have a leading sign (for the same reason as for INT4).
			 */
			if (isdigit((unsigned char) extval[0]) &&
				strcspn(extval, "eE.") != strlen(extval))
			{
				appendStringInfoString(valbuf, extval);
			}
			else
			{
				appendStringInfo(valbuf, "'%s'", extval);
				needlabel = true;	/* we must attach a cast */
			}
			break;

		case BOOLOID:
			if (strcmp(extval, "t") == 0)
				appendStringInfoString(valbuf, "true");
			else
				appendStringInfoString(valbuf, "false");
			break;

		default:
			simple_quote_literal(valbuf, extval);
			break;
	}

	pfree(extval);

	if (showtype < 0)
	{
		appendStringInfoString(buf, valbuf->data);
		pfree(valbuf->data);
		return;
	}

	/*
	 * XXX this code has to be kept in sync with the behavior of the parser,
	 * especially make_const.
	 */
	switch (constval->consttype)
	{
		case BOOLOID:
		case TEXTOID:
		case CHAROID:
		case UNKNOWNOID:
			/* These types can be left unlabeled */
			needlabel = false;
			break;
		case INT4OID:
			/* We determined above whether a label is needed */
			break;
		case NUMERICOID:

			/*
			 * Float-looking constants will be typed as numeric, which we
			 * checked above; but if there's a nondefault typmod we need to
			 * show it.
			 */
			needlabel |= (constval->consttypmod >= 0);
			break;
		default:
			needlabel = false;
			break;
	}
	if (needlabel || showtype > 0)
	{
		appendStringInfo(buf, "CAST(%s AS %s)", valbuf->data,
						 tsql_format_type_extended(constval->consttype,
												   constval->consttypmod,
												   FORMAT_TYPE_TYPEMOD_GIVEN));
	}
	else
	{
		appendStringInfoString(buf, valbuf->data);
	}

	pfree(valbuf->data);
	get_const_collation(constval, context);
}

/*
 * Deparse a Var which references OUTER_VAR, INNER_VAR, or INDEX_VAR.  This
 * routine is actually a callback for resolve_special_varno, which handles
 * finding the correct TargetEntry.  We get the expression contained in that
 * TargetEntry and just need to deparse it, a job we can throw back on
 * get_rule_expr.
 */
static void
get_special_variable(Node *node, deparse_context *context, void *callback_arg)
{
	StringInfo	buf = context->buf;

	/*
	 * For a non-Var referent, force parentheses because our caller probably
	 * assumed a Var is a simple expression.
	 */
	if (!IsA(node, Var))
		appendStringInfoChar(buf, '(');
	get_rule_expr(node, context, true);
	if (!IsA(node, Var))
		appendStringInfoChar(buf, ')');
}

/*
 * helper for get_const_expr: append COLLATE if needed
 */
static void
get_const_collation(Const *constval, deparse_context *context)
{
	StringInfo	buf = context->buf;

	if (OidIsValid(constval->constcollid))
	{
		Oid			typcollation = get_typcollation(constval->consttype);

		if (constval->constcollid != typcollation)
		{
			appendStringInfo(buf, " COLLATE %s",
							 generate_tsql_collation_name(constval->constcollid));
		}
	}
}

/*
 * simple_quote_literal - Format a string as a SQL literal, append to buf
 */
static void
simple_quote_literal(StringInfo buf, const char *val)
{
	const char *valptr;

	/*
	 * We form the string literal according to the prevailing setting of
	 * standard_conforming_strings; we never use E''. User is responsible for
	 * making sure result is used correctly.
	 */
	appendStringInfoChar(buf, '\'');
	for (valptr = val; *valptr; valptr++)
	{
		char		ch = *valptr;

		if (SQL_STR_DOUBLE(ch, !standard_conforming_strings))
			appendStringInfoChar(buf, ch);
		appendStringInfoChar(buf, ch);
	}
	appendStringInfoChar(buf, '\'');
}

/*
 * get_oper_expr			- Parse back an OpExpr node
 */
static void
get_oper_expr(OpExpr *expr, deparse_context *context)
{
	StringInfo	buf = context->buf;
	Oid			opno = expr->opno;
	List	   *args = expr->args;

	if (!PRETTY_PAREN(context))
		appendStringInfoChar(buf, '(');
	if (list_length(args) == 2)
	{
		/* binary operator */
		Node	   *arg1 = (Node *) linitial(args);
		Node	   *arg2 = (Node *) lsecond(args);

		get_rule_expr_paren(arg1, context, false, (Node *) expr);
		appendStringInfo(buf, " %s ",
						 generate_operator_name(opno,
												exprType(arg1),
												exprType(arg2)));
		get_rule_expr_paren(arg2, context, false, (Node *) expr);
	}
	else
	{
		/* prefix operator */
		Node	   *arg = (Node *) linitial(args);

		appendStringInfo(buf, "%s ",
						 generate_operator_name(opno,
												InvalidOid,
												exprType(arg)));
		get_rule_expr_paren(arg, context, true, (Node *) expr);
	}
	if (!PRETTY_PAREN(context))
		appendStringInfoChar(buf, ')');
}

/*
 * get_func_expr			- Parse back a FuncExpr node
 */
static void
get_func_expr(FuncExpr *expr, deparse_context *context,
			  bool showimplicit)
{
	StringInfo	buf = context->buf;
	Oid			funcoid = expr->funcid;
	Oid			argtypes[FUNC_MAX_ARGS];
	int			nargs;
	List	   *argnames;
	bool		use_variadic;
	char	   *funcname;
	ListCell   *l;

	/*
	 * If the function call came from an implicit coercion, then just show the
	 * first argument --- unless caller wants to see implicit coercions.
	 */
	if (expr->funcformat == COERCE_IMPLICIT_CAST && !showimplicit)
	{
		get_rule_expr_paren((Node *) linitial(expr->args), context,
							false, (Node *) expr);
		return;
	}

	/*
	 * If the function call came from a cast, then show the first argument
	 * plus an explicit cast operation.
	 */
	if (expr->funcformat == COERCE_EXPLICIT_CAST ||
		expr->funcformat == COERCE_IMPLICIT_CAST)
	{
		Node	   *arg = linitial(expr->args);
		Oid			rettype = expr->funcresulttype;
		int32		coercedTypmod;

		/* Get the typmod if this is a length-coercion function */
		(void) exprIsLengthCoercion((Node *) expr, &coercedTypmod);

		get_coercion_expr(arg, context,
						  rettype, coercedTypmod,
						  (Node *) expr);

		return;
	}

	/*
	 * Normal function: display as proname(args).  First we need to extract
	 * the argument datatypes.
	 */
	if (list_length(expr->args) > FUNC_MAX_ARGS)
		ereport(ERROR,
				(errcode(ERRCODE_TOO_MANY_ARGUMENTS),
				 errmsg("too many arguments")));
	nargs = 0;
	argnames = NIL;
	foreach(l, expr->args)
	{
		Node	   *arg = (Node *) lfirst(l);

		if (IsA(arg, NamedArgExpr))
			argnames = lappend(argnames, ((NamedArgExpr *) arg)->name);
		argtypes[nargs] = exprType(arg);
		nargs++;
	}

	funcname = generate_function_name(funcoid, nargs,
									  argnames, argtypes,
									  expr->funcvariadic,
									  &use_variadic,
									  context->special_exprkind);

	/*
	 * AT TIMEZONE from TSQL is parsed to timezone function internally. While
	 * de-parsing, convert it to AT TIME ZONE explicitly.
	 */
	if (strcmp(funcname, "timezone") == 0)
	{
		get_rule_expr((Node *) list_nth(expr->args, 1), context, false);
		appendStringInfoString(buf, " AT TIME ZONE ");
		get_rule_expr((Node *) list_nth(expr->args, 0), context, false);
	}
	else
	{
		appendStringInfo(buf, "%s(", funcname);
		nargs = 0;
		foreach(l, expr->args)
		{
			if (nargs++ > 0)
				appendStringInfoString(buf, ", ");
			if (use_variadic && lnext(expr->args, l) == NULL)
				appendStringInfoString(buf, "VARIADIC ");
			get_rule_expr((Node *) lfirst(l), context, false);
		}
		appendStringInfoChar(buf, ')');
	}
}

/*
 * generate_function_name
 *		Compute the name to display for a function specified by OID,
 *		given that it is being called with the specified actual arg names and
 *		types.  (Those matter because of ambiguous-function resolution rules.)
 *
 * If we're dealing with a potentially variadic function (in practice, this
 * means a FuncExpr or Aggref, not some other way of calling a function), then
 * has_variadic must specify whether variadic arguments have been merged,
 * and *use_variadic_p will be set to indicate whether to print VARIADIC in
 * the output.  For non-FuncExpr cases, has_variadic should be false and
 * use_variadic_p can be NULL.
 *
 * The result includes all necessary quoting and schema-prefixing.
 */
static char *
generate_function_name(Oid funcid, int nargs, List *argnames, Oid *argtypes,
					   bool has_variadic, bool *use_variadic_p,
					   ParseExprKind special_exprkind)
{
	char	   *result;
	HeapTuple	proctup;
	Form_pg_proc procform;
	char	   *proname;
	bool		use_variadic;
	char	   *nspname;
	FuncDetailCode p_result;
	Oid			p_funcid;
	Oid			p_rettype;
	bool		p_retset;
	int			p_nvargs;
	Oid			p_vatype;
	Oid		   *p_true_typeids;
	bool		force_qualify = false;

	proctup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcid));
	if (!HeapTupleIsValid(proctup))
		elog(ERROR, "cache lookup failed for function %u", funcid);
	procform = (Form_pg_proc) GETSTRUCT(proctup);
	proname = NameStr(procform->proname);

	/*
	 * Due to parser hacks to avoid needing to reserve CUBE, we need to force
	 * qualification in some special cases.
	 */
	if (special_exprkind == EXPR_KIND_GROUP_BY)
	{
		if (strcmp(proname, "cube") == 0 || strcmp(proname, "rollup") == 0)
			force_qualify = true;
	}

	/*
	 * Determine whether VARIADIC should be printed.  We must do this first
	 * since it affects the lookup rules in func_get_detail().
	 *
	 * We always print VARIADIC if the function has a merged variadic-array
	 * argument.  Note that this is always the case for functions taking a
	 * VARIADIC argument type other than VARIADIC ANY.  If we omitted VARIADIC
	 * and printed the array elements as separate arguments, the call could
	 * match a newer non-VARIADIC function.
	 */
	if (use_variadic_p)
	{
		/* Parser should not have set funcvariadic unless fn is variadic */
		Assert(!has_variadic || OidIsValid(procform->provariadic));
		use_variadic = has_variadic;
		*use_variadic_p = use_variadic;
	}
	else
	{
		Assert(!has_variadic);
		use_variadic = false;
	}

	/*
	 * The idea here is to schema-qualify only if the parser would fail to
	 * resolve the correct function given the unqualified func name with the
	 * specified argtypes and VARIADIC flag.  But if we already decided to
	 * force qualification, then we can skip the lookup and pretend we didn't
	 * find it.
	 */
	if (!force_qualify)
		p_result = func_get_detail(list_make1(makeString(proname)),
								   NIL, argnames, nargs, argtypes,
								   !use_variadic, true, false,
								   &p_funcid, &p_rettype,
								   &p_retset, &p_nvargs, &p_vatype,
								   &p_true_typeids, NULL);
	else
	{
		p_result = FUNCDETAIL_NOTFOUND;
		p_funcid = InvalidOid;
	}

	if ((p_result == FUNCDETAIL_NORMAL ||
		 p_result == FUNCDETAIL_AGGREGATE ||
		 p_result == FUNCDETAIL_WINDOWFUNC) &&
		p_funcid == funcid)
		nspname = NULL;
	else
		nspname = get_namespace_name(procform->pronamespace);

	result = tsql_quote_qualified_identifier(nspname, proname);

	ReleaseSysCache(proctup);

	return result;
}

/*
 * get_simple_binary_op_name
 *
 * helper function for isSimpleNode
 * will return single char binary operator name, or NULL if it's not
 */
static const char *
get_simple_binary_op_name(OpExpr *expr)
{
	List	   *args = expr->args;

	if (list_length(args) == 2)
	{
		/* binary operator */
		Node	   *arg1 = (Node *) linitial(args);
		Node	   *arg2 = (Node *) lsecond(args);
		const char *op;

		op = generate_operator_name(expr->opno, exprType(arg1), exprType(arg2));
		if (strlen(op) == 1)
			return op;
	}
	return NULL;
}


/*
 * isSimpleNode - check if given node is simple (doesn't need parenthesizing)
 *
 *	true   : simple in the context of parent node's type
 *	false  : not simple
 */
static bool
isSimpleNode(Node *node, Node *parentNode, int prettyFlags)
{
	if (!node)
		return false;

	switch (nodeTag(node))
	{
		case T_Var:
		case T_Const:
		case T_CoerceToDomainValue:
			/* single words: always simple */
			return true;

		case T_FuncExpr:
			/* function-like: name(..) or name[..] */
			return true;

			/* CASE keywords act as parentheses */
		case T_OpExpr:
			{
				/* depends on parent node type; needs further checking */
				if (prettyFlags & PRETTYFLAG_PAREN && IsA(parentNode, OpExpr))
				{
					const char *op;
					const char *parentOp;
					bool		is_lopriop;
					bool		is_hipriop;
					bool		is_lopriparent;
					bool		is_hipriparent;

					op = get_simple_binary_op_name((OpExpr *) node);
					if (!op)
						return false;

					/* We know only the basic operators + - and * / % */
					is_lopriop = (strchr("+-", *op) != NULL);
					is_hipriop = (strchr("*/%", *op) != NULL);
					if (!(is_lopriop || is_hipriop))
						return false;

					parentOp = get_simple_binary_op_name((OpExpr *) parentNode);
					if (!parentOp)
						return false;

					is_lopriparent = (strchr("+-", *parentOp) != NULL);
					is_hipriparent = (strchr("*/%", *parentOp) != NULL);
					if (!(is_lopriparent || is_hipriparent))
						return false;

					if (is_hipriop && is_lopriparent)
						return true;	/* op binds tighter than parent */

					if (is_lopriop && is_hipriparent)
						return false;

					/*
					 * Operators are same priority --- can skip parens only if
					 * we have (a - b) - c, not a - (b - c).
					 */
					if (node == (Node *) linitial(((OpExpr *) parentNode)->args))
						return true;

					return false;
				}
				/* else do the same stuff as for T_SubLink et al. */
			}
			/* FALLTHROUGH */

		case T_NullTest:
			switch (nodeTag(parentNode))
			{
				case T_FuncExpr:
					{
						/* special handling for casts */
						CoercionForm type = ((FuncExpr *) parentNode)->funcformat;

						if (type == COERCE_EXPLICIT_CAST ||
							type == COERCE_IMPLICIT_CAST)
							return false;
						return true;	/* own parentheses */
					}
				case T_BoolExpr:	/* lower precedence */
					return true;
				default:
					return false;
			}

		case T_BoolExpr:
			switch (nodeTag(parentNode))
			{
				case T_BoolExpr:
					if (prettyFlags & PRETTYFLAG_PAREN)
					{
						BoolExprType type;
						BoolExprType parentType;

						type = ((BoolExpr *) node)->boolop;
						parentType = ((BoolExpr *) parentNode)->boolop;
						switch (type)
						{
							case NOT_EXPR:
							case AND_EXPR:
								if (parentType == AND_EXPR || parentType == OR_EXPR)
									return true;
								break;
							case OR_EXPR:
								if (parentType == OR_EXPR)
									return true;
								break;
						}
					}
					return false;
				case T_FuncExpr:
					{
						/* special handling for casts */
						CoercionForm type = ((FuncExpr *) parentNode)->funcformat;

						if (type == COERCE_EXPLICIT_CAST ||
							type == COERCE_IMPLICIT_CAST)
							return false;
						return true;	/* own parentheses */
					}
				default:
					return false;
			}

		default:
			break;
	}
	/* those we don't know: in dubio complexo */
	return false;
}


/*
 * quote_identifier			- Quote an identifier only if needed
 *
 * When quotes are needed, we palloc the required space; slightly
 * space-wasteful but well worth it for notational simplicity.
 */
const char *
tsql_quote_identifier(const char *ident)
{
	/*
	 * Can avoid quoting if ident starts with a lowercase letter, underscore
	 * or at the rate(@) and contains only lowercase letters, digits, at the
	 * rate or  underscores, *and* is not any SQL keyword.  Otherwise, supply
	 * quotes.
	 */
	int			nquotes = 0;
	bool		safe;
	const char *ptr;
	char	   *result;
	char	   *optr;

	/*
	 * would like to use <ctype.h> macros here, but they might yield unwanted
	 * locale-specific results...
	 */
	safe = ((ident[0] >= 'a' && ident[0] <= 'z') || ident[0] == '_' || ident[0] == '@');

	for (ptr = ident; *ptr; ptr++)
	{
		char		ch = *ptr;

		if ((ch >= 'a' && ch <= 'z') ||
			(ch >= '0' && ch <= '9') ||
			(ch == '_') || (ch == '@'))
		{
			/* okay */
		}
		else
		{
			safe = false;
			if (ch == '"')
				nquotes++;
		}
	}

	if (quote_all_identifiers)
		safe = false;

	if (safe)
	{
		/*
		 * Check for keyword.  We quote keywords except for unreserved ones.
		 * (In some cases we could avoid quoting a col_name or type_func_name
		 * keyword, but it seems much harder than it's worth to tell that.)
		 *
		 * Note: ScanKeywordLookup() does case-insensitive comparison, but
		 * that's fine, since we already know we have all-lower-case.
		 */
		int			kwnum = ScanKeywordLookup(ident, &ScanKeywords);

		if (kwnum >= 0 && ScanKeywordCategories[kwnum] != UNRESERVED_KEYWORD)
			safe = false;
	}

	if (safe)
		return ident;			/* no change needed */

	result = (char *) palloc(strlen(ident) + nquotes + 2 + 1);

	optr = result;

	*optr++ = '"';
	for (ptr = ident; *ptr; ptr++)
	{
		char		ch = *ptr;

		if (ch == '"')
			*optr++ = '"';
		*optr++ = ch;
	}
	*optr++ = '"';
	*optr = '\0';

	return result;
}

/*
 * quote_qualified_identifier	- Quote a possibly-qualified identifier
 *
 * Return a name of the form qualifier.ident, or just ident if qualifier
 * is NULL, quoting each component if necessary.  The result is palloc'd.
 */
char *
tsql_quote_qualified_identifier(const char *qualifier,
								const char *ident)
{
	StringInfoData buf;

	initStringInfo(&buf);
	if (qualifier)
		appendStringInfo(&buf, "%s.", tsql_quote_identifier(qualifier));
	appendStringInfoString(&buf, tsql_quote_identifier(ident));
	return buf.data;
}

/*
 * push_child_plan: temporarily transfer deparsing attention to a child plan
 *
 * When expanding an OUTER_VAR or INNER_VAR reference, we must adjust the
 * deparse context in case the referenced expression itself uses
 * OUTER_VAR/INNER_VAR.  We modify the top stack entry in-place to avoid
 * affecting levelsup issues (although in a Plan tree there really shouldn't
 * be any).
 *
 * Caller must provide a local deparse_namespace variable to save the
 * previous state for pop_child_plan.
 */
static void
push_child_plan(deparse_namespace *dpns, Plan *plan,
				deparse_namespace *save_dpns)
{
	/* Save state for restoration later */
	*save_dpns = *dpns;

	/* Link current plan node into ancestors list */
	dpns->ancestors = lcons(dpns->plan, dpns->ancestors);

	/* Set attention on selected child */
	set_deparse_plan(dpns, plan);
}

/*
 * pop_child_plan: undo the effects of push_child_plan
 */
static void
pop_child_plan(deparse_namespace *dpns, deparse_namespace *save_dpns)
{
	List	   *ancestors;

	/* Get rid of ancestors list cell added by push_child_plan */
	ancestors = list_delete_first(dpns->ancestors);

	/* Restore fields changed by push_child_plan */
	*dpns = *save_dpns;

	/* Make sure dpns->ancestors is right (may be unnecessary) */
	dpns->ancestors = ancestors;
}

/*
 * Chase through plan references to special varnos (OUTER_VAR, INNER_VAR,
 * INDEX_VAR) until we find a real Var or some kind of non-Var node; then,
 * invoke the callback provided.
 */
static void
resolve_special_varno(Node *node, deparse_context *context,
					  rsv_callback callback, void *callback_arg)
{
	Var		   *var;
	deparse_namespace *dpns;

	/* This function is recursive, so let's be paranoid. */
	check_stack_depth();

	/* If it's not a Var, invoke the callback. */
	if (!IsA(node, Var))
	{
		(*callback) (node, context, callback_arg);
		return;
	}

	/* Find appropriate nesting depth */
	var = (Var *) node;
	dpns = (deparse_namespace *) list_nth(context->namespaces,
										  var->varlevelsup);

	/*
	 * If varno is special, recurse.  (Don't worry about varnosyn; if we're
	 * here, we already decided not to use that.)
	 */
	if (var->varno == OUTER_VAR && dpns->outer_tlist)
	{
		TargetEntry *tle;
		deparse_namespace save_dpns;
		Bitmapset  *save_appendparents;

		tle = get_tle_by_resno(dpns->outer_tlist, var->varattno);
		if (!tle)
			elog(ERROR, "bogus varattno for OUTER_VAR var: %d", var->varattno);

		/*
		 * If we're descending to the first child of an Append or MergeAppend,
		 * update appendparents.  This will affect deparsing of all Vars
		 * appearing within the eventually-resolved subexpression.
		 */
		save_appendparents = context->appendparents;

		if (IsA(dpns->plan, Append))
			context->appendparents = bms_union(context->appendparents,
											   ((Append *) dpns->plan)->apprelids);
		else if (IsA(dpns->plan, MergeAppend))
			context->appendparents = bms_union(context->appendparents,
											   ((MergeAppend *) dpns->plan)->apprelids);

		push_child_plan(dpns, dpns->outer_plan, &save_dpns);
		resolve_special_varno((Node *) tle->expr, context,
							  callback, callback_arg);
		pop_child_plan(dpns, &save_dpns);
		context->appendparents = save_appendparents;
		return;
	}
	else if (var->varno == INNER_VAR && dpns->inner_tlist)
	{
		TargetEntry *tle;
		deparse_namespace save_dpns;

		tle = get_tle_by_resno(dpns->inner_tlist, var->varattno);
		if (!tle)
			elog(ERROR, "bogus varattno for INNER_VAR var: %d", var->varattno);

		push_child_plan(dpns, dpns->inner_plan, &save_dpns);
		resolve_special_varno((Node *) tle->expr, context,
							  callback, callback_arg);
		pop_child_plan(dpns, &save_dpns);
		return;
	}
	else if (var->varno == INDEX_VAR && dpns->index_tlist)
	{
		TargetEntry *tle;

		tle = get_tle_by_resno(dpns->index_tlist, var->varattno);
		if (!tle)
			elog(ERROR, "bogus varattno for INDEX_VAR var: %d", var->varattno);

		resolve_special_varno((Node *) tle->expr, context,
							  callback, callback_arg);
		return;
	}
	else if (var->varno < 1 || var->varno > list_length(dpns->rtable))
		elog(ERROR, "bogus varno: %d", var->varno);

	/* Not special.  Just invoke the callback. */
	(*callback) (node, context, callback_arg);
}

/* ----------
 * get_coercion_expr
 *
 *	Make a string representation of a value coerced to a specific type
 * ----------
 */
static void
get_coercion_expr(Node *arg, deparse_context *context,
				  Oid resulttype, int32 resulttypmod,
				  Node *parentNode)
{
	StringInfo	buf = context->buf;

	appendStringInfoString(buf, "CAST(");

	/*
	 * Since parse_coerce.c doesn't immediately collapse application of
	 * length-coercion functions to constants, what we'll typically see in
	 * such cases is a Const with typmod -1 and a length-coercion function
	 * right above it.  Avoid generating redundant output. However, beware of
	 * suppressing casts when the user actually wrote something like
	 * 'foo'::text::char(3).
	 *
	 * Note: it might seem that we are missing the possibility of needing to
	 * print a COLLATE clause for such a Const.  However, a Const could only
	 * have nondefault collation in a post-constant-folding tree, in which the
	 * length coercion would have been folded too.  See also the special
	 * handling of CollateExpr in coerce_to_target_type(): any collation
	 * marking will be above the coercion node, not below it.
	 */
	if (arg && IsA(arg, Const) &&
		((Const *) arg)->consttype == resulttype &&
		((Const *) arg)->consttypmod == -1)
	{
		/* Show the constant without normal ::typename decoration */
		get_const_expr((Const *) arg, context, -1);
	}
	else
	{
		if (!PRETTY_PAREN(context))
			appendStringInfoChar(buf, '(');
		get_rule_expr_paren(arg, context, false, parentNode);
		if (!PRETTY_PAREN(context))
			appendStringInfoChar(buf, ')');
	}

	/*
	 * Never emit resulttype(arg) functional notation. A pg_proc entry could
	 * take precedence, and a resulttype in pg_temp would require schema
	 * qualification that format_type_with_typemod() would usually omit. We've
	 * standardized on arg::resulttype, but CAST(arg AS resulttype) notation
	 * would work fine.
	 */
	appendStringInfo(buf, " AS %s)",
					 tsql_format_type_extended(resulttype, resulttypmod,
											   FORMAT_TYPE_TYPEMOD_GIVEN));
}

/*
 * set_deparse_plan: set up deparse_namespace to parse subexpressions
 * of a given Plan node
 *
 * This sets the plan, outer_plan, inner_plan, outer_tlist, inner_tlist,
 * and index_tlist fields.  Caller must already have adjusted the ancestors
 * list if necessary.  Note that the rtable, subplans, and ctes fields do
 * not need to change when shifting attention to different plan nodes in a
 * single plan tree.
 */
static void
set_deparse_plan(deparse_namespace *dpns, Plan *plan)
{
	dpns->plan = plan;

	/*
	 * We special-case Append and MergeAppend to pretend that the first child
	 * plan is the OUTER referent; we have to interpret OUTER Vars in their
	 * tlists according to one of the children, and the first one is the most
	 * natural choice.
	 */
	if (IsA(plan, Append))
		dpns->outer_plan = linitial(((Append *) plan)->appendplans);
	else if (IsA(plan, MergeAppend))
		dpns->outer_plan = linitial(((MergeAppend *) plan)->mergeplans);
	else
		dpns->outer_plan = outerPlan(plan);

	if (dpns->outer_plan)
		dpns->outer_tlist = dpns->outer_plan->targetlist;
	else
		dpns->outer_tlist = NIL;

	/*
	 * For a SubqueryScan, pretend the subplan is INNER referent.  (We don't
	 * use OUTER because that could someday conflict with the normal meaning.)
	 * Likewise, for a CteScan, pretend the subquery's plan is INNER referent.
	 * For a WorkTableScan, locate the parent RecursiveUnion plan node and use
	 * that as INNER referent.
	 *
	 * For ON CONFLICT .. UPDATE we just need the inner tlist to point to the
	 * excluded expression's tlist. (Similar to the SubqueryScan we don't want
	 * to reuse OUTER, it's used for RETURNING in some modify table cases,
	 * although not INSERT .. CONFLICT).
	 */
	if (IsA(plan, SubqueryScan))
		dpns->inner_plan = ((SubqueryScan *) plan)->subplan;
	else if (IsA(plan, CteScan))
		dpns->inner_plan = list_nth(dpns->subplans,
									((CteScan *) plan)->ctePlanId - 1);
	else if (IsA(plan, WorkTableScan))
		dpns->inner_plan = find_recursive_union(dpns,
												(WorkTableScan *) plan);
	else if (IsA(plan, ModifyTable))
		dpns->inner_plan = plan;
	else
		dpns->inner_plan = innerPlan(plan);

	if (IsA(plan, ModifyTable))
		dpns->inner_tlist = ((ModifyTable *) plan)->exclRelTlist;
	else if (dpns->inner_plan)
		dpns->inner_tlist = dpns->inner_plan->targetlist;
	else
		dpns->inner_tlist = NIL;

	/* Set up referent for INDEX_VAR Vars, if needed */
	if (IsA(plan, IndexOnlyScan))
		dpns->index_tlist = ((IndexOnlyScan *) plan)->indextlist;
	else if (IsA(plan, ForeignScan))
		dpns->index_tlist = ((ForeignScan *) plan)->fdw_scan_tlist;
	else if (IsA(plan, CustomScan))
		dpns->index_tlist = ((CustomScan *) plan)->custom_scan_tlist;
	else
		dpns->index_tlist = NIL;
}

/*
 * get_relation_name
 *		Get the unqualified name of a relation specified by OID
 *
 * This differs from the underlying get_rel_name() function in that it will
 * throw error instead of silently returning NULL if the OID is bad.
 */
static char *
get_relation_name(Oid relid)
{
	char	   *relname = get_rel_name(relid);

	if (!relname)
		elog(ERROR, "cache lookup failed for relation %u", relid);
	return relname;
}

/*
 * Locate the ancestor plan node that is the RecursiveUnion generating
 * the WorkTableScan's work table.  We can match on wtParam, since that
 * should be unique within the plan tree.
 */
static Plan *
find_recursive_union(deparse_namespace *dpns, WorkTableScan *wtscan)
{
	ListCell   *lc;

	foreach(lc, dpns->ancestors)
	{
		Plan	   *ancestor = (Plan *) lfirst(lc);

		if (IsA(ancestor, RecursiveUnion) &&
			((RecursiveUnion *) ancestor)->wtParam == wtscan->wtParam)
			return ancestor;
	}
	elog(ERROR, "could not find RecursiveUnion for WorkTableScan with wtParam %d",
		 wtscan->wtParam);
	return NULL;
}

/*
 * tsql_format_type_extended
 *		Generate a possibly-qualified TSQL type name.
 *
 * The default behavior is to only qualify if the type is not in the search
 * path, to ignore the given typmod, and to raise an error if a non-existent
 * type_oid is given. It assumes that array type won't be supplied as input as
 * TSQL doesn't support array types.
 *
 * Refer format_type_extended() from format_type.c for flags documentation.
 *
 * Returns a palloc'd string.
 */
char *
tsql_format_type_extended(Oid type_oid, int32 typemod, bits16 flags)
{
	HeapTuple	tuple;
	Form_pg_type typeform;
	Datum		tsql_typename;
	char	   *buf;
	char	   *nspname;
	bool		with_typemod;

	LOCAL_FCINFO(fcinfo, 1);

	if (type_oid == InvalidOid && (flags & FORMAT_TYPE_ALLOW_INVALID) != 0)
		return pstrdup("-");

	tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(type_oid));
	if (!HeapTupleIsValid(tuple))
	{
		if ((flags & FORMAT_TYPE_ALLOW_INVALID) != 0)
			return pstrdup("???");
		else
			elog(ERROR, "cache lookup failed for type %u", type_oid);
	}
	typeform = (Form_pg_type) GETSTRUCT(tuple);

	/*
	 * Assign -1 as typmod which is equivalent to not printing the typmod for
	 * smalldatetime
	 */
	if ((*common_utility_plugin_ptr->is_tsql_smalldatetime_datatype) (type_oid))
		typemod = -1;

	with_typemod = (flags & FORMAT_TYPE_TYPEMOD_GIVEN) != 0 && (typemod >= 0);
	nspname = get_namespace_name_or_temp(typeform->typnamespace);

	buf = NULL;

	InitFunctionCallInfoData(*fcinfo, NULL, 0, InvalidOid, NULL, NULL);
	fcinfo->args[0].value = ObjectIdGetDatum(type_oid);
	fcinfo->args[0].isnull = false;
	tsql_typename = (*common_utility_plugin_ptr->translate_pg_type_to_tsql) (fcinfo);

	/*
	 * If it is TSQL type then report it without any qualification.
	 */
	if (tsql_typename)
	{
		buf = text_to_cstring(DatumGetTextPP(tsql_typename));
	}
	else
	{
		/*
		 * Default handling: report the name as it appears in the catalog.
		 * Here, we must qualify the name if it is not visible in the search
		 * path or if caller requests it; and we must double-quote it if it's
		 * not a standard identifier or if it matches any keyword.
		 */
		char	   *typname;

		typname = NameStr(typeform->typname);

		if ((flags & FORMAT_TYPE_FORCE_QUALIFY) == 0 &&
			TypeIsVisible(type_oid))
			buf = tsql_quote_qualified_identifier(NULL, typname);
		else
			buf = tsql_quote_qualified_identifier(nspname, typname);

		/*
		 * Assign correct typename in case of sys.binary, it gives bbf_binary
		 * internally
		 */
		if ((*common_utility_plugin_ptr->is_tsql_binary_datatype) (type_oid))
			buf = pstrdup("binary");
		if ((*common_utility_plugin_ptr->is_tsql_varbinary_datatype) (type_oid))
			buf = pstrdup("varbinary");
	}

	if (with_typemod)
	{
		int			typmodout = typeform->typmodout;

		/*
		 * In case of time, datetime2 or datetimeoffset print typmod info
		 * directly because it uses timestamp typmodout function which appends
		 * timezone data along with typmod which is not required. Directly
		 * print typename for smalldatetime as it doesn't support typmod.
		 */
		if (type_oid == TIMEOID ||
			(*common_utility_plugin_ptr->is_tsql_datetime2_datatype) (type_oid) ||
			(*common_utility_plugin_ptr->is_tsql_datetimeoffset_datatype) (type_oid))
		{
			typmodout = InvalidOid;
		}
		buf = tsql_printTypmod(buf, typemod, typmodout);
	}

	ReleaseSysCache(tuple);

	return buf;
}

/*
 * Add typmod decoration to the basic type name
 */
static char *
tsql_printTypmod(const char *typname, int32 typmod, Oid typmodout)
{
	char	   *res;

	/* Shouldn't be called if typmod is -1 */
	Assert(typmod >= 0);

	if (typmodout == InvalidOid)
	{
		/* Default behavior: just print the integer typmod with parens */
		res = psprintf("%s(%d)", typname, (int) typmod);
	}
	else
	{
		/* Use the type-specific typmodout procedure */
		char	   *tmstr;

		tmstr = DatumGetCString(OidFunctionCall1(typmodout,
												 Int32GetDatum(typmod)));
		res = psprintf("%s%s", typname, tmstr);
	}
	return res;
}

/*
 * Given a collation oid, this function generates the BBF collation name and
 * looks up in the reverse translation table to check if it's equivalent TSQL collation
 * name exists. If exists, it returns the TSQL collation name. Otherwise,
 * it returns the BBF collation name.
 */
char *
generate_tsql_collation_name(Oid collOid)
{
	char	   *res = NULL;
	char	   *translated_res = NULL;

	res = generate_collation_name(collOid);
	if (res)
		translated_res = (char *) tsql_translate_bbf_collation_to_tsql_collation(res);

	if (translated_res)
	{
		pfree(res);
		return translated_res;
	}
	return res;
}
