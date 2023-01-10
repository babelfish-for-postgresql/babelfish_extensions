#ifdef ENABLE_TDS_LIB
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

#define TSQL_IMAGE		SYBIMAGE
#define TSQL_VARBINARY		SYBVARBINARY
#define TSQL_BINARY		SYBBINARY
#define TSQL_BINARY_X		XSYBBINARY
#define TSQL_VARBINARY_X	XSYBVARBINARY

#define TSQL_VARCHAR	SYBVARCHAR
#define TSQL_CHAR	SYBCHAR
#define TSQL_NVARCHAR_X	XSYBNVARCHAR
#define TSQL_VARCHAR_X	XSYBVARCHAR
#define TSQL_XML	SYBMSXML
#define TSQL_NCHAR_X	XSYBNCHAR
#define TSQL_CHAR_X	XSYBCHAR

#define TSQL_BIT		SYBBIT
#define TSQL_BITN		SYBBITN
#define TSQL_TEXT		SYBTEXT
#define TSQL_NTEXT		SYBNTEXT
#define TSQL_DATETIME		SYBDATETIME
#define TSQL_DATETIMN		SYBDATETIMN
#define TSQL_SMALLDATETIME	SYBDATETIME4
#define TSQL_DATETIME2		SYBMSDATETIME2
#define TSQL_DATETIMEOFFSET	SYBMSDATETIMEOFFSET
#define TSQL_DATE		SYBMSDATE
#define TSQL_TIME		SYBMSTIME
#define TSQL_DECIMAL		SYBDECIMAL
#define TSQL_NUMERIC		SYBNUMERIC
#define TSQL_FLOAT		SYBFLT8
#define TSQL_FLOATN		SYBFLTN
#define TSQL_REAL		SYBREAL
#define TSQL_TINYINT		SYBINT1
#define TSQL_SMALLINT		SYBINT2
#define TSQL_INT		SYBINT4
#define TSQL_INTN		SYBINTN
#define TSQL_BIGINT		SYBINT8
#define TSQL_MONEY		SYBMONEY
#define TSQL_MONEYN		SYBMONEYN
#define TSQL_SMALLMONEY		SYBMONEY4

typedef struct
{
	uint64_t   time;	/**< time, 7 digit precision */
	int32_t      date;	/**< date, 0 = 1900-01-01 */
	int16_t offset;	/**< time offset */
	uint16_t time_prec3;
	uint16_t _tds_reserved10;
	uint16_t has_time1;
	uint16_t has_date1;
	uint16_t has_offset1;
} LS_TDS_DATETIMEALL;

#define LS_TDS_NUMERIC	DBNUMERIC
#define LS_INT_CANCEL	INT_CANCEL

typedef int LINKED_SERVER_RETCODE;

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
#define LINKED_SERVER_EXEC_QUERY(process)	dbsqlexec(process)
#define LINKED_SERVER_RESULTS(process)		dbresults(process)
#define LINKED_SERVER_NUM_COLS(process)		dbnumcols(process)
#define LINKED_SERVER_NEXT_ROW(process)		dbnextrow(process)
#define LINKED_SERVER_EXIT(void)		dbexit(void)
#define LINKED_SERVER_DATA(process, index)	dbdata(process, index)
#define LINKED_SERVER_DATA_LEN(process, index)	dbdatlen(process, index)
#define LINKED_SERVER_COL_TYPE(process, index)	dbcoltype(process, index)
#define LINKED_SERVER_COL_NAME(process, index)	dbcolname(process, index)
#define LINKED_SERVER_COL_LEN(process, index)	dbcollen(process, index)
#define LINKED_SERVER_BIND_VAR(process, index, bind_var_type, bind_var_size, bind_var)	\
					dbbind(process, index, bind_var_type, bind_var_size, bind_var)

#define LINKED_SERVER_SET_USER(login, username)		DBSETLUSER(login, username)
#define LINKED_SERVER_SET_PWD(login, password)		DBSETLPWD(login, password)
#define LINKED_SERVER_SET_APP(login)			DBSETLAPP(login, "babelfish_linked_server")
#define LINKED_SERVER_SET_VERSION(login)		DBSETLVERSION(login, DBVERSION_74)

#define LS_NTBSTRINGBING	NTBSTRINGBIND
#define	LS_INTBIND		INTBIND

#define LS_BYTE			BYTE

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
#define LINKED_SERVER_RESULTS(process)		((void)0)
#define LINKED_SERVER_NUM_COLS(process)		((void)0)
#define LINKED_SERVER_NEXT_ROW(process)		((void)0)
#define LINKED_SERVER_EXIT(void)		((void)0)
#define LINKED_SERVER_DATA(process, index)	((void)0)
#define LINKED_SERVER_DATA_LEN(process, index)	((void)0)
#define LINKED_SERVER_COL_TYPE(process, index)	((void)0)
#define LINKED_SERVER_COL_NAME(process, index)	((void)0)
#define LINKED_SERVER_COL_LEN(process, index)	((void)0)
#define LINKED_SERVER_BIND_VAR(process, index, bind_var_type, bind_var_size, bind_var)	\
										((void)0)

#define LINKED_SERVER_SET_USER(login, username)         ((void)0)
#define LINKED_SERVER_SET_PWD(login, password)          ((void)0)
#define LINKED_SERVER_SET_APP(login)                    ((void)0)
#define LINKED_SERVER_SET_VERSION(login)                ((void)0)

#define LS_NTBSTRINGBING	0
#define	LS_INTBIND		0

#define LS_BYTE			unsigned char

#endif
