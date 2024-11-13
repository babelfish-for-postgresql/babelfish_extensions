/*-------------------------------------------------------------------------
 *
 * tds_request.h
 *	  This file contains definitions for structures and externs used
 *	  for processing a TDS request.
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/tds/tds_request.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TDS_REQUEST_H
#define TDS_REQUEST_H

#define BBF_NAMEDATALEND (NAMEDATALEN + 2)
#define BBF_AUTHID_USER_EXT_TABLE_NAME "babelfish_authid_user_ext"
#define Anum_bbf_authid_user_ext_rolname				1
#define Anum_bbf_authid_user_ext_database_name			12
#define Anum_bbf_authid_user_ext_default_schema_name	13

#include "postgres.h"
#include "port.h"

#include "lib/stringinfo.h"
#include "miscadmin.h"

#include "src/include/tds_int.h"
#include "src/include/tds_typeio.h"
#include "src/collation.h"
#include "catalog/pg_proc.h"
#include "utils/syscache.h"
#include "utils/catcache.h"
#include "funcapi.h"
#include "utils/acl.h"
#include "utils/fmgroids.h"
#include "access/table.h"
#include "access/genam.h"
#include "utils/lsyscache.h"
#include "access/xact.h"
#include "utils/varlena.h"
#include "catalog/pg_type.h"
#include "parser/scansup.h"
#include "utils/builtins.h"
#include "access/heapam.h"


/* Different TDS request types returned by GetTDSRequest() */
typedef enum TDSRequestType
{
	TDS_REQUEST_SQL_BATCH = 1,	/* a simple SQL batch */
	TDS_REQUEST_SP_NUMBER = 2,	/* numbered SP like sp_execute */
	TDS_REQUEST_TXN_MGMT = 3,	/* transaction management request */
	TDS_REQUEST_BULK_LOAD = 4,	/* bulk load request */
	TDS_REQUEST_ATTN			/* attention request */
} TDSRequestType;

/* Simple SQL batch */
typedef struct TDSRequestSQLBatchData
{
	TDSRequestType reqType;
	StringInfoData query;
} TDSRequestSQLBatchData;
typedef TDSRequestSQLBatchData *TDSRequestSQLBatch;

/*
 * TODO: Use below values as an ENUM, rather than MACRO
 * Enum will flag out compile time error if any condition is missed
 */
#define SP_CURSOR			1
#define SP_CURSOROPEN		2
#define SP_CURSORPREPARE	3
#define SP_CURSOREXEC		4
#define SP_CURSORPREPEXEC	5
#define SP_CURSORUNPREPARE	6
#define SP_CURSORFETCH		7
#define SP_CURSOROPTION		8
#define SP_CURSORCLOSE		9
#define SP_EXECUTESQL		10
#define SP_PREPARE		11
#define SP_EXECUTE		12
#define SP_PREPEXEC		13
#define SP_PREPEXECRPC		14
#define SP_UNPREPARE		15
#define	SP_CUSTOMTYPE		16

/* Check if retStatus Not OK */
#define CheckPLPStatusNotOKForTVP(temp, retStatus) \
do \
{ \
	if (retStatus != STATUS_OK) \
	{ \
		ereport(ERROR, \
				(errcode(ERRCODE_PROTOCOL_VIOLATION), \
				 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. " \
					 "Table-valued parameter %d (\"%s\"), row %d, column %d: The chunking format is incorrect for a " \
					 "large object parameter of data type 0x%02X.", \
					 temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->tvpInfo->rowCount, \
					 i + 1, temp->tvpInfo->colMetaData[i].columnTdsType))); \
	} \
} while(0)

int			ReadPlp(ParameterToken temp, StringInfo message, uint64_t *mainOffset);

/* Numbered Stored Procedure like sp_prepexec, sp_execute */
typedef struct TDSRequestSPData
{
	TDSRequestType reqType;
	uint16_t	spType;
	uint16_t	spFlags;

	StringInfoData name;

	uint32		handle;			/* handle corresponding to this SP request */
	uint32		cursorHandle;	/* cursor handle corresponding to this
								 * SP_CURSOR* request */

	/*
	 * cursor prepared handle corresponding to
	 * SP_CURSOR[prepare/prepexec/exec] request
	 */
	uint32_t	cursorPreparedHandle;

	/*
	 * parameter points to the head of the ParameterToken linked List. Each
	 * ParameterToken contains all the data pertaining to the parameter.
	 */
	ParameterToken parameter;

	/*
	 * Pointer to request data, while parsing we don't copy the actual data
	 * but just store the dataOffset and len fields in the Parametertoken
	 * structure
	 */
	char	   *messageData;
	uint64_t	batchSeparatorOffset;
	int			messageLen;

	/*
	 * Below three fields are just a place holder for keeping the addresses of
	 * Parameter query & data token separate, so that during processing this
	 * can be used directly
	 */
	ParameterToken queryParameter;
	ParameterToken dataParameter;
	ParameterToken handleParameter;

	StringInfo	metaDataParameterValue;

	/*
	 * cursor parameters - all parameters except cursorHandleParameter have
	 * different meanings w.r.t the type of the cursor request (check
	 * GetTDSRequest() for their respective meaning).
	 */
	ParameterToken cursorPreparedHandleParameter;
	ParameterToken cursorHandleParameter;
	ParameterToken cursorExtraArg1;
	ParameterToken cursorExtraArg2;
	ParameterToken cursorExtraArg3;

	/* number of total dataParameters */
	uint16		nTotalParams;

	/* number of OUT dataParameters */
	uint16		nOutParams;

	/*
	 * cursor scorll option and concurrency control options (only valid for
	 * sp_cursoropen packet)
	 */
	int			scrollopt;
	int			ccopt;

	/*
	 * TODO: Use as local variable rather than part of the structure
	 */
	Datum	   *boundParamsData;
	char	   *boundParamsNullList;
	Oid		   *boundParamsOidList;

	uint16		nTotalBindParams;

	/* True, if this is a stored procedure */
	bool		isStoredProcedure;

	/*
	 * we store the OUT dataParameter pointers in the following array so that
	 * they can be accessed directly given their index.
	 */
	ParameterToken *idxOutParams;

	/*
	 * In case when parameter names aren't specified by the application, then
	 * use paramIndex for maintaining the paramIndex which is used by Engine
	 */
	int			paramIndex;
} TDSRequestSPData;
typedef TDSRequestSPData *TDSRequestSP;

