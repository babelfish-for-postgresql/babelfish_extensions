/*-------------------------------------------------------------------------
 *
 * datetime.c
 *	  Functions for the type "datetime".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <regex.h>
#include "fmgr.h"
#include "parser/parser.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/timestamp.h"
#include "utils/varlena.h"
#include "libpq/pqformat.h"

#include "miscadmin.h"
#include "datetime.h"


PG_FUNCTION_INFO_V1(datetime_in);
PG_FUNCTION_INFO_V1(datetime_out);
PG_FUNCTION_INFO_V1(datetime_recv);
PG_FUNCTION_INFO_V1(date_datetime);
PG_FUNCTION_INFO_V1(time_datetime);
PG_FUNCTION_INFO_V1(timestamp_datetime);
PG_FUNCTION_INFO_V1(timestamptz_datetime);
PG_FUNCTION_INFO_V1(datetime_varchar);
PG_FUNCTION_INFO_V1(varchar_datetime);
PG_FUNCTION_INFO_V1(datetime_char);
PG_FUNCTION_INFO_V1(char_datetime);
PG_FUNCTION_INFO_V1(datetime_pl_int4);
PG_FUNCTION_INFO_V1(int4_mi_datetime);
PG_FUNCTION_INFO_V1(int4_pl_datetime);
PG_FUNCTION_INFO_V1(datetime_mi_int4);

PG_FUNCTION_INFO_V1(datetime_pl_float8);
PG_FUNCTION_INFO_V1(datetime_mi_float8);
PG_FUNCTION_INFO_V1(float8_pl_datetime);
PG_FUNCTION_INFO_V1(float8_mi_datetime);

PG_FUNCTION_INFO_V1(datetime_pl_datetime);
PG_FUNCTION_INFO_V1(datetime_mi_datetime);

void		CheckDatetimeRange(const Timestamp time);
void		CheckDatetimePrecision(fsec_t fsec);

Datum
datetime_in_str(char *str)
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

	/*
	 * Set input to default '1900-01-01 00:00:00.000' if empty string
	 * encountered
	 */
	if (*str == '\0')
	{
		result = initializeToDefaultDatetime();
		PG_RETURN_TIMESTAMP(result);
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
		DateTimeParseError(dterr, str, "datetime");
	switch (dtype)
	{
		case DTK_DATE:
			if (tm2timestamp(tm, fsec, NULL, &result) != 0)
				ereport(ERROR,
						(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						 errmsg("datetime out of range: \"%s\"", str)));
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
			elog(ERROR, "unexpected dtype %d while parsing datetime \"%s\"",
				 dtype, str);
			TIMESTAMP_NOEND(result);
	}

	/*
	 * TODO: round datetime fsec to fixed bins (e.g. .000, .003, .007) see:
	 * BABEL-1081
	 */
	CheckDatetimeRange(result);
	CheckDatetimePrecision(fsec);

	PG_RETURN_TIMESTAMP(result);

}

/* datetime_in()
 * Convert a string to internal form.
 * Most parts of this functions is same as timestamp_in(),
 * but we use a different rounding function for datetime.
 */
Datum
datetime_in(PG_FUNCTION_ARGS)
{
	char	   *str = PG_GETARG_CSTRING(0);

	return datetime_in_str(str);
}

/* datetime_out()
 * Convert a datetime to external form.
 */
Datum
datetime_out(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	char	   *result;
	struct pg_tm tt,
			   *tm = &tt;
	fsec_t		fsec;
	char		buf[MAXDATELEN + 1];

	if (TIMESTAMP_NOT_FINITE(timestamp))
		EncodeSpecialTimestamp(timestamp, buf);
	else if (timestamp2tm(timestamp, NULL, tm, &fsec, NULL, NULL) == 0)
	{
		/* round fractional seconds to datetime precision */
		fsec = DTROUND(fsec);
		EncodeDateTime(tm, fsec, false, 0, NULL, DateStyle, buf);
	}
	else
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
	result = pstrdup(buf);
	PG_RETURN_CSTRING(result);
}

