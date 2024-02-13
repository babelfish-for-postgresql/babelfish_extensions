/*-------------------------------------------------------------------------
 *
 * spatialtypes.c
 *    Functions for the type "geometry" and "geography".
 *
 *-------------------------------------------------------------------------
 */
#ifdef ENABLE_SPATIAL_TYPES

#include "postgres.h"
#include "fmgr.h"
#include "utils/geo_decls.h"
#include "utils/builtins.h"

static void load_functions();

/*
 * Macros for identifying Z and M flags
 */
#define FLAG_Z         1 << 0
#define FLAG_M         1 << 1

/* Copied from PostGIS */
typedef struct
{
    uint32_t size; /* For PgSQL use only, use VAR* macros to manipulate. */
    uint8_t srid[3]; /* 24 bits of SRID */
    uint8_t gflags; /* HasZ, HasM, HasBBox, IsGeodetic */
    uint8_t data[1]; /* See gserialized.txt */
} GSERIALIZED;

typedef Datum (*lwgeom_in_t)(PG_FUNCTION_ARGS);
static lwgeom_in_t lwgeom_in_p;

typedef Datum (*gserialized_set_srid_t)(PG_FUNCTION_ARGS);
static gserialized_set_srid_t gserialized_set_srid_p;

typedef Datum (*st_flip_coord_t)(PG_FUNCTION_ARGS);
static st_flip_coord_t st_flip_coord_p;

typedef Datum (*lwgeom_x_t)(PG_FUNCTION_ARGS);
static lwgeom_x_t lwgeom_x_p;

typedef Datum (*geometry_type_t)(PG_FUNCTION_ARGS);
static geometry_type_t geometry_type_p;

PG_FUNCTION_INFO_V1(geometry_in);
PG_FUNCTION_INFO_V1(geography_in);

/*
 * Module to load external PostGIS functions
 */
static void
load_functions()
{
    if (lwgeom_in_p == NULL)
        lwgeom_in_p = (lwgeom_in_t) load_external_function("$libdir/postgis-3", "LWGEOM_in", true, NULL);

    if (geometry_type_p == NULL)
        geometry_type_p = (geometry_type_t) load_external_function("$libdir/postgis-3", "geometry_geometrytype", true, NULL);

    if (gserialized_set_srid_p == NULL)
        gserialized_set_srid_p = (gserialized_set_srid_t) load_external_function("$libdir/postgis-3", "LWGEOM_set_srid", true, NULL);

    if (st_flip_coord_p == NULL)
        st_flip_coord_p = (st_flip_coord_t) load_external_function("$libdir/postgis-3", "ST_FlipCoordinates", true, NULL);
    
    if (lwgeom_x_p == NULL)
        lwgeom_x_p = (lwgeom_x_t) load_external_function("$libdir/postgis-3", "LWGEOM_x_point", true, NULL);
}

Datum
geometry_in(PG_FUNCTION_ARGS)
{
    Datum geom_datum;
    Datum geom_type;
    char *geometry_name;
    GSERIALIZED *geom; /* Used to Store the bytes in the Format which is stored in PostGIS */
    LOCAL_FCINFO(fcinfo_local, 1); /* Use local fcinfo so as to avoid overriding of original structure */

    load_functions();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    fcinfo_local->args[0].value = fcinfo->args[0].value;
    fcinfo_local->args[0].isnull = false;

    /* Call the LWGEOM_in function via the function pointer */
    geom_datum = lwgeom_in_p(fcinfo_local);

    geom = (GSERIALIZED*)PG_DETOAST_DATUM(geom_datum);

    fcinfo_local->args[0].value = geom_datum;
    geom_type = geometry_type_p(fcinfo_local);

    geometry_name = text_to_cstring(PG_DETOAST_DATUM(geom_type));
    /* check if it is a 2-D point type */
    if (strcmp(geometry_name, "ST_Point") != 0)
        ereport(ERROR,
            (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
            errmsg("%s is not supported", geometry_name)));
    else
    {
        if ((geom->gflags & FLAG_Z) || (geom->gflags & FLAG_M) || (geom->gflags & (FLAG_Z | FLAG_M)) )
        {
            ereport(ERROR,
                    (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                    errmsg("Unsupported flags")));
        }
        PG_RETURN_DATUM(geom_datum);
    }

    PG_RETURN_DATUM(geom_datum);

}

Datum
geography_in(PG_FUNCTION_ARGS)
{
    Datum geom_datum;
    Datum geom_type;
    char *geometry_name;
    GSERIALIZED *geom; /* Used to Store the bytes in the Format which is stored in PostGIS */
    char *input_str = PG_GETARG_CSTRING(0);
    float8 lat;
    bool isBinary = false;
    LOCAL_FCINFO(fcinfo_local, 3); /* Use local fcinfo so as to avoid overriding of original structure */
    
    if (input_str == NULL)
        PG_RETURN_NULL(); 

    if (input_str[0] == '0')
        isBinary = true;

    load_functions();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 3, PG_GET_COLLATION(), NULL, NULL);

    fcinfo_local->args[0].value = fcinfo->args[0].value;
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = fcinfo->args[1].value;
    fcinfo_local->args[1].isnull = false;
    fcinfo_local->args[2].value = fcinfo->args[2].value;
    fcinfo_local->args[2].isnull = false;

    /* Call the LWGEOM_in function via the function pointer */
    geom_datum = lwgeom_in_p(fcinfo_local);

    geom = (GSERIALIZED*)PG_DETOAST_DATUM(geom_datum);

    fcinfo_local->args[0].value = geom_datum;
    geom_type = geometry_type_p(fcinfo_local);

    fcinfo_local->args[0].value = geom_datum;
    fcinfo_local->args[1].value = Int32GetDatum(4326);

    /* Setting deafault SRID for geography datatype = 4326 */
    geom_datum = gserialized_set_srid_p(fcinfo_local);

    geometry_name = text_to_cstring(PG_DETOAST_DATUM(geom_type));
    /* check if it is a 2-D point type */
    if (strcmp(geometry_name, "ST_Point") != 0)
        ereport(ERROR,
            (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
            errmsg("%s is not supported", geometry_name)));
    else
    {
        if ((geom->gflags & FLAG_Z) || (geom->gflags & FLAG_M) || (geom->gflags & (FLAG_Z | FLAG_M)) )
            ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                errmsg("Unsupported flags")));
        else
        {
            fcinfo_local->args[0].value = geom_datum;
            /* Flipping the coordinates since Geography Datatype stores the point in Reverse Order i.e. (long, lat)  */
            if (!isBinary)
                geom_datum = st_flip_coord_p(fcinfo_local);

            fcinfo_local->args[0].value = geom_datum;
            lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));

            /* Checking if latitude falls in allowed range -> [-90.0, 90.0] */
            if(lat <= 90.0 && lat >= -90.0)
                PG_RETURN_DATUM(geom_datum);
            else
                ereport(ERROR,
                    (errcode(ERRCODE_DATA_EXCEPTION),
                    errmsg("Latitude values must be between -90 and 90 degrees")));
        }
    }

    PG_RETURN_DATUM(geom_datum);

}

#endif
