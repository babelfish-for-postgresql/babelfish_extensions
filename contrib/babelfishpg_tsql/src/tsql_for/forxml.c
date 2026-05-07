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
#include "utils/datum.h"
#include "utils/xml.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/typcache.h"
#include "catalog/pg_type.h"
#include "catalog/namespace.h"
#include "catalog/pg_collation.h"

#include "tsql_for.h"

/* State structure for FOR XML AUTO */
typedef struct forxml_auto_state
{
	/* Metadata cache - populated on first row */
	bool			metadata_cached;
	int				num_columns;
	int			   *nest_levels;		/* nest_levels[i] = level for column i */
	char		  **table_aliases;		/* table_aliases[i] = table name for column i */
	char		  **column_names;		/* column_names[i] = original col name */

	/* Output function cache - populated on first row for fast type conversion */
	FmgrInfo	   *out_finfo;			/* Cached output function info per column */
	Oid			   *base_types;			/* Base type OID per column (after domain flattening) */
	bool			out_funcs_cached;	/* Whether output functions have been cached */

	/*
	 * T-SQL datatype conversion cache - populated on first row.
	 * Caches the result of update_tsql_datatype_and_val's SPI_gettype +
	 * get_namespace_oid + GetSysCacheOid2 lookups per column.
	 * 0 = no conversion needed, 1 = datetime/smalldatetime/datetime2,
	 * 2 = datetimeoffset, 3 = binary/varbinary/image/timestamp/rowversion
	 */
	int			   *tsql_convert_type;	/* Per-column T-SQL conversion type */
	bool			tsql_types_cached;	/* Whether T-SQL type cache is populated */

	/*
	 * Equality-operator cache for sibling-group detection.  Populated on the
	 * first row.  Grouping in FOR XML AUTO must follow T-SQL semantics, which
	 * uses the column's type+collation equality, not byte equality of the
	 * serialized form (e.g. two rows whose parent column differs only in
	 * letter case under a case-insensitive collation must be merged).
	 * For types with no default btree equality (xml, json, etc.) we fall
	 * back to strcmp on the serialized form.
	 */
	FmgrInfo	   *eq_finfo;			/* Per-column equality FmgrInfo */
	Oid			   *eq_collation;		/* Collation to pass to eq operator */
	bool		   *has_eq_op;			/* Does the column's type have a usable eq op? */
	int16		   *type_typlen;		/* typlen of column's base type (for datumCopy) */
	bool		   *type_typbyval;		/* typbyval of column's base type (for datumCopy) */
	bool			eq_cache_init;		/* Whether equality cache has been populated */

	/* Previous row values, stored as Datums for type-aware comparison. */
	Datum		   *prev_datums;		/* datumCopy'd previous values */
	bool		   *prev_isnull;		/* Per-column null flag for prev row */
	char		  **prev_str_values;	/* Fallback serialized prev values, used for
										 * types without a default btree equality (e.g. xml, json) */

	/* State for XML generation */
	int				max_depth;			/* Maximum nesting depth seen */
	char		  **level_to_alias;		/* level_to_alias[level] = table alias for that level */
	int			   *open_element_levels; /* Track which levels have open elements */
	bool			first_row;			/* Is this the first row? */
	bool			has_root;			/* Is there a ROOT wrapper? */
	bool			binary_base64;		/* BINARY BASE64 option flag */
} forxml_auto_state;

/*
 * Wrapper struct for FOR XML aggregate state.
 * Holds both the XML output buffer and AUTO mode state.
 */
typedef struct forxml_state
{
	StringInfo			xml_output;		/* Accumulated XML output */
	forxml_auto_state  *auto_state;		/* AUTO mode state, NULL for other modes */
} forxml_state;

static StringInfo for_xml_ffunc(PG_FUNCTION_ARGS);
static void tsql_row_to_xml_raw(StringInfo state, Datum record, const char *element_name, bool binary_base64, bool elements, bool xsinil);
static void tsql_row_to_xml_path(StringInfo state, Datum record, const char *element_name, bool binary_base64, bool xsinil);
static void tsql_row_to_xml_auto(StringInfo state, Datum record, bool elements, bool xsinil, forxml_auto_state *auto_state);
static void update_tsql_datatype_and_val(HeapTuple tuple, TupleDesc tupdesc, Oid *datatype_oid, Datum *colval, bool binary_base64, int i);
static char *tsql_escape_xml(const char *str);

/* Helper functions for XML AUTO */
static void xml_auto_parse_metadata(forxml_auto_state *auto_state, const char *metadata_str, int num_cols);
static char* auto_column_to_xml_string(Datum colval, bool isnull, HeapTuple tuple, TupleDesc tupdesc, int col_idx, forxml_auto_state *auto_state);

/*
 * tsql_escape_xml
 *
 * T-SQL variant of XML escaping for attribute values. PostgreSQL's
 * escape_xml() (used internally by map_sql_value_to_xml_value and
 * cached_value_to_xml_string) handles &, <, >, \r but not ". T-SQL
 * escapes " as &quot; in FOR XML attribute-value output (RAW, AUTO,
 * PATH). This helper adds the " → &quot; substitution on top of the
 * already XML-escaped value to match T-SQL behavior without touching
 * the engine's escape_xml().
 */
static char *
tsql_escape_xml(const char *str)
{
	StringInfoData buf;
	const char *p;

	/*
	 * Fast path: if no '"' is present, no substitution is needed.  The
	 * caller will copy the bytes via appendStringInfo, so returning the
	 * original pointer avoids a per-call palloc + byte-by-byte copy on
	 * what is the common case for most data.
	 */
	if (strchr(str, '"') == NULL)
		return (char *) str;

	initStringInfo(&buf);
	for (p = str; *p; p++)
	{
		if (*p == '"')
			appendStringInfoString(&buf, "&quot;");
		else
			appendStringInfoChar(&buf, *p);
	}
	return buf.data;
}

static int find_first_changed_level(forxml_auto_state *auto_state, HeapTuple tuple, TupleDesc tupdesc);
static void close_elements_to_level(StringInfo state, forxml_auto_state *auto_state, int target_level);
static void output_row_xml(StringInfo state, forxml_auto_state *auto_state, HeapTuple tuple, TupleDesc tupdesc, bool elements, bool xsinil);
static char *cached_value_to_xml_string(Datum value, int col_idx, forxml_auto_state *auto_state, Oid orig_type);
static void init_output_func_cache(forxml_auto_state *auto_state, TupleDesc tupdesc);
static void init_tsql_type_cache(forxml_auto_state *auto_state, TupleDesc tupdesc);
static void init_eq_op_cache(forxml_auto_state *auto_state, TupleDesc tupdesc);
static void cached_update_tsql_datatype_and_val(HeapTuple tuple, TupleDesc tupdesc, Oid *datatype_oid, Datum *colval, int col_idx, forxml_auto_state *auto_state);
static bool validate_attribute_centric_col_names_xml(const char *element_name, TupleDesc tupdesc);

