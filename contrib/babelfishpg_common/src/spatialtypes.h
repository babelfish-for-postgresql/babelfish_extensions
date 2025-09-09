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

extern Datum bytea_from_geometry(PG_FUNCTION_ARGS);
extern Datum bytea_from_geography(PG_FUNCTION_ARGS);

#endif  /* SPATIALTYPES_H */