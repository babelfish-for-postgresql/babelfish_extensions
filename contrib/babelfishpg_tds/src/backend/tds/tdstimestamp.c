/*-------------------------------------------------------------------------
 *
 * tdstimestamp.c
 *	  Handler functions for TDS timestamp datatype
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdstimestamp.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "utils/datetime.h"

#include "src/include/tds_timestamp.h"

int			DaycountInMonth[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
static inline
int
IsLeap(int y)
{
	if ((y % 100 != 0 && y % 4 == 0) || y % 400 == 0)
		return 1;

	return 0;
}

void
TdsCheckDateValidity(DateADT result)
{
	/* Limit to the same range that date_in() accepts. */
	if (DATE_NOT_FINITE(result) || (!IS_VALID_DATE(result)))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("date out of range")));
}

static inline int
CountLeapYears(struct pg_tm *t)
{
	int			years = t->tm_year;

	if (t->tm_mon <= 2)
		years--;

	return years / 4 - years / 100 + years / 400;
}

static inline int
GetDayDifference(struct pg_tm *t1, struct pg_tm *t2)
{
	long int	n1,
				n2;
	int			i;

	n1 = t1->tm_year * 365 + t1->tm_mday;
	for (i = 0; i < t1->tm_mon - 1; i++)
		n1 += DaycountInMonth[i];
	n1 += CountLeapYears(t1);

	n2 = t2->tm_year * 365 + t2->tm_mday;
	for (i = 0; i < t2->tm_mon - 1; i++)
		n2 += DaycountInMonth[i];
	n2 += CountLeapYears(t2);

	return (n2 - n1);
}

uint32
TdsGetDayDifferenceHelper(int day, int mon, int year, bool isDateType)
{
	uint32		numDays = 0;
	struct pg_tm tj,
				ti,
			   *tm = &ti,
			   *tt = &tj;

	tm->tm_mday = day, tm->tm_mon = mon, tm->tm_year = year;
	tt->tm_mday = 1, tt->tm_mon = 1;
	if (isDateType)
		tt->tm_year = 1;
	else
		tt->tm_year = 1900;
	numDays = GetDayDifference(tt, tm);
	return numDays;
}

static inline void
GetDateFromDatum(Datum date, struct pg_tm *tm)
{
	if (!DATE_NOT_FINITE(date))
	{
		j2date(date + POSTGRES_EPOCH_JDATE,
			   &(tm->tm_year), &(tm->tm_mon), &(tm->tm_mday));
	}
	else
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("date out of range")));
}

static inline void
GetDatetimeFromDatum(Datum value, fsec_t * fsec, struct pg_tm *tm)
{
	Timestamp	timestamp = (Timestamp) value;

	if (TIMESTAMP_NOT_FINITE(timestamp) ||
		timestamp2tm(timestamp, NULL, tm, fsec, NULL, NULL) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("Datetime out of range")));
}

/*
 * Get numDays elapsed between client date and 1-1-0001
 */
uint32
TdsDayDifference(Datum value)
{
	uint32		numDays = 0;
	struct pg_tm tj,
				ti,
			   *tm = &ti,
			   *tt = &tj;

	GetDateFromDatum(value, tm);

	tt->tm_mday = 1, tt->tm_mon = 1, tt->tm_year = 1;
	numDays = GetDayDifference(tt, tm);
	return numDays;
}

/*
 * Decides whether the effective date to consider is the next day
 * based on hour, minute, second value 23:59:59
 */
static inline void
GetNumDaysHelper(struct pg_tm *tm)
{
	tm->tm_hour = tm->tm_min = tm->tm_sec = 0;
	if (tm->tm_mday == DaycountInMonth[tm->tm_mon - 1] &&
		tm->tm_mon == 12)
	{
		tm->tm_year++;
		tm->tm_mon = tm->tm_mday = 1;
	}
	else if ((tm->tm_mday == DaycountInMonth[tm->tm_mon - 1] && tm->tm_mon != 2) ||
			 (tm->tm_mon == 2 && tm->tm_mday == 29 && IsLeap(tm->tm_year)) ||
			 (tm->tm_mon == 2 && tm->tm_mday == 28 && !IsLeap(tm->tm_year)))
	{
		tm->tm_mon++;
		tm->tm_mday = 1;
	}
	else
		tm->tm_mday++;
}

/*
 * Returns numDays and numTicks elapsed between given date
 * and 1-1-1900
 */
void
TdsTimeDifferenceSmalldatetime(Datum value, uint16 *numDays,
							   uint16 *numMins)
{
	struct pg_tm tj,
				ti,
			   *tm = &ti,
			   *tt = &tj;
	fsec_t		fsec = 0;

	GetDatetimeFromDatum(value, &fsec, tm);
	tt->tm_mday = 1, tt->tm_mon = 1, tt->tm_year = 1900;

	*numDays = (uint16) GetDayDifference(tt, tm);

	if (tm->tm_hour == 23 && tm->tm_min == 59 && tm->tm_sec == 59)
	{
		fsec = 0;
		GetNumDaysHelper(tm);
		(*numDays)++;
	}
	else if ((tm->tm_sec == 29 && (fsec / 1000) > 998) || tm->tm_sec > 29)
		tm->tm_min++;

	tm->tm_sec = 0;
	*numMins = (tm->tm_hour * 60) + tm->tm_min;
}

