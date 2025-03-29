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

typedef Datum (*lwgeom_from_text_t)(PG_FUNCTION_ARGS);
static lwgeom_from_text_t lwgeom_from_text_p;

typedef Datum (*geo_wkt_rewrite_t)(PG_FUNCTION_ARGS);
static geo_wkt_rewrite_t geo_wkt_rewrite_p;

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
PG_FUNCTION_INFO_V1(geometry_rewrite);
PG_FUNCTION_INFO_V1(charTogeom);
PG_FUNCTION_INFO_V1(geometry_from_bytea);
PG_FUNCTION_INFO_V1(bytea_from_geometry);
PG_FUNCTION_INFO_V1(geography_from_bytea);
PG_FUNCTION_INFO_V1(bytea_from_geography);
PG_FUNCTION_INFO_V1(geography_rewrite);
PG_FUNCTION_INFO_V1(get_valid_srids);
PG_FUNCTION_INFO_V1(charTogeog);
PG_FUNCTION_INFO_V1(geography_point);
PG_FUNCTION_INFO_V1(st_as_binary_geometry);
PG_FUNCTION_INFO_V1(st_as_binary_geography);
PG_FUNCTION_INFO_V1(st_as_text);
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

    if (geo_wkt_rewrite_p == NULL)
        geo_wkt_rewrite_p = (geo_wkt_rewrite_t) load_external_function("babelfishpg_common", "geo_wkt_rewrite", true, NULL);

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

Datum
geometry_in(PG_FUNCTION_ARGS)
{
    Datum geom_datum;
    Datum geom_type;
    char *geometry_name;
    LOCAL_FCINFO(fcinfo_local, 1); /* Use local fcinfo so as to avoid overriding of original structure */

    load_functions();

    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    fcinfo_local->args[0].value = fcinfo->args[0].value;
    fcinfo_local->args[0].isnull = false;

    /* Call the LWGEOM_in function via the function pointer */
    geom_datum = lwgeom_in_p(fcinfo_local);

    fcinfo_local->args[0].value = geom_datum;
    geom_type = geometry_type_p(fcinfo_local);

    geometry_name = text_to_cstring(PG_DETOAST_DATUM(geom_type));
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
    Datum geom_datum;
    Datum geom_type;
    char *geometry_name;
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

    fcinfo_local->args[0].value = geom_datum;
    geom_type = geometry_type_p(fcinfo_local);
    /*
    * For binary string, such as '0101000000000000000000F03F000000000000004', predefined SRID is set by default
    * For character string, such as 'POINT(0 0)', set default SRID to be 4326 for geography datatype
    */
    if (!isBinary)
    {
        fcinfo_local->args[0].value = geom_datum;
        fcinfo_local->args[1].value = Int32GetDatum(4326);

        geom_datum = gserialized_set_srid_p(fcinfo_local);
    }
    geometry_name = text_to_cstring(PG_DETOAST_DATUM(geom_type));
    /* check if it is a 2-D point type */
    if (strcmp(geometry_name, "ST_Point") != 0)
        ereport(ERROR,
            (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
            errmsg("%s is not supported", geometry_name)));
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
    /* Return the created geometry */
    PG_RETURN_DATUM(geom_datum);
}

