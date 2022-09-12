/*-------------------------------------------------------------------------
 *
 * numeric.c
 *	  An exact numeric data type for the Postgres database system
 *
 * Original coding 1998, Jan Wieck.  Heavily revised 2003, Tom Lane.
 *
 * Many of the algorithmic ideas are borrowed from David M. Smith's "FM"
 * multiple-precision math library, most recently published as Algorithm
 * 786: Multiple-Precision Complex Arithmetic and Functions, ACM
 * Transactions on Mathematical Software, Vol. 24, No. 4, December 1998,
 * pages 359-367.
 *
 * Copyright (c) 1998-2018, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  src/backend/utils/adt/numeric.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "fmgr.h"

#include <ctype.h>
#include <float.h>
#include <limits.h>
#include <math.h>

#include "access/hash.h"
#include "catalog/pg_type.h"
#include "common/int.h"
#include "funcapi.h"
#include "lib/hyperloglog.h"
#include "libpq/pqformat.h"
#include "miscadmin.h"
#include "nodes/nodeFuncs.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/int8.h"
#include "utils/numeric.h"
#include "utils/sortsupport.h"

#include "numeric.h"

/* ----------
 * Uncomment the following to enable compilation of dump_numeric()
 * and dump_var() and to get a dump of any result produced by make_result().
 * ----------
#define NUMERIC_DEBUG
 */


/* ----------
 * Local data types
 *
 * Numeric values are represented in a base-NBASE floating point format.
 * Each "digit" ranges from 0 to NBASE-1.  The type NumericDigit is signed
 * and wide enough to store a digit.  We assume that NBASE*NBASE can fit in
 * an int.  Although the purely calculational routines could handle any even
 * NBASE that's less than sqrt(INT_MAX), in practice we are only interested
 * in NBASE a power of ten, so that I/O conversions and decimal rounding
 * are easy.  Also, it's actually more efficient if NBASE is rather less than
 * sqrt(INT_MAX), so that there is "headroom" for mul_var and div_var_fast to
 * postpone processing carries.
 *
 * Values of NBASE other than 10000 are considered of historical interest only
 * and are no longer supported in any sense; no mechanism exists for the client
 * to discover the base, so every client supporting binary mode expects the
 * base-10000 format.  If you plan to change this, also note the numeric
 * abbreviation code, which assumes NBASE=10000.
 * ----------
 */

#if 0
#define NBASE		10
#define HALF_NBASE	5
#define DEC_DIGITS	1			/* decimal digits per NBASE digit */
#define MUL_GUARD_DIGITS	4	/* these are measured in NBASE digits */
#define DIV_GUARD_DIGITS	8

typedef signed char NumericDigit;
#endif

#if 0
#define NBASE		100
#define HALF_NBASE	50
#define DEC_DIGITS	2			/* decimal digits per NBASE digit */
#define MUL_GUARD_DIGITS	3	/* these are measured in NBASE digits */
#define DIV_GUARD_DIGITS	6

typedef signed char NumericDigit;
#endif

#if 1
#define NBASE		10000
#define HALF_NBASE	5000
#define DEC_DIGITS	4			/* decimal digits per NBASE digit */
#define MUL_GUARD_DIGITS	2	/* these are measured in NBASE digits */
#define DIV_GUARD_DIGITS	4

typedef int16 NumericDigit;
#endif

/*
 * The Numeric type as stored on disk.
 *
 * If the high bits of the first word of a NumericChoice (n_header, or
 * n_short.n_header, or n_long.n_sign_dscale) are NUMERIC_SHORT, then the
 * numeric follows the NumericShort format; if they are NUMERIC_POS or
 * NUMERIC_NEG, it follows the NumericLong format.  If they are NUMERIC_NAN,
 * it is a NaN.  We currently always store a NaN using just two bytes (i.e.
 * only n_header), but previous releases used only the NumericLong format,
 * so we might find 4-byte NaNs on disk if a database has been migrated using
 * pg_upgrade.  In either case, when the high bits indicate a NaN, the
 * remaining bits are never examined.  Currently, we always initialize these
 * to zero, but it might be possible to use them for some other purpose in
 * the future.
 *
 * In the NumericShort format, the remaining 14 bits of the header word
 * (n_short.n_header) are allocated as follows: 1 for sign (positive or
 * negative), 6 for dynamic scale, and 7 for weight.  In practice, most
 * commonly-encountered values can be represented this way.
 *
 * In the NumericLong format, the remaining 14 bits of the header word
 * (n_long.n_sign_dscale) represent the display scale; and the weight is
 * stored separately in n_weight.
 *
 * NOTE: by convention, values in the packed form have been stripped of
 * all leading and trailing zero digits (where a "digit" is of base NBASE).
 * In particular, if the value is zero, there will be no digits at all!
 * The weight is arbitrary in that case, but we normally set it to zero.
 */

struct NumericShort
{
	uint16		n_header;		/* Sign + display scale + weight */
	NumericDigit n_data[FLEXIBLE_ARRAY_MEMBER]; /* Digits */
};

struct NumericLong
{
	uint16		n_sign_dscale;	/* Sign + display scale */
	int16		n_weight;		/* Weight of 1st digit	*/
	NumericDigit n_data[FLEXIBLE_ARRAY_MEMBER]; /* Digits */
};

union NumericChoice
{
	uint16		n_header;		/* Header word */
	struct NumericLong n_long;	/* Long form (4-byte header) */
	struct NumericShort n_short;	/* Short form (2-byte header) */
};

struct NumericData
{
	int32		vl_len_;		/* varlena header (do not touch directly!) */
	union NumericChoice choice; /* choice of format */
};


/*
 * Interpretation of high bits.
 */

#define NUMERIC_SIGN_MASK	0xC000
#define NUMERIC_POS			0x0000
#define NUMERIC_NEG			0x4000
#define NUMERIC_SHORT		0x8000
#define NUMERIC_NAN			0xC000
#define NUMERIC_PINF		0xD000
#define NUMERIC_NINF		0xF000

#define NUMERIC_FLAGBITS(n) ((n)->choice.n_header & NUMERIC_SIGN_MASK)
#define NUMERIC_IS_NAN(n)		(NUMERIC_FLAGBITS(n) == NUMERIC_NAN)
#define NUMERIC_IS_SHORT(n)		(NUMERIC_FLAGBITS(n) == NUMERIC_SHORT)

#define NUMERIC_HDRSZ	(VARHDRSZ + sizeof(uint16) + sizeof(int16))
#define NUMERIC_HDRSZ_SHORT (VARHDRSZ + sizeof(uint16))

/*
 * If the flag bits are NUMERIC_SHORT or NUMERIC_NAN, we want the short header;
 * otherwise, we want the long one.  Instead of testing against each value, we
 * can just look at the high bit, for a slight efficiency gain.
 */
#define NUMERIC_HEADER_IS_SHORT(n)	(((n)->choice.n_header & 0x8000) != 0)
#define NUMERIC_HEADER_SIZE(n) \
	(VARHDRSZ + sizeof(uint16) + \
	 (NUMERIC_HEADER_IS_SHORT(n) ? 0 : sizeof(int16)))

/*
 * Short format definitions.
 */

