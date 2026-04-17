/*-------------------------------------------------------------------------
 *
 * temp_table.c
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

/*
 * getEnrByRelkind
 *
 * Returns a list of ENRs filtered by relkind.
 */
static List *
getEnrByRelkind(char relkind)
{
	List			   *result = NIL;
	QueryEnvironment   *qe = currentQueryEnv;
	ListCell		   *lc;

	while (qe)
	{
		foreach(lc, qe->namedRelList)
		{
			EphemeralNamedRelation enr = (EphemeralNamedRelation) lfirst(lc);

			if (get_rel_relkind(enr->md.reliddesc) == relkind)
				result = lappend(result, enr);
		}
		qe = qe->parentEnv;
	}
	return result;
}


PG_FUNCTION_INFO_V1(get_enr_temp_table_attributes);

/*
 * get_enr_temp_table_attributes
 *		Returns pg_attribute rows for ENR temp tables only.
 *
 * This function only works on TDS connections.
 */
Datum
get_enr_temp_table_attributes(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	ListCell   *lc;
	List	   *enrList;

	InitMaterializedSRF(fcinfo, MAT_SRF_USE_EXPECTED_DESC | MAT_SRF_BLESS);

	/* Only process on TDS connections */
	if (!IS_TDS_CONN())
		PG_RETURN_NULL();

	enrList = getEnrByRelkind(RELKIND_RELATION);

	foreach(lc, enrList)
	{
		EphemeralNamedRelation enr = (EphemeralNamedRelation) lfirst(lc);
		List	   *attList = enr->md.cattups[ENR_CATTUP_ATTRIBUTE];
		ListCell   *attlc;

		foreach(attlc, attList)
		{
			HeapTuple	tup = (HeapTuple) lfirst(attlc);

			if (tup != NULL)
				tuplestore_puttuple(rsinfo->setResult, heap_copytuple(tup));
		}
	}

	list_free(enrList);
	PG_RETURN_NULL();
}

