/*-------------------------------------------------------------------------
 *
 * tdstypeio.c
 *	  TDS Listener functions for PG-Datum <-> TDS-protocol conversion
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdstypeio.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/htup_details.h"
#include "access/xact.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_type.h"
#include "catalog/pg_namespace.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "parser/scansup.h"
#include "utils/cash.h"
#include "utils/hsearch.h"
#include "utils/builtins.h"				/* for format_type_be() */
#include "utils/guc.h"
#include "utils/lsyscache.h"				/* for getTypeInputInfo() and OidInputFunctionCall()*/
#include "utils/numeric.h"
#include "utils/snapmgr.h"
#include "utils/syscache.h"
#include "utils/uuid.h"
#include "utils/varlena.h"
#include "utils/xml.h"

#include "src/include/tds_int.h"
#include "src/include/tds_timestamp.h"
#include "src/include/tds_typeio.h"
#include "src/include/err_handler.h"
#include "src/include/tds_instr.h"

#include "tds_data_map.c"  /* include tables that used to initialize hashmaps */

#define TDS_RETURN_DATUM(x)		return ((Datum) (x))

#define VARCHAR_MAX 2147483647

#define GetPgOid(pgTypeOid, finfo) \
do { \
	pgTypeOid = (finfo->ttmbasetypeid != InvalidOid) ? \
				finfo->ttmbasetypeid : finfo->ttmtypeid; \
} while(0);

/*
 * macros to store length of metadata (including metadata for base type) for sqlvariant datatypes.
 */
#define VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES 	2	/* for BIT, TINYINT, SMALLINT, INT, BIGINT, REAL, FLOAT, [SMALL]MONEY and UID */
#define VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES	9	/* for [N][VAR]CHAR */
#define VARIANT_TYPE_METALEN_FOR_BIN_DATATYPES 	4	/* for [VAR]BINARY */
#define VARIANT_TYPE_METALEN_FOR_NUMERIC_DATATYPES	5	/* for NUMERIC */
#define VARIANT_TYPE_METALEN_FOR_DATE 			2	/* for DATE */
#define VARIANT_TYPE_METALEN_FOR_SMALLDATETIME 	2	/* for SMALLDATETIME */
#define VARIANT_TYPE_METALEN_FOR_DATETIME 		2	/* for DATETIME */
#define VARIANT_TYPE_METALEN_FOR_TIME 			3	/* for TIME */
#define VARIANT_TYPE_METALEN_FOR_DATETIME2 		3	/* for DATETIME2 */
#define VARIANT_TYPE_METALEN_FOR_DATETIMEOFFSET	3	/* for DATETIMEOFFSET */

/*
 * macros to store length of metadata for base type of sqlvariant datatype.
 */
#define VARIANT_TYPE_BASE_METALEN_FOR_NUM_DATATYPES	0	/* for BIT, TINYINT, SMALLINT, INT, BIGINT, REAL, FLOAT, [SMALL]MONEY and UID */
#define VARIANT_TYPE_BASE_METALEN_FOR_CHAR_DATATYPES	7	/* for [N][VAR]CHAR */
#define VARIANT_TYPE_BASE_METALEN_FOR_BIN_DATATYPES	2	/* for [VAR]BINARY */
#define VARIANT_TYPE_BASE_METALEN_FOR_NUMERIC_DATATYPES	2	/* for NUMERIC */
#define VARIANT_TYPE_BASE_METALEN_FOR_DATE	0	/* for DATE */
#define VARIANT_TYPE_BASE_METALEN_FOR_SMALLDATETIME	0	/* for SMALLDATETIME */
#define VARIANT_TYPE_BASE_METALEN_FOR_DATETIME	0	/* for DATETIME */
#define VARIANT_TYPE_BASE_METALEN_FOR_TIME	1	/* for TIME */
#define VARIANT_TYPE_BASE_METALEN_FOR_DATETIME2	1	/* for DATETIME2 */
#define VARIANT_TYPE_BASE_METALEN_FOR_DATETIMEOFFSET	1	/* for DATETIMEOFFSET */

static HTAB	   *functionInfoCacheByOid = NULL;
static HTAB	   *functionInfoCacheByTdsId = NULL;

static HTAB    *TdsEncodingInfoCacheByLCID = NULL;

void CopyMsgBytes(StringInfo msg, char *buf, int datalen);
int GetMsgByte(StringInfo msg);
const char * GetMsgBytes(StringInfo msg, int datalen);
unsigned int GetMsgInt(StringInfo msg, int b);
int64 GetMsgInt64(StringInfo msg);
uint128 GetMsgUInt128(StringInfo msg);
float4 GetMsgFloat4(StringInfo msg);
float8 GetMsgFloat8(StringInfo msg);
static void SwapData(StringInfo buf, int st, int end);
static Datum TdsAnyToServerEncodingConversion(pg_enc encoding, char *str, int len, uint8_t tdsColDataType);
int TdsUTF16toUTF8XmlResult(StringInfo buf, void **resultPtr);

Datum TdsTypeBitToDatum(StringInfo buf);
Datum TdsTypeIntegerToDatum(StringInfo buf, int maxLen);
Datum TdsTypeFloatToDatum(StringInfo buf, int maxLen);
Datum TdsTypeVarcharToDatum(StringInfo buf, pg_enc encoding, uint8_t tdsColDataType);
Datum TdsTypeNCharToDatum(StringInfo buf);
Datum TdsTypeNumericToDatum(StringInfo buf, int scale);
Datum TdsTypeVarbinaryToDatum(StringInfo buf);
Datum TdsTypeDatetime2ToDatum(StringInfo buf, int scale, int len);
Datum TdsTypeDatetimeToDatum(StringInfo buf);
Datum TdsTypeSmallDatetimeToDatum(StringInfo buf);
Datum TdsTypeDateToDatum(StringInfo buf);
Datum TdsTypeTimeToDatum(StringInfo buf, int scale, int len);
Datum TdsTypeDatetimeoffsetToDatum(StringInfo buf, int scale, int len);
Datum TdsTypeMoneyToDatum(StringInfo buf);
Datum TdsTypeSmallMoneyToDatum(StringInfo buf);
Datum TdsTypeXMLToDatum(StringInfo buf);
Datum TdsTypeUIDToDatum(StringInfo buf);
Datum TdsTypeSqlVariantToDatum(StringInfo buf);

/* Local structures for the Function Cache by TDS Type ID */
typedef struct FunctionCacheByTdsIdKey
{
	int32_t		tdstypeid;
	int32_t		tdstypelen;
} FunctionCacheByTdsIdKey;

typedef struct FunctionCacheByTdsIdEntry
{
	FunctionCacheByTdsIdKey		key;
	TdsIoFunctionData		data;
} FunctionCacheByTdsIdEntry;

/*
 * getSendFunc - get the function pointer for type output
 *
 * 	Given the ttmsendfunc id returns the function pointer for the
 * 	corresponding output function to call.
 */
static inline TdsSendTypeFunction
getSendFunc(int funcId)
{
	switch (funcId)
	{
		case TDS_SEND_BIT:		return TdsSendTypeBit;
		case TDS_SEND_TINYINT:		return TdsSendTypeTinyint;
		case TDS_SEND_SMALLINT:		return TdsSendTypeSmallint;
		case TDS_SEND_INTEGER:		return TdsSendTypeInteger;
		case TDS_SEND_BIGINT:		return TdsSendTypeBigint;
		case TDS_SEND_FLOAT4:		return TdsSendTypeFloat4;
		case TDS_SEND_FLOAT8:		return TdsSendTypeFloat8;
		case TDS_SEND_VARCHAR:		return TdsSendTypeVarchar;
		case TDS_SEND_NVARCHAR:		return TdsSendTypeNVarchar;
		case TDS_SEND_MONEY:		return TdsSendTypeMoney;
		case TDS_SEND_SMALLMONEY:	return TdsSendTypeSmallmoney;
		case TDS_SEND_CHAR:		return TdsSendTypeChar;
		case TDS_SEND_NCHAR:		return TdsSendTypeNChar;
		case TDS_SEND_SMALLDATETIME:	return TdsSendTypeSmalldatetime;
		case TDS_SEND_TEXT:		return TdsSendTypeText;
		case TDS_SEND_NTEXT:		return TdsSendTypeNText;
		case TDS_SEND_DATE:		return TdsSendTypeDate;
		case TDS_SEND_DATETIME:		return TdsSendTypeDatetime;
		case TDS_SEND_NUMERIC:		return TdsSendTypeNumeric;
		case TDS_SEND_IMAGE:		return TdsSendTypeImage;
		case TDS_SEND_BINARY:		return TdsSendTypeBinary;
		case TDS_SEND_VARBINARY:	return TdsSendTypeVarbinary;
		case TDS_SEND_UNIQUEIDENTIFIER:	return TdsSendTypeUniqueIdentifier;
		case TDS_SEND_TIME:		return TdsSendTypeTime;
		case TDS_SEND_DATETIME2:	return TdsSendTypeDatetime2;
		case TDS_SEND_XML:		return TdsSendTypeXml;
		case TDS_SEND_SQLVARIANT:	return TdsSendTypeSqlvariant;
		case TDS_SEND_DATETIMEOFFSET:	return TdsSendTypeDatetimeoffset;
		/* TODO: should Assert here once all types are implemented */
		default:					return NULL;
	}
}

/*
 * TdsRecvTypeFunction - get the function pointer for type input
 *
 * 	Given the ttmsendfunc id returns the function pointer for the
 * 	corresponding input function to call.
 */
static inline TdsRecvTypeFunction
getRecvFunc(int funcId)
{
	switch (funcId)
	{
		case TDS_RECV_BIT:		return TdsRecvTypeBit;
		case TDS_RECV_TINYINT:		return TdsRecvTypeTinyInt;
		case TDS_RECV_SMALLINT:		return TdsRecvTypeSmallInt;
		case TDS_RECV_INTEGER:		return TdsRecvTypeInteger;
		case TDS_RECV_BIGINT:		return TdsRecvTypeBigInt;
		case TDS_RECV_FLOAT4:		return TdsRecvTypeFloat4;
		case TDS_RECV_FLOAT8:		return TdsRecvTypeFloat8;
		case TDS_RECV_VARCHAR:		return TdsRecvTypeVarchar;
		case TDS_RECV_NVARCHAR:		return TdsRecvTypeNVarchar;
		case TDS_RECV_MONEY:		return TdsRecvTypeMoney;
		case TDS_RECV_SMALLMONEY:	return TdsRecvTypeSmallmoney;
		case TDS_RECV_CHAR:		return TdsRecvTypeChar;
		case TDS_RECV_NCHAR:		return TdsRecvTypeNChar;
		case TDS_RECV_SMALLDATETIME:	return TdsRecvTypeSmalldatetime;
		case TDS_RECV_TEXT:		return TdsRecvTypeText;
		case TDS_RECV_NTEXT:		return TdsRecvTypeNText;
		case TDS_RECV_DATE:		return TdsRecvTypeDate;
		case TDS_RECV_DATETIME:		return TdsRecvTypeDatetime;
		case TDS_RECV_NUMERIC:		return TdsRecvTypeNumeric;
		case TDS_RECV_IMAGE:		return TdsRecvTypeBinary;
		case TDS_RECV_BINARY:		return TdsRecvTypeBinary;
		case TDS_RECV_VARBINARY:	return TdsRecvTypeVarbinary;
		case TDS_RECV_UNIQUEIDENTIFIER:	return TdsRecvTypeUniqueIdentifier;
		case TDS_RECV_TIME:		return TdsRecvTypeTime;
		case TDS_RECV_DATETIME2:	return TdsRecvTypeDatetime2;
		case TDS_RECV_XML:		return TdsRecvTypeXml;
		case TDS_RECV_TABLE:		return TdsRecvTypeTable;
		case TDS_RECV_SQLVARIANT:	return TdsRecvTypeSqlvariant;
		case TDS_RECV_DATETIMEOFFSET:	return TdsRecvTypeDatetimeoffset;
		/* TODO: should Assert here once all types are implemented */
		default:					return NULL;
	}
}

collation_callbacks *collation_callbacks_ptr = NULL;

static void
init_collation_callbacks(void)
{
	collation_callbacks **callbacks_ptr;
	callbacks_ptr = (collation_callbacks **) find_rendezvous_variable("collation_callbacks"); 
	collation_callbacks_ptr = *callbacks_ptr;
}

char * TdsEncodingConversion(const char *s, int len, pg_enc src_encoding, pg_enc dest_encoding, int *encodedByteLen)
{
	if (!collation_callbacks_ptr)
		init_collation_callbacks();

	if (collation_callbacks_ptr && collation_callbacks_ptr->EncodingConversion)
		return (*collation_callbacks_ptr->EncodingConversion)(s, len, src_encoding, dest_encoding, encodedByteLen);
	else
		/* unlikely */
		ereport(ERROR, 
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Could not encode the string to the client encoding")));
}

coll_info_t TdsLookupCollationTableCallback(Oid oid)
{
	if (!collation_callbacks_ptr)
		init_collation_callbacks();

	if (collation_callbacks_ptr && collation_callbacks_ptr->lookup_collation_table_callback)
		return (*collation_callbacks_ptr->lookup_collation_table_callback)(oid);
	else
	{
		coll_info_t invalidCollInfo;
		invalidCollInfo.oid = InvalidOid;
		return invalidCollInfo;
	}
}

#ifdef USE_LIBXML

static int
xmlChar_to_encoding(const xmlChar *encoding_name)
{
	int encoding = pg_char_to_encoding((const char *)encoding_name);

	if (encoding < 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("invalid encoding name \"%s\"",
						(const char *)encoding_name)));
	return encoding;
}
#endif

int TdsUTF16toUTF8XmlResult(StringInfo buf, void **resultPtr)
{
	char *str;
	int nbytes;
	StringInfoData tempBuf;
	void *result;

	initStringInfo(&tempBuf);
	enlargeStringInfo(&tempBuf, buf->len);
	TdsUTF16toUTF8StringInfo(&tempBuf, buf->data, buf->len);
	buf = &tempBuf;

	nbytes = buf->len - buf->cursor;

	str = (char *)GetMsgBytes(buf, nbytes);

	result = palloc0(nbytes + 1 + VARHDRSZ);
	SET_VARSIZE(result, nbytes + VARHDRSZ);
	memcpy(VARDATA(result), str, nbytes);
	str = VARDATA(result);
	str[nbytes] = '\0';

	*resultPtr = result;

	return PG_UTF8;
}

/*
 * TdsAnyToServerEncodingConversion - lookup the PG Encoding based on lcid
 * and convert the encoding of input str
 */
static Datum
TdsAnyToServerEncodingConversion(pg_enc encoding, char *str, int len, uint8_t tdsColDataType)
{
	char 		*pstring;
	Datum 		pval;
	int			actualLen;

	/* The dest_encoding will always be UTF8 for Babelfish */
	pstring = TdsEncodingConversion(str, len, encoding, PG_UTF8, &actualLen);

	switch (tdsColDataType)
	{
		case TDS_TYPE_VARCHAR:
			pval = PointerGetDatum(pltsql_plugin_handler_ptr->tsql_varchar_input(pstring, actualLen, -1));
			break;
		case TDS_TYPE_CHAR:
			pval = PointerGetDatum(pltsql_plugin_handler_ptr->tsql_char_input(pstring, actualLen, -1));
			break;
		case TDS_TYPE_TEXT:
			pval = PointerGetDatum(cstring_to_text(pstring));
			break;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("TdsAnyToServerEncodingConversion is not supported for Tds Type: %d", tdsColDataType)));
			break;
	}

	/* Free result of encoding conversion, if any */
	if (pstring && pstring != str)
		pfree(pstring);

	return pval;
}

