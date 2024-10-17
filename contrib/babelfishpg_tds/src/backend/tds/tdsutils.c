/*-------------------------------------------------------------------------
 *
 * tdsutils.c
 *	  TDS Listener utility functions
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdsutils.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/genam.h"
#include "access/htup_details.h"
#include "access/table.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_db_role_setting.h"
#include "catalog/pg_database.h"
#include "commands/dbcommands.h"
#include "src/include/tds_int.h"
#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "parser/parser.h"
#include "parser/parse_node.h"
#include "utils/acl.h"
#include "utils/elog.h"
#include "utils/fmgroids.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "miscadmin.h"
#include "utils/builtins.h"

static int	FindMatchingParam(List *params, const char *name);
static Node *TransformParamRef(ParseState *pstate, ParamRef *pref);
Node	   *TdsFindParam(ParseState *pstate, ColumnRef *cref);
void		TdsErrorContextCallback(void *arg);

/* Create an object_access_hook */
object_access_hook_type next_object_access_hook = NULL;
void		babelfish_object_access(ObjectAccessType access, Oid classId, Oid objectId, int subId, void *arg);

void		tdsutils_ProcessUtility(PlannedStmt *pstmt, const char *queryString, bool readOnlyTree, ProcessUtilityContext context, ParamListInfo params, QueryEnvironment *queryEnv, DestReceiver *dest, QueryCompletion *completionTag);
ProcessUtility_hook_type next_ProcessUtility = NULL;
static void call_next_ProcessUtility(PlannedStmt *pstmt, const char *queryString, bool readOnlyTree, ProcessUtilityContext context, ParamListInfo params, QueryEnvironment *queryEnv, DestReceiver *dest, QueryCompletion *completionTag);
static void check_babelfish_droprole_restrictions(char *role);
static void check_babelfish_alterrole_restictions(bool allow_alter_role_operation);
static void check_babelfish_renamedb_restrictions(Oid target_db_id);
static void check_babelfish_dropdb_restrictions(Oid target_db_id);
static bool is_babelfish_ownership_enabled(ArrayType *array);
static bool is_babelfish_role(const char *role);

/* Role specific handlers */
static bool handle_drop_role(DropRoleStmt *drop_role_stmt);
static bool handle_rename(RenameStmt *rename_stmt);
static bool handle_alter_role(AlterRoleStmt* alter_role_stmt);
static bool handle_alter_role_set (AlterRoleSetStmt* alter_role_set_stmt);
static bool handle_grant_role(GrantRoleStmt *grant_stmt);

/* Drop database handler */
static bool handle_dropdb(DropdbStmt *dropdb_stmt);

static char *get_role_name(RoleSpec *role);
char	   *get_rolespec_name_internal(const RoleSpec *role, bool missing_ok);

/*
 * GetUTF8CodePoint - extract the next Unicode code point from 1..4
 *					  bytes at 'in' in UTF-8 encoding.
 */
static inline int32_t
GetUTF8CodePoint(const unsigned char *in, int len, int *consumed_p)
{
	int32_t		code;
	int			consumed;

	if (len == 0)
		return EOF;

	if ((in[0] & 0x80) == 0)
	{
		/* 1 byte - 0xxxxxxx */
		code = in[0];
		consumed = 1;
	}
	else if ((in[0] & 0xE0) == 0xC0)
	{
		/* 2 byte - 110xxxxx 10xxxxxx */
		if (len < 2)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("truncated UTF8 byte sequence starting with 0x%02x",
							in[0])));
		if ((in[1] & 0xC0) != 0x80)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("invalid UTF8 byte sequence starting with 0x%02x",
							in[0])));
		code = ((in[0] & 0x1F) << 6) | (in[1] & 0x3F);
		consumed = 2;
	}
	else if ((in[0] & 0xF0) == 0xE0)
	{
		/* 3 byte - 1110xxxx 10xxxxxx 10xxxxxx */
		if (len < 3)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("truncated UTF8 byte sequence starting with 0x%02x",
							in[0])));
		if ((in[1] & 0xC0) != 0x80 || (in[2] & 0xC0) != 0x80)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("invalid UTF8 byte sequence starting with 0x%02x",
							in[0])));
		code = ((in[0] & 0x0F) << 12) | ((in[1] & 0x3F) << 6) | (in[2] & 0x3F);
		consumed = 3;
	}
	else if ((in[0] & 0xF8) == 0xF0)
	{
		/* 4 byte - 1110xxxx 10xxxxxx 10xxxxxx 10xxxxxx */
		if (len < 4)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("truncated UTF8 byte sequence starting with 0x%02x",
							in[0])));
		if ((in[1] & 0xC0) != 0x80 || (in[2] & 0xC0) != 0x80 ||
			(in[3] & 0xC0) != 0x80)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("invalid UTF8 byte sequence starting with 0x%02x",
							in[0])));
		code = ((in[0] & 0x07) << 18) | ((in[1] & 0x3F) << 12) |
			((in[2] & 0x3F) << 6) | (in[3] & 0x3F);
		consumed = 4;
	}
	else
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid UTF8 byte sequence starting with 0x%02x",
						in[0])));
	}

	if (code > 0x10FFFF || (code >= 0xD800 && code < 0xE000))
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid UTF8 code point 0x%x", code)));

	if (consumed_p)
		*consumed_p = consumed;

	return code;
}

