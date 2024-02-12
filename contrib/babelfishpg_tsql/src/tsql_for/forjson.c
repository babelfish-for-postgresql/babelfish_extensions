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
#include "utils/jsonb.h"
#include "utils/syscache.h"
#include "utils/typcache.h"
#include "utils/hsearch.h"
#include "catalog/pg_type.h"
#include "catalog/namespace.h"

#include "tsql_for.h"

#define TABLE_SIZE 100

// For holding information regarding the state of the FOR JSON call
// Necessary to pass information regarding root_name & without_array-wrappers
// to ffunc. 
typedef struct {
	bool without_array_wrapper;
	char *root_name;
	JsonbValue* jsonbArray;
} forjson_state;

// Entry struct for use in HashTable
typedef struct {
	char path[NAMEDATALEN];
	JsonbValue *value;
	JsonbValue *parent;
	int idx;
} JsonbEntry;

static void tsql_row_to_json(JsonbValue* jsonbArray, Datum record, bool include_null_values);

static void tsql_auto_row_to_json(JsonbValue* jsonbArray, Datum record, bool include_null_values);

static char** determine_parts(const char* str, int *num);

char* remove_index_and_alias(const char* str);

static char* build_key(char **parts, int currentIdx);

static JsonbValue* create_json(char *part, JsonbValue* val, int *idx);

static JsonbValue* create_json_array(char *arrayKey, char* pairKey, JsonbValue* pairVal, int *idx);

static void insert_existing_json(JsonbValue *exists, JsonbValue* parent, JsonbValue *val, int idx, char *key);

static void insert_existing_json_to_obj(JsonbValue *exists, JsonbValue* parent, JsonbValue *val, int idx, char *key);

static void checkForDuplicateRows(JsonbValue *jsonbArray, JsonbValue* row, int maxDepth, int currDepth, int* minInsertDepth);

static int compareNumeric(Numeric a, Numeric b);

PG_FUNCTION_INFO_V1(tsql_query_to_json_sfunc);

Datum
tsql_query_to_json_sfunc(PG_FUNCTION_ARGS)
{
	forjson_state 	*state;
	JsonbValue  	*jsonbArray;
	
	Datum		record;
	int		mode;
	bool		include_null_values;
	bool		without_array_wrapper;
	char	   	*root_name;

	MemoryContext agg_context;
	MemoryContext old_context;

	if (!AggCheckCallContext(fcinfo, &agg_context))
		elog(ERROR, "aggregate function called in non-aggregate context");
	old_context = MemoryContextSwitchTo(agg_context);

	for (int i = 1; i < PG_NARGS() - 1; i++)
	{
		/*
		 * only state and root_name can be null, so check the other params for
		 * safety
		 */
		if (PG_ARGISNULL(i))
				PG_RETURN_NULL();
	}
	record = PG_GETARG_DATUM(1);
	mode = PG_GETARG_INT32(2);
	include_null_values = PG_GETARG_BOOL(3);
	if (PG_ARGISNULL(0))
	{
		// First time setup for struct & JsonBValue
		state = (forjson_state *) palloc(sizeof(forjson_state));

		jsonbArray = palloc(sizeof(JsonbValue));
		jsonbArray->type = jbvArray;
		jsonbArray->val.array.nElems = 0;
		jsonbArray->val.array.rawScalar = false;
		jsonbArray->val.array.elems = (JsonbValue *) palloc(sizeof(JsonbValue));
		
		// Populate the struct
		without_array_wrapper = PG_GETARG_BOOL(4);
		root_name = PG_ARGISNULL(5) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(5));

		state->jsonbArray = jsonbArray;
		state->without_array_wrapper = without_array_wrapper;
		state->root_name = root_name;
	}
	else
	{
		state = (forjson_state*) PG_GETARG_POINTER(0);
		jsonbArray = state->jsonbArray;
	}
	switch (mode)
	{
		case TSQL_FORJSON_AUTO:
			tsql_auto_row_to_json(jsonbArray, record, include_null_values);
			break;
		case TSQL_FORJSON_PATH: /* FOR JSON PATH */
			/* add the current row to the state */
			tsql_row_to_json(jsonbArray, record, include_null_values);
			break;
		default:
			/* Invalid mode, should not happen, report internal error */
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("invalid FOR JSON mode")));
	}

	MemoryContextSwitchTo(old_context);
	PG_RETURN_POINTER(state);
}

