#include "geo_data.h"

#define FLOAT8_TO_CSTRING(x)         DatumGetCString(DirectFunctionCall1(float8out, Float8GetDatum(x)))
#define YYFREE                       pfree

#define POINTFLAG_Z                  (1 << 0)  
#define POINTFLAG_M                  (1 << 1)

#define FLAGS_SET_Z(flags, value)    ((value) ? ((flags) |= POINTFLAG_Z) : ((flags) &= ~POINTFLAG_Z))
#define FLAGS_SET_M(flags, value)    ((value) ? ((flags) |= POINTFLAG_M) : ((flags) &= ~POINTFLAG_M))

#define FLAGS_GET_Z(flags)           ((flags) & POINTFLAG_Z)
#define FLAGS_GET_M(flags)           ((flags) & POINTFLAG_M)

typedef void (*PointFormatter)(StringInfoData *, POINT);

text*
geo_wkt_rewrite(text* input_text)
{
    text* result_text = NULL;
    char* input_str = NULL;
    char* translated_query = NULL;

    /* Check if the input argument is NULL */
    if (input_text == NULL)
    {
        /* Return NULL if input is NULL */
        return NULL;
    }
    

    /* Convert PostgreSQL TEXT to C string */
    input_str = text_to_cstring(input_text);

    /* Validate input string for printable ASCII characters */
    if (input_str && strlen(input_str) > 0) 
    {
        /* Check all characters for non-printable ASCII (outside range 0-127) */
        for (int i = 0; input_str[i] != '\0'; i++)
        {
            if ((unsigned char)input_str[i] > 127)
            {
                pfree(input_str);
                ereport(ERROR,
                        (errcode(ERRCODE_SYNTAX_ERROR),
                         errmsg("The input well-known text (WKT) is not valid")));
            }
        }
    }
   
    PG_TRY();
    {
        /* Initialize lexer (scanner) */
        geo_scanner_init(input_str);

        /* Call parser - Ensure `translated_query` is passed correctly */
        if (geo_yyparse(&translated_query) != 0)
            geo_yyerror(&translated_query, "geospatial parser failed");

    }
    PG_FINALLY();
    {
        geo_scanner_finish();
    }
    PG_END_TRY();

    /* Convert the rewritten query to PostgreSQL TEXT */
    if (translated_query)
    {
        result_text = cstring_to_text(translated_query);
    }

    /* Free allocated memory for input string */
    pfree(input_str);

    /* Return the rewritten query or NULL */
    return result_text;
}