/* --------------------
 * GetUTF16CodePoint - Extract the next UTF-16 code point from a byte sequence
 *
 *	The code point is extracted from 2 or 4 bytes at 'in'. The optional
 *	'consumed' pointer will be set to the number of bytes actually used.
 *
 *	Returns: next Unicode code point
 *
 *	Will thrown an ERROR if the encoding sequence is invalid as per Unicode
 *	specifications. Wiki claims that some Windows clients can produce invalid
 *	UTF-16 encoding sequences, but any attempt to work around that is a bad
 *	idea. We would silently mangle the data by converting invalid codes to
 *	something else, that will be interpreted differently when the application
 *	gets the data back. It is corrupted (invalid) data we are talking about.
 *	Forcing a square peg into a round hole with a sledge hammer has never
 *	worked out well in the PostgreSQL world.
 * --------------------
 */
static inline int32_t
GetUTF16CodePoint(const unsigned char *in, int len, int *consumed)
{
	uint16_t	code1;
	uint16_t	code2;
	int32_t		result;

	/* Get the first 16 bits */
	code1 = in[1] << 8 | in[0];
	if (code1 < 0xD800 || code1 >= 0xE000)
	{
		/*
		 * This is a single 16 bit code point, which is equal to code1.
		 * PostgreSQL does not support NUL bytes in character data as it
		 * internally needs the ability to convert any datum to a NUL
		 * terminated C-string without explicit length information.
		 */
		if (code1 == 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("invalid UTF16 byte sequence - "
							"code point 0 not supported")));
		if (consumed)
			*consumed = 2;
		return (int32_t) code1;
	}

	/* This is a surrogate pair - check that it is the high part */
	if (code1 >= 0xDC00)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid UTF16 byte sequence - "
						"high part is (0x%02x, 0x%02x)", in[0], in[1])));

	/* Check that there is a second surrogate half */
	if (len < 4)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid UTF16 byte sequence - "
						"only 2 bytes (0x%02x, 0x%02x)", in[0], in[1])));

	/* Get the second 16 bits (low part) */
	code2 = in[3] << 8 | in[2];
	if (code2 < 0xDC00 || code2 > 0xE000)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid UTF16 byte sequence - "
						"low part is (0x%02x, 0x%02x)", in[2], in[3])));

	/* Valid surrogate pair, convert to code point */
	result = ((code1 & 0x03FF) << 10 | (code2 & 0x03FF)) + 0x10000;

	/* Valid 32 bit surrogate code point */
	if (consumed)
		*consumed = 4;
	return result;
}

/*
 * AddUTF8ToStringInfo - Add Unicode code point to a StringInfo in UTF-8
 */
static inline void
AddUTF8ToStringInfo(int32_t code, StringInfo buf)
{
	/* Check that this is a valid code point */
	if ((code > 0xD800 && code < 0xE000) || code < 0x0001 || code > 0x10FFFF)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid Unicode code point 0x%x", code)));

	/* Range U+0000 .. U+007F (7 bit) */
	if (code <= 0x7F)
	{
		appendStringInfoChar(buf, code);
		return;
	}

	/* Range U+0080 .. U+07FF (11 bit) */
	if (code <= 0x7ff)
	{
		appendStringInfoChar(buf, 0xC0 | (code >> 6));
		appendStringInfoChar(buf, 0x80 | (code & 0x3F));
		return;
	}

	/* Range U+0800 .. U+FFFF (16 bit) */
	if (code <= 0xFFFF)
	{
		appendStringInfoChar(buf, 0xE0 | (code >> 12));
		appendStringInfoChar(buf, 0x80 | ((code >> 6) & 0x3F));
		appendStringInfoChar(buf, 0x80 | (code & 0x3F));
		return;
	}

	/* Range U+10000 .. U+10FFFF (21 bit) */
	appendStringInfoChar(buf, 0xF0 | (code >> 18));
	appendStringInfoChar(buf, 0x80 | ((code >> 12) & 0x3F));
	appendStringInfoChar(buf, 0x80 | ((code >> 6) & 0x3F));
	appendStringInfoChar(buf, 0x80 | (code & 0x3F));
}

/*
 * AddUTF16ToStringInfo - Add Unicode code point to a StringInfo in UTF-16
 */
static inline void
AddUTF16ToStringInfo(int32_t code, StringInfo buf)
{
	union
	{
		uint16_t	value;
		uint8_t		half[2];
	}			temp16;

	/* Check that this is a valid code point */
	if ((code > 0xD800 && code < 0xE000) || code < 0x0001 || code > 0x10FFFF)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid Unicode code point 0x%x", code)));

	/* Handle single 16-bit code point */
	if (code <= 0xFFFF)
	{
		appendStringInfoChar(buf, code & 0xFF);
		appendStringInfoChar(buf, (code >> 8) & 0xFF);
		return;
	}

	temp16.value = 0xD800 + (((code - 0x010000) >> 10) & 0x03FF);
	appendStringInfoChar(buf, temp16.half[0]);
	appendStringInfoChar(buf, temp16.half[1]);
	temp16.value = 0xDC00 + ((code - 0x010000) & 0x03FF);
	appendStringInfoChar(buf, temp16.half[0]);
	appendStringInfoChar(buf, temp16.half[1]);
}

/*
 * TdsUTF16toUTF8StringInfo - convert UTF16 data into UTF8 and
 * 								 add it to a StringInfo.
 */
void
TdsUTF16toUTF8StringInfo(StringInfo out, void *vin, int len)
{
	unsigned char *in = vin;
	int			i;
	int			consumed;
	int32_t		code;

	/* UTF16 data allways comes in 16-bit units */
	if ((len & 0x0001) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid UTF16 byte sequence - "
						"input data has odd number of bytes")));

	for (i = 0; i < len;)
	{
		code = GetUTF16CodePoint(&in[i], len - i, &consumed);
		AddUTF8ToStringInfo(code, out);
		i += consumed;
	}
}

