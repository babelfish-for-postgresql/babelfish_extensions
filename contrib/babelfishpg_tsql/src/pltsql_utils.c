#include "postgres.h"
#include "varatt.h"

#include "catalog/namespace.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "catalog/pg_trigger.h"
#include "catalog/pg_constraint.h"
#include "funcapi.h"
#include "parser/parser.h"		/* only needed for GUC variables */
#include "parser/parse_type.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "pltsql.h"
#include "storage/lock.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/fmgroids.h"
#include "utils/catcache.h"
#include "utils/acl.h"
#include "access/table.h"
#include "access/genam.h"
#include "catalog.h"
#include "hooks.h"
#include "tcop/utility.h"

#include "multidb.h"
#include "session.h"

common_utility_plugin *common_utility_plugin_ptr = NULL;

bool		suppress_string_truncation_error = false;

bool		pltsql_suppress_string_truncation_error(void);



bool
pltsql_createFunction(ParseState *pstate, PlannedStmt *pstmt, const char *queryString, ProcessUtilityContext context, 
                          ParamListInfo params);

extern bool restore_tsql_tabletype;
extern bool babelfish_dump_restore;
extern char *get_cur_db_name(void);
extern char *construct_unique_index_name(char *index_name, char *relation_name); 
extern char *get_physical_schema_name(char *db_name, const char *schema_name);
extern char *get_dbo_schema_name(const char *dbname);
PG_FUNCTION_INFO_V1(split_identifier_internal);

/* To cache oid of sys.varchar */
static Oid sys_varcharoid = InvalidOid;
static Oid sysadmin_oid = InvalidOid;

/*
 * Following the rule for locktag fields of advisory locks:
 *	field1: MyDatabaseId ... ensures locks are local to each database
 *	field2: high-order half of an int8 key
 *	field3: low-order half of an int8 key
 *	field4: 1 or 2 are used in advisory lock funcs that user may call, so we use 3
 *	We also add a magic number to the key to avoid collision
 */
const uint64 PLTSQL_LOCKTAG_OFFSET = 0xABCDEF;
#define SET_LOCKTAG_INT16(tag, key16) \
	SET_LOCKTAG_ADVISORY(tag, \
						 MyDatabaseId, \
						 (uint32) ((((int64) key16) + PLTSQL_LOCKTAG_OFFSET) >> 32), \
						 (uint32) (((int64) key16) + PLTSQL_LOCKTAG_OFFSET), \
						 3)
/*
 * Transaction processing using tsql semantics
 */
void
PLTsqlProcessTransaction(Node *parsetree,
						 ParamListInfo params,
						 QueryCompletion *qc)
{
	char	   *txnName = NULL;
	TransactionStmt *stmt = (TransactionStmt *) parsetree;

	if (params != NULL && params->numParams > 0 && !params->params[0].isnull)
	{
		Oid			typOutput;
		bool		typIsVarlena;
		FmgrInfo	finfo;

		Assert(params->numParams == 1);
		getTypeOutputInfo(params->params[0].ptype, &typOutput, &typIsVarlena);
		fmgr_info(typOutput, &finfo);
		txnName = OutputFunctionCall(&finfo, params->params[0].value);
	}
	else
		txnName = stmt->savepoint_name;

	if (txnName != NULL && strlen(txnName) > TSQL_TXN_NAME_LIMIT / 2)
		ereport(ERROR,
				(errcode(ERRCODE_NAME_TOO_LONG),
				 errmsg("Transaction name length %zu above limit %u",
						strlen(txnName), TSQL_TXN_NAME_LIMIT / 2)));

	if (AbortCurTransaction)
	{
		if (stmt->kind == TRANS_STMT_BEGIN ||
			stmt->kind == TRANS_STMT_COMMIT ||
			stmt->kind == TRANS_STMT_SAVEPOINT)
			ereport(ERROR,
					(errcode(ERRCODE_TRANSACTION_ROLLBACK),
					 errmsg("The current transaction cannot be committed and cannot support operations that write to the log file. Roll back the transaction.")));
	}

	switch (stmt->kind)
	{
		case TRANS_STMT_BEGIN:
			{
				PLTsqlStartTransaction(txnName);
			}
			break;

		case TRANS_STMT_COMMIT:
			{
				if (exec_state_call_stack &&
					exec_state_call_stack->estate &&
					exec_state_call_stack->estate->insert_exec &&
					NestedTranCount <= 1)
					ereport(ERROR,
							(errcode(ERRCODE_TRANSACTION_ROLLBACK),
							 errmsg("Cannot use the COMMIT statement within an INSERT-EXEC statement unless BEGIN TRANSACTION is used first.")));

				PLTsqlCommitTransaction(qc, stmt->chain);
			}
			break;

		case TRANS_STMT_ROLLBACK:
			{
				if (exec_state_call_stack &&
					exec_state_call_stack->estate &&
					exec_state_call_stack->estate->insert_exec)
					ereport(ERROR,
							(errcode(ERRCODE_TRANSACTION_ROLLBACK),
							 errmsg("Cannot use the ROLLBACK statement within an INSERT-EXEC statement.")));
				PLTsqlRollbackTransaction(txnName, qc, stmt->chain);
			}
			break;

		case TRANS_STMT_SAVEPOINT:
			RequireTransactionBlock(true, "SAVEPOINT");
			DefineSavepoint(txnName);
			break;

		default:
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_TRANSACTION_INITIATION),
					 errmsg("Unsupported transaction command : %d", stmt->kind)));
			break;
	}
}


bool
pltsql_createFunction(ParseState *pstate, PlannedStmt *pstmt, const char *queryString, ProcessUtilityContext context, 
                          ParamListInfo params)
{
	Node	   *parsetree = pstmt->utilityStmt;
	CreateFunctionStmt *stmt = (CreateFunctionStmt *)parsetree;
	ListCell *option, *location_cell = NULL;
	DefElem    *language_item = NULL;
	char *language = NULL;
	ObjectAddress address;
	bool isCompleteQuery = (context != PROCESS_UTILITY_SUBCOMMAND);
	bool needCleanup;
	Node *tbltypStmt = NULL;
	Node *trigStmt = NULL;
	ObjectAddress tbltyp;
	int origname_location = -1;
	bool with_recompile = false;

	pstate->p_sourcetext = queryString;

	foreach(option, stmt->options)
	{
		DefElem *defel = (DefElem *)lfirst(option); 

		if (strcmp(defel->defname, "language") == 0)
		{
			if (language_item)
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						errmsg("conflicting or redundant options"),
						parser_errposition(pstate, defel->location)));
			language_item = defel;
		}
	}

	if (language_item)
		language = strVal(language_item->arg);

	if(!((language && !strcmp(language,"pltsql")) || sql_dialect == SQL_DIALECT_TSQL))
	{
		return false;
	}
	else
	{
		/* Do not check for duplicate function if REPLACE flag is set and during dump and restore. */
		if (!stmt->replace && !babelfish_dump_restore)
		{
			ObjectWithArgs *func = NULL;
			Oid func_oid = InvalidOid;
			char *schemaname = NULL;
			char *funcname = NULL;
			List *path_oids = NULL;
			char *cur_schema_name = NULL;

			func = makeNode(ObjectWithArgs);

			/* Get the schema name and function name. */
			DeconstructQualifiedName(stmt->funcname, &schemaname, &funcname);

			/* If schema name is not specified, use the current default schema */
			if (schemaname == NULL || !strlen(schemaname))
			{
				path_oids = fetch_search_path(false);
				if (path_oids != NIL)
				{
					cur_schema_name = get_namespace_name(linitial_oid(path_oids));
					if (unlikely(cur_schema_name == NULL))
					{
						ereport(ERROR, (errcode(ERRCODE_UNDEFINED_SCHEMA),
										errmsg("Current schema name could not be determined")));
					}
					func->objname = list_make2(makeString(cur_schema_name), makeString(funcname));
					list_free(path_oids);
				}
			} 
			else
				func->objname = stmt->funcname;

			func->args_unspecified = true;

			func_oid = LookupFuncWithArgs(OBJECT_ROUTINE, func, true);

			if (cur_schema_name)
				pfree(cur_schema_name);

			if (OidIsValid(func_oid))
			{
				/* Restrict duplicate procedure/function. */
				ereport(ERROR, (errcode(ERRCODE_DUPLICATE_FUNCTION),
								errmsg("Function '%s' already exists with the same name", funcname)));
			}
		}

		/* All event trigger calls are done only when isCompleteQuery is true */
		needCleanup = isCompleteQuery && EventTriggerBeginCompleteQuery();

		/* PG_TRY block is to ensure we call EventTriggerEndCompleteQuery */
		PG_TRY();
		{
			if (isCompleteQuery)
				EventTriggerDDLCommandStart(parsetree);

			foreach (option, stmt->options)
			{
				DefElem *defel = (DefElem *)lfirst(option);
				if (strcmp(defel->defname, "tbltypStmt") == 0)
				{
					/*
					* tbltypStmt is an implicit option in tsql dialect,
					* we use this mechanism to create tsql style
					* multi-statement table-valued function and its
					* return (table) type in one statement.
					*/
					tbltypStmt = defel->arg;
				}
				else if (strcmp(defel->defname, "trigStmt") == 0)
				{
					/*
					* trigStmt is an implicit option in tsql dialect,
					* we use this mechanism to create tsql style function
					* and trigger in one statement.
					*/
					trigStmt = defel->arg;
				}
				else if (strcmp(defel->defname, "location") == 0)
				{
					/*
					* location is an implicit option in tsql dialect,
					* we use this mechanism to store location of function
					* name so that we can extract original input function
					* name from queryString.
					*/
					origname_location = intVal((Node *)defel->arg);
					location_cell = option;
					pfree(defel);
				}
				else if (strcmp(defel->defname, "recompile") == 0)
				{
					/*
					 * CREATE PROCEDURE ... WITH RECOMPILE
					 * Record RECOMPILE in catalog
					 */
					with_recompile = true;
				}					
			}

			/* delete location cell if it exists as it is for internal use only */
			if (location_cell)
				stmt->options = list_delete_cell(stmt->options, location_cell);

			/*
			* For tbltypStmt, we need to first process the CreateStmt
			* to create the type that will be used as the function's
			* return type. Then, after the function is created, add a
			* dependency between the type and the function.
			*/
			if (tbltypStmt)
			{
				/* Handle tbltypStmt, which is a CreateStmt */
				PlannedStmt *wrapper;

				wrapper = makeNode(PlannedStmt);
				wrapper->commandType = CMD_UTILITY;
				wrapper->canSetTag = false;
				wrapper->utilityStmt = tbltypStmt;
				wrapper->stmt_location = pstmt->stmt_location;
				wrapper->stmt_len = pstmt->stmt_len;

				ProcessUtility(wrapper,
							queryString,
							false,
							PROCESS_UTILITY_SUBCOMMAND,
							params,
							NULL,
							None_Receiver,
							NULL);

				/* Need CCI between commands */
				CommandCounterIncrement();
			}

			address = CreateFunction(pstate, stmt);

			/* Store function/procedure related metadata in babelfish catalog */
			pltsql_store_func_default_positions(address, stmt->parameters, queryString, origname_location, with_recompile);

			if (tbltypStmt || restore_tsql_tabletype)
			{
				/*
				* Add internal dependency between the table type and
				* the function.
				*/
				tbltyp.classId = TypeRelationId;
				tbltyp.objectId = typenameTypeId(pstate,
												stmt->returnType);
				tbltyp.objectSubId = 0;
				recordDependencyOn(&tbltyp, &address, DEPENDENCY_INTERNAL);
			}

			/*
			* For trigStmt, we need to process the CreateTrigStmt after
			* the function is created, and record bidirectional
			* dependency so that Drop Trigger CASCADE will drop the
			* implicit trigger function.
			* Create trigger takes care of dependency addition.
			*/
			if (trigStmt)
			{
				(void)CreateTrigger((CreateTrigStmt *)trigStmt,
									pstate->p_sourcetext, InvalidOid, InvalidOid,
									InvalidOid, InvalidOid, address.objectId,
									InvalidOid, NULL, false, false);
			}

			/*
			* Remember the object so that ddl_command_end event triggers have
			* access to it.
			*/
			EventTriggerCollectSimpleCommand(address, InvalidObjectAddress,
											parsetree);

			if (isCompleteQuery)
			{
				EventTriggerSQLDrop(parsetree);
				EventTriggerDDLCommandEnd(parsetree);
			}
		}

		PG_CATCH();
		{
			if (needCleanup)
				EventTriggerEndCompleteQuery();
			PG_RE_THROW();
		}
		PG_END_TRY();

		if (needCleanup)
			EventTriggerEndCompleteQuery();

		return true;
	}
}

