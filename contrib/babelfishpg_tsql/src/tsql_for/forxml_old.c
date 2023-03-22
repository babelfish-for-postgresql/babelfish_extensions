/*-------------------------------------------------------------------------
 *
 * forxml_old.c
 *   For XML clause support for Babel
 *
 * This implementation of FOR XML has been deprecated as of v2.4.0. However,
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
#include "utils/xml.h"

#include "tsql_for.h"

static xmltype *stringinfo_to_xmltype(StringInfo buf);
static void SPI_sql_row_to_xmlelement_raw(uint64 rownum, StringInfo result,
										  const char *element_name, bool binary_base64);
static void SPI_sql_row_to_xmlelement_path(uint64 rownum, StringInfo result,
										   const char *element_name, bool binary_base64);
static StringInfo tsql_query_to_xml_internal(const char *query, int mode,
											 const char *element_name, bool binary_base64,
											 const char *root_name);

PG_FUNCTION_INFO_V1(tsql_query_to_xml);
PG_FUNCTION_INFO_V1(tsql_query_to_xml_text);

static xmltype *
stringinfo_to_xmltype(StringInfo buf)
{
	return (xmltype *) cstring_to_text_with_len(buf->data, buf->len);
}

Datum
tsql_query_to_xml(PG_FUNCTION_ARGS)
{
	char	   *query = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			mode = PG_GETARG_INT32(1);
	char	   *element_name = PG_ARGISNULL(2) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(2));
	bool		binary_base64 = PG_GETARG_BOOL(3);
	char	   *root_name = PG_ARGISNULL(4) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(4));
	StringInfo result = tsql_query_to_xml_internal(query, mode,
												   element_name, binary_base64, root_name);

	ereport(WARNING,
			(errcode(ERRCODE_WARNING_DEPRECATED_FEATURE),
			 errmsg("This version of FOR XML has been deprecated. We recommend recreating the view for this query.")));

	PG_RETURN_XML_P(stringinfo_to_xmltype(result));
}

Datum
tsql_query_to_xml_text(PG_FUNCTION_ARGS)
{
	char	   *query = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			mode = PG_GETARG_INT32(1);
	char	   *element_name = PG_ARGISNULL(2) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(2));
	bool		binary_base64 = PG_GETARG_BOOL(3);
	char	   *root_name = PG_ARGISNULL(4) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(4));
	StringInfo result = tsql_query_to_xml_internal(query, mode,
												   element_name, binary_base64, root_name);

	ereport(WARNING,
			(errcode(ERRCODE_WARNING_DEPRECATED_FEATURE),
			 errmsg("This version of FOR XML has been deprecated. We recommend recreating the view for this query.")));

	PG_RETURN_TEXT_P(cstring_to_text_with_len(result->data, result->len));
}

/*
 * Map an SQL row to an XML element, taking the row from the active
 * SPI cursor. RAW mode, default element name is "row" if not specified.
 */
static void
SPI_sql_row_to_xmlelement_raw(uint64 rownum, StringInfo result,
							  const char *element_name, bool binary_base64)
{
	int			i;

	if (binary_base64)
	{
		/*
		 * TODO: encode binary/varbinary/image data values using base64
		 * encoding. Refer to how BYTEA type is handed in
		 * map_sql_value_to_xml_value(). Also, pg_b64_encode function might be
		 * useful. For now report an ERROR if any attribute is binary data
		 * type since base64 encoding is not implemented yet.
		 */
		for (i = 1; i <= SPI_tuptable->tupdesc->natts; i++)
		{
			char	   *typename = SPI_gettype(SPI_tuptable->tupdesc, i);

			if (strcmp(typename, "binary") == 0 ||
				strcmp(typename, "varbinary") == 0 ||
				strcmp(typename, "image") == 0)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("option binary base64 is not supported")));
		}
	}

	appendStringInfo(result, "<%s", element_name);

	for (i = 1; i <= SPI_tuptable->tupdesc->natts; i++)
	{
		char	   *colname;
		Datum		colval;
		bool		isnull;

		colname = map_sql_identifier_to_xml_name(SPI_fname(SPI_tuptable->tupdesc, i),
												 true, false);
		colval = SPI_getbinval(SPI_tuptable->vals[rownum],
							   SPI_tuptable->tupdesc,
							   i,
							   &isnull);
		if (!isnull)
		{
			appendStringInfo(result, " %s=\"%s\"",
							 colname,
							 map_sql_value_to_xml_value(colval,
														SPI_gettypeid(SPI_tuptable->tupdesc, i), true));
		}
	}

	appendStringInfoString(result, "/>");
}

