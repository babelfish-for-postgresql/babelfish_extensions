/*-------------------------------------------------------------------------
 *
 * varchar.c
 *	  Functions for the built-in types char(n) and varchar(n).
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/backend/utils/adt/varchar.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"


#include "access/hash.h"
#include "collation.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_type.h"
#include "encoding/encoding.h"
#include "fmgr.h"
#include "libpq/pqformat.h"
#include "nodes/nodeFuncs.h"
#include "parser/parser.h"		/* only needed for GUC variables */
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/float.h"
#include "utils/pg_locale.h"
#include "utils/varlena.h"
#include "mb/pg_wchar.h"
#include "utils/xml.h"
#include "utils/bytea.h"
#include "utils/cash.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/syscache.h"
#include "utils/uuid.h"
#include "utils/timestamp.h"
#include "utils/numeric.h"
#include "typecode.h"
#include "varchar.h"

int			TsqlUTF8LengthInUTF16(const void *vin, int len);
void		TsqlCheckUTF16Length_varchar(const char *s_data, int32 len, int32 maxlen, bool isExplicit);
void		TsqlCheckUTF16Length_bpchar(const char *s, int32 len, int32 maxlen, int charlen, bool isExplicit);
void		TsqlCheckUTF16Length_bpchar_input(const char *s, int32 len, int32 maxlen, int charlen);
void		TsqlCheckUTF16Length_varchar_input(const char *s, int32 len, int32 maxlen);
static inline int varcharTruelen(VarChar *arg);

#define DEFAULT_LCID 1033

/*
 * is_basetype_nchar_nvarchar - given datatype is nvarchar or nchar
 *     or created over nvarchar or nchar.
 */
static bool
is_basetype_nchar_nvarchar(Oid typid)
{
	if (tsql_nvarchar_oid == InvalidOid)
		tsql_nvarchar_oid = lookup_tsql_datatype_oid("nvarchar");
	if (tsql_nchar_oid == InvalidOid)
		tsql_nchar_oid = lookup_tsql_datatype_oid("nchar");

	for (;;)
	{
		HeapTuple	tup;
		Form_pg_type typTup;

		if (typid == tsql_nvarchar_oid || typid == tsql_nchar_oid)
			return true;

		tup = SearchSysCache1(TYPEOID, ObjectIdGetDatum(typid));
		if (!HeapTupleIsValid(tup))
			elog(ERROR, "cache lookup failed for type %u", typid);
		typTup = (Form_pg_type) GETSTRUCT(tup);
		if (typTup->typtype != TYPTYPE_DOMAIN)
		{
			/* Not a domain, so done */
			ReleaseSysCache(tup);
			break;
		}
		typid = typTup->typbasetype;
		ReleaseSysCache(tup);
	}
	return false;
}


/*
 * GetUTF8CodePoint - extract the next Unicode code point from 1..4
 *					  bytes at 'in' in UTF-8 encoding.
 */
int32_t
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

/*
 * TsqlUTF8LengthInUTF16 - compute the length of a UTF8 string in number of
 * 							 16-bit units if we were to convert it into
 * 							 UTF16 with TdsUTF8toUTF16StringInfo()
 */
int
TsqlUTF8LengthInUTF16(const void *vin, int len)
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

static inline void
TsqlCheckUTF16Length(const char *utf8_str, size_t len, size_t maxlen,
					 char *varstr)
{
	int			i;

	for (i = len; i > 0; i--)
		if (utf8_str[i - 1] != ' ')
			break;
	if (TsqlUTF8LengthInUTF16(utf8_str, i) > maxlen)
		ereport(ERROR,
				(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
				 errmsg("value too long for type character%s(%d) "
						"as UTF16 output",
						varstr, (int) maxlen)));
}

/*
 * Check for T-SQL varchar function
 */
