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
#include "utils/array.h"
#include "utils/datum.h"
#include "catalog/pg_type.h"

static void load_functions();

/*
 * Macros for identifying Z and M flags
 */
#define FLAG_Z         1 << 0
#define FLAG_M         1 << 1
#define MAX_DIMENSION_FLAG 4

/* Copied from PostGIS */
typedef struct
{
    uint32_t size; /* For PgSQL use only, use VAR* macros to manipulate. */
    uint8_t srid[3]; /* 24 bits of SRID */
    uint8_t gflags; /* HasZ, HasM, HasBBox, IsGeodetic */
    uint8_t data[1]; /* See gserialized.txt */
} GSERIALIZED;

/* Define header values for different dimensions */
static const uint8_t DIMENSION_HEADERS[] = {
    0x20,   /* Empty */
    0x20,   /* XY  */
    0xA0,   /* XYZ */
    0x60,   /* XYM */
    0xE0    /* XYZM */
};

/* Array of valid Spatial Reference System Identifiers (SRIDs) for Geography datatype */
static const int32 geography_valid_srids[] = {
    4120, 4121, 4122, 4123, 4124, 4127, 4128, 4129, 4130, 4131, 4132, 4133, 4134, 4135, 4136, 4137, 4138, 4139, 4141, 
    4142, 4143, 4144, 4145, 4146, 4147, 4148, 4149, 4150, 4151, 4152, 4153, 4154, 4155, 4156, 4157, 4158, 4159, 4160, 
    4161, 4162, 4163, 4164, 4165, 4166, 4167, 4168, 4169, 4170, 4171, 4173, 4174, 4175, 4176, 4178, 4179, 4180, 4181, 
    4182, 4183, 4184, 4188, 4189, 4190, 4191, 4192, 4193, 4194, 4195, 4196, 4197, 4198, 4199, 4200, 4201, 4202, 4203, 
    4204, 4205, 4206, 4207, 4208, 4209, 4210, 4211, 4212, 4213, 4214, 4215, 4216, 4218, 4219, 4220, 4221, 4222, 4223, 
    4224, 4225, 4227, 4229, 4230, 4231, 4232, 4236, 4237, 4238, 4239, 4240, 4241, 4242, 4243, 4244, 4245, 4246, 4247, 
    4248, 4249, 4250, 4251, 4252, 4253, 4254, 4255, 4256, 4257, 4258, 4259, 4261, 4262, 4263, 4265, 4266, 4267, 4268, 
    4269, 4270, 4271, 4272, 4273, 4274, 4275, 4276, 4277, 4278, 4279, 4280, 4281, 4282, 4283, 4284, 4285, 4286, 4288, 
    4289, 4292, 4293, 4295, 4297, 4298, 4299, 4300, 4301, 4302, 4303, 4304, 4306, 4307, 4308, 4309, 4310, 4311, 4312, 
    4313, 4314, 4315, 4316, 4317, 4318, 4319, 4322, 4324, 4326, 4600, 4601, 4602, 4603, 4604, 4605, 4606, 4607, 4608, 
    4609, 4610, 4611, 4612, 4613, 4614, 4615, 4616, 4617, 4618, 4619, 4620, 4621, 4622, 4623, 4624, 4625, 4626, 4627, 
    4628, 4629, 4630, 4632, 4633, 4636, 4637, 4638, 4639, 4640, 4641, 4642, 4643, 4644, 4646, 4657, 4658, 4659, 4660, 
    4661, 4662, 4663, 4664, 4665, 4666, 4667, 4668, 4669, 4670, 4671, 4672, 4673, 4674, 4675, 4676, 4677, 4678, 4679, 
    4680, 4682, 4683, 4684, 4686, 4687, 4688, 4689, 4690, 4691, 4692, 4693, 4694, 4695, 4696, 4697, 4698, 4699, 4700, 
    4701, 4702, 4703, 4704, 4705, 4706, 4707, 4708, 4709, 4710, 4711, 4712, 4713, 4714, 4715, 4716, 4717, 4718, 4719, 
    4720, 4721, 4722, 4723, 4724, 4725, 4726, 4727, 4728, 4729, 4730, 4732, 4733, 4734, 4735, 4736, 4737, 4738, 4739, 
    4740, 4741, 4742, 4743, 4744, 4745, 4746, 4747, 4748, 4749, 4750, 4751, 4752, 4753, 4754, 4755, 4756, 4757, 4758, 
    4801, 4802, 4803, 4804, 4805, 4806, 4807, 4808, 4809, 4810, 4811, 4813, 4814, 4815, 4816, 4817, 4818, 4820, 4821, 
    4895, 4898, 4900, 4901, 4902, 4903, 4904, 4907, 4909, 4921, 4923, 4925, 4927, 4929, 4931, 4933, 4935, 4937, 4939, 
    4941, 4943, 4945, 4947, 4949, 4951, 4953, 4955, 4957, 4959, 4961, 4963, 4965, 4967, 4971, 4973, 4975, 4977, 4979, 
    4981, 4983, 4985, 4987, 4989, 4991, 4993, 4995, 4997, 4999, 7843, 7844, 104001
};
/* Number of valid SRIDs */
static const int num_valid_srids_geography = sizeof(geography_valid_srids) / sizeof(geography_valid_srids[0]);

/*
 * Updates FunctionCallInfoBaseData with new arguments efficiently.
 * 
 * @param fcinfo - Function call info structure to update
 * @param nargs  - Number of arguments to set
 * @param ...    - Variable number of Datum arguments
 */
