/*-------------------------------------------------------------------------
 *
 * spatialtypes.h
 *      Definitions for spatial data type conversions.
 *
 *-------------------------------------------------------------------------
 */

#ifndef SPATIALTYPES_H
#define SPATIALTYPES_H

#include "postgres.h"
#include "fmgr.h"

#ifdef ENABLE_SPATIAL_TYPES

/* Shared bytea <-> spatial converters used across the module */
extern Datum bytea_from_geometry(PG_FUNCTION_ARGS);
extern Datum bytea_from_geography(PG_FUNCTION_ARGS);
extern Datum geometry_from_bytea(PG_FUNCTION_ARGS);
extern Datum geography_from_bytea(PG_FUNCTION_ARGS);

/* =========================================================
 * GEOMETRY
 * ========================================================= */

/* Predicates */
extern Datum bbf_st_intersects(PG_FUNCTION_ARGS);
extern Datum bbf_st_contains(PG_FUNCTION_ARGS);
extern Datum bbf_st_equals(PG_FUNCTION_ARGS);
extern Datum bbf_st_disjoint(PG_FUNCTION_ARGS);
extern Datum bbf_st_distance(PG_FUNCTION_ARGS);

/* Unary functions */
extern Datum bbf_st_area(PG_FUNCTION_ARGS);
extern Datum bbf_st_numpoints(PG_FUNCTION_ARGS);
extern Datum bbf_st_dimension(PG_FUNCTION_ARGS);
extern Datum bbf_st_isclosed(PG_FUNCTION_ARGS);
extern Datum bbf_st_makevalid(PG_FUNCTION_ARGS);
extern Datum bbf_st_geometrytype(PG_FUNCTION_ARGS);
extern Datum bbf_hasz(PG_FUNCTION_ARGS);
extern Datum bbf_hasm(PG_FUNCTION_ARGS);
extern Datum bbf_z(PG_FUNCTION_ARGS);
extern Datum bbf_m(PG_FUNCTION_ARGS);

/* Constructors */
extern Datum bbf_geometry_parse(PG_FUNCTION_ARGS);
extern Datum bbf_geometry_point(PG_FUNCTION_ARGS);
extern Datum bbf_geometry_stgeomfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geometry_stpointfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geometry_stlinefromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geometry_stpolyfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geometry_stmpointfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geometry_stmpointfromwkb(PG_FUNCTION_ARGS);

/* Operator wrappers */
extern Datum bbf_geom_op_equals(PG_FUNCTION_ARGS);
extern Datum bbf_geom_op_not_equals(PG_FUNCTION_ARGS);

/* Cast functions */
extern Datum bbf_geom_from_bpchar(PG_FUNCTION_ARGS);
extern Datum bbf_geom_from_varchar(PG_FUNCTION_ARGS);
extern Datum bbf_geom_from_varbinary(PG_FUNCTION_ARGS);
extern Datum bbf_geom_from_binary(PG_FUNCTION_ARGS);
extern Datum bbf_geom_to_varbinary(PG_FUNCTION_ARGS);
extern Datum bbf_geom_to_binary(PG_FUNCTION_ARGS);
extern Datum bbf_geom_asvarchar(PG_FUNCTION_ARGS);
extern Datum bbf_geom_to_text_error(PG_FUNCTION_ARGS);
extern Datum bbf_text_to_geom_error(PG_FUNCTION_ARGS);

/* =========================================================
 * GEOGRAPHY
 * ========================================================= */

/* Predicates */
extern Datum bbf_geog_intersects(PG_FUNCTION_ARGS);
extern Datum bbf_geog_contains(PG_FUNCTION_ARGS);
extern Datum bbf_geog_equals(PG_FUNCTION_ARGS);
extern Datum bbf_geog_disjoint(PG_FUNCTION_ARGS);
extern Datum bbf_geog_distance(PG_FUNCTION_ARGS);

/* Unary functions */
extern Datum bbf_geog_area(PG_FUNCTION_ARGS);
extern Datum bbf_geog_numpoints(PG_FUNCTION_ARGS);
extern Datum bbf_geog_dimension(PG_FUNCTION_ARGS);
extern Datum bbf_geog_isclosed(PG_FUNCTION_ARGS);
extern Datum bbf_geog_makevalid(PG_FUNCTION_ARGS);

/* Constructors */
extern Datum bbf_geography_parse(PG_FUNCTION_ARGS);
extern Datum bbf_geography_stgeomfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geography_stpointfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geography_stlinefromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geography_stpolyfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geography_stmpointfromtext(PG_FUNCTION_ARGS);
extern Datum bbf_geography_stmpointfromwkb(PG_FUNCTION_ARGS);

/* Operator wrappers */
extern Datum bbf_geog_op_equals(PG_FUNCTION_ARGS);
extern Datum bbf_geog_op_not_equals(PG_FUNCTION_ARGS);

/* Display + cast functions */
extern Datum bbf_geog_astext(PG_FUNCTION_ARGS);
extern Datum bbf_geog_asbpchar(PG_FUNCTION_ARGS);
extern Datum bbf_geog_asvarchar(PG_FUNCTION_ARGS);
extern Datum bbf_geog_from_bpchar(PG_FUNCTION_ARGS);
extern Datum bbf_geog_from_varchar(PG_FUNCTION_ARGS);
extern Datum bbf_geog_from_varbinary(PG_FUNCTION_ARGS);
extern Datum bbf_geog_from_binary(PG_FUNCTION_ARGS);
extern Datum bbf_geog_to_varbinary(PG_FUNCTION_ARGS);
extern Datum bbf_geog_to_binary(PG_FUNCTION_ARGS);
extern Datum bbf_geog_to_text_error(PG_FUNCTION_ARGS);
extern Datum bbf_text_to_geog_error(PG_FUNCTION_ARGS);

#endif  /* ENABLE_SPATIAL_TYPES */

#endif  /* SPATIALTYPES_H */
