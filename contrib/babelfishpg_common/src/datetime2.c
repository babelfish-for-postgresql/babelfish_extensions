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
static Datum datetime2_in_str(char *str, int32 typmod, Node *escontext);
void		CheckDatetime2Range(const Timestamp time, Node *escontext);

static char*
clean_input_str(char *str, bool *contains_extra_spaces)
{
	char *result = (char *) palloc(MAXDATELEN);
	int i = 0, j = 0;
	int last_non_space = -1;

	while (str[i] != '\0')
	{
		/*
		 * Remove leading spaces
		 */
		while (str[i] != '\0' && isspace(str[i]))
		{
			if (i != 0)
				*contains_extra_spaces = true;
			i++;
		}

		if (str[i] == '\0')
			break;

		if (isalpha(str[i]))
		{
			if (!isdigit(str[last_non_space]) && !isalpha(str[last_non_space]))
			{
				result[j] = str[i];
				j++;
			}
			else if (isdigit(str[last_non_space]))
			{
				result[j] = ' ';
				result[j+1] = str[i];
				j+=2;
			}
			else if (last_non_space == i-1)
			{
				result[j] = str[i];
				j++;
			}
			else
			{
				result[j] = ' ';
				result[j+1] = str[i];
				j+=2;
			}
		}
		
		else if (isdigit(str[i]))
		{
			
			if (!isdigit(str[last_non_space]) && !isalpha(str[last_non_space]))
			{
				result[j] = str[i];
				j++;
			}
			else if (isalpha(str[last_non_space]))
			{
				result[j] = ' ';
				result[j+1] = str[i];
				j+=2;
			}
			else if (last_non_space == i-1)
			{
				result[j] = str[i];
				j++;
			}
			else
			{
				result[j] = ' ';
				result[j+1] = str[i];
				j+=2;
			}
		}
		else
		{
			result[j] = str[i];
			j++;
		}

		last_non_space = i;
		i++;
	}

	result[j] = '\0';

	return result;
	
}

static void
tsql_decode_datetime2_fields(char *str, char **field, int nf, int ftype[], 
				bool contains_extra_spaces, struct pg_tm *tm,
				bool *is_year_set)
{
	int i, num_colons = 0, time_idx = nf;
	/*
	 * Modify time field to accept ':' as separator for
	 * seconds and milliseconds.
	 * Also, throw error if '.' is used as separator for
	 * any other combination.
	 */
	for (i = 0; i < nf; i++)
	{
		char	*cp;
		if (ftype[i] != DTK_TIME)
		{
			continue;
		}
		time_idx = i;
		cp = field[i];
		strtoi64(cp, &cp, 10);
		while (*cp == ':')
		{
			num_colons++;
			if(num_colons == 3)
			{
				*cp = '.';
				break;
			}
			cp++;
			strtoi64(cp, &cp, 10);
		}

		if (num_colons < 2 && cp != NULL && *cp == '.')
		{
			ereport(ERROR,
				(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
				errmsg("invalid input syntax for type datetime2: \"%s\"", str)));
		}

		break;
	}

	/*
	 * Number of DATE fields can not be more than 3 in any case.
	 */
	if (time_idx > 3)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
				errmsg("invalid input syntax for type datetime2: \"%s\"", str)));

	/*
	 * If there is a text month in the input str, move it to the 
	 * beginning of the DATE field.
	 * Also, if it is in ISO 8601 format, we need to check whether
	 * input str is matching 'YYYY-MM-DDThh:mm:ss[.mmm]' format.
	 */
	for (i = 0; i < time_idx; i++)
	{
		if (ftype[i] == DTK_STRING)
		{
			int j = i-1, temp_int;
			char *temp;

			ftype[i] = DecodeSpecial(i, field[i], &temp_int);

			if (ftype[i] == ISOTIME && (contains_extra_spaces || num_colons != 2))
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
						errmsg("invalid input syntax for type datetime2: \"%s\"", str)));

			if(ftype[i] != MONTH)
			{
				ftype[i] = DTK_STRING;
				continue;
			}

			if(!check_regex_for_text_month(str, DATE_TIME_2))
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
						errmsg("invalid input syntax for type datetime2: \"%s\"", str)));

			tm->tm_mon = temp_int;

			while (j>=0)
			{
				/* Swap ftype entries */
				temp_int = ftype[j];
				ftype[j] = ftype[j+1];
				ftype[j+1] = temp_int;

				/* Swap field entries */
				temp = field[j];
				field[j] = field[j+1];
				field[j+1] = temp;

				j--;
			}
		}
		else if (ftype[i] == DTK_NUMBER)
		{
			int field_len = strlen(field[i]);
			if (time_idx > 2)
				continue;

			if (field_len == 4)
			{
				tm->tm_year = atoi(field[i]);
				*is_year_set = true;
			}
			else if (field_len == 2 && time_idx == 2)
			{
				int temp = atoi(field[i]);
				tm->tm_year = (temp < 50) ? (2000 + temp) : (1900 + temp);
				*is_year_set = true;
			}
			else if (time_idx != 1 || (field_len != 8 && field_len != 6))
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
						errmsg("invalid input syntax for type datetime2: \"%s\"", str)));
		}
		else if (ftype[i] == DTK_DATE && strlen(field[i]) > 10)
			ereport(ERROR,
						(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
						errmsg("invalid input syntax for type datetime2: \"%s\"", str)));
	}
}

