/*-------------------------------------------------------------------------
 *
 *	  UHC <--> UTF8
 *
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/utils/mb/conversion_procs/utf8_and_uhc/utf8_and_uhc.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "src/backend/utils/mb/Unicode/uhc_to_utf8.map"
#include "src/backend/utils/mb/Unicode/utf8_to_uhc.map"

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
utf8_to_uhc(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *dest, int len)
{
	tds_UtfToLocal(src, len, dest,
			   &uhc_from_unicode_tree,
			   NULL, 0,
			   NULL,
			   PG_UHC);

	return;
}
