#include "postgres.h"

#include "fmgr.h"
#include "utils/timestamp.h"

/*
 * Casting float < -1.0 to unsigned integer could cause issues on ARM.
 *
 * For instance:
 *     auto fvalue = -176.0;
 *     auto tvalue = static_cast<uint16_t>(fvalue);
 *     On Intel, tvalue = 65360 which is correct.
 *     On ARM, tvalue = 0 which is wrong.
 *
 * Hence the compiler flag -Wfloat-conversion has been added to BBF Makefiles
 * to guard the codebase from this bug.
 *
 * However, float-conversion is not too granular enough because it also
 * flags things like float8 to float4 conversion or conversions where the
 * original value is always greater than or equal to zero.
 * For code that are being flagged but are not really an issue, we can suppress
 * the compilation error by surrounding them with _Pragma().
 */
#define BBF_Pragma_IgnoreFloatConversionWarning_Push \
    _Pragma("GCC diagnostic push") \
    _Pragma("GCC diagnostic ignored \"-Wfloat-conversion\"")

#define BBF_Pragma_IgnoreFloatConversionWarning_Pop \
    _Pragma("GCC diagnostic pop")

typedef enum TdsAtAtVarType 
{
  RCOUNT_TYPE, 
  ERR_TYPE, 
  TRANCOUNT_TYPE
} TdsAtAtVarType;

typedef struct common_utility_plugin
{
	/* Function pointers set up by the plugin */
	bytea	   *(*convertVarcharToSQLVariantByteA) (VarChar *vch, Oid coll);
	bytea	   *(*convertIntToSQLVariantByteA) (int ret);
	void	   *(*tsql_varchar_input) (const char *s, size_t len, int32 atttypmod);
	void	   *(*tsql_bpchar_input) (const char *s, size_t len, int32 atttypmod);
	bool		(*is_tsql_bpchar_datatype) (Oid oid);
	bool		(*is_tsql_nchar_datatype) (Oid oid);
	bool		(*is_tsql_varchar_datatype) (Oid oid);
	bool		(*is_tsql_nvarchar_datatype) (Oid oid);
	bool		(*is_tsql_text_datatype) (Oid oid);
	bool		(*is_tsql_ntext_datatype) (Oid oid);
	bool		(*is_tsql_image_datatype) (Oid oid);
	bool		(*is_tsql_binary_datatype) (Oid oid);
	bool		(*is_tsql_sys_binary_datatype) (Oid oid);
	bool		(*is_tsql_sys_varbinary_datatype) (Oid oid);
	bool		(*is_tsql_varbinary_datatype) (Oid oid);
	bool		(*is_tsql_timestamp_datatype) (Oid oid);
	bool		(*is_tsql_datetime2_datatype) (Oid oid);
	bool		(*is_tsql_smalldatetime_datatype) (Oid oid);
	bool		(*is_tsql_datetimeoffset_datatype) (Oid oid);
	bool		(*is_tsql_decimal_datatype) (Oid oid);
	bool		(*is_tsql_rowversion_or_timestamp_datatype) (Oid oid);
	Datum		(*datetime_in_str) (char *str);
	Datum		(*datetime2sqlvariant) (PG_FUNCTION_ARGS);
	Datum		(*timestamptz_datetimeoffset) (TimestampTz timestamp);
	Datum		(*timestamptz_datetime2) (PG_FUNCTION_ARGS);
	Datum		(*timestamptz_datetime) (PG_FUNCTION_ARGS);
	Datum		(*datetimeoffset_timestamp) (PG_FUNCTION_ARGS);
	Datum		(*tinyint2sqlvariant) (PG_FUNCTION_ARGS);
	Datum		(*translate_pg_type_to_tsql) (PG_FUNCTION_ARGS);
	Oid		(*get_tsql_datatype_oid) (char *type_name);
	void		(*TdsGetPGbaseType) (uint8 variantBaseType, int *pgBaseType, int tempLen,
									 int *dataLen, int *variantHeaderLen);
	void		(*TdsSetMetaData) (bytea *result, int pgBaseType, int scale,
								   int precision, int maxLen);
	int			(*TdsPGbaseType) (bytea *vlena);
	void		(*TdsGetMetaData) (bytea *result, int pgBaseType, int *scale,
								   int *precision, int *maxLen);
	void		(*TdsGetVariantBaseType) (int pgBaseType, int *variantBaseType,
										  bool *isBaseNum, bool *isBaseChar,
										  bool *isBaseDec, bool *isBaseBin,
										  bool *isBaseDate, int *variantHeaderLen);
	Oid			(*lookup_tsql_datatype_oid) (const char *typestr);
	const char	   	*(*resolve_pg_type_to_tsql) (Oid oid);
	int32_t		(*GetUTF8CodePoint) (const unsigned char *in, int len, int *consumed_p);
	int			(*TsqlUTF8LengthInUTF16) (const void *vin, int len);
} common_utility_plugin;
