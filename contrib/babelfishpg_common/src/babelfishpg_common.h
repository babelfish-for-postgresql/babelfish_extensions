#include "postgres.h"

#include "fmgr.h"

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
	Datum		(*tinyint2sqlvariant) (PG_FUNCTION_ARGS);
	Datum		(*translate_pg_type_to_tsql) (PG_FUNCTION_ARGS);
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
	int32_t		(*GetUTF8CodePoint) (const unsigned char *in, int len, int *consumed_p);

} common_utility_plugin;
