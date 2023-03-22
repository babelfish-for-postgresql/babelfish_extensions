/*
 * String-related functions for T-SQL
 */

#include "postgres.h"

#include "catalog/pg_type.h"
#include "common/cryptohash.h"
#include "common/md5.h"
#include "common/sha2.h"
#include "parser/parse_coerce.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include "utils/lsyscache.h"
#include <openssl/sha.h>
#include "utils/varlena.h"
#include "utils/numeric.h"
#include "c.h"
#include "pltsql.h"
#include "pltsql-2.h"


#define MD5_RESULTLEN  (16)
#define SHA1_RESULTLEN	(20)
#define SHA512_RESULTLEN (64)

PG_FUNCTION_INFO_V1(hashbytes);
PG_FUNCTION_INFO_V1(quotename);
PG_FUNCTION_INFO_V1(string_escape);
PG_FUNCTION_INFO_V1(formatmessage);
PG_FUNCTION_INFO_V1(tsql_varchar_substr);
PG_FUNCTION_INFO_V1(float_str);

/*
 * Helper functions for float_str()
*/
static int	round_float_char(char *float_char, int round_pos, int has_neg_sign);
static int	find_round_pos(char *float_char, int has_neg_sign, int int_digits, int deci_digits, int input_deci_digits, int input_deci_point, int deci_sig);
static Datum return_varchar_pointer(char *buf, int size);

/*
 * Hashbytes implementation
 *
 * According to some SQL tsql, MD2, MD4, MD5, SHA/SHA1 still
 * work, but should give a deprecation warning.
 *
 * OpenSSL no longer supports MD2 or MD4, so it would likely have to be
 * reimplemented from scratch if it is needed. For now,
 * treat MD2 and MD4 as unsupported.
 *
 * We use the Postgres implementations where available (for sha256 and md5),
 * and OpenSSL for the rest.
 */
