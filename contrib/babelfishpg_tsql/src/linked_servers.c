#include "postgres.h"
#include "funcapi.h"
#include "varatt.h"

#include "foreign/foreign.h"
#include "libpq/pqformat.h"
#include "tsearch/ts_locale.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "miscadmin.h"
#include "catalog/pg_type.h"

#include "pltsql.h"
#include "linked_servers.h"
#include "guc.h"
#include "catalog.h"

#define NO_CLIENT_LIB_ERROR() \
	ereport(ERROR, \
		(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION), \
		 errmsg("Could not establish connection with remote server as use of TDS client library has been disabled. " \
			"Please recompile source with 'ENABLE_TDS_LIB' flag to enable client library.")));

#define LINKED_SERVER_DEBUG(...)	elog(DEBUG1, __VA_ARGS__)
#define LINKED_SERVER_DEBUG_FINER(...)	elog(DEBUG2, __VA_ARGS__)

/*
 * Note: FreeTDS handles UTF-8 to UTF-16 LE conversion internally when we
 * use XSYBNVARCHAR/XSYBNCHAR types with dbrpcparam(). We configure the
 * client charset to UTF-8 via DBSETLCHARSET in linked_server_establish_connection()
 * so that FreeTDS correctly converts multi-byte UTF-8 characters (e.g., CJK,
 * Arabic, emoji) to UTF-16 LE for the TDS protocol wire format.
 */

PG_FUNCTION_INFO_V1(openquery_internal);
PG_FUNCTION_INFO_V1(sp_testlinkedserver_internal);

#ifdef ENABLE_TDS_LIB

#define TDS_NUMERIC_MAX_PRECISION	38

/*
 * number of bytes a numeric/decimal value takes in
 * TDS (according to implementation of client library),
 * where the array index is the numeric precision
 */
const int	tds_numeric_bytes_per_prec[TDS_NUMERIC_MAX_PRECISION + 1] = {
	1,
	2, 2, 3, 3, 4, 4, 4, 5, 5,
	6, 6, 6, 7, 7, 8, 8, 9, 9, 9,
	10, 10, 11, 11, 11, 12, 12, 13, 13, 14,
	14, 14, 15, 15, 16, 16, 16, 17, 17
};

int		tdsTypeStrToTypeId(char *datatype);
Oid		tdsTypeToOid(int datatype);
int		tdsTypeTypmod(int datatype, int datalen, bool is_metadata, int precision, int scale);
Datum		getDatumFromBytePtr(LinkedServerProcess lsproc, void *val, int datatype, int len);
static bool 	isQueryTimeout;

static int
linked_server_msg_handler(LinkedServerProcess lsproc, int error_code, int state, int severity, char *error_msg, char *svr_name, char *proc_name, int line)
{
	StringInfoData buf;

	initStringInfo(&buf);

	/*
	 * If error severity is greater than 10, we interpret it as a T-SQL error;
	 * otheriwse, a T-SQL info
	 */
	appendStringInfo(
					 &buf,
					 "TDS client library %s: Msg #: %i, Msg state: %i, ",
					 severity > 10 ? "error" : "info",
					 error_code,
					 state
		);

	if (error_msg)
		appendStringInfo(&buf, "Msg: %s, ", error_msg);

	if (svr_name)
		appendStringInfo(&buf, "Server: %s, ", svr_name);

	if (proc_name)
		appendStringInfo(&buf, "Process: %s, ", proc_name);

	appendStringInfo(&buf, "Line: %i, Level: %i", line, severity);

	if (severity > 10)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
				 errmsg("%s", buf.data)));
	else
	{
		/*
		 * We delibrately don't call the TDS report warning/info function here
		 * because in doing so, it spews a lot of messages client side like
		 * for database change, language change for every single connection
		 * made to a remote server. Thus, we just log those events in the PG
		 * log files. It would be better to atleast send the warnings client
		 * side but currently there is no way the client libary is able to
		 * distinguish between a warning and an informational message.
		 *
		 * TODO: Distinguish between WARNING and INFO
		 */
		ereport(INFO,
				(errmsg("%s", buf.data)));
	}

	return 0;
}

/*
 * Helper function to remove all occurrences
 * of a substring from a source string
 */
static char *
remove_substr(char *src, const char *substr)
{
	char	   *start,
			   *end;
	size_t		len;

	if (!*substr)
		return src;

	len = strlen(substr);

	if (len > 0)
	{
		start = src;
		while ((start = strstr(start, substr)) != NULL)
		{
			end = start + len;
			memmove(start, end, strlen(end) + 1);
		}
	}

	return src;
}

static StringInfoData
construct_err_string (int severity, int db_error, int os_error, char *db_err_str, char *os_err_str)
{
	StringInfoData buf;

	char	   *err_msg = NULL;
	char	   *str = NULL;

	initStringInfo(&buf);

	if (db_err_str)
	{
		/*
		 * We remove "Adaptive" from error message since we are only
		 * supporting remote servers that use T-SQL and communicate over TDS
		 */
		err_msg = remove_substr(pnstrdup(db_err_str, strlen(db_err_str) + 1), "Adaptive ");
		str = err_msg;

		/* We convert the 'S' in "Server" to lowercase */
		while ((str = strstr(str, "Server")) != NULL)
			*str = 's';
	}

	appendStringInfo(&buf, "TDS client library error: DB #: %i, ", db_error);

	if (err_msg)
		appendStringInfo(&buf, "DB Msg: %s, ", err_msg);

	appendStringInfo(&buf, "OS #: %i, ", os_error);

	if (os_err_str)
		appendStringInfo(&buf, "OS Msg: %s, ", os_err_str);

	appendStringInfo(&buf, "Level: %i", severity);

	return buf;
}

/*
 * Handle any error encountered in TDS client library itself
 */
static int
linked_server_err_handler(LinkedServerProcess lsproc, int severity, int db_error, int os_error, char *db_err_str, char *os_err_str)
{
	StringInfoData buf;

	buf = construct_err_string(severity, db_error, os_error, db_err_str, os_err_str);

	/* when the query times out we need to return LS_INT_CANCEL */
	if (db_error == SYBETIME)
	{
		isQueryTimeout = true;
		return LS_INT_CANCEL;
	} 

	ereport(ERROR,
			(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
			 errmsg("%s", buf.data)));

	return LS_INT_CANCEL;
}

/*
 * Given data from TDS client library, convert it to Datum.
 * Used for T-SQL OPENQUERY.
 */
