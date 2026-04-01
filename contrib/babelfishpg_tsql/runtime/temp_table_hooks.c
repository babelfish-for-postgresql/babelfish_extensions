/*-------------------------------------------------------------------------
 *
 * temp_table_hooks.c
 *	  Functions for handling temp table attribute lookups for BCP support
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
#include "parser/parser.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/queryenvironment.h"

#include "../src/pltsql.h"
#include "../src/multidb.h"

extern Datum object_id(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(get_tsql_temp_table_attributes);
PG_FUNCTION_INFO_V1(is_temp_table_name);

/*
 * get_tsql_temp_table_attributes
 *		Returns pg_attribute rows for a temp table.
 *
 * Uses object_id() to resolve table name to OID, then retrieves attributes
 * from ENR cache or pg_attribute catalog.
 *
 * This function only works in T-SQL dialect context. Returns empty result
 * set when called from PG dialect.
 */
Datum
get_tsql_temp_table_attributes(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	Relation	attrel;
	Oid			relid = InvalidOid;

	attrel = table_open(AttributeRelationId, AccessShareLock);

	PG_TRY();
	{
		/* Setup SRF using pg_attribute's tuple descriptor */
		rsinfo->expectedDesc = RelationGetDescr(attrel);
		InitMaterializedSRF(fcinfo, MAT_SRF_USE_EXPECTED_DESC | MAT_SRF_BLESS);

		/*
		 * Only process in T-SQL dialect or TDS connection. In PG dialect from
		 * non-TDS connection, return empty result set.
		 */
		if (sql_dialect == SQL_DIALECT_TSQL ||
			(is_bbf_tds_connection_hook && is_bbf_tds_connection_hook()))
		{
			/* Resolve table name to OID via object_id() */
			if (!PG_ARGISNULL(0))
			{
				LOCAL_FCINFO(locfcinfo, 2);
				FmgrInfo	flinfo;

				MemSet(&flinfo, 0, sizeof(flinfo));
				flinfo.fn_addr = object_id;
				flinfo.fn_nargs = 2;
				flinfo.fn_mcxt = CurrentMemoryContext;

				InitFunctionCallInfoData(*locfcinfo, &flinfo, 2, InvalidOid, NULL, NULL);
				locfcinfo->args[0].value = PG_GETARG_DATUM(0);
				locfcinfo->args[0].isnull = false;
				locfcinfo->args[1].value = (Datum) 0;
				locfcinfo->args[1].isnull = true;

				relid = DatumGetObjectId(FunctionCallInvoke(locfcinfo));
				if (locfcinfo->isnull)
					relid = InvalidOid;
			}

			/* Populate tuplestore if valid OID */
			if (OidIsValid(relid))
			{
				EphemeralNamedRelation enr = GetENRTempTableWithOid(relid, false);

				if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
				{
					/* ENR path: use cached tuples */
					ListCell *lc;
					foreach(lc, enr->md.cattups[ENR_CATTUP_ATTRIBUTE])
						tuplestore_puttuple(rsinfo->setResult,
											heap_copytuple((HeapTuple) lfirst(lc)));
				}
				else if (isTempNamespace(get_rel_namespace(relid)))
				{
					/* Non-ENR temp table path: scan pg_attribute */
					ScanKeyData skey[1];
					SysScanDesc scan;
					HeapTuple	tup;

					ScanKeyInit(&skey[0], Anum_pg_attribute_attrelid,
								BTEqualStrategyNumber, F_OIDEQ, ObjectIdGetDatum(relid));
					scan = systable_beginscan(attrel, AttributeRelidNumIndexId,
											  true, NULL, 1, skey);
					while (HeapTupleIsValid(tup = systable_getnext(scan)))
						tuplestore_puttuple(rsinfo->setResult, tup);
					systable_endscan(scan);
				}
				/* Regular tables: return empty result set */
			}
		}
	}
	PG_FINALLY();
	{
		table_close(attrel, AccessShareLock);
	}
	PG_END_TRY();

	return (Datum) 0;
}

/*
 * is_temp_table_name
 *		Returns true if the object name starts with #.
 *
 * Handles four-part qualified names with quoted identifiers or brackets.
 */
Datum
is_temp_table_name(PG_FUNCTION_ARGS)
{
	char   *input;
	char   *object_name;
	bool	result;

	if (PG_ARGISNULL(0))
		PG_RETURN_BOOL(false);

	input = text_to_cstring(PG_GETARG_VARCHAR_PP(0));
	downcase_truncate_split_object_name(input, NULL, NULL, NULL, &object_name);
	pfree(input);

	result = (object_name[0] == '#');
	pfree(object_name);

	PG_RETURN_BOOL(result);
}
