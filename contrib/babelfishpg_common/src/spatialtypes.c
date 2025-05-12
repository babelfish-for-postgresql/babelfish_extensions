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
#define POINT_TYPE     1  /* Identifier for Point geometry type */

#define DEFAULT_GEOGRAPHY_SRID 4326
#define DEFAULT_GEOMETRY_SRID  0
#define MIN_GEOMETRY_LENGTH    22  /* Minimum length for geometry data which 2D POINT */

#define COORD_SIZE     8      /* Size of each coordinate in bytes (double) */
#define HEADER_SIZE    6      /* Size of the geometry header in bytes */
#define XY_COORD_COUNT 2      /* Number of coordinates to check for NaN (X and Y) */

#define DIM_FLAG_EMPTY       0       /* Dimension flag for Empty Point */
#define DIM_FLAG_2D          1       /* Dimension flag for 2D Point (XY) */
#define DIM_FLAG_3D          2       /* Dimension flag for 3D Point (XYZ) */
#define DIM_FLAG_2DM         3       /* Dimension flag for 2D Point with M (XYM) */
#define DIM_FLAG_3DM         4       /* Dimension flag for 3D Point with M (XYZM) */

#define POSTGIS_HEADER_SIZE      5      /* Size of the postgis header in bytes */
#define SRID_SIZE                4      /* Size of the SRID field in bytes */
#define HEADER_DIMENSION_POS     4      /* Position of dimension info in header */
#define EMPTY_POINT_TYPE_LASTBYTE    0x01    /* Type identifier for empty point */

#define SRID_FLAG_POS     4     /* Position of SRID flag in binary data */
#define SRID_MASK         0x20  /* Bitmask for SRID presence flag */
#define DIMENSION_MASK    0xC0  /* Bitmask for dimension flags */

/* Dimension type flags */
#define POSTGIS_DIM_XY            0x00 /* XY dimensions (2D) */
#define POSTGIS_DIM_XYZ           0x80 /* XYZ dimensions (3D) */
#define POSTGIS_DIM_XYZM          0xC0 /* XYZM dimensions (4D) */
#define POSTGIS_DIM_XYM           0x40 /* XYM dimensions (2D with measure) */

/* Coordinate sizes in bytes */
#define COORD_SIZE_EMPTY   21  /* Size of empty point coordinates */
#define COORD_SIZE_XY      16  /* Size of XY coordinates (2 doubles) */
#define COORD_SIZE_XYZ     24  /* Size of XYZ coordinates (3 doubles) */
#define COORD_SIZE_XYM     24  /* Size of XYM coordinates (3 doubles) */
#define COORD_SIZE_XYZM    32  /* Size of XYZM coordinates (4 doubles) */

#define GEOM_TYPE_SIZE      2   /* Size of the geometry type header in bytes */
#define SRID_POS            0   /* Position of SRID in result data: TSQL */
#define GEOM_TYPE_HEADER    1   /* Geometry type header value */
#define COORD_POS           6   /* Position where coordinates start in result data */
#define SRID_POSTGIS_POS    5   /* Position of SRID FLAG in POSTGIS data */
#define OFFSET_WITH_SRID    9   /* Offset for coordinate data with SRID */
#define OFFSET_WITHOUT_SRID 5   /* Offset for coordinate data without SRID */

#define GEOM_TYPE_POS_POSTGIS  1   /* Position of geometry type in PostGIS binary data */
#define GEOM_TYPE_POS_RESULT   4   /* Position of geometry type in result data */

#define EMPTY_Binary_SIZE      9   /* Size of empty representation in binary */
#define EMPTY_POINT_Binary   "\x01\x04\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty point */
/* 
 * Global array representing NaN coordinate value in IEEE 754 format
 * Used for empty point detection and creation
 */
static const uint8 NAN_COORD[8] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f  /* NaN representation */
};

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
    bool      isNaN;
} GeometryData;