/*
 * Helper function to setup default typmod for sys types/domains
 * when typmod isn't specified (that is, typmod = -1).
 * We only care to do this in TSQL dialect, this means sys.varchar
 * defaults to sys.varchar(1) only in TSQL dialect.
 *
 * is_cast indicates if it's a CAST/CONVERT statement, if it's true the default
 * length of string and binary type will be set to 30.
 *
 * is_procedure_or_func indicates if it's a procedure/function statement,
 * if it's true the default length of string and binary type will be set to 1
 * otherwise we will add VARHDRSZ to it.
 *
 * If typmod is TSQLMaxTypmod (-8000), it means MAX is used in the
 * length field of VARCHAR, NVARCHAR or VARBINARY. Set typmod to -1,
 * by default -1 the engine will treat it as unlimited length.
 *
 * Also, length should be restricted to 8000 for sys.varchar and sys.char datatypes.
 * And length should be restricted to 4000 for sys.varchar and sys.char datatypes
 */
void
pltsql_check_or_set_default_typmod_helper(TypeName *typeName, int32 *typmod, bool is_cast, bool is_procedure_or_func)
{
	Assert(sql_dialect == SQL_DIALECT_TSQL);

	/* Do nothing for  internally generated TypeName or %TYPE */
	if (typeName->names == NIL || typeName->pct_type)
	{
		return;
	}
	else
	{
		/* Normal reference to a type name */
		char	   *schemaname;
		char	   *typname;
		bool		is_sys_schema = false;

		/* deconstruct the name list */
		DeconstructQualifiedName(typeName->names, &schemaname, &typname);
		if (schemaname)
			is_sys_schema = strcmp("sys", schemaname) == 0;
		else
		{
			Oid			schema_oid;
			Oid			sys_oid = InvalidOid;

			/* Unqualified type name, search the search path */
			schema_oid = typenameGetSchemaOID(typname, true);
			if (!OidIsValid(sys_oid))
				sys_oid = get_namespace_oid("sys", true);
			is_sys_schema = sys_oid == schema_oid;
		}
		if (is_sys_schema)
		{
			int			max_allowed_varchar_length = 8000;
			int			max_allowed_nvarchar_length = 4000;

			/*
			 * sys types/domains without typmod specification, set the default
			 * accordingly
			 */
			if (*typmod == -1)
			{
				if (strcmp(typname, "varchar") == 0 ||
					strcmp(typname, "nvarchar") == 0 ||
					strcmp(typname, "nchar") == 0 ||
					strcmp(typname, "varbinary") == 0 ||
					strcmp(typname, "binary") == 0 ||
					strcmp(typname, "bpchar") == 0)
				{
					/* Default length is 30 in cast and convert statement */
					if (is_cast)

						/*
						 * atttypmod is the declared length of the type plus
						 * VARHDRSZ.
						 */
						*typmod = 30;
					else
						/* Default length is 1 in the general case */
						*typmod = 1;

					if (!is_procedure_or_func)
						*typmod += VARHDRSZ;
				}
				else if (strcmp(typname, "smalldatetime") == 0)
					*typmod = 0;
				else if (strcmp(typname, "decimal") == 0)
					*typmod = 1179652;	/* decimal(18,0) */
			}
			/* for sys.varchar/nvarchar/varbinary(MAX), set typmod back to -1 */
			else if (*typmod == TSQLMaxTypmod)
			{
				if (strcmp(typname, "varchar") == 0 ||
					strcmp(typname, "nvarchar") == 0 ||
					strcmp(typname, "varbinary") == 0)
					*typmod = -1;
				else
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							 errmsg("Incorrect syntax near the keyword '%s'.", typname)));
			}
			else if (*typmod > (max_allowed_varchar_length + VARHDRSZ) && (strcmp(typname, "varchar") == 0 || strcmp(typname, "bpchar") == 0 || 
											strcmp(typname, "varbinary") == 0 || strcmp(typname, "binary") == 0))
			{
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("The size '%d' exceeds the maximum allowed (%d) for '%s' datatype.",
								*typmod - VARHDRSZ, max_allowed_varchar_length, typname)));
			}
			else if (*typmod > (max_allowed_nvarchar_length + VARHDRSZ) && (strcmp(typname, "nvarchar") == 0 || strcmp(typname, "nchar") == 0))
			{
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("The size '%d' exceeds the maximum allowed (%d) for '%s' datatype.",
								*typmod - VARHDRSZ, max_allowed_nvarchar_length, typname)));
			}
		}
	}
}

void
pltsql_check_or_set_default_typmod(TypeName *typeName, int32 *typmod, bool is_cast)
{
    pltsql_check_or_set_default_typmod_helper(typeName, typmod, is_cast, false);
}

/*
 * Declare variable API
 *
 * Given a variable's info, build its InlineCodeBlockArgs and FunctionCallInfo
 * Note that you still need to manually fill in the first two argumetns of fcinfo.
 * fcinfo->args[0] is the query string. fcinfo->args[1] is the
 * InlineCodeBlockAgs built here.
 *
 * Sample code for calling this function:
 *
 * InlineCodeBlock *codeblock = ...;
 * InlineCodeBlockArgs *args = ...;
 * LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);
 * MemSet(fcinfo, ...);
 *
 * fcinfo->flinfo = ...;
 * fcinfo->args[0].value = PointerGetDatum(codeblock);
 * fcinfo->args[0].isnull = false;
 * fcinfo->nargs = 1;
 *
 * for (p in params)
 *	pltsql_declare_variable(..., &args, &fcinfo);
 *
 * fcinfo->args[1].value = PointerGetDatum(args);
 * fcinfo->args[1].isnull = false;
 * fcinfo->nargs++;
 */
