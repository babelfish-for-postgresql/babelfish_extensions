#include "postgres.h"

#include "collation.h"
#include "fmgr.h"
#include "guc.h"
#include "utils/hsearch.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/memutils.h"
#include "utils/builtins.h"
#include "catalog/pg_type.h"
#include "catalog/pg_collation.h"
#include "catalog/namespace.h"
#include "tsearch/ts_locale.h"
#include "parser/parser.h"
#include "parser/parse_coerce.h"
#include "parser/parse_type.h"
#include "parser/parse_oper.h"
#include "nodes/makefuncs.h"
#include "nodes/nodes.h"
#ifdef USE_ICU
#include <unicode/utrans.h>
#include "utils/removeaccent.map"
#include <unicode/ucol.h>
#include <unicode/usearch.h>
#endif

#include "pltsql.h"
#include "src/collation.h"
#include "catalog.h"

#define NOT_FOUND -1
#define SORT_KEY_STR "\357\277\277\0"

/* 
 * Rule applied to transliterate Latin and general category Nd character 
 * then convert the Latin (source) char to ASCII (destination) representation
 */
#define TRANSFORMATION_RULE "[[:Latin:][:Nd:]]; Latin-ASCII"

/*
 * The maximum number of bytes per character is 4 according 
 * to RFC3629 which limited the character table to U+10FFFF
 * Ref: https://www.rfc-editor.org/rfc/rfc3629#section-3
 */
#define MAX_BYTES_PER_CHAR 4
#define MAX_INPUT_LENGTH_TO_REMOVE_ACCENTS 250 * 1024 * 1024

/*
 * Check if Uchar is lead surrogate pair, If Uchar is in
 * the range D800 - DBFF then it is a lead surrogate pair
 */
#define UCHAR_IS_SURROGATE(c) ((c & 0xF800) == 0xD800)

/* Find length of given Uchar */
#define UCHAR_LENGTH(c) (UCHAR_IS_SURROGATE(c) ? 2 : 1)

Oid			database_or_server_collation_oid = InvalidOid;

collation_callbacks *collation_callbacks_ptr = NULL;
extern bool babelfish_dump_restore;
static Oid remove_accents_internal_oid;
static UTransliterator *cached_transliterator = NULL;

static Node *pgtsql_expression_tree_mutator(Node *node, void *context);
static void init_and_check_collation_callbacks(void);
static int patindex_ai_match_text(pg_locale_t mylocale, char *input_str, char *pattern, Oid cid, bool is_cs_ai);

extern int	pattern_fixed_prefix_wrapper(Const *patt,
										 int ptype,
										 Oid collation,
										 Const **prefix,
										 Selectivity *rest_selec);

/* pattern prefix status for pattern_fixed_prefix_wrapper
 * Pattern_Prefix_None: no prefix found, this means the first character is a wildcard character
 * Pattern_Prefix_Exact: the pattern doesn't include any wildcard character
 * Pattern_Prefix_Partial: the pattern has a constant prefix
 */
typedef enum
{
	Pattern_Prefix_None, Pattern_Prefix_Partial, Pattern_Prefix_Exact
} Pattern_Prefix_Status;

PG_FUNCTION_INFO_V1(init_collid_trans_tab);
PG_FUNCTION_INFO_V1(init_like_ilike_table);
PG_FUNCTION_INFO_V1(get_server_collation_oid);
PG_FUNCTION_INFO_V1(is_collated_ci_as_internal);
PG_FUNCTION_INFO_V1(is_collated_ai_internal);

