#include "postgres.h"
#include "miscadmin.h"
#include "access/genam.h"
#include "access/htup_details.h"
#include "access/table.h"
#include "access/xact.h"
#include "catalog/catalog.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_namespace.h"
#include "commands/dbcommands.h"
#include "commands/defrem.h"
#include "commands/sequence.h"
#include "lib/stringinfo.h"
#include "nodes/plannodes.h"
#include "parser/parse_node.h"
#include "parser/parse_relation.h"
#include "parser/parser.h"
#include "storage/lockdefs.h"
#include "access/heapam.h"
#include "access/tableam.h"
#include "tcop/utility.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/timestamp.h"

#include "catalog.h"
#include "collation.h"
#include "dbcmds.h"
#include "session.h"
#include "multidb.h"
#include "guc.h"
#include "rolecmds.h"
#include "pltsql.h"

static bool have_createdb_privilege(void);
static List	*gen_createdb_subcmds(const char *schema,
								  const char *dbo,
								  const char *db_owner,
								  const char *guest);
static List *gen_dropdb_subcmds(const char *schema,
								const char *dbo,
								const char *db_owner,
								const char *guest);
static Oid do_create_bbf_db(const char *dbname, List *options, const char *owner);
static List *grant_guest_to_logins(StringInfoData *query);
static void drop_related_bbf_namespace_entries(int16 dbid);

static bool
have_createdb_privilege(void)
{
	bool		result = false;
	HeapTuple	utup;

	/* Superusers can always do everything */
	if (superuser())
		return true;

	utup = SearchSysCache1(AUTHOID, ObjectIdGetDatum(GetSessionUserId()));
	if (HeapTupleIsValid(utup))
	{
		result = ((Form_pg_authid) GETSTRUCT(utup))->rolcreatedb;
		ReleaseSysCache(utup);
	}
	return result;
}

/*
 * Generate subcmds for CREATE DATABASE. Note 'guest' can be NULL.
 */
static List	*
gen_createdb_subcmds(const char *schema, const char *dbo, const char *db_owner, const char *guest)
{
	StringInfoData	query;
	List			*res;
	List			*logins = NIL;
	Node			*stmt;
	int				i = 0;
	int				expected_stmt_num;

	/* 
	 * To avoid SQL injection, we generate statement parsetree with dummy values
	 * and update them later
	 */
	initStringInfo(&query);

	appendStringInfo(&query, "CREATE ROLE dummy INHERIT; ");
	appendStringInfo(&query, "CREATE ROLE dummy INHERIT ROLE sysadmin IN ROLE dummy; ");
	appendStringInfo(&query, "GRANT CREATE, CONNECT, TEMPORARY ON DATABASE dummy TO dummy; ");
	if (guest)
	{
		appendStringInfo(&query, "CREATE ROLE dummy INHERIT ROLE dummy; ");
		logins = grant_guest_to_logins(&query);
	}

	appendStringInfo(&query, "CREATE SCHEMA dummy AUTHORIZATION dummy; ");

	/* create sysdatabases under current DB's DBO schema */
	appendStringInfo(&query, "CREATE VIEW dummy.sysdatabases AS SELECT * FROM sys.sysdatabases; ");
	appendStringInfo(&query, "ALTER VIEW dummy.sysdatabases OWNER TO dummy; ");
	appendStringInfo(&query, "GRANT SELECT ON dummy.sysdatabases TO dummy; ");

	res = raw_parser(query.data);

	if (guest)
		expected_stmt_num = list_length(logins) > 0 ? 9 : 8;
	else
		expected_stmt_num = 7;

	if (list_length(res) != expected_stmt_num)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected %d statement but get %d statements after parsing",
						expected_stmt_num, list_length(res))));

	/* Replace dummy elements in parsetree with real values */
	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, db_owner, NULL, NULL);
	
	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, dbo, NULL, db_owner);

	stmt = parsetree_nth_stmt(res, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, dbo);

	if (guest)
	{
		stmt = parsetree_nth_stmt(res, i++);
		update_CreateRoleStmt(stmt, guest, db_owner, NULL);

		if (list_length(logins) > 0)
		{
			AccessPriv *tmp = makeNode(AccessPriv);
			tmp->priv_name = pstrdup(guest);
			tmp->cols = NIL;

			stmt = parsetree_nth_stmt(res, i++);
			update_GrantRoleStmt(stmt, list_make1(tmp), logins);
		}
	}

	stmt = parsetree_nth_stmt(res, i++);
	update_CreateSchemaStmt(stmt, "dbo", db_owner);

	stmt = parsetree_nth_stmt(res, i++);
	update_ViewStmt(stmt, schema);

	stmt = parsetree_nth_stmt(res, i++);
	update_AlterTableStmt(stmt, schema, db_owner);

	stmt = parsetree_nth_stmt(res, i++);
	update_GrantStmt(stmt, NULL, schema, db_owner);

	return res;
}