void
pltsql_declare_variable(Oid type, int32 typmod, char *name, char mode, Datum value,
						bool isnull, int index, InlineCodeBlockArgs **args,
						FunctionCallInfo *fcinfo)
{
	/*
	 * In case of sp_execute, we don't need the following info.  Hence, skip
	 * filling InlineCodeBlockArgs if it's not provided.
	 */
	if (args)
	{
		(*args)->argtypes[index] = type;
		(*args)->argtypmods[index] = typmod;
		(*args)->argnames[index] = name;
		(*args)->argmodes[index] = mode;
	}

	if (isnull)
		(*fcinfo)->args[index + 2].value = (Datum) 0;
	else
		(*fcinfo)->args[index + 2].value = value;

	(*fcinfo)->args[index + 2].isnull = isnull;
	(*fcinfo)->nargs++;

	/* Safety check */
	if ((*fcinfo)->nargs - 2 > PREPARE_STMT_MAX_ARGS)
		ereport(ERROR, (errcode(ERRCODE_TOO_MANY_ARGUMENTS),
						errmsg("cannot pass more than %d arguments to a procedure",
							   PREPARE_STMT_MAX_ARGS)));
}

/*
 * Read out param API
 *
 * This function deconstruct the input composite Datum comp_value, and store the
 * info in values and nulls.
 */
void
pltsql_read_composite_out_param(Datum comp_value, Datum **values, bool **nulls)
{
	HeapTupleData tmptup;
	TupleDesc	tupdesc;
	HeapTupleHeader td;
	Oid			tupType;
	int32		tupTypmod;

	/* Get tuple body (note this could involve detoasting) */
	td = DatumGetHeapTupleHeader(comp_value);

	/* Build a temporary HeapTuple control structure */
	tmptup.t_len = HeapTupleHeaderGetDatumLength(td);
	ItemPointerSetInvalid(&(tmptup.t_self));
	tmptup.t_tableOid = InvalidOid;
	tmptup.t_data = td;

	/* Extract rowtype info and find a tupdesc */
	tupType = HeapTupleHeaderGetTypeId(td);
	tupTypmod = HeapTupleHeaderGetTypMod(td);
	tupdesc = lookup_rowtype_tupdesc(tupType, tupTypmod);


	if (tupdesc && HeapTupleIsValid(&tmptup))
	{
		int			td_natts = tupdesc->natts;

		*values = (Datum *) palloc(sizeof(Datum) * td_natts);
		*nulls = (bool *) palloc(sizeof(bool) * td_natts);

		heap_deform_tuple(&tmptup, tupdesc, *values, *nulls);
	}
	else
	{
		*values = NULL;
		*nulls = NULL;
	}
	ReleaseTupleDesc(tupdesc);
}

bool
pltsql_suppress_string_truncation_error()
{
	return suppress_string_truncation_error;
}

void
pltsql_read_procedure_info(StringInfo inout_str,
						   bool *is_proc,
						   Oid *typid,
						   Oid *typmod,
						   int *collation)
{
	Oid			func_oid = InvalidOid;
	Oid			atttypid;
	Oid			atttypmod;
	int			attcollation;
	bool		isStoredProcedure = true;
	HeapTuple	proctup = NULL;
	Form_pg_proc proc = NULL;
	List	   *parsetree;
	CallStmt   *cstmt;
	FuncCall   *funccall;
	FuncCandidateList clist;
	const char *str1 = "EXECUTE ";
	StringInfoData proc_stmt;

	/*
	 * Create a fake EXECUTE statement to get the function name
	 */
	initStringInfo(&proc_stmt);
	appendStringInfoString(&proc_stmt, str1);
	appendStringInfoString(&proc_stmt, inout_str->data);
	parsetree = raw_parser(proc_stmt.data, RAW_PARSE_DEFAULT);
	cstmt = (CallStmt *) ((RawStmt *) linitial(parsetree))->stmt;
	Assert(cstmt);

	if (enable_schema_mapping())
		rewrite_object_refs((Node *) cstmt);

	funccall = cstmt->funccall;

	/*
	 * Parse the name into components and see if it matches any pg_proc
	 * entries in the current search path.
	 */
	clist = FuncnameGetCandidates(funccall->funcname, -1, NIL, false, false, false, false);

	if (clist == NULL)
	{
		/*
		 * We don't store some system procedures in the catalog, ex:
		 * sp_executesql, sp_prepare etc.  We can add a check for them here.
		 * But, let's skip the check from here because when we're going to
		 * execute the procedure, if it doesn't exist or it's not a system
		 * procedure, then anywaay we're going to throw an error.
		 */
		isStoredProcedure = true;
	}
	else
	{
		if (clist->next != NULL)
			ereport(ERROR,
					(errcode(ERRCODE_AMBIGUOUS_FUNCTION),
					 errmsg("more than one function named \"%s\"",
							NameListToString(funccall->funcname))));

		func_oid = clist->oid;
		Assert(func_oid != InvalidOid);

		/* Look up the function */
		proctup = SearchSysCache1(PROCOID, ObjectIdGetDatum(func_oid));

		/* shouldn't happen, otherwise regprocin would've thrown error */
		if (!HeapTupleIsValid(proctup))
			elog(ERROR, "cache lookup failed for function %d", func_oid);

		proc = (Form_pg_proc) GETSTRUCT(proctup);

		isStoredProcedure = (proc->prokind == PROKIND_PROCEDURE);
	}

	if (isStoredProcedure)
	{
		/* a procedure always returns integer */
		atttypid = INT4OID;
		atttypmod = -1;
		attcollation = -1;
	}
	else
	{
		Type		retType;
		Form_pg_type typtup;

		if (proc->proretset)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("The request for procedure \"%s\" failed because \"%s\" is"
							"a SET-returning function", NameStr(proc->proname),
							NameStr(proc->proname))));

		if (proc->prorettype == RECORDOID || proc->prorettype == VOIDOID)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("The request for procedure \"%s\" failed because \"%s\" is"
							"not a scalar-valued function", NameStr(proc->proname),
							NameStr(proc->proname))));

		retType = typeidType(proc->prorettype);
		typtup = (Form_pg_type) GETSTRUCT(retType);

		atttypid = proc->prorettype;
		attcollation = typtup->typcollation;

		/*
		 * By default, PG ignores the typmod of return type, so just pick th
		 * return type from the pg_type.  In [BABEL-1000], we've fixed this
		 * issue by storing the typemod of return type in pg_proc->probin
		 * field.  So, let's read the typmod from the same.
		 */
		Assert(func_oid != InvalidOid);
		atttypmod = probin_read_ret_typmod(func_oid, proc->pronargs, proc->prorettype);

		ReleaseSysCache((HeapTuple) retType);
	}

	if (proctup != NULL)
		ReleaseSysCache(proctup);

	if (is_proc)
		*is_proc = isStoredProcedure;
	if (typid)
		*typid = atttypid;
	if (typmod)
		*typmod = atttypmod;
	if (collation)
		*collation = attcollation;
}

void
PLTsqlStartTransaction(char *txnName)
{
	elog(DEBUG2, "TSQL TXN Start transaction %d", NestedTranCount);
	if (!IsTransactionBlockActive())
	{
		Assert(NestedTranCount == 0);
		BeginTransactionBlock();

		/*
		 * set transaction name in savepoint field. It is needed to
		 * distinguish rollback vs rollback to savepoint requests.
		 */
		if (txnName != NULL)
			SetTopTransactionName(txnName);
	}
	++NestedTranCount;

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_at_at_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_at_at_stat_var(TRANCOUNT_TYPE, NestedTranCount, 0);
}

void
PLTsqlCommitTransaction(QueryCompletion *qc, bool chain)
{
	elog(DEBUG2, "TSQL TXN Commit transaction %d", NestedTranCount);
	if (NestedTranCount <= 1)
	{
		RequireTransactionBlock(true, "COMMIT");
		if (!EndTransactionBlock(chain))
		{
			/* report unsuccessful commit in QueryCompletion */
			if (qc)
				qc->commandTag = CMDTAG_ROLLBACK;
		}
		NestedTranCount = 0;
	}
	else
	{
		--NestedTranCount;
	}

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_at_at_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_at_at_stat_var(TRANCOUNT_TYPE, NestedTranCount, 0);
}

void
PLTsqlRollbackTransaction(char *txnName, QueryCompletion *qc, bool chain)
{
	if (IsTopTransactionName(txnName))
	{
		elog(DEBUG2, "TSQL TXN Rollback transaction");
		RequireTransactionBlock(true, "ROLLBACK");
		/* Rollback request */
		UserAbortTransactionBlock(chain);
		NestedTranCount = 0;

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_at_at_stat_var)
			(*pltsql_protocol_plugin_ptr)->set_at_at_stat_var(TRANCOUNT_TYPE, NestedTranCount, 0);
	}
	else
	{
		elog(DEBUG2, "TSQL TXN Rollback to savepoint %s", txnName);
		RequireTransactionBlock(true, "ROLLBACK TO SAVEPOINT");
		RollbackToSavepoint(txnName);
		RollbackAndReleaseSavepoint(txnName);
		if (qc)
			/* strncpy(completionTag, "ROLLBACK TO SAVEPOINT"); */
			/* PG 13 merge: double check this line */
			qc->commandTag = CMDTAG_SAVEPOINT;
	}
}

void
pltsql_start_txn(void)
{
	PLTsqlStartTransaction(NULL);
	CommitTransactionCommand();
}

void
pltsql_commit_txn(void)
{
	PLTsqlCommitTransaction(NULL, false);
	CommitTransactionCommand();
	StartTransactionCommand();
}

void
pltsql_rollback_txn(void)
{
	PLTsqlRollbackTransaction(NULL, NULL, false);
	CommitTransactionCommand();
	StartTransactionCommand();
}

void
pltsql_abort_any_transaction(void)
{
	NestedTranCount = 0;
	AbortOutOfAnyTransaction();
}

