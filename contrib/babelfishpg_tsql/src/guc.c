#include "postgres.h"
#include "utils/guc.h"

#include "guc.h"
#include "collation.h"
#include "pltsql_instr.h"
#include "pltsql.h"

#define PLTSQL_SESSION_ISOLATION_LEVEL "default_transaction_isolation"
#define PLTSQL_TRANSACTION_ISOLATION_LEVEL "transaction_isolation"
#define PLTSQL_DEFAULT_LANGUAGE "us_english"

static int migration_mode = SINGLE_DB;
bool   enable_ownership_structure = false;

bool pltsql_use_antlr = true;
bool pltsql_dump_antlr_query_graph = false;
bool pltsql_enable_antlr_detailed_log = false;
bool pltsql_allow_antlr_to_unsupported_grammar_for_testing = false;
char* pltsql_default_locale = NULL;
char* pltsql_server_collation_name = NULL;
bool  pltsql_ansi_defaults = true;
bool  pltsql_quoted_identifier = true;
bool  pltsql_concat_null_yields_null = true;
bool  pltsql_ansi_nulls = true;
bool  pltsql_ansi_null_dflt_on = true;
bool  pltsql_ansi_null_dflt_off = false;
bool  pltsql_ansi_padding = true;
bool  pltsql_ansi_warnings = true;
bool  pltsql_arithignore = false;
bool  pltsql_arithabort = true;
bool  pltsql_numeric_roundabort = false;
bool  pltsql_nocount = false;
char* pltsql_database_name = NULL;
char* pltsql_version = NULL;
int   pltsql_datefirst = 7;
int   pltsql_rowcount = 0;
char* pltsql_language = NULL;


bool	pltsql_xact_abort = false;
bool	pltsql_implicit_transactions = false;
bool	pltsql_cursor_close_on_commit = false;
bool	pltsql_disable_batch_auto_commit = false;
bool	pltsql_disable_internal_savepoint = false;
bool	pltsql_disable_txn_in_triggers = false;
bool    pltsql_recursive_triggers = false;
bool  pltsql_noexec = false;
bool  pltsql_showplan_all = false;
bool  pltsql_showplan_text = false;
bool  pltsql_showplan_xml = false;
bool    pltsql_fmtonly = false;

extern bool Transform_null_equals;

static bool check_server_collation_name(char **newval, void **extra, GucSource source);
static bool check_default_locale (char **newval, void **extra, GucSource source);
static bool check_ansi_null_dflt_on (bool *newval, void **extra, GucSource source);
static bool check_ansi_null_dflt_off (bool *newval, void **extra, GucSource source);
static bool check_ansi_padding (bool *newval, void **extra, GucSource source);
static bool check_ansi_warnings (bool *newval, void **extra, GucSource source);
static bool check_arithignore (bool *newval, void **extra, GucSource source);
static bool check_arithabort (bool *newval, void **extra, GucSource source);
static bool check_numeric_roundabort (bool *newval, void **extra, GucSource source);
static bool check_cursor_close_on_commit (bool *newval, void **extra, GucSource source);
static bool check_rowcount (int *newval, void **extra, GucSource source);
static bool check_language (char **newval, void **extra, GucSource source);
static bool check_noexec (bool *newval, void **extra, GucSource source);
static bool check_showplan_all (bool *newval, void **extra, GucSource source);
static bool check_showplan_text (bool *newval, void **extra, GucSource source);
static bool check_showplan_xml (bool *newval, void **extra, GucSource source);
static void assign_transform_null_equals (bool newval, void *extra);
static void assign_ansi_defaults (bool newval, void *extra);
static void assign_language (const char *newval, void *extra);
int escape_hatch_session_settings; /* forward declaration */

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

static bool check_server_collation_name(char **newval, void **extra, GucSource source)
{
    return is_valid_server_collation_name(*newval);
}

static bool check_default_locale (char **newval, void **extra, GucSource source)
{
    if (find_locale(*newval) >= 0)
	return true;

    return false;
}

