#include "geo_data.h"

#define FLOAT8_TO_CSTRING(x)         DatumGetCString(DirectFunctionCall1(float8out, Float8GetDatum(x)))
#define YYFREE                       pfree

#define POINTFLAG_Z                  (1 << 0)  
#define POINTFLAG_M                  (1 << 1)

#define FLAGS_SET_Z(flags, value)    ((value) ? ((flags) |= POINTFLAG_Z) : ((flags) &= ~POINTFLAG_Z))
#define FLAGS_SET_M(flags, value)    ((value) ? ((flags) |= POINTFLAG_M) : ((flags) &= ~POINTFLAG_M))

#define FLAGS_GET_Z(flags)           ((flags) & POINTFLAG_Z)
#define FLAGS_GET_M(flags)           ((flags) & POINTFLAG_M)

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
    
    /* Return the resulting string */
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
