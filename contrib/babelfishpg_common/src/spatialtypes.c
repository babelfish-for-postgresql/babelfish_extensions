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

/* Helper structure for bytea to geometry conversion */
typedef struct 
{
    bytea   *input;
    uint8   *input_data;
    int      input_len;
    int32_t  srid;
    uint16_t geom_type;
    uint8    dimension_flag;
    int      isNaN;
} GeometryData;

/* Helper structure for geometry to bytea conversion */
typedef struct 
{
    Datum    geom_datum;    /* Input geometry/geography datum */
    bytea   *byte;          /* Binary representation */
    uint8   *byte_data;     /* Raw binary data pointer */
    int      byte_len;      /* Length of binary data */
    uint8    srid_flag;     /* SRID and dimension flags */
    uint8    geom_type;    /* Point dimension type */
    int      srid_size;     /* Size of SRID data (4 bytes) */
    int      coord_size;    /* Size of coordinate data */
    bool     is_empty;      /* Flag indicating empty geometry */
    bool     has_srid;      /* Flag indicating SRID presence */
} GeoDataInfo;

/* Define header values for different dimensions */
static const uint8_t
DIMENSION_HEADERS[] = {
    0x20,   /* Empty */
    0x20,   /* XY  */
    0xA0,   /* XYZ */
    0x60,   /* XYM */
    0xE0    /* XYZM */
};

/* Constant array representing empty coordinate data */
static const uint8 
EMPTY_COORD[] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff
};

/* Array of valid Spatial Reference System Identifiers (SRIDs) for Geography datatype */
static const int32
geography_valid_srids[] = {
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

/*
 * Check if the given SRID is valid for geography type using the predefined array
 * Returns true if SRID is valid, false otherwise
 */
static bool
is_valid_geography_srid(int32 srid)
{
    /* Calculate number of valid SRIDs */
    const int num_valid_srids = sizeof(geography_valid_srids) / sizeof(geography_valid_srids[0]);
    
    /* Since array is sorted, we can use binary search for better performance */
    int start_index = 0;
    int end_index = num_valid_srids - 1;

    while (start_index <= end_index)
    {
        int middle_index = start_index + (end_index - start_index) / 2;
        
        if (geography_valid_srids[middle_index] == srid)
            return true;
        
        if (geography_valid_srids[middle_index] < srid)
            start_index = middle_index + 1;
        else
            end_index = middle_index - 1;
    }

    return false;
}

/* Throw error for unsupported geometry types*/
static void 
check_geom_type(const char *geom_type)
{
    if (strcmp(geom_type, "ST_Point") != 0 )
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("%s is not supported", geom_type)));
    }
}

/*
 * Updates FunctionCallInfoBaseData with new arguments efficiently.
 * 
 * @param fcinfo - Function call info structure to update
 * @param nargs  - Number of arguments to set
 * @param ...    - Variable number of Datum arguments
 */
static inline void 
UpdateFunctionCallInfo(
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
    LOCAL_FCINFO(fcinfo_local, 1);

    load_functions();

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    /* Check for binary format */
    if (PG_GETARG_CSTRING(0)[0] == '0')
        is_binary_format = true;

    if(!is_binary_format)
    {
        /* Direct call to C function with converted input */
        rewritten_wkt_text = geo_wkt_rewrite(cstring_to_text(PG_GETARG_CSTRING(0)));

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
    
    /* check if it is a point type */
    check_geom_type(geometry_name);

    PG_RETURN_DATUM(geom_datum);
}

Datum
geography_in(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;               /* Geometry object */
    text    *rewritten_wkt_text;       /* Rewritten WKT as text */
    char    *rewritten_cstring,        /* Rewritten WKT as cstring */
            *geometry_name,            /* String representation of geometry type */
            *input_str = PG_GETARG_CSTRING(0);
    float8   lat;                      /* Latitude value */
    bool     is_binary_format = false; /* Flag for binary format detection */
    LOCAL_FCINFO(fcinfo_local, 3);

    load_functions();

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 3, PG_GET_COLLATION(), NULL, NULL);

    /* Check for NULL input */
    if (input_str == NULL)
        PG_RETURN_NULL();

    /* Check for binary format */
    if (input_str[0] == '0')
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
        rewritten_wkt_text = geo_wkt_rewrite(cstring_to_text(input_str));
        rewritten_cstring = text_to_cstring(rewritten_wkt_text);

        /* Convert WKT to geometry */
        UpdateFunctionCallInfo(fcinfo_local, 3,
                             CStringGetDatum(rewritten_cstring),
                             fcinfo->args[1].value,
                             fcinfo->args[2].value);
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
    check_geom_type(geometry_name);

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
     */
    check_geom_type(geom_type);

    PG_RETURN_DATUM(geom_datum);
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
    int32       srid;               /* Input SRID value */
    LOCAL_FCINFO(fcinfo_local, 2);  /* Local function call info with 2 arguments */

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);

    /* Extract input parameters from function arguments */
    srid = PG_GETARG_INT32(1);

    /* Load required functions for geometry processing */
    load_functions();

    /* Raise error if SRID is not in valid list */
    if (!is_valid_geography_srid(srid))
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
    check_geom_type(geom_type);
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
        else
        {
            ereport(ERROR,
                    (errcode(ERRCODE_DATA_EXCEPTION),
                     errmsg("Latitude values must be between -90 and 90 degrees")));
        }
    }

    /*  return NULL (only Point is currently supported)*/
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
    if (!is_valid_geography_srid(srid))
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

