/*-------------------------------------------------------------------------
 *
 * forjson.c
 *   For JSON clause support for Babel
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "executor/spi.h"
#include "fmgr.h"
#include "utils/guc.h"
#include "lib/stringinfo.h"
#include "miscadmin.h"
#include "parser/parser.h"
#include "utils/builtins.h"
#include "utils/json.h"

static StringInfo tsql_query_to_json_internal(const char *query, int mode, bool include_null_value,
								bool without_array_wrapper, const char *root_name);
static void SPI_sql_row_to_json_path(uint64 rownum, StringInfo result, bool include_null_value);

PG_FUNCTION_INFO_V1(tsql_query_to_json_text);


Datum 
tsql_query_to_json_text(PG_FUNCTION_ARGS)
{
	for (int i=0; i< PG_NARGS()-1; i++)
	{
		if PG_ARGISNULL(i) 
			PG_RETURN_NULL();
	}
	char *query = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int mode = PG_GETARG_INT32(1);
	bool include_null_value = PG_GETARG_BOOL(2);
	bool without_array_wrapper = PG_GETARG_BOOL(3);
	char *root_name = PG_ARGISNULL(4) ? NULL :  text_to_cstring(PG_GETARG_TEXT_PP(4));

	StringInfo result = tsql_query_to_json_internal(query, mode, include_null_value,
											without_array_wrapper, root_name);
	
	PG_RETURN_TEXT_P(cstring_to_text_with_len(result->data, result->len));
}


/*
 * Map an SQL row to an JSON element, taking the row from the active
 * SPI cursor.
 */
static void
SPI_sql_row_to_json_path(uint64 rownum, StringInfo result, bool include_null_value)
{
	int			i;
	const char  *sep="";
	bool 		isnull;

	appendStringInfoChar(result,'{');
	for (i = 1; i <= SPI_tuptable->tupdesc->natts; i++)
	{
		char        *colname;
		Datum		colval;
		
		colname = SPI_fname(SPI_tuptable->tupdesc, i);
		
		if (!strcmp(colname,"\?column\?")) /* When column name or alias is not provided */
		{
			ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Column expressions and data sources without names or aliases cannot be formatted as JSON text using FOR JSON clause. Add alias to the unnamed column or table")));
		}
		
		colval = SPI_getbinval(SPI_tuptable->vals[rownum],
							   SPI_tuptable->tupdesc,
							   i,
							   &isnull);	

		if (isnull && !include_null_value)
			continue;

		appendStringInfo(result,sep);
		sep = ",";
		tsql_json_build_object(result, 
								CStringGetDatum(colname), colval,
								SPI_gettypeid(SPI_tuptable->tupdesc,i),isnull);

	}
	appendStringInfoChar(result,'}');
	if (rownum != SPI_processed-1)
	{
		appendStringInfoString(result,",");
	}
}

/*
 * Perform the operation based on the mode and directives in the input query
 */
static StringInfo
tsql_query_to_json_internal(const char *query, int mode, bool include_null_value,
				bool without_array_wrapper, const char *root_name)
{
	StringInfo	result;
	uint64		i;

	set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
					  (superuser() ? PGC_SUSET : PGC_USERSET),
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	result = makeStringInfo();

	SPI_connect();
	if (SPI_execute(query, true, 0) != SPI_OK_SELECT)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid query")));

	/* If root_name is present then WITHOUT_ARRAY_WRAPPER will be FALSE */
	if(root_name)
		appendStringInfo(result, "{\"%s\":[",root_name);
	else if (!without_array_wrapper)
		appendStringInfoChar(result,'[');

	/* Format the query result according to the mode specified by the query */
	switch (mode)
	{
		case TSQL_FORJSON_AUTO: /* FOR JSON AUTO */
			ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("AUTO mode is not supported")));
			break;
		case TSQL_FORJSON_PATH: /* FOR JSON PATH */
			for (i = 0; i < SPI_processed; i++)
				SPI_sql_row_to_json_path(i, result, include_null_value);
			break;
		default:
			/* Invalid mode, should not happen, report internal error */
			ereport(ERROR,
						(errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("invalid FOR JSON mode")));
	}

	SPI_finish();


	if(root_name)
		appendStringInfoString(result, "]}");
	else if (!without_array_wrapper)
		appendStringInfoChar(result,']');

	return result;
}
