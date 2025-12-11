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
#include "spatialtypes.h"

static void load_functions();

/*
 * Macros for identifying Z and M flags
 */
#define FLAG_Z         1 << 0
#define FLAG_M         1 << 1
#define MAX_DIMENSION_FLAG 4
#define POINT_TYPE     1  /* Identifier for Point geometry type */
#define LINE_TYPE      2  /* Identifier for Linestring geometry type */
#define POLYGON_TYPE   3  /* Identifier for Polygon geometry type */

#define DEFAULT_GEOGRAPHY_SRID 4326
#define DEFAULT_GEOMETRY_SRID  0
#define MIN_GEOMETRY_LENGTH    22  /* Minimum length for geometry data which 2D POINT */
#define MIN_MULTIPOINT_LINE_LENGTH        80  /* Minimum length for geometry data which 2D POINT */

#define COORD_SIZE     8      /* Size of each coordinate in bytes (double) */
#define HEADER_SIZE    6      /* Size of the geometry header in bytes */
#define XY_PER_POINT 2        /* Number of coordinates to check for NaN (X and Y) */
#define EMPTY_LINE_DATA_SIZE    4     /* Size of the geometry header in bytes */

#define DIM_FLAG_EMPTY       0       /* Dimension flag for Empty Point */
#define DIM_FLAG_2D          1       /* Dimension flag for 2D Point (XY) */
#define DIM_FLAG_3D          2       /* Dimension flag for 3D Point (XYZ) */
#define DIM_FLAG_2DM         3       /* Dimension flag for 2D Point with M (XYM) */
#define DIM_FLAG_3DM         4       /* Dimension flag for 3D Point with M (XYZM) */

#define POSTGIS_HEADER_SIZE      5      /* Size of the postgis header in bytes */
#define SRID_SIZE                4      /* Size of the SRID field in bytes */
#define HEADER_DIMENSION_POS     4      /* Position of dimension info in header */
#define EMPTY_POINT_TYPE_LASTBYTE    0x01    /* Type identifier for empty point */
#define EMPTY_LINE_TYPE_LASTBYTE     0x02    /* Type identifier for empty linestring */
#define NPOINTS_SIZE                 4       /* Size of no. of points data (4 bytes ) */
#define RING_COUNT_BYTES                          4       /* No. of rings in a polygon denoted by 4 bytes data packet */
#define CUMULATIVE_RING_COUNT_SIZE_BYTES          5       /* Size for intermediate cumulative ring counts (4 bytes + 1 zero) */
#define FINAL_CUMULATIVE_RING_COUNT_SIZE_BYTES    4       /* Size for final cumulative ring count (4 bytes only) */

#define SRID_FLAG_POS     4     /* Position of SRID flag in binary data */
#define SRID_MASK         0x20  /* Bitmask for SRID presence flag */
#define DIMENSION_MASK    0xC0  /* Bitmask for dimension flags */

/* Dimension type flags */
#define POSTGIS_DIM_XY            0x00 /* XY dimensions (2D) */
#define POSTGIS_DIM_XYZ           0x80 /* XYZ dimensions (3D) */
#define POSTGIS_DIM_XYZM          0xC0 /* XYZM dimensions (4D) */
#define POSTGIS_DIM_XYM           0x40 /* XYM dimensions (2D with measure) */

#define GEO_HEADER1   0x01  /* header byte used to denote geometry/geography datatypes type 1*/
#define GEO_HEADER2   0x02  /* header byte used to denote geometry/geography datatypes type 1*/

#define POINT_XY    0x0C  /* XY point geometry type ( subtype 12 -> TSQL's flag) */
#define POINT_XYZ   0x0D  /* XYZ point geometry type ( subtype 13 -> TSQL's flag) */
#define POINT_XYM   0x0E  /* XYM point geometry type (subtype 14 -> TSQL's flag) */
#define POINT_XYZM  0x0F  /* XYZM point geometry type ( subtype 15 -> TSQL's flag) */

/* Line geometry validation constants for multi-point (MP) linestrings */
#define INVALID_2DLINE_MP   0x00  /* Invalid 2D linestring with multiple points */
#define INVALID_3DLINE_MP   0x01  /* Invalid 3D linestring with multiple points */
#define INVALID_2DMLINE_MP  0x02  /* Invalid 2D linestring with M dimension and multiple points */
#define INVALID_3DMLINE_MP  0x03  /* Invalid 3D linestring with M dimension and multiple points */
#define VALID_2DLINE_MP     0x04  /* Valid 2D linestring with multiple points */
#define VALID_3DLINE_MP     0x05  /* Valid 3D linestring with multiple points */
#define VALID_2DMLINE_MP    0x06  /* Valid 2D linestring with M dimension and multiple points */
#define VALID_3DMLINE_MP    0x07  /* Valid 3D linestring with M dimension and multiple points */
#define POLYGON_2D          0x00  /* 2D Polygon - XY dimensions*/
#define POLYGON_3D          0x01  /* 3D Polygon - XYZ dimensions */
#define POLYGON_2DM         0x02  /* 2DM Polygon -  XYM dimensions*/
#define POLYGON_3DM         0x03  /* 3DM Polygon - XYZM dimensions*/


/* Line geometry validation constants for two-point (2P) linestrings */
#define INVALID_2DLINE_2P  0x10   /* Invalid 2D linestring with exactly 2 points */
#define INVALID_3DLINE_2P  0x11   /* Invalid 3D linestring with exactly 2 points */
#define INVALID_2DMLINE_2P 0x12   /* Invalid 2D linestring with M dimension and exactly 2 points */
#define INVALID_3DMLINE_2P 0x13   /* Invalid 3D linestring with M dimension and exactly 2 points */
#define VALID_2DLINE_2P    0x14   /* Valid 2D linestring with exactly 2 points */
#define VALID_3DLINE_2P    0x15   /* Valid 3D linestring with exactly 2 points */
#define VALID_2DMLINE_2P   0x16   /* Valid 2D linestring with M dimension and exactly 2 points */
#define VALID_3DMLINE_2P   0x17   /* Valid 3D linestring with M dimension and exactly 2 points */

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
#define INALID_GEOGRAPHY_HEADER    2   /* Header value for invalid geography objects */  

#define GEOM_TYPE_POS_POSTGIS  1   /* Position of geometry type in PostGIS binary data */
#define GEOM_TYPE_POS_RESULT   4   /* Position of geometry type in result data */

#define EMPTY_Binary_SIZE      9   /* Size of empty representation in binary */
#define EMPTY_POINT_Binary   "\x01\x04\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty point */
#define EMPTY_LINE_Binary    "\x01\x02\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty linestring */
#define EMPTY_POLYGON_Binary "\x01\x03\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty polygon */
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
    uint32_t input_len;
    int32_t  srid;
    int32_t  npoints;
    uint8_t  geom_type;
    uint8_t  geom_class;
    uint8    geom_name;
    uint8    dimension_flag;
    bool     isNaN;
    bool     has_npoints_data;  
} GeometryData;