/*
 * Returns numDays and numTicks elapsed between given date
 * and 1-1-1900
 */
void
TdsTimeDifferenceDatetime(Datum value, uint32 *numDays,
						  uint32 *numTicks)
{
	uint32		milliCount = 0;
	struct pg_tm tj,
				ti,
			   *tm = &ti,
			   *tt = &tj;
	fsec_t		fsec;
	int			msec = 0,
				unit = 0,
				round_val = 0;

	/*
	 * 1 tick = 1/300 sec = 3.3333333 ms babelfish uses tick count to
	 * accommodate millisecound count in 4 bytes
	 */
	double		tick = 3.3333333;

	GetDatetimeFromDatum(value, &fsec, tm);
	tt->tm_mday = 1, tt->tm_mon = 1, tt->tm_year = 1900;

	*numDays = GetDayDifference(tt, tm);

	if (tm->tm_hour == 23 && tm->tm_min == 59 && tm->tm_sec == 59 &&
		fsec == 999000)
	{
		msec = 0;
		GetNumDaysHelper(tm);
		(*numDays)++;
	}
	else
	{
		msec = (fsec / 1000);
		unit = msec % 10;

		/*
		 * millisecond value rounded to increments of .000, .003, or .007
		 * seconds
		 */
		switch (unit)
		{
			case 0:
			case 1:
				round_val = 0;
				break;
			case 2:
			case 3:
			case 4:
				round_val = 3;

				/*
				 * slightly different from default tick value at 7th decimal
				 * place
				 */
				tick = 3.3333332;
				break;
			case 5:
			case 6:
			case 7:
			case 8:
				round_val = 7;
				break;
			case 9:
				round_val = 10;
				break;
			default:
				break;
		}
		msec = msec - unit + round_val;
	}
	milliCount = ((tm->tm_hour * 60 + tm->tm_min) * 60 +
				  tm->tm_sec) * 1000 + msec;

	*numTicks = (int) (milliCount / tick);
}

/*
 * Given a year and days elapsed in it, outputs month and
 * day of the date found by adding offset #days to day1
 */
static inline
void
RevoffsetDays(int offset, int *y, int *d, int *m)
{
	int			month[13] = {0, 31, 28, 31, 30, 31, 30,
	31, 31, 30, 31, 30, 31};
	int			i;

	if (IsLeap(*y))
		month[2] = 29;

	for (i = 1; i <= 12; i++)
	{
		if (offset <= month[i])
			break;
		offset = offset - month[i];
	}
	*d = offset;
	*m = i;
}

/*
 * Adds x days to specific start date(1.1.0001 or 1.1.1900) in order to
 * retrieve target client date
 */
static inline
void
CalculateTargetDate(int y1, int *d2, int *m2, int *y2, int x)
{
	int			y2days = 0;
	int			offset1 = 1;
	int			remDays = IsLeap(y1) ? (366 - offset1) : (365 - offset1);

	int			offset2;

	if (x <= remDays)
	{
		*y2 = y1;
		offset2 = offset1 + x;
	}
	else
	{
		x -= remDays;
		*y2 = y1 + 1;
		y2days = IsLeap(*y2) ? 366 : 365;
		while (x >= y2days)
		{
			x -= y2days;
			(*y2)++;
			y2days = IsLeap(*y2) ? 366 : 365;
		}
		offset2 = x;
	}

	RevoffsetDays(offset2, y2, d2, m2);
}

/*
 * Get date info(day, month, year) from numDays elapsed from
 * 1-1-0001.
 */
void
TdsTimeGetDatumFromDays(uint32 numDays, uint64 *val)
{
	int			y1 = 1;
	int			d2 = 0,
				m2 = 0,
				y2 = 0;
	int			res;
	struct pg_tm ti,
			   *tm = &ti;

	CalculateTargetDate(y1, &d2, &m2, &y2, numDays);
	tm->tm_mday = d2;
	tm->tm_mon = m2;
	tm->tm_year = y2;

	res = date2j(tm->tm_year, tm->tm_mon, tm->tm_mday);
	res -= POSTGRES_EPOCH_JDATE;
	*val = (uint64) res;
}

/*
 * Get date info(day, month, year) from numDays elapsed from
 * 1-1-1900.
 * Get time info from number of ticks (milliseconds/3.33333333)
 * elapsed.
 */
static inline
void
GetDatetimeFromDaysTicks(uint32 numDays, uint32 numTicks,
						 struct pg_tm *tm, fsec_t * fsec)
{
	int			y1 = 1900;
	int			d2 = 0,
				m2 = 0,
				y2 = 0;
	int			min,
				hour,
				sec,
				numMilli = 0;

