/*-------------------------------------------------------------------------
 *
 * json_funcs.c
 *   JSON function support for Babelfish
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "common/jsonapi.h"
#include "catalog/pg_type.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "utils/json.h"
#include "utils/jsonb.h"
#include "utils/jsonfuncs.h"
#include "parser/parser.h"
#include "utils/jsonpath.h"
#include "utils/varlena.h"
#include "catalog/pg_collation_d.h"

Datum		tsql_jsonb_in(text *json_text);
Datum		tsql_jsonb_path_query_first(Datum jsonb_datum, Datum jsonpath_datum);
JsonParseErrorType tsql_parse_json(text *json_text, JsonLexContext *lex, JsonSemAction *sem);
static Datum tsql_openjson_with_internal(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(tsql_isjson);
PG_FUNCTION_INFO_V1(tsql_json_value);
PG_FUNCTION_INFO_V1(tsql_json_query);

/*
 * tsql_isjson()
 *
 * Returns 1 if the string contains valid JSON; otherwise, returns 0.
 *
 * Returns null if expression is null and does not return errors.
 */
Datum
tsql_isjson(PG_FUNCTION_ARGS)
{
	JsonParseErrorType result;
	JsonLexContext lex;
	text	   *json_text = PG_GETARG_TEXT_PP(0);

	/* set up lex context and parse json expression */
	makeJsonLexContext(&lex, json_text, false);
	result = tsql_parse_json(json_text, &lex, &nullSemAction);

	PG_RETURN_INT32((result == JSON_SUCCESS) ? 1 : 0);
}

/*
 * tsql_parse_json()
 *
 * Wrapper around PG json parser, pg_parse_json(), with additional logic
 * to handle edge case where input expression is bare scalar
 */
JsonParseErrorType
tsql_parse_json(text *json_text, JsonLexContext *lex, JsonSemAction *sem)
{
	JsonParseErrorType result_first_token;
	JsonLexContext lex_first_token;
	JsonTokenType tok;

	/* Short circuit when first token is scalar */
	makeJsonLexContext(&lex_first_token, json_text, false);
	result_first_token = json_lex(&lex_first_token);
	tok = lex_first_token.token_type;
	if (result_first_token != JSON_SUCCESS ||
		(tok != JSON_TOKEN_OBJECT_START && tok != JSON_TOKEN_ARRAY_START))
		return JSON_EXPECTED_JSON;

	/* validate rest of json expression */
	return pg_parse_json(lex, sem);
}

/*
 * tsql_jsonb_in
 *
 * Turns json string into a jsonb Datum.
 *
 * Uses the json parser (with hooks) to construct a jsonb.
 */
Datum
tsql_jsonb_in(text *json_text)
{
	JsonParseErrorType result_first_token;
	JsonLexContext lex_first_token;
	JsonTokenType tok;

	/* Short circuit when first token is scalar */
	makeJsonLexContext(&lex_first_token, json_text, false);
	result_first_token = json_lex(&lex_first_token);
	tok = lex_first_token.token_type;
	if (result_first_token != JSON_SUCCESS ||
		(tok != JSON_TOKEN_OBJECT_START && tok != JSON_TOKEN_ARRAY_START))
		json_errsave_error(result_first_token, &lex_first_token, NULL);

	/* convert json expression to jsonb */
	return DirectFunctionCall1(jsonb_in, CStringGetDatum(text_to_cstring(json_text)));
}

/*
 * tsql_json_value()
 *
 * Extracts a scalar value from a json expression string
 *
 * 'json_text' - target document for jsonpath evaluation
 * 'jsonpath_text' - jsonpath to be executed
 */
