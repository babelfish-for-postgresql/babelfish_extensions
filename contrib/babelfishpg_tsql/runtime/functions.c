#include "postgres.h"
#include "port.h"
#include "funcapi.h"
#include "pgstat.h"

#include "access/detoast.h"
#include "access/htup_details.h"
#include "access/table.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_database.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_type.h"
#include "commands/dbcommands.h"
#include "common/md5.h"
#include "miscadmin.h"
#include "parser/scansup.h"
#include "tsearch/ts_locale.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/numeric.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "utils/queryenvironment.h"
#include "utils/float.h"
#include "utils/xid8.h"
#include <math.h>

#include "../src/babelfish_version.h"
#include "../src/datatype_info.h"
#include "../src/pltsql.h"
#include "../src/pltsql_instr.h"
#include "../src/multidb.h"
#include "../src/session.h"
#include "../src/catalog.h"
#include "../src/collation.h"
#include "../src/rolecmds.h"
#include "utils/fmgroids.h"
#include "utils/acl.h"
#include "access/table.h"
#include "access/genam.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_trigger.h"
#include "catalog/pg_constraint.h"

#define TSQL_STAT_GET_ACTIVITY_COLS 25
#define SP_DATATYPE_INFO_HELPER_COLS 23

PG_FUNCTION_INFO_V1(trancount);
PG_FUNCTION_INFO_V1(version);
PG_FUNCTION_INFO_V1(error);
PG_FUNCTION_INFO_V1(pgerror);
PG_FUNCTION_INFO_V1(datalength);
PG_FUNCTION_INFO_V1(int_floor);
PG_FUNCTION_INFO_V1(int_ceiling);
PG_FUNCTION_INFO_V1(bit_floor);
PG_FUNCTION_INFO_V1(bit_ceiling);
PG_FUNCTION_INFO_V1(servername);
PG_FUNCTION_INFO_V1(servicename);
PG_FUNCTION_INFO_V1(xact_state);
PG_FUNCTION_INFO_V1(get_enr_list);
PG_FUNCTION_INFO_V1(tsql_random);
PG_FUNCTION_INFO_V1(is_member);
PG_FUNCTION_INFO_V1(schema_id);
PG_FUNCTION_INFO_V1(schema_name);
PG_FUNCTION_INFO_V1(datefirst);
PG_FUNCTION_INFO_V1(options);
PG_FUNCTION_INFO_V1(default_domain);
PG_FUNCTION_INFO_V1(tsql_exp);
PG_FUNCTION_INFO_V1(host_os);
PG_FUNCTION_INFO_V1(tsql_stat_get_activity_deprecated_in_2_2_0);
PG_FUNCTION_INFO_V1(tsql_stat_get_activity);
PG_FUNCTION_INFO_V1(get_current_full_xact_id);
PG_FUNCTION_INFO_V1(checksum);
PG_FUNCTION_INFO_V1(has_dbaccess);
PG_FUNCTION_INFO_V1(object_id);
PG_FUNCTION_INFO_V1(object_name);
PG_FUNCTION_INFO_V1(sp_datatype_info_helper);
PG_FUNCTION_INFO_V1(language);
PG_FUNCTION_INFO_V1(host_name);
PG_FUNCTION_INFO_V1(procid);
PG_FUNCTION_INFO_V1(babelfish_integrity_checker);
PG_FUNCTION_INFO_V1(bigint_degrees);
PG_FUNCTION_INFO_V1(int_degrees);
PG_FUNCTION_INFO_V1(smallint_degrees);
PG_FUNCTION_INFO_V1(bigint_radians);
PG_FUNCTION_INFO_V1(int_radians);
PG_FUNCTION_INFO_V1(smallint_radians);
PG_FUNCTION_INFO_V1(bigint_power);
PG_FUNCTION_INFO_V1(int_power);
PG_FUNCTION_INFO_V1(smallint_power);
PG_FUNCTION_INFO_V1(numeric_degrees);
PG_FUNCTION_INFO_V1(numeric_radians);
PG_FUNCTION_INFO_V1(object_schema_name);

void	   *string_to_tsql_varchar(const char *input_str);
void	   *get_servername_internal(void);
void	   *get_servicename_internal(void);
void	   *get_language(void);
extern bool canCommitTransaction(void);

extern int	pltsql_datefirst;
extern bool pltsql_implicit_transactions;
extern bool pltsql_cursor_close_on_commit;
extern bool pltsql_ansi_warnings;
extern bool pltsql_ansi_padding;
extern bool pltsql_ansi_nulls;
extern bool pltsql_arithabort;
extern bool pltsql_arithignore;
extern bool pltsql_quoted_identifier;
extern bool pltsql_nocount;
extern bool pltsql_ansi_null_dflt_on;
extern bool pltsql_ansi_null_dflt_off;
extern bool pltsql_concat_null_yields_null;
extern bool pltsql_numeric_roundabort;
extern bool pltsql_xact_abort;
extern bool pltsql_case_insensitive_identifiers;
extern bool inited_ht_tsql_cast_info;
extern bool inited_ht_tsql_datatype_precedence_info;

char	   *bbf_servername = "BABELFISH";
const char *bbf_servicename = "MSSQLSERVER";
char	   *bbf_language = "us_english";
#define MD5_HASH_LEN 32

Datum
trancount(PG_FUNCTION_ARGS)
{
	PG_RETURN_UINT32(NestedTranCount);
}

Datum
procid(PG_FUNCTION_ARGS)
{
	PG_RETURN_OID(procid_var);
}

/*
 * This function will return following version string
 * Babelfish for PostgreSQL with SQL Server Compatibility - 12.0.2000.8
 * <Build Date> <Build Time>
 * Copyright (c) Amazon Web Services
 * PostgreSQL xx.xx on <host>
 */
Datum
version(PG_FUNCTION_ARGS)
{
	StringInfoData temp;
	void	   *info;
	const char *product_version;

	initStringInfo(&temp);

	if (pg_strcasecmp(pltsql_version, "default") == 0)
	{
		char	   *pg_version = pstrdup(PG_VERSION_STR);
		char	   *temp_str = pg_version;

		temp_str = strstr(temp_str, ", compiled by");
		*temp_str = '\0';
		product_version = GetConfigOption("babelfishpg_tds.product_version", true, false);

		Assert(product_version != NULL);
		if (pg_strcasecmp(product_version, "default") == 0)
			product_version = BABEL_COMPATIBILITY_VERSION;
		appendStringInfo(&temp,
						 "Babelfish for PostgreSQL with SQL Server Compatibility - %s"
						 "\n%s %s\nCopyright (c) Amazon Web Services\n%s (Babelfish %s)",
						 product_version,
						 __DATE__, __TIME__, pg_version, BABELFISH_VERSION_STR);
	}
	else
		appendStringInfoString(&temp, pltsql_version);

	/*
	 * TODO: Return Build number with version string as well.
	 */

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);
	pfree(temp.data);
	PG_RETURN_VARCHAR_P(info);
}