static bool check_ansi_null_dflt_on (bool *newval, void **extra, GucSource source)
{
    /* We only support setting ansi_null_dflt_on to on atm, report an error if someone tries to set it to off */
	if (*newval == false && escape_hatch_session_settings != EH_IGNORE)
    {
	TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_NULL_DFLT);
	ereport(ERROR,
		(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
		 errmsg("OFF setting is not allowed for option ANSI_NULL_DFLT_ON. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
    }
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = true; /* overwrite to a default value */
	}
    return true;
}

static bool check_ansi_null_dflt_off (bool *newval, void **extra, GucSource source)
{
    /* We only support setting ansi_null_dflt_on to on atm, report an error if someone tries to set it to off */
	if (*newval == true && escape_hatch_session_settings != EH_IGNORE)
    {
	TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_NULL_DFLT);
	ereport(ERROR,
		(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
		 errmsg("ON setting is not allowed for option ANSI_NULL_DFLT_OFF. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
    }
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = false; /* overwrite to a default value */
	}
    return true;
}

static bool check_ansi_padding (bool *newval, void **extra, GucSource source)
{
    /* We only support setting ANSI_PADDING to ON atm, report an error if someone tries to set it to OFF */
	if (*newval == false && escape_hatch_session_settings != EH_IGNORE)
    {
	TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_PADDING);
	ereport(ERROR,
		(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
		 errmsg("OFF setting is not allowed for option ANSI_PADDING. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
    }
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = true; /* overwrite to a default value */
	}
    return true;
}

static bool check_ansi_warnings (bool *newval, void **extra, GucSource source)
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
		*newval = true; /* overwrite to a default value */
	}
    return true;
}

static bool check_arithignore (bool *newval, void **extra, GucSource source)
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
		*newval = false; /* overwrite to a default value */
	}
    return true;
}

static bool check_arithabort (bool *newval, void **extra, GucSource source)
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
		*newval = true; /* overwrite to a default value */
	}
    return true;
}

static bool check_numeric_roundabort (bool *newval, void **extra, GucSource source)
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
		*newval = false; /* overwrite to a default value */
	}
    return true;
}

static bool check_cursor_close_on_commit (bool *newval, void **extra, GucSource source)
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
	*newval = false; /* overwrite to a default value */
    }
    return true;
}

static bool check_rowcount (int *newval, void **extra, GucSource source)
{
	if (*newval != 0 && *newval != INT_MAX && escape_hatch_session_settings != EH_IGNORE)
    {
	TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ROWCOUNT);
	ereport(ERROR,
		(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
		 errmsg("Settings other than 0 are not allowed for option ROWCOUNT. please use babelfishpg_tsql.escape_hatch_session_settings to ignore")));
    }
	else if (escape_hatch_session_settings == EH_IGNORE)
	{
		*newval = 0; /* overwrite to a default value. This would change the value if it was set to INT_MAX before. but, it would not cause a pratical problem */
	}
    return true;
}

static bool check_language (char **newval, void **extra, GucSource source)
{
	/* We will only allow "us_english" for now */
	if (strcmp(*newval, PLTSQL_DEFAULT_LANGUAGE) != 0 && escape_hatch_session_settings != EH_IGNORE)
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
			 errmsg("Settings other than \"%s\" are not allowed for option LANGUAGE. Please use babelfishpg_tsql.escape_hatch_session_settings to ignore", PLTSQL_DEFAULT_LANGUAGE)));
	else if (escape_hatch_session_settings == EH_IGNORE)
		*newval = PLTSQL_DEFAULT_LANGUAGE; /* overwrite to a default value */
	return true;
}

static bool check_noexec (bool *newval, void **extra, GucSource source)
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
		*newval = false; /* overwrite to a default value */
	}
	return true;
}

static bool check_showplan_all (bool *newval, void **extra, GucSource source)
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
		*newval = false; /* overwrite to a default value */
	}
	return true;
}

static bool check_showplan_text (bool *newval, void **extra, GucSource source)
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
		*newval = false; /* overwrite to a default value */
	}
	return true;
}

static bool check_showplan_xml (bool *newval, void **extra, GucSource source)
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
		*newval = false; /* overwrite to a default value */
	}
	return true;
}