Datum
tsql_json_value(PG_FUNCTION_ARGS)
{

	text	   *json_text,
			   *jsonpath_text;
	char	   *result_cstring;
	Datum result ,
				jsonb,
				jsonpath;
	Jsonb	   *result_jsonb;
	VarChar    *result_varchar;
	bool		islax;
	int			prev_sql_dialect;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();
	if (PG_ARGISNULL(1))
		elog(ERROR, "The JSON_VALUE function requires 2 arguments");

	/* read in arguments */
	json_text = PG_GETARG_TEXT_PP(0);
	jsonb = tsql_jsonb_in(json_text);
	jsonpath_text = PG_GETARG_TEXT_PP(1);
	jsonpath = DirectFunctionCall1(jsonpath_in, CStringGetDatum(text_to_cstring(jsonpath_text)));

	/*
	 * set sql_dialect to tsql, which is needed for jsonb parsing and
	 * processing
	 */
	prev_sql_dialect = sql_dialect;
	sql_dialect = SQL_DIALECT_TSQL;

	/* jsonb_path_query_first */
	result = tsql_jsonb_path_query_first(jsonb, jsonpath);

	/* reset sql_dialect */
	sql_dialect = prev_sql_dialect;

	/* Check for null result */
	if (!result)
		PG_RETURN_NULL();

	islax = (DatumGetJsonPathP(jsonpath)->header & JSONPATH_LAX) != 0;
	result_jsonb = DatumGetJsonbP(result);
	/* check value is scalar */
	if (result_jsonb && JB_ROOT_IS_SCALAR(result_jsonb))
	{
		/* handle cases where value is greater than 4000 characters */
		result_cstring = JsonbToCString(NULL, &result_jsonb->root, -1);
		if (strlen(result_cstring) > 4000)
		{
			if (islax)
				PG_RETURN_NULL();
			else
				elog(ERROR, "The JSON_VALUE function requires 2 arguments");
		}

		/*
		 * trim double quotes on json string values which are added by
		 * JsonbToCString()
		 */
		if (strlen(result_cstring) > 1 && result_cstring[0] == '\"')
			result_varchar = (VarChar *) cstring_to_text_with_len(result_cstring + 1, strlen(result_cstring) - 2);
		else
			result_varchar = (VarChar *) cstring_to_text(result_cstring);
		PG_RETURN_VARCHAR_P(result_varchar);
	}
	/* result is not a scalar value */
	else if (!islax)
		elog(ERROR, "Scalar value cannot be found in the specified JSON path.");

	PG_RETURN_NULL();
}

/*
 * tsql_json_query()
 *
 * Extracts a json object or array from a json expression string
 *
 * 'json_text' - target document for jsonpath evaluation
 * 'jsonpath_text' - jsonpath to be executed
 */
Datum
tsql_json_query(PG_FUNCTION_ARGS)
{
	text	   *json_text,
			   *jsonpath_text;
	Datum result ,
				jsonb,
				jsonpath;
	Jsonb	   *result_jsonb;
	VarChar    *result_varchar;
	bool		islax;
	int			prev_sql_dialect;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	/*
	 * set sql_dialect to tsql, which is needed for jsonb parsing and
	 * processing
	 */
	prev_sql_dialect = sql_dialect;
	sql_dialect = SQL_DIALECT_TSQL;

	/* read in arguments */
	json_text = PG_GETARG_TEXT_PP(0);
	jsonb = tsql_jsonb_in(json_text);
	jsonpath_text = PG_ARGISNULL(1) ? cstring_to_text("$") : PG_GETARG_TEXT_PP(1);
	jsonpath = DirectFunctionCall1(jsonpath_in, CStringGetDatum(text_to_cstring(jsonpath_text)));

	/* jsonb_path_query_first */
	result = tsql_jsonb_path_query_first(jsonb, jsonpath);

	/* reset sql_dialect */
	sql_dialect = prev_sql_dialect;

	/* Check for null result */
	if (!result)
		PG_RETURN_NULL();

	islax = (DatumGetJsonPathP(jsonpath)->header & JSONPATH_LAX) != 0;
	result_jsonb = DatumGetJsonbP(result);
	/* check if value is json object or array */
	if (result_jsonb
		&& !JB_ROOT_IS_SCALAR(result_jsonb)
		&& (JB_ROOT_IS_OBJECT(result_jsonb) || JB_ROOT_IS_ARRAY(result_jsonb)))
	{
		result_varchar = (VarChar *) cstring_to_text(JsonbToCString(NULL, &result_jsonb->root, -1));
		PG_RETURN_VARCHAR_P(result_varchar);
	}
	/* result is not an array or object */
	else if (!islax)
		elog(ERROR, "Object or array cannot be found in the specified JSON path.");

	PG_RETURN_NULL();
}

Datum
tsql_jsonb_path_query_first(Datum jsonb_datum, Datum jsonpath_datum)
{
	LOCAL_FCINFO(fcinfo, 4);
	Datum result ,
				vars;

	vars = DirectFunctionCall1(jsonb_in, CStringGetDatum("{}"));

	InitFunctionCallInfoData(*fcinfo, NULL, 4, PG_GET_COLLATION(), NULL, NULL);

	fcinfo->args[0].value = jsonb_datum;
	fcinfo->args[0].isnull = false;
	fcinfo->args[1].value = jsonpath_datum;
	fcinfo->args[1].isnull = false;
	fcinfo->args[2].value = vars;
	fcinfo->args[2].isnull = false;
	fcinfo->args[3].value = false;
	fcinfo->args[3].isnull = false;

	result = (*jsonb_path_query_first) (fcinfo);

	return result;
}