/*
 * Generate subcmds for DROP DATABASE. Note 'guest' can be NULL.
 */
static List *
gen_dropdb_subcmds(const char *schema, const char *dbo, const char *db_owner, const char *guest)
{
	StringInfoData query;
	List *res;
	Node *stmt;
	int i = 0;
	int expected_stmt = guest ? 5 : 4;

	const char **roles = (const char **) palloc(sizeof(const char *) * 3);
	roles[0] = db_owner;
	roles[1] = dbo;
	roles[2] = guest;

	initStringInfo(&query);

	appendStringInfo(&query, "DROP SCHEMA dummy CASCADE; ");
	if (guest)
		appendStringInfo(&query, "DROP OWNED BY dummy, dummy, dummy CASCADE; ");
	else
		appendStringInfo(&query, "DROP OWNED BY dummy, dummy CASCADE; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");
	if (guest)
		appendStringInfo(&query, "DROP ROLE dummy; ");
	res = raw_parser(query.data);

	if (list_length(res) != expected_stmt)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected %d statement but get %d statements after parsing",
						expected_stmt, list_length(res))));

	stmt = parsetree_nth_stmt(res, i++);
	update_DropStmt(stmt, schema);

	stmt = parsetree_nth_stmt(res, i++);
	update_DropOwnedStmt(stmt, roles, guest ? 3 : 2);

	stmt = parsetree_nth_stmt(res, i++);
	update_DropRoleStmt(stmt, db_owner);

	stmt = parsetree_nth_stmt(res, i++);
	update_DropRoleStmt(stmt, dbo);

	if (guest)
	{
		stmt = parsetree_nth_stmt(res, i++);
		update_DropRoleStmt(stmt, guest);
	}

	return res;
}

Oid
create_bbf_db(ParseState *pstate, const CreatedbStmt *stmt)
{
	ListCell 	*option;
	const char *owner = GetUserNameFromId(GetSessionUserId(), false);

	/* Check options */
	foreach(option, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(option);
		if (strcmp(defel->defname, "collate") == 0)
		{
			if (strcmp(pltsql_server_collation_name, defGetString(defel)))
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("only \"%s\" supported for default collation", pltsql_server_collation_name),
						 parser_errposition(pstate, defel->location)));
		}
		else
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("option \"%s\" not recognized", defel->defname),
					 parser_errposition(pstate, defel->location)));
	}

	return do_create_bbf_db(stmt->dbname, stmt->options, owner);
}

/* 
 * To guard the rare case that we have used up all the possible sequence values 
 * and it wraps around, check if the next seq value is used by an existing DB.
 * Also, we reserved four IDs 1-4 for native databases, 1-2 are created when
 * initializing babelfishpg_tsql (master and tempdb), 3-4 are just placeholder that 
 * we currently don't have plan to support. New user database will start from ID=5.
 *
 * If we can't find one after looping the entire range of sequence values
 * (1 to 32767), we should bail out.
 */