Datum
getDatumFromBytePtr(LinkedServerProcess lsproc, void *val, int datatype, int len)
{
	bytea	   *bytes;

	switch (datatype)
	{
		case TSQL_IMAGE:
		case TSQL_VARBINARY:
		case TSQL_BINARY:
		case TSQL_BINARY_X:
		case TSQL_VARBINARY_X:
			bytes = palloc0(len + VARHDRSZ);
			SET_VARSIZE(bytes, len + VARHDRSZ);
			memcpy(VARDATA(bytes), (LS_BYTE *) val, len);
			return PointerGetDatum(bytes);
		case TSQL_BIT:
		case TSQL_BITN:
			return BoolGetDatum(*(bool *) val);
		case TSQL_VARCHAR:
		case TSQL_VARCHAR_X:
		case TSQL_CHAR:
		case TSQL_CHAR_X:
		case TSQL_XML:
		case TSQL_NVARCHAR_X:
		case TSQL_NCHAR_X:

			/*
			 * All character data types are received from the client library
			 * in a format that can directly be stored in a PG tuple store so
			 * they need our TDS side receiver magic.
			 */
			PG_RETURN_VARCHAR_P((VarChar *) cstring_to_text_with_len((char *) val, len));
			break;
		case TSQL_TEXT:
		case TSQL_NTEXT:

			/*
			 * All character data types are received from the client library
			 * in a format that can directly be stored in a PG tuple store, so
			 * they do not need our TDS side receiver magic.
			 */
			PG_RETURN_TEXT_P(cstring_to_text_with_len((char *) val, len));
			break;
		case TSQL_UUID:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfoData pbuf;

				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfoData pointing to the correct portion of the TDS
				 * message buffer.
				 */
				pbuf.data = (char *) val;
				pbuf.maxlen = 16;
				pbuf.len = 16;
				pbuf.cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(&pbuf, TSQL_UUID, 0);
			}
			break;
		case TSQL_DATETIME:
		case TSQL_DATETIMN:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfoData pbuf;

				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfoData pointing to the correct portion of the TDS
				 * message buffer.
				 */
				pbuf.data = (char *) val;
				pbuf.maxlen = 8;
				pbuf.len = 8;
				pbuf.cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(&pbuf, TSQL_DATETIMN, 0);
			}
			break;
		case TSQL_SMALLDATETIME:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfoData pbuf;

				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfoData pointing to the correct portion of the TDS
				 * message buffer.
				 */
				pbuf.data = (char *) val;
				pbuf.maxlen = 4;
				pbuf.len = 4;
				pbuf.cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(&pbuf, TSQL_SMALLDATETIME, 0);
			}
			break;
		case TSQL_DATE:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				LS_TDS_DATETIMEALL date;

				memcpy(&date, (LS_TDS_DATETIMEALL *) val, sizeof(LS_TDS_DATETIMEALL));

				/* No optional attribute */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(0, date.date, TSQL_DATE, 0);
			}
			break;
		case TSQL_TIME:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				LS_TDS_DATETIMEALL time;

				memcpy(&time, (LS_TDS_DATETIMEALL *) val, sizeof(LS_TDS_DATETIMEALL));

				/* optional attribute here is scale */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(time.time, 0, TSQL_TIME, 7);
			}
			break;
		case TSQL_DECIMAL:
		case TSQL_NUMERIC:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				LS_TDS_NUMERIC *numeric;
				StringInfoData pbuf;
				int			n,
							i = 0;

				numeric = (LS_TDS_NUMERIC *) val;

				n = tds_numeric_bytes_per_prec[numeric->precision] - 1;

				/* reverse 'n' bytes after 1st byte (sign byte) */
				for (i = 0; i < n / 2; i++)
				{
					char		c = numeric->array[i + 1];

					numeric->array[i + 1] = numeric->array[n - i];
					numeric->array[n - i] = c;
				}

				/* flip the sign byte */
				if (numeric->array[0] == 0)
					numeric->array[0] = 1;
				else
					numeric->array[0] = 0;

				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfoData pointing to the correct portion of the TDS
				 * message buffer.
				 */
				pbuf.data = (char *) (numeric->array);
				pbuf.maxlen = 17;	/* sign byte + numeric bytes (1 + 16) */
				pbuf.len = 17;
				pbuf.cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(&pbuf, TSQL_NUMERIC, numeric->scale);
			}
			break;
		case TSQL_FLOATN:
		case TSQL_FLOAT:
			return Float8GetDatum(*(float8 *) val);
		case TSQL_REAL:
			return Float4GetDatum(*(float4 *) val);
		case TSQL_TINYINT:
			return UInt8GetDatum(*(int16_t *) val);
		case TSQL_SMALLINT:
			return Int16GetDatum(*(int16_t *) val);
		case TSQL_INT:
		case TSQL_INTN:
			return Int32GetDatum(*(int32_t *) val);
		case TSQL_BIGINT:
			return Int64GetDatum(*(int64_t *) val);
		case TSQL_MONEY:
		case TSQL_MONEYN:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfoData pbuf;

				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfoData pointing to the correct portion of the TDS
				 * message buffer.
				 */
				pbuf.data = (char *) val;
				pbuf.maxlen = 8;
				pbuf.len = 8;
				pbuf.cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(&pbuf, TSQL_MONEYN, 0);
			}
			break;
		case TSQL_SMALLMONEY:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfoData pbuf;

				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfoData pointing to the correct portion of the TDS
				 * message buffer.
				 */
				pbuf.data = (char *) val;
				pbuf.maxlen = 4;
				pbuf.len = 4;
				pbuf.cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(&pbuf, TSQL_SMALLMONEY, 0);
			}
			break;
		case TSQL_DATETIME2:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				LS_TDS_DATETIMEALL *datetime2 = (LS_TDS_DATETIMEALL *) val;

				/* optional attribute here is scale */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(datetime2->time, datetime2->date, TSQL_DATETIME2, 7);
			}
			break;
		case TSQL_DATETIMEOFFSET:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				LS_TDS_DATETIMEALL *datetimeoffset = (LS_TDS_DATETIMEALL *) val;

				/* optional attribute here is time offset */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(datetimeoffset->time, datetimeoffset->date, TSQL_DATETIMEOFFSET, datetimeoffset->offset);
			}
			break;
		default:
			return (Datum) 0;
	}

	return (Datum) 0;
}

/*
 * Given T-SQL data type in string, return equivalent client library TDS
 * type. Used when preparing tuple descriptor for T-SQL OPENQUERY.
 */
int
tdsTypeStrToTypeId(char *datatype)
{
	datatype = lowerstr(datatype);

	if (strcmp(datatype, "image") == 0)
		return TSQL_IMAGE;
	else if (strcmp(datatype, "varbinary") == 0)
		return TSQL_VARBINARY_X;
	else if (strcmp(datatype, "binary") == 0)
		return TSQL_BINARY_X;
	else if (strcmp(datatype, "bit") == 0)
		return TSQL_BIT;
	else if (strcmp(datatype, "ntext") == 0)
		return TSQL_NTEXT;
	else if (strcmp(datatype, "text") == 0)
		return TSQL_TEXT;
	else if (strcmp(datatype, "nvarchar") == 0)
		return TSQL_NVARCHAR_X;
	else if (strcmp(datatype, "varchar") == 0)
		return TSQL_VARCHAR_X;
	else if (strcmp(datatype, "nchar") == 0)
		return TSQL_NCHAR_X;
	else if (strcmp(datatype, "char") == 0)
		return TSQL_CHAR_X;
	else if (strcmp(datatype, "datetime") == 0)
		return TSQL_DATETIME;
	else if (strcmp(datatype, "datetime2") == 0)
		return TSQL_DATETIME2;
	else if (strcmp(datatype, "smalldatetime") == 0)
		return TSQL_SMALLDATETIME;
	else if (strcmp(datatype, "datetimeoffset") == 0)
		return TSQL_DATETIMEOFFSET;
	else if (strcmp(datatype, "date") == 0)
		return TSQL_DATE;
	else if (strcmp(datatype, "time") == 0)
		return TSQL_TIME;
	else if (strcmp(datatype, "decimal") == 0)
		return TSQL_DECIMAL;
	else if (strcmp(datatype, "numeric") == 0)
		return TSQL_NUMERIC;
	else if (strcmp(datatype, "float") == 0)
		return TSQL_FLOAT;
	else if (strcmp(datatype, "real") == 0)
		return TSQL_REAL;
	else if (strcmp(datatype, "tinyint") == 0)
		return TSQL_TINYINT;
	else if (strcmp(datatype, "smallint") == 0)
		return TSQL_SMALLINT;
	else if (strcmp(datatype, "int") == 0)
		return TSQL_INTN;
	else if (strcmp(datatype, "bigint") == 0)
		return TSQL_BIGINT;
	else if (strcmp(datatype, "money") == 0)
		return TSQL_MONEYN;
	else if (strcmp(datatype, "smallmoney") == 0)
		return TSQL_SMALLMONEY;
	else if (strcmp(datatype, "uniqueidentifier") == 0)
		return TSQL_UUID;
	else
		ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
				 errmsg("Unable to find type id for datatype %s", datatype)
				 ));

	return 0;
}

/*
 * Given TDS type from client library, return equivalent Babelfish T-SQL
 * data type OID. Used when preparing tuple descriptor for T-SQL OPENQUERY.
 */
Oid
tdsTypeToOid(int datatype)
{
	if (common_utility_plugin_ptr && common_utility_plugin_ptr->lookup_tsql_datatype_oid)
	{
		switch (datatype)
		{
			case TSQL_IMAGE:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("image");
			case TSQL_VARBINARY:
			case TSQL_VARBINARY_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("varbinary");
			case TSQL_BINARY:
			case TSQL_BINARY_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("binary");
			case TSQL_BIT:
			case TSQL_BITN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("bit");
			case TSQL_TEXT:
				return TEXTOID;
			case TSQL_NTEXT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("ntext");
			case TSQL_NVARCHAR_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar");
			case TSQL_VARCHAR:
			case TSQL_VARCHAR_X:
			case TSQL_CHAR:
			case TSQL_XML:
				return VARCHAROID;
			case TSQL_NCHAR_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nchar");
			case TSQL_CHAR_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("bpchar");
			case TSQL_DATETIME:
			case TSQL_DATETIMN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("datetime");
			case TSQL_SMALLDATETIME:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("smalldatetime");
			case TSQL_DATETIME2:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("datetime2");
			case TSQL_DATETIMEOFFSET:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("datetimeoffset");
			case TSQL_DATE:
				return DATEOID;
			case TSQL_TIME:
				return TIMEOID;
			case TSQL_DECIMAL:
			case TSQL_NUMERIC:

				/*
				 * Even though we have a domain for decimal, we will still use
				 * NUMERICOID
				 *
				 * In babelfish, we send decimal as numeric so when the client
				 * library reads the column metadata token, it reads it as
				 * TSQL_NUMERIC but while computing the tuple descriptor using
				 * sp_describe_first_result_set, the system_type_name is
				 * decimal which causes a mismatch between actual and expected
				 * data type.
				 *
				 * To get around this, we store both decimal and numeric with
				 * NUMERICOID
				 */
				return NUMERICOID;
			case TSQL_FLOAT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("float");
			case TSQL_REAL:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("real");
			case TSQL_TINYINT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("tinyint");
			case TSQL_SMALLINT:
				return INT2OID;
			case TSQL_INT:
			case TSQL_INTN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("int");
			case TSQL_BIGINT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("bigint");
			case TSQL_MONEY:
			case TSQL_MONEYN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("money");
			case TSQL_SMALLMONEY:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("smallmoney");
			case TSQL_UUID:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("uniqueidentifier");
			default:
				ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						 errmsg("Unable to find OID for datatype %d", datatype)
						 ));
		}
	}

	return InvalidOid;
}

