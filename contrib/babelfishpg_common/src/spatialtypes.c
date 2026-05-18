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

#define MAX_DIMENSION_FLAG 4
#define POINT_TYPE       1  /* Identifier for Point geometry type */
#define LINE_TYPE        2  /* Identifier for Linestring geometry type */
#define POLYGON_TYPE     3  /* Identifier for Polygon geometry type */
#define MULTIPOINT_TYPE  4  /* Identifier for MultiPoint geometry type */

#define SRID_UNKNOWN_VAL    0
#define GSERIALIZED_HDR_SIZE  8  /* offsetof(GSERIALIZED, data) */
#define G_FLAGS_BBOX_BIT    0x04

#define G_FLAGS_Z_BIT         0x01
#define G_FLAGS_M_BIT         0x02
#define G_FLAGS_GEODETIC_BIT  0x08
#define G_FLAGS_EXTENDED_BIT  0x10  /* v2 only */
#define G_FLAGS_VERSION_BIT   0x40  /* v2 sets this; v1 leaves it clear */

#define LWTYPE_POINT             1
#define LWTYPE_LINESTRING        2
#define LWTYPE_POLYGON           3
#define LWTYPE_MULTIPOINT        4
#define LWTYPE_MULTILINESTRING   5
#define LWTYPE_MULTIPOLYGON      6
#define LWTYPE_COLLECTION        7
#define LWTYPE_CIRCSTRING        8
#define LWTYPE_COMPOUNDCURVE     9
#define LWTYPE_CURVEPOLYGON     10
#define LWTYPE_MULTICURVE       11
#define LWTYPE_MULTISURFACE     12
#define LWTYPE_NUMTYPES         13   /* one past largest known */

#define GSERIALIZED_TYPE_SLICE_SIZE 64

#define DEFAULT_GEOGRAPHY_SRID 4326
#define DEFAULT_GEOMETRY_SRID  0
#define MIN_GEOMETRY_LENGTH    22  /* Minimum length for geometry data which 2D POINT */

#define COORD_SIZE     8      /* Size of each coordinate in bytes (double) */
#define HEADER_SIZE    6      /* Size of the geometry header in bytes */
#define XY_PER_POINT 2        /* Number of coordinates to check for NaN (X and Y) */
#define EMPTY_GEOM_DATA_SIZE    4     /* Size of the geometry header in bytes */

#define DIM_FLAG_EMPTY       0       /* Dimension flag for Empty Point */
#define DIM_FLAG_2D          1       /* Dimension flag for 2D Point (XY) */
#define DIM_FLAG_3D          2       /* Dimension flag for 3D Point (XYZ) */
#define DIM_FLAG_2DM         3       /* Dimension flag for 2D Point with M (XYM) */
#define DIM_FLAG_3DM         4       /* Dimension flag for 3D Point with M (XYZM) */

#define POSTGIS_HEADER_SIZE      5      /* Size of the postgis header in bytes */
#define SRID_SIZE                4      /* Size of the SRID field in bytes */
#define HEADER_DIMENSION_POS     4      /* Position of dimension info in header */
#define EMPTY_POINT_TYPE_LASTBYTE       0x01    /* Type identifier for empty point */
#define EMPTY_LINE_TYPE_LASTBYTE        0x02    /* Type identifier for empty linestring */
#define EMPTY_POLYGON_TYPE_LASTBYTE     0x03    /* Type identifier for empty polygon */
#define EMPTY_MULTIPOINT_TYPE_LASTBYTE  0x04    /* Type identifier for empty Multipoint */
#define NPOINTS_SIZE                 4          /* Size of no. of points data (4 bytes ) */

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
#define INVALID_POLYGON_2D  0x00  /* 2D Polygon - XY dimensions*/
#define INVALID_POLYGON_3D  0x01  /* 3D Polygon - XYZ dimensions */
#define INVALID_POLYGON_2DM 0x02  /* 2DM Polygon -  XYM dimensions*/
#define INVALID_POLYGON_3DM 0x03  /* 3DM Polygon - XYZM dimensions*/

/* Valid polygon variants — with V flag (bit 2 = 0x04) */
#define VALID_POLYGON_2D    0x04  /* Valid 2D Polygon */
#define VALID_POLYGON_3D    0x05  /* Valid 3D Polygon */
#define VALID_POLYGON_2DM   0x06  /* Valid 2DM Polygon */
#define VALID_POLYGON_3DM   0x07  /* Valid 3DM Polygon */

/* Complex geometry type constants (extensible for future geometry types) */
#define COMPLEX_GEOM_2D     0x00  /* 2D complex geometry (linestring MP, polygon, etc.) */
#define COMPLEX_GEOM_3D     0x01  /* 3D complex geometry (linestring MP, polygon, etc.) */
#define COMPLEX_GEOM_2DM    0x02  /* 2DM complex geometry (linestring MP, polygon, etc.) */
#define COMPLEX_GEOM_3DM    0x03  /* 3DM complex geometry (linestring MP, polygon, etc.) */


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
#define SRID_POSTGIS_POS    5   /* Position of SRID FLAG in POSTGIS data */
#define OFFSET_WITH_SRID    9   /* Offset for coordinate data with SRID */
#define OFFSET_WITHOUT_SRID 5   /* Offset for coordinate data without SRID */
#define INALID_GEOGRAPHY_HEADER    2   /* Header value for invalid geography objects */  

#define GEOM_TYPE_POS_POSTGIS  1   /* Position of geometry type in PostGIS binary data */
#define GEOM_TYPE_POS_RESULT   4   /* Position of geometry type in result data */

#define EMPTY_Binary_SIZE      9   /* Size of empty representation in binary */
#define EMPTY_POINT_Bytes      "\x01\x04\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty point */
#define EMPTY_LINE_Bytes       "\x01\x02\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty linestring */
#define EMPTY_POLYGON_Bytes    "\x01\x03\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty polygon */
#define EMPTY_MULTIPOINT_Bytes "\x01\x04\x00\x00\x00\x00\x00\x00\x00"  /* Binary for empty Multipoint */
#define FIGURE_INTERIOR_RING  0x00
#define FIGURE_STROKE         0x01
#define FIGURE_EXTERIOR_RING  0x02

/* CLR Shape Types — V1  */
#define SHAPE_POINT              1
#define SHAPE_LINESTRING         2
#define SHAPE_POLYGON            3
#define SHAPE_MULTIPOINT         4
#define SHAPE_MULTILINESTRING    5
#define SHAPE_MULTIPOLYGON       6
#define SHAPE_GEOMETRYCOLLECTION 7

/* CLR binary metadata entry sizes */
#define FIGURE_ENTRY_SIZE   5   /* 1 byte attribute + 4 bytes point_offset */
#define SHAPE_ENTRY_SIZE    9   /* 4 bytes parent + 4 bytes figure_off + 1 byte type */
#define COUNT_FIELD_SIZE    4   /* Size of NumFigures / NumShapes fields */

/* Point geometry type flags - P flag (0x08) WITHOUT V flag */
#define INVALID_POINT_2D_FLAG       0x08    /* P only (no V) —  2D Point */
#define INVALID_POINT_3D_FLAG       0x09    /* P+Z (no V) —  3D Point */
#define INVALID_POINT_2DM_FLAG      0x0A    /* P+M (no V) — 2DM Point */
#define INVALID_POINT_3DM_FLAG      0x0B    /* P+Z+M (no V) —  3DM Point */

#define POSTGIS_HEADER_POINT       "\x01\x01\x00\x00\x20"
#define POSTGIS_HEADER_LINESTRING  "\x01\x02\x00\x00\x20"
#define POSTGIS_HEADER_POLYGON     "\x01\x03\x00\x00\x20"
#define POSTGIS_HEADER_MULTIPOINT  "\x01\x04\x00\x00\x20"

#define SHAPE_TYPE_OFFSET (HEADER_SIZE + NPOINTS_SIZE + COUNT_FIELD_SIZE + COUNT_FIELD_SIZE + sizeof(int32_t) + sizeof(uint32_t))

/* Macro to throw varbinary to geometry/geography conversion error */
#define THROW_VARBINARY_CONVERSION_ERROR() \
    ereport(ERROR, \
            (errcode(ERRCODE_INVALID_PARAMETER_VALUE), \
             errmsg("Error converting data type varbinary.")))
             
#define CHECK_METADATA_BOUNDS(geom, base, off, sz) \
    do { \
        if ((uint64_t)((base) - (geom)->input_data) + (uint64_t)(off) + (uint64_t)(sz) \
            > (geom)->input_len) \
            THROW_VARBINARY_CONVERSION_ERROR(); \
    } while (0)             
             
/* 
 * Global array representing NaN coordinate value in IEEE 754 format
 * Used for empty point detection and creation
 */
static const uint8 NAN_COORD[8] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f  /* NaN representation */
};

/*
 * Parsed figure entry 
 */
typedef struct {
    uint8_t  attribute;      /* FIGURE_INTERIOR_RING / STROKE / EXTERIOR_RING */
    uint32_t point_offset;   /* Starting point index in coordinate arrays */
} Figure;

/*
 * Parsed shape entry 
 */
typedef struct {
    int32_t  parent_index;   /* -1 for root shape, else index of parent */
    uint32_t figure_offset;  /* Starting figure index for this shape */
    uint8_t  type;           /* SHAPE_POINT .. SHAPE_GEOMETRYCOLLECTION */
} Shape;

/* Copied from PostGIS */
typedef struct
{
    uint32_t size; /* For PgSQL use only, use VAR* macros to manipulate. */
    uint8_t srid[3]; /* 24 bits of SRID */
    uint8_t gflags; /* HasZ, HasM, HasBBox, IsGeodetic */
    uint8_t data[1]; /* See gserialized.txt */
} GSERIALIZED;

/* 2D bounding box for bbox-disjoint short-circuit */
typedef struct { float xmin, xmax, ymin, ymax; } GBOX2D;

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
    bool     has_invalid_coords;
    bool     has_npoints_data;

    uint32_t  nfigures;      
    uint32_t  nshapes;        
    Figure   *figures;        
    Shape    *shapes;        
    uint32_t  metadata_size;  /* Total bytes consumed by figure+shape sections */
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
        strcmp(geom_type, "ST_Polygon") != 0 &&
        strcmp(geom_type, "ST_MultiPoint") != 0) 
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

typedef Datum (*st_geometryn_t)(PG_FUNCTION_ARGS);
static st_geometryn_t st_geometryn_p;

static void validate_geography_latitude(Datum geom_datum, bool is_flipped);
static inline uint32_t gserialized_typecode(Datum datum);

/* Spatial predicate function pointers for optimized C wrappers */
typedef Datum (*postgis_predicate_fn_t)(PG_FUNCTION_ARGS);
static postgis_predicate_fn_t st_intersects_op_p = NULL;
static postgis_predicate_fn_t st_contains_op_p   = NULL;
static postgis_predicate_fn_t st_equals_op_p     = NULL;
static postgis_predicate_fn_t st_distance_op_p   = NULL;
static postgis_predicate_fn_t st_disjoint_op_p   = NULL;

/* Unary PostGIS function pointers for converted wrappers */
typedef Datum (*postgis_unary_fn_t)(PG_FUNCTION_ARGS);
static postgis_unary_fn_t st_area_p        = NULL;
static postgis_unary_fn_t st_makevalid_p   = NULL;
static postgis_unary_fn_t lwgeom_npoints_p = NULL;
static postgis_unary_fn_t lwgeom_dim_p     = NULL;
static postgis_unary_fn_t lwgeom_isclosed_p = NULL;
static postgis_unary_fn_t geog_distance_ellipsoid_p = NULL;
static postgis_unary_fn_t lwgeom_zmflag_p  = NULL;
static postgis_unary_fn_t lwgeom_z_point_p = NULL;
static postgis_unary_fn_t lwgeom_m_point_p = NULL;

/* Flag for one-time PostGIS function pointer loading */
static bool spatial_fns_loaded = false;

PG_FUNCTION_INFO_V1(geometry_in);
PG_FUNCTION_INFO_V1(geography_in);
PG_FUNCTION_INFO_V1(get_geometry_from_text);
PG_FUNCTION_INFO_V1(get_geography_from_text);
PG_FUNCTION_INFO_V1(get_geometry_from_wkb);
PG_FUNCTION_INFO_V1(get_geography_from_wkb);
PG_FUNCTION_INFO_V1(charTogeom);
PG_FUNCTION_INFO_V1(charTogeog);
PG_FUNCTION_INFO_V1(geography_point);
PG_FUNCTION_INFO_V1(geometry_from_bytea);
PG_FUNCTION_INFO_V1(bytea_from_geometry);
PG_FUNCTION_INFO_V1(geography_from_bytea);
PG_FUNCTION_INFO_V1(bytea_from_geography);
PG_FUNCTION_INFO_V1(st_as_binary_geometry);
PG_FUNCTION_INFO_V1(st_as_binary_geography);
PG_FUNCTION_INFO_V1(st_as_text);
PG_FUNCTION_INFO_V1(geometry_astext);
PG_FUNCTION_INFO_V1(geometry_asbpchar);

/* --- Constructors --- */
PG_FUNCTION_INFO_V1(bbf_geometry_stgeomfromtext);
PG_FUNCTION_INFO_V1(bbf_geography_stgeomfromtext);
PG_FUNCTION_INFO_V1(bbf_geometry_stpointfromtext);
PG_FUNCTION_INFO_V1(bbf_geometry_stlinefromtext);
PG_FUNCTION_INFO_V1(bbf_geometry_stpolyfromtext);
PG_FUNCTION_INFO_V1(bbf_geometry_stmpointfromtext);
PG_FUNCTION_INFO_V1(bbf_geography_stpointfromtext);
PG_FUNCTION_INFO_V1(bbf_geography_stlinefromtext);
PG_FUNCTION_INFO_V1(bbf_geography_stpolyfromtext);
PG_FUNCTION_INFO_V1(bbf_geography_stmpointfromtext);
PG_FUNCTION_INFO_V1(bbf_geometry_point);
PG_FUNCTION_INFO_V1(bbf_geometry_parse);
PG_FUNCTION_INFO_V1(bbf_geography_parse);
PG_FUNCTION_INFO_V1(bbf_geometry_stmpointfromwkb);
PG_FUNCTION_INFO_V1(bbf_geography_stmpointfromwkb);

/* --- Geometry predicates --- */
PG_FUNCTION_INFO_V1(bbf_st_intersects);
PG_FUNCTION_INFO_V1(bbf_st_contains);
PG_FUNCTION_INFO_V1(bbf_st_equals);
PG_FUNCTION_INFO_V1(bbf_st_disjoint);
PG_FUNCTION_INFO_V1(bbf_st_distance);

/* --- Geography predicates --- */
PG_FUNCTION_INFO_V1(bbf_geog_intersects);
PG_FUNCTION_INFO_V1(bbf_geog_contains);
PG_FUNCTION_INFO_V1(bbf_geog_equals);
PG_FUNCTION_INFO_V1(bbf_geog_disjoint);
PG_FUNCTION_INFO_V1(bbf_geog_distance);

/* --- Unary geometry functions --- */
PG_FUNCTION_INFO_V1(bbf_st_area);
PG_FUNCTION_INFO_V1(bbf_st_numpoints);
PG_FUNCTION_INFO_V1(bbf_st_dimension);
PG_FUNCTION_INFO_V1(bbf_st_isclosed);
PG_FUNCTION_INFO_V1(bbf_st_makevalid);
PG_FUNCTION_INFO_V1(bbf_st_geometrytype);

/* --- Unary geography functions --- */
PG_FUNCTION_INFO_V1(bbf_geog_area);
PG_FUNCTION_INFO_V1(bbf_geog_numpoints);
PG_FUNCTION_INFO_V1(bbf_geog_dimension);
PG_FUNCTION_INFO_V1(bbf_geog_isclosed);
PG_FUNCTION_INFO_V1(bbf_geog_makevalid);

/* --- Property accessors --- */
PG_FUNCTION_INFO_V1(bbf_hasz);
PG_FUNCTION_INFO_V1(bbf_hasm);
PG_FUNCTION_INFO_V1(bbf_z);
PG_FUNCTION_INFO_V1(bbf_m);

