/*-------------------------------------------------------------------------
 *
 * pltsql_outfuncs.c
 *    Wrapper for PLtsql node serialization (outfuncs).
 *
 * Mirrors the engine's outfuncs.c pattern: includes the generated
 * static _out* functions (pltsql_outfuncs_gen.c) and the switch
 * dispatch fragment (pltsql_outfuncs_switch.c).
 *
 * Provides pltsql_outNode() as the public entry point for serializing
 * PLtsql node types.
 *
 *-------------------------------------------------------------------------
 */
#include "pltsql_serialize_macros.h"

/* Forward declaration — satisfies -Werror=missing-prototypes */
extern void pltsql_outNode(StringInfo str, const void *obj);

/* Forward declarations for custom_read_write nodes (defined in pltsql_node_stubs.c).
 * The switch file references these but they aren't in the generated gen file. */
extern void _outPLtsql_nsitem(StringInfo str, const PLtsql_nsitem *node);
extern void _outPLtsql_expr(StringInfo str, const PLtsql_expr *node);
extern void _outPLtsql_row(StringInfo str, const PLtsql_row *node);
extern void _outPLtsql_recfield(StringInfo str, const PLtsql_recfield *node);

/* Pull in the generated static _out* functions — same as engine's
 * #include "outfuncs.funcs.c" inside outfuncs.c */
#include "pltsql_outfuncs_gen.c"

/*
 * pltsql_outNode - serialize a PLtsql node to StringInfo.
 *
 * Called by the engine's outNode() via hook when it encounters a
 * PLtsql NodeTag.  The caller has already written the opening '{'.
 */
void
pltsql_outNode(StringInfo str, const void *obj)
{
	switch ((int) nodeTag(obj))
	{
#include "pltsql_outfuncs_switch.c"

		default:
			elog(ERROR, "pltsql_outNode: unrecognized node type: %d",
				 (int) nodeTag(obj));
			break;
	}
}
