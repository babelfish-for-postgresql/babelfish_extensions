/*-------------------------------------------------------------------------
 *
 * datetime2.c
 *	  Functions for the type "datetime2".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/timestamp.h"
#include "libpq/pqformat.h"

#include "miscadmin.h"
#include "datetime2.h"
#include "datetime.h"

PG_FUNCTION_INFO_V1(datetime2_in);
PG_FUNCTION_INFO_V1(datetime2_out);
PG_FUNCTION_INFO_V1(datetime2_recv);
PG_FUNCTION_INFO_V1(date_datetime2);
PG_FUNCTION_INFO_V1(time_datetime2);
PG_FUNCTION_INFO_V1(timestamp_datetime2);
PG_FUNCTION_INFO_V1(timestamptz_datetime2);
PG_FUNCTION_INFO_V1(datetime2_scale);
PG_FUNCTION_INFO_V1(datetime2_varchar);
PG_FUNCTION_INFO_V1(varchar_datetime2);
PG_FUNCTION_INFO_V1(datetime2_char);
PG_FUNCTION_INFO_V1(char_datetime2);

static void AdjustDatetime2ForTypmod(Timestamp *time, int32 typmod);
static Datum datetime2_in_str(char *str, int32 typmod);
void		CheckDatetime2Range(const Timestamp time);

/* datetime2_in_str()
 * Convert a string to internal form.
 * Most parts of this functions is same as timestamp_in(),
 * but we use a different rounding function for datetime2.
 */
static Datum
datetime2_in_str(char *str, int32 typmod)
{
	Timestamp	result;
	fsec_t		fsec;
	struct pg_tm tt,
			   *tm = &tt;
	int			tz;
	int			dtype = -1;
	int			nf;
	int			dterr;
	char	   *field[MAXDATEFIELDS];
	int			ftype[MAXDATEFIELDS];
	char		workbuf[MAXDATELEN + MAXDATEFIELDS];

	/* Set input to default '1900-01-01 00:00:00.* if empty string encountered */
	if (*str == '\0')
	{
		result = initializeToDefaultDatetime();
		AdjustDatetime2ForTypmod(&result, typmod);

		PG_RETURN_TIMESTAMP(result);
	}

	dterr = ParseDateTime(str, workbuf, sizeof(workbuf),
						  field, ftype, MAXDATEFIELDS, &nf);
	if (dterr == 0)
		dterr = DecodeDateTime(field, ftype, nf, &dtype, tm, &fsec, &tz);

	/*
	 * dterr == 1 means that input is TIME format(e.g 12:34:59.123) initialize
	 * other necessary date parts and accept input format
	 */
	if (dterr == 1)
	{
		tm->tm_year = 1900;
		tm->tm_mon = 1;
		tm->tm_mday = 1;
		dterr = 0;
	}

	if (dterr != 0)
		DateTimeParseError(dterr, str, "datetime2");

	/*
	 * Caps upper limit on fractional seconds(999999 microseconds) so that the
	 * upper boundary for datetime2 is not exceeded when the Date and Time
	 * parts are at the upper value limit
	 */
	if ((fsec == USECS_PER_SEC) &&
		(tm->tm_year == 9999) &&
		(tm->tm_mon == 12) &&
		(tm->tm_mday == 31) &&
		(tm->tm_hour == 23) &&
		(tm->tm_min == 59) &&
		(tm->tm_sec == 59))
		fsec = 999999;

	switch (dtype)
	{
		case DTK_DATE:
			if (tm2timestamp(tm, fsec, NULL, &result) != 0)
				ereport(ERROR,
						(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						 errmsg("datetime2 out of range: \"%s\"", str)));
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
			elog(ERROR, "unexpected dtype %d while parsing datetime2 \"%s\"",
				 dtype, str);
			TIMESTAMP_NOEND(result);
	}
	AdjustDatetime2ForTypmod(&result, typmod);
	CheckDatetime2Range(result);

	PG_RETURN_TIMESTAMP(result);
}

/* datetime2_in()
 * Convert a string to internal form.
 * Most parts of this functions is same as timestamp_in(),
 * but we use a different rounding function for datetime2.
 */
Datum
datetime2_in(PG_FUNCTION_ARGS)
{
	char	   *str = PG_GETARG_CSTRING(0);
#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	int32		typmod = PG_GETARG_INT32(2);

	return datetime2_in_str(str, typmod);
}

/* AdjustDatetime2ForTypmod()
 * round off a datetime2 to suit given typmod
 */