// Main row to json function. 
// Creates a Jsonb row object, processes the row, determines if it should be inserted as a nested json object
// inserts json object to row and then into the main jsonbArray.
static void
tsql_auto_row_to_json(JsonbValue* jsonbArray, Datum record, bool include_null_values)
{
	// HashTable
	HTAB	   *jsonbHash;
	HASHCTL		ct;

	// JsonbValue for the row
	JsonbValue *jsonbRow;

	HeapTupleHeader td;
	Oid			tupType;
	int32		tupTypmod;
	TupleDesc	tupdesc;
	HeapTupleData tmptup;
	HeapTuple	tuple;
	int maxDepth = -1;
	int minInsertDepth;

	td = DatumGetHeapTupleHeader(record);

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;

	// Initialize the JsonbValue for the row
	jsonbRow = palloc(sizeof(JsonbValue));
	jsonbRow->type = jbvObject;
	jsonbRow->val.object.nPairs = 0;
	jsonbRow->val.object.pairs = palloc(sizeof(JsonbPair) * tupdesc->natts);

	// Initialize the hashTable to hold information regarding the nested json objects within the row
	memset(&ct, 0, sizeof(ct));
	ct.keysize = NAMEDATALEN;
	ct.entrysize = sizeof(JsonbEntry);
	jsonbHash = hash_create("JsonbHash", TABLE_SIZE, &ct, HASH_ELEM | HASH_STRINGS);

	/* process the tuple into key/value pairs */
	for (int i = 0; i < tupdesc->natts; i++)
	{
		// Pair object that holds key-value
		JsonbValue  *key; 
		JsonbValue  *value;
		JsonbPair	*jsonbPair;	

		// Used for nested json Objects
		JsonbEntry  *hashEntry;
		JsonbValue  *nestedVal;	
		JsonbValue  *current;
		char       **parts;
		int 		num;
		bool		found;
		char		*hashKey;

		char	   *colname;
		Datum		colval;
		bool		isnull;
		Oid			datatype_oid;
		Oid			nspoid;
		Oid			tsql_datatype_oid;
		char	   *typename;

		Form_pg_attribute att = TupleDescAttr(tupdesc, i);

		if (att->attisdropped)
			continue;

		colname = NameStr(att->attname);

		if (!strcmp(colname, "\?column\?")) /* When column name or alias is
											 * not provided */
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("column expressions and data sources without names or aliases cannot be formatted as JSON text using FOR JSON clause. Add alias to the unnamed column or table")));
		}

		colval = heap_getattr(tuple, i + 1, tupdesc, &isnull);

		if (isnull && !include_null_values)
			continue;

		/*
		 * Below is a workaround for is_tsql_x_datatype() which does not work
		 * as expected. We compare the datatype oid of the columns with the
		 * tsql_datatype_oid and then specially handle some TSQL-specific
		 * datatypes.
		 */
		datatype_oid = att->atttypid;
		typename = SPI_gettype(tupdesc, i + 1);
		nspoid = get_namespace_oid("sys", true);
		Assert(nspoid != InvalidOid);

		tsql_datatype_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));

		/*
		 * tsql_datatype_oid can be different from datatype_oid when there are
		 * datatypes in different namespaces but with the same name. Examples:
		 * bigint, int, etc.
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
				char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);
				StringInfo	format_output = makeStringInfo();

				tsql_for_datetime_format(format_output, val);
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
			}

			/*
			 * datetimeoffset has two behaviors: if offset is 0, just return
			 * the datetime with 'Z' at the end otherwise, append the offset
			 */
			else if (strcmp(typename, "datetimeoffset") == 0)
			{
				char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);
				StringInfo	format_output = makeStringInfo();

				tsql_for_datetimeoffset_format(format_output, val);
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
			}
			/* convert money and smallmoney to numeric */
			else if (strcmp(typename, "money") == 0 ||
					 strcmp(typename, "smallmoney") == 0)
			{
				char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);

				colval = DirectFunctionCall3(numeric_in, CStringGetDatum(val), ObjectIdGetDatum(InvalidOid), Int32GetDatum(-1));
				datatype_oid = NUMERICOID;
			}
		}
		
		// Check for NULL
		if (isnull && include_null_values)	{
			value = palloc(sizeof(JsonbValue));
			value->type=jbvNull;
		}
		else	{
			// Extract the colummn value in the correct format
			value = palloc(sizeof(JsonbValue));
			jsonb_get_value(colval, isnull, value, datatype_oid);
			if(datatype_oid != JSONOID)
				value = &value->val.array.elems[0];
		}

		// Determine if the value should be inserted as a nested json object
		parts = determine_parts(colname, &num);
		if(strcmp(parts[0], "JSONAUTOALIAS") != 0) {
			ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("sub-select and values for json auto are not currently supported.")));
		}
		colname = remove_index_and_alias(colname);
		nestedVal = value;

		found = false;

		sscanf(parts[1], "%d", &num);

		maxDepth = (num > maxDepth) ? num : maxDepth;

		if (num > 1)	{
			hashKey = parts[1];

			hashEntry = (JsonbEntry *) hash_search(jsonbHash, hashKey, HASH_FIND, &found);

			// If it exists, we insert the value into the existing JsonbValue and break out of the loop
			if (hashEntry)	{
				// function call
				current = hashEntry->value;
				insert_existing_json_to_obj(current, hashEntry->parent, nestedVal, hashEntry->idx, colname);
				pfree(hashKey);
			} else {
				hashEntry = (JsonbEntry *) hash_search(jsonbHash, (void *) hashKey, HASH_ENTER, NULL);
				strlcpy(hashEntry->path, hashKey, NAMEDATALEN);
				nestedVal = create_json_array(parts[2], colname, nestedVal, &hashEntry->idx);
				hashEntry->value = nestedVal;

				// if the nested json is not at the jsonbRow level
				if (num > 2) {
					hashEntry->parent = nestedVal;
					// insert new array into existing obj for nest
					sprintf(hashKey, "%d", num - 1);
					hashEntry = (JsonbEntry *) hash_search(jsonbHash, hashKey, HASH_FIND, &found);
					current = hashEntry->value;
					insert_existing_json_to_obj(current, hashEntry->parent, &(nestedVal->val.object.pairs[0].value), hashEntry->idx, parts[2]);
				}
				else	{
					hashEntry->parent = jsonbRow;
					hashEntry->idx = jsonbRow->val.object.nPairs;
				}

				pfree(hashKey);

				// Already inserted into existing json object (nested)
				if (found)
					continue;

				// JsonbValue was created in loop, insert and update structure.
				jsonbRow->val.object.pairs[jsonbRow->val.object.nPairs] = nestedVal->val.object.pairs[0];
				jsonbRow->val.object.nPairs++;
				}
		}
		else {
			// Increment nPairs in the row if it isnt inserted into an already existing json object.
			jsonbRow->val.object.nPairs++;

			// Allocate memory for key and create it
			key = palloc(sizeof(JsonbValue));
			key->type = jbvString;
			key->val.string.len = strlen(colname);
			key->val.string.val = pstrdup(colname);

			// Create JsonbPair
			jsonbPair = palloc(sizeof(JsonbPair));
			jsonbPair->key = *key;
			jsonbPair->value = *nestedVal;

			// Assign it to the JsonbValue Row
			jsonbRow->val.object.pairs[jsonbRow->val.object.nPairs - 1] = *jsonbPair;
		}
	}

	// Add the jsonb row to the jsonbArray
	minInsertDepth = 1;
	checkForDuplicateRows(jsonbArray, jsonbRow, maxDepth, 1, &minInsertDepth);

	ReleaseTupleDesc(tupdesc);
}

