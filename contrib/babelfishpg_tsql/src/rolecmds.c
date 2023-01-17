/*-------------------------------------------------------------------------
 *
 * rolecmds.c
 *	  Commands for manipulating roles.
 *
 * contrib/babelfishpg_tsql/src/rolecmds.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"
#include "miscadmin.h"

#include <ctype.h>
#include "access/genam.h"
#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/table.h"
#include "access/tableam.h"
#include "access/xact.h"
#include "catalog/binary_upgrade.h"
#include "catalog/catalog.h"
#include "catalog/dependency.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/objectaccess.h"
#include "catalog/pg_auth_members.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_database.h"
#include "catalog/pg_db_role_setting.h"
#include "catalog/pg_namespace.h"
#include "commands/comment.h"
#include "commands/dbcommands.h"
#include "commands/seclabel.h"
#include "commands/user.h"
#include "libpq/crypt.h"
#include "miscadmin.h"
#include "parser/parser.h"
#include "parser/scansup.h"
#include "storage/lmgr.h"
#include "storage/procarray.h"
#include "tcop/utility.h"
#include "utils/acl.h"
#include "utils/catcache.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/timestamp.h"

#include "catalog.h"
#include "multidb.h"
#include "rolecmds.h"
#include "session.h"
#include "pltsql.h"
#include "dbcmds.h"

#include <ctype.h>

static void drop_bbf_authid_login_ext(ObjectAccessType access,
										Oid classId,
										Oid roleid,
										int subId,
										void *arg);
static void drop_bbf_authid_user_ext(ObjectAccessType access,
										Oid classId,
										Oid roleid,
										int subId,
										void *arg);
static void drop_bbf_authid_user_ext_by_rolname(const char *rolname);
static void grant_guests_to_login(const char *login);
static bool has_user_in_db(const char *login, char **db_name);


void
create_bbf_authid_login_ext(CreateRoleStmt *stmt)
{
	Relation	bbf_authid_login_ext_rel;
	TupleDesc	bbf_authid_login_ext_dsc;
	HeapTuple	tuple_login_ext;
	Datum		new_record_login_ext[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	bool		new_record_nulls_login_ext[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	Oid			roleid;
	ListCell	*option;
	char		*default_database = NULL;

	/* Extract options from the statement node tree */
	foreach(option, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(option);

		if (strcmp(defel->defname, "default_database") == 0)
		{
			if (defel->arg)
				default_database = strVal(defel->arg);
		}
	}

	if (!default_database)
		default_database = "master";
	else if (get_db_id(default_database) == InvalidDbid)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("The database '%s' does not exist. Supply a valid database name. To see available databases, use sys.databases.", default_database)));

	/* Fetch roleid */
	roleid = get_role_oid(stmt->role, false);

	/* Fetch the relation */
	bbf_authid_login_ext_rel = table_open(get_authid_login_ext_oid(),
										  RowExclusiveLock);
	bbf_authid_login_ext_dsc = RelationGetDescr(bbf_authid_login_ext_rel);

	/* Build a tuple to insert */
	MemSet(new_record_login_ext, 0, sizeof(new_record_login_ext));
	MemSet(new_record_nulls_login_ext, false, sizeof(new_record_nulls_login_ext));

	new_record_login_ext[LOGIN_EXT_ROLNAME] = CStringGetDatum(stmt->role);
	new_record_login_ext[LOGIN_EXT_IS_DISABLED] = Int32GetDatum(0);
	if (strcmp(stmt->role, "sysadmin") == 0)
		new_record_login_ext[LOGIN_EXT_TYPE] = CStringGetTextDatum("R");
	else
		new_record_login_ext[LOGIN_EXT_TYPE] = CStringGetTextDatum("S");
	new_record_login_ext[LOGIN_EXT_CREDENTIAL_ID] = Int32GetDatum(-1); /* placeholder */
	new_record_login_ext[LOGIN_EXT_OWNING_PRINCIPAL_ID] = Int32GetDatum(-1); /* placeholder */
	new_record_login_ext[LOGIN_EXT_IS_FIXED_ROLE] = Int32GetDatum(0);
	new_record_login_ext[LOGIN_EXT_CREATE_DATE] = TimestampTzGetDatum(GetSQLCurrentTimestamp(-1));
	new_record_login_ext[LOGIN_EXT_MODIFY_DATE] = TimestampTzGetDatum(GetSQLCurrentTimestamp(-1));
	new_record_login_ext[LOGIN_EXT_DEFAULT_DATABASE_NAME] = CStringGetTextDatum(default_database);
	new_record_login_ext[LOGIN_EXT_DEFAULT_LANGUAGE_NAME] = CStringGetTextDatum("English"); /* placeholder */
	new_record_nulls_login_ext[LOGIN_EXT_PROPERTIES] = true;

	tuple_login_ext = heap_form_tuple(bbf_authid_login_ext_dsc,
									  new_record_login_ext,
									  new_record_nulls_login_ext);

	/* Insert new record in the bbf_authid_login_ext table */
	CatalogTupleInsert(bbf_authid_login_ext_rel, tuple_login_ext);

	/* Close bbf_authid_login_ext, but keep lock till commit */
	table_close(bbf_authid_login_ext_rel, RowExclusiveLock);

	/* Advance cmd counter to make the insert visible */
	CommandCounterIncrement();

	/* Grant membership to guests */
	if (!role_is_sa(roleid))
		grant_guests_to_login(GetUserNameFromId(roleid, false));
}