Datum
get_valid_srids(PG_FUNCTION_ARGS)
{
    Datum       *elements;
    int         num_srids,
                dims[1],
                lbs[1];
    ArrayType   *result;
    
    /* Array of valid Spatial Reference System Identifiers (SRIDs) */
    static const int32 valid_srids[] = {
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
    
    /* Ignore the input argument */
    (void) PG_GETARG_INT32(0);

    /* Calculate the number of SRIDs in the array */
    num_srids = sizeof(valid_srids) / sizeof(valid_srids[0]);

    /* Allocate memory for Datum array */
    elements = (Datum *) palloc(sizeof(Datum) * num_srids);

    /* Convert each SRID to a Datum */
    for (int i = 0; i < num_srids; i++) {
        elements[i] = Int32GetDatum(valid_srids[i]);
    }

    /* Set up array dimensions and lower bounds */
    dims[0] = num_srids;
    lbs[0] = 1;

    /* Construct the array */
    result = construct_md_array(elements, NULL, 1, dims, lbs,
                                INT4OID, sizeof(int32), true, 'i');

    /* Free the temporary Datum array */
    pfree(elements);

    /* Return the constructed array */
    PG_RETURN_ARRAYTYPE_P(result);
}

Datum
geometry_rewrite(PG_FUNCTION_ARGS)
{
    Datum   geom_datum,
            rewritten_wkt,
            geom_type_datum;
    int32   srid;
    char    *geom_type;
    LOCAL_FCINFO(fcinfo_local, 2);
    
    /* Load necessary functions */
    load_functions();

    /* Initialize function call info data */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);

    /* Set WKT text argument */
    fcinfo_local->args[0].value = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].isnull = false;

    /* Get and validate SRID argument */
    srid = PG_GETARG_INT32(1);

    if (srid < 0 || srid > 999999) {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("SRID value should be between 0 and 999999")));
    }

    fcinfo_local->args[1].value = Int32GetDatum(srid);
    fcinfo_local->args[1].isnull = false;

    /* Rewrite WKT */
    rewritten_wkt = geo_wkt_rewrite_p(fcinfo_local);

    /* Update first argument with rewritten WKT */
    fcinfo_local->args[0].value = rewritten_wkt;

    /* Convert WKT to geometry using lwgeom_from_text function */
    geom_datum = lwgeom_from_text_p(fcinfo_local);
    fcinfo_local->args[0].value = geom_datum;

    /* Get geometry type */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = geom_datum;
    fcinfo_local->args[0].isnull = false;
    geom_type_datum = geometry_type_p(fcinfo_local);
    geom_type = text_to_cstring(DatumGetTextP(geom_type_datum));

    /* Return the created geometry */
    if (strcmp(geom_type, "ST_Point") == 0)
        PG_RETURN_DATUM(geom_datum);

    /* This line should never be reached */
    PG_RETURN_NULL();  
}

Datum
geography_rewrite(PG_FUNCTION_ARGS)
{
    Datum       geom_datum,
                lat_datum,
                flipped_geom_datum,
                geom_type_datum,
                rewritten_wkt_datum;
    text        *wkt_text;
    char        *geom_type;
    float8      lat;
    bool        srid_valid;  
    int32       *valid_srids;
    int32       srid;
    int         num_valid_srids;
    ArrayType   *valid_srids_array;
    LOCAL_FCINFO(fcinfo_local, 2);

    /* Get input parameters */
    wkt_text = PG_GETARG_TEXT_PP(0);
    srid = PG_GETARG_INT32(1);
    srid_valid = false;

    /* Load necessary functions */
    load_functions();

    /* Get valid SRIDs using DirectFunctionCall1 */
    valid_srids_array = DatumGetArrayTypeP(DirectFunctionCall1(get_valid_srids, Int32GetDatum(4326)));
    valid_srids = (int32 *)ARR_DATA_PTR(valid_srids_array);
    num_valid_srids = ArrayGetNItems(ARR_NDIM(valid_srids_array), ARR_DIMS(valid_srids_array));

    /* Check if SRID is valid */
    for (int i = 0; i < num_valid_srids; i++)
    {    
        if (valid_srids[i] == srid)
        {
            srid_valid = true;
            break;
        }
    }

    /* If SRID is not valid, raise an error immediately */
    if (!srid_valid)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid SRID")));
    }

    /* Rewrite WKT */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = PointerGetDatum(wkt_text);
    fcinfo_local->args[0].isnull = false;
    rewritten_wkt_datum = geo_wkt_rewrite_p(fcinfo_local);

    /* Call stgeogfromtext_helper */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = rewritten_wkt_datum;
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = Int32GetDatum(srid);
    fcinfo_local->args[1].isnull = false;
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Get geometry type */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = geom_datum;
    fcinfo_local->args[0].isnull = false;
    geom_type_datum = geometry_type_p(fcinfo_local);
    geom_type = text_to_cstring(DatumGetTextP(geom_type_datum));

    if (strcmp(geom_type, "ST_Point") == 0)
    {
        /* Flip coordinates and get latitude */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = geom_datum;
        fcinfo_local->args[0].isnull = false;
        flipped_geom_datum = st_flipcoordinates_p(fcinfo_local);

        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = flipped_geom_datum;
        fcinfo_local->args[0].isnull = false;
        lat_datum = lwgeom_x_p(fcinfo_local);
        lat = DatumGetFloat8(lat_datum);

        /* Check if latitude is within valid range */
        if ((lat >= -90.0 && lat <= 90.0) || isnan(lat))
        {
            PG_RETURN_DATUM(flipped_geom_datum);
        }
        else
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Latitude values must be between -90 and 90 degrees")));
        }
    }
    /* This line should never be reached */
    PG_RETURN_NULL();  
}

