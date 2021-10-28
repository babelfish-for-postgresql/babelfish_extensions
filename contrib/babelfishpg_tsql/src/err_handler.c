#include "postgres.h"

#include "err_handler.h"
#include "funcapi.h"
#include "pltsql.h"

PG_FUNCTION_INFO_V1(babel_list_mapped_error);

/* error could be ignored within exec_stmt_execsql */
bool is_ignorable_error(int pg_error_code)
{
	/* 
	 * As of now, Trying do classification based on SQL error code.
	 * If it does not work then doing classification based on pg_error_code.
	 */
	switch(latest_error_code)
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
		{
			elog(DEBUG1, "TSQL TXN is_ignorable_error %d", latest_error_code);
			return true;
		}
		default:
			break;
	}
    switch(pg_error_code)
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
bool is_current_batch_aborting_error(int pg_error_code)
{
	/* 
	 * As of now, Trying do classification based on SQL error code.
	 * If it does not work then doing classification based on pg_error_code.
	 */
	switch(latest_error_code)
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
bool is_batch_txn_aborting_error(int pg_error_code)
{
	/* 
	 * As of now, Trying do classification based on SQL error code.
	 * If it does not work then doing classification based on pg_error_code.
	 */
	switch(latest_error_code)
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
		{
			elog(DEBUG1, "TSQL TXN is_batch_txn_aborting_error %d", latest_error_code);
			return true;
		}
		default:
			return false;
	}
}

bool ignore_xact_abort_error(int pg_error_code)
{
	/* 
	 * As of now, Trying do classification based on SQL error code.
	 * If it does not work then doing classification based on pg_error_code.
	 */
	switch(latest_error_code)
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
	switch(pg_error_code)
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
bool is_txn_aborting_compilation_error(int sql_error_code)
{
	switch(sql_error_code)
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
bool is_xact_abort_txn_compilation_error(int sql_error_code)
{
	switch(sql_error_code)
	{
		case SQL_ERROR_16948:
		case SQL_ERROR_2747:
		case SQL_ERROR_8159:
		case SQL_ERROR_11717:
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
bool get_tsql_error_code(ErrorData *edata, int *last_error)
{
    /* xxx: if (*pltsql_protocol_plugin_ptr)->get_tsql_error is initialised then use it
     * directly. If it is not initialised or in other words, babelfishpg_tds is not loaded
     * then use older approach. 
     * But we need to handle error neatly when only babelfishpg_tsql is loaded. We will address that case
     * as part of BABEL-1204.
     */
	*last_error = ERRCODE_PLTSQL_ERROR_NOT_MAPPED;
    if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_tsql_error)
    {
        int tsql_error_sev, tsql_error_state;
        return (*pltsql_protocol_plugin_ptr)->get_tsql_error (edata,
								last_error,
								&tsql_error_sev,
								&tsql_error_state,
								"babelfishpg_tsql");
    }
	return false;
}

Datum
babel_list_mapped_error(PG_FUNCTION_ARGS)
{
	/* To hold the list of supported SQL error code */
	int *list = NULL;

	/* SRF related things to keep enough state between calls */
	FuncCallContext *funcctx;
	int call_cntr;
	int max_calls;

	/* stuff done only on the first call of the function */
	if (SRF_IS_FIRSTCALL())
	{
		MemoryContext   oldcontext;
		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_mapped_error_list)
			list = (*pltsql_protocol_plugin_ptr)->get_mapped_error_list();

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