void
alter_bbf_authid_login_ext(AlterRoleStmt *stmt)
{
	Relation		bbf_authid_login_ext_rel;
	TupleDesc		bbf_authid_login_ext_dsc;
	HeapTuple		new_tuple;
	HeapTuple		tuple;
	HeapTuple		auth_tuple;
	Datum			new_record_login_ext[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	bool			new_record_nulls_login_ext[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	bool			new_record_repl_login_ext[BBF_AUTHID_LOGIN_EXT_NUM_COLS];
	ScanKeyData		scanKey;
	SysScanDesc		scan;
	Form_pg_authid	authform;
	ListCell		*option;
	char			*default_database = NULL;

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/* Extract options from the statement node tree */
	foreach(option, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(option);

		if (strcmp(defel->defname, "default_database") == 0)
		{
			if (defel->arg)
				default_database = strVal(defel->arg);
		}
	}

	if (default_database && get_db_id(default_database) == InvalidDbid)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("The database '%s' does not exist. Supply a valid database name. To see available databases, use sys.databases.", default_database)));

	/* Fetch pg_authid and roleid */
	auth_tuple = get_rolespec_tuple(stmt->role);
	authform = (Form_pg_authid) GETSTRUCT(auth_tuple);

	/* Fetch the relation */
	bbf_authid_login_ext_rel = table_open(get_authid_login_ext_oid(),
										  RowExclusiveLock);
	bbf_authid_login_ext_dsc = RelationGetDescr(bbf_authid_login_ext_rel);

	/* Advance the command counter to see the new record */
	CommandCounterIncrement();

	/* Search and obtain the tuple on the role name*/
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_login_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(stmt->role->rolename));

	scan = systable_beginscan(bbf_authid_login_ext_rel,
							  get_authid_login_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("tuple does not exist")));

	/* Build a tuple to insert */
	MemSet(new_record_login_ext, 0, sizeof(new_record_login_ext));
	MemSet(new_record_nulls_login_ext, false, sizeof(new_record_nulls_login_ext));
	MemSet(new_record_repl_login_ext, false, sizeof(new_record_repl_login_ext));

	/* flip to get is_disabled */
	new_record_login_ext[LOGIN_EXT_IS_DISABLED] = !authform->rolcanlogin;
	new_record_repl_login_ext[LOGIN_EXT_IS_DISABLED] = true;

	/* update modify_date */
	new_record_login_ext[LOGIN_EXT_MODIFY_DATE] = TimestampTzGetDatum(GetSQLCurrentTimestamp(-1));
	new_record_repl_login_ext[LOGIN_EXT_MODIFY_DATE] = true;

	/* update default_database */
	if (default_database)
	{
		new_record_login_ext[LOGIN_EXT_DEFAULT_DATABASE_NAME] = CStringGetTextDatum(default_database);
		new_record_repl_login_ext[LOGIN_EXT_DEFAULT_DATABASE_NAME] = true;
	}

	new_tuple = heap_modify_tuple(tuple,
								  bbf_authid_login_ext_dsc,
								  new_record_login_ext,
								  new_record_nulls_login_ext,
								  new_record_repl_login_ext);

	CatalogTupleUpdate(bbf_authid_login_ext_rel, &tuple->t_self, new_tuple);

	ReleaseSysCache(auth_tuple);
	systable_endscan(scan);
	heap_freetuple(new_tuple);

	/* Close bbf_authid_login_ext, but keep lock till commit */
	table_close(bbf_authid_login_ext_rel, RowExclusiveLock);
}

void
drop_bbf_roles(ObjectAccessType access,
							Oid classId,
							Oid roleid,
							int subId,
							void *arg)
{
	if (is_login(roleid))
		drop_bbf_authid_login_ext(access, classId, roleid, subId, arg);
	else if (is_user(roleid) || is_role(roleid))
		drop_bbf_authid_user_ext(access, classId, roleid, subId, arg);
}

static void
drop_bbf_authid_login_ext(ObjectAccessType access,
							Oid classId,
							Oid roleid,
							int subId,
							void *arg)
{
	Relation	bbf_authid_login_ext_rel;
	Relation	bbf_authid_user_ext_rel;
	TupleDesc	bbf_authid_user_ext_dsc;
	HeapTuple	logintuple;
	HeapTuple	usertuple;
	HeapTuple	new_tuple;
	HeapTuple	authtuple;
	Datum		new_record_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		new_record_nulls_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool		new_record_repl_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	ScanKeyData	scanKey;
	SysScanDesc	scan;
	TableScanDesc	tblscan;
	NameData	rolname;
	NameData   *invalidated_login_name;

	authtuple = SearchSysCache1(AUTHOID, ObjectIdGetDatum(roleid));
	if (!HeapTupleIsValid(authtuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("role with OID %u does not exist", roleid)));
	rolname = ((Form_pg_authid) GETSTRUCT(authtuple))->rolname;
	
	/* Fetch the relation */
	bbf_authid_login_ext_rel = table_open(get_authid_login_ext_oid(),
										  RowExclusiveLock);

	/* Search and drop on the role */
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_login_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&rolname));

	scan = systable_beginscan(bbf_authid_login_ext_rel,
							  get_authid_login_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	logintuple = systable_getnext(scan);

	if (HeapTupleIsValid(logintuple))
		CatalogTupleDelete(bbf_authid_login_ext_rel,
						   &logintuple->t_self);

	systable_endscan(scan);
	table_close(bbf_authid_login_ext_rel, RowExclusiveLock);
	ReleaseSysCache(authtuple);

	/*
	 * Invalidate the corresponding entries in user_ext which are related to
	 * this login
	 */
	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);
	bbf_authid_user_ext_dsc = RelationGetDescr(bbf_authid_user_ext_rel);

	/* Search and obtain the tuple on the login name*/
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_user_ext_login_name,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&rolname));

	tblscan = table_beginscan_catalog(bbf_authid_user_ext_rel, 1, &scanKey);

	MemSet(new_record_user_ext, 0, sizeof(new_record_user_ext));
	MemSet(new_record_nulls_user_ext, false, sizeof(new_record_nulls_user_ext));
	MemSet(new_record_repl_user_ext, false, sizeof(new_record_repl_user_ext));

	usertuple = heap_getnext(tblscan, ForwardScanDirection);

	while (HeapTupleIsValid(usertuple))
	{
		/*
		 * Insert empty string as login_name as an invalidation mark for this login
		 */
		invalidated_login_name = (NameData *) palloc0(NAMEDATALEN);
		snprintf(invalidated_login_name->data, NAMEDATALEN, "%s", "");
		new_record_user_ext[USER_EXT_LOGIN_NAME] = NameGetDatum(invalidated_login_name);
		new_record_repl_user_ext[USER_EXT_LOGIN_NAME] = true;

		new_tuple = heap_modify_tuple(usertuple,
									  bbf_authid_user_ext_dsc,
									  new_record_user_ext,
									  new_record_nulls_user_ext,
									  new_record_repl_user_ext);

		CatalogTupleUpdate(bbf_authid_user_ext_rel, &new_tuple->t_self, new_tuple);

		usertuple = heap_getnext(tblscan, ForwardScanDirection);

		heap_freetuple(new_tuple);
	}

	/* Advance the command counter to see the new record */
	CommandCounterIncrement();

	table_endscan(tblscan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
}

static void
drop_bbf_authid_user_ext(ObjectAccessType access,
							Oid classId,
							Oid roleid,
							int subId,
							void *arg)
{
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple;
	HeapTuple	authtuple;
	ScanKeyData	scanKey;
	SysScanDesc	scan;
	NameData	rolname;

	authtuple = SearchSysCache1(AUTHOID, ObjectIdGetDatum(roleid));
	if (!HeapTupleIsValid(authtuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("role with OID %u does not exist", roleid)));
	rolname = ((Form_pg_authid) GETSTRUCT(authtuple))->rolname;

	/* Fetch the relation */
	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	/* Search and drop on the role */
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&rolname));

	scan = systable_beginscan(bbf_authid_user_ext_rel,
							  get_authid_user_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (HeapTupleIsValid(tuple))
		CatalogTupleDelete(bbf_authid_user_ext_rel,
						   &tuple->t_self);

	systable_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
	ReleaseSysCache(authtuple);
}

