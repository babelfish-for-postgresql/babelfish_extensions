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

extern coll_info_t coll_infos[];

Datum
collationproperty(PG_FUNCTION_ARGS)
{
	const char *collationname = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *property = text_to_cstring(PG_GETARG_TEXT_P(1));
	bytea	   *result64 = NULL;
	int			result32 = -1;

	if (strcasecmp(property, "tdscollation") == 0)
	{
		result64 = tsql_tdscollationproperty_helper(collationname, property);
		if (result64 != NULL)
			PG_RETURN_BYTEA_P(result64);
	}
	else
	{
		result32 = tsql_collationproperty_helper(collationname, property);
		if (result32 != -1)
			PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertIntToSQLVariantByteA) (result32));
	}
	PG_RETURN_NULL();
}