/*
 * Given TDS type and data length from client library, return equivalent
 * Babelfish T-SQL data type typmod. Used when preparing tuple descriptor
 * for T-SQL OPENQUERY.
 */
int
tdsTypeTypmod(int datatype, int datalen, bool is_metadata, int precision, int scale)
{
	switch (datatype)
	{
		case TSQL_IMAGE:
		case TSQL_VARBINARY:
		case TSQL_BINARY:
		case TSQL_BINARY_X:
		case TSQL_VARBINARY_X:
			return datalen + VARHDRSZ;
		case TSQL_VARCHAR:
		case TSQL_CHAR:
		case TSQL_VARCHAR_X:
		case TSQL_XML:
		case TSQL_CHAR_X:
			{
				if (datalen == -1)
					return -1;

				/*
				 * When modfying the OPENQUERY result-set tuple descriptor, we
				 * use sp_describe_first_result_set, which gives us the
				 * correct data length of character data types. However, the
				 * col length that accompanies the actual result set column
				 * metadata from client library, is 4 * (max column len) and
				 * so we divide it by 4 to get appropriate typmod for
				 * character data types.
				 */
				if (is_metadata)
					return datalen + VARHDRSZ;
				else
					return (datalen / 4) + VARHDRSZ;
			}
		case TSQL_NCHAR_X:
		case TSQL_NVARCHAR_X:
			{
				if (datalen == -1)
					return -1;

				/*
				 * When modfying the OPENQUERY result-set tuple descriptor, we
				 * use sp_describe_first_result_set, which gives us the
				 * correct data length of character data types. However, the
				 * col length that accompanies the actual result set column
				 * metadata from client library, is 4 * (max column len) and
				 * so we divide it by 4 to get appropriate typmod for
				 * character data types.
				 */
				if (is_metadata)
					return (datalen / 2) + VARHDRSZ;
				else
					return (datalen / 4) + VARHDRSZ;
			}
		case TSQL_DECIMAL:
		case TSQL_NUMERIC:
			{
				LINKED_SERVER_DEBUG_FINER("LINKED SERVER: numeric info - precision: %d, scale: %d", precision, scale);

				/* copied from make_numeric_typmod */
				return ((precision << 16) | (scale & 0x7ff)) + VARHDRSZ;
			}
		case TSQL_DATETIME2:
		case TSQL_DATETIMEOFFSET:
		case TSQL_TIME:
			{
				LINKED_SERVER_DEBUG_FINER("LINKED SERVER: time info - scale: %d", scale);

				if (scale >= 0 && scale < 7)
					return scale;
				else
					return -1;
			}
		case TSQL_BIT:
		case TSQL_BITN:
		case TSQL_TEXT:
		case TSQL_NTEXT:
		case TSQL_DATETIME:
		case TSQL_DATETIMN:
		case TSQL_SMALLDATETIME:
		case TSQL_DATE:
		case TSQL_FLOAT:
		case TSQL_REAL:
		case TSQL_TINYINT:
		case TSQL_SMALLINT:
		case TSQL_INT:
		case TSQL_INTN:
		case TSQL_BIGINT:
		case TSQL_MONEY:
		case TSQL_MONEYN:
		case TSQL_SMALLMONEY:
		case TSQL_UUID:
			return -1;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Unable to find typmod for datatype %d", datatype)
					 ));
	}

	return 0;
}

static void
ValidateLinkedServerDataSource(char *data_src)
{
	/*
	 * Only treat fully qualified DNS names (endpoints) or IP address as valid
	 * data sources.
	 *
	 * If data source is provided in the form of servername\\instancename, we
	 * throw an error to suggest use of fully qualified domain name or the IP
	 * address instead.
	 */
	if (strchr(data_src, '\\'))
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("Only fully qualified domain name or IP address are allowed as data source")));
}

void
linked_server_establish_connection(char *servername, LinkedServerProcess * lsproc, bool isTesting)
{
	/* Get the foreign server and user mapping */
	ForeignServer *server = NULL;
	UserMapping *mapping = NULL;

	LinkedServerLogin login;
	ListCell	*option;
	char	*data_src = NULL;
	char	*database = NULL;
	int	query_timeout = 0;
	int	connect_timeout = 0;

	/* LOG: Function entry with context - proves this function was called */
	LINKED_SERVER_DEBUG("Establishing connection to server: %s (%s)", 
	     servername ? servername : "NULL",
	     isTesting ? "testing" : "execution");

	if (!pltsql_enable_linked_servers)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("'openquery' is not currently supported in Babelfish")));

	PG_TRY();
	{
		server = GetForeignServerByName(servername, false);

		/* Unlikely */
		if (server == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Error fetching foreign server with servername '%s'", servername)
					 ));

		/* LOG: Foreign server retrieved successfully */

		mapping = GetUserMapping(GetUserId(), server->serverid);

		if (mapping == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Error fetching user mapping with servername '%s'", servername)
					 ));

		/* LOG: User mapping retrieved successfully */

		if (LINKED_SERVER_INIT() == FAIL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Failed to initialize TDS client library environment")
					 ));

		/* LOG: TDS library initialization successful */

		LINKED_SERVER_ERR_HANDLE(linked_server_err_handler);
		LINKED_SERVER_MSG_HANDLE(linked_server_msg_handler);

		login = LINKED_SERVER_LOGIN();

		/* options in user mapping should be the username and password */
		foreach(option, mapping->options)
		{
			DefElem    *element = (DefElem *) lfirst(option);

			if (strcmp(element->defname, "username") == 0)
			{
				LINKED_SERVER_DEBUG("LINKED SERVER: Setting user as \"%s\" in login request", defGetString(element));
				LINKED_SERVER_SET_USER(login, defGetString(element));
			}
			else if (strcmp(element->defname, "password") == 0)
			{
				LINKED_SERVER_DEBUG("LINKED SERVER: Setting password in login request");
				LINKED_SERVER_SET_PWD(login, defGetString(element));
			}
			else
				ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						 errmsg("Unrecognized option \"%s\" for user mapping", element->defname)
						 ));
		}

		/* fetch connect timeout from the servername */
		connect_timeout = get_timeout_from_server_name(servername, Anum_bbf_servers_def_connect_timeout);

		/*
		 * fetch query timeout from the servername
		 * Don't fetch when testing connection as query timeout is not required
		 */
		if(!isTesting)
			query_timeout = get_timeout_from_server_name(servername, Anum_bbf_servers_def_query_timeout);

		LINKED_SERVER_SET_APP(login);
		LINKED_SERVER_SET_VERSION(login);
		LINKED_SERVER_SET_CHARSET(login, "UTF-8");

		/* options in foreign server should be the servername and database */
		foreach(option, server->options)
		{
			DefElem    *element = (DefElem *) lfirst(option);

			if (strcmp(element->defname, "servername") == 0)
				data_src = defGetString(element);
			else if (strcmp(element->defname, "database") == 0)
				database = defGetString(element);
			else
				ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						 errmsg("Unrecognized option \"%s\" for foreign server", element->defname)
						 ));
		}

		ValidateLinkedServerDataSource(data_src);

		if (database && strlen(database) > 0)
		{
			LINKED_SERVER_DEBUG("LINKED SERVER: Setting database as \"%s\" in login request", database);

			LINKED_SERVER_SET_DBNAME(login, database);
		}

		if(connect_timeout > 0)
		{
			LINKED_SERVER_SET_CONNECT_TIMEOUT(connect_timeout);
		}

		/* LOG: Connection parameters configured */
		LINKED_SERVER_DEBUG("LINKED SERVER: Connection parameters - data_source: %s, database: %s, connect_timeout: %d, query_timeout: %d",
		     data_src ? data_src : "NULL", 
		     database ? database : "(none)", 
		     connect_timeout, 
		     query_timeout);

		LINKED_SERVER_DEBUG("LINKED SERVER: Connecting to remote server \"%s\"", data_src);
		
		/* LOG: Initiating TDS connection */

		*lsproc = LINKED_SERVER_OPEN(login, data_src);
		if (!(*lsproc))
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Unable to connect to \"%s\"", data_src)));

		/* LOG: Connection successful */
		LINKED_SERVER_DEBUG("LINKED SERVER: TDS connection established successfully to: %s", data_src);

		LINKED_SERVER_FREELOGIN(login);

		if(!isTesting && query_timeout > 0)
		{
			LINKED_SERVER_SET_QUERY_TIMEOUT(query_timeout);
		}

		LINKED_SERVER_DEBUG("LINKED SERVER: Connected to remote server");
		
		/* LOG: Connection ready */
	}
	PG_CATCH();
	{
		HOLD_INTERRUPTS();
		LINKED_SERVER_DEBUG("LINKED SERVER: Failed to establish connection to remote server due to error");
		
		/* LOG: Connection failed */
		LINKED_SERVER_DEBUG("Failed to establish connection to server: %s", 
		     servername ? servername : "NULL");
		
		RESUME_INTERRUPTS();

		PG_RE_THROW();
	}
	PG_END_TRY();
}

