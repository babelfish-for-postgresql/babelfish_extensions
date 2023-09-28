#include "postgres.h"

#include "typecode.h"
#include "fmgr.h"
#include "nodes/execnodes.h"
#include "utils/hsearch.h"
#include "utils/syscache.h"
#include "utils/memutils.h"
#include "utils/elog.h"
#include "utils/builtins.h"
#include "catalog/namespace.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_type.h"
#include "utils/lsyscache.h"


/*  Memory context  */
MemoryContext TransMemoryContext = NULL;

type_info_t type_infos[TOTAL_TYPECODE_COUNT] =
{
	{0, 1, "sql_variant", "sql_variant", 1, 1, 1},
	{0, 1, "datetimeoffset", "datetimeoffset", 2, 2, 2},
	{0, 1, "datetime2", "datetime2", 2, 3, 2},
	{0, 1, "datetime", "datetime", 2, 4, 1},
	{0, 1, "smalldatetime", "smalldatetime", 2, 5, 1},
	{0, 0, "date", "date", 2, 6, 1},
	{0, 0, "time", "time", 2, 7, 2},
	{0, 0, "float8", "float", 3, 8, 1},
	{0, 0, "float4", "real", 3, 9, 1},
	{0, 0, "numeric", "numeric", 4, 10, 3},
	{0, 1, "money", "money", 4, 11, 1},
	{0, 1, "smallmoney", "smallmoney", 4, 12, 1},
	{0, 0, "int8", "bigint", 4, 13, 1},
	{0, 0, "int4", "int", 4, 14, 1},
	{0, 0, "int2", "smallint", 4, 15, 1},
	{0, 1, "tinyint", "tinyint", 4, 16, 1},
	{0, 1, "bit", "bit", 4, 17, 1},
	{0, 1, "nvarchar", "nvarchar", 5, 18, 5},
	{0, 1, "nchar", "nchar", 5, 19, 5},
	{0, 1, "varchar", "varchar", 5, 20, 5},
	{0, 1, "bpchar", "char", 5, 21, 5},
	{0, 1, "varbinary", "varbinary", 6, 22, 3},
	{0, 1, "binary", "binary", 6, 23, 3},
	{0, 1, "uniqueidentifier", "uniqueidentifier", 7, 24, 1},
	{0, 0, "text", "text", 5, 25, 5},
	{0, 1, "ntext", "ntext", 5, 26, 5},
	{0, 1, "image", "image", 5, 27, 5},
	{0, 0, "xml", "xml", 5, 28, 5},
	{0, 0, "bpchar", "char", 5, 29, 5},
	{0, 1, "decimal", "decimal", 5, 30, 5},
	{0, 1, "sysname", "sysname", 5, 31, 5},
	{0, 1, "rowversion", "timestamp", 8, 32, 3},
	{0, 1, "timestamp", "timestamp", 8, 33, 3}
};

/* Hash tables to help backward searching (from OID to Persist ID) */
HTAB	   *ht_oid2typecode = NULL;
static bool inited_ht_oid2typecode = false;

/*
 *                  Translation Table Initializers
 *  Load information from C arrays into hash tables
 *  Initializers are called right after shared library loading
 *  During "CREATE EXTENSION", data types are created after initialization call
 *  In this case, initializers do nothing
 *  After data types are created, initializers will be triggered again
 *  with a built-in procedure
 *
 */

PG_FUNCTION_INFO_V1(init_tcode_trans_tab);

