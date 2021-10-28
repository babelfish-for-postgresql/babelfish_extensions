/*-------------------------------------------------------------------------
 *
 * tds_response.h
 *	  This file contains definitions for structures and externs used
 *	  by the response module of  TDS listener.
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/libpq/tds_response.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TDS_H
#define TDS_H

#include "nodes/pg_list.h"

#include "tds_int.h"

/* TDS token types */
#define TDS_TOKEN_COLMETADATA	0x81
#define TDS_TOKEN_COLINFO		0xA5
#define TDS_TOKEN_ERROR			0xAA
#define TDS_TOKEN_INFO			0xAB
#define TDS_TOKEN_LOGINACK		0xAD
#define TDS_TOKEN_ROW			0xD1
#define TDS_TOKEN_NBCROW		0xD2
#define TDS_TOKEN_ENVCHANGE		0xE3
#define TDS_TOKEN_SSPI			0xED
#define TDS_TOKEN_DONE			0xFD
#define TDS_TOKEN_DONEINPROC	0xFF
#define TDS_TOKEN_DONEPROC		0xFE
#define TDS_TOKEN_RETURNSTATUS	0x79
#define TDS_TOKEN_RETURNVALUE	0xAC
#define TDS_TOKEN_TABNAME		0xA4

/* TDS done codes */
#define TDS_DONE_FINAL			0x00
#define TDS_DONE_MORE			0x01
#define TDS_DONE_ERROR			0x02
#define TDS_DONE_INXACT			0x04
#define TDS_DONE_COUNT			0x10
#define TDS_DONE_ATTN           0x20

/* TDS command types in DONE token */
#define TDS_CMD_UNKNOWN			0x02
#define TDS_CMD_SET				0xBE
#define TDS_CMD_SELECT			0xC1
#define TDS_CMD_INSERT			0xC3
#define TDS_CMD_DELETE			0xC4
#define TDS_CMD_UPDATE			0xC5
#define TDS_CMD_ROLLBACK		0xD2
#define TDS_CMD_BEGIN			0xD4
#define TDS_CMD_COMMIT			0xD5
#define TDS_CMD_EXECUTE			0xE0
#define TDS_CMD_INFO			0xF7

/* Functions in tdsresponse.c */
extern void InitTDSResponse(void);
extern void TdsResponseReset(void);
extern ParameterToken MakeEmptyParameterToken(char *name, int atttypid,
											  int32 atttypmod, int attcollation);
extern int32 GetTypModForToken(ParameterToken token);
extern void TdsSendInfo(int number, int state, int class,
						   char *message, int line_no);
extern void TdsSendDone(int tag, int status,
						   int curcmd, uint64_t nprocessed);
extern void SendColumnMetadataToken(int natts, bool sendRowStat);
extern void SendTabNameToken(void);
extern void SendColInfoToken(int natts, bool sendRowStat);
extern void PrepareRowDescription(TupleDesc typeinfo, List *targetlist, int16 *formats,
					  bool extendedInfo, bool fetchPkeys);
extern void SendReturnValueTokenInternal(ParameterToken token, uint8 status,
							 FmgrInfo *finfo, Datum datum, bool isNull,
							 bool	forceCoercion);
extern void TdsSendEnvChange(int envid, const char *new_val, const char *old_val);
extern void TdsSendInfoOrError(int token, int number, int state, int class,
								  char *message, char *server_name,
								  char *proc_name, int line_no);
extern void TdsPrepareReturnValueMetaData(TupleDesc typeinfo);
extern void TdsSendEnvChangeBinary(int envid,
								void *new, int new_nbytes,
								void *old, int old_nbytes);
extern void TdsSendReturnStatus(int status);
extern void TdsSendHandle(void);
extern void TdsSendRowDescription(TupleDesc typeinfo,
									 List *targetlist, int16 *formats);
extern bool TdsPrintTup(TupleTableSlot *slot, DestReceiver *self);
extern void TdsPrintTupShutdown(void);
extern void TdsSendError(int number, int state, int class,
						   char *message, int lineNo);
extern int TdsFlush(void);
extern void TDSStatementBeginCallback(PLtsql_execstate *estate, PLtsql_stmt *stmt);
extern void TDSStatementEndCallback(PLtsql_execstate *estate, PLtsql_stmt *stmt);
extern void TDSStatementExceptionCallback(PLtsql_execstate *estate, PLtsql_stmt *stmt,
										  bool terminate_batch);
extern void SendColumnMetadata(TupleDesc typeinfo, List *targetlist, int16 *formats);
extern bool GetTdsEstateErrorData(int *number, int *severity, int *state);

#endif	/* TDS_H */
