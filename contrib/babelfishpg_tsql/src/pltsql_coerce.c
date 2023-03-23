/*-------------------------------------------------------------------------
 *
 * pltsql_coerce.c
 *   Datatype Coercion Utility for Babel
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/htup_details.h"
#include "access/parallel.h"	/* InitializingParallelWorker */
#include "miscadmin.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_cast.h"
#include "catalog/pg_type.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_namespace.h"
#include "executor/spi.h"
#include "mb/pg_wchar.h"
#include "nodes/makefuncs.h"
#include "parser/parse_coerce.h"
#include "parser/parse_func.h"
#include "parser/parse_type.h"
#include "src/collation.h"
#include "utils/builtins.h"
#include "utils/float.h"
#include "utils/guc.h"
#include "common/int.h"
#include "utils/int8.h"
#include "utils/numeric.h"
#include "utils/memutils.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "pltsql_instr.h"


#include <math.h>
#include "pltsql.h"

/* Hooks for engine*/
extern find_coercion_pathway_hook_type find_coercion_pathway_hook;
extern determine_datatype_precedence_hook_type determine_datatype_precedence_hook;
extern func_select_candidate_hook_type func_select_candidate_hook;
extern coerce_string_literal_hook_type coerce_string_literal_hook;

PG_FUNCTION_INFO_V1(init_tsql_coerce_hash_tab);
PG_FUNCTION_INFO_V1(init_tsql_datatype_precedence_hash_tab);

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
	{TSQL_CAST_WITHOUT_FUNC_ENTRY, "sys", "bbf_varbinary", "sys", "bbf_binary", NULL, 'i', 'b'},
/*  binary     {only allow to cast to integral data type) */
	{PG_CAST_ENTRY, "sys", "bbf_binary", "pg_catalog", "int8", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bbf_binary", "pg_catalog", "int4", NULL, 'i', 'f'},
	{PG_CAST_ENTRY, "sys", "bbf_binary", "pg_catalog", "int2", NULL, 'i', 'f'},
	{TSQL_CAST_ENTRY, "sys", "bbf_binary", "sys", "rowversion", "binaryrowversion", 'i', 'f'},
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

	Oid			typeIds[2] = {sourceTypeId, targetTypeId};

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
			ReleaseSysCache(tuple);
		}
	}

	/* Perhaps the types are domains; if so, look at their base types */
	if (!isSqlVariantCast)
	{
		if (OidIsValid(sourceTypeId))
			sourceTypeId = getBaseType(sourceTypeId);

		/*
		 * if we are casting from INT8 to MONEY, don't look for base type of
		 * target so that it can call the cast function which matches with the
		 * exact types
		 */
		if (OidIsValid(targetTypeId) && !isInt8ToMoney)
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
							/* function is not loaded. wait for next scan */
							inited_ht_tsql_cast_info = false;
							continue;
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
tsql_has_func_args_higher_precedence(int n, Oid *inputtypes, FuncCandidateList candidate1, FuncCandidateList candidate2)
{
	int			i;
	Oid		   *argtypes1 = candidate1->args;
	Oid		   *argtypes2 = candidate2->args;

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

static FuncCandidateList
tsql_func_select_candidate(int nargs,
						   Oid *input_typeids,
						   FuncCandidateList candidates,
						   bool unknowns_resolved)
{
	FuncCandidateList new_candidates;
	FuncCandidateList current_candidate;
	FuncCandidateList another_candidate;
	int			i;

	if (unknowns_resolved)
	{
		Oid		   *new_input_typeids = palloc(nargs * sizeof(Oid));
		Oid			nspoid = get_namespace_oid("sys", false);
		Oid			sys_varcharoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("varchar"), ObjectIdGetDatum(nspoid));

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

	for (current_candidate = new_candidates;
		 current_candidate != NULL;
		 current_candidate = current_candidate->next)
	{
		bool		has_highest_precedence = true;

		for (another_candidate = new_candidates;
			 another_candidate != NULL;
			 another_candidate = another_candidate->next)
		{
			if (!tsql_has_func_args_higher_precedence(nargs, input_typeids, current_candidate, another_candidate))
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

static Node *
tsql_coerce_string_literal_hook(ParseCallbackState *pcbstate, Oid targetTypeId,
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

		if (ccontext != COERCION_EXPLICIT)
		{
			/*
			 * T-SQL may forbid casting from string literal to certain
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
														tsql_get_server_collation_oid_internal(false),
														-1,
														PointerGetDatum(cstring_to_text(msg)),
														false,
														false));
							errFunc = makeFuncExpr(errFuncOid, targetTypeId, args, 0, 0, COERCE_EXPLICIT_CALL);

							cancel_parser_errposition_callback(pcbstate);

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
	num = rint(ftrunc_(num));

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
	num = rint(ftrunc_(num));

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
	num = rint(ftrunc_(num));

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
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				n = (*cstr_to_name_hook) (VARDATA_ANY(s), len);
			}
			PG_CATCH();
			{
				set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				PG_RE_THROW();
			}
			PG_END_TRY();
			set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
							  (superuser() ? PGC_SUSET : PGC_USERSET),
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
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				n = (*cstr_to_name_hook) (VARDATA_ANY(s), len);
			}
			PG_CATCH();
			{
				set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				PG_RE_THROW();
			}
			PG_END_TRY();
			set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
							  (superuser() ? PGC_SUSET : PGC_USERSET),
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
