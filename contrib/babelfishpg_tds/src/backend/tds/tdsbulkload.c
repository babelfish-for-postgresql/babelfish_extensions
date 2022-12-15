/*-------------------------------------------------------------------------
 *
 * tdsbulkload.c
 *	  TDS Listener functions for handling Bulk Load Requests
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdsbulkload.c
 *
 *-------------------------------------------------------------------------
 */


#include "postgres.h"

#include "utils/guc.h"
#include "lib/stringinfo.h"
#include "pgstat.h"

#include "src/include/tds_instr.h"
#include "src/include/tds_int.h"
#include "src/include/tds_protocol.h"
#include "src/include/tds_request.h"
#include "src/include/tds_response.h"
#include "src/include/tds_typeio.h"

static StringInfo SetBulkLoadRowData(TDSRequestBulkLoad request, StringInfo message);
void ProcessBCPRequest(TDSRequest request);
static void FetchMoreBcpData(StringInfo *message, int dataLenToRead);
static void FetchMoreBcpPlpData(StringInfo *message, int dataLenToRead);
static int ReadBcpPlp(ParameterToken temp, StringInfo *message, TDSRequestBulkLoad request);
uint64_t offset = 0;

#define COLUMNMETADATA_HEADER_LEN			sizeof(uint32_t) + sizeof(uint16) + 1
#define FIXED_LEN_TYPE_COLUMNMETADATA_LEN	1
#define NUMERIC_COLUMNMETADATA_LEN			3
#define STRING_COLUMNMETADATA_LEN			sizeof(uint32_t) + sizeof(uint16) + 1
#define BINARY_COLUMNMETADATA_LEN			sizeof(uint16)
#define SQL_VARIANT_COLUMNMETADATA_LEN		sizeof(uint32_t)


/* Check if retStatus Not OK. */
#define CheckPLPStatusNotOK(temp, retStatus, colNum) \
do \
{ \
	if (retStatus != STATUS_OK) \
	{ \
		ereport(ERROR, \
				(errcode(ERRCODE_PROTOCOL_VIOLATION), \
				 errmsg("The incoming tabular data stream (TDS) Bulk Load Request (BulkLoadBCP) protocol stream is incorrect. " \
					 "Row %d, column %d: The chunking format is incorrect for a " \
					 "large object parameter of data type 0x%02X.", \
					 temp->rowCount, colNum + 1, temp->colMetaData[i].columnTdsType))); \
	} \
} while(0)

/* For checking the invalid length in the request. */
#define CheckForInvalidLength(len, temp, colNum) \
do \
{ \
	if ((uint32_t)len > (uint32_t)temp->colMetaData[i].maxLen) \
		ereport(ERROR, \
				(errcode(ERRCODE_PROTOCOL_VIOLATION), \
				errmsg("The incoming tabular data stream (TDS) Bulk Load Request (BulkLoadBCP) protocol stream is incorrect. " \
						"Row %d, column %d: Data type 0x%02X has an invalid data length or metadata length.", \
						temp->rowCount, colNum + 1, temp->colMetaData[i].columnTdsType))); \
} while(0)

/* Check if Message has enough data to read, if not then fetch more. */
#define CheckMessageHasEnoughBytesToRead(message, dataLen) \
do \
{ \
	if ((*message)->len - offset < dataLen) \
		FetchMoreBcpData(message, dataLen); \
} while(0)

/* Check if Message has enough data to read, if not then fetch more. */
#define CheckPlpMessageHasEnoughBytesToRead(message, dataLen) \
do \
{ \
	if ((*message)->len - offset < dataLen) \
		FetchMoreBcpPlpData(message, dataLen); \
} while(0)

static void
FetchMoreBcpData(StringInfo *message, int dataLenToRead)
{
	StringInfo temp;
	int ret;

	/* Unlikely that message will be NULL. */
	if ((*message) == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("Protocol violation: Message data is NULL")));

	/*
	 * If previous return value was 1 then that means that we have reached the EOM.
	 * No data left to read, we shall throw an error if we reach here.
	 */
	if (TdsGetRecvPacketEomStatus())
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("Trying to read more data than available in BCP request.")));

	temp = makeStringInfo();
	appendBinaryStringInfo(temp, (*message)->data + offset, (*message)->len - offset);

	if ((*message)->data)
		pfree((*message)->data);
	pfree((*message));

	/*
	 * Keep fetching for additional packets until we have enough
	 * data to read.
	 */
	while (dataLenToRead > temp->len)
	{
		/*
		 * We should hold the interrupts until we read the next
		 * request frame.
		 */
		HOLD_CANCEL_INTERRUPTS();
		ret = TdsReadNextPendingBcpRequest(temp);
		RESUME_CANCEL_INTERRUPTS();

		if (ret < 0)
		{
			TdsErrorContext->reqType = 0;
			TdsErrorContext->err_text = "EOF on TDS socket while fetching For Bulk Load Request";
			pfree(temp->data);
			pfree(temp);
			ereport(ERROR,
					(errcode(ERRCODE_PROTOCOL_VIOLATION),
						errmsg("EOF on TDS socket while fetching For Bulk Load Request")));
			return;
		}
	}

	offset = 0;
	(*message) = temp;
}

