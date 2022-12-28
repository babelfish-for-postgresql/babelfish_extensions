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
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "utils/queryenvironment.h"
#include "utils/float.h"
#include "utils/xid8.h"
#include <math.h>

#include "../src/babelfish_version.h"
#include "../src/datatype_info.h"
#include "../src/datatypes.h"
#include "../src/pltsql.h"
#include "../src/pltsql_instr.h"
#include "../src/multidb.h"
#include "../src/session.h"
#include "../src/catalog.h"
#include "../src/collation.h"
#include "../src/rolecmds.h"
#include "src/backend/catalog/objectaddress.c"
#include "src/include/utils/catcache.h"

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

void* string_to_tsql_varchar(const char *input_str);
void* get_servername_internal(void);
void* get_servicename_internal(void);
void* get_language(void);
extern bool canCommitTransaction(void);

extern int pltsql_datefirst;
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

char *bbf_servername = "BABELFISH";
const char *bbf_servicename = "MSSQLSERVER";
char *bbf_language = "us_english";
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
	void *info;

	initStringInfo(&temp);

	if (pg_strcasecmp(pltsql_version, "default") == 0)
	{
		char *pg_version = pstrdup(PG_VERSION_STR);
		char *temp_str = pg_version;

		temp_str = strstr(temp_str, ", compiled by");
		*temp_str = '\0';

		appendStringInfo(&temp,
						 "Babelfish for PostgreSQL with SQL Server Compatibility - %s"
						 "\n%s %s\nCopyright (c) Amazon Web Services\n%s (Babelfish %s)",
						 BABEL_COMPATIBILITY_VERSION,
						 __DATE__, __TIME__, pg_version, BABELFISH_VERSION_STR);
	}
	else
		appendStringInfoString(&temp, pltsql_version);

	/*
	 * TODO: Return Build number with version string as well.
	 */

	info = tsql_varchar_input(temp.data, temp.len, -1);
	pfree(temp.data);
	PG_RETURN_VARCHAR_P(info);
}

void* string_to_tsql_varchar(const char *input_str)
{
	StringInfoData temp;
	void* info;

	initStringInfo(&temp);
	appendStringInfoString(&temp, input_str);

	info = tsql_varchar_input(temp.data, temp.len, -1);
	pfree(temp.data);
	return info;
}

void* get_servername_internal()
{
	return string_to_tsql_varchar(bbf_servername);
}

void* get_servicename_internal()
{
	return string_to_tsql_varchar(bbf_servicename);
}

void* get_language()
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
	char *error_sqlstate = unpack_sql_state(latest_pg_error_code);
	PG_RETURN_VARCHAR_P(tsql_varchar_input((error_sqlstate), strlen(error_sqlstate), -1));
}


/* returns data length of one Datum
 * this function is very similar to pg_column_size, but returns untoasted data without header sizes for bytea objects
*/
Datum
datalength(PG_FUNCTION_ARGS)
{
	Datum		value = PG_GETARG_DATUM(0);
	int32		result;
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
		/* varlena type, untoasted and without header*/
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

Datum xact_state(PG_FUNCTION_ARGS)
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
    TupleDesc tupdesc;
    Tuplestorestate *tupstore;
    MemoryContext per_query_ctx;
    MemoryContext oldcontext;
	List *enr_list = get_namedRelList();
	ListCell *lc;

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

        values[0] = ((EphemeralNamedRelationMetadata)lfirst(lc))->reliddesc;
        values[1] = CStringGetTextDatum(((EphemeralNamedRelationMetadata)lfirst(lc))->name);

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
	int seed = PG_GETARG_INT32(0);
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
	Oid role_oid = get_role_oid(role, true);

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
	Oid oid = PG_GETARG_OID(0);
	HeapTuple   tup;
	Form_pg_namespace nspform;
	NameData name;
	const char *logical_name;

	VarChar *result;

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
		result = tsql_varchar_input(logical_name, strlen(logical_name), -1);
	else 
		result = tsql_varchar_input(name.data, strlen(name.data), -1);

	ReleaseSysCache(tup);
	PG_RETURN_VARCHAR_P(result);
}

