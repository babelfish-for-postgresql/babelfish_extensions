#include "postgres.h"

#include "access/printtup.h"
#include "access/xact.h"		/* for IsTransactionOrTransactionBlock() */
#include "commands/prepare.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "executor/spi.h"
#include "libpq/pqformat.h"
#include "lib/stringinfo.h"
#include "miscadmin.h"
#include "parser/parser.h"
#include "parser/scansup.h"
#include "pgstat.h"
#include "tcop/pquery.h"
#include "tcop/tcopprot.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/snapmgr.h"

#include "src/include/tds_debug.h"
#include "src/include/tds_int.h"
#include "src/include/tds_iofuncmap.h"
#include "src/include/tds_protocol.h"
#include "src/include/tds_response.h"
#include "src/include/tds_instr.h"
#include "src/include/faultinjection.h"

#define SP_FLAGS_BYREFVALUE   0x01
#define SP_FLAGS_DEFAULTVALUE 0x02
#define SP_FLAGS_ENCRYPTED    0x08

/*
 * sign, 10 digits, '\0'
 *
 * This is important for converting integer to string.  Else, we've to dynamically
 * allocate memory just for the conversion.
 */
#define INT32_STRLEN	12

/* For checking the invalid length parameters */
#define CheckForInvalidLength(temp) \
do \
{ \
	if (temp->len > temp->maxLen) \
	{ \
		ereport(ERROR, \
				(errcode(ERRCODE_PROTOCOL_VIOLATION), \
				 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. " \
					 "Parameter %d (\"%s\"): Data type 0x%02X has an invalid data length or metadata length.", \
					 temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->type))); \
	} \
} while(0)

/* Check if retStatus Not OK */
#define CheckPLPStatusNotOK(temp, retStatus) \
do \
{ \
	if (retStatus != STATUS_OK) \
	{ \
		ereport(ERROR, \
				(errcode(ERRCODE_PROTOCOL_VIOLATION), \
				 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. " \
					 "Parameter %d (\"%s\"): The chunking format is incorrect for a large object parameter of type 0x%02X.", \
					 temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->type))); \
	} \
} while(0)

/* For identifying the Batch Separator. */
#define GetRpcBatchSeparator(tdsVersion) ((tdsVersion > TDS_VERSION_7_1_1) ? 0xFF : 0x80)

/* Different cursor options */
#define SP_CURSOR_SCROLLOPT_KEYSET					0x0001
#define SP_CURSOR_SCROLLOPT_DYNAMIC					0x0002
#define SP_CURSOR_SCROLLOPT_FORWARD_ONLY			0x0004
#define SP_CURSOR_SCROLLOPT_STATIC					0x0008
#define SP_CURSOR_SCROLLOPT_FAST_FORWARD			0x10
#define SP_CURSOR_SCROLLOPT_PARAMETERIZED_STMT		0x1000
#define SP_CURSOR_SCROLLOPT_AUTO_FETCH				0x2000
#define SP_CURSOR_SCROLLOPT_AUTO_CLOSE				0x4000
#define SP_CURSOR_SCROLLOPT_CHECK_ACCEPTED_TYPES	0x8000
#define SP_CURSOR_SCROLLOPT_KEYSET_ACCEPTABLE		0x10000
#define SP_CURSOR_SCROLLOPT_DYNAMIC_ACCEPTABLE		0x20000
#define SP_CURSOR_SCROLLOPT_FORWARD_ONLY_ACCEPTABLE	0x40000
#define SP_CURSOR_SCROLLOPT_STATIC_ACCEPTABLE		0x80000
#define SP_CURSOR_SCROLLOPT_FAST_FORWARD_ACCEPTABLE	0x100000

#define SP_CURSOR_CCOPT_READ_ONLY					0x0001
#define SP_CURSOR_CCOPT_SCROLL_LOCKS				0x0002	/* previously known as LOCKCC */
#define SP_CURSOR_CCOPT_OPTIMISTIC1					0x0004	/* previously known as OPTCC */
#define SP_CURSOR_CCOPT_OPTIMISTIC2					0x0008	/* previously known as OPTCCVAL */
#define SP_CURSOR_CCOPT_ALLOW_DIRECT				0x2000
#define SP_CURSOR_CCOPT_UPDT_IN_PLACE				0x4000
#define SP_CURSOR_CCOPT_CHECK_ACCEPTED_OPTS			0x8000
#define SP_CURSOR_CCOPT_READ_ONLY_ACCEPTABLE		0x10000
#define SP_CURSOR_CCOPT_SCROLL_LOCKS_ACCEPTABLE		0x20000
#define SP_CURSOR_CCOPT_OPTIMISTIC_ACCEPTABLE		0x40000
#define SP_CURSOR_CCOPT_OPTIMISITC_ACCEPTABLE		0x80000

/* different fetch options in sp_cursorfetch */
#define SP_CURSOR_FETCH_FIRST			0x0001
#define SP_CURSOR_FETCH_NEXT			0x0002
#define SP_CURSOR_FETCH_PREV			0x0004
#define SP_CURSOR_FETCH_LAST			0x0008
#define SP_CURSOR_FETCH_ABSOLUTE		0x10
#define SP_CURSOR_FETCH_RELATIVE		0x20
#define SP_CURSOR_FETCH_REFRESH			0x80
#define SP_CURSOR_FETCH_INFO			0x100
#define SP_CURSOR_FETCH_PREV_NOADJUST	0x200
#define SP_CURSOR_FETCH_SKIP_UPDT_CNCY	0x400

/* To get the datatype from the parameter */
#define FetchDataTypeNameFromParameter(param) (param->paramMeta.metaEntry.type1.tdsTypeId)

/* different print option in sp_cursor */
#define PRINT_CURSOR_HANDLE 			0x0001
#define PRINT_PREPARED_CURSOR_HANDLE 		0x0002
#define PRINT_BOTH_CURSOR_HANDLE		0x0004

/* Local functions */
static void GetSPHandleParameter(TDSRequestSP request);
static void GetSPCursorPreparedHandleParameter(TDSRequestSP request);
static void GetSPCursorHandleParameter(TDSRequestSP request);
static inline void FillStoredProcedureCallFromParameterToken(TDSRequestSP req,
															 StringInfo inBuf);
static inline void FillQueryFromParameterToken(TDSRequestSP req,
											  StringInfo inBuf);
static inline void InitializeDataParamTokenIndex(TDSRequestSP req);
static void InitialiseParameterToken(TDSRequestSP request);
static inline Portal GetPortalFromCursorHandle(const int portalHandle, bool missingOk);
static void SendCursorResponse(TDSRequestSP req);
static inline void FetchCursorOptions(TDSRequestSP req);
static int SetCursorOption(TDSRequestSP req);
static void HandleSPCursorOpenCommon(TDSRequestSP req);
static void HandleSPCursorCloseRequest(TDSRequestSP req);
static void HandleSPCursorUnprepareRequest(TDSRequestSP req);
static void GenerateBindParamsData(TDSRequestSP req);
static int ReadParameters(TDSRequestSP request, uint64_t offset, StringInfo message, int *parameterCount);
static void SPExecuteSQL(TDSRequestSP req);
static void SPPrepare(TDSRequestSP req);
static void SPExecute(TDSRequestSP req);
static void SPPrepExec(TDSRequestSP req);
static void SPCustomType(TDSRequestSP req);
static void SPUnprepare(TDSRequestSP req);
static void TDSLogStatementCursorHandler(TDSRequestSP req, char *stmt, int option);
static InlineCodeBlockArgs* DeclareVariables(TDSRequestSP req, FunctionCallInfo *fcinfo, unsigned long options);
List *tvp_lookup_list = NIL;
bool lockForFaultInjection = false;

static InlineCodeBlockArgs*
CreateArgs(int nargs)
{
	InlineCodeBlockArgs		*args;

	args = (InlineCodeBlockArgs *) palloc0(sizeof(InlineCodeBlockArgs));
	args->numargs = nargs;

	args->argtypes = (Oid *) palloc(sizeof(Oid) * args->numargs);
	args->argtypmods = (int32 *) palloc(sizeof(int32) * args->numargs);
	args->argnames = (char **) palloc(sizeof(char *) * args->numargs);
	args->argmodes = (char *) palloc(sizeof(char) * args->numargs);

	return args;
}

/*
 * DeclareVariables - Declare TSQL variables by calling pltsql API directly
 *
 * We prepare the InlineCodeBlockArgs and the same as the second argument
 * of fcinfo.
 * If fcinfo is NULL, then don't call the pltsql API - just get the args and set
 * up TVP lookup.
 */
static InlineCodeBlockArgs*
DeclareVariables(TDSRequestSP req, FunctionCallInfo *fcinfo, unsigned long options)
{
	InlineCodeBlockArgs		*args = NULL;
	ParameterToken			token = NULL;
	int						i = 0, index = 0;
	bool					resolveParamNames = false;
	char					*tmp = NULL,
							*fToken = NULL;

	args = (InlineCodeBlockArgs *) palloc0(sizeof(InlineCodeBlockArgs));
	args->numargs = req->nTotalParams;
	args->options = options;

	if (fcinfo)
	{
		/* now add the same as second argument */
		(*fcinfo)->args[1].value = PointerGetDatum(args);
		(*fcinfo)->args[1].isnull = false;
		(*fcinfo)->nargs++;
	}

	/* set variables if there is any */
	if (req->nTotalParams <= 0)
		return args;

	args->argtypes = (Oid *) palloc(sizeof(Oid) * args->numargs);
	args->argtypmods = (int32 *) palloc(sizeof(int32) * args->numargs);
	args->argnames = (char **) palloc(sizeof(char *) * args->numargs);
	args->argmodes = (char *) palloc(sizeof(char) * args->numargs);
	/*
	 * We have the assumption that either all parameters will have names
	 * or none of them will have.
	 * So, check the parameter name for the first token and set the flag.
	 * If above assumption is invalid, then we will raise the error in
	 * below for loop.
	 */
	if (req->dataParameter->paramMeta.colName.len == 0)
	{
		resolveParamNames = true;
		if (req->metaDataParameterValue->len)
		{
			tmp = pnstrdup(req->metaDataParameterValue->data,
						   req->metaDataParameterValue->len);

			/*
			 * XXX: Ugly hack - When the client driver doesn't specify the parameter names
			 * along with each parameter token, it can be of the either of the following
			 * two formats:
			 *
			 * @P0 <datatype>, @P1 <datatype>, .....
			 * or
			 * @P1 <datatype>, @P2 <datatype>, .....
			 *
			 * So, we just check the first parameter name whether it starts with "0" or
			 * "1" and auto-generate the parameter names.
			 */
			fToken = strtok (tmp, " ");
			if (strcmp(fToken, "@P0") == 0)
				i = 0;
			else if (strcmp(fToken, "@P1") == 0)
				i = 1;
			else
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("unexpected parameter definition %s", fToken)));

			pfree(tmp);
		}
		else
			i = 0;
	}

	/*
	 * For each token, we need to call pltsql_declare_var_block_handler API
	 * to declare the corresponding variable.
	 */
	for (token = req->dataParameter, index = 0; token != NULL; token = token->next, index++)
	{
		char		*paramName;
		StringInfo 	name;
		Datum		pval;
		bool		isNull;
		TdsIoFunctionInfo tempFuncInfo;

		name = &(token->paramMeta.colName);

		/*
		 * TODO: Can we directly give the intermediate token (@P0 int, @P1
		 * varchar))to the pltsql ?
		 * Also, maybe we can use the raw_parser() directly for getting the parameter
		 * names
		 */
		if (resolveParamNames && (name->len))
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("not all Parameters have names")));
		else if(resolveParamNames)
		{
			char buf[10];

			snprintf(buf, sizeof(buf), "@p%d", i);
			paramName = pnstrdup(buf, strlen(buf));;
		}
		else
			paramName = downcase_truncate_identifier(name->data,
													 strlen(name->data), true);

		tempFuncInfo = TdsLookupTypeFunctionsByTdsId(token->type, token->maxLen);
		isNull = token->isNull;

		if (!isNull && fcinfo)
			pval = tempFuncInfo->recvFuncPtr(req->messageData, token);
		else
			pval = (Datum) 0;

		if (fcinfo)
			pltsql_plugin_handler_ptr->pltsql_declare_var_callback (
											 token->paramMeta.pgTypeOid,	/* oid */
											 GetTypModForToken(token),		/* typmod */
											 paramName,						/* name */
											 (token->flags == 0) ?
											 PROARGMODE_IN : PROARGMODE_INOUT,	/* mode */
											 pval,								/* datum */
											 isNull,							/* null */
											 index,
											 &args,
											 fcinfo);
		else
		{
			MemoryContext xactContext;
			MemoryContext oldContext = CurrentMemoryContext;
			StartTransactionCommand();
			if (get_typtype(token->paramMeta.pgTypeOid) == TYPTYPE_COMPOSITE)
			{
				TvpLookupItem *item;
				xactContext = MemoryContextSwitchTo(oldContext);
				item = (TvpLookupItem *) palloc(sizeof(TvpLookupItem));
				item->name = paramName;
				item->tableRelid = get_typ_typrelid(token->paramMeta.pgTypeOid);
				item->tableName = NULL;
				tvp_lookup_list = lappend(tvp_lookup_list, item);
				MemoryContextSwitchTo(xactContext);
			}
			CommitTransactionCommand();
			MemoryContextSwitchTo(oldContext);
		}

		i++;
	}

	return args;
}

/*
 * SetVariables - Set TSQL variables by calling pltsql API directly
 *
 * For sp_execute, we only need to set the values to the associated args in
 * fcinfo.  In this case, param type and name are not important, hence set
 * to NULL.
 */
static void
SetVariables(TDSRequestSP req, FunctionCallInfo *fcinfo)
{
	InlineCodeBlockArgs		*codeblock_args;
	ParameterToken			token = NULL;
	int						i = 0, index = 0;

	/* should be only called for sp_execute */
	Assert(req->spType == SP_EXECUTE);

	codeblock_args = (InlineCodeBlockArgs *) palloc0(sizeof(InlineCodeBlockArgs));
	codeblock_args->handle = (int) req->handle;
	codeblock_args->options = (BATCH_OPTION_EXEC_CACHED_PLAN |
								BATCH_OPTION_NO_FREE);

	/* Set variable if any. */
	if (req->nTotalParams > 0)
	{
		/*
		 * For each token, we need to call pltsql_declare_var_block_handler API
		 * to declare the corresponding variable.
		 */
		for (token = req->dataParameter, index = 0; token != NULL; token = token->next, index++)
		{
			Datum		pval;
			bool		isNull;
			TdsIoFunctionInfo tempFuncInfo;


			tempFuncInfo = TdsLookupTypeFunctionsByTdsId(token->type, token->maxLen);
			isNull = token->isNull;

			if (!isNull)
				pval = tempFuncInfo->recvFuncPtr(req->messageData, token);
			else
				pval = (Datum) 0;

			pltsql_plugin_handler_ptr->pltsql_declare_var_callback(token->paramMeta.pgTypeOid,	/* oid */
											 GetTypModForToken(token),		/* typmod */
											 NULL,						/* name */
											 (token->flags == 0) ?
											 PROARGMODE_IN : PROARGMODE_INOUT,	/* mode */
											 pval,								/* datum */
											 isNull,							/* null */
											 index,
											 NULL,
											 fcinfo);

			i++;
		}
	}

	/* Set the second argument as null just to satisfy the arg requirements */
	(*fcinfo)->args[1].value = PointerGetDatum(codeblock_args);
	(*fcinfo)->args[1].isnull = false;
	(*fcinfo)->nargs++;
}