PG_FUNCTION_INFO_V1(tsql_query_to_xml_sfunc);

Datum
tsql_query_to_xml_sfunc(PG_FUNCTION_ARGS)
{
	forxml_state *fstate;
	StringInfo	state;
	Datum		record = PG_GETARG_DATUM(1);
	int			mode = PG_GETARG_INT32(2);
	char	   *element_name = PG_ARGISNULL(3) ? "row" : text_to_cstring(PG_GETARG_TEXT_PP(3));
	bool		binary_base64 = PG_GETARG_BOOL(4);
	bool		elements = false;
	bool		xsinil = false;
	char	   *root_name;

	MemoryContext agg_context;
	MemoryContext old_context;

	/*
	* Backward compatibility: Check if ELEMENTS parameters are provided.
	* Old 6-argument version (deprecated_in_5_6_0): state, rec, mode, element_name, binary_base64, root_name
	* New 9-argument version (5.6.0+): adds elements, xsinil, auto_metadata parameters
	*/
	if (PG_NARGS() > 9)
		ereport(ERROR,
				(errcode(ERRCODE_TOO_MANY_ARGUMENTS),
				 errmsg("too many arguments")));

	if (PG_NARGS() > 6)
	{
		elements = PG_GETARG_BOOL(6);
		xsinil = PG_GETARG_BOOL(7);
	}
	if (!AggCheckCallContext(fcinfo, &agg_context))
		elog(ERROR, "aggregate function called in non-aggregate context");
	old_context = MemoryContextSwitchTo(agg_context);

	if (PG_ARGISNULL(0))
	{
		/* first time setup */
		fstate = (forxml_state *) palloc0(sizeof(forxml_state));
		fstate->xml_output = makeStringInfo();
		fstate->auto_state = NULL;
		state = fstate->xml_output;
		root_name = PG_ARGISNULL(5) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(5));
		if (root_name != NULL && strlen(root_name) > 0)
		{
			/*
			 * We need to add an extra token to the beginning so that the
			 * finalfunc knows there is a root element.
			 */
			if (xsinil)
				appendStringInfo(state, "{<%s " XML_XMLNS_XSI ">", root_name);
			else
				appendStringInfo(state, "{<%s>", root_name);
		}

		/* For AUTO mode, initialize auto_state with metadata from parameter */
		if (mode == TSQL_FORXML_AUTO)
		{
			char *auto_metadata;

			if (PG_NARGS() <= 8 || PG_ARGISNULL(8))
				ereport(ERROR,
						(errcode(ERRCODE_INTERNAL_ERROR),
						 errmsg("FOR XML AUTO requires metadata parameter (9th argument)")));

			auto_metadata = text_to_cstring(PG_GETARG_TEXT_PP(8));
			if (strlen(auto_metadata) > 0)
			{
				forxml_auto_state *auto_st = (forxml_auto_state *) palloc0(sizeof(forxml_auto_state));
				auto_st->first_row = true;
				auto_st->has_root = (root_name != NULL && strlen(root_name) > 0);
				auto_st->binary_base64 = binary_base64;
				fstate->auto_state = auto_st;

				/* Parse metadata now so it's ready for the first row */
				{
					HeapTupleHeader td = DatumGetHeapTupleHeader(record);
					Oid tupType = HeapTupleHeaderGetTypeId(td);
					int32 tupTypmod = HeapTupleHeaderGetTypMod(td);
					TupleDesc tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);
					xml_auto_parse_metadata(auto_st, auto_metadata, tupdesc->natts);
					ReleaseTupleDesc(tupdesc);
				}
			}
		}
	}
	else
	{
		fstate = (forxml_state *) PG_GETARG_POINTER(0);
		state = fstate->xml_output;
	}
	switch (mode)
	{
		case TSQL_FORXML_RAW:	/* FOR XML RAW */
			tsql_row_to_xml_raw(state, record, element_name, binary_base64, elements, xsinil);
			break;
		case TSQL_FORXML_AUTO:	/* FOR XML AUTO */
			{
				forxml_auto_state *auto_state = fstate->auto_state;

				if (auto_state == NULL)
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							 errmsg("FOR XML AUTO state not initialized")));

				tsql_row_to_xml_auto(state, record, elements, xsinil, auto_state);
			}
			break;
		case TSQL_FORXML_PATH:	/* FOR XML PATH */
			tsql_row_to_xml_path(state, record, element_name, binary_base64, xsinil);
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

	MemoryContextSwitchTo(old_context);

	PG_RETURN_POINTER(fstate);
}

PG_FUNCTION_INFO_V1(tsql_query_to_xml_ffunc);

Datum
tsql_query_to_xml_ffunc(PG_FUNCTION_ARGS)
{
	StringInfo	res = for_xml_ffunc(fcinfo);

	PG_RETURN_XML_P((xmltype *) cstring_to_text_with_len(res->data, res->len));
}

PG_FUNCTION_INFO_V1(tsql_query_to_xml_text_ffunc);

Datum
tsql_query_to_xml_text_ffunc(PG_FUNCTION_ARGS)
{
	StringInfo	res = for_xml_ffunc(fcinfo);

	/* return NULL if empty result (i.e. no rows) */
	if (res->len == 0)
		PG_RETURN_NULL();

	PG_RETURN_TEXT_P(cstring_to_text_with_len(res->data, res->len));
}