static int16 getAvailDbid() {
	int16  dbid;
	int16  start = 0;

	do {
		dbid = DirectFunctionCall1(nextval, CStringGetTextDatum("sys.babelfish_db_seq"));
		if (start == 0)
			start = dbid;
		else if (start == dbid)
			return InvalidDbid;
	} while (dbid == 3 || dbid == 4 || get_db_name(dbid) != NULL);

	return dbid;
}

static Oid
do_create_bbf_db(const char *dbname, List *options, const char *owner)
{
	int16       dbid;
	int16 		old_dbid;
	char		*old_dbname;
	Oid         datdba;
	Datum		*new_record;
	bool        *new_record_nulls;
	Relation	sysdatabase_rel;
	HeapTuple	tuple;
	List	  	*parsetree_list;
	ListCell   	*parsetree_item;
	const char  *dbo_scm;
	const char 	*dbo_role;
	const char  *db_owner_role;
	NameData 	default_collation;
	const char  *guest;
	const char	*prev_current_user;

	/* TODO: Extract options */

	if (DbidIsValid(get_db_id(dbname)))
		ereport(ERROR,
			(errcode(ERRCODE_DUPLICATE_DATABASE),
			errmsg("Database '%s' already exists. Choose a different database name.",
					dbname)));

	tuple = SearchSysCache1(COLLOID, ObjectIdGetDatum(get_server_collation_oid_internal()));
	if (!HeapTupleIsValid(tuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				errmsg("collation with OID %u does not exist", get_server_collation_oid_internal())));
	default_collation = ((Form_pg_collation) GETSTRUCT(tuple))->collname;
	ReleaseSysCache(tuple);

	/* single-db mode check */
	if (SINGLE_DB == get_migration_mode())
	{
		const char *user_dbname = get_one_user_db_name();
		if (user_dbname)
		 	ereport(ERROR,
 				 (errcode(ERRCODE_DUPLICATE_DATABASE),
                	errmsg("Only one user database allowed under single-db mode. User database \"%s\" already exists",
							user_dbname)));
	}

	if (!have_createdb_privilege())
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("permission denied to create database")));

	/* dbowner is always sysadmin */
	datdba = get_role_oid("sysadmin", false);
	check_is_member_of_role(GetSessionUserId(), datdba);

	/* pre check availablity of critical structures */
	dbo_scm = get_dbo_schema_name(dbname);
	dbo_role = get_dbo_role_name(dbname);
	db_owner_role = get_db_owner_name(dbname);
	guest = get_guest_role_name(dbname);

	if (SearchSysCacheExists1(NAMESPACENAME, PointerGetDatum(dbo_scm)))
		ereport(NOTICE,
				(errcode(ERRCODE_DUPLICATE_SCHEMA),
				 errmsg("schema \"%s\" already exists, skipping", dbo_scm)));

	if (OidIsValid(get_role_oid(dbo_role, true)))
		ereport(ERROR,
			(errcode(ERRCODE_DUPLICATE_OBJECT),
					errmsg("role \"%s\" already exists", dbo_role)));

	if (OidIsValid(get_role_oid(db_owner_role, true)))
		ereport(ERROR,
			(errcode(ERRCODE_DUPLICATE_OBJECT),
					errmsg("role \"%s\" already exists", db_owner_role)));

	/* For simplicity, do not allow bbf db name clides with pg dbnames */
	/* TODO: add another check in orignal createdb */
	if (OidIsValid(get_database_oid(dbname, true)))
		ereport(ERROR,
				(errcode(ERRCODE_DUPLICATE_DATABASE),
				 errmsg("postgres database \"%s\" already exists", dbname)));

	sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);

	/* Get new DB ID. Need sysadmin to do that. */
	prev_current_user = GetUserNameFromId(GetUserId(), false);
	SetConfigOption("role", "sysadmin", PGC_SUSET, PGC_S_DATABASE_USER);
	if ((dbid = getAvailDbid()) == InvalidDbid)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_DATABASE_DEFINITION),
				 errmsg("cannot find an available ID for database \"%s\"", dbname)));
	SetConfigOption("role", prev_current_user, PGC_SUSET, PGC_S_DATABASE_USER);

	/* Write catalog entry */
	new_record = palloc0(sizeof(Datum) * SYSDATABASES_NUM_COLS);
	new_record_nulls = palloc0(sizeof(bool) * SYSDATABASES_NUM_COLS);


	new_record[0] = Int16GetDatum(dbid);
	new_record[1] = Int32GetDatum(0);
	new_record[2] = Int32GetDatum(0);
	new_record[3] = CStringGetDatum(owner);
	new_record[4] = NameGetDatum(&default_collation);
	new_record[5] = CStringGetTextDatum(dbname);
	new_record[6] = TimestampGetDatum(GetSQLLocalTimestamp(0));
	new_record[7] = CStringGetTextDatum("{}");

	tuple = heap_form_tuple(RelationGetDescr(sysdatabase_rel),
							new_record, new_record_nulls);

	CatalogTupleInsert(sysdatabase_rel, tuple);

	table_close(sysdatabase_rel, RowExclusiveLock);

	/* Advance cmd counter to make the database visible */
	CommandCounterIncrement();

	parsetree_list = gen_createdb_subcmds(dbo_scm, dbo_role, db_owner_role, guest);

	/* Set current user to session user for create permissions */
	prev_current_user = GetUserNameFromId(GetUserId(), false);

	SetConfigOption("role", "sysadmin", PGC_SUSET, PGC_S_DATABASE_USER);

	old_dbid = get_cur_db_id();
	old_dbname = get_cur_db_name();
	set_cur_db(dbid, dbname);  /* tempororaily set current dbid as the new id */

	PG_TRY();
	{
		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 18;

			/* do this step */
			ProcessUtility(wrapper,
						   "(CREATE LOGICAL DATABASE )",
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
		set_cur_db(old_dbid, old_dbname);
	}
	PG_CATCH();
	{
		/* Clean up. Restore previous state. */
		SetConfigOption("role",
						prev_current_user,
						PGC_SUSET,
						PGC_S_DATABASE_USER);
		set_cur_db(old_dbid, old_dbname);
		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Set current user back to previous user */
	SetConfigOption("role", prev_current_user, PGC_SUSET, PGC_S_DATABASE_USER);

	return dbid;
}

void
drop_bbf_db(const char *dbname, bool missing_ok, bool force_drop)
{
	volatile Relation   sysdatabase_rel;
	HeapTuple 			tuple;
	Form_sysdatabases 	bbf_db;
	int16				dbid;
	const char 			*dbo_role;
	const char        	*db_owner_role;
	const char        	*guest;
	const char        	*schema_name;
	List	   			*parsetree_list;
	ListCell   			*parsetree_item;
	const char			*prev_current_user;
	ScanKeyData			scanKey;
	volatile SysScanDesc scan;

	if ((strcmp(dbname, "master") == 0) || (strcmp(dbname, "tempdb") == 0))
		if (!force_drop)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Cannot drop database \"%s\", because it is a system database", dbname)));

	/* Check if the DB exist */
	sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);

	ScanKeyInit(&scanKey,
				Anum_sysdatabaese_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(dbname));
	scan = systable_beginscan(sysdatabase_rel, sysdatabaese_idx_name_oid, true,
				NULL, 1, &scanKey);
	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple))
	{
		/* Close pg_database, release the lock, since we changed nothing */
		systable_endscan(scan);
		table_close(sysdatabase_rel, RowExclusiveLock);
		if (!missing_ok)
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					 errmsg("database \"%s\" does not exist", dbname)));
		}
		else
		{
			ereport(NOTICE,
					(errmsg("database \"%s\" does not exist, skipping",
							dbname)));
			return;
		}
	}

	bbf_db = ((Form_sysdatabases) GETSTRUCT(tuple));
	dbid = bbf_db->dbid;

	/* Check if the database is in use */
	if (dbid == get_cur_db_id())
		ereport(ERROR,
				(errcode(ERRCODE_CHECK_VIOLATION),
				 errmsg("Cannot drop database \"%s\" because it is currently in use", dbname)));

	/* Set current user to session user for dropping permissions */
	prev_current_user = GetUserNameFromId(GetUserId(), false);

	SetConfigOption("role", "sysadmin", PGC_SUSET, PGC_S_DATABASE_USER);

	PG_TRY();
	{
		Oid roleid = GetSessionUserId();

		if (!has_privs_of_role(roleid, get_role_oid("sysadmin", false)))
			aclcheck_error(ACLCHECK_NOT_OWNER, OBJECT_DATABASE,
						   dbname);

		/* Get a session-level exclusive lock on the new logical db we are trying to drop */
		if (!TryLockLogicalDatabaseForSession(dbid, ExclusiveLock))
			ereport(ERROR,
					(errcode(ERRCODE_CHECK_VIOLATION),
					 errmsg("Cannot drop database \"%s\" because it is currently in use"
							" in another session", dbname)));

		CatalogTupleDelete(sysdatabase_rel, &tuple->t_self);

		systable_endscan(scan);
		scan = NULL;
		table_close(sysdatabase_rel, RowExclusiveLock);
		sysdatabase_rel = NULL;

		/* Advance cmd counter to make the delete visible */
		CommandCounterIncrement();

		schema_name = get_dbo_schema_name(dbname);
		dbo_role = get_dbo_role_name(dbname);
		db_owner_role = get_db_owner_name(dbname);
		guest = get_guest_role_name(dbname);
		parsetree_list = gen_dropdb_subcmds(schema_name, dbo_role, db_owner_role, guest);

		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 16;

			/* do this step */
			ProcessUtility(wrapper,
						   "(DROP DATABASE )",
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
		/* clean up bbf namespace catalog accordingly */
		drop_related_bbf_namespace_entries(dbid);

		/* Release the session-level exclusive lock */
		UnlockLogicalDatabaseForSession(dbid, ExclusiveLock, true);
	}
	PG_CATCH();
	{
		/* Clean up. Restore previous state. */
		SetConfigOption("role",
						prev_current_user,
						PGC_SUSET,
						PGC_S_DATABASE_USER);

		UnlockLogicalDatabaseForSession(dbid, ExclusiveLock, false);

		if (scan)
			systable_endscan(scan);

		if (sysdatabase_rel)
			table_close(sysdatabase_rel, RowExclusiveLock);

		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Set current user back to previous user */
	SetConfigOption("role", prev_current_user, PGC_SUSET, PGC_S_DATABASE_USER);
}

PG_FUNCTION_INFO_V1(create_builtin_dbs);
Datum create_builtin_dbs(PG_FUNCTION_ARGS)
{	
	const char  *sql_dialect_value_old;
	const char  *tsql_dialect = "tsql";
	const char  *sa_name = text_to_cstring(PG_GETARG_TEXT_PP(0));

	sql_dialect_value_old = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", tsql_dialect,
							(superuser() ? PGC_SUSET : PGC_USERSET),
				  			PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		do_create_bbf_db("master", NULL, sa_name);
		do_create_bbf_db("tempdb", NULL, sa_name);
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
							(superuser() ? PGC_SUSET : PGC_USERSET),
				  			PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
							(superuser() ? PGC_SUSET : PGC_USERSET),
				  			PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

	}
	PG_END_TRY();
	PG_RETURN_INT32(0);
}