/*
 * errdetail_params
 *
 * Add an errdetail() line showing bind-parameter data, if available.
 */
static int
errdetail_params(int nTotalParams)
{
	ParamListInfo params;
	params = (ParamListInfo) palloc(offsetof(ParamListInfoData, params) +
									nTotalParams * sizeof(ParamExternData));

	/* We have static list of params, so no hooks needed. */
	params->paramFetch = NULL;
	params->paramFetchArg = NULL;
	params->paramCompile = NULL;
	params->paramCompileArg = NULL;
	params->parserSetup = NULL;
	params->parserSetupArg = NULL;
	params->numParams = nTotalParams;

	TdsFetchInParamValues(params);

	/* We mustn't call user-defined I/O functions when in an aborted xact */
	if (params && params->numParams > 0 && !IsAbortedTransactionBlockState())
	{
		StringInfoData param_str;
		int			paramno;
		MemoryContext oldcontext;

		/* This code doesn't support dynamic param lists */
		Assert(params->paramFetch == NULL);

		/* Make sure any trash is generated in MessageContext */
		oldcontext = MemoryContextSwitchTo(MessageContext);

		initStringInfo(&param_str);

		for (paramno = 0; paramno < params->numParams; paramno++)
		{
			ParamExternData *prm = &params->params[paramno];
			Oid			typoutput;
			bool		typisvarlena;
			char	   *pstring;
			char	   *p;

			appendStringInfo(&param_str, "%s$%d = ",
							 paramno > 0 ? ", " : "",
							 paramno + 1);

			if (prm->isnull || !OidIsValid(prm->ptype))
			{
				appendStringInfoString(&param_str, "NULL");
				continue;
			}

			getTypeOutputInfo(prm->ptype, &typoutput, &typisvarlena);

			pstring = OidOutputFunctionCall(typoutput, prm->value);

			appendStringInfoCharMacro(&param_str, '\'');
			for (p = pstring; *p; p++)
			{
				if (*p == '\'') /* double single quotes */
					appendStringInfoCharMacro(&param_str, *p);
				appendStringInfoCharMacro(&param_str, *p);
			}
			appendStringInfoCharMacro(&param_str, '\'');

			pfree(pstring);
		}

		errdetail("Parameters: %s", param_str.data);
		pfree(param_str.data);
		MemoryContextSwitchTo(oldcontext);
	}

	return 0;
}

static void
SPExecuteSQL(TDSRequestSP req)
{
	StringInfoData s;
	InlineCodeBlock *codeblock;
	LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);

	int paramno;
	Datum retval;
	Datum *values; 
	bool *nulls;
	char *activity;

	TdsErrorContext->err_text = "Processing SP_EXECUTESQL Request";
	if ((req->nTotalParams + 2) > FUNC_MAX_ARGS)
	    ereport(ERROR,
	                    (errcode(ERRCODE_PROTOCOL_VIOLATION),
	                    errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
							"Too many parameters were provided in this RPC request. The maximum is %d",
	                            FUNC_MAX_ARGS)));

	TDSInstrumentation(INSTR_TDS_SP_EXECUTESQL);

	initStringInfo(&s);
	FillQueryFromParameterToken(req, &s);

	activity = psprintf("SP_EXECUTESQL: %s", s.data);
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	codeblock = makeNode(InlineCodeBlock);
	codeblock->source_text = s.data;
	codeblock->langOid = 0; /* TODO does it matter */
	codeblock->langIsTrusted = true;
	codeblock->atomic = false;

	/* Just to satisfy argument requirement */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(FUNC_MAX_ARGS));
	fcinfo->nargs = 1;
	fcinfo->args[0].value = PointerGetDatum(codeblock);
	fcinfo->args[0].isnull = false;

	/* declare variables if there is any */
	if (req->nTotalParams > 0)
		DeclareVariables(req, &fcinfo, 0);

	TDSStatementBeginCallback(NULL, NULL);

	PG_TRY();
	{
		/* Now, execute the same and retrieve the composite datum */
		retval = pltsql_plugin_handler_ptr->sp_executesql_callback (fcinfo);
		MemoryContextSwitchTo(MessageContext);

		/* If pltsql_inline_handler does not end normally */
		if (fcinfo->isnull)
			elog(ERROR, "pltsql_inline_handler failed");

		/* Read out params and nulls after checking the retrived Datum for NULL */
		if (retval)
			pltsql_plugin_handler_ptr->pltsql_read_out_param_callback(retval, &values, &nulls);
		else if (req->nOutParams > 0)
			elog(ERROR, "missing OUT parameter values from pltsql handler");
	}
	PG_CATCH();
	{
		if (TDS_DEBUG_ENABLED(TDS_DEBUG2))
			ereport(LOG,
					(errmsg("sp_executesql statement: %s", s.data),
					 errhidestmt(true),
					 errdetail_params(req->nTotalParams)));

		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* Return Status: 0 (success) or non-zero (failure) */
	TdsSendReturnStatus(0);

	/* Send OUT parameters */
	for (paramno = 0; paramno < req->nOutParams; paramno++)
		SendReturnValueTokenInternal(req->idxOutParams[paramno], 0x01, NULL,
									 values[paramno], nulls[paramno], true);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/*
	 * Log immediately if dictated by log_statement
	 */
	if (pltsql_plugin_handler_ptr->stmt_needs_logging || TDS_DEBUG_ENABLED(TDS_DEBUG2))
	{

		ErrorContextCallback *plerrcontext = error_context_stack;
		error_context_stack = plerrcontext->previous;

		ereport(LOG,
				(errmsg("sp_executesql statement: %s", s.data),
				 errhidestmt(true),
				 errdetail_params(req->nTotalParams)));

		pltsql_plugin_handler_ptr->stmt_needs_logging = false;
		error_context_stack = plerrcontext;
	}

	/*
	 * Print TDS log duration, if log_duration is set
	 */
	TDSLogDuration(s.data);
	pfree(codeblock);
}

static void
SPPrepare(TDSRequestSP req)
{
	StringInfoData s;
	LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);

	Datum retval;
	Datum *values;
	bool *nulls;
	char *activity;

	TdsErrorContext->err_text = "Processing SP_PREPARE Request";
	TDSInstrumentation(INSTR_TDS_SP_PREPARE);

	tvp_lookup_list = NIL;

	if ((req->nTotalParams + 2) > FUNC_MAX_ARGS)
	    ereport(ERROR,
	                    (errcode(ERRCODE_PROTOCOL_VIOLATION),
	                    errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
							"Too many parameters were provided in this RPC request. The maximum is %d",
	                            FUNC_MAX_ARGS)));

	initStringInfo(&s);
	FillQueryFromParameterToken(req, &s);

	activity = psprintf("SP_PREPARE: %s", s.data);
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	MemSet(fcinfo, 0, SizeForFunctionCallInfo(FUNC_MAX_ARGS));

	fcinfo->nargs = 3;
	fcinfo->args[1].value = PointerGetDatum(cstring_to_text(req->metaDataParameterValue->data));
	if (req->metaDataParameterValue->len == 0)
		fcinfo->args[1].isnull = true;
	else
		fcinfo->args[1].isnull = false;

	fcinfo->args[2].value = PointerGetDatum(cstring_to_text(s.data));
	if (s.len == 0)
		fcinfo->args[2].isnull = true;
	else
		fcinfo->args[2].isnull = false;

	TDSStatementBeginCallback(NULL, NULL);

	PG_TRY();
	{
		/* Now, call the prepare handler and retrieve the handle */
		retval = pltsql_plugin_handler_ptr->sp_prepare_callback (fcinfo);
		MemoryContextSwitchTo(MessageContext);

		/* If sp_prepare_handler does not end normally */
		if (fcinfo->isnull)
			elog(ERROR, "sp_prepare_handler failed");

		/* Read out params and nulls after checking the retrived Datum for NULL */
		if (retval)
			pltsql_plugin_handler_ptr->pltsql_read_out_param_callback(retval, &values, &nulls);
		else if (req->nOutParams > 0)
			elog(ERROR, "missing OUT parameter values from pltsql handler");
	}
	PG_CATCH();
	{
		TDSStatementExceptionCallback(NULL, NULL, false);
		tvp_lookup_list = NIL;
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* Return Status: 0 (success) or non-zero (failure) */
	TdsSendReturnStatus(0);

	/* Send the handle */
	SendReturnValueTokenInternal(req->handleParameter, 0x01, NULL,
								 values[0], false, false);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	tvp_lookup_list = NIL;
}

static void
SPExecute(TDSRequestSP req)
{
	InlineCodeBlock *codeblock;
	LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);

	int paramno;
	Datum retval;
	Datum *values;
	bool *nulls;

	char *activity = psprintf("SP_EXECUTE Handle: %d", req->handle);
	TdsErrorContext->err_text = "Processing SP_EXECUTE Request";
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);
	TDSInstrumentation(INSTR_TDS_SP_EXECUTE);

	tvp_lookup_list = NIL;

	if ((req->nTotalParams + 2) > FUNC_MAX_ARGS)
	    ereport(ERROR,
	                    (errcode(ERRCODE_PROTOCOL_VIOLATION),
	                    errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
							"Too many parameters were provided in this RPC request. The maximum is %d",
	                            FUNC_MAX_ARGS)));

	codeblock = makeNode(InlineCodeBlock);
	codeblock->source_text = NULL;
	codeblock->langOid = 0; /* TODO does it matter */
	codeblock->langIsTrusted = true;
	codeblock->atomic = false;

	/* Just to satisfy argument requirement. */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(FUNC_MAX_ARGS));
	fcinfo->nargs = 1;
	fcinfo->args[0].value = PointerGetDatum(codeblock);
	fcinfo->args[0].isnull = false;

	SetVariables(req, &fcinfo);

	TDSStatementBeginCallback(NULL, NULL);

	PG_TRY();
	{
		/* Now, call the execute handler and retrieve the composite datum. */
		retval = pltsql_plugin_handler_ptr->sp_execute_callback (fcinfo);
		MemoryContextSwitchTo(MessageContext);

		/* If sp_execute_handler does not end normally. */
		if (fcinfo->isnull)
			elog(ERROR, "sp_execute_handler failed");

		/* Read the handle retrived if the returned Datum is not NULL. */
		if (retval)
			pltsql_plugin_handler_ptr->pltsql_read_out_param_callback(retval, &values, &nulls);
		else if (req->nOutParams > 0)
			elog(ERROR, "missing OUT parameter values from pltsql handler");
	}
	PG_CATCH();
	{
		if (TDS_DEBUG_ENABLED(TDS_DEBUG2))
			ereport(LOG,
					(errmsg("sp_execute handle: %d", req->handle),
					 errhidestmt(true),
					 errdetail_params(req->nTotalParams)));

		TDSStatementExceptionCallback(NULL, NULL, false);
		tvp_lookup_list = NIL;
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* Return Status: 0 (success) or non-zero (failure). */
	TdsSendReturnStatus(0);

	/* Send OUT parameters. */
	for (paramno = 0; paramno < req->nOutParams; paramno++)
		SendReturnValueTokenInternal(req->idxOutParams[paramno], 0x01, NULL,
									 values[paramno], nulls[paramno], true);

	/* Command type - execute (0xe0). */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/*
	 * Log immediately if dictated by log_statement
	 */
	if (pltsql_plugin_handler_ptr->stmt_needs_logging || TDS_DEBUG_ENABLED(TDS_DEBUG2))
	{
		ErrorContextCallback *plerrcontext = error_context_stack;
		error_context_stack = plerrcontext->previous;

		ereport(LOG,
				(errmsg("sp_execute handle: %d", req->handle),
				 errhidestmt(true),
				 errdetail_params(req->nTotalParams)));
		pltsql_plugin_handler_ptr->stmt_needs_logging = false;
		error_context_stack = plerrcontext;
	}

	/*
	 * Print TDS log duration, if log_duration is set
	 */
	TDSLogDuration(req->messageData);

	pfree(codeblock);
	tvp_lookup_list = NIL;
}

static void
SPPrepExec(TDSRequestSP req)
{
	StringInfoData s;
	InlineCodeBlock *codeblock;
	InlineCodeBlockArgs* codeblock_args;
	LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);

	int paramno;
	Datum retval;
	Datum *values;
	bool *nulls;
	char *activity;

	tvp_lookup_list = NIL;
	TdsErrorContext->err_text = "Processing SP_PREPEXEC Request";

	if ((req->nTotalParams + 2) > FUNC_MAX_ARGS)
	    ereport(ERROR,
	                    (errcode(ERRCODE_PROTOCOL_VIOLATION),
	                    errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
							"Too many parameters were provided in this RPC request. The maximum is %d",
	                            FUNC_MAX_ARGS)));

	TDSInstrumentation(INSTR_TDS_SP_PREPEXEC);

	initStringInfo(&s);
	FillQueryFromParameterToken(req, &s);

	activity = psprintf("SP_PREPEXEC: %s", s.data);
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	codeblock = makeNode(InlineCodeBlock);
	codeblock->source_text = s.data;
	codeblock->langOid = 0; /* TODO does it matter */
	codeblock->langIsTrusted = true;
	codeblock->atomic = false;

	/* Just to satisfy argument requirement */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(FUNC_MAX_ARGS));
	fcinfo->nargs = 1;
	fcinfo->args[0].value = PointerGetDatum(codeblock);
	fcinfo->args[0].isnull = false;

	codeblock_args = DeclareVariables(req, &fcinfo,
		(BATCH_OPTION_CACHE_PLAN | BATCH_OPTION_NO_FREE));

	TDSStatementBeginCallback(NULL, NULL);

	PG_TRY();
	{
		/* Now, call the execute handler and retrieve the composite datum. */
		retval = pltsql_plugin_handler_ptr->sp_prepexec_callback (fcinfo);
		MemoryContextSwitchTo(MessageContext);

		/* If sp_prepexec_handler does not end normally. */
		if (fcinfo->isnull)
			elog(ERROR, "sp_prepexec_handler failed");

		/* Read out params and nulls after checking the retrived Datum for NULL */
		if (retval)
			pltsql_plugin_handler_ptr->pltsql_read_out_param_callback(retval, &values, &nulls);
		else if (req->nOutParams > 0)
			elog(ERROR, "missing OUT parameter values from pltsql handler");
	}
	PG_CATCH();
	{
		if (TDS_DEBUG_ENABLED(TDS_DEBUG2))
			ereport(LOG,
					(errmsg("sp_prepexec handle: %d, "
						"statement: %s", req->handle, s.data),
					 errhidestmt(true),
					 errdetail_params(req->nTotalParams)));

		TDSStatementExceptionCallback(NULL, NULL, false);
		tvp_lookup_list = NIL;
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* TODO: other values than 0? */
	TdsSendReturnStatus(0);

	/* Send the handle */
	SendReturnValueTokenInternal(req->handleParameter, 0x01, NULL,
								 codeblock_args->handle, false, true);

	/* Send OUT parameters */
	for (paramno = 0; paramno < req->nOutParams; paramno++)
		SendReturnValueTokenInternal(req->idxOutParams[paramno], 0x01, NULL,
									 values[paramno], nulls[paramno], true);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/*
	 * Log immediately if dictated by log_statement
	 */
	if (pltsql_plugin_handler_ptr->stmt_needs_logging || TDS_DEBUG_ENABLED(TDS_DEBUG2))
	{
		ErrorContextCallback *plerrcontext = error_context_stack;

		error_context_stack = plerrcontext->previous;
		ereport(LOG,
				(errmsg("sp_prepexec handle: %d, "
						"statement: %s", req->handle, s.data),
				 errhidestmt(true),
				 errdetail_params(req->nTotalParams)));
		pltsql_plugin_handler_ptr->stmt_needs_logging = false;
		error_context_stack = plerrcontext;
	}

	/*
	 * Print TDS log duration, if log_duration is set
	 */
	TDSLogDuration(s.data);

	pfree(codeblock);
	tvp_lookup_list = NIL;
}

