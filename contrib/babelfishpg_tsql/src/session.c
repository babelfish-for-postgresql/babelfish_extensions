#include "postgres.h"
#include "fmgr.h"
#include "miscadmin.h"
#include "varatt.h"

#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/formatting.h"
#include "utils/guc.h"
#include "utils/hsearch.h"
#include "catalog.h"

#include <ctype.h>
#include "catalog.h"
#include "dbcmds.h"
#include "multidb.h"
#include "session.h"
#include "pl_explain.h"
#include "pltsql.h"
#include "guc.h"
#include "storage/shm_toc.h"
#include "collation.h"

/* Core Session Properties */

#define MAX_SYSNAME_LEN 512		/* Large enough to handle 128 character
								 * unicode strings */

static int16 current_db_id = 0;
static char current_db_name[MAX_BBF_NAMEDATALEND + 1] = {'\0'};
static Oid	current_user_id = InvalidOid;
static void set_search_path_for_user_schema(const char *db_name, const char *user);
void		reset_cached_batch(void);

/* Session Context */
static HTAB *session_context_table = NULL;
static void initialize_context_table(void);
typedef struct SessionCxtEntry
{
	char		sessionKey[MAX_SYSNAME_LEN];	/* Hashtable Key, must be
												 * first */
	bool		read_only;
	bytea	   *value;
} SessionCxtEntry;

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
set_cur_db_name_for_parallel_worker(const char* logical_db_name)
{
	int len;

	if (logical_db_name == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"\" does not exist")));

	len = strlen(logical_db_name);

	Assert(len <= MAX_BBF_NAMEDATALEND);

	if(!DbidIsValid(get_db_id(logical_db_name)))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist", logical_db_name)));
	
	strncpy(current_db_name, logical_db_name, MAX_BBF_NAMEDATALEND);
	current_db_name[len] = '\0';
}


void
set_cur_db(int16 id, const char *name)
{
	int			len = strlen(name);

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
	Oid			userid;

	userid = get_role_oid(user_name, false);
	SetConfigOption("role", user_name, PGC_SUSET, PGC_S_DATABASE_USER);
	SetCurrentRoleId(userid, false);
}

