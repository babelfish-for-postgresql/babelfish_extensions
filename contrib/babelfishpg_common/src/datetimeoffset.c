/*-------------------------------------------------------------------------
 *
 * datetimeoffset.c
 *	  Functions for the type "datetimeoffset".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "access/hash.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "libpq/pqformat.h"
#include "utils/timestamp.h"

#include "fmgr.h"
#include "miscadmin.h"
#include "datetimeoffset.h"
#include "datetime.h"

static void AdjustDatetimeoffsetForTypmod(Timestamp *time, int32 typmod);
static void CheckDatetimeoffsetRange(const tsql_datetimeoffset *df);
static int	datetimeoffset_cmp_internal(tsql_datetimeoffset *df1, tsql_datetimeoffset *df2);
static void datetimeoffset_timestamp_internal(const tsql_datetimeoffset *df, Timestamp *time);
static void EncodeDatetimeoffsetTimezone(char *str, int tz, int style);

PG_FUNCTION_INFO_V1(datetimeoffset_in);
PG_FUNCTION_INFO_V1(datetimeoffset_out);
PG_FUNCTION_INFO_V1(datetimeoffset_recv);
PG_FUNCTION_INFO_V1(datetimeoffset_send);

PG_FUNCTION_INFO_V1(datetimeoffset_eq);
PG_FUNCTION_INFO_V1(datetimeoffset_ne);
PG_FUNCTION_INFO_V1(datetimeoffset_lt);
PG_FUNCTION_INFO_V1(datetimeoffset_le);
PG_FUNCTION_INFO_V1(datetimeoffset_gt);
PG_FUNCTION_INFO_V1(datetimeoffset_ge);
PG_FUNCTION_INFO_V1(datetimeoffset_cmp);
PG_FUNCTION_INFO_V1(datetimeoffset_larger);
PG_FUNCTION_INFO_V1(datetimeoffset_smaller);

PG_FUNCTION_INFO_V1(datetimeoffset_pl_interval);
PG_FUNCTION_INFO_V1(datetimeoffset_mi_interval);
PG_FUNCTION_INFO_V1(interval_pl_datetimeoffset);
PG_FUNCTION_INFO_V1(datetimeoffset_mi);

PG_FUNCTION_INFO_V1(datetimeoffset_hash);
PG_FUNCTION_INFO_V1(datetimeoffset_hash_extended);

PG_FUNCTION_INFO_V1(timestamp_datetimeoffset);
PG_FUNCTION_INFO_V1(datetimeoffset_timestamp);
PG_FUNCTION_INFO_V1(date_datetimeoffset);
PG_FUNCTION_INFO_V1(datetimeoffset_date);
PG_FUNCTION_INFO_V1(time_datetimeoffset);
PG_FUNCTION_INFO_V1(datetimeoffset_time);
PG_FUNCTION_INFO_V1(smalldatetime_datetimeoffset);
PG_FUNCTION_INFO_V1(datetimeoffset_smalldatetime);
PG_FUNCTION_INFO_V1(datetime_datetimeoffset);
PG_FUNCTION_INFO_V1(datetimeoffset_datetime);
PG_FUNCTION_INFO_V1(datetime2_datetimeoffset);
PG_FUNCTION_INFO_V1(datetimeoffset_datetime2);
PG_FUNCTION_INFO_V1(datetimeoffset_scale);

PG_FUNCTION_INFO_V1(get_datetimeoffset_tzoffset_internal);


/* datetimeoffset_in()
 * Convert a string to internal form.
 * Most parts of this functions is same as timestamptz_in(),
 * but we store the timezone in a seperate int16 variable.
 */