/* Helper structure for geometry to bytea conversion */
typedef struct 
{
    Datum    geom_datum;    /* Input geometry/geography datum */
    bytea   *byte;          /* Binary representation */
    uint8   *byte_data;     /* Raw binary data pointer */
    int      byte_len;      /* Length of binary data */
    uint8    srid_flag;     /* SRID and dimension flags */
    uint8    geom_type;     /* Point dimension type */
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
    {
        lwgeom_in_p = (lwgeom_in_t) load_external_function("$libdir/postgis-3", "LWGEOM_in", true, NULL);
        geometry_type_p = (geometry_type_t) load_external_function("$libdir/postgis-3", "geometry_geometrytype", true, NULL);
        gserialized_set_srid_p = (gserialized_set_srid_t) load_external_function("$libdir/postgis-3", "LWGEOM_set_srid", true, NULL);
        st_flip_coord_p = (st_flip_coord_t) load_external_function("$libdir/postgis-3", "ST_FlipCoordinates", true, NULL);
        lwgeom_x_p = (lwgeom_x_t) load_external_function("$libdir/postgis-3", "LWGEOM_x_point", true, NULL);
        lwgeom_from_text_p = (lwgeom_from_text_t) load_external_function("$libdir/postgis-3", "LWGEOM_from_text", true, NULL);
        lwgeom_from_bytea_p = (lwgeom_from_bytea_t) load_external_function("$libdir/postgis-3", "LWGEOM_from_bytea", true, NULL);
        lwgeom_to_bytea_p = (lwgeom_to_bytea_t) load_external_function("$libdir/postgis-3", "LWGEOM_to_bytea", true, NULL);
        st_flipcoordinates_p = (st_flipcoordinates_t) load_external_function("$libdir/postgis-3", "ST_FlipCoordinates", true, NULL);
        st_point_p = (st_point_t) load_external_function("$libdir/postgis-3", "ST_Point", true, NULL);
        st_isempty_p = (st_isempty_t) load_external_function("$libdir/postgis-3", "LWGEOM_isempty", true, NULL);
        lwgeom_force_2d_p = (lwgeom_force_2d_t) load_external_function("$libdir/postgis-3", "LWGEOM_force_2d", true, NULL);
        lwgeom_asBinary_p = (lwgeom_asBinary_t) load_external_function("$libdir/postgis-3", "LWGEOM_asBinary", true, NULL);
        lwgeom_astext_p = (lwgeom_astext_t) load_external_function("$libdir/postgis-3", "LWGEOM_asText", true, NULL);
    }
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

/* Input function for the geometry data type. */
Datum
geometry_in(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;               /* Resulting geometry object */
    text    *rewritten_wkt_text;       /* Rewritten WKT as text */
    char    *rewritten_cstring,        /* Rewritten WKT as cstring */
            *geometry_name;            /* String representation of geometry type */
    bool     is_binary_format = false; /* Flag for binary format detection */
    LOCAL_FCINFO(fcinfo_local, 1);     /* Local function call info */

    load_functions();

    /* Initialize function call info with collation for text processing */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    /* 
     * Check if input is in binary format (WKB)
     * Binary format starts with '0' character
     */
    if (PG_GETARG_CSTRING(0)[0] == '0')
        is_binary_format = true;

    if(!is_binary_format)
    {
        /* 
         * Process text format (WKT):
         * 1. Convert input cstring to text
         * 2. Rewrite the WKT using geo_wkt_rewrite
         * 3. Convert rewritten WKT back to cstring for PostGIS function
         */
        rewritten_wkt_text = geo_wkt_rewrite(cstring_to_text(PG_GETARG_CSTRING(0)));
        rewritten_cstring = text_to_cstring(rewritten_wkt_text);

        /* Prepare for LWGEOM_in function call with rewritten WKT */
        UpdateFunctionCallInfo(fcinfo_local, 1, CStringGetDatum(rewritten_cstring));
    }
    else 
    {
        /* 
         * Process binary format (WKB):
         * Pass the binary data directly to PostGIS function
         */
        UpdateFunctionCallInfo(fcinfo_local, 1, fcinfo->args[0].value);
    }

    /* Convert input to PostGIS geometry object using LWGEOM_in function */
    geom_datum = lwgeom_in_p(fcinfo_local);

    /* Get the type of the resulting geometry */
    geometry_name = GetGeometryTypeName(fcinfo_local, geom_datum);
    
    /* Validate that the geometry is a supported type (Point) */
    check_geom_type(geometry_name);

    /* Return the PostGIS geometry object */
    PG_RETURN_DATUM(geom_datum);
}

/* Input function for the geography data type. */
Datum
geography_in(PG_FUNCTION_ARGS)
{
    Datum    geog_datum;               /* Resulting geography object */
    text    *rewritten_wkt_text;       /* Rewritten WKT as text */
    char    *rewritten_cstring,        /* Rewritten WKT as cstring */
            *geography_name,           /* String representation of geography type */
            *input_str = PG_GETARG_CSTRING(0);  /* Input string */
    float8   lat;                      /* Latitude value */
    bool     is_binary_format = false; /* Flag for binary format detection */
    LOCAL_FCINFO(fcinfo_local, 3);     /* Local function call info with 3 arguments */

    /* Load required PostGIS functions */
    load_functions();

    /* Initialize function call info with collation for text processing */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 3, PG_GET_COLLATION(), NULL, NULL);

    /* Check for NULL input and return NULL if found */
    if (input_str == NULL)
        PG_RETURN_NULL();

    /* 
     * Check if input is in binary format (WKB)
     * Binary format starts with '0' character
     */
    if (input_str[0] == '0')
        is_binary_format = true;

    /* Process input based on format */
    if(is_binary_format)
    {
        /* 
         * Process binary format (WKB):
         * Pass the binary data directly to PostGIS function with all arguments
         */
        UpdateFunctionCallInfo(fcinfo_local, 3,
                             fcinfo->args[0].value,
                             fcinfo->args[1].value,
                             fcinfo->args[2].value);
        
        /* Convert input to PostGIS geography object using LWGEOM_in function */
        geog_datum = lwgeom_in_p(fcinfo_local);
    }
    else
    {
        /* 
         * Process text format (WKT):
         * 1. Convert input cstring to text
         * 2. Rewrite the WKT using geo_wkt_rewrite
         * 3. Convert rewritten WKT back to cstring for PostGIS function
         */
        rewritten_wkt_text = geo_wkt_rewrite(cstring_to_text(input_str));
        rewritten_cstring = text_to_cstring(rewritten_wkt_text);

        /* Convert WKT to geography with original arguments */
        UpdateFunctionCallInfo(fcinfo_local, 3,
                             CStringGetDatum(rewritten_cstring),
                             fcinfo->args[1].value,
                             fcinfo->args[2].value);
        geog_datum = lwgeom_in_p(fcinfo_local);

        /* 
         * Set SRID to 4326 (WGS84) for geography datatype
         */
        UpdateFunctionCallInfo(fcinfo_local, 2,
                             geog_datum,
                             Int32GetDatum(DEFAULT_GEOGRAPHY_SRID));
        geog_datum = gserialized_set_srid_p(fcinfo_local);

        /* 
         * Flip coordinates for geography storage
         * This converts from longitude/latitude to latitude/longitude order
         */
        UpdateFunctionCallInfo(fcinfo_local, 1, geog_datum);
        geog_datum = st_flip_coord_p(fcinfo_local);
    }

    /* Get the type of the resulting geography */
    geography_name = GetGeometryTypeName(fcinfo_local, geog_datum);
    
    /* Validate that the geography is a supported type (Point) */
    check_geom_type(geography_name);

    /* 
     * Extract and validate latitude value
     * Geography objects require latitude values between -90 and 90 degrees
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, geog_datum);
    lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));

    /* Check if latitude is within valid range */
    if (lat > 90.0 || lat < -90.0)
    {
        /* Report error for invalid latitude */
        ereport(ERROR,
            (errcode(ERRCODE_DATA_EXCEPTION),
            errmsg("Latitude values must be between -90 and 90 degrees")));
    }

    /* Return the PostGIS geography object */
    PG_RETURN_DATUM(geog_datum);
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

    /*  Validate that the geometry is a supported type */
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
        if ((lat < -90.0 || lat > 90.0) && !isnan(lat)) 
        {
            ereport(ERROR,
                (errcode(ERRCODE_DATA_EXCEPTION),
                 errmsg("Latitude values must be between -90 and 90 degrees")));
        } 
    }
    PG_RETURN_DATUM(flipped_geom_datum);
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
    Datum   flipped_geom,      /* Geometry with flipped coordinates */
            lat_datum;         /* Latitude value as datum */
    float8  lat;               /* Latitude value as double */
    LOCAL_FCINFO(fcinfo_local, 1);  /* Local function call info */

    /* Initialize function call info for PostGIS function calls */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    /* 
     * Flip coordinates:
     * This converts from longitude/latitude to latitude/longitude order
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    flipped_geom = st_flipcoordinates_p(fcinfo_local);

    /* 
     * Extract latitude after flipping
     * using PostGIS's LWGEOM_x_point function
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
    lat_datum = lwgeom_x_p(fcinfo_local);
    lat = DatumGetFloat8(lat_datum);

    /* Check if latitude is within valid range (-90 to 90 degrees) */
    if (lat < -90.0 || lat > 90.0) {
        /* Report error for invalid latitude */
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Latitude values must be between -90 and 90 degrees")));
    }
}

