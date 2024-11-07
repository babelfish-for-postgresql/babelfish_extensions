/*-------------------------------------------------------------------------
 *
 * datetime.c
 *	  Functions for the type "datetime".
 *
 *-------------------------------------------------------------------------
 */

#include <regex.h>
#include "postgres.h"

#include "fmgr.h"
#include "varatt.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/numeric.h"
#include "utils/timestamp.h"
#include "libpq/pqformat.h"
#include "parser/scansup.h"
#include "common/int.h"
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

PG_FUNCTION_INFO_V1(datetime_to_bit);
PG_FUNCTION_INFO_V1(datetime_to_int2);
PG_FUNCTION_INFO_V1(datetime_to_int4);
PG_FUNCTION_INFO_V1(datetime_to_int8);
PG_FUNCTION_INFO_V1(datetime_to_float4);
PG_FUNCTION_INFO_V1(datetime_to_float8);
PG_FUNCTION_INFO_V1(datetime_to_numeric);

PG_FUNCTION_INFO_V1(dateadd_datetime);
PG_FUNCTION_INFO_V1(timestamp_diff);
PG_FUNCTION_INFO_V1(timestamp_diff_big);

void		CheckDatetimeRange(const Timestamp time, Node *escontext);
void		CheckDatetimePrecision(fsec_t fsec);

#define DTK_NANO 32

static bool
match_regex(char *str, char *regex_exp)
{
	regex_t regex;
	int status;
	status = regcomp(&regex, regex_exp, REG_EXTENDED);
    	status = regexec(&regex, str, 0, NULL, 0);
    	regfree(&regex);
	
	if (status == 0)
		return true;
	
	return false;
}

/*
 * This function checks the regex in case of the text month.
 * We will be checking with the combination of date regex's and
 * time regex's.
 */
bool
check_regex_for_text_month(char *str, DateTimeContext context)
{
	char curr_regex[200];
    	int i, j;
	const char *regex_time_offset = "(((\\+|\\-)[0-9]{1,2}:[0-9]{1,2})|Z)?";
	const char *datetime2_offset_supported[] = {
		"[0-9]{2}\\s*[a-zA-Z]{3,10}",
		"[a-zA-Z]{3,10}\\s*[0-9]{2}"
	};
	const int num_datetime2_offset_supported = lengthof(datetime2_offset_supported);

	for (i = 0; i < num_datetime2_offset_supported; i++) {
		for (j = 0; j < NUM_TIME_REGEXES; j++) {
			if (context == DATE_TIME)
				break;
	    		/*
			 * check for the combination of date and time
			 */
			strcpy(curr_regex, "^");
			strcat(curr_regex, datetime2_offset_supported[i]);
            		strcat(curr_regex, "\\s+");
            		strcat(curr_regex, time_regexes[j]);
			if (context == DATE_TIME_OFFSET)
			{
				strcat(curr_regex, "\\s*");
            			strcat(curr_regex, regex_time_offset);
			}
			strcat(curr_regex, "$");

			if(match_regex(str, curr_regex))
				return true;
		}
	}

	for (i = 0; i < NUM_DATE_REGEXES; i++) {
		/*
		 * check for just date syntax
		 */
		strcpy(curr_regex, "^");
        	strcat(curr_regex, date_regexes[i]);
        	strcat(curr_regex, "$");

		if(match_regex(str, curr_regex))
			return true;

        	for (j = 0; j < NUM_TIME_REGEXES; j++) {
			/*
			 * check for just time syntax
			 */
			strcpy(curr_regex, "^");
        		strcat(curr_regex, time_regexes[j]);
			if (context == DATE_TIME_OFFSET)
			{
				strcat(curr_regex, "\\s*");
            			strcat(curr_regex, regex_time_offset);
			}
        		strcat(curr_regex, "$");

			if(match_regex(str, curr_regex))
				return true;
	    		/*
			 * check for the combination of date and time
			 */
			strcpy(curr_regex, "^");
			strcat(curr_regex, date_regexes[i]);
            		strcat(curr_regex, "\\s+");
            		strcat(curr_regex, time_regexes[j]);
			if (context == DATE_TIME_OFFSET)
			{
				strcat(curr_regex, "\\s*");
            			strcat(curr_regex, regex_time_offset);
			}
			strcat(curr_regex, "$");

			if(match_regex(str, curr_regex))
				return true;
        	}
    	}

	return false;
}

