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
#include "common/ip.h"
#include "lib/stringinfo.h"
#include "libpq/libpq-be.h"
#include "libpq/pqformat.h"
#include "port.h"
#include "utils/array.h"
#include "utils/date.h"
#include "parser/parse_coerce.h"
#include "parser/parse_oper.h"
#include "pltsql_instr.h"
#include "babelfish_version.h"
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
#include "pltsql.h"

PG_FUNCTION_INFO_V1(connectionproperty);
PG_FUNCTION_INFO_V1(serverproperty);
PG_FUNCTION_INFO_V1(sessionproperty);
PG_FUNCTION_INFO_V1(fulltextserviceproperty);

extern bool pltsql_ansi_nulls;
extern bool pltsql_ansi_padding;
extern bool pltsql_ansi_warnings;
extern bool pltsql_arithabort;
extern bool pltsql_concat_null_yields_null;
extern bool pltsql_numeric_roundabort;
extern bool pltsql_quoted_identifier;
extern char *bbf_servername;

static void *get_servername_helper(void);
static VarChar *get_product_version_helper(int idx);
static VarChar *get_product_level_helper();

Datum
connectionproperty(PG_FUNCTION_ARGS)
{
	const char *property = text_to_cstring(PG_GETARG_TEXT_P(0));
	VarChar    *vch;

	if (strcasecmp(property, "net_transport") == 0)
	{
		const char *ret = "TCP";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "protocol_type") == 0)
	{
		const char *ret = "TSQL";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "auth_scheme") == 0)
	{
		const char *ret = "SQL";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "local_net_address") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "local_tcp_port") == 0)
	{
		PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertIntToSQLVariantByteA) (1433));
	}
	else if (strcasecmp(property, "client_net_address") == 0)
	{
		Port	   *port = MyProcPort;
		char		remote_host[NI_MAXHOST];
		const char *ret;
		int			rc;

		if (port == NULL)
			PG_RETURN_NULL();

		switch (port->raddr.addr.ss_family)
		{
			case AF_INET:
#ifdef HAVE_IPV6
			case AF_INET6:
#endif
				break;
			default:
				PG_RETURN_NULL();
		}

		remote_host[0] = '\0';

		rc = pg_getnameinfo_all(&port->raddr.addr, port->raddr.salen,
								remote_host, sizeof(remote_host),
								NULL, 0,
								NI_NUMERICHOST | NI_NUMERICSERV);
		if (rc != 0)
			PG_RETURN_NULL();

		clean_ipv6_addr(port->raddr.addr.ss_family, remote_host);

		ret = remote_host;
		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "physical_net_transport") == 0)
	{
		const char *ret = "TCP";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else
	{
		/* for invalid input, return NULL */
		PG_RETURN_NULL();
	}

	PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertVarcharToSQLVariantByteA) (vch, PG_GET_COLLATION()));
}

void *
get_servername_helper()
{
	StringInfoData temp;
	void	   *info;

	initStringInfo(&temp);
	appendStringInfoString(&temp, bbf_servername);

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);
	pfree(temp.data);
	return info;
}

static char *
get_version_number(const char *version_string, int idx)
{
	int			part = 0,
				len = 0;
	char	   *token;
	char	   *copy_version_number;

	Assert(version_string != NULL);
	if (idx == -1)
		return (char *) version_string;

	len = strlen(version_string);
	copy_version_number = palloc0(len + 1);
	memcpy(copy_version_number, version_string, len);
	for (token = strtok(copy_version_number, "."); token; token = strtok(NULL, "."))
	{
		if (part == idx)
			return token;
		part++;
	}

	/* part should less than 3 */
	Assert(part <= 2);
	return "";
}

