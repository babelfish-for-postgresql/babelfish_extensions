#ifndef GEO_DATA_H
#define GEO_DATA_H

#include "postgres.h"
#include "fmgr.h"
#include <math.h>
#include "utils/memutils.h"
#include "utils/geo_decls.h"
#include "utils/builtins.h"
#include "lib/stringinfo.h"

/* Structure definition for a geometric point */
typedef struct
{
    uint16_t flags;
    double x;
    double y;
    double z;
    double m;
} POINT;

/* Dynamic array to store geometric points */
typedef struct 
{
    POINT *points;
    int count; 
    int capacity;       
} PointArray;

/* Enum for different LineString dimension types */
typedef enum 
{ 
    XY, ZM, Z, M
} LineStringType;

/* Function declarations for lexer and parser */
void geo_yyerror(char **result, const char *message) pg_attribute_noreturn();
int geo_yylex(void);
int geo_yyparse(char** result_query);

/* Scanner initialization and cleanup functions */
void geo_scanner_init(const char *str);
void geo_scanner_finish(void);

/* External variable for lexer text */
char *geo_yytext;

text* geo_wkt_rewrite(text* input_text);

/* Function to create a POINT structure */
POINT create_point(double x, double y, double z, double m, int has_z, int has_m);

/* Function to rewrite a POINT query to WKT format */
char* rewrite_point_query(POINT p);
char* rewrite_point_dim_query (POINT coord);

/* PointArray management and LineString WKT conversion functions */
void init_point_array(PointArray *pa);
void resize_point_array(PointArray *pa);
void add_point(PointArray *pa, POINT p);
void transform_points(PointArray *pa, LineStringType type);
char* rewrite_linestring_query(PointArray *pa);
char* rewrite_dim_linestring_query(PointArray *pa);
LineStringType determine_linestring_type(PointArray *pa);

#endif /* GEO_DATA_H */