Datum
geography_point(PG_FUNCTION_ARGS)
{
    Datum       result;
    float8      lat,
                lon;
    int32       srid;
    bool        srid_valid;
    int         i,
                num_valid_srids;
    int32       *valid_srids;
    ArrayType   *valid_srids_array;
    
    LOCAL_FCINFO(fcinfo_local, 3);

    /* Get input parameters */
   lat = PG_GETARG_FLOAT8(0);
   lon = PG_GETARG_FLOAT8(1);
   srid = PG_GETARG_INT32(2);
   srid_valid = false;

    /* Load functions */
    load_functions();

    /* Get valid SRIDs using DirectFunctionCall1 */
    valid_srids_array = DatumGetArrayTypeP(DirectFunctionCall1(get_valid_srids, Int32GetDatum(0)));
    valid_srids = (int32 *)ARR_DATA_PTR(valid_srids_array);
    num_valid_srids = ArrayGetNItems(ARR_NDIM(valid_srids_array), ARR_DIMS(valid_srids_array));

    /* Check if SRID is valid */
    for (i = 0; i < num_valid_srids; i++)
    {
        if (valid_srids[i] == srid)
        {
            srid_valid = true;
            break;
        }
    }

    /* Check latitude range and SRID validity */
    if (srid_valid && lat >= -90.0 && lat <= 90.0)
    {
        /* Call the underlying helper function */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 3, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = Float8GetDatum(lat);
        fcinfo_local->args[0].isnull = false;
        fcinfo_local->args[1].value = Float8GetDatum(lon);
        fcinfo_local->args[1].isnull = false;
        fcinfo_local->args[2].value = Int32GetDatum(srid);
        fcinfo_local->args[2].isnull = false;

        result = st_point_p(fcinfo_local);

        PG_RETURN_DATUM(result);
    }
    else if (lat < -90.0 || lat > 90.0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Latitude values must be between -90 and 90 degrees")));
    }
    else
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid SRID")));
    }
    /* This point should never be reached */
    PG_RETURN_NULL();
}

Datum
charTogeom(PG_FUNCTION_ARGS)
{
    Datum   input_text,
            rewritten_wkt,
            geom_datum,
            geom_type_datum;
    char    *geom_type;
    LOCAL_FCINFO(fcinfo_local, 2);
    
    /* Load necessary functions */
    load_functions();

    /* Initialize function call info data for one argument */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);

    /* Set input text argument */
    input_text = PG_GETARG_DATUM(0);
    fcinfo_local->args[0].value = input_text;
    fcinfo_local->args[0].isnull = false;

    /* Rewrite WKT */
    rewritten_wkt = geo_wkt_rewrite_p(fcinfo_local);

    /* Create geometry from rewritten WKT */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = rewritten_wkt;
    fcinfo_local->args[1].value = Int32GetDatum(0);  /* SRID 0 */
    fcinfo_local->args[1].isnull = false;
    geom_datum = lwgeom_from_text_p(fcinfo_local);

    /* Get geometry type */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = geom_datum;
    fcinfo_local->args[0].isnull = false;
    geom_type_datum = geometry_type_p(fcinfo_local);
    geom_type = text_to_cstring(DatumGetTextP(geom_type_datum));

    /* Return the created geometry if it's a point */
    if (strcmp(geom_type, "ST_Point") == 0)
        PG_RETURN_DATUM(geom_datum);

    /* If not a point, raise an error */
    ereport(ERROR,
            (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
             errmsg("%s is not supported", geom_type)));

    /* This line should never be reached */
    PG_RETURN_NULL();
}

