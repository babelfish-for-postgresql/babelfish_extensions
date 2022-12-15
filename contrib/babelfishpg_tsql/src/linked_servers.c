#include "postgres.h"


#include "foreign/foreign.h"
#include "libpq/pqformat.h"

#include "../src/pltsql.h"

#include "linked_servers.h"

static TupleDesc *curr_openquery_tupdesc = NULL;

const int tds_numeric_bytes_per_prec[] = {
	/*
	 * precision can't be 0 but using a value > 0 assure no
	 * core if for some bug it's 0...
	 */
	1, 
	2,  2,  3,  3,  4,  4,  4,  5,  5,
	6,  6,  6,  7,  7,  8,  8,  9,  9,  9,
	10, 10, 11, 11, 11, 12, 12, 13, 13, 14,
	14, 14, 15, 15, 16, 16, 16, 17, 17, 18,
	18, 19, 19, 19, 20, 20, 21, 21, 21, 22,
	22, 23, 23, 24, 24, 24, 25, 25, 26, 26,
	26, 27, 27, 28, 28, 28, 29, 29, 30, 30,
	31, 31, 31, 32, 32, 33, 33, 33
};

char*
tds_err_msg(int severity, int dberr, int oserr, char *dberrstr, char *oserrstr)
{
	StringInfoData buf;

	initStringInfo(&buf);
	appendStringInfo(
			&buf,
			"FreeTDS Error: DB #: %i, DB Msg: %s, OS #: %i, OS Msg: %s, Level: %i",
			dberr,
			dberrstr ? dberrstr : "",
			oserr,
			oserrstr ? oserrstr : "",
			severity
	);

	return buf.data;
}

static int
tds_err_handler(LinkedServerProcess dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr)
{
	ereport(ERROR,
		(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
		errmsg("%s", tds_err_msg(severity, dberr, oserr, dberrstr, oserrstr))
		));

	return INT_CANCEL;
}

static int
tds_notice_msg_handler(LinkedServerProcess dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *svr_name, char *proc_name, int line)
{
	if (severity > 10)
		ereport(ERROR,
			(errmsg("DB-Library notice: Msg #: %ld, Msg state: %i, Msg: %s, Server: %s, Process: %s, Line: %i, Level: %i",
				(long)msgno, msgstate, msgtext, svr_name, proc_name, line, severity)
			));
	return 0;
}

