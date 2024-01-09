/*-------------------------------------------------------------------------
 *
 * varbinary.c
 *	  Functions for the variable-length binary type.
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include <ctype.h>
#include <limits.h>

#include "access/hash.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_type.h"
#include "collation.h"
#include "common/int.h"
#include "encoding/encoding.h"
#include "lib/hyperloglog.h"
#include "libpq/pqformat.h"
#include "miscadmin.h"
#include "parser/parser.h"
#include "parser/scansup.h"
#include "port/pg_bswap.h"
#include "regex/regex.h"
#include "utils/builtins.h"
#include "utils/bytea.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/pg_locale.h"
#include "utils/sortsupport.h"
#include "utils/varlena.h"

#include "instr.h"

PG_FUNCTION_INFO_V1(varbinaryin);
PG_FUNCTION_INFO_V1(varbinaryout);
PG_FUNCTION_INFO_V1(varbinaryrecv);
PG_FUNCTION_INFO_V1(varbinarysend);
PG_FUNCTION_INFO_V1(varbinary);
PG_FUNCTION_INFO_V1(binary);
PG_FUNCTION_INFO_V1(varbinarytypmodin);
PG_FUNCTION_INFO_V1(varbinarytypmodout);
PG_FUNCTION_INFO_V1(byteavarbinary);
PG_FUNCTION_INFO_V1(varbinarybytea);
PG_FUNCTION_INFO_V1(varbinaryrowversion);
PG_FUNCTION_INFO_V1(rowversionbinary);
PG_FUNCTION_INFO_V1(rowversionvarbinary);
PG_FUNCTION_INFO_V1(varcharvarbinary);
PG_FUNCTION_INFO_V1(bpcharvarbinary);
PG_FUNCTION_INFO_V1(varbinaryvarchar);
PG_FUNCTION_INFO_V1(varcharbinary);
PG_FUNCTION_INFO_V1(bpcharbinary);
PG_FUNCTION_INFO_V1(varcharrowversion);
PG_FUNCTION_INFO_V1(bpcharrowversion);
PG_FUNCTION_INFO_V1(int2varbinary);
PG_FUNCTION_INFO_V1(int4varbinary);
PG_FUNCTION_INFO_V1(int8varbinary);
PG_FUNCTION_INFO_V1(int2binary);
PG_FUNCTION_INFO_V1(int4binary);
PG_FUNCTION_INFO_V1(int8binary);
PG_FUNCTION_INFO_V1(int2rowversion);
PG_FUNCTION_INFO_V1(int4rowversion);
PG_FUNCTION_INFO_V1(int8rowversion);
PG_FUNCTION_INFO_V1(varbinaryint2);
PG_FUNCTION_INFO_V1(varbinaryint4);
PG_FUNCTION_INFO_V1(varbinaryint8);
PG_FUNCTION_INFO_V1(binaryint2);
PG_FUNCTION_INFO_V1(binaryint4);
PG_FUNCTION_INFO_V1(binaryint8);
PG_FUNCTION_INFO_V1(float4varbinary);
PG_FUNCTION_INFO_V1(float8varbinary);
PG_FUNCTION_INFO_V1(varbinaryfloat4);
PG_FUNCTION_INFO_V1(varbinaryfloat8);
PG_FUNCTION_INFO_V1(float4binary);
PG_FUNCTION_INFO_V1(float8binary);
PG_FUNCTION_INFO_V1(binaryfloat4);
PG_FUNCTION_INFO_V1(binaryfloat8);


/*****************************************************************************
 *	 USER I/O ROUTINES														 *
 *****************************************************************************/

#define VAL(CH)			((CH) - '0')
#define DIG(VAL)		((VAL) + '0')

#define MAX_BINARY_SIZE 8000
#define ROWVERSION_SIZE 8

static const int8 hexlookup[128] = {
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1, -1, -1,
	-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
};

static inline char
get_hex(char c)
{
	int			res = -1;

	if (c > 0 && c < 127)
		res = hexlookup[(unsigned char) c];

	if (res < 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("invalid hexadecimal digit: \"%c\"", c)));

	return (char) res;
}

/* A variant of PG's hex_decode function, but allows odd number of hex digits */
static uint64
babelfish_hex_decode_allow_odd_digits(const char *src, unsigned len, char *dst)
{
	const char *s,
			   *srcend;
	char		v1,
				v2,
			   *p;

	srcend = src + len;
	s = src;
	p = dst;

	if (len % 2 == 1)
	{
		/*
		 * If input has odd number of hex digits, add a 0 to the front to make
		 * it even
		 */
		v1 = '\0';
		v2 = get_hex(*s++);
		*p++ = v1 | v2;
	}
	/* The rest of the input must have even number of digits */
	while (s < srcend)
	{
		if (*s == ' ' || *s == '\n' || *s == '\t' || *s == '\r')
		{
			s++;
			continue;
		}
		v1 = get_hex(*s++) << 4;
		v2 = get_hex(*s++);
		*p++ = v1 | v2;
	}

	return p - dst;
}