/*
 * CheckDatetimeRange --- Check if timestamp is out of range for datetime
 */
void
CheckDatetimeRange(const Timestamp time)
{
	if (!IS_VALID_DATETIME(time))
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("data out of range for datetime")));
	}
}

/*
 * CheckDatetimePrecision --- Check precision for datetime
 */
void
CheckDatetimePrecision(fsec_t fsec)
{
	if (!IS_VALID_DT_PRECISION(fsec))
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("data precision out of range for datetime")));
	}
}

/* date_datetime()
 * Convert date to datetime
 */
Datum
date_datetime(PG_FUNCTION_ARGS)
{
	DateADT		dateVal = PG_GETARG_DATEADT(0);
	Timestamp	result;

	if (DATE_IS_NOBEGIN(dateVal))
		TIMESTAMP_NOBEGIN(result);
	else if (DATE_IS_NOEND(dateVal))
		TIMESTAMP_NOEND(result);
	else
		result = dateVal * USECS_PER_DAY;

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/* time_datetime()
 * Convert time to datetime
 */
Datum
time_datetime(PG_FUNCTION_ARGS)
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

	/* Convert TimeADT type to tm  */
	time2tm(timeVal, tm, &fsec);

	if (tm2timestamp(tm, fsec, NULL, &result) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("data out of range for datetime")));

	PG_RETURN_TIMESTAMP(result);
}

/* timestamp_datetime()
 * Convert timestamp to datetime
 */
Datum
timestamp_datetime(PG_FUNCTION_ARGS)
{
	Timestamp	result = PG_GETARG_TIMESTAMP(0);

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/* timestamptz_datetime()
 * Convert timestamptz to datetime
 */
Datum
timestamptz_datetime(PG_FUNCTION_ARGS)
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
					 errmsg("data out of range for datetime")));
		if (tm2timestamp(tm, fsec, NULL, &result) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("data out of range for datetime")));
	}
	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/* datetime_varchar()
 * Convert a datetime to varchar.
 */
Datum
datetime_varchar(PG_FUNCTION_ARGS)
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
	{
		/* round fractional seconds to datetime precision */
		fsec = DTROUND(fsec);
		EncodeDateTime(tm, fsec, false, 0, NULL, DateStyle, buf);
	}
	else
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
	s = pstrdup(buf);
	result = (VarChar *) cstring_to_text(s);
	PG_RETURN_VARCHAR_P(result);
}

/*
 * varchar_datetime()
 * Convert a VARCHAR to datetime
 */
Datum
varchar_datetime(PG_FUNCTION_ARGS)
{
	Datum		txt = PG_GETARG_DATUM(0);
	char	   *str = TextDatumGetCString(txt);

	return datetime_in_str(str);
}

/* datetime_char()
 * Convert a datetime to char.
 */
Datum
datetime_char(PG_FUNCTION_ARGS)
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
	{
		/* round fractional seconds to datetime precision */
		fsec = DTROUND(fsec);
		EncodeDateTime(tm, fsec, false, 0, NULL, DateStyle, buf);
	}
	else
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
	s = pstrdup(buf);
	result = (BpChar *) cstring_to_text(s);
	PG_RETURN_BPCHAR_P(result);
}

/*
 * char_datetime()
 * Convert a CHAR type to datetime
 */
Datum
char_datetime(PG_FUNCTION_ARGS)
{
	Datum		txt = PG_GETARG_DATUM(0);
	char	   *str = TextDatumGetCString(txt);

	return datetime_in_str(str);
}

/*
 * datetime_pl_int4()
 * operator function for adding datetime plus int
 *
 * simply add number of days to date value, while preserving the time
 * component
 */