Datum
charTogeog(PG_FUNCTION_ARGS)
{
    
    Datum   rewritten_wkt,
            geom_datum,
            geom_type_datum,
            flipped_geom,
            is_empty_datum,
            lat_datum;
    text    *input_text;
    char    *geom_type;
    bool    is_empty;
    float8  lat;
    LOCAL_FCINFO(fcinfo_local, 2);

    /* Load necessary functions */
    load_functions();

    /* Get the input text */
    input_text = PG_GETARG_TEXT_PP(0);

    /* Rewrite WKT */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = PointerGetDatum(input_text);
    fcinfo_local->args[0].isnull = false;
    
    /* Call geo_wkt_rewrite_p function to rewrite the WKT */
    rewritten_wkt = DirectFunctionCall1(geo_wkt_rewrite_p, PointerGetDatum(input_text));

    /* Create geometry from rewritten WKT */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 2, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = rewritten_wkt;
    fcinfo_local->args[0].isnull = false;
    fcinfo_local->args[1].value = Int32GetDatum(4326);  /* SRID 4326 */
    fcinfo_local->args[1].isnull = false;
    
    /* Call lwgeom_from_text_p function to create geometry from rewritten WKT */
    geom_datum = DirectFunctionCall2(lwgeom_from_text_p, rewritten_wkt, Int32GetDatum(4326));

    /* Get geometry type */
    geom_type_datum = DirectFunctionCall1(geometry_type_p, geom_datum);
    geom_type = text_to_cstring(DatumGetTextP(geom_type_datum));

    /* Check if geometry is empty */
    is_empty_datum = DirectFunctionCall1(st_isempty_p, geom_datum);
    is_empty = DatumGetBool(is_empty_datum);

    if (strcmp(geom_type, "ST_Point") == 0) {
        if (is_empty) {
            /* Return the empty geography */
            PG_RETURN_DATUM(geom_datum);
        }
        
        /* Flip coordinates for latitude check */
        flipped_geom = DirectFunctionCall1(st_flipcoordinates_p, geom_datum);

        /* Get latitude (X coordinate of flipped geometry) */
        lat_datum = DirectFunctionCall1(lwgeom_x_p, flipped_geom);
        lat = DatumGetFloat8(lat_datum);
        
        if (lat < -90.0 || lat > 90.0) {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Latitude values must be between -90 and 90 degrees")));
        }
        else if (lat >= -90.0 && lat <= 90.0) {
            /* Return the geography */
            PG_RETURN_DATUM(geom_datum);
        } 
    }
    else {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("%s is not supported", geom_type)));
    }

    /* This point should never be reached, but is needed to avoid compiler warnings */
    PG_RETURN_NULL();
}

