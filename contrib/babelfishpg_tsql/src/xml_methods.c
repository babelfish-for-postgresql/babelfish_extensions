/*-------------------------------------------------------------------------
 *
 * xml_methods.c
 *    C implementations of T-SQL XML data type methods (.query)
 *
 * Replaces the PL/pgSQL wrapper for sys.bbf_xmlquery with a direct C
 * implementation, eliminating per-call PL/pgSQL interpreter overhead.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "catalog/pg_type.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/fmgrprotos.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/xml.h"

#include "pltsql.h"

PG_FUNCTION_INFO_V1(bbf_xmlquery);

/*
 * get_tsql_type_name - Resolve a type OID to its T-SQL display name.
 *
 * Uses translate_pg_type_to_tsql via the common utility plugin.
 * For UDTs where the plugin returns NULL, falls back to the PG type
 * name at the immediate base level.
 *
 * Returns a palloc'd string.
 */
static const char *
get_tsql_type_name(Oid type_oid)
{
	const char *typname = NULL;
	LOCAL_FCINFO(tmp_fcinfo, 1);

	InitFunctionCallInfoData(*tmp_fcinfo, NULL, 0, InvalidOid, NULL, NULL);
	tmp_fcinfo->args[0].value = ObjectIdGetDatum(type_oid);
	tmp_fcinfo->args[0].isnull = false;

	/* Try direct translation first */
	if (common_utility_plugin_ptr)
	{
		Datum result;

		result = (*common_utility_plugin_ptr->translate_pg_type_to_tsql)(tmp_fcinfo);
		if (result)
			return text_to_cstring(DatumGetTextPP(result));
	}

	/* For UDTs: get immediate base type and try translation again */
	if (common_utility_plugin_ptr)
	{
		HeapTuple	typtup;
		Oid			immediate_base = InvalidOid;

		typtup = SearchSysCache1(TYPEOID, ObjectIdGetDatum(type_oid));
		if (HeapTupleIsValid(typtup))
		{
			Form_pg_type typform = (Form_pg_type) GETSTRUCT(typtup);

			immediate_base = typform->typbasetype;
			ReleaseSysCache(typtup);
		}

		if (OidIsValid(immediate_base))
		{
			Datum result;

			tmp_fcinfo->args[0].value = ObjectIdGetDatum(immediate_base);
			result = (*common_utility_plugin_ptr->translate_pg_type_to_tsql)(tmp_fcinfo);
			if (result)
				typname = text_to_cstring(DatumGetTextPP(result));
		}
	}

	if (typname == NULL)
		typname = format_type_be(type_oid);

	return typname;
}

/*
 * bbf_xmlquery - C implementation of XML .query() method
 *
 * Signature:
 *   sys.bbf_xmlquery(xpath_pattern TEXT, xml_element ANYELEMENT)
 *
 * Returns XML result of evaluating the XPath expression against the input.
 * Returns empty XML if no nodes match.
 *
 * Validates:
 *   - Input must be XML type (or UDT based on XML)
 *   - QUOTED_IDENTIFIER must be ON
 *   - XML must not contain DTD declarations
 */
Datum
bbf_xmlquery(PG_FUNCTION_ARGS)
{
	text	   *xpath_expr;
	Datum		xml_datum;
	Oid			arg_type;
	Oid			base_type;
	ArrayType  *namespaces;
	Datum		xpath_result;
	ArrayType  *result_arr;
	Datum	   *elems;
	bool	   *nulls;
	int			nitems;
	const char *quoted_identifier;
	StringInfoData buf;
	int			i;

	/* Strict: return NULL if any argument is NULL */
	if (PG_ARGISNULL(0) || PG_ARGISNULL(1))
		PG_RETURN_NULL();

	xpath_expr = PG_GETARG_TEXT_PP(0);
	xml_datum = PG_GETARG_DATUM(1);

	/*
	 * Validate that the input is XML type.
	 * Resolve through domains/UDTs to the base type.
	 */
	arg_type = get_fn_expr_argtype(fcinfo->flinfo, 1);
	base_type = getBaseType(arg_type);

	if (base_type != XMLOID)
	{
		const char *typname;

		/* Get T-SQL type name for error message */
		typname = get_tsql_type_name(arg_type);
		if (typname == NULL)
			typname = format_type_be(arg_type);

		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("Cannot call methods on %s.", typname)));
	}

	/* Check QUOTED_IDENTIFIER setting (required for XML methods in T-SQL) */
	quoted_identifier = GetConfigOption("babelfishpg_tsql.quoted_identifier",
										true, false);
	if (quoted_identifier != NULL && strcmp(quoted_identifier, "off") == 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("SELECT failed because the following SET options have "
						"incorrect settings: 'QUOTED_IDENTIFIER'. Verify that "
						"SET options are correct for XML data type methods.")));

	/*
	 * T-SQL does not allow internal subset DTDs in XML typed values.
	 */
	{
		char	   *xml_str = TextDatumGetCString(xml_datum);

		if (strstr(xml_str, "<!DOCTYPE") != NULL)
		{
			pfree(xml_str);
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_XML_CONTENT),
					 errmsg("%s", "invalid XML content")));
		}
		pfree(xml_str);
	}

	/*
	 * Call the built-in xpath(text, xml, text[][]) directly with an empty
	 * namespace array. Returns xml[] (array of XML fragments).
	 */
	namespaces = construct_empty_array(TEXTOID);
	xpath_result = DirectFunctionCall3Coll(xpath,
										   InvalidOid,
										   PointerGetDatum(xpath_expr),
										   xml_datum,
										   PointerGetDatum(namespaces));

	result_arr = DatumGetArrayTypeP(xpath_result);

	/* Deconstruct the result array */
	deconstruct_array(result_arr, XMLOID, -1, false, TYPALIGN_INT,
					  &elems, &nulls, &nitems);

	/* Empty result → return empty string as XML (matches T-SQL behavior) */
	if (nitems == 0)
		PG_RETURN_XML_P((xmltype *) cstring_to_text(""));

	/* Single result → return directly (common fast path) */
	if (nitems == 1 && !nulls[0])
		PG_RETURN_DATUM(elems[0]);

	/*
	 * Multiple results - concatenate all XML fragments.
	 * Equivalent to: SELECT xmlagg(x) FROM unnest(result_set) AS x
	 */
	initStringInfo(&buf);
	for (i = 0; i < nitems; i++)
	{
		if (!nulls[i])
		{
			char *fragment = TextDatumGetCString(elems[i]);

			appendStringInfoString(&buf, fragment);
			pfree(fragment);
		}
	}

	PG_RETURN_XML_P((xmltype *) cstring_to_text(buf.data));
}