/*
 *		varbinaryin	- input function of varbinary
 */
Datum
varbinaryin(PG_FUNCTION_ARGS)
{
	char	   *inputText = PG_GETARG_CSTRING(0);
	char	   *rp;
	char	   *tp;
	int			len;
	bytea	   *result;
	int32		typmod = PG_GETARG_INT32(2);
	const char *dump_restore = GetConfigOption("babelfishpg_tsql.dump_restore", true, false);

	len = strlen(inputText);

	if (typmod == TSQLHexConstTypmod ||
		(dump_restore && strcmp(dump_restore, "on") == 0))	/* Treat input string as
															 * T-SQL hex constant
															 * during restore */
	{
		/*
		 * calculate length of the binary code e.g. 0xFF should be 1 byte
		 * (plus VARHDRSZ) and 0xF should also be 1 byte (plus VARHDRSZ).
		 */
		int			bc = (len - 1) / 2 + VARHDRSZ;	/* maximum possible length */

		result = palloc(bc);
		bc = babelfish_hex_decode_allow_odd_digits(inputText + 2, len - 2, VARDATA(result));
		SET_VARSIZE(result, bc + VARHDRSZ); /* actual length */

		PG_RETURN_BYTEA_P(result);
	}

	tp = inputText;

	result = (bytea *) palloc(len + VARHDRSZ);
	SET_VARSIZE(result, len + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, tp, len);

	PG_RETURN_BYTEA_P(result);
}

/*
 *		varbinaryout		- converts to printable representation of byte array
 *
 *		In the traditional escaped format, non-printable characters are
 *		printed as '\nnn' (octal) and '\' as '\\'.
 *      This routine is copied from byteaout
 */
Datum
varbinaryout(PG_FUNCTION_ARGS)
{
	bytea	   *vlena = PG_GETARG_BYTEA_PP(0);
	char	   *result;
	char	   *rp;

	if (bytea_output == BYTEA_OUTPUT_HEX)
	{
		/* Print hex format */
		rp = result = palloc(VARSIZE_ANY_EXHDR(vlena) * 2 + 2 + 1);
		*rp++ = '0';
		*rp++ = 'x';
		rp += hex_encode(VARDATA_ANY(vlena), VARSIZE_ANY_EXHDR(vlena), rp);
	}
	else if (bytea_output == BYTEA_OUTPUT_ESCAPE)
	{
		/* Print traditional escaped format */
		char	   *vp;
		int			len;
		int			i;

		len = 1;				/* empty string has 1 char */
		vp = VARDATA_ANY(vlena);
		for (i = VARSIZE_ANY_EXHDR(vlena); i != 0; i--, vp++)
		{
			if (*vp == '\\')
				len += 2;
			else if ((unsigned char) *vp < 0x20 || (unsigned char) *vp > 0x7e)
				len += 4;
			else
				len++;
		}
		rp = result = (char *) palloc(len);
		vp = VARDATA_ANY(vlena);
		for (i = VARSIZE_ANY_EXHDR(vlena); i != 0; i--, vp++)
		{
			if (*vp == '\\')
			{
				*rp++ = '\\';
				*rp++ = '\\';
			}
			else if ((unsigned char) *vp < 0x20 || (unsigned char) *vp > 0x7e)
			{
				int			val;	/* holds unprintable chars */

				val = *vp;
				rp[0] = '\\';
				rp[3] = DIG(val & 07);
				val >>= 3;
				rp[2] = DIG(val & 07);
				val >>= 3;
				rp[1] = DIG(val & 03);
				rp += 4;
			}
			else
				*rp++ = *vp;
		}
	}
	else
	{
		elog(ERROR, "unrecognized bytea_output setting: %d",
			 bytea_output);
		rp = result = NULL;		/* keep compiler quiet */
	}
	
	if (rp)
		*rp = '\0';
	
	PG_RETURN_CSTRING(result);
}

/*
 *		varbinaryrecv	- converts external binary format to bytea
 */
Datum
varbinaryrecv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);
	bytea	   *result;
	int			nbytes;

	INSTR_METRIC_INC(INSTR_TSQL_VARBINARY_RECV);

	nbytes = buf->len - buf->cursor;
	result = (bytea *) palloc(nbytes + VARHDRSZ);
	SET_VARSIZE(result, nbytes + VARHDRSZ);
	pq_copymsgbytes(buf, VARDATA(result), nbytes);
	PG_RETURN_BYTEA_P(result);
}

/*
 *		varbinarysend	- converts bytea to binary format
 *
 * This is a special case: just copy the input...
 */
Datum
varbinarysend(PG_FUNCTION_ARGS)
{
	bytea	   *vlena = PG_GETARG_BYTEA_P_COPY(0);

	INSTR_METRIC_INC(INSTR_TSQL_VARBINARY_SEND);

	PG_RETURN_BYTEA_P(vlena);
}

