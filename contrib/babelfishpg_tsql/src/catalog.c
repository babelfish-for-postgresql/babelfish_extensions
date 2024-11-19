#include "postgres.h"
#include "miscadmin.h"
#include "access/htup_details.h"
#include "access/heapam.h"
#include "access/genam.h"
#include "access/skey.h"
#include "access/stratnum.h"
#include "access/table.h"
#include "catalog/catalog.h"
#include "catalog/heap.h"
#include "catalog/indexing.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_foreign_server.h"
#include "catalog/namespace.h"
#include "commands/extension.h"
#include "commands/schemacmds.h"
#include "commands/user.h"
#include "parser/parse_relation.h"
#include "parser/scansup.h"
#include "tcop/utility.h"
#include "utils/builtins.h"
#include "utils/catcache.h"
#include "utils/fmgroids.h"
#include "utils/formatting.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/tuplestore.h"
#include "utils/rel.h"
#include "utils/regproc.h"
#include "utils/array.h"
#include "utils/timestamp.h"
#include "nodes/execnodes.h"
#include "catalog.h"
#include "dbcmds.h"
#include "guc.h"
#include "hooks.h"
#include "multidb.h"
#include "rolecmds.h"
#include "session.h"
#include "pltsql.h"

/*****************************************
 *			SYS schema
 *****************************************/
Oid			sys_schema_oid = InvalidOid;

/*****************************************
 *			SYSDATABASES
 *****************************************/
Oid			sysdatabases_oid = InvalidOid;
Oid			sysdatabaese_idx_oid_oid = InvalidOid;
Oid			sysdatabaese_idx_name_oid = InvalidOid;

/*****************************************
 *			NAMESPACE_EXT
 *****************************************/
Oid			namespace_ext_oid = InvalidOid;
Oid			namespace_ext_idx_oid_oid = InvalidOid;
int			namespace_ext_num_cols = 4;

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
 *			VIEW_DEF
 *****************************************/
Oid			bbf_view_def_oid;
Oid			bbf_view_def_idx_oid;

/*****************************************
 *			LINKED_SERVERS_DEF
 *****************************************/
Oid			bbf_servers_def_oid;
Oid			bbf_servers_def_idx_oid;

/*****************************************
 *			FUNCTION_EXT
 *****************************************/
Oid			bbf_function_ext_oid;
Oid			bbf_function_ext_idx_oid;

/*****************************************
 *			SCHEMA
 *****************************************/
Oid			bbf_schema_perms_oid;
Oid			bbf_schema_perms_idx_oid;

int			permissions[NUMBER_OF_PERMISSIONS] = {ACL_INSERT, ACL_SELECT, ACL_UPDATE, ACL_DELETE, ACL_REFERENCES, ACL_EXECUTE};

/*****************************************
 *			DOMAIN MAPPING
 *****************************************/
Oid			bbf_domain_mapping_oid = InvalidOid;
Oid			bbf_domain_mapping_idx_oid = InvalidOid;

/*****************************************
 *			EXTENDED_PROPERTIES
 *****************************************/
Oid			bbf_extended_properties_oid = InvalidOid;
Oid			bbf_extended_properties_idx_oid = InvalidOid;

/*****************************************
 *			PARTITION_FUNCTION
 *****************************************/
Oid	bbf_partition_function_oid = InvalidOid;
Oid	bbf_partition_function_pk_idx_oid = InvalidOid;
Oid	bbf_partition_function_id_idx_oid = InvalidOid;
Oid	bbf_partition_function_seq_oid = InvalidOid;

/*****************************************
 *			PARTITION_SCHEME
 *****************************************/
Oid	bbf_partition_scheme_oid = InvalidOid;
Oid	bbf_partition_scheme_pk_idx_oid = InvalidOid;
Oid	bbf_partition_scheme_id_idx_oid = InvalidOid;
Oid	bbf_partition_scheme_seq_oid = InvalidOid;

/*****************************************
 *			PARTITION_DEPEND
 *****************************************/
Oid	bbf_partition_depend_oid = InvalidOid;
Oid	bbf_partition_depend_idx_oid = InvalidOid;


/*****************************************
 * 			Catalog General
 *****************************************/

static Oid bbf_assemblies_oid = InvalidOid;
static Oid bbf_configurations_oid = InvalidOid;
static Oid bbf_helpcollation_oid = InvalidOid;
static Oid bbf_syslanguages_oid = InvalidOid;
static Oid bbf_service_settings_oid = InvalidOid;
static Oid spt_datatype_info_table_oid = InvalidOid;
static Oid bbf_versions_oid = InvalidOid;

static bool tsql_syscache_inited = false;
extern bool babelfish_dump_restore;
extern char *orig_proc_funcname;

static struct cachedesc my_cacheinfo[] = {
	{-1,						/* SYSDATABASEOID */
		-1,
		1,
		{
			Anum_sysdatabases_oid,
			0,
			0,
			0
		},
		16
	},
	{-1,						/* SYSDATABASENAME */
		-1,
		1,
		{
			Anum_sysdatabases_name,
			0,
			0,
			0
		},
		16
	},
	{-1,						/* PROCNAMENSPSIGNATURE */
		-1,
		3,
		{
			Anum_bbf_function_ext_funcname,
			Anum_bbf_function_ext_nspname,
			Anum_bbf_function_ext_funcsignature,
			0
		},
		16
	},
	{-1,						/* SYSNAMESPACENAME */
		-1,
		1,
		{
			Anum_namespace_ext_namespace,
			0,
			0,
			0
		},
		16
	},
	{-1,						/* AUTHIDUSEREXTROLENAME */
		-1,
		1,
		{
			Anum_bbf_authid_user_ext_rolname,
			0,
			0,
			0
		},
		16
	}
};

PG_FUNCTION_INFO_V1(init_catalog);
Datum
init_catalog(PG_FUNCTION_ARGS)
{
	/* sys schema */
	sys_schema_oid = get_namespace_oid("sys", true);

	if (!OidIsValid(sys_schema_oid))
		PG_RETURN_INT32(0);

	/* sysdatabases */
	sysdatabases_oid = get_relname_relid(SYSDATABASES_TABLE_NAME, sys_schema_oid);
	sysdatabaese_idx_name_oid = get_relname_relid(SYSDATABASES_PK_NAME, sys_schema_oid);
	sysdatabaese_idx_oid_oid = get_relname_relid(SYSDATABASES_OID_IDX_NAME, sys_schema_oid);

	/* namespace_ext */
	namespace_ext_oid = get_relname_relid(NAMESPACE_EXT_TABLE_NAME, sys_schema_oid);
	namespace_ext_idx_oid_oid = get_relname_relid(NAMESAPCE_EXT_PK_NAME, sys_schema_oid);

	/* bbf_function_ext */
	bbf_function_ext_oid = get_relname_relid(BBF_FUNCTION_EXT_TABLE_NAME, sys_schema_oid);
	bbf_function_ext_idx_oid = get_relname_relid(BBF_FUNCTION_EXT_IDX_NAME, sys_schema_oid);

	/* user ext */
	bbf_authid_user_ext_oid = get_relname_relid(BBF_AUTHID_USER_EXT_TABLE_NAME,
												sys_schema_oid);
	bbf_authid_user_ext_idx_oid = get_relname_relid(BBF_AUTHID_USER_EXT_IDX_NAME,
													sys_schema_oid);

	/* syscache info */
	my_cacheinfo[0].reloid = sysdatabases_oid;
	my_cacheinfo[0].indoid = sysdatabaese_idx_oid_oid;
	my_cacheinfo[1].reloid = sysdatabases_oid;
	my_cacheinfo[1].indoid = sysdatabaese_idx_name_oid;
	my_cacheinfo[2].reloid = bbf_function_ext_oid;
	my_cacheinfo[2].indoid = bbf_function_ext_idx_oid;
	my_cacheinfo[3].reloid = namespace_ext_oid;
	my_cacheinfo[3].indoid = namespace_ext_idx_oid_oid;
	my_cacheinfo[4].reloid = bbf_authid_user_ext_oid;
	my_cacheinfo[4].indoid = bbf_authid_user_ext_idx_oid;

	/* login ext */
	bbf_authid_login_ext_oid = get_relname_relid(BBF_AUTHID_LOGIN_EXT_TABLE_NAME,
												 sys_schema_oid);
	bbf_authid_login_ext_idx_oid = get_relname_relid(BBF_AUTHID_LOGIN_EXT_IDX_NAME,
													 sys_schema_oid);

	/* bbf_view_def */
	bbf_view_def_oid = get_relname_relid(BBF_VIEW_DEF_TABLE_NAME, sys_schema_oid);
	bbf_view_def_idx_oid = get_relname_relid(BBF_VIEW_DEF_IDX_NAME, sys_schema_oid);

	/* bbf_schema_perms */
	bbf_schema_perms_oid = get_relname_relid(BBF_SCHEMA_PERMS_TABLE_NAME, sys_schema_oid);
	bbf_schema_perms_idx_oid = get_relname_relid(BBF_SCHEMA_PERMS_IDX_NAME, sys_schema_oid);

	/* bbf_servers_def */
	bbf_servers_def_oid = get_relname_relid(BBF_SERVERS_DEF_TABLE_NAME, sys_schema_oid);
	bbf_servers_def_idx_oid = get_relname_relid(BBF_SERVERS_DEF_IDX_NAME, sys_schema_oid);

	/* bbf_extended_properties */
	bbf_extended_properties_oid = get_relname_relid(BBF_EXTENDED_PROPERTIES_TABLE_NAME, sys_schema_oid);
	bbf_extended_properties_idx_oid = get_relname_relid(BBF_EXTENDED_PROPERTIES_IDX_NAME, sys_schema_oid);

	/* bbf_domain_mapping */
	bbf_domain_mapping_oid = get_relname_relid(BBF_DOMAIN_MAPPING_TABLE_NAME, sys_schema_oid);
	bbf_domain_mapping_idx_oid = get_relname_relid(BBF_DOMAIN_MAPPING_IDX_NAME, sys_schema_oid);

	/* general catalog */
	bbf_assemblies_oid = get_relname_relid(BBF_ASSEMBLIES_TABLE_NAME, sys_schema_oid);
	bbf_configurations_oid = get_relname_relid(BBF_CONFIGURATIONS_TABLE_NAME, sys_schema_oid);
	bbf_helpcollation_oid = get_relname_relid(BBF_HELPCOLLATION_TABLE_NAME, sys_schema_oid);
	bbf_syslanguages_oid = get_relname_relid(BBF_SYSLANGUAGES_TABLE_NAME, sys_schema_oid);
	bbf_service_settings_oid = get_relname_relid(BBF_SERVICE_SETTINGS_TABLE_NAME, sys_schema_oid);
	spt_datatype_info_table_oid = get_relname_relid(SPT_DATATYPE_INFO_TABLE_NAME, sys_schema_oid);
	bbf_versions_oid = get_relname_relid(BBF_VERSIONS_TABLE_NAME, sys_schema_oid);

	/* bbf_partition_function */
	bbf_partition_function_oid = get_bbf_partition_function_oid();
	bbf_partition_function_pk_idx_oid = get_bbf_partition_function_pk_idx_oid();
	bbf_partition_function_id_idx_oid = get_bbf_partition_function_id_idx_oid();
	bbf_partition_function_seq_oid = get_bbf_partition_function_seq_oid();

	/* bbf_partition_scheme */
	bbf_partition_scheme_oid = get_bbf_partition_scheme_oid();
	bbf_partition_scheme_pk_idx_oid = get_bbf_partition_scheme_pk_idx_oid();
	bbf_partition_scheme_id_idx_oid = get_bbf_partition_scheme_id_idx_oid();
	bbf_partition_scheme_seq_oid = get_bbf_partition_scheme_seq_oid();

	/* bbf_partition_depend */
	bbf_partition_depend_oid = get_bbf_partition_depend_oid();
	bbf_partition_depend_idx_oid = get_bbf_partition_depend_idx_oid();

	if (sysdatabases_oid != InvalidOid)
		initTsqlSyscache();

	PG_RETURN_INT32(0);
}

void
initTsqlSyscache()
{
	Assert(my_cacheinfo[0].reloid != -1);
	/* Initialize info for catcache */
	if (!tsql_syscache_inited)
	{
		InitExtensionCatalogCache(my_cacheinfo, SYSDATABASEOID, 5);
		tsql_syscache_inited = true;
	}
}

/*****************************************
 * 			Catalog Hooks
 *****************************************/
/*
 * The assumption of parent function is that it should not perform any
 * catalog accesses.
 */
bool
IsPLtsqlExtendedCatalog(Oid relationId)
{
	/* Skip during Babelfish restore */
	if (!babelfish_dump_restore && (relationId == sysdatabases_oid ||
		relationId == bbf_function_ext_oid || relationId == namespace_ext_oid ||
		relationId == bbf_authid_login_ext_oid || relationId == bbf_authid_user_ext_oid ||
		relationId == bbf_view_def_oid || relationId == bbf_servers_def_oid ||
		relationId == bbf_schema_perms_oid || relationId == bbf_domain_mapping_oid ||
		relationId == bbf_extended_properties_oid || relationId == bbf_assemblies_oid ||
		relationId == bbf_configurations_oid || relationId == bbf_helpcollation_oid ||
		relationId == bbf_syslanguages_oid || relationId == bbf_service_settings_oid ||
		relationId == spt_datatype_info_table_oid || relationId == bbf_versions_oid ||
		relationId == bbf_partition_function_oid || relationId == bbf_partition_scheme_oid ||
		relationId == bbf_partition_depend_oid))
		return true;
	if (PrevIsExtendedCatalogHook)
		return (*PrevIsExtendedCatalogHook) (relationId);
	return false;
}

bool
IsPltsqlToastRelationHook(Relation relation)
{
	/*
	* If relname is pg_toast and exists in ENR then it is a local toast relation.
	* Match IsToastRelation() such that return true for locally owned toast relation only.
	*/
	if (strstr(RelationGetRelationName(relation), "@pg_toast"))
		return get_ENR(currentQueryEnv, RelationGetRelationName(relation), true);

	return IsToastNamespace(RelationGetNamespace(relation));
}

bool IsPltsqlToastClassHook(Form_pg_class pg_class_tup)
{
	/*
	* Similar as above but different input parameter
	*/
	char *relname = NameStr((pg_class_tup)->relname);
	if (strstr(relname, "@pg_toast"))
		return get_ENR(currentQueryEnv, relname, true);

	return IsToastNamespace(pg_class_tup->relnamespace);
}

void pltsql_drop_relation_refcnt_hook(Relation relation)
{
	int expected_refcnt = 0;
	if (!IsTsqlTableVariable(relation))
		return;

	expected_refcnt = relation->rd_isnailed ? 2 : 1;

	while (relation->rd_refcnt > expected_refcnt)
	{
		RelationDecrementReferenceCount(relation);
	}
}

/*****************************************
 *			SYSDATABASES
 *****************************************/
int16
get_db_id(const char *dbname)
{
	int16		db_id = 0;
	HeapTuple	tuple;
	Form_sysdatabases sysdb;

	tuple = SearchSysCache1(SYSDATABASENAME, CStringGetTextDatum(dbname));

	if (!HeapTupleIsValid(tuple))
		return InvalidDbid;

	sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
	db_id = sysdb->dbid;
	ReleaseSysCache(tuple);

	return db_id;
}

char *
get_db_name(int16 dbid)
{
	HeapTuple	tuple;
	Datum		name_datum;
	char	   *name = NULL;
	bool		isNull;

	tuple = SearchSysCache1(SYSDATABASEOID, Int16GetDatum(dbid));

	if (!HeapTupleIsValid(tuple))
		return NULL;

	name_datum = SysCacheGetAttr(SYSDATABASEOID, tuple, Anum_sysdatabases_name, &isNull);
	name = TextDatumGetCString(name_datum);
	ReleaseSysCache(tuple);

	return name;
}

const char *
get_one_user_db_name(void)
{
	HeapTuple	tuple;
	TableScanDesc scan;
	Relation	rel;
	char	   *user_db_name = NULL;
	bool		is_null;

	rel = table_open(sysdatabases_oid, AccessShareLock);
	scan = table_beginscan_catalog(rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		char	   *db_name;

		Datum		name = heap_getattr(tuple, Anum_sysdatabases_name,
										rel->rd_att, &is_null);

		db_name = TextDatumGetCString(name);

		/* check that db_name is not "master", "tempdb", or "msdb" */
		if (!IS_BBF_BUILT_IN_DB(db_name))
		{
			user_db_name = db_name;
			break;
		}
		pfree(db_name);
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
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	char	   *dbname;
	char	   *dbname_lower;
	ScanKeyData scanKey;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	Relation	rel;
	SysScanDesc scan;
	HeapTuple	tuple;
	Form_sysdatabases sysdb;
	Oid			datetime_output_func;
	bool		typIsVarlena;
	Oid			datetime_type;
	Oid			sys_nspoid = get_namespace_oid("sys", false);
	int			index;

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
		dbname_lower = str_tolower(dbname, strlen(dbname), DEFAULT_COLLATION_OID);
		/* Remove trailing spaces at the end of user typed dbname */
		index = -1;
		for (int i = 0; dbname_lower[i] != '\0'; i++)
		{
			if (dbname_lower[i] != ' ')
			{
				index = i;
			}
		}
		dbname_lower[index + 1] = '\0';
		if (!DbidIsValid(get_db_id(dbname_lower)))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					 errmsg("The database '%s' does not exist. Supply a valid database name. To see available databases, use sys.databases.", dbname)));
		ScanKeyInit(&scanKey,
					Anum_sysdatabases_name,
					BTEqualStrategyNumber, F_TEXTEQ,
					CStringGetTextDatum(dbname_lower));
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
		char	   *db_name_entry;
		Timestamp	tmstmp;
		char	   *tmstmp_str;
		bool		isNull;

		sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));

		MemSet(nulls, 0, sizeof(nulls));

		db_name_entry = TextDatumGetCString(heap_getattr(tuple, Anum_sysdatabases_name,
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

		tmstmp = DatumGetTimestamp(heap_getattr(tuple, Anum_sysdatabases_crdate,
												RelationGetDescr(rel), &isNull));

		tmstmp_str = OidOutputFunctionCall(datetime_output_func, tmstmp);
		values[4] = CStringGetTextDatum(tmstmp_str);

		nulls[5] = 1;
		values[6] = UInt8GetDatum(120);

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
	HeapTuple	tuple;
	Datum		datum;
	const char *logical_name;
	bool		isnull;

	if (!physical_schema_name || get_namespace_oid(physical_schema_name, missingOk) == InvalidOid)
		return NULL;

	tuple = SearchSysCache1(SYSNAMESPACENAME, CStringGetDatum(physical_schema_name));
	if (!HeapTupleIsValid(tuple))
	{
		if (!missingOk)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Could find logical schema name for: \"%s\"", physical_schema_name)));
		return NULL;
	}
	datum = SysCacheGetAttr(SYSNAMESPACENAME, tuple, Anum_namespace_ext_orig_name, &isnull);
	logical_name = pstrdup(TextDatumGetCString(datum));
	ReleaseSysCache(tuple);

	return logical_name;
}

int16
get_dbid_from_physical_schema_name(const char *physical_schema_name, bool missingOk)
{
	HeapTuple	tuple;
	Datum		datum;
	int16		dbid;
	bool		isnull;

	if (get_namespace_oid(physical_schema_name, false) == InvalidOid)
		return InvalidDbid;

	tuple = SearchSysCache1(SYSNAMESPACENAME, CStringGetDatum(physical_schema_name));
	if (!HeapTupleIsValid(tuple))
	{
		if (!missingOk)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Could not find db id for: \"%s\"", physical_schema_name)));
		return InvalidDbid;
	}
	datum = SysCacheGetAttr(SYSNAMESPACENAME, tuple, Anum_namespace_ext_dbid, &isnull);
	dbid = DatumGetInt16(datum);
	ReleaseSysCache(tuple);

	return dbid;
}

/*****************************************
 *			LOGIN EXT
 *****************************************/