/*
 * Fetch the column medata for the expected result set
 * from remote server
 */
static void
getOpenqueryTupdescFromMetadata(char *linked_server, char *query, TupleDesc *tupdesc)
{
	LinkedServerProcess lsproc = NULL;

	PG_TRY();
	{
		LINKED_SERVER_RETCODE erc;

		StringInfoData buf;
		int			colcount;

		linked_server_establish_connection(linked_server, &lsproc, false);

		/*
		 * prepare the query that will executed on remote server to get column
		 * medata of result set
		 */
		initStringInfo(&buf);
		appendStringInfoString(&buf, "EXEC sp_describe_first_result_set N'");

		for (int i = 0; i < strlen(query); i++)
		{
			appendStringInfoChar(&buf, query[i]);

			/*
			 * If character is a single quote, we append another single quote
			 * because we want to escape it when we feed the query as a
			 * parameter to sp_describe_first_result_set stored procedure.
			 */
			if (query[i] == '\'')
				appendStringInfoChar(&buf, '\'');
		}

		appendStringInfoString(&buf, "', NULL, 0");

		LINKED_SERVER_DEBUG("LINKED SERVER: (Metadata) - Writing the following query to LinkedServerProcess struct: %s", buf.data);

		/* populate query in LinkedServerProcess structure */
		if ((erc = LINKED_SERVER_PUT_CMD(lsproc, buf.data)) != SUCCEED)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("error writing query \"%s\" to LinkedServerProcess struct", buf.data)
					 ));

		LINKED_SERVER_DEBUG("LINKED SERVER: (Metadata) - Executing query against remote server");

		/* LOG: Metadata query execution starting */
		LINKED_SERVER_DEBUG("Executing metadata query on remote server");

		/* Execute the query on remote server */
		if (LINKED_SERVER_EXEC_QUERY(lsproc) == FAIL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("error executing query \"%s\" against remote server", buf.data)
					 ));

		/* LOG: Metadata query execution successful */

		LINKED_SERVER_DEBUG("LINKED SERVER: (Metadata) - Begin fetching results from remote server");

		while ((erc = LINKED_SERVER_RESULTS(lsproc)) != NO_MORE_RESULTS)
		{
			if (erc == FAIL)
			{
				ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						 errmsg("Failed to get results from query %s", buf.data)
						 ));
			}

			/* We have some results to process */
			colcount = LINKED_SERVER_NUM_COLS(lsproc);

			if (colcount > 0)
			{
				int			numrows = 0;
				int			i = 0;

				int			collen[MAX_COLS_SELECT];
				char	  **colname = (char **) palloc0(MAX_COLS_SELECT * sizeof(char *));
				int			tdsTypeId[MAX_COLS_SELECT];
				int			tdsTypePrecision[MAX_COLS_SELECT];
				int			tdsTypeScale[MAX_COLS_SELECT];

				/* bound variables */
				int			bind_collen,
							bind_tdsTypeId,
							bind_precision,
							bind_scale;
				char		bind_colname[256] = {0x00};
				char		bind_typename[256] = {0x00};
				char	   *column_dup;
				int			dup_collen;

				for (i = 0; i < MAX_COLS_SELECT; i++)
					colname[i] = (char *) palloc0(256 * sizeof(char));

				if (LINKED_SERVER_BIND_VAR(lsproc, 3, LS_NTBSTRINGBING, sizeof(bind_colname), (LS_BYTE *) bind_colname) != SUCCEED)
					ereport(ERROR,
							(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
							 errmsg("Failed to bind results for column \"name\" to a variable.")
							 ));

				if (LINKED_SERVER_BIND_VAR(lsproc, 5, LS_INTBIND, sizeof(int), (LS_BYTE *) & bind_tdsTypeId) != SUCCEED)
					ereport(ERROR,
							(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
							 errmsg("Failed to bind results for column \"system_type_id\" to a variable.")
							 ));

				if (LINKED_SERVER_BIND_VAR(lsproc, 6, LS_NTBSTRINGBING, sizeof(bind_typename), (LS_BYTE *) & bind_typename) != SUCCEED)
					ereport(ERROR,
							(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
							 errmsg("Failed to bind results for column \"system_type_name\" to a variable.")
							 ));

				if (LINKED_SERVER_BIND_VAR(lsproc, 7, INTBIND, sizeof(int), (LS_BYTE *) & bind_collen) != SUCCEED)
					ereport(ERROR,
							(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
							 errmsg("Failed to bind results for column \"max_length\" to a variable.")
							 ));

				if (LINKED_SERVER_BIND_VAR(lsproc, 8, LS_INTBIND, sizeof(int), (LS_BYTE *) & bind_precision) != SUCCEED)
					ereport(ERROR,
							(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
							 errmsg("Failed to bind results for column \"precision\" to a variable.")
							 ));

				if (LINKED_SERVER_BIND_VAR(lsproc, 9, LS_INTBIND, sizeof(int), (LS_BYTE *) & bind_scale) != SUCCEED)
					ereport(ERROR,
							(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
							 errmsg("Failed to bind results for column \"scale\" to a variable.")
							 ));

				LINKED_SERVER_DEBUG("LINKED SERVER: (Metadata) - Fetching result rows");

				/* fetch the rows */
				while (LINKED_SERVER_NEXT_ROW(lsproc) != NO_MORE_ROWS)
				{
					char	   *typestr;

					/*
					 * We encountered an error, we shouldn't return any
					 * results
					 */

					/*
					 * We return here, when we will again execute the query we
					 * will error out from there
					 */
					if (bind_typename == NULL)
						ereport(ERROR,
								(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
								 errmsg("Failed to bind results for column \"system_type_name\" to a variable.")
								 ));

					collen[numrows] = bind_collen;

					/*
					 * If column name is NULL or column name consists only of
					 * whitespace characters, we internally store it as
					 * ?column? (PG interpretation of NULL column name).
					 *
					 * This is needed so that later in the query plan, this
					 * column is not interpreted as a dropped column.
					 *
					 * TODO: Solve for cases where column with only whitespace
					 * characters is a valid column name.
					 */
					if ((bind_colname == NULL))
						strncpy(bind_colname, "?column?", 256);
					else
					{
						/* we create a duplicate just to be safe */
						column_dup = pstrdup(bind_colname);
						dup_collen = strlen(column_dup);

						/* remove trailing whitespaces */
						while (isspace(column_dup[dup_collen - 1]))
							column_dup[--dup_collen] = 0;

						/* column name only had whitespace characters */
						if (dup_collen == 0)
							strncpy(bind_colname, "?column?", 256);

						if (column_dup)
							pfree(column_dup);
					}

					strlcpy(colname[numrows], bind_colname, strlen(bind_colname) + 1);

					/* Only keep the data type name */
					typestr = strstr(bind_typename, "(");

					if (typestr != NULL)
						*typestr = '\0';

					tdsTypeId[numrows] = tdsTypeStrToTypeId(bind_typename);

					tdsTypePrecision[numrows] = bind_precision;
					tdsTypeScale[numrows] = bind_scale;

					++numrows;
				}

				LINKED_SERVER_DEBUG("LINKED SERVER: (Metadata) - Finished fetching results. Fetched %d rows", numrows);

				if (numrows > 0)
				{
					*tupdesc = CreateTemplateTupleDesc(numrows);

					for (i = 0; i < numrows; i++)
					{
						LINKED_SERVER_DEBUG_FINER("LINKED SERVER: (Metadata) - Colinfo - index: %d, name: %s, type: %d, len: %d", i + 1, colname[i], tdsTypeId[i], collen[i]);

						TupleDescInitEntry(*tupdesc, (AttrNumber) (i + 1), colname[i], tdsTypeToOid(tdsTypeId[i]), tdsTypeTypmod(tdsTypeId[i], collen[i], true, tdsTypePrecision[i], tdsTypeScale[i]), 0);
					}

					*tupdesc = BlessTupleDesc(*tupdesc);
					
					/* LOG: Metadata retrieval complete */
					LINKED_SERVER_DEBUG("Metadata retrieval complete - %d columns", numrows);
				}
				else
				{
					/*
					 * Result set is empty, that means DML/DDL was passed as
					 * an argument to sp_describe_first_result_set. Since we
					 * only support SELECTs, we error out.
					 */
					ereport(ERROR,
							(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
							 errmsg("Query passed to OPENQUERY did not return a result set")
							 ));
				}

				if (colname)
				{
					for (i = 0; i < MAX_COLS_SELECT; i++)
					{
						if (colname[i])
							pfree(colname[i]);
					}

					pfree(colname);
				}
			}
		}

		if (buf.data)
			pfree(buf.data);
	}
	PG_FINALLY();
	{
		if (lsproc)
		{
			LINKED_SERVER_DEBUG("LINKED SERVER: (Metadata) - Closing connections to remote server");
			LINKED_SERVER_EXIT();
		}
	}
	PG_END_TRY();
}

