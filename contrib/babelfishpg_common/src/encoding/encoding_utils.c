#include "postgres.h"

#include "access/xact.h"
#include "catalog/namespace.h"
#include "mb/pg_wchar.h"
#include "utils/builtins.h"
#include "utils/memutils.h"
#include "utils/syscache.h"

#include "src/encoding/encoding.h"

static unsigned char *do_encoding_conversion(unsigned char *src, int len, int src_encoding, int dest_encoding, int *encodedByteLen);

/*
 * Convert server encoding to any encoding or vice-versa.
 *
 * s: input string encoded in server's encoding
 * len: byte length of input string s
 * src_encoding: encoding from which input string should be encoded to dest_encoding
 * dest_encoding: desired encoding to which input string should be encoded to
 * encodedByteLen: byte length of output string encoded in desired encoding
 */

char *
encoding_conv_util(const char *s, int len, int src_encoding, int dest_encoding, int *encodedByteLen)
{
	if (len <= 0)
	{
		*encodedByteLen = len;
		return (char *) s;		/* empty string is always valid */
	}

	return (char *) do_encoding_conversion((unsigned char *) s,
										   len,
										   src_encoding,
										   dest_encoding,
										   encodedByteLen);
}

/*
 * Convert src string to another encoding (general case).
 *
 */
static unsigned char *
do_encoding_conversion(unsigned char *src, int len,
					   int src_encoding, int dest_encoding, int *encodedByteLen)
{
	unsigned char *result;

	if (len <= 0)
	{
		*encodedByteLen = len;
		return src;				/* empty string is always valid */
	}

	if (src_encoding == dest_encoding)
	{
		*encodedByteLen = len;
		return src;				/* no conversion required, assume valid */
	}

	if (dest_encoding == PG_SQL_ASCII)
	{
		*encodedByteLen = len;
		return src;				/* any string is valid in SQL_ASCII */
	}

	if (src_encoding == PG_SQL_ASCII)
	{
		/* No conversion is possible, but we must validate the result */
		(void) pg_verify_mbstr(dest_encoding, (const char *) src, len, false);
		*encodedByteLen = len;
		return src;
	}

	if (!IsTransactionState())	/* shouldn't happen */
		elog(ERROR, "cannot perform encoding conversion outside a transaction");

	/*
	 * Allocate space for conversion result, being wary of integer overflow.
	 *
	 * len * MAX_CONVERSION_GROWTH is typically a vast overestimate of the
	 * required space, so it might exceed MaxAllocSize even though the result
	 * would actually fit.  We do not want to hand back a result string that
	 * exceeds MaxAllocSize, because callers might not cope gracefully --- but
	 * if we just allocate more than that, and don't use it, that's fine.
	 */
	if ((Size) len >= (MaxAllocHugeSize / (Size) MAX_CONVERSION_GROWTH))
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("out of memory"),
				 errdetail("String of %d bytes is too long for encoding conversion.",
						   len)));

	result = (unsigned char *)
		MemoryContextAllocHuge(CurrentMemoryContext,
							   (Size) len * MAX_CONVERSION_GROWTH + 1);

	if (src_encoding == PG_UTF8)
	{
		switch (dest_encoding)
		{
			case PG_BIG5:
				*encodedByteLen = utf8_to_big5(src_encoding, dest_encoding, src, result, len);
				break;
			case PG_GBK:
				*encodedByteLen = utf8_to_gbk(src_encoding, dest_encoding, src, result, len);
				break;
			case PG_UHC:
				*encodedByteLen = utf8_to_uhc(src_encoding, dest_encoding, src, result, len);
				break;
			case PG_SJIS:
				*encodedByteLen = utf8_to_sjis(src_encoding, dest_encoding, src, result, len);
				break;
			default:
				*encodedByteLen = utf8_to_win(src_encoding, dest_encoding, src, result, len);
				break;
		}
	}
	else
	{
		switch (src_encoding)
		{
			case PG_BIG5:
				*encodedByteLen = big5_to_utf8(src_encoding, dest_encoding, src, result, len);
				break;
			case PG_GBK:
				*encodedByteLen = gbk_to_utf8(src_encoding, dest_encoding, src, result, len);
				break;
			case PG_UHC:
				*encodedByteLen = uhc_to_utf8(src_encoding, dest_encoding, src, result, len);
				break;
			case PG_SJIS:
				*encodedByteLen = sjis_to_utf8(src_encoding, dest_encoding, src, result, len);
				break;
			default:
				*encodedByteLen = win_to_utf8(src_encoding, dest_encoding, src, result, len);
				break;
		}
	}

	/*
	 * If the result is large, it's worth repalloc'ing to release any extra
	 * space we asked for.  The cutoff here is somewhat arbitrary, but we
	 * *must* check when len * MAX_CONVERSION_GROWTH exceeds MaxAllocSize.
	 */
	if (len > 1000000)
	{
		Size		resultlen = strlen((char *) result);

		if (resultlen >= MaxAllocSize)
			ereport(ERROR,
					(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
					 errmsg("out of memory"),
					 errdetail("String of %d bytes is too long for encoding conversion.",
							   len)));

		result = (unsigned char *) repalloc(result, resultlen + 1);
	}

	return result;
}