Datum
schema_id(PG_FUNCTION_ARGS)
{
	const char *name = text_to_cstring(PG_GETARG_TEXT_P(0));
	int id;
	HeapTuple   tup;
	Oid         nspOid;
	Form_pg_namespace nspform;
	const char *physical_name;

	if (pltsql_case_insensitive_identifiers)
		name = downcase_identifier(name, strlen(name), false, false); /* no truncation here. truncation will be handled inside get_physical_schema_name() */
	physical_name = get_physical_schema_name(get_cur_db_name(), name);

	/*
	 * If physical schema name is empty or NULL for any reason then return NULL.
	 */
	if (physical_name == NULL || strlen(physical_name) == 0)
		PG_RETURN_NULL();

	tup = SearchSysCache1(NAMESPACENAME, CStringGetDatum(physical_name));

	if (!HeapTupleIsValid(tup))
	{
		PG_RETURN_NULL();
	}

	nspform = (Form_pg_namespace) GETSTRUCT(tup);
	nspOid = nspform->oid;
	id = (int) nspOid;
	
	ReleaseSysCache(tup);
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
    int options = 0;

    /* 1st bit is for DISABLE_DEF_CNST_CHK, which is an obsolete setting and should always be 0 */

    /* 2nd bit: IMPLICIT_TRANSACTIONS */
    if (pltsql_implicit_transactions)
        options += 2;

    /* 3rd bit: CURSOR_CLOSE_ON_COMMIT */
    if (pltsql_cursor_close_on_commit)
        options += 4;

    /* 4th bit: ANSI_WARNINGS */
    if (pltsql_ansi_warnings)
        options += 8;

    /* 5th bit: ANSI_PADDING, this setting is WIP. We only support the default ON setting atm */
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
	char* login_domainname = NULL;

	if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_login_domainname)
		login_domainname = (*pltsql_protocol_plugin_ptr)->get_login_domainname();

	if (login_domainname)
		PG_RETURN_VARCHAR_P(tsql_varchar_input(login_domainname, strlen(login_domainname), -1));
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
	float8		result;

	errno = 0;
	result = exp(arg1);
	if (errno == ERANGE && result != 0 && !isinf(result))
		result = get_float8_infinity();

	if (unlikely(isinf(result)) && !isinf(arg1))
		float_overflow_error();
	PG_RETURN_FLOAT8(result);
}

Datum
host_os(PG_FUNCTION_ARGS)
{
	char *host_os_res, *pg_version, host_str[256];
	void *info;

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

	info = tsql_varchar_input(host_os_res, strlen(host_os_res), -1);
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
	char*			view_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			pid = -1;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/* For sys.dm_exec_sessions view:
	 *     - If user is sysadmin, we show info of all the sessions
	 *     - If user is not sysadmin, we only show info of current session
	 * For sys.dm_exec_connections view:
	 *     - If user is sysadmin, we show info of all the connections
	 *     - If user is not sysadmin, we throw an error since user does not
	 *       have the required permissions to query this view
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
		else continue;

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
	char*			view_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			pid = -1;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/* For sys.dm_exec_sessions view:
	 *     - If user is sysadmin, we show info of all the sessions
	 *     - If user is not sysadmin, we only show info of current session
	 * For sys.dm_exec_connections view:
	 *     - If user is sysadmin, we show info of all the connections
	 *     - If user is not sysadmin, we throw an error since user does not
	 *       have the required permissions to query this view
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
		else continue;

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
       int nargs = PG_NARGS();
       StringInfoData buf;
       char md5[MD5_HASH_LEN + 1];
       char *name;
       bool success;

       initStringInfo(&buf);
       if (nargs > 0)
       {
                ArrayType *arr;
                Datum *values;
                bool *nulls;
                int nelems;
                int i;
                arr = PG_GETARG_ARRAYTYPE_P(0);
                deconstruct_array(arr, TEXTOID, -1, false, TYPALIGN_INT, &values, &nulls, &nelems);
                for (i=0; i<nelems; i++)
                {
                        name = nulls[i] ? "": TextDatumGetCString(values[i]);
                        if (strlen(name) == 0 && nelems == 1)
                                PG_RETURN_INT32(0);
                        else
                                appendStringInfoString(&buf, name);
                }
        }

        /* We get hash value for md5 which is in hexadecimal.
         * We are taking the first 8 characters of the md5 hash
         * and converting it to int32.
         */
        success = pg_md5_hash(buf.data, buf.len, md5);
        if (success)
        {
                md5[8] = '\0';
                result = (int)strtol(md5, NULL, 16);
        }
        pfree(buf.data);

        PG_RETURN_INT32(result);
}