bool
is_login(Oid role_oid)
{
	Relation	relation;
	bool		is_login = true;
	ScanKeyData scanKey;
	SysScanDesc scan;
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
	ScanKeyData scanKey;
	SysScanDesc scan;
	HeapTuple	tuple;
	NameData   *login;

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
Datum
bbf_get_login_default_db(PG_FUNCTION_ARGS)
{
	char	   *login_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	char	   *ret;

	ret = get_login_default_db(login_name);

	if (!ret)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(cstring_to_text(ret));
}

char *
get_login_default_db(char *login_name)
{
	Relation	bbf_authid_login_ext_rel;
	TupleDesc	dsc;
	HeapTuple	tuple;
	ScanKeyData scanKey;
	SysScanDesc scan;
	Datum		datum;
	bool		isnull;
	char	   *default_db_name;

	/* Fetch the relation */
	bbf_authid_login_ext_rel = table_open(get_authid_login_ext_oid(), AccessShareLock);
	dsc = RelationGetDescr(bbf_authid_login_ext_rel);

	/* Search and obtain the tuple on the role name */
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

	datum = heap_getattr(tuple, LOGIN_EXT_DEFAULT_DATABASE_NAME + 1, dsc, &isnull);
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

/*
 * Check if role is a bbf db principal. Returns BBF_ROLE if it is
 * a db role, returns BBF_USER if it is db user else returns 0
 */

const int
get_db_principal_kind(Oid role_oid, const char *db_name)
{
	char    	result = 0;
	bool    	isnull;
	HeapTuple	tuple;
	char    	*rolname;

	Assert(OidIsValid(role_oid) && db_name);

	rolname = GetUserNameFromId(role_oid, false);
	tuple = SearchSysCache1(AUTHIDUSEREXTROLENAME, CStringGetDatum(rolname));
	pfree(rolname);

	if (HeapTupleIsValid(tuple))
	{
		BpChar type = ((Form_authid_user_ext) GETSTRUCT(tuple))->type;
		Datum datum = SysCacheGetAttr(AUTHIDUSEREXTROLENAME, tuple,
									  Anum_bbf_authid_user_ext_database_name,
									  &isnull);
		char *type_str;
		char *db_name_cstring;

		Assert(!isnull);

		type_str = bpchar_to_cstring(&type);
		db_name_cstring = TextDatumGetCString(datum);

		if (strcmp(db_name_cstring, db_name) == 0)
			result = (strcmp(type_str, "R") == 0) ? BBF_ROLE : BBF_USER;

		pfree(type_str);
		pfree(db_name_cstring);
		ReleaseSysCache(tuple);
	}

	return result;
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

/* Returns palloc'd original name given the physical name of the db principal */
char *
get_authid_user_ext_original_name(const char *physical_role_name, const char *db_name)
{
	char*    	orig_username = NULL;
	bool    	isnull;
	HeapTuple	tuple;

	Assert(physical_role_name && strlen(physical_role_name) != 0);
	Assert(db_name && strlen(db_name) != 0);

	tuple = SearchSysCache1(AUTHIDUSEREXTROLENAME, CStringGetDatum(physical_role_name));

	if (HeapTupleIsValid(tuple))
	{
		Datum datum = SysCacheGetAttr(AUTHIDUSEREXTROLENAME, tuple,
									  Anum_bbf_authid_user_ext_database_name, &isnull);
		char *db_name_cstring;

		Assert(!isnull);

		db_name_cstring = TextDatumGetCString(datum);

		if (strcmp(db_name_cstring, db_name) == 0)
		{
			datum = SysCacheGetAttr(AUTHIDUSEREXTROLENAME, tuple,
									Anum_bbf_authid_user_ext_orig_username, &isnull);
			Assert(!isnull);
			orig_username = TextDatumGetCString(datum);
		}

		pfree(db_name_cstring);
		ReleaseSysCache(tuple);
	}

	if (orig_username == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Could not find original name for db principal %s in database %s", physical_role_name, db_name)));

	return orig_username;
}

char *
get_authid_user_ext_physical_name(const char *db_name, const char *login)
{
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple_user_ext;
	ScanKeyData key[2];
	TableScanDesc scan;
	char	   *user_name = NULL;
	NameData   *login_name;

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
		Datum datum;
		bool user_can_connect;
		bool isnull;

		datum = heap_getattr(tuple_user_ext, Anum_bbf_authid_user_ext_user_can_connect,
							 RelationGetDescr(bbf_authid_user_ext_rel), &isnull);
		Assert(!isnull);
		user_can_connect = DatumGetInt32(datum);

		/* db_accessadmin members should always have connect permissions */
		if (user_can_connect == 1 ||
			(has_privs_of_role(get_role_oid(login, false), get_db_accessadmin_oid(db_name, false))))
		{
			datum = heap_getattr(tuple_user_ext, Anum_bbf_authid_user_ext_rolname,
								 RelationGetDescr(bbf_authid_user_ext_rel), &isnull);
			Assert(!isnull);
			user_name = pstrdup(DatumGetCString(datum));
		}
	}

	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	return user_name;
}

char *
get_authid_user_ext_schema_name(const char *db_name, const char *user)
{
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple_user_ext;
	ScanKeyData key[2];
	TableScanDesc scan;
	char	   *schema_name = NULL;
	NameData   *user_name;

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
		Datum		datum;
		bool		is_null;

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
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple;
	ScanKeyData key;
	TableScanDesc scan;
	List	   *db_users_list = NIL;

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
		char	   *user_name;
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

/*
 * Checks if there exists any user for respective database and login,
 * if there is not any then use dbo or guest user.
 * Checks whether decided user role has privileges of current login role and
 * returns the user name.
 */
char *
get_user_for_database(const char *db_name)
{
	char	   *user = NULL;
	const char *login;
	bool		login_is_db_owner;

	login = GetUserNameFromId(GetSessionUserId(), false);
	user = get_authid_user_ext_physical_name(db_name, login);
	login_is_db_owner = 0 == strncmp(login, get_owner_of_db(db_name), NAMEDATALEN);

	if (!user)
	{
		Oid			datdba;

		datdba = get_role_oid("sysadmin", false);
		if (is_member_of_role(GetSessionUserId(), datdba) || login_is_db_owner)
			user = (char *) get_dbo_role_name(db_name);
		else
		{
			/*
			 * Get the guest role name only if the guest is enabled on the
			 * current db.
			 */
			if (guest_has_dbaccess((char *) db_name))
				user = (char *) get_guest_role_name(db_name);
			else
				user = NULL;
		}
	}

	if (user && !(is_member_of_role(GetSessionUserId(), get_role_oid(user, false))
				  || login_is_db_owner))
		user = NULL;

	return user;
}

/*****************************************
 *			VIEW_DEF
 *****************************************/

Oid
get_bbf_view_def_oid()
{
	if (!OidIsValid(bbf_view_def_oid))
		bbf_view_def_oid = get_relname_relid(BBF_VIEW_DEF_TABLE_NAME,
											 get_namespace_oid("sys", false));

	return bbf_view_def_oid;
}

Oid
get_bbf_view_def_idx_oid()
{
	if (!OidIsValid(bbf_view_def_idx_oid))
		bbf_view_def_idx_oid = get_relname_relid(BBF_VIEW_DEF_IDX_NAME,
												 get_namespace_oid("sys", false));

	return bbf_view_def_idx_oid;
}

HeapTuple
search_bbf_view_def(Relation bbf_view_def_rel, int16 dbid, const char *logical_schema_name, const char *view_name)
{

	ScanKeyData scanKey[3];
	SysScanDesc scan;
	HeapTuple	scantup,
				oldtup;

	if (!DbidIsValid(dbid) || logical_schema_name == NULL || view_name == NULL)
		return NULL;


	/* Search and drop the definition */
	ScanKeyInit(&scanKey[0],
				Anum_bbf_view_def_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0, Anum_bbf_view_def_schema_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false), F_TEXTEQ,
				CStringGetTextDatum(logical_schema_name));

	ScanKeyEntryInitialize(&scanKey[2], 0, Anum_bbf_view_def_object_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false), F_TEXTEQ,
				CStringGetTextDatum(view_name));

	scan = systable_beginscan(bbf_view_def_rel,
							  get_bbf_view_def_idx_oid(),
							  true, NULL, 3, scanKey);

	scantup = systable_getnext(scan);
	oldtup = heap_copytuple(scantup);
	systable_endscan(scan);
	return oldtup;
}

/* Checks if it is view created during v2.2.0 or after that */
bool
check_is_tsql_view(Oid relid)
{
	Oid			schema_oid;
	Relation	bbf_view_def_rel;
	HeapTuple	scantup;
	char	   *view_name,
			   *schema_name;
	int16		logical_dbid;
	const char *logical_schema_name;
	bool		is_tsql_view = false;

	view_name = get_rel_name(relid);
	schema_oid = get_rel_namespace(relid);
	schema_name = get_namespace_name(schema_oid);
	if (view_name == NULL || schema_name == NULL || is_shared_schema(schema_name))
	{
		if (view_name)
			pfree(view_name);
		if (schema_name)
			pfree(schema_name);
		return false;
	}
	logical_schema_name = get_logical_schema_name(schema_name, true);
	logical_dbid = get_dbid_from_physical_schema_name(schema_name, true);
	if (logical_schema_name == NULL || !DbidIsValid(logical_dbid))
	{
		pfree(view_name);
		pfree(schema_name);
		if (logical_schema_name)
			pfree((char *) logical_schema_name);
		return false;
	}
	/* Fetch the relation */
	bbf_view_def_rel = table_open(get_bbf_view_def_oid(), AccessShareLock);

	scantup = search_bbf_view_def(bbf_view_def_rel, logical_dbid, logical_schema_name, view_name);

	if (HeapTupleIsValid(scantup))
	{
		is_tsql_view = true;
		heap_freetuple(scantup);
	}
	table_close(bbf_view_def_rel, AccessShareLock);
	pfree(view_name);
	pfree(schema_name);
	pfree((char *) logical_schema_name);
	return is_tsql_view;
}

void
clean_up_bbf_view_def(int16 dbid)
{
	Relation	bbf_view_def_rel;
	HeapTuple	scantup;
	ScanKeyData scanKey[1];
	SysScanDesc scan;

	/* Fetch the relation */
	bbf_view_def_rel = table_open(get_bbf_view_def_oid(), RowExclusiveLock);

	/* Search and drop the definition */
	ScanKeyInit(&scanKey[0],
				Anum_bbf_view_def_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	scan = systable_beginscan(bbf_view_def_rel,
							  get_bbf_view_def_idx_oid(),
							  true, NULL, 1, scanKey);

	while ((scantup = systable_getnext(scan)) != NULL)
	{
		if (HeapTupleIsValid(scantup))
			CatalogTupleDelete(bbf_view_def_rel,
							   &scantup->t_self);
	}

	systable_endscan(scan);
	table_close(bbf_view_def_rel, RowExclusiveLock);
}

/*****************************************
 *			LINKED_SERVERS_DEF
 *****************************************/

Oid
get_bbf_servers_def_oid()
{
	if (!OidIsValid(bbf_servers_def_oid))
		bbf_servers_def_oid = get_relname_relid(BBF_SERVERS_DEF_TABLE_NAME,
											 get_namespace_oid("sys", false));

	return bbf_servers_def_oid;
}

Oid
get_bbf_servers_def_idx_oid()
{
	if (!OidIsValid(bbf_servers_def_idx_oid))
		bbf_servers_def_idx_oid = get_relname_relid(BBF_SERVERS_DEF_IDX_NAME,
											 get_namespace_oid("sys", false));

	return bbf_servers_def_idx_oid;
}

int
get_timeout_from_server_name(char *servername, int attnum)
{
	Relation	bbf_servers_def_rel;
	HeapTuple	tuple;
	ScanKeyData	key;
	TableScanDesc	scan;
	int		timeout = 0;

	bbf_servers_def_rel = table_open(get_bbf_servers_def_oid(),
										 RowExclusiveLock);

	ScanKeyInit(&key,
				Anum_bbf_servers_def_servername,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(servername));

	scan = table_beginscan_catalog(bbf_servers_def_rel, 1, &key);

	tuple = heap_getnext(scan, ForwardScanDirection);
	if (HeapTupleIsValid(tuple))
	{
		bool	isNull;
		timeout = DatumGetInt32(heap_getattr(tuple, attnum,
														 RelationGetDescr(bbf_servers_def_rel), &isNull));
		if (isNull)
			timeout = 0;
	}

	table_endscan(scan);
	table_close(bbf_servers_def_rel, RowExclusiveLock);
	return timeout;
}

void
clean_up_bbf_server_def()
{
	/* Fetch the relation */
	Relation bbf_servers_def_rel = table_open(get_bbf_servers_def_oid(), RowExclusiveLock);
	/* Truncate the relation */
	heap_truncate_one_rel(bbf_servers_def_rel);
	table_close(bbf_servers_def_rel, RowExclusiveLock);
}

/*****************************************
 *			FUNCTION_EXT
 *****************************************/

Oid
get_bbf_function_ext_oid()
{
	if (!OidIsValid(bbf_function_ext_oid))
		bbf_function_ext_oid = get_relname_relid(BBF_FUNCTION_EXT_TABLE_NAME,
												 get_namespace_oid("sys", false));

	return bbf_function_ext_oid;
}

Oid
get_bbf_function_ext_idx_oid()
{
	if (!OidIsValid(bbf_function_ext_idx_oid))
		bbf_function_ext_idx_oid = get_relname_relid(BBF_FUNCTION_EXT_IDX_NAME,
													 get_namespace_oid("sys", false));

	return bbf_function_ext_idx_oid;
}

HeapTuple
get_bbf_function_tuple_from_proctuple(HeapTuple proctuple)
{
	CatCList    	*catlist;
	HeapTuple   	newtup = NULL;
	HeapTuple   	bbffunctuple;
	Form_pg_proc	form;
	char        	*physical_schemaname;
	NameData    	nsp_name;
	char        	*func_signature;

	/* Disallow extended catalog lookup during restore */
	if (!HeapTupleIsValid(proctuple) || babelfish_dump_restore)
		return NULL;			/* concurrently dropped */
	form = (Form_pg_proc) GETSTRUCT(proctuple);
	if (!is_pltsql_language_oid(form->prolang))
		return NULL;

	physical_schemaname = get_namespace_name(form->pronamespace);
	if (physical_schemaname == NULL)
	{
		elog(ERROR,
			 "Could not find physical schemaname for %u",
			 form->pronamespace);
	}

	/* skip for shared schemas */
	if (is_shared_schema(physical_schemaname))
	{
		pfree(physical_schemaname);
		return NULL;
	}

	namestrcpy(&nsp_name, physical_schemaname);
	pfree(physical_schemaname);

	/* First search just using function name and schema name */
	catlist = SearchSysCacheList2(PROCNAMENSPSIGNATURE,
								  NameGetDatum(&form->proname),
								  NameGetDatum(&nsp_name));

	if (catlist->n_members == 0)
	{
		ReleaseSysCacheList(catlist);
		return NULL;
	}

	/* Done, found a unique function */
	if (catlist->n_members == 1)
	{
		bbffunctuple = heap_copytuple(&catlist->members[0]->tuple);
		ReleaseSysCacheList(catlist);
		return bbffunctuple;
	}

	/* Now search using function name, schema name and signature */
	func_signature = get_pltsql_function_signature_internal(NameStr(form->proname),
															form->pronargs,
															form->proargtypes.values);

	if (func_signature == NULL)
		return NULL;

	bbffunctuple = SearchSysCache3(PROCNAMENSPSIGNATURE,
								   NameGetDatum(&form->proname),
								   NameGetDatum(&nsp_name),
								   CStringGetTextDatum(func_signature));

	if (HeapTupleIsValid(bbffunctuple))
	{
		newtup = heap_copytuple(bbffunctuple);
		ReleaseSysCache(bbffunctuple);
	}
	pfree(func_signature);

	return newtup;
}

void
clean_up_bbf_function_ext(int16 dbid)
{
	Relation	bbf_function_ext_rel,
				namespace_rel;
	AttrNumber	attnum;
	HeapTuple	scantup;
	ScanKeyData scanKey[1];
	TableScanDesc scan;

	/* Fetch the relations */
	namespace_rel = table_open(namespace_ext_oid, AccessShareLock);
	bbf_function_ext_rel = table_open(get_bbf_function_ext_oid(), RowExclusiveLock);

	attnum = (AttrNumber) attnameAttNum(namespace_rel, "dbid", false);
	if (attnum == InvalidAttrNumber)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_COLUMN),
				 errmsg("column \"dbid\" of relation \"%s\" does not exist",
						RelationGetRelationName(namespace_rel))));

	ScanKeyInit(&scanKey[0],
				attnum,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	scan = table_beginscan_catalog(namespace_rel, 1, scanKey);
	scantup = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(scantup))
	{
		bool		isNull;
		Datum		nspname;
		HeapTuple	functup;
		SysScanDesc funcscan;

		nspname = heap_getattr(scantup,
							   Anum_namespace_ext_namespace,
							   RelationGetDescr(namespace_rel),
							   &isNull);

		/* Search and drop the entry */
		ScanKeyInit(&scanKey[0],
					Anum_bbf_function_ext_nspname,
					BTEqualStrategyNumber, F_NAMEEQ,
					nspname);

		funcscan = systable_beginscan(bbf_function_ext_rel,
									  get_bbf_function_ext_idx_oid(),
									  true, NULL, 1, scanKey);

		while ((functup = systable_getnext(funcscan)) != NULL)
		{
			if (HeapTupleIsValid(functup))
				CatalogTupleDelete(bbf_function_ext_rel,
								   &functup->t_self);
		}

		systable_endscan(funcscan);
		scantup = heap_getnext(scan, ForwardScanDirection);
	}

	table_endscan(scan);
	table_close(namespace_rel, AccessShareLock);
	table_close(bbf_function_ext_rel, RowExclusiveLock);
}

/*
 * Look up the RECOMPILE flag in the extended catalog
 * This is called for every procedure execution so overhead should be minimized.
 */ 
bool
is_created_with_recompile(Oid objectId) 
{
	HeapTuple	proctuple,
				bbffunctuple;
	bool recompile = false;

	proctuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(objectId));
	if (!HeapTupleIsValid(proctuple))
	{
		ReleaseSysCache(proctuple);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("Cannot find the object \"%d\", because it does not exist or you do not have permission.", objectId)));
	}

	/* 
	 * The next lookup is relevant only for procedures (prokind = 'p') but since the OID 
	 * can only be for a procedure we do not check this to avoid additonal overhead
	 */
	bbffunctuple = get_bbf_function_tuple_from_proctuple(proctuple);

	if (HeapTupleIsValid(bbffunctuple))
	{
		bool isnull = false;
		Datum flag_validity;
		Datum flag_values;
		flag_validity = SysCacheGetAttr(PROCNAMENSPSIGNATURE,
												bbffunctuple,
												Anum_bbf_function_ext_flag_validity,
												&isnull);	
		Assert(isnull == false);				
																
		flag_values   = SysCacheGetAttr(PROCNAMENSPSIGNATURE,
												bbffunctuple,
												Anum_bbf_function_ext_flag_values,
												&isnull);		
		Assert(isnull == false);									

		/* Get the RECOMPILE bit */
		if ((DatumGetUInt64(flag_values) & DatumGetUInt64(flag_validity)) & FLAG_CREATED_WITH_RECOMPILE) 
			recompile = true;

		heap_freetuple(bbffunctuple);
	}

	ReleaseSysCache(proctuple);
	
	return recompile;
}

/*
 * Check if a catalog name is a classic T-SQL catalog starting with 'sys' (e.g. sysobjects).
 * Historically (dating back to the Sybase era) these catalogs were located in the
 * 'dbo' schema but have since been relocated to the 'sys' schema.
 * They can however still be referenced in the 'dbo' schema which is equivalent to using 'sys'.
 * Note: newer catalogs do not normally start with 'sys', but some exceptions exist, such as
 * 'system_sql_modules'. These newer cases are however not referencable via 'dbo'.
 *
 * The input parameter is a table/view name, from which enclosing double quotes or square brackets
 * have been stripped.
 */
bool
is_classic_catalog(const char *name)
{
	size_t len;
	Assert(name);
	len = strlen(name);
	if (len <= 7) // sysusers,systypes,syslocks,sysfiles are shortest
		return false;

	if ((len == 3) && pg_strncasecmp(name, "sys", 3) != 0)
		return false;

	return (
		// Currently supported catalogs:

	    // Instance-wide classic catalogs
	    // NB: sysdatabases does not need its schema mapped from 'dbo' to 'sys',
	    // but it is included here for completeness.
	    ((len == 12) &&  (pg_strncasecmp(name, "sysdatabases", len) == 0)) ||
	    ((len == 11) &&  (pg_strncasecmp(name, "syscharsets", len) == 0)) ||
	    ((len == 13) &&  (pg_strncasecmp(name, "sysconfigures", len) == 0)) ||
	    ((len == 13) &&  (pg_strncasecmp(name, "syscurconfigs", len) == 0)) ||
	    ((len == 12) &&  (pg_strncasecmp(name, "syslanguages", len) == 0)) ||
	    ((len ==  9) &&  (pg_strncasecmp(name, "syslogins", len) == 0)) ||
	    ((len == 12) &&  (pg_strncasecmp(name, "sysprocesses", len) == 0)) ||
                         
	    // DB-specific classic catalogs
	    ((len ==  10) && (pg_strncasecmp(name, "syscolumns", len) == 0)) ||
	    ((len ==  14) && (pg_strncasecmp(name, "sysforeignkeys", len) == 0)) ||
	    ((len ==  10) && (pg_strncasecmp(name, "sysindexes", len) == 0)) ||
	    ((len ==  10) && (pg_strncasecmp(name, "sysobjects", len) == 0)) ||
	    ((len ==   8) && (pg_strncasecmp(name, "systypes", len) == 0)) ||
	    ((len ==   8) && (pg_strncasecmp(name, "sysusers", len) == 0))
	);
	    
/*
 * Additional T-SQL catalogs, not currently supported in Babelfish.
 *
 * When adding support for such a catalog, add it to the list above.
 * We could include all of these in the list above, but that might
 * impact performance.
 *
 * Instance-wide catalogs:
		sysaltfiles
		syscacheobjects
		sysdevices
		sysfilegroups
		sysfiles
		syslockinfo
		syslocks
		sysoledbusers
		sysopentapes
		sysperfinfo
		sysremotelogins
		sysservers

 * DB-specific catalogs:
		syscomments
		sysconstraints
		sysdepends
		sysforeignkeys
		sysfulltextcatalogs
		sysindexkeys
		sysmembers
		sysmessages
		syspermissions
		sysprotects
		sysreferences
 *
 */
}

