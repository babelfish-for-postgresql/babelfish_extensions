#include "postgres.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "src/backend/utils/mb/Unicode/gbk_to_utf8.map"
#include "src/backend/utils/mb/Unicode/utf8_to_gbk.map"

#include "src/encoding/encoding.h"

/* ----------
 * tsql_utf8_to_gbk:
 *		src_encoding,	-- source encoding id
 *		dest_encoding,	-- destination encoding id
 *		src,			-- source string (null terminated C string)
 *		dest,			-- destination string (null terminated C string)
 *		len,			-- source string length
 * Returns byte length of result string encoded in desired encoding
 * ----------
 */
int
tsql_utf8_to_gbk(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *dest, int len)
{
	return TsqlUtfToLocal(src, len, dest,
						  &gbk_from_unicode_tree,
						  NULL, 0,
						  NULL,
						  PG_GBK);
}

int
tsql_gbk_to_utf8(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *dest, int len)
{
	return TsqlLocalToUtf(src, len, dest,
						  &gbk_to_unicode_tree,
						  NULL, 0,
						  NULL,
						  PG_GBK);
}
