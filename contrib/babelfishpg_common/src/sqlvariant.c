/*-------------------------------------------------------------------------
 *
 * sqlvariant.c
 *    Functions for the type "sql_variant".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "executor/spi.h"
#include "fmgr.h"
#include "miscadmin.h"
#include "access/hash.h"
#include "access/htup_details.h"
#include "catalog/namespace.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_database.h"
#include "catalog/pg_type.h"
#include "catalog/pg_operator.h"
#include "commands/dbcommands.h"
#include "lib/stringinfo.h"
#include "libpq/pqformat.h"
#include "port.h"
#include "utils/array.h"
#include "utils/date.h"
#include "parser/parse_coerce.h"
#include "parser/parse_oper.h"
#include "instr.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include "utils/guc.h"
#include "utils/hsearch.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/numeric.h"
#include "utils/syscache.h"
#include "utils/timestamp.h"
#include "utils/uuid.h"
#include "utils/varbit.h"

#include "collation.h"
#include "datetimeoffset.h"
#include "typecode.h"
#include "numeric.h"
#include "sqlvariant.h"

/*  Function Registeration  */
PG_FUNCTION_INFO_V1(sqlvariantin);
PG_FUNCTION_INFO_V1(sqlvariantout);
PG_FUNCTION_INFO_V1(sqlvariantrecv);
PG_FUNCTION_INFO_V1(sqlvariantsend);

/* extract coll related info*/
extern HTAB *ht_oid2collid;

/*
 * SQL_VARINT does not have its own textual representation
 * All supported types are expected to be cased into SQL_VARIANT
 * String values are treated as VARCHAR(len) type
 */

Datum
sqlvariantin(PG_FUNCTION_ARGS)
{
	char	   *str = PG_GETARG_CSTRING(0);
	Oid			typelem = PG_GETARG_OID(1);
	int32		atttypmod = PG_GETARG_INT32(2);
	bytea	   *result;
	text	   *data_val;
	size_t		data_size;
	size_t		total_size;
	type_info_t type_info = get_tsql_type_info(VARCHAR_T);
	Oid			type = type_info.oid;	/* hardcoded varchar */
	uint8_t		svhdr_size = type_info.svhdr_size;
	Oid			input_func;
	Oid			typIOParam;
	svhdr_5B_t *svhdr;

	getTypeInputInfo(type, &input_func, &typIOParam);
	/* evalute input fuction */
	data_val = (text *) OidInputFunctionCall(input_func, str, typelem, atttypmod);

	/* Copy Data */
	data_size = VARSIZE_ANY(data_val);
	if (SV_CAN_USE_SHORT_VALENA(data_size, svhdr_size))
	{
		total_size = VARHDRSZ_SHORT + svhdr_size + data_size;
		result = (bytea *) palloc(total_size);
		SET_VARSIZE_SHORT(result, total_size);
	}
	else
	{
		total_size = VARHDRSZ + svhdr_size + data_size;
		result = (bytea *) palloc(total_size);
		SET_VARSIZE(result, total_size);
	}
	memcpy(SV_DATA(result, svhdr_size), data_val, data_size);

	/* Set Metadata */
	svhdr = SV_HDR_5B(result);
	SV_SET_METADATA(svhdr, VARCHAR_T, HDR_VER); /* hardcode as VARCHAR */
	svhdr->typmod = VARSIZE_ANY_EXHDR(data_val);
	svhdr->collid = get_server_collation_collidx();

	/* Cleanup */
	pfree(data_val);

	PG_RETURN_BYTEA_P(result);
}

/*
 * SQL_VARIANT does not have its own textual representation
 * It always calls internal types's output function
 */

Datum
sqlvariantout(PG_FUNCTION_ARGS)
{
	char	   *result = NULL;
	bytea	   *vlena = PG_GETARG_BYTEA_PP(0);
	uint8_t		type_code = SV_GET_TYPCODE_PTR(vlena);
	type_info_t type_info = get_tsql_type_info(type_code);
	Oid			type = (Oid) type_info.oid;
	uint8_t		svhdr_size = type_info.svhdr_size;
	Oid			output_func;
	bool		typIsVarlena;
	size_t		data_len = VARSIZE_ANY_EXHDR(vlena) - svhdr_size;
	Datum	   *output_datum = palloc0(SIZEOF_DATUM);

	if (!get_typbyval(type))	/* pass by reference */
		*output_datum = SV_DATUM(vlena, svhdr_size);
	else						/* pass by value */
	{
		memcpy(output_datum, SV_DATUM_PTR(vlena, svhdr_size), data_len);
	}

	getTypeOutputInfo(type, &output_func, &typIsVarlena);
	result = OidOutputFunctionCall(output_func, *output_datum);

	PG_FREE_IF_COPY(vlena, 0);
	PG_RETURN_CSTRING(result);
}

/*
 * Binary representation is identical, only do memory copy in RECV/SEND functions
 */

Datum
sqlvariantrecv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);
	bytea	   *result;
	int			nbytes;

	INSTR_METRIC_INC(INSTR_TSQL_SQLVARIANT_RECV);

	nbytes = buf->len - buf->cursor;

	if (SV_CAN_USE_SHORT_VALENA(nbytes, 0))
	{
		result = (bytea *) palloc(nbytes + VARHDRSZ_SHORT);
		SET_VARSIZE_SHORT(result, nbytes + VARHDRSZ_SHORT);
	}
	else
	{
		result = (bytea *) palloc(nbytes + VARHDRSZ);
		SET_VARSIZE(result, nbytes + VARHDRSZ);
	}

	pq_copymsgbytes(buf, VARDATA_ANY(result), nbytes);
	PG_RETURN_BYTEA_P(result);
}

Datum
sqlvariantsend(PG_FUNCTION_ARGS)
{
	bytea	   *vlena = PG_GETARG_BYTEA_P_COPY(0);

	INSTR_METRIC_INC(INSTR_TSQL_SQLVARIANT_SEND);

	PG_RETURN_BYTEA_P(vlena);
}

/* Helper functions */
static Datum get_varchar128_sv_datum(const char *value);
static Datum get_int_sv_datum(int32_t value);

Datum
get_varchar128_sv_datum(const char *value)
{
	size_t		len = strlen(value);
	bytea	   *result;
	svhdr_5B_t *svhdr;
	size_t		sv_size;
	uint8_t		svhdr_size = get_tsql_type_info(VARCHAR_T).svhdr_size;

	/* return varchar(128) */
	sv_size = VARHDRSZ + svhdr_size + VARHDRSZ + len;
	result = palloc(sv_size);
	SET_VARSIZE(result, sv_size);
	SET_VARSIZE(SV_DATA(result, svhdr_size), VARHDRSZ + len);
	memcpy(VARDATA(SV_DATA(result, svhdr_size)), value, len);

	/* Header */
	svhdr = SV_HDR_5B(result);
	SV_SET_METADATA(svhdr, VARCHAR_T, HDR_VER);
	svhdr->typmod = len;		/* Actual Data Length */
	svhdr->collid = get_server_collation_collidx();

	PG_RETURN_BYTEA_P(result);
}