/* Common function to handle  WKT to both geometry and geography conversion */
static Datum 
char_to_geo_common(text *input_text, bool is_geography) 
{
    Datum   geom_datum,        /* Resulting geometry/geography object */
            is_empty_datum;    /* Result of ST_IsEmpty function */
    text    *rewritten_wkt_text; /* Rewritten WKT text */
    char    *geom_type;        /* String representation of geometry type */
    bool    is_empty;          /* Flag indicating if geometry is empty */
    int32   srid;              /* Spatial Reference ID to use */
    LOCAL_FCINFO(fcinfo_local, 2); /* Local function call info */

    /* Set appropriate SRID based on target type */
    srid = is_geography ? DEFAULT_GEOGRAPHY_SRID : DEFAULT_GEOMETRY_SRID;

    /* Initialize function call info for PostGIS function calls */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    load_functions();

    /* Rewrite the WKT to ensure proper formatting */
    rewritten_wkt_text = geo_wkt_rewrite(input_text);

    /* 
     * Convert rewritten WKT to geometry with appropriate SRID
     * using PostGIS's LWGEOM_from_text function
     */
    UpdateFunctionCallInfo(fcinfo_local, 2,
                         PointerGetDatum(rewritten_wkt_text),
                         Int32GetDatum(srid));
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Get the type of the resulting geometry */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);
    
    /* Validate that the geometry is a supported type (Point) */
    check_geom_type(geom_type);

    /* Perform additional validation for geography objects */
    if (is_geography) 
    {
        /* Check if the geometry is empty using PostGIS's ST_IsEmpty function */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
        is_empty_datum = st_isempty_p(fcinfo_local);
        is_empty = DatumGetBool(is_empty_datum);

        if (!is_empty) 
        {
            /* 
             * For non-empty geography points, validate latitude values
             * to ensure they are within the valid range (-90 to 90 degrees)
             */
            validate_latitude(geom_datum);
        }
    }

    /* Return the resulting geometry or geography object */
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

