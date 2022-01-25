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


/*  Memory context  */
MemoryContext TransMemoryContext = NULL;

type_info_t type_infos[TOTAL_TYPECODE_COUNT] =
{
    {0, 1, "sql_variant"     , "sql_variant"     , 1,  1, 1},
    {0, 1, "datetimeoffset"  , "datetimeoffset"  , 2,  2, 2},
    {0, 1, "datetime2"       , "datetime2"       , 2,  3, 2},
    {0, 1, "datetime"        , "datetime"        , 2,  4, 1},
    {0, 1, "smalldatetime"   , "smalldatetime"   , 2,  5, 1},
    {0, 0, "date"            , "date"            , 2,  6, 1},
    {0, 0, "time"            , "time"            , 2,  7, 2},
    {0, 0, "float8"          , "float"           , 3,  8, 1},
    {0, 0, "float4"          , "real"            , 3,  9, 1},
    {0, 0, "numeric"         , "numeric"         , 4, 10, 3},
    {0, 1, "money"           , "money"           , 4, 11, 1},
    {0, 1, "smallmoney"      , "smallmoney"      , 4, 12, 1},
    {0, 0, "int8"            , "bigint"          , 4, 13, 1},
    {0, 0, "int4"            , "int"             , 4, 14, 1},
    {0, 0, "int2"            , "smallint"        , 4, 15, 1},
    {0, 1, "tinyint"         , "tinyint"         , 4, 16, 1},
    {0, 1, "bit"             , "bit"             , 4, 17, 1},
    {0, 1, "nvarchar"        , "nvarchar"        , 5, 18, 5},
    {0, 1, "nchar"           , "nchar"           , 5, 19, 5},
    {0, 1, "varchar"         , "varchar"         , 5, 20, 5},
    {0, 0, "bpchar"          , "char"            , 5, 21, 5},
    {0, 1, "varbinary"       , "varbinary"       , 6, 22, 3},
    {0, 1, "binary"          , "binary"          , 6, 23, 3},
    {0, 1, "uniqueidentifier", "uniqueidentifier", 7, 24, 1}
};

/* Hash tables to help backward searching (from OID to Persist ID) */
HTAB *ht_oid2typecode = NULL;

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
    HASHCTL hashCtl;
    Oid sys_nspoid;
    Oid nspoid;
    ht_oid2typecode_entry_t *entry;

    if (TransMemoryContext == NULL)  /* initialize memory context */
    {
        TransMemoryContext =
            AllocSetContextCreateInternal(NULL,
                                          "SQL Variant Memory Context",
                                          ALLOCSET_DEFAULT_SIZES);
    }

    if (ht_oid2typecode == NULL) /* create hash table */
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

    sys_nspoid = get_namespace_oid("sys", false);
    /* retrieve oid and setup hashtable*/
    for (int i=0; i<TOTAL_TYPECODE_COUNT; i++)
    {
        nspoid = type_infos[i].nsp_is_sys ? sys_nspoid : PG_CATALOG_NAMESPACE;
        type_infos[i].oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
                                            CStringGetDatum(type_infos[i].pg_typname), ObjectIdGetDatum(nspoid));
        if (OidIsValid(type_infos[i].oid))
        {
            entry = hash_search(ht_oid2typecode, &type_infos[i].oid, HASH_ENTER, NULL);
            entry->persist_id = i;
        }
    }

    PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(typecode_list);

Datum
typecode_list(PG_FUNCTION_ARGS)
{
    ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
    TupleDesc tupdesc;
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

Oid get_type_oid(int type_code)
{
	return type_infos[type_code].oid;
}

Oid tsql_bpchar_oid = InvalidOid;
Oid tsql_nchar_oid = InvalidOid;
Oid tsql_varchar_oid = InvalidOid;
Oid tsql_nvarchar_oid = InvalidOid;
Oid tsql_ntext_oid = InvalidOid;
Oid tsql_image_oid = InvalidOid;
Oid tsql_binary_oid = InvalidOid;
Oid tsql_varbinary_oid = InvalidOid;

Oid
lookup_tsql_datatype_oid(const char *typename)
{
	Oid nspoid;
	Oid typoid;

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
is_tsql_varbinary_datatype(Oid oid)
{
	if (tsql_varbinary_oid == InvalidOid)
		tsql_varbinary_oid = lookup_tsql_datatype_oid("bbf_varbinary");
	return tsql_varbinary_oid == oid;
}
