/*-------------------------------------------------------------------------
 *
 * smalldatetime.c
 *	  Functions for the type "smalldatetime".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/timestamp.h"

#include "miscadmin.h"

PG_FUNCTION_INFO_V1(smalldatetime_in);
PG_FUNCTION_INFO_V1(smalldatetime_recv);
PG_FUNCTION_INFO_V1(time_smalldatetime);
PG_FUNCTION_INFO_V1(date_smalldatetime);
PG_FUNCTION_INFO_V1(timestamp_smalldatetime);
PG_FUNCTION_INFO_V1(timestamptz_smalldatetime);
PG_FUNCTION_INFO_V1(smalldatetime_varchar);
PG_FUNCTION_INFO_V1(varchar_smalldatetime);
PG_FUNCTION_INFO_V1(smalldatetime_char);
PG_FUNCTION_INFO_V1(char_smalldatetime);

PG_FUNCTION_INFO_V1(smalldatetime_pl_int4);
PG_FUNCTION_INFO_V1(int4_mi_smalldatetime);
PG_FUNCTION_INFO_V1(int4_pl_smalldatetime);
PG_FUNCTION_INFO_V1(smalldatetime_mi_int4);

PG_FUNCTION_INFO_V1(smalldatetime_pl_float8);
PG_FUNCTION_INFO_V1(smalldatetime_mi_float8);
PG_FUNCTION_INFO_V1(float8_pl_smalldatetime);
PG_FUNCTION_INFO_V1(float8_mi_smalldatetime);

void AdjustTimestampForSmallDatetime(Timestamp *time);
void CheckSmalldatetimeRange(const Timestamp time);
static Datum smalldatetime_in_str(char *str);

/* smalldatetime_in_str()
 * Convert a string to internal form.
 * Most parts of this functions is same as timestamp_in(),
 * but we use a different rounding function for smalldatetime.
 */
static Datum
smalldatetime_in_str(char *str)
{
#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	Timestamp	result;
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

	dterr = ParseDateTime(str, workbuf, sizeof(workbuf),
						  field, ftype, MAXDATEFIELDS, &nf);
	
	if (dterr == 0)
		dterr = DecodeDateTime(field, ftype, nf, &dtype, tm, &fsec, &tz);
	// dterr == 1 means that input is TIME format(e.g 12:34:59.123)
	// initialize other necessary date parts and accept input format
	if (dterr == 1)
	{
		tm->tm_year = 1900;
		tm->tm_mon = 1;
		tm->tm_mday = 1;
		dterr = 0;
	}
	if (dterr != 0)
		DateTimeParseError(dterr, str, "smalldatetime");
	switch (dtype)
	{
		case DTK_DATE:
			if (tm2timestamp(tm, fsec, NULL, &result) != 0)
				ereport(ERROR,
						(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						 errmsg("smalldatetime out of range: \"%s\"", str)));
			break;

		case DTK_EPOCH:
			result = SetEpochTimestamp();
			break;

		case DTK_LATE:
			TIMESTAMP_NOEND(result);
			break;

		case DTK_EARLY:
			TIMESTAMP_NOBEGIN(result);
			break;

		default:
			elog(ERROR, "unexpected dtype %d while parsing smalldatetime \"%s\"",
				 dtype, str);
			TIMESTAMP_NOEND(result);
	}

	CheckSmalldatetimeRange(result);
	AdjustTimestampForSmallDatetime(&result);

	PG_RETURN_TIMESTAMP(result);
}

/* smalldatetime_in()
 * Convert a string to internal form.
 * Most parts of this functions is same as timestamp_in(),
 * but we use a different rounding function for smalldatetime.
 */
Datum
smalldatetime_in(PG_FUNCTION_ARGS)
{
	char	     *str 			   = PG_GETARG_CSTRING(0);

	return smalldatetime_in_str(str);
}

/*
 * CheckSmalldatetimeRange --- Check if timestamp is out of range for smalldatetime
 */
void
CheckSmalldatetimeRange(const Timestamp time)
{
	/* the lower bound and uppbound stands for 1899-12-31 23:59:29.999 and 2079-06-06 23:59:29.999 */
	static const int64 lower_bound = -3155673630001000;
	static const int64 upper_bound = 2506636769999000;
	if (time < lower_bound || time >= upper_bound)
	{
		ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("data out of range for smalldatetime")));
	}
}

