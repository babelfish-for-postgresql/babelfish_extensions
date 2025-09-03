/*-------------------------------------------------------------------------
 *
 * spatialtypes.h
 *	  Definitions for spatial data type conversions.
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "fmgr.h"

extern Datum bytea_from_geometry(PG_FUNCTION_ARGS);
extern Datum bytea_from_geography(PG_FUNCTION_ARGS);