/*
 * Converts a VARBINARY type to the specified size.
 *
 * maxlen is the typmod, ie, declared length plus VARHDRSZ bytes.
 *
 * Truncation rules: for an explicit cast, silently truncate to the given
 * length; for an implicit cast, raise error.
 * (This is sort-of per SQL: the spec would actually have us
 * raise a "completion condition" for the explicit cast case, but Postgres
 * hasn't got such a concept.)
 */
Datum
varbinary(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		len,
				maxlen;

	len = VARSIZE_ANY_EXHDR(source);

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (!isExplicit &&
		!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
		if (len > maxlen)
			ereport(ERROR,
					(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
					 errmsg("String or binary data would be truncated.\n"
							"The statement has been terminated.")));

	/* No work if typmod is invalid or supplied data fits it already */
	if (maxlen < 0 || len <= maxlen)
		PG_RETURN_BYTEA_P(source);

	/*
	 * Truncate the input data using cstring_to_text_with_len, notice text and
	 * bytea actually have the same struct.
	 */
	PG_RETURN_BYTEA_P((bytea *) cstring_to_text_with_len(data, maxlen));
}

/*
 * Converts a BINARY type to the specified size.
 *
 * maxlen is the typmod, ie, declared length plus VARHDRSZ bytes.
 *
 * Truncation rules: for an explicit cast, silently truncate to the given
 * length; for an implicit cast, raise error.
 * (This is sort-of per SQL: the spec would actually have us
 * raise a "completion condition" for the explicit cast case, but Postgres
 * hasn't got such a concept.)
 */
Datum
binary(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		len,
				maxlen;

	len = VARSIZE_ANY_EXHDR(source);

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (maxlen > MAX_BINARY_SIZE)
		ereport(ERROR,
				(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
				 errmsg("The size (%d) given to the type 'binary' exceeds the maximum allowed (%d)",
						maxlen, MAX_BINARY_SIZE)));

	if (!isExplicit &&
		!(suppress_string_truncation_error_hook && (*suppress_string_truncation_error_hook) ()))
		if (len > maxlen)
			ereport(ERROR,
					(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
					 errmsg("String or binary data would be truncated.\n"
							"The statement has been terminated.")));

	/* No work if maxlen is invalid or supplied data fits it exactly */
	if (maxlen < 0 || len == maxlen)
		PG_RETURN_BYTEA_P(source);

	if (len < maxlen)
	{
		bytea	   *result;
		int			total_size = maxlen + VARHDRSZ;
		char	   *tp;
		char	   *rp;

		result = (bytea *) palloc(total_size);
		SET_VARSIZE(result, total_size);
		tp = VARDATA(source);
		rp = VARDATA(result);

		memcpy(rp, tp, len);
		/* NULL pad the rest of the space */
		memset(rp + len, '\0', maxlen - len);

		PG_RETURN_BYTEA_P(result);
	}

	/*
	 * Truncate the input data to maxlen using cstring_to_text_with_len,
	 * notice text and bytea actually have the same struct.
	 */
	PG_RETURN_BYTEA_P((bytea *) cstring_to_text_with_len(data, maxlen));
}

/* common code for varbinarytypmodin, bpchartypmodin and varchartypmodin */
static int32
anychar_typmodin(ArrayType *ta, const char *typename)
{
	int32		typmod;
	int32	   *tl;
	int			n;

	tl = ArrayGetIntegerTypmods(ta, &n);

	/* Allow typmod of VARBINARY(MAX) to go through as is */
	if (*tl == TSQLMaxTypmod)
	{
		return *tl;
	}

	/*
	 * we're not too tense about good error message here because grammar
	 * shouldn't allow wrong number of modifiers for CHAR
	 */
	if (n != 1)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("invalid type modifier")));

	if (*tl < 1)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("length for type %s must be at least 1", typename)));
	if (*tl > MaxAttrSize)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("length for type %s cannot exceed %d",
						typename, MaxAttrSize)));

	/*
	 * For largely historical reasons, the typmod is VARHDRSZ plus the number
	 * of characters; there is enough client-side code that knows about that
	 * that we'd better not change it.
	 */
	typmod = VARHDRSZ + *tl;

	return typmod;
}

/*
 * code for varbinarytypmodout
 * copied from bpchartypmodout and varchartypmodout
 */
static char *
anychar_typmodout(int32 typmod)
{
	char	   *res = (char *) palloc(64);

	if (typmod > VARHDRSZ)
		snprintf(res, 64, "(%d)", (int) (typmod - VARHDRSZ));
	else
		*res = '\0';

	return res;
}

Datum
varbinarytypmodin(PG_FUNCTION_ARGS)
{
	ArrayType  *ta = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_INT32(anychar_typmodin(ta, "varbinary"));
}

