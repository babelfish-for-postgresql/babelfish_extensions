%{
#include "fts_data.h"

/* LCOV_EXCL_START */

/* No reason to constrain amount of data slurped */
#define YY_READ_BUF_SIZE 16777216

/* Handles to the buffer that the lexer uses internally */
static YY_BUFFER_STATE scanbufhandle;
%}

%option never-interactive
%option nodefault
%option noinput
%option nounput
%option noyywrap
%option yylineno
%option warn
%option prefix="fts_yy"

%%

"AND"           { yylval = "AND"; yyerror(NULL, "Full-text search conditions with boolean operators are not currently supported in Babelfish"); return AND_TOKEN; }
"AND NOT"       { yylval = "AND NOT"; yyerror(NULL, "Full-text search conditions with boolean operators are not currently supported in Babelfish"); return AND_NOT_TOKEN; }
"OR"            { yylval = "OR"; yyerror(NULL, "Full-text search conditions with boolean operators are not currently supported in Babelfish"); return OR_TOKEN; }
"NOT"			{ yylval = "NOT"; yyerror(NULL, "Full-text search conditions with boolean operators are not currently supported in Babelfish"); return NOT_TOKEN; }
"INFLECTIONAL"  { yylval = "INFLECTIONAL"; return INFLECTIONAL_TOKEN; }
"THESAURUS"     { yylval = "THESAURUS"; return THESAURUS_TOKEN; }
"FORMSOF"       { yylval = "FORMSOF"; return FORMSOF_TOKEN; }
"("             { yylval = "("; return O_PAREN_TOKEN; }
")"             { yylval = ")"; return C_PAREN_TOKEN; }
","             { yylval = ","; return COMMA_TOKEN; }
[ \t\r\n]+      { yylval = " "; return WS_TOKEN; }


FORMSOF\s*\(\s*(INFLECTIONAL|THESAURUS)\s*,\s*((\w+)|(\"[\w\s]+\"))(\s*,\s*((\w+)|(\"[\w\s]+\")))*\s*\)			    { yylval = yytext; yyerror(NULL, "Generation term is not currently supported in Babelfish"); return GENERATION_TERM_TOKEN; }  /* Handle FORMSOF generation term */
\"[^"]+\*\"               																							{ if (yytext[strlen(yytext)-2] == ' ') { yyerror(NULL, "Syntax error, space is not allowed before *"); } yylval = yytext; return PREFIX_TERM_TOKEN; }  /* Handle prefix terms */
\"[^"]*\"                																						    { yylval = yytext; return TEXT_TOKEN; }  /* Handle double-quoted phrases */
[a-zA-Z0-9~`!@#$%^&*()+_\-={[}\]\|\\:;"'<,>.?/]+ 																	{ if (strncasecmp(yytext, "FORMSOF(", strlen("FORMSOF(")) == 0) { yyerror(NULL, "Generation term is not currently supported in Babelfish"); } yylval = yytext; return WORD_TOKEN; }  /* Handle individual words */

.               																									{ return yytext[0]; }  /* Other characters are returned as-is */

%%

/* LCOV_EXCL_STOP */

void yyerror(char **result, const char *message) {
	ereport(ERROR,
			(errcode(ERRCODE_SYNTAX_ERROR),
			 errmsg("%s", message)));
}

/*
 * Called before any actual parsing is done
 */
void
fts_scanner_init(const char *str)
{
	Size slen = strlen(str);

	/*
	 * Might be left over after ereport()
	 */
	if (YY_CURRENT_BUFFER)
		yy_delete_buffer(YY_CURRENT_BUFFER);

	
	/*
	 * Check for empty input
	 */
	if (!str || !*str || (strspn(str, " \t\n\r") == slen)) {
		yyerror(NULL, "Null or empty full-text predicate.");
	}

	/* Check for Non-English Language, if true, throw unsupported error */
	if (isNonEnglishString(str)) {
		yyerror(NULL, "Full-text search conditions with languages other than English are not currently supported in Babelfish");
	}

	/*
	 * Make a scan buffer with special termination needed by flex.
	 */
	scanbuflen = slen;
	scanbuf = palloc(slen + 2);
	memcpy(scanbuf, str, slen);
	scanbuf[slen] = scanbuf[slen + 1] = YY_END_OF_BUFFER_CHAR;
	scanbufhandle = yy_scan_buffer(scanbuf, slen + 2);
	BEGIN(INITIAL);
}


/*
 * Called after parsing is done to clean up after fts_scanner_init()
 */
void
fts_scanner_finish(void)
{
	yy_delete_buffer(scanbufhandle);
	pfree(scanbuf);
}

/*
 * Util function to check if the string is of Non-English language
 */
bool
isNonEnglishString(const char *str) {
	for (const char *p = str; *p; p++) {
		/* Ignore non-breaking space character */
		if ((*p == '\302' && *p == -62 ) || (*p == '\240' && *p == -96)) {
			continue;
		}
		if (*p < 0 || *p > 127) {
			return true;
		}
	}
	return false;
}