/* this function is no longer needed and is only a placeholder for upgrade script */
PG_FUNCTION_INFO_V1(init_server_collation);
Datum
init_server_collation(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

/* this function is no longer needed and is only a placeholder for upgrade script */
PG_FUNCTION_INFO_V1(init_server_collation_oid);
Datum
init_server_collation_oid(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

/* init_collid_trans_tab - this function is no longer needed and is only a placeholder for upgrade script */
Datum
init_collid_trans_tab(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(collation_list);

Datum
collation_list(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(tsql_collation_list_internal(fcinfo));
}


/*
 * get_server_collation_oid - this is being used by sys.babelfish_update_collation_to_default
 * to update the collation of system objects
 */
Datum
get_server_collation_oid(PG_FUNCTION_ARGS)
{
	PG_RETURN_OID(tsql_get_database_or_server_collation_oid_internal(false));
}


Datum
is_collated_ci_as_internal(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(tsql_is_collated_ci_as_internal(fcinfo));
}

Datum
is_collated_ai_internal(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(tsql_is_collated_ai_internal(fcinfo));
}

/* init_like_ilike_table - this function is no longer needed and is only a placeholder for upgrade script */
Datum
init_like_ilike_table(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

static Expr *
make_op_with_func(Oid opno, Oid opresulttype, bool opretset,
				  Expr *leftop, Expr *rightop,
				  Oid opcollid, Oid inputcollid, Oid oprfuncid)
{
	OpExpr	   *expr = (OpExpr *) make_opclause(opno,
												opresulttype,
												opretset,
												leftop,
												rightop,
												opcollid,
												inputcollid);

	expr->opfuncid = oprfuncid;
	return (Expr *) expr;
}

/* helper fo make or qual, simialr to make_and_qual  */
static Node *
make_or_qual(Node *qual1, Node *qual2)
{
	if (qual1 == NULL)
		return qual2;
	if (qual2 == NULL)
		return qual1;
	return (Node *) make_orclause(list_make2(qual1, qual2));
}

static Node *
transform_funcexpr(Node *node)
{
	if (node && IsA(node, FuncExpr))
	{
		FuncExpr   *fe = (FuncExpr *) node;
		int			collidx_of_cs_as;

		if (fe->funcid == 868 || //strpos - see pg_proc.dat
		/* fe->funcid == 394  ||  // string_to_array, 3-arg form */
		/* fe->funcid == 376  ||  // string_to_array, 2-arg form */
			fe->funcid == 2073 || //substring - 2 - arg form, see pg_proc.dat
			fe->funcid == 2074 || //substring - 3 - arg form, see pg_proc.dat

			fe->funcid == 2285 || //regexp_replace, flags in 4 th arg
			fe->funcid == 3397 || //regexp_match(find first match), flags in 3 rd arg
			fe->funcid == 2764)
			/* regexp_matches, flags in 3 rd arg */
		{
			coll_info_t coll_info_of_inputcollid = tsql_lookup_collation_table_internal(fe->inputcollid);
			Node	   *leftop = (Node *) linitial(fe->args);
			Node	   *rightop = (Node *) lsecond(fe->args);

			if (OidIsValid(coll_info_of_inputcollid.oid) &&
				coll_info_of_inputcollid.collateflags == 0x000d /* CI_AS  */ )
			{
				Oid			lower_funcid = 870;

				/* lower */
				Oid result_type = 25;

				/* text */

				tsql_get_database_or_server_collation_oid_internal(true);

				if (!OidIsValid(database_or_server_collation_oid))
					return node;

				/*
				 * Find the CS_AS collation corresponding to the CI_AS
				 * collation Change the collation of the func op to the CS_AS
				 * collation
				 */
				collidx_of_cs_as =
					tsql_find_cs_as_collation_internal(
													   tsql_find_collation_internal(coll_info_of_inputcollid.collname));

				if (NOT_FOUND == collidx_of_cs_as)
					return node;

				if (fe->funcid == 2285 || fe->funcid == 3397 || fe->funcid == 2764)
				{
					Node	   *flags = (fe->funcid == 2285) ? lfourth(fe->args) : lthird(fe->args);

					if (!IsA(flags, Const))
						return node;
					else
					{
						char	   *patt = TextDatumGetCString(((Const *) flags)->constvalue);
						int			f = 0;

						while (patt[f] != '\0')
						{
							if (patt[f] == 'i')
								break;

							f++;
						}

						/*
						 * If the 'i' flag was specified then the operation is
						 * case-insensitive and so the ci_as collation may be
						 * replaced with the corresponding deterministic cs_as
						 * collation. If not, return.
						 */
						if (patt[f] != 'i')
							return node;
					}
				}

				fe->inputcollid = tsql_get_oid_from_collidx(collidx_of_cs_as);

				if (fe->funcid >= 2285)
					return node;

				/*
				 * regexp operators have their own way to handle case
				 * -insensitivity
				 */

				if (!IsA(leftop, FuncExpr) || ((FuncExpr *) leftop)->funcid != lower_funcid)
					leftop = (Node *) makeFuncExpr(lower_funcid,
												   result_type,
												   list_make1(leftop),
												   fe->inputcollid,
												   fe->inputcollid,
												   COERCE_EXPLICIT_CALL);
				if (!IsA(rightop, FuncExpr) || ((FuncExpr *) rightop)->funcid != lower_funcid)
					rightop = (Node *) makeFuncExpr(lower_funcid,
													result_type,
													list_make1(rightop),
													fe->inputcollid,
													fe->inputcollid,
													COERCE_EXPLICIT_CALL);

				if (list_length(fe->args) == 3)
				{
					Node	   *thirdop = (Node *) makeFuncExpr(lower_funcid,
																result_type,
																list_make1(lthird(fe->args)),
																fe->inputcollid,
																fe->inputcollid,
																COERCE_EXPLICIT_CALL);

					fe->args = list_make3(leftop, rightop, thirdop);
				}
				else if (list_length(fe->args) == 2)
				{
					fe->args = list_make2(leftop, rightop);
				}
			}
		}
	}

	return node;
}

/*
 * If the node is OpExpr and the colaltion is ci_as, then
 * transform the LIKE OpExpr to ILIKE OpExpr:
 *
 * Case 1: if the pattern is a constant stirng
 *		 col LIKE PATTERN -> col = PATTERN
 * Case 2: if the pattern have a constant prefix
 *		 col LIKE PATTERN ->
 *		 col LIKE PATTERN BETWEEN prefix AND prefix||E'\uFFFF'
 * Case 3: if the pattern doesn't have a constant prefix
 *		 col LIKE PATTERN -> col ILIKE PATTERN
 */

static Node *
transform_from_ci_as_for_likenode(Node *node, OpExpr *op, like_ilike_info_t like_entry, coll_info_t coll_info_of_inputcollid)
{
	Node	   *leftop = (Node *) linitial(op->args);
	Node	   *rightop = (Node *) lsecond(op->args);
	Oid			ltypeId = exprType(leftop);
	Oid			rtypeId = exprType(rightop);
	char	   *op_str;
	Node	   *ret;
	Const	   *patt;
	Const	   *prefix;
	Operator	optup;
	Pattern_Prefix_Status pstatus;
	int			collidx_of_cs_as;

	tsql_get_database_or_server_collation_oid_internal(true);

	if (!OidIsValid(database_or_server_collation_oid))
		return node;


	/*
	 * Find the CS_AS collation corresponding to the CI_AS collation
	 * Change the collation of the ILIKE op to the CS_AS collation
	 */
	collidx_of_cs_as =
		tsql_find_cs_as_collation_internal(
											tsql_find_collation_internal(coll_info_of_inputcollid.collname));


	/*
	 * A CS_AS collation should always exist unless a Babelfish CS_AS
	 * collation was dropped or the lookup tables were not defined in
	 * lexicographic order.  Program defensively here and just do no
	 * transformation in this case, which will generate a
	 * 'nondeterministic collation not supported' error.
	 */

	if (NOT_FOUND == collidx_of_cs_as)
	{
		elog(DEBUG2, "No corresponding CS_AS collation found for collation \"%s\"", coll_info_of_inputcollid.collname);
		return node;
	}

	/* Change the opno and oprfuncid to ILIKE */
	op->opno = like_entry.ilike_oid;
	op->opfuncid = like_entry.ilike_opfuncid;

	op->inputcollid = tsql_get_oid_from_collidx(collidx_of_cs_as);

	/* 
	 * This is needed to process CI_AI for Const nodes
	 * Because after we call coerce_to_target_type for type conversion in transform_likenode_for_AI,
	 * we obtain a Relabel node which won't help us to perform optimization
	 * for constant prefix. Hence, we process that here
	 */
	if (IsA(rightop, RelabelType))
	{
		RelabelType		*relabel = (RelabelType *) rightop;
		if (IsA(relabel->arg, Const))
		{
			lsecond(op->args) = relabel->arg;
			rightop = (Node *) lsecond(op->args);
		}
	}

	/* no constant prefix found in pattern, or pattern is not constant */
	if (IsA(leftop, Const) || !IsA(rightop, Const) ||
		((Const *) rightop)->constisnull)
	{
		return node;
	}

	patt = (Const *) rightop;

	/* extract pattern */
	pstatus = pattern_fixed_prefix_wrapper(patt, 1, coll_info_of_inputcollid.oid,
											&prefix, NULL);

	/* If there is no constant prefix then there's nothing more to do */
	if (pstatus == Pattern_Prefix_None)
	{
		return node;
	}

	/*
	 * If we found an exact-match pattern, generate an "=" indexqual.
	 */
	if (pstatus == Pattern_Prefix_Exact)
	{
		op_str = like_entry.is_not_match ? "<>" : "=";
		optup = compatible_oper(NULL, list_make1(makeString(op_str)), ltypeId, ltypeId,
								true, -1);
		if (optup == (Operator) NULL)
			return node;

		ret = (Node *) (make_op_with_func(oprid(optup), BOOLOID, false,
											(Expr *) leftop, (Expr *) prefix,
											InvalidOid, coll_info_of_inputcollid.oid, oprfuncid(optup)));

		ReleaseSysCache(optup);
	}
	else
	{
		Expr	   *greater_equal,
					*less_equal,
					*concat_expr;
		Node	   *constant_suffix;
		Const	   *highest_sort_key;

		/* construct leftop >= pattern */
		optup = compatible_oper(NULL, list_make1(makeString(">=")), ltypeId, ltypeId,
								true, -1);
		if (optup == (Operator) NULL)
			return node;
		greater_equal = make_op_with_func(oprid(optup), BOOLOID, false,
											(Expr *) leftop, (Expr *) prefix,
											InvalidOid, coll_info_of_inputcollid.oid, oprfuncid(optup));
		ReleaseSysCache(optup);
		/* construct pattern||E'\uFFFF' */
		highest_sort_key = makeConst(TEXTOID, -1, coll_info_of_inputcollid.oid, -1,
										PointerGetDatum(cstring_to_text(SORT_KEY_STR)), false, false);

		optup = compatible_oper(NULL, list_make1(makeString("||")), rtypeId, rtypeId,
								true, -1);
		if (optup == (Operator) NULL)
			return node;
		concat_expr = make_op_with_func(oprid(optup), rtypeId, false,
										(Expr *) prefix, (Expr *) highest_sort_key,
										InvalidOid, coll_info_of_inputcollid.oid, oprfuncid(optup));
		ReleaseSysCache(optup);
		/* construct leftop < pattern */
		optup = compatible_oper(NULL, list_make1(makeString("<")), ltypeId, ltypeId,
								true, -1);
		if (optup == (Operator) NULL)
			return node;

		less_equal = make_op_with_func(oprid(optup), BOOLOID, false,
										(Expr *) leftop, (Expr *) concat_expr,
										InvalidOid, coll_info_of_inputcollid.oid, oprfuncid(optup));
		constant_suffix = make_and_qual((Node *) greater_equal, (Node *) less_equal);
		if (like_entry.is_not_match)
		{
			constant_suffix = (Node *) make_notclause((Expr *) constant_suffix);
			ret = make_or_qual(node, constant_suffix);
		}
		else
		{
			constant_suffix = make_and_qual((Node *) greater_equal, (Node *) less_equal);
			ret = make_and_qual(node, constant_suffix);
		}
		ReleaseSysCache(optup);
	}
	return ret;
}

/*
 * Only use cached mappings for removing accents when the
 * current ICU version matches to the one used to generate
 * the cache. Otherwise we fallback on the ICU function
 */
static void
get_remove_accents_internal_oid()
{
	const Oid funcargtypes[1] = {TEXTOID};
	if (OidIsValid(remove_accents_internal_oid))
		return;

#ifdef USE_ICU
	if (U_ICU_VERSION_MAJOR_NUM == pltsql_remove_accent_map_icu_major_version && U_ICU_VERSION_MINOR_NUM == pltsql_remove_accent_map_icu_min_version)
	{
		elog(LOG, "Using cached mappings to remove accents");
		remove_accents_internal_oid = LookupFuncName(list_make2(makeString("sys"), makeString("remove_accents_internal_using_cache")), -1, funcargtypes, true);
		return;
	}
#endif
	elog(LOG, "Using ICU function to remove accents");
	remove_accents_internal_oid = LookupFuncName(list_make2(makeString("sys"), makeString("remove_accents_internal")), -1, funcargtypes, true);
}

/*
 * store 32bit character representation into multibyte stream
 */
static inline void
store_coded_char(unsigned char *dest, uint32 code)
{
	if (code & 0xff000000)
	{
		*dest++ = code >> 24;
	}
	if (code & 0x00ff0000)
	{
		*dest++ = code >> 16;
	}
	if (code & 0x0000ff00)
	{
		*dest++ = code >> 8;
	}
	if (code & 0x000000ff)
	{
		*dest++ = code;
	}
	*dest = '\0';
	return;
}

static int
compare_remove_accent_map_pair(const void *p1, const void *p2)
{
	uint32		v1,
				v2;

	v1 = *(const uint32 *) p1;
	v2 = ((const remove_accent_map_pair *) p2)->original_char;
	return (v1 > v2) ? 1 : ((v1 == v2) ? 0 : -1);
}

PG_FUNCTION_INFO_V1(remove_accents_internal_using_cache);
Datum remove_accents_internal_using_cache(PG_FUNCTION_ARGS)
{
	unsigned char *input_str,
	              *input_str_start,
	              *normalized_char;
	int           len,
	              char_len;
	text          *return_result;
	StringInfoData result;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	input_str = (unsigned char *) text_to_cstring(PG_GETARG_TEXT_PP(0));
	input_str_start = input_str;
	len = strlen((char *) input_str);
	initStringInfo(&result);
	normalized_char = (unsigned char *) palloc(sizeof(uint32) + 1);

	for (; len > 0; len -= char_len)
	{
		unsigned char b1 = 0;
		unsigned char b2 = 0;
		unsigned char b3 = 0;
		unsigned char b4 = 0;
		uint32 utf8_char;
		uint32 utf8_normalized_str;
		remove_accent_map_pair *pr;

		/* "break" cases all represent errors */
		if (*input_str == '\0')
			break;

		char_len = pg_utf_mblen(input_str);
		
		if (len < char_len)
			break;

		if (!pg_utf8_islegal(input_str, char_len))
			break;

		if (char_len == 1)
		{
			appendBinaryStringInfo(&result, input_str++, 1);
			continue;
		}

		/* collect coded char of length l */
		if (char_len == 2)
		{
			b3 = *input_str++;
			b4 = *input_str++;
		}
		else if (char_len == 3)
		{
			b2 = *input_str++;
			b3 = *input_str++;
			b4 = *input_str++;
		}
		else if (char_len == 4)
		{
			b1 = *input_str++;
			b2 = *input_str++;
			b3 = *input_str++;
			b4 = *input_str++;
		}
		else
		{
			elog(ERROR, "unsupported character length %d", char_len);
		}

		utf8_char = (b1 << 24 | b2 << 16 | b3 << 8 | b4);

		pr = bsearch(&utf8_char, pltsql_remove_accent_map, lengthof(pltsql_remove_accent_map),
							sizeof(remove_accent_map_pair), compare_remove_accent_map_pair);

		/* Use the mapping if availaible or else the character */
		if (pr && pr->normalized_char)
			utf8_normalized_str = pr->normalized_char;
		else
			utf8_normalized_str = utf8_char;

		store_coded_char(normalized_char, utf8_normalized_str);

		appendBinaryStringInfo(&result, normalized_char, strlen((const char *) normalized_char));
	}

	if (len > 0)
		ereport(ERROR,
			(errcode(ERRCODE_CHARACTER_NOT_IN_REPERTOIRE),
			 errmsg("invalid byte sequence for encoding UTF-8 while removing accents")));

	return_result = cstring_to_text_with_len(result.data, result.len);
	pfree(result.data);
	pfree(input_str_start);
	pfree(normalized_char);

	PG_RETURN_VARCHAR_P(return_result);
}

/*
 * Function responsible for obtaining unaccented version of input
 * string with the help of ICU provided APIs. 
 * We use a transformation rule to transliterate the string
 */

PG_FUNCTION_INFO_V1(remove_accents_internal);
Datum remove_accents_internal(PG_FUNCTION_ARGS)
{
	char *input_str = text_to_cstring(PG_GETARG_TEXT_PP(0));
	UChar *utf16_input, *utf16_res;
	int32_t len_uinput, limit, capacity, len_result;
	char *result;
	UErrorCode status = U_ZERO_ERROR;
	text *res_str;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

#ifdef USE_ICU
	// Check if transliterator is not yet cached
	if (!cached_transliterator)
	{
		MemoryContext oldcontext;
		UChar *rules;
		int32_t len_uchar;

		// Switch to TopMemoryContext for allocating cached transliterator
		oldcontext = MemoryContextSwitchTo(TopMemoryContext);

		// Load transliterator rules
		len_uchar = icu_to_uchar(&rules, TRANSFORMATION_RULE, strlen(TRANSFORMATION_RULE));

		// Open transliterator
		cached_transliterator = utrans_openU(rules, len_uchar, UTRANS_FORWARD, NULL, 0, NULL, &status);
		if (U_FAILURE(status) || !cached_transliterator)
		{
			ereport(ERROR,
					(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
						errmsg("Error opening transliterator: %s", u_errorName(status))));
		}

		// Switch back to original memory context
		MemoryContextSwitchTo(oldcontext);
	}

	/*
	 * XXX: Currently, we are allowing length of input string upto 250MB bytes. For long term,
	 * we should try to chunk the input string into smaller parts, remove the accents of that
	 * part and concat back the final string.
	 */
	if (strlen(input_str) > MAX_INPUT_LENGTH_TO_REMOVE_ACCENTS)
	{
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
					errmsg("Input string of the length greater than 250MB is not supported by the function remove_accents_internal." \
							" This function might be used internally by LIKE operator.")));
	}

	len_uinput = icu_to_uchar(&utf16_input, input_str, strlen(input_str));

	limit = len_uinput;
	/* 
	 * set the capacity (In UChar terms) to limit * MAX_BYTES_PER_CHAR if it is less than INT32_MAX
	 * else set it to INT32_MAX as capacity is of int32_t datatype so it can have maximum INT32_MAX
	 * value which would be equivalent to 2GB UChar points and 2GB * sizeof(UChar) in byte terms.
	 * XXX: It is assumed that this capacity should handle almost all the general input strings.
	 */
	capacity = (limit < (PG_INT32_MAX / MAX_BYTES_PER_CHAR)) ? (limit * MAX_BYTES_PER_CHAR) : PG_INT32_MAX;

	/*
	 * utrans_transUChars will modify input string in place so ensure that it has enough capacity to store
	 * transformed string.
	 */
	utf16_res = (UChar *) palloc0(capacity * sizeof(UChar));
	/*
	 * utf16_input would have one NULL terminator at the end. Copy that too. Limiting memory copy to min of
	 * (len_uinput + 1) * sizeof(UChar) and capacity * sizeof(UChar) in order to avoid buffer overwriting.
	 */
	memcpy(utf16_res, utf16_input, Min((len_uinput + 1) * sizeof(UChar), capacity * sizeof(UChar)));
	pfree(utf16_input);
	pfree(input_str);

	utrans_transUChars(cached_transliterator,
						utf16_res,
						&len_uinput,
						capacity,
						0,
						&limit,
						&status);

	/* Allocated capacity may not be enough to hold un-accented string. This shouldn't occur ideally but still defensive code. */
	if (U_FAILURE(status))
	{
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
					errmsg("Error normalising the input string: %s", u_errorName(status))));
	}

	len_result = icu_from_uchar(&result, utf16_res, len_uinput);
	pfree(utf16_res);

	// Return result as NVARCHAR
	res_str = cstring_to_text_with_len(result, len_result);
	pfree(result);
	PG_RETURN_VARCHAR_P(res_str);
#else
	ereport(ERROR,
			(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				errmsg("ICU library is required to be installed in order to use the function remove_accents_internal")));
	PG_RETURN_NULL();
#endif
}