// Main row to json function. 
// Creates a Jsonb row object, processes the row, determines if it should be inserted as a nested json object
// inserts json object to row and then into the main jsonbArray.
static void
tsql_row_to_json(JsonbValue* jsonbArray, Datum record, bool include_null_values)
{
	// HashTable
	HTAB	   *jsonbHash;
	HASHCTL		ct;

	// JsonbValue for the row
	JsonbValue *jsonbRow;

	HeapTupleHeader td;
	Oid			tupType;
	int32		tupTypmod;
	TupleDesc	tupdesc;
	HeapTupleData tmptup;
	HeapTuple	tuple;

	td = DatumGetHeapTupleHeader(record);

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;

	// Initialize the JsonbValue for the row
	jsonbRow = palloc(sizeof(JsonbValue));
	jsonbRow->type = jbvObject;
	jsonbRow->val.object.nPairs = 0;
	jsonbRow->val.object.pairs = palloc(sizeof(JsonbPair) * tupdesc->natts);

	// Initialize the hashTable to hold information regarding the nested json objects within the row
	memset(&ct, 0, sizeof(ct));
	ct.keysize = NAMEDATALEN;
	ct.entrysize = sizeof(JsonbEntry);
	jsonbHash = hash_create("JsonbHash", TABLE_SIZE, &ct, HASH_ELEM | HASH_STRINGS);

	/* process the tuple into key/value pairs */
	for (int i = 0; i < tupdesc->natts; i++)
	{
		// Pair object that holds key-value
		JsonbValue  *key; 
		JsonbValue  *value;
		JsonbPair	*jsonbPair;	

		// Used for nested json Objects
		JsonbEntry  *hashEntry;
		JsonbValue  *nestedVal;	
		JsonbValue  *current;
		char       **parts;
		int 		num;
		bool		found;
		char		*hashKey;

		char	   *colname;
		Datum		colval;
		bool		isnull;
		Oid			datatype_oid;
		Oid			nspoid;
		Oid			tsql_datatype_oid;
		char	   *typename;

		Form_pg_attribute att = TupleDescAttr(tupdesc, i);

		if (att->attisdropped)
			continue;

		colname = NameStr(att->attname);

		if (!strcmp(colname, "\?column\?")) /* When column name or alias is
											 * not provided */
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("column expressions and data sources without names or aliases cannot be formatted as JSON text using FOR JSON clause. Add alias to the unnamed column or table")));
		}

		colval = heap_getattr(tuple, i + 1, tupdesc, &isnull);

		if (isnull && !include_null_values)
			continue;

		/*
		 * Below is a workaround for is_tsql_x_datatype() which does not work
		 * as expected. We compare the datatype oid of the columns with the
		 * tsql_datatype_oid and then specially handle some TSQL-specific
		 * datatypes.
		 */
		datatype_oid = att->atttypid;
		typename = SPI_gettype(tupdesc, i + 1);
		nspoid = get_namespace_oid("sys", true);
		Assert(nspoid != InvalidOid);

		tsql_datatype_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));

		/*
		 * tsql_datatype_oid can be different from datatype_oid when there are
		 * datatypes in different namespaces but with the same name. Examples:
		 * bigint, int, etc.
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
				char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);
				StringInfo	format_output = makeStringInfo();

				tsql_for_datetime_format(format_output, val);
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
			}

			/*
			 * datetimeoffset has two behaviors: if offset is 0, just return
			 * the datetime with 'Z' at the end otherwise, append the offset
			 */
			else if (strcmp(typename, "datetimeoffset") == 0)
			{
				char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);
				StringInfo	format_output = makeStringInfo();

				tsql_for_datetimeoffset_format(format_output, val);
				colval = CStringGetDatum(format_output->data);

				datatype_oid = CSTRINGOID;
			}
			/* convert money and smallmoney to numeric */
			else if (strcmp(typename, "money") == 0 ||
					 strcmp(typename, "smallmoney") == 0)
			{
				char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);

				colval = DirectFunctionCall3(numeric_in, CStringGetDatum(val), ObjectIdGetDatum(InvalidOid), Int32GetDatum(-1));
				datatype_oid = NUMERICOID;
			}
		}
		
		// Check for NULL
		if (isnull && include_null_values)	{
			value = palloc(sizeof(JsonbValue));
			value->type=jbvNull;
		}
		else	{
			// Extract the colummn value in the correct format
			value = palloc(sizeof(JsonbValue));
			jsonb_get_value(colval, isnull, value, datatype_oid);
			value = &value->val.array.elems[0];
		}

		// Determine if the value should be inserted as a nested json object
		parts = determine_parts(colname, &num);
		nestedVal = value;

		found = false;
		if (num > 1)	{
			for (int i = num - 1; i >= 0; i--)	{
				hashKey = build_key(parts, i);

				// Check if the current key exists in the hashTable
				hashEntry = (JsonbEntry *) hash_search(jsonbHash, hashKey, HASH_FIND, &found);

				// If it exists, we insert the value into the existing JsonbValue and break out of the loop
				if (hashEntry)	{
					// function call
					current = hashEntry->value;
					insert_existing_json(current, hashEntry->parent, nestedVal, hashEntry->idx, colname);
					pfree(hashKey);
					break;
				}

				// If it does not exist
				hashEntry = (JsonbEntry *) hash_search(jsonbHash, (void *) hashKey, HASH_ENTER, NULL);
				strlcpy(hashEntry->path, hashKey, NAMEDATALEN);
				hashEntry->value = nestedVal;
				nestedVal = create_json(parts[i], nestedVal, &hashEntry->idx);

				// if the nested json is not at the jsonbRow level
				if (i != 0)
					hashEntry->parent = nestedVal;
				else	{
					hashEntry->parent = jsonbRow;
					hashEntry->idx = jsonbRow->val.object.nPairs;
				}

				pfree(hashKey);
			}

			// Already inserted into existing json object (nested)
			if (found)
				continue;

			// JsonbValue was created in loop, insert and update structure.
			jsonbRow->val.object.pairs[jsonbRow->val.object.nPairs] = nestedVal->val.object.pairs[0];
			jsonbRow->val.object.nPairs++;
		}

		else	{
			// Increment nPairs in the row if it isnt inserted into an already existing json object.
			jsonbRow->val.object.nPairs++;		
			colname = parts[0];

			// Allocate memory for key and create it
			key = palloc(sizeof(JsonbValue));
			key->type = jbvString;
			key->val.string.len = strlen(colname);
			key->val.string.val = pstrdup(colname);

			// Create JsonbPair
			jsonbPair = palloc(sizeof(JsonbPair));
			jsonbPair->key = *key;
			jsonbPair->value = *nestedVal;

			// Assign it to the JsonbValue Row
			jsonbRow->val.object.pairs[jsonbRow->val.object.nPairs - 1] = *jsonbPair;
		}
	}

	// Add the jsonb row to the jsonbArray
	jsonbArray->val.array.nElems++;
	jsonbArray->val.array.elems = (JsonbValue *) repalloc(jsonbArray->val.array.elems, sizeof(JsonbValue) * (jsonbArray->val.array.nElems));
	jsonbArray->val.array.elems[jsonbArray->val.array.nElems - 1] = *jsonbRow;

	ReleaseTupleDesc(tupdesc);
}