/*****************************************
 *			SCHEMA
 *****************************************/

Oid
get_bbf_schema_perms_oid()
{
	if (!OidIsValid(bbf_schema_perms_oid))
		bbf_schema_perms_oid = get_relname_relid(BBF_SCHEMA_PERMS_TABLE_NAME,
								get_namespace_oid("sys", false));
	return bbf_schema_perms_oid;
}

static Oid
get_bbf_schema_perms_idx_oid()
{
	if (!OidIsValid(bbf_schema_perms_idx_oid))
		bbf_schema_perms_idx_oid = get_relname_relid(BBF_SCHEMA_PERMS_IDX_NAME,
									get_namespace_oid("sys", false));
	return bbf_schema_perms_idx_oid;
}

/*****************************************
 *			DOMAIN MAPPING
 *****************************************/

Oid
get_bbf_domain_mapping_oid()
{
	if (!OidIsValid(bbf_domain_mapping_oid))
		bbf_domain_mapping_oid = get_relname_relid(BBF_DOMAIN_MAPPING_TABLE_NAME,
												   get_namespace_oid("sys", false));

	return bbf_domain_mapping_oid;
}

Oid
get_bbf_domain_mapping_idx_oid()
{
	if (!OidIsValid(bbf_domain_mapping_idx_oid))
		bbf_domain_mapping_idx_oid = get_relname_relid(BBF_DOMAIN_MAPPING_IDX_NAME,
													   get_namespace_oid("sys", false));

	return bbf_domain_mapping_idx_oid;
}

/*****************************************
 *			EXTENDED_PROPERTIES
 *****************************************/

Oid
get_bbf_extended_properties_oid()
{
	if (!OidIsValid(bbf_extended_properties_oid))
		bbf_extended_properties_oid = get_relname_relid(BBF_EXTENDED_PROPERTIES_TABLE_NAME,
														get_namespace_oid("sys", false));

	return bbf_extended_properties_oid;
}

Oid
get_bbf_extended_properties_idx_oid()
{
	if (!OidIsValid(bbf_extended_properties_idx_oid))
		bbf_extended_properties_idx_oid = get_relname_relid(BBF_EXTENDED_PROPERTIES_IDX_NAME,
															get_namespace_oid("sys", false));

	return bbf_extended_properties_idx_oid;
}

/*****************************************
 *			PARTITION_FUNCTION
 *****************************************/
Oid
get_bbf_partition_function_oid()
{
	if (!OidIsValid(bbf_partition_function_oid))
		bbf_partition_function_oid = get_relname_relid(BBF_PARTITION_FUNCTION_TABLE_NAME,
									get_namespace_oid("sys", false));

	return bbf_partition_function_oid;
}

Oid
get_bbf_partition_function_seq_oid()
{
	if (!OidIsValid(bbf_partition_function_seq_oid))
	{
		bbf_partition_function_seq_oid = get_relname_relid(BBF_PARTITION_FUNCTION_SEQ_NAME,
									get_namespace_oid("sys", false));
	}

	return bbf_partition_function_seq_oid;
}

Oid
get_bbf_partition_function_pk_idx_oid()
{
	if (!OidIsValid(bbf_partition_function_pk_idx_oid))
		bbf_partition_function_pk_idx_oid = get_relname_relid(BBF_PARTITION_FUNCTION_PK_IDX_NAME,
									get_namespace_oid("sys", false));

	return bbf_partition_function_pk_idx_oid;
}

Oid
get_bbf_partition_function_id_idx_oid()
{
	if (!OidIsValid(bbf_partition_function_id_idx_oid))
		bbf_partition_function_id_idx_oid = get_relname_relid(BBF_PARTITION_FUNCTION_ID_IDX_NAME,
									get_namespace_oid("sys", false));

	return bbf_partition_function_id_idx_oid;
}

/*****************************************
 *			PARTITION_SCHEME
 *****************************************/
Oid
get_bbf_partition_scheme_oid()
{
	if (!OidIsValid(bbf_partition_scheme_oid))
		bbf_partition_scheme_oid = get_relname_relid(BBF_PARTITION_SCHEME_TABLE_NAME,
									get_namespace_oid("sys", false));

	return bbf_partition_scheme_oid;
}

Oid
get_bbf_partition_scheme_pk_idx_oid()
{
	if (!OidIsValid(bbf_partition_scheme_pk_idx_oid))
		bbf_partition_scheme_pk_idx_oid = get_relname_relid(BBF_PARTITION_SCHEME_PK_IDX_NAME,
									get_namespace_oid("sys", false));

	return bbf_partition_scheme_pk_idx_oid;
}

Oid
get_bbf_partition_scheme_id_idx_oid()
{
	if (!OidIsValid(bbf_partition_scheme_id_idx_oid))
		bbf_partition_scheme_id_idx_oid = get_relname_relid(BBF_PARTITION_SCHEME_ID_IDX_NAME,
									get_namespace_oid("sys", false));

	return bbf_partition_scheme_id_idx_oid;
}

Oid
get_bbf_partition_scheme_seq_oid()
{
	if (!OidIsValid(bbf_partition_scheme_seq_oid))
	{
		bbf_partition_scheme_seq_oid = get_relname_relid(BBF_PARTITION_SCHEME_SEQ_NAME,
									get_namespace_oid("sys", false));
	}

	return bbf_partition_scheme_seq_oid;
}


/*****************************************
 *			PARTITION_DEPEND
 *****************************************/
Oid
get_bbf_partition_depend_oid()
{
	if (!OidIsValid(bbf_partition_depend_oid))
		bbf_partition_depend_oid = get_relname_relid(BBF_PARTITION_DEPEND_TABLE_NAME,
								get_namespace_oid("sys", false));

	return bbf_partition_depend_oid;
}

Oid
get_bbf_partition_depend_idx_oid()
{
	if (!OidIsValid(bbf_partition_depend_idx_oid))
		bbf_partition_depend_idx_oid = get_relname_relid(BBF_PARTITION_DEPEND_IDX_NAME,
									get_namespace_oid("sys", false));

	return bbf_partition_depend_idx_oid;
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
bool		stop_at_first_error = false;

/*
 * This parameter controls whether the function will return consistent rule list
 * or detected inconsistency.
 */
bool		return_consistency = false;

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
static Datum get_tempdb_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_msdb_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_name_db_owner(HeapTuple tuple, TupleDesc dsc);
static Datum get_name_dbo(HeapTuple tuple, TupleDesc dsc);
static Datum get_name_guest(HeapTuple tuple, TupleDesc dsc);
static Datum get_nspname(HeapTuple tuple, TupleDesc dsc);
static Datum get_login_rolname(HeapTuple tuple, TupleDesc dsc);
static Datum get_default_database_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_user_rolname(HeapTuple tuple, TupleDesc dsc);
static Datum get_database_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_function_nspname(HeapTuple tuple, TupleDesc dsc);
static Datum get_function_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_perms_schema_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_perms_grantee_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_server_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_partition_function_dbname(HeapTuple tuple, TupleDesc dsc);
static Datum get_partition_scheme_dbname(HeapTuple tuple, TupleDesc dsc);
static Datum get_partition_depend_dbname(HeapTuple tuple, TupleDesc dsc);
static Datum get_partition_depend_schema_name(HeapTuple tuple, TupleDesc dsc);
static Datum get_partition_depend_table_oid(HeapTuple tuple, TupleDesc dsc);

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
static void create_guest_role_for_db(const char *dbname);
static char *get_db_owner_role_name(const char *dbname);
static void alter_guest_schema_for_db(const char *dbname);

/* Helper function Rename BBF catalog update*/
static void rename_view_update_bbf_catalog(RenameStmt *stmt);
static void rename_procfunc_update_bbf_catalog(RenameStmt *stmt);
static void rename_object_update_bbf_schema_permission_catalog(RenameStmt *stmt, int rename_type);

static int get_privilege_of_object(const char *schema_name, const char *object_name, const char *grantee, const char *object_type);

/*****************************************
 * 			Catalog Extra Info
 * ---------------------------------------
 * MUST also edit init_catalog_data() when
 * editing the listed catalogs here.
 *****************************************/
RelData		catalog_data[] =
{
	{"babelfish_sysdatabases", InvalidOid, InvalidOid, true, InvalidOid, Anum_sysdatabases_name, F_TEXTEQ},
	{"babelfish_namespace_ext", InvalidOid, InvalidOid, true, InvalidOid, Anum_namespace_ext_namespace, F_NAMEEQ},
	{"babelfish_authid_login_ext", InvalidOid, InvalidOid, true, InvalidOid, Anum_bbf_authid_login_ext_rolname, F_NAMEEQ},
	{"babelfish_authid_user_ext", InvalidOid, InvalidOid, true, InvalidOid, Anum_bbf_authid_user_ext_rolname, F_NAMEEQ},
	{"pg_namespace", InvalidOid, InvalidOid, true, InvalidOid, Anum_pg_namespace_nspname, F_NAMEEQ},
	{"pg_authid", InvalidOid, InvalidOid, true, InvalidOid, Anum_pg_authid_rolname, F_NAMEEQ},
	{"pg_proc", InvalidOid, InvalidOid, false, InvalidOid, Anum_pg_proc_proname, F_NAMEEQ},
	{"pg_foreign_server", InvalidOid, InvalidOid, true, InvalidOid, Anum_pg_foreign_server_srvname, F_NAMEEQ},
	{"pg_class", InvalidOid, InvalidOid, true, InvalidOid, Anum_pg_class_oid, F_OIDEQ}
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
Rule		must_have_rules[] =
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
	{"tempdb_db_owner must exist in babelfish_authid_user_ext",
	"babelfish_authid_user_ext", "rolname", NULL, get_tempdb_db_owner, NULL, check_exist, NULL},
	{"tempdb_dbo must exist in babelfish_authid_user_ext",
	"babelfish_authid_user_ext", "rolname", NULL, get_tempdb_dbo, NULL, check_exist, NULL},
	{"msdb_db_owner must exist in babelfish_authid_user_ext",
	"babelfish_authid_user_ext", "rolname", NULL, get_msdb_db_owner, NULL, check_exist, NULL},
	{"msdb_dbo must exist in babelfish_authid_user_ext",
	"babelfish_authid_user_ext", "rolname", NULL, get_msdb_dbo, NULL, check_exist, NULL}
};

/* Must match rules, MUST comply with metadata_inconsistency_check() */
/* babelfish_sysdatabases */
Rule		must_match_rules_sysdb[] =
{
	{"<owner> in babelfish_sysdatabases must also exist in babelfish_authid_login_ext",
	"babelfish_authid_login_ext", "rolname", NULL, get_owner, NULL, check_exist, NULL},
	{"In multi-db mode, for each <name> in babelfish_sysdatabases, <name>_db_owner must also exist in pg_authid",
	"pg_authid", "rolname", NULL, get_name_db_owner, is_multidb, check_exist, NULL},
	{"In multi-db mode, for each <name> in babelfish_sysdatabases, <name>_dbo must also exist in pg_authid",
	"pg_authid", "rolname", NULL, get_name_dbo, is_multidb, check_exist, NULL},
	{"In multi-db mode, for each <name> in babelfish_sysdatabases, <name>_dbo must also exist in babelfish_namespace_ext",
	"babelfish_namespace_ext", "nspname", NULL, get_name_dbo, is_multidb, check_exist, NULL},
	{"In multi-db mode, for each <name> in babelfish_sysdatabases, <name>_guest must also exist in babelfish_authid_user_ext",
	"babelfish_authid_user_ext", "rolname", NULL, get_name_guest, is_multidb, check_exist, NULL},
	{"In single-db mode, for each <name> in babelfish_sysdatabases, <name>_guest must also exist in babelfish_authid_user_ext",
	"babelfish_authid_user_ext", "rolname", NULL, get_name_guest, is_singledb_exists_userdb, check_exist, NULL}
};

/* babelfish_namespace_ext */
Rule		must_match_rules_nsp[] =
{
	{"<nspname> in babelfish_namespace_ext must also exist in pg_namespace",
	"pg_namespace", "nspname", NULL, get_nspname, NULL, check_exist, NULL}
};

/* babelfish_authid_login_ext */
Rule		must_match_rules_login[] =
{
	{"<rolname> in babelfish_authid_login_ext must also exist in pg_authid",
	"pg_authid", "rolname", NULL, get_login_rolname, NULL, check_exist, NULL},
	{"<default_database_name> in babelfish_authid_login_ext must also exist in babelfish_sysdatabases",
	"babelfish_sysdatabases", "name", NULL, get_default_database_name, NULL, check_exist, NULL}
};

/* babelfish_authid_user_ext */
Rule		must_match_rules_user[] =
{
	{"<rolname> in babelfish_authid_user_ext must also exist in pg_authid",
	"pg_authid", "rolname", NULL, get_user_rolname, NULL, check_exist, NULL},
	{"<database_name> in babelfish_authid_user_ext must also exist in babelfish_sysdatabases",
	"babelfish_sysdatabases", "name", NULL, get_database_name, NULL, check_exist, NULL}
};

/* babelfish_function_ext */
Rule		must_match_rules_function[] =
{
	{"<nspname> in babelfish_function_ext must also exist in babelfish_namespace_ext",
	"babelfish_namespace_ext", "nspname", NULL, get_function_nspname, NULL, check_exist, NULL},
	{"<funcname> in babelfish_function_ext must also exist in pg_proc",
	"pg_proc", "proname", NULL, get_function_name, NULL, check_exist, NULL}
};

/* babelfish_schema_permissions */
Rule		must_match_rules_schema_permission[] =
{
	{"<schema_name> in babelfish_schema_permissions must also exist in babelfish_namespace_ext",
	"babelfish_namespace_ext", "nspname", NULL, get_perms_schema_name, NULL, check_exist, NULL},
	{"<grantee> in babelfish_schema_permissions must also exist in pg_authid",
	"pg_authid", "rolname", NULL, get_perms_grantee_name, NULL, check_exist, NULL}
};

/* babelfish_server_options */
Rule		must_match_rules_srv_options[] =
{
	{"<servername> in babelfish_server_options must also exist in pg_foreign_server",
	"pg_foreign_server", "srvname", NULL, get_server_name, NULL, check_exist, NULL}
};

/*
 * For consistency of the "dbid" column in partition catalogs, we search on the "name" column
 * in babelfish_sysdatabases instead of "dbid". The metadata consistency framework does not
 * support defining multiple rules for the same catalog column, and a rule already exists
 * for the "name" column in babelfish_sysdatabases.
 *
 * Additionally, since there are no explicit indexes on the "partition_function_name" and
 * "partition_scheme_name" columns, consistency checks cannot be added to validate those.
 */

/* babelfish_partition_function */
Rule		must_match_rules_partition_function[] =
{
	{"<dbid> in babelfish_partition_function must also exist in babelfish_sysdatabases",
	"babelfish_sysdatabases", "name", NULL, get_partition_function_dbname, NULL, check_exist, NULL}
};

/* babelfish_partition_scheme */
Rule		must_match_rules_partition_scheme[] =
{
	{"<dbid> in babelfish_partition_scheme must also exist in babelfish_sysdatabases",
	"babelfish_sysdatabases", "name", NULL, get_partition_scheme_dbname, NULL, check_exist, NULL}
};

/* babelfish_partition_depend */
Rule		must_match_rules_partition_depend[] =
{
	{"<dbid> in babelfish_partition_depend must also exist in babelfish_sysdatabases",
	"babelfish_sysdatabases", "name", NULL, get_partition_depend_dbname, NULL, check_exist, NULL},
	{"<schema_name> in babelfish_partition_depend must also exist in babelfish_namespace_ext",
	"babelfish_namespace_ext", "nspname", NULL, get_partition_depend_schema_name, NULL, check_exist, NULL},
	{"<table_name> in babelfish_partition_depend must also exist in pg_class",
	"pg_class", "oid", NULL, get_partition_depend_table_oid, NULL, check_exist, NULL}
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
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;

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
		if (metadata_inconsistency_check_enabled())
		{
			/* Check metadata inconsistency */
			metadata_inconsistency_check(tupstore, tupdesc);
		}
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
	size_t		num_must_have_rules = sizeof(must_have_rules) / sizeof(must_have_rules[0]);
	size_t		num_must_match_rules_sysdb = sizeof(must_match_rules_sysdb) / sizeof(must_match_rules_sysdb[0]);
	size_t		num_must_match_rules_nsp = sizeof(must_match_rules_nsp) / sizeof(must_match_rules_nsp[0]);
	size_t		num_must_match_rules_login = sizeof(must_match_rules_login) / sizeof(must_match_rules_login[0]);
	size_t		num_must_match_rules_user = sizeof(must_match_rules_user) / sizeof(must_match_rules_user[0]);
	size_t		num_must_match_rules_function = sizeof(must_match_rules_function) / sizeof(must_match_rules_function[0]);
	size_t		num_must_match_rules_schema_permission = sizeof(must_match_rules_schema_permission) / sizeof(must_match_rules_schema_permission[0]);
	size_t		num_must_match_rules_srv_options = sizeof(must_match_rules_srv_options) / sizeof(must_match_rules_srv_options[0]);
	size_t		num_must_match_rules_partition_function = sizeof(must_match_rules_partition_function) / sizeof(must_match_rules_partition_function[0]);
	size_t		num_must_match_rules_partition_scheme = sizeof(must_match_rules_partition_scheme) / sizeof(must_match_rules_partition_scheme[0]);
	size_t		num_must_match_rules_partition_depend = sizeof(must_match_rules_partition_depend) / sizeof(must_match_rules_partition_depend[0]);

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
		||
		!(check_must_match_rules(must_match_rules_function, num_must_match_rules_function,
								 bbf_function_ext_oid, res_tupstore, res_tupdesc))
		||
		!(check_must_match_rules(must_match_rules_schema_permission, num_must_match_rules_schema_permission,
								 bbf_schema_perms_oid, res_tupstore, res_tupdesc))
		||
		!(check_must_match_rules(must_match_rules_srv_options, num_must_match_rules_srv_options,
								 bbf_servers_def_oid, res_tupstore, res_tupdesc))
		||
		!(check_must_match_rules(must_match_rules_partition_function, num_must_match_rules_partition_function,
								 bbf_partition_function_oid, res_tupstore, res_tupdesc))
		||
		!(check_must_match_rules(must_match_rules_partition_scheme, num_must_match_rules_partition_scheme,
								 bbf_partition_scheme_oid, res_tupstore, res_tupdesc))
		||
		!(check_must_match_rules(must_match_rules_partition_depend, num_must_match_rules_partition_depend,
								 bbf_partition_depend_oid, res_tupstore, res_tupdesc))
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
		Rule	   *rule = &(rules[i]);

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
	HeapTuple	tuple;
	TupleDesc	dsc;
	SysScanDesc scan;
	Relation	rel;

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
	char	   *rolname = GetUserNameFromId(GetSessionUserId(), false);

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
get_tempdb_db_owner(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("tempdb_db_owner");
}

static Datum
get_msdb_db_owner(HeapTuple tuple, TupleDesc dsc)
{
	return CStringGetDatum("msdb_db_owner");
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
	char	   *name_str = text_to_cstring(name);
	char	   *name_db_owner = palloc0(MAX_BBF_NAMEDATALEND);

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
	char	   *name_str = text_to_cstring(name);
	char	   *name_dbo = palloc0(MAX_BBF_NAMEDATALEND);

	truncate_identifier(name_str, strlen(name_str), false);
	snprintf(name_dbo, MAX_BBF_NAMEDATALEND, "%s_dbo", name_str);
	truncate_identifier(name_dbo, strlen(name_dbo), false);
	return CStringGetDatum(name_dbo);
}

static Datum
get_name_guest(HeapTuple tuple, TupleDesc dsc)
{
	Form_sysdatabases sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
	const text *name = &(sysdb->name);
	char	   *name_str = text_to_cstring(name);
	char	   *name_dbo = palloc0(MAX_BBF_NAMEDATALEND);

	truncate_identifier(name_str, strlen(name_str), false);
	snprintf(name_dbo, MAX_BBF_NAMEDATALEND, "%s_guest", name_str);
	truncate_identifier(name_dbo, strlen(name_dbo), false);
	return CStringGetDatum(name_dbo);
}

static Datum
get_nspname(HeapTuple tuple, TupleDesc dsc)
{
	bool		isNull;
	Datum		nspname = heap_getattr(tuple, Anum_namespace_ext_namespace, dsc, &isNull);

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
	bool		isNull;
	Datum		dbname = heap_getattr(tuple, Anum_bbf_authid_user_ext_database_name, dsc, &isNull);

	return dbname;
}

static Datum
get_function_nspname(HeapTuple tuple, TupleDesc dsc)
{
	Form_bbf_function_ext func = ((Form_bbf_function_ext) GETSTRUCT(tuple));

	return NameGetDatum(&(func->schema));
}

static Datum
get_function_name(HeapTuple tuple, TupleDesc dsc)
{
	Form_bbf_function_ext func = ((Form_bbf_function_ext) GETSTRUCT(tuple));

	return NameGetDatum(&(func->funcname));
}

static Datum
get_perms_schema_name(HeapTuple tuple, TupleDesc dsc)
{
	bool		schema_is_null, dbid_is_null;
	Datum		schema_name = heap_getattr(tuple, Anum_bbf_schema_perms_schema_name, dsc, &schema_is_null);
	Datum		dbid = heap_getattr(tuple, Anum_bbf_schema_perms_dbid, dsc, &dbid_is_null);
	char		*physical_schema_name;

	if (dbid_is_null)
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("dbid should not be null in babelfish_schema_permissions catalog")));
	if (schema_is_null)
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("schema name should not be null in babelfish_schema_permissions catalog")));

	/* get_physical_schema_name() itself handles truncation, no explicit truncation needed */
	physical_schema_name = get_physical_schema_name(get_db_name(DatumGetInt16(dbid)), TextDatumGetCString(schema_name));

	return CStringGetDatum(physical_schema_name);
}