static Node *
convert_node_to_funcexpr_for_like(Node *node)
{
	FuncExpr *newFuncExpr = makeNode(FuncExpr);
	Node *new_node;
	newFuncExpr->funcid = remove_accents_internal_oid;
	newFuncExpr->funcresulttype = get_sys_varcharoid();

	if (node == NULL)
		return node;

	switch (nodeTag(node))
	{
		case T_Const:
			{
				Const *con;
				new_node = coerce_to_target_type(NULL, (Node *) node, exprType(node),
													TEXTOID, -1,
													COERCION_EXPLICIT,
													COERCE_EXPLICIT_CAST,
													exprLocation(node));
				if (unlikely(new_node == NULL))
				{
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
								errmsg("Could not type cast the input argument of LIKE operator to desired data type")));
				}

				if (IsA(new_node, Const))
				{
					con = (Const *) new_node;
					if (con->constisnull)
						return new_node;
					con->constvalue = DirectFunctionCall1(remove_accents_internal, con->constvalue);
					return (Node *) con;
				}
				else
				{
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							 errmsg("Could not convert Const node to desired node type")));
				}
				return new_node;
			}
		case T_FuncExpr:
		case T_Var:
		case T_Param:
		case T_CaseExpr:
		case T_RelabelType:
		case T_CoerceViaIO:
		case T_CollateExpr:
			{
				new_node = coerce_to_target_type(NULL, (Node *) node, exprType(node),
													TEXTOID, -1,
													COERCION_EXPLICIT,
													COERCE_EXPLICIT_CAST,
													exprLocation(node));
				if (unlikely(new_node == NULL))
				{
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
								errmsg("Could not type cast the input argument of LIKE operator to desired data type")));
				}
				newFuncExpr->args = list_make1(new_node);
				break;
			}
		case T_SubLink:
			{
				new_node = coerce_to_target_type(NULL, (Node *) node, exprType(node),
													TEXTOID, -1,
													COERCION_EXPLICIT,
													COERCE_EXPLICIT_CAST,
													exprLocation(node));
				if (unlikely(new_node == NULL))
				{
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
								errmsg("Could not type cast the input argument of LIKE operator to desired data type")));
				}
				new_node = expression_tree_mutator(new_node, pgtsql_expression_tree_mutator, NULL);
				newFuncExpr->args = list_make1(new_node);
				break;
			}

		default:
			{
				ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							 errmsg("unrecognized node type: %d", (int) nodeTag(node))));
			}
	}
	return (Node *) newFuncExpr;
}


