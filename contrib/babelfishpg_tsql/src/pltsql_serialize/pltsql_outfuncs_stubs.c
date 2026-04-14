/*-------------------------------------------------------------------------
 *
 * pltsql_outfuncs_stubs.c
 *    Custom serialization for PLtsql custom_read_write nodes.
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
	WRITE_NODE_TYPE("PLTSQL_RECFIELD");
	WRITE_ENUM_FIELD(dtype, PLtsql_datum_type);
	WRITE_INT_FIELD(dno);
	WRITE_STRING_FIELD(fieldname);
	WRITE_INT_FIELD(recparentno);
	WRITE_INT_FIELD(nextfield);
	/* rectupledescid: runtime cache, skip */
	/* finfo: runtime cache, skip */
}
