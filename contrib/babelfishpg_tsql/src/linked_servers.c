#include "postgres.h"
#include "funcapi.h"

#include "foreign/foreign.h"
#include "libpq/pqformat.h"
#include "utils/builtins.h"
#include "miscadmin.h"

#include "pltsql.h"
#include "linked_servers.h"

PG_FUNCTION_INFO_V1(openquery_imp);

void getOpenqueryTupdescFromMetadata(char* linked_server, char* query, TupleDesc *tupdesc);

#ifdef ENABLE_TDS_LIB

#define TDS_NUMERIC_MAX_PRECISION	38

/* 
 * number of bytes a numeric/decimal value takes in
 * TDS (according to implementation of client library),
 * where the array index is the numeric precision
 */
const int tds_numeric_bytes_per_prec[TDS_NUMERIC_MAX_PRECISION + 1] = {
	1, 
	2,  2,  3,  3,  4,  4,  4,  5,  5,
	6,  6,  6,  7,  7,  8,  8,  9,  9,  9,
	10, 10, 11, 11, 11, 12, 12, 13, 13, 14,
	14, 14, 15, 15, 16, 16, 16, 17, 17
};

int tdsTypeStrToTypeId(char* datatype);
Oid tdsTypeToOid(int datatype);
int tdsTypeLen(int datatype, int datalen, bool is_metadata);
Datum getDatumFromBytePtr(LinkedServerProcess lsproc, void *val, int datatype, int len);

/*
 * T-SQL OPENQUERY is implemented as a PG range table function.
 * For a PG range table function, the expected tuple descriptor
 * is computed twice from the SQL definition: first during the
 * pre-analyze phase of query execution, and next during the
 * query planning phase. In case of T-SQL OPENQUERY, the tuple
 * descriptor computation is a costly operation which involves
 * connecting to the remote server to get the expected column
 * metadata information using sp_describe_first_result_set.
 *
 * As an optimization, instead of doing the above operation twice,
 * we store the initial computed tuple descriptor in this structure
 * and simply re-use it a second time during the planning phase.
 *
 * We invalidate the stored tuple descriptor once the actual column
 * metadata is fetched as part of the OPENQUERY result-set.
 */
static TupleDesc curr_openquery_tupdesc = NULL;

static int
linked_server_msg_handler(LinkedServerProcess lsproc, int error_code, int state, int severity, char *error_msg, char *svr_name, char *proc_name, int line)
{
	StringInfoData buf;

	initStringInfo(&buf);
	
	/* If error severity is greater than 10, we interpret it as a T-SQL error; otheriwse, a T-SQL info */
	appendStringInfo(
		&buf,
		"TDS client library %s: Msg #: %i, Msg state: %i, Msg: %s, Server: %s, Process: %s, Line: %i, Level: %i",
		severity > 10 ? "error" : "info",
		error_code,
		state,
		error_msg ? error_msg : "",
		svr_name ? svr_name : "",
		proc_name ? proc_name : "",
		line,
		severity
	);
	
	if (severity > 10)
		ereport(ERROR,
			(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
			errmsg("%s", buf.data)));
	else
	{
		/*
		 * We delibrately don't call the TDS report warning/info function
		 * here because in doing so, it spews a lot of messages client side
		 * like for database change, language change for every single connection
		 * made to a remote server. Thus, we just log those events in the PG log
		 * files. It would be better to atleast send the warnings client side but
		 * currently there is no way the client libary is able to distinguish
		 * between a warning and an informational message.
		 *
		 * TODO: Distinguish between WARNING and INFO
		 */
		ereport(INFO,
			(errmsg("%s", buf.data)));
	}

	return 0;
}

/*
 * Given data from TDS client library, convert it to Datum.
 * Used for T-SQL OPENQUERY.
 */
