/*-------------------------------------------------------------------------
 *
 * guc.c
 *	  TDS configuration variables
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/guc.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "miscadmin.h"
#include "utils/guc.h"

#include "src/include/tds_int.h"
#include "src/include/tds_response.h"
#include "src/include/tds_secure.h"
#include "src/include/faultinjection.h"
#include "src/include/guc.h"

/* Global variables */
int		pe_port;
char	*pe_listen_addrs = NULL;
char	*pe_unix_socket_directories = NULL;
int		pe_unix_socket_permissions = 0;
char	*pe_unix_socket_group = NULL;

char   *default_server_name = NULL;
int 	tds_default_numeric_precision = 38;
int 	tds_default_numeric_scale = 8;
bool	tds_ssl_encrypt = false;
int 	tds_default_protocol_version = 0;
int32_t tds_default_packet_size = 4096;
int	tds_debug_log_level = 1;
char*	product_version = NULL;

#ifdef FAULT_INJECTOR
static bool TdsFaultInjectionEnabled = false;
#endif
bool enable_drop_babelfish_role = false;

const struct config_enum_entry ssl_protocol_versions_info[] = {
	{"", PG_TLS_ANY, false},
	{"TLSv1", PG_TLS1_VERSION, false},
	{"TLSv1.1", PG_TLS1_1_VERSION, false},
	{"TLSv1.2", PG_TLS1_2_VERSION, false},
	{NULL, 0, false}
};

const struct config_enum_entry tds_protocol_versions_info[] = {
	{"TDSv7.0", TDS_VERSION_7_0, false},
	{"TDSv7.1", TDS_VERSION_7_1, false},
	{"TDSv7.1.1", TDS_VERSION_7_1_1, false},
	{"TDSv7.2", TDS_VERSION_7_2, false},
	{"TDSv7.3A", TDS_VERSION_7_3_A, false},
	{"TDSv7.3B", TDS_VERSION_7_3_B, false},
	{"TDSv7.4", TDS_VERSION_7_4, false},
	{"DEFAULT", TDS_DEFAULT_VERSION, false},
	{NULL, 0, false}
};

/* --------------------------------
 * TdsSslProtocolMinVersionCheck - check for Tds ssl min Protocol Vesion GUC
 * -------------------------------
 */
static bool
TdsSslProtocolMinVersionCheck(int *newvalue, void **extra, GucSource source)
{
	if (*newvalue <= tds_ssl_max_protocol_version)
		return true;
	else
	{
		GUC_check_errmsg("TDS SSL Min Protocol Version 0x%X  more than TDS SSL Max Protocol Version 0x%x",
				*newvalue, tds_ssl_max_protocol_version);
		return false;
	}
}

/* --------------------------------
 * TdsSslProtocolMaxVersionCheck - check for Tds ssl max Protocol Vesion GUC
 * -------------------------------
 */
static bool
TdsSslProtocolMaxVersionCheck(int *newvalue, void **extra, GucSource source)
{
	if (*newvalue >= tds_ssl_min_protocol_version)
		return true;
	else
	{
		GUC_check_errmsg("TDS SSL Max Protocol Version 0x%X  less than TDS SSL Min Protocol Version 0x%x",
				*newvalue, tds_ssl_min_protocol_version);
		return false;
	}
}

/* --------------------------------
 * TdsGucDefaultPacketSizeCheck - Using this function to Assign the
 * appropriate value to the GUC. In TDS, the packet
 * Size is rounded down to the nearest multiple of 4.
 * -------------------------------
 */
static bool
TdsGucDefaultPacketSizeCheck(int *newvalue, void **extra, GucSource source)
{
	*newvalue = (((int) *newvalue / 4) * 4);
	return true;
}

static bool 
check_version_number(char **newval, void **extra, GucSource source)
{
	char 		*copy_version_number = malloc(sizeof(*newval));
	char		*token;
	int		part = 0;

	strcpy(copy_version_number,*newval);
	if(strcasecmp(copy_version_number,"default") == 0)
		return true;

	PG_TRY();
	{
		for (token = strtok(copy_version_number, "."); token; token = strtok(NULL, "."))
		{	
			/* check each token contains only digits */
			if(!isdigit((unsigned char) *token))
			{
				ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Please enter a valid version number")));
			}
			
			/* check Major Version is between 11 and 15 */
			if(part == 0 && (11 > atoi(token) || atoi(token) > 15))
			{
				ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Please enter a valid major version number between 11 and 15")));
			}

			/* Minor Version takes 1 byte in PreLogin message when doing handshake, here to check
				it is between 0 and 0xFF
			*/
			if(part == 1 && (atoi(token) < 0 || atoi(token) > 0xFF))
			{
				ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Please enter a valid minor version number")));
			}
			/* Micro Version takes 2 bytes in PreLogin message when doing handshake, here to check
				it is between 0 and 0xFFFF
			*/
			if(part == 2 && (atoi(token) < 0 || atoi(token) > 0xFFFF))
			{
				ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Please enter a valid micro version number")));
			}
			part++;
		}

		if(part != 4)
		{
			ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Please enter 4 valid number separated by \'.\' ")));
		}
	}
	PG_FINALLY();
	{
		free(copy_version_number);
	}
	PG_END_TRY();

    return true;
}

/*
 * Define various GUCs which are part of TDS protocol
 */