PG_FUNCTION_INFO_V1(tsql_query_to_json_ffunc);

Datum
tsql_query_to_json_ffunc(PG_FUNCTION_ARGS)
{
	forjson_state 	*state;
	JsonbValue 		*res;
	Jsonb 			*jsonOut;
	StringInfo		resStr;

	// Only used if a root_name is given
	JsonbValue		*root;
	JsonbValue		*key;

	// Get the processed JsonbValue array
	state = (forjson_state*) PG_GETARG_POINTER(0);
	resStr = makeStringInfo();

	if (state->root_name)	{

		// Key jsonBValue to store the root name
		key = palloc(sizeof(JsonbValue));
		key->type = jbvString;
		key->val.string.len = strlen(state->root_name);
		key->val.string.val = state->root_name;
		
		// Root JsonbValue where the key is the root name and value is the processed jsonbVal array
		root = palloc(sizeof(JsonbValue));
		root->type = jbvObject;
		root->val.object.nPairs = 1;
		root->val.object.pairs = (JsonbPair *) palloc(sizeof(JsonbPair));
		root->val.object.pairs[0].key = *key;
		root->val.object.pairs[0].value = *state->jsonbArray;

		// Update the processed jsonbArray
		state->jsonbArray = root;
	}

	// Convert JsonbValue to StringInfo for array wrapper check and to return
	res = state->jsonbArray;
	jsonOut = JsonbValueToJsonb(res);
	JsonbToCString(resStr, &jsonOut->root, 0);

	// if without array wrappers is true, remove the array wrappers
	if (state->without_array_wrapper)	{
		if (resStr->data[0] == '[')	{
			resStr->data++;
			resStr->len--;
		}
		if (resStr->data[resStr->len - 1] == ']')	{
			resStr->data[resStr->len - 1] = '\0';
			resStr->len--;
		}
	}
	
	PG_RETURN_TEXT_P(cstring_to_text_with_len(resStr->data, resStr->len));
}

