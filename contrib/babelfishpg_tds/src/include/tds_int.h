/*-------------------------------------------------------------------------
 *
 * tds_int.h
 *	  This file contains definitions for structures and externs used
 *	  internally by the  TDS listener.
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/tds/tds_int.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TDS_INT_H
#define TDS_INT_H

#include "catalog/objectaccess.h"
#include "datatype/timestamp.h"
#include "fmgr.h"
#include "varatt.h"
#include "lib/stringinfo.h"
#include "libpq/hba.h"
#include "libpq/libpq-be.h"
#include "libpq/pqcomm.h"
#include "nodes/parsenodes.h"
#include "parser/parse_node.h"
#include "nodes/params.h"
#include "tcop/dest.h"
#include "tcop/utility.h"
#include "utils/memutils.h"
#include "utils/numeric.h"
#include <libxml/uri.h>

#include "tds_typeio.h"
#include "guc.h"

#include "../../contrib/babelfishpg_tsql/src/pltsql.h"
#include "../../contrib/babelfishpg_tsql/src/pltsql-2.h"

#define TDS_PACKET_HEADER_SIZE 8

/*
 * Default packet size for initial hand-shake - this is used only for prelogin
 * SSL handshakes and login packets.
 * TODO. This will vary with the SQL clients.  We need a to determine the sizes
 * of prelogin, SSL handshakes and login packets by inspecting the respective
 * packets..  For now, just use the default.
 */
#define TDS_DEFAULT_INIT_PACKET_SIZE 4096

/*
 * If the client sends the following packet size, we should use server default
 * packet size.
 */
#define TDS_USE_SERVER_DEFAULT_PACKET_SIZE 0

/* default database for TSQL */
#define TSQL_DEFAULT_DB "master"

/* default server name */
#define TDS_DEFAULT_SERVER_NAME "Microsoft SQL Server"

/* Assembly type name for Geospatial types */
#define TDS_ASSEMBLY_TYPE_NAME_GEOMETRY "Microsoft.SqlServer.Types.SqlGeometry, Microsoft.SqlServer.Types"
#define TDS_ASSEMBLY_TYPE_NAME_GEOGRAPHY "Microsoft.SqlServer.Types.SqlGeography, Microsoft.SqlServer.Types"

/* default compatibility version */
#define BABEL_COMPATIBILITY_VERSION "12.0.2000.8"

/* TDS packet types */
#define TDS_QUERY				0x01
#define TDS_RPC					0x03
#define TDS_RESPONSE			0x04
#define TDS_BULK_LOAD 			0x07
#define TDS_TXN					0x0E
#define TDS_LOGIN7				0x10
#define TDS_PRELOGIN			0x12
#define TDS_ATTENTION			0x06

/* various flags in TDS request packet header */
#define TDS_PACKET_HEADER_STATUS_EOM				0x01	/* end of message */
#define TDS_PACKET_HEADER_STATUS_IGNORE				0x02	/* ignore event */
#define TDS_PACKET_HEADER_STATUS_RESETCON			0x08	/* reset connection */
#define TDS_PACKET_HEADER_STATUS_RESETCONSKIPTRAN	0x10	/* reset connection but
															 * keep transaction
															 * context */

/* TDS prelogin option types */
#define TDS_PRELOGIN_VERSION 0x00
#define TDS_PRELOGIN_ENCRYPTION 0x01
#define TDS_PRELOGIN_INSTOPT 0x02
#define TDS_PRELOGIN_THREADID 0x03
#define TDS_PRELOGIN_MARS 0x04
#define TDS_PRELOGIN_TRACEID 0x05
#define TDS_PRELOGIN_FEDAUTHREQUIRED 0x06
#define TDS_PRELOGIN_NONCEOPT 0x07
#define TDS_PRELOGIN_TERMINATOR 0xFF

/* TDS Encryption values */
#define TDS_ENCRYPT_OFF 0x00
#define TDS_ENCRYPT_ON 0x01
#define TDS_ENCRYPT_NOT_SUP 0x02
#define TDS_ENCRYPT_REQ 0x03
#define TDS_ENCRYPT_CLIENT_CERT_ENCRYPT_OFF 0x80
#define TDS_ENCRYPT_CLIENT_CERT_ENCRYPT_ON 0x81
#define TDS_ENCRYPT_CLIENT_CERT_ENCRYPT_REQ 0x83

