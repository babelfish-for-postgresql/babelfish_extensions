#ifndef VARCHAR_H
#define VARCHAR_H

#include "postgres.h"

extern int32_t GetUTF8CodePoint(const unsigned char *in, int len, int *consumed_p);
extern void *tsql_varchar_input(const char *s, size_t len, int32 atttypmod);
extern void *tsql_bpchar_input(const char *s, size_t len, int32 atttypmod);

#endif