static void
drop_bbf_authid_user_ext_by_rolname(const char *rolname)
{
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple;
	ScanKeyData	scanKey;
	SysScanDesc	scan;

	/* Fetch the relation */
	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	/* Search and drop on the role */
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(rolname));

	scan = systable_beginscan(bbf_authid_user_ext_rel,
							  get_authid_user_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (HeapTupleIsValid(tuple))
		CatalogTupleDelete(bbf_authid_user_ext_rel,
						   &tuple->t_self);

	systable_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
}

void
drop_related_bbf_users(List *db_users)
{
	ListCell *elem;

	foreach (elem, db_users)
	{
		char *user_name = (char *) lfirst(elem);

		drop_bbf_authid_user_ext_by_rolname(user_name);
	}
}

static void
grant_guests_to_login(const char *login)
{
	Relation		db_rel;
	TableScanDesc	scan;
	HeapTuple		tuple;
	bool			is_null;
	StringInfoData	query;
	List			*parsetree_list;
	List			*guests = NIL;
	Node			*stmt;
	RoleSpec		*tmp;
	PlannedStmt		*wrapper;

	initStringInfo(&query);
	db_rel = table_open(sysdatabases_oid, AccessShareLock);
	scan = table_beginscan_catalog(db_rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		Datum db_name_datum = heap_getattr(tuple,
										   Anum_sysdatabaese_name,
										   db_rel->rd_att,
										   &is_null);

		const char *db_name = TextDatumGetCString(db_name_datum);
		const char *guest_name = NULL;
		AccessPriv *tmp = makeNode(AccessPriv);
		
		if (guest_role_exists_for_db(db_name))
			guest_name = get_guest_role_name(db_name);

		if (guest_name)
		{
			tmp->priv_name = pstrdup(guest_name);
			tmp->cols = NIL;
			guests = lappend(guests, tmp);
		}

		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	table_endscan(scan);
	table_close(db_rel, AccessShareLock);

	/* Build dummy GRANT statement to grant membership in login to all guests */
	if (list_length(guests) == 0)
		return;

	appendStringInfo(&query, "GRANT dummy TO dummy; ");

	parsetree_list = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if (list_length(parsetree_list) != 1)
		ereport(ERROR, 
				(errcode(ERRCODE_SYNTAX_ERROR), 
				 errmsg("Expected 1 statement but get %d statements after parsing",
						list_length(parsetree_list))));

	/* Update the dummy statement with real values */
	stmt = parsetree_nth_stmt(parsetree_list, 0);
	tmp = makeNode(RoleSpec);
	tmp->roletype = ROLESPEC_CSTRING;
	tmp->location = -1;
	tmp->rolename = pstrdup(login);

	update_GrantRoleStmt(stmt, guests, list_make1(tmp));

	/* Run the built query */
	/* need to make a wrapper PlannedStmt */
	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = stmt;
	wrapper->stmt_location = 0;
	wrapper->stmt_len = 18;

	/* do this step */
	ProcessUtility(wrapper,
				   "(CREATE DATABASE )",
				   false,
				   PROCESS_UTILITY_SUBCOMMAND,
				   NULL,
				   NULL,
				   None_Receiver,
				   NULL);

	/* make sure later steps can see the object created here */
	CommandCounterIncrement();

	pfree(query.data);
}

static List *
gen_droplogin_subcmds(const char *login)
{
	StringInfoData query;
	List *res;
	Node *stmt;

	initStringInfo(&query);

	appendStringInfo(&query, "DROP LOGIN dummy; ");
	res = raw_parser(query.data, RAW_PARSE_DEFAULT);

	if (list_length(res) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing",
						list_length(res))));

	stmt = parsetree_nth_stmt(res, 0);
	update_DropRoleStmt(stmt, login);

	return res;
}

/*
 * Check if the given role is SA of the current database.
 * We assume that SA is the DBA of the babelfish DB.
 */
