/*-------------------------------------------------------------------------
 *
 * tdsxact.c
 *	  TDS Listener functions for handling Transaction requests
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdsxact.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/transam.h"
#include "nodes/parsenodes.h"
#include "pgstat.h"
#include "storage/proc.h"

#include "src/include/tds_instr.h"
#include "src/include/tds_int.h"
#include "src/include/tds_request.h"
#include "src/include/tds_response.h"

/* Transaction management request */

/* Transaction command types */
#define TDS_TM_BEGIN_XACT		5
#define TDS_TM_COMMIT_XACT		7
#define TDS_TM_ROLLBACK_XACT	8
#define TDS_TM_SAVEPOINT_XACT	9

/* Transaction isolation level */
#define TDS_ISOLATION_LEVEL_NONE 0
#define TDS_ISOLATION_LEVEL_READ_UNCOMMITTED 1
#define TDS_ISOLATION_LEVEL_READ_COMMITTED 2
#define TDS_ISOLATION_LEVEL_REPEATABLE_READ 3
#define TDS_ISOLATION_LEVEL_SERIALIZABLE 4
#define TDS_ISOLATION_LEVEL_SNAPSHOT 5

/* [A-Za-z\200-\377_\#] */
static bool
IsValidIdentFirstChar(char ch)
{
	if ((ch >= 'a' && ch <= 'z') ||
		(ch >= 'A' && ch <= 'Z') ||
		(ch >= 0x80 && ch <= 0xff) ||
		(ch == '_') || (ch == '#'))
		return true;

	return false;
}

/* [A-Za-z\200-\377_0-9\$\#] */
static bool
IsValidIdentChar(char ch)
{
	if (IsValidIdentFirstChar(ch) ||
		(ch >= '0' && ch <= '9') ||
		(ch == '$'))
		return true;

	return false;
}

static bool
IsValidTxnName(char *txnName, int len)
{
	if (len > 0 && IsValidIdentFirstChar(txnName[0]))
	{
		for (int i = 1; i < len; ++i)
			if (!IsValidIdentChar(txnName[i]))
				return false;
		return true;
	}
	return false;
}

/* Get transaction name from transaction management request */
static int
GetTxnName(const StringInfo message, TDSRequestTxnMgmt request, int offset)
{
	uint8_t		len;

	memcpy(&len, message->data + offset, sizeof(len));
	offset += sizeof(len);

	if (len != 0)
	{
		if (len > TSQL_TXN_NAME_LIMIT)
			ereport(ERROR,
					(errcode(ERRCODE_NAME_TOO_LONG),
					 errmsg("Transaction name length %u above limit %u",
							len, TSQL_TXN_NAME_LIMIT)));

		initStringInfo(&(request->txnName));
		TdsUTF16toUTF8StringInfo(&(request->txnName),
								 message->data + offset,
								 len);
		if (!IsValidTxnName(request->txnName.data, request->txnName.len))
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_NAME),
					 errmsg("Transaction savepoint name is not valid")));

		offset += len;
	}
	return offset;
}

/* A new transaction request -> isolation level + txn name */
static int
GetNewTxnRequest(const StringInfo message,
				 TDSRequestTxnMgmt request,
				 int offset)
{
	/* Transaction isolation level */
	memcpy(&(request->isolationLevel),
		   message->data + offset,
		   sizeof(request->isolationLevel));
	offset += sizeof(request->isolationLevel);

	if (request->isolationLevel > TDS_ISOLATION_LEVEL_SNAPSHOT)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("Invalid isolation level %u for transaction request",
						request->isolationLevel)));

	return GetTxnName(message, request, offset);
}

static const char *
GetIsolationLevelStr(uint8_t isolationLevel)
{
	switch (isolationLevel)
	{
		case TDS_ISOLATION_LEVEL_READ_UNCOMMITTED:
			return "READ UNCOMMITTED ";
		case TDS_ISOLATION_LEVEL_READ_COMMITTED:
			return "READ COMMITTED ";
		case TDS_ISOLATION_LEVEL_REPEATABLE_READ:
			return "REPEATABLE READ ";
		case TDS_ISOLATION_LEVEL_SERIALIZABLE:
			return "SERIALIZABLE ";
		case TDS_ISOLATION_LEVEL_SNAPSHOT:
			return "SNAPSHOT ";
		default:
			return "UNKNOWN ";
	}
}