bool
pltsql_get_errdata(int *tsql_error_code, int *tsql_error_severity, int *tsql_error_state)
{
	if (exec_state_call_stack == NULL ||
		exec_state_call_stack->error_data.error_number < 50000)
		return false;

	if (tsql_error_code)
		*tsql_error_code = exec_state_call_stack->error_data.error_number;
	if (tsql_error_severity)
		*tsql_error_severity = exec_state_call_stack->error_data.error_severity;
	if (tsql_error_state)
		*tsql_error_state = exec_state_call_stack->error_data.error_state;
	return true;
}

bool
is_sysname_column(ColumnDef *coldef)
{
	return pg_strcasecmp(((String *) llast(coldef->typeName->names))->sval, "sysname") == 0;
}

bool
have_null_constr(List *constr_list)
{
	ListCell   *lc;
	bool		isnull = false;

	foreach(lc, constr_list)
	{
		Constraint *c = lfirst_node(Constraint, lc);

		if (c->contype == CONSTR_NULL)
		{
			isnull = true;
			break;
		}
	}
	return isnull;
}

Node *
parsetree_nth_stmt(List *parsetree, int n)
{
	return ((RawStmt *) list_nth(parsetree, n))->stmt;
}

/*
 * Functions to update parsed dummy statements with real values
 */