/*
 * Incase of PLP data we should not discard the previous packet since we
 * first store the offset of the PLP Chunks first and then read the data later.
 */
static void
FetchMoreBcpPlpData(StringInfo *message, int dataLenToRead)
{
	int ret;

	/* Unlikely that message will be NULL. */
	if ((*message) == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("Protocol violation: Message data is NULL")));

	/*
	 * If previous return value was 1 then that means that we have reached the EOM.
	 * No data left to read, we shall throw an error if we reach here.
	 */
	if (TdsGetRecvPacketEomStatus())
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("Trying to read more data than available in BCP request.")));

	/*
	 * Keep fetching for additional packets until we have enough
	 * data to read.
	 */
	while (dataLenToRead + offset > (*message)->len)
	{
		/*
		 * We should hold the interrupts until we read the next
		 * request frame.
		 */
		HOLD_CANCEL_INTERRUPTS();
		ret = TdsReadNextPendingBcpRequest(*message);
		RESUME_CANCEL_INTERRUPTS();

		if (ret < 0)
		{
			TdsErrorContext->reqType = 0;
			TdsErrorContext->err_text = "EOF on TDS socket while fetching For Bulk Load Request";
			ereport(ERROR,
					(errcode(ERRCODE_PROTOCOL_VIOLATION),
						errmsg("EOF on TDS socket while fetching For Bulk Load Request")));
			return;
		}
	}
}

/*
 * GetBulkLoadRequest - Builds the request structure associated
 * with Bulk Load.
 * TODO: Reuse for TVP.
 */
