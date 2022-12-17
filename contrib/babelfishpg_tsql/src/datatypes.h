#include "utils/numeric.h"

/* Functions in datatypes/numeric.c */
extern Numeric tsql_set_var_from_str_wrapper(const char *str);
extern int32_t tsql_numeric_get_typmod(Numeric num);

/* Functions in datatypes/varchar.c */
extern void *tsql_varchar_input(const char *s, size_t len, int32 atttypmod);
extern void *tsql_bpchar_input(const char *s, size_t len, int32 atttypmod);

/* Defined in typecode.c */
extern Oid lookup_tsql_datatype_oid(const char *typename);
extern bool is_tsql_bpchar_datatype(Oid oid);
extern bool is_tsql_nchar_datatype(Oid oid);
extern bool is_tsql_varchar_datatype(Oid oid);
extern bool is_tsql_nvarchar_datatype(Oid oid);
extern bool is_tsql_text_datatype(Oid oid);
extern bool is_tsql_ntext_datatype(Oid oid);
extern bool is_tsql_image_datatype(Oid oid);
extern bool is_tsql_binary_datatype(Oid oid);
extern bool is_tsql_varbinary_datatype(Oid oid);
extern bool is_tsql_datetime2_datatype(Oid oid);
extern bool is_tsql_smalldatetime_datatype(Oid oid);
extern bool is_tsql_datetimeoffset_datatype(Oid oid);
extern bool is_tsql_timestamp_datatype(Oid oid);
extern bool is_tsql_decimal_datatype(Oid oid);
