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

static void SetBulkLoadRowData(TDSRequestBulkLoad request, const StringInfo message, uint64_t offset);
void ProcessBCPRequest(TDSRequest request);

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
	uint64_t 				offset = 0;

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
				colmetadata[currentColumn].maxLen = message->data[offset++];
			break;
			case TDS_TYPE_DECIMALN:
			case TDS_TYPE_NUMERICN:
				colmetadata[currentColumn].maxLen    = message->data[offset++];
				colmetadata[currentColumn].precision = message->data[offset++];
				colmetadata[currentColumn].scale 	 = message->data[offset++];
			break;
			case TDS_TYPE_CHAR:
			case TDS_TYPE_VARCHAR:
			case TDS_TYPE_NCHAR:
			case TDS_TYPE_NVARCHAR:
			{
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
				memcpy(&colmetadata[currentColumn].maxLen, &message->data[offset], sizeof(uint32_t));
				offset += sizeof(uint32_t);

				/* Read collation(LICD) and sort-id for TEXT and NTEXT. */
				if (colmetadata[currentColumn].columnTdsType == TDS_TYPE_TEXT ||
					colmetadata[currentColumn].columnTdsType == TDS_TYPE_NTEXT)
				{
					memcpy(&colmetadata[currentColumn].collation, &message->data[offset], sizeof(uint32_t));
					offset += sizeof(uint32_t);
					colmetadata[currentColumn].sortId = message->data[offset++];
				}

				memcpy(&tableLen, &message->data[offset], sizeof(uint16_t));
				offset += sizeof(uint16_t);

				/* Skip table name for now. */
				offset += tableLen * 2;
			}
			break;
			case TDS_TYPE_XML:
			{
				colmetadata[currentColumn].maxLen = message->data[offset++];
			}
			break;
			case TDS_TYPE_DATETIME2:
			{
				colmetadata[currentColumn].scale = message->data[offset++];
				colmetadata[currentColumn].maxLen = 8;
			}
			break;
			case TDS_TYPE_TIME:
			{
				colmetadata[currentColumn].scale = message->data[offset++];
				colmetadata[currentColumn].maxLen = 5;
			}
			break;
			case TDS_TYPE_DATETIMEOFFSET:
			{
				colmetadata[currentColumn].scale = message->data[offset++];
				colmetadata[currentColumn].maxLen = 10;
			}
			break;
			case TDS_TYPE_BINARY:
			case TDS_TYPE_VARBINARY:
			{
				uint16 plp;
				memcpy(&plp, &message->data[offset], sizeof(uint16));
				offset += sizeof(uint16);
				colmetadata[currentColumn].maxLen = plp;
			}
			break;
			case TDS_TYPE_DATE:
				colmetadata[currentColumn].maxLen = 3;
			break;
			case TDS_TYPE_SQLVARIANT:
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
		memcpy(&colmetadata[currentColumn].colNameLen, &message->data[offset++], sizeof(uint8_t));
		colmetadata[currentColumn].colName = (char *)palloc0(colmetadata[currentColumn].colNameLen * sizeof(char) * 2 + 1);
		memcpy(colmetadata[currentColumn].colName, &message->data[offset],
					colmetadata[currentColumn].colNameLen * 2);
		colmetadata[currentColumn].colName[colmetadata[currentColumn].colNameLen * 2] = '\0';

		offset += colmetadata[currentColumn].colNameLen * 2;
	}

	SetBulkLoadRowData(request, message, offset);

	return (TDSRequest)request;
}

/*
 * SetBulkLoadRowData - Builds the row data structure associated
 * with Bulk Load.
 * TODO: Reuse for TVP.
 */