PG_FUNCTION_INFO_V1(tsql_openjson_with);

Datum
tsql_openjson_with(PG_FUNCTION_ARGS)
{
	return tsql_openjson_with_internal(fcinfo);
}

/*
 * tsql_openjson_with
 *     Executes jsonpath for each column definition passed and returns result as a rowset.
 */
static Datum
tsql_openjson_with_internal(PG_FUNCTION_ARGS)
{
	FuncCallContext *funcctx;
	int			call_cntr;
	int			max_calls;
	TupleDesc	tupdesc;
	AttInMetadata *attinmeta;

	/*
	 * column_list is a list of lists - each contained list corresponds to a
	 * column in the return set
	 */
	List	   *column_list;

	if (SRF_IS_FIRSTCALL())
	{
		int			prev_sql_dialect;
		MemoryContext oldcontext;

		funcctx = SRF_FIRSTCALL_INIT();
		prev_sql_dialect = sql_dialect;
		PG_TRY();
		{
			Jsonb	   *sub_jb;
			ArrayType  *arr;
			int			ndim;

			/*
			 * set sql_dialect to tsql, which is needed for jsonb parsing and
			 * processing
			 */
			sql_dialect = SQL_DIALECT_TSQL;
			oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

			/*
			 * Get information about return type. Used to build return message
			 * later.
			 */
			if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("function returning record called in context "
								"that cannot accept type record")));

			sub_jb = tsql_openjson_with_get_subjsonb(fcinfo);

			/* read in column definitions */
			arr = PG_GETARG_ARRAYTYPE_P(2);

			/* Deconstruct column info array */
			ndim = ARR_NDIM(arr);
			if (ndim > 1)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("array must be one-dimensional")));
			else if (array_contains_nulls(arr))
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("array must not contain nulls")));
			else if (ndim == 1)
			{
				/* generate rowsets for each column path */
				Datum	   *datum_opts;
				int			nelems;

				Assert(ARR_ELEMTYPE(arr) == TEXTOID);

				deconstruct_array(arr, TEXTOID, -1, false, TYPALIGN_INT,
								  &datum_opts, NULL, &nelems);

				max_calls = 0;
				column_list = NIL;

				for (int i = 0; i < nelems; i++)
				{
					char	   *col_info = TextDatumGetCString(datum_opts[i]);
					List	   *list = tsql_openjson_with_columnize(sub_jb, col_info);

					column_list = lappend(column_list, list);

					if (list && list->length > max_calls)
						max_calls = list->length;
				}
				funcctx->user_fctx = column_list;
				funcctx->max_calls = max_calls;
			}
			attinmeta = TupleDescGetAttInMetadata(tupdesc);
			funcctx->attinmeta = attinmeta;
		}
		PG_FINALLY();
		{
			sql_dialect = prev_sql_dialect;
			MemoryContextSwitchTo(oldcontext);
		}
		PG_END_TRY();
	}

	funcctx = SRF_PERCALL_SETUP();
	column_list = funcctx->user_fctx;
	call_cntr = funcctx->call_cntr;
	max_calls = funcctx->max_calls;
	attinmeta = funcctx->attinmeta;
	if (call_cntr < max_calls && column_list != NULL)
	{
		char	  **values;
		ListCell   *lc;
		HeapTuple	tuple;
		Datum result;

		values = palloc0(sizeof(char *) * column_list->length);

		/*
		 * go through each column list and add its result to the current tuple
		 * to be returned
		 */
		foreach(lc, column_list)
		{
			int			i = foreach_current_index(lc);
			List	   *column = lfirst(lc);

			if (column)
				values[i] = linitial(column);
			lc->ptr_value = list_delete_first(column);	/* update each column to
														 * the next result for
														 * the next iteration */
		}
		tuple = BuildTupleFromCStrings(attinmeta, values);
		result = HeapTupleGetDatum(tuple);

		SRF_RETURN_NEXT(funcctx, result);
	}
	else
	{
		SRF_RETURN_DONE(funcctx);
	}
}