/*
 * TdsUTF8toUTF16StringInfo - convert UTF8 data into UTF16 and
 * 								 add it to a StringInfo.
 */
void
TdsUTF8toUTF16StringInfo(StringInfo out, const void *vin, size_t len)
{
	const unsigned char *in = vin;
	size_t		i;
	int			consumed;
	int32_t		code;

	for (i = 0; i < len;)
	{
		code = GetUTF8CodePoint(&in[i], len - i, &consumed);
		AddUTF16ToStringInfo(code, out);
		i += consumed;
	}
}

/*
 * TdsUTF8LengthInUTF16 - compute the length of a UTF8 string in number of
 * 							 16-bit units if we were to convert it into
 * 							 UTF16 with TdsUTF8toUTF16StringInfo()
 * 							 */
int
TdsUTF8LengthInUTF16(const void *vin, int len)
{
	const unsigned char *in = vin;
	int			result = 0;
	int			i;
	int			consumed;
	int32_t		code;

	for (i = 0; i < len;)
	{
		code = GetUTF8CodePoint(&in[i], len - i, &consumed);

		/* Check that this is a valid code point */
		if ((code > 0xD800 && code < 0xE000) || code < 0x0001 || code > 0x10FFFF)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("invalid Unicode code point 0x%x", code)));

		if (code <= 0xFFFF)
			/* This code point would result in a single 16-bit output */
			result += 1;
		else
			/* This code point would result in a 16-bit surrogate pair */
			result += 2;

		i += consumed;
	}

	return result;
}

/* Process the stream headers for message */
int32_t
ProcessStreamHeaders(const StringInfo message)
{
	int32_t		header_len;

	/* We expect at least the packet type and header length */
	if (message->len < 4)
		elog(FATAL, "corrupted TDS_QUERY packet - len=%d",
			 message->len);

	/* Skip the headers */
	memcpy(&header_len, &(message->data[0]), 4);
	if (header_len > message->len)
		elog(FATAL, "corrupted TDS_QUERY packet - "
			 "header length beyond packet end");
	return header_len;
}

/*
 * Returns the parameter number to associate with the given
 * parameter name, or zero if the given name is not found.
 *
 * NOTE: parameter numbers start at 1, not zero, so we
 *       add 1 to the array index below.
 */
static int
FindMatchingParam(List *params, const char *name)
{
	ListCell   *cell;
	int			i = 0;

	foreach(cell, params)
	{
		TdsParamName item = lfirst(cell);

		if (pg_strcasecmp(name, item->name) == 0)
			return i + 1;
		i++;
	}

	return 0;
}

/*
 * Transforms the given ColumnRef to a ParamRef if the name
 * of the column matches the name of one of the parameters
 * found in parameter list returned by TdsGetParamNames().
 *
 * If a match is found, this function returns a new ParamRef
 * node, otherwise it returns NULL and the given ColumnRef
 * should be treated as a ColumnRef.
 */
Node *
TdsFindParam(ParseState *pstate, ColumnRef *cref)
{
	extern int	sql_dialect;
	List	   *params = NULL;

	if (sql_dialect != SQL_DIALECT_TSQL)
		return NULL;

	if (!TdsGetParamNames(&params))
		return NULL;

	if (pstate->p_paramref_hook == NULL)
		return NULL;

	if (list_length(cref->fields) != 1)
		return NULL;
	else
	{
		char	   *colname = strVal(linitial(cref->fields));
		int			paramNo = 0;
		ParamRef   *pref;

		if (params != NULL)
		{
			paramNo = FindMatchingParam(params, colname);
		}
		else
		{
			paramNo = TdsGetAndSetParamIndex(colname);
		}

		if (paramNo == 0)
			return NULL;

		pref = makeNode(ParamRef);

		pref->number = paramNo;
		pref->location = cref->location;

		return TransformParamRef(pstate, pref);
	}
}

static Node *
TransformParamRef(ParseState *pstate, ParamRef *pref)
{
	Node	   *result;

	/*
	 * The core parser knows nothing about Params.  If a hook is supplied,
	 * call it.  If not, or if the hook returns NULL, throw a generic error.
	 */
	if (pstate->p_paramref_hook != NULL)
		result = pstate->p_paramref_hook(pstate, pref);
	else
		result = NULL;

	if (result == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_PARAMETER),
				 errmsg("there is no parameter $%d", pref->number),
				 parser_errposition(pstate, pref->location)));

	return result;
}

/*
 * TDS Error context callback to let us supply a call-stack traceback.
 */