void *
string_to_tsql_varchar(const char *input_str)
{
	StringInfoData temp;
	void	   *info;

	initStringInfo(&temp);
	appendStringInfoString(&temp, input_str);

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);
	pfree(temp.data);
	return info;
}

void *
get_servername_internal()
{
	return string_to_tsql_varchar(bbf_servername);
}

void *
get_servicename_internal()
{
	return string_to_tsql_varchar(bbf_servicename);
}

void *
get_language()
{
	return string_to_tsql_varchar(bbf_language);
}

/*
 * This function will return the servername.
 */
Datum
servername(PG_FUNCTION_ARGS)
{
	PG_RETURN_VARCHAR_P(get_servername_internal());
}

/*
 * This function will return the servicename.
 */
Datum
servicename(PG_FUNCTION_ARGS)
{
	PG_RETURN_VARCHAR_P(get_servicename_internal());
}

Datum
error(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(latest_error_code);
}

Datum
pgerror(PG_FUNCTION_ARGS)
{
	char	   *error_sqlstate = unpack_sql_state(latest_pg_error_code);

	PG_RETURN_VARCHAR_P((*common_utility_plugin_ptr->tsql_varchar_input) ((error_sqlstate), strlen(error_sqlstate), -1));
}


/* returns data length of one Datum
 * this function is very similar to pg_column_size, but returns untoasted data without header sizes for bytea objects
*/
Datum
datalength(PG_FUNCTION_ARGS)
{
	Datum		value = PG_GETARG_DATUM(0);
	int32 result;
	int			typlen;

	/* On first call, get the input type's typlen, and save at *fn_extra */
	if (fcinfo->flinfo->fn_extra == NULL)
	{
		/* Lookup the datatype of the supplied argument */
		Oid			argtypeid = get_fn_expr_argtype(fcinfo->flinfo, 0);

		typlen = get_typlen(argtypeid);
		if (typlen == 0)		/* should not happen */
			elog(ERROR, "cache lookup failed for type %u", argtypeid);

		fcinfo->flinfo->fn_extra = MemoryContextAlloc(fcinfo->flinfo->fn_mcxt,
													  sizeof(int));
		*((int *) fcinfo->flinfo->fn_extra) = typlen;
	}
	else
		typlen = *((int *) fcinfo->flinfo->fn_extra);

	if (typlen == -1)
	{
		/* varlena type, untoasted and without header */
		result = toast_raw_datum_size(value) - VARHDRSZ;
	}
	else if (typlen == -2)
	{
		/* cstring */
		result = strlen(DatumGetCString(value)) + 1;
	}
	else
	{
		/* ordinary fixed-width type */
		result = typlen;
	}

	PG_RETURN_INT32(result);
}

/*
* The int_floor() and int_ceiling() functions are made to just return the
* original argument because floor(int) and ceiling(int) are always equal to int
* itself. This can only be done for int types and we are sure that these
* functions only have int arguments because these functions are ONLY invoked
* from wrapper functions that accept bigint, int, smallint and tinyint arguments.
*/
Datum
int_floor(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);

	/* Floor of an integer is the integer itself */
	PG_RETURN_INT64(arg1);
}

Datum
int_ceiling(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);

	/* Ceiling of an integer is the integer itself */
	PG_RETURN_INT64(arg1);
}

/*
* Floor/ceiling of bit type returns FLOATNTYPE in tsql. By default, we
* return numeric for floor/ceiling of bit. This function is to return a double
* precision output for a bit input.
*/
Datum
bit_floor(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);

	/* Floor of a bit is the bit itself */
	PG_RETURN_FLOAT8((float8) arg1);
}

Datum
bit_ceiling(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);

	/* Ceiling of a bit is the bit itself */
	PG_RETURN_FLOAT8((float8) arg1);
}

Datum
xact_state(PG_FUNCTION_ARGS)
{
	if (NestedTranCount == 0)
	{
		PG_RETURN_INT16(0);
	}
	else if (canCommitTransaction())
	{
		PG_RETURN_INT16(1);
	}
	else
	{
		PG_RETURN_INT16(-1);
	}
}

