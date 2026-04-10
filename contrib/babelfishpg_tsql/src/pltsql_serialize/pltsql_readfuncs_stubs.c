/*-------------------------------------------------------------------------
 *
 * pltsql_readfuncs_stubs.c
 *    Custom _read (deserialization) implementations for PLtsql
 *    custom_read_write nodes.
 *
 * These functions implement deserialization for PLtsql node types that are
 * marked pg_node_attr(custom_read_write) in pltsql_serializable.h:
 *   - PLtsql_expr: has runtime-only fields that must be skipped
 *   - PLtsql_nsitem: has FLEXIBLE_ARRAY_MEMBER requiring special allocation
 *   - PLtsql_row: has string/int arrays requiring custom handling
 *   - PLtsql_recfield: has inline struct (finfo) that gen_node_support.pl
 *     cannot handle
 *
 * The corresponding _out (serialization) functions are in
 * pltsql_outfuncs_stubs.c.
 *
 * These are called by the generated pltsql_readfuncs_switch.c dispatch code
 * when pltsql_nodeRead() encounters these types.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "nodes/nodes.h"
#include "nodes/bitmapset.h"
#include "nodes/readfuncs.h"
#include "lib/stringinfo.h"

#include "src/pltsql.h"
#include "src/pltsql-2.h"

#include "pltsql_serialize_macros.h"

/*
 * Forward declarations for custom_read_write _read functions.
 * Required by -Werror=missing-prototypes.
 */
extern PLtsql_nsitem *_readPLtsql_nsitem(void);
extern PLtsql_row *_readPLtsql_row(void);
extern PLtsql_recfield *_readPLtsql_recfield(void);


/* ----------------------------------------------------------------
 *                    PLtsql_nsitem (custom_read_write)
 *
 * Has FLEXIBLE_ARRAY_MEMBER for name[], so cannot use makeNode.
 * The prev pointer forms a linked list (namespace chain).
 * ----------------------------------------------------------------
 */
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
	int			name_len;

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
	prev = (PLtsql_nsitem *) pltsql_nodeRead(NULL, 0);

	/* Read name */
	token = pg_strtok(&length);		/* skip :name */
	token = pg_strtok(&length);		/* get value */
	name_str = pltsql_nullable_string(token, length);

	/* Allocate with extra space for flexible array member */
	name_len = name_str ? strlen(name_str) : 0;

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

	return result;
}

/* ----------------------------------------------------------------
 *                    PLtsql_row (custom_read_write)
 *
 * Has string array (fieldnames) and int array (varnos) with
 * array_size(nfields). rowtupdesc is read_write_ignore.
 * ----------------------------------------------------------------
 */
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
	local_node->default_val = (PLtsql_expr *) pltsql_nodeRead(NULL, 0);

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
 * Only deserialize: dtype, dno, fieldname, recparentno, nextfield.
 * rectupledescid and finfo are runtime cache — zeroed by makeNode.
 * ----------------------------------------------------------------
 */
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