/*
 * DeclareSPVariables - declare arguments and return type of a stored procedure
 * or a scalar UDF.
 */
static ParameterToken
DeclareSPVariables(TDSRequestSP req, FunctionCallInfo *fcinfo)
{
	InlineCodeBlockArgs		*args = NULL;
	ParameterToken			token = NULL;
	int						index = 0;
	ParameterToken			returnToken;
	Oid						atttypid;
	Oid						atttypmod;
	int						attcollation;

	/*
	 * The return type is not sent by the client.  So, we first look up the
	 * function/procedure name from the catalog using a builtin system
	 * function.  Then, we check the type of the function.  If it's a procedure
	 * the return type will be always an integer in case of babel,  and if
	 * it's a UDF, we just fetch the return type from catalog.
	 */
	pltsql_plugin_handler_ptr->pltsql_read_procedure_info(
														  &req->name,
														  &req->isStoredProcedure,
														  &atttypid,
														  &atttypmod,
														  &attcollation);

	args = CreateArgs(req->nTotalParams + 1);

	/* now add the same as second argument */
	(*fcinfo)->args[1].value = PointerGetDatum(args);
	(*fcinfo)->args[1].isnull = false;
	(*fcinfo)->nargs++;

	/*
	 * Once we know the return type, we've to prepare a parameter token, so that
	 * we can send the return value of as OUT parameter if required.
	 */
	returnToken = MakeEmptyParameterToken("", atttypid, atttypmod, attcollation);
	returnToken->paramOrdinal = 0;

	pltsql_plugin_handler_ptr->pltsql_declare_var_callback (
									 returnToken->paramMeta.pgTypeOid,	/* oid */
									 GetTypModForToken(returnToken),	/* typmod */
									 "@p0",								/* name */
									 PROARGMODE_INOUT,					/* mode */
									 (Datum) 0,							/* datum */
									 true,								/* null */
									 index,
									 &args,
									 fcinfo);
	index++;

	/*
	 * For each token, we need to call pltsql_declare_var_block_handler API
	 * to declare the corresponding variable.
	 */
	for (token = req->dataParameter; token != NULL; token = token->next, index++)
	{
		char		*paramName;
		StringInfo 	name;
		Datum		pval;
		bool		isNull;
		TdsIoFunctionInfo tempFuncInfo;

		name = &(token->paramMeta.colName);

		if (name->len == 0)
		{
			char buf[10];

			snprintf(buf, sizeof(buf), "@p%d", index);
			paramName = pnstrdup(buf, strlen(buf));;
		}
		else
			paramName = downcase_truncate_identifier(name->data,
													 strlen(name->data), true);

		tempFuncInfo = TdsLookupTypeFunctionsByTdsId(token->type, token->maxLen);
		isNull = token->isNull;

		if (!isNull)
			pval = tempFuncInfo->recvFuncPtr(req->messageData, token);
		else
			pval = (Datum) 0;

		pltsql_plugin_handler_ptr->pltsql_declare_var_callback (
										 token->paramMeta.pgTypeOid,	/* oid */
										 GetTypModForToken(token),		/* typmod */
										 paramName,						/* name */
										 (token->flags == 0) ?
										 PROARGMODE_IN : PROARGMODE_INOUT,	/* mode */
										 pval,								/* datum */
										 isNull,							/* null */
										 index,
										 &args,
										 fcinfo);
	}

	return returnToken;
}

static void
SPCustomType(TDSRequestSP req)
{
	StringInfoData s;
	InlineCodeBlock *codeblock;
	LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);
	ParameterToken returnParamToken = NULL;

	int paramno;
	Datum retval;
	Datum *values;
	bool *nulls;
	char *activity;

	TdsErrorContext->err_text = "Processing SP_CUSTOMTYPE Request";
	if ((req->nTotalParams + 2) > FUNC_MAX_ARGS)
	    ereport(ERROR,
	                    (errcode(ERRCODE_PROTOCOL_VIOLATION),
	                    errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
							"Too many parameters were provided in this RPC request. The maximum is %d",
	                            FUNC_MAX_ARGS)));

	TDSInstrumentation(INSTR_TDS_USER_CUSTOM_SP);

	initStringInfo(&s);
	FillStoredProcedureCallFromParameterToken(req, &s);

	activity = psprintf("SP_CUSTOMTYPE: %s", s.data);
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	codeblock = makeNode(InlineCodeBlock);
	codeblock->source_text = s.data;
	codeblock->langOid = 0; /* TODO does it matter */
	codeblock->langIsTrusted = true;
	codeblock->atomic = false;

	/* Just to satisfy argument requirement */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(FUNC_MAX_ARGS));
	fcinfo->nargs = 1;
	fcinfo->args[0].value = PointerGetDatum(codeblock);
	fcinfo->args[0].isnull = false;

	PG_TRY();
	{
		/* declare variables if there is any */
		returnParamToken = DeclareSPVariables(req, &fcinfo);

		/* Now, execute the same and retrieve the composite datum */
		retval = pltsql_plugin_handler_ptr->sp_executesql_callback (fcinfo);
		MemoryContextSwitchTo(MessageContext);

		/* If pltsql_inline_handler does not end normally */
		if (fcinfo->isnull)
			elog(ERROR, "pltsql_inline_handler failed");

		/* Read out params and nulls after checking the retrived Datum for NULL */
		if (retval)
			pltsql_plugin_handler_ptr->pltsql_read_out_param_callback(retval, &values, &nulls);
		else if (req->nOutParams > 0)
			elog(ERROR, "missing OUT parameter values from pltsql handler");
	}
	PG_CATCH();
	{
		if (TDS_DEBUG_ENABLED(TDS_DEBUG2))
			ereport(LOG,
					(errmsg("stored procedure: %s", req->name.data),
					 errhidestmt(true),
					 errdetail_params(req->nTotalParams)));

		tvp_lookup_list = NIL;

		PG_RE_THROW();
	}
	PG_END_TRY();

	/*
	 * Return value is sent as ReturnStatus token for SP and ReturnValue token
	 * for scalar UDFs.
	 */
	if (req->isStoredProcedure)
	{
		TdsSendReturnStatus(DatumGetInt32(values[0]));
	}
	else
	{
		SendReturnValueTokenInternal(returnParamToken, 0x02, NULL,
									 values[0], nulls[0], true);
	}

	/*
	 * Send OUT parameters.  Please note that the first entry contains the
	 * return status that we've already sent.
	 */
	for (paramno = 0; paramno < req->nOutParams; paramno++)
		SendReturnValueTokenInternal(req->idxOutParams[paramno], 0x01, NULL,
									 values[paramno + 1], nulls[paramno + 1], true);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/*
	 * Log immediately if dictated by log_statement
	 */
	if (pltsql_plugin_handler_ptr->stmt_needs_logging || TDS_DEBUG_ENABLED(TDS_DEBUG2))
	{
		ErrorContextCallback *plerrcontext = error_context_stack;
		error_context_stack = plerrcontext->previous;
		ereport(LOG,
				(errmsg("stored procedure: %s", req->name.data),
				 errhidestmt(true),
				 errdetail_params(req->nTotalParams)));
		pltsql_plugin_handler_ptr->stmt_needs_logging = false;
		error_context_stack = plerrcontext;
	}

	/*
	 * Print TDS log duration, if log_duration is set
	 */
	TDSLogDuration(req->name.data);
	pfree(codeblock);
}

static void
SPUnprepare(TDSRequestSP req)
{
	LOCAL_FCINFO(fcinfo, FUNC_MAX_ARGS);

	char *activity = psprintf("SP_UNPREPARE Handle: %d", req->handle);
	TdsErrorContext->err_text = "Processing SP_UNPREPARE Request";
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	TDSInstrumentation(INSTR_TDS_SP_UNPREPARE);

	/* Just to satisfy argument requirement */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(FUNC_MAX_ARGS));
	fcinfo->nargs = 1;
	fcinfo->args[0].value = PointerGetDatum(req->handle);
	fcinfo->args[0].isnull = false;

	TDSStatementBeginCallback(NULL, NULL);

	PG_TRY();
	{
		/* Now, execute the unprepare handler and retrieve the composite datum */
		pltsql_plugin_handler_ptr->sp_unprepare_callback (fcinfo);
		MemoryContextSwitchTo(MessageContext);

		/* If sp_unprepare_handler does not end normally. */
		if (fcinfo->isnull)
			elog(ERROR, "pltsql_sp_unprepare_handler failed");
	}
	PG_CATCH();
	{
		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);


	/* Return Status: 0 (success) or non-zero (failure). */
	TdsSendReturnStatus(0);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);
}

static int
GetSetColMetadataForCharType(ParameterToken temp, StringInfo message, uint8_t tdsType,
				uint64_t *mainOffset)
{

	uint32_t collation;
	uint8_t sortId;
	uint64_t offset = *mainOffset;
	uint16_t tempLen;
	pg_enc	enc;

	if ((offset + sizeof(tempLen) +
		sizeof(collation) +
		sizeof(sortId)) >
		message->len)
		return STATUS_ERROR;

	memcpy(&tempLen, &message->data[offset], sizeof(tempLen));
	temp->maxLen = tempLen;
	offset += sizeof(tempLen);
	memcpy(&collation, &message->data[offset], sizeof(collation));
	offset += sizeof(collation);
	sortId = message->data[offset];
	offset += sizeof(sortId);

	/* If we recieve 0 value for LCID then we should treat it as a default LCID.*/
	enc = TdsGetEncoding(collation);

	/*
	 * TODO: we should send collation name here instead of Locale ID.
	 */
	if (enc == -1)
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Babelfish does not support %d Locale with %d collate flags and %d SortId", collation & 0xFFFFF, (collation & 0xFFF00000) >> 20, sortId)));

	SetColMetadataForCharType(&temp->paramMeta, tdsType,
								collation & 0xFFFFF, enc,
								(collation & 0xFFF00000) >> 20,
								sortId, tempLen);

	*mainOffset = offset;
	return STATUS_OK;
}