static StringInfo
for_xml_ffunc(PG_FUNCTION_ARGS)
{
	StringInfo	res = makeStringInfo();
	forxml_state *fstate;
	char	   *state;
	text	   *state_text;
	text	   *pattern_text;
	Datum		root_tag_datum;
	text	   *root_tag_text;
	char	   *root_tag;

	if (PG_ARGISNULL(0))
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("unexpected null state in FOR XML processing")));

	fstate = (forxml_state *) PG_GETARG_POINTER(0);

	/* Handle AUTO mode: close remaining open elements */
	if (fstate->auto_state != NULL)
	{
		close_elements_to_level(fstate->xml_output, fstate->auto_state, 0);
	}

	state = fstate->xml_output->data;

	if (state[0] == '{')		/* '{' indicates that root was specified, so
								 * add the corresponding end tag */
	{
		/*
		 * Using PostgreSQL's textregexsubstr() to extract the root tag name.
		 * simpler than manual regex handling and leverages PostgreSQL's 
		 * cached regex compilation and proper memory management.
		 */
		state_text = cstring_to_text(state);
		pattern_text = cstring_to_text("<([^ />]+)[^>]*>");

		/* Extract the root tag name using textregexsubstr */
		root_tag_datum = DirectFunctionCall2Coll(textregexsubstr, 
											 C_COLLATION_OID,
											 PointerGetDatum(state_text),
											 PointerGetDatum(pattern_text));

		if (DatumGetPointer(root_tag_datum) == NULL)
		{
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("unexpected error parsing xml root tag")));
		}

		root_tag_text = DatumGetTextPP(root_tag_datum);
		root_tag = text_to_cstring(root_tag_text);

		/* Copy state content (skip the '{' marker) and add closing tag */
		appendStringInfoString(res, state + 1);
		appendStringInfo(res, "</%s>", root_tag);
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
tsql_row_to_xml_raw(StringInfo state, Datum record, const char *element_name, bool binary_base64, bool elements, bool xsinil)
{
	HeapTupleHeader td;
	Oid             tupType;
	int32           tupTypmod;
	TupleDesc       tupdesc;
	HeapTupleData   tmptup;
	HeapTuple       tuple;
	bool            allnull = true;
	
	td = DatumGetHeapTupleHeader(record);

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;

	/*
	 * Empty element name without ELEMENTS mode is not allowed — attribute-centric
	 * serialization requires a row tag name.
	 */
	if (element_name[0] == '\0' && !elements)
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_XML_PROCESSING_INSTRUCTION),
				 errmsg("Row tag omission (empty row tag name) cannot be used "
						"with attribute-centric FOR XML serialization.")));
	}

	/* Output opening tag (only when element_name is non-empty) */
	if (element_name[0] != '\0')
	{
		if (elements)
		{
			/* ELEMENTS mode: <row><col>value</col></row> */
			if (xsinil)
				appendStringInfo(state, "<%s " XML_XMLNS_XSI ">", element_name);
			else
				appendStringInfo(state, "<%s>", element_name);
		}
		else
		{
			/* ATTRIBUTES mode: <row col="value"/> */
			appendStringInfo(state, "<%s", element_name);
		}
	}

	for (int i = 0; i < tupdesc->natts; i++)
	{
		char       *colname;
		Datum       colval;
		bool        isnull;
		Oid         datatype_oid;
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);

		if (att->attisdropped)
			continue;

		colname = map_sql_identifier_to_xml_name(NameStr(att->attname), true, false);
		colval = heap_getattr(tuple, i + 1, tupdesc, &isnull);
		datatype_oid = att->atttypid;

		update_tsql_datatype_and_val(tuple, tupdesc, &datatype_oid, &colval, binary_base64, i);

		if (elements)
		{
			/* ELEMENTS mode output */
			if (!isnull)
			{
				allnull = false;
				/* When RAW('') is used with XSINIL, add xmlns to each element */
				if ((element_name && strlen(element_name) == 0) && xsinil)
					appendStringInfo(state, "<%s " XML_XMLNS_XSI ">%s</%s>",
									 colname,
									 map_sql_value_to_xml_value(colval, datatype_oid, true),
									 colname);
				else
					appendStringInfo(state, "<%s>%s</%s>",
									 colname,
									 map_sql_value_to_xml_value(colval, datatype_oid, true),
									 colname);
			}
			else if (xsinil)
			{
				allnull = false;
				/* When RAW('') is used with XSINIL, add xmlns to each element */
				if (element_name && strlen(element_name) == 0)
					appendStringInfo(state, "<%s " XML_XMLNS_XSI " " XML_XSI_NIL "/>", colname);
				else
					appendStringInfo(state, "<%s " XML_XSI_NIL "/>", colname);
			}
			/* else: ABSENT - skip NULL columns (do nothing) */
		}
		else
		{
			/* ATTRIBUTES mode output */
			if (!isnull)
			{
				appendStringInfo(state, " %s=\"%s\"",
								 colname,
								 tsql_escape_xml(map_sql_value_to_xml_value(colval, datatype_oid, true)));
			}
		}
	}

	/* Output closing tag */
	if (elements)
	{
		if (element_name[0] == '\0')
		{
			/*
			 * Empty element name with ELEMENTS: no wrapper tag needed.
			 * Just output the child elements directly, same as PATH('').
			 */
		}
		else if (allnull)
		{
			/*
			 * If all column values are NULL, produce a self-closing element
			 * like TSQL does: <row/>. Replace the '>' in the already
			 * appended opening tag with '/' and append '>'.
			 */
			state->data[state->len - 1] = '/';
			appendStringInfoChar(state, '>');
		}
		else
		{
			appendStringInfo(state, "</%s>", element_name);
		}
	}
	else
		appendStringInfoString(state, "/>");

	ReleaseTupleDesc(tupdesc);
}

/*
 * validate_attribute_centric_col_names_xml
 *	Check if the tupdesc has attribute-centric columns and if present 
 *	check the following -
 *	1. all of them are present in the starting of attribute list before any non-attribute-centric column ,
 *	2. the element_name to be not NULL for tupdesc having attribute-centric columns.
 */
static bool
validate_attribute_centric_col_names_xml(const char *element_name, TupleDesc tupdesc)
{
	bool seen_non_att_centric = false;
	bool seen_att_centric = false;
	for (int i = 0; i < tupdesc->natts; i++)
	{
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);
		if (NameStr(att->attname)[0] == '@')
		{
			seen_att_centric = true;
			if(seen_non_att_centric)
				ereport(ERROR,
					(errcode(ERRCODE_INVALID_XML_PROCESSING_INSTRUCTION),
					 errmsg("Attribute-centric column '%s' must not come after a non-attribute-centric sibling in XML hierarchy in FOR XML PATH.",
					  NameStr(att->attname))));
		}
		else
			seen_non_att_centric = true;
	}

	if(seen_att_centric && (element_name && strlen(element_name) == 0))
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_XML_PROCESSING_INSTRUCTION),
				 errmsg("Row tag omission (empty row tag name) cannot be used " \
				 		"with attribute-centric FOR XML serialization.")));
	}

	return seen_att_centric;
}

/*
 * Map an SQL row to an XML element in PATH mode.
 */
