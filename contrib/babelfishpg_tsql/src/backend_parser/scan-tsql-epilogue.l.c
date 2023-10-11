/*
 * Called before any actual parsing is done
 */
core_yyscan_t
pgtsql_scanner_init(const char *str,
					core_yy_extra_type *yyext,
					const ScanKeywordList *keywordlist,
					const uint16 *keyword_tokens)
{
	Size		slen = strlen(str);
	yyscan_t	scanner;

	/*
	 * If sql_dialect is set to SQL_DIALECT_TSQL arrange to inject a dialect
	 * selector token (DIALECT_TSQL)
	 */
	if (sql_dialect == SQL_DIALECT_TSQL)
		dialect_selector = DIALECT_TSQL;
	else
		dialect_selector = 0;

	if (yylex_init(&scanner) != 0)
		elog(ERROR, "yylex_init() failed: %m");

	pgtsql_core_yyset_extra(yyext, scanner);

	yyext->keywordlist = keywordlist;
	yyext->keyword_tokens = keyword_tokens;

	yyext->backslash_quote = backslash_quote;
	yyext->escape_string_warning = escape_string_warning;
	yyext->standard_conforming_strings = standard_conforming_strings;

	/*
	 * Make a scan buffer with special termination needed by flex.
	 */
	yyext->scanbuf = (char *) palloc(slen + 2);
	yyext->scanbuflen = slen;
	memcpy(yyext->scanbuf, str, slen);
	yyext->scanbuf[slen] = yyext->scanbuf[slen + 1] = YY_END_OF_BUFFER_CHAR;
	yy_scan_buffer(yyext->scanbuf, slen + 2, scanner);

	/* initialize literal buffer to a reasonable but expansible size */
	yyext->literalalloc = 1024;
	yyext->literalbuf = (char *) palloc(yyext->literalalloc);
	yyext->literallen = 0;

	return scanner;
}

/*
 * Called after parsing is done to clean up after scanner_init()
 */
void
pgtsql_scanner_finish(core_yyscan_t yyscanner)
{
	scanner_finish(yyscanner);
}

void	   *core_yyalloc(yy_size_t bytes, core_yyscan_t yyscanner);

void *
pgtsql_core_yyalloc(yy_size_t bytes, core_yyscan_t yyscanner)
{
	return core_yyalloc(bytes, yyscanner);
}

void	   *core_yyrealloc(void *ptr, yy_size_t bytes, core_yyscan_t yyscanner);

void *
pgtsql_core_yyrealloc(void *ptr, yy_size_t bytes, core_yyscan_t yyscanner)
{
	return core_yyrealloc(ptr, bytes, yyscanner);
}

void
			core_yyfree(void *ptr, core_yyscan_t yyscanner);

void
pgtsql_core_yyfree(void *ptr, core_yyscan_t yyscanner)
{
	core_yyfree(ptr, yyscanner);
}

#define core_yyset_extra pgtsql_core_yyset_extra