static int babelfish_get_delimiter_pos(char *str)
{	
	char *ptr;
	if(strlen(str) <= 2 && (strchr(str, '"') || strchr(str, '[') || strchr(str, ']')))
		return -1;
	else if(str[0] == '[')
	{
		ptr = strstr(str, "].");
		if(ptr == NULL)
			return -1;
		else
			return (int)(ptr - str) + 1;
	}
	else if(str[0] == '"')
	{
		ptr = strstr(&str[1], "\".");
		if(ptr == NULL)
			return -1;
		else
			return (int)(ptr - str) + 1;
	}
	else
	{	
		ptr = strstr(str, ".");
		if(ptr == NULL)
			return -1;
		else
			return (int)(ptr - str);
	}
	
	return -1;
}

static char* extract_and_remove_delimiter_pair(char *str, int len)
{	
	/* Extract string from str of given length and remove delimiter pair */
	if (len >= 2 && ((str[0] == '[' && str[len - 1] == ']') || (str[0] == '"' && str[len - 1] == '"')))
	{	
		if(len > 2)
		{	
			char *res = (char *) palloc((len - 1) * sizeof(char));
			strncpy(res, &str[1], len - 2);
			res[len - 2] = '\0';
			return res;
		} 
		else
			return "";
			
	}
	else
	{
		char *res = (char *) palloc((len + 1) * sizeof(char));
		strncpy(res, str, len);
		res[len] =  '\0';
		return res;
	}
}

