/* hook implementation needed in backend gram.y */

#include "postgres.h"

#include "nodes/nodeFuncs.h"
#include "parser/parser.h"
#include "parser/parse_expr.h"
#include "parser/scanner.h"
#include "src/pltsql.h"			/* needed for pltsql_protocol_plugin_ptr */

extern bool babelfish_dump_restore;

void		install_backend_gram_hooks(void);
static List *rewrite_typmod_expr(List *expr_list);
static Node *makeIntConst(int val, int location);
static void TsqlValidateNumericTypmods(List **typmods, bool isNumeric, void *yyscanner);
static bool tsql_is_recursive_cte(WithClause *with_clause);
static void fix_tsql_domain_typmods(TypeName *typname);

void
install_backend_gram_hooks()
{
	rewrite_typmod_expr_hook = rewrite_typmod_expr;
	validate_numeric_typmods_hook = TsqlValidateNumericTypmods;
	check_recursive_cte_hook = tsql_is_recursive_cte;
	fix_domain_typmods_hook = fix_tsql_domain_typmods;
}

/*
 * Some T-SQL domain types, e.g., sys.sysname from PG13, can have wrong typmods
 * so that it can cause a failure during dump and restore. This function detects
 * problematic cases and fixes it.
 */
static void
fix_tsql_domain_typmods(TypeName *typname)
{
	if (!babelfish_dump_restore)
		return;

	/* sys.sysname and sys._ci_sysname should not have typmods */
	if (list_length(typname->names) >= 2 &&
		strcmp(strVal(linitial(typname->names)), "sys") == 0 &&
		(strcmp(strVal(lsecond(typname->names)), "sysname") == 0 ||
		 strcmp(strVal(lsecond(typname->names)), "_ci_sysname") == 0))
		typname->typmods = NIL;
}

static List *
rewrite_typmod_expr(List *expr_list)
{
	/*
	 * Look for ( max ) if we are in tsql dialect, MAX can be used in
	 * sys.varchar, sys.nvarchar, sys.binary and sys.varbinary. map it to
	 * TSQLMaxTypmod
	 */
	Node	   *expr;

	Assert(sql_dialect == SQL_DIALECT_TSQL);

	expr = linitial(expr_list);
	if (list_length(expr_list) == 1 && IsA(expr, ColumnRef))
	{
		ColumnRef  *columnref = (ColumnRef *) expr;

		if (list_length(columnref->fields) == 1)
		{
			char	   *str = ((String *) linitial(columnref->fields))->sval;

			if (strcmp(str, "max") == 0)
				return list_make1(makeIntConst(TSQLMaxTypmod, -1));
		}
	}

	return expr_list;			/* nothing to do */
}

static Node *
makeIntConst(int val, int location)
{
	A_Const    *n = makeNode(A_Const);

	n->val.ival.type = T_Integer;
	n->val.ival.ival = val;
	n->location = location;

	return (Node *) n;
}

/*
 * Validate precision of numeric type is <= TSQLMaxNumPrecision (38)
 * in TSQL dialect or in TSQL session because the client can't handle oversized precision.
 * Set default precision,scale to 18,0 if they're not specified.
 * Set the default scale to 0 if only the precision is specified.
 */
void
TsqlValidateNumericTypmods(List **typmods, bool isNumeric, void *yyscanner)
{
	int			precision = 0;

	if (*typmods == NIL)
	{
		/* Set default precision, sale to 18, 0 */
		*typmods = list_make2(makeIntConst(18, -1), makeIntConst(0, -1));
	}

	Assert((sql_dialect == SQL_DIALECT_TSQL ||
			IS_TDS_CLIENT()) &&
		   list_length(*typmods) <= 2);

	switch (list_length(*typmods))
	{
		case 1:
			{
				Node	   *expr = linitial(*typmods);

				if (IsA(expr, A_Const))
				{
					A_Const    *con = (A_Const *) expr;

					if (IsA(&(con->val), Integer))
						precision = intVal(&(con->val));
					if (precision > TSQLMaxNumPrecision)
					{
						const char *type = isNumeric ?
						"numeric" : "decimal";

						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("The size (%d) given to the type '%s' exceeds the maximum allowed (38)", precision, type),
								 scanner_errposition(con->location, yyscanner)));
					}
				}
				/* Set default scale to 0 when only precision is provided */
				*typmods = list_append_unique(*typmods, makeIntConst(0, -1));
				break;
			}
		case 2:
			{
				Node	   *expr = linitial(*typmods);

				if (IsA(expr, A_Const))
				{
					A_Const    *con = (A_Const *) expr;

					if (IsA(&(con->val), Integer))
						precision = intVal(&(con->val));
					if (precision > TSQLMaxNumPrecision)
					{
						const char *type = isNumeric ?
						"numeric" : "decimal";

						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("The size (%d) given to the type '%s' exceeds the maximum allowed (38)", precision, type),
								 scanner_errposition(con->location, yyscanner)));
					}
				}
				break;
			}
		case 0:
			break;
	}
}

