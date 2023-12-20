/*-------------------------------------------------------------------------
 *
 * forjson.c
 *   For JSON clause support for Babel
 *
 * This implementation of FOR JSON has been deprecated as of v2.4.0. However,
 * we cannot remove this implementation, as there may be older views that reference
 * these functions from prior versions, and we do not want to prevent those
 * views from returning the correct result after upgrade.
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
#include "utils/syscache.h"
#include "catalog/pg_type.h"
#include "catalog/namespace.h"

#include "tsql_for.h"

static StringInfo tsql_query_to_json_internal(const char *query, int mode, bool include_null_value,
											  bool without_array_wrapper, const char *root_name);
static void SPI_sql_row_to_json_path(uint64 rownum, StringInfo result, bool include_null_value);
static void tsql_unsupported_datatype_check(void);
static void for_json_datetime_format(StringInfo format_output, char *outputstr);
static void for_json_datetimeoffset_format(StringInfo format_output, char *outputstr);

PG_FUNCTION_INFO_V1(tsql_query_to_json_text);


Datum
tsql_query_to_json_text(PG_FUNCTION_ARGS)
{
	char	   *query;
	int			mode;
	bool		include_null_value;
	bool		without_array_wrapper;
	char	   *root_name;
	StringInfo result;

	ereport(WARNING,
			(errcode(ERRCODE_WARNING_DEPRECATED_FEATURE),
			 errmsg("This version of FOR JSON has been deprecated. We recommend recreating the view for this query.")));

	for (int i = 0; i < PG_NARGS() - 1; i++)
	{
		if (PG_ARGISNULL(i))
				PG_RETURN_NULL();
	}
	query = text_to_cstring(PG_GETARG_TEXT_PP(0));
	mode = PG_GETARG_INT32(1);
	include_null_value = PG_GETARG_BOOL(2);
	without_array_wrapper = PG_GETARG_BOOL(3);
	root_name = PG_ARGISNULL(4) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(4));

	result = tsql_query_to_json_internal(query, mode, include_null_value,
										 without_array_wrapper, root_name);

	if (result)
		PG_RETURN_TEXT_P(cstring_to_text_with_len(result->data, result->len));
	else
		PG_RETURN_NULL();
}


/*
 * Map an SQL row to an JSON element, taking the row from the active
 * SPI cursor.
 */
static void
SPI_sql_row_to_json_path(uint64 rownum, StringInfo result, bool include_null_value)
{
	int			i;
	const char *sep = "";
	bool		isnull;

	appendStringInfoChar(result, '{');
	for (i = 1; i <= SPI_tuptable->tupdesc->natts; i++)
	{
		char	   *colname;
		Datum		colval;
		Oid			nspoid;
		Oid			tsql_datatype_oid;
		Oid			datatype_oid;
		char	   *typename;

		colname = SPI_fname(SPI_tuptable->tupdesc, i);

		if (!strcmp(colname, "\?column\?")) /* When column name or alias is
											 * not provided */
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("column expressions and data sources without names or aliases cannot be formatted as JSON text using FOR JSON clause. Add alias to the unnamed column or table")));
		}

		colval = SPI_getbinval(SPI_tuptable->vals[rownum],
							   SPI_tuptable->tupdesc,
							   i,
							   &isnull);

		if (isnull && !include_null_value)
			continue;

		datatype_oid = SPI_gettypeid(SPI_tuptable->tupdesc, i);
		typename = SPI_gettype(SPI_tuptable->tupdesc, i);
		nspoid = get_namespace_oid("sys", true);
		Assert(nspoid != InvalidOid);

		tsql_datatype_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));

		if (tsql_datatype_oid == datatype_oid)
		{
			/* check for bit datatype, and if so, change type to BOOL */
			if (strcmp(typename, "bit") == 0)
			{
				datatype_oid = BOOLOID;
			}

			/*
			 * convert datetime, smalldatetime, and datetime2 to appropriate
			 * text values, as T-SQL has a different text conversion than
			 * postgres.
			 */
			else if (strcmp(typename, "datetime") == 0 ||
					 strcmp(typename, "smalldatetime") == 0 ||
					 strcmp(typename, "datetime2") == 0)
			{
				char	   *val = SPI_getvalue(SPI_tuptable->vals[rownum], SPI_tuptable->tupdesc, i);
				StringInfo	format_output = makeStringInfo();

				for_json_datetime_format(format_output, val);
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
			}

			/*
			 * datetimeoffset has two behaviors: if offset is 0, just return
			 * the datetime with 'Z' at the end otherwise, append the offset
			 */
			else if (strcmp(typename, "datetimeoffset") == 0)
			{
				char	   *val = SPI_getvalue(SPI_tuptable->vals[rownum], SPI_tuptable->tupdesc, i);
				StringInfo	format_output = makeStringInfo();

				for_json_datetimeoffset_format(format_output, val);
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
			}
			/* convert money and smallmoney to numeric */
			else if (strcmp(typename, "money") == 0 ||
					 strcmp(typename, "smallmoney") == 0)
			{
				char	   *val = SPI_getvalue(SPI_tuptable->vals[rownum], SPI_tuptable->tupdesc, i);

				colval = DirectFunctionCall3(numeric_in, CStringGetDatum(val), ObjectIdGetDatum(InvalidOid), Int32GetDatum(-1));
				datatype_oid = NUMERICOID;
			}
		}


		appendStringInfoString(result, sep);
		sep = ",";
		tsql_json_build_object(result, CStringGetDatum(colname), colval, datatype_oid, isnull);

	}
	appendStringInfoChar(result, '}');
	if (rownum != SPI_processed - 1)
	{
		appendStringInfoString(result, ",");
	}
}

