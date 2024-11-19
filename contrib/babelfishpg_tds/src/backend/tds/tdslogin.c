/*-------------------------------------------------------------------------
 *
 * tdslogin.c
 *	  TDS Listener connection handshake
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tdslogin.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <sys/param.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#include "access/printtup.h"
#include "access/xlog.h"
#include "catalog/pg_type.h"	/* For type translation */
#include "commands/dbcommands.h"
#include "common/ip.h"
#include "common/md5.h"
#include "common/scram-common.h"
#include "common/string.h"
#include "commands/extension.h"
#include "commands/user.h"
#include "libpq/auth.h"
#include "libpq/crypt.h"
#include "libpq/libpq.h"
#include "libpq/pqformat.h"
#include "libpq/scram.h"
#include "miscadmin.h"
#include "replication/walsender.h"
#include "storage/ipc.h"
#include "utils/timestamp.h"

#include "access/printtup.h"
#include "libpq/libpq.h"
#include "libpq/pqformat.h"
#include "tcop/pquery.h"
#include "parser/scansup.h"
#include "utils/guc.h"
#include "utils/acl.h"
#include "utils/formatting.h"
#include "utils/lsyscache.h"
#include "utils/memdebug.h"
#include "utils/memutils.h"
#include "utils/ps_status.h"
#include "utils/snapmgr.h"
#include "utils/timestamp.h"

#include "src/include/tds_debug.h"
#include "src/include/tds_int.h"
#include "src/include/tds_protocol.h"
#include "src/include/tds_request.h"
#include "src/include/tds_response.h"
#include "src/include/guc.h"

#include "src/include/tds_secure.h"
#include "src/include/tds_instr.h"

#include <sys/time.h>
#ifdef USE_OPENSSL
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif
#ifdef HAVE_NETINET_TCP_H
#include <netinet/tcp.h>
#endif

#ifdef ENABLE_SSPI
#define SECURITY_WIN32
#if defined(WIN32) && !defined(_MSC_VER)
#include <ntsecapi.h>
#endif
#include <security.h>
#undef SECURITY_WIN32

#ifndef ENABLE_GSS
/*
 * Define a fake structure compatible with GSSAPI on Unix.
 */
typedef struct
{
	void	   *value;
	int			length;
} gss_buffer_desc;
#endif
#endif							/* ENABLE_SSPI */

/*----------------------------------------------------------------
 * GSSAPI Authentication
 *----------------------------------------------------------------
 */
#ifdef ENABLE_GSS
#if defined(HAVE_GSSAPI_H)
#include <gssapi.h>
#else
#include <gssapi/gssapi.h>
#endif							/* HAVE_GSSAPI_H */
/*
 * GSSAPI brings in headers that set a lot of things in the global namespace on win32,
 * that doesn't match the msvc build. It gives a bunch of compiler warnings that we ignore,
 * but also defines a symbol that simply does not exist. Undefine it again.
 */
#ifdef _MSC_VER
#undef HAVE_GETADDRINFO
#endif

static int	SecureOpenServer(Port *port);
static void SendGSSAuthError(int severity, const char *errmsg, OM_uint32 maj_stat,
							 OM_uint32 min_stat);
static void SendGSSAuthResponse(Port *port, char *extradata, uint16_t extralen);
static int	CheckGSSAuth(Port *port);
#endif							/* ENABLE_GSS */

/* Global to store default collation info */
int			TdsDefaultLcid;
int			TdsDefaultCollationFlags;
uint8_t		TdsDefaultSortid;
pg_enc		TdsDefaultClientEncoding;

static void TdsDefineDefaultCollationInfo(void);

typedef struct LoginRequestData
{
	/* Fixed length attributes */
	uint32_t	length;
	uint32_t	tdsVersion;
	uint32_t	packetSize;
	uint32_t	clientProVersion;
	uint32_t	clientPid;
	uint32_t	connectionId;
	uint8_t		optionFlags1;	/* see above */
	uint8_t		optionFlags2;	/* see above */
	uint8_t		typeFlags;		/* see above */
	uint8_t		optionFlags3;	/* Reserved flags, see above */
	uint32_t	clientTimezone;
	uint32_t	clientLcid;		/* Language code identifier */

	/*
	 * The variable length attributes are stored in the following order in the
	 * login packet.  If a new entry has to be added in future, make sure to
	 * keep TDS_LOGIN_ATTR_MAX as the last index. For all fields, we always
	 * store null terminated strings.  Hence, we don't store the lengths.
	 */
#define TDS_LOGIN_ATTR_HOSTNAME 0
	char	   *hostname;
#define TDS_LOGIN_ATTR_USERNAME 1
	char	   *username;
#define TDS_LOGIN_ATTR_PASSWORD 2
	char	   *password;
#define TDS_LOGIN_ATTR_APPNAME 3
	char	   *appname;
#define TDS_LOGIN_ATTR_SERVERNAME 4
	char	   *servername;
#define TDS_LOGIN_ATTR_UNUSED 5
#define TDS_LOGIN_ATTR_LIBRARY 6
	char	   *library;
#define TDS_LOGIN_ATTR_LANGUAGE 7
	char	   *language;
#define TDS_LOGIN_ATTR_DATABASE 8
	char	   *database;
#define TDS_LOGIN_ATTR_MAX 9	/* should be last */

	/* the 6-byte client mac address */
	char		clientId[6];

	uint16_t	sspiLen;
	char	   *sspi;

	/* the Active Directory (AD) domain name */
	char	   *domainname;

	/* TODO: Feature data */

} LoginRequestData;

typedef LoginRequestData *LoginRequest;

#define SizeOfLoginRequestFixed (offsetof(LoginRequestData, clientLcid) + sizeof(uint32_t))

typedef struct PreLoginOption
{
	int8_t		token;
	uint16_t	offset;
	uint16_t	length;
	StringInfoData val;
	struct PreLoginOption *next;
} PreLoginOption;

PreLoginOption *TdsPreLoginRequest;
LoginRequest loginInfo = NULL;

static const char *PreLoginTokenType(uint8_t token);
static void DebugPrintPreLoginStructure(PreLoginOption *request);
static int	ParsePreLoginRequest();
static int *ProcessVersionNumber(const char *inputString);
static void SetPreLoginResponseVal(Port *port, uint8_t token,
								   StringInfo val, StringInfo reqVal,
								   bool loadSsl, int *loadEncryption);
static int	MakePreLoginResponse(Port *, bool);

static void ValidateLoginRequest(LoginRequest request);
static int	FetchLoginRequest(LoginRequest request);
static int	ProcessLoginInternal(Port *port);
static int	CheckAuthPassword(Port *port, const char **logdetail);
static void SendLoginError(Port *port, const char *logdetail);
static void GetLoginFlagsInstrumentation(LoginRequest loginInfo);
static void GetTDSVersionInstrumentation(uint32_t version);

/* Macros for OptionFlags1. */
#define LOGIN_OPTION_FLAGS1_BYTE_ORDER_68000	0x01
#define LOGIN_OPTION_FLAGS1_CHAR_EBCDIC		0x02
#define LOGIN_OPTION_FLAGS1_FLOAT_VAX		0x04
#define LOGIN_OPTION_FLAGS1_FLOAT_ND5000	0x08
#define LOGIN_OPTION_FLAGS1_DUMP_LOAD_OFF	0x10
#define LOGIN_OPTION_FLAGS1_USE_DB_ON		0x20
#define LOGIN_OPTION_FLAGS1_DATABASE_FATAL	0x40
#define LOGIN_OPTION_FLAGS1_SET_LANG_ON		0x80

/* Macros for OptionFlags2. */
#define LOGIN_OPTION_FLAGS2_LANGUAGE_FATAL	0x01
#define LOGIN_OPTION_FLAGS2_ODBC		0x02
#define LOGIN_OPTION_FLAGS2_TRAN_BOUNDARY	0x04
#define LOGIN_OPTION_FLAGS2_CACHE_CONNECT	0x08
#define LOGIN_OPTION_FLAGS2_USER_TYPE_SERVER	0x10
#define LOGIN_OPTION_FLAGS2_USER_TYPE_REMUSER	0x20
#define LOGIN_OPTION_FLAGS2_USER_TYPE_SQLREPL	0x30
#define LOGIN_OPTION_FLAGS2_INT_SECURITY_ON	0x80

/* Macros for TypeFlags */
#define LOGIN_TYPE_FLAGS_SQL_TSQL		0x01
#define LOGIN_TYPE_FLAGS_OLEDB			0x10
#define LOGIN_TYPE_FLAGS_READ_ONLY_INTENT	0x20

/* Macros for OptionFlags3. */
#define LOGIN_OPTION_FLAGS3_CHANGE_PASSWORD		0x01
#define LOGIN_OPTION_FLAGS3_USER_INSTANCE		0x02
#define LOGIN_OPTION_FLAGS3_SEND_YUKON_BINARY_XML	0x04
#define LOGIN_OPTION_FLAGS3_UNKNOWN_COLLATION_HANDLING	0x08
#define LOGIN_OPTION_FLAGS3_EXTENSION			0x10

#define TEXT_SIZE_2GB 0x7FFFFFFF
#define TEXT_SIZE_INFINITE 0xFFFFFFFF

static const char *
PreLoginTokenType(uint8_t token)
{
	const char *id = NULL;

	switch (token)
	{
		case TDS_PRELOGIN_VERSION:
			id = "TDS_PRELOGIN_VERSION (0x00)";
			break;
		case TDS_PRELOGIN_ENCRYPTION:
			id = "TDS_PRELOGIN_ENCRYPTION (0x01)";
			break;
		case TDS_PRELOGIN_INSTOPT:
			id = "TDS_PRELOGIN_INSTOPT (0x02)";
			break;
		case TDS_PRELOGIN_THREADID:
			id = "TDS_PRELOGIN_THREADID (0x03)";
			break;
		case TDS_PRELOGIN_MARS:
			id = "TDS_PRELOGIN_MARS (0x04)";
			break;
		case TDS_PRELOGIN_TRACEID:
			id = "TDS_PRELOGIN_TRACEID (0x05)";
			break;
		case TDS_PRELOGIN_FEDAUTHREQUIRED:
			id = "TDS_PRELOGIN_FEDAUTHREQUIRED (0x06)";
			break;
		case TDS_PRELOGIN_NONCEOPT:
			id = "TDS_PRELOGIN_NONCEOPT (0x07)";
			break;
		case TDS_PRELOGIN_TERMINATOR:
			id = "TDS_PRELOGIN_TERMINATOR (0xFF)";
			break;
		default:
			id = "unknown";
	}

	return id;
}

