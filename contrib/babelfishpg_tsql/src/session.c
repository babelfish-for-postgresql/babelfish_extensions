#include "postgres.h"
#include "fmgr.h"
#include "miscadmin.h"

#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/guc.h"

#include <ctype.h>
#include "catalog.h"
#include "dbcmds.h"
#include "multidb.h"
#include "session.h"
#include "pltsql.h"

/* Core Session Properties */

static int16 current_db_id = 0;
static char current_db_name[MAX_BBF_NAMEDATALEND+1] = {'\0'};
static Oid current_user_id = InvalidOid;
static void set_search_path_for_user_schema(const char* db_name, const char* user);
void reset_cached_batch(void);

int16
get_cur_db_id(void)
{
	return current_db_id;
}

char *
get_cur_db_name(void)
{
	return pstrdup(current_db_name);
}

void
set_cur_db(int16 id, const char *name)
{
	int len = strlen(name);

	Assert(len <= MAX_BBF_NAMEDATALEND);

	current_db_id = id;
	strncpy(current_db_name, name, MAX_BBF_NAMEDATALEND);
	current_db_name[len] = '\0';

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_db_stat_var)
			(*pltsql_protocol_plugin_ptr)->set_db_stat_var(id);
}

void
bbf_set_current_user(const char *user_name)
{
	Oid userid;

	userid = get_role_oid(user_name, false);
	SetConfigOption("role", user_name, PGC_SUSET, PGC_S_DATABASE_USER);
	SetCurrentRoleId(userid, false);
}

void
set_session_properties(const char *db_name)
{
	int16 db_id = get_db_id(db_name);

	if (!DbidIsValid(db_id))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					 errmsg("database \"%s\" does not exist", db_name)));

	check_session_db_access(db_name);

	set_cur_user_db_and_path(db_name);
}

/* 
 * Raises an error if the current session does not have access to the given database
 * Caller responsible for checking db_name is valid 
 */
void
check_session_db_access(const char* db_name)
{
	const char		*user = NULL;
	const char		*login;

	user = get_user_for_database(db_name);

	if (!user)
	{
		login = GetUserNameFromId(GetSessionUserId(), false);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("The server principal \"%s\" is not able to access "
						"the database \"%s\" under the current security context",
						login, db_name)));
	}
}

/* Caller responsible for checking db_name is valid */
void
set_cur_user_db_and_path(const char* db_name)
{
	const char		*user = get_user_for_database(db_name);
	int16			db_id = get_db_id(db_name);

	/* set current DB */
	set_cur_db(db_id, db_name);

	/* set current user */
	bbf_set_current_user(user);
	current_user_id = GetUserId();

	/* set search path */
	set_search_path_for_user_schema(db_name, user);
}

static void
set_search_path_for_user_schema(const char* db_name, const char* user)
{
	const char		*path;
	const char		*buffer = "%s, \"$user\", sys, pg_catalog";
	const char		*physical_schema;
	const char		*dbo_role_name = get_dbo_role_name(db_name);
	const char		*guest_role_name = get_guest_role_name(db_name);

	if ((dbo_role_name && strcmp(user, dbo_role_name) == 0) ||
		(guest_role_name && strcmp(user, guest_role_name) == 0))
	{
		physical_schema = get_dbo_schema_name(db_name);
	}
	else
	{
		const char		*schema;
		schema = get_authid_user_ext_schema_name(db_name, user);
		physical_schema = get_physical_schema_name(pstrdup(db_name), schema);
	}

	path = psprintf(buffer, physical_schema);
	SetConfigOption("search_path",
					path,
					PGC_SUSET,
					PGC_S_DATABASE_USER);
}

/*
 * Wrapper function to reset the session properties and cached batch
 * incase of a reset connection.
 */
void
reset_session_properties(void)
{
	reset_cached_batch();
	set_session_properties(get_cur_db_name());
}

void
restore_session_properties()
{
	if (DbidIsValid(get_cur_db_id()) && OidIsValid(current_user_id))
	{
		char *cur_user;

		cur_user = GetUserNameFromId(current_user_id, true);

		if (cur_user)
			bbf_set_current_user(cur_user);
		else
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("current user \"%s\" does not exist", cur_user)));
	}
}

PG_FUNCTION_INFO_V1(babelfish_db_id);
Datum babelfish_db_id(PG_FUNCTION_ARGS)
{
	char *str;
	int16 dbid;

	if (PG_NARGS() > 0)
	{
		str = TextDatumGetCString(PG_GETARG_DATUM(0));
		if (pltsql_case_insensitive_identifiers)
			// Lowercase the entry, if needed
			for (char *p = str ; *p; ++p) *p = tolower(*p);
	
		dbid = get_db_id(str);
	}
	else
		dbid = current_db_id;

	if (!DbidIsValid(dbid))
	{
		PG_RETURN_NULL();
	}

	PG_RETURN_INT16(dbid);
}

PG_FUNCTION_INFO_V1(babelfish_db_name);
Datum babelfish_db_name(PG_FUNCTION_ARGS)
{
	int16 dbid;
	char * dbname;

	if (PG_NARGS() > 0)
		dbid = PG_GETARG_INT32(0);
	else
		dbid = current_db_id;

	if (dbid == 1)
	{
		dbname = palloc((strlen("master") + 1) * sizeof(char));
		strncpy(dbname, "master", MAX_BBF_NAMEDATALEND);
	}
	else if (dbid == 2)
	{
		dbname = palloc((strlen("tempdb") + 1) * sizeof(char));
		strncpy(dbname, "tempdb", MAX_BBF_NAMEDATALEND);
	}
	else if (dbid == 4)
	{
		dbname = palloc((strlen("msdb") + 1) * sizeof(char));
		strncpy(dbname, "msdb", MAX_BBF_NAMEDATALEND);
	}
	else
		dbname = get_db_name(dbid);

	if (dbname == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(CStringGetTextDatum(dbname));
}
