#include "postgres.h"
#include "commands/explain.h"
#include "parser/scansup.h"		/* downcase_identifier */
#include "utils/guc.h"
#include "miscadmin.h"

#include "guc.h"
#include "collation.h"
#include "pltsql_instr.h"
#include "pltsql.h"
#include "pl_explain.h"
#include "miscadmin.h"
#include "access/parallel.h"

#define PLTSQL_SESSION_ISOLATION_LEVEL "default_transaction_isolation"
#define PLTSQL_TRANSACTION_ISOLATION_LEVEL "transaction_isolation"
#define PLTSQL_MIGRATION_MODE "babelfishpg_tsql.migration_mode"
#define PLTSQL_DEFAULT_LANGUAGE "us_english"

static int	migration_mode = SINGLE_DB;
bool		enable_ownership_structure = false;

bool		enable_metadata_inconsistency_check = true;

bool		pltsql_dump_antlr_query_graph = false;
bool		pltsql_enable_antlr_detailed_log = false;
bool		pltsql_enable_sll_parse_mode = true;
bool		pltsql_allow_antlr_to_unsupported_grammar_for_testing = false;
bool		pltsql_ansi_defaults = true;
bool		pltsql_quoted_identifier = true;
bool		pltsql_concat_null_yields_null = true;
bool		pltsql_ansi_nulls = true;
bool		pltsql_ansi_null_dflt_on = true;
bool		pltsql_ansi_null_dflt_off = false;
bool		pltsql_ansi_padding = true;
bool		pltsql_ansi_warnings = true;
bool		pltsql_arithignore = false;
bool		pltsql_arithabort = true;
bool		pltsql_numeric_roundabort = false;
bool		pltsql_nocount = false;
char	   *pltsql_database_name = NULL;
char	   *pltsql_version = NULL;
int			pltsql_datefirst = 7;
int			pltsql_rowcount = 0;
char	   *pltsql_language = NULL;
char	   *pltsql_psql_logical_babelfish_db_name = NULL;
int			pltsql_lock_timeout = -1;
bool		pltsql_enable_linked_servers = true;
bool		pltsql_allow_windows_login = true;
bool		pltsql_allow_fulltext_parser = false;

bool		pltsql_xact_abort = false;
bool		pltsql_implicit_transactions = false;
bool		pltsql_cursor_close_on_commit = false;
bool		pltsql_disable_batch_auto_commit = false;
bool		pltsql_disable_internal_savepoint = false;
bool		pltsql_disable_txn_in_triggers = false;
bool		pltsql_recursive_triggers = false;
bool		pltsql_noexec = false;
bool		pltsql_showplan_all = false;
bool		pltsql_showplan_text = false;
bool		pltsql_showplan_xml = false;
bool		pltsql_fmtonly = false;
bool		pltsql_enable_tsql_information_schema = false;
bool		pltsql_no_browsetable = false;

char	   *pltsql_host_destribution = NULL;
char	   *pltsql_host_release = NULL;
char	   *pltsql_host_service_pack_level = NULL;

bool		pltsql_enable_create_alter_view_from_pg = false;

static const struct config_enum_entry explain_format_options[] = {
	{"text", EXPLAIN_FORMAT_TEXT, false},
	{"xml", EXPLAIN_FORMAT_XML, false},
	{"json", EXPLAIN_FORMAT_JSON, false},
	{"yaml", EXPLAIN_FORMAT_YAML, false},
	{NULL, 0, false}
};

extern bool Transform_null_equals;

/* Dump and Restore */
bool		babelfish_dump_restore = false;
bool		restore_tsql_tabletype = false;
char	   *babelfish_dump_restore_min_oid = NULL;

/* T-SQL Hint Mapping */
bool		enable_hint_mapping = true;
bool		enable_pg_hint = false;

static bool check_ansi_null_dflt_on(bool *newval, void **extra, GucSource source);
static bool check_ansi_null_dflt_off(bool *newval, void **extra, GucSource source);
static bool check_ansi_padding(bool *newval, void **extra, GucSource source);
static bool check_ansi_warnings(bool *newval, void **extra, GucSource source);
static bool check_arithignore(bool *newval, void **extra, GucSource source);
static bool check_arithabort(bool *newval, void **extra, GucSource source);
static bool check_babelfish_dump_restore_min_oid(char **newval, void **extra, GucSource source);
static bool check_numeric_roundabort(bool *newval, void **extra, GucSource source);
static bool check_cursor_close_on_commit(bool *newval, void **extra, GucSource source);
static bool check_language(char **newval, void **extra, GucSource source);
static bool check_noexec(bool *newval, void **extra, GucSource source);
static bool check_showplan_all(bool *newval, void **extra, GucSource source);
static bool check_showplan_text(bool *newval, void **extra, GucSource source);
static bool check_showplan_xml(bool *newval, void **extra, GucSource source);
static bool check_enable_pg_hint(bool *newval, void **extra, GucSource source);
static void assign_transform_null_equals(bool newval, void *extra);
static void assign_ansi_defaults(bool newval, void *extra);
static void assign_quoted_identifier(bool newval, void *extra);
static void assign_arithabort(bool newval, void *extra);
static void assign_ansi_null_dflt_on(bool newval, void *extra);
static void assign_ansi_warnings(bool newval, void *extra);
static void assign_ansi_padding(bool newval, void *extra);
static void assign_concat_null_yields_null(bool newval, void *extra);
static void assign_language(const char *newval, void *extra);
static void assign_lock_timeout(int newval, void *extra);
static void assign_datefirst(int newval, void *extra);
static bool check_no_browsetable(bool *newval, void **extra, GucSource source);
static void assign_enable_pg_hint(bool newval, void *extra);
int			escape_hatch_session_settings;	/* forward declaration */