Datum
getDatumFromBytePtr(LinkedServerProcess dbproc, void *val, int datatype, int len)
{
	bytea *bytes;

	switch (datatype)
	{
		case SYBIMAGE:
		case SYBVARBINARY:
		case SYBBINARY:
		case XSYBBINARY:
		case XSYBVARBINARY:
			bytes = palloc(len + VARHDRSZ);
			SET_VARSIZE(bytes, len + VARHDRSZ);
			memcpy(VARDATA(bytes), (BYTE *) val, len);
			return PointerGetDatum(bytes);
		case SYBBIT:
		case SYBBITN:
			return BoolGetDatum(*(bool *)val);
		case SYBVARCHAR:
		case XSYBVARCHAR:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (BYTE *)val;
				pbuf->maxlen = len;
				pbuf->len = len;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, XSYBVARCHAR, 0, 0);
			}
		case SYBCHAR:
		case XSYBCHAR:
		case SYBMSXML:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (BYTE *)val;
				pbuf->maxlen = len;
				pbuf->len = len;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, XSYBVARCHAR, 0, 0);
			}
		case XSYBNVARCHAR:
		case XSYBNCHAR:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (BYTE *)val;
				pbuf->maxlen = len;
				pbuf->len = len;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, datatype, 0, 0);
			}
		case SYBTEXT:
		case SYBNTEXT:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf = makeStringInfo();

				//pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				appendStringInfoString(pbuf, (BYTE *)val);
				//pbuf->data = (BYTE *)val;
				// pbuf->maxlen = strlen(pbuf->data);
				// pbuf->len = strlen(pbuf->data);
				// pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, datatype, 0, 0);
			}
		case SYBDATETIME:
		case SYBDATETIMN:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (BYTE *)val;
				pbuf->maxlen = 8;
				pbuf->len = 8;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, SYBDATETIMN, 0, 0);
			}
		case SYBDATETIME4:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				StringInfo pbuf;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = (BYTE *)val;
				pbuf->maxlen = 4;
				pbuf->len = 4;
				pbuf->cursor = 0;

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, SYBDATETIME4, 0, 0);
			}
		case SYBMSDATE:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				TDS_DATETIMEALL date;

				memcpy(&date, (TDS_DATETIMEALL *) val, sizeof(TDS_DATETIMEALL));

				/* No optional attribute */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(0, date.date, SYBMSDATE, 0);
			}
		case SYBTIME:
		case SYBMSTIME:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				TDS_DATETIMEALL time;
				// StringInfo pbuf;

				// int len;

				memcpy(&time, (TDS_DATETIMEALL *) val, sizeof(TDS_DATETIMEALL));
				// pbuf = palloc(sizeof(StringInfoData));

				// switch (time.time_prec)
				// {
				// 	case 0:
				// 	case 1:
				// 	case 2:
				// 		len = 3;
				// 		break;
				// 	case 3:
				// 	case 4:
				// 		len = 4;
				// 		break;
				// 	case 5:
				// 	case 6:
				// 	case 7:
				// 		len = 5;
				// 		break;
				// 	default:
				// 		len = 3;
				// 		break;
				// }

				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 * 
				 * We always get time with scale 7
				 */

				// pbuf->data = (BYTE *)&(time.time);
				// pbuf->maxlen = 5;
				// pbuf->len = 5;
				// pbuf->cursor = 0;

				// return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, SYBMSTIME, 7, 0);
				/* optional attribute here is scale */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(time.time, 0, SYBMSTIME, 7);
			}
		case SYBDECIMAL:
		case SYBNUMERIC:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr)
			{
				DBNUMERIC *numeric;
				StringInfo pbuf;
				int i = 0;
				char numeric_bytes[16] = {0x00};
				int n;

				numeric = (DBNUMERIC *)val;

				pbuf = palloc(sizeof(StringInfoData));
				/*
				 * Rather than copying data around, we just set up a phony
				 * StringInfo pointing to the correct portion of the TDS message
				 * buffer. 
				 */
				pbuf->data = numeric->array;

				// while (numeric->array[n] == 0x00 && n >= 0)
				// 	--n;

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

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, SYBNUMERIC, numeric->scale, numeric->precision);
			}
		case SYBFLTN:
		case SYBFLT8:
			return Float8GetDatum(*(float8 *)val);
		case SYBREAL:
			return Float4GetDatum(*(float4 *)val);
		case SYBINT1:
			return UInt8GetDatum(*(int16_t *)val);
		case SYBINT2:
			return Int16GetDatum(*(int16_t *)val);
		case SYBINT4:
		case SYBINTN:
			return Int32GetDatum(*(int32_t *)val);
		case SYBINT8:
			return Int64GetDatum(*(int64_t *)val);
		case SYBMONEY:
		case SYBMONEYN:
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

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, SYBMONEYN, 0, 0);
			}
		case SYBMONEY4:
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

				return (*pltsql_protocol_plugin_ptr)->get_datum_from_byte_ptr(pbuf, SYBMONEY4, 0, 0);
			}
		case SYBMSDATETIME2:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				TDS_DATETIMEALL *datetime2 = (TDS_DATETIMEALL *) val;

				/* optional attribute here is scale */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(datetime2->time, datetime2->date, SYBMSDATETIME2, 7);
			}
		case SYBMSDATETIMEOFFSET:
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct)
			{
				TDS_DATETIMEALL *datetimeoffset = (TDS_DATETIMEALL *) val;
				
				/* optional attribute here is time offset */
				return (*pltsql_protocol_plugin_ptr)->get_datum_from_date_time_struct(datetimeoffset->time, datetimeoffset->date, SYBMSDATETIMEOFFSET, datetimeoffset->offset);
			}
		default:
			return (Datum) 0;
	}

	return 0;
}