Datum
object_id(PG_FUNCTION_ARGS)
{	
	char 			*db_name = "";
	char 			*schema_name = "";
	char 			*physical_schema_name;
	char 			*object_name;
	bool 			is_temp_object;
	Oid 			schema_oid;
	Oid 			result = InvalidOid;
	CatCList		*catlist;
	Relation		tgrel;
	ScanKeyData 	skey[2];
	SysScanDesc 	tgscan;
	HeapTuple		tuple;
	int 			i;
	int 			cur_pos;
	int 			next_pos;
	char *input = 	lowerstr(text_to_cstring(PG_GETARG_TEXT_P(0)));
	char *object_type = text_to_cstring(PG_GETARG_TEXT_P(1));
	List 			*list = NIL;
	char 			*str;

	/* strip trailing whitespace */
	i = strlen(input);
	while (i > 0 && isspace((unsigned char) input[i - 1]))
		input[--i] = '\0';
	
	/* 
	 * Resolve the three part name
	 * Get physical schema name from logical schema name
	 * Valid formats are db_name.schema_name.object_name or schema_name.object_name or object_name
	 */
	cur_pos = 0;
	next_pos = babelfish_get_delimiter_pos(input);
	while (next_pos != -1)
	{
		str = extract_and_remove_delimiter_pair(&input[cur_pos], next_pos);
		list = lappend(list, str);
		cur_pos += next_pos + 1;
		next_pos = babelfish_get_delimiter_pos(&input[cur_pos]);
	}
	str = extract_and_remove_delimiter_pair(&input[cur_pos], strlen(&input[cur_pos]));
	list = lappend(list, str);

	switch (list_length(list))
	{
		case 1:
			object_name = (char *) linitial(list);
			break;
		case 2:
			schema_name = (char *) linitial(list);
			object_name = (char *) lsecond(list);
			break;
		case 3:
			db_name = (char *) linitial(list);
			schema_name = (char *) lsecond(list);
			object_name = (char *) lthird(list);
			break;
		default:
			PG_RETURN_NULL();
	}
	/* truncate identifiers if needed */
	truncate_tsql_identifier(db_name);
	truncate_tsql_identifier(schema_name);
	truncate_tsql_identifier(object_name);

	/* Invalid object_name */
	if (!object_name)
		PG_RETURN_NULL();

	if (!strcmp(db_name, ""))
		db_name = get_cur_db_name();

	/* Check if looking in current database, if not then return null value */
	if (strcmp(db_name, get_cur_db_name()) && strcmp(db_name, "tempdb"))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("Can only do lookup in current database.")));

	if (!strcmp(schema_name, ""))
	{	
		/* find the default schema for current user */
		const char *user = get_user_for_database(db_name);
		schema_name = get_authid_user_ext_schema_name((const char *) db_name, user);
	}

	physical_schema_name = get_physical_schema_name(db_name, schema_name);

	/* Get schema oid from physical schema name */
	schema_oid = LookupExplicitNamespace(physical_schema_name, true);
	if (!OidIsValid(schema_oid))
		PG_RETURN_NULL();
	
	/* Check if looking for temp object */
	is_temp_object = (object_name[0] == '#'? true: false);

	if (strcmp(object_type, "")) /* object_type is not empty */
	{
		if (!strcmp(object_type, "S") || !strcmp(object_type, "U") || !strcmp(object_type, "V") ||
			!strcmp(object_type, "IT") || !strcmp(object_type, "ET") || !strcmp(object_type, "SO"))
		{
			if (is_temp_object)
			{
				/* Search in list of ENRs registered in the current query environment by name */
				List *enr_list = get_namedRelList();
				ListCell *lc;
				int reloid;
				char *relname;
				foreach (lc, enr_list)
				{	
					reloid = ((EphemeralNamedRelationMetadata)lfirst(lc))->reliddesc;
					relname = ((EphemeralNamedRelationMetadata)lfirst(lc))->name;
					if (!strcmp(relname, object_name))
					{
						result = reloid;
						break;
					}
				}
			}
			else
			{
				/* Search in pg_class by name and schema oid */
				result = get_relname_relid((const char *) object_name, schema_oid); 
			}
		}
		else if (!strcmp(object_type, "C") || !strcmp(object_type, "D") || !strcmp(object_type, "F") ||
				!strcmp(object_type, "PK") || !strcmp(object_type, "UQ"))
		{
			/* Search in pg_constraint by name and schema oid */
			tgrel = table_open(ConstraintRelationId, AccessShareLock);
			ScanKeyInit(&skey[0],
						Anum_pg_constraint_conname,
						BTEqualStrategyNumber, F_NAMEEQ,
						CStringGetDatum(object_name));

			ScanKeyInit(&skey[1],
						Anum_pg_constraint_connamespace,
						BTEqualStrategyNumber, F_OIDEQ,
						ObjectIdGetDatum(schema_oid));

			tgscan = systable_beginscan(tgrel, ConstraintNameNspIndexId,
										true, NULL, 2, skey);

			/* We are interested in the first row only */
			if (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
			{
				Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);
				result = con->oid;
			}
			systable_endscan(tgscan);
			table_close(tgrel, AccessShareLock);
		}
		else if (!strcmp(object_type, "AF") || !strcmp(object_type, "FN") || !strcmp(object_type, "FS") ||
				!strcmp(object_type, "FT") || !strcmp(object_type, "IF") || !strcmp(object_type, "P") ||
				!strcmp(object_type, "PC") || !strcmp(object_type, "TF") || !strcmp(object_type, "RF") ||
				!strcmp(object_type, "X"))
		{
			/* First search in pg_proc by name */
			catlist = SearchSysCacheList1(PROCNAMEARGSNSP, CStringGetDatum(object_name));
			for (i = 0; i < catlist->n_members; i++)
			{
				Form_pg_proc procform;
				tuple = &catlist->members[i]->tuple;
				procform = (Form_pg_proc) GETSTRUCT(tuple);
				/* Then consider only procs in specified schema oid */
				if (procform->pronamespace == schema_oid)
				{
					result = procform->oid;
					break;
				}
			}
			ReleaseSysCacheList(catlist);
		}
		else if (!strcmp(object_type, "TR") || !strcmp(object_type, "TA"))
		{
			/* Search in pg_trigger by name */
			tgrel = table_open(TriggerRelationId, AccessShareLock);
			ScanKeyInit(&skey[0],
						Anum_pg_trigger_tgname,
						BTEqualStrategyNumber, F_NAMEEQ,
						CStringGetDatum(object_name));

			tgscan = systable_beginscan(tgrel, TriggerRelidNameIndexId,
										true, NULL, 1, skey);

			/* We are interested in the first row only */
			if (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
			{
				Form_pg_trigger pg_trigger = (Form_pg_trigger) GETSTRUCT(tuple);
				result = pg_trigger->oid;
			}
			systable_endscan(tgscan);
			table_close(tgrel, AccessShareLock);
		}
		else if (!strcmp(object_type, "R") || !strcmp(object_type, "EC") || !strcmp(object_type, "PG") ||
				!strcmp(object_type, "SN") || !strcmp(object_type, "SQ") || !strcmp(object_type, "TT"))
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					errmsg("Object type currently unsupported")));
		}
		else
		{
			PG_RETURN_NULL();
		}

		if (OidIsValid(result))
			PG_RETURN_INT32(result);
		else
			PG_RETURN_NULL();
	}
	else
	{	
		if (is_temp_object) /* temp object without "object_type" in-argument */
		{
			/* Search in list of ENRs registered in the current query environment by name */
			List *enr_list = get_namedRelList();
			ListCell *lc;
			int reloid;
			char *relname;
			foreach (lc, enr_list)
			{	
				reloid = ((EphemeralNamedRelationMetadata)lfirst(lc))->reliddesc;
				relname = ((EphemeralNamedRelationMetadata)lfirst(lc))->name;
				if (!strcmp(relname, object_name))
				{
					result = reloid;
					PG_RETURN_INT32(result);
				}
			}
			PG_RETURN_NULL();
		}
		else
		{
			/* Search in pg_constraint by name and schema oid */
			tgrel = table_open(ConstraintRelationId, AccessShareLock);
			ScanKeyInit(&skey[0],
						Anum_pg_constraint_conname,
						BTEqualStrategyNumber, F_NAMEEQ,
						CStringGetDatum(object_name));

			ScanKeyInit(&skey[1],
						Anum_pg_constraint_connamespace,
						BTEqualStrategyNumber, F_OIDEQ,
						ObjectIdGetDatum(schema_oid));

			tgscan = systable_beginscan(tgrel, ConstraintNameNspIndexId,
										true, NULL, 2, skey);

			/* We are interested in the first row only */
			if (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
			{
				Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);
				if (OidIsValid(con->oid))
				{
					result = con->oid;
				}
			}
			systable_endscan(tgscan);
			table_close(tgrel, AccessShareLock);
			if(OidIsValid(result))
				PG_RETURN_INT32(result);

			/* Search in pg_class by name and schema oid */
			result = get_relname_relid((const char *) object_name, schema_oid); 
			if (OidIsValid(result))
				PG_RETURN_INT32(result);

			/* Search in pg_trigger by name */
			tgrel = table_open(TriggerRelationId, AccessShareLock);
			ScanKeyInit(&skey[0],
						Anum_pg_trigger_tgname,
						BTEqualStrategyNumber, F_NAMEEQ,
						CStringGetDatum(object_name));

			tgscan = systable_beginscan(tgrel, TriggerRelidNameIndexId,
										true, NULL, 1, skey);
			
			/* We are interested in the first row only */
			if (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
			{
				Form_pg_trigger pg_trigger = (Form_pg_trigger) GETSTRUCT(tuple);
				if (OidIsValid(pg_trigger->oid))
				{
					result = pg_trigger->oid;
				}
			}
			systable_endscan(tgscan);
			table_close(tgrel, AccessShareLock);
			if (OidIsValid(result))
				PG_RETURN_INT32(result);

			/* First search in pg_proc by name*/
			catlist = SearchSysCacheList1(PROCNAMEARGSNSP, CStringGetDatum(object_name));
			for (i = 0; i < catlist->n_members; i++)
			{
				Form_pg_proc procform;
				tuple = &catlist->members[i]->tuple;
				procform = (Form_pg_proc) GETSTRUCT(tuple);
				/* Then consider only procs in specified schema oid */
				if (procform->pronamespace == schema_oid)
				{
					result = procform->oid;
					break;
				}
			}
			ReleaseSysCacheList(catlist);
			if (OidIsValid(result))
				PG_RETURN_INT32(result);
			else
				PG_RETURN_NULL();
		}
	}

}