static int
GetSetColMetadataForTextType(ParameterToken temp, StringInfo message, uint8_t tdsType,
				uint64_t *mainOffset)
{

	uint32_t collation;
	uint8_t sortId;
	uint64_t offset = *mainOffset;
	pg_enc	enc;

	if ((offset + sizeof(temp->maxLen) +
		sizeof(collation) +
		sizeof(sortId)) > message->len)
		return STATUS_ERROR;

	memcpy(&temp->maxLen, &message->data[offset], sizeof(temp->maxLen));
	offset += sizeof(temp->maxLen);
	memcpy(&collation, &message->data[offset], sizeof(collation));
	offset += sizeof(collation);
	sortId = message->data[offset];
	offset += sizeof(sortId);

	/* If we recieve 0 value for LCID then we should treat it as a default LCID.*/
	enc = TdsGetEncoding(collation);

	/*
	 * TODO: we should send collation name here instead of Locale ID.
	 */
	if (enc == -1)
		ereport(ERROR,
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Babelfish does not support %d Locale with %d collate flags and %d SortId", collation & 0xFFFFF, (collation & 0xFFF00000) >> 20, sortId)));

	SetColMetadataForTextType(&temp->paramMeta, tdsType,
								collation & 0xFFFFF, enc,
								(collation & 0xFFF00000) >> 20,
								sortId, temp->maxLen);

	*mainOffset = offset;
	return STATUS_OK;
}

int
ReadPlp(ParameterToken temp, StringInfo message, uint64_t *mainOffset)
{

	uint64_t plpTok;
	Plp plpTemp, plpPrev = NULL;
	unsigned long lenCheck = 0;
	uint64_t offset = *mainOffset;

	memcpy(&plpTok , &message->data[offset], sizeof(plpTok));
	offset += sizeof(plpTok);
	temp->plp = NULL;

	/* NULL Check */
	if (plpTok == PLP_NULL)
	{
		temp->isNull = true;
		*mainOffset = offset;
		return STATUS_OK;
	}

	while (true)
	{
		uint32_t tempLen;

		if (offset + sizeof(tempLen) > message->len)
			return STATUS_ERROR;
		memcpy(&tempLen , &message->data[offset], sizeof(tempLen));
		offset += sizeof(tempLen);

		/* PLP Terminator */
		if (tempLen == PLP_TERMINATOR)
			break;
		plpTemp = palloc0(sizeof(PlpData));
		plpTemp->next = NULL;
		plpTemp->offset = offset;
		plpTemp->len = tempLen;
		if (plpPrev == NULL)
		{
			plpPrev = plpTemp;
			temp->plp = plpTemp;
		}
		else
		{
			plpPrev->next = plpTemp;
			plpPrev = plpPrev->next;
		}
		if (offset + plpTemp->len > message->len)
			return STATUS_ERROR;

		offset += plpTemp->len;
		lenCheck += plpTemp->len;
	}

	if (plpTok != PLP_UNKNOWN_LEN)
	{
		/* Length check */
		if (lenCheck != plpTok)
			return STATUS_ERROR;
	}

	*mainOffset = offset;
	return STATUS_OK;
}

static void
InitialiseParameterToken(TDSRequestSP request)
{
	/* Initialize */
	request->handleParameter = NULL;
	request->cursorHandleParameter = NULL;
      request->cursorPreparedHandleParameter = NULL;
	request->queryParameter = NULL;
	request->cursorExtraArg1 = NULL;
	request->cursorExtraArg2 = NULL;
	request->cursorExtraArg3 = NULL;
	request->dataParameter = NULL;
}

static int
ReadParameters(TDSRequestSP request, uint64_t offset, StringInfo message, int *parameterCount)
{
	ParameterToken temp, prev = NULL;
	int len = 0;
	TdsIoFunctionInfo tempFuncInfo;
	uint16	paramOrdinal = 0;
	int retStatus;

	while(offset < message->len)
	{
		uint8_t	tdsType;

		/*
		 * If next byte after a parameter is a BatchFlag
		 * we store the following parameters for the next RPC packet in the Batch.
		 * BatchFlag is '0xFF' For TDS versions more than or equal to 7.2
		 * and '0x80' for Versions lower than or equal to TDS 7.1
		 */
		if((uint8_t) message->data[offset]  == GetRpcBatchSeparator(GetClientTDSVersion()))
		{
			/* Increment offset by 1 to ignore the batch-separator. */
			request->batchSeparatorOffset = offset + 1;

			/* Need to save the lenght of the message, since only messageData field is set for TdsRequestCtrl. */
			request->messageLen = message->len;
			return STATUS_OK;
		}

		temp = palloc0(sizeof(ParameterTokenData));
		len = message->data[offset++];

		/*
		 * Call initStringInfo for every parameter name even if len is 0
		 * so that the processing logic can check the length field from
		 * temp->name->len
		 */
		initStringInfo(&(temp->paramMeta.colName));

		if (len > 0)
		{
			/*
			 * FIXME: parameter name is in UTF-16 format.  Fix this separately.
			 */
			TdsUTF16toUTF8StringInfo(&(temp->paramMeta.colName), &(message->data[offset]), 2 * len);
			offset += 2 * len;
			len = 0;
		}

		memcpy(&temp->flags, &message->data[offset], sizeof(temp->flags));
		offset += sizeof(temp->flags);

#ifdef FAULT_INJECTOR
	/*
	 * We need to have a lock since we are injecting pre-parsing
	 * fault while parsing ReadParameters.
	 */
	if (!lockForFaultInjection)
	{
		TdsMessageWrapper	wrapper;
		lockForFaultInjection = true;
		wrapper.message = message;
		wrapper.messageType = TDS_RPC;
		wrapper.offset = offset;
		FAULT_INJECT(ParseRpcType, &wrapper);
		lockForFaultInjection = false;
	}
#endif
		tdsType = message->data[offset++];

		temp->type = tdsType;
		temp->paramOrdinal = paramOrdinal;
		paramOrdinal++;

		switch (tdsType)
		{
			case TDS_TYPE_TEXT:
			case TDS_TYPE_NTEXT:
			{
				/* Type TEXT and NTEXT are deprecated large objects */
				if(temp->flags & SP_FLAGS_BYREFVALUE)
					ereport(ERROR,
							(errcode(ERRCODE_PROTOCOL_VIOLATION),
							 errmsg("Invalid parameter %d (\"%s\"): Data type 0x%02X is a deprecated large object, or LOB, but is marked as output parameter. "
								 "Deprecated types are not supported as output parameters. Use current large object types instead.",
								 paramOrdinal, temp->paramMeta.colName.data, tdsType)));
				retStatus = GetSetColMetadataForTextType(temp, message, tdsType, &offset);
				if (retStatus != STATUS_OK)
					return retStatus;

				memcpy(&temp->len, &message->data[offset], sizeof(temp->len));

				/* for Null values, Len field is set to -1(0xFFFFFFFF) */
				if (temp->len == 0xFFFFFFFF)
				{
					temp->len = 0;
					temp->isNull = true;
				}

				CheckForInvalidLength(temp);

				offset += sizeof(temp->len);
				temp->dataOffset = offset;
				offset += temp->len;
			}
			break;
			case TDS_TYPE_IMAGE:
			case TDS_TYPE_SQLVARIANT:
			{
				/* Type IMAGE is a deprecated large object*/
				if((temp->flags & SP_FLAGS_BYREFVALUE) && tdsType == TDS_TYPE_IMAGE)
					ereport(ERROR,
							(errcode(ERRCODE_PROTOCOL_VIOLATION),
							 errmsg("Invalid parameter %d (\"%s\"): Data type 0x%02X is a deprecated large object, or LOB, but is marked as output parameter. "
								 "Deprecated types are not supported as output parameters. Use current large object types instead.",
								 paramOrdinal, temp->paramMeta.colName.data, tdsType)));
				SetColMetadataForImageType(&temp->paramMeta, tdsType);
					
				memcpy(&temp->len, &message->data[offset], sizeof(temp->len));

				/* for Null values, Len field is set to -1(0xFFFFFFFF) or 0 */
				if (temp->len == 0xFFFFFFFF ||
					(tdsType == TDS_TYPE_SQLVARIANT && temp->len == 0))
				{
					temp->len = 0;
					temp->isNull = true;
				}

				if (tdsType == TDS_TYPE_SQLVARIANT && temp->len > temp->paramMeta.metaEntry.type8.maxSize)
					ereport(ERROR,
							(errcode(ERRCODE_PROTOCOL_VIOLATION),
							 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
								 "Parameter %d (\"%s\"): Data type 0x%02X (sql_variant) has an invalid length for type-specific metadata.",
								 paramOrdinal, temp->paramMeta.colName.data, tdsType)));

				/*
				 * Skipping two sequence of 4 Bytes, each sequence containing
				 * actual image file length
				 */
				offset += 2 * sizeof(temp->len);
				
				temp->dataOffset = offset;
				offset += temp->len;
			}
			break;
			case TDS_TYPE_CHAR:
			case TDS_TYPE_NCHAR:
			case TDS_TYPE_VARCHAR:
			case TDS_TYPE_NVARCHAR:
			{
				retStatus = GetSetColMetadataForCharType(temp, message, tdsType, &offset);
				if (retStatus != STATUS_OK)
					return retStatus;

				/*
				 * If varchar/Nvchar is created with max keyword, then
				 * data will come in PLP chuncks
				 */
				if (temp->maxLen == 0xFFFF)
				{
					retStatus = ReadPlp(temp, message, &offset);
					CheckPLPStatusNotOK(temp, retStatus);
				}
				else
				{
					/*
					 * Nvarchar datatype have length field of 2 byte
					 */
					uint16_t tempLen;

					if (offset + sizeof(tempLen) > message->len)
						ereport(ERROR,
								(errcode(ERRCODE_PROTOCOL_VIOLATION),
								 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
									 "Parameter %d (\"%s\"): The supplied length is not valid for data type CHAR/NCHAR/VARCHAR/NVARCHAR. "
									 "Check the source data for invalid lengths. An example of an invalid length is data of nchar type with an odd length in bytes.",
									 paramOrdinal, temp->paramMeta.colName.data)));

					memcpy(&tempLen , &message->data[offset], sizeof(tempLen));
					temp->len = tempLen;
					offset += sizeof(tempLen);
					temp->dataOffset = offset;

					/*
					 * For Null values, Len field is set to 65535(0xffff)
					 */
					if (temp->len == 0xffff)
					{
						temp->len = 0;
						temp->isNull = true;
					}

					if (offset + temp->len > message->len)
						ereport(ERROR,
								(errcode(ERRCODE_PROTOCOL_VIOLATION),
								 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
									 "Parameter %d (\"%s\"): Data type 0x%02X has an invalid data length or metadata length.",
									 paramOrdinal, temp->paramMeta.colName.data, tdsType)));

					offset += temp->len;
				}
			}
			break;
			case TDS_TYPE_BIT:
			case TDS_TYPE_INTEGER:
			case TDS_TYPE_FLOAT:
			case TDS_TYPE_MONEYN:
			case TDS_TYPE_DATETIMEN:
			case TDS_TYPE_UNIQUEIDENTIFIER:
			{
				if ((offset + 2) > message->len)
					return STATUS_ERROR;
				temp->maxLen = message->data[offset++];
				/*
				 * Fixed-length datatypes have length field of 1 byte
				 */
				temp->len = message->data[offset++];

				if (temp->len == 0)
					temp->isNull = true;

				CheckForInvalidLength(temp);

				temp->dataOffset = offset;
				if (offset + temp->len > message->len)
					return STATUS_ERROR;
				offset += temp->len;

				SetColMetadataForFixedType(&temp->paramMeta, tdsType, temp->maxLen);
			}
			break;
			case TDS_TYPE_TABLE:
			{
				temp->tvpInfo = palloc0(sizeof(TvpData));

				/* Sets the col metadata and also the corresponding row data. */
				SetColMetadataForTvp(temp, message, &offset);
			}
			break;
			case TDS_TYPE_BINARY:
			case TDS_TYPE_VARBINARY:
			{
				uint16 len;
				
				memcpy(&len, &message->data[offset], sizeof(len));
				offset += sizeof(len);
				temp->maxLen = len;


				SetColMetadataForBinaryType(&temp->paramMeta, tdsType, temp->maxLen);

				/*
				 * If varbinary is created with max keyword,
				 * data will come in PLP chuncks
				 */
				if (temp->maxLen == 0xffff)
				{
					retStatus = ReadPlp(temp, message, &offset);
					CheckPLPStatusNotOK(temp, retStatus);
				}
				else
				{
					memcpy(&len, &message->data[offset], sizeof(len));
					offset += sizeof(len);
					temp->len = len;
					/*
					 * Binary, varbinary  datatypes have length field of 2 bytes
					 * For NULL value, Len field is set to 65535(0xffff)
				 	 */
					if (temp->len == 0xffff)
					{
						temp->len = 0;
						temp->isNull = true;
					}

					CheckForInvalidLength(temp);

					temp->dataOffset = offset;
					if (offset + temp->len > message->len)
						return STATUS_ERROR;
					offset += temp->len;
				}
			}
			break;
			case TDS_TYPE_DATE:
			{
				if ((offset + 1) > message->len)
					return STATUS_ERROR;

				temp->len = message->data[offset++];
				temp->maxLen = 3;

				if (temp->len == 0)
					temp->isNull = true;

				CheckForInvalidLength(temp);

				temp->dataOffset = offset;
				if (offset + temp->len > message->len)
					return STATUS_ERROR;
				offset += temp->len;

				SetColMetadataForDateType(&temp->paramMeta, tdsType);
			}
			break;
			case TDS_TYPE_TIME:
			case TDS_TYPE_DATETIME2:
			case TDS_TYPE_DATETIMEOFFSET:
			{
				uint8_t scale = message->data[offset++];
				temp->len = message->data[offset++];

				if (temp->len == 0)
					temp->isNull = true;

				if (tdsType == TDS_TYPE_TIME)
					temp->maxLen = 5;
				else if (tdsType == TDS_TYPE_DATETIME2)
					temp->maxLen = 8;
				else if (tdsType == TDS_TYPE_DATETIMEOFFSET)
					temp->maxLen = 10;

				CheckForInvalidLength(temp);

				temp->dataOffset = offset;
				if ((offset + temp->len) > message->len)
					return STATUS_ERROR;
				offset += temp->len;

				SetColMetadataForTimeType(&temp->paramMeta, tdsType, scale);
			}
			break;
			case TDS_TYPE_DECIMALN:
			case TDS_TYPE_NUMERICN:
			{
				uint8_t scale;
				uint8_t precision;

				temp->maxLen = message->data[offset++];

				precision = message->data[offset++];
				scale = message->data[offset++];

				if (scale > precision)
				    ereport(ERROR,
				                    (errcode(ERRCODE_PROTOCOL_VIOLATION),
				                    errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
										"Parameter %d (\"%s\"): The supplied value is not a valid instance of data type Numeric/Decimal. Check the source data for invalid values. "
										"An example of an invalid value is data of numeric type with scale greater than precision",
				                            paramOrdinal, temp->paramMeta.colName.data)));

				temp->len = message->data[offset++];
				if (temp->len > TDS_MAXLEN_NUMERIC)
					ereport(ERROR,
							(errcode(ERRCODE_PROTOCOL_VIOLATION),
								errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
									"Parameter %d (\"%s\"): Data type 0x%02X has an invalid data length or metadata length.",
									paramOrdinal, temp->paramMeta.colName.data, tdsType)));

	 			if (temp->len == 0)
	 				temp->isNull = true;

				CheckForInvalidLength(temp);

				temp->dataOffset = offset;

				if ((offset + temp->len) > message->len)
					return STATUS_ERROR;

				/*
				 * XXX: We do not support DECIMAL so internally we store
				 * DECIMAL as NUMERIC.
				 */
				temp->type = TDS_TYPE_NUMERICN;
				tdsType = TDS_TYPE_NUMERICN;

				SetColMetadataForNumericType(&temp->paramMeta, TDS_TYPE_NUMERICN, temp->maxLen,
								precision, scale);
				offset += temp->len;
			}
			break;
			case TDS_TYPE_XML:
			{
				temp->maxLen = message->data[offset++];
				retStatus = ReadPlp(temp, message, &offset);
				CheckPLPStatusNotOK(temp, retStatus);
			}
			break;
			default:
			        ereport(ERROR,
			                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
			                        errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
										"Parameter %d (\"%s\"): Data type 0x%02X is unknown.",
			                                paramOrdinal, temp->paramMeta.colName.data, tdsType)));
		}
		tempFuncInfo = TdsLookupTypeFunctionsByTdsId(tdsType, temp->maxLen);

		/*
		 * We save the recvFunc address here, so that during the bind we can directly
		 * use the recv function and save one extra lookup.  We also store the sender
		 * sendFunc address here which can be used to send back OUT parameters.
		 */
		SetParamMetadataCommonInfo(&(temp->paramMeta), tempFuncInfo);

		/* Explicity retrieve the oid for TVP type and map it. */
		if (temp->paramMeta.pgTypeOid == InvalidOid && tdsType == TDS_TYPE_TABLE)
		{
			int rc;
			HeapTuple                               row;
			bool isnull;
			TupleDesc tupdesc;
			char * query;

			StartTransactionCommand();
			PushActiveSnapshot(GetTransactionSnapshot());
			if ((rc = SPI_connect()) < 0)
				elog(ERROR, "SPI_connect() failed in TDS Listener "
											"with return code %d", rc);

			query = psprintf("SELECT '%s'::regtype::oid", temp->tvpInfo->tvpTypeName);

			rc = SPI_execute(query, false, 1);
			if(rc != SPI_OK_SELECT)
				elog(ERROR, "Failed to insert in the underlying table for table-valued parameter: %d", rc);

			tupdesc = SPI_tuptable->tupdesc;
			row = SPI_tuptable->vals[0];

			temp->paramMeta.pgTypeOid = DatumGetObjectId(SPI_getbinval(row, tupdesc,
																					1, &isnull));

			SPI_finish();
			PopActiveSnapshot();
			CommitTransactionCommand();
		}

		temp->next = NULL;
		if (prev == NULL)
		{
			prev = temp;
			request->parameter = temp;
		}
		else
		{
			prev->next = temp;
			prev = temp;
		}
              *parameterCount += 1;
	}
	/*
	 * We set the flag for offset as an invalid value so as to
	 * to execute the Flush phase in TdsSocketBackend.
	 */
	request->batchSeparatorOffset = message->len;
	return STATUS_OK;
}

/*
 * GetSPCursorHandleParameter - Generate or fetch the cursor handle parameter for a
 * SP_CURSOR* request.
 */
static void
GetSPCursorHandleParameter(TDSRequestSP request)
{
	switch(request->spType)
	{
		case SP_CURSORPREPEXEC:
		case SP_CURSOREXEC:
		case SP_CURSOROPEN:
			break;
		case SP_CURSORFETCH:
		case SP_CURSORCLOSE:
		case SP_CURSOR:
		case SP_CURSOROPTION:
			{
				/* Fetch the handle from the request */
				ParameterToken token = request->cursorHandleParameter;

				/* handle must exist */
				Assert(token);

				/* the token must be integer */
				Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
					   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

				memcpy(&request->cursorHandle, &request->messageData[token->dataOffset],
					   sizeof(uint32));

				/* the handle must be valid */
				if (request->cursorHandle == SP_CURSOR_HANDLE_INVALID)
					ereport(ERROR,
                                                        (errcode(ERRCODE_UNDEFINED_OBJECT),
                                                         errmsg("cursor %d doesn't exist", request->cursorHandle)));

			}
			break;
		case SP_CURSORUNPREPARE:
		case SP_CURSORPREPARE:
		case SP_PREPARE:
		case SP_PREPEXEC:
		case SP_PREPEXECRPC:
		case SP_EXECUTE:
		case SP_UNPREPARE:
		case SP_CUSTOMTYPE:
		case SP_EXECUTESQL:
			request->cursorHandle = SP_CURSOR_HANDLE_INVALID;
			break;
		default:
			Assert(0);
	}
}

