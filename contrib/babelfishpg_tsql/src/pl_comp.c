/*-------------------------------------------------------------------------
 *
 * pl_comp.c		- Compiler part of the PL/tsql
 *			  procedural language
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/pl/pltsql/src/pl_comp.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "miscadmin.h"
#include "varatt.h"
#include <ctype.h>
#include <fcntl.h>				/* FIXME: for debugging only - feel free to
								 * remove */
#include <unistd.h>				/* FIXME: for debugging only - feel free to
								 * remove */

#include "access/htup_details.h"
#include "catalog/namespace.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "funcapi.h"
#include "nodes/makefuncs.h"
#include "parser/parse_relation.h"
#include "parser/parse_type.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/regproc.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/typcache.h"

#include "pltsql.h"
#include "pltsql-2.h"
#include "analyzer.h"
#include "codegen.h"
#include "iterative_exec.h"
#include "multidb.h"
#include "collation.h"

/* ----------
 * Our own local and global variables
 * ----------
 */
PLtsql_stmt_block *pltsql_parse_result;

static int	datums_alloc;
int			pltsql_nDatums;
PLtsql_datum **pltsql_Datums;
static int	datums_last;

char	   *pltsql_error_funcname;
bool		pltsql_DumpExecTree = false;
bool		pltsql_check_syntax = false;

PLtsql_function *pltsql_curr_compile;
int			pltsql_curr_compile_body_lineno;	/* lineno of
												 * function/procedure body in
												 * CREATE */

/* A context appropriate for short-term allocs during compilation */
MemoryContext pltsql_compile_tmp_cxt;

/* ----------
 * Hash table for compiled functions
 * ----------
 */
static HTAB *pltsql_HashTable = NULL;

typedef struct pltsql_hashent
{
	PLtsql_func_hashkey key;
	PLtsql_function *function;
} pltsql_HashEnt;

#define FUNCS_PER_USER		128 /* initial table size */

/* ----------
 * Lookup table for EXCEPTION condition names
 * ----------
 */
typedef struct
{
	const char *label;
	int			sqlerrstate;
} ExceptionLabelMap;

static const ExceptionLabelMap exception_label_map[] = {
#include "plerrcodes.h"			/* pgrminclude ignore */
	{NULL, 0}
};

/* ----------
 * Current session's handler
 * ----------
 */

static int	cur_handle_id = 1;

/* ----------
 * static prototypes
 * ----------
 */
static PLtsql_function *do_compile(FunctionCallInfo fcinfo,
								   HeapTuple procTup,
								   PLtsql_function *function,
								   PLtsql_func_hashkey *hashkey,
								   bool forValidator);
static void pltsql_compile_error_callback(void *arg);
static void add_parameter_name(PLtsql_nsitem_type itemtype, int itemno, const char *name);
static void add_dummy_return(PLtsql_function *function);
static void add_decl_table(PLtsql_function *function, int tbl_dno, char *tbl_typ);
static Node *pltsql_pre_column_ref(ParseState *pstate, ColumnRef *cref);
static Node *pltsql_post_column_ref(ParseState *pstate, ColumnRef *cref, Node *var);
static void pltsql_post_expand_star(ParseState *pstate, ColumnRef *cref, List *l);
static Node *pltsql_param_ref(ParseState *pstate, ParamRef *pref);
static Node *resolve_column_ref(ParseState *pstate, PLtsql_expr *expr,
								ColumnRef *cref, bool error_if_no_field);
static Node *make_datum_param(PLtsql_expr *expr, int dno, int location);
static PLtsql_row *build_row_from_vars(PLtsql_variable **vars, int numvars);
static PLtsql_type *build_datatype(HeapTuple typeTup, int32 typmod,
								   Oid collation, TypeName *origtypname);
static void pltsql_start_datums(void);
static void pltsql_finish_datums(PLtsql_function *function);
static void compute_function_hashkey(FunctionCallInfo fcinfo,
									 Form_pg_proc procStruct,
									 PLtsql_func_hashkey *hashkey,
									 bool forValidator);
static void pltsql_resolve_polymorphic_argtypes(int numargs,
												Oid *argtypes, char *argmodes,
												Node *call_expr, bool forValidator,
												const char *proname);
static PLtsql_function *pltsql_HashTableLookup(PLtsql_func_hashkey *func_key);
static void pltsql_HashTableInsert(PLtsql_function *function,
								   PLtsql_func_hashkey *func_key);
static void pltsql_HashTableDelete(PLtsql_function *function);
static void delete_function(PLtsql_function *func);

extern Portal ActivePortal;
extern bool pltsql_function_parse_error_transpose(const char *prosrc);

/* ----------
 * pltsql_compile		Make an execution tree for a PL/tsql function.
 *
 * If forValidator is true, we're only compiling for validation purposes,
 * and so some checks are skipped.
 *
 * Note: it's important for this to fall through quickly if the function
 * has already been compiled.
 * ----------
 */
PLtsql_function *
pltsql_compile(FunctionCallInfo fcinfo, bool forValidator)
{
	Oid			funcOid = fcinfo->flinfo->fn_oid;
	HeapTuple	procTup;
	Form_pg_proc procStruct;
	PLtsql_function *function;
	PLtsql_func_hashkey hashkey;
	bool		function_valid = false;
	bool		hashkey_valid = false;
	bool		function_in_use = false;

	/*
	 * Lookup the pg_proc tuple by Oid; we'll need it in any case
	 */
	procTup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcOid));
	if (!HeapTupleIsValid(procTup))
		elog(ERROR, "cache lookup failed for function %u", funcOid);
	procStruct = (Form_pg_proc) GETSTRUCT(procTup);

	/*
	 * See if there's already a cache entry for the current FmgrInfo. If not,
	 * try to find one in the hash table.
	 */
	function = (PLtsql_function *) fcinfo->flinfo->fn_extra;

recheck:
	if (!function)
	{
		/* Compute hashkey using function signature and actual arg types */
		compute_function_hashkey(fcinfo, procStruct, &hashkey, forValidator);
		hashkey_valid = true;

		/* And do the lookup */
		function = pltsql_HashTableLookup(&hashkey);
	}

	if (function)
	{
		/* We have a compiled function, but is it still valid? */
		if (function->fn_xmin == HeapTupleHeaderGetRawXmin(procTup->t_data) &&
			ItemPointerEquals(&function->fn_tid, &procTup->t_self) &&
			function->exec_codes_valid)
			function_valid = true;
		else
		{
			/*
			 * Nope, so remove it from hashtable and try to drop associated
			 * storage (if not done already).
			 * Check whether function is in use or not before deleting it, if
			 * function is not in use - its memory context will be freed.
			 * PLtsql_function struct itself could have been allocated in the same
			 * context, so we avoid accessing struct fields after the delete call.
			 */
			function_in_use = function->use_count != 0;
			delete_function(function);

			/*
			 * If the function isn't in active use then we can overwrite the
			 * func struct with new data, allowing any other existing fn_extra
			 * pointers to make use of the new definition on their next use.
			 * If it is in use then just leave it alone and make a new one.
			 * (The active invocations will run to completion using the
			 * previous definition, and then the cache entry will just be
			 * leaked; doesn't seem worth adding code to clean it up, given
			 * what a corner case this is.)
			 *
			 * If we found the function struct via fn_extra then it's possible
			 * a replacement has already been made, so go back and recheck the
			 * hashtable.
			 */
			if (function_in_use)
			{
				function = NULL;
				if (!hashkey_valid)
					goto recheck;
			}
		}
	}

	/*
	 * If the function wasn't found or was out-of-date, we have to compile it
	 */
	if (!function_valid)
	{
		/*
		 * Calculate hashkey if we didn't already; we'll need it to store the
		 * completed function.
		 */
		if (!hashkey_valid)
			compute_function_hashkey(fcinfo, procStruct, &hashkey,
									 forValidator);

		/*
		 * Do the hard part.
		 */
		function = do_compile(fcinfo, procTup, function,
							  &hashkey, forValidator);
	}

	ReleaseSysCache(procTup);

	/*
	 * Save pointer in FmgrInfo to avoid search on subsequent calls
	 */
	fcinfo->flinfo->fn_extra = (void *) function;

	/*
	 * Finally return the compiled function
	 */
	return function;
}

/*
 * This is the slow part of pltsql_compile().
 *
 * The passed-in "function" pointer is either NULL or an already-allocated
 * function struct to overwrite.
 *
 * While compiling a function, the CurrentMemoryContext is the
 * per-function memory context of the function we are compiling. That
 * means a palloc() will allocate storage with the same lifetime as
 * the function itself.
 *
 * Because palloc()'d storage will not be immediately freed, temporary
 * allocations should either be performed in a short-lived memory
 * context or explicitly pfree'd. Since not all backend functions are
 * careful about pfree'ing their allocations, it is also wise to
 * switch into a short-term context before calling into the
 * backend. An appropriate context for performing short-term
 * allocations is the pltsql_compile_tmp_cxt.
 *
 * NB: this code is not re-entrant.  We assume that nothing we do here could
 * result in the invocation of another pltsql function.
 */