/* Creates a POINT coordinate structure with the given values. */
POINT
create_point(double x, double y, double z, double m, int has_z, int has_m)
{
    POINT coord;
    
    coord.x = x;
    coord.y = y;
    coord.z = z;
    coord.m = m;
    coord.flags = 0;

    /* Check for NaN values since X and Y never allow NaN coordinates */
    if (isnan(coord.x) || isnan(coord.y))
    ereport(ERROR,
            (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Invalid coordinate value (NaN)")));
             
    if (has_z)
        FLAGS_SET_Z(coord.flags, 1);
    if (has_m)
        FLAGS_SET_M(coord.flags, 1);
        
    return coord;
}


/* Rewrites a TSQL's POINT coordinate into a PostGIS's WKT (Well-Known Text) string representation. */
char*
rewrite_point_query(POINT coord)
{
    StringInfoData output;

    /* Check for NaN values in Z nd M coordinate if present */
    if ((FLAGS_GET_Z(coord.flags) && isnan(coord.z)) ||
        (FLAGS_GET_M(coord.flags) && isnan(coord.m)))
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid coordinate value (NaN)")));
    }
    
    initStringInfo(&output);
    
    /* Start the WKT string with "POINT" */
    appendStringInfoString(&output, "POINT");

    /* 
     * Add 'M' if the point has M coordinate and doesn't have Z coordinate since PostGIS can't interpret it without M value
     * We don't need to  add Z or ZM for their respective conditions because PostGIS also understands TSQL format for these cases
     */
    if (FLAGS_GET_M(coord.flags) && !FLAGS_GET_Z(coord.flags) )
        appendStringInfoString(&output, " M");

    /* Open parenthesis for coordinate values */
    appendStringInfoChar(&output, '(');

    /* Add X and Y coordinates */
    appendStringInfo(&output, "%s %s", 
                    FLOAT8_TO_CSTRING(coord.x),
                    FLOAT8_TO_CSTRING(coord.y));

    /* Add Z coordinate if present */
    if (FLAGS_GET_Z(coord.flags)) 
        appendStringInfo(&output, " %s", FLOAT8_TO_CSTRING(coord.z));

    /* Add M coordinate if present */
    if (FLAGS_GET_M(coord.flags)) 
        appendStringInfo(&output, " %s", FLOAT8_TO_CSTRING(coord.m));
    
    /* Close parenthesis */
    appendStringInfoChar(&output, ')');
    
    return output.data; 
}

/* Rewrites a PostGIS's POINT coordinate into a TSQL's WKT (Well-Known Text) string representation. */
char*
rewrite_point_dim_query(POINT coord)
{
    StringInfoData output;

    initStringInfo(&output);

    /* Start the WKT string with "POINT" keyword  */
    appendStringInfoString(&output, "POINT");

    /* Open parenthesis for coordinate values */
    appendStringInfoChar(&output, '(');

    /* Add X and Y coordinates (always required) */
    appendStringInfo(&output, "%s %s", 
                    FLOAT8_TO_CSTRING(coord.x),
                    FLOAT8_TO_CSTRING(coord.y));

    /* Handle case: Both Z and M dimensions are present */
    if (FLAGS_GET_Z(coord.flags) && FLAGS_GET_M(coord.flags) && (!isnan(coord.z) || !isnan(coord.m))) 
    {
        /* Add Z coordinate if not NaN, otherwise add NULL placeholder */
        if (!isnan(coord.z))
            appendStringInfo(&output, " %s", FLOAT8_TO_CSTRING(coord.z));
        else
            appendStringInfoString(&output, " NULL");

        /* Add M coordinate if not NaN  */
        if (!isnan(coord.m))
            appendStringInfo(&output, " %s", FLOAT8_TO_CSTRING(coord.m));
    }
    /* Handle case: Only M dimension is present and not NaN */
    else if (FLAGS_GET_M(coord.flags) && !isnan(coord.m))
    {
        /* Add NULL placeholder for Z (even though Z flag is not set) to maintain position */
        appendStringInfoString(&output, " NULL");
        /* Add M coordinate value */
        appendStringInfo(&output, " %s", FLOAT8_TO_CSTRING(coord.m));
    }
    /* Handle case: Only Z dimension is present and not NaN */
    else if (FLAGS_GET_Z(coord.flags) && !isnan(coord.z))
    {
        appendStringInfo(&output, " %s", FLOAT8_TO_CSTRING(coord.z));
    }
    /* Implicit else: Neither Z nor M dimensions are present or both are NaN, 
       so only X and Y coordinates are included */

    /* Close parenthesis to complete the WKT representation */
    appendStringInfoChar(&output, ')');

    return output.data; 
}

/**
 * Initialize a PointArray structure with default capacity
 * Allocates memory for points array with initial capacity of 64 points.
 * Sets count to 0 and reports error if memory allocation fails.
 */
void 
init_point_array(PointArray *pa) 
{
    pa->capacity = 64;
    pa->points = palloc(pa->capacity * sizeof(POINT));
    pa->count = 0;

}

/**
 * Resize a PointArray when it reaches capacity
 * Doubles the capacity of the points array when count reaches current capacity.
 * Reports error if memory reallocation fails.
 */
void 
resize_point_array(PointArray *pa) 
{
    if (pa->count >= pa->capacity) 
    {
        pa->capacity *= 2;
        pa->points = repalloc(pa->points, pa->capacity * sizeof(POINT));
    }
}

/*
 * Add a point to the PointArray
 * Resizes array if needed and adds the point at the end.
 */
void 
add_point(PointArray *pa, POINT p) 
{
    resize_point_array(pa);
    pa->points[pa->count++] = p;
}

/*
 * Determine the appropriate dimension type based on point dimensions
 * Examines all points to determine the most appropriate dimension type:
 * - ZM: Points with both Z and M coordinates (4D)
 * - M: Points with M coordinate but no Z coordinate
 * - Z: Points with Z coordinate but no M coordinate
 * - XY: Points with only X and Y coordinates (2D)
 */
DimensionType 
determine_ptarray_type(PointArray *pa) 
{
    bool has_z = false, 
         has_m = false;

    for (int i = 0; i < pa->count; i++) 
    {
        POINT p = pa->points[i];

        /* Check for NaN values in Z nd M coordinate if present */
        if ((FLAGS_GET_Z(p.flags) && isnan(p.z)) ||
            (FLAGS_GET_M(p.flags) && isnan(p.m)))
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("Invalid coordinate value (NaN)")));
        }

        if (FLAGS_GET_Z(p.flags)) 
            has_z = true;
        if (FLAGS_GET_M(p.flags)) 
            has_m = true;
            
        /* Early return if we have both Z and M */
        if (has_z && has_m) 
            return ZM;
    }

    if (has_m) 
        return M;
    if (has_z) 
        return Z;

    return XY;
}

