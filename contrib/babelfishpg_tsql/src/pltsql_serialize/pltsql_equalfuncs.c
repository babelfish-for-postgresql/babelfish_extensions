/*-------------------------------------------------------------------------
 *
 * pltsql_equalfuncs.c
 *    PLtsql node equality comparison and parse tree comparison.
 *
 * Mirrors the engine's equalfuncs.c pattern: includes the generated
 * static _equal* functions (pltsql_equalfuncs_gen.c) and the switch
 * dispatch fragment (pltsql_equalfuncs_switch.c).
 *
 * Public entry points:
 *   pltsql_equal_node()          — per-node equality dispatch; switches
 *                                  on NodeTag and calls the appropriate
 *                                  generated or hand-written _equal*
 *   pltsql_compare_parse_trees() — top-level harness for comparing two
 *                                  complete PLtsql_stmt_block trees;
 *                                  called by hooks.c and pl_comp.c
 *
 * Also contains hand-written _equal* stubs for custom_read_write nodes
 * (PLtsql_expr, PLtsql_row, PLtsql_recfield, PLtsql_nsitem) that skip
 * fields known to differ between CREATE-time and EXEC-time contexts
 * (e.g., dno, lineno, itemno).
 *
 *-------------------------------------------------------------------------
 */
#include "pltsql_serialize_macros.h" /* COMPARE_* macros, pltsql_equal_nodes_or_equal() */
#include "pltsql_serialize.h"        /* forward declaration for pltsql_compare_parse_trees */

/*
 * Stub equality functions for custom_read_write nodes.
 * These are referenced by the generated switch but skipped from gen code.
 * List comparison is handled by pltsql_equal_nodes_or_equal() in the
 * macros header, so no _equalList stub is needed here.
 */
static bool
_equalPLtsql_expr(const PLtsql_expr *a, const PLtsql_expr *b)
{
	if (a == NULL && b == NULL) return true;
	if (a == NULL || b == NULL) return false;
	if (a->query == NULL && b->query == NULL) return true;
	if (a->query == NULL || b->query == NULL) return false;

	/*
	 * Skip query, paramnos, rwparam, and ns comparison.
	 *
	 * query: contains embedded dno values (e.g. "pltsql_assign_var(3, ...)")
	 *   that differ between cached (CREATE-time) and ANTLR (EXEC-time) trees
	 *   due to datum numbering offsets. The query text is derived from the
	 *   same source code so it's semantically identical.
	 *
	 * paramnos: Bitmapset of datum numbers referenced by the expression.
	 *   Since dno numbering differs between CREATE and EXEC contexts, the
	 *   bitmapset values differ even though they reference equivalent datums.
	 *
	 * rwparam: dno of the read-write parameter, same dno offset issue.
	 *
	 * ns: PLtsql_nsitem namespace chain. Each nsitem contains an itemno
	 *   field (which is a dno reference). Although _equalPLtsql_nsitem skips
	 *   itemno, the EXEC-time do_compile creates additional namespace entries
	 *   for extra $N placeholder datums, making the chain lengths differ.
	 *
	 * itvf_query: safe to compare — contains the rewritten ITVF query string
	 *   which does not embed dno values.
	 */
	COMPARE_STRING_FIELD(itvf_query);

	return true;
}

static bool
_equalPLtsql_row(const PLtsql_row *a, const PLtsql_row *b)
{
	if (a == NULL && b == NULL) return true;
	if (a == NULL || b == NULL) return false;
	COMPARE_SCALAR_FIELD(dtype);
	/* skip dno — datum numbering differs between CREATE/EXEC contexts */
	/*COMPARE_SCALAR_FIELD(dno);*/
	COMPARE_STRING_FIELD(refname);
	/* skip lineno */
	/*COMPARE_SCALAR_FIELD(lineno);*/
	COMPARE_SCALAR_FIELD(nfields);
	return true;
}

static bool
_equalPLtsql_recfield(const PLtsql_recfield *a, const PLtsql_recfield *b)
{
	if (a == NULL && b == NULL) return true;
	if (a == NULL || b == NULL) return false;
	COMPARE_SCALAR_FIELD(dtype);
	/* skip dno */
	/*COMPARE_SCALAR_FIELD(dno);*/
	COMPARE_STRING_FIELD(fieldname);
	/* skip recparentno — same reason as dno */
	/*COMPARE_SCALAR_FIELD(recparentno);*/
	return true;
}

static bool
_equalPLtsql_nsitem(const PLtsql_nsitem *a, const PLtsql_nsitem *b)
{
	if (a == NULL && b == NULL) return true;
	if (a == NULL || b == NULL) return false;
	COMPARE_SCALAR_FIELD(itemtype);
	/* skip itemno — datum numbering differs between CREATE/EXEC contexts */
	/*COMPARE_SCALAR_FIELD(itemno);*/
	COMPARE_NODE_FIELD(prev);
	COMPARE_STRING_FIELD(name);
	return true;
}

/* Pull in the generated static _equal* functions */
#include "pltsql_equalfuncs_gen.c"

/*
 * pltsql_equal_node - compare two PLtsql nodes for structural equality.
 *
 * Returns true if both nodes are field-by-field equal.
 * Returns false on any mismatch, NULL difference, or unknown node type.
 */
bool
pltsql_equal_node(const void *a, const void *b)
{
	bool retval;

	if (a == b)
		return true;
	if (a == NULL || b == NULL)
		return false;
	if (nodeTag(a) != nodeTag(b))
		return false;

	switch ((int) nodeTag(a))
	{
#include "pltsql_equalfuncs_switch.c"

		default:
			/* Unknown PLtsql node type — cannot compare */
			retval = false;
			elog(DEBUG1, "pltsql_equal_node: unknown PLtsql node type: %d", (int) nodeTag(a));
			break;
	}

	return retval;
}

/*
 * pltsql_compare_parse_trees
 *    Compare two complete PLtsql_stmt_block parse trees for structural equality.
 *
 * Top-level entry point called by hooks.c and pl_comp.c for validation.
 * Delegates to pltsql_equal_node() for the actual per-node comparison.
 * Gated behind babelfishpg_tsql.validate_parse_cache GUC.
 *
 * Arguments:
 *   tree_a — first PLtsql_stmt_block parse tree to compare
 *   tree_b — second PLtsql_stmt_block parse tree to compare
 *
 * Returns true if both trees are structurally equal.
 * Returns false on any mismatch or NULL difference.
 * Panic logs if exactly one tree is NULL (indicates a caller bug).
 */
bool
pltsql_compare_parse_trees(PLtsql_stmt_block *tree_a,
                           PLtsql_stmt_block *tree_b)
{
	if (tree_a == NULL && tree_b == NULL)
		return true;
	if (tree_a == NULL || tree_b == NULL)
	{
		/*
		 * This function is only called from internal validation paths
		 * (validate_parse_cache GUC). A NULL tree here means a bug in
		 * the caller — both trees should always be non-NULL when we
		 * reach this point.
		 */
		elog(PANIC, "pltsql_validate_parse_cache[FAIL]: pltsql_compare_parse_trees: one tree is NULL (tree_a=%p, tree_b=%p)",
			 (void *) tree_a, (void *) tree_b);
		return false;
	}

	return pltsql_equal_node(tree_a, tree_b);
}