typedef struct TDSRequestBulkLoadData
{
	TDSRequestType reqType;
	int			colCount;
	int			rowCount;

	/*
	 * Holds the First Message data to be transfered from TDS Fetch to TDS
	 * Process phase.
	 */
	StringInfo	firstMessage;

	int			currentBatchSize;	/* Current Batch Size in byes */

	BulkLoadColMetaData *colMetaData;	/* Array of each column's metadata. */
	List	   *rowData;		/* List holding each row. */
} TDSRequestBulkLoadData;
typedef TDSRequestBulkLoadData *TDSRequestBulkLoad;

/* Default handle value for a RPC request which doesn't use any handle */
/*
 * TODO: Check and correct the values for SP_HANDLE_INVALID
 * and SP_CURSOR_HANDLE_INVALID
 */
#define SP_HANDLE_INVALID	0
#define SP_CURSOR_PREPARED_HANDLE_START 1073741824
#define SP_CURSOR_PREPARED_HANDLE_INVALID 0xFFFFFFFF
#define SP_CURSOR_HANDLE_INVALID	180150000

/* During parse, we should always send the base type OID if it exists. */
#define SetParamMetadataCommonInfo(paramMeta, finfo) \
do { \
	(paramMeta)->pgTypeOid = (finfo->ttmbasetypeid != InvalidOid) ? \
				finfo->ttmbasetypeid : finfo->ttmtypeid; \
	(paramMeta)->sendFunc = finfo->sendFuncPtr; \
} while(0);

#define GetPgOid(pgTypeOid, finfo) \
do { \
	pgTypeOid = (finfo->ttmbasetypeid != InvalidOid) ? \
				finfo->ttmbasetypeid : finfo->ttmtypeid; \
} while(0);

/* Macro used to check if Next RPC Packet Exists. */
#define RPCBatchExists(sp) (sp.batchSeparatorOffset < sp.messageLen)

/* Transaction management request */
typedef struct TDSRequestTxnMgmtData
{
	TDSRequestType reqType;
	uint16_t	txnReqType;
	StringInfoData txnName;
	uint8_t		isolationLevel;
	StringInfoData query;

	/* Commit/rollback requests can have optional begin transaction */
	struct TDSRequestTxnMgmtData *nextTxn;

} TDSRequestTxnMgmtData;
typedef TDSRequestTxnMgmtData *TDSRequestTxnMgmt;

typedef union TDSRequestData
{
	TDSRequestType reqType;
	TDSRequestSQLBatchData sqlBatch;
	TDSRequestSPData sp;
	TDSRequestTxnMgmtData txnMgmt;
} TDSRequestData;
typedef TDSRequestData *TDSRequest;

/* COLMETADATA flags */
#define TDS_COLMETA_NULLABLE	0x01
#define TDS_COLMETA_CASESEN		0x02
#define TDS_COLMETA_UPD_RO		0x00
#define TDS_COLMETA_UPD_RW		0x04
#define TDS_COLMETA_UPD_UNKNOWN	0x08
#define TDS_COLMETA_IDENTITY	0x10
#define TDS_COLMETA_COMPUTED	0x20

#define TDS_COL_METADATA_DEFAULT_FLAGS  TDS_COLMETA_NULLABLE | \
					TDS_COLMETA_UPD_UNKNOWN
#define TDS_COL_METADATA_NOT_NULL_FLAGS TDS_COLMETA_UPD_UNKNOWN
#define TDS_COL_METADATA_IDENTITY_FLAGS TDS_COLMETA_IDENTITY
#define TDS_COL_METADATA_COMPUTED_FLAGS TDS_COLMETA_NULLABLE | \
					TDS_COLMETA_COMPUTED

/* Macro for TVP tokens. */
#define TVP_ROW_TOKEN				0x01
#define TVP_NULL_TOKEN			0xFFFF
#define TVP_ORDER_UNIQUE_TOKEN		0x10
#define TVP_COLUMN_ORDERING_TOKEN		0x11
#define TVP_END_TOKEN				0x00

static Oid
get_authid_user_ext_oid()
{
	Oid			bbf_authid_user_ext_oid = InvalidOid;
	if (!OidIsValid(bbf_authid_user_ext_oid))
		bbf_authid_user_ext_oid = get_relname_relid(BBF_AUTHID_USER_EXT_TABLE_NAME,
													get_namespace_oid("sys", false));

	return bbf_authid_user_ext_oid;
}

static char *
get_authid_user_ext_schema_name1(const char *db_name, const char *user)
{
	Relation	bbf_authid_user_ext_rel;
	HeapTuple	tuple_user_ext;
	ScanKeyData key[2];
	TableScanDesc scan;
	char	   *schema_name = NULL;
	NameData   *user_name;

	if (!db_name || !user)
		return NULL;

	bbf_authid_user_ext_rel = table_open(get_authid_user_ext_oid(),
										 RowExclusiveLock);

	user_name = (NameData *) palloc0(NAMEDATALEN);
	snprintf(user_name->data, NAMEDATALEN, "%s", user);
	ScanKeyInit(&key[0],
				Anum_bbf_authid_user_ext_rolname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(user_name));
	ScanKeyInit(&key[1],
				Anum_bbf_authid_user_ext_database_name,
				BTEqualStrategyNumber, F_TEXTEQ,
				CStringGetTextDatum(db_name));

	scan = table_beginscan_catalog(bbf_authid_user_ext_rel, 2, key);

	tuple_user_ext = heap_getnext(scan, ForwardScanDirection);
	if (HeapTupleIsValid(tuple_user_ext))
	{
		Datum		datum;
		bool		is_null;

		datum = heap_getattr(tuple_user_ext,
							 Anum_bbf_authid_user_ext_default_schema_name,
							 bbf_authid_user_ext_rel->rd_att,
							 &is_null);
		schema_name = pstrdup(TextDatumGetCString(datum));
	}

	table_endscan(scan);
	table_close(bbf_authid_user_ext_rel, RowExclusiveLock);

	return schema_name;
}