Datum
geometry_from_bytea(PG_FUNCTION_ARGS)
{
    Datum   geometry_result;
    bytea   *input,
            *result;
    uint8   *input_data,
            *result_data,
            geom_type[2],
            dimension_flag = 0,
            coord_NaN[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f};
    int     input_len,
            byte_position = 6,
            isNaN = 0;        
    int32_t srid;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Load necessary functions */
    load_functions();

    /* Get input bytea */
    input = PG_GETARG_BYTEA_PP(0);
    input_data = (uint8 *)VARDATA_ANY(input);
    input_len = VARSIZE_ANY_EXHDR(input);

    /* Check if input is valid */
    if (input_len < 22)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid Geometry")));
    }

    /* Extract SRID from input */
    srid = (input_data[3] << 24) | (input_data[2] << 16) | (input_data[1] << 8) | input_data[0];

    /* Check for NaN coordinates */
    while (byte_position < input_len)
    {
        if (input_len - byte_position < 8)
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Invalid Geometry: Unexpected end of input")));
        }
        if (memcmp(input_data + byte_position, coord_NaN, 8) == 0)
        {
            isNaN = 1;
            break;
        }
        byte_position += 8;
    }

    /* Extract geometry type */
    memcpy(geom_type, input_data + 4, 2);

    /* Determine dimension flag (XY, XYZ, XYM, XYZM) */
    if (memcmp(geom_type, "\x01\x0c", 2) == 0)
        dimension_flag = 0;
    else if (memcmp(geom_type, "\x01\x0d", 2) == 0) 
        dimension_flag = 1;
    else if (memcmp(geom_type, "\x01\x0e", 2) == 0) 
        dimension_flag = 2;
    else if (memcmp(geom_type, "\x01\x0f", 2) == 0) 
        dimension_flag = 3;
    else
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Unsupported geometry type")));
    }

    /* Process valid geometries */
    if (srid >= 0 && srid <= 999999 && isNaN == 0)
    {
        /* Adjust the new header for XYZ, XYM, and XYZM */
        uint8 new_header[5] = "\x01\x01\x00\x00\x20"; // Base header
        if (dimension_flag == 1) new_header[4] = 0xA0; // XYZ
        if (dimension_flag == 2) new_header[4] = 0x60; // XYM
        if (dimension_flag == 3) new_header[4] = 0xE0; // XYZM

        /* Allocate memory for result */
        result = (bytea *) palloc(VARHDRSZ + input_len - 2 + 5);
        SET_VARSIZE(result, VARHDRSZ + input_len - 2 + 5);
        result_data = (uint8 *)VARDATA(result);

        /* Construct new geometry */
        memcpy(result_data, new_header, 5);
        memcpy(result_data + 5, input_data, 4);
        memcpy(result_data + 9, input_data + 6, input_len - 6);
    }
    else
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geometry.")));
    }

    /* Call the underlying function after preprocessing */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = PointerGetDatum(result);
    fcinfo_local->args[0].isnull = false;
    geometry_result = DirectFunctionCall1(lwgeom_from_bytea_p, PointerGetDatum(result));

    return geometry_result;
}