typedef struct
{
	char	   *cur_cte_name;	/* current CTE name */
	List	   *inner_ctes;		/* inner CTE-list list */
	bool		is_recursive;
} CteContext;

/*
 * Traverse the parse tree and identify self reference
 * This function has similar structure as makeDependencyGraphWalker
 * In parse_cte.c
 */
static bool
check_recursive_cte_walker(Node *node, CteContext *context)
{
	if (node == NULL)
		return false;
	if (IsA(node, RangeVar))
	{
		RangeVar   *rv = (RangeVar *) node;

		if (!rv->schemaname)
		{
			ListCell   *lc;

			/* ... but first see if it's captured by an inner WITH */
			foreach(lc, context->inner_ctes)
			{
				List	   *withlist = (List *) lfirst(lc);
				ListCell   *lc2;

				foreach(lc2, withlist)
				{
					CommonTableExpr *cte = (CommonTableExpr *) lfirst(lc2);

					if (strcmp(rv->relname, cte->ctename) == 0)
						return false;	/* yes, so bail out */
				}
			}
			if (strcmp(rv->relname, context->cur_cte_name) == 0)
			{
				context->is_recursive = true;	/* found recursive CTE */
				return true;	/* terminate the worker */
			}
		}
		return false;
	}
	if (IsA(node, SelectStmt))
	{
		SelectStmt *stmt = (SelectStmt *) node;
		ListCell   *lc;

		if (stmt->withClause)
		{
			/*
			 * In T-SQL mode, name resolution follows non-RECURSIVE rule. In
			 * the non-RECURSIVE case, query names are visible to the WITH
			 * items after them and to the main query.
			 */
			ListCell   *cell1;

			context->inner_ctes = lcons(NIL, context->inner_ctes);
			cell1 = list_head(context->inner_ctes);
			foreach(lc, stmt->withClause->ctes)
			{
				CommonTableExpr *cte = (CommonTableExpr *) lfirst(lc);

				check_recursive_cte_walker(cte->ctequery, context);
				lfirst(cell1) = lappend((List *) lfirst(cell1), cte);
			}
			(void) raw_expression_tree_walker(node,
											  check_recursive_cte_walker,
											  (void *) context);
			context->inner_ctes = list_delete_first(context->inner_ctes);
		}
	}
	if (IsA(node, WithClause))
	{
		/*
		 * Prevent raw_expression_tree_walker from recursing directly into a
		 * WITH clause.  We need that to happen only under the control of the
		 * code above.
		 */
	}
	return raw_expression_tree_walker(node,
									  check_recursive_cte_walker,
									  (void *) context);
}

/*
 * Identifies potential recursive CTE by checking self reference
 * It is called to mark recursive flag for with clause
 * Invalid RECURSIVE CTEs are handled by transformWithClause
 */
static bool
tsql_is_recursive_cte(WithClause *with_clause)
{
	ListCell   *lc;

	foreach(lc, with_clause->ctes)
	{
		SelectStmt *stmt;
		CommonTableExpr *cte = (CommonTableExpr *) lfirst(lc);
		CteContext	context;

		/* cannot be recursive */
		if (!IsA(cte->ctequery, SelectStmt))
			continue;

		stmt = (SelectStmt *) cte->ctequery;

		/* recursive CTE must have at least one SET OP */
		if (stmt->op == SETOP_NONE)
			continue;

		context.cur_cte_name = cte->ctename;
		context.inner_ctes = NULL;
		context.is_recursive = false;
		check_recursive_cte_walker((Node *) stmt, &context);
		if (context.is_recursive)
			return true;
	}
	return false;
}