/* Helper function implementations for char to geometry/geography conversions */

/* Validate whether latitude is between -90 to 90  for non-empty geography */
static void 
validate_latitude(Datum geom_datum) 
{
    Datum   flipped_geom, 
            lat_datum;
    float8  lat;
    LOCAL_FCINFO(fcinfo_local, 1);

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    /* Flip coordinates and get latitude */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    flipped_geom = st_flipcoordinates_p(fcinfo_local);

    UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
    lat_datum = lwgeom_x_p(fcinfo_local);
    lat = DatumGetFloat8(lat_datum);

    if (lat < -90.0 || lat > 90.0) {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Latitude values must be between -90 and 90 degrees")));
    }
}

/* Common function to handle  WKT to both geometry and geography conversion */
static Datum 
char_to_geo_common(text *input_text, bool is_geography) 
{
    Datum   geom_datum, 
            is_empty_datum;
    text    *rewritten_wkt_text;
    char    *geom_type;
    bool    is_empty;
    int32   srid = is_geography ? 4326 : 0;
    LOCAL_FCINFO(fcinfo_local, 2);

    /* Initialize function call info */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    load_functions();

    /* Process input WKT */
    rewritten_wkt_text = geo_wkt_rewrite(input_text);

    /* Convert to geometry with appropriate SRID */
    UpdateFunctionCallInfo(fcinfo_local, 2,
                         PointerGetDatum(rewritten_wkt_text),
                         Int32GetDatum(srid));
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Get and validate geometry type */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);
    check_geom_type(geom_type);

    if (is_geography) 
    {
        /* Check if geometry is empty */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
        is_empty_datum = st_isempty_p(fcinfo_local);
        is_empty = DatumGetBool(is_empty_datum);

        if (!is_empty) 
        {
            /* Validate latitude for non-empty geography points */
            validate_latitude(geom_datum);
        }
    }

    return geom_datum;
}

/* This function converts WKT (Well-Known Text) input to a geometry object. */
Datum 
charTogeom(PG_FUNCTION_ARGS) 
{
    return char_to_geo_common(PG_GETARG_TEXT_PP(0), false);
}

/* This function converts WKT (Well-Known Text) input to a geography object. */
Datum 
charTogeog(PG_FUNCTION_ARGS) 
{
    return char_to_geo_common(PG_GETARG_TEXT_PP(0), true);
}

/* Helper function implementations for bytea to geometry/geography conversions */
static void 
validate_input_length(const bytea *input, const char *type_name) 
{
    if (VARSIZE_ANY_EXHDR(input) < 22) {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid %s", type_name)));
    }
}

static GeometryData* 
initialize_geometry_data(bytea *input) 
{
    GeometryData *geom_data = palloc(sizeof(GeometryData));
    
    geom_data->input = input;
    geom_data->input_data = (uint8 *)VARDATA_ANY(input);
    geom_data->input_len = VARSIZE_ANY_EXHDR(input);
    
    /* Extract SRID from first 4 bytes (little-endian) */
    geom_data->srid = (geom_data->input_data[3] << 24) | 
                      (geom_data->input_data[2] << 16) | 
                      (geom_data->input_data[1] << 8) | 
                       geom_data->input_data[0];
    
    /* Extract geometry type */
    geom_data->geom_type = (geom_data->input_data[4] << 8) | 
                            geom_data->input_data[5];
    
    geom_data->dimension_flag = 0;
    geom_data->isNaN = 0;
    
    return geom_data;
}

