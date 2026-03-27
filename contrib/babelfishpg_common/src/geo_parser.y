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
    PointArray* pointarray;
    PointArrayList* pointarraylist;
}

%token <val> DOUBLE_TOK

%token LPAREN RPAREN COMMA_TOK NULL_TOK EMPTY_TOK Z_TOK M_TOK ZM_TOK
%token POINT_TOK LINESTRING_TOK POLYGON_TOK CIRCULARSTRING_TOK
%token MPOINT_TOK MLINESTRING_TOK MPOLYGON_TOK MSURFACE_TOK MCURVE_TOK
%token CURVEPOLYGON_TOK COMPOUNDCURVE_TOK TRIANGLE_TOK
%token COLLECTION_TOK TIN_TOK POLYHEDRALSURFACE_TOK

%type <coordinatevalue> coordinate coordz coordm coordzm
%type <pointarray> ptarray ptarraym ptarrayzm ptarrayz
%type <pointarraylist> ringlist ringlistm ringlistz ringlistzm
%type <str> geospatial_query point_query linestring_query polygon_query 
%type <str> multipoint_query
%type <pointarray> mpoint_list mpoint_list_z mpoint_list_m mpoint_list_zm

%start geospatial_query
%define api.prefix {geo_yy}
%parse-param {char** result}
%expect 0

%%

geospatial_query:
    linestring_query { $$ = $1; *result = $$;  }
    | point_query { $$ = $1; *result = $$;  }
    | polygon_query { $$ = $1; *result = $$;  }
    | multipoint_query { $$ = $1; *result = $$;  }
    ;

point_query:
    POINT_TOK LPAREN coordinate RPAREN
        { $$ = rewrite_point_query($3); }
    | POINT_TOK EMPTY_TOK
        { $$ = strdup("POINT EMPTY"); }
    | POINT_TOK  Z_TOK LPAREN coordz RPAREN
        { $$ = rewrite_point_dim_query($4); }
    | POINT_TOK  M_TOK LPAREN coordm RPAREN
        { $$ = rewrite_point_dim_query($4); }
    | POINT_TOK  ZM_TOK LPAREN coordzm RPAREN
        { $$ = rewrite_point_dim_query($4); }
    ;

linestring_query:
    LINESTRING_TOK LPAREN ptarray RPAREN
        { $$ = rewrite_linestring_query($3); }
    | LINESTRING_TOK EMPTY_TOK
        { $$ = strdup("LINESTRING EMPTY"); }
    | LINESTRING_TOK Z_TOK LPAREN ptarrayz RPAREN
        { $$ = rewrite_dim_linestring_query($4); }
    | LINESTRING_TOK M_TOK LPAREN ptarraym RPAREN
        { $$ = rewrite_dim_linestring_query($4); }
    | LINESTRING_TOK ZM_TOK LPAREN ptarrayzm RPAREN
        { $$ = rewrite_dim_linestring_query($4); }
    ;

polygon_query:
    POLYGON_TOK LPAREN ringlist RPAREN
        { $$ = rewrite_polygon_query($3); }
    | POLYGON_TOK EMPTY_TOK
        { $$ = strdup("POLYGON EMPTY"); }
    | POLYGON_TOK Z_TOK LPAREN ringlistz RPAREN
        { $$ = rewrite_dim_polygon_query($4); }
    | POLYGON_TOK M_TOK LPAREN ringlistm RPAREN
        { $$ = rewrite_dim_polygon_query($4); }
    | POLYGON_TOK ZM_TOK LPAREN ringlistzm RPAREN
        { $$ = rewrite_dim_polygon_query($4); }
    ;
    
ptarray:
    ptarray COMMA_TOK coordinate
        {
            add_point($1, $3);
            $$ = $1;
        }
    | coordinate
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $1);
            $$ = pa;
        }
    ;

ptarraym:
    ptarraym COMMA_TOK coordm
        {
            add_point($1, $3);
            $$ = $1;
        }
    | coordm
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $1);
            $$ = pa;
        }
    ;

ptarrayz:
    ptarrayz COMMA_TOK coordz
        {
            add_point($1, $3);
            $$ = $1;
        }
    | coordz
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $1);
            $$ = pa;
        }
    ;

ptarrayzm:
    ptarrayzm COMMA_TOK coordzm
        {
            add_point($1, $3);
            $$ = $1;
        }
    | coordzm
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $1);
            $$ = pa;
        }
    ;