void
TsqlCheckUTF16Length_varchar(const char *s_data, int32 len, int32 maxlen, bool isExplicit)
{
	int			i;
	size_t		maxmblen;

	if (maxlen < 0)
		return;

	if (len <= maxlen)
	{
		TsqlCheckUTF16Length(s_data, len, maxlen, " varying");
		return;
	}

	/* truncate multibyte string preserving multibyte boundary */
	maxmblen = pg_mbcharcliplen(s_data, len, maxlen);

	if (!isExplicit &&
		!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
	{
		for (i = maxmblen; i < len; i++)
			if (s_data[i] != ' ')
				ereport(ERROR,
						(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
						 errmsg("value too long for type character varying(%d)",
								maxlen)));
		TsqlCheckUTF16Length(s_data, len, maxlen, " varying");
	}
	else
		TsqlCheckUTF16Length(s_data, maxmblen, maxlen, " varying");
}

/*
 * Check for T-SQL bpchar function
 */
void
TsqlCheckUTF16Length_bpchar(const char *s, int32 len, int32 maxlen, int charlen, bool isExplicit)
{
	int			i;

	if (charlen == maxlen)
	{
		TsqlCheckUTF16Length(s, len, maxlen, "");
	}
	else if (charlen > maxlen)
	{
		/* Verify that extra characters are spaces, and clip them off */
		size_t		maxmblen;

		maxmblen = pg_mbcharcliplen(s, len, maxlen);

		if (!isExplicit &&
			!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
		{
			for (i = maxmblen; i < len; i++)
				if (s[i] != ' ')
					ereport(ERROR,
							(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
							 errmsg("value too long for type character(%d)",
									maxlen)));
		}

		len = maxmblen;
		TsqlCheckUTF16Length(s, len, maxlen, "");
	}
	else
	{
		TsqlCheckUTF16Length(s, len, maxlen, "");
	}
}

/*
 * Check for T-SQL varchar common input function, varchar_input()
 */
void
TsqlCheckUTF16Length_varchar_input(const char *s, int32 len, int32 maxlen)
{
	TsqlCheckUTF16Length(s, len, maxlen, " varying");
}

/*
 * Check for T-SQL bpchar function
 */
void
TsqlCheckUTF16Length_bpchar_input(const char *s, int32 len, int32 maxlen, int charlen)
{
	if (charlen > maxlen)
	{
		/* Verify that extra characters are spaces, and clip them off */
		size_t		mbmaxlen = pg_mbcharcliplen(s, len, maxlen);
		size_t		j;

		/*
		 * at this point, len is the actual BYTE length of the input string,
		 * maxlen is the max number of CHARACTERS allowed for this bpchar
		 * type, mbmaxlen is the length in BYTES of those chars.
		 */
		for (j = mbmaxlen; j < len; j++)
		{
			if (s[j] != ' ')
				ereport(ERROR,
						(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
						 errmsg("value too long for type character(%d)",
								(int) maxlen)));
		}

		TsqlCheckUTF16Length(s, len, maxlen, "");
	}
	else
	{
		TsqlCheckUTF16Length(s, len, maxlen, "");
	}
}

/*  Function Registeration  */
PG_FUNCTION_INFO_V1(bpcharin);
PG_FUNCTION_INFO_V1(bpchar);
PG_FUNCTION_INFO_V1(nchar);
PG_FUNCTION_INFO_V1(bpcharrecv);

PG_FUNCTION_INFO_V1(bpchar2int2);
PG_FUNCTION_INFO_V1(bpchar2int4);
PG_FUNCTION_INFO_V1(bpchar2int8);
PG_FUNCTION_INFO_V1(bpchar2float4);
PG_FUNCTION_INFO_V1(bpchar2float8);

PG_FUNCTION_INFO_V1(varcharin);
PG_FUNCTION_INFO_V1(varchar);
PG_FUNCTION_INFO_V1(nvarchar);
PG_FUNCTION_INFO_V1(varcharrecv);
PG_FUNCTION_INFO_V1(varchareq);
PG_FUNCTION_INFO_V1(varcharne);
PG_FUNCTION_INFO_V1(varcharlt);
PG_FUNCTION_INFO_V1(varcharle);
PG_FUNCTION_INFO_V1(varchargt);
PG_FUNCTION_INFO_V1(varcharge);
PG_FUNCTION_INFO_V1(varcharcmp);
PG_FUNCTION_INFO_V1(hashvarchar);

PG_FUNCTION_INFO_V1(varchar2int2);
PG_FUNCTION_INFO_V1(varchar2int4);
PG_FUNCTION_INFO_V1(varchar2int8);
PG_FUNCTION_INFO_V1(varchar2float4);
PG_FUNCTION_INFO_V1(varchar2float8);
PG_FUNCTION_INFO_V1(varchar2date);
PG_FUNCTION_INFO_V1(varchar2time);
PG_FUNCTION_INFO_V1(varchar2money);
PG_FUNCTION_INFO_V1(varchar2numeric);

/*****************************************************************************
 *	 varchar - varchar(n)
 *
 * Note: varchar piggybacks on type text for most operations, and so has no
 * C-coded functions except for I/O and typmod checking.
 *****************************************************************************/

/*
 * varchar_input -- common guts of varcharin and varcharrecv
 *
 * s is the input text of length len (may not be null-terminated)
 * atttypmod is the typmod value to apply
 *
 * Note that atttypmod is measured in characters, which
 * is not necessarily the same as the number of bytes.
 *
 * If the input string is too long, raise an error, unless the extra
 * characters are spaces, in which case they're truncated.  (per SQL)
 *
 * Uses the C string to text conversion function, which is only appropriate
 * if VarChar and text are equivalent types.
 */
static VarChar *
varchar_input(const char *s, size_t len, int32 atttypmod)
{
	VarChar    *result;
	size_t		maxlen;

	maxlen = atttypmod - VARHDRSZ;

	if (atttypmod >= (int32) VARHDRSZ && len > maxlen)
	{
		/* Verify that extra characters are spaces, and clip them off */
		size_t		mbmaxlen = pg_mbcharcliplen(s, len, maxlen);
		size_t		j;

		for (j = mbmaxlen; j < len; j++)
		{
			if (s[j] != ' ')
				ereport(ERROR,
						(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
						 errmsg("value too long for type character varying(%d)",
								(int) maxlen)));
		}

		len = mbmaxlen;
	}

	if (atttypmod >= (int32) VARHDRSZ)
		TsqlCheckUTF16Length_varchar_input(s, len, maxlen);

	result = (VarChar *) cstring_to_text_with_len(s, len);
	return result;
}

void *
tsql_varchar_input(const char *s, size_t len, int32 atttypmod)
{
	return varchar_input(s, len, atttypmod);
}

/*
 * Convert a C string to VARCHAR internal representation.  atttypmod
 * is the declared length of the type plus VARHDRSZ.
 */
Datum
varcharin(PG_FUNCTION_ARGS)
{
	char	   *s = PG_GETARG_CSTRING(0);

#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	int32		atttypmod = PG_GETARG_INT32(2);
	VarChar    *result;

	result = varchar_input(s, strlen(s), atttypmod);
	PG_RETURN_VARCHAR_P(result);
}

/*
 *		varcharrecv			- converts external binary format to varchar
 */
Datum
varcharrecv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);

#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	int32		atttypmod = PG_GETARG_INT32(2);
	VarChar    *result;
	char	   *str;
	int			nbytes;

	str = pq_getmsgtext(buf, buf->len - buf->cursor, &nbytes);
	result = varchar_input(str, nbytes, atttypmod);
	pfree(str);
	PG_RETURN_VARCHAR_P(result);
}