void
TdsErrorContextCallback(void *arg)
{
	TdsErrorContextData *tdsErrorContext = (TdsErrorContextData *) arg;

	/*
	 * err_text should not be NULL. Initialise to Empty String if it need's to
	 * be ignored.
	 */
	Assert(tdsErrorContext != NULL && tdsErrorContext->err_text != NULL);

	switch (tdsErrorContext->reqType)
	{
		case TDS_LOGIN7:		/* Login7 request */
			{
				errcontext("TDS Protocol: Message Type: TDS Login7, Phase: Login. %s",
						   tdsErrorContext->err_text);
			}
			break;
		case TDS_PRELOGIN:		/* Pre-login Request */
			{
				errcontext("TDS Protocol: Message Type: TDS Pre-Login, Phase: Login. %s",
						   tdsErrorContext->err_text);
			}
			break;
		case TDS_QUERY:			/* Simple SQL BATCH */
			{
				errcontext("TDS Protocol: Message Type: SQL BATCH, Phase: %s. %s",
						   tdsErrorContext->phase,
						   tdsErrorContext->err_text);
			}
			break;
		case TDS_RPC:			/* Remote procedure call */
			{
				errcontext("TDS Protocol: Message Type: RPC, SP Type: %s, Phase: %s. %s",
						   tdsErrorContext->spType,
						   tdsErrorContext->phase,
						   tdsErrorContext->err_text);
			}
			break;
		case TDS_TXN:			/* Transaction management request */
			{
				errcontext("TDS Protocol: Message Type: Txn Manager, Txn Type: %s, Phase: %s. %s",
						   tdsErrorContext->txnType,
						   tdsErrorContext->phase,
						   tdsErrorContext->err_text);
			}
			break;
		case TDS_ATTENTION:		/* Attention request */
			{
				errcontext("TDS Protocol: Message Type: Attention, Phase: %s. %s",
						   tdsErrorContext->phase,
						   tdsErrorContext->err_text);
			}
			break;
		case TDS_BULK_LOAD:		/* Bulk Load request */
			{
				errcontext("TDS Protocol: Message Type: Bulk Load, Phase: %s. %s",
						   tdsErrorContext->phase,
						   tdsErrorContext->err_text);
			}
			break;
		default:
			errcontext("TDS Protocol: %s",
					   tdsErrorContext->err_text);
	}
}

void
babelfish_object_access(ObjectAccessType access,
						Oid classId,
						Oid objectId,
						int subId,
						void *arg)
{
	if (next_object_access_hook)
		(*next_object_access_hook) (access, classId, objectId, subId, arg);

	switch (access)
	{
		case OAT_DROP:
			{
				switch (classId)
				{
					case AuthIdRelationId:
						{
							/*
							 * Prevent the user from dropping a babelfish role
							 * when not in babelfish mode by checking for
							 * dependency on the master_guest, tempdb_guest,
							 * and msdb_guest roles. User can override if
							 * needed.
							 */
							if (sql_dialect != SQL_DIALECT_TSQL)
							{
								Oid			bbf_master_guest_oid;
								Oid			bbf_tempdb_guest_oid;
								Oid			bbf_msdb_guest_oid;

								bbf_master_guest_oid = get_role_oid("master_guest", true);
								bbf_tempdb_guest_oid = get_role_oid("tempdb_guest", true);
								bbf_msdb_guest_oid = get_role_oid("msdb_guest", true);
								if (OidIsValid(bbf_master_guest_oid)
									&& OidIsValid(bbf_tempdb_guest_oid)
									&& OidIsValid(bbf_msdb_guest_oid)
									&& is_member_of_role(objectId, bbf_master_guest_oid)
									&& is_member_of_role(objectId, bbf_tempdb_guest_oid)
									&& is_member_of_role(objectId, bbf_msdb_guest_oid)
									&& !enable_drop_babelfish_role)
									ereport(ERROR,
											(errcode(ERRCODE_OBJECT_IN_USE),
											 errmsg("Babelfish-created login cannot be dropped or altered outside of a Babelfish session")));
							}
						}
						break;
					default:
						break;
				}
			}
			break;
		default:
			break;
	}
}

/*
 * tdsutils_ProcessUtility
 *
 * Description: The entry point function into the module (for the most part).  Responsible
 * 	for additional validation for certain statements, and for elevating to real
 * 	superuser for certain commands where we require it.
 *
 * Returns: Nothing
 */
void
tdsutils_ProcessUtility(PlannedStmt *pstmt,
						const char *queryString,
						bool readOnlyTree,
						ProcessUtilityContext context,
						ParamListInfo params,
						QueryEnvironment *queryEnv,
						DestReceiver *dest,
						QueryCompletion *completionTag)
{
	Node	   *parsetree;
	bool		handle_result = true;

	/*
	 * If the given node tree is read-only, make a copy to ensure that parse
	 * transformations don't damage the original tree.  This might cause us to
	 * create unnecessary copies, but in theory the impact of the unnecessary
	 * copies is negligible.
	 */
	if (readOnlyTree)
		pstmt = copyObject(pstmt);
	parsetree = pstmt->utilityStmt;

	/*
	 * Explicitly skip TransactionStmt commands prior to calling the
	 * superuser() function.
	 *
	 * If we are in an aborted transaction, some TransactionStmts (e.g.
	 * ROLLBACK) will be allowed to pass through to the process utility hooks.
	 * In this aborted state, the syscache lookup that superuser() does is not
	 * safe.  However, we do not do any kind of handling for TransactionStmts
	 * in this hook anyway, so we can easily avoid this issue by skipping it.
	 */
	if (parsetree && IsA(parsetree, TransactionStmt))
	{
		call_next_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, completionTag);
		return;
	}

	/* Ignore any of this for real superusers */
	if (superuser())
	{
		call_next_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, completionTag);
		return;
	}
	switch (nodeTag(parsetree))
	{
			/* Role lock down. */
		case T_DropRoleStmt:
			handle_result = handle_drop_role((DropRoleStmt *) parsetree);
			break;
		case T_RenameStmt:
			handle_result = handle_rename((RenameStmt *) parsetree);
			break;
			/* Case that deal with Drop Database */
		case T_DropdbStmt:
			handle_result = handle_dropdb((DropdbStmt *) parsetree);
			break;
		case T_AlterRoleStmt:
			handle_result = handle_alter_role((AlterRoleStmt*)parsetree);
			break;
		case T_AlterRoleSetStmt:
			handle_result = handle_alter_role_set((AlterRoleSetStmt*)parsetree);
			break;
		case T_GrantRoleStmt:
			handle_result = handle_grant_role((GrantRoleStmt *) parsetree);
			break;
		default:
			break;
	}

	/*
	 * handle_result: true - If this is a command that we're not going to
	 * handle, allow it to processed in the normal way. false - Do nothing
	 * else.  We've most likely reported an error, and most likely won't end
	 * up hitting this.
	 */
	if (handle_result)
		call_next_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, completionTag);
}

