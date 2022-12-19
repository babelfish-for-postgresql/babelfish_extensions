/*
 * String-related functions for T-SQL
 */

#include "postgres.h"

#include "catalog/pg_type.h"
#include "common/cryptohash.h"
#include "common/md5.h"
#include "common/sha2.h"
#include "parser/parse_coerce.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include "utils/lsyscache.h"
#include <openssl/sha.h>
#include "utils/varlena.h"

#include "pltsql.h"
#include "pltsql-2.h"

#define MD5_RESULTLEN  (16)
#define SHA1_RESULTLEN	(20)
#define SHA512_RESULTLEN (64)

PG_FUNCTION_INFO_V1(hashbytes);
PG_FUNCTION_INFO_V1(quotename);
PG_FUNCTION_INFO_V1(string_escape);
PG_FUNCTION_INFO_V1(formatmessage);
PG_FUNCTION_INFO_V1(tsql_varchar_substr);

/*
 * Hashbytes implementation
 *
 * According to some SQL tsql, MD2, MD4, MD5, SHA/SHA1 still
 * work, but should give a deprecation warning.
 *
 * OpenSSL no longer supports MD2 or MD4, so it would likely have to be
 * reimplemented from scratch if it is needed. For now,
 * treat MD2 and MD4 as unsupported.
 *
 * We use the Postgres implementations where available (for sha256 and md5),
 * and OpenSSL for the rest.
 */
