/*-------------------------------------------------------------------------
 *
 *	  GBK <--> UTF8
 *
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/utils/mb/conversion_procs/utf8_and_gbk/utf8_and_gbk.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "src/backend/utils/mb/Unicode/gbk_to_utf8.map"
#include "src/backend/utils/mb/Unicode/utf8_to_gbk.map"

#include "src/include/tds_int.h"

/* ----------
 * conv_proc(
 *		INTEGER,	-- source encoding id
 *		INTEGER,	-- destination encoding id
 *		CSTRING,	-- source string (null terminated C string)
 *		CSTRING,	-- destination string (null terminated C string)
 *		INTEGER		-- source string length
 * ) returns VOID;
 * ----------
 */
void
utf8_to_gbk(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *dest, int len)
{
	tds_UtfToLocal(src, len, dest,
			   &gbk_from_unicode_tree,
			   NULL, 0,
			   NULL,
			   PG_GBK);

	return;
}