/*
 * TdsResetTypeFunctionCache - reset the type function caches.
 *
 * During connection reset, this is used.
 */
void
TdsResetCache(void)
{
	functionInfoCacheByOid = NULL;
	functionInfoCacheByTdsId = NULL;
	TdsEncodingInfoCacheByLCID = NULL;
	reset_error_mapping_cache();
}

void
TdsLoadEncodingLCIDCache(void)
{
	HASHCTL 				hashCtl;

	if (TdsEncodingInfoCacheByLCID == NULL)
	{
		/* Create the LCID - Encoding (code page in tsql's term) hash table in our TDS memory context */
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(int);
		hashCtl.entrysize = 2 * sizeof(int);
		hashCtl.hcxt = TdsMemoryContext;
		TdsEncodingInfoCacheByLCID = hash_create("LCID - Encoding map cache",
											SPI_processed,
											&hashCtl,
											HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
		/*
		* Load LCID - Encoding pair into our hash table.
		*/
		for (int i = 0; i < TdsLCIDToEncodingMap_datasize; i++)
		{
			int 						lcid;
			TdsLCIDToEncodingMapInfo mInfo;

			/* Create the hash entry for lookup by LCID*/
			lcid = TdsLCIDToEncodingMap_data[i].lcid;
			mInfo = (TdsLCIDToEncodingMapInfo)hash_search(TdsEncodingInfoCacheByLCID,
													&lcid,
													HASH_ENTER,
													NULL);
			mInfo->enc = TdsLCIDToEncodingMap_data[i].enc;
		}
	}
}

/* 
 * TdsLookupEncodingByLCID - LCID - Encoding lookup 
 */
int
TdsLookupEncodingByLCID(int lcid)
{
	bool found;
	TdsLCIDToEncodingMapInfo mInfo;

	mInfo = (TdsLCIDToEncodingMapInfo)hash_search(TdsEncodingInfoCacheByLCID,
													&lcid,
													HASH_FIND,
													&found);

	/*
	 * TODO: which encoding by default we should consider 
	 * if appropriate Encoding is not found.
	 */
	if (!found)
	{
		mInfo = (TdsLCIDToEncodingMapInfo)hash_search(TdsEncodingInfoCacheByLCID,
													&TdsDefaultLcid,
													HASH_FIND,
													&found);
		/*
		 * could not find encoding corresponding to default lcid still.
		 */
		if (!found)
			return -1;
	}
	return mInfo->enc;
}

void
TdsLoadTypeFunctionCache(void)
{
	HASHCTL	hashCtl;
	Oid sys_nspoid = get_namespace_oid("sys", false);

	/* Create the function info hash table in our TDS memory context */
	if (functionInfoCacheByOid == NULL) /* create hash table */
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(Oid);
		hashCtl.entrysize = sizeof(TdsIoFunctionData);
		hashCtl.hcxt = TdsMemoryContext;
		functionInfoCacheByOid = hash_create("IO function info cache",
											SPI_processed,
											&hashCtl,
											HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	if (functionInfoCacheByTdsId == NULL) /* create hash table */
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(FunctionCacheByTdsIdKey);
		hashCtl.entrysize = sizeof(FunctionCacheByTdsIdEntry);
		hashCtl.hcxt = TdsMemoryContext;
		functionInfoCacheByTdsId = hash_create("IO function info cache by TDS id",
											SPI_processed,
											&hashCtl,
											HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}
	/*
	 * Load the contents of the table into our hash table.
	 */

	for (int i = 0; i < TdsIoFunctionRawData_datasize; i++)
	{
		Oid							typeoid;
		Oid							basetypeoid;
    	Oid                         nspoid;
		TdsIoFunctionInfo		finfo;
		FunctionCacheByTdsIdKey		fc2key;
		FunctionCacheByTdsIdEntry  *fc2ent;

		nspoid = strcmp(TdsIoFunctionRawData_data[i].typnsp, "sys") == 0 ? sys_nspoid : PG_CATALOG_NAMESPACE;
        typeoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
                                            CStringGetDatum(TdsIoFunctionRawData_data[i].typname), ObjectIdGetDatum(nspoid));

		if (OidIsValid(typeoid))
		{
			basetypeoid = getBaseType(typeoid);
			finfo = (TdsIoFunctionInfo)hash_search(functionInfoCacheByOid,
											&typeoid,
											HASH_ENTER,
											NULL);
			finfo->ttmbasetypeid = typeoid == basetypeoid ? 0 : basetypeoid;
			finfo->ttmtdstypeid = TdsIoFunctionRawData_data[i].ttmtdstypeid;
			finfo->ttmtdstypelen = TdsIoFunctionRawData_data[i].ttmtdstypelen;
			finfo->ttmtdslenbytes = TdsIoFunctionRawData_data[i].ttmtdslenbytes;
			finfo->sendFuncId = TdsIoFunctionRawData_data[i].ttmsendfunc;
			finfo->sendFuncPtr = getSendFunc(finfo->sendFuncId);
			finfo->recvFuncId = TdsIoFunctionRawData_data[i].ttmrecvfunc;
			finfo->recvFuncPtr = getRecvFunc(finfo->recvFuncId);

			/* Create the hash entry for lookup by TDS' type ID */
			fc2key.tdstypeid = TdsIoFunctionRawData_data[i].ttmtdstypeid;
			fc2key.tdstypelen = TdsIoFunctionRawData_data[i].ttmtdstypelen;

			if(TdsIoFunctionRawData_data[i].ttmrecvfunc != TDS_RECV_INVALID) /* Do not load the Receiver function if its Invalid. */
			{
				fc2ent = (FunctionCacheByTdsIdEntry *)hash_search(functionInfoCacheByTdsId,
														&fc2key,
														HASH_ENTER,
														NULL);
				finfo = &(fc2ent->data);
				finfo->ttmtypeid = typeoid;
				finfo->ttmbasetypeid = basetypeoid;
				finfo->ttmtdstypeid = TdsIoFunctionRawData_data[i].ttmtdstypeid;
				finfo->ttmtdstypelen = TdsIoFunctionRawData_data[i].ttmtdstypelen;
				finfo->ttmtdslenbytes = TdsIoFunctionRawData_data[i].ttmtdslenbytes;
				finfo->sendFuncId = TdsIoFunctionRawData_data[i].ttmsendfunc;
				finfo->sendFuncPtr = getSendFunc(finfo->sendFuncId);
				finfo->recvFuncId = TdsIoFunctionRawData_data[i].ttmrecvfunc;
				finfo->recvFuncPtr = getRecvFunc(finfo->recvFuncId);
			}
		}
	}

	{
		/* Load Table Valued Paramerter since we can't have a static oid mapping for it.*/
		TdsIoFunctionInfo finfo_table;
		FunctionCacheByTdsIdKey fc2key_table;
		FunctionCacheByTdsIdEntry *fc2ent_table;

		fc2key_table.tdstypeid = TDS_TYPE_TABLE;
		fc2key_table.tdstypelen = -1;
		fc2ent_table = (FunctionCacheByTdsIdEntry *)hash_search(functionInfoCacheByTdsId,
															&fc2key_table,
															HASH_ENTER,
															NULL);
		finfo_table = &(fc2ent_table->data);
		finfo_table->ttmtypeid = InvalidOid;
		finfo_table->ttmbasetypeid = InvalidOid;
		finfo_table->ttmtdstypeid = TDS_TYPE_TABLE;
		finfo_table->ttmtdstypelen = -1;
		finfo_table->ttmtdslenbytes = 1;
		finfo_table->sendFuncId = -1;
		finfo_table->sendFuncPtr = getSendFunc(-1);
		finfo_table->recvFuncId = TDS_RECV_TABLE;
		finfo_table->recvFuncPtr = getRecvFunc(TDS_RECV_TABLE);
	}
}

/*
 * TdsLookupTypeFunctionsByOid - IO function cache lookup
 */
TdsIoFunctionInfo
TdsLookupTypeFunctionsByOid(Oid typeId, int32* typmod)
{
	TdsIoFunctionInfo	finfo;
	bool					found;
	Oid						tmpTypeId;

	Assert(functionInfoCacheByOid != NULL);

	finfo = (TdsIoFunctionInfo)hash_search(functionInfoCacheByOid,
											  &typeId,
											  HASH_FIND,
											  &found);

	/*
	 * If an entry is not found on tds mapping table, we try to find whether
	 * we've an entry for its base type.  If not found, we continue till the
	 * bottom base type.
	 */
	tmpTypeId = typeId;
	while (!found)
	{
		HeapTuple	tup;
		Form_pg_type typTup;

		tup = SearchSysCache1(TYPEOID, ObjectIdGetDatum(tmpTypeId));
		if (!HeapTupleIsValid(tup))
			break;

		typTup = (Form_pg_type) GETSTRUCT(tup);
		if (typTup->typtype != TYPTYPE_DOMAIN)
		{
			/* Not a domain, so stop descending */
			ReleaseSysCache(tup);
			break;
		}

		tmpTypeId = typTup->typbasetype;

		/*
		 * Typmod is allowed for domain only when enable_domain_typmod
		 * is enabled when executing the CREATE DOMAIN Statement,
		 * see DefineDomain for details.
		 */
		if (*typmod == -1)
			*typmod = typTup->typtypmod;

		finfo = (TdsIoFunctionInfo)hash_search(functionInfoCacheByOid,
												  &tmpTypeId,
												  HASH_FIND,
												  &found);
		ReleaseSysCache(tup);
	}

	if (!found)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("data type %s is not supported yet", format_type_be(typeId))));

	return finfo;
}

/*
 * TdsLookupTypeFunctionsByTdsId - IO function cache lookup
 */
TdsIoFunctionInfo
TdsLookupTypeFunctionsByTdsId(int32_t typeId, int32_t typeLen)
{
	FunctionCacheByTdsIdKey		fc2key;
	FunctionCacheByTdsIdEntry  *fc2ent;
	bool						found;

	Assert(functionInfoCacheByTdsId != NULL);

	/* Try a lookup with the indicated length */
	fc2key.tdstypeid = typeId;
	fc2key.tdstypelen = typeLen;
	fc2ent = (FunctionCacheByTdsIdEntry *)hash_search(functionInfoCacheByTdsId,
													  &fc2key,
													  HASH_FIND,
													  &found);
	if (found)
		return &(fc2ent->data);

	/* Variable length types are configured with len=-1, so try that */
	fc2key.tdstypeid = typeId;
	fc2key.tdstypelen = -1;
	fc2ent = (FunctionCacheByTdsIdEntry *)hash_search(functionInfoCacheByTdsId,
													  &fc2key,
													  HASH_FIND,
													  &found);
	if (found)
		return &(fc2ent->data);

	/*
	 * In spite of being fixed length datatypes, Numeric and Decimal at times
	 * come on wire with a different length as part of the column-metadata.
	 * We shall update the tdstypelen and search again.
	 */
	if (typeId == TDS_TYPE_NUMERICN || typeId == TDS_TYPE_DECIMALN)
	{
		fc2key.tdstypelen = TDS_MAXLEN_NUMERIC;
		fc2ent = (FunctionCacheByTdsIdEntry *)hash_search(functionInfoCacheByTdsId,
														  &fc2key,
														  HASH_FIND,
														  &found);
		if (found)
			return &(fc2ent->data);
	}

	/* Not found either way */
	ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
			 errmsg("data type %d not supported yet", typeId)));

	return NULL;
}

/* --------------------------------
 * CopyMsgBytes - copy raw data from a message buffer
 *
 * Same as above, except data is copied to caller's buffer.
 * Function definition closely matches to pq_copymsgbytes
 * --------------------------------
 */
void
CopyMsgBytes(StringInfo msg, char *buf, int datalen)
{
	if (datalen < 0 || datalen > (msg->len - msg->cursor))
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("insufficient data left in message")));
	memcpy(buf, &msg->data[msg->cursor], datalen);
	msg->cursor += datalen;
}

/* --------------------------------
 * GetMsgByte - get a raw byte from a message buffer
 * Function definition closely matches pq_getmsgbyte
 * --------------------------------
 */
int
GetMsgByte(StringInfo msg)
{
	if (msg->cursor >= msg->len)
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("no data left in message")));
	return (unsigned char) msg->data[msg->cursor++];
}

/* --------------------------------
 *		GetMsgBytes	- get raw data from a message buffer
 *
 *		Returns a pointer directly into the message buffer; note this
 *		may not have any particular alignment.
 * --------------------------------
 */
const char *
GetMsgBytes(StringInfo msg, int datalen)
{
	const char *result;

	if (datalen < 0 || datalen > (msg->len - msg->cursor))
		ereport(FATAL,
				(errcode(ERRCODE_PROTOCOL_VIOLATION),
				 errmsg("insufficient data left in message")));
	result = &msg->data[msg->cursor];
	msg->cursor += datalen;
	return result;
}

/* --------------------------------
 * GetMsgInt - get a binary integer from a message buffer
 *
 * Values are treated as unsigned.
 * Function definition closely matches to pq_getmsgint
 * --------------------------------
 */
unsigned int
GetMsgInt(StringInfo msg, int b)
{
	unsigned int result;
	unsigned char n8;
	uint16		n16;
	uint32		n32;

	switch (b)
	{
		case 1:
			CopyMsgBytes(msg, (char *) &n8, 1);
			result = n8;
			break;
		case 2:
			CopyMsgBytes(msg, (char *) &n16, 2);
			result = LEtoh16(n16);
			break;
		case 3:
			memset(&n32, 0, sizeof(n32));
			CopyMsgBytes(msg, (char *) &n32, 3);
			result = LEtoh32(n32);
			break;
		case 4:
			CopyMsgBytes(msg, (char *) &n32, 4);
			result = LEtoh32(n32);
			break;
		default:
			elog(ERROR, "unsupported integer size %d", b);
			result = 0;			/* keep compiler quiet */
			break;
	}
	return result;
}

/* --------------------------------
 * GetMsgInt64 - get a binary 8-byte int from a message buffer
 *
 * It is tempting to merge this with GetMesInt, but we'd have to make the
 * result int64 for all data widths --- that could be a big performance
 * hit on machines where int64 isn't efficient.
 * Function definition closely mateches to pg_getmsgint64
 * --------------------------------
 */
int64
GetMsgInt64(StringInfo msg)
{
	uint64		n64;

	CopyMsgBytes(msg, (char *) &n64, sizeof(n64));

	return LEtoh64(n64);
}

/* --------------------------------
 * GetMsgUInt128 - get a binary 16-byte unsigned int from a message buffer
 * --------------------------------
 */
uint128
GetMsgUInt128(StringInfo msg)
{
	uint128		n128;

	memcpy(&n128, &msg->data[msg->cursor], sizeof(n128));
	msg->cursor += sizeof(n128);

	return LEtoh128(n128);
}

/* --------------------------------
 * GetMsgFloat4 - get a float4 from a message buffer
 *
 * Function definition closely matches to pq_getmsgfloat4
 * --------------------------------
 */
float4
GetMsgFloat4(StringInfo msg)
{
	union
	{
		float4		f;
		uint32		i;
	}			swap;

	swap.i = GetMsgInt(msg, 4);
	return swap.f;

}

/* --------------------------------
 * GetMsgFloat8 - get a float8 from a message buffer
 *
 * Function definition closely matches to pq_getmsgfloat8
 * --------------------------------
 */
