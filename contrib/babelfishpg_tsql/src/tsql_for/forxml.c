/*-------------------------------------------------------------------------
 *
 * forxml.c
 *   For XML clause support for Babel
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
#include "utils/syscache.h"
#include "utils/typcache.h"
#include "catalog/pg_type.h"
#include "catalog/namespace.h"

#include <regex.h>

#include "tsql_for.h"

static StringInfo for_xml_ffunc(PG_FUNCTION_ARGS);
static void tsql_row_to_xml_raw(StringInfo state, Datum record, const char* element_name, bool binary_base64);
static void tsql_row_to_xml_path(StringInfo state, Datum record, const char* element_name, bool binary_base64);
static void update_tsql_datatype_and_val(HeapTuple tuple, TupleDesc tupdesc, Oid *datatype_oid, Datum *colval, bool binary_base64, int i);

PG_FUNCTION_INFO_V1(tsql_query_to_xml_sfunc);

Datum
tsql_query_to_xml_sfunc(PG_FUNCTION_ARGS)
{
	StringInfo	state;
	Datum		record = PG_GETARG_DATUM(1);
	int			mode = PG_GETARG_INT32(2);
	char		*element_name = PG_ARGISNULL(3) ? "row" : text_to_cstring(PG_GETARG_TEXT_PP(3));
	bool		binary_base64 = PG_GETARG_BOOL(4);
	char		*root_name;
	
	MemoryContext agg_context;
	MemoryContext old_context;
	if (!AggCheckCallContext(fcinfo, &agg_context))
		elog(ERROR, "aggregate function called in non-aggregate context");
	old_context = MemoryContextSwitchTo(agg_context);

	if (PG_ARGISNULL(0))
	{
		/* first time setup */
		state = makeStringInfo();
		root_name = PG_ARGISNULL(5) ? NULL :  text_to_cstring(PG_GETARG_TEXT_PP(5));
		if (root_name != NULL && strlen(root_name) > 0)
			/* we need to add an extra token to the beginning so that the finalfunc knows there is a root element */
			appendStringInfo(state, "{<%s>", root_name);
	}
	else
	{
		state = (StringInfo) PG_GETARG_POINTER(0);
	}
	switch (mode)
	{
		case TSQL_FORXML_RAW: /* FOR XML RAW */
			tsql_row_to_xml_raw(state, record, element_name, binary_base64);
			break;
		case TSQL_FORXML_AUTO:
			/*
			 * TODO FOR XML AUTO: element_name should be set to relation name of the attribute
			 * value being processed, but relation id/name is not provided by aggregate functions. We need to make
			 * relation id available in aggregate functions in order to support AUTO mode.
			 */
			ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("AUTO mode is not supported")));
			break;
		case TSQL_FORXML_PATH: /* FOR XML PATH */
			tsql_row_to_xml_path(state, record, element_name, binary_base64);
			break;
		case TSQL_FORXML_EXPLICIT:
			/*
			 * TODO: EXPLICIT mode is quite different from the other mode and is
			 * not supported yet.
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

	MemoryContextSwitchTo(old_context);

	PG_RETURN_POINTER(state);
}

PG_FUNCTION_INFO_V1(tsql_query_to_xml_ffunc);

Datum
tsql_query_to_xml_ffunc(PG_FUNCTION_ARGS)
{
	StringInfo res = for_xml_ffunc(fcinfo);
	PG_RETURN_XML_P((xmltype *) cstring_to_text_with_len(res->data, res->len));
}

PG_FUNCTION_INFO_V1(tsql_query_to_xml_text_ffunc);

Datum
tsql_query_to_xml_text_ffunc(PG_FUNCTION_ARGS)
{
	StringInfo res = for_xml_ffunc(fcinfo);
	PG_RETURN_TEXT_P(cstring_to_text_with_len(res->data, res->len));
}

static StringInfo
for_xml_ffunc(PG_FUNCTION_ARGS)
{
	StringInfo	res = makeStringInfo();
	char		*state = ((StringInfo) PG_GETARG_POINTER(0))->data;
	if (state[0] == '{') /* '{' indicates that root was specified, so add the corresponding end tag */
	{
		/* set up regex to match first tag */
		char		*pattern = "<([^\\/>]+)[\\/]*>";
		regex_t		preg;
		regmatch_t	match, pmatch[1];
		char		*root = palloc(1024);
		int			len;
		
		if (regcomp(&preg, pattern, REG_EXTENDED) != 0)
			ereport(ERROR,
						(errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("unexpected error parsing xml root tag")));
		
		if (regexec(&preg, state, 1, pmatch, 0) != 0)
			ereport(ERROR,
						(errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("unexpected error parsing xml root tag")));
						
		match = pmatch[0];
		len = match.rm_eo - match.rm_so - 1;
		if (len >= 1024)
		{
			ereport(WARNING,
							(errcode(ERRCODE_WARNING_STRING_DATA_RIGHT_TRUNCATION),
								errmsg("root name too long and will be truncated at the end tag")));
		}
		len = len >= 1024 ? 1023 : len;
		
		pg_snprintf(root, len, "%s", state + match.rm_so+1);
		root[len] = '\0';

		/* add the state (minus the '{') in along with the end tag for the root */
		appendStringInfo(res, "%s</%s>", state+1, root);
	}
	else
	{
		appendStringInfoString(res, state);
	}
	return res;
}

/*
 * Map an SQL row to an XML element in RAW mode.
 */