#define DROP_DB_BATCH_SIZE 32
PG_FUNCTION_INFO_V1(drop_all_dbs);
Datum drop_all_dbs(PG_FUNCTION_ARGS)
{
	Relation		sysdatabase_rel;
	TableScanDesc 	scan;
	HeapTuple 		tuple;
	char*          	dbnames[DROP_DB_BATCH_SIZE];
	bool			is_null;
	bool            all_db_dropped = false;
	const char  *sql_dialect_value_old;
	const char  *tsql_dialect = "tsql";

	sql_dialect_value_old = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", tsql_dialect,
							(superuser() ? PGC_SUSET : PGC_USERSET),
				  			PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		/* drop built-in DBs */
		drop_bbf_db("master", false, true);
		drop_bbf_db("tempdb", false, true);

		/* drop user created DBs */
		while (!all_db_dropped)
		{
			int i = 0, j;

			sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);
			scan = table_beginscan_catalog(sysdatabase_rel, 0, NULL);
			tuple = heap_getnext(scan, ForwardScanDirection);

			while (HeapTupleIsValid(tuple) && i < DROP_DB_BATCH_SIZE) 
			{
				Datum name = heap_getattr(tuple, Anum_sysdatabaese_name,
										  sysdatabase_rel->rd_att, &is_null);
				dbnames[i] = TextDatumGetCString(name);
				i++;

				tuple = heap_getnext(scan, ForwardScanDirection);
			}
			table_endscan(scan);
			table_close(sysdatabase_rel, RowExclusiveLock);
			
			for (j = 0; j < i; j++)
				drop_bbf_db(dbnames[j], false, true);

			if (!tuple)
				all_db_dropped = true;
		}
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
							(superuser() ? PGC_SUSET : PGC_USERSET),
				  			PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
							(superuser() ? PGC_SUSET : PGC_USERSET),
				  			PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		PG_RE_THROW();
	}
	PG_END_TRY();

	PG_RETURN_INT32(0);
}

