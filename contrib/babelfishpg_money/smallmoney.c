/*-------------------------------------------------------------------------
 *
 * smallmoney.c
 *		  Fixed Decimal numeric type extension
 *-------------------------------------------------------------------------
 */
#include "postgres.h"
#include "varatt.h"

#include <ctype.h>
#include <limits.h>
#include <math.h>

#include "funcapi.h"
#include "libpq/pqformat.h"
#include "access/hash.h"
#include "common/int.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/numeric.h"
#include "fixeddecimal.h"

PG_FUNCTION_INFO_V1(smallmoneyint8pl);
PG_FUNCTION_INFO_V1(smallmoneyint8mi);
PG_FUNCTION_INFO_V1(smallmoneyint8mul);
PG_FUNCTION_INFO_V1(smallmoneyint8div);
PG_FUNCTION_INFO_V1(smallmoneyint4pl);
PG_FUNCTION_INFO_V1(smallmoneyint4mi);
PG_FUNCTION_INFO_V1(smallmoneyint4mul);
PG_FUNCTION_INFO_V1(smallmoneyint4div);
PG_FUNCTION_INFO_V1(smallmoneyint2pl);
PG_FUNCTION_INFO_V1(smallmoneyint2mi);
PG_FUNCTION_INFO_V1(smallmoneyint2mul);
PG_FUNCTION_INFO_V1(smallmoneyint2div);

PG_FUNCTION_INFO_V1(smallmoneypl);
PG_FUNCTION_INFO_V1(smallmoneymi);
PG_FUNCTION_INFO_V1(smallmoneymul);
PG_FUNCTION_INFO_V1(smallmoneydiv);

PG_FUNCTION_INFO_V1(int8smallmoneypl);
PG_FUNCTION_INFO_V1(int8smallmoneymi);
PG_FUNCTION_INFO_V1(int8smallmoneymul);
PG_FUNCTION_INFO_V1(int8smallmoneydiv);
PG_FUNCTION_INFO_V1(int4smallmoneypl);
PG_FUNCTION_INFO_V1(int4smallmoneymi);
PG_FUNCTION_INFO_V1(int4smallmoneymul);
PG_FUNCTION_INFO_V1(int4smallmoneydiv);
PG_FUNCTION_INFO_V1(int2smallmoneypl);
PG_FUNCTION_INFO_V1(int2smallmoneymi);
PG_FUNCTION_INFO_V1(int2smallmoneymul);


/*----------------------------------------------------------
 *	Arithmetic operators on smallmoney.
 *---------------------------------------------------------*/

Datum
smallmoneypl(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    result = (int64) arg1 + arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneymi(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_sub_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    result = (int64) arg1 - arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneymul(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_mul_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * We need to promote this to 64bit as we may overflow int32 here.
     * Remember that arg2 is the number multiplied by FIXEDDECIMAL_MULTIPLIER,
     * we must divide the result by this to get the correct result.
     */
    result = (int64) arg1 * arg2 / FIXEDDECIMAL_MULTIPLIER;

    /* Round off the result to FIXEDDECIMAL_SCALE. */
    if (((int64) arg1 * arg2) % FIXEDDECIMAL_MULTIPLIER >= FIXEDDECIMAL_ROUNDUP)
    {
        result++;
    }

    /*
     * Overflow check.  If the 64 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneydiv(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

    if (arg2 == 0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DIVISION_BY_ZERO),
                 errmsg("division by zero")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    /*
     * this can't overflow, but we can end up with a number that's too big for
     * int32
     */
    result = (int64) arg1 * FIXEDDECIMAL_MULTIPLIER / arg2;

    /*
     * Overflow check.  If the 64 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));

    PG_RETURN_INT32(result);
}

Datum
smallmoneyint8pl(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int128		adder = (int128) PG_GETARG_INT64(1) * FIXEDDECIMAL_MULTIPLIER;
    int128		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, adder, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the adder cannot be fit into 
     * 64 bit, then the result will definitely overflow
     */
    if (adder != (int64) adder) 
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = arg1 + adder;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint8mi(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int128		subtractor = (int128) PG_GETARG_INT64(1) * FIXEDDECIMAL_MULTIPLIER;
    int128		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, adder, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the subtractor cannot be fit into 
     * 64 bit, then the result will definitely overflow
     */
    if (subtractor != (int64) subtractor)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }
        

    result = arg1 - subtractor;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint8mul(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int64		arg2 = PG_GETARG_INT64(1);
    int128		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_mul_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int128) arg1 * arg2;

    /*
     * Overflow check.  If the 128 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint8div(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int64		arg2 = PG_GETARG_INT64(1);
    int32		result;

    if (arg2 == 0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DIVISION_BY_ZERO),
                 errmsg("division by zero")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    /*
     * INT64_MIN / -1 is problematic, since the result can't be represented on
     * a two's-complement machine.  Some machines produce INT64_MIN, some
     * produce zero, some throw an exception.  We can dodge the problem by
     * recognizing that division by -1 is the same as negation.
     */
    if (arg2 == -1)
    {
#ifdef HAVE_BUILTIN_OVERFLOW
        int64		zero = 0;

        if (__builtin_sub_overflow(zero, arg1, &result))
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                     errmsg("smallmoney out of range")));
#else
        result = -arg1;
        /* overflow check (needed for INT64_MIN) */
        if (arg1 != 0 && SAMESIGN(result, arg1))
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                    errmsg("smallmoney out of range")));
#endif							/* HAVE_BUILTIN_OVERFLOW */

        PG_RETURN_INT32(result);
    }

    /*
     division with values > SMALLMONEY_MAX lead to overflow
     in T-SQL
    */
    if (arg2 > SMALLMONEY_MAX)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = arg1 / arg2;

    PG_RETURN_INT32(result);
}

