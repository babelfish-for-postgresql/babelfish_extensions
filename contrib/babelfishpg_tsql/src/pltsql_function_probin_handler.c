/*-------------------------------------------------------------------------
 *
 * pltsql_function_probin_handler.c		- Handling probin for pltsql functions/procedures
 *
 * IDENTIFICATION
 *	  src/pl/pltsql/src/pltsql_function_probin_handler.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "pltsql.h"
#include "funcapi.h"

#include "catalog/pg_proc.h"
#include "catalog/pg_language.h"
#include "parser/parse_coerce.h"
#include "parser/parse_type.h"
#include "parser/parser.h"
#include "utils/builtins.h"
#include "utils/jsonb.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/varlena.h"

#define probin_version 1
#define typmod_arr_key "typmod_array"

static char* catalog_read_probin(Oid funcid);
static Jsonb* ProbinJsonbBuilder(CreateFunctionStmt *stmt, char** probin_str);
static void pushJsonbPairIntAsText(JsonbParseState **jpstate,
						JsonbValue **result, const char* key, const long long int val);
static void pushJsonbPairText(JsonbParseState **jpstate,
						JsonbValue **result, const char* key, char** val);
static void pushJsonbArray(JsonbParseState **jpstate,
						JsonbValue **result, int *items, int array_len);
static void buildTypmodArray(CreateFunctionStmt *stmt, int** typmod_array_p, int* array_len);
void probin_json_reader(text* probin, int** typmod_arr_p, int typmod_arr_len);
int adjustTypmod(Oid oid, int typmod);

bool pltsql_function_as_checker(const char *lang, List *as, char **prosrc_str_p, char **probin_str_p)
{
	/*
	 * This hook checks if it's pltsql language and if we have two AS
	 * clauses (probin+prosrc). We'll populate the probin and prosrc strings
	 * with the AS clauses here and later we'll skip the generation of new
	 * probin string in write_stored_proc_probin_hook function.
	 */
	if (strcmp(lang, "pltsql") == 0 && as->length == 2)
	{
		*probin_str_p = strVal(linitial(as));
		*prosrc_str_p = strVal(lsecond(as));
		return true;
	}
	return false;
}

void pltsql_function_probin_writer(CreateFunctionStmt *stmt, Oid languageOid, char** probin_str_p)
{
	char				*langname;
	int 	    		probin_len;
	Jsonb*				jb;

	langname = get_language_name(languageOid, true);
	/* only write probin when language is pltsql */
	if(!langname || strcmp(langname, "pltsql") != 0)
		return;

	/* skip if probin is already set */
	if ((*probin_str_p) && (*probin_str_p)[0] == '{')
		return;

	jb = ProbinJsonbBuilder(stmt, probin_str_p);

	probin_len = strlen(JsonbToCString(NULL, &jb->root, VARSIZE(jb)));
	/* extra padding space to prevent chunk overwrite */
	*probin_str_p = palloc(probin_len+2);
	*probin_str_p[0] = '\0';
	strncat(*probin_str_p,
			JsonbToCString(NULL, &jb->root, probin_len), probin_len+2);
}