#define NUMERIC_SHORT_SIGN_MASK			0x2000
#define NUMERIC_SHORT_DSCALE_MASK		0x1F80
#define NUMERIC_SHORT_DSCALE_SHIFT		7
#define NUMERIC_SHORT_DSCALE_MAX		\
	(NUMERIC_SHORT_DSCALE_MASK >> NUMERIC_SHORT_DSCALE_SHIFT)
#define NUMERIC_SHORT_WEIGHT_SIGN_MASK	0x0040
#define NUMERIC_SHORT_WEIGHT_MASK		0x003F
#define NUMERIC_SHORT_WEIGHT_MAX		NUMERIC_SHORT_WEIGHT_MASK
#define NUMERIC_SHORT_WEIGHT_MIN		(-(NUMERIC_SHORT_WEIGHT_MASK+1))

/*
 * Extract sign, display scale, weight.
 */

#define NUMERIC_DSCALE_MASK			0x3FFF

#define NUMERIC_SIGN(n) \
	(NUMERIC_IS_SHORT(n) ? \
		(((n)->choice.n_short.n_header & NUMERIC_SHORT_SIGN_MASK) ? \
		NUMERIC_NEG : NUMERIC_POS) : NUMERIC_FLAGBITS(n))
#define NUMERIC_DSCALE(n)	(NUMERIC_HEADER_IS_SHORT((n)) ? \
	((n)->choice.n_short.n_header & NUMERIC_SHORT_DSCALE_MASK) \
		>> NUMERIC_SHORT_DSCALE_SHIFT \
	: ((n)->choice.n_long.n_sign_dscale & NUMERIC_DSCALE_MASK))
#define NUMERIC_WEIGHT(n)	(NUMERIC_HEADER_IS_SHORT((n)) ? \
	(((n)->choice.n_short.n_header & NUMERIC_SHORT_WEIGHT_SIGN_MASK ? \
		~NUMERIC_SHORT_WEIGHT_MASK : 0) \
	 | ((n)->choice.n_short.n_header & NUMERIC_SHORT_WEIGHT_MASK)) \
	: ((n)->choice.n_long.n_weight))

/* ----------
 * NumericVar is the format we use for arithmetic.  The digit-array part
 * is the same as the NumericData storage format, but the header is more
 * complex.
 *
 * The value represented by a NumericVar is determined by the sign, weight,
 * ndigits, and digits[] array.
 *
 * Note: the first digit of a NumericVar's value is assumed to be multiplied
 * by NBASE ** weight.  Another way to say it is that there are weight+1
 * digits before the decimal point.  It is possible to have weight < 0.
 *
 * buf points at the physical start of the palloc'd digit buffer for the
 * NumericVar.  digits points at the first digit in actual use (the one
 * with the specified weight).  We normally leave an unused digit or two
 * (preset to zeroes) between buf and digits, so that there is room to store
 * a carry out of the top digit without reallocating space.  We just need to
 * decrement digits (and increment weight) to make room for the carry digit.
 * (There is no such extra space in a numeric value stored in the database,
 * only in a NumericVar in memory.)
 *
 * If buf is NULL then the digit buffer isn't actually palloc'd and should
 * not be freed --- see the constants below for an example.
 *
 * dscale, or display scale, is the nominal precision expressed as number
 * of digits after the decimal point (it must always be >= 0 at present).
 * dscale may be more than the number of physically stored fractional digits,
 * implying that we have suppressed storage of significant trailing zeroes.
 * It should never be less than the number of stored digits, since that would
 * imply hiding digits that are present.  NOTE that dscale is always expressed
 * in *decimal* digits, and so it may correspond to a fractional number of
 * base-NBASE digits --- divide by DEC_DIGITS to convert to NBASE digits.
 *
 * rscale, or result scale, is the target precision for a computation.
 * Like dscale it is expressed as number of *decimal* digits after the decimal
 * point, and is always >= 0 at present.
 * Note that rscale is not stored in variables --- it's figured on-the-fly
 * from the dscales of the inputs.
 *
 * While we consistently use "weight" to refer to the base-NBASE weight of
 * a numeric value, it is convenient in some scale-related calculations to
 * make use of the base-10 weight (ie, the approximate log10 of the value).
 * To avoid confusion, such a decimal-units weight is called a "dweight".
 *
 * NB: All the variable-level functions are written in a style that makes it
 * possible to give one and the same variable as argument and destination.
 * This is feasible because the digit buffer is separate from the variable.
 * ----------
 */
typedef struct NumericVar
{
	int			ndigits;		/* # of digits in digits[] - can be 0! */
	int			weight;			/* weight of first digit */
	int			sign;			/* NUMERIC_POS, NUMERIC_NEG, or NUMERIC_NAN */
	int			dscale;			/* display scale */
	NumericDigit *buf;			/* start of palloc'd space for digits[] */
	NumericDigit *digits;		/* base-NBASE digits */
} NumericVar;


/* ----------
 * Data for generate_series
 * ----------
 */
typedef struct
{
	NumericVar	current;
	NumericVar	stop;
	NumericVar	step;
} generate_series_numeric_fctx;


/* ----------
 * Sort support.
 * ----------
 */
typedef struct
{
	void	   *buf;			/* buffer for short varlenas */
	int64		input_count;	/* number of non-null values seen */
	bool		estimating;		/* true if estimating cardinality */

	hyperLogLogState abbr_card; /* cardinality estimator */
} NumericSortSupport;


/* ----------
 * Fast sum accumulator.
 *
 * NumericSumAccum is used to implement SUM(), and other standard aggregates
 * that track the sum of input values.  It uses 32-bit integers to store the
 * digits, instead of the normal 16-bit integers (with NBASE=10000).  This
 * way, we can safely accumulate up to NBASE - 1 values without propagating
 * carry, before risking overflow of any of the digits.  'num_uncarried'
 * tracks how many values have been accumulated without propagating carry.
 *
 * Positive and negative values are accumulated separately, in 'pos_digits'
 * and 'neg_digits'.  This is simpler and faster than deciding whether to add
 * or subtract from the current value, for each new value (see sub_var() for
 * the logic we avoid by doing this).  Both buffers are of same size, and
 * have the same weight and scale.  In accum_sum_final(), the positive and
 * negative sums are added together to produce the final result.
 *
 * When a new value has a larger ndigits or weight than the accumulator
 * currently does, the accumulator is enlarged to accommodate the new value.
 * We normally have one zero digit reserved for carry propagation, and that
 * is indicated by the 'have_carry_space' flag.  When accum_sum_carry() uses
 * up the reserved digit, it clears the 'have_carry_space' flag.  The next
 * call to accum_sum_add() will enlarge the buffer, to make room for the
 * extra digit, and set the flag again.
 *
 * To initialize a new accumulator, simply reset all fields to zeros.
 *
 * The accumulator does not handle NaNs.
 * ----------
 */
typedef struct NumericSumAccum
{
	int			ndigits;
	int			weight;
	int			dscale;
	int			num_uncarried;
	bool		have_carry_space;
	int32	   *pos_digits;
	int32	   *neg_digits;
} NumericSumAccum;

/*
 * Structs referenced from utils/adt/numeric.c
 *
 * Since the support for int128 is platform dependant,
 * Different states definition are maintained for SUM(BIGINT)
 * to speed up computation.
 */