/*
 * Converts a VARCHAR type to the specified size.
 *
 * maxlen is the typmod, ie, declared length plus VARHDRSZ bytes.
 * isExplicit is true if this is for an explicit cast to varchar(N).
 *
 * Truncation rules: for an explicit cast, silently truncate to the given
 * length; for an implicit cast, raise error unless extra characters are
 * all spaces.  (This is sort-of per SQL: the spec would actually have us
 * raise a "completion condition" for the explicit cast case, but Postgres
 * hasn't got such a concept.)
 */
Datum
varchar(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);	/* source string is in
													 * UTF8 */
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		byteLen;
	int32		maxByteLen;
	size_t		maxmblen;
	int			i;
	char	   *s_data;
	coll_info	collInfo;
	int			charLength;
	char	   *tmp = NULL;		/* To hold the string encoded in target
								 * column's collation. */
	char	   *resStr = NULL;	/* To hold the final string in UTF8 encoding. */
	int			encodedByteLen;

	/* If type of target is NVARCHAR then handle it differently. */
	if (fcinfo->flinfo->fn_expr && is_basetype_nchar_nvarchar(((FuncExpr *) fcinfo->flinfo->fn_expr)->funcresulttype))
		return nvarchar(fcinfo);

	byteLen = VARSIZE_ANY_EXHDR(source);
	s_data = VARDATA_ANY(source);
	maxByteLen = typmod - VARHDRSZ;

	/* No work if typmod is invalid or supplied data fits it already */
	if (maxByteLen < 0)
		PG_RETURN_VARCHAR_P(source);

	/*
	 * Try to find the lcid corresponding to the collation of the target
	 * column.
	 */
	if (fcinfo->flinfo->fn_expr)
	{
		collInfo = lookup_collation_table(((FuncExpr *) fcinfo->flinfo->fn_expr)->funccollid);
	}
	else
	{
		/*
		 * Special handling required for OUTPUT params because this input
		 * function, varchar would be called from TDS to send the OUTPUT
		 * params of stored proc.
		 */
		collInfo = lookup_collation_table(get_server_collation_oid_internal(false));
	}

	/* count the number of chars present in input string. */
	charLength = pg_mbstrlen_with_len(s_data, byteLen);

	/*
	 * Optimisation: Check if we can accommodate charLength number of chars
	 * considering every char requires max number of bytes for given encoding.
	 */
	if (charLength * pg_encoding_max_length(collInfo.enc) <= maxByteLen)
		PG_RETURN_VARCHAR_P(source);

	/*
	 * And encode the input string (usually in UTF8 encoding) in desired
	 * encoding.
	 */
	tmp = encoding_conv_util(s_data, byteLen, PG_UTF8, collInfo.enc, &encodedByteLen);
	byteLen = encodedByteLen;

	/*
	 * We used byteLen here because we are interested in byte length of input
	 * string encoded using the code page of the target column's collation.
	 */
	if (tmp && byteLen <= maxByteLen)
	{
		if (tmp != s_data)
			pfree(tmp);
		PG_RETURN_VARCHAR_P(source);
	}

	/* only reach here if string is too long... */

	/*
	 * Truncate multibyte string (already encoded to the collation of target
	 * column) preserving multibyte boundary.
	 */
	maxmblen = pg_encoding_mbcliplen(collInfo.enc, tmp, byteLen, maxByteLen);

	if (!isExplicit &&
		!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
	{
		for (i = maxmblen; i < byteLen; i++)
			if (tmp[i] != ' ')
				ereport(ERROR,
						(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
						 errmsg("value too long for type character varying(%d)",
								maxByteLen)));
	}

	/* Encode the input string encoding to UTF8(server) encoding */
	resStr = encoding_conv_util(tmp, maxmblen, collInfo.enc, PG_UTF8, &encodedByteLen);

	if (tmp && s_data != tmp && tmp != resStr)
		pfree(tmp);

	/*
	 * Output of encoding_conv_util() would always be NULL terminated So we
	 * can use cstring_to_text directly.
	 */
	PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text_with_len(resStr, encodedByteLen));
}

/*
 * Converts a NVARCHAR type to the specified size.
 *
 * maxlen is the typmod, ie, declared length plus VARHDRSZ bytes.
 * isExplicit is true if this is for an explicit cast to nvarchar(N).
 *
 * Truncation rules: for an explicit cast, silently truncate to the given
 * length; for an implicit cast, raise error unless extra characters are
 * all spaces.  (This is sort-of per SQL: the spec would actually have us
 * raise a "completion condition" for the explicit cast case, but Postgres
 * hasn't got such a concept.)
 */
