#include "postgres.h"
#include "catalog/pg_collation.h"
#include "commands/typecmds.h"
#include "optimizer/pathnode.h"

#include "fmgr.h"
#include "instr.h"
#include "optimizer/planner.h"
#include "parser/parse_collate.h"
#include "parser/parse_target.h"
#include "parser/scansup.h"		/* downcase_identifier */
#include "utils/guc.h"

#include "babelfishpg_common.h"
#include "collation.h"
#include "datetime.h"
#include "encoding/encoding.h"
#include "sqlvariant.h"
#include "typecode.h"
#include "varchar.h"

common_utility_plugin common_utility_plugin_var = {NULL};
static common_utility_plugin *get_common_utility_plugin(void);
extern Datum init_tcode_trans_tab(PG_FUNCTION_ARGS);

PG_MODULE_MAGIC;

char	   *pltsql_default_locale = NULL;
char	   *pltsql_server_collation_name = NULL;

/* Dump and Restore */
char	   *babelfish_restored_server_collation_name = NULL;

const char *BabelfishTranslateCollation(
										const char *collname,
										Oid collnamespace,
										int32 encoding);

CLUSTER_COLLATION_OID_hook_type prev_CLUSTER_COLLATION_OID_hook = NULL;
TranslateCollation_hook_type prev_TranslateCollation_hook = NULL;
PreCreateCollation_hook_type prev_PreCreateCollation_hook = NULL;

set_like_collation_hook_type prev_set_like_collation_hook = NULL;
get_like_collation_hook_type prev_get_like_collation_hook = NULL;


/* Module callbacks */
void		_PG_init(void);
void		_PG_fini(void);

static bool
check_server_collation_name(char **newval, void **extra, GucSource source)
{
	if (is_valid_server_collation_name(*newval))
	{
		/*
		 * We are storing value in lower case since Collation names are stored
		 * in lowercase into pg catalog (pg_collation).
		 */
		int			length = strlen(*newval);

		strncpy(*newval, downcase_identifier(*newval, length, false, false), length);
		return true;
	}
	return false;
}

static bool
check_default_locale(char **newval, void **extra, GucSource source)
{
	if (find_locale(*newval) >= 0)
		return true;
	return false;
}

static bool
check_restored_server_collation_name(char **newval, void **extra, GucSource source)
{
	/*
	 * NULL should be treated as valid value for
	 * babelfishpg_tsql.restored_server_collation_name
	 */
	if (*newval == NULL)
		return true;

	return check_server_collation_name(newval, extra, source);
}

void
_PG_init(void)
{
	FunctionCallInfo fcinfo = NULL; /* empty interface */
	collation_callbacks **coll_cb_ptr;
	common_utility_plugin **common_utility_plugin_ptr;

	init_instr();
	init_tcode_trans_tab(fcinfo);

	coll_cb_ptr = (collation_callbacks **) find_rendezvous_variable("collation_callbacks");
	*coll_cb_ptr = get_collation_callbacks();
	common_utility_plugin_ptr = (common_utility_plugin **) find_rendezvous_variable("common_utility_plugin");
	*common_utility_plugin_ptr = get_common_utility_plugin();

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
							   PGC_SUSET,	/* only superuser can set */
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

	handle_type_and_collation_hook = handle_type_and_collation;
	avoid_collation_override_hook = check_target_type_is_sys_varchar;
	define_type_default_collation_hook = babelfish_define_type_default_collation;

	prev_CLUSTER_COLLATION_OID_hook = CLUSTER_COLLATION_OID_hook;
	CLUSTER_COLLATION_OID_hook = BABELFISH_CLUSTER_COLLATION_OID;

	prev_TranslateCollation_hook = TranslateCollation_hook;
	TranslateCollation_hook = BabelfishTranslateCollation;

	prev_PreCreateCollation_hook = PreCreateCollation_hook;
	PreCreateCollation_hook = BabelfishPreCreateCollation_hook;

	prev_set_like_collation_hook = set_like_collation_hook;
	set_like_collation_hook = bbf_set_like_collation;
 	prev_get_like_collation_hook = get_like_collation_hook;
	get_like_collation_hook = bbf_get_like_collation;

}
void
_PG_fini(void)
{
	handle_type_and_collation_hook = NULL;
	avoid_collation_override_hook = NULL;
	define_type_default_collation_hook = NULL;
	CLUSTER_COLLATION_OID_hook = prev_CLUSTER_COLLATION_OID_hook;
	TranslateCollation_hook = prev_TranslateCollation_hook;
	PreCreateCollation_hook = prev_PreCreateCollation_hook;
	set_like_collation_hook = prev_set_like_collation_hook;
	get_like_collation_hook = prev_get_like_collation_hook;
}

