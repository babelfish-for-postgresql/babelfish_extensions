/*-------------------------------------------------------------------------
 *
 * tdssqlbatch.c
 *	  TDS Listener functions for handling SQL Batch requests
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdssqlbatch.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/htup_details.h"
#include "access/printtup.h"
#include "access/xact.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "nodes/parsenodes.h"
#include "pgstat.h"
#include "tcop/tcopprot.h"

#include "src/include/tds_int.h"
#include "src/include/tds_protocol.h"
#include "src/include/tds_request.h"
#include "src/include/tds_response.h"

TDSRequest
GetSQLBatchRequest(StringInfo message)
{
	TDSRequestSQLBatch request;
	int			query_offset = 0;
	int			query_len;
	uint32_t	tdsVersion = GetClientTDSVersion();

	TdsErrorContext->err_text = "Fetching SQL Batch Request";

	/*
	 * In the ALL_HEADERS rule, the Query Notifications header and the
	 * Transaction Descriptor header were introduced in TDS 7.2. We need to to
	 * Process them only for TDS versions more than or equal to 7.2, otherwise
	 * we do not increment the offset.
	 */
	if (tdsVersion > TDS_VERSION_7_1_1)
		query_offset = ProcessStreamHeaders(message);
	query_len = message->len - query_offset;

	/* Build return structure */
	request = palloc0(sizeof(TDSRequestSQLBatchData));
	request->reqType = TDS_REQUEST_SQL_BATCH;

	initStringInfo(&(request->query));

	TdsUTF16toUTF8StringInfo(&(request->query),
							 &(message->data[query_offset]),
							 query_len);

	return (TDSRequest) request;
}

/*
 * Helper function to execute a SQL Batch
 * query using pltsql inline handler
 */
void
ExecuteSQLBatch(char *query)
{
	LOCAL_FCINFO(fcinfo, 1);
	InlineCodeBlock *codeblock = makeNode(InlineCodeBlock);
	char	   *activity = psprintf("SQL_BATCH: %s", query);

	TdsErrorContext->err_text = "Processing SQL Batch Request";
	pgstat_report_activity(STATE_RUNNING, activity);
	pfree(activity);

	/* Only source text matters to handler */
	codeblock->source_text = query;
	codeblock->langOid = 0;		/* TODO does it matter */
	codeblock->langIsTrusted = true;
	codeblock->atomic = false;

	/* Just to satisfy argument requirement */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(1));
	fcinfo->args[0].value = PointerGetDatum(codeblock);
	fcinfo->args[0].isnull = false;
	PG_TRY();
	{
		pltsql_plugin_handler_ptr->sql_batch_callback(fcinfo);
	}
	PG_CATCH();
	{
		if (TDS_DEBUG_ENABLED(TDS_DEBUG2))
		{
			HOLD_INTERRUPTS();
			ereport(LOG,
					(errmsg("sql_batch statement: %s", query),
					 errhidestmt(true)));
			RESUME_INTERRUPTS();
		}

		PG_RE_THROW();
	}
	PG_END_TRY();

	/*
	 * Log immediately if dictated by log_statement
	 */
	if (pltsql_plugin_handler_ptr->stmt_needs_logging || TDS_DEBUG_ENABLED(TDS_DEBUG2))
	{
		ErrorContextCallback *plerrcontext = error_context_stack;

		error_context_stack = plerrcontext->previous;
		ereport(LOG,
				(errmsg("sql_batch statement: %s", query),
				 errhidestmt(true)));
		pltsql_plugin_handler_ptr->stmt_needs_logging = false;
		error_context_stack = plerrcontext;
	}

	/*
	 * Print TDS log duration, if log_duration is set
	 */
	TDSLogDuration(query);

}

/*
 * SQL batch requests directly go to pltsql
 * inline block handler
 */
void
ProcessSQLBatchRequest(TDSRequest request)
{
	TDSRequestSQLBatch req = (TDSRequestSQLBatch) request;

	ExecuteSQLBatch(req->query.data);
	MemoryContextSwitchTo(MessageContext);

	/* If there was an empty query, send a done token */
	if (TdsRequestCtrl->isEmptyResponse)
		TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_FINAL, 0xfd, 0);
}