/* Helper structure for geometry to bytea conversion */
typedef struct 
{
    Datum    geom_datum;    /* Input geometry/geography datum */
    bytea   *byte;          /* Binary representation */
    uint8   *byte_data;     /* Raw binary data pointer */
    uint8    srid_flag;     /* SRID and dimension flags */
    uint8    geom_type;     /* Point dimension type */
    bool     is_empty;      /* Flag indicating empty geometry */
    bool     is_valid;      /* Flag indicating valid geometry */
    bool     has_srid;      /* Flag indicating SRID presence */
    uint8    postgis_geom_type;   /* 2nd byte of byte_data */
    uint32_t byte_len;  /* Length of binary data */
    uint32_t srid_size; /* Size of SRID data (4 bytes) */
    uint32_t coord_size;/* Size of coordinate data */
    int npoints;   /* Number of points in geometry */
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

/* 
 * Trailing metadata appended to linestring instances with more than 2 points.
 * Required by T-SQL's spatial format for linestring geometry type (0x02).
 */
static const uint8 
line_end_metadata[] = {
    0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x00, 0x00, 0x00, 0x02
};

/* 
 * Trailing metadata appended to polygon instances.
 * Required by T-SQL's spatial format for polygon geometry type (0x03).
 */
static const uint8 
polygon_end_metadata[] = {
    0x01, 0x00, 0x00, 0x00,
    0xff, 0xff, 0xff, 0xff, 
    0x00, 0x00, 0x00, 0x00, 0x03
};

/* 
 * Identifier for multi-ring polygons in T-SQL spatial format.
 * Used when polygon has multiple rings (exterior + interior rings).
 */
static const uint8 
poly_identifier_multiring[] = {
    0x02, 0x00, 0x00, 0x00, 0x00, 0x00
};

/* 
 * Identifier for single-ring polygons in T-SQL spatial format.
 * Used when polygon has only one ring (exterior ring only).
 */
static const uint8 
poly_identifier_singlering[] = {
    0x02, 0x00, 0x00, 0x00, 0x00
};

/* NAN format used by TSQL */
static const uint8 
SPECIFIC_NAN[COORD_SIZE] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0xff
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
    if (strcmp(geom_type, "ST_Point") != 0 &&
        strcmp(geom_type, "ST_LineString") != 0 &&
        strcmp(geom_type, "ST_Polygon") != 0)
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

typedef Datum (*lwgeom_y_t)(PG_FUNCTION_ARGS);
static lwgeom_y_t lwgeom_y_p;

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

typedef Datum (*st_npoints_t)(PG_FUNCTION_ARGS);
static st_npoints_t st_npoints_p;

typedef Datum (*st_pointn_t)(PG_FUNCTION_ARGS);
static st_pointn_t st_pointn_p;

typedef Datum (*st_isvalid_t)(PG_FUNCTION_ARGS);
static st_isvalid_t st_isvalid_p;

typedef Datum (*st_exteriorring_t)(PG_FUNCTION_ARGS);
static st_exteriorring_t st_exteriorring_p;

typedef Datum (*st_interiorringn_t)(PG_FUNCTION_ARGS);
static st_interiorringn_t st_interiorringn_p;

typedef Datum (*st_numinteriorrings_t)(PG_FUNCTION_ARGS);
static st_numinteriorrings_t st_numinteriorrings_p;

static void validate_geography_latitude(Datum geom_datum, bool is_flipped);

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
PG_FUNCTION_INFO_V1(geometry_asbpchar);
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
        lwgeom_y_p = (lwgeom_y_t) load_external_function("$libdir/postgis-3", "LWGEOM_y_point", true, NULL);
        lwgeom_from_text_p = (lwgeom_from_text_t) load_external_function("$libdir/postgis-3", "LWGEOM_from_text", true, NULL);
        lwgeom_from_bytea_p = (lwgeom_from_bytea_t) load_external_function("$libdir/postgis-3", "LWGEOM_from_bytea", true, NULL);
        lwgeom_to_bytea_p = (lwgeom_to_bytea_t) load_external_function("$libdir/postgis-3", "LWGEOM_to_bytea", true, NULL);
        st_flipcoordinates_p = (st_flipcoordinates_t) load_external_function("$libdir/postgis-3", "ST_FlipCoordinates", true, NULL);
        st_point_p = (st_point_t) load_external_function("$libdir/postgis-3", "ST_Point", true, NULL);
        st_isempty_p = (st_isempty_t) load_external_function("$libdir/postgis-3", "LWGEOM_isempty", true, NULL);
        lwgeom_force_2d_p = (lwgeom_force_2d_t) load_external_function("$libdir/postgis-3", "LWGEOM_force_2d", true, NULL);
        lwgeom_asBinary_p = (lwgeom_asBinary_t) load_external_function("$libdir/postgis-3", "LWGEOM_asBinary", true, NULL);
        lwgeom_astext_p = (lwgeom_astext_t) load_external_function("$libdir/postgis-3", "LWGEOM_asText", true, NULL);
        st_npoints_p = (st_npoints_t) load_external_function("$libdir/postgis-3", "LWGEOM_npoints", true, NULL);
        st_pointn_p = (st_pointn_t) load_external_function("$libdir/postgis-3", "LWGEOM_pointn_linestring", true, NULL);
        st_isvalid_p = (st_isvalid_t) load_external_function("$libdir/postgis-3", "isvalid", true, NULL); 
        st_exteriorring_p = (st_exteriorring_t) load_external_function("$libdir/postgis-3", "LWGEOM_exteriorring_polygon", true, NULL);
        st_interiorringn_p = (st_interiorringn_t) load_external_function("$libdir/postgis-3", "LWGEOM_interiorringn_polygon", true, NULL);
        st_numinteriorrings_p = (st_numinteriorrings_t) load_external_function("$libdir/postgis-3", "LWGEOM_numinteriorrings_polygon", true, NULL); 
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

/*
 * Validates that the given latitude value is within the valid range of -90 to 90 degrees.
 * Throws an error if the latitude is outside this range.
 */
static void
validate_latitude_range(double lat)
{
    if (lat < -90.0 || lat > 90.0)
    {
        ereport(ERROR,
            (errcode(ERRCODE_DATA_EXCEPTION),
             errmsg("Latitude values must be between -90 and 90 degrees")));
    }
}

/*
 * Check for antipodal points and update previous coordinates
 */
static void
check_antipodal_points(FunctionCallInfoBaseData *fcinfo, Datum point, int point_index, 
                      float8 *prev_lat, float8 *prev_lon)
{
    float8 lat, lon;
    
    /* Get latitude (x coordinate after flipping) */
    UpdateFunctionCallInfo(fcinfo, 1, point);
    lat = DatumGetFloat8(lwgeom_x_p(fcinfo));

    /* Get longitude (y coordinate after flipping) */
    UpdateFunctionCallInfo(fcinfo, 1, point);
    lon = DatumGetFloat8(lwgeom_y_p(fcinfo));
    
    if (point_index > 1)
    {  
        /* Check for antipodal points */
        if (fabs(fabs(lon - *prev_lon) - 180.0) < 0.1 || fabs(fabs(lat - *prev_lat) - 180.0) < 0.1)
        {
            ereport(ERROR,
                (errcode(ERRCODE_DATA_EXCEPTION),
                 errmsg("The specified input cannot be accepted because it contains an edge with antipodal points")));
        }
        
        *prev_lat = lat;
        *prev_lon = lon;
    }
    else
    {
        /* First point - initialize previous coordinates */
        UpdateFunctionCallInfo(fcinfo, 1, point);
        *prev_lat = lat;
        *prev_lon = DatumGetFloat8(lwgeom_y_p(fcinfo));
    }
}

/*
 * Validates that all latitude values in a geometry are within valid range (-90 to 90 degrees).
 */
static void 
validate_geography_latitude(Datum geom_datum, bool is_flipped)
{
    LOCAL_FCINFO(fcinfo_local, 2);  /* Local function call info with max 2 args */
    char *geom_type;
    Datum flipped_geom;
    float8 lat;
    int npoints;
    int i;
    Datum point;

    /* Initialize function call info */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    
    /* Get geometry type name using helper function */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);
    
    if (!is_flipped) 
    {
        /* For text format, flip coordinates before validation (x,y becomes y,x) */
        UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
        flipped_geom = st_flipcoordinates_p(fcinfo_local);
    } 
    else 
    {
        /* Coordinates are already flipped, use as-is */
        flipped_geom = geom_datum;
    }

    if (strcmp(geom_type, "ST_Point") == 0) 
    {
        /* Check single point latitude - after flipping, x coordinate is latitude */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));
        
        /* Validate latitude is within -90 to 90 degrees range */
        validate_latitude_range(lat);
    } 
    else if (strcmp(geom_type, "ST_LineString") == 0) 
    {
        float8 prev_lat = 0, prev_lon = 0;

        /* Get total number of points in the linestring */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        npoints = DatumGetInt32(st_npoints_p(fcinfo_local));
        
        /* Check each point in the linestring */
        for (i = 1; i <= npoints; i++) 
        {
            /* Extract the i-th point from the linestring */
            UpdateFunctionCallInfo(fcinfo_local, 2, flipped_geom, Int32GetDatum(i));
            point = st_pointn_p(fcinfo_local);
            
            /* Get latitude value (x coordinate after flipping) */
            UpdateFunctionCallInfo(fcinfo_local, 1, point);
            lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));
            
            /* Validate latitude is within -90 to 90 degrees range */
            validate_latitude_range(lat);
            
            /* Check for antipodal points */
            check_antipodal_points(fcinfo_local, point, i, &prev_lat, &prev_lon);
        }
    }
    else if (strcmp(geom_type, "ST_Polygon") == 0)
    {
        Datum exterior_ring,
              interior_ring;
        int num_interior_rings,
            ring_idx;
        float8 prev_lat = 0, prev_lon = 0;
        
        /* 
         * Validate exterior ring of the polygon
         * Extract the outer boundary ring and check all its points
         */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        exterior_ring = st_exteriorring_p(fcinfo_local);
        
        /* Get total number of points in the exterior ring */
        UpdateFunctionCallInfo(fcinfo_local, 1, exterior_ring);
        npoints = DatumGetInt32(st_npoints_p(fcinfo_local));
        
        /* Check each point in the exterior ring for valid latitude */
        for (i = 1; i <= npoints; i++)
        {
            /* Extract the i-th point from the exterior ring */
            UpdateFunctionCallInfo(fcinfo_local, 2, exterior_ring, Int32GetDatum(i));
            point = st_pointn_p(fcinfo_local);
            
            /* Get latitude value (x coordinate after flipping) */
            UpdateFunctionCallInfo(fcinfo_local, 1, point);
            lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));
            
            /* Validate latitude is within -90 to 90 degrees range */
            validate_latitude_range(lat);
            /* Check for antipodal points */
            check_antipodal_points(fcinfo_local, point, i, &prev_lat, &prev_lon);
        }
        
        /* 
         * Validate interior rings (holes) of the polygon
         * Each interior ring represents a hole within the polygon
         */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        num_interior_rings = DatumGetInt32(st_numinteriorrings_p(fcinfo_local));
        
        /* Iterate through each interior ring */
        for (ring_idx = 1; ring_idx <= num_interior_rings; ring_idx++)
        {
            /* Extract the ring_idx-th interior ring */
            UpdateFunctionCallInfo(fcinfo_local, 2, flipped_geom, Int32GetDatum(ring_idx));
            interior_ring = st_interiorringn_p(fcinfo_local);
            
            /* Get total number of points in this interior ring */
            UpdateFunctionCallInfo(fcinfo_local, 1, interior_ring);
            npoints = DatumGetInt32(st_npoints_p(fcinfo_local));
            
            /* Check each point in the interior ring for valid latitude */
            for (i = 1; i <= npoints; i++)
            {
                /* Extract the i-th point from the interior ring */
                UpdateFunctionCallInfo(fcinfo_local, 2, interior_ring, Int32GetDatum(i));
                point = st_pointn_p(fcinfo_local);
                
                /* Get latitude value (x coordinate after flipping) */
                UpdateFunctionCallInfo(fcinfo_local, 1, point);
                lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));
                
                /* Validate latitude is within -90 to 90 degrees range */
                validate_latitude_range(lat);
                /* Check for antipodal points */
                check_antipodal_points(fcinfo_local, point, i, &prev_lat, &prev_lon);
            }
        }
    }
    
    /* Free allocated memory */
    if (geom_type)
        pfree(geom_type);
    /* Other geometry types are not validated in this function */
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

    /* Free allocated memory */
    if (geometry_name)
        pfree(geometry_name);
    if (!is_binary_format) 
    {
        pfree(rewritten_wkt_text);
        pfree(rewritten_cstring);
    }

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
     * Validate latitude values
     * Geography objects require latitude values between -90 and 90 degrees
     * here,we don't flip coordinates as it's already done above
     */
    validate_geography_latitude(geog_datum, true);

    /* Free allocated memory */
    if (geography_name)
        pfree(geography_name);
    if (!is_binary_format) 
    {
        pfree(rewritten_wkt_text);
        pfree(rewritten_cstring);
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

    /* Free allocated memory */
    if (geom_type)
        pfree(geom_type);
    pfree(rewritten_wkt_text);

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
                flipped_geom_datum; /* Geometry with flipped coordinates */
    text       *rewritten_wkt_text; /* Processed WKT text */          
    char       *geom_type;          /* String representation of geometry type */
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

    /* Validate latitude values using helper function */
    validate_geography_latitude(geom_datum, false);

    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    flipped_geom_datum = st_flipcoordinates_p(fcinfo_local);

    /* Free allocated memory */
    if (geom_type)
        pfree(geom_type);
    pfree(rewritten_wkt_text);

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
    int i;
    LOCAL_FCINFO(fcinfo_local, 3); /* Local function call info with 3 arguments */

    /* Initialize function call info once */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 3, InvalidOid, NULL, NULL);

    for (i = 0; i < 3; i++)    
        if (PG_ARGISNULL(i))
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("'geography::Point' failed because parameter %d is not allowed to be null.", i+1)));

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
    validate_latitude_range(lat);

    /* Create the point using helper function */
    UpdateFunctionCallInfo(fcinfo_local, 3,
                         Float8GetDatum(lat),
                         Float8GetDatum(lon),
                         Int32GetDatum(srid));
    result = st_point_p(fcinfo_local);

    PG_RETURN_DATUM(result);
}