Datum
datetime_pl_int4(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	int32		days = PG_GETARG_INT32(1);
	Timestamp	result;
	Interval   *input_interval;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, days, 0, 0, 0);

	/* add interval */
	result = DirectFunctionCall2(timestamp_pl_interval, timestamp, PointerGetDatum(input_interval));

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * int4_mi_datetime()
 * Operator function for subtracting int minus datetime
 *
 * Convert the input int32 value d to datetime(1/1/1900) + d days.
 * Then add the difference between the input datetime value and the one
 * above to the default datetime value (1/1/1900).
 *
 * ex:
 * d = 9, dt = '1/11/1900'
 * dt_left = datetime(1/1/1900) + 9 days = datetime(1/10/1900)
 * diff = dt_left - dt = -1 day
 * result = 1/1/1900 + diff = 1899-12-31
 */
Datum
int4_mi_datetime(PG_FUNCTION_ARGS)
{
	int32		days = PG_GETARG_INT32(0);
	Timestamp	timestamp_right = PG_GETARG_TIMESTAMP(1);
	Timestamp	result;
	Timestamp	default_timestamp;
	Timestamp	timestamp_left;
	Interval   *input_interval;
	Interval   *result_interval;

	if (TIMESTAMP_NOT_FINITE(timestamp_right))
		PG_RETURN_TIMESTAMP(timestamp_right);

	/* inialize input int(days) as timestamp */
	default_timestamp = DirectFunctionCall6(make_timestamp, 1900, 1, 1, 0, 0, 0);
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, days, 0, 0, 0);
	timestamp_left = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(input_interval));

	/* calculate timestamp diff */
	result_interval = (Interval *) DirectFunctionCall2(timestamp_mi, timestamp_left, timestamp_right);

	/*
	 * if the diff between left and right timestamps is positive, then we add
	 * the interval. else, subtract
	 */
	result = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(result_interval));

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * int4_pl_datetime()
 * operator function for adding int plus datetime
 */
Datum
int4_pl_datetime(PG_FUNCTION_ARGS)
{
	int32		days = PG_GETARG_INT32(0);
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(1);

	PG_RETURN_TIMESTAMP(DirectFunctionCall2(datetime_pl_int4, timestamp, days));
}

/*
 * datetime_mi_int4()
 * operator function for subtracting datetime minus int
 */
Datum
datetime_mi_int4(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	int32		days = PG_GETARG_INT32(1);

	PG_RETURN_TIMESTAMP(DirectFunctionCall2(datetime_pl_int4, timestamp, -days));
}


/*
 * datetime_pl_float8()
 * operator function for adding datetime plus float
 *
 * simply add number of days/secs to date value, while preserving the time
 * component
 */
Datum
datetime_pl_float8(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	double		days = PG_GETARG_FLOAT8(1);
	double		day_whole,
				day_fract;
	Interval   *input_interval;
	Timestamp	result;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(SECS_PER_DAY * day_fract));

	/* add interval */
	result = DirectFunctionCall2(timestamp_pl_interval, timestamp, PointerGetDatum(input_interval));

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}


/*
 * float8_mi_datetime()
 * Operator function for subtracting float8 minus datetime
 *
 * Convert the input float8 value d to datetime(1/1/1900) + d days.
 * Then add the difference between the input datetime value and the one
 * above to the default datetime value (1/1/1900).
 */
Datum
float8_mi_datetime(PG_FUNCTION_ARGS)
{
	double		days = PG_GETARG_FLOAT8(0);
	Timestamp	timestamp_right = PG_GETARG_TIMESTAMP(1);
	double		day_whole,
				day_fract;
	Timestamp	result;
	Timestamp	default_timestamp;
	Timestamp	timestamp_left;
	Interval   *input_interval;
	Interval   *result_interval;

	if (TIMESTAMP_NOT_FINITE(timestamp_right))
		PG_RETURN_TIMESTAMP(timestamp_right);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(SECS_PER_DAY * day_fract));


	/* inialize input int(days) as timestamp */
	default_timestamp = DirectFunctionCall6(make_timestamp, 1900, 1, 1, 0, 0, 0);
	timestamp_left = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(input_interval));

	/* calculate timestamp diff */
	result_interval = (Interval *) DirectFunctionCall2(timestamp_mi, timestamp_left, timestamp_right);

	/*
	 * if the diff between left and right timestamps is positive, then we add
	 * the interval. else, subtract
	 */
	result = DirectFunctionCall2(timestamp_pl_interval, default_timestamp, PointerGetDatum(result_interval));


	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * float8_pl_datetime()
 * operator function for adding float8 plus datetime
 */