#ifdef HAVE_INT128
typedef struct Int128AggState
{
	bool		calcSumX2;		/* if true, calculate sumX2 */
	int64		N;				/* count of processed numbers */
	int128		sumX;			/* sum of processed numbers */
	int128		sumX2;			/* sum of squares of processed numbers */
} Int128AggState;
typedef Int128AggState PolyNumAggState;
#else
typedef struct NumericAggState
{
	bool		calcSumX2;		/* if true, calculate sumX2 */
	MemoryContext agg_context;	/* context we're calculating in */
	int64		N;				/* count of processed numbers */
	NumericSumAccum sumX;		/* sum of processed numbers */
	NumericSumAccum sumX2;		/* sum of squares of processed numbers */
	int			maxScale;		/* maximum scale seen so far */
	int64		maxScaleCount;	/* number of values seen with maximum scale */
	/* These counts are *not* included in N!  Use NA_TOTAL_COUNT() as needed */
	int64		NaNcount;		/* count of NaN values */
	int64		pInfcount;		/* count of +Inf values */
	int64		nInfcount;		/* count of -Inf values */
} NumericAggState;
typedef NumericAggState PolyNumAggState;
#endif

/*
 * We define our own macros for packing and unpacking abbreviated-key
 * representations for numeric values in order to avoid depending on
 * USE_FLOAT8_BYVAL.  The type of abbreviation we use is based only on
 * the size of a datum, not the argument-passing convention for float8.
 */
#define NUMERIC_ABBREV_BITS (SIZEOF_DATUM * BITS_PER_BYTE)
#if SIZEOF_DATUM == 8
#define NumericAbbrevGetDatum(X) ((Datum) (X))
#define DatumGetNumericAbbrev(X) ((int64) (X))
#define NUMERIC_ABBREV_NAN		 NumericAbbrevGetDatum(PG_INT64_MIN)
#else
#define NumericAbbrevGetDatum(X) ((Datum) (X))
#define DatumGetNumericAbbrev(X) ((int32) (X))
#define NUMERIC_ABBREV_NAN		 NumericAbbrevGetDatum(PG_INT32_MIN)
#endif

/* ----------
 * Local functions
 * ----------
 */

#ifdef NUMERIC_DEBUG
static void dump_numeric(const char *str, Numeric num);
static void dump_var(const char *str, NumericVar *var);
#else
#define dump_numeric(s,n)
#define dump_var(s,v)
#endif

#define digitbuf_alloc(ndigits)  \
	((NumericDigit *) palloc((ndigits) * sizeof(NumericDigit)))
#define digitbuf_free(buf)	\
	do { \
		 if ((buf) != NULL) \
			 pfree(buf); \
	} while (0)

#define init_var(v)		MemSetAligned(v, 0, sizeof(NumericVar))

#define NUMERIC_DIGITS(num) (NUMERIC_HEADER_IS_SHORT(num) ? \
	(num)->choice.n_short.n_data : (num)->choice.n_long.n_data)
#define NUMERIC_NDIGITS(num) \
	((VARSIZE(num) - NUMERIC_HEADER_SIZE(num)) / sizeof(NumericDigit))
#define NUMERIC_CAN_BE_SHORT(scale,weight) \
	((scale) <= NUMERIC_SHORT_DSCALE_MAX && \
	(weight) <= NUMERIC_SHORT_WEIGHT_MAX && \
	(weight) >= NUMERIC_SHORT_WEIGHT_MIN)

static const NumericVar const_nan =
{0, 0, NUMERIC_NAN, 0, NULL, NULL};

static const NumericVar const_pinf =
{0, 0, NUMERIC_PINF, 0, NULL, NULL};

static const NumericVar const_ninf =
{0, 0, NUMERIC_NINF, 0, NULL, NULL};

static const NumericDigit const_zero_data[1] = {0};
static const NumericVar const_zero =
{0, 0, NUMERIC_POS, 0, NULL, (NumericDigit *) const_zero_data};

#if DEC_DIGITS == 4
static const int round_powers[4] = {0, 1000, 100, 10};
#endif

PG_FUNCTION_INFO_V1(tsql_numeric_round);
PG_FUNCTION_INFO_V1(tsql_numeric_trunc);
PG_FUNCTION_INFO_V1(bigint_poly_sum);
PG_FUNCTION_INFO_V1(int4int2_sum);

static void alloc_var(NumericVar *var, int ndigits);
static void free_var(NumericVar *var);
static const char *set_var_from_str(const char *str, const char *cp,
				 NumericVar *dest);
static Numeric make_result(const NumericVar *var);
static void strip_var(NumericVar *var);
static void set_var_from_var(const NumericVar *value, NumericVar *dest);
static bool numericvar_to_int64(const NumericVar *var, int64 *result);
static void round_var(NumericVar *var, int rscale);
static int64 numeric_sum_tsql(PolyNumAggState *state);
static void accum_sum_final(NumericSumAccum *accum, NumericVar *result);
static void accum_sum_carry(NumericSumAccum *accum);
static void add_var(const NumericVar *var1, const NumericVar *var2, NumericVar *result);
static void add_abs(const NumericVar *var1, const NumericVar *var2, NumericVar *result);
static void sub_abs(const NumericVar *var1, const NumericVar *var2, NumericVar *result);
static int cmp_abs(const NumericVar *var1, const NumericVar *var2);
static int cmp_abs_common(const NumericDigit *var1digits, int var1ndigits, int var1weight,
				 const NumericDigit *var2digits, int var2ndigits, int var2weight);
static void zero_var(NumericVar *var);

/* ----------------------------------------------------------------------
 *
 * Local functions follow
 *
 * In general, these do not support NaNs --- callers must eliminate
 * the possibility of NaN first.  (make_result() is an exception.)
 *
 * ----------------------------------------------------------------------
 */


/*
 * alloc_var() -
 *
 *	Allocate a digit buffer of ndigits digits (plus a spare digit for rounding)
 */
static void
alloc_var(NumericVar *var, int ndigits)
{
	digitbuf_free(var->buf);
	var->buf = digitbuf_alloc(ndigits + 1);
	var->buf[0] = 0;			/* spare digit for rounding */
	var->digits = var->buf + 1;
	var->ndigits = ndigits;
}


/*
 * free_var() -
 *
 *	Return the digit buffer of a variable to the free pool
 */
static void
free_var(NumericVar *var)
{
	digitbuf_free(var->buf);
	var->buf = NULL;
	var->digits = NULL;
	var->sign = NUMERIC_NAN;
}

/*
 * set_var_from_str()
 *
 *	Parse a string and put the number into a variable
 *
 * This function does not handle leading or trailing spaces, and it doesn't
 * accept "NaN" either.  It returns the end+1 position so that caller can
 * check for trailing spaces/garbage if deemed necessary.
 *
 * cp is the place to actually start parsing; str is what to use in error
 * reports.  (Typically cp would be the same except advanced over spaces.)
 */