int
tdsTypeStrToTypeId(char* datatype)
{
	if (strcmp(datatype, "image") == 0)
		return SYBIMAGE;
	else if (strcmp(datatype, "varbinary") == 0)
		return XSYBVARBINARY;
	else if (strcmp(datatype, "binary") == 0)
		return XSYBBINARY;
	else if (strcmp(datatype, "bit") == 0)
		return SYBBIT;
	else if (strcmp(datatype, "ntext") == 0)
		return SYBNTEXT;
	else if (strcmp(datatype, "text") == 0)
		return SYBTEXT;
	else if (strcmp(datatype, "nvarchar") == 0)
		return XSYBNVARCHAR;
	else if (strcmp(datatype, "varchar") == 0)
		return XSYBVARCHAR;
	else if (strcmp(datatype, "nchar") == 0)
		return XSYBNCHAR;
	else if (strcmp(datatype, "char") == 0)
		return XSYBCHAR;
	else if (strcmp(datatype, "datetime") == 0)
		return SYBDATETIME;
	else if (strcmp(datatype, "datetime2") == 0)
		return SYBMSDATETIME2;
	else if (strcmp(datatype, "smalldatetime") == 0)
		return SYBDATETIME4;
	else if (strcmp(datatype, "datetimeoffset") == 0)
		return SYBMSDATETIMEOFFSET;
	else if (strcmp(datatype, "date") == 0)
		return SYBMSDATE;
	else if (strcmp(datatype, "time") == 0)
		return SYBMSTIME;
	else if (strcmp(datatype, "decimal") == 0)
		return SYBDECIMAL;
	else if (strcmp(datatype, "numeric") == 0)
		return SYBNUMERIC;
	else if (strcmp(datatype, "float") == 0)
		return SYBFLT8;
	else if (strcmp(datatype, "real") == 0)
		return SYBREAL;
	else if (strcmp(datatype, "tinyint") == 0)
		return SYBINT1;
	else if (strcmp(datatype, "smallint") == 0)
		return SYBINT2;
	else if (strcmp(datatype, "int") == 0)
		return SYBINTN;
	else if (strcmp(datatype, "bigint") == 0)
		return SYBINT8;
	else if (strcmp(datatype, "money") == 0)
		return SYBMONEYN;
	else if (strcmp(datatype, "smallmoney") == 0)
		return SYBMONEY4;
	else
		ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Unable to find type id for datatype %s", datatype)
				));

	return 0;
}

Oid
tdsTypeToOid(int datatype)
{
	switch (datatype)
	{
		case SYBIMAGE:
		case SYBVARBINARY:
		case SYBBINARY:
		case XSYBBINARY:
		case XSYBVARBINARY:
			return BYTEAOID;
		case SYBBIT:
		case SYBBITN:
			return lookup_tsql_datatype_oid("bit");
		case SYBTEXT:
		case SYBNTEXT:
			return TEXTOID;
		case SYBVARCHAR:
		case XSYBVARCHAR:
		case XSYBNVARCHAR:
		case SYBCHAR:
		case SYBMSXML:
			return VARCHAROID;
		case XSYBNCHAR:
		case XSYBCHAR:
			return lookup_tsql_datatype_oid("bpchar");
		case SYBDATETIME:
		case SYBDATETIMN:
			return lookup_tsql_datatype_oid("datetime");
		case SYBDATETIME4:
			return lookup_tsql_datatype_oid("smalldatetime");
		case SYBMSDATETIME2:
			return lookup_tsql_datatype_oid("datetime2");
		case SYBMSDATETIMEOFFSET:
			return lookup_tsql_datatype_oid("datetimeoffset");
		case SYBDATE:
		case SYBMSDATE:
			return DATEOID;
		case SYBTIME:
		case SYBMSTIME:
			return TIMEOID;
		case SYBDECIMAL:
		case SYBNUMERIC:
			return NUMERICOID;
		case SYBFLT8:
			return FLOAT8OID;
		case SYBREAL:
			return FLOAT4OID;
		case SYBINT1:
			return INT2OID;
		case SYBINT2:
			return INT2OID;
		case SYBINT4:
		case SYBINTN:
			return INT4OID;
		case SYBINT8:
			return INT8OID;
		case SYBMONEY:
		case SYBMONEYN:
		case SYBMONEY4:
			return lookup_tsql_datatype_oid("fixeddecimal");
		default:
			ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Unable to find OID for datatype %d", datatype)
				));
	}

	return 0;
}