void
set_session_properties(const char *db_name)
{
	int16		db_id = get_db_id(db_name);

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
check_session_db_access(const char *db_name)
{
	const char *user = NULL;
	const char *login;

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
set_cur_user_db_and_path(const char *db_name)
{
	const char *user = get_user_for_database(db_name);
	int16		db_id = get_db_id(db_name);

	/* set current DB */
	set_cur_db(db_id, db_name);

	/* set current user */
	bbf_set_current_user(user);
	current_user_id = GetUserId();

	/* set search path */
	set_search_path_for_user_schema(db_name, user);

	/* set database level collation */
	set_db_collation_internal(db_name);
}

static void
set_search_path_for_user_schema(const char *db_name, const char *user)
{
	const char	*path;
	const char	*buffer = "%s, \"$user\", sys, pg_catalog";
	char		*physical_schema;
	char		*dbo_role_name = get_dbo_role_name(db_name);
	char		*guest_role_name = get_guest_role_name(db_name);

	if ((dbo_role_name && strcmp(user, dbo_role_name) == 0))
	{
		physical_schema = get_dbo_schema_name(db_name);
	}
	else if (guest_role_name && strcmp(user, guest_role_name) == 0)
	{
		const char *guest_schema = get_authid_user_ext_schema_name(db_name, "guest");

		if (!guest_schema)
			guest_schema = "guest";
		physical_schema = get_physical_schema_name(pstrdup(db_name), guest_schema);
	}
	else
	{
		const char *schema;

		schema = get_authid_user_ext_schema_name(db_name, user);
		physical_schema = get_physical_schema_name(pstrdup(db_name), schema);
	}

	path = psprintf(buffer, quote_identifier(physical_schema));
	SetConfigOption("search_path",
					path,
					PGC_SUSET,
					PGC_S_DATABASE_USER);
	
	pfree(dbo_role_name);
	pfree(guest_role_name);
	pfree(physical_schema);
}

/*
 * Wrapper function to reset the session properties and cached batch
 * incase of a reset connection.
 */
void
reset_session_properties(void)
{
	reset_cached_batch();
	reset_cached_cursor();
	pltsql_explain_only = false;
	pltsql_explain_analyze = false;
}

void
restore_session_properties()
{
	if (DbidIsValid(get_cur_db_id()) && OidIsValid(current_user_id))
	{
		char	   *cur_user;

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
Datum
babelfish_db_id(PG_FUNCTION_ARGS)
{
	char	   *str;
	int16		dbid;

	if (PG_NARGS() > 0)
	{
		str = TextDatumGetCString(PG_GETARG_DATUM(0));
		if (pltsql_case_insensitive_identifiers)
			/* Lowercase the entry, if needed */
			for (char *p = str; *p; ++p)
				*p = tolower(*p);

		dbid = get_db_id(str);
	}
	else
	{
		if (!IS_TDS_CLIENT() && pltsql_psql_logical_babelfish_db_name)
			dbid = get_db_id(pltsql_psql_logical_babelfish_db_name);
		else 
			dbid = current_db_id;
	}
		

	if (!DbidIsValid(dbid))
	{
		PG_RETURN_NULL();
	}

	PG_RETURN_INT16(dbid);
}

PG_FUNCTION_INFO_V1(babelfish_db_name);
Datum
babelfish_db_name(PG_FUNCTION_ARGS)
{
	int16		dbid;
	char	   *dbname;

	if (PG_NARGS() > 0)
		dbid = PG_GETARG_INT32(0);
	else
		dbid = current_db_id;

	if (dbid == 1)
	{
		int dbnamelen = strlen("master");
		dbname = palloc0((dbnamelen + 1) * sizeof(char));
		strncpy(dbname, "master", dbnamelen);
	}
	else if (dbid == 2)
	{
		int dbnamelen = strlen("tempdb");
		dbname = palloc0((dbnamelen + 1) * sizeof(char));
		strncpy(dbname, "tempdb", dbnamelen);
	}
	else if (dbid == 4)
	{
		int dbnamelen = strlen("msdb");
		dbname = palloc0((dbnamelen + 1) * sizeof(char));
		strncpy(dbname, "msdb", dbnamelen);
	}
	else
		dbname = get_db_name(dbid);

	if (dbname == NULL)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(cstring_to_text(dbname));
}

/*
 * Stores key-value pairs in a hashtable
 * Table takes a string as a key, and saves a pointer to the sql_variant-typed value
 */
PG_FUNCTION_INFO_V1(sp_set_session_context);
Datum
sp_set_session_context(PG_FUNCTION_ARGS)
{
	VarChar    *key_arg;
	SessionCxtEntry *result_entry;
	char	   *key;
	int			encoded_key_bytelen;
	bool		found;
	MemoryContext oldContext;
	int			i;

	if (PG_ARGISNULL(0))
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						errmsg("The parameters supplied for the procedure \"sp_set_session_context\" are not valid.")));
	key_arg = PG_GETARG_VARCHAR_PP(0);
	key = str_tolower(VARDATA_ANY(key_arg), VARSIZE_ANY_EXHDR(key_arg), DEFAULT_COLLATION_OID);
	if (strlen(key) == 0)
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						errmsg("The parameters supplied for the procedure \"sp_set_session_context\" are not valid.")));

	encoded_key_bytelen = ((*common_utility_plugin_ptr->TsqlUTF8LengthInUTF16)(VARDATA_ANY(key_arg), VARSIZE_ANY_EXHDR(key_arg))) * 2;	/* Each UTF16 character is 2 bytes */

	if (encoded_key_bytelen > 256)
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("Cannot set key '%s' in the session context. The size of the key cannot exceed 256 bytes.", key)));

	/* Strip Whitespace */
	i = strlen(key);
	while (i > 0 && isspace((unsigned char) key[i - 1]))
		key[--i] = '\0';

	if (!session_context_table)
		initialize_context_table();

	result_entry = (SessionCxtEntry *) hash_search(session_context_table, key, HASH_ENTER, &found);

	if (found && result_entry->read_only == true)
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						errmsg("Cannot set key '%s' in the session context. The key has been set as read_only for this session.", key)));

	/* Free old entry if val argument is null */
	if (PG_ARGISNULL(1))
	{
		if (found)
			pfree(result_entry->value);
		hash_search(session_context_table, key, HASH_REMOVE, NULL);
		PG_RETURN_NULL();
	}
	pfree(key);

	oldContext = MemoryContextSwitchTo(TopMemoryContext);
	result_entry->read_only = PG_GETARG_BOOL(2);
	result_entry->value = PG_GETARG_BYTEA_P_COPY(1);
	MemoryContextSwitchTo(oldContext);

	PG_RETURN_NULL();
}

