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

/* This is copy of a struct from POSTGIS so that we could store and use the following values directly */
typedef struct
{
    uint32_t size; /* For PgSQL use only, use VAR* macros to manipulate. */
    uint8_t srid[3]; /* 24 bits of SRID */
    uint8_t gflags; /* HasZ, HasM, HasBBox, IsGeodetic */
    uint8_t data[1]; /* See gserialized.txt */
} GSERIALIZED;

typedef Datum (*LWGEOM_in_t)(PG_FUNCTION_ARGS);
static LWGEOM_in_t LWGEOM_in_p;

typedef Datum (*gserialized_set_srid_t)(PG_FUNCTION_ARGS);
static gserialized_set_srid_t gserialized_set_srid_p;

typedef Datum (*ST_FLIP_COORD_t)(PG_FUNCTION_ARGS);
static ST_FLIP_COORD_t ST_FLIP_COORD_p;

typedef Datum (*lwgeom_x_t)(PG_FUNCTION_ARGS);
static lwgeom_x_t lwgeom_x_p;

PG_FUNCTION_INFO_V1(LWGEOM_in);
PG_FUNCTION_INFO_V1(geography_in);

Datum
LWGEOM_in(PG_FUNCTION_ARGS)
{
    Datum geom_datum;
    GSERIALIZED *geom; /* Used to Store the bytes in the Format which is stored in PostGIS */

    /* Ensure LWGEOM_in_p is properly initialized before using it */
    if (LWGEOM_in_p == NULL) LWGEOM_in_p = (LWGEOM_in_t) load_external_function("$libdir/postgis-3", "LWGEOM_in", true, NULL);

    /* Call the LWGEOM_in function via the function pointer */
    geom_datum = LWGEOM_in_p(fcinfo);

    geom = (GSERIALIZED*)PG_DETOAST_DATUM(geom_datum);

    /* check if it is a 2-D point type */
    if(*((uint32_t*)geom->data) != 1) ereport(ERROR,
                                        (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                                        errmsg("Currently only Point type is supported")));
    else
    {
        if ( (geom->gflags & 0x01) || (geom->gflags & 0x02) || (geom->gflags & 0x03) )
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
    GSERIALIZED *geom; /* Used to Store the bytes in the Format which is stored in PostGIS */
    char *input_str = PG_GETARG_CSTRING(0);
    float8 lat;
    bool isBinary = false;

    if(input_str[0] == '0') isBinary = true;

    /* Ensure LWGEOM_in_p is properly initialized before using it */
    if (LWGEOM_in_p == NULL) LWGEOM_in_p = (LWGEOM_in_t) load_external_function("$libdir/postgis-3", "LWGEOM_in", true, NULL);

    /* Call the LWGEOM_in function via the function pointer */
    geom_datum = LWGEOM_in_p(fcinfo);

    geom = (GSERIALIZED*)PG_DETOAST_DATUM(geom_datum);

    if (gserialized_set_srid_p == NULL) gserialized_set_srid_p = (gserialized_set_srid_t) load_external_function("$libdir/postgis-3", "LWGEOM_set_srid", true, NULL);

    fcinfo->args[0].value = geom_datum;
    fcinfo->args[1].value = Int32GetDatum(4326);

    /* Setting deafault SRID for geography datatype = 4326 */
    geom_datum = gserialized_set_srid_p(fcinfo);

    /* check if it is a 2-D point type */
    if(*((uint32_t*)geom->data) != 1) ereport(ERROR,
                                        (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                                        errmsg("Currently only Point type is supported")));
    else
    {
        if ((geom->gflags & 0x01) || (geom->gflags & 0x02) || (geom->gflags & 0x03) )
            ereport(ERROR,
                    (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                    errmsg("Unsupported flags")));
        else
        {
            if (ST_FLIP_COORD_p == NULL) ST_FLIP_COORD_p = (ST_FLIP_COORD_t) load_external_function("$libdir/postgis-3", "ST_FlipCoordinates", true, NULL);
            if (lwgeom_x_p == NULL) lwgeom_x_p = (lwgeom_x_t) load_external_function("$libdir/postgis-3", "LWGEOM_x_point", true, NULL);

            fcinfo->args[0].value = geom_datum;
            /* Flipping the coordinates since Geography Datatype stores the point in Reverse Order i.e. (long, lat)  */
            if (!isBinary) geom_datum = ST_FLIP_COORD_p(fcinfo);

            fcinfo->args[0].value = geom_datum;
            lat = DatumGetFloat8(lwgeom_x_p(fcinfo));

            /* Checking if latitude falls in allowed range -> [-90.0, 90.0] */
            if(lat <= 90.0 && lat >= -90.0) PG_RETURN_DATUM(geom_datum);
            else
                ereport(ERROR,
                    (errcode(ERRCODE_DATA_EXCEPTION),
                    errmsg("Latitude values must be between -90 and 90 degrees")));
        }
    }

    PG_RETURN_DATUM(geom_datum);

}

#endif
