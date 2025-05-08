/*-------------------------------------------------------------------------
 *
 * tdsprotocol.c
 *	  TDS Listener tokenized protocol handling
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdsprotocol.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/htup_details.h"	/* for GETSTRUCT() to extract tuple data */
#include "access/printtup.h"	/* for SetRemoteDestReceiverParams() */
#include "access/table.h"
#include "access/relation.h"
#include "access/relscan.h"
#include "access/genam.h"
#include "access/xact.h"		/* for IsTransactionOrTransactionBlock() */
#include "catalog/indexing.h"
#include "catalog/pg_type.h"
#include "commands/async.h"
#include "commands/defrem.h"
#include "commands/prepare.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "libpq/pqformat.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "nodes/parsenodes.h"
#include "parser/parser.h"
#include "parser/parse_coerce.h"
#include "port/pg_bswap.h"
#include "tcop/pquery.h"
#include "utils/fmgroids.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/memdebug.h"
#include "utils/numeric.h"
#include "utils/portal.h"
#include "utils/rel.h"
#include "utils/snapmgr.h"

#include "src/include/tds_debug.h"
#include "src/include/tds_int.h"
#include "src/include/tds_protocol.h"
#include "src/include/tds_response.h"
#include "src/include/faultinjection.h"
#include "storage/proc.h"
#include "utils/timeout.h"

/*
 * When we reset the connection, we save the required information in the following
 * structure that should be restored after the reset.
 */
typedef struct ResetConnectionData
{
	StringInfo	message;
	uint8_t		messageType;
	uint8_t		status;
} ResetConnectionData;
typedef ResetConnectionData *ResetConnection;

/*
 * Local structures
 */
TdsRequestCtrlData *TdsRequestCtrl = NULL;

ResetConnection resetCon = NULL;
bool resetTdsConnectionFlag = false;

/* Local functions */
static void ResetTDSConnection(void);
static TDSRequest GetTDSRequest(bool *resetProtocol);
static void ProcessTDSRequest(TDSRequest request);
static void enable_statement_timeout(void);
static void disable_statement_timeout(void);

/*
 * TDSDiscardAll - copy of DiscardAll
 */
static
void
TdsDiscardAll()
{
	/*
	 * Disallow DISCARD ALL in a transaction block. This is arguably
	 * inconsistent (we don't make a similar check in the command sequence
	 * that DISCARD ALL is equivalent to), but the idea is to catch mistakes:
	 * DISCARD ALL inside a transaction block would leave the transaction
	 * still uncommitted.
	 */
	PreventInTransactionBlock(true, "DISCARD ALL");

	/* Closing portals might run user-defined code, so do that first. */
	PortalHashTableDeleteAll();
	ResetAllOptions();
	DropAllPreparedStatements();
	Async_UnlistenAll();
	LockReleaseAll(USER_LOCKMETHOD, true);
	ResetPlanCache();
	ResetTempTableNamespace();
	ResetSequenceCaches();
}

/*
 * ResetTDSConnection - resets the TDS connection
 *
 * It resets the TDS connection by calling DISCARD ALL api in .  Also, it
 * releases the memory allocated in TDS layer and re-initializes different
 * buffers and structures.  Additionally, it sends an environment change token
 * for RESETCON.
 */