static Datum
get_perms_grantee_name(HeapTuple tuple, TupleDesc dsc)
{
	bool		isNull;
	Datum		grantee_datum = heap_getattr(tuple, Anum_bbf_schema_perms_grantee, dsc, &isNull);
	char *grantee_name = pstrdup(TextDatumGetCString(grantee_datum));
	truncate_identifier(grantee_name, strlen(grantee_name), false);

	return CStringGetDatum(grantee_name);
}

static Datum
get_server_name(HeapTuple tuple, TupleDesc dsc)
{
	Form_bbf_servers_def	srv_def = ((Form_bbf_servers_def) GETSTRUCT(tuple));
	const text 		*srv_name = &(srv_def->servername);
	char 			*servername = text_to_cstring(srv_name);

	return CStringGetDatum(servername);
}

static Datum
get_partition_function_dbname(HeapTuple tuple, TupleDesc dsc)
{
	bool		is_null;
	char		*dbname;
	Datum		dbid = heap_getattr(tuple, Anum_bbf_partition_function_dbid, dsc, &is_null);

	if (is_null) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("dbid should not be null in babelfish_partition_function catalog")));

	/* Another way to check for existence of dbid in babelfish_sysdatabases catalog. */
	dbname = get_db_name(DatumGetInt16(dbid));

	if (!dbname) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("dbid in babelfish_partition_function catalog doesn't exists in babelfish_sysdatabases catalog")));

	return CStringGetTextDatum(dbname);
}

static Datum
get_partition_scheme_dbname(HeapTuple tuple, TupleDesc dsc)
{
	bool		is_null;
	char		*dbname;
	Datum		dbid = heap_getattr(tuple, Anum_bbf_partition_scheme_dbid, dsc, &is_null);

	if (is_null) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("dbid should not be null in babelfish_partition_scheme catalog")));
	
	/* Another way to check for existence of dbid in babelfish_sysdatabases catalog.*/
	dbname = get_db_name(DatumGetInt16(dbid));

	if (!dbname) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("dbid in babelfish_partition_scheme catalog doesn't exists in babelfish_sysdatabases catalog")));

	return CStringGetTextDatum(dbname);
}

static Datum
get_partition_depend_dbname(HeapTuple tuple, TupleDesc dsc)
{
	bool		is_null;
	Datum		dbid = heap_getattr(tuple, Anum_bbf_partition_depend_dbid, dsc, &is_null);
	char		*dbname;

	if (is_null) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("dbid should not be null in babelfish_partition_depend catalog")));
	
	/* Another way to check for existence of dbid in babelfish_sysdatabases catalog */
	dbname = get_db_name(DatumGetInt16(dbid));

	if (!dbname) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("dbid in babelfish_partition_depend catalog doesn't exists in babelfish_sysdatabases catalog")));

	return CStringGetTextDatum(dbname);
}

static Datum
get_partition_depend_schema_name(HeapTuple tuple, TupleDesc dsc)
{
	bool		schema_is_null, dbid_is_null;
	char		*physical_schema_name, *schema_name, *org_schema_name;
	Datum		dbid = heap_getattr(tuple, Anum_bbf_partition_depend_dbid, dsc, &dbid_is_null);
	Datum		schema_name_datum = heap_getattr(tuple, Anum_bbf_partition_depend_table_schema_name, dsc, &schema_is_null);

	if (dbid_is_null) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("dbid should not be null in babelfish_partition_depend catalog")));

	if (schema_is_null) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("schema_name should not be null in babelfish_partition_depend catalog")));

	org_schema_name = TextDatumGetCString(schema_name_datum);
	/*
	 * Downcase the orginal schema name and don't truncate it since
	 * truncation will be handled inside get_physical_schema_name().
	 */
	schema_name = downcase_identifier(org_schema_name, strlen(org_schema_name), false, false);
	physical_schema_name = get_physical_schema_name(get_db_name(DatumGetInt16(dbid)), schema_name);

	pfree(schema_name);
	pfree(org_schema_name);
	return CStringGetDatum(physical_schema_name);
}

static Datum
get_partition_depend_table_oid(HeapTuple tuple, TupleDesc dsc)
{
	bool		schema_is_null, dbid_is_null, table_is_null;
	char		*physical_schema_name, *db_name, *schema_name, *table_name, *org_schema_name;
	Oid		schema_oid, table_oid;
	Datum		dbid = heap_getattr(tuple, Anum_bbf_partition_depend_dbid, dsc, &dbid_is_null);
	Datum		schema_name_datum = heap_getattr(tuple, Anum_bbf_partition_depend_table_schema_name, dsc, &schema_is_null);
	Datum		table_name_datum = heap_getattr(tuple, Anum_bbf_partition_depend_table_name, dsc, &table_is_null);

	/* Sanity checks. */
	if (dbid_is_null)
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("dbid should not be null in babelfish_partition_depend catalog")));
	if (schema_is_null)
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("schema_name should not be null in babelfish_partition_depend catalog")));
	if (table_is_null)
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
					errmsg("table_name should not be null in babelfish_partition_depend catalog")));

	org_schema_name = TextDatumGetCString(schema_name_datum);
	table_name = TextDatumGetCString(table_name_datum);

	db_name = get_db_name(DatumGetInt16(dbid));

	if (!db_name) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("dbid in babelfish_partition_depend should also exists babelfish_sysdatabases catalog")));

	/*
	 * Downcase the orginal schema name and don't truncate it since
	 * truncation will be handled inside get_physical_schema_name().
	 */
	schema_name = downcase_identifier(org_schema_name, strlen(org_schema_name), false, false);
	physical_schema_name = get_physical_schema_name(db_name, schema_name);

	schema_oid = get_namespace_oid(physical_schema_name, true);

	if (!OidIsValid(schema_oid)) /* Sanity check. */
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("schema_name in babelfish_partition_depend should also exists in babelfish_namespace_ext")));

	table_oid = get_relname_relid(table_name, schema_oid);

	pfree(physical_schema_name);
	pfree(db_name);
	pfree(org_schema_name);
	pfree(schema_name);
	pfree(table_name);

	return ObjectIdGetDatum(table_oid);
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
	bool		found;
	Relation	rel;
	SysScanDesc scan;
	ScanKeyData scanKey;
	Rule	   *rule;
	Datum		datum;

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

	scan = systable_beginscan(rel, rule->tbldata->idx_oid, rule->tbldata->index_ok, NULL, 1, &scanKey);

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
	const char *object_type;
	const char *schema_name;
	const char *object_name = rule->colname;
	int			str_len = strlen(rule->desc) + strlen("{\"Rule\":\"\"}") + 1;
	char	   *detail = palloc0(str_len);
	Jsonb	   *detail_jsonb;

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
			catalog_data[i].atttype = get_atttype(sysdatabases_oid, Anum_sysdatabases_name);
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
		else if (strcmp(catalog_data[i].tblname, "pg_proc") == 0)
		{
			catalog_data[i].tbl_oid = ProcedureRelationId;
			catalog_data[i].idx_oid = InvalidOid;
			catalog_data[i].atttype = get_atttype(ProcedureRelationId, Anum_pg_proc_proname);
		}
		else if (strcmp(catalog_data[i].tblname, "pg_foreign_server") == 0)
		{
			catalog_data[i].tbl_oid = ForeignServerRelationId;
			catalog_data[i].idx_oid = ForeignServerNameIndexId;
			catalog_data[i].atttype = get_atttype(ForeignServerRelationId, Anum_pg_foreign_server_srvname);
		}
		else if (strcmp(catalog_data[i].tblname, "pg_class") == 0)
		{
			catalog_data[i].tbl_oid = RelationRelationId;
			catalog_data[i].idx_oid = ClassOidIndexId;
			catalog_data[i].atttype = get_atttype(RelationRelationId, Anum_pg_class_oid);
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
	size_t		num_catalog = sizeof(catalog_data) / sizeof(catalog_data[0]);
	size_t		i = 0;

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

/* Modifies the user_can_connect column in the catalog table
 * sys.babelfish_authid_user_ext based on the "GRANT/REVOKE
 * connect TO/FROM" statements.
 */
void
alter_user_can_connect(bool is_grant, char *user_name, char *db_name)
{
	Relation	bbf_authid_user_ext_rel;
	TupleDesc	bbf_authid_user_ext_dsc;
	ScanKeyData key[2];
	HeapTuple	usertuple;
	HeapTuple	new_tuple;
	TableScanDesc tblscan;
	Datum		new_record_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		new_record_nulls_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		new_record_repl_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);
	bbf_authid_user_ext_dsc = RelationGetDescr(bbf_authid_user_ext_rel);

	/* Search and obtain the tuple based on the user name and db name */
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_orig_username,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(user_name));
	ScanKeyInit(&key[1],
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(db_name));

	tblscan = table_beginscan_catalog(bbf_authid_user_ext_rel, 2, key);

	/* Build a tuple to insert */
	MemSet(new_record_user_ext, 0, sizeof(new_record_user_ext));
	MemSet(new_record_nulls_user_ext, false, sizeof(new_record_nulls_user_ext));
	MemSet(new_record_repl_user_ext, false, sizeof(new_record_repl_user_ext));

	usertuple = heap_getnext(tblscan, ForwardScanDirection);

	if (!HeapTupleIsValid(usertuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("Cannot find the user \"%s\", because it does not exist or you do not have permission.", user_name)));

	/*
	 * Update the column user_can_connect to 1 in case of GRANT and to 0 in
	 * case of REVOKE
	 */
	if (is_grant)
		new_record_user_ext[USER_EXT_USER_CAN_CONNECT] = Int32GetDatum(1);
	else
		new_record_user_ext[USER_EXT_USER_CAN_CONNECT] = Int32GetDatum(0);

	new_record_repl_user_ext[USER_EXT_USER_CAN_CONNECT] = true;

	new_tuple = heap_modify_tuple(usertuple,
								  bbf_authid_user_ext_dsc,
								  new_record_user_ext,
								  new_record_nulls_user_ext,
								  new_record_repl_user_ext);

	CatalogTupleUpdate(bbf_authid_user_ext_rel, &new_tuple->t_self, new_tuple);

	heap_freetuple(new_tuple);

	table_endscan(tblscan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
}

/* Checks if the guest user is enabled on a given database. */
bool
guest_has_dbaccess(const char *db_name)
{
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple_user_ext;
	ScanKeyData key[3];
	TableScanDesc scan;
	bool		has_access = false;

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_orig_username,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum("guest"));
	ScanKeyInit(&key[1],
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(db_name));
	ScanKeyInit(&key[2],
				Anum_bbf_authid_user_ext_user_can_connect,
				BTEqualStrategyNumber, F_INT4EQ,
				Int32GetDatum(1));

	scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 3, key);

	tuple_user_ext = heap_getnext(scan, ForwardScanDirection);
	if (HeapTupleIsValid(tuple_user_ext))
		has_access = true;

	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
	return has_access;
}

PG_FUNCTION_INFO_V1(update_user_catalog_for_guest);
Datum
update_user_catalog_for_guest(PG_FUNCTION_ARGS)
{
	Relation	db_rel;
	TableScanDesc scan;
	HeapTuple	tuple;
	bool		is_null;

	/* We only allow this to be called from an extension's SQL script. */
	if (!creating_extension)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("%s can only be called from an SQL script executed by CREATE/ALTER EXTENSION",
						"update_user_catalog_for_guest()")));

	db_rel = table_open(sysdatabases_oid, AccessShareLock);
	scan = table_beginscan_catalog(db_rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		Datum		db_name_datum = heap_getattr(tuple, Anum_sysdatabases_name,
												 db_rel->rd_att, &is_null);
		const char *db_name = TextDatumGetCString(db_name_datum);

		/*
		 * For each database, check if the guest user exists. If exists, check
		 * the next database. If not, create the guest user on that database.
		 */
		if (guest_role_exists_for_db(db_name))
		{
			tuple = heap_getnext(scan, ForwardScanDirection);
			continue;
		}
		create_guest_role_for_db(db_name);
		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	table_endscan(scan);
	table_close(db_rel, AccessShareLock);
	PG_RETURN_INT32(0);
}

bool
guest_role_exists_for_db(const char *dbname)
{
	char		*guest_role = get_guest_role_name(dbname);
	bool		role_exists = false;
	HeapTuple	tuple;

	tuple = SearchSysCache1(AUTHIDUSEREXTROLENAME, CStringGetDatum(guest_role));

	if (HeapTupleIsValid(tuple))
	{
		role_exists = true;
		ReleaseSysCache(tuple);
	}

	pfree(guest_role);

	return role_exists;
}

/*
 * get_login_for_user
 * Get mapped login for given user_id.
 * Usually login can be retrived from login_name column of bbf_authid_login_ext
 * catalog although sometimes the column can be empty such as when user_id belongs
 * to dbo or guest user. In case the user_id is of dbo role then we get owner of
 * the respective database which can be deduced from physical_schema_name. For all
 * other cases, return InvalidOid since mapped login does not exist for the rest.
 */
Oid
get_login_for_user(Oid user_id, const char *physical_schema_name)
{
	HeapTuple	tuple;
	Oid loginId = InvalidOid;
	char *physical_user_name = GetUserNameFromId(user_id, true);

	if (!physical_user_name || !physical_schema_name)
		return InvalidOid;

	/* Search if the role exists */
	tuple = SearchSysCache1(AUTHIDUSEREXTROLENAME, CStringGetDatum(physical_user_name));

	if (HeapTupleIsValid(tuple))
	{
		Datum datum;
		bool isnull;

		datum = SysCacheGetAttr(AUTHIDUSEREXTROLENAME, tuple, Anum_bbf_authid_user_ext_login_name, &isnull);
		Assert(!isnull);
		loginId = get_role_oid((DatumGetName(datum)->data), true);

		if (!OidIsValid(loginId))
		{
			char *orig_username = TextDatumGetCString(SysCacheGetAttr(AUTHIDUSEREXTROLENAME,
								tuple, Anum_bbf_authid_user_ext_orig_username, &isnull));

			Assert(!isnull);
			/* Get owner of the db if the user is dbo */
			if (strlen(orig_username) == 3 && pg_strcasecmp(orig_username, "dbo") == 0)
			{
				int16 dbid = get_dbid_from_physical_schema_name(physical_schema_name, false);
				loginId = get_role_oid(get_owner_of_db(get_db_name(dbid)), false);
			}
		}
		ReleaseSysCache(tuple);
	}

	return loginId;
}

static void
create_guest_role_for_db(const char *dbname)
{
	char	   *guest = get_guest_role_name(dbname);
	const char *db_owner_role = get_db_owner_role_name(dbname);
	List	   *logins = NIL;
	List	   *res;
	StringInfoData query;
	Node	   *stmt;
	ListCell   *res_item;
	int			i = 0;
	int16		old_dbid;
	char	   *old_dbname;
	int16		dbid = get_db_id(dbname);
	Oid 		save_userid;
	int 		save_sec_context;
	const char	*old_createrole_self_grant;

	initStringInfo(&query);
	appendStringInfo(&query, "CREATE ROLE dummy INHERIT ROLE dummy; ");
	logins = grant_guest_to_logins(&query);
	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	/* Replace dummy elements in parsetree with real values */
	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, guest, db_owner_role, NULL);
	pfree((char *) db_owner_role);

	if (list_length(logins) > 0)
	{
		stmt = parsetree_nth_stmt(res, i++);
		update_GrantRoleStmt(stmt, list_make1(make_accesspriv_node(guest)), logins);
	}

	GetUserIdAndSecContext(&save_userid, &save_sec_context);
	old_createrole_self_grant = pstrdup(GetConfigOption("createrole_self_grant", false, true));

	old_dbid = get_cur_db_id();
	old_dbname = get_cur_db_name();
	set_cur_db(dbid, dbname);	/* temporarily set current dbid as the new id */

	PG_TRY();
	{
		/*
		 * We have performed all the permissions checks.
		 * Set current user to bbf_role_admin for create permissions.
		 * Set createrole_self_grant to "inherit" so that bbf_role_admin
		 * inherits the new role.
		 */
		SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
		SetConfigOption("createrole_self_grant", "inherit", PGC_USERSET, PGC_S_OVERRIDE);
		/* Run all subcommands */
		foreach(res_item, res)
		{
			Node	   *res_stmt = ((RawStmt *) lfirst(res_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = res_stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 18;

			/* do this step */
			ProcessUtility(wrapper,
						   CREATE_LOGICAL_DATABASE,
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
		set_cur_db(old_dbid, old_dbname);
		add_to_bbf_authid_user_ext(guest, "guest", dbname, NULL, NULL, false, false, false);
	}
	PG_FINALLY();
	{
		/* Clean up. Restore previous state. */
		SetConfigOption("createrole_self_grant", old_createrole_self_grant, PGC_USERSET, PGC_S_OVERRIDE);
		SetUserIdAndSecContext(save_userid, save_sec_context);
		set_cur_db(old_dbid, old_dbname);
	}
	PG_END_TRY();

	pfree(guest);
}

/*
 * Retrieve the db_owner role name of a specific
 * database from the catalog, it doesn't rely on the
 * migration mode GUC.
 */
static char *
get_db_owner_role_name(const char *dbname)
{
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple_user_ext;
	ScanKeyData key[2];
	TableScanDesc scan;
	char	   *db_owner_role = NULL;

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_orig_username,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum("db_owner"));
	ScanKeyInit(&key[1],
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(dbname));

	scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 2, key);

	tuple_user_ext = heap_getnext(scan, ForwardScanDirection);
	if (HeapTupleIsValid(tuple_user_ext))
	{
		Form_authid_user_ext userform = (Form_authid_user_ext) GETSTRUCT(tuple_user_ext);

		db_owner_role = pstrdup(NameStr(userform->rolname));
	}

	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
	return db_owner_role;
}

void
rename_update_bbf_catalog(RenameStmt *stmt)
{
	switch (stmt->renameType)
	{
		/*
		 * In case of renaming a table, view, procedure and function, modify the object
		 * names present in all the Babelfish catalogs which stores these object names to
		 * have consistency with the new names.
		 *
		 * List of catalogs which are updated here:
		 * babelfish_schema_permissions, babelfish_function_ext, babelfish_view_def
		 */
		case OBJECT_TABLE:
			rename_object_update_bbf_schema_permission_catalog(stmt, stmt->renameType);
			break;
		case OBJECT_VIEW:
			rename_view_update_bbf_catalog(stmt);
			rename_object_update_bbf_schema_permission_catalog(stmt, stmt->renameType);
			break;
		case OBJECT_PROCEDURE:
			rename_procfunc_update_bbf_catalog(stmt);
			rename_object_update_bbf_schema_permission_catalog(stmt, stmt->renameType);
			break;
		case OBJECT_FUNCTION:
			rename_procfunc_update_bbf_catalog(stmt);
			rename_object_update_bbf_schema_permission_catalog(stmt, stmt->renameType);
			break;
		case OBJECT_SEQUENCE:
			break;
		case OBJECT_TRIGGER:
			break;
		case OBJECT_TYPE:
			break;
		case OBJECT_COLUMN:
			break;
		default:
			break;
	}
}

/*
 * rename_object_update_bbf_schema_permission_catalog
 *
 * In case of renaming a table, view, procedure and function, modify the 'object_name' in
 * 'babelfish_schema_permissions' to have consistency with the new names.
 */
static void
rename_object_update_bbf_schema_permission_catalog(RenameStmt *stmt, int rename_type)
{
	/* Update 'object_name' in 'babelfish_schema_permissions' */
	Relation	bbf_schema_rel;
	TupleDesc	bbf_schema_dsc;
	ScanKeyData key[4];
	HeapTuple	tuple_bbf_schema;
	HeapTuple	new_tuple;
	SysScanDesc scan;
	Datum		new_record_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS] = {0};
	bool		new_record_nulls_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS] = {false};
	bool		new_record_repl_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS] = {false};
	char		*logical_schema_name = NULL;
	char		*physical_schema_name = NULL;
	char		*object_name = NULL;
	const char	*object_type = NULL;
	int16		dbid = get_cur_db_id();
	ObjectWithArgs *objwargs;

	/* open the catalog table */
	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(), RowExclusiveLock);
	/* get the description of the table */
	bbf_schema_dsc = RelationGetDescr(bbf_schema_rel);

	if (rename_type == OBJECT_TABLE || rename_type == OBJECT_VIEW)
	{
		logical_schema_name = (char *) get_logical_schema_name(stmt->relation->schemaname, false);
		object_name = stmt->relation->relname;
		object_type = OBJ_RELATION;
	}
	else
	{
		if (rename_type == OBJECT_PROCEDURE)
			object_type = OBJ_PROCEDURE;
		else if (rename_type == OBJECT_FUNCTION)
			object_type = OBJ_FUNCTION;
		objwargs = (ObjectWithArgs *) stmt->object;
		DeconstructQualifiedName(objwargs->objname, &physical_schema_name, &object_name);
		logical_schema_name = (char *) get_logical_schema_name(physical_schema_name, false);
	}

	/* search for the row for update => build the key */
	ScanKeyInit(&key[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&key[1], 0,
				Anum_bbf_schema_perms_schema_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(logical_schema_name));
	ScanKeyEntryInitialize(&key[2], 0,
				Anum_bbf_schema_perms_object_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(object_name));
	ScanKeyEntryInitialize(&key[3], 0,
				Anum_bbf_schema_perms_object_type,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(object_type));

	/* scan */
	scan = systable_beginscan(bbf_schema_rel,
			get_bbf_schema_perms_oid(),
			false, NULL, 4, key);

	/* get the scan result -> original tuple */
	tuple_bbf_schema = systable_getnext(scan);

	/*
	 * If a permission on the same object is granted to multiple grantees,
	 * there can be multiple rows in the catalog corresponding to each grantee name.
	 * All such rows need to be updated with the new name.
	 *
	 * It is OK to not throw an error if an entry is not found in 'babelfish_schema_permissions'.
	 * Explaination: An entry is added to 'babelfish_schema_permissions' only if an object has an explicit GRANT on it.
	 * It is not necessary that each RENAME on an object has a GRANT of that object too.
	 * Hence, there can be missing entries.
	 */
	while (HeapTupleIsValid(tuple_bbf_schema))
	{
		/* create new tuple to substitute */
		new_record_bbf_schema[Anum_bbf_schema_perms_object_name - 1] = CStringGetTextDatum(stmt->newname);
		new_record_repl_bbf_schema[Anum_bbf_schema_perms_object_name - 1] = true;

		new_tuple = heap_modify_tuple(tuple_bbf_schema,
									bbf_schema_dsc,
									new_record_bbf_schema,
									new_record_nulls_bbf_schema,
									new_record_repl_bbf_schema);

		CatalogTupleUpdate(bbf_schema_rel, &new_tuple->t_self, new_tuple);

		heap_freetuple(new_tuple);
		tuple_bbf_schema = systable_getnext(scan);
	}

	if (physical_schema_name != NULL)
		pfree(physical_schema_name);
	if (logical_schema_name != NULL)
		pfree(logical_schema_name);

	systable_endscan(scan);
	table_close(bbf_schema_rel, RowExclusiveLock);
}