common_utility_plugin *
get_common_utility_plugin(void)
{
	if (!common_utility_plugin_var.convertVarcharToSQLVariantByteA)
	{
		common_utility_plugin_var.convertVarcharToSQLVariantByteA = &convertVarcharToSQLVariantByteA;
		common_utility_plugin_var.convertIntToSQLVariantByteA = &convertIntToSQLVariantByteA;
		common_utility_plugin_var.tsql_varchar_input = &tsql_varchar_input;
		common_utility_plugin_var.tsql_bpchar_input = &tsql_bpchar_input;
		common_utility_plugin_var.is_tsql_bpchar_datatype = &is_tsql_bpchar_datatype;
		common_utility_plugin_var.is_tsql_nchar_datatype = &is_tsql_nchar_datatype;
		common_utility_plugin_var.is_tsql_varchar_datatype = &is_tsql_varchar_datatype;
		common_utility_plugin_var.is_tsql_nvarchar_datatype = &is_tsql_nvarchar_datatype;
		common_utility_plugin_var.is_tsql_text_datatype = &is_tsql_text_datatype;
		common_utility_plugin_var.is_tsql_ntext_datatype = &is_tsql_ntext_datatype;
		common_utility_plugin_var.is_tsql_image_datatype = &is_tsql_image_datatype;
		common_utility_plugin_var.is_tsql_binary_datatype = &is_tsql_binary_datatype;
		common_utility_plugin_var.is_tsql_sys_binary_datatype = &is_tsql_sys_binary_datatype;
		common_utility_plugin_var.is_tsql_varbinary_datatype = &is_tsql_varbinary_datatype;
		common_utility_plugin_var.is_tsql_sys_varbinary_datatype = &is_tsql_sys_varbinary_datatype;
		common_utility_plugin_var.is_tsql_timestamp_datatype = &is_tsql_timestamp_datatype;
		common_utility_plugin_var.is_tsql_datetime2_datatype = &is_tsql_datetime2_datatype;
		common_utility_plugin_var.is_tsql_smalldatetime_datatype = &is_tsql_smalldatetime_datatype;
		common_utility_plugin_var.is_tsql_datetimeoffset_datatype = &is_tsql_datetimeoffset_datatype;
		common_utility_plugin_var.is_tsql_decimal_datatype = &is_tsql_decimal_datatype;
		common_utility_plugin_var.is_tsql_rowversion_or_timestamp_datatype = &is_tsql_rowversion_or_timestamp_datatype;
		common_utility_plugin_var.datetime_in_str = &datetime_in_str;
		common_utility_plugin_var.datetime2sqlvariant = &datetime2sqlvariant;
		common_utility_plugin_var.tinyint2sqlvariant = &tinyint2sqlvariant;
		common_utility_plugin_var.translate_pg_type_to_tsql = &translate_pg_type_to_tsql;
		common_utility_plugin_var.TdsGetPGbaseType = &TdsGetPGbaseType;
		common_utility_plugin_var.TdsSetMetaData = &TdsSetMetaData;
		common_utility_plugin_var.TdsPGbaseType = &TdsPGbaseType;
		common_utility_plugin_var.TdsGetMetaData = &TdsGetMetaData;
		common_utility_plugin_var.TdsGetVariantBaseType = &TdsGetVariantBaseType;
		common_utility_plugin_var.lookup_tsql_datatype_oid = &lookup_tsql_datatype_oid;
		common_utility_plugin_var.GetUTF8CodePoint = &GetUTF8CodePoint;
	}
	return &common_utility_plugin_var;
}
