#include "sybdb.h"

#define SQL_RETURN_CODE_LEN 1000

#define MAX_COLS_SELECT 4096

#define	XSYBCHAR 175            /* 0xAF */
#define	XSYBVARCHAR 167	        /* 0xA7 */
#define	XSYBNVARCHAR 231	/* 0xE7 */
#define	XSYBNCHAR 239	        /* 0xEF */
#define	XSYBVARBINARY 165	/* 0xA5 */
#define	XSYBBINARY 173	        /* 0xAD */
#define	SYBMSXML 241		/* 0xF1 */

typedef struct
{
	uint64_t   time;	/**< time, 7 digit precision */
	int32_t      date;	/**< date, 0 = 1900-01-01 */
	int16_t offset;	/**< time offset */
	uint16_t time_prec:3;
	uint16_t _tds_reserved:10;
	uint16_t has_time:1;
	uint16_t has_date:1;
	uint16_t has_offset:1;
} TDS_DATETIMEALL;

typedef int LINKED_SERVER_RETCODE;

extern void linked_server_establish_connection(char* servername, LinkedServerProcess *dbproc);

#ifdef ENABLE_TDS_LIB
typedef LOGINREC *LinkedServerLogin;
typedef DBPROCESS *LinkedServerProcess;

#define LINKED_SERVER_INIT(void)		dbinit(void)
#define LINKED_SERVER_ERR_HANDLE(h)		dberrhandle(h)
#define LINKED_SERVER_MSG_HANDLE(h)		dbmsghandle(h)
#define LINKED_SERVER_LOGIN(void)		dblogin(void)
#define LINKED_SERVER_OPEN(login, server)	dbopen(login, server)
#define LINKED_SERVER_FREELOGIN(login)		dbloginfree(login)
#define LINKED_SERVER_USE_DB(process, dbname)	dbuse(process, dbname)
#define LINKED_SERVER_PUT_CMD(process, query)	dbcmd(process, query)
#define LINKED_SERVER_EXEC_QUERY(process)	dbsqlexec(process, query)

#define LINKED_SERVER_SET_USER(login, username)		DBSETLUSER(login, username)
#define LINKED_SERVER_SET_PWD(login, password)		DBSETLPWD(login, password)
#define LINKED_SERVER_SET_APP(login)			DBSETLAPP(login, "babelfish_linked_server")
#define LINKED_SERVER_SET_VERSION(login)		DBSETLVERSION(login, DBVERSION_74)

#else
typedef int *LinkedServerLogin;
typedef int *LinkedServerProcess;

#define LINKED_SERVER_INIT(void)		((void)0)
#define LINKED_SERVER_ERR_HANDLE(h)		((void)0)
#define LINKED_SERVER_MSG_HANDLE(h)		((void)0)
#define LINKED_SERVER_LOGIN(void)		((void)0)
#define LINKED_SERVER_OPEN(login, server)	((void)0)
#define LINKED_SERVER_FREELOGIN(login)		((void)0)
#define LINKED_SERVER_USE_DB(process, dbname)	((void)0)
#define LINKED_SERVER_PUT_CMD(process, query)	((void)0)
#define LINKED_SERVER_EXEC_QUERY(process)	((void)0)

#define LINKED_SERVER_SET_USER(login, username)         ((void)0)
#define LINKED_SERVER_SET_PWD(login, password)          ((void)0)
#define LINKED_SERVER_SET_APP(login)                    ((void)0)
#define LINKED_SERVER_SET_VERSION(login)                ((void)0)
#endif