static void
tsql_row_to_xml_path(StringInfo state, Datum record, const char *element_name, bool binary_base64, bool xsinil)
{
	HeapTupleHeader td;
	Oid             tupType;
	int32           tupTypmod;
	TupleDesc       tupdesc;
	HeapTupleData   tmptup;
	HeapTuple       tuple;
	bool            allnull = true;
	bool            has_att_centric = false;
	bool            first = true;
	int             inital_state_len = state->len;

	td = DatumGetHeapTupleHeader(record);

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;

	has_att_centric = validate_attribute_centric_col_names_xml(element_name, tupdesc);

	/*
	 * each tuple is either contained in a "row" tag, or standalone if the
	 * element_name is an empty string
	 */
	if (element_name && strlen(element_name) > 0)
	{
		/* if "''" is the input path, ignore it per TSQL behavior */
		if (has_att_centric)
		{
			if (xsinil)
				appendStringInfo(state, "<%s " XML_XMLNS_XSI, element_name);
			else
				appendStringInfo(state, "<%s", element_name);
		}
		else
		{
			if (xsinil)
				appendStringInfo(state, "<%s " XML_XMLNS_XSI ">", element_name);
			else
				appendStringInfo(state, "<%s>", element_name);
		}
	}

	/* process the tuple into tags */
	for (int i = 0; i < tupdesc->natts; i++)
	{
		char	   *colname;
		Datum		colval;
		bool		isnull;
		Oid			datatype_oid;
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
			if(NameStr(att->attname)[0] == '@')
			{
				appendStringInfo(state, " %s=\"%s\"",
								 NameStr(att->attname)+1,
								 tsql_escape_xml(map_sql_value_to_xml_value(colval, datatype_oid, true)));
			}
			else
			{
				if (has_att_centric && first)
				{
					appendStringInfoChar(state, '>');
					first = false;
				}
				if(strncmp(NameStr(att->attname), "?column?", 8) == 0)
				{
					/* Dont include Default Colname that is assigned by PG */
					appendStringInfo(state, "%s",
									map_sql_value_to_xml_value(colval, datatype_oid, true));
				}
				else
				{
					/* When PATH('') is used with XSINIL, add xmlns to each element */
					if ((element_name && strlen(element_name) == 0) && xsinil)
						appendStringInfo(state, "<%s " XML_XMLNS_XSI ">%s</%s>",
										 colname,
										 map_sql_value_to_xml_value(colval, datatype_oid, true),
										 colname);
					else
						appendStringInfo(state, "<%s>%s</%s>",
										 colname,
										 map_sql_value_to_xml_value(colval, datatype_oid, true),
										 colname);
				}
			}
		}
		else if (xsinil)
		{
			/*
			* XSINIL: Output NULL columns with xsi:nil="true".
			* Skip attribute-centric columns (prefixed with '@') as
			* xsi:nil is only valid on XML elements, not on attributes.
			*/
			if (NameStr(att->attname)[0] != '@')
			{
				allnull = false;

				if (has_att_centric && first)
				{
					appendStringInfoChar(state, '>');
					first = false;
				}

				if (strncmp(NameStr(att->attname), "?column?", 8) != 0)
				{
					/* When PATH('') is used with XSINIL, add xmlns to each element */
					if (element_name && strlen(element_name) == 0)
						appendStringInfo(state, "<%s " XML_XMLNS_XSI " " XML_XSI_NIL "/>", colname);
					else
						appendStringInfo(state, "<%s " XML_XSI_NIL "/>", colname);
				}
			}
		}
	}

	if (element_name && strlen(element_name) > 0)
	{
		if (has_att_centric && first)
		{
			appendStringInfoString(state, "/>");
		}
		else
		{
			if (allnull)
			{
				/*
				 * At this point, state = <output from previous rows> + '<element_name>'
				 * 
				 * If all the column values are nulls, this element should be
				 * <element_name/>, modify the already appended <element_name> to
				 * <element_name/>.
				 */
				if (state->len > inital_state_len)	/* sanity check, should always be true */
				{
					state->data[state->len - 1] = '/';
					appendStringInfoString(state, ">");
				}
			}
			else
				appendStringInfo(state, "</%s>", element_name);
		}
	}
	ReleaseTupleDesc(tupdesc);
}

static void
update_tsql_datatype_and_val(HeapTuple tuple, TupleDesc tupdesc, Oid *datatype_oid, Datum *colval, bool binary_base64, int i)
{
	char	   *typename;
	Oid			nspoid,
				tsql_datatype_oid;

	/*
	 * Below is a workaround for is_tsql_x_datatype() which does not work as
	 * expected. We compare the datatype oid of the columns with the
	 * tsql_datatype_oid and then specially handle some TSQL-specific
	 * datatypes.
	 */
	typename = SPI_gettype(tupdesc, i + 1);
	nspoid = get_namespace_oid("sys", true);
	Assert(nspoid != InvalidOid);

	tsql_datatype_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum(typename), ObjectIdGetDatum(nspoid));

	/*
	 * tsql_datatype_oid can be different from datatype_oid when there are
	 * datatypes in different namespaces but with the same name. Examples:
	 * bigint, int, etc.
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
		 * convert datetime, smalldatetime, and datetime2 to appropriate text
		 * values, as T-SQL has a different text conversion than postgres.
		 */
		else if (strcmp(typename, "datetime") == 0 ||
				 strcmp(typename, "smalldatetime") == 0 ||
				 strcmp(typename, "datetime2") == 0)
		{
			char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);
			StringInfo	format_output = makeStringInfo();

			tsql_for_datetime_format(format_output, val);
			*colval = CStringGetDatum(format_output->data);

			*datatype_oid = CSTRINGOID;
		}

		/*
		 * datetimeoffset has two behaviors: if offset is 0, just return the
		 * datetime with 'Z' at the end otherwise, append the offset
		 */
		else if (strcmp(typename, "datetimeoffset") == 0)
		{
			char	   *val = SPI_getvalue(tuple, tupdesc, i + 1);
			StringInfo	format_output = makeStringInfo();

			tsql_for_datetimeoffset_format(format_output, val);
			*colval = CStringGetDatum(format_output->data);

			*datatype_oid = CSTRINGOID;
		}
	}
}

/*
 * Unescape _x002E_ back to literal '.' in a string.
 * The metadata uses escape_period=true to avoid dot delimiter collisions,
 * but T-SQL outputs dots literally in XML names, so we reverse it.
 */
static char *
unescape_period(const char *str)
{
	StringInfoData buf;
	const char *p = str;
	const char *end = str + strlen(str);

	initStringInfo(&buf);
	while (*p)
	{
		if ((end - p) >= 7 && strncmp(p, "_x002E_", 7) == 0)
		{
			appendStringInfoChar(&buf, '.');
			p += 7;
		}
		else
		{
			appendStringInfoChar(&buf, *p);
			p++;
		}
	}
	return buf.data;
}

