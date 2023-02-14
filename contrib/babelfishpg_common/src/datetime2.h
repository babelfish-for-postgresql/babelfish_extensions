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
/* Maximum precision for round off datetime2 */
#define MAX_TIMESTAMP_PRECISION_TSQL 7

/* Datetime2 limits */
/* lower bound: 0001-01-01 00:00:00.000 */
#define MIN_DATETIME2	INT64CONST(-63082281600000000)
/* upper bound: 10000-00-00 00:00:00 */
#define END_DATETIME2	INT64CONST(252455616000000000)

/* Range-check a datetime */
#define IS_VALID_DATETIME2(t)  (MIN_DATETIME2 <= (t) && (t) < END_DATETIME2)

#endif							/* PLTSQL_DATETIME2_H */