static Datum
openquery_imp(PG_FUNCTION_ARGS)
{
	LinkedServerProcess lsproc = NULL;
	char	   *query;

	LINKED_SERVER_RETCODE erc;

	int			colcount = 0;
	int			rowcount = 0;

	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	PG_TRY();
	{
		isQueryTimeout = false;
		query = PG_ARGISNULL(1) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(1));

		linked_server_establish_connection(PG_ARGISNULL(0) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(0)), &lsproc, false);

		LINKED_SERVER_DEBUG("LINKED SERVER: (OPENQUERY) - Writing the following query to LinkedServerProcess struct: %s", query);

		/* populate query in LinkedServerProcess */
		if (LINKED_SERVER_PUT_CMD(lsproc, query) == FAIL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("error writing query to lsproc struct")
					 ));

		LINKED_SERVER_DEBUG("LINKED SERVER: (OPENQUERY) - Executing query against remote server");

		/* LOG: Query execution starting */
		LINKED_SERVER_DEBUG("Executing query on remote server");

		/* Execute the query on remote server */
		if (LINKED_SERVER_EXEC_QUERY(lsproc) == FAIL)
		{
			if (isQueryTimeout)
			{
				StringInfoData buf;
				isQueryTimeout = false;
				buf = construct_err_string(6, 20003, 0, "server connection timed out", "Success");
				ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
			 		errmsg("%s", buf.data)));
			}
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("error executing query \"%s\" against remote server", query)
					 ));
		}

		/* LOG: Query execution successful */

		LINKED_SERVER_DEBUG("LINKED SERVER: (OPENQUERY) - Begin fetching results from remote server");

		/*
		 * This is not a while loop because we should only return the first
		 * result set
		 */
		if ((erc = LINKED_SERVER_RESULTS(lsproc)) != NO_MORE_RESULTS)
		{
			int			i;

			void	   *val[MAX_COLS_SELECT];

			if (erc == FAIL)
			{
				ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						 errmsg("Failed to get results from query %s", query)
						 ));
			}

			/* store the column count */
			colcount = LINKED_SERVER_NUM_COLS(lsproc);

			LINKED_SERVER_DEBUG_FINER("LINKED SERVER: (OPENQUERY) - Number of columns in result set: %d", colcount);

			if (colcount > 0)
			{
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
				tupdesc = CreateTemplateTupleDesc(colcount);

				/* Let us process column metadata first */
				for (i = 0; i < colcount; i++)
				{
					Oid			tdsTypeOid;
					int			coltype = LINKED_SERVER_COL_TYPE(lsproc, i + 1);
					char	   *colname = LINKED_SERVER_COL_NAME(lsproc, i + 1);
					int			collen = LINKED_SERVER_COL_LEN(lsproc, i + 1);
					LS_TYPEINFO *typinfo = LINKED_SERVER_COL_TYPEINFO(lsproc, i + 1);

					tdsTypeOid = tdsTypeToOid(coltype);

					LINKED_SERVER_DEBUG_FINER("LINKED SERVER: (OPENQUERY) - Colinfo - index: %d, name: %s, type: %d, len: %d", i + 1, colname, coltype, collen);

					/*
					 * Current TDS client library has a limitation where it
					 * can send column types like nvarchar as varchar in
					 * column metadata, so check with out previously computed
					 * tuple descriptor to see what should be the actual data
					 * type. At the moment there is no other way.
					 */
					if ((tdsTypeOid == VARCHAROID) || (tdsTypeOid == TEXTOID) || (common_utility_plugin_ptr && ((*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("binary"))))
					{
						Form_pg_attribute att = TupleDescAttr(rsinfo->expectedDesc, (AttrNumber) i);

						tdsTypeOid = att->atttypid;
					}

					TupleDescInitEntry(tupdesc, (AttrNumber) (i + 1), colname, tdsTypeOid, tdsTypeTypmod(coltype, collen, false, typinfo->precision, typinfo->scale), 0);
				}
				tupdesc = BlessTupleDesc(tupdesc);

				per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
				oldcontext = MemoryContextSwitchTo(per_query_ctx);

				tupstore = tuplestore_begin_heap(true, false, work_mem);
				rsinfo->returnMode = SFRM_Materialize;
				rsinfo->setResult = tupstore;
				rsinfo->setDesc = tupdesc;

				MemoryContextSwitchTo(oldcontext);

				LINKED_SERVER_DEBUG("LINKED SERVER: (OPENQUERY) - Fetching result rows");

				/* fetch the rows */
				while (LINKED_SERVER_NEXT_ROW(lsproc) != NO_MORE_ROWS)
				{
					/* for each row */
					Datum	   *values = palloc0(sizeof(Datum) * colcount);
					bool	   *nulls = palloc0(sizeof(bool) * colcount);

					for (i = 0; i < colcount; i++)
					{
						int			coltype = LINKED_SERVER_COL_TYPE(lsproc, i + 1);
						int			datalen = LINKED_SERVER_DATA_LEN(lsproc, i + 1);

						val[i] = LINKED_SERVER_DATA(lsproc, i + 1);

						if (val[i] == NULL)
							nulls[i] = true;
						else
							values[i] = getDatumFromBytePtr(lsproc, val[i], coltype, datalen);
					}

					tuplestore_putvalues(tupstore, tupdesc, values, nulls);

					++rowcount;
				}

				LINKED_SERVER_DEBUG("LINKED SERVER: (OPENQUERY) - Finished fetching results. Fetched %d rows", rowcount);

				/* LOG: Result set summary */
				LINKED_SERVER_DEBUG("Result set retrieved - %d columns, %d rows", colcount, rowcount);

				tuplestore_donestoring(tupstore);
			}
		}
		
		/* LOG: Query completed with results */
	}
	PG_FINALLY();
	{
		if (lsproc)
		{
			LINKED_SERVER_DEBUG("LINKED SERVER: (OPENQUERY) - Closing connections to remote server");
			LINKED_SERVER_EXIT();
		}

		if (query)
			pfree(query);
	}
	PG_END_TRY();

	return (Datum) 0;
}

/*
 * Map PostgreSQL/Babelfish type OID to TDS type for RPC parameter binding.
 *
 * Babelfish type OIDs are resolved at runtime, so they cannot be used in
 * switch/case labels (C requires constant expressions). We use the cached
 * is_tsql_*_datatype() functions from the common utility plugin (typecode.c)
 * which perform lazy-cached OID lookups internally — avoiding the overhead
 * of repeated syscache queries on every call.
 *
 * For the few types without dedicated is_tsql_*_datatype() functions
 * (float, real, datetime, uniqueidentifier), we use get_tsql_datatype_oid()
 * which scans the pre-initialized type_infos[] array (also no syscache).
 */