bool
role_is_sa(Oid role)
{
	HeapTuple tuple;
	Oid			dba;

	tuple = SearchSysCache1(DATABASEOID, ObjectIdGetDatum(MyDatabaseId));
	if (!HeapTupleIsValid(tuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database with OID %u does not exist", MyDatabaseId)));
	dba = ((Form_pg_database) GETSTRUCT(tuple))->datdba;
	ReleaseSysCache(tuple);
	return role == dba;
}

bool
tsql_has_pgstat_permissions(Oid role)
{
	return role_is_sa(GetSessionUserId()) || has_privs_of_role(GetSessionUserId(), role);
}

PG_FUNCTION_INFO_V1(initialize_logins);
Datum
initialize_logins(PG_FUNCTION_ARGS)
{
	char			*login = text_to_cstring(PG_GETARG_TEXT_PP(0));
	CreateRoleStmt	*stmt = makeNode(CreateRoleStmt);

	stmt->stmt_type = ROLESTMT_USER;
	stmt->role = login;

	create_bbf_authid_login_ext(stmt);
	PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(user_name);
Datum
user_name(PG_FUNCTION_ARGS)
{
	Oid				id;
	Relation		bbf_authid_user_ext_rel;
	HeapTuple		tuple;
	ScanKeyData		scanKey;
	SysScanDesc		scan;
	char			*physical_user;
	NameData		*physical_user_name;
	char			*user;
	Datum			datum;
	bool			is_null;

	id = PG_ARGISNULL(0) ? InvalidOid : PG_GETARG_OID(0);

	if (id == InvalidOid)
		id = GetUserId();

	physical_user = GetUserNameFromId(id, true);
	if (!physical_user)
		PG_RETURN_NULL();

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	/* Search and obtain the tuple on the role name*/
	physical_user_name = (NameData *) palloc0(NAMEDATALEN);
	snprintf(physical_user_name->data, NAMEDATALEN, "%s", physical_user);
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(physical_user_name));

	scan = systable_beginscan(bbf_authid_user_ext_rel,
							  get_authid_user_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);
	if (!HeapTupleIsValid(tuple))
	{	
		systable_endscan(scan);
		table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
		PG_RETURN_NULL();
	}

	datum = heap_getattr(tuple,
						 Anum_bbf_authid_user_ext_orig_username,
						 bbf_authid_user_ext_rel->rd_att,
						 &is_null);
	user = pstrdup(TextDatumGetCString(datum));

	systable_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	PG_RETURN_TEXT_P(CStringGetTextDatum(user));
}

PG_FUNCTION_INFO_V1(user_id);
Datum
user_id(PG_FUNCTION_ARGS)
{
	char			*user_input;
	char			*user_name;
	char			*db_name;
	HeapTuple		auth_tuple;
	Form_pg_authid	authform;
	Oid				ret;

	user_input = PG_ARGISNULL(0) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(0));
	db_name = get_cur_db_name();

	if (!db_name)
		PG_RETURN_NULL();

	if (!user_input)
		PG_RETURN_OID(GetUserId());

	user_name = get_physical_user_name(db_name, user_input);

	if (!user_name)
		PG_RETURN_NULL();

	if (pltsql_case_insensitive_identifiers)
		// Lowercase the entry, if needed
		for (char *p = user_name ; *p; ++p) *p = tolower(*p);

	auth_tuple = SearchSysCache1(AUTHNAME, CStringGetDatum(user_name));
	if (!HeapTupleIsValid(auth_tuple))
		PG_RETURN_NULL();

	authform = (Form_pg_authid) GETSTRUCT(auth_tuple);
	ret = authform->oid;

	ReleaseSysCache(auth_tuple);

	PG_RETURN_OID(ret);
}

PG_FUNCTION_INFO_V1(suser_name);
Datum
suser_name(PG_FUNCTION_ARGS)
{
	Oid				server_user_id;
	char			*ret;

	server_user_id = PG_ARGISNULL(0) ? InvalidOid : PG_GETARG_OID(0);

	if (server_user_id == InvalidOid)
		server_user_id = GetSessionUserId();

	ret = GetUserNameFromId(server_user_id, true);

	if (!ret || !is_login(server_user_id))
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(CStringGetTextDatum(ret));
}

PG_FUNCTION_INFO_V1(suser_id);
Datum
suser_id(PG_FUNCTION_ARGS)
{
	char			*login;
	HeapTuple		auth_tuple;
	Form_pg_authid	authform;
	Oid				ret;

	login = PG_ARGISNULL(0) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(0));

	if (!login)
		ret = GetSessionUserId();
	else
	{
		/* Strip trailing whitespace to mimic SQL Server behaviour */
		int i;
		i = strlen(login);
		while (i > 0 && isspace((unsigned char) login[i - 1]))
			login[--i] = '\0';
	
		/* Convert login to lower-case */
		for (i = 0; login[i]; i++)
		{
			login[i] = tolower(login[i]);
		}
			
		/* Check if it is a role and get the oid */
		auth_tuple = SearchSysCache1(AUTHNAME, CStringGetDatum(login));
		if (!HeapTupleIsValid(auth_tuple))
			PG_RETURN_NULL();

		authform = (Form_pg_authid) GETSTRUCT(auth_tuple);
		ret = authform->oid;

		ReleaseSysCache(auth_tuple);
	}

	if (!is_login(ret))
		PG_RETURN_NULL();

	PG_RETURN_OID(ret);
}

PG_FUNCTION_INFO_V1(drop_all_logins);
Datum drop_all_logins(PG_FUNCTION_ARGS)
{
	Relation	bbf_authid_login_ext_rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	char*		rolname;
	List		*rolname_list = NIL;
	const char  *prev_current_user;
	List        *parsetree_list;
	ListCell    *parsetree_item;
	int         saved_dialect = sql_dialect;
	
	/* Only allow superuser or SA to drop all logins. */
	if (!superuser() && !role_is_sa(GetUserId()))
          ereport(ERROR,
                  (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
                   errmsg("user %s not allowed to drop all logins in babelfish database %s", 
					   GetUserNameFromId(GetUserId(), true), get_database_name(MyDatabaseId))));

	/* Fetch the relation */
	bbf_authid_login_ext_rel = table_open(get_authid_login_ext_oid(),
										  RowExclusiveLock);
	scan = systable_beginscan(bbf_authid_login_ext_rel, 0, false, NULL, 0, NULL);

	/* Get all the login names beforehand. */
	while (HeapTupleIsValid(tuple = systable_getnext(scan))) {
		Form_authid_login_ext  loginform = (Form_authid_login_ext) GETSTRUCT(tuple);
		rolname = NameStr(loginform->rolname);
		/* 
		 * Remove SA from authid_login_ext now but do not add it to the list
		 * because we don't want to remove the corresponding PG role.
		 */
		if (role_is_sa(get_role_oid(rolname, false)) || (strcmp(rolname, "sysadmin") == 0))
			CatalogTupleDelete(bbf_authid_login_ext_rel, &tuple->t_self);
		else
			rolname_list = lcons(rolname, rolname_list);
	}

	systable_endscan(scan);
	table_close(bbf_authid_login_ext_rel, RowExclusiveLock);

	/* Set current user to session user for dropping permissions */
	prev_current_user = GetUserNameFromId(GetUserId(), false);
	bbf_set_current_user("sysadmin");

	sql_dialect = SQL_DIALECT_TSQL;

	while (rolname_list != NIL) {
		char *rolname = linitial(rolname_list);
		rolname_list = list_delete_first(rolname_list);

		PG_TRY();
		{
			/* Advance cmd counter to make the delete visible */
			CommandCounterIncrement();

			parsetree_list = gen_droplogin_subcmds(rolname);

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
							   "(DROP LOGIN )",
							   false,
							   PROCESS_UTILITY_SUBCOMMAND,
							   NULL,
							   NULL,
							   None_Receiver,
							   NULL);

				/* make sure later steps can see the object created here */
				CommandCounterIncrement();
			}
		}
		PG_CATCH();
		{
			/* Clean up. Restore previous state. */
			bbf_set_current_user(prev_current_user);
			sql_dialect = saved_dialect;
			PG_RE_THROW();
		}
		PG_END_TRY();
	}
	/* Set current user back to previous user */
	bbf_set_current_user(prev_current_user);
	sql_dialect = saved_dialect;
	PG_RETURN_INT32(0);
}

