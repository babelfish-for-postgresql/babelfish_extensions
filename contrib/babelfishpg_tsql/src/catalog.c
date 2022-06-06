#include "postgres.h"
#include "miscadmin.h"
#include "access/htup_details.h"
#include "access/heapam.h"
#include "access/genam.h"
#include "access/skey.h"
#include "access/stratnum.h"
#include "access/table.h"
#include "catalog/catalog.h"
#include "catalog/indexing.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_authid.h"
#include "catalog/namespace.h"
#include "parser/scansup.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/tuplestore.h"
#include "utils/rel.h"
#include "utils/timestamp.h"
#include "nodes/execnodes.h"
#include "catalog.h"
#include "guc.h"
#include "hooks.h"
#include "multidb.h"
#include "rolecmds.h"
#include "pltsql.h"

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
 *			USER EXT
 *****************************************/
Oid			bbf_authid_user_ext_oid;
Oid			bbf_authid_user_ext_idx_oid;

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
	/* user ext */
	bbf_authid_user_ext_oid = get_relname_relid(BBF_AUTHID_USER_EXT_TABLE_NAME,
												sys_schema_oid);
	bbf_authid_user_ext_idx_oid = get_relname_relid(BBF_AUTHID_USER_EXT_IDX_NAME,
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

      tuple = SearchSysCache1(SYSDATABASENAME, CStringGetTextDatum(dbname));

      if (!HeapTupleIsValid(tuple))
              return InvalidDbid;

      sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
      db_id = sysdb->dbid;
      ReleaseSysCache(tuple);

	return db_id;
}

char *get_db_name(int16 dbid)
{
	HeapTuple 			tuple;
	Datum               name_datum;
	char				*name = NULL;
	bool 				isNull;

      tuple  = SearchSysCache1(SYSDATABASEOID, Int16GetDatum(dbid));

      if (!HeapTupleIsValid(tuple))
              return NULL;

      name_datum = SysCacheGetAttr(SYSDATABASEOID, tuple, Anum_sysdatabaese_name, &isNull);
      name = TextDatumGetCString(name_datum);
      ReleaseSysCache(tuple);

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

		// check that db_name is not "master", "tempdb", or "msdb"
		if ((strlen(db_name) != 6 || (strncmp(db_name, "master", 6) != 0)) &&
			(strlen(db_name) != 6 || (strncmp(db_name, "tempdb", 6) != 0)) &&
			(strlen(db_name) != 4 || (strncmp(db_name, "msdb", 4) != 0)))
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

		if (strlen(db_name_entry) == 6 && (strncmp(db_name_entry, "master", 6) == 0))
			values[3] = 1;
		else if (strlen(db_name_entry) == 6 && (strncmp(db_name_entry, "tempdb", 6) == 0))
			values[3] = 2;
		else if (strlen(db_name_entry) == 4 && (strncmp(db_name_entry, "msdb", 4) == 0))
			values[3] = 4;
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

bool
is_login_name(char *rolname)
{
	Relation	relation;
	bool		is_login = true;
	ScanKeyData	scanKey;
	SysScanDesc	scan;
	HeapTuple	tuple;
	NameData	*login;

	relation = table_open(get_authid_login_ext_oid(), AccessShareLock);

	login = (NameData *) palloc0(NAMEDATALEN);
	snprintf(login->data, NAMEDATALEN, "%s", rolname);
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_login_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(login));

	scan = systable_beginscan(relation,
							  get_authid_login_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple))
		is_login = false;

	systable_endscan(scan);
	table_close(relation, AccessShareLock);

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

      tuple = SearchSysCache1(SYSDATABASENAME, CStringGetTextDatum(default_db_name));

	if (!HeapTupleIsValid(tuple))
		return NULL;
      ReleaseSysCache(tuple);

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

/*****************************************
 *			USER EXT
 *****************************************/

