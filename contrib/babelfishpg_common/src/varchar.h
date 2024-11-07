#ifndef VARCHAR_H
#define VARCHAR_H

#include "postgres.h"

extern int32_t GetUTF8CodePoint(const unsigned char *in, int len, int *consumed_p);
extern void AddUTF16ToStringInfo(int32_t code, StringInfo buf);
extern void *tsql_varchar_input(const char *s, size_t len, int32 atttypmod);
extern void *tsql_bpchar_input(const char *s, size_t len, int32 atttypmod);
extern int  TsqlUTF8LengthInUTF16(const void *vin, int len);
extern void TsqlUTF8toUTF16StringInfo(StringInfo out, const void *vin, size_t len);
extern bool is_basetype_nchar_nvarchar(Oid typid);
extern void tsql_utf8_to_utf16(StringInfoData *utf16_data, const uint8 *data, size_t len);
#endif
