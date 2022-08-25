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
#define CheckForInvalidLength(rowData, temp, colNum) \
do \
{ \
	if ((uint32_t)rowData->columnValues[i].len > (uint32_t)temp->colMetaData[i].maxLen) \
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

	memcpy(&colCount, &message->data[offset], sizeof(uint16));
	colmetadata = palloc0(colCount * sizeof(BulkLoadColMetaData));
	request->colCount = colCount;
	request->colMetaData = colmetadata;
	offset += sizeof(uint16);

	for (int currentColumn = 0; currentColumn < colCount; currentColumn++)
	{
		CheckMessageHasEnoughBytesToRead(&message, COLUMNMETADATA_HEADER_LEN);
		/* UserType */
		memcpy(&colmetadata[currentColumn].userType, &message->data[offset], sizeof(uint32_t));
		offset += sizeof(uint32_t);

		/* Flags */
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
				memcpy(&colmetadata[currentColumn].maxLen, &message->data[offset], sizeof(uint16));
				offset += sizeof(uint16);

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
				memcpy(&colmetadata[currentColumn].maxLen, &message->data[offset], sizeof(uint32_t));
				offset += sizeof(uint32_t);

				/* Read collation(LICD) and sort-id for TEXT and NTEXT. */
				if (colmetadata[currentColumn].columnTdsType == TDS_TYPE_TEXT ||
					colmetadata[currentColumn].columnTdsType == TDS_TYPE_NTEXT)
				{
					CheckMessageHasEnoughBytesToRead(&message, sizeof(uint32_t) + 1);
					memcpy(&colmetadata[currentColumn].collation, &message->data[offset], sizeof(uint32_t));
					offset += sizeof(uint32_t);
					colmetadata[currentColumn].sortId = message->data[offset++];
				}

				CheckMessageHasEnoughBytesToRead(&message, sizeof(uint16_t));
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
		memcpy(&colmetadata[currentColumn].colNameLen, &message->data[offset++], sizeof(uint8_t));

		CheckMessageHasEnoughBytesToRead(&message, colmetadata[currentColumn].colNameLen * 2);
		colmetadata[currentColumn].colName = (char *)palloc0(colmetadata[currentColumn].colNameLen * sizeof(char) * 2 + 1);
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

		rowData->columnValues = palloc0(request->colCount * sizeof(StringInfoData));
		rowData->isNull 	  = palloc0(request->colCount);

		offset++;
		request->currentBatchSize++;

		while(i != request->colCount) /* Loop over each column. */
		{
			initStringInfo(&rowData->columnValues[i]);
			rowData->isNull[i] = 'f';
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
				{
					if (colmetadata[i].variantType)
					{
						rowData->columnValues[i].len = colmetadata[i].maxLen;
					}
					else
					{
						CheckMessageHasEnoughBytesToRead(&message, 1);
						rowData->columnValues[i].len = message->data[offset++];
						request->currentBatchSize++;

						if (rowData->columnValues[i].len == 0) /* null */
						{
							rowData->isNull[i] = 'n';
							i++;
							continue;
						}
					}
					CheckForInvalidLength(rowData, request, i);

					if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
						enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

					CheckMessageHasEnoughBytesToRead(&message, rowData->columnValues[i].len);
					memcpy(rowData->columnValues[i].data, &message->data[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
					request->currentBatchSize += rowData->columnValues[i].len;
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

					rowData->columnValues[i].len = message->data[offset++];
					request->currentBatchSize++;
					if (rowData->columnValues[i].len == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}

					CheckForInvalidLength(rowData, request, i);

					if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
						enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

					CheckMessageHasEnoughBytesToRead(&message, rowData->columnValues[i].len);

					memcpy(rowData->columnValues[i].data, &message->data[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
					request->currentBatchSize += rowData->columnValues[i].len;
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
						memcpy(&rowData->columnValues[i].len, &message->data[offset], sizeof(short));
						offset +=  sizeof(short);
						request->currentBatchSize +=  sizeof(short);
						if (rowData->columnValues[i].len != 0xffff)
						{
							CheckForInvalidLength(rowData, request, i);

							if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
								enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

							CheckMessageHasEnoughBytesToRead(&message, rowData->columnValues[i].len);
							memcpy(rowData->columnValues[i].data, &message->data[offset], rowData->columnValues[i].len);
							offset += rowData->columnValues[i].len;
							request->currentBatchSize += rowData->columnValues[i].len;
						}
						else /* null */
						{
							rowData->isNull[i] = 'n';
							i++;
							continue;
						}
					}
					else
					{
						StringInfo plpStr;
						ParameterToken temp = palloc0(sizeof(ParameterTokenData));

						retStatus = ReadBcpPlp(temp, &message, request);

						CheckPLPStatusNotOK(request, retStatus, i);
						if (temp->isNull) /* null */
						{
							rowData->isNull[i] = 'n';
							i++;
							temp->isNull = false;
							continue;
						}

						plpStr = TdsGetPlpStringInfoBufferFromToken(message->data, temp);
						rowData->columnValues[i] = *plpStr;
						pfree(plpStr);
						pfree(temp);
					}
				}
				break;
				case TDS_TYPE_TEXT:
				case TDS_TYPE_NTEXT:
				case TDS_TYPE_IMAGE:
				{
					CheckMessageHasEnoughBytesToRead(&message, 1);
					/* Ignore the Data Text Ptr since its currently of no use. */
					uint8 dataTextPtrLen = message->data[offset++];
					request->currentBatchSize++;
					if (dataTextPtrLen == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}

					CheckMessageHasEnoughBytesToRead(&message, dataTextPtrLen + 8 + sizeof(uint32_t));

					offset += dataTextPtrLen;
					request->currentBatchSize += dataTextPtrLen;
					offset += 8; /* TODO: Ignored the Data Text TimeStamp for now. */
					request->currentBatchSize += 8;

					memcpy(&rowData->columnValues[i].len, &message->data[offset], sizeof(uint32_t));
					offset +=  sizeof(uint32_t);
					request->currentBatchSize += sizeof(uint32_t);
					if (rowData->columnValues[i].len == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}

					CheckForInvalidLength(rowData, request, i);

					if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
						enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

					CheckMessageHasEnoughBytesToRead(&message, rowData->columnValues[i].len);

					memcpy(rowData->columnValues[i].data, &message->data[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
					request->currentBatchSize += rowData->columnValues[i].len;
				}
				break;
				case TDS_TYPE_XML:
				{
					StringInfo plpStr;
					ParameterToken temp = palloc0(sizeof(ParameterTokenData));
					retStatus = ReadBcpPlp(temp, &message, request);
					CheckPLPStatusNotOK(request, retStatus, i);
					if (temp->isNull) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						temp->isNull = false;
						continue;
					}

					plpStr = TdsGetPlpStringInfoBufferFromToken(message->data, temp);
					rowData->columnValues[i] = *plpStr;
					pfree(plpStr);
					pfree(temp);
				}
				break;
				case TDS_TYPE_SQLVARIANT:
				{
					CheckMessageHasEnoughBytesToRead(&message, sizeof(uint32_t));

					memcpy(&rowData->columnValues[i].len, &message->data[offset], sizeof(uint32_t));
					offset += sizeof(uint32_t);
					request->currentBatchSize += sizeof(uint32_t);

					if (rowData->columnValues[i].len == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}

					CheckForInvalidLength(rowData, request, i);

					if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
						enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

					CheckMessageHasEnoughBytesToRead(&message, rowData->columnValues[i].len);

					memcpy(rowData->columnValues[i].data, &message->data[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
					request->currentBatchSize += rowData->columnValues[i].len;
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
	int retValue = 0;
	StringInfo temp = makeStringInfo();
	TDSRequestBulkLoad req = (TDSRequestBulkLoad) request;
	BulkLoadColMetaData *colMetaData = req->colMetaData;
	StringInfo message = req->firstMessage;

	TdsErrorContext->err_text = "Processing Bulk Load Request";
	pgstat_report_activity(STATE_RUNNING, "Processing Bulk Load Request");

	while (1)
	{
		int nargs = 0;
		Datum *values = NULL;
		char *nulls = NULL;
		Oid *argtypes = NULL;
		bool *defaults = NULL;
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
		 * If the row-count is 0 then this no rows are left to be inserted.
		 * We should begin with cleanup.
		 */
		if (req->rowCount == 0)
		{
			/* Using Same callback function to fo the clean-up. */
			pltsql_plugin_handler_ptr->bulk_load_callback(0, 0, NULL, NULL, NULL, NULL);
			break;
		}

		/*
		 * defaults array will always contain nargs length of data, where as
		 * values and nulls array can be less than nargs length. The length of
		 * values and nulls array will be the number of bind params in
		 * bulk_load_callback function.
		 */
		nargs = req->colCount * req->rowCount;
		values = palloc0(nargs * sizeof(Datum));
		nulls = palloc0(nargs * sizeof(char));
		argtypes= palloc0(nargs * sizeof(Oid));
		defaults = palloc0(nargs * sizeof(bool));
		nargs = 0;

		foreach (lc, req->rowData) /* build an array of Value Datums */
		{
			BulkLoadRowData *row = (BulkLoadRowData *) lfirst(lc);
			TdsIoFunctionInfo tempFuncInfo;
			int currentColumn = 0;

			while(currentColumn != req->colCount)
			{
				temp = &(row->columnValues[currentColumn]);
				tempFuncInfo = TdsLookupTypeFunctionsByTdsId(colMetaData[currentColumn].columnTdsType, colMetaData[currentColumn].maxLen);
				GetPgOid(argtypes[count], tempFuncInfo);
				if (row->isNull[currentColumn] == 'n') /* null */
					if (pltsql_plugin_handler_ptr->get_insert_bulk_keep_nulls())
						nulls[count++] = row->isNull[currentColumn];
					else
						defaults[nargs] = true;
				else
				{
					switch(colMetaData[currentColumn].columnTdsType)
					{
						case TDS_TYPE_CHAR:
						case TDS_TYPE_VARCHAR:
						case TDS_TYPE_TEXT:
							values[count] = TdsTypeVarcharToDatum(temp, argtypes[count], colMetaData[currentColumn].collation);
						break;
						case TDS_TYPE_NCHAR:
						case TDS_TYPE_NVARCHAR:
						case TDS_TYPE_NTEXT:
							values[count] = TdsTypeNCharToDatum(temp);
						break;
						case TDS_TYPE_INTEGER:
						case TDS_TYPE_BIT:
							values[count] = TdsTypeIntegerToDatum(temp, colMetaData[currentColumn].maxLen);
						break;
						case TDS_TYPE_FLOAT:
							values[count] = TdsTypeFloatToDatum(temp, colMetaData[currentColumn].maxLen);
						break;
						case TDS_TYPE_NUMERICN:
						case TDS_TYPE_DECIMALN:
							values[count] = TdsTypeNumericToDatum(temp, colMetaData[currentColumn].scale);
						break;
						case TDS_TYPE_VARBINARY:
						case TDS_TYPE_BINARY:
						case TDS_TYPE_IMAGE:
							values[count] = TdsTypeVarbinaryToDatum(temp);
							argtypes[count] = tempFuncInfo->ttmtypeid;
						break;
						case TDS_TYPE_DATE:
							values[count] = TdsTypeDateToDatum(temp);
						break;
						case TDS_TYPE_TIME:
							values[count] = TdsTypeTimeToDatum(temp, colMetaData[currentColumn].scale, temp->len);
						break;
						case TDS_TYPE_DATETIME2:
							values[count] = TdsTypeDatetime2ToDatum(temp, colMetaData[currentColumn].scale, temp->len);
						break;
						case TDS_TYPE_DATETIMEN:
							if (colMetaData[currentColumn].maxLen == TDS_MAXLEN_SMALLDATETIME)
								values[count] = TdsTypeSmallDatetimeToDatum(temp);
							else
								values[count] = TdsTypeDatetimeToDatum(temp);
						break;
						case TDS_TYPE_DATETIMEOFFSET:
							values[count] = TdsTypeDatetimeoffsetToDatum(temp, colMetaData[currentColumn].scale, temp->len);
						break;
						case TDS_TYPE_MONEYN:
							if (colMetaData[currentColumn].maxLen == TDS_MAXLEN_SMALLMONEY)
								values[count] = TdsTypeSmallMoneyToDatum(temp);
							else
								values[count] = TdsTypeMoneyToDatum(temp);
						break;
						case TDS_TYPE_XML:
							values[count] = TdsTypeXMLToDatum(temp);
						break;
						case TDS_TYPE_UNIQUEIDENTIFIER:
							values[count] = TdsTypeUIDToDatum(temp);
						break;
						case TDS_TYPE_SQLVARIANT:
							values[count] = TdsTypeSqlVariantToDatum(temp);
						break;
					}
					count++;
				}
				nargs++;
				currentColumn++;
			}
		}

		if (req->rowData) /* If any row exists then do an insert. */
		{
			PG_TRY();
			{
				retValue += pltsql_plugin_handler_ptr->bulk_load_callback(req->colCount,
											req->rowCount, argtypes,
											values, nulls, defaults);
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
			if (argtypes)
				pfree(argtypes);
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