static Node *
transform_likenode_for_AI(Node *node, OpExpr *op)
{
	Node		*leftop = (Node *) linitial(op->args);
	Node		*rightop = (Node *) lsecond(op->args);

	linitial(op->args) = coerce_to_target_type(NULL,
												convert_node_to_funcexpr_for_like(leftop),
												get_sys_varcharoid(),
												exprType(leftop), -1,
												COERCION_EXPLICIT,
												COERCE_EXPLICIT_CAST,
												-1);
	lsecond(op->args) = coerce_to_target_type(NULL,
												convert_node_to_funcexpr_for_like(rightop),
												get_sys_varcharoid(),
												exprType(rightop), -1,
												COERCION_EXPLICIT,
												COERCE_EXPLICIT_CAST,
												-1);
	return node;
}

/*
 * To handle CS_AI collation for LIKE, we simply find the corresponding CS_AS collation
 * and modify the nodes by removing accents from them
 */

static Node *
transform_from_cs_ai_for_likenode(Node *node, OpExpr *op, like_ilike_info_t like_entry, coll_info_t coll_info_of_inputcollid)
{
	int			collidx_of_cs_as;

	tsql_get_database_or_server_collation_oid_internal(true);

	if (!OidIsValid(database_or_server_collation_oid))
		return node;

	/*
	 * Find the CS_AS collation corresponding to the CS_AI collation
	 */
	collidx_of_cs_as =
		tsql_find_cs_as_collation_internal(
											tsql_find_collation_internal(coll_info_of_inputcollid.collname));


	/*
	 * A CS_AS collation should always exist unless a Babelfish CS_AS
	 * collation was dropped or the lookup tables were not defined in
	 * lexicographic order.  Program defensively here and just do no
	 * transformation in this case, which will generate a
	 * 'nondeterministic collation not supported' error.
	 */
	if (NOT_FOUND == collidx_of_cs_as)
	{
		elog(DEBUG2, "No corresponding CS_AS collation found for collation \"%s\"", coll_info_of_inputcollid.collname);
		return node;
	}

	op->inputcollid = tsql_get_oid_from_collidx(collidx_of_cs_as);

	return transform_likenode_for_AI(node, op);	
}

/*
 * Currently we support Latin based collations for LIKE for AI
 * and database level collation 
 * The following code pages corresponds to the expected collations
 */
bool
supported_collation_for_db_and_like(int32_t code_page)
{
	if (code_page == 1250 || code_page == 1252 || code_page == 1257)
		return true;
	return false;
}

static Node *
transform_likenode(Node *node)
{
	if (node && IsA(node, OpExpr))
	{
		OpExpr	   *op = (OpExpr *) node;
		like_ilike_info_t like_entry = tsql_lookup_like_ilike_table_internal(op->opno);
		coll_info_t coll_info_of_inputcollid = tsql_lookup_collation_table_internal(op->inputcollid);

		get_remove_accents_internal_oid();

		/*
		 * We do not allow CREATE TABLE statements with CHECK constraint where
		 * the constraint has an ILIKE operator and the collation is ci_as.
		 * But during dump and restore, this kind of a table definition may be
		 * generated. At this point we know that any tables being restored
		 * that match this pattern are generated by pg_dump, and not created
		 * by a user. So, it is safe to go ahead with replacing the ci_as
		 * collation with a corresponding cs_as one if an ILIKE node is found
		 * during dump and restore.
		 */
		init_and_check_collation_callbacks();
		if ((*collation_callbacks_ptr->has_ilike_node) (node) && babelfish_dump_restore)
		{
			int			collidx_of_cs_as;

			if (coll_info_of_inputcollid.oid != InvalidOid)
			{
				collidx_of_cs_as =
					tsql_find_cs_as_collation_internal(
													   tsql_find_collation_internal(coll_info_of_inputcollid.collname));
				if (NOT_FOUND == collidx_of_cs_as)
				{
					op->inputcollid = DEFAULT_COLLATION_OID;
					return node;
				}
				op->inputcollid = tsql_get_oid_from_collidx(collidx_of_cs_as);
			}
			else
			{
				/* If a collation is not specified, use the default one */
				op->inputcollid = DEFAULT_COLLATION_OID;
			}
		}

		if (OidIsValid(like_entry.like_oid) &&
			OidIsValid(coll_info_of_inputcollid.oid) &&
			coll_info_of_inputcollid.collateflags == 0x000e /* CS_AI  */ )
		{
			if (supported_collation_for_db_and_like(coll_info_of_inputcollid.code_page))
				return transform_from_cs_ai_for_likenode(node, op, like_entry, coll_info_of_inputcollid);
			else
				ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("LIKE operator is not supported for \"%s\"", coll_info_of_inputcollid.collname)));
		}

		if (OidIsValid(like_entry.like_oid) &&
			OidIsValid(coll_info_of_inputcollid.oid) &&
			coll_info_of_inputcollid.collateflags == 0x000f /* CI_AI  */ )
		{
			if (supported_collation_for_db_and_like(coll_info_of_inputcollid.code_page))
				return transform_from_ci_as_for_likenode(transform_likenode_for_AI(node, op), op, like_entry, coll_info_of_inputcollid);
			else
				ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("LIKE operator is not supported for \"%s\"", coll_info_of_inputcollid.collname)));
		}

		/* check if this is LIKE expr, and collation is CI_AS */
		if (OidIsValid(like_entry.like_oid) &&
			OidIsValid(coll_info_of_inputcollid.oid) &&
			coll_info_of_inputcollid.collateflags == 0x000d /* CI_AS  */ )
		{
			return transform_from_ci_as_for_likenode(node, op, like_entry, coll_info_of_inputcollid);
		}
	}
	return node;
}