/*
 * Modifies point flags and coordinates to ensure all points conform to the
 * specified dimension type. Like if any point has M or Z then all other points must have M or Z
 * to conform to PostGIS's expectations. If a point doesn't have Z or M and other point has,
 * then we sets Z/M to NAN and set the respective flag.
 */
void 
transform_points(PointArray *pa, DimensionType type) 
{

    if (type == XY)
        return;  /* No transformation needed for XY type */
    
    for (int i = 0; i < pa->count; i++) 
    {
        POINT *p = &pa->points[i];

        switch (type) 
        {
            case ZM:
                if (!FLAGS_GET_Z(p->flags)) p->z = NAN;
                if (!FLAGS_GET_M(p->flags)) p->m = NAN;
                FLAGS_SET_Z(p->flags, 1);
                FLAGS_SET_M(p->flags, 1);
                break;
            case Z:
                if (!FLAGS_GET_Z(p->flags)) p->z = NAN;
                FLAGS_SET_Z(p->flags, 1);
                FLAGS_SET_M(p->flags, 0);
                break;
            case M:
                if (!FLAGS_GET_M(p->flags)) p->m = NAN;
                FLAGS_SET_Z(p->flags, 0);
                FLAGS_SET_M(p->flags, 1);
                break;
            default:
                break;
        }
    }
}

/*
 * Format  T-SQL  point coordinates to PostGIS compatible point coordinates
 */
static void
format_tsql_point_coordinates(StringInfoData *output, POINT p)
{
    /* X and Y coordinates are always included */
    appendStringInfo(output, "%s %s", FLOAT8_TO_CSTRING(p.x), FLOAT8_TO_CSTRING(p.y));

    /* Add Z and M coordinates based on flags */
    if (FLAGS_GET_Z(p.flags)) 
        appendStringInfo(output, " %s", FLOAT8_TO_CSTRING(p.z));
    if (FLAGS_GET_M(p.flags)) 
        appendStringInfo(output, " %s", FLOAT8_TO_CSTRING(p.m));
}

/*
 * Format PostGIS point coordinates to T-SQL compatible point coordinates
 */
static void
format_postgis_point_coordinates(StringInfoData *output, POINT p)
{
    /* X and Y coordinates are always included */
    appendStringInfo(output, "%s %s", FLOAT8_TO_CSTRING(p.x), FLOAT8_TO_CSTRING(p.y));
    
    /* Format Z and M values based on flags and NaN status */
    if (FLAGS_GET_Z(p.flags) && FLAGS_GET_M(p.flags)) 
    {
        /* Point has both Z and M flags */
        if (!isnan(p.z) && !isnan(p.m)) 
        {
            /* Both Z and M are not NaN */
            appendStringInfo(output, " %s %s", FLOAT8_TO_CSTRING(p.z), FLOAT8_TO_CSTRING(p.m));
        }
        else if (!isnan(p.z)) 
        {
            /* Only Z is not NaN */
            appendStringInfo(output, " %s", FLOAT8_TO_CSTRING(p.z));
        }
        else if (!isnan(p.m)) 
        {
            /* Only M is not NaN */
            appendStringInfo(output, " NULL %s", FLOAT8_TO_CSTRING(p.m));
        }
        /* If both are NaN, print nothing */
    }
    else if (FLAGS_GET_Z(p.flags) && !isnan(p.z)) 
    {
        /* Point has only Z flag and Z is not NaN */
        appendStringInfo(output, " %s", FLOAT8_TO_CSTRING(p.z));
    }
    else if (FLAGS_GET_M(p.flags) && !isnan(p.m)) 
    {
        /* Point has only M flag and M is not NaN */
        appendStringInfo(output, " NULL %s", FLOAT8_TO_CSTRING(p.m));
    }
}

/*  pfree(pa->points); pfree(pa); pattern */
static void
free_point_array(PointArray *pa)
{
    if (!pa)
        return;
    if (pa->points)
        pfree(pa->points);
    pfree(pa);
}