Datum
getDatumFromBytePtr(LinkedServerProcess lsproc, void *val, int datatype, int len)
{
	bytea *bytes;
	
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
			return BoolGetDatum(*(bool *)val);
		case TSQL_VARCHAR:
		case TSQL_VARCHAR_X:
		case TSQL_CHAR:
		case TSQL_CHAR_X:
		case TSQL_XML:
		case TSQL_NVARCHAR_X:
		case TSQL_NCHAR_X:
			/*
			 * All character data types are received from the client library in a format that can
			 * directly be stored in a PG tuple store so they need our TDS side receiver magic.
			 */
			PG_RETURN_VARCHAR_P((VarChar *)cstring_to_text_with_len((char *)val, len));
			break;
		case TSQL_TEXT:
		case TSQL_NTEXT:
			/*
			 * All character data types are received from the client library in a format that can
			 * directly be stored in a PG tuple store, so they do not need our TDS side receiver magic.
			 */
			PG_RETURN_TEXT_P(cstring_to_text_with_len((char *)val, len));
			break;
		case TSQL_DATETIME:
		case TSQL_DATETIMN:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (char *)val;
				pbuf->maxlen = 8;
				pbuf->len = 8;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, TSQL_DATETIMN, 0);
			}
			break;
		case TSQL_SMALLDATETIME:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (char *)val;
				pbuf->maxlen = 4;
				pbuf->len = 4;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, TSQL_SMALLDATETIME, 0);
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
				StringInfo pbuf;
				int n, i = 0;
				char numeric_bytes[16] = {0x00}; /* max storage bytes for numeric - sign byte = 17 - 1 = 16 */

				numeric = (LS_TDS_NUMERIC *)val;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (char *)(numeric->array);

				n = tds_numeric_bytes_per_prec[numeric->precision] - 1;

				/* reverse copy 'n' bytes after 1st byte (sign byte) */
				for (i = 0; i < n; i++)
					numeric_bytes[i] = numeric->array[n-i];

				/* flip the sign byte */
				if (numeric->array[0] == 0)
					pbuf->data[0] = 1;
				else
					pbuf->data[0] = 0;
				
				memcpy(&pbuf->data[1], numeric_bytes, 16);

				pbuf->maxlen = 17;		/* sign byte + numeric bytes (1 + 16) */
				pbuf->len = 17;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, TSQL_NUMERIC, numeric->scale);
			}
			break;
		case TSQL_FLOATN:
		case TSQL_FLOAT:
			return Float8GetDatum(*(float8 *)val);
		case TSQL_REAL:
			return Float4GetDatum(*(float4 *)val);
		case TSQL_TINYINT:
			return UInt8GetDatum(*(int16_t *)val);
		case TSQL_SMALLINT:
			return Int16GetDatum(*(int16_t *)val);
		case TSQL_INT:
		case TSQL_INTN:
			return Int32GetDatum(*(int32_t *)val);
		case TSQL_BIGINT:
			return Int64GetDatum(*(int64_t *)val);
		case TSQL_MONEY:
		case TSQL_MONEYN:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (char *)val;
				pbuf->maxlen = 8;
				pbuf->len = 8;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, TSQL_MONEYN, 0);
			}
			break;
		case TSQL_SMALLMONEY:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (char *)val;
				pbuf->maxlen = 4;
				pbuf->len = 4;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, TSQL_SMALLMONEY, 0);
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
tdsTypeStrToTypeId(char* datatype)
{
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
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("image");
			case TSQL_VARBINARY:
			case TSQL_VARBINARY_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("varbinary");
			case TSQL_BINARY:
			case TSQL_BINARY_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("binary");
			case TSQL_BIT:
			case TSQL_BITN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("bit");
			case TSQL_TEXT:
				return TEXTOID;
			case TSQL_NTEXT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("ntext");
			case TSQL_NVARCHAR_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("nvarchar");
			case TSQL_VARCHAR:
			case TSQL_VARCHAR_X:
			case TSQL_CHAR:
			case TSQL_XML:
				return VARCHAROID;
			case TSQL_NCHAR_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("nchar");
			case TSQL_CHAR_X:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("bpchar");
			case TSQL_DATETIME:
			case TSQL_DATETIMN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("datetime");
			case TSQL_SMALLDATETIME:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("smalldatetime");
			case TSQL_DATETIME2:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("datetime2");
			case TSQL_DATETIMEOFFSET:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("datetimeoffset");
			case TSQL_DATE:
				return DATEOID;
			case TSQL_TIME:
				return TIMEOID;
			case TSQL_DECIMAL:
			case TSQL_NUMERIC:
				/* 
				 * Even though we have a domain for decimal, we will still use NUMERICOID
				 *
				 * In babelfish, we send decimal as numeric so when the client library reads
				 * the column metadata token, it reads it as TSQL_NUMERIC but while computing
				 * the tuple descriptor using sp_describe_first_result_set, the system_type_name
				 * is decimal which causes a mismatch between actual and expected data type.
				 * 
				 * To get around this, we store both decimal and numeric with NUMERICOID
				 */
				return NUMERICOID;
			case TSQL_FLOAT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("float");
			case TSQL_REAL:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("real");
			case TSQL_TINYINT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("tinyint");
			case TSQL_SMALLINT:
				return INT2OID;
			case TSQL_INT:
			case TSQL_INTN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("int");
			case TSQL_BIGINT:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("bigint");
			case TSQL_MONEY:
			case TSQL_MONEYN:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("money");
			case TSQL_SMALLMONEY:
				return (*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("smallmoney");
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
 * Babelfish T-SQL data type length. Used when preparing tuple descriptor
 * for T-SQL OPENQUERY.
 */
int
tdsTypeLen(int datatype, int datalen, bool is_metadata)
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
		case TSQL_NVARCHAR_X:
		case TSQL_VARCHAR_X:
		case TSQL_XML:
		case TSQL_NCHAR_X:
		case TSQL_CHAR_X:
			{
				if (datalen == -1)
					return -1;

				/* 
				 * When modfying the OPENQUERY result-set tuple descriptor, we use sp_describe_first_result_set,
				 * which gives us the correct data length of character data types. However, the col length that 
				 * accompanies the actual result set column metadata from client library, is 4 * (max column
				 * len) and so we divide it by 4 to get appropriate typmod for character data types.
				 */
				if (is_metadata)
					return datalen + VARHDRSZ;
				else
					return (datalen/4) + VARHDRSZ;
			}
                case TSQL_BIT:
		case TSQL_BITN:
                case TSQL_TEXT:
		case TSQL_NTEXT:
		case TSQL_DATETIME:
		case TSQL_DATETIMN:
		case TSQL_SMALLDATETIME:
		case TSQL_DATETIME2:
		case TSQL_DATETIMEOFFSET:
		case TSQL_DATE:
		case TSQL_TIME:
		case TSQL_DECIMAL:
		case TSQL_NUMERIC:
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
			return -1;
		default:
			ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Unable to find len for datatype %d", datatype)
				));
	}

	return 0;
}

