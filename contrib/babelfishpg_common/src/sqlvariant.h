#ifndef SQLVARIANT_H
#define SQLVARIANT_H

/*
 * macros for supporting sqlvariant datatype on TDS side
 */

#define VARIANT_TYPE_TINYINT        48
#define VARIANT_TYPE_BIT        50
#define VARIANT_TYPE_SMALLINT       52
#define VARIANT_TYPE_INT        56
#define VARIANT_TYPE_BIGINT     127
#define VARIANT_TYPE_REAL       59
#define VARIANT_TYPE_FLOAT      62
#define VARIANT_TYPE_NUMERIC        108
#define VARIANT_TYPE_DECIMAL 	106
#define VARIANT_TYPE_MONEY      60
#define VARIANT_TYPE_SMALLMONEY     122
#define VARIANT_TYPE_DATE       40
#define VARIANT_TYPE_CHAR       175
#define VARIANT_TYPE_VARCHAR        167
#define VARIANT_TYPE_NCHAR      239
#define VARIANT_TYPE_NVARCHAR       231
#define VARIANT_TYPE_BINARY     173
#define VARIANT_TYPE_VARBINARY      165
#define VARIANT_TYPE_UNIQUEIDENTIFIER   36
#define VARIANT_TYPE_TIME       41
#define VARIANT_TYPE_SMALLDATETIME  58
#define VARIANT_TYPE_DATETIME       61
#define VARIANT_TYPE_DATETIME2      42
#define VARIANT_TYPE_DATETIMEOFFSET 43

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

/*  Header version
 *  For now, we assume that headers of all types use Header Version 1.
 *  However, in future we may want to define header versions for each types,
 *  for example we may want to store addional data for a type.
 *  As of now there's no use cases where we could use that.
 */
#define HDR_VER 1

/*  Header related macros  */
#define SV_HDR_1B(PTR) ((svhdr_1B_t *) (VARDATA_ANY(PTR)))
#define SV_HDR_2B(PTR) ((svhdr_2B_t *) (VARDATA_ANY(PTR)))
#define SV_HDR_3B(PTR) ((svhdr_3B_t *) (VARDATA_ANY(PTR)))
#define SV_HDR_5B(PTR) ((svhdr_5B_t *) (VARDATA_ANY(PTR)))

#define SV_GET_TYPCODE(HEADER) (HEADER->metadata >> 3)
#define SV_GET_TYPCODE_PTR(PTR) (SV_HDR_1B(PTR)->metadata >> 3)
#define SV_GET_MDVER(HEADER) (HEADER->metadata & 0x07)
#define SV_SET_METADATA(HEADER, TYPCODE, MDVER) (HEADER->metadata = TYPCODE << 3 | MDVER)

#define SV_DATA(PTR, SVHDR) (VARDATA_ANY(PTR) + SVHDR)
#define SV_DATUM(PTR, SVHDR) ((Datum) (VARDATA_ANY(PTR) + SVHDR))
#define SV_DATUM_PTR(PTR, SVHDR) ((Datum *) (VARDATA_ANY(PTR) + SVHDR))

#define SV_CAN_USE_SHORT_VALENA(DATALEN, SVHDR) (DATALEN + SVHDR + VARHDRSZ_SHORT <= VARATT_SHORT_MAX)


/*
 *              Storage Layout of SQL_VARIANT Header
 *  Total length 2-9 bytes : varlena header (1-4B) + sv header (1-5B)
 *  Bytes are interpreted differently for different types
 *  WARNING: Modification on storage layout need backward compatibility support
 *  Place holders MUST filled with 0 to avoid ambiguity in the future
 */

/* HDR: Basic format
 * following custom of PG, typmod is stored
 * It could be interpreted differently for difffernt types
 * e.g
 * for decimal types, precision and scale are encoded
 * for datetime2, datetimeoffset it is scale
 */
typedef struct __attribute__((packed)) svhdr_1B
{
    uint8_t metadata;
} svhdr_1B_t;

typedef struct __attribute__((packed)) svhdr_2B
{
    uint8_t metadata;
    int8_t typmod;
} svhdr_2B_t;

typedef struct __attribute__((packed)) svhdr_3B
{
    uint8_t metadata;
    int16_t typmod;
} svhdr_3B_t;

typedef struct __attribute__((packed)) svhdr_5B
{
    uint8_t  metadata;
    int16_t  typmod;
    uint16_t collid;
} svhdr_5B_t;

extern bytea *gen_sqlvariant_bytea_from_type_datum(size_t typcode, Datum data);
extern bytea *convertVarcharToSQLVariantByteA(VarChar *vch, Oid coll);
extern bytea *convertIntToSQLVariantByteA(int ret);
extern Datum datetime2sqlvariant(PG_FUNCTION_ARGS);
extern Datum tinyint2sqlvariant(PG_FUNCTION_ARGS);
extern void TdsGetPGbaseType(uint8 variantBaseType, int *pgBaseType, int tempLen,
					int *dataLen, int *variantHeaderLen);
extern void TdsSetMetaData(bytea *result, int pgBaseType, int scale,
						int precision, int maxLen);
extern int TdsPGbaseType(bytea *vlena);
extern void TdsGetMetaData(bytea *result, int pgBaseType, int *scale,
                                        int *precision, int *maxLen);
extern void TdsGetVariantBaseType(int pgBaseType, int *variantBaseType,
                                     bool *isBaseNum, bool *isBaseChar,
                                     bool *isBaseDec, bool *isBaseBin,
                                     bool *isBaseDate, int *variantHeaderLen);

#endif