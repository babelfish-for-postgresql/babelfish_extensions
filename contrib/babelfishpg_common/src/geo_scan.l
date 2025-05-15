%{
#include "geo_data.h"

#define YY_READ_BUF_SIZE 16 * 1024 * 1024

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

POINT                 { return POINT_TOK; }
LINESTRING            { yyerror(NULL, "LINESTRING is not supported"); return LINESTRING_TOK; }
CIRCULARSTRING        { yyerror(NULL, "CIRCULARSTRING is not supported"); return CIRCULARSTRING_TOK; }
POLYGON               { yyerror(NULL, "POLYGON is not supported");  return POLYGON_TOK; }
MULTIPOINT            { yyerror(NULL, "MULTIPOINT is not supported");  return MPOINT_TOK; }
MULTILINESTRING       { yyerror(NULL, "MULTILINESTRING is not supported"); return MLINESTRING_TOK; }
MULTIPOLYGON          { yyerror(NULL, "MULTIPOLYGON is not supported");  return MPOLYGON_TOK; }
CURVEPOLYGON          { yyerror(NULL, "CURVEPOLYGON is not supported");  return CURVEPOLYGON_TOK; }
COMPOUNDCURVE         { yyerror(NULL, "COMPOUNDCURVE is not supported");  return COMPOUNDCURVE_TOK; }
GEOMETRYCOLLECTION    { yyerror(NULL, "GEOMETRYCOLLECTION is not supported");  return COLLECTION_TOK; }
MULTISURFACE          { yyerror(NULL, "Invalid Geometry");  return MSURFACE_TOK; }
MULTICURVE            { yyerror(NULL, "Invalid Geometry");  return MCURVE_TOK; }
POLYHEDRALSURFACE     { yyerror(NULL, "Invalid Geometry");  return POLYHEDRALSURFACE_TOK; }
TRIANGLE              { yyerror(NULL, "Invalid Geometry");  return TRIANGLE_TOK; }
TIN                   { yyerror(NULL, "Invalid Geometry");  return TIN_TOK; }

[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)? {
    double val = atof(yytext);
    yylval.val = val;
    return DOUBLE_TOK;
}
[nN][aA][nN]    {
    yylval.val = NAN;
    return DOUBLE_TOK;
}


NULL             { return NULL_TOK; }
[ \t\n\r]+EMPTY  { return EMPTY_TOK; }

\(         { return LPAREN; }
\)         { return RPAREN; }

Z          { return Z_TOK; }
M          { return M_TOK; }
ZM         { return ZM_TOK; }

[ \t\n\r]+    { /* Ignore whitespace */ }

.           { return yytext[0]; }

%%

void yyerror(char **result, const char *message) {
    ereport(ERROR,
            (errcode(ERRCODE_SYNTAX_ERROR),
            errmsg("%s", message)));
}

void geo_scanner_init(const char *str)
{
    Size slen;

    if (YY_CURRENT_BUFFER)
        yy_delete_buffer(YY_CURRENT_BUFFER);

    /* Check for NULL input first */
    if (str == NULL) {
       yyerror(NULL, "Invalid input: string is NULL");
    }

    slen = strlen(str);

    /* Check for empty or whitespace-only input */
    if (slen == 0  || (strspn(str, " \t\n\r") == slen)) {
        yyerror(NULL, "Invalid input: string is empty or contains only whitespace characters");
    }

    scanbuflen = slen;
    scanbuf = palloc(slen + 2);
    memcpy(scanbuf, str, slen);
    scanbuf[slen] = scanbuf[slen + 1] = YY_END_OF_BUFFER_CHAR;
    scanbufhandle = yy_scan_buffer(scanbuf, slen + 2);
    BEGIN(INITIAL);
}

void geo_scanner_finish(void)
{
    if (scanbufhandle)
        yy_delete_buffer(scanbufhandle);
    if (scanbuf)
        pfree(scanbuf);
    scanbuf = NULL;
    scanbufhandle = NULL;
}