Datum
get_enr_list(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	List	   *enr_list = get_namedRelList();
	ListCell   *lc;

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not " \
						"allowed in this context")));

	/* need to build tuplestore in query context */
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	/* build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(2);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "reloid",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "relname",
					   TEXTOID, -1, 0);

	tupstore =
		tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
							  false, 1024);
	/* generate junk in short-term context */
	MemoryContextSwitchTo(oldcontext);

	/* scan all the variables in top estate */
	foreach(lc, enr_list)
	{
		Datum		values[2];
		bool		nulls[2];

		MemSet(nulls, 0, sizeof(nulls));

		values[0] = ((EphemeralNamedRelationMetadata) lfirst(lc))->reliddesc;
		values[1] = CStringGetTextDatum(((EphemeralNamedRelationMetadata) lfirst(lc))->name);

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	PG_RETURN_NULL();
}

Datum
tsql_random(PG_FUNCTION_ARGS)
{
	LOCAL_FCINFO(fcinfo1, 0);
	int			seed = PG_GETARG_INT32(0);
	Datum result;

	/* set the seed first */
	DirectFunctionCall1(setseed, Float8GetDatum((double) seed / 2147483649));

	/* call PG's random function */
	InitFunctionCallInfoData(*fcinfo1, NULL, 0, InvalidOid, NULL, NULL);
	result = drandom(fcinfo1);

	return result;
}

Datum
is_member(PG_FUNCTION_ARGS)
{
	const char *role = text_to_cstring(PG_GETARG_TEXT_P(0));
	Oid			role_oid = get_role_oid(role, true);

	if (!OidIsValid(role_oid))
	{
		PG_RETURN_NULL();
	}

	if (is_member_of_role(GetUserId(), role_oid))
	{
		PG_RETURN_INT32(1);
	}
	else
	{
		PG_RETURN_INT32(0);
	}
}

Datum
schema_name(PG_FUNCTION_ARGS)
{
	Oid			oid = PG_GETARG_OID(0);
	HeapTuple	tup;
	Form_pg_namespace nspform;
	NameData	name;
	const char *logical_name;

	VarChar    *result;

	if (!OidIsValid(oid))
	{
		PG_RETURN_NULL();
	}

	tup = SearchSysCache1(NAMESPACEOID, ObjectIdGetDatum(oid));

	if (!HeapTupleIsValid(tup))
	{
		PG_RETURN_NULL();
	}

	nspform = (Form_pg_namespace) GETSTRUCT(tup);
	name = nspform->nspname;

	logical_name = get_logical_schema_name(name.data, true);
	if (logical_name)
		result = (*common_utility_plugin_ptr->tsql_varchar_input) (logical_name, strlen(logical_name), -1);

	else
		result = (*common_utility_plugin_ptr->tsql_varchar_input) (name.data, strlen(name.data), -1);

	ReleaseSysCache(tup);
	PG_RETURN_VARCHAR_P(result);
}

Datum
schema_id(PG_FUNCTION_ARGS)
{
	char	   *name;
	char	   *input_name;
	char	   *physical_name;
	int			id;

	/* when no argument is passed, then ID of default schema of the caller */
	if (PG_NARGS() == 0)
	{
		char	   *db_name = get_cur_db_name();
		const char *user = get_user_for_database(db_name);
		const char *guest_role_name = get_guest_role_name(db_name);

		if (!user)
		{
			pfree(db_name);
			PG_RETURN_NULL();
		}
		else if ((guest_role_name && strcmp(user, guest_role_name) == 0))
		{
			physical_name = pstrdup(get_guest_schema_name(db_name));
		}
		else
		{
			name = get_authid_user_ext_schema_name((const char *) db_name, user);
			physical_name = get_physical_schema_name(db_name, name);
		}
		pfree(db_name);
	}
	else
	{
		if (PG_ARGISNULL(0))
			PG_RETURN_NULL();

		input_name = text_to_cstring(PG_GETARG_TEXT_P(0));
		if (pltsql_case_insensitive_identifiers)
		{
			name = downcase_identifier(input_name, strlen(input_name), false, false);	/* no truncation here.
																						 * truncation will be
																						 * handled inside
																						 * get_physical_schema_name() */
			pfree(input_name);
		}
		else
			name = input_name;

		physical_name = get_physical_schema_name(get_cur_db_name(), name);
	}

	/*
	 * If physical schema name is empty or NULL for any reason then return
	 * NULL.
	 */
	if (physical_name == NULL || strlen(physical_name) == 0)
		PG_RETURN_NULL();

	id = get_namespace_oid(physical_name, true);

	pfree(name);
	pfree(physical_name);

	if (!OidIsValid(id))
		PG_RETURN_NULL();

	PG_RETURN_INT32(id);
}

Datum
datefirst(PG_FUNCTION_ARGS)
{
	PG_RETURN_UINT32(pltsql_datefirst);
}

/* @@OPTIONS returns a bitmap of the current boolean SET options */
Datum
options(PG_FUNCTION_ARGS)
{
	int			options = 0;

	/*
	 * 1st bit is for DISABLE_DEF_CNST_CHK, which is an obsolete setting and
	 * should always be 0
	 */

	/* 2nd bit: IMPLICIT_TRANSACTIONS */
	if (pltsql_implicit_transactions)
		options += 2;

	/* 3rd bit: CURSOR_CLOSE_ON_COMMIT */
	if (pltsql_cursor_close_on_commit)
		options += 4;

	/* 4th bit: ANSI_WARNINGS */
	if (pltsql_ansi_warnings)
		options += 8;

	/*
	 * 5th bit: ANSI_PADDING, this setting is WIP. We only support the default
	 * ON setting atm
	 */
	if (pltsql_ansi_padding)
		options += 16;

	/* 6th bit: ANSI_NULLS */
	if (pltsql_ansi_nulls)
		options += 32;

	/* 7th bit: ARITHABORT */
	if (pltsql_arithabort)
		options += 64;

	/* 8th bit: ARITHIGNORE */
	if (pltsql_arithignore)
		options += 128;

	/* 9th bit: QUOTED_IDENTIFIER */
	if (pltsql_quoted_identifier)
		options += 256;

	/* 10th bit: NOCOUNT */
	if (pltsql_nocount)
		options += 512;

	/* 11th bit: ANSI_NULL_DFLT_ON */
	if (pltsql_ansi_null_dflt_on)
		options += 1024;

	/* 12th bit: ANSI_NULL_DFLT_OFF */
	if (pltsql_ansi_null_dflt_off)
		options += 2048;

	/* 13th bit: CONCAT_NULL_YIELDS_NULL */
	if (pltsql_concat_null_yields_null)
		options += 4096;

	/* 14th bit: NUMERIC_ROUNDABORT */
	if (pltsql_numeric_roundabort)
		options += 8192;

	/* 15th bit: XACT_ABORT */
	if (pltsql_xact_abort)
		options += 16384;

	PG_RETURN_UINT32(options);
}

/* This function will return the default AD domain name */
Datum
default_domain(PG_FUNCTION_ARGS)
{
	char	   *login_domainname = NULL;

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_login_domainname)
		login_domainname = (*pltsql_protocol_plugin_ptr)->get_login_domainname();

	if (login_domainname)
		PG_RETURN_VARCHAR_P((*common_utility_plugin_ptr->tsql_varchar_input) (login_domainname, strlen(login_domainname), -1));
	else
		PG_RETURN_NULL();
}

/*
 *		tsql_exp			- returns the exponential function of arg1
 */
Datum
tsql_exp(PG_FUNCTION_ARGS)
{
	float8		arg1 = PG_GETARG_FLOAT8(0);
	float8 result;

	errno = 0;
	result = exp(arg1);

	if (errno == ERANGE && result !=0 && !isinf(result))
		result = get_float8_infinity();

	if (unlikely(isinf(result)) && !isinf(arg1))
		float_overflow_error();
	PG_RETURN_FLOAT8(result);
}

Datum
host_os(PG_FUNCTION_ARGS)
{
	char	   *host_os_res,
			   *pg_version,
				host_str[256];
	void	   *info;

	/* filter out host info */
	pg_version = pstrdup(PG_VERSION_STR);
	sscanf(pg_version, "PostgreSQL %*s on %s, compiled by %*s", host_str);

	if (strstr(host_str, "w64") || strstr(host_str, "w32") || strstr(host_str, "mingw") || strstr(host_str, "visual studio"))
	{
		host_os_res = pstrdup("Windows");
	}
	else if (strstr(host_str, "linux"))
	{
		host_os_res = pstrdup("Linux");
	}
	else if (strstr(host_str, "mac"))
	{
		host_os_res = pstrdup("Mac");
	}
	else
		host_os_res = pstrdup("UNKNOWN");

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (host_os_res, strlen(host_os_res), -1);
	if (pg_version)
		pfree(pg_version);
	if (host_os_res)
		pfree(host_os_res);
	PG_RETURN_VARCHAR_P(info);
}

/*
 * Returns activity of TDS backends.
 */
