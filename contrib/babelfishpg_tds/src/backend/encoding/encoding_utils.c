#include "postgres.h"

#include "access/xact.h"
#include "catalog/namespace.h"
#include "mb/pg_wchar.h"
#include "utils/builtins.h"
#include "utils/memutils.h"
#include "utils/syscache.h"

#include "src/include/tds_int.h"

static unsigned char *do_encoding_conversion(unsigned char *src, int len, int src_encoding, int dest_encoding);

/*
 * Convert server encoding to any encoding.
 *
 * See the notes about string conversion functions at the top of this file.
 */
char *
server_to_any(const char *s, int len, int encoding)
{
	if (len <= 0)
		return (char *) s;		/* empty string is always valid */

	if (encoding == GetDatabaseEncoding() ||
		encoding == PG_SQL_ASCII)
		return (char *) s;		/* assume data is valid */

	if (GetDatabaseEncoding() == PG_SQL_ASCII)
	{
		/* No conversion is possible, but we must validate the result */
		(void) pg_verify_mbstr(encoding, s, len, false);
		return (char *) s;
	}
	return (char *) do_encoding_conversion((unsigned char *) s,
											  len,
											  GetDatabaseEncoding(),
											  encoding);
}

/*
 * Convert src string to another encoding (general case).
 *
 * See the notes about string conversion functions at the top of this file.
 */
static unsigned char *
do_encoding_conversion(unsigned char *src, int len,
						  int src_encoding, int dest_encoding)
{
	unsigned char *result;

	if (len <= 0)
		return src;				/* empty string is always valid */

	if (src_encoding == dest_encoding)
		return src;				/* no conversion required, assume valid */

	if (dest_encoding == PG_SQL_ASCII)
		return src;				/* any string is valid in SQL_ASCII */

	if (src_encoding == PG_SQL_ASCII)
	{
		/* No conversion is possible, but we must validate the result */
		(void) pg_verify_mbstr(dest_encoding, (const char *) src, len, false);
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

        if (dest_encoding == PG_BIG5)
                utf8_to_big5(src_encoding, dest_encoding, src, result, len);
        else if (dest_encoding == PG_GBK)
                utf8_to_gbk(src_encoding, dest_encoding, src, result, len);
        else if (dest_encoding == PG_UHC)
                utf8_to_uhc(src_encoding, dest_encoding, src, result, len);
        else if (dest_encoding == PG_SJIS)
                utf8_to_sjis(src_encoding, dest_encoding, src, result, len);
        else
	        utf8_to_win(src_encoding, dest_encoding, src, result, len);

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