Datum
nvarchar(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		len,
				maxlen;
	size_t		maxmblen;
	int			i;
	char	   *s_data;

	len = VARSIZE_ANY_EXHDR(source);
	s_data = VARDATA_ANY(source);
	maxlen = typmod - VARHDRSZ;

	TsqlCheckUTF16Length_varchar(s_data, len, maxlen, isExplicit);

	/* No work if typmod is invalid or supplied data fits it already */
	if (maxlen < 0 || len <= maxlen)
		PG_RETURN_VARCHAR_P(source);

	/* only reach here if string is too long... */

	/* truncate multibyte string preserving multibyte boundary */
	maxmblen = pg_mbcharcliplen(s_data, len, maxlen);

	if (!isExplicit &&
		!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
	{
		for (i = maxmblen; i < len; i++)
			if (s_data[i] != ' ')
				ereport(ERROR,
						(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
						 errmsg("value too long for type character varying(%d)",
								maxlen)));
	}

	PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text_with_len(s_data,
															 maxmblen));
}

static char *
varchar2cstring(const VarChar *source)
{
	const char *s_data = VARDATA_ANY(source);
	int			len = VARSIZE_ANY_EXHDR(source);

	char	   *result = (char *) palloc(len + 1);

	memcpy(result, s_data, len);
	result[len] = '\0';

	return result;
}

Datum
varchar2int2(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);

	if (varcharTruelen(source) == 0)
		PG_RETURN_INT16(0);

	PG_RETURN_INT16(pg_strtoint16(varchar2cstring(source)));
}

Datum
varchar2int4(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);

	if (varcharTruelen(source) == 0)
		PG_RETURN_INT32(0);

	PG_RETURN_INT32(pg_strtoint32(varchar2cstring(source)));
}

Datum
varchar2int8(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);

	if (varcharTruelen(source) == 0)
		PG_RETURN_INT64(0);

	PG_RETURN_INT64(pg_strtoint64(varchar2cstring(source)));
}

static Datum
cstring2float4(char *num)
{
	/* This came from float4in() in backend/utils/adt/float.c */
	char	   *orig_num;
	float		val;
	char	   *endptr;

	/*
	 * endptr points to the first character _after_ the sequence we recognized
	 * as a valid floating point number. orig_num points to the original input
	 * string.
	 */
	orig_num = num;

	/* skip leading whitespace */
	while (*num != '\0' && isspace((unsigned char) *num))
		num++;

	/*
	 * Check for an empty-string input to begin with, to avoid the vagaries of
	 * strtod() on different platforms.
	 */
	if (*num == '\0')
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
				 errmsg("invalid input syntax for type %s: \"%s\"",
						"real", orig_num)));

	errno = 0;
	val = strtof(num, &endptr);

	/* did we not see anything that looks like a double? */
	if (endptr == num || errno != 0)
	{
		int			save_errno = errno;

		/*
		 * C99 requires that strtof() accept NaN, [+-]Infinity, and [+-]Inf,
		 * but not all platforms support all of these (and some accept them
		 * but set ERANGE anyway...)  Therefore, we check for these inputs
		 * ourselves if strtof() fails.
		 *
		 * Note: C99 also requires hexadecimal input as well as some extended
		 * forms of NaN, but we consider these forms unportable and don't try
		 * to support them.  You can use 'em if your strtof() takes 'em.
		 */
		if (pg_strncasecmp(num, "NaN", 3) == 0)
		{
			val = get_float4_nan();
			endptr = num + 3;
		}
		else if (pg_strncasecmp(num, "Infinity", 8) == 0)
		{
			val = get_float4_infinity();
			endptr = num + 8;
		}
		else if (pg_strncasecmp(num, "+Infinity", 9) == 0)
		{
			val = get_float4_infinity();
			endptr = num + 9;
		}
		else if (pg_strncasecmp(num, "-Infinity", 9) == 0)
		{
			val = -get_float4_infinity();
			endptr = num + 9;
		}
		else if (pg_strncasecmp(num, "inf", 3) == 0)
		{
			val = get_float4_infinity();
			endptr = num + 3;
		}
		else if (pg_strncasecmp(num, "+inf", 4) == 0)
		{
			val = get_float4_infinity();
			endptr = num + 4;
		}
		else if (pg_strncasecmp(num, "-inf", 4) == 0)
		{
			val = -get_float4_infinity();
			endptr = num + 4;
		}
		else if (save_errno == ERANGE)
		{
			/*
			 * Some platforms return ERANGE for denormalized numbers (those
			 * that are not zero, but are too close to zero to have full
			 * precision).  We'd prefer not to throw error for that, so try to
			 * detect whether it's a "real" out-of-range condition by checking
			 * to see if the result is zero or huge.
			 *
			 * Use isinf() rather than HUGE_VALF on VS2013 because it
			 * generates a spurious overflow warning for -HUGE_VALF.  Also use
			 * isinf() if HUGE_VALF is missing.
			 */
			if (val == 0.0 ||
#if !defined(HUGE_VALF) || (defined(_MSC_VER) && (_MSC_VER < 1900))
				isinf(val)
#else
				(val >= HUGE_VALF || val <= -HUGE_VALF)
#endif
				)
				ereport(ERROR,
						(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
						 errmsg("\"%s\" is out of range for type real",
								orig_num)));
		}
		else
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
					 errmsg("invalid input syntax for type %s: \"%s\"",
							"real", orig_num)));
	}
