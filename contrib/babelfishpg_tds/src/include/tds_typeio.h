/*-------------------------------------------------------------------------
 *
 * tds_typeio.h
 *	  Definitions for PG-Datum <-> TDS-protocol conversion
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/tds/tds_typeio.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef TDS_TYPEIO_H
#define TDS_TYPEIO_H

#include "fmgr.h"

#include "tds_iofuncmap.h"

/* Prototypes for Send and Receive IO functions */

/* Partial Length Prefixecd-bytes tokens */
#define PLP_TERMINATOR	0x00000000
#define PLP_NULL		0xFFFFFFFFFFFFFFFF
#define PLP_UNKNOWN_LEN 0xFFFFFFFFFFFFFFFE
#define PLP_CHUNCK_LEN	32000

/*
 * TODO: Using a void * for the column meta data is an ugly hack.
 *		 This is needed here now because there are circular
 *		 dependencies with tds_int.h that I rather untangle
 *		 in a separate CR than muddling it up into this one.
 *		 -- Jan
 *		Circular dependency for parameter token needs to be handled
 *		in a similar way as that of column meta data
 */
typedef int (*TdsSendTypeFunction)(FmgrInfo *finfo, Datum value,
									  void *vMetaData);

/* COLMETADATA entry for types like INTEGER and SMALLINT */
typedef struct __attribute__((packed)) ColMetaEntry1
{
	uint16_t		flags;
	uint8_t			tdsTypeId;
	uint8_t			maxSize;
} ColMetaEntry1;

/* COLMETADATA entry for types like NVARCHAR */
typedef struct __attribute__((packed)) ColMetaEntry2
{
	uint16_t		flags;
	uint8_t			tdsTypeId;
	uint16_t		maxSize;
	/*
	 * collationInfo(32 bits): LCID/CodePage (20 bits) + 
	 * collationFlags(8 bits) + version (4 bits) 
	 */
	uint32_t		collationInfo;
	uint8_t			charSet; /* sortID */
} ColMetaEntry2;


/* COLMETADATA entry for types like TEXT */
typedef struct __attribute__((packed)) ColMetaEntry3
{
	uint16_t		flags;
	uint8_t			tdsTypeId;
	uint32_t		maxSize;
	/*
	 * collationInfo(32 bits): LCID/CodePage (20 bits) +
	 * collationFlags(8 bits) + version (4 bits)
	 */
	uint32_t		collationInfo;
	uint8_t			charSet; /* sortID */
} ColMetaEntry3;

/* COLMETADATA entry for type like DATE */
typedef struct __attribute__((packed)) ColMetaEntry4
{
	uint16_t		flags;
	uint8_t			tdsTypeId;
} ColMetaEntry4;

/* COLMETADATA entry for type NUMERIC */
typedef struct __attribute__((packed)) ColMetaEntry5
{
	uint16_t                flags;
	uint8_t                 tdsTypeId;
	uint8_t                 maxSize;
	uint8_t                 precision;
	uint8_t                 scale;
} ColMetaEntry5;

/* COLMETADATA entry for type like TIME, DATETIME2, DATETIMEOFFSET */
typedef struct __attribute__((packed)) ColMetaEntry6
{
	uint16_t		flags;
	uint8_t			tdsTypeId;
	uint8_t			scale;
} ColMetaEntry6;

/* COLMETADATA entry for types like BINARY VARBINARY */
typedef struct __attribute__((packed)) ColMetaEntry7
{
	uint16_t		flags;
	uint8_t			tdsTypeId;
	uint16_t		maxSize;
} ColMetaEntry7;

/* COLMETADATA entry for type like IMAGE */
typedef struct __attribute__((packed)) ColMetaEntry8
{
        uint16_t                flags;
        uint8_t                 tdsTypeId;
        uint32_t                maxSize;
} ColMetaEntry8;

typedef union ColMetaEntry
{
	ColMetaEntry1	type1;
	ColMetaEntry2	type2;
	ColMetaEntry3	type3;
	ColMetaEntry4	type4;
	ColMetaEntry5	type5;
	ColMetaEntry6	type6;
	ColMetaEntry7	type7;
	ColMetaEntry8	type8;
} ColMetaEntry;