Datum
datetimeoffset_in(PG_FUNCTION_ARGS)
{
	char	   *str = PG_GETARG_CSTRING(0);

#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	int32		typmod = PG_GETARG_INT32(2);
	tsql_datetimeoffset *datetimeoffset;
	Timestamp	tsql_ts;
	fsec_t		fsec;
	struct pg_tm tt,
			   *tm = &tt;
	int			tz;
	int			dtype;
	int			nf;
	int			dterr;
	char	   *field[MAXDATEFIELDS];
	int			ftype[MAXDATEFIELDS];
	char		workbuf[MAXDATELEN + MAXDATEFIELDS];

	datetimeoffset = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);

	/*
	 * Set input to default '1900-01-01 00:00:00.* 00:00' if empty string
	 * encountered
	 */
	if (*str == '\0')
	{
		tsql_ts = initializeToDefaultDatetime();
		AdjustDatetimeoffsetForTypmod(&tsql_ts, typmod);
		datetimeoffset->tsql_ts = (int64) tsql_ts;
		datetimeoffset->tsql_tz = 0;
		PG_RETURN_DATETIMEOFFSET(datetimeoffset);
	}

	dterr = ParseDateTime(str, workbuf, sizeof(workbuf),
						  field, ftype, MAXDATEFIELDS, &nf);

	if (dterr == 0)
		dterr = DecodeDateTime(field, ftype, nf, &dtype, tm, &fsec, &tz);
	/* dterr == 1 means that input is TIME format(e.g 12:34:59.123) */
	/* initialize other necessary date parts and accept input format */
	if (dterr == 1)
	{
		tm->tm_year = 1900;
		tm->tm_mon = 1;
		tm->tm_mday = 1;
		dterr = 0;
	}
	if (dterr != 0)
		DateTimeParseError(dterr, str, "timestamp with time zone");

	/*
	 * When time zone offset it not specified in input string
	 * DecodeDateTime sets it to the session time zone.
	 * In T-SQL it must default to '+00:00', not to session time zone.
	 */
	if (nf > 0 && ftype[nf - 1] == DTK_TZ)
		datetimeoffset->tsql_tz = (int16) (tz / 60);
	else
		datetimeoffset->tsql_tz = 0;

	tz = 0;
	switch (dtype)
	{
		case DTK_DATE:
			if (tm2timestamp(tm, fsec, &tz, &tsql_ts) != 0)
				ereport(ERROR,
						(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						 errmsg("timestamp out of range: \"%s\"", str)));
			break;

		case DTK_EPOCH:
			tsql_ts = SetEpochTimestamp();
			break;

		case DTK_LATE:
			TIMESTAMP_NOEND(tsql_ts);
			break;

		case DTK_EARLY:
			TIMESTAMP_NOBEGIN(tsql_ts);
			break;

		default:
			elog(ERROR, "unexpected dtype %d while parsing timestamptz \"%s\"",
				 dtype, str);
			TIMESTAMP_NOEND(tsql_ts);
	}
	AdjustDatetimeoffsetForTypmod(&tsql_ts, typmod);
	datetimeoffset->tsql_ts = (int64) tsql_ts;
	CheckDatetimeoffsetRange(datetimeoffset);

	PG_RETURN_DATETIMEOFFSET(datetimeoffset);
}

/* datetimeoffset_out()
 * Convert datetimeoffset to external form.
 */
Datum
datetimeoffset_out(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	char	   *result;
	struct pg_tm tt,
			   *tm = &tt;
	fsec_t		fsec;
	char		buf[MAXDATELEN + 1];
	Timestamp	timestamp;

	timestamp = df->tsql_ts;
	if (timestamp2tm(timestamp, NULL, tm, &fsec, NULL, NULL) == 0)
		EncodeDateTime(tm, fsec, false, 0, NULL, DateStyle, buf);
	else
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("datetimeoffset out of range")));
	EncodeDatetimeoffsetTimezone(buf, df->tsql_tz, DateStyle);
	result = pstrdup(buf);

	PG_RETURN_CSTRING(result);
}

/*
 *		datetimeoffset_recv	- converts external binary format to datetimeoffset
 */
Datum
datetimeoffset_recv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);

#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	int32		typmod = PG_GETARG_INT32(2);
	tsql_datetimeoffset *result;

	result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);

	result->tsql_ts = pq_getmsgint64(buf);

	result->tsql_tz = pq_getmsgint(buf, sizeof(int16));
	/* Check for sane GMT displacement; see notes in datatype/timestamp.h */
	if (result->tsql_tz <= -DATETIMEOFFSET_TIMEZONE_LIMIT || result->tsql_tz >= DATETIMEOFFSET_TIMEZONE_LIMIT)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_TIME_ZONE_DISPLACEMENT_VALUE),
				 errmsg("datetimeoffset time zone out of range")));

	AdjustDatetimeoffsetForTypmod(&(result->tsql_ts), typmod);
	CheckDatetimeoffsetRange(result);

	PG_RETURN_DATETIMEOFFSET(result);
}