/*
 * AdjustTimestampForSmallDatetime --- round off a timestamp to suit smalldatetime.
 * The rounding logic: if second is larger or equal to 29.999 round up, otherwise round down.
 */
void
AdjustTimestampForSmallDatetime(Timestamp *time)
{
	static const int64 SmallDatetimeRoundsThresould[2] = {
        29999000,
        30001000
    };

    if (*time >= INT64CONST(0))
    {
        if( *time % USECS_PER_MINUTE >= SmallDatetimeRoundsThresould[0])
        {
            *time = *time / USECS_PER_MINUTE * USECS_PER_MINUTE + USECS_PER_MINUTE;
        }
        else
        {
            *time = *time / USECS_PER_MINUTE * USECS_PER_MINUTE;
        }
    }
    else
    {
        if( (-(*time)) % USECS_PER_MINUTE <= SmallDatetimeRoundsThresould[1])
        {
            *time = *time / USECS_PER_MINUTE * USECS_PER_MINUTE;
        }
        else
        {
            *time = *time / USECS_PER_MINUTE * USECS_PER_MINUTE - USECS_PER_MINUTE;
        }
    }
}

/* time_smalldatetime()
 * Convert time to smalldatetime
 */
Datum
time_smalldatetime(PG_FUNCTION_ARGS)
{
	TimeADT		timeVal = PG_GETARG_TIMEADT(0);
	Timestamp	result;

	struct 		pg_tm tt,
				*tm = &tt;
	fsec_t		fsec;

	// Initialize default year, month, day to 1900-01-01
	tm->tm_year = 1900;
	tm->tm_mon = 1;
	tm->tm_mday = 1;

	// Convert TimeADT type to tm
	time2tm(timeVal, tm, &fsec);

	if (tm2timestamp(tm, fsec, NULL, &result) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("data out of range for smalldatetime")));
	
	AdjustTimestampForSmallDatetime(&result);

	PG_RETURN_TIMESTAMP(result);
}

/* date_smalldatetime()
 * Convert date to smalldatetime
 */
Datum
date_smalldatetime(PG_FUNCTION_ARGS)
{
	DateADT		dateVal = PG_GETARG_DATEADT(0);
	Timestamp	result;

	if (DATE_IS_NOBEGIN(dateVal))
		TIMESTAMP_NOBEGIN(result);
	else if (DATE_IS_NOEND(dateVal))
		TIMESTAMP_NOEND(result);
	else
		result = dateVal * USECS_PER_DAY;

	CheckSmalldatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/* timestamp_smalldatetime()
 * Convert timestamp to smalldatetime
 */
Datum
timestamp_smalldatetime(PG_FUNCTION_ARGS)
{
	Timestamp result = PG_GETARG_TIMESTAMP(0);

	CheckSmalldatetimeRange(result);
	AdjustTimestampForSmallDatetime(&result);
	PG_RETURN_TIMESTAMP(result);
}

/* timestamptz_smalldatetime()
 * Convert timestamptz to smalldatetime
 */
Datum
timestamptz_smalldatetime(PG_FUNCTION_ARGS)
{
	TimestampTz timestamp = PG_GETARG_TIMESTAMPTZ(0);
	Timestamp	result;

	struct pg_tm tt,
	*tm = &tt;
	fsec_t		fsec;
	int			tz;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		result = timestamp;
	else
	{
		if (timestamp2tm(timestamp, &tz, tm, &fsec, NULL, NULL) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("data out of range for smalldatetime")));
		if (tm2timestamp(tm, fsec, NULL, &result) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("data out of range for smalldatetime")));
	}
	CheckSmalldatetimeRange(result);
	AdjustTimestampForSmallDatetime(&result);
	PG_RETURN_TIMESTAMP(result);
}

/* smalldatetime_varchar()
 * Convert a smalldatetime to varchar.
 * The function is the same as timestamp_out() except the return type is a VARCHAR Datum.
 */
