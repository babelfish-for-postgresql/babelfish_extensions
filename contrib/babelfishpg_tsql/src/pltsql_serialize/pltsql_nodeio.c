/*-------------------------------------------------------------------------
 *
 * pltsql_nodeio.c
 *    Extension-side node serialization/deserialization dispatch.
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
 * pltsql_serialize.h: public API (pltsql_nodeToString, pltsql_stringToNode)
 * pltsql_serialize_macros.h: internal macros + pltsql_outNode, pltsql_nodeRead
 */
#include "pltsql_serialize.h"
#include "pltsql_serialize_macros.h"

/* Static helpers defined in this file */
static void pltsql_outList(StringInfo str, const List *node);
static Node *pltsql_parseNodeString(void);

/*
 * Forward declarations for hand-written _out* / _read* stub functions.
 * Defined in pltsql_outfuncs_stubs.c / pltsql_readfuncs_stubs.c.
 * Needed here because the generated switch files (included below) call them.
 */
extern void _outPLtsql_nsitem(StringInfo str, const PLtsql_nsitem *node);
extern void _outPLtsql_row(StringInfo str, const PLtsql_row *node);
extern void _outPLtsql_recfield(StringInfo str, const PLtsql_recfield *node);
extern void _outPLtsql_stmt_dbcc(StringInfo str, const PLtsql_stmt_dbcc *node);

extern PLtsql_nsitem *_readPLtsql_nsitem(void);
extern PLtsql_row *_readPLtsql_row(void);
extern PLtsql_recfield *_readPLtsql_recfield(void);
extern PLtsql_stmt_dbcc *_readPLtsql_stmt_dbcc(void);

/* Pull in the generated static _out* and _read* functions. */
#include "pltsql_outfuncs_gen.c"
#include "pltsql_readfuncs_gen.c"


/* ----------------------------------------------------------------
 * Helper: check if a NodeTag is a PLtsql extension type.
 * Uses the generated defines from pltsql_nodetags.h.
 * ----------------------------------------------------------------
 */