static void
ResetTDSConnection(void)
{
	const char *isolationOld;

	Assert(TdsRequestCtrl->request == NULL);
	Assert(TdsRequestCtrl->requestContext != NULL);
	TdsErrorContext->err_text = "Resetting the TDS connection";

	/* Make sure we've killed any active transaction */
	pltsql_plugin_handler_ptr->pltsql_abort_any_transaction_callback();

	/*
	 * Save the transaction isolation level that should be restored after
	 * connection reset.
	 */
	isolationOld = GetConfigOption("default_transaction_isolation", false, false);

	/*
	 * Start an implicit transaction block because the internal code may need
	 * to access the catalog.
	 */
	StartTransactionCommand();
	TdsDiscardAll();
	pltsql_plugin_handler_ptr->reset_session_properties();
	CommitTransactionCommand();

	/*
	 * Now reset the TDS top memory context and re-initialize everything.
	 * Also, restore the transaction isolation level.
	 */
	MemoryContextReset(TdsMemoryContext);
	TdsCommReset();
	TdsProtocolInit();
	TdsResetCache();
	TdsResponseReset();
	TdsResetBcpOffset();
	TdsResetLoginFlags();

	/* Retore previous isolation level when not called by sys.sp_reset_connection. */
	if (!resetTdsConnectionFlag)
	{
		SetConfigOption("default_transaction_isolation", isolationOld,
						PGC_BACKEND, PGC_S_CLIENT);
	}
	tvp_lookup_list = NIL;

	/* Send an environement change token is its not called via sys.sp_reset_connection procedure. */
	if (!resetTdsConnectionFlag)
	{
		TdsSendEnvChange(TDS_ENVID_RESETCON, NULL, NULL);
	}
}

/*
 * SetResetTDSConnectionFlag - Sets reset tds connection flag
 */
void SetResetTDSConnectionFlag()
{
	resetTdsConnectionFlag = true;	
}

bool GetResetTDSConnectionFlag()
{
	return resetTdsConnectionFlag;	
}

/*
 * GetTDSRequest - Fetch and parse a TDS packet and generate a TDS request that
 * can be processed later.
 *
 * 	Note that, this method is called in TDS Request Context so that any allocation
 * 	done here will get reset only after sending the response.
 *
 * 	resetProtocol - set to true if we've reset the connection.
 */