void
add_to_bbf_authid_user_ext(const char *user_name,
						   const char *orig_user_name,
						   const char *db_name,
						   const char *schema_name,
						   const char *login_name,
						   bool	is_role,
						   bool has_dbaccess)
{
	Relation		bbf_authid_user_ext_rel;
	TupleDesc		bbf_authid_user_ext_dsc;
	HeapTuple		tuple_user_ext;
	Datum			new_record_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool			new_record_nulls_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];

	if (!user_name || !orig_user_name)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("User catalog requires user names.")));

	/* Fetch the relation */
	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);
	bbf_authid_user_ext_dsc = RelationGetDescr(bbf_authid_user_ext_rel);

	/* Build a tuple to insert */
	MemSet(new_record_user_ext, 0, sizeof(new_record_user_ext));
	MemSet(new_record_nulls_user_ext, false, sizeof(new_record_nulls_user_ext));

	new_record_user_ext[USER_EXT_ROLNAME] = CStringGetDatum(pstrdup(user_name));
	if (login_name)
		new_record_user_ext[USER_EXT_LOGIN_NAME] = CStringGetDatum(pstrdup(login_name));
	else
		new_record_user_ext[USER_EXT_LOGIN_NAME] = CStringGetDatum("");
	if (is_role)
		new_record_user_ext[USER_EXT_TYPE] = CStringGetTextDatum("R"); 
	else
		new_record_user_ext[USER_EXT_TYPE] = CStringGetTextDatum("S");
	new_record_user_ext[USER_EXT_OWNING_PRINCIPAL_ID] = Int32GetDatum(-1); /* placeholder */
	new_record_user_ext[USER_EXT_IS_FIXED_ROLE] = Int32GetDatum(-1); /* placeholder */
	new_record_user_ext[USER_EXT_AUTHENTICATION_TYPE] = Int32GetDatum(-1); /* placeholder */
	new_record_user_ext[USER_EXT_DEFAULT_LANGUAGE_LCID] = Int32GetDatum(-1); /* placeholder */
	new_record_user_ext[USER_EXT_ALLOW_ENCRYPTED_VALUE_MODIFICATIONS] = Int32GetDatum(-1); /* placeholder */
	new_record_user_ext[USER_EXT_CREATE_DATE] = TimestampTzGetDatum(GetSQLCurrentTimestamp(-1));
	new_record_user_ext[USER_EXT_MODIFY_DATE] = TimestampTzGetDatum(GetSQLCurrentTimestamp(-1));
	new_record_user_ext[USER_EXT_ORIG_USERNAME] = CStringGetTextDatum(pstrdup(orig_user_name));
	if (db_name)
		new_record_user_ext[USER_EXT_DATABASE_NAME] = CStringGetTextDatum(pstrdup(db_name));
	else
		new_record_user_ext[USER_EXT_DATABASE_NAME] = CStringGetTextDatum(get_cur_db_name());
	if (schema_name)
		new_record_user_ext[USER_EXT_DEFAULT_SCHEMA_NAME] = CStringGetTextDatum(pstrdup(schema_name));
	else
		new_record_user_ext[USER_EXT_DEFAULT_SCHEMA_NAME] = CStringGetTextDatum("");
	new_record_user_ext[USER_EXT_DEFAULT_LANGUAGE_NAME] = CStringGetTextDatum("English");
	new_record_user_ext[USER_EXT_AUTHENTICATION_TYPE_DESC] = CStringGetTextDatum(""); /* placeholder */
	if (has_dbaccess)
		new_record_user_ext[USER_EXT_USER_CAN_CONNECT] = Int32GetDatum(1);
	else
		new_record_user_ext[USER_EXT_USER_CAN_CONNECT] = Int32GetDatum(0);

	tuple_user_ext = heap_form_tuple(bbf_authid_user_ext_dsc,
									 new_record_user_ext,
									 new_record_nulls_user_ext);

	/* Insert new record in the bbf_authid_user_ext table */
	CatalogTupleInsert(bbf_authid_user_ext_rel, tuple_user_ext);

	/* Close bbf_authid_user_ext, but keep lock till commit */
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	/* Advance cmd counter to make the insert visible */
	CommandCounterIncrement();
}

void
create_bbf_authid_user_ext(CreateRoleStmt *stmt, bool has_schema, bool has_login)
{
	ListCell		*option;
	char			*default_schema = NULL;
	char			*original_user_name = NULL;
	RoleSpec		*login = NULL;
	NameData		*login_name;
	char			*login_name_str = NULL;

	/* Extract options from the statement node tree */
	foreach(option, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(option);

		if (has_login && strcmp(defel->defname, "default_schema") == 0)
		{
			if (defel->arg)
				default_schema = strVal(defel->arg);
		}
		else if (strcmp(defel->defname, "original_user_name") == 0)
		{
			if (defel->arg)
				original_user_name = strVal(defel->arg);
		}
		/* Extract login info if the stmt is CREATE USER */
		else if (has_login && strcmp(defel->defname, "rolemembers") == 0)
		{
			List		*rolemembers = NIL;

			rolemembers = (List *) defel->arg;
			login = (RoleSpec *) linitial(rolemembers);
		}
	}

	if (has_schema && !default_schema)
		default_schema = "dbo";

	if (has_login)
	{
		Relation		bbf_authid_user_ext_rel;
		HeapTuple		tuple_user_ext;
		ScanKeyData		key[2];
		TableScanDesc	scan;
		const char *cur_db_owner;

		if (login == NULL || !is_login_name(login->rolename))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("The login '%s' does not exist.", login->rolename)));

		/* Fetch the relation */
		bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
											 RowExclusiveLock);

		/* Check for login to user uniqueness in the database */
		login_name = (NameData *) palloc0(NAMEDATALEN);
		snprintf(login_name->data, NAMEDATALEN, "%s", login->rolename);
		ScanKeyInit(&key[0],
					Anum_bbf_authid_user_ext_login_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					NameGetDatum(login_name));
		ScanKeyInit(&key[1],
					Anum_bbf_authid_user_ext_database_name,
					BTEqualStrategyNumber, F_TEXTEQ,
					CStringGetTextDatum(get_cur_db_name()));

		scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 2, key);

		tuple_user_ext = heap_getnext(scan, ForwardScanDirection);
		if (tuple_user_ext != NULL)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_ROLE_SPECIFICATION),
					 errmsg("Existing user already maps to login '%s' in current database.", login->rolename)));

		table_endscan(scan);
		table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

		login_name_str = login->rolename;
		cur_db_owner = get_owner_of_db((const char *)get_cur_db_name());

		if (strcmp(login_name_str, cur_db_owner) == 0)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_ROLE_SPECIFICATION),
					 errmsg("The login already has an account under a different user name.")));

	}

	/* Add to the catalog table. Adds current database name by default */
	add_to_bbf_authid_user_ext(stmt->role, original_user_name, NULL, default_schema, login_name_str, !has_login, true);
}