/* --- Operator wrappers --- */
PG_FUNCTION_INFO_V1(bbf_geom_op_equals);
PG_FUNCTION_INFO_V1(bbf_geom_op_not_equals);
PG_FUNCTION_INFO_V1(bbf_geog_op_equals);
PG_FUNCTION_INFO_V1(bbf_geog_op_not_equals);

/* --- Display wrappers (geometry/geography → text/varchar/bpchar) --- */
PG_FUNCTION_INFO_V1(bbf_geog_astext);
PG_FUNCTION_INFO_V1(bbf_geog_asbpchar);
PG_FUNCTION_INFO_V1(bbf_geog_asvarchar);
PG_FUNCTION_INFO_V1(bbf_geom_asvarchar);

/* --- String-to-geometry/geography cast wrappers --- */
PG_FUNCTION_INFO_V1(bbf_geom_from_bpchar);
PG_FUNCTION_INFO_V1(bbf_geom_from_varchar);
PG_FUNCTION_INFO_V1(bbf_geog_from_bpchar);
PG_FUNCTION_INFO_V1(bbf_geog_from_varchar);

/* --- Error-raising cast functions --- */
PG_FUNCTION_INFO_V1(bbf_geom_to_text_error);
PG_FUNCTION_INFO_V1(bbf_geog_to_text_error);
PG_FUNCTION_INFO_V1(bbf_text_to_geom_error);
PG_FUNCTION_INFO_V1(bbf_text_to_geog_error);

/* --- Binary / varbinary cast wrappers --- */
PG_FUNCTION_INFO_V1(bbf_geom_from_varbinary);
PG_FUNCTION_INFO_V1(bbf_geom_to_varbinary);
PG_FUNCTION_INFO_V1(bbf_geom_from_binary);
PG_FUNCTION_INFO_V1(bbf_geom_to_binary);
PG_FUNCTION_INFO_V1(bbf_geog_from_varbinary);
PG_FUNCTION_INFO_V1(bbf_geog_to_varbinary);
PG_FUNCTION_INFO_V1(bbf_geog_from_binary);
PG_FUNCTION_INFO_V1(bbf_geog_to_binary);


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
        st_geometryn_p = (st_geometryn_t) load_external_function("$libdir/postgis-3", "LWGEOM_geometryn_collection", true, NULL); 
        st_numinteriorrings_p = (st_numinteriorrings_t) load_external_function("$libdir/postgis-3", "LWGEOM_numinteriorrings_polygon", true, NULL); 
        st_intersects_op_p = (postgis_predicate_fn_t) load_external_function("$libdir/postgis-3", "ST_Intersects", true, NULL);
        st_contains_op_p = (postgis_predicate_fn_t) load_external_function("$libdir/postgis-3", "within", true, NULL);
        st_equals_op_p = (postgis_predicate_fn_t) load_external_function("$libdir/postgis-3", "ST_Equals", true, NULL);
        st_distance_op_p = (postgis_predicate_fn_t) load_external_function("$libdir/postgis-3", "ST_Distance", true, NULL);
        st_disjoint_op_p = (postgis_predicate_fn_t) load_external_function("$libdir/postgis-3", "disjoint", true, NULL);
        st_area_p        = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "ST_Area", true, NULL);
        st_makevalid_p   = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "ST_MakeValid", true, NULL);
        lwgeom_npoints_p = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "LWGEOM_npoints", true, NULL);
        lwgeom_dim_p     = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "LWGEOM_dimension", true, NULL);
        lwgeom_isclosed_p = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "LWGEOM_isclosed", true, NULL);
        geog_distance_ellipsoid_p = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "LWGEOM_distance_ellipsoid", true, NULL);
        lwgeom_zmflag_p  = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "LWGEOM_zmflag", true, NULL);
        lwgeom_z_point_p = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "LWGEOM_z_point", true, NULL);
        lwgeom_m_point_p = (postgis_unary_fn_t) load_external_function("$libdir/postgis-3", "LWGEOM_m_point", true, NULL);
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

static void
validate_longitude_range(double lon)
{
    if (lon < -15069.0 || lon > 15069.0)
    {
        ereport(ERROR,
            (errcode(ERRCODE_DATA_EXCEPTION),
             errmsg("Longitude values must be between -15069 and 15069 degrees")));
    }
}

static void
validate_not_inf_nan(double value, const char *coord_name)
{
    if (isinf(value))
    {
        ereport(ERROR,
            (errcode(ERRCODE_DATA_EXCEPTION),
             errmsg("%s values must not contain infinity", coord_name)));
    }
    if (isnan(value))
    {
        ereport(ERROR,
            (errcode(ERRCODE_DATA_EXCEPTION),
             errmsg("%s values must not contain NaN", coord_name)));
    }
}

/*
 * Validates a single lat/lon coordinate pair for geography constraints:
 * - Neither value may be NaN or Infinity
 * - Latitude must be in [-90, 90]
 * - Longitude must be in [-15069, 15069]
 */
static inline void
validate_geography_coord_pair(double lat, double lon)
{
    validate_not_inf_nan(lat, "Latitude");
    validate_not_inf_nan(lon, "Longitude");
    validate_latitude_range(lat);
    validate_longitude_range(lon);
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
    float8 lat, lon;
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
        /* After flipping: x = latitude, y = longitude */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));
        
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        lon = DatumGetFloat8(lwgeom_y_p(fcinfo_local));
        
         validate_geography_coord_pair(lat, lon);
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
            
            /* Get longitude (y after flip) */
            UpdateFunctionCallInfo(fcinfo_local, 1, point);
            lon = DatumGetFloat8(lwgeom_y_p(fcinfo_local));
            
            validate_geography_coord_pair(lat, lon);
            
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
            
            UpdateFunctionCallInfo(fcinfo_local, 1, point);
            lon = DatumGetFloat8(lwgeom_y_p(fcinfo_local));
            
            validate_geography_coord_pair(lat, lon);
            
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
            
            prev_lat = 0;
            prev_lon = 0;
            
            /* Check each point in the interior ring for valid latitude */
            for (i = 1; i <= npoints; i++)
            {
                /* Extract the i-th point from the interior ring */
                UpdateFunctionCallInfo(fcinfo_local, 2, interior_ring, Int32GetDatum(i));
                point = st_pointn_p(fcinfo_local);
                
                /* Get latitude value (x coordinate after flipping) */
                UpdateFunctionCallInfo(fcinfo_local, 1, point);
                lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));
                
                UpdateFunctionCallInfo(fcinfo_local, 1, point);
                lon = DatumGetFloat8(lwgeom_y_p(fcinfo_local));
                
                validate_geography_coord_pair(lat, lon);
                
                /* Check for antipodal points */
                check_antipodal_points(fcinfo_local, point, i, &prev_lat, &prev_lon);
            }
        }
    }  else if (strcmp(geom_type, "ST_MultiPoint") == 0)
    {
        /* Get total number of points in the MultiPoint */
        UpdateFunctionCallInfo(fcinfo_local, 1, flipped_geom);
        npoints = DatumGetInt32(st_npoints_p(fcinfo_local));

        /* 
         * Validate each child point using ST_GeometryN 
         * ST_GeometryN uses 1-based indexing.
         */
        for (i = 1; i <= npoints; i++)
        {
            Datum child_point;

            /* Extract the i-th point from the MultiPoint collection */
            UpdateFunctionCallInfo(fcinfo_local, 2, flipped_geom, Int32GetDatum(i));
            child_point = st_geometryn_p(fcinfo_local);

            /* Get latitude (x coordinate after flipping) */
            UpdateFunctionCallInfo(fcinfo_local, 1, child_point);
            lat = DatumGetFloat8(lwgeom_x_p(fcinfo_local));

            /* Get longitude (y coordinate after flipping) */
            UpdateFunctionCallInfo(fcinfo_local, 1, child_point);
            lon = DatumGetFloat8(lwgeom_y_p(fcinfo_local));

            validate_geography_coord_pair(lat, lon);
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

/*
 * Converts WKB binary to geometry with SRID validation.
 */
Datum
get_geometry_from_wkb(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;
    int32    srid;
    char    *geom_type;
    bytea   *wkb_input;
    LOCAL_FCINFO(fcinfo_local, 2);

    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    load_functions();

    srid = PG_GETARG_INT32(1);

    if (srid < 0 || srid > 999999)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("SRID value should be between 0 and 999999")));
    }

    wkb_input = PG_GETARG_BYTEA_PP(0);

    /* Convert WKB to geometry */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(wkb_input));
    geom_datum = lwgeom_from_bytea_p(fcinfo_local);

    /* Set SRID */
    UpdateFunctionCallInfo(fcinfo_local, 2, geom_datum, Int32GetDatum(srid));
    geom_datum = gserialized_set_srid_p(fcinfo_local);

    /* Validate geometry type */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);
    check_geom_type(geom_type);

    if (geom_type)
        pfree(geom_type);

    PG_RETURN_DATUM(geom_datum);
}

/*
 * Converts WKB binary to geography with SRID and latitude validation.
 */
Datum
get_geography_from_wkb(PG_FUNCTION_ARGS)
{
    Datum    geom_datum;
    char    *geom_type;
    int32    srid;
    bytea   *wkb_input;
    LOCAL_FCINFO(fcinfo_local, 2);

    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    load_functions();

    srid = PG_GETARG_INT32(1);

    if (!is_valid_geography_srid(srid))
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid SRID")));
    }

    wkb_input = PG_GETARG_BYTEA_PP(0);

    /* Convert WKB to geometry */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(wkb_input));
    geom_datum = lwgeom_from_bytea_p(fcinfo_local);

    /* Set SRID */
    UpdateFunctionCallInfo(fcinfo_local, 2, geom_datum,  Int32GetDatum(srid));
    geom_datum = gserialized_set_srid_p(fcinfo_local);

    /* Validate geometry type */
    geom_type = GetGeometryTypeName(fcinfo_local, geom_datum);
    check_geom_type(geom_type);

    /* Validate latitude */
    validate_geography_latitude(geom_datum, false);

    /* Flip coordinates for geography storage */
    UpdateFunctionCallInfo(fcinfo_local, 1, geom_datum);
    geom_datum = st_flipcoordinates_p(fcinfo_local);

    if (geom_type)
        pfree(geom_type);

    PG_RETURN_DATUM(geom_datum);
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

     /* Validate coordinates: NaN, Infinity, and range */
     validate_geography_coord_pair(lat, lon);


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
    GeometryData *geom_data = palloc0(sizeof(GeometryData));
    
    /* Store reference to original input */
    geom_data->input = input;

    /* Get pointer to actual data (skipping bytea header) */
    geom_data->input_data = (uint8 *)VARDATA_ANY(input);
    
    /* Store length of data (excluding bytea header) */
    geom_data->input_len = VARSIZE_ANY_EXHDR(input);
    
    /* Extract SRID from first 4 bytes (little-endian) */
    memcpy(&geom_data->srid, geom_data->input_data, sizeof(int32_t));
    
    /* Extract geometry type from bytes 4-5 */
    geom_data->geom_class = geom_data->input_data[4];
    geom_data->geom_type = geom_data->input_data[5];
    
    /* 
     * for P-flag and L-flag geometries,
     * bytes 6+ are coordinate data, not npoints.
     * npoints is read in set_dimension_flag() only for complex types.
     */
    /* Initialize flags */
    geom_data->npoints           = 0;
    geom_data->has_npoints_data= false;
    geom_data->geom_name = 0;
    geom_data->dimension_flag = 0;
    geom_data->has_invalid_coords = false;
    
    /* Initialize CLR metadata (populated by parse_figures_and_shapes) */
    geom_data->nfigures      = 0;
    geom_data->nshapes       = 0;
    geom_data->figures       = NULL;
    geom_data->shapes        = NULL;
    geom_data->metadata_size = 0;
    
    return geom_data;
}

/* STEP 2: GEOMETRY TYPE ANALYSIS - Set dimension flag based on geometry type */
/* P flag (0x08) — single point ,,L flag (0x10)  */
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
        /*
         * CLR Serialization Properties byte layout: 000 L P V M Z
         *
         * When neither P(0x08) nor L(0x10) is set, the geometry is a
         * "complex" type — could be LineString(>2pts), Polygon,
         * MultiPoint, MultiLineString, MultiPolygon, or GeometryCollection.
         *
         * We leave geom_name = 0 so parse_figures_and_shapes() determines
         * the actual type from the SHAPE metadata section.
         */


        case 0x04:
            /* Check for empty geometry first — with bounds check */
            if (geom_data->input_len >= HEADER_SIZE + sizeof(EMPTY_COORD) && memcmp(geom_data->input_data + HEADER_SIZE, EMPTY_COORD, sizeof(EMPTY_COORD)) == 0)
            {
                geom_data->dimension_flag = 0;
                break;
            }
            /* Non-empty: fall through to COMPLEX_GEOM_2D handling */
            /* FALLTHROUGH */

        case COMPLEX_GEOM_2D:  /* 0x00 — no flags (invalid 2D complex) */
            geom_data->dimension_flag = DIM_FLAG_2D;
            geom_data->has_npoints_data = true;
            memcpy(&geom_data->npoints,geom_data->input_data + HEADER_SIZE, sizeof(int32_t));
            break;

        case COMPLEX_GEOM_3D:  /* 0x01 — Z only (invalid 3D complex) */
        case VALID_3DLINE_MP:  /* 0x05 — V+Z (valid 3D complex) */
            geom_data->dimension_flag = DIM_FLAG_3D;
            geom_data->has_npoints_data = true;
            memcpy(&geom_data->npoints,geom_data->input_data + HEADER_SIZE, sizeof(int32_t));
            break;

        case COMPLEX_GEOM_2DM: /* 0x02 — M only (invalid 2DM complex) */
        case VALID_2DMLINE_MP: /* 0x06 — V+M (valid 2DM complex) */
            geom_data->dimension_flag = DIM_FLAG_2DM;
            geom_data->has_npoints_data = true; 
            memcpy(&geom_data->npoints,  geom_data->input_data + HEADER_SIZE, sizeof(int32_t));
            break;

        case COMPLEX_GEOM_3DM: /* 0x03 — Z+M (invalid 3DM complex) */
        case VALID_3DMLINE_MP: /* 0x07 — V+Z+M (valid 3DM complex) */
            geom_data->dimension_flag = DIM_FLAG_3DM;
            geom_data->has_npoints_data = true;
            memcpy(&geom_data->npoints,geom_data->input_data + HEADER_SIZE, sizeof(int32_t));
            break;

        /* Point — P flag (0x08) WITH V flag (0x04) */
        case POINT_XY:   /* 0x0C — P+V */
            geom_data->dimension_flag = DIM_FLAG_2D;
            geom_data->geom_name = POINT_TYPE;
            break;
        case POINT_XYZ:  /* 0x0D — P+V+Z */
            geom_data->dimension_flag = DIM_FLAG_3D;
            geom_data->geom_name = POINT_TYPE;
            break;
        case POINT_XYM:  /* 0x0E — P+V+M */
            geom_data->dimension_flag = DIM_FLAG_2DM;
            geom_data->geom_name = POINT_TYPE;
            break;
        case POINT_XYZM: /* 0x0F — P+V+Z+M */
            geom_data->dimension_flag = DIM_FLAG_3DM;
            geom_data->geom_name = POINT_TYPE;
            break;

        /* 
         *  Point — P flag (0x08) WITHOUT V flag.
         * Props: 0x08=P, 0x09=P+Z, 0x0A=P+M, 0x0B=P+Z+M
         */
        case INVALID_POINT_2D_FLAG:  /* P only (no V) — 2D */
            geom_data->dimension_flag = DIM_FLAG_2D;
            geom_data->geom_name = POINT_TYPE;
            break;
        case INVALID_POINT_3D_FLAG:  /* P+Z (no V) — 3D */
            geom_data->dimension_flag = DIM_FLAG_3D;
            geom_data->geom_name = POINT_TYPE;
            break;
        case INVALID_POINT_2DM_FLAG:  /* P+M (no V) — 2DM */
            geom_data->dimension_flag = DIM_FLAG_2DM;
            geom_data->geom_name = POINT_TYPE;
            break;
        case INVALID_POINT_3DM_FLAG:  /* P+Z+M (no V) — 3DM */
            geom_data->dimension_flag = DIM_FLAG_3DM;
            geom_data->geom_name = POINT_TYPE;
            break;

        /* 2-point LineString — L flag (0x10) set */
        case INVALID_2DLINE_2P: /* 0x10 — L */
        case VALID_2DLINE_2P:   /* 0x14 — L+V */
            geom_data->dimension_flag = DIM_FLAG_2D;
            geom_data->geom_name = LINE_TYPE;
            break;
        case INVALID_3DLINE_2P: /* 0x11 — L+Z */
        case VALID_3DLINE_2P:   /* 0x15 — L+V+Z */
            geom_data->dimension_flag = DIM_FLAG_3D;
            geom_data->geom_name = LINE_TYPE;
            break;
        case INVALID_2DMLINE_2P: /* 0x12 — L+M */
        case VALID_2DMLINE_2P:   /* 0x16 — L+V+M */
            geom_data->dimension_flag = DIM_FLAG_2DM;
            geom_data->geom_name = LINE_TYPE;
            break;
        case INVALID_3DMLINE_2P: /* 0x13 — L+Z+M */
        case VALID_3DMLINE_2P:   /* 0x17 — L+V+Z+M */
            geom_data->dimension_flag = DIM_FLAG_3DM;
            geom_data->geom_name = LINE_TYPE;
            break;

        default:
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Unsupported geometry type")));
    }

    /*
     *  Detect empty geometry for complex types with Z/M flags.
     * When has_npoints_data is true and npoints == 0, this is an
     * empty geometry (e.g., properties 0x05/0x06/0x07 with npoints=0).
     */
    if (geom_data->has_npoints_data && geom_data->npoints == 0)
    {
        geom_data->dimension_flag = DIM_FLAG_EMPTY;
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
    if (geom_data->geom_name != POINT_TYPE) 
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
    for (i = 0; i < (int)check_count; i++) 
    {
        /* Copy the coordinate bytes to a double value */
        memcpy(&coord_value, geom_data->input_data + byte_position, COORD_SIZE);
        if (isnan(coord_value) || isinf(coord_value)) 
        {
            /* Set the NaN flag if a NaN is found */
            geom_data->has_invalid_coords = true;
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
    double lat, lon;
    uint64_t lat_bits, lon_bits;
    uint32_t point_size = COORD_SIZE * 2; /* Size of XY coordinates (2 doubles) */
    int point_count;
    uint32_t offset;
    
    if (geom_data->geom_name != POINT_TYPE)  /* LineString, Polygon, or MultiPoint */
    {
        point_count = geom_data->has_npoints_data ? geom_data->npoints : 2;
        offset = geom_data->has_npoints_data ? HEADER_SIZE + NPOINTS_SIZE : HEADER_SIZE;
    }
    else
    {
        point_count = 1;
        offset = HEADER_SIZE;
    }

    /* Validate SRID first */
    if (!is_valid_geography_srid(geom_data->srid))
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geography.")));
    }

    for (i = 0; i < point_count; i++) 
    {
        uint32_t point_offset = offset + (i * point_size);

        /* Extract latitude (first double) */
        memcpy(&lat_bits, geom_data->input_data + point_offset, sizeof(uint64_t));
        lat_bits = le64toh(lat_bits);
        memcpy(&lat, &lat_bits, sizeof(double));

        /* Extract longitude (second double) */
        memcpy(&lon_bits, geom_data->input_data + point_offset + COORD_SIZE, sizeof(uint64_t));
        lon_bits = le64toh(lon_bits);
        memcpy(&lon, &lon_bits, sizeof(double));

        /* Check NaN */
        if (geom_data->has_invalid_coords || isnan(lat) || isnan(lon))
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Error converting data type varbinary to geography.")));
        }

        /* Check Infinity */
        if (isinf(lat) || isinf(lon))
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Error converting data type varbinary to geography.")));
        }

        /* Latitude range: [-90, 90] */
        if (lat < -90.0 || lat > 90.0)
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Error converting data type varbinary to geography.")));
        }

        /* Longitude range: [-15069, 15069] */
        if (lon < -15069.0 || lon > 15069.0)
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("Error converting data type varbinary to geography.")));
        }
    }
}