/*
 * It stores the relation related information corresponding to
 * a TdsColumnMetaData entry.  We need this information to
 * construct the COLMETADATA, TABNAME and COLINFO tokens.
 */
typedef struct TdsRelationMetaData
{
	Oid				relOid;			/* relation oid */
	AttrNumber		*keyattrs;		/* primary keys for this relation */
	int16			numkeyattrs;	/* number of attributes in pk */

	/*
	 * We store the fully qualified name of the relation.  This information is
	 * needed on TABNAME token.
	 *
	 * partName[0] - relation name
	 * partName[1] - schema name
	 * partName[2] - database name
	 * partName[3] - object name
	 */
	char			*partName[4];

	/*
	 * A 1-based index for this relation which is used while sending the
	 * COLINFO token.
	 */
	uint8			tableNum;
} TdsRelationMetaDataInfoData;

typedef TdsRelationMetaDataInfoData *TdsRelationMetaDataInfo;

typedef struct TdsColumnMetaData
{
	Oid						pgTypeOid;	/* type identifier in PostgreSQL */
	StringInfoData			colName;	/* column name */
	int						sizeLen;	/* size of the type's data length */
	int						metaLen;	/* size of ColMetaEntry used */
	TdsSendTypeFunction	sendFunc;
	ColMetaEntry			metaEntry;
	bool					sendTableName;
	pg_enc					encoding;

	/*
	 * Following information are only needed if we need to send TABNAME and COLINFO
	 * tokens.
	 */
	char					*baseColName;	/* actual column name if any alias is used */
	Oid						relOid;		/* relation that this column belongs to (0 if
										   an expression column */
	AttrNumber				attrNum;	/* attribute number in the relation */
	TdsRelationMetaDataInfo	relinfo;
	bool 					attNotNull; 	/* true if the column has not null constraint */
	bool 					attidentity;	/* true if it is an identity column */
	bool 					attgenerated;	/* true if it is a computed column */
} TdsColumnMetaData;

/* Partial Length Prefixed-bytes */
typedef struct PlpData
{
	unsigned long offset;
	unsigned long len;
	struct PlpData *next;
} PlpData;
typedef PlpData *Plp;

typedef struct TvpColMetaData
{
	int userType;
	uint16 flags;
	uint8_t columnTdsType;

	/* For numeric and decimal. */
	uint8_t scale;
	uint8_t precision;

	uint8_t sortId;
	pg_enc	encoding;

	uint32_t maxLen;
} TvpColMetaData;

typedef struct TvpRowData
{
	/* Array of length col count, holds value of each column in that row. */
	StringInfo columnValues;

	char *isNull;
	struct TvpRowData *nextRow;
} TvpRowData;

typedef struct TvpData
{
	char 			*tvpTypeName;
	char 			*tvpTypeSchemaName;
	char 			*tableName;
	int 			colCount;
	int 			rowCount;

	TvpColMetaData  *colMetaData; /* Array of each column's metadata. */
	TvpRowData 		*rowData;     /* Linked List holding each row. */
} TvpData;

typedef struct BulkLoadColMetaData
{
	int 		userType;
	uint16 		flags;
	uint8_t 	columnTdsType;

	/* For numeric and decimal. */
	uint8_t 	scale;
	uint8_t 	precision;

	/* For String Datatpes. */
	uint8_t 	sortId;
	pg_enc		encoding;

	uint32_t 	maxLen;

	uint32_t 	colNameLen;
	char 		*colName;

	bool 		variantType;
} BulkLoadColMetaData;

typedef struct BulkLoadRowData
{
	/* Array of length col count, holds value of each column in that row. */
	Datum *columnValues;

	bool *isNull;
} BulkLoadRowData;

/* Map TVP to its underlying table, either by relid or by table name. */
typedef struct TvpLookupItem
{
	char 			*name;
	Oid 			tableRelid;
	char 			*tableName;
} TvpLookupItem;