float8
GetMsgFloat8(StringInfo msg)
{
	union
	{
		float8		f;
		int64		i;
	}			swap;

	swap.i = GetMsgInt64(msg);
	return swap.f;
}

/* Helper Function to convert Bit value into Datum. */
Datum
TdsTypeBitToDatum(StringInfo buf)
{
	int ext = GetMsgByte(buf);
	PG_RETURN_BOOL((ext != 0) ? true : false);
}

/* Helper Function to convert Integer value into Datum. */
Datum
TdsTypeIntegerToDatum(StringInfo buf, int maxLen)
{
	switch(maxLen)
	{
		case TDS_MAXLEN_TINYINT: /* TINY INT. */
		{
			uint8 res = GetMsgInt(buf, sizeof(int8));
			PG_RETURN_INT16((int16) res);
		}
		break;
		case TDS_MAXLEN_SMALLINT: /* SMALL INT. */
		{
			uint16 res = GetMsgInt(buf, sizeof(uint16));
			PG_RETURN_INT16((uint16) res);
		}
		break;
		case TDS_MAXLEN_INT: /* INT. */
		{
			unsigned int res = GetMsgInt(buf, sizeof(int32));
			PG_RETURN_INT32((int32) res);
		}
		break;
		case TDS_MAXLEN_BIGINT: /* BIG INT. */
		{
			uint64 res = GetMsgInt64(buf);
			PG_RETURN_INT64((int64) res);
		}
		break;
		default:
			elog(ERROR, "unsupported integer size %d", maxLen);
			PG_RETURN_INT32(0);		/* keep compiler quiet */
		break;
	}
}

/* Helper Function to convert Float value into Datum. */
Datum
TdsTypeFloatToDatum(StringInfo buf, int maxLen)
{
	switch(maxLen)
	{
		case TDS_MAXLEN_FLOAT4:
		{
			float4 res;
			res = GetMsgFloat4(buf);
			PG_RETURN_FLOAT4(res);
		}
		break;
		case TDS_MAXLEN_FLOAT8:
		{
			float8 res;
			res = GetMsgFloat8(buf);
			PG_RETURN_FLOAT8(res);
		}
		default:
			elog(ERROR, "unsupported float size %d", maxLen);
			PG_RETURN_FLOAT4(0);		/* keep compiler quiet */
		break;
	}
}

/* Helper Function to convert Varchar,Char and Text values into Datum. */
Datum
TdsTypeVarcharToDatum(StringInfo buf, pg_enc encoding, uint8_t tdsColDataType)
{
	char 		csave;
	Datum 		pval;

	csave = buf->data[buf->len];
	buf->data[buf->len] = '\0';

	pval = TdsAnyToServerEncodingConversion(encoding,
									buf->data, buf->len,
									tdsColDataType);
	buf->data[buf->len] = csave;
	return pval;
}

/* Helper Function to convert NVarchar, NChar and NText values into Datum. */
Datum
TdsTypeNCharToDatum(StringInfo buf)
{
	void    *result;
	StringInfoData temp;

	initStringInfo(&temp);
	TdsUTF16toUTF8StringInfo(&temp, buf->data, buf->len);

	result = tds_varchar_input(temp.data, temp.len, -1);
	pfree(temp.data);

	PG_RETURN_VARCHAR_P(result);
}

static inline char *
ReverseString(char *res)
{
	int lo, hi;
	if (!res)
		return NULL;

	lo = 0;
	hi = strlen(res)-1;

	while (lo < hi)
	{
		res[lo] ^= res[hi];
		res[hi] ^= res[lo];
		res[lo] ^= res[hi];
		lo++; hi--;
	}
	return res;
}

static inline void
Integer2String(uint128 num, char* str)
{
	int i = 0, rem = 0;
	while (num)
	{
		rem = num % 10;
		str[i++] = rem + '0';
		num = num/10;
	}
	str[i++] = '-';
	ReverseString(str);
}

/* Helper Function to convert Numeric value into Datum. */
Datum
TdsTypeNumericToDatum(StringInfo buf, int scale)
{
	Numeric		res;
	int		 	len, sign;
	char		*decString;
	int		temp1, temp2;
	uint128		num = 0;

	/* fetch the sign from the actual data which is the first byte */
	sign = (uint8_t)GetMsgInt(buf, 1);

	/* fetch the data but ignore the sign byte now */
	{
		uint128		n128 = 0;

		memcpy(&n128, &buf->data[buf->cursor], TDS_MAXLEN_NUMERIC - 1);
		buf->cursor += TDS_MAXLEN_NUMERIC - 1;

		num = LEtoh128(n128);
	}

	decString = (char *)palloc0(sizeof(char) * 40);

	if (num != 0)
		Integer2String(num, decString);
	else
		decString[0] = '0';

	len = strlen(decString);
	temp1 = '.';

	/*
	 * If scale is more than length then we need to append zeros at the start;
	 * Since there is a '-' at the start of decString, we should ignore it before
	 * appending and then add it later.
	 */
	if (num != 0 && scale >= len)
	{
		int diff = scale - len + 1;
		char *zeros = palloc0(sizeof(char) * diff + 1);
		char *tempString = decString;
		while(diff)
		{
			zeros[--diff] = '0';
		}
		/*
		 * Add extra '.' character in psprintf; Later we make use of
		 * this index during shifting the scale part of the string.
		 */
		decString = psprintf("-%s%s.", zeros, tempString + 1);
		len = strlen(decString) - 1;
		pfree(tempString);
	}
	if (num != 0)
	{
		while (scale)
		{
			temp2 = decString[len - scale];
			decString[len - scale] = temp1;
			temp1 = temp2;
			scale--;
		}
		decString[len++] = temp1;
	}
	else
	{
		decString[len++] = temp1;
		while (scale)
		{
			decString[len++] = '0';
			scale--;
		}
	}

	if (sign == 1 && num != 0)
		decString++;

	res = TdsSetVarFromStrWrapper(decString);
	PG_RETURN_NUMERIC(res);
}

/* Helper Function to convert Varbinary and Binary values into Datum. */
Datum
TdsTypeVarbinaryToDatum(StringInfo buf)
{
	bytea           *result;
	int             nbytes;

	nbytes = buf->len - buf->cursor;
	result = (bytea *) palloc0(nbytes + VARHDRSZ);
	SET_VARSIZE(result, nbytes + VARHDRSZ);
	CopyMsgBytes(buf, VARDATA(result), nbytes);

	PG_RETURN_BYTEA_P(result);
}

/* Helper Function to convert Datetime2 value into Datum. */
Datum
TdsTypeDatetime2ToDatum(StringInfo buf, int scale, int len)
{
	uint64_t    numMicro = 0;
	uint32_t	numDays = 0;
	Timestamp	timestamp;

	if (scale == 255)
		scale = DATETIMEOFFSETMAXSCALE;

	memcpy(&numMicro, &buf->data[buf->cursor], len - 3);
	buf->cursor += len - 3;

	memcpy(&numDays, &buf->data[buf->cursor], 3);
	buf->cursor += 3;

	TdsGetTimestampFromDayTime(numDays, numMicro, 0, &timestamp, scale);

	PG_RETURN_TIMESTAMP((Timestamp)timestamp);
}

/* Helper Function to convert Datetime value into Datum. */
Datum
TdsTypeDatetimeToDatum(StringInfo buf)
{
	uint32	numDays, numTicks;
	uint64	val;
	Timestamp	timestamp;

	val = (uint64)GetMsgInt64(buf);
	numTicks = val >> 32;
	numDays = val & 0x00000000ffffffff;

	TdsTimeGetDatumFromDatetime(numDays, numTicks, &timestamp);

	PG_RETURN_TIMESTAMP((uint64)timestamp);
}

/* Helper Function to convert Small Datetime value into Datum. */
Datum
TdsTypeSmallDatetimeToDatum(StringInfo buf)
{
	uint16	numDays, numMins;
	uint32	val;
	Timestamp	timestamp;

	val = (uint32)GetMsgInt(buf, 4);
	numMins = val >> 16;
	numDays = val & 0x0000ffff;

	TdsTimeGetDatumFromSmalldatetime(numDays, numMins, &timestamp);

	PG_RETURN_TIMESTAMP((uint64)timestamp);
}

/* Helper Function to convert Date value into Datum. */
Datum
TdsTypeDateToDatum(StringInfo buf)
{
	DateADT		result;
	uint64	val;
	result = (DateADT)GetMsgInt(buf, 3);
	TdsCheckDateValidity(result);

	TdsTimeGetDatumFromDays(result, &val);

	PG_RETURN_DATEADT(val);
}

/* Helper Function to convert Time value into Datum. */
Datum
TdsTypeTimeToDatum(StringInfo buf, int scale, int len)
{
	double		result = 0;
	uint64_t	numMicro = 0;

	/*
	 * if time data has no specific scale specified in the query, default scale
	 * to be considered is 7 always.
	 */
	if (scale == 255)
		scale = DATETIMEOFFSETMAXSCALE;

	memcpy(&numMicro, &buf->data[buf->cursor], len);
	buf->cursor += len;

	result = (double)numMicro;
	while (scale--)
		result /= 10;

	result *= 1000000;
	if (result < INT64CONST(0) || result > USECS_PER_DAY)
		ereport(ERROR,
		(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
		errmsg("time out of range")));


	PG_RETURN_TIMEADT((TimeADT)result);
}

/* Helper Function to convert Datetimeoffset value into Datum. */
Datum
TdsTypeDatetimeoffsetToDatum(StringInfo buf, int scale, int len)
{
	uint64_t 	numMicro = 0;
	uint32_t	numDays = 0;
	int16_t		timezone = 0;
	tsql_datetimeoffset *tdt = (tsql_datetimeoffset *) palloc0(DATETIMEOFFSET_LEN);
	TimestampTz	timestamp;
	/*
	 * if Datetimeoffset data has no specific scale specified in the query, default scale
	 * to be considered is 7 always.
	 */
	if (scale == 0xFF)
		scale = DATETIMEOFFSETMAXSCALE;

	memcpy(&numMicro, &buf->data[buf->cursor], len - 5);
	buf->cursor += len - 5;

	memcpy(&numDays, &buf->data[buf->cursor], 3);
	buf->cursor += 3;

	memcpy(&timezone, &buf->data[buf->cursor], 2);
	buf->cursor += 2;

	timezone *= -1;
	TdsGetTimestampFromDayTime(numDays, numMicro, (int)timezone, &timestamp, scale);

	timestamp -= (timezone * SECS_PER_MINUTE * USECS_PER_SEC);
	/* since reverse is done in tm2timestamp() */
	timestamp -= (timezone * USECS_PER_SEC);

	tdt->tsql_ts = timestamp;
	tdt->tsql_tz = timezone;

	PG_RETURN_DATETIMEOFFSET(tdt);
}

/* Helper Function to convert Money value into Datum. */
Datum
TdsTypeMoneyToDatum(StringInfo buf)
{
	uint64		high, low;
	uint64		val = GetMsgInt64(buf);

	high = val & 0xffffffff00000000;
	low = val & 0x00000000ffffffff;
	val = high >> 32 | low << 32;


	PG_RETURN_CASH((Cash)val);
}

/* Helper Function to convert Small Money value into Datum. */
Datum
TdsTypeSmallMoneyToDatum(StringInfo buf)
{
	uint64		val = 0;
	uint32		low = GetMsgInt(buf, 4);

	val = (uint64)low;

	PG_RETURN_CASH((Cash)val);
}

/* Helper Function to convert XML value into Datum. */
Datum
TdsTypeXMLToDatum(StringInfo buf)
{
	void    *result;
	char	   *str;
	int			nbytes;
	void	*doc;
	int			encoding = PG_UTF8;
	xmlChar *encodingStr = NULL;

	/*
	 * Read the data in raw format. We don't know yet what the encoding is, as
	 * that information is embedded in the xml declaration; so we have to
	 * parse that before converting to server encoding.
	 */
	nbytes = buf->len - buf->cursor;

	str = (char *)GetMsgBytes(buf, nbytes);

	/*
	 * We need a null-terminated string to pass to parse_xml_decl().  Rather
	 * than make a separate copy, make the temporary result one byte bigger
	 * than it needs to be.
	 */
	result = palloc0(nbytes + 1 + VARHDRSZ);
	SET_VARSIZE(result, nbytes + VARHDRSZ);
	memcpy(VARDATA(result), str, nbytes);
	str = VARDATA(result);
	str[nbytes] = '\0';

	/*
	 * TODO: handle the encoding list
	 * tds_parse_xml_decl((const char *) str, NULL, NULL, NULL, NULL);
	 * encoding = encodingStr ? xmlChar_to_encoding(encodingStr) : PG_UTF8;
	 */
	tds_parse_xml_decl((const xmlChar *)str, NULL, NULL, &encodingStr, NULL);
	encoding = encodingStr ? xmlChar_to_encoding(encodingStr) : TdsUTF16toUTF8XmlResult(buf, &result);

	/*
	 * Parse the data to check if it is well-formed XML data.  Assume that
	 * xml_parse will throw ERROR if not.
	 */
	doc = tds_xml_parse(result, XMLOPTION_CONTENT, true, encoding);
	tds_xmlFreeDoc(doc);

	PG_RETURN_XML_P(result);
}

/* Helper Function to convert UID value into Datum. */
Datum
TdsTypeUIDToDatum(StringInfo buf)
{
	pg_uuid_t  *uuid;

	/*
	 * Valid values for UUID are NULL or 16 byte value.
	 * NULL values are handled in the caller, so in the recv
	 * function we will only get 16 byte value
	 */
	Assert(buf->len == TDS_MAXLEN_UNIQUEIDENTIFIER);

	/* SWAP to match TSQL behaviour */
	SwapData(buf, buf->cursor + 0, buf->cursor + 3);
	SwapData(buf, buf->cursor + 1, buf->cursor + 2);
	SwapData(buf, buf->cursor + 4, buf->cursor + 5);
	SwapData(buf, buf->cursor + 6, buf->cursor + 7);

	uuid = (pg_uuid_t *) palloc(UUID_LEN);
	memcpy(uuid->data, GetMsgBytes(buf, UUID_LEN), UUID_LEN);

	PG_RETURN_POINTER(uuid);
}

StringInfo
TdsGetPlpStringInfoBufferFromToken(const char *message, const ParameterToken token)
{
	StringInfo pbuf;
	Plp plpHead = token->plp, temp;
	uint64_t len = 0;

	temp = plpHead;
	pbuf = makeStringInfo();

	/* data of zero length */
	if (temp == NULL)
		return pbuf;

	while(temp != NULL)
	{
		len += temp->len;
		temp = temp->next;
	}


	/*
	 * Explicitly calling enlargeStringInfo. This will save
	 * some overhead incase the data is very large and needs
	 * repalloc again and again
	 */
	enlargeStringInfo(pbuf, len);

	temp = plpHead;

	while (temp != NULL)
	{
		appendBinaryStringInfo(pbuf, &message[temp->offset], temp->len);
		temp = temp->next;
	}

	return pbuf;
}

StringInfo
TdsGetStringInfoBufferFromToken(const char *message, const ParameterToken token)
{
	StringInfo pbuf;

	const char *pvalue = &message[token->dataOffset];

	pbuf = palloc(sizeof(StringInfoData));
	/*
	 * Rather than copying data around, we just set up a phony
	 * StringInfo pointing to the correct portion of the TDS message
	 * buffer. 
	 */
	pbuf->data = (char *) pvalue;
	pbuf->maxlen = token->len;
	pbuf->len = token->len;
	pbuf->cursor = 0;

	return pbuf;
}