static void
DebugPrintPreLoginStructure(PreLoginOption *request)
{
	PreLoginOption *prev;
	StringInfoData s;
	int			i = 0;

	initStringInfo(&s);
	appendStringInfo(&s, "\nOption token: %s \n\t Option offset: %d \n\t Option Length: %d \n\t Version: %02x.%02x.%04x Subbuild: %04x ",
					 PreLoginTokenType(request->token), request->offset, request->length,
					 request->val.data[0], request->val.data[1], request->val.data[2], request->val.data[4]);
	prev = request->next;
	while (prev != NULL)
	{
		appendStringInfo(&s, "\nOption token: %s \n\t Option offset: %d \n\t Option Length: %d \n\t Data : ",
						 PreLoginTokenType(prev->token), prev->offset, prev->length);

		for (i = 0; i < prev->length; i++)
		{
			appendStringInfo(&s, "%02x", (unsigned char) prev->val.data[i]);
		}

		prev = prev->next;
	}

	if (!TDS_DEBUG_ENABLED(TDS_DEBUG3))
		return;
	if (s.len > 0)
		elog(LOG, "MESSAGE: \n %s", s.data);
	else
		elog(LOG, "MESSAGE: <empty>");
}


static int
ParsePreLoginRequest()
{
	uint16_t	data16;
	PreLoginOption *temp;
	PreLoginOption *prev = NULL;

	TdsErrorContext->reqType = TDS_PRELOGIN;
	while (1)
	{
		temp = palloc0(sizeof(PreLoginOption));
		if (TdsGetbytes((char *) (&temp->token), sizeof(temp->token)))
			return STATUS_ERROR;

		/* Terminator token */
		if (temp->token == -1)
		{
			temp->offset = 0;
			temp->length = 0;
			temp->next = NULL;
			initStringInfo(&temp->val);
			prev->next = temp;
			prev = prev->next;
			break;
		}
		if (TdsGetbytes((char *) &data16, sizeof(data16)))
			return STATUS_ERROR;
		temp->offset = pg_ntoh16(data16);
		if (TdsGetbytes((char *) &data16, sizeof(data16)))
			return STATUS_ERROR;
		temp->length = pg_ntoh16(data16);
		initStringInfo(&temp->val);

		temp->next = NULL;
		if (prev == NULL)
		{
			prev = temp;
			TdsPreLoginRequest = temp;
		}
		else
		{
			prev->next = temp;
			prev = prev->next;
		}
	}
	prev = TdsPreLoginRequest;
	while (prev->next != NULL)
	{
		if (TdsGetbytes(prev->val.data, prev->length))
			return STATUS_ERROR;
		prev = prev->next;
	}
	if (!TdsCheckMessageType(TDS_PRELOGIN))
		return STATUS_ERROR;

	DebugPrintPreLoginStructure(TdsPreLoginRequest);

	TDS_DEBUG(TDS_DEBUG1, "message_type: TDS7 Prelogin Message");

	return 0;
}
static int *
ProcessVersionNumber(const char *inputString)
{
	static int	version_arr[4];
	int			part = 0,
				len = 0;
	char	   *copy_version_number;
	char	   *token;

	Assert(inputString != NULL);
	len = strlen(inputString);
	copy_version_number = palloc0(len + 1);
	memcpy(copy_version_number, inputString, len);
	for (token = strtok(copy_version_number, "."); token; token = strtok(NULL, "."))
	{
		version_arr[part] = atoi(token);
		part++;
		Assert(part <= 4);
	}
	return version_arr;
}

static int
makeVersionByte(int byteNum)
{
	int		   *version_pnt;
	int			MajorVersion;
	int			MinorVersion;
	int			MicroVersion;

	Assert(product_version != NULL);
	Assert(byteNum <= 3);
	if (pg_strcasecmp(product_version, "default") == 0)
		version_pnt = ProcessVersionNumber(BABEL_COMPATIBILITY_VERSION);
	else
		version_pnt = ProcessVersionNumber(product_version);

	MajorVersion = *(version_pnt + 0);
	MinorVersion = *(version_pnt + 1);
	MicroVersion = *(version_pnt + 2);

	if (byteNum == 0)
	{
		return MajorVersion & 0xFF;
	}
	else if (byteNum == 1)
	{
		return MinorVersion & 0xFF;
	}
	else if (byteNum == 2)
	{
		if (MicroVersion <= 0xFF)
		{
			return 0x00;
		}
		else
		{
			return (MicroVersion >> 8) & 0xFF;
		}
	}
	else if (byteNum == 3)
	{
		return MicroVersion & 0xFF;
	}

	return 0;
}

static void
SetPreLoginResponseVal(Port *port, uint8_t token, StringInfo val,
					   StringInfo reqVal, bool loadSsl, int *loadEncryption)
{
	switch (token)
	{
		case TDS_PRELOGIN_VERSION:
			appendStringInfoChar(val, makeVersionByte(0));
			appendStringInfoChar(val, makeVersionByte(1));
			appendStringInfoChar(val, makeVersionByte(2));
			appendStringInfoChar(val, makeVersionByte(3));
			appendStringInfoChar(val, 0x00);
			appendStringInfoChar(val, 0x00);
			break;
		case TDS_PRELOGIN_ENCRYPTION:

			/*
			 * Support full encryption if server supports & client has
			 * requested ENCRYPT_ON or ENCRYPT_REQ, or Login7 request
			 * encryption if req = TDS_ENCRYPT_OFF or else TDS_ENCRYPT_OFF No
			 * SSL support - when disabled or on Unix sockets
			 */
			if (loadSsl && port->laddr.addr.ss_family != AF_UNIX)
			{
				if ((reqVal->data[0] == TDS_ENCRYPT_ON) ||
					(reqVal->data[0] == TDS_ENCRYPT_REQ))
				{
					appendStringInfoChar(val, TDS_ENCRYPT_ON);
					*loadEncryption = TDS_ENCRYPT_ON;
				}
				else if (reqVal->data[0] == TDS_ENCRYPT_OFF)
				{
					if (tds_ssl_encrypt)
					{
						appendStringInfoChar(val, TDS_ENCRYPT_REQ);
						*loadEncryption = TDS_ENCRYPT_REQ;
					}
					else
					{
						appendStringInfoChar(val, TDS_ENCRYPT_OFF);
						*loadEncryption = TDS_ENCRYPT_OFF;
					}
				}
				else if (reqVal->data[0] == TDS_ENCRYPT_NOT_SUP)
				{
					if (tds_ssl_encrypt)
					{
						appendStringInfoChar(val, TDS_ENCRYPT_REQ);
						*loadEncryption = TDS_ENCRYPT_REQ;
					}
					else
					{
						appendStringInfoChar(val, TDS_ENCRYPT_NOT_SUP);
						*loadEncryption = TDS_ENCRYPT_NOT_SUP;
					}
				}
				else
					elog(FATAL, "Certification 0x%02x not supported", (unsigned char) reqVal->data[0]);
			}
			else
			{
				appendStringInfoChar(val, TDS_ENCRYPT_NOT_SUP);
				*loadEncryption = TDS_ENCRYPT_NOT_SUP;
			}

			MyTdsEncryptOption = *loadEncryption;
			break;
		case TDS_PRELOGIN_INSTOPT:

			/*
			 * Val 00 - To indicate client's val matches server expectation
			 * Val 01 -	 Otherwise 01 to indicate client should terminate
			 * TODO:- Instead of fixed value, add the logic
			 */
			TDSInstrumentation(INSTR_UNSUPPORTED_TDS_PRELOGIN_INSTOPT);
			appendStringInfoChar(val, 0x00);
			break;
		case TDS_PRELOGIN_THREADID:
			TDSInstrumentation(INSTR_UNSUPPORTED_TDS_PRELOGIN_THREADID);
			break;
		case TDS_PRELOGIN_MARS:
			appendStringInfoChar(val, 0x00);
			break;
		case TDS_PRELOGIN_TRACEID:
			TDSInstrumentation(INSTR_UNSUPPORTED_TDS_PRELOGIN_TRACEID);
			break;
		case TDS_PRELOGIN_FEDAUTHREQUIRED:

			/*
			 * Should only be set when SSPI or FedAuth is supported Val 00 -
			 * SSPI supported Val 01 - FedAuth Supported
			 */
			TDSInstrumentation(INSTR_UNSUPPORTED_TDS_PRELOGIN_FEDAUTHREQUIRED);
			break;
		case TDS_PRELOGIN_NONCEOPT:
			/* Only used with FedAuth - Noop in our case */
			TDSInstrumentation(INSTR_UNSUPPORTED_TDS_PRELOGIN_NONCEOPT);
			break;
		case TDS_PRELOGIN_TERMINATOR:
			break;

	}
}

/*
 * MakePreLoginResponse - Sends the PreLogin response to the client, also decides
 * whether to load the encryption for the session
 *
 * Return Value:
 * Encryption option which can be
 * TDS_ENCRYPT_ON - Complete End to End Encryption
 * TDS_ENCRYPT_OFF - Login7 Encryption
 * TDS_ENCRYPT_NOT_SUP - No Encryption
 */
static int
MakePreLoginResponse(Port *port, bool loadSsl)
{
	uint16_t	temp16;
	PreLoginOption *preLoginResponse;
	PreLoginOption *tempRequest,
			   *temp,
			   *prev = NULL;
	int			offset = 0;
	int			loadEncryption = 0;

	preLoginResponse = palloc0(sizeof(PreLoginOption));

	/* Prepare the structure */
	tempRequest = TdsPreLoginRequest;

	while (tempRequest != NULL)
	{
		if (tempRequest->token != TDS_PRELOGIN_FEDAUTHREQUIRED)
		{
			temp = palloc0(sizeof(PreLoginOption));
			temp->token = tempRequest->token;
			initStringInfo(&temp->val);
			SetPreLoginResponseVal(port, temp->token, &temp->val, &tempRequest->val,
								   loadSsl, &loadEncryption);
			temp->length = temp->val.len;
			/* 1 - type, 2 - offsetlen, 2 - len */
			offset += 5;
			temp->next = NULL;
			if (prev == NULL)
			{
				preLoginResponse = temp;
				prev = temp;
			}
			else
			{
				prev->next = temp;
				prev = prev->next;
			}
		}
		tempRequest = tempRequest->next;
	}
	/* Terminator token doesn't have offset & len */
	offset -= 4;

	/* Add all the offset val */
	prev = preLoginResponse;
	while (prev != NULL)
	{
		prev->offset = offset;
		offset += prev->length;
		prev = prev->next;
	}
	/* Structure prepared, now print it */
	DebugPrintPreLoginStructure(preLoginResponse);

	/* Prepare the response message */
	TdsSetMessageType(TDS_RESPONSE);
	prev = preLoginResponse;
	while (prev->next != NULL)
	{
		TdsPutbytes(&(prev->token), sizeof(prev->token));
		temp16 = pg_hton16(prev->offset);
		TdsPutbytes(&temp16, sizeof(temp16));
		temp16 = pg_hton16(prev->length);
		TdsPutbytes(&temp16, sizeof(temp16));
		prev = prev->next;
	}
	/* Terminator token */
	TdsPutbytes(&(prev->token), sizeof(prev->token));

	prev = preLoginResponse;
	while (prev != NULL)
	{
		TdsPutbytes(prev->val.data, prev->val.len);
		prev = prev->next;
	}

	/* Free the PreLogin Structures */
	prev = TdsPreLoginRequest;
	while (prev != NULL)
	{
		pfree(prev->val.data);
		temp = prev->next;
		pfree(prev);
		prev = temp;
	}
	prev = preLoginResponse;
	while (prev != NULL)
	{
		pfree(prev->val.data);
		temp = prev->next;
		pfree(prev);
		prev = temp;
	}
	return loadEncryption;
}