Datum
geography_from_bytea(PG_FUNCTION_ARGS)
{
    Datum       geography_result;
    bytea       *input,
                *result;
    uint8       *input_data,
                *result_data,
                geom_type[2],
                dimension_flag = 0,
                coord_NaN[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f};
    int         input_len,
                byte_position = 6,
                isNaN = 0,
                num_valid_srids;        
    int32_t     srid;
    double      lat;
    uint64_t    lat_bits;
    bool        srid_valid = false;
    int32       *valid_srids;
    ArrayType   *valid_srids_array;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Load necessary functions */
    load_functions();

    /* Get input bytea */
    input = PG_GETARG_BYTEA_PP(0);
    input_data = (uint8 *)VARDATA_ANY(input);
    input_len = VARSIZE_ANY_EXHDR(input);

    /* Check if input is valid */
    if (input_len < 22)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Invalid Geography")));
    }

    /* Extract SRID from input */
    srid = (input_data[3] << 24) | (input_data[2] << 16) | (input_data[1] << 8) | input_data[0];

    /* Calculate latitude */
    memcpy(&lat_bits, input_data + 6, sizeof(uint64_t));
    lat_bits = le64toh(lat_bits);  // Convert from little-endian to host byte order
    memcpy(&lat, &lat_bits, sizeof(double));
        

    /* Check for NaN coordinates */
    while (byte_position < input_len)
    {
        if (input_len - byte_position < 8)
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Invalid Geography: Unexpected end of input")));
        }
        if (memcmp(input_data + byte_position, coord_NaN, 8) == 0)
        {
            isNaN = 1;
            break;
        }
        byte_position += 8;
    }

    /* Extract geometry type */
    memcpy(geom_type, input_data + 4, 2);

    /* Determine dimension flag (XY, XYZ, XYM, XYZM) */
    if (memcmp(geom_type, "\x01\x0c", 2) == 0)
        dimension_flag = 0;
    else if (memcmp(geom_type, "\x01\x0d", 2) == 0) 
        dimension_flag = 1;
    else if (memcmp(geom_type, "\x01\x0e", 2) == 0) 
        dimension_flag = 2;
    else if (memcmp(geom_type, "\x01\x0f", 2) == 0) 
        dimension_flag = 3;
    else
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Unsupported geography type")));
    }

    /* Get valid SRIDs */
    valid_srids_array = DatumGetArrayTypeP(DirectFunctionCall1(get_valid_srids, Int32GetDatum(0)));
    valid_srids = (int32 *)ARR_DATA_PTR(valid_srids_array);
    num_valid_srids = ArrayGetNItems(ARR_NDIM(valid_srids_array), ARR_DIMS(valid_srids_array));

    /* Check if SRID is valid */
    for (int i = 0; i < num_valid_srids; i++)
    {
        if (valid_srids[i] == srid)
        {
            srid_valid = true;
            break;
        }
    }

    /* Process valid geographies */
    if (srid_valid && isNaN == 0)
    {
        if (lat >= -90.0 && lat <= 90.0)
        {
            /* Adjust the new header for XYZ, XYM, and XYZM */
            uint8 new_header[5] = "\x01\x01\x00\x00\x20"; // Base header
            if (dimension_flag == 1) new_header[4] = 0xA0; // XYZ
            if (dimension_flag == 2) new_header[4] = 0x60; // XYM
            if (dimension_flag == 3) new_header[4] = 0xE0; // XYZM

            /* Allocate memory for result */
            result = (bytea *) palloc(VARHDRSZ + input_len - 2 + 5);
            SET_VARSIZE(result, VARHDRSZ + input_len - 2 + 5);
            result_data = (uint8 *)VARDATA(result);

            /* Construct new geography */
            memcpy(result_data, new_header, 5);
            memcpy(result_data + 5, input_data, 4);  /* SRID */
            memcpy(result_data + 9, input_data + 6, input_len - 6);  /* coordinates */
        }
        else
        {
            ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                     errmsg("Error converting data type varbinary to geography.")));
        }
    }
    else
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("Error converting data type varbinary to geography.")));
    }

    /* Call the underlying function after preprocessing */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = PointerGetDatum(result);
    fcinfo_local->args[0].isnull = false;
    geography_result = DirectFunctionCall1(lwgeom_from_bytea_p, PointerGetDatum(result));

    return geography_result;
}

Datum
bytea_from_geometry(PG_FUNCTION_ARGS)
{
    Datum   geom_datum;
    bytea   *byte,
            *result;
    uint8   *byte_data,
            srid_flag,
            *result_data,
            point_type;
    int     byte_len,
            srid_size,
            coord_size;
    bool    has_srid;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Load necessary functions */
    load_functions();

    /* Get the GEOMETRY input */
    geom_datum = PG_GETARG_DATUM(0);

    /* Call bytea_helper function */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = geom_datum;
    fcinfo_local->args[0].isnull = false;
    byte = DatumGetByteaPP(lwgeom_to_bytea_p(fcinfo_local));

    byte_data = (uint8 *)VARDATA_ANY(byte);
    byte_len = VARSIZE_ANY_EXHDR(byte);

    /* Check the Geometry type (POINT type -> type = 1) */
    if (byte_len >= 5 && byte_data[1] == 0x01 && byte_data[2] == 0x00 && byte_data[3] == 0x00)
    {
        srid_flag = byte_data[4];
        has_srid = srid_flag & 0x20;
        srid_size = 4;
   
        /* Determine point type and coordinate size */
        if ((srid_flag & 0xC0) == 0x00) {
            point_type = 0x0c;  /* XY */
            coord_size = 16;
        } else if ((srid_flag & 0xC0) == 0x80) {
            point_type = 0x0d;  /* XYZ */
            coord_size = 24;
        } else if ((srid_flag & 0xC0) == 0xC0) {
            point_type = 0x0f;  /* XYZM */
            coord_size = 32;
        } else if ((srid_flag & 0xC0) == 0x40) {
            point_type = 0x0e;  /* XYM */
            coord_size = 24;
        } else {
            /* Unsupported type, return original byte */
            PG_RETURN_BYTEA_P(byte);
        }

        /* Allocate memory for result */
        result = (bytea *) palloc(6 + srid_size + coord_size);
        SET_VARSIZE(result, 6 + srid_size + coord_size);
        result_data = (uint8 *)VARDATA(result);
        
        /* Copy or set SRID */
        if (has_srid)
        {
            /* Copy SRID */
            memcpy(result_data, byte_data + 5, 4);
        }
        else
        {
            /* Set SRID to 0 */
            memset(result_data, 0, 4);
        }

        /* 
        * Set geometry type 
        * Set type to 0x01xx for POINT
        */
        result_data[4] = 0x01;  
        result_data[5] = point_type;

        if (has_srid)
        {
            /* Copy coordinates */
            memcpy(result_data + 6, byte_data + 9, coord_size);  
        }
        else
        {
            /* Copy coordinates */
            memcpy(result_data + 6, byte_data + 5, coord_size);  
        }
        PG_RETURN_BYTEA_P(result);
    }
    /* If no modifications were made, return the original byte */
    PG_RETURN_BYTEA_P(byte);
}