Datum
hashbytes(PG_FUNCTION_ARGS)
{
	const char 	*algorithm	= text_to_cstring(PG_GETARG_TEXT_P(0));
	bytea		*in			= PG_GETARG_BYTEA_PP(1);
	size_t		len			= VARSIZE_ANY_EXHDR(in);
	const uint8 *data		= (unsigned char*) VARDATA_ANY(in);
	bytea 		*result;

	if (strcasecmp(algorithm, "MD2") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(algorithm, "MD4") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(algorithm, "MD5") == 0)
	{
		unsigned char 	buf[MD5_RESULTLEN];
		const char		*errstr = NULL;
		bool			success;

		success = pg_md5_binary(data, len, buf, &errstr);

		if (unlikely(!success)) /* OOM */
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("could not compute MD5 encryption: %s", errstr)));

		result = palloc(sizeof(buf) + VARHDRSZ);
		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else if (strcasecmp(algorithm, "SHA") == 0 ||
				strcasecmp(algorithm, "SHA1") == 0)
	{
		unsigned char buf[SHA1_RESULTLEN];

		SHA1(data, len, buf);

		result = palloc(sizeof(buf) + VARHDRSZ);
		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else if (strcasecmp(algorithm, "SHA2_256") == 0)
	{
		pg_cryptohash_ctx *ctx = pg_cryptohash_create(PG_SHA256);
		unsigned char buf[PG_SHA256_DIGEST_LENGTH];

		if (pg_cryptohash_init(ctx) < 0)
			elog(ERROR, "could not initialize %s context", "SHA256");
		if (pg_cryptohash_update(ctx, data, len) < 0)
			elog(ERROR, "could not update %s context", "SHA256");
		if (pg_cryptohash_final(ctx, buf, PG_SHA256_DIGEST_LENGTH) < 0)
			elog(ERROR, "could not finalize %s context", "SHA256");
		pg_cryptohash_free(ctx);

		result = palloc(sizeof(buf) + VARHDRSZ);
		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else if (strcasecmp(algorithm, "SHA2_512") == 0)
	{
		unsigned char buf[SHA512_RESULTLEN];

		SHA512(data, len, buf);

		result = palloc(sizeof(buf) + VARHDRSZ);
		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else
	{
		PG_RETURN_NULL();
	}
}

/*
 * Takes in a sysname (nvarchar(128) NOT NULL) 
 *
 * Returns nvarchar
 *
 * Adds brackets around string to create a valid delimited identifier.
 */
Datum
quotename(PG_FUNCTION_ARGS)
{
	const char *input_string = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *delimiter = text_to_cstring(PG_GETARG_TEXT_P(1));

	char left_delim;
	char right_delim;
	char *buf;
	int buf_i = 0;

	VarChar *result;

	/* Validate input len */
	if (strlen(input_string) > 128) {
		PG_RETURN_NULL();
	}
	if (strlen(delimiter) != 1) {
		PG_RETURN_NULL();
	}

	switch (*delimiter) {
		case ']':
		case '[':
			left_delim = '[';
			right_delim = ']';
			break;
		case '`':
		case '\'':
		case '"':
			left_delim = *delimiter;
			right_delim = *delimiter;
			break;
		case '(':
		case ')':
			left_delim = '(';
			right_delim = ')';
			break;
		case '<':
		case '>':
			left_delim = '>';
			right_delim = '<';
			break;
		case '{':
		case '}':
			left_delim = '{';
			right_delim = '}';
			break;
		default:
			PG_RETURN_NULL();
	}

	/* Input size is max 128, so output max is 128 * 2 + 2 (for delimiters) */
	buf = palloc(258 * sizeof(char));
	memset(buf, 0, 258 * sizeof (char));

	
	/* Process input string to include escape characters */
	buf[buf_i++] = left_delim;
	for (int i = 0; i < strlen(input_string); i++) {
		switch (input_string[i]) {
			/* Escape chars */
			case '\'':
			case ']':
			case '"':
				buf[buf_i++] = input_string[i];
				buf[buf_i++] = input_string[i];
				break;
			default:
				buf[buf_i++] = input_string[i];
		}
	}
	buf[buf_i++] = right_delim;

	result = (*common_utility_plugin_ptr->tsql_varchar_input)(buf, buf_i, -1);
	pfree(buf);

	PG_RETURN_VARCHAR_P(result);	
}

Datum
string_escape(PG_FUNCTION_ARGS)
{
	const char *str = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *type = text_to_cstring(PG_GETARG_TEXT_P(1));
	
	StringInfoData buf;
	int text_len = strlen(str);

	VarChar *result;

	if (strcmp(type, "json")) 
	{
		PG_RETURN_NULL();
	}

	if (text_len == 0)
	{
		PG_RETURN_NULL();
	}

	initStringInfo(&buf);

	for (int i = 0; i < text_len; i++)
	{
		switch(str[i])
		{
			case 8: /* Backspace */
				appendStringInfoString(&buf, "\\b");
				break;
			case 9: /* Horizontal tab */
				appendStringInfoString(&buf, "\\t");
				break;
			case 10: /* New line */
				appendStringInfoString(&buf, "\\n");
				break;
			case 12: /* Form feed */
				appendStringInfoString(&buf, "\\f");
				break;
			case 13: /* Carriage return */
				appendStringInfoString(&buf, "\\r");
				break;
			case '\"':
				appendStringInfoString(&buf, "\\\"");
				break;
			case '/': 
				appendStringInfoString(&buf, "\\/");
				break;
			case '\\': 
				appendStringInfoString(&buf, "\\\\");
				break;
			default:
				if (str[i] < 32)
				{
					appendStringInfo(&buf, "\\u00%02x", (unsigned char)(str[i]));
				}
				else
				{
					appendStringInfoChar(&buf, str[i]);
				}
		}
	}
	
	result = (*common_utility_plugin_ptr->tsql_varchar_input)(buf.data, buf.len, -1);
	pfree(buf.data);

	PG_RETURN_VARCHAR_P(result);
}

/*
 * The default format() function implemented in Postgres doesn't cover some
 * of the more exotic number formats, such as %i, %o, %u, and %x. There are 
 * also TSQL specific implementation details for FORMATMESSAGE, such as NULL
 * handling and escape sequences that differ from the default as well..
 * 
 */
Datum
formatmessage(PG_FUNCTION_ARGS)
{
	char			*msg_string;
	int				nargs = PG_NARGS() - 1;
	Datum			*args;
	Oid				*argtypes;
	bool			*argisnull;
	StringInfoData	buf;
	VarChar			*result;

	if (nargs > 20)
	{
		/* Need to issue warning? */
		nargs = 20;
	}

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	msg_string = text_to_cstring(PG_GETARG_TEXT_P(0));

	args = (Datum *) palloc(sizeof(Datum) * nargs);
	argtypes = (Oid *) palloc(sizeof(Oid) * nargs);
	argisnull = (bool *) palloc(sizeof(bool) * nargs);

	for (int i = 0; i < nargs; i++)
	{
		args[i] = PG_GETARG_DATUM(i + 1);
		argtypes[i] = get_fn_expr_argtype(fcinfo->flinfo, i + 1);
		argisnull[i] = PG_ARGISNULL(i + 1);
	}

	initStringInfo(&buf);
	prepare_format_string(&buf, msg_string, nargs, args, argtypes, argisnull);
	result = (*common_utility_plugin_ptr->tsql_varchar_input)(buf.data, buf.len, -1);
	pfree(buf.data);

	PG_RETURN_VARCHAR_P(result);
}

/*
 * Constructs a formatted string with provided format and arguments.
 */
void
prepare_format_string(StringInfo buf, char *msg_string, int nargs, 
					  Datum *args, Oid *argtypes, bool *argisnull)
{
	int				i = 0;

	size_t			prev_fmt_seg_sz = TSQL_MAX_MESSAGE_LEN + 1;
	size_t			seg_len = 0;

	char			*seg_start, *seg_end, *arg_str, *fmt_seg;
	char			placeholder;

	Oid				prev_type = 0;
	Oid				typid;
	TYPCATEGORY		type;
	Datum			arg;

	FmgrInfo		typoutputfinfo;

	fmt_seg = palloc((TSQL_MAX_MESSAGE_LEN + 1) * sizeof(char));
	memset(fmt_seg, 0, (TSQL_MAX_MESSAGE_LEN + 1) * sizeof(char));

	seg_start = msg_string;
	seg_end = strchr(seg_start, '%');

	/* Missing format char */
	if (seg_end == NULL)
	{
		seg_len = strlen(seg_start);
	}
	else
	{
		seg_len = seg_end - seg_start;
	}

	/* Copy over beginning of message, before first % character */
	appendBinaryStringInfoNT(buf, seg_start, seg_len);

	while (seg_end != NULL && buf->len <= TSQL_MAX_MESSAGE_LEN)
	{	
		seg_start = seg_end;
		seg_end = strchr(seg_start + 1, '%');

		if (seg_end != NULL)
		{
			seg_len = seg_end - seg_start;
		}
		else
		{
			seg_len = strlen(seg_start);
		}
		if (seg_len > TSQL_MAX_MESSAGE_LEN + 1)
		{
			seg_len = TSQL_MAX_MESSAGE_LEN + 1;
		}
		placeholder = seg_start[1];
		
		if (strchr("diouxXs", placeholder) != NULL)
		{
			/* Valid placeholder */
			
			memset(fmt_seg, 0, prev_fmt_seg_sz);
			strncpy(fmt_seg, seg_start, seg_len);
			prev_fmt_seg_sz = seg_len;
			
			arg = args[i];

			if (i >= nargs || argisnull[i])
			{
				appendStringInfo(buf, "(null)");
				appendStringInfoString(buf, fmt_seg + 2);
				continue;
			}

			typid = argtypes[i];
			type = TypeCategory(typid);

			if (typid != prev_type)
			{
				Oid			typoutputfunc;
				bool		typIsVarlena;
				getTypeOutputInfo(typid, &typoutputfunc, &typIsVarlena);
				fmgr_info(typoutputfunc, &typoutputfinfo);
				prev_type = typid;
			}

			switch(type)
			{
				case TYPCATEGORY_STRING:
				case TYPCATEGORY_UNKNOWN:
					if (placeholder != 's')
						ereport(ERROR, 
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Param %d expected format type %s but received type %s",
										i + 1, fmt_seg, format_type_be(typid))));
					arg_str = OutputFunctionCall(&typoutputfinfo, arg);
					appendStringInfo(buf, fmt_seg, arg_str);
					break;
				case TYPCATEGORY_USER:
					arg_str = OutputFunctionCall(&typoutputfinfo, arg);
					appendStringInfo(buf, fmt_seg, arg_str);
					break;
				case TYPCATEGORY_NUMERIC:
					if (placeholder == 's')
						ereport(ERROR, 
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Param %d expected format type %s but received type %s",
										i + 1, fmt_seg, format_type_be(typid))));
					appendStringInfo(buf, fmt_seg, DatumGetInt32(arg));
					break;
				default:
					ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						errmsg("Unsupported type with type %s", format_type_be(typid))));
			}

			i++;
		}
		else
		{
			/* Invalid placeholder, throw an error */
			ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                         errmsg("Invalid format specification: %s", seg_start)));
		}
	}
	if (seg_end != NULL)
	{
		seg_len = strlen(seg_end);
		appendBinaryStringInfoNT(buf, seg_end, seg_len);
	}

	if (buf->len > TSQL_MAX_MESSAGE_LEN)
	{
		// Trim buf to be 2044, truncate with ...
		for (int i = TSQL_MAX_MESSAGE_LEN - 3; i < TSQL_MAX_MESSAGE_LEN; i++)
		{
			buf->data[i] = '.';
		}
		buf->len = TSQL_MAX_MESSAGE_LEN;
	}
	
	buf->data[buf->len] = '\0';

	pfree(fmt_seg);
}

/*
 * tsql_varchar_substr()
 * Return a substring starting at the specified position.
 */
Datum
tsql_varchar_substr(PG_FUNCTION_ARGS)
{
	if (PG_ARGISNULL(0) || PG_ARGISNULL(1) || PG_ARGISNULL(2))
		PG_RETURN_NULL();
	
	PG_RETURN_VARCHAR_P(DirectFunctionCall3(text_substr,PG_GETARG_DATUM(0),
									PG_GETARG_INT32(1),
									PG_GETARG_INT32(2)));
}