/*
 *		datetimeoffset_send	- converts datetimeoffset to external binary format
 */
Datum
datetimeoffset_send(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *datetimeoffset = PG_GETARG_DATETIMEOFFSET(0);
	StringInfoData buffer;

	pq_begintypsend(&buffer);
	pq_sendint64(&buffer, datetimeoffset->tsql_ts);
	pq_sendint16(&buffer, datetimeoffset->tsql_tz);

	PG_RETURN_BYTEA_P(pq_endtypsend(&buffer));
}

/* cast datetimeoffset to timestamp internal representation */
static void
datetimeoffset_timestamp_internal(const tsql_datetimeoffset *df, Timestamp *time)
{
	*time = df->tsql_ts + (int64) df->tsql_tz * SECS_PER_MINUTE * USECS_PER_SEC;
}

/*
 * This function converts datetimeoffset to timestamp and do the comparision.
 */
static int
datetimeoffset_cmp_internal(tsql_datetimeoffset *df1, tsql_datetimeoffset *df2)
{
	Timestamp	t1;
	Timestamp	t2;

	datetimeoffset_timestamp_internal(df1, &t1);
	datetimeoffset_timestamp_internal(df2, &t2);

	return (t1 < t2) ? -1 : ((t1 > t2) ? 1 : 0);
}

Datum
datetimeoffset_eq(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);

	PG_RETURN_BOOL(datetimeoffset_cmp_internal(df1, df2) == 0);
}

Datum
datetimeoffset_ne(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);

	PG_RETURN_BOOL(datetimeoffset_cmp_internal(df1, df2) != 0);
}

Datum
datetimeoffset_lt(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);

	PG_RETURN_BOOL(datetimeoffset_cmp_internal(df1, df2) < 0);
}

Datum
datetimeoffset_gt(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);

	PG_RETURN_BOOL(datetimeoffset_cmp_internal(df1, df2) > 0);
}

Datum
datetimeoffset_le(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);

	PG_RETURN_BOOL(datetimeoffset_cmp_internal(df1, df2) <= 0);
}

Datum
datetimeoffset_ge(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);

	PG_RETURN_BOOL(datetimeoffset_cmp_internal(df1, df2) >= 0);
}

Datum
datetimeoffset_cmp(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);

	PG_RETURN_INT32(datetimeoffset_cmp_internal(df1, df2));
}

Datum
datetimeoffset_smaller(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);
	tsql_datetimeoffset *result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);

	if (datetimeoffset_cmp_internal(df1, df2) < 0)
		*result = *df1;
	else
		*result = *df2;
	PG_RETURN_DATETIMEOFFSET(result);
}

Datum
datetimeoffset_larger(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);
	tsql_datetimeoffset *result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);

	if (datetimeoffset_cmp_internal(df1, df2) > 0)
		*result = *df1;
	else
		*result = *df2;
	PG_RETURN_DATETIMEOFFSET(result);
}

/* datetimeoffset_pl_interval()
 * This function is similar to timestamptz_pl_interval,
 * adding some logic to handle the timezone.
 */