/* Validates that the input bytea has sufficient length to be a valid geometry  which is 22 for 2D Point (smallest possible geometry) */
static void 
validate_input_length(const bytea *input, const char *type_name) 
{
    if (VARSIZE_ANY_EXHDR(input) < MIN_GEOMETRY_LENGTH) {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid %s", type_name)));
    }
}

/* Initializes a GeometryData structure from a bytea input. */

/*
 * Geometry Structure: HEADER + POINT COORDINATES
 * HEADER_SIZE -> 4 Bytes SRID + 2 Bytes Geometry Type
 * pointSize -> COORD_SIZE*2( for X and Y) + COORD_SIZE(if Z exists) + COORD_SIZE_M(if M exists)
 */
static GeometryData* 
initialize_geometry_data(bytea *input) 
{
    /* Allocate memory for the GeometryData structure */
    GeometryData *geom_data = palloc(sizeof(GeometryData));
    
    /* Store reference to original input */
    geom_data->input = input;
    
    /* Get pointer to actual data (skipping bytea header) */
    geom_data->input_data = (uint8 *)VARDATA_ANY(input);
    
    /* Store length of data (excluding bytea header) */
    geom_data->input_len = VARSIZE_ANY_EXHDR(input);
    
    /* Extract SRID from first 4 bytes (little-endian) */
    geom_data->srid = (geom_data->input_data[3] << 24) | 
                      (geom_data->input_data[2] << 16) | 
                      (geom_data->input_data[1] << 8) | 
                       geom_data->input_data[0];
    
    /* Extract geometry type from next 2 bytes : 5th and 6th */
    geom_data->geom_type = (geom_data->input_data[4] << 8) | 
                            geom_data->input_data[5];
    
    /* Initialize dimension flag and NaN indicator to zero */
    geom_data->dimension_flag = 0;
    geom_data->isNaN = false;
    
    return geom_data;
}

/* Checks if the X or Y coordinates in the geometry data contain NaN values. */
static void check_nan_coordinates(GeometryData *geom_data) 
{
    uint8 input_coord[COORD_SIZE];
    int byte_position = HEADER_SIZE;  /* Start after the header */
    
    /* Check only X and Y coordinates for NaN values */
    for (int i = 0; i < XY_COORD_COUNT; i++) 
    {
        /* Copy the coordinate bytes to our buffer */
        memcpy(input_coord, geom_data->input_data + byte_position, COORD_SIZE);
        
        /* Compare with the NaN pattern */
        if (memcmp(input_coord, NAN_COORD, COORD_SIZE) == 0) 
        {
            /* Set the NaN flag if a match is found */
            geom_data->isNaN = true;
            break;
        }
        
        /* Move to the next coordinate */
        byte_position += COORD_SIZE;
    }
}

/* Set dimension flag based on geometry type */
static void 
set_dimension_flag(GeometryData *geom_data) 
{
    switch (geom_data->geom_type) 
    {
        case 0x0104:                                /* Empty Point, also valid for LINESTRING to be updated later */
            geom_data->dimension_flag = 0; 
            break;
        case 0x010C: 
            geom_data->dimension_flag = DIM_FLAG_2D; /* 2D Point (XY) */
            break;
        case 0x010D: 
            geom_data->dimension_flag = DIM_FLAG_3D; /* 3D Point (XYZ) */
            break;
        case 0x010E: 
            geom_data->dimension_flag = DIM_FLAG_2DM; /* 2D Point with M (XYM) */
            break;
        case 0x010F: 
            geom_data->dimension_flag = DIM_FLAG_3DM; /* 3D Point with M (XYZM) */
            break;
        default:
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Unsupported geometry type")));
    }
}