static inline void UpdateFunctionCallInfo(
    FunctionCallInfoBaseData *fcinfo,
    int nargs,
    ...)
{
    va_list args;
    int i;

    fcinfo->nargs = nargs;
    
    va_start(args, nargs);
    for (i = 0; i < nargs; i++) {
        fcinfo->args[i].value = va_arg(args, Datum);
        fcinfo->args[i].isnull = false;
    }
    va_end(args);
}


/* Function to rewrite geospatial data */
text* geo_wkt_rewrite(text *input_text);

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

typedef Datum (*lwgeom_from_text_t)(PG_FUNCTION_ARGS);
static lwgeom_from_text_t lwgeom_from_text_p;

typedef Datum (*lwgeom_from_bytea_t)(PG_FUNCTION_ARGS);
static lwgeom_from_bytea_t lwgeom_from_bytea_p;

typedef Datum (*lwgeom_to_bytea_t)(PG_FUNCTION_ARGS);
static lwgeom_to_bytea_t lwgeom_to_bytea_p;

typedef Datum (*st_flipcoordinates_t)(PG_FUNCTION_ARGS);
static st_flipcoordinates_t st_flipcoordinates_p;

typedef Datum (*st_point_t)(PG_FUNCTION_ARGS);
static st_point_t st_point_p;

typedef Datum (*st_isempty_t)(PG_FUNCTION_ARGS);
static st_isempty_t st_isempty_p;

typedef Datum (*lwgeom_force_2d_t)(PG_FUNCTION_ARGS);
static lwgeom_force_2d_t lwgeom_force_2d_p;

typedef Datum (*lwgeom_asBinary_t)(PG_FUNCTION_ARGS);
static lwgeom_asBinary_t lwgeom_asBinary_p;

typedef Datum (*lwgeom_astext_t)(PG_FUNCTION_ARGS);
static lwgeom_astext_t lwgeom_astext_p;

PG_FUNCTION_INFO_V1(geometry_in);
PG_FUNCTION_INFO_V1(geography_in);
PG_FUNCTION_INFO_V1(get_geometry_from_text);
PG_FUNCTION_INFO_V1(charTogeom);
PG_FUNCTION_INFO_V1(geometry_from_bytea);
PG_FUNCTION_INFO_V1(bytea_from_geometry);
PG_FUNCTION_INFO_V1(geography_from_bytea);
PG_FUNCTION_INFO_V1(bytea_from_geography);
PG_FUNCTION_INFO_V1(get_geography_from_text);
PG_FUNCTION_INFO_V1(charTogeog);
PG_FUNCTION_INFO_V1(geography_point);
PG_FUNCTION_INFO_V1(st_as_binary_geometry);
PG_FUNCTION_INFO_V1(st_as_binary_geography);
PG_FUNCTION_INFO_V1(st_as_text);
PG_FUNCTION_INFO_V1(geometry_astext);
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

    if (lwgeom_from_text_p == NULL)
        lwgeom_from_text_p = (lwgeom_from_text_t) load_external_function("$libdir/postgis-3", "LWGEOM_from_text", true, NULL);

    if (lwgeom_from_bytea_p == NULL)
        lwgeom_from_bytea_p = (lwgeom_from_bytea_t) load_external_function("$libdir/postgis-3", "LWGEOM_from_bytea", true, NULL);

    if (lwgeom_to_bytea_p == NULL)
        lwgeom_to_bytea_p = (lwgeom_to_bytea_t) load_external_function("$libdir/postgis-3", "LWGEOM_to_bytea", true, NULL);

    if (st_flipcoordinates_p == NULL)
        st_flipcoordinates_p = (st_flipcoordinates_t) load_external_function("$libdir/postgis-3", "ST_FlipCoordinates", true, NULL);

    if (st_point_p == NULL)
        st_point_p = (st_point_t) load_external_function("$libdir/postgis-3", "ST_Point", true, NULL);

    if (st_isempty_p == NULL)
        st_isempty_p = (st_isempty_t) load_external_function("$libdir/postgis-3", "LWGEOM_isempty", true, NULL);

    if (lwgeom_force_2d_p == NULL)
        lwgeom_force_2d_p = (lwgeom_force_2d_t) load_external_function("$libdir/postgis-3", "LWGEOM_force_2d", true, NULL);

    if (lwgeom_asBinary_p == NULL)
        lwgeom_asBinary_p = (lwgeom_asBinary_t) load_external_function("$libdir/postgis-3", "LWGEOM_asBinary", true, NULL);
    
    if (lwgeom_astext_p == NULL)
        lwgeom_astext_p = (lwgeom_astext_t) load_external_function("$libdir/postgis-3", "LWGEOM_asText", true, NULL);
}

/*
 * Gets geometry type name from a geometry datum.
 * Returns allocated string that must be pfree'd by caller.
 */
static inline char *
GetGeometryTypeName(FunctionCallInfoBaseData *fcinfo, Datum geom_datum)
{
    Datum geom_type;
    
    UpdateFunctionCallInfo(fcinfo, 1, geom_datum);
    geom_type = geometry_type_p(fcinfo);
    return text_to_cstring(DatumGetTextP(geom_type));
}