static void
SetBulkLoadRowData(TDSRequestBulkLoad request, const StringInfo message, uint64_t offset)
{
	BulkLoadColMetaData *colmetadata = request->colMetaData;
	char *messageData = message->data;
	int retStatus = 0;
	request->rowCount = 0;
	request->rowData = NIL;
	while((uint8_t)messageData[offset] == TDS_TOKEN_ROW) /* Loop over each row. */
	{
		int i = 0; /* Current Column Number. */
		BulkLoadRowData *rowData = palloc0(sizeof(BulkLoadRowData));
		request->rowCount++;
		retStatus += 1;
		rowData->columnValues = palloc0(request->colCount * sizeof(StringInfoData));
		rowData->isNull 	  = palloc0(request->colCount);
		offset++;
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
						rowData->columnValues[i].len = messageData[offset++];
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

					memcpy(rowData->columnValues[i].data, &messageData[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
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
					rowData->columnValues[i].len = messageData[offset++];
					if (rowData->columnValues[i].len == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}

					CheckForInvalidLength(rowData, request, i);

					if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
						enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

					memcpy(rowData->columnValues[i].data, &messageData[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
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
						memcpy(&rowData->columnValues[i].len, &messageData[offset], sizeof(short));
						offset +=  sizeof(short);
						if (rowData->columnValues[i].len != 0xffff)
						{
							CheckForInvalidLength(rowData, request, i);

							if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
								enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

							memcpy(rowData->columnValues[i].data, &messageData[offset], rowData->columnValues[i].len);
							offset += rowData->columnValues[i].len;
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
						retStatus = ReadPlp(temp, message, &offset);
						CheckPLPStatusNotOK(request, retStatus, i);
						if (temp->isNull) /* null */
						{
							rowData->isNull[i] = 'n';
							i++;
							temp->isNull = false;
							continue;
						}

						plpStr = TdsGetPlpStringInfoBufferFromToken(messageData, temp);
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
					/* Ignore the Data Text Ptr since its currently of no use. */
					uint8 dataTextPtrLen = messageData[offset++];
					if (dataTextPtrLen == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}
					offset += dataTextPtrLen;
					offset += 8; /* TODO: Ignored the Data Text TimeStamp for now. */

					memcpy(&rowData->columnValues[i].len, &messageData[offset], sizeof(uint32_t));
					offset +=  sizeof(uint32_t);
					if (rowData->columnValues[i].len == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}

					CheckForInvalidLength(rowData, request, i);

					if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
						enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

					memcpy(rowData->columnValues[i].data, &messageData[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
				}
				break;
				case TDS_TYPE_XML:
				{
					StringInfo plpStr;
					ParameterToken temp = palloc0(sizeof(ParameterTokenData));
					retStatus = ReadPlp(temp, message, &offset);
					CheckPLPStatusNotOK(request, retStatus, i);
					if (temp->isNull) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						temp->isNull = false;
						continue;
					}

					plpStr = TdsGetPlpStringInfoBufferFromToken(messageData, temp);
					rowData->columnValues[i] = *plpStr;
					pfree(plpStr);
					pfree(temp);
				}
				break;
				case TDS_TYPE_SQLVARIANT:
				{
					memcpy(&rowData->columnValues[i].len, &messageData[offset], sizeof(uint32_t));
					offset += sizeof(uint32_t);

					if (rowData->columnValues[i].len == 0) /* null */
					{
						rowData->isNull[i] = 'n';
						i++;
						continue;
					}

					CheckForInvalidLength(rowData, request, i);

					if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
						enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

					memcpy(rowData->columnValues[i].data, &messageData[offset], rowData->columnValues[i].len);
					offset += rowData->columnValues[i].len;
				}
				break;
			}
			i++;
		}
		request->rowData = lappend(request->rowData, rowData);
	}
	if ((uint8_t)messageData[offset] != TDS_TOKEN_DONE)
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
					errmsg("The incoming tabular data stream (TDS) Bulk Load Request (BulkLoadBCP) protocol stream is incorrect. "
						"Row %d, column %d, unexpected token encountered processing the request. %d",
						request->rowCount, request->colCount, (uint8_t)messageData[offset])));
	offset++;
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

	int nargs = req->colCount * req->rowCount;
	Datum *values = palloc0(nargs * sizeof(Datum));
	char *nulls = palloc0(nargs * sizeof(char));
	Oid *argtypes= palloc0(nargs * sizeof(Oid));

	int count = 0;
	ListCell 	*lc;

	TdsErrorContext->err_text = "Processing Bulk Load Request";
	pgstat_report_activity(STATE_RUNNING, "Processing Bulk Load Request");

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
				nulls[count] = row->isNull[currentColumn];
			else
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
			currentColumn++;
		}
	}

	if (req->rowData) /* If any row exists then do an insert. */
	{
		PG_TRY();
		{
			retValue = pltsql_plugin_handler_ptr->bulk_load_callback(req->colCount,
										req->rowCount, argtypes,
										values, nulls);
		}
		PG_CATCH();
		{
			if (TDS_DEBUG_ENABLED(TDS_DEBUG2))
				ereport(LOG,
						(errmsg("Bulk Load Request. Number of Rows: %d and Number of columns: %d.",
						req->rowCount, req->colCount),
						errhidestmt(true)));

			PG_RE_THROW();
		}
		PG_END_TRY();

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

	/* Free the List of Rows. */
	list_free_deep(req->rowData);
	if (values)
		pfree(values);
	if (nulls)
		pfree(nulls);
	if (argtypes)
		pfree(argtypes);
}