bool
is_user(Oid role_oid)
{
	Relation	relation;
	bool		is_user = true;
	ScanKeyData	scanKey;
	SysScanDesc	scan;
	HeapTuple	tuple;
	HeapTuple	authtuple;
	NameData	rolname;
	BpChar		type;
	char		*type_str = "";

	authtuple = SearchSysCache1(AUTHOID, ObjectIdGetDatum(role_oid));
	if (!HeapTupleIsValid(authtuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				errmsg("role with OID %u does not exist", role_oid)));
	rolname = ((Form_pg_authid) GETSTRUCT(authtuple))->rolname;

	relation = table_open(get_authid_user_ext_oid(), AccessShareLock);

	ScanKeyInit(&scanKey,
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&rolname));

	scan = systable_beginscan(relation,
							  get_authid_user_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple))
		is_user = false;

	type = ((Form_authid_user_ext) GETSTRUCT(tuple))->type;
	type_str = bpchar_to_cstring(&type);

	if (strcmp(type_str, "S") != 0)
		is_user = false;

	systable_endscan(scan);
	table_close(relation, AccessShareLock);

	ReleaseSysCache(authtuple);

	return is_user;
}

bool
is_role(Oid role_oid)
{
	Relation	relation;
	bool		is_role = true;
	ScanKeyData	scanKey;
	SysScanDesc	scan;
	HeapTuple	tuple;
	HeapTuple	authtuple;
	NameData	rolname;
	BpChar 		type;
	char		*type_str = "";

	authtuple = SearchSysCache1(AUTHOID, ObjectIdGetDatum(role_oid));
	if (!HeapTupleIsValid(authtuple))
	ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_OBJECT),
			errmsg("role with OID %u does not exist", role_oid)));
	rolname = ((Form_pg_authid) GETSTRUCT(authtuple))->rolname;

	relation = table_open(get_authid_user_ext_oid(), AccessShareLock);

	ScanKeyInit(&scanKey,
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&rolname));

	scan = systable_beginscan(relation,
							  get_authid_user_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple))
		is_role = false;
	else
	{
		type = ((Form_authid_user_ext) GETSTRUCT(tuple))->type;
		type_str = bpchar_to_cstring(&type);

		if (strcmp(type_str, "R") != 0)
		is_role = false;
	}

	systable_endscan(scan);
	table_close(relation, AccessShareLock);

	ReleaseSysCache(authtuple);

	return is_role;
}

Oid
get_authid_user_ext_oid()
{
	if (!OidIsValid(bbf_authid_user_ext_oid))
		bbf_authid_user_ext_oid = get_relname_relid(BBF_AUTHID_USER_EXT_TABLE_NAME,
													get_namespace_oid("sys", false));

	return bbf_authid_user_ext_oid;
}

Oid
get_authid_user_ext_idx_oid(void)
{
	if (!OidIsValid(bbf_authid_user_ext_idx_oid))
		bbf_authid_user_ext_idx_oid = get_relname_relid(BBF_AUTHID_USER_EXT_IDX_NAME,
														get_namespace_oid("sys", false));

	return bbf_authid_user_ext_idx_oid;
}

char *
get_authid_user_ext_physical_name(const char *db_name, const char *login)
{
	Relation		bbf_authid_user_ext_rel;
	HeapTuple		tuple_user_ext;
	ScanKeyData		key[2];
	TableScanDesc	scan;
	char			*user_name = NULL;
	NameData		*login_name;

	if (!db_name || !login)
		return NULL;

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	login_name = (NameData *) palloc0(NAMEDATALEN);
	snprintf(login_name->data, NAMEDATALEN, "%s", login);
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_login_name,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(login_name));
	ScanKeyInit(&key[1],
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(db_name));

	scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 2, key);

	tuple_user_ext = heap_getnext(scan, ForwardScanDirection);
	if (HeapTupleIsValid(tuple_user_ext))
	{
		Form_authid_user_ext userform;

		userform = (Form_authid_user_ext) GETSTRUCT(tuple_user_ext);
		user_name = pstrdup(NameStr(userform->rolname));
	}

	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	return user_name;
}

char *
get_authid_user_ext_schema_name(const char *db_name, const char *user)
{
	Relation		bbf_authid_user_ext_rel;
	HeapTuple		tuple_user_ext;
	ScanKeyData		key[2];
	TableScanDesc	scan;
	char			*schema_name = NULL;
	NameData		*user_name;

	if (!db_name || !user)
		return NULL;

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	user_name = (NameData *) palloc0(NAMEDATALEN);
	snprintf(user_name->data, NAMEDATALEN, "%s", user);
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(user_name));
	ScanKeyInit(&key[1],
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(db_name));

	scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 2, key);

	tuple_user_ext = heap_getnext(scan, ForwardScanDirection);
	if (HeapTupleIsValid(tuple_user_ext))
	{
		Datum	datum;
		bool	is_null;

		datum = heap_getattr(tuple_user_ext,
							 Anum_bbf_authid_user_ext_default_schema_name,
							 bbf_authid_user_ext_rel->rd_att,
							 &is_null);
		schema_name = pstrdup(TextDatumGetCString(datum));
	}

	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	return schema_name;
}