Datum
float8_pl_datetime(PG_FUNCTION_ARGS)
{
	double		days = PG_GETARG_FLOAT8(0);
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(1);
	double		day_whole,
				day_fract;
	Interval   *input_interval;
	Timestamp	result;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(SECS_PER_DAY * day_fract));

	/* add interval */
	result = DirectFunctionCall2(timestamp_pl_interval, timestamp, PointerGetDatum(input_interval));

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * datetime_mi_float8()
 * operator function for subtracting datetime minus float8
 */
Datum
datetime_mi_float8(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp = PG_GETARG_TIMESTAMP(0);
	double		days = PG_GETARG_FLOAT8(1);
	double		day_whole,
				day_fract;
	Interval   *input_interval;
	Timestamp	result;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		PG_RETURN_TIMESTAMP(timestamp);

	/* split day into whole and fractional parts */
	day_fract = modf(days, &day_whole);

	/* make interval */
	input_interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, (int32) day_whole, 0, 0, Float8GetDatum(SECS_PER_DAY * day_fract));


	/* subtract interval */
	result = DirectFunctionCall2(timestamp_mi_interval, timestamp, PointerGetDatum(input_interval));

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/*
 * Set input to default '1900-01-01 00:00:00' if empty string encountered
 */
Timestamp
initializeToDefaultDatetime(void)
{
	Timestamp	result;
	struct pg_tm tt,
			   *tm = &tt;

	tm->tm_year = 1900;
	tm->tm_mon = 1;
	tm->tm_mday = 1;
	tm->tm_hour = tm->tm_min = tm->tm_sec = 0;

	tm2timestamp(tm, 0, NULL, &result);

	return result;
}

Datum
datetime_pl_datetime(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp1 = PG_GETARG_TIMESTAMP(0);
	Timestamp	timestamp2 = PG_GETARG_TIMESTAMP(1);
	Timestamp	diff;
	Timestamp	result;

	/*
	 * calculate interval from timestamp2. It should be calculated as the
	 * difference from 1900-01-01 00:00:00 (default datetime)
	 */
	diff = timestamp2 - initializeToDefaultDatetime();

	/* add interval */
	result = timestamp1 + diff;

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}

/* Checks whether the field is valid text month */
static bool isTextMonthPresent(char* field)
{
	char* months[] = {"january", "february", "march", "april", "may",
		"june", "july", "august", "september", "october",
		"november", "december", "jan", "feb", "mar", "apr",
		"may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"};
	for (int i = 0; i < 24; i++)
		if (pg_strcasecmp(field, months[i]) == 0)
			return true;
	return false;
}

/*
 * This function will check whether the first 3 inputs are in any of the format
 * {"DD MON YYYY", "DD YYYY MON", "MON DD YYYY", "MON YYYY DD", "YYYY MON DD", "YYYY DD MON"}
 * where MON is valid month in text format then returns true if present.
 * Additional to that if Month is present in 1st or 3rd field then will swap the field with 2nd
 * field i.e., if the fields are of format {"DD YYYY MON", "MON DD YYYY", "MON YYYY DD", "YYYY DD MON"}
 * then will be converted to {"DD MON YYYY", "YYYY MON DD"} because later the fields will be changed
 * to format {"DD-MON-YYYY", "DD-YYYY-MON", "MON-DD-YYYY", "MON-YYYY-DD", "YYYY-MON-DD", "YYYY-DD-MON"}
 * out of which only formats {"DD-MON-YYYY", "YYYY-MON-DD"} are valid.
 */
