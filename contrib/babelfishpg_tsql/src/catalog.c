#include "postgres.h"
#include "access/htup_details.h"
#include "access/heapam.h"
#include "access/genam.h"
#include "access/skey.h"
#include "access/stratnum.h"
#include "access/table.h"
#include "catalog/catalog.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_authid.h"
#include "catalog/namespace.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/tuplestore.h"
#include "utils/rel.h"
#include "utils/timestamp.h"
#include "nodes/execnodes.h"
#include "catalog.h"
#include "hooks.h"
#include "rolecmds.h"

/*****************************************
 *			SYS schema
 *****************************************/
Oid sys_schema_oid = InvalidOid;

/*****************************************
 *			SYSDATABASES
 *****************************************/
Oid sysdatabases_oid = InvalidOid;
Oid sysdatabaese_idx_oid_oid = InvalidOid;
Oid sysdatabaese_idx_name_oid = InvalidOid;

/*****************************************
 *			NAMESPACE_EXT
 *****************************************/
Oid namespace_ext_oid = InvalidOid;
Oid namespace_ext_idx_oid_oid = InvalidOid;
int namespace_ext_num_cols = 4;

/*****************************************
 *			LOGIN EXT
 *****************************************/
Oid			bbf_authid_login_ext_oid;
Oid			bbf_authid_login_ext_idx_oid;

/*****************************************
 * 			Catalog General
 *****************************************/

static bool tsql_syscache_inited = false;

static struct cachedesc my_cacheinfo[] = {
     {-1,       /* SYSDATABASEOID */ 
          -1,
          1,
          {
              Anum_sysdatabaese_oid,
              0,
              0,
              0
          },
          16
     },
     {-1,       /* SYSDATABASENAME */ 
          -1,
          1,
          {
              Anum_sysdatabaese_name,
              0,
              0,
              0
          },
          16
      }
};

PG_FUNCTION_INFO_V1(init_catalog);
Datum init_catalog(PG_FUNCTION_ARGS)
{
	/* sys schema */
	sys_schema_oid = get_namespace_oid("sys", false);

	/* sysdatabases */
	sysdatabases_oid = get_relname_relid(SYSDATABASES_TABLE_NAME, sys_schema_oid);
	sysdatabaese_idx_name_oid = get_relname_relid(SYSDATABASES_PK_NAME, sys_schema_oid);
	sysdatabaese_idx_oid_oid = get_relname_relid(SYSDATABASES_OID_IDX_NAME, sys_schema_oid);

	/* namespace_ext */
	namespace_ext_oid = get_relname_relid(NAMESPACE_EXT_TABLE_NAME, sys_schema_oid);
	namespace_ext_idx_oid_oid = get_relname_relid(NAMESAPCE_EXT_PK_NAME, sys_schema_oid);

	/* syscache info */
	my_cacheinfo[0].reloid = sysdatabases_oid;
	my_cacheinfo[0].indoid = sysdatabaese_idx_oid_oid;
	my_cacheinfo[1].reloid = sysdatabases_oid;
	my_cacheinfo[1].indoid = sysdatabaese_idx_name_oid;

	/* login ext */
	bbf_authid_login_ext_oid = get_relname_relid(BBF_AUTHID_LOGIN_EXT_TABLE_NAME,
												 sys_schema_oid);
	bbf_authid_login_ext_idx_oid = get_relname_relid(BBF_AUTHID_LOGIN_EXT_IDX_NAME,
													 sys_schema_oid);
	if (sysdatabases_oid != InvalidOid)
		initTsqlSyscache();

	PG_RETURN_INT32(0);
}

void initTsqlSyscache() {
	Assert(my_cacheinfo[0].reloid != -1);
	/* Initialize info for catcache */
	if (!tsql_syscache_inited) {
		InitExtensionCatalogCache(my_cacheinfo, SYSDATABASEOID, 2);
		tsql_syscache_inited = true;
	}
}

/*****************************************
 * 			Catalog Hooks
 *****************************************/

bool 
IsPLtsqlExtendedCatalog(Oid relationId)
{
	if (relationId == sysdatabases_oid)
		return true;
	if (PrevIsExtendedCatalogHook)
		return (*PrevIsExtendedCatalogHook)(relationId);
	return false;
}

/*****************************************
 *			SYSDATABASES
 *****************************************/