/*
 * Map an SQL row to an XML element, taking the row from the active
 * SPI cursor. PATH mode, default element name is "row" if not specified.
 */
static void
SPI_sql_row_to_xmlelement_path(uint64 rownum, StringInfo result,
							   const char *element_name, bool binary_base64)
{
	int			i;
	bool		allnull = true;

	if (binary_base64)
	{
		/*
		 * TODO: encode binary/varbinary/image data values using base64
		 * encoding. Refer to how BYTEA type is handed in
		 * map_sql_value_to_xml_value(). Also, pg_b64_encode function might be
		 * useful. For now report an ERROR if any attribute is binary data
		 * type since base64 encoding is not implemented yet.
		 */
		for (i = 1; i <= SPI_tuptable->tupdesc->natts; i++)
		{
			char	   *typename = SPI_gettype(SPI_tuptable->tupdesc, i);

			if (strcmp(typename, "binary") == 0 ||
				strcmp(typename, "varbinary") == 0 ||
				strcmp(typename, "image") == 0)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("option binary base64 is not supported")));
		}
	}

	if (element_name[0] != '\0')
		/* if "''" is the input path, ignore it per SQL Server behavior */
				appendStringInfo(result, "<%s>", element_name);

	for (i = 1; i <= SPI_tuptable->tupdesc->natts; i++)
	{
		char	   *colname;
		Datum		colval;
		bool		isnull;

		colname = map_sql_identifier_to_xml_name(SPI_fname(SPI_tuptable->tupdesc, i),
												 true, false);
		colval = SPI_getbinval(SPI_tuptable->vals[rownum],
							   SPI_tuptable->tupdesc,
							   i,
							   &isnull);
		if (!isnull)
		{
			allnull = false;
			appendStringInfo(result, "<%s>%s</%s>",
							 colname,
							 map_sql_value_to_xml_value(colval,
														SPI_gettypeid(SPI_tuptable->tupdesc, i), true),
							 colname);
		}
	}

	if (allnull)
	{
		/*
		 * If all the column values are nulls, this element should be
		 * <element_name/>, modify the already appended <element_name> to
		 * <element_name/>.
		 */
		result	  ->data[result->len - 1] = '/';

		appendStringInfoString(result, ">");
	}
	else if (element_name[0] != '\0')
		appendStringInfo(result, "</%s>", element_name);
}

static StringInfo
tsql_query_to_xml_internal(const char *query, int mode,
						   const char *element_name, bool binary_base64,
						   const char *root_name)
{
	StringInfo result;
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

	if (root_name != NULL && strlen(root_name) > 0)
		appendStringInfo(result, "<%s>", root_name);
	if (element_name == NULL)
		element_name = "row";

	/*
	 * Format the query result according to the mode specified by the query.
	 */
	switch (mode)
	{
		case TSQL_FORXML_RAW:	/* FOR XML RAW */
			for (i = 0; i < SPI_processed; i++)
				SPI_sql_row_to_xmlelement_raw(i, result, element_name, binary_base64);
			break;
		case TSQL_FORXML_AUTO:

			/*
			 * TODO FOR XML AUTO: element_name should be set to relation name
			 * of the attribute value being processed, but relation id/name is
			 * not provided by SPI. We need to make relation id available in
			 * SPI_tuptable->tupdesc in order to support AUTO mode.
			 */
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("AUTO mode is not supported")));
			break;
		case TSQL_FORXML_PATH:	/* FOR XML PATH */
			for (i = 0; i < SPI_processed; i++)
				SPI_sql_row_to_xmlelement_path(i, result, element_name, binary_base64);
			break;
		case TSQL_FORXML_EXPLICIT:

			/*
			 * TODO: EXPLICIT mode is quite different from the other mode and
			 * is not supported yet.
			 */
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("EXPLICIT mode is not supported")));
			break;
		default:
			/* Invalid mode, should not happen, report internal error */
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("invalid FOR XML mode")));
	}

	if (root_name != NULL && strlen(root_name) > 0)
		appendStringInfo(result, "</%s>", root_name);
	SPI_finish();

	return result;
}