/* --------------------------------
 * TdsRevTypeBit	- converts external binary format to bool
 *
 * The external representation is one byte.  Any nonzero value is taken
 * as "true".
 * Function definition closely matches to get boolrecv
 * --------------------------------
 */
Datum
TdsRecvTypeBit(const char *message, const ParameterToken token)
{
	Datum res;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	res = TdsTypeBitToDatum(buf);

	pfree(buf);
	return res;
}

/* --------------------------------
 * TdsRecvTypeSmallInt - converts external binary format to int2
 * --------------------------------
 */
Datum
TdsRecvTypeTinyInt(const char *message, const ParameterToken token)
{
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);
	Datum res;

	res = TdsTypeIntegerToDatum(buf, sizeof(int8));

	pfree(buf);
	return res;
}

/* --------------------------------
 * TdsRecvTypeSmallInt - converts external binary format to int2
 * Function definition closely matches to int2recv
 * --------------------------------
 */
Datum
TdsRecvTypeSmallInt(const char *message, const ParameterToken token)
{
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);
	Datum res;

	res = TdsTypeIntegerToDatum(buf, sizeof(int16));

	pfree(buf);
	return res;
}

/* --------------------------------
 * TdsRecvTypeInteger - converts external binary format to int4
 * Function definition closely matches to int4recv
 * --------------------------------
 */
Datum
TdsRecvTypeInteger(const char *message, const ParameterToken token)
{
	Datum res;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	res = TdsTypeIntegerToDatum(buf, sizeof(int32));

	pfree(buf);
	return res;
}

/* --------------------------------
 * TdsRecvTypeBigInt - converts external binary format to int8
 * Function definition closely matches to int8recv
 * --------------------------------
 */
Datum
TdsRecvTypeBigInt(const char *message, const ParameterToken token)
{
	Datum res;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	res = TdsTypeIntegerToDatum(buf, sizeof(int64));

	pfree(buf);
	return res;
}

/* --------------------------------
 * TdsRecvTypeFloat4 - converts external binary format to float4
 * Function definition closely matches to float4recv
 * --------------------------------
 */
Datum
TdsRecvTypeFloat4(const char *message, const ParameterToken token)
{
	Datum res;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	res = TdsTypeFloatToDatum(buf, sizeof(float4));

	pfree(buf);
	return res;
}

/* --------------------------------
 * TdsRecvTypeFloat4 - converts external binary format to float8
 * Function definition closely matches to float8recv
 * --------------------------------
 */
Datum
TdsRecvTypeFloat8(const char *message, const ParameterToken token)
{
	Datum res;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	res = TdsTypeFloatToDatum(buf, sizeof(float8));

	pfree(buf);
	return res;
}

/* --------------------------------
 * TdsRecvTypeBinary - converts external binary format to byte data
 * --------------------------------
 */
Datum
TdsRecvTypeBinary(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	result = TdsTypeVarbinaryToDatum(buf);

	pfree(buf);
	return result;
}

/* --------------------------------
 * TdsRecvTypeVarbinary - converts external varbinary format to byte data
 * --------------------------------
 */
Datum
TdsRecvTypeVarbinary(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo      buf;

	if (token->maxLen == 0xffff)
		buf = TdsGetPlpStringInfoBufferFromToken(message, token);
	else
	{
		TDSInstrumentation(INSTR_TDS_DATATYPE_VARBINARY_MAX);

		buf = TdsGetStringInfoBufferFromToken(message, token);
	}

	result = TdsTypeVarbinaryToDatum(buf);

	if (token->maxLen == 0xffff)
		pfree(buf->data);

	pfree(buf);
	return result;
}

/* --------------------------------
 * TdsRecvTypeVarchar - converts external binary format to varchar
 *
 * Function defination closely matches to varcharrecv
 * --------------------------------
 */
Datum
TdsRecvTypeVarchar(const char *message, const ParameterToken token)
{
	StringInfo	buf;
	char 		csave;
	Datum 		pval;

	if (token->maxLen == 0xFFFF)
	{
		TDSInstrumentation(INSTR_TDS_DATATYPE_VARCHAR_MAX);

		buf = TdsGetPlpStringInfoBufferFromToken(message, token);
	}
	else
		buf = TdsGetStringInfoBufferFromToken(message, token);

	csave = buf->data[buf->len];
	buf->data[buf->len] = '\0';
	pval = TdsAnyToServerEncodingConversion(token->paramMeta.encoding,
									buf->data, buf->len, TDS_TYPE_VARCHAR);
	buf->data[buf->len] = csave;

	if (token->maxLen == 0xFFFF)
		pfree(buf->data);

	pfree(buf);
	return pval;
}

void
TdsReadUnicodeDataFromTokenCommon(const char *message, const ParameterToken token, StringInfo temp)
{
	StringInfo	buf;

	/*
	 * XXX: We reuse this code for extracting the query from the TDS request.  In
	 * some cases, the query is sent as non-unicode datatypes.  In those cases, the
	 * data can come as PLP.
	 */
	if ((token->type == TDS_TYPE_NVARCHAR || token->type == TDS_TYPE_VARCHAR) &&
		(token->maxLen == 0xFFFF))
		buf = TdsGetPlpStringInfoBufferFromToken(message, token);
	else
		buf = TdsGetStringInfoBufferFromToken(message, token);

	enlargeStringInfo(temp, buf->len);

	TdsUTF16toUTF8StringInfo(temp, buf->data, buf->len);

	if ((token->type == TDS_TYPE_NVARCHAR || token->type == TDS_TYPE_VARCHAR) &&
		(token->maxLen == 0xFFFF))
		pfree(buf->data);

	pfree(buf);
}

/* --------------------------------
 * TdsRecvTypeNVarchar - converts external binary format to varchar
 *
 * Function defination closely matches to varcharrecv
 * --------------------------------
 */
Datum
TdsRecvTypeNVarchar(const char *message, const ParameterToken token)
{
	void    *result;
	StringInfoData temp;

	if (token->maxLen == 0xFFFF)
		TDSInstrumentation(INSTR_TDS_DATATYPE_NVARCHAR_MAX);

	initStringInfo(&temp);

	TdsReadUnicodeDataFromTokenCommon(message, token, &temp);
	result = tds_varchar_input(temp.data, temp.len, -1);

	pfree(temp.data);

	PG_RETURN_VARCHAR_P(result);
}

Datum
TdsRecvTypeText(const char *message, const ParameterToken token)
{
	char        csave;
	Datum       pval;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	csave = buf->data[buf->len];
	buf->data[buf->len] = '\0';
	pval = TdsAnyToServerEncodingConversion(token->paramMeta.encoding, buf->data, buf->len,
									TDS_TYPE_TEXT);
	buf->data[buf->len] = csave;

	pfree(buf);
	return pval;
}

Datum
TdsRecvTypeNText(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	result = TdsTypeNCharToDatum(buf);

	pfree(buf);
	return result;
}

/* --------------------------------
 * TdsRecvTypeChar - converts external binary format to char
 *
 * Function defination closely matches to bpcharrecv
 * --------------------------------
 */
Datum
TdsRecvTypeChar(const char *message, const ParameterToken token)
{
	char        csave;
	Datum       pval;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	csave = buf->data[buf->len];
	buf->data[buf->len] = '\0';
	pval = TdsAnyToServerEncodingConversion(token->paramMeta.encoding, buf->data, buf->len, TDS_TYPE_CHAR);
	buf->data[buf->len] = csave;

	pfree(buf);
	return pval;
}

/* --------------------------------
 * TdsRecvTypeNChar - converts external binary format to nchar
 *
 * Function defination closely matches to bpcharrecv
 * --------------------------------
 */
Datum
TdsRecvTypeNChar(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	result = TdsTypeNCharToDatum(buf);

	pfree(buf);
	return result;
}

/*
  * TdsRecvTypeXml - convert extenal binary format to XML Datum
  * Function defination closely matches to xml_recv
  * XMLChar * is equivant to char *
  */
Datum
TdsRecvTypeXml(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo buf = TdsGetPlpStringInfoBufferFromToken(message, token);

	TDSInstrumentation(INSTR_TDS_DATATYPE_XML);

	result = TdsTypeXMLToDatum(buf);

	pfree(buf->data);
	pfree(buf);
	return result;
}

/* --------------------------------
 * TdsRecvTypeMoney - converts external binary format to UniqueIdentifier
 *
 * Function defination closely matches to uuid_recv
 * --------------------------------
 */
Datum
TdsRecvTypeUniqueIdentifier(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	result = TdsTypeUIDToDatum(buf);

	pfree(buf);
	return result;
}

/* --------------------------------
 * TdsRecvTypeMoney - converts external binary format to uint64 for
 * money data type
 * Function defination closely matches to cash_recv
 * --------------------------------
 */
Datum
TdsRecvTypeMoney(const char *message, const ParameterToken token)
{
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	uint64		high, low;
	uint64		val = GetMsgInt64(buf);

	TDSInstrumentation(INSTR_TDS_DATATYPE_MONEY);

	high = val & 0xffffffff00000000;
	low = val & 0x00000000ffffffff;
	val = high >> 32 | low << 32;

	pfree(buf);
	PG_RETURN_CASH((Cash)val);
}

/* --------------------------------
 * TdsRecvTypeSmallmoney - converts external binary format to uint64 for
 * Smallmoney data type
 * Function defination closely matches to cash_recv
 * --------------------------------
 */
Datum
TdsRecvTypeSmallmoney(const char *message, const ParameterToken token)
{
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	uint64		val = 0;
	uint32		low = GetMsgInt(buf, 4);

	TDSInstrumentation(INSTR_TDS_DATATYPE_SMALLMONEY);

	val = (uint64)low;
	pfree(buf);
	PG_RETURN_CASH((Cash)val);
}

/* --------------------------------
 * TdsRecvTypeSmalldatetime - converts external binary format to
 * Small Datetime data type
 * --------------------------------
 */
Datum
TdsRecvTypeSmalldatetime(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	result = TdsTypeSmallDatetimeToDatum(buf);

	pfree(buf);
	return result;
}

/* -------------------------------
 * TdsRecvTypeDate - converts external binary format to
 * Date  data type
 * --------------------------------
 */
Datum
TdsRecvTypeDate(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	result = TdsTypeDateToDatum(buf);

	pfree(buf);
	return result;
}

/* --------------------------------
 * TdsRecvTypeDatetime - converts external binary format to
 * Datetime data type
 * --------------------------------
 */
Datum
TdsRecvTypeDatetime(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);

	result = TdsTypeDatetimeToDatum(buf);

	pfree(buf);
	return result;
}

/* -------------------------------
 * TdsRecvTypeTime - converts external binary format to
 * Time data type
 * --------------------------------
 */
Datum
TdsRecvTypeTime(const char *message, const ParameterToken token)
{
	Datum 	result;
	int		scale = 0;
	StringInfo	buf = TdsGetStringInfoBufferFromToken(message, token);
	TdsColumnMetaData       col = token->paramMeta;
	scale = col.metaEntry.type6.scale;

	result = TdsTypeTimeToDatum(buf, scale, token->len);

	pfree(buf);
	return result;
}

Datum
TdsRecvTypeDatetime2(const char *message, const ParameterToken token)
{
	Datum 	result;
	int		scale = 0;
	StringInfo      buf = TdsGetStringInfoBufferFromToken(message, token);
	TdsColumnMetaData       col = token->paramMeta;

	scale = col.metaEntry.type6.scale;


	result = TdsTypeDatetime2ToDatum(buf, scale, token->len);

	pfree(buf);
	return result;
}

static inline uint128
StringToInteger(char *str)
{
	int i = 0, len = 0;
	uint128 num = 0;

	if (!str)
		return 0;

	len = strlen(str);

	for (	; i < len; i++)
		num = num * 10 + (str[i] - '0');

	return num;
}


/* --------------------------------
 * TdsRecvTypeNumeric - converts external binary format to numeric/decimal
 * Function definition closely matches to numeric_recv
 * --------------------------------
 */
Datum
TdsRecvTypeNumeric(const char *message, const ParameterToken token)
{
	Numeric		res;
	int		scale, len, sign;
	char		*decString, *wholeString;
	int		temp1, temp2;
	uint128		num = 0;
	TdsColumnMetaData	col = token->paramMeta;

	StringInfo buf = TdsGetStringInfoBufferFromToken(message, token);

	/* scale and precision are part of the type info */
	scale = col.metaEntry.type5.scale;

	/* fetch the sign from the actual data which is the first byte */
	sign = (uint8_t)GetMsgInt(buf, 1);

	/* fetch the data but ignore the sign byte now */
	{
		uint128		n128 = 0;

		if ((token->len - 1) > sizeof(n128))
			ereport(ERROR,
					(errcode(ERRCODE_PROTOCOL_VIOLATION),
						errmsg("Data length %d is invalid for NUMERIC/DECIMAL data types.",
								token->len)));

		memcpy(&n128, &buf->data[buf->cursor], token->len - 1);
		buf->cursor += token->len - 1;

		num = LEtoh128(n128);
	}

	decString = (char *)palloc0(sizeof(char) * 40);

	if (num != 0)
		Integer2String(num, decString);
	else
		decString[0] = '0';


	len = strlen(decString);
	temp1 = '.';

	/*
	 * If scale is more than length then we need to append zeros at the start;
	 * Since there is a '-' at the start of decString, we should ignore it before
	 * appending and then add it later.
	 */
	if (num != 0 && scale >= len)
	{
		int diff = scale - len + 1;
		char *zeros = palloc0(sizeof(char) * diff + 1);
		char *tempString = decString;
		while(diff)
		{
			zeros[--diff] = '0';
		}
		/*
		 * Add extra '.' character in psprintf; Later we make use of
		 * this index during shifting the scale part of the string.
		 */
		decString = psprintf("-%s%s.", zeros, tempString + 1);
		len = strlen(decString) - 1;
		pfree(tempString);
	}
	if (num != 0)
	{
		while (scale)
		{
			temp2 = decString[len - scale];
			decString[len - scale] = temp1;
			temp1 = temp2;
			scale--;
		}
		decString[len++] = temp1;
	}
	else
	{
		decString[len++] = temp1;
		while (scale)
		{
			decString[len++] = '0';
			scale--;
		}
	}
	/*
	 * We use wholeString just to free the address at decString later,
	 * since it gets updated later.
	 */
	wholeString = decString;

	if (sign == 1 && num != 0)
		decString++;

	res = TdsSetVarFromStrWrapper(decString);

	if (wholeString)
		pfree(wholeString);
	if (buf)
		pfree(buf);
	PG_RETURN_NUMERIC(res);
}

/* --------------------------------
 * TdsRecvTypeTable - creates a temp-table from the data being recevied on the wire
 * and sends this temp-table's name to the engine.
 * --------------------------------
 */