Datum
geometry_in(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;               /* Geometry object */
    text    *rewritten_wkt_text;       /* Rewritten WKT as text */
    char    *rewritten_cstring,        /* Rewritten WKT as cstring */
            *geometry_name;            /* String representation of geometry type */
    bool     is_binary_format = false; /* Flag for binary format detection */
    LOCAL_FCINFO(fcinfo_local, 2);

    load_functions();

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    /* Check for binary format */
    if (PG_GETARG_CSTRING(0)[0] == '0')
        is_binary_format = true;

    if(!is_binary_format)
    {
        /* Direct call to C function with converted input */
        rewritten_wkt_text = geo_wkt_rewrite(DatumGetTextP(CStringGetTextDatum(PG_GETARG_CSTRING(0))));

        /* Convert rewritten WKT from text to cstring */
        rewritten_cstring = text_to_cstring(rewritten_wkt_text);

        /* Prepare for LWGEOM_in function call */
        UpdateFunctionCallInfo(fcinfo_local, 1, CStringGetDatum(rewritten_cstring));

    }
    else 
    {
        UpdateFunctionCallInfo(fcinfo_local, 1, fcinfo->args[0].value);
    }

    /* Call the LWGEOM_in function via the function pointer */
    geom_datum = lwgeom_in_p(fcinfo_local);

    /* Get geometry type */
    geometry_name = GetGeometryTypeName(fcinfo_local, geom_datum);
    
    /* check if it is a 2-D point type */
    if (strcmp(geometry_name, "ST_Point") != 0)
        ereport(ERROR,
            (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
             errmsg("%s is not supported", geometry_name)));

    PG_RETURN_DATUM(geom_datum);
}

Datum
geography_in(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;               /* Geometry object */
    text    *rewritten_wkt_text;       /* Rewritten WKT as text */
    char    *rewritten_cstring,        /* Rewritten WKT as cstring */
            *geometry_name;            /* String representation of geometry type */
    float8   lat;                      /* Latitude value */
    bool     is_binary_format = false; /* Flag for binary format detection */
    LOCAL_FCINFO(fcinfo_local, 3);

    load_functions();

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 3, PG_GET_COLLATION(), NULL, NULL);

    /* Check for NULL input */
    if (PG_GETARG_CSTRING(0) == NULL)
        PG_RETURN_NULL();

    /* Check for binary format */
    if (PG_GETARG_CSTRING(0)[0] == '0')
        is_binary_format = true;

    /* Process input based on format */
    if(is_binary_format)
    {
        /* Handle binary format */
        UpdateFunctionCallInfo(fcinfo_local, 3,
                             fcinfo->args[0].value,
                             fcinfo->args[1].value,
                             fcinfo->args[2].value);
        
        /* Get geometry */
        geom_datum = lwgeom_in_p(fcinfo_local);
    }
    else
    {
        /* Handle text format */
        rewritten_wkt_text = geo_wkt_rewrite(DatumGetTextP(CStringGetTextDatum(PG_GETARG_CSTRING(0))));
        rewritten_cstring = text_to_cstring(rewritten_wkt_text);

        /* Convert WKT to geometry */
        UpdateFunctionCallInfo(fcinfo_local, 3,
                             CStringGetDatum(rewritten_cstring),
                             Int32GetDatum(0),
                             Int32GetDatum(-1));
        geom_datum = lwgeom_in_p(fcinfo_local);

        /* Set SRID to 4326 for geography datatype */
        UpdateFunctionCallInfo(fcinfo_local, 2,
                             geom_datum,
                             Int32GetDatum(4326));
        geom_datum = gserialized_set_srid_p(fcinfo_local);

        /* Flip coordinates for geography storage (long, lat) */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
        geom_datum = st_flip_coord_p(fcinfo_local);
    }

    /* Get and validate geometry type */
    geometry_name = GetGeometryTypeName(fcinfo_local, geom_datum);

    if (strcmp(geometry_name, "ST_Point") != 0)
    {
        ereport(ERROR,
            (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
             errmsg("%s is not supported", geometry_name)));
    }

    /* Get and validate latitude */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));

    if(lat <= 90.0 && lat >= -90.0)
    {
        PG_RETURN_DATUM(geom_datum);
    }
    else 
    {
    ereport(ERROR,
        (errcode(ERRCODE_DATA_EXCEPTION),
         errmsg("Latitude values must be between -90 and 90 degrees")));
    }

    /* This point should never be reached, but to satisfy the compiler: */
    PG_RETURN_NULL();
}

/*
 * This function takes a WKT representation and SRID as input, validates the SRID,
 * rewrites the WKT, and converts it to a geometry object.
 */
Datum
get_geometry_from_text(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;             /* Final geometry object */
    int32    srid;                   /* Spatial Reference ID */
    char    *geom_type;              /* String representation of geometry type */
    text    *rewritten_wkt_text;     /* Rewritten WKT as text */
    LOCAL_FCINFO(fcinfo_local, 2);   /* Local function call info with 2 arguments */
    
    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);

    /* Load required PostGIS functions for geometry processing */
    load_functions();

    /* 
     * Extract and validate SRID value
     * SRID must be between 0 and 999999 for geometry types
     */
    srid = PG_GETARG_INT32(1);

    if (srid < 0 || srid > 999999) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("SRID value should be between 0 and 999999")));
    }

    /* Get input WKT text and rewrite */
    rewritten_wkt_text = geo_wkt_rewrite(PG_GETARG_TEXT_PP(0));

    /* Convert WKT to geometry with SRID */
    UpdateFunctionCallInfo(fcinfo_local, 2,
                         PointerGetDatum(rewritten_wkt_text),
                         Int32GetDatum(srid));
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Determine the type of geometry created */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);

    /* 
     * Return the geometry object if it's a Point type
     * Otherwise return NULL (only ST_Point is currently supported)
     */
    if (strcmp(geom_type, "ST_Point") == 0)
        PG_RETURN_DATUM(geom_datum);

    PG_RETURN_NULL();
}

/*
 * This function takes a WKT representation and SRID as input, validates the SRID,
 * rewrites the WKT, and converts it to a geography object.
 */