static bool containsInTextMonthFormat(int *ftype, char **field)
{
	int count_number = 0, count_string = 0;

	#define SWAP_FIELDS(i, j) \
		char* temp_field;	\
		int temp_ftype;	\
		temp_field = field[i];	\
		temp_ftype = ftype[i];	\
		field[i] = field[j];	\
		field[j] = temp_field;	\
		ftype[i] = ftype[j];	\
		ftype[j] = temp_ftype;	\

	for (int i = 0; i < 3; i++)
	{
		if (ftype[i] == DTK_NUMBER)
			count_number++;
		else if (ftype[i] == DTK_STRING)
		{
			/* Check whether the string is valid text month */
			if (!isTextMonthPresent(field[i]))
				return false;
			count_string++;
		}
		else
			return false;
	}
	if (count_number == 2 && count_string == 1)
	{
		/*
		 * If the first field and third field is an string then swap with the second field
		 * as when the date is given separatly then all different forms of
		 * dates is supported. To avoid the conversion failure from `isTextMonthPresent`
		 * later we are swapping earlier. And convert to Supported date formats which are
		 * {"DD-MON-YYYY", "YYYY-MON-DD"}
		 *
		 * For example convert the input from "JULY 23 2000" to "23 JULY 2000"
		 * and convert the input from "23 2000 JULY" to "23 JULY 2000".
		 */
		if (ftype[0] == DTK_STRING)
		{
			SWAP_FIELDS(0, 1);
		}
		else if (ftype[2] == DTK_STRING)
		{
			SWAP_FIELDS(1, 2);
		}
		return true;
	}
	return false;
}

/*
 * pltsql_time_in
 *		The function modifies the given input into valid form and
 *		stores the output to result. If there are any errors then
 *		an error message will be thrown.
 * Returns
 * 		false - If the sql_dialect is not an TSQL and proceed with
 * 			the original behaviour
 * 		true - If the sql_dialect is an TSQL
 */