static void
AdjustDatetime2ForTypmod(Timestamp *time, int32 typmod)
{
	static const int64 TimestampScales[MAX_DATETIME2_PRECISION + 1] = {
		INT64CONST(1000000),
		INT64CONST(100000),
		INT64CONST(10000),
		INT64CONST(1000),
		INT64CONST(100),
		INT64CONST(10),
		INT64CONST(1),
		INT64CONST(1)
	};

	static const int64 TimestampOffsets[MAX_DATETIME2_PRECISION + 1] = {
		INT64CONST(500000),
		INT64CONST(50000),
		INT64CONST(5000),
		INT64CONST(500),
		INT64CONST(50),
		INT64CONST(5),
		INT64CONST(0),
		INT64CONST(0)
	};

	/* new offset for negative timestamp value */
	static const int64 TimestampOffsetsNegative[MAX_DATETIME2_PRECISION + 1] = {
		INT64CONST(499999),
		INT64CONST(49999),
		INT64CONST(4999),
		INT64CONST(499),
		INT64CONST(49),
		INT64CONST(4),
		INT64CONST(0),
		INT64CONST(0)
	};

	int64		adjustedTime;

	if (!TIMESTAMP_NOT_FINITE(*time)
		&& (typmod != -1))
	{
		if (typmod < 0 || typmod > MAX_DATETIME2_PRECISION)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("datetime2(%d) precision must be between %d and %d",
							typmod, 0, MAX_DATETIME2_PRECISION)));

		if (*time >= INT64CONST(0))
		{
			adjustedTime = ((*time + TimestampOffsets[typmod]) / TimestampScales[typmod]) *
				TimestampScales[typmod];
			/* Make sure typmod doesn't push datetime2 out of range */
			if (adjustedTime < END_DATETIME2)
				*time = adjustedTime;

			/*
			 * If applying typmod pushes datetime2 out of range, simply
			 * truncate fractional seconds to typmod precision
			 */
			else
			{
				*time = (*time / TimestampScales[typmod]) * TimestampScales[typmod];
			}
		}
		else
		{
			*time = -((((-*time) + TimestampOffsetsNegative[typmod]) / TimestampScales[typmod])
					  * TimestampScales[typmod]);
		}
	}
}

/*
 * CheckDatetime2Range()
 * Check if timestamp is out of range for datetime2
 */
void
CheckDatetime2Range(const Timestamp time)
{
	if (!IS_VALID_DATETIME2(time))
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("data out of range for datetime2")));
	}
}

/* date_datetime2()
 * Convert date to datetime2
 */
Datum
date_datetime2(PG_FUNCTION_ARGS)
{
	DateADT		dateVal = PG_GETARG_DATEADT(0);
	Timestamp	result;

	if (DATE_IS_NOBEGIN(dateVal))
		TIMESTAMP_NOBEGIN(result);
	else if (DATE_IS_NOEND(dateVal))
		TIMESTAMP_NOEND(result);
	else
		result = dateVal * USECS_PER_DAY;

	PG_RETURN_TIMESTAMP(result);
}

/* time_datetime2()
 * Convert time to datetime2
 */
Datum
time_datetime2(PG_FUNCTION_ARGS)
{
	TimeADT		timeVal = PG_GETARG_TIMEADT(0);
	Timestamp	result;

	struct pg_tm tt,
			   *tm = &tt;
	fsec_t		fsec;

	/* Initialize default year, month, day */
	tm->tm_year = 1900;
	tm->tm_mon = 1;
	tm->tm_mday = 1;

	/* Convert TimeADT type to tm */
	time2tm(timeVal, tm, &fsec);

	if (tm2timestamp(tm, fsec, NULL, &result) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("data out of range for datetime2")));

	PG_RETURN_TIMESTAMP(result);
}

/* timestamp_datetime2()
 * Convert timestamp to datetime2
 */
Datum
timestamp_datetime2(PG_FUNCTION_ARGS)
{
	Timestamp	result = PG_GETARG_TIMESTAMP(0);

	CheckDatetime2Range(result);
	PG_RETURN_TIMESTAMP(result);
}

/* timestamptz_datetime2()
 * Convert timestamptz to datetime2
 */
Datum
timestamptz_datetime2(PG_FUNCTION_ARGS)
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
					 errmsg("data out of range for datetime2")));
		if (tm2timestamp(tm, fsec, NULL, &result) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("data out of range for datetime2")));
	}
	CheckDatetime2Range(result);
	PG_RETURN_TIMESTAMP(result);
}

/* datetime2_scale()
 * Adjust datetime2_scale type for specified scale factor.
 * Used by PostgreSQL type system to stuff columns.
 */
Datum
datetime2_scale(PG_FUNCTION_ARGS)
{
	Timestamp	result = PG_GETARG_TIMESTAMP(0);
	int32		typmod = PG_GETARG_INT32(1);

	AdjustDatetime2ForTypmod(&result, typmod);
	PG_RETURN_TIMESTAMP(result);
}

/* datetime2_varchar()
 * Convert a datetime2 to varchar.
 * The function is the same as timestamp_out() except the return type is a VARCHAR Datum.
 */
Datum
datetime2_varchar(PG_FUNCTION_ARGS)
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
 * varchar_datetime2()
 * Convert a varchar to datetime2
 */
Datum
varchar_datetime2(PG_FUNCTION_ARGS)
{
	Datum		txt = PG_GETARG_DATUM(0);
	char	   *str = TextDatumGetCString(txt);

	return datetime2_in_str(str, MAX_TIMESTAMP_PRECISION);
}

/* datetime2_char()
 * Convert a datetim2 to char.
 * The function is the same as timestamp_out() except the return type is a CHAR Datum.
 */
Datum
datetime2_char(PG_FUNCTION_ARGS)
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
 * char_datetime2()
 * Convert a CHAR to datetim2
 */
Datum
char_datetime2(PG_FUNCTION_ARGS)
{
	Datum		txt = PG_GETARG_DATUM(0);
	char	   *str = TextDatumGetCString(txt);

	return datetime2_in_str(str, MAX_TIMESTAMP_PRECISION);
}