Datum
bytea_from_geography(PG_FUNCTION_ARGS)
{
    Datum   geom_datum;
    bytea   *byte,
            *result;
    uint8   *byte_data,
            srid_flag,
            *result_data,
            point_type;
    int     byte_len,
            srid_size,
            coord_size;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Load necessary functions */
    load_functions();

    /* Get the GEOMETRY input */
    geom_datum = PG_GETARG_DATUM(0);

    /* Call bytea_helper function */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, PG_GET_COLLATION(), NULL, NULL);
    fcinfo_local->args[0].value = geom_datum;
    fcinfo_local->args[0].isnull = false;
    byte = DatumGetByteaPP(lwgeom_to_bytea_p(fcinfo_local));

    byte_data = (uint8 *)VARDATA_ANY(byte);
    byte_len = VARSIZE_ANY_EXHDR(byte);

    /* Check the Geometry type (POINT type -> type = 1) */
    if (byte_len >= 9 && byte_data[1] == 0x01 && byte_data[2] == 0x00 && byte_data[3] == 0x00)
    {
        srid_flag = byte_data[4];
        srid_size = 4;
   
        /* Determine point type and coordinate size */
        if ((srid_flag & 0xC0) == 0x00) {
            point_type = 0x0c;  /* XY */
            coord_size = 16;
        } else if ((srid_flag & 0xC0) == 0x80) {
            point_type = 0x0d;  /* XYZ */
            coord_size = 24;
        } else if ((srid_flag & 0xC0) == 0xC0) {
            point_type = 0x0f;  /* XYZM */
            coord_size = 32;
        } else if ((srid_flag & 0xC0) == 0x40) {
            point_type = 0x0e;  /* XYM */
            coord_size = 24;
        } else {
            /* Unsupported type, return original byte */
            PG_RETURN_BYTEA_P(byte);
        }

        /* Allocate memory for result */
        result = (bytea *) palloc(6 + srid_size + coord_size);
        SET_VARSIZE(result, 6 + srid_size + coord_size);
        result_data = (uint8 *)VARDATA(result);
        
        /* Copy SRID */
        memcpy(result_data, byte_data + 5, 4);

        /* 
        * Set geometry type 
        * Set type to 0x01xx for POINT
        */
        result_data[4] = 0x01;  
        result_data[5] = point_type;

        /* Copy coordinates */
        memcpy(result_data + 6, byte_data + 9, coord_size);  

        PG_RETURN_BYTEA_P(result);
    }
    /* If no modifications were made, return the original byte */
    PG_RETURN_BYTEA_P(byte);
}