/* STEP 6.0: SIZE CALCULATION - Calculate required buffer size for polygon geometries */
static uint32_t
calculate_polygon_size(GeometryData *geom_data)
{
    uint32_t postgis_ring_headers = sizeof(uint32_t) * (geom_data->nfigures + 1);

    return geom_data->input_len 
         - GEOM_TYPE_SIZE 
         - NPOINTS_SIZE          
         + POSTGIS_HEADER_SIZE 
         - geom_data->metadata_size 
         + postgis_ring_headers;
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
    bool has_z = (geom_data->dimension_flag == DIM_FLAG_3D || 
                  geom_data->dimension_flag == DIM_FLAG_3DM);
    bool has_m = (geom_data->dimension_flag == DIM_FLAG_2DM || 
                  geom_data->dimension_flag == DIM_FLAG_3DM);
    uint32_t coord_bytes = COORD_SIZE * 2
                         + (has_z ? COORD_SIZE : 0)
                         + (has_m ? COORD_SIZE : 0);

    return POSTGIS_HEADER_SIZE + SRID_SIZE + coord_bytes;
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

/*
 * Validate that all figures in a linestring are strokes (0x01).
 */
static void
validate_linestring_figures(GeometryData *geom_data)
{
    uint32_t i;
    for (i = 0; i < geom_data->nfigures; i++)
    {
        if (geom_data->figures[i].attribute != FIGURE_STROKE)
            THROW_VARBINARY_CONVERSION_ERROR();
    }
}

/*
 * Validate polygon figure attributes and derive ring point counts.
 *   - Each ring must have >= 4 points
 *   - Total ring points must equal npoints
 */
static void
validate_polygon_figures(GeometryData *geom_data, uint32_t npoints)
{
    uint32_t i, ring_points, total_points = 0;

    for (i = 0; i < geom_data->nfigures; i++)
    {
        /* 
         * Accept both EXTERIOR_RING (0x02) and INTERIOR_RING (0x00)
         * for all polygon figures.
         */
        if (geom_data->figures[i].attribute != FIGURE_EXTERIOR_RING &&
            geom_data->figures[i].attribute != FIGURE_INTERIOR_RING)
        {
            THROW_VARBINARY_CONVERSION_ERROR();
        }

        /* Calculate points in this ring from figure offsets */
        if (i < geom_data->nfigures - 1)
            ring_points = geom_data->figures[i + 1].point_offset 
                        - geom_data->figures[i].point_offset;
        else
            ring_points = npoints - geom_data->figures[i].point_offset;

        /* Closed ring needs minimum 4 points */
        if (ring_points < 4)
            THROW_VARBINARY_CONVERSION_ERROR();

        total_points += ring_points;
    }

    /* Consistency check */
    if (total_points != npoints)
        THROW_VARBINARY_CONVERSION_ERROR();
}

/*
 * Generic validator for multi-geometry figure attributes.
 * Checks that child shapes have correct parent and type.
 * Delegates figure validation based on expected child type.
 */
static void
validate_multi_figures(GeometryData *geom_data, uint32_t npoints,  uint8_t expected_child_type)
{
    uint32_t i;

    /* All child shapes (index 1..nshapes-1) must have parent=0 (root) */
    for (i = 1; i < geom_data->nshapes; i++)
    {
        if (geom_data->shapes[i].parent_index != 0)
            THROW_VARBINARY_CONVERSION_ERROR();
        if (geom_data->shapes[i].type != expected_child_type)
            THROW_VARBINARY_CONVERSION_ERROR();
    }

    /* Validate figure attributes based on child type */
    switch (expected_child_type)
    {
        case SHAPE_POINT:
        case SHAPE_LINESTRING:
            /* All figures must be STROKE */
            validate_linestring_figures(geom_data);
            break;

        case SHAPE_POLYGON:
            /* Figures must be EXTERIOR_RING or INTERIOR_RING */
            validate_polygon_figures(geom_data, npoints);
            break;

        default:
            THROW_VARBINARY_CONVERSION_ERROR();
    }
}
/*
 * parse_figures_and_shapes()
 *
 * Properly parses CLR Figure and Shape arrays from T-SQL spatial binary.
 */
static void
parse_figures_and_shapes(GeometryData *geom_data)
{
    bool     has_z = (geom_data->dimension_flag == DIM_FLAG_3DM || 
                      geom_data->dimension_flag == DIM_FLAG_3D);
    bool     has_m = (geom_data->dimension_flag == DIM_FLAG_3DM || 
                      geom_data->dimension_flag == DIM_FLAG_2DM);
    uint32_t npoints = geom_data->npoints;
    uint32_t coord_data_size = npoints * (COORD_SIZE * 2 
                             + (has_z ? COORD_SIZE : 0) 
                             + (has_m ? COORD_SIZE : 0));
    uint8_t *metadata = geom_data->input_data + HEADER_SIZE 
                       + NPOINTS_SIZE + coord_data_size;
    uint32_t offset = 0;
    uint32_t i;

    /* ── Parse Figure Array ──── */

    CHECK_METADATA_BOUNDS(geom_data, metadata, offset, COUNT_FIELD_SIZE);
    memcpy(&geom_data->nfigures, metadata + offset, sizeof(uint32_t));
    offset += COUNT_FIELD_SIZE;

    if (geom_data->nfigures < 1 || geom_data->nfigures > (uint32_t)npoints)
        THROW_VARBINARY_CONVERSION_ERROR();

    CHECK_METADATA_BOUNDS(geom_data, metadata, offset, geom_data->nfigures * FIGURE_ENTRY_SIZE);

    geom_data->figures = palloc0(geom_data->nfigures * sizeof(Figure));
    for (i = 0; i < geom_data->nfigures; i++)
    {
        geom_data->figures[i].attribute = metadata[offset];
        memcpy(&geom_data->figures[i].point_offset, metadata + offset + 1, sizeof(uint32_t));
        offset += FIGURE_ENTRY_SIZE;

        /* Validate attribute is known V1 value */
        if (geom_data->figures[i].attribute > FIGURE_EXTERIOR_RING)
            THROW_VARBINARY_CONVERSION_ERROR();

        /* First figure must start at point 0 */
        if (i == 0 && geom_data->figures[i].point_offset != 0)
            THROW_VARBINARY_CONVERSION_ERROR();

        /* Point offset must be within bounds */
        if (geom_data->figures[i].point_offset >= (uint32_t)npoints)
            THROW_VARBINARY_CONVERSION_ERROR();

        /* Offsets must be strictly increasing */
        if (i > 0 && geom_data->figures[i].point_offset <= geom_data->figures[i - 1].point_offset)
            THROW_VARBINARY_CONVERSION_ERROR();
    }

    /* ── Parse Shape Array ────────── */

    CHECK_METADATA_BOUNDS(geom_data, metadata, offset, COUNT_FIELD_SIZE);
    memcpy(&geom_data->nshapes, metadata + offset, sizeof(uint32_t));
    offset += COUNT_FIELD_SIZE;

    if (geom_data->nshapes < 1)
        THROW_VARBINARY_CONVERSION_ERROR();

    CHECK_METADATA_BOUNDS(geom_data, metadata, offset, geom_data->nshapes * SHAPE_ENTRY_SIZE);

    geom_data->shapes = palloc0(geom_data->nshapes * sizeof(Shape));
    for (i = 0; i < geom_data->nshapes; i++)
    {
        memcpy(&geom_data->shapes[i].parent_index, 
               metadata + offset, sizeof(int32_t));
        memcpy(&geom_data->shapes[i].figure_offset, 
               metadata + offset + 4, sizeof(uint32_t));
        geom_data->shapes[i].type = metadata[offset + 8];
        offset += SHAPE_ENTRY_SIZE;

        /* Root shape must have parent = -1 */
        if (i == 0 && geom_data->shapes[i].parent_index != -1)
            THROW_VARBINARY_CONVERSION_ERROR();

        /* Figure offset must be valid (or 0xFFFFFFFF for empty) */
        if (geom_data->shapes[i].figure_offset >= geom_data->nfigures &&
            geom_data->shapes[i].figure_offset != 0xFFFFFFFF)
            THROW_VARBINARY_CONVERSION_ERROR();
    }

    geom_data->metadata_size = offset;

    /* ── Resolve geometry type from root shape ────────────── */
    switch (geom_data->shapes[0].type)
    {
        case SHAPE_LINESTRING:
            geom_data->geom_name = LINE_TYPE;
            validate_linestring_figures(geom_data);
            break;

        case SHAPE_POLYGON:
            geom_data->geom_name = POLYGON_TYPE;
            validate_polygon_figures(geom_data, npoints);
            break;

        case SHAPE_POINT:
            geom_data->geom_name = POINT_TYPE;
            break;

        case SHAPE_MULTIPOINT:
            geom_data->geom_name = MULTIPOINT_TYPE;
            validate_multi_figures(geom_data, npoints, SHAPE_POINT);
            break;

        default:
            ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("Unsupported geometry type: %d", 
                        geom_data->shapes[0].type)));
    }
}



/* Copy polygon ring coordinates from separated XYZ/M format to interleaved format */
static void
copy_polygon_ring_coordinates(uint8_t *src, uint8_t *dst, uint32_t total_points, uint32_t start_point, uint32_t ring_points, uint32_t dimension_flag)
{
    bool has_z = dimension_flag == DIM_FLAG_3DM || dimension_flag == DIM_FLAG_3D,
         has_m = dimension_flag == DIM_FLAG_3DM || dimension_flag == DIM_FLAG_2DM;
    uint32_t i, 
             dst_offset = 0;
    
    for (i = 0; i < ring_points; i++) 
    {
        uint32_t point_idx = start_point + i;
        
        /* Copy XY coordinates */
        memcpy(dst + dst_offset, src + (point_idx * COORD_SIZE * 2), COORD_SIZE * 2);
        dst_offset += COORD_SIZE * 2;
        
        /* Copy Z coordinate if present */
        if (has_z) 
        {
            memcpy(dst + dst_offset, src + (total_points * COORD_SIZE * 2) + (point_idx * COORD_SIZE), COORD_SIZE);
            dst_offset += COORD_SIZE;
        }
        
        /* Copy M coordinate if present */
        if (has_m) 
        {
            uint32_t m_offset = (total_points * COORD_SIZE * 2) + (has_z ? total_points * COORD_SIZE : 0) + (point_idx * COORD_SIZE);
            memcpy(dst + dst_offset, src + m_offset, COORD_SIZE);
            dst_offset += COORD_SIZE;
        }
    }
}