TDSRequest
GetBulkLoadRequest(StringInfo message)
{
	TDSRequestBulkLoad		request;
	uint16_t 				colCount;
	BulkLoadColMetaData 			*colmetadata;

	TdsErrorContext->err_text = "Fetching Bulk Load Request";

	TDSInstrumentation(INSTR_TDS_BULK_LOAD_REQUEST);

	request = palloc0(sizeof(TDSRequestBulkLoadData));
	request->rowData 		= NIL;
	request->reqType 		= TDS_REQUEST_BULK_LOAD;

	if(unlikely((uint8_t)message->data[offset] != TDS_TOKEN_COLMETADATA))
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("The incoming tabular data stream (TDS) Bulk Load Request (BulkLoadBCP) protocol stream is incorrect. "
							"unexpected token encountered processing the request.")));

	offset++;
	Assert(sizeof(uint16)<=sizeof(colCount));
	memcpy(&colCount, &message->data[offset], sizeof(uint16));
	colmetadata = palloc0(colCount * sizeof(BulkLoadColMetaData));
	request->colCount = colCount;
	request->colMetaData = colmetadata;
	offset += sizeof(uint16);

	for (int currentColumn = 0; currentColumn < colCount; currentColumn++)
	{
		CheckMessageHasEnoughBytesToRead(&message, COLUMNMETADATA_HEADER_LEN);
		/* UserType */
		Assert(sizeof(uint32_t)<=sizeof(colmetadata[currentColumn].userType));
		memcpy(&colmetadata[currentColumn].userType, &message->data[offset], sizeof(uint32_t));
		offset += sizeof(uint32_t);

		/* Flags */
		Assert(sizeof(uint16)<=sizeof(colmetadata[currentColumn].flags));
		memcpy(&colmetadata[currentColumn].flags, &message->data[offset], sizeof(uint16));
		offset += sizeof(uint16);

		/* TYPE_INFO */
		colmetadata[currentColumn].columnTdsType = message->data[offset++];

		/* Datatype specific Column Metadata. */
		switch(colmetadata[currentColumn].columnTdsType)
		{
			case TDS_TYPE_INTEGER:
			case TDS_TYPE_BIT:
			case TDS_TYPE_FLOAT:
			case TDS_TYPE_MONEYN:
			case TDS_TYPE_DATETIMEN:
			case TDS_TYPE_UNIQUEIDENTIFIER:
				CheckMessageHasEnoughBytesToRead(&message, FIXED_LEN_TYPE_COLUMNMETADATA_LEN);
				colmetadata[currentColumn].maxLen = message->data[offset++];
			break;
			case TDS_TYPE_DECIMALN:
			case TDS_TYPE_NUMERICN:
				CheckMessageHasEnoughBytesToRead(&message, NUMERIC_COLUMNMETADATA_LEN);
				colmetadata[currentColumn].maxLen    = message->data[offset++];
				colmetadata[currentColumn].precision = message->data[offset++];
				colmetadata[currentColumn].scale 	 = message->data[offset++];
			break;
			case TDS_TYPE_CHAR:
			case TDS_TYPE_VARCHAR:
			case TDS_TYPE_NCHAR:
			case TDS_TYPE_NVARCHAR:
			{
				CheckMessageHasEnoughBytesToRead(&message, STRING_COLUMNMETADATA_LEN);
				Assert(sizeof(uint16)<=sizeof(colmetadata[currentColumn].maxLen));
				memcpy(&colmetadata[currentColumn].maxLen, &message->data[offset], sizeof(uint16));
				offset += sizeof(uint16);
				Assert(sizeof(uint32_t)<=sizeof(colmetadata[currentColumn].collation));
				memcpy(&colmetadata[currentColumn].collation, &message->data[offset], sizeof(uint32_t));
				offset += sizeof(uint32_t);
				colmetadata[currentColumn].sortId = message->data[offset++];
			}
			break;
			case TDS_TYPE_TEXT:
			case TDS_TYPE_NTEXT:
			case TDS_TYPE_IMAGE:
			{
				uint16_t tableLen = 0;
				CheckMessageHasEnoughBytesToRead(&message, sizeof(uint32_t));
				Assert(sizeof(uint32_t)<=sizeof(colmetadata[currentColumn].maxLen));
				memcpy(&colmetadata[currentColumn].maxLen, &message->data[offset], sizeof(uint32_t));
				offset += sizeof(uint32_t);

				/* Read collation(LICD) and sort-id for TEXT and NTEXT. */
				if (colmetadata[currentColumn].columnTdsType == TDS_TYPE_TEXT ||
					colmetadata[currentColumn].columnTdsType == TDS_TYPE_NTEXT)
				{
					CheckMessageHasEnoughBytesToRead(&message, sizeof(uint32_t) + 1);
					Assert(sizeof(uint32_t)<=sizeof(colmetadata[currentColumn].collation));
					memcpy(&colmetadata[currentColumn].collation, &message->data[offset], sizeof(uint32_t));
					offset += sizeof(uint32_t);
					colmetadata[currentColumn].sortId = message->data[offset++];
				}

				CheckMessageHasEnoughBytesToRead(&message, sizeof(uint16_t));
				Assert(sizeof(uint16_t)<=sizeof(tableLen));
				memcpy(&tableLen, &message->data[offset], sizeof(uint16_t));
				offset += sizeof(uint16_t);

				/* Skip table name for now. */
				CheckMessageHasEnoughBytesToRead(&message, tableLen * 2);
				offset += tableLen * 2;
			}
			break;
			case TDS_TYPE_XML:
			{
				CheckMessageHasEnoughBytesToRead(&message, 1);
				colmetadata[currentColumn].maxLen = message->data[offset++];
			}
			break;
			case TDS_TYPE_DATETIME2:
			{
				CheckMessageHasEnoughBytesToRead(&message, FIXED_LEN_TYPE_COLUMNMETADATA_LEN);
				colmetadata[currentColumn].scale = message->data[offset++];
				colmetadata[currentColumn].maxLen = 8;
			}
			break;
			case TDS_TYPE_TIME:
			{
				CheckMessageHasEnoughBytesToRead(&message, FIXED_LEN_TYPE_COLUMNMETADATA_LEN);
				colmetadata[currentColumn].scale = message->data[offset++];
				colmetadata[currentColumn].maxLen = 5;
			}
			break;
			case TDS_TYPE_DATETIMEOFFSET:
			{
				CheckMessageHasEnoughBytesToRead(&message, FIXED_LEN_TYPE_COLUMNMETADATA_LEN);
				colmetadata[currentColumn].scale = message->data[offset++];
				colmetadata[currentColumn].maxLen = 10;
			}
			break;
			case TDS_TYPE_BINARY:
			case TDS_TYPE_VARBINARY:
			{
				uint16 plp;
				CheckMessageHasEnoughBytesToRead(&message, BINARY_COLUMNMETADATA_LEN);
				Assert(sizeof(uint16)<=sizeof(plp));
				memcpy(&plp, &message->data[offset], sizeof(uint16));
				offset += sizeof(uint16);
				colmetadata[currentColumn].maxLen = plp;
			}
			break;
			case TDS_TYPE_DATE:
				colmetadata[currentColumn].maxLen = 3;
			break;
			case TDS_TYPE_SQLVARIANT:
				CheckMessageHasEnoughBytesToRead(&message, SQL_VARIANT_COLUMNMETADATA_LEN);
				Assert(sizeof(uint32_t)<=sizeof(colmetadata[currentColumn].maxLen));
				memcpy(&colmetadata[currentColumn].maxLen, &message->data[offset], sizeof(uint32_t));
				offset += sizeof(uint32_t);
			break;
			/*
			 * Below cases are for variant types; in case of fixed length datatype columns, with
			 * a Not NUll constraint, makes use of this type as an optimisation for not receiving
			 * the the lengths for the column metadata and row data.
			 */
			case VARIANT_TYPE_INT:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_INTEGER;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_INT;
			}
			break;
			case VARIANT_TYPE_BIT:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_BIT;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_BIT;
			}
			break;
			case VARIANT_TYPE_BIGINT:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_INTEGER;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_BIGINT;
			}
			break;
			case VARIANT_TYPE_SMALLINT:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_INTEGER;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_SMALLINT;
			}
			break;
			case VARIANT_TYPE_TINYINT:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_INTEGER;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_TINYINT;
			}
			break;
			case VARIANT_TYPE_REAL:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_FLOAT;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_FLOAT4;
			}
			break;
			case VARIANT_TYPE_FLOAT:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_FLOAT;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_FLOAT8;
			}
			break;
			case VARIANT_TYPE_DATETIME:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_DATETIMEN;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_DATETIME;
			}
			break;
			case VARIANT_TYPE_SMALLDATETIME:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_DATETIMEN;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_SMALLDATETIME;
			}
			break;
			case VARIANT_TYPE_MONEY:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_MONEYN;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_MONEY;
			}
			break;
			case VARIANT_TYPE_SMALLMONEY:
			{
				colmetadata[currentColumn].columnTdsType = TDS_TYPE_MONEYN;
				colmetadata[currentColumn].variantType = true;
				colmetadata[currentColumn].maxLen = TDS_MAXLEN_SMALLMONEY;
			}
			break;
			default:
			    ereport(ERROR,
						(errcode(ERRCODE_PROTOCOL_VIOLATION),
						errmsg("The incoming tabular data stream (TDS) is incorrect. "
							"Data type 0x%02X is unknown.", colmetadata[currentColumn].columnTdsType)));
		}

		/* Column Name */
		CheckMessageHasEnoughBytesToRead(&message, sizeof(uint8_t));
		Assert(sizeof(uint8_t)<=sizeof(colmetadata[currentColumn].colNameLen));
		memcpy(&colmetadata[currentColumn].colNameLen, &message->data[offset++], sizeof(uint8_t));

		CheckMessageHasEnoughBytesToRead(&message, colmetadata[currentColumn].colNameLen * 2);
		colmetadata[currentColumn].colName = (char *)palloc0(colmetadata[currentColumn].colNameLen * sizeof(char) * 2 + 1);
		Assert((colmetadata[currentColumn].colNameLen * 2)<=sizeof(colmetadata[currentColumn].colName));
		memcpy(colmetadata[currentColumn].colName, &message->data[offset],
					colmetadata[currentColumn].colNameLen * 2);
		colmetadata[currentColumn].colName[colmetadata[currentColumn].colNameLen * 2] = '\0';

		offset += colmetadata[currentColumn].colNameLen * 2;
	}
	request->firstMessage = makeStringInfo();
	appendBinaryStringInfo(request->firstMessage, message->data, message->len);
	return (TDSRequest)request;
}