/* parameter token in RPC */
typedef struct ParameterTokenData
{
	uint8_t type;
	uint8_t flags;

	/*
	 * maxlen and len fields are 4 bytes for some
	 * datatypes(text, ntext) while 2 bytes for
	 * (nvarchar, others?) and 1 byte for others.
	 */
	uint32_t maxLen;
	uint32_t len;
	bool	isNull;

	Plp plp;

	/*
	 * dataOffset points to the offset in the request message
	 * from where the data bytes actually start.
	 * Using, dataOffset + len we can fetch the entire data
	 * from the request message, when we want to use it.
	 */
	int dataOffset;

	uint16					paramOrdinal;

	/*
	 * Upon receiving a parameter for a RPC packet, we fill the following
	 * structure with the meta information about that parameter.  We also
	 * store the corresponding PG type OID, receiver function and sender
	 * function.  For IN parameters, we use the receiver functions to
	 * convert the parameter from TDS wire format to Datum.  For OUT
	 * parameters, we use the sender functions to convert the Datums to
	 * TDS wire format and include them in the return value tokens.
	 */
	TdsColumnMetaData		paramMeta;

	/*
	 * If this is an OUT parameter, it points to the column number in the
	 * result set.
	 */
	int						outAttNo;

	TvpData 		*tvpInfo;
	struct ParameterTokenData *next;
} ParameterTokenData;

typedef ParameterTokenData *ParameterToken;


typedef Datum (*TdsRecvTypeFunction)(const char *, const ParameterToken);

/*
 * TdsCollationData - hash table structure for
 * mapping Postgres - TSQL Collation
 */
typedef struct TdsCollationData
{
	Oid						collationOid;
	int32_t					codePage;
	int32_t					collateFlags;
	int32_t					sortId;
} TdsCollationData;

typedef TdsCollationData *TdsCollationInfo;

/*
 * TdsLCIDToEncodingMap - hash table structure to
 * store LCID - Encoding pair
 */
typedef struct TdsLCIDToEncodingMap
{
	int 					lcid;
	int 					enc;
} TdsLCIDToEncodingMap;

typedef TdsLCIDToEncodingMap *TdsLCIDToEncodingMapInfo;
/*
 * TdsIoFunctionData - hash table entry for IO function cache
 * TdsIoFunctionRawData - Raw Table data entry for TdsIoFunctionData
 */

typedef struct TdsIoFunctionRawData
{
	const char *typnsp;
	const char *typname;
	int32_t ttmtdstypeid;
	int32_t ttmtdstypelen;
	int32_t ttmtdslenbytes;
	int32_t ttmsendfunc;
	int32_t ttmrecvfunc;
} TdsIoFunctionRawData;

typedef struct TdsIoFunctionData
{
	Oid						ttmtypeid;
	Oid						ttmbasetypeid;
	int32_t					ttmtdstypeid;
	int32_t					ttmtdstypelen;
	int32_t					ttmtdslenbytes;
	int32_t					sendFuncId;
	int32_t					recvFuncId;
	TdsSendTypeFunction	sendFuncPtr;
	TdsRecvTypeFunction	recvFuncPtr;
} TdsIoFunctionData;

typedef struct TdsIoFunctionData *TdsIoFunctionInfo;

/* Functions in tdstypeio.c */
extern void TdsResetCache(void);
extern void TdsLoadTypeFunctionCache(void);
extern TdsIoFunctionInfo TdsLookupTypeFunctionsByOid(Oid typeId, int32* typmod);
extern TdsIoFunctionInfo TdsLookupTypeFunctionsByTdsId(int32_t typeId, 
								int32_t typeLen);

extern StringInfo TdsGetStringInfoBufferFromToken(const char *message,
											const ParameterToken token);
extern StringInfo TdsGetPlpStringInfoBufferFromToken(const char *message,
												const ParameterToken token);
extern void TdsReadUnicodeDataFromTokenCommon(const char *message,
											const ParameterToken token,
											StringInfo temp);