/*
 * Parse metadata string for XML AUTO mode.
 * Format: "level.table.colname,level.table.colname,..."
 * e.g. "1.c.CustomerID,1.c.Name,2.o.OrderID,2.o.Amount"
 */
static void
xml_auto_parse_metadata(forxml_auto_state *auto_state, const char *metadata_str, int num_cols)
{
	char *str_copy;
	char *token;
	char *saveptr;
	int col_idx = 0;

	auto_state->num_columns = num_cols;
	auto_state->nest_levels = (int *) palloc0(num_cols * sizeof(int));
	auto_state->table_aliases = (char **) palloc0(num_cols * sizeof(char *));
	auto_state->column_names = (char **) palloc0(num_cols * sizeof(char *));

	/* Storage for per-column previous-row tracking (for sibling-group detection) */
	auto_state->prev_datums = (Datum *) palloc0(num_cols * sizeof(Datum));
	auto_state->prev_isnull = (bool *) palloc0(num_cols * sizeof(bool));
	auto_state->prev_str_values = (char **) palloc0(num_cols * sizeof(char *));

	auto_state->max_depth = 0;

	/* Output function cache arrays — populated on first row in cached_value_to_xml_string */
	auto_state->out_finfo = (FmgrInfo *) palloc0(num_cols * sizeof(FmgrInfo));
	auto_state->base_types = (Oid *) palloc0(num_cols * sizeof(Oid));
	auto_state->out_funcs_cached = false;

	/* T-SQL type conversion cache — populated on first row */
	auto_state->tsql_convert_type = (int *) palloc0(num_cols * sizeof(int));
	auto_state->tsql_types_cached = false;

	str_copy = pstrdup(metadata_str);

	/* Parse comma-separated entries (names are pre-escaped, no commas in them) */
	token = strtok_r(str_copy, ",", &saveptr);
	while (token != NULL && col_idx < num_cols)
	{
		/* Each token is "level.table.colname" */
		char *entry_copy = pstrdup(token);
		char *dot1 = strchr(entry_copy, '.');
		char *dot2 = (dot1 != NULL) ? strchr(dot1 + 1, '.') : NULL;
		char *endptr;
		long level;

		if (dot1 == NULL || dot2 == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("FOR XML AUTO metadata entry has invalid format: \"%s\"", token)));

		*dot1 = '\0';
		*dot2 = '\0';

		level = strtol(entry_copy, &endptr, 10);
		if (endptr == entry_copy || *endptr != '\0')
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("FOR XML AUTO metadata has non-numeric level: \"%s\"", entry_copy)));
		if (level < 1 || level > num_cols)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("FOR XML AUTO metadata has invalid level %ld", level)));
		auto_state->nest_levels[col_idx] = (int) level;

		auto_state->table_aliases[col_idx] = unescape_period(dot1 + 1);
		auto_state->column_names[col_idx] = unescape_period(dot2 + 1);

		if (auto_state->nest_levels[col_idx] > auto_state->max_depth)
			auto_state->max_depth = auto_state->nest_levels[col_idx];

		pfree(entry_copy);

		col_idx++;
		token = strtok_r(NULL, ",", &saveptr);
	}

	pfree(str_copy);

	if (col_idx != num_cols)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("FOR XML AUTO metadata entry count (%d) does not match column count (%d)",
						col_idx, num_cols)));

	/* Allocate array to track open elements at each level */
	auto_state->open_element_levels = (int *) palloc0((auto_state->max_depth + 1) * sizeof(int));

	/* Build level-to-alias lookup array for O(1) access */
	auto_state->level_to_alias = (char **) palloc0((auto_state->max_depth + 1) * sizeof(char *));
	for (int i = 0; i < num_cols; i++)
	{
		int lvl = auto_state->nest_levels[i];
		if (lvl > 0 && auto_state->level_to_alias[lvl] == NULL)
			auto_state->level_to_alias[lvl] = auto_state->table_aliases[i];
	}

	auto_state->metadata_cached = true;
}

/*
 * auto_column_to_xml_string - Unified value-to-XML-text conversion for AUTO mode.
 *
 * Given a column's Datum and null flag, produces the XML-ready text string.
 * Handles T-SQL datetime formatting, special XSD types, and the cached fast
 * path internally.  Returns a palloc'd string, or NULL if the column is null.
 *
 * tuple/tupdesc are needed for the datetime formatting sub-path (SPI_getvalue).
 */
static char*
auto_column_to_xml_string(Datum colval, bool isnull, HeapTuple tuple, TupleDesc tupdesc, int col_idx, forxml_auto_state *auto_state)
{
	Form_pg_attribute att = TupleDescAttr(tupdesc, col_idx);
	Oid datatype_oid = att->atttypid;

	if (isnull)
		return NULL;

	/* Apply T-SQL datetime formatting if needed */
	if (auto_state != NULL && auto_state->tsql_types_cached)
		cached_update_tsql_datatype_and_val(tuple, tupdesc, &datatype_oid, &colval, col_idx, auto_state);

	return cached_value_to_xml_string(colval, col_idx, auto_state, datatype_oid);
}

/*
 * Find the first nesting level where current row differs from previous row,
 * and update per-column previous-value state in the same pass.
 *
 * Comparison uses the column type's equality operator under the column's
 * collation so that grouping follows T-SQL semantics (e.g. two rows whose
 * parent column differs only in letter case under a case-insensitive
 * collation must be merged into one parent element).  For types without a
 * default btree equality (xml, json, ...) we fall back to strcmp on the
 * serialized form, which is what the engine was doing before.
 *
 * Returns the level number where change first occurs.
 * Returns max_depth+1 if nothing changed.
 * Returns 1 if this is the first row.
 */
