/*-------------------------------------------------------------------------
 *
 * databasepropertyex.c
 *	  Function databasepropertyex
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/htup_details.h"
#include "access/xlog.h"
#include "catalog/pg_database.h"
#include "commands/dbcommands.h"
#include "pltsql.h"
#include "utils/builtins.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "catalog.h"
#include "datatypes.h"
#include "catalog.h"

PG_FUNCTION_INFO_V1(databasepropertyex);

Datum databasepropertyex(PG_FUNCTION_ARGS) {
	VarChar *vch = NULL;
	int64_t intVal = 0;
	const char *dbname = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *property = text_to_cstring(PG_GETARG_TEXT_P(1));
	Oid		dboid = get_db_id(dbname);
	if(dboid == InvalidOid)
	{
		PG_RETURN_NULL();
	}

	if (strcasecmp(property, "Collation") == 0)
	{
		const char *ret = pstrdup(pltsql_server_collation_name);
		vch = (*common_utility_plugin_ptr->tsql_varchar_input)(ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "ComparisonStyle") == 0)
	{
		// TOOD:[BABEL-1015]
		intVal = 0;
	}
	else if (strcasecmp(property, "Edition") == 0)
	{
		const char *ret = "Standard";
		vch = (*common_utility_plugin_ptr->tsql_varchar_input)(ret, strlen(ret), -1);
	}
	//TODO[BABEL-247]
	else if (strcasecmp(property, "IsAnsiNullDefault") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsAnsiNullsEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsAnsiPaddingEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsAnsiWarningsEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsArithmeticAbortEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsAutoClose") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsAutoCreateStatistics") == 0)
	{
		intVal = 1;
	}
	else if (strcasecmp(property, "IsAutoCreateStatisticsIncremental") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsAutoShrink") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsAutoUpdateStatistics") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsClone") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsCloseCursorsOnCommitEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsFulltextEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsInStandBy") == 0)
	{
		if(RecoveryInProgress())
			intVal = 1;
		else
			intVal = 0;
	}
	else if (strcasecmp(property, "IsLocalCursorsDefault") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsMemoryOptimizedElevateToSnapshotEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsNullConcat") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsNumericRoundAbortEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsParameterizationForced	") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsQuotedIdentifiersEnabled") == 0)
	{
		//TODO:[BABEL-245]
		intVal = 0;
	}
	else if (strcasecmp(property, "IsPublished") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsRecursiveTriggersEnabled") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsSubscribed") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsSyncWithBackup") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsTornPageDetectionEnabled") == 0)
	{
		if(fullPageWrites)
			intVal = 1;
		else
			intVal = 0;
	}
	else if (strcasecmp(property, "IsVerifiedClone") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "IsXTPSupported") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "LastGoodCheckDbTime") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "LCID") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "MaxSizeInBytes") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "Recovery") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "ServiceObjective") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "ServiceObjectiveId") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "SQLSortOrder") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "Status") == 0)
	{
		const char *ret = "ONLINE";
		vch = (*common_utility_plugin_ptr->tsql_varchar_input)(ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "Updateability") == 0)
	{
		const char *ret = "READ_WRITE";
		vch = (*common_utility_plugin_ptr->tsql_varchar_input)(ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "UserAccess") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(property, "Version") == 0)
	{
		const char *ret = PG_VERSION;
		vch = (*common_utility_plugin_ptr->tsql_varchar_input)(ret, strlen(ret), -1);
	}
	else
	{
		/* no property name matches, return NULL */
		PG_RETURN_NULL();
	}

	if (vch != NULL) {
		PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertVarcharToSQLVariantByteA)(vch, PG_GET_COLLATION()));
	} else {
		PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertIntToSQLVariantByteA)(intVal));
	}
}