void
pltsql_function_probin_reader(ParseState *pstate,
								List *fargs,
								Oid *actual_arg_types,
								Oid *declared_arg_types,
								Oid funcid)
{
	HeapTuple	tuple;
	int*		typmod_array = NULL;
	char* 		probin_c = catalog_read_probin(funcid);
	Oid			languageOid;
	char		*langname;

	tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcid));
	if (!HeapTupleIsValid(tuple))
		elog(ERROR, "cache lookup failed for function %u", funcid);

	languageOid = ((Form_pg_proc) GETSTRUCT(tuple))->prolang;
	ReleaseSysCache(tuple);
	langname = get_language_name(languageOid, true);

	/* only read probin when it is defined and language is pltsql */
	if(!langname || strcmp(langname, "pltsql") != 0 ||
		!probin_c || probin_c[0] != '{')
	{
		make_fn_arguments(pstate,
						fargs,
						actual_arg_types,
						declared_arg_types);
	}
	else
	{
		ListCell   *current_fargs;
		int			i = 0;
		int			numargs = 0;
		int			num_IN_or_OUT_args = 0;
		Oid			*argtypes;
		char		**argnames;
		char		*argmodes;
		HeapTuple	procTup = NULL;

		/*
		 * Lookup the pg_proc tuple by Oid
		 */
		procTup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcid));
		if (!HeapTupleIsValid(procTup))
			elog(ERROR, "cache lookup failed for function %u", funcid);
		
		numargs = get_func_arg_info(procTup, &argtypes, &argnames, &argmodes);

		if (argmodes)
		{
			for (i = 0; i < numargs; i++)
			{
				/*
				 * We only stored typmod of parameter with mode INPUT/'i', OUTPUT/'o' and INOUT/'b'
				 * Refer to PROARGMODE_IN in pg_proc.h
				 */
				if (argmodes[i] == PROARGMODE_IN ||
					argmodes[i] == PROARGMODE_OUT ||
					argmodes[i] == PROARGMODE_INOUT)
					num_IN_or_OUT_args++;
			}
			i = 0;
		}
		/* No argmodes. Meaning every argument is IN arg. We can simply use numargs */
		else
		{
			num_IN_or_OUT_args = numargs;
		}

		/*
		 * BABEL-2392 There can be less arguments in the EXEC PROC statement compared to
		 * the full list of arguments desired by the procedure.
		 * Also the named arguments in the EXEC PROC statement can appear in any order.
		 * So we have to get the full typmod_array using the number of IN or OUT parameters
		 * instead of fargs.length.
		 * Also we need to match the argument name and then invoke adjustTypmod on the
		 * corresponding typmod_array element.
		 */
		probin_json_reader(cstring_to_text(probin_c), &typmod_array, num_IN_or_OUT_args);

		foreach(current_fargs, fargs)
		{
			Node	   *node = (Node *) lfirst(current_fargs);

			if (IsA(node, NamedArgExpr))
			{
				NamedArgExpr 	*na = (NamedArgExpr *) node;
				int				j = 0;
				bool			name_matched = false;

				/*
				 * BABEL-2392
				 * Arguments in EXEC PROC statement can be in any order such as exec mysp @arg2 = 1, @arg1 = 'abc'
				 * Look for the matching argument name then invoke adjustTypmod on the corresponding typmod_array element
				 */
				for (j = 0; j < num_IN_or_OUT_args; j++)
				{
					if (strcmp(na->name, argnames[j]) == 0)
					{
						name_matched = true;
						typmod_array[j] += adjustTypmod(declared_arg_types[i], typmod_array[j]);
						break;
					}
				}

				if (name_matched)
				{
					node = coerce_to_target_type(pstate,
									(Node *) na->arg,
									actual_arg_types[i],
									declared_arg_types[i], typmod_array[j],
									COERCION_EXPLICIT,
									COERCE_IMPLICIT_CAST,
									-1);
					na->arg = (Expr *) node;
				}
				/* Name unmatched, this should not happen since we've done checks during parse analysis. But just in case */
				else
				{
					elog(ERROR, "No match for argument %s of function %u", na->name, funcid);
				}
			}
			else
			{
				typmod_array[i] += adjustTypmod(declared_arg_types[i], typmod_array[i]);
				node = coerce_to_target_type(pstate,
								node,
								actual_arg_types[i],
								declared_arg_types[i], typmod_array[i],
								COERCION_EXPLICIT,
								COERCE_IMPLICIT_CAST,
								-1);
				lfirst(current_fargs) = node;
			}
			i++;
		}
		ReleaseSysCache(procTup);
	}
}

void probin_read_args_typmods(HeapTuple procTup, int nargs, Oid *argtypes, int **typmods)
{
	bool isnull;
	char *probin_c = NULL;
	Datum tmp = SysCacheGetAttr(PROCOID, procTup, Anum_pg_proc_probin, &isnull);

	if (!isnull)
		probin_c = TextDatumGetCString(tmp);
	if(!probin_c || probin_c[0] != '{')
	{
		*typmods = NULL;
		return;
	}

	probin_json_reader(cstring_to_text(probin_c), typmods, nargs); /* no need to read ret */
	Assert(typmods != NULL);

	for (int i=0; i<nargs; ++i)
		(*typmods)[i] += adjustTypmod(argtypes[i], (*typmods)[i]);
}