/* datetime2_in_str()
 * Convert a string to internal form.
 * Most parts of this functions is same as timestamp_in(),
 * but we use a different rounding function for datetime2.
 */
static Datum
datetime2_in_str(char *str, int32 typmod, Node *escontext)
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
	bool		contains_extra_spaces = false;
	bool		is_year_set = false;
	DateTimeErrorExtra extra;

	tm->tm_year = 0;
	tm->tm_mon = 0;
	tm->tm_mday = 0;

	/* Set input to default '1900-01-01 00:00:00.* if empty string encountered */
	if (*str == '\0')
	{
		result = initializeToDefaultDatetime();
		AdjustDatetime2ForTypmod(&result, typmod);

		PG_RETURN_TIMESTAMP(result);
	}

	str = clean_input_str(str, &contains_extra_spaces);

	dterr = ParseDateTime(str, workbuf, sizeof(workbuf),
						  field, ftype, MAXDATEFIELDS, &nf);

	tsql_decode_datetime2_fields(str, field, nf, ftype, 
								contains_extra_spaces, tm, &is_year_set);

	if (dterr == 0)
		dterr = DecodeDateTime(field, ftype, nf, 
							   &dtype, tm, &fsec, &tz, &extra);

	/*
	 * dterr == 1 means that input is TIME format(e.g 12:34:59.123) initialize
	 * other necessary date parts and accept input format
	 */
	if (dterr == 1 || is_year_set)
	{
		if (!is_year_set)
			tm->tm_year = 1900;
		if (!tm->tm_mon)
			tm->tm_mon = 1;
		if (is_year_set || !tm->tm_mday)
			tm->tm_mday = 1;
		dterr = 0;
	}

	if (dterr != 0)
		DateTimeParseError(dterr, &extra, str, "datetime2", escontext);

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
	CheckDatetime2Range(result, escontext);

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

	return datetime2_in_str(str, typmod, fcinfo->context);
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
CheckDatetime2Range(const Timestamp time, Node *escontext)
{
	if (!IS_VALID_DATETIME2(time))
	{
		errsave(escontext,
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

	CheckDatetime2Range(result, fcinfo->context);
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
	CheckDatetime2Range(result, fcinfo->context);
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

	return datetime2_in_str(str, MAX_TIMESTAMP_PRECISION, fcinfo->context);
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

	return datetime2_in_str(str, MAX_TIMESTAMP_PRECISION, fcinfo->context);
}