static void
ValidateLinkedServerDataSource(char* data_src)
{
	/* 
	 * Only treat fully qualified DNS names (endpoints) or IP address 
	 * as valid data sources.
	 * 
	 * If data source is provided in the form of servername\\instancename, we
	 * throw an error to suggest use of fully qualified domain name or the IP address
	 * instead.
	 */
	if (strchr(data_src, '\\'))
		ereport(ERROR,
			(errcode(ERRCODE_FDW_ERROR),
				errmsg("Only fully qualified domain name or IP address are allowed as data source")));
}

#endif

static void
linked_server_establish_connection(char* servername, LinkedServerProcess *lsproc)
{
	/* Get the foreign server and user mapping */
	ForeignServer *server = NULL;
	UserMapping *mapping = NULL;

#ifdef ENABLE_TDS_LIB
	
	LinkedServerLogin login;
	DefElem *element;
#endif

	PG_TRY();
	{
		server = GetForeignServerByName(servername, false);

		/* Unlikely */
		if (server == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Error fetching foreign server with servername '%s'", servername)
					));

		mapping = GetUserMapping(GetUserId(), server->serverid);

		if (mapping == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Error fetching user mapping with servername '%s'", servername)
					));
#ifdef ENABLE_TDS_LIB

		LINKED_SERVER_INIT();

		LINKED_SERVER_MSG_HANDLE(linked_server_msg_handler);

		login = LINKED_SERVER_LOGIN();

		/* first option in user mapping should be the username */
		element = linitial_node(DefElem, mapping->options);
		if (strcmp(element->defname, "username") == 0)
			LINKED_SERVER_SET_USER(login, defGetString(element));
		else
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Incorrect option. Expected \"username\" but got \"%s\"", element->defname)
					));

		/* second option in user mapping should be the password */
		element = lsecond_node(DefElem, mapping->options);
		if (strcmp(element->defname, "password") == 0)
			LINKED_SERVER_SET_PWD(login, defGetString(element));
		else
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Incorrect option. Expected \"password\" but got \"%s\"", element->defname)
					));

		LINKED_SERVER_SET_APP(login);
		LINKED_SERVER_SET_VERSION(login);

		/* first option in foreign server should be servername */
		element = linitial_node(DefElem, server->options);
		if (strcmp(element->defname, "servername") == 0){

			char *data_src = defGetString(element);

			ValidateLinkedServerDataSource(data_src);

			*lsproc = LINKED_SERVER_OPEN(login, data_src);
			if (!(*lsproc))
				ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Unable to connect to %s", data_src)
					));
		}
		else
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Incorrect option. Expected \"servername\" but got \"%s\"", element->defname)
					));

		LINKED_SERVER_FREELOGIN(login);

		element = lsecond_node(DefElem, server->options);
		if (strcmp(element->defname, "database") == 0)
		{
			if (strlen(defGetString(element)))
				Assert(LINKED_SERVER_USE_DB(*lsproc, defGetString(element)) == SUCCEED);
		}
		else
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Incorrect option. Expected \"database\" but got \"%s\"", element->defname)
					));
