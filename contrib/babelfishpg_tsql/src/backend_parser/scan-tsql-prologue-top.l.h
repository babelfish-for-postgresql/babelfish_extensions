#include "postgres.h"

#include <ctype.h>
#include <unistd.h>

#include "common/string.h"
#include "nodes/parsenodes.h"
#include "src/backend_parser/gramparse.h"

#define CHECK_LOCAL_TEMP_TABLE_LENGTH(ident) \
	do { \
		if ((ident)[0] == '#' && (ident)[1] != '#' && \
			pg_mbstrlen(ident) > 116) \
		{ \
			int cliplen = pg_mbcliplen((ident), strlen(ident), 116); \
			ereport(ERROR, \
					(errcode(ERRCODE_NAME_TOO_LONG), \
					 errmsg("The identifier that starts with '%.*s' is too long. Maximum length for local temporary table is 116.", \
							cliplen, (ident)))); \
		} \
	} while (0)