int16 get_db_id(const char *dbname)
{
	int16				db_id = 0;
	HeapTuple 			tuple;
	Form_sysdatabases 	sysdb;
	Relation			rel;
	ScanKeyData			scanKey;
	SysScanDesc			scan;

	/* 
	 * TODO: BABEL-2578: invalidate non-pg_catalog tuples properly in syscache
	 * so we can use syscache here.
	 */
	rel = table_open(sysdatabases_oid, AccessShareLock);

	ScanKeyInit(&scanKey,
				Anum_sysdatabaese_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(dbname));

	scan = systable_beginscan(rel, sysdatabaese_idx_name_oid, true,
				NULL, 1, &scanKey);
	tuple = systable_getnext(scan);

	if (HeapTupleIsValid(tuple))
	{
		sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
		db_id = sysdb->dbid;
	}

	systable_endscan(scan);
	table_close(rel, NoLock);

	return db_id;
}

char *get_db_name(int16 dbid)
{
	HeapTuple 			tuple;
	Datum               name_datum;
	char				*name = NULL;
	bool 				isNull;

	/* 
	 * TODO: BABEL-2578: invalidate non-pg_catalog tuples properly in syscache
	 * so we can use syscache here.
	 */
	Relation            rel;
	ScanKeyData			scanKey;
	SysScanDesc         scan;

	rel = table_open(sysdatabases_oid, AccessShareLock);

	ScanKeyInit(&scanKey,
				Anum_sysdatabaese_oid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	scan = systable_beginscan(rel, sysdatabaese_idx_oid_oid, true,
				NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (HeapTupleIsValid(tuple))
	{
		name_datum = heap_getattr(tuple, Anum_sysdatabaese_name, rel->rd_att, &isNull);
		name = TextDatumGetCString(name_datum);
	}

	systable_endscan(scan);
	table_close(rel, NoLock);

	return name;
}

const char *get_one_user_db_name(void)
{
	HeapTuple 		tuple;
	TableScanDesc 	scan;
	Relation		rel;
	char 			*user_db_name = NULL;
	bool			is_null;

	rel = table_open(sysdatabases_oid, AccessShareLock);
	scan = table_beginscan_catalog(rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple)) 
	{
		char *db_name;

		Datum name = heap_getattr(tuple, Anum_sysdatabaese_name,
								  rel->rd_att, &is_null);
		db_name = TextDatumGetCString(name);

		if ((strncmp(db_name, "master", 6) != 0) && (strncmp(db_name, "tempdb", 6) != 0))
		{
			user_db_name = db_name;
			break;
		}
		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	
	table_endscan(scan);
	table_close(rel, AccessShareLock);

	return user_db_name;
}


PG_FUNCTION_INFO_V1(babelfish_helpdb);

Datum
babelfish_helpdb(PG_FUNCTION_ARGS)
{
    ReturnSetInfo 		*rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	char 				*dbname;
	ScanKeyData 		scanKey;
    TupleDesc 			tupdesc;
    Tuplestorestate 	*tupstore;
	MemoryContext 		per_query_ctx;
    MemoryContext 		oldcontext;
	Relation			rel;
	SysScanDesc 		scan;
	HeapTuple 			tuple;
	Form_sysdatabases 	sysdb;
	Oid                 datetime_output_func;
	bool				typIsVarlena;
	Oid 				datetime_type;
    Oid 				sys_nspoid = get_namespace_oid("sys", false);


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
    TupleDescInitEntry(tupdesc, (AttrNumber) 1, "name",
                       VARCHAROID, 128, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 2, "db_size",
                       VARCHAROID, 13, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 3, "owner",
                       VARCHAROID, 128, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 4, "dbid",
                       INT4OID, -1, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 5, "created",
                       VARCHAROID, 11, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 6, "status",
                       VARCHAROID, 600, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 7, "compatibility_level",
                       INT2OID, -1, 0);

    tupstore =
        tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
                              false, 1024);
    /* generate junk in short-term context */
    MemoryContextSwitchTo(oldcontext);

	rel = table_open(sysdatabases_oid, AccessShareLock);

	if (PG_NARGS() > 0)
	{
		dbname = TextDatumGetCString(PG_GETARG_DATUM(0));
		if (!DbidIsValid(get_db_id(dbname)))
			ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("The database '%s' does not exist. Supply a valid database name. To see available databases, use sys.databases.", dbname)));
		ScanKeyInit(&scanKey,
			Anum_sysdatabaese_name,
			BTEqualStrategyNumber, F_TEXTEQ,
			CStringGetTextDatum(dbname));
		scan = systable_beginscan(rel, sysdatabaese_idx_name_oid, true,
								NULL, 1, &scanKey);
	}
	else
	{
		scan = systable_beginscan(rel, 0, false, NULL, 0, NULL);
	}

	datetime_type = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
										CStringGetDatum("datetime"), ObjectIdGetDatum(sys_nspoid));

	getTypeOutputInfo(datetime_type, &datetime_output_func, &typIsVarlena);

    /* scan all the variables in top estate */
	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
        Datum		values[7];
        bool		nulls[7];
		char 		*db_name_entry;
		Timestamp 	tmstmp;
		char 		*tmstmp_str;
		bool		isNull;

		sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));

        MemSet(nulls, 0, sizeof(nulls));

		db_name_entry = TextDatumGetCString(heap_getattr(tuple, Anum_sysdatabaese_name,
                                RelationGetDescr(rel), &isNull));

		values[0] = CStringGetTextDatum(db_name_entry);

        nulls[1] = 1;

		values[2] = CStringGetTextDatum(NameStr(sysdb->owner));

		if (strcmp(db_name_entry, "master") == 0)
			values[3] = 1;
		else if (strcmp(db_name_entry, "tempdb") == 0)
			values[3] = 2;
		else
        	values[3] = sysdb->dbid;

		tmstmp = DatumGetTimestamp(heap_getattr(tuple, Anum_sysdatabaese_crdate,
                                RelationGetDescr(rel), &isNull));

		tmstmp_str = OidOutputFunctionCall(datetime_output_func, tmstmp);
		values[4] = CStringGetTextDatum(tmstmp_str);

        nulls[5] = 1;
		nulls[6] = 1;

        tuplestore_putvalues(tupstore, tupdesc, values, nulls);
    }
	systable_endscan(scan);
	table_close(rel, AccessShareLock);
    /* clean up and return the tuplestore */
    tuplestore_donestoring(tupstore);

    rsinfo->returnMode = SFRM_Materialize;
    rsinfo->setResult = tupstore;
    rsinfo->setDesc = tupdesc;

    PG_RETURN_NULL();
}