static void
rename_view_update_bbf_catalog(RenameStmt *stmt)
{
	/* update the 'object_name' in 'babelfish_view_def' */
	Relation	bbf_view_def_rel;
	TupleDesc	bbf_view_def_dsc;
	ScanKeyData key[3];
	HeapTuple	usertuple;
	HeapTuple	new_tuple;
	TableScanDesc tblscan;
	Datum		new_record_view_def[BBF_VIEW_DEF_NUM_COLS] = {0};
	bool		new_record_nulls_view_def[BBF_VIEW_DEF_NUM_COLS] = {false};
	bool		new_record_repl_view_def[BBF_VIEW_DEF_NUM_COLS] = {false};
	int16		dbid;
	const char *logical_schema_name;

	/* open the catalog table */
	bbf_view_def_rel = table_open(get_bbf_view_def_oid(), RowExclusiveLock);
	/* get the description of the table */
	bbf_view_def_dsc = RelationGetDescr(bbf_view_def_rel);

	/* search for the row for update => build the key */
	dbid = get_dbid_from_physical_schema_name(stmt->relation->schemaname, true);
	ScanKeyInit(&key[0],
				Anum_bbf_view_def_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	logical_schema_name = get_logical_schema_name(stmt->relation->schemaname, true);
	ScanKeyEntryInitialize(&key[1], 0, Anum_bbf_view_def_schema_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false), 
				F_TEXTEQ, CStringGetTextDatum(logical_schema_name));
	ScanKeyEntryInitialize(&key[2], 0,
				Anum_bbf_view_def_object_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(stmt->relation->relname));

	/* scan */
	tblscan = table_beginscan_catalog(bbf_view_def_rel, 3, key);

	/* get the scan result -> original tuple */
	usertuple = heap_getnext(tblscan, ForwardScanDirection);

	if (!HeapTupleIsValid(usertuple))
	{
		table_endscan(tblscan);
		table_close(bbf_view_def_rel, RowExclusiveLock);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("Cannot find the view_name \"%s\", because it does not exist or you do not have permission.", stmt->subname)));
	}

	/* create new tuple to substitute */
	new_record_view_def[Anum_bbf_view_def_object_name - 1] = CStringGetTextDatum(stmt->newname);
	new_record_repl_view_def[Anum_bbf_view_def_object_name - 1] = true;

	new_tuple = heap_modify_tuple(usertuple,
								  bbf_view_def_dsc,
								  new_record_view_def,
								  new_record_nulls_view_def,
								  new_record_repl_view_def);

	CatalogTupleUpdate(bbf_view_def_rel, &new_tuple->t_self, new_tuple);

	heap_freetuple(new_tuple);

	table_endscan(tblscan);
	table_close(bbf_view_def_rel, RowExclusiveLock);
}

static void
rename_procfunc_update_bbf_catalog(RenameStmt *stmt)
{
	/*
	 * update the 'funcname', 'orig_name', 'funcsignature' in
	 * 'babelfish_function_ext'
	 */
	Relation	bbf_func_ext_rel;
	TupleDesc	bbf_func_ext_dsc;
	ScanKeyData key[2];
	HeapTuple	usertuple;
	HeapTuple	sec_tuple;
	HeapTuple	new_tuple;
	TableScanDesc tblscan;
	Datum		new_record_func_ext[BBF_FUNCTION_EXT_NUM_COLS] = {0};
	bool		new_record_nulls_func_ext[BBF_FUNCTION_EXT_NUM_COLS] = {false};
	bool		new_record_repl_func_ext[BBF_FUNCTION_EXT_NUM_COLS] = {false};
	NameData   *objname_data;
	NameData    newname_data;
	NameData   *schemaname_data;
	bool		is_null;
	char	   *funcsign;
	StringInfoData new_funcsign;
	Datum		funcsign_datum;
	Node	   *schema;
	char	   *schemaname;
	ObjectWithArgs *objwargs = (ObjectWithArgs *) stmt->object;

	/* open the catalog table */
	bbf_func_ext_rel = table_open(get_bbf_function_ext_oid(), RowExclusiveLock);

	/* get the description of the table */
	bbf_func_ext_dsc = RelationGetDescr(bbf_func_ext_rel);

	/* search for the row for update => build the key */
	/* Keys: schema_name, obj_name */
	schema = (Node *) linitial(objwargs->objname);
	schemaname = strVal(schema);
	schemaname_data = (NameData *) palloc0(NAMEDATALEN);
	snprintf(schemaname_data->data, NAMEDATALEN, "%s", schemaname);
	ScanKeyInit(&key[0],
				Anum_bbf_function_ext_nspname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(schemaname_data));
	objname_data = (NameData *) palloc0(NAMEDATALEN);
	snprintf(objname_data->data, NAMEDATALEN, "%s", stmt->subname);
	ScanKeyInit(&key[1],
				Anum_bbf_function_ext_funcname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(objname_data));

	/* scan */
	tblscan = table_beginscan_catalog(bbf_func_ext_rel, 2, key);

	/* get the scan result -> original tuple */
	usertuple = heap_getnext(tblscan, ForwardScanDirection);

	if (!HeapTupleIsValid(usertuple))
	{
		table_endscan(tblscan);
		table_close(bbf_func_ext_rel, RowExclusiveLock);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("Cannot find the object \"%s\", because it does not exist or you do not have permission.", stmt->subname)));
	}

	/* create new tuple to substitute */
	funcsign_datum = heap_getattr(usertuple, Anum_bbf_function_ext_funcsignature,
								  bbf_func_ext_rel->rd_att, &is_null);
	funcsign = pstrdup(TextDatumGetCString(funcsign_datum));
	/* get new funcsignature */
	initStringInfo(&new_funcsign);
	appendStringInfoString(&new_funcsign, stmt->newname);
	appendStringInfoString(&new_funcsign, strrchr(funcsign, '('));
	namestrcpy(&newname_data, stmt->newname);

	new_record_func_ext[Anum_bbf_function_ext_funcname - 1] = NameGetDatum(&newname_data);
	new_record_func_ext[Anum_bbf_function_ext_funcsignature - 1] = CStringGetTextDatum(new_funcsign.data);
	new_record_repl_func_ext[Anum_bbf_function_ext_funcname - 1] = true;
	new_record_repl_func_ext[Anum_bbf_function_ext_funcsignature - 1] = true;
	if (orig_proc_funcname != NULL)
	{
		new_record_func_ext[Anum_bbf_function_ext_orig_name - 1] = CStringGetTextDatum(orig_proc_funcname);
		new_record_repl_func_ext[Anum_bbf_function_ext_orig_name - 1] = true;
	}

	new_tuple = heap_modify_tuple(usertuple,
								  bbf_func_ext_dsc,
								  new_record_func_ext,
								  new_record_nulls_func_ext,
								  new_record_repl_func_ext);

	/* if there is more than 1 match, throw error */
	sec_tuple = heap_getnext(tblscan, ForwardScanDirection);
	if (HeapTupleIsValid(sec_tuple))
	{
		orig_proc_funcname = NULL;
		table_endscan(tblscan);
		table_close(bbf_func_ext_rel, RowExclusiveLock);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("There are multiple objects with the given name \"%s\".", stmt->subname)));
	}

	CatalogTupleUpdate(bbf_func_ext_rel, &new_tuple->t_self, new_tuple);

	orig_proc_funcname = NULL;
	heap_freetuple(new_tuple);

	table_endscan(tblscan);
	table_close(bbf_func_ext_rel, RowExclusiveLock);
}

/*
 * Add an entry to catalog BABELFISH_SCHEMA_PERMISSIONS.
 */
void
add_entry_to_bbf_schema_perms(const char *schema_name,
				const char *object_name,
				int permission,
				const char *grantee,
				const char *object_type,
				const char *func_args)
{
	Relation	bbf_schema_rel;
	TupleDesc	bbf_schema_dsc;
	HeapTuple	tuple_bbf_schema;
	Datum		new_record_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS];
	bool		new_record_nulls_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS];
	int16	dbid = get_cur_db_id();

	/* Immediately return, if grantee is NULL or PUBLIC. */
	if ((grantee == NULL) || (strcmp(grantee, PUBLIC_ROLE_NAME) == 0))
		return;

	/* Fetch the relation */
	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
									RowExclusiveLock);
	bbf_schema_dsc = RelationGetDescr(bbf_schema_rel);

	/* Build a tuple to insert */
	MemSet(new_record_bbf_schema, 0, sizeof(new_record_bbf_schema));
	MemSet(new_record_nulls_bbf_schema, false, sizeof(new_record_nulls_bbf_schema));

	new_record_bbf_schema[Anum_bbf_schema_perms_dbid - 1] = Int16GetDatum(dbid);
	new_record_bbf_schema[Anum_bbf_schema_perms_schema_name - 1] = CStringGetTextDatum(pstrdup(schema_name));
	new_record_bbf_schema[Anum_bbf_schema_perms_object_name - 1] = CStringGetTextDatum(pstrdup(object_name));
	new_record_bbf_schema[Anum_bbf_schema_perms_permission - 1] = Int32GetDatum(permission);
	new_record_bbf_schema[Anum_bbf_schema_perms_grantee - 1] = CStringGetTextDatum(pstrdup(grantee));
	new_record_bbf_schema[Anum_bbf_schema_perms_object_type - 1] = CStringGetTextDatum(pstrdup(object_type));
	if (func_args)
		new_record_bbf_schema[Anum_bbf_schema_perms_function_args - 1] = CStringGetTextDatum(func_args);
	else
		new_record_nulls_bbf_schema[Anum_bbf_schema_perms_function_args - 1] = true;
	new_record_nulls_bbf_schema[Anum_bbf_schema_perms_grantor - 1] = true;

	tuple_bbf_schema = heap_form_tuple(bbf_schema_dsc,
									new_record_bbf_schema,
									new_record_nulls_bbf_schema);

	/* Insert new record in the bbf_authid_user_ext table */
	CatalogTupleInsert(bbf_schema_rel, tuple_bbf_schema);

	/* Close bbf_authid_user_ext, but keep lock till commit */
	table_close(bbf_schema_rel, RowExclusiveLock);

	/* make sure later steps can see the entry added here */
	CommandCounterIncrement();
}

/*
 * Updates the permission column for a particular row in BABELFISH_SCHEMA_PERMISSIONS table.
 */
void
update_privileges_of_object(const char *schema_name,
				const char *object_name,
				int new_permission,
				const char *grantee,
				const char *object_type,
				bool is_grant)
{
	Relation	bbf_schema_rel;
	HeapTuple	tuple_bbf_schema;
	TupleDesc	bbf_schema_dsc;
	HeapTuple	new_tuple;
	ScanKeyData scanKey[5];
	SysScanDesc scan;
	int16	dbid = get_cur_db_id();
	int old_permission = 0;
	int current_permission = 0;
	Datum		new_record_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS];
	bool		new_record_nulls_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS];
	bool		new_record_repl_bbf_schema[BBF_SCHEMA_PERMS_NUM_OF_COLS];

	/* Immediately return false, if SCHEMA name is NULL or it's a shared schema. */
	if (schema_name == NULL || is_shared_schema(schema_name))
		return;

	/* Immediately return, if grantee is NULL or PUBLIC. */
	if ((grantee == NULL) || (strcmp(grantee, PUBLIC_ROLE_NAME) == 0))
		return;

	/* Get existing privilege of an object. */
	old_permission = get_privilege_of_object(schema_name, object_name, grantee, object_type);

	if (is_grant)
	{
		/*
		 * In case of GRANT, we add the new privilege along with the previous privilege in the column.
		 */
		current_permission = old_permission | new_permission;
	}
	else
	{
		/*
		 * In case of REVOKE, we remove the new privilege and keep the previous privilege as it is.
		 */
		current_permission = old_permission & ~new_permission;
	}

	if (current_permission == 0)
	{
		remove_entry_from_bbf_schema_perms(schema_name, object_name, grantee, object_type);
		return;
	}

	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
							RowExclusiveLock);

	ScanKeyInit(&scanKey[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_schema_perms_schema_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(schema_name));
	ScanKeyEntryInitialize(&scanKey[2], 0,
				Anum_bbf_schema_perms_object_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(object_name));
	ScanKeyInit(&scanKey[3],
				Anum_bbf_schema_perms_permission,
				BTEqualStrategyNumber, F_INT4EQ,
				Int32GetDatum(old_permission));
	ScanKeyEntryInitialize(&scanKey[4], 0,
				Anum_bbf_schema_perms_grantee,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(grantee));

	scan = systable_beginscan(bbf_schema_rel,
				get_bbf_schema_perms_idx_oid(),
				false, NULL, 5, scanKey);

	tuple_bbf_schema = systable_getnext(scan);
	if (HeapTupleIsValid(tuple_bbf_schema))
	{
		bbf_schema_dsc = RelationGetDescr(bbf_schema_rel);
		/* Build a tuple to insert */
		MemSet(new_record_bbf_schema, 0, sizeof(new_record_bbf_schema));
		MemSet(new_record_nulls_bbf_schema, false, sizeof(new_record_nulls_bbf_schema));
		MemSet(new_record_repl_bbf_schema, false, sizeof(new_record_repl_bbf_schema));

		new_record_bbf_schema[Anum_bbf_schema_perms_permission - 1] = Int32GetDatum(current_permission);
		new_record_repl_bbf_schema[Anum_bbf_schema_perms_permission - 1] = true;

		new_tuple = heap_modify_tuple(tuple_bbf_schema,
									bbf_schema_dsc,
									new_record_bbf_schema,
									new_record_nulls_bbf_schema,
									new_record_repl_bbf_schema);

		CatalogTupleUpdate(bbf_schema_rel, &new_tuple->t_self, new_tuple);
		heap_freetuple(new_tuple);
	}

	systable_endscan(scan);
	table_close(bbf_schema_rel, RowExclusiveLock);

	/* make sure later steps can see the entry updated here */
	CommandCounterIncrement();
}

/*
 * Checks if a particular privilege exists in catalog BABELFISH_SCHEMA_PERMISSIONS.
 */
bool
privilege_exists_in_bbf_schema_permissions(const char *schema_name,
							const char *object_name,
							const char *grantee)
{
	Relation	bbf_schema_rel;
	HeapTuple	tuple_bbf_schema;
	SysScanDesc	scan;
	bool	catalog_entry_exists = false;
	int16	dbid = get_cur_db_id();

	/* Immediately return false, if SCHEMA name is NULL or it's a shared schema. */
	if (schema_name == NULL || is_shared_schema(schema_name))
		return false;

	if (grantee != NULL)
	{
		ScanKeyData	scanKey[4];
		/* Immediately return false, if grantee is PUBLIC. */
		if (strcmp(grantee, PUBLIC_ROLE_NAME) == 0)
			return false;

		bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
										AccessShareLock);
		ScanKeyInit(&scanKey[0],
					Anum_bbf_schema_perms_dbid,
					BTEqualStrategyNumber, F_INT2EQ,
					Int16GetDatum(dbid));
		ScanKeyEntryInitialize(&scanKey[1], 0,
					Anum_bbf_schema_perms_schema_name,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(schema_name));
		ScanKeyEntryInitialize(&scanKey[2], 0,
					Anum_bbf_schema_perms_object_name,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(object_name));
		ScanKeyEntryInitialize(&scanKey[3], 0,
					Anum_bbf_schema_perms_grantee,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(grantee));
		scan = systable_beginscan(bbf_schema_rel,
					get_bbf_schema_perms_idx_oid(),
					true, NULL, 4, scanKey);
	}
	else
	{
		ScanKeyData	scanKey[3];
		bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
										AccessShareLock);
		ScanKeyInit(&scanKey[0],
					Anum_bbf_schema_perms_dbid,
					BTEqualStrategyNumber, F_INT2EQ,
					Int16GetDatum(dbid));
		ScanKeyEntryInitialize(&scanKey[1], 0,
					Anum_bbf_schema_perms_schema_name,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(schema_name));
		ScanKeyEntryInitialize(&scanKey[2], 0,
					Anum_bbf_schema_perms_object_name,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(object_name));

		scan = systable_beginscan(bbf_schema_rel,
					get_bbf_schema_perms_idx_oid(),
					true, NULL, 3, scanKey);
	}

	tuple_bbf_schema = systable_getnext(scan);
	if (HeapTupleIsValid(tuple_bbf_schema))
		catalog_entry_exists = true;

	systable_endscan(scan);
	table_close(bbf_schema_rel, AccessShareLock);
	return catalog_entry_exists;
}

/*
 * Get the value of permission column from BABELFISH_SCHEMA_PERMISSIONS table.
 */
static int
get_privilege_of_object(const char *schema_name,
					const char *object_name,
					const char *grantee,
					const char *object_type)
{
	Relation	bbf_schema_rel;
	HeapTuple	tuple_bbf_schema;
	ScanKeyData	scanKey[5];
	SysScanDesc	scan;
	int16	dbid = get_cur_db_id();
	int permission = 0;

	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
									AccessShareLock);
	ScanKeyInit(&scanKey[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_schema_perms_schema_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(schema_name));
	ScanKeyEntryInitialize(&scanKey[2], 0,
				Anum_bbf_schema_perms_object_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(object_name));
	ScanKeyEntryInitialize(&scanKey[3], 0,
				Anum_bbf_schema_perms_grantee,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(grantee));
	ScanKeyEntryInitialize(&scanKey[4], 0,
				Anum_bbf_schema_perms_object_type,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(object_type));
	scan = systable_beginscan(bbf_schema_rel,
				get_bbf_schema_perms_idx_oid(),
				true, NULL, 5, scanKey);
	tuple_bbf_schema = systable_getnext(scan);

	if (HeapTupleIsValid(tuple_bbf_schema))
	{
		Datum datum;
		bool isnull;
		datum = heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_permission, RelationGetDescr(bbf_schema_rel), &isnull);
		permission = DatumGetInt32(datum);
	}

	systable_endscan(scan);
	table_close(bbf_schema_rel, AccessShareLock);
	return permission;
}

/*
 * Removes a row from the catalog BABELFISH_SCHEMA_PERMISSIONS.
 */