Datum
smalldatetime_varchar(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	char	   *s;
	struct pg_tm tt,
			   *tm = &tt;
	fsec_t		fsec;
	char		buf[MAXDATELEN + 1];
	VarChar    *result;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		EncodeSpecialTimestamp(timestamp, buf);
	else if (timestamp2tm(timestamp, NULL, tm, &fsec, NULL, NULL) == 0)
		EncodeDateTime(tm, fsec, false, 0, NULL, DateStyle, buf);
	else
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
	s = pstrdup(buf);
	result = (VarChar *) cstring_to_text(s);
	PG_RETURN_VARCHAR_P(result);
}

/*
 * varchar_smalldatetime()
 * Convert a varchar to smalldatetime
 */
Datum
varchar_smalldatetime(PG_FUNCTION_ARGS)
{
	Datum txt = PG_GETARG_DATUM(0);
	char *str = TextDatumGetCString(txt);

	return smalldatetime_in_str(str);
}

/* smalldatetime_char()
 * Convert a smalldatetime to char.
 * The function is the same as timestamp_out() except the return type is a CHAR Datum.
 */
Datum
smalldatetime_char(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	char	   *s;
	struct pg_tm tt,
			   *tm = &tt;
	fsec_t		fsec;
	char		buf[MAXDATELEN + 1];
	VarChar    *result;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		EncodeSpecialTimestamp(timestamp, buf);
	else if (timestamp2tm(timestamp, NULL, tm, &fsec, NULL, NULL) == 0)
		EncodeDateTime(tm, fsec, false, 0, NULL, DateStyle, buf);
	else
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
	s = pstrdup(buf);
	result = (BpChar *) cstring_to_text(s);
	PG_RETURN_BPCHAR_P(result);
}

/*
 * char_smalldatetime()
 * Convert a CHAR to smalldatetime
 */
Datum
char_smalldatetime(PG_FUNCTION_ARGS)
{
	Datum txt = PG_GETARG_DATUM(0);
	char *str = TextDatumGetCString(txt);

	return smalldatetime_in_str(str);
}

/*
 * smalldatetime_pl_int4()
 * operator function for adding smalldatetime plus int
 * 
 * simply add number of days to date value, while preserving the time
 * component
 */
Datum
smalldatetime_pl_int4(PG_FUNCTION_ARGS)
{	
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	int32		days = PG_GETARG_INT32(1);
	Timestamp	result;
	Interval *input_interval;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, days, 0, 0, 0);

	/* add interval */
	result = DirectFunctionCall2(timestamp_pl_interval, timestamp, PointerGetDatum(input_interval));

	CheckSmalldatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * int4_mi_smalldatetime()
 * Operator function for subtracting int minus smalldatetime
 * 
 * Convert the input int32 value d to smalldatetime(1/1/1900) + d days.
 * Then add the difference between the input smalldatetime value and the one 
 * above to the default smalldatetime value (1/1/1900).
 * 
 * ex: 
 * d = 9, dt = '1/11/1900'
 * dt_left = smalldatetime(1/1/1900) + 9 days = smalldatetime(1/10/1900)
 * diff = dt_left - dt = -1 day
 * result = 1/1/1900 + diff = 1899-12-31
 */
Datum
int4_mi_smalldatetime(PG_FUNCTION_ARGS)
{	
	int32		days = PG_GETARG_INT32(0);
	Timestamp	timestamp_right = PG_GETARG_TIMESTAMP(1);
	Timestamp	result;
	Timestamp	default_timestamp;
	Timestamp	timestamp_left;
	Interval *input_interval;
	Interval *result_interval;

	if (TIMESTAMP_NOT_FINITE(timestamp_right))
		PG_RETURN_TIMESTAMP(timestamp_right);

	/* inialize input int(days) as timestamp */
	default_timestamp = DirectFunctionCall6(make_timestamp, 1900, 1, 1, 0, 0,0);
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, days, 0, 0, 0);
	timestamp_left = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(input_interval));

	/* calculate timestamp diff */
	result_interval = (Interval *) DirectFunctionCall2(timestamp_mi, timestamp_left, timestamp_right);

	/* if the diff between left and right timestamps is positive, then we add the interval. else, subtract */
	result = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(result_interval));

	CheckSmalldatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * int4_pl_smalldatetime()
 * operator function for adding int plus smalldatetime
 */