PG_FUNCTION_INFO_V1(session_context);
Datum
session_context(PG_FUNCTION_ARGS)
{
	char	   *key;
	SessionCxtEntry *result_entry;
	VarChar    *key_arg;
	int			i;

	if (!session_context_table)
		PG_RETURN_NULL();

	if (PG_ARGISNULL(0))
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						errmsg("The parameters supplied for the function \"session_context\" are not valid.")));

	key_arg = PG_GETARG_VARCHAR_PP(0);
	key = str_tolower(VARDATA_ANY(key_arg), VARSIZE_ANY_EXHDR(key_arg), DEFAULT_COLLATION_OID);

	/* Strip Whitespace */
	i = strlen(key);
	while (i > 0 && isspace((unsigned char) key[i - 1]))
		key[--i] = '\0';

	result_entry = (SessionCxtEntry *) hash_search(session_context_table, key, HASH_FIND, NULL);
	pfree(key);

	if (!result_entry)
		PG_RETURN_NULL();
	PG_RETURN_BYTEA_P(result_entry->value);
}

static void
initialize_context_table()
{
	HASHCTL		hash_options;

	memset(&hash_options, 0, sizeof(hash_options));
	hash_options.keysize = MAX_SYSNAME_LEN;
	hash_options.entrysize = sizeof(SessionCxtEntry);

	session_context_table = hash_create("Session Context", 128, &hash_options, HASH_ELEM | HASH_STRINGS);
}

/* 
* This function is responsible for estimating the size of the entry and the number of keys 
* and insert into the DSM for parallel workers
* The first argument is ParallelContext which contains the info related to TOC
* The second argument indicates whether we want to estimate the space or
* we want to insert the data into DSM
*/
void
babelfixedparallelstate_insert(ParallelContext *pcxt, bool estimate)
{
	BabelfishFixedParallelState *bfps;
	int len;
	char* current_db_name;
	if (estimate)
	{
		/* Allow space to store the babelfish fixed-size parallel state. */
		shm_toc_estimate_chunk(&pcxt->estimator, sizeof(BabelfishFixedParallelState));
		shm_toc_estimate_keys(&pcxt->estimator, 1);
	}
	else
	{
		/* Initialize babelfish fixed-size state in shared memory. */
		bfps = (BabelfishFixedParallelState *) shm_toc_allocate(pcxt->toc, sizeof(BabelfishFixedParallelState));
		current_db_name = get_cur_db_name();

		if (current_db_name == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					errmsg("database \"\" does not exist")));

		if(!DbidIsValid(get_db_id(current_db_name)))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					errmsg("database \"%s\" does not exist", current_db_name)));

		len = strlen(current_db_name);
		strncpy(bfps->logical_db_name, current_db_name, MAX_BBF_NAMEDATALEND);
		bfps->logical_db_name[len] = '\0';
		shm_toc_insert(pcxt->toc, BABELFISH_PARALLEL_KEY_FIXED, bfps);
		pfree(current_db_name);
	}
}

/* This function is responsible for restoring the babelfixedparallelstate*/
void
babelfixedparallelstate_restore(shm_toc *toc)
{
	BabelfishFixedParallelState *bfps;	

	/* Get the babelfish fixed parallel state from DSM */
	bfps = shm_toc_lookup(toc, BABELFISH_PARALLEL_KEY_FIXED, false);

	/* Set the logcial db name for parallel workers */
	set_cur_db_name_for_parallel_worker(bfps->logical_db_name);
}