/*  Replaces the repeated for-loop that formats points */
static void
append_formatted_points(StringInfoData *output, PointArray *pa, bool wrap_each, PointFormatter formatter)
{
    for (int i = 0; i < pa->count; i++)
    {
        if (wrap_each)
            appendStringInfoChar(output, '(');

        formatter(output, pa->points[i]);

        if (wrap_each)
            appendStringInfoChar(output, ')');

        if (i < pa->count - 1)
            appendStringInfoString(output, ", ");
    }
}

/*
 * Converts a PointArray to a PostGIS-compatible LINESTRING WKT representation
 * Determines the appropriate dimension type (Z, M, ZM, etc.) based on the points,
 * transforms points to conform to that type, and generates a properly formatted
 * WKT string. Returns NULL if input is NULL.
 */
char* 
rewrite_linestring_query(PointArray *pa) 
{
    DimensionType type;
    StringInfoData output;

    if (!pa) 
        return NULL;

    initStringInfo(&output);
    
    /* Determine the appropriate type based on point dimensions */
    type = determine_ptarray_type(pa);
    
    /* Start with LINESTRING keyword and appropriate dimension indicator */
    appendStringInfoString(&output, "LINESTRING ");

    /* 
     * Add 'M' if the LINESTRING is M type  since PostGIS can't interpret it without M value
     * We don't need to  add Z or ZM for their respective conditions because PostGIS also understands TSQL format for these cases
     */
    if (type == M) 
        appendStringInfoChar(&output, 'M');

    /* Open parenthesis for coordinate values */
    appendStringInfoChar(&output, '(');
    
    /* Transform points to conform to the determined type */
    transform_points(pa, type);

    /* Add each point's coordinates to the WKT string */
    for (int i = 0; i < pa->count; i++) 
    {
        POINT p = pa->points[i];
        format_tsql_point_coordinates(&output, p);

        /* Add comma between points, except after the last point */
        if (i < pa->count - 1) 
            appendStringInfoString(&output, ", ");
    }

    /* Close parenthesis */
    appendStringInfoChar(&output, ')');

    /* Clean up resources */
    pfree(pa->points);
    pfree(pa);
    
    return output.data;
}

/*
 * Converts a PointArray back to a T-SQL compatible LINESTRING WKT representation
 * Creates a T-SQL compatible WKT string based on the point flags.
 * Frees the PointArray before returning.
 */
char* 
rewrite_dim_linestring_query(PointArray *pa) 
{
    StringInfoData output;
    initStringInfo(&output);

    if (!pa) 
        return NULL;

    /* Start with LINESTRING keyword */
    appendStringInfoString(&output, "LINESTRING ");
    
    /* Open parenthesis for coordinate values */
    appendStringInfoChar(&output, '(');

    /* Add each point's coordinates to the WKT string */
    for (int i = 0; i < pa->count; i++) 
    {
        POINT p = pa->points[i];
        format_postgis_point_coordinates(&output, p);

        /* Add comma between points, except after the last point */
        if (i < pa->count - 1) 
            appendStringInfoString(&output, ", ");
    }
    
    /* Close parenthesis */
    appendStringInfoChar(&output, ')');

    /* Clean up resources */
    pfree(pa->points);
    pfree(pa);
    
    return output.data;
}


/*
 * Initialize a PointArrayList structure
 */
void 
init_point_array_list(PointArrayList *pal) 
{
    pal->capacity = 8;
    pal->rings = palloc(pal->capacity * sizeof(PointArray*));
    pal->count = 0;
}

/*
 * Resize a PointArrayList when it reaches capacity
 */
void 
resize_point_array_list(PointArrayList *pal) 
{
    if (pal->count >= pal->capacity) 
    {
        pal->capacity *= 2;
        pal->rings = repalloc(pal->rings, pal->capacity * sizeof(PointArray*));
    }
}

/*
 * Add a ring (PointArray) to the PointArrayList
 */
void 
add_ring(PointArrayList *pal, PointArray *ring) 
{
    resize_point_array_list(pal);
    pal->rings[pal->count++] = ring;
}

/*
 * Determine the appropriate polygon type by examining all rings
 */
DimensionType
determine_ring_type(PointArrayList *pal)
{
    bool has_z = false, 
         has_m = false;
    
    for (int ring_idx = 0; ring_idx < pal->count; ring_idx++)
    {
        DimensionType ring_type = determine_ptarray_type(pal->rings[ring_idx]);
        
        if (ring_type == Z)
            has_z = true;
        if (ring_type == M)
            has_m = true;
        if (ring_type == ZM || (has_z && has_m)) 
            return ZM;
    }
    
    if (has_m) return M;
    if (has_z) return Z;
    return XY;
}