void
remove_entry_from_bbf_schema_perms(const char *schema_name,
				  const char *object_name,
				  const char *grantee,
				  const char *object_type)
{
	Relation	bbf_schema_rel;
	HeapTuple	tuple_bbf_schema;
	ScanKeyData scanKey[5];
	SysScanDesc scan;
	int16	dbid = get_cur_db_id();

	/* Immediately return false, if SCHEMA name is NULL or it's a shared schema. */
	if (schema_name == NULL || is_shared_schema(schema_name))
		return;

	/* Immediately return, if grantee is NULL or PUBLIC. */
	if ((grantee == NULL) || (strcmp(grantee, PUBLIC_ROLE_NAME) == 0))
		return;

	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
									RowExclusiveLock);
	ScanKeyInit(&scanKey[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_schema_perms_schema_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(schema_name));
	ScanKeyEntryInitialize(&scanKey[2], 0,
				Anum_bbf_schema_perms_object_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(object_name));
	ScanKeyEntryInitialize(&scanKey[3], 0,
				Anum_bbf_schema_perms_grantee,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(grantee));
	ScanKeyEntryInitialize(&scanKey[4], 0,
				Anum_bbf_schema_perms_object_type,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(object_type));
	scan = systable_beginscan(bbf_schema_rel,
				get_bbf_schema_perms_idx_oid(),
				true, NULL, 5, scanKey);

	tuple_bbf_schema = systable_getnext(scan);

	if (HeapTupleIsValid(tuple_bbf_schema))
		CatalogTupleDelete(bbf_schema_rel, &tuple_bbf_schema->t_self);

	systable_endscan(scan);
	table_close(bbf_schema_rel, RowExclusiveLock);
}

/*
 * Add an entry to BABELFISH_SCHEMA_PERMISSIONS table, if it doesn't exist already.
 * If exists, updates the PERMISSION column in the table.
 */
void
add_or_update_object_in_bbf_schema(const char *schema_name,
				const char *object_name,
				int new_permission,
				const char *grantee,
				const char *object_type,
				bool is_grant,
				const char *func_args)
{
	if (!privilege_exists_in_bbf_schema_permissions(schema_name, object_name, grantee))
		add_entry_to_bbf_schema_perms(schema_name, object_name, new_permission, grantee, object_type, func_args);
	else
		update_privileges_of_object(schema_name, object_name, new_permission, grantee, object_type, is_grant);
}

/*
 * Removes all the rows corresponding to an OBJECT/SCHEMA from the catalog BABELFISH_SCHEMA_PERMISSIONS.
 */
void
clean_up_bbf_schema_permissions(const char *schema_name,
				  const char *object_name,
				  bool is_schema)
{
	SysScanDesc scan;
	Relation	bbf_schema_rel;
	HeapTuple	tuple_bbf_schema;
	int16	dbid = get_cur_db_id();

	/* Immediately return false, if SCHEMA name is NULL or it's a shared schema. */
	if (schema_name == NULL || is_shared_schema(schema_name))
		return;

	/* Fetch the relation */
	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
									RowExclusiveLock);

	if (is_schema)
	{
		ScanKeyData scanKey[2];
		ScanKeyInit(&scanKey[0],
					Anum_bbf_schema_perms_dbid,
					BTEqualStrategyNumber, F_INT2EQ,
					Int16GetDatum(dbid));
		ScanKeyEntryInitialize(&scanKey[1], 0,
					Anum_bbf_schema_perms_schema_name,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(schema_name));
		scan = systable_beginscan(bbf_schema_rel,
					get_bbf_schema_perms_idx_oid(),
					true, NULL, 2, scanKey);
	}
	else
	{
		ScanKeyData scanKey[3];
		ScanKeyInit(&scanKey[0],
					Anum_bbf_schema_perms_dbid,
					BTEqualStrategyNumber, F_INT2EQ,
					Int16GetDatum(dbid));
		ScanKeyEntryInitialize(&scanKey[1], 0,
					Anum_bbf_schema_perms_schema_name,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(schema_name));
		ScanKeyEntryInitialize(&scanKey[2], 0,
					Anum_bbf_schema_perms_object_name,
					BTEqualStrategyNumber,
					InvalidOid,
					tsql_get_database_or_server_collation_oid_internal(false),
					F_TEXTEQ,
					CStringGetTextDatum(object_name));
		scan = systable_beginscan(bbf_schema_rel,
					get_bbf_schema_perms_idx_oid(),
					true, NULL, 3, scanKey);
	}

	while ((tuple_bbf_schema = systable_getnext(scan)) != NULL)
	{
		if (HeapTupleIsValid(tuple_bbf_schema))
			CatalogTupleDelete(bbf_schema_rel,
							   &tuple_bbf_schema->t_self);
	}

	systable_endscan(scan);
	table_close(bbf_schema_rel, RowExclusiveLock);
}

/*
 * Clean up babelfish_schema_permissions table for a given database
 * when database is dropped.
 */
void
drop_bbf_schema_permission_entries(int16 dbid)
{
	Relation	bbf_schema_rel;
	HeapTuple	tuple_bbf_schema;
	ScanKeyData scanKey[1];
	SysScanDesc scan;

	/* Fetch the relation */
	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(), RowExclusiveLock);

	/* Search and drop the entries */
	ScanKeyInit(&scanKey[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	scan = systable_beginscan(bbf_schema_rel,
							  get_bbf_schema_perms_idx_oid(),
							  true, NULL, 1, scanKey);

	while ((tuple_bbf_schema = systable_getnext(scan)) != NULL)
	{
		if (HeapTupleIsValid(tuple_bbf_schema))
			CatalogTupleDelete(bbf_schema_rel,
							   &tuple_bbf_schema->t_self);
	}

	systable_endscan(scan);
	table_close(bbf_schema_rel, RowExclusiveLock);
}

/*
 * For all objects belonging to a schema which has OBJECT level permission,
 * It grants the permission explicitly when REVOKE has been executed on that
 * specific schema.
 */
void
grant_perms_to_objects_in_schema(const char *schema_name,
				  int permission,
				  const char *grantee)
{
	SysScanDesc scan;
	Relation	bbf_schema_rel;
	TupleDesc	dsc;
	HeapTuple	tuple_bbf_schema;
	ScanKeyData scanKey[3];
	int16		dbid = get_cur_db_id();
	const char *db_name = get_cur_db_name();

	/* Fetch the relation */
	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
									AccessShareLock);
	dsc = RelationGetDescr(bbf_schema_rel);
	ScanKeyInit(&scanKey[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_schema_perms_schema_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(schema_name));
	ScanKeyEntryInitialize(&scanKey[2], 0,
				Anum_bbf_schema_perms_grantee,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(grantee));

	scan = systable_beginscan(bbf_schema_rel, get_bbf_schema_perms_idx_oid(),
							true, NULL, 3, scanKey);
	tuple_bbf_schema = systable_getnext(scan);

	while (HeapTupleIsValid(tuple_bbf_schema))
	{
		bool isnull;
		Datum datum;
		const char	*object_name;
		const char	*object_type;
		const char	*func_args = NULL;
		int		current_permission;
		object_name = TextDatumGetCString(heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_object_name, dsc, &isnull));
		object_type = TextDatumGetCString(heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_object_type, dsc, &isnull));
		current_permission = DatumGetInt32(heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_permission, dsc, &isnull));
		datum = heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_function_args, dsc, &isnull);
		if (!isnull)
			func_args = TextDatumGetCString(datum);
		/* For each object, grant the permission explicitly. */
		if (strcmp(object_name, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA) != 0)
		{
			const char	*query = NULL;
			char			*schema;
			List			*res;
			GrantStmt		*grant;
			PlannedStmt		*wrapper;
			const char		*priv_name;

			schema = get_physical_schema_name((char *)db_name, schema_name);
			/* Check if the permission to be REVOKED on SCHEMA exists on the OBJECT. */

			if (current_permission & permission)
			{
				priv_name = privilege_to_string(permission);
				if (strcmp(object_type, OBJ_RELATION) == 0)
					query = psprintf("GRANT %s ON [%s].[%s] TO %s", priv_name, schema, object_name, grantee);
				else if (strcmp(object_type, OBJ_FUNCTION) == 0)
					query = psprintf("GRANT %s ON FUNCTION [%s].[%s](%s) TO %s", priv_name, schema, object_name, func_args, grantee);
				else if (strcmp(object_type, OBJ_PROCEDURE) == 0)
					query = psprintf("GRANT %s ON PROCEDURE [%s].[%s](%s) TO %s", priv_name, schema, object_name, func_args, grantee);
				res = raw_parser(query, RAW_PARSE_DEFAULT);
				grant = (GrantStmt *) parsetree_nth_stmt(res, 0);

				/* need to make a wrapper PlannedStmt */
				wrapper = makeNode(PlannedStmt);
				wrapper->commandType = CMD_UTILITY;
				wrapper->canSetTag = false;
				wrapper->utilityStmt = (Node *) grant;
				wrapper->stmt_location = 0;
				wrapper->stmt_len = 1;

				/* do this step */
				ProcessUtility(wrapper,
							INTERNAL_GRANT_STATEMENT,
							false,
							PROCESS_UTILITY_SUBCOMMAND,
							NULL,
							NULL,
							None_Receiver,
							NULL);
			}
		}
		tuple_bbf_schema = systable_getnext(scan);
	}
	systable_endscan(scan);
	table_close(bbf_schema_rel, AccessShareLock);
}

/*
 * For a new object(function/procedure) belonging to a schema where EXECUTE privilege has been
 * granted explicitly to any user, this function grants the EXECUTE permission to those users
 * implicitly at the time of CREATE function/procedure.
 */
void
exec_internal_grant_on_function(Oid objectId)
{
	SysScanDesc scan;
	Relation	bbf_schema_rel;
	TupleDesc	dsc;
	HeapTuple	tuple_bbf_schema;
	HeapTuple	proc_tuple;
	const char	*grantee = NULL;
	int			current_permission;
	ScanKeyData scanKey[3];
	int16		dbid = get_cur_db_id();
	Oid 		phy_sch_oid;
	char 		*object_name;
	char 		*schema;
	const char 	*logicalschema;
	char 		object_type;
	Form_pg_proc	procedureStruct;

	/* TSQL specific behavior */
	if (sql_dialect != SQL_DIALECT_TSQL || !IS_TDS_CONN())
		return;

	proc_tuple = SearchSysCache1(PROCOID,
								ObjectIdGetDatum(objectId));
	if (!HeapTupleIsValid(proc_tuple))
		elog(ERROR, "cache lookup failed for function %u", objectId);

	procedureStruct = (Form_pg_proc) GETSTRUCT(proc_tuple);

	object_name = NameStr(procedureStruct->proname);
	phy_sch_oid = procedureStruct->pronamespace;
	schema = get_namespace_name(phy_sch_oid);
	logicalschema = get_logical_schema_name(schema, true);
	object_type = procedureStruct->prokind;

	/* Fetch the relation */
	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
									AccessShareLock);
	dsc = RelationGetDescr(bbf_schema_rel);
	ScanKeyInit(&scanKey[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_schema_perms_schema_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(logicalschema));
	ScanKeyEntryInitialize(&scanKey[2], 0,
				Anum_bbf_schema_perms_object_name,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA));

	scan = systable_beginscan(bbf_schema_rel, get_bbf_schema_perms_idx_oid(),
							true, NULL, 3, scanKey);
	tuple_bbf_schema = systable_getnext(scan);

	while (HeapTupleIsValid(tuple_bbf_schema))
	{
		bool isnull;
		Datum datum;
		current_permission = DatumGetInt32(heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_permission, dsc, &isnull));
		datum = heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_grantee, dsc, &isnull);
		if (!isnull)
			grantee = TextDatumGetCString(datum);
		/* For each object, grant the permission explicitly. */
		if (current_permission & ALL_PERMISSIONS_ON_FUNCTION)
		{
			const char	*query = NULL;
			List			*res;
			GrantStmt		*grant;
			PlannedStmt		*wrapper;
			Oid     		save_userid;
			int     		save_sec_context;

			if (object_type == PROKIND_FUNCTION)
				query = psprintf("GRANT EXECUTE ON FUNCTION [%s].[%s] TO %s", schema, object_name, grantee);
			else if (object_type == PROKIND_PROCEDURE)
				query = psprintf("GRANT EXECUTE ON PROCEDURE [%s].[%s] TO %s", schema, object_name, grantee);
			res = raw_parser(query, RAW_PARSE_DEFAULT);
			grant = (GrantStmt *) parsetree_nth_stmt(res, 0);

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = (Node *) grant;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 1;

			GetUserIdAndSecContext(&save_userid, &save_sec_context);

			PG_TRY();
			{
				/*
				 * babelfish routines could be transferred to schema owner during creation so
				 * current user may not have grant privilege on this routine when we reach here
				 */
				SetUserIdAndSecContext(procedureStruct->proowner, save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

				ProcessUtility(wrapper,
							INTERNAL_GRANT_STATEMENT,
							false,
							PROCESS_UTILITY_SUBCOMMAND,
							NULL,
							NULL,
							None_Receiver,
							NULL);
			}
			PG_FINALLY();
			{
				SetUserIdAndSecContext(save_userid, save_sec_context);
			}
			PG_END_TRY();
		}
		tuple_bbf_schema = systable_getnext(scan);
	}
	systable_endscan(scan);
	table_close(bbf_schema_rel, AccessShareLock);
	pfree(schema);
	ReleaseSysCache(proc_tuple);
}

PG_FUNCTION_INFO_V1(update_user_catalog_for_guest_schema);
Datum
update_user_catalog_for_guest_schema(PG_FUNCTION_ARGS)
{
	Relation	db_rel;
	TableScanDesc scan;
	HeapTuple	tuple;
	bool		is_null;

	db_rel = table_open(sysdatabases_oid, AccessShareLock);
	scan = table_beginscan_catalog(db_rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		Datum		db_name_datum = heap_getattr(tuple, Anum_sysdatabases_name,
												 db_rel->rd_att, &is_null);
		const char *db_name = TextDatumGetCString(db_name_datum);

		alter_guest_schema_for_db(db_name);
		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	table_endscan(scan);
	table_close(db_rel, AccessShareLock);
	PG_RETURN_INT32(0);
}

static void
alter_guest_schema_for_db (const char *dbname)
{
	Relation	bbf_authid_user_ext_rel;
	TupleDesc	bbf_authid_user_ext_dsc;
	ScanKeyData key[2];
	HeapTuple	usertuple;
	HeapTuple	new_tuple;
	TableScanDesc tblscan;
	Datum		new_record_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		new_record_nulls_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		new_record_repl_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);
	bbf_authid_user_ext_dsc = RelationGetDescr(bbf_authid_user_ext_rel);

	/* Search and obtain the tuple based on the user name and db name */
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_orig_username,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum("guest"));
	ScanKeyInit(&key[1],
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(dbname));

	tblscan = table_beginscan_catalog(bbf_authid_user_ext_rel, 2, key);

	/* Build a tuple to insert */
	MemSet(new_record_user_ext, 0, sizeof(new_record_user_ext));
	MemSet(new_record_nulls_user_ext, false, sizeof(new_record_nulls_user_ext));
	MemSet(new_record_repl_user_ext, false, sizeof(new_record_repl_user_ext));

	usertuple = heap_getnext(tblscan, ForwardScanDirection);
	if (!HeapTupleIsValid(usertuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("Cannot find the user \"guest\", because it does not exist or you do not have permission.")));

	new_record_user_ext[USER_EXT_DEFAULT_SCHEMA_NAME] = CStringGetTextDatum("guest");
	new_record_repl_user_ext[USER_EXT_DEFAULT_SCHEMA_NAME] = true;
	new_tuple = heap_modify_tuple(usertuple,
								  bbf_authid_user_ext_dsc,
								  new_record_user_ext,
								  new_record_nulls_user_ext,
								  new_record_repl_user_ext);

	CatalogTupleUpdate(bbf_authid_user_ext_rel, &new_tuple->t_self, new_tuple);

	heap_freetuple(new_tuple);

	table_endscan(tblscan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
}

/*
 * Update the owner of a database in the catalog.
 */
void
update_db_owner(const char *new_owner_name, const char *db_name)
{
	volatile 		Relation sysdatabases_rel;
	TupleDesc		sysdatabases_rel_descr;
	ScanKeyData		key;
	HeapTuple		tuple, db_found;
	TableScanDesc	tblscan;
	NameData    	new_owner_namedata;
		
	Datum		values[SYSDATABASES_NUM_COLS];
	bool		nulls[SYSDATABASES_NUM_COLS];
	bool		replaces[SYSDATABASES_NUM_COLS];

	/* Do not allow changes to system databases. */
	/* Note: T-SQL allows changing ownership of msdb. */
	if ( (strlen(db_name) == 6 && (strncmp(db_name, "master", 6) == 0)) ||
		 (strlen(db_name) == 6 && (strncmp(db_name, "tempdb", 6) == 0))
	    )
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Cannot change the owner of the master, model, tempdb or distribution database.")));
	}

	/* Find the database */
	sysdatabases_rel = table_open(sysdatabases_oid, RowExclusiveLock);
	sysdatabases_rel_descr = RelationGetDescr(sysdatabases_rel);	

	ScanKeyInit(&key,
				Anum_sysdatabases_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(db_name));
				
	tblscan = table_beginscan_catalog(sysdatabases_rel, 1, &key);
	
	db_found = heap_getnext(tblscan, ForwardScanDirection);

	if (!db_found)
	{
		/* Database should have been verified to exist, but if not, exit politely */
		table_close(sysdatabases_rel, RowExclusiveLock);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist", db_name)));
	}
	
	/* Build a tuple */
	MemSet(values, 0, sizeof(values));
	MemSet(nulls, false, sizeof(nulls));
	MemSet(replaces, false, sizeof(replaces));
	namestrcpy(&new_owner_namedata, new_owner_name);
		
	/* Set up the new owner. */
	values[Anum_sysdatabases_owner - 1]   = NameGetDatum(&new_owner_namedata);
	replaces[Anum_sysdatabases_owner - 1] = true;	
								  
	tuple = heap_modify_tuple(db_found,
							  sysdatabases_rel_descr,
							  values,
							  nulls,
							  replaces);							  

	/* Perform the actual catalog update. */
	CatalogTupleUpdate(sysdatabases_rel, &tuple->t_self, tuple);
	
	/* Cleanup. */
	heap_freetuple(tuple);
	table_endscan(tblscan);	
	table_close(sysdatabases_rel, RowExclusiveLock);	
}

/*
 * Update the name of a database in the sysdatabases catalog.
 */
void
update_sysdatabases_db_name(const char *old_db_name, const char *new_db_name)
{
	volatile 		Relation sysdatabases_rel;
	TupleDesc		sysdatabases_rel_descr;
	ScanKeyData		key;
	HeapTuple		tuple, db_found;
	TableScanDesc	tblscan;
		
	Datum		values[SYSDATABASES_NUM_COLS];
	bool		nulls[SYSDATABASES_NUM_COLS];
	bool		replaces[SYSDATABASES_NUM_COLS];

	sysdatabases_rel = table_open(sysdatabases_oid, RowExclusiveLock);
	sysdatabases_rel_descr = RelationGetDescr(sysdatabases_rel);	

	ScanKeyInit(&key,
				Anum_sysdatabases_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(old_db_name));
				
	tblscan = table_beginscan_catalog(sysdatabases_rel, 1, &key);
	
	db_found = heap_getnext(tblscan, ForwardScanDirection);

	if (!db_found)
	{
		/* Database should have been verified to exist, but if not, exit politely. */
		table_close(sysdatabases_rel, RowExclusiveLock);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist", old_db_name)));
	}
	
	/* Build a tuple */
	MemSet(values, 0, sizeof(values));
	MemSet(nulls, false, sizeof(nulls));
	MemSet(replaces, false, sizeof(replaces));
		
	/* Set up the new database. */
	values[Anum_sysdatabases_name - 1]   = CStringGetTextDatum(new_db_name);
	replaces[Anum_sysdatabases_name - 1] = true;	
								  
	tuple = heap_modify_tuple(db_found,
							  sysdatabases_rel_descr,
							  values,
							  nulls,
							  replaces);							  

	/* Perform the actual catalog update. */
	CatalogTupleUpdate(sysdatabases_rel, &tuple->t_self, tuple);
	
	/* Cleanup. */
	heap_freetuple(tuple);
	table_endscan(tblscan);	
	table_close(sysdatabases_rel, RowExclusiveLock);	
}

/*
 * Update the physical schema name in the babelfish_namespace_ext catalog.
 * It returns the List of Original schema names which can be used to
 * produce the new schema name after rename db.
 */
