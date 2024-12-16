/*-------------------------------------------------------------------------
 *
 * pltsql_coerce.c
 *   Datatype Coercion Utility for Babel
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/htup_details.h"
#include "access/genam.h"
#include "access/table.h"
#include "access/parallel.h"	/* InitializingParallelWorker */
#include "miscadmin.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_cast.h"
#include "catalog/pg_type.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_namespace.h"
#include "collation.h"
#include "executor/spi.h"
#include "mb/pg_wchar.h"
#include "nodes/makefuncs.h"
#include "parser/parse_coerce.h"
#include "parser/parse_func.h"
#include "parser/parse_type.h"
#include "parser/parse_expr.h"
#include "src/collation.h"
#include "utils/builtins.h"
#include "utils/float.h"
#include "utils/guc.h"
#include "utils/fmgroids.h"
#include "common/int.h"
#include "utils/numeric.h"
#include "utils/memutils.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "pltsql_instr.h"
#include "parser/parse_target.h"


#include <math.h>
#include "pltsql.h"

/* 
 * This macro is to define typmod of sysname to 128 beacause
 * sysname is created as CREATE DOMAIN sys.SYSNAME AS sys.VARCHAR(128);
 */
#define SYSNAME_TYPMOD 128
#define NCHAR_MAX_TYPMOD 4000
#define BPCHAR_MAX_TYPMOD 8000

/* Hooks for engine*/
extern find_coercion_pathway_hook_type find_coercion_pathway_hook;
extern determine_datatype_precedence_hook_type determine_datatype_precedence_hook;
extern func_select_candidate_hook_type func_select_candidate_hook;
extern coerce_string_literal_hook_type coerce_string_literal_hook;
extern select_common_type_hook_type select_common_type_hook;
extern select_common_typmod_hook_type select_common_typmod_hook;
extern handle_constant_literals_hook_type handle_constant_literals_hook;
extern set_common_typmod_case_expr_hook_type set_common_typmod_case_expr_hook;

extern bool babelfish_dump_restore;

PG_FUNCTION_INFO_V1(init_tsql_coerce_hash_tab);
PG_FUNCTION_INFO_V1(init_tsql_datatype_precedence_hash_tab);
PG_FUNCTION_INFO_V1(get_immediate_base_type_of_UDT);

static Oid select_common_type_setop(ParseState *pstate, List *exprs, Node **which_expr, const char *context);
static Oid select_common_type_for_isnull(ParseState *pstate, List *exprs);
static Oid select_common_type_for_coalesce_function(ParseState *pstate, List *exprs);
static Oid get_immediate_base_type_of_UDT_internal(Oid typeid);

/* Memory Context */
static MemoryContext pltsql_coercion_context = NULL;

typedef enum
{
	PG_CAST_ENTRY, TSQL_CAST_ENTRY, TSQL_CAST_WITHOUT_FUNC_ENTRY
} cast_type;

typedef struct tsql_cast_raw_info
{
	cast_type	casttype;
	const char *srcnsp;
	const char *srctypname;
	const char *tarnsp;
	const char *tartypname;
	const char *castfunc;
	char		castcontext;
	char		castmethod;
} tsql_cast_raw_info_t;

