/*
 * Constant data exported from this file.  This array maps from the
 * zero-based keyword numbers returned by ScanKeywordLookup to the
 * Bison token numbers needed by gram.y.  This is exported because
 * callers need to pass it to scanner_init, if they are using the
 * standard keyword list ScanKeywords.
 */
#define PG_KEYWORD(kwname, value, category) value,

const uint16 pgtsql_ScanKeywordTokens[] = {
#include "src/backend_parser/kwlist.h"
};

#undef PG_KEYWORD

int dialect_selector = 0;

/*
 *  If dialect_selector is set to a value other than
 *  zero, the following macro will inject that value
 *  as the first token in the string being parsed.
 *  We use this mechanism to choose different dialects
 *  within the parser.  See the corresponding code
 *  in scanner_init()
 */

#define YY_USER_INIT                            \
	if (dialect_selector != 0 && raw_parser_hook) \
	{                                             \
		int first_token = dialect_selector;       \
		dialect_selector = 0;                     \
		*yylloc = 0;                              \
		return first_token;                       \
	}

/* need to undef to prevent an infinite-loop calling
 * pgtsql_core_yylex(...) inside pgtsql_core_yylex(...)
 */
#undef PG_YYLEX