PG_FUNCTION_INFO_V1(add_existing_users_to_catalog);
Datum
add_existing_users_to_catalog(PG_FUNCTION_ARGS)
{
	Relation        db_rel;
	TableScanDesc   scan;
	HeapTuple       tuple;
	bool            is_null;
	List            *dbo_list = NIL;
	StringInfoData  query;
	List            *parsetree_list;
	Node            *stmt;
	PlannedStmt     *wrapper;
	const char      *prev_current_user;
	int             saved_dialect = sql_dialect;

	db_rel = table_open(sysdatabases_oid, AccessShareLock);
	scan = table_beginscan_catalog(db_rel, 0, NULL);
	tuple = heap_getnext(scan, ForwardScanDirection);

	while (HeapTupleIsValid(tuple))
	{
		Datum           db_name_datum;
		const char      *db_name;
		const char      *dbo_role;
		const char      *db_owner_role;
		const char      *guest;
		RoleSpec        *rolspec;

		db_name_datum = heap_getattr(tuple,
		Anum_sysdatabaese_name,
		db_rel->rd_att,
		&is_null);

		db_name = TextDatumGetCString(db_name_datum);
		dbo_role = get_dbo_role_name(db_name);
		db_owner_role = get_db_owner_name(db_name);
		guest = get_guest_role_name(db_name);

		/* Add users to catalog ext */
		if (dbo_role)
		{
			rolspec = makeNode(RoleSpec);
			rolspec->type = ROLESPEC_CSTRING;
			rolspec->location = -1;
			rolspec->rolename = pstrdup(dbo_role);
			dbo_list = lappend(dbo_list, rolspec);
			add_to_bbf_authid_user_ext(dbo_role, "dbo", db_name, "dbo", NULL, false, true);
		}
		if (db_owner_role)
			add_to_bbf_authid_user_ext(db_owner_role, "db_owner", db_name, NULL, NULL, true, true);
		if (guest)
		{
			/* For master, tempdb and msdb databases, the guest user will be enabled by default */
			if (strcmp(db_name, "master") == 0 || strcmp(db_name, "tempdb") == 0 || strcmp(db_name, "msdb") == 0)
				add_to_bbf_authid_user_ext(guest, "guest", db_name, NULL, NULL, false, true);
			else
				add_to_bbf_authid_user_ext(guest, "guest", db_name, NULL, NULL, false, false);
		}

		tuple = heap_getnext(scan, ForwardScanDirection);
	}
	table_endscan(scan);
	table_close(db_rel, AccessShareLock);

	if (list_length(dbo_list) <= 0)
		PG_RETURN_INT32(0);

	/* Alter role to enable createrole to all dbo users */
	/* Set current user to sysadmin for alter permissions */
	prev_current_user = GetUserNameFromId(GetUserId(), false);
	bbf_set_current_user("sysadmin");

	sql_dialect = SQL_DIALECT_TSQL;

	while (dbo_list != NIL)
	{
		RoleSpec *rolspec = (RoleSpec *) linitial(dbo_list);
		dbo_list = list_delete_first(dbo_list);

		PG_TRY();
		{
			initStringInfo(&query);
			appendStringInfo(&query, "ALTER ROLE dummy WITH createrole; ");

			parsetree_list = raw_parser(query.data, RAW_PARSE_DEFAULT);

			if (list_length(parsetree_list) != 1)
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("Expected 1 statement after parsing, but got %d statements",
						 list_length(parsetree_list))));

			stmt = parsetree_nth_stmt(parsetree_list, 0);

			/* Update dummy statement with real values */
			update_AlterRoleStmt(stmt, rolspec);

			/* Make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 34;

			/* Run the built query */
			ProcessUtility(wrapper,
						   "(CREATE DATABASE )",
						   false,
						   PROCESS_UTILITY_SUBCOMMAND,
						   NULL,
						   NULL,
						   None_Receiver,
						   NULL);

			/* Make sure later steps can see the object created here */
			CommandCounterIncrement();

			pfree(query.data);
		}
		PG_CATCH();
		{
			/* Clean up. Restore previous state. */
			bbf_set_current_user(prev_current_user);
			sql_dialect = saved_dialect;
			PG_RE_THROW();
		}
		PG_END_TRY();
	}

	bbf_set_current_user(prev_current_user);
	sql_dialect = saved_dialect;
	PG_RETURN_INT32(0);
}

void
alter_bbf_authid_user_ext(AlterRoleStmt *stmt)
{
	Relation		bbf_authid_user_ext_rel;
	TupleDesc		bbf_authid_user_ext_dsc;
	HeapTuple		new_tuple;
	HeapTuple		tuple;
	Datum			new_record_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool			new_record_nulls_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	bool			new_record_repl_user_ext[BBF_AUTHID_USER_EXT_NUM_COLS];
	ScanKeyData		scanKey;
	SysScanDesc		scan;
	ListCell		*option;
	NameData		*user_name;
	char			*default_schema = NULL;
	char			*new_user_name = NULL;
	char			*physical_name = NULL;

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/* Extract options from the statement node tree */
	foreach(option, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(option);

		if (strcmp(defel->defname, "default_schema") == 0)
		{
			if (defel->arg)
				default_schema = strVal(defel->arg);
		}
		if (strcmp(defel->defname, "rename") == 0)
		{
			if (defel->arg)
				new_user_name = strVal(defel->arg);
		}
	}

	/* Fetch the relation */
	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);
	bbf_authid_user_ext_dsc = RelationGetDescr(bbf_authid_user_ext_rel);

	/* Search and obtain the tuple on the role name*/
	user_name = (NameData *) palloc0(NAMEDATALEN);
	snprintf(user_name->data, NAMEDATALEN, "%s", stmt->role->rolename);
	ScanKeyInit(&scanKey,
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(user_name));

	scan = systable_beginscan(bbf_authid_user_ext_rel,
							  get_authid_user_ext_idx_oid(),
							  true, NULL, 1, &scanKey);

	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("tuple does not exist")));

	/* Build a tuple to insert */
	MemSet(new_record_user_ext, 0, sizeof(new_record_user_ext));
	MemSet(new_record_nulls_user_ext, false, sizeof(new_record_nulls_user_ext));
	MemSet(new_record_repl_user_ext, false, sizeof(new_record_repl_user_ext));

	/* update user name */
	if (new_user_name)
	{
		physical_name = get_physical_user_name(get_cur_db_name(), new_user_name);
		new_record_user_ext[USER_EXT_ROLNAME] = CStringGetDatum(physical_name);
		new_record_repl_user_ext[USER_EXT_ROLNAME] = true;
		new_record_user_ext[USER_EXT_ORIG_USERNAME] = CStringGetTextDatum(new_user_name);
		new_record_repl_user_ext[USER_EXT_ORIG_USERNAME] = true;

	}

	/* update modify_date */
	new_record_user_ext[USER_EXT_MODIFY_DATE] = TimestampTzGetDatum(GetSQLCurrentTimestamp(-1));
	new_record_repl_user_ext[USER_EXT_MODIFY_DATE] = true;

	/* update default_schema */
	if (default_schema)
	{
		if (strcmp(default_schema, "") == 0)
		{
			pfree(default_schema);
			default_schema = "dbo";
		}
		new_record_user_ext[USER_EXT_DEFAULT_SCHEMA_NAME] = CStringGetTextDatum(pstrdup(default_schema));
		new_record_repl_user_ext[USER_EXT_DEFAULT_SCHEMA_NAME] = true;
	}

	new_tuple = heap_modify_tuple(tuple,
								  bbf_authid_user_ext_dsc,
								  new_record_user_ext,
								  new_record_nulls_user_ext,
								  new_record_repl_user_ext);

	CatalogTupleUpdate(bbf_authid_user_ext_rel, &tuple->t_self, new_tuple);

	/* Advance the command counter to see the new record */
	CommandCounterIncrement();

	systable_endscan(scan);
	heap_freetuple(new_tuple);

	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	if (new_user_name)
	{
		StringInfoData	query;
		List			*parsetree_list;
		Node			*n;
		PlannedStmt		*wrapper;

		initStringInfo(&query);
		appendStringInfo(&query, "ALTER ROLE dummy RENAME TO dummy; ");

		parsetree_list = raw_parser(query.data, RAW_PARSE_DEFAULT);

		if (list_length(parsetree_list) != 1)
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("Expected 1 statement but get %d statements after parsing",
							list_length(parsetree_list))));

		/* Update the dummy statement with real values */
		n = parsetree_nth_stmt(parsetree_list, 0);

		update_RenameStmt(n, stmt->role->rolename, physical_name);

		/* Run the built query */
		/* need to make a wrapper PlannedStmt */
		wrapper = makeNode(PlannedStmt);
		wrapper->commandType = CMD_UTILITY;
		wrapper->canSetTag = false;
		wrapper->utilityStmt = n;
		wrapper->stmt_location = -1;
		wrapper->stmt_len = -1;

		/* do this step */
		ProcessUtility(wrapper,
					   "(ALTER ROLE )",
					   false,
					   PROCESS_UTILITY_SUBCOMMAND,
					   NULL,
					   NULL,
					   None_Receiver,
					   NULL);

		pfree(query.data);
	}
}