/* TDS Environment Change IDs */
#define TDS_ENVID_DATABASE		0x01
#define TDS_ENVID_LANGUAGE		0x02
#define TDS_ENVID_BLOCKSIZE		0x04
#define TDS_ENVID_COLLATION		0x07
#define TDS_ENVID_RESETCON		0x12

/* TDS Environment Change IDs */
#define TDS_ENVID_BEGINTXN			0x08
#define TDS_ENVID_COMMITTXN			0x09
#define TDS_ENVID_ROLLBACKTXN		0x0a

/*
 * Macros for TDS Versions
 *
 * If tds_default_protocol_version is set to TDS_DEFAULT_VERSION value
 * then we shall use the TDS Version that the client specifies during login.
 */
#define TDS_DEFAULT_VERSION 0
#define TDS_VERSION_7_0 	0x70000000	/* TDS version 7.0 */
#define TDS_VERSION_7_1 	0x71000000	/* TDS version 7.1 */
#define TDS_VERSION_7_1_1	0x71000001	/* TDS version 7.1 Rev 1 */
#define TDS_VERSION_7_2 	0x72090002	/* TDS version 7.2 */
#define TDS_VERSION_7_3_A	0x730A0003	/* TDS version 7.3A */
#define TDS_VERSION_7_3_B	0x730B0003	/* TDS version 7.3B */
#define TDS_VERSION_7_4 	0x74000004	/* TDS version 7.4 */

/*
 * Macros to explicitly convert host byte order to LITTLE_ENDIAN
 * fashioned after the pg_hton16().. family found in port/pg_bswap.h
 */
#ifdef WORDS_BIGENDIAN

#define htoLE16(x)		pg_bswap16(x)
#define htoLE32(x)		pg_bswap32(x)
#define htoLE64(x)		pg_bswap64(x)
#define htoLE128(x)		pg_bswap128(x)

#define LEtoh16(x)		pg_bswap16(x)
#define LEtoh32(x)		pg_bswap32(x)
#define LEtoh64(x)		pg_bswap64(x)
#define LEtoh128(x)		pg_bswap128(x)

#else

#define htoLE16(x)		(x)
#define htoLE32(x)		(x)
#define htoLE64(x)		(x)
#define htoLE128(x)		(x)

#define LEtoh16(x)		(x)
#define LEtoh32(x)		(x)
#define LEtoh64(x)		(x)
#define LEtoh128(x)		(x)

#endif

/* TDS type related */
#define TDS_MAX_NUM_PRECISION 38
#define READ_DATA(PTR, SVHDR) (VARDATA_ANY(PTR) + SVHDR)

/* Globals */
extern PLtsql_protocol_plugin *pltsql_plugin_handler_ptr;
extern collation_callbacks *collation_callbacks_ptr;

/* Globals in backend/tds/tdscomm.c */
extern MemoryContext TdsMemoryContext;

/* Global to store default collation info */
extern int	TdsDefaultLcid;
extern int	TdsDefaultCollationFlags;
extern uint8_t TdsDefaultSortid;
extern pg_enc TdsDefaultClientEncoding;

#define TDS_DEBUG1 1
#define TDS_DEBUG2 2
#define TDS_DEBUG3 3

#define TDS_DEBUG_ENABLED(level) (level <= tds_debug_log_level)

#define TDS_DEBUG(level, ... ) do { \
if (TDS_DEBUG_ENABLED(level)) \
    elog(LOG,  __VA_ARGS__); \
} while(0);

#define TdsGetEncoding(collation)\
	(\
	 (collation & 0xFFFFF) ? TdsLookupEncodingByLCID(collation & 0xFFFFF) : \
	 TdsLookupEncodingByLCID(TdsDefaultLcid) \
	);

/* Structures in backend/tds/tdsprotocol.c */
typedef struct TdsParamNameData
{
	char	   *name;			/* name of the parameter (If there is an
								 * upperlimit, we can use fixed size array) */
	uint8		type;			/* 0: IN parameter 1: OUT parameter (TODO:
								 * INOUT parameters?) */
} TdsParamNameData;

typedef TdsParamNameData *TdsParamName;