static int
find_first_changed_level(forxml_auto_state *auto_state, HeapTuple tuple, TupleDesc tupdesc)
{
	int i;
	int first_change = auto_state->max_depth + 1;

	if (auto_state->first_row)
		return 1;

	for (i = 0; i < auto_state->num_columns; i++)
	{
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);
		int level = auto_state->nest_levels[i];
		Datum curr_datum;
		bool curr_isnull;
		bool changed = false;

		if (att->attisdropped || level == 0)
			continue;

		curr_datum = heap_getattr(tuple, i + 1, tupdesc, &curr_isnull);

		/* NULL handling: two NULLs are equal, exactly one NULL is different */
		if (curr_isnull && auto_state->prev_isnull[i])
		{
			changed = false;
		}
		else if (curr_isnull != auto_state->prev_isnull[i])
		{
			changed = true;
		}
		else if (auto_state->has_eq_op[i])
		{
			/*
			 * Type-aware equality via the column's eq operator under the
			 * column's collation.  Matches T-SQL grouping semantics.
			 */
			Datum eq;

			eq = FunctionCall2Coll(&auto_state->eq_finfo[i],
									auto_state->eq_collation[i],
									auto_state->prev_datums[i],
									curr_datum);
			changed = !DatumGetBool(eq);
		}
		else
		{
			/*
			 * Fallback for types with no default btree equality: compare
			 * the serialized XML-string form.
			 */
			char *curr_str = auto_column_to_xml_string(curr_datum, curr_isnull, tuple, tupdesc, i, auto_state);
			char *prev_str = auto_state->prev_str_values[i];

			if ((curr_str == NULL) != (prev_str == NULL) ||
				(curr_str != NULL && strcmp(curr_str, prev_str) != 0))
				changed = true;

			/* Update cached prev string */
			if (auto_state->prev_str_values[i] != NULL)
				pfree(auto_state->prev_str_values[i]);
			auto_state->prev_str_values[i] = curr_str;
		}

		if (changed && level < first_change)
			first_change = level;

		/*
		 * Update prev Datum for eq-op columns.  For pass-by-reference types
		 * we must datumCopy into the aggregate context, since the source
		 * tuple will be reclaimed before the next row.  For pass-by-value
		 * types the Datum itself is the value.
		 */
		if (auto_state->has_eq_op[i])
		{
			if (!auto_state->prev_isnull[i] &&
				!auto_state->type_typbyval[i])
			{
				pfree(DatumGetPointer(auto_state->prev_datums[i]));
			}

			if (curr_isnull)
			{
				auto_state->prev_datums[i] = (Datum) 0;
			}
			else
			{
				auto_state->prev_datums[i] = datumCopy(curr_datum,
														auto_state->type_typbyval[i],
														auto_state->type_typlen[i]);
			}
		}

		auto_state->prev_isnull[i] = curr_isnull;
	}

	return first_change;
}

/*
 * Close XML elements down to target_level (exclusive).
 * If target_level = 0, close all open elements.
 */
static void
close_elements_to_level(StringInfo state, forxml_auto_state *auto_state, int target_level)
{
	int level;

	if (auto_state == NULL)
		return;

	for (level = auto_state->max_depth; level > target_level; level--)
	{
		if (auto_state->open_element_levels[level] > 0)
		{
			char *alias = auto_state->level_to_alias[level];
			if (alias != NULL)
			{
				appendStringInfo(state, "</%s>", alias);
				auto_state->open_element_levels[level] = 0;
			}
		}
	}

	if (target_level > 0 && auto_state->open_element_levels[target_level] > 0)
	{
		char *alias = auto_state->level_to_alias[target_level];
		if (alias != NULL)
		{
			appendStringInfo(state, "</%s>", alias);
			auto_state->open_element_levels[target_level] = 0;
		}
	}
}

/*
 * cached_value_to_xml_string
 *
 * Fast path for converting a column value to its XML string representation.
 * Requires that init_output_func_cache() has been called first to populate
 * the per-column cache.
 *
 * Types that need special XSD formatting (bool, date, timestamp, bytea, xml,
 * arrays) fall back to the full map_sql_value_to_xml_value().
 */
static char *
cached_value_to_xml_string(Datum value, int col_idx, forxml_auto_state *auto_state, Oid orig_type)
{
	Oid base_type;

	/*
	 * CSTRINGOID means update_tsql_datatype_and_val already converted the
	 * value to a formatted C string (e.g. datetime → "2023-07-04T00:00:00").
	 * Just XML-escape it directly.
	 */
	if (orig_type == CSTRINGOID)
		return escape_xml(DatumGetCString(value));

	base_type = auto_state->base_types[col_idx];

	/*
	 * Types requiring special XSD formatting — fall back to the full
	 * map_sql_value_to_xml_value which handles them correctly.
	 */
	switch (base_type)
	{
		case BOOLOID:
		case DATEOID:
		case TIMESTAMPOID:
		case TIMESTAMPTZOID:
		case BYTEAOID:
		case XMLOID:
			return map_sql_value_to_xml_value(value, orig_type, true);
		default:
			break;
	}

	/* Array domains also need the full path */
	if (type_is_array_domain(orig_type))
		return map_sql_value_to_xml_value(value, orig_type, true);

	/* Fast path: use cached FmgrInfo directly, then escape for XML */
	return escape_xml(OutputFunctionCall(&auto_state->out_finfo[col_idx], value));
}

/*
 * Initialize the output function cache for all columns.
 * Must be called once with a valid TupleDesc before using cached_value_to_xml_string.
 */
static void
init_output_func_cache(forxml_auto_state *auto_state, TupleDesc tupdesc)
{
	for (int i = 0; i < auto_state->num_columns; i++)
	{
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);
		Oid base_type;
		Oid typeOut;
		bool isvarlena;

		if (att->attisdropped)
			continue;

		base_type = getBaseType(att->atttypid);
		auto_state->base_types[i] = base_type;

		getTypeOutputInfo(base_type, &typeOut, &isvarlena);
		fmgr_info(typeOut, &auto_state->out_finfo[i]);
	}
	auto_state->out_funcs_cached = true;
}

/*
 * Initialize the equality-operator cache for all columns.
 *
 * Used by find_first_changed_level to detect sibling-group boundaries in
 * FOR XML AUTO the same way T-SQL does: via the column type's equality
 * operator under the column's collation, not byte equality of the
 * serialized output.  For types without a default btree equality we mark
 * the column as eq-less and fall back to strcmp at compare time.
 */
static void
init_eq_op_cache(forxml_auto_state *auto_state, TupleDesc tupdesc)
{
	auto_state->eq_finfo = (FmgrInfo *) palloc0(auto_state->num_columns * sizeof(FmgrInfo));
	auto_state->eq_collation = (Oid *) palloc0(auto_state->num_columns * sizeof(Oid));
	auto_state->has_eq_op = (bool *) palloc0(auto_state->num_columns * sizeof(bool));
	auto_state->type_typlen = (int16 *) palloc0(auto_state->num_columns * sizeof(int16));
	auto_state->type_typbyval = (bool *) palloc0(auto_state->num_columns * sizeof(bool));

	for (int i = 0; i < auto_state->num_columns; i++)
	{
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);
		Oid base_type;
		TypeCacheEntry *tce;

		if (att->attisdropped)
			continue;

		base_type = auto_state->base_types[i];
		if (base_type == InvalidOid)
			base_type = getBaseType(att->atttypid);

		/* Capture typlen/typbyval for later datumCopy of prev row value */
		get_typlenbyval(base_type,
						&auto_state->type_typlen[i],
						&auto_state->type_typbyval[i]);

		/* Look up the type's default equality operator and its FmgrInfo */
		tce = lookup_type_cache(base_type, TYPECACHE_EQ_OPR_FINFO);
		if (OidIsValid(tce->eq_opr_finfo.fn_oid))
		{
			fmgr_info(tce->eq_opr_finfo.fn_oid, &auto_state->eq_finfo[i]);
			auto_state->has_eq_op[i] = true;
			/*
			 * Use the column's declared collation for the comparison, so
			 * case-insensitive and accent-insensitive collations group as
			 * T-SQL does.
			 */
			auto_state->eq_collation[i] = att->attcollation;
		}
		else
		{
			auto_state->has_eq_op[i] = false;
		}
	}

	auto_state->eq_cache_init = true;
}