Datum
TdsRecvTypeTable(const char *message, const ParameterToken token)
{
	char * tableName;
	char * query;
	StringInfo temp;
	int rc;
	TvpRowData *row = token->tvpInfo->rowData;
	TvpColMetaData *colMetaData = token->tvpInfo->colMetaData;
	bool xactStarted = IsTransactionOrTransactionBlock();
	char *finalTableName;
	TvpLookupItem *item; 
	temp = palloc(sizeof(StringInfoData));
	initStringInfo(temp);

	TDSInstrumentation(INSTR_TDS_DATATYPE_TABLE_VALUED_PARAMETER);

	 /* Setting a unique name for TVP temp table. */
	tableName = psprintf("%s_TDS_TVP_TEMP_TABLE_%d", token->tvpInfo->tableName, rand());

	/*
	 * We change the dialect to postgres to create temp tables
	 * and execute a prep/exec insert query via SPI.
	 */
	set_config_option("babelfishpg_tsql.sql_dialect", "postgres",
						  (superuser() ? PGC_SUSET : PGC_USERSET),
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

	/* Connect to the SPI manager. */
	if ((rc = SPI_connect()) < 0)
		elog(ERROR, "SPI_connect() failed in TDS Listener "
					"with return code %d", rc);

	if (!xactStarted)
		StartTransactionCommand();
	PushActiveSnapshot(GetTransactionSnapshot()); 



	query = psprintf("CREATE TEMPORARY TABLE IF NOT EXISTS %s (like %s including all)",
		tableName, token->tvpInfo->tvpTypeName);


	/*
	 * If table with the same name already exists, we should just use that table
	 * and ignore the NOTICE of "relation already exists, skipping".
	 */
	rc = SPI_execute(query, false, 1);

	if (rc != SPI_OK_UTILITY)
		elog(ERROR, "Failed to create the underlying table for table-valued parameter: %d", rc);

	SPI_finish();
	PopActiveSnapshot();
	if (!xactStarted)
		CommitTransactionCommand();

	{
		char *src;
		int nargs = token->tvpInfo->colCount * token->tvpInfo->rowCount;
		Datum *values = palloc(nargs * sizeof(Datum));
		char *nulls = palloc(nargs * sizeof(char));
		Oid *argtypes= palloc(nargs * sizeof(Datum));
		int i = 0;
		query = " ";

		if (!xactStarted)
			StartTransactionCommand();
		PushActiveSnapshot(GetTransactionSnapshot());

		while (row) /* Create the prep/exec query to insert the rows. */
		{
			TdsIoFunctionInfo tempFuncInfo;
			int currentColumn = 0;
			char *currentQuery = " ";

			while(currentColumn != token->tvpInfo->colCount)
			{
				temp = &(row->columnValues[currentColumn]);
				tempFuncInfo = TdsLookupTypeFunctionsByTdsId(colMetaData[currentColumn].columnTdsType, colMetaData[currentColumn].maxLen);
				GetPgOid(argtypes[i], tempFuncInfo);
				if (row->isNull[currentColumn] == 'n')
					nulls[i] = row->isNull[currentColumn];
				else
					switch(colMetaData[currentColumn].columnTdsType)
					{
						case TDS_TYPE_CHAR:
						case TDS_TYPE_VARCHAR:
							values[i] = TdsTypeVarcharToDatum(temp, colMetaData[currentColumn].encoding, colMetaData[currentColumn].columnTdsType);
						break;
						case TDS_TYPE_NCHAR:
							values[i] = TdsTypeNCharToDatum(temp);
						break;
						case TDS_TYPE_NVARCHAR:
							if (!row->isNull[currentColumn]) /* NULL. */
								currentQuery = psprintf("%s,\'NULL\'", currentQuery);
							else
								currentQuery = psprintf("%s,\'%s\'", currentQuery, temp->data);
							nargs--;
						break;
						case TDS_TYPE_INTEGER:
						case TDS_TYPE_BIT:
							values[i] = TdsTypeIntegerToDatum(temp, colMetaData[currentColumn].maxLen);
						break;
						case TDS_TYPE_FLOAT:
							values[i] = TdsTypeFloatToDatum(temp, colMetaData[currentColumn].maxLen);
						break;
						case TDS_TYPE_NUMERICN:
						case TDS_TYPE_DECIMALN:
							values[i] = TdsTypeNumericToDatum(temp, colMetaData[currentColumn].scale);
						break;
						case TDS_TYPE_VARBINARY:
						case TDS_TYPE_BINARY:
							values[i] = TdsTypeVarbinaryToDatum(temp);
							argtypes[i] = tempFuncInfo->ttmtypeid;
						break;
						case TDS_TYPE_DATE:
							values[i] = TdsTypeDateToDatum(temp);
						break;
						case TDS_TYPE_TIME:
							values[i] = TdsTypeTimeToDatum(temp, colMetaData[currentColumn].scale, temp->len);
						break;
						case TDS_TYPE_DATETIMEOFFSET:
							values[i] = TdsTypeDatetimeoffsetToDatum(temp, colMetaData[currentColumn].scale, temp->len);
						break;
						case TDS_TYPE_DATETIME2:
							values[i] = TdsTypeDatetime2ToDatum(temp, colMetaData[currentColumn].scale, temp->len);
						break;
						case TDS_TYPE_DATETIMEN:
							values[i] = TdsTypeDatetimeToDatum(temp);
						break;
						case TDS_TYPE_MONEYN:
							values[i] = TdsTypeMoneyToDatum(temp);
						break;
						case TDS_TYPE_XML:
							values[i] = TdsTypeXMLToDatum(temp);
						break;
						case TDS_TYPE_UNIQUEIDENTIFIER:
							values[i] = TdsTypeUIDToDatum(temp);
						break;
						case TDS_TYPE_SQLVARIANT:
							values[i] = TdsTypeSqlVariantToDatum(temp);
						break;
					}
				/* Build a string for bind parameters. */
				if (colMetaData[currentColumn].columnTdsType != TDS_TYPE_NVARCHAR || row->isNull[currentColumn] == 'n')
				{
					currentQuery = psprintf("%s,$%d", currentQuery, i + 1);
					i++;
				}
				currentColumn++;
			}
			row = row->nextRow;
			currentQuery[1] = ' '; /* Convert the first ',' into a blank space. */

			/* Add each row values in a single insert query so that we call SPI only once. */
			query = psprintf("%s,(%s)", query, currentQuery);
		}

		if (token->tvpInfo->rowData) /* If any row in TVP */
		{
			query[1] = ' '; /* Convert the first ',' into a blank space. */

			src = psprintf("Insert into %s values %s", tableName, query);
			if ((rc = SPI_connect()) < 0)
				elog(ERROR, "SPI_connect() failed in TDS Listener "
							"with return code %d", rc);

			rc = SPI_execute_with_args(src,
				  nargs, argtypes,
				  values, nulls,
				  false, 1);

			if (rc != SPI_OK_INSERT)
				elog(ERROR, "Failed to insert in the underlying table for table-valued parameter: %d", rc);

			SPI_finish();
			PopActiveSnapshot();
			if (!xactStarted)
				CommitTransactionCommand();
		}

		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
								(superuser() ? PGC_SUSET : PGC_USERSET),
									PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}

	/* Free all the pointers. */
	while (token->tvpInfo->rowData)
	{
		TvpRowData *tempRow = token->tvpInfo->rowData;
		token->tvpInfo->rowData = token->tvpInfo->rowData->nextRow;
		pfree(tempRow);
	}
	pfree(token->tvpInfo->colMetaData);

	finalTableName = downcase_truncate_identifier(tableName, strlen(tableName), true);

	item = (TvpLookupItem *) palloc(sizeof(TvpLookupItem));
	item->name = downcase_truncate_identifier(token->paramMeta.colName.data,
			strlen(token->paramMeta.colName.data),
			true);
	item->tableRelid = InvalidOid;
	item->tableName = finalTableName;
	tvp_lookup_list = lappend(tvp_lookup_list, item);

	PG_RETURN_CSTRING(finalTableName);
}

/* TdsRecvTypeSqlvariant - converts external binary format to byte data
 * based on sqlvariant base type
 * --------------------------------
 */
Datum
TdsRecvTypeSqlvariant(const char *message, const ParameterToken token)
{
	Datum result;
	StringInfo      buf = TdsGetStringInfoBufferFromToken(message, token);

	TDSInstrumentation(INSTR_TDS_DATATYPE_SQLVARIANT);

	result = TdsTypeSqlVariantToDatum(buf);

	pfree(buf);
	return result;
}

int
TdsSendTypeBit(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = 0;
	int8_t		out = DatumGetBool(value);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(sizeof(out));

	if (rc == 0)
		rc = TdsPutInt8(out);
	return rc;
}

int
TdsSendTypeTinyint(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = 0;
	int8_t		out = DatumGetUInt8(value);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(sizeof(out));

	if (rc == 0)
		rc = TdsPutInt8(out);
	return rc;
}
int
TdsSendTypeSmallint(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = 0;
	int16_t		out = DatumGetInt16(value);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(sizeof(out));

	if (rc == 0)
		rc = TdsPutInt16LE(out);
	return rc;
}

int
TdsSendTypeInteger(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = 0;
	int32_t		out = DatumGetInt32(value);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(sizeof(out));

	if (rc == 0)
		rc = TdsPutInt32LE(out);
	return rc;
}

int
TdsSendTypeBigint(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = 0;
	int64_t		out = DatumGetInt64(value);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(sizeof(out));

	if (rc == 0)
		rc = TdsPutInt64LE(out);
	return rc;
}

int
TdsSendTypeFloat4(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = 0;
	float4		out = DatumGetFloat4(value);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(sizeof(out));

	if (rc == 0)
		rc = TdsPutFloat4LE(out);
	return rc;
}

int
TdsSendTypeFloat8(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = 0;
	float8		out = DatumGetFloat8(value);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(sizeof(out));

	if (rc == 0)
		rc = TdsPutFloat8LE(out);
	return rc;
}

static int
TdsSendPlpDataHelper(char *data, int len)
{
	int 			rc;
	uint32_t		plpTerminator = PLP_TERMINATOR;
	uint64_t		tempOffset = 0;
	uint32_t		plpChunckLen = PLP_CHUNCK_LEN;

	if ((rc = TdsPutInt64LE(len)) == 0)
	{
		while (true)
		{
			if (plpChunckLen > (len - tempOffset))
				plpChunckLen = (len - tempOffset);

			// Either data is "0" or no more data to send
			if (plpChunckLen == 0)
				break;

			// need testing for "0" len
			if ((rc = TdsPutUInt32LE(plpChunckLen)) == 0)
			{
				TdsPutbytes(&(data[tempOffset]), plpChunckLen);
			}
			if (rc != 0)
				return rc;

			tempOffset += plpChunckLen;
			Assert(tempOffset <= len);
		}
		rc |= TdsPutInt32LE(plpTerminator);
	}

	return rc;
}

int
TdsSendTypeXml(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc;
	char			*out = OutputFunctionCall(finfo, value);
	StringInfoData      	buf;

	/*
	 * If client being connected is using TDS version lower than or equal to 7.1
	 * then TSQL treats XML as NText.
	 */
	if (GetClientTDSVersion() <= TDS_VERSION_7_1_1)
		return TdsSendTypeNText(finfo, value, vMetaData);

	TDSInstrumentation(INSTR_TDS_DATATYPE_XML);

	initStringInfo(&buf);
	TdsUTF8toUTF16StringInfo(&buf, out, strlen(out));

	rc = TdsSendPlpDataHelper(buf.data, buf.len);
	
	pfree(buf.data);

	return rc;
}

int
TdsSendTypeBinary(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = EOF,maxLen = 0;
	bytea			*vlena = DatumGetByteaPCopy(value);
	bytea			*buf;
	TdsColumnMetaData	*col = (TdsColumnMetaData *)vMetaData;

	maxLen = col->metaEntry.type7.maxSize;
	buf = (bytea *)palloc0(sizeof(bytea) * maxLen);
	memcpy(buf, VARDATA_ANY(vlena), VARSIZE_ANY_EXHDR(vlena));

	if ((rc = TdsPutUInt16LE(maxLen)) == 0)
		TdsPutbytes(buf, maxLen);
	
	pfree(buf);
	return rc;
}

int
TdsSendTypeVarchar(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int 			rc = EOF,
				len,		/* number of bytes used to store the string. */
				actualLen,	/* Number of bytes that would be needed to store given string in given encoding. */
				maxLen;		/* max size of given column in bytes */
	char 			*destBuf, *buf = OutputFunctionCall(finfo, value);
	TdsColumnMetaData	*col = (TdsColumnMetaData *)vMetaData;

	len = strlen(buf);

	destBuf = TdsEncodingConversion(buf, len, PG_UTF8, col->encoding, &actualLen);
	maxLen = col->metaEntry.type2.maxSize;

	if (maxLen != 0xffff)
	{
		if (unlikely(actualLen > maxLen))
			elog(ERROR, "Number of bytes for the field of varchar(n) exeeds max specified for the field.");

		if ((rc = TdsPutInt16LE(actualLen)) == 0)
			rc = TdsPutbytes(destBuf, actualLen);
	}
	else
	{
		/* We can store upto 2GB (2^31 - 1 bytes) for the varchar(max). */ 
		if (unlikely(actualLen > VARCHAR_MAX))
			elog(ERROR, "Number of bytes required for the field of varchar(max) exeeds 2GB");
		TDSInstrumentation(INSTR_TDS_DATATYPE_VARCHAR_MAX);

		rc = TdsSendPlpDataHelper(destBuf, actualLen);
	}

	pfree(buf);
	return rc;
}

int
TdsSendTypeChar(FmgrInfo *finfo, Datum value, void *vMetaData)
{	
	int			rc = EOF,
				maxLen,		/* max size of given column in bytes */
				actualLen,	/* Number of bytes that would be needed to store given string in given encoding. */
				len;		/* number of bytes used to store the string. */
	char			*destBuf, *buf = OutputFunctionCall(finfo, value);
	TdsColumnMetaData	*col = (TdsColumnMetaData *)vMetaData;

	len = strlen(buf);

	destBuf = TdsEncodingConversion(buf, len, PG_UTF8, col->encoding, &actualLen);
	maxLen = col->metaEntry.type2.maxSize;

	if (unlikely(maxLen != actualLen))
		elog(ERROR, "Number of bytes required for the field of char(n) does not match with max bytes specified of the field");

	if ((rc = TdsPutUInt16LE(actualLen)) == 0)
		rc = TdsPutbytes(destBuf, actualLen);

	pfree(buf);
	return rc;
}

int
TdsSendTypeVarbinary(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = EOF, len = 0, maxlen = 0;
	bytea			*vlena = DatumGetByteaPCopy(value);
	char			*buf = VARDATA_ANY(vlena);
	TdsColumnMetaData	*col = (TdsColumnMetaData *)vMetaData;

	maxlen = col->metaEntry.type7.maxSize;
	len = VARSIZE_ANY_EXHDR(vlena);

	if (maxlen != 0xffff)
	{
		if ((rc = TdsPutInt16LE(len)) == 0)
			TdsPutbytes(buf, len);
	}
	else
	{
		TDSInstrumentation(INSTR_TDS_DATATYPE_VARBINARY_MAX);

		rc = TdsSendPlpDataHelper(buf, len);
	}
        return rc;
}

static inline void
SendTextPtrInfo(void)
{
	/*
	 * For now, we are sending dummy data for textptr and texttimestamp
	 * TODO: Once the engine supports TEXTPTR, TIMESTAMP - BABEL-260,
	 * query & send the actual values
	 */
	uint8_t                         temp = 16;
	char textptr[] = {0x64, 0x75, 0x6d, 0x6d, 0x79, 0x20, 0x74, 0x65, 0x78, 0x74,
				0x70, 0x74, 0x72, 0x00, 0x00, 0x00};
	char texttimestamp[] = { 0x64, 0x75, 0x6d, 0x6d, 0x79, 0x54, 0x53, 0x00};

	TdsPutUInt8(temp);

	TdsPutbytes(textptr, sizeof(textptr));
	TdsPutbytes(texttimestamp, sizeof(texttimestamp));
}

int
TdsSendTypeText(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int					rc;
	uint32_t			len;
	char			   	*destBuf, *buf = OutputFunctionCall(finfo, value);
	TdsColumnMetaData	*col = (TdsColumnMetaData *)vMetaData;
	int					encodedByteLen;

	SendTextPtrInfo();

	len = strlen(buf);
	destBuf = TdsEncodingConversion(buf, len, PG_UTF8, col->encoding, &encodedByteLen);

	if ((rc = TdsPutUInt32LE(encodedByteLen)) == 0)
		rc = TdsPutbytes(destBuf, encodedByteLen);

	pfree(buf);
	return rc;
}

int
TdsSendTypeImage(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int			rc = EOF, len;
	bytea			*vlena = DatumGetByteaPCopy(value);
	char			*buf = VARDATA(vlena);

	TDSInstrumentation(INSTR_TDS_DATATYPE_IMAGE);

	SendTextPtrInfo();

	len = VARSIZE_ANY_EXHDR(vlena);

	if ((rc = TdsPutUInt32LE(len)) == 0)
		TdsPutbytes(buf, len);
	return rc;
}

int
TdsSendTypeNText(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int					rc;
	char			   *out = OutputFunctionCall(finfo, value);
	StringInfoData      buf;

	SendTextPtrInfo();

	initStringInfo(&buf);
	TdsUTF8toUTF16StringInfo(&buf, out, strlen(out));

	/*
	 * TODO: Enable below check: BABEL-298
	 * This is a special case we are making for TDS clients. TSQL treats
	 * on-the-wire data really as UCS2, not UTF16. While we try our best
	 * to detect possible problems on input, the special rules about
	 * truncating trailing spaces allow to enter data that exceeds the
	 * number of 16-bit units to be sent here. In a best effort approach
	 * we strip extra spaces here. The FATAL error will never happen
	 * if the input rules are correct.
	 */
	/*while (buf.len > 0 && buf.len > col->metaEntry.type2.maxSize)
	{
		if (buf.data[buf.len - 2] != ' ' || buf.data[buf.len - 1] != '\0')
			elog(FATAL, "UTF16 output of varchar/bpchar exceeds max length");
		buf.len -= 2;
	}*/
	if ((rc = TdsPutUInt32LE(buf.len)) == 0)
		TdsPutbytes(buf.data, buf.len);

	pfree(buf.data);
	return rc;
}

int
TdsSendTypeNVarchar(FmgrInfo *finfo, Datum value, void *vMetaData)
{

	int			rc, maxlen;
	char			*out = OutputFunctionCall(finfo, value);
	TdsColumnMetaData	*col = (TdsColumnMetaData *)vMetaData;
	StringInfoData		buf;

	initStringInfo(&buf);
	TdsUTF8toUTF16StringInfo(&buf, out, strlen(out));
	maxlen = col->metaEntry.type2.maxSize;

	if (maxlen != 0xffff)
	{
		
		/*
		 * This is a special case we are making for TDS clients. TSQL treats
		 * on-the-wire data really as UCS2, not UTF16. While we try our best
	 	 * to detect possible problems on input, the special rules about
	 	 * truncating trailing spaces allow to enter data that exceeds the
	 	 * number of 16-bit units to be sent here. In a best effort approach
	 	 * we strip extra spaces here. The FATAL error will never happen
	 	 * if the input rules are correct.
	 	 */
		while (buf.len > 0 && buf.len > col->metaEntry.type2.maxSize)
		{
			if (buf.data[buf.len - 2] != ' ' || buf.data[buf.len - 1] != '\0')
				elog(FATAL, "UTF16 output of varchar/bpchar exceeds max length");
			buf.len -= 2;
		}
		if ((rc = TdsPutInt16LE(buf.len)) == 0)
			TdsPutbytes(buf.data, buf.len);
	}
	else
	{
		TDSInstrumentation(INSTR_TDS_DATATYPE_NVARCHAR_MAX);

		rc = TdsSendPlpDataHelper(buf.data, buf.len);
	}

        pfree(buf.data);
	return rc;
}

int
TdsSendTypeNChar(FmgrInfo *finfo, Datum value, void *vMetaData)
{

	int			rc, len;
	char			*out = OutputFunctionCall(finfo, value);
	TdsColumnMetaData	*col = (TdsColumnMetaData *)vMetaData;
	StringInfoData		buf;

	initStringInfo(&buf);
	TdsUTF8toUTF16StringInfo(&buf, out, strlen(out));

	/*
	 * This is a special case we are making for TDS clients. TSQL treats
	 * on-the-wire data really as UCS2, not UTF16. While we try our best
	 * to detect possible problems on input, the special rules about
	 * truncating trailing spaces allow to enter data that exceeds the
	 * number of 16-bit units to be sent here. In a best effort approach
	 * we strip extra spaces here. The FATAL error will never happen
	 * if the input rules are correct.
	 */
	while (buf.len > 0 && buf.len > col->metaEntry.type2.maxSize)
	{
		if (buf.data[buf.len - 2] != ' ' || buf.data[buf.len - 1] != '\0')
			elog(FATAL, "UTF16 output of varchar/bpchar exceeds max length");
		buf.len -= 2;
	}

	/*
	 * Add explicit padding, Otherwise can give garbage in some cases.
	 * This code needs to be removed and padding should be handled
	 * internally - BABEL-273
	 */
	len = buf.len;
	while (len < col->metaEntry.type2.maxSize)
	{
		appendStringInfoChar(&buf, 0x20);
		appendStringInfoChar(&buf, 0x00);
		len += 2;
	}

	len = col->metaEntry.type2.maxSize;	

	if ((rc = TdsPutInt16LE(len)) == 0)
		TdsPutbytes(buf.data, len);
	pfree(buf.data);

	return rc;
}

int
TdsSendTypeMoney(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int rc = 0, length = 8;
	uint32 low = 0, high = 0;
	uint64 out = DatumGetUInt64(value);

	TDSInstrumentation(INSTR_TDS_DATATYPE_MONEY);

	low = out & 0xffffffff;
	high = (out >> 32) & 0xffffffff;

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(length);

	if (rc == 0)
	{
		rc = TdsPutUInt32LE(high);
		rc |= TdsPutUInt32LE(low);
	}
	return rc;
}

int
TdsSendTypeSmallmoney(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int rc = 0, length = 4;
	uint32 low = 0, high = 0;
	uint64 out = DatumGetUInt64(value);

	TDSInstrumentation(INSTR_TDS_DATATYPE_SMALLMONEY);

	low = out & 0xffffffff;
	high = (out >> 32) & 0xffffffff;
	if (high != 0xffffffff && high != 0)
	{
		ereport(ERROR,(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
		errmsg("SMALLMONEY exceeds permissible range of 4 bytes!")));
		return EOF;
	}

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(length);

	if (rc == 0)
		rc = TdsPutUInt32LE(low);
	return rc;
}

int
TdsSendTypeSmalldatetime(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int rc = 0, length = 4;
	uint16 numDays = 0, numMins = 0;

	TdsTimeDifferenceSmalldatetime(value, &numDays, &numMins);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(length);

	if (rc == 0)
	{
		rc = TdsPutUInt16LE(numDays);
		rc |= TdsPutUInt16LE(numMins);
	}
	return rc;
}

int
TdsSendTypeDate(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int rc = 0, length = 3;
	uint32 numDays = 0;

	if (GetClientTDSVersion() < TDS_VERSION_7_3_A)
		/*
		 * If client being connected is using TDS version lower than 7.3A
		 * then TSQL treats DATE as NVARCHAR.
		 */
		return TdsSendTypeNVarchar(finfo, value, vMetaData);

	numDays = TdsDayDifference(value);

	if ((rc = TdsPutInt8(length)) == 0)
		rc = TdsPutDate(numDays);
	return rc;
}

int
TdsSendTypeDatetime(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int rc = 0, length = 8;
	uint32 numDays = 0, numTicks = 0;

	TdsTimeDifferenceDatetime(value, &numDays, &numTicks);

	/* Don't send the length if the column type is not null. */
	if (!((TdsColumnMetaData *)vMetaData)->attNotNull)
		rc = TdsPutInt8(length);

	if (rc == 0)
	{
		rc = TdsPutUInt32LE(numDays);
		rc |= TdsPutUInt32LE(numTicks);
	}
	return rc;
}

/*
 * TdsSendTypeNumeric() formats  response for numeric
 * data in TDS listener side before writing it to wire.
 * Based on numeric prescision, TdsSendTypeNumeric()  generates
 * 4-16 byte data followed by data length and sign bytes and writes to wire.
 */
int
TdsSendTypeNumeric(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int	rc = EOF, precision = 0, scale = -1;
	uint8	sign = 1, length = 0;
	char	*out, *decString;
	uint128	num = 0;
	TdsColumnMetaData  *col = (TdsColumnMetaData *)vMetaData;
	uint8_t max_scale = col->metaEntry.type5.scale;
	uint8_t max_precision = col->metaEntry.type5.precision;

	out = OutputFunctionCall(finfo, value);
	if (out[0] == '-')
	{
		sign = 0;
		out++;
	}
	if (out[0] == '0')
		out++;
	/*
	 *  response string is formatted to obtain string representation
	 * of TDS unsigned integer along with its precision and scale
	 */
	decString = (char *)palloc(sizeof(char) * (strlen(out) + 1));
	/* While there is still digit in out and we haven't reached max_scale */
	while (*out && scale < max_scale)
	{
		if (*out == '.')
		{
			out++;
			/* Start counting scale */
			scale = 0;
			continue;
		}
		decString[precision++] = *out;
		out++;
		if (scale >= 0)
			scale++;
	}

	/* done scanning and haven't seen the decimal point, set scale to 0 */
	if (scale == -1)
		scale = 0;

	/*
	 * Fill in the remaining 0's if the processed scale from out is less than max_scale
	 * This is needed because the output generated by engine may not always
	 * produce the same precision/scale as calculated by resolve_numeric_typmod_from_exp,
	 * which is the precision/scale we have sent to the client with column metadata.
	 */
	while (scale++ < max_scale)
	{
		decString[precision++] = '0';
	}
	decString[precision] = '\0';

	if (precision > TDS_MAX_NUM_PRECISION ||
		precision > max_precision)
		ereport(ERROR, (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				errmsg("Arithmetic overflow error for data type numeric.")));

	if (precision >= 1 && precision < 10)
		length = 4;
	else if (precision < 20)
		length = 8;
	else if (precision < 29)
		length = 12;
	else if (precision < 39)
		length = 16;

	num = StringToInteger(decString);
	if (TdsPutInt8(length + 1) == 0 && TdsPutInt8(sign) == 0)
		rc = TdsPutbytes(&num, length);

	pfree(decString);
	return rc;
}

static void
SwapData(StringInfo buf, int st, int end)
{
	char		tempswap;

	if (buf->len < end || st > end)
		return;

	tempswap = buf->data[st];
	buf->data[st] = buf->data[end];
	buf->data[end] = tempswap;
}

int
TdsSendTypeUniqueIdentifier(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	pg_uuid_t  *uuid = DatumGetUUIDP(value);
	int			rc;
	StringInfoData buf;

	initStringInfo(&buf);
	resetStringInfo(&buf);
	appendBinaryStringInfo(&buf, (char *) uuid->data, UUID_LEN);

	/* SWAP to match TSQL behaviour */
	SwapData(&buf, 0, 3);
	SwapData(&buf, 1, 2);
	SwapData(&buf, 4, 5);
	SwapData(&buf, 6, 7);

	if ((rc = TdsPutInt8(UUID_LEN)) == 0)
		TdsPutbytes(buf.data, UUID_LEN);

	pfree(buf.data);
	return rc;
}

int
TdsSendTypeTime(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int		rc = EOF, length = 0, scale = 0;
	uint64_t	res = 0;
	double		numSec = 0;
	TdsColumnMetaData  *col = (TdsColumnMetaData *)vMetaData;

	if (GetClientTDSVersion() < TDS_VERSION_7_3_A)
		/*
		 * If client being connected is using TDS version lower than 7.3A
		 * then TSQL treats TIME as NVARCHAR.
		 */
		return TdsSendTypeNVarchar(finfo, value, vMetaData);

	scale = col->metaEntry.type6.scale;

	/*
	 * if time data has no specific scale specified in the query, default scale
	 * to be considered is 7 always.
	 */
	if (scale == 255)
		scale = DATETIMEOFFSETMAXSCALE;

	if (scale >= 0 && scale < 3)
		length = 3;
	else if (scale >= 3 && scale < 5)
		length = 4;
	else if (scale >= 5 && scale <= 7)
		length = 5;

	numSec = (double)value / 1000000;
	while (scale--)
		numSec *= 10;
	/* Round res to the nearest integer */
	numSec += 0.5;

	res = (uint64_t)numSec;
	if ((rc = TdsPutInt8(length)) == 0)
		rc = TdsPutbytes(&res, length);
	return rc;
}

int
TdsSendTypeDatetime2(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int		rc = EOF, length = 0, scale = 0;
	uint64		numSec = 0;
	uint32		numDays = 0;
	TdsColumnMetaData  *col = (TdsColumnMetaData *)vMetaData;

	if (GetClientTDSVersion() < TDS_VERSION_7_3_A)
		/*
		 * If client being connected is using TDS version lower than 7.3A
		 * then TSQL treats DATETIME2 as NVARCHAR.
		 */
		return TdsSendTypeNVarchar(finfo, value, vMetaData);

	scale = col->metaEntry.type6.scale;
	/*
	 * if Datetime2 data has no specific scale specified in the query, default scale
	 * to be considered is 7 always.
	 */
	if (scale == 255)
		scale = DATETIMEOFFSETMAXSCALE;

	if (scale >= 0 && scale < 3)
		length = 6;
	else if (scale >= 3 && scale < 5)
		length = 7;
	else if (scale >= 5 && scale <= 7)
		length = 8;

	TdsGetDayTimeFromTimestamp((Timestamp)value, &numDays,
					&numSec, scale);

	if (TdsPutInt8(length) == 0 &&
	    TdsPutbytes(&numSec, length - 3) == 0)
		rc = TdsPutDate(numDays);

	return rc;
}

static void
SwapByte(char *buf, int st, int end)
{
	char temp = buf[st];
	buf[st] = buf[end];
	buf[end] = temp;
}

/* Helper Function to convert SQL_VARIANT value into Datum. */
Datum
TdsTypeSqlVariantToDatum(StringInfo buf)
{
	bytea           *result = 0;
	uint8		variantBaseType = 0;
	int		pgBaseType = 0;
	int             dataLen = 0, i = 0, len = 0;
	int		tempScale = 0, tempLen = 0;
	int		variantHeaderLen = 0, maxLen = 0, resLen = 0;
	uint8_t		scale = 0, precision = 0, sign = 1, temp = 0;		  
	DateADT		date = 0;
	uint64		numMicro = 0, dateval = 0;
	uint16		numDays = 0, numMins = 0;
	int16		timezone = 0;
        uint32		numDays32 = 0, numTicks = 0; 
	Timestamp	timestamp = 0;
	TimestampTz	timestamptz = 0;
	Numeric		res = 0;
	char		*decString, temp1, temp2;
	uint128         n128 = 0, num = 0;
	StringInfoData	strbuf;
        tsql_datetimeoffset *tdt = (tsql_datetimeoffset *) palloc0(DATETIMEOFFSET_LEN);

	variantBaseType = buf->data[0];
	tempLen = buf->len - buf->cursor;

	pltsql_plugin_handler_ptr->sqlvariant_get_pg_base_type(variantBaseType, &pgBaseType,
							tempLen, &dataLen, &variantHeaderLen);

	/*
	 * Header formats:
	 *
	 *	3-byte Header (for datetime series types with typmod):
	 *		1. One byte varlena Header
	 *		2. One byte type code (5bit) + MD ver (3bit)
	 *		3. One byte scale
	 *
	 *	2-byte Header (for fixed length types without typmod):
	 *		1. One byte varlena Header
	 * 		2. One byte type code (5bit) + MD ver (3bit)
	 *
	 *	4-byte Header (for decimal type):
	 *		1. One byte varlena Header
	 *		2. One byte type code (5bit) + MD ver (3bit)
	 *		3. Two bytes typmod (encoded precision and scale)
	 *
	 *	Header for binary types:
	 *		1. 1 or 4 bytes varlena header
	 *		2. One byte type code ( 5bit ) + MD ver (3bit)
	 *		3. 2 Bytes max length
	 *
	 *	Header for string types:
	 *		1. 1 or 4 bytes varlena Header
	 *		2. One byte type code (5bit) + MD ver (3bit)
	 *		3. Two bytes for max length
	 * 		4. Two bytes for collation code
	 */
  
	/*
	 * If base type is N[VAR]CHAR then we have to use length of data in UTF8 format as datalen.
	 */
	if (variantBaseType == VARIANT_TYPE_NCHAR ||
		variantBaseType == VARIANT_TYPE_NVARCHAR)
	{
		/*
		 * dataformat: totalLen(4B) + metadata(9B)( baseType(1B) + metadatalen(1B) +
		 *	encodingLen(5B) + dataLen(2B) ) + data(dataLen)
		 * Data is in UTF16 format.
		 */
		initStringInfo(&strbuf);
		TdsUTF16toUTF8StringInfo(&strbuf, &buf->data[VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES], tempLen - VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES);
		dataLen = strbuf.len;
	}

	resLen = dataLen + variantHeaderLen;

	/* We need an extra varlena header for varlena datatypes */
	if (variantBaseType == VARIANT_TYPE_CHAR || 
		variantBaseType == VARIANT_TYPE_NCHAR ||
		variantBaseType == VARIANT_TYPE_VARCHAR || 
		variantBaseType == VARIANT_TYPE_NVARCHAR ||
		variantBaseType == VARIANT_TYPE_BINARY || 
		variantBaseType == VARIANT_TYPE_VARBINARY ||
		variantBaseType == VARIANT_TYPE_NUMERIC ||
		variantBaseType == VARIANT_TYPE_DECIMAL ||
		variantBaseType == VARIANT_TYPE_TIME ||
		variantBaseType == VARIANT_TYPE_DATETIME2 ||
		variantBaseType == VARIANT_TYPE_DATETIMEOFFSET)
	{
		resLen += VARHDRSZ;
	}

	/* common varlena header for SQL_VARIANT datatype */
	if (resLen + VARHDRSZ_SHORT <= VARATT_SHORT_MAX)
	{
		resLen += VARHDRSZ_SHORT;
		result = (bytea *) palloc0(resLen);
		SET_VARSIZE_SHORT(result, resLen);
	}
	else
	{
		resLen += VARHDRSZ;
		result = (bytea *) palloc0(resLen);
		SET_VARSIZE(result, resLen);
	}

	if (variantBaseType == VARIANT_TYPE_CHAR || 
		variantBaseType == VARIANT_TYPE_NCHAR ||
	    variantBaseType == VARIANT_TYPE_VARCHAR || 
	    variantBaseType == VARIANT_TYPE_NVARCHAR)
	{
		SET_VARSIZE(READ_DATA(result, variantHeaderLen), VARHDRSZ + dataLen);
		memcpy(&maxLen, &buf->data[7], 2);
		if (variantBaseType == VARIANT_TYPE_NCHAR || variantBaseType == VARIANT_TYPE_NVARCHAR)
		{
			/*
			 * dataformat: totalLen(4B) + metadata(9B)( baseType(1B) + metadatalen(1B) +
			 *	encodingLen(5B) + dataLen(2B) ) + data(dataLen)
			 * Data is in UTF16 format.
			 */
			memcpy(VARDATA(READ_DATA(result, variantHeaderLen)), strbuf.data, dataLen);
			pfree(strbuf.data);
		}
		else
		{
			/*
			 * dataformat: totalLen(4B) + metadata(9B)( baseType(1B) + metadatalen(1B) +
			 *	encodingLen(5B) + dataLen(2B) ) + data(dataLen)
			 */
			memcpy(VARDATA(READ_DATA(result, variantHeaderLen)), &buf->data[VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES], dataLen);
		}
	}
	else if (variantBaseType == VARIANT_TYPE_BINARY || 
			variantBaseType == VARIANT_TYPE_VARBINARY)
	{
		/*
		 * dataformat : totalLen(4B) + metadata(4B)( baseType(1B) + metadatalen(1B) +
		 *      dataLen(2B) ) + data(dataLen)
		 */
		SET_VARSIZE(READ_DATA(result, variantHeaderLen), VARHDRSZ + dataLen);
		memcpy(&maxLen, &buf->data[2], 2);
		memcpy(VARDATA(READ_DATA(result, variantHeaderLen)), &buf->data[VARIANT_TYPE_METALEN_FOR_BIN_DATATYPES], dataLen);
	}
	else if (variantBaseType == VARIANT_TYPE_DATE)
	{
		/*
		 * dataformat : totalLen(4B) + metadata(2B)( baseType(1B) + metadatalen(1B) ) +
		 *              data(3B)
		 */
		memset(&date, 0, sizeof(date));
		memcpy(&date, &buf->data[VARIANT_TYPE_METALEN_FOR_DATE], 3);
		TdsCheckDateValidity(date);
		TdsTimeGetDatumFromDays(date, &dateval);
		memcpy(READ_DATA(result, variantHeaderLen), &dateval, sizeof(date));
	}
	else if (variantBaseType == VARIANT_TYPE_SMALLDATETIME)
	{
		/*
		 * dataformat : totalLen(4B) + metadata(2B)( baseType(1B) + metadatalen(1B) ) +
		 *              data(4B)
		 */
		memcpy(&numDays, &buf->data[VARIANT_TYPE_METALEN_FOR_SMALLDATETIME], 2);
		memcpy(&numMins, &buf->data[4], 2);
		TdsTimeGetDatumFromSmalldatetime(numDays, numMins, &timestamp);
		memcpy(READ_DATA(result, variantHeaderLen), &timestamp, sizeof(timestamp));
	}
	else if (variantBaseType == VARIANT_TYPE_DATETIME)
	{
		/*
		 * dataformat : totalLen(4B) + metadata(2B)( baseType(1B) + metadatalen(1B) ) +
		 *              data(8B)
		 */
		memcpy(&numDays32, &buf->data[VARIANT_TYPE_METALEN_FOR_DATETIME], 4);
		memcpy(&numTicks, &buf->data[6], 4);
		TdsTimeGetDatumFromDatetime(numDays32, numTicks, &timestamp);
		memcpy(READ_DATA(result, variantHeaderLen), &timestamp, sizeof(timestamp));
	}
	else if (variantBaseType == VARIANT_TYPE_TIME)
	{
		/*
		 * dataformat : totalLen(4B) + metadata(3B)( baseType(1B) + metadatalen(1B) +
		 *              scale(1B) ) + data(3B-5B)
		 */
		scale = buf->data[2];
		temp = scale;	
		/* postgres limitation */
		if (scale > 7 || scale < 0)
			scale = DATETIMEOFFSETMAXSCALE;

		if (scale <= 2)
			dataLen = 3;
		else if (scale <= 4)
			dataLen = 4;
		else if (scale <= 7)
			dataLen = 5;

		memset(&numMicro, 0, sizeof(numMicro));
		memcpy(&numMicro, &buf->data[VARIANT_TYPE_METALEN_FOR_TIME], dataLen);

		if (temp == 7 || temp == 0xff)
			numMicro /= 10;
		
		while (scale < 6)
		{
			numMicro *= 10;
			scale++;
		}
		scale = temp;
		memcpy(READ_DATA(result, variantHeaderLen), &numMicro, sizeof(numMicro));	
	}
	else if (variantBaseType == VARIANT_TYPE_DATETIME2)
	{
		/*
		 * dataformat : totalLen(4B) + metadata(3B)( baseType(1B) + metadatalen(1B) +
		 *              scale(1B) ) + data(6B-8B)
		 */
		scale = buf->data[2];
	
		/* postgres limitation */
                if (scale > 7 || scale == 0xff || scale < 0)
			scale = DATETIMEOFFSETMAXSCALE;

		if (scale <= 2)
			dataLen = 6;
		else if (scale <= 4)
			dataLen = 7;
		else if (scale <= 7)
			dataLen = 8;
		
		memset(&numDays32, 0, sizeof(numDays32));
		memset(&numMicro, 0, sizeof(numMicro));
		memcpy(&numDays32, &buf->data[VARIANT_TYPE_METALEN_FOR_DATETIME2], 3);
		memcpy(&numMicro, &buf->data[6], dataLen - 3);
		TdsGetTimestampFromDayTime(numDays32, numMicro, 0, &timestamp, scale);
		memcpy(READ_DATA(result, variantHeaderLen), &timestamp, sizeof(timestamp));
	}
	else if (variantBaseType == VARIANT_TYPE_DATETIMEOFFSET)
	{
		/*
		 * dataformat : totalLen(4B) + metadata(3B)(baseType(1B) + metadatalen(1B) +
		 *              scale(1B)) + data(8B-10B)
		 */
		scale = buf->data[2];
	
		/* postgres limitation */
		if (scale > 7 || scale == 0xff || scale < 0)
			scale = DATETIMEOFFSETMAXSCALE;

		if (scale <= 2)
			dataLen = 8;
		else if (scale <= 4)
			dataLen = 9;
		else if (scale <= 7)
			dataLen = 10;
	
		memset(&numDays32, 0, sizeof(numDays32));
		memset(&numMicro, 0, sizeof(numMicro));
		memcpy(&numDays32, &buf->data[dataLen - 2], 3);
		memcpy(&numMicro, &buf->data[3], dataLen - 5);
		memcpy(&timezone, &buf->data[dataLen + 1], 2);

		timezone *= -1;
		TdsGetTimestampFromDayTime(numDays32, numMicro, (int)timezone, &timestamptz, scale);
		timestamptz -= (timezone * SECS_PER_MINUTE * USECS_PER_SEC);
		timestamptz -= (timezone * USECS_PER_SEC);

		tdt->tsql_ts = timestamptz;
		tdt->tsql_tz = timezone;
		memcpy(READ_DATA(result, variantHeaderLen), tdt, DATETIMEOFFSET_LEN);
	}
	else if (variantBaseType == VARIANT_TYPE_NUMERIC || variantBaseType == VARIANT_TYPE_DECIMAL)
	{
		/*
		 * dataformat : totalLen(4B) + metdata(5B)( baseType(1B) + metadatalen(1B) +
		 * 		precision(1B) + scale(1B) + sign(1B) ) + data(dataLen)
		 */
		SET_VARSIZE(READ_DATA(result, variantHeaderLen), VARHDRSZ + dataLen);
		precision = buf->data[2];
		scale = buf->data[3];
		sign = buf->data[4];
		tempScale = scale;

		dataLen = 16;
		memcpy(&n128, &buf->data[VARIANT_TYPE_METALEN_FOR_NUMERIC_DATATYPES], dataLen);
		num = LEtoh128(n128);
		decString = (char *)palloc0(sizeof(char) * 40);
		if (num != 0)
			Integer2String(num, decString);
		else
			decString[0] = '0';
		len = strlen(decString);
		temp1 = '.';
		if (num != 0)
		{
			while (tempScale)
			{
				temp2 = decString[len - tempScale];
				decString[len - tempScale] = temp1;
				temp1 = temp2;
				tempScale--;
			}
			decString[len++] = temp1;
		}
		else
		{
			decString[len++] = temp1;
			while (tempScale)
			{
				decString[len++] = '0';
				tempScale--;
			}
		}

		if (sign == 1 && num != 0)
			decString++;
		res = TdsSetVarFromStrWrapper(decString);
		memcpy(READ_DATA(result, variantHeaderLen), (bytea *)DatumGetPointer(res), dataLen);
	}
	else
	{
		/*
		 * For all other fixed length datatypes
		 */
		memcpy(READ_DATA(result, variantHeaderLen), &buf->data[VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES], dataLen);

		if (variantBaseType == VARIANT_TYPE_MONEY)
		{
			/*
			 * swap positions of 2 nibbles for money type
			 * to match SQL behaviour
			 */
			for (i = 0; i < 4; i++)
				SwapByte(READ_DATA(result, variantHeaderLen), i, i + 4);
		}
		else if (variantBaseType == VARIANT_TYPE_UNIQUEIDENTIFIER)
		{
			/* SWAP to match TSQL behaviour */
			SwapByte(READ_DATA(result, variantHeaderLen), 0, 3);
			SwapByte(READ_DATA(result, variantHeaderLen), 1, 2);
			SwapByte(READ_DATA(result, variantHeaderLen), 4, 5);
			SwapByte(READ_DATA(result, variantHeaderLen), 6, 7);
		}
	}

	pltsql_plugin_handler_ptr->sqlvariant_set_metadata(result,
					pgBaseType, scale, precision, maxLen);

	buf->cursor += tempLen;

	pfree(tdt);
	PG_RETURN_BYTEA_P(result);
}

int
TdsSendTypeSqlvariant(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int		rc = EOF, variantBaseType = 0;
	uint8_t		pgBaseType = 0;
	int		dataLen = 0, totalLen = 0, maxLen = 0, variantHeaderLen = 0;
	bytea		*vlena = DatumGetByteaPCopy(value);
	char		*buf = VARDATA(vlena), *decString = NULL, *out = NULL;
	bool		isBaseNum = false, isBaseChar = false;
	bool		isBaseBin = false, isBaseDec = false, isBaseDate = false;
	uint32		numDays = 0, numTicks = 0, dateval = 0; 
	uint16		numMins = 0, numDays16 = 0;
	uint64		numMicro = 0;
	int16		timezone = 0;
	int		precision = 0, scale = -1, sign = 1, i = 0, temp = 0;
	uint128		num = 0;
	Timestamp	timestamp = 0;
	TimestampTz	timestamptz = 0;

	TDSInstrumentation(INSTR_TDS_DATATYPE_SQLVARIANT);

	/*
	 * First sql variant header byte contains:
	 * 		 type code ( 5bit ) + MD ver (3bit)
	 */
	pgBaseType = pltsql_plugin_handler_ptr->sqlvariant_inline_pg_base_type(vlena);

	pltsql_plugin_handler_ptr->sqlvariant_get_metadata(vlena, pgBaseType,
							&scale, &precision, &maxLen);		

	pltsql_plugin_handler_ptr->sqlvariant_get_variant_base_type(pgBaseType,
				 &variantBaseType, &isBaseNum, &isBaseChar,
				 &isBaseDec, &isBaseBin, &isBaseDate, &variantHeaderLen);

	dataLen = VARSIZE_ANY_EXHDR(vlena) - variantHeaderLen;
	buf += variantHeaderLen;

	if (isBaseNum)
	{
		/*
		 * dataformat: totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 * 		data(dataLen)
		 */
		if (variantBaseType == VARIANT_TYPE_TINYINT)
			dataLen = 1;

		if (variantBaseType == VARIANT_TYPE_SMALLMONEY)
			dataLen = 4;

		if (variantBaseType == VARIANT_TYPE_MONEY)
		{
			/*
			 * swap positions of 2 nibbles for money type
			 * to match SQL behaviour
			 */
			for (i = 0; i < 4; i++)
				SwapByte(buf, i, i + 4);
		}

		if (variantBaseType == VARIANT_TYPE_UNIQUEIDENTIFIER)
		{
			/* SWAP to match TSQL behaviour */
			SwapByte(buf, 0, 3);
			SwapByte(buf, 1, 2);
			SwapByte(buf, 4, 5);
			SwapByte(buf, 6, 7);
		}

		totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
		rc = TdsPutUInt32LE(totalLen);
		rc |= TdsPutInt8(variantBaseType);
		rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_NUM_DATATYPES);
		rc |= TdsPutbytes(buf, dataLen);
	}
	else if (isBaseChar)
	{
		/*
		 * dataformat: totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 *		encodingLen(5B) + dataLen(2B) + data(dataLen)
		 */
		StringInfoData	strbuf;
		int actualDataLen = 0;	 /* Number of bytes that would be needed to store given string in given encoding. */
		char *destBuf = NULL;
		dataLen -= VARHDRSZ;
		if (variantBaseType == VARIANT_TYPE_NCHAR ||
		    variantBaseType == VARIANT_TYPE_NVARCHAR)
		{
			initStringInfo(&strbuf);
			TdsUTF8toUTF16StringInfo(&strbuf, buf + VARHDRSZ, dataLen);
			actualDataLen = strbuf.len;
		}
		else
		{
			/* 
			 * TODO: [BABEL-1069] Remove collation related hardcoding 
			 * from sql_variant sender for char class basetypes
			 */
			if (dataLen > 0)
				destBuf = TdsEncodingConversion(buf + VARHDRSZ, dataLen, PG_UTF8 ,PG_WIN1252, &actualDataLen);
			else
				/* We can not assume that buf would be NULL terminated. */
				actualDataLen = 0;
		}

		totalLen = actualDataLen + VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES;

		rc = TdsPutUInt32LE(totalLen);
		rc |= TdsPutInt8(variantBaseType);
		rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_CHAR_DATATYPES);
		/*
		 * 5B of fixed collation
		 * TODO: [BABEL-1069] Remove collation related hardcoding 
		 * from sql_variant sender for char class basetypes
		 */
		rc |= TdsPutInt8(9);
		rc |= TdsPutInt8(4);
		rc |= TdsPutInt8(208);
		rc |= TdsPutInt8(0);
		rc |= TdsPutInt8(52);

		rc |= TdsPutUInt16LE(actualDataLen);

		if (variantBaseType == VARIANT_TYPE_NCHAR ||
		    variantBaseType == VARIANT_TYPE_NVARCHAR)
		{
			rc |= TdsPutbytes(strbuf.data, actualDataLen);
			pfree(strbuf.data);
		}
		else	
			rc |= TdsPutbytes(destBuf, actualDataLen);

		if (destBuf)
			pfree(destBuf);
	}
	else if (isBaseBin)
	{
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 * 		dataLen(2B) + data(dataLen)
		 */
		dataLen = dataLen - VARHDRSZ;
		totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_BIN_DATATYPES;

		rc = TdsPutUInt32LE(totalLen);
		rc |= TdsPutInt8(variantBaseType);
		rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_BIN_DATATYPES);
		rc |= TdsPutUInt16LE(maxLen);
		rc |= TdsPutbytes(buf + VARHDRSZ, dataLen);
	}
	else if (isBaseDec)
	{
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 * 		precision(1B) + scale(1B) + sign(1B) + data(dataLen)
		 */
		dataLen = 16;
		totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_NUMERIC_DATATYPES;

		out = OutputFunctionCall(finfo, value);
		if (out && out[0] == '-')
		{
			sign = 0;
			out++;
		}
		decString = (char *)palloc(sizeof(char) * (strlen(out) + 1));
		precision = 0, scale = -1;
		while (out && *out)
		{
			if (*out == '.')
			{
				out++;
				scale = 0;
				continue;
			}
			decString[precision++] = *out;
			out++;
			if (scale >= 0)
				scale++;
		}
		if (scale == -1)
			scale = 0;
		decString[precision] = '\0';
		num = StringToInteger(decString);

		rc = TdsPutUInt32LE(totalLen);
		rc |= TdsPutInt8(variantBaseType);
		rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_NUMERIC_DATATYPES);
		rc |= TdsPutInt8(precision);
		rc |= TdsPutInt8(scale);
		rc |= TdsPutInt8(sign);
		rc |= TdsPutbytes(&num, dataLen);
	}
	else if (isBaseDate)
	{
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 *              data(3B)
		 */

		if (variantBaseType == VARIANT_TYPE_DATE)
		{
			memset(&dateval, 0, sizeof(dateval));
			memcpy(&dateval, buf, sizeof(dateval));
			numDays = TdsDayDifference(dateval);
			dataLen = 3;
			totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_DATE;
			rc = TdsPutUInt32LE(totalLen);
			rc |= TdsPutInt8(variantBaseType);
			rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_DATE);
			rc |= TdsPutDate(numDays);
		}
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 *              data(4B)
		 */
		else if (variantBaseType == VARIANT_TYPE_SMALLDATETIME)
		{
			memcpy(&timestamp, buf, sizeof(timestamp));
			dataLen = 4;
			totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_SMALLDATETIME;		
			TdsTimeDifferenceSmalldatetime(timestamp, &numDays16, &numMins);
			rc = TdsPutUInt32LE(totalLen);
			rc |= TdsPutInt8(variantBaseType);
			rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_SMALLDATETIME);
			rc |= TdsPutUInt16LE(numDays16);
			rc |= TdsPutUInt16LE(numMins);
		}
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 *              data(8B)
		 */
		else if (variantBaseType == VARIANT_TYPE_DATETIME)
		{
			memcpy(&timestamp, buf, dataLen);
			TdsTimeDifferenceDatetime(timestamp, &numDays, &numTicks);
			dataLen = 8;
			totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_DATETIME;
			rc = TdsPutUInt32LE(totalLen);
			rc |= TdsPutInt8(variantBaseType);
			rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_DATETIME);
			rc |= TdsPutUInt32LE(numDays);
			rc |= TdsPutUInt32LE(numTicks);
		}
		else if (variantBaseType == VARIANT_TYPE_TIME)
		{
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 *              scale(1B) + data(3B-5B)
		 */
			if (scale == 0xff || scale < 0 || scale > 7)
				scale = DATETIMEOFFSETMAXSCALE;

			if (scale >= 0 && scale < 3)
				dataLen = 3;
			else if (scale >= 3 && scale < 5)
				dataLen = 4;
			else if (scale >= 5 && scale <= 7)
				dataLen = 5;

			memcpy(&numMicro, buf, sizeof(numMicro));
			temp = scale;
			if (scale == 7 || scale == 0xff)
				numMicro *= 10;

			while (temp < 6)
			{
				numMicro /= 10;
				temp++;
			}
			totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_TIME;
			rc = TdsPutUInt32LE(totalLen);
			rc |= TdsPutInt8(variantBaseType);
			rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_TIME);
			rc |= TdsPutInt8(scale);
			rc = TdsPutbytes(&numMicro, dataLen);
		}
		else if(variantBaseType == VARIANT_TYPE_DATETIME2)
		{
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 *              scale(1B) + data(6B-8B)
		 */
			if (scale == 0xff || scale < 0 || scale > 7)
				scale = DATETIMEOFFSETMAXSCALE;

			if (scale >= 0 && scale < 3)
				dataLen = 6;
			else if (scale >= 3 && scale < 5)
				dataLen = 7;
			else if (scale >= 5 && scale <= 7)
				dataLen = 8;

			memcpy(&timestamp, buf, sizeof(timestamp));
			TdsGetDayTimeFromTimestamp((Timestamp)timestamp, &numDays,
							&numMicro, scale);

			totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_DATETIME2;
			rc = TdsPutUInt32LE(totalLen);
			rc |= TdsPutInt8(variantBaseType);
			rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_DATETIME2);
			rc |= TdsPutInt8(scale);
			rc |= TdsPutbytes(&numMicro, dataLen - 3);
			rc |= TdsPutDate(numDays);
		}
		else if (variantBaseType == VARIANT_TYPE_DATETIMEOFFSET)
		{
		/*
		 * dataformat : totalLen(4B) + baseType(1B) + metadatalen(1B) +
		 *              scale(1B) + data(8B-10B)
		 */
			tsql_datetimeoffset *tdt = (tsql_datetimeoffset *)buf;
			timestamptz = tdt->tsql_ts;
			timezone = tdt->tsql_tz;
			timestamptz += (timezone * SECS_PER_MINUTE * USECS_PER_SEC);
			
			if (scale == 0xff || scale < 0 || scale > 7)
				scale = DATETIMEOFFSETMAXSCALE;

			if (scale >= 0 && scale < 3)
				dataLen = 8;
			else if (scale >= 3 && scale < 5)
				dataLen = 9;
			else if (scale >= 5 && scale <= 7)
				dataLen = 10;

			TdsGetDayTimeFromTimestamp((Timestamp)timestamptz, &numDays,
							&numMicro, scale);
			timezone *= -1;

			totalLen = dataLen + VARIANT_TYPE_METALEN_FOR_DATETIMEOFFSET;
			rc = TdsPutUInt32LE(totalLen);
			rc |= TdsPutInt8(variantBaseType);
			rc |= TdsPutInt8(VARIANT_TYPE_BASE_METALEN_FOR_DATETIMEOFFSET);
			rc |= TdsPutInt8(scale);
			rc |= TdsPutbytes(&numMicro, dataLen - 5);
			rc |= TdsPutDate(numDays);
			rc |= TdsPutInt16LE(timezone);
		}
	}

	if (vlena)
		pfree(vlena);
	return rc;
}