extern PGDLLIMPORT uint32_t MyTdsClientVersion;
extern PGDLLIMPORT char *MyTdsLibraryName;
extern PGDLLIMPORT char *MyTdsHostName;
extern PGDLLIMPORT char *MyTdsContextInfo;
extern PGDLLIMPORT uint32_t MyTdsClientPid;
extern PGDLLIMPORT uint32_t MyTdsProtocolVersion;
extern PGDLLIMPORT uint32_t MyTdsPacketSize;
extern PGDLLIMPORT int MyTdsEncryptOption;

/* XXX: Should be removed */
/* Stores mapping between TVP and underlying table */
extern List *tvp_lookup_list;

typedef struct TdsMessageWrapper
{
	StringInfo	message;
	uint8_t		messageType;
	uint64_t	offset;
} TdsMessageWrapper;

/*
 * We store the required TDS information to gain more context if we
 * encounter an error in TDS.
 */
typedef struct
{
	uint8_t		reqType;		/* current Tds Request Type */
	char	   *phase;			/* current TDS_REQUEST_PHASE_* (see above) */
	char	   *spType;
	char	   *txnType;
	char	   *err_text;		/* additional errorstate info */

} TdsErrorContextData;

extern TdsErrorContextData *TdsErrorContext;


/* Socket functions */
typedef ssize_t (*TdsSecureSocketApi) (Port *port, void *ptr, size_t len);

/* Globals in backend/tds/tdsutils.c */
extern object_access_hook_type next_object_access_hook;
extern ProcessUtility_hook_type next_ProcessUtility;

/* Postgres Public role name */
#define PUBLIC_ROLE_NAME "public"
#define BABELFISH_SYSADMIN "sysadmin"
#define BABELFISH_ROLE_ADMIN "bbf_role_admin"

/* Functions in backend/tds/tdscomm.c */
extern void TdsSetMessageType(uint8_t msgType);
extern void TdsCommInit(uint32_t bufferSize,
						TdsSecureSocketApi secure_read,
						TdsSecureSocketApi secure_write);
extern void TdsSetMessageType(uint8_t msgType);
extern void TdsCommReset(void);
extern void TdsCommShutdown(void);
extern int	TdsPeekbyte(void);
extern int	TdsReadNextBuffer(void);
extern int	TdsSocketFlush(void);
extern int	TdsGetbytes(char *s, size_t len);
extern int	TdsDiscardbytes(size_t len);
extern int	TdsPutbytes(void *s, size_t len);
extern int	TdsPutInt8(int8_t value);
extern int	TdsPutUInt8(uint8_t value);
extern int	TdsPutInt16LE(int16_t value);
extern int	TdsPutUInt16LE(uint16_t value);
extern int	TdsPutInt32LE(int32_t value);
extern int	TdsPutUInt32LE(uint32_t value);
extern int	TdsPutInt64LE(int64_t value);
extern int	TdsPutFloat4LE(float4 value);
extern int	TdsPutFloat8LE(float8 value);
extern bool TdsCheckMessageType(uint8_t messageType);
extern int	TdsReadNextRequest(StringInfo message, uint8_t *status, uint8_t *messageType);
extern int	TdsReadMessage(StringInfo message, uint8_t messageType);
extern int	TdsReadNextPendingBcpRequest(StringInfo message);
extern int	TdsDiscardAllPendingBcpRequest(void);
extern int	TdsWriteMessage(StringInfo message, uint8_t messageType);
extern int	TdsHandleTestQuery(StringInfo message);
extern int	TdsTestProtocol(void);
extern int	TdsPutUInt16LE(uint16_t value);
extern int	TdsPutUInt64LE(uint64_t value);
extern int	TdsPutDate(uint32_t value);
extern bool TdsGetRecvPacketEomStatus(void);

/* Functions in backend/tds/tdslogin.c */
extern void TdsSetBufferSize(uint32_t newSize);
extern void TdsClientAuthentication(Port *port);
extern void TdsClientInit(Port *port);
extern void TdsSetBufferSize(uint32_t newSize);
extern int	TdsProcessLogin(Port *port, bool LoadSsl);
extern void TdsSendLoginAck(Port *port);
extern uint32_t GetClientTDSVersion(void);
extern char *get_tds_login_domainname(void);
extern void TdsSetDbContext(void);

