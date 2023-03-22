/*-------------------------------------------------------------------------
 *
 * pltsql_coerce.c
 *   Datatype Coercion Utility for Babel
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/htup_details.h"
#include "access/parallel.h"	/* InitializingParallelWorker */
#include "miscadmin.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_cast.h"
#include "catalog/pg_type.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_namespace.h"
#include "executor/spi.h"
#include "mb/pg_wchar.h"
#include "parser/parse_coerce.h"
#include "parser/parse_func.h"
#include "utils/builtins.h"
#include "utils/float.h"
#include "utils/guc.h"
#include "common/int.h"
#include "utils/int8.h"
#include "utils/numeric.h"
#include "utils/memutils.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"


#include <math.h>

/*
 * Additional Casting Functions for T-SQL
 *
 * Some castings in T-SQL has different behavior with PG.
 * (i.e. real datatype to integral type - PG uses round but T-SQL uses trunc)
 */

/*  dtrunc in float.c */
inline static float8
dtrunc_(float8 arg1)
{
	float8		result;

	if (arg1 >= 0)
		result = floor(arg1);
	else
		result = -floor(-arg1);

	return result;
}

inline static float4
ftrunc_(float4 arg1)
{
	float8		result;

	if (arg1 >= 0)
		result = floor(arg1);
	else
		result = -floor(-arg1);

	return result;
}

/* dtrunci8(X) = dtoi8(dtrunc(X)) */
PG_FUNCTION_INFO_V1(dtrunci8);

Datum
dtrunci8(PG_FUNCTION_ARGS)
{
	float8		num = PG_GETARG_FLOAT8(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(dtrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT8_FITS_IN_INT64(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT64((int64) num);
}


/* dtrunci4(X) = dtoi4(dtrunc(X)) */
PG_FUNCTION_INFO_V1(dtrunci4);

Datum
dtrunci4(PG_FUNCTION_ARGS)
{
	float8		num = PG_GETARG_FLOAT8(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(dtrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT8_FITS_IN_INT32(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT32((int32) num);
}


/* dtrunci2(X) = dtoi2(dtrunc(X)) */
PG_FUNCTION_INFO_V1(dtrunci2);

Datum
dtrunci2(PG_FUNCTION_ARGS)
{
	float8		num = PG_GETARG_FLOAT8(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(dtrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT8_FITS_IN_INT16(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("smallint out of range")));

	PG_RETURN_INT16((int16) num);
}


/* ftrunci8(X) = ftoi8(ftrunc(X)) */
PG_FUNCTION_INFO_V1(ftrunci8);

Datum
ftrunci8(PG_FUNCTION_ARGS)
{
	float4		num = PG_GETARG_FLOAT4(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(ftrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT4_FITS_IN_INT64(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT64((int64) num);
}


/* ftrunci4(X) = ftoi4(ftrunc(X)) */
PG_FUNCTION_INFO_V1(ftrunci4);

Datum
ftrunci4(PG_FUNCTION_ARGS)
{
	float4		num = PG_GETARG_FLOAT4(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(ftrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT4_FITS_IN_INT32(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT32((int32) num);
}


/* ftrunci2(X) = ftoi2(ftrunc(X)) */
PG_FUNCTION_INFO_V1(ftrunci2);

Datum
ftrunci2(PG_FUNCTION_ARGS)
{
	float4		num = PG_GETARG_FLOAT4(0);

	/*
	 * Get rid of any fractional part in the input.  This is so we don't fail
	 * on just-out-of-range values that would round into range.  Note
	 * assumption that rint() will pass through a NaN or Inf unchanged.
	 */
	num = rint(ftrunc_(num));

	/* Range check */
	if (unlikely(isnan(num) || !FLOAT4_FITS_IN_INT16(num)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("integer out of range")));

	PG_RETURN_INT16((int16) num);
}



PG_FUNCTION_INFO_V1(pltsql_text_name);
PG_FUNCTION_INFO_V1(pltsql_bpchar_name);

/* replace text_name() to handle t-sql identifier truncation */
Datum
pltsql_text_name(PG_FUNCTION_ARGS)
{
	text	   *s = PG_GETARG_TEXT_PP(0);
	Name		result;
	int			len;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	len = VARSIZE_ANY_EXHDR(s);

	/* Truncate oversize input */
	if (len >= NAMEDATALEN)
	{
		if (cstr_to_name_hook)	/* to apply special truncation logic */
		{
			Name		n;

			PG_TRY();
			{
				/* T-SQL casting. follow T-SQL truncation rule */
				set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				n = (*cstr_to_name_hook) (VARDATA_ANY(s), len);
			}
			PG_CATCH();
			{
				set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				PG_RE_THROW();
			}
			PG_END_TRY();
			set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
							  (superuser() ? PGC_SUSET : PGC_USERSET),
							  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

			PG_RETURN_NAME(n);
		}

		len = pg_mbcliplen(VARDATA_ANY(s), len, NAMEDATALEN - 1);
	}

	/* We use palloc0 here to ensure result is zero-padded */
	result = (Name) palloc0(NAMEDATALEN);
	memcpy(NameStr(*result), VARDATA_ANY(s), len);

	PG_RETURN_NAME(result);
}

/* replace bpchar_name() to handle t-sql identifier truncation */
Datum
pltsql_bpchar_name(PG_FUNCTION_ARGS)
{
	BpChar	   *s = PG_GETARG_BPCHAR_PP(0);
	char	   *s_data;
	Name		result;
	int			len;
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	len = VARSIZE_ANY_EXHDR(s);
	s_data = VARDATA_ANY(s);

	/* Truncate oversize input */
	if (len >= NAMEDATALEN)
	{
		if (cstr_to_name_hook)	/* to apply special truncation logic */
		{
			Name		n;

			/* Remove trailing blanks */
			while (len > 0)
			{
				if (s_data[len - 1] != ' ')
					break;
				len--;
			}

			PG_TRY();
			{
				/* T-SQL casting. follow T-SQL truncation rule */
				set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				n = (*cstr_to_name_hook) (VARDATA_ANY(s), len);
			}
			PG_CATCH();
			{
				set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
								  (superuser() ? PGC_SUSET : PGC_USERSET),
								  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
				PG_RE_THROW();
			}
			PG_END_TRY();
			set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
							  (superuser() ? PGC_SUSET : PGC_USERSET),
							  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

			PG_RETURN_NAME(n);
		}

		len = pg_mbcliplen(s_data, len, NAMEDATALEN - 1);
	}

	/* Remove trailing blanks */
	while (len > 0)
	{
		if (s_data[len - 1] != ' ')
			break;
		len--;
	}

	/* We use palloc0 here to ensure result is zero-padded */
	result = (Name) palloc0(NAMEDATALEN);
	memcpy(NameStr(*result), s_data, len);

	PG_RETURN_NAME(result);
}