static int
babelfish_get_delimiter_pos(char *str)
{
	char	   *ptr;

	if (strlen(str) <= 2 && (strchr(str, '"') || strchr(str, '[') || strchr(str, ']')))
		return -1;
	else if (str[0] == '[')
	{
		ptr = strstr(str, "].");
		if (ptr == NULL)
			return -1;
		else
			return (int) (ptr - str) + 1;
	}
	else if (str[0] == '"')
	{
		ptr = strstr(&str[1], "\".");
		if (ptr == NULL)
			return -1;
		else
			return (int) (ptr - str) + 1;
	}
	else
	{
		ptr = strstr(str, ".");
		if (ptr == NULL)
			return -1;
		else
			return (int) (ptr - str);
	}

	return -1;
}

/*
 * Extract string from input of given length and remove delimited identifiers.
 */
static char *
remove_delimited_identifiers(char *str, int len)
{

	if (len >= 2 && ((str[0] == '[' && str[len - 1] == ']') || (str[0] == '"' && str[len - 1] == '"')))
	{
		if (len > 2)
			return pnstrdup(&str[1], len - 2);
		else
			return pstrdup("");
	}
	else
		return pnstrdup(str, len);
}

/*
 * Split multiple-part object-name into array of pointers, it also remove the delimited identifiers.
 */
static char	  **
split_object_name1(char *name)
{
	char	  **res = palloc(4 * sizeof(char *));
	char	   *temp[4];
	char	   *str;
	int			cur_pos,
				next_pos;
	int			count = 0;

	/* extract and remove the delimited identifiers from input into temp array */
	cur_pos = 0;
	next_pos = babelfish_get_delimiter_pos(name);
	while (next_pos != -1 && count < 3)
	{
		str = remove_delimited_identifiers(&name[cur_pos], next_pos);
		temp[count++] = str;
		cur_pos += next_pos + 1;
		next_pos = babelfish_get_delimiter_pos(&name[cur_pos]);
	}
	str = remove_delimited_identifiers(&name[cur_pos], strlen(&name[cur_pos]));
	temp[count++] = str;

	/* fill unspecified parts with empty strings */
	for (int i = 0; i < 4; i++)
	{
		if (i < 4 - count)
			res[i] = pstrdup("");
		else
			res[i] = temp[i - (4 - count)];
	}

	return res;
}

static Oid get_proc_namespace_oid(char **proc_name, char *curr_db)
{
	char *logical_sch_name;
	char *physical_sch_name;
	char *db_name;
	char *schema_name;
	char	  **splited_object_name;
	Oid obj_schema_oid = InvalidOid;

	splited_object_name = split_object_name1(*proc_name);
	db_name = splited_object_name[1];
	schema_name = splited_object_name[2];
	*proc_name = splited_object_name[3];

	if (!strcmp(db_name, ""))
		db_name = curr_db;

	if (!strcmp(schema_name, ""))
	{
		/*
		* find the default schema for current user and get physical schema
		* name
		*/
		const char *user = pltsql_plugin_handler_ptr->pltsql_get_user_for_database(db_name);
		schema_name = get_authid_user_ext_schema_name1((const char *) db_name, user);
	}

	logical_sch_name = downcase_truncate_identifier(schema_name,strlen(schema_name), true);
	physical_sch_name = pltsql_plugin_handler_ptr->get_physical_schema_name(db_name, logical_sch_name);
	obj_schema_oid = get_namespace_oid(physical_sch_name, false);

	return obj_schema_oid;

}

static inline char** fetch_func_input_arg_names1(HeapTuple func_tuple)
{
	Datum proargnames;
	Datum		proargmodes;
	char**		arg_names;
	bool 		isnull;

	proargnames = SysCacheGetAttr(PROCNAMEARGSNSP, func_tuple,
					Anum_pg_proc_proargnames,
					&isnull);

	proargmodes = SysCacheGetAttr(PROCNAMEARGSNSP, func_tuple,
					Anum_pg_proc_proargmodes,
					&isnull);

	if (isnull)
		proargmodes = PointerGetDatum(NULL);	/* just to be sure */

	get_func_input_arg_names(proargnames,
									proargmodes,
									&arg_names);
	return arg_names;
}

static inline Oid
tds_get_proargtypes_oid(char *proname, Oid pronamespace, Oid user_id, char *targeted_arg_name)
{
    HeapTuple    tuple;
    CatCList   *catlist;
    Oid matched_type = InvalidOid;

    /* first search in pg_proc by name */

    catlist = SearchSysCacheList1(PROCNAMEARGSNSP, CStringGetDatum(proname));

    for (int i = 0; i < catlist->n_members; i++)
    {
        Form_pg_proc procform;

        tuple = &catlist->members[i]->tuple;
        procform = (Form_pg_proc) GETSTRUCT(tuple);
        /* then consider only procs in specified namespace */
        if (procform->pronamespace == pronamespace &&
            object_aclcheck(ProcedureRelationId, procform->oid, user_id, ACL_EXECUTE) == ACLCHECK_OK)
        {
            char **proargnames = fetch_func_input_arg_names1(tuple);
            Oid *proargtypes = procform->proargtypes.values;

            for (int j = 0; j < procform->pronargs; j++)
            {
                if (strcmp(proargnames[j], targeted_arg_name) == 0)
                {
                    /* Match found, set the matched type and return the index */
                    matched_type = proargtypes[j];
                    break;
                }
            }
        }
    }
    ReleaseSysCacheList(catlist);
	if (matched_type == InvalidOid)
    {
        ereport(ERROR,
                (errcode(ERRCODE_UNDEFINED_FUNCTION),
                 errmsg("No procedure found with name \"%s\" that has an argument named \"%s\"",
                        proname, targeted_arg_name)));
    }
    return matched_type;
}