tsql_cast_raw_info_t tsql_cast_raw_infos[] =
{
	{PG_CAST_ENTRY, "pg_catalog", "float8", "pg_catalog", "float4", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "float8", "pg_catalog", "numeric", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "float8", "sys", "fixeddecimal", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "float8", "pg_catalog", "int8", "dtrunci8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "float8", "pg_catalog", "int4", "dtrunci4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "float8", "pg_catalog", "int2", "dtrunci2", 'i', 'f'},
/*  float4 */
	{PG_CAST_ENTRY, "pg_catalog", "float4", "pg_catalog", "numeric", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "float4", "sys", "fixeddecimal", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "float4", "pg_catalog", "int8", "ftrunci8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "float4", "pg_catalog", "int4", "ftrunci4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "float4", "pg_catalog", "int2", "ftrunci2", 'i', 'f'},
/*  numeric */
	{TSQL_CAST_ENTRY, "pg_catalog", "numeric", "pg_catalog", "int8", "_trunc_numeric_to_int8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "numeric", "pg_catalog", "int4", "_trunc_numeric_to_int4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "numeric", "pg_catalog", "int2", "_trunc_numeric_to_int2", 'i', 'f'},
	/* {"sys", "fixeddecimal", "pg_catalog", "int8", 'i'}, */
	{TSQL_CAST_ENTRY, "sys", "fixeddecimal", "pg_catalog", "int8", "_round_fixeddecimal_to_int8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "fixeddecimal", "pg_catalog", "int4", "_round_fixeddecimal_to_int4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "fixeddecimal", "pg_catalog", "int2", "_round_fixeddecimal_to_int2", 'i', 'f'},
/*  bit */
	{PG_CAST_ENTRY, "pg_catalog", "int2", "sys", "bit", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "int4", "sys", "bit", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "int8", "sys", "bit", NULL, 'i', 'f'},
/*  int8 */
	{PG_CAST_ENTRY, "pg_catalog", "int8", "pg_catalog", "int4", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "int8", "pg_catalog", "int2", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "int8", "sys", "money", "int8_to_money", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "int8", "sys", "smallmoney", "int8_to_smallmoney", 'i', 'f'},
/*  int4 */
	{PG_CAST_ENTRY, "pg_catalog", "int4", "pg_catalog", "int2", NULL, 'i', 'f'},
/*  varbinary     {only allow to cast to integral data type) */
	{PG_CAST_ENTRY, "sys", "bbf_varbinary", "pg_catalog", "int8", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bbf_varbinary", "pg_catalog", "int4", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bbf_varbinary", "pg_catalog", "int2", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bbf_varbinary", "sys", "rowversion", "varbinaryrowversion", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bbf_varbinary", "sys", "bbf_binary", "varbinarybinary", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bbf_varbinary", "sys", "nvarchar", "varbinarysysnvarchar", 'i', 'f'},
/*  binary     {only allow to cast to integral data type) */
	{PG_CAST_ENTRY, "sys", "bbf_binary", "pg_catalog", "int8", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bbf_binary", "pg_catalog", "int4", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bbf_binary", "pg_catalog", "int2", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bbf_binary", "sys", "rowversion", "binaryrowversion", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bbf_binary", "sys", "nvarchar", "binarysysnvarchar", 'i', 'f'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bbf_binary", "sys", "bbf_varbinary", NULL, 'i', 'b'},
/*  rowversion */
	{PG_CAST_ENTRY, "sys", "rowversion", "pg_catalog", "int8", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "rowversion", "pg_catalog", "int4", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "rowversion", "pg_catalog", "int2", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "xid8", "sys", "rowversion", "xid8rowversion", 'i', 'f'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "rowversion", "sys", "bbf_varbinary", NULL, 'i', 'b'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "rowversion", "sys", "bbf_binary", NULL, 'i', 'b'},
/*  characters */
	{TSQL_CAST_ENTRY, "pg_catalog", "text", "sys", "fixeddecimal", "char_to_fixeddecimal", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "bpchar", "sys", "fixeddecimal", "char_to_fixeddecimal", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bpchar", "sys", "fixeddecimal", "char_to_fixeddecimal", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "varchar", "sys", "fixeddecimal", "char_to_fixeddecimal", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "varchar", "sys", "fixeddecimal", "char_to_fixeddecimal", 'i', 'f'},
/*  smalldatetime */
	{PG_CAST_ENTRY, "pg_catalog", "date", "sys", "smalldatetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "time", "sys", "smalldatetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "smalldatetime", "sys", "datetime", NULL, 'i', 'b'},
	{PG_CAST_ENTRY, "sys", "smalldatetime", "sys", "datetime2", NULL, 'i', 'b'},
	{PG_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "varchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "smalldatetime", "sys", "varchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "bpchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "varchar", "sys", "smalldatetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "varchar", "sys", "smalldatetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "bpchar", "sys", "smalldatetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bpchar", "sys", "smalldatetime", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "sys", "bit", "smalldatetime_to_bit", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "int2", "smalldatetime_to_int2", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "int4", "smalldatetime_to_int4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "int8", "smalldatetime_to_int8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "float4", "smalldatetime_to_float4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "float8", "smalldatetime_to_float8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "pg_catalog", "numeric", "smalldatetime_to_numeric", 'i', 'f'},
/*  datetime */
	{PG_CAST_ENTRY, "sys", "datetime", "pg_catalog", "date", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime", "pg_catalog", "time", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime", "sys", "smalldatetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime", "pg_catalog", "varchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime", "sys", "varchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime", "pg_catalog", "bpchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "varchar", "sys", "datetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "varchar", "sys", "datetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "bpchar", "sys", "datetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bpchar", "sys", "datetime", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "sys", "bit", "datetime_to_bit", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "pg_catalog", "int2", "datetime_to_int2", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "pg_catalog", "int4", "datetime_to_int4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "pg_catalog", "int8", "datetime_to_int8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "pg_catalog", "float4", "datetime_to_float4", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "pg_catalog", "float8", "datetime_to_float8", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "pg_catalog", "numeric", "datetime_to_numeric", 'i', 'f'},
/*  datetime2 */
	{PG_CAST_ENTRY, "sys", "datetime2", "pg_catalog", "date", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime2", "pg_catalog", "time", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime2", "sys", "smalldatetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime2", "sys", "datetime", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime2", "pg_catalog", "varchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime2", "sys", "varchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "datetime2", "pg_catalog", "bpchar", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "varchar", "sys", "datetime2", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "varchar", "sys", "datetime2", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "pg_catalog", "bpchar", "sys", "datetime2", NULL, 'i', 'f'},
/*  datetimeoffset */
	{TSQL_CAST_ENTRY, "sys", "datetimeoffset", "pg_catalog", "time", "datetimeoffset2time", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetimeoffset", "pg_catalog", "date", "datetimeoffset2date", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetimeoffset", "sys", "datetime", "datetimeoffset2datetime", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetimeoffset", "sys", "datetime2", "datetimeoffset2datetime2", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetimeoffset", "sys", "smalldatetime", "datetimeoffset2smalldatetime", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "time", "sys", "datetimeoffset", "time2datetimeoffset", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "date", "sys", "datetimeoffset", "date2datetimeoffset", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime", "sys", "datetimeoffset", "datetime2datetimeoffset", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "datetime2", "sys", "datetimeoffset", "datetime22datetimeoffset", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smalldatetime", "sys", "datetimeoffset", "smalldatetime2datetimeoffset", 'i', 'f'},
/*  uniqueidentifier */
	{PG_CAST_ENTRY, "sys", "bbf_binary", "sys", "uniqueidentifier", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bbf_varbinary", "sys", "uniqueidentifier", NULL, 'i', 'f'},
/*  sql_variant */
/*  when casting to sql variant, we need to store type information which will be lost for some of pg's domain casts */
/*  so we need to manually add them here to go through tsql's casting sysem */
	{TSQL_CAST_ENTRY, "sys", "money", "sys", "sql_variant", "money_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smallmoney", "sys", "sql_variant", "smallmoney_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "smallint", "sys", "sql_variant", "smallint_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "tinyint", "sys", "sql_variant", "tinyint_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "varchar", "sys", "sql_variant", "varchar_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "varchar", "sys", "sql_variant", "varchar_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "nvarchar", "sys", "sql_variant", "nvarchar_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "bpchar", "sys", "sql_variant", "char_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bpchar", "sys", "sql_variant", "char_sqlvariant", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "nchar", "sys", "sql_variant", "nchar_sqlvariant", 'i', 'f'},
/*  name     {special overriding to handle identifier truncation) */
	{TSQL_CAST_ENTRY, "pg_catalog", "text", "pg_catalog", "name", "text_to_name", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "bpchar", "pg_catalog", "name", "bpchar_to_name", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bpchar", "pg_catalog", "name", "bpchar_to_name", 'i', 'f'},
	{TSQL_CAST_ENTRY, "pg_catalog", "varchar", "pg_catalog", "name", "varchar_to_name", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "varchar", "pg_catalog", "name", "varchar_to_name", 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "nvarchar", "sys", "bbf_varbinary", "nvarcharvarbinary", 'a', 'f'},
	{TSQL_CAST_ENTRY, "sys", "nvarchar", "sys", "bbf_binary", "nvarcharbinary", 'a', 'f'},
/*  string -> float8 via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "text", "pg_catalog", "float8", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bpchar", "pg_catalog", "float8", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "varchar", "pg_catalog", "float8", NULL, 'i', 'i'},
/*  string -> float4 via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "text", "pg_catalog", "float4", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bpchar", "pg_catalog", "float4", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "varchar", "pg_catalog", "float4", NULL, 'i', 'i'},
/*  string -> int2 via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "text", "pg_catalog", "int2", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bpchar", "pg_catalog", "int2", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "varchar", "pg_catalog", "int2", NULL, 'i', 'i'},
/*  string -> int4 via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "text", "pg_catalog", "int4", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bpchar", "pg_catalog", "int4", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "varchar", "pg_catalog", "int4", NULL, 'i', 'i'},
/*  string -> int8 via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "text", "pg_catalog", "int8", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bpchar", "pg_catalog", "int8", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "varchar", "pg_catalog", "int8", NULL, 'i', 'i'},
/*  string -> numeric via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "text", "pg_catalog", "numeric", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bpchar", "pg_catalog", "numeric", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bpchar", "pg_catalog", "numeric", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "varchar", "pg_catalog", "numeric", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "varchar", "pg_catalog", "numeric", NULL, 'i', 'i'},
/*  string -> uniqueidentifier via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "text", "sys", "uniqueidentifier", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bpchar", "sys", "uniqueidentifier", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bpchar", "sys", "uniqueidentifier", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "varchar", "sys", "uniqueidentifier", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "varchar", "sys", "uniqueidentifier", NULL, 'i', 'i'},
/*  int2 -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int2", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int2", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int2", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int2", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int2", "sys", "varchar", NULL, 'i', 'i'},
/*  int4 -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int4", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int4", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int4", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int4", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int4", "sys", "varchar", NULL, 'i', 'i'},
/*  int8 -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int8", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int8", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int8", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int8", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "int8", "sys", "varchar", NULL, 'i', 'i'},
/*  float4 -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float4", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float4", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float4", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float4", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float4", "sys", "varchar", NULL, 'i', 'i'},
/*  float8 -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float8", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float8", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float8", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float8", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "float8", "sys", "varchar", NULL, 'i', 'i'},
/*  numeric -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "numeric", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "numeric", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "numeric", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "numeric", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "numeric", "sys", "varchar", NULL, 'i', 'i'},
/*  // fixeddecimal -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "fixeddecimal", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "fixeddecimal", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "fixeddecimal", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "fixeddecimal", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "fixeddecimal", "sys", "varchar", NULL, 'i', 'i'},
/*  fixeddecimal -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "uniqueidentifier", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "uniqueidentifier", "pg_catalog", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "uniqueidentifier", "sys", "bpchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "uniqueidentifier", "pg_catalog", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "uniqueidentifier", "sys", "varchar", NULL, 'i', 'i'},
/*  bit -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bit", "sys", "varchar", NULL, 'i', 'i'},
/*  oid -> int4 */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "oid", "pg_catalog", "int4", NULL, 'i', 'b'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "oid", "pg_catalog", "text", NULL, 'i', 'i'},
/*  text */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "rowversion", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "timestamp", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "timestamptz", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "varbinary", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bbf_varbinary", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "sql_variant", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "date", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "datetime", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "datetime2", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "smalldatetime", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bit", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "binary", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bbf_binary", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "bytea", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "datetimeoffset", "pg_catalog", "text", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "time", "pg_catalog", "text", NULL, 'i', 'i'},
/*  date/time -> string via I/O */
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "time", "sys", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "pg_catalog", "date", "sys", "varchar", NULL, 'i', 'i'},
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "datetimeoffset", "sys", "varchar", NULL, 'i', 'i'},
};

#define TOTAL_TSQL_CAST_COUNT (sizeof(tsql_cast_raw_infos)/sizeof(tsql_cast_raw_infos[0]))

typedef struct tsql_precedence_info
{
	int			precedence;
	const char *nsp;
	const char *typname;
} tsql_precedence_info_t;

tsql_precedence_info_t tsql_precedence_infos[] =
{
	{0, "sys", "sql_variant"},
	{1, "sys", "datetimeoffset"},
	{2, "sys", "datetime2"},
	{3, "sys", "datetime"},
	{4, "sys", "smalldatetime"},
	{5, "pg_catalog", "date"},
	{6, "pg_catalog", "time"},
	{7, "pg_catalog", "float8"},
	{8, "pg_catalog", "float4"},
	{9, "pg_catalog", "numeric"},
	{10, "sys", "fixeddecimal"},
	{11, "sys", "money"},
	{12, "sys", "smallmoney"},
	{13, "pg_catalog", "int8"},
	{14, "pg_catalog", "int4"},
	{15, "pg_catalog", "int2"},
	{16, "sys", "tinyint"},
	{17, "sys", "bit"},
	{18, "sys", "ntext"},
	{19, "pg_catalog", "text"},
	{20, "sys", "image"},
	{21, "sys", "timestamp"},
	{22, "sys", "uniqueidentifier"},
	{23, "sys", "nvarchar"},
	{24, "sys", "nchar"},
	{25, "sys", "varchar"},
	{26, "pg_catalog", "varchar"},
	{27, "pg_catalog", "char"},
	{28, "sys", "bpchar"},
	{29, "pg_catalog", "bpchar"},
	{30, "pg_catalog", "name"}, /* pg_catalog.name is depriotized than any
								 * other string datatype not to be looked up
								 * unless requested explicitly */
	{31, "sys", "bbf_varbinary"},
	{32, "sys", "varbinary"},
	{33, "sys", "bbf_binary"},
	{34, "sys", "binary"},
	{35, "pg_catalog", "bytea"} /* pg_catalog.bytea is depriotized than any
								 * other binary datatype not to be looked up
								 * unless requested explicitly */
};

#define TOTAL_TSQL_PRECEDENCE_COUNT (sizeof(tsql_precedence_infos)/sizeof(tsql_precedence_infos[0]))

/* struct to store details of special function */
typedef struct tsql_special_function
{
	const char             *nsp;                              /* namespace of special function */
	const char             *funcname;                         /* name of special function */
	const char             *formatted_funcname;               /* formatted name of special function */
	bool                    is_variadic;                      /* need to handle variadic functions differently */
	int                     nargs;                            /* number of arguments of special function (for variadic function number of fixed arguments will be stored) */
} tsql_special_function_t;

tsql_special_function_t tsql_special_function_list[] = 
{
	{"sys", "replace", "replace", false, 3},
	{"sys", "string_agg", "string_agg", false, 2},
	{"sys", "substring", "substring", false, 3},
	{"sys", "stuff", "stuff", false, 4},
	{"sys", "translate", "translate", false, 3},
	{"sys", "trim", "Trim", false, 1},
	{"sys", "trim", "Trim", false, 2},
	{"sys", "ltrim", "ltrim", false, 1},
	{"sys", "rtrim", "rtrim", false, 1},
	{"sys", "left", "left", false, 2},
	{"sys", "right", "right", false, 2},
	{"sys", "replicate", "replicate", false, 2},
	{"sys", "reverse", "reverse", false, 1},
	{"sys", "lower", "lower", false, 1},
	{"sys", "upper", "upper", false, 1},
	{"sys", "concat", "concat", true, 0},
	{"sys", "concat_ws", "concat_ws", true, 1}
};

#define TOTAL_TSQL_SPECIAL_FUNCTION_COUNT (sizeof(tsql_special_function_list)/sizeof(tsql_special_function_list[0]))

/* T-SQL Cast */
typedef struct tsql_cast_info_key
{
	Oid			castsource;
	Oid			casttarget;
} tsql_cast_info_key_t;

typedef struct tsql_cast_info_entry
{
	Oid			castsource;
	Oid			casttarget;
	Oid			castfunc;
	char		castcontext;
	char		castmethod;
} tsql_cast_info_entry_t;

static tsql_cast_info_key_t *tsql_cast_info_keys = NULL;
static tsql_cast_info_entry_t *tsql_cast_info_entries = NULL;
static HTAB *ht_tsql_cast_info = NULL;
bool		inited_ht_tsql_cast_info = false;

/* Returns true if the oid belongs to binary, bbf_binary, varbinary, bbf_varbinary datatype */
static bool
is_tsql_binary_family_datatype(Oid oid)
{
	if((*common_utility_plugin_ptr->is_tsql_binary_datatype)(oid) || (*common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype)(oid)
	|| (*common_utility_plugin_ptr->is_tsql_sys_binary_datatype)(oid) || (*common_utility_plugin_ptr->is_tsql_varbinary_datatype)(oid))
	{
		return true;
	}
	return false;
}

static CoercionPathType
tsql_find_coercion_pathway(Oid sourceTypeId, Oid targetTypeId, CoercionContext ccontext, Oid *funcid)
{
	tsql_cast_info_key_t key;
	tsql_cast_info_entry_t *entry;
	CoercionContext castcontext;
	CoercionPathType result = COERCION_PATH_NONE;

	/* check if any of source/target type is sql variant */
	HeapTuple	tuple;
	bool		isSqlVariantCast = false;
	bool		isInt8Type = false;
	bool		isInt8ToMoney = false;
	bool		isVarbinaryToNvarchar = false;
	bool		isNvarchartoVarbinary = false;

	Oid			typeIds[2] = {sourceTypeId, targetTypeId};
	Oid			UDT_sourceBaseType = InvalidOid;
	Oid			UDT_targetBaseType = InvalidOid;

	for (int i = 0; i < 2; i++)
	{
		tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(typeIds[i]));
		if (HeapTupleIsValid(tuple))
		{
			Form_pg_type typtup = (Form_pg_type) GETSTRUCT(tuple);
			Oid			type_nsoid;
			char	   *type_name;
			char	   *type_nsname;

			type_nsoid = typtup->typnamespace;
			type_nsname = get_namespace_name(type_nsoid);
			type_name = NameStr(typtup->typname);

			/* We've found INT8 to MONEY casting */
			if (isInt8Type && strcmp(type_nsname, "sys") == 0 && ((strcmp(type_name, "money") == 0) || (strcmp(type_name, "smallmoney") == 0)))
				isInt8ToMoney = true;

			/* Check if type is INT8 */
			if (strcmp(type_nsname, "pg_catalog") == 0 && strcmp(type_name, "int8") == 0)
				isInt8Type = true;

			/* We've found a SQL Variant Casting */
			if (strcmp(type_nsname, "sys") == 0 && strcmp(type_name, "sql_variant") == 0)
			{
				isSqlVariantCast = true;
				ReleaseSysCache(tuple);
				break;
			}
			if( i == 0 && strcmp(type_nsname, "sys") != 0 && strcmp(type_nsname, "pg_catalog") != 0)
			{
				UDT_sourceBaseType = get_immediate_base_type_of_UDT_internal(sourceTypeId);
			}

			if(i == 1 && strcmp(type_nsname, "sys") != 0 && strcmp(type_nsname, "pg_catalog") != 0)
			{
				UDT_targetBaseType = get_immediate_base_type_of_UDT_internal(targetTypeId);
			}


			ReleaseSysCache(tuple);
		}
	}

	/* Check if the UDT's base type is nvarchar or varbinary.
	 * If so, use the immediate base type for further processing.
	 */
	if(UDT_sourceBaseType != InvalidOid && ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(UDT_sourceBaseType) || is_tsql_binary_family_datatype(UDT_sourceBaseType)))
	{
		typeIds[0] = UDT_sourceBaseType;
		sourceTypeId = UDT_sourceBaseType;
	}

	if(UDT_targetBaseType != InvalidOid && ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(UDT_targetBaseType) || is_tsql_binary_family_datatype(UDT_targetBaseType)))
	{
		typeIds[1] = UDT_targetBaseType;
		targetTypeId = UDT_targetBaseType;
	}

	/* We've found VARBINARY To NVARCHAR casting */
	if (is_tsql_binary_family_datatype(typeIds[0]) && (*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(typeIds[1]))
		isVarbinaryToNvarchar = true;

	/* We've found NVARCHAR TO (bbf)(VAR)BINARY casting */
	if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(typeIds[0]) && is_tsql_binary_family_datatype(typeIds[1]))
		isNvarchartoVarbinary = true;

	/* Perhaps the types are domains; if so, look at their base types */
	if (!isSqlVariantCast)
	{
		/*
		 * if we are casting from NVARCHAR TO VARBINARY, don't look for base type of
		 * source so that it can call the cast function which matches with the
		 * exact types
		 */
		if (OidIsValid(sourceTypeId) && !isNvarchartoVarbinary)
			sourceTypeId = getBaseType(sourceTypeId);

		/*
		 * if we are casting from INT8 to MONEY or VARBINARY To NVARCHAR, don't look for base type of
		 * target so that it can call the cast function which matches with the
		 * exact types
		 */
		if (OidIsValid(targetTypeId) && !isInt8ToMoney && !isVarbinaryToNvarchar)
			targetTypeId = getBaseType(targetTypeId);
	}

	key.castsource = sourceTypeId;
	key.casttarget = targetTypeId;

	/* Initialise T-SQL coercion hash table if not already done */
	if (!inited_ht_tsql_cast_info)
	{
		FunctionCallInfo fcinfo = NULL; /* empty interface */

		init_tsql_coerce_hash_tab(fcinfo);
	}

	entry = (tsql_cast_info_entry_t *) hash_search(ht_tsql_cast_info, &key, HASH_FIND, NULL);
	if (entry == NULL)
		return COERCION_PATH_NONE;

	switch (entry->castcontext)
	{
		case COERCION_CODE_IMPLICIT:
			castcontext = COERCION_IMPLICIT;
			break;
		case COERCION_CODE_ASSIGNMENT:
			castcontext = COERCION_ASSIGNMENT;
			break;
		case COERCION_CODE_EXPLICIT:
			castcontext = COERCION_EXPLICIT;
			break;
		default:
			elog(ERROR, "unrecognized castcontext: %d",
				 (int) entry->castcontext);
			castcontext = 0;	/* keep compiler quiet */
			break;
	}

	/* Rely on ordering of enum for correct behavior here */
	if (ccontext >= castcontext)
	{
		switch (entry->castmethod)
		{
			case COERCION_METHOD_FUNCTION:
				result = COERCION_PATH_FUNC;

				*funcid = entry->castfunc;
				break;
			case COERCION_METHOD_INOUT:
				result = COERCION_PATH_COERCEVIAIO;

				break;
			case COERCION_METHOD_BINARY:
				result = COERCION_PATH_RELABELTYPE;

				break;
			default:
				elog(ERROR, "unrecognized castmethod: %d",
					 (int) entry->castmethod);
				break;
		}
	}

	return result;
}

Datum
init_tsql_coerce_hash_tab(PG_FUNCTION_ARGS)
{
	HASHCTL		hashCtl;
	MemoryContext oldContext;
	void	   *value;
	tsql_cast_info_key_t *key;
	tsql_cast_info_entry_t *entry;
	Oid			sys_nspoid = get_namespace_oid("sys", true);
	Oid		   *argTypes;

	TSQLInstrumentation(INSTR_TSQL_INIT_TSQL_COERCE_HASH_TAB);

	/* Register Hooks */
	find_coercion_pathway_hook = tsql_find_coercion_pathway;

	if (!OidIsValid(sys_nspoid))
		PG_RETURN_INT32(0);


	if (pltsql_coercion_context == NULL)	/* initialize memory context */
	{
		pltsql_coercion_context = AllocSetContextCreateInternal(NULL,
																"PLTSQL CoercionMemory Context",
																ALLOCSET_DEFAULT_SIZES);
	}

	/* create internal table */
	oldContext = MemoryContextSwitchTo(pltsql_coercion_context);
	if (tsql_cast_info_keys == NULL)
		tsql_cast_info_keys = palloc0(sizeof(tsql_cast_info_key_t) * (TOTAL_TSQL_CAST_COUNT));
	if (tsql_cast_info_entries == NULL)
		tsql_cast_info_entries = palloc0(sizeof(tsql_cast_info_entry_t) * (TOTAL_TSQL_CAST_COUNT));
	MemoryContextSwitchTo(oldContext);

	/* create hash table */
	if (ht_tsql_cast_info == NULL)
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(tsql_cast_info_key_t);
		hashCtl.entrysize = sizeof(tsql_cast_info_entry_t);
		hashCtl.hcxt = pltsql_coercion_context;
		ht_tsql_cast_info = hash_create("T-SQL cast",
										SPI_processed,
										&hashCtl,
										HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	/* mark the hash table initialised */
	inited_ht_tsql_cast_info = true;

	/*
	 * Below array will be used to provide argument types to buildoidvector
	 * function. A cast function can have 3 arguments: source datatype, typmod
	 * (int4) and cast context (bool), so we prepare the array here with last
	 * two values prefilled and source datatype oid will be filled when
	 * required.
	 */
	argTypes = (Oid *) palloc(3 * sizeof(Oid));
	argTypes[1] = INT4OID;
	argTypes[2] = BOOLOID;

	for (int i = 0; i < TOTAL_TSQL_CAST_COUNT; i++)
	{
		Oid			castsource;
		Oid			casttarget;
		Oid			srcnspoid;
		Oid			tarnspoid;

		key = &(tsql_cast_info_keys[i]);
		entry = &(tsql_cast_info_entries[i]);
		srcnspoid = strcmp(tsql_cast_raw_infos[i].srcnsp, "sys") == 0 ? sys_nspoid : PG_CATALOG_NAMESPACE;
		castsource = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
									 CStringGetDatum(tsql_cast_raw_infos[i].srctypname), ObjectIdGetDatum(srcnspoid));
		tarnspoid = strcmp(tsql_cast_raw_infos[i].tarnsp, "sys") == 0 ? sys_nspoid : PG_CATALOG_NAMESPACE;
		casttarget = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
									 CStringGetDatum(tsql_cast_raw_infos[i].tartypname), ObjectIdGetDatum(tarnspoid));

		if (OidIsValid(casttarget) && OidIsValid(castsource))
		{
			HeapTuple	tuple;
			Form_pg_cast castForm;

			key->casttarget = casttarget;
			entry->casttarget = casttarget;
			key->castsource = castsource;
			entry->castsource = castsource;

			switch (tsql_cast_raw_infos[i].casttype)
			{
				case PG_CAST_ENTRY:
					tuple = SearchSysCache2(CASTSOURCETARGET,
											ObjectIdGetDatum(castsource),
											ObjectIdGetDatum(casttarget));
					if (HeapTupleIsValid(tuple))
					{
						castForm = (Form_pg_cast) GETSTRUCT(tuple);
						entry->castfunc = castForm->castfunc;
						ReleaseSysCache(tuple);
					}
					else
					{
						/* function is not loaded. wait for next scan */
						inited_ht_tsql_cast_info = false;
						continue;
					}
					break;
				case TSQL_CAST_ENTRY:
					entry->castfunc = GetSysCacheOid3(PROCNAMEARGSNSP, Anum_pg_proc_oid,
													  CStringGetDatum(tsql_cast_raw_infos[i].castfunc),
													  PointerGetDatum(buildoidvector(&castsource, 1)),
													  ObjectIdGetDatum(sys_nspoid));
					if (!OidIsValid(entry->castfunc))
					{
						/* also search cast function with 3 input arguments */
						argTypes[0] = castsource;
						entry->castfunc = GetSysCacheOid3(PROCNAMEARGSNSP, Anum_pg_proc_oid,
														  CStringGetDatum(tsql_cast_raw_infos[i].castfunc),
														  PointerGetDatum(buildoidvector(argTypes, 3)),
														  ObjectIdGetDatum(sys_nspoid));

						if (!OidIsValid(entry->castfunc))
						{
							/*
							 * varbinary to binary implicit type cast without function should be allowed during MVU
							 * since the cast function might not exists when source version is before 14_11 and 15_6
							 */ 
							if (babelfish_dump_restore && ((*common_utility_plugin_ptr->is_tsql_varbinary_datatype) (castsource) 
								&& (*common_utility_plugin_ptr->is_tsql_binary_datatype) (casttarget)))
							{
								entry->castfunc = 0;
								entry->castcontext = COERCION_CODE_IMPLICIT;
								entry->castmethod = COERCION_METHOD_BINARY;
								value = hash_search(ht_tsql_cast_info, key, HASH_ENTER, NULL);
								*(tsql_cast_info_entry_t *) value = *entry;
								continue;
							}
							/* function is not loaded. wait for next scan */
							else
							{
								inited_ht_tsql_cast_info = false;
								continue;
							}
						}
					}
					break;
				case TSQL_CAST_WITHOUT_FUNC_ENTRY:
					entry->castfunc = 0;
					break;
				default:
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							 errmsg("Unrecognized Cast Behavior")));
					break;
			}

			entry->castcontext = tsql_cast_raw_infos[i].castcontext;
			entry->castmethod = tsql_cast_raw_infos[i].castmethod;

			value = hash_search(ht_tsql_cast_info, key, HASH_ENTER, NULL);
			*(tsql_cast_info_entry_t *) value = *entry;
		}
	}

	PG_RETURN_INT32(0);
}