Datum
has_dbaccess(PG_FUNCTION_ARGS)
{
	char *db_name = text_to_cstring(PG_GETARG_TEXT_P(0));
	/* Ensure the database name input argument is lower-case, as all Babel table names are lower-case */
	char *lowercase_db_name = lowerstr(db_name);
	/* Also strip trailing whitespace to mimic SQL Server behaviour */
	int i;
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

	/* Special cases:
		Database Owner should always have access
		If this DB has guest roles, the guests should always have access
	*/
	if (!user)
	{
		Oid				datdba;

		datdba = get_role_oid("sysadmin", false);
		if (is_member_of_role(GetSessionUserId(), datdba))
			user = get_dbo_role_name(lowercase_db_name);
		else
		{
			/* Get the guest role name only if the guest is enabled on the current db.*/
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
	int i;
	Oid nspoid = get_namespace_oid("sys", false);
	Oid sys_varcharoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("varchar"), ObjectIdGetDatum(nspoid));
	Oid colloid = tsql_get_server_collation_oid_internal(false);

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
	int64	arg1 = PG_GETARG_INT64(0);
	float8	result;
	 
	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result < 0)
		result = ceil(result);
	else
		result = floor(result);

	 /* Range check */
	if (unlikely(isnan(result) || !FLOAT8_FITS_IN_INT64(result)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				errmsg("Arithmetic overflow error converting expression to data type bigint")));

	PG_RETURN_INT64((int64)result);
}