/* Helper function implementations for char to geometry/geography conversions */

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
            validate_geography_latitude(geom_datum, false);
        }
    }

    /* Free allocated memory */
    if (geom_type)
        pfree(geom_type);
    pfree(rewritten_wkt_text);

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

/*
 * BYTEA TO GEOMETRY/GEOGRAPHY CONVERSION FLOW:
 * 
 * Input: Binary data (bytea) containing spatial geometry information
 * Output: PostGIS geometry/geography object
 * 
 * STEP 1: INPUT VALIDATION AND INITIALIZATION
 * ├── validate_input_length()        - Ensure minimum bytea length (22 bytes for 2D point)
 * └── initialize_geometry_data()     - Parse binary header and extract metadata
 *     ├── Extract SRID (4 bytes)     - Spatial Reference System ID
 *     ├── Extract geometry type      - Point, LineString, etc.
 *     ├── Extract npoints data       - Number of points (for multi-point geometries)
 *     └── Initialize flags           - has_npoints_data, dimension_flag, isNaN
 * 
 * STEP 2: GEOMETRY TYPE ANALYSIS
 * └── set_dimension_flag()           - Determine geometry type and dimensions
 *     ├── Validate geometry headers  - Check for valid geometry class bytes
 *     ├── Handle empty geometries    - Detect EMPTY_COORD patterns
 *     ├── Process point types        - POINT_XY, POINT_XYZ, POINT_XYM, POINT_XYZM
 *     └── Process linestring types   - 2-point vs multi-point linestrings
 *         ├── 2D linestrings         - XY coordinates only
 *         ├── 3D linestrings         - XYZ coordinates
 *         ├── 2DM linestrings        - XY + M (measure) coordinates
 *         └── 3DM linestrings        - XYZ + M coordinates
 * 
 * STEP 3: COORDINATE VALIDATION
 * └── check_nan_coordinates()        - Scan coordinate data for NaN values
 *     ├── Determine scan parameters  - Starting position and coordinate count
 *     ├── Extract coordinate values  - Copy bytes to double values
 *     └── Validate using isnan()     - Set isNaN flag if NaN detected
 * 
 * STEP 4: SPATIAL CONSTRAINTS (Geography only)
 * └── validate_geography_latitude_bytes() - Validate latitude constraints
 *     ├── Extract latitude values    - From XY coordinate pairs
 *     ├── Convert byte order         - Little-endian to host order
 *     ├── Validate SRID              - Check for valid geography SRID
 *     └── Validate latitude range    - Must be between -90 and +90 degrees
 * 
 * STEP 5: FINAL VALIDATION
 * ├── Validate SRID range           - Must be 0-999999
 * ├── Check for NaN coordinates     - Reject if NaN values found
 * └── Validate geography constraints - Additional checks for geography type
 * 
 * STEP 6: POSTGIS FORMAT CONVERSION
 * └── process_geometry_data()        - Convert to PostGIS-compatible format
 *     ├── handle_empty_geometry_bytea()  - Process empty geometries
 *     │   ├── create_empty_point()       - Generate empty point with NaN coords
 *     │   └── create_empty_linestring()  - Generate empty linestring with zeros
 *     └── handle_non_empty_geometry_bytea() - Process non-empty geometries
 *         ├── calculate_linestring_size() - Compute required buffer size
 *         ├── calculate_point_size()      - Compute required buffer size
 *         ├── Setup PostGIS headers       - Add PostGIS-specific headers
 *         ├── handle_linestring_coordinates() - Process linestring data
 *         │   ├── Write point count       - Add npoints to output
 *         │   └── copy_coordinates_with_dimensions() - Copy coordinate data
 *         │       ├── Copy XY coordinates - Base coordinate pairs
 *         │       ├── Copy Z coordinates  - Height/elevation data
 *         │       └── Copy M coordinates  - Measure/linear referencing
 *         └── handle_point_coordinates() - Simple coordinate copy for points
 * 
 * STEP 7: POSTGIS OBJECT CREATION
 * ├── UpdateFunctionCallInfo()       - Prepare function call context
 * ├── lwgeom_from_bytea_p()         - Convert bytea to PostGIS object
 * └── Return geometry/geography      - Final spatial object
 */

