#include "postgres.h"

#include "common/string.h"
#include "err_handler.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "utils/builtins.h"
#include "utils/syscache.h"

#define FN_MAPPED_SYSTEM_ERROR_LIST_COLS 4
PG_FUNCTION_INFO_V1(babel_list_mapped_error);
PG_FUNCTION_INFO_V1(babel_list_mapped_error_deprecated_in_2_2_0);

/*
 * Certain tsql error code can behave differently depending on when it is
 * raised or what operations were being executed.
 * For example, tsql error code 547 can behave in 2 different ways:
 * 1. Error code 547 will behave as if it is statement terminating error if
 *    It is raised when DML was being executed.
 * 2. Same error code will behave as transaction aborting error for any other cases.
 *
 * Scenario described in point no. 1 is happening probably because another tsql error
 * token (i.e. 3621) also being raised after original token. But Babelfish does not
 * have support to raise multiple token.
 *
 * So, This function override_txn_behaviour could be used to override behaviour of
 * any error code for different situation.
 *
 * This will return int flag with required information encoded.
 * flag & IGNORABLE_ERROR (0x01) --> statement terminating
 * flag & CUR_BATCH_ABORTING_ERROR (0x02) --> current batch terminating
 * flag & TXN_ABORTING_ERROR (0x04) --> transaction aborting
 * flag & IGNORE_XACT_ERROR (0x08) --> ignore xact_abort
 */
uint8_t
override_txn_behaviour(PLtsql_stmt *stmt)
{
	uint8_t		override_flag = 0;

	if (!stmt)
		return 0;

	/*
	 * If tsql error code 547 is raised while executing DML statement then
	 * error code should behave as if it is statement terminating error.
	 */
	if (latest_error_code == SQL_ERROR_547 && stmt->cmd_type == PLTSQL_STMT_EXECSQL)
	{
		PLtsql_expr *expr = ((PLtsql_stmt_execsql *) stmt)->sqlstmt;

		if (expr && expr->plan)
		{
			ListCell   *lc;

			/*
			 * Below loop will iterate one time only for every statement in
			 * the batch.
			 */
			foreach(lc, SPI_plan_get_plan_sources(expr->plan))
			{
				CachedPlanSource *plansource = (CachedPlanSource *) lfirst(lc);

				if (plansource &&
					plansource->commandTag &&
					(plansource->commandTag == CMDTAG_INSERT ||
					 plansource->commandTag == CMDTAG_UPDATE ||
					 plansource->commandTag == CMDTAG_DELETE))
				{
					override_flag |= IGNORABLE_ERROR;
				}
			}
		}
	}
	return override_flag;
}

/* error could be ignored within exec_stmt_execsql */
bool
is_ignorable_error(int pg_error_code, uint8_t override_flag)
{
	/*
	 * Check if override transactional behaviour flag is set, And use the same
	 * to determine the transactional behaviour.
	 */
	if (override_flag)
	{
		if (override_flag & IGNORABLE_ERROR)
			return true;
		else
			return false;
	}

	/*
	 * As of now, Trying do classification based on SQL error code. If it does
	 * not work then doing classification based on pg_error_code.
	 */
	switch (latest_error_code)
	{
		case SQL_ERROR_232:
		case SQL_ERROR_3902:
		case SQL_ERROR_3903:
		case SQL_ERROR_574:
		case SQL_ERROR_8115:
		case SQL_ERROR_3701:
		case SQL_ERROR_2627:
		case SQL_ERROR_6401:
		case SQL_ERROR_220:
		case SQL_ERROR_8134:
		case SQL_ERROR_512:
		case SQL_ERROR_515:
		case SQL_ERROR_306:
		case SQL_ERROR_477:
		case SQL_ERROR_16915:
		case SQL_ERROR_1801:
		case SQL_ERROR_545:
		case SQL_ERROR_550:
		case SQL_ERROR_3914:
		case SQL_ERROR_8143:
		case SQL_ERROR_8152:
		case SQL_ERROR_1752:
		case SQL_ERROR_16950:
		case SQL_ERROR_517:
		case SQL_ERROR_266:
		case SQL_ERROR_2787:
		case SQL_ERROR_2732:
		case SQL_ERROR_8179:
		case SQL_ERROR_9809:
		case SQL_ERROR_201:
		case SQL_ERROR_206:
		case SQL_ERROR_8144:
		case SQL_ERROR_8145:
		case SQL_ERROR_8146:
		case SQL_ERROR_213:
			{
				elog(DEBUG1, "TSQL TXN is_ignorable_error %d", latest_error_code);
				return true;
			}
		default:
			break;
	}
	switch (pg_error_code)
	{
		case ERRCODE_PLTSQL_RAISERROR:
			{
				elog(DEBUG1, "TSQL TXN is_ignorable_error raise error %d", latest_error_code);
				return true;
			}
		default:
			return false;
	}
}

