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
#include "commands/extension.h"
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
#include "utils/regproc.h"
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
#include "extendedproperty.h"

#define NOT_FOUND -1

Oid sys_babelfish_db_seq_oid = InvalidOid;

static Oid get_sys_babelfish_db_seq_oid(void);
static List *gen_createdb_subcmds(const char *dbname,
								  const char *owner);
static List *gen_dropdb_subcmds(const char *dbname,
								List *db_users);
static void add_fixed_user_roles_to_bbf_authid_user_ext(const char *dbname);
static Oid	do_create_bbf_db(ParseState *pstate, const char *dbname, List *options, const char *owner);
static void create_bbf_db_internal(ParseState *pstate, const char *dbname, List *options, const char *owner, int16 dbid);
static void drop_related_bbf_namespace_entries(int16 dbid);


static Oid
get_sys_babelfish_db_seq_oid()
{
	if(!OidIsValid(sys_babelfish_db_seq_oid))
	{
		RangeVar	*sequence = makeRangeVarFromNameList(stringToQualifiedNameList("sys.babelfish_db_seq", NULL));
		Oid			seqid = RangeVarGetRelid(sequence, NoLock, false);
		
		Assert(OidIsValid(seqid));
		sys_babelfish_db_seq_oid = seqid;
	}
	return sys_babelfish_db_seq_oid;
}

/*
 * Generate subcmds for CREATE DATABASE. Note 'guest' can be NULL.
 */
static List *
gen_createdb_subcmds(const char *dbname, const char *owner)
{
	StringInfoData query;
	List           *res;
	List           *logins = NIL;
	Node           *stmt;
	int            i = 0;
	int            expected_stmt_num;
	const char     *schema;
	const char     *dbo;
	const char     *db_owner;
	const char     *db_accessadmin;
	const char     *db_securityadmin;
	const char     *db_ddladmin;
	const char     *guest;
	const char     *guest_schema;
	Oid       	owner_oid;
	bool     	owner_is_sa_or_superuser = false;
	const char     *db_datareader;
	const char     *db_datawriter;

	schema = get_dbo_schema_name(dbname);
	dbo = get_dbo_role_name(dbname);
	db_owner = get_db_owner_name(dbname);
	db_accessadmin = get_db_accessadmin_role_name(dbname);
	db_securityadmin = get_db_securityadmin_role_name(dbname);
	guest = get_guest_role_name(dbname);
	guest_schema = get_guest_schema_name(dbname);
	owner_oid = get_role_oid(owner, true);
	db_datareader = get_db_datareader_name(dbname);
	db_datawriter = get_db_datawriter_name(dbname);
	db_ddladmin = get_db_ddladmin_role_name(dbname);

	if (superuser_arg(owner_oid) || role_is_sa(owner_oid))
		owner_is_sa_or_superuser = true;
	/*
	 * To avoid SQL injection, we generate statement parsetree with dummy
	 * values and update them later
	 */
	initStringInfo(&query);

	appendStringInfo(&query, "CREATE ROLE dummy CREATEROLE INHERIT; ");
	appendStringInfo(&query, "CREATE ROLE dummy INHERIT CREATEROLE ROLE sysadmin IN ROLE dummy; ");
	appendStringInfo(&query, "GRANT CREATE, CONNECT, TEMPORARY ON DATABASE dummy TO dummy; ");
	
	/* Only grant dbo to owner if owner is not master user or superuser  */
	if (!owner_is_sa_or_superuser)
		appendStringInfo(&query, "GRANT dummy TO dummy; ");

	appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
	appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");

	/* create db_accessadmin for database */
	appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
	appendStringInfo(&query, "GRANT CREATE ON DATABASE dummy TO dummy; ");

	/* create db_securityadmin */
	appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
	appendStringInfo(&query, "GRANT CREATE ON DATABASE dummy TO dummy; ");

	/* create db_ddladmin for database */
	appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
	appendStringInfo(&query, "GRANT CREATE ON DATABASE dummy TO dummy; ");

	if (guest)
	{
		appendStringInfo(&query, "CREATE ROLE dummy INHERIT ROLE dummy; ");
		logins = grant_guest_to_logins(&query);
	}

	appendStringInfo(&query, "CREATE SCHEMA dummy AUTHORIZATION dummy; ");

	/* create sysdatabases under current DB's DBO schema */
	appendStringInfo(&query, "CREATE VIEW dummy.sysdatabases AS SELECT * FROM sys.sysdatabases; ");
	appendStringInfo(&query, "ALTER VIEW dummy.sysdatabases OWNER TO dummy; ");

	/* create guest schema in the database. This has to be the last statement */
	if (guest)
		appendStringInfo(&query, "CREATE SCHEMA dummy AUTHORIZATION dummy; ");

	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if (guest)
	{
		if (!owner_is_sa_or_superuser)
			expected_stmt_num = list_length(logins) > 0 ? 18 : 17;
		else
			expected_stmt_num = list_length(logins) > 0 ? 17 : 16;
	}
	else
	{
		expected_stmt_num = 14;

		if (!owner_is_sa_or_superuser)
			expected_stmt_num++;
	}

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
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, dbo, NULL);

	if (!owner_is_sa_or_superuser)
	{
		/* Grant dbo role to owner */
		stmt = parsetree_nth_stmt(res, i++);
		update_GrantRoleStmt(stmt, list_make1(make_accesspriv_node(dbo)),
							list_make1(make_rolespec_node(owner)));
	}

	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, db_datareader, db_owner, NULL);

	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, db_datawriter, db_owner, NULL);

	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, db_accessadmin, db_owner, NULL);

	stmt = parsetree_nth_stmt(res, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_accessadmin, NULL);

	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, db_securityadmin, db_owner, NULL);

	stmt = parsetree_nth_stmt(res, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_securityadmin, NULL);

	stmt = parsetree_nth_stmt(res, i++);
	update_CreateRoleStmt(stmt, db_ddladmin, db_owner, NULL);

	stmt = parsetree_nth_stmt(res, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_ddladmin, NULL);

	if (guest)
	{
		stmt = parsetree_nth_stmt(res, i++);
		update_CreateRoleStmt(stmt, guest, db_owner, NULL);

		if (list_length(logins) > 0)
		{
			stmt = parsetree_nth_stmt(res, i++);
			update_GrantRoleStmt(stmt, list_make1(make_accesspriv_node(guest)), logins);
		}
	}

	stmt = parsetree_nth_stmt(res, i++);
	update_CreateSchemaStmt(stmt, schema, db_owner);

	stmt = parsetree_nth_stmt(res, i++);
	update_ViewStmt(stmt, schema);

	stmt = parsetree_nth_stmt(res, i++);
	update_AlterTableStmt(stmt, schema, db_owner);

	if (guest)
	{
		stmt = parsetree_nth_stmt(res, i++);
		update_CreateSchemaStmt(stmt, guest_schema, guest);
	}

	pfree((char *) schema);
	pfree((char *) dbo);
	pfree((char *) db_owner);
	pfree((char *) db_accessadmin);
	pfree((char *) db_securityadmin);
	pfree((char *) guest);
	pfree((char *) guest_schema);

	return res;
}