Datum
int_degrees(PG_FUNCTION_ARGS)
{
	int32	arg1 = PG_GETARG_INT32(0);
	float8	result;
	 
	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result < 0)
		result = ceil(result);
	else
		result = floor(result);

	 /* Range check */
	if (unlikely(isnan(result) || !FLOAT8_FITS_IN_INT32(result)))
		ereport(ERROR,
				(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				errmsg("Arithmetic overflow error converting expression to data type int")));

	PG_RETURN_INT32((int32)result);
}

Datum
smallint_degrees(PG_FUNCTION_ARGS)
{
	int16	arg1 = PG_GETARG_INT16(0);
	float8	result;

	result = DatumGetFloat8(DirectFunctionCall1(degrees, Float8GetDatum((float8) arg1)));

	if (result < 0)
		result = ceil(result);
	else
		result = floor(result);

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32) result);
}

Datum
bigint_radians(PG_FUNCTION_ARGS)
{
	int64    arg1 = PG_GETARG_INT64(0);
	float8  result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int64 */

	PG_RETURN_INT64((int64)result);
}

Datum
int_radians(PG_FUNCTION_ARGS)
{
	int32    arg1 = PG_GETARG_INT32(0);
	float8  result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32)result);
}

Datum
smallint_radians(PG_FUNCTION_ARGS)
{
	int16    arg1 = PG_GETARG_INT16(0);
	float8  result;

	result = DatumGetFloat8(DirectFunctionCall1(radians, Float8GetDatum((float8) arg1)));

	/* skip range check, since it cannot overflow int32 */

	PG_RETURN_INT32((int32)result);
}
