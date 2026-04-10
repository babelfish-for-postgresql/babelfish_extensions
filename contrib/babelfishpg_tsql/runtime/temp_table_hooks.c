/*-------------------------------------------------------------------------
 *
 * temp_table_hooks.c
 *	  Functions for handling temp table attribute lookups
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/skey.h"
#include "access/table.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/pg_attribute.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/queryenvironment.h"

#include "../src/pltsql.h"
#include "../src/multidb.h"
#include "functions.h"

#define OBJECT_TYPE	"u"

PG_FUNCTION_INFO_V1(get_tsql_temp_table_attributes);
PG_FUNCTION_INFO_V1(is_temp_table_name);

/*
 * get_tsql_temp_table_attributes
 *		Returns pg_attribute rows for a temp table.
 *
 * Uses object_id() to resolve table name to OID, then retrieves attributes
 * from ENR cache or pg_attribute catalog.
 *
 * This function only works on TDS connections.
 */
Datum
get_tsql_temp_table_attributes(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	Relation	attrel;
	Oid			relid = InvalidOid;
	Datum		tablename = PG_GETARG_DATUM(0);

	/* Setup SRF using pg_attribute's tuple descriptor */
	attrel = table_open(AttributeRelationId, AccessShareLock);
	rsinfo->expectedDesc = RelationGetDescr(attrel);
	InitMaterializedSRF(fcinfo, MAT_SRF_USE_EXPECTED_DESC | MAT_SRF_BLESS);

	/* Only process on TDS connections */
	if (!is_bbf_tds_connection_hook())
		elog(ERROR, "function is only supported on TDS connections");

	/* Resolve table name to OID via object_id() */
	if (!PG_ARGISNULL(0))
	{
		PG_TRY();
		{
			relid = DatumGetObjectId(DirectFunctionCall2(object_id, tablename, CStringGetTextDatum(OBJECT_TYPE)));
		}
		PG_CATCH();
		{
			/* object_id threw an error - return empty result set */
			FlushErrorState();
			table_close(attrel, AccessShareLock);
			PG_RETURN_NULL();
		}
		PG_END_TRY();
	}

	/* Return empty if table not found */
	if (!OidIsValid(relid))
	{
		table_close(attrel, AccessShareLock);
		PG_RETURN_NULL();
	}

	PG_TRY();
	{
		EphemeralNamedRelation enr = GetENRTempTableWithOid(relid, false);

		if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
		{
			/* ENR path: use cached tuples, skip system attributes */
			ListCell *lc;
			foreach(lc, enr->md.cattups[ENR_CATTUP_ATTRIBUTE])
			{
				HeapTuple	tup = (HeapTuple) lfirst(lc);
				Form_pg_attribute att = (Form_pg_attribute) GETSTRUCT(tup);

				if (att->attnum > 0)
					tuplestore_puttuple(rsinfo->setResult, heap_copytuple(tup));
			}
		}
		else if (isTempNamespace(get_rel_namespace(relid)))
		{
			/* Non-ENR temp table path: scan pg_attribute, skip system attributes */
			ScanKeyData skey[1];
			SysScanDesc scan;
			HeapTuple	tup;

			ScanKeyInit(&skey[0], Anum_pg_attribute_attrelid, BTEqualStrategyNumber, F_OIDEQ, ObjectIdGetDatum(relid));
			scan = systable_beginscan(attrel, AttributeRelidNumIndexId, true, NULL, 1, skey);
			while (HeapTupleIsValid(tup = systable_getnext(scan)))
			{
				Form_pg_attribute att = (Form_pg_attribute) GETSTRUCT(tup);

				if (att->attnum > 0)
					tuplestore_puttuple(rsinfo->setResult, tup);
			}
			systable_endscan(scan);
		}
	}
	PG_FINALLY();
	{
		table_close(attrel, AccessShareLock);
	}
	PG_END_TRY();

	PG_RETURN_NULL();
}

/*
 * is_temp_table_name
 *		Returns true if the object name starts with #.
 *
 * Handles four-part qualified names with quoted identifiers or brackets.
 * Only works on TDS connections, returns false otherwise.
 */
Datum
is_temp_table_name(PG_FUNCTION_ARGS)
{
	char   *input;
	char   *object_name;
	bool	result;

	/* Only process on TDS connections */
	if (!is_bbf_tds_connection_hook())
		PG_RETURN_BOOL(false);

	/* Validate argument at the start */
	if (PG_ARGISNULL(0))
		PG_RETURN_BOOL(false);

	/* Extract argument into local variable */
	input = text_to_cstring(PG_GETARG_VARCHAR_PP(0));

	downcase_truncate_split_object_name(input, NULL, NULL, NULL, &object_name);
	pfree(input);

	result = (object_name[0] == '#');
	pfree(object_name);

	PG_RETURN_BOOL(result);
}