/* T-SQL Precedence */
typedef struct tsql_datatype_precedence_info_entry
{
	Oid			typ;
	int32		precedence;
} tsql_datatype_precedence_info_entry_t;

static tsql_datatype_precedence_info_entry_t *tsql_datatype_precedence_info_entries = NULL;
static HTAB *ht_tsql_datatype_precedence_info = NULL;
bool		inited_ht_tsql_datatype_precedence_info = false;

/*
 * smaller value has higher precedence
 * for unknown, return -1. (assume it is a user-defined type)
 */
static int
tsql_get_type_precedence(Oid typeId)
{
	tsql_datatype_precedence_info_entry_t *entry;

	/* Initialise T-SQL datatype precedence hash table if not already done */
	if (!inited_ht_tsql_datatype_precedence_info)
	{
		FunctionCallInfo fcinfo = NULL; /* empty interface */

		init_tsql_datatype_precedence_hash_tab(fcinfo);
	}

	entry = (tsql_datatype_precedence_info_entry_t *) hash_search(ht_tsql_datatype_precedence_info, &typeId, HASH_FIND, NULL);
	if (entry == NULL)
		return -1;

	return entry->precedence;
}

static bool
tsql_has_higher_precedence(Oid typeId1, Oid typeId2)
{
	int			type1_precedence;
	int			type2_precedence;

	type1_precedence = tsql_get_type_precedence(typeId1);
	type2_precedence = tsql_get_type_precedence(typeId2);

	return type1_precedence < type2_precedence;
}