/* Tsql errors which terminate only the batch where error was raised  */
bool
is_current_batch_aborting_error(int pg_error_code, uint8_t override_flag)
{
	/*
	 * Check if override transactional behaviour flag is set, And use the same
	 * to determine the transactional behaviour.
	 */
	if (override_flag)
	{
		if (override_flag & CUR_BATCH_ABORTING_ERROR)
			return true;
		else
			return false;
	}

	/*
	 * As of now, Trying do classification based on SQL error code. If it does
	 * not work then doing classification based on pg_error_code.
	 */
	switch (latest_error_code)
	{
		case SQL_ERROR_306:
		case SQL_ERROR_477:
		case SQL_ERROR_1752:
		case SQL_ERROR_10793:
			{
				elog(DEBUG1, "TSQL TXN is_current_batch_aborting_error %d", latest_error_code);
				return true;
			}
		default:
			return false;
	}
}

/* Tsql errors which lead to batch abort and transaction rollback */
bool
is_batch_txn_aborting_error(int pg_error_code, uint8_t override_flag)
{
	/*
	 * Check if override transactional behaviour flag is set, And use the same
	 * to determine the transactional behaviour.
	 */
	if (override_flag)
	{
		if (override_flag & TXN_ABORTING_ERROR)
			return true;
		else
			return false;
	}

	/*
	 * As of now, Trying do classification based on SQL error code. If it does
	 * not work then doing classification based on pg_error_code.
	 */
	switch (latest_error_code)
	{
		case SQL_ERROR_628:
		case SQL_ERROR_3723:
		case SQL_ERROR_3726:
		case SQL_ERROR_3729:
		case SQL_ERROR_3732:
		case SQL_ERROR_4712:
		case SQL_ERROR_1505:
		case SQL_ERROR_2714:
		case SQL_ERROR_217:
		case SQL_ERROR_547:
		case SQL_ERROR_219:
		case SQL_ERROR_11700:
		case SQL_ERROR_11705:
		case SQL_ERROR_11706:
		case SQL_ERROR_11708:
		case SQL_ERROR_4708:
		case SQL_ERROR_4920:
		case SQL_ERROR_10610:
		case SQL_ERROR_8107:
		case SQL_ERROR_1768:
		case SQL_ERROR_1778:
		case SQL_ERROR_3728:
		case SQL_ERROR_1715:
		case SQL_ERROR_1765:
		case SQL_ERROR_556:
		case SQL_ERROR_4901:
		case SQL_ERROR_1946:
		case SQL_ERROR_293:
		case SQL_ERROR_289:
		case SQL_ERROR_3623:
		case SQL_ERROR_3609:
		case SQL_ERROR_4514:
		case SQL_ERROR_1205:
		case SQL_ERROR_11702:
		case SQL_ERROR_11703:
		case SQL_ERROR_8106:
		case SQL_ERROR_9441:
		case SQL_ERROR_9451:
		case SQL_ERROR_11701:
		case SQL_ERROR_3616:
		case SQL_ERROR_911:
			{
				elog(DEBUG1, "TSQL TXN is_batch_txn_aborting_error %d", latest_error_code);
				return true;
			}
		default:
			return false;
	}
}