/*
 * call_next_ProcessUtility
 *
 * Description: Helper function which calls the next ProcessUtility function in
 * 	the chain if one exists, or calls the standard Postgres one if
 * 	we're the only one.
 *
 * Returns: nothing
 */
static void
call_next_ProcessUtility(PlannedStmt *pstmt,
						 const char *queryString,
						 bool readOnlyTree,
						 ProcessUtilityContext context,
						 ParamListInfo params,
						 QueryEnvironment *queryEnv,
						 DestReceiver *dest,
						 QueryCompletion *completionTag)
{
	if (next_ProcessUtility)
		next_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, completionTag);
	else
		standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, completionTag);
}

/*
 * handle_drop_role
 *
 * Description: This function deals with DROP ROLE.
 *
 * Returns: true - should allow statement to continue
 * 	false - otherwise
 */
static bool
handle_drop_role(DropRoleStmt *drop_role_stmt)
{
	ListCell   *item = NULL;

	/* We should not be handling superusers */
	Assert(!superuser());
	Assert(NULL != drop_role_stmt);

	/*
	 * Postgres allows you to drop multiple roles at the same time, which
	 * means we get to parse out the roles by hand.  We could theoretically
	 * allow for skipping this role if it's specified in a list; however,
	 * blocking the statement seems less error prone at this point.
	 */
	foreach(item, drop_role_stmt->roles)
	{
		char	   *role = NULL;

		/* Roles is a list of RoleSpecs now */
		RoleSpec   *node = lfirst(item);

		/* If the role does not exist, the role name will be NULL */
		role = get_role_name(node);
		if (NULL == role)
			continue;

		check_babelfish_droprole_restrictions(role);
		pfree(role);
		role = NULL;
	}
	return true;
}

/*
 * get_role_name
 *
 * Description: This function is used to get the role name
 *
 * Returns: The (palloc'd) role name (or NULL if the role does not exist)
 */
static char *
get_role_name(RoleSpec *role)
{
	Assert(NULL != role);

	/*
	 * get_rolespec_name_internal will return NULL if called for
	 * ROLESPEC_PUBLIC. Postgres will return a different error if the user
	 * tries to modify the public role. It will be a better user experience to
	 * return that instead of tdsutils returning an error here by calling
	 * get_rolespec_name_internal. So return the public role name from here
	 * instead of calling get_rolespec_name_internal.
	 */
	if (ROLESPEC_PUBLIC == role->roletype)
	{
		/* Callers are expecting the return value to be palloc'd */
		return pstrdup(PUBLIC_ROLE_NAME);
	}
	return (char *) get_rolespec_name_internal(role, true);
}

/*
 * Given a RoleSpec, returns a palloc'ed copy of the corresponding role's name.
 * If missing_ok is true and the role does not exist, NULL is returned.  If
 * missing_ok if false and the role does not exists, this function errors out.
 */
char *
get_rolespec_name_internal(const RoleSpec *role, bool missing_ok)
{
	HeapTuple	tp;
	Form_pg_authid authForm;
	char	   *rolename;

	switch (role->roletype)
	{
		case ROLESPEC_CSTRING:
			Assert(role->rolename);
			tp = SearchSysCache1(AUTHNAME, CStringGetDatum(role->rolename));
			if (!HeapTupleIsValid(tp) && !missing_ok)
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_OBJECT),
						 errmsg("role \"%s\" does not exist", role->rolename)));
			break;

		case ROLESPEC_CURRENT_ROLE:
		case ROLESPEC_CURRENT_USER:
			tp = SearchSysCache1(AUTHOID, GetUserId());
			if (!HeapTupleIsValid(tp))
				elog(ERROR, "cache lookup failed for role %u", GetUserId());
			break;

		case ROLESPEC_SESSION_USER:
			tp = SearchSysCache1(AUTHOID, GetSessionUserId());
			if (!HeapTupleIsValid(tp))
				elog(ERROR, "cache lookup failed for role %u", GetSessionUserId());
			break;

		case ROLESPEC_PUBLIC:
			if (!missing_ok)
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_OBJECT),
						 errmsg("role \"%s\" does not exist", "public")));
			tp = NULL;
			break;

		default:
			elog(ERROR, "unexpected role type %d", role->roletype);
	}

	if (!HeapTupleIsValid(tp))
		return NULL;

	authForm = (Form_pg_authid) GETSTRUCT(tp);
	rolename = pstrdup(NameStr(authForm->rolname));
	ReleaseSysCache(tp);

	return rolename;
}

/*
 *  check_babelfish_droprole_restrictions
 *
 *  Implements following one additional limitation to drop role stmt
 *  block dropping an active babelfish role/user
 */
static void
check_babelfish_droprole_restrictions(char *role)
{
	Oid bbf_role_admin_oid = InvalidOid;

	if (MyProcPort->is_tds_conn && sql_dialect == SQL_DIALECT_TSQL)
		return;

	bbf_role_admin_oid = get_role_oid(BABELFISH_ROLE_ADMIN, false);

	/*
	 * Allow DROP ROLE if current user is bbf_role_admin as we need
	 * to allow remove_babelfish from PG endpoint. It is safe
	 * since only superusers can assume this role.
	 */
	if (bbf_role_admin_oid == GetUserId())
		return;

	if (is_babelfish_role(role))
	{
		pfree(role);			/* avoid mem leak */
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Babelfish-created logins/users/roles cannot be dropped or altered outside of a Babelfish session")));
	}
}