int
get_tds_type_from_pg_oid(Oid pgtype)
{
	/*
	 * Check for Babelfish-specific types using cached is_tsql_*_datatype()
	 * functions from the common utility plugin. Each function uses a
	 * lazy-initialized static OID variable internally (see typecode.c),
	 * so the syscache is consulted at most once per type per session.
	 */
	if (common_utility_plugin_ptr)
	{
		/* String types */
		if (common_utility_plugin_ptr->is_tsql_varchar_datatype &&
			(*common_utility_plugin_ptr->is_tsql_varchar_datatype)(pgtype))
			return LS_TYPE_VARCHAR;
		if (common_utility_plugin_ptr->is_tsql_nvarchar_datatype &&
			(*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(pgtype))
			return LS_TYPE_NVARCHAR;
		if (common_utility_plugin_ptr->is_tsql_bpchar_datatype &&
			(*common_utility_plugin_ptr->is_tsql_bpchar_datatype)(pgtype))
			return LS_TYPE_CHAR;
		if (common_utility_plugin_ptr->is_tsql_nchar_datatype &&
			(*common_utility_plugin_ptr->is_tsql_nchar_datatype)(pgtype))
			return LS_TYPE_NCHAR;

		/* Integer types */
		if (common_utility_plugin_ptr->is_tsql_int_datatype &&
			(*common_utility_plugin_ptr->is_tsql_int_datatype)(pgtype))
			return LS_TYPE_INT4;
		if (common_utility_plugin_ptr->is_tsql_bigint_datatype &&
			(*common_utility_plugin_ptr->is_tsql_bigint_datatype)(pgtype))
			return LS_TYPE_INT8;
		if (common_utility_plugin_ptr->is_tsql_tinyint_datatype &&
			(*common_utility_plugin_ptr->is_tsql_tinyint_datatype)(pgtype))
			return LS_TYPE_INT1;

		/* Floating point types (no dedicated is_tsql_* — use cached array lookup) */
		if (common_utility_plugin_ptr->get_tsql_datatype_oid)
		{
			if (pgtype == (*common_utility_plugin_ptr->get_tsql_datatype_oid)("float"))
				return LS_TYPE_FLOAT;
			if (pgtype == (*common_utility_plugin_ptr->get_tsql_datatype_oid)("real"))
				return LS_TYPE_REAL;
		}

		/* Boolean type */
		if (common_utility_plugin_ptr->is_tsql_bit_datatype &&
			(*common_utility_plugin_ptr->is_tsql_bit_datatype)(pgtype))
			return LS_TYPE_BIT;

		/* Binary types */
		if (common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype &&
			(*common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype)(pgtype))
			return LS_TYPE_VARBINARY;
		if (common_utility_plugin_ptr->is_tsql_sys_binary_datatype &&
			(*common_utility_plugin_ptr->is_tsql_sys_binary_datatype)(pgtype))
			return LS_TYPE_BINARY;

		/* DateTime types — send as ISO string, server will parse */
		if (common_utility_plugin_ptr->get_tsql_datatype_oid &&
			pgtype == (*common_utility_plugin_ptr->get_tsql_datatype_oid)("datetime"))
			return LS_TYPE_VARCHAR;
		if (common_utility_plugin_ptr->is_tsql_smalldatetime_datatype &&
			(*common_utility_plugin_ptr->is_tsql_smalldatetime_datatype)(pgtype))
			return LS_TYPE_VARCHAR;
		if (common_utility_plugin_ptr->is_tsql_datetime2_datatype &&
			(*common_utility_plugin_ptr->is_tsql_datetime2_datatype)(pgtype))
			return LS_TYPE_VARCHAR;
		if (common_utility_plugin_ptr->is_tsql_datetimeoffset_datatype &&
			(*common_utility_plugin_ptr->is_tsql_datetimeoffset_datatype)(pgtype))
			return LS_TYPE_VARCHAR;

		/* Numeric/Decimal — send as string, server will convert */
		if (common_utility_plugin_ptr->is_tsql_decimal_datatype &&
			(*common_utility_plugin_ptr->is_tsql_decimal_datatype)(pgtype))
			return LS_TYPE_VARCHAR;

		/* Money types — send as string, server will convert */
		if (common_utility_plugin_ptr->is_tsql_money_datatype &&
			(*common_utility_plugin_ptr->is_tsql_money_datatype)(pgtype))
			return LS_TYPE_VARCHAR;
		if (common_utility_plugin_ptr->is_tsql_smallmoney_datatype &&
			(*common_utility_plugin_ptr->is_tsql_smallmoney_datatype)(pgtype))
			return LS_TYPE_VARCHAR;

		/* Uniqueidentifier — send as string (GUID format) */
		if (common_utility_plugin_ptr->get_tsql_datatype_oid &&
			pgtype == (*common_utility_plugin_ptr->get_tsql_datatype_oid)("uniqueidentifier"))
			return LS_TYPE_VARCHAR;
	}

	/* Standard PostgreSQL types (compile-time OIDs, switch is appropriate) */
	switch (pgtype)
	{
		case INT2OID:
			return LS_TYPE_INT2;
		case INT4OID:
			return LS_TYPE_INT4;
		case INT8OID:
			return LS_TYPE_INT8;
		case FLOAT4OID:
			return LS_TYPE_REAL;
		case FLOAT8OID:
			return LS_TYPE_FLOAT;
		case NUMERICOID:
			return LS_TYPE_VARCHAR;
		case BOOLOID:
			return LS_TYPE_BIT;
		case TEXTOID:
			return LS_TYPE_TEXT;
		case VARCHAROID:
			return LS_TYPE_VARCHAR;
		case BPCHAROID:
			return LS_TYPE_CHAR;
		case DATEOID:
			return LS_TYPE_VARCHAR;
		case TIMEOID:
			return LS_TYPE_VARCHAR;
		case TIMESTAMPOID:
			return LS_TYPE_DATETIME;
		case BYTEAOID:
			return LS_TYPE_VARBINARY;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("PostgreSQL type OID %u is not supported for remote procedure parameters", pgtype)));
	}

	return 0;  /* Should not reach here */
}

/*
 * Helper: Convert a text/varchar Datum to raw TDS bytes (no null terminator).
 * Used for all string-like types (varchar, nvarchar, char, nchar, text, etc.)
 *
 * FreeTDS handles UTF-8 to UTF-16 encoding conversion internally when
 * XSYBNVARCHAR/XSYBNCHAR types are used with dbrpcparam(). We send
 * UTF-8 data and FreeTDS converts it as needed for the TDS wire format.
 *
 * Note: Do NOT include null terminator in output — it causes conversion
 * errors in FreeTDS when passed via dbrpcparam.
 */
static void
datum_text_to_tds_bytes(Datum value, void **data_out, DBINT *len_out)
{
	char *str = TextDatumGetCString(value);

	*len_out = strlen(str);
	*data_out = palloc(*len_out);
	memcpy(*data_out, str, *len_out);
	pfree(str);
}

/*
 * Helper: Convert any Datum to TDS bytes via its type output function.
 * The value is serialized to its text representation and sent as a string;
 * the remote server will parse and convert to the appropriate type.
 *
 * Used for types that are complex to send in native TDS binary format
 * (numeric, decimal, money, smallmoney, datetime variants, etc.)
 */
static void
datum_output_to_tds_bytes(Datum value, Oid valtype, void **data_out, DBINT *len_out)
{
	Oid		typoutput;
	bool	typIsVarlena;
	char   *str;

	getTypeOutputInfo(valtype, &typoutput, &typIsVarlena);
	str = OidOutputFunctionCall(typoutput, value);
	*len_out = strlen(str);
	*data_out = palloc(*len_out);
	memcpy(*data_out, str, *len_out);
	pfree(str);
}

/*
 * Convert a Datum value to raw bytes suitable for TDS RPC parameter binding.
 * Returns palloc'd buffer containing the data.
 *
 * Uses cached is_tsql_*_datatype() functions from the common utility plugin
 * (typecode.c) to identify Babelfish types without repeated syscache lookups.
 * Standard PostgreSQL types use a switch statement on compile-time OIDs.
 *
 * Note on tds_typeio.h: The TDS type I/O functions in babelfishpg_tds
 * (TdsSendType*, TdsRecvType*) handle server-side TDS protocol I/O — they
 * write/read TDS wire format bytes to/from the protocol stream buffer.
 * This function handles client-side conversion — it produces raw C values
 * (int32, float8, char*) for FreeTDS dbrpcparam() which has a different API
 * contract. The two cannot be shared due to both the cross-extension boundary
 * (babelfishpg_tds vs babelfishpg_tsql) and the fundamentally different
 * output format requirements.
 */