int probin_read_ret_typmod(Oid funcid, int nargs, Oid declared_oid)
{
	int*		typmod_array = NULL;
	int 		arr_len = nargs + 1;
	int 		ret_typmod = -1;
	char* 		probin_c = catalog_read_probin(funcid);
	if(!probin_c || probin_c[0] != '{')
	{
		return ret_typmod;
	}
	probin_json_reader(cstring_to_text(probin_c), &typmod_array, arr_len);
	ret_typmod = typmod_array[arr_len-1];
	ret_typmod += adjustTypmod(declared_oid, ret_typmod);
	return ret_typmod;
}

static char* catalog_read_probin(Oid funcid)
{
	bool		isnull;
	HeapTuple	ftup;
	Datum		tmp;
	char* 		probin_c = NULL;

	ftup = SearchSysCache1(PROCOID,
				ObjectIdGetDatum(funcid));
	if (!HeapTupleIsValid(ftup))
		return probin_c;
	tmp = SysCacheGetAttr(PROCOID, ftup, Anum_pg_proc_probin, &isnull);
	if (!isnull)
		probin_c = TextDatumGetCString(tmp);

	ReleaseSysCache(ftup);
	return probin_c;
}

/* ProbinJsonbBuilder()
 * build JsonB from create function statement and original probin
 */
static Jsonb*
ProbinJsonbBuilder(CreateFunctionStmt *stmt, char** probin_str)
{
	JsonbValue *	result;
	JsonbParseState*jpstate = NULL;
	int*			typmod_array = NULL;
	int				array_len;
	result = pushJsonbValue(&jpstate, WJB_BEGIN_OBJECT, NULL);

	pushJsonbPairIntAsText(&jpstate, &result, "version_num", probin_version);

	pushJsonbPairText(&jpstate, &result, "original_probin", probin_str);

	buildTypmodArray(stmt, &typmod_array, &array_len);
	pushJsonbArray(&jpstate, &result, typmod_array, array_len);
	free(typmod_array);

	result = pushJsonbValue(&jpstate, WJB_END_OBJECT, NULL);
	return JsonbValueToJsonb(result);
}

static void
pushJsonbPairIntAsText(JsonbParseState **jpstate, JsonbValue **result, const char* key, const long long int val)
{
	JsonbValue v;
	char buf [22];

	v.type = jbvString;
	v.val.string.len = strlen(key);
	v.val.string.val = (char*)key;
	*result = pushJsonbValue(jpstate, WJB_KEY, &v);

	snprintf(buf, 22, "%lld", val);
	v.val.string.len = strlen(buf);
	v.val.string.val = pstrdup(buf);
	*result = pushJsonbValue(jpstate, WJB_VALUE, &v);
}

static void
pushJsonbPairText(JsonbParseState **jpstate, JsonbValue **result, const char* key, char** val)
{
	JsonbValue v;
	v.type = jbvString;
	v.val.string.len = strlen(key);
	v.val.string.val = (char*)key;
	*result = pushJsonbValue(jpstate, WJB_KEY, &v);
	if (val && *val && strlen(*val) != 0) 
	{
		v.val.string.len = strlen(*val);
		v.val.string.val[0] = '\0';
		strncat(v.val.string.val, (char*)(*val), v.val.string.len);
		free(*val);
	}
	else
	{
		v.val.string.len = 0;
		v.val.string.val = "";
	}
	*result = pushJsonbValue(jpstate, WJB_VALUE, &v);
}

/* Construct a JSON array from the item list */
static void
pushJsonbArray(JsonbParseState **jpstate, JsonbValue **result, int *items, int array_len)
{
	JsonbValue      v;
	char 	  buf[22];

	v.type = jbvString;
	v.val.string.len = strlen(typmod_arr_key);
	v.val.string.val = typmod_arr_key;
	*result = pushJsonbValue(jpstate, WJB_KEY, &v);

	*result = pushJsonbValue(jpstate, WJB_BEGIN_ARRAY, NULL);
	if(array_len)
	{
		for(int i = 0; i< array_len; i++)
		{
			snprintf(buf, 22, "%d", items[i]);
			v.type = jbvString;
			v.val.string.len = strlen(buf);
			v.val.string.val = pstrdup(buf);
			*result = pushJsonbValue(jpstate, WJB_ELEM, &v);
		}
	}

	*result = pushJsonbValue(jpstate, WJB_END_ARRAY, NULL);
}