Datum
init_tcode_trans_tab(PG_FUNCTION_ARGS)
{
	HASHCTL		hashCtl;
	Oid			sys_nspoid;
	Oid			nspoid;
	ht_oid2typecode_entry_t *entry;

	if (TransMemoryContext == NULL) /* initialize memory context */
	{
		TransMemoryContext =
			AllocSetContextCreateInternal(NULL,
										  "SQL Variant Memory Context",
										  ALLOCSET_DEFAULT_SIZES);
	}

	if (ht_oid2typecode == NULL)	/* create hash table */
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(Oid);
		hashCtl.entrysize = sizeof(ht_oid2typecode_entry_t);
		hashCtl.hcxt = TransMemoryContext;
		ht_oid2typecode = hash_create("OID to Persist Type Code Mapping",
									  TOTAL_TYPECODE_COUNT,
									  &hashCtl,
									  HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	sys_nspoid = get_namespace_oid("sys", true);

	if (!OidIsValid(sys_nspoid))
		PG_RETURN_INT32(0);

	/* mark the hash table initialised */
	inited_ht_oid2typecode = true;

	/* retrieve oid and setup hashtable */
	for (int i = 0; i < TOTAL_TYPECODE_COUNT; i++)
	{
		nspoid = type_infos[i].nsp_is_sys ? sys_nspoid : PG_CATALOG_NAMESPACE;
		type_infos[i].oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
											CStringGetDatum(type_infos[i].pg_typname), ObjectIdGetDatum(nspoid));
		if (OidIsValid(type_infos[i].oid))
		{
			entry = hash_search(ht_oid2typecode, &type_infos[i].oid, HASH_ENTER, NULL);
			entry->persist_id = i;
		}
		else
		{
			/* type is not loaded. wait for next scan */
			inited_ht_oid2typecode = false;
		}
	}

	PG_RETURN_INT32(0);
}

type_info_t
get_tsql_type_info(uint8_t type_code)
{
	/* Initialise T-SQL type info hash table if not already done */
	if (!inited_ht_oid2typecode)
	{
		FunctionCallInfo fcinfo = NULL; /* empty interface */

		init_tcode_trans_tab(fcinfo);
	}

	return type_infos[type_code];
}

PG_FUNCTION_INFO_V1(typecode_list);

Datum
typecode_list(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not " \
						"allowed in this context")));

	/* need to build tuplestore in query context */
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	/*
	 * build tupdesc for result tuples.
	 */
	tupdesc = CreateTemplateTupleDesc(7);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "oid",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "pg_namespace",
					   TEXTOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "pg_typname",
					   TEXTOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "tsql_typname",
					   TEXTOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "type_family_priority",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "priority",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "sql_variant_hdr_size",
					   INT2OID, -1, 0);

	tupstore =
		tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
							  false, 1024);
	/* generate junk in short-term context */
	MemoryContextSwitchTo(oldcontext);

	/* scan all the variables in top estate */
	for (int i = 0; i < TOTAL_TYPECODE_COUNT; i++)
	{
		type_info_t *info = &type_infos[i];
		Datum		values[7];
		bool		nulls[7];

		MemSet(nulls, 0, sizeof(nulls));

		values[0] = info->oid;
		values[1] = info->nsp_is_sys ? CStringGetTextDatum("sys") : CStringGetTextDatum("pg_catalog");
		values[2] = CStringGetTextDatum(info->pg_typname);
		values[3] = CStringGetTextDatum(info->tsql_typname);
		values[4] = info->family_prio;
		values[5] = info->prio;
		values[6] = info->svhdr_size;

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	PG_RETURN_NULL();
}

PG_FUNCTION_INFO_V1(translate_pg_type_to_tsql);

Datum
translate_pg_type_to_tsql(PG_FUNCTION_ARGS)
{
	Oid			pg_type = PG_GETARG_OID(0);
	ht_oid2typecode_entry_t *entry;

	if (OidIsValid(pg_type))
	{
		entry = hash_search(ht_oid2typecode, &pg_type, HASH_FIND, NULL);

		if (entry && entry->persist_id < TOTAL_TYPECODE_COUNT)
			PG_RETURN_TEXT_P(CStringGetTextDatum(type_infos[entry->persist_id].tsql_typname));
	}
	PG_RETURN_NULL();
}

Oid
get_type_oid(int type_code)
{
	return type_infos[type_code].oid;
}