static void
add_fixed_user_roles_to_bbf_authid_user_ext(const char *dbname)
{
	const char     *dbo;
	const char     *db_owner;
	const char     *db_accessadmin;
	const char     *db_securityadmin;
	const char     *db_datareader;
	const char     *db_datawriter;
	const char     *db_ddladmin;
	const char     *guest;

	dbo = get_dbo_role_name(dbname);
	db_owner = get_db_owner_name(dbname);
	db_accessadmin = get_db_accessadmin_role_name(dbname);
	db_securityadmin = get_db_securityadmin_role_name(dbname);
	guest = get_guest_role_name(dbname);
	db_datareader = get_db_datareader_name(dbname);
	db_datawriter = get_db_datawriter_name(dbname);
	db_ddladmin = get_db_ddladmin_role_name(dbname);

	add_to_bbf_authid_user_ext(dbo, DBO, dbname, DBO, NULL, false, true, false);
	add_to_bbf_authid_user_ext(db_owner, DB_OWNER, dbname, NULL, NULL, true, true, false);
	add_to_bbf_authid_user_ext(db_accessadmin, DB_ACCESSADMIN, dbname, NULL, NULL, true, true, false);
	add_to_bbf_authid_user_ext(db_securityadmin, DB_SECURITYADMIN, dbname, NULL, NULL, true, false, false);
	add_to_bbf_authid_user_ext(db_datareader, DB_DATAREADER, dbname, NULL, NULL, true, false, false);
	add_to_bbf_authid_user_ext(db_datawriter, DB_DATAWRITER, dbname, NULL, NULL, true, false, false);
	add_to_bbf_authid_user_ext(db_ddladmin, DB_DDLADMIN, dbname, NULL, NULL, true, false, false);

	/*
	 * For master, tempdb and msdb databases, the guest user will be
	 * enabled by default
	 */
	if (IS_BBF_BUILT_IN_DB(dbname))
		add_to_bbf_authid_user_ext(guest, "guest", dbname, "guest", NULL, false, true, false);
	else
		add_to_bbf_authid_user_ext(guest, "guest", dbname, "guest", NULL, false, false, false);

	pfree((char *) dbo);
	pfree((char *) db_owner);
	pfree((char *) db_accessadmin);
	pfree((char *) db_securityadmin);
	pfree((char *) guest);
}

/*
 * Generate subcmds for DROP DATABASE. Note 'guest' can be NULL.
 */
static List *
gen_dropdb_subcmds(const char *dbname, List *db_users)
{
	StringInfoData query;
	List	   *stmt_list;
	ListCell   *elem;
	Node	   *stmt;
	int         expected_stmts = 14;
	int         i = 0;
	const char *dbo;
	const char *db_owner;
	const char *db_accessadmin;
	const char *db_securityadmin;
	const char *schema;
	const char *guest_schema;
	const char *db_datareader;
	const char *db_datawriter;
	const char *db_ddladmin;

	dbo = get_dbo_role_name(dbname);
	db_owner = get_db_owner_name(dbname);
	db_accessadmin = get_db_accessadmin_role_name(dbname);
	db_securityadmin = get_db_securityadmin_role_name(dbname);
	schema = get_dbo_schema_name(dbname);
	guest_schema = get_guest_schema_name(dbname);
	db_datareader = get_db_datareader_name(dbname);
	db_datawriter = get_db_datawriter_name(dbname);
	db_ddladmin = get_db_ddladmin_role_name(dbname);

	initStringInfo(&query);
	appendStringInfo(&query, "DROP SCHEMA dummy CASCADE; ");
	appendStringInfo(&query, "DROP SCHEMA dummy CASCADE; ");

	/* First drop guest user and custom users if they exist */
	foreach(elem, db_users)
	{
		char	   *user_name = (char *) lfirst(elem);
		char 	   *original_user_name = get_authid_user_ext_original_name(user_name, dbname);

		if (!IS_FIXED_DB_PRINCIPAL(original_user_name))
		{
			appendStringInfo(&query, "DROP OWNED BY dummy CASCADE; ");
			appendStringInfo(&query, "DROP ROLE dummy; ");
			expected_stmts += 2;
		}

		pfree(original_user_name);
	}
	appendStringInfo(&query, "DROP OWNED BY dummylist CASCADE; ");

	/* 
	 * Then drop db_ddladmin, db_datareader, db_datawriter, db_securityadmin, db_accessadmin,
	 * db_owner and dbo in that order
	 */
	appendStringInfo(&query, "REVOKE CREATE ON DATABASE dummy FROM dummy; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");

	appendStringInfo(&query, "DROP ROLE dummy; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");

	appendStringInfo(&query, "REVOKE CREATE ON DATABASE dummy FROM dummy; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");

	appendStringInfo(&query, "REVOKE CREATE ON DATABASE dummy FROM dummy; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");
	appendStringInfo(&query, "REVOKE CREATE, CONNECT, TEMPORARY ON DATABASE dummy FROM dummy; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");
	appendStringInfo(&query, "DROP ROLE dummy; ");

	stmt_list = raw_parser(query.data, RAW_PARSE_DEFAULT);
	if (list_length(stmt_list) != expected_stmts)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected %d statements, but got %d statements after parsing",
						expected_stmts, list_length(stmt_list))));

	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropStmt(stmt, schema);

	/* Drop guest schema */
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropStmt(stmt, guest_schema);

	foreach(elem, db_users)
	{
		char	   *user_name = (char *) lfirst(elem);
		char 	   *original_user_name = get_authid_user_ext_original_name(user_name, dbname);

		if (!IS_FIXED_DB_PRINCIPAL(original_user_name))
		{
			stmt = parsetree_nth_stmt(stmt_list, i++);
			update_DropOwnedStmt(stmt, list_make1(user_name));

			stmt = parsetree_nth_stmt(stmt_list, i++);
			update_DropRoleStmt(stmt, user_name);
		}

		pfree(original_user_name);
	}

	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropOwnedStmt(stmt, list_make5(pstrdup(db_ddladmin), pstrdup(db_securityadmin), pstrdup(db_accessadmin), pstrdup(db_owner), pstrdup(dbo)));

	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_ddladmin, NULL);
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropRoleStmt(stmt, db_ddladmin);
	
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropRoleStmt(stmt, db_datareader);
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropRoleStmt(stmt, db_datawriter);

	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_securityadmin, NULL);
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropRoleStmt(stmt, db_securityadmin);

	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_accessadmin, NULL);
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropRoleStmt(stmt, db_accessadmin);

	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, dbo, NULL);
	
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropRoleStmt(stmt, db_owner);
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_DropRoleStmt(stmt, dbo);

	pfree((char *) dbo);
	pfree((char *) db_owner);
	pfree((char *) db_accessadmin);
	pfree((char *) db_securityadmin);
	pfree((char *) schema);
	pfree((char *) guest_schema);

	return stmt_list;
}