Datum
hashbytes(PG_FUNCTION_ARGS)
{
	const char *algorithm = text_to_cstring(PG_GETARG_TEXT_P(0));
	bytea	   *in = PG_GETARG_BYTEA_PP(1);
	size_t		len = VARSIZE_ANY_EXHDR(in);
	const uint8 *data = (unsigned char *) VARDATA_ANY(in);
	bytea	   *result;

	if (strcasecmp(algorithm, "MD2") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(algorithm, "MD4") == 0)
	{
		PG_RETURN_NULL();
	}
	else if (strcasecmp(algorithm, "MD5") == 0)
	{
		unsigned char buf[MD5_RESULTLEN];
		const char *errstr = NULL;
		bool		success;

		success = pg_md5_binary(data, len, buf, &errstr);

		if (unlikely(!success)) /* OOM */
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("could not compute MD5 encryption: %s", errstr)));

		result = palloc(sizeof(buf) + VARHDRSZ);

		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else if (strcasecmp(algorithm, "SHA") == 0 ||
			 strcasecmp(algorithm, "SHA1") == 0)
	{
		unsigned char buf[SHA1_RESULTLEN];

		SHA1(data, len, buf);

		result = palloc(sizeof(buf) + VARHDRSZ);

		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else if (strcasecmp(algorithm, "SHA2_256") == 0)
	{
		pg_cryptohash_ctx *ctx = pg_cryptohash_create(PG_SHA256);
		unsigned char buf[PG_SHA256_DIGEST_LENGTH];

		if (pg_cryptohash_init(ctx) < 0)
			elog(ERROR, "could not initialize %s context", "SHA256");
		if (pg_cryptohash_update(ctx, data, len) < 0)
			elog(ERROR, "could not update %s context", "SHA256");
		if (pg_cryptohash_final(ctx, buf, PG_SHA256_DIGEST_LENGTH) < 0)
			elog(ERROR, "could not finalize %s context", "SHA256");
		pg_cryptohash_free(ctx);

		result = palloc(sizeof(buf) + VARHDRSZ);

		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else if (strcasecmp(algorithm, "SHA2_512") == 0)
	{
		unsigned char buf[SHA512_RESULTLEN];

		SHA512(data, len, buf);

		result = palloc(sizeof(buf) + VARHDRSZ);

		SET_VARSIZE(result, sizeof(buf) + VARHDRSZ);
		memcpy(VARDATA(result), buf, sizeof(buf));

		PG_RETURN_BYTEA_P(result);
	}
	else
	{
		PG_RETURN_NULL();
	}
}

/*
 * Takes in a sysname (nvarchar(128) NOT NULL)
 *
 * Returns nvarchar
 *
 * Adds brackets around string to create a valid delimited identifier.
 */
Datum
quotename(PG_FUNCTION_ARGS)
{
	const char *input_string = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *delimiter = text_to_cstring(PG_GETARG_TEXT_P(1));

	char		left_delim;
	char		right_delim;
	char	   *buf;
	int			buf_i = 0;

	/* Validate input len */
	if (strlen(input_string) > 128)
	{
		PG_RETURN_NULL();
	}
	if (strlen(delimiter) != 1)
	{
		PG_RETURN_NULL();
	}

	switch (*delimiter)
	{
		case ']':
		case '[':
			left_delim = '[';
			right_delim = ']';
			break;
		case '`':
		case '\'':
		case '"':
			left_delim = *delimiter;
			right_delim = *delimiter;
			break;
		case '(':
		case ')':
			left_delim = '(';
			right_delim = ')';
			break;
		case '<':
		case '>':
			left_delim = '>';
			right_delim = '<';
			break;
		case '{':
		case '}':
			left_delim = '{';
			right_delim = '}';
			break;
		default:
			PG_RETURN_NULL();
	}

	/* Input size is max 128, so output max is 128 * 2 + 2 (for delimiters) */
	buf = palloc(258 * sizeof(char));
	memset(buf, 0, 258 * sizeof(char));


	/* Process input string to include escape characters */
	buf[buf_i++] = left_delim;
	for (int i = 0; i < strlen(input_string); i++)
	{
		switch (input_string[i])
		{
				/* Escape chars */
			case '\'':
			case ']':
			case '"':
				buf[buf_i++] = input_string[i];
				buf[buf_i++] = input_string[i];
				break;
			default:
				buf[buf_i++] = input_string[i];
		}
	}
	buf[buf_i++] = right_delim;

	return return_varchar_pointer(buf, buf_i);
}

Datum
string_escape(PG_FUNCTION_ARGS)
{
	const char *str = text_to_cstring(PG_GETARG_TEXT_P(0));
	const char *type = text_to_cstring(PG_GETARG_TEXT_P(1));

	StringInfoData buf;
	int			text_len = strlen(str);

	if (strcmp(type, "json"))
	{
		PG_RETURN_NULL();
	}

	if (text_len == 0)
	{
		PG_RETURN_NULL();
	}

	initStringInfo(&buf);

	for (int i = 0; i < text_len; i++)
	{
		switch (str[i])
		{
			case 8:				/* Backspace */
				appendStringInfoString(&buf, "\\b");
				break;
			case 9:				/* Horizontal tab */
				appendStringInfoString(&buf, "\\t");
				break;
			case 10:			/* New line */
				appendStringInfoString(&buf, "\\n");
				break;
			case 12:			/* Form feed */
				appendStringInfoString(&buf, "\\f");
				break;
			case 13:			/* Carriage return */
				appendStringInfoString(&buf, "\\r");
				break;
			case '\"':
				appendStringInfoString(&buf, "\\\"");
				break;
			case '/':
				appendStringInfoString(&buf, "\\/");
				break;
			case '\\':
				appendStringInfoString(&buf, "\\\\");
				break;
			default:
				if (str[i] < 32)
				{
					appendStringInfo(&buf, "\\u00%02x", (unsigned char) (str[i]));
				}
				else
				{
					appendStringInfoChar(&buf, str[i]);
				}
		}
	}

	return return_varchar_pointer(buf.data, buf.len);
}

/*
 * The default format() function implemented in Postgres doesn't cover some
 * of the more exotic number formats, such as %i, %o, %u, and %x. There are
 * also TSQL specific implementation details for FORMATMESSAGE, such as NULL
 * handling and escape sequences that differ from the default as well..
 *
 */
Datum
formatmessage(PG_FUNCTION_ARGS)
{
	char	   *msg_string;
	int			nargs = PG_NARGS() - 1;
	Datum	   *args;
	Oid		   *argtypes;
	bool	   *argisnull;
	StringInfoData buf;

	if (nargs > 20)
	{
		/* Need to issue warning? */
		nargs = 20;
	}

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	msg_string = text_to_cstring(PG_GETARG_TEXT_P(0));

	args = (Datum *) palloc(sizeof(Datum) * nargs);
	argtypes = (Oid *) palloc(sizeof(Oid) * nargs);
	argisnull = (bool *) palloc(sizeof(bool) * nargs);

	for (int i = 0; i < nargs; i++)
	{
		args[i] = PG_GETARG_DATUM(i + 1);
		argtypes[i] = get_fn_expr_argtype(fcinfo->flinfo, i + 1);
		argisnull[i] = PG_ARGISNULL(i + 1);
	}

	initStringInfo(&buf);
	prepare_format_string(&buf, msg_string, nargs, args, argtypes, argisnull);
	return return_varchar_pointer(buf.data, buf.len);
}

/*
 * Constructs a formatted string with provided format and arguments.
 */
void
prepare_format_string(StringInfo buf, char *msg_string, int nargs,
					  Datum *args, Oid *argtypes, bool *argisnull)
{
	int			i = 0;

	size_t		prev_fmt_seg_sz = TSQL_MAX_MESSAGE_LEN + 1;
	size_t		seg_len = 0;

	char	   *seg_start,
			   *seg_end,
			   *arg_str,
			   *fmt_seg;
	char		placeholder;

	Oid			prev_type = 0;
	Oid			typid;
	TYPCATEGORY type;
	Datum		arg;

	FmgrInfo	typoutputfinfo;

	fmt_seg = palloc((TSQL_MAX_MESSAGE_LEN + 1) * sizeof(char));
	memset(fmt_seg, 0, (TSQL_MAX_MESSAGE_LEN + 1) * sizeof(char));

	seg_start = msg_string;
	seg_end = strchr(seg_start, '%');

	/* Missing format char */
	if (seg_end == NULL)
	{
		seg_len = strlen(seg_start);
	}
	else
	{
		seg_len = seg_end - seg_start;
	}

	/* Copy over beginning of message, before first % character */
	appendBinaryStringInfoNT(buf, seg_start, seg_len);

	while (seg_end != NULL && buf->len <= TSQL_MAX_MESSAGE_LEN)
	{
		seg_start = seg_end;
		seg_end = strchr(seg_start + 1, '%');

		if (seg_end != NULL)
		{
			seg_len = seg_end - seg_start;
		}
		else
		{
			seg_len = strlen(seg_start);
		}
		if (seg_len > TSQL_MAX_MESSAGE_LEN + 1)
		{
			seg_len = TSQL_MAX_MESSAGE_LEN + 1;
		}
		placeholder = seg_start[1];

		if (strchr("diouxXs", placeholder) != NULL)
		{
			/* Valid placeholder */

			memset(fmt_seg, 0, prev_fmt_seg_sz);
			strncpy(fmt_seg, seg_start, seg_len);
			prev_fmt_seg_sz = seg_len;

			arg = args[i];

			if (i >= nargs || argisnull[i])
			{
				appendStringInfo(buf, "(null)");
				appendStringInfoString(buf, fmt_seg + 2);
				continue;
			}

			typid = argtypes[i];
			type = TypeCategory(typid);

			if (typid != prev_type)
			{
				Oid			typoutputfunc;
				bool		typIsVarlena;

				getTypeOutputInfo(typid, &typoutputfunc, &typIsVarlena);
				fmgr_info(typoutputfunc, &typoutputfinfo);
				prev_type = typid;
			}

			switch (type)
			{
				case TYPCATEGORY_STRING:
				case TYPCATEGORY_UNKNOWN:
					if (placeholder != 's')
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Param %d expected format type %s but received type %s",
										i + 1, fmt_seg, format_type_be(typid))));
					arg_str = OutputFunctionCall(&typoutputfinfo, arg);
					appendStringInfo(buf, fmt_seg, arg_str);
					break;
				case TYPCATEGORY_USER:
					arg_str = OutputFunctionCall(&typoutputfinfo, arg);
					appendStringInfo(buf, fmt_seg, arg_str);
					break;
				case TYPCATEGORY_NUMERIC:
					if (placeholder == 's')
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Param %d expected format type %s but received type %s",
										i + 1, fmt_seg, format_type_be(typid))));
					appendStringInfo(buf, fmt_seg, DatumGetInt32(arg));
					break;
				default:
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							 errmsg("Unsupported type with type %s", format_type_be(typid))));
			}

			i++;
		}
		else
		{
			/* Invalid placeholder, throw an error */
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("Invalid format specification: %s", seg_start)));
		}
	}
	if (seg_end != NULL)
	{
		seg_len = strlen(seg_end);
		appendBinaryStringInfoNT(buf, seg_end, seg_len);
	}

	if (buf->len > TSQL_MAX_MESSAGE_LEN)
	{
		/* Trim buf to be 2044, truncate with ... */
		for (int i = TSQL_MAX_MESSAGE_LEN - 3; i < TSQL_MAX_MESSAGE_LEN; i++)
		{
			buf->data[i] = '.';
		}
		buf->len = TSQL_MAX_MESSAGE_LEN;
	}

	buf->data[buf->len] = '\0';

	pfree(fmt_seg);
}