Node *
pltsql_predicate_transformer(Node *expr)
{
	if (expr == NULL)
		return expr;

	if (IsA(expr, OpExpr))
	{
		/* Singleton predicate */
		return transform_likenode(expr);
	}
	else
	{
		/*
		 * Nonsingleton predicate, which could either a BoolExpr with a list
		 * of predicates or a simple List of predicates.
		 */
		ListCell   *lc;
		List	   *new_predicates = NIL;
		List	   *predicates;

		if (IsA(expr, List))
		{
			predicates = (List *) expr;
		}
		else if (IsA(expr, BoolExpr))
		{
			predicates = ((BoolExpr *)expr)->args;
		}
		else if (IsA(expr, FuncExpr))
		{
			/*
			 * This is performed even in the postgres dialect to handle
			 * babelfish CI_AS collations so that regexp operators can work
			 * inside plpgsql functions
			 */
			expr = expression_tree_mutator(expr, pgtsql_expression_tree_mutator, NULL);
			return transform_funcexpr(expr);
		}
		else if (IsA(expr, SubLink))
		{
			return expression_tree_mutator(expr, pgtsql_expression_tree_mutator, NULL);
		}
		else
			return expr;

		/*
		 * Process each predicate, and recursively process any nested
		 * predicate clauses of a toplevel predicate
		 */
		foreach(lc, predicates)
		{
			Node	   *qual = (Node *) lfirst(lc);

			/* For bool expr recall pltsql_predicate_transformer on its args */
			if (IsA(qual, BoolExpr))
			{
				new_predicates = lappend(new_predicates,
										 pltsql_predicate_transformer(qual));
			}
			else if (IsA(qual, OpExpr))
			{
				qual = transform_likenode(qual);
				new_predicates = lappend(new_predicates,
										 expression_tree_mutator(qual, pgtsql_expression_tree_mutator, NULL));
			}
			else
				new_predicates = lappend(new_predicates, qual);
		}

		if (IsA(expr, BoolExpr))
		{
			((BoolExpr *)expr)->args = new_predicates;
			return expr;
		}
		else
		{
			return (Node *) new_predicates;
		}
	}
}

static Node *
pgtsql_expression_tree_mutator(Node *node, void *context)
{
	if (NULL == node)
		return node;
	if (IsA(node, CaseExpr))
	{
		CaseExpr   *caseexpr = (CaseExpr *) node;

		if (caseexpr->arg != NULL)
			/* CASE expression WHEN... */
		{
			pltsql_predicate_transformer((Node *) caseexpr->arg);
		}
	}
	else if (IsA(node, CaseWhen))
		/* CASE WHEN expr */
	{
		CaseWhen   *casewhen = (CaseWhen *) node;

		pltsql_predicate_transformer((Node *) casewhen->expr);
	}

	/* Recurse through the operands of node */
	node = expression_tree_mutator(node, pgtsql_expression_tree_mutator, NULL);

	if (IsA(node, FuncExpr))
	{
		/*
		 * This is performed even in the postgres dialect to handle babelfish
		 * CI_AS collations so that regexp operators can work inside plpgsql
		 * functions
		 */
		node = transform_funcexpr(node);
	}
	else if (IsA(node, OpExpr))
	{
		/*
		 * Possibly a singleton LIKE predicate:  SELECT 'abc' LIKE 'ABC'; This
		 * is done even in the postgres dialect.
		 */
		node = transform_likenode(node);
	}

	return node;
}

Node *
pltsql_planner_node_transformer(PlannerInfo *root,
								Node *expr,
								int kind)
{
	/*
	 * check if this is called to reset saved expression kind. Quickly return if so.
	 */
	if (kind == -1)
	{
		Assert(expr == NULL);
		saved_expr_kind = -1;
		return NULL;
	}

	/*
	 * Fall out quickly if expression is empty.
	 */
	if (expr == NULL)
		return NULL;

	if (EXPRKIND_TARGET == kind)
	{
		saved_expr_kind = EXPRKIND_TARGET;
		/*
		 * If expr is NOT a Boolean expression then recurse through its
		 * expresion tree
		 */
		return expression_tree_mutator(
									   expr,
									   pgtsql_expression_tree_mutator,
									   NULL);
	}
	return pltsql_predicate_transformer(expr);
}

static void
init_and_check_collation_callbacks(void)
{
	if (!collation_callbacks_ptr)
	{
		collation_callbacks **callbacks_ptr;

		callbacks_ptr = (collation_callbacks **) find_rendezvous_variable("collation_callbacks");
		collation_callbacks_ptr = *callbacks_ptr;

		/* collation_callbacks_ptr is still not initialised */
		if (!collation_callbacks_ptr)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("collation callbacks pointer is not initialised properly.")));
	}
}

/*
 * Wrapper of get_database_or_server_collation_oid_internal function in common extension
 * which returns database collation Oid if valid else return server collation Oid
 */
Oid
tsql_get_database_or_server_collation_oid_internal(bool missingOk)
{
	if (OidIsValid(database_or_server_collation_oid))
		return database_or_server_collation_oid;

	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	database_or_server_collation_oid = (*collation_callbacks_ptr->get_database_or_server_collation_oid_internal) (missingOk);
	return database_or_server_collation_oid;
}

Datum
tsql_collation_list_internal(PG_FUNCTION_ARGS)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->collation_list_internal) (fcinfo);
}

Datum
tsql_is_collated_ci_as_internal(PG_FUNCTION_ARGS)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->is_collated_ci_as_internal) (fcinfo);
}

Datum
tsql_is_collated_ai_internal(PG_FUNCTION_ARGS)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->is_collated_ai_internal) (fcinfo);
}

bytea *
tsql_tdscollationproperty_helper(const char *collationaname, const char *property)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->tdscollationproperty_helper) (collationaname, property);
}

int
tsql_collationproperty_helper(const char *collationaname, const char *property)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->collationproperty_helper) (collationaname, property);
}

bool
tsql_is_database_or_server_collation_CI(void)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->is_database_or_server_collation_CI) ();
}

bool
tsql_is_valid_server_collation_name(const char *collationname)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->is_valid_server_collation_name) (collationname);
}

int
tsql_find_locale(const char *locale)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->find_locale) (locale);
}

Oid
tsql_get_oid_from_collidx(int collidx)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->get_oid_from_collidx_internal) (collidx);
}

coll_info_t
tsql_lookup_collation_table_internal(Oid oid)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->lookup_collation_table_callback) (oid);
}

like_ilike_info_t
tsql_lookup_like_ilike_table_internal(Oid opno)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->lookup_like_ilike_table) (opno);
}

int
tsql_find_cs_as_collation_internal(int collidx)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->find_cs_as_collation_internal) (collidx);
}

int
tsql_find_collation_internal(const char *collation_name)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->find_collation_internal) (collation_name);
}


const char *
tsql_translate_bbf_collation_to_tsql_collation(const char *collname)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->translate_bbf_collation_to_tsql_collation) (collname);
}

