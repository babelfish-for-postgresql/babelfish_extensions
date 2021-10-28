/*-------------------------------------------------------------------------
 *
 * bit.c
 *	  Functions for the type "bit".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <ctype.h>

#include "libpq/pqformat.h"
#include "utils/builtins.h"
#include "utils/numeric.h"

#include "instr.h"
#include "typecode.h"
#include "numeric.h"


PG_FUNCTION_INFO_V1(bitin);
PG_FUNCTION_INFO_V1(bitout);
PG_FUNCTION_INFO_V1(bitrecv);
PG_FUNCTION_INFO_V1(bitsend);
PG_FUNCTION_INFO_V1(int2bit);
PG_FUNCTION_INFO_V1(int4bit);
PG_FUNCTION_INFO_V1(int8bit);
PG_FUNCTION_INFO_V1(numeric_bit);
PG_FUNCTION_INFO_V1(ftobit);
PG_FUNCTION_INFO_V1(dtobit);
PG_FUNCTION_INFO_V1(bitneg);
PG_FUNCTION_INFO_V1(biteq);
PG_FUNCTION_INFO_V1(bitne);
PG_FUNCTION_INFO_V1(bitlt);
PG_FUNCTION_INFO_V1(bitle);
PG_FUNCTION_INFO_V1(bitgt);
PG_FUNCTION_INFO_V1(bitge);
PG_FUNCTION_INFO_V1(bit_cmp);
PG_FUNCTION_INFO_V1(bit2int2);
PG_FUNCTION_INFO_V1(bit2int4);
PG_FUNCTION_INFO_V1(bit2int8);
PG_FUNCTION_INFO_V1(bit2numeric);
PG_FUNCTION_INFO_V1(bit2fixeddec);

/* Comparison between int and bit */
PG_FUNCTION_INFO_V1(int4biteq);
PG_FUNCTION_INFO_V1(int4bitne);
PG_FUNCTION_INFO_V1(int4bitlt);
PG_FUNCTION_INFO_V1(int4bitle);
PG_FUNCTION_INFO_V1(int4bitgt);
PG_FUNCTION_INFO_V1(int4bitge);

/* Comparison between bit and int */
PG_FUNCTION_INFO_V1(bitint4eq);
PG_FUNCTION_INFO_V1(bitint4ne);
PG_FUNCTION_INFO_V1(bitint4lt);
PG_FUNCTION_INFO_V1(bitint4le);
PG_FUNCTION_INFO_V1(bitint4gt);
PG_FUNCTION_INFO_V1(bitint4ge);

/*
 * Try to interpret value as boolean value.  Valid values are: true,
 * false, TRUE, FALSE, digital string as well as unique prefixes thereof.
 * If the string parses okay, return true, else false.
 * If okay and result is not NULL, return the value in *result.
 */

static bool
parse_bit_with_len(const char *value, size_t len, bool *result)
{
	switch (*value)
	{
		case 't':
		case 'T':
			if (len == 4 && pg_strncasecmp(value, "true", len) == 0)
			{
				if (result)
					*result = true;
				return true;
			}
			break;
		case 'f':
		case 'F':
			if (len == 5 && pg_strncasecmp(value, "false", len) == 0)
			{
				if (result)
					*result = false;
				return true;
			}
			break;
		default:
		{
			int i = 0;

			/* Skip the minus sign */
			if (*value == '-')
				i = 1;
			/* Is it all 0's? */
			for (; i < len; i++)
			{
				if (value[i] != '0')
					break;
			}
			/* all 0's */
			if (i == len)
			{
				if (result)
					*result = false;
				return true;
			}

			/* So it's not all 0's, is it all digits? */
			/* Skip the minus sign */
			if (*value == '-')
				i = 1;
			else
				i = 0;
			for (; i < len; i++)
			{
				if (!isdigit(value[i]))
					break;
			}
			/* all digits and not all 0's, result should be true */
			if (i == len)
			{
				if (result)
					*result = true;
				return true;
			}
			/* not all digits, meaning invalid input */
			break;
		}
	}

	if (result)
		*result = false;		/* suppress compiler warning */
	return false;
}

/*****************************************************************************
 *	 USER I/O ROUTINES														 *
 *****************************************************************************/

/*
 *		bitin			- converts "t" or "f" to 1 or 0
 *
 * Check explicitly for "true/false" and TRUE/FALSE, 1/0 and any digital string
 * Reject other values.
 *
 * In the switch statement, check the most-used possibilities first.
 */
Datum
bitin(PG_FUNCTION_ARGS)
{
	const char *in_str = PG_GETARG_CSTRING(0);
	const char *str;
	size_t		len;
	bool		result;

	/*
	 * Skip leading and trailing whitespace
	 */
	str = in_str;
	while (isspace((unsigned char) *str))
		str++;

	len = strlen(str);
	while (len > 0 && isspace((unsigned char) str[len - 1]))
		len--;

	if (parse_bit_with_len(str, len, &result))
		PG_RETURN_BOOL(result);

	ereport(ERROR,
			(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
			 errmsg("invalid input syntax for type %s: \"%s\"",
					"bit", in_str)));

	/* not reached */
	PG_RETURN_BOOL(false);
}