Datum
get_int_sv_datum(int32_t value)
{
	bytea	   *result;
	svhdr_1B_t *svhdr;
	uint8_t		svhdr_size = get_tsql_type_info(INT_T).svhdr_size;

	result = palloc(VARHDRSZ_SHORT + svhdr_size + sizeof(int32_t));
	SET_VARSIZE_SHORT(result, VARHDRSZ_SHORT + svhdr_size + sizeof(int32_t));
	*(int32_t *) (SV_DATA(result, svhdr_size)) = value;

	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, INT_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

/* Helper functions for CAST and COMPARE */
static Datum do_cast(Oid source_type, Oid target_type, Datum value, int32_t typmod, Oid coll,
					 CoercionContext cc, bool *cast_by_relabel);

static Datum compare_value(char *oprname, Oid type, Datum d1, Datum d2, Oid coll);

static Datum gen_type_datum_from_sqlvariant_bytea(bytea *sv, uint8_t target_typcode, int32_t typmod, Oid coll);

/* only called from the same type family */
Datum		do_compare(char *oprname, bytea *arg1, bytea *arg2, Oid fncollation);

Datum		comp_time(char *oprname, uint16_t t1, uint16_t t2);

Datum
compare_value(char *oprname, Oid type, Datum d1, Datum d2, Oid coll)
{
	Operator	operator;
	Oid			oprcode;

	operator = compatible_oper(NULL, list_make1(makeString(oprname)), type, type, false, -1);
	oprcode = oprfuncid(operator);
	ReleaseSysCache(operator);

	return OidFunctionCall2Coll(oprcode, coll, d1, d2);
}

Datum
do_cast(Oid source_type, Oid target_type, Datum value, int32_t typmod, Oid coll,
		CoercionContext ccontext, bool *cast_by_relabel)
{
	Oid			funcid;
	CoercionPathType path;
	Oid			typioparam;
	bool		isVarlena;

	path = find_coercion_pathway(target_type, source_type, ccontext, &funcid);


	switch (path)
	{
		case COERCION_PATH_FUNC:
			*cast_by_relabel = false;
			return OidFunctionCall3Coll(funcid, coll, value, (Datum) typmod, (Datum) ccontext == COERCION_EXPLICIT);
			break;
		case COERCION_PATH_COERCEVIAIO:
			*cast_by_relabel = false;
			if (TypeCategory(source_type) == TYPCATEGORY_STRING)
			{
				getTypeInputInfo(target_type, &funcid, &typioparam);
				return OidInputFunctionCall(funcid, TextDatumGetCString(value), typioparam, typmod);
			}
			else
			{
				getTypeOutputInfo(source_type, &funcid, &isVarlena);
				return CStringGetTextDatum(OidOutputFunctionCall(funcid, value));
			}
			break;
		case COERCION_PATH_RELABELTYPE:
			*cast_by_relabel = true;
			return value;
			break;
		default:
			*cast_by_relabel = false;
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("unable to cast from internal type %s to %s",
							format_type_be(source_type), format_type_be(target_type))));
	}
	return value;
}

bytea *
gen_sqlvariant_bytea_from_type_datum(size_t typcode, Datum data)
{
	type_info_t type_info = get_tsql_type_info(typcode);
	Oid			typoid = type_info.oid;
	int8_t		svhdr_size = type_info.svhdr_size;
	int16_t		typlen = get_typlen(typoid);
	size_t		data_len;

	bytea	   *result;
	size_t		result_len;

	if (IS_STRING_TYPE(typcode) || IS_BINARY_TYPE(typcode) || typcode == NUMERIC_T) /* varlena datatype */
	{
		data_len = VARSIZE_ANY(data);
		if (SV_CAN_USE_SHORT_VALENA(data_len, svhdr_size))
		{
			result_len = VARHDRSZ_SHORT + svhdr_size + data_len;
			result = palloc(result_len);
			SET_VARSIZE_SHORT(result, result_len);
		}
		else
		{
			result_len = VARHDRSZ + svhdr_size + data_len;
			result = palloc(result_len);
			SET_VARSIZE(result, result_len);
		}
		/* Copy Data */
		memcpy(SV_DATA(result, svhdr_size), (bytea *) DatumGetPointer(data), data_len);
	}
	else						/* fixed length datatype */
	{
		result_len = VARHDRSZ_SHORT + svhdr_size + typlen;
		result = palloc(result_len);
		SET_VARSIZE_SHORT(result, result_len);

		if (typlen <= SIZEOF_DATUM) /* pass by value */
			memcpy(SV_DATA(result, svhdr_size), &data, typlen);
		else
			memcpy(SV_DATA(result, svhdr_size), (bytea *) DatumGetPointer(data), typlen);
	}

	return result;
}

Datum
gen_type_datum_from_sqlvariant_bytea(bytea *sv, uint8_t target_typcode, int32_t typmod, Oid coll)
{
	uint8_t		typcode = SV_GET_TYPCODE_PTR(sv);
	type_info_t type_info = get_tsql_type_info(typcode);
	Oid			type_oid = (Oid) type_info.oid;
	uint8_t		svhdr_size = type_info.svhdr_size;
	Oid			target_oid = (Oid) get_tsql_type_info(target_typcode).oid;
	Datum	   *target_datum = palloc0(SIZEOF_DATUM);
	size_t		data_len = VARSIZE_ANY_EXHDR(sv) - svhdr_size;
	bool		cast_by_relabel;

	if (!get_typbyval(type_oid))	/* Pass by reference */
		*target_datum = SV_DATUM(sv, svhdr_size);
	else						/* Pass by value */
	{
		memcpy(target_datum, SV_DATUM_PTR(sv, svhdr_size), data_len);
	}

	set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

	if (typcode == target_typcode)
		return *target_datum;
	else
		return do_cast(type_oid, target_oid, *target_datum, typmod, coll, COERCION_EXPLICIT, &cast_by_relabel);
}

/*
 *  Time could not be implicitly cast to any other date & time types
 *  Within SQL_VARIANT type, we regard time is alwasy smaller than
 *  other date & time types
 */
Datum
comp_time(char *oprname, uint16_t t1, uint16_t t2)
{
	/*
	 * Notice: THIS IS NOT A GENERATL COMPARISON FUNCTION Assumption : 1 and
	 * ONLY 1 of t1,t2 is of TIME_T
	 */
	if (pg_strncasecmp(oprname, "<>", 2) == 0)
		PG_RETURN_BOOL(true);
	else if (pg_strncasecmp(oprname, ">", 1) == 0)	/* including >= */
		PG_RETURN_BOOL(t1 != TIME_T && t2 == TIME_T);
	else if (pg_strncasecmp(oprname, "<", 1) == 0)	/* including <= */
		PG_RETURN_BOOL(t1 == TIME_T && t2 != TIME_T);
	else						/* (pg_strncasecmp(oprname, "=", 2) == 0) */
		PG_RETURN_BOOL(false);

}