/* Helper function implementations for bytea to geometry/geography conversions */

/* STEP 1.1: INPUT VALIDATION - Validates that the input bytea has sufficient length to be a valid geometry  which is 22 for 2D Point (smallest possible geometry) */
static void 
validate_input_length(const bytea *input, const char *type_name) 
{
    if (VARSIZE_ANY_EXHDR(input) < MIN_GEOMETRY_LENGTH) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid %s", type_name)));
    }
}

/* STEP 1.2: INITIALIZATION - Initializes a GeometryData structure from a bytea input.
 *
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
    geom_data->geom_class = geom_data->input_data[4];
    geom_data->geom_type = geom_data->input_data[5];
    
    /* Extract number of points data from next 4 bytes (little-endian) : 7th to 10th , we are using it only when has_npoints_data is set true */
    geom_data->npoints = (geom_data->input_data[9] << 24) | 
                         (geom_data->input_data[8] << 16) | 
                         (geom_data->input_data[7] << 8) | 
                          geom_data->input_data[6];
    
    /* 
     * Initialise has_npoints_data to validate if npoints info is present in input (present when npoints > 2).
     * Initialise geom_name to set later ( 1 for point, 2 for linestring, etc.)
     */
    geom_data->has_npoints_data= false;
    geom_data->geom_name = 0;
    /* Initialize dimension flag and NaN indicator to zero */
    geom_data->dimension_flag = 0;
    geom_data->isNaN = false;
    
    return geom_data;
}

/* STEP 2: GEOMETRY TYPE ANALYSIS - Set dimension flag based on geometry type */
static void 
set_dimension_flag(GeometryData *geom_data) 
{

    if (geom_data->geom_class != GEO_HEADER1 && geom_data->geom_class != GEO_HEADER2)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Unsupported geometry type")));
    }

    switch (geom_data->geom_type) 
    {
        case 0x04:
            /* If EMPTY_COORD data is present then it represents Empty geometries */                               
            if ( memcmp(geom_data->input_data + HEADER_SIZE, EMPTY_COORD, sizeof(EMPTY_COORD)) == 0)
            {
                geom_data->dimension_flag = 0;
            }
            else /* case for 2D LINESTRING  with more than 2 points */
            {
                geom_data->dimension_flag = DIM_FLAG_2D;  /* Has 2D Points (XY) */
                geom_data->geom_name = LINE_TYPE;
                geom_data->has_npoints_data = true;

                if (geom_data->input_len < MIN_MULTIPOINT_LINE_LENGTH)
                {
                    ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                         errmsg("Unsupported geometry type")));
                }
            }
            break;
        /* Simple point cases - only set dimension flag */
        case POINT_XY: 
            geom_data->dimension_flag = DIM_FLAG_2D; /* 2D Point (XY) */
            break;
        case POINT_XYZ: 
            geom_data->dimension_flag = DIM_FLAG_3D; /* 3D Point (XYZ) */
            break;
        case POINT_XYM: 
            geom_data->dimension_flag = DIM_FLAG_2DM; /* 2D Point with M (XYM) */
            break;
        case POINT_XYZM: 
            geom_data->dimension_flag = DIM_FLAG_3DM; /* 3D Point with M (XYZM) */
            break;
            
        /* Linestring Cases with more than 2 points */
        case INVALID_2DLINE_MP:
            geom_data->dimension_flag = DIM_FLAG_2D; /* Has 2D Points (XY) */
            geom_data->geom_name = LINE_TYPE;
            geom_data->has_npoints_data = true;
            break;
        case INVALID_3DLINE_MP: 
        case VALID_3DLINE_MP:
            geom_data->dimension_flag = DIM_FLAG_3D; /* Has 3D Points (XYZ) */
            geom_data->geom_name = LINE_TYPE;
            geom_data->has_npoints_data = true; 
            break;
        case INVALID_2DMLINE_MP: 
        case VALID_2DMLINE_MP:
            geom_data->dimension_flag = DIM_FLAG_2DM; /* Has 2D Points with M (XYM) */
            geom_data->geom_name = LINE_TYPE;
            geom_data->has_npoints_data = true; 
            break;
        case INVALID_3DMLINE_MP: 
        case VALID_3DMLINE_MP:
            geom_data->dimension_flag = DIM_FLAG_3DM; /* Has 3D Points with M (XYZM) */
            geom_data->geom_name = LINE_TYPE;
            geom_data->has_npoints_data = true; 
            break;
            
        /* Linestring Cases with 2 points */
        case INVALID_2DLINE_2P: 
        case VALID_2DLINE_2P:
            geom_data->dimension_flag = DIM_FLAG_2D; /* Has 2D Points (XY) */
            geom_data->geom_name = LINE_TYPE;
            break;
        case INVALID_3DLINE_2P: 
        case VALID_3DLINE_2P:
            geom_data->dimension_flag = DIM_FLAG_3D; /* Has 3D Points (XYZ) */
            geom_data->geom_name = LINE_TYPE;
            break;
        case INVALID_2DMLINE_2P: 
        case VALID_2DMLINE_2P:
            geom_data->dimension_flag = DIM_FLAG_2DM; /* Has 2D Points with M (XYM) */
            geom_data->geom_name = LINE_TYPE;
            break;
        case INVALID_3DMLINE_2P: 
        case VALID_3DMLINE_2P:
            geom_data->dimension_flag = DIM_FLAG_3DM; /* Has 3D Points with M (XYZM) */
            geom_data->geom_name = LINE_TYPE;
            break;
        default:
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Unsupported geometry type")));
    }
}

/* STEP 3: COORDINATE VALIDATION - Checks if coordinates in the geometry data contain NaN values.
 * 
 * This function examines coordinate values in the binary data to detect NaN values.
 * The number of coordinates checked and the starting position depend on the geometry type:
 * - For linestrings with npoints data: Checks npoints * 2 coordinates starting after header+npoints
 * - For linestrings without npoints data: Checks 4 coordinates (2 points) starting after header
 * - For point : Checks XY_PER_POINT coordinates starting after header
 */
static void 
check_nan_coordinates(GeometryData *geom_data) 
{
    double coord_value;
    uint32_t byte_position;
    uint32_t check_count;
    int i;
    
    /* Determine starting position and count based on geometry type */
    if (geom_data->geom_name == LINE_TYPE) 
    {
        if (geom_data->has_npoints_data) 
        {
            byte_position = HEADER_SIZE + NPOINTS_SIZE;  /* Skip header and npoints */
            check_count = geom_data->npoints * 2;  /* Check all X,Y pairs */
        } 
        else 
        {
            byte_position = HEADER_SIZE;  /* Start after header */
            check_count = XY_PER_POINT * 2;  /* Check 2 points (4 coordinates) */
        }
    } 
    else 
    {
        byte_position = HEADER_SIZE;  /* Start after header */
        check_count = XY_PER_POINT;  /* Default: check X,Y coordinates */
    }
    
    /* Check coordinates for NaN values */
    for (i = 0; i < check_count; i++) 
    {
        /* Copy the coordinate bytes to a double value */
        memcpy(&coord_value, geom_data->input_data + byte_position, COORD_SIZE);
        
        /* Use isnan() to check for NaN value */
        if (isnan(coord_value)) 
        {
            /* Set the NaN flag if a NaN is found */
            geom_data->isNaN = true;
            break;
        }
        
        /* Move to the next coordinate */
        byte_position += COORD_SIZE;
    }
}

/* STEP 4: SPATIAL CONSTRAINTS - Validates latitude values for geography data */
static void
validate_geography_latitude_bytes(GeometryData *geom_data)
{
    int i;
    double lat;
    uint64_t lat_bits;
    uint32_t point_size = COORD_SIZE * 2; /* Size of XY coordinates (2 doubles) */
    
    if (geom_data->geom_name == LINE_TYPE) /* LineString */
    {
        int point_count = geom_data->has_npoints_data ? geom_data->npoints : 2;
        uint32_t offset = geom_data->has_npoints_data ? HEADER_SIZE + NPOINTS_SIZE : HEADER_SIZE;
        
        /* Check each point in the linestring */
        for (i = 0; i < point_count; i++) 
        {
            /* Extract latitude value for this point */
            memcpy(&lat_bits, geom_data->input_data + offset + (i * point_size), sizeof(uint64_t));
            lat_bits = le64toh(lat_bits);  /* Convert from little-endian to host byte order */
            memcpy(&lat, &lat_bits, sizeof(double));
            
            /* Check if latitude is outside valid range */
            if (!is_valid_geography_srid(geom_data->srid) || 
                geom_data->isNaN || 
                lat < -90.0 || 
                lat > 90.0) 
            {
                ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("Error converting data type varbinary to geography.")));
            }
        }
    }
    else /* Point or other geometry types */
    {
        memcpy(&lat_bits, geom_data->input_data + HEADER_SIZE, sizeof(uint64_t));
        lat_bits = le64toh(lat_bits);  /* Convert from little-endian to host byte order */
        memcpy(&lat, &lat_bits, sizeof(double));

        /* Validate geography-specific constraints */
        if (!is_valid_geography_srid(geom_data->srid) || 
            geom_data->isNaN || 
            lat < -90.0 || 
            lat > 90.0) 
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("Error converting data type varbinary to geography.")));
        }
    }
}

