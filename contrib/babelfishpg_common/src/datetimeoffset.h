/*-------------------------------------------------------------------------
 *
 * datetimeoffset.h
 *	  Definitions for the TSQL "datetimeoffset" type.
 *
 *-------------------------------------------------------------------------
 */
#ifndef DATETIMEOFFSET_H
#define DATETIMEOFFSET_H
#include "fmgr.h" // check if necessary
#include "utils/timestamp.h"

/* datetimeoffset size in bytes */
#define DATETIMEOFFSET_LEN MAXALIGN(sizeof(tsql_datetimeoffset))
/* datetimeoffset default value in internal representation */
#define DATETIMEOFFSET_DEFAULT_TS -3155673600000000
/* datetimeoffset timezone limit, it is valid for -14:00 to +14:00
 * So the limit to mins will be 14*60+1 = 841
 */
#define DATETIMEOFFSET_TIMEZONE_LIMIT 841

#define DATETIMEOFFSET_MAX INT64CONST(252455616000000000)

extern void AdjustTimestampForSmallDatetime(Timestamp *time);
extern void CheckSmalldatetimeRange(const Timestamp time);
extern void CheckDatetimeRange(const Timestamp time);
extern void CheckDatetime2Range(const Timestamp time);
extern Datum timestamptz_datetimeoffset(TimestampTz timestamp);
extern Datum timestamptz_datetime2(PG_FUNCTION_ARGS);
extern Datum timestamptz_datetime(PG_FUNCTION_ARGS);
extern Datum datetimeoffset_timestamp(PG_FUNCTION_ARGS);
typedef struct tsql_datetimeoffset
{
	int64		tsql_ts;
	int16		tsql_tz;
} tsql_datetimeoffset;

/* fmgr interface macros */
#define DatetimeoffsetGetDatum(X) PointerGetDatum(X)
#define PG_RETURN_DATETIMEOFFSET(X) return DatetimeoffsetGetDatum(X)
#define DatumGetDatetimeoffset(X) ((tsql_datetimeoffset *) DatumGetPointer(X))
#define PG_GETARG_DATETIMEOFFSET(X) DatumGetDatetimeoffset(PG_GETARG_DATUM(X))

#endif							/* DATETIMEOFFSET_H */