static VarChar *
get_product_version_helper(int idx)
{
	StringInfoData temp;
	void	   *info;
	const char *product_version;

	product_version = GetConfigOption("babelfishpg_tds.product_version", true, false);
	Assert(product_version != NULL);
	Assert(idx == -1 || idx == 0 || idx == 1);

	initStringInfo(&temp);
	if (pg_strcasecmp(product_version, "default") == 0)
	{
		appendStringInfoString(&temp, get_version_number(BABEL_COMPATIBILITY_VERSION, idx));
	}
	else
	{
		appendStringInfoString(&temp, get_version_number(product_version, idx));
	}

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);
	pfree(temp.data);
	return (VarChar *) info;
}

static VarChar *
get_product_level_helper()
{
	StringInfoData temp;
	void	   *info;
	int			minor_version;
	char	   *product_level_RTM = "RTM";
	char	   *product_level_prefix = "SP";

	initStringInfo(&temp);

	minor_version = atoi(get_version_number(BABELFISH_VERSION_STR, 1));
	if (minor_version == 0)
	{
		appendStringInfoString(&temp, product_level_RTM);
	}
	else
	{
		appendStringInfoString(&temp, product_level_prefix);
		appendStringInfoString(&temp, get_version_number(BABELFISH_VERSION_STR, 1));
		appendStringInfoString(&temp, ".");
		appendStringInfoString(&temp, get_version_number(BABELFISH_VERSION_STR, 2));
	}

	info = (*common_utility_plugin_ptr->tsql_varchar_input) (temp.data, temp.len, -1);
	pfree(temp.data);
	return (VarChar *) info;
}