/*
 * This function cleans up the input string by removing
 * unnecessary spaces between the fields.
 */
char*
clean_input_str(char *str, bool *contains_extra_spaces, DateTimeContext context)
{
	char *result = (char *) palloc(MAXDATELEN + 1);
	int i = 0, j = 0;
	int last_non_space = -1;
	int num_colons = 0;
	char *context_str = (context == DATE_TIME) ? "datetime" 
			: ((context == DATE_TIME_2) ? "datetime2" : "datetimeoffset");

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

		if (j >= MAXDATELEN)
		{
			if (result)
				pfree(result);

			ereport(ERROR,
					(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
					errmsg("invalid input syntax for type %s: \"%s\"", context_str, str)));
		}
		
		if (context == DATE_TIME_OFFSET && str[i] == ':')
			num_colons++;

		/*
		 * Modify DATE delimiters to '.' as in DATETIME multiple delimiters can
		 * be passed for DATE field.
		 */
		if (context == DATE_TIME && (str[i] == '/' || str[i] == '-' || str[i] == '.'))
		{
			result[j] = '.';
			j++;
		}
		/*
		 * If the current character is an alphabet, do not add
		 * space if the last non space character is a delimiter,
		 * else an additional space is required.
		 */
		else if (isalpha(str[i]))
		{
			if (last_non_space == -1 ||
				(!isdigit(str[last_non_space]) && !isalpha(str[last_non_space])))
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
		/*
		 * If the current character is a digit, do not add
		 * space if the last non space character is a delimiter,
		 * else an additional space is required.
		 */
		else if (isdigit(str[i]))
		{
			
			if (last_non_space == -1 || 
				(!isdigit(str[last_non_space]) && !isalpha(str[last_non_space])))
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
		/*
		 * If the context is DATETIME only ',' and ':' are allowed
		 * other than above mentioned characters.
		 */
		else if ((str[i] == ',' || str[i] == ':') || 
				(context != DATE_TIME && (str[i] == '.' || str[i] == '/' 
				|| str[i] == '+' || str[i] == '-')))
		{
			result[j] = str[i];
			j++;
		}
		else
		{
			if (result)
				pfree(result);
			
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
					errmsg("invalid input syntax for type %s: \"%s\"", context_str, str)));
		}

		last_non_space = i;
		i++;
	}

	result[j] = '\0';

	return result;
	
}

