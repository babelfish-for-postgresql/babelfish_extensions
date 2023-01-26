/*-------------------------------------------------------------------------
 *
 * tsql_for.c
 *   shared functions between forjson and forxml
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "tsql_for.h"

/*
 * This function handles the format for datetime datatypes by converting the output
 * into required format for SELECT FOR JSON/XML. For example:
 * "2022-11-11 20:56:22.41" -> "2022-11-11T20:56:22.41" for datetime, datetime2 & smalldatetime
 */
void
tsql_for_datetime_format(StringInfo format_output, const char *outputstr)
{
	char *date;
	char *spaceptr = strstr(outputstr, " ");
	int len;

	len = spaceptr - outputstr;
	date = palloc(len + 1);
	strncpy(date, outputstr, len);
	date[len] = '\0';
	appendStringInfoString(format_output, date);
	appendStringInfoChar(format_output, 'T');
	appendStringInfoString(format_output, ++spaceptr);
}

/*
 * This function handles the format for datetimeoffset datatype by converting the output
 * into required format for SELECT FOR JSON/XML. For example:
 * "2022-11-11 22:25:01.015 +00:00" -> "2022-11-11T22:25:01.015Z"
 * "2022-11-11 12:34:56 +02:30" -> "2022-11-11T12:34:56+02:30"
 */
void
tsql_for_datetimeoffset_format(StringInfo format_output, const char *str)
{
	char *date, *endptr, *time, *offset;
	char *spaceptr = strstr(str, " ");
	int len;

	/* append date part of string */
	len = spaceptr - str;
	date = palloc(len + 1);
	strncpy(date, str, len);
	date[len] = '\0';
	appendStringInfoString(format_output, date);
	appendStringInfoChar(format_output, 'T');

	/* append time part of string */
	endptr = ++spaceptr;
	spaceptr = strstr(endptr, " ");
	len = spaceptr - endptr;
	time = palloc(len + 1);
	strncpy(time, endptr, len);
	time[len] = '\0';
	appendStringInfoString(format_output, time);
	
	/* append either timezone offset or Z if offset is 0 */
	offset = ++spaceptr;
	if (strcmp(offset, "+00:00") == 0)
	{
		appendStringInfoChar(format_output, 'Z');
	}
	else
	{
		appendStringInfoString(format_output, offset);
	}
}