Datum
tsql_stat_get_activity_deprecated_in_2_2_0(PG_FUNCTION_ARGS)
{
	int			num_backends = pgstat_fetch_stat_numbackends();
	int			curr_backend;
	char	   *view_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			pid = -1;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/*
	 * For sys.dm_exec_sessions view: - If user is sysadmin, we show info of
	 * all the sessions - If user is not sysadmin, we only show info of
	 * current session For sys.dm_exec_connections view: - If user is
	 * sysadmin, we show info of all the connections - If user is not
	 * sysadmin, we throw an error since user does not have the required
	 * permissions to query this view
	 */
	if (strcmp(view_name, "sessions") == 0)
	{
		if (role_is_sa(GetSessionUserId()))
			pid = -1;
		else
			pid = MyProcPid;
	}
	else if (strcmp(view_name, "connections") == 0)
	{
		if (role_is_sa(GetSessionUserId()))
			pid = -1;
		else
			ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					 errmsg("The user does not have permission to perform this action")));
	}

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(TSQL_STAT_GET_ACTIVITY_COLS - 1);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "procid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "client_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "library_name", VARCHAROID, 32, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "language", VARCHAROID, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "quoted_identifier", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "arithabort", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "ansi_null_dflt_on", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "ansi_defaults", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "ansi_warnings", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "ansi_padding", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "ansi_nulls", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "concat_null_yields_null", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "textsize", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "datefirst", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "lock_timeout", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 16, "transaction_isolation", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 17, "client_pid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 18, "row_count", INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 19, "prev_error", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 20, "trancount", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 21, "protocol_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 22, "packet_size", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 23, "encrypt_option", VARCHAROID, 40, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 24, "database_id", INT2OID, -1, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	/* 1-based index */
	for (curr_backend = 1; curr_backend <= num_backends; curr_backend++)
	{
		/* for each row */
		Datum		values[TSQL_STAT_GET_ACTIVITY_COLS - 1];
		bool		nulls[TSQL_STAT_GET_ACTIVITY_COLS - 1];

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_stat_values &&
			(*pltsql_protocol_plugin_ptr)->get_stat_values(values, nulls, TSQL_STAT_GET_ACTIVITY_COLS, pid, curr_backend))
			tuplestore_putvalues(tupstore, tupdesc, values, nulls);
		else
			continue;

		/* If only a single backend was requested, and we found it, break. */
		if (pid != -1)
			break;
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->invalidate_stat_view)
		(*pltsql_protocol_plugin_ptr)->invalidate_stat_view();

	return (Datum) 0;
}

Datum
tsql_stat_get_activity(PG_FUNCTION_ARGS)
{
	Oid			sysadmin_oid = get_role_oid("sysadmin", false);
	int			num_backends = pgstat_fetch_stat_numbackends();
	int			curr_backend;
	char	   *view_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			pid = -1;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/*
	 * For sys.dm_exec_sessions view: - If user is sysadmin, we show info of
	 * all the sessions - If user is not sysadmin, we only show info of
	 * current session For sys.dm_exec_connections view: - If user is
	 * sysadmin, we show info of all the connections - If user is not
	 * sysadmin, we throw an error since user does not have the required
	 * permissions to query this view
	 */
	if (strcmp(view_name, "sessions") == 0)
	{
		if (has_privs_of_role(GetSessionUserId(), sysadmin_oid))
			pid = -1;
		else
			pid = MyProcPid;
	}
	else if (strcmp(view_name, "connections") == 0)
	{
		if (has_privs_of_role(GetSessionUserId(), sysadmin_oid))
			pid = -1;
		else
			ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					 errmsg("The user does not have permission to perform this action")));
	}

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(TSQL_STAT_GET_ACTIVITY_COLS);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "procid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "client_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "library_name", VARCHAROID, 32, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "language", VARCHAROID, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "quoted_identifier", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "arithabort", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "ansi_null_dflt_on", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "ansi_defaults", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "ansi_warnings", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "ansi_padding", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "ansi_nulls", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "concat_null_yields_null", BOOLOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "textsize", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "datefirst", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "lock_timeout", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 16, "transaction_isolation", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 17, "client_pid", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 18, "row_count", INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 19, "prev_error", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 20, "trancount", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 21, "protocol_version", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 22, "packet_size", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 23, "encrypt_option", VARCHAROID, 40, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 24, "database_id", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 25, "host_name", VARCHAROID, 128, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	/* 1-based index */
	for (curr_backend = 1; curr_backend <= num_backends; curr_backend++)
	{
		/* for each row */
		Datum		values[TSQL_STAT_GET_ACTIVITY_COLS];
		bool		nulls[TSQL_STAT_GET_ACTIVITY_COLS];

		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_stat_values &&
			(*pltsql_protocol_plugin_ptr)->get_stat_values(values, nulls, TSQL_STAT_GET_ACTIVITY_COLS, pid, curr_backend))
			tuplestore_putvalues(tupstore, tupdesc, values, nulls);
		else
			continue;

		/* If only a single backend was requested, and we found it, break. */
		if (pid != -1)
			break;
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->invalidate_stat_view)
		(*pltsql_protocol_plugin_ptr)->invalidate_stat_view();

	return (Datum) 0;
}

Datum
get_current_full_xact_id(PG_FUNCTION_ARGS)
{
	PreventCommandDuringRecovery("get_current_full_xact_id()");

	PG_RETURN_FULLTRANSACTIONID(GetCurrentFullTransactionId());
}

Datum
checksum(PG_FUNCTION_ARGS)
{
	int32 result = 0;
	int			nargs = PG_NARGS();
	StringInfoData buf;
	char		md5[MD5_HASH_LEN + 1];
	char	   *name;
	bool		success;

	initStringInfo(&buf);
	if (nargs > 0)
	{
		ArrayType  *arr;
		Datum	   *values;
		bool	   *nulls;
		int			nelems;
		int			i;

		arr = PG_GETARG_ARRAYTYPE_P(0);
		deconstruct_array(arr, TEXTOID, -1, false, TYPALIGN_INT, &values, &nulls, &nelems);
		for (i = 0; i < nelems; i++)
		{
			name = nulls[i] ? "" : TextDatumGetCString(values[i]);
			if (strlen(name) == 0 && nelems == 1)
				PG_RETURN_INT32(0);
			else
				appendStringInfoString(&buf, name);
		}
	}

	/*
	 * We get hash value for md5 which is in hexadecimal. We are taking the
	 * first 8 characters of the md5 hash and converting it to int32.
	 */
	success = pg_md5_hash(buf.data, buf.len, md5);
	if (success)
	{
		md5[8] = '\0';
		result = (int) strtol(md5, NULL, 16);
	}
	pfree(buf.data);

	PG_RETURN_INT32(result);
}

/*
 * object_id
 * 	Returns the object ID with object name and object type as input where object type is optional
 * Returns NULL
 * 	if input is NULL
 * 	if there is no such object
 * 	if user don't have right permission
 * 	if any error occured
 */
