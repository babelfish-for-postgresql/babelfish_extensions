/*-------------------------------------------------------------------------
 *
 * pltsql_compare.c
 *    Parse tree comparison harness for validation testing.
 *
 * Provides pltsql_compare_parse_trees() which compares two PLtsql_stmt_block
 * trees field-by-field using the generated equality functions.
 *
 * Gated behind babelfishpg_tsql.validate_parse_cache GUC.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "nodes/nodes.h"
#include "lib/stringinfo.h"
#include "utils/builtins.h"

#include "src/pltsql.h"
#include "src/pltsql-2.h"

/* From pltsql_equalfuncs.c */
extern bool pltsql_equal_node(const void *a, const void *b);

/* Forward declaration */
extern bool pltsql_compare_parse_trees(PLtsql_stmt_block *tree_a,
                                       PLtsql_stmt_block *tree_b);

/*
 * pltsql_compare_parse_trees
 *    Compare two PLtsql_stmt_block trees for structural equality.
 *
 * Uses generated equality functions. On mismatch, the generated _equal*
 * functions log which node type and field differ at DEBUG1 level.
 */
bool
pltsql_compare_parse_trees(PLtsql_stmt_block *tree_a,
                           PLtsql_stmt_block *tree_b)
{
	if (tree_a == NULL && tree_b == NULL)
		return true;
	if (tree_a == NULL || tree_b == NULL)
	{
		elog(DEBUG1, "pltsql_validate_parse_cache[FAIL]: pltsql_compare_parse_trees: one tree is NULL");
		return false;
	}

	return pltsql_equal_node(tree_a, tree_b);
}