static inline void
SetTvpRowData(ParameterToken temp, const StringInfo message, uint64_t *offset)
{
	TvpColMetaData *colmetadata = temp->tvpInfo->colMetaData;
	TvpRowData *rowData = NULL;
	char	   *messageData = message->data;
	int			retStatus = 0;

	temp->tvpInfo->rowCount = 0;
	while (messageData[*offset] == TVP_ROW_TOKEN)	/* Loop over each row. */
	{
		int			i = 0;		/* Current Column Number. */

		if (rowData == NULL)	/* First Row. */
		{
			rowData = palloc0(sizeof(TvpRowData));
			temp->tvpInfo->rowData = rowData;
		}
		else
		{
			TvpRowData *temp = palloc0(sizeof(TvpRowData));

			rowData->nextRow = temp;
			rowData = temp;
		}

		temp->tvpInfo->rowCount += 1;
		rowData->columnValues = palloc0(temp->tvpInfo->colCount * sizeof(StringInfoData));
		rowData->isNull = palloc0(temp->tvpInfo->colCount);
		(*offset)++;

		while (i != temp->tvpInfo->colCount)	/* Loop over each column. */
		{
			initStringInfo(&rowData->columnValues[i]);
			rowData->isNull[i] = 'f';
			switch (colmetadata[i].columnTdsType)
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
						rowData->columnValues[i].len = messageData[(*offset)++];
						if (rowData->columnValues[i].len == 0)	/* null */
						{
							rowData->isNull[i] = 'n';
							i++;
							continue;
						}
						if (rowData->columnValues[i].len > colmetadata[i].maxLen)
							ereport(ERROR,
									(errcode(ERRCODE_PROTOCOL_VIOLATION),
									 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
											"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X has an invalid data length or metadata length.",
											temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->tvpInfo->rowCount, i + 1, colmetadata[i].columnTdsType)));
						memcpy(rowData->columnValues[i].data, &messageData[*offset], rowData->columnValues[i].len);
						*offset += rowData->columnValues[i].len;
					}
					break;
				case TDS_TYPE_CLRUDT:
					{
						retStatus = ReadPlp(temp, message, offset);
						CheckPLPStatusNotOKForTVP(temp, retStatus);
						if (temp->isNull)
						{
							rowData->isNull[i] = 'n';
							i++;
							temp->isNull = false;
							continue;
						}
						rowData->columnValues[i] = *(TdsGetPlpStringInfoBufferFromToken(messageData, temp));

					}
					break;
				case TDS_TYPE_NUMERICN:
				case TDS_TYPE_DECIMALN:
					{
						if (colmetadata[i].scale > colmetadata[i].precision)
							ereport(ERROR,
									(errcode(ERRCODE_PROTOCOL_VIOLATION),
									 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
											"Table-valued parameter %d (\"%s\"): row %d, column %d: The supplied value is not a valid instance of data type Numeric/Decimal. "
											"Check the source data for invalid values. An example of an invalid value is data of numeric type with scale greater than precision.",
											temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->tvpInfo->rowCount, i + 1)));
						rowData->columnValues[i].len = messageData[(*offset)++];
						if (rowData->columnValues[i].len == 0)	/* null */
						{
							rowData->isNull[i] = 'n';
							i++;
							continue;
						}
						if (rowData->columnValues[i].len > colmetadata[i].maxLen)
							ereport(ERROR,
									(errcode(ERRCODE_PROTOCOL_VIOLATION),
									 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
											"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X has an invalid data length or metadata length.",
											temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->tvpInfo->rowCount, i + 1, colmetadata[i].columnTdsType)));

						memcpy(rowData->columnValues[i].data, &messageData[*offset], rowData->columnValues[i].len);
						*offset += rowData->columnValues[i].len;
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
							memcpy(&rowData->columnValues[i].len, &messageData[*offset], sizeof(short));
							*offset += sizeof(short);
							rowData->columnValues[i].maxlen = colmetadata[i].maxLen;
							if (rowData->columnValues[i].len != 0xffff)
							{
								char	   *value;

								if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
									ereport(ERROR,
											(errcode(ERRCODE_PROTOCOL_VIOLATION),
											 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
													"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X has an invalid data length or metadata length.",
													temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->tvpInfo->rowCount, i + 1, colmetadata[i].columnTdsType)));
								value = palloc(rowData->columnValues[i].len);
								memcpy(value, &messageData[*offset], rowData->columnValues[i].len);
								rowData->columnValues[i].data = value;
								*offset += rowData->columnValues[i].len;
								if (colmetadata[i].columnTdsType == TDS_TYPE_NVARCHAR)
								{
									StringInfo	tempStringInfo = palloc(sizeof(StringInfoData));

									initStringInfo(tempStringInfo);
									TdsUTF16toUTF8StringInfo(tempStringInfo, value, rowData->columnValues[i].len);
									rowData->columnValues[i] = *tempStringInfo;
								}
							}
							else
							{
								rowData->isNull[i] = 'n';
								i++;
								continue;
							}
						}
						else
						{
							retStatus = ReadPlp(temp, message, offset);
							CheckPLPStatusNotOKForTVP(temp, retStatus);
							if (temp->isNull)
							{
								rowData->isNull[i] = 'n';
							}
							rowData->columnValues[i] = *(TdsGetPlpStringInfoBufferFromToken(messageData, temp));
							if (colmetadata[i].columnTdsType == TDS_TYPE_NVARCHAR)
							{
								StringInfo	tempStringInfo = palloc(sizeof(StringInfoData));

								initStringInfo(tempStringInfo);
								TdsUTF16toUTF8StringInfo(tempStringInfo, rowData->columnValues[i].data, rowData->columnValues[i].len);
								rowData->columnValues[i] = *tempStringInfo;
							}
							temp->isNull = false;
						}
					}
					break;
				case TDS_TYPE_XML:
					{
						retStatus = ReadPlp(temp, message, offset);
						CheckPLPStatusNotOKForTVP(temp, retStatus);
						if (temp->isNull)
						{
							rowData->isNull[i] = 'n';
							i++;
							temp->isNull = false;
							continue;
						}
						rowData->columnValues[i] = *(TdsGetPlpStringInfoBufferFromToken(messageData, temp));
					}
					break;
				case TDS_TYPE_SQLVARIANT:
					{
						memcpy(&rowData->columnValues[i].len, &messageData[*offset], sizeof(uint32_t));
						*offset += sizeof(uint32_t);

						if (rowData->columnValues[i].len == 0)
						{
							rowData->isNull[i] = 'n';
							i++;
							continue;
						}
						if (rowData->columnValues[i].len > colmetadata[i].maxLen)
							ereport(ERROR,
									(errcode(ERRCODE_PROTOCOL_VIOLATION),
									 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
											"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X has an invalid data length or metadata length.",
											temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->tvpInfo->rowCount, i + 1, colmetadata[i].columnTdsType)));

						/*
						 * Check if rowData->columnValues[i].data has enough
						 * length allocated.
						 */
						if (rowData->columnValues[i].len > rowData->columnValues[i].maxlen)
							enlargeStringInfo(&rowData->columnValues[i], rowData->columnValues[i].len);

						memcpy(rowData->columnValues[i].data, &messageData[*offset], rowData->columnValues[i].len);
						*offset += rowData->columnValues[i].len;
					}
					break;
			}
			i++;
		}
	}
	if (messageData[*offset] != TVP_END_TOKEN)
		ereport(ERROR,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
						"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X (user-defined table type) "
						"unexpected token encountered processing a table-valued parameter.",
						temp->paramOrdinal + 1, temp->paramMeta.colName.data, temp->tvpInfo->rowCount, temp->tvpInfo->colCount, temp->type)));
	(*offset)++;
}