Oid
create_bbf_db(ParseState *pstate, const CreatedbStmt *stmt)
{
	const char *owner = GetUserNameFromId(GetSessionUserId(), false);
	
	return do_create_bbf_db(pstate, stmt->dbname, stmt->options, owner);
}

/*
 * To guard the rare case that we have used up all the possible sequence values
 * and it wraps around, check if the next seq value is used by an existing DB.
 * Also, we reserved four IDs 1-4 for native databases, 1,2 and 4 are created when
 * initializing babelfishpg_tsql (master, tempdb, and msdb, respectively), 3 is just a placeholder that
 * we currently don't have plan to support. New user database will start from ID=5.
 *
 * If we can't find one after looping the entire range of sequence values
 * (1 to 32767), we should bail out.
 */
static int16
getAvailDbid(void)
{
	int16		dbid;
	int16		start = 0;

	if(GetUserId() != get_role_oid("sysadmin", true))
		return InvalidDbid;

	do
	{
		dbid = nextval_internal(get_sys_babelfish_db_seq_oid(), false);
		if (start == 0)
			start = dbid;
		else if (start == dbid)
			return InvalidDbid;
	} while (dbid == 3 || get_db_name(dbid) != NULL);

	return dbid;
}

/*
 * Only called while restoring a Babelfish logical database to get new
 * dbid for database being restored. The value returned will be used in
 * filling missing dbid column values in a tuple being inserted into catalog
 * table.
 * The function will return either new generated dbid in case we are inserting
 * into sys.babelfish_sysdatabases catalog or last used dbid for all other
 * catalogs.
 */
int16
getDbidForLogicalDbRestore(Oid relid)
{
	const char *prev_current_user;
	int16		dbid;

	/* Get new DB ID. Need sysadmin to do that. */
	prev_current_user = GetUserNameFromId(GetUserId(), false);
	bbf_set_current_user("sysadmin");

	/*
	 * For sysdatabases table we need to generate new dbid for the database we
	 * are currently restoring.
	 */
	if (relid == sysdatabases_oid)
	{
		if ((dbid = getAvailDbid()) == InvalidDbid)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_DATABASE_DEFINITION),
					 errmsg("cannot find an available ID for new database.")));
	}

	/*
	 * For all the other catalog tables which contain dbid column, get dbid
	 * using current value of the babelfish_db_seq sequence. It is ok to fetch
	 * current value of the sequence here since we already have generated new
	 * dbid while inserting into sysdatabases catalog.
	 */
	else
		dbid = DirectFunctionCall1(currval_oid, get_sys_babelfish_db_seq_oid());

	bbf_set_current_user(prev_current_user);

	return dbid;
}

static Oid
do_create_bbf_db(ParseState *pstate, const char *dbname, List *options, const char *owner)
{
	int16		dbid;
	const char *prev_current_user;

	if (DbidIsValid(get_db_id(dbname)))
		ereport(ERROR,
				(errcode(ERRCODE_DUPLICATE_DATABASE),
				 errmsg("Database '%s' already exists. Choose a different database name.",
						dbname)));

	/* Get new DB ID. Need sysadmin to do that. */
	prev_current_user = GetUserNameFromId(GetUserId(), false);
	bbf_set_current_user("sysadmin");
	if ((dbid = getAvailDbid()) == InvalidDbid)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_DATABASE_DEFINITION),
				 errmsg("cannot find an available ID for database \"%s\"", dbname)));
	bbf_set_current_user(prev_current_user);

	create_bbf_db_internal(pstate, dbname, options, owner, dbid);

	return dbid;
}

static void
check_database_collation_name(const char *database_collation_name)
{
	coll_info_t coll_info_of_inputcollid;

	if (tsql_find_collation_internal(database_collation_name) == NOT_FOUND)
	{
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("\"%s\" is not currently supported for database collation ", database_collation_name)));
	}

	/* Block any non-LATIN and CS collation */
	coll_info_of_inputcollid = tsql_lookup_collation_table_internal(
		get_collation_oid(list_make1(makeString((char*) database_collation_name)), false));

	if (!supported_collation_for_db_and_like(coll_info_of_inputcollid.code_page) 
		|| coll_info_of_inputcollid.collateflags == 0x000c /* CS_AS */
		|| coll_info_of_inputcollid.collateflags == 0x000e /* CS_AI */)
	{
		const char *server_collation_name = GetConfigOption("babelfishpg_tsql.server_collation_name", false, false);
		if (server_collation_name && strcmp(server_collation_name, database_collation_name))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					errmsg("\"%s\" is not currently supported for database collation ", database_collation_name)));
	}
}

