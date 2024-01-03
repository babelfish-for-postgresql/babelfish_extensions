#ifndef FTS_PARSER_H
#define FTS_PARSER_H

/* in fts_scan.l */
extern int	fts_yylex(void);
extern void fts_yyerror(char **result, const char *message) pg_attribute_noreturn();
extern void fts_scanner_init(const char *str);
extern void fts_scanner_finish(void);
extern bool isNonEnglishString(const char *str);

/* in fts_parser.y */
extern int fts_yyparse(char **result);

#endif /* FTS_PARSER_H */