static void
handle_polygon_coordinates(GeometryData *geom_data, uint8 *result_data)
{
    uint32_t npoints = geom_data->has_npoints_data ? geom_data->npoints : 2;
    uint32_t i, offset = 0;
    bool     has_z = (geom_data->dimension_flag == DIM_FLAG_3DM || 
                      geom_data->dimension_flag == DIM_FLAG_3D);
    bool     has_m = (geom_data->dimension_flag == DIM_FLAG_3DM || 
                      geom_data->dimension_flag == DIM_FLAG_2DM);
    uint32_t point_stride = COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0) + (has_m ? COORD_SIZE : 0);
    uint8_t *src = geom_data->input_data + HEADER_SIZE + (geom_data->has_npoints_data ? NPOINTS_SIZE : 0);
    uint8_t *dst = result_data + POSTGIS_HEADER_SIZE + SRID_SIZE + NPOINTS_SIZE;
    
    /* Write number of rings = number of figures */
    memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, &geom_data->nfigures, sizeof(uint32_t));
    
    for (i = 0; i < geom_data->nfigures; i++)
    {
        uint32_t start_point = geom_data->figures[i].point_offset;
        uint32_t ring_points = (i < geom_data->nfigures - 1) ? geom_data->figures[i + 1].point_offset - start_point : npoints - start_point;
        
        /* Write ring point count */
        memcpy(dst + offset, &ring_points, sizeof(uint32_t));
        offset += sizeof(uint32_t);
        
        /* Copy interleaved coordinates for this ring */
        copy_polygon_ring_coordinates(src, dst + offset, npoints, start_point, ring_points, geom_data->dimension_flag);
        
        offset += ring_points * point_stride;
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
    bool has_z = (geom_data->dimension_flag == DIM_FLAG_3D || 
                  geom_data->dimension_flag == DIM_FLAG_3DM);
    bool has_m = (geom_data->dimension_flag == DIM_FLAG_2DM || 
                  geom_data->dimension_flag == DIM_FLAG_3DM);
    
    /* 
     * Source offset depends on format:
     * - P-flag format: coordinates start at HEADER_SIZE (no npoints field)
     * - Complex format: coordinates start at HEADER_SIZE + NPOINTS_SIZE
     */
    uint32_t src_offset = HEADER_SIZE + (geom_data->has_npoints_data ? NPOINTS_SIZE : 0);
    uint8   *src = geom_data->input_data + src_offset;
    uint8   *dst = result_data + POSTGIS_HEADER_SIZE + SRID_SIZE;

    /* Copy XY coordinates */
    memcpy(dst, src, COORD_SIZE * 2);
    dst += COORD_SIZE * 2;

    /* Copy Z (stored after all XY; for npoints=1, right after XY) */
    if (has_z)
    {
        memcpy(dst, src + COORD_SIZE * 2, COORD_SIZE);
        dst += COORD_SIZE;
    }

    /* Copy M (stored after all Z, or after XY if no Z) */
    if (has_m)
    {
        uint32_t m_offset = COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0);
        memcpy(dst, src + m_offset, COORD_SIZE);
    }
}
/* Get WKB type code with PostGIS dimension encoding (+1000 Z, +2000 M, +3000 ZM) */

static inline uint32_t
get_wkb_type(uint32_t base_type, bool has_z, bool has_m)
{
    if (has_z && has_m) return base_type + 3000;
    if (has_z)          return base_type + 1000;
    if (has_m)          return base_type + 2000;
    return base_type;
}

/* Write interleaved point (XY [Z] [M]) from CLR columnar layout */
static uint32_t
write_interleaved_point(uint8 *dst, uint8 *src_base, uint32_t total_points, uint32_t pt_idx, bool has_z, bool has_m)
{
    uint32_t pos = 0;

    memcpy(dst + pos, src_base + (pt_idx * COORD_SIZE * 2), COORD_SIZE * 2);
    pos += COORD_SIZE * 2;

    if (has_z)
    {
        memcpy(dst + pos, src_base + (total_points * COORD_SIZE * 2) + (pt_idx * COORD_SIZE), COORD_SIZE);
        pos += COORD_SIZE;
    }

    if (has_m)
    {
        uint32_t m_base = total_points * COORD_SIZE * 2 + (has_z ? total_points * COORD_SIZE : 0);
        memcpy(dst + pos, src_base + m_base + (pt_idx * COORD_SIZE), COORD_SIZE);
        pos += COORD_SIZE;
    }

    return pos;
}

/*
 * Write a single WKB Point child from CLR columnar data.
 */
static uint32_t
write_wkb_point_child(uint8 *dst, uint8 *src_base, uint32_t total_points, uint32_t pt_idx, bool has_z, bool has_m)
{
    uint32_t wkb_type = get_wkb_type(POINT_TYPE, has_z, has_m);
    uint32_t pos = 0;

    dst[pos++] = 0x01;  /* little endian */
    memcpy(dst + pos, &wkb_type, sizeof(uint32_t));
    pos += sizeof(uint32_t);
    pos += write_interleaved_point(dst + pos, src_base, total_points, pt_idx, has_z, has_m);
    return pos;
}


/* Write child WKB entry based on parent multi-type */
static uint32_t
write_child_wkb(uint8 *dst, uint8 *src_base, uint32_t total_points, uint32_t pt_start, uint8 parent_type, bool has_z, bool has_m)
{
    switch (parent_type)
    {
        case MULTIPOINT_TYPE:
            return write_wkb_point_child(dst, src_base, total_points, pt_start, has_z, has_m);

        default:
            THROW_VARBINARY_CONVERSION_ERROR();
            return 0;
    }
}

/*
 * Calculate WKB size for child geometry
 */

static uint32_t
calculate_child_wkb_size(uint8 parent_type, bool has_z, bool has_m)
{
    uint32_t coord_per_point = COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0)  + (has_m ? COORD_SIZE : 0);

    switch (parent_type)
    {
        case MULTIPOINT_TYPE:
            /* byte_order(1) + type(4) + coords */
            return 5 + coord_per_point;

        default:
            return 0;
    }
}

/* Get child geometry point and figure ranges */


static void
get_child_info(GeometryData *geom_data, uint32_t child_idx,
               uint32_t *pt_start, uint32_t *child_npoints,
               uint32_t *fig_start, uint32_t *fig_end)
{
    uint32_t pt_end;

    *fig_start = geom_data->shapes[child_idx].figure_offset;
    *pt_start  = geom_data->figures[*fig_start].point_offset;

    if (child_idx < geom_data->nshapes - 1)
        *fig_end = geom_data->shapes[child_idx + 1].figure_offset;
    else
        *fig_end = geom_data->nfigures;

    if (*fig_end < geom_data->nfigures)
        pt_end = geom_data->figures[*fig_end].point_offset;
    else
        pt_end = geom_data->npoints;

    *child_npoints = pt_end - *pt_start;
}

/*
 * Convert CLR multi-geometry binary to PostGIS WKB.
 */
static bytea*
handle_multi_to_postgis(GeometryData *geom_data)
{
    bool     has_z = (geom_data->dimension_flag == DIM_FLAG_3D || geom_data->dimension_flag == DIM_FLAG_3DM);
    bool     has_m = (geom_data->dimension_flag == DIM_FLAG_2DM || geom_data->dimension_flag == DIM_FLAG_3DM);
    uint32_t nchildren = geom_data->nshapes - 1;  /* exclude root shape */
    uint32_t result_size;
    uint8    postgis_header[POSTGIS_HEADER_SIZE];
    uint8    postgis_type_byte;
    bytea   *result;
    uint8   *result_data, *src;
    uint32_t offset, i;

    /* Determine PostGIS WKB type byte */
    switch (geom_data->geom_name)
    {
        case MULTIPOINT_TYPE:     
          postgis_type_byte = 0x04; 
          break;

        default:
            THROW_VARBINARY_CONVERSION_ERROR();
            return NULL;
    }

    /* Source coordinate data base (after header + npoints) */
    src = geom_data->input_data + HEADER_SIZE + NPOINTS_SIZE;

    /* Calculate total WKB size: header + SRID + nchildren(4) + all children */
    result_size = POSTGIS_HEADER_SIZE + SRID_SIZE + sizeof(uint32_t);

    for (i = 0; i < nchildren; i++)
    {
        uint32_t pt_start, child_npoints, fig_start, fig_end;
        get_child_info(geom_data, i + 1, &pt_start, &child_npoints, &fig_start, &fig_end);

        result_size += calculate_child_wkb_size(geom_data->geom_name, has_z, has_m);
    }

    /* Build PostGIS header */
    memcpy(postgis_header, POSTGIS_HEADER_MULTIPOINT, POSTGIS_HEADER_SIZE);
    postgis_header[1] = postgis_type_byte;
    if (geom_data->dimension_flag <= MAX_DIMENSION_FLAG)
        postgis_header[HEADER_DIMENSION_POS] = DIMENSION_HEADERS[geom_data->dimension_flag];

    /* Allocate result */
    result = (bytea *)palloc(VARHDRSZ + result_size);
    SET_VARSIZE(result, VARHDRSZ + result_size);
    result_data = (uint8 *)VARDATA(result);

    /* Write header + SRID + child count */
    memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
    offset = POSTGIS_HEADER_SIZE + SRID_SIZE;
    memcpy(result_data + offset, &nchildren, sizeof(uint32_t));
    offset += sizeof(uint32_t);

    /* Write each child geometry */
    for (i = 0; i < nchildren; i++)
    {
        uint32_t pt_start, child_npoints, fig_start, fig_end;
        get_child_info(geom_data, i + 1, &pt_start, &child_npoints, &fig_start, &fig_end);

        offset += write_child_wkb(result_data + offset, src, geom_data->npoints, pt_start, geom_data->geom_name, has_z, has_m);
    }

    return result;
}

/* STEP 6.6: NON-EMPTY GEOMETRY PROCESSING - Convert non-empty geometries to PostGIS format */
static bytea*
handle_non_empty_geometry_bytea(GeometryData *geom_data)
{
    uint8 postgis_header[POSTGIS_HEADER_SIZE] = POSTGIS_HEADER_POINT;
    bytea *result;
    uint8 *result_data;
    uint32_t new_data_size;
    
    /* Update dimension information in header */
    if (geom_data->dimension_flag <= MAX_DIMENSION_FLAG) 
        postgis_header[HEADER_DIMENSION_POS] = DIMENSION_HEADERS[geom_data->dimension_flag];
    
    /*
     * For complex geometries (has_npoints_data=true, geom_name not yet set),
     * parse CLR figure/shape metadata to determine the actual geometry type.
     */
    if (geom_data->has_npoints_data && geom_data->geom_name == 0)
        parse_figures_and_shapes(geom_data);
    
    /* Calculate buffer size and set PostGIS geometry type byte */
    switch (geom_data->geom_name)
    {
        case POINT_TYPE:
            new_data_size = calculate_point_size(geom_data);
            break;
        case LINE_TYPE:
            postgis_header[1] = LINE_TYPE;
            new_data_size = calculate_linestring_size(geom_data);
            break;
        case POLYGON_TYPE:
            postgis_header[1] = POLYGON_TYPE;
            new_data_size = calculate_polygon_size(geom_data);
            break;
         case MULTIPOINT_TYPE:
            return handle_multi_to_postgis(geom_data);
        default:
            THROW_VARBINARY_CONVERSION_ERROR();
            return NULL;  /* unreachable */
    }
    
    /* Allocate result buffer */
    result = (bytea *) palloc0(VARHDRSZ + new_data_size);
    SET_VARSIZE(result, VARHDRSZ + new_data_size);
    result_data = (uint8 *)VARDATA(result);
    
    /* Write PostGIS header + SRID */
    memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
    
    /* Copy coordinates based on geometry type */
    switch (geom_data->geom_name)
    {
        case POLYGON_TYPE:
            handle_polygon_coordinates(geom_data, result_data);
            break;
        case LINE_TYPE:
            handle_linestring_coordinates(geom_data, result_data);
            break;
        case POINT_TYPE:
            handle_point_coordinates(geom_data, result_data);
            break;
    }
    
    return result;
}

/* STEP 6.7: EMPTY POINT CREATION - Generate empty point with NaN coordinates */
static bytea*
create_empty_point(GeometryData *geom_data)
{
    uint8 postgis_header[POSTGIS_HEADER_SIZE] = POSTGIS_HEADER_POINT;
    bytea *result = (bytea *) palloc0(VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE * 2);
    uint8 *result_data;
    
    SET_VARSIZE(result, VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE * 2);
    result_data = (uint8 *)VARDATA(result);
    
    memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, NAN_COORD, COORD_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE + COORD_SIZE, NAN_COORD, COORD_SIZE);
    
    return result;
}

/* STEP 6.8: EMPTY GEOMETRY CREATION */
static bytea*
create_empty_geometry(GeometryData *geom_data)
{
    uint8 postgis_header[POSTGIS_HEADER_SIZE] = POSTGIS_HEADER_LINESTRING; /* keeping default as linestring, will be modified as per other geometries */
    bytea *result = (bytea *) palloc0(VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + EMPTY_GEOM_DATA_SIZE);
    uint8 *result_data;

    if (geom_data->geom_name == POLYGON_TYPE)
        postgis_header[1] = 0x03;
    else if (geom_data->geom_name == MULTIPOINT_TYPE)
        postgis_header[1] = 0x04;
    
    SET_VARSIZE(result, VARHDRSZ + POSTGIS_HEADER_SIZE + SRID_SIZE + EMPTY_GEOM_DATA_SIZE);
    result_data = (uint8 *)VARDATA(result);
    
    memcpy(result_data, postgis_header, POSTGIS_HEADER_SIZE);
    memcpy(result_data + POSTGIS_HEADER_SIZE, geom_data->input_data, SRID_SIZE);
    memset(result_data + POSTGIS_HEADER_SIZE + SRID_SIZE, 0, EMPTY_GEOM_DATA_SIZE);
    
    return result;
}

