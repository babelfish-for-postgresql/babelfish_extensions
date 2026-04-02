/*-------------------------------------------------------------------------
 *
 * pltsql_serialize_macros.h
 *    Shared WRITE_/READ_ macro definitions for PLtsql serialization.
 *
 * These macros are defined inside PostgreSQL's outfuncs.c / readfuncs.c
 * and are NOT exposed in any public header.  We replicate them here so
 * that both pltsql_node_stubs.c (hand-written) and the generated
 * pltsql_outfuncs_gen.c / pltsql_readfuncs_gen.c can share a single
 * definition.
 *
 * This file also provides pltsql_nullable_string() and helper macros
 * (booltostr, atoui, strtobool) that match readfuncs.c internals.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PLTSQL_SERIALIZE_MACROS_H
#define PLTSQL_SERIALIZE_MACROS_H

#include "postgres.h"

#include "miscadmin.h"
#include "nodes/nodes.h"
#include "nodes/bitmapset.h"
#include "nodes/readfuncs.h"
#include "lib/stringinfo.h"
#include "nodes/parsenodes.h"
#include "nodes/execnodes.h"

#include "src/pltsql.h"
#include "src/pltsql-2.h"

/* ----------------------------------------------------------------
 *  Helper macros (from outfuncs.c / readfuncs.c / equalfuncs.c internals)
 * ----------------------------------------------------------------
 */

/*
 * outfuncs.c macros are not in a header, so we redefine the ones we need.
 * These match the definitions in outfuncs.c exactly.
 */
#define WRITE_NODE_TYPE(nodelabel) \
	appendStringInfoString(str, nodelabel)

#define WRITE_INT_FIELD(fldname) \
	appendStringInfo(str, " :" CppAsString(fldname) " %d", node->fldname)

#define WRITE_UINT_FIELD(fldname) \
	appendStringInfo(str, " :" CppAsString(fldname) " %u", node->fldname)

#define WRITE_BOOL_FIELD(fldname) \
	appendStringInfo(str, " :" CppAsString(fldname) " %s", \
					 booltostr(node->fldname))

#define WRITE_STRING_FIELD(fldname) \
	(appendStringInfoString(str, " :" CppAsString(fldname) " "), \
	 outToken(str, node->fldname))

#define WRITE_ENUM_FIELD(fldname, enumtype) \
	appendStringInfo(str, " :" CppAsString(fldname) " %d", \
					 (int) node->fldname)

/*
 * WRITE_NODE_FIELD — serialize a child node field.
 * Routes through pltsql_outNode() so PLtsql nodes inside Lists and
 * nested fields are handled by our extension dispatcher, not PG's outNode().
 */
extern void pltsql_outNode(StringInfo str, const void *obj);

#define WRITE_NODE_FIELD(fldname) \
	(appendStringInfoString(str, " :" CppAsString(fldname) " "), \
	 pltsql_outNode(str, node->fldname))

#define WRITE_BITMAPSET_FIELD(fldname) \
	(appendStringInfoString(str, " :" CppAsString(fldname) " "), \
	 outBitmapset(str, node->fldname))

/*
 * readfuncs.c macros - redefined here since they're not in a header.
 * Note: READ_LOCALS cannot be used for PLtsql_nsitem (flexible array member),
 * so we handle that case manually.
 */
#define READ_TEMP_LOCALS()	\
	const char *token;		\
	int			length

#define READ_LOCALS_NO_FIELDS(nodeTypeName) \
	nodeTypeName *local_node = makeNode(nodeTypeName)

#define READ_LOCALS(nodeTypeName)			\
	READ_LOCALS_NO_FIELDS(nodeTypeName);	\
	READ_TEMP_LOCALS()

#define READ_INT_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = atoi(token)

#define READ_UINT_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = atoui(token)

#define READ_BOOL_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = strtobool(token)

#define READ_STRING_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = pltsql_nullable_string(token, length)

#define READ_ENUM_FIELD(fldname, enumtype) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = (enumtype) atoi(token)