Datum
object_id(PG_FUNCTION_ARGS)
{
	char	   *db_name,
			   *schema_name,
			   *object_name;
	char	   *physical_schema_name;
	char	   *input;
	char	   *object_type = NULL;
	char	  **splited_object_name;
	Oid			schema_oid;
	Oid			user_id = GetUserId();
	Oid result = InvalidOid;
	bool		is_temp_object;
	int			i;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();
	input = text_to_cstring(PG_GETARG_TEXT_P(0));

	if (!PG_ARGISNULL(1))
	{
		char	   *str = text_to_cstring(PG_GETARG_TEXT_P(1));

		i = strlen(str);
		if (i > 2)
		{
			pfree(input);
			pfree(str);
			PG_RETURN_NULL();
		}
		else if (i == 2 && isspace((unsigned char) str[1]))
		{
			str[1] = '\0';
		}
		object_type = downcase_identifier(str, strlen(str), false, false);
		pfree(str);
	}
	/* strip trailing whitespace from input */
	i = strlen(input);
	while (i > 0 && isspace((unsigned char) input[i - 1]))
		input[--i] = '\0';

	/* length should be restricted to 4000 */
	if (i > 4000)
		ereport(ERROR,
				(errcode(ERRCODE_STRING_DATA_LENGTH_MISMATCH),
				 errmsg("input value is too long for object name")));

	/* resolve the three part name */
	splited_object_name = split_object_name(input);
	db_name = splited_object_name[1];
	schema_name = splited_object_name[2];
	object_name = splited_object_name[3];

	/* downcase identifier if needed */
	if (pltsql_case_insensitive_identifiers)
	{
		db_name = downcase_identifier(db_name, strlen(db_name), false, false);
		schema_name = downcase_identifier(schema_name, strlen(schema_name), false, false);
		object_name = downcase_identifier(object_name, strlen(object_name), false, false);
		for (int i = 0; i < 4; i++)
			pfree(splited_object_name[i]);
	}
	else
		pfree(splited_object_name[0]);

	pfree(input);
	pfree(splited_object_name);

	/* truncate identifiers if needed */
	truncate_tsql_identifier(db_name);
	truncate_tsql_identifier(schema_name);
	truncate_tsql_identifier(object_name);

	if (!strcmp(db_name, ""))
		db_name = get_cur_db_name();
	else if (strcmp(db_name, get_cur_db_name()) && strcmp(db_name, "tempdb"))
	{
		/* cross database lookup */
		int			db_id = get_db_id(db_name);

		if (!DbidIsValid(db_id))
		{
			pfree(db_name);
			pfree(schema_name);
			pfree(object_name);
			if (object_type)
				pfree(object_type);
			PG_RETURN_NULL();
		}
		user_id = GetSessionUserId();
	}

	/* get physical schema name from logical schema name */
	if (!strcmp(schema_name, ""))
	{
		/*
		 * find the default schema for current user and get physical schema
		 * name
		 */
		const char *user = get_user_for_database(db_name);
		const char *guest_role_name = get_guest_role_name(db_name);

		if (!user)
		{
			pfree(db_name);
			pfree(schema_name);
			pfree(object_name);
			if (object_type)
				pfree(object_type);
			PG_RETURN_NULL();
		}
		else if ((guest_role_name && strcmp(user, guest_role_name) == 0))
		{
			physical_schema_name = pstrdup(get_guest_schema_name(db_name));
		}
		else
		{
			pfree(schema_name);
			schema_name = get_authid_user_ext_schema_name((const char *) db_name, user);
			physical_schema_name = get_physical_schema_name(db_name, schema_name);
		}
	}
	else
	{
		physical_schema_name = get_physical_schema_name(db_name, schema_name);
	}

	/*
	 * get schema oid from physical schema name, it will return InvalidOid if
	 * user don't have lookup access
	 */
	schema_oid = get_namespace_oid(physical_schema_name, true);

	/* free unnecessary pointers */
	pfree(db_name);
	pfree(schema_name);
	pfree(physical_schema_name);

	if (!OidIsValid(schema_oid) || pg_namespace_aclcheck(schema_oid, user_id, ACL_USAGE) != ACLCHECK_OK)
	{
		pfree(object_name);
		if (object_type)
			pfree(object_type);
		PG_RETURN_NULL();
	}

	/* check if looking for temp object */
	is_temp_object = (object_name[0] == '#' ? true : false);

	if (object_type)			/* "object_type" is specified in-argument */
	{
		if (is_temp_object)
		{
			if (!strcmp(object_type, "s") || !strcmp(object_type, "u") || !strcmp(object_type, "v") ||
				!strcmp(object_type, "it") || !strcmp(object_type, "et") || !strcmp(object_type, "so"))
			{
				/*
				 * search in list of ENRs registered in the current query
				 * environment by name
				 */
				EphemeralNamedRelation enr = get_ENR(currentQueryEnv, object_name);

				if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
				{
					result = enr->md.reliddesc;
				}
			}
			else if (!strcmp(object_type, "r") || !strcmp(object_type, "ec") || !strcmp(object_type, "pg") ||
					 !strcmp(object_type, "sn") || !strcmp(object_type, "sq") || !strcmp(object_type, "tt"))
			{
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Object type currently unsupported in Babelfish.")));
			}
		}
		else
		{
			if (!strcmp(object_type, "s") || !strcmp(object_type, "u") || !strcmp(object_type, "v") ||
				!strcmp(object_type, "it") || !strcmp(object_type, "et") || !strcmp(object_type, "so"))
			{
				/* search in pg_class by name and schema oid */
				Oid			relid = get_relname_relid((const char *) object_name, schema_oid);

				if (OidIsValid(relid) && pg_class_aclcheck(relid, user_id, ACL_SELECT) == ACLCHECK_OK)
				{
					result = relid;
				}
			}
			else if (!strcmp(object_type, "c") || !strcmp(object_type, "d") || !strcmp(object_type, "f") ||
					 !strcmp(object_type, "pk") || !strcmp(object_type, "uq"))
			{
				/* search in pg_constraint by name and schema oid */
				result = tsql_get_constraint_oid(object_name, schema_oid, user_id);
			}
			else if (!strcmp(object_type, "af") || !strcmp(object_type, "fn") || !strcmp(object_type, "fs") ||
					 !strcmp(object_type, "ft") || !strcmp(object_type, "if") || !strcmp(object_type, "p") ||
					 !strcmp(object_type, "pc") || !strcmp(object_type, "tf") || !strcmp(object_type, "rf") ||
					 !strcmp(object_type, "x"))
			{
				/* search in pg_proc by name and schema oid */
				result = tsql_get_proc_oid(object_name, schema_oid, user_id);
			}
			else if (!strcmp(object_type, "tr") || !strcmp(object_type, "ta"))
			{
				/* search in pg_trigger by name and schema oid */
				result = tsql_get_trigger_oid(object_name, schema_oid, user_id);
			}
			else if (!strcmp(object_type, "r") || !strcmp(object_type, "ec") || !strcmp(object_type, "pg") ||
					 !strcmp(object_type, "sn") || !strcmp(object_type, "sq") || !strcmp(object_type, "tt"))
			{
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Object type currently unsupported in Babelfish.")));
			}
		}

	}
	else
	{
		if (is_temp_object)		/* temp object without "object_type"
								 * in-argument */
		{
			/*
			 * search in list of ENRs registered in the current query
			 * environment by name
			 */
			EphemeralNamedRelation enr = get_ENR(currentQueryEnv, object_name);

			if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
			{
				result = enr->md.reliddesc;
			}
		}
		else
		{
			/* search in pg_class by name and schema oid */
			Oid			relid = get_relname_relid((const char *) object_name, schema_oid);

			if (OidIsValid(relid) && pg_class_aclcheck(relid, user_id, ACL_SELECT) == ACLCHECK_OK)
			{
				result = relid;
			}

			if (!OidIsValid(result))	/* search only if not found earlier */
			{
				/* search in pg_trigger by name and schema oid */
				result = tsql_get_trigger_oid(object_name, schema_oid, user_id);
			}

			if (!OidIsValid(result))
			{
				/* search in pg_proc by name and schema oid */
				result = tsql_get_proc_oid(object_name, schema_oid, user_id);
			}

			if (!OidIsValid(result))
			{
				/* search in pg_constraint by name and schema oid */
				result = tsql_get_constraint_oid(object_name, schema_oid, user_id);
			}
		}
	}
	pfree(object_name);
	if (object_type)
		pfree(object_type);

	if (OidIsValid(result))
		PG_RETURN_INT32(result);
	else
		PG_RETURN_NULL();
}