Datum
smallmoneyint4pl(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int64		adder = (int64) PG_GETARG_INT32(1) * FIXEDDECIMAL_MULTIPLIER;
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, adder, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the adder cannot be fit into 
     * 32 bit, then the result will definitely overflow
     */
    if (adder != (int32) adder)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = arg1 + adder;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint4mi(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int64		subtractor = (int64) PG_GETARG_INT32(1) * FIXEDDECIMAL_MULTIPLIER;
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_sub_overflow(arg1, subtractor, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the subtractor cannot be fit into 
     * 32 bit, then the result will definitely overflow
     */
    if (subtractor != (int32) subtractor)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = arg1 - subtractor;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint4mul(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_mul_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int64) arg1 * arg2;

    /*
     * Overflow check.  If the 64 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint4div(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int32		result;

    if (arg2 == 0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DIVISION_BY_ZERO),
                errmsg("division by zero")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    /*
     * INT64_MIN / -1 is problematic, since the result can't be represented on
     * a two's-complement machine.  Some machines produce INT64_MIN, some
     * produce zero, some throw an exception.  We can dodge the problem by
     * recognizing that division by -1 is the same as negation.
     */
    if (arg2 == -1)
    {
#ifdef HAVE_BUILTIN_OVERFLOW
        int64		zero = 0;

        if (__builtin_sub_overflow(zero, arg1, &result))
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                     errmsg("smallmoney out of range")));
#else
        result = -arg1;
        /* overflow check (needed for INT64_MIN) */
        if (arg1 != 0 && SAMESIGN(result, arg1))
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                    errmsg("smallmoney out of range")));
#endif							/* HAVE_BUILTIN_OVERFLOW */

        PG_RETURN_INT32(result);
    }

    /*
     division with values > SMALLMONEY_MAX lead to overflow
     in T-SQL
    */
    if (arg2 > SMALLMONEY_MAX)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = arg1 / arg2;

    PG_RETURN_INT32(result);
}

Datum
smallmoneyint2pl(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		adder = (int32) PG_GETARG_INT16(1) * FIXEDDECIMAL_MULTIPLIER;
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, adder, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    result = (int64) arg1 + adder;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint2mi(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		subtractor = (int32) PG_GETARG_INT16(1) * FIXEDDECIMAL_MULTIPLIER;
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_sub_overflow(arg1, subtractor, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int64) arg1 - subtractor;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint2mul(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int16		arg2 = PG_GETARG_INT16(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_mul_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int64) arg1 * arg2;

    /*
     * Overflow check.  If the 64 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
smallmoneyint2div(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int16		arg2 = PG_GETARG_INT16(1);
    int32		result;

    if (arg2 == 0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DIVISION_BY_ZERO),
                errmsg("division by zero")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    /*
     * INT64_MIN / -1 is problematic, since the result can't be represented on
     * a two's-complement machine.  Some machines produce INT64_MIN, some
     * produce zero, some throw an exception.  We can dodge the problem by
     * recognizing that division by -1 is the same as negation.
     */
    if (arg2 == -1)
    {
#ifdef HAVE_BUILTIN_OVERFLOW
        int64		zero = 0;

        if (__builtin_sub_overflow(zero, arg1, &result))
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                     errmsg("smallmoney out of range")));
#else
        result = -arg1;
        /* overflow check (needed for INT64_MIN) */
        if (arg1 != 0 && SAMESIGN(result, arg1))
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                    errmsg("smallmoney out of range")));
#endif							/* HAVE_BUILTIN_OVERFLOW */

        PG_RETURN_INT32(result);
    }

    /* No overflow is possible */
    result = arg1 / arg2;

    PG_RETURN_INT32(result);
}

