/*-------------------------------------------------------------------------
 *
 * datetime.h
 *	  Definitions for the TSQL "datetime" type.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PLTSQL_DATETIME_H
#define PLTSQL_DATETIME_H

#include "datatype/timestamp.h"

/*	Round off to MAX_DATETIME_PRECISION decimal places. */
#define DT_PREC_INV 1000
#define DTROUND(j) ((((int) (j / DT_PREC_INV)) * DT_PREC_INV))

/* TODO: round datetime fsec to fixed bins (e.g. .000, .003, .007)
 * see: BABEL-1081
 */

/* Check precision is valid for datetime */
#define IS_VALID_DT_PRECISION(j) (j % (int) DT_PREC_INV == 0)

/* Datetime limits */
/* lower bound: 1753-01-01 00:00:00.000 */
#define MIN_DATETIME	INT64CONST(-7794489600000000)
/* upper bond: 9999-12-31 23:59:29.999 */
#define END_DATETIME	INT64CONST(252455615999999000)

extern Timestamp initializeToDefaultDatetime(void);
/** Utility function to calculate days from '1900-01-01 00:00:00' */
extern double calculateDaysFromDefaultDatetime(Timestamp timestamp_left); 
extern int roundFractionalSeconds(int fractseconds); 

extern int days_in_date(int day, int month, int year);
extern char* datetypeName(int num);

extern bool int64_multiply_add(int64 val, int64 multiplier, int64 *sum);
extern bool int32_multiply_add(int32 val, int32 multiplier, int32 *sum);

/* Range-check a datetime */
#define IS_VALID_DATETIME(t)  (MIN_DATETIME <= (t) && (t) < END_DATETIME)

extern Datum datetime_in_str(char *str, Node *escontext);

typedef enum
{
    DATE_TIME, DATE_TIME_2, DATE_TIME_OFFSET
} DateTimeContext;

static const char *date_regexes[] = {
    "[a-zA-Z]{3,5}\\s*[0-9]{1,2}[,]?\\s*([0-9]{4})", // mon [dd][,] yyyy
    "[a-zA-Z]{3,5}\\s*[0-9]{1,2}[,]?\\s*([0-9]{4}|[0-9]{2}|[0-9]{1})?", // mon dd[,] [yy]
    "[a-zA-Z]{3,5}\\s*[0-9]{4}\\s*[0-9]{1,2}?", // mon yyyy [dd]
    "[0-9]{1,2}?\\s*[a-zA-Z]{3,5}[,]?\\s*[0-9]{4}", // [dd] mon[,] yyyy
    "[0-9]{1,2}\\s*[a-zA-Z]{3,5}[,]?\\s*[0-9]{2}?[0-9]{2}", // dd mon[,][yy]yy
    "[0-9]{1,2}\\s*[0-9]{2}?[0-9]{2}\\s*[a-zA-Z]{3,5}", // dd [yy]yy mon
    "[0-9]{1,2}?\\s*[0-9]{4}\\s*[a-zA-Z]{3,5}", // [dd] yyyy mon
    "[0-9]{4}\\s*[a-zA-Z]{3,5}\\s*[0-9]{1,2}?", // yyyy mon [dd]
    "[0-9]{4}\\s*[0-9]{1,2}?\\s*[a-zA-Z]{3,5}", // yyyy [dd] mon
    "[0-9]{2}\\s*[a-zA-Z]{3,5}", // yy mon
    "[0-9]{4}\\s*[-]\\s*[a-zA-Z]{3,5}\\s*[-]\\s*[0-9]{1,2}", // yyyy-mon-dd
    "[0-9]{4}\\s*[/]\\s*[a-zA-Z]{3,5}\\s*[/]\\s*[0-9]{1,2}", // yyyy/mon/dd
    "[0-9]{4}\\s*[.]\\s*[a-zA-Z]{3,5}\\s*[.]\\s*[0-9]{1,2}", // yyyy.mon.dd
    "[0-9]{1,2}\\s*[-]\\s*[a-zA-Z]{3,5}\\s*[-]\\s*[0-9]{4}", // dd-mon-[yy]yy
    "[0-9]{1,2}\\s*[/]\\s*[a-zA-Z]{3,5}\\s*[/]\\s*[0-9]{4}", // dd/mon/[yy]yy
    "[0-9]{1,2}\\s*[.]\\s*[a-zA-Z]{3,5}\\s*[.]\\s*[0-9]{4}" // dd.mon.[yy]yy
};

static const int num_date_regexes = sizeof(date_regexes) / sizeof(date_regexes[0]);

static const char *time_regexes[] = {
    "[0-9]{1,2}:[0-9]{1,2}\\s*([AP]M)?", // hh:mm
    "[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\\s*([AP]M)?", // hh:mm:ss
    "[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}[.][0-9]{1,9}\\s*([AP]M)?", // hh:mm:ss.fffff
    "[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,9}\\s*([AP]M)?", // hh:mm:ss:fffff
    "[0-9]{1,2}\\s*([AP]M)" // hh AM/PM
};

static const int num_time_regexes = sizeof(time_regexes) / sizeof(time_regexes[0]);

extern bool check_regex_for_text_month(char *str, DateTimeContext context);
extern char* clean_input_str(char *str, bool *contains_extra_spaces, DateTimeContext context);

#endif							/* PLTSQL_DATETIME_H */