/*
 * GetSPCursorPreparedHandleParameter - Generate or fetch the handle parameter
 * for a SP_CURSOR_[PREPEXEC/EXEC] request.
 */
static void
GetSPCursorPreparedHandleParameter(TDSRequestSP request)
{
	switch(request->spType)
	{
		case SP_CURSORPREPEXEC:
		case SP_CURSOROPEN:
		case SP_CURSORFETCH:
		case SP_CURSORCLOSE:
		case SP_CURSOR:
		case SP_CURSOROPTION:
		case SP_CUSTOMTYPE:
		case SP_EXECUTESQL:
		case SP_PREPARE:
		case SP_PREPEXEC:
		case SP_EXECUTE:
		case SP_PREPEXECRPC:
		case SP_UNPREPARE:
			/* handle will be retrieved from babelfishpg_tsql extension */
			request->cursorPreparedHandle = SP_CURSOR_PREPARED_HANDLE_INVALID;
			break;
		case SP_CURSOREXEC:
		case SP_CURSORUNPREPARE:
		case SP_CURSORPREPARE:
			{
				/* Fetch the handle from the request */
				ParameterToken token = request->cursorPreparedHandleParameter;

				/* handle must exist */
				Assert(token);

				/* the token must be integer */
				Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
					   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

				memcpy(&request->cursorPreparedHandle, &request->messageData[token->dataOffset],
					   sizeof(uint32));

				/* the handle must be valid */
				Assert(request->cursorPreparedHandle != SP_CURSOR_PREPARED_HANDLE_INVALID);

			}
			break;
		default:
			Assert(0);
	}
}

/*
 * GetSPHandleParameter - Generate or fetch the handle parameter for a SP_*
 * request.
 */
static void
GetSPHandleParameter(TDSRequestSP request)
{
	switch(request->spType)
	{
		case SP_CURSORPREPARE:
		case SP_CURSORPREPEXEC:
		case SP_CURSOREXEC:
		case SP_CURSOROPEN:
		case SP_CURSORFETCH:
		case SP_CURSORCLOSE:
		case SP_CURSOR:
		case SP_CURSOROPTION:
		case SP_CURSORUNPREPARE:
		case SP_CUSTOMTYPE:
		case SP_EXECUTESQL:
		case SP_PREPARE:
		case SP_PREPEXEC:
		case SP_PREPEXECRPC:
			/* handle will be retrieved from babelfishpg_tsql extension */
			request->handle = SP_HANDLE_INVALID;
			break;
		case SP_EXECUTE:
		case SP_UNPREPARE:
			{
				/* Fetch the handle from the request */
				ParameterToken token = request->handleParameter;

				/* handle must exist */
				Assert(token);

				/* the token must be integer */
				Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
					   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

				memcpy(&request->handle, &request->messageData[token->dataOffset],
					   sizeof(uint32));

				/* the handle must be valid */
				Assert(request->handle != SP_HANDLE_INVALID);

			}
			break;
		default:
			Assert(0);
	}
}

/*
 * FillStoredProcedureCallFromParameterToken - construct a query string in the
 * following format:
 *
 * if tsql dialect, then
 * EXECUTE <procedurename> @P0, @P1, ....
 * or
 * EXECUTE <procedurename> @param1 = @param1, @param2 = @param2, ....
 *
 * XXX: The format @param1 = @param1 is not currently supported for UDFs in
 * Babel.  Once we support that feature, we need to build the string format
 * accordingly.  Currently, it's commented out.
 */
static inline void
FillStoredProcedureCallFromParameterToken(TDSRequestSP req, StringInfo inBuf)
{
	int			paramno;
	int			numParams;
	ParameterToken		token = NULL;
	StringInfo			name;

	Assert(req->queryParameter == NULL);

	numParams = req->nTotalParams;

	if (sql_dialect != SQL_DIALECT_TSQL)
		elog(ERROR, "sql dialect is not set to TSQL");

	paramno = 0;
	appendStringInfo(inBuf, "EXECUTE @p%d = %s ", paramno, req->name.data);
	paramno++;

	if (numParams > 0)
	{
		token = req->dataParameter;
		name = &(token->paramMeta.colName);

		if (name->len == 0)
			appendStringInfo(inBuf, "@p%d", paramno);
		else
			appendStringInfo(inBuf, "%s = %s", name->data, name->data);
		/* If this is an OUT parameter, mark it */
		if(token->flags & SP_FLAGS_BYREFVALUE)
			appendStringInfo(inBuf, " OUT");
		token = token->next;
		paramno++;
	}

	for (; token != NULL; token = token->next)
	{
		name = &(token->paramMeta.colName);

		if (name->len == 0)
			appendStringInfo(inBuf, ", @P%d", paramno);
		else
			appendStringInfo(inBuf, ", %s = %s", name->data, name->data);
		/* If this is an OUT parameter, mark it */
		if(token->flags & SP_FLAGS_BYREFVALUE)
			appendStringInfo(inBuf, " OUT");
		paramno++;
	}

	appendStringInfoCharMacro(inBuf, '\0');
}

/*
 * GetQueryFromParameterToken - extract the query from parameter token
 *
 */
static inline void
FillQueryFromParameterToken(TDSRequestSP req, StringInfo inBuf)
{
	ParameterToken token = req->queryParameter;

	TdsReadUnicodeDataFromTokenCommon(req->messageData, token, inBuf);
	appendStringInfoCharMacro(inBuf, '\0');
}

/*
 * InitializeDataParamTokenIndex - initialize the IN/OUT parameter index array
 */
static inline void
InitializeDataParamTokenIndex(TDSRequestSP request)
{
	ParameterToken 	token;
	uint16			idOutParam = 0;
	int32			paramCount = 0;

	request->nOutParams = 0;
	request->idxOutParams = NULL;

	for (token = request->dataParameter; token != NULL; token = token->next)
	{
		request->nTotalParams++;

		if ((token->flags & 0x01) ==  1)
			request->nOutParams++;
	}

	/* Allocate the memory for OUT parameter array. */
	if (request->nOutParams > 0)
		request->idxOutParams = palloc(request->nOutParams
									   * sizeof(ParameterToken));

	/*
	 * Store all OUT parameters together.
	 */
	for (token = request->dataParameter; token != NULL; token = token->next)
	{

		if ((token->flags & 0x01) ==  1)
			request->idxOutParams[idOutParam++] = token;
		paramCount++;
	}

	Assert(request->nOutParams == idOutParam);
}

static inline void
FillOidsFromParameterToken(TDSRequestSP req, StringInfo inBuf)
{
	ParameterToken 	token;

	/* store num of data params amd their oids */
	enlargeStringInfo(inBuf, sizeof(uint16)
					  + req->nTotalParams * sizeof(Oid));

	pq_writeint16(inBuf, req->nTotalParams);

	for (token = req->dataParameter; token != NULL; token = token->next)
	{
		uint32 paramType = (uint32) token->paramMeta.pgTypeOid;
		pq_writeint32(inBuf, paramType);
	}
}

static inline void
FillColumnInfoFromParameterToken(TDSRequestSP req, StringInfo inBuf)
{
	/*
	 * 1. store num of data params amd their formats
	 *
	 * TODO: For now, we set this to zero to indicate that there are no
	 * parameters or that the parameters all use the default format (text).
	 */
	enlargeStringInfo(inBuf, sizeof(uint16));

	pq_writeint16(inBuf, 0);

	/* 2. store num of data params */
	enlargeStringInfo(inBuf, sizeof(uint16));
	pq_writeint16(inBuf, req->nTotalParams);
}

static inline Portal
GetPortalFromCursorHandle(const int portalHandle, bool missingOk)
{
	Portal		portal;
	char		cursorHandle[INT32_STRLEN];

	snprintf(cursorHandle, INT32_STRLEN, "%d", portalHandle);

	portal = GetPortalByName(cursorHandle);

	if (!missingOk && !PortalIsValid(portal))
		elog(ERROR, "portal \"%s\" does not exist", cursorHandle);

	return portal;
}

static inline void
FetchCursorOptions(TDSRequestSP req)
{
	ParameterToken token;

	token = req->cursorExtraArg1;
	Assert(token);

	/* the token must be integer */
	Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
		   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

	memcpy(&req->scrollopt, &req->messageData[token->dataOffset],
		   sizeof(uint32));

	token = req->cursorExtraArg2;
	Assert(token);

	/* the token must be integer */
	Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
		   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

	memcpy(&req->ccopt, &req->messageData[token->dataOffset],
		   sizeof(uint32));

}

static int
SetCursorOption(TDSRequestSP req)
{

	int				curoptions = 0;

	/* we're always going to fetch in binary format */
	curoptions = CURSOR_OPT_BINARY;

	/*
	 * XXX: For now, map STATIC cursor to WITH HOLD cursor option.  It materializes
	 * the result in a temp file when the transaction is closed.  But, a STATIC
	 * cursor should also return the number of tuples in the result set.  We've
	 * not implemented that yet.
	 */
	if (req->scrollopt & SP_CURSOR_SCROLLOPT_STATIC)
		curoptions |= CURSOR_OPT_HOLD;
	else if ((req->ccopt & SP_CURSOR_SCROLLOPT_CHECK_ACCEPTED_TYPES) &&
			 (req->ccopt & SP_CURSOR_SCROLLOPT_STATIC_ACCEPTABLE))
		curoptions |= CURSOR_OPT_HOLD;

	if (req->scrollopt & SP_CURSOR_SCROLLOPT_FORWARD_ONLY)
		curoptions |= CURSOR_OPT_NO_SCROLL;
	else if ((req->ccopt & SP_CURSOR_SCROLLOPT_CHECK_ACCEPTED_TYPES) &&
			 (req->ccopt & SP_CURSOR_SCROLLOPT_FORWARD_ONLY_ACCEPTABLE))
		curoptions |= CURSOR_OPT_NO_SCROLL;
	else
		curoptions |= CURSOR_OPT_SCROLL;

	return curoptions;
}

/*
 * Send the Cursor Response:
 * Only for sp_cursorprepexec, we send the handle for the prepared statement
 * otherwise this is common to sp_cursoropen, sp_cursorprepexec, sp_cursorexec
 */
static void
SendCursorResponse(TDSRequestSP req)
{
	int		cmd_type = TDS_CMD_UNKNOWN;
	Portal  portal;

	/* fetch the portal */
	portal = GetPortalFromCursorHandle(req->cursorHandle, false);

	/*
	 * If we are in aborted transaction state, we can't run
	 * PrepareRowDescription(), because that needs catalog accesses.
	 * Hence, refuse to Describe portals that return data.
	 */
	if (IsAbortedTransactionBlockState() &&
		portal->tupDesc)
		elog(ERROR, "current transaction is aborted, "
						"commands ignored until end of transaction block");

	if (portal->commandTag && portal->commandTag == CMDTAG_SELECT)
	{
		cmd_type = TDS_CMD_SELECT;
	}
	else
	{
		elog(ERROR, "TDS: unhandled cursor completionTag '%s'",
			 portal->commandTag ? GetCommandTagName(portal->commandTag) : "<empty>");
		cmd_type = TDS_CMD_UNKNOWN;
	}

	/*
	 * First get all the information needed to construct the tokens.  We don't
	 * want to throw error in the middle of sending the response.  That'll
	 * break the protocol.  We also need to fetch the primary keys for dynamic
	 * and keyset cursors (XXX: these cursors are not yet implemented).
	 */
	PrepareRowDescription(portal->tupDesc, FetchPortalTargetList(portal),
							   portal->formats, true,
							   (req->scrollopt & (SP_CURSOR_SCROLLOPT_DYNAMIC | SP_CURSOR_SCROLLOPT_KEYSET)));

	/* Send COLMETADATA token, TABNAME token and COLINFO token */
	SendColumnMetadataToken(portal->tupDesc->natts, true /* send ROWSTAT column */);
	SendTabNameToken();
	SendColInfoToken(portal->tupDesc->natts, true /* send ROWSTAT column */);

	TdsSendDone(TDS_TOKEN_DONEINPROC, TDS_DONE_MORE, cmd_type, 0);

	/*
	 * return codes - procedure executed successfully (0)
	 *
	 * XXX: How to implement other return codes related to different error scenarios?
	 */
	TdsSendReturnStatus(0);

	/*
	 * Send the handle for the PrePared Plan only for the
	 * sp_cursorprepexec request
	 *
	 */
	if (req->spType == SP_CURSORPREPEXEC)
		SendReturnValueTokenInternal(req->cursorPreparedHandleParameter, 0x01, NULL,
									 UInt32GetDatum(req->cursorPreparedHandle), false, false);

	/* send the cursor handle */
	SendReturnValueTokenInternal(req->cursorHandleParameter, 0x01, NULL,
								 UInt32GetDatum(req->cursorHandle), false, false);

	/*
	 * If the scrollopt value is not appropriate for the cursor w.r.t the sql statement,
	 * the engine can override the scrollopt value.
	 * TODO: Implement this feature in the engine.  Currently, PG engine doesn't have
	 * a way to modify the input value.  For now, just return the input value.
	 */
	if (req->cursorExtraArg1 && (req->cursorExtraArg1->flags & 0x01) == 1)
		SendReturnValueTokenInternal(req->cursorExtraArg1, 0x01, NULL,
									 UInt32GetDatum((int) req->scrollopt), false, false);

	/*
	 * If the ccopt value is not appropriate for the cursor w.r.t the sql statement,
	 * the engine can override the ccopt value.
	 * TODO: Implement this feature in the engine.  Currently, PG engine doesn't have
	 * a way to modify the input value.  For now, just return the input value.
	 */
	if (req->cursorExtraArg2 && (req->cursorExtraArg2->flags & 0x01) == 1)
		SendReturnValueTokenInternal(req->cursorExtraArg2, 0x01, NULL,
									 UInt32GetDatum((int) req->ccopt), false, false);

	/*
	 * If the cursor is populated as part of sp_cursoropen request packet (STATIC,
	 * INSENSITIVE cursors), then we should return the actual number of rows in
	 * the result set.  For dynamic cursors, we should return -1.  Ideally, we should
	 * fetch the correct value from @@CURSOR_ROWS global variable.
	 *
	 * TODO: Implement @@CURSOR_ROWS global variable.  As part of that implementation,
	 * we should check how to get the correct number of rows without fetching anything
	 * from the cursor.  For now, always send -1 and hope the client driver doesn't
	 * complain.
	 */
	if (req->cursorExtraArg3 && (req->cursorExtraArg3->flags & 0x01) == 1)
		SendReturnValueTokenInternal(req->cursorExtraArg3, 0x01, NULL,
									 UInt32GetDatum((int) -1), false, false);

	/*
	 * command type - execute (0xe0)
	 */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);
}