Oid			tsql_bpchar_oid = InvalidOid;
Oid			tsql_nchar_oid = InvalidOid;
Oid			tsql_varchar_oid = InvalidOid;
Oid			tsql_nvarchar_oid = InvalidOid;
Oid			tsql_ntext_oid = InvalidOid;
Oid			tsql_image_oid = InvalidOid;
Oid			tsql_binary_oid = InvalidOid;
Oid			tsql_sys_binary_oid = InvalidOid;
Oid			tsql_varbinary_oid = InvalidOid;
Oid			tsql_sys_varbinary_oid = InvalidOid;
Oid			tsql_rowversion_oid = InvalidOid;
Oid			tsql_timestamp_oid = InvalidOid;
Oid			tsql_datetime2_oid = InvalidOid;
Oid			tsql_smalldatetime_oid = InvalidOid;
Oid			tsql_datetimeoffset_oid = InvalidOid;
Oid			tsql_decimal_oid = InvalidOid;

Oid
lookup_tsql_datatype_oid(const char *typename)
{
	Oid			nspoid;
	Oid			typoid;

	nspoid = get_namespace_oid("sys", true);
	if (nspoid == InvalidOid)
		return InvalidOid;

	typoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));
	return typoid;
}

bool
is_tsql_bpchar_datatype(Oid oid)
{
	if (tsql_bpchar_oid == InvalidOid)
		tsql_bpchar_oid = lookup_tsql_datatype_oid("bpchar");
	return tsql_bpchar_oid == oid;
}

bool
is_tsql_nchar_datatype(Oid oid)
{
	if (tsql_nchar_oid == InvalidOid)
		tsql_nchar_oid = lookup_tsql_datatype_oid("nchar");
	return tsql_nchar_oid == oid;
}

bool
is_tsql_varchar_datatype(Oid oid)
{
	if (tsql_varchar_oid == InvalidOid)
		tsql_varchar_oid = lookup_tsql_datatype_oid("varchar");
	return tsql_varchar_oid == oid;
}

bool
is_tsql_nvarchar_datatype(Oid oid)
{
	if (tsql_nvarchar_oid == InvalidOid)
		tsql_nvarchar_oid = lookup_tsql_datatype_oid("nvarchar");
	return tsql_nvarchar_oid == oid;
}

bool
is_tsql_text_datatype(Oid oid)
{
	return TEXTOID == oid;
}

bool
is_tsql_ntext_datatype(Oid oid)
{
	if (tsql_ntext_oid == InvalidOid)
		tsql_ntext_oid = lookup_tsql_datatype_oid("ntext");
	return tsql_ntext_oid == oid;
}

bool
is_tsql_image_datatype(Oid oid)
{
	if (tsql_image_oid == InvalidOid)
		tsql_image_oid = lookup_tsql_datatype_oid("image");
	return tsql_image_oid == oid;
}

bool
is_tsql_binary_datatype(Oid oid)
{
	if (tsql_binary_oid == InvalidOid)
		tsql_binary_oid = lookup_tsql_datatype_oid("bbf_binary");
	return tsql_binary_oid == oid;
}

bool
is_tsql_sys_binary_datatype(Oid oid)
{
	if (tsql_sys_binary_oid == InvalidOid)
		tsql_sys_binary_oid = lookup_tsql_datatype_oid("binary");
	return tsql_sys_binary_oid == oid;
}

bool
is_tsql_varbinary_datatype(Oid oid)
{
	if (tsql_varbinary_oid == InvalidOid)
		tsql_varbinary_oid = lookup_tsql_datatype_oid("bbf_varbinary");
	return tsql_varbinary_oid == oid;
}

bool
is_tsql_sys_varbinary_datatype(Oid oid)
{
	if (tsql_sys_varbinary_oid == InvalidOid)
		tsql_sys_varbinary_oid = lookup_tsql_datatype_oid("varbinary");
	return tsql_sys_varbinary_oid == oid;
}

bool
is_tsql_rowversion_datatype(Oid oid)
{
	if (tsql_rowversion_oid == InvalidOid)
		tsql_rowversion_oid = lookup_tsql_datatype_oid("rowversion");
	return tsql_rowversion_oid == oid;
}