Datum
varbinarytypmodout(PG_FUNCTION_ARGS)
{
	int32		typmod = PG_GETARG_INT32(0);

	PG_RETURN_CSTRING(anychar_typmodout(typmod));
}

static void
reverse_memcpy(char *dst, char *src, size_t n)
{
	size_t		i;

	for (i = 0; i < n; i++)
		dst[n - 1 - i] = src[i];
}

/*
 *   Cast functions
 */
Datum
byteavarbinary(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);

	PG_RETURN_BYTEA_P(source);
}

Datum
varbinarybytea(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);

	PG_RETURN_BYTEA_P(source);
}

Datum
varbinaryrowversion(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	bytea	   *result;
	char	   *data = VARDATA_ANY(source);
	size_t		len = VARSIZE_ANY_EXHDR(source);
	char	   *rp;

	if (len > ROWVERSION_SIZE)
		len = ROWVERSION_SIZE;

	result = (bytea *) palloc0(ROWVERSION_SIZE + VARHDRSZ);
	SET_VARSIZE(result, ROWVERSION_SIZE + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
rowversionbinary(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	int32		typmod = PG_GETARG_INT32(1);
	char	   *data = VARDATA_ANY(source);
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	int32		maxlen;
	bytea	   *result;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (len > maxlen)
		len = maxlen;

	result = (bytea *) palloc0(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	PG_RETURN_BYTEA_P(source);
}

Datum
rowversionvarbinary(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	int32		typmod = PG_GETARG_INT32(1);
	char	   *data = VARDATA_ANY(source);
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	int32		maxlen;
	bytea	   *result;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (len > maxlen)
		len = maxlen;

	result = (bytea *) palloc(len + VARHDRSZ);
	SET_VARSIZE(result, len + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	PG_RETURN_BYTEA_P(source);
}

Datum
varcharvarbinary(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	char	   *data = VARDATA_ANY(source);		/* Source string is UTF-8 */
	char	   *encoded_data;
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		maxlen;
	bytea	   *result;
	coll_info	collInfo;
	int			encodedByteLen;
	MemoryContext ccxt = CurrentMemoryContext;

	if (!isExplicit)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Implicit conversion from data type varchar to "
						"varbinary is not allowed. Use the CONVERT function "
						"to run this query.")));

	PG_TRY();
	{
		collInfo = lookup_collation_table(get_server_collation_oid_internal(false));
		encoded_data = encoding_conv_util(data, len, PG_UTF8, collInfo.enc, &encodedByteLen);
	}
	PG_CATCH();
	{
		MemoryContext ectx;
		ErrorData    *errorData;

		ectx = MemoryContextSwitchTo(ccxt);
		errorData = CopyErrorData();
		FlushErrorState();
		MemoryContextSwitchTo(ectx);

		ereport(ERROR,
			   (errcode(ERRCODE_INTERNAL_ERROR),
				errmsg("Failed to convert from data type varchar to varbinary, %s",
				errorData->message)));
	}
	PG_END_TRY();

	/* 
	 * If typmod is -1 (or invalid), use the actual length
	 * Length should be checked after encoding into server encoding
	 */
	if (typmod < (int32) VARHDRSZ)
		maxlen = encodedByteLen;
	else
		maxlen = typmod - VARHDRSZ;

	if (encodedByteLen > maxlen)
		encodedByteLen = maxlen;

	result = (bytea *) palloc(encodedByteLen + VARHDRSZ);
	SET_VARSIZE(result, encodedByteLen + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, encoded_data, encodedByteLen);

	PG_RETURN_BYTEA_P(result);
}

Datum
bpcharvarbinary(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);
	char	   *data = VARDATA_ANY(source);
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		maxlen;
	bytea	   *result;

	if (!isExplicit)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Implicit conversion from data type bpchar to "
						"varbinary is not allowed. Use the CONVERT function "
						"to run this query.")));

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (len > maxlen)
		len = maxlen;

	result = (bytea *) palloc(len + VARHDRSZ);
	SET_VARSIZE(result, len + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	PG_RETURN_BYTEA_P(result);
}

/*
 * This function is currently being called with 1 and 3 arguments,
 * Currently, the third argument is not being parsed in this function, 
 * Check for the number of args needs to be added if the third arg is 
 * being parsed in future
 */