/* Processes geometry data and converts it to the target format. */
static bytea* 
process_geometry_data(GeometryData *geom_data) 
{
    /* Initialize the new header with default values as a placeholder */
    uint8 postgis_header[POSTGIS_HEADER_SIZE] = "\x01\x01\x00\x00\x20";
    bytea *result;
    uint8 *result_data,
          last_emptybyte;
    int new_data_size;

    /* 
     * Handle empty geometry case
     * TODO : To be updated for LINESTRING which has same flags
     */
    if (geom_data->dimension_flag == DIM_FLAG_EMPTY)
    {
        /* 
         * Validate empty geometry format:
         * Input length should be sizeof(EMPTY_COORD) + 7 bytes 
         * (6 bytes header + 20 bytes coordinates + 1 byte type)
         * Compare input data (skipping 6 byte header) with EMPTY_COORD pattern
         * Throw error if either condition fails
         */
        if (memcmp(geom_data->input_data + HEADER_SIZE, EMPTY_COORD, sizeof(EMPTY_COORD)) != 0)
        {
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Unsupported geometry type")));
        }
        
        /* Get the geometry type identifier from the last byte */
        last_emptybyte = geom_data->input_data[sizeof(EMPTY_COORD) + HEADER_SIZE];

        switch(last_emptybyte)
        {
            /* Handle POINT type where last byte is 01 */
            case EMPTY_POINT_TYPE_LASTBYTE:
                /* Allocate memory for empty geometry */
                result = (bytea *) palloc(VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE * 2);
                SET_VARSIZE(result, VARHDRSZ +  POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE * 2);
                result_data = (uint8 *)VARDATA(result);

                /* Construct empty geometry with new header */
                memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
                
                /* Copy the SRID from the original data */
                memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
                
                /* Set X and Y coordinates to NaN */
                memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, NAN_COORD, COORD_SIZE);
                memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE, NAN_COORD, COORD_SIZE);
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
        /* Update dimension information in header based on dimension flag */
        if (geom_data->dimension_flag <= MAX_DIMENSION_FLAG)
            postgis_header[HEADER_DIMENSION_POS] = DIMENSION_HEADERS[geom_data->dimension_flag];

        /* Calculate size for the new geometry: VARHDRSZ + (input_len - 2 + 5) */
        new_data_size = geom_data->input_len - GEOM_TYPE_SIZE + POSTGIS_HEADER_SIZE;
        
        /* Allocate memory for non-empty geometry */
        result = (bytea *) palloc(VARHDRSZ + new_data_size);
        SET_VARSIZE(result, VARHDRSZ + new_data_size);
        result_data = (uint8 *)VARDATA(result);

        /* Construct non-empty geometry */
        /* Copy the new header */
        memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
        
        /* Copy the SRID from the original data */
        memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
        
        /* Copy the coordinate data (skipping the original 6-byte header) */
        memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, 
               geom_data->input_data + HEADER_SIZE, 
               geom_data->input_len - HEADER_SIZE);
    }
    
    /* Return the processed geometry */
    return result;
}


/* Converts a binary (bytea) representation to a PostGIS geometry object. */
Datum 
geometry_from_bytea(PG_FUNCTION_ARGS) 
{
    bytea   *result,            /* Processed binary data */
            *input;             /* Input binary data */
    Datum   geometry_result;    /* Final PostGIS geometry object */
    GeometryData *geom_data;    /* Structure to hold geometry information */
    LOCAL_FCINFO(fcinfo_local, 1);  /* Local function call info for PostGIS functions */

    /* Initialize function call info for PostGIS function calls */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    load_functions();

    /* Get binary input argument and validate its length */
    input = PG_GETARG_BYTEA_PP(0);
    validate_input_length(input, "Geometry");

    /* Initialize geometry data structure with input data */
    geom_data = initialize_geometry_data(input);
    
    /* Check for NaN values in coordinates */
    check_nan_coordinates(geom_data);
    
    /* Determine the dimension flag based on geometry type */
    set_dimension_flag(geom_data);

    /* 
     * Validate SRID and coordinate values:
     * - SRID must be between 0 and 999999
     * - Coordinates must not contain NaN values
     */
    if (geom_data->srid < 0 || 
        geom_data->srid > 999999 || 
        geom_data->isNaN) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geometry.")));
    }

    /* Process the geometry data into PostGIS-compatible format */
    result = process_geometry_data(geom_data);
    
    /* Convert the processed binary data to a PostGIS geometry object */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geometry_result = lwgeom_from_bytea_p(fcinfo_local);

    /* Free allocated memory */
    pfree(geom_data);
    
    /* Return the PostGIS geometry object */
    return geometry_result;
}

   /* Offset to latitude coordinate in binary data */