static bool
is_vectorized_binary_operator(FuncCandidateList candidate)
{
	Oid			argoid = InvalidOid;
	HeapTuple	tup = NULL;

	Assert(candidate);

	if (candidate->nargs != 2)
		return false;
	if (candidate->nvargs > 0)
		return false;

	argoid = candidate->args[0];
	for (int i = 1; i < candidate->nargs; ++i)
		if (argoid != candidate->args[i])
			return false;

	/* look-up syscache to check candidate is a valid operator */
	tup = SearchSysCache1(OPEROID, ObjectIdGetDatum(candidate->oid));
	if (!HeapTupleIsValid(tup))
		return false;

	ReleaseSysCache(tup);
	return true;
}

static bool
tsql_has_func_args_higher_precedence(int n, Oid *inputtypes, FuncCandidateList candidate1, FuncCandidateList candidate2, bool candidates_are_opers)
{
	int			i;
	Oid		   *argtypes1 = candidate1->args;
	Oid		   *argtypes2 = candidate2->args;
	bool		can1_is_sametype = true;
	bool		can2_is_sametype = true;

	/*
	 * There is no public documentation how T-SQL chooses the best candidate.
	 * Let's use a simple heuristic based on type precedence to resolve
	 * ambiguity.
	 *
	 * Please note that other more important criteria such as (# of exact
	 * matching types) should be already handled by PG backend. So we don't
	 * need to consider it here.
	 *
	 * Please note that there still can be an ambiguous case. i.e. input is
	 * (int,int) but candidate 1 is (int,bigint) and candidate 2 is
	 * (bigint,int)
	 */

	if (is_vectorized_binary_operator(candidate1) && !is_vectorized_binary_operator(candidate2))
		return true;

	/* Prioritize candidates with same-typed arguments for operators only*/
	if (candidates_are_opers)
	{
		for (i = 1; i < n; ++i)
		{
			can1_is_sametype &= argtypes1[i-1] == argtypes1[i];
			can2_is_sametype &= argtypes2[i-1] == argtypes2[i];
		}

		if (can2_is_sametype != can1_is_sametype)
			return can1_is_sametype;
	}

	for (i = 0; i < n; ++i)
	{
		if (argtypes1[i] == argtypes2[i])
			continue;
		if (tsql_has_higher_precedence(argtypes1[i], argtypes2[i]))
			continue;

		return false;
	}

	return true;
}

static FuncCandidateList
deep_copy_func_candidate(FuncCandidateList in)
{
	/* deep copy single func-candidate except pointer to a next func-candidate */
	FuncCandidateList out;

	out = (FuncCandidateList) palloc(sizeof(struct _FuncCandidateList) + in->nargs * sizeof(Oid));
	memcpy(out, in, sizeof(struct _FuncCandidateList) + in->nargs * sizeof(Oid));
	out->next = NULL;
	return out;
}

static FuncCandidateList
run_tsql_best_match_heuristics(int nargs, Oid *input_typeids, FuncCandidateList candidates)
{
	FuncCandidateList new_candidates = NULL;
	Oid			input_base_typeids[FUNC_MAX_ARGS];
	int			i;
	int			nmatch;
	int			nbestMatch;
	FuncCandidateList current_candidate;
	FuncCandidateList last_candidate;
	Oid		   *current_typeids;

	for (i = 0; i < nargs; i++)
	{
		if (input_typeids[i] != UNKNOWNOID)
			input_base_typeids[i] = getBaseType(input_typeids[i]);
		else
		{
			/* no need to call getBaseType on UNKNOWNOID */
			input_base_typeids[i] = UNKNOWNOID;
		}
	}

	/*
	 * Run through all candidates and keep those with the most matches on
	 * exact types. Keep all candidates if none match.
	 */
	nbestMatch = 0;
	last_candidate = NULL;
	for (current_candidate = candidates;
		 current_candidate != NULL;
		 current_candidate = current_candidate->next)
	{
		current_typeids = current_candidate->args;
		nmatch = 0;
		for (i = 0; i < nargs; i++)
		{
			if (input_base_typeids[i] != UNKNOWNOID &&
				(current_typeids[i] == input_base_typeids[i] ||
				 current_typeids[i] == input_typeids[i]))	/* this is the
															 * difference from PG */
				nmatch++;
		}

		/* take this one as the best choice so far? */
		if ((nmatch > nbestMatch) || (last_candidate == NULL))
		{
			nbestMatch = nmatch;
			new_candidates = deep_copy_func_candidate(current_candidate);
			last_candidate = new_candidates;
		}
		/* no worse than the last choice, so keep this one too? */
		else if (nmatch == nbestMatch)
		{
			last_candidate->next = deep_copy_func_candidate(current_candidate);
			last_candidate = last_candidate->next;
		}
		/* otherwise, don't bother keeping this one... */
	}

	return new_candidates;
}

/*
 * get_immediate_base_type_of_UDT_internal()
 * This function returns the Immediate base type for UDT.
 * Returns InvalidOid if given type is not an UDT
 */
static Oid
get_immediate_base_type_of_UDT_internal(Oid typeid)
{
	HeapTuple					tuple;
	bool						isnull;
	Datum						datum;
	Datum                       tsql_typename;
	Oid							base_type;
	LOCAL_FCINFO(fcinfo, 1);

	if (!OidIsValid(typeid))
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("typeid is invalid!")));

	/* if common_utility_plugin_ptr is not initialised */
	if (common_utility_plugin_ptr == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("Failed to find common utility plugin.")));

	/* if tsql_typename is NULL it implies that inputTypId corresponds to UDT */
	InitFunctionCallInfoData(*fcinfo, NULL, 0, InvalidOid, NULL, NULL);
	fcinfo->args[0].value = ObjectIdGetDatum(typeid);
	fcinfo->args[0].isnull = false;
	tsql_typename = (*common_utility_plugin_ptr->translate_pg_type_to_tsql) (fcinfo);

	/* if given type is not an UDT then return InvalidOid */
	if (tsql_typename)
		return InvalidOid;

	/* Get immediate base type id of given type id */
	tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(typeid));
	if (!HeapTupleIsValid(tuple))
		return InvalidOid;

	datum = SysCacheGetAttr(TYPEOID, tuple, Anum_pg_type_typbasetype, &isnull);
	if (isnull)
		return InvalidOid;

	base_type = DatumGetObjectId(datum);
	ReleaseSysCache(tuple);

	return base_type;
}

Datum
get_immediate_base_type_of_UDT(PG_FUNCTION_ARGS)
{
	Oid			base_type;
	
	base_type = get_immediate_base_type_of_UDT_internal(PG_GETARG_OID(0));
	if (!OidIsValid(base_type))
		PG_RETURN_NULL();

	PG_RETURN_OID(base_type);
}

/*
 * For a given function details, validate whether it is in special function list
 */