static inline void
SetColMetadataForTvp(ParameterToken temp, const StringInfo message, uint64_t *offset, char *proc_name)
{
	uint8_t		len;
	uint16		colCount;
	uint16		isTvpNull;
	char	   *tempString;
	int			i = 0;
	char	   *messageData = message->data;
	StringInfo	tempStringInfo = palloc(sizeof(StringInfoData));
	uint32_t	collation;
	bool		xactStarted = IsTransactionOrTransactionBlock();
	Oid result_proargtype = InvalidOid;
	Oid user_id = InvalidOid;
	Oid obj_schema_oid = InvalidOid;
	char *target_arg_name;
	HeapTuple    tuple;
	char        *typename = NULL;
	Oid typnamespace_oid = InvalidOid;
	char *nsp_name;
	char *tvpschemaname;
	char *beginingofdb;
	char *curr_db;
	MemoryContext oldContext;

	/* Database-Name.Schema-Name.TableType-Name */
	for (; i < 3; i++)
	{
		len = messageData[(*offset)++];
		if (len != 0)
		{
			/* Database name not allowed in a TVP */
			if (i == 0)
				ereport(ERROR,
						(errcode(ERRCODE_PROTOCOL_VIOLATION),
						 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
								"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X (user-defined table type) "
								"has a non-zero length database name specified. Database name is not allowed with a table-valued parameter, "
								"only schema name and type name are valid.",
								temp->paramOrdinal + 1, temp->paramMeta.colName.data, 1, 1, temp->type)));
			initStringInfo(tempStringInfo);

			tempString = palloc0(len * 2);
			memcpy(tempString, &messageData[*offset], len * 2);
			TdsUTF16toUTF8StringInfo(tempStringInfo, tempString, len * 2);

			*offset += len * 2;
			temp->len += len;

			if (i == 1)
				temp->tvpInfo->tvpTypeSchemaName = tempStringInfo->data;
			else
			{
				temp->tvpInfo->tvpTypeName = tempStringInfo->data;
				temp->tvpInfo->tableName = tempStringInfo->data;
			}
		}
		else if (i == 2)
		{
			if (!xactStarted)
				StartTransactionCommand(); 
			user_id = GetSessionUserId();
			target_arg_name = temp->paramMeta.colName.data;
			curr_db = pltsql_plugin_handler_ptr->get_cur_db_name();

			obj_schema_oid = get_proc_namespace_oid(&proc_name,curr_db);

			/* Fetch proargtype value of our targeted variable*/ 
			result_proargtype = tds_get_proargtypes_oid(proc_name, obj_schema_oid, user_id, target_arg_name);

			/* --------- pg_type -------- */
			/* search in pg_type by object_id */
			tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(result_proargtype));
			/* check if user have right permission on object */
			if (HeapTupleIsValid(tuple) && object_aclcheck(TypeRelationId, result_proargtype, user_id, ACL_USAGE) == ACLCHECK_OK)
			{
				Form_pg_type pg_type = (Form_pg_type) GETSTRUCT(tuple);
				typename = NameStr(pg_type->typname);
				typnamespace_oid = pg_type->typnamespace;
				nsp_name = get_namespace_name(typnamespace_oid);

				/* Remove db_ from begining of nsp_name to get the tvpTypeSchemaName*/
				beginingofdb = palloc0(BBF_NAMEDATALEND);
				snprintf(beginingofdb, BBF_NAMEDATALEND , "%s_", curr_db); 

				/* Check if nsp_name starts with beginingofdb */ 
				if (strncmp(nsp_name, beginingofdb, strlen(beginingofdb)) == 0) {
					/* If it starts with "beginingofdb", remove the prefix and return the rest of the string */ 
					tvpschemaname = nsp_name + strlen(beginingofdb);
					oldContext = MemoryContextSwitchTo(TopMemoryContext);
					temp->len += strlen(tvpschemaname);
					temp->tvpInfo->tvpTypeSchemaName = pstrdup(tvpschemaname);
					MemoryContextSwitchTo(oldContext);
				}
				ReleaseSysCache(tuple);
			}

            temp->len += strlen(typename);
            temp->tvpInfo->tvpTypeName = typename;
			temp->tvpInfo->tableName = typename;

			if(!xactStarted)
                CommitTransactionCommand();
		}
	}

	i = 0;

	memcpy(&isTvpNull, &messageData[*offset], sizeof(uint16));
	if (isTvpNull != TVP_NULL_TOKEN)
	{
		/*
		 * TypeColumnMetaData = UserType Flags TYPE_INFO ColName ;
		 */
		TvpColMetaData *colmetadata;

		memcpy(&colCount, &messageData[*offset], sizeof(uint16));
		colmetadata = palloc0(colCount * sizeof(TvpColMetaData));
		temp->tvpInfo->colCount = colCount;
		*offset += sizeof(uint16);

		temp->isNull = false;

		while (i != colCount)
		{
			if (((*offset) + sizeof(uint32_t) > message->len))
				ereport(ERROR,
						(errcode(ERRCODE_PROTOCOL_VIOLATION),
						 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
								"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X "
								"(user-defined table type) has an invalid column count specified.",
								temp->paramOrdinal + 1, temp->paramMeta.colName.data, 1, i + 1, temp->type)));

			/* UserType */
			memcpy(&colmetadata[i].userType, &messageData[*offset], sizeof(uint32_t));
			*offset += sizeof(uint32_t);
			/* Flags */
			memcpy(&colmetadata[i].flags, &messageData[*offset], sizeof(uint32));
			*offset += sizeof(uint16);

			/* TYPE_INFO */
			colmetadata[i].columnTdsType = messageData[(*offset)++];
			switch (colmetadata[i].columnTdsType)
			{
				case TDS_TYPE_INTEGER:
				case TDS_TYPE_BIT:
				case TDS_TYPE_FLOAT:
				case TDS_TYPE_MONEYN:
				case TDS_TYPE_DATETIMEN:
				case TDS_TYPE_UNIQUEIDENTIFIER:
					colmetadata[i].maxLen = messageData[(*offset)++];
					break;
				case TDS_TYPE_DECIMALN:
				case TDS_TYPE_NUMERICN:
					colmetadata[i].maxLen = messageData[(*offset)++];
					colmetadata[i].precision = messageData[(*offset)++];
					colmetadata[i].scale = messageData[(*offset)++];
					break;
				case TDS_TYPE_CHAR:
				case TDS_TYPE_VARCHAR:
				case TDS_TYPE_NCHAR:
				case TDS_TYPE_NVARCHAR:
					{
						memcpy(&colmetadata[i].maxLen, &messageData[*offset], sizeof(uint16));
						*offset += sizeof(uint16);

						memcpy(&collation, &messageData[*offset], sizeof(uint32_t));
						*offset += sizeof(uint32_t);
						colmetadata[i].sortId = messageData[(*offset)++];
						colmetadata[i].encoding = TdsGetEncoding(collation);
					}
					break;
				case TDS_TYPE_XML:
					{
						colmetadata[i].maxLen = messageData[(*offset)++];
					}
					break;
				case TDS_TYPE_DATETIME2:
					{
						colmetadata[i].scale = messageData[(*offset)++];
						colmetadata[i].maxLen = 8;
					}
					break;
				case TDS_TYPE_TIME:
					{
						colmetadata[i].scale = messageData[(*offset)++];
						colmetadata[i].maxLen = 5;
					}
					break;
				case TDS_TYPE_BINARY:
				case TDS_TYPE_VARBINARY:
					{
						uint16		plp;

						memcpy(&plp, &messageData[*offset], sizeof(uint16));
						*offset += sizeof(uint16);
						colmetadata[i].maxLen = plp;
					}
					break;
				case TDS_TYPE_DATE:
					colmetadata[i].maxLen = 3;
					break;
				case TDS_TYPE_SQLVARIANT:
					memcpy(&colmetadata[i].maxLen, &messageData[*offset], sizeof(uint32_t));
					*offset += sizeof(uint32_t);
					break;
				case TDS_TYPE_CLRUDT:
					colmetadata[i].maxLen = messageData[(*offset)++];
					break;
				default:
					ereport(ERROR,
							(errcode(ERRCODE_PROTOCOL_VIOLATION),
							 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
									"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X is unknown.",
									temp->paramOrdinal + 1, temp->paramMeta.colName.data, 1, i + 1, colmetadata[i].columnTdsType)));
			}

			if ((colmetadata[i].flags & TDS_COLMETA_COMPUTED) && ((messageData[*offset] == TVP_ORDER_UNIQUE_TOKEN) ||
																  (messageData[*offset] == TVP_COLUMN_ORDERING_TOKEN)))
				ereport(ERROR,
						(errcode(ERRCODE_PROTOCOL_VIOLATION),
						 errmsg("Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X (user-defined table type). "
								"The specified column is computed or default and has ordering or uniqueness set. Ordering and uniqueness "
								"can only be set on columns that have client supplied data.",
								temp->paramOrdinal + 1, temp->paramMeta.colName.data, 1, i + 1, colmetadata[i].columnTdsType)));
			if (messageData[*offset] != TVP_END_TOKEN)
				ereport(ERROR,
						(errcode(ERRCODE_PROTOCOL_VIOLATION),
						 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
								"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X (user-defined table type) "
								"unexpected token encountered processing a table-valued parameter.",
								temp->paramOrdinal + 1, temp->paramMeta.colName.data, 1, i + 1, colmetadata[i].columnTdsType)));
			i++;
			(*offset)++;
		}
		temp->tvpInfo->colMetaData = colmetadata;	/* Setting the column
													 * metadata in paramtoken. */

		/* TODO Optional Metadata token:- [TVP_ORDER_UNIQUE] */
		if (messageData[*offset] == TVP_ORDER_UNIQUE_TOKEN)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Order unique token for TVP is not currently supported in Babelfish")));

		/* TODO Optional Metadata token:- [TVP_COLUMN_ORDERING_TOKEN] */
		if (messageData[*offset] == TVP_COLUMN_ORDERING_TOKEN)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Column ordering token for TVP is not currently supported in Babelfish")));

		if (messageData[*offset] != TVP_END_TOKEN)
			ereport(ERROR,
					(errcode(ERRCODE_PROTOCOL_VIOLATION),
					 errmsg("The incoming tabular data stream (TDS) remote procedure call (RPC) protocol stream is incorrect. "
							"Table-valued parameter %d (\"%s\"), row %d, column %d: Data type 0x%02X (user-defined table type) "
							"unexpected token encountered processing a table-valued parameter.",
							temp->paramOrdinal + 1, temp->paramMeta.colName.data, 1, i + 1, colmetadata[i].columnTdsType)));
		(*offset)++;
	}
	else
	{
		temp->isNull = true;	/* If TVP is NULL. */
		(*offset) += 2;
	}
	SetTvpRowData(temp, message, offset);
}