/*
 * tsql_varchar_substr()
 * Return a substring starting at the specified position.
 */
Datum
tsql_varchar_substr(PG_FUNCTION_ARGS)
{
	if (PG_ARGISNULL(0) || PG_ARGISNULL(1) || PG_ARGISNULL(2))
		PG_RETURN_NULL();

	PG_RETURN_VARCHAR_P(DirectFunctionCall3(text_substr, PG_GETARG_DATUM(0),
											PG_GETARG_INT32(1),
											PG_GETARG_INT32(2)));
}

/*
 * Returns character data converted from numeric data. The character data
 * is right-justified, with a specified length and decimal precision.
*/
Datum
float_str(PG_FUNCTION_ARGS)
{
	Numeric		float_numeric;
	int			precision;
	char	   *float_char;
	int32		length;
	int32		decimal;
	char	   *buf;
	int			size;
	char	   *ptr;
	int			input_deci_digits;
	int			has_neg_sign = 0;
	int			input_deci_point = 0;
	int			has_deci_point = 0;
	int			num_spaces = 0;
	int			int_digits = 0;
	int			deci_digits = 0;
	int			int_part_zeros = 0;
	int			deci_part_zeros = 0;
	int			deci_sig;
	int			round_pos = -1;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	float_numeric = PG_GETARG_NUMERIC(0);

	if (numeric_is_nan(float_numeric) || numeric_is_inf(float_numeric))
		PG_RETURN_NULL();

	float_char = DatumGetCString(DirectFunctionCall1(numeric_out,
													 NumericGetDatum(float_numeric)));

	/* precision = num of digits - negative sign - decimal point */
	precision = strlen(float_char);

	/* count number of numeric digits in the numeric input */
	/* find - and . in input */
	if (strchr(float_char, '-') != NULL)
	{
		precision--;
		has_neg_sign = 1;
	}

	if (strchr(float_char, '.') != NULL)
	{
		precision--;
		input_deci_point = 1;
		/* int_digits is num digits before decimal point (excluding -) */
		/* STR(-1234.56), int_digits = 4 */
		int_digits = strchr(float_char, '.') - float_char - has_neg_sign;
	}
	else
	{
		/* no decimal point, all digits are int digits */
		/* STR(123400), int_digits = precision = 6 */
		int_digits = precision;
	}
	input_deci_digits = precision - int_digits;

	/* max allowed input precision is 38 */
	if (precision > 38)
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("The number '%s' is out of the range for numeric representation (maximum precision 38).", float_char)));

	length = PG_GETARG_INT32(1);
	decimal = PG_GETARG_INT32(2);

	if (length <= 0 || length > 8000 || decimal < 0)
		PG_RETURN_NULL();

	if (int_digits + has_neg_sign > length)
	{
		/* return string of length filled with *  */
		/* STR(-1234, 4), return "****" */
		buf = palloc(length);
		memset(buf, '*', length);
		return return_varchar_pointer(buf, length);
	}
	else if (int_digits > 17)
	{
		/*
		 * max precision is 17 so remaining int digits will be padded with
		 * zeros
		 */
		/*
		 * STR(12345678901234567890, 20), int_part_zeros = 3, will return
		 * "12345678901234568000"
		 */
		int_part_zeros = int_digits - 17;
	}

	/* calculate num_spaces and deci_part_zeros */
	size = length + 1;
	/* allocate buffer for putting result together */
	buf = palloc(size);
	memset(buf, 0, size);
	if (has_neg_sign)
		length--;
	if (decimal > 0 && length > int_digits)
	{
		//result will have decimal part and it will take up 1 space
			has_deci_point = 1;
		length--;
	}

	/* update atual max decimal digits in result */

	/*
	 * STR(1234.5678, 8, 4), int_digits=4, length=8-1=7, decimal=7-4=3, will
	 * return "1234.567"
	 */
	if (length < (decimal + int_digits))
		decimal = length - int_digits;

	if (decimal > 0)
	{
		//max scale is 16, so actual deci_digits is min(decimal, 16),
		/* rest of the decimal digits will be disgarded */

		/*
		 * STR(0.123456789012345678, 20, 18), decimal=18, deci_digits=16. will
		 * return "  0.1234567890123457"
		 */
			deci_digits = Min(decimal, 16);
	}
	else
	{
		//no decimal digits
			deci_digits = 0;
	}

	num_spaces = length - int_digits - deci_digits;

	/* comp space for the decimal point */
	if (has_deci_point && !deci_digits)
	{
		//no enough space for decimal
			part, remove the decimal point and add one space
			/* STR(1.234, 2, 1) returns " 1" */
				num_spaces++;
		has_deci_point--;
	}

	/*
	 * max precision is 17, max significant digits in decimal part =
	 * min(remaining significant digits, input decimal digits)
	 */
	deci_sig = Min(Max(17 - int_digits, 0), input_deci_digits);

	/* compute deci_part_zeros and update actual deci_sig */
	if (deci_digits > 0 && length > 17 && deci_digits > deci_sig)
	{
		//total significant digits > 17 and last sig digit in decimal part
		/* STR(1234567890.1234567890, 22, 20) returns "1234567890.12345670000" */
			deci_part_zeros = deci_digits - deci_sig;
	}
	else if (deci_digits > input_deci_digits)
	{
		//decimal digits needed more than input

		/*
		 * STR(1.1234, 8, 6) returns "1.123400", deci_sig = 4, deci_part_zeros
		 * = 2
		 */
			deci_part_zeros = deci_digits - input_deci_digits;
		deci_sig = input_deci_digits;
	}
	else
	{
		//no zeros in the decimal part
		/* STR(1.1234, 5, 3) returns "1.123" */
			deci_sig = deci_digits;
	}


	/* set the spaces at the start of the string */
	if (num_spaces > 0)
		memset(buf, ' ', num_spaces);


	/* find if need to round, if round_pos = 0, do not need rounding */
	round_pos = find_round_pos(float_char, has_neg_sign, int_digits, deci_digits, input_deci_digits, input_deci_point, deci_sig);

	if (round_pos > 0)
	{
		/* do rounding */
		if (round_float_char(float_char, round_pos, has_neg_sign))
		{
			if (num_spaces > 0)
			{
				/* one more digits in front of the number,  */
				/* set the 1 in buffer and set first digit in float_char to 0 */
				/* STR(-999.9, 6, 0) returns " -1000" */
				if (has_neg_sign)
				{
					//set '-' after the spaces and increment num_spaces to skip '-' when copying number
						memset(buf + num_spaces - 1, '-', 1);
					num_spaces++;
				}
				memset(buf + num_spaces - 1, '1', 1);
				memset(float_char, '0', 1);
			}
			else
			{
				/* not enough space for the carried_over digit, return *** */
				/*
				 * the space limitation goes by the one set before the
				 * rounding & carried over
				 */
				/*
				 * STR(9999.998, 7, 2) returns "*******" but STR(10000.000, 7,
				 * 2) returns "10000.0"
				 */
				/*
				 * which means the max length constraint of integer part is
				 * still 4 after rounding
				 */
				memset(buf, '*', size - 1);
				return return_varchar_pointer(buf, size - 1);
			}
		}
	}


	/* copy the actual number to the buffer after preceding spaces */
	strncpy(buf + num_spaces, float_char, size - 1 - num_spaces);

	/* add decimal point if needed */
	/* STR(4, 3, 1) returns "4.0" */
	if (has_deci_point && !input_deci_digits)
		memset(buf + num_spaces + has_neg_sign + int_digits, '.', 1);


	/* set the zeros */
	if (deci_part_zeros > 0)
		memset(buf + size - deci_part_zeros - 1, '0', deci_part_zeros);

	if (int_part_zeros > 0)
	{
		if (deci_digits > 0)
		{
			ptr = strchr(buf, '.');
			memset(ptr - int_part_zeros, '0', int_part_zeros);
		}
		else
		{
			memset(buf + size - int_part_zeros - 1, '0', int_part_zeros);
		}
	}

	return return_varchar_pointer(buf, size);
}