Datum
get_geography_from_text(PG_FUNCTION_ARGS)
{
    Datum       geom_datum,         /* Geometry object */
                lat_datum,          /* Latitude value as datum */
                flipped_geom_datum; /* Geometry with flipped coordinates */
    text       *rewritten_wkt_text; /* Processed WKT text */          
    char       *geom_type;          /* String representation of geometry type */
    float8      lat;                /* Latitude value */
    bool        srid_valid = false; /* Flag for SRID validation */
    int32       srid;               /* Input SRID value */
    LOCAL_FCINFO(fcinfo_local, 2);  /* Local function call info with 2 arguments */

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);

    /* Extract input parameters from function arguments */
    srid = PG_GETARG_INT32(1);

    /* Load required functions for geometry processing */
    load_functions();

    /* Validate input SRID against list of valid SRIDs */
    for (int i = 0; i < num_valid_srids_geography; i++) 
    {    
        if (geography_valid_srids[i] == srid)
        {
            srid_valid = true;
            break;
        }
    }

    /* Raise error if SRID is not in valid list */
    if (!srid_valid) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid SRID")));
    }

    /* Process and rewrite the WKT string */
    rewritten_wkt_text = geo_wkt_rewrite(PG_GETARG_TEXT_PP(0));

    /* Convert WKT to geometry with SRID */
    UpdateFunctionCallInfo(fcinfo_local, 2,
                         PointerGetDatum(rewritten_wkt_text),
                         Int32GetDatum(srid));
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Determine geometry type */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);

    if (strcmp(geom_type, "ST_Point") == 0) 
    {
        /* Flip coordinates to check latitude */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
        flipped_geom_datum = st_flipcoordinates_p(fcinfo_local);

        /* Extract and validate latitude */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom_datum);
        lat_datum = lwgeom_x_p(fcinfo_local);
        lat = DatumGetFloat8(lat_datum);

        /* Validate latitude is within -90 to 90 degrees or NaN */
        if ((lat >= -90.0 && lat <= 90.0) || isnan(lat)) 
        {
            PG_RETURN_DATUM(flipped_geom_datum);
        } 
        
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Latitude values must be between -90 and 90 degrees")));
    }

    /* Code path for non-Point geometries (should never be reached) */
    PG_RETURN_NULL();
}

/* This function creates a geography point (only 2D) */
Datum
geography_point(PG_FUNCTION_ARGS)
{
    Datum    result;              /* Final geography point object */
    float8   lat,                /* Latitude value */
             lon;                /* Longitude value */
    int32    srid;              /* Spatial Reference ID */
    bool     srid_valid = false; /* Flag for SRID validation */
    int      i;                 /* Loop counter */
    LOCAL_FCINFO(fcinfo_local, 3); /* Local function call info with 3 arguments */

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 3, InvalidOid, NULL, NULL);

    /* Extract input parameters from function arguments */
    lat = PG_GETARG_FLOAT8(0);
    lon = PG_GETARG_FLOAT8(1);
    srid = PG_GETARG_INT32(2);

    /* Load required functions for geometry processing */
    load_functions();

    /* Validate input SRID against list of valid SRIDs */
    for (i = 0; i < num_valid_srids_geography; i++) 
    {
        if (geography_valid_srids[i] == srid) 
        {
            srid_valid = true;
            break;
        }
    }

    /* Validate SRID */
    if (!srid_valid)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid SRID")));
    }

    /* Validate latitude range */
    if (lat < -90.0 || lat > 90.0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Latitude values must be between -90 and 90 degrees")));
    }

    /* Create the point using helper function */
    UpdateFunctionCallInfo(fcinfo_local, 3,
                         Float8GetDatum(lat),
                         Float8GetDatum(lon),
                         Int32GetDatum(srid));
    result = st_point_p(fcinfo_local);

    PG_RETURN_DATUM(result);
}

/* This function converts WKT (Well-Known Text) input to a geometry object. */
Datum
charTogeom(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;           /* Geometry object */
    text    *rewritten_wkt_text;   /* Processed WKT text */
    char    *geom_type;            /* String representation of geometry type */
    LOCAL_FCINFO(fcinfo_local, 2); /* Local function call info with 2 arguments */
    
    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);

    /* Load required functions for geometry processing */
    load_functions();

    /* Get input text and rewrite WKT */
    rewritten_wkt_text = geo_wkt_rewrite(PG_GETARG_TEXT_PP(0));

    /* 
     * Convert rewritten WKT to geometry
     * Uses SRID 0 (undefined/unknown spatial reference system)
     */
    UpdateFunctionCallInfo(fcinfo_local, 2,
                         PointerGetDatum(rewritten_wkt_text),
                         Int32GetDatum(0));
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Determine the type of geometry created */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);

    /* Return geometry if it's a Point type */
    if (strcmp(geom_type, "ST_Point") == 0) 
    {
        PG_RETURN_DATUM(geom_datum);
    }
    else 
    {
    /* 
     * Raise error for unsupported geometry types
     * Currently only Point geometries are supported
     */
    ereport(ERROR,
            (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("%s is not supported", geom_type)));
    }

    /* Control should never reach this point */
    PG_RETURN_NULL();
}

