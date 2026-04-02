/*-------------------------------------------------------------------------
 *
 * pltsql_nodeio.c
 *    Extension-side node serialization/deserialization dispatch.
 *
 * Provides pltsql_nodeToString() and pltsql_stringToNode() as the public
 * API for serializing/deserializing PLtsql parse trees.
 *
 * These functions handle PLtsql node types directly via the generated
 * _out/_read switch files, and delegate standard PG node types to the
 * engine public outNode() / nodeRead() functions.
 *
 * This eliminates the need for outNode_hook / parseNodeString_hook in
 * the PG engine, achieving complete decoupling.
 *
 * Adapted from PG outfuncs.c, read.c, and readfuncs.c dispatch logic.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "nodes/nodes.h"
#include "nodes/bitmapset.h"
#include "nodes/value.h"
#include "nodes/readfuncs.h"
#include "lib/stringinfo.h"

#include "src/pltsql.h"
#include "src/pltsql-2.h"

/*
 * Forward declarations for functions defined in this file.
 * pltsql_nodeToString and pltsql_stringToNode are the public API.
 * The rest are static helpers.
 */
extern char *pltsql_nodeToString(const void *obj);
extern void *pltsql_stringToNode(const char *str);
extern void pltsql_outNode(StringInfo str, const void *obj);

static void pltsql_outList(StringInfo str, const List *node);

/*
 * Forward declarations for generated/hand-written _out* functions.
 * These are defined in pltsql_outfuncs.c (which #includes the generated
 * pltsql_outfuncs_gen.c and pltsql_outfuncs_switch.c).
 */
extern void _outPLtsql_nsitem(StringInfo str, const PLtsql_nsitem *node);
extern void _outPLtsql_expr(StringInfo str, const PLtsql_expr *node);
extern void _outPLtsql_row(StringInfo str, const PLtsql_row *node);
extern void _outPLtsql_recfield(StringInfo str, const PLtsql_recfield *node);

/*
 * Pull in the generated static _out* functions.
 * These must be in the same compilation unit as the switch that calls them.
 */
#include "pltsql_serialize_macros.h"
#include "pltsql_outfuncs_gen.c"


/* ----------------------------------------------------------------
 * Helper: check if a NodeTag is a PLtsql extension type.
 * Uses the generated defines from pltsql_nodetags.h.
 * ----------------------------------------------------------------
 */
static inline bool
is_pltsql_node(const void *obj)
{
	int tag = (int) nodeTag(obj);

	return (tag >= (int) T_PLtsql_type &&
			tag <= (int) T_PLtsql_stmt_restore_ctx_partial);
}


/* ================================================================
 * SERIALIZE (WRITE) SIDE
 * ================================================================
 */

/*
 * pltsql_outList - serialize a List to StringInfo.
 *
 * Adapted from PG's _outList() in outfuncs.c.
 * The only change: calls pltsql_outNode() per element instead of
 * PG's outNode(), so PLtsql nodes inside Lists are handled by us.
 */
static void
pltsql_outList(StringInfo str, const List *node)
{
	const ListCell *lc;

	appendStringInfoChar(str, '(');

	if (IsA(node, IntList))
		appendStringInfoChar(str, 'i');
	else if (IsA(node, OidList))
		appendStringInfoChar(str, 'o');
	else if (IsA(node, XidList))
		appendStringInfoChar(str, 'x');

	foreach(lc, node)
	{
		if (IsA(node, List))
		{
			pltsql_outNode(str, lfirst(lc));
			if (lnext(node, lc))
				appendStringInfoChar(str, ' ');
		}
		else if (IsA(node, IntList))
			appendStringInfo(str, " %d", lfirst_int(lc));
		else if (IsA(node, OidList))
			appendStringInfo(str, " %u", lfirst_oid(lc));
		else if (IsA(node, XidList))
			appendStringInfo(str, " %u", lfirst_xid(lc));
		else
			elog(ERROR, "unrecognized list node type: %d",
				 (int) node->type);
	}

	appendStringInfoChar(str, ')');
}

/*
 * pltsql_outNode - serialize a node to StringInfo.
 *
 * Adapted from PG's outNode() in outfuncs.c.
 * Routes PLtsql nodes to our generated _out* functions, Lists to
 * pltsql_outList(), and everything else to PG's outNode().
 */
void
pltsql_outNode(StringInfo str, const void *obj)
{
	check_stack_depth();

	if (obj == NULL)
	{
		appendStringInfoString(str, "<>");
		return;
	}

	/* Lists: use our walker so PLtsql elements are dispatched correctly */
	if (IsA(obj, List) || IsA(obj, IntList) || IsA(obj, OidList) ||
		IsA(obj, XidList))
	{
		pltsql_outList(str, obj);
		return;
	}

	/* PLtsql nodes: dispatch to our generated/hand-written _out* functions */
	if (is_pltsql_node(obj))
	{
		appendStringInfoChar(str, '{');
		switch ((int) nodeTag(obj))
		{
#include "pltsql_outfuncs_switch.c"

			default:
				elog(ERROR, "pltsql_outNode: unrecognized PLtsql node type: %d",
					 (int) nodeTag(obj));
				break;
		}
		appendStringInfoChar(str, '}');
		return;
	}

	/*
	 * PG nodes (TypeName, Integer, Float, Boolean, String, BitString,
	 * Bitmapset, etc.): delegate to PG's public outNode().
	 */
	outNode(str, obj);
}

/*
 * pltsql_nodeToString - serialize a PLtsql node tree to a palloc'd string.
 *
 * Public entry point. Call this instead of nodeToString() when serializing
 * PLtsql parse trees (function->action, datum lists, etc.).
 */
char *
pltsql_nodeToString(const void *obj)
{
	StringInfoData str;

	initStringInfo(&str);
	pltsql_outNode(&str, obj);
	return str.data;
}

/* End of write-side functions */