/*
 * object_name
 * 		returns the object name with object id and database id as input where database id is optional
 * Returns NULL
 * 		if there is no such object in specified database, if database id is not provided it will lookup in current database
 * 		if user don't have right permission
 */
Datum
object_name(PG_FUNCTION_ARGS)
{
	int32		input1 = PG_GETARG_INT32(0);
	Oid			object_id;
	Oid			database_id;
	Oid			user_id = GetUserId();
	Oid			schema_id = InvalidOid;
	HeapTuple	tuple;
	Relation	tgrel;
	ScanKeyData key;
	SysScanDesc tgscan;
	EphemeralNamedRelation enr;
	bool		found = false;
	char	   *result = NULL;

	if (input1 < 0)
		PG_RETURN_NULL();
	object_id = (Oid) input1;
	if (!PG_ARGISNULL(1))		/* if database id is provided */
	{
		int32		input2 = PG_GETARG_INT32(1);

		if (input2 < 0)
			PG_RETURN_NULL();
		database_id = (Oid) input2;
		if (database_id != get_cur_db_id()) /* cross-db lookup */
		{
			char	   *db_name = get_db_name(database_id);

			if (db_name == NULL)	/* database doesn't exist with given oid */
				PG_RETURN_NULL();
			user_id = GetSessionUserId();
			pfree(db_name);
		}
	}
	else						/* by default lookup in current database */
		database_id = get_cur_db_id();

	/*
	 * search in list of ENRs registered in the current query environment by
	 * object_id
	 */
	enr = get_ENR_withoid(currentQueryEnv, object_id);
	if (enr != NULL && enr->md.enrtype == ENR_TSQL_TEMP)
	{
		result = enr->md.name;

		PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text(result));
	}

	/* search in pg_class by object_id */
	tuple = SearchSysCache1(RELOID, ObjectIdGetDatum(object_id));
	if (HeapTupleIsValid(tuple))
	{
		/* check if user have right permission on object */
		if (pg_class_aclcheck(object_id, user_id, ACL_SELECT) == ACLCHECK_OK)
		{
			Form_pg_class pg_class = (Form_pg_class) GETSTRUCT(tuple);
			result = NameStr(pg_class->relname);

			schema_id = pg_class->relnamespace;
		}
		ReleaseSysCache(tuple);
		found = true;
	}

	if (!found)
	{
		/* search in pg_proc by object_id */
		tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			/* check if user have right permission on object */
			if (pg_proc_aclcheck(object_id, user_id, ACL_EXECUTE) == ACLCHECK_OK)
			{
				Form_pg_proc procform = (Form_pg_proc) GETSTRUCT(tuple);
				result = NameStr(procform->proname);

				schema_id = procform->pronamespace;
			}
			ReleaseSysCache(tuple);
			found = true;
		}
	}

	if (!found)
	{
		/* search in pg_type by object_id */
		tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			/* check if user have right permission on object */
			if (pg_type_aclcheck(object_id, user_id, ACL_USAGE) == ACLCHECK_OK)
			{
				Form_pg_type pg_type = (Form_pg_type) GETSTRUCT(tuple);
				result = NameStr(pg_type->typname);
			}
			ReleaseSysCache(tuple);
			found = true;
		}
	}

	if (!found)
	{
		/* search in pg_trigger by object_id */
		tgrel = table_open(TriggerRelationId, AccessShareLock);
		ScanKeyInit(&key,
					Anum_pg_trigger_oid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(object_id));

		tgscan = systable_beginscan(tgrel, TriggerOidIndexId, true,
									NULL, 1, &key);

		tuple = systable_getnext(tgscan);
		if (HeapTupleIsValid(tuple))
		{
			Form_pg_trigger pg_trigger = (Form_pg_trigger) GETSTRUCT(tuple);

			/* check if user have right permission on object */
			if (OidIsValid(pg_trigger->tgrelid) &&
				pg_class_aclcheck(pg_trigger->tgrelid, user_id, ACL_SELECT) == ACLCHECK_OK)
			{
				result = NameStr(pg_trigger->tgname);

				schema_id = get_rel_namespace(pg_trigger->tgrelid);
			}
			found = true;
		}
		systable_endscan(tgscan);
		table_close(tgrel, AccessShareLock);
	}

	if (!found)
	{
		/* search in pg_constraint by object_id */
		tuple = SearchSysCache1(CONSTROID, ObjectIdGetDatum(object_id));
		if (HeapTupleIsValid(tuple))
		{
			Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);

			/* check if user have right permission on object */
			if (OidIsValid(con->conrelid) && (pg_class_aclcheck(con->conrelid, user_id, ACL_SELECT) == ACLCHECK_OK))
			{
				result = NameStr(con->conname);

				schema_id = con->connamespace;
			}
			ReleaseSysCache(tuple);
			found = true;
		}
	}

	if (result)
	{
		/*
		 * Check if schema corresponding to found object belongs to specified
		 * database, schema also can be shared schema like "sys" or
		 * "information_schema_tsql". In case of pg_type schema_id will be
		 * invalid.
		 */
		if (!OidIsValid(schema_id) || is_schema_from_db(schema_id, database_id)
			|| (schema_id == get_namespace_oid("sys", true)) || (schema_id == get_namespace_oid("information_schema_tsql", true)))
			PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text(result));
	}
	PG_RETURN_NULL();
}

Datum
has_dbaccess(PG_FUNCTION_ARGS)
{
	char	   *db_name = text_to_cstring(PG_GETARG_TEXT_P(0));

	/*
	 * Ensure the database name input argument is lower-case, as all Babel
	 * table names are lower-case
	 */
	char	   *lowercase_db_name = lowerstr(db_name);

	/* Also strip trailing whitespace to mimic SQL Server behaviour */
	int			i;
	const char *user = NULL;
	const char *login;
	int16		db_id;

	i = strlen(lowercase_db_name);
	while (i > 0 && isspace((unsigned char) lowercase_db_name[i - 1]))
		lowercase_db_name[--i] = '\0';

	db_id = get_db_id(lowercase_db_name);

	if (!DbidIsValid(db_id))
		PG_RETURN_NULL();

	login = GetUserNameFromId(GetSessionUserId(), false);
	user = get_authid_user_ext_physical_name(lowercase_db_name, login);

	/*
	 * Special cases: Database Owner should always have access If this DB has
	 * guest roles, the guests should always have access
	 */
	if (!user)
	{
		Oid			datdba;

		datdba = get_role_oid("sysadmin", false);
		if (is_member_of_role(GetSessionUserId(), datdba))
			user = get_dbo_role_name(lowercase_db_name);
		else
		{
			/*
			 * Get the guest role name only if the guest is enabled on the
			 * current db.
			 */
			if (guest_has_dbaccess(lowercase_db_name))
				user = get_guest_role_name(lowercase_db_name);
			else
				user = NULL;
		}
	}

	if (!user)
		PG_RETURN_INT32(0);
	else
		PG_RETURN_INT32(1);
}