static List*
update_babelfish_namespace_ext_rename_db(int16 db_id, char *new_db_name)
{
	volatile		Relation namespace_rel;
	TupleDesc		namespace_rel_descr;
	ScanKeyData		key;
	HeapTuple		old_tuple, new_tuple;
	SysScanDesc		tblscan;
	List			*list_of_schemas_to_rename = NIL;
	Datum			values[NAMESPACE_EXT_NUM_COLS];
	bool			nulls[NAMESPACE_EXT_NUM_COLS];
	bool			replaces[NAMESPACE_EXT_NUM_COLS];

	namespace_rel = table_open(namespace_ext_oid, RowExclusiveLock);
	namespace_rel_descr = RelationGetDescr(namespace_rel);

	ScanKeyInit(&key,
				Anum_namespace_ext_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(db_id));

	tblscan = systable_beginscan(namespace_rel, namespace_ext_oid, false,
							  NULL, 1, &key);

	/* Build a tuple only once and reuse it throughout. */
	MemSet(values, 0, sizeof(values));
	MemSet(nulls, false, sizeof(nulls));
	MemSet(replaces, false, sizeof(replaces));

	while (HeapTupleIsValid(old_tuple = systable_getnext(tblscan)))
	{
		bool		isNull;
		char		*schema_name = TextDatumGetCString(heap_getattr(old_tuple, Anum_namespace_ext_orig_name, namespace_rel_descr, &isNull));
		NameData 	physical_schema_name_namedata;

		namestrcpy(&physical_schema_name_namedata, get_physical_schema_name(new_db_name, schema_name));
		list_of_schemas_to_rename = lappend(list_of_schemas_to_rename, pstrdup(schema_name));

		/* Update the Physical Db Name. */
		values[Anum_namespace_ext_namespace - 1] = NameGetDatum(&physical_schema_name_namedata);
		replaces[Anum_namespace_ext_namespace - 1] = true;	

		new_tuple = heap_modify_tuple(old_tuple,
								namespace_rel_descr,
								values,
								nulls,
								replaces);

		/* Perform the actual catalog update. */
		CatalogTupleUpdate(namespace_rel, &new_tuple->t_self, new_tuple);
		heap_freetuple(new_tuple);
		if (schema_name)
			pfree(schema_name);
	}

	/* Cleanup. */
	systable_endscan(tblscan);
	table_close(namespace_rel, RowExclusiveLock);

	return list_of_schemas_to_rename;
}

/*
 * Update the fields relevant to database name in babelfish_authid_user_ext.
 * It returns the List of Original role names which can be used to
 * produce the new role name after rename db.
 */
static List*
update_babelfish_authid_user_ext_rename_db(
	const char *old_db_name,
	const char *new_db_name)
{
	volatile 		Relation bbf_authid_user_ext_rel;
	TupleDesc		bbf_authid_user_ext_dsc;
	ScanKeyData		key;
	HeapTuple		new_tuple, old_tuple;
	SysScanDesc		tblscan;
	List *list_of_roles_to_rename = NIL;
		
	Datum		values[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		nulls[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		replaces[BBF_AUTHID_USER_EXT_NUM_COLS];

	/* Fetch the relation. */
	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(), RowExclusiveLock);
	bbf_authid_user_ext_dsc = RelationGetDescr(bbf_authid_user_ext_rel);	

	/* Search and obtain the tuple on the database name. */
	ScanKeyInit(&key,
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(old_db_name));

	tblscan = systable_beginscan(bbf_authid_user_ext_rel,
							  get_authid_user_ext_oid(),
							  false, NULL, 1, &key);

	/* Build a tuple only once and reuse it throughout. */
	MemSet(values, 0, sizeof(values));
	MemSet(nulls, false, sizeof(nulls));
	MemSet(replaces, false, sizeof(replaces));

	while (HeapTupleIsValid(old_tuple = systable_getnext(tblscan)))
	{
		bool isNull;
		char *role_name = TextDatumGetCString(heap_getattr(old_tuple,
							Anum_bbf_authid_user_ext_orig_username, bbf_authid_user_ext_dsc, &isNull));
		NameData rolename_namedata;
		
		namestrcpy(&rolename_namedata, get_physical_user_name((char *)new_db_name, role_name, true, true));
		list_of_roles_to_rename = lappend(list_of_roles_to_rename, pstrdup(role_name));

		/* update rolname */
		values[USER_EXT_ROLNAME] 
						= NameGetDatum(&rolename_namedata);
		replaces[USER_EXT_ROLNAME] = true;

		/* update database name */
		values[USER_EXT_DATABASE_NAME]   = CStringGetTextDatum(new_db_name);
		replaces[USER_EXT_DATABASE_NAME] = true;

		/* update the modify date */
		values[USER_EXT_MODIFY_DATE]   = TimestampTzGetDatum(GetCurrentStatementStartTimestamp());
		replaces[USER_EXT_MODIFY_DATE] = true;

		new_tuple = heap_modify_tuple(old_tuple,
									bbf_authid_user_ext_dsc,
									values,
									nulls,
									replaces);

		CatalogTupleUpdate(bbf_authid_user_ext_rel, &new_tuple->t_self, new_tuple);
		heap_freetuple(new_tuple);
		if (role_name)
			pfree(role_name);
	}

	/* Cleanup. */
	systable_endscan(tblscan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
	return list_of_roles_to_rename;
}

/*
 * Update the name of the default database
 * in the babelfish_authid_login_ext catalog.
 */
static void
update_babelfish_authid_login_ext_rename_db(
	const char *old_db_name,
	const char *new_db_name)
{
	Relation	bbf_authid_login_ext_rel;
	TupleDesc	bbf_authid_login_ext_dsc;
	HeapTuple	new_tuple, old_tuple;
	Datum		values[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	bool		nulls[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	bool		replaces[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	ScanKeyData scanKey;
	SysScanDesc scan;

	/* Fetch the relation. */
	bbf_authid_login_ext_rel = table_open(get_authid_login_ext_oid(),
										  RowExclusiveLock);
	bbf_authid_login_ext_dsc = RelationGetDescr(bbf_authid_login_ext_rel);


	/* Search and obtain the tuple on the default database name. */
	ScanKeyInit(&scanKey,
				LOGIN_EXT_DEFAULT_DATABASE_NAME + 1,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(old_db_name));

	scan = systable_beginscan(bbf_authid_login_ext_rel,
							  get_authid_login_ext_oid(),
							  false, NULL, 1, &scanKey);

	/* Build a tuple to insert. */
	MemSet(values, 0, sizeof(values));
	MemSet(nulls, false, sizeof(nulls));
	MemSet(replaces, false, sizeof(replaces));

	while (HeapTupleIsValid(old_tuple = systable_getnext(scan)))
	{
		/* update modify_date */
		values[LOGIN_EXT_MODIFY_DATE] = TimestampTzGetDatum(GetCurrentStatementStartTimestamp());
		replaces[LOGIN_EXT_MODIFY_DATE] = true;

		/* update default_database field */
		values[LOGIN_EXT_DEFAULT_DATABASE_NAME] = CStringGetTextDatum(new_db_name);
		replaces[LOGIN_EXT_DEFAULT_DATABASE_NAME] = true;

		new_tuple = heap_modify_tuple(old_tuple,
									bbf_authid_login_ext_dsc,
									values,
									nulls,
									replaces);

		CatalogTupleUpdate(bbf_authid_login_ext_rel, &old_tuple->t_self, new_tuple);
		heap_freetuple(new_tuple);
	}
	systable_endscan(scan);

	/* Close bbf_authid_login_ext, but keep lock till commit. */
	table_close(bbf_authid_login_ext_rel, RowExclusiveLock);
}

static char
*gen_rename_schema_or_role_cmds(char *old_name, char *new_name, bool is_schema)
{
	StringInfoData query;
	initStringInfo(&query);
	/*
	 * We prepare the following query to Rename a schema or a ROLE.
	 *
	 * ALTER SCHEMA/ROLE <name>
	 *
	 */
	appendStringInfo(&query, is_schema ? "ALTER SCHEMA " : "ALTER ROLE ");

	appendStringInfo(&query, "%s RENAME TO %s", old_name, new_name);
	return query.data;
}

/*
 * We use processUtility to execute the renaming of schemas and roles
 * instead of directly calling the individual APIs to rename them in
 * order to adhere to the common high level code flow on which a lot of
 * features depend.
 */
static void
exec_rename_db_util(char *old_db_name, char *new_db_name, bool is_schema)
{
	char *query_str = gen_rename_schema_or_role_cmds(old_db_name, new_db_name, is_schema);
	List		*res;
	Node	   	*res_stmt;
	PlannedStmt *wrapper;

	/*
	 * The above query will be
	 * executed using ProcessUtility()
	 */
	res = raw_parser(query_str, RAW_PARSE_DEFAULT);
	res_stmt = ((RawStmt *) linitial(res))->stmt;

	/* need to make a wrapper PlannedStmt */
	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = res_stmt;
	wrapper->stmt_location = 0;
	wrapper->stmt_len = 0;

	ProcessUtility(wrapper,
				is_schema ? "(RENAME SCHEMA )" : "(RENAME ROLE )",
				false,
				PROCESS_UTILITY_SUBCOMMAND,
				NULL,
				NULL,
				None_Receiver,
				NULL);

	pfree(query_str);
}

void
rename_tsql_db(char *old_db_name, char *new_db_name)
{
	int xactStarted = IsTransactionOrTransactionBlock();
	Oid save_userid = InvalidOid;
	int save_sec_context = 0;
	int dbid = get_db_id(old_db_name);
	int tries;
	Oid     	prev_current_user = InvalidOid;

	/*
	 * Check that db_name is not "master", "tempdb", or "msdb",
	 * IDs 1-4 are reserved for these native system databases.
	 */
	if (dbid == 0)
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("Database %s does not exist. Make sure that the name is entered correctly.", old_db_name)));
	if (dbid && dbid <= 4)
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("Cannot change the name of the system database %s.", old_db_name)));

	/* 
	 * Check permission on the given database.
	 * Dbcreator can only alter the databases in which it has a mapped user.
	 */
	if (!has_privs_of_role(GetSessionUserId(), get_sysadmin_oid()) && !(get_user_for_database(old_db_name) 
							&& has_privs_of_role(GetSessionUserId(), get_dbcreator_oid())))
		ereport(ERROR,
			(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				errmsg("User does not have permission to rename the database \'%s\', the database does not exist, or the database is not in a state that allows access checks.",
					old_db_name)));

	Assert (*pltsql_protocol_plugin_ptr);
	/* 50 tries with 100ms sleep between tries makes 5 sec total wait */
	for (tries = 0; tries < 50; tries++)
	{
		if ((*pltsql_protocol_plugin_ptr)->get_tds_database_backend_count &&
			!(*pltsql_protocol_plugin_ptr)->get_tds_database_backend_count(dbid, dbid == get_cur_db_id()))
			break;

		/* sleep, then try again */
		pg_usleep(100 * 1000L); /* 100ms */
		if ((*pltsql_protocol_plugin_ptr)->invalidate_stat_view)
			(*pltsql_protocol_plugin_ptr)->invalidate_stat_view();
		/* timed out, still conflicts */
	}

	if (tries == 50)
		ereport(ERROR,
			(errcode(ERRCODE_OBJECT_IN_USE),
				errmsg("The database could not be exclusively locked to perform the operation.")));

	/*
	 * Get an exclusive lock on the logical database we are trying to rename.
	 */
	if (!TryLockLogicalDatabaseForSession(dbid, ExclusiveLock))
		ereport(ERROR,
			(errcode(ERRCODE_CHECK_VIOLATION),
				errmsg("The database could not be exclusively locked to perform the operation.")));

	if (!xactStarted)
		StartTransactionCommand();
	
	PG_TRY();
	{
		List *list_of_schemas_to_rename;
		List *list_of_roles_to_rename;
		ListCell *lc;
		char message[128];

		prev_current_user = GetUserId();

		/*
		 * We have checked for all permissions.
		 * Now change context to admin to perform the renames.
		 */
		SetCurrentRoleId(get_bbf_role_admin_oid(), true);
		GetUserIdAndSecContext(&save_userid, &save_sec_context);
		SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

		/*
		 * Update the database name in sys.babelfish_sysdatabases.
		 * This should happen irrespective of the migration mode.
		 */
		update_sysdatabases_db_name(old_db_name, new_db_name);

		/*
		 * There is no need to rename schemas for single-db mode.
		 * Therefore, no updates required Babelfish catalog as well.
		 */
		if (MULTI_DB == get_migration_mode())
		{
			/*
			 * Rename the physical schema and update them in
			 * sys.babelfish_namespace_ext.
			 * This includes system default and user created schemas in that db.
			 */
			list_of_schemas_to_rename = update_babelfish_namespace_ext_rename_db(dbid, new_db_name);
			foreach (lc, list_of_schemas_to_rename)
			{
				char *sch = (char *) lfirst(lc);
				char *old_schema_name = get_physical_schema_name(old_db_name, sch);
				char *new_schema_name = get_physical_schema_name(new_db_name, sch);

				exec_rename_db_util(old_schema_name, new_schema_name, true);
			}
		}

		/*
		 * Rename the physical roles and update the metadata in
		 * sys.babelfish_authid_user_ext.
		 * This includes system default and user created roles in that db.
		 */
		list_of_roles_to_rename = update_babelfish_authid_user_ext_rename_db(old_db_name, new_db_name);
		foreach (lc, list_of_roles_to_rename)
		{
			char *role = (char *) lfirst(lc);
			char *old_role_name;
			char *new_role_name;

			if (SINGLE_DB == get_migration_mode() && IS_FIXED_DB_PRINCIPAL(role))
				continue;

			old_role_name = get_physical_user_name(old_db_name, role, true, true);
			new_role_name = get_physical_user_name(new_db_name, role, true, true);
			exec_rename_db_util(old_role_name, new_role_name, false);

			pfree(old_role_name);
			pfree(new_role_name);
		}

		/* Update the default_database field in babelfish_authid_login_ext. */
		update_babelfish_authid_login_ext_rename_db(old_db_name, new_db_name);

		if (dbid == get_cur_db_id())
			snprintf(message, sizeof(message), "Changed database context to '%s'.\nThe database name '%s' has been set.", new_db_name, new_db_name);
		else
			snprintf(message, sizeof(message), "The database name '%s' has been set.", new_db_name);
		/* send env change token to user */

		/* Send env change token if User is renaming current database. */
		if (dbid == get_cur_db_id() && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_env_change)
			((*pltsql_protocol_plugin_ptr)->send_env_change) (1, new_db_name, old_db_name);
		/* Send message to User. */
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
			((*pltsql_protocol_plugin_ptr)->send_info) (0, 1, 0, message, 0);
	
	}
	PG_CATCH();
	{
		UnlockLogicalDatabaseForSession(dbid, ExclusiveLock, false);
		SetUserIdAndSecContext(save_userid, save_sec_context);
		SetCurrentRoleId(prev_current_user, true);
		PG_RE_THROW();
	}
	PG_END_TRY();

	UnlockLogicalDatabaseForSession(dbid, ExclusiveLock, false);
	SetUserIdAndSecContext(save_userid, save_sec_context);
	SetCurrentRoleId(prev_current_user, true);

	if (!xactStarted)
		CommitTransactionCommand();
}

/*
 * Returns true if the user/role exists in the sys.babelfish_authid_user_ext catalog,
 * false otherwise.
 */
bool
user_exists_for_db(const char *db_name, const char *user_name)
{
	HeapTuple		tuple_cache;
	NameData		rolname;
	bool			user_exists = false;

	namestrcpy(&rolname, user_name);

	tuple_cache = SearchSysCache1(AUTHIDUSEREXTROLENAME, NameGetDatum(&rolname));

	if (HeapTupleIsValid(tuple_cache))
	{
		bool isnull;
		char *db_name_from_cache = TextDatumGetCString(SysCacheGetAttr(AUTHIDUSEREXTROLENAME, tuple_cache,
												 Anum_bbf_authid_user_ext_database_name, &isnull));

		Assert(!isnull);

		if (strcmp(db_name_from_cache, db_name) == 0)
			user_exists = true;
		
		pfree(db_name_from_cache);
		ReleaseSysCache(tuple_cache);
	}

	return user_exists;
}

/*
 * partition_function_id_exists
 *		Returns true if provided function id is in use, false otherwise.
 *
 * 	This is helper function to find new id for partition function, it checks if provided
 * 	id is already in use by looking up in sys.babelfish_partition_function catalog.
 */
static bool
partition_function_id_exists(int32 id)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey;
	bool		exists = false;
	/* open the relation */
	rel = table_open(get_bbf_partition_function_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey,
					Anum_bbf_partition_function_id,
					BTEqualStrategyNumber, F_INT4EQ,
					Int32GetDatum(id));

	/* scan using index */
	scan = systable_beginscan(rel,
			get_bbf_partition_function_id_idx_oid(),
			false, NULL, 1, &scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
		exists = true;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return exists;
}

/*
 * get_available_partition_function_id
 * 		Returns available id for partition function.
 * 
 * 	1. To guard against race conditions for IDs, we check if the
 * 	   ID generated by sequence is used by an existing partition function.
 * 	2. To guard rare case where all possible sequence values have been exhausted
 * 	   and the sequence wraps around, we will loop through the entire range of
 * 	   sequence values and on loop completion, we should bail out.
 */
int32
get_available_partition_function_id(void)
{
	int32		id;
	int32		start = 0;

	do
	{
		id = nextval_internal(get_bbf_partition_function_seq_oid(), false);
		if (start == 0)
			start = id;
		else if (start == id) /* loop completed */
		{
			ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Cannot find an available ID for new partition function.")));

		}
	} while (partition_function_id_exists(id));

	return id;
}

/*
 * partition_scheme_id_exists
 *		Returns true if provided scheme id is in use, false otherwise.
 *
 * 	This is helper function to find new id for partition scheme, it checks
 * 	if provided id is already in use by looking up in sys.babelfish_partition_scheme catalog.
 */
static bool
partition_scheme_id_exists(int32 id)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey;
	bool		exists = false;

	/* open the relation */
	rel = table_open(get_bbf_partition_scheme_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey,
			Anum_bbf_partition_scheme_id,
			BTEqualStrategyNumber, F_INT4EQ,
			Int32GetDatum(id));

	/* scan using index */
	scan = systable_beginscan(rel,
			get_bbf_partition_scheme_id_idx_oid(),
			false, NULL, 1, &scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
		exists = true;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return exists;
}

/*
 * get_available_partition_scheme_id
 * 		Returns available id for partition scheme.
 * 	1. To guard against race conditions for IDs, we check if the
 * 	   ID generated by sequence is used by an existing partition scheme.
 * 	2. To guard rare case where all possible sequence values have been exhausted
 * 	   and the sequence wraps around, we will loop through the entire range of
 * 	   sequence values and on loop completion, we should bail out.
 */
int32
get_available_partition_scheme_id(void)
{
	int32		id;
	int32		start = 0;

	do
	{
		id = nextval_internal(get_bbf_partition_scheme_seq_oid(), false);
		if (start == 0)
			start = id;
		else if (start == id) /* loop completed */
		{
			ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Cannot find an available ID for new partition scheme.")));

		}
	} while (partition_scheme_id_exists(id));

	return id;
}

/*
 * is_partition_function_used
 *		Returns true if provided function name is in use, false otherwise.
 *
 * 	This function checks if provided function name is used by any partition scheme,
 * 	by looking up in sys.babelfish_partition_scheme catalog.
 */
static bool
is_partition_function_used(int16 dbid, const char *partition_function_name)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey[2];
	bool		is_used = false;

	rel = table_open(get_bbf_partition_scheme_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_scheme_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0, 
				Anum_bbf_partition_scheme_func_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_function_name));

	scan = systable_beginscan(rel,
			get_bbf_partition_scheme_pk_idx_oid(),
			false, NULL, 2, scanKey);

	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
		is_used = true;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return is_used;
}

/*
 * add_entry_to_bbf_partition_function
 *		Add a new entry to the sys.babelfish_partition_function catalog table.
 */
void
add_entry_to_bbf_partition_function(int16 dbid, const char *partition_function_name, char *typname,
					bool partition_option, ArrayType *values)
{
	Relation	rel;
	TupleDesc	dsc;
	HeapTuple	tuple;
	Datum		new_record[BBF_PARTITION_FUNCTION_NUM_COLS];
	bool		new_record_nulls[BBF_PARTITION_FUNCTION_NUM_COLS];
	int32		partition_function_id = get_available_partition_function_id();

	MemSet(new_record, 0, sizeof(new_record));
	MemSet(new_record_nulls, false, sizeof(new_record_nulls));

	/* open the relation */
	rel = table_open(get_bbf_partition_function_oid(), RowExclusiveLock);
	dsc = RelationGetDescr(rel);

	/* Build a tuple to insert */
	new_record[Anum_bbf_partition_function_dbid - 1] = Int16GetDatum(dbid);
	new_record[Anum_bbf_partition_function_id - 1] = Int32GetDatum(partition_function_id);
	new_record[Anum_bbf_partition_function_name - 1] = CStringGetTextDatum(partition_function_name);
	new_record[Anum_bbf_partition_function_input_parameter_type - 1] =  CStringGetTextDatum(typname);
	new_record[Anum_bbf_partition_function_partition_option - 1] = BoolGetDatum(partition_option);
	new_record[Anum_bbf_partition_function_range_values - 1] = PointerGetDatum(values);
	new_record[6] = new_record[7] = TimestampGetDatum(GetSQLLocalTimestamp(3));

	tuple = heap_form_tuple(dsc, new_record, new_record_nulls);

	/* insert new record in the bbf_partition_function table */
	CatalogTupleInsert(rel, tuple);

	heap_freetuple(tuple);
	/* close the relation */
	table_close(rel, RowExclusiveLock);
}

/*
 * remove_entry_from_bbf_partition_function
 * 		Tries to remove an entry from the sys.babelfish_partition_function catalog table.
 * 
 * 	It raises errors for following cases:
 * 		1. If partition function doesn't exists in database.
 * 		2. If there are any dependent partition schemes on this partition function.
 */