/*
 * is_babelfish_role
 *
 * Helper function to check if a given role is babelfish user or role or login
 *
 * Notes:
 * 	Direct evidence of babelfish membership is stored in babelfish catalog,
 * 	that is only accessible in babelfish_db.
 * 	Since role related DDLs could be executed in any PG databases,
 * 	This function check the underlying assumption on the membership chain instead
 * 	sysadmin <-- dbo* <--- db_owner* <--- users/roles
 *
 * actual dbo and db_owner name varies across different babelfish logical databases
 */
static bool
is_babelfish_role(const char *role)
{
	Oid			sysadmin_oid;
	Oid			role_oid;
	Oid			bbf_master_guest_oid;
	Oid			bbf_tempdb_guest_oid;
	Oid			bbf_msdb_guest_oid;
	Oid			securityadmin_oid;

	sysadmin_oid = get_role_oid(BABELFISH_SYSADMIN, true);	/* missing OK */
	role_oid = get_role_oid(role, true);	/* missing OK */
	securityadmin_oid = get_role_oid(BABELFISH_SECURITYADMIN, true);  /* missing OK */

	if (!OidIsValid(sysadmin_oid) || !OidIsValid(role_oid))
		return false;

	if (is_member_of_role(sysadmin_oid, role_oid) ||
		is_member_of_role(securityadmin_oid, role_oid) ||
		pg_strcasecmp(role, BABELFISH_ROLE_ADMIN) == 0) /* check if it is bbf_role_admin */
		return true;

	bbf_master_guest_oid = get_role_oid("master_guest", true);
	bbf_tempdb_guest_oid = get_role_oid("tempdb_guest", true);
	bbf_msdb_guest_oid = get_role_oid("msdb_guest", true);
	if (OidIsValid(bbf_master_guest_oid)
		&& OidIsValid(bbf_tempdb_guest_oid)
		&& OidIsValid(bbf_msdb_guest_oid)
		&& is_member_of_role(role_oid, bbf_master_guest_oid)
		&& is_member_of_role(role_oid, bbf_tempdb_guest_oid)
		&& is_member_of_role(role_oid, bbf_msdb_guest_oid))
		return true;

	return false;
}

/*
 * handle_rename
 *
 * Description: This function handles all potential rename operations that don't go through
 * 	the event trigger infrastructure.
 *
 * Returns: true - If it passes through all the basic checks.
 */
static bool
handle_rename(RenameStmt *rename_stmt)
{
	Assert(NULL != rename_stmt);

	/*
	 * The majority of potential renames should not be coming through here as
	 * they're handled by the event trigger infrastructure. We will; however,
	 * intercept calls for databases, table spaces, and (obviously) event
	 * triggers, so we need to ignore those.
	 */
	if (OBJECT_ROLE == rename_stmt->renameType)
	{
		if ((!MyProcPort->is_tds_conn || sql_dialect != SQL_DIALECT_TSQL) &&
			 is_babelfish_role(rename_stmt->subname))
		{
			/*
			 * Renaming of an babelfish role/user/login
			 * shouldn't be allowed for an any pg user
			 * other than superuser
			 */
			check_babelfish_alterrole_restictions(false);
		}
	}

	else if (OBJECT_DATABASE == rename_stmt->renameType)
	{
		Oid			target_db_id = InvalidOid;

		/*
		 * Basic checks to avoid non-privileged user to access metadata.
		 * Always let backend to handle error.
		 */
		target_db_id = get_database_oid(rename_stmt->subname, true);
		if (target_db_id == InvalidOid)
			return true;

		/* must be owner */
		if (!object_ownercheck(DatabaseRelationId, target_db_id, GetUserId()))
			return true;

		/* must have createdb rights */
		if (!have_createdb_privilege())
			return true;

		check_babelfish_renamedb_restrictions(target_db_id);
	}
	return true;
}

/*
 * check_babelfish_alterrole_restictions
 *
 * Implements following one additional limitation to alter role stmt
 *
 * Will throw a error when any pg user other than superuser tried to alter an active
 * babelfish role/user/login and which is not an allowed alter role operation
 */
static void
check_babelfish_alterrole_restictions(bool allow_alter_role_operation)
{
	if(!allow_alter_role_operation)
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Babelfish-created logins/users/roles cannot be altered outside of a Babelfish session")));
}

/*
 * handle_alter_role
 *
 * Description: This function handles dealing with ALTER ROLE <role> WITH.
 *
 * Returns: true - We're not attempting to modify something we shouldn't have access to. Normal security checks.
 *          false - We've reported an error and should not continue executing this call.
 */