static void check_nan_coordinates(GeometryData *geom_data) 
{
    uint8 empty_geom[8] = "\x00\x00\x00\x00\x00\x00\xf8\x7f";
    uint8 input_coord[8];
    int byte_position = 6;
    
    /* Check only X and Y coordinates for Nan values */
    for (int i = 0; i < 2 && byte_position < geom_data->input_len; i++) 
    {
        memcpy(input_coord, geom_data->input_data + byte_position, 8);
        if (memcmp(input_coord, empty_geom, 8) == 0) 
        {
            geom_data->isNaN = 1;
            break;
        }
        byte_position += 8;
    }
}

/* Set dimension flag based on geometry type */
static void 
set_dimension_flag(GeometryData *geom_data) 
{
    switch (geom_data->geom_type) 
    {
        case 0x0104: 
            geom_data->dimension_flag = 0; 
            break;
        case 0x010C: 
            geom_data->dimension_flag = 1; 
            break;
        case 0x010D: 
            geom_data->dimension_flag = 2; 
            break;
        case 0x010E: 
            geom_data->dimension_flag = 3; 
            break;
        case 0x010F: 
            geom_data->dimension_flag = 4; 
            break;
        default:
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Unsupported geometry type")));
    }
}

static bytea* 
process_geometry_data(GeometryData *geom_data) 
{
    uint8 new_header[5] = "\x01\x01\x00\x00\x20";
    uint8 empty_geom[8] = "\x00\x00\x00\x00\x00\x00\xf8\x7f";
    bytea *result;
    uint8 *result_data,
          last_emptybyte;

    /* 
     * Handle empty geometry case
     * TODO : To be updated for LINESTRING which has same flags
     */
    if (geom_data->dimension_flag == 0 )
    {
        /* 
         * Validate empty geometry format:
         * Input length should be sizeof(EMPTY_COORD) + 7 bytes 
         * (6 bytes header + 20 bytes coordinates + 1 byte type)
         * Compare input data (skipping 6 byte header) with EMPTY_COORD pattern
         * Throw error if either condition fails
         */
        if (geom_data->input_len != sizeof(EMPTY_COORD) + 7 ||
            memcmp(geom_data->input_data + 6, EMPTY_COORD, sizeof(EMPTY_COORD)) != 0)
        {
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Unsupported geometry type")));
        }
        last_emptybyte = geom_data->input_data[sizeof(EMPTY_COORD)+6];

        switch(last_emptybyte)
        {
            /* Handle POINT type where last byte is 01 */
            case 0x01:
                /* Allocate memory for empty geometry */
                result = (bytea *) palloc(VARHDRSZ + 25);
                SET_VARSIZE(result, VARHDRSZ + 25);
                result_data = (uint8 *)VARDATA(result);

                /* Construct empty geometry */
                memcpy(result_data, new_header, 5);
                memcpy(result_data + 5, geom_data->input_data, 4);
                memcpy(result_data + 9, empty_geom, 8);
                memcpy(result_data + 17, empty_geom, 8);
                break;
                
            default:
                ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Unsupported geometry type")));
                break;
        }
    }
    else 
    {
        /* Update dimension information in header */
        if (geom_data->dimension_flag <= MAX_DIMENSION_FLAG)
            new_header[4] = DIMENSION_HEADERS[geom_data->dimension_flag];

        /* Allocate memory for non-empty geometry */
        result = (bytea *) palloc(VARHDRSZ + geom_data->input_len - 2 + 5);
        SET_VARSIZE(result, VARHDRSZ + geom_data->input_len - 2 + 5);
        result_data = (uint8 *)VARDATA(result);

        /* Construct non-empty geometry */
        memcpy(result_data, new_header, 5);
        memcpy(result_data + 5, geom_data->input_data, 4);
        memcpy(result_data + 9, geom_data->input_data + 6, geom_data->input_len - 6);
    }
    
    return result;
}

/* This function converts a binary (bytea) representation to a PostGIS geography object. */
Datum 
geometry_from_bytea(PG_FUNCTION_ARGS) 
{
    bytea   *result,
            *input;
    Datum   geometry_result;
    GeometryData *geom_data;
    LOCAL_FCINFO(fcinfo_local, 1);

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    load_functions();

    /* Get binary input argument and validate its length */
    input = PG_GETARG_BYTEA_PP(0);
    validate_input_length(input, "Geometry");

    /* Initialize geometry data then validate coordinates and set dimension information */
    geom_data = initialize_geometry_data(input);
    check_nan_coordinates(geom_data);
    set_dimension_flag(geom_data);

    /* SRID must be between 0 and 999999 */
    if (geom_data->srid < 0 || geom_data->srid > 999999 || geom_data->isNaN) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geometry.")));
    }

    /* Process the geometry data */
    result = process_geometry_data(geom_data);
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geometry_result = lwgeom_from_bytea_p(fcinfo_local);

    pfree(geom_data);
    return geometry_result;
}

