/*-------------------------------------------------------------------------
 *
 * pltsql_equalfuncs.c
 *    Wrapper for PLtsql node equality comparison (equalfuncs).
 *
 * Mirrors the engine's equalfuncs.c pattern: includes the generated
 * static _equal* functions (pltsql_equalfuncs_gen.c) and the switch
 * dispatch fragment (pltsql_equalfuncs_switch.c).
 *
 * Provides pltsql_equal_node() as the public entry point for comparing
 * PLtsql node types field-by-field.
 *
 * Used for parse tree validation (PoC testing): comparing an ANTLR-compiled
 * tree against a serialized-then-deserialized tree to verify round-trip
 * correctness.
 *
 *-------------------------------------------------------------------------
 */
#include "pltsql_serialize_macros.h"

/* Forward declaration */
extern bool pltsql_equal_node(const void *a, const void *b);

/*
 * Stub equality functions for custom_read_write / special_read_write nodes.
 * These are referenced by the generated switch but skipped from gen code.
 * For PoC validation, compare via serialized string representation.
 */
static bool
_equalList(const List *a, const List *b)
{
	return pltsql_equal_nodes_or_equal(a, b);
}

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