Datum
serverproperty(PG_FUNCTION_ARGS)
{
	const char *property = text_to_cstring(PG_GETARG_TEXT_P(0));
	VarChar    *vch = NULL;
	int64_t		intVal = 0;

	if (strcasecmp(property, "BuildClrVersion") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_TSQL_SERVERPROPERTY_BUILDCLRVERSION);
	}
	else if (strcasecmp(property, "Collation") == 0)
	{
		const char *server_collation_name = GetConfigOption("babelfishpg_tsql.server_collation_name", false, false);

		if (server_collation_name)
			vch = (*common_utility_plugin_ptr->tsql_varchar_input) (server_collation_name, strlen(server_collation_name), -1);
	}
	else if (strcasecmp(property, "CollationID") == 0)
	{
		HeapTuple	tuple;
		char	   *collation_name;
		Oid			collation_oid;
		List	   *list;
		Oid			dboid = get_database_oid("template1", true);

		tuple = SearchSysCache1(DATABASEOID, ObjectIdGetDatum(dboid));

		TSQLInstrumentation(INSTR_TSQL_SERVERPROPERTY_COLLATIONID);
		if (HeapTupleIsValid(tuple))
		{
			char		datlocprovider;
			Datum		datum;
			bool		isnull;

			datlocprovider = ((Form_pg_database) GETSTRUCT(tuple))->datlocprovider;
			datum = SysCacheGetAttr(DATABASEOID, tuple, datlocprovider == COLLPROVIDER_ICU ? Anum_pg_database_datlocale : Anum_pg_database_datcollate, &isnull);
			Assert(!isnull);
			collation_name = pstrdup(TextDatumGetCString(datum));
			ReleaseSysCache(tuple);
			list = list_make1(makeString(collation_name));
			collation_oid = get_collation_oid(list, true);
			intVal = (int64_t) collation_oid;
		}
	}
	else if (strcasecmp(property, "ComparisonStyle") == 0)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_COMPARISON_STYLE);
		intVal = 0;
	}
	else if (strcasecmp(property, "ComputerNamePhysicalNetBIOS") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_COMPUTERNAME_PHYSICAL_NETBIOS);
	}
	else if (strcasecmp(property, "Edition") == 0)
	{
		/*
		 * Edition can be one of the following: 'Enterprise Edition'
		 * 'Enterprise Edition: Core-based Licensing' 'Enterprise Evaluation
		 * Edition' 'Business Intelligence Edition' 'Developer Edition'
		 * 'Express Edition' 'Express Edition with Advanced Services'
		 * 'Standard Edition' 'Web Edition' 'SQL Azure'
		 */
		const char *ret = "Standard Edition";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_TSQL_SERVERPROPERTY_EDITION);
	}
	else if (strcasecmp(property, "EditionID") == 0)
	{
		TSQLInstrumentation(INSTR_TSQL_SERVERPROPERTY_EDITIONID);
		/* This is the value corresponding to Standard edition */
		intVal = -1534726760;
	}
	else if (strcasecmp(property, "EngineEdition") == 0)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_ENGINE_EDITION);
		/* Engine edition corresponding to Standard */
		intVal = 2;
	}
	else if (strcasecmp(property, "HadrManagerStatus") == 0)
	{
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_HADR_MANAGER_STATUS);
		/* Started and Running */
		intVal = 1;
	}
	else if (strcasecmp(property, "InstanceDefaultDataPath") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_INSTANCE_DEFAULT_PATH);
	}
	else if (strcasecmp(property, "InstanceDefaultLogPath") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_INSTANCE_DEFAULT_LOG_PATH);
	}
	else if (strcasecmp(property, "InstanceName") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_INSTANCE_NAME);
	}
	else if (strcasecmp(property, "IsAdvancedAnalyticsInstalled") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_ADVANCED_ANALYTICS_INSTALLED);
	}
	else if (strcasecmp(property, "IsBigDataCluster") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_BIG_DATA_CLUSTER);
	}
	else if (strcasecmp(property, "IsClustered") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_CLUSTERED);
	}
	else if (strcasecmp(property, "IsFullTextInstalled") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_FULL_TEXT_INSTALLED);
	}
	else if (strcasecmp(property, "IsHadrEnabled") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_HADR_ENABLED);
	}
	else if (strcasecmp(property, "IsIntegratedSecurityOnly") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_INTEGRATED_SECURITY);
	}
	else if (strcasecmp(property, "IsLocalDB") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_LOCAL_DB);
	}
	else if (strcasecmp(property, "IsPolyBaseInstalled") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_POLYBASE_INSTALLED);
	}
	else if (strcasecmp(property, "IsSingleUser") == 0)
	{
		TSQLInstrumentation(INSTR_TSQL_SERVERPROPERTY_IS_SINGLE_USER);
		if (IsUnderPostmaster)
			/* not single - user mode */
			intVal = 0;
		else
			/* is single - user mode */
			intVal = 1;
	}
	else if (strcasecmp(property, "IsXTPSupported") == 0)
	{
		intVal = 0;
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_XTP_SUPPORTED);
	}
	else if (strcasecmp(property, "LCID") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_LCID);
	}
	else if (strcasecmp(property, "LicenseType") == 0)
	{
		const char *ret = "DISABLED";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
		TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_LICENSE_TYPE);
	}
	else if (strcasecmp(property, "MachineName") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "NumLicenses") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "ProcessID") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "ProductBuild") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "ProductBuildType") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "ProductLevel") == 0)
	{
		vch = get_product_level_helper();
	}
	else if (strcasecmp(property, "ProductMajorVersion") == 0)
	{
		vch = get_product_version_helper(0);
	}
	else if (strcasecmp(property, "ProductMinorVersion") == 0)
	{
		vch = get_product_version_helper(1);
	}
	else if (strcasecmp(property, "ProductUpdateLevel") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "ProductUpdateReference") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "ProductVersion") == 0)
	{
		vch = get_product_version_helper(-1);
	}
	else if (strcasecmp(property, "ResourceLastUpdateDateTime") == 0)
	{
		/* We need a valid date in here */
		const char *date = "2021-01-01 00:00:00-08";
		Datum		data = (*common_utility_plugin_ptr->datetime_in_str) ((char *) date, fcinfo->context);

		/*
		 * bytea        *result  =
		 * gen_sqlvariant_bytea_from_type_datum(DATETIME_T, data); svhdr_1B_t
		 * *svhdr;
		 *
		 * TSQLInstrumentation(INSTR_TSQL_DATETIME_SQLVARIANT); svhdr =
		 * SV_HDR_1B(result); SV_SET_METADATA(svhdr, DATETIME_T, HDR_VER);
		 */

		Datum result = DirectFunctionCall1(common_utility_plugin_ptr->datetime2sqlvariant, data);

		return result;
	}
	else if (strcasecmp(property, "ResourceVersion") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "ServerName") == 0)
	{
		vch = (VarChar *) get_servername_helper();
	}
	else if (strcasecmp(property, "SqlCharSet") == 0 || strcasecmp(property, "SqlSortOrder") == 0)
	{
		Datum		data = Int8GetDatum(0);

		/*
		 * bytea        *result  =
		 * gen_sqlvariant_bytea_from_type_datum(TINYINT_T, data); svhdr_1B_t
		 * *svhdr;
		 *
		 * TSQLInstrumentation(INSTR_TSQL_TINYINT_SQLVARIANT);
		 *
		 * svhdr = SV_HDR_1B(result); SV_SET_METADATA(svhdr, TINYINT_T,
		 * HDR_VER);
		 */

		Datum result = DirectFunctionCall1(common_utility_plugin_ptr->tinyint2sqlvariant, data);

		return result;
	}
	else if (strcasecmp(property, "SqlCharSetName") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "SqlSortOrderName") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "FilestreamShareName") == 0)
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "FilestreamConfiguredLevel") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "FilestreamEffectiveLevel") == 0)
	{
		intVal = 0;
	}
	else if (strcasecmp(property, "babelfish") == 0)
	{
		intVal = 1;
	}
	else if (strcasecmp(property, "BabelfishVersion") == 0)
	{
		const char *ret = BABELFISH_VERSION_STR;

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else if (strcasecmp(property, "BabelfishInternalVersion") == 0)
	{
		const char *ret;
		StringInfoData babelInternalVersion;

		initStringInfo(&babelInternalVersion);
		appendStringInfoString(&babelInternalVersion, BABELFISH_INTERNAL_VERSION_STR);

		ret = babelInternalVersion.data;
		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}
	else
	{
		const char *ret = "";

		vch = (*common_utility_plugin_ptr->tsql_varchar_input) (ret, strlen(ret), -1);
	}

	if (vch != NULL)
	{
		PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertVarcharToSQLVariantByteA) (vch, PG_GET_COLLATION()));
	}
	else
	{
		PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertIntToSQLVariantByteA) (intVal));
	}
}