const char *
tsql_translate_tsql_collation_to_bbf_collation(const char *collname)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->translate_tsql_collation_to_bbf_collation) (collname);
}

bool
has_ilike_node_and_ci_as_coll(Node *expr)
{
	List	   *queue;

	if (expr == NULL)
		return false;

	queue = list_make1(expr);

	while (list_length(queue) > 0)
	{
		Node	   *predicate = (Node *) linitial(queue);

		queue = list_delete_first(queue);

		if (IsA(predicate, OpExpr))
		{
			Oid			inputcoll = ((OpExpr *) predicate)->inputcollid;

			/* Initialize collation callbacks */
			init_and_check_collation_callbacks();
			if ((*collation_callbacks_ptr->has_ilike_node) (predicate) &&
				DatumGetBool(DirectFunctionCall1Coll(tsql_is_collated_ci_as_internal, inputcoll, ObjectIdGetDatum(inputcoll))))
				return true;
		}
		else if (IsA(predicate, BoolExpr))
		{
			BoolExpr   *boolexpr = (BoolExpr *) predicate;

			queue = list_concat(queue, boolexpr->args);
		}
	}
	return false;
}

static void
check_collation_set(Oid collid)
{
	if (!OidIsValid(collid))
	{
		/*
		 * This typically means that the parser could not resolve a conflict
		 * of implicit collations, so report it that way.
		 */
		ereport(ERROR,
				(errcode(ERRCODE_INDETERMINATE_COLLATION),
				 errmsg("could not determine which collation to use for string comparison"),
				 errhint("Use the COLLATE clause to set the collation explicitly.")));
	}
}

PG_FUNCTION_INFO_V1(get_icu_major_version);
Datum
get_icu_major_version(PG_FUNCTION_ARGS)
{
#ifdef USE_ICU
	PG_RETURN_INT32(U_ICU_VERSION_MAJOR_NUM);
#else
	ereport(ERROR,
			(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				errmsg("ICU library is not found")));
	PG_RETURN_NULL();
#endif
}

PG_FUNCTION_INFO_V1(get_icu_minor_version);
Datum
get_icu_minor_version(PG_FUNCTION_ARGS)
{
#ifdef USE_ICU
	PG_RETURN_INT32(U_ICU_VERSION_MINOR_NUM);
#else
	ereport(ERROR,
			(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				errmsg("ICU library is not found")));
	PG_RETURN_NULL();
#endif
}
/*
 * For a given string and position in UTF-16 and return
 * the corresponding position in UTF-8 string. UTF-16
 * string considers surrogate pairs as two chars while
 * in UTF-8 they are 1, which is why we need to translate
 */

static int32_t
translate_char_pos(const char* str,		/* UTF-8 string */
				   int32_t str_len,		/* length of UTF-8 string */
				   const UChar* str_utf16, 		/* UTF-16 string */
				   int32_t u16_len,		/* length of UTF-16 string */
				   int32_t u16_pos,		/* position to translare in UTF-16 string */
				   const char **p_str)		/* character at same position in UTF-8 string */
{
	UChar32 c;
	int32_t u16_idx = 0;
	int32_t out_pos = 0;
	int32_t u8_offset = 0;

	Assert (GetDatabaseEncoding() == PG_UTF8);

	/* for UTF-8, use ICU macros instead of calling pg_mblen() */
	while (u16_idx < u16_pos)
	{
#ifdef USE_ICU
		U16_NEXT(str_utf16, u16_idx, u16_len, c);
		U8_NEXT(str, u8_offset, str_len, c);
		out_pos++;
#else
	ereport(ERROR,
			(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				errmsg("translate_char_pos requires ICU library, which is not available")));
#endif
	}
	if (p_str != NULL)
		*p_str = str + u8_offset;

	return out_pos;
}

static int
icu_compare_utf8_coll(UCollator  *coll, UChar *uchar1, int32_t ulen1,
					  UChar *uchar2, int32_t ulen2, bool is_cs_ai_range_cmp)
{
	UErrorCode	status = U_ZERO_ERROR;
	UCollator   *collator;
	int i;

	if (is_cs_ai_range_cmp)
	{
		collator = ucol_safeClone(coll, NULL, NULL, &status);

		if (U_FAILURE(status))
			ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("failed to clone collator in icu compare: %s", u_errorName(status))));

		ucol_setAttribute(collator, UCOL_CASE_FIRST, UCOL_OFF, &status);

		if (U_FAILURE(status))
			ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("failed to set attribute for ucollator: %s", u_errorName(status))));
	}
	else
	{
		collator = coll;
	}

	i = ucol_strcoll(collator,
					 uchar1, ulen1,
					 uchar2, ulen2);

	if (is_cs_ai_range_cmp)
		ucol_close(collator);

	return i;
}

bool
pltsql_strpos_non_determinstic(text *src_text, text *substr_text, Oid collid, int *r)
{
	pg_locale_t mylocale = 0;

	check_collation_set(collid);

	if (!lc_collate_is_c(collid))
		mylocale = pg_newlocale_from_collation(collid);
	else
		return false;

	if (!pg_locale_deterministic(mylocale) && mylocale->provider == 'i')
	{
#ifdef USE_ICU
		int32_t src_len_utf8 = VARSIZE_ANY_EXHDR(src_text);
		int32_t substr_len_utf8 = VARSIZE_ANY_EXHDR(substr_text);
		int32_t src_ulen, substr_ulen;
		int32_t u8_pos = -1, pos_prev_loop = -1;
		UErrorCode	status = U_ZERO_ERROR;
		UStringSearch *usearch;
		UChar *src_uchar, *substr_uchar;
		coll_info_t coll_info_of_inputcollid = tsql_lookup_collation_table_internal(collid);
		bool is_CS_AI = false;
		bool is_substr_starts_with_surrogate;

		if (OidIsValid(coll_info_of_inputcollid.oid) &&
		    coll_info_of_inputcollid.collateflags == 0x000e /* CS_AI  */ )
		{
			is_CS_AI = true;
		}

		src_ulen = icu_to_uchar(&src_uchar, VARDATA_ANY(src_text), src_len_utf8);
		substr_ulen = icu_to_uchar(&substr_uchar, VARDATA_ANY(substr_text), substr_len_utf8);

		is_substr_starts_with_surrogate = UCHAR_IS_SURROGATE(substr_uchar[0]);

		usearch = usearch_openFromCollator(substr_uchar,
										substr_ulen,
										src_uchar,
										src_ulen,
										mylocale->info.icu.ucol,
										NULL,
										&status);

		usearch_setAttribute(usearch, USEARCH_OVERLAP, USEARCH_ON, &status);

		if (U_FAILURE(status))
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("failed to perform ICU search: %s",
							u_errorName(status))));

		for (int32_t u16_pos = usearch_first(usearch, &status);
		     u16_pos != USEARCH_DONE;
		     u16_pos = usearch_next(usearch, &status))
		{
			if (U_FAILURE(status))
				ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("failed to perform ICU search: %s",
							u_errorName(status))));

			/* ICU bug, When pattern start with a surrogate pair ICU usearch_next stops moving forward entering an infinite loop */
			if (u16_pos == pos_prev_loop)
			{
				int32_t next_char_idx = u16_pos + UCHAR_LENGTH(src_uchar[u16_pos]);

				if (is_substr_starts_with_surrogate && next_char_idx < src_ulen)
				{
					usearch_setOffset(usearch, next_char_idx, &status);

					if (U_FAILURE(status))
						ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
						        errmsg("failed to set offset in ICU search: %s", u_errorName(status))));

					continue;
				}
				else
					break;
			}

			pos_prev_loop = u16_pos;

			/* for CS_AI collations usearch can give false positives so we double check the results here */
			if (!(is_CS_AI && icu_compare_utf8_coll(mylocale->info.icu.ucol, &src_uchar[usearch_getMatchedStart(usearch)], usearch_getMatchedLength(usearch), substr_uchar, substr_ulen, false) != 0))
			{
				u8_pos = translate_char_pos(VARDATA_ANY(src_text), src_len_utf8,
										src_uchar, src_ulen, u16_pos,
										NULL);
				break;
			}
		}

		pfree(src_uchar);
		pfree(substr_uchar);
		usearch_close(usearch);

		/* return 0 if not found or the 1-based position of substr_text inside src_text */
		*r = u8_pos + 1;
		return true;