/*
 *		bitout			- converts 1 or 0 to "t" or "f"
 */
Datum
bitout(PG_FUNCTION_ARGS)
{
	bool		b = PG_GETARG_BOOL(0);
	char	   *result = (char *) palloc(2);

	result[0] = (b) ? '1' : '0';
	result[1] = '\0';
	PG_RETURN_CSTRING(result);
}

/*
 *		bitrecv			- converts external binary format to bit
 *
 * The external representation is one byte.  Any nonzero value is taken
 * as "true".
 */
Datum
bitrecv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);
	int			ext;

	INSTR_METRIC_INC(INSTR_TSQL_BIT_RECV);

	ext = pq_getmsgbyte(buf);
	PG_RETURN_BOOL((ext != 0) ? true : false);
}

/*
 *		bitsend			- converts bit to binary format
 */
Datum
bitsend(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	StringInfoData buf;

	INSTR_METRIC_INC(INSTR_TSQL_BIT_SEND);

	pq_begintypsend(&buf);
	pq_sendbyte(&buf, arg1 ? 1 : 0);
	PG_RETURN_BYTEA_P(pq_endtypsend(&buf));
}

/*
 *   Cast functions
 */
Datum
int2bit(PG_FUNCTION_ARGS)
{
	int input = PG_GETARG_INT16(0);
	bool result = input == 0 ? false : true;

	PG_RETURN_BOOL(result);
}

Datum
int4bit(PG_FUNCTION_ARGS)
{
	int32 input = PG_GETARG_INT32(0);
	bool result = input == 0 ? false : true;

	PG_RETURN_BOOL(result);
}

Datum
int8bit(PG_FUNCTION_ARGS)
{
	int64 input = PG_GETARG_INT64(0);
	bool result = input == 0 ? false : true;

	PG_RETURN_BOOL(result);
}

/* Convert float4 to fixeddecimal */
Datum
ftobit(PG_FUNCTION_ARGS)
{
	float4 arg = PG_GETARG_FLOAT4(0);
	bool result = arg == 0 ? false : true;

	PG_RETURN_BOOL(result);
}

/* Convert float8 to fixeddecimal */
Datum
dtobit(PG_FUNCTION_ARGS)
{
	float8 arg = PG_GETARG_FLOAT8(0);
	bool result = arg == 0 ? false : true;

	PG_RETURN_BOOL(result);
}

Datum
numeric_bit(PG_FUNCTION_ARGS)
{
	Numeric num = PG_GETARG_NUMERIC(0);
	char *tmp;
	bool result = false;
	int len;
	int i;

	if (numeric_is_nan(num))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("cannot convert NaN to bit")));

	tmp = DatumGetCString(DirectFunctionCall1(numeric_out,
											  NumericGetDatum(num)));

	len = strlen(tmp);
	for(i = 0; i < len; i++)
	{
		/* Skip the decimal point */
		if (tmp[i] == '.')
			continue;
		if (tmp[i] != '0')
		{
			result = true;
			break;
		}
	}

	PG_RETURN_BOOL(result);
}

/* Arithmetic operators on bit */
Datum
bitneg(PG_FUNCTION_ARGS)
{
	bool arg = PG_GETARG_BOOL(0);

	PG_RETURN_BOOL(arg);
}

Datum
biteq(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	bool		arg2 = PG_GETARG_BOOL(1);

	PG_RETURN_BOOL(arg1 == arg2);
}

Datum
bitne(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	bool		arg2 = PG_GETARG_BOOL(1);

	PG_RETURN_BOOL(arg1 != arg2);
}

Datum
bitlt(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	bool		arg2 = PG_GETARG_BOOL(1);

	PG_RETURN_BOOL(arg1 < arg2);
}

Datum
bitgt(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	bool		arg2 = PG_GETARG_BOOL(1);

	PG_RETURN_BOOL(arg1 > arg2);
}

Datum
bitle(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	bool		arg2 = PG_GETARG_BOOL(1);

	PG_RETURN_BOOL(arg1 <= arg2);
}

Datum
bitge(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	bool		arg2 = PG_GETARG_BOOL(1);

	PG_RETURN_BOOL(arg1 >= arg2);
}

Datum
bit_cmp(PG_FUNCTION_ARGS)
{
	bool		arg1 = PG_GETARG_BOOL(0);
	bool		arg2 = PG_GETARG_BOOL(1);

	PG_RETURN_INT32((arg1 < arg2) ? -1 : ((arg1 > arg2) ? 1 : 0));
}

