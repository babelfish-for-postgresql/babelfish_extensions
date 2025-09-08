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

/* Enum for different dimension types */
typedef enum 
{ 
    XY, ZM, Z, M
} DimensionType;

/* Function declarations for lexer and parser */
extern void geo_yyerror(char **result, const char *message) pg_attribute_noreturn();
extern int geo_yylex(void);
extern int geo_yyparse(char** result_query);

/* Scanner initialization and cleanup functions */
extern void geo_scanner_init(const char *str);
extern void geo_scanner_finish(void);

/* External variable for lexer text */
extern char *geo_yytext;

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
void transform_points(PointArray *pa, DimensionType type);
char* rewrite_linestring_query(PointArray *pa);
char* rewrite_dim_linestring_query(PointArray *pa);
DimensionType determine_linestring_type(PointArray *pa);

#endif /* GEO_DATA_H */