/*
 * Transform all points in all rings of a polygon to conform to the specified type
 */
void
transform_polygon_points(PointArrayList *pal, DimensionType type)
{
    if (type == XY)
        return;
        
    for (int ring_idx = 0; ring_idx < pal->count; ring_idx++)
    {
        transform_points(pal->rings[ring_idx], type);
    }
}

/*
 * Converts a PointArrayList to a PostGIS-compatible POLYGON WKT representation
 */
char* 
rewrite_polygon_query(PointArrayList *pal) 
{
    StringInfoData output;
    DimensionType type;

    if (!pal || pal->count == 0) 
        return NULL;

    initStringInfo(&output);
    
    /* Determine type from all rings */
    type = determine_ring_type(pal);
    
    appendStringInfoString(&output, "POLYGON");
    
    if (type == M) 
        appendStringInfoString(&output, " M");

    appendStringInfoChar(&output, '(');
    
    /* Transform all points in all rings to conform to the determined type */
    transform_polygon_points(pal, type);

    for (int ring_idx = 0; ring_idx < pal->count; ring_idx++) 
    {
        PointArray *pa = pal->rings[ring_idx];
        
        appendStringInfoChar(&output, '(');
        
        for (int i = 0; i < pa->count; i++) 
        {
            POINT p = pa->points[i];
            format_tsql_point_coordinates(&output, p);

            if (i < pa->count - 1) 
                appendStringInfoString(&output, ", ");
        }
        
        appendStringInfoChar(&output, ')');
        
        if (ring_idx < pal->count - 1) 
            appendStringInfoString(&output, ", ");
            
        pfree(pa->points);
        pfree(pa);
    }

    appendStringInfoChar(&output, ')');
    
    pfree(pal->rings);
    pfree(pal);
    
    return output.data;
}

/*
 * Converts a PointArrayList to a T-SQL compatible POLYGON WKT representation
 */
char* 
rewrite_dim_polygon_query(PointArrayList *pal) 
{
    StringInfoData output;

    if (!pal || pal->count == 0) 
        return NULL;

    initStringInfo(&output);
    appendStringInfoString(&output, "POLYGON(");

    for (int ring_idx = 0; ring_idx < pal->count; ring_idx++) 
    {
        PointArray *pa = pal->rings[ring_idx];
        
        appendStringInfoChar(&output, '(');
        
        for (int i = 0; i < pa->count; i++) 
        {
            POINT p = pa->points[i];
            format_postgis_point_coordinates(&output, p);

            if (i < pa->count - 1) 
                appendStringInfoString(&output, ", ");
        }
        
        appendStringInfoChar(&output, ')');
        
        if (ring_idx < pal->count - 1) 
            appendStringInfoString(&output, ", ");
            
        pfree(pa->points);
        pfree(pa);
    }

    appendStringInfoChar(&output, ')');
    
    pfree(pal->rings);
    pfree(pal);
    
    return output.data;
}

char* 
rewrite_multipoint_wkt(PointArray *pa) 
{
    DimensionType type;
    StringInfoData output;

    if (!pa || pa->count == 0)
    {
        free_point_array(pa);
        return pstrdup("MULTIPOINT EMPTY");
    }

    initStringInfo(&output);
    
    type = determine_ptarray_type(pa);
    
    appendStringInfoString(&output, "MULTIPOINT");

    if (type == M) 
        appendStringInfoString(&output, " M");

    appendStringInfoChar(&output, '(');
    
    transform_points(pa, type);

    append_formatted_points(&output, pa, true, format_tsql_point_coordinates);

    appendStringInfoChar(&output, ')');

    free_point_array(pa);
    
    return output.data;
}


char* 
rewrite_dim_multipoint_wkt(PointArray *pa) 
{
    StringInfoData output;

    if (!pa || pa->count == 0)
    {
        free_point_array(pa);
        return pstrdup("MULTIPOINT EMPTY");
    }

    initStringInfo(&output);
    
    appendStringInfoString(&output, "MULTIPOINT(");

    append_formatted_points(&output, pa, true, format_postgis_point_coordinates);

    appendStringInfoChar(&output, ')');

    free_point_array(pa);
    
    return output.data;
}