static inline void
SetColMetadataForFixedType(TdsColumnMetaData *col, uint8_t tdsType, uint8_t maxSize)
{
	col->sizeLen = 1;

	/*
	 * If column is Not NULL constrained then we don't want to send maxSize
	 * except for uniqueidentifier and xml. This needs to be done for identity
	 * contraints as well.
	 */
	if (col->attNotNull && tdsType != TDS_TYPE_UNIQUEIDENTIFIER && tdsType != TDS_TYPE_XML)
	{
		col->metaLen = sizeof(col->metaEntry.type1) - 1;
		if (col->attidentity)
			col->metaEntry.type1.flags = TDS_COL_METADATA_IDENTITY_FLAGS;
		else
			col->metaEntry.type1.flags = TDS_COL_METADATA_NOT_NULL_FLAGS;
	}
	else
	{
		col->metaLen = sizeof(col->metaEntry.type1);
		if (col->attgenerated)
			col->metaEntry.type1.flags = TDS_COL_METADATA_COMPUTED_FLAGS;
		else
			col->metaEntry.type1.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	}
	col->metaEntry.type1.tdsTypeId = tdsType;
	col->metaEntry.type1.maxSize = maxSize;
}

static inline void
SetColMetadataForCharType(TdsColumnMetaData *col, uint8_t tdsType, uint32_t codePage,
						  pg_enc encoding, uint16_t codeFlags, uint8_t sortId,
						  uint16_t maxSize)
{
	col->sizeLen = 2;
	col->metaLen = sizeof(col->metaEntry.type2);
	col->metaEntry.type2.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	col->metaEntry.type2.tdsTypeId = tdsType;
	col->metaEntry.type2.maxSize = maxSize;

	col->metaEntry.type2.collationInfo = codePage | (codeFlags << 20);
	col->metaEntry.type2.charSet = sortId;
	col->encoding = encoding;
}

