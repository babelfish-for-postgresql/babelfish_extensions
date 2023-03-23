#include "postgres.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "src/backend/utils/mb/Unicode/sjis_to_utf8.map"
#include "src/backend/utils/mb/Unicode/utf8_to_sjis.map"

#include "src/encoding/encoding.h"

/* ----------
 * utf8_to_sjis:
 *		src_encoding,	-- source encoding id
 *		dest_encoding,	-- destination encoding id
 *		src,			-- source string (null terminated C string)
 *		dest,			-- destination string (null terminated C string)
 *		len,			-- source string length
 * Returns byte length of result string encoded in desired encoding
 * ----------
 */
int
utf8_to_sjis(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *dest, int len)
{
	return TsqlUtfToLocal(src, len, dest,
						  &sjis_from_unicode_tree,
						  NULL, 0,
						  NULL,
						  PG_SJIS);
}

int
sjis_to_utf8(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *dest, int len)
{
	return TsqlLocalToUtf(src, len, dest,
						  &sjis_to_unicode_tree,
						  NULL, 0,
						  NULL,
						  PG_SJIS);
}