TdsCollationInfo TdsLookupCollationByOid(Oid cId);
extern void TdsLoadEncodingLCIDCache(void);
extern int TdsLookupEncodingByLCID(int LCID);
extern int TdsSendTypeBit(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeTinyint(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeSmallint(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeInteger(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeBigint(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeFloat4(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeFloat8(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeVarchar(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeNVarchar(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeMoney(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeSmallmoney(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeChar(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeNChar(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeSmalldatetime(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeText(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeNText(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeDate(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeDatetime(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeNumeric(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeSmalldatetime(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeImage(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeBinary(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeVarbinary(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeUniqueIdentifier(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeTime(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeDatetime2(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeXml(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeSqlvariant(FmgrInfo *finfo, Datum value, void *vMetaData);
extern int TdsSendTypeDatetimeoffset(FmgrInfo *finfo, Datum value, void *vMetaData);

extern Datum TdsRecvTypeBit(const char *, const ParameterToken);
extern Datum TdsRecvTypeTinyInt(const char *, const ParameterToken);
extern Datum TdsRecvTypeSmallInt(const char *, const ParameterToken);
extern Datum TdsRecvTypeInteger(const char *, const ParameterToken);
extern Datum TdsRecvTypeBigInt(const char *, const ParameterToken);
extern Datum TdsRecvTypeFloat4(const char *, const ParameterToken);
extern Datum TdsRecvTypeFloat8(const char *, const ParameterToken);
extern Datum TdsRecvTypeVarchar(const char *, const ParameterToken);
extern Datum TdsRecvTypeNVarchar(const char *, const ParameterToken);
extern Datum TdsRecvTypeMoney(const char *, const ParameterToken);
extern Datum TdsRecvTypeSmallmoney(const char *, const ParameterToken);
extern Datum TdsRecvTypeChar(const char *, const ParameterToken);
extern Datum TdsRecvTypeNChar(const char *, const ParameterToken);
extern Datum TdsRecvTypeText(const char *message, const ParameterToken);
extern Datum TdsRecvTypeNText(const char *message, const ParameterToken);
extern Datum TdsRecvTypeDate(const char *message, const ParameterToken);
extern Datum TdsRecvTypeDatetime(const char *message, const ParameterToken);
extern Datum TdsRecvTypeNumeric(const char *message, const ParameterToken);
extern Datum TdsRecvTypeSmalldatetime(const char *, const ParameterToken);
extern Datum TdsRecvTypeImage(const char *, const ParameterToken);
extern Datum TdsRecvTypeBinary(const char *message, const ParameterToken);
extern Datum TdsRecvTypeVarbinary(const char *message, const ParameterToken);
extern Datum TdsRecvTypeUniqueIdentifier(const char *, const ParameterToken);
extern Datum TdsRecvTypeTime(const char *message, const ParameterToken);
extern Datum TdsRecvTypeDatetime2(const char *message, const ParameterToken);
extern Datum TdsRecvTypeXml(const char *, const ParameterToken);
extern Datum TdsRecvTypeTable(const char *, const ParameterToken);
extern Datum TdsRecvTypeSqlvariant(const char *message, const ParameterToken);
extern Datum TdsRecvTypeDatetimeoffset(const char *message, const ParameterToken);

extern Datum TdsTypeBitToDatum(StringInfo buf);
extern Datum TdsTypeIntegerToDatum(StringInfo buf, int maxLen);
extern Datum TdsTypeFloatToDatum(StringInfo buf, int maxLen);
extern Datum TdsTypeVarcharToDatum(StringInfo buf, pg_enc encoding, uint8_t tdsColDataType);
extern Datum TdsTypeNCharToDatum(StringInfo buf);
extern Datum TdsTypeNumericToDatum(StringInfo buf, int scale);
extern Datum TdsTypeVarbinaryToDatum(StringInfo buf);
extern Datum TdsTypeDatetime2ToDatum(StringInfo buf, int scale, int len);
extern Datum TdsTypeDatetimeToDatum(StringInfo buf);
extern Datum TdsTypeSmallDatetimeToDatum(StringInfo buf);
extern Datum TdsTypeDateToDatum(StringInfo buf);
extern Datum TdsTypeTimeToDatum(StringInfo buf, int scale, int len);
extern Datum TdsTypeDatetimeoffsetToDatum(StringInfo buf, int scale, int len);
extern Datum TdsTypeMoneyToDatum(StringInfo buf);
extern Datum TdsTypeSmallMoneyToDatum(StringInfo buf);
extern Datum TdsTypeXMLToDatum(StringInfo buf);
extern Datum TdsTypeUIDToDatum(StringInfo buf);
extern Datum TdsTypeSqlVariantToDatum(StringInfo buf);

#endif	/* TDS_TYPEIO_H */