/*
 * Initialize the T-SQL datatype conversion cache for all columns.
 * Determines once per column whether it needs special T-SQL datetime formatting.
 *
 * Looks up the OIDs of the known T-SQL types once, then compares each
 * column's atttypid directly against those OIDs.  No per-column SPI_gettype
 * or strcmp needed.
 *
 * tsql_convert_type values: 0 = no conversion, 1 = datetime, 2 = datetimeoffset,
 * 3 = binary types (error when binary_base64 is set)
 */
static void
init_tsql_type_cache(forxml_auto_state *auto_state, TupleDesc tupdesc)
{
	Oid nspoid = get_namespace_oid("sys", true);
	Oid datetime_oid;
	Oid smalldatetime_oid;
	Oid datetime2_oid;
	Oid datetimeoffset_oid;
	Oid binary_oid;
	Oid varbinary_oid;
	Oid image_oid;
	Oid bbf_timestamp_oid;
	Oid rowversion_oid;

	if (!OidIsValid(nspoid))
	{
		auto_state->tsql_types_cached = true;
		return;
	}

	/* Look up known T-SQL type OIDs once */
	datetime_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
								   CStringGetDatum("datetime"), ObjectIdGetDatum(nspoid));
	smalldatetime_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
										CStringGetDatum("smalldatetime"), ObjectIdGetDatum(nspoid));
	datetime2_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
									CStringGetDatum("datetime2"), ObjectIdGetDatum(nspoid));
	datetimeoffset_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
										 CStringGetDatum("datetimeoffset"), ObjectIdGetDatum(nspoid));
	binary_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
								 CStringGetDatum("binary"), ObjectIdGetDatum(nspoid));
	varbinary_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
									CStringGetDatum("varbinary"), ObjectIdGetDatum(nspoid));
	image_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
								CStringGetDatum("image"), ObjectIdGetDatum(nspoid));
	bbf_timestamp_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
										CStringGetDatum("timestamp"), ObjectIdGetDatum(nspoid));
	rowversion_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
									 CStringGetDatum("rowversion"), ObjectIdGetDatum(nspoid));

	for (int i = 0; i < auto_state->num_columns; i++)
	{
		Form_pg_attribute att = TupleDescAttr(tupdesc, i);
		Oid typid;

		if (att->attisdropped)
			continue;

		typid = att->atttypid;

		if (typid == datetime_oid || typid == smalldatetime_oid || typid == datetime2_oid)
			auto_state->tsql_convert_type[i] = 1;
		else if (typid == datetimeoffset_oid)
			auto_state->tsql_convert_type[i] = 2;
		else if (typid == binary_oid || typid == varbinary_oid || typid == image_oid ||
				 typid == bbf_timestamp_oid || typid == rowversion_oid)
			auto_state->tsql_convert_type[i] = 3;
	}
	auto_state->tsql_types_cached = true;
}

/*
 * Cached version of update_tsql_datatype_and_val for AUTO mode.
 * Uses pre-computed tsql_convert_type to skip catalog lookups on every row.
 */
static void
cached_update_tsql_datatype_and_val(HeapTuple tuple, TupleDesc tupdesc,
									Oid *datatype_oid, Datum *colval,
									int col_idx, forxml_auto_state *auto_state)
{
	int convert_type = auto_state->tsql_convert_type[col_idx];

	if (convert_type == 1)
	{
		/* datetime / smalldatetime / datetime2 */
		char *val = SPI_getvalue(tuple, tupdesc, col_idx + 1);
		StringInfo format_output;

		/* SPI_getvalue returns NULL for a null column; nothing to format */
		if (val == NULL)
			return;

		format_output = makeStringInfo();
		tsql_for_datetime_format(format_output, val);
		*colval = CStringGetDatum(format_output->data);
		*datatype_oid = CSTRINGOID;
		pfree(format_output);	/* free StringInfo struct, data is kept via colval */
	}
	else if (convert_type == 2)
	{
		/* datetimeoffset */
		char *val = SPI_getvalue(tuple, tupdesc, col_idx + 1);
		StringInfo format_output;

		if (val == NULL)
			return;

		format_output = makeStringInfo();
		tsql_for_datetimeoffset_format(format_output, val);
		*colval = CStringGetDatum(format_output->data);
		*datatype_oid = CSTRINGOID;
		pfree(format_output);	/* free StringInfo struct, data is kept via colval */
	}
	else if (convert_type == 3 && auto_state->binary_base64)
	{
		/* binary / varbinary / image / timestamp / rowversion */
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("option binary base64 is not supported")));
	}
	/* else: convert_type == 0, no conversion needed */
}

/*
 * Output XML for current row in AUTO mode.
 *
 * Algorithm:
 * 1. Find the first level where values changed from previous row
 * 2. Close open elements from deepest back to the changed level
 * 3. For each level from changed level to max_depth:
 *    a. Open element tag with table alias
 *    b. Add all column attributes for that level
 *    c. If this is the deepest level with columns in this row, self-close
 *    d. Otherwise close the opening tag with ">" to allow children
 * 4. Store current values for next row comparison
 */