/* STEP 6.9: EMPTY GEOMETRY PROCESSING - Process empty geometries and delegate to appropriate handlers */
static bytea*
handle_empty_geometry_bytea(GeometryData *geom_data)
{
    uint8    last_emptybyte;
    uint8    props = geom_data->geom_type;
    
    if (props == 0x04)
    {
        /*
         * Properties = 0x04 (V only): uses EMPTY_COORD pattern.
         * Layout: [header(6)] [EMPTY_COORD(20)] [shape_type(1)]
         */
        if (geom_data->input_len < HEADER_SIZE + sizeof(EMPTY_COORD) + 1)
            THROW_VARBINARY_CONVERSION_ERROR();
        
        if (memcmp(geom_data->input_data + HEADER_SIZE, EMPTY_COORD, sizeof(EMPTY_COORD)) != 0) 
        {
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Unsupported geometry type")));
        }
        
        last_emptybyte = geom_data->input_data[sizeof(EMPTY_COORD) + HEADER_SIZE];
    }
    else
    {
        /*
         * Properties with Z/M flags (0x05, 0x06, 0x07) and npoints=0.
         *
         * Binary layout after header:
         *   npoints(4)        = 0x00000000
         *   nfigures(4)       = 0x00000000
         *   nshapes(4)        = 0x01000000
         *   shape parent(4)   = 0xFFFFFFFF
         *   shape fig_off(4)  = 0xFFFFFFFF
         *   shape type(1)     = geometry type byte
         *
         * Shape type is at: HEADER_SIZE + 4 + 4 + 4 + 4 + 4 = HEADER_SIZE + 20
         */
        uint32_t shape_type_offset = SHAPE_TYPE_OFFSET;

        
        if (geom_data->input_len < shape_type_offset + 1)
            THROW_VARBINARY_CONVERSION_ERROR();
        
        last_emptybyte = geom_data->input_data[shape_type_offset];
    }
    
    switch(last_emptybyte) 
    {
        case EMPTY_POINT_TYPE_LASTBYTE:
            return create_empty_point(geom_data);
        case EMPTY_LINE_TYPE_LASTBYTE:
            geom_data->geom_name = LINE_TYPE;
            return create_empty_geometry(geom_data);
        case EMPTY_POLYGON_TYPE_LASTBYTE:
            geom_data->geom_name = POLYGON_TYPE;
            return create_empty_geometry(geom_data);
        case EMPTY_MULTIPOINT_TYPE_LASTBYTE:  /* 0x04 */
            geom_data->geom_name = MULTIPOINT_TYPE;
            return create_empty_geometry(geom_data);
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

/*
 * Free all memory associated with a GeometryData structure.
 */
static void
free_geometry_data(GeometryData *geom_data)
{
    if (geom_data == NULL)
        return;
    if (geom_data->figures)
        pfree(geom_data->figures);
    if (geom_data->shapes)
        pfree(geom_data->shapes);
    pfree(geom_data);
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
        geom_data->has_invalid_coords) 
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
    free_geometry_data(geom_data);
    
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

    /* Process the geography data into PostGIS-compatible format */
    result = process_geometry_data(geom_data);

    /* 
     * Extract and validate latitude values from binary data
     * 1. Copy 8 bytes from the input data at appropriate offset
     * 2. Convert from little-endian to host byte order
     * 3. Interpret the bytes as a double-precision floating point value
     * 4. Validate the latitude is within valid range (-90 to 90 degrees)
     */
    if(geom_data->dimension_flag != DIM_FLAG_EMPTY)
        validate_geography_latitude_bytes(geom_data);
    
    /* Convert the processed binary data to a PostGIS geography object */
    UpdateFunctionCallInfo(fcinfo_local, 1, PointerGetDatum(result));
    geography_result = lwgeom_from_bytea_p(fcinfo_local);

    /* Free allocated memory */
    free_geometry_data(geom_data);
    
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

    /*
     * Point fast-path: a Point is always valid (no self-intersection possible)
     * and has exactly 1 vertex (or 0 if empty). Skipping the GEOS validity pass
     * and the npoints deserialization saves two full geometry walks per row on
     * point-heavy workloads (CAST(point AS VARBINARY), STAsBinary(point), etc).
     */
    if (gserialized_typecode(input_datum) == LWTYPE_POINT)
    {
        geom_data->is_valid = true;
        geom_data->npoints  = geom_data->is_empty ? 0 : 1;
    }
    else
    {
        geom_data->is_valid = DatumGetBool(call_postgis_func(st_isvalid_p, input_datum));
        geom_data->npoints  = DatumGetInt32(call_postgis_func(st_npoints_p, input_datum));
    }

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
    return (geom_type == POINT_TYPE || geom_type == LINE_TYPE || geom_type == POLYGON_TYPE || geom_type == MULTIPOINT_TYPE) &&
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
                        geom_data->geom_type = geom_data->is_valid ? POINT_XY : INVALID_POINT_2D_FLAG;
                        geom_data->coord_size = COORD_SIZE_XY;
                        break;
                    case LINE_TYPE:
                        geom_data->geom_type = geom_data->is_valid ? 
                            (geom_data->npoints > 2 ? VALID_2DLINE_MP : VALID_2DLINE_2P) :
                            (geom_data->npoints > 2 ? INVALID_2DLINE_MP : INVALID_2DLINE_2P);
                        geom_data->coord_size = COORD_SIZE_XY * geom_data->npoints;
                        break;
                    case POLYGON_TYPE:
                        geom_data->geom_type = geom_data->is_valid ? VALID_POLYGON_2D : INVALID_POLYGON_2D;
                        geom_data->coord_size = COORD_SIZE_XY * geom_data->npoints;
                        break;
                     case MULTIPOINT_TYPE:
                        geom_data->geom_type = VALID_2DLINE_MP;  /* 0x04 — same props byte */
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
                    geom_data->geom_type = geom_data->is_valid ? POINT_XYZ : INVALID_POINT_3D_FLAG;
                    geom_data->coord_size = COORD_SIZE_XYZ;
                    break;
                case LINE_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? 
                        (geom_data->npoints > 2 ? VALID_3DLINE_MP : VALID_3DLINE_2P) :
                        (geom_data->npoints > 2 ? INVALID_3DLINE_MP : INVALID_3DLINE_2P);
                    geom_data->coord_size = COORD_SIZE_XYZ * geom_data->npoints;
                    break;
                case POLYGON_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? VALID_POLYGON_3D : INVALID_POLYGON_3D;
                    geom_data->coord_size = COORD_SIZE_XYZ * geom_data->npoints;
                    break;
                case MULTIPOINT_TYPE:
                    geom_data->geom_type = VALID_3DLINE_MP;  /* 0x05 */
                    geom_data->coord_size = COORD_SIZE_XYZ * geom_data->npoints;
                    break;
            }
            break;
        case POSTGIS_DIM_XYZM:
            /* 3D geometry with measure (XYZM) */
            switch (geom_data->postgis_geom_type)
            {
                case POINT_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? POINT_XYZM : INVALID_POINT_3DM_FLAG;
                    geom_data->coord_size = COORD_SIZE_XYZM;
                    break;
                case LINE_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? 
                        (geom_data->npoints > 2 ? VALID_3DMLINE_MP : VALID_3DMLINE_2P) :
                        (geom_data->npoints > 2 ? INVALID_3DMLINE_MP : INVALID_3DMLINE_2P);
                    geom_data->coord_size = COORD_SIZE_XYZM * geom_data->npoints;
                    break;
                case POLYGON_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? VALID_POLYGON_3DM : INVALID_POLYGON_3DM;
                    geom_data->coord_size = COORD_SIZE_XYZM * geom_data->npoints;
                    break;
                    
                 case MULTIPOINT_TYPE:
                    geom_data->geom_type = VALID_3DMLINE_MP;  /* 0x07 */
                    geom_data->coord_size = COORD_SIZE_XYZM * geom_data->npoints;
                    break;
            }
            break;
        case POSTGIS_DIM_XYM:
            /* 2D geometry with measure (XYM) */
            switch (geom_data->postgis_geom_type)
            {
                case POINT_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? POINT_XYM : INVALID_POINT_2DM_FLAG;
                    geom_data->coord_size = COORD_SIZE_XYM;
                    break;
                case LINE_TYPE:
                    geom_data->geom_type = geom_data->is_valid ? 
                        (geom_data->npoints > 2 ? VALID_2DMLINE_MP : VALID_2DMLINE_2P) :
                        (geom_data->npoints > 2 ? INVALID_2DMLINE_MP : INVALID_2DMLINE_2P);
                    geom_data->coord_size = COORD_SIZE_XYM * geom_data->npoints;
                    break;
                case POLYGON_TYPE:
                    geom_data->geom_type = geom_data->is_valid ?   VALID_POLYGON_2DM : INVALID_POLYGON_2DM;
                    geom_data->coord_size = COORD_SIZE_XYM * geom_data->npoints;
                    break;
                case MULTIPOINT_TYPE:
                    geom_data->geom_type = VALID_2DMLINE_MP;  /* 0x06 */
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
/*
 * CLR Binary Metadata Serialization
 * 
 * T-SQL CLR binary layout after coordinate data:
 *   [nfigures:4] [Figure entries: 5 bytes each]
 *   [nshapes:4]  [Shape entries:  9 bytes each]
 *
 * Figure entry (5 bytes): [attribute:1][point_offset:4]
 *   attribute: 0x00 = INTERIOR_RING
 *              0x01 = STROKE  
 *              0x02 = EXTERIOR_RING
 *
 * Shape entry (9 bytes): [parent_index:4][figure_offset:4][type:1]
 *   type: 1=Point, 2=LineString, 3=Polygon,
 *         4=MultiPoint, 5=MultiLineString,
 *         6=MultiPolygon, 7=GeometryCollection
 */

/*
 * Write a single CLR Figure entry (5 bytes).
 * Returns: FIGURE_ENTRY_SIZE (always 5)
 */
static inline uint32_t
write_figure_entry(uint8 *dst, uint8_t attribute, uint32_t point_offset)
{
    dst[0] = attribute;
    memcpy(dst + 1, &point_offset, sizeof(uint32_t));
    return FIGURE_ENTRY_SIZE;
}

/*
 * Write a single CLR Shape entry (9 bytes).
 * Returns: SHAPE_ENTRY_SIZE (always 9)
 */
static inline uint32_t
write_shape_entry(uint8 *dst, int32_t parent_index, uint32_t figure_offset, uint8_t type)
{
    memcpy(dst, &parent_index, sizeof(int32_t));
    memcpy(dst + sizeof(int32_t), &figure_offset, sizeof(uint32_t));
    dst[sizeof(int32_t) + sizeof(uint32_t)] = type;
    return SHAPE_ENTRY_SIZE;
}

/*
 * Get per-point byte stride based on dimension flags.
 */
static inline uint32_t
get_coord_stride(uint8 srid_flag)
{
    uint8 dim_mask = srid_flag & DIMENSION_MASK;
    bool has_z = (dim_mask == POSTGIS_DIM_XYZ || dim_mask == POSTGIS_DIM_XYZM);
    bool has_m = (dim_mask == POSTGIS_DIM_XYM || dim_mask == POSTGIS_DIM_XYZM);
    return COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0) + (has_m ? COORD_SIZE : 0);
}

/*
 * Extract ring count from PostGIS polygon binary data.
 */
static inline int32
get_polygon_ring_count(GeoDataInfo *geom_data, bool is_geography)
{
    int offset = (is_geography || geom_data->has_srid)  ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID;
    return *(int32 *)(geom_data->byte_data + offset);
}

/*
 * Write CLR metadata for LineString (>2 points).
 *
 * Output:
 *   nfigures(4)=1  figure[0]: STROKE, offset=0
 *   nshapes(4)=1   shape[0]: parent=-1, fig=0, type=LINESTRING
 *
 * Total: 4 + 5 + 4 + 9 = 22 bytes
 */
static uint32_t
write_linestring_clr_metadata(uint8 *dst)
{
    uint32_t pos = 0;
    int32_t  count;

    /* Figure array */
    count = 1;
    memcpy(dst + pos, &count, COUNT_FIELD_SIZE);
    pos += COUNT_FIELD_SIZE;
    pos += write_figure_entry(dst + pos, FIGURE_STROKE, 0);

    /* Shape array */
    count = 1;
    memcpy(dst + pos, &count, COUNT_FIELD_SIZE);
    pos += COUNT_FIELD_SIZE;
    pos += write_shape_entry(dst + pos, -1, 0, SHAPE_LINESTRING);

    return pos;
}

/*
 * Write CLR metadata for Polygon.
 *
 * Output:
 *   nfigures(4)=num_rings
 *     figure[0]: EXTERIOR_RING, offset=0
 *     figure[1]: INTERIOR_RING, offset=ring0_pts
 *     figure[2]: INTERIOR_RING, offset=ring0_pts+ring1_pts
 *     ...
 *   nshapes(4)=1
 *     shape[0]: parent=-1, fig=0, type=POLYGON
 *
 * Total: 4 + (num_rings × 5) + 4 + 9 bytes
 */
static uint32_t
write_polygon_clr_metadata(uint8 *dst, GeoDataInfo *geom_data, bool is_geography)
{
    int      data_offset = (is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID;
    uint8    *src_start = geom_data->byte_data + data_offset;
    int32    num_rings  = *(int32 *)src_start;
    uint8    *src = src_start + sizeof(int32);
    uint32_t stride = get_coord_stride(geom_data->srid_flag);
    uint32_t pos = 0;
    uint32_t cumulative_points = 0;
    int32_t  nshapes = 1;
    int      i;

    /* ── Figure Array ─────────────────────── */
    memcpy(dst + pos, &num_rings, COUNT_FIELD_SIZE);
    pos += COUNT_FIELD_SIZE;

    for (i = 0; i < num_rings; i++)
    {
        int32    ring_npoints = *(int32 *)src;
        uint8_t  attr = (i == 0) ? FIGURE_EXTERIOR_RING : FIGURE_INTERIOR_RING;

        pos += write_figure_entry(dst + pos, attr, cumulative_points);

        cumulative_points += ring_npoints;
        src += sizeof(int32) + ring_npoints * stride;
    }

    /* ── Shape Array ──────────────────────── */
    memcpy(dst + pos, &nshapes, COUNT_FIELD_SIZE);
    pos += COUNT_FIELD_SIZE;
    pos += write_shape_entry(dst + pos, -1, 0, SHAPE_POLYGON);

    return pos;
}

/*
 * Write CLR metadata for MultiPoint.
 *
 * Output:
 *   nfigures(4)=npoints
 *     figure[i]: STROKE, offset=i    (one figure per point)
 *   nshapes(4)=npoints+1
 *     shape[0]: parent=-1, fig=0, type=MULTIPOINT (root)
 *     shape[i]: parent=0, fig=i-1, type=POINT     (children)
 *
 * Total: 4 + (npoints × 5) + 4 + ((npoints+1) × 9)
 */
static uint32_t
write_multipoint_clr_metadata(uint8 *dst, int npoints)
{
    uint32_t pos = 0;
    int32_t  count;
    int      i;

    /* Figure array: one STROKE figure per point */
    count = npoints;
    memcpy(dst + pos, &count, COUNT_FIELD_SIZE);
    pos += COUNT_FIELD_SIZE;

    for (i = 0; i < npoints; i++)
    {
        uint32_t pt_offset = (uint32_t)i;
        pos += write_figure_entry(dst + pos, FIGURE_STROKE, pt_offset);
    }

    /* Shape array: root MultiPoint + one Point child per point */
    count = npoints + 1;
    memcpy(dst + pos, &count, COUNT_FIELD_SIZE);
    pos += COUNT_FIELD_SIZE;

    /* Root shape: MultiPoint */
    pos += write_shape_entry(dst + pos, -1, 0, SHAPE_MULTIPOINT);

    /* Child shapes: one Point per point */
    for (i = 0; i < npoints; i++)
    {
        pos += write_shape_entry(dst + pos, 0, (uint32_t)i, SHAPE_POINT);
    }

    return pos;
}

/*
 * CLR metadata writer — dispatches by geometry type.
 * Returns: total bytes written to dst.
 */
static uint32_t
write_clr_metadata(uint8 *dst, GeoDataInfo *geom_data, bool is_geography)
{
    switch (geom_data->postgis_geom_type)
    {
        case LINE_TYPE:
            return (geom_data->npoints > 2) 
                 ? write_linestring_clr_metadata(dst) 
                 : 0;

        case POLYGON_TYPE:
            return write_polygon_clr_metadata(dst, geom_data, is_geography);

        default:
            return 0;  /* Points and 2-point lines have no metadata */
    }
}

/*
 * Calculate CLR metadata size for buffer allocation.
 *
 * Formula: COUNT_FIELD_SIZE + (nfigures × FIGURE_ENTRY_SIZE)
 *        + COUNT_FIELD_SIZE + (nshapes  × SHAPE_ENTRY_SIZE)
 *
 * Returns 0 for types with no metadata (points, 2-point lines).
 */
static uint32_t
calculate_clr_metadata_size(GeoDataInfo *geom_data, bool is_geography)
{
    uint32_t nfigures = 0;
    uint32_t nshapes  = 0;

    switch (geom_data->postgis_geom_type)
    {
        case POINT_TYPE:
            return 0;

        case LINE_TYPE:
            if (geom_data->npoints <= 2)
                return 0;
            nfigures = 1;
            nshapes  = 1;
            break;

        case POLYGON_TYPE:
            nfigures = get_polygon_ring_count(geom_data, is_geography);
            nshapes  = 1;
            break;

        case MULTIPOINT_TYPE:
            nfigures = geom_data->npoints;    /* one figure per point */
            nshapes  = geom_data->npoints + 1; /* root + one per point */
            break;

        default:
            return 0;
    }

    return COUNT_FIELD_SIZE + (nfigures * FIGURE_ENTRY_SIZE) + COUNT_FIELD_SIZE + (nshapes  * SHAPE_ENTRY_SIZE);
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

    /* De-interleave coordinates into columnar format */
    copy_xy_coords(dst, src, geom_data->npoints, stride);
    if (has_z) copy_z_coords(dst, src, geom_data->npoints, stride);
    if (has_m) copy_m_coords(dst, src, geom_data->npoints, stride, has_z);
    /* Write CLR figure + shape metadata after coordinates */
    if (geom_data->npoints > 2)
        write_clr_metadata(dst + geom_data->coord_size,geom_data, is_geography);
    
    return result;
}

static bytea*
handle_polygon_type_data(GeoDataInfo *geom_data, uint8 *result_data, bytea *result, bool is_geography)
{
    int offset = (is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID;

    uint8 *src_start = geom_data->byte_data + offset;
    uint8 *dst = result_data + HEADER_SIZE + NPOINTS_SIZE;
    uint8  dim_mask = geom_data->srid_flag & DIMENSION_MASK;

    bool has_z = (dim_mask == POSTGIS_DIM_XYZ || dim_mask == POSTGIS_DIM_XYZM);
    bool has_m = (dim_mask == POSTGIS_DIM_XYM || dim_mask == POSTGIS_DIM_XYZM);

    int stride = COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0) + (has_m ? COORD_SIZE : 0);
    int num_rings = *(int32 *)src_start;
    uint8 *src;
    int ring_idx, ring_npoints;
    int total_points_copied = 0;
    int z_points_copied = 0;
    int m_points_copied = 0;
    int z_offset;        
    uint8 *metadata_pos;

    /* First pass: copy all XY coordinates from all rings */
    src = src_start + sizeof(int32);
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

    /* ── Write CLR metadata after all coordinates ──── */
    metadata_pos = dst + (total_points_copied * COORD_SIZE * 2) + (has_z ? total_points_copied * COORD_SIZE : 0) + (has_m ? total_points_copied * COORD_SIZE : 0);

    write_clr_metadata(metadata_pos, geom_data, is_geography);

    return result;
}

/*
 * handle_multipoint_type_data()
 *
 * Converts PostGIS MultiPoint WKB (interleaved per-point) to
 * T-SQL CLR columnar format:
 *   [npoints(4)] [X1 Y1 X2 Y2 ...] [Z1 Z2 ...] [M1 M2 ...] [metadata]
 *
 * PostGIS MultiPoint WKB layout:
 *   byte_order(1) + type(4) + numpoints(4)
 *   For each point: byte_order(1) + type(4) + X(8) + Y(8) [+ Z(8)] [+ M(8)]
 */
static bytea*
handle_multipoint_type_data(GeoDataInfo *geom_data, uint8 *result_data, bytea *result, bool is_geography)
{
    uint32_t src_offset;
    uint8    dim_mask = geom_data->srid_flag & DIMENSION_MASK;
    bool     has_z = (dim_mask == POSTGIS_DIM_XYZ || dim_mask == POSTGIS_DIM_XYZM);
    bool     has_m = (dim_mask == POSTGIS_DIM_XYM || dim_mask == POSTGIS_DIM_XYZM);
    int      npoints = geom_data->npoints;
    int      i;
    uint32_t offset;
    uint32_t temp_src;
    int      wkb_point_size;  /* Size of one point in WKB */
    uint8   *dst;
    uint8   *metadata_pos;

    /* Source offset past PostGIS header + SRID + MultiPoint WKB header */
    /* PostGIS WKB: byte_order(1) + type(4) + numpoints(4) = 9 bytes */
    src_offset = ((is_geography || geom_data->has_srid) ? OFFSET_WITH_SRID : OFFSET_WITHOUT_SRID) + NPOINTS_SIZE;  /* skip past WKB numpoints */

    /* WKB point entry: header(5) + XY(16) [+ Z(8)] [+ M(8)] */
    wkb_point_size = 5 + COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0) + (has_m ? COORD_SIZE : 0);

    /* Destination starts after SRID(4) + props(2) + npoints(4) */
    dst = result_data + HEADER_SIZE + NPOINTS_SIZE;

    /* ── Pass 1: Write all XY pairs ── */
    temp_src = src_offset;
    offset = 0;
    for (i = 0; i < npoints; i++)
    {
        /* Skip WKB point header (5 bytes: byte_order + type) */
        memcpy(dst + offset, geom_data->byte_data + temp_src + 5, COORD_SIZE * 2);
        offset += COORD_SIZE * 2;
        temp_src += wkb_point_size;
    }

    /* ── Pass 2: Write all Z values ── */
    if (has_z)
    {
        temp_src = src_offset;
        for (i = 0; i < npoints; i++)
        {
            double *z_coord = (double *)(geom_data->byte_data + temp_src + 5 + COORD_SIZE * 2);
            copy_coord_with_nan_check(dst + offset, z_coord);
            offset += COORD_SIZE;
            temp_src += wkb_point_size;
        }
    }

    /* ── Pass 3: Write all M values ── */
    if (has_m)
    {
        temp_src = src_offset;
        for (i = 0; i < npoints; i++)
        {
            uint32_t m_pos = 5 + COORD_SIZE * 2 + (has_z ? COORD_SIZE : 0);
            double *m_coord = (double *)(geom_data->byte_data + temp_src + m_pos);
            copy_coord_with_nan_check(dst + offset, m_coord);
            offset += COORD_SIZE;
            temp_src += wkb_point_size;
        }
    }

    /* ── Write CLR metadata (figures + shapes) ── */
    metadata_pos = dst + offset;
    write_multipoint_clr_metadata(metadata_pos, npoints);

    return result;
}
/* Step 4: Construct final T-SQL binary representation */
static bytea* 
construct_result_bytea(GeoDataInfo *geom_data, bool is_geography) 
{
    uint32_t total_size;
    uint32_t metadata_size;
    bytea *result;
    uint8 *result_data;
    bool needs_npoints;

    /* Calculate total size needed for result bytea */
    total_size = SRID_SIZE + GEOM_TYPE_SIZE + geom_data->coord_size;

    /* 
     * Calculate CLR metadata size (figures + shapes).
     * Returns 0 for points and 2-point linestrings.
     */
    metadata_size = geom_data->is_empty ? 0 : calculate_clr_metadata_size(geom_data, is_geography);

    /* 
     * Add npoints field for complex geometries:
     *   - LineString with >2 points
     *   - Polygon (always has npoints field)
     *   - MultiPoint (always has npoints field)
     */
    needs_npoints = 
    (geom_data->postgis_geom_type == LINE_TYPE && geom_data->npoints > 2) ||
    ((geom_data->postgis_geom_type == POLYGON_TYPE || geom_data->postgis_geom_type == MULTIPOINT_TYPE) && !geom_data->is_empty);

    if (needs_npoints)
    {
    total_size += NPOINTS_SIZE;
    }

    /* Add CLR metadata */
    total_size += metadata_size;

    /* Allocate and initialize result bytea */
    result = (bytea *) palloc0(VARHDRSZ + total_size);
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
            case MULTIPOINT_TYPE:
                memcpy(result_data + HEADER_SIZE, &geom_data->npoints, NPOINTS_SIZE);
                return handle_multipoint_type_data(geom_data, result_data, result, is_geography);
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
        empty_geom = palloc0(VARHDRSZ + EMPTY_Binary_SIZE);
        SET_VARSIZE(empty_geom, VARHDRSZ + EMPTY_Binary_SIZE);
        
        /* Create appropriate WKB based on geometry type */
        if (strcmp(geom_type, "ST_Point" ) == 0) 
        {
            /* Copy empty point WKB pattern */
            memcpy(VARDATA(empty_geom), EMPTY_POINT_Bytes, EMPTY_Binary_SIZE);
        }
        else if (strcmp(geom_type, "ST_LineString" ) == 0) 
        {
            /* Copy empty linestring WKB pattern */
            memcpy(VARDATA(empty_geom), EMPTY_LINE_Bytes, EMPTY_Binary_SIZE);
        }
        else if (strcmp(geom_type, "ST_Polygon" ) == 0) 
        {
            /* Copy empty linestring WKB pattern */
            memcpy(VARDATA(empty_geom), EMPTY_POLYGON_Bytes, EMPTY_Binary_SIZE);
        }
         else if (strcmp(geom_type, "ST_MultiPoint") == 0)
        {
            memcpy(VARDATA(empty_geom), EMPTY_MULTIPOINT_Bytes, EMPTY_Binary_SIZE);
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


/* One-time session-level PostGIS function pointer resolution. */
static inline void
load_spatial_fns_once(void)
{
    if (likely(spatial_fns_loaded))
        return;
    load_functions();
    spatial_fns_loaded = true;
}

static inline int32_t
get_srid_from_header(const GSERIALIZED *g)
{

    int32_t srid = ((int32_t) g->srid[0] << 16)
                 | ((int32_t) g->srid[1] << 8)
                 |  (int32_t) g->srid[2];

    return (srid == 0) ? SRID_UNKNOWN_VAL : srid;
}

/*
 * Get GSERIALIZED header pointer with minimal I/O.
 * For inline data: direct pointer cast.
 * For external/compressed: fetch only first 8 bytes via SLICE.
 */
static inline GSERIALIZED *
get_geometry_header(Datum datum)
{
    if (VARATT_IS_EXTENDED(datum))
        return (GSERIALIZED *) PG_DETOAST_DATUM_SLICE(datum, 0, GSERIALIZED_HDR_SIZE);
    else
        return (GSERIALIZED *) DatumGetPointer(datum);
}

/*
 * Check if two geometry/geography arguments have matching SRIDs.
 * Uses header-only access — does NOT detoast the full geometry.
 */
static inline bool
check_srids_match(FunctionCallInfo fcinfo)
{
    GSERIALIZED *h1 = get_geometry_header(PG_GETARG_DATUM(0));
    GSERIALIZED *h2 = get_geometry_header(PG_GETARG_DATUM(1));
    return (get_srid_from_header(h1) == get_srid_from_header(h2));
}

/* BBox-disjoint short-circuit: returns true if cached bboxes don't overlap. */

static inline bool
header_has_bbox(const GSERIALIZED *g)
{
    return (g->gflags & G_FLAGS_BBOX_BIT) != 0;
}

/*
 * Fetch the cached 2D bbox from both operands. Returns false if either
 * lacks a cached bbox — caller must fall back to the full PostGIS path.
 */
static inline bool
fetch_bboxes(Datum a, Datum b, GBOX2D **out_a, GBOX2D **out_b)
{
    GSERIALIZED *ga, *gb;

    if (VARATT_IS_EXTENDED(a))
        ga = (GSERIALIZED *) PG_DETOAST_DATUM_SLICE(a, 0,
                                                    GSERIALIZED_HDR_SIZE + sizeof(GBOX2D));
    else
        ga = (GSERIALIZED *) DatumGetPointer(a);

    if (VARATT_IS_EXTENDED(b))
        gb = (GSERIALIZED *) PG_DETOAST_DATUM_SLICE(b, 0,
                                                    GSERIALIZED_HDR_SIZE + sizeof(GBOX2D));
    else
        gb = (GSERIALIZED *) DatumGetPointer(b);

    if (!header_has_bbox(ga) || !header_has_bbox(gb))
        return false;

    *out_a = (GBOX2D *) ga->data;
    *out_b = (GBOX2D *) gb->data;
    return true;
}

static inline bool
geom_bbox_disjoint(Datum a, Datum b)
{
    GBOX2D *ba, *bb;

    if (!fetch_bboxes(a, b, &ba, &bb))
        return false;

    /* classic AABB-disjoint test */
    return (ba->xmax < bb->xmin || bb->xmax < ba->xmin ||
            ba->ymax < bb->ymin || bb->ymax < ba->ymin);
}


/*
 * Geography variant: planar AABB test, but only when both bboxes are
 * canonical (xmin <= xmax, ymin <= ymax). Wrapped bboxes (antimeridian
 * or pole) fall back to PostGIS for correctness.
 */
static inline bool
geog_bbox_disjoint_safe(Datum a, Datum b)
{
    GBOX2D *ba, *bb;

    if (!fetch_bboxes(a, b, &ba, &bb))
        return false;

    /* Refuse to decide if either bbox is wrapped (non-canonical). */
    if (ba->xmin > ba->xmax || ba->ymin > ba->ymax ||
        bb->xmin > bb->xmax || bb->ymin > bb->ymax)
        return false;

    return (ba->xmax < bb->xmin || bb->xmax < ba->xmin ||
            ba->ymax < bb->ymin || bb->ymax < ba->ymin);
}

/*
 * Read the lwgeom type code from a GSERIALIZED without parsing the whole
 * geometry. Handles both v1 and v2 GSERIALIZED layouts.
 *
 *   v1: data[]  = [bbox?][type:uint32][...]
 *   v2: data[]  = [extended?][bbox?][type:uint32][...]
 *
 * The bbox length depends on dimensions and geodetic flag.
 */
static inline uint32_t
gserialized_typecode(Datum datum)
{
    GSERIALIZED *g;
    uint8_t      gflags;
    const uint8_t *p;
    uint32_t     type;

    if (VARATT_IS_EXTENDED(datum))
        g = (GSERIALIZED *) PG_DETOAST_DATUM_SLICE(datum, 0,
                                                   GSERIALIZED_TYPE_SLICE_SIZE);
    else
        g = (GSERIALIZED *) DatumGetPointer(datum);

    gflags = g->gflags;
    p      = g->data;

    /* v2 may carry an 8-byte "extended" block before the bbox */
    if ((gflags & G_FLAGS_VERSION_BIT) && (gflags & G_FLAGS_EXTENDED_BIT))
        p += 8;

    /* bbox, if present: geodetic = 6 floats = 24 bytes; cartesian = 2*ndims floats */
    if (gflags & G_FLAGS_BBOX_BIT)
    {
        if (gflags & G_FLAGS_GEODETIC_BIT)
        {
            p += 6 * sizeof(float);
        }
        else
        {
            int ndims = 2
                      + ((gflags & G_FLAGS_Z_BIT) ? 1 : 0)
                      + ((gflags & G_FLAGS_M_BIT) ? 1 : 0);
            p += 2 * ndims * sizeof(float);
        }
    }

    memcpy(&type, p, sizeof(uint32_t));
    return type;
}

/*
 * Trivially-valid shapes: a Point cannot be invalid by construction (a single
 * coord, no self-intersection possible). Saves an ST_IsValid (full GEOS
 * topology check) per row on point-on-polygon joins.
 *
 * NOTE: this preserves T-SQL semantics — STIsValid() on a POINT in SQL Server
 * always returns 1.
 */
static inline bool
is_trivially_valid(Datum geom)
{
    return gserialized_typecode(geom) == LWTYPE_POINT;
}

/*
 * Validate a single geometry/geography datum. Throws error if invalid.
 */
static inline void
check_validity_single(Datum geom, const char *type_name)
{
    LOCAL_FCINFO(fcinfo_valid, 1);

    if (is_trivially_valid(geom))
        return;

    InitFunctionCallInfoData(*fcinfo_valid, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_valid->args[0].value = geom;
    fcinfo_valid->args[0].isnull = false;
    if (!DatumGetBool(st_isvalid_p(fcinfo_valid)))
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("The %s instance is not valid", type_name)));
}

/*
 * Validate both arguments of a binary predicate.
 * SQL Server validates both operands — valid.STIntersects(invalid) also errors.
 */
static inline void
check_validity_both_geom(FunctionCallInfo fcinfo)
{
    check_validity_single(PG_GETARG_DATUM(0), "geometry");
    check_validity_single(PG_GETARG_DATUM(1), "geometry");
}

static inline void
check_validity_both_geog(FunctionCallInfo fcinfo)
{
    check_validity_single(PG_GETARG_DATUM(0), "geography");
    check_validity_single(PG_GETARG_DATUM(1), "geography");
}

/* --- Geometry wrappers --- */

Datum
bbf_st_intersects(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geom(fcinfo);
    if (geom_bbox_disjoint(PG_GETARG_DATUM(0), PG_GETARG_DATUM(1)))
        PG_RETURN_BOOL(false);
    return st_intersects_op_p(fcinfo);
}

Datum
bbf_st_contains(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geom(fcinfo);
    return st_contains_op_p(fcinfo);
}

Datum
bbf_st_equals(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geom(fcinfo);
    return st_equals_op_p(fcinfo);
}

Datum
bbf_st_distance(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_check, 1);

    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();

    /* T-SQL: distance on an empty operand returns NULL. */
    InitFunctionCallInfoData(*fcinfo_check, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_check->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_check->args[0].isnull = false;
    if (DatumGetBool(st_isempty_p(fcinfo_check)))
        PG_RETURN_NULL();
    fcinfo_check->args[0].value = PG_GETARG_DATUM(1);
    fcinfo_check->args[0].isnull = false;
    if (DatumGetBool(st_isempty_p(fcinfo_check)))
        PG_RETURN_NULL();

    check_validity_both_geom(fcinfo);
    return st_distance_op_p(fcinfo);
}

Datum
bbf_st_disjoint(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geom(fcinfo);
    if (geom_bbox_disjoint(PG_GETARG_DATUM(0), PG_GETARG_DATUM(1)))
        PG_RETURN_BOOL(true);
    return st_disjoint_op_p(fcinfo);
}

/* --- Geography wrappers --- */

Datum
bbf_geog_intersects(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geog(fcinfo);
    if (geog_bbox_disjoint_safe(PG_GETARG_DATUM(0), PG_GETARG_DATUM(1)))
        PG_RETURN_BOOL(false);
    return st_intersects_op_p(fcinfo);
}

Datum
bbf_geog_equals(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geog(fcinfo);
    return st_equals_op_p(fcinfo);
}

Datum
bbf_geog_contains(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geog(fcinfo);
    if (geog_bbox_disjoint_safe(PG_GETARG_DATUM(0), PG_GETARG_DATUM(1)))
        PG_RETURN_BOOL(false);
    return st_contains_op_p(fcinfo);
}

Datum
bbf_geog_disjoint(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();
    check_validity_both_geog(fcinfo);
    if (geog_bbox_disjoint_safe(PG_GETARG_DATUM(0), PG_GETARG_DATUM(1)))
        PG_RETURN_BOOL(true);
    return st_disjoint_op_p(fcinfo);
}

/* --- Unary wrappers (GEOMETRY + GEOGRAPHY) --- */

Datum
bbf_st_area(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* Point fast path: area is always 0 and a Point is always valid → skip GEOS. */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) == LWTYPE_POINT)
        PG_RETURN_FLOAT8(0.0);

    check_validity_single(PG_GETARG_DATUM(0), "geometry");
    return st_area_p(fcinfo);
}