#else

		ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Could not establish connection with remote server as use of TDS client library has been disabled. "
							"Please recompile source with 'ENABLE_TDS_LIB' flag to enable client library.")
					));
#endif
	}
	PG_CATCH();
	{
#ifdef ENABLE_TDS_LIB
		LINKED_SERVER_EXIT();
#endif

		PG_RE_THROW();
	}
	PG_END_TRY();
}

/*
 * Fetch the column medata for the expected result set 
 * from remote server 
 */
void
getOpenqueryTupdescFromMetadata(char* linked_server, char* query, TupleDesc *tupdesc)
{
	LinkedServerProcess lsproc;

#ifdef ENABLE_TDS_LIB

	LINKED_SERVER_RETCODE erc;

 	MemoryContext oldContext;
	StringInfoData buf;
	int colcount;

	PG_TRY();
	{

		/* Reuse already computed Tuple Descriptor if it exists */
		if (curr_openquery_tupdesc != NULL)
		{
			*tupdesc = CreateTupleDescCopy(curr_openquery_tupdesc);
			return;
		}
#endif
		linked_server_establish_connection(linked_server, &lsproc);

#ifdef ENABLE_TDS_LIB

		/* prepare the query that will executed on remote server to get column medata of result set*/
		initStringInfo(&buf);
		appendStringInfoString(&buf, "EXEC sp_describe_first_result_set N'");
		appendStringInfoString(&buf, query);
		appendStringInfoString(&buf, "', NULL, 0");
		
		/* populate query in LinkedServerProcess structure */
		if ((erc = LINKED_SERVER_PUT_CMD(lsproc, buf.data)) != SUCCEED) {
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("error writing query to LinkedServerProcess struct")
					));
		}

		/* Execute the query on remote server */
		LINKED_SERVER_EXEC_QUERY(lsproc);

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

			if(colcount > 0)
			{
				int numrows = 0;
				int i = 0;

				int collen[MAX_COLS_SELECT];
				char **colname = (char **) palloc0(MAX_COLS_SELECT * sizeof(char*));
				int tdsTypeId[MAX_COLS_SELECT];

				/* bound variables */
				int bind_collen, bind_tdsTypeId;
				char bind_colname[256] = {0x00};
				char bind_typename[256] = {0x00};
				char *column_dup;
				int dup_collen;

				for (i = 0; i < MAX_COLS_SELECT; i++)
					colname[i] = (char *) palloc0(256 * sizeof(char));

				if ((erc = LINKED_SERVER_BIND_VAR(lsproc, 3, LS_NTBSTRINGBING, sizeof(bind_colname), (LS_BYTE *)bind_colname)) != SUCCEED)
					ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Failed to bind results for column \"name\" to a variable.")
					));

				if ((erc = LINKED_SERVER_BIND_VAR(lsproc, 5, LS_INTBIND, sizeof(int), (LS_BYTE *)&bind_tdsTypeId)) != SUCCEED)
					ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Failed to bind results for column \"system_type_id\" to a variable.")
					));
				
				if ((erc = LINKED_SERVER_BIND_VAR(lsproc, 6, LS_NTBSTRINGBING, sizeof(bind_typename), (LS_BYTE *)&bind_typename)) != SUCCEED)
					ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Failed to bind results for column \"system_type_name\" to a variable.")
					));

				if ((erc = LINKED_SERVER_BIND_VAR(lsproc, 7, INTBIND, sizeof(int), (LS_BYTE *)&bind_collen)) != SUCCEED)
					ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Failed to bind results for column \"max_length\" to a variable.")
					));

				/* fetch the rows */
				while ((erc = LINKED_SERVER_NEXT_ROW(lsproc)) != NO_MORE_ROWS)
				{
					char *typestr;
					
					/* We encountered an error, we shouldn't return any results */
					/* We return here, when we will again execute the query we will error out from there */
					if (bind_typename == NULL)
						ereport(ERROR,
						(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Failed to bind results for column \"system_type_name\" to a variable.")
					));

					collen[numrows] = bind_collen;

					/*
					 * If column name is NULL or column name consists only of whitespace characters,
					 * we internally store it as ?column? (PG interpretation of NULL column name).
					 *
					 * This is needed so that later in the query plan, this column is not interpreted
					 * as a dropped column.
					 *
					 * TODO: Solve for cases where column with only whitespace characters is a valid
					 * column name.
					 */
					if ((bind_colname == NULL))
						strncpy(bind_colname, "?column?", 256);
					else
					{
						/* we create a duplicate just to be safe */
						column_dup = pstrdup(bind_colname);
						dup_collen = strlen(column_dup);

						/* remove trailing whitespaces */
						while(isspace(column_dup[dup_collen - 1]))
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
					++numrows;
				}

				if (numrows > 0)
				{
					*tupdesc = CreateTemplateTupleDesc(numrows);

					for (i = 0; i < numrows; i++)
						TupleDescInitEntry(*tupdesc, (AttrNumber) (i + 1), colname[i], tdsTypeToOid(tdsTypeId[i]), tdsTypeLen(tdsTypeId[i], collen[i], true), 0);

					*tupdesc = BlessTupleDesc(*tupdesc);
				}
				else
				{
					/*
					 * Result set is empty, that means DML/DDL was passed as an argument to
					 * sp_describe_first_result_set. Since we only support SELECTs, we error out.
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

		/* Store the tuple descriptor in TopMemoryContext to be used later */
		oldContext = MemoryContextSwitchTo(TopMemoryContext);
		curr_openquery_tupdesc = CreateTemplateTupleDesc((*tupdesc)->natts);
		TupleDescCopy(curr_openquery_tupdesc, *tupdesc);
		MemoryContextSwitchTo(oldContext);
	}
	PG_FINALLY();
	{
		LINKED_SERVER_EXIT();

		if (buf.data)
			pfree(buf.data);
	}
	PG_END_TRY();