static void assign_transform_null_equals (bool newval, void *extra)
{
	Transform_null_equals = !newval;
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
static void assign_ansi_defaults (bool newval, void *extra)
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
	assign_transform_null_equals (true, NULL);

	pltsql_ansi_warnings = true;
	pltsql_ansi_null_dflt_on = true;
	pltsql_ansi_padding = true;
	pltsql_implicit_transactions = true;
	pltsql_quoted_identifier = true;
    }
    /* newval == false && escape_hatch_session_settings == EH_IGNORE, skip unsupported settings */
    else
    {
        pltsql_ansi_nulls = false;
	/* Call the assign hook function for ANSI_NULLS as well */
	assign_transform_null_equals (false, NULL);

	pltsql_implicit_transactions = false;
	pltsql_quoted_identifier = false;

	/* Skip ANSI_WARNINGS, ANSI_PADDING and ANSI_NULL_DFLT_ON */
    }
}

static void assign_language (const char *newval, void *extra)
{
	if (pltsql_language != NULL)
	{
		char	mbuf[1024];
		snprintf(mbuf, sizeof(mbuf), "Changed language setting to '%s'",
				 newval);

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_env_change && (*pltsql_protocol_plugin_ptr)->send_info)
		{
			((*pltsql_protocol_plugin_ptr)->send_env_change) (2, newval, pltsql_language);
			((*pltsql_protocol_plugin_ptr)->send_info) (5703 /* number */,
									1 /* state */,
									10 /* class */,
									mbuf /* message */,
									1 /* line number */);
		}
	}
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
							  PGC_SUSET,  /* only superuser can set */
							  GUC_NO_RESET_ALL,
							  NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.enable_ownership_structure",
				 gettext_noop("Enable Babelfish Ownership Structure"),
				 NULL,
				 &enable_ownership_structure,
				 false,
				 PGC_SUSET,  /* only superuser can set */
				 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				 NULL, NULL, NULL);

	/* ANTLR parser */
	DefineCustomBoolVariable("babelfishpg_tsql.use_antlr",
				 gettext_noop("Selects new ANTLR parser for pl/tsql functions, procedures, trigger, and batches."),
				 NULL,
				 &pltsql_use_antlr,
				 true,
				 PGC_SUSET,
				 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				 NULL, NULL, NULL);

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

	/* temporary GUC until test is refactored properly */
	DefineCustomBoolVariable("babelfishpg_tsql.allow_antlr_to_unsupported_grammar_for_testing",
				 gettext_noop("GUC for internal testing - make antlr allow some of unsupported grammar"),
				 NULL,
				 &pltsql_allow_antlr_to_unsupported_grammar_for_testing,
				 false,
				 PGC_SUSET,  /* only superuser can set */
				 GUC_NO_SHOW_ALL,
				 NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.server_collation_name",
				   gettext_noop("Name of the default server collation."),
				   NULL,
				   &pltsql_server_collation_name,
				   "sql_latin1_general_cp1_ci_as",
				   PGC_SIGHUP,
				   GUC_NO_RESET_ALL,
				   check_server_collation_name, NULL, NULL);


	DefineCustomStringVariable("babelfishpg_tsql.default_locale",
				   gettext_noop("The default locale to use when creating a new collation."),
				   NULL,
				   &pltsql_default_locale,
				   "en_US",
				   PGC_SUSET,  /* only superuser can set */
				   0,
				   check_default_locale, NULL, NULL);

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
				 NULL, NULL, NULL);
	
	DefineCustomBoolVariable("babelfishpg_tsql.concat_null_yields_null",
				 gettext_noop("If enabled, concatenating a NULL value produces a NULL result"),
				 NULL,
				 &pltsql_concat_null_yields_null,
				 true,
				 PGC_USERSET, 0,
				 NULL, NULL, NULL);

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
				 check_ansi_null_dflt_on, NULL, NULL);

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
				 check_ansi_padding, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.ansi_warnings",
				 gettext_noop("Specifies ISO standard behavior for several error conditions"),
				 NULL,
				 &pltsql_ansi_warnings,
				 true,
				 PGC_USERSET,
				 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				 check_ansi_warnings, NULL, NULL);

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
				 check_arithabort, NULL, NULL);

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

	DefineCustomIntVariable("babelfishpg_tsql.datefirst",
				 gettext_noop("Sets the first day of the week to a number from 1 through 7."),
				 NULL,
				 &pltsql_datefirst,
				 7, 1, 7,
				 PGC_USERSET,
				 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				 NULL, NULL, NULL);

	DefineCustomIntVariable("babelfishpg_tsql.rowcount",
				 gettext_noop("Causes the DB engine to stop processing the query after the "
					      "specified number of rows are returned."),
				 NULL,
				 &pltsql_rowcount,
				 0, 0, INT_MAX,
				 PGC_USERSET,
				 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				 check_rowcount, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.version",
				 gettext_noop("Sets the output of @@VERSION variable"),
				 NULL,
				 &pltsql_version,
				 "default",
				 PGC_SUSET,
				 GUC_NOT_IN_SAMPLE,
				 NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.language",
				 gettext_noop("T-SQL compatibility LANGUAGE option."),
				 NULL,
				 &pltsql_language,
				 "us_english", /* TODO correct boot value? */
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

	DefineCustomBoolVariable("babelfishpg_tsql.showplan_xml",
				 gettext_noop("SQL-Server compatibility SHOWPLAN_XML option."),
				 NULL,
				 &pltsql_showplan_xml,
				 false,
				 PGC_USERSET,
				 GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				 check_showplan_xml, NULL, NULL);
}