/*****************************************
 *			NAMESPACE_EXT
 *****************************************/
const char *
get_logical_schema_name(const char *physical_schema_name, bool missingOk)
{
	Relation 	rel;
	HeapTuple	tuple;
	ScanKeyData scanKey;
	SysScanDesc scan;
	Datum		datum;
	const char  *logical_name;
	TupleDesc	dsc;
	bool 		isnull;

	if (get_namespace_oid(physical_schema_name, false) == InvalidOid)
		return NULL;

	rel = table_open(namespace_ext_oid, AccessShareLock);
	dsc = RelationGetDescr(rel);

	ScanKeyInit(&scanKey,
				Anum_namespace_ext_namespace,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(physical_schema_name));

	scan = systable_beginscan(rel, namespace_ext_idx_oid_oid, true,
							  NULL, 1, &scanKey);

	tuple = systable_getnext(scan);
	if (!HeapTupleIsValid(tuple))
	{
		systable_endscan(scan);
		table_close(rel, AccessShareLock);
		if (!missingOk)
			ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Could find logical schema name for: \"%s\"", physical_schema_name)));
		return NULL;
	}
	datum = heap_getattr(tuple, Anum_namespace_ext_orig_name, dsc, &isnull);
	logical_name = pstrdup(TextDatumGetCString(datum));

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return logical_name;
}

/*****************************************
 *			LOGIN EXT
 *****************************************/

bool
is_login(Oid role_oid)
{
	Relation	relation;
	bool		is_login = true;
	ScanKeyData	scanKey;
	SysScanDesc	scan;
	HeapTuple	tuple;
	HeapTuple	authtuple;
	NameData	rolname;

	authtuple = SearchSysCache1(AUTHOID, ObjectIdGetDatum(role_oid));
	if (!HeapTupleIsValid(authtuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				errmsg("role with OID %u does not exist", role_oid)));
	rolname = ((Form_pg_authid) GETSTRUCT(authtuple))->rolname;

	relation = table_open(get_authid_login_ext_oid(), AccessShareLock);

	ScanKeyInit(&scanKey,
				Anum_bbf_authid_login_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&rolname));

	scan = systable_beginscan(relation,
							  get_authid_login_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple))
		is_login = false;

	systable_endscan(scan);
	table_close(relation, AccessShareLock);

	ReleaseSysCache(authtuple);

	return is_login;
}