void
update_AlterTableStmt(Node *n, const char *tbl_schema, const char *newowner)
{
	AlterTableStmt *stmt = (AlterTableStmt *) n;
	ListCell   *lc;

	if (!IsA(stmt, AlterTableStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a AlterTableStmt")));

	if (tbl_schema)
		stmt->relation->schemaname = pstrdup(tbl_schema);

	if (!newowner)
		return;

	foreach(lc, stmt->cmds)
	{
		AlterTableCmd *cmd = (AlterTableCmd *) lfirst(lc);

		switch (cmd->subtype)
		{
			case AT_ChangeOwner:
				{
					cmd->newowner->rolename = pstrdup(newowner);
					break;
				}
			default:
				break;
		}
	}
}

void
update_CreateRoleStmt(Node *n, const char *role, const char *member, const char *addto)
{
	CreateRoleStmt *stmt = (CreateRoleStmt *) n;
	ListCell   *option;

	if (!IsA(stmt, CreateRoleStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a CreateRoleStmt")));

	if (role)
		stmt->role = pstrdup(role);

	if (!member && !addto)
		return;

	foreach(option, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(option);

		if (member && defel->arg && strcmp(defel->defname, "rolemembers") == 0)
		{
			RoleSpec   *tmp = (RoleSpec *) llast((List *) defel->arg);

			tmp->rolename = pstrdup(member);
		}
		else if (addto && defel->arg && strcmp(defel->defname, "addroleto") == 0)
		{
			RoleSpec   *tmp = (RoleSpec *) llast((List *) defel->arg);

			tmp->rolename = pstrdup(addto);
		}
	}
}

void
update_AlterRoleStmt(Node *n, RoleSpec *role)
{
	AlterRoleStmt *stmt = (AlterRoleStmt *) n;

	if (!IsA(stmt, AlterRoleStmt))
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("query is not an AlterRoleStmt")));

	stmt->role = role;
}

void
update_CreateSchemaStmt(Node *n, const char *schemaname, const char *authrole)
{
	CreateSchemaStmt *stmt = (CreateSchemaStmt *) n;

	if (!IsA(stmt, CreateSchemaStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a CreateSchemaStmt")));

	if (schemaname)
		stmt->schemaname = pstrdup(schemaname);

	if (authrole)
		stmt->authrole->rolename = pstrdup(authrole);
}

void
update_DropOwnedStmt(Node *n, List *role_list)
{
	DropOwnedStmt *stmt = (DropOwnedStmt *) n;
	List	   *rolespec_list = NIL;
	ListCell   *elem;

	if (!IsA(stmt, DropOwnedStmt))
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("query is not a DropOwnedStmt")));

	foreach(elem, role_list)
	{
		char	   *name = (char *) lfirst(elem);
		rolespec_list = lappend(rolespec_list, make_rolespec_node(name));
	}
	stmt->roles = rolespec_list;
}

void
update_DropRoleStmt(Node *n, const char *role)
{
	DropRoleStmt *stmt = (DropRoleStmt *) n;

	if (!IsA(stmt, DropRoleStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a DropRoleStmt")));

	if (role && stmt->roles)
	{
		/*
		 * Delete the first element if it's is_role flag, in this way we won't
		 * need to rewrite the role names during internal call.
		 */
		RoleSpec   *tmp = (RoleSpec *) linitial(stmt->roles);

		if (strcmp(tmp->rolename, "is_role") == 0)
			stmt->roles = list_delete_cell(stmt->roles, list_head(stmt->roles));

		if (!stmt->roles)
			return;

		/* Update the statement with given role name */
		tmp = (RoleSpec *) llast(stmt->roles);
		tmp->rolename = pstrdup(role);
	}
}

void
update_DropStmt(Node *n, const char *object)
{
	DropStmt   *stmt = (DropStmt *) n;

	if (!IsA(stmt, DropStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a DropStmt")));

	if (object && stmt->objects)
		llast(stmt->objects) = makeString(pstrdup(object));
}

void
update_GrantRoleStmt(Node *n, List *privs, List *roles)
{
	GrantRoleStmt *stmt = (GrantRoleStmt *) n;

	if (!IsA(stmt, GrantRoleStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a GrantRoleStmt")));

	stmt->granted_roles = privs;
	stmt->grantee_roles = roles;
}

void
update_GrantStmt(Node *n, const char *object, const char *obj_schema, const char *grantee, const char *priv)
{
	GrantStmt  *stmt = (GrantStmt *) n;

	if (!IsA(stmt, GrantStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a GrantStmt")));

	if (object && stmt->objects)
		llast(stmt->objects) = makeString(pstrdup(object));
	else if (obj_schema && stmt->objects)
	{
		RangeVar   *tmp = (RangeVar *) llast(stmt->objects);
		tmp->schemaname = pstrdup(obj_schema);
	}

	if (grantee && stmt->grantees)
	{
		RoleSpec   *tmp = (RoleSpec *) llast(stmt->grantees);
		if (strcmp(grantee, PUBLIC_ROLE_NAME) == 0)
		{
			tmp->roletype = ROLESPEC_PUBLIC;
		}
		tmp->rolename = pstrdup(grantee);
	}

	if (priv && stmt->privileges)
	{
		AccessPriv *tmp = (AccessPriv *) llast(stmt->privileges);
		tmp->priv_name = pstrdup(priv);
	}
}

void
update_AlterDefaultPrivilegesStmt(Node *n, const char *schema, const char *role1, const char *role2, const char *grantee, const char *priv)
{
	AlterDefaultPrivilegesStmt *stmt = (AlterDefaultPrivilegesStmt *) n;
	ListCell *lc;

	if (!IsA(stmt, AlterDefaultPrivilegesStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a AlterDefaultPrivilegesStmt")));

	if (grantee && priv && stmt->action)
	{
		update_GrantStmt((Node *)(stmt->action), NULL, NULL, grantee, priv);
	}

	foreach(lc, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(lc);

		if (schema && defel->arg && strcmp(defel->defname, "schemas") == 0)
		{
			defel->arg = (Node *)list_make1(makeString((char *)schema));
		}

		else if (role1 && role2 && defel->arg && strcmp(defel->defname, "roles") == 0)
		{
			defel->arg = (Node *)list_make2(makeString((char *)role1), makeString((char *)role2));
		}
	}
}

void
update_RenameStmt(Node *n, const char *old_name, const char *new_name)
{
	RenameStmt *stmt = (RenameStmt *) n;

	if (!IsA(stmt, RenameStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a RenameStmt")));

	stmt->subname = pstrdup(old_name);
	stmt->newname = pstrdup(new_name);
}

void
update_ViewStmt(Node *n, const char *view_schema)
{
	ViewStmt   *stmt = (ViewStmt *) n;

	if (!IsA(stmt, ViewStmt))
		ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("query is not a ViewStmt")));

	if (view_schema)
		stmt->view->schemaname = pstrdup(view_schema);
}

/* sys.char, sys.varchar */
bool
is_tsql_varchar_or_char_datatype(Oid oid)
{
	return (*common_utility_plugin_ptr->is_tsql_bpchar_datatype) (oid) ||
		(*common_utility_plugin_ptr->is_tsql_varchar_datatype) (oid);
}

/* sys.nchar, sys.nvarchar */
bool
is_tsql_nchar_or_nvarchar_datatype(Oid oid)
{
	return (*common_utility_plugin_ptr->is_tsql_nchar_datatype) (oid) ||
		(*common_utility_plugin_ptr->is_tsql_nvarchar_datatype) (oid);
}

/* sys.binary, sys.varbinary */
bool 
is_tsql_binary_or_varbinary_datatype(Oid oid)
{
	return (*common_utility_plugin_ptr->is_tsql_sys_binary_datatype) (oid) ||
		(*common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype) (oid);
}

/* varchar(max), nvarchar(max), varbinary(max) */
bool
is_tsql_datatype_with_max_scale_expr_allowed(Oid oid)
{
	return	(*common_utility_plugin_ptr->is_tsql_varchar_datatype) (oid) ||
		(*common_utility_plugin_ptr->is_tsql_nvarchar_datatype) (oid) ||
		(*common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype) (oid);
}

bool
is_tsql_text_ntext_or_image_datatype(Oid oid)
{
	return (*common_utility_plugin_ptr->is_tsql_text_datatype) (oid) ||
		(*common_utility_plugin_ptr->is_tsql_ntext_datatype) (oid) ||
		(*common_utility_plugin_ptr->is_tsql_image_datatype) (oid);
}

/*
 * Try to acquire a lock with no wait
 */
bool
TryLockLogicalDatabaseForSession(int16 dbid, LOCKMODE lockmode)
{
	LOCKTAG		tag;

	SET_LOCKTAG_INT16(tag, dbid);

	return LockAcquire(&tag, lockmode, true, true) != LOCKACQUIRE_NOT_AVAIL;
}

/*
 * Release the lock
 */
void
UnlockLogicalDatabaseForSession(int16 dbid, LOCKMODE lockmode, bool force)
{
	LOCKTAG		tag;

	SET_LOCKTAG_INT16(tag, dbid);

	if (!force && !LockHeldByMe(&tag, lockmode, false))
		return;

	LockRelease(&tag, lockmode, true);
}

/*
 * Converts a BpChar (TSQL CHAR(n)) type to cstring
 */
char *
bpchar_to_cstring(const BpChar *bpchar)
{
	const char *bp_data = VARDATA_ANY(bpchar);
	int			len = VARSIZE_ANY_EXHDR(bpchar);

	char	   *result = (char *) palloc(len + 1);

	memcpy(result, bp_data, len);
	result[		len] = '\0';

	return result;
}

/*
 * Converts a VarChar type to cstring
 */
char *
varchar_to_cstring(const VarChar *varchar)
{
	const char *vc_data = VARDATA_ANY(varchar);
	int			len = VARSIZE_ANY_EXHDR(varchar);

	char	   *result = (char *) palloc(len + 1);

	memcpy(result, vc_data, len);
	result[		len] = '\0';

	return result;
}

/*
 * Convert list of schema OIDs to schema names.
 */

char *
flatten_search_path(List *oid_list)
{
	StringInfoData pathbuf;
	ListCell   *lc;

	initStringInfo(&pathbuf);

	foreach(lc, oid_list)
	{
		Oid			schema_oid = lfirst_oid(lc);
		char	   *schema_name = get_namespace_name(schema_oid);

		appendStringInfo(&pathbuf, " %s,", quote_identifier(schema_name));
	}
	pathbuf.data[strlen(pathbuf.data) - 1] = '\0';
	return pathbuf.data;
}

char *
get_pltsql_function_signature_internal(const char *funcname,
									   int nargs, const Oid *argtypes)
{
	StringInfoData argbuf;
	int			i;
	const char *prev_quote_ident = GetConfigOption("quote_all_identifiers", true, true);

	initStringInfo(&argbuf);

	PG_TRY();
	{
		/*
		 * Temporarily set quote_all_identifiers to TRUE to generate quoted
		 * string
		 */
		set_config_option("quote_all_identifiers", "true",
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		appendStringInfo(&argbuf, "%s(", funcname);
		for (i = 0; i < nargs; i++)
		{
			if (i)
				appendStringInfoString(&argbuf, ", ");
			appendStringInfoString(&argbuf, format_type_be_qualified(argtypes[i]));
		}
		appendStringInfoChar(&argbuf, ')');
	}
	PG_FINALLY();
	{
		set_config_option("quote_all_identifiers", prev_quote_ident,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_END_TRY();
	return argbuf.data;			/* return palloc'd string buffer */
}

PG_FUNCTION_INFO_V1(get_pltsql_function_signature);

Datum
get_pltsql_function_signature(PG_FUNCTION_ARGS)
{
	Oid			funcoid = PG_GETARG_OID(0);
	HeapTuple	proctup;
	Form_pg_proc form_proctup;
	const char *func_signature;

	proctup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcoid));
	if (HeapTupleIsValid(proctup))
	{
		form_proctup = (Form_pg_proc) GETSTRUCT(proctup);
		func_signature = (char *) get_pltsql_function_signature_internal(NameStr(form_proctup->proname),
																		 form_proctup->pronargs,
																		 form_proctup->proargtypes.values);

		ReleaseSysCache(proctup);
		PG_RETURN_TEXT_P(cstring_to_text(func_signature));
	}
	PG_RETURN_NULL();
}

void
report_info_or_warning(int elevel, char *message)
{
	ereport(elevel, errmsg("%s", message));

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
		((*pltsql_protocol_plugin_ptr)->send_info) (0, 1, 0, message, 0);
}

void
init_and_check_common_utility(void)
{
	if (!common_utility_plugin_ptr)
	{
		common_utility_plugin **utility_plugin;

		utility_plugin = (common_utility_plugin **) find_rendezvous_variable("common_utility_plugin");
		common_utility_plugin_ptr = *utility_plugin;

		/* common_utility_plugin_ptr is still not initialised */
		if (!common_utility_plugin_ptr)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Failed to find common utility plugin.")));
	}
}


/*
 * tsql_get_constraint_oid
 *	Given name and namespace of a constraint, look up the OID.
 *
 * Returns InvalidOid if there is no such constraint.
 */
Oid
tsql_get_constraint_oid(char *conname, Oid connamespace, Oid user_id)
{
	Relation	tgrel;
	ScanKeyData skey[2];
	SysScanDesc tgscan;
	HeapTuple	tuple;
	Oid result = InvalidOid;

	/* search in pg_constraint by name and namespace */
	tgrel = table_open(ConstraintRelationId, AccessShareLock);
	ScanKeyInit(&skey[0],
				Anum_pg_constraint_conname,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(conname));

	ScanKeyInit(&skey[1],
				Anum_pg_constraint_connamespace,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(connamespace));

	tgscan = systable_beginscan(tgrel, ConstraintNameNspIndexId,
								true, NULL, 2, skey);

	/* we are interested in the first row only */
	if (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
	{
		Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);

		if (OidIsValid(con->oid))
		{
			if (OidIsValid(con->conrelid))
			{
				if (pg_class_aclcheck(con->conrelid, user_id, ACL_SELECT) == ACLCHECK_OK)
					result = con->oid;
			}
			else
				result = con->oid;
		}
	}
	systable_endscan(tgscan);
	table_close(tgrel, AccessShareLock);
	return result;
}

/*
 * tsql_get_trigger_oid
 *	Given name and namespace of a trigger, look up the OID.
 *
 * Returns InvalidOid if there is no such trigger.
 */
Oid
tsql_get_trigger_oid(char *tgname, Oid tgnamespace, Oid user_id)
{
	Relation	tgrel;
	ScanKeyData key;
	SysScanDesc tgscan;
	HeapTuple	tuple;
	Oid result = InvalidOid;

	/* first search in pg_trigger by name */
	tgrel = table_open(TriggerRelationId, AccessShareLock);
	ScanKeyInit(&key,
				Anum_pg_trigger_tgname,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(tgname));

	tgscan = systable_beginscan(tgrel, TriggerRelidNameIndexId,
								true, NULL, 1, &key);

	while (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
	{
		Form_pg_trigger pg_trigger = (Form_pg_trigger) GETSTRUCT(tuple);

		if (!OidIsValid(pg_trigger->tgrelid))
		{
			break;
		}
		/* then consider only trigger in specified namespace */
		if (get_rel_namespace(pg_trigger->tgrelid) == tgnamespace &&
			pg_class_aclcheck(pg_trigger->tgrelid, user_id, ACL_SELECT) == ACLCHECK_OK)
		{
			result = pg_trigger->oid;

			break;
		}
	}
	systable_endscan(tgscan);
	table_close(tgrel, AccessShareLock);
	return result;
}

/*
 * tsql_get_proc_oid
 *	Given name and namespace of a proc, look up the OID.
 *
 * Returns InvalidOid if there is no such proc.
 */
Oid
tsql_get_proc_oid(char *proname, Oid pronamespace, Oid user_id)
{
	HeapTuple	tuple;
	CatCList   *catlist;
	Oid result = InvalidOid;

	/* first search in pg_proc by name */
	catlist = SearchSysCacheList1(PROCNAMEARGSNSP, CStringGetDatum(proname));
	for (int i = 0; i < catlist->n_members; i++)
	{
		Form_pg_proc procform;

		tuple = &catlist->members[i]->tuple;
		procform = (Form_pg_proc) GETSTRUCT(tuple);
		/* then consider only procs in specified namespace */
		if (procform->pronamespace == pronamespace &&
			object_aclcheck(ProcedureRelationId, procform->oid, user_id, ACL_EXECUTE) == ACLCHECK_OK)
		{
			result = procform->oid;

			break;
		}
	}
	ReleaseSysCacheList(catlist);
	return result;
}

static int
babelfish_get_delimiter_pos(char *str)
{
	char	   *ptr;

	if (strlen(str) <= 2 && (strchr(str, '"') || strchr(str, '[') || strchr(str, ']')))
		return -1;
	else if (str[0] == '[')
	{
		ptr = strstr(str, "].");
		if (ptr == NULL)
			return -1;
		else
			return (int) (ptr - str) + 1;
	}
	else if (str[0] == '"')
	{
		ptr = strstr(&str[1], "\".");
		if (ptr == NULL)
			return -1;
		else
			return (int) (ptr - str) + 1;
	}
	else
	{
		ptr = strstr(str, ".");
		if (ptr == NULL)
			return -1;
		else
			return (int) (ptr - str);
	}

	return -1;
}

/*
 * Extract string from input of given length and remove delimited identifiers.
 */
static char *
remove_delimited_identifiers(char *str, int len)
{

	if (len >= 2 && ((str[0] == '[' && str[len - 1] == ']') || (str[0] == '"' && str[len - 1] == '"')))
	{
		if (len > 2)
			return pnstrdup(&str[1], len - 2);
		else
			return pstrdup("");
	}
	else
		return pnstrdup(str, len);
}

/*
 * Split multiple-part object-name into array of pointers, it also remove the delimited identifiers.
 */
char	  **
split_object_name(char *name)
{
	char	  **res = palloc(4 * sizeof(char *));
	char	   *temp[4];
	char	   *str;
	int			cur_pos,
				next_pos;
	int			count = 0;

	/* extract and remove the delimited identifiers from input into temp array */
	cur_pos = 0;
	next_pos = babelfish_get_delimiter_pos(name);
	while (next_pos != -1 && count < 3)
	{
		str = remove_delimited_identifiers(&name[cur_pos], next_pos);
		temp[count++] = str;
		cur_pos += next_pos + 1;
		next_pos = babelfish_get_delimiter_pos(&name[cur_pos]);
	}
	str = remove_delimited_identifiers(&name[cur_pos], strlen(&name[cur_pos]));
	temp[count++] = str;

	/* fill unspecified parts with empty strings */
	for (int i = 0; i < 4; i++)
	{
		if (i < 4 - count)
			res[i] = pstrdup("");
		else
			res[i] = temp[i - (4 - count)];
	}

	return res;
}

/*
 * Wrapper over split_object_name function above to expose it as a SQL function.
 */
Datum
split_identifier_internal(PG_FUNCTION_ARGS)
{
	FuncCallContext	*funcctx;
	char        	**split_parts = NULL;

	if (SRF_IS_FIRSTCALL())
	{
		int         	num_parts = 0;
		MemoryContext	oldcontext;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);
		if (!PG_ARGISNULL(0))
		{
			char	*input;
			char	**splited_object_name;
			int 	i, j = 0;

			input = text_to_cstring(PG_GETARG_TEXT_P(0));
			splited_object_name = split_object_name(input);

			for (i = 0; i < 4; i++)
			{
				if (strlen(splited_object_name[i]) > 0)
					num_parts++;
			}

			if (num_parts > 0)
			{
				split_parts = (char **) palloc(num_parts * sizeof(char *));

				for (i = 0; i < 4; i++)
				{
					if (i >= (4 - num_parts))
						split_parts[j++] = splited_object_name[i];
					else
						pfree(splited_object_name[i]);
				}
			}
			pfree(splited_object_name);
		}

		funcctx->max_calls = num_parts;
		funcctx->user_fctx = split_parts;
		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	split_parts = (char **) funcctx->user_fctx;

	if (funcctx->call_cntr < funcctx->max_calls)
	{
		VarChar *val = (*common_utility_plugin_ptr->tsql_varchar_input) (split_parts[funcctx->call_cntr],
																		 strlen(split_parts[funcctx->call_cntr]),
																		 -1);
		SRF_RETURN_NEXT(funcctx, PointerGetDatum(val));
	}
	else
		SRF_RETURN_DONE(funcctx);
}


/*
 * is_schema_from_db
 *		Given schema_oid and db_id, check if schema belongs to provided database id.
 */
bool
is_schema_from_db(Oid schema_oid, Oid db_id)
{
	Oid			db_id_from_schema;
	char	   *schema_name = get_namespace_name(schema_oid);

	if (!schema_name)
		return false;

	db_id_from_schema = get_dbid_from_physical_schema_name(schema_name, true);
	pfree(schema_name);
	return (db_id_from_schema == db_id);
}

/*
 * remove_trailing_spaces
 * 		Remove trailing spaces from a string
 */
void
remove_trailing_spaces(char *name)
{
	int			len = strlen(name);

	while (len > 0 && isspace((unsigned char) name[len - 1]))
		name[--len] = '\0';
}

/*
 * tsql_get_proc_nsp_oid
 * Given Oid of pg_proc entry return namespace_oid
 * Returns InvalidOid if Oid is not found
 */
Oid
tsql_get_proc_nsp_oid(Oid object_id)
{
	Oid			namespace_oid = InvalidOid;
	HeapTuple	tuple;
	bool		isnull;

	/* retrieve pronamespace in pg_proc by oid */
	tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(object_id));

	if (HeapTupleIsValid(tuple))
	{
		(void) SysCacheGetAttr(PROCOID, tuple,
							   Anum_pg_proc_pronamespace,
							   &isnull);
		if (!isnull)
		{
			Form_pg_proc proc = (Form_pg_proc) GETSTRUCT(tuple);

			namespace_oid = proc->pronamespace;
		}
		ReleaseSysCache(tuple);
	}
	return namespace_oid;
}

/*
 * tsql_get_constraint_nsp_oid
 * Given Oid of pg_constraint entry return namespace_oid
 * Returns InvalidOid if Oid is not found
 */
Oid
tsql_get_constraint_nsp_oid(Oid object_id, Oid user_id)
{

	Oid			namespace_oid = InvalidOid;
	HeapTuple	tuple;
	bool		isnull;

	/* retrieve connamespace in pg_constraint by oid */
	tuple = SearchSysCache1(CONSTROID, ObjectIdGetDatum(object_id));

	if (HeapTupleIsValid(tuple))
	{
		(void) SysCacheGetAttr(CONSTROID, tuple,
							   Anum_pg_constraint_connamespace,
							   &isnull);
		if (!isnull)
		{
			Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);

			if (OidIsValid(con->oid))
			{
				/*
				 * user should have permission of table associated with
				 * constraint
				 */
				if (OidIsValid(con->conrelid))
				{
					if (pg_class_aclcheck(con->conrelid, user_id, ACL_SELECT) == ACLCHECK_OK)
						namespace_oid = con->connamespace;
				}
			}
		}
		ReleaseSysCache(tuple);
	}
	return namespace_oid;
}

/*
 * tsql_get_trigger_rel_oid
 * Given Oid of pg_trigger entry return Oid of table
 * the trigger is on
 * Returns InvalidOid if Oid is not found
 */
Oid
tsql_get_trigger_rel_oid(Oid object_id)
{

	Relation	tgrel;
	ScanKeyData key[1];
	SysScanDesc tgscan;
	HeapTuple	tuple;
	Oid			tgrelid = InvalidOid;

	/* retrieve tgrelid in pg_trigger by oid */
	tgrel = table_open(TriggerRelationId, AccessShareLock);
	ScanKeyInit(&key[0],
				Anum_pg_trigger_oid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(object_id));

	tgscan = systable_beginscan(tgrel, TriggerOidIndexId,
								true, NULL, 1, key);

	if (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
	{
		Form_pg_trigger trig = (Form_pg_trigger) GETSTRUCT(tuple);

		tgrelid = trig->tgrelid;
	}
	systable_endscan(tgscan);
	table_close(tgrel, AccessShareLock);
	return tgrelid;
}

/*
 * Helper function to execute a utility command using
 * ProcessUtility(). Caller should make sure their
 * inputs are sanitized to prevent unexpected behaviour.
 */
void
exec_utility_cmd_helper(char *query_str)
{
	List	   *parsetree_list;
	Node	   *stmt;
	PlannedStmt *wrapper;

	parsetree_list = raw_parser(query_str, RAW_PARSE_DEFAULT);

	if (list_length(parsetree_list) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing",
						list_length(parsetree_list))));

	/* Update the dummy statement with real values */
	stmt = parsetree_nth_stmt(parsetree_list, 0);

	/* Run the built query */
	/* need to make a wrapper PlannedStmt */
	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = stmt;
	wrapper->stmt_location = 0;
	wrapper->stmt_len = strlen(query_str);

	/* do this step */
	ProcessUtility(wrapper,
				   query_str,
				   false,
				   PROCESS_UTILITY_QUERY,
				   NULL,
				   NULL,
				   None_Receiver,
				   NULL);

	/* make sure later steps can see the object created here */
	CommandCounterIncrement();
}

Oid get_sys_varcharoid(void)
{
	Oid sys_oid;
	if (OidIsValid(sys_varcharoid))
	{
		return sys_varcharoid;
	}
	sys_oid = get_namespace_oid("sys", false);
	sys_varcharoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("varchar"), ObjectIdGetDatum(sys_oid));
	if (!OidIsValid(sys_varcharoid))
	{
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Oid corresponding to sys.varchar datatype could not be found.")));
	}
	return sys_varcharoid;
}

Oid get_sysadmin_oid(void)
{
	if (!OidIsValid(sysadmin_oid))
		sysadmin_oid = get_role_oid("sysadmin", true);
	
	return sysadmin_oid;
}

/*
 *	Generates the schema name for fulltext index statements
 *	depending on whether it's master schema or not
 */
const char *
gen_schema_name_for_fulltext_index(const char *schema_name)
{
	char *dbname = get_cur_db_name();
	if (strlen(schema_name) == 0)
		return get_dbo_schema_name(dbname);
	else
		return get_physical_schema_name(dbname, schema_name);
}

/*
 * check_fulltext_exist
 * Check if the fulltext index exist for the given table and schema 
 * during execution of CONTAINS() statement
 */
bool
check_fulltext_exist(const char *schema_name, const char *table_name)
{
	const char	*gen_schema_name = gen_schema_name_for_fulltext_index((char *)schema_name);
	char		*ft_index_name;
	Oid			schemaOid;
	Oid			relid;

	schemaOid = LookupExplicitNamespace(gen_schema_name, true);

	// Check if schema exists
	if (!OidIsValid(schemaOid))
		ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_SCHEMA),
				errmsg("schema \"%s\" does not exist",
					schema_name)));	

	relid = get_relname_relid((const char *) table_name, schemaOid);


	// Check if table exists
	if (!OidIsValid(relid))
		ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_TABLE),
				errmsg("relation \"%s\" does not exist",
					table_name)));
	
	ft_index_name = get_fulltext_index_name(relid, table_name);
	return ft_index_name != NULL;
}

/*
 * replace_special_chars_fts_impl
 * Replace special characters in the input string with the unique hash
 */
char
*replace_special_chars_fts_impl(char *input_str) {
	size_t			input_len = strlen(input_str);
	char			*replacement = NULL;
	char            *unique_hashes[4];
	const char		*special_chars[4] = {"~!&|@#$%^*+=\\;:<>?./", "`", "'", "_"};
	StringInfoData	output_str;
	
	for (int i = 0; i < 4; i++) {
		unique_hashes[i] = construct_unique_index_name("specialChars", psprintf("cat%d", i + 1));
	}
	
	initStringInfo(&output_str);

	for (size_t i = 0; i < input_len; i++) {
		replacement = NULL;

		for (int j = 0; j < 4; j++) {
			if (strchr(special_chars[j], input_str[i]) != NULL) {
				replacement = unique_hashes[j];
				break;
			}
		}
		if (replacement != NULL) {
			/* Check if the current special character is the only one in a sequence */
			bool is_single = true;
			size_t next_char_index = i + 1;

			if (next_char_index < input_len) {
				for (int k = 0; k < 4; k++) {
					char *is_special_char = strchr(special_chars[k], input_str[next_char_index]);
					while ((next_char_index < input_len && isspace((unsigned char)input_str[next_char_index])) || (next_char_index < input_len && is_special_char != NULL)) {
						if (is_special_char != NULL) {
							is_single = false;
						}
						next_char_index++;
						is_special_char = next_char_index < input_len ? strchr(special_chars[k], input_str[next_char_index]) : NULL;
					}
				}
			}

			if (is_single) {
				/* Remove trailing whitespaces from output_str */
				while (output_str.len > 0 && isspace((unsigned char)output_str.data[output_str.len - 1])) {
					output_str.len--;
					output_str.data[output_str.len] = '\0';
				}

				/* Copy the replacement with removed spaces */
				if (strchr("`'_", input_str[i]) != NULL) {
					bool is_prev_space = (i > 0 && isspace((unsigned char)input_str[i - 1]));
					bool is_next_space = (i + 1 < input_len && isspace((unsigned char)input_str[i + 1]));
					if (is_prev_space && is_next_space) {
						appendStringInfo(&output_str, " %s ", replacement);
					} else if (is_prev_space) {
						appendStringInfo(&output_str, " %s", replacement);
					} else if (is_next_space) {
						appendStringInfo(&output_str, "%s ", replacement);
					} else {
						appendStringInfoString(&output_str, replacement);
					}
				} else {
					appendStringInfo(&output_str, " %s ", replacement);
				}
			} else {
				/* Append consecutive special characters group as they are */
				appendBinaryStringInfo(&output_str, &input_str[i], next_char_index - i);
			}

			/* Move the index to the end of the processed sequence */
			i = next_char_index - 1; 
		} else {
			appendStringInfoChar(&output_str, input_str[i]);
		}
	}

	/* Null-terminate the output string */
	appendStringInfoChar(&output_str, '\0');

	/* Free the allocated memory */
	for (int i = 0; i < 4; i++) {
		pfree(unique_hashes[i]);
	}

	return output_str.data;
}

/*
 * get_fulltext_index_name
 * Get the fulltext index name of a relation specified by OID
 */
char
*get_fulltext_index_name(Oid relid, const char *table_name)
{
    Relation        relation = RelationIdGetRelation(relid);
    List            *indexoidlist = RelationGetIndexList(relation);
	ListCell		*cell;
    char            *ft_index_name = NULL;
	char			*table_name_cpy = palloc(strlen(table_name) + 1);
    char            *temp_ft_index_name;

	strcpy(table_name_cpy, table_name);
	temp_ft_index_name = construct_unique_index_name("ft_index", table_name_cpy);
    foreach(cell, indexoidlist)
    {
        Oid indexOid = lfirst_oid(cell);
        ft_index_name = get_rel_name(indexOid);

        if (strcmp(ft_index_name, temp_ft_index_name) == 0)
            break;

        ft_index_name = NULL;
    }

    RelationClose(relation);
    list_free(indexoidlist);
	pfree(table_name_cpy);
    return ft_index_name;
}

/*
 * is_unique_index
 * Check if given index is unique index of a relation specified by OID
 */
bool
is_unique_index(Oid relid, const char *index_name)
{
    Relation        relation = RelationIdGetRelation(relid);
    List            *indexoidlist = RelationGetIndexList(relation);
	ListCell		*cell;
    bool            is_unique = false;
	int				unique_key_count = 0;

    foreach(cell, indexoidlist)
    {
        Oid indexOid = lfirst_oid(cell);
        char *name = get_rel_name(indexOid);

        if (strcmp(name, index_name) == 0)
        {
            HeapTuple       indexTuple = SearchSysCache1(INDEXRELID, ObjectIdGetDatum(indexOid));
            Form_pg_index   indexForm = (Form_pg_index) GETSTRUCT(indexTuple);

			/* Check if the key column is unique and is of single-key */
            if (indexForm->indisunique && indexForm->indrelid == relid && indexForm->indnkeyatts == 1)
            {
				/* Check if the key column is non-nullable */
                for (int i = 0; i < indexForm->indnatts; i++)
                {
					AttrNumber attnum = indexForm->indkey.values[i];
                    if (attnum != 0)
                    {
                        HeapTuple attTuple = SearchSysCache2(ATTNUM,
												ObjectIdGetDatum(relid),
                                                Int16GetDatum(attnum));
						if(HeapTupleIsValid(attTuple))
						{
							Form_pg_attribute attForm = (Form_pg_attribute) GETSTRUCT(attTuple);

							if (attForm->attnotnull)
							{
								unique_key_count++;
								if (unique_key_count > 1)
								{
									ReleaseSysCache(attTuple);
									break;
								}
							}
						}
                        ReleaseSysCache(attTuple);
                    }
                }

                if (unique_key_count == 1)
					is_unique = true;
			}

            ReleaseSysCache(indexTuple);
            break;
        }
    }

    RelationClose(relation);
    list_free(indexoidlist);
    return is_unique;
}

char
*gen_createfulltextindex_cmds(const char *table_name, const char *schema_name, const List *column_name, const char *index_name)
{
	StringInfoData query;

	initStringInfo(&query);

	/*
	 * We prepare the following query to create a fulltext index.
	 *
	 * CREATE INDEX <index_name> ON <table_name> 
	 * USING gin(to_tsvector('fts_contains_simple', sys.replace_special_chars_fts(<column_name>)));
	 *
	 */
	appendStringInfo(&query, "CREATE INDEX \"%s\" ON ", index_name);
	if (schema_name == NULL || strlen(schema_name) == 0 || *schema_name == '\0')
		appendStringInfo(&query, "\"%s\"", table_name);
	else
		appendStringInfo(&query, "\"%s\".\"%s\"", schema_name, table_name);

	appendStringInfo(&query, "USING GIN(");
	for (int i = 0; i < list_length(column_name); i++)
	{
		char *col_name = (char *) list_nth(column_name, i);
		// Add column name
		appendStringInfo(&query, "to_tsvector('fts_contains_simple', sys.replace_special_chars_fts(\"%s\"))", col_name);
		if (i != list_length(column_name) - 1)
			appendStringInfo(&query, ", ");
	}
	appendStringInfo(&query, ")");

	return query.data;
}

char
*gen_dropfulltextindex_cmds(const char *index_name, const char *schema_name) 
{
	StringInfoData query;
	initStringInfo(&query);
	/*
	 * We prepare the following query to drop a fulltext index.
	 *
	 * DROP INDEX <index_name>
	 *
	 */
	appendStringInfo(&query, "DROP INDEX ");

	if (schema_name == NULL || strlen(schema_name) == 0 || *schema_name == '\0')
		appendStringInfo(&query, "\"%s\"", index_name);
	else
		appendStringInfo(&query, "\"%s\".\"%s\"", schema_name, index_name);
	return query.data;

}

/*
 * Helper function to execute ALTER ROLE command using
 * ProcessUtility(). Caller should make sure their
 * inputs are sanitized to prevent unexpected behaviour.
 */
void
exec_alter_role_cmd(char *query_str, RoleSpec *role)
{
	List	   *parsetree_list;
	Node	   *stmt;
	PlannedStmt *wrapper;

	parsetree_list = raw_parser(query_str, RAW_PARSE_DEFAULT);

	if (list_length(parsetree_list) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing",
						list_length(parsetree_list))));

	/* Update the dummy statement with real values */
	stmt = parsetree_nth_stmt(parsetree_list, 0);

	/* Update dummy statement with real values */
	update_AlterRoleStmt(stmt, role);

	/* Run the built query */
	/* need to make a wrapper PlannedStmt */
	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = stmt;
	wrapper->stmt_location = 0;
	wrapper->stmt_len = strlen(query_str);

	/* do this step */
	ProcessUtility(wrapper,
				   query_str,
				   false,
				   PROCESS_UTILITY_SUBCOMMAND,
				   NULL,
				   NULL,
				   None_Receiver,
				   NULL);

	/* make sure later steps can see the object created here */
	CommandCounterIncrement();
}

/*
 * Helper function to generate GRANT on SCHEMA subcommands.
 */
static List
*gen_grantschema_subcmds(const char *schema, const char *rolname, bool is_grant, bool with_grant_option, AclMode privilege, bool is_create_schema)
{
	StringInfoData query;
	List	   *stmt_list;
	Node	   *stmt;
	int			expected_stmts = 2;
	int			i = 0;
	bool		owner_other_than_dbo = false;
	char 		*dbname = get_cur_db_name();
	const char	*dbo_role = get_dbo_role_name(dbname);
	const char	*db_owner_role = get_db_owner_name(dbname);
	const char	*schema_owner = GetUserNameFromId(get_owner_of_schema(schema), false);

	/*
	 * Don't need multiple ALTER DEFAULT PRIVILEGE statements, if:
	 * 1. It's a part of CREATE SCHEMA statement
	 * 2. If the schema owner is dbo
	 * 3. If the schema owner is db_owner (dbo_schema owner is a db_owner)
	 */
	if (!is_create_schema && (strcmp(dbo_role, schema_owner) != 0) && (strcmp(db_owner_role, schema_owner) != 0))
	{
		owner_other_than_dbo = true;
	}

	initStringInfo(&query);
	if (is_grant)
	{
		if (privilege == ACL_EXECUTE)
		{
			if (with_grant_option)
			{
				appendStringInfo(&query, "GRANT dummy ON ALL FUNCTIONS IN SCHEMA dummy TO dummy WITH GRANT OPTION; ");
				appendStringInfo(&query, "GRANT dummy ON ALL PROCEDURES IN SCHEMA dummy TO dummy WITH GRANT OPTION; ");
			}
			else
			{
				appendStringInfo(&query, "GRANT dummy ON ALL FUNCTIONS IN SCHEMA dummy TO dummy; ");
				appendStringInfo(&query, "GRANT dummy ON ALL PROCEDURES IN SCHEMA dummy TO dummy; ");
			}
		}
		else
		{
			if (with_grant_option)
				appendStringInfo(&query, "GRANT dummy ON ALL TABLES IN SCHEMA dummy TO dummy WITH GRANT OPTION; ");
			else
				appendStringInfo(&query, "GRANT dummy ON ALL TABLES IN SCHEMA dummy TO dummy; ");
			
			if (owner_other_than_dbo)
			{
				/* Grant ALTER DEFAULT PRIVILEGES on schema owner and dbo user. */
				appendStringInfo(&query, "ALTER DEFAULT PRIVILEGES FOR ROLE dummy, dummy IN SCHEMA dummy GRANT dummy ON TABLES TO dummy; ");
			}
			else
				appendStringInfo(&query, "ALTER DEFAULT PRIVILEGES IN SCHEMA dummy GRANT dummy ON TABLES TO dummy; ");
		}
	}
	else
	{
		if (privilege == ACL_EXECUTE)
		{
			appendStringInfo(&query, "REVOKE dummy ON ALL FUNCTIONS IN SCHEMA dummy FROM dummy; ");
			appendStringInfo(&query, "REVOKE dummy ON ALL PROCEDURES IN SCHEMA dummy FROM dummy; ");
		}
		else
		{
			appendStringInfo(&query, "REVOKE dummy ON ALL TABLES IN SCHEMA dummy FROM dummy; ");
			if (owner_other_than_dbo)
			{
				/* Grant ALTER DEFAULT PRIVILEGES on schema owner and dbo user. */
				appendStringInfo(&query, "ALTER DEFAULT PRIVILEGES FOR ROLE dummy, dummy IN SCHEMA dummy REVOKE dummy ON TABLES FROM dummy; ");
			}
			else
				appendStringInfo(&query, "ALTER DEFAULT PRIVILEGES IN SCHEMA dummy REVOKE dummy ON TABLES FROM dummy; ");
		}
	}
	stmt_list = raw_parser(query.data, RAW_PARSE_DEFAULT);
	if (list_length(stmt_list) != expected_stmts)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected %d statements, but got %d statements after parsing",
						expected_stmts, list_length(stmt_list))));
	/* Replace dummy elements in parsetree with real values */
	stmt = parsetree_nth_stmt(stmt_list, i++);
	update_GrantStmt(stmt, schema, NULL, rolname, privilege_to_string(privilege));

	stmt = parsetree_nth_stmt(stmt_list, i++);
	if (privilege == ACL_EXECUTE)
		update_GrantStmt(stmt, schema, NULL, rolname, privilege_to_string(privilege));
	else
	{
		if (owner_other_than_dbo)
		{
			update_AlterDefaultPrivilegesStmt(stmt, schema, dbo_role, schema_owner, rolname, privilege_to_string(privilege));
		}
		else
		{
			update_AlterDefaultPrivilegesStmt(stmt, schema, NULL, NULL, rolname, privilege_to_string(privilege));
		}
	}

	pfree(query.data);
	return stmt_list;
}