Datum
sp_datatype_info_helper(PG_FUNCTION_ARGS)
{

	int16		odbcVer = PG_GETARG_INT16(0);
	bool		is_100 = PG_GETARG_BOOL(1);

	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	int			i;
	Oid			nspoid = get_namespace_oid("sys", false);
	Oid			sys_varcharoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("varchar"), ObjectIdGetDatum(nspoid));
	Oid			colloid = tsql_get_server_collation_oid_internal(false);

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(SP_DATATYPE_INFO_HELPER_COLS);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "TYPE_NAME", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "DATA_TYPE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "PRECISION", INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "LITERAL_PREFIX", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "LITERAL_SUFFIX", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "CREATE_PARAMS", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "NULLABLE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "CASE_SENSITIVE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "SEARCHABLE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "UNSIGNED_ATTRIBUTE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "MONEY", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "AUTO_INCREMENT", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "LOCAL_TYPE_NAME", sys_varcharoid, 20, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "MINIMUM_SCALE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "MAXIMUM_SCALE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 16, "SQL_DATA_TYPE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 17, "SQL_DATETIME_SUB", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 18, "NUM_PREC_RADIX", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 19, "INTERVAL_PRECISION", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 20, "USERTYPE", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 21, "LENGTH", INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 22, "SS_DATA_TYPE", INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 23, "PG_TYPE_NAME", sys_varcharoid, 20, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	/* And set the correct collations to the required fields. */
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 1, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 4, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 5, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 6, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 13, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 23, colloid);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	for (i = 0; i < DATATYPE_INFO_TABLE_ROWS; i++)
	{
		/* for each row */
		Datum		values[SP_DATATYPE_INFO_HELPER_COLS];
		bool		nulls[SP_DATATYPE_INFO_HELPER_COLS];

		DatatypeInfo datatype_info_element = datatype_info_table[i];

		MemSet(nulls, false, SP_DATATYPE_INFO_HELPER_COLS);

		values[0] = CStringGetTextDatum(datatype_info_element.type_name);

		if (odbcVer == 3)
		{
			if (is_100)
				values[1] = Int32GetDatum(datatype_info_element.data_type_3_100);
			else
				values[1] = Int32GetDatum(datatype_info_element.data_type_3);
		}
		else
		{
			if (is_100)
				values[1] = Int32GetDatum(datatype_info_element.data_type_2_100);
			else
				values[1] = Int32GetDatum(datatype_info_element.data_type_2);
		}

		values[2] = Int64GetDatum(datatype_info_element.precision);

		if (strcmp(datatype_info_element.literal_prefix, NULLVAL_STR) == 0)
			nulls[3] = true;
		else
			values[3] = CStringGetTextDatum(datatype_info_element.literal_prefix);

		if (strcmp(datatype_info_element.literal_suffix, NULLVAL_STR) == 0)
			nulls[4] = true;
		else
			values[4] = CStringGetTextDatum(datatype_info_element.literal_suffix);

		if (strcmp(datatype_info_element.create_params, NULLVAL_STR) == 0)
			nulls[5] = true;
		else
			values[5] = CStringGetTextDatum(datatype_info_element.create_params);

		values[6] = Int32GetDatum(datatype_info_element.nullable);
		values[7] = Int32GetDatum(datatype_info_element.case_sensitive);
		values[8] = Int32GetDatum(datatype_info_element.searchable);

		if (datatype_info_element.unsigned_attribute == NULLVAL)
			nulls[9] = true;
		else
			values[9] = Int32GetDatum(datatype_info_element.unsigned_attribute);

		values[10] = Int32GetDatum(datatype_info_element.money);

		if (datatype_info_element.auto_increment == NULLVAL)
			nulls[11] = true;
		else
			values[11] = Int32GetDatum(datatype_info_element.auto_increment);

		values[12] = CStringGetTextDatum(datatype_info_element.local_type_name);

		if (datatype_info_element.minimum_scale == NULLVAL)
			nulls[13] = true;
		else
			values[13] = Int32GetDatum(datatype_info_element.minimum_scale);

		if (datatype_info_element.maximum_scale == NULLVAL)
			nulls[14] = true;
		else
			values[14] = Int32GetDatum(datatype_info_element.maximum_scale);

		values[15] = Int32GetDatum(datatype_info_element.sql_data_type);

		if (datatype_info_element.sql_datetime_sub == NULLVAL)
			nulls[16] = true;
		else
			values[16] = Int32GetDatum(datatype_info_element.sql_datetime_sub);

		if (datatype_info_element.num_prec_radix == NULLVAL)
			nulls[17] = true;
		else
			values[17] = Int32GetDatum(datatype_info_element.num_prec_radix);

		if (datatype_info_element.interval_precision == NULLVAL)
			nulls[18] = true;
		else
			values[18] = Int32GetDatum(datatype_info_element.interval_precision);

		values[19] = Int32GetDatum(datatype_info_element.usertype);
		values[20] = Int32GetDatum(datatype_info_element.length);
		values[21] = UInt8GetDatum(datatype_info_element.ss_data_type);

		if (strcmp(datatype_info_element.pg_type_name, NULLVAL_STR) == 0)
			nulls[22] = true;
		else
			values[22] = CStringGetTextDatum(datatype_info_element.pg_type_name);

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	return (Datum) 0;
}

Datum
language(PG_FUNCTION_ARGS)
{
	PG_RETURN_VARCHAR_P(get_language());
}

Datum
host_name(PG_FUNCTION_ARGS)
{
	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_host_name)
		PG_RETURN_VARCHAR_P(string_to_tsql_varchar((*pltsql_protocol_plugin_ptr)->get_host_name()));
	else
		PG_RETURN_NULL();
}

/*
 * Execute various integrity checks.
 * Returns true if all the checks pass otherwise
 * raises an appropriate error message.
 */
Datum
babelfish_integrity_checker(PG_FUNCTION_ARGS)
{
	if (!inited_ht_tsql_cast_info)
	{
		ereport(ERROR,
				(errcode(ERRCODE_CHECK_VIOLATION),
				 errmsg("T-SQL cast info hash table is not properly initialized.")));
	}
	else if (!inited_ht_tsql_datatype_precedence_info)
	{
		ereport(ERROR,
				(errcode(ERRCODE_CHECK_VIOLATION),
				 errmsg("T-SQL datatype precedence hash table is not properly initialized.")));
	}

	PG_RETURN_BOOL(true);
}