// Function to determine how many nested json objects a column requires
// Splits a string into an array of strings by the "."
static char**
determine_parts(const char* str, int* num)
{
	int			i;
	char		**parts;
	char		*copy_str;
	char 		*token;

	// Determine how many parts there are (words seperated by ".")
	*num = 1;
	for (i = 0; str[i]; i++)	{	
		if (str[i] == '.')
			(*num)++;
	}

	// Create a string array to hold each indiviual word
	parts = (char **) palloc(sizeof(char *) * (*num + 1)); 
	copy_str = pstrdup(str);
	token = strtok(copy_str, ".");
	i = 0;
	while (token != NULL)	{
		parts[i++] = pstrdup(token);
		token = strtok(NULL, ".");
	}
	
	parts[i] = NULL;
	pfree(copy_str);
	return parts;

}

// Function to build a key to use to search in the Hashtable
// Uses the parts** created from determine_parts to build a string
// that is used as a key/path.
static char* 
build_key(char **parts, int currentIdx)
{
	StringInfo str;
	str = makeStringInfo();

	// Build a string up to the current path
	for (int i = 0; i <= currentIdx; i++)	{
		appendStringInfoString(str, parts[i]);
		if (i < currentIdx)	{
			appendStringInfoChar(str, '.');
		}
	}

	return str->data;
}