/* Functions in backend/tds/tdsprotocol.c */
extern int	TdsSocketBackend(void);
extern void TdsProtocolInit(void);
extern void TdsProtocolFinish(void);
extern int	TestGetTdsRequest(uint8_t reqType, const char *expectedStr);

/* Functions in backend/tds/tdsrpc.c */
extern bool TdsIsSPPrepare(void);
extern void TdsFetchInParamValues(ParamListInfo params);
extern bool TdsGetParamNames(List **);
extern int	TdsGetAndSetParamIndex(const char *pname);
extern void TDSLogDuration(char *query);

/* Functions in backend/tds/tdsutils.c */
extern int	TdsUTF8LengthInUTF16(const void *in, int len);
extern void TdsUTF16toUTF8StringInfo(StringInfo out, void *in, int len);
extern void TdsUTF8toUTF16StringInfo(StringInfo out,
									 const void *in,
									 size_t len);
extern int32_t ProcessStreamHeaders(const StringInfo message);
extern Node *TdsFindParam(ParseState *pstate, ColumnRef *cref);
extern void TdsErrorContextCallback(void *arg);
extern void babelfish_object_access(ObjectAccessType access, Oid classId, Oid objectId, int subId, void *arg);
extern void tdsutils_ProcessUtility(PlannedStmt *pstmt, const char *queryString, bool readOnlyTree, ProcessUtilityContext context, ParamListInfo params, QueryEnvironment *queryEnv, DestReceiver *dest, QueryCompletion *completionTag);

/* Functions in backend/tds/guc.c */
extern void TdsDefineGucs(void);

extern void tdsstat_initialize(void);
extern void tdsstat_bestart(void);
extern void TdsSetGucStatVariable(const char *guc, bool boolVal, const char *strVal, int intVal);
extern void TdsSetAtAtStatVariable(TdsAtAtVarType at_at_var, int intVal, uint64 bigintVal);
extern void TdsSetDatabaseStatVariable(int16 db_id);
extern bool get_tds_database_backend_count(int16 db_id, bool ignore_current_connection);
extern bool tds_stat_get_activity(Datum *values, bool *nulls, int len, int pid, int curr_backend);
extern int tdsstat_fetch_stat_numbackends(void);
extern void invalidate_stat_table(void);
extern char *get_tds_host_name(void);
extern uint32_t get_tds_client_pid(void);
extern Datum get_tds_context_info(void);
extern void set_tds_context_info(bytea *context_info);

/* Functions in backend/tds/tdspostgres.c */
extern void TDSPostgresMain(int argc, char *argv[],
							const char *dbname, const Oid dboid,
							const char *username) pg_attribute_noreturn();

/* Functions in backend/tds/tdspostinit.c */
extern void TDSInitPostgres(const char *in_dbname, Oid dboid, const char *username,
							Oid useroid, char *out_dbname, bool override_allow_connections);

/* Functions in backend/tds/tdspostmaster.c */
extern void TDSBackendRun(Port *port, bool loadedSSL, char *extraOptions);

/* Functions in backend/tds/tds_srv.c */
extern void pe_init(void);
extern void pe_fin(void);

/* Functions in backend/utils/adt/numeric.c */
extern Numeric TdsSetVarFromStrWrapper(const char *str);
extern int32_t numeric_get_typmod(Numeric num);

/* Functions in backend/utils/adt/varchar.c */
extern void *tds_varchar_input(const char *s, size_t len, int32 atttypmod);

/* Functions in backend/utils/adt/xml.c */
extern void tds_xmlFreeDoc(void *doc);
extern void *tds_xml_parse(text *data, int xmloption_arg, bool preserve_whitespace,
						   int encoding);
extern int	tds_parse_xml_decl(const xmlChar *str, size_t *lenp,
							   xmlChar **version, xmlChar **encoding, int *standalone);

/* Functions in tdstypeio.c */
extern char *TdsEncodingConversion(const char *s, int len, pg_enc src_encoding, pg_enc dest_encoding, int *encodedByteLen);
extern coll_info_t TdsLookupCollationTableCallback(Oid oid);
extern Datum TdsBytePtrToDatum(StringInfo buf, int datatype, int scale);
extern Datum TdsDateTimeTypeToDatum(uint64 time, int32 date, int datatype, int scale);

/* Functions in tdsbulkload.c */
extern void TdsResetBcpOffset(void);

#endif							/* TDS_INT_H */