bool
ignore_xact_abort_error(int pg_error_code, uint8_t override_flag)
{
	/*
	 * Check if override transactional behaviour flag is set, And use the same
	 * to determine the transactional behaviour.
	 */
	if (override_flag)
	{
		if (override_flag & IGNORE_XACT_ERROR)
			return true;
		else
			return false;
	}

	/*
	 * As of now, Trying do classification based on SQL error code. If it does
	 * not work then doing classification based on pg_error_code.
	 */
	switch (latest_error_code)
	{
		case SQL_ERROR_3701:
		case SQL_ERROR_129:
		case SQL_ERROR_2787:
		case SQL_ERROR_266:
		case SQL_ERROR_180:
		case SQL_ERROR_132:
		case SQL_ERROR_133:
		case SQL_ERROR_135:
		case SQL_ERROR_136:
		case SQL_ERROR_1049:
		case SQL_ERROR_1034:
		case SQL_ERROR_134:
		case SQL_ERROR_141:
		case SQL_ERROR_10733:
		case SQL_ERROR_10727:
		case SQL_ERROR_11555:
		case SQL_ERROR_487:
		case SQL_ERROR_153:
		case SQL_ERROR_11709:
			{
				elog(DEBUG1, "TSQL TXN ignore_xact_abort_error %d", latest_error_code);
				return true;
			}
		default:
			break;
	}
	switch (pg_error_code)
	{
		case ERRCODE_PLTSQL_RAISERROR:
			return true;
		default:
			return false;
	}
}

/*
 * Compile time errors which abort transactions by default
 */
bool
is_txn_aborting_compilation_error(int sql_error_code)
{
	switch (sql_error_code)
	{
		default:
			break;
	}
	return false;
}

/*
 * Compile time error which abort transactions when xact_abort
 * is set to ON
 */
bool
is_xact_abort_txn_compilation_error(int sql_error_code)
{
	switch (sql_error_code)
	{
		case SQL_ERROR_2747:
		case SQL_ERROR_8159:
		case SQL_ERROR_11717:
		case SQL_ERROR_16948:
			{
				elog(DEBUG1, "TSQL TXN is_xact_abort_txn_compilation_error %d", latest_error_code);
				return true;
			}
		default:
			break;
	}
	return false;
}

/* translate PG error code to  error code */
bool
get_tsql_error_code(ErrorData *edata, int *last_error)
{
	/*
	 * xxx: if (*pltsql_protocol_plugin_ptr)->get_tsql_error is initialised
	 * then use it directly. If it is not initialised or in other words,
	 * babelfishpg_tds is not loaded then use older approach. But we need to
	 * handle error neatly when only babelfishpg_tsql is loaded. We will
	 * address that case as part of BABEL-1204.
	 */
	*last_error = ERRCODE_PLTSQL_ERROR_NOT_MAPPED;
	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_tsql_error)
	{
		int			tsql_error_sev,
					tsql_error_state;

		return (*pltsql_protocol_plugin_ptr)->get_tsql_error(edata,
															 last_error,
															 &tsql_error_sev,
															 &tsql_error_state,
															 "babelfishpg_tsql");
	}
	return false;
}

static int
get_err_lineno(const char *context)
{
	int			lineno = -1;
	const char *pattern1 = "line ";
	const char *pattern2 = " at";
	char	   *start,
			   *end;

	if ((start = strstr(context, pattern1)))
	{
		start += strlen(pattern1);
		if ((end = strstr(start, pattern2)))
		{
			lineno = strtoint(start, &end, 10);
		}
	}
	return lineno;
}

/*
 * Do error mapping to get the mapped error info, including error number, error
 * severity and error state.
 */