/*
 * SetBulkLoadRowData - Builds the row data structure associated
 * with Bulk Load.
 * TODO: Reuse for TVP.
 */
static StringInfo
SetBulkLoadRowData(TDSRequestBulkLoad request, StringInfo message)
{
	BulkLoadColMetaData *colmetadata = request->colMetaData;
	int retStatus = 0;
	uint32_t len;
	StringInfo temp = palloc0(sizeof(StringInfoData));
	request->rowCount = 0;
	request->rowData = NIL;
	request->currentBatchSize = 0;

	CheckMessageHasEnoughBytesToRead(&message, 1);

	/* Loop over each row. */
	while((uint8_t)message->data[offset] == TDS_TOKEN_ROW
			&& request->currentBatchSize < pltsql_plugin_handler_ptr->get_insert_bulk_kilobytes_per_batch() * 1024
			&& request->rowCount < pltsql_plugin_handler_ptr->get_insert_bulk_rows_per_batch())
	{
		int i = 0; /* Current Column Number. */
		BulkLoadRowData *rowData = palloc0(sizeof(BulkLoadRowData));
		request->rowCount++;

		rowData->columnValues = palloc0(request->colCount * sizeof(Datum));
		rowData->isNull 	  = palloc0(request->colCount * sizeof(bool));

		offset++;
		request->currentBatchSize++;

		while(i != request->colCount) /* Loop over each column. */
		{
			len = 0;
			switch(colmetadata[i].columnTdsType)
			{
				case TDS_TYPE_INTEGER:
				case TDS_TYPE_BIT:
				case TDS_TYPE_FLOAT:
				case TDS_TYPE_TIME:
				case TDS_TYPE_DATE:
				case TDS_TYPE_DATETIME2:
				case TDS_TYPE_DATETIMEN:
				case TDS_TYPE_MONEYN:
				case TDS_TYPE_UNIQUEIDENTIFIER:
				case TDS_TYPE_DATETIMEOFFSET:
				{
					if (colmetadata[i].variantType)
					{
						len = colmetadata[i].maxLen;
					}
					else
					{
						CheckMessageHasEnoughBytesToRead(&message, 1);
						len = message->data[offset++];
						request->currentBatchSize++;

						if (len == 0) /* null */
						{
							rowData->isNull[i] = true;
							i++;
							continue;
						}
					}
					CheckForInvalidLength(len, request, i);

					CheckMessageHasEnoughBytesToRead(&message, len);

					/* Build temp Stringinfo. */
					temp->data = &message->data[offset];
					temp->len = len;
					temp->maxlen = colmetadata[i].maxLen;
					temp->cursor = 0;

					/* Create and store the appropriate datum for this column. */
					switch(colmetadata[i].columnTdsType)
					{
						case TDS_TYPE_INTEGER:
						case TDS_TYPE_BIT:
							rowData->columnValues[i] = TdsTypeIntegerToDatum(temp, colmetadata[i].maxLen);
						break;
						case TDS_TYPE_FLOAT:
							rowData->columnValues[i] = TdsTypeFloatToDatum(temp, colmetadata[i].maxLen);
						break;
						case TDS_TYPE_TIME:
							rowData->columnValues[i] = TdsTypeTimeToDatum(temp, colmetadata[i].scale, len);
						break;
						case TDS_TYPE_DATE:
							rowData->columnValues[i] = TdsTypeDateToDatum(temp);
						break;
						case TDS_TYPE_DATETIME2:
							rowData->columnValues[i] = TdsTypeDatetime2ToDatum(temp, colmetadata[i].scale, temp->len);
						break;
						case TDS_TYPE_DATETIMEN:
							if (colmetadata[i].maxLen == TDS_MAXLEN_SMALLDATETIME)
								rowData->columnValues[i] = TdsTypeSmallDatetimeToDatum(temp);
							else
								rowData->columnValues[i] = TdsTypeDatetimeToDatum(temp);
						break;
						case TDS_TYPE_DATETIMEOFFSET:
							rowData->columnValues[i] = TdsTypeDatetimeoffsetToDatum(temp, colmetadata[i].scale, temp->len);
						break;
						case TDS_TYPE_MONEYN:
							if (colmetadata[i].maxLen == TDS_MAXLEN_SMALLMONEY)
								rowData->columnValues[i] = TdsTypeSmallMoneyToDatum(temp);
							else
								rowData->columnValues[i] = TdsTypeMoneyToDatum(temp);
						break;
						case TDS_TYPE_UNIQUEIDENTIFIER:
							rowData->columnValues[i] = TdsTypeUIDToDatum(temp);
						break;
					}

					offset += len;
					request->currentBatchSize += len;
				}
				break;
				case TDS_TYPE_NUMERICN:
				case TDS_TYPE_DECIMALN:
				{
					if (colmetadata[i].scale > colmetadata[i].precision)
						ereport(ERROR,
								(errcode(ERRCODE_PROTOCOL_VIOLATION),
									errmsg("The incoming tabular data stream (TDS) Bulk Load Request (BulkLoadBCP) protocol stream is incorrect. "
										"Row %d, column %d: The supplied value is not a valid instance of data type Numeric/Decimal. "
										"Check the source data for invalid values. An example of an invalid value is data of numeric type with scale greater than precision.",
										request->rowCount, i + 1)));

					CheckMessageHasEnoughBytesToRead(&message, 1);

					len = message->data[offset++];
					request->currentBatchSize++;
					if (len == 0) /* null */
					{
						rowData->isNull[i] = true;
						i++;
						continue;
					}

					CheckForInvalidLength(len, request, i);

					CheckMessageHasEnoughBytesToRead(&message, len);

					/* Build temp Stringinfo. */
					temp->data = &message->data[offset];
					temp->len = len;
					temp->maxlen = colmetadata[i].maxLen;
					temp->cursor = 0;

					/* Create and store the appropriate datum for this column. */
					rowData->columnValues[i] = TdsTypeNumericToDatum(temp, colmetadata[i].scale);

					offset += len;
					request->currentBatchSize += len;
				}
				break;

				case TDS_TYPE_CHAR:
				case TDS_TYPE_VARCHAR:
				case TDS_TYPE_NCHAR:
				case TDS_TYPE_NVARCHAR:
				case TDS_TYPE_BINARY:
				case TDS_TYPE_VARBINARY:
				{
					if (colmetadata[i].maxLen != 0xffff)
					{
						CheckMessageHasEnoughBytesToRead(&message, sizeof(short));
						Assert(sizeof(short)<=sizeof(len));
						memcpy(&len, &message->data[offset], sizeof(short));
						offset +=  sizeof(short);
						request->currentBatchSize +=  sizeof(short);
						if (len != 0xffff)
						{
							CheckForInvalidLength(len, request, i);

							CheckMessageHasEnoughBytesToRead(&message, len);

							/* Build temp Stringinfo. */
							temp->data = &message->data[offset];
							temp->len = len;
							temp->maxlen = colmetadata[i].maxLen;
							temp->cursor = 0;

							offset += len;
							request->currentBatchSize += len;
						}
						else /* null */
						{
							rowData->isNull[i] = true;
							i++;
							continue;
						}
					}
					else
					{
						ParameterToken token = palloc0(sizeof(ParameterTokenData));

						retStatus = ReadBcpPlp(token, &message, request);

						CheckPLPStatusNotOK(request, retStatus, i);
						if (token->isNull) /* null */
						{
							rowData->isNull[i] = true;
							i++;
							token->isNull = false;
							continue;
						}

						/* Free the previously allocated temp. */
						pfree(temp);
						temp = TdsGetPlpStringInfoBufferFromToken(message->data, token);
						pfree(token);
					}

					/* Create and store the appropriate datum for this column. */
					switch(colmetadata[i].columnTdsType)
					{
						case TDS_TYPE_CHAR:
						case TDS_TYPE_VARCHAR:
							rowData->columnValues[i] = TdsTypeVarcharToDatum(temp, colmetadata[i].collation, colmetadata[i].columnTdsType);
						break;
						case TDS_TYPE_NCHAR:
						case TDS_TYPE_NVARCHAR:
							rowData->columnValues[i] = TdsTypeNCharToDatum(temp);
						break;
						case TDS_TYPE_BINARY:
						case TDS_TYPE_VARBINARY:
							rowData->columnValues[i] = TdsTypeVarbinaryToDatum(temp);
						break;
					}
					/*
					 * Free temp->data only if this was created as part of PLP parsing.
					 * We do not free temp pointer since it can be re-used for the next iteration.
					 */
					if (colmetadata[i].maxLen == 0xffff)
						pfree(temp->data);
				}
				break;
				case TDS_TYPE_TEXT:
				case TDS_TYPE_NTEXT:
				case TDS_TYPE_IMAGE:
				{
					uint8 dataTextPtrLen;

					CheckMessageHasEnoughBytesToRead(&message, 1);
					/* Ignore the Data Text Ptr since its currently of no use. */
					dataTextPtrLen = message->data[offset++];
					request->currentBatchSize++;
					if (dataTextPtrLen == 0) /* null */
					{
						rowData->isNull[i] = true;
						i++;
						continue;
					}

					CheckMessageHasEnoughBytesToRead(&message, dataTextPtrLen + 8 + sizeof(uint32_t));

					offset += dataTextPtrLen;
					request->currentBatchSize += dataTextPtrLen;
					offset += 8; /* TODO: Ignored the Data Text TimeStamp for now. */
					request->currentBatchSize += 8;
					Assert(sizeof(uint32_t)<=sizeof(len));
					memcpy(&len, &message->data[offset], sizeof(uint32_t));
					offset +=  sizeof(uint32_t);
					request->currentBatchSize += sizeof(uint32_t);
					if (len == 0) /* null */
					{
						rowData->isNull[i] = true;
						i++;
						continue;
					}

					CheckForInvalidLength(len, request, i);

					CheckMessageHasEnoughBytesToRead(&message, len);

					/* Build temp Stringinfo. */
					temp->data = &message->data[offset];
					temp->len = len;
					temp->maxlen = colmetadata[i].maxLen;
					temp->cursor = 0;

					/* Create and store the appropriate datum for this column. */
					switch(colmetadata[i].columnTdsType)
					{
						case TDS_TYPE_TEXT:
							rowData->columnValues[i] = TdsTypeVarcharToDatum(temp, colmetadata[i].collation, colmetadata[i].columnTdsType);
						break;
						case TDS_TYPE_NTEXT:
							rowData->columnValues[i] = TdsTypeNCharToDatum(temp);
						break;
						case TDS_TYPE_IMAGE:
							rowData->columnValues[i] = TdsTypeVarbinaryToDatum(temp);
						break;
					}

					offset += len;
					request->currentBatchSize += len;
				}
				break;
				case TDS_TYPE_XML:
				{
					ParameterToken token = palloc0(sizeof(ParameterTokenData));

					retStatus = ReadBcpPlp(token, &message, request);
					CheckPLPStatusNotOK(request, retStatus, i);
					if (token->isNull) /* null */
					{
						rowData->isNull[i] = true;
						i++;
						token->isNull = false;
						continue;
					}
					/* Free the previously allocated temp. */
					pfree(temp);
					temp = TdsGetPlpStringInfoBufferFromToken(message->data, token);
					/* Create and store the appropriate datum for this column. */
					rowData->columnValues[i] = TdsTypeXMLToDatum(temp);

					/* We do not free temp pointer since it can be re-used for the next iteration. */
					pfree(temp->data);
					pfree(token);
				}
				break;
				case TDS_TYPE_SQLVARIANT:
				{
					CheckMessageHasEnoughBytesToRead(&message, sizeof(uint32_t));
					Assert(sizeof(uint32_t)<=sizeof(len));
					memcpy(&len, &message->data[offset], sizeof(uint32_t));
					offset += sizeof(uint32_t);
					request->currentBatchSize += sizeof(uint32_t);

					if (len == 0) /* null */
					{
						rowData->isNull[i] = true;
						i++;
						continue;
					}

					CheckForInvalidLength(len, request, i);

					CheckMessageHasEnoughBytesToRead(&message, len);

					/* Build temp Stringinfo. */
					temp->data = &message->data[offset];
					temp->len = len;
					temp->maxlen = colmetadata[i].maxLen;
					temp->cursor = 0;

					/* Create and store the appropriate datum for this column. */
					rowData->columnValues[i] = TdsTypeSqlVariantToDatum(temp);

					offset += len;
					request->currentBatchSize += len;
				}
				break;
			}
			i++;
		}
		request->rowData = lappend(request->rowData, rowData);
		CheckMessageHasEnoughBytesToRead(&message, 1);
	}

	/*
	 * If row count is less than the default batch size then this is the last packet,
	 * the next byte should be the done token.
	 */
	CheckMessageHasEnoughBytesToRead(&message, 1);

	if (request->rowCount < pltsql_plugin_handler_ptr->get_insert_bulk_rows_per_batch()
			&& request->currentBatchSize < pltsql_plugin_handler_ptr->get_insert_bulk_kilobytes_per_batch() * 1024
			&& (uint8_t)message->data[offset] != TDS_TOKEN_DONE)
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("The incoming tabular data stream (TDS) Bulk Load Request (BulkLoadBCP) protocol stream is incorrect. "
						"Row %d, unexpected token encountered processing the request. %d",
						request->rowCount, (uint8_t)message->data[offset])));

	pfree(temp);
	return message;
}