#ifdef HAVE_BUGGY_SOLARIS_STRTOD
	else
	{
		/*
		 * Many versions of Solaris have a bug wherein strtod sets endptr to
		 * point one byte beyond the end of the string when given "inf" or
		 * "infinity".
		 */
		if (endptr != num && endptr[-1] == '\0')
			endptr--;
	}
#endif							/* HAVE_BUGGY_SOLARIS_STRTOD */

	/* skip trailing whitespace */
	while (*endptr != '\0' && isspace((unsigned char) *endptr))
		endptr++;

	/* if there is any junk left at the end of the string, bail out */
	if (*endptr != '\0')
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
				 errmsg("invalid input syntax for type %s: \"%s\"",
						"real", orig_num)));

	PG_RETURN_FLOAT4(val);
}

Datum
varchar2float4(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);

	if (varcharTruelen(source) == 0)
		PG_RETURN_FLOAT4(0);

	return cstring2float4(varchar2cstring(source));
}

Datum
varchar2float8(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	char	   *num;

	if (varcharTruelen(source) == 0)
		PG_RETURN_FLOAT8(0);

	num = varchar2cstring(source);
	PG_RETURN_FLOAT8(float8in_internal(num, NULL, "double precision", num));
}

Datum
varchar2date(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	char	   *str;
	DateADT		date;

	str = varchar2cstring(source);
	date = DatumGetDateADT(DirectFunctionCall1(date_in, CStringGetDatum(str)));
	pfree(str);
	PG_RETURN_DATEADT(date);
}

Datum
varchar2time(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	char	   *str;
	TimeADT		time;

	str = varchar2cstring(source);
	time = DatumGetTimeADT(DirectFunctionCall1(time_in, CStringGetDatum(str)));
	pfree(str);
	PG_RETURN_TIMEADT(time);
}

Datum
varchar2money(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	int64		val;

	if (varcharTruelen(source) == 0)
		PG_RETURN_CASH(0);

	val = pg_strtoint64(varchar2cstring(source));
	PG_RETURN_CASH((Cash) val);
}

Datum
varchar2numeric(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	Numeric		result;
	char	   *str;

	str = varchar2cstring(source);
	result = DatumGetNumeric(DirectFunctionCall1(numeric_in, CStringGetDatum(str)));
	pfree(str);
	PG_RETURN_NUMERIC(result);
}

/*****************************************************************************
 *	 bpchar - char()														 *
 *****************************************************************************/

/*
 * bpchar_input -- common guts of bpcharin and bpcharrecv
 *
 * s is the input text of length len (may not be null-terminated)
 * atttypmod is the typmod value to apply
 *
 * Note that atttypmod is measured in characters, which
 * is not necessarily the same as the number of bytes.
 *
 * If the input string is too long, raise an error, unless the extra
 * characters are spaces, in which case they're truncated.  (per SQL)
 */
static BpChar *
bpchar_input(const char *s, size_t len, int32 atttypmod)
{
	BpChar	   *result;
	char	   *r;
	size_t		maxlen;

	/* If typmod is -1 (or invalid), use the actual string length */
	if (atttypmod < (int32) VARHDRSZ)
		maxlen = len;
	else
	{
		size_t		charlen;	/* number of CHARACTERS in the input */

		maxlen = atttypmod - VARHDRSZ;
		charlen = pg_mbstrlen_with_len(s, len);

		TsqlCheckUTF16Length_bpchar_input(s, len, maxlen, charlen);

		if (charlen > maxlen)
		{
			/* Verify that extra characters are spaces, and clip them off */
			size_t		mbmaxlen = pg_mbcharcliplen(s, len, maxlen);
			size_t		j;

			/*
			 * at this point, len is the actual BYTE length of the input
			 * string, maxlen is the max number of CHARACTERS allowed for this
			 * bpchar type, mbmaxlen is the length in BYTES of those chars.
			 */
			for (j = mbmaxlen; j < len; j++)
			{
				if (s[j] != ' ')
					ereport(ERROR,
							(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
							 errmsg("value too long for type character(%d)",
									(int) maxlen)));
			}

			/*
			 * Now we set maxlen to the necessary byte length, not the number
			 * of CHARACTERS!
			 */
			maxlen = len = mbmaxlen;
		}
		else
		{
			/*
			 * Now we set maxlen to the necessary byte length, not the number
			 * of CHARACTERS!
			 */
			maxlen = len + (maxlen - charlen);
		}
	}

	result = (BpChar *) palloc(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);
	r = VARDATA(result);
	memcpy(r, s, len);

	/* blank pad the string if necessary */
	if (maxlen > len)
		memset(r + len, ' ', maxlen - len);

	return result;
}

void *
tsql_bpchar_input(const char *s, size_t len, int32 atttypmod)
{
	return bpchar_input(s, len, atttypmod);
}

/*
 * Convert a C string to CHARACTER internal representation.  atttypmod
 * is the declared length of the type plus VARHDRSZ.
 */
Datum
bpcharin(PG_FUNCTION_ARGS)
{
	char	   *s = PG_GETARG_CSTRING(0);

#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	int32		atttypmod = PG_GETARG_INT32(2);
	BpChar	   *result;

	result = bpchar_input(s, strlen(s), atttypmod);
	PG_RETURN_BPCHAR_P(result);
}

/*
 *		bpcharrecv			- converts external binary format to bpchar
 */
Datum
bpcharrecv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);

