#include "postgres.h"

#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/skey.h"
#include "access/table.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/pg_attribute.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/queryenvironment.h"
#include "utils/tuplestore.h"

#include "../src/pltsql.h"
#include "../src/multidb.h"

PG_FUNCTION_INFO_V1(get_tsql_temp_table_attributes);
PG_FUNCTION_INFO_V1(is_temp_table_name);

/*
 * get_tsql_temp_table_attributes - Get pg_attribute rows for a temp table by name
 *
 * This function returns all pg_attribute columns for a temp table.
 * It works for both ENR temp tables (reads from ENR cache) and non-ENR temp tables
 * (reads from actual pg_attribute catalog).
 */
Datum
get_tsql_temp_table_attributes(PG_FUNCTION_ARGS)
{
	char	   *input;
	char	   *db_name;
	char	   *schema_name;
	char	   *object_name;
	Oid			relid = InvalidOid;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	EphemeralNamedRelation enr = NULL;
	Relation	pg_attribute_rel;
	bool		is_enr = false;

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	input = text_to_cstring(PG_GETARG_VARCHAR_PP(0));

	/* Parse the table name */
	downcase_truncate_split_object_name(input, NULL, &db_name, &schema_name, &object_name);
	pfree(input);

	/* Must be a temp table (starts with #) */
	if (object_name[0] != '#')
	{
		pfree(db_name);
		pfree(schema_name);
		pfree(object_name);
		PG_RETURN_NULL();
	}

	/* Try ENR first */
	if (currentQueryEnv != NULL)
	{
		enr = get_ENR(currentQueryEnv, object_name, true);
		if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
		{
			is_enr = true;
			relid = enr->md.reliddesc;
		}
	}

	/* If not ENR, try pg_temp namespace for non-ENR temp tables */
	if (!is_enr)
	{
		Oid temp_ns = LookupNamespaceNoError("pg_temp");
		if (OidIsValid(temp_ns))
			relid = get_relname_relid(object_name, temp_ns);
	}

	pfree(db_name);
	pfree(schema_name);
	pfree(object_name);

	if (!OidIsValid(relid))
		PG_RETURN_NULL();

	/* Setup return - use pg_attribute's tuple descriptor */
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	pg_attribute_rel = table_open(AttributeRelationId, AccessShareLock);
	tupdesc = CreateTupleDescCopy(RelationGetDescr(pg_attribute_rel));

	tupstore = tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
									 false, work_mem);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = BlessTupleDesc(tupdesc);

	MemoryContextSwitchTo(oldcontext);

	if (is_enr)
	{
		/* ENR path: return tuples directly from ENR cache */
		ListCell   *lc;

		foreach(lc, enr->md.cattups[ENR_CATTUP_ATTRIBUTE])
		{
			HeapTuple	tup = (HeapTuple) lfirst(lc);

			tuplestore_puttuple(tupstore, tup);
		}
	}
	else
	{
		/* Non-ENR path: scan pg_attribute catalog */
		ScanKeyData skey[1];
		SysScanDesc scan;
		HeapTuple	tup;

		ScanKeyInit(&skey[0],
					Anum_pg_attribute_attrelid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(relid));

		scan = systable_beginscan(pg_attribute_rel, AttributeRelidNumIndexId,
								  true, NULL, 1, skey);

		while (HeapTupleIsValid(tup = systable_getnext(scan)))
		{
			tuplestore_puttuple(tupstore, tup);
		}

		systable_endscan(scan);
	}

	table_close(pg_attribute_rel, AccessShareLock);

	tuplestore_donestoring(tupstore);

	PG_RETURN_NULL();
}

/*
 * is_temp_table_name - Check if a name refers to a temp table
 *
 * Returns true if the object name part starts with #.
 *
 * The input name can be a four-part qualified name, with quoted identifiers
 * or square bracket qualifiers. We use downcase_truncate_split_object_name()
 * to parse and extract the object_name part.
 */
Datum
is_temp_table_name(PG_FUNCTION_ARGS)
{
	char	   *input;
	char	   *db_name;
	char	   *schema_name;
	char	   *object_name;
	bool		result = false;

	if (PG_ARGISNULL(0))
		PG_RETURN_BOOL(false);

	input = text_to_cstring(PG_GETARG_VARCHAR_PP(0));

	/* Parse the name to extract object_name */
	downcase_truncate_split_object_name(input, NULL, &db_name, &schema_name, &object_name);
	pfree(input);

	/* Check if object_name starts with # */
	if (object_name[0] == '#')
		result = true;

	pfree(db_name);
	pfree(schema_name);
	pfree(object_name);

	PG_RETURN_BOOL(result);
}