/*
 * ValidateLoginRequest - Validate the login request according to the TDS
 * specifications.
 */
static void
ValidateLoginRequest(LoginRequest request)
{
	/* TODO: do the sanity checks */

	uint32_t	version;

	/* Use the GUC's values, if set. */
	if (tds_default_protocol_version > 0)
		request->tdsVersion = tds_default_protocol_version;
	version = request->tdsVersion;

	/* TDS Version must be valid */
	if (!(version == TDS_VERSION_7_0 ||
		  version == TDS_VERSION_7_1 ||
		  version == TDS_VERSION_7_1_1 ||
		  version == TDS_VERSION_7_2 ||
		  version == TDS_VERSION_7_3_A ||
		  version == TDS_VERSION_7_3_B ||
		  version == TDS_VERSION_7_4))
		elog(FATAL, "invalid TDS Version: %X", version);

	GetTDSVersionInstrumentation(version);

	/* TDS Version 7.0 is unsupported */
	if (version == TDS_VERSION_7_0)
		elog(FATAL, "unsupported TDS Version: %X", version);

	/*
	 * The packet size must be greater than or equal to 512 bytes and smaller
	 * than or equal to 32,767 bytes.  Or, the packet size can be 0 in which
	 * case we should use the server default.
	 */
	if (request->packetSize != TDS_USE_SERVER_DEFAULT_PACKET_SIZE &&
		(request->packetSize < 512 || request->packetSize > 32767))
		elog(FATAL, "Invalid packet size: %u, Packet size has to be zero or "
			 "a number between 512 and 32767.", request->packetSize);
}

/*
 * FetchLoginRequest - Fetch and parse TDS login packet
 *
 * RETURNS: STATUS_OK or STATUS_ERROR
 */
static int
FetchLoginRequest(LoginRequest request)
{
	uint32_t	attrs[TDS_LOGIN_ATTR_MAX];
	uint32_t	sspiOffsetLen;
	StringInfoData buf;
	StringInfoData temp_utf8;
	int			i,
				read = 0;

	Assert(request != NULL);

	TdsErrorContext->reqType = TDS_LOGIN7;
#ifdef WORDS_BIGENDIAN

	/*
	 * Are we going to support this?
	 */
	Assert(0);
#endif

	/*
	 * The client writes all other bytes except clientProVersion in
	 * little-endian.  Hence, we can read everything at once.  No endian
	 * conversion is needed.
	 */
	if (TdsGetbytes((char *) request, SizeOfLoginRequestFixed))
		return STATUS_ERROR;

	/*
	 * The length of a LOGIN7 stream MUST NOT be longer than 128K-1(byte)
	 * bytes
	 */
	if (request->length > 128 * 1024)
		return STATUS_ERROR;

	read += SizeOfLoginRequestFixed;

	/* At any point, read CANNOT be greater than length of login stream */
	if (read > request->length)
		return STATUS_ERROR;

	/* Check we indeed got the correct packet */
	if (!TdsCheckMessageType(TDS_LOGIN7))
		return STATUS_ERROR;

	/* fix the client version now */
	request->clientProVersion = pg_bswap32(request->clientProVersion);

	/* Let's read the {offset, length} array now. */
	if (TdsGetbytes((char *) attrs, TDS_LOGIN_ATTR_MAX * sizeof(uint32_t)))
		return STATUS_ERROR;

	read += TDS_LOGIN_ATTR_MAX * sizeof(uint32_t);

	if (read > request->length)
		return STATUS_ERROR;

	/* 6-bytes Client MAC Address */
	if (TdsGetbytes((char *) request->clientId, sizeof(request->clientId)))
		return STATUS_ERROR;

	read += sizeof(request->clientId);

	if (read > request->length)
		return STATUS_ERROR;

	/* SSPI data */
	if (TdsGetbytes((char *) &sspiOffsetLen, sizeof(sspiOffsetLen)))
		return STATUS_ERROR;

	read += sizeof(sspiOffsetLen);

	if (read > request->length)
		return STATUS_ERROR;

	/*
	 * It follows the following data that we're going to discard for now: 1.
	 * Database to attach during connection process 2. New password for the
	 * specified login. Introduced in TDS 7.2 3. Used for large SSPI data when
	 * cbSSPI==USHORT_MAX. Introduced in TDS 7.2
	 */

	initStringInfo(&buf);
	initStringInfo(&temp_utf8);

	/* Now, read from the offsets */
	for (i = 0; i < TDS_LOGIN_ATTR_MAX; i++)
	{
		uint16_t	offset = (uint16_t) attrs[i];
		uint16_t	length = (uint16_t) (attrs[i] >> 16);

		if (length > 0)
		{
			/* Skip bytes till the offset */
			if (TdsDiscardbytes(offset - read))
			{
				pfree(temp_utf8.data);
				pfree(buf.data);
				return STATUS_ERROR;
			}

			read = offset;

			/*
			 * The hostname, username, password, appname, servername, library
			 * name, language and database name MUST specify at most 128
			 * characters
			 */
			if (length > 128)
				return STATUS_ERROR;

			if (i == TDS_LOGIN_ATTR_UNUSED)
			{
				if (TdsDiscardbytes(length))
				{
					pfree(temp_utf8.data);
					pfree(buf.data);
					return STATUS_ERROR;
				}

				read += length;

				if (read > request->length)
					return STATUS_ERROR;

				continue;
			}

			/* Since, it has UTF-16 format */
			length *= 2;

			resetStringInfo(&buf);
			enlargeStringInfo(&buf, length);

			if (TdsGetbytes(buf.data, length))
			{
				pfree(temp_utf8.data);
				pfree(buf.data);
				return STATUS_ERROR;
			}

			read += length;

			if (read > request->length)
				return STATUS_ERROR;

			buf.len += length;

			/*
			 * The password field is an obfusticated unicode string.  So,
			 * we've to handle it differently.
			 */
			if (i == TDS_LOGIN_ATTR_PASSWORD)
			{
				int			j;

				for (j = 0; j < length; j++)
				{
					uint8_t		p = buf.data[j];

					p = (((p & 0xff) ^ 0xA5) << 4) | (((p & 0xff) ^ 0xA5) >> 4);
					buf.data[j] = p & 0xff;
				}

			}

			TdsUTF16toUTF8StringInfo(&temp_utf8, buf.data, length);

			switch (i)
			{
				case TDS_LOGIN_ATTR_HOSTNAME:
					request->hostname = pstrdup(temp_utf8.data);
					MyTdsHostName = request->hostname;
					break;
				case TDS_LOGIN_ATTR_USERNAME:
					request->username = pstrdup(temp_utf8.data);
					break;
				case TDS_LOGIN_ATTR_PASSWORD:
					request->password = pstrdup(temp_utf8.data);
					break;
				case TDS_LOGIN_ATTR_APPNAME:
					request->appname = pstrdup(temp_utf8.data);
					break;
				case TDS_LOGIN_ATTR_SERVERNAME:
					request->servername = pstrdup(temp_utf8.data);
					break;
				case TDS_LOGIN_ATTR_LIBRARY:
					request->library = pstrdup(temp_utf8.data);
					MyTdsLibraryName = request->library;
					break;
				case TDS_LOGIN_ATTR_LANGUAGE:
					request->language = pstrdup(temp_utf8.data);
					break;
				case TDS_LOGIN_ATTR_DATABASE:
					request->database = pstrdup(temp_utf8.data);
					break;
				default:
					/* shouldn't reach here */
					Assert(0);
					break;
			}
			resetStringInfo(&temp_utf8);
		}
	}

	pfree(temp_utf8.data);
	pfree(buf.data);

	if (sspiOffsetLen > 0)
	{
		uint16_t	offset = (uint16_t) sspiOffsetLen;

		request->sspiLen = (uint16_t) (sspiOffsetLen >> 16);

		if (request->sspiLen > 0)
		{
			const char *is_windows_allowed = GetConfigOption("babelfishpg_tsql.allow_windows_login", true, false);

			if (is_windows_allowed && strncasecmp(is_windows_allowed, "false", 5) == 0)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Windows login is not supported in babelfish")));

			/*
			 * XXX: large SSPI data when length==USHORT_MAX - not supported
			 * yet
			 */
			if (request->sspiLen == -1)
			{
				TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_CB_SSPI_LONG);
				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("large SSPI is not supported yet")));
			}


			/* Skip bytes till the offset */
			if (TdsDiscardbytes(offset - read))
			{
				pfree(temp_utf8.data);
				pfree(buf.data);
				return STATUS_ERROR;
			}

			read = offset;

			request->sspi = palloc(request->sspiLen);

			if (TdsGetbytes(request->sspi, request->sspiLen))
			{
				pfree(temp_utf8.data);
				pfree(buf.data);
				return STATUS_ERROR;
			}

			read += request->sspiLen;
		}
	}

	/* Now, discard rest of the bytes, if any */
	if (TdsDiscardbytes((size_t) (request->length - read)))
		return STATUS_ERROR;

	DebugPrintLoginMessage(request);

	TDS_DEBUG(TDS_DEBUG1, "message_type: TDS7 Login");

	return STATUS_OK;
}