static void
HandleSPCursorOpenCommon(TDSRequestSP req)
{
	int curoptions = 0;
	int ret;
	StringInfoData buf;

	TdsErrorContext->err_text = "Processing SP_CURSOROPEN Common Request";
	/* fetch cursor options */
	FetchCursorOptions(req);

	curoptions = SetCursorOption(req);

	TDSStatementBeginCallback(NULL, NULL);

	PG_TRY();
	{
		if (req->spType == SP_CURSOREXEC)
		{
			char *activity = psprintf("SP_CURSOREXEC Handle: %d", (int)req->cursorPreparedHandle);
			pgstat_report_activity(STATE_RUNNING, activity);
			pfree(activity);

			ret = pltsql_plugin_handler_ptr->sp_cursorexecute_callback((int)req->cursorPreparedHandle, (int *)&req->cursorHandle, &req->scrollopt, &req->ccopt,
																	   NULL /* TODO row_count */, req->nTotalParams, req->boundParamsData, req->boundParamsNullList);
		}

		else
		{
			char *activity;
			initStringInfo(&buf);
			/* fetch the query */
			FillQueryFromParameterToken(req, &buf);

			switch (req->spType)
			{
			case SP_CURSOROPEN:
				activity = psprintf("SP_CURSOROPEN: %s", buf.data);
				pgstat_report_activity(STATE_RUNNING, activity);
				pfree(activity);

				ret = pltsql_plugin_handler_ptr->sp_cursoropen_callback((int *)&req->cursorHandle, buf.data, &req->scrollopt, &req->ccopt,
																		NULL /* TODO row_count */, req->nTotalParams, req->boundParamsData, req->boundParamsNullList);
				break;
			case SP_CURSORPREPARE:
				activity = psprintf("SP_CURSORPREPARE: %s", buf.data);
				pgstat_report_activity(STATE_RUNNING, activity);
				pfree(activity);

				ret = pltsql_plugin_handler_ptr->sp_cursorprepare_callback((int *)&req->cursorPreparedHandle, buf.data, curoptions, &req->scrollopt, &req->ccopt,
																		   (int)req->nTotalBindParams, req->boundParamsOidList);
				break;
			case SP_CURSORPREPEXEC:
				activity = psprintf("SP_CURSORPREPEXEC: %s", buf.data);
				pgstat_report_activity(STATE_RUNNING, activity);
				pfree(activity);

				ret = pltsql_plugin_handler_ptr->sp_cursorprepexec_callback((int *)&req->cursorPreparedHandle, (int *)&req->cursorHandle, buf.data, curoptions, &req->scrollopt, &req->ccopt,
																			NULL /* TODO row_count */, req->nTotalParams, (int)req->nTotalBindParams, req->boundParamsOidList, req->boundParamsData, req->boundParamsNullList);
				break;
			default:
				Assert(0);
			}

			if (ret > 0)
				ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
								errmsg("sp_cursoropen failed: %d", ret)));

		}

		MemoryContextSwitchTo(MessageContext);
	}

	PG_CATCH();
	{
		TDSLogStatementCursorHandler(req, buf.data, PRINT_BOTH_CURSOR_HANDLE);
		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* Send the response now */
	SendCursorResponse(req);

	/* Log immediately if dictated by log_statement and log_duration */
	TDSLogStatementCursorHandler(req, buf.data, PRINT_BOTH_CURSOR_HANDLE);
}

/*
 * TODO: can be reused this for prepare-exec
 */
static void
GenerateBindParamsData(TDSRequestSP req)
{
	uint16_t count = 0;
	ParameterToken tempBindParam;
	bool		isNull;
	TdsIoFunctionInfo tempFuncInfo;
	Oid			ptype;
	Datum		pval;

	TdsErrorContext->err_text = "Generating Bind Parameters' Data";
	tempBindParam = req->dataParameter;

	while (tempBindParam != NULL)
	{
		count++;
		tempBindParam = tempBindParam->next;
	}

	req->nTotalBindParams = count;

	/* If count == 0, then there is no bind Parameter */
	if (count == 0)
	{
		req->boundParamsData = NULL;
		req->boundParamsNullList = NULL;
		req->boundParamsOidList = NULL;
		return;
	}
	req->boundParamsData = palloc0(sizeof(Datum) * count);
	req->boundParamsNullList = palloc0(sizeof(char) * count);
	req->boundParamsOidList = palloc0(sizeof(Oid) * count);

	tempBindParam = req->dataParameter;

	count = 0;
	while (tempBindParam != NULL)
	{

		tempFuncInfo = TdsLookupTypeFunctionsByTdsId(tempBindParam->type,
									tempBindParam->maxLen);
		isNull = tempBindParam->isNull;

		ptype = tempBindParam->paramMeta.pgTypeOid;

		if (!isNull)
			pval = tempFuncInfo->recvFuncPtr(req->messageData, tempBindParam);
		else
			pval = (Datum) 0;

		req->boundParamsData[count] = pval;
		req->boundParamsNullList[count] = (isNull) ? 'n' : ' ';
		req->boundParamsOidList[count] = ptype;

		count++;
		tempBindParam = tempBindParam->next;
	}
}

static void
FetchAndValidateCursorFetchOptions(TDSRequestSP req, int *fetchType,
								   int *rownum, int *howMany)
{
	ParameterToken 	token;

	token = req->cursorExtraArg1;
	Assert(token);

	/* the token must be integer */
	Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
		   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

	memcpy(fetchType, &req->messageData[token->dataOffset], sizeof(uint32));

	switch(*fetchType)
	{
		case SP_CURSOR_FETCH_FIRST:
		case SP_CURSOR_FETCH_NEXT:
		case SP_CURSOR_FETCH_PREV:
		case SP_CURSOR_FETCH_LAST:
		case SP_CURSOR_FETCH_ABSOLUTE:
			break;
		/*
		 * The following cursor options are not supported in postgres.  Although
		 * postgres supports the relative cursor fetch option, but the behaviour
		 * in TDS protocol is very different from postgres.
		 */
		case SP_CURSOR_FETCH_RELATIVE:
		case SP_CURSOR_FETCH_REFRESH:
		case SP_CURSOR_FETCH_INFO:
		case SP_CURSOR_FETCH_PREV_NOADJUST:
		case SP_CURSOR_FETCH_SKIP_UPDT_CNCY:
			ereport(ERROR,
                                        (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                                         errmsg("cursor fetch type %X not supported", *fetchType)));
			break;
		default:
			ereport(ERROR,
                                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                                         errmsg("invalid cursor fetch type %X", *fetchType)));
	}

	token = req->cursorExtraArg2;

	if (token)
	{
		/* the token must be integer */
		Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
			   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

		memcpy(rownum, &req->messageData[token->dataOffset], sizeof(uint32));

		/*
		 * Rownum is used to specify the row position for the ABSOLUTE and INFO
		 * fetchtype.  And, it serves as the row offset for the fetchtype bit
		 * value RELATIVE.  It is ignored for all other values.
		 */
		if (*fetchType != SP_CURSOR_FETCH_ABSOLUTE &&
			*fetchType != SP_CURSOR_FETCH_RELATIVE &&
			*fetchType != SP_CURSOR_FETCH_INFO)
			*rownum = -1;

	}
	else
		*rownum = -1;

	token = req->cursorExtraArg3;

	if (token)
	{
		/* the token must be integer */
		Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
			   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

		memcpy(howMany, &req->messageData[token->dataOffset], sizeof(uint32));

		/*
		 * For the fetchtype values of NEXT, PREV, ABSOLUTE, RELATIVE, and
		 * PREV_NOADJUST, an nrow value of 0 is not valid.
		 */
		if (*howMany == 0)
		{
			if (*fetchType == SP_CURSOR_FETCH_NEXT ||
				*fetchType == SP_CURSOR_FETCH_PREV ||
				*fetchType == SP_CURSOR_FETCH_ABSOLUTE ||
				*fetchType == SP_CURSOR_FETCH_RELATIVE ||
				*fetchType == SP_CURSOR_FETCH_PREV_NOADJUST)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("invalid nrow value 0 for cursor type %X", *fetchType)));
		}
	}
	else
	{
		/* If nrows is not specified, the default value is 20 rows. */
		*howMany = 20;
	}
}

static void
HandleSPCursorFetchRequest(TDSRequestSP req)
{
	int ret;
	int fetchType;
	int rownum;
	int nrows;
	char *activity = psprintf("SP_CURSORFETCH Handle: %d", (int)req->cursorHandle);

	TdsErrorContext->err_text = "Processing SP_CURSORFETCH Request";
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	FetchAndValidateCursorFetchOptions(req, &fetchType, &rownum, &nrows);

	TDSStatementBeginCallback(NULL, NULL);

	PG_TRY();
	{
		ret = pltsql_plugin_handler_ptr->sp_cursorfetch_callback((int)req->cursorHandle, &fetchType, &rownum, &nrows);
		MemoryContextSwitchTo(MessageContext);

		if (ret > 0)
			ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("sp_cursorfetch failed: %d", ret)));
	}

	PG_CATCH();
	{
		TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	TdsSendDone(TDS_TOKEN_DONEINPROC, TDS_DONE_MORE, TDS_CMD_SELECT, SPI_processed);

	/* for success, the return status is 0 */
	TdsSendReturnStatus(0);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/* Log immediately if dictated by log_statement and log_duration */
	TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
}

static void
HandleSPCursorCloseRequest(TDSRequestSP req)
{
	int ret;
	char *activity = psprintf("SP_CURSORCLOSE Handle: %d", (int)req->cursorHandle);

	TdsErrorContext->err_text = "Processing SP_CURSORCLOSE Request";
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);
	TDSStatementBeginCallback(NULL, NULL);

	/* close the cursor */
	PG_TRY();
	{
		ret = pltsql_plugin_handler_ptr->sp_cursorclose_callback((int)req->cursorHandle);
		MemoryContextSwitchTo(MessageContext);

		if (ret > 0)
			ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("sp_cursorclose failed: %d", ret)));
	}

	PG_CATCH();
	{
		TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* for success, the return status is 0 */
	TdsSendReturnStatus(0);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/* Log immediately if dictated by log_statement and log_duration */
	TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
}

static void
HandleSPCursorUnprepareRequest(TDSRequestSP req)
{
	int ret;
	char *activity = psprintf("SP_CURSORUNPREPARE Handle: %d", (int)req->cursorPreparedHandle);

	TdsErrorContext->err_text = "Processing SP_CURSORUNPREPARE Request";
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);
	TDSStatementBeginCallback(NULL, NULL);

	/* close the cursor */
	PG_TRY();
	{
		ret = pltsql_plugin_handler_ptr->sp_cursorunprepare_callback((int)req->cursorPreparedHandle);
		MemoryContextSwitchTo(MessageContext);

		if (ret > 0)
			ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("sp_cursorunprepare failed: %d", ret)));
	}

	PG_CATCH();
	{
		TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* for success, the return status is 0 */
	TdsSendReturnStatus(0);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);
	
	/* Log immediately if dictated by log_statement and log_duration */
	TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
}

static void
HandleSPCursorOptionRequest(TDSRequestSP req)
{
	int ret;
	ParameterToken token;
	int code;
	int value;

	char *activity = psprintf("SP_CURSOROPTION Handle: %d", (int)req->cursorHandle);
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	TDSStatementBeginCallback(NULL, NULL);

	token = req->cursorExtraArg1;

	if (token)
	{
		/* the token must be integer */
		Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
			   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

		memcpy(&code, &req->messageData[token->dataOffset], sizeof(uint32));
	}

	token = req->cursorExtraArg2;

	if (token)
	{
		/* the token must be integer */
		Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
			   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

		memcpy(&value, &req->messageData[token->dataOffset], sizeof(uint32));
	}

	PG_TRY();
	{
		ret = pltsql_plugin_handler_ptr->sp_cursoroption_callback((int)req->cursorHandle, code, value);
		MemoryContextSwitchTo(MessageContext);

		if (ret > 0)
			ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("sp_cursoroption failed: %d", ret)));
	}

	PG_CATCH();
	{
		TDSLogStatementCursorHandler(req, req->messageData, PRINT_PREPARED_CURSOR_HANDLE);
		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* for success, the return status is 0 */
	TdsSendReturnStatus(0);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/* Log immediately if dictated by log_statement and log_duration */
	TDSLogStatementCursorHandler(req, req->messageData, PRINT_PREPARED_CURSOR_HANDLE);
}