Datum
bbf_geog_area(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* Same point fast-path as bbf_st_area. */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) == LWTYPE_POINT)
        PG_RETURN_FLOAT8(0.0);

    check_validity_single(PG_GETARG_DATUM(0), "geography");
    return st_area_p(fcinfo);
}

Datum
bbf_st_numpoints(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* Point fast path: 0 if empty, else 1. Skips full deserialization. */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) == LWTYPE_POINT)
    {
        if (DatumGetBool(st_isempty_p(fcinfo)))
            PG_RETURN_INT32(0);
        PG_RETURN_INT32(1);
    }

    check_validity_single(PG_GETARG_DATUM(0), "geometry");
    return lwgeom_npoints_p(fcinfo);
}

Datum
bbf_geog_numpoints(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* Same Point fast-path as bbf_st_numpoints. */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) == LWTYPE_POINT)
    {
        if (DatumGetBool(st_isempty_p(fcinfo)))
            PG_RETURN_INT32(0);
        PG_RETURN_INT32(1);
    }

    check_validity_single(PG_GETARG_DATUM(0), "geography");
    return lwgeom_npoints_p(fcinfo);
}

   /*
   * Dimension from typecode (no deserialization).
   * Returns 0/1/2 for known types; -2 means caller falls back to PostGIS.
   */