void
convert_datum_to_tds_bytes(Datum value, Oid valtype, int32 valtypmod, bool isnull,
						   void **data_out, DBINT *len_out)
{
	if (isnull)
	{
		*data_out = NULL;
		*len_out = 0;
		return;
	}

	/*
	 * Check for Babelfish-specific types using cached is_tsql_*_datatype()
	 * functions from the common utility plugin. Each function uses a
	 * lazy-initialized static OID variable internally (see typecode.c),
	 * so the syscache is consulted at most once per type per session.
	 */
	if (common_utility_plugin_ptr)
	{
		/*
		 * String types (varchar, nvarchar, char, nchar) — send as UTF-8.
		 * FreeTDS handles encoding conversion internally for nvarchar/nchar.
		 */
		if ((common_utility_plugin_ptr->is_tsql_nvarchar_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_nvarchar_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_nchar_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_nchar_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_varchar_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_varchar_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_bpchar_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_bpchar_datatype)(valtype)))
		{
			datum_text_to_tds_bytes(value, data_out, len_out);
			return;
		}

		/* Babelfish FLOAT (8 bytes) */
		if (common_utility_plugin_ptr->get_tsql_datatype_oid &&
			valtype == (*common_utility_plugin_ptr->get_tsql_datatype_oid)("float"))
		{
			*len_out = sizeof(LS_DBFLT8);
			*data_out = palloc(*len_out);
			*((LS_DBFLT8 *)*data_out) = DatumGetFloat8(value);
			return;
		}

		/* Babelfish REAL (4 bytes) */
		if (common_utility_plugin_ptr->get_tsql_datatype_oid &&
			valtype == (*common_utility_plugin_ptr->get_tsql_datatype_oid)("real"))
		{
			*len_out = sizeof(LS_DBREAL);
			*data_out = palloc(*len_out);
			*((LS_DBREAL *)*data_out) = DatumGetFloat4(value);
			return;
		}

		/* Babelfish BIT */
		if (common_utility_plugin_ptr->is_tsql_bit_datatype &&
			(*common_utility_plugin_ptr->is_tsql_bit_datatype)(valtype))
		{
			*len_out = sizeof(LS_DBBOOL);
			*data_out = palloc(*len_out);
			*((LS_DBBOOL *)*data_out) = DatumGetBool(value) ? 1 : 0;
			return;
		}

		/* Babelfish TINYINT (unsigned 0-255, stored internally as int2) */
		if (common_utility_plugin_ptr->is_tsql_tinyint_datatype &&
			(*common_utility_plugin_ptr->is_tsql_tinyint_datatype)(valtype))
		{
			*len_out = sizeof(unsigned char);
			*data_out = palloc(*len_out);
			*((unsigned char *)*data_out) = (unsigned char) DatumGetInt16(value);
			return;
		}

		/* Babelfish VARBINARY/BINARY */
		if ((common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_sys_varbinary_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_sys_binary_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_sys_binary_datatype)(valtype)))
		{
			bytea *bytes = DatumGetByteaPP(value);

			*len_out = VARSIZE_ANY_EXHDR(bytes);
			*data_out = palloc(*len_out);
			memcpy(*data_out, VARDATA_ANY(bytes), *len_out);
			return;
		}

		/*
		 * Types sent as string representation — the remote server parses
		 * and converts to the appropriate native type:
		 *   numeric, decimal, money, smallmoney,
		 *   datetime, datetime2, smalldatetime, date, datetimeoffset, time
		 */
		if ((common_utility_plugin_ptr->is_tsql_decimal_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_decimal_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_money_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_money_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_smallmoney_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_smallmoney_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_datetime2_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_datetime2_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_smalldatetime_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_smalldatetime_datatype)(valtype)) ||
			(common_utility_plugin_ptr->is_tsql_datetimeoffset_datatype &&
			 (*common_utility_plugin_ptr->is_tsql_datetimeoffset_datatype)(valtype)))
		{
			datum_output_to_tds_bytes(value, valtype, data_out, len_out);
			return;
		}

		/* datetime, date, time — no dedicated is_tsql_* function, use cached array */
		if (common_utility_plugin_ptr->get_tsql_datatype_oid)
		{
			Oid datetime_oid = (*common_utility_plugin_ptr->get_tsql_datatype_oid)("datetime");
			Oid numeric_oid = (*common_utility_plugin_ptr->get_tsql_datatype_oid)("numeric");

			if (valtype == datetime_oid || valtype == numeric_oid)
			{
				datum_output_to_tds_bytes(value, valtype, data_out, len_out);
				return;
			}
		}
	}

	/* Standard PostgreSQL types (compile-time OIDs, switch is appropriate) */
	switch (valtype)
	{
		case BOOLOID:
			{
				*len_out = sizeof(LS_DBBOOL);
				*data_out = palloc(*len_out);
				*((LS_DBBOOL *)*data_out) = DatumGetBool(value) ? 1 : 0;
			}
			break;

		case INT2OID:
			{
				*len_out = sizeof(LS_DBSMALLINT);
				*data_out = palloc(*len_out);
				*((LS_DBSMALLINT *)*data_out) = DatumGetInt16(value);
			}
			break;

		case INT4OID:
			{
				*len_out = sizeof(LS_DBINT);
				*data_out = palloc(*len_out);
				*((LS_DBINT *)*data_out) = DatumGetInt32(value);
			}
			break;

		case INT8OID:
			{
				*len_out = sizeof(int64);
				*data_out = palloc(*len_out);
				*((int64 *)*data_out) = DatumGetInt64(value);
			}
			break;

		case FLOAT4OID:
			{
				*len_out = sizeof(LS_DBREAL);
				*data_out = palloc(*len_out);
				*((LS_DBREAL *)*data_out) = DatumGetFloat4(value);
			}
			break;

		case FLOAT8OID:
			{
				*len_out = sizeof(LS_DBFLT8);
				*data_out = palloc(*len_out);
				*((LS_DBFLT8 *)*data_out) = DatumGetFloat8(value);
			}
			break;

		case TEXTOID:
		case VARCHAROID:
		case BPCHAROID:
			datum_text_to_tds_bytes(value, data_out, len_out);
			break;

		case BYTEAOID:
			{
				bytea *bytes = DatumGetByteaPP(value);

				*len_out = VARSIZE_ANY_EXHDR(bytes);
				*data_out = palloc(*len_out);
				memcpy(*data_out, VARDATA_ANY(bytes), *len_out);
			}
			break;

		default:
			datum_output_to_tds_bytes(value, valtype, data_out, len_out);
			break;
	}
}

/*
 * Helper function to compare two procedure references for equality
 */
static bool
match_procedure_reference(const char *s1, const char *d1, const char *sc1, const char *p1,
						 const char *s2, const char *d2, const char *sc2, const char *p2)
{
	/* Server name comparison (case-insensitive, NULL means current server) */
	if (s1 && s2)
	{
		if (pg_strcasecmp(s1, s2) != 0)
			return false;
	}
	else if (s1 || s2)
	{
		/* One is NULL, one is not - treat as different unless explicitly same server */
		return false;
	}
	
	/* Database name comparison (case-insensitive) */
	if (d1 && d2)
	{
		if (pg_strcasecmp(d1, d2) != 0)
			return false;
	}
	else if (d1 || d2)
		return false;
	
	/* Schema name comparison (case-insensitive) */
	if (sc1 && sc2)
	{
		if (pg_strcasecmp(sc1, sc2) != 0)
			return false;
	}
	else if (sc1 || sc2)
		return false;
	
	/* Procedure name comparison (case-insensitive, required) */
	if (!p1 || !p2)
		return false;
	
	return pg_strcasecmp(p1, p2) == 0;
}

/*
 * Check if a procedure reference exists in the visited list (circular reference detection)
 */
static bool
is_circular_reference(List *visited_procs,
					 const char *server_name,
					 const char *database_name,
					 const char *schema_name,
					 const char *procedure_name)
{
	ListCell *cell;
	
	foreach(cell, visited_procs)
	{
		NestedProcedureInfo *visited = (NestedProcedureInfo *) lfirst(cell);
		
		if (match_procedure_reference(
				visited->server_name, visited->database_name,
				visited->schema_name, visited->procedure_name,
				server_name, database_name, schema_name, procedure_name))
		{
			return true;
		}
	}
	
	return false;
}

/*
 * Check if a procedure has already been validated (skip redundant validation)
 * Uses the same match logic as is_circular_reference but for validated list
 */
static bool
is_already_validated(List *validated_procs,
					const char *server_name,
					const char *database_name,
					const char *schema_name,
					const char *procedure_name)
{
	ListCell *cell;
	
	foreach(cell, validated_procs)
	{
		NestedProcedureInfo *validated = (NestedProcedureInfo *) lfirst(cell);
		
		if (match_procedure_reference(
				validated->server_name, validated->database_name,
				validated->schema_name, validated->procedure_name,
				server_name, database_name, schema_name, procedure_name))
		{
			return true;
		}
	}
	
	return false;
}

/*
 * Recursively validate a remote procedure and all its nested procedure calls
 * 
 * visited_procs: Per-branch list for circular reference detection (sees ancestors only)
 * validated_procs_ptr: Global list to avoid redundant re-validation (pointer for modification)
 */