Datum
bigint_degrees(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result <0)
		result = ceil(result);

	else
		result = floor(result);

	/* Range check */
	if (unlikely(isnan(result) || !FLOAT8_FITS_IN_INT64(result)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("Arithmetic overflow error converting expression to data type bigint")));

	PG_RETURN_INT64((int64) result);
}

Datum
int_degrees(PG_FUNCTION_ARGS)
{
	int32		arg1 = PG_GETARG_INT32(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result <0)
		result = ceil(result);

	else
		result = floor(result);

	/* Range check */
	if (unlikely(isnan(result) || !FLOAT8_FITS_IN_INT32(result)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("Arithmetic overflow error converting expression to data type int")));

	PG_RETURN_INT32((int32) result);
}

Datum
smallint_degrees(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result <0)
		result = ceil(result);

	else
		result = floor(result);

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32) result);
}

Datum
bigint_radians(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int64 */

	PG_RETURN_INT64((int64) result);
}

Datum
int_radians(PG_FUNCTION_ARGS)
{
	int32		arg1 = PG_GETARG_INT32(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32) result);
}

Datum
smallint_radians(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);
	float8 result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32) result);
}

Datum
bigint_power(PG_FUNCTION_ARGS)
{
	int64		arg1 = PG_GETARG_INT64(0);
	Numeric		arg2 = PG_GETARG_NUMERIC(1);
	int64 result;
	Numeric		arg1_numeric,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(int8_numeric, arg1));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_power, NumericGetDatum(arg1_numeric), NumericGetDatum(arg2)));

	result = DatumGetInt64(DirectFunctionCall1(numeric_int8, NumericGetDatum(result_numeric)));

	PG_RETURN_INT64(result);
}

Datum
int_power(PG_FUNCTION_ARGS)
{
	int32		arg1 = PG_GETARG_INT32(0);
	Numeric		arg2 = PG_GETARG_NUMERIC(1);
	int32 result;
	Numeric		arg1_numeric,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(int4_numeric, arg1));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_power, NumericGetDatum(arg1_numeric), NumericGetDatum(arg2)));

	result = DatumGetInt32(DirectFunctionCall1(numeric_int4, NumericGetDatum(result_numeric)));

	PG_RETURN_INT32(result);
}

Datum
smallint_power(PG_FUNCTION_ARGS)
{
	int16		arg1 = PG_GETARG_INT16(0);
	Numeric		arg2 = PG_GETARG_NUMERIC(1);
	int32 result;
	Numeric		arg1_numeric,
				result_numeric;

	arg1_numeric = DatumGetNumeric(DirectFunctionCall1(int2_numeric, arg1));
	result_numeric = DatumGetNumeric(DirectFunctionCall2(numeric_power, NumericGetDatum(arg1_numeric), Int16GetDatum(arg2)));

	result = DatumGetInt32(DirectFunctionCall1(numeric_int4, NumericGetDatum(result_numeric)));

	PG_RETURN_INT32(result);
}

Datum
numeric_degrees(PG_FUNCTION_ARGS)
{
	Numeric		arg1 = PG_GETARG_NUMERIC(0);
	Numeric		radians_per_degree,
	result;

	radians_per_degree = DatumGetNumeric(DirectFunctionCall1(float8_numeric, Float8GetDatum(RADIANS_PER_DEGREE)));

	result = DatumGetNumeric(DirectFunctionCall2(numeric_div, NumericGetDatum(arg1), NumericGetDatum(radians_per_degree)));

	PG_RETURN_NUMERIC(result);
}

Datum
numeric_radians(PG_FUNCTION_ARGS)
{
	Numeric		arg1 = PG_GETARG_NUMERIC(0);
	Numeric		radians_per_degree,
	result;

	radians_per_degree = DatumGetNumeric(DirectFunctionCall1(float8_numeric, Float8GetDatum(RADIANS_PER_DEGREE)));

	result = DatumGetNumeric(DirectFunctionCall2(numeric_mul, NumericGetDatum(arg1), NumericGetDatum(radians_per_degree)));

	PG_RETURN_NUMERIC(result);
}

/* Returns the database schema name for schema-scoped objects. */
Datum
object_schema_name(PG_FUNCTION_ARGS)
{
	Oid			object_id;
	Oid			database_id;
	Oid			user_id = GetUserId();
	Oid			namespace_oid = InvalidOid;
	Oid			temp_nspid = InvalidOid;
	char	   *namespace_name;
	const char *schema_name;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();
	else
		object_id = (Oid) PG_GETARG_INT32(0);

	if (PG_ARGISNULL(1))
		database_id = get_cur_db_id();
	else
	{
		database_id = (Oid) PG_GETARG_INT32(1);
		user_id = GetSessionUserId();
	}

	/* lookup namespace_oid in pg_class */
	temp_nspid = get_rel_namespace(object_id);
	if (OidIsValid(temp_nspid))
	{
		if (pg_class_aclcheck(object_id, user_id, ACL_SELECT) == ACLCHECK_OK)
			namespace_oid = temp_nspid;
		else
			PG_RETURN_NULL();
	}
	if (!OidIsValid(namespace_oid))
	{							/* if not found earlier */
		/* Lookup namespace_oid in pg_proc */
		temp_nspid = tsql_get_proc_nsp_oid(object_id);
		if (OidIsValid(temp_nspid))
		{
			if (pg_proc_aclcheck(object_id, user_id, ACL_EXECUTE) == ACLCHECK_OK)
				namespace_oid = temp_nspid;
			else
				PG_RETURN_NULL();
		}
	}
	if (!OidIsValid(namespace_oid))
	{							/* if not found earlier */
		/* Lookup namespace_oid in pg_trigger */
		temp_nspid = tsql_get_trigger_rel_oid(object_id);
		if (OidIsValid(temp_nspid))
		{
			/*
			 * Since pg_trigger does not contain namespace oid, we use the
			 * fact that the schema name of the trigger should be same as that
			 * of the table the trigger is on
			 */
			if (pg_class_aclcheck(temp_nspid, user_id, ACL_SELECT) == ACLCHECK_OK)
				namespace_oid = get_rel_namespace(temp_nspid);
			else
				PG_RETURN_NULL();
		}
	}
	if (!OidIsValid(namespace_oid))
	{							/* if not found earlier */
		/* Lookup namespace_oid in pg_constraint */
		namespace_oid = tsql_get_constraint_nsp_oid(object_id, user_id);
	}

	/* Find schema name from namespace_oid */
	if (OidIsValid(namespace_oid))
	{
		namespace_name = get_namespace_name(namespace_oid);
		if (pg_namespace_aclcheck(namespace_oid, user_id, ACL_USAGE) != ACLCHECK_OK ||
		/* database_id should be same as that of db_id of physical schema name */
			database_id != get_dbid_from_physical_schema_name(namespace_name, true))
			PG_RETURN_NULL();
		schema_name = get_logical_schema_name(namespace_name, true);
		pfree(namespace_name);
		PG_RETURN_TEXT_P(cstring_to_text(schema_name));
	}
	else
		PG_RETURN_NULL();
}
