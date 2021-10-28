/*-------------------------------------------------------------------------
 *
 * collationproperty.c
 *	  Function collationproperty
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/htup_details.h"
#include "catalog/pg_database.h"
#include "commands/dbcommands.h"
#include "utils/builtins.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "collation.h"

PG_FUNCTION_INFO_V1(collationproperty);

extern bytea *convertIntToSQLVariantByteA(int ret);
extern  coll_info_t coll_infos[];

Datum collationproperty(PG_FUNCTION_ARGS) {
	const char *collationname = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *property = text_to_cstring(PG_GETARG_TEXT_P(1));
	int collidx = find_any_collation(collationname);
	
	if (collidx >= 0)
	{
	    coll_info_t coll = coll_infos[collidx];

	    if (strcasecmp(property, "CodePage") == 0)
		PG_RETURN_BYTEA_P(convertIntToSQLVariantByteA(coll.code_page));
	    else if (strcasecmp(property, "LCID") == 0)
		PG_RETURN_BYTEA_P(convertIntToSQLVariantByteA(coll.lcid));
	    else if (strcasecmp(property, "ComparisonStyle") == 0)
		PG_RETURN_BYTEA_P(convertIntToSQLVariantByteA(coll.style));
	    else if (strcasecmp(property, "Version") == 0)
		PG_RETURN_BYTEA_P(convertIntToSQLVariantByteA(coll.ver));
	    else
		PG_RETURN_NULL();
	}

	PG_RETURN_NULL();
}