/*
 * ProcessLoginFlags -- Processes the information stored in the following Flags:
 *
 * 1. information stored in optionFlags1 (in least significant bit order):
 * fByteOrder:	0 = ORDER_X86, 1 = ORDER_68000
 * 				The byte order used by client for numeric and datetime data types.
 * fChar:	0 = CHARSET_ASCII, 1 = CHARSET_EBCDIC
 * 				The character set used on the client.
 * fFloat:	0 = FLOAT_IEEE_754, 1 = FLOAT_VAX, 2 = ND5000
 * 				The type of floating point representation used by the client.
 * fDumpLoad:	0 = DUMPLOAD_ON, 1 = DUMPLOAD_OFF
 * 				Set if dump/load or BCP capabilities are needed by the client.
 * fUseDB:	0 = USE_DB_OFF, 1 = USE_DB_ON
 * 				Set if the client requires warning messages on execution of the USE
 * 				SQL statement. If this flag is not set, the server MUST NOT inform
 * 				the client when the database changes, and therefore the client will
 * 				be unaware of any accompanying collation changes.
 * fDatabase:	0 = INIT_DB_WARN, 1 = INIT_DB_FATAL
 * 				Set if the change to initial database needs to succeed if the
 * 				connection is to succeed.
 * fSetLang: 			0 = SET_LANG_OFF, 1 = SET_LANG_ON
 * 				Set if the client requires warning messages on execution of a language
 * 				change statement.
 *
 * 2. information stored in optionFlags2 (in least significant bit order):
 * fLanguage: 	0 = INIT_LANG_WARN, 1 = INIT_LANG_FATAL
 * 				Set if the change to initial language needs to succeed if the
 * 				connect is to succeed.
 * fODBC: 		0 = ODBC_OFF, 1 = ODBC_ON
 * 				Set if the client is the ODBC driver. This causes the server to
 * 				set ANSI_DEFAULTS to ON, CURSOR_CLOSE_ON_COMMIT and
 * 				IMPLICIT_TRANSACTIONS to OFF, TEXTSIZE to 0x7FFFFFFF (2GB)
 * 				(TDS 7.2 and earlier), TEXTSIZE to infinite (introduced in
 * 				TDS 7.3), and ROWCOUNT to infinite.
 * fTransBoundary
 * fCacheConnect
 * fUserType: 	0 = USER_NORMAL—regular logins,
 * 				1 = USER_SERVER—reserved,
 * 				2 = USER_REMUSER—Distributed Query login,
 * 				3 = USER_SQLREPL—replication login
 * 				The type of user connecting to the server.
 * fIntSecurity: 0 = INTEGRATED_SECURTY_OFF, 1 = INTEGRATED_SECURITY_ON
 * 				The type of security required by the client.
 *
 * 3. information stored in typeFlags (in least significant bit order):
 * fSQLType:	0 = SQL_DFLT, 1 = SQL_TSQL
 * 				The type of SQL the client sends to the server.
 * fOLEDB:		0 = OLEDB_OFF, 1 = OLEDB_ON
 *				Set if the client is the OLEDB driver. This causes the server
 *				to set ANSI_DEFAULTS to ON, CURSOR_CLOSE_ON_COMMIT and
 *				IMPLICIT_TRANSACTIONS to OFF, TEXTSIZE to 0x7FFFFFFF (2GB)
 *				(TDS 7.2 and earlier), TEXTSIZE to infinite (introduced in
 *				TDS 7.3), and ROWCOUNT to infinite.<21>
 * fReadOnlyIntent: This bit was introduced in TDS 7.4; however, TDS 7.1, 7.2,
 * 				and 7.3 clients can also use this bit in LOGIN7 to specify
 * 				that the application intent of the connection is read-only. The
 * 				server SHOULD ignore this bit if the highest TDS version
 * 				supported by the server is lower than TDS 7.4.
 *
 * 4. information stored in optionFlags3 (in least significant bit order):
 * fChangePassword: 	0 = No change request. ibChangePassword MUST be 0.
 * 						1 = Request to change login's password.
 * 						Specifies whether the login request SHOULD change password.
 * fSendYukonBinaryXML: 1 if XML data type instances are returned as binary XML.
 * fUserInstance: 		1 if client is requesting separate process to be spawned
 * 						as user instance.
 * fUnknownCollationHandling:
 * 						0 = The server MUST restrict the collations sent
 * 						to a specific set of collations. It MAY disconnect or
 * 						send an error if some other value is outside the specific
 * 						collation set. The client MUST properly support all
 * 						collations within the collation set.
 *					 	1 = The server MAY send any collation that fits in the
 *						storage space. The client MUST be able to both properly
 *						support collations and gracefully fail for those it does
 *						not support. This bit is used by the server to determine
 *						if a client is able to properly handle collations introduced
 *						after TDS 7.2. TDS 7.2 and earlier clients are encouraged
 *						to use this login packet bit. Servers MUST ignore this
 *						bit when it is sent by TDS 7.3 or 7.4 clients. See
 *						[MSDN-SQLCollation] and [MS-LCID] for the complete list
 *						of collations for a database server that supports SQL
 *						and LCIDs.
 * fExtension: 			0 = ibExtension/cbExtension fields are not used. The
 * 						fields are treated the same as ibUnused/cchUnused.
 * 						1 = ibExtension/cbExtension fields are used.
 * 						Specifies whether ibExtension/cbExtension fields are used.
 */
static void
ProcessLoginFlags(LoginRequest loginInfo)
{
	GetLoginFlagsInstrumentation(loginInfo);

	/* fODBC and fOLEDB */
	if ((loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_ODBC) ||
		(loginInfo->typeFlags & LOGIN_TYPE_FLAGS_OLEDB))
	{
		char	   *textSize = psprintf("%d", (loginInfo->tdsVersion <= TDS_VERSION_7_2) ?
										TEXT_SIZE_2GB : TEXT_SIZE_INFINITE);
		char	   *rowCount = psprintf("%d", INT_MAX);

		set_config_option("babelfishpg_tsql.ansi_defaults",
						  "ON",
						  PGC_USERSET,
						  PGC_S_OVERRIDE,
						  GUC_ACTION_SET,
						  true,
						  0,
						  false);

		set_config_option("babelfishpg_tsql.implicit_transactions",
						  "OFF",
						  PGC_USERSET,
						  PGC_S_OVERRIDE,
						  GUC_ACTION_SET,
						  true,
						  0,
						  false);
		set_config_option("babelfishpg_tsql.cursor_close_on_commit",
						  "OFF",
						  PGC_USERSET,
						  PGC_S_OVERRIDE,
						  GUC_ACTION_SET,
						  true,
						  0,
						  false);
		set_config_option("babelfishpg_tsql.textsize",
						  textSize,
						  PGC_USERSET,
						  PGC_S_OVERRIDE,
						  GUC_ACTION_SET,
						  true,
						  0,
						  false);
		set_config_option("babelfishpg_tsql.rowcount",
						  rowCount,
						  PGC_USERSET,
						  PGC_S_OVERRIDE,
						  GUC_ACTION_SET,
						  true,
						  0,
						  false);
	}

	if (loginInfo->optionFlags3 & LOGIN_OPTION_FLAGS3_CHANGE_PASSWORD)
	{
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS3_CHANGE_PASSWORD);
		ereport(FATAL,
				errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
				errmsg("Password change request is not supported"));
	}
}

/*
 * TdsResetLoginFlags - Resets the session properties which
 * we provided during login time.
 * Wrapper of ProcessLoginFlags, since we do not expose loginInfo.
 */
void
TdsResetLoginFlags()
{
	ProcessLoginFlags(loginInfo);
}

/*
 * ProcessLoginInternal - internal workhorse for processing login
 * request.
 *
 * Read a TDS client's login packet and do something according to it.
 *
 * Returns STATUS_OK or STATUS_ERROR, or might call ereport(FATAL) and
 * not return at all.
 */
static int
ProcessLoginInternal(Port *port)
{
	MemoryContext oldContext;
	LoginRequest request;
	const char *gucDatabaseName = GetConfigOption("babelfishpg_tsql.database_name", true, false);

	if (gucDatabaseName == NULL)
		ereport(FATAL, (errcode(ERRCODE_UNDEFINED_OBJECT),
						errmsg("Configuration parameter \"babelfishpg_tsql.database_name\" is not defined"),
						errhint("Set GUC value by specifying it in postgresql.conf or by ALTER SYSTEM")));

	/*
	 * We want to keep all login related information around even after
	 * postmaster context gets deleted and after a connection reset.
	 */
	oldContext = MemoryContextSwitchTo(TopMemoryContext);

	/* We're allocating the memory in postmaster context. */
	request = palloc0(sizeof(LoginRequestData));

	TdsErrorContext->err_text = "Fetch Login Request";
	/* fetch and parse the login packet */
	if (FetchLoginRequest(request) != STATUS_OK)
		return STATUS_ERROR;

	TdsErrorContext->err_text = "Validate Login Request";
	/* validate the login request */
	ValidateLoginRequest(request);

	/*
	 * Downcase and copy the username and database name in port structure so
	 * that no one messes up with the local copy.
	 */
	if (request->username != NULL)
	{
		request->username = downcase_identifier(request->username,
												strlen(request->username),
												false,
												false);
		port->user_name = pstrdup(request->username);
	}
	if (request->database != NULL)
	{
		request->database = downcase_identifier(request->database,
												strlen(request->database),
												false,
												false);
		port->database_name = pstrdup(request->database);
	}

	/*
	 * We set application name in port structure in case we want to log
	 * connections in future.
	 */
	if (request->appname != NULL)
	{
		port->application_name = pg_clean_ascii(request->appname, 0);
	}

	/*
	 * If GUC "babelfishpg_tsql.database_name" is not "none" then database
	 * name specified in login request is overridden by
	 * "babelfish_pgtsql.database_name"
	 */
	if (gucDatabaseName != NULL && strcmp(gucDatabaseName, "none") != 0)
		port->database_name = pstrdup(gucDatabaseName);

	if (request->sspiLen > 0)
	{
		char		tempusername[10] = "<unknown>";

		port->user_name = pstrdup(tempusername);
	}

	/* Check a user name was given. */
	if (port->user_name == NULL || port->user_name[0] == '\0')
		ereport(FATAL,
				errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
				errmsg("no PostgreSQL user name specified in startup packet"));

	/* The database defaults to the user name. */
	if (port->database_name == NULL || port->database_name[0] == '\0')
		port->database_name = pstrdup(TSQL_DEFAULT_DB);

	/* save the login information for the entire session */
	loginInfo = request;

	/*
	 * Truncate given database and user names to length of a Postgres name.
	 * This avoids lookup failures when overlength names are given.
	 */
	if (strlen(port->database_name) >= NAMEDATALEN)
		port->database_name[NAMEDATALEN - 1] = '\0';
	if (strlen(port->user_name) >= NAMEDATALEN)
		port->user_name[NAMEDATALEN - 1] = '\0';

	/*
	 * Done putting stuff in TopMemoryContext.
	 */
	MemoryContextSwitchTo(oldContext);

	/*
	 * If we're going to reject the connection due to database state, say so
	 * now instead of wasting cycles on an authentication exchange. (This also
	 * allows a pg_ping utility to be written.)
	 */
	switch (port->canAcceptConnections)
	{
		case CAC_STARTUP:
			ereport(FATAL,
					errcode(ERRCODE_CANNOT_CONNECT_NOW),
					errmsg("the database system is starting up"));
			break;
		case CAC_NOTCONSISTENT:
			if (EnableHotStandby)
				ereport(FATAL,
						(errcode(ERRCODE_CANNOT_CONNECT_NOW),
						 errmsg("the database system is not yet accepting connections"),
						 errdetail("Consistent recovery state has not been yet reached.")));
			else
				ereport(FATAL,
						(errcode(ERRCODE_CANNOT_CONNECT_NOW),
						 errmsg("the database system is not accepting connections"),
						 errdetail("Hot standby mode is disabled.")));
			break;
		case CAC_SHUTDOWN:
			ereport(FATAL,
					errcode(ERRCODE_CANNOT_CONNECT_NOW),
					errmsg("the database system is shutting down"));
			break;
		case CAC_RECOVERY:
			ereport(FATAL,
					errcode(ERRCODE_CANNOT_CONNECT_NOW),
					errmsg("the database system is in recovery mode"));
			break;
		case CAC_TOOMANY:
			ereport(FATAL,
					errcode(ERRCODE_TOO_MANY_CONNECTIONS),
					errmsg("sorry, too many clients already"));
			break;
		case CAC_OK:
			break;
	}

	TdsErrorContext->err_text = "Process Login Flags";
	ProcessLoginFlags(loginInfo);

	MyTdsClientVersion = loginInfo->clientProVersion;
	MyTdsClientPid = loginInfo->clientPid;
	MyTdsProtocolVersion = loginInfo->tdsVersion;
	MyTdsPacketSize = loginInfo->packetSize;

	return STATUS_OK;
}