Datum
datetimeoffset_pl_interval(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Interval   *span = PG_GETARG_INTERVAL_P(1);
	tsql_datetimeoffset *result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);
	Timestamp	tmp = df->tsql_ts;
	int			tz;

	if (span->month != 0)
	{
		struct pg_tm tt,
				   *tm = &tt;
		fsec_t		fsec;

		if (timestamp2tm(tmp, &tz, tm, &fsec, NULL, NULL) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("datetimeoffset out of range")));

		tm->tm_mon += span->month;
		if (tm->tm_mon > MONTHS_PER_YEAR)
		{
			tm->tm_year += (tm->tm_mon - 1) / MONTHS_PER_YEAR;
			tm->tm_mon = ((tm->tm_mon - 1) % MONTHS_PER_YEAR) + 1;
		}
		else if (tm->tm_mon < 1)
		{
			tm->tm_year += tm->tm_mon / MONTHS_PER_YEAR - 1;
			tm->tm_mon = tm->tm_mon % MONTHS_PER_YEAR + MONTHS_PER_YEAR;
		}

		/* adjust for end of month boundary problems... */
		if (tm->tm_mday > day_tab[isleap(tm->tm_year)][tm->tm_mon - 1])
			tm->tm_mday = (day_tab[isleap(tm->tm_year)][tm->tm_mon - 1]);

		tz = 0;
		if (tm2timestamp(tm, fsec, &tz, &tmp) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("datetimeoffset out of range")));
	}

	if (span->day != 0)
	{
		struct pg_tm tt,
				   *tm = &tt;
		fsec_t		fsec;
		int			julian;

		if (timestamp2tm(tmp, &tz, tm, &fsec, NULL, NULL) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("datetimeoffset out of range")));

		/* Add days by converting to and from Julian */
		julian = date2j(tm->tm_year, tm->tm_mon, tm->tm_mday) + span->day;
		j2date(julian, &tm->tm_year, &tm->tm_mon, &tm->tm_mday);

		tz = 0;
		if (tm2timestamp(tm, fsec, &tz, &tmp) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("datetimeoffset out of range")));
	}

	tmp += span->time;
	result->tsql_ts = tmp + df->tsql_tz * USECS_PER_MINUTE;
	result->tsql_tz = df->tsql_tz;
	CheckDatetimeoffsetRange(result);

	PG_RETURN_DATETIMEOFFSET(result);
}

Datum
datetimeoffset_mi_interval(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Interval   *span = PG_GETARG_INTERVAL_P(1);
	Interval	tspan;

	tspan.month = -span->month;
	tspan.day = -span->day;
	tspan.time = -span->time;

	return DirectFunctionCall2(datetimeoffset_pl_interval,
							   DatetimeoffsetGetDatum(df),
							   PointerGetDatum(&tspan));
}

Datum
interval_pl_datetimeoffset(PG_FUNCTION_ARGS)
{
	Interval   *span = PG_GETARG_INTERVAL_P(0);
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(1);

	return DirectFunctionCall2(datetimeoffset_pl_interval,
							   DatetimeoffsetGetDatum(df),
							   PointerGetDatum(span));
}

Datum
datetimeoffset_mi(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df1 = PG_GETARG_DATETIMEOFFSET(0);
	tsql_datetimeoffset *df2 = PG_GETARG_DATETIMEOFFSET(1);
	Timestamp	t1;
	Timestamp	t2;
	Interval   *result;

	datetimeoffset_timestamp_internal(df1, &t1);
	datetimeoffset_timestamp_internal(df2, &t2);
	result = (Interval *) palloc(sizeof(Interval));

	result->time = t1 - t2;

	result->month = 0;
	result->day = 0;


	result = DatumGetIntervalP(DirectFunctionCall1(interval_justify_hours,
												   IntervalPGetDatum(result)));

	PG_RETURN_INTERVAL_P(result);
}

/* hash index support */
Datum
datetimeoffset_hash(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);

	return hash_any((unsigned char *) df, DATETIMEOFFSET_LEN);
}

/* smalldatetime_datetimeoffset()
 * Convert smalldatetime to datetimeoffset
 */
Datum
smalldatetime_datetimeoffset(PG_FUNCTION_ARGS)
{
	Timestamp	time = PG_GETARG_TIMESTAMP(0);
	tsql_datetimeoffset *result;

	result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);
	result->tsql_ts = time;
	result->tsql_tz = 0;
	CheckDatetimeoffsetRange(result);

	PG_RETURN_DATETIMEOFFSET(result);
}

/* datetimeoffset_smalldatetime()
 * Convert datetimeoffset to smalldatetime
 */
Datum
datetimeoffset_smalldatetime(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Timestamp	result;

	datetimeoffset_timestamp_internal(df, &result);
	CheckSmalldatetimeRange(result);
	AdjustTimestampForSmallDatetime(&result);

	PG_RETURN_TIMESTAMP(result);
}

/* datetime_datetimeoffset()
 * Convert datetime to datetimeoffset
 */
Datum
datetime_datetimeoffset(PG_FUNCTION_ARGS)
{
	Timestamp	time = PG_GETARG_TIMESTAMP(0);
	tsql_datetimeoffset *result;

	result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);
	result->tsql_ts = time;
	result->tsql_tz = 0;
	CheckDatetimeoffsetRange(result);

	PG_RETURN_DATETIMEOFFSET(result);
}