/* This function converts WKT (Well-Known Text) input to a geography object. */
Datum
charTogeog(PG_FUNCTION_ARGS)
{
    Datum   geom_datum,            /* Geometry object */
            flipped_geom,          /* Geometry with flipped coordinates */
            is_empty_datum,        /* Empty status as datum */
            lat_datum;             /* Latitude value as datum */
    text   *rewritten_wkt_text;    /* Processed WKT text */
    char   *geom_type;             /* String representation of geometry type */
    bool    is_empty;              /* Flag indicating if geometry is empty */
    float8  lat;                   /* Latitude value */
    LOCAL_FCINFO(fcinfo_local, 2); /* Local function call info with 2 arguments */

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);

    /* Load required functions for geometry processing */
    load_functions();

    /* Get and process input WKT */
    rewritten_wkt_text = geo_wkt_rewrite(PG_GETARG_TEXT_PP(0));

    /* Convert rewritten WKT to geometry with SRID 4326 */
    UpdateFunctionCallInfo(fcinfo_local, 2,
                         PointerGetDatum(rewritten_wkt_text),
                         Int32GetDatum(4326));
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Get geometry type */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);

    /* Check if geometry is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    is_empty_datum = st_isempty_p(fcinfo_local);
    is_empty = DatumGetBool(is_empty_datum);

    if (strcmp(geom_type, "ST_Point") == 0) 
    {
        if (is_empty) 
        {
            /* Empty points are valid geography objects */
            PG_RETURN_DATUM(geom_datum);
        }
        
        /* Process non-empty points */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
        flipped_geom = st_flipcoordinates_p(fcinfo_local);

        /* Get and validate latitude */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        lat_datum = lwgeom_x_p(fcinfo_local);
        lat = DatumGetFloat8(lat_datum);
        
        if (lat >= -90.0 && lat <= 90.0) 
        {
            /* Valid latitude, return the geography object */
            PG_RETURN_DATUM(geom_datum);
        }
        else
        {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Latitude values must be between -90 and 90 degrees")));
        }
    }
    else 
    {
    /* Raise error for unsupported geometry types */
    ereport(ERROR,
            (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("%s is not supported", geom_type)));
    }

    /* Control should never reach this point */
    PG_RETURN_NULL();
}

/* This function converts a binary (bytea) representation to a PostGIS geometry object. */
Datum
geometry_from_bytea(PG_FUNCTION_ARGS)
{
    Datum   geometry_result;      /* Final geometry object */
    bytea  *input,                /* Input binary data */
           *result;               /* Processed binary data */
    uint8  *input_data,           /* Raw input data pointer */
           *result_data,          /* Result data pointer */
            dimension_flag = 0,   /* Dimension type flag */
            empty_geom[8] = "\x00\x00\x00\x00\x00\x00\xf8\x7f",
            input_coord[8],
            new_header[5] = "\x01\x01\x00\x00\x20";
    int     input_len,            /* Length of input data */
            isNaN = 0,            /* Flag for NaN detection */
            byte_position = 6;
    int32_t srid;                 /* Spatial Reference ID */
    uint16_t geom_type;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    /* Load required functions */
    load_functions();

    /* Extract input binary data */
    input = PG_GETARG_BYTEA_PP(0);
    input_data = (uint8 *)VARDATA_ANY(input);
    input_len = VARSIZE_ANY_EXHDR(input);

    /* Validate minimum input length (header + basic geometry data) */
    if (input_len < 22) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid Geometry")));
    }

    /* Extract SRID from first 4 bytes (little-endian) */
    srid = (input_data[3] << 24) | (input_data[2] << 16) | 
           (input_data[1] << 8) | input_data[0];
    
    while (byte_position < input_len)
    {
        memcpy(input_coord, input_data + byte_position, 8);
        if (memcmp(input_coord, empty_geom, 8) == 0)
        {
            isNaN = 1;
            break;
        }
        byte_position += 8;
    }

    /* Extract and validate geometry type */
    geom_type = (input_data[4] << 8) | input_data[5];

    /* Set dimension flag based on geometry type */
    switch (geom_type) {
        case 0x0104:
            dimension_flag = 0;
            break;
        case 0x010C:
            dimension_flag = 1;
            break;
        case 0x010D:
            dimension_flag = 2;
            break;
        case 0x010E:
            dimension_flag = 3;
            break;
        case 0x010F:
            dimension_flag = 4;
            break;
        default:
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Unsupported geometry type")));
    }

    /* Process geometry if SRID is valid and no NaN coordinates found */
    if (srid >= 0 && srid <= 999999 && isNaN == 0) 
    {
        if (dimension_flag == 0) {
            /* Handle empty geometry */
            result = (bytea *) palloc(VARHDRSZ + 25);
            SET_VARSIZE(result, VARHDRSZ + 25);
            result_data = (uint8 *)VARDATA(result);

            /* Construct new geometry with updated header */
            memcpy(result_data, new_header, 5);
            memcpy(result_data + 5, input_data, 4);
            memcpy(result_data + 9, empty_geom, 8);
            memcpy(result_data + 17, empty_geom, 8);
        } else {
            /* Handle non-empty geometry with dimensions */
            if (dimension_flag <= MAX_DIMENSION_FLAG) 
                new_header[4] = DIMENSION_HEADERS[dimension_flag];

            /* Allocate and construct result */
            result = (bytea *) palloc(VARHDRSZ + input_len - 2 + 5);
            SET_VARSIZE(result, VARHDRSZ + input_len - 2 + 5);
            result_data = (uint8 *)VARDATA(result);

            memcpy(result_data, new_header, 5);
            memcpy(result_data + 5, input_data, 4);
            memcpy(result_data + 9, input_data + 6, input_len - 6);
        }
    }
    else 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geometry.")));
    }

    /* Convert processed binary data to geometry object */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geometry_result = lwgeom_from_bytea_p(fcinfo_local);

    return geometry_result;
}