bool
is_tsql_timestamp_datatype(Oid oid)
{
	if (tsql_timestamp_oid == InvalidOid)
		tsql_timestamp_oid = lookup_tsql_datatype_oid("timestamp");
	return tsql_timestamp_oid == oid;
}

bool
is_tsql_rowversion_or_timestamp_datatype(Oid oid)
{
	return (is_tsql_rowversion_datatype(oid) || is_tsql_timestamp_datatype(oid));
}

bool
is_tsql_datetime2_datatype(Oid oid)
{
	if (tsql_datetime2_oid == InvalidOid)
		tsql_datetime2_oid = lookup_tsql_datatype_oid("datetime2");
	return tsql_datetime2_oid == oid;
}

bool
is_tsql_smalldatetime_datatype(Oid oid)
{
	if (tsql_smalldatetime_oid == InvalidOid)
		tsql_smalldatetime_oid = lookup_tsql_datatype_oid("smalldatetime");
	return tsql_smalldatetime_oid == oid;
}

bool
is_tsql_datetimeoffset_datatype(Oid oid)
{
	if (tsql_datetimeoffset_oid == InvalidOid)
		tsql_datetimeoffset_oid = lookup_tsql_datatype_oid("datetimeoffset");
	return tsql_datetimeoffset_oid == oid;
}

bool
is_tsql_decimal_datatype(Oid oid)
{
	if (tsql_decimal_oid == InvalidOid)
		tsql_decimal_oid = lookup_tsql_datatype_oid("decimal");
	return tsql_decimal_oid == oid;
}

/*
 * handle_type_and_collation - is implemented to handle the domain id and
 * collation id assigned to FuncExpr of the target column. (Maily for target types
 * based on [n][var]char including domains created over it.)
 */
void
handle_type_and_collation(Node *node, Oid typeid, Oid collationid)
{
	FuncExpr   *expr;

	/*
	 * We want to preserve the datatype and collation of the target column, so
	 * that it can be used later in datatype input function.
	 */
	if (nodeTag(node) == T_FuncExpr)
		expr = (FuncExpr *) node;

	/*
	 * If datatype of target column is created as domain over varchar or char
	 * (e.g., nvarchar or nchar) Or if datatypes is user defined datatype
	 * created over [n][var]char then override funcresulttype with the oid of
	 * the domain type and store the collation using funccollid field so that
	 * we can make distinction inside input function to handle the input.
	 */
	else if (nodeTag(node) == T_CoerceToDomain &&
			 ((CoerceToDomain *) node)->arg &&
			 nodeTag(((CoerceToDomain *) node)->arg) == T_FuncExpr)
		expr = (FuncExpr *) ((CoerceToDomain *) node)->arg;
	else if (nodeTag(node) == T_RelabelType &&
			 ((RelabelType *) node)->arg &&
			 nodeTag(((RelabelType *) node)->arg) == T_CoerceToDomain &&
			 ((CoerceToDomain *) ((RelabelType *) node)->arg)->arg &&
			 nodeTag(((CoerceToDomain *) ((RelabelType *) node)->arg)->arg) == T_FuncExpr)
		expr = (FuncExpr *) ((CoerceToDomain *) ((RelabelType *) node)->arg)->arg;
	else
		return;

	if (!check_target_type_is_sys_varchar(expr->funcid))
		return;

	expr->funcresulttype = typeid;

	if (OidIsValid(collationid))
		expr->funccollid = collationid;

	return;
}

/*
 * check_target_type_is_varchar - checks whether target type is [n][var]char based on supplied funcid
 */
bool
check_target_type_is_sys_varchar(Oid funcid)
{
	char	   *func_namespace = NULL;
	char	   *funcname = NULL;

	func_namespace = get_namespace_name(get_func_namespace(funcid));
	if (!func_namespace || strcmp("sys", func_namespace) != 0)
		return false;

	funcname = get_func_name(funcid);
	if (!funcname || (strcmp("varchar", funcname) != 0 && strcmp("bpchar", funcname) != 0))
		return false;

	return true;
}