static void buildTypmodArray(CreateFunctionStmt *stmt, int** typmod_array_p, int* array_len_p)
{
	A_Const* 	  ptr;
	List*  arg_typmod;
	ListCell*       x;
	TypeName*     ret = stmt->returnType;
	int 		i = 0;

	*array_len_p = list_length(stmt->parameters);

	/* for functions, we need to store return type typmod */
	if(!stmt->is_procedure)
	{
		*array_len_p += 1;
	}
	/* if no typemod needs to be stored, skip */
	if (*array_len_p == 0)
		return;
	*typmod_array_p = (int*)malloc(sizeof(int32_t) * (*array_len_p));
	memset(*typmod_array_p, 0, sizeof(int32_t) * (*array_len_p));

	foreach(x, stmt->parameters)
	{
		FunctionParameter *fp = (FunctionParameter *) lfirst(x);
		arg_typmod = fp->argType->typmods;
		if(!arg_typmod)
		{
			(*typmod_array_p)[i] = -1;
		}
		else
		{
			ListCell* typmod_head = list_head(arg_typmod);
			for(int idx = 0; idx < arg_typmod->length; idx++)
			{
				ptr = (A_Const *)(lfirst(typmod_head));
				/* numeric type */
				if(idx > 0)
				{
					(*typmod_array_p)[i] =  (((*typmod_array_p)[i]) << 16) + ptr->val.ival.ival + VARHDRSZ;
				}
				else
				{
					(*typmod_array_p)[i] = ptr->val.ival.ival;
				}
				typmod_head = lnext(arg_typmod, typmod_head);
			}
			
		}
		i++;
	}
	/* skip allocating return type typemod for procedures */
	if(stmt->is_procedure)
	{
		return;
	}

	/* handle return type */
	if(ret && ret->typmods)
	{
		ListCell* typmod_head = list_head(ret->typmods);
		for(int idx = 0; idx < ret->typmods->length; idx++)
		{
			ptr = (A_Const *)(lfirst(typmod_head));
			/* numeric type */
			if(idx > 0)
			{
				(*typmod_array_p)[i] =  (((*typmod_array_p)[i]) << 16) + ptr->val.ival.ival + VARHDRSZ;
			}
			else
			{
				(*typmod_array_p)[i] = ptr->val.ival.ival;
			}
			typmod_head = lnext(ret->typmods, typmod_head);
		}
	}
	else
	{
		(*typmod_array_p)[i++] = -1;
	}
}

void
probin_json_reader(text* probin, int** typmod_arr_p, int typmod_arr_len)
{
	Datum	   arr_json_d;
	Datum	   elem_d;

	arr_json_d = DirectFunctionCall2(json_object_field,
								PointerGetDatum(probin),
								PointerGetDatum(cstring_to_text(typmod_arr_key)));

	*typmod_arr_p = (int*)palloc(sizeof(int32_t) * (typmod_arr_len));

	for(int i = 0; i < typmod_arr_len; i++)
	{
		char* tmp;
		elem_d = DirectFunctionCall2(json_array_element, arr_json_d, Int32GetDatum(i));
		tmp = text_to_cstring(DatumGetTextP(elem_d));
		/* remove prefix and trailing \" */
		tmp++;
		tmp[strlen(tmp)-1]='\0';
		(*typmod_arr_p)[i] = atoi(tmp);
	}
}

/* adjust typmod for some spefic type */
int adjustTypmod(Oid oid, int typmod)
{
	Type 		baseType;
	char* 		typname;

	if(typmod == 0)
		return -1;

	baseType = typeidType(oid);
	typname = typeTypeName(baseType);
	ReleaseSysCache(baseType);

	if(strcmp(typname,"varchar") == 0
	|| strcmp(typname,"varbinary") == 0
	|| strcmp(typname,"binary") == 0
	|| strcmp(typname,"nvarchar") == 0
	|| strcmp(typname,"nchar") == 0
	|| strcmp(typname,"bpchar") == 0)
	{
		if (typmod == -1)
		/* Default length without specification of these types is 1 in tsql */
			return VARHDRSZ + 1 - typmod;
		else
			return VARHDRSZ;
	}
	return 0;
}