int
tdsTypeLen(int datatype, int datalen, bool is_metadata)
{
	switch (datatype)
	{
		case SYBIMAGE:
		case SYBVARBINARY:
		case SYBBINARY:
		case XSYBBINARY:
		case XSYBVARBINARY:
			return datalen;
		case SYBVARCHAR:
		case SYBCHAR:
		case XSYBNVARCHAR:
		case XSYBVARCHAR:
		case SYBMSXML:
		case XSYBNCHAR:
		case XSYBCHAR:
			{
				if (is_metadata)
					return datalen + VARHDRSZ;
				else
					return (datalen/4) + VARHDRSZ;
			}
                case SYBBIT:
		case SYBBITN:
                case SYBTEXT:
		case SYBNTEXT:
		case SYBDATETIME:
		case SYBDATETIMN:
		case SYBDATETIME4:
		case SYBMSDATETIME2:
		case SYBMSDATETIMEOFFSET:
		case SYBDATE:
		case SYBMSDATE:
		case SYBTIME:
		case SYBMSTIME:
		case SYBDECIMAL:
		case SYBNUMERIC:
		case SYBFLT8:
		case SYBREAL:
		case SYBINT1:
		case SYBINT2:
		case SYBINT4:
		case SYBINTN:
		case SYBINT8:
		case SYBMONEY:
		case SYBMONEYN:
		case SYBMONEY4:
			return -1;
		default:
			ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Unable to find len for datatype %d", datatype)
				));
	}

	return 0;
}

void
linked_server_establish_connection(char* servername, LinkedServerProcess *dbproc)
{
#ifdef ENABLE_TDS_LIB
        LinkedServerLogin login;
        DefElem *element;
        DBINT erc;
#endif

        /* Get the foreign server and user mapping */
	ForeignServer *server = GetForeignServerByName(servername, false);
	UserMapping *mapping = GetUserMapping(GetUserId(), server->serverid);

#ifdef ENABLE_TDS_LIB
	LINKED_SERVER_INIT();

	LINKED_SERVER_ERR_HANDLE(tds_err_handler);
	LINKED_SERVER_MSG_HANDLE(tds_notice_msg_handler);

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
		*dbproc = LINKED_SERVER_OPEN(login, defGetString(element));
		if (!(*dbproc))
			ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Unable to connect to %s", defGetString(element))
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
		if (strlen(defGetString(element))) {
			erc = LINKED_SERVER_USE_DB(*dbproc, defGetString(element));
			Assert(erc == SUCCEED);
		}
	}
	else
		ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Incorrect option. Expected \"database\" but got \"%s\"", element->defname)
				));
#else
	ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Could not establish connection with remote server as use of TDS client library has been disabled."
						"Please recompile source with 'ENABLE_TDS_LIB' flag to enable client library.")
				));
#endif
}

/* 
 * Fetch the column medata for the expected result set 
 * from remote server 
 */