static inline int32_t
dimension_from_typecode(uint32_t tc)
{
    switch (tc)
    {
        case LWTYPE_POINT:
        case LWTYPE_MULTIPOINT:
            return 0;
        case LWTYPE_LINESTRING:
        case LWTYPE_MULTILINESTRING:
        case LWTYPE_CIRCSTRING:
        case LWTYPE_COMPOUNDCURVE:
        case LWTYPE_MULTICURVE:
            return 1;
        case LWTYPE_POLYGON:
        case LWTYPE_MULTIPOLYGON:
        case LWTYPE_CURVEPOLYGON:
        case LWTYPE_MULTISURFACE:
            return 2;
        default:
            return -2;
    }
}

Datum
bbf_st_dimension(PG_FUNCTION_ARGS)
{
    int32_t dim;
    uint32_t tc;

    load_spatial_fns_once();

    /* T-SQL returns -1 for empty geometries — must check first. */
    if (DatumGetBool(st_isempty_p(fcinfo)))
        PG_RETURN_INT32(-1);

    tc = gserialized_typecode(PG_GETARG_DATUM(0));
    dim = dimension_from_typecode(tc);

    /* Point fast path: always valid, skip GEOS check. */
    if (tc == LWTYPE_POINT)
        PG_RETURN_INT32(0);

    check_validity_single(PG_GETARG_DATUM(0), "geometry");

    if (dim >= 0)
        PG_RETURN_INT32(dim);

    /* Collection / polyhedral / unknown: fall back to PostGIS for correctness. */
    return lwgeom_dim_p(fcinfo);
}

Datum
bbf_geog_dimension(PG_FUNCTION_ARGS)
{
    int32_t dim;
    uint32_t tc;

    load_spatial_fns_once();

    /* T-SQL returns -1 for empty geographies — must check first. */
    if (DatumGetBool(st_isempty_p(fcinfo)))
        PG_RETURN_INT32(-1);

    tc = gserialized_typecode(PG_GETARG_DATUM(0));
    dim = dimension_from_typecode(tc);

    /* Point fast-path: skip GEOS validity (Point is always valid). */
    if (tc == LWTYPE_POINT)
        PG_RETURN_INT32(0);

    check_validity_single(PG_GETARG_DATUM(0), "geography");

    if (dim >= 0)
        PG_RETURN_INT32(dim);

    /* Collection / polyhedral / unknown: fall back to PostGIS. */
    return lwgeom_dim_p(fcinfo);
}

Datum
bbf_st_isclosed(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* T-SQL: STIsClosed returns 0 for Point geometries */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) == LWTYPE_POINT)
        PG_RETURN_BOOL(false);

    check_validity_single(PG_GETARG_DATUM(0), "geometry");
    return lwgeom_isclosed_p(fcinfo);
}

Datum
bbf_geog_isclosed(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* T-SQL: STIsClosed returns 0 for Point geographies */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) == LWTYPE_POINT)
        PG_RETURN_BOOL(false);

    check_validity_single(PG_GETARG_DATUM(0), "geography");
    return lwgeom_isclosed_p(fcinfo);
}

Datum
bbf_st_makevalid(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    if (DatumGetBool(st_isempty_p(fcinfo)))
        PG_RETURN_DATUM(PG_GETARG_DATUM(0));

    /* Skip ST_MakeValid for already-valid input — measurable win on all-valid data. */
    if (DatumGetBool(st_isvalid_p(fcinfo)))
        PG_RETURN_DATUM(PG_GETARG_DATUM(0));

    return st_makevalid_p(fcinfo);
}

Datum
bbf_geog_makevalid(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    if (DatumGetBool(st_isempty_p(fcinfo)))
        PG_RETURN_DATUM(PG_GETARG_DATUM(0));

    /* Skip ST_MakeValid for already-valid input — measurable win on all-valid data. */
    if (DatumGetBool(st_isvalid_p(fcinfo)))
        PG_RETURN_DATUM(PG_GETARG_DATUM(0));

    return st_makevalid_p(fcinfo);
}

/* Geography STDistance: flips lat/lon to lon/lat before calling PostGIS. */
Datum
bbf_geog_distance(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_flip1, 1);
    LOCAL_FCINFO(fcinfo_flip2, 1);
    LOCAL_FCINFO(fcinfo_dist,  2);
    LOCAL_FCINFO(fcinfo_empty, 1);
    Datum flipped_a, flipped_b;

    load_spatial_fns_once();

    if (!check_srids_match(fcinfo))
        PG_RETURN_NULL();

    /* T-SQL: distance on an empty operand returns NULL. */
    InitFunctionCallInfoData(*fcinfo_empty, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_empty->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_empty->args[0].isnull = false;
    if (DatumGetBool(st_isempty_p(fcinfo_empty)))
        PG_RETURN_NULL();
    fcinfo_empty->args[0].value = PG_GETARG_DATUM(1);
    fcinfo_empty->args[0].isnull = false;
    if (DatumGetBool(st_isempty_p(fcinfo_empty)))
        PG_RETURN_NULL();

    check_validity_both_geog(fcinfo);

    /* flip operand 0 */
    InitFunctionCallInfoData(*fcinfo_flip1, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_flip1->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_flip1->args[0].isnull = false;
    flipped_a = st_flipcoordinates_p(fcinfo_flip1);

    /* flip operand 1 */
    InitFunctionCallInfoData(*fcinfo_flip2, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_flip2->args[0].value = PG_GETARG_DATUM(1);
    fcinfo_flip2->args[0].isnull = false;
    flipped_b = st_flipcoordinates_p(fcinfo_flip2);

    /* call LWGEOM_distance_ellipsoid on flipped operands */
    InitFunctionCallInfoData(*fcinfo_dist, NULL, 2, InvalidOid, NULL, NULL);
    fcinfo_dist->args[0].value = flipped_a;
    fcinfo_dist->args[0].isnull = false;
    fcinfo_dist->args[1].value = flipped_b;
    fcinfo_dist->args[1].isnull = false;
    return geog_distance_ellipsoid_p(fcinfo_dist);
}

/* --- Parse wrappers --- */

Datum
bbf_geometry_parse(PG_FUNCTION_ARGS)
{
    text *input_text = PG_GETARG_TEXT_PP(0);
    char *input_str;
    bool  is_null_literal;
    LOCAL_FCINFO(fcinfo_local, 2);

    load_spatial_fns_once();

    /* Check for 'NULL' string (case-insensitive) */
    input_str = text_to_cstring(input_text);
    is_null_literal = (pg_strcasecmp(input_str, "NULL") == 0);
    pfree(input_str);                                         /* free before any path that can throw */
    if (is_null_literal)
        PG_RETURN_NULL();

    /* Delegate to get_geometry_from_text with SRID=0 */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = Int32GetDatum(0);
    fcinfo_local->args[1].isnull = false;
    return get_geometry_from_text(fcinfo_local);
}

Datum
bbf_geography_parse(PG_FUNCTION_ARGS)
{
    text *input_text = PG_GETARG_TEXT_PP(0);
    char *input_str;
    bool  is_null_literal;
    LOCAL_FCINFO(fcinfo_local, 2);

    load_spatial_fns_once();

    /* Check for 'NULL' string (case-insensitive) */
    input_str = text_to_cstring(input_text);
    is_null_literal = (pg_strcasecmp(input_str, "NULL") == 0);
    pfree(input_str);                                         /* free before any path that can throw */
    if (is_null_literal)
        PG_RETURN_NULL();

    /* Delegate to get_geography_from_text with SRID=4326 */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = Int32GetDatum(DEFAULT_GEOGRAPHY_SRID);
    fcinfo_local->args[1].isnull = false;
    return get_geography_from_text(fcinfo_local);
}

/* --- HasZ / HasM wrappers --- */

Datum
bbf_hasz(PG_FUNCTION_ARGS)
{
    int16 zmflag;

    load_spatial_fns_once();
    zmflag = DatumGetInt16(lwgeom_zmflag_p(fcinfo));

    /* zmflag: 1=M, 2=Z, 3=ZM */
    PG_RETURN_BOOL(zmflag == 2 || zmflag == 3);
}

Datum
bbf_hasm(PG_FUNCTION_ARGS)
{
    int16 zmflag;

    load_spatial_fns_once();
    zmflag = DatumGetInt16(lwgeom_zmflag_p(fcinfo));

    /* zmflag: 1=M, 2=Z, 3=ZM */
    PG_RETURN_BOOL(zmflag == 1 || zmflag == 3);
}

/* --- Z / M coordinate accessors --- */

Datum
bbf_z(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* Only return Z for Point types */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) != LWTYPE_POINT)
        PG_RETURN_NULL();

    return lwgeom_z_point_p(fcinfo);
}

Datum
bbf_m(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();

    /* Only return M for Point types */
    if (gserialized_typecode(PG_GETARG_DATUM(0)) != LWTYPE_POINT)
        PG_RETURN_NULL();

    return lwgeom_m_point_p(fcinfo);
}

/* --- STGeometryType wrapper --- */

Datum
bbf_st_geometrytype(PG_FUNCTION_ARGS)
{
    /* T-SQL name (ST_ prefix stripped); mapped from header type code. */
    static const char *const tsql_type_names[LWTYPE_NUMTYPES] = {
        [LWTYPE_POINT]           = "Point",
        [LWTYPE_LINESTRING]      = "LineString",
        [LWTYPE_POLYGON]         = "Polygon",
        [LWTYPE_MULTIPOINT]      = "MultiPoint",
        [LWTYPE_MULTILINESTRING] = "MultiLineString",
        [LWTYPE_MULTIPOLYGON]    = "MultiPolygon",
        [LWTYPE_COLLECTION]      = "GeometryCollection",
        [LWTYPE_CIRCSTRING]      = "CircularString",
        [LWTYPE_COMPOUNDCURVE]   = "CompoundCurve",
        [LWTYPE_CURVEPOLYGON]    = "CurvePolygon",
        [LWTYPE_MULTICURVE]      = "MultiCurve",
        [LWTYPE_MULTISURFACE]    = "MultiSurface",
    };
    uint32_t type_code;
    const char *name;

    load_spatial_fns_once();

    /* Resolve type code; skip GEOS validity for Point (always valid). */
    type_code = gserialized_typecode(PG_GETARG_DATUM(0));

     /* Skip GEOS validity for Point (always valid); all other types go through st_isvalid. */
    if (type_code != LWTYPE_POINT && !DatumGetBool(st_isvalid_p(fcinfo)))
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("This operation cannot be completed because the instance is not valid")));

    if (type_code < LWTYPE_NUMTYPES && (name = tsql_type_names[type_code]) != NULL)
        PG_RETURN_TEXT_P(cstring_to_text(name));

    /*
     * Fall back to PostGIS for any future/unknown type code so we keep
     * working if PostGIS adds a type we don't know about yet.
     */
    {
        char *geom_type = text_to_cstring(DatumGetTextP(geometry_type_p(fcinfo)));

        if (strncmp(geom_type, "ST_", 3) == 0)
        {
            text *result = cstring_to_text(geom_type + 3);
            pfree(geom_type);
            PG_RETURN_TEXT_P(result);
        }

        ereport(ERROR,
                (errcode(ERRCODE_INTERNAL_ERROR),
                 errmsg("Unexpected geometry type format: %s. Expected ST_* prefix.", geom_type)));
        PG_RETURN_NULL(); /* unreachable */
    }
}

/* --- Operator wrappers (= and <>) for geometry/geography --- */

   /*
   * Delegate to bbf_st_equals / bbf_geog_equals.
   *  =  : propagate NULL (T-SQL parity)
   *  <> : map NULL -> TRUE
   */

Datum
bbf_geom_op_equals(PG_FUNCTION_ARGS)
{
    Datum result = bbf_st_equals(fcinfo);


    return result;
}

Datum
bbf_geom_op_not_equals(PG_FUNCTION_ARGS)
{
    Datum result = bbf_st_equals(fcinfo);

    if (fcinfo->isnull)
    {
        fcinfo->isnull = false;
        PG_RETURN_BOOL(true);
    }
    PG_RETURN_BOOL(!DatumGetBool(result));
}

Datum
bbf_geog_op_equals(PG_FUNCTION_ARGS)
{
    Datum result = bbf_geog_equals(fcinfo);

    /* STRICT semantics: preserve NULL from the underlying STEquals. */
    return result;
}

Datum
bbf_geog_op_not_equals(PG_FUNCTION_ARGS)
{
    Datum result = bbf_geog_equals(fcinfo);

    if (fcinfo->isnull)
    {
        fcinfo->isnull = false;
        PG_RETURN_BOOL(true);
    }
    PG_RETURN_BOOL(!DatumGetBool(result));
}

