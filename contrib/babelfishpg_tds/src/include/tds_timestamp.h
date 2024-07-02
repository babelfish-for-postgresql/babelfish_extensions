/*-------------------------------------------------------------------------
 *
 * tds_timestamp.h
 *	  Definitions of handler functions for TDS timestamp datatype
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/tds/tds_timestamp.h
 *
 *-------------------------------------------------------------------------
 */
#include "utils/date.h"
#include "utils/timestamp.h"

#define DATETIMEOFFSETMAXSCALE 7

extern void TdsGetTimestampFromDayTime(uint32 numDays, uint64 numMicro, int tz,
									   Timestamp *timestamp, int scale);
extern void TdsGetDayTimeFromTimestamp(Timestamp value, uint32 *numDays,
									   uint64 *numSec, int scale);

extern void TdsTimeDifferenceSmalldatetime(Datum value, uint16 *numDays,
										   uint16 *numMins);
extern void TdsTimeGetDatumFromSmalldatetime(uint16 numDays, uint16 numMins,
											 Timestamp *timestamp);
extern uint32 TdsDayDifference(Datum value);
extern void TdsTimeDifferenceDatetime(Datum value, uint32 *numDays,
									  uint32 *numTicks);
extern void TdsCheckDateValidity(DateADT result);
extern void TdsTimeGetDatumFromDays(uint32 numDays, uint64 *val);
extern void TdsTimeGetDatumFromDatetime(uint32 numDays, uint32 numTicks,
										Timestamp *timestamp);
extern uint32 TdsGetDayDifferenceHelper(int day, int mon, int year, bool isDateType);
extern char* TdsTimeGetDateAsString(Datum value);
extern char* TdsTimeGetTimeAsString(TimeADT value, int scale);
extern char* TdsTimeGetDatetime2AsString(Timestamp value, int scale);

/*
 *  structure for datatimeoffset support with separate time zone field
 */
typedef struct tsql_datetimeoffset
{
	int64		tsql_ts;
	int16		tsql_tz;
} tsql_datetimeoffset;

extern char* TdsTimeGetDatetimeoffsetAsString(tsql_datetimeoffset *value, int scale);

/* datetimeoffset macros */
#define DATETIMEOFFSET_LEN MAXALIGN(sizeof(tsql_datetimeoffset))
/* datetimeoffset default value in internal representation */
#define DatetimeoffsetGetDatum(X) PointerGetDatum(X)
#define PG_RETURN_DATETIMEOFFSET(X) return DatetimeoffsetGetDatum(X)