Datum
do_compare(char *oprname, bytea *arg1, bytea *arg2, Oid fncollation)
{
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	type_info_t type_info1 = get_tsql_type_info(type_code1);
	type_info_t type_info2 = get_tsql_type_info(type_code2);
	Oid			type_oid1 = (Oid) type_info1.oid;
	Oid			type_oid2 = (Oid) type_info2.oid;
	uint8_t		svhdr_size1 = type_info1.svhdr_size;
	uint8_t		svhdr_size2 = type_info2.svhdr_size;
	bool		d1_pass_by_ref = get_typbyval(type_oid1) == false;
	bool		d2_pass_by_ref = get_typbyval(type_oid2) == false;
	size_t		data_len1 = VARSIZE_ANY_EXHDR(arg1) - svhdr_size1;
	size_t		data_len2 = VARSIZE_ANY_EXHDR(arg2) - svhdr_size2;
	Datum		d1 = 0;
	Datum		d2 = 0;

	if (d1_pass_by_ref)
		d1 = SV_DATUM(arg1, svhdr_size1);
	else
		memcpy(&d1, SV_DATUM_PTR(arg1, svhdr_size1), data_len1);
	if (d2_pass_by_ref)
		d2 = SV_DATUM(arg2, svhdr_size2);
	else
		memcpy(&d2, SV_DATUM_PTR(arg2, svhdr_size2), data_len2);

	set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

	/* Check Type Code */
	if (type_code1 == type_code2)	/* same type */
	{
		if (IS_STRING_TYPE(type_code1)) /* handle string with different
										 * collation */
		{
			svhdr_5B_t *str_header1 = SV_HDR_5B(arg1);
			svhdr_5B_t *str_header2 = SV_HDR_5B(arg2);

			if (str_header1->collid != str_header2->collid)
			{
				int8_t		coll_cmp_result = cmp_collation(str_header1->collid, str_header2->collid);

				if (pg_strncasecmp(oprname, "<>", 2) == 0)
					PG_RETURN_BOOL(true);
				else if (pg_strncasecmp(oprname, ">", 1) == 0)	/* including >= */
					PG_RETURN_BOOL(coll_cmp_result > 0);
				else if (pg_strncasecmp(oprname, "<", 1) == 0)	/* including <= */
					PG_RETURN_BOOL(coll_cmp_result < 0);
				else			/* (pg_strncasecmp(oprname, "=", 1) == 0) */
					PG_RETURN_BOOL(false);
			}
		}
		return compare_value(oprname, type_oid1, d1, d2, fncollation);
	}
	else						/* implicit cast within type family */
	{
		Datum		temp_datum;
		Datum		result;
		Operator	direct_cmp;
		Oid			oprcode;
		bool		cast_by_relabel;

		/* handle sql_variant specific cases */
		if (type_code1 == TIME_T || type_code2 == TIME_T)
			return comp_time(oprname, type_code1, type_code2);

		/* find direct comparisions without casting */
		direct_cmp = compatible_oper(NULL, list_make1(makeString(oprname)),
									 type_oid1, type_oid2, true, -1);
		if (direct_cmp)
		{
			oprcode = oprfuncid(direct_cmp);
			ReleaseSysCache(direct_cmp);
			return OidFunctionCall2Coll(oprcode, fncollation, d1, d2);
		}

		/* do implicit cast */
		/* typmod is not considered during a implicit cast comparison */
		if (type_code1 < type_code2)	/* CAST arg2 to arg1 */
		{
			temp_datum = do_cast(type_oid2, type_oid1, d2, -1, fncollation, COERCION_IMPLICIT, &cast_by_relabel);
			result = compare_value(oprname, type_oid1, d1, temp_datum, fncollation);
			if (d1_pass_by_ref && !cast_by_relabel) /* delete temporary
													 * variable */
				pfree((char *) temp_datum);

			return result;
		}
		else					/* CAST arg1 to arg2 */
		{
			temp_datum = do_cast(type_oid1, type_oid2, d1, -1, fncollation, COERCION_IMPLICIT, &cast_by_relabel);
			result = compare_value(oprname, type_oid2, temp_datum, d2, fncollation);
			if (d2_pass_by_ref && !cast_by_relabel) /* delete temporary
													 * variable */
				pfree((char *) temp_datum);

			return result;
		}
	}
}


/*
 * CAST functions to SQL_VARIANT
 */

PG_FUNCTION_INFO_V1(datetime2sqlvariant);
PG_FUNCTION_INFO_V1(datetime22sqlvariant);
PG_FUNCTION_INFO_V1(smalldatetime2sqlvariant);
PG_FUNCTION_INFO_V1(datetimeoffset2sqlvariant);
PG_FUNCTION_INFO_V1(date2sqlvariant);
PG_FUNCTION_INFO_V1(time2sqlvariant);
PG_FUNCTION_INFO_V1(float2sqlvariant);
PG_FUNCTION_INFO_V1(real2sqlvariant);
PG_FUNCTION_INFO_V1(numeric2sqlvariant);
PG_FUNCTION_INFO_V1(money2sqlvariant);
PG_FUNCTION_INFO_V1(smallmoney2sqlvariant);
PG_FUNCTION_INFO_V1(bigint2sqlvariant);
PG_FUNCTION_INFO_V1(int2sqlvariant);
PG_FUNCTION_INFO_V1(smallint2sqlvariant);
PG_FUNCTION_INFO_V1(tinyint2sqlvariant);
PG_FUNCTION_INFO_V1(bit2sqlvariant);
PG_FUNCTION_INFO_V1(varchar2sqlvariant);
PG_FUNCTION_INFO_V1(nvarchar2sqlvariant);
PG_FUNCTION_INFO_V1(char2sqlvariant);
PG_FUNCTION_INFO_V1(nchar2sqlvariant);
PG_FUNCTION_INFO_V1(bbfvarbinary2sqlvariant);
PG_FUNCTION_INFO_V1(bbfbinary2sqlvariant);
PG_FUNCTION_INFO_V1(uniqueidentifier2sqlvariant);

/* Date and time */
Datum
datetime2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(DATETIME_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, DATETIME_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
datetime22sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(DATETIME2_T, data);
	svhdr_2B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_2B(result);
	SV_SET_METADATA(svhdr, DATETIME2_T, HDR_VER);
	svhdr->typmod = -1;

	PG_RETURN_BYTEA_P(result);
}

Datum
smalldatetime2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(SMALLDATETIME_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, SMALLDATETIME_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
datetimeoffset2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(DATETIMEOFFSET_T, data);
	svhdr_2B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_2B(result);
	SV_SET_METADATA(svhdr, DATETIMEOFFSET_T, HDR_VER);
	svhdr->typmod = -1;

	PG_RETURN_BYTEA_P(result);
}

Datum
date2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(DATE_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, DATE_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
time2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(TIME_T, data);
	svhdr_2B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_2B(result);
	SV_SET_METADATA(svhdr, TIME_T, HDR_VER);
	svhdr->typmod = -1;

	PG_RETURN_BYTEA_P(result);
}