/* This function converts a binary (bytea) representation to a PostGIS geography object. */
Datum
geography_from_bytea(PG_FUNCTION_ARGS)
{
    Datum    geography_result;    /* Final geography object */
    bytea  *input,                /* Input binary data */
           *result;               /* Processed binary data */
    uint8  *input_data,           /* Raw input data pointer */
           *result_data,          /* Result data pointer */
            dimension_flag = 0,   /* Dimension type flag */
            empty_geom[8] = "\x00\x00\x00\x00\x00\x00\xf8\x7f",
            input_coord[8],
            new_header[5] = "\x01\x01\x00\x00\x20";
    int     input_len,            /* Length of input data */
            isNaN = 0,            /* Flag for NaN detection */
            byte_position = 6;
    int32_t srid;                 /* Spatial Reference ID */
    bool    srid_valid = false;   /* Flag for SRID validation */
    double  lat;                  /* Latitude value */
    uint64_t lat_bits;            /* Binary representation of latitude */ 
    uint16_t geom_type;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    /* Load required PostGIS functions */
    load_functions();

    /* Extract and validate input binary data */
    input = PG_GETARG_BYTEA_PP(0);
    input_data = (uint8 *)VARDATA_ANY(input);
    input_len = VARSIZE_ANY_EXHDR(input);

    if (input_len < 22) {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid Geography")));
    }

    /* Extract SRID (little-endian) */
    srid = (input_data[3] << 24) | (input_data[2] << 16) | 
           (input_data[1] << 8) | input_data[0];

    /* Extract and convert latitude */
    memcpy(&lat_bits, input_data + 6, sizeof(uint64_t));
    lat_bits = le64toh(lat_bits);
    memcpy(&lat, &lat_bits, sizeof(double));

    while (byte_position < input_len)
    {
        memcpy(input_coord, input_data + byte_position, 8);
        if (memcmp(input_coord, empty_geom, 8) == 0)
        {
            isNaN = 1;
            break;
        }
        byte_position += 8;
    }

    geom_type = (input_data[4] << 8) | input_data[5];

    /* Set dimension flag based on geometry type */
    switch (geom_type) {
        case 0x0104:
            dimension_flag = 0;
            break;
        case 0x010C:
            dimension_flag = 1;
            break;
        case 0x010D:
            dimension_flag = 2;
            break;
        case 0x010E:
            dimension_flag = 3;
            break;
        case 0x010F:
            dimension_flag = 4;
            break;
        default:
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Unsupported geography type")));
    }

    /* Validate SRID against allowed values */
    for (int i = 0; i < num_valid_srids_geography; i++) {
        if (geography_valid_srids[i] == srid) {
            srid_valid = true;
            break;
        }
    }

    /* Process geography if SRID is valid and coordinates are valid */
    if (srid_valid && !isNaN && lat >= -90.0 && lat <= 90.0) {
        if (dimension_flag == 0) {
            /* Handle empty geography */
            result = (bytea *) palloc(VARHDRSZ + 25);
            SET_VARSIZE(result, VARHDRSZ + 25);
            result_data = (uint8 *)VARDATA(result);

            /* Construct new geography with updated header */
            memcpy(result_data, new_header, 5);
            memcpy(result_data + 5, input_data, 4);
            memcpy(result_data + 9, empty_geom, 8);
            memcpy(result_data + 17, empty_geom, 8);
        } else {
            /* Handle non-empty geography with dimensions */
            if (dimension_flag <= MAX_DIMENSION_FLAG) 
                new_header[4] = DIMENSION_HEADERS[dimension_flag];

            /* Allocate and construct result */
            result = (bytea *) palloc(VARHDRSZ + input_len - 2 + 5);
            SET_VARSIZE(result, VARHDRSZ + input_len - 2 + 5);
            result_data = (uint8 *)VARDATA(result);

            memcpy(result_data, new_header, 5);
            memcpy(result_data + 5, input_data, 4);
            memcpy(result_data + 9, input_data + 6, input_len - 6);
        }
    } 
    else 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geography.")));
    }

    /* Convert to geography object */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geography_result = lwgeom_from_bytea_p(fcinfo_local);

    return geography_result;
}