static bool
handle_alter_role(AlterRoleStmt* alter_role_stmt)
{
    char *name = get_role_name(alter_role_stmt->role);
    const char *babelfish_db_name = NULL;
    bool allow_alter_role_operation;
    bool master_user = false;
    List *options = alter_role_stmt->options;
    ListCell *opt;
    Oid role_oid;
    Oid	babelfish_db_oid;
    HeapTuple tp;
    Form_pg_authid authForm = NULL;

    /* If the role does not exist, just let the normal Postgres checks happen. */
    if (name == NULL)
    {
	    return true;
    }

    if ((!MyProcPort->is_tds_conn || sql_dialect != SQL_DIALECT_TSQL) &&
	     is_babelfish_role(name))
    {
	    /* Quick check, directly disallow alter role for bbf_role_admin */
	    if (pg_strcasecmp(name, BABELFISH_ROLE_ADMIN) == 0)
		    check_babelfish_alterrole_restictions(false);

	    tp = SearchSysCache1(AUTHNAME, CStringGetDatum(name));
	    if (HeapTupleIsValid(tp))
	    {
		    authForm = (Form_pg_authid) GETSTRUCT(tp);
	    }
	    babelfish_db_name = GetConfigOption("babelfishpg_tsql.database_name", true, false);
		if(babelfish_db_name)
		{
			babelfish_db_oid = get_database_oid(babelfish_db_name, true);
			role_oid = get_role_oid(name, true);

			/* Permission checks */
			if (OidIsValid(role_oid) && OidIsValid(babelfish_db_oid) && object_ownercheck(DatabaseRelationId, babelfish_db_oid, role_oid))
				master_user = true;
		}

	    /*
	     * For any pg user, there are only few operations which need to be allowed for
	     * ALTER ROLE <role> WITH. The allowed operations to alter master user is password change
		 * and the allowed operations to alter babelfish created logins/users/roles are
		 * password change, connection limit and valid until.
	     *
	     * If any non-allowed option is given among the options of alter role then disallow the operation.
	     *
	     * In fututre, if need to allow more operations then add those options into the list.
	     */
	    foreach(opt, options)
	    {
		    DefElem *defel = (DefElem *) lfirst(opt);
		    if(master_user)
		    {
			    if (strcmp(defel->defname, "password") == 0)
				    allow_alter_role_operation = true;
			    else
			    {
				    allow_alter_role_operation = false;
				    break;
			    }
		    }
		    else
		    {
			    if ((authForm && authForm->rolcanlogin) && (strcmp(defel->defname, "password") == 0 ||
					    strcmp(defel->defname, "connectionlimit") == 0 ||
					    strcmp(defel->defname, "validUntil") == 0))
				  allow_alter_role_operation = true;
			    else
			    {
				    allow_alter_role_operation = false;
				    break;
			    }
		    }
	    }
	    if (authForm)
		    ReleaseSysCache(tp);
	    check_babelfish_alterrole_restictions(allow_alter_role_operation);
    }
    pfree(name);
    return true;
}

/* handle_alter_role_set
 *
 * Description: This function handles dealing with ALTER ROLE <role> SET.
 *
 * Returns: true - We're not attempting to modify something we shouldn't have access to, continue on.
 *          false - We've reported an error and should not continue executing this call.
 */
static bool
handle_alter_role_set (AlterRoleSetStmt* alter_role_set_stmt)
{
    char *name;

    /*
     * If this is an ALTER ROLE ALL [ IN DATABASE ] SET statement,
     * alter_role_set_stmt->role will be NULL.  While we don't want users
     * altering our "protected" roles, we can pass through here because
     * PostgreSQL already handles those situations correctly.
     *
     * The ALTER ROLE ALL SET variant of this command can only be run by
     * superusers, and the ALTER ROLE ALL IN DATABASE SET variant is the same as
     * ALTER DATABASE SET, which is handled via the regular database ownership
     * checks.  (Customers should not be able to obtain ownership of our
     * "protected" databases thanks to handle_alter_owner().)
     */
    if (alter_role_set_stmt->role == NULL)
    {
	    const char *babelfish_db_name = NULL;
	    babelfish_db_name = GetConfigOption("babelfishpg_tsql.database_name", true, false);
	    if((!MyProcPort->is_tds_conn || sql_dialect != SQL_DIALECT_TSQL) &&
		    babelfish_db_name && alter_role_set_stmt->database &&
		    strcmp(alter_role_set_stmt->database, babelfish_db_name) == 0)
		    check_babelfish_alterrole_restictions(false);
	    return true;
    }

    name = get_role_name(alter_role_set_stmt->role);

    /* If the role does not exist, just let the normal Postgres checks happen.*/
    if (name == NULL)
    {
	    return true;
    }

    if ((!MyProcPort->is_tds_conn || sql_dialect != SQL_DIALECT_TSQL) &&
	     is_babelfish_role(name))
    {
	    check_babelfish_alterrole_restictions(false);
    }

    /*
     * Reaching here does not mean that this user has permission to modify the role.
     * Those permissions checks are done through normal handling.
     */
    pfree(name);
    return true;
}

/*
 * handle_grant_role
 *
 * Handles GRANT/REVOKE ROLE TO/FROM ROLE.
 *
 * Returns: true - We're not attempting to modify something we shouldn't have access to. Normal security checks.
 *          false - We've reported an error and should not continue executing this call.
 */
static bool
handle_grant_role(GrantRoleStmt *grant_stmt)
{
	ListCell *item;
	Oid bbf_role_admin_oid = InvalidOid;
	Oid securityadmin_oid = InvalidOid;

	if (MyProcPort->is_tds_conn && sql_dialect == SQL_DIALECT_TSQL)
		return true;

	bbf_role_admin_oid = get_role_oid(BABELFISH_ROLE_ADMIN, false);
	securityadmin_oid = get_role_oid(BABELFISH_SECURITYADMIN, false);

	/*
	 * Allow GRANT ROLE if current user is bbf_role_admin as we need
	 * to allow initialise_babelfish from PG endpoint. It is safe
	 * since only superusers can assume this role.
	 */
	if (bbf_role_admin_oid == GetUserId())
		return true;

	/* Restrict roles to added as a member of bbf_role_admin/securityadmin */
	foreach(item, grant_stmt->granted_roles)
	{
		AccessPriv *priv = (AccessPriv *) lfirst(item);
		char	   *rolename = priv->priv_name;
		Oid			roleid;

		if (rolename == NULL)
			continue;

		roleid = get_role_oid(rolename, false);
		if (OidIsValid(roleid) && (roleid == bbf_role_admin_oid || roleid == securityadmin_oid))
			check_babelfish_alterrole_restictions(false);
	}

	/* Restrict grant to/from bbf_role_admin/securityadmin role */
	foreach(item, grant_stmt->grantee_roles)
	{
		RoleSpec   *rolespec = lfirst_node(RoleSpec, item);
		Oid			roleid;

		roleid = get_rolespec_oid(rolespec, false);
		if (OidIsValid(roleid) && (roleid == bbf_role_admin_oid || roleid == securityadmin_oid))
			check_babelfish_alterrole_restictions(false);
	}

	return true;
}