/*
 * Perform the operation based on the mode and directives in the input query
 */
static StringInfo
tsql_query_to_json_internal(const char *query, int mode, bool include_null_value,
							bool without_array_wrapper, const char *root_name)
{
	StringInfo result;
	uint64		i;

	set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	result = makeStringInfo();

	SPI_connect();
	if (SPI_execute(query, true, 0) != SPI_OK_SELECT)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("invalid query")));

	if (SPI_processed == 0)
	{
		SPI_finish();
		return NULL;
	}

	/*
	 * To check if query output table has columns with datatypes that are
	 * currently not supported in FOR JSON
	 */
	tsql_unsupported_datatype_check();

	/* If root_name is present then WITHOUT_ARRAY_WRAPPER will be FALSE */
	if (root_name)
		appendStringInfo(result, "{\"%s\":[", root_name);
	else if (!without_array_wrapper)
		appendStringInfoChar(result, '[');

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


	if (root_name)
		appendStringInfoString(result, "]}");
	else if (!without_array_wrapper)
		appendStringInfoChar(result, ']');
	return result;
}

/*
 * For now report an ERROR if any attribute is binary datatype since they are not implemented yet.
 */
static void
tsql_unsupported_datatype_check(void)
{
	for (int i = 1; i <= SPI_tuptable->tupdesc->natts; i++)
	{
		/*
		 * This part of code is a workaround for is_tsql_x_datatype() which
		 * does not work as expected. It compares the datatype oid of the
		 * columns with the tsql_datatype_oid and then throw feature not
		 * supported error based on the typename.
		 */
		Oid			tsql_datatype_oid;
		Oid			datatype_oid = SPI_gettypeid(SPI_tuptable->tupdesc, i);
		char	   *typename = SPI_gettype(SPI_tuptable->tupdesc, i);
		Oid			nspoid = get_namespace_oid("sys", true);

		Assert(nspoid != InvalidOid);

		tsql_datatype_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));

		/*
		 * tsql_datatype_oid can be different from datatype_oid when there are
		 * datatypes in different namespaces but with the same name. Examples:
		 * bigint, int, etc.
		 */
		if (tsql_datatype_oid == datatype_oid)
		{
			if (strcmp(typename, "binary") == 0 ||
				strcmp(typename, "varbinary") == 0 ||
				strcmp(typename, "image") == 0 ||
				strcmp(typename, "timestamp") == 0 ||
				strcmp(typename, "rowversion") == 0)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("binary types are not supported with FOR JSON")));
		}
	}
}

/*
 * This function handles the format for datetime datatypes by converting the output
 * into required format for SELECT FOR JSON PATH. For example:
 * "2022-11-11 20:56:22.41" -> "2022-11-11T20:56:22.41" for datetime, datetime2 & smalldatetime
 */
static void
for_json_datetime_format(StringInfo format_output, char *outputstr)
{
	char	   *date;
	char	   *spaceptr = strstr(outputstr, " ");
	int			len;

	len = spaceptr - outputstr;
	date = palloc(len + 1);
	strncpy(date, outputstr, len);
	date[len] = '\0';
	appendStringInfoString(format_output, date);
	appendStringInfoChar(format_output, 'T');
	appendStringInfoString(format_output, ++spaceptr);
}

/*
 * This function handles the format for datetimeoffset datatype by converting the output
 * into required format for SELECT FOR JSON PATH. For example:
 * "2022-11-11 22:25:01.015 +00:00" -> "2022-11-11T22:25:01.015Z"
 * "2022-11-11 12:34:56 +02:30" -> "2022-11-11T12:34:56+02:30"
 */
static void
for_json_datetimeoffset_format(StringInfo format_output, char *str)
{
	char	   *date,
			   *endptr,
			   *time,
			   *offset;
	char	   *spaceptr = strstr(str, " ");
	int			len;

	/* append date part of string */
	len = spaceptr - str;
	date = palloc(len + 1);
	strncpy(date, str, len);
	date[len] = '\0';
	appendStringInfoString(format_output, date);
	appendStringInfoChar(format_output, 'T');

	/* append time part of string */
	endptr = ++spaceptr;
	spaceptr = strstr(endptr, " ");
	len = spaceptr - endptr;
	time = palloc(len + 1);
	strncpy(time, endptr, len);
	time[len] = '\0';
	appendStringInfoString(format_output, time);

	/* append either timezone offset or Z if offset is 0 */
	offset = ++spaceptr;
	if (strcmp(offset, "+00:00") == 0)
	{
		appendStringInfoChar(format_output, 'Z');
	}
	else
	{
		appendStringInfoString(format_output, offset);
	}
}