static void
BuildTxnMgmtRequestQuery(TDSRequest requestParam, StringInfo cmdStr)
{
	TDSRequestTxnMgmt request = (TDSRequestTxnMgmt) requestParam;

	switch (request->txnReqType)
	{
		case TDS_TM_BEGIN_XACT:
			{
				appendStringInfoString(cmdStr, "BEGIN TRANSACTION ");
				if (request->txnName.len != 0)
					appendStringInfoString(cmdStr, request->txnName.data);
				if (request->isolationLevel != TDS_ISOLATION_LEVEL_NONE)
				{
					appendStringInfoString(cmdStr, "; SET TRANSACTION ISOLATION LEVEL ");
					appendStringInfoString(cmdStr,
										   GetIsolationLevelStr(
																request->isolationLevel));
				}
			}
			break;
		case TDS_TM_COMMIT_XACT:
		case TDS_TM_ROLLBACK_XACT:
			{
				if (request->txnReqType == TDS_TM_COMMIT_XACT)
					appendStringInfoString(cmdStr, "COMMIT TRANSACTION ");
				else
					appendStringInfoString(cmdStr, "ROLLBACK TRANSACTION ");
				if (request->txnName.len != 0)
					appendStringInfoString(cmdStr, request->txnName.data);
				if (request->nextTxn != NULL)
				{
					appendStringInfoString(cmdStr, "; BEGIN TRANSACTION ");
					if (request->nextTxn->txnName.len != 0)
						appendStringInfoString(cmdStr,
											   request->nextTxn->txnName.data);
					if (request->nextTxn->isolationLevel !=
						TDS_ISOLATION_LEVEL_NONE)
					{
						appendStringInfoString(cmdStr, "; SET TRANSACTION ISOLATION LEVEL ");
						appendStringInfoString(cmdStr,
											   GetIsolationLevelStr(
																	request->nextTxn->isolationLevel));
					}
				}
			}
			break;
		case TDS_TM_SAVEPOINT_XACT:
			{
				appendStringInfoString(cmdStr, "SAVE TRANSACTION ");
				appendStringInfoString(cmdStr, request->txnName.data);
			}
			break;
		default:
			break;
	}
}

TDSRequest
GetTxnMgmtRequest(const StringInfo message)
{
	TDSRequestTxnMgmt request;
	int			txnReqOffset = 0;
	uint8_t		flags;
	uint32_t	tdsVersion = GetClientTDSVersion();

	TDSInstrumentation(INSTR_TDS_TM_REQUEST);

	TdsErrorContext->err_text = "Fetching Transaction Management Request";

	/*
	 * In the ALL_HEADERS rule, the Query Notifications header and the
	 * Transaction Descriptor header were introduced in TDS 7.2. We need to to
	 * Process them only for TDS versions more than or equal to 7.2, otherwise
	 * we do not increment the offset.
	 */
	if (tdsVersion > TDS_VERSION_7_1_1)
		txnReqOffset = ProcessStreamHeaders(message);

	/* Build return structure */
	request = palloc0(sizeof(TDSRequestTxnMgmtData));
	request->reqType = TDS_REQUEST_TXN_MGMT;

	/* Transaction request type */
	memcpy(&(request->txnReqType),
		   message->data + txnReqOffset,
		   sizeof(request->txnReqType));
	txnReqOffset += sizeof(request->txnReqType);

	switch (request->txnReqType)
	{
		case TDS_TM_BEGIN_XACT:
			{
				TdsErrorContext->txnType = "TM_BEGIN_XACT";
				txnReqOffset = GetNewTxnRequest(message,
												request,
												txnReqOffset);
				TDS_DEBUG(TDS_DEBUG1, "message_type: Transaction Management Request (14) txn_request_type: TM_BEGIN_XACT");
			}
			break;
		case TDS_TM_COMMIT_XACT:
		case TDS_TM_ROLLBACK_XACT:
			{
				if (request->txnReqType == TDS_TM_COMMIT_XACT)
				{
					TdsErrorContext->txnType = "TM_COMMIT_XACT";
					TDS_DEBUG(TDS_DEBUG1, "message_type: Transaction Management Request (14) txn_request_type: TM_COMMIT_XACT");
				}
				else
				{
					TdsErrorContext->txnType = "TM_ROLLBACK_XACT";
					TDS_DEBUG(TDS_DEBUG1, "message_type: Transaction Management Request (14) txn_request_type: TM_ROLLBACK_XACT");
				}
				txnReqOffset = GetTxnName(message, request, txnReqOffset);

				/* Transaction request flags */
				memcpy(&flags, message->data + txnReqOffset, sizeof(flags));
				txnReqOffset += sizeof(flags);

				/* Next transaction request */
				if (flags & 0x1)
				{
					request->nextTxn = palloc0(sizeof(TDSRequestTxnMgmtData));
					txnReqOffset = GetNewTxnRequest(message,
													request->nextTxn,
													txnReqOffset);
				}
			}
			break;
		case TDS_TM_SAVEPOINT_XACT:
			{
				TdsErrorContext->txnType = "TM_SAVEPOINT_XACT";
				txnReqOffset = GetTxnName(message, request, txnReqOffset);
				if (request->txnName.len == 0)
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							 errmsg("Savepoint request with empty name")));
				TDS_DEBUG(TDS_DEBUG1, "message_type: Transaction Management Request (14) txn_request_type: TM_SAVEPOINT_XACT");
			}
			break;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("Transaction management request %u not supported",
							request->txnReqType)));
			break;
	}

	if (txnReqOffset > message->len)
		elog(FATAL,
			 "Transaction management request is corrupt,"
			 "request length: %u request offset: %u",
			 message->len, txnReqOffset);

	/* Build the internal query corresponding to the txn request */
	initStringInfo(&(request->query));
	BuildTxnMgmtRequestQuery((TDSRequest) request, &(request->query));

	pfree(message->data);

	return (TDSRequest) request;

}