static void
do_error_mapping(PLtsql_estate_err *err)
{
	if (!(*pltsql_protocol_plugin_ptr) ||
		!(*pltsql_protocol_plugin_ptr)->get_tsql_error)
		return;

	err->number = err->error->sqlerrcode;
	(*pltsql_protocol_plugin_ptr)->get_tsql_error(err->error,
												  &err->number,
												  &err->severity,
												  &err->state,
												  "babelfishpg_tsql");
}

/*
 * If there is no error in current estate, try to check previous estates one by
 * one, in case we are inside a previous estate's CATCH block.
 */
static PLtsql_execstate *
find_innermost_catch_block(void)
{
	PLExecStateCallStack *stack = exec_state_call_stack;
	PLtsql_execstate *estate = stack->estate;

	while ((!estate || !estate->cur_error || !estate->cur_error->error) &&
		   stack->next)
	{
		stack = stack->next;
		estate = stack->estate;
	}

	return estate;
}

Datum
babel_list_mapped_error_deprecated_in_2_2_0(PG_FUNCTION_ARGS)
{
	/* To hold the list of supported SQL error code */
	int		   *list = NULL;

	/* SRF related things to keep enough state between calls */
	FuncCallContext *funcctx;
	int			call_cntr;
	int			max_calls;

	/* stuff done only on the first call of the function */
	if (SRF_IS_FIRSTCALL())
	{
		MemoryContext oldcontext;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_mapped_error_list)
			list = (*pltsql_protocol_plugin_ptr)->get_mapped_tsql_error_code_list();

		funcctx->user_fctx = (void *) list;
		funcctx->max_calls = list[0];
		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	call_cntr = funcctx->call_cntr;
	max_calls = funcctx->max_calls;
	list = (int *) funcctx->user_fctx;

	if (call_cntr < max_calls)
		/* Actual data starts at index 1. Index 0 is to store length. */
		SRF_RETURN_NEXT(funcctx, Int32GetDatum(list[call_cntr + 1]));
	else
		SRF_RETURN_DONE(funcctx);
}

Datum
babel_list_mapped_error(PG_FUNCTION_ARGS)
{
	/* To hold the list of supported SQL error code */
	error_map_details_t *list = NULL;

	/* SRF related things to keep enough state between calls */
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	Tuplestorestate *tupstore;
	TupleDesc	tupdesc;
	int			call_cntr = 0;
	MemoryContext oldcontext;
	MemoryContext per_query_ctx;
	Oid			nspoid = get_namespace_oid("sys", false);
	Oid			sys_varcharoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("nvarchar"), ObjectIdGetDatum(nspoid));

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Create tuple descriptor for the result set. */
	tupdesc = CreateTemplateTupleDesc(FN_MAPPED_SYSTEM_ERROR_LIST_COLS);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "pg_sql_state", sys_varcharoid, 5, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "error_message", sys_varcharoid, 4000, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "error_msg_parameters", sys_varcharoid, 4000, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "sql_error_code", INT4OID, -1, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_mapped_error_list)
		list = (error_map_details_t *) (*pltsql_protocol_plugin_ptr)->get_mapped_error_list();

	if (list == NULL)
		return (Datum) 0;

	while (1)
	{
		Datum		values[4];
		bool		nulls[4] = {false, false, false, false};

		/* Last record would have error_message = NULL. */
		if (list[call_cntr].error_message == NULL)
			break;

		values[0] = CStringGetTextDatum(list[call_cntr].sql_state);
		values[1] = CStringGetTextDatum(list[call_cntr].error_message);
		values[2] = CStringGetTextDatum(list[call_cntr].error_msg_keywords);
		values[3] = Int32GetDatum(list[call_cntr].tsql_error_code);

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
		call_cntr += 1;
	}
	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	return (Datum) 0;
}

/*
 * ERROR_*() functions
 */