static bool
tsql_decode_datetime_fields(char *orig_str, char *str, char **field, int nf, int ftype[], 
						bool contains_extra_spaces, struct pg_tm *tm,
						bool *is_year_set)
{
	int start_idx = 0, last_idx = nf, time_idx = -1;
	int i = 0, num_colons = 0, number_fields = 0;
	bool date_exists = false, am_pm = false, contains_text_month = false, contains_time = false;

	/*
	 * Modify time field to accept ':' as separator for
	 * seconds and milliseconds.
	 */
	for (i = 0; i < nf; i++)
	{
		if (ftype[i] == DTK_NUMBER)
			number_fields++;
		else if (ftype[i] == DTK_DATE)
			date_exists = true;
		else if (ftype[i] == DTK_TIME)
		{
			char	*cp;

			contains_time = true;

			time_idx = i;
			cp = field[time_idx];

			strtoi64(cp, &cp, 10);
			while (*cp == ':')
			{
				num_colons++;
				if(num_colons == 3)
				{
					if (strlen(cp) > 4)
						return 1;

					*cp = '.';
					break;
				}
				cp++;
				strtoi64(cp, &cp, 10);
			}

			if (num_colons == 1 && cp != NULL && *cp == '.')
				*cp = ':';

			if (i+1 < nf && (pg_strcasecmp(field[i+1], "AM") == 0 ||
				pg_strcasecmp(field[i+1], "PM") == 0))
			{
				am_pm = true;
				start_idx = (i==0) ? 2 : 0;
				last_idx = (start_idx==0) ? i : nf;
			}
			else
			{
				start_idx = (i == 0) ? 1 : 0;
				last_idx = (i == 0) ? nf : nf-1;
			}
		}				
	}
	/*
	 * Number of DATE fields can not be more than 3 in any case.
	 */
	if (last_idx - start_idx > 3)
		return 1;

	/*
	 * If there is a text month in the input str, move it to the 
	 * beginning of the DATE field.
	 * Also, if it is in ISO 8601 format, we need to check whether
	 * input str is matching 'YYYY-MM-DDThh:mm:ss[.mmm]' format.
	 */
	for (i = start_idx; i < last_idx; i++)
	{
		if (ftype[i] == DTK_STRING)
		{
			int j = i-1, temp_int;
			char *temp;

			ftype[i] = DecodeSpecial(i, field[i], &temp_int);

			if (ftype[i] == ISOTIME && (contains_extra_spaces || num_colons < 2))
				return 1;
			
			else if (ftype[i] == ISOTIME)
			{
				char *regex_exp = "^[0-9]{4}[-][0-9]{2}[-][0-9]{2}[T][0-9]{2}[:][0-9]{2}[:][0-9]{2}([.][0-9]{1,3})?$";
				
				if (!match_regex(orig_str, regex_exp))
					return 1;
			}

			if(ftype[i] != MONTH)
			{
				ftype[i] = DTK_STRING;
				continue;
			}

			contains_text_month = true;

			if(!check_regex_for_text_month(str, DATE_TIME))
				return 1;

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
		else if (ftype[i] == DTK_NUMBER && !date_exists)
		{
			int field_len = strlen(field[i]);
			if (last_idx - start_idx > 2)
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
			else if (last_idx - start_idx != 1 || (field_len != 8 && field_len != 6))
				return 1;


		}
		else if (ftype[i] == DTK_DATE)
		{
			/*
			 * Check whether the field contains any alphabet.
			 * If yes, it might contain text month. 
			 * If no alphabet are found, we need to check whether the
			 * length of the DATE field is less than 10. Throw error if it
			 * exceeds.
			 */
			char *cp = field[i];
			/* regex expression for "[m]m-yyyy-[d]d" format */
			char *regex_expr = "^[0-9]{1,2}[-|.|/][0-9]{4}[-|.|/][0-9]{1,2}$";

			while (cp != NULL && *cp != '\0' && !isalpha(*cp))
				cp++;
			
			if (cp != NULL && isalpha(*cp))
				continue;
			
			/*
			 * If the DATE is in mm-yyyy-dd format, DecodeDateTime
			 * throws error, hence we need to rearrange it the DATE string
			 * to mm-dd-yyyy format
			 */
			
			if (match_regex(field[i], regex_expr))
			{
				int month = 0, year = 0, day = 0;
				cp = field[i];

				month = strtoi64(cp, &cp, 10);
				cp++;
				year = strtoi64(cp, &cp, 10);
				cp++;
				day = strtoi64(cp, &cp, 10);

				sprintf(field[i], "%d.%d.%d", month, day, year);
			}

			if (strlen(field[i]) > 10)
				return 1;
		}
	}

	/*
	 * Date delimiter should not be a space ' '. ParseDateTime() allows
	 * ' ' as a delimiter for DATE field. But, in T-SQL it should be blocked.
	 * Hence, check the number of DTK_NUMBER fields.
	 */
	if (!am_pm || contains_time)
		return (contains_text_month) ? (number_fields > 2) : (number_fields > 1);
	else
		return (contains_text_month) ? (number_fields > 3) : (number_fields > 1);

	return 0;
}


Datum
datetime_in_str(char *str, Node *escontext)
{
#ifdef NOT_USED
	Oid			typelem = PG_GETARG_OID(1);
#endif
	Timestamp	result;
	fsec_t		fsec;
	struct pg_tm tt,
			   *tm = &tt;
	int			tz;
	int			dtype = -1;
	int			nf;
	int			dterr;
	DateTimeErrorExtra extra;
	char	   *field[MAXDATEFIELDS];
	int			ftype[MAXDATEFIELDS];
	char		workbuf[MAXDATELEN + MAXDATEFIELDS];
	bool		contains_extra_spaces = false;
	bool		is_year_set = false;
	char		*modified_str;

	/*
	 * Set input to default '1900-01-01 00:00:00.000' if empty string
	 * encountered
	 */
	if (*str == '\0')
	{
		result = initializeToDefaultDatetime();
		PG_RETURN_TIMESTAMP(result);
	}

	tm->tm_year = 0;
	tm->tm_mon = 0;
	tm->tm_mday = 0;

	modified_str = clean_input_str(str, &contains_extra_spaces, DATE_TIME);

	dterr = ParseDateTime(modified_str, workbuf, sizeof(workbuf),
						  field, ftype, MAXDATEFIELDS, &nf);

	/*
	 * throw error if the return value is not zero.
	 */
	if(tsql_decode_datetime_fields(str, modified_str, field, nf, ftype, 
					contains_extra_spaces, tm, &is_year_set))
	{
		if (modified_str)
			pfree(modified_str);

		ereport(ERROR,
				(errcode(ERRCODE_INVALID_DATETIME_FORMAT),
				errmsg("invalid input syntax for type datetime: \"%s\"", str)));
	}

	if (modified_str)
		pfree(modified_str);
	
	if (dterr == 0)
		dterr = DecodeDateTime(field, ftype, nf, 
							&dtype, tm, &fsec, &tz, &extra);

	/* dterr == 1 means that input is TIME format(e.g 12:34:59.123) */
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
	else if(dterr == 1)
	{
		tm->tm_mon = 1;
		tm->tm_mday = 1;
		dterr = 0;
	}

	if (dterr != 0)
		DateTimeParseError(dterr, &extra, str, "datetime", escontext);
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
	CheckDatetimeRange(result, escontext);
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

	return datetime_in_str(str, fcinfo->context);
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
CheckDatetimeRange(const Timestamp time, Node *escontext)
{
	if (!IS_VALID_DATETIME(time))
	{
		errsave(escontext,
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

	CheckDatetimeRange(result, fcinfo->context);
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

	CheckDatetimeRange(result, fcinfo->context);
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
	CheckDatetimeRange(result, fcinfo->context);
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

	return datetime_in_str(str, fcinfo->context);
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

	return datetime_in_str(str, fcinfo->context);
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

	CheckDatetimeRange(result, fcinfo->context);
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

	CheckDatetimeRange(result, fcinfo->context);
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

	CheckDatetimeRange(result, fcinfo->context);
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


	CheckDatetimeRange(result, fcinfo->context);
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

	CheckDatetimeRange(result, fcinfo->context);
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

	CheckDatetimeRange(result, fcinfo->context);
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

	CheckDatetimeRange(result, fcinfo->context);
	PG_RETURN_TIMESTAMP(result);
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

	CheckDatetimeRange(result, fcinfo->context);
	PG_RETURN_TIMESTAMP(result);
}

/*
* Common Utility function to calculate days elapsed from 1900-01-01 00:00:00 (default datetime)
* Days will contains whole as well as fractional part
*/
float8
calculateDaysFromDefaultDatetime(Timestamp timestamp_left)
{
	Timestamp timestamp_right;
	Interval   *result_interval;
	struct pg_itm tt, *itm = &tt;
	float8 result;
	int fsec_rounded = 0;

	timestamp_right = DirectFunctionCall6(make_timestamp, 1900, 1, 1, 0, 0, 0);
	result_interval = (Interval *) DirectFunctionCall2(timestamp_mi, timestamp_left, timestamp_right);
	interval2itm(*result_interval, itm);
	fsec_rounded = roundFractionalSeconds(itm->tm_usec/1000) * 1000;
	result = result_interval->day + (float8) (itm->tm_hour * USECS_PER_HOUR + itm->tm_min * USECS_PER_MINUTE + itm->tm_sec * USECS_PER_SEC + fsec_rounded)/(float8) USECS_PER_DAY;
	return result;
}

/** round datetime fractional seconds to fixed bins */
int roundFractionalSeconds(int v_fractseconds)
{
	int v_modpart;
   	int v_decpart;
    v_modpart = v_fractseconds % 10;
    v_decpart = v_fractseconds - v_modpart;

	 switch (v_modpart)
	 {
		case 0:
	 	case 1:
			return v_decpart;
		case 2:
	 	case 3:
		case 4:
      		return v_decpart + 3;
		case 5:
	 	case 6:
		case 7:
		case 8:
			return v_decpart + 7;
		default:
			return v_decpart + 10;
	 }
	 
}

Datum
datetime_to_bit(PG_FUNCTION_ARGS)
{
	Timestamp timestamp_left = PG_GETARG_TIMESTAMP(0);
	float8 result = calculateDaysFromDefaultDatetime(timestamp_left);
	PG_RETURN_BOOL((bool)result);
}

Datum
datetime_to_int2(PG_FUNCTION_ARGS)
{
	Timestamp timestamp_left = PG_GETARG_TIMESTAMP(0);
	float8 result = calculateDaysFromDefaultDatetime(timestamp_left);
	PG_RETURN_INT16((int16)round(result));
}


Datum
datetime_to_int4(PG_FUNCTION_ARGS)
{
	Timestamp timestamp_left = PG_GETARG_TIMESTAMP(0);
	float8 result = calculateDaysFromDefaultDatetime(timestamp_left);
	PG_RETURN_INT32((int32)round(result));
}

Datum
datetime_to_int8(PG_FUNCTION_ARGS)
{
	Timestamp timestamp_left = PG_GETARG_TIMESTAMP(0);
	float8 result = calculateDaysFromDefaultDatetime(timestamp_left);
	PG_RETURN_INT64((int64)round(result));
}

Datum
datetime_to_float4(PG_FUNCTION_ARGS)
{
	Timestamp timestamp_left = PG_GETARG_TIMESTAMP(0);
	float8 result = calculateDaysFromDefaultDatetime(timestamp_left);
	PG_RETURN_FLOAT4((float4)result);
}

Datum
datetime_to_float8(PG_FUNCTION_ARGS)
{
	Timestamp timestamp_left = PG_GETARG_TIMESTAMP(0);
	float8 result = calculateDaysFromDefaultDatetime(timestamp_left);
	PG_RETURN_FLOAT8((float8)result);
}

Datum
datetime_to_numeric(PG_FUNCTION_ARGS)
{
	Timestamp timestamp_left = PG_GETARG_TIMESTAMP(0);
	float8 result = calculateDaysFromDefaultDatetime(timestamp_left);
	return (DirectFunctionCall1(float8_numeric, Float8GetDatum(result)));
}

/*
 * Returns the difference of two timestamps based on a provided unit
 * INT64 representation for bigints
 */
Datum
timestamp_diff(PG_FUNCTION_ARGS)
{

	text        *field     = PG_GETARG_TEXT_PP(0);
	Timestamp	timestamp1 = PG_GETARG_TIMESTAMP(1);
	Timestamp	timestamp2 = PG_GETARG_TIMESTAMP(2);
	int32 diff = -1;
	int tm1Valid;
	int tm2Valid;
	int32 yeardiff;
	int32 monthdiff;
	int32 daydiff;
	int32 hourdiff;
	int32 minutediff;
	int32 seconddiff;
	int32 millisecdiff;
	int32 microsecdiff;
	struct pg_tm tt1,
			   *tm1 = &tt1;
	fsec_t		fsec1;
	struct pg_tm tt2,
			*tm2 = &tt2;
	fsec_t		fsec2;
	int			type,
				val;
	char	   *lowunits;
	bool       overflow = false;
	bool	   validDateDiff = true;

	tm1Valid = timestamp2tm(timestamp1, NULL, tm1, &fsec1, NULL, NULL);
	tm2Valid = timestamp2tm(timestamp2, NULL, tm2, &fsec2, NULL, NULL);

	lowunits = downcase_truncate_identifier(VARDATA_ANY(field),
										VARSIZE_ANY_EXHDR(field),
										false);

	type = DecodeUnits(0, lowunits, &val);

	// Decode units does not handle doy properly
	if(strncmp(lowunits, "doy", 3) == 0) {
		type = UNITS;
		val = DTK_DOY;
	}

	if(strncmp(lowunits, "nanosecond", 11) == 0) {
		type = UNITS;
		val = DTK_NANO;
	}
	if(strncmp(lowunits, "weekday", 7) == 0) {
		type = UNITS;
		val = DTK_DAY;
	}

	if(type == UNITS) {
		if(tm1Valid == 0 && tm2Valid == 0) {
			switch(val) {
				case DTK_YEAR:
					diff = tm2->tm_year - tm1->tm_year;
					break;
				case DTK_QUARTER:
					yeardiff = tm2->tm_year - tm1->tm_year;
					monthdiff = tm2->tm_mon - tm1->tm_mon;
					diff = (yeardiff * 12 + monthdiff) / 3;
					break;
				case DTK_MONTH:
					yeardiff = tm2->tm_year - tm1->tm_year;
					monthdiff = tm2->tm_mon - tm1->tm_mon;
					diff = yeardiff * 12 + monthdiff;
					break;
				case DTK_WEEK:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					diff = daydiff / 7;
					if(daydiff % 7 >= 4)
						diff++;
					break;
				case DTK_DAY:
				case DTK_DOY:
					diff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					break;
				case DTK_HOUR:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					overflow = (overflow || !(int32_multiply_add(daydiff, 24, &hourdiff)));
					diff = hourdiff;
					break;
				case DTK_MINUTE:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					overflow = (overflow || !(int32_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int32_multiply_add(hourdiff, 60, &minutediff)));
					diff = minutediff;
					break;
				case DTK_SECOND:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					overflow = (overflow || !(int32_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int32_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int32_multiply_add(minutediff, 60, &seconddiff)));
					diff = seconddiff;
					break;
				case DTK_MILLISEC:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					millisecdiff = (fsec2 / 1000) - (fsec1 / 1000);
					overflow = (overflow || !(int32_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int32_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int32_multiply_add(minutediff, 60, &seconddiff)));
					overflow = (overflow || !(int32_multiply_add(seconddiff, 1000, &millisecdiff)));
					diff = millisecdiff;
					break;
				case DTK_MICROSEC:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					microsecdiff = fsec2 - fsec1;
					overflow = (overflow || !(int32_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int32_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int32_multiply_add(minutediff, 60, &seconddiff)));
					overflow = (overflow || !(int32_multiply_add(seconddiff, 1000000, &microsecdiff)));
					diff = microsecdiff;
					break;
				case DTK_NANO:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					microsecdiff = fsec2 - fsec1;
					overflow = (overflow || !(int32_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int32_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int32_multiply_add(minutediff, 60, &seconddiff)));
					overflow = (overflow || !(int32_multiply_add(seconddiff, 1000000, &microsecdiff)));
					overflow = (overflow || (pg_mul_s32_overflow(microsecdiff, 1000, &diff)));
					break;
				default:
					validDateDiff = false;
					break;
			}
		}
		else {
			ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
		}
	} else {
		validDateDiff = false;
	}

	if(!validDateDiff) {
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("\'%s\' is not a recognized %s option", lowunits, "datediff")));
	}
	if(overflow) {
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("The datediff function resulted in an overflow. The number of dateparts separating two date/time instances is too large. Try to use datediff with a less precise datepart")));
	}

	PG_RETURN_INT32(diff);
}