PG_FUNCTION_INFO_V1(bbf_get_login_default_db);
Datum bbf_get_login_default_db(PG_FUNCTION_ARGS)
{
	char *login_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	char *ret;

	ret = get_login_default_db(login_name);

	if (!ret)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(CStringGetTextDatum(ret));
}

char *
get_login_default_db(char *login_name)
{
	Relation				bbf_authid_login_ext_rel;
	Relation				sysdatabase_rel;
	TupleDesc				dsc;
	HeapTuple				tuple;
	ScanKeyData				scanKey;
	SysScanDesc				scan;
	Datum					datum;
	bool					isnull;
	char					*default_db_name;

	/* Fetch the relation */
	bbf_authid_login_ext_rel = table_open(get_authid_login_ext_oid(), AccessShareLock);
	dsc = RelationGetDescr(bbf_authid_login_ext_rel);

	/* Search and obtain the tuple on the role name*/
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_login_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(login_name));

	scan = systable_beginscan(bbf_authid_login_ext_rel,
							  get_authid_login_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);
	if (!HeapTupleIsValid(tuple))
	{
		systable_endscan(scan);
		table_close(bbf_authid_login_ext_rel, AccessShareLock);
		return NULL;
	}

	datum = heap_getattr(tuple, LOGIN_EXT_DEFAULT_DATABASE_NAME+1, dsc, &isnull);
	default_db_name = pstrdup(TextDatumGetCString(datum));

	systable_endscan(scan);
	table_close(bbf_authid_login_ext_rel, AccessShareLock);

	sysdatabase_rel = table_open(sysdatabases_oid, AccessShareLock);

	ScanKeyInit(&scanKey,
				Anum_sysdatabaese_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(default_db_name));

	scan = systable_beginscan(sysdatabase_rel, sysdatabaese_idx_name_oid, true,
			NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	systable_endscan(scan);
	table_close(sysdatabase_rel, AccessShareLock);

	if (!HeapTupleIsValid(tuple))
		return NULL;

	return default_db_name;
}

Oid
get_authid_login_ext_oid()
{
	if (!OidIsValid(bbf_authid_login_ext_oid))
		bbf_authid_login_ext_oid = get_relname_relid(BBF_AUTHID_LOGIN_EXT_TABLE_NAME,
													 get_namespace_oid("sys", false));

	return bbf_authid_login_ext_oid;
}

Oid
get_authid_login_ext_idx_oid(void)
{
	if (!OidIsValid(bbf_authid_login_ext_idx_oid))
		bbf_authid_login_ext_idx_oid = get_relname_relid(BBF_AUTHID_LOGIN_EXT_IDX_NAME,
														 get_namespace_oid("sys", false));

	return bbf_authid_login_ext_idx_oid;
}

PG_FUNCTION_INFO_V1(babelfish_inconsistent_metadata);

Datum
babelfish_inconsistent_metadata(PG_FUNCTION_ARGS)
{
    ReturnSetInfo 		*rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	MemoryContext 		per_query_ctx;
	MemoryContext 		oldcontext;
    TupleDesc 			tupdesc;
    Tuplestorestate 	*tupstore;

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
    tupdesc = CreateTemplateTupleDesc(4);
    TupleDescInitEntry(tupdesc, (AttrNumber) 1, "object_type",
                       VARCHAROID, 32, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 2, "schema_name",
                       VARCHAROID, 128, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 3, "object_name",
                       VARCHAROID, 128, 0);
    TupleDescInitEntry(tupdesc, (AttrNumber) 4, "detail",
                       TEXTOID, -1, 0);
    tupstore =
        tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
                              false, 1024);

    /* generate junk in short-term context */
    MemoryContextSwitchTo(oldcontext);

    /* clean up and return the tuplestore */
    tuplestore_donestoring(tupstore);

    rsinfo->returnMode = SFRM_Materialize;
    rsinfo->setResult = tupstore;
    rsinfo->setDesc = tupdesc;

    PG_RETURN_NULL();
}
