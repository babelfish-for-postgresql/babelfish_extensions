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

/* Range-check a datetime */
#define IS_VALID_DATETIME(t)  (MIN_DATETIME <= (t) && (t) < END_DATETIME)

extern Datum datetime_in_str(char *str);

#endif							/* PLTSQL_DATETIME_H */