PG_FUNCTION_INFO_V1(pltsql_error_line);
PG_FUNCTION_INFO_V1(pltsql_error_message);
PG_FUNCTION_INFO_V1(pltsql_error_number);
PG_FUNCTION_INFO_V1(pltsql_error_procedure);
PG_FUNCTION_INFO_V1(pltsql_error_severity);
PG_FUNCTION_INFO_V1(pltsql_error_state);

Datum
pltsql_error_line(PG_FUNCTION_ARGS)
{
	PLtsql_execstate *estate;
	int			lineno = -1;

	if (exec_state_call_stack == NULL)
		PG_RETURN_NULL();

	estate = find_innermost_catch_block();

	if (!estate || !estate->cur_error || !estate->cur_error->error ||
		!estate->cur_error->error->context)
		PG_RETURN_NULL();

	/*
	 * TODO: This function is just a temporary workaround for error line
	 * number. We should cache line number as soon as an error is raised.
	 */
	lineno = get_err_lineno(estate->cur_error->error->context);

	if (lineno == -1)
		PG_RETURN_NULL();

	PG_RETURN_INT32(lineno);
}

Datum
pltsql_error_message(PG_FUNCTION_ARGS)
{
	PLtsql_execstate *estate;
	StringInfoData temp;
	void	   *message = NULL;

	if (exec_state_call_stack == NULL)
		PG_RETURN_NULL();

	estate = find_innermost_catch_block();

	if (!estate || !estate->cur_error || !estate->cur_error->error ||
		!estate->cur_error->error->message)
		PG_RETURN_NULL();

	initStringInfo(&temp);
	appendStringInfoString(&temp, estate->cur_error->error->message);
	message = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);

	pfree(temp.data);

	Assert(message);
	PG_RETURN_VARCHAR_P(message);
}

Datum
pltsql_error_number(PG_FUNCTION_ARGS)
{
	PLtsql_execstate *estate;

	if (exec_state_call_stack == NULL)
		PG_RETURN_NULL();

	estate = find_innermost_catch_block();

	if (!estate || !estate->cur_error || !estate->cur_error->error)
		PG_RETURN_NULL();

	/* For system generated error, do error mapping */
	if (estate->cur_error->number == -1)
		do_error_mapping(estate->cur_error);

	PG_RETURN_INT32(estate->cur_error->number);
}

Datum
pltsql_error_procedure(PG_FUNCTION_ARGS)
{
	PLtsql_execstate *estate;
	StringInfoData temp;
	void	   *procedure = NULL;

	if (exec_state_call_stack == NULL)
		PG_RETURN_NULL();

	estate = find_innermost_catch_block();

	if (!estate || !estate->cur_error || !estate->cur_error->error ||
		!estate->cur_error->procedure)
		PG_RETURN_NULL();

	initStringInfo(&temp);
	appendStringInfoString(&temp, estate->cur_error->procedure);
	procedure = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);

	pfree(temp.data);

	Assert(procedure);
	PG_RETURN_VARCHAR_P(procedure);
}

Datum
pltsql_error_severity(PG_FUNCTION_ARGS)
{
	PLtsql_execstate *estate;

	if (exec_state_call_stack == NULL)
		PG_RETURN_NULL();

	estate = find_innermost_catch_block();

	if (!estate || !estate->cur_error || !estate->cur_error->error)
		PG_RETURN_NULL();

	/* For system generated error, do error mapping */
	if (estate->cur_error->number == -1)
		do_error_mapping(estate->cur_error);

	PG_RETURN_INT32(estate->cur_error->severity);
}

Datum
pltsql_error_state(PG_FUNCTION_ARGS)
{
	PLtsql_execstate *estate;

	if (exec_state_call_stack == NULL)
		PG_RETURN_NULL();

	estate = find_innermost_catch_block();

	if (!estate || !estate->cur_error || !estate->cur_error->error)
		PG_RETURN_NULL();

	/* For system generated error, do error mapping */
	if (estate->cur_error->number == -1)
		do_error_mapping(estate->cur_error);

	PG_RETURN_INT32(estate->cur_error->state);
}