/*
 *  check_babelfish_renamedb_restrictions
 *
 *  Implements following one additional limitation to rename database stmt
 *  1. block renaming an active babelfish database (indicated by babelfishpg_tsql.database_name)
 */
static void
check_babelfish_renamedb_restrictions(Oid target_db_id)
{
	const char *babelfish_db_name = NULL;
	Oid			babelfish_db_id = InvalidOid;

	babelfish_db_name = GetConfigOption("babelfishpg_tsql.database_name", true, false);

	if (!babelfish_db_name)		/* not defined */
		return;

	babelfish_db_id = get_database_oid(babelfish_db_name, true);
	if (babelfish_db_id == target_db_id)	/* rename active babelfish
											 * database */
		ereport(ERROR,
				(errcode(ERRCODE_OBJECT_IN_USE),
				 errmsg("cannot rename active babelfish database")));
}

/*
 *  handle_dropdb
 *
 *  Implements following two additional limitation to drop database stmt
 *  1. block dropping an active babelfish database (indicated by babelfishpg_tsql.database_name)
 *  2. block dropping an inactive babelfish database containing babelfish metadata (indicated by babelfishpg_tsql.enable_ownership_structure)
 */
static bool
handle_dropdb(DropdbStmt *dropdb_stmt)
{
	Oid			target_db_id = InvalidOid;

	/*
	 * Basic checkings to avoid non-privileged user to access metadata allways
	 * let backend to handle error
	 */
	target_db_id = get_database_oid(dropdb_stmt->dbname, true);
	if (target_db_id == InvalidOid)
		return true;

	/* Permission checks */
	if (!object_ownercheck(DatabaseRelationId, target_db_id, GetUserId()))
		return true;

	check_babelfish_dropdb_restrictions(target_db_id);
	return true;
}

static void
check_babelfish_dropdb_restrictions(Oid target_db_id)
{
	Relation	relsetting;
	HeapTuple	tuple;
	ScanKeyData scankey[2];
	SysScanDesc scan;
	const char *babelfish_db_name = NULL;
	Oid			babelfish_db_id = InvalidOid;
	bool		has_bbf_md = false;

	babelfish_db_name = GetConfigOption("babelfishpg_tsql.database_name", true, false);
	if (!babelfish_db_name)		/* not define */
		return;
	babelfish_db_id = get_database_oid(babelfish_db_name, true);
	if (babelfish_db_id == target_db_id)	/* drop active babelfish database */
		ereport(ERROR,
				(errcode(ERRCODE_OBJECT_IN_USE),
				 errmsg("cannot drop active babelfish database")));

	/*
	 * check if it's an inactive babelfish database. get db configs
	 */
	relsetting = table_open(DbRoleSettingRelationId, AccessShareLock);
	ScanKeyInit(&scankey[0],
				Anum_pg_db_role_setting_setdatabase,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(target_db_id));
	ScanKeyInit(&scankey[1],
				Anum_pg_db_role_setting_setrole,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(InvalidOid));
	scan = systable_beginscan(relsetting, DbRoleSettingDatidRolidIndexId, true,
							  NULL, 2, scankey);
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		bool		isnull;
		Datum		datum;
		ArrayType  *configs = NULL;

		datum = heap_getattr(tuple, Anum_pg_db_role_setting_setconfig,
							 RelationGetDescr(relsetting), &isnull);
		if (!isnull)
			configs = DatumGetArrayTypeP(datum);

		if (configs && is_babelfish_ownership_enabled(configs))
			has_bbf_md = true;
	}
	systable_endscan(scan);
	table_close(relsetting, AccessShareLock);
	if (has_bbf_md)
		ereport(ERROR,
				(errcode(ERRCODE_OBJECT_IN_USE),
				 errmsg("babelfish metadata not removed, please run remove_babelfish before dropping database")));
}

/*
 *  is_babelfish_ownership_enabled
 *
 *  helper function to test value of babelfishpg_tsql.enable_ownership_structure
 */
static bool
is_babelfish_ownership_enabled(ArrayType *array)
{
	int			i;

	for (i = 1; i <= ARR_DIMS(array)[0]; i++)
	{
		Datum		d;
		bool		isnull;
		char	   *s;
		char	   *name;
		char	   *value;

		d = array_ref(array, 1, &i,
					  -1 /* varlenarray */ ,
					  -1 /* TEXT's typlen */ ,
					  false /* TEXT's typbyval */ ,
					  TYPALIGN_INT /* TEXT's typalign */ ,
					  &isnull);
		if (isnull)
			continue;
		s = TextDatumGetCString(d);
		ParseLongOption(s, &name, &value);
		if ((0 == strncmp(name, "babelfishpg_tsql.enable_ownership_structure", 44))
			&& (0 == strncmp(value, "true", 4)))
			return true;
	}
	return false;
}