static void
create_bbf_db_internal(ParseState *pstate, const char *dbname, List *options, const char *owner, int16 dbid)
{
	int16       old_dbid;
	char        *old_dbname;
	Datum       *new_record;
	bool        *new_record_nulls;
	Relation    sysdatabase_rel;
	HeapTuple   tuple;
	List        *parsetree_list;
	ListCell    *parsetree_item;
	char        *dbo_role;
	NameData    default_collation;
	NameData    owner_namedata;
	int         stmt_number = 0;
	int         save_sec_context;
	bool        is_set_userid = false;
	Oid         save_userid;
	const char  *old_createrole_self_grant;
	ListCell    *option;
	const char  *database_collation_name = NULL;

	/* Check options */
	foreach(option, options)
	{
		DefElem    *defel = (DefElem *) lfirst(option);

		if (strcmp(defel->defname, "collate") == 0)
		{
			database_collation_name = tsql_translate_tsql_collation_to_bbf_collation(defGetString(defel));
			check_database_collation_name(database_collation_name);
		}
		else
		{
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("option \"%s\" not recognized", defel->defname),
					 parser_errposition(pstate, defel->location)));
		}	
	}

	if (database_collation_name == NULL)
	{
		database_collation_name = tsql_translate_tsql_collation_to_bbf_collation(GetConfigOption("babelfishpg_tsql.server_collation_name", false, false));
		if (tsql_find_collation_internal(database_collation_name) == NOT_FOUND)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					errmsg("\"%s\" is not currently supported for database collation ", database_collation_name)));
	}
	namestrcpy(&default_collation, database_collation_name);

	/* single-db mode check. IDs 1-4 are reserved for native system databases */
	if (SINGLE_DB == get_migration_mode() && dbid > 4)
	{
		const char *user_dbname = get_one_user_db_name();

		if (user_dbname)
			ereport(ERROR,
					(errcode(ERRCODE_DUPLICATE_DATABASE),
					 errmsg("Only one user database allowed under single-db mode. User database \"%s\" already exists",
							user_dbname)));
	}

	/* temporarily change to session user while checking createdb privilege */
	GetUserIdAndSecContext(&save_userid, &save_sec_context);
	PG_TRY();
	{
		SetUserIdAndSecContext(GetSessionUserId(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

		/* Session user must be member of sysadmin or dbcreator fixed server role */
		if (!has_privs_of_role(GetSessionUserId(), get_sysadmin_oid()) &&
							!has_privs_of_role(GetSessionUserId(), get_dbcreator_oid()))
			ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					errmsg("permission denied to create database")));
	}
	PG_FINALLY();
	{
		SetUserIdAndSecContext(save_userid, save_sec_context);
	}
	PG_END_TRY();

	/* For simplicity, do not allow bbf db name clides with pg dbnames */
	/* TODO: add another check in orignal createdb */
	if (OidIsValid(get_database_oid(dbname, true)))
		ereport(ERROR,
				(errcode(ERRCODE_DUPLICATE_DATABASE),
				 errmsg("postgres database \"%s\" already exists", dbname)));

	sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);

	/* Write catalog entry */
	new_record = palloc0(sizeof(Datum) * SYSDATABASES_NUM_COLS);
	new_record_nulls = palloc0(sizeof(bool) * SYSDATABASES_NUM_COLS);
	namestrcpy(&owner_namedata, owner);

	new_record[0] = Int16GetDatum(dbid);
	new_record[1] = Int32GetDatum(0);
	new_record[2] = Int32GetDatum(0);
	new_record[3] = NameGetDatum(&owner_namedata);
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

	parsetree_list = gen_createdb_subcmds(dbname, owner);

	GetUserIdAndSecContext(&save_userid, &save_sec_context);
	old_createrole_self_grant = pstrdup(GetConfigOption("createrole_self_grant", false, true));

	old_dbid = get_cur_db_id();
	old_dbname = get_cur_db_name();
	set_cur_db(dbid, dbname);	/* temporarily set current dbid as the new id */
	dbo_role = get_dbo_role_name(dbname);

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
		foreach(parsetree_item, parsetree_list)
		{
			Node	   		*stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt 	*wrapper;
			is_set_userid = false;

			if(stmt->type == T_CreateSchemaStmt || stmt->type == T_AlterTableStmt
				|| stmt->type == T_ViewStmt)
			{
				SetUserIdAndSecContext(get_role_oid(dbo_role, true),
							save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
				is_set_userid = true;
			}
			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			stmt_number++;
			if (list_length(parsetree_list) == stmt_number)
				wrapper->stmt_len = 19;
			else
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

			if(is_set_userid)
				SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

			CommandCounterIncrement();
		}
		set_cur_db(old_dbid, old_dbname);
		add_fixed_user_roles_to_bbf_authid_user_ext(dbname);
	}
	PG_FINALLY();
	{
		/* Clean up. Restore previous state. */
		SetConfigOption("createrole_self_grant", old_createrole_self_grant, PGC_USERSET, PGC_S_OVERRIDE);
		SetUserIdAndSecContext(save_userid, save_sec_context);
		set_cur_db(old_dbid, old_dbname);
	}
	PG_END_TRY();

	pfree(dbo_role);
}

