%{   
#include "geo_data.h"
#include "utils/elog.h"

static char     *scanbuf;
static int      scanbuflen;

%}

%union {
    char* str;
    double val;
    POINT coordinatevalue;
}

%token <val> DOUBLE_TOK

%token LPAREN RPAREN COMMA_TOK NULL_TOK EMPTY_TOK Z_TOK M_TOK ZM_TOK
%token POINT_TOK LINESTRING_TOK POLYGON_TOK CIRCULARSTRING_TOK
%token MPOINT_TOK MLINESTRING_TOK MPOLYGON_TOK MSURFACE_TOK MCURVE_TOK
%token CURVEPOLYGON_TOK COMPOUNDCURVE_TOK TRIANGLE_TOK
%token COLLECTION_TOK TIN_TOK POLYHEDRALSURFACE_TOK

%type <coordinatevalue> coordinate coordz coordm coordzm
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
    | POINT_TOK  Z_TOK LPAREN coordz RPAREN
        { *result = rewrite_point_dim_query($4); }
    | POINT_TOK  M_TOK LPAREN coordm RPAREN
        { *result = rewrite_point_dim_query($4); }
    | POINT_TOK  ZM_TOK LPAREN coordzm RPAREN
        { *result = rewrite_point_dim_query($4); }
    ;

coordz:
    DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK
        { $$ = create_point($1, $2, $3, 0, 1, 0); }
            
coordm:
    DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK
        { $$ = create_point($1, $2, 0 , $3, 0, 1); }
            
coordzm:
    DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK
        { $$ = create_point($1, $2, $3, $4, 1, 1); }
    

coordinate:
    DOUBLE_TOK DOUBLE_TOK
        { $$ = create_point($1, $2, 0, 0, 0, 0); }
    | DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK
        { $$ = create_point($1, $2, $3, 0, 1, 0); }
    | DOUBLE_TOK DOUBLE_TOK NULL_TOK
        { $$ = create_point($1, $2, 0, 0, 0, 0); }
    | DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK
        { $$ = create_point($1, $2, $3, $4, 1, 1); }
    | DOUBLE_TOK DOUBLE_TOK NULL_TOK NULL_TOK
        { $$ = create_point($1, $2, 0, 0, 0, 0); }
    | DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK NULL_TOK
        { $$ = create_point($1, $2, $3, 0, 1, 0); }
    | DOUBLE_TOK DOUBLE_TOK NULL_TOK DOUBLE_TOK 
        { $$ = create_point($1, $2, 0, $4, 0, 1); }
    ;

%%

/* Include lexer after parser to avoid circular dependencies and ensure shared context */
#include "geo_scan.c"