Datum
TdsRecvTypeDatetimeoffset(const char *message, const ParameterToken token)
{
	StringInfo      buf = TdsGetStringInfoBufferFromToken(message, token);
	Datum 	result;
	TdsColumnMetaData       col = token->paramMeta;
	int scale = col.metaEntry.type6.scale;

	TDSInstrumentation(INSTR_TDS_DATATYPE_DATETIME_OFFSET);

	result = TdsTypeDatetimeoffsetToDatum(buf, scale, token->len);

	pfree(buf);
	return result;
}

int
TdsSendTypeDatetimeoffset(FmgrInfo *finfo, Datum value, void *vMetaData)
{
	int		rc = EOF, length = 0, scale = 0;
	uint64		numSec = 0;
	uint32		numDays = 0;
	int16_t		timezone = 0;
	TimestampTz	timestamp = 0;
	TdsColumnMetaData  *col = (TdsColumnMetaData *)vMetaData;
	
	tsql_datetimeoffset *tdt = (tsql_datetimeoffset *)value;

	if (GetClientTDSVersion() < TDS_VERSION_7_3_A)
		/*
		 * If client being connected is using TDS version lower than 7.3A
		 * then TSQL treats DATETIMEOFFSET as NVARCHAR.
		 */
		return TdsSendTypeNVarchar(finfo, value, vMetaData);

	TDSInstrumentation(INSTR_TDS_DATATYPE_DATETIME_OFFSET);

	timestamp = tdt->tsql_ts;
	timezone = tdt->tsql_tz;
	timestamp += (timezone * SECS_PER_MINUTE * USECS_PER_SEC);

	scale = col->metaEntry.type6.scale;
	/*
	 * if Datetimeoffset data has no specific scale specified in the query, default scale
	 * to be considered is 7 always.
	 */
	if (scale == 0xFF)
		scale = DATETIMEOFFSETMAXSCALE;

	if (scale >= 0 && scale < 3)
		length = 8;
	else if (scale >= 3 && scale < 5)
		length = 9;
	else if (scale >= 5 && scale <= 7)
		length = 10;

	
	TdsGetDayTimeFromTimestamp((Timestamp)timestamp, &numDays,
					&numSec, scale);
	timezone *= -1;
	if (TdsPutInt8(length) == 0 &&
	    TdsPutbytes(&numSec, length - 5) == 0 &&
	    TdsPutDate(numDays) == 0)
		rc = TdsPutUInt16LE(timezone);

	return rc;
}