/* Converts a binary (bytea) representation to a PostGIS geography object. */
Datum 
geography_from_bytea(PG_FUNCTION_ARGS)
{
    bytea   *result,            /* Processed binary data */
            *input;             /* Input binary data */
    Datum   geography_result;   /* Final PostGIS geography object */
    double  lat;                /* Extracted latitude value */
    uint64_t lat_bits;          /* Latitude value as raw bits for endian conversion */
    GeometryData *geom_data;    /* Structure to hold geography information */
    LOCAL_FCINFO(fcinfo_local, 1);  /* Local function call info for PostGIS functions */

    /* Initialize function call info for PostGIS function calls */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    load_functions();

    /* Get binary input argument and validate its length */
    input = PG_GETARG_BYTEA_PP(0);
    validate_input_length(input, "Geography");

    /* Initialize geography data structure with input data */
    geom_data = initialize_geometry_data(input);
    
    /* Check for NaN values in coordinates */
    check_nan_coordinates(geom_data);
    
    /* Determine the dimension flag based on geometry type */
    set_dimension_flag(geom_data);

    /* 
     * Extract latitude value from binary data:
     * 1. Copy 8 bytes from the input data starting at offset 6
     * 2. Convert from little-endian to host byte order
     * 3. Interpret the bytes as a double-precision floating point value
     */
    memcpy(&lat_bits, geom_data->input_data + HEADER_SIZE, sizeof(uint64_t));
    lat_bits = le64toh(lat_bits);  /* Convert from little-endian to host byte order */
    memcpy(&lat, &lat_bits, sizeof(double));

    /* 
     * Validate geography-specific constraints:
     * - SRID must be valid for geography
     * - Coordinates must not contain NaN values
     * - Latitude must be between -90 and 90 degrees
     */
    if (!is_valid_geography_srid(geom_data->srid) || 
        geom_data->isNaN || 
        lat < -90.0 || 
        lat > 90.0) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geography.")));
    }

    /* Process the geography data into PostGIS-compatible format */
    result = process_geometry_data(geom_data);
    
    /* Convert the processed binary data to a PostGIS geography object */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geography_result = lwgeom_from_bytea_p(fcinfo_local);

    /* Free allocated memory */
    pfree(geom_data);
    
    /* Return the PostGIS geography object */
    return geography_result;
}

/* Helper function implementations for geometry/geography to bytea conversions */

/* Initializes a GeoDataInfo structure from a PostGIS geometry/geography datum. */
static GeoDataInfo* 
initialize_geom_data(Datum input_datum) 
{
    /* Create local function call info for PostGIS function calls */
    LOCAL_FCINFO(fcinfo_local, 1);
    
    /* Allocate memory for the GeoDataInfo structure and initialize to zero */
    GeoDataInfo *geom_data = palloc0(sizeof(GeoDataInfo));
    
    /* Initialize function call info for PostGIS function calls */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    
    /* Store the original geometry/geography datum */
    geom_data->geom_datum = input_datum;
    
    /* Check if the geometry is empty using PostGIS's ST_IsEmpty function */
    UpdateFunctionCallInfo(fcinfo_local, 1, input_datum);
    geom_data->is_empty = DatumGetBool(st_isempty_p(fcinfo_local));
    
    /* Convert the geometry to binary format using PostGIS's LWGEOM_asBinary function */
    UpdateFunctionCallInfo(fcinfo_local, 1, input_datum);
    geom_data->byte = DatumGetByteaPP(lwgeom_to_bytea_p(fcinfo_local));
    
    /* Get pointer to the actual binary data (skipping bytea header) */
    geom_data->byte_data = (uint8 *)VARDATA_ANY(geom_data->byte);
    
    /* Calculate the length of the binary data (excluding bytea header) */
    geom_data->byte_len = VARSIZE_ANY_EXHDR(geom_data->byte);
    
    /* Set the default SRID size */
    geom_data->srid_size = SRID_SIZE;
    
    return geom_data;
}




/* Validates that the binary data represents a supported geometry type(Point) */
static bool
validate_geom_type(const GeoDataInfo *geom_data) 
{
    return (geom_data->byte_len >= POSTGIS_HEADER_SIZE && 
            geom_data->byte_data[GEOM_TYPE_POS_POSTGIS] == POINT_TYPE &&  /* Point type identifier */
            geom_data->byte_data[GEOM_TYPE_POS_POSTGIS+1] == 0x00 && 
            geom_data->byte_data[GEOM_TYPE_POS_POSTGIS+2] == 0x00);
}



/* Determines the dimension flags  and coordinate size of a geometry. */
static bool
determine_geom_dimensions(GeoDataInfo *geom_data) 
{
    /* Extract the SRID flag from the binary data */
    geom_data->srid_flag = geom_data->byte_data[SRID_FLAG_POS];
    
    /* Determine if the geometry has an SRID */
    geom_data->has_srid = geom_data->srid_flag & SRID_MASK;
    
    /* Determine the TSQL dimensionality based on the PostGIS's dimension flags */
    switch (geom_data->srid_flag & DIMENSION_MASK) 
    {
        case POSTGIS_DIM_XY:  /* XY or Empty */
            if (geom_data->is_empty) 
            {
                /* Empty point geometry */
                geom_data->geom_type = 0x04;
                geom_data->coord_size = COORD_SIZE_EMPTY;
            } 
            else 
            {
                /* 2D point geometry (XY) */
                geom_data->geom_type = 0x0C;
                geom_data->coord_size = COORD_SIZE_XY;
            }
            break;
            
        case POSTGIS_DIM_XYZ:  /* XYZ (3D) */
            geom_data->geom_type = 0x0D;
            geom_data->coord_size = COORD_SIZE_XYZ;
            break;
            
        case POSTGIS_DIM_XYZM:  /* XYZM (3D with measure) */
            geom_data->geom_type = 0x0F;
            geom_data->coord_size = COORD_SIZE_XYZM;
            break;
            
        case POSTGIS_DIM_XYM:  /* XYM (2D with measure) */
            geom_data->geom_type = 0x0E;
            geom_data->coord_size = COORD_SIZE_XYM;
            break;
            
        default:
            /* Invalid dimension flags */
            return false;
    }
    
    /* Dimensions successfully determined */
    return true;
}