static const struct config_enum_entry migration_mode_options[] = {
	{"single-db", SINGLE_DB, false},
	{"multi-db", MULTI_DB, false},
	{NULL, SINGLE_DB, false}
};

static const struct config_enum_entry escape_hatch_options[] = {
	{"strict", EH_STRICT, false},
	{"ignore", EH_IGNORE, false},
	{NULL, EH_NULL, false},
};

static const struct config_enum_entry bbf_isolation_options[] = {
	{"off", ISOLATION_OFF, false},
	{"pg_isolation", PG_ISOLATION, false},
	{NULL, ISOLATION_OFF, false},
};

static bool
check_ansi_null_dflt_on(bool *newval, void **extra, GucSource source)
{
	/*
	 * We only support setting ansi_null_dflt_on to on atm, report an error if
	 * someone tries to set it to off
	 */
	if (*newval == false && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_NULL_DFLT);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("OFF setting is not allowed for option ANSI_NULL_DFLT_ON. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = true;			/* overwrite to a default value */
	}
	return true;
}

static bool
check_ansi_null_dflt_off(bool *newval, void **extra, GucSource source)
{
	/*
	 * We only support setting ansi_null_dflt_on to on atm, report an error if
	 * someone tries to set it to off
	 */
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_NULL_DFLT);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option ANSI_NULL_DFLT_OFF. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}

static bool
check_ansi_padding(bool *newval, void **extra, GucSource source)
{
	/*
	 * We only support setting ANSI_PADDING to ON atm, report an error if
	 * someone tries to set it to OFF
	 */
	if (*newval == false && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_PADDING);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("OFF setting is not allowed for option ANSI_PADDING. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = true;			/* overwrite to a default value */
	}
	return true;
}

static bool
check_ansi_warnings(bool *newval, void **extra, GucSource source)
{
	if (*newval == false && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_WARNINGS);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("OFF setting is not allowed for option ANSI_WARNINGS. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = true;			/* overwrite to a default value */
	}
	return true;
}

static bool
check_arithignore(bool *newval, void **extra, GucSource source)
{
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ARITHIGNORE);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option ARITHIGNORE. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}

static bool
check_arithabort(bool *newval, void **extra, GucSource source)
{
	if (*newval == false && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ARITHABORT);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("OFF setting is not allowed for option ARITHABORT. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = true;			/* overwrite to a default value */
	}
	return true;
}

static bool
check_babelfish_dump_restore_min_oid(char **newval, void **extra, GucSource source)
{
	return *newval == NULL || OidIsValid(atooid(*newval));
}

static bool
check_numeric_roundabort(bool *newval, void **extra, GucSource source)
{
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_NUMERIC_ROUNDABORT);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option NUMERIC_ROUNDABORT. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}

static bool
check_cursor_close_on_commit(bool *newval, void **extra, GucSource source)
{
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_CURSOR_CLOSE_ON_COMMIT);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option CURSOR_CLOSE_ON_COMMIT. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}

static bool
check_language(char **newval, void **extra, GucSource source)
{
	/* We will only allow "us_english" for now */
	if (strcmp(*newval, PLTSQL_DEFAULT_LANGUAGE) != 0 && escape_hatch_session_settings != EH_IGNORE)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Settings other than \"%s\" are not allowed for option LANGUAGE. Please use babelfishpg_tsql.escape_hatch_session_settings to ignore", PLTSQL_DEFAULT_LANGUAGE)));
	else if (escape_hatch_session_settings == EH_IGNORE)
		*newval = PLTSQL_DEFAULT_LANGUAGE;	/* overwrite to a default value */
	return true;
}

static bool
check_noexec(bool *newval, void **extra, GucSource source)
{
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_NOEXEC);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option NOEXEC. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}

static bool
check_showplan_all(bool *newval, void **extra, GucSource source)
{
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_ALL);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option SHOWPLAN_ALL. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}

static bool
check_showplan_text(bool *newval, void **extra, GucSource source)
{
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_TEXT);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option SHOWPLAN_TEXT. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}

static bool
check_no_browsetable(bool *newval, void **extra, GucSource source)
{
	if (*newval == false && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_NO_BROWSETABLE);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("OFF setting is not allowed for option NO_BROWSETABLE. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = true;			/* overwrite to a default value */
	}
	return true;
}

static bool
check_showplan_xml(bool *newval, void **extra, GucSource source)
{
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_XML);
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("ON setting is not allowed for option SHOWPLAN_XML. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false;		/* overwrite to a default value */
	}
	return true;
}
static bool
check_tsql_version(char **newval, void **extra, GucSource source)
{
	Assert(*newval != NULL);
	if (pg_strcasecmp(*newval, "default") != 0)
		ereport(WARNING,
				(errmsg("Product version setting by babelfishpg_tds.product_version GUC will have no effect on @@VERSION")));

	return true;
}