void
remove_entry_from_bbf_partition_function(int16 dbid, const char *partition_function_name)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData	scanKey[2];
	SysScanDesc	scan;
	int32		function_exists = false;
	bool		has_dependent_objects = true;

	/* Fetch the relation */
	rel = table_open(get_bbf_partition_function_oid(), RowExclusiveLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_function_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_partition_function_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_function_name));
	/* scan using index */
	scan = systable_beginscan(rel, get_bbf_partition_function_pk_idx_oid(),
					false, NULL, 2, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{	
		function_exists = true;
		/* remove the entry only if there is no dependent partition scheme on it */
		if (!is_partition_function_used(dbid, partition_function_name))
		{
			has_dependent_objects = false;
			CatalogTupleDelete(rel, &tuple->t_self);
		}
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	/* raise error if it doesn't exists in database */
	if (!function_exists)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_UNDEFINED_OBJECT),
				errmsg("Cannot drop the partition function '%s', because it does not exist or you do not have permission.", partition_function_name)));
	}

	/* raise error if there are dependent partition scheme on it */
	if (has_dependent_objects)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_UNDEFINED_OBJECT),
				errmsg("Partition function '%s' is being used by one or more partition schemes.", partition_function_name)));
	}
}

/*
 * partition_function_exists
 *	Returns true if provided partition function name exists in database, false otherwise.
 */
bool
partition_function_exists(int16 dbid, const char *partition_function_name)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey[2];
	bool		exists = false;

	/* open the relation */
	rel = table_open(get_bbf_partition_function_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_function_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_partition_function_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_function_name));
	
	/* scan using index */
	scan = systable_beginscan(rel, get_bbf_partition_function_pk_idx_oid(),
					false, NULL, 2, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
		exists = true;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return exists;
}

/*
 * get_partition_count
 *		Returns the number of partitions that will be generated using the given partition function name.
 */
int
get_partition_count(int16 dbid, const char *partition_function_name)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey[2];
	int		count = 0;
	/* Fetch the relation */
	rel = table_open(get_bbf_partition_function_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_function_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&scanKey[1], 0, 
				Anum_bbf_partition_function_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_function_name));
	/* scan using index */
	scan = systable_beginscan(rel, get_bbf_partition_function_pk_idx_oid(),
					false, NULL, 2, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		bool isnull;
		ArrayType *values;
		values = DatumGetArrayTypeP(heap_getattr(tuple, Anum_bbf_partition_function_range_values, RelationGetDescr(rel), &isnull));
		count = ArrayGetNItems(ARR_NDIM(values), ARR_DIMS(values)) + 1;
	}
	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return count;
}

/*
 * is_partition_scheme_used
 *		Returns true if provided scheme name is in use, false otherwise.
 *
 * 	This function checks if provided scheme name is used by any partition scheme,
 * 	by looking up in sys.babelfish_partition_depend catalog.
 */
static bool
is_partition_scheme_used(int16 dbid, const char *partition_scheme_name)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData scanKey[2];
	SysScanDesc scan;
	bool is_used = false;

 	rel = table_open(get_bbf_partition_depend_oid(), AccessShareLock);
 	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_depend_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0, 
				Anum_bbf_partition_depend_scheme_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_scheme_name));


	scan = systable_beginscan(rel,
			get_bbf_partition_depend_idx_oid(),
			false, NULL, 2, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
		is_used = true;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return is_used;
}

/*
 * add_entry_to_bbf_partition_scheme
 *		Add a new entry to the sys.babelfish_partition_scheme catalog table.
 */
void
add_entry_to_bbf_partition_scheme(int16 dbid, const char *partition_scheme_name, const char *partition_function_name, bool next_used)
{
	Relation	rel;
	TupleDesc	dsc;
	HeapTuple	tuple;
	Datum		new_record[BBF_PARTITION_SCHEME_NUM_COLS];
	bool		new_record_nulls[BBF_PARTITION_SCHEME_NUM_COLS];
	int32		partition_scheme_id = get_available_partition_scheme_id();

	/* Fetch the relation */
	rel = table_open(get_bbf_partition_scheme_oid(), RowExclusiveLock);
	dsc = RelationGetDescr(rel);

	/* Build a tuple to insert */
	MemSet(new_record, 0, sizeof(new_record));
	MemSet(new_record_nulls, false, sizeof(new_record_nulls));

	new_record[Anum_bbf_partition_scheme_dbid - 1] = Int16GetDatum(dbid);
	new_record[Anum_bbf_partition_scheme_id - 1] = Int32GetDatum(partition_scheme_id);
	new_record[Anum_bbf_partition_scheme_name - 1] = CStringGetTextDatum(partition_scheme_name);
	new_record[Anum_bbf_partition_scheme_func_name - 1] = CStringGetTextDatum(partition_function_name);
	new_record[Anum_bbf_partition_scheme_next_used - 1] = BoolGetDatum(next_used);

	tuple = heap_form_tuple(dsc, new_record, new_record_nulls);

	/* Insert new record in the bbf_partition_scheme table */
	CatalogTupleInsert(rel, tuple);

	heap_freetuple(tuple);
	/* Close bbf_partition_scheme */
	table_close(rel, RowExclusiveLock);
}

/*
 * remove_entry_from_bbf_partition_scheme
 * 		Tries to remove an entry from the sys.babelfish_partition_scheme catalog table.
 * 
 * 	It raises errors for following cases:
 * 		1. If partition scheme doesn't exists in database.
 * 		2. If there are any dependent tables on this partition scheme.
 */
void
remove_entry_from_bbf_partition_scheme(int16 dbid, const char *partition_scheme_name)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData	scanKey[2];
	SysScanDesc	scan;
	bool 		scheme_exists = false;
	bool 		has_dependent_objects = true;

	/* open the relation */
	rel = table_open(get_bbf_partition_scheme_oid(), RowExclusiveLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_scheme_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0, 
				Anum_bbf_partition_scheme_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_scheme_name));
	/* scan using index */
	scan = systable_beginscan(rel, get_bbf_partition_scheme_pk_idx_oid(),
					false, NULL, 2, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		scheme_exists = true;
		/* remove the entry only if there is no dependent tables on it */
		if (!is_partition_scheme_used(dbid, partition_scheme_name))
		{
			has_dependent_objects = false;
			CatalogTupleDelete(rel, &tuple->t_self);
		}
	}

	systable_endscan(scan);
	/* close the relation */
	table_close(rel, RowExclusiveLock);

	/* raise error if it doesn't exists in database */
	if (!scheme_exists)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_UNDEFINED_OBJECT), 
				errmsg("Cannot drop the partition scheme '%s', because it does not exist or you do not have permission.", partition_scheme_name)));
	}

	/* raise error if there are dependent tables on it */
	if (has_dependent_objects) 
	{
		ereport(ERROR, 
			(errcode(ERRCODE_UNDEFINED_OBJECT),
				errmsg("The partition scheme \"%s\" is currently being used to partition one or more tables.", partition_scheme_name)));
	}
}

/*
 * partition_scheme_exists
 * 	Returns true if provided scheme name exists in database, false otherwise.
 */
bool
partition_scheme_exists(int16 dbid, const char *partition_scheme_name)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey[2];
	bool		exists = false;

	rel = table_open(get_bbf_partition_scheme_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_scheme_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0, 
				Anum_bbf_partition_scheme_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_scheme_name));

	scan = systable_beginscan(rel, get_bbf_partition_scheme_pk_idx_oid(),
					false, NULL, 2, scanKey);

	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
		exists = true;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return exists;
}

/*
 * get_partition_function_name
 * 	Returns the partition function name for the given partition scheme name.
 */
char*
get_partition_function_name(int16 dbid, const char *partition_scheme_name)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey[2];
	char		*partition_function_name = NULL;

	rel = table_open(get_bbf_partition_scheme_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_scheme_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0, 
				Anum_bbf_partition_scheme_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_scheme_name));

	scan = systable_beginscan(rel, get_bbf_partition_scheme_pk_idx_oid(),
					false, NULL, 2, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		bool isnull;
		partition_function_name = TextDatumGetCString(heap_getattr(tuple, Anum_bbf_partition_scheme_func_name, RelationGetDescr(rel), &isnull));
	}

	systable_endscan(scan);
	table_close(rel, AccessShareLock);
	return partition_function_name;
}
/*
 * add_entry_to_bbf_partition_depend
 *	Inserts a new entry into the sys.babelfish_partition_depend catalog
 *	to track the dependecy between partition scheme and partitioned tables
 *	created using that.
 */
void
add_entry_to_bbf_partition_depend(int16 dbid, char* partition_scheme_name, char *schema_name, char *table_name)
{
	Relation	rel;
	TupleDesc	dsc;
	HeapTuple	tuple;
	Datum		new_record[BBF_PARTITION_DEPEND_NUM_COLS];
	bool		new_record_nulls[BBF_PARTITION_DEPEND_NUM_COLS];

	MemSet(new_record, 0, sizeof(new_record));
	MemSet(new_record_nulls, false, sizeof(new_record_nulls));

	rel = table_open(get_bbf_partition_depend_oid(), RowExclusiveLock);
	dsc = RelationGetDescr(rel);

	/* Build a tuple to insert. */
	new_record[Anum_bbf_partition_depend_dbid - 1] = Int16GetDatum(dbid);
	new_record[Anum_bbf_partition_depend_scheme_name - 1] = CStringGetTextDatum(partition_scheme_name);
	new_record[Anum_bbf_partition_depend_table_schema_name - 1] = CStringGetTextDatum(schema_name);
	new_record[Anum_bbf_partition_depend_table_name - 1] = CStringGetTextDatum(table_name);

	tuple = heap_form_tuple(dsc, new_record, new_record_nulls);

	/* Insert new record in the table. */
	CatalogTupleInsert(rel, tuple);

	heap_freetuple(tuple);
	table_close(rel, RowExclusiveLock);
}

/*
 * remove_entry_from_bbf_partition_depend
 *	Removes an entry from the sys.babelfish_partition_depend catalog.
 */
void
remove_entry_from_bbf_partition_depend(int16 dbid, char *schema_name, char *table_name)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData	scanKey[3];
	SysScanDesc	scan;

	rel = table_open(get_bbf_partition_depend_oid(), RowExclusiveLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_depend_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_partition_depend_table_schema_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(schema_name));

	ScanKeyEntryInitialize(&scanKey[2], 0, 
				Anum_bbf_partition_depend_table_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(table_name));

	scan = systable_beginscan(rel, get_bbf_partition_depend_idx_oid(),
					false, NULL, 3, scanKey);
	
	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		CatalogTupleDelete(rel, &tuple->t_self);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);
}

/*
 * rename_table_update_bbf_partition_depend_catalog
 * 	Updates table_name in sys.babelfish_partition_depend catalog for
 * 	RENAME TABLE command to have consistency with the new names.
 */
void
rename_table_update_bbf_partition_depend_catalog(RenameStmt *stmt, char *logical_schema_name, int16 dbid)
{
	Relation	rel;
	HeapTuple	tuple, new_tuple;
	TupleDesc	dsc;
	ScanKeyData	scanKey[3];
	SysScanDesc	scan;
	Datum		new_record[BBF_PARTITION_DEPEND_NUM_COLS];
	bool		new_record_nulls[BBF_PARTITION_DEPEND_NUM_COLS];
	bool		new_record_replace[BBF_PARTITION_DEPEND_NUM_COLS];
	char		*table_name = stmt->relation->relname;

	/* Open the catalog table. */
	rel = table_open(get_bbf_partition_depend_oid(), RowExclusiveLock);

	/* Search for the row which needs to be updated. */
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_depend_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0, 
				Anum_bbf_partition_depend_table_schema_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(logical_schema_name));

	ScanKeyEntryInitialize(&scanKey[2], 0, 
				Anum_bbf_partition_depend_table_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(table_name));

	scan = systable_beginscan(rel, get_bbf_partition_depend_idx_oid(),
					false, NULL, 3, scanKey);

	tuple = systable_getnext(scan);

	/* Update the table name of the found row. */
	if (HeapTupleIsValid(tuple))
	{
		/* Get the descriptor of the table. */
		dsc = RelationGetDescr(rel);

		/* Build a tuple to insert. */
		MemSet(new_record, 0, sizeof(new_record));
		MemSet(new_record_nulls, false, sizeof(new_record_nulls));
		MemSet(new_record_replace, false, sizeof(new_record_replace));

		new_record[Anum_bbf_partition_depend_table_name - 1] = CStringGetTextDatum(stmt->newname);
		new_record_replace[Anum_bbf_partition_depend_table_name - 1] = true;
		new_tuple = heap_modify_tuple(tuple, dsc, new_record, new_record_nulls, new_record_replace);

		/* Perform the actual catalog update. */
		CatalogTupleUpdate(rel, &new_tuple->t_self, new_tuple);

		/* Free the allocated tuple. */
		heap_freetuple(new_tuple);
	}

	systable_endscan(scan);
	/* Close the catalog table. */
	table_close(rel, RowExclusiveLock);
}

/*
 * is_bbf_partitioned_table
 *		Returns true if provided table is babelfish partitioned table, false otherwise.
 *
 *	This function checks if provided table is babelfish partitioned table
 *	by looking up in sys.babelfish_partition_depend catalog.
 */
bool
is_bbf_partitioned_table(int16 dbid, char *schema_name, char *table_name)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData	scanKey[3];
	SysScanDesc	scan;
	bool		sucess = false;

	rel = table_open(get_bbf_partition_depend_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_depend_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_partition_depend_table_schema_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(schema_name));

	ScanKeyEntryInitialize(&scanKey[2], 0,
				Anum_bbf_partition_depend_table_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(table_name));

	scan = systable_beginscan(rel, get_bbf_partition_depend_idx_oid(),
					false, NULL, 3, scanKey);

	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
		sucess = true;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	return sucess;
}

/*
 * get_partition_scheme_for_partitioned_table
 * 	Returns the name of partition scheme used to create the partitioned table.
 */
char*
get_partition_scheme_for_partitioned_table(int16 dbid, char *schema_name, char *table_name)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData	scanKey[3];
	SysScanDesc	scan;
	char		*partition_scheme_name = NULL;

	rel = table_open(get_bbf_partition_depend_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_depend_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_partition_depend_table_schema_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(schema_name));

	ScanKeyEntryInitialize(&scanKey[2], 0,
				Anum_bbf_partition_depend_table_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(table_name));

	scan = systable_beginscan(rel, get_bbf_partition_depend_idx_oid(),
					false, NULL, 3, scanKey);

	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		bool isnull;
		partition_scheme_name = TextDatumGetCString(heap_getattr(tuple, Anum_bbf_partition_depend_scheme_name, RelationGetDescr(rel), &isnull));
	}

	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	return partition_scheme_name;
}

/*
 * clean_up_bbf_partition_metadata
 *		clean up all the maintained metadata related to partition for
 * 		provided database
 */
void
clean_up_bbf_partition_metadata(int16 dbid)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey;

	/* clean up sys.babelfish_partition_depend catalog */
	rel = table_open(get_bbf_partition_depend_oid(), RowExclusiveLock);

	ScanKeyInit(&scanKey,
			Anum_bbf_partition_function_dbid,
			BTEqualStrategyNumber, F_INT2EQ,
			Int16GetDatum(dbid));

	scan = systable_beginscan(rel, get_bbf_partition_depend_idx_oid(),
					true, NULL, 1, &scanKey);

	while ((tuple = systable_getnext(scan)) != NULL)
	{
		if (HeapTupleIsValid(tuple))
			CatalogTupleDelete(rel, &tuple->t_self);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	/* clean up sys.babelfish_partition_scheme catalog */
	rel = table_open(get_bbf_partition_scheme_oid(), RowExclusiveLock);

	ScanKeyInit(&scanKey,
			Anum_bbf_partition_scheme_dbid,
			BTEqualStrategyNumber, F_INT2EQ,
			Int16GetDatum(dbid));

	scan = systable_beginscan(rel, get_bbf_partition_scheme_pk_idx_oid(),
					true, NULL, 1, &scanKey);

	while ((tuple = systable_getnext(scan)) != NULL)
	{
		if (HeapTupleIsValid(tuple))
			CatalogTupleDelete(rel, &tuple->t_self);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);
	
	/* clean up sys.babelfish_partition_function catalog */
	rel = table_open(get_bbf_partition_function_oid(), RowExclusiveLock);

	ScanKeyInit(&scanKey,
			Anum_bbf_partition_function_dbid,
			BTEqualStrategyNumber, F_INT2EQ,
			Int16GetDatum(dbid));

	scan = systable_beginscan(rel, get_bbf_partition_function_pk_idx_oid(),
					true, NULL, 1, &scanKey);

	while ((tuple = systable_getnext(scan)) != NULL)
	{
		if (HeapTupleIsValid(tuple))
			CatalogTupleDelete(rel, &tuple->t_self);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);
}
/* 
 * This is a temporary procedure which is called during upgrade to alter
 * default privileges on all the schemas where the schema owner is not dbo/db_owner.
 */
static void
alter_default_privilege_for_db(char *dbname)
{
	SysScanDesc scan;
	Relation	bbf_schema_rel;
	TupleDesc	dsc;
	HeapTuple	tuple_bbf_schema;
	ScanKeyData scanKey[2];
	int16		dbid = get_db_id(dbname);
	MigrationMode baseline_mode = is_user_database_singledb(dbname) ? SINGLE_DB : MULTI_DB;

	/* Fetch the relation */
	bbf_schema_rel = table_open(get_bbf_schema_perms_oid(),
									AccessShareLock);
	dsc = RelationGetDescr(bbf_schema_rel);
	ScanKeyInit(&scanKey[0],
				Anum_bbf_schema_perms_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));
	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_schema_perms_object_type,
				BTEqualStrategyNumber,
				InvalidOid,
				tsql_get_database_or_server_collation_oid_internal(false),
				F_TEXTEQ,
				CStringGetTextDatum(OBJ_SCHEMA));

	scan = systable_beginscan(bbf_schema_rel, get_bbf_schema_perms_idx_oid(),
							true, NULL, 2, scanKey);
	tuple_bbf_schema = systable_getnext(scan);

	while (HeapTupleIsValid(tuple_bbf_schema))
	{
		bool		isnull;
		const char	*schema_name;
		const char	*grantee;
		int			current_permission;
		char		*schema_owner;
		char		*physical_schema;
		const char	*dbo_user;
		const char	*db_owner;
		int			i;

		schema_name = TextDatumGetCString(heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_schema_name, dsc, &isnull));
		grantee = TextDatumGetCString(heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_grantee, dsc, &isnull));
		current_permission = DatumGetInt32(heap_getattr(tuple_bbf_schema, Anum_bbf_schema_perms_permission, dsc, &isnull));

		physical_schema = get_physical_schema_name_by_mode(dbname, schema_name, baseline_mode);
		dbo_user = get_dbo_role_name_by_mode(dbname, baseline_mode);
		db_owner = get_db_owner_name_by_mode(dbname, baseline_mode);
		schema_owner = GetUserNameFromId(get_owner_of_schema(physical_schema), false);

		/* If schema owner is other that dbo or db_owner user, only then execute ALTER DEFAULT PRIVILEGES. */
		if ((strcmp(schema_owner, dbo_user) != 0) && (strcmp(schema_owner, db_owner) != 0))
		{
			/* For each permission, grant alter default privileges explicitly. */
			for (i = 0; i < NUMBER_OF_PERMISSIONS; i++)
			{
				if ((current_permission & permissions[i]) &&  permissions[i] != ACL_EXECUTE)
				{
					char	*alter_query = NULL;
					char	*grant_query = NULL;
					alter_query = psprintf("ALTER DEFAULT PRIVILEGES FOR ROLE %s, %s IN SCHEMA %s GRANT %s ON TABLES TO %s", dbo_user, schema_owner, physical_schema, privilege_to_string(permissions[i]), grantee);
					exec_utility_cmd_helper(alter_query);
					grant_query = psprintf("GRANT %s ON ALL TABLES IN SCHEMA %s TO %s", privilege_to_string(permissions[i]), physical_schema, grantee);
					exec_utility_cmd_helper(grant_query);
					pfree(alter_query);
					pfree(grant_query);
				}
			}
		}
		pfree(physical_schema);
		pfree(schema_owner);
		tuple_bbf_schema = systable_getnext(scan);
	}
	
	systable_endscan(scan);
	table_close(bbf_schema_rel, AccessShareLock);
}


PG_FUNCTION_INFO_V1(alter_default_privilege_on_schema);
Datum
alter_default_privilege_on_schema(PG_FUNCTION_ARGS)
{
	Relation	db_rel;
	TableScanDesc scan;
	HeapTuple	tuple;
	bool		is_null;

	db_rel = table_open(sysdatabases_oid, AccessShareLock);
	scan = table_beginscan_catalog(db_rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		Datum		db_name_datum = heap_getattr(tuple, Anum_sysdatabases_name,
												 db_rel->rd_att, &is_null);
		char *db_name = TextDatumGetCString(db_name_datum);

		alter_default_privilege_for_db(db_name);
		pfree(db_name);
		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	table_endscan(scan);
	table_close(db_rel, AccessShareLock);
	PG_RETURN_INT32(0);
}