static TDSRequest
GetTDSRequest(bool *resetProtocol)
{
	uint8_t		messageType;
	uint8_t		status;
	TDSRequest	request;
	StringInfoData message;

	initStringInfo(&message);

	/*
	 * Setup error traceback support for ereport()
	 */
	TdsErrorContext->err_text = "Fetching TDS Request";
	TdsErrorContext->spType = "Unknown (Pre-Parsing Request)";
	TdsErrorContext->txnType = "Unknown (Pre-Parsing Request)";
	PG_TRY();
	{
		/*
		 * If we've saved the TDS request earlier, process the same instead of
		 * trying to fetch a new request.
		 */
		if (resetCon != NULL)
		{
			messageType = resetCon->messageType;
			status = resetCon->status;
			appendBinaryStringInfo(&message, resetCon->message->data, resetCon->message->len);

			/* cleanup and reset */
			pfree(resetCon->message->data);
			pfree(resetCon->message);
			pfree(resetCon);
			resetCon = NULL;
		}
		else
		{
			/*
			 * If TdsRequestCtrl->request is not NULL then there are mutliple
			 * RPCs in a Batch and we would restore the message Otherwise we
			 * would fetch the next packet.]
			 */
			if (TdsRequestCtrl->request == NULL)
			{
				int			ret;

				/*
				 * We should hold the interrupts untill we read the entire
				 * request.
				 */
				HOLD_CANCEL_INTERRUPTS();
				ret = TdsReadNextRequest(&message, &status, &messageType);
				RESUME_CANCEL_INTERRUPTS();

				if (ret != 0)
				{
					TdsErrorContext->reqType = 0;
					TdsErrorContext->err_text = "EOF reached on TDS socket";
					TDS_DEBUG(TDS_DEBUG1, "EOF on TDS socket");
					pfree(message.data);
					return NULL;
				}
				TdsErrorContext->err_text = "Fetching TDS Request";
				TdsRequestCtrl->status = status;
			}
			else
				RestoreRPCBatch(&message, &status, &messageType);
		}

		DebugPrintMessageData("Fetched message:", message);

		TdsErrorContext->reqType = messageType;

#ifdef FAULT_INJECTOR
		{
			TdsMessageWrapper wrapper;

			wrapper.message = &message;
			wrapper.messageType = messageType;

			FAULT_INJECT(PreParsingType, &wrapper);
		}
#endif

		Assert(messageType != 0);

		/*
		 * If we have to reset the connection, we save the TDS request in top
		 * memory context before exit so that we can process the request
		 * later.
		 */
		if (status & TDS_PACKET_HEADER_STATUS_RESETCON)
		{
			MemoryContextSwitchTo(TopMemoryContext);

			if (resetCon == NULL)
				resetCon = palloc(sizeof(ResetConnectionData));

			resetCon->message = makeStringInfo();
			appendBinaryStringInfo(resetCon->message, message.data, message.len);
			resetCon->messageType = messageType;
			resetCon->status = (status & ~TDS_PACKET_HEADER_STATUS_RESETCON);

			/*
			 * Set resetTdsConnectionFlag to true so that we avoid
			 * sending any env change token for the USE DB command
			 * which will get executed.
			 */
			resetTdsConnectionFlag = true;
			TdsSetDbContext();
			resetTdsConnectionFlag = false;
			ResetTDSConnection();

			TdsErrorContext->err_text = "Fetching TDS Request";
			*resetProtocol = true;
			return NULL;
		}

		/*
		 * XXX: We don't support the following feature.  But, throw an error
		 * to detect the case in case we get such a request.
		 */
		if (status & TDS_PACKET_HEADER_STATUS_RESETCONSKIPTRAN)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("RESETCONSKIPTRAN is not supported")));

		/* An attention request can also have message.len = 0. */
		if (message.len == 0 && messageType != TDS_ATTENTION)
		{
			TDS_DEBUG(TDS_DEBUG1, "zero byte client message on TDS socket");
			pfree(message.data);
			return NULL;
		}

		/*
		 * Enable statement timeout. Note we add this function here to include
		 * the time taken by the protocol in the timeout.
		 */
		enable_statement_timeout();

		/* Parse the packet */
		switch (messageType)
		{
			case TDS_QUERY:		/* Simple SQL BATCH */
				{
					request = GetSQLBatchRequest(&message);

					pfree(message.data);
				}
				break;
			case TDS_RPC:		/* Remote procedure call */
				{
					request = GetRPCRequest(&message);
				}
				break;
			case TDS_TXN:		/* Transaction management request */
				{
					request = GetTxnMgmtRequest(&message);
				}
				break;
			case TDS_BULK_LOAD: /* Bulk Load request */
				{
					request = GetBulkLoadRequest(&message);
				}
				break;
			case TDS_ATTENTION: /* Attention request */
				{
					/* Return an empty request with the attention type. */
					request = palloc0(sizeof(TDSRequest));
					request->reqType = TDS_REQUEST_ATTN;
				}
				break;
			default:
				DebugPrintMessageData("Ignored message", message);
				elog(ERROR, "TDSRequest: ignoring request type 0x%02x",
					 message.data[0]);
		}
	}
	PG_CATCH();
	{
		PG_RE_THROW();
	}
	PG_END_TRY();

	FAULT_INJECT(PostParsingType, request);

	return request;
}

/*
 * ProcessTDSRequest - TDS specific processing of the request
 *
 * Note that, this method is called in MessageContext so that any allocation
 * done here can be reset in next TCOP iteration.
 */
static void
ProcessTDSRequest(TDSRequest request)
{
	/*
	 * Setup error traceback support for ereport()
	 */
	TdsErrorContext->err_text = "Processing TDS Request";

	/*
	 * We shouldn't be in this state as we handle the aborted case on
	 * babelfishpg_tsql extension itself.  But, if we somehow end up in this
	 * state, throw error and disconnect immediately.
	 */
	if (IsAbortedTransactionBlockState())
		elog(FATAL, "terminating connection due to unexpected TSQL transaction state");

	PG_TRY();
	{
		StartTransactionCommand();
		MemoryContextSwitchTo(MessageContext);
		pltsql_plugin_handler_ptr->stmt_needs_logging = false;

		switch (request->reqType)
		{
			case TDS_REQUEST_SP_NUMBER:
				{
					ProcessRPCRequest(request);
				}
				break;
			case TDS_REQUEST_SQL_BATCH:
				{
					ProcessSQLBatchRequest(request);
				}
				break;
			case TDS_REQUEST_TXN_MGMT:
				{
					ProcessTxnMgmtRequest(request);
				}
				break;
			case TDS_REQUEST_ATTN:
				{
					TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_ATTN, 0xfd, 0);
				}
				break;
			case TDS_REQUEST_BULK_LOAD:
				{
					ProcessBCPRequest(request);
				}
				break;
			default:
				/* GetTDSRequest() should've returned the correct request type */
				Assert(0);
				break;
		}

		/* Disabling statement timeout after processing. */
		disable_statement_timeout();

		CommitTransactionCommand();
		MemoryContextSwitchTo(MessageContext);

	}
	PG_CATCH();
	{
		int			token_type;
		int			command_type = TDS_CMD_UNKNOWN;

		disable_statement_timeout();
		CommitTransactionCommand();
		MemoryContextSwitchTo(MessageContext);

		EmitErrorReport();
		FlushErrorState();

		if (request->reqType == TDS_REQUEST_SP_NUMBER)
			token_type = TDS_TOKEN_DONEPROC;
		else
			token_type = TDS_TOKEN_DONE;

		TdsSendDone(token_type, TDS_DONE_ERROR, command_type, 0);
	}
	PG_END_TRY();
}

