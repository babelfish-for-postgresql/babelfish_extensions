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
#include "libpq/pqformat.h"
#include "nodes/nodeFuncs.h"
#include "parser/parser.h"		/* only needed for GUC variables */
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/varlena.h"
#include "mb/pg_wchar.h"

#include "src/include/tds_int.h"

static inline void
CheckUTF16Length(const char *utf8_str, size_t len, size_t maxlen,
				 char *varstr)
{
	int			i;

	if (sql_dialect == SQL_DIALECT_TSQL)
	{
		for (i = len; i > 0; i--)
			if (utf8_str[i - 1] != ' ')
				break;
		if (TdsUTF8LengthInUTF16(utf8_str, i) > maxlen)
			ereport(ERROR,
					(errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
					 errmsg("value too long for type character%s(%d) "
							"as UTF16 output",
							varstr, (int) maxlen)));
	}
}

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
		CheckUTF16Length(s, len, maxlen, " varying");

	result = (VarChar *) cstring_to_text_with_len(s, len);
	return result;
}

void *
tds_varchar_input(const char *s, size_t len, int32 atttypmod)
{
	return varchar_input(s, len, atttypmod);
}