/*
 * Plaintext password authentication.
 */
static int
CheckAuthPassword(Port *port, const char **logdetail)
{
	char	   *passwd;
	int			result;
	const char *shadowPass;

	passwd = loginInfo->password;

	if (passwd == NULL)
		return STATUS_EOF;		/* client wouldn't send password */

	shadowPass = get_role_password(port->user_name, logdetail);
	if (shadowPass)
	{
		result = plain_crypt_verify(port->user_name, shadowPass, passwd,
									logdetail);
	}
	else
		result = STATUS_ERROR;

	if (shadowPass)
		pfree((char *) shadowPass);
	pfree(passwd);

	/* since we've freed the password, set it to NULL */
	loginInfo->password = NULL;

	return result;
}

/*----------------------------------------------------------------
 * GSSAPI authentication system
 *----------------------------------------------------------------
 */
#ifdef ENABLE_GSS

#if defined(WIN32) && !defined(_MSC_VER)
/*
 * MIT Kerberos GSSAPI DLL doesn't properly export the symbols for MingW
 * that contain the OIDs required. Redefine here, values copied
 * from src/athena/auth/krb5/src/lib/gssapi/generic/gssapi_generic.c
 */
static const gss_OID_desc GSS_C_NT_USER_NAME_desc =
{10, (void *) "\x2a\x86\x48\x86\xf7\x12\x01\x02\x01\x02"};
static GSS_DLLIMP gss_OID GSS_C_NT_USER_NAME = &GSS_C_NT_USER_NAME_desc;
#endif


/*
 * Generate an error for GSSAPI authentication.  The caller should apply
 * _() to errmsg to make it translatable.
 *
 * This function is similar to pg_GSS_Error().
 */
static void
SendGSSAuthError(int severity, const char *errmsg, OM_uint32 maj_stat, OM_uint32 min_stat)
{
	gss_buffer_desc gmsg;
	OM_uint32	lmin_s,
				msg_ctx;
	char		msg_major[128],
				msg_minor[128];

	/* Fetch major status message */
	msg_ctx = 0;
	gss_display_status(&lmin_s, maj_stat, GSS_C_GSS_CODE,
					   GSS_C_NO_OID, &msg_ctx, &gmsg);
	strlcpy(msg_major, gmsg.value, sizeof(msg_major));
	gss_release_buffer(&lmin_s, &gmsg);

	if (msg_ctx)

		/*
		 * More than one message available. XXX: Should we loop and read all
		 * messages? (same below)
		 */
		ereport(WARNING,
				(errmsg_internal("incomplete GSS error report")));

	/* Fetch mechanism minor status message */
	msg_ctx = 0;
	gss_display_status(&lmin_s, min_stat, GSS_C_MECH_CODE,
					   GSS_C_NO_OID, &msg_ctx, &gmsg);
	strlcpy(msg_minor, gmsg.value, sizeof(msg_minor));
	gss_release_buffer(&lmin_s, &gmsg);

	if (msg_ctx)
		ereport(WARNING,
				(errmsg_internal("incomplete GSS minor error report")));

	/*
	 * errmsg_internal, since translation of the first part must be done
	 * before calling this function anyway.
	 */
	ereport(severity,
			(errmsg_internal("%s", errmsg),
			 errdetail_internal("%s: %s", msg_major, msg_minor)));
}

static void
SendGSSAuthResponse(Port *port, char *extradata, uint16_t extralen)
{
	/*
	 * If not already in RESPONSE mode, switch the TDS protocol to RESPONSE
	 * mode.
	 */
	TdsSetMessageType(TDS_RESPONSE);

	TdsPutInt8(TDS_TOKEN_SSPI);
	TdsPutInt16LE(extralen);
	TdsPutbytes(extradata, extralen);

	TdsFlush();

	TDSInstrumentation(INSTR_TDS_TOKEN_SSPI);
}

static char *
convertUsernameToCanonicalform(char *user_name)
{
	char	   *canonicalUsername = "";
	char	   *chr;

	if ((chr = strchr(user_name, '@')) != NULL)
	{
		canonicalUsername = psprintf("%s%s",
									 str_tolower(user_name, (chr - user_name), C_COLLATION_OID),
									 str_toupper(chr, strlen(chr), C_COLLATION_OID));
		return canonicalUsername;
	}
	return user_name;
}

/*
 * This function is similar to pg_GSS_recvauth() but to authenticate a TDS
 * client.
 */
static int
CheckGSSAuth(Port *port)
{
	LoginRequest request = loginInfo;
	OM_uint32	maj_stat,
				min_stat,
				lmin_s,
				gflags;
	int			ret;
	gss_buffer_desc gbuf;
	MemoryContext oldContext;
	char	   *at_pos = NULL;
	char	   *princ;

	if (pg_krb_server_keyfile && strlen(pg_krb_server_keyfile) > 0)
	{
		/*
		 * Set default Kerberos keytab file for the Krb5 mechanism.
		 *
		 * setenv("KRB5_KTNAME", pg_krb_server_keyfile, 0); except setenv()
		 * not always available.
		 */
		if (getenv("KRB5_KTNAME") == NULL)
		{
			size_t		kt_len = strlen(pg_krb_server_keyfile) + 14;
			char	   *kt_path = malloc(kt_len);

			if (!kt_path ||
				snprintf(kt_path, kt_len, "KRB5_KTNAME=%s",
						 pg_krb_server_keyfile) != kt_len - 2 ||
				putenv(kt_path) != 0)
			{
				ereport(LOG,
						(errcode(ERRCODE_OUT_OF_MEMORY),
						 errmsg("out of memory")));
				return STATUS_ERROR;
			}
		}
	}

	/*
	 * We accept any service principal that's present in our keytab. This
	 * increases interoperability between kerberos implementations that see
	 * for example case sensitivity differently, while not really opening up
	 * any vector of attack.
	 */
	port->gss->cred = GSS_C_NO_CREDENTIAL;

	/*
	 * Initialize sequence with an empty context
	 */
	port->gss->ctx = GSS_C_NO_CONTEXT;

	do
	{
		/* Map to GSSAPI style buffer */
		gbuf.length = request->sspiLen;
		gbuf.value = request->sspi;

		elog(DEBUG4, "Processing received GSS token of length %u",
			 (unsigned int) gbuf.length);

		maj_stat = gss_accept_sec_context(
										  &min_stat,
										  &port->gss->ctx,
										  port->gss->cred,
										  &gbuf,
										  GSS_C_NO_CHANNEL_BINDINGS,
										  &port->gss->name,
										  NULL,
										  &port->gss->outbuf,
										  &gflags,
										  NULL,
										  NULL);

		elog(DEBUG4, "gss_accept_sec_context major: %d, "
			 "minor: %d, outlen: %u, outflags: %x",
			 maj_stat, min_stat,
			 (unsigned int) port->gss->outbuf.length, gflags);

		if (port->gss->outbuf.length != 0)
		{
			/*
			 * Negotiation generated data to be sent to the client.
			 */
			elog(DEBUG4, "sending GSS response token of length %u",
				 (unsigned int) port->gss->outbuf.length);

			SendGSSAuthResponse(port, port->gss->outbuf.value,
								port->gss->outbuf.length);

			gss_release_buffer(&lmin_s, &port->gss->outbuf);
		}

		if (maj_stat != GSS_S_COMPLETE && maj_stat != GSS_S_CONTINUE_NEEDED)
		{
			gss_delete_sec_context(&lmin_s, &port->gss->ctx, GSS_C_NO_BUFFER);
			SendGSSAuthError(ERROR,
							 _("accepting GSS security context failed"),
							 maj_stat, min_stat);
		}

		/*
		 * XXX: First we need a reproducible case to implement the following
		 * feature.
		 */
		if (maj_stat == GSS_S_CONTINUE_NEEDED)
		{
			TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_GSS_S_CONTINUE_NEEDED);
			elog(FATAL, "GSS continue needed - not supported yet");
		}

	} while (maj_stat == GSS_S_CONTINUE_NEEDED);

	if (port->gss->cred != GSS_C_NO_CREDENTIAL)
	{
		/*
		 * Release service principal credentials
		 */
		gss_release_cred(&min_stat, &port->gss->cred);
	}

	/*
	 * GSS_S_COMPLETE indicates that authentication is now complete.
	 *
	 * Get the name of the user that authenticated, and compare it to the pg
	 * username that was specified for the connection.
	 */
	maj_stat = gss_display_name(&min_stat, port->gss->name, &gbuf, NULL);
	if (maj_stat != GSS_S_COMPLETE)
		SendGSSAuthError(ERROR,
						 _("retrieving GSS user name failed"),
						 maj_stat, min_stat);

	/*
	 * gbuf.value might not be null-terminated, so turn it into a regular
	 * null-terminated string.
	 */
	princ = palloc(gbuf.length + 1);
	memcpy(princ, gbuf.value, gbuf.length);
	princ[gbuf.length] = '\0';

	/*
	 * Copy the original name of the authenticated principal into our backend
	 * memory for display later.
	 *
	 * This is also our authenticated identity.  Set it now, rather than
	 * waiting for the usermap check below, because authentication has already
	 * succeeded and we want the log file to reflect that.
	 */
	port->gss->princ = MemoryContextStrdup(TopMemoryContext, princ);

	/*
	 * XXX: In PG there are options to match realm names or perform ident
	 * mappings. We're not going to do those checks now.  If required, we can
	 * implement the same in future. For now, we just get the realm(domain)
	 * name and store it in loginInfo.
	 *
	 * We also include the realm name along with username.  And, we don't
	 * support stripping off the realm name from username.  So, an username
	 * will always have the following format: username@realname.
	 */

	oldContext = MemoryContextSwitchTo(TopMemoryContext);
	pfree(port->user_name);
	port->user_name = convertUsernameToCanonicalform(gbuf.value);

	/* Assign canonical form username to loginInfo->username. */
	loginInfo->username = pstrdup(port->user_name);
	if ((at_pos = strchr(gbuf.value, '@')) != NULL && loginInfo)
	{
		/* skip '@' */
		at_pos++;
		loginInfo->domainname = pstrdup(at_pos);
	}
	MemoryContextSwitchTo(oldContext);

	ret = STATUS_OK;
	gss_release_buffer(&lmin_s, &gbuf);

	return ret;
}
#endif							/* ENABLE_GSS */