#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	int32		atttypmod = PG_GETARG_INT32(2);
	BpChar	   *result;
	char	   *str;
	int			nbytes;

	str = pq_getmsgtext(buf, buf->len - buf->cursor, &nbytes);
	result = bpchar_input(str, nbytes, atttypmod);
	pfree(str);
	PG_RETURN_BPCHAR_P(result);
}

/*
 * Converts a CHARACTER type to the specified size.
 *
 * maxlen is the typmod, ie, declared length plus VARHDRSZ bytes.
 * isExplicit is true if this is for an explicit cast to char(N).
 *
 * Truncation rules: for an explicit cast, silently truncate to the given
 * length; for an implicit cast, raise error unless extra characters are
 * all spaces.  (This is sort-of per SQL: the spec would actually have us
 * raise a "completion condition" for the explicit cast case, but Postgres
 * hasn't got such a concept.)
 */
Datum
bpchar(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);	/* source string in UTF8 */
	int32		maxByteLen = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	BpChar	   *result;
	int32		byteLen;
	char	   *r;
	char	   *s_data;
	int			i;
	char	   *tmp = NULL;		/* To hold the string encoded in target
								 * column's collation. */
	char	   *resStr = NULL;	/* To hold the final string in UTF8 encoding. */
	coll_info	collInfo;
	int			blankSpace = 0; /* How many blank space we need to pad. */
	int			encodedByteLen;

	/* If type of target is NCHAR then handle it differently. */
	if (fcinfo->flinfo->fn_expr && is_basetype_nchar_nvarchar(((FuncExpr *) fcinfo->flinfo->fn_expr)->funcresulttype))
		return nchar(fcinfo);

	/* No work if typmod is invalid */
	if (maxByteLen < (int32) VARHDRSZ)
		PG_RETURN_BPCHAR_P(source);

	maxByteLen -= VARHDRSZ;

	byteLen = VARSIZE_ANY_EXHDR(source);
	s_data = VARDATA_ANY(source);

	/*
	 * Try to find the lcid corresponding to the collation of the target
	 * column.
	 */
	if (fcinfo->flinfo->fn_expr)
	{
		collInfo = lookup_collation_table(((FuncExpr *) fcinfo->flinfo->fn_expr)->funccollid);
	}
	else
	{
		/*
		 * Special handling required for OUTPUT params because this input
		 * function, bpchar would be called from TDS to send the OUTPUT params
		 * of stored proc.
		 */
		collInfo = lookup_collation_table(get_server_collation_oid_internal(false));
	}

	/*
	 * And encode the input string (usually in UTF8 encoding) in desired
	 * encoding.
	 */
	tmp = encoding_conv_util(s_data, byteLen, PG_UTF8, collInfo.enc, &encodedByteLen);
	byteLen = encodedByteLen;

	if (byteLen == maxByteLen)
		PG_RETURN_BPCHAR_P(source);

	if (byteLen > maxByteLen)
	{
		/*
		 * Verify that extra characters are spaces, and clip them off
		 * preserving multibyte boundary.
		 */
		size_t		maxmblen;

		maxmblen = pg_encoding_mbcliplen(collInfo.enc, tmp, byteLen, maxByteLen);

		if (!isExplicit &&
			!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
		{
			for (i = maxmblen; i < byteLen; i++)
				if (tmp[i] != ' ')
					ereport(ERROR,
							(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
							 errmsg("value too long for type character(%d)",
									maxByteLen)));
		}

		/* Encode the input string back to UTF8 */
		resStr = encoding_conv_util(tmp, maxmblen, collInfo.enc, PG_UTF8, &encodedByteLen);
		byteLen = encodedByteLen;
	}
	else
	{
		blankSpace = maxByteLen - byteLen;
		/* Encode the input string back to UTF8 */
		resStr = encoding_conv_util(tmp, byteLen, collInfo.enc, PG_UTF8, &encodedByteLen);

		/*
		 * And override the len with actual length of string (encoded in
		 * UTF-8)
		 */
		if (resStr != tmp)
			byteLen = encodedByteLen;
	}

	result = palloc(byteLen + blankSpace + VARHDRSZ);
	SET_VARSIZE(result, byteLen + blankSpace + VARHDRSZ);
	r = VARDATA(result);

	memcpy(r, resStr, byteLen);

	/* blank pad the string if necessary */
	if (blankSpace > 0)
		memset(r + byteLen, ' ', blankSpace);

	if (tmp && s_data != tmp)
		pfree(tmp);

	PG_RETURN_BPCHAR_P(result);
}

/*
 * Converts a NCHAR type to the specified size.
 *
 * maxlen is the typmod, ie, declared length plus VARHDRSZ bytes.
 * isExplicit is true if this is for an explicit cast to nchar(N).
 *
 * Truncation rules: for an explicit cast, silently truncate to the given
 * length; for an implicit cast, raise error unless extra characters are
 * all spaces.  (This is sort-of per SQL: the spec would actually have us
 * raise a "completion condition" for the explicit cast case, but Postgres
 * hasn't got such a concept.)
 */