void
TdsProtocolInit(void)
{
	MemoryContext oldContext;

	SetConfigOption("babelfishpg_tsql.sql_dialect", "tsql", PGC_SU_BACKEND, PGC_S_OVERRIDE);
	SetConfigOption("babelfishpg_tsql.enable_tsql_information_schema", "true", PGC_USERSET, PGC_S_SESSION);
	SetConfigOption("lock_timeout", "0", PGC_SU_BACKEND, PGC_S_OVERRIDE);
	oldContext = MemoryContextSwitchTo(TdsMemoryContext);
	TdsRequestCtrl = palloc(sizeof(TdsRequestCtrlData));
	TdsRequestCtrl->phase = TDS_REQUEST_PHASE_INIT;

	TdsRequestCtrl->requestContext = AllocSetContextCreate(TdsMemoryContext,
														   "TDS Request",
														   ALLOCSET_DEFAULT_SIZES);
	TdsRequestCtrl->request = NULL;
	TdsRequestCtrl->status = 0;

	MemoryContextSwitchTo(oldContext);
}

void
TdsProtocolFinish(void)
{
	SetConfigOption("babelfishpg_tsql.sql_dialect", "postgres", PGC_SU_BACKEND, PGC_S_OVERRIDE);
	SetConfigOption("babelfishpg_tsql.enable_tsql_information_schema", "false", PGC_USERSET, PGC_S_SESSION);
	SetConfigOption("lock_timeout", NULL, PGC_SU_BACKEND, PGC_S_OVERRIDE);

	if (TdsRequestCtrl->requestContext)
	{
		MemoryContextDelete(TdsRequestCtrl->requestContext);
		TdsRequestCtrl->requestContext = NULL;
	}

	pfree(TdsRequestCtrl);
	TdsRequestCtrl = NULL;
}

/*
 * TdsSocketBackend()		Is called for frontend-backend TDS connections
 *
 * This function reads requests from a TDS client and executes the same.  We
 * leave the function only in case of an error or if connection is lost.  EOF
 * is returned if the connection is lost.
 */