static void
HandleSPCursorRequest(TDSRequestSP req)
{
	int ret;
	List *values = NIL;
	int i;
	ParameterToken token;
	int optype;
	int rownum;

	pgstat_report_activity(STATE_RUNNING, "SP_CURSOR");
	for (i = 0; i < req->nTotalBindParams; i++)
		values = lappend(values, &req->boundParamsData[i]);

	TDSStatementBeginCallback(NULL, NULL);

	token = req->cursorExtraArg1;

	if (token)
	{
		/* the token must be integer */
		Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
			   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

		memcpy(&optype, &req->messageData[token->dataOffset], sizeof(uint32));
	}

	token = req->cursorExtraArg2;

	if (token)
	{
		/* the token must be integer */
		Assert(token->paramMeta.metaLen == sizeof(token->paramMeta.metaEntry.type1) &&
			   token->paramMeta.metaEntry.type1.tdsTypeId == TDS_TYPE_INTEGER);

		memcpy(&rownum, &req->messageData[token->dataOffset], sizeof(uint32));
	}

	PG_TRY();
	{
		StringInfo buf = makeStringInfo();
		ParameterToken token = req->cursorExtraArg3;

		TdsReadUnicodeDataFromTokenCommon(req->messageData, token, buf);
		appendStringInfoCharMacro(buf, '\0');

		ret = pltsql_plugin_handler_ptr->sp_cursor_callback((int)req->cursorHandle, optype, rownum, buf->data, values);
		MemoryContextSwitchTo(MessageContext);

		if (ret > 0)
			ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("sp_cursor failed: %d", ret)));
	}

	PG_CATCH();
	{
		TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
		TDSStatementExceptionCallback(NULL, NULL, false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	TDSStatementEndCallback(NULL, NULL);

	/* for success, the return status is 0 */
	TdsSendReturnStatus(0);

	/* command type - execute (0xe0) */
	TdsSendDone(TDS_TOKEN_DONEPROC, TDS_DONE_FINAL, 0xe0, 0);

	/* Log immediately if dictated by log_statement and log_duration */
	TDSLogStatementCursorHandler(req, req->messageData, PRINT_CURSOR_HANDLE);
}

TDSRequest
GetRPCRequest(StringInfo message)
{
	TDSRequestSP		request;
	uint64_t 		offset = 0;
	uint16_t 		len = 0;
	int 			messageLen = 0;
	int 			parameterCount = 0;
	uint32_t 			tdsVersion = GetClientTDSVersion();

	TdsErrorContext->err_text = "Fetching RPC Request";
	/*
	 * In the ALL_HEADERS rule, the Query Notifications header and the Transaction
	 * Descriptor header were introduced in TDS 7.2. We need to to Process them only
	 * for TDS versions more than or equal to 7.2, otherwise we do not increment the offset.
	 */
	if (tdsVersion > TDS_VERSION_7_1_1)
		offset = ProcessStreamHeaders(message);

	/* Build return structure */
	if(TdsRequestCtrl->request != NULL && RPCBatchExists(TdsRequestCtrl->request->sp))
	{
		/*
		 * If previously an RPC batch separator was found and if another RPC is left to process
		 * then we set the offset to the first byte of the next RPC packet
		 * and use the existing request after initialising.
		 */
		offset = TdsRequestCtrl->request->sp.batchSeparatorOffset;
		messageLen = TdsRequestCtrl->request->sp.messageLen;
		request = &TdsRequestCtrl->request->sp;
		memset(request, 0, sizeof(TDSRequestSPData));
		request->messageLen = messageLen;
	}
	else
		request = palloc0(sizeof(TDSRequestSPData));

	request->reqType = TDS_REQUEST_SP_NUMBER;
	memcpy(&len, &(message->data[offset]), sizeof(len));
	/*
	 * initStringInfo even if len is 0, so that
	 * the processing logic can check the length field from
	 * request.name->len
	 */
	initStringInfo(&request->name);
	offset += sizeof(len); /* Procedure name len */

	/*
	 * The RPC packet will contain the SP name
	 * (dotnet SP) or will contain the TDS spec
	 * defined SPType (prep-exec, Java SP)
	 */
	if (len != 0xffff)
	{
		TdsUTF16toUTF8StringInfo(&request->name, &(message->data[offset]), 2 * len);
		offset += 2 * len;
		request->spType = SP_CUSTOMTYPE;
	}
	else
	{
		memcpy(&request->spType, &(message->data[offset]), sizeof(request->spType));
		offset += sizeof(request->spType);
	}

	request->isStoredProcedure = false;
	request->metaDataParameterValue = makeStringInfo();

	memcpy(&request->spFlags, &(message->data[offset]), sizeof(request->spFlags));
	offset += sizeof(request->spFlags);

	/*
	 * Store the address of message data, so that
	 * the Process step can fetch it
	 */
	request->messageData = message->data;

	if (ReadParameters(request, offset, message, &parameterCount) != STATUS_OK)
		elog(FATAL, "corrupted TDS_RPC message - "
					"offset beyond the message length");
	/*Initialise*/
	InitialiseParameterToken(request);

	/* TODO: SP might need special handling, this is only for prep-exec */
	switch (request->spType)
	{
		case SP_CURSOROPEN:
			{
				TdsErrorContext->spType = "SP_CURSOROPEN";
				TDSInstrumentation(INSTR_TDS_SP_CURSOR_OPEN);
				/*
				 *
				 * The order of the parameter is cursor handle, cursor statement,
				 * scrollopt, ccopt, rowcount and boundparams.  Cursor handle
				 * and statement are mandatory, the rest are optional parameters.
				 * If one optional parameter exists, all previous optional parameter
				 * must be there in the packet.
				 */
				if (unlikely(parameterCount < 2))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 2)));
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor handle", "integer")));
				request->cursorHandleParameter = request->parameter;
				if (unlikely(!request->parameter->next))
					ereport(ERROR,
                                                        (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                                                         errmsg("%s parameter should not be null", "Query")));
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter->next) != TDS_TYPE_NVARCHAR &&
					FetchDataTypeNameFromParameter(request->parameter->next) != TDS_TYPE_NTEXT))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));
				request->queryParameter = request->parameter->next;

				/*
				 * ExtraArg1 = scrollopt
				 * ExtraArg2 = ccopt
				 * ExtraArg3 = Rowcount
				 * dataParameter = boundparams
				 */
				request->cursorExtraArg1 = request->queryParameter->next;

				if (request->cursorExtraArg1)
				{
					request->cursorExtraArg2 = request->cursorExtraArg1->next;

					if (request->cursorExtraArg2)
					{
						request->cursorExtraArg3 = request->cursorExtraArg2->next;

						if (request->cursorExtraArg3->next != NULL)
						{
							TdsReadUnicodeDataFromTokenCommon(message->data,
														request->cursorExtraArg3->next,
														request->metaDataParameterValue);
							request->dataParameter = request->cursorExtraArg3->next->next;
						}
					}
				}
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursoropen");
			}
			break;
		case SP_CURSOREXEC:
			{
				TdsErrorContext->spType = "SP_CURSOREXEC";
				TDSInstrumentation(INSTR_TDS_SP_CURSOR_EXEC);
				if (unlikely(parameterCount < 2))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 2)));
				/*
				 * 1. Cursor prepared Handle parameter (mandatory)
				 * 2. Cursor parameter	(mandatory)
				 * 3. ExtraArg1 = scrollopt
				 * 4. ExtraArg2 = ccopt
				 * 5. ExtraArg3 = Rowcount
				 * 6. dataParameter = boundparams
				 */
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor prepared handle", "integer")));
				request->cursorPreparedHandleParameter = request->parameter;
				if (unlikely(!request->cursorPreparedHandleParameter->next))
					ereport(ERROR,
                                                        (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                                                         errmsg("%s parameter should not be null", "Cursor handle")));
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorPreparedHandleParameter->next) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor handle", "integer")));
				request->cursorHandleParameter = request->cursorPreparedHandleParameter->next;

				if (request->cursorHandleParameter)
				{
					request->cursorExtraArg1 =
						request->cursorHandleParameter->next;
					if (request->cursorExtraArg1)
					{
						request->cursorExtraArg2 =
							request->cursorExtraArg1->next;
						if (request->cursorExtraArg2)
						{
							request->cursorExtraArg3 =
								request->cursorExtraArg2->next;
							if (request->cursorExtraArg3)
								request->dataParameter =
									request->cursorExtraArg3->next;
						}
					}
				}
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursorexec");
			}
			break;
		case SP_CURSORPREPEXEC:
			{
				TdsErrorContext->spType = "SP_CURSORPREPEXEC";
				TDSInstrumentation(INSTR_TDS_SP_CURSOR_PREPEXEC);

                              if (unlikely(parameterCount < 3))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 3)));
				/*
				 * 1. Cursor prepared Handle parameter (mandatory)
				 * 2. Cursor parameter (mandatory)
				 * 3. query parameter (mandatory)
				 * 4. ExtraArg1 = scrollopt
				 * 5. ExtraArg2 = ccopt
				 * 6. ExtraArg3 = Rowcount
				 * 7. dataParameter = boundparams
				 */

				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor prepared handle", "integer")));
				request->cursorPreparedHandleParameter = request->parameter;
				if (unlikely(!request->cursorPreparedHandleParameter->next))
					ereport(ERROR,
                                                        (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                                                         errmsg("%s parameter should not be null", "Cursor handle")));
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorPreparedHandleParameter->next) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor handle", "integer")));
				request->cursorHandleParameter = request->cursorPreparedHandleParameter->next;

				/*
				 * We haven't seen the case where dataParameter is absent in case of cursorprepexec
				 * So, indirectly, metaData (For ex. @P1 int, @P2 int etc) will always be there.
				 */

				TdsReadUnicodeDataFromTokenCommon(message->data,
													request->cursorHandleParameter->next,
													request->metaDataParameterValue);

				if (unlikely(!request->cursorHandleParameter->next->next))
					ereport(ERROR,
                                                        (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                                                         errmsg("%s parameter should not be null", "Query")));
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorHandleParameter->next->next) != TDS_TYPE_NVARCHAR &&
					FetchDataTypeNameFromParameter(request->cursorHandleParameter->next->next) != TDS_TYPE_NTEXT))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));
				request->queryParameter = request->cursorHandleParameter->next->next;

				if (request->queryParameter)
				{
					request->cursorExtraArg1 = request->queryParameter->next;
					if (request->cursorExtraArg1)
					{
						request->cursorExtraArg2 =
							request->cursorExtraArg1->next;
						if (request->cursorExtraArg2)
						{
							request->cursorExtraArg3 =
								request->cursorExtraArg2->next;
							if (request->cursorExtraArg3)
								request->dataParameter =
									request->cursorExtraArg3->next;
						}
					}
				}
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursorprepexec");
			}
			break;
		case SP_CURSORFETCH:
			{
				TdsErrorContext->spType = "SP_CURSORFETCH";
				TDSInstrumentation(INSTR_TDS_SP_CURSOR_FETCH);
				if (unlikely(parameterCount < 1))
					ereport(ERROR,
							(errcode(ERRCODE_PROTOCOL_VIOLATION),
							 errmsg("The minimum number of parameters should be %d", 1)));

				/*
				 *
				 * The order of the parameter is cursor handle, fetch
				 * type, rownum and nrows.  Only Cursor handle is mandatory,
				 * the rest are optional parameters.  If one optional
				 * parameter exists, all previous optional parameter
				 * must be there in the packet.
				 */
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor handle", "integer")));
				request->cursorHandleParameter = request->parameter;

				/*
				 * ExtraArg1 = fetch type
				 * ExtraArg2 = rownum
				 * ExtraArg3 = nrows
				 */
				request->cursorExtraArg1 = request->cursorHandleParameter->next;

				if (request->cursorExtraArg1)
				{
					request->cursorExtraArg2 = request->cursorExtraArg1->next;

					if (request->cursorExtraArg2)
						request->cursorExtraArg3 = request->cursorExtraArg2->next;
				}
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursorfetch");
			}
			break;
		case SP_CURSORCLOSE:
			{
				TdsErrorContext->spType = "SP_CURSORCLOSE";
				TDSInstrumentation(INSTR_TDS_SP_CURSOR_CLOSE);
				if (unlikely(parameterCount < 1))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 1)));

				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor handle", "integer")));
				request->cursorHandleParameter = request->parameter;
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursorclose");
			}
			break;
		case SP_CURSORUNPREPARE:
			{
				TdsErrorContext->spType = "SP_CURSORUNPREPARE";
				TDSInstrumentation(INSTR_TDS_SP_CURSOR_UNPREPARE);

				if (unlikely(parameterCount < 1))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 1)));
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor prepared handle", "integer")));
				request->cursorPreparedHandleParameter = request->parameter;
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursorunprepare");
			}
			break;
		case SP_CURSOR:
			{
				/*
				 * 1. Cursor parameter (mandatory)
				 * 2. ExtraArg1 = optype (mandatory)
				 * 3. ExtraArg2 = rownum (mandatory)
				 * 4. ExtraArg3 = table (mandatory)
				 * 5. dataParameter = value
				 */
				TdsErrorContext->spType = "SP_CURSOR";
				TDSInstrumentation(INSTR_UNSUPPORTED_TDS_SP_CURSOR);
                              if (unlikely(parameterCount < 4))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 4)));

                              if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor handle", "integer")));
				request->cursorHandleParameter = request->parameter;

				request->cursorExtraArg1 = request->cursorHandleParameter->next;
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg1) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "optype", "integer")));

				request->cursorExtraArg2 = request->cursorExtraArg1->next;
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg2) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "rownum", "integer")));

				/* table should be of string datatype */
				request->cursorExtraArg3 = request->cursorExtraArg2->next;
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_NVARCHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_VARCHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_NCHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_CHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_NTEXT &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_TEXT))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "table", "string")));

				if (request->cursorExtraArg3->next)
				{
					/* value should be of string datatype */
					request->dataParameter = request->cursorExtraArg3->next;
					if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_NVARCHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_VARCHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_NCHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_CHAR &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_NTEXT &&
							FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_TEXT))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "value", "string")));
				}
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursor");
			}
			break;
		case SP_CURSOROPTION:
			{
				/*
				 * 1. Cursor parameter (mandatory)
				 * 2. ExtraArg1 = code (mandatory)
				 * 3. ExtraArg2 = value (mandatory)
				 */
				TdsErrorContext->spType = "SP_CURSOROPTION";
				TDSInstrumentation(INSTR_UNSUPPORTED_TDS_SP_CURSOROPTION);
                              if (unlikely(parameterCount < 3))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 3)));

                              if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Cursor handle", "integer")));
				request->cursorHandleParameter = request->parameter;

				request->cursorExtraArg1 = request->cursorHandleParameter->next;
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg1) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "code", "integer")));

				request->cursorExtraArg2 = request->cursorExtraArg1->next;
				if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg2) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "value", "integer")));
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_cursoroption");
			}
			break;
		case SP_CURSORPREPARE:
			{
					/*
					* 1. Cursor prepared Handle parameter (mandatory)
					* 2. query parameter (mandatory)
					* 3. ExtraArg1 = scrollopt
					* 4. ExtraArg2 = ccopt
					*/
					TDSInstrumentation(INSTR_UNSUPPORTED_TDS_SP_CURSORPREPARE);
								if (unlikely(parameterCount < 4))
										ereport(ERROR,
                                                                                                (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                                                                 errmsg("The minimum number of parameters should be %d", 4)));

								if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
										ereport(ERROR,
                                                                                                (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                                                 errmsg("%s parameter should be of %s type", "Cursor prepared handle", "integer")));
					request->cursorPreparedHandleParameter = request->parameter;

					TdsReadUnicodeDataFromTokenCommon(message->data,
													request->cursorPreparedHandleParameter->next,
													request->metaDataParameterValue);

                              if (unlikely(!request->cursorPreparedHandleParameter->next->next))
					ereport(ERROR,
                                                        (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                                                         errmsg("%s parameter should not be null", "Query")));
                              if (unlikely(FetchDataTypeNameFromParameter(request->cursorPreparedHandleParameter->next->next) != TDS_TYPE_NVARCHAR &&
                                          FetchDataTypeNameFromParameter(request->cursorPreparedHandleParameter->next->next) != TDS_TYPE_NTEXT))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));
			        request->queryParameter = request->cursorPreparedHandleParameter->next->next;

					if (unlikely(FetchDataTypeNameFromParameter(request->queryParameter) != TDS_TYPE_NVARCHAR &&
											FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_NCHAR &&
											FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_NTEXT))
							ereport(ERROR,
                                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                         errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));

					request->cursorExtraArg1 = request->queryParameter->next;
					if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg1) != TDS_TYPE_INTEGER))
							ereport(ERROR,
                                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                         errmsg("%s parameter should be of %s type", "options", "integer")));

					request->cursorExtraArg2 = request->queryParameter->next;
					if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg2) != TDS_TYPE_INTEGER))
							ereport(ERROR,
                                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                         errmsg("%s parameter should be of %s type", "scrollopt", "integer")));

					request->cursorExtraArg3 = request->queryParameter->next;
					if (unlikely(FetchDataTypeNameFromParameter(request->cursorExtraArg3) != TDS_TYPE_INTEGER))
							ereport(ERROR,
                                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                         errmsg("%s parameter should be of %s type", "ccopt", "integer")));
					ereport(ERROR,
                                                        (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                                                         errmsg("\n Tds %s not supported yet", "SP_CURSORPREPARE")));
			}
			break;
		case SP_EXECUTESQL:
			{
				TdsErrorContext->spType = "SP_EXECUTESQL";
				if (unlikely(parameterCount < 1))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 1)));
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_NVARCHAR &&
					FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_NTEXT))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));
				request->queryParameter = request->parameter;

				if (request->queryParameter->next &&
					request->queryParameter->next->next)
				{
					TdsReadUnicodeDataFromTokenCommon(message->data,
														request->queryParameter->next,
														request->metaDataParameterValue);
					request->dataParameter =
						request->queryParameter->next->next;
				}
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_executesql");
			}
			break;
		case SP_PREPARE:
			{
				TdsErrorContext->spType = "SP_PREPARE";
				if (unlikely(parameterCount < 2))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 2)));
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Handle", "integer")));
				request->handleParameter = request->parameter;

				/*
				 * In case, IN/OUT parameters are absent
				 * then the intermediate parameter will
				 * (@P0 int, ...) will be absent, and
				 * next parameter after the handle parameter
				 * should be the actual query
				 */
				if (request->parameter->next && request->parameter->next->next)
				{
					if (request->handleParameter)
					{
						TdsReadUnicodeDataFromTokenCommon(message->data,
							request->handleParameter->next,
							request->metaDataParameterValue);
					}
					if (unlikely(FetchDataTypeNameFromParameter(request->parameter->next->next) != TDS_TYPE_NVARCHAR &&
						FetchDataTypeNameFromParameter(request->parameter->next->next) != TDS_TYPE_NTEXT))
						ereport(ERROR,
                                                                (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                 errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));

					request->queryParameter = request->parameter->next->next;
				}
				else
				{
					if (unlikely(FetchDataTypeNameFromParameter(request->parameter->next) != TDS_TYPE_NVARCHAR &&
						FetchDataTypeNameFromParameter(request->parameter->next) != TDS_TYPE_NTEXT))
						ereport(ERROR,
                                                                (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                 errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));
					request->queryParameter = request->parameter->next;
				}
				if (request->queryParameter->next)
					request->dataParameter = request->queryParameter->next;

				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_prepare");
			}
			break;
		case SP_EXECUTE:
			{
				TdsErrorContext->spType = "SP_EXECUTE";
				if (unlikely(parameterCount < 1))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 1)));
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Handle", "INT")));

				request->handleParameter = request->parameter;

				if (request->parameter->next)
					request->dataParameter = request->parameter->next;
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_execute");
			}
			break;
		case SP_PREPEXEC:
			{
				TdsErrorContext->spType = "SP_PREPEXEC";
				if (unlikely(parameterCount < 2))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 2)));
				if (unlikely(FetchDataTypeNameFromParameter(request->parameter) != TDS_TYPE_INTEGER))
					ereport(ERROR,
                                                        (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                         errmsg("%s parameter should be of %s type", "Handle", "INT")));
				request->handleParameter = request->parameter;

				/*
				 * In case, IN/OUT parameters are absent
				 * then the intermediate parameter will
				 * (@P0 int, ...) will be absent, and
				 * next parameter after the handle parameter
				 * should be the actual query
				 */
				if (request->parameter->next &&
					request->parameter->next->next)
				{
					if (request->handleParameter)
					{
						TdsReadUnicodeDataFromTokenCommon(message->data,
															request->handleParameter->next,
															request->metaDataParameterValue);
					}
					if (unlikely(FetchDataTypeNameFromParameter(request->parameter->next->next) != TDS_TYPE_NVARCHAR &&
						FetchDataTypeNameFromParameter(request->parameter->next->next) != TDS_TYPE_NTEXT))
						ereport(ERROR,
                                                                (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                 errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));
					request->queryParameter =
						request->parameter->next->next;
				}
				else
				{
					if (unlikely(FetchDataTypeNameFromParameter(request->parameter->next) != TDS_TYPE_NVARCHAR &&
						FetchDataTypeNameFromParameter(request->parameter->next) != TDS_TYPE_NTEXT))
						ereport(ERROR,
                                                                (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                                                                 errmsg("%s parameter should be of %s type", "Query", "NVARCHAR or NTEXT")));
					request->queryParameter = request->parameter->next;
				}
				if (request->queryParameter->next)
					request->dataParameter = request->queryParameter->next;
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_prepexec");
			}
			break;
		case SP_PREPEXECRPC:
			{
				TdsErrorContext->spType = "SP_PREPEXECRPC";
				/* Not supported yet */
				ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						errmsg("SP_PREPEXECRPC not supported yet")));
			}
			break;
		case SP_UNPREPARE:
			{
				TdsErrorContext->spType = "SP_UNPREPARE";
				if (unlikely(parameterCount < 1))
					ereport(ERROR,
                                                        (errcode(ERRCODE_PROTOCOL_VIOLATION),
                                                         errmsg("The minimum number of parameters should be %d", 1)));
				request->handleParameter = request->parameter;
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: sp_unprepare");
			}
			break;
		case SP_CUSTOMTYPE:
			{
				TdsErrorContext->spType = "SP_CUSTOMTYPE";
				request->dataParameter = request->parameter;
				TDS_DEBUG(TDS_DEBUG1, "message_type: Remote Procedure Call (3) rpc_packet_type: user defined procedure");
			}
			break;
		default:
				ereport(ERROR,
					(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. The RPC name is invalid.")));
	}

	/* initialize the IN/OUT parameter index array */
	InitializeDataParamTokenIndex(request);

	/* get the SP handle */
	GetSPHandleParameter(request);

	/* get the SP cursor handle */
	GetSPCursorHandleParameter(request);

	/* get the SP cursor Prepared handle */
	GetSPCursorPreparedHandleParameter(request);

	return (TDSRequest)request;
}