/* This function converts a binary (bytea) representation to a PostGIS geometry object. */
Datum 
geography_from_bytea(PG_FUNCTION_ARGS)
{
    bytea   *result,
            *input;
    Datum   geography_result;
    double  lat;
    uint64_t lat_bits;
    GeometryData *geom_data;
    LOCAL_FCINFO(fcinfo_local, 1);

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    load_functions();

    /* Get binary input argument and validate its length */
    input = PG_GETARG_BYTEA_PP(0);
    validate_input_length(input, "Geography");

    /* Initialize geography data then validate coordinates and set dimension information */
    geom_data = initialize_geometry_data(input);
    check_nan_coordinates(geom_data);
    set_dimension_flag(geom_data);

    /* Geography-specific validation */
    memcpy(&lat_bits, geom_data->input_data + 6, sizeof(uint64_t));
    lat_bits = le64toh(lat_bits);
    memcpy(&lat, &lat_bits, sizeof(double));

    /* Check SRID and latitude validity */
    if (!is_valid_geography_srid(geom_data->srid) ||  geom_data->isNaN || lat < -90.0 || lat > 90.0) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geography.")));
    }

    /* Process the geography data */
    result = process_geometry_data(geom_data);
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geography_result = lwgeom_from_bytea_p(fcinfo_local);

    pfree(geom_data);
    return geography_result;
}

/* Helper function implementations for geometry/geography to bytea conversions */
static GeoDataInfo* 
initialize_geom_data(Datum input_datum) 
{
    LOCAL_FCINFO(fcinfo_local, 1);
    GeoDataInfo *geom_data = palloc0(sizeof(GeoDataInfo));
    
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    
    geom_data->geom_datum = input_datum;
    
    /* Check if the geometry is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, input_datum);
    geom_data->is_empty = DatumGetBool(st_isempty_p(fcinfo_local));
    
    /* Convert to binary format */
    UpdateFunctionCallInfo(fcinfo_local, 1, input_datum);
    geom_data->byte = DatumGetByteaPP(lwgeom_to_bytea_p(fcinfo_local));
    
    geom_data->byte_data = (uint8 *)VARDATA_ANY(geom_data->byte);
    geom_data->byte_len = VARSIZE_ANY_EXHDR(geom_data->byte);
    geom_data->srid_size = 4;
    
    return geom_data;
}

static bool
validate_geom_type(const GeoDataInfo *geom_data) 
{
    return (geom_data->byte_len >= 5 && 
            geom_data->byte_data[1] == 0x01 &&  /* Point type identifier */
            geom_data->byte_data[2] == 0x00 && 
            geom_data->byte_data[3] == 0x00);
}

static bool
determine_geom_dimensions(GeoDataInfo *geom_data) 
{
    geom_data->srid_flag = geom_data->byte_data[4];
    geom_data->has_srid = geom_data->srid_flag & 0x20;
    
    switch (geom_data->srid_flag & 0xC0) 
    {
        case 0x00:  /* XY or Empty */
            if (geom_data->is_empty) 
            {
                geom_data->geom_type = 0x04;  /* Empty point */
                geom_data->coord_size = 21;
            } 
            else 
            {
                geom_data->geom_type = 0x0c;  /* XY point */
                geom_data->coord_size = 16;
            }
            break;
        case 0x80:  /* XYZ */
            geom_data->geom_type = 0x0d;
            geom_data->coord_size = 24;
            break;
        case 0xC0:  /* XYZM */
            geom_data->geom_type = 0x0f;
            geom_data->coord_size = 32;
            break;
        case 0x40:  /* XYM */
            geom_data->geom_type = 0x0e;
            geom_data->coord_size = 24;
            break;
        default:
            return false;
    }
    return true;
}

