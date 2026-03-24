/*-------------------------------------------------------------------------
 *
 * pltsql_node_stubs.c
 *    Custom read/write implementations for PLtsql custom_read_write nodes.
 *
 * These functions implement serialization/deserialization for PLtsql node
 * types that are marked pg_node_attr(custom_read_write) in
 * pltsql_serializable.h:
 *   - PLtsql_expr: has runtime-only fields that must be skipped
 *   - PLtsql_nsitem: has FLEXIBLE_ARRAY_MEMBER requiring special allocation
 *   - PLtsql_row: has string/int arrays requiring custom handling
 *
 * These are called by the generated outfuncs.switch.c / readfuncs.switch.c
 * dispatch code when nodeToString/stringToNode encounters these types.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "nodes/nodes.h"
#include "nodes/bitmapset.h"
#include "nodes/readfuncs.h"
#include "lib/stringinfo.h"
/*
 * On the extension side we include pltsql.h and pltsql-2.h directly — they have
 * the real struct definitions that the serializable headers mirror.
 */
#include "src/pltsql.h"
#include "src/pltsql-2.h"
#include "nodes/parsenodes.h"  /* for TypeName */
#include "nodes/execnodes.h"   /* for ExprState */

#include "pltsql_serialize_macros.h"

/*
 * Forward declarations for custom_read_write functions.
 * Required by -Werror=missing-prototypes.
 */
extern void _outPLtsql_nsitem(StringInfo str, const PLtsql_nsitem *node);
extern PLtsql_nsitem *_readPLtsql_nsitem(void);
extern void _outPLtsql_expr(StringInfo str, const PLtsql_expr *node);
extern PLtsql_expr *_readPLtsql_expr(void);
extern void _outPLtsql_row(StringInfo str, const PLtsql_row *node);
extern PLtsql_row *_readPLtsql_row(void);
extern void _outPLtsql_recfield(StringInfo str, const PLtsql_recfield *node);
extern PLtsql_recfield *_readPLtsql_recfield(void);

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

	/* Serialize prev as a nested node (recursive, via outNode for proper bracing) */
	appendStringInfoString(str, " :prev ");
	outNode(str, node->prev);

	/* Serialize flexible array member as a string */
	appendStringInfoString(str, " :name ");
	outToken(str, node->name);

	/* Note: outNode() writes the closing '}' after we return */
}

PLtsql_nsitem *
_readPLtsql_nsitem(void)
{
	const char *token;
	int			length;
	int			itemtype;
	int			itemno;
	PLtsql_nsitem *prev;
	char	   *name_str;
	PLtsql_nsitem *result;

	/* Read itemtype */
	token = pg_strtok(&length);		/* skip :itemtype */
	token = pg_strtok(&length);		/* get value */
	itemtype = atoi(token);

	/* Read itemno */
	token = pg_strtok(&length);		/* skip :itemno */
	token = pg_strtok(&length);		/* get value */
	itemno = atoi(token);

	/* Read prev (recursive) */
	token = pg_strtok(&length);		/* skip :prev */
	prev = (PLtsql_nsitem *) nodeRead(NULL, 0);

	/* Read name */
	token = pg_strtok(&length);		/* skip :name */
	token = pg_strtok(&length);		/* get value */
	name_str = pltsql_nullable_string(token, length);

	/* Allocate with extra space for flexible array member */
	{
		int name_len = name_str ? strlen(name_str) : 0;

		result = (PLtsql_nsitem *) palloc0(offsetof(PLtsql_nsitem, name) + name_len + 1);
		NodeSetTag(result, T_PLtsql_nsitem);
		result->itemtype = (PLtsql_nsitem_type) itemtype;
		result->itemno = itemno;
		result->prev = prev;
		if (name_str)
		{
			memcpy(result->name, name_str, name_len + 1);
			pfree(name_str);
		}
		else
			result->name[0] = '\0';
	}

	return result;
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
	outNode(str, node->ns);

	/* expr_simple_*: all read_write_ignore */
	WRITE_STRING_FIELD(itvf_query);
	/* Note: outNode() writes the closing '}' after we return */
}

PLtsql_expr *
_readPLtsql_expr(void)
{
	READ_LOCALS(PLtsql_expr);

	READ_STRING_FIELD(query);
	/* plan: read_write_ignore, init to NULL (palloc0 via makeNode) */
	READ_BITMAPSET_FIELD(paramnos);
	READ_INT_FIELD(rwparam);
	/* func: read_write_ignore, already NULL from makeNode */

	/* ns: read the namespace chain */
	token = pg_strtok(&length);		/* skip :ns */
	(void) token;
	local_node->ns = (PLtsql_nsitem *) nodeRead(NULL, 0);

	/* expr_simple_*: all read_write_ignore, already zeroed by makeNode */
	READ_STRING_FIELD(itvf_query);

	READ_DONE();
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
	outNode(str, node->default_val);

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

PLtsql_row *
_readPLtsql_row(void)
{
	int			i;

	READ_LOCALS(PLtsql_row);

	READ_ENUM_FIELD(dtype, PLtsql_datum_type);
	READ_INT_FIELD(dno);
	READ_STRING_FIELD(refname);
	READ_INT_FIELD(lineno);
	READ_BOOL_FIELD(isconst);
	READ_BOOL_FIELD(notnull);

	/* default_val: PLtsql_expr pointer */
	token = pg_strtok(&length);		/* skip :default_val */
	(void) token;
	local_node->default_val = (PLtsql_expr *) nodeRead(NULL, 0);

	/* rowtupdesc: read_write_ignore, already NULL from makeNode */
	READ_INT_FIELD(nfields);

	/* fieldnames: string array */
	token = pg_strtok(&length);		/* skip :fieldnames */
	if (local_node->nfields > 0)
	{
		local_node->fieldnames = (char **) palloc(local_node->nfields * sizeof(char *));
		for (i = 0; i < local_node->nfields; i++)
		{
			token = pg_strtok(&length);
			local_node->fieldnames[i] = pltsql_nullable_string(token, length);
		}
	}

	/* varnos: int array */
	token = pg_strtok(&length);		/* skip :varnos */
	if (local_node->nfields > 0)
	{
		local_node->varnos = (int *) palloc(local_node->nfields * sizeof(int));
		for (i = 0; i < local_node->nfields; i++)
		{
			token = pg_strtok(&length);
			local_node->varnos[i] = atoi(token);
		}
	}

	READ_DONE();
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

PLtsql_recfield *
_readPLtsql_recfield(void)
{
	READ_LOCALS(PLtsql_recfield);

	READ_ENUM_FIELD(dtype, PLtsql_datum_type);
	READ_INT_FIELD(dno);
	READ_STRING_FIELD(fieldname);
	READ_INT_FIELD(recparentno);
	READ_INT_FIELD(nextfield);
	/* rectupledescid: zeroed by makeNode */
	/* finfo: zeroed by makeNode */

	READ_DONE();
}