// Function to create the nested json output for a col if required
// Used when created nested json objects
static JsonbValue*
create_json(char *part, JsonbValue* val, int *idx)
{
	JsonbValue *obj;
	JsonbValue *key;
	JsonbPair  *pair;

	// Create key
	key = palloc(sizeof(JsonbValue));
	key->type = jbvString;
	key->val.string.len = strlen(part);
	key->val.string.val = pstrdup(part);

	// Create pair to hold key and value
	pair = palloc(sizeof(JsonbPair));
	pair->key = *key;
	pair->value = *val;

	// If we are not inserting into an already existing json object

	obj = palloc(sizeof(JsonbValue));
	obj->type = jbvObject;
	obj->val.object.nPairs = 1;
	obj->val.object.pairs = palloc(sizeof(JsonbPair));


	obj->val.object.pairs[obj->val.object.nPairs - 1] = *pair;
	*idx = obj->val.object.nPairs - 1;
	return obj;

}

// Creates a json array object of the form
// {arrayKey: [{pairkey: pairval}]}
static JsonbValue*
create_json_array(char *arrayKey, char* pairKey, JsonbValue* pairVal, int *idx)
{
	JsonbValue *obj;
	JsonbValue *key;
	JsonbValue *innerKey;
	JsonbPair  *pair;
    JsonbValue *jsonbArray;
	JsonbValue *innerObj;
	JsonbPair  *innerPair;

	// Create keys
	key = palloc(sizeof(JsonbValue));
	key->type = jbvString;
	key->val.string.len = strlen(arrayKey);
	key->val.string.val = pstrdup(arrayKey);

	innerKey = palloc(sizeof(JsonbValue));
	innerKey->type = jbvString;
	innerKey->val.string.len = strlen(pairKey);
	innerKey->val.string.val = pstrdup(pairKey);

	// Create Val
	jsonbArray = palloc(sizeof(JsonbValue));
	jsonbArray->type = jbvArray;
	jsonbArray->val.array.nElems = 1;
	jsonbArray->val.array.rawScalar = false;
	jsonbArray->val.array.elems = (JsonbValue *) palloc(sizeof(JsonbValue));

	// Create pair to hold key and value
	innerPair = palloc(sizeof(JsonbPair));
	innerPair->key = *innerKey;
	innerPair->value = *pairVal;

	innerObj = palloc(sizeof(JsonbValue));
	innerObj->type = jbvObject;
	innerObj->val.object.nPairs = 1;
	innerObj->val.object.pairs = palloc(sizeof(JsonbPair));
	innerObj->val.object.pairs[innerObj->val.object.nPairs - 1] = *innerPair;
	
	jsonbArray->val.array.elems[0] = *innerObj;

	// Create pair to hold key and value
	pair = palloc(sizeof(JsonbPair));
	pair->key = *key;
	pair->value = *jsonbArray;

	// If we are not inserting into an already existing json object
	obj = palloc(sizeof(JsonbValue));
	obj->type = jbvObject;
	obj->val.object.nPairs = 1;
	obj->val.object.pairs = palloc(sizeof(JsonbPair));


	obj->val.object.pairs[obj->val.object.nPairs - 1] = *pair;
	*idx = obj->val.object.nPairs - 1;
	return obj;
}