Datum
int2smallmoneypl(PG_FUNCTION_ARGS)
{
    int32		adder = (int32) PG_GETARG_INT16(0) * FIXEDDECIMAL_MULTIPLIER;
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, adder, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int64) adder + arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int2smallmoneymi(PG_FUNCTION_ARGS)
{
    int32		subtractor = (int32) PG_GETARG_INT16(0) * FIXEDDECIMAL_MULTIPLIER;
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_sub_overflow(arg2, subtractor, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int64) subtractor - arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int2smallmoneymul(PG_FUNCTION_ARGS)
{
    int16		arg1 = PG_GETARG_INT16(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_mul_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int64) arg1 * arg2;

    /*
     * Overflow check.  If the 64 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int4smallmoneypl(PG_FUNCTION_ARGS)
{
    int64		adder = (int64) PG_GETARG_INT32(0) * FIXEDDECIMAL_MULTIPLIER;
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, adder, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the adder cannot be fit into 
     * 32 bit, then the result will definitely overflow
     */
    if (adder != (int32) adder)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = adder + arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int4smallmoneymi(PG_FUNCTION_ARGS)
{
    int64		subtractor = (int64) PG_GETARG_INT32(0) * FIXEDDECIMAL_MULTIPLIER;
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_sub_overflow(arg2, subtractor, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the subtractor cannot be fit into 
     * 32 bit, then the result will definitely overflow
     */
    if (subtractor != (int32) subtractor)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = subtractor - arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int4smallmoneymul(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int64		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_mul_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int64) arg1 * arg2;

    /*
     * Overflow check.  If the 64 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int4smallmoneydiv(PG_FUNCTION_ARGS)
{
    int32		arg1 = PG_GETARG_INT32(0);
    float8		arg2 = (float8) PG_GETARG_INT32(1) / FIXEDDECIMAL_MULTIPLIER;
    float8      t;    
    int64       result;

    if (arg2 == 0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DIVISION_BY_ZERO),
                 errmsg("division by zero")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    /*
     division with values > SMALLMONEY_MAX lead to overflow
     in T-SQL
    */
    if (arg1 > SMALLMONEY_MAX)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    t = (float8) arg1 / arg2;
    t *= FIXEDDECIMAL_MULTIPLIER;
    t = rint(t);

    result = (int64) t;

    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));

    PG_RETURN_INT32(result);
}


Datum
int8smallmoneypl(PG_FUNCTION_ARGS)
{
    int128		adder = (int128) PG_GETARG_INT64(0) * FIXEDDECIMAL_MULTIPLIER;
    int32		arg2 = PG_GETARG_INT32(1);
    int128		result;

#ifdef HAVE_BUILTIN_OVERFLOW /* HAVE_BUILTIN_OVERFLOW */
    if (__builtin_add_overflow(arg1, adder, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the adder cannot be fit into 
     * 64 bit, then the result will definitely overflow
     */
    if (adder != (int64) adder)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = adder + arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int8smallmoneymi(PG_FUNCTION_ARGS)
{
    int128		subtractor = (int128) PG_GETARG_INT64(0) * FIXEDDECIMAL_MULTIPLIER;
    int32		arg2 = PG_GETARG_INT32(1);
    int128		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_sub_overflow(arg2, subtractor, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else

    /*
     * Overflow check. If the subtractor cannot be fit into 
     * 64 bit, then the result will definitely overflow
     */
    if (subtractor != (int64) subtractor)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    result = subtractor - arg2;

    /*
     * Overflow check. If the result cannot be converted back
     * to a 32 bit result, then we can say that there is a 
     * overflow
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int8smallmoneymul(PG_FUNCTION_ARGS)
{
    int64		arg1 = PG_GETARG_INT64(0);
    int32		arg2 = PG_GETARG_INT32(1);
    int128		result;

#ifdef HAVE_BUILTIN_OVERFLOW
    if (__builtin_mul_overflow(arg1, arg2, &result))
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#else
    result = (int128) arg1 * arg2;

    /*
     * Overflow check.  If the 64 bit int result of the multiplication
     * cannot be converted back to a 32 bit int, then we know that the 
     * value overflows
     */
    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
#endif							
    PG_RETURN_INT32(result);
}

Datum
int8smallmoneydiv(PG_FUNCTION_ARGS)
{
    int64		arg1 = PG_GETARG_INT64(0);
    float8		arg2 = (float8) PG_GETARG_INT32(1) / FIXEDDECIMAL_MULTIPLIER;
    float8      t;    
    int64       result;

    if (arg2 == 0)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DIVISION_BY_ZERO),
                 errmsg("division by zero")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    /*
     division with values > SMALLMONEY_MAX lead to overflow
     in T-SQL
    */
    if (arg1 > SMALLMONEY_MAX)
    {
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));
        /* ensure compiler realizes we mustn't reach the division (gcc bug) */
        PG_RETURN_NULL();
    }

    t = (float8) arg1 / arg2;
    t *= FIXEDDECIMAL_MULTIPLIER;
    t = rint(t);

    result = (int64) t;

    if (result != (int32) result)
        ereport(ERROR,
                (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                 errmsg("smallmoney out of range")));

    PG_RETURN_INT32(result);
}