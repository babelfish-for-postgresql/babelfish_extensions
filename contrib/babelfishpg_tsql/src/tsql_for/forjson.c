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
#include "utils/syscache.h"
#include "utils/typcache.h"
#include "catalog/pg_type.h"
#include "catalog/namespace.h"

#include "tsql_for.h"

static void tsql_row_to_json(StringInfo state, Datum record, bool include_null_values);

PG_FUNCTION_INFO_V1(tsql_query_to_json_sfunc);

Datum
tsql_query_to_json_sfunc(PG_FUNCTION_ARGS)
{
	StringInfo	state;
	Datum		record;
	int			mode;
	bool		include_null_values;
	bool		without_array_wrapper;
	char		*root_name;
	for (int i=1; i < PG_NARGS()-1; i++)
	{
		if PG_ARGISNULL(i) 
			PG_RETURN_NULL();
	}
	state = makeStringInfo();
	record = PG_GETARG_DATUM(1);
	mode = PG_GETARG_INT32(2);
	include_null_values = PG_GETARG_BOOL(3);
	without_array_wrapper = PG_GETARG_BOOL(4);
	root_name = PG_ARGISNULL(5) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(5));
	if (PG_ARGISNULL(0))
	{
		/* first time setup */
		/* If root_name is present then WITHOUT_ARRAY_WRAPPER will be FALSE */
		if(root_name)
			/* we need to add an extra token to the beginning so that the finalfunc knows to append "]}" to the end */
			appendStringInfo(state, "<{\"%s\":[", root_name);
		else if (!without_array_wrapper)
			appendStringInfoChar(state,'[');
	}
	else
	{
		appendStringInfoString(state, TextDatumGetCString(PG_GETARG_TEXT_PP(0)));
		appendStringInfoChar(state, ',');
	}
	switch (mode)
	{
		case TSQL_FORJSON_AUTO:
			/*
			 * TODO FOR JSON AUTO: if there are joined tables, we need to know
			 * which table a particular column came from, but that is currently
			 * not accessible within the aggregate function.
			 */
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						errmsg("AUTO mode is not supported")));
			break;
		case TSQL_FORJSON_PATH: /* FOR JSON PATH */
			/* add the current row to the state */
			tsql_row_to_json(state, record, include_null_values);
			break;
		default:
			/* Invalid mode, should not happen, report internal error */
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
						errmsg("invalid FOR JSON mode")));
	}

	PG_RETURN_TEXT_P(cstring_to_text_with_len(state->data, state->len));
}

static void 
tsql_row_to_json(StringInfo state, Datum record, bool include_null_values)
{
	HeapTupleHeader td;
	Oid				tupType;
	int32			tupTypmod;
	TupleDesc		tupdesc;
	HeapTupleData 	tmptup;
	HeapTuple		tuple;
	char  			*sep="";

	td = DatumGetHeapTupleHeader(record);

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;
	
	/* each tuple is its own object */
	appendStringInfoChar(state,'{');

	/* process the tuple into key/value pairs */
	for (int i = 0; i < tupdesc->natts; i++)
	{
		char	*colname;
		Datum	colval;
		bool 	isnull;
		Oid 	datatype_oid;
		Oid 	nspoid;
		Oid 	tsql_datatype_oid;
		char	*typename;
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);

		if (att->attisdropped)
			continue;
		
		colname = NameStr(att->attname);
		
		if (!strcmp(colname,"\?column\?")) /* When column name or alias is not provided */
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("column expressions and data sources without names or aliases cannot be formatted as JSON text using FOR JSON clause. Add alias to the unnamed column or table")));
		}
		
		colval = heap_getattr(tuple, i + 1, tupdesc, &isnull);

		if (isnull && !include_null_values)
			continue;

		/* 
		 * Below is a workaround for is_tsql_x_datatype() which does not work as expected.
		 * We compare the datatype oid of the columns with the tsql_datatype_oid and
		 * then specially handle some TSQL-specific datatypes.
		 */
		datatype_oid = att->atttypid;
		typename = SPI_gettype(tupdesc, i+1);
		nspoid = get_namespace_oid("sys", true);
		Assert(nspoid != InvalidOid);

		tsql_datatype_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));
		
		/*
		 * tsql_datatype_oid can be different from datatype_oid when there are datatypes in different namespaces
		 * but with the same name. Examples: bigint, int, etc.
		 */
		if (tsql_datatype_oid == datatype_oid)
		{
			/* binary datatypes are not supported */
			if (strcmp(typename, "binary") == 0 ||
				strcmp(typename, "varbinary") == 0 ||
				strcmp(typename, "image") == 0 ||
				strcmp(typename, "timestamp") == 0 ||
				strcmp(typename, "rowversion") == 0)
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								errmsg("binary types are not supported with FOR JSON")));
			/* check for bit datatype, and if so, change type to BOOL */
			if (strcmp(typename, "bit")  == 0)
			{
				datatype_oid = BOOLOID;
			}
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
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
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
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
			}
			/* convert money and smallmoney to numeric */
			else if (strcmp(typename, "money") == 0 ||
				strcmp(typename, "smallmoney") == 0)
			{
				char *val = SPI_getvalue(tuple, tupdesc, i+1);
				colval = DirectFunctionCall3(numeric_in, CStringGetDatum(val), ObjectIdGetDatum(InvalidOid), Int32GetDatum(-1));
				datatype_oid = NUMERICOID;
			}
		}

		appendStringInfoString(state,sep);
		sep = ",";
		tsql_json_build_object(state, CStringGetDatum(colname), colval, datatype_oid, isnull);

	}
	appendStringInfoChar(state,'}');
}
