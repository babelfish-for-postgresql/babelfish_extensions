/*-------------------------------------------------------------------------
 *
 * functions.h
 *	  Declarations for runtime functions
 *
 *-------------------------------------------------------------------------
 */
#ifndef BABELFISHPG_TSQL_FUNCTIONS_H
#define BABELFISHPG_TSQL_FUNCTIONS_H

#include "fmgr.h"

/* Object resolution functions */
extern Datum object_id(PG_FUNCTION_ARGS);

#endif							/* BABELFISHPG_TSQL_FUNCTIONS_H */