static inline bool
is_pltsql_node(const void *obj)
{
	return ((int) nodeTag(obj) >= PLTSQL_NODETAG_START);
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


/* ================================================================
 * DESERIALIZE (READ) SIDE
 * ================================================================
 */

/*
 * Token type constants (from PG read.c, not in any public header).
 * Used by pltsql_tokenType() below.
 */
#define PLTSQL_RIGHT_PAREN	(1000000 + 1)
#define PLTSQL_LEFT_PAREN	(1000000 + 2)
#define PLTSQL_LEFT_BRACE	(1000000 + 3)
#define PLTSQL_OTHER_TOKEN	(1000000 + 4)

/*
 * pltsql_tokenType - classify a token from pg_strtok.
 *
 * Replica of PG static nodeTokenType() in read.c.
 * Returns T_Integer, T_Float, T_Boolean, T_String, T_BitString,
 * or one of the PLTSQL_LEFT_BRACE/PLTSQL_LEFT_PAREN/etc constants.
 */
static NodeTag
pltsql_tokenType(const char *token, int length)
{
	const char *numptr;
	int			numlen;

	numptr = token;
	numlen = length;
	if (*numptr == '+' || *numptr == '-')
		numptr++, numlen--;
	if ((numlen > 0 && isdigit((unsigned char) *numptr)) ||
		(numlen > 1 && *numptr == '.' && isdigit((unsigned char) numptr[1])))
	{
		char	   *endptr;

		errno = 0;
		(void) strtol(token, &endptr, 10);
		if (endptr != token + length || errno == ERANGE)
			return T_Float;
		return T_Integer;
	}
	else if (*token == '(')
		return (NodeTag) PLTSQL_LEFT_PAREN;
	else if (*token == ')')
		return (NodeTag) PLTSQL_RIGHT_PAREN;
	else if (*token == '{')
		return (NodeTag) PLTSQL_LEFT_BRACE;
	else if ((length == 4 && strncmp(token, "true", 4) == 0) ||
			 (length == 5 && strncmp(token, "false", 5) == 0))
		return T_Boolean;
	else if (*token == '"' && length > 1 && token[length - 1] == '"')
		return T_String;
	else if (*token == 'b' || *token == 'x')
		return T_BitString;
	else if (*token == '0' && length > 1 && (token[1] == 'x' || token[1] == 'X'))
		return T_TSQL_HexString;
	else
		return (NodeTag) PLTSQL_OTHER_TOKEN;
}

/*
 * pltsql_parseNodeString - read a node type name and dispatch.
 *
 * Adapted from PG parseNodeString() in readfuncs.c.
 * Tries PLtsql node names first (via generated switch), then falls
 * back to PG parseNodeString() for standard PG types.
 */
static Node *
pltsql_parseNodeString(void)
{
	READ_TEMP_LOCALS();

	check_stack_depth();

	token = pg_strtok(&length);

	/* Try PLtsql node types first */
#define MATCH(tokname, namelen) \
	(length == namelen && memcmp(token, tokname, namelen) == 0)

#include "pltsql_readfuncs_switch.c"

#undef MATCH

	/* Not a PLtsql node - delegate to PG parseNodeString().
	 * Push back the token by resetting pg_strtok to the token position. */
	if (token != NULL)
		pg_strtok_init(token);

	return parseNodeString();
}

/*
 * pltsql_nodeRead - read a serialized node from pg_strtok state.
 *
 * Adapted from PG nodeRead() in read.c.
 * Routes '{' tokens through pltsql_parseNodeString() (which handles
 * both PLtsql and PG types), and '(' list tokens through our own
 * list reader. Everything else delegates to PG nodeRead().
 */
void *
pltsql_nodeRead(const char *token, int tok_len)
{
	Node	   *result;
	NodeTag		type;

	if (token == NULL)
	{
		token = pg_strtok(&tok_len);
		if (token == NULL)
			return NULL;
	}

	type = pltsql_tokenType(token, tok_len);

	switch ((int) type)
	{
		case PLTSQL_LEFT_BRACE:
			result = pltsql_parseNodeString();
			token = pg_strtok(&tok_len);
			if (token == NULL || token[0] != '}')
				elog(ERROR, "did not find '}' at end of input node");
			break;

		case PLTSQL_LEFT_PAREN:
			{
				List	   *l = NIL;

				token = pg_strtok(&tok_len);
				if (token == NULL)
					elog(ERROR, "unterminated List structure");

				if (tok_len == 1 && token[0] == 'i')
				{
					for (;;)
					{
						int val;
						char *endptr;
						token = pg_strtok(&tok_len);
						if (token == NULL)
							elog(ERROR, "unterminated List structure");
						if (token[0] == ')')
							break;
						val = (int) strtol(token, &endptr, 10);
						if (endptr != token + tok_len)
							elog(ERROR, "unrecognized integer: \"%.*s\"", tok_len, token);
						l = lappend_int(l, val);
					}
					result = (Node *) l;
				}
				else if (tok_len == 1 && token[0] == 'o')
				{
					for (;;)
					{
						Oid val;
						char *endptr;
						token = pg_strtok(&tok_len);
						if (token == NULL)
							elog(ERROR, "unterminated List structure");
						if (token[0] == ')')
							break;
						val = (Oid) strtoul(token, &endptr, 10);
						if (endptr != token + tok_len)
							elog(ERROR, "unrecognized OID: \"%.*s\"", tok_len, token);
						l = lappend_oid(l, val);
					}
					result = (Node *) l;
				}
				else if (tok_len == 1 && token[0] == 'x')
				{
					for (;;)
					{
						TransactionId val;
						char *endptr;
						token = pg_strtok(&tok_len);
						if (token == NULL)
							elog(ERROR, "unterminated List structure");
						if (token[0] == ')')
							break;
						val = (TransactionId) strtoul(token, &endptr, 10);
						if (endptr != token + tok_len)
							elog(ERROR, "unrecognized Xid: \"%.*s\"", tok_len, token);
						l = lappend_xid(l, val);
					}
					result = (Node *) l;
				}
				else if (tok_len == 1 && token[0] == 'b')
				{
					Bitmapset *bms = NULL;
					for (;;)
					{
						int val;
						char *endptr;
						token = pg_strtok(&tok_len);
						if (token == NULL)
							elog(ERROR, "unterminated Bitmapset structure");
						if (tok_len == 1 && token[0] == ')')
							break;
						val = (int) strtol(token, &endptr, 10);
						if (endptr != token + tok_len)
							elog(ERROR, "unrecognized integer: \"%.*s\"", tok_len, token);
						bms = bms_add_member(bms, val);
					}
					result = (Node *) bms;
				}
				else
				{
					/* Node list: walk elements through our reader */
					for (;;)
					{
						if (token[0] == ')')
							break;
						l = lappend(l, pltsql_nodeRead(token, tok_len));
						token = pg_strtok(&tok_len);
						if (token == NULL)
							elog(ERROR, "unterminated List structure");
					}
					result = (Node *) l;
				}
				break;
			}

		case PLTSQL_RIGHT_PAREN:
			elog(ERROR, "unexpected right parenthesis");
			result = NULL;
			break;

		case PLTSQL_OTHER_TOKEN:
			if (tok_len == 0)
				result = NULL;	/* "<>" = null pointer */
			else
			{
				elog(ERROR, "unrecognized token: \"%.*s\"", tok_len, token);
				result = NULL;
			}
			break;

		default:
			/* Value types (Integer, Float, Boolean, String, etc.)
			 * - delegate to PG nodeRead() */
			result = (Node *) nodeRead(token, tok_len);
			break;
	}

	return (void *) result;
}

/*
 * pltsql_stringToNode - deserialize a PLtsql node tree from a string.
 *
 * Public entry point. Sets up pg_strtok state via pg_strtok_init(),
 * then calls pltsql_nodeRead() to parse the tree.
 */
void *
pltsql_stringToNode(const char *str)
{
	void	   *retval;

	/* Point tokenizer at our string */
	pg_strtok_init(str);

	retval = pltsql_nodeRead(NULL, 0);

	return retval;
}