static inline void
SetColMetadataForTextType(TdsColumnMetaData *col, uint8_t tdsType, uint32_t codePage,
						  pg_enc encoding, uint16_t codeFlags, uint8_t sortId,
						  uint32_t maxSize)
{
	col->sizeLen = 3;
	col->sendTableName = true;
	col->metaLen = sizeof(col->metaEntry.type3);
	col->metaEntry.type3.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	col->metaEntry.type3.tdsTypeId = tdsType;
	/* TODO: Remove the hardcoding :- BABEL-298 */
	col->metaEntry.type3.maxSize = 0x7fffffff;

	col->metaEntry.type3.collationInfo = codePage | (codeFlags << 20);
	col->metaEntry.type3.charSet = sortId;
	col->encoding = encoding;
}

static inline void
SetColMetadataForImageType(TdsColumnMetaData *col, uint8_t tdsType)
{
	col->sizeLen = 1;
	if (tdsType == TDS_TYPE_IMAGE)
	{
		col->sendTableName = true;
		col->metaEntry.type8.maxSize = 0x7fffffff;
	}
	else if (tdsType == TDS_TYPE_SQLVARIANT)
	{
		col->sendTableName = false;

		/*
		 * varchar(max), nvarchar(max), varbinary(max) can not be supported by
		 * sql_variant, this is a datatype restriction, hence, maxLen
		 * supported for varchar, nvarchar, varbinary would be <= 8K
		 */
		col->metaEntry.type8.maxSize = 0x00001f49;
	}
	col->metaLen = sizeof(col->metaEntry.type8);
	col->metaEntry.type8.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	col->metaEntry.type8.tdsTypeId = tdsType;
}

static inline void
SetColMetadataForDateType(TdsColumnMetaData *col, uint8_t tdsType)
{
	col->sizeLen = 1;
	col->metaLen = sizeof(col->metaEntry.type4);
	col->metaEntry.type4.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	col->metaEntry.type4.tdsTypeId = tdsType;
}