static void
SendLoginError(Port *port, const char *logdetail)
{
	LoginRequest request = loginInfo;

	if (request->sspiLen > 0)
		ereport(FATAL,
				errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
				errmsg("GSSAPI authentication failed"));
	else
		ereport(FATAL,
				errcode(ERRCODE_SQLSERVER_REJECTED_ESTABLISHMENT_OF_SQLCONNECTION),
				errmsg("Login failed for user \"%s\"",
					   request->username));
}

/*
 * TdsClientAuthentication - Similar to ClientAuthentication, but specific
 * to TDS client authentication
 *
 * TDS Client authentication starts here.  If there is an error, this function
 * does not return and the backend process is terminated.
 *
 * Note that this method should be called in postmaster context so that we can
 * access the login request information.
 */
void
TdsClientAuthentication(Port *port)
{
	int			status = STATUS_ERROR;
	const char *logdetail = NULL;
#ifdef ENABLE_GSS
	StringInfoData ps_data;
#endif

	if (loginInfo->sspiLen > 0)
	{
#ifdef ENABLE_GSS

		/* NTLMSSP Authentication Isn't Supported yet. */
		if (strcmp(loginInfo->sspi, "NTLMSSP") == 0)
		{
			TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_NTLMSSP);

			ereport(FATAL,
					(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
					 errmsg("Authentication method \"NTLMSSP\" not supported")));
		}

		/* We might or might not have the gss workspace already */
		if (port->gss == NULL)
			port->gss = (pg_gssinfo *)
				MemoryContextAllocZero(TopMemoryContext,
									   sizeof(pg_gssinfo));
		port->gss->auth = true;

		status = CheckGSSAuth(port);

		if (status == STATUS_ERROR)
			SendLoginError(port, logdetail);

		if (status != STATUS_ERROR)
			TDSInstrumentation(INSTR_TDS_LOGIN_ACTIVE_DIRECTORY);

		initStringInfo(&ps_data);
		appendStringInfo(&ps_data, "%s ", port->user_name);
		appendStringInfo(&ps_data, "%s", port->remote_host);
		if (port->remote_port[0] != '\0')
			appendStringInfo(&ps_data, "(%s)", port->remote_port);

		init_ps_display(ps_data.data);
#else
		ereport(FATAL,
				(errcode(ERRCODE_CONFIG_FILE_ERROR),
				 errmsg("invalid authentication method \"GSSAPI\": not supported by this build")));
#endif
	}

	/*
	 * Get the authentication method to use for this frontend/database
	 * combination.  Note: we do not parse the file at this point; this has
	 * already been done elsewhere.  hba.c dropped an error message into the
	 * server logfile if parsing the hba config file failed.
	 */
	hba_getauthmethod(port);

	CHECK_FOR_INTERRUPTS();

	/*
	 * Now proceed to do the actual authentication check
	 *
	 * We only support password-based authentication.  So, if we cannot trust
	 * the user, fall back to password based authentication.
	 */
	switch (port->hba->auth_method)
	{
		case uaReject:

			/*
			 * An explicit "reject" entry in pg_hba.conf.  This report exposes
			 * the fact that there's an explicit reject entry, which is
			 * perhaps not so desirable from a security standpoint; but the
			 * message for an implicit reject could confuse the DBA a lot when
			 * the true situation is a match to an explicit reject.  And we
			 * don't want to change the message for an implicit reject.  As
			 * noted below, the additional information shown here doesn't
			 * expose anything not known to an attacker.
			 */
			{
				char		hostinfo[NI_MAXHOST];

				pg_getnameinfo_all(&port->raddr.addr, port->raddr.salen,
								   hostinfo, sizeof(hostinfo),
								   NULL, 0,
								   NI_NUMERICHOST);

#ifdef USE_SSL
				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("pg_hba.conf rejects connection for host \"%s\", user \"%s\", database \"%s\", %s",
								hostinfo, port->user_name,
								port->database_name,
								port->ssl_in_use ? _("SSL on") : _("SSL off"))));
#else
				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("pg_hba.conf rejects connection for host \"%s\", user \"%s\", database \"%s\"",
								hostinfo, port->user_name,
								port->database_name)));
#endif
				break;
			}
		case uaImplicitReject:

			/*
			 * No matching entry, so tell the user we fell through.
			 *
			 * NOTE: the extra info reported here is not a security breach,
			 * because all that info is known at the frontend and must be
			 * assumed known to bad guys.  We're merely helping out the less
			 * clueful good guys.
			 */
			{
				char		hostinfo[NI_MAXHOST];

				pg_getnameinfo_all(&port->raddr.addr, port->raddr.salen,
								   hostinfo, sizeof(hostinfo),
								   NULL, 0,
								   NI_NUMERICHOST);

#define HOSTNAME_LOOKUP_DETAIL(port) \
				(port->remote_hostname ? \
				 (port->remote_hostname_resolv == +1 ? \
				  errdetail_log("Client IP address resolved to \"%s\", forward lookup matches.", \
								port->remote_hostname) : \
				  port->remote_hostname_resolv == 0 ? \
				  errdetail_log("Client IP address resolved to \"%s\", forward lookup not checked.", \
								port->remote_hostname) : \
				  port->remote_hostname_resolv == -1 ? \
				  errdetail_log("Client IP address resolved to \"%s\", forward lookup does not match.", \
								port->remote_hostname) : \
				  port->remote_hostname_resolv == -2 ? \
				  errdetail_log("Could not translate client host name \"%s\" to IP address: %s.", \
								port->remote_hostname, \
								gai_strerror(port->remote_hostname_errcode)) : \
				  0) \
				 : (port->remote_hostname_resolv == -2 ? \
					errdetail_log("Could not resolve client IP address to a host name: %s.", \
								  gai_strerror(port->remote_hostname_errcode)) : \
					0))

#ifdef USE_SSL
				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("no pg_hba.conf entry for host \"%s\", user \"%s\", database \"%s\", %s",
								hostinfo, port->user_name,
								port->database_name,
								port->ssl_in_use ? _("SSL on") : _("SSL off")),
						 HOSTNAME_LOOKUP_DETAIL(port)));
#else
				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("no pg_hba.conf entry for host \"%s\", user \"%s\", database \"%s\"",
								hostinfo, port->user_name,
								port->database_name),
						 HOSTNAME_LOOKUP_DETAIL(port)));
#endif

				pg_getnameinfo_all(&port->raddr.addr, port->raddr.salen,
								   hostinfo, sizeof(hostinfo),
								   NULL, 0,
								   NI_NUMERICHOST);
				break;
			}
		case uaSSPI:
		case uaPeer:
		case uaIdent:
		case uaSCRAM:
		case uaPAM:
		case uaBSD:
		case uaLDAP:
		case uaCert:
		case uaRADIUS:
			/* the above authentication methods are not supported for TDS */
			{
				char		hostinfo[NI_MAXHOST];

				pg_getnameinfo_all(&port->raddr.addr, port->raddr.salen,
								   hostinfo, sizeof(hostinfo),
								   NULL, 0,
								   NI_NUMERICHOST);

				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("pg_hba.conf entry specifies unsupported TDS authentication for host \"%s\", user \"%s\", database \"%s\"",
								hostinfo, port->user_name, port->database_name),
						 errhint("Supported methods are trust, password, md5 and gssapi")));
			}
			break;
		case uaGSS:

			/*
			 * If pg_hba.conf specifies that the entry should be authenticated
			 * using GSSAPI.  If we reach here, we should've already
			 * authenticated using GSSAPI.  So, we can just check the status..
			 */
			if (status != STATUS_OK)
			{
				char		hostinfo[NI_MAXHOST];

				pg_getnameinfo_all(&port->raddr.addr, port->raddr.salen,
								   hostinfo, sizeof(hostinfo),
								   NULL, 0,
								   NI_NUMERICHOST);

				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("invalid TDS authentication request for host \"%s\", user \"%s\", database \"%s\"",
								hostinfo, port->user_name, port->database_name),
						 errhint("Expected authentication request: gssapi")));
			}
			break;
		case uaMD5:
		case uaPassword:
			/* if sspiLen > 0 then GSS auth is already done at this point */
			if (loginInfo->sspiLen > 0)
			{
				Assert(loginInfo->sspi);

				/* Cleanup sspi data. */
				pfree(loginInfo->sspi);
				loginInfo->sspiLen = 0;
				break;
			}

			/*
			 * If pg_hba.conf specifies that the entry should be authenticated
			 * using password and the request doesn't contain a password, we
			 * should throw an error.
			 */
			if (!loginInfo->password)
			{
				char		hostinfo[NI_MAXHOST];

				pg_getnameinfo_all(&port->raddr.addr, port->raddr.salen,
								   hostinfo, sizeof(hostinfo),
								   NULL, 0,
								   NI_NUMERICHOST);

				ereport(FATAL,
						(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
						 errmsg("invalid TDS authentication request for host \"%s\", user \"%s\", database \"%s\"",
								hostinfo, port->user_name, port->database_name),
						 errhint("Expected authentication request: md5 or password")));
			}

			/* we've a password, let's verify it */
			status = CheckAuthPassword(port, &logdetail);
			break;
		case uaTrust:
			status = STATUS_OK;
			break;
	}

	/* If authentication failed, tell the user. */
	if (status != STATUS_OK)
		SendLoginError(port, logdetail);

	/*
	 * Authentication succeeded.  But, we cannot send the login
	 * acknowledgement response until we successfully initialize POSTGRES.  If
	 * we encounter an error during initialization we've to send the error
	 * along with a login failed response to the TDS client.  Check
	 * InitPostgres for different initialization failure scenarios.
	 */
}