Datum
nchar(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);
	int32		maxlen = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	BpChar	   *result;
	int32		len;
	char	   *r;
	char	   *s;
	int			i;
	int			charlen;		/* number of characters in the input string +
								 * VARHDRSZ */

	/* No work if typmod is invalid */
	if (maxlen < (int32) VARHDRSZ)
		PG_RETURN_BPCHAR_P(source);

	maxlen -= VARHDRSZ;

	len = VARSIZE_ANY_EXHDR(source);
	s = VARDATA_ANY(source);

	charlen = pg_mbstrlen_with_len(s, len);

	TsqlCheckUTF16Length_bpchar(s, len, maxlen, charlen, isExplicit);

	/* No work if supplied data matches typmod already */
	if (charlen == maxlen)
		PG_RETURN_BPCHAR_P(source);

	if (charlen > maxlen)
	{
		/* Verify that extra characters are spaces, and clip them off */
		size_t		maxmblen;

		maxmblen = pg_mbcharcliplen(s, len, maxlen);

		if (!isExplicit &&
			!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
		{
			for (i = maxmblen; i < len; i++)
				if (s[i] != ' ')
					ereport(ERROR,
							(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
							 errmsg("value too long for type character(%d)",
									maxlen)));
		}

		len = maxmblen;

		/*
		 * At this point, maxlen is the necessary byte length, not the number
		 * of CHARACTERS!
		 */
		maxlen = len;
	}
	else
	{

		/*
		 * At this point, maxlen is the necessary byte length, not the number
		 * of CHARACTERS!
		 */
		maxlen = len + (maxlen - charlen);
	}

	Assert(maxlen >= len);

	result = palloc(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);
	r = VARDATA(result);

	memcpy(r, s, len);

	/* blank pad the string if necessary */
	if (maxlen > len)
		memset(r + len, ' ', maxlen - len);

	PG_RETURN_BPCHAR_P(result);
}

static char *
bpchar2cstring(const BpChar *source)
{
	const char *s_data = VARDATA_ANY(source);
	int			len = VARSIZE_ANY_EXHDR(source);

	char	   *result = (char *) palloc(len + 1);

	memcpy(result, s_data, len);
	result[len] = '\0';

	return result;
}

Datum
bpchar2int2(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);

	if (bpchartruelen(VARDATA_ANY(source), VARSIZE_ANY_EXHDR(source)) == 0)
		PG_RETURN_INT16(0);

	PG_RETURN_INT16(pg_strtoint16(bpchar2cstring(source)));
}

Datum
bpchar2int4(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);

	if (bpchartruelen(VARDATA_ANY(source), VARSIZE_ANY_EXHDR(source)) == 0)
		PG_RETURN_INT32(0);

	PG_RETURN_INT32(pg_strtoint32(bpchar2cstring(source)));
}

Datum
bpchar2int8(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);

	if (bpchartruelen(VARDATA_ANY(source), VARSIZE_ANY_EXHDR(source)) == 0)
		PG_RETURN_INT64(0);

	PG_RETURN_INT64(pg_strtoint64(bpchar2cstring(source)));
}

Datum
bpchar2float4(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);

	if (bpchartruelen(VARDATA_ANY(source), VARSIZE_ANY_EXHDR(source)) == 0)
		PG_RETURN_FLOAT4(0);

	return cstring2float4(bpchar2cstring(source));
}

Datum
bpchar2float8(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);
	char	   *num;

	if (bpchartruelen(VARDATA_ANY(source), VARSIZE_ANY_EXHDR(source)) == 0)
		PG_RETURN_FLOAT8(0);

	num = bpchar2cstring(source);
	PG_RETURN_FLOAT8(float8in_internal(num, NULL, "double precision", num));
}

static inline int
varcharTruelen(VarChar *arg)
{
	char	   *s = VARDATA_ANY(arg);
	int			len = VARSIZE_ANY_EXHDR(arg);

	int			i;

	/*
	 * Note that we rely on the assumption that ' ' is a singleton unit on
	 * every supported multibyte server encoding.
	 */
	for (i = len - 1; i >= 0; i--)
	{
		if (s[i] != ' ')
			break;
	}
	return i + 1;
}

static inline void
check_collation_set(Oid collid)
{
	if (!OidIsValid(collid))
	{
		/*
		 * This typically means that the parser could not resolve a conflict
		 * of implicit collations, so report it that way.
		 */
		ereport(ERROR,
				(errcode(ERRCODE_INDETERMINATE_COLLATION),
				 errmsg("could not determine which collation to use for string comparison"),
				 errhint("Use the COLLATE clause to set the collation explicitly.")));
	}
}

Datum
varchareq(PG_FUNCTION_ARGS)
{
	VarChar    *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar    *arg2 = PG_GETARG_VARCHAR_PP(1);
	int			len1,
				len2;
	bool		result;
	Oid			collid = PG_GET_COLLATION();

	check_collation_set(collid);

	len1 = varcharTruelen(arg1);
	len2 = varcharTruelen(arg2);

	if (lc_collate_is_c(collid) ||
		collid == DEFAULT_COLLATION_OID ||
		pg_newlocale_from_collation(collid)->deterministic)
	{
		/*
		 * Since we only care about equality or not-equality, we can avoid all
		 * the expense of strcoll() here, and just do bitwise comparison.
		 */
		if (len1 != len2)
			result = false;
		else
			result = (memcmp(VARDATA_ANY(arg1), VARDATA_ANY(arg2), len1) == 0);
	}
	else
	{
		result = (varstr_cmp(VARDATA_ANY(arg1), len1, VARDATA_ANY(arg2), len2,
							 collid) == 0);
	}

	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	PG_RETURN_BOOL(result);
}