static inline void
SetColMetadataForNumericType(TdsColumnMetaData *col, uint8_t tdsType,
							 uint8_t maxSize, uint8_t precision, uint8_t scale)
{
	col->sizeLen = 1;
	col->metaLen = sizeof(col->metaEntry.type5);
	col->metaEntry.type5.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	col->metaEntry.type5.tdsTypeId = tdsType;
	col->metaEntry.type5.maxSize = maxSize;
	col->metaEntry.type5.precision = precision;
	col->metaEntry.type5.scale = scale;
}

static inline void
SetColMetadataForBinaryType(TdsColumnMetaData *col, uint8_t tdsType, uint16_t maxSize)
{
	col->sizeLen = 1;
	col->metaLen = sizeof(col->metaEntry.type7);
	col->metaEntry.type7.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	col->metaEntry.type7.tdsTypeId = tdsType;
	col->metaEntry.type7.maxSize = maxSize;
}

static inline void
SetColMetadataForTimeType(TdsColumnMetaData *col, uint8_t tdsType, uint8_t scale)
{
	col->sizeLen = 1;
	col->metaLen = sizeof(col->metaEntry.type6);
	col->metaEntry.type6.flags = TDS_COL_METADATA_DEFAULT_FLAGS;
	col->metaEntry.type6.tdsTypeId = tdsType;
	col->metaEntry.type6.scale = scale;
}

static inline void
SetColMetadataForGeometryType(TdsColumnMetaData *col, uint8_t tdsType, uint16_t maxSize, char *assemblyName, char *typeName)
{
	col->sizeLen = 1;
	col->metaLen = sizeof(col->metaEntry.type7);
	col->metaEntry.type7.flags = TDS_COL_METADATA_COMPUTED_FLAGS;
	col->metaEntry.type7.tdsTypeId = tdsType;
	col->metaEntry.type7.maxSize = maxSize;
	col->isSpatialType = true;
	col->assemblyName = assemblyName;
	col->typeName = typeName;
}

static inline void
SetColMetadataForGeographyType(TdsColumnMetaData *col, uint8_t tdsType, uint16_t maxSize, char *assemblyName, char *typeName)
{
	col->sizeLen = 1;
	col->metaLen = sizeof(col->metaEntry.type7);
	col->metaEntry.type7.flags = TDS_COL_METADATA_COMPUTED_FLAGS;
	col->metaEntry.type7.tdsTypeId = tdsType;
	col->metaEntry.type7.maxSize = maxSize;
	col->isSpatialType = true;
	col->assemblyName = assemblyName;
	col->typeName = typeName;
}

/*
 * SetColMetadataForCharTypeHelper - set the collation for tds char datatypes by
 * doing lookup on the hashtable setup by babelfishpg_tsql extension, which maps
 * postgres collation to TSQL. If no entry is found then set the default
 * TSQL collation values.
 */
static inline void
SetColMetadataForCharTypeHelper(TdsColumnMetaData *col, uint8_t tdsType,
								Oid collation, int32 atttypmod)
{
	coll_info_t cinfo;

	cinfo = TdsLookupCollationTableCallback(collation);

	/*
	 * TODO: Remove the NULL condition once all the Postgres collations are
	 * mapped to TSQL
	 */
	if (cinfo.oid == InvalidOid)
	{
		SetColMetadataForCharType(col, tdsType,
								  TdsDefaultLcid,	/* collation lcid */
								  TdsDefaultClientEncoding,
								  TdsDefaultCollationFlags, /* collation flags */
								  TdsDefaultSortid, /* sort id */
								  atttypmod);
	}
	else
	{
		SetColMetadataForCharType(col, tdsType,
								  cinfo.lcid,
								  cinfo.enc,
								  cinfo.collateflags,
								  cinfo.sortid,
								  atttypmod);
	}
}

/*
 * SetColMetadataForTextTypeHelper - set the collation for tds text datatypes by
 * doing lookup on the hashtable setup by babelfishpg_tsql extension, which maps
 * postgres collation to TSQL. If no entry is found then set the default
 * TSQL collation values.
 */
static inline void
SetColMetadataForTextTypeHelper(TdsColumnMetaData *col, uint8_t tdsType,
								Oid collation, int32 atttypmod)
{
	coll_info_t cinfo;

	cinfo = TdsLookupCollationTableCallback(collation);

	/*
	 * TODO: Remove the NULL condition once all the Postgres collations are
	 * mapped to TSQL
	 */
	if (cinfo.oid == InvalidOid)
	{
		SetColMetadataForTextType(col, tdsType,
								  TdsDefaultLcid,	/* collation lcid */
								  TdsDefaultClientEncoding,
								  TdsDefaultCollationFlags, /* collation flags */
								  TdsDefaultSortid, /* sort id */
								  atttypmod);
	}
	else
	{
		SetColMetadataForTextType(col, tdsType,
								  cinfo.lcid,
								  cinfo.enc,
								  cinfo.collateflags,
								  cinfo.sortid,
								  atttypmod);
	}
}

/* Functions in tdssqlbatch.c */
extern TDSRequest GetSQLBatchRequest(StringInfo message);
extern void ProcessSQLBatchRequest(TDSRequest request);
extern void ExecuteSQLBatch(char *query);

/* Funtions in tdsrpc.c */
extern TDSRequest GetRPCRequest(StringInfo message);
extern void RestoreRPCBatch(StringInfo message, uint8_t *status, uint8_t *messageType);
extern void ProcessRPCRequest(TDSRequest request);

/* Functions in tdsxact.c */
extern TDSRequest GetTxnMgmtRequest(const StringInfo message);
extern void ProcessTxnMgmtRequest(TDSRequest request);
extern int	TestTxnMgmtRequest(TDSRequest request, const char *expectedStr);

/* Functions in tdsbulkload.c */
extern TDSRequest GetBulkLoadRequest(StringInfo message);
extern void ProcessBCPRequest(TDSRequest request);

#endif							/* TDS_REQUEST_H */
