/*-------------------------------------------------------------------------
 *
 *	  WIN <--> UTF8
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/utils/mb/conversion_procs/utf8_and_win/utf8_and_win.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "src/backend/utils/mb/Unicode/utf8_to_win1250.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1251.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1252.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1253.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1254.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1255.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1256.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1257.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win1258.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win866.map"
#include "src/backend/utils/mb/Unicode/utf8_to_win874.map"
#include "src/backend/utils/mb/Unicode/win1250_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1251_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1252_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1253_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1254_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1255_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1256_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1257_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win866_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win874_to_utf8.map"
#include "src/backend/utils/mb/Unicode/win1258_to_utf8.map"

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

typedef struct
{
	pg_enc		encoding;
	const pg_mb_radix_tree *map1;	/* to UTF8 map name */
	const pg_mb_radix_tree *map2;	/* from UTF8 map name */
} pg_conv_map;

static const pg_conv_map maps[] = {
	{PG_WIN866, &win866_to_unicode_tree, &win866_from_unicode_tree},
	{PG_WIN874, &win874_to_unicode_tree, &win874_from_unicode_tree},
	{PG_WIN1250, &win1250_to_unicode_tree, &win1250_from_unicode_tree},
	{PG_WIN1251, &win1251_to_unicode_tree, &win1251_from_unicode_tree},
	{PG_WIN1252, &win1252_to_unicode_tree, &win1252_from_unicode_tree},
	{PG_WIN1253, &win1253_to_unicode_tree, &win1253_from_unicode_tree},
	{PG_WIN1254, &win1254_to_unicode_tree, &win1254_from_unicode_tree},
	{PG_WIN1255, &win1255_to_unicode_tree, &win1255_from_unicode_tree},
	{PG_WIN1256, &win1256_to_unicode_tree, &win1256_from_unicode_tree},
	{PG_WIN1257, &win1257_to_unicode_tree, &win1257_from_unicode_tree},
	{PG_WIN1258, &win1258_to_unicode_tree, &win1258_from_unicode_tree},
};

void
utf8_to_win(int src_encoding, int dest_encoding, const unsigned char *src,unsigned char *dest, int len)
{
	int			i;

	for (i = 0; i < lengthof(maps); i++)
	{
		if (dest_encoding == maps[i].encoding)
		{
			tds_UtfToLocal(src, len, dest,
					   maps[i].map2,
					   NULL, 0,
					   NULL,
					   dest_encoding);
			return ;
		}
	}

	ereport(ERROR,
			(errcode(ERRCODE_INTERNAL_ERROR),
			 errmsg("unexpected encoding ID %d for WIN character sets",
					dest_encoding)));

	return ;
}