static void
validate_remote_procedure_recursive(const char *server_name,
								   const char *database_name,
								   const char *schema_name,
								   const char *procedure_name,
								   int depth,
								   List *visited_procs,
								   List **validated_procs_ptr)
{
	LINKED_SERVER_RETCODE erc;
	StringInfoData query;
	char *definition = NULL;
	int colcount = 0;
	LinkedServerProcess validation_lsproc = NULL;
	List *nested_calls = NIL;
	ListCell *cell;
	NestedProcedureInfo *current;  /* C90: declare at top of function */

	/* Initialize query.data to NULL so PG_FINALLY can safely check it */
	query.data = NULL;
	
	/* Check recursion depth limit (matches pl_exec.c MAX_EXEC_DEPTH_LIMIT) */
	if (depth > 32)
	{
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("Maximum recursion depth (32) exceeded while validating remote procedure %s.%s.%s.%s",
						server_name, database_name, schema_name, procedure_name),
				 errhint("Check for circular procedure references or excessive nesting")));
	}
	
	/* Check for circular reference (in current call stack) */
	if (is_circular_reference(visited_procs, server_name, database_name, schema_name, procedure_name))
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_RECURSION),
				 errmsg("Circular procedure reference detected: %s.%s.%s.%s",
						server_name, database_name, schema_name, procedure_name),
				 errhint("Procedure calls itself directly or indirectly")));
	}
	
	/* Skip if already validated (avoid redundant connections) */
	if (is_already_validated(*validated_procs_ptr, server_name, database_name, schema_name, procedure_name))
	{
		LINKED_SERVER_DEBUG("SELECT-only validation: Skipping %s.%s.%s.%s - already validated",
		     server_name, database_name, schema_name, procedure_name);
		return;
	}
	
	/* Add current procedure to both lists */
	current = (NestedProcedureInfo *) palloc(sizeof(NestedProcedureInfo));
	current->server_name = server_name ? pstrdup(server_name) : NULL;
	current->database_name = database_name ? pstrdup(database_name) : NULL;
	current->schema_name = schema_name ? pstrdup(schema_name) : NULL;
	current->procedure_name = pstrdup(procedure_name);
	
	/* Add to visited (per-branch) for circular detection */
	visited_procs = lappend(visited_procs, current);
	
	/* Add to validated (global) to prevent re-validation */
	*validated_procs_ptr = lappend(*validated_procs_ptr, current);
	
	/*
	 * Fetch procedure definition from remote server
	 * (Reusing existing pattern from current implementation)
	 */
	PG_TRY();
	{
		/* Establish separate connection for validation query */
		linked_server_establish_connection((char *)server_name, &validation_lsproc, false);
		
		/*
		 * Build query to fetch procedure definition from sys.sql_modules.
		 * Use bracket-quoting for identifiers and escape single quotes in
		 * string literals to prevent SQL injection (reviewer comment #90:
		 * procedure names with ' are valid in T-SQL via [] quoting).
		 */
		initStringInfo(&query);
		appendStringInfo(&query,
			"SELECT m.definition "
			"FROM [%s].sys.sql_modules m "
			"JOIN [%s].sys.objects o ON m.object_id = o.object_id "
			"WHERE o.name = N'",
			database_name, database_name);
		/* Escape single quotes in procedure_name */
		for (int i = 0; procedure_name[i] != '\0'; i++)
		{
			appendStringInfoChar(&query, procedure_name[i]);
			if (procedure_name[i] == '\'')
				appendStringInfoChar(&query, '\'');
		}
		appendStringInfoString(&query, "' AND SCHEMA_NAME(o.schema_id) = N'");
		/* Escape single quotes in schema_name */
		for (int i = 0; schema_name[i] != '\0'; i++)
		{
			appendStringInfoChar(&query, schema_name[i]);
			if (schema_name[i] == '\'')
				appendStringInfoChar(&query, '\'');
		}
		appendStringInfoString(&query, "' AND o.type IN ('P', 'PC')");
		
		LINKED_SERVER_DEBUG("SELECT-only validation: Fetching definition for %s.%s.%s.%s (depth=%d)",
			 server_name, database_name, schema_name, procedure_name, depth);
		
		/* Execute query */
		if (LINKED_SERVER_PUT_CMD(validation_lsproc, query.data) != SUCCEED)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Failed to send query to fetch procedure definition for %s", procedure_name)));
		
		if (LINKED_SERVER_EXEC_QUERY(validation_lsproc) == FAIL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Failed to execute query to fetch procedure definition for %s", procedure_name)));
		
		/* Get results */
		if ((erc = LINKED_SERVER_RESULTS(validation_lsproc)) == FAIL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					 errmsg("Failed to get results from procedure definition query")));
		
		colcount = LINKED_SERVER_NUM_COLS(validation_lsproc);
		
		if (colcount > 0)
		{
			/* Fetch definition without buffer binding (handles nvarchar(max)) */
			if (LINKED_SERVER_NEXT_ROW(validation_lsproc) != NO_MORE_ROWS)
			{
				void *data = LINKED_SERVER_DATA(validation_lsproc, 1);
				int data_len = LINKED_SERVER_DATA_LEN(validation_lsproc, 1);
				
				if (data && data_len > 0)
				{
					definition = (char *)palloc(data_len + 1);
					memcpy(definition, data, data_len);
					definition[data_len] = '\0';
				}
			}
			
			/* Consume remaining rows */
			while (LINKED_SERVER_NEXT_ROW(validation_lsproc) != NO_MORE_ROWS)
				;
		}
		
		/* Consume remaining result sets */
		while (LINKED_SERVER_RESULTS(validation_lsproc) != NO_MORE_RESULTS)
		{
			while (LINKED_SERVER_NEXT_ROW(validation_lsproc) != NO_MORE_ROWS)
				;
		}
	}
	PG_FINALLY();
	{
		/* Close validation connection */
		if (validation_lsproc)
		{
			LINKED_SERVER_CANCEL(validation_lsproc);
			LINKED_SERVER_CLOSE(validation_lsproc);
		}
	}
	PG_END_TRY();

	if (definition == NULL)
	{
		pfree(query.data);
		query.data = NULL;
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_FUNCTION),
				 errmsg("Could not fetch definition for remote procedure %s.%s.%s.%s",
						server_name, database_name, schema_name, procedure_name),
				 errhint("Ensure the procedure exists and you have permission to view its definition")));
	}
	
	
	/*
	 * Validate this procedure with ANTLR (SELECT-only check) and
	 * extract nested procedure calls from the same parse.
	 * This replaces the old extract_nested_procedure_calls() C string
	 * parser which was inferior (case-sensitive, matched inside strings/comments).
	 */
	PG_TRY();
	{
		validate_remote_procedure_select_only_antlr(
			definition,
			server_name,
			database_name,
			schema_name,
			procedure_name,
			&nested_calls);
		
	}
	PG_CATCH();
	{
		/* Clean up before re-throwing */
		if (definition)
			pfree(definition);
		if (query.data)
			pfree(query.data);
		PG_RE_THROW();
	}
	PG_END_TRY();
	
	LINKED_SERVER_DEBUG("SELECT-only validation: Found %d nested procedure calls in %s",
	     list_length(nested_calls), procedure_name);
	
	/* Recursively validate each nested procedure */
	foreach(cell, nested_calls)
	{
		NestedProcedureInfo *nested = (NestedProcedureInfo *) lfirst(cell);
		List *child_visited;  /* Fresh copy for each child to prevent false circular detection */
		
		/* Inherit parent values for unspecified parts */
		const char *nested_server = nested->server_name ? nested->server_name : server_name;
		const char *nested_db = nested->database_name ? nested->database_name : database_name;
		const char *nested_schema = nested->schema_name ? nested->schema_name : schema_name;
		
		LINKED_SERVER_DEBUG("SELECT-only validation: Validating nested %s.%s.%s.%s (depth=%d)",
		     nested_server, nested_db, nested_schema, nested->procedure_name, depth + 1);
		
		/*
		 * Create a copy of visited_procs for each child branch.
		 * This prevents false circular reference detection when the same procedure
		 * is called multiple times by the same parent (e.g., EXEC sp_A; EXEC sp_A;).
		 * Each branch should only see its ancestors, not its siblings.
		 */
		child_visited = list_copy(visited_procs);
		
		/* Recursive call with the isolated copy but shared validated list */
		validate_remote_procedure_recursive(
			nested_server,
			nested_db,
			nested_schema,
			nested->procedure_name,
			depth + 1,
			child_visited,
			validated_procs_ptr);
		
		/* Free the copy (contents are shallow but that's OK since we don't modify entries) */
		list_free(child_visited);
	}
	
	/* Clean up - free definition and query.data on all paths */
	if (definition)
		pfree(definition);
	if (query.data)
		pfree(query.data);
	if (nested_calls)
		list_free_deep(nested_calls);
}

/*
 * Validate that a remote stored procedure contains only SELECT statements.
 * This function fetches the procedure definition from the remote server and
 * performs static analysis to detect forbidden DML/DDL statements.
 * 
 * This is the entry point that initiates recursive validation of the procedure
 * and all nested procedure calls.
 *
 * Throws ERROR if the procedure or any nested procedures contain non-SELECT statements.
 */
void
validate_procedure_select_only(const char *server_name,
							   const char *database_name,
							   const char *schema_name,
							   const char *procedure_name)
{
	List *visited_procs = NIL;   /* Per-branch list for circular detection */
	List *validated_procs = NIL; /* Global list to skip redundant validation */
	
	LINKED_SERVER_DEBUG("SELECT-only validation: Starting for %s.%s.%s.%s",
		 server_name, database_name, schema_name, procedure_name);
	
	/* Start recursive validation at depth 0 with empty lists */
	validate_remote_procedure_recursive(
		server_name,
		database_name,
		schema_name,
		procedure_name,
		0,
		visited_procs,
		&validated_procs);
	
	/* Clean up both lists */
	list_free_deep(visited_procs);
	list_free_deep(validated_procs);
	
}

#endif

void
GetOpenqueryTupdescFromMetadata(char *linked_server, char *query, TupleDesc *tupdesc)
{
#ifdef ENABLE_TDS_LIB
	getOpenqueryTupdescFromMetadata(linked_server, query, tupdesc);
#else
	NO_CLIENT_LIB_ERROR();
#endif
}

Datum
openquery_internal(PG_FUNCTION_ARGS)
{
#ifdef ENABLE_TDS_LIB
	openquery_imp(fcinfo);
#else
	NO_CLIENT_LIB_ERROR();
#endif
	return (Datum) 0;
}

Datum
sp_testlinkedserver_internal(PG_FUNCTION_ARGS)
{
#ifdef ENABLE_TDS_LIB
	char *servername = PG_ARGISNULL(0) ? NULL : lowerstr(text_to_cstring(PG_GETARG_VARCHAR_PP(0)));

	LinkedServerProcess lsproc = NULL;

	if (servername == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_FDW_ERROR),
				 errmsg("@servername parameter cannot be NULL")));

	PG_TRY();
	{
		remove_trailing_spaces(servername);

		linked_server_establish_connection(servername, &lsproc, true);
	}
	PG_FINALLY();
	{
		if (lsproc)
		{
			LINKED_SERVER_DEBUG("LINKED SERVER: (CONNECTION TEST) - Closing connections to remote server");
			LINKED_SERVER_EXIT();
		}
	}
	PG_END_TRY();

	if(servername)
		pfree(servername);
#else
	NO_CLIENT_LIB_ERROR();
#endif
	PG_RETURN_VOID();

}
