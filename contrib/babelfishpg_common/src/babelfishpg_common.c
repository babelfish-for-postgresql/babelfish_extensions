#include "postgres.h"
#include "catalog/pg_collation.h"
#include "optimizer/pathnode.h"

#include "fmgr.h"
#include "instr.h"
#include "optimizer/planner.h"
#include "parser/parse_collate.h"
#include "parser/parse_target.h"

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

void
_PG_init(void)
{
	FunctionCallInfo fcinfo  = NULL;  /* empty interface */
	collation_callbacks **coll_cb_ptr;
	common_utility_plugin **common_utility_plugin_ptr;

	init_instr();
	init_tcode_trans_tab(fcinfo);

	coll_cb_ptr = (collation_callbacks **) find_rendezvous_variable("collation_callbacks");
	*coll_cb_ptr = get_collation_callbacks();
	common_utility_plugin_ptr = (common_utility_plugin **) find_rendezvous_variable("common_utility_plugin");
	*common_utility_plugin_ptr = get_common_utility_plugin();

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

common_utility_plugin *
get_common_utility_plugin(void)
{
	if(!common_utility_plugin_var.convertVarcharToSQLVariantByteA)
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
		common_utility_plugin_var.is_tsql_varbinary_datatype = &is_tsql_varbinary_datatype;
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
	}
	return &common_utility_plugin_var;
}