/* Constructs a bytea object containing the binary representation of a geometry. */
static bytea* 
construct_result_bytea(GeoDataInfo *geom_data, bool is_geography) 
{
    bytea *result;
    uint8 *result_data;
    
    /* Calculate total size needed for the result bytea: 4(SRID) + 2 ( GEOM TYPE) + coordinate size */
    int total_size = SRID_SIZE + GEOM_TYPE_SIZE + geom_data->coord_size;
    
    /* Allocate memory for the result bytea and set its size */
    result = (bytea *) palloc(VARHDRSZ + total_size);
    SET_VARSIZE(result, VARHDRSZ + total_size);
    
    /* Get pointer to the data portion of the bytea */
    result_data = (uint8 *)VARDATA(result);
    
    /* 
     * Handle SRID data:
     * - For geography objects or geometries with SRID flag set: copy SRID from source
     * - Otherwise if SRID is not present : set SRID to zero
     */
    if (is_geography || geom_data->has_srid) 
    {
        /* Copy SRID from source data (4 bytes starting at position 5) */
        memcpy(result_data , geom_data->byte_data + SRID_POSTGIS_POS, geom_data->srid_size);
    } else 
    {
        /* Set SRID to zero */
        memset(result_data , 0, geom_data->srid_size);
    }
    
    /* Set geometry type in header */
    result_data[GEOM_TYPE_POS_RESULT] = GEOM_TYPE_HEADER;
    result_data[GEOM_TYPE_POS_RESULT + 1] = geom_data->geom_type;
    
    /* Copy coordinate data based on whether the geometry is empty */
    if (geom_data->is_empty) 
    {
        /* For empty geometries, copy the empty coordinate pattern */
        memcpy(result_data + HEADER_SIZE, EMPTY_COORD, sizeof(EMPTY_COORD));
        
        /* 
         * For point geometries, set the type at the end of the coordinates
         * This identifies it as a point type in the empty geometry format
         */
        if (geom_data->byte_data[GEOM_TYPE_POS_POSTGIS] == POINT_TYPE)
            result_data[HEADER_SIZE + sizeof(EMPTY_COORD)] = POINT_TYPE;
    } 
    else 
    {
        /* 
         * For non-empty geometries, determine the source offset based on SRID presence
         * and copy the coordinate data from the source
         */
        int offset = (is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID;
        memcpy(result_data + HEADER_SIZE, geom_data->byte_data + offset, geom_data->coord_size);
    }
    
    return result;
}

/* Converts a PostGIS geometry object to its binary (bytea) representation. */
Datum 
bytea_from_geometry(PG_FUNCTION_ARGS) 
{
    GeoDataInfo *geom_data;  /* Structure to hold geometry information */
    bytea       *result;     /* Final binary representation */

    load_functions();
    
    /* Initialize geometry data structure from the input datum */
    geom_data = initialize_geom_data(PG_GETARG_DATUM(0));
   
    /* 
     * Validate that the geometry is a supported type (Point)
     * If validation fails, return the original binary representation
     */
    if (!validate_geom_type(geom_data)) 
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
    
    /* 
     * Determine the dimensions and coordinate size of the geometry
     * If dimension determination fails, return the original binary representation
     */
    if (!determine_geom_dimensions(geom_data))
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
   
    /* Construct the final binary representation */
    result = construct_result_bytea(geom_data, false);
    
    /* Free allocated memory */
    pfree(geom_data);
    
    /* Return the binary representation */
    PG_RETURN_BYTEA_P(result);
}

/* Converts a PostGIS geography object to its binary (bytea) representation. */
Datum 
bytea_from_geography(PG_FUNCTION_ARGS) 
{
    GeoDataInfo *geom_data;  /* Structure to hold geography information */
    bytea       *result;     /* Final binary representation */

    load_functions();
    
    /* Initialize geography data structure from the input datum */
    geom_data = initialize_geom_data(PG_GETARG_DATUM(0));
    
    /* 
     * Validate that the geography is a supported type (Point)
     * If validation fails, return the original binary representation
     */
    if (!validate_geom_type(geom_data)) 
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
    
    /* 
     * Determine the dimensions and coordinate size of the geography
     * If dimension determination fails, return the original binary representation
     */
    if (!determine_geom_dimensions(geom_data)) 
    {
        result = geom_data->byte;
        pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
    
    /* 
     * Construct the final binary representation
     * The 'true' parameter indicates this is a geography object,
     * which ensures the SRID is always included in the result
     */
    result = construct_result_bytea(geom_data, true);
    
    /* Free allocated memory */
    pfree(geom_data);
    
    /* Return the binary representation */
    PG_RETURN_BYTEA_P(result);
}

/* Common function to handle both geometry and geography conversion to binary */
static Datum 
st_as_binary_common(Datum input, bool is_geography) 
{
    Datum   modified_datum,   /* Intermediate modified geometry */
            result;           /* Final WKB result */
    bool    is_empty;         /* Flag indicating if geometry is empty */
    char   *geom_type;        /* String containing geometry type name */
    bytea  *empty_geom;       /* WKB representation for empty geometries */
    LOCAL_FCINFO(fcinfo_local, 1);  /* Local function call info */

    /* Initialize function call info for PostGIS function calls */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    load_functions();

    /* Check if the input geometry/geography is empty */
    UpdateFunctionCallInfo(fcinfo_local, 1, input);
    is_empty = DatumGetBool(st_isempty_p(fcinfo_local));

    if (is_empty) 
    {
        /* 
         * Handle empty geometry case:
         * 1. Get the geometry type name
         * 2. Create a custom WKB representation based on type
         */
        geom_type = GetGeometryTypeName(fcinfo_local, input);
        
        /* Allocate memory for empty WKB representation */
        empty_geom = palloc(VARHDRSZ + EMPTY_Binary_SIZE);
        SET_VARSIZE(empty_geom, VARHDRSZ + EMPTY_Binary_SIZE);
        
        /* Create appropriate WKB based on geometry type */
        if (strcmp(geom_type, "ST_Point" ) == 0) 
        {
            /* Copy empty point WKB pattern */
            memcpy(VARDATA(empty_geom), EMPTY_POINT_Binary, EMPTY_Binary_SIZE);
        }
        
        /* Free allocated memory and return the empty WKB */
        pfree(geom_type);
        return PointerGetDatum(empty_geom);
    }

    /* 
     * Process non-empty geometry:
     * 1. Convert to 2D (remove Z and M dimensions) to meet TSQL expectations
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, input);
    modified_datum = lwgeom_force_2d_p(fcinfo_local);

    if (is_geography) 
    {
        /* 
         * Additional step for geography: flip coordinates
         * This converts from longitude/latitude to latitude/longitude order
         */
        UpdateFunctionCallInfo(fcinfo_local, 1, modified_datum);
        modified_datum = st_flipcoordinates_p(fcinfo_local);
    }

    /* Convert to WKB format using PostGIS's internal binary conversion function */
    UpdateFunctionCallInfo(fcinfo_local, 1, modified_datum);
    result = lwgeom_asBinary_p(fcinfo_local);

    return result;
}

/* This function converts a PostGIS geometry to its WKB representation. */
Datum 
st_as_binary_geometry(PG_FUNCTION_ARGS) 
{
    /* Call common function with is_geography=false */
    return st_as_binary_common(PG_GETARG_DATUM(0), false);
}

/* This function converts a PostGIS geography to its WKB representation. */
Datum 
st_as_binary_geography(PG_FUNCTION_ARGS) 
{
    /* Call common function with is_geography=true */
    return st_as_binary_common(PG_GETARG_DATUM(0), true);
}

/* Converts a PostGIS geometry to its WKT (Well-Known Text) representation limited to 2D */
Datum
st_as_text(PG_FUNCTION_ARGS)
{
    Datum   geom,            /* Input geometry */
            forced_2d_geom,  /* 2D version of input geometry */
            result;          /* Final WKT result */
    LOCAL_FCINFO(fcinfo_local, 1);  /* Local function call info */

    /* Initialize function call info for PostGIS function calls */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);

    load_functions();

    /* Get input geometry object from function arguments */
    geom = PG_GETARG_DATUM(0);

    /* 
     * Convert input geometry to 2D
     * This removes any Z (elevation) or M (measure) dimensions
     * to meet TSQL expectations
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom);
    forced_2d_geom = lwgeom_force_2d_p(fcinfo_local);

    /* 
     * Convert 2D geometry to WKT format
     * Uses PostGIS's internal text conversion function (ST_AsText)
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, forced_2d_geom);
    result = lwgeom_astext_p(fcinfo_local);

    /* Return the WKT representation */
    PG_RETURN_DATUM(result);
}

/* Converts a PostGIS geometry to its WKT representation with custom formatting. */
Datum
geometry_astext(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;            /* Input geometry */
    text    *text_result,           /* Initial WKT text from PostGIS */
            *rewritten_text;        /* Processed WKT text after rewriting */
    LOCAL_FCINFO(fcinfo_local, 1);  /* Local function call info */

    /* Initialize function call info with collation for text processing */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    load_functions();

    /* Get input geometry object from function arguments */
    geom_datum = PG_GETARG_DATUM(0);

    /* 
     * Get standard WKT text representation of geometry
     * Uses PostGIS's internal text conversion function (ST_AsText)
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    text_result = DatumGetTextP(lwgeom_astext_p(fcinfo_local));

    /* 
     * Rewrite the WKT text using the geo_wkt_rewrite function
     * This applies custom formatting rules to the standard WKT
     */
    rewritten_text = geo_wkt_rewrite(text_result);

    /* Return the rewritten WKT representation */
    PG_RETURN_DATUM(PointerGetDatum(rewritten_text));
}

#endif
