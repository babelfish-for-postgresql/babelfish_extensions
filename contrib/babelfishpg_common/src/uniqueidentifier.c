/*-------------------------------------------------------------------------
 *
 * uniqueidentifier.c
 *	  Functions for the type "uniqueidentifier".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/uuid.h"
#include "lib/stringinfo.h"

static void string_to_uuid(const char *source, pg_uuid_t *uuid);
static void reverse_memcpy(unsigned char *dst, unsigned char *src, size_t n);

PG_FUNCTION_INFO_V1(uniqueidentifier_in);

Datum
uniqueidentifier_in(PG_FUNCTION_ARGS)
{
    char       *uuid_str = PG_GETARG_CSTRING(0);
    pg_uuid_t  *uuid;

    uuid = (pg_uuid_t *) palloc(sizeof(*uuid));
    string_to_uuid(uuid_str, uuid);
    PG_RETURN_UUID_P(uuid);
}

PG_FUNCTION_INFO_V1(uniqueidentifier_out);

Datum
uniqueidentifier_out(PG_FUNCTION_ARGS)
{
    pg_uuid_t  *uuid = PG_GETARG_UUID_P(0);
    static const char hex_chars[] = "0123456789ABCDEF";
    StringInfoData buf;
    int         i;

    initStringInfo(&buf);
    for (i = 0; i < UUID_LEN; i++)
    {
        int         hi;
        int         lo;

        /*
         * We print uuid values as a string of 8, 4, 4, 4, and then 12
         * hexadecimal characters, with each group is separated by a hyphen
         * ("-"). Therefore, add the hyphens at the appropriate places here.
         */
        if (i == 4 || i == 6 || i == 8 || i == 10)
            appendStringInfoChar(&buf, '-');

        hi = uuid->data[i] >> 4;
        lo = uuid->data[i] & 0x0F;

        appendStringInfoChar(&buf, hex_chars[hi]);
        appendStringInfoChar(&buf, hex_chars[lo]);
    }

    PG_RETURN_CSTRING(buf.data);
}

/*
 * We allow UUIDs as a series of 32 hexadecimal digits with an optional dash
 * after each group of 4 hexadecimal digits, and optionally surrounded by {}.
 * (The canonical format 8x-4x-4x-4x-12x, where "nx" means n hexadecimal
 * digits, is the only one used for output.)
 */
static void
string_to_uuid(const char *source, pg_uuid_t *uuid)
{
	const char *src = source;
	bool		braces = false;
	int			i;

	if (src[0] == '{')
	{
		src++;
		braces = true;
	}

	for (i = 0; i < UUID_LEN; i++)
	{
		char		str_buf[3];

		if (src[0] == '\0' || src[1] == '\0')
			goto syntax_error;
		memcpy(str_buf, src, 2);
		if (!isxdigit((unsigned char) str_buf[0]) ||
			!isxdigit((unsigned char) str_buf[1]))
			goto syntax_error;

		str_buf[2] = '\0';
		uuid->data[i] = (unsigned char) strtoul(str_buf, NULL, 16);
		src += 2;
		if (src[0] == '-' && (i % 2) == 1 && i < UUID_LEN - 1)
			src++;
	}

	if (braces)
	{
		if (*src != '}')
			goto syntax_error;
		src++;
	}

	return;

syntax_error:
	ereport(ERROR,
			(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
			 errmsg("invalid input syntax for type %s: \"%s\"",
					"uuid", source)));
}

PG_FUNCTION_INFO_V1(varchar2uniqueidentifier);

Datum
varchar2uniqueidentifier(PG_FUNCTION_ARGS)
{
    pg_uuid_t  *uuid;
    char *uuid_str = TextDatumGetCString(PG_GETARG_DATUM(0));
    uuid = (pg_uuid_t *) palloc(sizeof(*uuid));
    string_to_uuid(uuid_str, uuid);
    PG_RETURN_UUID_P(uuid);

}

PG_FUNCTION_INFO_V1(varbinary2uniqueidentifier);

Datum
varbinary2uniqueidentifier(PG_FUNCTION_ARGS)
{
	pg_uuid_t *uuid;
	unsigned char buffer[UUID_LEN];
	bytea *source = PG_GETARG_BYTEA_PP(0);
	char *data = VARDATA_ANY(source);
	int len = VARSIZE_ANY_EXHDR(source);

	memset(buffer, 0, UUID_LEN);
	memcpy(buffer, data, (len > UUID_LEN) ? UUID_LEN : len);

	uuid = (pg_uuid_t *) palloc0(sizeof(*uuid));
	/* T-SQL uses UUID variant 2 which is mixed-endian encoding */
	reverse_memcpy(uuid->data, buffer, 4);
	reverse_memcpy(uuid->data+4, buffer+4, 2);
	reverse_memcpy(uuid->data+6, buffer+6, 2);
	memcpy(uuid->data+8, buffer+8, 8);
	PG_RETURN_UUID_P(uuid);
}


PG_FUNCTION_INFO_V1(uniqueidentifier2varbinary);

Datum
uniqueidentifier2varbinary(PG_FUNCTION_ARGS)
{
	char *rp;
	bytea *result;
	int32 maxlen;
	unsigned char buffer[UUID_LEN];
	size_t len = UUID_LEN;
	pg_uuid_t *uuid = PG_GETARG_UUID_P(0);
	int32 typmod = PG_GETARG_INT32(1);

	/* T-SQL uses UUID variant 2 which is mixed-endian encoding */
	reverse_memcpy(buffer, uuid->data, 4);
	reverse_memcpy(buffer+4, uuid->data+4, 2);
	reverse_memcpy(buffer+6, uuid->data+6, 2);
	memcpy(buffer+8, uuid->data+8, 8);

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (len > maxlen)
		len = maxlen;

	result = (bytea *) palloc(len + VARHDRSZ);
	SET_VARSIZE(result, len + VARHDRSZ);
	rp = VARDATA(result);
	memcpy(rp, buffer, len);

	PG_RETURN_BYTEA_P(result);
}

PG_FUNCTION_INFO_V1(uniqueidentifier2binary);

Datum
uniqueidentifier2binary(PG_FUNCTION_ARGS)
{
	char *rp;
	bytea *result;
	int32 maxlen;
	unsigned char buffer[UUID_LEN];
	size_t len = UUID_LEN;
	pg_uuid_t *uuid = PG_GETARG_UUID_P(0);
	int32 typmod = PG_GETARG_INT32(1);

	/* T-SQL uses UUID variant 2 which is mixed-endian encoding */
	reverse_memcpy(buffer, uuid->data, 4);
	reverse_memcpy(buffer+4, uuid->data+4, 2);
	reverse_memcpy(buffer+6, uuid->data+6, 2);
	memcpy(buffer+8, uuid->data+8, 8);

	/* If typmod is -1 (or invalid), use the actual length */
	if (typmod < (int32) VARHDRSZ)
		maxlen = len;
	else
		maxlen = typmod - VARHDRSZ;

	if (len > maxlen)
		len = maxlen;

	result = (bytea *) palloc(maxlen + VARHDRSZ);
	SET_VARSIZE(result, maxlen + VARHDRSZ);
	rp = VARDATA(result);
	memcpy(rp, buffer, len);

	/* NULL pad the rest of the space */
	memset(rp + len, '\0', maxlen - len);

	PG_RETURN_BYTEA_P(result);
}

static void
reverse_memcpy(unsigned char *dst, unsigned char *src, size_t n)
{
	size_t i;

	for (i = 0; i < n; i++)
		dst[n-1-i] = src[i];
}