Datum
st_as_binary_geometry(PG_FUNCTION_ARGS)
{
    Datum   geom,
            modified_geom,
            result,
            geom_type_datum;
    bool    is_empty;
    char    *geom_type;
    bytea   *empty_geom;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Load necessary functions */
    load_functions();

    /* Get input geometry */
    geom = PG_GETARG_DATUM(0);

    /* Check if geometry is empty */
    is_empty = DatumGetBool(DirectFunctionCall1(st_isempty_p, geom));

    if (is_empty)
    {
        /* Get geometry type */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = geom;
        fcinfo_local->args[0].isnull = false;
        geom_type_datum = geometry_type_p(fcinfo_local);
        geom_type = text_to_cstring(DatumGetTextP(geom_type_datum));

        /* For empty geometries, return the specific binary representation */
        empty_geom = palloc(VARHDRSZ + 9);
        SET_VARSIZE(empty_geom, VARHDRSZ + 9);
        
        if (strcmp(geom_type, "ST_Point") == 0)
        {
            memcpy(VARDATA(empty_geom), "\x01\x04\x00\x00\x00\x00\x00\x00\x00", 9);
        }
        pfree(geom_type);
        PG_RETURN_BYTEA_P(empty_geom);

    }
    else
    {
        /* Create a new geometry without Z and M dimensions */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = geom;
        fcinfo_local->args[0].isnull = false;
        modified_geom = lwgeom_force_2d_p(fcinfo_local);

        /* Call the existing ST_AsBinary function with the modified geometry */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = modified_geom;
        fcinfo_local->args[0].isnull = false;
        result = lwgeom_asBinary_p(fcinfo_local);

        PG_RETURN_DATUM(result);
    }
}

Datum
st_as_binary_geography(PG_FUNCTION_ARGS)
{
    Datum   geom,
            modified_geom,
            flipped_geom,
            result,
            geom_type_datum;
    bool    is_empty;
    char    *geom_type;
    bytea   *empty_geom;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Load necessary functions */
    load_functions();

    /* Get input geometry */
    geom = PG_GETARG_DATUM(0);

    /* Check if geometry is empty */
    is_empty = DatumGetBool(DirectFunctionCall1(st_isempty_p, geom));

    if (is_empty)
    {
        /* Get geometry type */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = geom;
        fcinfo_local->args[0].isnull = false;
        geom_type_datum = geometry_type_p(fcinfo_local);
        geom_type = text_to_cstring(DatumGetTextP(geom_type_datum));

        /* For empty geometries, return the specific binary representation */
        empty_geom = palloc(VARHDRSZ + 9);
        SET_VARSIZE(empty_geom, VARHDRSZ + 9);
        
        if (strcmp(geom_type, "ST_Point") == 0)
        {
            memcpy(VARDATA(empty_geom), "\x01\x04\x00\x00\x00\x00\x00\x00\x00", 9);
        }
        pfree(geom_type);
        PG_RETURN_BYTEA_P(empty_geom);
    }
    else
    {
        /* Create a new geometry without Z and M dimensions */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = geom;
        fcinfo_local->args[0].isnull = false;
        modified_geom = lwgeom_force_2d_p(fcinfo_local);

        /* Flip the coordinates */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = modified_geom;
        fcinfo_local->args[0].isnull = false;
        flipped_geom = st_flipcoordinates_p(fcinfo_local);

        /* Call the existing ST_AsBinary function with the flipped geometry */
        InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
        fcinfo_local->args[0].value = flipped_geom;
        fcinfo_local->args[0].isnull = false;
        result = lwgeom_asBinary_p(fcinfo_local);

        PG_RETURN_DATUM(result);
    }
}

Datum
st_as_text(PG_FUNCTION_ARGS)
{
    Datum   geom,
            forced_2d_geom,
            result;
    LOCAL_FCINFO(fcinfo_local, 1);

    /* Load necessary functions */
    load_functions();

    /* Get input geometry */
    geom = PG_GETARG_DATUM(0);

    /* Force the geometry to 2D */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = geom;
    fcinfo_local->args[0].isnull = false;
    forced_2d_geom = lwgeom_force_2d_p(fcinfo_local);

    /* Call the helper function with the 2D geometry */
    InitFunctionCallInfoData(*fcinfo_local, NULL, 1, InvalidOid, NULL, NULL);
    fcinfo_local->args[0].value = forced_2d_geom;
    fcinfo_local->args[0].isnull = false;
    result = lwgeom_astext_p(fcinfo_local);

    PG_RETURN_DATUM(result);
}

#endif
