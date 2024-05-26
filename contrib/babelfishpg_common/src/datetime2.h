/*-------------------------------------------------------------------------
*
* datetime2.h
*	  Definitions for the TSQL "datetime2" type.
*
*-------------------------------------------------------------------------
*/
#ifndef PLTSQL_DATETIME2_H
#define PLTSQL_DATETIME2_H

/* Maximum precision for datetime2 */
#define MAX_DATETIME2_PRECISION 7

/* Datetime2 limits */
/* lower bound: 0001-01-01 00:00:00.000 */
#define MIN_DATETIME2	INT64CONST(-63082281600000000)
/* upper bound: 10000-00-00 00:00:00 */
#define END_DATETIME2	INT64CONST(252455616000000000)

/* Range-check a datetime */
#define IS_VALID_DATETIME2(t)  (MIN_DATETIME2 <= (t) && (t) < END_DATETIME2)

extern int tsql_decode_datetime2_fields(char *orig_str, char *str, char **field, int nf, int ftype[], 
				bool contains_extra_spaces, struct pg_tm *tm,
				bool *is_year_set, bool dump_restore, int context);

#endif							/* PLTSQL_DATETIME2_H */