/* Approximate numerics */
Datum
float2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(FLOAT_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, FLOAT_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
real2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(REAL_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, REAL_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

/* Exact numerics */
Datum
numeric2sqlvariant(PG_FUNCTION_ARGS)
{
	Numeric		num = PG_GETARG_NUMERIC(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(NUMERIC_T, NumericGetDatum(num));
	svhdr_3B_t *svhdr;
	int16_t		precision;
	int16_t		scale;
	int32_t		typmod_container;

	/* Type Specific Header */
	svhdr = SV_HDR_3B(result);
	SV_SET_METADATA(svhdr, NUMERIC_T, HDR_VER);

	/*
	 * tsql_numeric_get_typmod() returns 32bit int. need to convert it to
	 * 16bit
	 */
	typmod_container = tsql_numeric_get_typmod(num);
	if (typmod_container != -1)
	{
		precision = ((typmod_container - VARHDRSZ) >> 16) & 0xFF;
		scale = (typmod_container - VARHDRSZ) & 0xFF;
		svhdr->typmod = (precision << 8) | scale;
	}
	else
	{
		svhdr->typmod = -1;
	}


	PG_RETURN_BYTEA_P(result);
}

Datum
money2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(MONEY_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, MONEY_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
smallmoney2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(SMALLMONEY_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, SMALLMONEY_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
bigint2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(BIGINT_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, BIGINT_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
int2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(INT_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, INT_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
smallint2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(SMALLINT_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, SMALLINT_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
tinyint2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(TINYINT_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, TINYINT_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

Datum
bit2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(BIT_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, BIT_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}

/* Character strings */
Datum
varchar2sqlvariant(PG_FUNCTION_ARGS)
{
	VarChar    *vch = PG_GETARG_VARCHAR_PP(0);
	Oid			coll = PG_GET_COLLATION();
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(VARCHAR_T, PointerGetDatum(vch));
	svhdr_5B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_5B(result);
	SV_SET_METADATA(svhdr, VARCHAR_T, HDR_VER);
	svhdr->typmod = VARSIZE_ANY_EXHDR(vch);
	svhdr->collid = get_persist_collation_id(coll);

	PG_RETURN_BYTEA_P(result);
}

Datum
nvarchar2sqlvariant(PG_FUNCTION_ARGS)
{
	VarChar    *vch = PG_GETARG_VARCHAR_PP(0);
	Oid			coll = PG_GET_COLLATION();
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(NVARCHAR_T, PointerGetDatum(vch));
	svhdr_5B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_5B(result);
	SV_SET_METADATA(svhdr, NVARCHAR_T, HDR_VER);
	svhdr->typmod = VARSIZE_ANY_EXHDR(vch);
	svhdr->collid = get_persist_collation_id(coll);

	PG_RETURN_BYTEA_P(result);
}

Datum
char2sqlvariant(PG_FUNCTION_ARGS)
{
	BpChar	   *bpch = PG_GETARG_BPCHAR_PP(0);
	Oid			coll = PG_GET_COLLATION();
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(CHAR_T, PointerGetDatum(bpch));
	svhdr_5B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_5B(result);
	SV_SET_METADATA(svhdr, CHAR_T, HDR_VER);
	svhdr->typmod = VARSIZE_ANY_EXHDR(bpch);
	svhdr->collid = get_persist_collation_id(coll);

	PG_RETURN_BYTEA_P(result);
}

Datum
nchar2sqlvariant(PG_FUNCTION_ARGS)
{
	BpChar	   *bpch = PG_GETARG_BPCHAR_PP(0);
	Oid			coll = PG_GET_COLLATION();
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(NCHAR_T, PointerGetDatum(bpch));
	svhdr_5B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_5B(result);
	SV_SET_METADATA(svhdr, NCHAR_T, HDR_VER);
	svhdr->typmod = VARSIZE_ANY_EXHDR(bpch);
	svhdr->collid = get_persist_collation_id(coll);

	PG_RETURN_BYTEA_P(result);
}

/* Binary strings */
Datum
bbfvarbinary2sqlvariant(PG_FUNCTION_ARGS)
{
	bytea	   *bt = PG_GETARG_BYTEA_PP(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(VARBINARY_T, PointerGetDatum(bt));
	svhdr_3B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_3B(result);
	SV_SET_METADATA(svhdr, VARBINARY_T, HDR_VER);
	svhdr->typmod = VARSIZE_ANY_EXHDR(bt);

	PG_RETURN_BYTEA_P(result);
}

Datum
bbfbinary2sqlvariant(PG_FUNCTION_ARGS)
{
	bytea	   *bt = PG_GETARG_BYTEA_PP(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(BINARY_T, PointerGetDatum(bt));
	svhdr_3B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_3B(result);
	SV_SET_METADATA(svhdr, BINARY_T, HDR_VER);
	svhdr->typmod = VARSIZE_ANY_EXHDR(bt);

	PG_RETURN_BYTEA_P(result);
}

Datum
uniqueidentifier2sqlvariant(PG_FUNCTION_ARGS)
{
	Datum		data = PG_GETARG_DATUM(0);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(UNIQUEIDENTIFIER_T, data);
	svhdr_1B_t *svhdr;

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, UNIQUEIDENTIFIER_T, HDR_VER);

	PG_RETURN_BYTEA_P(result);
}


/*
 * CAST functions from SQL_VARIANT
 */

PG_FUNCTION_INFO_V1(sqlvariant2timestamp);
PG_FUNCTION_INFO_V1(sqlvariant2datetime2);
PG_FUNCTION_INFO_V1(sqlvariant2datetimeoffset);
PG_FUNCTION_INFO_V1(sqlvariant2date);
PG_FUNCTION_INFO_V1(sqlvariant2time);
PG_FUNCTION_INFO_V1(sqlvariant2float);
PG_FUNCTION_INFO_V1(sqlvariant2real);
PG_FUNCTION_INFO_V1(sqlvariant2numeric);
PG_FUNCTION_INFO_V1(sqlvariant2fixeddecimal);
PG_FUNCTION_INFO_V1(sqlvariant2bigint);
PG_FUNCTION_INFO_V1(sqlvariant2int);
PG_FUNCTION_INFO_V1(sqlvariant2smallint);
PG_FUNCTION_INFO_V1(sqlvariant2bit);
PG_FUNCTION_INFO_V1(sqlvariant2varchar);
PG_FUNCTION_INFO_V1(sqlvariant2char);
PG_FUNCTION_INFO_V1(sqlvariant2bbfvarbinary);
PG_FUNCTION_INFO_V1(sqlvariant2bbfbinary);
PG_FUNCTION_INFO_V1(sqlvariant2uniqueidentifier);


/* Postgres will do self casts to apply typmod
 * if we does not apply typmod during type cast.
 * However, it may be faster may be if we apply typmod
 * directly during type cast.
*/
Datum
sqlvariant2timestamp(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	Timestamp	result;

	result = DatumGetTimestamp(gen_type_datum_from_sqlvariant_bytea(sv, DATETIME_T, -1, coll));

	PG_RETURN_TIMESTAMP(result);
}

Datum
sqlvariant2datetime2(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	Timestamp	result;

	result = DatumGetTimestamp(gen_type_datum_from_sqlvariant_bytea(sv, DATETIME2_T, -1, coll));

	PG_RETURN_TIMESTAMP(result);
}

Datum
sqlvariant2datetimeoffset(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	tsql_datetimeoffset *result;

	result = DatumGetDatetimeoffset(gen_type_datum_from_sqlvariant_bytea(sv, DATETIMEOFFSET_T, -1, coll));

	PG_RETURN_DATETIMEOFFSET(result);
}

Datum
sqlvariant2date(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	DateADT		result;

	result = DatumGetDateADT(gen_type_datum_from_sqlvariant_bytea(sv, DATE_T, -1, coll));

	PG_RETURN_DATEADT(result);
}

Datum
sqlvariant2time(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	TimeADT		result;

	result = DatumGetTimeADT(gen_type_datum_from_sqlvariant_bytea(sv, TIME_T, -1, coll));

	PG_RETURN_TIMEADT(result);
}

Datum
sqlvariant2float(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	double		result;

	result = DatumGetFloat8(gen_type_datum_from_sqlvariant_bytea(sv, FLOAT_T, -1, coll));

	PG_RETURN_FLOAT8(result);
}

Datum
sqlvariant2real(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	float		result;

	result = DatumGetFloat4(gen_type_datum_from_sqlvariant_bytea(sv, REAL_T, -1, coll));

	PG_RETURN_FLOAT4(result);
}

Datum
sqlvariant2numeric(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	Numeric		result;

	result = DatumGetNumeric(gen_type_datum_from_sqlvariant_bytea(sv, NUMERIC_T, -1, coll));

	PG_RETURN_NUMERIC(result);
}

Datum
sqlvariant2fixeddecimal(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	int64		result;

	result = DatumGetInt64(gen_type_datum_from_sqlvariant_bytea(sv, MONEY_T, -1, coll));

	PG_RETURN_INT64(result);
}

Datum
sqlvariant2bigint(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	int64		result;

	result = DatumGetInt64(gen_type_datum_from_sqlvariant_bytea(sv, BIGINT_T, -1, coll));

	PG_RETURN_INT64(result);
}

Datum
sqlvariant2int(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	int32		result;

	result = DatumGetInt32(gen_type_datum_from_sqlvariant_bytea(sv, INT_T, -1, coll));

	PG_RETURN_INT32(result);
}

Datum
sqlvariant2smallint(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	int16		result;

	result = DatumGetInt16(gen_type_datum_from_sqlvariant_bytea(sv, SMALLINT_T, -1, coll));

	PG_RETURN_INT16(result);
}

Datum
sqlvariant2bit(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	bool		result;

	result = DatumGetBool(gen_type_datum_from_sqlvariant_bytea(sv, BIT_T, -1, coll));

	PG_RETURN_BOOL(result);
}

Datum
sqlvariant2varchar(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	VarChar    *result;

	result = DatumGetVarCharP(gen_type_datum_from_sqlvariant_bytea(sv, VARCHAR_T, -1, coll));

	PG_RETURN_VARCHAR_P(result);
}

Datum
sqlvariant2char(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	BpChar	   *result;

	result = DatumGetBpCharP(gen_type_datum_from_sqlvariant_bytea(sv, CHAR_T, -1, coll));

	PG_RETURN_BPCHAR_P(result);
}

Datum
sqlvariant2bbfvarbinary(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	bytea	   *result;

	result = DatumGetByteaP(gen_type_datum_from_sqlvariant_bytea(sv, VARBINARY_T, -1, coll));

	PG_RETURN_BYTEA_P(result);
}

Datum
sqlvariant2bbfbinary(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	bytea	   *result;

	result = DatumGetByteaP(gen_type_datum_from_sqlvariant_bytea(sv, BINARY_T, -1, coll));

	PG_RETURN_BYTEA_P(result);
}

Datum
sqlvariant2uniqueidentifier(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	Oid			coll = PG_GET_COLLATION();
	pg_uuid_t  *result;

	result = DatumGetUUIDP(gen_type_datum_from_sqlvariant_bytea(sv, UNIQUEIDENTIFIER_T, -1, coll));

	PG_RETURN_UUID_P(result);
}

/*
 * SQL_VARIANT_PROPERTY
 */

PG_FUNCTION_INFO_V1(sql_variant_property);
typedef enum sv_property
{
	SV_PROPERTY_BASETYPE,
	SV_PROPERTY_PRECISION,
	SV_PROPERTY_SCALE,
	SV_PROPERTY_TOTALBYTES,
	SV_PROPERTY_COLLATION,
	SV_PROPERTY_MAXLENGTH,
	SV_PROPERTY_INVALID
} sv_property_t;

static sv_property_t get_property_type(const char *arg, int len);
static Datum get_base_type(bytea *sv_value);
static Datum get_precision(bytea *sv_value);
static Datum get_scale(bytea *sv_value);
static Datum get_total_bytes(bytea *sv_value);
static Datum get_max_length(bytea *sv_value);

sv_property_t
get_property_type(const char *arg, int len)
{
	/* Incase sensitive match, No prefix/suffix spaces handling */
	if (pg_strncasecmp(arg, "basetype", len) == 0)
		return SV_PROPERTY_BASETYPE;
	else if (pg_strncasecmp(arg, "precision", len) == 0)
		return SV_PROPERTY_PRECISION;
	else if (pg_strncasecmp(arg, "scale", len) == 0)
		return SV_PROPERTY_SCALE;
	else if (pg_strncasecmp(arg, "totalbytes", len) == 0)
		return SV_PROPERTY_TOTALBYTES;
	else if (pg_strncasecmp(arg, "collation", len) == 0)
		return SV_PROPERTY_COLLATION;
	else if (pg_strncasecmp(arg, "maxlength", len) == 0)
		return SV_PROPERTY_MAXLENGTH;
	else
		return SV_PROPERTY_INVALID;
}

Datum
get_base_type(bytea *sv_value)
{
	uint8_t		type_code = SV_GET_TYPCODE_PTR(sv_value);
	const char *type_name = get_tsql_type_info(type_code).tsql_typname;

	return get_varchar128_sv_datum(type_name);
}

Datum
get_precision(bytea *sv_value)
{
	uint8_t		type_code = SV_GET_TYPCODE_PTR(sv_value);
	uint8_t		svhdr_size = get_tsql_type_info(type_code).svhdr_size;
	int16_t		typmod;
	int			precision;
	svhdr_2B_t *svhdr_2b;
	svhdr_3B_t *svhdr_3b;
	svhdr_5B_t *svhdr_5b;

	switch (svhdr_size)
	{
		case 2:
			svhdr_2b = SV_HDR_2B(sv_value);
			typmod = svhdr_2b->typmod;
			break;
		case 3:
			svhdr_3b = SV_HDR_3B(sv_value);
			typmod = svhdr_3b->typmod;
			break;
		case 5:
			svhdr_5b = SV_HDR_5B(sv_value);
			typmod = svhdr_5b->typmod;
			break;
		default:
			typmod = 0;
	}


	switch (type_code)
	{
		case DATETIME2_T:
			if (typmod == -1)
				precision = 27;
			else if (typmod == 0)
				precision = 19;
			else
				precision = typmod + 20;
			break;
		case DATETIMEOFFSET_T:
			if (typmod == -1)
				precision = 34;
			else if (typmod == 0)
				precision = 26;
			else
				precision = typmod + 27;
			break;
		case DATETIME_T:
			precision = 23;
			break;
		case SMALLDATETIME_T:
			precision = 16;
			break;
		case DATE_T:
			precision = 10;
			break;
		case TIME_T:
			if (typmod == -1)
				precision = 16;
			else if (typmod == 0)
				precision = 8;
			else
				precision = typmod + 9;
			break;
		case FLOAT_T:
			precision = 53;
			break;
		case REAL_T:
			precision = 24;
			break;
		case NUMERIC_T:
			if (typmod == -1)
				precision = 18;
			else
				precision = (typmod >> 8) & 0xFF;
			break;
			break;
		case MONEY_T:
			precision = 19;
			break;
		case SMALLMONEY_T:
			precision = 10;
			break;
		case BIGINT_T:
			precision = 19;
			break;
		case INT_T:
			precision = 10;
			break;
		case SMALLINT_T:
			precision = 5;
			break;
		case TINYINT_T:
			precision = 3;
			break;
		case BIT_T:
			precision = 1;
			break;
		case NVARCHAR_T:
		case NCHAR_T:
		case VARCHAR_T:
		case CHAR_T:
		case VARBINARY_T:
		case BINARY_T:
		case UNIQUEIDENTIFIER_T:
			precision = 0;
			break;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Unknown Internal data type code %d", type_code)));
	}

	return get_int_sv_datum(precision);
}

Datum
get_scale(bytea *sv_value)
{
	uint8_t		type_code = SV_GET_TYPCODE_PTR(sv_value);
	uint8_t		svhdr_size = get_tsql_type_info(type_code).svhdr_size;
	int16_t		typmod;
	int			scale;
	svhdr_2B_t *svhdr_2b;
	svhdr_3B_t *svhdr_3b;
	svhdr_5B_t *svhdr_5b;

	switch (svhdr_size)
	{
		case 2:
			svhdr_2b = SV_HDR_2B(sv_value);
			typmod = svhdr_2b->typmod;
			break;
		case 3:
			svhdr_3b = SV_HDR_3B(sv_value);
			typmod = svhdr_3b->typmod;
			break;
		case 5:
			svhdr_5b = SV_HDR_5B(sv_value);
			typmod = svhdr_5b->typmod;
			break;
		default:
			typmod = 0;
	}


	switch (type_code)
	{
		case DATETIME2_T:
			if (typmod == -1)
				scale = 7;
			else
				scale = typmod;
			break;
		case DATETIMEOFFSET_T:
			if (typmod == -1)
				scale = 7;
			else
				scale = typmod;
			break;
		case DATETIME_T:
			scale = 3;
			break;
		case SMALLDATETIME_T:
		case DATE_T:
			scale = 0;
			break;
		case TIME_T:
			if (typmod == -1)
				scale = 7;
			else
				scale = typmod;
			break;
		case FLOAT_T:
		case REAL_T:
			scale = 0;
			break;
		case NUMERIC_T:
			if (typmod == -1)
				scale = 0;
			else
				scale = typmod & 0xFF;
			break;
		case MONEY_T:
			scale = 4;
			break;
		case SMALLMONEY_T:
			scale = 4;
			break;
		case BIGINT_T:
		case INT_T:
		case SMALLINT_T:
		case TINYINT_T:
		case BIT_T:
		case NVARCHAR_T:
		case NCHAR_T:
		case VARCHAR_T:
		case CHAR_T:
		case VARBINARY_T:
		case BINARY_T:
		case UNIQUEIDENTIFIER_T:
			scale = 0;
			break;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Unknown Internal data type code %d", type_code)));
	}

	return get_int_sv_datum(scale);
}

Datum
get_total_bytes(bytea *sv_value)
{
	return get_int_sv_datum(VARSIZE_ANY(sv_value));
}

Datum
get_max_length(bytea *sv_value)
{
	uint8_t		type_code = SV_GET_TYPCODE_PTR(sv_value);
	int			max_len;

	switch (type_code)
	{
		case DATETIME2_T:
			max_len = 8;
			break;
		case DATETIMEOFFSET_T:
			max_len = 10;
			break;
		case DATETIME_T:
			max_len = 8;
			break;
		case SMALLDATETIME_T:
			max_len = 8;
			break;
		case DATE_T:
			max_len = 4;
			break;
		case TIME_T:
			max_len = 8;
			break;
		case FLOAT_T:
			max_len = 8;
			break;
		case REAL_T:
			max_len = 4;
			break;
		case NUMERIC_T:
			max_len = 65535;
			break;
		case MONEY_T:
			max_len = 8;
			break;
		case SMALLMONEY_T:
			max_len = 8;
			break;
		case BIGINT_T:
			max_len = 8;
			break;
		case INT_T:
			max_len = 4;
			break;
		case SMALLINT_T:
			max_len = 2;
			break;
		case TINYINT_T:
			max_len = 2;
			break;
		case BIT_T:
			max_len = 1;
			break;
		case NVARCHAR_T:
		case NCHAR_T:
		case VARCHAR_T:
		case CHAR_T:
		case VARBINARY_T:
		case BINARY_T:
			max_len = 65535;
			break;
		case UNIQUEIDENTIFIER_T:
			max_len = 16;
			break;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("Unknown Internal data type code %d", type_code)));

	}

	return get_int_sv_datum(max_len);
}

Datum
sql_variant_property(PG_FUNCTION_ARGS)
{
	bytea	   *sv_value = PG_GETARG_BYTEA_PP(0);
	int			prop_len = VARSIZE_ANY_EXHDR(PG_GETARG_BYTEA_PP(1));
	const char *prop_str = VARDATA_ANY(PG_GETARG_BYTEA_PP(1));
	sv_property_t prop_type;

	/* CHECK Validity of Property */
	prop_type = get_property_type(prop_str, prop_len);
	if (prop_type == SV_PROPERTY_INVALID)
		PG_RETURN_NULL();

	/* Dispatch to property functions */
	switch (prop_type)
	{
		case SV_PROPERTY_BASETYPE:
			return get_base_type(sv_value);
		case SV_PROPERTY_PRECISION:
			return get_precision(sv_value);
		case SV_PROPERTY_SCALE:
			return get_scale(sv_value);
		case SV_PROPERTY_TOTALBYTES:
			return get_total_bytes(sv_value);
		case SV_PROPERTY_COLLATION:
			{
				uint8_t		type_code = SV_GET_TYPCODE_PTR(sv_value);

				switch (type_code)
				{
					case NVARCHAR_T:
					case NCHAR_T:
					case VARCHAR_T:
					case CHAR_T:
						{
							svhdr_5B_t *svhdr_5b = SV_HDR_5B(sv_value);
							Oid			coll_oid = get_tsql_collation_oid(svhdr_5b->collid);
							char	   *collname;

							collname = get_collation_name(coll_oid);
							return get_varchar128_sv_datum(collname);
						}
					default:
						break;
				}
				PG_RETURN_NULL();
			}
		case SV_PROPERTY_MAXLENGTH:
			return get_max_length(sv_value);
		default:
			break;
	}
	PG_RETURN_NULL();			/* SHOULD NOT HAPPEN */
}

/*
 *  Comparision functions
 */

PG_FUNCTION_INFO_V1(sqlvarianteq);
PG_FUNCTION_INFO_V1(sqlvariantne);
PG_FUNCTION_INFO_V1(sqlvariantlt);
PG_FUNCTION_INFO_V1(sqlvariantle);
PG_FUNCTION_INFO_V1(sqlvariantgt);
PG_FUNCTION_INFO_V1(sqlvariantge);

Datum
sqlvariantlt(PG_FUNCTION_ARGS)
{
	bytea	   *arg1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *arg2 = PG_GETARG_BYTEA_PP(1);
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	uint8_t		type_family1 = get_tsql_type_info(type_code1).family_prio;
	uint8_t		type_family2 = get_tsql_type_info(type_code2).family_prio;
	char	   *oprname = "<";
	Datum		result;

	if (type_family1 == type_family2)
		result = do_compare(oprname, arg1, arg2, PG_GET_COLLATION());
	else						/* based on type family precedence */
		result = BoolGetDatum(type_family1 > type_family2);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	return result;
}

Datum
sqlvariantle(PG_FUNCTION_ARGS)
{
	bytea	   *arg1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *arg2 = PG_GETARG_BYTEA_PP(1);
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	uint8_t		type_family1 = get_tsql_type_info(type_code1).family_prio;
	uint8_t		type_family2 = get_tsql_type_info(type_code2).family_prio;
	char	   *oprname = "<=";
	Datum		result;

	if (type_family1 == type_family2)
		result = do_compare(oprname, arg1, arg2, PG_GET_COLLATION());
	else						/* based on type family precedence */
		result = BoolGetDatum(type_family1 > type_family2);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	return result;
}

Datum
sqlvarianteq(PG_FUNCTION_ARGS)
{
	bytea	   *arg1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *arg2 = PG_GETARG_BYTEA_PP(1);
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	uint8_t		type_family1 = get_tsql_type_info(type_code1).family_prio;
	uint8_t		type_family2 = get_tsql_type_info(type_code2).family_prio;
	char	   *oprname = "=";
	Datum		result;

	if (type_family1 == type_family2)
		result = do_compare(oprname, arg1, arg2, PG_GET_COLLATION());
	else						/* based on type family precedence */
		result = BoolGetDatum(false);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	return result;
}

Datum
sqlvariantge(PG_FUNCTION_ARGS)
{
	bytea	   *arg1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *arg2 = PG_GETARG_BYTEA_PP(1);
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	uint8_t		type_family1 = get_tsql_type_info(type_code1).family_prio;
	uint8_t		type_family2 = get_tsql_type_info(type_code2).family_prio;
	char	   *oprname = ">=";
	Datum		result;

	if (type_family1 == type_family2)
		result = do_compare(oprname, arg1, arg2, PG_GET_COLLATION());
	else						/* based on type family precedence */
		result = BoolGetDatum(type_family1 < type_family2);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	return result;
}

Datum
sqlvariantgt(PG_FUNCTION_ARGS)
{
	bytea	   *arg1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *arg2 = PG_GETARG_BYTEA_PP(1);
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	uint8_t		type_family1 = get_tsql_type_info(type_code1).family_prio;
	uint8_t		type_family2 = get_tsql_type_info(type_code2).family_prio;
	char	   *oprname = ">";
	Datum		result;

	if (type_family1 == type_family2)
		result = do_compare(oprname, arg1, arg2, PG_GET_COLLATION());
	else						/* based on type family precedence */
		result = BoolGetDatum(type_family1 < type_family2);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	return result;
}

Datum
sqlvariantne(PG_FUNCTION_ARGS)
{
	bytea	   *arg1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *arg2 = PG_GETARG_BYTEA_PP(1);
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	uint8_t		type_family1 = get_tsql_type_info(type_code1).family_prio;
	uint8_t		type_family2 = get_tsql_type_info(type_code2).family_prio;
	char	   *oprname = "<>";
	Datum		result;

	if (type_family1 == type_family2)
		result = do_compare(oprname, arg1, arg2, PG_GET_COLLATION());
	else						/* based on type family precedence */
		result = BoolGetDatum(true);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	return result;
}

/*
 * Index Supporting Functions
 */

PG_FUNCTION_INFO_V1(sqlvariant_cmp);
PG_FUNCTION_INFO_V1(sqlvariant_hash);

Datum
sqlvariant_cmp(PG_FUNCTION_ARGS)
{
	bytea	   *arg1 = PG_GETARG_BYTEA_PP(0);
	bytea	   *arg2 = PG_GETARG_BYTEA_PP(1);
	uint8_t		type_code1 = SV_GET_TYPCODE_PTR(arg1);
	uint8_t		type_code2 = SV_GET_TYPCODE_PTR(arg2);
	uint8_t		type_family1 = get_tsql_type_info(type_code1).family_prio;
	uint8_t		type_family2 = get_tsql_type_info(type_code2).family_prio;
	Datum		result;

	if (type_family1 == type_family2)
	{
		char	   *opeq = "=";
		char	   *oplt = "<";
		Datum		is_eq;
		Datum		is_lt;

		is_lt = do_compare(oplt, arg1, arg2, PG_GET_COLLATION());
		if (DatumGetBool(is_lt))
			result = Int32GetDatum(-1);
		else
		{
			is_eq = do_compare(opeq, arg1, arg2, PG_GET_COLLATION());
			result = DatumGetBool(is_eq) ? Int32GetDatum(0) : Int32GetDatum(1);
		}
	}
	else
		result = (type_family1 > type_family2) ? Int32GetDatum(-1) : Int32GetDatum(1);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(arg1, 0);
	PG_FREE_IF_COPY(arg2, 1);

	return result;
}

Datum
sqlvariant_hash(PG_FUNCTION_ARGS)
{
	bytea	   *key = PG_GETARG_BYTEA_PP(0);
	int			keylen = VARSIZE_ANY_EXHDR(key);
	int			hdrlen = VARSIZE_ANY(key) - keylen;
	Datum		result;

	/*
	 * Exclude varlena header for computation Size of varlena header could be
	 * 1 or 4 bytes, Newly created values usually have 4 bytes However, values
	 * read from storage have 1 bytes if total length is short
	 */
	result = hash_any((unsigned char *) key + hdrlen, keylen);

	/* Avoid leaking memory for toasted inputs */
	PG_FREE_IF_COPY(key, 0);

	return result;
}


/*
 * DATALENGTH function for SQL_VARIANT
 */

PG_FUNCTION_INFO_V1(datalength_sqlvariant);

Datum
datalength_sqlvariant(PG_FUNCTION_ARGS)
{
	bytea	   *sv = PG_GETARG_BYTEA_PP(0);
	uint8_t		type_code = SV_GET_TYPCODE_PTR(sv);
	uint8_t		svhdr_size = get_tsql_type_info(type_code).svhdr_size;
	int32		octet_len = VARSIZE_ANY_EXHDR(sv) - svhdr_size;

	/* For varlen types, exclude the original varlena header */
	if (IS_STRING_TYPE(type_code) || IS_BINARY_TYPE(type_code) || type_code == NUMERIC_T)
		octet_len -= VARHDRSZ;

	PG_RETURN_INT32(octet_len);
}

/*
 * TDS side code support on sql variant
 */
/*
 * Retrieve PGbaseType code, dataLen, variable header length
 * for each base datatype on sql variant
 */
void
TdsGetPGbaseType(uint8 variantBaseType, int *pgBaseType, int tempLen,
				 int *dataLen, int *variantHeaderLen)
{
	switch (variantBaseType)
	{
		case VARIANT_TYPE_BIT:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = BIT_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_TINYINT:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = TINYINT_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_SMALLINT:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = SMALLINT_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_INT:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = INT_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_BIGINT:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = BIGINT_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_REAL:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = REAL_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_FLOAT:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = FLOAT_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_CHAR:

			/*
			 * dataformat: totalLen(4B) + metadata(9B)( baseType(1B) +
			 * metadatalen(1B) + encodingLen(5B) + dataLen(2B) ) +
			 * data(dataLen)
			 */
			*pgBaseType = CHAR_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES;
			break;
		case VARIANT_TYPE_NCHAR:
			*pgBaseType = NCHAR_T;

			/*
			 * dataformat: totalLen(4B) + metadata(9B)( baseType(1B) +
			 * metadatalen(1B) + encodingLen(5B) + dataLen(2B) ) +
			 * data(dataLen) Data is in UTF16 format.
			 */
			*dataLen = (tempLen - VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES) / 2;
			break;
		case VARIANT_TYPE_VARCHAR:

			/*
			 * dataformat: totalLen(4B) + metadata(9B)( baseType(1B) +
			 * metadatalen(1B) + encodingLen(5B) + dataLen(2B) ) +
			 * data(dataLen)
			 */
			*pgBaseType = VARCHAR_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES;
			break;
		case VARIANT_TYPE_NVARCHAR:
			*pgBaseType = NVARCHAR_T;

			/*
			 * dataformat: totalLen(4B) + metadata(9B)( baseType(1B) +
			 * metadatalen(1B) + encodingLen(5B) + dataLen(2B) ) +
			 * data(dataLen) Data is in UTF16 format.
			 */
			*dataLen = (tempLen - VARIANT_TYPE_METALEN_FOR_CHAR_DATATYPES) / 2;
			break;
		case VARIANT_TYPE_BINARY:

			/*
			 * dataformat : totalLen(4B) + metadata(4B)( baseType(1B) +
			 * metadatalen(1B) + dataLen(2B) ) + data(dataLen)
			 */
			*pgBaseType = BINARY_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_BIN_DATATYPES;
			break;
		case VARIANT_TYPE_VARBINARY:

			/*
			 * dataformat : totalLen(4B) + metadata(4B)( baseType(1B) +
			 * metadatalen(1B) + dataLen(2B) ) + data(dataLen)
			 */
			*pgBaseType = VARBINARY_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_BIN_DATATYPES;
			break;
		case VARIANT_TYPE_DATE:

			/*
			 * dataformat : totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(3B)
			 */
			*pgBaseType = DATE_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_DATE;
			break;
		case VARIANT_TYPE_TIME:

			/*
			 * dataformat : totalLen(4B) + metadata(3B)( baseType(1B) +
			 * metadatalen(1B) + scale(1B) ) + data(3B-5B)
			 */
			*pgBaseType = TIME_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_TIME;
			break;
		case VARIANT_TYPE_SMALLDATETIME:

			/*
			 * dataformat : totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(4B)
			 */
			*pgBaseType = SMALLDATETIME_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_SMALLDATETIME;
			break;
		case VARIANT_TYPE_DATETIME:

			/*
			 * dataformat : totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(8B)
			 */
			*pgBaseType = DATETIME_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_DATETIME;
			break;
		case VARIANT_TYPE_DATETIME2:

			/*
			 * dataformat : totalLen(4B) + metadata(3B)( baseType(1B) +
			 * metadatalen(1B) + scale(1B) ) + data(6B-8B)
			 */
			*pgBaseType = DATETIME2_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_DATETIME2;
			break;
		case VARIANT_TYPE_UNIQUEIDENTIFIER:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = UNIQUEIDENTIFIER_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_NUMERIC:
		case VARIANT_TYPE_DECIMAL:

			/*
			 * dataformat : totalLen(4B) + metdata(5B)( baseType(1B) +
			 * metadatalen(1B) + precision(1B) + scale(1B) + sign(1B) ) +
			 * data(dataLen)
			 */
			*pgBaseType = NUMERIC_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUMERIC_DATATYPES;
			break;
		case VARIANT_TYPE_MONEY:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = MONEY_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_SMALLMONEY:

			/*
			 * dataformat: totalLen(4B) + metadata(2B)( baseType(1B) +
			 * metadatalen(1B) ) + data(dataLen)
			 */
			*pgBaseType = SMALLMONEY_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_NUM_DATATYPES;
			break;
		case VARIANT_TYPE_DATETIMEOFFSET:

			/*
			 * dataformat : totalLen(4B) + metadata(3B)(baseType(1B) +
			 * metadatalen(1B) + scale(1B)) + data(8B-10B)
			 */
			*pgBaseType = DATETIMEOFFSET_T;
			*dataLen = tempLen - VARIANT_TYPE_METALEN_FOR_DATETIMEOFFSET;
			break;
		default:
			elog(ERROR, "0x%02X : datatype as basetype for SQL_VARIANT is not supported", variantBaseType);
			break;
	}

	*variantHeaderLen = get_tsql_type_info(*pgBaseType).svhdr_size;
}


/*
 * set metadata on sqlvariant header for variable length datatypes
 */
void
TdsSetMetaData(bytea *result, int pgBaseType, int scale,
			   int precision, int maxLen)
{
	if (pgBaseType == TIME_T || pgBaseType == DATETIME2_T ||
		pgBaseType == DATETIMEOFFSET_T)
	{
		/* For datatypes having sql_variant specific header of length 2 bytes */
		svhdr_2B_t *svhdr2;

		svhdr2 = SV_HDR_2B(result);
		SV_SET_METADATA(svhdr2, pgBaseType, HDR_VER);
		svhdr2->typmod = scale;
	}
	else if (pgBaseType == NUMERIC_T)
	{
		/* For datatypes having sql_variant specific header of length 3 bytes */
		svhdr_3B_t *svhdr3;

		svhdr3 = SV_HDR_3B(result);
		SV_SET_METADATA(svhdr3, pgBaseType, HDR_VER);
		svhdr3->typmod = (precision << 8) | scale;
	}
	else if (pgBaseType == BINARY_T || pgBaseType == VARBINARY_T ||
			 pgBaseType == CHAR_T || pgBaseType == NCHAR_T ||
			 pgBaseType == VARCHAR_T || pgBaseType == NVARCHAR_T)
	{
		/* For datatypes having sql_variant specific header of length 5 bytes */
		svhdr_5B_t *svhdr5;

		svhdr5 = SV_HDR_5B(result);
		SV_SET_METADATA(svhdr5, pgBaseType, HDR_VER);
		svhdr5->typmod = (int16) maxLen;
	}
	else
	{
		/* For all other fixed-length datatypes */
		svhdr_2B_t *svhdr2;

		svhdr2 = SV_HDR_2B(result);
		SV_SET_METADATA(svhdr2, pgBaseType, HDR_VER);
	}
}

int
TdsPGbaseType(bytea *vlena)
{
	/*
	 * First sql variant header byte contains: type code ( 5bit ) + MD ver
	 * (3bit)
	 */
	return SV_GET_TYPCODE_PTR(vlena);
}

void
TdsGetMetaData(bytea *result, int pgBaseType, int *scale,
			   int *precision, int *maxLen)
{
	svhdr_5B_t *svhdr;

	svhdr = SV_HDR_5B(result);

	if (pgBaseType == TIME_T || pgBaseType == DATETIME2_T ||
		pgBaseType == DATETIMEOFFSET_T)
	{
		*scale = svhdr->typmod;
	}
	else if (pgBaseType == NUMERIC_T)
	{
		*scale = svhdr->typmod & 0x00ff;
		*precision = (svhdr->typmod & 0xff00) >> 8;
	}
	else if (pgBaseType == BINARY_T || pgBaseType == VARBINARY_T ||
			 pgBaseType == CHAR_T || pgBaseType == NCHAR_T ||
			 pgBaseType == VARCHAR_T || pgBaseType == NVARCHAR_T)
	{
		*maxLen = (int) svhdr->typmod;
	}
}

void
TdsGetVariantBaseType(int pgBaseType, int *variantBaseType,
					  bool *isBaseNum, bool *isBaseChar,
					  bool *isBaseDec, bool *isBaseBin,
					  bool *isBaseDate, int *variantHeaderLen)
{
	switch (pgBaseType)
	{
		case BIT_T:
			*variantBaseType = VARIANT_TYPE_BIT;
			*isBaseNum = true;
			break;
		case BIGINT_T:
			*variantBaseType = VARIANT_TYPE_BIGINT;
			*isBaseNum = true;
			break;
		case INT_T:
			*variantBaseType = VARIANT_TYPE_INT;
			*isBaseNum = true;
			break;
		case SMALLINT_T:
			*variantBaseType = VARIANT_TYPE_SMALLINT;
			*isBaseNum = true;
			break;
		case TINYINT_T:
			*variantBaseType = VARIANT_TYPE_TINYINT;
			*isBaseNum = true;
			break;
		case REAL_T:
			*variantBaseType = VARIANT_TYPE_REAL;
			*isBaseNum = true;
			break;
		case FLOAT_T:
			*variantBaseType = VARIANT_TYPE_FLOAT;
			*isBaseNum = true;
			break;
		case MONEY_T:
			*variantBaseType = VARIANT_TYPE_MONEY;
			*isBaseNum = true;
			break;
		case SMALLMONEY_T:
			*variantBaseType = VARIANT_TYPE_SMALLMONEY;
			*isBaseNum = true;
			break;
		case DATE_T:
			*variantBaseType = VARIANT_TYPE_DATE;
			*isBaseDate = true;
			break;
		case SMALLDATETIME_T:
			*variantBaseType = VARIANT_TYPE_SMALLDATETIME;
			*isBaseDate = true;
			break;
		case DATETIME_T:
			*variantBaseType = VARIANT_TYPE_DATETIME;
			*isBaseDate = true;
			break;
		case TIME_T:
			*variantBaseType = VARIANT_TYPE_TIME;
			*isBaseDate = true;
			break;
		case DATETIME2_T:
			*variantBaseType = VARIANT_TYPE_DATETIME2;
			*isBaseDate = true;
			break;
		case DATETIMEOFFSET_T:
			*variantBaseType = VARIANT_TYPE_DATETIMEOFFSET;
			*isBaseDate = true;
			break;
		case CHAR_T:
			*variantBaseType = VARIANT_TYPE_CHAR;
			*isBaseChar = true;
			break;
		case VARCHAR_T:
			*variantBaseType = VARIANT_TYPE_VARCHAR;
			*isBaseChar = true;
			break;
		case NCHAR_T:
			*variantBaseType = VARIANT_TYPE_NCHAR;
			*isBaseChar = true;
			break;
		case NVARCHAR_T:
			*variantBaseType = VARIANT_TYPE_NVARCHAR;
			*isBaseChar = true;
			break;
		case BINARY_T:
			*variantBaseType = VARIANT_TYPE_BINARY;
			*isBaseBin = true;
			break;
		case VARBINARY_T:
			*variantBaseType = VARIANT_TYPE_VARBINARY;
			*isBaseBin = true;
			break;
		case UNIQUEIDENTIFIER_T:
			*variantBaseType = VARIANT_TYPE_UNIQUEIDENTIFIER;
			*isBaseNum = true;
			break;
		case NUMERIC_T:
			*variantBaseType = VARIANT_TYPE_NUMERIC;
			*isBaseDec = true;
			break;
		default:
			elog(ERROR, "%d: datatype not supported in TDS sender", pgBaseType);
			break;
	}

	*variantHeaderLen = get_tsql_type_info(pgBaseType).svhdr_size;
}

bytea *
convertIntToSQLVariantByteA(int ret)
{
	Datum		data = Int64GetDatum(ret);
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(INT_T, data);
	svhdr_1B_t *svhdr;

	INSTR_METRIC_INC(INSTR_TSQL_INT_SQLVARIANT);

	/* Type Specific Header */
	svhdr = SV_HDR_1B(result);
	SV_SET_METADATA(svhdr, INT_T, HDR_VER);

	return result;
}

bytea *
convertVarcharToSQLVariantByteA(VarChar *vch, Oid coll)
{
	bytea	   *result = gen_sqlvariant_bytea_from_type_datum(NVARCHAR_T, PointerGetDatum(vch));
	svhdr_5B_t *svhdr;

	INSTR_METRIC_INC(INSTR_TSQL_NVARCHAR_SQLVARIANT);

	/* Type Specific Header */
	svhdr = SV_HDR_5B(result);
	SV_SET_METADATA(svhdr, NVARCHAR_T, HDR_VER);
	svhdr->typmod = VARSIZE_ANY_EXHDR(vch);
	svhdr->collid = get_persist_collation_id(coll);

	return result;
}