void
drop_bbf_db(const char *dbname, bool missing_ok, bool force_drop)
{
	volatile Relation   sysdatabase_rel;
	HeapTuple           tuple;
	Form_sysdatabases   bbf_db;
	int16               dbid;
	char               *dbo_role;
	List               *db_users_list;
	List               *parsetree_list;
	ListCell           *parsetree_item;
	const char         *prev_current_user;
	int                save_sec_context;
	bool               is_set_userid = false;
	Oid                save_userid;

	if (IS_BBF_BUILT_IN_DB(dbname))
	{
		if (!force_drop)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Cannot drop database \"%s\", because it is a system database", dbname)));
	}

	/* Check if the DB exist */
	sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);

	tuple = SearchSysCache1(SYSDATABASENAME, CStringGetTextDatum(dbname));

	if (!HeapTupleIsValid(tuple))
	{
		/* Close pg_database, release the lock, since we changed nothing */
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

	bbf_set_current_user("sysadmin");

	PG_TRY();
	{
		Oid			roleid = GetSessionUserId();
		const char *login = GetUserNameFromId(roleid, false);
		bool		login_is_db_owner = 0 == strncmp(login, get_owner_of_db(dbname), NAMEDATALEN);

		/* Check if login has required privilege to drop the database */
		if (!(has_privs_of_role(roleid, get_sysadmin_oid()) 
			|| has_privs_of_role(roleid, get_dbcreator_oid()) || login_is_db_owner))
			aclcheck_error(ACLCHECK_NOT_OWNER, OBJECT_DATABASE,
						   dbname);

		/*
		 * Get a session-level exclusive lock on the new logical db we are
		 * trying to drop
		 */
		if (!TryLockLogicalDatabaseForSession(dbid, ExclusiveLock))
			ereport(ERROR,
					(errcode(ERRCODE_CHECK_VIOLATION),
					 errmsg("Cannot drop database \"%s\" because it is currently in use"
							" in another session", dbname)));

		CatalogTupleDelete(sysdatabase_rel, &tuple->t_self);
		ReleaseSysCache(tuple);

		table_close(sysdatabase_rel, RowExclusiveLock);

		/* Advance cmd counter to make the delete visible */
		CommandCounterIncrement();

		dbo_role = get_dbo_role_name(dbname);
		/* Get a list of all the database's users */
		db_users_list = get_authid_user_ext_db_users(dbname);

		parsetree_list = gen_dropdb_subcmds(dbname, db_users_list);

		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node	   *stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;
			is_set_userid = false;

			if(stmt->type != T_GrantStmt)
			{
				GetUserIdAndSecContext(&save_userid, &save_sec_context);
				if (stmt->type == T_DropOwnedStmt || stmt->type == T_DropRoleStmt) /* need bbf_role_admin to perform DropOwnedObjects */
					SetUserIdAndSecContext(get_bbf_role_admin_oid(),
										   save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
				else
					SetUserIdAndSecContext(get_role_oid(dbo_role, true),
										   save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
				is_set_userid = true;
			}
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
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);
			
			if(is_set_userid)
				SetUserIdAndSecContext(save_userid, save_sec_context);
			
			/* make sure later steps can see the object created here */
			CommandCounterIncrement();
		}
		/* clean up bbf view def catalog */
		clean_up_bbf_view_def(dbid);
		/* clean up bbf partition metadata */
		clean_up_bbf_partition_metadata(dbid);
		/* clean up bbf function catalog */
		clean_up_bbf_function_ext(dbid);
		/* clean up bbf namespace catalog accordingly */
		drop_related_bbf_namespace_entries(dbid);
		/* clean up corresponding db users */
		drop_related_bbf_users(db_users_list);
		/* delete extended property */
		delete_extended_property(dbid, NULL, NULL, NULL, NULL);
		/* clean up bbf schema permission catalog */
		drop_bbf_schema_permission_entries(dbid);

		/* Release the session-level exclusive lock */
		UnlockLogicalDatabaseForSession(dbid, ExclusiveLock, true);
	}
	PG_CATCH();
	{
		if(is_set_userid)
			SetUserIdAndSecContext(save_userid, save_sec_context);

		/* Clean up. Restore previous state. */
		bbf_set_current_user(prev_current_user);
		UnlockLogicalDatabaseForSession(dbid, ExclusiveLock, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	pfree(dbo_role);

	/* Set current user back to previous user */
	bbf_set_current_user(prev_current_user);
}

PG_FUNCTION_INFO_V1(create_builtin_dbs);
Datum
create_builtin_dbs(PG_FUNCTION_ARGS)
{
	const char *sql_dialect_value_old;
	const char *tsql_dialect = "tsql";
	const char *sa_name = text_to_cstring(PG_GETARG_TEXT_PP(0));

	sql_dialect_value_old = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", tsql_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		do_create_bbf_db(NULL, "master", NULL, sa_name);
		do_create_bbf_db(NULL, "tempdb", NULL, sa_name);
		do_create_bbf_db(NULL, "msdb", NULL, sa_name);
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		PG_RE_THROW();
	}
	PG_END_TRY();
	PG_RETURN_INT32(0);
}

/*  This function is only being used for the purposes of the upgrade script to add the msdb database */
/*  It was first added in babelfishpg_tsql--1.2.0--1.3.0.sql */
PG_FUNCTION_INFO_V1(create_msdb_if_not_exists);
Datum
create_msdb_if_not_exists(PG_FUNCTION_ARGS)
{
	const char *sql_dialect_value_old;
	const char *tsql_dialect = "tsql";
	const char *sa_name = text_to_cstring(PG_GETARG_TEXT_PP(0));

	if (get_db_name(4) != NULL || DbidIsValid(get_db_id("msdb")))
		PG_RETURN_INT32(0);

	sql_dialect_value_old = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", tsql_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		create_bbf_db_internal(NULL, "msdb", NULL, sa_name, 4);
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		PG_RE_THROW();
	}
	PG_END_TRY();
	PG_RETURN_INT32(0);
}