/*
 * Returns the difference of two timestamps based on a provided unit
 * INT64 representation for bigints
 */
Datum
timestamp_diff_big(PG_FUNCTION_ARGS)
{
	text        *field     = PG_GETARG_TEXT_PP(0);
	Timestamp	timestamp1 = PG_GETARG_TIMESTAMP(1);
	Timestamp	timestamp2 = PG_GETARG_TIMESTAMP(2);
	int64 diff = -1;
	int tm1Valid;
	int tm2Valid;
	int64 yeardiff;
	int64 monthdiff;
	int64 daydiff;
	int64 hourdiff;
	int64 minutediff;
	int64 seconddiff;
	int64 millisecdiff;
	int64 microsecdiff;
	struct pg_tm tt1,
			   *tm1 = &tt1;
	fsec_t		fsec1;
	struct pg_tm tt2,
			*tm2 = &tt2;
	fsec_t		fsec2;
	int			type,
				val;
	char	   *lowunits;
	bool       overflow = false;
	bool	   validDateDiff = true;

	tm1Valid = timestamp2tm(timestamp1, NULL, tm1, &fsec1, NULL, NULL);
	tm2Valid = timestamp2tm(timestamp2, NULL, tm2, &fsec2, NULL, NULL);

	lowunits = downcase_truncate_identifier(VARDATA_ANY(field),
										VARSIZE_ANY_EXHDR(field),
										false);

	type = DecodeUnits(0, lowunits, &val);

	// Decode units does not handle doy or nano properly
	if(strncmp(lowunits, "doy", 3) == 0) {
		type = UNITS;
		val = DTK_DOY;
	}
	if(strncmp(lowunits, "nanosecond", 11) == 0) {
		type = UNITS;
		val = DTK_NANO;
	}
	if(strncmp(lowunits, "weekday", 7) == 0) {
		type = UNITS;
		val = DTK_DAY;
	}

	if(type == UNITS) {
		if(tm1Valid == 0 && tm2Valid == 0) {
			switch(val)
			{
				case DTK_YEAR:
					diff = tm2->tm_year - tm1->tm_year;
					break;
				case DTK_QUARTER:
					yeardiff = tm2->tm_year - tm1->tm_year;
					monthdiff = tm2->tm_mon - tm1->tm_mon;
					diff = (yeardiff * 12 + monthdiff) / 3;
					break;
				case DTK_MONTH:
					yeardiff = tm2->tm_year - tm1->tm_year;
					monthdiff = tm2->tm_mon - tm1->tm_mon;
					diff = yeardiff * 12 + monthdiff;
					break;
				case DTK_WEEK:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					diff = daydiff / 7;
					if(daydiff % 7 >= 4)
						diff++;
					break;
				case DTK_DAY:
				case DTK_DOY:
					diff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					break;
				case DTK_HOUR:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					overflow = (overflow || !(int64_multiply_add(daydiff, 24, &hourdiff)));
					diff = hourdiff;
					break;
				case DTK_MINUTE:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					overflow = (overflow || !(int64_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int64_multiply_add(hourdiff, 60, &minutediff)));
					diff = minutediff;
					break;
				case DTK_SECOND:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					overflow = (overflow || !(int64_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int64_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int64_multiply_add(minutediff, 60, &seconddiff)));
					diff = seconddiff;
					break;
				case DTK_MILLISEC:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					millisecdiff = (fsec2 / 1000) - (fsec1 / 1000);
					overflow = (overflow || !(int64_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int64_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int64_multiply_add(minutediff, 60, &seconddiff)));
					overflow = (overflow || !(int64_multiply_add(seconddiff, 1000, &millisecdiff)));
					diff = millisecdiff;
					break;
				case DTK_MICROSEC:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					microsecdiff = fsec2 - fsec1;
					overflow = (overflow || !(int64_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int64_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int64_multiply_add(minutediff, 60, &seconddiff)));
					overflow = (overflow || !(int64_multiply_add(seconddiff, 1000000, &microsecdiff)));
					diff = microsecdiff;
					break;
				case DTK_NANO:
					daydiff = days_in_date(tm2->tm_mday, tm2->tm_mon, tm2->tm_year) - days_in_date(tm1->tm_mday, tm1->tm_mon, tm1->tm_year);
					hourdiff = tm2->tm_hour - tm1->tm_hour;
					minutediff = tm2->tm_min - tm1->tm_min;
					seconddiff = tm2->tm_sec - tm1->tm_sec;
					microsecdiff = fsec2 - fsec1;
					overflow = (overflow || !(int64_multiply_add(daydiff, 24, &hourdiff)));
					overflow = (overflow || !(int64_multiply_add(hourdiff, 60, &minutediff)));
					overflow = (overflow || !(int64_multiply_add(minutediff, 60, &seconddiff)));
					overflow = (overflow || !(int64_multiply_add(seconddiff, 1000000, &microsecdiff)));
					overflow = (overflow || (pg_mul_s64_overflow(microsecdiff, 1000, &diff)));
					break;
				default:
					validDateDiff = false;
			}
		}
		else {
			ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp out of range")));
		}
	} else {
		validDateDiff = false;
	}

	if(!validDateDiff) {
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("\'%s\' is not a recognized %s option", lowunits, "datediff")));
	}
	if(overflow) {
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("The datediff function resulted in an overflow. The number of dateparts separating two date/time instances is too large. Try to use datediff with a less precise datepart")));
	}

	PG_RETURN_INT64(diff);
}