static List *
grant_guest_to_logins(StringInfoData *query)
{
	Relation		login_rel;
	TableScanDesc	scan;
	HeapTuple		tuple;
	bool			is_null;
	List			*logins = NIL;

	login_rel = table_open(get_authid_login_ext_oid(), AccessShareLock);
	scan = table_beginscan_catalog(login_rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		Datum rolname = heap_getattr(tuple,
									 LOGIN_EXT_ROLNAME+1,
									 login_rel->rd_att,
									 &is_null);
		const char *name = NameStr(*(DatumGetName(rolname)));
		Oid roleid = get_role_oid(name, false);

		if (!role_is_sa(roleid))
		{
			RoleSpec *tmp = makeNode(RoleSpec);
			tmp->roletype = ROLESPEC_CSTRING;
			tmp->location = -1;
			tmp->rolename = pstrdup(name);
			logins = lappend(logins, tmp);
		}
		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	table_endscan(scan);
	table_close(login_rel, AccessShareLock);

	if (list_length(logins) > 0)
		appendStringInfo(query, "GRANT dummy TO dummy; ");

	return logins;
}

static void
drop_related_bbf_namespace_entries(int16 dbid)
{
	Relation		namespace_rel;
	AttrNumber		attnum;
	TableScanDesc	scan;
	ScanKeyData		key[1];
	HeapTuple		tuple;

	namespace_rel = table_open(namespace_ext_oid, RowExclusiveLock);
	attnum = (AttrNumber) attnameAttNum(namespace_rel, "dbid", false);
	if (attnum == InvalidAttrNumber)
		ereport(ERROR, 
				(errcode(ERRCODE_UNDEFINED_COLUMN),
				 errmsg("column \"dbid\" of relation \"%s\" does not exist",
						RelationGetRelationName(namespace_rel))));

	ScanKeyInit(&key[0], 
				attnum,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	scan = table_beginscan_catalog(namespace_rel, 1, key);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		CatalogTupleDelete(namespace_rel, &tuple->t_self);
		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	table_endscan(scan);
	table_close(namespace_rel, RowExclusiveLock);
}