static const char *
set_var_from_str(const char *str, const char *cp, NumericVar *dest)
{
	bool		have_dp = false;
	int			i;
	unsigned char *decdigits;
	int			sign = NUMERIC_POS;
	int			dweight = -1;
	int			ddigits;
	int			dscale = 0;
	int			weight;
	int			ndigits;
	int			offset;
	NumericDigit *digits;

	/*
	 * We first parse the string to extract decimal digits and determine the
	 * correct decimal weight.  Then convert to NBASE representation.
	 */
	switch (*cp)
	{
		case '+':
			sign = NUMERIC_POS;
			cp++;
			break;

		case '-':
			sign = NUMERIC_NEG;
			cp++;
			break;
	}

	if (*cp == '.')
	{
		have_dp = true;
		cp++;
	}

	if (!isdigit((unsigned char) *cp))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
				 errmsg("invalid input syntax for type %s: \"%s\"",
						"numeric", str)));

	decdigits = (unsigned char *) palloc(strlen(cp) + DEC_DIGITS * 2);

	/* leading padding for digit alignment later */
	memset(decdigits, 0, DEC_DIGITS);
	i = DEC_DIGITS;

	while (*cp)
	{
		if (isdigit((unsigned char) *cp))
		{
			decdigits[i++] = *cp++ - '0';
			if (!have_dp)
				dweight++;
			else
				dscale++;
		}
		else if (*cp == '.')
		{
			if (have_dp)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
						 errmsg("invalid input syntax for type %s: \"%s\"",
								"numeric", str)));
			have_dp = true;
			cp++;
		}
		else
			break;
	}

	ddigits = i - DEC_DIGITS;
	/* trailing padding for digit alignment later */
	memset(decdigits + i, 0, DEC_DIGITS - 1);

	/* Handle exponent, if any */
	if (*cp == 'e' || *cp == 'E')
	{
		long		exponent;
		char	   *endptr;

		cp++;
		exponent = strtol(cp, &endptr, 10);
		if (endptr == cp)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
					 errmsg("invalid input syntax for type %s: \"%s\"",
							"numeric", str)));
		cp = endptr;

		/*
		 * At this point, dweight and dscale can't be more than about
		 * INT_MAX/2 due to the MaxAllocSize limit on string length, so
		 * constraining the exponent similarly should be enough to prevent
		 * integer overflow in this function.  If the value is too large to
		 * fit in storage format, make_result() will complain about it later;
		 * for consistency use the same ereport errcode/text as make_result().
		 */
		if (exponent >= INT_MAX / 2 || exponent <= -(INT_MAX / 2))
			ereport(ERROR,
					(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
					 errmsg("value overflows numeric format")));
		dweight += (int) exponent;
		dscale -= (int) exponent;
		if (dscale < 0)
			dscale = 0;
	}

	/*
	 * Okay, convert pure-decimal representation to base NBASE.  First we need
	 * to determine the converted weight and ndigits.  offset is the number of
	 * decimal zeroes to insert before the first given digit to have a
	 * correctly aligned first NBASE digit.
	 */
	if (dweight >= 0)
		weight = (dweight + 1 + DEC_DIGITS - 1) / DEC_DIGITS - 1;
	else
		weight = -((-dweight - 1) / DEC_DIGITS + 1);
	offset = (weight + 1) * DEC_DIGITS - (dweight + 1);
	ndigits = (ddigits + offset + DEC_DIGITS - 1) / DEC_DIGITS;

	alloc_var(dest, ndigits);
	dest->sign = sign;
	dest->weight = weight;
	dest->dscale = dscale;

	i = DEC_DIGITS - offset;
	digits = dest->digits;

	while (ndigits-- > 0)
	{
#if DEC_DIGITS == 4
		*digits++ = ((decdigits[i] * 10 + decdigits[i + 1]) * 10 +
					 decdigits[i + 2]) * 10 + decdigits[i + 3];
#elif DEC_DIGITS == 2
		*digits++ = decdigits[i] * 10 + decdigits[i + 1];
#elif DEC_DIGITS == 1
		*digits++ = decdigits[i];
#else
#error unsupported NBASE
#endif
		i += DEC_DIGITS;
	}

	pfree(decdigits);

	/* Strip any leading/trailing zeroes, and normalize weight if zero */
	strip_var(dest);

	/* Return end+1 position for caller */
	return cp;
}

/*
 * make_result() -
 *
 *	Create the packed db numeric format in palloc()'d memory from
 *	a variable.
 */
static Numeric
make_result(const NumericVar *var)
{
	Numeric		result;
	NumericDigit *digits = var->digits;
	int			weight = var->weight;
	int			sign = var->sign;
	int			n;
	Size		len;

	if (sign == NUMERIC_NAN)
	{
		result = (Numeric) palloc(NUMERIC_HDRSZ_SHORT);

		SET_VARSIZE(result, NUMERIC_HDRSZ_SHORT);
		result->choice.n_header = NUMERIC_NAN;
		/* the header word is all we need */

		dump_numeric("make_result()", result);
		return result;
	}

	n = var->ndigits;

	/* truncate leading zeroes */
	while (n > 0 && *digits == 0)
	{
		digits++;
		weight--;
		n--;
	}
	/* truncate trailing zeroes */
	while (n > 0 && digits[n - 1] == 0)
		n--;

	/* If zero result, force to weight=0 and positive sign */
	if (n == 0)
	{
		weight = 0;
		sign = NUMERIC_POS;
	}

	/* Build the result */
	if (NUMERIC_CAN_BE_SHORT(var->dscale, weight))
	{
		len = NUMERIC_HDRSZ_SHORT + n * sizeof(NumericDigit);
		result = (Numeric) palloc(len);
		SET_VARSIZE(result, len);
		result->choice.n_short.n_header =
			(sign == NUMERIC_NEG ? (NUMERIC_SHORT | NUMERIC_SHORT_SIGN_MASK)
			 : NUMERIC_SHORT)
			| (var->dscale << NUMERIC_SHORT_DSCALE_SHIFT)
			| (weight < 0 ? NUMERIC_SHORT_WEIGHT_SIGN_MASK : 0)
			| (weight & NUMERIC_SHORT_WEIGHT_MASK);
	}
	else
	{
		len = NUMERIC_HDRSZ + n * sizeof(NumericDigit);
		result = (Numeric) palloc(len);
		SET_VARSIZE(result, len);
		result->choice.n_long.n_sign_dscale =
			sign | (var->dscale & NUMERIC_DSCALE_MASK);
		result->choice.n_long.n_weight = weight;
	}

	Assert(NUMERIC_NDIGITS(result) == n);
	if (n > 0)
		memcpy(NUMERIC_DIGITS(result), digits, n * sizeof(NumericDigit));

	/* Check for overflow of int16 fields */
	if (NUMERIC_WEIGHT(result) != weight ||
		NUMERIC_DSCALE(result) != var->dscale)
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("value overflows numeric format")));

	dump_numeric("make_result()", result);
	return result;
}

/*
 * strip_var
 *
 * Strip any leading and trailing zeroes from a numeric variable
 */
static void
strip_var(NumericVar *var)
{
	NumericDigit *digits = var->digits;
	int			ndigits = var->ndigits;

	/* Strip leading zeroes */
	while (ndigits > 0 && *digits == 0)
	{
		digits++;
		var->weight--;
		ndigits--;
	}

	/* Strip trailing zeroes */
	while (ndigits > 0 && digits[ndigits - 1] == 0)
		ndigits--;

	/* If it's zero, normalize the sign and weight */
	if (ndigits == 0)
	{
		var->sign = NUMERIC_POS;
		var->weight = 0;
	}

	var->digits = digits;
	var->ndigits = ndigits;
}