Datum
varcharne(PG_FUNCTION_ARGS)
{
	VarChar    *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar    *arg2 = PG_GETARG_VARCHAR_PP(1);
	int			len1,
				len2;
	bool		result;
	Oid			collid = PG_GET_COLLATION();

	check_collation_set(collid);

	len1 = varcharTruelen(arg1);
	len2 = varcharTruelen(arg2);

	if (lc_collate_is_c(collid) ||
		collid == DEFAULT_COLLATION_OID ||
		pg_newlocale_from_collation(collid)->deterministic)
	{
		/*
		 * Since we only care about equality or not-equality, we can avoid all
		 * the expense of strcoll() here, and just do bitwise comparison.
		 */
		if (len1 != len2)
			result = true;
		else
			result = (memcmp(VARDATA_ANY(arg1), VARDATA_ANY(arg2), len1) != 0);
	}
	else
	{
		result = (varstr_cmp(VARDATA_ANY(arg1), len1, VARDATA_ANY(arg2), len2,
							 collid) != 0);
	}

	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	PG_RETURN_BOOL(result);
}

Datum
varcharlt(PG_FUNCTION_ARGS)
{
	VarChar    *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar    *arg2 = PG_GETARG_VARCHAR_PP(1);
	int			len1,
				len2;
	int			cmp;

	len1 = varcharTruelen(arg1);
	len2 = varcharTruelen(arg2);

	cmp = varstr_cmp(VARDATA_ANY(arg1), len1, VARDATA_ANY(arg2), len2,
					 PG_GET_COLLATION());

	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	PG_RETURN_BOOL(cmp < 0);
}

Datum
varcharle(PG_FUNCTION_ARGS)
{
	VarChar    *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar    *arg2 = PG_GETARG_VARCHAR_PP(1);
	int			len1,
				len2;
	int			cmp;

	len1 = varcharTruelen(arg1);
	len2 = varcharTruelen(arg2);

	cmp = varstr_cmp(VARDATA_ANY(arg1), len1, VARDATA_ANY(arg2), len2,
					 PG_GET_COLLATION());

	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	PG_RETURN_BOOL(cmp <= 0);
}

Datum
varchargt(PG_FUNCTION_ARGS)
{
	VarChar    *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar    *arg2 = PG_GETARG_VARCHAR_PP(1);
	int			len1,
				len2;
	int			cmp;

	len1 = varcharTruelen(arg1);
	len2 = varcharTruelen(arg2);

	cmp = varstr_cmp(VARDATA_ANY(arg1), len1, VARDATA_ANY(arg2), len2,
					 PG_GET_COLLATION());

	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	PG_RETURN_BOOL(cmp > 0);
}

Datum
varcharge(PG_FUNCTION_ARGS)
{
	VarChar    *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar    *arg2 = PG_GETARG_VARCHAR_PP(1);
	int			len1,
				len2;
	int			cmp;

	len1 = varcharTruelen(arg1);
	len2 = varcharTruelen(arg2);

	cmp = varstr_cmp(VARDATA_ANY(arg1), len1, VARDATA_ANY(arg2), len2,
					 PG_GET_COLLATION());

	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	PG_RETURN_BOOL(cmp >= 0);
}

Datum
varcharcmp(PG_FUNCTION_ARGS)
{
	VarChar    *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar    *arg2 = PG_GETARG_VARCHAR_PP(1);
	int			len1,
				len2;
	int			cmp;

	len1 = varcharTruelen(arg1);
	len2 = varcharTruelen(arg2);

	cmp = varstr_cmp(VARDATA_ANY(arg1), len1, VARDATA_ANY(arg2), len2,
					 PG_GET_COLLATION());

	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	PG_RETURN_INT32(cmp);
}

/*
 * varchar needs a specialized hash function because we want to ignore
 * trailing blanks in comparisons.
 */
Datum
hashvarchar(PG_FUNCTION_ARGS)
{
	VarChar    *key = PG_GETARG_VARCHAR_PP(0);
	Oid			collid = PG_GET_COLLATION();
	char	   *keydata;
	int			keylen;
	pg_locale_t mylocale = 0;
	Datum		result;

	if (!collid)
		ereport(ERROR,
				(errcode(ERRCODE_INDETERMINATE_COLLATION),
				 errmsg("could not determine which collation to use for string hashing"),
				 errhint("Use the COLLATE clause to set the collation explicitly.")));

	keydata = VARDATA_ANY(key);
	keylen = varcharTruelen(key);

	if (!lc_collate_is_c(collid) && collid != DEFAULT_COLLATION_OID)
		mylocale = pg_newlocale_from_collation(collid);

	if (!mylocale || mylocale->deterministic)
	{
		result = hash_any((unsigned char *) keydata, keylen);
	}
	else
	{
#ifdef USE_ICU
		if (mylocale->provider == COLLPROVIDER_ICU)
		{
			int32_t		ulen = -1;
			UChar	   *uchar = NULL;
			Size		bsize;
			uint8_t    *buf;

			ulen = icu_to_uchar(&uchar, keydata, keylen);

			bsize = ucol_getSortKey(mylocale->info.icu.ucol,
									uchar, ulen, NULL, 0);
			buf = palloc(bsize);
			ucol_getSortKey(mylocale->info.icu.ucol,
							uchar, ulen, buf, bsize);

			result = hash_any(buf, bsize);

			pfree(buf);
		}
		else
#endif
			/* shouldn't happen */
			elog(ERROR, "unsupported collprovider: %c", mylocale->provider);
	}

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(key, 0);

	return result;
}