static void
output_row_xml(StringInfo state, forxml_auto_state *auto_state, HeapTuple tuple, TupleDesc tupdesc, bool elements, bool xsinil)
{
	int first_changed_level;
	int deepest_level_in_row = auto_state->max_depth;

	/* Initialize output function cache on first row (covers all columns) */
	if (!auto_state->out_funcs_cached)
		init_output_func_cache(auto_state, tupdesc);

	/* Initialize T-SQL type conversion cache on first row */
	if (!auto_state->tsql_types_cached)
		init_tsql_type_cache(auto_state, tupdesc);

	/*
	 * Initialize equality-operator cache on first row.  Depends on
	 * base_types[] from init_output_func_cache, so must run after it.
	 */
	if (!auto_state->eq_cache_init)
		init_eq_op_cache(auto_state, tupdesc);

	/* Find where this row differs from previous */
	first_changed_level = find_first_changed_level(auto_state, tuple, tupdesc);

	/*
	 * If no visible column changed (all values identical to previous row),
	 * we still need to emit the deepest-level element again. The expected
	 * behavior is one leaf element per input row regardless of duplicate values.
	 */
	if (!auto_state->first_row && first_changed_level > deepest_level_in_row)
		first_changed_level = deepest_level_in_row;

	/* Close elements that have changed */
	if (!auto_state->first_row && first_changed_level <= auto_state->max_depth)
	{
		for (int level = auto_state->max_depth; level >= first_changed_level; level--)
		{
			if (auto_state->open_element_levels[level] > 0)
			{
				for (int j = 0; j < auto_state->num_columns; j++)
				{
					if (auto_state->nest_levels[j] == level && auto_state->table_aliases[j] != NULL)
					{
						appendStringInfo(state, "</%s>", auto_state->table_aliases[j]);
						auto_state->open_element_levels[level] = 0;
						break;
					}
				}
			}
		}
	}

	/*
	 * Always emit all levels down to deepest_level_in_row, even if all
	 * columns at a level are NULL.  The expected behavior is to emit empty
	 * self-closing elements for all-NULL levels (e.g. LEFT JOIN with no
	 * matching rows still produces <o><i/></o> rather than skipping those
	 * levels).
	 */

	/* Output elements for each level from first_changed_level to deepest */
	for (int level = first_changed_level; level <= deepest_level_in_row; level++)
	{
		char *table_alias = auto_state->level_to_alias[level];
		bool has_columns_at_level = (table_alias != NULL);

		if (!has_columns_at_level || table_alias == NULL)
			continue;

		/* Open element tag */
		if (elements && xsinil && !auto_state->has_root && level == 1)
			appendStringInfo(state, "<%s " XML_XMLNS_XSI ">", table_alias);
		else if (elements)
			appendStringInfo(state, "<%s>", table_alias);
		else
			appendStringInfo(state, "<%s", table_alias);

		/* Add all columns for this level */
		for (int i = 0; i < auto_state->num_columns; i++)
		{
			Datum colval;
			bool isnull;
			Form_pg_attribute att;

			if (auto_state->nest_levels[i] != level)
				continue;

			att = TupleDescAttr(tupdesc, i);
			if (att->attisdropped)
				continue;

			colval = heap_getattr(tuple, i + 1, tupdesc, &isnull);

			if (elements)
			{
				/* ELEMENTS mode: <colname>value</colname> */
				if (!isnull)
				{
					char *val_str = auto_column_to_xml_string(colval, isnull, tuple, tupdesc, i, auto_state);
					appendStringInfo(state, "<%s>%s</%s>",
									auto_state->column_names[i],
									val_str,
									auto_state->column_names[i]);
				}
				else if (xsinil)
				{
					appendStringInfo(state, "<%s " XML_XSI_NIL "/>",
									auto_state->column_names[i]);
				}
				/* else: ABSENT mode - skip NULL columns */
			}
			else
			{
				/* ATTRIBUTES mode: col="value" */
				if (!isnull)
				{
					char *val_str = auto_column_to_xml_string(colval, isnull, tuple, tupdesc, i, auto_state);
					appendStringInfo(state, " %s=\"%s\"",
									auto_state->column_names[i],
									tsql_escape_xml(val_str));
				}
			}
		}

		/* Close or self-close the element tag */
		if (elements)
		{
			/* In ELEMENTS mode, tag is already closed with ">", leave open for children or close */
			if (level == deepest_level_in_row)
				appendStringInfo(state, "</%s>", table_alias);
			/* else: leave open for child elements */
		}
		else
		{
			/* In ATTRIBUTES mode, close the opening tag */
			if (level == deepest_level_in_row)
				appendStringInfoString(state, "/>");
			else
				appendStringInfoString(state, ">");
		}

		/*
		 * Mark this level as open.  The deepest level in this row is actually
		 * closed in the same step (</alias> in ELEMENTS mode, /> in
		 * ATTRIBUTES mode) and gets reset to 0 immediately after this loop;
		 * we set it uniformly here for loop simplicity.
		 */
		auto_state->open_element_levels[level] = 1;
	}

	/* prev state already updated in find_first_changed_level */

	/* On first row, capture prev state since find_first_changed_level skipped it */
	if (auto_state->first_row)
	{
		for (int i = 0; i < auto_state->num_columns; i++)
		{
			Form_pg_attribute att = TupleDescAttr(tupdesc, i);
			Datum curr_datum;
			bool curr_isnull;

			if (att->attisdropped || auto_state->nest_levels[i] == 0)
				continue;

			curr_datum = heap_getattr(tuple, i + 1, tupdesc, &curr_isnull);

			if (auto_state->has_eq_op[i])
			{
				if (curr_isnull)
					auto_state->prev_datums[i] = (Datum) 0;
				else
					auto_state->prev_datums[i] = datumCopy(curr_datum,
															auto_state->type_typbyval[i],
															auto_state->type_typlen[i]);
			}
			else
			{
				/* Fallback path: cache serialized form for strcmp */
				auto_state->prev_str_values[i] = auto_column_to_xml_string(curr_datum, curr_isnull, tuple, tupdesc, i, auto_state);
			}

			auto_state->prev_isnull[i] = curr_isnull;
		}
	}

	/* The deepest output level was self-closed, so mark it as not open */
	if (deepest_level_in_row > 0)
		auto_state->open_element_levels[deepest_level_in_row] = 0;

	auto_state->first_row = false;
}

/*
 * Map an SQL row to XML in AUTO mode.
 */
static void
tsql_row_to_xml_auto(StringInfo state, Datum record, bool elements, bool xsinil, forxml_auto_state *auto_state)
{
	HeapTupleHeader td;
	Oid tupType;
	int32 tupTypmod;
	TupleDesc tupdesc;
	HeapTupleData tmptup;
	HeapTuple tuple;

	td = DatumGetHeapTupleHeader(record);

	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);

	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	tmptup.t_data = td;
	tuple = &tmptup;

	/* First row: parse metadata if not already done */
	if (!auto_state->metadata_cached)
	{
		/* Metadata should have been parsed in sfunc init; if not, error */
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("FOR XML AUTO metadata not initialized")));
	}

	/* Generate hierarchical XML output */
	output_row_xml(state, auto_state, tuple, tupdesc, elements, xsinil);

	ReleaseTupleDesc(tupdesc);
}