/* Constructs result bytea from geometry data */
static bytea* 
construct_result_bytea(GeoDataInfo *geom_data, bool is_geography) 
{
    bytea *result;
    uint8 *result_data;
    
    result = (bytea *) palloc(6 + geom_data->srid_size + geom_data->coord_size);
    SET_VARSIZE(result, 6 + geom_data->srid_size + geom_data->coord_size);
    result_data = (uint8 *)VARDATA(result);
    
    /* Handle SRID data */
    if (is_geography || geom_data->has_srid) 
    {
        memcpy(result_data, geom_data->byte_data + 5, 4);
    } else 
    {
        memset(result_data, 0, 4);
    }
    
    /* Set geometry type in header */
    result_data[4] = 0x01;
    result_data[5] = geom_data->geom_type;
    
    /* Copy coordinate data */
    if (geom_data->is_empty) 
    {
        memcpy(result_data + 6, EMPTY_COORD, geom_data->coord_size);
        /* Check if the last byte is 01 which represents POINT type*/
        if (geom_data->byte_data[1] == 0x01)
            result_data[6 + sizeof(EMPTY_COORD)] = 0x01;
    } 
    else 
    {
        int offset = (is_geography || geom_data->has_srid) ? 9 : 5;
        memcpy(result_data + 6, geom_data->byte_data + offset, geom_data->coord_size);
    }
    
    return result;
}

/* This function converts a PostGIS geometry object to its binary (bytea) representation. */
Datum 
bytea_from_geometry(PG_FUNCTION_ARGS) 
{
    GeoDataInfo *geom_data;
    bytea       *result;
    load_functions();
    
    geom_data = initialize_geom_data(PG_GETARG_DATUM(0));
   
    /* If geometry validation fails, return existing binary representation without further processing */
    if (!validate_geom_type(geom_data)) 
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
    
    /* If dimension validation fails, return existing binary representation without further processing */
    if (!determine_geom_dimensions(geom_data))
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
   
    /* Construct final binary representation */
    result = construct_result_bytea(geom_data, false);
    pfree(geom_data);
    PG_RETURN_BYTEA_P(result);
}

/* This function converts a PostGIS geography object to its binary (bytea) representation. */
Datum 
bytea_from_geography(PG_FUNCTION_ARGS) 
{
    GeoDataInfo *geom_data;
    bytea       *result;
    load_functions();
    
    geom_data = initialize_geom_data(PG_GETARG_DATUM(0));
    
    /* If geography validation fails, return existing binary representation without further processing */
    if (!validate_geom_type(geom_data)) 
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
    
    /* If dimension validation fails, return existing binary representation without further processing */
    if (!determine_geom_dimensions(geom_data)) 
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
    
    /* Construct final binary representation */
    result = construct_result_bytea(geom_data, true);
    pfree(geom_data);
    PG_RETURN_BYTEA_P(result);
}

/* Common function to handle both geometry and geography conversion to binary */
static Datum 
st_as_binary_common(Datum input, bool is_geography) 
{
    Datum   modified_datum, result;
    bool    is_empty;
    char   *geom_type;
    bytea  *empty_geom;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Initialize function call info */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    load_functions();

    /* Check if the input is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, input);
    is_empty = DatumGetBool(st_isempty_p(fcinfo_local));

    if (is_empty) 
    {
        /* Handle empty geometry case */
        geom_type = GetGeometryTypeName(fcinfo_local, input);
        empty_geom = palloc(VARHDRSZ + 9);
        SET_VARSIZE(empty_geom, VARHDRSZ + 9);
        
        if (strcmp(geom_type, "ST_Point") == 0) 
        {
            memcpy(VARDATA(empty_geom), 
                  "\x01\x04\x00\x00\x00\x00\x00\x00\x00", 9);
        }
        
        pfree(geom_type);
        return PointerGetDatum(empty_geom);
    }

    /* Process non-empty geometry */
    UpdateFunctionCallInfo(fcinfo_local, 1, input);
    modified_datum = lwgeom_force_2d_p(fcinfo_local);

    if (is_geography) 
    {
        /* Additional step for geography: flip coordinates */
        UpdateFunctionCallInfo(fcinfo_local, 1, modified_datum);
        modified_datum = st_flipcoordinates_p(fcinfo_local);
    }

    /* Convert to WKB format */
    UpdateFunctionCallInfo(fcinfo_local, 1, modified_datum);
    result = lwgeom_asBinary_p(fcinfo_local);

    return result;
}

/* This function converts a PostGIS geometry to its WKB representation. */
Datum 
st_as_binary_geometry(PG_FUNCTION_ARGS) 
{
    return st_as_binary_common(PG_GETARG_DATUM(0), false);
}

/* This function converts a PostGIS geography to its WKB representation. */
Datum 
st_as_binary_geography(PG_FUNCTION_ARGS) 
{
    return st_as_binary_common(PG_GETARG_DATUM(0), true);
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