Datum TdsBytePtrToDatum(StringInfo buf, int datatype, int scale)
{	
	switch (datatype)
	{
		case TDS_TYPE_DATETIMEN:
			return TdsTypeDatetimeToDatum(buf);
		case TDS_TYPE_SMALLDATETIME:
			return TdsTypeSmallDatetimeToDatum(buf);
		case TDS_TYPE_MONEYN:
			return TdsTypeMoneyToDatum(buf);
		case TDS_TYPE_SMALLMONEY:
			return TdsTypeSmallMoneyToDatum(buf);
		case TDS_TYPE_NUMERICN:
			return TdsTypeNumericToDatum(buf, scale);
		default:
			return (Datum) 0;
	}
}

Datum TdsDateTimeTypeToDatum (uint64 time, int32 date, int datatype, int optional_attr)
{
	switch (datatype)
	{
		case TDS_TYPE_DATE:
			{
				DateADT result;
				uint64	val;

				/* 
				 * By default we calculate date from 01-01-0001
				 * but buf has number of days from 01-01-1900. So adding
				 * number of days between 01-01-1900 and 01-01-0001
				 */
				result = (DateADT)date + (DateADT)TdsGetDayDifferenceHelper(1, 1, 1900, true);
				TdsCheckDateValidity(result);

				TdsTimeGetDatumFromDays(result, &val);

				PG_RETURN_DATEADT(val);
			}
		case TDS_TYPE_TIME:
			{
				/* optional attribute here is scale */
				while (optional_attr--)
					time /= 10;

				time *= 1000000;
				if (time < INT64CONST(0) || time > USECS_PER_DAY)
					ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("time out of range")));

				PG_RETURN_TIMEADT((TimeADT)time);
			}
		case TDS_TYPE_DATETIME2:
			{	
				Timestamp	timestamp;

				/* 
				 * By default we calculate date from 01-01-0001
				 * but buf has number of days from 01-01-1900. So adding
				 * number of days between 01-01-1900 and 01-01-0001
				 */
				date += TdsGetDayDifferenceHelper(1, 1, 1900, true);

				/* optional attribute here is scale */
				TdsGetTimestampFromDayTime(date, time, 0, &timestamp, optional_attr);

				PG_RETURN_TIMESTAMP((Timestamp)timestamp);
			}
		case TDS_TYPE_DATETIMEOFFSET:
			{	
				tsql_datetimeoffset *tdt = (tsql_datetimeoffset *) palloc0(DATETIMEOFFSET_LEN);
				TimestampTz	timestamp;

				/* 
				 * By default we calculate date from 01-01-0001
				 * but buf has number of days from 01-01-1900. So adding
				 * number of days between 01-01-1900 and 01-01-0001
				 */
				date += TdsGetDayDifferenceHelper(1, 1, 1900, true);

				/* optional attribute here is time offset */
				optional_attr *= -1;
				TdsGetTimestampFromDayTime(date, time, (int)optional_attr, &timestamp, 7);

				timestamp -= (optional_attr * SECS_PER_MINUTE * USECS_PER_SEC);
				/* since reverse is done in tm2timestamp() */
				timestamp -= (optional_attr * USECS_PER_SEC);

				tdt->tsql_ts = timestamp;
				tdt->tsql_tz = optional_attr;

				PG_RETURN_DATETIMEOFFSET(tdt);
			}
		default:
			return (Datum) 0;
	}
}