PG_FUNCTION_INFO_V1(drop_all_users);
Datum drop_all_users(PG_FUNCTION_ARGS)
{
	/*
	 * This function has been deprecated since v2.1.
	 * However, we cannot remove this function entirely because,
	 * in PG13, sys.babel_drop_all_users() procedure refers it.
	 * Without this function, MVU from PG13 to PG14 will fail.
	 *
	 * Removing the procedure sys.babel_drop_all_users() during pg_dump
	 * cannot be an option because other user-defined procedures
	 * are able to refer this function as well.
	 */
	ereport(WARNING,
			(errcode(ERRCODE_WARNING_DEPRECATED_FEATURE),
			 errmsg("This function has been deprecated and will no longer drop all users.")));
	PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(babelfish_set_role);
Datum
babelfish_set_role(PG_FUNCTION_ARGS)
{
	char *role = text_to_cstring(PG_GETARG_TEXT_PP(0));

	bbf_set_current_user(role);

	PG_RETURN_INT32(1);
}

bool
is_alter_server_stmt(GrantRoleStmt *stmt)
{
	/* is alter server role statement,
	 * if one and the only one granted role is server role
	 */

	if (list_length(stmt->granted_roles) == 1)
	{
		RoleSpec *spec = (RoleSpec *) linitial(stmt->granted_roles);		
		if (strcmp(spec->rolename, "sysadmin") != 0) /* only supported server role */
			return false;
	}
	/* has one and only one grantee  */
	if (list_length(stmt->grantee_roles) != 1)
		return false;

	return true;
}

void
check_alter_server_stmt(GrantRoleStmt *stmt)
{
	Oid grantee;
	const char 	*grantee_name;
	const char 	*granted_name;
	RoleSpec 	*spec;
	AccessPriv 	*granted;
	CatCList   	*memlist;
	Oid         sysadmin;
	char		*db_name;

	spec = (RoleSpec *) linitial(stmt->grantee_roles);		
	sysadmin = get_role_oid("sysadmin", false);

	granted = (AccessPriv *) linitial(stmt->granted_roles);
	granted_name = granted->priv_name;

	/* grantee MUST be a login */
	grantee_name = spec->rolename;
	grantee = get_role_oid(grantee_name, false);  /* missing not OK */

	if(!is_login(grantee))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("%s is not a login", grantee_name)));

	/* only sysadmin role is assumed below */
	if (!has_privs_of_role(GetSessionUserId(), sysadmin))
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Current login %s does not have permission to alter server role",
					 GetUserNameFromId(GetSessionUserId(), true))));

	/* sysadmin role is not granted if grantee login has a user in one of the databases, as Babelfish only supports one dbo currently*/
	if (stmt->is_grant && (strcmp(granted_name, "sysadmin") == 0) && has_user_in_db(grantee_name, &db_name))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("'sysadmin' role cannot be granted to login: a user is already created in database '%s'", db_name)));

	/* could not drop the last member of sysadmin */
	memlist = SearchSysCacheList1(AUTHMEMROLEMEM,
									ObjectIdGetDatum(sysadmin));

	if (memlist->n_members == 1)
	{
		HeapTuple   tup = &memlist->members[0]->tuple;
		Oid         member = ((Form_pg_auth_members) GETSTRUCT(tup))->member;

		if (member == grantee)
		{
			ReleaseSysCacheList(memlist);
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Could not drop last member of sysadmin")));
		}
	}
	ReleaseSysCacheList(memlist);
}

bool
is_alter_role_stmt(GrantRoleStmt *stmt)
{
	/*
	 * The statement is ALTER ROLE if 
	 * 1. There is only one grantee role
	 * 2. There is only one granted role and it's an existing babelfish db role
	 */
	if (list_length(stmt->granted_roles) != 1 || list_length(stmt->grantee_roles) != 1)
		return false;
	else
	{
		RoleSpec *spec = (RoleSpec *) linitial(stmt->granted_roles);        
		Oid granted = get_role_oid(spec->rolename, true);
		/* Check if the granted role is an existing database role */
		if (granted == InvalidOid || !is_role(granted))
			return false;
	}

	return true;
}

void
check_alter_role_stmt(GrantRoleStmt *stmt)
{
	Oid         granted;
	Oid         grantee;
	const char  *granted_name;
	const char  *grantee_name;
	RoleSpec    *granted_spec;
	RoleSpec    *grantee_spec;

	/* The grantee must be a db user or a user-defined db role */
	grantee_spec = (RoleSpec *) linitial(stmt->grantee_roles);      
	grantee_name = grantee_spec->rolename;
	grantee = get_role_oid(grantee_name, false);

	/* Disallow ALTER ROLE if the grantee is not a db principal */
	if (!is_user(grantee) && !is_role(grantee))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("%s is not a database user or a user-defined database role",
						grantee_name)));

	/* Need to have permission on the granted role */
	granted_spec = (RoleSpec *) linitial(stmt->granted_roles);
	granted_name = granted_spec->rolename;
	granted = get_role_oid(granted_name, false);

	/*
	 * Disallow ALTER ROLE if
	 * 1. Current login doesn't have permission on the granted role, or
	 * 2. The current user is trying to add/drop itself from the granted role
	 */
	if (!has_privs_of_role(GetSessionUserId(), granted) ||
		grantee == GetUserId())
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Current login %s does not have permission to alter role %s", 
						GetUserNameFromId(GetSessionUserId(), true), granted_name)));
}

