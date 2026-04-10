/*-------------------------------------------------------------------------
 *
 * pltsql_serialize.h
 *    Public API for PLtsql node serialization, deserialization, and
 *    comparison.
 *
 * Include this header from files outside the pltsql_serialize/ directory
 * that need to call serialization or comparison functions. This avoids
 * pulling in the internal WRITE_/READ_/COMPARE_ macros from
 * pltsql_serialize_macros.h.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PLTSQL_SERIALIZE_H
#define PLTSQL_SERIALIZE_H

#include "src/pltsql.h"

/* Serialization / deserialization (pltsql_nodeio.c) */
extern char *pltsql_nodeToString(const void *obj);
extern void *pltsql_stringToNode(const char *str);

/* Parse tree comparison (pltsql_equalfuncs.c) */
extern bool pltsql_compare_parse_trees(PLtsql_stmt_block *tree_a,
                                       PLtsql_stmt_block *tree_b);

/* Datum array comparison for validation (pltsql_equalfuncs.c) */
extern void pltsql_compare_datum_arrays(const char *fn_signature,
                                        PLtsql_datum **cached_datums, int cached_ndatums,
                                        PLtsql_datum **antlr_datums, int antlr_ndatums);

/* Per-node equality dispatch (pltsql_equalfuncs.c) */
extern bool pltsql_equal_node(const void *a, const void *b);

#endif /* PLTSQL_SERIALIZE_H */