#else
	ereport(ERROR,
			(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				errmsg("pltsql strpos requires ICU library, which is not available")));
#endif
	}

	return false;
}

bool
pltsql_replace_non_determinstic(text *src_text, text *from_text, text *to_text, Oid collid, text **r)
{
	pg_locale_t mylocale = 0;

	check_collation_set(collid);

	if (!lc_collate_is_c(collid))
		mylocale = pg_newlocale_from_collation(collid);
	else
		return false;

	if (!pg_locale_deterministic(mylocale) && mylocale->provider == 'i')
	{
#ifdef USE_ICU
		const char *src_text_currptr = VARDATA_ANY(src_text);
		const char* src_text_startptr = VARDATA_ANY(src_text);
		int32_t src_len = VARSIZE_ANY_EXHDR(src_text);
		int32_t from_str_len = VARSIZE_ANY_EXHDR(from_text);
		int32_t to_str_len = VARSIZE_ANY_EXHDR(to_text);
		int32_t previous_pos, pos_prev_loop = -1;
		int32_t src_ulen, from_ulen;		/* in utf-16 units */
		UErrorCode	status = U_ZERO_ERROR;
		UStringSearch *usearch;
		UChar *src_uchar, *from_uchar;
		text *result;
		StringInfoData resbuf;
		coll_info_t coll_info_of_inputcollid = tsql_lookup_collation_table_internal(collid);
		bool is_CS_AI = false;
		bool is_substr_starts_with_surrogate;

		if (OidIsValid(coll_info_of_inputcollid.oid) &&
		    coll_info_of_inputcollid.collateflags == 0x000e /* CS_AI  */ )
		{
			is_CS_AI = true;
		}

		src_ulen = icu_to_uchar(&src_uchar, VARDATA_ANY(src_text), src_len);
		from_ulen = icu_to_uchar(&from_uchar, VARDATA_ANY(from_text), from_str_len);

		is_substr_starts_with_surrogate = UCHAR_IS_SURROGATE(from_uchar[0]);

		usearch = usearch_openFromCollator(from_uchar, /* needle */
										from_ulen,
										src_uchar, /* haystack */
										src_ulen,
										mylocale->info.icu.ucol,
										NULL,
										&status);

		usearch_setAttribute(usearch, USEARCH_OVERLAP, USEARCH_ON, &status);

		initStringInfo(&resbuf);
		previous_pos = 0;

		for (int32_t pos = usearch_first(usearch, &status);
		     pos != USEARCH_DONE;
		     pos = usearch_next(usearch, &status))
		{
			const char *src_text_nextptr;
			int32_t matched_length;

			if (U_FAILURE(status))
				ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("failed to perform ICU search: %s",
							u_errorName(status))));

			/* ICU bug, When pattern start with a surrogate pair ICU usearch_next stops moving forward entering an infinite loop */
			if (pos == pos_prev_loop)
			{
				int32_t next_char_idx = pos + UCHAR_LENGTH(src_uchar[pos]);

				if (is_substr_starts_with_surrogate && next_char_idx < src_ulen)
				{
					usearch_setOffset(usearch, next_char_idx, &status);

					if (U_FAILURE(status))
						ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
						        errmsg("failed to set offset in ICU search: %s", u_errorName(status))));

					continue;
				}
				else
					break;
			}

			pos_prev_loop = pos;

			/* for CS_AI collations usearch can give false positives so we double check the results here */
			if (is_CS_AI && icu_compare_utf8_coll(mylocale->info.icu.ucol, &src_uchar[usearch_getMatchedStart(usearch)], usearch_getMatchedLength(usearch), from_uchar, from_ulen, false) != 0)
				continue;

			/* reject if overlaps with the last successful match */
			if (pos < previous_pos)
				continue;

			/* copy the segment before the match */
			translate_char_pos(
				src_text_currptr,
				src_len - (src_text_currptr - src_text_startptr),
				src_uchar + previous_pos,
				src_ulen - previous_pos,
				pos - previous_pos,
				&src_text_nextptr);

			appendBinaryStringInfo(&resbuf,
								src_text_currptr,
								src_text_nextptr - src_text_currptr);


			matched_length = usearch_getMatchedLength(usearch);

			/* compute the length of the replaced text in txt1 */
			translate_char_pos(
				src_text_nextptr,
				src_len - (src_text_nextptr - src_text_startptr),
				src_uchar + pos,
				matched_length,
				matched_length,
				&src_text_currptr);

			/* append the replacement text */
			appendBinaryStringInfo(&resbuf, VARDATA_ANY(to_text), to_str_len);

			previous_pos = pos + matched_length;
		}

		/* copy the segment after the last match */
		if (previous_pos)
		{
			if (src_len - (src_text_currptr - src_text_startptr) > 0)
			{
				appendBinaryStringInfo(&resbuf,
									src_text_currptr,
									src_len - (src_text_currptr - src_text_startptr));
			}
			result = cstring_to_text_with_len(resbuf.data, resbuf.len);
			pfree(resbuf.data);
		}
		else
		{
			/*
			* The substring is not found: return the original string
			*/
			result = src_text;
		}

		pfree(src_uchar);
		pfree(from_uchar);

		if (usearch != NULL)
			usearch_close(usearch);

		if (U_FAILURE(status))
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("failed to perform ICU search: %s",
							u_errorName(status))));

		*r = result;
		return true;
#else
	ereport(ERROR,
			(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				errmsg("pltsql replace requires ICU library, which is not available")));
#endif
	}
	return false;
}

/* Find the collation corresponding to a specific database */
char*
get_collation_name_for_db(const char* dbname)
{
	HeapTuple	tuple;
	Form_sysdatabases sysdb;
	char *collation_name;

	tuple = SearchSysCache1(SYSDATABASENAME, PointerGetDatum(cstring_to_text(dbname)));

	if (!HeapTupleIsValid(tuple))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
					 errmsg("Could not find database: \"%s\"", dbname)));

	sysdb = ((Form_sysdatabases) GETSTRUCT(tuple));
	collation_name = pstrdup(NameStr(sysdb->default_collation));

	ReleaseSysCache(tuple);
	return collation_name;
}

/* 
 * We need to communicate to common extension
 * that user has invoked USE DB command
 * Hence, we need to update the cache related to -
 * 1. database collation oid
 * 2. database collation index
 * 
 * Also, We are processesing USE DB command
 * Communicate the same to common extension
 * so that collation related information gets updated
 */
void
set_db_collation_internal(const char *db_name)
{
	Oid database_collation_oid;

	/* Get collation oid corresponding to collation name */
	database_collation_oid = get_collation_oid(list_make1(makeString((char*)get_collation_name_for_db(db_name))), false);

	if (!OidIsValid(database_collation_oid))
		ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_DATABASE),
			 errmsg("Could not find database with collation oid \"%u\"", database_collation_oid)));

	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	(*collation_callbacks_ptr->set_db_collation) (database_collation_oid);

	database_or_server_collation_oid = InvalidOid;
}

/*
 * Find the matched length for substr in src_text
 * Only matches if substr is prefix of src_text
 */