void
TdsClientInit(void)
{
	/* set up process-exit hook to close the socket */
	/* on_proc_exit(socket_close, 0); TODO Enable it later */

	/*
	 * In backends (as soon as forked) we operate the underlying socket in
	 * nonblocking mode and use latches to implement blocking semantics if
	 * needed. That allows us to provide safely interruptible reads and
	 * writes.
	 *
	 * Use COMMERROR on failure, because ERROR would try to send the error to
	 * the client, which might require changing the mode again, leading to
	 * infinite recursion.
	 */
#ifndef WIN32
	if (!pg_set_noblock(MyProcPort->sock))
		ereport(COMMERROR,
				(errmsg("could not set socket to nonblocking mode: %m")));
#endif

	FeBeWaitSet = CreateWaitEventSet(TopMemoryContext, 3);
	AddWaitEventToSet(FeBeWaitSet, WL_SOCKET_WRITEABLE, MyProcPort->sock,
					  NULL, NULL);
	AddWaitEventToSet(FeBeWaitSet, WL_LATCH_SET, -1, MyLatch, NULL);
	AddWaitEventToSet(FeBeWaitSet, WL_POSTMASTER_DEATH, -1, NULL, NULL);
	TdsCommInit(TDS_DEFAULT_INIT_PACKET_SIZE,
				tds_secure_read, tds_secure_write);
}

/*
 *	Attempt to negotiate secure session.
 */
static int
SecureOpenServer(Port *port)
{
	int			r = 0;

#ifdef USE_SSL
	TDSInstrumentation(INSTR_TDS_LOGIN_SSL);

	r = Tds_be_tls_open_server(port);

	ereport(DEBUG2,
			(errmsg("SSL connection from \"%s\"",
					port->peer_cn ? port->peer_cn : "(anonymous)")));
#endif

	return r;
}

/*
 * : Process a TDS login handshake
 */
int
TdsProcessLogin(Port *port, bool loadedSsl)
{
	int			rc = 0;
	int			loadEncryption = 0;

	/* Set the LOGIN7 request type for error context */
	TdsErrorContext->phase = 0;
	TdsErrorContext->reqType = TDS_LOGIN7;

	PG_TRY();
	{
		TdsErrorContext->err_text = "Parsing PreLogin Request";
		/* Pre-Login */
		rc = ParsePreLoginRequest();
		if (rc < 0)
			return rc;

		TdsErrorContext->err_text = "Make PreLogin Response";

		loadEncryption = MakePreLoginResponse(port, loadedSsl);
		TdsFlush();

		TdsErrorContext->err_text = "Setup SSL Handshake";
		/* Setup the SSL handshake */
		if (loadEncryption == TDS_ENCRYPT_ON ||
			loadEncryption == TDS_ENCRYPT_OFF ||
			loadEncryption == TDS_ENCRYPT_REQ)
			rc = SecureOpenServer(port);
	}
	PG_CATCH();
	{
		PG_RE_THROW();
	}
	PG_END_TRY();

	/*
	 * If SSL handshake failure has occurred then no need to go ahead with
	 * login, Just return from here.
	 */
	if (rc < 0)
		return rc;

	if (loadEncryption == TDS_ENCRYPT_ON)
		TDSInstrumentation(INSTR_TDS_LOGIN_END_TO_END_ENCRYPT);

	PG_TRY();
	{
		/* Login */
		rc = ProcessLoginInternal(port);
	}
	PG_CATCH();
	{
		PG_RE_THROW();
	}
	PG_END_TRY();

	TdsErrorContext->err_text = "";

	if (rc < 0)
		return rc;

	/* Free up the SSL strcture if TDS_ENCRYPT_OFF is set */
	if (loadEncryption == TDS_ENCRYPT_OFF)
		TdsFreeSslStruct(port);

	return rc;
}

/*
 * TdsSetDbContext:
 *		Used to Set the Database Context during login
 *		and during reset connection.
 *		Note: We should not optimize the scenario during
 *		reset connection to reset to the same database
 *		which might be in use since the USE db command
 *		will reset other configurations which might
 *		have changed.
 */
void
TdsSetDbContext()
{
	char *dbname				= NULL;
	char *useDbCommand			= NULL;
	char *user 					= NULL;
	MemoryContext oldContext	= CurrentMemoryContext;

	PG_TRY();
	{
		if (loginInfo->database != NULL && loginInfo->database[0] != '\0')
		{
			Oid			db_id;

			/*
			 * Before preparing the query, first check whether we got a valid
			 * database name and it exists.  Otherwise, there'll be risk of
			 * SQL injection.
			 */
			StartTransactionCommand();
			db_id = pltsql_plugin_handler_ptr->pltsql_get_database_oid(loginInfo->database);
			CommitTransactionCommand();
			MemoryContextSwitchTo(oldContext);

			if (!OidIsValid(db_id))
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_DATABASE),
							errmsg("database \"%s\" does not exist", loginInfo->database)));

			/*
			 * Any delimitated/quoted db name identifier requested in login
			 * must be already handled before this point.
			 */
			useDbCommand = psprintf("USE [%s]", loginInfo->database);
			dbname = pstrdup(loginInfo->database);
		}
		else
		{
			char	   *temp = NULL;

			StartTransactionCommand();
			temp = pltsql_plugin_handler_ptr->pltsql_get_login_default_db(loginInfo->username);
			MemoryContextSwitchTo(oldContext);

			if (temp == NULL)
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_DATABASE),
							errmsg("could not find default database for user \"%s\"", loginInfo->username)));

			useDbCommand = psprintf("USE [%s]", temp);
			dbname = pstrdup(temp);
			CommitTransactionCommand();
			MemoryContextSwitchTo(oldContext);
		}

		StartTransactionCommand();
		/*
		 * Check if user has privileges to access current database.
		 */
		user = pltsql_plugin_handler_ptr->pltsql_get_user_for_database(dbname);
		if (!user)
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_DATABASE),
						errmsg("Cannot open database \"%s\" requested by the login. The login failed", dbname)));

		/*
		 * loginInfo has a database name provided, so we execute a "USE
		 * [<db_name>]" through pltsql inline handler.
		 */
		ExecuteSQLBatch(useDbCommand);
		CommitTransactionCommand();
	}
	PG_CATCH();
	{
		/*
		 * If this is during reset phase and we encounter an error
		 * with mapped user or db not found then we should terminate
		 * the connection.
		 */
		if (resetTdsConnectionFlag)
		{
			/* Before terminating the connection, send the response to the client. */
			EmitErrorReport();
			FlushErrorState();

			/*
			 * Client driver terminates the connection with a
			 * dual error token and with error 596. Otherwise
			 * it sends the next requests before realising the
			 * session was terminated.
			 */
			TdsSendError(596, 1, ERROR,
					"Cannot continue the execution because the session is in the kill state.", 1);

			TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_ERROR, 0, 0);
			TdsFlush();

			/* Terminate the connection. */
			ereport(FATAL,
					(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
					errmsg("Reset Connection Failed")));
		}
		/* Else rethrow the error. */
		PG_RE_THROW();
	}
	PG_END_TRY();
	if (useDbCommand)
		pfree(useDbCommand);
	if (dbname)
		pfree(dbname);
}

/*
 * TdsSendLoginAck - Send a login acknowledgement to the client
 *
 * This function should be called in postmaster context.
 */