#endif
}

Datum
openquery_imp(PG_FUNCTION_ARGS)
{
	LinkedServerProcess lsproc = NULL;
	char* query; 

#ifdef ENABLE_TDS_LIB

	LINKED_SERVER_RETCODE erc;

	int colcount;
	
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
#endif

	PG_TRY();
	{
		query = PG_ARGISNULL(1) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(1));
	
		linked_server_establish_connection(PG_ARGISNULL(0) ? NULL : text_to_cstring(PG_GETARG_TEXT_PP(0)), &lsproc);

#ifdef ENABLE_TDS_LIB

		/* populate query in DBPROCESS */
		if ((erc = LINKED_SERVER_PUT_CMD(lsproc, query)) != SUCCEED) {
			ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("error writing query to lsproc struct")
					));
		}

		/* Execute the query on remote server */
		LINKED_SERVER_EXEC_QUERY(lsproc);

		while ((erc = LINKED_SERVER_RESULTS(lsproc)) != NO_MORE_RESULTS)
		{
			int i;
			int coltype[MAX_COLS_SELECT];
			char *colname[MAX_COLS_SELECT];
			int collen[MAX_COLS_SELECT];

			void *val[MAX_COLS_SELECT];

			if (erc == FAIL)
			{
				ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
						errmsg("Failed to get results from query %s", query)
					));
			}

			/* store the column metadata if present */
			colcount = LINKED_SERVER_NUM_COLS(lsproc);

			for(i = 0; i < colcount; i++)
			{
				/* Let us process column metadata first */
				coltype[i] = LINKED_SERVER_COL_TYPE(lsproc, i + 1);
				colname[i] = LINKED_SERVER_COL_NAME(lsproc, i + 1);
				collen[i] = LINKED_SERVER_COL_LEN(lsproc, i + 1);
			}

			if(colcount > 0)
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

				/* 
				 * If column name is NULL, we set the column name as "?column?" (default 
				 * column name set by PG if column name is NULL). We have logic in the
				 * babelfishpg_tds extension to set the column name length 0 on the wire
				 * if we come across this column name.
				 */
				for(i = 0; i < colcount; i++)
				{
					Oid tdsTypeOid = tdsTypeToOid(coltype[i]);

					/* 
					 * Current TDS client library has a limitation where it can send
					 * column types like nvarchar as varchar in column metadata, so
					 * check with out previously computed tuple descriptor to see what
					 * should be the actual data type. At the moment there is no other way.
					 */
					if ((tdsTypeOid == VARCHAROID) || (tdsTypeOid == TEXTOID) || (common_utility_plugin_ptr && ((*common_utility_plugin_ptr->lookup_tsql_datatype_oid)("binary"))))
					{
						Form_pg_attribute att = TupleDescAttr(curr_openquery_tupdesc, (AttrNumber) i);
						tdsTypeOid = att->atttypid;
					}

					TupleDescInitEntry(tupdesc, (AttrNumber) (i + 1), colname[i], tdsTypeOid, tdsTypeLen(coltype[i], collen[i], false), 0);
				}
				tupdesc = BlessTupleDesc(tupdesc);

				per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
				oldcontext = MemoryContextSwitchTo(per_query_ctx);

				tupstore = tuplestore_begin_heap(true, false, work_mem);
				rsinfo->returnMode = SFRM_Materialize;
				rsinfo->setResult = tupstore;
				rsinfo->setDesc = tupdesc;

				MemoryContextSwitchTo(oldcontext);

				/* fetch the rows */
				while ((erc = LINKED_SERVER_NEXT_ROW(lsproc)) != NO_MORE_ROWS)
				{
					/* for each row */
					Datum	*values = palloc0(sizeof(SIZEOF_DATUM) * colcount);
					bool	*nulls = palloc0(sizeof(bool) * colcount);

					MemSet(nulls, false, sizeof(nulls));

					for (i = 0; i < colcount; i++)
					{
						int datalen = LINKED_SERVER_DATA_LEN(lsproc, i + 1);
						val[i] = LINKED_SERVER_DATA(lsproc, i + 1);

						// if (val[i] == NULL && datalen == 0)
						if (val[i] == NULL)
							nulls[i] = true;
						else
							values[i] = getDatumFromBytePtr(lsproc, val[i], coltype[i], datalen);
							
					}

					tuplestore_putvalues(tupstore, tupdesc, values, nulls);
				}

				tuplestore_donestoring(tupstore);
			}
		}
#endif
	}
	PG_FINALLY();
	{
#ifdef ENABLE_TDS_LIB
		/* Invalidate Tuple Descriptor */
		if (curr_openquery_tupdesc)
			pfree(curr_openquery_tupdesc);

		curr_openquery_tupdesc = NULL;

		LINKED_SERVER_EXIT();
#endif
		if (query)
			pfree(query);
	}
	PG_END_TRY();

	return (Datum)0;
}