/*
 * Find the rounding position of the float_char input using the constraints
 * returns the rounding position
*/
static int
find_round_pos(char *float_char, int has_neg_sign, int int_digits, int deci_digits, int input_deci_digits, int input_deci_point, int deci_sig)
{
	int			round_pos = 0;
	int			curr_digit;

	if (int_digits + input_deci_digits > 17)
	{
		/*
		 * exceeds the max precision, need to round to 17th digit(excluding -
		 * and .)
		 */
		if (int_digits > 17)
		{
			//round in int part
			/* STR(12345678901234567890, 20) returns "1234567890123456800" */
						curr_digit = float_char[17 + has_neg_sign] - '0';

			if (curr_digit >= 5)
				round_pos = 16 + has_neg_sign;
		}
		else
		{
			//round in decimal part

			/*
			 * STR(1234567890.1234567890, 22, 20) returns
			 * "1234567890.12345670000"
			 */
				curr_digit = float_char[17 + has_neg_sign + input_deci_point] - '0';
			if (curr_digit >= 5)
				round_pos = 16 + has_neg_sign + input_deci_point;
		}
	}
	else if (deci_digits && input_deci_digits > deci_sig)
	{
		/* input decimal digits > needed, round to last output decimal digit  */
		/* STR(-1.123456, 8, 5) retuns "-1.12346" */
		curr_digit = float_char[has_neg_sign + int_digits + input_deci_point + deci_sig] - '0';
		if (curr_digit >= 5)
			round_pos = has_neg_sign + int_digits + input_deci_point + deci_sig - 1;
	}
	else if (!deci_sig && input_deci_digits)
	{
		/* int part == length and has deci digit input, round to integer */
		/* STR(-1234.9, 5, 1) returns "-1235" */
		curr_digit = float_char[has_neg_sign + int_digits + 1] - '0';
		if (curr_digit >= 5)
			round_pos = has_neg_sign + int_digits - 1;
		//last digit of integer
	}

	return round_pos;
}

/*
 * Inplace round the float_char to the digit at round_pos, returns the final carried over digit
*/
static int
round_float_char(char *float_char, int round_pos, int has_neg_sign)
{
	int			curr_digit;
	int			carry = 1;

	while (round_pos > (0 + has_neg_sign) && carry)
	{
		if (float_char[round_pos] == '.')
		{
			round_pos--;
			continue;
		}
		curr_digit = float_char[round_pos] - '0' + carry;
		carry = curr_digit / 10;
		memset(float_char + round_pos, '0' + curr_digit % 10, 1);
		//update the curr digit
			round_pos--;
	}

	return carry;
}

/*
 * Convert a char * to Varchar *
 * returns the Varchar *
*/
static Datum
return_varchar_pointer(char *buf, int size)
{
	VarChar    *result;

	result = (*common_utility_plugin_ptr->tsql_varchar_input) (buf, size, -1);

	pfree(buf);
	PG_RETURN_VARCHAR_P(result);
}