Datum
varbinaryvarchar(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);		/* Source data is server encoded */
	VarChar    *result;
	char 	   *encoded_result;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	int32		typmod = -1;
	int32		maxlen = -1;
	coll_info	collInfo;
	int			encodedByteLen;
	MemoryContext ccxt = CurrentMemoryContext;

	/*
	 * Check whether the typmod argument exists, so that we 
	 * will not be reading any garbage values for typmod 
	 * which might cause Invalid read such as BABEL-4475
	 */
	if (PG_NARGS() > 1)
	{
		typmod = PG_GETARG_INT32(1);
		maxlen = typmod - VARHDRSZ;
	}

	/*
	 * Allow trailing null bytes 
	 * Its safe since multi byte UTF-8 does not contain 0x00 
	 * This is needed since we implicity add trailing zeroes to 
	 * binary type if input is less than binary(n)
	 * ex: CAST(CAST('a' AS BINARY(10)) AS VARCHAR) should work
	 * and not fail because of null byte
	 */
	while(len>0 && data[len-1] == '\0')
		len -= 1;
	
	/*
	 * Cast the entire input binary data if maxlen is 
	 * invalid or supplied data fits it
	 * Else truncate it
	 */
	PG_TRY();
	{
		collInfo = lookup_collation_table(get_server_collation_oid_internal(false));
		if (maxlen < 0 || len <= maxlen)
			encoded_result = encoding_conv_util(data, len, collInfo.enc, PG_UTF8, &encodedByteLen);
		else
			encoded_result = encoding_conv_util(data, maxlen, collInfo.enc, PG_UTF8, &encodedByteLen);
	}
	PG_CATCH();
	{
		MemoryContext ectx;
		ErrorData    *errorData;

		ectx = MemoryContextSwitchTo(ccxt);
		errorData = CopyErrorData();
		FlushErrorState();
		MemoryContextSwitchTo(ectx);

		ereport(ERROR,
			   (errcode(ERRCODE_INTERNAL_ERROR),
				errmsg("Failed to convert from data type varbinary to varchar, %s",
				errorData->message)));
	}
	PG_END_TRY();

	result = (VarChar *) cstring_to_text_with_len(encoded_result, encodedByteLen);

	PG_RETURN_VARCHAR_P(result);
}

Datum
varcharbinary(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	char	   *data = VARDATA_ANY(source);
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		maxlen;
	bytea	   *result;

	if (!isExplicit)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Implicit conversion from data type varchar to "
						"binary is not allowed. Use the CONVERT function "
						"to run this query.")));

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (len > maxlen)
		len = maxlen;

	result = (bytea *) palloc(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	/* NULL pad the rest of the space */
	memset(rp + len, '\0', maxlen - len);
	PG_RETURN_BYTEA_P(result);
}

Datum
bpcharbinary(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);
	char	   *data = VARDATA_ANY(source);
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	int32		typmod = PG_GETARG_INT32(1);
	bool		isExplicit = PG_GETARG_BOOL(2);
	int32		maxlen;
	bytea	   *result;

	if (!isExplicit)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Implicit conversion from data type char to "
						"binary is not allowed. Use the CONVERT function "
						"to run this query.")));

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (len > maxlen)
		len = maxlen;

	result = (bytea *) palloc(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	/* NULL pad the rest of the space */
	memset(rp + len, '\0', maxlen - len);
	PG_RETURN_BYTEA_P(result);
}