/*
 * Converts input string to numeric value in TDS receiver side
 */
Numeric
tsql_set_var_from_str_wrapper(const char *str)
{
	NumericVar value;
	Numeric res;
	init_var(&value);
	set_var_from_str(str, str, &value);
	res = make_result(&value);
	free_var(&value);
	return res;
}

/*
 * set_var_from_num() -
 * Set NumericVar from Numeric
 */
static void
set_var_from_num(Numeric num, NumericVar *dest)
{
	int			ndigits;

	ndigits = NUMERIC_NDIGITS(num);

	alloc_var(dest, ndigits);

	dest->weight = NUMERIC_WEIGHT(num);
	dest->sign = NUMERIC_SIGN(num);
	dest->dscale = NUMERIC_DSCALE(num);

	memcpy(dest->digits, NUMERIC_DIGITS(num), ndigits * sizeof(NumericDigit));
}


/*
 * tsql_round_var
 *
 * This function is similar to round_var,
 * but we check if rounding up will cause an overflow 
 */
static void
tsql_round_var(NumericVar *var, int rscale)
{
	NumericDigit *digits = var->digits;
	int			di;
	int			ndigits;
	int			carry;

	var->dscale = rscale;

	/* decimal digits wanted */
	di = (var->weight + 1) * DEC_DIGITS + rscale;

	/* checking numeric overflow for TSQL */
	if (rscale < 0)
	{
		int integral_digits = di - DEC_DIGITS;
		int	leading_digits = digits[0];
		static const int32 timescales[DEC_DIGITS] = {
			1000,
			100,
			10,
			1,
		};

		for(int i = 0; i < DEC_DIGITS; i++)
		{
			if(leading_digits >= timescales[i])
			{
				integral_digits += (4-i);
				break;
			}
		}
		/* Overflow when rounding up*/
		if (integral_digits == 0)
			ereport(ERROR,
					(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
					errmsg("value overflows for numeric format")));
		/* should lose all digits */
		else if (integral_digits < 0)
			di = -1;
	}

	/*
	 * If di < 0, the value loses all digits
	 */
	if (di < 0)
	{
		var->ndigits = 0;
		var->weight = 0;
		var->sign = NUMERIC_POS;
	}
	else
	{
		/* NBASE digits wanted */
		ndigits = (di + DEC_DIGITS - 1) / DEC_DIGITS;

		/* 0, or number of decimal digits to keep in last NBASE digit */
		di %= DEC_DIGITS;

		if (ndigits < var->ndigits ||
			(ndigits == var->ndigits && di > 0))
		{
			var->ndigits = ndigits;

#if DEC_DIGITS == 1
			/* di must be zero */
			carry = (digits[ndigits] >= HALF_NBASE) ? 1 : 0;
#else
			if (di == 0)
				carry = (digits[ndigits] >= HALF_NBASE) ? 1 : 0;
			else
			{
				/* Must round within last NBASE digit */
				int			extra,
							pow10;

#if DEC_DIGITS == 4
				pow10 = round_powers[di];
#elif DEC_DIGITS == 2
				pow10 = 10;
#else
#error unsupported NBASE
#endif
				extra = digits[--ndigits] % pow10;
				digits[ndigits] -= extra;
				carry = 0;
				if (extra >= pow10 / 2)
				{
					pow10 += digits[ndigits];
					if (pow10 >= NBASE)
					{
						pow10 -= NBASE;
						carry = 1;
					}
					digits[ndigits] = pow10;
				}
			}
#endif

			/* Propagate carry if needed */
			while (carry)
			{
				carry += digits[--ndigits];
				if (carry >= NBASE)
				{
					digits[ndigits] = carry - NBASE;
					carry = 1;
				}
				else
				{
					digits[ndigits] = carry;
					carry = 0;
				}
			}

			if (ndigits < 0)
			{
				Assert(ndigits == -1);	/* better not have added > 1 digit */
				Assert(var->digits > var->buf);
				var->digits--;
				var->ndigits++;
				var->weight++;
			}
		}
	}
}

/*
 * tsql_numeric_round() -
 *
 * compared to numeric_round(), we handle NULL input parameter in this function,
 * and calls tsql_round_var() for rounding
 */
Datum
tsql_numeric_round(PG_FUNCTION_ARGS)
{
	Numeric		num;
	int32		scale;
	Numeric		res;
	NumericVar	arg;
	/* when num or scale is NULL, return NULL */
	if(PG_ARGISNULL(0) || PG_ARGISNULL(1))
		PG_RETURN_NULL();

	num = PG_GETARG_NUMERIC(0);
	scale = PG_GETARG_INT32(1);

	/*
	 * Handle NaN
	 */
	if (NUMERIC_IS_NAN(num))
		PG_RETURN_NUMERIC(make_result(&const_nan));

	/*
	 * Limit the scale value to avoid possible overflow in calculations
	 */
	scale = Max(scale, -NUMERIC_MAX_RESULT_SCALE);
	scale = Min(scale, NUMERIC_MAX_RESULT_SCALE);

	/*
	 * Unpack the argument and round it at the proper digit position
	 */
	init_var(&arg);
	set_var_from_num(num, &arg);

	tsql_round_var(&arg, scale);

	/* We don't allow negative output dscale */
	if (scale < 0)
		arg.dscale = 0;

	/*
	 * Return the rounded result
	 */
	res = make_result(&arg);

	free_var(&arg);
	PG_RETURN_NUMERIC(res);
}

/*
 * tsql_numeric_round() -
 * 
 * Directly call numeric_trunc() or
 * call tsql_numeric_round() when 'function' is 0 or null
*/
Datum
tsql_numeric_trunc(PG_FUNCTION_ARGS)
{
	Numeric		num;
	int32		scale ;
	/* when num or scale is NULL, return NULL */
	if(PG_ARGISNULL(0) || PG_ARGISNULL(1))
		PG_RETURN_NULL();
	num = PG_GETARG_NUMERIC(0);
	scale = PG_GETARG_INT32(1);
	if(PG_ARGISNULL(2) || PG_GETARG_INT32(2) == 0)
		return DirectFunctionCall2(tsql_numeric_round,
							NumericGetDatum(num),
							Int32GetDatum(scale));
	

	return DirectFunctionCall2(numeric_trunc,
							NumericGetDatum(num),
							Int32GetDatum(scale));
}

/* 
 * Get Precision & Scale from Numeric Value
 */
int32_t
tsql_numeric_get_typmod(Numeric num)
{
	int32_t scale = NUMERIC_DSCALE(num);
	int32_t weight = NUMERIC_WEIGHT(num);
	int32_t precision;

	if (weight >= 0)
	{
		static const int32 timescales[DEC_DIGITS] = {
			1000,
			100,
			10,
			1,
		};
		int leading_digits = NUMERIC_DIGITS(num)[0];
		precision = weight * DEC_DIGITS + scale;

		for(int i = 0; i < DEC_DIGITS; i++)
		{
			if(leading_digits >= timescales[i])
			{
				precision += (4-i);
				break;
			}
		}
	}
	else
		/* weight < 0 means the integral part of the number is 0 */
		precision = 1 + scale;

	return (((precision & 0xFFFF) << 16 ) | (scale & 0xFFFF)) + VARHDRSZ;
}

/* 
 * Final function to be used by SUM(BIGINT) aggregate
 */
