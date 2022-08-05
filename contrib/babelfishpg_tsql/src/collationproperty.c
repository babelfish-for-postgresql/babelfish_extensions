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
#include "pltsql.h"

PG_FUNCTION_INFO_V1(collationproperty);

extern bytea *convertIntToSQLVariantByteA(int ret);
extern bytea *convertBinaryToSQLVariantByteA(int64_t ret);

extern  coll_info_t coll_infos[];

Datum collationproperty(PG_FUNCTION_ARGS)
{
	const char *collationname = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *property = text_to_cstring(PG_GETARG_TEXT_P(1));
	int64_t result64 = -1;
	int result32 = -1;

	if (strcasecmp(property, "tdscollation") == 0)
		result64 = tsql_tdscollationproperty_helper(collationname, property);
  	else
  		result32 = tsql_collationproperty_helper(collationname, property);


	if (result32 != -1)
		PG_RETURN_BYTEA_P(convertIntToSQLVariantByteA(result32));
	if (result64 != -1)
	{
		/* SQL variant Base type for tdscollation is Binary, while for the rest is INT. */
		PG_RETURN_BYTEA_P(convertBinaryToSQLVariantByteA(result64));
	}
	PG_RETURN_NULL();
}