Datum
bbf_geog_astext(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_flip, 1);
    LOCAL_FCINFO(fcinfo_text, 1);
    Datum flipped;

    load_spatial_fns_once();

    /* Flip coordinates (geography stores lat,lon; WKT needs lon,lat) */
    InitFunctionCallInfoData(*fcinfo_flip, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_flip->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_flip->args[0].isnull = false;
    flipped = st_flipcoordinates_p(fcinfo_flip);

    /* Call the existing st_as_text C function */
    InitFunctionCallInfoData(*fcinfo_text, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_text->args[0].value = flipped;
    fcinfo_text->args[0].isnull = false;
    return st_as_text(fcinfo_text);
}

/* Geography → bpchar cast: flip coordinates then format as text. */
Datum
bbf_geog_asbpchar(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_flip, 1);
    LOCAL_FCINFO(fcinfo_bp, 3);
    Datum flipped;

    load_spatial_fns_once();

    /* Flip coordinates: geography (lat,lon) → (lon,lat) for display */
    InitFunctionCallInfoData(*fcinfo_flip, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_flip->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_flip->args[0].isnull = false;
    flipped = st_flipcoordinates_p(fcinfo_flip);

    /* Delegate to geometry_asbpchar(flipped, maxlen, explicit) */
    InitFunctionCallInfoData(*fcinfo_bp, NULL, 3, InvalidOid, NULL, NULL);
    fcinfo_bp->args[0].value = flipped;
    fcinfo_bp->args[0].isnull = false;
    fcinfo_bp->args[1].value = PG_GETARG_DATUM(1);
    fcinfo_bp->args[1].isnull = false;
    fcinfo_bp->args[2].value = PG_GETARG_DATUM(2);
    fcinfo_bp->args[2].isnull = false;
    return geometry_asbpchar(fcinfo_bp);
}

/*
 * Geography → varchar cast.
 * Flips coordinates then gets text representation, with length validation.
 */
Datum
bbf_geog_asvarchar(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_flip, 1);
    LOCAL_FCINFO(fcinfo_text, 1);
    Datum flipped;
    text *str_notation;
    int32 maxlen = PG_GETARG_INT32(1);
    int32 len;

    load_spatial_fns_once();

    /* Flip coordinates: geography (lat,lon) → (lon,lat) for display */
    InitFunctionCallInfoData(*fcinfo_flip, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_flip->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_flip->args[0].isnull = false;
    flipped = st_flipcoordinates_p(fcinfo_flip);

    /* Get text representation via geometry_astext (same as GeographyAsTextvar_helper) */
    InitFunctionCallInfoData(*fcinfo_text, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_text->args[0].value = flipped;
    fcinfo_text->args[0].isnull = false;
    str_notation = DatumGetTextP(geometry_astext(fcinfo_text));

    /* Length check: pg_catalog.length(str) + 4 > maxlen */
    len = VARSIZE_ANY_EXHDR(str_notation) + 4;
    if (len > maxlen && maxlen != -1)
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("There is insufficient result space to convert a geography value to varchar/nvarchar.")));

    PG_RETURN_TEXT_P(str_notation);
}

/*
 * Geometry::STGeomFromText(nvarchar, srid)
 * - param 2 NULL → error
 * - param 1 NULL → return NULL
 * - otherwise delegate to get_geometry_from_text
 */

Datum
bbf_geometry_stgeomfromtext(PG_FUNCTION_ARGS)
{
    /* $2 (SRID) must not be NULL */
    if (PG_ARGISNULL(1))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'geometry::STGeomFromText' failed because parameter 2 is not allowed to be null.")));

    /* $1 (WKT text) NULL → return NULL */
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    /* Delegate to get_geometry_from_text($1::text, $2) */
    return get_geometry_from_text(fcinfo);
}


Datum
bbf_geography_stgeomfromtext(PG_FUNCTION_ARGS)
{
    /* $2 (SRID) must not be NULL */
    if (PG_ARGISNULL(1))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'geography::STGeomFromText' failed because parameter 2 is not allowed to be null.")));

    /* $1 (WKT text) NULL → return NULL */
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    /* Delegate to get_geography_from_text($1::text, $2) */
    return get_geography_from_text(fcinfo);
}


Datum
bbf_geom_asvarchar(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_text, 1);
    Datum geom = PG_GETARG_DATUM(0);
    int32 maxlen = PG_GETARG_INT32(1);
    text *str_notation;
    int32 len;

    load_spatial_fns_once();

    /* Get varchar representation via geometry_astext */
    InitFunctionCallInfoData(*fcinfo_text, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_text->args[0].value = geom;
    fcinfo_text->args[0].isnull = false;
    str_notation = DatumGetTextP(geometry_astext(fcinfo_text));

    /* Length check: pg_catalog.length(str) + 4 > maxlen */
    len = VARSIZE_ANY_EXHDR(str_notation) + 4;
    if (len > maxlen && maxlen != -1)
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("There is insufficient result space to convert a geometry value to varchar/nvarchar.")));

    PG_RETURN_TEXT_P(str_notation);
}


Datum
bbf_geog_from_bpchar(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_parse, 1);
    LOCAL_FCINFO(fcinfo_flip, 1);
    Datum geog;

    load_spatial_fns_once();

    /* Parse bpchar to geography via charTogeog */
    InitFunctionCallInfoData(*fcinfo_parse, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_parse->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_parse->args[0].isnull = false;
    geog = charTogeog(fcinfo_parse);

    /* Flip coordinates (geography stores lat,lon) */
    InitFunctionCallInfoData(*fcinfo_flip, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_flip->args[0].value = geog;
    fcinfo_flip->args[0].isnull = false;
    return st_flipcoordinates_p(fcinfo_flip);
}


/* varchar uses the same wire format as bpchar */
Datum
bbf_geog_from_varchar(PG_FUNCTION_ARGS)
{
    return bbf_geog_from_bpchar(fcinfo);
}

Datum
bbf_geometry_point(PG_FUNCTION_ARGS)
{
    int32 srid;

    load_spatial_fns_once();

    if (PG_ARGISNULL(0))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'geometry::Point' failed because parameter 1 is not allowed to be null.")));
    if (PG_ARGISNULL(1))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'geometry::Point' failed because parameter 2 is not allowed to be null.")));
    if (PG_ARGISNULL(2))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'geometry::Point' failed because parameter 3 is not allowed to be null.")));

    srid = PG_GETARG_INT32(2);
    if (srid < 0 || srid > 999999)
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("SRID value should be between 0 and 999999")));

    /* Delegate to ST_Point(x, y, srid) — GeomPoint_helper */
    return st_point_p(fcinfo);
}

Datum
bbf_geog_to_text_error(PG_FUNCTION_ARGS)
{
    ereport(ERROR,
            (errcode(ERRCODE_CANNOT_COERCE),
             errmsg("Explicit Conversion from data type sys.Geography to Text is not allowed.")));
    PG_RETURN_NULL(); /* unreachable */
}

Datum
bbf_text_to_geom_error(PG_FUNCTION_ARGS)
{
    bool is_explicit = PG_GETARG_BOOL(2);

    if (is_explicit)
        ereport(ERROR,
                (errcode(ERRCODE_CANNOT_COERCE),
                 errmsg("Explicit Conversion from data type Text to sys.Geometry is not allowed.")));
    else
        ereport(ERROR,
                (errcode(ERRCODE_CANNOT_COERCE),
                 errmsg("Implicit Conversion from data type Text to sys.Geometry is not allowed.")));
    PG_RETURN_NULL(); /* unreachable */
}


Datum
bbf_text_to_geog_error(PG_FUNCTION_ARGS)
{
    bool is_explicit = PG_GETARG_BOOL(2);

    if (is_explicit)
        ereport(ERROR,
                (errcode(ERRCODE_CANNOT_COERCE),
                 errmsg("Explicit Conversion from data type Text to sys.Geography is not allowed.")));
    else
        ereport(ERROR,
                (errcode(ERRCODE_CANNOT_COERCE),
                 errmsg("Implicit Conversion from data type Text to sys.Geography is not allowed.")));
    PG_RETURN_NULL(); /* unreachable */
}


/* --- Geometry typed constructors --- */


/*
 * Build the 2-arg fcinfo used by all typed constructors below and call the
 * underlying parser. Caller is responsible for the type-of-result check.
 */
static inline Datum
parse_typed_constructor(FunctionCallInfo fcinfo,
                        Datum (*parser)(FunctionCallInfo),
                        const char *fn_label)
{
    LOCAL_FCINFO(fcinfo_local, 2);

    if (PG_ARGISNULL(1))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'%s' failed because parameter 2 is not allowed to be null.",
                        fn_label)));
    if (PG_ARGISNULL(0))
        return (Datum) 0;   /* sentinel; caller checks PG_ARGISNULL(0) again */

    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = PG_GETARG_DATUM(1);
    fcinfo_local->args[1].isnull = false;
    return parser(fcinfo_local);
}

Datum
bbf_geometry_stpointfromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geometry_from_text,
                                   "geometry::STPointFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_POINT)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"POINT\" at Position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}


Datum
bbf_geometry_stlinefromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geometry_from_text,
                                   "geometry::STLineFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_LINESTRING)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"LINESTRING\" at Position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}


Datum
bbf_geometry_stpolyfromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geometry_from_text,
                                   "geometry::STPolyFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_POLYGON)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"POLYGON\" at Position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}

Datum
bbf_geometry_stmpointfromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geometry_from_text,
                                   "geometry::STMPointFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_MULTIPOINT)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"MULTIPOINT\" at position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}

/* --- Geography typed constructors --- */


Datum
bbf_geography_stpointfromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geography_from_text,
                                   "geography::STPointFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_POINT)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"POINT\" at Position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}

Datum
bbf_geography_stlinefromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geography_from_text,
                                   "geography::STLineFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_LINESTRING)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"LINESTRING\" at Position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}

Datum
bbf_geography_stpolyfromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geography_from_text,
                                   "geography::STPolyFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_POLYGON)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"POLYGON\" at Position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}

Datum
bbf_geography_stmpointfromtext(PG_FUNCTION_ARGS)
{
    Datum geom;

    load_spatial_fns_once();

    geom = parse_typed_constructor(fcinfo, get_geography_from_text,
                                   "geography::STMPointFromText");
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    if (gserialized_typecode(geom) == LWTYPE_MULTIPOINT)
        PG_RETURN_DATUM(geom);

    ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("Expected \"MULTIPOINT\" at position 1. The input has %s",
                    text_to_cstring(PG_GETARG_TEXT_PP(0)))));
    PG_RETURN_NULL();
}

/* --- Cast wrappers: remaining PL/pgSQL → C conversions --- */

/* GEOMETRY(bpchar) — bpchar to geometry cast */
Datum
bbf_geom_from_bpchar(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    return charTogeom(fcinfo);
}

/* GEOMETRY(varchar) — varchar uses the same wire format as bpchar */
Datum
bbf_geom_from_varchar(PG_FUNCTION_ARGS)
{
    return bbf_geom_from_bpchar(fcinfo);
}

/* text(GEOMETRY) — error: explicit conversion not allowed */
Datum
bbf_geom_to_text_error(PG_FUNCTION_ARGS)
{
    ereport(ERROR,
            (errcode(ERRCODE_CANNOT_COERCE),
             errmsg("Explicit Conversion from data type sys.Geometry to Text is not allowed.")));
    PG_RETURN_NULL();
}

/* GEOMETRY(bbf_varbinary) — varbinary has same internal format as bytea */
Datum
bbf_geom_from_varbinary(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    return geometry_from_bytea(fcinfo);
}

/* bbf_varbinary(GEOMETRY, int, bool) — geometry to varbinary with length check */
Datum
bbf_geom_to_varbinary(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_local, 1);
    bytea *byte_result;
    int32 byte_len;
    int32 maxlen = PG_GETARG_INT32(1);

    load_spatial_fns_once();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    byte_result = DatumGetByteaP(bytea_from_geometry(fcinfo_local));

    byte_len = VARSIZE_ANY_EXHDR(byte_result) + 4;
    if (byte_len > maxlen && maxlen != -1)
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("Error converting sys.geometry to binary. The result would be truncated.")));

    PG_RETURN_BYTEA_P(byte_result);
}

/* GEOMETRY(bbf_binary) — binary has same internal format as bytea */
Datum
bbf_geom_from_binary(PG_FUNCTION_ARGS)
{
    return bbf_geom_from_varbinary(fcinfo);
}

/* bbf_binary(GEOMETRY, int, bool) — geometry to fixed-length binary */
Datum
bbf_geom_to_binary(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_local, 1);
    bytea *byte_result;
    int32 byte_len;
    int32 target_len = PG_GETARG_INT32(1);

    load_spatial_fns_once();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    byte_result = DatumGetByteaP(bytea_from_geometry(fcinfo_local));

    byte_len = VARSIZE_ANY_EXHDR(byte_result) + 4;
    if (byte_len == target_len)
        PG_RETURN_BYTEA_P(byte_result);
    else if (byte_len > target_len)
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("Error converting sys.geometry to binary. The result would be truncated.")));
    else
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("Error converting sys.geometry to fixed length binary type. The result would be padded and cannot be converted back.")));
    PG_RETURN_NULL();
}

/* Geometry__STMPointFromWKB — WKB to geometry with MultiPoint type validation */
Datum
bbf_geometry_stmpointfromwkb(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_local, 2);
    Datum geom;

    load_spatial_fns_once();

    if (PG_ARGISNULL(1))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'geometry::STMPointFromWKB' failed because parameter 2 is not allowed to be null.")));
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = PG_GETARG_DATUM(1);
    fcinfo_local->args[1].isnull = false;
    geom = get_geometry_from_wkb(fcinfo_local);

    if (gserialized_typecode(geom) == LWTYPE_MULTIPOINT)
        PG_RETURN_DATUM(geom);

    /* Type mismatch: format the same way the PL/pgSQL version did. */
    {
        LOCAL_FCINFO(fcinfo_name, 1);
        char *geom_type;

        InitFunctionCallInfoData(*fcinfo_name, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_name->args[0].value = geom;
        fcinfo_name->args[0].isnull = false;
        geom_type = text_to_cstring(DatumGetTextP(geometry_type_p(fcinfo_name)));
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Expected \"MULTIPOINT\" at position 1. The input has %s",
                        geom_type)));
        PG_RETURN_NULL();
    }
}

/* GEOGRAPHY(bbf_varbinary) — varbinary has same internal format as bytea */
Datum
bbf_geog_from_varbinary(PG_FUNCTION_ARGS)
{
    load_spatial_fns_once();
    return geography_from_bytea(fcinfo);
}

/* bbf_varbinary(GEOGRAPHY, int, bool) — geography to varbinary with length check */
Datum
bbf_geog_to_varbinary(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_local, 1);
    bytea *byte_result;
    int32 byte_len;
    int32 maxlen = PG_GETARG_INT32(1);

    load_spatial_fns_once();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    byte_result = DatumGetByteaP(bytea_from_geography(fcinfo_local));

    byte_len = VARSIZE_ANY_EXHDR(byte_result) + 4;
    if (byte_len > maxlen && maxlen != -1)
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("Error converting sys.geography to binary. The result would be truncated.")));

    PG_RETURN_BYTEA_P(byte_result);
}

/* GEOGRAPHY(bbf_binary) — binary has same internal format as bytea */
Datum
bbf_geog_from_binary(PG_FUNCTION_ARGS)
{
    return bbf_geog_from_varbinary(fcinfo);
}

/* bbf_binary(GEOGRAPHY, int, bool) — geography to fixed-length binary */
Datum
bbf_geog_to_binary(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_local, 1);
    bytea *byte_result;
    int32 byte_len;
    int32 target_len = PG_GETARG_INT32(1);

    load_spatial_fns_once();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    byte_result = DatumGetByteaP(bytea_from_geography(fcinfo_local));

    byte_len = VARSIZE_ANY_EXHDR(byte_result) + 4;
    if (byte_len == target_len)
        PG_RETURN_BYTEA_P(byte_result);
    else if (byte_len > target_len)
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("Error converting sys.geography to binary. The result would be truncated.")));
    else
        ereport(ERROR,
                (errcode(ERRCODE_STRING_DATA_RIGHT_TRUNCATION),
                 errmsg("Error converting sys.geography to fixed length binary type. The result would be padded and cannot be converted back.")));
    PG_RETURN_NULL();
}

/* Geography__STMPointFromWKB — WKB to geography with MultiPoint type validation */
Datum
bbf_geography_stmpointfromwkb(PG_FUNCTION_ARGS)
{
    LOCAL_FCINFO(fcinfo_local, 2);
    Datum geog;

    load_spatial_fns_once();

    if (PG_ARGISNULL(1))
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("'geography::STMPointFromWKB' failed because parameter 2 is not allowed to be null.")));
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = PG_GETARG_DATUM(1);
    fcinfo_local->args[1].isnull = false;
    geog = get_geography_from_wkb(fcinfo_local);

    if (gserialized_typecode(geog) == LWTYPE_MULTIPOINT)
        PG_RETURN_DATUM(geog);

    /* Type mismatch: keep the same error format as the PL/pgSQL version. */
    {
        LOCAL_FCINFO(fcinfo_name, 1);
        char *geom_type;

        InitFunctionCallInfoData(*fcinfo_name, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_name->args[0].value = geog;
        fcinfo_name->args[0].isnull = false;
        geom_type = text_to_cstring(DatumGetTextP(geometry_type_p(fcinfo_name)));
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Expected \"MULTIPOINT\" at position 1. The input has %s",
                        geom_type)));
        PG_RETURN_NULL();
    }
}


#endif