/* This function converts a geometry object to its binary (bytea) representation. */
Datum
bytea_from_geometry(PG_FUNCTION_ARGS)
{
    Datum   geom_datum;           /* Input geometry object */
    bytea   *byte,                /* Original binary data */
            *result;              /* Processed binary data */
    uint8   *byte_data,           /* Original data pointer */
            srid_flag,            /* SRID and dimension flags */
            *result_data,         /* Result data pointer */
            point_type;           /* Point dimension type */
    int     byte_len,             /* Length of input data */
            srid_size,            /* Size of SRID data (4 bytes) */
            coord_size;           /* Size of coordinate data */
    bool    has_srid,             /* Flag indicating SRID presence */
            is_empty = false;     /* Flag indicating empty geometry */
    /* Coordinate data for empty points */
    uint8    coord[] = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0x01
    };
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    /* Load required PostGIS functions */
    load_functions();

    /* Get the input geometry object */
    geom_datum = PG_GETARG_DATUM(0);

    /* Check if the geometry is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    is_empty = DatumGetBool(st_isempty_p(fcinfo_local));

    /* Convert geometry to binary format */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    byte = DatumGetByteaPP(lwgeom_to_bytea_p(fcinfo_local));

    /* Extract binary data and length */
    byte_data = (uint8 *)VARDATA_ANY(byte);
    byte_len = VARSIZE_ANY_EXHDR(byte);

    /* Validate if input is a point geometry */
    if (byte_len >= 5 && byte_data[1] == 0x01 && 
        byte_data[2] == 0x00 && byte_data[3] == 0x00) 
    {
        /* Extract SRID flag and check for SRID presence */
        srid_flag = byte_data[4];
        has_srid = srid_flag & 0x20;
        srid_size = 4;
   
        /* Determine point type and coordinate size based on dimension flags */
        switch (srid_flag & 0xC0) 
        {
            case 0x00:
                if (is_empty) 
                {
                    point_type = 0x04;
                    coord_size = 21;
                }
                else 
                {
                    /* XY coordinates */
                    point_type = 0x0c;
                    coord_size = 16;
                }
                break;
        
            case 0x80:
                /* XYZ coordinates */
                point_type = 0x0d;
                coord_size = 24;
                break;
        
            case 0xC0:
                /* XYZM coordinates */
                point_type = 0x0f;
                coord_size = 32;
                break;
        
            case 0x40:
                /* XYM coordinates */
                point_type = 0x0e;
                coord_size = 24;
                break;
        
            default:
                /* Return original data for unsupported types */
                PG_RETURN_BYTEA_P(byte);
        }

        /* Allocate memory for result */
        result = (bytea *) palloc(6 + srid_size + coord_size);
        SET_VARSIZE(result, 6 + srid_size + coord_size);
        result_data = (uint8 *)VARDATA(result);
        
        /* Handle SRID data */
        if (has_srid) 
        {
            memcpy(result_data, byte_data + 5, 4);
        } 
        else 
        {
            memset(result_data, 0, 4);
        }

        /* Set point type in header */
        result_data[4] = 0x01;
        result_data[5] = point_type;

        /* Copy coordinate data */
        if (is_empty) 
        {
            memcpy(result_data + 6, coord, coord_size);
        } 
        else 
        {
            memcpy(result_data + 6, byte_data + (has_srid ? 9 : 5), coord_size);
        }
        
        PG_RETURN_BYTEA_P(result);
    }

    /* Return original data if not a point geometry */
    PG_RETURN_BYTEA_P(byte);
}

/* This function converts a PostGIS geography object to its binary (bytea) representation. */
Datum
bytea_from_geography(PG_FUNCTION_ARGS)
{
    Datum   geom_datum;          /* Input geography object */
    bytea   *byte,               /* Original binary data */
            *result;             /* Processed binary data */
    uint8   *byte_data,          /* Original data pointer */
            srid_flag,           /* SRID and dimension flags */
            *result_data,        /* Result data pointer */
            point_type;          /* Point dimension type */
    int     byte_len,            /* Length of input data */
            srid_size,           /* Size of SRID data (4 bytes) */
            coord_size;          /* Size of coordinate data */
    bool    is_empty = false;    /* Flag indicating empty geometry */
    /* Coordinate data for empty points */
    uint8    coord[] = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0x01
    };
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    /* Load required functions */
    load_functions();

    /* Get the input geography object */
    geom_datum = PG_GETARG_DATUM(0);

    /* Check if the geometry is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    is_empty = DatumGetBool(st_isempty_p(fcinfo_local));

    /* Convert geography to binary format */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    byte = DatumGetByteaPP(lwgeom_to_bytea_p(fcinfo_local));

    /* Extract binary data and length */
    byte_data = (uint8 *)VARDATA_ANY(byte);
    byte_len = VARSIZE_ANY_EXHDR(byte);

    /* Validate geography type (Point type = 1) */
    if (byte_len >= 9 && byte_data[1] == 0x01 && 
        byte_data[2] == 0x00 && byte_data[3] == 0x00) 
    {
        /* Extract SRID flag */
        srid_flag = byte_data[4];
        srid_size = 4;
   
        /* Determine point type and coordinate size based on dimension flags */
        switch (srid_flag & 0xC0) 
        {
            case 0x00:
                if (is_empty) 
                {
                    point_type = 0x04;
                    coord_size = 21;
                } 
                else 
                {
                    /* XY coordinates */
                    point_type = 0x0c;
                    coord_size = 16;
                }
                break;
        
            case 0x80:
                /* XYZ coordinates */
                point_type = 0x0d;
                coord_size = 24;
                break;
        
            case 0xC0:
                /* XYZM coordinates */
                point_type = 0x0f;
                coord_size = 32;
                break;
        
            case 0x40:
                /* XYM coordinates */
                point_type = 0x0e;
                coord_size = 24;
                break;
        
            default:
                /* Return original data for unsupported types */
                PG_RETURN_BYTEA_P(byte);
        }

        /* Allocate memory for result with header and data */
        result = (bytea *) palloc(6 + srid_size + coord_size);
        SET_VARSIZE(result, 6 + srid_size + coord_size);
        result_data = (uint8 *)VARDATA(result);
        
        /* Copy SRID (always present in geography) */
        memcpy(result_data, byte_data + 5, 4);

        /* Set point type in header */
        result_data[4] = 0x01;
        result_data[5] = point_type;

        if (is_empty) 
        {
            memcpy(result_data + 6, coord, coord_size);
        } 
        else 
        {
            /* Copy coordinate data */
            memcpy(result_data + 6, byte_data + 9, coord_size);
        }

        PG_RETURN_BYTEA_P(result);
    }

    /* Return original data if not a point geography */
    PG_RETURN_BYTEA_P(byte);
}