void
RestoreRPCBatch(StringInfo message, uint8_t *status, uint8_t *messageType)
{
	/* Restore the common Packet for the Batch. */
	Assert(TdsRequestCtrl->request->reqType == TDS_REQUEST_SP_NUMBER);
	Assert(RPCBatchExists(TdsRequestCtrl->request->sp));
	message->data = TdsRequestCtrl->request->sp.messageData;
	message->len = TdsRequestCtrl->request->sp.messageLen;
	*messageType = TDS_RPC; /* Hardcoded the type since we do an assert at the start. */
	*status = TdsRequestCtrl->status;
}

void
ProcessRPCRequest(TDSRequest request)
{
	TDSRequestSP req;

	req = (TDSRequestSP) request;

	switch(req->spType)
	{
		case SP_CURSOR:
			GenerateBindParamsData(req);
			HandleSPCursorRequest(req);
			break;
		case SP_CURSOROPEN:
		case SP_CURSORPREPARE:
		case SP_CURSORPREPEXEC:
		case SP_CURSOREXEC:
			GenerateBindParamsData(req);
			HandleSPCursorOpenCommon(req);
			break;
		case SP_CURSORFETCH:
			HandleSPCursorFetchRequest(req);
			break;
		case SP_CURSORCLOSE:
			HandleSPCursorCloseRequest(req);
			break;
		case SP_CURSORUNPREPARE:
			HandleSPCursorUnprepareRequest(req);
			break;
		case SP_CURSOROPTION:
			HandleSPCursorOptionRequest(req);
			break;
		case SP_PREPARE:
			SPPrepare(req);
			break;
		case SP_PREPEXECRPC:
			Assert(0);
			break;
		case SP_PREPEXEC:
			SPPrepExec(req);
			break;
		case SP_EXECUTE:
			SPExecute(req);
			break;
		case SP_EXECUTESQL:
			SPExecuteSQL(req);
			break;
		case SP_CUSTOMTYPE:
			SPCustomType(req);
			break;
		case SP_UNPREPARE:
			SPUnprepare(req);
			break;
	}
}

/*
 * TdsIsSPPrepare - Returns true if sp_prepare packet is being processed
 */
bool
TdsIsSPPrepare()
{
	TDSRequestSP req;
	req = (TDSRequestSP) TdsRequestCtrl->request;
	if (req->spType == SP_PREPARE)
		return true;
	return false;
}

/*
 * TdsFetchInParamValues - fetch the IN parameters from TDS message buffer
 *
 * params		- (OUT argument) store the actual Datums
 *
 * It's the responsibility of the caller allocate memory for the same.
 *
 * Also note that we send the OUT parameters as INOUT parameters.  The TDS
 * protocol sends the value of these parameters as NULL.  So, we're going to
 * bind NULL as values for these paramters.
 */
void
TdsFetchInParamValues(ParamListInfo params)
{
	ParameterToken	token;
	TDSRequest request = TdsRequestCtrl->request;
	TDSRequestSP req;
	int			paramno = 0;

	Assert(params != NULL);

	Assert(request->reqType == TDS_REQUEST_SP_NUMBER);
	req = (TDSRequestSP) request;

	for (token = req->dataParameter; token != NULL; token = token->next, paramno++)
	{
		Oid			ptype;
		Datum		pval;
		bool		isNull;
		TdsIoFunctionInfo tempFuncInfo;

		tempFuncInfo = TdsLookupTypeFunctionsByTdsId(token->type, token->maxLen);
		isNull = token->isNull;

		ptype = token->paramMeta.pgTypeOid;

		if (!isNull && token->type != TDS_TYPE_TABLE)
			pval = tempFuncInfo->recvFuncPtr(req->messageData, token);
		else if (token->type == TDS_TYPE_TABLE)
			pval = (Datum) token->tvpInfo->tvpTypeName;
		else
			pval = (Datum) 0;

		params->params[paramno].value = pval;
		params->params[paramno].isnull = isNull;

		/*
		 * We mark the params as CONST.  This ensures that any custom plan
		 * makes full use of the parameter values.
		 */
		params->params[paramno].pflags = PARAM_FLAG_CONST;
		params->params[paramno].ptype = ptype;
	}
}

/*
 * In case of SP or prep-exec, parameter names are optional.
 * If client applications doesn't specify the parameter name then internally
 * driver sends the default parameter name with query text.
 * For ex: insert into tablenm values (@P0).
 *
 * Engine needs the parameter index to store the values appropriately.
 * For example: index 1 for @P0, index 2 for @P1
 *
 * TdsGetAndSetParamIndex function acts as a reference counter to send the
 * paramter Index starting from 1 for valid param.
 * For anything else, return 0.
 *
 * Assumption:
 * 1. Parameter values will always be in the serial order in case of SP_[CURSOR]EXEC
 * 2. Valid Parameter names will always start from @P
 */
int
TdsGetAndSetParamIndex(const char *name)
{
	TDSRequestSP req;

	if ((TdsRequestCtrl == NULL) || (TdsRequestCtrl->request == NULL)
		|| (TdsRequestCtrl->request->reqType != TDS_REQUEST_SP_NUMBER))
	{
		return 0;
	}

	/*
	 * Default parameters should always start from @P
	 */
	if (strlen(name) < 3 || name[0] != '@')
	{
		return 0;
	}

	req = (TDSRequestSP) TdsRequestCtrl->request;
	/*
	 * We need to use the intermediate Parameter
	 * For ex: (@P0 int, @P1 int etc) when available.
	 */
	if (req->metaDataParameterValue->len > 0)
	{
		int			i = 0, temp = 0;
		const char	*source = req->metaDataParameterValue->data;
		char		*pos;
		int			ptr;
		int 		qlen = strlen(source);
		int			nlen = strlen(name);
		while (temp < qlen)
		{
			int j;

			/*
			 * If param names are not given by the application, then driver
			 * default params names always start with "@P"
			 */
			pos = strstr(source, "@P");

			/*
			 * If parameter names don't match, return 0
			 */
			if (pos == NULL)
			{
				return 0;
			}
			ptr = pos - source;
			for (j = ptr; j < ptr + nlen && j < qlen; j++)
			{
				/*
				 * Parameter names comparison seems to be dependent on collation
				 * (case sensitive vs insensitive). So here, we will have to do the
				 * comparision depending on collation. For now, convert everything
				 * into lower case and compare since by default collation in TSQL
				 * is case insensitive (SQL_Latin1_General_CP1_CI_AS)
				 */
				if (tolower(source[j]) != tolower(name[j - ptr]))
				{
					break;
				}
			}
			/*
			 * If no characters match, then return 0
			 */
			if (j == ptr)
			{
				return 0;
			}

			if (j == ptr + nlen)
				return i + 1;

			temp = j;
			source = &source[temp];
			i++;
		}
		return 0;
	}

	/*
	 * We shouldn't reach here other than SP_[CURSOR]EXEC SP request.
	 *
	 * Assumption: In case of SP_[CURSOR]EXEC SP request,
	 * this function will be called only once during exec_bind_message.
	 *
	 * If in future we encounter a case, where above assumption doesn't work,
	 * then only option is to parse the complete query text to get the param index.
	 * This is kind of an optimization to save us from the complete query
	 * parsing based on above assumptions.
	 */
	Assert(req->spType == SP_EXECUTE ||
		req->spType == SP_CURSOREXEC);

	return ++(req->paramIndex);
}

/*
 * TdsGetParamNames - fetch TDS IN/OUT parameter names
 *
 * We'll follow the same IN/OUT parameter order in which we've received. Also,
 * we're allocating the memory in callers memory context.  So, it's
 * responsibility of the caller to perform cleanups.
 */
bool
TdsGetParamNames(List **pnames)
{
	TDSRequest			request;
	TDSRequestSP		req;
	ParameterToken		token;

	if ((TdsRequestCtrl == NULL) || (TdsRequestCtrl->request == NULL)
		|| (TdsRequestCtrl->request->reqType != TDS_REQUEST_SP_NUMBER))
		return false;

	request = TdsRequestCtrl->request;
	req = (TDSRequestSP) request;

	if (req->spType == SP_EXECUTESQL
		|| req->spType == SP_PREPARE
		|| req->spType == SP_PREPEXEC
		|| req->spType == SP_EXECUTE)
		return false;

	if (req->spType == SP_CUSTOMTYPE)
		return false;

	if (req->nTotalParams == 0)
		return false;

	for (token = req->dataParameter; token != NULL; token = token->next)
	{
		StringInfo		name;
		TdsParamName item = palloc(sizeof(TdsParamNameData));

		name = &(token->paramMeta.colName);

		/*
		 * When parameter names aren't given by the client driver, then
		 * simply return true.
		 * We make an assumption that all parameters will either have a name
		 * or not. There won't be a case where some parameters in a packet have name,
		 * while others don't.
		 */
		if (name->len == 0)
			return true;

		item->name = pnstrdup(name->data, strlen(name->data));
		item->type = (token->flags == 0) ? 0 : 1;

		*pnames = lappend(*pnames, item);
	}

	return true;
}

/*
 * TDS function to log statement duration related info
 */
void
TDSLogDuration(char *query)
{
	char    msec_str[32];

	switch (check_log_duration(msec_str, false))
	{
		case 1:
			ereport(LOG, (errmsg("Query duration: %s ms", msec_str),
							errhidestmt(true)));
			break;
		case 2:
			ereport(LOG, (errmsg("Query: %s duration: %s ms",
					query, msec_str), errhidestmt(true)));
			break;
		default:
			break;
	}
	return;
}

/*
 * TDS function to log statement handler and duration detail for cursor
 */
static void
TDSLogStatementCursorHandler(TDSRequestSP req, char *stmt, int option)
{
	if (pltsql_plugin_handler_ptr->stmt_needs_logging || TDS_DEBUG_ENABLED(TDS_DEBUG2))
	{
		ErrorContextCallback *plerrcontext = error_context_stack;
		error_context_stack = plerrcontext->previous;
		
		switch (option)
		{
			case PRINT_CURSOR_HANDLE:
				ereport(LOG,
					(errmsg("sp_cursor handle: %d; statement: %s",
						req->cursorHandle, stmt),
					 errhidestmt(true),
					 errdetail_params(req->nTotalParams)));
				break;
			case PRINT_PREPARED_CURSOR_HANDLE:
				ereport(LOG,
					(errmsg("sp_cursor prepared handle: %d; statement: %s",
						req->cursorPreparedHandle, stmt),
					 errhidestmt(true),
					 errdetail_params(req->nTotalParams)));
				break;
			case PRINT_BOTH_CURSOR_HANDLE:
				ereport(LOG,
					(errmsg("sp_cursor handle: %d; sp_cursor prepared handle: %d; statement: %s",
						req->cursorHandle, req->cursorPreparedHandle, stmt),
					 errhidestmt(true),
					 errdetail_params(req->nTotalParams)));
				break;
			default:
				break;
		}

		pltsql_plugin_handler_ptr->stmt_needs_logging = false;
		error_context_stack = plerrcontext;
	}
	
	/* Print TDS log duration, if log_duration is set */
	TDSLogDuration(stmt);
}