bool
int64_multiply_add(int64 val, int64 multiplier, int64 *sum)
{
	int64		product;

	if (pg_mul_s64_overflow(val, multiplier, &product) ||
		pg_add_s64_overflow(*sum, product, sum))
		return false;
	return true;
}

bool
int32_multiply_add(int32 val, int32 multiplier, int32 *sum)
{
	int32		product;

	if (pg_mul_s32_overflow(val, multiplier, &product) ||
		pg_add_s32_overflow(*sum, product, sum))
		return false;
	return true;
}

int days_in_date(int day, int month, int year) {
	int n1 = year * 365 + day;
	for(int i = 1; i < month; i++) {
		if(i == 2)
			n1 += 28;
		else if(i == 4 || i == 6 || i == 9 || i == 11)
			n1 += 30;
		else
			n1 += 31;
	}
	if(month <= 2)
		year -= 1;
	n1 += (year / 4 - year / 100 + year / 400);
	return n1;
}

char *datetypeName(int num) {
	char* ret;
	switch(num) {
		case 0:
			ret = "time";
			break;
		case 1:
			ret = "date";
			break;
		case 2:
			ret = "smalldatetime";
			break;
		case 3:
			ret = "datetime";
			break;
		case 4:
			ret = "datetime2";
			break;
		default:
			ret = "unknown";
	}
	return ret;
}