/*
 * ProcessBCPRequest - Processes the request and calls the bulk_load_callback
 * for futher execution.
 * TODO: Reuse for TVP.
 */
void
ProcessBCPRequest(TDSRequest request)
{
	uint64 retValue = 0;
	TDSRequestBulkLoad req = (TDSRequestBulkLoad) request;
	StringInfo message = req->firstMessage;

	TdsErrorContext->err_text = "Processing Bulk Load Request";
	pgstat_report_activity(STATE_RUNNING, "Processing Bulk Load Request");

	while (1)
	{
		int nargs = 0;
		Datum *values = NULL;
		bool *nulls = NULL;
		int count = 0;
		ListCell 	*lc;

		PG_TRY();
		{
			message = SetBulkLoadRowData(req, message);
		}
		PG_CATCH();
		{
			int ret;
			HOLD_CANCEL_INTERRUPTS();
			/*
			 * Discard remaining TDS_BULK_LOAD packets only if End of Message has not been reached for the
			 * current request. Otherwise we have no TDS_BULK_LOAD packets left for the current request
			 * that need to be discarded.
			 */
			if (!TdsGetRecvPacketEomStatus())
				ret = TdsDiscardAllPendingBcpRequest();

			RESUME_CANCEL_INTERRUPTS();

			if (ret < 0)
				TdsErrorContext->err_text = "EOF on TDS socket while fetching For Bulk Load Request";

			PG_RE_THROW();
		}
		PG_END_TRY();
		/*
		 * If the row-count is 0 then there are no rows left to be inserted.
		 * We should begin with cleanup.
		 */
		if (req->rowCount == 0)
		{
			/* Using Same callback function to do the clean-up. */
			pltsql_plugin_handler_ptr->bulk_load_callback(0, 0, NULL, NULL);
			break;
		}

		nargs = req->colCount * req->rowCount;
		values = palloc0(nargs * sizeof(Datum));
		nulls = palloc0(nargs * sizeof(bool));

		/* Flaten and create a 1-D array of Value & Datums */
		foreach (lc, req->rowData)
		{
			BulkLoadRowData *row = (BulkLoadRowData *) lfirst(lc);
			for(int currentColumn = 0; currentColumn < req->colCount; currentColumn++)
			{
				if (row->isNull[currentColumn]) /* null */
					nulls[count] = row->isNull[currentColumn];
				else
					values[count] = row->columnValues[currentColumn];
				count++;
			}
		}

		if (req->rowData) /* If any row exists then do an insert. */
		{
			PG_TRY();
			{
				retValue += pltsql_plugin_handler_ptr->bulk_load_callback(req->colCount,
											req->rowCount, values, nulls);
			}
			PG_CATCH();
			{
				int ret;
				HOLD_CANCEL_INTERRUPTS();

				/*
				 * Discard remaining TDS_BULK_LOAD packets only if End of Message has not been reached for the
				 * current request. Otherwise we have no TDS_BULK_LOAD packets left for the current request
				 * that need to be discarded.
				 */
				if (!TdsGetRecvPacketEomStatus())
					ret = TdsDiscardAllPendingBcpRequest();

				RESUME_CANCEL_INTERRUPTS();

				/* Using Same callback function to do the clean-up. */
				pltsql_plugin_handler_ptr->bulk_load_callback(0, 0, NULL, NULL);

				if (ret < 0)
					TdsErrorContext->err_text = "EOF on TDS socket while fetching For Bulk Load Request";

				if (TDS_DEBUG_ENABLED(TDS_DEBUG2))
					ereport(LOG,
							(errmsg("Bulk Load Request. Number of Rows: %d and Number of columns: %d.",
							req->rowCount, req->colCount),
							errhidestmt(true)));

				PG_RE_THROW();
			}
			PG_END_TRY();
			/* Free the List of Rows. */
			list_free_deep(req->rowData);
			req->rowData = NIL;
			if (values)
				pfree(values);
			if (nulls)
				pfree(nulls);
		}
	}

	/* Send Done Token if rows processed is a positive number. Command type - execute (0xf0). */
	if (retValue >= 0)
		TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_COUNT, 0xf0, retValue);
	else /* Send Unknown Error. */
		ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
			errmsg("Unknown error occurred during Insert Bulk")));

	/*
	 * Log immediately if dictated by log_statement.
	 */
	if (pltsql_plugin_handler_ptr->stmt_needs_logging || TDS_DEBUG_ENABLED(TDS_DEBUG2))
	{
		ErrorContextCallback *plerrcontext = error_context_stack;
		error_context_stack = plerrcontext->previous;
		ereport(LOG,
				(errmsg("Bulk Load Request. Number of Rows: %d and Number of columns: %d.",
				req->rowCount, req->colCount),
				errhidestmt(true)));
		pltsql_plugin_handler_ptr->stmt_needs_logging = false;
		error_context_stack = plerrcontext;
	}
	offset = 0;
}