ringlist:
    ringlist COMMA_TOK LPAREN ptarray RPAREN
        {
            add_ring($1, $4);
            $$ = $1;
        }
    | LPAREN ptarray RPAREN
        {
            PointArrayList *pal = palloc(sizeof(PointArrayList));
            init_point_array_list(pal);
            add_ring(pal, $2);
            $$ = pal;
        }
    ;

ringlistm:
    ringlistm COMMA_TOK LPAREN ptarraym RPAREN
        {
            add_ring($1, $4);
            $$ = $1;
        }
    | LPAREN ptarraym RPAREN
        {
            PointArrayList *pal = palloc(sizeof(PointArrayList));
            init_point_array_list(pal);
            add_ring(pal, $2);
            $$ = pal;
        }
    ;

ringlistz:
    ringlistz COMMA_TOK LPAREN ptarrayz RPAREN
        {
            add_ring($1, $4);
            $$ = $1;
        }
    | LPAREN ptarrayz RPAREN
        {
            PointArrayList *pal = palloc(sizeof(PointArrayList));
            init_point_array_list(pal);
            add_ring(pal, $2);
            $$ = pal;
        }
    ;

ringlistzm:
    ringlistzm COMMA_TOK LPAREN ptarrayzm RPAREN
        {
            add_ring($1, $4);
            $$ = $1;
        }
    | LPAREN ptarrayzm RPAREN
        {
            PointArrayList *pal = palloc(sizeof(PointArrayList));
            init_point_array_list(pal);
            add_ring(pal, $2);
            $$ = pal;
        }
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

multipoint_query:
    MPOINT_TOK LPAREN mpoint_list RPAREN
        { $$ = rewrite_multipoint_wkt($3); }
    | MPOINT_TOK LPAREN ptarray RPAREN
        { $$ = rewrite_multipoint_wkt($3); }      
    | MPOINT_TOK EMPTY_TOK
        { $$ = pstrdup("MULTIPOINT EMPTY"); }
    | MPOINT_TOK Z_TOK LPAREN mpoint_list_z RPAREN
        { $$ = rewrite_dim_multipoint_wkt($4); }  
    | MPOINT_TOK M_TOK LPAREN mpoint_list_m RPAREN
        { $$ = rewrite_dim_multipoint_wkt($4); }  
    | MPOINT_TOK ZM_TOK LPAREN mpoint_list_zm RPAREN
        { $$ = rewrite_dim_multipoint_wkt($4); } 
    | MPOINT_TOK Z_TOK LPAREN ptarrayz RPAREN
        { $$ = rewrite_dim_multipoint_wkt($4); }
    | MPOINT_TOK M_TOK LPAREN ptarraym RPAREN
        { $$ = rewrite_dim_multipoint_wkt($4); }
    | MPOINT_TOK ZM_TOK LPAREN ptarrayzm RPAREN
        { $$ = rewrite_dim_multipoint_wkt($4); } 
    ;


/* 2D MULTIPOINT: MULTIPOINT((x y), (x y), ...) */
mpoint_list:
    LPAREN coordinate RPAREN
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $2);
            $$ = pa;
        }
    | mpoint_list COMMA_TOK LPAREN coordinate RPAREN
        {
            add_point($1, $4);
            $$ = $1;
        }
    ;

/* Z MULTIPOINT: MULTIPOINT Z((x y z), (x y z), ...) */
mpoint_list_z:
    LPAREN coordz RPAREN
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $2);
            $$ = pa;
        }
    | mpoint_list_z COMMA_TOK LPAREN coordz RPAREN
        {
            add_point($1, $4);
            $$ = $1;
        }
    ;

/* M MULTIPOINT: MULTIPOINT M((x y m), (x y m), ...) */
mpoint_list_m:
    LPAREN coordm RPAREN
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $2);
            $$ = pa;
        }
    | mpoint_list_m COMMA_TOK LPAREN coordm RPAREN
        {
            add_point($1, $4);
            $$ = $1;
        }
    ;

/* ZM MULTIPOINT: MULTIPOINT ZM((x y z m), (x y z m), ...) */
mpoint_list_zm:
    LPAREN coordzm RPAREN
        {
            PointArray *pa = palloc(sizeof(PointArray));
            init_point_array(pa);
            add_point(pa, $2);
            $$ = pa;
        }
    | mpoint_list_zm COMMA_TOK LPAREN coordzm RPAREN
        {
            add_point($1, $4);
            $$ = $1;
        }
    ;

%%

/* Include lexer after parser to avoid circular dependencies and ensure shared context */
#include "geo_scan.c"