bool
validate_special_function(char *func_nsname, char *func_name, int nargs, bool num_args_match)
{
	tsql_special_function_t    *special_func;

	/* Sanity checks */
	if (func_name == NULL)
		return false;

	/* 
	 * Special function handling is only for some specific system functions.
	 * If func_nsname is NULL, consider it to be a "sys".
	 */
	if (func_nsname != NULL &&
		(strlen(func_nsname) != 3 || strncmp(func_nsname, "sys", 3) != 0))
		return false;

	/* Get Special function details */
	special_func = NULL;

	for (int i = 0; i < TOTAL_TSQL_SPECIAL_FUNCTION_COUNT; i++)
	{
		if (strcmp(func_name, tsql_special_function_list[i].funcname) == 0
			&& (tsql_special_function_list[i].is_variadic || nargs == tsql_special_function_list[i].nargs))
		{
			special_func = &tsql_special_function_list[i];
			break;
		}
	}

	/* If function is not a special function no additional handling required */
	if (special_func == NULL)
		return false;

	/* if the function is not variadic and number of args don't match, no need for special handling */
	if (!(special_func->is_variadic || num_args_match))
		return false;

	/* For variadic function add check on number of arguments */
	if (special_func->is_variadic)
	{
		/* PG has limitation for max number of args = 100. */
		if ((strlen(func_name) == 6 && strncmp(func_name, "concat", 6) == 0)
			&& (nargs < 1 || nargs > 100))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
						errmsg("The concat function requires 1 to 100 arguments.")));
		else if ((strlen(func_name) == 9 && strncmp(func_name, "concat_ws", 9) == 0)
				&& (nargs < 2 || nargs > 100))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
						errmsg("The concat_ws function requires 2 to 100 arguments.")));
	}

	return true;
}

/*
 * tsql_func_select_candidate_for_special_func()
 *
 * For functions present in special function list, and try to find best candidate 
 * based on matching return type. Also throw error in case of invalid argument data type.
 */
static FuncCandidateList
tsql_func_select_candidate_for_special_func(List *names, int nargs, Oid *input_typeids, FuncCandidateList candidates)
{
	FuncCandidateList			current_candidate, best_candidate;
	Oid 						expr_result_type;
	char					   *proc_nsname;
	char					   *proc_name;
	bool						is_func_validated;
	int							ncandidates;
	Oid							rettype;
	Oid							sys_oid = get_namespace_oid("sys", false);
	Oid						   *new_input_typeids;

	DeconstructQualifiedName(names, &proc_nsname, &proc_name);

	is_func_validated = validate_special_function(proc_nsname, proc_name, nargs, true);

	/* Return NULL if function is not a special function */
	if (!is_func_validated)
		return NULL;

	/*
	 * If input type ids are UDT then we should use its immediate base type to pick the correct definition.
	 */
	new_input_typeids = (Oid *) palloc0(nargs * sizeof(Oid));
	for (int i = 0; i < nargs; i++)
	{
		new_input_typeids[i] = get_immediate_base_type_of_UDT_internal(input_typeids[i]);
		if (!OidIsValid(new_input_typeids[i]))
		{
			new_input_typeids[i] = input_typeids[i];
		}
	}

	/* if common_utility_plugin_ptr is not initialised */
	if (common_utility_plugin_ptr == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("Failed to find common utility plugin.")));

	/* function based logic to decide return type */
	expr_result_type = InvalidOid;
	if (strlen(proc_name) == 4 && strncmp(proc_name,"trim", 4) == 0 && nargs == 2)
	{
		if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[1])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[1])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[1]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar");	
		}
		else
		{
			expr_result_type = get_sys_varcharoid();
		}
	}
	else if (strlen(proc_name) == 9 && strncmp(proc_name, "translate", 9) == 0)
	{
		if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[0]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar"); 
		}
		else
		{
			expr_result_type = get_sys_varcharoid();
		}
	}
	else if (strlen(proc_name) == 7 && strncmp(proc_name,"replace", 7) == 0)
	{
		if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[1])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[1])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[1])
			|| (*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[2])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[2])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[2]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar");	
		}
		else
		{
			expr_result_type = get_sys_varcharoid();
		}
	}
	else if (strlen(proc_name) == 5 && strncmp(proc_name, "stuff", 5) == 0)
	{
		if ((*common_utility_plugin_ptr->is_tsql_sys_binary_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype)(new_input_typeids[0]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("varbinary"); 
		}
		else if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[3])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[3])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[3]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar"); 
		}
		else
		{
			expr_result_type = get_sys_varcharoid();
		}
	}
	else if (strlen(proc_name) == 10 && strncmp(proc_name, "string_agg", 10) == 0)
	{
		if ((*common_utility_plugin_ptr->is_tsql_varchar_datatype)(new_input_typeids[0])
				|| (*common_utility_plugin_ptr->is_tsql_bpchar_datatype)(new_input_typeids[0])
				|| (*common_utility_plugin_ptr->is_tsql_text_datatype)(new_input_typeids[0])
				|| new_input_typeids[0] == UNKNOWNOID)
		{
			expr_result_type = get_sys_varcharoid();
		}
		else
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar");
		}
	}
	else if (strlen(proc_name) == 9 && strncmp(proc_name, "concat_ws", 9) == 0)
	{
		expr_result_type = get_sys_varcharoid();
		for (int i = 0; i < nargs; i++)
		{
			if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[i])
				|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[i])
				|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[i]))
			{
				expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar");
				break;
			}
		}
	}
	else if (strlen(proc_name) == 6 && strncmp(proc_name, "concat", 6) == 0)
	{
		expr_result_type = get_sys_varcharoid();
		for (int i = 0; i < nargs; i++)
		{
			if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[i])
				|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[i])
				|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[i]))
			{
				expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar");
				break;
			}
		}
	}
	else if (strlen(proc_name) == 9 && strncmp(proc_name, "substring", 9) == 0)
	{
		if ((*common_utility_plugin_ptr->is_tsql_sys_binary_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_image_datatype)(new_input_typeids[0]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("varbinary"); 
		}
		else if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[0]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar"); 
		}
		else
		{
			expr_result_type = get_sys_varcharoid();
		}
	}
	else if ((strlen(proc_name) == 4 && strncmp(proc_name,"trim", 4) == 0 && nargs == 1)
			|| (strlen(proc_name) == 5 && strncmp(proc_name,"ltrim", 5) == 0)
			|| (strlen(proc_name) == 5 && strncmp(proc_name,"rtrim", 5) == 0)
			|| (strlen(proc_name) == 4 && strncmp(proc_name,"left", 4) == 0)
			|| (strlen(proc_name) == 5 && strncmp(proc_name,"right", 5) == 0)
			|| (strlen(proc_name) == 7 && strncmp(proc_name,"reverse", 7) == 0)
			|| (strlen(proc_name) == 9 && strncmp(proc_name,"replicate", 9) == 0)
			|| (strlen(proc_name) == 5 && strncmp(proc_name,"upper", 5) == 0)
			|| (strlen(proc_name) == 5 && strncmp(proc_name,"lower", 5) == 0))
	{
		if ((*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(new_input_typeids[0])
			|| (*common_utility_plugin_ptr->is_tsql_ntext_datatype)(new_input_typeids[0]))
		{
			expr_result_type = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar"); 
		}
		else
		{
			expr_result_type = get_sys_varcharoid();
		}
	}

	/* free new_input_typeids, as they are no longer needed */
	if (new_input_typeids)
		pfree(new_input_typeids);

	if (!OidIsValid(expr_result_type))
		return NULL;

	/* Get the candidate with matching return type */
	ncandidates = 0;
	best_candidate = NULL;
	for (current_candidate = candidates;
			current_candidate != NULL;
			current_candidate = current_candidate->next)
	{
		/* we should only consider candidates for special function from sys schema */
		if (get_func_namespace(current_candidate->oid) != sys_oid)
			continue;

		rettype = get_func_rettype(current_candidate->oid);
		
		/* Ignore following definitions as these are used when no other potential definition can be used. */
		if ((current_candidate->args[0] == TEXTOID && rettype == get_sys_varcharoid())
			|| (current_candidate->args[0] == BYTEAOID && rettype == BYTEAOID))
			continue;

		if (expr_result_type == rettype)
		{
			best_candidate = current_candidate;
			ncandidates++;
		}
	}

	/* if there are no suitable candidates in sys schema, let PG decide which canidate to use. */
	if (ncandidates == 0)
	{
		return NULL;
	}
	/* multiple suitable candidates with same return type should not exist in sys schema.  */
	else if (ncandidates > 1)
	{
		ereport(ERROR,
			(errcode(ERRCODE_INTERNAL_ERROR),
				errmsg("multiple definitions of function %s.%s with return type %s found.", proc_nsname, proc_name, format_type_be(expr_result_type))));
	}

	if (best_candidate != NULL)
		best_candidate->next = NULL;
	return best_candidate;
}

static FuncCandidateList
tsql_func_select_candidate(List *names,
						   List *fargs,
						   int nargs,
						   Oid *input_typeids,
						   FuncCandidateList candidates,
						   bool unknowns_resolved,
						   bool is_special)
{
	FuncCandidateList new_candidates;
	FuncCandidateList current_candidate;
	FuncCandidateList another_candidate;
	int			i;
	bool			  candidates_are_opers = false;

	if (is_special)
	{
		/*
		 * In case of dump restore we don't require special handling as PG handling will be sufficient
		 */
		if (babelfish_dump_restore)
			return NULL;

		return tsql_func_select_candidate_for_special_func(names, nargs, input_typeids, candidates);
	}

	if (unknowns_resolved)
	{
		Oid		   *new_input_typeids = palloc(nargs * sizeof(Oid));
		Oid			sys_varcharoid = get_sys_varcharoid();

		/*
		 * For unknown literals, try the following orders: varchar -> text ->
		 * others
		 */
		for (i = 0; i < nargs; i++)
		{
			new_input_typeids[i] = (input_typeids[i] == UNKNOWNOID) ? sys_varcharoid : input_typeids[i];
		}
		current_candidate = func_select_candidate(nargs, new_input_typeids, candidates);
		if (current_candidate)
		{
			int			n_poly_args = 0;

			for (i = 0; i < nargs; i++)
				if (input_typeids[i] == UNKNOWNOID && IsPolymorphicType(current_candidate->args[i]))
					++n_poly_args;

			if (n_poly_args == 0)
				return current_candidate;
		}

		/*
		 * TODO: PG doens't blindly use TEXT datatype for UNKNOWNOID. It is
		 * based on its category and preffered datatype. It's not clear to
		 * follow the same policy in babelfish. For now, simply always
		 * choosing TEXT datatype here.
		 */
		for (i = 0; i < nargs; i++)
		{
			new_input_typeids[i] = (input_typeids[i] == UNKNOWNOID) ? TEXTOID : input_typeids[i];
		}

		/*
		 * UNKNOWNOID was overwritten to TEXTOID. apply the PG logic again to
		 * find the candidate
		 */
		return func_select_candidate(nargs, new_input_typeids, candidates);
	}

	new_candidates = run_tsql_best_match_heuristics(nargs, input_typeids, candidates);
	candidates_are_opers = SearchSysCacheExists1(OPEROID, new_candidates->oid);

	for (current_candidate = new_candidates;
		 current_candidate != NULL;
		 current_candidate = current_candidate->next)
	{
		bool		has_highest_precedence = true;

		for (another_candidate = new_candidates;
			 another_candidate != NULL;
			 another_candidate = another_candidate->next)
		{
			if (!tsql_has_func_args_higher_precedence(nargs, input_typeids, current_candidate, another_candidate, candidates_are_opers))
			{
				has_highest_precedence = false;
				break;
			}
		}

		if (has_highest_precedence)
		{
			current_candidate->next = NULL;
			return current_candidate;
		}
	}

	/*
	 * can't find the function which beats all the other functions. still
	 * ambiguous.
	 */
	return NULL;
}

