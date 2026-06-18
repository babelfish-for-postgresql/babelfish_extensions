/*-------------------------------------------------------------------------
 *
 * pltsql_equalfuncs.c
 *    PLtsql node equality comparison and parse tree comparison.
 *
 *-------------------------------------------------------------------------
 */
#include "pltsql_node_macros.h"
#include "pltsql_serialize.h"

/*
 * Stub equality functions for custom_read_write nodes.
 * These are referenced by the generated switch but skipped from gen code.
 * List comparison is handled by pltsql_equal_nodes_or_equal() in the
 * macros header, so no _equalList stub is needed here.
 */
static bool
_equalPLtsql_row(const PLtsql_row *a, const PLtsql_row *b)
{
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
	COMPARE_SCALAR_FIELD(itemtype);
	/* skip itemno — datum numbering differs between CREATE/EXEC contexts */
	/*COMPARE_SCALAR_FIELD(itemno);*/
	COMPARE_NODE_FIELD(prev);
	COMPARE_STRING_FIELD(name);
	return true;
}

static bool
_equalPLtsql_stmt_dbcc(const PLtsql_stmt_dbcc *a, const PLtsql_stmt_dbcc *b)
{
	COMPARE_SCALAR_FIELD(cmd_type);
	COMPARE_SCALAR_FIELD(dbcc_stmt_type);

	switch (a->dbcc_stmt_type)
	{
		case PLTSQL_DBCC_CHECKIDENT:
			COMPARE_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.db_name);
			COMPARE_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.schema_name);
			COMPARE_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.table_name);
			COMPARE_SCALAR_FIELD(dbcc_stmt_data.dbcc_checkident.is_reseed);
			COMPARE_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.new_reseed_value);
			COMPARE_SCALAR_FIELD(dbcc_stmt_data.dbcc_checkident.no_infomsgs);
			break;
		default:
			elog(ERROR, "_equalPLtsql_stmt_dbcc: unsupported dbcc_stmt_type %d",
				 a->dbcc_stmt_type);
			return false;
	}
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
			elog(ERROR, "pltsql_equal_node: unknown PLtsql node type: %d", (int) nodeTag(a));
			retval = false;	/* unreachable, keeps compiler quiet */
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
		elog(PANIC, "pltsql_validate_antlr_parse_cache[FAIL]: pltsql_compare_parse_trees: one tree is NULL (tree_a=%p, tree_b=%p)",
			 (void *) tree_a, (void *) tree_b);
		return false;
	}

	return pltsql_equal_node(tree_a, tree_b);
}

/*
 * pltsql_compare_datum_arrays
 *    Compare two datum arrays using a two-pointer walk.
 *
 * The ANTLR EXEC-time compilation creates duplicate datums for local
 * variables (the cached array from CREATE has them once, ANTLR re-parse
 * appends them again). A naive positional comparison would cascade a
 * single extra datum into N false mismatches. The ANTLR datums array is
 * always >= cached in length.
 *
 * This uses lookahead: On mismatch, try skipping one ANTLR datum to resynchronize 
 * equality check (handles the duplicate case). Reports genuine mismatches separately
 * from extra (duplicate) ANTLR datums.
 */
void
pltsql_compare_datum_arrays(const char *fn_signature,
                            PLtsql_datum **cached_datums, int cached_ndatums,
                            PLtsql_datum **antlr_datums, int antlr_ndatums)
{
	int		ci = 0;				/* cached index */
	int		ai = 0;				/* antlr index */
	int		mismatches = 0;
	int		extra_antlr = 0;

	while (ci < cached_ndatums && ai < antlr_ndatums)
	{
		PLtsql_datum *dc = cached_datums[ci];
		PLtsql_datum *da = antlr_datums[ai];

		if (dc == NULL && da == NULL)
		{
			ci++;
			ai++;
			continue;
		}

		if (dc != NULL && da != NULL && pltsql_equal_node(dc, da))
		{
			ci++;
			ai++;
			continue;
		}

		/* Mismatch — try skipping one ANTLR datum to resync */
		if (ai + 1 < antlr_ndatums && dc != NULL &&
			pltsql_equal_node(dc, antlr_datums[ai + 1]))
		{
			extra_antlr++;
			ai++;
			continue;
		}

		/* Genuine mismatch — advance both */
		mismatches++;
		elog(WARNING, "pltsql_validate_antlr_parse_cache[DIFF]: %s datum mismatch "
			 "at cached[%d] vs antlr[%d] (cached_tag=%d, antlr_tag=%d)",
			 fn_signature, ci, ai,
			 dc ? (int) nodeTag(dc) : -1,
			 da ? (int) nodeTag(da) : -1);
		ci++;
		ai++;
	}

	/* Remaining unmatched ANTLR datums at the tail (expected duplicates) */
	extra_antlr += (antlr_ndatums - ai);

	/* Remaining unmatched cached datums would be unexpected */
	if (ci < cached_ndatums)
		mismatches += (cached_ndatums - ci);

	elog((mismatches == 0) ? DEBUG1 : WARNING, "pltsql_validate_antlr_parse_cache[%s]: %s PLtsql Datums comparison "
		 "at EXEC (cached=%d, antlr=%d, mismatches=%d, extra_antlr=%d)",
		 (mismatches == 0) ? "PASS" : "DIFF",
		 fn_signature,
		 cached_ndatums, antlr_ndatums,
		 mismatches, extra_antlr);
}