static int
ReadBcpPlp(ParameterToken temp, StringInfo *message, TDSRequestBulkLoad request)
{
	uint64_t plpTok;
	Plp plpTemp, plpPrev = NULL;
	unsigned long lenCheck = 0;

	CheckPlpMessageHasEnoughBytesToRead(message, sizeof(plpTok));
	Assert(sizeof(plpTok)<=sizeof(plpTok));
	memcpy(&plpTok , &(*message)->data[offset], sizeof(plpTok));
	offset += sizeof(plpTok);
	request->currentBatchSize += sizeof(plpTok);
	temp->plp = NULL;

	/* NULL Check */
	if (plpTok == PLP_NULL)
	{
		temp->isNull = true;
		return STATUS_OK;
	}

	while (true)
	{
		uint32_t tempLen;

		CheckPlpMessageHasEnoughBytesToRead(message, sizeof(tempLen));
		if (offset + sizeof(tempLen) > (*message)->len)
			return STATUS_ERROR;
		Assert(sizeof(tempLen)<=sizeof(tempLen));
		memcpy(&tempLen , &(*message)->data[offset], sizeof(tempLen));
		offset += sizeof(tempLen);
		request->currentBatchSize += sizeof(tempLen);

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

		CheckPlpMessageHasEnoughBytesToRead(message, plpTemp->len);
		if (offset + plpTemp->len > (*message)->len)
			return STATUS_ERROR;

		offset += plpTemp->len;
		request->currentBatchSize += plpTemp->len;
		lenCheck += plpTemp->len;
	}

	if (plpTok != PLP_UNKNOWN_LEN)
	{
		/* Length check */
		if (lenCheck != plpTok)
			return STATUS_ERROR;
	}

	return STATUS_OK;
}