int
TdsSocketBackend(void)
{
	bool		resetProtocol;
	bool		loop = true;

	while (loop)
	{
		PG_TRY();
		{
			switch (TdsRequestCtrl->phase)
			{
				case TDS_REQUEST_PHASE_INIT:
					{
						MemoryContext oldContext;

						resetProtocol = false;

						TdsErrorContext->phase = "TDS_REQUEST_PHASE_INIT";

						/*
						 * Switch to the request context.  We reset this
						 * context once once TDSfunctionCache is loaded
						 */
						oldContext = MemoryContextSwitchTo(TdsMemoryContext);

						InitTDSResponse();
						StartTransactionCommand();
						PushActiveSnapshot(GetTransactionSnapshot());

						/*
						 * Loading the cache tables in TdsMemoryContext Memory
						 * context and is loaded only once during the INIT
						 * step. TODO: Cache invalidate & reload if some
						 * enteries have changed
						 */
						TdsLoadTypeFunctionCache();
						TdsLoadEncodingLCIDCache();
						PopActiveSnapshot();
						CommitTransactionCommand();

						MemoryContextSwitchTo(oldContext);

						/*
						 * we should have exec callbacks initialized by this
						 * time
						 */
						if (!(pltsql_plugin_handler_ptr->sql_batch_callback))
							elog(FATAL, "sql_batch_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_executesql_callback))
							elog(FATAL, "sp_executesql_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_prepare_callback))
							elog(FATAL, "sp_prepare_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_execute_callback))
							elog(FATAL, "sp_execute_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_prepexec_callback))
							elog(FATAL, "sp_prepexec_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_unprepare_callback))
							elog(FATAL, "sp_unprepare_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->pltsql_declare_var_callback))
							elog(FATAL, "pltsql_declare_var_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->pltsql_read_out_param_callback))
							elog(FATAL, "pltsql_read_out_param_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_cursoropen_callback))
							elog(FATAL, "sp_cursoropen_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_cursorclose_callback))
							elog(FATAL, "sp_cursorclose_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_cursorfetch_callback))
							elog(FATAL, "sp_cursorfetch_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_cursorexecute_callback))
							elog(FATAL, "sp_cursorexecute_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_cursorprepexec_callback))
							elog(FATAL, "sp_cursorprepexec_callback is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_cursorprepare_callback))
							elog(FATAL, "sp_cursorprepare is not initialized");
						if (!(pltsql_plugin_handler_ptr->sp_cursorunprepare_callback))
							elog(FATAL, "sp_cursorunprepare is not initialized");
						if (!(pltsql_plugin_handler_ptr->send_column_metadata))
							elog(FATAL, "send_column_metadata is not initialized");

						/* Ready to fetch the next request */
						TdsRequestCtrl->phase = TDS_REQUEST_PHASE_FETCH;
						break;
					}
				case TDS_REQUEST_PHASE_FETCH:
					{
						MemoryContext oldContext;

						TdsErrorContext->phase = "TDS_REQUEST_PHASE_FETCH";

						/*
						 * Switch to the request context.  We reset this
						 * context once we send the response.
						 */
						oldContext = MemoryContextSwitchTo(TdsRequestCtrl->requestContext);

						/*
						 * Also consider releasing our catalog snapshot if
						 * any, so that it's not preventing advance of global
						 * xmin while we wait for the client.
						 */
						InvalidateCatalogSnapshotConditionally();

						/*
						 * We should hold the interrupts untill we read the
						 * entire request.
						 */
						resetProtocol = false;
						TdsRequestCtrl->request = GetTDSRequest(&resetProtocol);

						MemoryContextSwitchTo(oldContext);

						/* if we've reset the connection, break here. */
						if (resetProtocol)
						{
							/* the next phase should be set to init phase */
							Assert(TdsRequestCtrl->phase == TDS_REQUEST_PHASE_INIT);
							break;
						}

						if (TdsRequestCtrl->request == NULL)
							return EOF;

						/* Switch the TDS protocol to RESPONSE mode */
						TdsSetMessageType(TDS_RESPONSE);

						/* we should be in tsql dialect */
						if (sql_dialect != SQL_DIALECT_TSQL)
							elog(ERROR, "babelfishpg_tsql.sql_dialect is not set to tsql");

						/* Now, process the request */
						TdsRequestCtrl->phase = TDS_REQUEST_PHASE_PROCESS;

						/*
						 * Break here. We will process the request later in
						 * PostgresMain function.
						 */
						loop = false;
						break;
					}

				case TDS_REQUEST_PHASE_PROCESS:
					{
						TdsErrorContext->phase = "TDS_REQUEST_PHASE_PROCESS";
						TdsRequestCtrl->isEmptyResponse = true;

						ProcessTDSRequest(TdsRequestCtrl->request);

						/* we should be still in MessageContext */
						Assert(CurrentMemoryContext == MessageContext);

						/*
						 * If there are RPC packets left to fetch in the
						 * packet then we go back to the fetch phase
						 */
						if (TdsRequestCtrl->request->reqType == TDS_REQUEST_SP_NUMBER && RPCBatchExists(TdsRequestCtrl->request->sp))
							TdsRequestCtrl->phase = TDS_REQUEST_PHASE_FETCH;
						else

							/*
							 * No more message to send to the TCOP loop.  Send
							 * the response.
							 */
							TdsRequestCtrl->phase = TDS_REQUEST_PHASE_FLUSH;

						/*
						 * Break here. We will Flush or Fetch the next request
						 * in the next iteration of PostgresMain function.
						 */
						loop = false;
						break;
					}
				case TDS_REQUEST_PHASE_FLUSH:
					{
						TdsErrorContext->phase = "TDS_REQUEST_PHASE_FLUSH";

						if (resetTdsConnectionFlag)
						{
							/*
							 * We must set the Db Context before resetting TDS state,
							 * becasue we need the existing TDS state to flush any errors
							 * along with the reset.
							 */
							TdsSetDbContext();
						}

						/* Send the response now */
						TdsFlush();

						/* Cleanups */
						MemoryContextReset(TdsRequestCtrl->requestContext);

						/* Reset the request */
						TdsRequestCtrl->request = NULL;

						/* Ready to fetch the next request */
						TdsRequestCtrl->phase = TDS_REQUEST_PHASE_FETCH;

						if (resetTdsConnectionFlag)
						{
							ResetTDSConnection();
							resetTdsConnectionFlag = false;
						}

						break;
					}
				case TDS_REQUEST_PHASE_ERROR:
					TdsErrorContext->phase = "TDS_REQUEST_PHASE_ERROR";

					/*
					 * We've already sent an error token. If required, we can
					 * send more error tokens before flushing the response.
					 * N.B. We can reach this state only for some unexpected
					 * error condition. For normal execution error,
					 * babelfishpg_tsql extension already handles the error
					 * and doesn't rethrow to TDS. So, if we're getting some
					 * error at this level, we should investigate the error.
					 */

					/*
					 * Send the done token that follows error XXX: Does it
					 * matter whether it's DONE or DONEPROC? This is anyway
					 * not an expected place to throw an error. Find a valid
					 * usecase before making this logic more complicated.
					 */
					TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_ERROR,
								TDS_CMD_UNKNOWN, 0);

					/* We're done.  Send the response. */
					TdsRequestCtrl->phase = TDS_REQUEST_PHASE_FLUSH;
					break;
			}
		}
		PG_CATCH();
		{
			TdsRequestCtrl->phase = TDS_REQUEST_PHASE_ERROR;

			/*
			 * We need to rethrow the error as the error handling code in the
			 * main postgres tcop loop does a lot of necessary cleanups. But,
			 * if we want to do any further cleanup or take any further
			 * action, we can do that here as a pre-processing or in
			 * TDS_REQUEST_PHASE_ERROR state as post-processing.
			 */
			PG_RE_THROW();
		}
		PG_END_TRY();
	}

	return 0;
}

int
TestGetTdsRequest(uint8_t reqType, const char *expectedStr)
{
	int			res = 0;
	bool		resetProtocol;
	TDSRequest	request = GetTDSRequest(&resetProtocol);

	switch (reqType)
	{
		case TDS_TXN:
			res = TestTxnMgmtRequest(request, expectedStr);
			break;
		default:
			return -1;
	}
	return res;
}

/*
 * Start statement timeout timer, if enabled.
 */
static void
enable_statement_timeout(void)
{
	if (StatementTimeout > 0)
	{
		if (!get_timeout_active(STATEMENT_TIMEOUT))
			enable_timeout_after(STATEMENT_TIMEOUT, StatementTimeout);
	}
	else
	{
		if (get_timeout_active(STATEMENT_TIMEOUT))
			disable_timeout(STATEMENT_TIMEOUT, false);
	}
}

/*
 * Disable statement timeout, if active.
 */
static void
disable_statement_timeout(void)
{
	if (get_timeout_active(STATEMENT_TIMEOUT))
		disable_timeout(STATEMENT_TIMEOUT, false);
}
