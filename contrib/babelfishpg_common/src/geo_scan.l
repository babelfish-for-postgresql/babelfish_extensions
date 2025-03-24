%{
#include "geo_data.h"
#include "postgres.h"
#include <stdio.h>
#include <string.h>

#define YY_READ_BUF_SIZE 16777216

/* Handles to the buffer that the lexer uses internally */
static YY_BUFFER_STATE scanbufhandle;
%}

%option never-interactive
%option case-insensitive
%option nodefault
%option noinput
%option nounput
%option noyywrap
%option yylineno
%option warn
%option prefix="geo_yy"

%%

"POINT"                 { return POINT_TOK; }
"GEOMETRYCOLLECTION"    { yyerror(NULL, " GEOMETRYCOLLECTION is currently not supported in Babelfish");  return COLLECTION_TOK; }
"MULTIPOLYGON"          { yyerror(NULL, " MULTIPOLYGON is currently not supported in Babelfish");  return MPOLYGON_TOK; }
"MULTILINESTRING"       { yyerror(NULL, " MULTILINESTRING is currently not supported in Babelfish"); return MLINESTRING_TOK; }
"MULTIPOINT"            { yyerror(NULL, " MULTIPOINT is currently not supported in Babelfish");  return MPOINT_TOK; }
"CURVEPOLYGON"          { yyerror(NULL, " CURVEPOLYGON is currently not supported in Babelfish");  return CURVEPOLYGON_TOK; }
"POLYGON"               { yyerror(NULL, " POLYGON is currently not supported in Babelfish");  return POLYGON_TOK; }
"COMPOUNDCURVE"         { yyerror(NULL, " COMPOUNDCURVE is currently not supported in Babelfish");  return COMPOUNDCURVE_TOK; }
"CIRCULARSTRING"        { yyerror(NULL, " CIRCULARSTRING is currently not supported in Babelfish"); return CIRCULARSTRING_TOK; }
"LINESTRING"            { yyerror(NULL, " LINESTRING is currently not supported in Babelfish"); return LINESTRING_TOK; }
"MULTISURFACE"          { yyerror(NULL, " Invalid Geometry ");  return MSURFACE_TOK; }
"MULTICURVE"            { yyerror(NULL, " Invalid Geometry ");  return MCURVE_TOK; }
"POLYHEDRALSURFACE"     { yyerror(NULL, " Invalid Geometry ");  return POLYHEDRALSURFACE_TOK; }
"TRIANGLE"              { yyerror(NULL, " Invalid Geometry ");  return TRIANGLE_TOK; }
"TIN"                   { yyerror(NULL, " Invalid Geometry ");  return TIN_TOK; }

-?[0-9]+(\.[0-9]+)?     { yylval.val = atof(yytext);  return DOUBLE_TOK; }

"NULL"      { return NULL_TOK; }
"EMPTY"     { return EMPTY_TOK; }
","         { return COMMA_TOK;}

"("         { return LPAREN; }
")"         { return RPAREN; }

[ \t\n]+    { /* Ignore whitespace */ }

.           { return yytext[0]; }

%%

void yyerror(char **result, const char *message) {
    ereport(ERROR,
            (errcode(ERRCODE_SYNTAX_ERROR),
            errmsg("%s", message)));
}

void geo_scanner_init(const char *str)
{
    Size slen = strlen(str);

    if (YY_CURRENT_BUFFER)
        yy_delete_buffer(YY_CURRENT_BUFFER);

    /* Check for empty input */
    if (!str || !*str || (strspn(str, " \t\n\r") == slen))
        yyerror(NULL, "Null or empty ");

    scanbuflen = slen;
    scanbuf = palloc(slen + 2);
    memcpy(scanbuf, str, slen);
    scanbuf[slen] = scanbuf[slen + 1] = YY_END_OF_BUFFER_CHAR;
    scanbufhandle = yy_scan_buffer(scanbuf, slen + 2);
    BEGIN(INITIAL);
}

void geo_scanner_finish(void)
{
    yy_delete_buffer(scanbufhandle);
    pfree(scanbuf);
}