/*
 * Helper function to execute GRANT on SCHEMA subcommands using
 * ProcessUtility(). Caller should make sure their
 * inputs are sanitized to prevent unexpected behaviour.
 */
void
exec_grantschema_subcmds(const char *schema, const char *rolname, bool is_grant, bool with_grant_option, AclMode privilege, bool is_create_schema)
{
	List		*parsetree_list;
	ListCell	*parsetree_item;
	const char *dbo_role;
	const char *dbname = get_cur_db_name();
	Oid 			save_userid;
	int 			save_sec_context;
	MigrationMode baseline_mode = is_user_database_singledb(dbname) ? SINGLE_DB : MULTI_DB;
	dbo_role = get_dbo_role_name_by_mode(dbname, baseline_mode);

	/* Need dbo user to execute the statements. */
	PG_TRY();
	{
		GetUserIdAndSecContext(&save_userid, &save_sec_context);
		SetUserIdAndSecContext(get_role_oid(dbo_role, true),
					save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
		parsetree_list = gen_grantschema_subcmds(schema, rolname, is_grant, with_grant_option, privilege, is_create_schema);
		/* Run all subcommands */
		foreach(parsetree_item, parsetree_list)
		{
			Node		*stmt = ((RawStmt *) lfirst(parsetree_item))->stmt;
			PlannedStmt *wrapper;

			/* need to make a wrapper PlannedStmt */
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = 0;
			wrapper->stmt_len = 0;

			/* do this step */
			ProcessUtility(wrapper,
						"(GRANT SCHEMA )",
						false,
						PROCESS_UTILITY_SUBCOMMAND,
						NULL,
						NULL,
						None_Receiver,
						NULL);
		}
	}
	PG_CATCH();
	{
		SetUserIdAndSecContext(save_userid, save_sec_context);
		PG_RE_THROW();
	}
	PG_END_TRY();
	SetUserIdAndSecContext(save_userid, save_sec_context);
}

AclMode
string_to_privilege(const char *privname)
{
	if (strcmp(privname, "insert") == 0)
		return ACL_INSERT;
	if (strcmp(privname, "select") == 0)
		return ACL_SELECT;
	if (strcmp(privname, "update") == 0)
		return ACL_UPDATE;
	if (strcmp(privname, "delete") == 0)
		return ACL_DELETE;
	if (strcmp(privname, "references") == 0)
		return ACL_REFERENCES;
	if (strcmp(privname, "execute") == 0)
		return ACL_EXECUTE;
	else
		return 0;
}

const char *
privilege_to_string(AclMode privilege)
{
	switch (privilege)
	{
		case ACL_INSERT:
			return "insert";
		case ACL_SELECT:
			return "select";
		case ACL_UPDATE:
			return "update";
		case ACL_DELETE:
			return "delete";
		case ACL_REFERENCES:
			return "references";
		case ACL_EXECUTE:
			return "execute";
		default:
			elog(ERROR, "unrecognized privilege: %d", (int) privilege);
	}
	return NULL;
}

AccessPriv *
make_accesspriv_node(const char *priv_name)
{
	AccessPriv *n = makeNode(AccessPriv);

	Assert(priv_name != NULL || strlen(priv_name) != 0);

	n->priv_name = pstrdup(priv_name);
	n->cols = NIL;

	return n;
}

RoleSpec *
make_rolespec_node(const char *rolename)
{
	RoleSpec *n = makeNode(RoleSpec);

	Assert(rolename != NULL || strlen(rolename) != 0);

	n->roletype = ROLESPEC_CSTRING;
	n->location = -1;
	n->rolename = pstrdup(rolename);

	return n;
}

/* 
 * Returns the oid of schema owner.
 */
Oid
get_owner_of_schema(const char *schema)
{
	HeapTuple	tup;
	Form_pg_namespace nspform;
	Oid result;

	tup = SearchSysCache1(NAMESPACENAME, CStringGetDatum(schema));

	if (!HeapTupleIsValid(tup))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_SCHEMA),
				 errmsg("schema \"%s\" does not exist", schema)));

	nspform = (Form_pg_namespace) GETSTRUCT(tup);
	result = ((Oid) nspform->nspowner);
	ReleaseSysCache(tup);

	return result;
}
