/*-------------------------------------------------------------------------
 *
 * pltsql_readfuncs.c
 *    Wrapper for PLtsql node deserialization (readfuncs).
 *
 * Mirrors the engine's readfuncs.c pattern: includes the generated
 * static _read* functions (pltsql_readfuncs_gen.c) and the MATCH-based
 * dispatch fragment (pltsql_readfuncs_switch.c).
 *
 * Provides pltsql_parseNodeString() as the public entry point for
 * deserializing PLtsql node types.
 *
 *-------------------------------------------------------------------------
 */
#include "pltsql_serialize_macros.h"

/* Forward declaration — satisfies -Werror=missing-prototypes */
extern Node *pltsql_parseNodeString(const char *token, int length);

/* Forward declarations for custom_read_write nodes (defined in pltsql_node_stubs.c).
 * The switch file references these but they aren't in the generated gen file. */
extern PLtsql_nsitem *_readPLtsql_nsitem(void);
extern PLtsql_expr *_readPLtsql_expr(void);
extern PLtsql_row *_readPLtsql_row(void);
extern PLtsql_recfield *_readPLtsql_recfield(void);

/* Pull in the generated static _read* functions — same as engine's
 * #include "readfuncs.funcs.c" inside readfuncs.c */
#include "pltsql_readfuncs_gen.c"

/*
 * pltsql_parseNodeString - deserialize a PLtsql node from token stream.
 *
 * Called by the engine's parseNodeString() via hook when it encounters
 * a PLtsql node type token.  token/length are already set by the caller.
 */
Node *
pltsql_parseNodeString(const char *token, int length)
{
#include "pltsql_readfuncs_switch.c"

	return NULL;  /* not a PLtsql node type */
}