Datum
sessionproperty(PG_FUNCTION_ARGS)
{
	const char *property = text_to_cstring(PG_GETARG_TEXT_P(0));
	int64_t		intVal = 0;

	if (strcasecmp(property, "ANSI_NULLS") == 0)
		intVal = (int) pltsql_ansi_nulls;
	else if (strcasecmp(property, "ANSI_PADDING") == 0)
		intVal = (int) pltsql_ansi_padding;
	else if (strcasecmp(property, "ANSI_WARNINGS") == 0)
		intVal = (int) pltsql_ansi_warnings;
	else if (strcasecmp(property, "ARITHABORT") == 0)
		intVal = (int) pltsql_arithabort;
	else if (strcasecmp(property, "CONCAT_NULL_YIELDS_NULL") == 0)
		intVal = (int) pltsql_concat_null_yields_null;
	else if (strcasecmp(property, "NUMERIC_ROUNDABORT") == 0)
		intVal = (int) pltsql_numeric_roundabort;
	else if (strcasecmp(property, "QUOTED_IDENTIFIER") == 0)
		intVal = (int) pltsql_quoted_identifier;
	else
		PG_RETURN_NULL();

	PG_RETURN_BYTEA_P((*common_utility_plugin_ptr->convertIntToSQLVariantByteA) (intVal));
}

Datum
fulltextserviceproperty(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}