#define DROP_DB_BATCH_SIZE 32
PG_FUNCTION_INFO_V1(drop_all_dbs);
Datum
drop_all_dbs(PG_FUNCTION_ARGS)
{
	Relation	sysdatabase_rel;
	TableScanDesc scan;
	HeapTuple	tuple;
	char	   *dbnames[DROP_DB_BATCH_SIZE];
	bool		is_null;
	bool		all_db_dropped = false;
	const char *sql_dialect_value_old;
	const char *tsql_dialect = "tsql";

	sql_dialect_value_old = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", tsql_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		/* drop built-in DBs */
		drop_bbf_db("master", false, true);
		drop_bbf_db("tempdb", false, true);
		drop_bbf_db("msdb", false, true);

		/* drop user created DBs */
		while (!all_db_dropped)
		{
			int			i = 0,
						j;

			sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);
			scan = table_beginscan_catalog(sysdatabase_rel, 0, NULL);
			tuple = heap_getnext(scan, ForwardScanDirection);

			while (HeapTupleIsValid(tuple) && i < DROP_DB_BATCH_SIZE)
			{
				Datum		name = heap_getattr(tuple, Anum_sysdatabases_name,
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
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		PG_RE_THROW();
	}
	PG_END_TRY();

	PG_RETURN_INT32(0);
}

List *
grant_guest_to_logins(StringInfoData *query)
{
	Relation	login_rel;
	TableScanDesc scan;
	HeapTuple	tuple;
	bool		is_null;
	List	   *logins = NIL;

	login_rel = table_open(get_authid_login_ext_oid(), AccessShareLock);
	scan = table_beginscan_catalog(login_rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		Datum		rolname = heap_getattr(tuple,
										   LOGIN_EXT_ROLNAME + 1,
										   login_rel->rd_att,
										   &is_null);
		const char *name = NameStr(*(DatumGetName(rolname)));
		Oid			roleid = get_role_oid(name, false);

		if (!role_is_sa(roleid))
		{
			logins = lappend(logins, make_rolespec_node(name));
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
	Relation	namespace_rel;
	AttrNumber	attnum;
	TableScanDesc scan;
	ScanKeyData key[1];
	HeapTuple	tuple;

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

/*
 * Helper function to get the owner from a given database name
 * Caller is responsible for validating that the given database exists
 */
const char *
get_owner_of_db(const char *dbname)
{
	char	   *owner = NULL;
	HeapTuple	tuple;
	Form_sysdatabases sysdb;

	tuple = SearchSysCache1(SYSDATABASENAME, CStringGetTextDatum(dbname));

	if (!HeapTupleIsValid(tuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist", dbname)));

	sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
	owner = NameStr(sysdb->owner);
	ReleaseSysCache(tuple);

	return owner;
}


static void
create_schema_if_not_exists(const uint16 dbid,
							const char *dbname,
							const char *schemaname,
							const char *owner_role)
{
	StringInfoData query;
	List	   *parsetree_list;
	Oid			datdba;
	const char *prev_current_user;
	uint16		old_dbid;
	const char *old_dbname,
			   *phys_schema_name;
	char	   *phys_role;

	/*
	 * During upgrade, the migration mode is reset to single-db so we cannot
	 * call get_physical_user_name() directly. Detect whether the original
	 * migration was single-db or multi-db.
	 */
	MigrationMode baseline_mode = is_user_database_singledb(dbname) ? SINGLE_DB : MULTI_DB;

	phys_schema_name = get_physical_schema_name_by_mode((char *) dbname, schemaname, baseline_mode);

	if (SearchSysCacheExists1(NAMESPACENAME, PointerGetDatum(phys_schema_name)))
	{
		ereport(LOG,
				(errcode(ERRCODE_DUPLICATE_SCHEMA),
				 errmsg("schema \"%s\" already exists, skipping", phys_schema_name)));
		return;
	}

	/*
	 * guest role prepends dbname regardless if single-db or multi-db. If for
	 * some reason guest role does not exist, then that is a bigger problem.
	 * We skip creating the guest schema entirely instead of crashing though.
	 */
	phys_role = get_physical_user_name((char *) dbname, (char *) owner_role, false, true);
	if (!OidIsValid(get_role_oid(phys_role, true)))
	{
		ereport(LOG,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("role \"%s\" does not exist", phys_role)));
		return;
	}

	datdba = get_role_oid("sysadmin", false);
	check_can_set_role(GetSessionUserId(), datdba);

	initStringInfo(&query);
	appendStringInfo(&query, "CREATE SCHEMA %s AUTHORIZATION %s; ", schemaname, owner_role);

	parsetree_list = raw_parser(query.data, RAW_PARSE_DEFAULT);
	Assert(list_length(parsetree_list) == 1);

	/* Set current user to session user for create permissions */
	prev_current_user = GetUserNameFromId(GetUserId(), false);
	bbf_set_current_user("sysadmin");

	old_dbid = get_cur_db_id();
	old_dbname = get_cur_db_name();
	set_cur_db(dbid, dbname);

	PG_TRY();
	{
		PlannedStmt *wrapper;
		Node	   *stmt = ((RawStmt *) linitial(parsetree_list))->stmt;

		update_CreateSchemaStmt(stmt, phys_schema_name, phys_role);

		wrapper = makeNode(PlannedStmt);
		wrapper->commandType = CMD_UTILITY;
		wrapper->canSetTag = false;
		wrapper->utilityStmt = stmt;
		wrapper->stmt_location = 0;
		wrapper->stmt_len = 0;

		ProcessUtility(wrapper,
					   CREATE_GUEST_SCHEMAS_DURING_UPGRADE,
					   false,
					   PROCESS_UTILITY_SUBCOMMAND,
					   NULL,
					   NULL,
					   None_Receiver,
					   NULL);

		/* make sure later steps can see the object created here */
		CommandCounterIncrement();
	}
	PG_FINALLY();
	{
		bbf_set_current_user(prev_current_user);
		set_cur_db(old_dbid, old_dbname);
	}
	PG_END_TRY();

	pfree(phys_role);

	bbf_set_current_user(prev_current_user);
	set_cur_db(old_dbid, old_dbname);

}

/*
* This function is only being used for the purpose of the upgrade script to add
* the guest schema for each database if the database does not have the guest schema yet.
*/
PG_FUNCTION_INFO_V1(create_guest_schema_for_all_dbs);
Datum
create_guest_schema_for_all_dbs(PG_FUNCTION_ARGS)
{
	Relation	sysdatabase_rel;
	TableScanDesc scan;
	HeapTuple	tuple;
	const char *sql_dialect_value_old;
	const char *tsql_dialect = "tsql";
	Form_sysdatabases bbf_db;
	const char *dbname;
	bool		creating_extension_backup = creating_extension;

	/* We only allow this to be called from an extension's SQL script. */
	if (!creating_extension)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("%s can only be called from an SQL script executed by CREATE/ALTER EXTENSION",
						"create_guest_schema_for_all_dbs()")));

	sql_dialect_value_old = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", tsql_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		/*
		 * Since this is part of upgrade script, PG assumes we would like to
		 * set the babelfish extension depend on this new schema. This is not
		 * true so we tell PG not to set any dependency for us. Check
		 * recordDependencyOnCurrentExtension() for more information.
		 */
		creating_extension = false;

		sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);
		scan = table_beginscan_catalog(sysdatabase_rel, 0, NULL);
		tuple = heap_getnext(scan, ForwardScanDirection);

		while (HeapTupleIsValid(tuple))
		{
			bbf_db = (Form_sysdatabases) GETSTRUCT(tuple);
			dbname = text_to_cstring(&(bbf_db->name));

			create_schema_if_not_exists(bbf_db->dbid, dbname, "guest", "guest");

			tuple = heap_getnext(scan, ForwardScanDirection);
		}
		table_endscan(scan);
		table_close(sysdatabase_rel, RowExclusiveLock);

		creating_extension = creating_extension_backup;
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_FINALLY();
	{
		creating_extension = creating_extension_backup;
		set_config_option("babelfishpg_tsql.sql_dialect", sql_dialect_value_old,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_END_TRY();

	PG_RETURN_INT32(0);
}

/* Grant permissions on all the existing objects to db_datareader/db_datawriter/db_ddladmin */
static void
grant_perms_to_dbreader_dbwriter_ddladmin(const uint16 dbid,
				const char *db_datareader,
				const char *db_datawriter,
				const char *db_ddladmin)
{
	Relation    namespace_rel;
	TupleDesc   namespace_rel_descr;
	ScanKeyData key;
	HeapTuple   tuple;
	TableScanDesc	tblscan;
	StringInfoData	query;
	List		*stmt_list;
	char		*dbname = get_db_name(dbid);
	MigrationMode	baseline_mode = is_user_database_singledb(dbname) ? SINGLE_DB : MULTI_DB;

	namespace_rel = table_open(namespace_ext_oid, RowExclusiveLock);
	namespace_rel_descr = RelationGetDescr(namespace_rel);

	initStringInfo(&query);
	appendStringInfo(&query, "GRANT SELECT ON ALL TABLES IN SCHEMA dummy TO dummy; ");
	appendStringInfo(&query, "GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dummy TO dummy; ");
	appendStringInfo(&query, "GRANT TRUNCATE ON ALL TABLES IN SCHEMA dummy TO dummy; ");
	appendStringInfo(&query, "GRANT CREATE ON SCHEMA dummy TO dummy ; ");

	/* Grant ALTER DEFAULT PRIVILEGES on schema owner and dbo user. */
	appendStringInfo(&query, "ALTER DEFAULT PRIVILEGES FOR ROLE dummy, dummy IN SCHEMA dummy GRANT SELECT ON TABLES TO dummy; ");
	appendStringInfo(&query, "ALTER DEFAULT PRIVILEGES FOR ROLE dummy, dummy IN SCHEMA dummy GRANT INSERT, UPDATE, DELETE ON TABLES TO dummy; ");
	appendStringInfo(&query, "ALTER DEFAULT PRIVILEGES FOR ROLE dummy, dummy IN SCHEMA dummy GRANT TRUNCATE ON TABLES TO dummy; ");

	stmt_list = raw_parser(query.data, RAW_PARSE_DEFAULT);

	Assert(list_length(stmt_list) == 7);

	ScanKeyInit(&key,
				Anum_namespace_ext_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	tblscan = table_beginscan_catalog(namespace_rel, 1, &key);

	while ((tuple = heap_getnext(tblscan, ForwardScanDirection)) != NULL)
	{
		bool		isNull;
		Datum		datum;
		char		*schema_name;
		Node		*stmts;
		int			i = 0;
		ListCell	*parsetree_item;
		char		*schema_owner;
		char		*dbo_user;

		datum = heap_getattr(tuple, Anum_namespace_ext_namespace, namespace_rel_descr, &isNull);
		schema_name = NameStr(*DatumGetName(datum));
		schema_owner = GetUserNameFromId(get_owner_of_schema(schema_name), false);
		dbo_user = get_dbo_role_name_by_mode(dbname, baseline_mode);

		/* Replace dummy elements in parsetree with real values */
		stmts = parsetree_nth_stmt(stmt_list, i++);
		update_GrantStmt(stmts, schema_name, NULL, db_datareader, NULL);
		stmts = parsetree_nth_stmt(stmt_list, i++);
		update_GrantStmt(stmts, schema_name, NULL, db_datawriter, NULL);
		stmts = parsetree_nth_stmt(stmt_list, i++);
		update_GrantStmt(stmts, schema_name, NULL, db_ddladmin, NULL);
		stmts = parsetree_nth_stmt(stmt_list, i++);
		update_GrantStmt(stmts, schema_name, NULL, db_ddladmin, NULL);

		stmts = parsetree_nth_stmt(stmt_list, i++);
		update_AlterDefaultPrivilegesStmt(stmts, schema_name, schema_owner, dbo_user, db_datareader, NULL);
		stmts = parsetree_nth_stmt(stmt_list, i++);
		update_AlterDefaultPrivilegesStmt(stmts, schema_name, schema_owner, dbo_user, db_datawriter, NULL);
		stmts = parsetree_nth_stmt(stmt_list, i++);
		update_AlterDefaultPrivilegesStmt(stmts, schema_name, schema_owner, dbo_user, db_ddladmin, NULL);

		/* Run all subcommands */
		foreach(parsetree_item, stmt_list)
		{
			Node		*stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 0;

			/* do this step */
			ProcessUtility(wrapper,
						CREATE_FIXED_DB_ROLES,
						false,
						PROCESS_UTILITY_SUBCOMMAND,
						NULL,
						NULL,
						None_Receiver,
						NULL);
		}

		pfree(dbo_user);
		pfree(schema_owner);
	}

	/* Cleanup. */
	table_endscan(tblscan);
	table_close(namespace_rel, RowExclusiveLock);
	pfree(dbname);
	pfree(query.data);
}

static void
rolname_same_as_db_rolname(char *rolname)
{
	if (OidIsValid(get_role_oid(rolname, true)))
	{
		ereport(ERROR,
				(errcode(ERRCODE_DUPLICATE_OBJECT),
				 errmsg("role \"%s\" already exists. Please drop the role and restart upgrade.", rolname)));
	}
}

static void
create_db_roles_in_database(const char *dbname, List *parsetree_list)
{
	Node           *stmt;
	Oid            save_userid;
	int            save_sec_context;
	int            i = 0;
	char           *db_owner;
	char           *db_accessadmin;
	char           *db_securityadmin;
	char           *db_datareader;
	char           *db_datawriter;
	char           *db_ddladmin;
	int16          dbid = get_db_id(dbname);

	db_owner = get_db_owner_name(dbname);
	db_accessadmin = get_db_accessadmin_role_name(dbname);
	db_securityadmin = get_db_securityadmin_role_name(dbname);
	db_datareader = get_db_datareader_name(dbname);
	db_datawriter = get_db_datawriter_name(dbname);
	db_ddladmin = get_db_ddladmin_role_name(dbname);

	/* Throws error if a role exists already with the same name as db role. */
	rolname_same_as_db_rolname(db_accessadmin);
	rolname_same_as_db_rolname(db_datareader);
	rolname_same_as_db_rolname(db_datawriter);
	rolname_same_as_db_rolname(db_securityadmin);
	rolname_same_as_db_rolname(db_ddladmin);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_CreateRoleStmt(stmt, db_datareader, db_owner, NULL);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_CreateRoleStmt(stmt, db_datawriter, db_owner, NULL);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_CreateRoleStmt(stmt, db_accessadmin, db_owner, NULL);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_accessadmin, NULL);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_CreateRoleStmt(stmt, db_securityadmin, db_owner, NULL);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_securityadmin, NULL);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_CreateRoleStmt(stmt, db_ddladmin, db_owner, NULL);

	stmt = parsetree_nth_stmt(parsetree_list, i++);
	update_GrantStmt(stmt, get_database_name(MyDatabaseId), NULL, db_ddladmin, NULL);

	GetUserIdAndSecContext(&save_userid, &save_sec_context);

	PG_TRY();
	{
		ListCell 	*parsetree_item;

		SetConfigOption("createrole_self_grant", "inherit", PGC_USERSET, PGC_S_OVERRIDE);
		add_to_bbf_authid_user_ext(db_accessadmin, DB_ACCESSADMIN, dbname, NULL, NULL, true, true, false);
		add_to_bbf_authid_user_ext(db_securityadmin, DB_SECURITYADMIN, dbname, NULL, NULL, true, false, false);
		add_to_bbf_authid_user_ext(db_datareader, DB_DATAREADER, dbname, NULL, NULL, true, false, false);
		add_to_bbf_authid_user_ext(db_datawriter, DB_DATAWRITER, dbname, NULL, NULL, true, false, false);
		add_to_bbf_authid_user_ext(db_ddladmin, DB_DDLADMIN, dbname, NULL, NULL, true, false, false);

		SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

		foreach(parsetree_item, parsetree_list)
		{
			PlannedStmt 	*wrapper;

			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			wrapper->stmt_location = 0;

			ProcessUtility(wrapper,
						CREATE_FIXED_DB_ROLES,
						false,
						PROCESS_UTILITY_SUBCOMMAND,
						NULL,
						NULL,
						None_Receiver,
						NULL);

			CommandCounterIncrement();
		}
		/* Grant permissions on all the schemas in a database to db_datareader/db_datawriter/db_ddladmin */
		grant_perms_to_dbreader_dbwriter_ddladmin(dbid, db_datareader, db_datawriter, db_ddladmin);
	}
	PG_FINALLY();
	{
		SetUserIdAndSecContext(save_userid, save_sec_context);
		pfree(db_owner);
		pfree(db_accessadmin);
		pfree(db_securityadmin);
		pfree(db_datareader);
		pfree(db_datawriter);
		pfree(db_ddladmin);
	}
	PG_END_TRY();
}


/*
* This function is only being used during upgrade to v4.4.0
* to create database roles db_accessadmin for each database
*/
PG_FUNCTION_INFO_V1(create_db_roles_during_upgrade);
Datum
create_db_roles_during_upgrade(PG_FUNCTION_ARGS)
{
	Relation          sysdatabase_rel;
	TableScanDesc     scan;
	HeapTuple         tuple;
	StringInfoData    query;
	List              *parsetree_list;
	int               pltsql_save_nestlevel;
	int               save_nestlevel;

	if (!creating_extension)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("%s can only be called from an SQL script executed by CREATE/ALTER EXTENSION",
						"create_db_roles_during_upgrade()")));

	pltsql_save_nestlevel = pltsql_new_guc_nest_level();
	save_nestlevel = NewGUCNestLevel();

	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
							GUC_CONTEXT_CONFIG,
							PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		set_config_option("babelfishpg_tsql.migration_mode", physical_schema_name_exists(DBO) ? "single-db" : "multi-db",
							GUC_CONTEXT_CONFIG,
							PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		initStringInfo(&query);

		appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
		appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
		appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
		appendStringInfo(&query, "GRANT CREATE ON DATABASE dummy TO dummy; ");
		appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
		appendStringInfo(&query, "GRANT CREATE ON DATABASE dummy TO dummy; ");
		appendStringInfo(&query, "CREATE ROLE dummy ROLE dummy; ");
		appendStringInfo(&query, "GRANT CREATE ON DATABASE dummy TO dummy; ");

		parsetree_list = raw_parser(query.data, RAW_PARSE_DEFAULT);

		Assert(list_length(parsetree_list) == 8);

		sysdatabase_rel = table_open(sysdatabases_oid, RowExclusiveLock);
		scan = table_beginscan_catalog(sysdatabase_rel, 0, NULL);

		while ((tuple = heap_getnext(scan, ForwardScanDirection)) != NULL)
		{
			Datum 	datum;
			bool 	isnull;
			char 	*db_name;

			datum = heap_getattr(tuple, Anum_sysdatabases_name,
											sysdatabase_rel->rd_att, &isnull);

			Assert(!isnull);

			db_name = TextDatumGetCString(datum);

			create_db_roles_in_database(db_name, parsetree_list);

			pfree(db_name);
		}
	}
	PG_FINALLY();
	{
		pltsql_revert_guc(pltsql_save_nestlevel);
	}
	PG_END_TRY();

	pfree(query.data);
	AtEOXact_GUC(false, save_nestlevel);
	table_endscan(scan);
	table_close(sysdatabase_rel, RowExclusiveLock);

	PG_RETURN_INT32(0);
}