/*
 * READ_NODE_FIELD - read a child node field.
 * Routes through pltsql_nodeRead() so PLtsql nodes inside Lists and
 * nested fields are handled by our extension dispatcher.
 */
extern void *pltsql_nodeRead(const char *token, int tok_len);

#define READ_NODE_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	(void) token; \
	local_node->fldname = pltsql_nodeRead(NULL, 0)

#define READ_BITMAPSET_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	(void) token; \
	local_node->fldname = readBitmapset()

#define READ_DONE() \
	return local_node

/* Helper macros matching readfuncs.c internals */
#define atoui(x)  ((unsigned int) strtoul((x), NULL, 10))
#define strtobool(x)  ((*(x) == 't') ? true : false)
#define booltostr(x)  ((x) ? "true" : "false")

/*
 * pltsql_nullable_string - local version of nullable_string from readfuncs.c
 *
 * outToken emits <> for NULL, and pg_strtok makes that an empty string.
 */
static inline char *
pltsql_nullable_string(const char *token, int length)
{
	if (length == 0)
		return NULL;
	else if (length == 2 && token[0] == '<' && token[1] == '>')
		return NULL;
	else
		return debackslash(token, length);
}

/*
 * Additional macros needed by generated code (not used by pltsql_node_stubs.c
 * but required by pltsql_outfuncs_gen.c / pltsql_readfuncs_gen.c).
 */
#define WRITE_OID_FIELD(fldname) \
	appendStringInfo(str, " :" CppAsString(fldname) " %u", node->fldname)

#define WRITE_LONG_FIELD(fldname) \
	appendStringInfo(str, " :" CppAsString(fldname) " %ld", node->fldname)

#define WRITE_CHAR_FIELD(fldname) \
	do { \
		char _c = node->fldname; \
		if (_c == '\0') \
			appendStringInfo(str, " :" CppAsString(fldname) " <>"); \
		else { \
			char _in[2]; _in[0] = _c; _in[1] = '\0'; \
			appendStringInfoString(str, " :" CppAsString(fldname) " "); \
			outToken(str, _in); \
		} \
	} while (0)

#define WRITE_INT_ARRAY(fldname, len) \
	do { \
		appendStringInfoString(str, " :" CppAsString(fldname) " "); \
		if (node->fldname) { \
			int _i; \
			appendStringInfoChar(str, '('); \
			for (_i = 0; _i < (len); _i++) \
				appendStringInfo(str, " %d", node->fldname[_i]); \
			appendStringInfoString(str, " )"); \
		} else { \
			appendStringInfoString(str, "<>"); \
		} \
	} while (0)

#define READ_OID_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = atooid(token)

#define READ_LONG_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = atol(token)

#define READ_CHAR_FIELD(fldname) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	token = pg_strtok(&length);		/* get field value */ \
	local_node->fldname = (length == 0) ? '\0' : (token[0] == '\\' ? token[1] : token[0])

#define READ_INT_ARRAY(fldname, len) \
	token = pg_strtok(&length);		/* skip :fldname */ \
	local_node->fldname = readIntCols(len)

/* MATCH macro for readfuncs switch dispatch */
#define MATCH(tokname, namelen) \
	(length == namelen && memcmp(token, tokname, namelen) == 0)


/*
 * equalfuncs.c macros are not in a header, so we redefine the ones we need.
 * These match the definitions in postgresql_modified_for_babelfish/src/backend/nodes/equalfuncs.c exactly.
 */
	

/* Compare a simple scalar field (int, float, bool, enum, etc) */
#define COMPARE_SCALAR_FIELD(fldname) \
	do { \
		if (a->fldname != b->fldname) \
			return false; \
	} while (0)

/* Compare a field that is a pointer to some kind of Node or Node tree.
 * Uses pltsql_equal_nodes_or_equal() to handle both PLtsql and PG node types. */
extern bool pltsql_equal_node(const void *a, const void *b);

