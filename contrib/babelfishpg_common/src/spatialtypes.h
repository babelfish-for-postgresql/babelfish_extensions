/*-------------------------------------------------------------------------
 *
 * spatialtypes.h
 *	  Definitions for spatial data type conversions.
 *
 *-------------------------------------------------------------------------
 */

#ifndef SPATIALTYPES_H
#define SPATIALTYPES_H

#include "postgres.h"
#include "fmgr.h"

#ifdef ENABLE_SPATIAL_TYPES
extern Datum bytea_from_geometry(PG_FUNCTION_ARGS);
extern Datum bytea_from_geography(PG_FUNCTION_ARGS);
extern Datum geometry_from_bytea(PG_FUNCTION_ARGS);
extern Datum geography_from_bytea(PG_FUNCTION_ARGS);
#endif

#endif  /* SPATIALTYPES_H */