static bool
check_enable_pg_hint(bool *newval, void **extra, GucSource source)
{
	/*
     * Parallel workers send data to the leader, not the client. They always
     * send data using pg_hint_plan.enable_hint_plan.
     */
    if (IsParallelWorker() && !InitializingParallelWorker)
    {
        /*
         * A change other than during startup, for example due to a SET clause
         * attached to a function definition, should be rejected, as there is
         * nothing we can do inside the worker to make it take effect.
         */
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_TRANSACTION_STATE),
                 errmsg("cannot change enable_hint_plan during a parallel operation")));
    }

	return true;
}


static void
assign_enable_pg_hint(bool newval, void *extra)
{
    if (IsParallelWorker())
		return;
    
	if (newval)
	{
		/* Will throw an error if pg_hint_plan is not installed */
		load_libraries("pg_hint_plan", NULL, false);
	}

	if (GetConfigOption("pg_hint_plan.enable_hint", true, false))
		SetConfigOption("pg_hint_plan.enable_hint", newval ? "on" : "off", PGC_USERSET, PGC_S_SESSION);
}

static void
assign_transform_null_equals(bool newval, void *extra)
{
	Transform_null_equals = !newval;

	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_nulls", newval, NULL, 0);
}

/*
 * When ANSI_DEFAULTS is enabled, it enables the following ISO settings:
 * ANSI_NULLS, ANSI_NULL_DFLT_ON, IMPLICIT_TRANSACTIONS,
 * ANSI_PADDING, QUOTED_IDENTIFIER, ANSI_WARNINGS and CURSOR_CLOSE_ON_COMMIT
 * BUT according to doc
 * https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/t-sql/statements/set-ansi-defaults-transact-sql.md
 * ODBC driver and OLE DB automatically set ANSI_DEFAULTS to ON when connecting.
 * The driver and Provider then set CURSOR_CLOSE_ON_COMMIT and IMPLICIT_TRANSACTIONS to OFF.
 * So CURSOR_CLOSE_ON_COMMIT is actually OFF at connection but ANSI_DEFAULTS is ON.
 * Also tested that changing ANSI_DEFAULTS in a session don't change CURSOR_CLOSE_ON_COMMIT at all.
 * Thus I'm excluding CURSOR_CLOSE_ON_COMMIT from this assign function.
 */
static void
assign_ansi_defaults(bool newval, void *extra)
{
	if (newval == false && escape_hatch_session_settings != EH_IGNORE)
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("OFF setting is not allowed for option ANSI_NULL_DFLT_ON, ANSI_PADDING and ANSI_WARNINGS. Please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
	}
	else if (newval)
	{
		pltsql_ansi_nulls = true;
		/* Call the assign hook function for ANSI_NULLS as well */
		assign_transform_null_equals(true, NULL);

		pltsql_ansi_warnings = true;
		pltsql_ansi_null_dflt_on = true;
		pltsql_ansi_padding = true;
		pltsql_implicit_transactions = true;
		pltsql_quoted_identifier = true;

		if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		{
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_defaults", newval, NULL, 0);
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_warnings", true, NULL, 0);
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_null_dflt_on", true, NULL, 0);
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_padding", true, NULL, 0);
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.quoted_identifier", true, NULL, 0);
		}
	}

	/*
	 * newval == false && escape_hatch_session_settings == EH_IGNORE, skip
	 * unsupported settings
	 */
	else
	{
		pltsql_ansi_nulls = false;
		/* Call the assign hook function for ANSI_NULLS as well */
		assign_transform_null_equals(false, NULL);

		pltsql_implicit_transactions = false;
		pltsql_quoted_identifier = false;

		if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		{
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_defaults", newval, NULL, 0);
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.quoted_identifier", false, NULL, 0);
		}

		/* Skip ANSI_WARNINGS, ANSI_PADDING and ANSI_NULL_DFLT_ON */
	}
}

static void
assign_quoted_identifier(bool newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.quoted_identifier", newval, NULL, 0);
}

static void
assign_arithabort(bool newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.arithabort", newval, NULL, 0);
}

static void
assign_ansi_null_dflt_on(bool newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_null_dflt_on", newval, NULL, 0);
}

static void
assign_ansi_warnings(bool newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_warnings", newval, NULL, 0);
}

static void
assign_ansi_padding(bool newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.ansi_padding", newval, NULL, 0);
}

static void
assign_concat_null_yields_null(bool newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.concat_null_yields_null", newval, NULL, 0);
}

static void
assign_language(const char *newval, void *extra)
{
	if (pltsql_language != NULL)
	{
		char		mbuf[1024];

		snprintf(mbuf, sizeof(mbuf), "Changed language setting to '%s'",
				 newval);

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_env_change && (*pltsql_protocol_plugin_ptr)->send_info)
		{
			((*pltsql_protocol_plugin_ptr)->send_env_change) (2, newval, pltsql_language);
			((*pltsql_protocol_plugin_ptr)->send_info) (5703 /* number */ ,
														1 /* state */ ,
														10 /* class */ ,
														mbuf /* message */ ,
														1 /* line number */ );
		}

		if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
			(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.language", false, newval, 0);
	}
}

static void
assign_lock_timeout(int newval, void *extra)
{
	char		timeout_str[16];

	/*
	 * PG's lock_timeout guc will take different values depending upon newval:
	 * newval = INT_MIN to -1: no time-out period (wait forever, PG's
	 * lock_timeout = 0) newval = 0            : not wait at all and return a
	 * message as soon as a lock is encountered. (no matching setting in PG,
	 * so we will set lock_timeout to smallest possible value = 1ms) newval =
	 * 1 to INT_MAX : number of milliseconds that will pass before returns a
	 * locking error. (PG's lock_timeout = newval)
	 */

	if (newval > 0)
		snprintf(timeout_str, sizeof(timeout_str), "%d", newval);
	else if (newval == 0)
		snprintf(timeout_str, sizeof(timeout_str), "%d", 1);
	else
		snprintf(timeout_str, sizeof(timeout_str), "%d", 0);
	SetConfigOption("lock_timeout", timeout_str,
					PGC_USERSET, PGC_S_OVERRIDE);
}

