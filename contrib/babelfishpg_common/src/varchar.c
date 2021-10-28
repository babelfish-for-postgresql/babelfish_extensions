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
#include "catalog/pg_collation.h"
#include "fmgr.h"
#include "libpq/pqformat.h"
#include "nodes/nodeFuncs.h"
#include "parser/parser.h"      /* only needed for GUC variables */
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/pg_locale.h"
#include "utils/varlena.h"
#include "mb/pg_wchar.h"

int  TsqlUTF8LengthInUTF16(const void *vin, int len);
void TsqlCheckUTF16Length_varchar(const char *s_data, int32 len, int32 maxlen, bool isExplicit);
void TsqlCheckUTF16Length_bpchar(const char *s, int32 len, int32 maxlen, int charlen, bool isExplicit);
void TsqlCheckUTF16Length_bpchar_input(const char *s, int32 len, int32 maxlen, int charlen);
void TsqlCheckUTF16Length_varchar_input(const char *s, int32 len, int32 maxlen);
void *tsql_varchar_input(const char *s, size_t len, int32 atttypmod);

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

/*
 * TsqlUTF8LengthInUTF16 - compute the length of a UTF8 string in number of
 * 							 16-bit units if we were to convert it into
 * 							 UTF16 with TdsUTF8toUTF16StringInfo()
 */	
int
TsqlUTF8LengthInUTF16(const void *vin, int len)
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

static inline void
TsqlCheckUTF16Length(const char *utf8_str, size_t len, size_t maxlen,
						char *varstr)
{
	int i;
	for (i = len; i > 0; i--)
		if (utf8_str[i - 1] != ' ')
			break;
	if (TsqlUTF8LengthInUTF16(utf8_str, i) > maxlen)
		ereport(ERROR,
				(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
					errmsg("value too long for type character%s(%d) "
						"as UTF16 output",
						varstr, (int)maxlen)));
}

/*
 * Check for T-SQL varchar function
 */
void
TsqlCheckUTF16Length_varchar(const char *s_data, int32 len, int32 maxlen, bool isExplicit)
{
	int 		i;
	size_t		maxmblen;
	if (maxlen < 0)
		return ;
	
	if (len <= maxlen)
	{
		TsqlCheckUTF16Length(s_data, len, maxlen, " varying");
		return ;
	}

	/* truncate multibyte string preserving multibyte boundary */
	maxmblen = pg_mbcharcliplen(s_data, len, maxlen);

	if (!isExplicit && 
		!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook)()))
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
	int i;
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
			!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook)()))
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
void TsqlCheckUTF16Length_varchar_input(const char *s, int32 len, int32 maxlen)
{
	TsqlCheckUTF16Length(s, len, maxlen, " varying");
}

/*
 * Check for T-SQL bpchar function
 */
void TsqlCheckUTF16Length_bpchar_input(const char *s, int32 len, int32 maxlen, int charlen)
{
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
PG_FUNCTION_INFO_V1(bpcharrecv);

PG_FUNCTION_INFO_V1(varcharin);
PG_FUNCTION_INFO_V1(varchar);
PG_FUNCTION_INFO_V1(varcharrecv);
PG_FUNCTION_INFO_V1(varchareq);
PG_FUNCTION_INFO_V1(varcharne);
PG_FUNCTION_INFO_V1(varcharlt);
PG_FUNCTION_INFO_V1(varcharle);
PG_FUNCTION_INFO_V1(varchargt);
PG_FUNCTION_INFO_V1(varcharge);
PG_FUNCTION_INFO_V1(varcharcmp);
PG_FUNCTION_INFO_V1(hashvarchar);

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
		!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook)()))
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
			!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook)()))
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

static inline int
varcharTruelen(VarChar *arg)
{
	char *s = VARDATA_ANY(arg);
	int len = VARSIZE_ANY_EXHDR(arg);

	int i;

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
	VarChar	   *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar	   *arg2 = PG_GETARG_VARCHAR_PP(1);
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
	VarChar	   *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar	   *arg2 = PG_GETARG_VARCHAR_PP(1);
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
	VarChar	   *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar	   *arg2 = PG_GETARG_VARCHAR_PP(1);
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
	VarChar	   *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar	   *arg2 = PG_GETARG_VARCHAR_PP(1);
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
	VarChar	   *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar	   *arg2 = PG_GETARG_VARCHAR_PP(1);
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
	VarChar	   *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar	   *arg2 = PG_GETARG_VARCHAR_PP(1);
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
	VarChar	   *arg1 = PG_GETARG_VARCHAR_PP(0);
	VarChar	   *arg2 = PG_GETARG_VARCHAR_PP(1);
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
	VarChar	   *key = PG_GETARG_VARCHAR_PP(0);
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