List *
get_authid_user_ext_db_users(const char *db_name)
{
	Relation		bbf_authid_user_ext_rel;
	HeapTuple		tuple;
	ScanKeyData		key;
	TableScanDesc	scan;
	List			*db_users_list = NIL;

	if (!db_name)
		return NULL;

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	ScanKeyInit(&key,
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(db_name));

	scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 1, &key);

	tuple = heap_getnext(scan, ForwardScanDirection);
	while (HeapTupleIsValid(tuple))
	{
		char *user_name;
		Form_authid_user_ext userform;

		userform = (Form_authid_user_ext) GETSTRUCT(tuple);
		user_name = pstrdup(NameStr(userform->rolname));
		db_users_list = lappend(db_users_list, user_name);
		tuple = heap_getnext(scan, ForwardScanDirection);
	}

	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	return db_users_list;
}

/*****************************************
 * 			Metadata Check
 * ---------------------------------------
 * Babelfish catalogs should comply with
 * PG catalogs. We defined some metadata
 * rules to check the metadata integrity.
 *****************************************/

/* 
 * This parameter controls whether the metadata check would stop at the first
 * detected error. 
 */
bool stop_at_first_error = false;
/*
 * This parameter controls whether the function will return consistent rule list
 * or detected inconsistency.
 */
bool return_consistency = false;

/* Core function declaration */
static void metadata_inconsistency_check(Tuplestorestate *res_tupstore, TupleDesc res_tupdesc);
/* Value function declaration */
static Datum get_master(HeapTuple tuple, TupleDesc dsc);
static Datum get_tempdb(HeapTuple tuple, TupleDesc dsc);
static Datum get_msdb(HeapTuple tuple, TupleDesc dsc);
static Datum get_cur_rolname(HeapTuple tuple, TupleDesc dsc);
static Datum get_master_dbo(HeapTuple tuple, TupleDesc dsc);
static Datum get_tempdb_dbo(HeapTuple tuple, TupleDesc dsc);
static Datum get_msdb_dbo(HeapTuple tuple, TupleDesc dsc);
static Datum get_dbo(HeapTuple tuple, TupleDesc dsc);
static Datum get_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_master_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_master_guest(HeapTuple tuple, TupleDesc dsc);
static Datum get_tempdb_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_tempdb_guest(HeapTuple tuple, TupleDesc dsc);
static Datum get_msdb_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_msdb_guest(HeapTuple tuple, TupleDesc dsc);
static Datum get_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_name_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_name_dbo(HeapTuple tuple, TupleDesc dsc);
static Datum get_nspname(HeapTuple tuple, TupleDesc dsc);
static Datum get_login_rolname(HeapTuple tuple, TupleDesc dsc);
static Datum get_default_database_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_user_rolname(HeapTuple tuple, TupleDesc dsc);
static Datum get_database_name(HeapTuple tuple, TupleDesc dsc);
/* Condition function declaration */
static bool is_multidb(void);
static bool is_singledb_exists_userdb(void);
/* Rule validation function declaration */
static bool check_exist(void *arg, HeapTuple tuple);
static bool check_rules(Rule rules[], size_t num_rules, HeapTuple tuple, TupleDesc dsc,
						Tuplestorestate *res_tupstore, TupleDesc res_tupdesc);
static bool check_must_match_rules(Rule rules[], size_t num_rules, Oid catalog_oid, 
								   Tuplestorestate *res_tupstore, TupleDesc res_tupdesc);
/* Helper function declaration */
static void update_report(Rule *rule, Tuplestorestate *res_tupstore, TupleDesc res_tupdesc);
static void init_catalog_data(void);
static void get_catalog_info(Rule *rule);

/*****************************************
 * 			Catalog Extra Info
 * ---------------------------------------
 * MUST also edit init_catalog_data() when 
 * editing the listed catalogs here.
 *****************************************/