static PLtsql_function *
do_compile(FunctionCallInfo fcinfo,
		   HeapTuple procTup,
		   PLtsql_function *function,
		   PLtsql_func_hashkey *hashkey,
		   bool forValidator)
{
	Form_pg_proc procStruct = (Form_pg_proc) GETSTRUCT(procTup);
	bool		is_dml_trigger = CALLED_AS_TRIGGER(fcinfo);
	bool		is_event_trigger = CALLED_AS_EVENT_TRIGGER(fcinfo);
	Datum		prosrcdatum;
	bool		isnull;
	char	   *proc_source;
	HeapTuple	typeTup;
	Form_pg_type typeStruct;
	PLtsql_variable *var;
	PLtsql_rec *rec;
	int			i;
	ErrorContextCallback plerrcontext;
	int			parse_rc;
	Oid			rettypeid;
	int			numargs;
	int			num_in_args = 0;
	int			num_out_args = 0;
	Oid		   *argtypes;
	char	  **argnames;
	char	   *argmodes;
	int		   *in_arg_varnos = NULL;
	PLtsql_variable **out_arg_variables;
	MemoryContext func_cxt;

	/* Special handling is needed for Multi-Statement Table-Valued Functions. */
	int			tbl_dno = -1;	/* dno of the output table variable */
	char	   *tbl_typ = NULL; /* Name of the output table variable's type */
	int		   *typmods = NULL; /* typmod of each argument if available */
	CompileContext *cmpl_ctx = create_compile_context();

	/*
	 * Setup the scanner input and error info.  We assume that this function
	 * cannot be invoked recursively, so there's no need to save and restore
	 * the static variables used here.
	 */
	prosrcdatum = SysCacheGetAttr(PROCOID, procTup,
								  Anum_pg_proc_prosrc, &isnull);
	if (isnull)
		elog(ERROR, "null prosrc");
	proc_source = TextDatumGetCString(prosrcdatum);
	pltsql_scanner_init(proc_source);

	pltsql_error_funcname = pstrdup(NameStr(procStruct->proname));

	/*
	 * Setup error traceback support for ereport()
	 */
	plerrcontext.callback = pltsql_compile_error_callback;
	plerrcontext.arg = forValidator ? proc_source : NULL;
	plerrcontext.previous = error_context_stack;
	error_context_stack = &plerrcontext;

	/*
	 * Do extra syntax checks when validating the function definition. We skip
	 * this when actually compiling functions for execution, for performance
	 * reasons.
	 */
	pltsql_check_syntax = forValidator;

	/*
	 * Create the new function struct, if not done already.  The function
	 * structs are never thrown away, so keep them in TopMemoryContext.
	 */
	if (function == NULL)
	{
		function = (PLtsql_function *)
			MemoryContextAllocZero(TopMemoryContext, sizeof(PLtsql_function));
	}
	else
	{
		free_exec_codes(function->exec_codes);
		/* re-using a previously existing struct, so clear it out */
		memset(function, 0, sizeof(PLtsql_function));
	}
	pltsql_curr_compile = function;

	/*
	 * All the permanent output of compilation (e.g. parse tree) is kept in a
	 * per-function memory context, so it can be reclaimed easily.
	 */
	func_cxt = AllocSetContextCreate(TopMemoryContext,
									 "PL/tsql function",
									 ALLOCSET_DEFAULT_SIZES);
	pltsql_compile_tmp_cxt = MemoryContextSwitchTo(func_cxt);

	function->fn_signature = format_procedure(fcinfo->flinfo->fn_oid);
	MemoryContextSetIdentifier(func_cxt, function->fn_signature);
	function->fn_oid = fcinfo->flinfo->fn_oid;
	function->fn_xmin = HeapTupleHeaderGetRawXmin(procTup->t_data);
	function->fn_tid = procTup->t_self;
	function->fn_input_collation = fcinfo->fncollation;
	function->fn_cxt = func_cxt;
	function->out_param_varno = -1; /* set up for no OUT param */
	function->resolve_option = pltsql_variable_conflict;

	if (is_dml_trigger)
		function->fn_is_trigger = PLTSQL_DML_TRIGGER;
	else if (is_event_trigger)
		function->fn_is_trigger = PLTSQL_EVENT_TRIGGER;
	else
		function->fn_is_trigger = PLTSQL_NOT_TRIGGER;

	function->fn_prokind = procStruct->prokind;
	/* Build a tuple descriptor for the result rowtype */
	function->fn_tupdesc = NULL;

	/*
	 * Initialize the compiler, particularly the namespace stack.  The
	 * outermost namespace contains function parameters and other special
	 * variables (such as FOUND), and is named after the function itself.
	 */
	pltsql_ns_init();
	pltsql_ns_push(NameStr(procStruct->proname), PLTSQL_LABEL_BLOCK);
	pltsql_start_datums();

	switch (function->fn_is_trigger)
	{
		case PLTSQL_NOT_TRIGGER:

			/*
			 * Fetch info about the procedure's parameters. Allocations aren't
			 * needed permanently, so make them in tmp cxt.
			 *
			 * We also need to resolve any polymorphic input or output
			 * argument types.  In validation mode we won't be able to, so we
			 * arbitrarily assume we are dealing with integers.
			 */
			MemoryContextSwitchTo(pltsql_compile_tmp_cxt);

			numargs = get_func_arg_info(procTup,
										&argtypes, &argnames, &argmodes);

			pltsql_resolve_polymorphic_argtypes(numargs, argtypes, argmodes,
												fcinfo->flinfo->fn_expr,
												forValidator,
												pltsql_error_funcname);

			in_arg_varnos = (int *) palloc(numargs * sizeof(int));
			out_arg_variables = (PLtsql_variable **) palloc(numargs * sizeof(PLtsql_variable *));

			MemoryContextSwitchTo(func_cxt);

			/*
			 * use pronargs and proargtypes here instead of numargs and
			 * argtypes. it matches function signature and typmods array
			 * stored in probin
			 */
			probin_read_args_typmods(procTup, procStruct->pronargs, procStruct->proargtypes.values, &typmods);

			/* Function return type should not be rowversion. */
			if (procStruct->prokind == PROKIND_FUNCTION &&
				(*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (procStruct->prorettype))
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
						 errmsg("The timestamp data type is invalid for return values.")));

			/*
			 * Create the variables for the procedure's parameters.
			 */
			for (i = 0; i < numargs; i++)
			{
				char		buf[32];
				Oid			argtypeid = argtypes[i];
				char		argmode = argmodes ? argmodes[i] : PROARGMODE_IN;
				PLtsql_type *argdtype;
				PLtsql_variable *argvariable;
				PLtsql_nsitem_type argitemtype;
				int typmod = 0;

				/* Create $n name for variable */
				snprintf(buf, sizeof(buf), "$%d", i + 1);

				/* rowversion is not a valid type for function parameter. */
				if (procStruct->prokind == PROKIND_FUNCTION &&
					(*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (argtypeid) &&
					argmode != PROARGMODE_TABLE)
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
							 errmsg("Parameter or variable \"%s\" has an invalid data type.", argnames[i])));

				/*
				 * Function is a Multi-Statement Table-Valued function if
				 * there is a table arg, and the return type is a composite
				 * type. An inline Table-Valued function can also have table
				 * args, but its return type is either RECORD (multi-column)
				 * or a base type (single-column).
				 */
				if (argmode == PROARGMODE_TABLE &&
					get_typtype(procStruct->prorettype) == TYPTYPE_COMPOSITE)
				{
					/* Mstvf should only have one table arg */
					if (function->is_mstvf)
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
								 errmsg("multi-statement table-valued functions can only have one table arg")));

					function->is_mstvf = true;
				}

				/*
 				 * Create datatype info.
 				 * typmods array has length procStruct->pronargs and numargs >= procStruct->pronargs,
 				 * (See Assert in get_func_arg_info())
 				 * Pass in typmods[i] while we are not out of bounds, otherwise pass in -1.
 				 */
				typmod = (typmods && i < procStruct->pronargs) ? typmods[i] : -1;
				argdtype = pltsql_build_datatype(argtypeid,
												 typmod,
												 function->fn_input_collation,
												 NULL);

				/* Disallow pseudotype argument */
				/* (note we already replaced polymorphic types) */
				/* (build_variable would do this, but wrong message) */
				if (argdtype->ttype == PLTSQL_TTYPE_PSEUDO)
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("PL/tsql functions cannot accept type %s",
									format_type_be(argtypeid))));

				/*
				 * Build variable and add to datum list.  If there's a name
				 * for the argument, use that as refname, else use $n name.
				 */
				argvariable = pltsql_build_variable((argnames &&
													 argnames[i][0] != '\0') ?
													argnames[i] : buf,
													0, argdtype, false);

				/*
				 * Multi-Statement Table-Valued Function - save dno and
				 * typname
				 */
				if (function->is_mstvf)
				{
					/* 
					 * For a user-defined @@var or @var# name,
					 * delimit with square brackets
					 */
					char *typname_fmt = "%s.\"%s\"";
					if (!is_tsql_atatuservar(argdtype->typname))
						typname_fmt = pstrdup("%s.%s");

					tbl_dno = argvariable->dno;
					tbl_typ = psprintf(typname_fmt,
									   get_namespace_name(
														  get_rel_namespace(get_typ_typrelid(argtypeid))),
									   argdtype->typname);
				}

				if (argvariable->dtype == PLTSQL_DTYPE_VAR)
				{
					argitemtype = PLTSQL_NSTYPE_VAR;
				}
				else if (argvariable->dtype == PLTSQL_DTYPE_TBL)
				{
					argitemtype = PLTSQL_NSTYPE_TBL;
				}
				else
				{
					Assert(argvariable->dtype == PLTSQL_DTYPE_REC);
					argitemtype = PLTSQL_NSTYPE_REC;
				}

				/* Remember arguments in appropriate arrays */
				if (argmode == PROARGMODE_IN ||
					argmode == PROARGMODE_INOUT ||
					argmode == PROARGMODE_VARIADIC)
					in_arg_varnos[num_in_args++] = argvariable->dno;
				if (argmode == PROARGMODE_OUT ||
					argmode == PROARGMODE_INOUT ||
					argmode == PROARGMODE_TABLE)
					out_arg_variables[num_out_args++] = argvariable;

				/* Add to namespace under the $n name */
				add_parameter_name(argitemtype, argvariable->dno, buf);

				/*
				 * If there's a name for the argument, make an alias
				 *
				 * Inline Table-Valued Function has one argument for each
				 * column of the rows to be returned, and we don't add them to
				 * the namespace to avoid error when query contain the same
				 * column reference name.
				 *
				 * For Multi-Statement Table-Valued Function we don't need to
				 * skip this because it only has one argument for the result
				 * table variable, and shouldn't be confused with column
				 * references.
				 */
				if (argnames && argnames[i][0] != '\0' &&
					(argmode != PROARGMODE_TABLE || function->is_mstvf))
					add_parameter_name(argitemtype, argvariable->dno,
									   argnames[i]);
			}

			/*
			 * If there's just one OUT parameter, out_param_varno points
			 * directly to it.  If there's more than one, build a row that
			 * holds all of them.  Procedures return a row even for one OUT
			 * parameter.
			 */
			if (num_out_args > 1 ||
				(num_out_args == 1 && function->fn_prokind == PROKIND_PROCEDURE))
			{
				PLtsql_row *row = build_row_from_vars(out_arg_variables,
													  num_out_args);

				pltsql_adddatum((PLtsql_datum *) row);
				function->out_param_varno = row->dno;
			}
			else if (num_out_args == 1)
				function->out_param_varno = out_arg_variables[0]->dno;

			/*
			 * Check for a polymorphic returntype. If found, use the actual
			 * returntype type from the caller's FuncExpr node, if we have
			 * one.  (In validation mode we arbitrarily assume we are dealing
			 * with integers.)
			 *
			 * Note: errcode is FEATURE_NOT_SUPPORTED because it should always
			 * work; if it doesn't we're in some context that fails to make
			 * the info available.
			 */
			rettypeid = procStruct->prorettype;
			if (IsPolymorphicType(rettypeid))
			{
				if (forValidator)
				{
					if (rettypeid == ANYARRAYOID)
						rettypeid = INT4ARRAYOID;
					else if (rettypeid == ANYRANGEOID)
						rettypeid = INT4RANGEOID;
					else		/* ANYELEMENT or ANYNONARRAY */
						rettypeid = INT4OID;
					/* XXX what could we use for ANYENUM? */
				}
				else
				{
					rettypeid = get_fn_expr_rettype(fcinfo->flinfo);
					if (!OidIsValid(rettypeid))
						ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("could not determine actual return type "
										"for polymorphic function \"%s\"",
										pltsql_error_funcname)));
				}
			}

			/*
			 * Normal function has a defined returntype
			 */
			function->fn_rettype = rettypeid;
			function->fn_retset = procStruct->proretset;

			/*
			 * Lookup the function's return type
			 */
			typeTup = SearchSysCache1(TYPEOID, ObjectIdGetDatum(rettypeid));
			if (!HeapTupleIsValid(typeTup))
				elog(ERROR, "cache lookup failed for type %u", rettypeid);
			typeStruct = (Form_pg_type) GETSTRUCT(typeTup);

			/* Disallow pseudotype result, except VOID or RECORD */
			/* (note we already replaced polymorphic types) */
			if (typeStruct->typtype == TYPTYPE_PSEUDO)
			{
				if (rettypeid == VOIDOID ||
					rettypeid == RECORDOID)
					 /* okay */ ;
				else if (rettypeid == TRIGGEROID || rettypeid == EVENT_TRIGGEROID)
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("trigger functions can only be called as triggers")));
				else
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("PL/tsql functions cannot return type %s",
									format_type_be(rettypeid))));
			}

			function->fn_retistuple = type_is_rowtype(rettypeid);
			function->fn_retisdomain = (typeStruct->typtype == TYPTYPE_DOMAIN);
			function->fn_retbyval = typeStruct->typbyval;
			function->fn_rettyplen = typeStruct->typlen;
			/* Special handling is needed for Inline Table-Valued Functions. */
			function->is_itvf = procStruct->prokind == PROKIND_FUNCTION &&
				procStruct->proretset &&
				get_typtype(procStruct->prorettype) != TYPTYPE_COMPOSITE;

			/*
			 * install $0 reference, but only for polymorphic return types,
			 * and not when the return is specified through an output
			 * parameter.
			 */
			if (IsPolymorphicType(procStruct->prorettype) &&
				num_out_args == 0)
			{
				(void) pltsql_build_variable("$0", 0,
											 build_datatype(typeTup,
															-1,
															function->fn_input_collation,
															NULL),
											 true);
			}

			ReleaseSysCache(typeTup);
			break;

		case PLTSQL_DML_TRIGGER:
			/* Trigger procedure's return type is unknown yet */
			function->fn_rettype = InvalidOid;
			function->fn_retbyval = false;
			function->fn_retistuple = true;
			function->fn_retisdomain = false;
			function->fn_retset = false;

			/* shouldn't be any declared arguments */
			if (procStruct->pronargs != 0)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
						 errmsg("trigger functions cannot have declared arguments"),
						 errhint("The arguments of the trigger can be accessed through TG_NARGS and TG_ARGV instead.")));

			/* Add the record for referencing NEW ROW */
			rec = pltsql_build_record("new", 0, NULL, RECORDOID, true);
			function->new_varno = rec->dno;

			/* Add the record for referencing OLD ROW */
			rec = pltsql_build_record("old", 0, NULL, RECORDOID, true);
			function->old_varno = rec->dno;

			/* Add the variable tg_name */
			var = pltsql_build_variable("tg_name", 0,
										pltsql_build_datatype(NAMEOID,
															  -1,
															  InvalidOid,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_NAME;

			/* Add the variable tg_when */
			var = pltsql_build_variable("tg_when", 0,
										pltsql_build_datatype(TEXTOID,
															  -1,
															  function->fn_input_collation,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_WHEN;

			/* Add the variable tg_level */
			var = pltsql_build_variable("tg_level", 0,
										pltsql_build_datatype(TEXTOID,
															  -1,
															  function->fn_input_collation,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_LEVEL;

			/* Add the variable tg_op */
			var = pltsql_build_variable("tg_op", 0,
										pltsql_build_datatype(TEXTOID,
															  -1,
															  function->fn_input_collation,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_OP;

			/* Add the variable tg_relid */
			var = pltsql_build_variable("tg_relid", 0,
										pltsql_build_datatype(OIDOID,
															  -1,
															  InvalidOid,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_RELID;

			/* Add the variable tg_relname */
			var = pltsql_build_variable("tg_relname", 0,
										pltsql_build_datatype(NAMEOID,
															  -1,
															  InvalidOid,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_TABLE_NAME;

			/* tg_table_name is now preferred to tg_relname */
			var = pltsql_build_variable("tg_table_name", 0,
										pltsql_build_datatype(NAMEOID,
															  -1,
															  InvalidOid,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_TABLE_NAME;

			/* add the variable tg_table_schema */
			var = pltsql_build_variable("tg_table_schema", 0,
										pltsql_build_datatype(NAMEOID,
															  -1,
															  InvalidOid,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_TABLE_SCHEMA;

			/* Add the variable tg_nargs */
			var = pltsql_build_variable("tg_nargs", 0,
										pltsql_build_datatype(INT4OID,
															  -1,
															  InvalidOid,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_NARGS;

			/* Add the variable tg_argv */
			var = pltsql_build_variable("tg_argv", 0,
										pltsql_build_datatype(TEXTARRAYOID,
															  -1,
															  function->fn_input_collation,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_ARGV;

			break;

		case PLTSQL_EVENT_TRIGGER:
			function->fn_rettype = VOIDOID;
			function->fn_retbyval = false;
			function->fn_retistuple = true;
			function->fn_retisdomain = false;
			function->fn_retset = false;

			/* shouldn't be any declared arguments */
			if (procStruct->pronargs != 0)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
						 errmsg("event trigger functions cannot have declared arguments")));

			/* Add the variable tg_event */
			var = pltsql_build_variable("tg_event", 0,
										pltsql_build_datatype(TEXTOID,
															  -1,
															  function->fn_input_collation,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_EVENT;

			/* Add the variable tg_tag */
			var = pltsql_build_variable("tg_tag", 0,
										pltsql_build_datatype(TEXTOID,
															  -1,
															  function->fn_input_collation,
															  NULL),
										true);
			Assert(var->dtype == PLTSQL_DTYPE_VAR);
			var->dtype = PLTSQL_DTYPE_PROMISE;
			((PLtsql_var *) var)->promise = PLTSQL_PROMISE_TG_TAG;

			break;

		default:
			elog(ERROR, "unrecognized function typecode: %d",
				 (int) function->fn_is_trigger);
			break;
	}

	/* Remember if function is STABLE/IMMUTABLE */
	function->fn_readonly = (procStruct->provolatile != PROVOLATILE_VOLATILE);

	/*
	 * Create the magic FOUND variable.
	 */
	var = pltsql_build_variable("found", 0,
								pltsql_build_datatype(BOOLOID,
													  -1,
													  InvalidOid,
													  NULL),
								true);
	function->found_varno = var->dno;

	var = pltsql_build_variable("@@fetch_status", 0,
								pltsql_build_datatype(INT4OID,
													  -1,
													  InvalidOid,
													  NULL),
								true);

	function->fetch_status_varno = var->dno;

	/*
	 * Now parse the function's text
	 */
	{
		ANTLR_result result = antlr_parser_cpp(proc_source);

		if (result.success)
		{
			parse_rc = 0;
		}
		else
		{
			report_antlr_error(result);
			parse_rc = 1;		/* invalid input */
		}
	}

	if (parse_rc != 0)
		elog(ERROR, "pltsql parser returned %d", parse_rc);
	function->action = pltsql_parse_result;

	pltsql_scanner_finish();
	pfree(proc_source);

	/*
	 * Multi-Statement Table-Valued Function: 1) Add a declare table statement
	 * to the beginning 2) Add a return table statement to the end
	 */
	if (function->is_mstvf)
	{
		/*
		 * ANTLR parser would return a stmt list like INIT->BLOCK, where BLOCK
		 * is a wrapper for the statements. For MSTVF parsing we don't want
		 * the wrapper.
		 */
		Assert(list_length(pltsql_parse_result->body) >= 2);
		function->action = (PLtsql_stmt_block *) lsecond(pltsql_parse_result->body);
		add_decl_table(function, tbl_dno, tbl_typ);
	}

	/*
	 * If it has OUT parameters or returns VOID or returns a set, we allow
	 * control to fall off the end without an explicit RETURN statement. The
	 * easiest way to implement this is to add a RETURN statement to the end
	 * of the statement list during parsing.
	 */
	if (num_out_args > 0 || function->fn_rettype == VOIDOID ||
		function->fn_retset)
		add_dummy_return(function);

	/*
	 * Complete the function's info
	 */
	function->fn_nargs = procStruct->pronargs;
	for (i = 0; i < function->fn_nargs; i++)
		function->fn_argvarnos[i] = in_arg_varnos[i];

	pltsql_finish_datums(function);

	/* Debug dump for completed functions */
	if (pltsql_DumpExecTree || pltsql_trace_tree)
		pltsql_dumptree(function);

	/*
	 * add it to the hash table
	 */
	pltsql_HashTableInsert(function, hashkey);

	/*
	 * Pop the error context stack
	 */
	error_context_stack = plerrcontext.previous;
	pltsql_error_funcname = NULL;

	pltsql_check_syntax = false;

	MemoryContextSwitchTo(pltsql_compile_tmp_cxt);
	pltsql_compile_tmp_cxt = NULL;

	/* Generate execution code for new executor */
	PG_TRY();
	{
		analyze(function, cmpl_ctx);
		gen_exec_code(function, cmpl_ctx);
	}
	PG_CATCH();
	{
		destroy_compile_context(cmpl_ctx);
		PG_RE_THROW();
	}
	PG_END_TRY();
	destroy_compile_context(cmpl_ctx);

	return function;
}

/* ----------
 * pltsql_compile_inline	Make an execution tree for an anonymous code block.
 *
 * Note: this is generally parallel to do_compile(); is it worth trying to
 * merge the two?
 *
 * Note: we assume the block will be thrown away so there is no need to build
 * persistent data structures.
 * ----------
 */
PLtsql_function *
pltsql_compile_inline(char *proc_source, InlineCodeBlockArgs *args)
{
	char	   *func_name = "inline_code_block";
	PLtsql_function *function;
	ErrorContextCallback plerrcontext;
	PLtsql_variable *var;
	int			parse_rc;
	MemoryContext func_cxt;

	Datum	   *allTypes;
	Datum	   *paramModes;
	Datum	   *paramNames;
	bool		have_names = false;
	int		   *in_arg_varnos = NULL;
	int			num_in_args = 0;
	int			num_out_args = 0;
	PLtsql_variable **out_arg_variables;
	int			i;

	int			numargs = args ? args->numargs : 0;
	Oid		   *argtypes = args ? args->argtypes : NULL;
	char	  **argnames = args ? args->argnames : NULL;
	char	   *argmodes = args ? args->argmodes : NULL;
	CompileContext *cmpl_ctx = create_compile_context();

	/*
	 * Setup the scanner input and error info.  We assume that this function
	 * cannot be invoked recursively, so there's no need to save and restore
	 * the static variables used here.
	 */
	pltsql_scanner_init(proc_source);

	pltsql_error_funcname = func_name;

	/*
	 * Setup error traceback support for ereport()
	 */
	plerrcontext.callback = pltsql_compile_error_callback;
	plerrcontext.arg = proc_source;
	plerrcontext.previous = error_context_stack;
	error_context_stack = &plerrcontext;

	/* Do extra syntax checking if check_function_bodies is on */
	pltsql_check_syntax = check_function_bodies;

	/*
	 * All the rest of the compile-time storage (e.g. parse tree) is kept in
	 * its own memory context, so it can be reclaimed easily.
	 */
	if (OPTION_ENABLED(args, CACHE_PLAN))
		func_cxt = AllocSetContextCreate(TopMemoryContext,
										 "PL/tsql inline code context",
										 ALLOCSET_DEFAULT_SIZES);
	else
		func_cxt = AllocSetContextCreate(CurrentMemoryContext,
										 "PL/tsql inline code context",
										 ALLOCSET_DEFAULT_SIZES);

	pltsql_compile_tmp_cxt = MemoryContextSwitchTo(func_cxt);

	/* Function struct does not live past current statement */
	function = (PLtsql_function *) palloc0(sizeof(PLtsql_function));

	pltsql_curr_compile = function;


	function->fn_signature = pstrdup(func_name);
	function->fn_is_trigger = PLTSQL_NOT_TRIGGER;
	function->fn_input_collation = InvalidOid;
	function->fn_cxt = func_cxt;
	function->out_param_varno = -1; /* set up for no OUT param */
	function->resolve_option = pltsql_variable_conflict;

	/*
	 * don't do extra validation for inline code as we don't want to add spam
	 * at runtime
	 */
	function->extra_warnings = 0;
	function->extra_errors = 0;

	pltsql_ns_init();
	pltsql_ns_push(func_name, PLTSQL_LABEL_BLOCK);
	pltsql_DumpExecTree = false;
	pltsql_start_datums();

	/* Set up as though in a function returning VOID */
	function->fn_rettype = VOIDOID;
	function->fn_retset = false;
	function->fn_retistuple = false;
	function->fn_retisdomain = false;
	function->fn_prokind = PROKIND_FUNCTION;
	/* a bit of hardwired knowledge about type VOID here */
	function->fn_retbyval = true;
	function->fn_rettyplen = sizeof(int32);
	function->fn_tupdesc = NULL;

	/*
	 * Remember if function is STABLE/IMMUTABLE.  XXX would it be better to
	 * set this true inside a read-only transaction?  Not clear.
	 */
	function->fn_readonly = false;

	if (numargs > 0)
	{
		in_arg_varnos = (int *) palloc(numargs * sizeof(int));
		out_arg_variables = (PLtsql_variable **) palloc(numargs * sizeof(PLtsql_variable *));
		allTypes = (Datum *) palloc(numargs * sizeof(Datum));
		paramModes = (Datum *) palloc(numargs * sizeof(Datum));
		paramNames = (Datum *) palloc(numargs * sizeof(Datum));
	}

	for (i = 0; i < numargs; i++)
	{
		char		buf[32];
		Oid			argtypeid = argtypes[i];
		char		argmode = argmodes[i];
		PLtsql_type *argdtype;
		PLtsql_variable *argvariable;
		PLtsql_nsitem_type argitemtype;

		/* Create $n name for variable */
		snprintf(buf, sizeof(buf), "$%d", i + 1);

		/* Create datatype info */
		argdtype = pltsql_build_datatype(argtypeid,
										 -1,
										 function->fn_input_collation,
										 NULL);

		/*
		 * Disallow pseudotype argument (note we already replaced polymorphic
		 * types build_variable would do this, but wrong message)
		 */
		if (argdtype->ttype == PLTSQL_TTYPE_PSEUDO)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("PL/tsql functions cannot accept type %s",
							format_type_be(argtypeid))));

		/*
		 * Build variable and add to datum list. If there's a name for the
		 * argument, use that as refname, else use $n name.
		 */
		argvariable = pltsql_build_variable((argnames &&
											 argnames[i][0] != '\0') ?
											argnames[i] : buf,
											0,
											argdtype,
											false);

		if (argvariable->dtype == PLTSQL_DTYPE_VAR)
			argitemtype = PLTSQL_NSTYPE_VAR;
		else if (argvariable->dtype == PLTSQL_DTYPE_TBL)
			argitemtype = PLTSQL_NSTYPE_TBL;
		else
		{
			Assert(argvariable->dtype == PLTSQL_DTYPE_REC);
			argitemtype = PLTSQL_NSTYPE_REC;
		}

		/* Remember arguments in appropriate arrays */
		if (argmode == FUNC_PARAM_IN ||
			argmode == FUNC_PARAM_INOUT ||
			argmode == FUNC_PARAM_VARIADIC)
			in_arg_varnos[num_in_args++] = argvariable->dno;
		if (argmode == FUNC_PARAM_OUT ||
			argmode == FUNC_PARAM_INOUT ||
			argmode == FUNC_PARAM_TABLE)
			out_arg_variables[num_out_args++] = argvariable;

		/* Add to namespace under the $n name */
		add_parameter_name(argitemtype, argvariable->dno, buf);

		/* If there's a name for the argument, make an alias */
		if (argnames && argnames[i][0] != '\0')
		{
			add_parameter_name(argitemtype, argvariable->dno,
							   argnames[i]);
			paramNames[i] = CStringGetTextDatum(argnames[i]);
			have_names = true;
		}

		allTypes[i] = ObjectIdGetDatum(argtypeid);
		paramModes[i] = CharGetDatum(argmode);
	}

	/*
	 * When there are more than one output argument, the return type should be
	 * RECORD and there should be a tuple descriptor for all argument types,
	 * i.e. this is a sp_executesql case.
	 */
	if (num_out_args >= 1)
	{
		ArrayType  *allParameterTypes;
		ArrayType  *parameterModes;
		ArrayType  *parameterNames;
		PLtsql_row *row;

		function->fn_prokind = PROKIND_PROCEDURE;
		function->fn_rettype = RECORDOID;
		function->fn_retistuple = true;
		function->fn_retbyval = false;
		function->fn_rettyplen = -1;

		allParameterTypes = construct_array(allTypes, numargs, OIDOID,
											sizeof(Oid), true, 'i');
		parameterModes = construct_array(paramModes, numargs, CHAROID,
										 1, true, 'c');
		if (have_names)
		{
			for (i = 0; i < numargs; i++)
			{
				if (paramNames[i] == PointerGetDatum(NULL))
					paramNames[i] = CStringGetTextDatum("");
			}
			parameterNames = construct_array(paramNames, numargs, TEXTOID,
											 -1, false, 'i');
		}
		else
			parameterNames = NULL;

		/* Build a tuple descriptor for the result rowtype */
		function->fn_tupdesc = build_function_result_tupdesc_d(function->fn_prokind,
															   PointerGetDatum(allParameterTypes),
															   PointerGetDatum(parameterModes),
															   PointerGetDatum(parameterNames));

		/*
		 * For a procedure that has one or more OUT parameters (sp_executesql
		 * at the moment), build a row that holds all of them.
		 */
		row = build_row_from_vars(out_arg_variables, num_out_args);
		pltsql_adddatum((PLtsql_datum *) row);
		function->out_param_varno = row->dno;
	}

	/*
	 * Create the magic FOUND variable.
	 */
	var = pltsql_build_variable("found", 0,
								pltsql_build_datatype(BOOLOID,
													  -1,
													  InvalidOid,
													  NULL),
								true);
	function->found_varno = var->dno;

	var = pltsql_build_variable("@@fetch_status", 0,
								pltsql_build_datatype(INT4OID,
													  -1,
													  InvalidOid,
													  NULL),
								true);
	function->fetch_status_varno = var->dno;

	/*
	 * Now parse the function's text
	 */
	{
		ANTLR_result result = antlr_parser_cpp(proc_source);

		if (result.success)
		{
			parse_rc = 0;
		}
		else
		{
			report_antlr_error(result);
			parse_rc = 1;		/* invalid input */
		}
	}

	if (parse_rc != 0)
		elog(ERROR, "pltsql parser returned %d", parse_rc);
	function->action = pltsql_parse_result;

	{
		extern void toDotTSql(PLtsql_stmt *tree, const char *sourceText, const char *fileName);

		toDotTSql((PLtsql_stmt *) pltsql_parse_result, proc_source, "/tmp/sql.dot");
	}


	pltsql_scanner_finish();

	/*
	 * If it returns VOID or has OUT parameters (always true at the moment),
	 * we allow control to fall off the end without an explicit RETURN
	 * statement.
	 */
	if (num_out_args > 0 || function->fn_rettype == VOIDOID)
		add_dummy_return(function);

	/*
	 * Complete the function's info
	 */
	function->fn_nargs = numargs;
	for (i = 0; i < function->fn_nargs; i++)
		function->fn_argvarnos[i] = in_arg_varnos[i];

	pltsql_finish_datums(function);

	/* Debug dump for completed functions */
	if (pltsql_DumpExecTree || pltsql_trace_tree)
		pltsql_dumptree(function);

	/*
	 * Pop the error context stack
	 */
	error_context_stack = plerrcontext.previous;
	pltsql_error_funcname = NULL;

	pltsql_check_syntax = false;

	MemoryContextSwitchTo(pltsql_compile_tmp_cxt);
	pltsql_compile_tmp_cxt = NULL;

	/* Generate execution code for new executor */
	PG_TRY();
	{
		analyze(function, cmpl_ctx);
		gen_exec_code(function, cmpl_ctx);
	}
	PG_CATCH();
	{
		destroy_compile_context(cmpl_ctx);
		PG_RE_THROW();
	}
	PG_END_TRY();
	destroy_compile_context(cmpl_ctx);

	return function;
}

/*
 * error context callback to let us supply a call-stack traceback.
 * If we are validating or executing an anonymous code block, the function
 * source text is passed as an argument.
 */
static void
pltsql_compile_error_callback(void *arg)
{
	if (arg)
	{
		/*
		 * Try to convert syntax error position to reference text of original
		 * CREATE FUNCTION or DO command.
		 */

		if (!ActivePortal || !ActivePortal->sourceText)
		{
			/*
			 * ActivePortal can be NULL when tsql batch mode is on. But
			 * function_parse_error_transpose() can assume ActivePortal is not
			 * NULL and try to access it to get full original query text.
			 * Also, we may have created a dummy ActivePortal which does not
			 * contain query text. To avoid crash, use pltsql function which
			 * is the similar as original one but not trying to get full
			 * original query text. The side effect will be errposition is set
			 * to 0 in some cases.
			 */
			if (pltsql_function_parse_error_transpose((const char *) arg))
				return;
		}
		else
		{
			if (function_parse_error_transpose((const char *) arg))
				return;
		}

		/*
		 * Done if a syntax error position was reported; otherwise we have to
		 * fall back to a "near line N" report.
		 */
	}

	if (pltsql_error_funcname)
		errcontext("compilation of PL/tsql function \"%s\" near line %d",
				   pltsql_error_funcname, pltsql_latest_lineno());
}


/*
 * Add a name for a function parameter to the function's namespace
 */
static void
add_parameter_name(PLtsql_nsitem_type itemtype, int itemno, const char *name)
{
	/*
	 * Before adding the name, check for duplicates.  We need this even though
	 * functioncmds.c has a similar check, because that code explicitly
	 * doesn't complain about conflicting IN and OUT parameter names.  In
	 * pltsql, such names are in the same namespace, so there is no way to
	 * disambiguate.
	 */
	if (pltsql_ns_lookup(pltsql_ns_top(), true,
						 name, NULL, NULL,
						 NULL) != NULL)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
				 errmsg("parameter name \"%s\" used more than once",
						name)));

	/* OK, add the name */
	pltsql_ns_additem(itemtype, itemno, name);
}

/*
 * Add a dummy RETURN statement to the given function's body
 */
static void
add_dummy_return(PLtsql_function *function)
{
	/*
	 * If the outer block has an EXCEPTION clause, we need to make a new outer
	 * block, since the added RETURN shouldn't act like it is inside the
	 * EXCEPTION clause.
	 */
	if (function->action->exceptions != NULL)
	{
		PLtsql_stmt_block *new;

		new = palloc0(sizeof(PLtsql_stmt_block));
		new->cmd_type = PLTSQL_STMT_BLOCK;
		new->body = list_make1(function->action);

		function->action = new;
	}
	if (function->action->body == NIL ||
		((PLtsql_stmt *) llast(function->action->body))->cmd_type != PLTSQL_STMT_RETURN)
	{
		PLtsql_stmt_return *new;

		new = palloc0(sizeof(PLtsql_stmt_return));
		new->cmd_type = PLTSQL_STMT_RETURN;
		new->expr = NULL;
		new->retvarno = function->out_param_varno;

		function->action->body = lappend(function->action->body, new);
	}
}

/*
 * Add a DECLARE TABLE statement to the given function's body
 */
static void
add_decl_table(PLtsql_function *function, int tbl_dno, char *tbl_typ)
{
	PLtsql_stmt_decl_table *new;

	new = palloc0(sizeof(PLtsql_stmt_decl_table));
	new->cmd_type = PLTSQL_STMT_DECL_TABLE;
	new->dno = tbl_dno;
	new->tbltypname = tbl_typ;

	/* Add the stmt to the beginning */
	function->action->body = lcons(new, function->action->body);
}

/*
 * pltsql_parser_setup		set up parser hooks for dynamic parameters
 *
 * Note: this routine, and the hook functions it prepares for, are logically
 * part of pltsql parsing.  But they actually run during function execution,
 * when we are ready to evaluate a SQL query or expression that has not
 * previously been parsed and planned.
 */
void
pltsql_parser_setup(struct ParseState *pstate, PLtsql_expr *expr)
{
	pstate->p_pre_columnref_hook = pltsql_pre_column_ref;
	pstate->p_post_columnref_hook = pltsql_post_column_ref;
	pstate->p_post_expand_star_hook = pltsql_post_expand_star;
	pstate->p_paramref_hook = pltsql_param_ref;
	/* no need to use p_coerce_param_hook */
	pstate->p_ref_hook_state = (void *) expr;
}

/*
 * pltsql_pre_column_ref		parser callback before parsing a ColumnRef
 */
static Node *
pltsql_pre_column_ref(ParseState *pstate, ColumnRef *cref)
{
	PLtsql_expr *expr = (PLtsql_expr *) pstate->p_ref_hook_state;

	if (expr->func->resolve_option == PLTSQL_RESOLVE_VARIABLE)
		return resolve_column_ref(pstate, expr, cref, false);
	else
		return NULL;
}

/*
 * pltsql_post_column_ref		parser callback after parsing a ColumnRef
 */
static Node *
pltsql_post_column_ref(ParseState *pstate, ColumnRef *cref, Node *var)
{
	PLtsql_expr *expr = (PLtsql_expr *) pstate->p_ref_hook_state;
	Node	   *myvar;

	if (expr->func->resolve_option == PLTSQL_RESOLVE_VARIABLE)
		return NULL;			/* we already found there's no match */

	if (expr->func->resolve_option == PLTSQL_RESOLVE_COLUMN && var != NULL)
		return NULL;			/* there's a table column, prefer that */

	/*
	 * If we find a record/row variable but can't match a field name, throw
	 * error if there was no core resolution for the ColumnRef either.  In
	 * that situation, the reference is inevitably going to fail, and
	 * complaining about the record/row variable is likely to be more on-point
	 * than the core parser's error message.  (It's too bad we don't have
	 * access to transformColumnRef's internal crerr state here, as in case of
	 * a conflict with a table name this could still be less than the most
	 * helpful error message possible.)
	 */
	myvar = resolve_column_ref(pstate, expr, cref, (var == NULL));

	if (myvar != NULL && var != NULL)
	{
		/*
		 * We could leave it to the core parser to throw this error, but we
		 * can add a more useful detail message than the core could.
		 */
		ereport(ERROR,
				(errcode(ERRCODE_AMBIGUOUS_COLUMN),
				 errmsg("column reference \"%s\" is ambiguous",
						NameListToString(cref->fields)),
				 errdetail("It could refer to either a PL/tsql variable or a table column."),
				 parser_errposition(pstate, cref->location)));
	}

	return myvar;
}


/*
 * Call this hook only when expanding a SELECT * or relation.* to its individual column names
 * We can rewrite the column names to their Babelfish (ie original case) names
 * if we find them in pg_attribute.
 */
static void
pltsql_post_expand_star(ParseState *pstate, ColumnRef *cref, List *l)
{
	ListCell   *li;
	Datum		attopts;
	ArrayType  *arr;
	Datum	   *optiondatums;
	int			noptions,
				i;
	char	   *optstr;

	foreach(li, l)
	{
		/*
		 * Each item in the List here should be a TargetEntry (see
		 * ExpandAllTables/expandNSItemAttrs)
		 */
		TargetEntry *te = (TargetEntry *) lfirst(li);
		Var		   *varnode = (Var *) te->expr;
		RangeTblEntry *rte = GetRTEByRangeTablePosn(pstate, varnode->varno, varnode->varlevelsup);
		Oid			relid = rte->relid;
		int16		attnum = varnode->varattno;

		if (rte->rtekind != RTE_RELATION || relid == InvalidOid)
		{
			return;
		}

		/*
		 * Get the list of names in pg_attribute. get_attoptions returns a
		 * Datum of the text[] field pgattribute.attoptions. We don't want to
		 * throw a full error if cache lookup fails to preserve functionality,
		 * so just log it.
		 */
		PG_TRY();
		{
			attopts = get_attoptions(relid, attnum);
		}
		PG_CATCH();
		{
			HOLD_INTERRUPTS();
			elog(LOG, "Cache lookup failed in pltsql_post_expand_star for attribute %d of relation %u",
				 attnum, relid);
			attopts = (Datum) 0;
			RESUME_INTERRUPTS();
		}
		PG_END_TRY();
		if (!attopts)
		{
			return;
		}

		arr = DatumGetArrayTypeP(attopts);
		deconstruct_array(arr, TEXTOID, -1, false, TYPALIGN_INT,
						  &optiondatums, NULL, &noptions);

		for (i = 0; i < noptions; i++)
		{
			optstr = VARDATA(optiondatums[i]);
			if (strncmp(optstr, "bbf_original_name=", 18) == 0)
			{
				/*
				 * We found the original name; rewrite it as bbf_original_name
				 */
				te->resname = pnstrdup((char *) &optstr[18], strlen(te->resname));
				break;
			}
		}
	}
}

/*
 * pltsql_param_ref		parser callback for ParamRefs ($n symbols)
 */
static Node *
pltsql_param_ref(ParseState *pstate, ParamRef *pref)
{
	PLtsql_expr *expr = (PLtsql_expr *) pstate->p_ref_hook_state;
	char		pname[32];
	PLtsql_nsitem *nse;

	snprintf(pname, sizeof(pname), "$%d", pref->number);

	nse = pltsql_ns_lookup(expr->ns, false,
						   pname, NULL, NULL,
						   NULL);

	if (nse == NULL)
		return NULL;			/* name not known to pltsql */

	return make_datum_param(expr, nse->itemno, pref->location);
}

/*
 * resolve_column_ref		attempt to resolve a ColumnRef as a pltsql var
 *
 * Returns the translated node structure, or NULL if name not found
 *
 * error_if_no_field tells whether to throw error or quietly return NULL if
 * we are able to match a record/row name but don't find a field name match.
 */
static Node *
resolve_column_ref(ParseState *pstate, PLtsql_expr *expr,
				   ColumnRef *cref, bool error_if_no_field)
{
	PLtsql_execstate *estate;
	PLtsql_nsitem *nse;
	const char *name1;
	const char *name2 = NULL;
	const char *name3 = NULL;
	const char *colname = NULL;
	int			nnames;
	int			nnames_scalar = 0;
	int			nnames_wholerow = 0;
	int			nnames_field = 0;

	/*
	 * We use the function's current estate to resolve parameter data types.
	 * This is really pretty bogus because there is no provision for updating
	 * plans when those types change ...
	 */
	estate = expr->func->cur_estate;

	/*----------
	 * The allowed syntaxes are:
	 *
	 * A		Scalar variable reference, or whole-row record reference.
	 * A.B		Qualified scalar or whole-row reference, or field reference.
	 * A.B.C	Qualified record field reference.
	 * A.*		Whole-row record reference.
	 * A.B.*	Qualified whole-row record reference.
	 *----------
	 */
	switch (list_length(cref->fields))
	{
		case 1:
			{
				Node	   *field1 = (Node *) linitial(cref->fields);

				Assert(IsA(field1, String));
				name1 = strVal(field1);
				nnames_scalar = 1;
				nnames_wholerow = 1;
				break;
			}
		case 2:
			{
				Node	   *field1 = (Node *) linitial(cref->fields);
				Node	   *field2 = (Node *) lsecond(cref->fields);

				Assert(IsA(field1, String));
				name1 = strVal(field1);

				/* Whole-row reference? */
				if (IsA(field2, A_Star))
				{
					/* Set name2 to prevent matches to scalar variables */
					name2 = "*";
					nnames_wholerow = 1;
					break;
				}

				Assert(IsA(field2, String));
				name2 = strVal(field2);
				colname = name2;
				nnames_scalar = 2;
				nnames_wholerow = 2;
				nnames_field = 1;
				break;
			}
		case 3:
			{
				Node	   *field1 = (Node *) linitial(cref->fields);
				Node	   *field2 = (Node *) lsecond(cref->fields);
				Node	   *field3 = (Node *) lthird(cref->fields);

				Assert(IsA(field1, String));
				name1 = strVal(field1);
				Assert(IsA(field2, String));
				name2 = strVal(field2);

				/* Whole-row reference? */
				if (IsA(field3, A_Star))
				{
					/* Set name3 to prevent matches to scalar variables */
					name3 = "*";
					nnames_wholerow = 2;
					break;
				}

				Assert(IsA(field3, String));
				name3 = strVal(field3);
				colname = name3;
				nnames_field = 2;
				break;
			}
		default:
			/* too many names, ignore */
			return NULL;
	}

	nse = pltsql_ns_lookup(expr->ns, false,
						   name1, name2, name3,
						   &nnames);

	if (nse == NULL)
		return NULL;			/* name not known to pltsql */

	switch (nse->itemtype)
	{
		case PLTSQL_NSTYPE_VAR:
			if (nnames == nnames_scalar)
				return make_datum_param(expr, nse->itemno, cref->location);
			break;
		case PLTSQL_NSTYPE_REC:
			if (nnames == nnames_wholerow)
				return make_datum_param(expr, nse->itemno, cref->location);
			if (nnames == nnames_field)
			{
				/* colname could be a field in this record */
				PLtsql_rec *rec = (PLtsql_rec *) estate->datums[nse->itemno];
				int			i;

				/* search for a datum referencing this field */
				i = rec->firstfield;
				while (i >= 0)
				{
					PLtsql_recfield *fld = (PLtsql_recfield *) estate->datums[i];

					Assert(fld->dtype == PLTSQL_DTYPE_RECFIELD &&
						   fld->recparentno == nse->itemno);
					if (strcmp(fld->fieldname, colname) == 0)
					{
						return make_datum_param(expr, i, cref->location);
					}
					i = fld->nextfield;
				}

				/*
				 * We should not get here, because a RECFIELD datum should
				 * have been built at parse time for every possible qualified
				 * reference to fields of this record.  But if we do, handle
				 * it like field-not-found: throw error or return NULL.
				 */
				if (error_if_no_field)
					ereport(ERROR,
							(errcode(ERRCODE_UNDEFINED_COLUMN),
							 errmsg("record \"%s\" has no field \"%s\"",
									(nnames_field == 1) ? name1 : name2,
									colname),
							 parser_errposition(pstate, cref->location)));
			}
			break;
		case PLTSQL_NSTYPE_TBL:
			/* table variables should look like scalar variables */
			if (nnames == nnames_scalar)
				return make_datum_param(expr, nse->itemno, cref->location);
			break;
		default:
			elog(ERROR, "unrecognized pltsql itemtype: %d", nse->itemtype);
	}

	/* Name format doesn't match the pltsql variable type */
	return NULL;
}

/*
 * Helper for columnref parsing: build a Param referencing a pltsql datum,
 * and make sure that that datum is listed in the expression's paramnos.
 */
static Node *
make_datum_param(PLtsql_expr *expr, int dno, int location)
{
	PLtsql_execstate *estate;
	PLtsql_datum *datum;
	Param	   *param;
	MemoryContext oldcontext;

	/* see comment in resolve_column_ref */
	estate = expr->func->cur_estate;
	Assert(dno >= 0 && dno < estate->ndatums);
	datum = estate->datums[dno];

	/*
	 * Bitmapset must be allocated in function's permanent memory context
	 */
	oldcontext = MemoryContextSwitchTo(expr->func->fn_cxt);
	expr->paramnos = bms_add_member(expr->paramnos, dno);
	MemoryContextSwitchTo(oldcontext);

	param = makeNode(Param);
	param->paramkind = PARAM_EXTERN;
	param->paramid = dno + 1;
	pltsql_exec_get_datum_type_info(estate,
									datum,
									&param->paramtype,
									&param->paramtypmod,
									&param->paramcollid);
	param->location = location;

	return (Node *) param;
}


/* ----------
 * pltsql_parse_word		The scanner calls this to postparse
 *				any single word that is not a reserved keyword.
 *
 * word1 is the downcased/dequoted identifier; it must be palloc'd in the
 * function's long-term memory context.
 *
 * yytxt is the original token text; we need this to check for quoting,
 * so that later checks for unreserved keywords work properly.
 *
 * If recognized as a variable, fill in *wdatum and return true;
 * if not recognized, fill in *word and return false.
 * (Note: those two pointers actually point to members of the same union,
 * but for notational reasons we pass them separately.)
 * ----------
 */
bool
pltsql_parse_word(char *word1, const char *yytxt,
				  PLwdatum *wdatum, PLword *word)
{
	PLtsql_nsitem *ns;

	/*
	 * We should do nothing in DECLARE sections.  In SQL expressions, there's
	 * no need to do anything either --- lookup will happen when the
	 * expression is compiled.
	 */

	/*
	 * Update for table variables: because we need to replace the table
	 * variables by their underlying tables' names in the expression, we need
	 * to be able to lookup in IDENTIFIER_LOOKUP_EXPR as well.
	 */
	if (pltsql_IdentifierLookup == IDENTIFIER_LOOKUP_NORMAL ||
		pltsql_IdentifierLookup == IDENTIFIER_LOOKUP_EXPR)
	{
		/*
		 * Do a lookup in the current namespace stack
		 */
		ns = pltsql_ns_lookup(pltsql_ns_top(), false,
							  word1, NULL, NULL,
							  NULL);

		if (ns != NULL)
		{
			switch (ns->itemtype)
			{
				case PLTSQL_NSTYPE_VAR:
				case PLTSQL_NSTYPE_REC:
				case PLTSQL_NSTYPE_TBL:
					wdatum->datum = pltsql_Datums[ns->itemno];
					wdatum->ident = word1;
					wdatum->quoted = (yytxt[0] == '"') || (yytxt[0] == '[');
					wdatum->idents = NIL;
					return true;

				default:
					/* pltsql_ns_lookup should never return anything else */
					elog(ERROR, "unrecognized pltsql itemtype: %d",
						 ns->itemtype);
			}
		}
	}

	/*
	 * Nothing found - up to now it's a word without any special meaning for
	 * us.
	 */
	word->ident = word1;
	word->quoted = (yytxt[0] == '"') || (yytxt[0] == '[');
	return false;
}


/* ----------
 * pltsql_parse_dblword		Same lookup for two words
 *					separated by a dot.
 * ----------
 */
bool
pltsql_parse_dblword(char *word1, char *word2,
					 PLwdatum *wdatum, PLcword *cword)
{
	PLtsql_nsitem *ns;
	List	   *idents;
	int			nnames;

	idents = list_make2(makeString(word1),
						makeString(word2));

	/*
	 * We should do nothing in DECLARE sections.  In SQL expressions, we
	 * really only need to make sure that RECFIELD datums are created when
	 * needed.
	 */
	if (pltsql_IdentifierLookup != IDENTIFIER_LOOKUP_DECLARE)
	{
		/*
		 * Do a lookup in the current namespace stack
		 */
		ns = pltsql_ns_lookup(pltsql_ns_top(), false,
							  word1, word2, NULL,
							  &nnames);
		if (ns != NULL)
		{
			switch (ns->itemtype)
			{
				case PLTSQL_NSTYPE_VAR:
					/* Block-qualified reference to scalar variable. */
					wdatum->datum = pltsql_Datums[ns->itemno];
					wdatum->ident = NULL;
					wdatum->quoted = false; /* not used */
					wdatum->idents = idents;
					return true;

				case PLTSQL_NSTYPE_REC:
					if (nnames == 1)
					{
						/*
						 * First word is a record name, so second word could
						 * be a field in this record.  We build a RECFIELD
						 * datum whether it is or not --- any error will be
						 * detected later.
						 */
						PLtsql_rec *rec;
						PLtsql_recfield *new;

						rec = (PLtsql_rec *) (pltsql_Datums[ns->itemno]);
						new = pltsql_build_recfield(rec, word2);

						wdatum->datum = (PLtsql_datum *) new;
					}
					else
					{
						/* Block-qualified reference to record variable. */
						wdatum->datum = pltsql_Datums[ns->itemno];
					}
					wdatum->ident = NULL;
					wdatum->quoted = false; /* not used */
					wdatum->idents = idents;
					return true;

				default:
					break;
			}
		}
	}

	/* Nothing found */
	cword->idents = idents;
	return false;
}


/* ----------
 * pltsql_parse_tripword		Same lookup for three words
 *					separated by dots.
 * ----------
 */
bool
pltsql_parse_tripword(char *word1, char *word2, char *word3,
					  PLwdatum *wdatum, PLcword *cword)
{
	PLtsql_nsitem *ns;
	List	   *idents;
	int			nnames;

	idents = list_make3(makeString(word1),
						makeString(word2),
						makeString(word3));

	/*
	 * We should do nothing in DECLARE sections.  In SQL expressions, we
	 * really only need to make sure that RECFIELD datums are created when
	 * needed.
	 */
	if (pltsql_IdentifierLookup != IDENTIFIER_LOOKUP_DECLARE)
	{
		/*
		 * Do a lookup in the current namespace stack. Must find a qualified
		 * reference, else ignore.
		 */
		ns = pltsql_ns_lookup(pltsql_ns_top(), false,
							  word1, word2, word3,
							  &nnames);
		if (ns != NULL && nnames == 2)
		{
			switch (ns->itemtype)
			{
				case PLTSQL_NSTYPE_REC:
					{
						/*
						 * words 1/2 are a record name, so third word could be
						 * a field in this record.
						 */
						PLtsql_rec *rec;
						PLtsql_recfield *new;

						rec = (PLtsql_rec *) (pltsql_Datums[ns->itemno]);
						new = pltsql_build_recfield(rec, word3);

						wdatum->datum = (PLtsql_datum *) new;
						wdatum->ident = NULL;
						wdatum->quoted = false; /* not used */
						wdatum->idents = idents;
						return true;
					}

				default:
					break;
			}
		}
	}

	/* Nothing found */
	cword->idents = idents;
	return false;
}


/* ----------
 * pltsql_parse_wordtype	The scanner found word%TYPE. word can be
 *				a variable name or a basetype.
 *
 * Returns datatype struct, or NULL if no match found for word.
 * ----------
 */
PLtsql_type *
pltsql_parse_wordtype(char *ident)
{
	PLtsql_type *dtype;
	PLtsql_nsitem *nse;
	TypeName   *typeName;
	HeapTuple	typeTup;

	/*
	 * Do a lookup in the current namespace stack
	 */
	nse = pltsql_ns_lookup(pltsql_ns_top(), false,
						   ident, NULL, NULL,
						   NULL);

	if (nse != NULL)
	{
		switch (nse->itemtype)
		{
			case PLTSQL_NSTYPE_VAR:
				return ((PLtsql_var *) (pltsql_Datums[nse->itemno]))->datatype;

				/* XXX perhaps allow REC/ROW here? */

			default:
				return NULL;
		}
	}

	/*
	 * Word wasn't found in the namespace stack. Try to find a data type with
	 * that name, but ignore shell types and complex types.
	 */
	typeName = makeTypeName(ident);
	typeTup = LookupTypeName(NULL, typeName, NULL, false);
	if (typeTup)
	{
		Form_pg_type typeStruct = (Form_pg_type) GETSTRUCT(typeTup);

		if (!typeStruct->typisdefined ||
			typeStruct->typrelid != InvalidOid)
		{
			ReleaseSysCache(typeTup);
			return NULL;
		}

		dtype = build_datatype(typeTup, -1,
							   pltsql_curr_compile->fn_input_collation,
							   typeName);

		ReleaseSysCache(typeTup);
		return dtype;
	}

	/*
	 * Nothing found - up to now it's a word without any special meaning for
	 * us.
	 */
	return NULL;
}


/* ----------
 * pltsql_parse_cwordtype		Same lookup for compositeword%TYPE
 * ----------
 */
PLtsql_type *
pltsql_parse_cwordtype(List *idents)
{
	PLtsql_type *dtype = NULL;
	PLtsql_nsitem *nse;
	const char *fldname;
	Oid			classOid;
	HeapTuple	classtup = NULL;
	HeapTuple	attrtup = NULL;
	HeapTuple	typetup = NULL;
	Form_pg_class classStruct;
	Form_pg_attribute attrStruct;
	MemoryContext oldCxt;

	/* Avoid memory leaks in the long-term function context */
	oldCxt = MemoryContextSwitchTo(pltsql_compile_tmp_cxt);

	if (list_length(idents) == 2)
	{
		/*
		 * Do a lookup in the current namespace stack. We don't need to check
		 * number of names matched, because we will only consider scalar
		 * variables.
		 */
		nse = pltsql_ns_lookup(pltsql_ns_top(), false,
							   strVal(linitial(idents)),
							   strVal(lsecond(idents)),
							   NULL,
							   NULL);

		if (nse != NULL && nse->itemtype == PLTSQL_NSTYPE_VAR)
		{
			dtype = ((PLtsql_var *) (pltsql_Datums[nse->itemno]))->datatype;
			goto done;
		}

		/*
		 * First word could also be a table name
		 */
		classOid = RelnameGetRelid(strVal(linitial(idents)));
		if (!OidIsValid(classOid))
			goto done;
		fldname = strVal(lsecond(idents));
	}
	else if (list_length(idents) == 3)
	{
		RangeVar   *relvar;

		relvar = makeRangeVar(strVal(linitial(idents)),
							  strVal(lsecond(idents)),
							  -1);
		/* Can't lock relation - we might not have privileges. */
		classOid = RangeVarGetRelid(relvar, NoLock, true);
		if (!OidIsValid(classOid))
			goto done;
		fldname = strVal(lthird(idents));
	}
	else
		goto done;

	classtup = SearchSysCache1(RELOID, ObjectIdGetDatum(classOid));
	if (!HeapTupleIsValid(classtup))
		goto done;
	classStruct = (Form_pg_class) GETSTRUCT(classtup);

	/*
	 * It must be a relation, sequence, view, materialized view, composite
	 * type, or foreign table
	 */
	if (classStruct->relkind != RELKIND_RELATION &&
		classStruct->relkind != RELKIND_SEQUENCE &&
		classStruct->relkind != RELKIND_VIEW &&
		classStruct->relkind != RELKIND_MATVIEW &&
		classStruct->relkind != RELKIND_COMPOSITE_TYPE &&
		classStruct->relkind != RELKIND_FOREIGN_TABLE &&
		classStruct->relkind != RELKIND_PARTITIONED_TABLE)
		goto done;

	/*
	 * Fetch the named table field and its type
	 */
	attrtup = SearchSysCacheAttName(classOid, fldname);
	if (!HeapTupleIsValid(attrtup))
		goto done;
	attrStruct = (Form_pg_attribute) GETSTRUCT(attrtup);

	typetup = SearchSysCache1(TYPEOID,
							  ObjectIdGetDatum(attrStruct->atttypid));
	if (!HeapTupleIsValid(typetup))
		elog(ERROR, "cache lookup failed for type %u", attrStruct->atttypid);

	/*
	 * Found that - build a compiler type struct in the caller's cxt and
	 * return it.  Note that we treat the type as being found-by-OID; no
	 * attempt to re-look-up the type name will happen during invalidations.
	 */
	MemoryContextSwitchTo(oldCxt);
	dtype = build_datatype(typetup,
						   attrStruct->atttypmod,
						   attrStruct->attcollation,
						   NULL);
	MemoryContextSwitchTo(pltsql_compile_tmp_cxt);

done:
	if (HeapTupleIsValid(classtup))
		ReleaseSysCache(classtup);
	if (HeapTupleIsValid(attrtup))
		ReleaseSysCache(attrtup);
	if (HeapTupleIsValid(typetup))
		ReleaseSysCache(typetup);

	MemoryContextSwitchTo(oldCxt);
	return dtype;
}

/* ----------
 * pltsql_parse_wordrowtype		Scanner found word%ROWTYPE.
 *					So word must be a table name.
 * ----------
 */
PLtsql_type *
pltsql_parse_wordrowtype(char *ident)
{
	Oid			classOid;

	/*
	 * Look up the relation.  Note that because relation rowtypes have the
	 * same names as their relations, this could be handled as a type lookup
	 * equally well; we use the relation lookup code path only because the
	 * errors thrown here have traditionally referred to relations not types.
	 * But we'll make a TypeName in case we have to do re-look-up of the type.
	 */
	classOid = RelnameGetRelid(ident);
	if (!OidIsValid(classOid))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_TABLE),
				 errmsg("relation \"%s\" does not exist", ident)));

	/* Build and return the row type struct */
	return pltsql_build_datatype(get_rel_type_id(classOid), -1, InvalidOid,
								 makeTypeName(ident));
}

/* ----------
 * pltsql_parse_cwordrowtype		Scanner found compositeword%ROWTYPE.
 *			So word must be a namespace qualified table name.
 * ----------
 */
PLtsql_type *
pltsql_parse_cwordrowtype(List *idents)
{
	Oid			classOid;
	RangeVar   *relvar;
	MemoryContext oldCxt;

	/*
	 * As above, this is a relation lookup but could be a type lookup if we
	 * weren't being backwards-compatible about error wording.
	 */
	if (list_length(idents) != 2)
		return NULL;

	/* Avoid memory leaks in long-term function context */
	oldCxt = MemoryContextSwitchTo(pltsql_compile_tmp_cxt);

	/* Look up relation name.  Can't lock it - we might not have privileges. */
	relvar = makeRangeVar(strVal(linitial(idents)),
						  strVal(lsecond(idents)),
						  -1);
	classOid = RangeVarGetRelid(relvar, NoLock, false);

	MemoryContextSwitchTo(oldCxt);

	/* Build and return the row type struct */
	return pltsql_build_datatype(get_rel_type_id(classOid), -1, InvalidOid,
								 makeTypeNameFromNameList(idents));
}

/*
 * pltsql_build_variable - build a datum-array entry of a given
 * datatype
 *
 * The returned struct may be a PLtsql_var or PLtsql_rec
 * depending on the given datatype, and is allocated via
 * palloc.  The struct is automatically added to the current datum
 * array, and optionally to the current namespace.
 */
PLtsql_variable *
pltsql_build_variable(const char *refname, int lineno, PLtsql_type *dtype,
					  bool add2namespace)
{
	PLtsql_variable *result;

	switch (dtype->ttype)
	{
		case PLTSQL_TTYPE_SCALAR:
			{
				/* Ordinary scalar datatype */
				PLtsql_var *var;

				var = palloc0(sizeof(PLtsql_var));
				var->dtype = PLTSQL_DTYPE_VAR;
				var->refname = pstrdup(refname);
				var->lineno = lineno;
				var->datatype = dtype;
				/* other fields are left as 0, might be changed by caller */

				/* preset to NULL */
				var->value = 0;
				var->isnull = true;
				var->freeval = false;

				pltsql_adddatum((PLtsql_datum *) var);
				if (add2namespace)
					pltsql_ns_additem(PLTSQL_NSTYPE_VAR,
									  var->dno,
									  refname);
				result = (PLtsql_variable *) var;

				break;
			}
		case PLTSQL_TTYPE_REC:
			{
				/* Composite type -- build a record variable */
				PLtsql_rec *rec;

				rec = pltsql_build_record(refname, lineno,
										  dtype, dtype->typoid,
										  add2namespace);
				result = (PLtsql_variable *) rec;

				break;
			}
		case PLTSQL_TTYPE_PSEUDO:
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("variable \"%s\" has pseudo-type %s",
							refname, format_type_be(dtype->typoid))));
			result = NULL;		/* keep compiler quiet */

			break;
		case PLTSQL_TTYPE_TBL:
			{
				/* Table type -- build a table variable */
				PLtsql_tbl *tbl;

				tbl = pltsql_build_table(refname, lineno,
										 dtype, dtype->typoid,
										 add2namespace);
				result = (PLtsql_variable *) tbl;

				break;
			}
		default:
			elog(ERROR, "unrecognized ttype: %d", dtype->ttype);
			result = NULL;		/* keep compiler quiet */

			break;
	}

	return result;
}

/*
 * Build empty named record variable, and optionally add it to namespace
 */
PLtsql_rec *
pltsql_build_record(const char *refname, int lineno,
					PLtsql_type *dtype, Oid rectypeid,
					bool add2namespace)
{
	PLtsql_rec *rec;

	rec = palloc0(sizeof(PLtsql_rec));
	rec->dtype = PLTSQL_DTYPE_REC;
	rec->refname = pstrdup(refname);
	rec->lineno = lineno;
	/* other fields are left as 0, might be changed by caller */
	rec->datatype = dtype;
	rec->rectypeid = rectypeid;
	rec->firstfield = -1;
	rec->erh = NULL;
	pltsql_adddatum((PLtsql_datum *) rec);
	if (add2namespace)
		pltsql_ns_additem(PLTSQL_NSTYPE_REC, rec->dno, rec->refname);

	return rec;
}

/*
 * Build empty named table variable, and optionally add it to namespace
 */
PLtsql_tbl *
pltsql_build_table(const char *refname, int lineno,
				   PLtsql_type *dtype, Oid tbltypeid,
				   bool add2namespace)
{
	PLtsql_tbl *tbl;

	tbl = palloc0(sizeof(PLtsql_tbl));
	tbl->dtype = PLTSQL_DTYPE_TBL;
	tbl->refname = pstrdup(refname);
	tbl->lineno = lineno;
	/* other fields are left as 0, might be changed by caller */
	tbl->datatype = dtype;
	tbl->tbltypeid = tbltypeid;
	tbl->tblname = NULL;
	tbl->need_drop = false;
	pltsql_adddatum((PLtsql_datum *) tbl);
	if (add2namespace)
		pltsql_ns_additem(PLTSQL_NSTYPE_TBL, tbl->dno, tbl->refname);

	return tbl;
}

/*
 * Build a row-variable data structure given the component variables.
 * Include a rowtupdesc, since we will need to materialize the row result.
 */
static PLtsql_row *
build_row_from_vars(PLtsql_variable **vars, int numvars)
{
	PLtsql_row *row;
	int			i;

	row = palloc0(sizeof(PLtsql_row));
	row->dtype = PLTSQL_DTYPE_ROW;
	row->refname = "(unnamed row)";
	row->lineno = -1;
	row->rowtupdesc = CreateTemplateTupleDesc(numvars);
	row->nfields = numvars;
	row->fieldnames = palloc(numvars * sizeof(char *));
	row->varnos = palloc(numvars * sizeof(int));

	for (i = 0; i < numvars; i++)
	{
		PLtsql_variable *var = vars[i];
		Oid			typoid;
		int32		typmod;
		Oid			typcoll;

		/* Member vars of a row should never be const */
		Assert(!var->isconst);

		switch (var->dtype)
		{
			case PLTSQL_DTYPE_VAR:
			case PLTSQL_DTYPE_PROMISE:
				typoid = ((PLtsql_var *) var)->datatype->typoid;
				typmod = ((PLtsql_var *) var)->datatype->atttypmod;
				typcoll = ((PLtsql_var *) var)->datatype->collation;
				break;

			case PLTSQL_DTYPE_REC:
				/* shouldn't need to revalidate rectypeid already... */
				typoid = ((PLtsql_rec *) var)->rectypeid;
				typmod = -1;	/* don't know typmod, if it's used at all */
				typcoll = InvalidOid;	/* composite types have no collation */
				break;

			default:
				elog(ERROR, "unrecognized dtype: %d", var->dtype);
				typoid = InvalidOid;	/* keep compiler quiet */
				typmod = 0;
				typcoll = InvalidOid;
				break;
		}

		row->fieldnames[i] = var->refname;
		row->varnos[i] = var->dno;

		TupleDescInitEntry(row->rowtupdesc, i + 1,
						   var->refname,
						   typoid, typmod,
						   0);
		TupleDescInitEntryCollation(row->rowtupdesc, i + 1, typcoll);
	}

	return row;
}

/*
 * Build a RECFIELD datum for the named field of the specified record variable
 *
 * If there's already such a datum, just return it; we don't need duplicates.
 */
PLtsql_recfield *
pltsql_build_recfield(PLtsql_rec *rec, const char *fldname)
{
	PLtsql_recfield *recfield;
	int			i;

	/* search for an existing datum referencing this field */
	i = rec->firstfield;
	while (i >= 0)
	{
		PLtsql_recfield *fld = (PLtsql_recfield *) pltsql_Datums[i];

		Assert(fld->dtype == PLTSQL_DTYPE_RECFIELD &&
			   fld->recparentno == rec->dno);
		if (strcmp(fld->fieldname, fldname) == 0)
			return fld;
		i = fld->nextfield;
	}

	/* nope, so make a new one */
	recfield = palloc0(sizeof(PLtsql_recfield));
	recfield->dtype = PLTSQL_DTYPE_RECFIELD;
	recfield->fieldname = pstrdup(fldname);
	recfield->recparentno = rec->dno;
	recfield->rectupledescid = INVALID_TUPLEDESC_IDENTIFIER;

	pltsql_adddatum((PLtsql_datum *) recfield);

	/* now we can link it into the parent's chain */
	recfield->nextfield = rec->firstfield;
	rec->firstfield = recfield->dno;

	return recfield;
}

/*
 * pltsql_build_datatype
 *		Build PLtsql_type struct given type OID, typmod, collation,
 *		and type's parsed name.
 *
 * If collation is not InvalidOid then it overrides the type's default
 * collation.  But collation is ignored if the datatype is non-collatable.
 *
 * origtypname is the parsed form of what the user wrote as the type name.
 * It can be NULL if the type could not be a composite type, or if it was
 * identified by OID to begin with (e.g., it's a function argument type).
 */
PLtsql_type *
pltsql_build_datatype(Oid typeOid, int32 typmod,
					  Oid collation, TypeName *origtypname)
{
	HeapTuple	typeTup;
	PLtsql_type *typ;

	typeTup = SearchSysCache1(TYPEOID, ObjectIdGetDatum(typeOid));
	if (!HeapTupleIsValid(typeTup))
		elog(ERROR, "cache lookup failed for type %u", typeOid);

	typ = build_datatype(typeTup, typmod, collation, origtypname);

	/* Check whether datatype is collatable, if yes then assign database level collation to it */
	if (OidIsValid(typ->collation))
		typ->collation = tsql_get_database_or_server_collation_oid_internal(false);

	ReleaseSysCache(typeTup);

	return typ;
}

/*
 * Utility subroutine to make a PLtsql_type struct given a pg_type entry
 * and additional details (see comments for pltsql_build_datatype).
 */
static PLtsql_type *
build_datatype(HeapTuple typeTup, int32 typmod,
			   Oid collation, TypeName *origtypname)
{
	Form_pg_type typeStruct = (Form_pg_type) GETSTRUCT(typeTup);
	PLtsql_type *typ;

	if (!typeStruct->typisdefined)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("type \"%s\" is only a shell",
						NameStr(typeStruct->typname))));

	typ = (PLtsql_type *) palloc(sizeof(PLtsql_type));

	typ->typname = pstrdup(NameStr(typeStruct->typname));
	typ->typoid = typeStruct->oid;
	switch (typeStruct->typtype)
	{
		case TYPTYPE_BASE:
		case TYPTYPE_ENUM:
		case TYPTYPE_RANGE:
			typ->ttype = PLTSQL_TTYPE_SCALAR;
			break;
		case TYPTYPE_COMPOSITE:
			typ->ttype = PLTSQL_TTYPE_TBL;
			break;
		case TYPTYPE_DOMAIN:
			if (type_is_rowtype(typeStruct->typbasetype))
				typ->ttype = PLTSQL_TTYPE_REC;
			else
				typ->ttype = PLTSQL_TTYPE_SCALAR;
			break;
		case TYPTYPE_PSEUDO:
			if (typ->typoid == RECORDOID)
				typ->ttype = PLTSQL_TTYPE_REC;
			else
				typ->ttype = PLTSQL_TTYPE_PSEUDO;
			break;
		default:
			elog(ERROR, "unrecognized typtype: %d",
				 (int) typeStruct->typtype);
			break;
	}
	typ->typlen = typeStruct->typlen;
	typ->typbyval = typeStruct->typbyval;
	typ->typtype = typeStruct->typtype;
	typ->collation = typeStruct->typcollation;
	if (OidIsValid(collation) && OidIsValid(typ->collation))
		typ->collation = collation;
	/* Detect if type is true array, or domain thereof */
	/* NB: this is only used to decide whether to apply expand_array */
	if (typeStruct->typtype == TYPTYPE_BASE)
	{
		/*
		 * This test should include what get_element_type() checks.  We also
		 * disallow non-toastable array types (i.e. oidvector and int2vector).
		 */
		typ->typisarray = (typeStruct->typlen == -1 &&
						   OidIsValid(typeStruct->typelem) &&
						   typeStruct->typstorage != 'p');
	}
	else if (typeStruct->typtype == TYPTYPE_DOMAIN)
	{
		/* we can short-circuit looking up base types if it's not varlena */
		typ->typisarray = (typeStruct->typlen == -1 &&
						   typeStruct->typstorage != 'p' &&
						   OidIsValid(get_base_element_type(typeStruct->typbasetype)));
	}
	else
		typ->typisarray = false;
	typ->atttypmod = typmod;
	typ->coldef = NULL;

	/*
	 * If it's a named composite type (or domain over one), find the typcache
	 * entry and record the current tupdesc ID, so we can detect changes
	 * (including drops).  We don't currently support on-the-fly replacement
	 * of non-composite types, else we might want to do this for them too.
	 */
	if ((typ->ttype == PLTSQL_TTYPE_REC || typ->ttype == PLTSQL_TTYPE_TBL) &&
		typ->typoid != RECORDOID)
	{
		TypeCacheEntry *typentry;

		typentry = lookup_type_cache(typ->typoid,
									 TYPECACHE_TUPDESC |
									 TYPECACHE_DOMAIN_BASE_INFO);
		if (typentry->typtype == TYPTYPE_DOMAIN)
			typentry = lookup_type_cache(typentry->domainBaseType,
										 TYPECACHE_TUPDESC);
		if (typentry->tupDesc == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("type %s is not composite",
							format_type_be(typ->typoid))));

		typ->origtypname = origtypname;
		typ->tcache = typentry;
		typ->tupdesc_id = typentry->tupDesc_identifier;
	}
	else
	{
		typ->origtypname = NULL;
		typ->tcache = NULL;
		typ->tupdesc_id = 0;
	}

	return typ;
}

/* Create a simple table type with a column definition list string */
PLtsql_type *
pltsql_build_table_datatype_coldef(const char *coldef)
{
	PLtsql_type *typ;

	typ = (PLtsql_type *) palloc(sizeof(PLtsql_type));
	typ->typname = NULL;
	typ->typoid = InvalidOid;
	typ->ttype = PLTSQL_TTYPE_TBL;
	typ->typlen = -1;
	typ->typbyval = false;
	typ->typtype = TYPTYPE_COMPOSITE;
	typ->collation = InvalidOid;
	typ->typisarray = false;
	typ->atttypmod = -1;
	typ->coldef = pstrdup(coldef);
	typ->origtypname = NULL;
	typ->tcache = NULL;
	typ->tupdesc_id = 0;

	return typ;
}

/*
 *	pltsql_recognize_err_condition
 *		Check condition name and translate it to SQLSTATE.
 *
 * Note: there are some cases where the same condition name has multiple
 * entries in the table.  We arbitrarily return the first match.
 */
int
pltsql_recognize_err_condition(const char *condname, bool allow_sqlstate)
{
	int			i;

	if (allow_sqlstate)
	{
		if (strlen(condname) == 5 &&
			strspn(condname, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ") == 5)
			return MAKE_SQLSTATE(condname[0],
								 condname[1],
								 condname[2],
								 condname[3],
								 condname[4]);
	}

	for (i = 0; exception_label_map[i].label != NULL; i++)
	{
		if (strcmp(condname, exception_label_map[i].label) == 0)
			return exception_label_map[i].sqlerrstate;
	}

	ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_OBJECT),
			 errmsg("unrecognized exception condition \"%s\"",
					condname)));
	return 0;					/* keep compiler quiet */
}

/*
 * pltsql_parse_err_condition
 *		Generate PLtsql_condition entry(s) for an exception condition name
 *
 * This has to be able to return a list because there are some duplicate
 * names in the table of error code names.
 */
PLtsql_condition *
pltsql_parse_err_condition(char *condname)
{
	int			i;
	PLtsql_condition *new;
	PLtsql_condition *prev;

	/*
	 * XXX Eventually we will want to look for user-defined exception names
	 * here.
	 */

	/*
	 * OTHERS is represented as code 0 (which would map to '00000', but we
	 * have no need to represent that as an exception condition).
	 */
	if (strcmp(condname, "others") == 0)
	{
		new = palloc(sizeof(PLtsql_condition));
		new->sqlerrstate = 0;
		new->condname = condname;
		new->next = NULL;
		return new;
	}

	prev = NULL;
	for (i = 0; exception_label_map[i].label != NULL; i++)
	{
		if (strcmp(condname, exception_label_map[i].label) == 0)
		{
			new = palloc(sizeof(PLtsql_condition));
			new->sqlerrstate = exception_label_map[i].sqlerrstate;
			new->condname = condname;
			new->next = prev;
			prev = new;
		}
	}

	if (!prev)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("unrecognized exception condition \"%s\"",
						condname)));

	return prev;
}

/* ----------
 * pltsql_start_datums			Initialize datum list at compile startup.
 * ----------
 */
static void
pltsql_start_datums(void)
{
	datums_alloc = 128;
	pltsql_nDatums = 0;
	/* This is short-lived, so needn't allocate in function's cxt */
	pltsql_Datums = MemoryContextAlloc(pltsql_compile_tmp_cxt,
									   sizeof(PLtsql_datum *) * datums_alloc);
	/* datums_last tracks what's been seen by pltsql_add_initdatums() */
	datums_last = 0;
}

/* ----------
 * pltsql_adddatum			Add a variable, record or row
 *					to the compiler's datum list.
 * ----------
 */
void
pltsql_adddatum(PLtsql_datum *newdatum)
{
	if (pltsql_nDatums == datums_alloc)
	{
		datums_alloc *= 2;
		pltsql_Datums = repalloc(pltsql_Datums, sizeof(PLtsql_datum *) * datums_alloc);
	}

	newdatum->dno = pltsql_nDatums;
	pltsql_Datums[pltsql_nDatums++] = newdatum;
}

/* ----------
 * pltsql_finish_datums	Copy completed datum info into function struct.
 * ----------
 */
static void
pltsql_finish_datums(PLtsql_function *function)
{
	Size		copiable_size = 0;
	int			i;

	function->ndatums = pltsql_nDatums;
	function->datums = palloc(sizeof(PLtsql_datum *) * pltsql_nDatums);
	for (i = 0; i < pltsql_nDatums; i++)
	{
		function->datums[i] = pltsql_Datums[i];

		/* This must agree with copy_pltsql_datums on what is copiable */
		switch (function->datums[i]->dtype)
		{
			case PLTSQL_DTYPE_VAR:
			case PLTSQL_DTYPE_PROMISE:
				copiable_size += MAXALIGN(sizeof(PLtsql_var));
				break;
			case PLTSQL_DTYPE_REC:
				copiable_size += MAXALIGN(sizeof(PLtsql_rec));
				break;
			case PLTSQL_DTYPE_TBL:
				copiable_size += MAXALIGN(sizeof(PLtsql_tbl));
				function->table_varnos = lappend_int(function->table_varnos, function->datums[i]->dno);
				break;
			default:
				break;
		}
	}
	function->copiable_size = copiable_size;
}


/* ----------
 * pltsql_add_initdatums		Make an array of the datum numbers of
 *					all the initializable datums created since the last call
 *					to this function.
 *
 * If varnos is NULL, we just forget any datum entries created since the
 * last call.
 *
 * This is used around a DECLARE section to create a list of the datums
 * that have to be initialized at block entry.  Note that datums can also
 * be created elsewhere than DECLARE, eg by a FOR-loop, but it is then
 * the responsibility of special-purpose code to initialize them.
 * ----------
 */
int
pltsql_add_initdatums(int **varnos)
{
	int			i;
	int			n = 0;

	/*
	 * The set of dtypes recognized here must match what exec_stmt_block()
	 * cares about (re)initializing at block entry.
	 */
	for (i = datums_last; i < pltsql_nDatums; i++)
	{
		switch (pltsql_Datums[i]->dtype)
		{
			case PLTSQL_DTYPE_VAR:
			case PLTSQL_DTYPE_REC:
				n++;
				break;

			default:
				break;
		}
	}

	if (varnos != NULL)
	{
		if (n > 0)
		{
			*varnos = (int *) palloc(sizeof(int) * n);

			n = 0;
			for (i = datums_last; i < pltsql_nDatums; i++)
			{
				switch (pltsql_Datums[i]->dtype)
				{
					case PLTSQL_DTYPE_VAR:
					case PLTSQL_DTYPE_REC:
						(*varnos)[n++] = pltsql_Datums[i]->dno;

					default:
						break;
				}
			}
		}
		else
			*varnos = NULL;
	}

	datums_last = pltsql_nDatums;
	return n;
}


/*
 * Compute the hashkey for a given function invocation
 *
 * The hashkey is returned into the caller-provided storage at *hashkey.
 */
static void
compute_function_hashkey(FunctionCallInfo fcinfo,
						 Form_pg_proc procStruct,
						 PLtsql_func_hashkey *hashkey,
						 bool forValidator)
{
	/* Make sure any unused bytes of the struct are zero */
	MemSet(hashkey, 0, sizeof(PLtsql_func_hashkey));

	/* get function OID */
	hashkey->funcOid = fcinfo->flinfo->fn_oid;

	/* get call context */
	hashkey->isTrigger = CALLED_AS_TRIGGER(fcinfo);
	hashkey->isEventTrigger = CALLED_AS_EVENT_TRIGGER(fcinfo);

	/*
	 * If DML trigger, include trigger's OID in the hash, so that each trigger
	 * usage gets a different hash entry, allowing for e.g. different relation
	 * rowtypes or transition table names.  In validation mode we do not know
	 * what relation or transition table names are intended to be used, so we
	 * leave trigOid zero; the hash entry built in this case will never be
	 * used for any actual calls.
	 *
	 * We don't currently need to distinguish different event trigger usages
	 * in the same way, since the special parameter variables don't vary in
	 * type in that case.
	 */
	if (hashkey->isTrigger && !forValidator)
	{
		TriggerData *trigdata = (TriggerData *) fcinfo->context;

		hashkey->trigOid = trigdata->tg_trigger->tgoid;
	}

	/* get input collation, if known */
	hashkey->inputCollation = fcinfo->fncollation;

	if (procStruct->pronargs > 0)
	{
		/* get the argument types */
		memcpy(hashkey->argtypes, procStruct->proargtypes.values,
			   procStruct->pronargs * sizeof(Oid));

		/* resolve any polymorphic argument types */
		pltsql_resolve_polymorphic_argtypes(procStruct->pronargs,
											hashkey->argtypes,
											NULL,
											fcinfo->flinfo->fn_expr,
											forValidator,
											NameStr(procStruct->proname));
	}
}

/*
 * This is the same as the standard resolve_polymorphic_argtypes() function,
 * but with a special case for validation: assume that polymorphic arguments
 * are integer, integer-array or integer-range.  Also, we go ahead and report
 * the error if we can't resolve the types.
 */
static void
pltsql_resolve_polymorphic_argtypes(int numargs,
									Oid *argtypes, char *argmodes,
									Node *call_expr, bool forValidator,
									const char *proname)
{
	int			i;

	if (!forValidator)
	{
		/* normal case, pass to standard routine */
		if (!resolve_polymorphic_argtypes(numargs, argtypes, argmodes,
										  call_expr))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("could not determine actual argument "
							"type for polymorphic function \"%s\"",
							proname)));
	}
	else
	{
		/* special validation case */
		for (i = 0; i < numargs; i++)
		{
			switch (argtypes[i])
			{
				case ANYELEMENTOID:
				case ANYNONARRAYOID:
				case ANYENUMOID:	/* XXX dubious */
					argtypes[i] = INT4OID;
					break;
				case ANYARRAYOID:
					argtypes[i] = INT4ARRAYOID;
					break;
				case ANYRANGEOID:
					argtypes[i] = INT4RANGEOID;
					break;
				default:
					break;
			}
		}
	}
}

/*
 * delete_function - clean up as much as possible of a stale function cache
 *
 * We can't release the PLtsql_function struct itself, because of the
 * possibility that there are fn_extra pointers to it.  We can release
 * the subsidiary storage, but only if there are no active evaluations
 * in progress.  Otherwise we'll just leak that storage.  Since the
 * case would only occur if a pg_proc update is detected during a nested
 * recursive call on the function, a leak seems acceptable.
 *
 * Note that this can be called more than once if there are multiple fn_extra
 * pointers to the same function cache.  Hence be careful not to do things
 * twice.
 */
static void
delete_function(PLtsql_function *func)
{
	/* remove function from hash table (might be done already) */
	pltsql_HashTableDelete(func);

	/* release the function's storage if safe and not done already */
	if (func->use_count == 0)
		pltsql_free_function_memory(func);
}

/* exported so we can call it from pltsql_init() */
void
pltsql_HashTableInit(void)
{
	HASHCTL		ctl;

	/* don't allow double-initialization */
	Assert(pltsql_HashTable == NULL);

	memset(&ctl, 0, sizeof(ctl));
	ctl.keysize = sizeof(PLtsql_func_hashkey);
	ctl.entrysize = sizeof(pltsql_HashEnt);
	pltsql_HashTable = hash_create("PLtsql function hash",
								   FUNCS_PER_USER,
								   &ctl,
								   HASH_ELEM | HASH_BLOBS);
}

static PLtsql_function *
pltsql_HashTableLookup(PLtsql_func_hashkey *func_key)
{
	pltsql_HashEnt *hentry;

	hentry = (pltsql_HashEnt *) hash_search(pltsql_HashTable,
											(void *) func_key,
											HASH_FIND,
											NULL);
	if (hentry)
		return hentry->function;
	else
		return NULL;
}

static void
pltsql_HashTableInsert(PLtsql_function *function,
					   PLtsql_func_hashkey *func_key)
{
	pltsql_HashEnt *hentry;
	bool		found;

	hentry = (pltsql_HashEnt *) hash_search(pltsql_HashTable,
											(void *) func_key,
											HASH_ENTER,
											&found);
	if (found)
		elog(WARNING, "trying to insert a function that already exists");

	hentry->function = function;
	/* prepare back link from function to hashtable key */
	function->fn_hashkey = &hentry->key;
}

static void
pltsql_HashTableDelete(PLtsql_function *function)
{
	pltsql_HashEnt *hentry;

	/* do nothing if not in table */
	if (function->fn_hashkey == NULL)
		return;

	hentry = (pltsql_HashEnt *) hash_search(pltsql_HashTable,
											(void *) function->fn_hashkey,
											HASH_REMOVE,
											NULL);
	if (hentry == NULL)
		elog(WARNING, "trying to delete function that does not exist");

	/* remove back link, which no longer points to allocated storage */
	function->fn_hashkey = NULL;
}

/* helper function for compiled batch */

int			cache_compiled_batch(PLtsql_function *func);
PLtsql_function *find_cached_batch(int handle);
void		delete_cached_batch(int handle);

/* helper function to reset cache incase reset connection takes place */
void		reset_cached_batch(void);

PLtsql_function *
find_cached_batch(int handle)
{
	PLtsql_func_hashkey hashkey;
	PLtsql_function *func;

	MemSet(&hashkey, 0, sizeof(PLtsql_func_hashkey));
	/* use upper 32bit for funcOid */
	hashkey.funcOid = ((long) handle) << 32;
	hashkey.isTrigger = false;
	hashkey.isEventTrigger = false;
	hashkey.inputCollation = -1;

	func = pltsql_HashTableLookup(&hashkey);

	return func;
}

int
cache_compiled_batch(PLtsql_function *func)
{
	PLtsql_func_hashkey hashkey;
	int			handle = cur_handle_id;

	MemSet(&hashkey, 0, sizeof(PLtsql_func_hashkey));
	hashkey.funcOid = ((long) handle) << 32;	/* use upper 32bit for funcOid */
	hashkey.isTrigger = false;
	hashkey.isEventTrigger = false;
	hashkey.inputCollation = -1;

	/* avoid overflow when wraparound */
	cur_handle_id = (cur_handle_id % INT32_MAX) + 1;

	pltsql_HashTableInsert(func, &hashkey);
	return handle;
}

void
delete_cached_batch(int handle)
{
	PLtsql_function *func;

	func = find_cached_batch(handle);

	if (func)
	{
		pltsql_HashTableDelete(func);
		pltsql_free_function_memory(func);
	}
}

void
reset_cached_batch()
{
	while (cur_handle_id > 0)
		delete_cached_batch(cur_handle_id--);
	cur_handle_id = 1;
}