// Function to append into existing JsonbValue
// Used when the path to insert a json object is already found in the HashTable.
static void
insert_existing_json(JsonbValue *current, JsonbValue* parent, JsonbValue *nestedVal, int idx, char *key)
{
	JsonbPair* newPairs;
    // Make sure both current and nestedVal are non-null and are objects
    if (!current || !nestedVal || current->type != jbvObject || nestedVal->type != jbvObject)	{
			ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("Property %s cannot be generated in JSON output due to a conflict with another column name or alias. Use different names and aliases for each column in SELECT list.", key)));
	}

    // Allocate space for the new pairs
	newPairs = (JsonbPair *) repalloc(
        current->val.object.pairs, 
        sizeof(JsonbPair) * (current->val.object.nPairs + nestedVal->val.object.nPairs)
    );

    // Append the pairs from nestedVal to the new pair array
    for (int i = 0; i < nestedVal->val.object.nPairs; i++) {
        newPairs[current->val.object.nPairs + i] = nestedVal->val.object.pairs[i];
    }

    // Point the current's pairs to the newPairs
    current->val.object.pairs = newPairs;

    // Update the pair count
    current->val.object.nPairs += nestedVal->val.object.nPairs;

    // update parent pointer
    parent->val.object.pairs[idx].value = *current;
}

// This function adds a json pair to a given array
static void
insert_existing_json_to_obj(JsonbValue *current, JsonbValue* parent, JsonbValue *nestedVal, int idx, char *key)
{
	JsonbValue *jsonbArray;
	JsonbValue *jsonKey;
	JsonbPair* newPair;
	JsonbPair* currPairs;
	JsonbPair* newPairs;
	int numPairs;

	jsonKey = palloc(sizeof(JsonbValue));
	jsonKey->type = jbvString;
	jsonKey->val.string.len = strlen(key);
	jsonKey->val.string.val = pstrdup(key);

	newPair = palloc(sizeof(JsonbPair));
	newPair->key = *jsonKey;
	newPair->value = *nestedVal;

	jsonbArray = (JsonbValue *) (((JsonbPair*) current->val.object.pairs)->value.val.array.elems); // Object within the array
	currPairs = (JsonbPair*) jsonbArray->val.object.pairs;
	numPairs = jsonbArray->val.object.nPairs;

	// Allocate space for the new pairs
	newPairs = palloc(sizeof(JsonbPair) * (numPairs + 1));

	for(int i = 0; i < numPairs; i++)
		newPairs[i] = currPairs[i];
	newPairs[numPairs] = *newPair;

	jsonbArray->val.object.nPairs = numPairs + 1;

	jsonbArray->val.object.pairs = newPairs;	

	parent->val.object.pairs[idx].value = ((JsonbPair*) current->val.object.pairs)->value;

	return;
}

/*
 * checkForDuplicateRows inserts the given row into the json array 
 * nested based on the root object
 */