Datum
dateadd_datetime(PG_FUNCTION_ARGS) {
	text    *field     = PG_GETARG_TEXT_PP(0);
	int      num       = PG_GETARG_INT32(1);
	enum Datetimetype {
		TIME,
		DATE,
		SMALLDATETIME,
		DATETIME,
		DATETIME2
	};
	Timestamp timestamp;
	enum Datetimetype dttype = PG_GETARG_INT32(3);
	char	   *lowunits;
	int			type,
				val;
	Timestamp result;
	Interval   *interval;
	bool validDateAdd = true;
	bool incompatibleDatePart = false;

	switch(dttype) {
		case TIME:
			timestamp = DirectFunctionCall1(time_datetime, (TimeADT) PG_GETARG_TIMEADT(2));
			break;
		case DATE:
			timestamp = DirectFunctionCall1(date_datetime, (DateADT) PG_GETARG_DATEADT(2));
			break;
		default:
			timestamp = PG_GETARG_TIMESTAMP(2);
	}

	lowunits = downcase_truncate_identifier(VARDATA_ANY(field),
									VARSIZE_ANY_EXHDR(field),
									false);

	type = DecodeUnits(0, lowunits, &val);

	if(strncmp(lowunits, "doy", 3) == 0 || strncmp(lowunits, "dayofyear", 9) == 0) {
		type = UNITS;
		val = DTK_DOY;
	}
	if(strncmp(lowunits, "nanosecond", 11) == 0) {
		type = UNITS;
		val = DTK_NANO;
	}
	if(strncmp(lowunits, "weekday", 7) == 0) {
		type = UNITS;
		val = DTK_DAY;
	}


	if(type == UNITS) {
		PG_TRY();
		{
			switch(val) {
				case DTK_YEAR:
					if(dttype == TIME) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, num, 0, 0, 0, 0, 0, 0);
					break;
				case DTK_QUARTER:
					if(dttype == TIME) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, num * 3, 0, 0, 0, 0, 0);
					break;
				case DTK_MONTH:
					if(dttype == TIME) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, num, 0, 0, 0, 0, 0);
					break;
				case DTK_WEEK:
					if(dttype == TIME) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, num, 0, 0, 0, 0);
					break;
				case DTK_DAY:
				case DTK_DOY:
					if(dttype == TIME) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, num, 0, 0, 0);
					break;
				case DTK_HOUR:
					if(dttype == DATE) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, 0, num, 0, 0);
					break;
				case DTK_MINUTE:
					if(dttype == DATE) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, 0, 0, num, 0);
					break;
				case DTK_SECOND:
					if(dttype == DATE) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, 0, 0, 0, Float8GetDatum(num));
					break;
				case DTK_MILLISEC:
					if(dttype == DATE) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, 0, 0, 0, Float8GetDatum((float) num * 0.001));
					break;
				case DTK_MICROSEC:
					if(dttype == SMALLDATETIME || dttype == DATETIME || dttype == DATE) {
						incompatibleDatePart = true;
						break;
					}
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, 0, 0, 0, Float8GetDatum((float) num * 0.000001));
					break;
				case DTK_NANO:
					if(dttype == SMALLDATETIME || dttype == DATETIME || dttype == DATE) {
						incompatibleDatePart = true;
						break;
					}
					num = num / 1000 * 1000; // Floors the number to avoid incorrect rounding
					interval = (Interval *) DirectFunctionCall7(make_interval, 0, 0, 0, 0, 0, 0, Float8GetDatum((float) num * 0.000000001));
					break;
				default:
					validDateAdd = false;
					break;
			}
		}
		PG_CATCH();
		{
			ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("Adding a value to a \'%s\' column caused an overflow.", datetypeName(dttype))));
		}
		PG_END_TRY();
	} else {
		validDateAdd = false;
	}

	if(incompatibleDatePart) {
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("The datepart %s is not supported by date function %s for data type %s.", lowunits, "dateadd", datetypeName(dttype))));
	}

	if(!validDateAdd) {
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("\'%s\' is not a recognized %s option", lowunits, "dateadd")));
	}
	
	PG_TRY();
	{
		result = DirectFunctionCall2(timestamp_pl_interval, timestamp, PointerGetDatum(interval));

		/*
		 * This check is required because the range of valid timestamps
		 * is greater than the range of valid datetimes
		 */
		CheckDatetimeRange(result, fcinfo->context);
	}
	PG_CATCH();
	{
		ereport(ERROR,
			(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				errmsg("Adding a value to a \'%s\' column caused an overflow.", datetypeName(dttype))));
	}
	PG_END_TRY();

	PG_RETURN_TIMESTAMP(result);
}