static void
assign_datefirst(int newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.datefirst", false, NULL, newval);
}

void
			define_escape_hatch_variables(void);

void
define_custom_variables(void)
{
	define_escape_hatch_variables();

	DefineCustomEnumVariable("babelfishpg_tsql.migration_mode",
							 gettext_noop("Defines if multiple user databases are supported"),
							 NULL,
							 &migration_mode,
							 SINGLE_DB,
							 migration_mode_options,
							 PGC_SUSET, /* only superuser can set */
							 GUC_NO_RESET_ALL,
							 NULL, NULL, NULL);


	/* ANTLR parser */
	DefineCustomBoolVariable("babelfishpg_tsql.dump_antlr_query_graph",
							 gettext_noop("dump query graph parsed by ANTLR parser to local disk"),
							 NULL,
							 &pltsql_dump_antlr_query_graph,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.enable_antlr_detailed_log",
							 gettext_noop("enable detailed ATNLR parser logging"),
							 NULL,
							 &pltsql_enable_antlr_detailed_log,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.enable_sll_parse_mode",
							 gettext_noop("enable SLL parser mode for ANTLR parser"),
							 NULL,
							 &pltsql_enable_sll_parse_mode,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* temporary GUC until test is refactored properly */
	DefineCustomBoolVariable("babelfishpg_tsql.allow_antlr_to_unsupported_grammar_for_testing",
							 gettext_noop("GUC for internal testing - make antlr allow some of unsupported grammar"),
							 NULL,
							 &pltsql_allow_antlr_to_unsupported_grammar_for_testing,
							 false,
							 PGC_SUSET, /* only superuser can set */
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE,
							 NULL, NULL, NULL);

	/* temporary GUC for enable or disable windows login */
	DefineCustomBoolVariable("babelfishpg_tsql.allow_windows_login",
							 gettext_noop("GUC for enable or disable windows login"),
							 NULL,
							 &pltsql_allow_windows_login,
							 true,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* GUC for enabling or disabling full text search features */
	DefineCustomBoolVariable("babelfishpg_tsql.allow_fulltext_parser",
							 gettext_noop("GUC for enabling or disabling full text search features"),
							 NULL,
							 &pltsql_allow_fulltext_parser,
							 true,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_SUPERUSER_ONLY,
							 NULL, NULL, NULL);

	/* ISO standard settings */
	DefineCustomBoolVariable("babelfishpg_tsql.ansi_defaults",
							 gettext_noop("Controls a group of settings that collectively specify some "
										  "ISO standard behavior. "),
							 NULL,
							 &pltsql_ansi_defaults,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, assign_ansi_defaults, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.quoted_identifier",
							 gettext_noop("Interpret double-quoted strings as quoted identifiers"),
							 NULL,
							 &pltsql_quoted_identifier,
							 true,
							 PGC_USERSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, assign_quoted_identifier, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.concat_null_yields_null",
							 gettext_noop("If enabled, concatenating a NULL value produces a NULL result"),
							 NULL,
							 &pltsql_concat_null_yields_null,
							 true,
							 PGC_USERSET, 0,
							 NULL, assign_concat_null_yields_null, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.ansi_nulls",
							 gettext_noop("Specifies ISO compliant behavior of the Equals (=) "
										  "and Not Equal To (<>) comparison operators when they "
										  "are used with null values."),
							 NULL,
							 &pltsql_ansi_nulls,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, assign_transform_null_equals, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.ansi_null_dflt_on",
							 gettext_noop("Modifies the behavior of the session to override default nullability "
										  "of new columns when the ANSI null default option for the database is false."),

							 NULL,
							 &pltsql_ansi_null_dflt_on,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_ansi_null_dflt_on, assign_ansi_null_dflt_on, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.ansi_null_dflt_off",
							 gettext_noop("Modifies the behavior of the session to override default nullability "
										  "of new columns when the ANSI null default option for the database is on."),

							 NULL,
							 &pltsql_ansi_null_dflt_off,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_ansi_null_dflt_off, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.ansi_padding",
							 gettext_noop("Controls the way the column stores values shorter than the defined size of the column, "
										  "and the way the column stores values that have trailing blanks in char, varchar, binary, and varbinary data."),

							 NULL,
							 &pltsql_ansi_padding,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_ansi_padding, assign_ansi_padding, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.ansi_warnings",
							 gettext_noop("Specifies ISO standard behavior for several error conditions"),
							 NULL,
							 &pltsql_ansi_warnings,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_ansi_warnings, assign_ansi_warnings, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.arithignore",
							 gettext_noop("Controls whether error messages are returned from overflow or "
										  "divide-by-zero errors during a query."),
							 NULL,
							 &pltsql_arithignore,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_arithignore, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.arithabort",
							 gettext_noop("Ends a query when an overflow or divide-by-zero error occurs "
										  "during query execution."),
							 NULL,
							 &pltsql_arithabort,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_arithabort, assign_arithabort, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.numeric_roundabort",
							 gettext_noop("Ends a query when an overflow or divide-by-zero error occurs "
										  "during query execution."),
							 NULL,
							 &pltsql_numeric_roundabort,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_numeric_roundabort, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.nocount",
							 gettext_noop("Tsql compatibility NOCOUNT option."),
							 NULL,
							 &pltsql_nocount,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.database_name",
							   gettext_noop("Predefined Babelfish database name"),
							   NULL,
							   &pltsql_database_name,
							   "babelfish_db",
							   PGC_SUSET,
							   GUC_NOT_IN_SAMPLE | GUC_NO_RESET_ALL,
							   NULL, NULL, NULL);

	DefineCustomStringVariable("psql_logical_babelfish_db_name",
							   gettext_noop("Sets a Babelfish database name from PG endpoint"),
							   NULL,
							   &pltsql_psql_logical_babelfish_db_name,
							   NULL,
							   PGC_USERSET,
							   GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_NO_RESET_ALL | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							   NULL, NULL, NULL);

	DefineCustomIntVariable("babelfishpg_tsql.datefirst",
							gettext_noop("Sets the first day of the week to a number from 1 through 7."),
							NULL,
							&pltsql_datefirst,
							7, 1, 7,
							PGC_USERSET,
							GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							NULL, assign_datefirst, NULL);

	DefineCustomIntVariable("babelfishpg_tsql.rowcount",
							gettext_noop("Causes the DB engine to stop processing the query after the "
										 "specified number of rows are returned."),
							NULL,
							&pltsql_rowcount,
							0, 0, INT_MAX,
							PGC_USERSET,
							GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							NULL, NULL, NULL);

	DefineCustomIntVariable("babelfishpg_tsql.lock_timeout",
							gettext_noop("Specifies the number of milliseconds a statement waits for a lock to be released."),
							NULL,
							&pltsql_lock_timeout,
							-1, INT_MIN, INT_MAX,
							PGC_USERSET,
							GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							NULL, assign_lock_timeout, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.version",
							   gettext_noop("Sets the output of @@VERSION variable"),
							   NULL,
							   &pltsql_version,
							   "default",
							   PGC_SUSET,
							   GUC_NOT_IN_SAMPLE,
							   check_tsql_version, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.language",
							   gettext_noop("T-SQL compatibility LANGUAGE option."),
							   NULL,
							   &pltsql_language,
							   "us_english",	/* TODO correct boot value? */
							   PGC_USERSET, 0,
							   check_language, assign_language, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.xact_abort",
							 gettext_noop("enable xact abort"),
							 NULL,
							 &pltsql_xact_abort,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	pltsql_implicit_transactions = false;
	// define babelfishpg_tsql.ansi_defaults will set pltsql_implicit_transactions = true
	// that's not expected during initialize, set to false as the same for default

	DefineCustomBoolVariable("babelfishpg_tsql.implicit_transactions",
							 gettext_noop("enable implicit transactions"),
							 NULL,
							 &pltsql_implicit_transactions,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.cursor_close_on_commit",
							 gettext_noop("Controls the behavior of the cursor during COMMIT TRANSACTION "
										  "statement."),
							 NULL,
							 &pltsql_cursor_close_on_commit,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_cursor_close_on_commit, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.disable_batch_auto_commit",
							 gettext_noop("disable auto commit inside procedures"),
							 NULL,
							 &pltsql_disable_batch_auto_commit,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.disable_internal_savepoint",
							 gettext_noop("disable internal savepoints"),
							 NULL,
							 &pltsql_disable_internal_savepoint,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.disable_txn_in_triggers",
							 gettext_noop("disable transaction in triggers"),
							 NULL,
							 &pltsql_disable_txn_in_triggers,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.recursive_triggers",
							 gettext_noop("SQL-Server compatibility recursive_triggers option"),
							 NULL,
							 &pltsql_recursive_triggers,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.noexec",
							 gettext_noop("SQL-Server compatibility NOEXEC option."),
							 NULL,
							 &pltsql_noexec,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_noexec, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.fmtonly",
							 gettext_noop("SQL-Server compatibility FMTONLY option."),
							 NULL,
							 &pltsql_fmtonly,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.showplan_all",
							 gettext_noop("SQL-Server compatibility SHOWPLAN_ALL option."),
							 NULL,
							 &pltsql_showplan_all,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_showplan_all, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.showplan_text",
							 gettext_noop("SQL-Server compatibility SHOWPLAN_TEXT option."),
							 NULL,
							 &pltsql_showplan_text,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_showplan_text, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.no_browsetable",
							 gettext_noop("SQL-Server compatibility NO_BROWSETABLE option."),
							 NULL,
							 &pltsql_no_browsetable,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_no_browsetable, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.showplan_xml",
							 gettext_noop("SQL-Server compatibility SHOWPLAN_XML option."),
							 NULL,
							 &pltsql_showplan_xml,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_showplan_xml, NULL, NULL);
	DefineCustomBoolVariable("babelfishpg_tsql.enable_tsql_information_schema",
							 gettext_noop("toggles between the information_schema for postgres and tsql"),
							 NULL,
							 &pltsql_enable_tsql_information_schema,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* EXPLAIN-related GUCs */
	DefineCustomBoolVariable("babelfishpg_tsql.explain_verbose",
							 gettext_noop("Display additional information regarding the plan"),
							 NULL,
							 &pltsql_explain_verbose,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.explain_costs",
							 gettext_noop("Include information on estimated startup and total cost"),
							 NULL,
							 &pltsql_explain_costs,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.explain_settings",
							 gettext_noop("Include information on configuration parameters"),
							 NULL,
							 &pltsql_explain_settings,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.explain_buffers",
							 gettext_noop("Include information on buffer usage"),
							 NULL,
							 &pltsql_explain_buffers,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.explain_wal",
							 gettext_noop("Include information on WAL record generation"),
							 NULL,
							 &pltsql_explain_wal,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.explain_timing",
							 gettext_noop("Include actual startup time and time spent in each node in the output"),
							 NULL,
							 &pltsql_explain_timing,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.explain_summary",
							 gettext_noop("Include summary information (e.g., totaled timing information) after the query plan"),
							 NULL,
							 &pltsql_explain_summary,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.explain_format",
							 "Specify the output format, which can be TEXT, XML, JSON, or YAML",
							 NULL,
							 &pltsql_explain_format,
							 EXPLAIN_FORMAT_TEXT,
							 explain_format_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* Host info related GUCs */
	DefineCustomStringVariable("babelfishpg_tsql.host_distribution",
							   gettext_noop("Sets host distribution"),
							   NULL,
							   &pltsql_host_destribution,
							   "",
							   PGC_SIGHUP,
							   GUC_NOT_IN_SAMPLE,
							   NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.host_release",
							   gettext_noop("Sets host release"),
							   NULL,
							   &pltsql_host_release,
							   "",
							   PGC_SIGHUP,
							   GUC_NOT_IN_SAMPLE,
							   NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.host_service_pack_level",
							   gettext_noop("Sets host service pack level"),
							   NULL,
							   &pltsql_host_service_pack_level,
							   "",
							   PGC_SIGHUP,
							   GUC_NOT_IN_SAMPLE,
							   NULL, NULL, NULL);

	/*
	 * Block DDL from PG endpoint Currently only blocks DDLs for View object
	 */
	DefineCustomBoolVariable("babelfishpg_tsql.enable_create_alter_view_from_pg",
							 gettext_noop("Enables blocked DDL statements from PG endpoint"),
							 NULL,
							 &pltsql_enable_create_alter_view_from_pg,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* Dump and Restore */
	DefineCustomBoolVariable("babelfishpg_tsql.dump_restore",
							 gettext_noop("Enable special handlings during dump and restore"),
							 NULL,
							 &babelfish_dump_restore,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.restore_tsql_tabletype",
							 gettext_noop("Shows that if a table is creating a T-SQL table type during restore"),
							 NULL,
							 &restore_tsql_tabletype,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.dump_restore_min_oid",
							   gettext_noop("All new OIDs should be greater than this number during dump and restore"),
							   NULL,
							   &babelfish_dump_restore_min_oid,
							   NULL,
							   PGC_USERSET,
							   GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							   check_babelfish_dump_restore_min_oid, NULL, NULL);

	/* 
	 * This is an int here but actually represents an Oid (uint32). It's accessed only in hooks.c using the 
	 * macros defined there. 
	 */
	DefineCustomIntVariable("babelfishpg_tsql.temp_oid_buffer_start",
							gettext_noop("Internal. Specifies the start range of the buffer for temp oids"),
							NULL,
							&temp_oid_buffer_start,
							INT_MIN, INT_MIN, INT_MAX, 
							PGC_SUSET,
							GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							NULL, NULL, NULL);

	/*
	 * For now, Oid buffer size will not be adjustable by users. A value of 0 will disable temp oid generation.
	 */
	DefineCustomIntVariable("babelfishpg_tsql.temp_oid_buffer_size",
							gettext_noop("Temp oid buffer size"),
							NULL,
							&temp_oid_buffer_size,
							65536, 0, 131072,
							PGC_SUSET,
							GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.temp_table_xact_support",
							 gettext_noop("Enable temp table changes to respect transactional behavior"),
							 NULL,
							 &temp_table_xact_support,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* T-SQL Hint Mapping */
	DefineCustomBoolVariable("babelfishpg_tsql.enable_hint_mapping",
							 gettext_noop("Enables T-SQL hint mapping in ANTLR parser"),
							 NULL,
							 &enable_hint_mapping,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);
	DefineCustomBoolVariable("babelfishpg_tsql.enable_pg_hint",
							 gettext_noop("Loads and enables pg_hint_plan library"),
							 NULL,
							 &enable_pg_hint,
							 false,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 check_enable_pg_hint, assign_enable_pg_hint, NULL);

	DefineCustomIntVariable("babelfishpg_tsql.insert_bulk_rows_per_batch",
							gettext_noop("Sets the number of rows per batch to be processed for Insert Bulk"),
							NULL,
							&insert_bulk_rows_per_batch,
							DEFAULT_INSERT_BULK_ROWS_PER_BATCH, 1, INT_MAX,
							PGC_USERSET,
							GUC_NOT_IN_SAMPLE,
							NULL, NULL, NULL);

	DefineCustomIntVariable("babelfishpg_tsql.insert_bulk_kilobytes_per_batch",
							gettext_noop("Sets the number of bytes per batch to be processed for Insert Bulk"),
							NULL,
							&insert_bulk_kilobytes_per_batch,
							DEFAULT_INSERT_BULK_PACKET_SIZE, 1, INT_MAX,
							PGC_USERSET,
							GUC_NOT_IN_SAMPLE,
							NULL, NULL, NULL);


	DefineCustomBoolVariable("babelfishpg_tsql.enable_metadata_inconsistency_check",
							 gettext_noop("Enables babelfish_inconsistent_metadata"),
							 NULL,
							 &enable_metadata_inconsistency_check,
							 true,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.enable_linked_servers",
							 gettext_noop("Enables linked servers"),
							 NULL,
							 &pltsql_enable_linked_servers,
							 true,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);
}

int			escape_hatch_storage_options = EH_IGNORE;
int			escape_hatch_storage_on_partition = EH_STRICT;
int			escape_hatch_database_misc_options = EH_IGNORE;
int			escape_hatch_language_non_english = EH_STRICT;
int			escape_hatch_login_hashed_password = EH_STRICT;
int			escape_hatch_login_old_password = EH_STRICT;
int			escape_hatch_login_password_must_change = EH_STRICT;
int			escape_hatch_login_password_unlock = EH_STRICT;
int			escape_hatch_login_misc_options = EH_STRICT;
int			escape_hatch_compatibility_level = EH_IGNORE;
int			escape_hatch_fulltext = EH_STRICT;
int			escape_hatch_schemabinding_function = EH_IGNORE;
int			escape_hatch_schemabinding_trigger = EH_IGNORE;
int			escape_hatch_schemabinding_procedure = EH_IGNORE;
int			escape_hatch_schemabinding_view = EH_IGNORE;
int			escape_hatch_index_clustering = EH_IGNORE;
int			escape_hatch_index_columnstore = EH_STRICT;
int			escape_hatch_for_replication = EH_STRICT;
int			escape_hatch_rowguidcol_column = EH_IGNORE;
int			escape_hatch_nocheck_add_constraint = EH_STRICT;
int			escape_hatch_nocheck_existing_constraint = EH_STRICT;
int			escape_hatch_constraint_name_for_default = EH_IGNORE;
int			escape_hatch_table_hints = EH_IGNORE;
int			escape_hatch_query_hints = EH_IGNORE;
int			escape_hatch_join_hints = EH_IGNORE;
int			escape_hatch_session_settings = EH_IGNORE;
int			escape_hatch_ignore_dup_key = EH_STRICT;
int			escape_hatch_rowversion = EH_STRICT;
int			escape_hatch_showplan_all = EH_STRICT;
int			escape_hatch_checkpoint = EH_IGNORE;
int			escape_hatch_set_transaction_isolation_level = EH_STRICT;
int			pltsql_isolation_level_repeatable_read = ISOLATION_OFF;
int 		pltsql_isolation_level_serializable = ISOLATION_OFF;
int 		escape_hatch_identity_function = EH_STRICT;
int 		escape_hatch_insert_bulk_options = EH_IGNORE;

void
define_escape_hatch_variables(void)
{
	/* storage_options */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_storage_options",
							 gettext_noop("escape hatch for storage options option in CREATE/ALTER TABLE/INDEX"),
							 NULL,
							 &escape_hatch_storage_options,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* storage_on_partition */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_storage_on_partition",
							 gettext_noop("escape hatch for storage_on_partition option in CREATE/ALTER TABLE and CREATE INDEX"),
							 NULL,
							 &escape_hatch_storage_on_partition,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* database_misc_options */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_database_misc_options",
							 gettext_noop("escape hatch for misc options in CREATE/ALTER DATABASE"),
							 NULL,
							 &escape_hatch_database_misc_options,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* language non_english */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_language_non_english",
							 gettext_noop("escape hatch for non-english language"),
							 NULL,
							 &escape_hatch_language_non_english,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* login hashed password */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_login_hashed_password",
							 gettext_noop("escape hatch for login hashed passwords"),
							 NULL,
							 &escape_hatch_login_hashed_password,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* login old password */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_login_old_password",
							 gettext_noop("escape hatch for login old passwords"),
							 NULL,
							 &escape_hatch_login_old_password,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* login password must_change */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_login_password_must_change",
							 gettext_noop("escape hatch for login passwords must_change option"),
							 NULL,
							 &escape_hatch_login_password_must_change,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* login password unlock */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_login_password_unlock",
							 gettext_noop("escape hatch for login passwords unlock option"),
							 NULL,
							 &escape_hatch_login_password_unlock,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* login misc options */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_login_misc_options",
							 gettext_noop("escape hatch for login miscellaneous options"),
							 NULL,
							 &escape_hatch_login_misc_options,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* compatibility_level */

	/*
	 * disable escape_hatch_compatibility_level as long as we block all ALTER
	 * DATABASE
	 */

	/*
	 *
	 * DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_compatibility_level",
	 * gettext_noop("escape hatch for compatibility level"), NULL,
	 * &escape_hatch_compatibility_level, EH_IGNORE, escape_hatch_options,
	 * PGC_USERSET, GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE |
	 * GUC_DISALLOW_IN_AUTO_FILE, NULL, NULL, NULL);
	 */

	/* fulltext */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_fulltext",
							 gettext_noop("escape hatch for fulltext search"),
							 NULL,
							 &escape_hatch_fulltext,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* schemabinding */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_schemabinding_function",
							 gettext_noop("escape hatch for SCHEMABINDING option in CREATE FUNCTION"),
							 NULL,
							 &escape_hatch_schemabinding_function,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_schemabinding_trigger",
							 gettext_noop("escape hatch for SCHEMABINDING option in CREATE TRIGGER"),
							 NULL,
							 &escape_hatch_schemabinding_trigger,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_schemabinding_procedure",
							 gettext_noop("escape hatch for SCHEMABINDING option in CREATE PROCEDURE"),
							 NULL,
							 &escape_hatch_schemabinding_procedure,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_schemabinding_view",
							 gettext_noop("escape hatch for SCHEMABINDING option in CREATE VIEW"),
							 NULL,
							 &escape_hatch_schemabinding_view,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* index clustering */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_index_clustering",
							 gettext_noop("escape hatch for CLUSTERED option in CREATE INDEX"),
							 NULL,
							 &escape_hatch_index_clustering,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* index columnstore */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_index_columnstore",
							 gettext_noop("escape hatch for COLUMNSTORE option in CREATE INDEX"),
							 NULL,
							 &escape_hatch_index_columnstore,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* for_replication */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_for_replication",
							 gettext_noop("escape hatch for (NOT) FOR REPLICATION option"),
							 NULL,
							 &escape_hatch_for_replication,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* ROWGUIDCOL */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_rowguidcol_column",
							 gettext_noop("escape hatch for ROWGUIDCOL option"),
							 NULL,
							 &escape_hatch_rowguidcol_column,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* with [no]check */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_nocheck_add_constraint",
							 gettext_noop("escape hatch for WITH [NO]CHECK option in alter table add"),
							 NULL,
							 &escape_hatch_nocheck_add_constraint,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_nocheck_existing_constraint",
							 gettext_noop("escape hatch for WITH [NO]CHECK option in alter table on exsiting constraint"),
							 NULL,
							 &escape_hatch_nocheck_existing_constraint,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* escape_hatch_constraint_name_for_default */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_constraint_name_for_default",
							 gettext_noop("escape hatch for DEFAULT option in alter table add constraint"),
							 NULL,
							 &escape_hatch_constraint_name_for_default,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* hints */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_table_hints",
							 gettext_noop("escape hatch for table hints"),
							 NULL,
							 &escape_hatch_table_hints,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_query_hints",
							 gettext_noop("escape hatch for query hints"),
							 NULL,
							 &escape_hatch_query_hints,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_join_hints",
							 gettext_noop("escape hatch for join hints"),
							 NULL,
							 &escape_hatch_join_hints,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_session_settings",
							 gettext_noop("escape hatch for session settings"),
							 NULL,
							 &escape_hatch_session_settings,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);
	/* Ignore_dup_key */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_ignore_dup_key",
							 gettext_noop("escape hatch for ignore_dup_key=on option in CREATE/ALTER TABLE/INDEX"),
							 NULL,
							 &escape_hatch_ignore_dup_key,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_rowversion",
							 gettext_noop("escape hatch for TIMESTAMP/ROWVERSION columns"),
							 NULL,
							 &escape_hatch_rowversion,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* SHOWPLAN_ALL */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_showplan_all",
							 gettext_noop("escape hatch for SHOWPLAN_ALL and STATISTICS PROFILE"),
							 NULL,
							 &escape_hatch_showplan_all,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* CHECKPOINT */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_checkpoint",
							 gettext_noop("escape hatch for CHECKPOINT"),
							 NULL,
							 &escape_hatch_checkpoint,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);
	
	/* SET TRANSACTION ISOLATION */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_set_transaction_isolation_level",
							 gettext_noop("escape hatch for SET TRANSACTION ISOLATION LEVEL"),
							 NULL,
							 &escape_hatch_set_transaction_isolation_level,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	/* REPEATABLE READ MAPPING */
	DefineCustomEnumVariable("babelfishpg_tsql.isolation_level_repeatable_read",
							 gettext_noop("Select mapping for isolation level reapeatable read"),
							 NULL,
							 &pltsql_isolation_level_repeatable_read,
							 ISOLATION_OFF,
							 bbf_isolation_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);
	
	/* SERIALIZABLE MAPPING */
	DefineCustomEnumVariable("babelfishpg_tsql.isolation_level_serializable",
							 gettext_noop("Select mapping for isolation level serializable"),
							 NULL,
							 &pltsql_isolation_level_serializable,
							 ISOLATION_OFF,
							 bbf_isolation_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);
	
	/* IDENTITY() in SELECT-INTO */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_identity_function",
							 gettext_noop("escape hatch for IDENTITY() in SELECT-INTO"),
							 NULL,
							 &escape_hatch_identity_function,
							 EH_STRICT,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_insert_bulk_options",
							 gettext_noop("escape hatch for unsupported INSERT BULK OPTIONS"),
							 NULL,
							 &escape_hatch_insert_bulk_options,
							 EH_IGNORE,
							 escape_hatch_options,
							 PGC_USERSET,
							 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);
}

void
pltsql_validate_set_config_function(char *name, char *value)
{
	if (strncmp(name, PLTSQL_SESSION_ISOLATION_LEVEL, strlen(PLTSQL_SESSION_ISOLATION_LEVEL)) == 0 ||
		strncmp(name, PLTSQL_TRANSACTION_ISOLATION_LEVEL, strlen(PLTSQL_TRANSACTION_ISOLATION_LEVEL)) == 0 ||
		strncmp(name, PLTSQL_MIGRATION_MODE, strlen(PLTSQL_MIGRATION_MODE)) == 0 ||
		strncmp(name, "role", strlen("role")) == 0)
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set_config not allowed for option %s", name)));

	}
}

/*************************************
 * 				Getters
 ************************************/

MigrationMode
get_migration_mode(void)
{
	return (MigrationMode) migration_mode;
}


bool
metadata_inconsistency_check_enabled(void)
{
	return enable_metadata_inconsistency_check;
}