/*
 * This function checks if the given role has any members.
 * Note that this will simply return true for InvalidOid.
 */
bool
is_empty_role(Oid roleid)
{
	CatCList 	*memlist;

	if (roleid == InvalidOid)
		return true;

	memlist = SearchSysCacheList1(AUTHMEMROLEMEM,
								  ObjectIdGetDatum(roleid));

	if (memlist->n_members == 1)
	{
		HeapTuple	tup = &memlist->members[0]->tuple;
		Oid			member = ((Form_pg_auth_members) GETSTRUCT(tup))->member;
		char		*db_name = get_cur_db_name();

		if (db_name == NULL || strcmp(db_name, "") == 0)
			return true;

		if (member == get_role_oid(get_db_owner_name(db_name), true))
		{
			ReleaseSysCacheList(memlist);
			return true;
		}
	}

	ReleaseSysCacheList(memlist);

	return false;
}

PG_FUNCTION_INFO_V1(role_id);
Datum
role_id(PG_FUNCTION_ARGS)
{
	char	*user_input;
	char	*role_name;
	Oid		result;

	user_input = text_to_cstring(PG_GETARG_TEXT_PP(0));

	if (0 != strncmp(user_input, "db_owner", 8))
		PG_RETURN_NULL();  /* don't have other roles */

	if (!get_cur_db_name())
		PG_RETURN_NULL();

	role_name = get_physical_user_name(get_cur_db_name(), user_input);

	result = get_role_oid(role_name, true);

	if (result == InvalidOid)
		PG_RETURN_NULL();
	else
		PG_RETURN_INT32(result);
}

/*
 * Internal function for IS_MEMBER and IS_ROLEMEMBER
 */
PG_FUNCTION_INFO_V1(is_rolemember);
Datum
is_rolemember(PG_FUNCTION_ARGS)
{
	Oid		role_oid;
	Oid		principal_oid;
	Oid		cur_user_oid = GetUserId();
	Oid		db_owner_oid;
	Oid		dbo_role_oid;
	char	*role;
	char 	*dc_role;
	char 	*dc_principal = NULL;
	char	*physical_role_name;
	char	*physical_principal_name;
	char	*cur_db_name;
	const char	*db_owner_name;
	const char	*dbo_role_name;
	int idx;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	/* Do role name mapping */
	role = text_to_cstring(PG_GETARG_TEXT_P(0));
	idx = strlen(role);
	while (idx > 0 && isspace((unsigned char) role[idx - 1]))
		role[--idx] = '\0';
	dc_role = downcase_identifier(role, strlen(role), false, false);
	physical_role_name = get_physical_user_name(get_cur_db_name(), dc_role);
	role_oid = get_role_oid(physical_role_name, true);

	/* If principal name is NULL, take current user instead */
	if (PG_ARGISNULL(1))
		principal_oid = cur_user_oid;
	else
	{
		/* Do principal name mapping */
		char *principal = text_to_cstring(PG_GETARG_TEXT_P(1));
		idx = strlen(principal);
		while (idx > 0 && isspace((unsigned char) principal[idx - 1]))
			principal[--idx] = '\0';
		dc_principal = downcase_identifier(principal, strlen(principal), false, false);
		physical_principal_name = get_physical_user_name(get_cur_db_name(), dc_principal);
		principal_oid = get_role_oid(physical_principal_name, true);
	}

	/* Return 1 if given role is PUBLIC */
	if (strcmp(dc_role, "public") == 0 && 
		(principal_oid != InvalidOid || strcmp(dc_principal, "public") == 0))
		PG_RETURN_INT32(1);

	/* Return NULL if given role or principal doesn't exist */
	if (role_oid == InvalidOid || principal_oid == InvalidOid)
		PG_RETURN_NULL();

	/* Return 1 if given role and principal are the same */
	if (role_oid == principal_oid)
		PG_RETURN_INT32(1);

	/* 
	 * Return NULL if given role is not a real role, or if current user doesn't 
	 * directly/indirectly have privilges over the given role and principal.
	 * Note that if given principal is current user, we'll always have
	 * permissions.
	 */
	if (!is_role(role_oid) ||
		(principal_oid != cur_user_oid &&
		 (!has_privs_of_role(cur_user_oid, role_oid) ||
		  !has_privs_of_role(cur_user_oid, principal_oid))))
		PG_RETURN_NULL();

	/* 
	 * Recursively check if the given principal is a member of the role, not
	 * considering superuserness
	 */
	cur_db_name = get_cur_db_name();
	db_owner_name = get_db_owner_name(cur_db_name);
	dbo_role_name = get_dbo_role_name(cur_db_name);
	db_owner_oid = get_role_oid(db_owner_name, false);
	dbo_role_oid = get_role_oid(dbo_role_name, false);
	if ((principal_oid == db_owner_oid) || (principal_oid == dbo_role_oid))
		PG_RETURN_INT32(0);
	else 
		if (is_member_of_role_nosuper(principal_oid, role_oid))
			PG_RETURN_INT32(1);
		else
			PG_RETURN_INT32(0);
}

/*
 * To check if there are any active backends with given login
 */
bool
is_active_login(Oid role_oid)
{
	if (CountUserBackends(role_oid) == 0)
		return false; /* If there are no backends with given role */

	return true;
}

/*
 * To check if given login is already a user in one of the databases
 */
static bool
has_user_in_db(const char *login, char **db_name)
{
	Relation		bbf_authid_user_ext_rel;
	HeapTuple		tuple_user_ext;
	ScanKeyData		key[3];
	TableScanDesc	scan;
	NameData		*login_name;
	bool			is_null;

	// open the table to scane
	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	// change the target name to NameData for search
	login_name = (NameData *) palloc0(NAMEDATALEN);
	snprintf(login_name->data, NAMEDATALEN, "%s", login);

	// operate scanning
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_login_name,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(login_name));
	scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 1, key);

	// match stored, if there is a match
	tuple_user_ext = heap_getnext(scan, ForwardScanDirection);
	if (HeapTupleIsValid(tuple_user_ext))
	{

		Datum name = heap_getattr(tuple_user_ext, Anum_bbf_authid_user_ext_database_name,
								  bbf_authid_user_ext_rel->rd_att, &is_null);

		*db_name = pstrdup(TextDatumGetCString(name));
		
		table_endscan(scan);
		table_close(bbf_authid_user_ext_rel, RowExclusiveLock);
		return true;
	}
	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	return false;
}