/* STEP 6.1: SIZE CALCULATION - Calculate required buffer size for linestring geometries */
static uint32_t
calculate_linestring_size(GeometryData *geom_data)
{
    return geom_data->has_npoints_data ? 
        geom_data->input_len - GEOM_TYPE_SIZE + POSTGIS_HEADER_SIZE - sizeof(line_end_metadata) :
        geom_data->input_len - GEOM_TYPE_SIZE + POSTGIS_HEADER_SIZE + NPOINTS_SIZE;
}

/* STEP 6.2: SIZE CALCULATION - Calculate required buffer size for point geometries */
static uint32_t
calculate_point_size(GeometryData *geom_data)
{
    return geom_data->input_len - GEOM_TYPE_SIZE + POSTGIS_HEADER_SIZE;
}

/* STEP 6.3: COORDINATE COPYING - Copy coordinate data with proper handling of Z and M dimensions */
static void
copy_coordinates_with_dimensions(uint8_t *src, uint8_t *dst, uint32_t npoints, uint32_t dimension_flag)
{
    bool has_z = dimension_flag == DIM_FLAG_3DM || dimension_flag == DIM_FLAG_3D;
    bool has_m = dimension_flag == DIM_FLAG_3DM || dimension_flag == DIM_FLAG_2DM;
    uint32_t stride = COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0) + (has_m ? COORD_SIZE : 0);
    int i;
    
    for (i = 0; i < npoints; i++) 
    {
        /* Copy XY coordinates */
        memcpy(dst + (i * stride), src + (i * COORD_SIZE * 2), COORD_SIZE * 2);
        
        /* Copy Z coordinates if present */
        if (has_z) 
        {
            memcpy(dst + (i * stride) + COORD_SIZE * 2, 
                   src + (npoints * COORD_SIZE * 2) + (i * COORD_SIZE), COORD_SIZE);
        }
        
        /* Copy M coordinates if present */
        if (has_m) 
        {
            memcpy(dst + (i * stride) + COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0),
                   src + (npoints * COORD_SIZE * 2) + (has_z ? npoints * COORD_SIZE : 0) + (i * COORD_SIZE), COORD_SIZE);
        }
    }
}

/* STEP 6.4: LINESTRING PROCESSING - Process linestring coordinate data and write point count */
static void
handle_linestring_coordinates(GeometryData *geom_data, uint8 *result_data)
{
    uint32_t npoints = geom_data->has_npoints_data ? geom_data->npoints : 2;
    uint8_t *src = geom_data->input_data + HEADER_SIZE + (geom_data->has_npoints_data ? NPOINTS_SIZE : 0);
    uint8_t *dst = result_data + POSTGIS_HEADER_SIZE + SRID_SIZE + NPOINTS_SIZE;
    
    /* Write number of points */
    memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, &npoints, NPOINTS_SIZE);
    
    /* Copy coordinates with proper handling of Z and M dimensions */
    copy_coordinates_with_dimensions(src, dst, npoints, geom_data->dimension_flag);
}

/* STEP 6.5: POINT PROCESSING - Simple coordinate copy for point geometries */
static void
handle_point_coordinates(GeometryData *geom_data, uint8 *result_data)
{
    memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, 
           geom_data->input_data + HEADER_SIZE, 
           geom_data->input_len - HEADER_SIZE);
}

/* STEP 6.6: NON-EMPTY GEOMETRY PROCESSING - Convert non-empty geometries to PostGIS format */
static bytea*
handle_non_empty_geometry_bytea(GeometryData *geom_data)
{
    uint8 postgis_header[POSTGIS_HEADER_SIZE] = "\x01\x01\x00\x00\x20";
    bytea *result;
    uint8 *result_data;
    uint32_t new_data_size;
    
    /* Update dimension information in header */
    if (geom_data->dimension_flag <= MAX_DIMENSION_FLAG) 
    {
        postgis_header[HEADER_DIMENSION_POS] = DIMENSION_HEADERS[geom_data->dimension_flag];
    }
    
    /* Calculate new data size and set geometry type */
    if (geom_data->geom_name == LINE_TYPE) 
    {
        postgis_header[1] = 0x02;
        new_data_size = calculate_linestring_size(geom_data);
    } 
    else 
    {
        new_data_size = calculate_point_size(geom_data);
    }
    
    /* Allocate memory and set size */
    result = (bytea *) palloc(VARHDRSZ + new_data_size);
    SET_VARSIZE(result, VARHDRSZ + new_data_size);
    result_data = (uint8 *)VARDATA(result);
    
    /* Copy header and SRID */
    memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
    
    /* Handle coordinate data copying */
    if (geom_data->geom_name == LINE_TYPE) 
    {
        handle_linestring_coordinates(geom_data, result_data);
    } 
    else 
    {
        handle_point_coordinates(geom_data, result_data);
    }

    return result;
}

/* STEP 6.7: EMPTY POINT CREATION - Generate empty point with NaN coordinates */
static bytea*
create_empty_point(GeometryData *geom_data)
{
    uint8 postgis_header[POSTGIS_HEADER_SIZE] = "\x01\x01\x00\x00\x20";
    bytea *result = (bytea *) palloc(VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE * 2);
    uint8 *result_data;
    
    SET_VARSIZE(result, VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE * 2);
    result_data = (uint8 *)VARDATA(result);
    
    memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, NAN_COORD, COORD_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE, NAN_COORD, COORD_SIZE);
    
    return result;
}

/* STEP 6.8: EMPTY LINESTRING CREATION - Generate empty linestring with zero data */
static bytea*
create_empty_linestring(GeometryData *geom_data)
{
    uint8 postgis_header[POSTGIS_HEADER_SIZE] = "\x01\x02\x00\x00\x20";
    bytea *result = (bytea *) palloc(VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + EMPTY_LINE_DATA_SIZE);
    uint8 *result_data;
    
    SET_VARSIZE(result, VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + EMPTY_LINE_DATA_SIZE);
    result_data = (uint8 *)VARDATA(result);
    
    memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
    memset(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, 0, EMPTY_LINE_DATA_SIZE);
    
    return result;
}