bool pltsql_time_in(const char* str, int32 typmod, TimeADT *result)
{
	fsec_t fsec;
	struct pg_tm tt, *tm = &tt;
	int tz, nf, dterr, dtype, ftype[MAXDATEFIELDS];
	char workbuf[MAXDATELEN + 1], *field[MAXDATEFIELDS];
	StringInfo res;
	regex_t time_regex;
	char *pattern, *temp_field;
	int len_str = strlen(str);
	char *modified_str = (char*) palloc(len_str + 1);
	int j = 0, i = 0;

	/* If sql_dialect is not an TSQL then return false */
	if (sql_dialect != SQL_DIALECT_TSQL)
		return false;

	/* Throw a common error message while casting to time datatype */
	#define TIME_IN_ERROR()	\
		ereport(ERROR,	\
				(errcode(ERRCODE_INVALID_DATETIME_FORMAT),	\
				 errmsg("Conversion failed when converting date and/or time from character string.")));	\

	/*
	 * The below logic removes the space present before and after of ':', '/',
	 * '.', '-' and also removes the multiple whitespaces to single whitespace.
	 * For example converts the input from "    1  :     1" to " 1:1"
	 */
	while (i < len_str)
	{
		if (str[i] == ' ' && (i == (len_str - 1) || str[i+1] == ' ' || str[i+1] == ':' || str[i+1] == '/' || str[i+1] == '.' || str[i+1] == '-'))
		{
			i++;
			continue;
		}
		else if (str[i] == ':' || str[i] == '/' || str[i] == '.' || str[i] == '-')
		{
			modified_str[j++] = str[i++];
			while (i < len_str && str[i] == ' ')
				i++;
		}
		else
			modified_str[j++] = str[i++];
	}
	modified_str[j] = '\0';

	dterr = ParseDateTime(modified_str, workbuf, sizeof(workbuf),
			field, ftype, MAXDATEFIELDS, &nf);

	/*
	 * If there are no errors while parsing the modified_str then
	 * validate the fields based on their types.
	 */
	if (dterr == 0)
	{
		if (nf >= 3)
		{
			/*
			 * If the total no.of fields is >=3 then there is an possiblity that
			 * the modified_str contains text month and can be of any format
			 * {"DD MON YYYY", "DD YYYY MON", "MON DD YYYY", "MON YYYY DD",
			 * "YYYY MON DD", "YYYY DD MON"} then convert the fields to an valid
			 * format of {"DD-MON-YYYY", "YYYY-MON-DD"} and change type to "DTK_DATE"
			 */
			if (containsInTextMonthFormat(ftype, field))
			{
				/*
				 * The below logic will append the field[1], field[2] to the field[0]
				 * and change the type of field[0] to "DTK_DATE".
				 * For example if input is "2000 nov 23" will be converted
				 * to "2000-nov-23".
				 */
				res = makeStringInfo();
				appendStringInfo(res, "%s-%s-%s", field[0], field[1], field[2]);
				field[0] = res->data;
				ftype[0] = DTK_DATE;
				pfree(res);

				/*
				 * Since the first 3 fields appended to 1st field, skip the
				 * attached fields i.e., field[1]/[2], ftype[1]/[2]
				 */
				nf = nf - 2;
				for(int i = 1; i < nf; i++)
				{
					field[i] = field[i+2];
					ftype[i] = ftype[i+2];
				}
			}
		}

		/*
		 * Iterate through each fields and do pre-validation of that field,
		 * throw error if the field is in invalid format.
		 */
		for (int i = 0; i < nf; i++)
		{
			int len;
			char* different_date_formats[] = {"/", ".", "-"};
			temp_field = pstrdup(field[i]);
			len = strlen(temp_field);

			switch (ftype[i])
			{
				case DTK_NUMBER:
					/*
					 * If there is an number field present in the field
					 * then following conditions should be satisfied based
					 * on the length of the numeric field.
					 * 1. len = 1,2 : The next field should contain "[ap]m" and
					 * 		this field will be modified to by appending ":00:00"
					 * 		and ftype will be considered as "DTK_TIME"
					 * 2. len = 4 : The field is considered as year of format "YYYY-01-01"
					 * 		and ftype will be modified to "DTK_DATE"
					 * 3. len = 6 : The field is considered as format `"YY-MM-DD"
					 * 		and ftype will be modified to "DTK_DATE"
					 * 4. len = 8 : The field is considered as format "YYYY-MM-DD"
					 * 		and ftype will be modified to "DTK_DATE"
					 * 5. len = 3,5,7,>8 : Not an valid and should throw error
					 */
					switch (len)
					{
						case 1:
						case 2:
							/*
							 * Throw an error if next field doesn't exist or
							 * the next field is not "[ap]m"
							 */
							if (i == nf - 1 || ftype[i+1] != DTK_STRING)
								TIME_IN_ERROR();
							if (pg_strcasecmp(field[i+1], "am") == 0 || pg_strcasecmp(field[i+1], "pm") == 0)
							{
								/*
								 * For example if the input is "1 am"
								 * will be converted to "1:00:00 am".
								 */
								res = makeStringInfo();
								appendStringInfo(res, "%s%s", field[i], ":00:00");
								field[i] = res->data;
								ftype[i] = DTK_TIME;
								pfree(res);
							}
							else
								TIME_IN_ERROR();
							break;

						case 4:
							/*
							 * For example if input is "2000" will be converted
							 * to "2000-01-01".
							 */
							res = makeStringInfo();
							appendStringInfo(res, "%s%s", field[i], "-01-01");
							field[i] = res->data;
							ftype[i] = DTK_DATE;
							pfree(res);
							break;

						case 6:
						case 8:
							/*
							 * For example if input is "201213" will be converted
							 * to "20-12-13", and input "20001118" will be
							 * converted to "2000-11-18"
							 */
							res = makeStringInfo();
							for (int k = 0; k < len; k++)
							{
								appendStringInfo(res, "%c", temp_field[k]);
								if ((len == 6 && ((k + 1) % 2 == 0 && k < 5)) ||
										(len == 8 && (k == 3 || k == 5)))
									appendStringInfo(res, "%c", '-');
							}
							field[i] = res->data;
							ftype[i] = DTK_DATE;
							pfree(res);
							break;

						default:
							TIME_IN_ERROR();
					}
					break;

				case DTK_DATE:
					/*
					 * If the modified_str is of format "<DATE>T<TIME>", then the
					 * <DATE> should be of format "YYYY-MM-DD". If there are any
					 * other date formats then an error will be thrown.
					 */
					if (i == 0 && nf > 1 && field[1] && pg_strcasecmp(field[1], "t") == 0)
					{
						pattern = "^[1-9][0-9]{3}-[0-9]?[0-9]-[0-9]?[0-9]$";
						if (regcomp(&time_regex, pattern, REG_EXTENDED) != 0)
							ereport(ERROR,
										(errcode(ERRCODE_INTERNAL_ERROR),
										errmsg("time format internal error")));
						if (regexec(&time_regex, field[i], 0, NULL, 0) != 0)
							TIME_IN_ERROR();
						regfree(&time_regex);
					}
					/*
					 * If the date of modified_str is of any formats {"Mon{/.-}yyyy{/.-}dd",
					 * "Mon{/.-}dd{/.-}yyyy", "DD{/.-}MM{/.-}YYYY", "DD{/.-}YYYY{/.-}MM"}
					 * then these dates shouldn't be supported and an error should be thrown.
					 * Supported date formats are {"DD-MON-YYYY", "YYYY-MON-DD",
					 * "MM{-/.}DD{-/.}YYYY", "YYYY{-/.}MM{-/.}DD"}.
					 */
					else
					{
						for (int k = 0 ; k < 3; k++)
						{
							temp_field = strtok(temp_field, different_date_formats[k]);
							if (pg_strcasecmp(field[i], temp_field) != 0)
								break;
						}
						/*
						 * If valid text month is present in start of field like
						 * {"MON{/.-}YYYY{/.-}DD", "MON{/.-}DD{/.-}YYYY"} then
						 * an error should be thrown.
						 * Note: We are checking if text month at start because the
						 * function "containsInTextMonthFormat" will not be called
						 * if the modified_str contains {/.-} in the date.
						 */
						if (isTextMonthPresent(temp_field))
							TIME_IN_ERROR();

						/* If date is of format {"0YYYY-MON-0DD", "0DD-MON-0YYYY"} where 0's are
						 * present at the start of year or day then the dates are valid.
						 * But for the formats {"0MM{-/.}0DD{-/.}0YYYY", "0YYYY{-/.}0MM{-/.}0DD"}
						 * where 0 are present at the start of year/month/day then the dates are invalid.
						 *
						 * The below pattern will check whether text month is present in date and
						 * if text month is not present then the date should be of format
						 * {"MM{-/.}DD{-/.}YYYY", "YYYY{-/.}MM{-/.}DD"}
						 */
						pattern = "([a-z])";
						if (regcomp(&time_regex, pattern, REG_EXTENDED) != 0)
							ereport(ERROR,
										(errcode(ERRCODE_INTERNAL_ERROR),
										errmsg("time format internal error")));
						/* Text month not present */
						if (regexec(&time_regex, field[i], 0, NULL, 0) != 0)
						{
							pattern = "^([1-9][0-9]{3}|[0-9]{1,2})[-/.]([0-9]{1,2})[-/.]([1-9][0-9]{3}|[0-9]{1,2})$";
							regfree(&time_regex);
							if (regcomp(&time_regex, pattern, REG_EXTENDED) != 0)
								ereport(ERROR,
											(errcode(ERRCODE_INTERNAL_ERROR),
											errmsg("time format internal error")));
							if (regexec(&time_regex, field[i], 0, NULL, 0) != 0)
								TIME_IN_ERROR();
							regfree(&time_regex);
						}
					}
					break;

				case DTK_TIME:
					/*
					 * If the modified_str is of format "<DATE>T<TIME>", then the
					 * <TIME> field should be of format hh:mm:ss[.sss]
					 * where hh should definitely be 2 digit.
					 */
					if (i-1 == 1 && field[1] && pg_strcasecmp(field[1], "t") == 0)
						pattern = "^([0-1][0-9]|2[0-3])(:[0-5]?[0-9]:[0-5]?[0-9]?.[0-9]{1,9})?$";
					/* For all other time fields check if <TIME> is in hh:mm[:ss][.nnn] format */
					else
						pattern = "^([0-1]?[0-9]|2[0-3]|[0-9])(:[0-5]?[0-9])(:[0-5]?[0-9]|:[0-5]?[0-9]?.[0-9]{1,9})?$";

					if (regcomp(&time_regex, pattern, REG_EXTENDED) != 0)
						ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("time format internal error")));
					if (regexec(&time_regex, field[i], 0, NULL, 0) != 0)
						TIME_IN_ERROR();
					regfree(&time_regex);
					break;

				case DTK_TZ:
					/*
					 * If the input contains timezone then the format should be "[+-]ZZ:ZZ" and the previous field should be time.
					 */
					if(i-1 < 0 || (i-1 >= 0 && ftype[i-1] != DTK_TIME))
						TIME_IN_ERROR();
					pattern = "([0-9]?[0-9]:[0-9]?[0-9])$";
					if (regcomp(&time_regex, pattern, REG_EXTENDED) != 0)
						ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("time format internal error")));
					if (regexec(&time_regex, field[i], 0, NULL, 0) != 0)
						TIME_IN_ERROR();
					regfree(&time_regex);
					break;

				default:
					break;
			}
			/* Free the temp_field which stores the field[i] value */
			pfree(temp_field);
		}
		switch (nf)
		{
			case 1:
				/*
				 * If only date is specified then add an default
				 * time of 00:00:00
				 */
				if (ftype[0] == DTK_DATE)
				{
					ftype[1] = DTK_TIME;
					field[1] = "00:00:00";
					nf = nf + 1;
				}
				break;

			case 3:
				/*
				 * If the given modified_str is of valid format "YYYY-MM-DDThh:mm:ss"
				 * then convert it to "YYYY-MM-DD hh:mm:ss" by ignoring 'T'.
				 * Invalid formats are {"YYYY-MM-DDthh:mm:ss", "YYYY-MM-DDT hh:mm:ss"}
				 * Note: The DATE and TIME validation are already done above for those
				 * particular type.
				 */
				if (ftype[1] == DTK_STRING && pg_strcasecmp(field[1], "t") == 0 && ftype[2] == DTK_TIME)
				{
					/*
					 * Since the modified_str is of format "<DATE>T<TIME>" and if modified_str
					 * contains "t" then throw error. Here we are comparing the "t" with the modified_str
					 * as the field always contain "t" irrespective of original modified_str because
					 * while parsing the modified_str all the [A-Z] are converted to [a-z].
					 */
					pattern = "t";
					if (regcomp(&time_regex, pattern, 0) != 0)
						ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("time format internal error")));
					if (!regexec(&time_regex, modified_str, 0, NULL, 0))
						TIME_IN_ERROR();
					regfree(&time_regex);

					ftype[1] = ftype[2];
					field[1] = field[2];
					nf = nf - 1;
				}
				break;

			default:
				break;
		}

		dterr = DecodeTimeOnly(field, ftype, nf, &dtype, tm, &fsec, &tz);
	}
	pfree(modified_str);

	if (dterr != 0)
		TIME_IN_ERROR();

	tm2time(tm, fsec, result);
	AdjustTimeForTypmod(result, typmod);

	return true;
}

Datum
datetime_mi_datetime(PG_FUNCTION_ARGS)
{
	Timestamp	timestamp1 = PG_GETARG_TIMESTAMP(0);
	Timestamp	timestamp2 = PG_GETARG_TIMESTAMP(1);
	Timestamp	diff;
	Timestamp	result;

	/*
	 * calculate interval from timestamp2. It should be calculated as the
	 * difference from 1900-01-01 00:00:00 (default datetime)
	 */
	diff = timestamp2 - initializeToDefaultDatetime();

	/* subtract interval */
	result = timestamp1 - diff;

	CheckDatetimeRange(result);
	PG_RETURN_TIMESTAMP(result);
}