int escape_hatch_storage_options = EH_IGNORE;
int escape_hatch_storage_on_partition = EH_STRICT;
int escape_hatch_database_misc_options = EH_IGNORE;
int escape_hatch_language_non_english = EH_STRICT;
int escape_hatch_login_hashed_password = EH_STRICT;
int escape_hatch_login_old_password = EH_STRICT;
int escape_hatch_login_password_must_change = EH_STRICT;
int escape_hatch_login_password_unlock = EH_STRICT;
int escape_hatch_login_misc_options = EH_STRICT;
int escape_hatch_compatibility_level = EH_IGNORE;
int escape_hatch_fulltext = EH_STRICT;
int escape_hatch_schemabinding_function = EH_IGNORE;
int escape_hatch_schemabinding_trigger = EH_IGNORE;
int escape_hatch_schemabinding_procedure = EH_IGNORE;
int escape_hatch_schemabinding_view = EH_IGNORE;
int escape_hatch_index_clustering = EH_IGNORE;
int escape_hatch_index_columnstore = EH_STRICT;
int escape_hatch_for_replication = EH_STRICT;
int escape_hatch_rowguidcol_column = EH_IGNORE;
int escape_hatch_nocheck_add_constraint = EH_STRICT;
int escape_hatch_nocheck_existing_constraint = EH_STRICT;
int escape_hatch_constraint_name_for_default = EH_IGNORE;
int escape_hatch_table_hints = EH_IGNORE;
int escape_hatch_query_hints = EH_IGNORE;
int escape_hatch_join_hints = EH_IGNORE;
int escape_hatch_session_settings = EH_IGNORE;
int escape_hatch_unique_constraint = EH_STRICT;

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

	/* disable escape_hatch_compatibility_level as long as we block all ALTER DATABASE */
	/*
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_compatibility_level",
							  gettext_noop("escape hatch for compatibility level"),
							  NULL,
							  &escape_hatch_compatibility_level,
							  EH_IGNORE,
							  escape_hatch_options,
							  PGC_USERSET,
							  GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							  NULL, NULL, NULL);
	*/

	/* fulltext */
	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_fulltext",
							  gettext_noop("escape hatch for fulltext"),
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

	DefineCustomEnumVariable("babelfishpg_tsql.escape_hatch_unique_constraint",
							  gettext_noop("escape hatch for unique constraint"),
							  NULL,
							  &escape_hatch_unique_constraint,
							  EH_STRICT,
							  escape_hatch_options,
							  PGC_USERSET,
							  GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							  NULL, NULL, NULL);
}

void
pltsql_validate_set_config_function(char *name, char *value)
{
	if (strncmp(name, PLTSQL_SESSION_ISOLATION_LEVEL, strlen(PLTSQL_SESSION_ISOLATION_LEVEL)) == 0 ||
		strncmp(name, PLTSQL_TRANSACTION_ISOLATION_LEVEL, strlen(PLTSQL_TRANSACTION_ISOLATION_LEVEL)) == 0)
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
ownership_structure_enabled(void)
{
	return enable_ownership_structure;
}