static bool
is_tsql_char_type_with_len(Oid type, bool is_case_expr)
{
	bool		       result;
	common_utility_plugin *utilptr = common_utility_plugin_ptr;
	result =  utilptr->is_tsql_bpchar_datatype(type) ||
			  utilptr->is_tsql_nchar_datatype(type) ||
			  utilptr->is_tsql_varchar_datatype(type) ||
			  utilptr->is_tsql_nvarchar_datatype(type);
	
	/* 
         * For case expr we need to find common type based on TSQL's
	 * precedence for text and ntext also.
	 */
	if(is_case_expr)
		result |= utilptr->is_tsql_text_datatype(type) ||
			  	  utilptr->is_tsql_ntext_datatype(type);

	return result;
}

static bool
starts_with(const char *text, const char *pat)
{
	int i = 0;
	int textlen = strlen(text);
	int patlen = strlen(pat);

	if (text == NULL || pat == NULL || textlen < patlen)
		return false;

	/* skip initial spaces in the main text string */
	for (i = 0; i < strlen(text); i++)
	{
		if (text[i] != ' ')
			break;
	}

	for (i = 0; i < patlen; i++)
	{
		if (text[i] != pat[i])
			return false;
	}

	return true;
}

static Node *
tsql_coerce_string_literal_hook(Oid targetTypeId,
								int32 targetTypeMod, int32 baseTypeMod,
								Const *newcon, char *value,
								CoercionContext ccontext, CoercionForm cformat,
								int location)
{
	Oid			baseTypeId = newcon->consttype;
	Type		baseType = typeidType(baseTypeId);
	int32		inputTypeMod = newcon->consttypmod;

	if (newcon->constisnull)
	{
		newcon->constvalue = stringTypeDatum(baseType, NULL, inputTypeMod);
	}
	else
	{
		int			i;
		bool		val_is_non_integer = starts_with(value, "0x") || starts_with(value, "0b") || starts_with(value, "0o") ;

		if (ccontext != COERCION_EXPLICIT)
		{
			/*
			 * T-SQL forbids implicit casting from string literal to certain
			 * datatypes (i.e. binary, varbinary)
			 */
			if ((*common_utility_plugin_ptr->is_tsql_binary_datatype) (baseTypeId))
				ereport(ERROR,
						(errcode(ERRCODE_CANNOT_COERCE),
						 errmsg("cannot coerce string literal to binary datatype")));
			if ((*common_utility_plugin_ptr->is_tsql_varbinary_datatype) (baseTypeId))
				ereport(ERROR,
						(errcode(ERRCODE_CANNOT_COERCE),
						 errmsg("cannot coerce string literal to varbinary datatype")));
		}

		if (val_is_non_integer &&
			(baseTypeId == INT2OID ||
			 baseTypeId == INT4OID))
		{
			const char *dtname = baseTypeId == INT2OID ? "smallint" : "int";
			ereport(ERROR,
					(errcode(ERRCODE_CANNOT_COERCE),
						 errmsg("Conversion failed when converting the varchar value '%s' to data type %s.",
								value, dtname)));
		}
		else if (val_is_non_integer &&
				 baseTypeId == INT8OID)
			ereport(ERROR,
					(errcode(ERRCODE_CANNOT_COERCE),
						 errmsg("Error converting data type varchar to bigint.")));

		/*
		 * T-SQL treats an empty string literal as 0 in certain datatypes,
		 * e.g., INT, FLOAT, etc.
		 */
		for (i = strlen(value) - 1; i >= 0; i--)
		{
			if (value[i] != ' ')
				break;
		}

		if (i == -1)
		{
			/*
			 * i == 1 means the value does not contain any characters but
			 * spaces
			 */
			switch (baseTypeId)
			{
				case INT2OID:
					newcon->constvalue = Int16GetDatum(0);
					break;
				case INT4OID:
					newcon->constvalue = Int32GetDatum(0);
					break;
				case INT8OID:
					newcon->constvalue = Int64GetDatum(0);
					break;
				case FLOAT4OID:
					newcon->constvalue = Float4GetDatum(0);
					break;
				case FLOAT8OID:
					newcon->constvalue = Float8GetDatum(0);
					break;
				case NUMERICOID:
					{
						/*
						 * T-SQL allows an empty/space-only string as a
						 * default constraint of NUMERIC column in CREATE
						 * TABLE statement. However, it will eventually throw
						 * an error when actual INSERT happens for the default
						 * value.
						 *
						 * For example, "CREATE TABLE t1 (c1 INT, c2 NUMERIC
						 * DEFAULT '')" can be executed without an error, but
						 * "INSERT INTO t1 (c1) VALUES (1)" will throw an
						 * error because an empty string to NUMERIC conversion
						 * is disallowed.
						 *
						 * To support this behavior without impacting general
						 * DML performance, we replace the wrong default value
						 * with the built-in function,
						 * sys.babelfish_runtime_error(), which raises an
						 * error in execution time.
						 */

						Oid			argTypes[1];
						List	   *funcname;
						Oid			errFuncOid;
						Node	   *result;

						argTypes[0] = ANYCOMPATIBLEOID;
						funcname = list_make1(makeString(pstrdup("babelfish_runtime_error")));
						errFuncOid = LookupFuncName(funcname, 1, argTypes, true);

						if (OidIsValid(errFuncOid))
						{
							char	   *msg;
							List	   *args;
							FuncExpr   *errFunc;
							Node	   *coerced;

							msg = pstrdup("An empty or space-only string cannot be converted into numeric/decimal data type");

							args = list_make1(makeConst(TEXTOID,
														-1,
														tsql_get_database_or_server_collation_oid_internal(false),
														-1,
														PointerGetDatum(cstring_to_text(msg)),
														false,
														false));
							errFunc = makeFuncExpr(errFuncOid, targetTypeId, args, 0, 0, COERCE_EXPLICIT_CALL);

							result = (Node *) errFunc;

							/* If target is a domain, apply constraints. */
							if (baseTypeId != targetTypeId)
								result = coerce_to_domain(result,
														  baseTypeId, baseTypeMod,
														  targetTypeId,
														  ccontext, cformat, location,
														  false);

							coerced = coerce_to_target_type(NULL, result, ANYCOMPATIBLEOID,
															NUMERICOID, targetTypeMod, COERCION_PLPGSQL,
															cformat, location);
							result = coerced ? coerced : result;

							ReleaseSysCache(baseType);

							return result;
						}

						/*
						 * If we cannot find errFunc, let normal exception
						 * happens inside stringTypeDatum().
						 */
						newcon->constvalue = stringTypeDatum(baseType, value, inputTypeMod);
						break;
					}
				default:
					newcon->constvalue = stringTypeDatum(baseType, value, inputTypeMod);
			}
		}
		else if ((*common_utility_plugin_ptr->is_tsql_binary_datatype) (baseTypeId) ||
				 (*common_utility_plugin_ptr->is_tsql_varbinary_datatype) (baseTypeId) ||
				 (*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (baseTypeId))
		{
			/*
			 * binary datatype should be passed in client encoding
			 * when explicit cast is called
			 */

			TypeName 	*varcharTypeName = makeTypeNameFromNameList(list_make2(makeString("sys"),
																	makeString("varchar")));
			Node 		*result;
			Const 		*tempcon;

			typenameTypeIdAndMod(NULL, (const TypeName *)varcharTypeName, &baseTypeId, &baseTypeMod);

			tempcon = makeConst(baseTypeId, -1,
								tsql_get_database_or_server_collation_oid_internal(false),
								-1, PointerGetDatum(cstring_to_text(value)),
								false, false);

			result = coerce_to_target_type(NULL, (Node *) tempcon, baseTypeId,
										   targetTypeId, targetTypeMod,
										   COERCION_EXPLICIT,
										   COERCE_EXPLICIT_CAST,
										   location);
			
			pfree(varcharTypeName);
			ReleaseSysCache(baseType);
			
			return result;
		}
		else
		{
			newcon->constvalue = stringTypeDatum(baseType, value, inputTypeMod);
		}
	}

	ReleaseSysCache(baseType);

	/*
	 * NULL means the newcon is updated properly so that we can proceed the
	 * rest of coerce_type() function.
	 */
	return NULL;
}

static bool
expr_is_null(Node *expr)
{
	return IsA(expr, Const) && ((Const*)expr)->constisnull 
				&& exprType(expr) == UNKNOWNOID;
}

static bool
is_tsql_str_const(Node *expr)
{
	return exprType(expr) == UNKNOWNOID && IsA(expr, Const) && !((Const*)expr)->constisnull;
}

static bool
expr_is_var_max(Node *expr)
{
	common_utility_plugin *utilptr = common_utility_plugin_ptr;
	return exprTypmod(expr) == -1 && (
		utilptr->is_tsql_varchar_datatype(exprType(expr)) ||
		utilptr->is_tsql_nvarchar_datatype(exprType(expr)) ||
		utilptr->is_tsql_varbinary_datatype(exprType(expr)) ||
		utilptr->is_tsql_sys_varbinary_datatype(exprType(expr)));
}

/* 
 * Handles special cases for finding a type when two or more need to be merged
 * Splits handling between cases with setops and values, and for ISNULL
 * 
 * If InvalidOid is returned, pg's select_common_type will attempt to
 * find a common type instead.
 */
static Oid
tsql_select_common_type_hook(ParseState *pstate, List *exprs, const char *context,
				  				Node **which_expr)
{
	int32  len;
	if (sql_dialect != SQL_DIALECT_TSQL || !context)
		return InvalidOid;
    
	len = strlen(context);
	
	if (len == 6 && strncmp(context, "ISNULL", 6) == 0)
		return select_common_type_for_isnull(pstate, exprs);
	else if(len == 13 && strncmp(context, "TSQL_COALESCE", 13) == 0)
		return select_common_type_for_coalesce_function(pstate, exprs);
	else if ((len == 5 && strncmp(context, "UNION", 5) == 0) || 
            (len == 9 && strncmp(context, "INTERSECT", 9) == 0) ||
            (len == 6 && strncmp(context, "EXCEPT", 6) == 0) ||
            (len == 6 && strncmp(context, "VALUES", 6) == 0) ||
            (len == 22 && strncmp(context, "UNION/INTERSECT/EXCEPT", 22) == 0) ||
            (len == 4 && strncmp(context, "CASE", 4) == 0))
		return select_common_type_setop(pstate, exprs, which_expr, context);

	return InvalidOid;
}

/*
 * Hook to handle constant string literal inputs for
 * COALESCE function. This function also handles empty and
 * white space string literals.
 */
static Node*
tsql_handle_constant_literals_hook(ParseState *pstate, Node *e)
{
	Const	   *con;
	char	   *val;
	int	   i = -1;

	if (exprType(e) != UNKNOWNOID || !IsA(e, Const))
		return e;

	con = (Const *) e;
	val = DatumGetCString(con->constvalue);

	if (val != NULL)
		i = strlen(val) - 1;

	/*
	 * Additional handling for empty or white space string literals as
	 * T-SQL treats an empty string literal as 0 in certain datatypes
	 */
	for (; i >= 0; i--)
	{
		if (!isspace(val[i]))
			break;
	}

	if (i != -1)
		e = coerce_to_common_type(pstate, e,
						VARCHAROID,
						"COALESCE");

	return e;
}

/*
 * When we must merge types together (i.e. UNION), if all types are
 * null, literals, or [n][var]char types, then return the correct
 * output type based on TSQL's precedence rules
 */ 
static Oid
select_common_type_setop(ParseState *pstate, List *exprs, Node **which_expr, const char *context)
{
	Node		*result_expr = (Node*) linitial(exprs);
	Oid			result_type = InvalidOid;
	ListCell	*lc;
	bool		is_case_expr = (strlen(context) == 4 && strncmp(context, "CASE", 4) == 0);

	/* Find a common type based on precedence. NULLs are ignored, and make 
	 * string literals varchars. If a type besides CHAR, NCHAR, VARCHAR, 
	 * or NVARCHAR is present, let engine handle finding the type.
	 * But if it is CASE expr then it will also check for text and ntext.
	 */
	foreach(lc, exprs)
	{
		Node		*expr = (Node *) lfirst(lc);
		Oid		type = exprType(expr);

		if (is_case_expr)
		{
			Oid		baseType = get_immediate_base_type_of_UDT_internal(type);

			/*
			 * If any of the branch is of UDT, then we will find the baseType using
			 * get_immediate_base_type_of_UDT_internal(), to find common type using TSQL precedence.
			 * If type is not UDT then baseType will be NULL.
			 */
			if (OidIsValid(baseType))
					type = baseType;
			
			/* 
			 * If any of the branch is of sysname or UDT is made from sysname
			 * We need to assign type to "varchar" (As sysname is created from "varchar").
			 */
 			if ((*common_utility_plugin_ptr->is_tsql_sysname_datatype) (type))
					type = get_sys_varcharoid();
		}

		if (expr_is_null(expr))
			continue;
		else if (is_tsql_str_const(expr))
			type = common_utility_plugin_ptr->lookup_tsql_datatype_oid("varchar");
		else if ((!is_tsql_char_type_with_len(type, is_case_expr)))
			return InvalidOid;
		
		if (tsql_has_higher_precedence(type, result_type) || result_type == InvalidOid)
		{
			result_expr = expr;
			result_type = type;
		}
	}

	if (which_expr)
		*which_expr = result_expr;
	return result_type;
}

/*
 * select_common_type_for_isnull - Deduce common data type for ISNULL(check_expression , replacement_value) 
 * function.
 * This function should return same as check_expression. If that expression is NULL then reyurn the data type of
 * replacement_value. If replacement_value is also NULL then return INT.
 */
static Oid
select_common_type_for_isnull(ParseState *pstate, List *exprs)
{
	Node	   *pexpr;
	Oid		   ptype;

	Assert(exprs != NIL);
	pexpr = (Node *) linitial(exprs);
	ptype = exprType(pexpr);

	/* Check if first arg (check_expression) is NULL literal */
	if (IsA(pexpr, Const) && ((Const *) pexpr)->constisnull && ptype == UNKNOWNOID)
	{
		Node *nexpr = (Node *) lfirst(list_second_cell(exprs));
		Oid ntype = exprType(nexpr);
		/* Check if second arg (replace_expression) is NULL literal */
		if (IsA(nexpr, Const) && ((Const *) nexpr)->constisnull && ntype == UNKNOWNOID)
		{
			return INT4OID;
		}
		/* If second argument is non-null string literal */
		if (ntype == UNKNOWNOID)
		{
			return get_sys_varcharoid();
		}
		return ntype;
	}
	/* If first argument is non-null string literal */
	if (ptype == UNKNOWNOID)
	{
		return get_sys_varcharoid();
	}
	return ptype;
}

static Oid
select_common_type_for_coalesce_function(ParseState *pstate, List *exprs)
{
	Node		*pexpr;
	Oid		ptype;
	ListCell	*lc;
	Oid		commontype = InvalidOid;
	int 		curr_precedence = INT_MAX, temp_precedence = 0;

	Assert(exprs != NIL);

	if (exprs->length < 2)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("COALESCE function should have at least 2 arguments")));

	foreach(lc, exprs)
	{
		pexpr = (Node *) lfirst(lc);
		ptype = exprType(pexpr);

		/* Check if arg is NULL literal */
		if (IsA(pexpr, Const) && ((Const *) pexpr)->constisnull)
			continue;

		/* If the arg is non-null string literal */
		if (ptype == UNKNOWNOID)
		{
			Oid curr_oid = get_sys_varcharoid();
			temp_precedence = tsql_get_type_precedence(curr_oid);
			if (commontype == InvalidOid 
				|| temp_precedence < curr_precedence)
			{
				commontype = curr_oid;
				curr_precedence = temp_precedence;
			}
			
			continue;
		}

		temp_precedence = tsql_get_type_precedence(ptype);

		if (commontype == InvalidOid || temp_precedence < curr_precedence)
		{
			commontype = ptype;
			curr_precedence = temp_precedence;
		}
	}

	if (commontype == InvalidOid)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("At least one of the arguments to COALESCE must be a non-NULL constant")));
	
	return commontype;
}