void
TdsDefineGucs(void)
{
	/* Define TDS specific GUCs */
	DefineCustomIntVariable(
                "babelfishpg_tds.port",
                gettext_noop("Sets the TDS TCP port the server listens on."),
                NULL,
                &pe_port,
                1433, 1024, 65536,
                PGC_POSTMASTER,
                GUC_NOT_IN_SAMPLE,
                NULL, NULL, NULL);

	DefineCustomStringVariable(
                "babelfishpg_tds.listen_addresses",
                gettext_noop("Sets the host name or IP address(es) to listen TDS to."),
                NULL,
                &pe_listen_addrs,
                "*",
                PGC_POSTMASTER,
                GUC_NOT_IN_SAMPLE,
                NULL, NULL, NULL);

	DefineCustomStringVariable(
                "babelfishpg_tds.unix_socket_directories",
                gettext_noop("TDS server unix socket directories."),
                NULL,
                &pe_unix_socket_directories,
                NULL,
                PGC_POSTMASTER,
                GUC_NOT_IN_SAMPLE,
                NULL, NULL, NULL);

	DefineCustomIntVariable(
                "babelfishpg_tds.unix_socket_permissions",
                gettext_noop("TDS server unix socket permissions."),
                NULL,
                &pe_unix_socket_permissions,
                0777, 0, 0777,
                PGC_POSTMASTER,
                GUC_NOT_IN_SAMPLE,
                NULL, NULL, NULL);

	DefineCustomStringVariable(
                "babelfishpg_tds.unix_socket_group",
                gettext_noop("TDS server unix socket group."),
                NULL,
                &pe_unix_socket_group,
                NULL,
                PGC_POSTMASTER,
                GUC_NOT_IN_SAMPLE,
                NULL, NULL, NULL);

	DefineCustomStringVariable(
                "babelfishpg_tds.default_server_name",
                gettext_noop("Predefined Babelfish default server name"),
                NULL,
                &default_server_name,
                TDS_DEFAULT_SERVER_NAME,
                PGC_SIGHUP,
                GUC_NOT_IN_SAMPLE,
                NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tds.product_version",
				 gettext_noop("Sets the Product Version returned by Babelfish"),
				 NULL,
				 &product_version,
				 "default",
				 PGC_USERSET,
				 GUC_NOT_IN_SAMPLE,
				 check_version_number, NULL, NULL);

	DefineCustomIntVariable(
		"babelfishpg_tds.tds_default_numeric_precision",
		gettext_noop("Sets the default precision of numeric type to be sent in"
			"the TDS column metadata if the engine does not specify one."),
		NULL,
		&tds_default_numeric_precision,
		38, 1, 38,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		NULL, NULL, NULL);

	DefineCustomIntVariable(
		"babelfishpg_tds.tds_default_numeric_scale",
		gettext_noop("Sets the default scale of numeric type to be sent in"
			"the TDS column metadata if the engine does not specify one."),
		NULL,
		&tds_default_numeric_scale,
		8, 0, 38,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		NULL, NULL, NULL);

	DefineCustomBoolVariable(
		"babelfishpg_tds.tds_ssl_encrypt",
		gettext_noop("Sets the SSL Encryption option"),
		NULL,
		&tds_ssl_encrypt,
		false,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		NULL, NULL, NULL);

	DefineCustomEnumVariable(
		"babelfishpg_tds.tds_default_protocol_version",
		gettext_noop("Sets a default TDS protocol version for"
			"all the clients being connected"),
		NULL,
		&tds_default_protocol_version,
		TDS_DEFAULT_VERSION, tds_protocol_versions_info,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		NULL,
		NULL,
		NULL);

	DefineCustomEnumVariable(
		"babelfishpg_tds.tds_ssl_max_protocol_version",
		gettext_noop("Sets the minimum SSL/TLS protocol version to use"
				"for tds session."),
		NULL,
		&tds_ssl_max_protocol_version,
		PG_TLS1_2_VERSION, ssl_protocol_versions_info + 1,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		TdsSslProtocolMaxVersionCheck,
		NULL,
		NULL);

	DefineCustomEnumVariable(
		"babelfishpg_tds.tds_ssl_min_protocol_version",
		gettext_noop("Sets the minimum SSL/TLS protocol version to use"
				"for tds session."),
		NULL,
		&tds_ssl_min_protocol_version,
		PG_TLS1_VERSION, ssl_protocol_versions_info,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		TdsSslProtocolMinVersionCheck,
		NULL,
		NULL);

	DefineCustomIntVariable(
		"babelfishpg_tds.tds_default_packet_size",
		gettext_noop("Sets the default packet size for"
			"all the clients being connected"),
		NULL,
		&tds_default_packet_size,
		4096, 512, 32767,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		TdsGucDefaultPacketSizeCheck,
		NULL,
		NULL);

	DefineCustomIntVariable(
		"babelfishpg_tds.tds_debug_log_level",
		gettext_noop("Sets the tds debug log level"),
		NULL,
		&tds_debug_log_level,
		1, 0, 3,
		PGC_SIGHUP,
		GUC_NOT_IN_SAMPLE,
		NULL,
		NULL,
		NULL);

	/*
	 * Enable user to drop a babelfish role while not in a babelfish setting.
	 */
	DefineCustomBoolVariable(
		"enable_drop_babelfish_role",
		gettext_noop("Enables dropping a babelfish role"),
		NULL,
		&enable_drop_babelfish_role,
		false,
		PGC_USERSET,
		GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
		NULL,
		NULL,
		NULL);

/* the guc is accessible only if it's compiled with fault injection flag */
#ifdef FAULT_INJECTOR
	if (!TdsFaultInjectionEnabled)
	{
		DefineCustomBoolVariable(
			"babelfishpg_tds.trigger_fault_enabled",
			gettext_noop("Enable fault injection triggers"),
			NULL,
			&trigger_fault_injection,
			true,
			PGC_SUSET,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE,
			NULL, NULL, NULL);
		TdsFaultInjectionEnabled = true;
	}
#endif
}