/* datetimeoffset_datetime()
 * Convert datetimeoffset to datetime
 */
Datum
datetimeoffset_datetime(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Timestamp	result;

	datetimeoffset_timestamp_internal(df, &result);
	CheckDatetimeRange(result);

	PG_RETURN_TIMESTAMP(result);
}

/* datetime2_datetimeoffset()
 * Convert datetime2 to datetimeoffset
 */
Datum
datetime2_datetimeoffset(PG_FUNCTION_ARGS)
{
	Timestamp	time = PG_GETARG_TIMESTAMP(0);
	tsql_datetimeoffset *result;

	result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);
	result->tsql_ts = time;
	result->tsql_tz = 0;
	CheckDatetimeoffsetRange(result);

	PG_RETURN_DATETIMEOFFSET(result);
}

/* datetimeoffset_datetime2()
 * Convert datetimeoffset to datetime
 */
Datum
datetimeoffset_datetime2(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Timestamp	result;

	datetimeoffset_timestamp_internal(df, &result);
	CheckDatetime2Range(result);

	PG_RETURN_TIMESTAMP(result);
}

/* timestamp_datetimeoffset()
 * Convert timestamp to datetimeoffset
 */
Datum
timestamp_datetimeoffset(PG_FUNCTION_ARGS)
{
	Timestamp	time = PG_GETARG_TIMESTAMP(0);
	tsql_datetimeoffset *result;

	result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);
	result->tsql_ts = time;
	result->tsql_tz = 0;
	CheckDatetimeoffsetRange(result);

	PG_RETURN_DATETIMEOFFSET(result);
}

/* datetimeoffset_timestamp()
 * Convert datetimeoffset to timestamp
 */
Datum
datetimeoffset_timestamp(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Timestamp	result;

	datetimeoffset_timestamp_internal(df, &result);

	PG_RETURN_TIMESTAMP(result);
}

/* date_datetimeoffset()
 * Convert date to datetimeoffset
 */
Datum
date_datetimeoffset(PG_FUNCTION_ARGS)
{
	DateADT		dateVal = PG_GETARG_DATEADT(0);
	tsql_datetimeoffset *result;

	result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);
	result->tsql_ts = (int64) dateVal * USECS_PER_DAY;
	result->tsql_tz = 0;
	CheckDatetimeoffsetRange(result);

	PG_RETURN_DATETIMEOFFSET(result);
}

/* datetimeoffset_date()
 * Convert datetimeoffset to date
 */
Datum
datetimeoffset_date(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Timestamp	time;
	struct pg_tm tt,
			   *tm = &tt;
	fsec_t		fsec;
	int			tz;
	DateADT		result;

	datetimeoffset_timestamp_internal(df, &time);
	if (timestamp2tm(time, &tz, tm, &fsec, NULL, NULL) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("datetimeoffset out of range")));

	result = date2j(tm->tm_year, tm->tm_mon, tm->tm_mday) - POSTGRES_EPOCH_JDATE;

	PG_RETURN_DATEADT(result);
}

/* datetimeoffset_time()
 * Convert datetimeoffset to time data type.
 */
Datum
datetimeoffset_time(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	Timestamp	time;
	TimeADT		result;

	datetimeoffset_timestamp_internal(df, &time);
	if (time < 0)
		result = time - (time / USECS_PER_DAY * USECS_PER_DAY) + USECS_PER_DAY;
	else
		result = time - (time / USECS_PER_DAY * USECS_PER_DAY);

	PG_RETURN_TIMEADT(result);
}

/* time_datetimeoffset()
 * Convert time to datetimeoffset data type.
 */
Datum
time_datetimeoffset(PG_FUNCTION_ARGS)
{
	TimeADT		time = PG_GETARG_TIMEADT(0);
	tsql_datetimeoffset *result;

	result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);
	result->tsql_ts = DATETIMEOFFSET_DEFAULT_TS + time;
	result->tsql_tz = 0;

	PG_RETURN_DATETIMEOFFSET(result);
}

/* datetimeoffset_scale()
 * Adjust datetimeoffset_scale type for specified scale factor.
 * Used by PostgreSQL type system to stuff columns.
 */
