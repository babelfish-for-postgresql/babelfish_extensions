#include "postgres.h"
#include "fmgr.h"

/* Function declarations */
extern Datum geometry_in(PG_FUNCTION_ARGS);
extern Datum geography_in(PG_FUNCTION_ARGS);
extern Datum get_geometry_from_text(PG_FUNCTION_ARGS);
extern Datum charTogeom(PG_FUNCTION_ARGS);
extern Datum geometry_from_bytea(PG_FUNCTION_ARGS);
extern Datum bytea_from_geometry(PG_FUNCTION_ARGS);
extern Datum geography_from_bytea(PG_FUNCTION_ARGS);
extern Datum bytea_from_geography(PG_FUNCTION_ARGS);
extern Datum get_geography_from_text(PG_FUNCTION_ARGS);
extern Datum charTogeog(PG_FUNCTION_ARGS);
extern Datum geography_point(PG_FUNCTION_ARGS);
extern Datum st_as_binary_geometry(PG_FUNCTION_ARGS);
extern Datum st_as_binary_geography(PG_FUNCTION_ARGS);
extern Datum st_as_text(PG_FUNCTION_ARGS);
extern Datum geometry_astext(PG_FUNCTION_ARGS);
extern Datum geometry_asbpchar(PG_FUNCTION_ARGS);

/* Function to rewrite geospatial data */
extern text* geo_wkt_rewrite(text *input_text);