/* This function converts a PostGIS geometry to its WKB representation. */
Datum
st_as_binary_geometry(PG_FUNCTION_ARGS)
{
    Datum    geom,             /* Input geometry */
             modified_geom,    /* 2D version of input geometry */
             result;           /* Final WKB result */
    bool     is_empty;         /* Flag for empty geometry */
    char    *geom_type;        /* String representation of geometry type */
    bytea   *empty_geom;       /* Special representation for empty geometry */
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    /* Load required functions */
    load_functions();

    /* Get input geometry object */
    geom = PG_GETARG_DATUM(0);

    /* Check if the geometry is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom);
    is_empty = DatumGetBool(st_isempty_p(fcinfo_local));

    if (is_empty) 
    {
        /* Get the type of empty geometry for proper representation */
        geom_type = GetGeometryTypeName(fcinfo_local, geom);

        /* Create special binary representation for empty geometry */
        empty_geom = palloc(VARHDRSZ + 9);
        SET_VARSIZE(empty_geom, VARHDRSZ + 9);
        
        if (strcmp(geom_type, "ST_Point") == 0) 
        {
            /* 
             * Empty Point WKB representation:
             * 0x01: byte order (little endian)
             * 0x04: empty point type
             * 0x00000000: empty coordinate sequence
             */
            memcpy(VARDATA(empty_geom), 
                  "\x01\x04\x00\x00\x00\x00\x00\x00\x00", 9);
        }
        
        /* Clean up allocated memory */
        pfree(geom_type);
        PG_RETURN_BYTEA_P(empty_geom);
    }
    else 
    {
        /* 
         * Handle non-empty geometry case
         * 1. Force geometry to 2D (remove Z and M dimensions)
         * 2. Convert to WKB format
         */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom);
        modified_geom = lwgeom_force_2d_p(fcinfo_local);

        /* Convert 2D geometry to WKB format */
        UpdateFunctionCallInfo(fcinfo_local, 1, modified_geom);
        result = lwgeom_asBinary_p(fcinfo_local);

        PG_RETURN_DATUM(result);
    }
}

/* This function converts a PostGIS geography to its WKB representation. */
Datum
st_as_binary_geography(PG_FUNCTION_ARGS)
{
    Datum    geom,            /* Input geography */
             modified_geom,   /* 2D version of input */
             flipped_geom,    /* Geography with flipped coordinates */
             result;          /* Final WKB result */
    bool     is_empty;        /* Flag for empty geography */
    char    *geom_type;       /* String representation of geography type */
    bytea   *empty_geom;      /* Special representation for empty geography */
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    /* Load required functions */
    load_functions();

    /* Get input geography object */
    geom = PG_GETARG_DATUM(0);

    /* Check if the geography is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom);
    is_empty = DatumGetBool(st_isempty_p(fcinfo_local));

    if (is_empty) 
    {
        /* Get the type of empty geography for proper representation */
        geom_type = GetGeometryTypeName(fcinfo_local, geom);

        /* Create special binary representation for empty geography */
        empty_geom = palloc(VARHDRSZ + 9);
        SET_VARSIZE(empty_geom, VARHDRSZ + 9);
        
        if (strcmp(geom_type, "ST_Point") == 0) 
        {
            /* 
             * Empty Point WKB representation:
             * 0x01: byte order (little endian)
             * 0x04: empty point type
             * 0x00000000: empty coordinate sequence
             */
            memcpy(VARDATA(empty_geom), 
                  "\x01\x04\x00\x00\x00\x00\x00\x00\x00", 9);
        }
        
        /* Clean up allocated memory */
        pfree(geom_type);
        PG_RETURN_BYTEA_P(empty_geom);
    }
    else 
    {
        /* 
         * Handle non-empty geography case
         * Process in three steps:
         * 1. Force geography to 2D (remove Z and M dimensions)
         * 2. Flip coordinates (convert to lat/long order)
         * 3. Convert to WKB format
         */

        /* Convert to 2D */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom);
        modified_geom = lwgeom_force_2d_p(fcinfo_local);

        /* Flip coordinates for proper lat/long orientation */
        UpdateFunctionCallInfo(fcinfo_local, 1, modified_geom);
        flipped_geom = st_flipcoordinates_p(fcinfo_local);

        /* Convert flipped geography to WKB format */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        result = lwgeom_asBinary_p(fcinfo_local);

        PG_RETURN_DATUM(result);
    }
}

/* This function converts a PostGIS geometry to its WKT representation. */
Datum
st_as_text(PG_FUNCTION_ARGS)
{
    Datum    geom,            /* Input geometry */
             forced_2d_geom,  /* 2D version of input geometry */
             result;          /* Final WKT result */
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    /* Load required functions */
    load_functions();

    /* Get input geometry object */
    geom = PG_GETARG_DATUM(0);

    /* 
     * Convert input geometry to 2D
     * This removes any Z (elevation) or M (measure) dimensions
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom);
    forced_2d_geom = lwgeom_force_2d_p(fcinfo_local);

    /* 
     * Convert 2D geometry to WKT format
     * Uses PostGIS's internal text conversion function
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, forced_2d_geom);
    result = lwgeom_astext_p(fcinfo_local);

    PG_RETURN_DATUM(result);
}

Datum
geometry_astext(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;          /* Input geometry */
    text    *text_result,         /* Initial WKT text */
            *rewritten_text;      /* Processed WKT text */
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    /* Load required functions */
    load_functions();

    /* Get input geometry */
    geom_datum = PG_GETARG_DATUM(0);

    /* Get text representation of geometry */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    text_result = DatumGetTextP(lwgeom_astext_p(fcinfo_local));

    /* Rewrite the text using direct C function call */
    rewritten_text = geo_wkt_rewrite(text_result);

    /* Return the rewritten text */
    PG_RETURN_DATUM(PointerGetDatum(rewritten_text));
}

#endif