void
TdsSendLoginAck(Port *port)
{
	uint16_t	temp16;
	int			prognameLen = pg_mbstrlen(default_server_name);
	LoginRequest request;
	StringInfoData buf;
	uint8		temp8;
	uint32_t	collationInfo;
	char		collationBytesNew[5];
	Oid			roleid = InvalidOid;
	uint32_t	tdsVersion = pg_hton32(loginInfo->tdsVersion);
	char		srvVersionBytes[4];

	PG_TRY();
	{

		/* Initialize the normal TDS protocol */
		TdsProtocolInit();

		TdsErrorContext->err_text = "Initialising Collation Info";

		/*
		 * Checking if babelfishpg_tsql extension is loaded before reading
		 * babelfishpg_tsql.server_collation_oid GUC
		 */
		StartTransactionCommand();
		PushActiveSnapshot(GetTransactionSnapshot());
		if (get_extension_oid("babelfishpg_tsql", true) == InvalidOid)
			elog(FATAL, "babelfishpg_tsql extension is not installed");
		PopActiveSnapshot();
		CommitTransactionCommand();

		TdsDefineDefaultCollationInfo();

		/*
		 * Collation(total 5bytes) is made of below fields. And we have to
		 * send 5 bytes as part of enviornment change token. LCID(20 bits) +
		 * collationFlags(8 bits) + version(4 bits) + sortId (8 bits) Here, we
		 * are storing 5 bytes individually and then send it as part of
		 * enviornment change token.
		 */
		collationInfo = TdsDefaultLcid | (TdsDefaultCollationFlags << 20);
		collationBytesNew[0] = (char) collationInfo & 0x000000ff;
		collationBytesNew[1] = (char) ((collationInfo & 0x0000ff00) >> 8);
		collationBytesNew[2] = (char) ((collationInfo & 0x00ff0000) >> 16);
		collationBytesNew[3] = (char) ((collationInfo & 0xff000000) >> 24);
		collationBytesNew[4] = (char) TdsDefaultSortid;

		initStringInfo(&buf);
		/* get the login request */
		request = loginInfo;

		TdsErrorContext->err_text = "Verifying and Sending Login Acknowledgement";

		/* Start a server->client message */

		/*
		 * TODO: Why do we do this? All messages the backend sends have this
		 * type
		 */
		TdsSetMessageType(TDS_RESPONSE);

		/* Append the ENVCHANGE and INFO messages */
		/* TODO: find all the real values for EnvChange and Info messages */

		/*
		 * In TDS the packet Size is rounded down to the nearest multiple of
		 * 4.
		 */
		if (request->packetSize == TDS_USE_SERVER_DEFAULT_PACKET_SIZE)
		{
			char		old[10];
			char		new[10];

			/* set the packet size as server default */
			request->packetSize = tds_default_packet_size;

			snprintf(old, sizeof(old), "%u", tds_default_packet_size);
			snprintf(new, sizeof(new), "%u", request->packetSize);
			TdsSendEnvChange(TDS_ENVID_BLOCKSIZE, new, old);
		}
		else if (request->packetSize != tds_default_packet_size)
		{
			char		old[10];	/* the values are between 512 and 32767 */
			char		new[10];

			/*
			 * SQL Server rounds down the packet Size to the nearest multiple
			 * of 4.
			 */
			request->packetSize = (((int) request->packetSize / 4) * 4);

			snprintf(old, sizeof(old), "%u", tds_default_packet_size);
			snprintf(new, sizeof(new), "%u", request->packetSize);
			TdsSendEnvChange(TDS_ENVID_BLOCKSIZE, new, old);
		}

		/*
		 * Check if the user is a valid babelfish login. We will only allow
		 * following users to login: 1. An existing PG user that we have
		 * initialised with sys.babelfish_initialize() 2. A Postgres
		 * SUPERUSER. 3. New users created using CREATE LOGIN command through
		 * TDS endpoint.
		 */
		if (port->user_name != NULL && port->user_name[0] != '\0')
		{
			bool		login_exist;

			StartTransactionCommand();
			roleid = get_role_oid(port->user_name, false);
			login_exist = pltsql_plugin_handler_ptr->pltsql_is_login(roleid);
			CommitTransactionCommand();

			/* Throw error if this user is not one of the type mentioned above */
			if (!login_exist && !superuser_arg(roleid))
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_OBJECT),
						 errmsg("\"%s\" is not a Babelfish user", port->user_name)));
		}

		TdsSetDbContext();

		/*
		 * Set the GUC for language, it will take care of changing the GUC,
		 * doing language validity checks and sending INFO and ENV change
		 * tokens
		 */
		if (request->language != NULL)
		{
			int			ret;

			/*
			 * For varchar GUCs we call pltsql_truncate_identifier which calls
			 * get_namespace_oid which does catalog access, hence we require
			 * to be inside a transaction command.
			 */
			StartTransactionCommand();
			ret = set_config_option_ext("babelfishpg_tsql.language",
										request->language,
										PGC_USERSET,
										PGC_S_CLIENT,
										roleid,
										GUC_ACTION_SET,
										true /* changeVal */ ,
										0 /* elevel */ ,
										false /* is_reload */ );
			CommitTransactionCommand();
			if (ret != 1)
			{
				/* TODO Error handling */
				Assert(false);
			}
		}

		/* Set the GUC for application_name. */
		if (request->appname != NULL)
		{
			int			ret;
			char	   *tmpAppName = pg_clean_ascii(request->appname, 0);

			/*
			 * For varchar GUCs we call pltsql_truncate_identifier which calls
			 * get_namespace_oid which does catalog access, hence we require
			 * to be inside a transaction command.
			 */
			StartTransactionCommand();
			ret = set_config_option_ext("application_name",
										tmpAppName,
										PGC_USERSET,
										PGC_S_CLIENT,
										roleid,
										GUC_ACTION_SET,
										true /* changeVal */ ,
										0 /* elevel */ ,
										false /* is_reload */ );
			CommitTransactionCommand();

			if (ret != 1)
			{
				/* TODO Error handling */
				Assert(false);
			}
		}

		TdsSendEnvChangeBinary(TDS_ENVID_COLLATION,
							   collationBytesNew, sizeof(collationBytesNew),
							   NULL, 0);

		/* Append the LOGINACK message */
		TDS_DEBUG(TDS_DEBUG2, "TdsSendLoginAck: token=0x%02x", TDS_TOKEN_LOGINACK);
		temp8 = TDS_TOKEN_LOGINACK;
		TdsPutbytes(&temp8, sizeof(temp8));

		temp16 = 1				/* interface */
			+ sizeof(tdsVersion)
			+ 1					/* prognameLen */
			+ prognameLen * 2
			+ sizeof(srvVersionBytes);
		TdsPutbytes(&temp16, sizeof(temp16));

		temp8 = 0x01;
		TdsPutbytes(&temp8, sizeof(temp8)); /* interface ??? */

		TdsPutbytes(&tdsVersion, sizeof(tdsVersion));
		TdsPutbytes(&prognameLen, sizeof(temp8));

		TdsUTF8toUTF16StringInfo(&buf, default_server_name, prognameLen);
		TdsPutbytes(buf.data, buf.len);

		srvVersionBytes[0] = makeVersionByte(0);
		srvVersionBytes[1] = makeVersionByte(1);
		srvVersionBytes[2] = makeVersionByte(2);
		srvVersionBytes[3] = makeVersionByte(3);

		TdsPutbytes(&srvVersionBytes, sizeof(srvVersionBytes));

		pfree(buf.data);

		/* Append the DONE message */
		TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_FINAL, 2, 0);

		TdsFlush();

		/*
		 * Now, set the network packet size that'll be used further TDS
		 * communication.
		 *
		 * CAUTION: If required, this internally repallocs memory for TDS send
		 * and receive buffers.  So, we should do this after sending the login
		 * response.
		 */
		TdsErrorContext->err_text = "Resetting the TDS Buffer size";
		TdsSetBufferSize(request->packetSize);

	}
	PG_CATCH();
	{
		/* Before terminating the connection, send the response to the client */
		EmitErrorReport();
		FlushErrorState();

		TdsSendDone(TDS_TOKEN_DONE, TDS_DONE_ERROR, 0, 0);
		TdsFlush();

		TdsErrorContext->err_text = "Verifying and Sending Login Acknowledgement";

		ereport(FATAL,
				(errcode(ERRCODE_INVALID_AUTHORIZATION_SPECIFICATION),
				 errmsg("Login failed for user \"%s\"", port->user_name)));

	}
	PG_END_TRY();
}

/*
 * GetClientTDSVersion - exposes TDS version of client being connected.
 */
uint32_t
GetClientTDSVersion(void)
{
	/* This should not happen. */
	if (loginInfo == NULL)
		ereport(FATAL,
				(errcode(ERRCODE_INTERNAL_ERROR), errmsg("Login Info should not be NULL")));
	return loginInfo->tdsVersion;
}

/*
 * This function will return the AD domain name.
 */
char *
get_tds_login_domainname(void)
{
	if (loginInfo)
		return loginInfo->domainname;
	else
		return NULL;
}

/*
 * To initialise information of default collation based on "babelfishpg_tsql.server_collation_oid" GUC.
 */
static void
TdsDefineDefaultCollationInfo(void)
{
	coll_info_t cinfo;

	StartTransactionCommand();
	cinfo = TdsLookupCollationTableCallback(InvalidOid);
	CommitTransactionCommand();

	if (unlikely(cinfo.oid == InvalidOid))
		elog(FATAL, "Oid of default collation is not valid, This might mean that value of server_collation_name GUC is invalid");

	TdsDefaultLcid = cinfo.lcid;
	TdsDefaultCollationFlags = cinfo.collateflags;
	TdsDefaultSortid = (uint8_t) cinfo.sortid;
	TdsDefaultClientEncoding = cinfo.enc;
}

/*
 * Increment appropriate instrumentation metric for TDS version
 */
static void
GetTDSVersionInstrumentation(uint32_t version)
{
	switch (version)
	{
		case TDS_VERSION_7_0:
			TDSInstrumentation(INSTR_TDS_VERSION_7_0);
			break;
		case TDS_VERSION_7_1:
			TDSInstrumentation(INSTR_TDS_VERSION_7_1);
			break;
		case TDS_VERSION_7_1_1:
			TDSInstrumentation(INSTR_TDS_VERSION_7_1_1);
			break;
		case TDS_VERSION_7_2:
			TDSInstrumentation(INSTR_TDS_VERSION_7_2);
			break;
		case TDS_VERSION_7_3_A:
			TDSInstrumentation(INSTR_TDS_VERSION_7_3_A);
			break;
		case TDS_VERSION_7_3_B:
			TDSInstrumentation(INSTR_TDS_VERSION_7_3_B);
			break;
		case TDS_VERSION_7_4:
			TDSInstrumentation(INSTR_TDS_VERSION_7_4);
			break;
		default:
			break;
	}
}

/*
 * Increment appropriate instrumentation metric for unsupported login flags
 */
static void
GetLoginFlagsInstrumentation(LoginRequest loginInfo)
{
	/* OptionFlags1 */
	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_BYTE_ORDER_68000)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_BYTE_ORDER_68000);

	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_CHAR_EBCDIC)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_CHAR_EBCDIC);

	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_FLOAT_VAX)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_FLOAT_VAX);

	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_FLOAT_ND5000)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_FLOAT_ND5000);

	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_DUMP_LOAD_OFF)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_DUMP_LOAD_OFF);

	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_USE_DB_ON)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_USE_DB_ON);

	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_DATABASE_FATAL)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_DATABASE_FATAL);

	if (loginInfo->optionFlags1 & LOGIN_OPTION_FLAGS1_SET_LANG_ON)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS1_SET_LANG_ON);

	/* OptionFlags2 */
	if (loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_LANGUAGE_FATAL)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS2_LANGUAGE_FATAL);

	if ((GetClientTDSVersion() < TDS_VERSION_7_2) && (loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_TRAN_BOUNDARY))
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS2_TRAN_BOUNDARY);

	if ((GetClientTDSVersion() < TDS_VERSION_7_2) && (loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_CACHE_CONNECT))
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS2_CACHE_CONNECT);

	if (loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_USER_TYPE_SERVER)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS2_USER_TYPE_SERVER);

	if (loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_USER_TYPE_REMUSER)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS2_USER_TYPE_REMUSER);

	if (loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_USER_TYPE_SQLREPL)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS2_USER_TYPE_SQLREPL);

	if (loginInfo->optionFlags2 & LOGIN_OPTION_FLAGS2_INT_SECURITY_ON)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS2_INT_SECURITY_ON);

	/* TypeFlags */
	if (loginInfo->typeFlags & LOGIN_TYPE_FLAGS_SQL_TSQL)
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_TYPE_FLAGS_SQL_TSQL);

	if ((GetClientTDSVersion() == TDS_VERSION_7_4) && (loginInfo->typeFlags & LOGIN_TYPE_FLAGS_READ_ONLY_INTENT))
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_TYPE_FLAGS_READ_ONLY_INTENT);

	/* OptionFlags3 */
	if ((GetClientTDSVersion() >= TDS_VERSION_7_2) && (loginInfo->optionFlags3 & LOGIN_OPTION_FLAGS3_USER_INSTANCE))
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS3_USER_INSTANCE);

	if ((GetClientTDSVersion() >= TDS_VERSION_7_2) && (loginInfo->optionFlags3 & LOGIN_OPTION_FLAGS3_SEND_YUKON_BINARY_XML))
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS3_SEND_YUKON_BINARY_XML);

	if ((GetClientTDSVersion() >= TDS_VERSION_7_3_A) && (loginInfo->optionFlags3 & LOGIN_OPTION_FLAGS3_UNKNOWN_COLLATION_HANDLING))
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS3_UNKNOWN_COLLATION_HANDLING);

	if ((GetClientTDSVersion() == TDS_VERSION_7_4) && (loginInfo->optionFlags3 & LOGIN_OPTION_FLAGS3_EXTENSION))
		TDSInstrumentation(INSTR_UNSUPPORTED_TDS_LOGIN_OPTION_FLAGS3_EXTENSION);
}