RelData catalog_data[] = 
{
	{"babelfish_sysdatabases", InvalidOid, InvalidOid, InvalidOid, Anum_sysdatabaese_name, F_TEXTEQ},
	{"babelfish_namespace_ext", InvalidOid, InvalidOid, InvalidOid, Anum_namespace_ext_namespace, F_NAMEEQ},
	{"babelfish_authid_login_ext", InvalidOid, InvalidOid, InvalidOid, Anum_bbf_authid_login_ext_rolname, F_NAMEEQ},
	{"babelfish_authid_user_ext", InvalidOid, InvalidOid, InvalidOid, Anum_bbf_authid_user_ext_rolname, F_NAMEEQ},
	{"pg_namespace", InvalidOid, InvalidOid, InvalidOid, Anum_pg_namespace_nspname, F_NAMEEQ},
	{"pg_authid", InvalidOid, InvalidOid, InvalidOid, Anum_pg_authid_rolname, F_NAMEEQ}
};
	
/*****************************************
 * 			Rule Definitions
 * ---------------------------------------
 * 1. Must have rule
 *		A.a must have some value V
 * 2. Must match rule
 *		B->A, if we have a value V2 in B.b, 
 *		then A.a should have value V1
 *****************************************/

/* Must have rules */
Rule must_have_rules[] =
{
	{"master must exist in babelfish_sysdatabases",
	 "babelfish_sysdatabases", "name", NULL, get_master, NULL, check_exist, NULL},
	{"tempdb must exist in babelfish_sysdatabases",
	 "babelfish_sysdatabases", "name", NULL, get_tempdb, NULL, check_exist, NULL},
	{"msdb must exist in babelfish_sysdatabases",
	 "babelfish_sysdatabases", "name", NULL, get_msdb, NULL, check_exist, NULL},
	{"Current role name must exist in babelfish_authid_login_ext",
	 "babelfish_authid_login_ext", "rolname", NULL, get_cur_rolname, NULL, check_exist, NULL},
	{"master_dbo must exist in babelfish_namespace_ext",
	 "babelfish_namespace_ext", "nspname", NULL, get_master_dbo, NULL, check_exist, NULL},
	{"tempdb_dbo must exist in babelfish_namespace_ext",
	 "babelfish_namespace_ext", "nspname", NULL, get_tempdb_dbo, NULL, check_exist, NULL},
	{"msdb_dbo must exist in babelfish_namespace_ext",
	 "babelfish_namespace_ext", "nspname", NULL, get_msdb_dbo, NULL, check_exist, NULL},
	{"In single-db mode, if user db exists, dbo must exist in babelfish_namespace_ext",
	 "babelfish_namespace_ext", "nspname", NULL, get_dbo, is_singledb_exists_userdb, check_exist, NULL},
	{"In single-db mode, if user db exists, db_owner must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_db_owner, is_singledb_exists_userdb, check_exist, NULL},
	{"In single-db mode, if user db exists, dbo must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_dbo, is_singledb_exists_userdb, check_exist, NULL},
	{"master_db_owner must exist in babelfish_authid_user_ext", 
	 "babelfish_authid_user_ext", "rolname", NULL, get_master_db_owner, NULL, check_exist, NULL},
	{"master_dbo must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_master_dbo, NULL, check_exist, NULL},
	{"master_guest must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_master_guest, NULL, check_exist, NULL},
	{"tempdb_db_owner must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_tempdb_db_owner, NULL, check_exist, NULL},
	{"tempdb_dbo must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_tempdb_dbo, NULL, check_exist, NULL},
	{"tempdb_guest must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_tempdb_guest, NULL, check_exist, NULL},
	{"msdb_db_owner must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_msdb_db_owner, NULL, check_exist, NULL},
	{"msdb_dbo must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_msdb_dbo, NULL, check_exist, NULL},
	{"msdb_guest must exist in babelfish_authid_user_ext",
	 "babelfish_authid_user_ext", "rolname", NULL, get_msdb_guest, NULL, check_exist, NULL}
};

/* Must match rules, MUST comply with metadata_inconsistency_check() */
/* babelfish_sysdatabases */
Rule must_match_rules_sysdb[] =
{
	{"<owner> in babelfish_sysdatabases must also exist in babelfish_authid_login_ext", 
	 "babelfish_authid_login_ext", "rolname", NULL, get_owner, NULL, check_exist, NULL},
	{"In multi-db mode, for each <name> in babelfish_sysdatabases, <name>_db_owner must also exist in pg_authid",
	 "pg_authid", "rolname", NULL, get_name_db_owner, is_multidb, check_exist, NULL},
	{"In multi-db mode, for each <name> in babelfish_sysdatabases, <name>_dbo must also exist in pg_authid",
	 "pg_authid", "rolname", NULL, get_name_dbo, is_multidb, check_exist, NULL},
	{"In multi-db mode, for each <name> in babelfish_sysdatabases, <name>_dbo must also exist in babelfish_namespace_ext",
	 "babelfish_namespace_ext", "nspname", NULL, get_name_dbo, is_multidb, check_exist, NULL}
};

/* babelfish_namespace_ext */
Rule must_match_rules_nsp[] = 
{
	{"<nspname> in babelfish_namespace_ext must also exist in pg_namespace",
	 "pg_namespace", "nspname", NULL, get_nspname, NULL, check_exist, NULL}
};

/* babelfish_authid_login_ext */
Rule must_match_rules_login[] = 
{
	{"<rolname> in babelfish_authid_login_ext must also exist in pg_authid",
	 "pg_authid", "rolname", NULL, get_login_rolname, NULL, check_exist, NULL},
	{"<default_database_name> in babelfish_authid_login_ext must also exist in babelfish_sysdatabases",
	 "babelfish_sysdatabases", "name", NULL, get_default_database_name, NULL, check_exist, NULL}
};

/* babelfish_authid_user_ext */
Rule must_match_rules_user[] = 
{
	{"<rolname> in babelfish_authid_user_ext must also exist in pg_authid",
	 "pg_authid", "rolname", NULL, get_user_rolname, NULL, check_exist, NULL},
	{"<database_name> in babelfish_authid_user_ext must also exist in babelfish_sysdatabases",
	 "babelfish_sysdatabases", "name", NULL, get_database_name, NULL, check_exist, NULL}
};
	
/*****************************************
 * 			Core function
 *****************************************/

PG_FUNCTION_INFO_V1(babelfish_inconsistent_metadata);

/*
 * Execute the metadata inconsistency check.
 * Detected metadata inconsistency will be returned as the output of the
 * procedure sys.babelfish_inconsistent_metadata().
 */
Datum
babelfish_inconsistent_metadata(PG_FUNCTION_ARGS)
{
    ReturnSetInfo 		*rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	MemoryContext 		per_query_ctx;
	MemoryContext 		oldcontext;
    TupleDesc 			tupdesc;
    Tuplestorestate 	*tupstore;

	return_consistency = PG_GETARG_BOOL(0);

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
                       JSONBOID, -1, 0);
    tupstore =
        tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
                              false, 1024);

    /* generate junk in short-term context */
    MemoryContextSwitchTo(oldcontext);

	PG_TRY();
	{
		/* Check metadata inconsistency */
		metadata_inconsistency_check(tupstore, tupdesc);

		/* clean up and return the tuplestore */
		tuplestore_donestoring(tupstore);

		rsinfo->returnMode = SFRM_Materialize;
		rsinfo->setResult = tupstore;
		rsinfo->setDesc = tupdesc;

		PG_RETURN_NULL();
	}
	PG_CATCH();
	{
		tuplestore_donestoring(tupstore);
		PG_RE_THROW();
	}
	PG_END_TRY();
}

static void
metadata_inconsistency_check(Tuplestorestate *res_tupstore, TupleDesc res_tupdesc)
{
	size_t num_must_have_rules = sizeof(must_have_rules) / sizeof(must_have_rules[0]);
	size_t num_must_match_rules_sysdb =  sizeof(must_match_rules_sysdb) / sizeof(must_match_rules_sysdb[0]);
	size_t num_must_match_rules_nsp = sizeof(must_match_rules_nsp) / sizeof(must_match_rules_nsp[0]);
	size_t num_must_match_rules_login = sizeof(must_match_rules_login) / sizeof(must_match_rules_login[0]);
	size_t num_must_match_rules_user = sizeof(must_match_rules_user) / sizeof(must_match_rules_user[0]);

	/* Initialize the catalog_data array to fetch catalog info */
	init_catalog_data();

	/* 
	 * If any of the following function call returns false, that means an
	 * inconsistency is detected AND stop_at_first_error is set to true, thus
	 * we should immediately stop checking and output the result
	 */
	if (
		/* Must have rules */
		!(check_rules(must_have_rules, num_must_have_rules, NULL, NULL, res_tupstore, res_tupdesc))
		/* Must match rules, MUST comply with the defined must match rules */
		||
		!(check_must_match_rules(must_match_rules_sysdb, num_must_match_rules_sysdb, 
								 sysdatabases_oid, res_tupstore, res_tupdesc))
		||
		!(check_must_match_rules(must_match_rules_nsp, num_must_match_rules_nsp, 
								 namespace_ext_oid, res_tupstore, res_tupdesc)) 
		||
		!(check_must_match_rules(must_match_rules_login, num_must_match_rules_login,
								 bbf_authid_login_ext_oid, res_tupstore, res_tupdesc))
		||
		!(check_must_match_rules(must_match_rules_user, num_must_match_rules_user,
								 bbf_authid_user_ext_oid, res_tupstore, res_tupdesc))
	)
		return;
}

/* 
 * Check all rules in a rule array.
 * It only returns false when an inconsistency is detected AND
 * stop_at_first_error is set to true.
 * For must have rules, tuple and dsc should be NULL.
 */
static bool
check_rules(Rule rules[], size_t num_rules, HeapTuple tuple, TupleDesc dsc,
			Tuplestorestate *res_tupstore, TupleDesc res_tupdesc)
{
	for (size_t i = 0; i < num_rules; i++)
	{
		Rule *rule = &(rules[i]);

		/* Check the rule's required condition */
		if (rule->func_cond && !(rule->func_cond) ())
			continue;

		/* Read catalog info and store in rule->tbldata */
		get_catalog_info(rule);

		/* Get the tuple description for current catalog */
		if (dsc)
			rule->tupdesc = dsc;

		if (!rule->func_check)
			ereport(ERROR,
					(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					 errmsg("Null check function for rule: \n%s",
							rule->desc)));

		/* When return_consistency=true, update report with passed rules */
		if ((rule->func_check) (rule, tuple))
		{
			if (return_consistency)
				update_report(rule, res_tupstore, res_tupdesc);
		}
		/* When return_consistency=false, update report with inconsistency */
		else if (!return_consistency)
		{
			update_report(rule, res_tupstore, res_tupdesc);
			/* Stop checking if we want to stop at the first error */
			if (stop_at_first_error)
				return false;
		}
	}

	return true;
}

/* 
 * Check a set of must match rules that depend on a certain catalog.
 * It only returns false when an inconsistency is detected AND
 * stop_at_first_error is set to true.
 */
static bool
check_must_match_rules(Rule rules[], size_t num_rules, Oid catalog_oid, 
					   Tuplestorestate *res_tupstore, TupleDesc res_tupdesc)
{
	HeapTuple		tuple;
	TupleDesc		dsc;
	SysScanDesc 	scan;
	Relation		rel;

	/* Rules depending on the catalog */
	rel = table_open(catalog_oid, AccessShareLock);
	dsc = RelationGetDescr(rel);
	scan = systable_beginscan(rel, 0, false, NULL, 0, NULL);
		
	PG_TRY();
	{
		while (HeapTupleIsValid(tuple = systable_getnext(scan)))
		{
			/* Loop through all rules that depend on the catalog */
			if (!check_rules(rules, num_rules, tuple, dsc, res_tupstore, res_tupdesc))
			{
				systable_endscan(scan);
				table_close(rel, AccessShareLock);
				return false;
			}
		}
	}
	PG_FINALLY();
	{
		if (scan)
			  systable_endscan(scan);
		if (rel)
			  table_close(rel, AccessShareLock);
	}
	PG_END_TRY();

	return true;
}

/*****************************************
 * 			Value functions
 *****************************************/

static Datum
get_master(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetTextDatum("master");
}

static Datum
get_tempdb(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetTextDatum("tempdb");
}

static Datum
get_msdb(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetTextDatum("msdb");
}

static Datum
get_cur_rolname(HeapTuple tuple, TupleDesc dsc)
{
	char *rolname = GetUserNameFromId(GetSessionUserId(), false);
	truncate_identifier(rolname, strlen(rolname), false);
	return CStringGetDatum(rolname);
}

static Datum
get_master_dbo(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("master_dbo");
}

static Datum
get_tempdb_dbo(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("tempdb_dbo");
}

static Datum
get_msdb_dbo(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("msdb_dbo");
}

static Datum
get_dbo(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("dbo");
}

static Datum
get_db_owner(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("db_owner");
}

static Datum
get_master_db_owner(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("master_db_owner");
}

static Datum
get_master_guest(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("master_guest");
}

static Datum
get_tempdb_db_owner(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("tempdb_db_owner");
}

static Datum
get_tempdb_guest(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("tempdb_guest");
}

static Datum
get_msdb_db_owner(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("msdb_db_owner");
}

static Datum
get_msdb_guest(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("msdb_guest");
}

static Datum
get_owner(HeapTuple tuple, TupleDesc dsc)
{
	Form_sysdatabases sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
	return NameGetDatum(&(sysdb->owner));
}

static Datum
get_name_db_owner(HeapTuple tuple, TupleDesc dsc)
{
	Form_sysdatabases sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
	const text *name = &(sysdb->name);
	char *name_str = text_to_cstring(name);
	char *name_db_owner = palloc0(MAX_BBF_NAMEDATALEND);

	truncate_identifier(name_str, strlen(name_str), false);
	snprintf(name_db_owner, MAX_BBF_NAMEDATALEND, "%s_db_owner", name_str);
	truncate_identifier(name_db_owner, strlen(name_db_owner), false);
	return CStringGetDatum(name_db_owner);
}

static Datum
get_name_dbo(HeapTuple tuple, TupleDesc dsc)
{
	Form_sysdatabases sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
	const text *name = &(sysdb->name);
	char *name_str = text_to_cstring(name);
	char *name_dbo = palloc0(MAX_BBF_NAMEDATALEND);

	truncate_identifier(name_str, strlen(name_str), false);
	snprintf(name_dbo, MAX_BBF_NAMEDATALEND, "%s_dbo", name_str);
	truncate_identifier(name_dbo, strlen(name_dbo), false);
	return CStringGetDatum(name_dbo);
}

static Datum
get_nspname(HeapTuple tuple, TupleDesc dsc)
{
	bool isNull;
	Datum nspname = heap_getattr(tuple, Anum_namespace_ext_namespace, dsc, &isNull);
	return nspname;
}

static Datum
get_login_rolname(HeapTuple tuple, TupleDesc dsc)
{
	Form_authid_login_ext authid = ((Form_authid_login_ext) GETSTRUCT(tuple));
	return NameGetDatum(&(authid->rolname));
}

static Datum
get_default_database_name(HeapTuple tuple, TupleDesc dsc)
{
	Form_authid_login_ext authid = ((Form_authid_login_ext) GETSTRUCT(tuple));
	return PointerGetDatum(&(authid->default_database_name));
}

static Datum
get_user_rolname(HeapTuple tuple, TupleDesc dsc)
{
	Form_authid_user_ext authid = ((Form_authid_user_ext) GETSTRUCT(tuple));
	return NameGetDatum(&(authid->rolname));
}

static Datum
get_database_name(HeapTuple tuple, TupleDesc dsc)
{
	bool isNull;
	Datum dbname = heap_getattr(tuple, Anum_bbf_authid_user_ext_database_name, dsc, &isNull);
	return dbname;
}

/*****************************************
 * 			Condition check funcs
 *****************************************/
static bool
is_singledb_exists_userdb(void)
{
	return (SINGLE_DB == get_migration_mode() && get_one_user_db_name());
}

static bool
is_multidb(void)
{
	return (MULTI_DB == get_migration_mode());
}

/*****************************************
 * 			Rule validation funcs
 *****************************************/

static bool
check_exist(void *arg, HeapTuple tuple)
{
	bool			found;
	Relation		rel;
	SysScanDesc		scan;
	ScanKeyData		scanKey;
	Rule			*rule;
	Datum			datum;

	rule = (Rule *) arg;

	if (!rule->func_val)
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("Null value function for rule: \n%s",
						rule->desc)));

	rel = table_open(rule->tbldata->tbl_oid, AccessShareLock);

	/* Get the wanted datum through value function */
	datum = (rule->func_val) (tuple, rule->tupdesc);

	ScanKeyInit(&scanKey, 
				rule->tbldata->attnum, 
				BTEqualStrategyNumber, 
				rule->tbldata->regproc, 
				datum);

	scan = systable_beginscan(rel, rule->tbldata->idx_oid, true, NULL, 1, &scanKey);

	/* The rule passes if we found the wanted datum in the catalog */
	found = (HeapTupleIsValid(systable_getnext(scan)));

	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	return found;
}

/*****************************************
 * 			Helper functions
 *****************************************/

static void 
update_report(Rule *rule, Tuplestorestate *res_tupstore, TupleDesc res_tupdesc)
{
	Datum		values[4];
	bool		nulls[4];
	const char	*object_type;
	const char	*schema_name;
	const char	*object_name = rule->colname;
	int			str_len = strlen(rule->desc) + strlen("{\"Rule\":\"\"}") + 1;
	char		*detail = palloc0(str_len);
	Jsonb		*detail_jsonb;

	snprintf(detail, str_len, "{\"Rule\":\"%s\"}", rule->desc);
	detail_jsonb = DatumGetJsonbP(DirectFunctionCall1(jsonb_in, CStringGetDatum(detail)));

	MemSet(nulls, 0, sizeof(nulls));

	if (!rule->tbldata)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Failed to find catalog info for rule: \n%s",
						rule->desc)));

	object_type = format_type_be(rule->tbldata->atttype);
	schema_name = get_namespace_name(get_rel_namespace(rule->tbldata->tbl_oid));

	/* Build tuple values for the report */
	values[0] = CStringGetTextDatum(object_type);
	values[1] = CStringGetTextDatum(schema_name);
	values[2] = CStringGetTextDatum(object_name);
	values[3] = JsonbPGetDatum(detail_jsonb);

	tuplestore_putvalues(res_tupstore, res_tupdesc, values, nulls);
}

/*
 * Initialize the inconstant members of the RelData array catalog_data[]
 * MUST comply with catalog_data[].
 */
static void
init_catalog_data(void)
{
	for (size_t i = 0; i < sizeof(catalog_data) / sizeof(catalog_data[0]); i++)
	{
		if (strcmp(catalog_data[i].tblname, "babelfish_sysdatabases") == 0)
		{
			catalog_data[i].tbl_oid = sysdatabases_oid;
			catalog_data[i].idx_oid = sysdatabaese_idx_name_oid;
			catalog_data[i].atttype = get_atttype(sysdatabases_oid, Anum_sysdatabaese_name);
		}
		else if (strcmp(catalog_data[i].tblname, "babelfish_namespace_ext") == 0)
		{
			catalog_data[i].tbl_oid = namespace_ext_oid;
			catalog_data[i].idx_oid = namespace_ext_idx_oid_oid;
			catalog_data[i].atttype = get_atttype(namespace_ext_oid, Anum_namespace_ext_namespace);
		}
		else if (strcmp(catalog_data[i].tblname, "babelfish_authid_login_ext") == 0)
		{
			catalog_data[i].tbl_oid = bbf_authid_login_ext_oid;
			catalog_data[i].idx_oid = bbf_authid_login_ext_idx_oid;
			catalog_data[i].atttype = get_atttype(bbf_authid_login_ext_oid, Anum_bbf_authid_login_ext_rolname);
		}
		else if (strcmp(catalog_data[i].tblname, "babelfish_authid_user_ext") == 0)
		{
			catalog_data[i].tbl_oid = bbf_authid_user_ext_oid;
			catalog_data[i].idx_oid = bbf_authid_user_ext_idx_oid;
			catalog_data[i].atttype = get_atttype(bbf_authid_user_ext_oid, Anum_bbf_authid_user_ext_rolname);
		}
		else if (strcmp(catalog_data[i].tblname, "pg_namespace") == 0)
		{
			catalog_data[i].tbl_oid = NamespaceRelationId;
			catalog_data[i].idx_oid = NamespaceNameIndexId;
			catalog_data[i].atttype = get_atttype(NamespaceRelationId, Anum_pg_namespace_nspname);
		}
		else if (strcmp(catalog_data[i].tblname, "pg_authid") == 0)
		{
			catalog_data[i].tbl_oid = AuthIdRelationId;
			catalog_data[i].idx_oid = AuthIdRolnameIndexId;
			catalog_data[i].atttype = get_atttype(AuthIdRelationId, Anum_pg_authid_rolname);
		}
		else
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("\"%s\" is not a supported catalog", catalog_data[i].tblname)));
	}
}

static void
get_catalog_info(Rule *rule)
{
	size_t num_catalog = sizeof(catalog_data) / sizeof(catalog_data[0]);
	size_t i = 0;

	for (; i < num_catalog; i++)
	{
		if (strcmp(rule->tblname, catalog_data[i].tblname) == 0)
		{
			rule->tbldata = &catalog_data[i];
			break;
		}
	}
	if (i == num_catalog)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Failed to find \"%s\" in the pre-defined catalog data array", 
						rule->tblname)));
}