Datum
varcharrowversion(PG_FUNCTION_ARGS)
{
	VarChar    *source = PG_GETARG_VARCHAR_PP(0);
	char	   *data = VARDATA_ANY(source);
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	bool		isExplicit = PG_GETARG_BOOL(2);
	bytea	   *result;

	if (!isExplicit)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Implicit conversion from data type varchar to "
						"rowversion is not allowed. Use the CONVERT function "
						"to run this query.")));

	if (len > ROWVERSION_SIZE)
		len = ROWVERSION_SIZE;

	result = (bytea *) palloc0(ROWVERSION_SIZE + VARHDRSZ);
	SET_VARSIZE(result, ROWVERSION_SIZE + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
bpcharrowversion(PG_FUNCTION_ARGS)
{
	BpChar	   *source = PG_GETARG_BPCHAR_PP(0);
	char	   *data = VARDATA_ANY(source);
	char	   *rp;
	size_t		len = VARSIZE_ANY_EXHDR(source);
	bool		isExplicit = PG_GETARG_BOOL(2);
	bytea	   *result;

	if (!isExplicit)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Implicit conversion from data type bpchar to "
						"rowversion is not allowed. Use the CONVERT function "
						"to run this query.")));

	if (len > ROWVERSION_SIZE)
		len = ROWVERSION_SIZE;

	result = (bytea *) palloc0(ROWVERSION_SIZE + VARHDRSZ);
	SET_VARSIZE(result, ROWVERSION_SIZE + VARHDRSZ);

	rp = VARDATA(result);
	memcpy(rp, data, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int2varbinary(PG_FUNCTION_ARGS)
{
	int16		input = PG_GETARG_INT16(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(int16);
	int			actual_len;
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	actual_len = maxlen < len ? maxlen : len;

	result = (bytea *) palloc(actual_len + VARHDRSZ);
	SET_VARSIZE(result, actual_len + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in MSSQL */
	reverse_memcpy(rp, (char *) &input, actual_len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int4varbinary(PG_FUNCTION_ARGS)
{
	int32		input = PG_GETARG_INT32(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(int32);
	int			actual_len;
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	actual_len = maxlen < len ? maxlen : len;

	result = (bytea *) palloc(actual_len + VARHDRSZ);
	SET_VARSIZE(result, actual_len + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in MSSQL */
	reverse_memcpy(rp, (char *) &input, actual_len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int8varbinary(PG_FUNCTION_ARGS)
{
	int64		input = PG_GETARG_INT64(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(int64);
	int			actual_len;
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	actual_len = maxlen < len ? maxlen : len;

	result = (bytea *) palloc(actual_len + VARHDRSZ);
	SET_VARSIZE(result, actual_len + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in MSSQL */
	reverse_memcpy(rp, (char *) &input, actual_len);

	PG_RETURN_BYTEA_P(result);
}

Datum
varbinaryint2(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	int16	   *result = palloc0(sizeof(int16));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(int16) ? sizeof(int16) : len;
	reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_INT16(*result);
}

Datum
varbinaryint4(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	int32	   *result = palloc0(sizeof(int32));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(int32) ? sizeof(int32) : len;
	reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_INT32(*result);
}

Datum
varbinaryint8(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	int64	   *result = palloc0(sizeof(int64));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(int64) ? sizeof(int64) : len;
	reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_INT64(*result);
}

Datum
float4varbinary(PG_FUNCTION_ARGS)
{
	float4		input = PG_GETARG_FLOAT4(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(float4);
	int			actual_len;
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	actual_len = maxlen < len ? maxlen : len;

	result = (bytea *) palloc(actual_len + VARHDRSZ);
	SET_VARSIZE(result, actual_len + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in MSSQL */
	reverse_memcpy(rp, (char *) &input, actual_len);

	PG_RETURN_BYTEA_P(result);
}

Datum
float8varbinary(PG_FUNCTION_ARGS)
{
	float8		input = PG_GETARG_FLOAT8(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(float8);
	int			actual_len;
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	actual_len = maxlen < len ? maxlen : len;

	result = (bytea *) palloc(actual_len + VARHDRSZ);
	SET_VARSIZE(result, actual_len + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in MSSQL */
	reverse_memcpy(rp, (char *) &input, actual_len);

	PG_RETURN_BYTEA_P(result);
}

Datum
varbinaryfloat4(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	float4	   *result = palloc0(sizeof(float4));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(float4) ? sizeof(float4) : len;
	reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_FLOAT4(*result);
}

Datum
varbinaryfloat8(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	float8	   *result = palloc0(sizeof(float8));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(float8) ? sizeof(float8) : len;
	reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_FLOAT8(*result);
}

Datum
int2binary(PG_FUNCTION_ARGS)
{
	int16		input = PG_GETARG_INT16(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(int16);
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	result = (bytea *) palloc0(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	if (maxlen <= len)
		/* Need reverse copy because endianness is different in MSSQL */
		reverse_memcpy(rp, (char *) &input, maxlen);
	else
		/* Pad 0 to the left if maxlen is longer than input length */
		reverse_memcpy(rp + maxlen - len, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int4binary(PG_FUNCTION_ARGS)
{
	int32		input = PG_GETARG_INT32(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(int32);
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;


	result = (bytea *) palloc0(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	if (maxlen <= len)
		/* Need reverse copy because endianness is different in MSSQL */
		reverse_memcpy(rp, (char *) &input, maxlen);
	else
		/* Pad 0 to the left if maxlen is longer than input length */
		reverse_memcpy(rp + maxlen - len, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int8binary(PG_FUNCTION_ARGS)
{
	int64		input = PG_GETARG_INT64(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(int64);
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;


	result = (bytea *) palloc0(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	if (maxlen <= len)
		/* Need reverse copy because endianness is different in MSSQL */
		reverse_memcpy(rp, (char *) &input, maxlen);
	else
		/* Pad 0 to the left if maxlen is longer than input length */
		reverse_memcpy(rp + maxlen - len, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int2rowversion(PG_FUNCTION_ARGS)
{
	int16		input = PG_GETARG_INT16(0);
	int			len = sizeof(int16);
	bytea	   *result;
	char	   *rp;

	result = (bytea *) palloc0(ROWVERSION_SIZE + VARHDRSZ);
	SET_VARSIZE(result, ROWVERSION_SIZE + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in T-SQL */
	reverse_memcpy(rp + ROWVERSION_SIZE - len, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int4rowversion(PG_FUNCTION_ARGS)
{
	int32		input = PG_GETARG_INT32(0);
	int			len = sizeof(int32);
	bytea	   *result;
	char	   *rp;

	result = (bytea *) palloc0(ROWVERSION_SIZE + VARHDRSZ);
	SET_VARSIZE(result, ROWVERSION_SIZE + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in T-SQL */
	reverse_memcpy(rp + ROWVERSION_SIZE - len, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
int8rowversion(PG_FUNCTION_ARGS)
{
	int64		input = PG_GETARG_INT64(0);
	int			len = sizeof(int64);
	bytea	   *result;
	char	   *rp;

	result = (bytea *) palloc0(ROWVERSION_SIZE + VARHDRSZ);
	SET_VARSIZE(result, ROWVERSION_SIZE + VARHDRSZ);

	rp = VARDATA(result);
	/* Need reverse copy because endianness is different in T-SQL */
	reverse_memcpy(rp, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
binaryint2(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	int16	   *result = palloc0(sizeof(int16));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(int16) ? sizeof(int16) : len;
	if (len > sizeof(int16))

		/*
		 * Skip the potentially 0 padded part if the input binary is over
		 * length
		 */
		reverse_memcpy((char *) result, data + len - sizeof(int16), result_len);
	else
		reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_INT16(*result);
}

Datum
binaryint4(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	int32	   *result = palloc0(sizeof(int32));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(int32) ? sizeof(int32) : len;
	if (len > sizeof(int32))

		/*
		 * Skip the potentially 0 padded part if the input binary is over
		 * length
		 */
		reverse_memcpy((char *) result, data + len - sizeof(int32), result_len);
	else
		reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_INT32(*result);
}

Datum
binaryint8(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	int64	   *result = palloc0(sizeof(int64));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(int64) ? sizeof(int64) : len;
	if (len > sizeof(int64))

		/*
		 * Skip the potentially 0 padded part if the input binary is over
		 * length
		 */
		reverse_memcpy((char *) result, data + len - sizeof(int64), result_len);
	else
		reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_INT64(*result);
}

Datum
float4binary(PG_FUNCTION_ARGS)
{
	float4		input = PG_GETARG_FLOAT4(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(float4);
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;


	result = (bytea *) palloc0(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	if (maxlen <= len)
		/* Need reverse copy because endianness is different in MSSQL */
		reverse_memcpy(rp, (char *) &input, maxlen);
	else
		/* Pad 0 to the left if maxlen is longer than input length */
		reverse_memcpy(rp + maxlen - len, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
float8binary(PG_FUNCTION_ARGS)
{
	float8		input = PG_GETARG_FLOAT8(0);
	int32		typmod = PG_GETARG_INT32(1);
	int32		maxlen;
	int			len = sizeof(float8);
	bytea	   *result;
	char	   *rp;

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;


	result = (bytea *) palloc0(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);

	rp = VARDATA(result);
	if (maxlen <= len)
		/* Need reverse copy because endianness is different in MSSQL */
		reverse_memcpy(rp, (char *) &input, maxlen);
	else
		/* Pad 0 to the left if maxlen is longer than input length */
		reverse_memcpy(rp + maxlen - len, (char *) &input, len);

	PG_RETURN_BYTEA_P(result);
}

Datum
binaryfloat4(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	float4	   *result = palloc0(sizeof(float4));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(float4) ? sizeof(float4) : len;
	if (len > sizeof(float4))

		/*
		 * Skip the potentially 0 padded part if the input binary is over
		 * length
		 */
		reverse_memcpy((char *) result, data + len - sizeof(float4), result_len);
	else
		reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_FLOAT4(*result);
}

Datum
binaryfloat8(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	char	   *data = VARDATA_ANY(source);
	int32		len;
	int32		result_len;
	float8	   *result = palloc0(sizeof(float8));

	len = VARSIZE_ANY_EXHDR(source);
	result_len = len > sizeof(float8) ? sizeof(float8) : len;
	if (len > sizeof(float8))

		/*
		 * Skip the potentially 0 padded part if the input binary is over
		 * length
		 */
		reverse_memcpy((char *) result, data + len - sizeof(float8), result_len);
	else
		reverse_memcpy((char *) result, data, result_len);

	PG_RETURN_FLOAT8(*result);
}

int8
			varbinarycompare(bytea *source1, bytea *source2);

int8
			inline
varbinarycompare(bytea *source1, bytea *source2)
{
	char	   *data1 = VARDATA_ANY(source1);
	int32		len1 = VARSIZE_ANY_EXHDR(source1);
	char	   *data2 = VARDATA_ANY(source2);
	int32		len2 = VARSIZE_ANY_EXHDR(source2);

	unsigned char byte1;
	unsigned char byte2;
	int32		maxlen = len2 > len1 ? len2 : len1;

	INSTR_METRIC_INC(INSTR_TSQL_VARBINARY_COMPARE);

	/* loop all the bytes */
	for (int i = 0; i < maxlen; i++)
	{
		byte1 = i < len1 ? data1[i] : 0;
		byte2 = i < len2 ? data2[i] : 0;
		/* we've found a different byte */
		if (byte1 > byte2)
			return 1;
		else if (byte1 < byte2)
			return -1;
	}
	return 0;
}

PG_FUNCTION_INFO_V1(varbinary_eq);
PG_FUNCTION_INFO_V1(varbinary_neq);
PG_FUNCTION_INFO_V1(varbinary_gt);
PG_FUNCTION_INFO_V1(varbinary_geq);
PG_FUNCTION_INFO_V1(varbinary_lt);
PG_FUNCTION_INFO_V1(varbinary_leq);
PG_FUNCTION_INFO_V1(varbinary_cmp);
PG_FUNCTION_INFO_V1(int4varbinary_div);
PG_FUNCTION_INFO_V1(varbinaryint4_div);

Datum
varbinary_eq(PG_FUNCTION_ARGS)
{
	bytea	   *source1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *source2 = PG_GETARG_BYTEA_PP(1);
	bool		result = varbinarycompare(source1, source2) == 0;

	PG_RETURN_BOOL(result);
}

Datum
varbinary_neq(PG_FUNCTION_ARGS)
{
	bytea	   *source1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *source2 = PG_GETARG_BYTEA_PP(1);
	bool		result = varbinarycompare(source1, source2) != 0;

	PG_RETURN_BOOL(result);
}

Datum
varbinary_gt(PG_FUNCTION_ARGS)
{
	bytea	   *source1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *source2 = PG_GETARG_BYTEA_PP(1);
	bool		result = varbinarycompare(source1, source2) > 0;

	PG_RETURN_BOOL(result);
}

Datum
varbinary_geq(PG_FUNCTION_ARGS)
{
	bytea	   *source1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *source2 = PG_GETARG_BYTEA_PP(1);
	bool		result = varbinarycompare(source1, source2) >= 0;

	PG_RETURN_BOOL(result);
}

Datum
varbinary_lt(PG_FUNCTION_ARGS)
{
	bytea	   *source1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *source2 = PG_GETARG_BYTEA_PP(1);
	bool		result = varbinarycompare(source1, source2) < 0;

	PG_RETURN_BOOL(result);
}

Datum
varbinary_leq(PG_FUNCTION_ARGS)
{
	bytea	   *source1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *source2 = PG_GETARG_BYTEA_PP(1);
	bool		result = varbinarycompare(source1, source2) <= 0;

	PG_RETURN_BOOL(result);
}

Datum
int4varbinary_div(PG_FUNCTION_ARGS)
{
       int32      dividend = PG_GETARG_INT32(0);
       bytea      *varbinary_divisor = PG_GETARG_BYTEA_PP(1);
       char       *data = VARDATA_ANY(varbinary_divisor);
       int32      len;
       int32      result_len;
       int32      *resultint = palloc0(sizeof(int32));
       int32 divisor = 0;
       int32 result;
       len = VARSIZE_ANY_EXHDR(varbinary_divisor);
       result_len = len > sizeof(int32) ? sizeof(int32) : len;
       memcpy((char *) resultint + (sizeof(int32)- result_len), data, result_len);

       divisor = pg_ntoh32((int32) *resultint);
       if (divisor == 0)
       {
	       ereport(ERROR,
			(errcode(ERRCODE_DIVISION_BY_ZERO),
			errmsg("division by zero")));
	       /* ensure compiler realizes we mustn't reach the division (gcc bug) */
	       PG_RETURN_NULL();
       }

       result = dividend / divisor;
       PG_RETURN_INT32(result);
}

Datum
varbinaryint4_div(PG_FUNCTION_ARGS)
{
       bytea      *varbinary_dividend = PG_GETARG_BYTEA_PP(0);
	   int32      divisor = PG_GETARG_INT32(1);
       char       *data = VARDATA_ANY(varbinary_dividend);
       int32      len;
       int32      result_len;
       int32      *resultint = palloc0(sizeof(int32));
       int32 dividend = 0;
       int32 result;

       len = VARSIZE_ANY_EXHDR(varbinary_dividend);
       result_len = len > sizeof(int32) ? sizeof(int32) : len;
       memcpy((char *) resultint + (sizeof(int32)- result_len), data, result_len);
       dividend = pg_ntoh32((int32) *resultint);

       if (divisor == 0)
       {
		ereport(ERROR,
			(errcode(ERRCODE_DIVISION_BY_ZERO),
			errmsg("division by zero")));
		/* ensure compiler realizes we mustn't reach the division (gcc bug) */
		PG_RETURN_NULL();
       }

       result = dividend / divisor;
       PG_RETURN_INT32(result);

}


Datum
varbinary_cmp(PG_FUNCTION_ARGS)
{
	bytea	   *source1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *source2 = PG_GETARG_BYTEA_PP(1);

	PG_RETURN_INT32(varbinarycompare(source1, source2));
}


PG_FUNCTION_INFO_V1(varbinary_length);

Datum
varbinary_length(PG_FUNCTION_ARGS)
{
	bytea	   *source = PG_GETARG_BYTEA_PP(0);
	int32		limit = VARSIZE_ANY_EXHDR(source);

	PG_RETURN_INT32(limit);
}