Datum
int4_pl_smalldatetime(PG_FUNCTION_ARGS)
{	
	int32		days = PG_GETARG_INT32(0);
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(1);
	PG_RETURN_TIMESTAMP(DirectFunctionCall2(smalldatetime_pl_int4, timestamp, days));
}

/*
 * smalldatetime_mi_int4()
 * operator function for subtracting smalldatetime minus int
 */
Datum
smalldatetime_mi_int4(PG_FUNCTION_ARGS)
{	
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	int32		days = PG_GETARG_INT32(1);
	PG_RETURN_TIMESTAMP(DirectFunctionCall2(smalldatetime_pl_int4, timestamp, -days));
}


/*
 * smalldatetime_pl_float8()
 * operator function for adding smalldatetime plus float
 * 
 * simply add number of days/secs to date value, while preserving the time
 * component
 */
Datum
smalldatetime_pl_float8(PG_FUNCTION_ARGS)
{	
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	double		days = PG_GETARG_FLOAT8(1);
	double 		day_whole, day_fract, sec_whole;
	Interval *input_interval;
	Timestamp	result;
	
	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);
	day_fract = modf(SECS_PER_DAY*day_fract, &sec_whole);
	// fsec_whole = TSROUND(TS_PREC_INV*sec_fract);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(sec_whole));

	/* add interval */
	result = DirectFunctionCall2(timestamp_pl_interval, timestamp, PointerGetDatum(input_interval));

	CheckSmalldatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}


/*
 * float8_mi_smalldatetime()
 * Operator function for subtracting float8 minus smalldatetime
 * 
 * Convert the input float8 value d to smalldatetime(1/1/1900) + d days.
 * Then add the difference between the input smalldatetime value and the one 
 * above to the default smalldatetime value (1/1/1900).
 */
Datum
float8_mi_smalldatetime(PG_FUNCTION_ARGS)
{	
	double		days = PG_GETARG_FLOAT8(0);
	Timestamp	timestamp_right = PG_GETARG_TIMESTAMP(1);
	double 		day_whole, day_fract, sec_whole;
	Timestamp	result;
	Timestamp	default_timestamp;
	Timestamp	timestamp_left;
	Interval *input_interval;
	Interval *result_interval;

	if (TIMESTAMP_NOT_FINITE(timestamp_right))
		PG_RETURN_TIMESTAMP(timestamp_right);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);
	day_fract = modf(SECS_PER_DAY*day_fract, &sec_whole);


	/* inialize input int(days) as timestamp */
	default_timestamp = DirectFunctionCall6(make_timestamp, 1900, 1, 1, 0, 0,0);
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(sec_whole));
	timestamp_left = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(input_interval));

	/* calculate timestamp diff */
	result_interval = (Interval *) DirectFunctionCall2(timestamp_mi, timestamp_left, timestamp_right);

	/* if the diff between left and right timestamps is positive, then we add the interval. else, subtract */
	result = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(result_interval));


	CheckSmalldatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * float8_pl_smalldatetime()
 * operator function for adding float8 plus smalldatetime
 */
Datum
float8_pl_smalldatetime(PG_FUNCTION_ARGS)
{	
	double		days = PG_GETARG_FLOAT8(0);
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(1);
	double 		day_whole, day_fract, sec_whole;
	Interval *input_interval;
	Timestamp	result;
	
	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);
	day_fract = modf(SECS_PER_DAY*day_fract, &sec_whole);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(sec_whole));

	/* add interval */
	result = DirectFunctionCall2(timestamp_pl_interval, timestamp, PointerGetDatum(input_interval));

	CheckSmalldatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * smalldatetime_mi_float8()
 * operator function for subtracting smalldatetime minus float8
 */
Datum
smalldatetime_mi_float8(PG_FUNCTION_ARGS)
{	
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	double		days = PG_GETARG_FLOAT8(1);
	double 		day_whole, day_fract, sec_whole;
	Interval *input_interval;
	Timestamp	result;
	
	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);
	day_fract = modf(SECS_PER_DAY*day_fract, &sec_whole);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(sec_whole));


	/* subtract interval */
	result = DirectFunctionCall2(timestamp_mi_interval, timestamp, PointerGetDatum(input_interval));

	CheckSmalldatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}