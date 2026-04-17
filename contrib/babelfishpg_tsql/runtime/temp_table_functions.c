/*-------------------------------------------------------------------------
 *
 * temp_table_functions.c
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
#include "catalog/pg_class.h"
#include "fmgr.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "utils/aclchk_internal.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/queryenvironment.h"

#include "src/hooks.h"
#include "src/pltsql.h"
#include "src/multidb.h"

PG_FUNCTION_INFO_V1(get_all_temp_table_attributes);

/*
 * get_all_temp_table_attributes
 *		Returns pg_attribute rows for all temp tables (ENR and non-ENR).
 *
 * This function only works on TDS connections.
 */
Datum
get_all_temp_table_attributes(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	ListCell   *lc, *lcoid;
	Relation	attrel;
	List	   *enrList;
	List	   *nonEnrList;

	InitMaterializedSRF(fcinfo, MAT_SRF_USE_EXPECTED_DESC | MAT_SRF_BLESS);

	/* Only process on TDS connections */
	if (!IS_TDS_CONN())
		PG_RETURN_NULL();

	attrel = table_open(AttributeRelationId, AccessShareLock);
	enrList = getEnrByRelkind(RELKIND_RELATION);
	nonEnrList = getRelationsInNamespace(GetTempNamespace(), RELKIND_RELATION);

	foreach(lc, enrList)
	{
		EphemeralNamedRelation enr = (EphemeralNamedRelation) lfirst(lc);
		List *attList;
		ListCell *attlc;

		attList = enr->md.cattups[ENR_CATTUP_ATTRIBUTE];

		foreach(attlc, attList)
		{
			HeapTuple	tup = (HeapTuple) lfirst(attlc);
			if (tup != NULL)
				tuplestore_puttuple(rsinfo->setResult, heap_copytuple(tup));
		}
	}

	foreach(lcoid, nonEnrList)
	{
		Oid relid = (Oid) lfirst_oid(lcoid);
		ScanKeyData attskey[1];
		SysScanDesc attscan;
		HeapTuple	atttup;

		ScanKeyInit(&attskey[0], Anum_pg_attribute_attrelid, BTEqualStrategyNumber, F_OIDEQ, ObjectIdGetDatum(relid));
		attscan = systable_beginscan(attrel, AttributeRelidNumIndexId, true, NULL, 1, attskey);
		while (HeapTupleIsValid(atttup = systable_getnext(attscan)))
		{
			tuplestore_puttuple(rsinfo->setResult, atttup);
		}
		systable_endscan(attscan);
	}

	list_free(enrList);
	table_close(attrel, AccessShareLock);
	PG_RETURN_NULL();
}
