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

#include "src/include/tds_int.h"
#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "parser/parser.h"
#include "parser/parse_node.h"
#include "utils/elog.h"

static int FindMatchingParam(List *params, const char *name);
static Node * TransformParamRef(ParseState *pstate, ParamRef *pref);
Node * TdsFindParam(ParseState *pstate, ColumnRef *cref);
void TdsErrorContextCallback(void *arg);

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
		 * PostgreSQL does not support NUL bytes in character data as
		 * it internally needs the ability to convert any datum to a
		 * NUL terminated C-string without explicit length information.
		 */
		if (code1 == 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("invalid UTF16 byte sequence - "
							"code point 0 not supported")));
		if (consumed)
			*consumed = 2;
		return (int32_t)code1;
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

	/* Range U+0000 .. U+007F (7 bit)*/
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
	union {
		uint16_t	value;
		uint8_t		half[2];
	} temp16;

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
	unsigned char  *in = vin;
	int				i;
	int				consumed;
	int32_t			code;

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
	const unsigned char  *in = vin;
	size_t				i;
	int				consumed;
	int32_t			code;

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
	const unsigned char  *in = vin;
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
	int32_t	header_len;
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
		TdsParamName	item = lfirst(cell);

		if (pg_strcasecmp(name,	item->name) == 0)
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
	extern int sql_dialect;
	List *params = NULL;

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
		char *colname = strVal(linitial(cref->fields));
		int paramNo = 0;
		ParamRef *pref;

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

		pref->number   = paramNo;
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
	 * err_text should not be NULL. Initialise to Empty String
	 * if it need's to be ignored.
	 */
	Assert(tdsErrorContext != NULL && tdsErrorContext->err_text != NULL);

	switch (tdsErrorContext->reqType)
	{
		case TDS_LOGIN7: 	/* Login7 request */
			{
				errcontext("TDS Protocol: Message Type: TDS Login7, Phase: Login. %s",
					tdsErrorContext->err_text);
			}
			break;
		case TDS_PRELOGIN: /* Pre-login Request*/
			{
				errcontext("TDS Protocol: Message Type: TDS Pre-Login, Phase: Login. %s",
					tdsErrorContext->err_text);
			}
			break;
		case TDS_QUERY:		/* Simple SQL BATCH */
			{
				errcontext("TDS Protocol: Message Type: SQL BATCH, Phase: %s. %s",
					tdsErrorContext->phase,
					tdsErrorContext->err_text);
			}
			break;
		case TDS_RPC:		/* Remote procedure call */
			{
				errcontext("TDS Protocol: Message Type: RPC, SP Type: %s, Phase: %s. %s",
					tdsErrorContext->spType,
					tdsErrorContext->phase,
					tdsErrorContext->err_text);
			}
			break;
		case TDS_TXN:	/* Transaction management request */
			{
					errcontext("TDS Protocol: Message Type: Txn Manager, Txn Type: %s, Phase: %s. %s",
					tdsErrorContext->txnType,
					tdsErrorContext->phase,
					tdsErrorContext->err_text);
			}
			break;
		case TDS_ATTENTION: 	/* Attention request */
			{
				errcontext("TDS Protocol: Message Type: Attention, Phase: %s. %s",
					tdsErrorContext->phase,
					tdsErrorContext->err_text);
			}
			break;
		default:
			errcontext("TDS Protocol: %s",
					tdsErrorContext->err_text);
	}
}