	CalculateTargetDate(y1, &d2, &m2, &y2, numDays);

	numMilli = 3.33333333 * numTicks;
	*fsec = (numMilli % 1000) * 1000;
	numMilli /= 1000;

	/*
	 * need explicit assignment for JDBC prep-exec query where time datatype
	 * is sent as datetime in case sendTimeAsDateTime parameter is not
	 * explicitly set to false
	 */
	if (*fsec == 999000)
	{
		numMilli++;
		*fsec = 0;
	}

	sec = numMilli % 60;
	numMilli /= 60;
	min = numMilli % 60;
	numMilli /= 60;
	hour = numMilli;

	tm->tm_mday = d2;
	tm->tm_mon = m2;
	tm->tm_year = y2;
	tm->tm_hour = hour;
	tm->tm_min = min;
	tm->tm_sec = sec;
}

/*
 * Get hour, min, sec, millisecond, date info from numDays elapsed from 1-1-1900 and
 * numTicks (= numMilliSecond / 3.3333333) elapsed from 12AM of that day.
 * Also, do necessary millisecond adjustment before storing client datetime in system.
 * Ex.- 1955-12-13 23:59:59.999 is stored as 1955-12-14 0:0:0.0
 */
void
TdsTimeGetDatumFromDatetime(uint32 numDays, uint32 numTicks,
							Timestamp *timestamp)
{
	struct pg_tm ti,
			   *tm = &ti;
	fsec_t		fsec;

	GetDatetimeFromDaysTicks(numDays, numTicks, tm, &fsec);
	if (tm2timestamp(tm, fsec, NULL, timestamp) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
}

static inline
void
GetDatetimeFromDaysMins(uint16 numDays, uint16 numMins,
						struct pg_tm *tm, fsec_t * fsec)
{
	int			y1 = 1900;
	int			d2 = 0,
				m2 = 0,
				y2 = 0;
	int			min,
				hour;

	CalculateTargetDate(y1, &d2, &m2, &y2, numDays);

	min = numMins % 60;
	numMins /= 60;
	hour = numMins;

	tm->tm_mday = d2;
	tm->tm_mon = m2;
	tm->tm_year = y2;
	tm->tm_hour = hour;
	tm->tm_min = min;
}

/*
 * Get hour, min, date info from numDays elapsed from 1-1-1900
 */
void
TdsTimeGetDatumFromSmalldatetime(uint16 numDays, uint16 numMins,
								 Timestamp *timestamp)
{
	struct pg_tm ti,
			   *tm = &ti;
	fsec_t		fsec = 0;

	GetDatetimeFromDaysMins(numDays, numMins, tm, &fsec);
	tm->tm_sec = 0;
	if (tm2timestamp(tm, fsec, NULL, timestamp) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
}

void
TdsGetDayTimeFromTimestamp(Timestamp value, uint32 *numDays, uint64 *numSec,
						   int scale)
{
	struct pg_tm ti,
				tj,
			   *tm = &ti,
			   *tt = &tj;
	fsec_t		fsec = 0;
	double		res = 0;

	if (timestamp2tm((Timestamp) value, NULL, tm, &fsec, NULL, NULL) != 0)
		ereport(ERROR, (errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("timestamp out of range")));

	tt->tm_mday = 1, tt->tm_mon = 1, tt->tm_year = 1;
	*numDays = (uint32) GetDayDifference(tt, tm);

	res = (double) (((tm->tm_hour * 60 + tm->tm_min) * 60 + tm->tm_sec) +
					((double) fsec / 1000000));
	while (scale--)
		res *= 10;
	/* Round res to the nearest integer */
	res += 0.5;

	*numSec = (uint64_t) res;
}

void
TdsGetTimestampFromDayTime(uint32 numDays, uint64 numMicro, int tz,
						   Timestamp *timestamp, int scale)
{
	struct pg_tm ti,
			   *tm = &ti;
	fsec_t		fsec;
	int			y1 = 1;
	int			d2 = 0,
				m2 = 0,
				y2 = 0,
				min,
				hour,
				sec;
	double result;

	CalculateTargetDate(y1, &d2, &m2, &y2, numDays);

	result = (double) numMicro;

	while (scale--)
		result	  /=10;
	result	   *= 1000000;

	/*
	 * Casting result to unint64_t will always round it down to the nearest
	 * integer (similar to what floor() does). Instead, we should round it to
	 * the nearest integer.
	 */
	numMicro = (result -(uint64_t) result <=0.5) ? (uint64_t) result : (uint64_t) result +1;

	fsec = numMicro % 1000000;
	numMicro /= 1000000;
	sec = numMicro % 60;
	numMicro /= 60;
	min = numMicro % 60;
	numMicro /= 60;
	hour = numMicro;

	tm->tm_mday = d2;
	tm->tm_mon = m2;
	tm->tm_year = y2;
	tm->tm_hour = hour;
	tm->tm_min = min;
	tm->tm_sec = sec;

	if (tm2timestamp(tm, fsec, &tz, timestamp) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
}