Datum
bigint_poly_sum(PG_FUNCTION_ARGS)
{
	
	PolyNumAggState		*state;
	
	state = PG_ARGISNULL(0) ? NULL : (PolyNumAggState *) PG_GETARG_POINTER(0);
	/* If there were no non-null inputs, return NULL */
	if (state == NULL || state->N == 0)
		PG_RETURN_NULL();

	#ifdef HAVE_INT128
	int128		arg;
	arg = state->sumX;

	if (unlikely(arg < PG_INT64_MIN) || unlikely(arg > PG_INT64_MAX))
	{
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("Arithmetic overflow error converting expression to data type bigint.")));
	}
	else
		PG_RETURN_INT64((int64) arg);
	#else

	PG_RETURN_INT64(numeric_sum_tsql(state));

	#endif
}

/*
 * In case of platform not supporting int128 type 
 * 
 * Utility Function used by bigint_poly_sum() to handle the numeric data 
 * returned by int8_avg_accum() transition function and convert it to 
 * required return type
 */
static int64
numeric_sum_tsql(PolyNumAggState *state)
{	
	NumericVar sumX_var;
	int64 result;
	bool overflow_flag;

	if (state->NaNcount > 0)	/* there was at least one NaN input */
		sumX_var = const_nan;
	/* adding plus and minus infinities gives NaN */
	if (state->pInfcount > 0 && state->nInfcount > 0)
		sumX_var = const_nan;
	if (state->pInfcount > 0)
		sumX_var = const_pinf;
	if (state->nInfcount > 0)
		sumX_var = const_ninf;

	if (!(state->NaNcount > 0) && !(state->pInfcount > 0) && !(state->nInfcount > 0))
	{
	init_var(&sumX_var);
	accum_sum_final(&state->sumX, &sumX_var);

	if (detect_numeric_overflow_hook && sumX_var.digits &&
	    (*detect_numeric_overflow_hook)(sumX_var.weight, sumX_var.dscale, sumX_var.digits[0], DEC_DIGITS))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				errmsg("Arithmetic overflow error for data type numeric.")));
	}

	overflow_flag = numericvar_to_int64( &sumX_var, &result);
	free_var(&sumX_var);

	if (!overflow_flag){
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("Arithmetic overflow error converting expression to data type bigint.")));
	
	}
	else
		return result;
}

/*
 * Function referenced from utils/adt/numeric.c
 * Return the current value of the accumulator.  This perform final carry
 * propagation, and adds together the positive and negative sums.
 *
 * Unlike all the other routines, the caller is not required to switch to
 * the memory context that holds the accumulator.
 */
static void
accum_sum_final(NumericSumAccum *accum, NumericVar *result)
{
	int			i;
	NumericVar	pos_var;
	NumericVar	neg_var;

	if (accum->ndigits == 0)
	{
		set_var_from_var(&const_zero, result);
		return;
	}

	/* Perform final carry */
	accum_sum_carry(accum);

	/* Create NumericVars representing the positive and negative sums */
	init_var(&pos_var);
	init_var(&neg_var);

	pos_var.ndigits = neg_var.ndigits = accum->ndigits;
	pos_var.weight = neg_var.weight = accum->weight;
	pos_var.dscale = neg_var.dscale = accum->dscale;
	pos_var.sign = NUMERIC_POS;
	neg_var.sign = NUMERIC_NEG;

	pos_var.buf = pos_var.digits = digitbuf_alloc(accum->ndigits);
	neg_var.buf = neg_var.digits = digitbuf_alloc(accum->ndigits);

	for (i = 0; i < accum->ndigits; i++)
	{
		Assert(accum->pos_digits[i] < NBASE);
		pos_var.digits[i] = (int16) accum->pos_digits[i];

		Assert(accum->neg_digits[i] < NBASE);
		neg_var.digits[i] = (int16) accum->neg_digits[i];
	}

	/* And add them together */
	add_var(&pos_var, &neg_var, result);

	/* Remove leading/trailing zeroes */
	strip_var(result);
}

/*
 * Function referenced from utils/adt/numeric.c
 * Propagate carries.
 */
static void
accum_sum_carry(NumericSumAccum *accum)
{
	int			i;
	int			ndigits;
	int32	   *dig;
	int32		carry;
	int32		newdig = 0;

	/*
	 * If no new values have been added since last carry propagation, nothing
	 * to do.
	 */
	if (accum->num_uncarried == 0)
		return;

	/*
	 * We maintain that the weight of the accumulator is always one larger
	 * than needed to hold the current value, before carrying, to make sure
	 * there is enough space for the possible extra digit when carry is
	 * propagated.  We cannot expand the buffer here, unless we require
	 * callers of accum_sum_final() to switch to the right memory context.
	 */
	Assert(accum->pos_digits[0] == 0 && accum->neg_digits[0] == 0);

	ndigits = accum->ndigits;

	/* Propagate carry in the positive sum */
	dig = accum->pos_digits;
	carry = 0;
	for (i = ndigits - 1; i >= 0; i--)
	{
		newdig = dig[i] + carry;
		if (newdig >= NBASE)
		{
			carry = newdig / NBASE;
			newdig -= carry * NBASE;
		}
		else
			carry = 0;
		dig[i] = newdig;
	}
	/* Did we use up the digit reserved for carry propagation? */
	if (newdig > 0)
		accum->have_carry_space = false;

	/* And the same for the negative sum */
	dig = accum->neg_digits;
	carry = 0;
	for (i = ndigits - 1; i >= 0; i--)
	{
		newdig = dig[i] + carry;
		if (newdig >= NBASE)
		{
			carry = newdig / NBASE;
			newdig -= carry * NBASE;
		}
		else
			carry = 0;
		dig[i] = newdig;
	}
	if (newdig > 0)
		accum->have_carry_space = false;

	accum->num_uncarried = 0;
}

/*
 * Function referenced from utils/adt/numeric.c
 * add_var() -
 *
 *	Full version of add functionality on variable level (handling signs).
 *	result might point to one of the operands too without danger.
 */
