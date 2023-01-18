#include "postgres.h"
#include "fmgr.h"
#include "miscadmin.h"

#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/guc.h"

#include "catalog.h"
#include "dbcmds.h"
#include "multidb.h"
#include "session.h"
#include "pltsql.h"

/* Core Session Properties */

static int16 current_db_id = 0;
static char current_db_name[MAX_BBF_NAMEDATALEND+1] = {'\0'};
static Oid current_user_id = InvalidOid;
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
	const char		*buffer = "%s, \"$user\", sys, pg_catalog";
	const char		*path;
	const char		*user = NULL;
	const char		*login;
	const char		*physical_schema;
	int16			db_id = get_db_id(db_name);

	if (!DbidIsValid(db_id))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					 errmsg("database \"%s\" does not exist", db_name)));

	login = GetUserNameFromId(GetSessionUserId(), false);
	user = get_authid_user_ext_physical_name(db_name, login);

	/* set current DB */
	set_cur_db(db_id, db_name);

	if (!user)
	{
		Oid				datdba;

		datdba = get_role_oid("sysadmin", false);
		if (is_member_of_role(GetSessionUserId(), datdba))
			user = get_dbo_role_name(db_name);
		else
			user = get_guest_role_name(db_name);

		if (!user)
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					 errmsg("The server principal \"%s\" is not able to access "
							"the database \"%s\" under the current security context",
							login, db_name)));

		physical_schema = get_dbo_schema_name(db_name);
	}
	else
	{
		const char		*schema;

		schema = get_authid_user_ext_schema_name(db_name, user);
		physical_schema = get_physical_schema_name(pstrdup(db_name), schema);
	}

	/* set current user */
	bbf_set_current_user(user);
	current_user_id = GetUserId();

	/* set search path */
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
		dbname = palloc0((strlen("master") + 1) * sizeof(char));
		strncpy(dbname, "master", MAX_BBF_NAMEDATALEND);
	}
	else if (dbid == 2)
	{
		dbname = palloc0((strlen("tempdb") + 1) * sizeof(char));
		strncpy(dbname, "tempdb", MAX_BBF_NAMEDATALEND);
	}
	else
		dbname = get_db_name(dbid);

	if (dbname == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(CStringGetTextDatum(dbname));
}