static bool
icu_find_matched_length(char *src_text, int src_len, char *substr_text, int substr_len, Oid collid, int *matched_len, bool is_cs_ai)
{
    pg_locale_t mylocale = 0;

    if (!lc_collate_is_c(collid))
        mylocale = pg_newlocale_from_collation(collid);

    if (!pg_locale_deterministic(mylocale) && mylocale->provider == 'i')
    {
#ifdef USE_ICU
		int32_t src_len_utf8 = src_len;
		int32_t substr_len_utf8 = substr_len;
		int32_t src_ulen, substr_ulen;
		int32_t u16_pos, u8_pos = 0;
		UErrorCode  status = U_ZERO_ERROR;
		UStringSearch *usearch;
		UChar *src_uchar, *substr_uchar;
		int32 matched_length_u16, u8_endpos;

		src_ulen = icu_to_uchar(&src_uchar, src_text, src_len_utf8);
		substr_ulen = icu_to_uchar(&substr_uchar, substr_text, substr_len_utf8);

		usearch = usearch_openFromCollator(substr_uchar,
										substr_ulen,
										src_uchar,
										src_ulen,
										mylocale->info.icu.ucol,
										NULL,
										&status);
		if (U_FAILURE(status))
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
						errmsg("failed to perform ICU search: %s",
							   u_errorName(status))));

		/* substr should start matching from the first position in src string */
		u16_pos = usearch_first(usearch, &status);
		if (!U_FAILURE(status) && u16_pos != USEARCH_DONE && u16_pos == 0 && (!is_cs_ai ||
		    icu_compare_utf8_coll(mylocale->info.icu.ucol, src_uchar, usearch_getMatchedLength(usearch), substr_uchar, substr_ulen, false) == 0))
		{
			/* u16 position will only be zero */
			matched_length_u16 = usearch_getMatchedLength(usearch);
			u8_endpos = translate_char_pos(src_text, src_len_utf8,
										   src_uchar, src_ulen,
										   matched_length_u16, NULL);
			*matched_len = u8_endpos;
		}
		else
			u8_pos = -1;

		pfree(src_uchar);
		pfree(substr_uchar);
		usearch_close(usearch);

		return u8_pos < 0 ? false : true;
#else
	ereport(ERROR,
			(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				errmsg("ICU find matched length requires ICU library")));
#endif
    }

	return false;
}

static void
next_char(char **p, int *plen)
{
	int l = pg_mblen(*p);

	if (l > *plen)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
						errmsg("malformed string")));

	(*p) += l;
	*plen -= l;
}

static int
patindex_ai_match_text(pg_locale_t mylocale, char *input_str, char *pattern, Oid cid, bool is_cs_ai)
{
	bool start_offset = false;
	int  itr = 0;

	if (pattern == NULL || strlen(pattern) == 0)
		return 0;

	while (pattern != NULL && *pattern != '\0' && *pattern == '%')
	{
		pattern++;
		start_offset = true;
	}

	/* pattern only contained % wildcard */
	if (pattern == NULL || *pattern == '\0')
		return 1;

	while (*input_str != '\0')
	{
		char  *t = input_str;
		char  *p = pattern;
		int   tlen = strlen(t),
		      plen = strlen(pattern);
		bool  match_failed = false;

		itr++;

		while (tlen > 0 && plen > 0)
		{
			if (*p == '%')
			{
				if (patindex_ai_match_text(mylocale, t, p, cid, is_cs_ai))
					return itr;
				else
					return 0;
			}
			else if (*p == '_')
			{
				/* _ matches any single character, and we know there is one */
				next_char(&t, &tlen);
				next_char(&p, &plen);
				continue;
			}
			else if (*p == '[')
			{
				/* Tsql deal with [ and ] wild character */
				bool find_match = false, reverse_mode = false, close_bracket = false;
				const char *prev = NULL;

				next_char(&p, &plen);
				if (plen > 0 && *p == '^')
				{
					reverse_mode = true;
					next_char(&p, &plen);
				}
				while (plen > 0)
				{
					if (*p == ']')
					{
						close_bracket = true;
						next_char(&p, &plen);
						break;
					}
					if (find_match)
					{
						next_char(&p, &plen);
						continue;
					}
					if (*p == '-' && prev && plen > 1 && *(p+1) != ']')
					{
						UChar *t_uchar, *p_uchar, *prev_uchar;
						int32_t t_ulen, prev_ulen, p_ulen;
						next_char(&p, &plen);
						Assert(cid != InvalidOid);
						t_ulen = icu_to_uchar(&t_uchar, t, pg_mblen(t));
						prev_ulen = icu_to_uchar(&prev_uchar, prev, pg_mblen(prev));
						p_ulen = icu_to_uchar(&p_uchar, p, pg_mblen(p));

						if (icu_compare_utf8_coll(mylocale->info.icu.ucol, t_uchar, t_ulen, prev_uchar, prev_ulen, is_cs_ai) >= 0 &&
						    icu_compare_utf8_coll(mylocale->info.icu.ucol, t_uchar, t_ulen, p_uchar, p_ulen, is_cs_ai) <= 0)
						{
							find_match = true; 
						}
						prev = NULL;
						next_char(&p, &plen);
					}
					else
					{
						int p_start_len = plen, matched_idx = 0;
						char *p_start = p;
						text *src_text, *substr_text;
						prev = NULL;

						/* find the string till the next special character, '-' is a special char only if prev and next exists */
						while (plen > 0 && *p != ']' && !(prev && *p == '-'))
						{
							prev = p;
							next_char(&p, &plen);
						}
						
						src_text = cstring_to_text_with_len(p_start, p_start_len - plen);
						substr_text = cstring_to_text_with_len(t, pg_mblen(t));
						
						if (pltsql_strpos_non_determinstic(src_text, substr_text, cid, &matched_idx) && matched_idx != 0)
						{
							find_match = true;
						}
						pfree(src_text);
						pfree(substr_text);
					}
				}

				if (close_bracket && (find_match ^ reverse_mode)) /* found a match */
					next_char(&t, &tlen);
				else
				{
					match_failed = true;
					break;
				}
			}
			else
			{
				char *p_start = p;
				int  len = plen, matched_len = 0;

				while (plen > 0 && *p != '[' && *p != '_' && *p != '%')
				{
					next_char(&p, &plen);
				}
				if (icu_find_matched_length(t, strlen(t), p_start, len-plen, cid, &matched_len, is_cs_ai))
				{
					while (matched_len--)
						next_char(&t, &tlen);
				}
				else
				{
					match_failed = true;
					break;
				}
			}
		}

		if (tlen > 0 && !match_failed)
		{
			while (tlen > 0 && *t == ' ')
				next_char(&t, &tlen);
			if (tlen <= 0 && plen <=0)
				return itr;
		}

		/*
		* End of text, but perhaps not of pattern.  Match if the remaining
		* pattern can match a zero-length string, ie, it's zero or more %'s.
		*/
		while (plen > 0 && *p == '%')
			next_char(&p, &plen);
		if (plen <= 0 && !match_failed)
			return itr;

		if (start_offset)
			input_str += pg_mblen(input_str);
		else
			break;
	}

	return 0;
}

PG_FUNCTION_INFO_V1(patindex_ai_collations);
Datum
patindex_ai_collations(PG_FUNCTION_ARGS)
{
	pg_locale_t  mylocale = 0;
	char         *pattern = text_to_cstring(PG_GETARG_TEXT_PP(0));
	char         *input_str = text_to_cstring(PG_GETARG_TEXT_PP(1));
	Oid          cid = PG_GET_COLLATION();
	int 		 result = 0;
	bool		 is_CS_AI = false;
	coll_info_t  coll_info_of_inputcollid;

	check_collation_set(cid);

	coll_info_of_inputcollid = tsql_lookup_collation_table_internal(cid);

	if (OidIsValid(coll_info_of_inputcollid.oid))
	{
		is_CS_AI = coll_info_of_inputcollid.collateflags == 0x000e;  /* CS_AI ? */
	}
	else
	{
		ereport(ERROR,
				(errcode(ERRCODE_INDETERMINATE_COLLATION),
				 errmsg("patindex is not supported with non babelfish non deterministic collations")));
	}

	if (!lc_collate_is_c(cid))
	{
		mylocale = pg_newlocale_from_collation(cid);
		
		if (!pg_locale_deterministic(mylocale) && mylocale->provider == 'i')
			result = patindex_ai_match_text(mylocale, input_str, pattern, cid, is_CS_AI);
	}

	pfree(input_str);
	pfree(pattern);

	PG_RETURN_INT32(result);
}