void
ProcessTxnMgmtRequest(TDSRequest request)
{
	uint64_t	txnId = (uint64_t) MyProc->vxid.lxid;
	TDSRequestTxnMgmt req;
	InlineCodeBlock *codeblock = makeNode(InlineCodeBlock);
	int			cmd_type = TDS_CMD_UNKNOWN;
	char	   *activity;

	LOCAL_FCINFO(fcinfo, 1);

	TdsErrorContext->err_text = "Processing Transaction Management Request";
	req = (TDSRequestTxnMgmt) request;

	/* Only source text matters to handler */
	codeblock->source_text = req->query.data;
	codeblock->langOid = 0;		/* TODO does it matter */
	codeblock->langIsTrusted = true;
	codeblock->atomic = false;

	/* Just to satisfy argument requirement */
	MemSet(fcinfo, 0, SizeForFunctionCallInfo(1));
	fcinfo->args[0].value = PointerGetDatum(codeblock);
	fcinfo->args[0].isnull = false;

	pltsql_plugin_handler_ptr->sp_executesql_callback(fcinfo);
	MemoryContextSwitchTo(MessageContext);

	/*
	 * XXX: For BEGIN, COMMIT AND ROLLBACK transaction commands, we send
	 * environment change tokens.  Ideally, the tokens should be sent from
	 * pltsql extension itself so that even when we execute the above commands
	 * as SQL batch, the tokens are sent correctly.
	 */
	switch (req->txnReqType)
	{
		case TDS_TM_BEGIN_XACT:
			{
				activity = psprintf("TDS_TM_BEGIN_XACT: %s", req->query.data);
				pgstat_report_activity(STATE_RUNNING, activity);
				pfree(activity);

				cmd_type = TDS_CMD_BEGIN;

				/*
				 * Client expects new transaction id as part of ENV change
				 * token but BEGIN does not generate new id until a write
				 * command is executed. So BEGIN returns 0 as new transaction
				 * id. This is OK as transaction id has value in the context
				 * of MARS only (client sends it as part of transaction stream
				 * header). To support MARS, fix it.
				 */
				TdsSendEnvChangeBinary(TDS_ENVID_BEGINTXN,
									   &txnId, sizeof(uint64_t),
									   NULL, 0);
			}
			break;
		case TDS_TM_COMMIT_XACT:
			{
				activity = psprintf("TDS_TM_COMMIT_XACT: %s", req->query.data);
				pgstat_report_activity(STATE_RUNNING, activity);
				pfree(activity);

				cmd_type = TDS_CMD_COMMIT;

				/*
				 * As BEGIN commands sends 0 as new transaction id, COMMIT has
				 * to do the same thing.
				 */
				TdsSendEnvChangeBinary(TDS_ENVID_COMMITTXN, NULL, 0,
									   &txnId, sizeof(uint64_t));
				if (req->nextTxn != NULL)
				{
					txnId = (uint64_t) MyProc->vxid.lxid;
					TdsSendEnvChangeBinary(TDS_ENVID_BEGINTXN,
										   &txnId, sizeof(uint64_t),
										   NULL, 0);
				}
			}
			break;
		case TDS_TM_ROLLBACK_XACT:
			{
				activity = psprintf("TDS_TM_ROLLBACK_XACT: %s", req->query.data);
				pgstat_report_activity(STATE_RUNNING, activity);
				pfree(activity);

				cmd_type = TDS_CMD_ROLLBACK;

				/*
				 * As BEGIN commands sends 0 as new transaction id, ROLLBACK
				 * has to do the same thing. But, we don't send the token for
				 * ROLLBACK TO SAVEPOINT command.  So if we've rolled back the
				 * top transaction, send the token.
				 */
				if (GetTopTransactionIdIfAny() == InvalidTransactionId)
					TdsSendEnvChangeBinary(TDS_ENVID_ROLLBACKTXN, NULL, 0,
										   &txnId, sizeof(uint64_t));
				if (req->nextTxn != NULL)
				{
					txnId = (uint64_t) MyProc->vxid.lxid;
					TdsSendEnvChangeBinary(TDS_ENVID_BEGINTXN,
										   &txnId, sizeof(uint64_t),
										   NULL, 0);
				}
			}
			break;
		default:
			break;
	}

	TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_FINAL, cmd_type, 0);
	pfree(codeblock);
}

int
TestTxnMgmtRequest(TDSRequest request, const char *expectedStr)
{
	int			res = 0;
	StringInfoData cmdStr;

	Assert(request->reqType == TDS_REQUEST_TXN_MGMT);
	initStringInfo(&cmdStr);
	BuildTxnMgmtRequestQuery(request, &cmdStr);
	res = strncmp(cmdStr.data,
				  expectedStr,
				  Min(cmdStr.len, strlen(expectedStr)));
	pfree(cmdStr.data);

	return res;
}
