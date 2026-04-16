/*-------------------------------------------------------------------------
 *
 * pltsql_readfuncs_stubs.c
 *    Custom deserialization for PLtsql custom_read_write nodes.
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


/* ----------------------------------------------------------------
 *                    PLtsql_stmt_dbcc (custom_read_write)
 *
 * Contains a union (PLtsql_dbcc_stmt_data) keyed by dbcc_stmt_type.
 * Currently only PLTSQL_DBCC_CHECKIDENT is supported.
 * ----------------------------------------------------------------
 */
extern PLtsql_stmt_dbcc *_readPLtsql_stmt_dbcc(void);

PLtsql_stmt_dbcc *
_readPLtsql_stmt_dbcc(void)
{
	READ_LOCALS(PLtsql_stmt_dbcc);

	READ_ENUM_FIELD(cmd_type, PLtsql_stmt_type);
	READ_INT_FIELD(lineno);
	READ_INT_FIELD(dbcc_stmt_type);

	switch (local_node->dbcc_stmt_type)
	{
		case PLTSQL_DBCC_CHECKIDENT:
			READ_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.db_name);
			READ_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.schema_name);
			READ_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.table_name);
			READ_BOOL_FIELD(dbcc_stmt_data.dbcc_checkident.is_reseed);
			READ_STRING_FIELD(dbcc_stmt_data.dbcc_checkident.new_reseed_value);
			READ_BOOL_FIELD(dbcc_stmt_data.dbcc_checkident.no_infomsgs);
			break;
		default:
			elog(ERROR, "_readPLtsql_stmt_dbcc: unsupported dbcc_stmt_type %d",
				 local_node->dbcc_stmt_type);
			break;
	}

	READ_DONE();
}