/* 
 * When we must merge types together (i.e. UNION), if the target type
 * is CHAR, NCHAR, or BINARY, make the typmod (representing the length)
 * equal to that of the largest expression
 * 
 * If -1 is returned, engine will handle finding a common typmod as usual
 */
static int32
tsql_select_common_typmod_hook(ParseState *pstate, List *exprs, Oid common_type)
{
	int32		max_typmods=0;
	ListCell	*lc;
	common_utility_plugin *utilptr = common_utility_plugin_ptr;

	if (sql_dialect != SQL_DIALECT_TSQL)
		return -1;

	if (!is_tsql_char_type_with_len(common_type, false) &&
			 !utilptr->is_tsql_binary_datatype(common_type) &&
			 !utilptr->is_tsql_sys_binary_datatype(common_type) &&
			 !utilptr->is_tsql_varbinary_datatype(common_type) &&
			 !utilptr->is_tsql_sys_varbinary_datatype(common_type))
		return -1;

	/* If resulting type is a length, need to be max of length types */
	foreach(lc, exprs)
	{
		Node *expr = (Node*) lfirst(lc);
		int32 typmod = exprTypmod(expr);
		Oid   type = exprType(expr);
		Oid   immediate_base_type = get_immediate_base_type_of_UDT_internal(type);

		/* 
		 * Handling for UDT, If immediate_base_type is Valid Oid that mean we need to handle typmod for UDT,
		 * By calculating typmod of its base type using getBaseTypeAndTypmod.
		 * Other wise if immediate_base_type is not Valid Oid We don't need any handling for UDT.
		 */
		if (OidIsValid(immediate_base_type))
		{
			/* Finding the typmod of base type of UDT using getBaseTypeAndTypmod() */
			int32 base_typmod = -1;
			Oid   base_type = getBaseTypeAndTypmod(type, &base_typmod);
			
			/* 
			 * This conditon is for the datatype with MAX typmod.
			 * -1 will only be returned if common_type is a datatype
			 * that supports MAX typmod. If common type is nchar(maxtypmod = 4000)
			 * or bpchar(maxtypmod = 8000) return the MAX typmod for them.
			 */
			if (base_typmod == -1 && 
				is_tsql_datatype_with_max_scale_expr_allowed(base_type))
			{
				if ((*common_utility_plugin_ptr->is_tsql_bpchar_datatype)(common_type))
					return BPCHAR_MAX_TYPMOD + VARHDRSZ;
				else if ((*common_utility_plugin_ptr->is_tsql_nchar_datatype)(common_type))
					return NCHAR_MAX_TYPMOD + VARHDRSZ;
				else if (is_tsql_datatype_with_max_scale_expr_allowed(common_type))
					return -1;
			}
			
			typmod = base_typmod;	
		}
		
		/* 
		 * Handling for sysname, In CASE expression if one of the branch is 
		 * of type sysname then set typmod as SYSNAME_TYPMOD (i.e. 128).
		 */
		if ((*common_utility_plugin_ptr->is_tsql_sysname_datatype) (type))
			typmod = SYSNAME_TYPMOD + VARHDRSZ;

		if (is_tsql_str_const(expr))
			typmod = strlen(DatumGetCString( ((Const*)expr)->constvalue )) + VARHDRSZ;

		/* This conditon is for the datatype with MAX typmod.
		 * -1 will only be returned if common_type is a datatype
		 * that supports MAX typmod.If common type is nchar(maxtypmod = 4000)
		 * or bpchar(maxtypmod = 8000) return the MAX typmod for them.
		 */
		if (expr_is_var_max(expr))
		{
			if ((*common_utility_plugin_ptr->is_tsql_bpchar_datatype)(common_type))
				return BPCHAR_MAX_TYPMOD + VARHDRSZ;
			else if ((*common_utility_plugin_ptr->is_tsql_nchar_datatype)(common_type))
				return NCHAR_MAX_TYPMOD + VARHDRSZ;
			else if (is_tsql_datatype_with_max_scale_expr_allowed(common_type))
				return -1;
		}

		if (lc == list_head(exprs))
			max_typmods = typmod;
		else
			max_typmods = Max(max_typmods, typmod);
	}

	return max_typmods;
}