Datum
datetimeoffset_scale(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);
	int32		typmod = PG_GETARG_INT32(1);
	tsql_datetimeoffset *result = (tsql_datetimeoffset *) palloc(DATETIMEOFFSET_LEN);

	result->tsql_ts = df->tsql_ts;
	result->tsql_tz = df->tsql_tz;
	AdjustDatetimeoffsetForTypmod(&(result->tsql_ts), typmod);

	PG_RETURN_DATETIMEOFFSET(result);
}


Datum
get_datetimeoffset_tzoffset_internal(PG_FUNCTION_ARGS)
{
	tsql_datetimeoffset *df = PG_GETARG_DATETIMEOFFSET(0);

	PG_RETURN_INT16(-df->tsql_tz);
}

/*
 * CheckDatetimeoffsetRange --- Check if datetimeoffset is out of range
 * for 0001-01-01 through 9999-12-31
 */
static void
CheckDatetimeoffsetRange(const tsql_datetimeoffset *df)
{
	Timestamp	time;

	/*
	 * the lower bound and uppbound stands for 0001-01-01 00:00:00 and
	 * 10000-01-01 00:00:00
	 */
	static const int64 lower_bound = -63082281600000000;
	static const int64 upper_bound = 252455616000000000;

	datetimeoffset_timestamp_internal(df, &time);
	if (time < lower_bound || time >= upper_bound)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("data out of range for datetimeoffset")));
	}
}

/*
 * AdjustDatetimeoffsetForTypmod --- round off a datetimeoffset to suit given typmod
 * this function is from timestamp.c
 */
static void
AdjustDatetimeoffsetForTypmod(Timestamp *time, int32 typmod)
{
	static const int64 TimestampScales[MAX_TIMESTAMP_PRECISION + 1] = {
		INT64CONST(1000000),
		INT64CONST(100000),
		INT64CONST(10000),
		INT64CONST(1000),
		INT64CONST(100),
		INT64CONST(10),
		INT64CONST(1)
	};

	static const int64 TimestampOffsets[MAX_TIMESTAMP_PRECISION + 1] = {
		INT64CONST(500000),
		INT64CONST(50000),
		INT64CONST(5000),
		INT64CONST(500),
		INT64CONST(50),
		INT64CONST(5),
		INT64CONST(0)
	};

	/* new offset for negative timestamp value */
	static const int64 TimestampOffsetsNegative[MAX_TIMESTAMP_PRECISION + 1] = {
		INT64CONST(499999),
		INT64CONST(49999),
		INT64CONST(4999),
		INT64CONST(499),
		INT64CONST(49),
		INT64CONST(4),
		INT64CONST(0)
	};

	if (!TIMESTAMP_NOT_FINITE(*time)
		&& (typmod != -1) && (typmod != MAX_TIMESTAMP_PRECISION))
	{
		if (typmod < 0 || typmod > MAX_TIMESTAMP_PRECISION)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("datetimeoffset(%d) precision must be between %d and %d",
							typmod, 0, MAX_TIMESTAMP_PRECISION)));

		if (*time >= INT64CONST(0))
		{
			*time = ((*time + TimestampOffsets[typmod]) / TimestampScales[typmod]) *
				TimestampScales[typmod];
		}
		else
		{
			*time = -((((-*time) + TimestampOffsetsNegative[typmod]) / TimestampScales[typmod])
					  * TimestampScales[typmod]);
		}
	}
}

/* EncodeDatetimeoffsetTimezone()
 *	Copies representation of a numeric timezone offset to str.
 *  Note: we need to hanlde the '\0' at the end of original input string.
 */
static void
EncodeDatetimeoffsetTimezone(char *str, int tz, int style)
{
	int			hour,
				min;
	char	   *tmp;

	min = abs(tz);
	hour = min / MINS_PER_HOUR;
	min = min % MINS_PER_HOUR;
	/* point tmp to '\0' */
	tmp = str + strlen(str);
	*tmp++ = ' ';
	/* TZ is negated compared to sign we wish to display ... */
	*tmp++ = (tz <= 0 ? '+' : '-');

	tmp = pg_ultostr_zeropad(tmp, hour, 2);
	*tmp++ = ':';
	tmp = pg_ultostr_zeropad(tmp, min, 2);

	*tmp = '\0';
}