void
getOpenqueryTupdesc(char* linked_server, char* query, TupleDesc *tupdesc)
{
	LinkedServerProcess dbproc;

#ifdef ENABLE_TDS_LIB

	int i;
	LINKED_SERVER_RETCODE erc;

	int colcount;
	DefElem *element;

	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	StringInfoData buf;
#endif
	linked_server_establish_connection(linked_server, &dbproc);

#ifdef ENABLE_TDS_LIB

	/* prepare the query that will executed on remote server to get column medata of result set*/
	initStringInfo(&buf);
	appendStringInfoString(&buf, "EXEC sp_describe_first_result_set N'");
	appendStringInfoString(&buf, query);
	appendStringInfoString(&buf, "', NULL, 0");
	
	/* populate query in LinkedServerProcess structure */
	if ((erc = LINKED_SERVER_PUT_CMD(dbproc, buf.data)) != SUCCEED) {
		ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("error writing query to LinkedServerProcess struct")
				));
	}

	/* Execute the query on remote server */
	LINKED_SERVER_EXEC_QUERY(dbproc);

	while ((erc = dbresults(dbproc)) != NO_MORE_RESULTS)
	{
		if (erc == FAIL)
		{
			ereport(ERROR,
				(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Failed to get results from query %s", buf.data)
				));
		}

		/* We have some results to process */
		colcount = dbnumcols(dbproc);

		if(colcount > 0)
		{
			int numrows = 0;
			int i = 0;

			/* Build tupdesc for result tuples. */

			//for(i = 0; i < colcount; i++)
			int collen[MAX_COLS_SELECT];
			char **colname = (char **) palloc0(MAX_COLS_SELECT * sizeof(char*));
			char **typename = (char **) palloc0(MAX_COLS_SELECT * sizeof(char*));
			int tdsTypeId[MAX_COLS_SELECT];

			/* bound variables */
			int bind_collen;
			char bind_colname[256];
			char bind_typename[256];
			int bind_tdsTypeId;
			//int bind_errornumber;

			for (i = 0; i < MAX_COLS_SELECT; i++)
				colname[i] = (char *) palloc0(256 * sizeof(char));

			if ((erc = dbbind(dbproc, 3, NTBSTRINGBIND, sizeof(bind_colname), (BYTE *)bind_colname)) != SUCCEED)
				ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Failed to bind results for column \"name\" to a variable.")
				));

			if ((erc = dbbind(dbproc, 5, INTBIND, sizeof(int), (BYTE *)&bind_tdsTypeId)) != SUCCEED)
				ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Failed to bind results for column \"system_type_id\" to a variable.")
				));
			
			if ((erc = dbbind(dbproc, 6, NTBSTRINGBIND, sizeof(bind_typename), (BYTE *)&bind_typename)) != SUCCEED)
				ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Failed to bind results for column \"system_type_name\" to a variable.")
				));

			if ((erc = dbbind(dbproc, 7, INTBIND, sizeof(int), (BYTE *)&bind_collen)) != SUCCEED)
				ereport(ERROR,
					(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
					errmsg("Failed to bind results for column \"max_length\" to a variable.")
				));
			
			// if ((erc = dbbind(dbproc, 36, INTBIND, sizeof(int), (BYTE *)&bind_errornumber)) != SUCCEED)
			// 	ereport(ERROR,
			// 		(errcode(ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION),
			// 		errmsg("Failed to bind results for column \"error_number\" to a variable.")
			// 	));

			/* fetch the rows */
			while ((erc = dbnextrow(dbproc)) != NO_MORE_ROWS)
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
				strlcpy(colname[numrows], bind_colname, strlen(bind_colname) + 1);

				/* Only keep the data type name */
				typestr = strstr(bind_typename, "(");

				if (typestr != NULL)
					*typestr = '\0';

				tdsTypeId[numrows] = tdsTypeStrToTypeId(bind_typename);
				//tdsTypeId[numrows] = bind_tdsTypeId;
				++numrows;
			}

			if (numrows > 0)
			{
				*tupdesc = CreateTemplateTupleDesc(numrows);

				for (i = 0; i < numrows; i++)
					TupleDescInitEntry(*tupdesc, (AttrNumber) (i + 1), colname[i] != NULL ? colname[i] : "?column?", tdsTypeToOid(tdsTypeId[i]), tdsTypeLen(tdsTypeId[i], collen[i], true), 0);

				*tupdesc = BlessTupleDesc(*tupdesc);
			}
		}
	}
#endif
}