/* Comparison between int and bit */
Datum
int4biteq(PG_FUNCTION_ARGS)
{
    int  input1 = PG_GETARG_INT32(0);
    bool arg1 = input1 == 0 ? false : true;
    bool arg2 = PG_GETARG_BOOL(1);

    PG_RETURN_BOOL(arg1 == arg2);
}

Datum
int4bitne(PG_FUNCTION_ARGS)
{
    int  input1 = PG_GETARG_INT32(0);
    bool arg1 = input1 == 0 ? false : true;
    bool arg2 = PG_GETARG_BOOL(1);

    PG_RETURN_BOOL(arg1 != arg2);
}

Datum
int4bitlt(PG_FUNCTION_ARGS)
{
    int  input1 = PG_GETARG_INT32(0);
    bool arg1 = input1 == 0 ? false : true;
    bool arg2 = PG_GETARG_BOOL(1);

    PG_RETURN_BOOL(arg1 < arg2);
}

Datum
int4bitle(PG_FUNCTION_ARGS)
{
    int  input1 = PG_GETARG_INT32(0);
    bool arg1 = input1 == 0 ? false : true;
    bool arg2 = PG_GETARG_BOOL(1);

    PG_RETURN_BOOL(arg1 <= arg2);
}

Datum
int4bitgt(PG_FUNCTION_ARGS)
{
    int  input1 = PG_GETARG_INT32(0);
    bool arg1 = input1 == 0 ? false : true;
    bool arg2 = PG_GETARG_BOOL(1);

    PG_RETURN_BOOL(arg1 > arg2);
}

Datum
int4bitge(PG_FUNCTION_ARGS)
{
    int  input1 = PG_GETARG_INT32(0);
    bool arg1 = input1 == 0 ? false : true;
    bool arg2 = PG_GETARG_BOOL(1);

    PG_RETURN_BOOL(arg1 >= arg2);
}

/* Comparison between bit and int */
Datum
bitint4eq(PG_FUNCTION_ARGS)
{
    bool arg1 = PG_GETARG_BOOL(0);
    int  input2 = PG_GETARG_INT32(1);
    bool arg2 = input2 == 0 ? false : true;

    PG_RETURN_BOOL(arg1 == arg2);
}

Datum
bitint4ne(PG_FUNCTION_ARGS)
{
    bool arg1 = PG_GETARG_BOOL(0);
    int  input2 = PG_GETARG_INT32(1);
    bool arg2 = input2 == 0 ? false : true;

    PG_RETURN_BOOL(arg1 != arg2);
}

Datum
bitint4lt(PG_FUNCTION_ARGS)
{
    bool arg1 = PG_GETARG_BOOL(0);
    int  input2 = PG_GETARG_INT32(1);
    bool arg2 = input2 == 0 ? false : true;

    PG_RETURN_BOOL(arg1 < arg2);
}

Datum
bitint4le(PG_FUNCTION_ARGS)
{
    bool arg1 = PG_GETARG_BOOL(0);
    int  input2 = PG_GETARG_INT32(1);
    bool arg2 = input2 == 0 ? false : true;

    PG_RETURN_BOOL(arg1 <= arg2);
}

Datum
bitint4gt(PG_FUNCTION_ARGS)
{
    bool arg1 = PG_GETARG_BOOL(0);
    int  input2 = PG_GETARG_INT32(1);
    bool arg2 = input2 == 0 ? false : true;

    PG_RETURN_BOOL(arg1 > arg2);
}

Datum
bitint4ge(PG_FUNCTION_ARGS)
{
    bool arg1 = PG_GETARG_BOOL(0);
    int  input2 = PG_GETARG_INT32(1);
    bool arg2 = input2 == 0 ? false : true;

    PG_RETURN_BOOL(arg1 >= arg2);
}

Datum
bit2int2(PG_FUNCTION_ARGS)
{
    bool bit = PG_GETARG_BOOL(0);

    PG_RETURN_INT16(bit ? 1 : 0);
}

Datum
bit2int4(PG_FUNCTION_ARGS)
{
    bool bit = PG_GETARG_BOOL(0);

    PG_RETURN_INT32(bit ? 1 : 0);
}

Datum
bit2int8(PG_FUNCTION_ARGS)
{
    bool bit = PG_GETARG_BOOL(0);

    PG_RETURN_INT64(bit ? 1 : 0);
}

Datum
bit2numeric(PG_FUNCTION_ARGS)
{
    bool bit = PG_GETARG_BOOL(0);
    Numeric num = bit ? tsql_set_var_from_str_wrapper("1") : tsql_set_var_from_str_wrapper("0");

    PG_RETURN_NUMERIC(num);
}

Datum
bit2fixeddec(PG_FUNCTION_ARGS)
{
    bool bit = PG_GETARG_BOOL(0);

    PG_RETURN_INT64(bit ? 1*FIXEDDECIMAL_MULTIPLIER : 0);
}