/* 
 * For CASE expression, this function will set the typmod to all the CASE branches from coerce_type_typmod().
 */
static void
tsql_set_common_typmod_case_expr_hook(ParseState *pstate, List *exprs, CaseExpr *newc)
{
        /* calculating common_typemod for case expr */
        int32           typmod = select_common_typmod(pstate, exprs, newc->casetype);
        ListCell       *l;
        
        newc->defresult = (Expr *) 
                coerce_to_target_type(pstate,
                                (Node *) newc->defresult, 
                                newc->casetype, 
                                newc->casetype, 
                                typmod, 
                                COERCION_IMPLICIT,
				COERCE_IMPLICIT_CAST,
                                -1);

        foreach(l, newc->args)
        {
                CaseWhen   *w = (CaseWhen *) lfirst(l);

                w->result = (Expr *)
                        coerce_to_target_type(pstate,
                                (Node *) w->result, 
                                newc->casetype, 
                                newc->casetype, 
                                typmod, 
                                COERCION_IMPLICIT,
				COERCE_IMPLICIT_CAST,
                                -1);
        }
}

Datum
init_tsql_datatype_precedence_hash_tab(PG_FUNCTION_ARGS)
{
	HASHCTL		hashCtl;
	MemoryContext oldContext;
	tsql_datatype_precedence_info_entry_t *value;
	Oid			typoid;
	Oid			nspoid;
	Oid			sys_nspoid = get_namespace_oid("sys", true);

	TSQLInstrumentation(INSTR_TSQL_INIT_TSQL_DATATYPE_PRECEDENCE_HASH_TAB);

	/* Register Hooks */
	determine_datatype_precedence_hook = tsql_has_higher_precedence;
	func_select_candidate_hook = tsql_func_select_candidate;
	coerce_string_literal_hook = tsql_coerce_string_literal_hook;
	select_common_type_hook = tsql_select_common_type_hook;
	select_common_typmod_hook = tsql_select_common_typmod_hook;
	handle_constant_literals_hook = tsql_handle_constant_literals_hook;
	set_common_typmod_case_expr_hook = tsql_set_common_typmod_case_expr_hook;

	if (!OidIsValid(sys_nspoid))
		PG_RETURN_INT32(0);

	if (pltsql_coercion_context == NULL)	/* initialize memory context */
	{
		pltsql_coercion_context = AllocSetContextCreateInternal(NULL,
																"PLTSQL CoercionMemory Context",
																ALLOCSET_DEFAULT_SIZES);
	}

	/* create internal table */
	oldContext = MemoryContextSwitchTo(pltsql_coercion_context);
	if (tsql_datatype_precedence_info_entries == NULL)
		tsql_datatype_precedence_info_entries = palloc0(sizeof(tsql_datatype_precedence_info_entry_t) * (TOTAL_TSQL_PRECEDENCE_COUNT));
	MemoryContextSwitchTo(oldContext);

	/* create hash table */
	if (ht_tsql_datatype_precedence_info == NULL)
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(Oid);
		hashCtl.entrysize = sizeof(tsql_datatype_precedence_info_entry_t);
		hashCtl.hcxt = pltsql_coercion_context;
		ht_tsql_datatype_precedence_info = hash_create("T-SQL datatype precedence",
													   SPI_processed,
													   &hashCtl,
													   HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	/* mark the hash table initialised */
	inited_ht_tsql_datatype_precedence_info = true;

	for (int i = 0; i < TOTAL_TSQL_PRECEDENCE_COUNT; i++)
	{
		nspoid = strcmp(tsql_precedence_infos[i].nsp, "sys") == 0 ? sys_nspoid : PG_CATALOG_NAMESPACE;
		typoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
								 CStringGetDatum(tsql_precedence_infos[i].typname), ObjectIdGetDatum(nspoid));

		if (OidIsValid(typoid))
		{
			value = hash_search(ht_tsql_datatype_precedence_info, &typoid, HASH_ENTER, NULL);
			value->typ = typoid;
			value->precedence = tsql_precedence_infos[i].precedence;
		}
		else
		{
			/* type is not loaded. wait for next scan */
			inited_ht_tsql_datatype_precedence_info = false;
		}
	}

	PG_RETURN_INT32(0);
}

/*
 * Additional Casting Functions for T-SQL
 *
 * Some castings in T-SQL has different behavior with PG.
 * (i.e. real datatype to integral type - PG uses round but T-SQL uses trunc)
 */

/*  dtrunc in float.c */
inline static float8
dtrunc_(float8 arg1)
{
	float8 result;

	if (arg1 >= 0)
		result = floor(arg1);

	else
		result = -floor(-arg1);

	return result;
}

BBF_Pragma_IgnoreFloatConversionWarning_Push
inline static float4
ftrunc_(float4 arg1)
{
	float8 result;

	if (arg1 >= 0)
		result = floor(arg1);

	else
		result = -floor(-arg1);

	return result;
}
BBF_Pragma_IgnoreFloatConversionWarning_Pop

/* dtrunci8(X) = dtoi8(dtrunc(X)) */
PG_FUNCTION_INFO_V1(dtrunci8);

Datum
dtrunci8(PG_FUNCTION_ARGS)
{
	float8		num = PG_GETARG_FLOAT8(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(dtrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT8_FITS_IN_INT64(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT64((int64) num);
}


/* dtrunci4(X) = dtoi4(dtrunc(X)) */
PG_FUNCTION_INFO_V1(dtrunci4);

Datum
dtrunci4(PG_FUNCTION_ARGS)
{
	float8		num = PG_GETARG_FLOAT8(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(dtrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT8_FITS_IN_INT32(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT32((int32) num);
}


/* dtrunci2(X) = dtoi2(dtrunc(X)) */
PG_FUNCTION_INFO_V1(dtrunci2);

Datum
dtrunci2(PG_FUNCTION_ARGS)
{
	float8		num = PG_GETARG_FLOAT8(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(dtrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT8_FITS_IN_INT16(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("smallint out of range")));

	PG_RETURN_INT16((int16) num);
}


/* ftrunci8(X) = ftoi8(ftrunc(X)) */
PG_FUNCTION_INFO_V1(ftrunci8);

Datum
ftrunci8(PG_FUNCTION_ARGS)
{
	float4		num = PG_GETARG_FLOAT4(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	BBF_Pragma_IgnoreFloatConversionWarning_Push
	num = rint(ftrunc_(num));
	BBF_Pragma_IgnoreFloatConversionWarning_Pop

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT4_FITS_IN_INT64(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT64((int64) num);
}


/* ftrunci4(X) = ftoi4(ftrunc(X)) */
PG_FUNCTION_INFO_V1(ftrunci4);

Datum
ftrunci4(PG_FUNCTION_ARGS)
{
	float4		num = PG_GETARG_FLOAT4(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	BBF_Pragma_IgnoreFloatConversionWarning_Push
	num = rint(ftrunc_(num));
	BBF_Pragma_IgnoreFloatConversionWarning_Pop

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT4_FITS_IN_INT32(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT32((int32) num);
}


/* ftrunci2(X) = ftoi2(ftrunc(X)) */
PG_FUNCTION_INFO_V1(ftrunci2);

Datum
ftrunci2(PG_FUNCTION_ARGS)
{
	float4		num = PG_GETARG_FLOAT4(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	BBF_Pragma_IgnoreFloatConversionWarning_Push
	num = rint(ftrunc_(num));
	BBF_Pragma_IgnoreFloatConversionWarning_Pop

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT4_FITS_IN_INT16(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT16((int16) num);
}



PG_FUNCTION_INFO_V1(pltsql_text_name);
PG_FUNCTION_INFO_V1(pltsql_bpchar_name);

/* replace text_name() to handle t-sql identifier truncation */
Datum
pltsql_text_name(PG_FUNCTION_ARGS)
{
	text	   *s = PG_GETARG_TEXT_PP(0);
	Name result;
	int			len;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	len = VARSIZE_ANY_EXHDR(s);

	/* Truncate oversize input */
	if (len >= NAMEDATALEN)
	{
		if (cstr_to_name_hook)	/* to apply special truncation logic */
		{
			Name		n;

			PG_TRY();
			{
				/* T-SQL casting. follow T-SQL truncation rule */
				set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
								  GUC_CONTEXT_CONFIG,
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				n = (*cstr_to_name_hook) (VARDATA_ANY(s), len);
			}
			PG_CATCH();
			{
				set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
								  GUC_CONTEXT_CONFIG,
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				PG_RE_THROW();
			}
			PG_END_TRY();
			set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
							  GUC_CONTEXT_CONFIG,
							  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

			PG_RETURN_NAME(n);
		}

		len = pg_mbcliplen(VARDATA_ANY(s), len, NAMEDATALEN - 1);
	}

	/* We use palloc0 here to ensure result is zero-padded */
	result = (Name) palloc0(NAMEDATALEN);

	memcpy(NameStr(*result), VARDATA_ANY(s), len);

	PG_RETURN_NAME(result);
}

/* replace bpchar_name() to handle t-sql identifier truncation */
Datum
pltsql_bpchar_name(PG_FUNCTION_ARGS)
{
	BpChar	   *s = PG_GETARG_BPCHAR_PP(0);
	char	   *s_data;
	Name result;
	int			len;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	len = VARSIZE_ANY_EXHDR(s);
	s_data = VARDATA_ANY(s);

	/* Truncate oversize input */
	if (len >= NAMEDATALEN)
	{
		if (cstr_to_name_hook)	/* to apply special truncation logic */
		{
			Name		n;

			/* Remove trailing blanks */
			while (len > 0)
			{
				if (s_data[len - 1] != ' ')
					break;
				len--;
			}

			PG_TRY();
			{
				/* T-SQL casting. follow T-SQL truncation rule */
				set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
								  GUC_CONTEXT_CONFIG,
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				n = (*cstr_to_name_hook) (VARDATA_ANY(s), len);
			}
			PG_CATCH();
			{
				set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
								  GUC_CONTEXT_CONFIG,
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				PG_RE_THROW();
			}
			PG_END_TRY();
			set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
							  GUC_CONTEXT_CONFIG,
							  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

			PG_RETURN_NAME(n);
		}

		len = pg_mbcliplen(s_data, len, NAMEDATALEN - 1);
	}

	/* Remove trailing blanks */
	while (len > 0)
	{
		if (s_data[len - 1] != ' ')
			break;
		len--;
	}

	/* We use palloc0 here to ensure result is zero-padded */
	result = (Name) palloc0(NAMEDATALEN);

	memcpy(NameStr(*result), s_data, len);

	PG_RETURN_NAME(result);
}