/* STEP 6.9: EMPTY GEOMETRY PROCESSING - Process empty geometries and delegate to appropriate handlers */
static bytea*
handle_empty_geometry_bytea(GeometryData *geom_data)
{
    uint8 last_emptybyte;
    
    /* Validate empty geometry format */
    if (memcmp(geom_data->input_data + HEADER_SIZE, EMPTY_COORD, sizeof(EMPTY_COORD)) != 0) 
    {
        ereport(ERROR,
            (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Unsupported geometry type")));
    }
    
    last_emptybyte = geom_data->input_data[sizeof(EMPTY_COORD) + HEADER_SIZE];
    
    switch(last_emptybyte) 
    {
        case EMPTY_POINT_TYPE_LASTBYTE:
            return create_empty_point(geom_data);
        case EMPTY_LINE_TYPE_LASTBYTE:
            return create_empty_linestring(geom_data);
        default:
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Unsupported geometry type")));
            return NULL;
    }
}

/* STEP 6.10: GEOMETRY DATA PROCESSING - Main dispatcher for empty vs non-empty geometry processing */
static bytea* 
process_geometry_data(GeometryData *geom_data) 
{
    return (geom_data->dimension_flag == DIM_FLAG_EMPTY) ? 
           handle_empty_geometry_bytea(geom_data) : 
           handle_non_empty_geometry_bytea(geom_data);
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

    /* Determine the dimension flag based on geometry type */
    set_dimension_flag(geom_data);

    /* Check for NaN values in coordinates */
    if (geom_data->dimension_flag != 0)
        check_nan_coordinates(geom_data);

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
    if (geom_data)
        pfree(geom_data);
    
    /* Return the PostGIS geometry object */
    return geometry_result;
}

/* Converts a binary (bytea) representation to a PostGIS geography object. */
Datum 
geography_from_bytea(PG_FUNCTION_ARGS)
{
    bytea   *result,            /* Processed binary data */
            *input;             /* Input binary data */
    Datum   geography_result;   /* Final PostGIS geography object */
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
    
    /* Determine the dimension flag based on geometry type */
    set_dimension_flag(geom_data);

    /* Check for NaN values in coordinates */
    if (geom_data->dimension_flag != 0)
        check_nan_coordinates(geom_data);

    /* 
     * Extract and validate latitude values from binary data
     * 1. Copy 8 bytes from the input data at appropriate offset
     * 2. Convert from little-endian to host byte order
     * 3. Interpret the bytes as a double-precision floating point value
     * 4. Validate the latitude is within valid range (-90 to 90 degrees)
     */
    validate_geography_latitude_bytes(geom_data);

    /* Process the geography data into PostGIS-compatible format */
    result = process_geometry_data(geom_data);
    
    /* Convert the processed binary data to a PostGIS geography object */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geography_result = lwgeom_from_bytea_p(fcinfo_local);

    /* Free allocated memory */
    if (geom_data)
        pfree(geom_data);
    
    /* Return the PostGIS geography object */
    return geography_result;
}

/* Helper function implementations for geometry/geography to bytea conversions */

/*
 * GEOMETRY/GEOGRAPHY TO BYTEA CONVERSION FLOW:
 * 
 * 1. initialize_geom_data()     - Extract PostGIS data and metadata
 * 2. validate_geom_type()       - Check if geometry type is supported
 * 3. determine_geom_dimensions() - Analyze dimensions and set type codes
 *    ├── handle_xy_dimension()   - Process XY geometries
 *    ├── handle_xyz_dimension()  - Process XYZ geometries  
 *    ├── handle_xym_dimension()  - Process XYM geometries
 *    └── handle_xyzm_dimension() - Process XYZM geometries
 * 4. construct_result_bytea()   - Build final binary representation
 *    ├── set_srid_data()         - Set SRID information
 *    ├── set_geom_type_header()  - Set geometry type header
 *    ├── handle_empty_geometry() - Handle empty geometries
 *    └── handle_linestring_type_data() - Process linestring coordinates
 *        ├── copy_xy_coords()    - Copy XY coordinate data
 *        ├── copy_z_coords()     - Copy Z coordinate data
 *        └── copy_m_coords()     - Copy M coordinate data
 *            └── copy_coord_with_nan_check() - Handle NaN values
 */

/* Helper to call PostGIS functions with single argument */
static inline Datum
call_postgis_func(void *func, Datum arg)
{
    LOCAL_FCINFO(fcinfo, 1);
    InitFunctionCallInfoData(*fcinfo, NULL, 1, InvalidOid, NULL, NULL);
    UpdateFunctionCallInfo(fcinfo, 1, arg);
    return ((PGFunction)func)(fcinfo);
}

/* Step 1: Initialize geometry data structure from PostGIS datum */
static GeoDataInfo* 
initialize_geom_data(Datum input_datum) 
{
    GeoDataInfo *geom_data = palloc0(sizeof(GeoDataInfo));
    
    /* Store original datum */
    geom_data->geom_datum = input_datum;
    
    /* Query PostGIS for geometry properties */
    geom_data->is_empty = DatumGetBool(call_postgis_func(st_isempty_p, input_datum));
    geom_data->is_valid = DatumGetBool(call_postgis_func(st_isvalid_p, input_datum));
    geom_data->npoints = DatumGetInt32(call_postgis_func(st_npoints_p, input_datum));
    geom_data->byte = DatumGetByteaPP(call_postgis_func(lwgeom_to_bytea_p, input_datum));
    
    /* Extract binary data and metadata */
    geom_data->byte_data = (uint8 *)VARDATA_ANY(geom_data->byte);
    geom_data->byte_len = VARSIZE_ANY_EXHDR(geom_data->byte);
    /* Set the default SRID size */
    geom_data->srid_size = SRID_SIZE;
    geom_data->postgis_geom_type = (geom_data->byte_len > POSTGIS_HEADER_SIZE) ? geom_data->byte_data[1] : 0;
    
    return geom_data;
}

/* Step 2: Validate geometry type is supported */
static bool
validate_geom_type(const GeoDataInfo *geom_data) 
{
    uint8 geom_type;
    
    if (geom_data->byte_len < POSTGIS_HEADER_SIZE)
        return false;
        
    geom_type = geom_data->byte_data[GEOM_TYPE_POS_POSTGIS];
    return (geom_type == POINT_TYPE || geom_type == LINE_TYPE || geom_type == POLYGON_TYPE) &&
           geom_data->byte_data[GEOM_TYPE_POS_POSTGIS+1] == 0x00 && 
           geom_data->byte_data[GEOM_TYPE_POS_POSTGIS+2] == 0x00;
}

/* Step 3: Determines the dimension flags and coordinate size of a geometry */
static bool
determine_geom_dimensions(GeoDataInfo *geom_data) 
{
    /* Extract SRID and dimension flags from binary data */
    geom_data->srid_flag = geom_data->byte_data[SRID_FLAG_POS];
    geom_data->has_srid = geom_data->srid_flag & SRID_MASK;
    
    /* Process each dimension type and set appropriate geometry type codes */
    switch (geom_data->srid_flag & DIMENSION_MASK) 
    {
        case POSTGIS_DIM_XY:
            if (geom_data->is_empty) 
            {
                /* Empty point geometry */
                geom_data->geom_type = 0x04;
                geom_data->coord_size = COORD_SIZE_EMPTY;
            } 
            else 
            {
                /* 2D geometry (XY) */
                switch (geom_data->postgis_geom_type)
                {
                    case POINT_TYPE:
                        geom_data->geom_type = POINT_XY;
                        geom_data->coord_size = COORD_SIZE_XY;
                        break;
                    case LINE_TYPE:
                        geom_data->geom_type = geom_data->is_valid ? 
                            (geom_data->npoints > 2 ? VALID_2DLINE_MP : VALID_2DLINE_2P) :
                            (geom_data->npoints > 2 ? INVALID_2DLINE_MP : INVALID_2DLINE_2P);
                        geom_data->coord_size = COORD_SIZE_XY * geom_data->npoints;
                        break;
                    case POLYGON_TYPE:
                        geom_data->geom_type = POLYGON_2D;
                        geom_data->coord_size = COORD_SIZE_XY * geom_data->npoints;
                        break;
                }
            }
            break;
        case POSTGIS_DIM_XYZ:
            /* 3D geometry (XYZ) */
            switch (geom_data->postgis_geom_type)
            {
                case POINT_TYPE:
                    geom_data->geom_type = POINT_XYZ;
                    geom_data->coord_size = COORD_SIZE_XYZ;
                    break;
                case LINE_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? 
                        (geom_data->npoints > 2 ? VALID_3DLINE_MP : VALID_3DLINE_2P) :
                        (geom_data->npoints > 2 ? INVALID_3DLINE_MP : INVALID_3DLINE_2P);
                    geom_data->coord_size = COORD_SIZE_XYZ * geom_data->npoints;
                    break;
                case POLYGON_TYPE:
                    geom_data->geom_type = POLYGON_3D;
                    geom_data->coord_size = COORD_SIZE_XYZ * geom_data->npoints;
                    break;
            }
            break;
        case POSTGIS_DIM_XYZM:
            /* 3D geometry with measure (XYZM) */
            switch (geom_data->postgis_geom_type)
            {
                case POINT_TYPE:
                    geom_data->geom_type = POINT_XYZM;
                    geom_data->coord_size = COORD_SIZE_XYZM;
                    break;
                case LINE_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? 
                        (geom_data->npoints > 2 ? VALID_3DMLINE_MP : VALID_3DMLINE_2P) :
                        (geom_data->npoints > 2 ? INVALID_3DMLINE_MP : INVALID_3DMLINE_2P);
                    geom_data->coord_size = COORD_SIZE_XYZM * geom_data->npoints;
                    break;
                case POLYGON_TYPE:
                    geom_data->geom_type = POLYGON_3DM;
                    geom_data->coord_size = COORD_SIZE_XYZM * geom_data->npoints;
                    break;
            }
            break;
        case POSTGIS_DIM_XYM:
            /* 2D geometry with measure (XYM) */
            switch (geom_data->postgis_geom_type)
            {
                case POINT_TYPE:
                    geom_data->geom_type = POINT_XYM;
                    geom_data->coord_size = COORD_SIZE_XYM;
                    break;
                case LINE_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? 
                        (geom_data->npoints > 2 ? VALID_2DMLINE_MP : VALID_2DMLINE_2P) :
                        (geom_data->npoints > 2 ? INVALID_2DMLINE_MP : INVALID_2DMLINE_2P);
                    geom_data->coord_size = COORD_SIZE_XYM * geom_data->npoints;
                    break;
                case POLYGON_TYPE:
                    geom_data->geom_type = POLYGON_2DM;
                    geom_data->coord_size = COORD_SIZE_XYM * geom_data->npoints;
                    break;
            }
            break;
        default:
            /* Invalid dimension flags */
            return false;
    }

    /* Dimensions successfully determined */    
    return true;
}

/* Step 4.4.1: Handle NaN values in coordinates */
static inline void
copy_coord_with_nan_check(uint8 *dst, double *src)
{
    if (isnan(*src))
        memcpy(dst, SPECIFIC_NAN, COORD_SIZE);
    else
        memcpy(dst, src, COORD_SIZE);
}

/* Step 4.4.2: Copy XY coordinates for all points */
static void
copy_xy_coords(uint8 *dst, uint8 *src, int npoints, uint32_t stride)
{
    int i;
    
    for (i = 0; i < npoints; i++)
        memcpy(dst + (i * COORD_SIZE * 2), src + (i * stride), COORD_SIZE * 2);
}

/* Step 4.4.3: Copy Z coordinates for all points */
static void
copy_z_coords(uint8 *dst, uint8 *src, int npoints, uint32_t stride)
{
    int i;
    double *z_coord;
    
    for (i = 0; i < npoints; i++) {
        z_coord = (double*)(src + (i * stride) + COORD_SIZE * 2);
        copy_coord_with_nan_check(dst + (npoints * COORD_SIZE * 2) + (i * COORD_SIZE), z_coord);
    }
}

/* Step 4.4.4: Copy M coordinates for all points */
static void
copy_m_coords(uint8 *dst, uint8 *src, int npoints, uint32_t stride, bool has_z)
{
    uint32_t z_offset = has_z ? npoints * COORD_SIZE : 0;
    uint32_t coord_offset = has_z ? COORD_SIZE : 0;
    int i;
    double *m_coord;
    
    for (i = 0; i < npoints; i++) {
        m_coord = (double*)(src + (i * stride) + COORD_SIZE * 2 + coord_offset);
        copy_coord_with_nan_check(dst + (npoints * COORD_SIZE * 2) + z_offset + (i * COORD_SIZE), m_coord);
    }
}

/* Step 4.1: Set SRID data in result */
static void
set_srid_data(uint8 *result_data, GeoDataInfo *geom_data, bool is_geography)
{
    if (is_geography || geom_data->has_srid)
        memcpy(result_data, geom_data->byte_data + SRID_POSTGIS_POS, geom_data->srid_size);
    else
        memset(result_data, 0, geom_data->srid_size);
}

/* Step 4.2: Set geometry type header */
static void
set_geom_type_header(uint8 *result_data, GeoDataInfo *geom_data, bool is_geography)
{
    result_data[GEOM_TYPE_POS_RESULT] = (!geom_data->is_valid && is_geography) ? 
                                        INALID_GEOGRAPHY_HEADER : GEOM_TYPE_HEADER;
    result_data[GEOM_TYPE_POS_RESULT + 1] = geom_data->geom_type;
}

/* Step 4.3: Handle empty geometry data */
static void
handle_empty_geometry(uint8 *result_data, GeoDataInfo *geom_data)
{
    memcpy(result_data + HEADER_SIZE, EMPTY_COORD, sizeof(EMPTY_COORD));
    result_data[HEADER_SIZE + sizeof(EMPTY_COORD)] = geom_data->byte_data[GEOM_TYPE_POS_POSTGIS];
}

/* Step 4.4: Handle linestring coordinate data copying */
static bytea*
handle_linestring_type_data(GeoDataInfo *geom_data, uint8 *result_data, bytea *result, bool is_geography)
{
    uint32_t offset = (is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID;
    uint8 *src = geom_data->byte_data + offset + NPOINTS_SIZE;
    uint8 *dst = (geom_data->npoints > 2) ? result_data + HEADER_SIZE + NPOINTS_SIZE : result_data + HEADER_SIZE;
    
    uint8 dim_mask = geom_data->srid_flag & DIMENSION_MASK;
    bool has_z = (dim_mask == POSTGIS_DIM_XYZ || dim_mask == POSTGIS_DIM_XYZM);
    bool has_m = (dim_mask == POSTGIS_DIM_XYM || dim_mask == POSTGIS_DIM_XYZM);
    
    uint32_t stride = COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0) + (has_m ? COORD_SIZE : 0);
    
    copy_xy_coords(dst, src, geom_data->npoints, stride);
    if (has_z) copy_z_coords(dst, src, geom_data->npoints, stride);
    if (has_m) copy_m_coords(dst, src, geom_data->npoints, stride, has_z);
    
    if (geom_data->npoints > 2)
        memcpy(dst + geom_data->coord_size, line_end_metadata, sizeof(line_end_metadata));
    
    return result;
}

static bytea*
handle_polygon_type_data(GeoDataInfo *geom_data, uint8 *result_data, bytea *result, bool is_geography)
{
    int offset = (is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID;

    uint8 *src_start = geom_data->byte_data + offset,
          *dst = (geom_data->npoints > 2) ? result_data + HEADER_SIZE + NPOINTS_SIZE : result_data + HEADER_SIZE,
          dim_mask = geom_data->srid_flag & DIMENSION_MASK,
          *src = src_start + sizeof(int32),
          *metadata_pos,
          *ring_counts_pos;

    bool has_z = (dim_mask == POSTGIS_DIM_XYZ || dim_mask == POSTGIS_DIM_XYZM),
         has_m = (dim_mask == POSTGIS_DIM_XYM || dim_mask == POSTGIS_DIM_XYZM);
    
    int stride = COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0) + (has_m ? COORD_SIZE : 0),
        num_rings = *(int32*)src_start,
        ring_npoints = *(int32*)src,
        ring_idx,
        total_points_copied = 0,
        z_points_copied = 0,
        m_points_copied = 0,
        z_offset,
        cumulative_points = 0;

    /* First pass: copy all XY coordinates from all rings */
    for (ring_idx = 0; ring_idx < num_rings; ring_idx++)
    {
        ring_npoints = *(int32*)src;
        src += sizeof(int32);
        
        copy_xy_coords(dst + (total_points_copied * COORD_SIZE * 2), src, ring_npoints, stride);
        
        src += ring_npoints * stride;
        total_points_copied += ring_npoints;
    }
    
    /* Second pass: copy all Z coordinates from all rings */
    if (has_z)
    {
        src = src_start + sizeof(int32);
        for (ring_idx = 0; ring_idx < num_rings; ring_idx++)
        {
            ring_npoints = *(int32*)src;
            src += sizeof(int32);
            
            /* Reuse copy_z_coords by adjusting destination offset:
             * - copy_z_coords adds (npoints * COORD_SIZE * 2) internally for linestrings
             * - We subtract (ring_npoints * COORD_SIZE * 2) to cancel that offset
             * - Then add our polygon-specific offset (z_points_copied * COORD_SIZE) */
            copy_z_coords(dst + (total_points_copied * COORD_SIZE * 2) - (ring_npoints * COORD_SIZE * 2) + (z_points_copied * COORD_SIZE), src, ring_npoints, stride);
            
            src += ring_npoints * stride;
            z_points_copied += ring_npoints;
        }
    }
    
    /* Third pass: copy all M coordinates from all rings */
    if (has_m)
    {
        src = src_start + sizeof(int32);
        z_offset = has_z ? total_points_copied * COORD_SIZE : 0;
        for (ring_idx = 0; ring_idx < num_rings; ring_idx++)
        {
            ring_npoints = *(int32*)src;
            src += sizeof(int32);
            
            /* Reuse copy_m_coords by adjusting destination offset:
             * - copy_m_coords adds (npoints * COORD_SIZE * 2) + z_offset internally for linestrings
             * - We subtract (ring_npoints * COORD_SIZE * 2) to cancel XY offset
             * - We subtract (has_z ? ring_npoints * COORD_SIZE : 0) to cancel Z offset
             * - Then add our polygon-specific offset (m_points_copied * COORD_SIZE) */
            copy_m_coords(dst + (total_points_copied * COORD_SIZE * 2) + z_offset - (ring_npoints * COORD_SIZE * 2) - (has_z ? ring_npoints * COORD_SIZE : 0) + (m_points_copied * COORD_SIZE), src, ring_npoints, stride, has_z);
            
            src += ring_npoints * stride;
            m_points_copied += ring_npoints;
        }
    }
    
    /* Calculate final position after all coordinates */
    metadata_pos = dst + (total_points_copied * COORD_SIZE * 2) + (has_z ? total_points_copied * COORD_SIZE : 0) + (has_m ? total_points_copied * COORD_SIZE : 0);
    
    /* Add number of rings */
    memcpy(metadata_pos, &num_rings, sizeof(int32));
    metadata_pos += sizeof(int32);
    
    /* Add 6 bytes representing value 2 followed by 4 zero bytes for single ring polygon and followed by 5 zero bytes for  multi-ring polygon */
    if (num_rings == 1)
    {
        memcpy(metadata_pos, poly_identifier_singlering, 5);
        metadata_pos += sizeof(poly_identifier_singlering);
    }
    else if (num_rings > 1)
    {
        memcpy(metadata_pos, poly_identifier_multiring, 6);
        metadata_pos += sizeof(poly_identifier_multiring);
    }
    
    /* Add cumulative ring point counts */
    ring_counts_pos = metadata_pos;
    
    src = src_start + sizeof(int32);
    for (ring_idx = 0; ring_idx < num_rings - 1; ring_idx++)
    {
        ring_npoints = *(int32*)src;
        src += sizeof(int32) + ring_npoints * stride;
        cumulative_points += ring_npoints;
        
        if (ring_idx == num_rings - 2)
        {
            /* Last ring of 3+ rings: 4 bytes */
            memcpy(ring_counts_pos, &cumulative_points, sizeof(int32));
            ring_counts_pos += FINAL_CUMULATIVE_RING_COUNT_SIZE_BYTES;
        }
        else
        {
            /* Other rings: 5 bytes (4 bytes + 1 zero byte) */
            memcpy(ring_counts_pos, &cumulative_points, sizeof(int32));
            ring_counts_pos[4] = 0x00;
            ring_counts_pos += CUMULATIVE_RING_COUNT_SIZE_BYTES;
        }
    }

    /* Add 13-byte polygon ending suffix */        
    memcpy(ring_counts_pos, polygon_end_metadata, sizeof(polygon_end_metadata));
    
    return result;
}

/* Step 4: Construct final binary representation */
static bytea* 
construct_result_bytea(GeoDataInfo *geom_data, bool is_geography) 
{
    uint32_t total_size;
    bytea *result;
    uint8 *result_data;
    
    /* Calculate total size needed for result bytea */
    total_size = SRID_SIZE + GEOM_TYPE_SIZE + geom_data->coord_size;

    if (geom_data->npoints > 2 && geom_data->postgis_geom_type == LINE_TYPE)
        total_size += NPOINTS_SIZE + sizeof(line_end_metadata);

    if (geom_data->postgis_geom_type == POLYGON_TYPE && !geom_data->is_empty)
    {
        /* For polygon, calculate additional bytes needed */
        int offset = (is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID,
            num_rings = *(int32*)(geom_data->byte_data + offset);

        total_size += NPOINTS_SIZE + RING_COUNT_BYTES;          /* Ring count (4 bytes) */

        if (num_rings > 1) 
            total_size += sizeof(poly_identifier_multiring) + (num_rings - 2) * CUMULATIVE_RING_COUNT_SIZE_BYTES + FINAL_CUMULATIVE_RING_COUNT_SIZE_BYTES;  /* Cumulative counts: 6 + (n-2)*5 + 4 bytes, or just 5 if only 1 ring */
        else
            total_size += sizeof(poly_identifier_singlering);                           /* Single ring polygon suffix */

        total_size += sizeof(polygon_end_metadata);  
    }
    
    /* Allocate and initialize result bytea */
    result = (bytea *) palloc(VARHDRSZ + total_size);
    SET_VARSIZE(result, VARHDRSZ + total_size);

    /* Get pointer to the data portion of the bytea */
    result_data = (uint8 *)VARDATA(result);
    
    /* Build result binary data step by step */
    set_srid_data(result_data, geom_data, is_geography);
    set_geom_type_header(result_data, geom_data, is_geography);

    if (geom_data->is_empty) 
    {
        /* Handle empty geometries with special metadata */
        handle_empty_geometry(result_data, geom_data);
    } 
    else 
    {
        /* 
         * For non-empty geometries, determine the source offset based on SRID presence
         * and copy the coordinate data from the source
         */
        uint32_t offset = (is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID;
        
        /* Copy coordinate data based on geometry type */
        switch (geom_data->postgis_geom_type) 
        {
            case POINT_TYPE:
                /* Simple coordinate copy for points */
                memcpy(result_data + HEADER_SIZE, geom_data->byte_data + offset, geom_data->coord_size);
                break;
            case LINE_TYPE:
                /* Add point count for multi-point linestrings */
                if (geom_data->npoints > 2)
                    memcpy(result_data + HEADER_SIZE, &geom_data->npoints, NPOINTS_SIZE);
                return handle_linestring_type_data(geom_data, result_data, result, is_geography);
            case POLYGON_TYPE:
                memcpy(result_data + HEADER_SIZE, &geom_data->npoints, NPOINTS_SIZE);
                return handle_polygon_type_data(geom_data, result_data, result, is_geography);
        }
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
        if (geom_data)
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
        if (geom_data)
            pfree(geom_data);
        PG_RETURN_BYTEA_P(result);
    }
   
    /* Construct the final binary representation */
    result = construct_result_bytea(geom_data, false);
    
    /* Free allocated memory */
    if (geom_data)
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
        if (geom_data)
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
        if (geom_data)
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
    if (geom_data)
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
        else if (strcmp(geom_type, "ST_LineString" ) == 0) 
        {
            /* Copy empty linestring WKB pattern */
            memcpy(VARDATA(empty_geom), EMPTY_LINE_Binary, EMPTY_Binary_SIZE);
        }
        else if (strcmp(geom_type, "ST_Polygon" ) == 0) 
        {
            /* Copy empty linestring WKB pattern */
            memcpy(VARDATA(empty_geom), EMPTY_POLYGON_Binary, EMPTY_Binary_SIZE);
        }
        
        /* Free allocated memory and return the empty WKB */
        if (geom_type)
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

    /* Free allocated memory */
    pfree(text_result);
    
    /* Return the rewritten WKT representation */
    PG_RETURN_DATUM(PointerGetDatum(rewritten_text));
}

/* Converts a PostGIS geometry to its WKT representation with custom formatting. */
Datum
geometry_asbpchar(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;            /* Input geometry */
    text    *text_result,           /* Initial WKT text from PostGIS */
            *rewritten_text;        /* Processed WKT text after rewriting */
    int32   typmod = PG_GETARG_INT32(1);
    int     maxlen = typmod - VARHDRSZ;
    char   *bpchar_result;        /* Resulting bpchar text */
    char   *buf_padded;
    int    str_len;
    Datum  res;
    LOCAL_FCINFO(fcinfo_local, 3);  /* Local function call info */

    /* Initialize function call info with collation for text processing */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 3, PG_GET_COLLATION(), NULL, NULL);

    load_functions();

    /* Get input geometry object from function arguments */
    geom_datum = PG_GETARG_DATUM(0);

    /* 
     * Get standard WKT text representation of geometry
     * Uses PostGIS's internal text conversion function (ST_AsText)
     */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    text_result = DatumGetTextPP(lwgeom_astext_p(fcinfo_local));

    /* 
     * Rewrite the WKT text using the geo_wkt_rewrite function
     * This applies custom formatting rules to the standard WKT
     */
    rewritten_text = geo_wkt_rewrite(text_result);
    bpchar_result = text_to_cstring(rewritten_text);

    /* Check if the string fits within the specified length */
    str_len = strlen(bpchar_result);
    if (str_len > maxlen) 
        ereport(ERROR,
            (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
            errmsg("There is insufficient result space to convert a geometry/geography value to char/nchar.")));

    /* Right pad string value with the spaces */
    buf_padded = (char *) palloc0(maxlen + 1);
    memcpy(buf_padded, bpchar_result, str_len);
    memset(buf_padded + str_len, ' ', maxlen - str_len);

    res = DirectFunctionCall3(bpcharin,
                               CStringGetDatum(buf_padded),
                               ObjectIdGetDatum(0),
                               Int32GetDatum(typmod));

    pfree(text_result);
    pfree(rewritten_text);
    pfree(bpchar_result);
    pfree(buf_padded);
    PG_RETURN_DATUM(res);
}

#endif