static void
checkForDuplicateRows(JsonbValue *jsonbArray, JsonbValue* row, int maxDepth, int currDepth, int* minInsertDepth)
{
	JsonbPair *arrRowPairs;
	JsonbPair *rowPairs;
	if(currDepth == maxDepth) {
		jsonbArray->val.array.nElems++;
		jsonbArray->val.array.elems = (JsonbValue *) repalloc(jsonbArray->val.array.elems, sizeof(JsonbValue) * (jsonbArray->val.array.nElems));
		jsonbArray->val.array.elems[jsonbArray->val.array.nElems - 1] = *row;
		*minInsertDepth = currDepth;
		return;
	}
	else {
		for(int i = 0; i < jsonbArray->val.array.nElems; i++) {
			arrRowPairs = (jsonbArray->val.array.elems[i]).val.object.pairs;
			// Assumes that last value will be the next nested array
			for(int j = 0; j < (jsonbArray->val.array.elems[i]).val.object.nPairs - 1; j++) {
				bool sameElem = false;
				rowPairs = row->val.object.pairs;
				if(arrRowPairs[j].value.type != rowPairs[j].value.type)
					break;
				switch(rowPairs[j].value.type) {
					case jbvNull:
						sameElem = true;
						continue;
					case jbvString:
						sameElem = (strcmp(arrRowPairs[j].value.val.string.val, rowPairs[j].value.val.string.val) == 0);
						break;
					case jbvNumeric:
						sameElem = (compareNumeric(arrRowPairs[j].value.val.numeric, rowPairs[j].value.val.numeric) == 0);
						break;
					case jbvBool:
						sameElem = arrRowPairs[j].value.val.boolean == rowPairs[j].value.val.boolean;
						break;
					case jbvDatetime:
						sameElem = true;
						if(arrRowPairs[j].value.val.datetime.value != rowPairs[j].value.val.datetime.value)
							sameElem = false;
						if(arrRowPairs[j].value.val.datetime.typid != rowPairs[j].value.val.datetime.typid)
							sameElem = false;
						if(arrRowPairs[j].value.val.datetime.typmod != rowPairs[j].value.val.datetime.typmod)
							sameElem = false;
						if(arrRowPairs[j].value.val.datetime.tz != rowPairs[j].value.val.datetime.tz)
							sameElem = false;
						break;
					default:
						break;
				}
				if(!sameElem)
					break;
				if(sameElem && j == (jsonbArray->val.array.elems[i]).val.object.nPairs - 2) {
					if(*minInsertDepth == 1)
						*minInsertDepth = 2;
					checkForDuplicateRows(&(arrRowPairs[(jsonbArray->val.array.elems[i]).val.object.nPairs - 1].value), (row->val.object.pairs[(jsonbArray->val.array.elems[i]).val.object.nPairs - 1].value).val.array.elems, maxDepth, currDepth + 1, minInsertDepth);
				}
			}
		}
		if(currDepth == *minInsertDepth) {
			jsonbArray->val.array.nElems++;
			jsonbArray->val.array.elems = (JsonbValue *) repalloc(jsonbArray->val.array.elems, sizeof(JsonbValue) * (jsonbArray->val.array.nElems));
			if(jsonbArray->val.array.nElems == 1) {
				jsonbArray->val.array.elems[0] = *row;
			}
			else {
				jsonbArray->val.array.elems[jsonbArray->val.array.nElems - 1] = jsonbArray->val.array.elems[jsonbArray->val.array.nElems - 2];
				jsonbArray->val.array.elems[jsonbArray->val.array.nElems - 2] = *row;
			}
		}
		return;
	}
}

static int
compareNumeric(Numeric a, Numeric b)
{
	return DatumGetInt32(DirectFunctionCall2(numeric_cmp,
											 NumericGetDatum(a),
											 NumericGetDatum(b)));
}

/*
 * JSON AUTO columns are modified to be in the form
 * JSONAUTOALIAS.[nest_level].[table_alias].[original_colname]
 * this function returns the original column name
 */
char* 
remove_index_and_alias(const char* str)
{
	int index = 0;
	int num = 0;
	for (int i = 0; str[i]; i++) {	
		if (str[i] == '.')
			num++;
		index++;
		if(num == 3)
			return (char*) (str + index);
	}
	return (char*) str;
}