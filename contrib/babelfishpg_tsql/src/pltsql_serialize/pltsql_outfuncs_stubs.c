/*-------------------------------------------------------------------------
 *
 * pltsql_outfuncs_stubs.c
 *    Custom _out (serialization) implementations for PLtsql custom_read_write
 *    nodes.
 *
 * These functions implement serialization for PLtsql node types that are
 * marked pg_node_attr(custom_read_write) in pltsql_serializable.h:
 *   - PLtsql_expr: has runtime-only fields that must be skipped
 *   - PLtsql_nsitem: has FLEXIBLE_ARRAY_MEMBER requiring special handling
 *   - PLtsql_row: has string/int arrays requiring custom handling
 *   - PLtsql_recfield: has inline struct (finfo) that gen_node_support.pl
 *     cannot handle
 *
 * The corresponding _read (deserialization) functions are in
 * pltsql_readfuncs_stubs.c.
 *
 * These are called by the generated pltsql_outfuncs_switch.c dispatch code
 * when pltsql_outNode() encounters these types.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "nodes/nodes.h"
#include "nodes/bitmapset.h"
#include "lib/stringinfo.h"

#include "src/pltsql.h"
#include "src/pltsql-2.h"

#include "pltsql_serialize_macros.h"

/*
 * Forward declarations for custom_read_write _out functions.
 * Required by -Werror=missing-prototypes.
 */
extern void _outPLtsql_nsitem(StringInfo str, const PLtsql_nsitem *node);
extern void _outPLtsql_expr(StringInfo str, const PLtsql_expr *node);
extern void _outPLtsql_row(StringInfo str, const PLtsql_row *node);
extern void _outPLtsql_recfield(StringInfo str, const PLtsql_recfield *node);


/* ----------------------------------------------------------------
 *                    PLtsql_nsitem (custom_read_write)
 *
 * Has FLEXIBLE_ARRAY_MEMBER for name[], so cannot use makeNode.
 * The prev pointer forms a linked list (namespace chain).
 * ----------------------------------------------------------------
 */
void
_outPLtsql_nsitem(StringInfo str, const PLtsql_nsitem *node)
{
	if (node == NULL)
	{
		appendStringInfoString(str, "<>");
		return;
	}

	/* Note: outNode() already writes the opening '{' before calling us */
	WRITE_NODE_TYPE("PLTSQL_NSITEM");
	WRITE_ENUM_FIELD(itemtype, PLtsql_nsitem_type);
	WRITE_INT_FIELD(itemno);

	/* Serialize prev as a nested node (recursive, via pltsql_outNode for proper bracing) */
	appendStringInfoString(str, " :prev ");
	pltsql_outNode(str, node->prev);

	/* Serialize flexible array member as a string */
	appendStringInfoString(str, " :name ");
	outToken(str, node->name);

	/* Note: outNode() writes the closing '}' after we return */
}

/* ----------------------------------------------------------------
 *                    PLtsql_expr (custom_read_write)
 *
 * Has many read_write_ignore fields (runtime-only: plan, func,
 * expr_simple_*). Only serializes: query, paramnos, rwparam, ns,
 * itvf_query.
 * ----------------------------------------------------------------
 */
void
_outPLtsql_expr(StringInfo str, const PLtsql_expr *node)
{
	if (node == NULL)
	{
		appendStringInfoString(str, "<>");
		return;
	}

	/* Note: outNode() already writes the opening '{' before calling us */
	WRITE_NODE_TYPE("PLTSQL_EXPR");
	WRITE_STRING_FIELD(query);
	/* plan: read_write_ignore */
	WRITE_BITMAPSET_FIELD(paramnos);
	WRITE_INT_FIELD(rwparam);
	/* func: read_write_ignore */

	/* ns: serialize the namespace chain */
	appendStringInfoString(str, " :ns ");
	pltsql_outNode(str, node->ns);

	/* expr_simple_*: all read_write_ignore */
	WRITE_STRING_FIELD(itvf_query);
	/* Note: outNode() writes the closing '}' after we return */
}

/* ----------------------------------------------------------------
 *                    PLtsql_row (custom_read_write)
 *
 * Has string array (fieldnames) and int array (varnos) with
 * array_size(nfields). rowtupdesc is read_write_ignore.
 * ----------------------------------------------------------------
 */
void
_outPLtsql_row(StringInfo str, const PLtsql_row *node)
{
	int			i;

	if (node == NULL)
	{
		appendStringInfoString(str, "<>");
		return;
	}

	/* Note: outNode() already writes the opening '{' before calling us */
	WRITE_NODE_TYPE("PLTSQL_ROW");
	WRITE_ENUM_FIELD(dtype, PLtsql_datum_type);
	WRITE_INT_FIELD(dno);
	WRITE_STRING_FIELD(refname);
	WRITE_INT_FIELD(lineno);
	WRITE_BOOL_FIELD(isconst);
	WRITE_BOOL_FIELD(notnull);

	/* default_val is a PLtsql_expr pointer */
	appendStringInfoString(str, " :default_val ");
	pltsql_outNode(str, node->default_val);

	/* rowtupdesc: read_write_ignore */
	WRITE_INT_FIELD(nfields);

	/* fieldnames: string array of size nfields */
	appendStringInfoString(str, " :fieldnames");
	for (i = 0; i < node->nfields; i++)
	{
		appendStringInfoChar(str, ' ');
		outToken(str, node->fieldnames[i]);
	}

	/* varnos: int array of size nfields */
	appendStringInfoString(str, " :varnos");
	for (i = 0; i < node->nfields; i++)
		appendStringInfo(str, " %d", node->varnos[i]);

	/* Note: outNode() writes the closing '}' after we return */
}

/* ----------------------------------------------------------------
 *                    PLtsql_recfield (custom_read_write)
 *
 * Has ExpandedRecordFieldInfo finfo (inline struct) which
 * gen_node_support.pl cannot handle with read_as().
 * Only serialize: dtype, dno, fieldname, recparentno, nextfield.
 * rectupledescid and finfo are runtime cache — zeroed by makeNode.
 * ----------------------------------------------------------------
 */
void
_outPLtsql_recfield(StringInfo str, const PLtsql_recfield *node)
{
	if (node == NULL)
	{
		appendStringInfoString(str, "<>");
		return;
	}

	WRITE_NODE_TYPE("PLTSQL_RECFIELD");
	WRITE_ENUM_FIELD(dtype, PLtsql_datum_type);
	WRITE_INT_FIELD(dno);
	WRITE_STRING_FIELD(fieldname);
	WRITE_INT_FIELD(recparentno);
	WRITE_INT_FIELD(nextfield);
	/* rectupledescid: runtime cache, skip */
	/* finfo: runtime cache, skip */
}