static void
add_var(const NumericVar *var1, const NumericVar *var2, NumericVar *result)
{
	/*
	 * Decide on the signs of the two variables what to do
	 */
	if (var1->sign == NUMERIC_POS)
	{
		if (var2->sign == NUMERIC_POS)
		{
			/*
			 * Both are positive result = +(ABS(var1) + ABS(var2))
			 */
			add_abs(var1, var2, result);
			result->sign = NUMERIC_POS;
		}
		else
		{
			/*
			 * var1 is positive, var2 is negative Must compare absolute values
			 */
			switch (cmp_abs(var1, var2))
			{
				case 0:
					/* ----------
					 * ABS(var1) == ABS(var2)
					 * result = ZERO
					 * ----------
					 */
					zero_var(result);
					result->dscale = Max(var1->dscale, var2->dscale);
					break;

				case 1:
					/* ----------
					 * ABS(var1) > ABS(var2)
					 * result = +(ABS(var1) - ABS(var2))
					 * ----------
					 */
					sub_abs(var1, var2, result);
					result->sign = NUMERIC_POS;
					break;

				case -1:
					/* ----------
					 * ABS(var1) < ABS(var2)
					 * result = -(ABS(var2) - ABS(var1))
					 * ----------
					 */
					sub_abs(var2, var1, result);
					result->sign = NUMERIC_NEG;
					break;
			}
		}
	}
	else
	{
		if (var2->sign == NUMERIC_POS)
		{
			/* ----------
			 * var1 is negative, var2 is positive
			 * Must compare absolute values
			 * ----------
			 */
			switch (cmp_abs(var1, var2))
			{
				case 0:
					/* ----------
					 * ABS(var1) == ABS(var2)
					 * result = ZERO
					 * ----------
					 */
					zero_var(result);
					result->dscale = Max(var1->dscale, var2->dscale);
					break;

				case 1:
					/* ----------
					 * ABS(var1) > ABS(var2)
					 * result = -(ABS(var1) - ABS(var2))
					 * ----------
					 */
					sub_abs(var1, var2, result);
					result->sign = NUMERIC_NEG;
					break;

				case -1:
					/* ----------
					 * ABS(var1) < ABS(var2)
					 * result = +(ABS(var2) - ABS(var1))
					 * ----------
					 */
					sub_abs(var2, var1, result);
					result->sign = NUMERIC_POS;
					break;
			}
		}
		else
		{
			/* ----------
			 * Both are negative
			 * result = -(ABS(var1) + ABS(var2))
			 * ----------
			 */
			add_abs(var1, var2, result);
			result->sign = NUMERIC_NEG;
		}
	}
}

/*
 * Function referenced from utils/adt/numeric.c
 * sub_abs()
 *
 *	Subtract the absolute value of var2 from the absolute value of var1
 *	and store in result. result might point to one of the operands
 *	without danger.
 *
 *	ABS(var1) MUST BE GREATER OR EQUAL ABS(var2) !!!
 */
static void
sub_abs(const NumericVar *var1, const NumericVar *var2, NumericVar *result)
{
	NumericDigit *res_buf;
	NumericDigit *res_digits;
	int			res_ndigits;
	int			res_weight;
	int			res_rscale,
				rscale1,
				rscale2;
	int			res_dscale;
	int			i,
				i1,
				i2;
	int			borrow = 0;

	/* copy these values into local vars for speed in inner loop */
	int			var1ndigits = var1->ndigits;
	int			var2ndigits = var2->ndigits;
	NumericDigit *var1digits = var1->digits;
	NumericDigit *var2digits = var2->digits;

	res_weight = var1->weight;

	res_dscale = Max(var1->dscale, var2->dscale);

	/* Note: here we are figuring rscale in base-NBASE digits */
	rscale1 = var1->ndigits - var1->weight - 1;
	rscale2 = var2->ndigits - var2->weight - 1;
	res_rscale = Max(rscale1, rscale2);

	res_ndigits = res_rscale + res_weight + 1;
	if (res_ndigits <= 0)
		res_ndigits = 1;

	res_buf = digitbuf_alloc(res_ndigits + 1);
	res_buf[0] = 0;				/* spare digit for later rounding */
	res_digits = res_buf + 1;

	i1 = res_rscale + var1->weight + 1;
	i2 = res_rscale + var2->weight + 1;
	for (i = res_ndigits - 1; i >= 0; i--)
	{
		i1--;
		i2--;
		if (i1 >= 0 && i1 < var1ndigits)
			borrow += var1digits[i1];
		if (i2 >= 0 && i2 < var2ndigits)
			borrow -= var2digits[i2];

		if (borrow < 0)
		{
			res_digits[i] = borrow + NBASE;
			borrow = -1;
		}
		else
		{
			res_digits[i] = borrow;
			borrow = 0;
		}
	}

	Assert(borrow == 0);		/* else caller gave us var1 < var2 */

	digitbuf_free(result->buf);
	result->ndigits = res_ndigits;
	result->buf = res_buf;
	result->digits = res_digits;
	result->weight = res_weight;
	result->dscale = res_dscale;

	/* Remove leading/trailing zeroes */
	strip_var(result);
}

/*
 * Function referenced from utils/adt/numeric.c
 * add_abs() -
 *
 *	Add the absolute values of two variables into result.
 *	result might point to one of the operands without danger.
 */
static void
add_abs(const NumericVar *var1, const NumericVar *var2, NumericVar *result)
{
	NumericDigit *res_buf;
	NumericDigit *res_digits;
	int			res_ndigits;
	int			res_weight;
	int			res_rscale,
				rscale1,
				rscale2;
	int			res_dscale;
	int			i,
				i1,
				i2;
	int			carry = 0;

	/* copy these values into local vars for speed in inner loop */
	int			var1ndigits = var1->ndigits;
	int			var2ndigits = var2->ndigits;
	NumericDigit *var1digits = var1->digits;
	NumericDigit *var2digits = var2->digits;

	res_weight = Max(var1->weight, var2->weight) + 1;

	res_dscale = Max(var1->dscale, var2->dscale);

	/* Note: here we are figuring rscale in base-NBASE digits */
	rscale1 = var1->ndigits - var1->weight - 1;
	rscale2 = var2->ndigits - var2->weight - 1;
	res_rscale = Max(rscale1, rscale2);

	res_ndigits = res_rscale + res_weight + 1;
	if (res_ndigits <= 0)
		res_ndigits = 1;

	res_buf = digitbuf_alloc(res_ndigits + 1);
	res_buf[0] = 0;				/* spare digit for later rounding */
	res_digits = res_buf + 1;

	i1 = res_rscale + var1->weight + 1;
	i2 = res_rscale + var2->weight + 1;
	for (i = res_ndigits - 1; i >= 0; i--)
	{
		i1--;
		i2--;
		if (i1 >= 0 && i1 < var1ndigits)
			carry += var1digits[i1];
		if (i2 >= 0 && i2 < var2ndigits)
			carry += var2digits[i2];

		if (carry >= NBASE)
		{
			res_digits[i] = carry - NBASE;
			carry = 1;
		}
		else
		{
			res_digits[i] = carry;
			carry = 0;
		}
	}

	Assert(carry == 0);			/* else we failed to allow for carry out */

	digitbuf_free(result->buf);
	result->ndigits = res_ndigits;
	result->buf = res_buf;
	result->digits = res_digits;
	result->weight = res_weight;
	result->dscale = res_dscale;

	/* Remove leading/trailing zeroes */
	strip_var(result);
}

/* 
 * Function referenced from utils/adt/numeric.c
 * cmp_abs() -
 *
 *	Compare the absolute values of var1 and var2
 *	Returns:	-1 for ABS(var1) < ABS(var2)
 *				0  for ABS(var1) == ABS(var2)
 *				1  for ABS(var1) > ABS(var2)
 */
static int
cmp_abs(const NumericVar *var1, const NumericVar *var2)
{
	return cmp_abs_common(var1->digits, var1->ndigits, var1->weight,
						  var2->digits, var2->ndigits, var2->weight);
}

/* 
 * Function referenced from utils/adt/numeric.c
 * cmp_abs_common() -
 *
 *	Main routine of cmp_abs(). This function can be used by both
 *	NumericVar and Numeric.
 */
