#include "postgres.h"
#include "catalog/pg_collation.h"
#include "optimizer/pathnode.h"

#include "fmgr.h"
#include "instr.h"
#include "optimizer/planner.h"
#include "parser/parse_collate.h"
#include "parser/parse_target.h"
#include "parser/scansup.h"  /* downcase_identifier */
#include "utils/guc.h"

#include "collation.h"
#include "encoding/encoding.h"
#include "typecode.h"

extern Datum init_tcode_trans_tab(PG_FUNCTION_ARGS);

PG_MODULE_MAGIC;

char *pltsql_default_locale = NULL;
char *pltsql_server_collation_name = NULL;

/* Dump and Restore */
char *babelfish_restored_server_collation_name = NULL;
char *babelfish_restored_default_locale = NULL;

const char *
BabelfishTranslateCollation(
	const char *collname, 
	Oid collnamespace, 
	int32 encoding);

CLUSTER_COLLATION_OID_hook_type prev_CLUSTER_COLLATION_OID_hook = NULL;
TranslateCollation_hook_type prev_TranslateCollation_hook = NULL;
PreCreateCollation_hook_type prev_PreCreateCollation_hook = NULL;

/* Module callbacks */
void	_PG_init(void);
void	_PG_fini(void);

static bool check_server_collation_name(char **newval, void **extra, GucSource source)
{
	if (is_valid_server_collation_name(*newval))
	{
		/*
		 * We are storing value in lower case since
		 * Collation names are stored in lowercase into pg catalog (pg_collation).
		 */
		int length = strlen(*newval);
		strncpy(*newval, downcase_identifier(*newval, length, false, false), length);
		return true;
	}
	return false;
}

static bool check_default_locale (char **newval, void **extra, GucSource source)
{
	if (find_locale(*newval) >= 0)
		return true;
	return false;
}

static bool check_restored_server_collation_name(char **newval, void **extra, GucSource source)
{
	/* NULL should be treated as valid value for babelfishpg_tsql.restored_server_collation_name */
	if (*newval == NULL)
		return true;

	return check_server_collation_name(newval, extra, source);
}

static bool check_restored_default_locale (char **newval, void **extra, GucSource source)
{
	/* NULL should be treated as valid value for babelfishpg_tsql.restored_default_locale */
	if (*newval == NULL)
		return true;

	return check_default_locale(newval, extra, source);
}

void
_PG_init(void)
{
	FunctionCallInfo fcinfo  = NULL;  /* empty interface */
	collation_callbacks **coll_cb_ptr;

	init_instr();
	init_tcode_trans_tab(fcinfo);

	coll_cb_ptr = (collation_callbacks **) find_rendezvous_variable("collation_callbacks");
	*coll_cb_ptr = get_collation_callbacks();

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

	DefineCustomStringVariable("babelfishpg_tsql.restored_server_collation_name",
				gettext_noop("To persist the user defined setting of babelfishpg_tsql.server_collation_name GUC"),
				NULL,
				&babelfish_restored_server_collation_name,
				NULL,
				PGC_USERSET,
				GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				check_restored_server_collation_name, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.restored_default_locale",
				gettext_noop("To persist the user defined setting of babelfishpg_tsql.default_locale GUC"),
				NULL,
				&babelfish_restored_default_locale,
				NULL,
				PGC_USERSET,
				GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
				check_restored_default_locale, NULL, NULL);

	handle_type_and_collation_hook = handle_type_and_collation;
	avoid_collation_override_hook = check_target_type_is_sys_varchar;

	prev_CLUSTER_COLLATION_OID_hook = CLUSTER_COLLATION_OID_hook;
	CLUSTER_COLLATION_OID_hook = BABELFISH_CLUSTER_COLLATION_OID;

	prev_TranslateCollation_hook = TranslateCollation_hook;
	TranslateCollation_hook = BabelfishTranslateCollation;

	prev_PreCreateCollation_hook = PreCreateCollation_hook;
	PreCreateCollation_hook = BabelfishPreCreateCollation_hook;
}
void
_PG_fini(void)
{
	handle_type_and_collation_hook = NULL;
	avoid_collation_override_hook = NULL;
	CLUSTER_COLLATION_OID_hook = prev_CLUSTER_COLLATION_OID_hook;
	TranslateCollation_hook = prev_TranslateCollation_hook;
	PreCreateCollation_hook = prev_PreCreateCollation_hook;
}
