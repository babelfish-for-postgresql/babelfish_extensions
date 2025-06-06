/*
 * The scale which the number is actually stored.
 * For example: 100 will allow 2 decimal places of precision
 * This must always be a '1' followed by a number of '0's.
 */
#define FIXEDDECIMAL_MULTIPLIER 10000LL
/*
 * Number of decimal places to store.
 * This number should be the number of decimal digits that it takes to
 * represent FIXEDDECIMAL_MULTIPLIER - 1
 */
#define FIXEDDECIMAL_SCALE 4
/*
 * This ensures that we round up the result in case the 5th decimal place >= 5
 * in case of fixeddecimal multiplication.
 */
#define FIXEDDECIMAL_ROUNDUP 5000
/*
 * This is bounded by the maximum and minimum values of int64.
 * 9223372036854775807 is 19 decimal digits long.
 */
#define FIXEDDECIMAL_MAX_PRECISION 19

#define FIXEDDECIMAL_MAX (INT64_MAX/FIXEDDECIMAL_MULTIPLIER)
#define FIXEDDECIMAL_MIN (INT64_MIN/FIXEDDECIMAL_MULTIPLIER)

#define SMALLMONEY_MAX (INT32_MAX/FIXEDDECIMAL_MULTIPLIER)
#define SMALLMONEY_MIN (INT32_MIN/FIXEDDECIMAL_MULTIPLIER)

/* Define this if your compiler has _builtin_add_overflow() */
/* #define HAVE_BUILTIN_OVERFLOW */

#ifndef HAVE_BUILTIN_OVERFLOW
#define SAMESIGN(a,b)	(((a) < 0) == ((b) < 0))
#endif							/* HAVE_BUILTIN_OVERFLOW */

/* Compiler must have a working 128 int type */
typedef __int128 int128;