static int
cmp_abs_common(const NumericDigit *var1digits, int var1ndigits, int var1weight,
			   const NumericDigit *var2digits, int var2ndigits, int var2weight)
{
	int			i1 = 0;
	int			i2 = 0;

	/* Check any digits before the first common digit */

	while (var1weight > var2weight && i1 < var1ndigits)
	{
		if (var1digits[i1++] != 0)
			return 1;
		var1weight--;
	}
	while (var2weight > var1weight && i2 < var2ndigits)
	{
		if (var2digits[i2++] != 0)
			return -1;
		var2weight--;
	}

	/* At this point, either w1 == w2 or we've run out of digits */

	if (var1weight == var2weight)
	{
		while (i1 < var1ndigits && i2 < var2ndigits)
		{
			int			stat = var1digits[i1++] - var2digits[i2++];

			if (stat)
			{
				if (stat > 0)
					return 1;
				return -1;
			}
		}
	}

	/*
	 * At this point, we've run out of digits on one side or the other; so any
	 * remaining nonzero digits imply that side is larger
	 */
	while (i1 < var1ndigits)
	{
		if (var1digits[i1++] != 0)
			return 1;
	}
	while (i2 < var2ndigits)
	{
		if (var2digits[i2++] != 0)
			return -1;
	}

	return 0;
}

/*
 * Function referenced from utils/adt/numeric.c
 * zero_var() -
 *
 *	Set a variable to ZERO.
 *	Note: its dscale is not touched.
 */
static void
zero_var(NumericVar *var)
{
	digitbuf_free(var->buf);
	var->buf = NULL;
	var->digits = NULL;
	var->ndigits = 0;
	var->weight = 0;			/* by convention; doesn't really matter */
	var->sign = NUMERIC_POS;	/* anything but NAN... */
}

/* 
 * Final function to be used by SUM(INT,SMALLINT,TINYINT) aggregate
 */
Datum
int4int2_sum(PG_FUNCTION_ARGS)
{

	int64 result;
 	if (PG_ARGISNULL(0))
	{
		PG_RETURN_NULL();
	}
	else
	{
		result  = PG_GETARG_INT64(0);

		if (unlikely(result < PG_INT32_MIN) || unlikely(result > PG_INT32_MAX))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("Arithmetic overflow error converting expression to data type int.")));

		PG_RETURN_INT32((int32) result);
	}
}

/*
 * Function referenced from utils/adt/numeric.c
 * Convert numeric to int8, rounding if needed.
 *
 * If overflow, return false (no error is raised).  Return true if okay.
 */
static bool
numericvar_to_int64(const NumericVar *var, int64 *result)
{
	NumericDigit *digits;
	int			ndigits;
	int			weight;
	int			i;
	int64		val;
	bool		neg;
	NumericVar	rounded;

	/* Round to nearest integer */
	init_var(&rounded);
	set_var_from_var(var, &rounded);
	round_var(&rounded, 0);

	/* Check for zero input */
	strip_var(&rounded);
	ndigits = rounded.ndigits;
	if (ndigits == 0)
	{
		*result = 0;
		free_var(&rounded);
		return true;
	}

	/*
	 * For input like 10000000000, we must treat stripped digits as real. So
	 * the loop assumes there are weight+1 digits before the decimal point.
	 */
	weight = rounded.weight;
	Assert(weight >= 0 && ndigits <= weight + 1);

	/*
	 * Construct the result. To avoid issues with converting a value
	 * corresponding to INT64_MIN (which can't be represented as a positive 64
	 * bit two's complement integer), accumulate value as a negative number.
	 */
	digits = rounded.digits;
	neg = (rounded.sign == NUMERIC_NEG);
	val = -digits[0];
	for (i = 1; i <= weight; i++)
	{
		if (unlikely(pg_mul_s64_overflow(val, NBASE, &val)))
		{
			free_var(&rounded);
			return false;
		}

		if (i < ndigits)
		{
			if (unlikely(pg_sub_s64_overflow(val, digits[i], &val)))
			{
				free_var(&rounded);
				return false;
			}
		}
	}

	free_var(&rounded);

	if (!neg)
	{
		if (unlikely(val == PG_INT64_MIN))
			return false;
		val = -val;
	}
	*result = val;

	return true;
}

/*
 * Function referenced from utils/adt/numeric.c
 * set_var_from_var() -
 *
 *	Copy one variable into another
 */
static void
set_var_from_var(const NumericVar *value, NumericVar *dest)
{
	NumericDigit *newbuf;

	newbuf = digitbuf_alloc(value->ndigits + 1);
	newbuf[0] = 0;				/* spare digit for rounding */
	if (value->ndigits > 0)		/* else value->digits might be null */
		memcpy(newbuf + 1, value->digits,
			   value->ndigits * sizeof(NumericDigit));

	digitbuf_free(dest->buf);

	memmove(dest, value, sizeof(NumericVar));
	dest->buf = newbuf;
	dest->digits = newbuf + 1;
}

/*
 * Function referenced from utils/adt/numeric.c
 * round_var
 *
 * Round the value of a variable to no more than rscale decimal digits
 * after the decimal point.  NOTE: we allow rscale < 0 here, implying
 * rounding before the decimal point.
 */
static void
round_var(NumericVar *var, int rscale)
{	
	NumericDigit *digits = var->digits;
	int			di;
	int			ndigits;
	int			carry;

	var->dscale = rscale;

	/* decimal digits wanted */
	di = (var->weight + 1) * DEC_DIGITS + rscale;

	/*
	 * If di = 0, the value loses all digits, but could round up to 1 if its
	 * first extra digit is >= 5.  If di < 0 the result must be 0.
	 */
	if (di < 0)
	{
		var->ndigits = 0;
		var->weight = 0;
		var->sign = NUMERIC_POS;
	}
	else
	{
		/* NBASE digits wanted */
		ndigits = (di + DEC_DIGITS - 1) / DEC_DIGITS;

		/* 0, or number of decimal digits to keep in last NBASE digit */
		di %= DEC_DIGITS;
		if (ndigits < var->ndigits ||
			(ndigits == var->ndigits && di > 0))
		{
			var->ndigits = ndigits;

#if DEC_DIGITS == 1
			/* di must be zero */
			carry = (digits[ndigits] >= HALF_NBASE) ? 1 : 0;
#else
			if (di == 0)
				carry = (digits[ndigits] >= HALF_NBASE) ? 1 : 0;
			else
			{
				/* Must round within last NBASE digit */
				int			extra,
							pow10;

#if DEC_DIGITS == 4
				pow10 = round_powers[di];
#elif DEC_DIGITS == 2
				pow10 = 10;
#else
#error unsupported NBASE
#endif
				extra = digits[--ndigits] % pow10;
				digits[ndigits] -= extra;
				carry = 0;
				if (extra >= pow10 / 2)
				{
					pow10 += digits[ndigits];
					if (pow10 >= NBASE)
					{
						pow10 -= NBASE;
						carry = 1;
					}
					digits[ndigits] = pow10;
				}
			}
#endif
			/* Propagate carry if needed */
			while (carry)
			{
				carry += digits[--ndigits];
				if (carry >= NBASE)
				{
					digits[ndigits] = carry - NBASE;
					carry = 1;
				}
				else
				{
					digits[ndigits] = carry;
					carry = 0;
				}
			}
			if (ndigits < 0)
			{
				Assert(ndigits == -1);	/* better not have added > 1 digit */
				Assert(var->digits > var->buf);
				var->digits--;
				var->ndigits++;
				var->weight++;
			}
		}
	}
}