static void
tsql_row_to_xml_raw(StringInfo state, Datum record, const char* element_name, bool binary_base64)
{
	HeapTupleHeader td;
	Oid				tupType;
	int32			tupTypmod;
	TupleDesc		tupdesc;
	HeapTupleData 	tmptup;
	HeapTuple		tuple;

	td = DatumGetHeapTupleHeader(record);

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;

	/* each tuple is its own tag in raw mode */
	appendStringInfo(state, "<%s", element_name);

	/* process the tuple into attributes */
	for (int i = 0; i < tupdesc->natts; i++)
	{
		char	*colname;
		Datum	colval;
		bool	isnull;
		Oid 	datatype_oid;
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);

		if (att->attisdropped)
			continue;

		colname = map_sql_identifier_to_xml_name(NameStr(att->attname), true, false);
		colval = heap_getattr(tuple, i + 1, tupdesc, &isnull);
		datatype_oid = att->atttypid;

		update_tsql_datatype_and_val(tuple, tupdesc, &datatype_oid, &colval, binary_base64, i);

		if (!isnull)
		{
			appendStringInfo(state, " %s=\"%s\"",
							 colname,
							 map_sql_value_to_xml_value(colval, datatype_oid, true));
		}
	}
	appendStringInfoString(state, "/>");
}

/*
 * Map an SQL row to an XML element in PATH mode.
 */
static void
tsql_row_to_xml_path(StringInfo state, Datum record, const char* element_name, bool binary_base64)
{
	HeapTupleHeader td;
	Oid				tupType;
	int32			tupTypmod;
	TupleDesc		tupdesc;
	HeapTupleData 	tmptup;
	HeapTuple		tuple;
	bool 			allnull = true;

	td = DatumGetHeapTupleHeader(record);

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;

	/* each tuple is either contained in a "row" tag, or standalone if the element_name is an empty string */
	if (element_name[0] != '\0') // if "''" is the input path, ignore it per SQL Server behavior
		appendStringInfo(state, "<%s>", element_name);

	/* process the tuple into tags */
	for (int i = 0; i < tupdesc->natts; i++)
	{
		char	*colname;
		Datum	colval;
		bool	isnull;
		Oid 	datatype_oid;
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);

		if (att->attisdropped)
			continue;

		colname = map_sql_identifier_to_xml_name(NameStr(att->attname), true, false);
		colval = heap_getattr(tuple, i + 1, tupdesc, &isnull);
		datatype_oid = att->atttypid;

		update_tsql_datatype_and_val(tuple, tupdesc, &datatype_oid, &colval, binary_base64, i);

		if (!isnull)
		{
			allnull = false;
			appendStringInfo(state, "<%s>%s</%s>",
							 colname,
							 map_sql_value_to_xml_value(colval, datatype_oid, true),
							 colname);
		}
	}

	if (allnull)
	{
		/*
		 * If all the column values are nulls, this element should be <element_name/>,
		 * modify the already appended <element_name> to <element_name/>.
		 */
		state->data[state->len-1] = '/';
		appendStringInfoString(state, ">");
	}
	else if (element_name[0] != '\0')
		appendStringInfo(state, "</%s>", element_name);
}

static void
update_tsql_datatype_and_val(HeapTuple tuple, TupleDesc tupdesc, Oid *datatype_oid, Datum *colval, bool binary_base64, int i)
{
	char	*typename;
	Oid		nspoid, tsql_datatype_oid;

	/* 
	 * Below is a workaround for is_tsql_x_datatype() which does not work as expected.
	 * We compare the datatype oid of the columns with the tsql_datatype_oid and
	 * then specially handle some TSQL-specific datatypes.
	 */
	typename = SPI_gettype(tupdesc, i+1);
	nspoid = get_namespace_oid("sys", true);
	Assert(nspoid != InvalidOid);

	tsql_datatype_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));

	/*
	 * tsql_datatype_oid can be different from datatype_oid when there are datatypes in different namespaces
	 * but with the same name. Examples: bigint, int, etc.
	 */
	if (tsql_datatype_oid == *datatype_oid)
	{
		/* binary datatypes are not supported */
		if (binary_base64 &&
			(strcmp(typename, "binary") == 0 ||
			strcmp(typename, "varbinary") == 0 ||
			strcmp(typename, "image") == 0 ||
			strcmp(typename, "timestamp") == 0 ||
			strcmp(typename, "rowversion") == 0))
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("option binary base64 is not supported")));
		/*
		 * convert datetime, smalldatetime, and datetime2 to appropriate text values, 
		 * as T-SQL has a different text conversion than postgres.
		 */
		else if (strcmp(typename, "datetime")  == 0 ||
			strcmp(typename, "smalldatetime") == 0 ||
			strcmp(typename, "datetime2") == 0)
		{
			char *val = SPI_getvalue(tuple, tupdesc, i+1);
			StringInfo format_output = makeStringInfo();
			tsql_for_datetime_format(format_output, val);
			*colval = CStringGetDatum(format_output->data);

			*datatype_oid = CSTRINGOID;
		}
		/*
		 * datetimeoffset has two behaviors:
		 * if offset is 0, just return the datetime with 'Z' at the end
		 * otherwise, append the offset
		 */
		else if (strcmp(typename, "datetimeoffset") == 0)
		{
			char *val = SPI_getvalue(tuple, tupdesc, i+1);
			StringInfo format_output = makeStringInfo();
			tsql_for_datetimeoffset_format(format_output, val);
			*colval = CStringGetDatum(format_output->data);

			*datatype_oid = CSTRINGOID;
		}
	}
}
