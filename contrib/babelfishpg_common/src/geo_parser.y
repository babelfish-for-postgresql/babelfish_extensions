%{   
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "postgres.h"
#include "lib/stringinfo.h"
#include "utils/elog.h"
#include "utils/builtins.h"
#include "fmgr.h"  
#include "geo_data.h"

static char     *scanbuf;
static int      scanbuflen;

%}

%union {
    char* str;
    double val;
    POINT coordinatevalue;
}

%token <val> DOUBLE_TOK

%token POINT_TOK
%token LPAREN
%token RPAREN
%token NULL_TOK
%token EMPTY_TOK
%token COMMA_TOK 

%token LINESTRING_TOK
%token POLYGON_TOK
%token MPOINT_TOK
%token MLINESTRING_TOK
%token MPOLYGON_TOK
%token MSURFACE_TOK
%token MCURVE_TOK
%token CURVEPOLYGON_TOK
%token COMPOUNDCURVE_TOK
%token CIRCULARSTRING_TOK
%token COLLECTION_TOK
%token TRIANGLE_TOK
%token TIN_TOK
%token POLYHEDRALSURFACE_TOK

%type <coordinatevalue> coordinate
%type <str> point_query 

%start point_query
%define api.prefix {geo_yy}
%parse-param {char** result}
%expect 0

%%

point_query:
    POINT_TOK LPAREN coordinate RPAREN
        { *result = rewrite_point_query($3); }
    | POINT_TOK EMPTY_TOK
        { *result = strdup("POINT EMPTY"); }
    ;

coordinate:
    DOUBLE_TOK DOUBLE_TOK
        { $$ = create_coordinate($1, $2, 0, 0, 0, 0); }
    | DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK
        { $$ = create_coordinate($1, $2, $3, 0, 1, 0); }
    | DOUBLE_TOK DOUBLE_TOK NULL_TOK
        { $$ = create_coordinate($1, $2, 0, 0, 0, 0); }
    | DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK
        { $$ = create_coordinate($1, $2, $3, $4, 1, 1); }
    | DOUBLE_TOK DOUBLE_TOK NULL_TOK NULL_TOK
        { $$ = create_coordinate($1, $2, 0, 0, 0, 0); }
    | DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK NULL_TOK
        { $$ = create_coordinate($1, $2, $3, 0, 1, 0); }
    | DOUBLE_TOK DOUBLE_TOK NULL_TOK DOUBLE_TOK 
        { $$ = create_coordinate($1, $2, 0, $4, 0, 1); }
    ;

%%

/* Include lexer after parser to avoid circular dependencies and ensure shared context */
#include "geo_scan.c"