static inline bool
pltsql_equal_nodes_or_equal(const void *a, const void *b)
{
	if (a == b)
		return true;
	if (a == NULL || b == NULL)
		return (a == b);

	if (nodeTag(a) != nodeTag(b))
		return false;

	check_stack_depth();

	/* PLtsql node tags are in range 1000-1079 */
	if ((int) nodeTag(a) >= 1000 && (int) nodeTag(a) <= 1079)
		return pltsql_equal_node(a, b);

	/* Lists (all variants): walk elements and check each */
	if (IsA(a, List) || IsA(a, IntList) || IsA(a, OidList) || IsA(a, XidList))
	{
		if(IsA(b, List) || IsA(b, IntList) || IsA(b, OidList) || IsA(b, XidList))
		{
			const List *la = (const List *) a;
			const List *lb = (const List *) b;
			const ListCell *lca, *lcb;

			if (list_length(la) != list_length(lb))
				return false;

			forboth(lca, la, lcb, lb)
			{
				if (!pltsql_equal_nodes_or_equal(lfirst(lca), lfirst(lcb)))
					return false;
			}
			return true;
		}
		else
			return false;
	}

	/* Fall back to PG's equal() for standard node types */
	return equal(a, b);
}

#define COMPARE_NODE_FIELD(fldname) \
	do { \
		if (!pltsql_equal_nodes_or_equal(a->fldname, b->fldname)) \
			return false; \
	} while (0)

/* Compare a field that is a pointer to a Bitmapset */
#define COMPARE_BITMAPSET_FIELD(fldname) \
	do { \
		if (!bms_equal(a->fldname, b->fldname)) \
			return false; \
	} while (0)

/* Compare a field that is a pointer to a C string, or perhaps NULL */
#define COMPARE_STRING_FIELD(fldname) \
	do { \
		if (!equalstr(a->fldname, b->fldname)) \
			return false; \
	} while (0)

/* Macro for comparing string fields that might be NULL */
#define equalstr(a, b)	\
	(((a) != NULL && (b) != NULL) ? (strcmp(a, b) == 0) : (a) == (b))

/* Compare a field that is an inline array */
#define COMPARE_ARRAY_FIELD(fldname) \
	do { \
		if (memcmp(a->fldname, b->fldname, sizeof(a->fldname)) != 0) \
			return false; \
	} while (0)

/* Compare a field that is a pointer to a simple palloc'd object of size sz */
#define COMPARE_POINTER_FIELD(fldname, sz) \
	do { \
		if (memcmp(a->fldname, b->fldname, (sz)) != 0) \
			return false; \
	} while (0)

/* Compare a parse location field (this is a no-op, per note above) */
#define COMPARE_LOCATION_FIELD(fldname) \
	((void) 0)

/* Compare a CoercionForm field (also a no-op, per comment in primnodes.h) */
#define COMPARE_COERCIONFORM_FIELD(fldname) \
	((void) 0)

/*
 * Logging COMPARE macros for equalfuncs — log field name and node type on mismatch.
 * Used by generated pltsql_equalfuncs_gen.c for detailed diff reporting.
 */
#define COMPARE_SCALAR_FIELD_LOG(fldname, nodename) \
	do { \
		if (a->fldname != b->fldname) { \
			elog(LOG, "pltsql_equal: %s.%s differs (a=%d, b=%d)", \
				 nodename, CppAsString(fldname), (int)(a->fldname), (int)(b->fldname)); \
			return false; \
		} \
	} while (0)

#define COMPARE_STRING_FIELD_LOG(fldname, nodename) \
	do { \
		if (!equalstr(a->fldname, b->fldname)) { \
			elog(LOG, "pltsql_equal: %s.%s differs (a=%s, b=%s)", \
				 nodename, CppAsString(fldname), \
				 a->fldname ? a->fldname : "<null>", \
				 b->fldname ? b->fldname : "<null>"); \
			return false; \
		} \
	} while (0)

#define COMPARE_NODE_FIELD_LOG(fldname, nodename) \
	do { \
		if (!pltsql_equal_nodes_or_equal(a->fldname, b->fldname)) { \
			elog(LOG, "pltsql_equal: %s.%s (node field) differs", \
				 nodename, CppAsString(fldname)); \
			return false; \
		} \
	} while (0)

#endif /* PLTSQL_SERIALIZE_MACROS_H */
