#ifndef TYPECODE_H
#define TYPECODE_H

/* Persistent Type Code for SQL Variant Type */
/* WARNING: EXISTING VALUES MUST NOT BE CHANGED */

#define SQLVARIANT_T        0
#define DATETIMEOFFSET_T    1
#define DATETIME2_T         2
#define DATETIME_T          3
#define SMALLDATETIME_T     4
#define DATE_T              5
#define TIME_T              6
#define FLOAT_T             7
#define REAL_T              8
#define NUMERIC_T           9
#define MONEY_T            10
#define SMALLMONEY_T       11
#define BIGINT_T           12
#define INT_T              13
#define SMALLINT_T         14
#define TINYINT_T          15
#define BIT_T              16
#define NVARCHAR_T         17
#define NCHAR_T            18
#define VARCHAR_T          19
#define CHAR_T             20
#define VARBINARY_T        21
#define BINARY_T           22
#define UNIQUEIDENTIFIER_T 23

#define TIMESTAMP_L        8
#define DATE_L             4
#define DATETIMEOFFSET_L   DATETIMEOFFSET_LEN
#define TIME_L             8
#define FLOAT_L            8
#define REAL_L             4
#define FIXEDDECIMAL_L     8
#define BIGINT_L           8
#define INT_L              4
#define SMALLINT_L         2
#define BIT_L              1
#define UNIQUEIDENTIFIER_L 16

#define IS_STRING_TYPE(t)                       \
    ( ((t) == NVARCHAR_T) || ((t) == NCHAR_T)   \
      || ((t) == VARCHAR_T) || ((t) == CHAR_T))

#define IS_MONEY_TYPE(t) (((t) == MONEY_T) || ((t) == SMALLMONEY_T))
#define IS_BINARY_TYPE(t) (((t) == VARBINARY_T) || ((t) == BINARY_T))

/* MACRO from fixed decimal */
#ifndef FIXEDDECIMAL_MULTIPLIER
#define FIXEDDECIMAL_MULTIPLIER 10000LL
#endif

#endif
