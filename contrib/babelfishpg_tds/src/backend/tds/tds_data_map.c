#include "postgres.h"

#include "mb/pg_wchar.h"
#include "access/attnum.h"
#include "lib/stringinfo.h"
#include "src/include/tds_typeio.h"
#include "src/include/tds_iofuncmap.h"


TdsLCIDToEncodingMap TdsLCIDToEncodingMap_data[] =
{
	{0x0436, PG_WIN1252}, //Afrikaans:South Africa
	{0x041c, PG_WIN1250}, //Albanian:Albania
	{0x1401, PG_WIN1256}, //Arabic:Algeria
	{0x3c01, PG_WIN1256}, //Arabic:Bahrain
	{0x0c01, PG_WIN1256}, //Arabic:Egypt
	{0x0801, PG_WIN1256}, //Arabic:Iraq
	{0x2c01, PG_WIN1256}, //Arabic:Jordan
	{0x3401, PG_WIN1256}, //Arabic:Kuwait
	{0x3001, PG_WIN1256}, //Arabic:Lebanon
	{0x1001, PG_WIN1256}, //Arabic:Libya
	{0x1801, PG_WIN1256}, //Arabic:Morocco
	{0x2001, PG_WIN1256}, //Arabic:Oman
	{0x4001, PG_WIN1256}, //Arabic:Qatar
	{0x0401, PG_WIN1256}, //Arabic:Saudi Arabia
	{0x2801, PG_WIN1256}, //Arabic:Syria
	{0x1c01, PG_WIN1256}, //Arabic:Tunisia
	{0x3801, PG_WIN1256}, //Arabic:U.A.E.
	{0x2401, PG_WIN1256}, //Arabic:Yemen
	/* {0x042b, 0},// Armenian: Armenia */
	{0x082c, PG_WIN1251}, //Azeri:Azerbaijan(Cyrillic)
	{0x042c, PG_WIN1250}, //Azeri:Azerbaijan(Latin)
	{0x042d, PG_WIN1252}, //Basque:Spain
	{0x0423, PG_WIN1251}, //Belarusian:Belarus
	{0x0402, PG_WIN1251}, //Bulgarian:Bulgaria
	{0x0403, PG_WIN1252}, //Catalan:Spain
	{0x0c04, PG_BIG5},
	{0x1404, PG_BIG5}, //Chinese:Macao SAR(Traditional)
	{0x0804, PG_GBK}, //Chinese:PRC(Simplified)
	{0x1004, PG_GBK}, //Chinese:Singapore(Simplified)
	{0x0404, PG_BIG5}, //Chinese:Taiwan(Traditional)
	/* {0x0827, PG_WIN1257}, */
	{0x041a, PG_WIN1250}, //Croatian:Croatia
	{0x0405, PG_WIN1250}, //Czech:Czech Republic
	{0x0406, PG_WIN1252}, //Danish:Denmark
	{0x0813, PG_WIN1252}, //Dutch:Belgium
	{0x0413, PG_WIN1252}, //Dutch:Netherlands
	{0x0c09, PG_WIN1252}, //English:Australia
	{0x2809, PG_WIN1252}, //English:Belize
	{0x1009, PG_WIN1252}, //English:Canada
	/* {0x2409, PG_WIN1252}, */
	{0x1809, PG_WIN1252}, //English:Ireland
	{0x2009, PG_WIN1252}, //English:Jamaica
	{0x1409, PG_WIN1252}, //English:New Zealand
	{0x3409, PG_WIN1252}, //English:Philippines
	{0x1c09, PG_WIN1252}, //English:South Africa
	{0x2c09, PG_WIN1252}, //English:Trinidad
	{0x0809, PG_WIN1252}, //English:United Kingdom
	{0x0409, PG_WIN1252}, //English:United States
	{0x3009, PG_WIN1252}, //English:Zimbabwe
	{0x0425, PG_WIN1257}, //Estonian:Estonia
	{0x0438, PG_WIN1252}, //Faeroese:Faeroe Islands
	{0x0429, PG_WIN1256}, //Farsi:Iran
	{0x040b, PG_WIN1252}, //Finnish:Finland
	{0x080c, PG_WIN1252}, //French:Belgium
	{0x0c0c, PG_WIN1252}, //French:Canada
	{0x040c, PG_WIN1252}, //French:France
	{0x140c, PG_WIN1252}, //French:Luxembourg
	{0x180c, PG_WIN1252}, //French:Monaco
	{0x100c, PG_WIN1252}, //French:Switzerland
	{0x042f, PG_WIN1251}, //Macedonian(FYROM)
	/* {0x0437, 0},// Georgian: Georgia */
	{0x0c07, PG_WIN1252}, //German:Austria
	{0x0407, PG_WIN1252}, //German:Germany
	{0x1407, PG_WIN1252}, //German:Liechtenstein
	{0x1007, PG_WIN1252}, //German:Luxembourg
	{0x0807, PG_WIN1252}, //German:Switzerland
	{0x0408, PG_WIN1253}, //Greek:Greece
	/* {0x0447, 0},// Gujarati: India */
	{0x040d, PG_WIN1255}, //Hebrew:Israel
	/* {0x0439, 0},// Hindi: India */
	{0x040e, PG_WIN1250}, //Hungarian:Hungary
	{0x040f, PG_WIN1252}, //Icelandic:Iceland
	{0x0421, PG_WIN1252}, //Indonesian:Indonesia
	{0x0410, PG_WIN1252}, //Italian:Italy
	{0x0810, PG_WIN1252}, //Italian:Switzerland
	{0x0411, PG_SJIS}, //Japanese:Japan
	/* {0x044b, 0},// Kannada: India */
	/* {0x0457, 0},// Konkani: India */
	{0x0412, PG_UHC}, //Korean(Extended Wansung):Korea
	{0x0440, PG_WIN1251}, //Kyrgyz:Kyrgyzstan
	{0x0426, PG_WIN1257}, //Latvian:Latvia
	{0x0427, PG_WIN1257}, //Lithuanian:Lithuania
	{0x083e, PG_WIN1252}, //Malay:Brunei Darussalam
	{0x043e, PG_WIN1252}, //Malay:Malaysia
	/* {0x044e, 0},// Marathi: India */
	{0x0450, PG_WIN1251}, //Mongolian:Mongolia
	{0x0414, PG_WIN1252}, //Norwegian:Norway(Bokm√ • l)
	{0x0814, PG_WIN1252}, //Norwegian:Norway(Nynorsk)
	{0x0415, PG_WIN1250}, //Polish:Poland
	{0x0416, PG_WIN1252}, //Portuguese:Brazil
	{0x0816, PG_WIN1252}, //Portuguese:Portugal
	/* {0x0446, 0},// Punjabi: India */
	{0x0418, PG_WIN1250}, //Romanian:Romania
	{0x0419, PG_WIN1251}, //Russian:Russia
	/* {0x044f, 0},// Sanskrit: India */
	{0x0c1a, PG_WIN1251}, //Serbian:Serbia(Cyrillic)
	{0x081a, PG_WIN1250}, //Serbian:Serbia(Latin)
	{0x041b, PG_WIN1250}, //Slovak:Slovakia
	{0x0424, PG_WIN1250}, //Slovenian:Slovenia
	{0x2c0a, PG_WIN1252}, //Spanish:Argentina
	{0x400a, PG_WIN1252}, //Spanish:Bolivia
	{0x340a, PG_WIN1252}, //Spanish:Chile
	{0x240a, PG_WIN1252}, //Spanish:Colombia
	{0x140a, PG_WIN1252}, //Spanish:Costa Rica
	{0x1c0a, PG_WIN1252}, //Spanish:Dominican Republic
	{0x300a, PG_WIN1252}, //Spanish:Ecuador
	{0x440a, PG_WIN1252}, //Spanish:El Salvador
	{0x100a, PG_WIN1252}, //Spanish:Guatemala
	{0x480a, PG_WIN1252}, //Spanish:Honduras
	{0x080a, PG_WIN1252}, //Spanish:Mexico
	{0x4c0a, PG_WIN1252}, //Spanish:Nicaragua
	{0x180a, PG_WIN1252}, //Spanish:Panama
	{0x3c0a, PG_WIN1252}, //Spanish:Paraguay
	{0x280a, PG_WIN1252}, //Spanish:Peru
	{0x500a, PG_WIN1252}, //Spanish:Puerto Rico
	{0x0c0a, PG_WIN1252}, //Spanish:Spain(Modern Sort)
	{0x040a, PG_WIN1252}, //Spanish:Spain(International Sort)
	{0x380a, PG_WIN1252}, //Spanish:Uruguay
	{0x200a, PG_WIN1252}, //Spanish:Venezuela
	{0x0441, PG_WIN1252}, //Swahili:Kenya
	{0x081d, PG_WIN1252}, //Swedish:Finland
	{0x041d, PG_WIN1252}, //Swedish:Sweden
	{0x0444, PG_WIN1251}, //Tatar:Tatarstan
	/* {0x044a, 0},// Telgu: India */
	{0x041e, PG_WIN874}, //Thai:Thailand
	{0x041f, PG_WIN1254}, //Turkish:Turkey
	{0x0422, PG_WIN1251}, //Ukrainian:Ukraine
	{0x0820, PG_WIN1256}, //Urdu:India
	{0x0420, PG_WIN1256}, //Urdu:Pakistan
	{0x0843, PG_WIN1251}, //Uzbek:Uzbekistan(Cyrillic)
	{0x0443, PG_WIN1250}, //Uzbek:Uzbekistan(Latin)
	{0x042a, PG_WIN1258} //Vietnamese:Vietnam
};

size_t		TdsLCIDToEncodingMap_datasize = lengthof(TdsLCIDToEncodingMap_data);

TdsIoFunctionRawData TdsIoFunctionRawData_data[] =
{
	{"sys", "bit", TDS_TYPE_BIT, 1, 1, TDS_SEND_BIT, TDS_RECV_BIT},
	{"sys", "tinyint", TDS_TYPE_INTEGER, 1, 1, TDS_SEND_TINYINT, TDS_RECV_TINYINT},
	{"pg_catalog", "int2", TDS_TYPE_INTEGER, 2, 1, TDS_SEND_SMALLINT, TDS_RECV_SMALLINT},
	{"pg_catalog", "int4", TDS_TYPE_INTEGER, 4, 1, TDS_SEND_INTEGER, TDS_RECV_INTEGER},
	{"pg_catalog", "int8", TDS_TYPE_INTEGER, 8, 1, TDS_SEND_BIGINT, TDS_RECV_BIGINT},
	{"pg_catalog", "float4", TDS_TYPE_FLOAT, 4, 1, TDS_SEND_FLOAT4, TDS_RECV_FLOAT4},
	{"pg_catalog", "float8", TDS_TYPE_FLOAT, 8, 1, TDS_SEND_FLOAT8, TDS_RECV_FLOAT8},
	{"pg_catalog", "bpchar", TDS_TYPE_CHAR, -1, 2, TDS_SEND_CHAR, TDS_RECV_CHAR},
	{"sys", "bpchar", TDS_TYPE_CHAR, -1, 2, TDS_SEND_CHAR, TDS_RECV_CHAR},
	{"sys", "nchar", TDS_TYPE_NCHAR, -1, 2, TDS_SEND_NCHAR, TDS_RECV_NCHAR},
	{"sys", "nvarchar", TDS_TYPE_NVARCHAR, -1, 2, TDS_SEND_NVARCHAR, TDS_RECV_NVARCHAR},
	{"sys", "varchar", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_VARCHAR},
	{"sys", "smallmoney", TDS_TYPE_MONEYN, 4, 1, TDS_SEND_SMALLMONEY, TDS_RECV_SMALLMONEY},
	{"sys", "money", TDS_TYPE_MONEYN, 8, 1, TDS_SEND_MONEY, TDS_RECV_MONEY},
	{"pg_catalog", "text", TDS_TYPE_TEXT, -1, 2, TDS_SEND_TEXT, TDS_RECV_TEXT},
	{"sys", "ntext", TDS_TYPE_NTEXT, -1, 2, TDS_SEND_NTEXT, TDS_RECV_NTEXT},
	{"pg_catalog", "date", TDS_TYPE_DATE, 3, 1, TDS_SEND_DATE, TDS_RECV_DATE},
	{"sys", "datetime", TDS_TYPE_DATETIMEN, 8, 1, TDS_SEND_DATETIME, TDS_RECV_DATETIME},
	{"pg_catalog", "numeric", TDS_TYPE_NUMERICN, 17, 1, TDS_SEND_NUMERIC, TDS_RECV_NUMERIC},
	{"sys", "decimal", TDS_TYPE_DECIMALN, 17, 1, TDS_SEND_NUMERIC, TDS_RECV_NUMERIC},
	{"sys", "smalldatetime", TDS_TYPE_DATETIMEN, 4, 1, TDS_SEND_SMALLDATETIME, TDS_RECV_SMALLDATETIME},
	{"sys", "binary", TDS_TYPE_BINARY, -1, 2, TDS_SEND_BINARY, TDS_RECV_BINARY},
	{"sys", "bbf_binary", TDS_TYPE_BINARY, -1, 2, TDS_SEND_BINARY, TDS_RECV_BINARY},
	{"sys", "varbinary", TDS_TYPE_VARBINARY, -1, 2, TDS_SEND_VARBINARY, TDS_RECV_VARBINARY},
	{"sys", "bbf_varbinary", TDS_TYPE_VARBINARY, -1, 2, TDS_SEND_VARBINARY, TDS_RECV_VARBINARY},
	{"sys", "image", TDS_TYPE_IMAGE, -1, 2, TDS_SEND_IMAGE, TDS_RECV_IMAGE},
	{"sys", "uniqueidentifier", TDS_TYPE_UNIQUEIDENTIFIER, 16, 1, TDS_SEND_UNIQUEIDENTIFIER, TDS_RECV_UNIQUEIDENTIFIER},
	{"pg_catalog", "time", TDS_TYPE_TIME, 5, 1, TDS_SEND_TIME, TDS_RECV_TIME},
	{"sys", "datetime2", TDS_TYPE_DATETIME2, 8, 1, TDS_SEND_DATETIME2, TDS_RECV_DATETIME2},
	{"pg_catalog", "xml", TDS_TYPE_XML, -1, 1, TDS_SEND_XML, TDS_RECV_XML},
	{"sys", "sql_variant", TDS_TYPE_SQLVARIANT, -1, 4, TDS_SEND_SQLVARIANT, TDS_RECV_SQLVARIANT},
	{"sys", "datetimeoffset", TDS_TYPE_DATETIMEOFFSET, 10, 1, TDS_SEND_DATETIMEOFFSET, TDS_RECV_DATETIMEOFFSET},
	{"sys", "fixeddecimal", TDS_TYPE_MONEYN, 8, 1, TDS_SEND_MONEY, TDS_RECV_INVALID},
	{"sys", "rowversion", TDS_TYPE_BINARY, 8, 2, TDS_SEND_BINARY, TDS_RECV_BINARY},
	{"sys", "timestamp", TDS_TYPE_BINARY, 8, 2, TDS_SEND_BINARY, TDS_RECV_BINARY},

	/* Mapping TDS listener sender to basic Postgres datatypes. */
	{"pg_catalog", "oid", TDS_TYPE_INTEGER, 4, 1, TDS_SEND_INTEGER, TDS_RECV_INVALID},
	{"pg_catalog", "sql_identifier", TDS_TYPE_VARCHAR, -1, 1, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "name", TDS_TYPE_VARCHAR, -1, 1, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "character_data", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "bool", TDS_TYPE_BIT, 1, 1, TDS_SEND_BIT, TDS_RECV_INVALID},
	{"pg_catalog", "varchar", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "cardinal_number", TDS_TYPE_INTEGER, 4, 1, TDS_SEND_INTEGER, TDS_RECV_INVALID},
	{"pg_catalog", "yes_or_no", TDS_TYPE_VARCHAR, -1, 1, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "char", TDS_TYPE_VARCHAR, -1, 1, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "timestamp", TDS_TYPE_DATETIMEN, 8, 1, TDS_SEND_DATETIME, TDS_RECV_INVALID},
	{"pg_catalog", "timestamptz", TDS_TYPE_VARCHAR, -1, 1, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "regproc", TDS_TYPE_VARCHAR, -1, 1, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "cstring", TDS_TYPE_TEXT, -1, 2, TDS_SEND_TEXT, TDS_RECV_INVALID},
	{"pg_catalog", "real", TDS_TYPE_FLOAT, 4, 1, TDS_SEND_FLOAT4, TDS_RECV_INVALID},
	{"pg_catalog", "aclitem", TDS_TYPE_VARCHAR, -1, 1, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "int2vector", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "oidvector", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "pg_node_tree", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "pg_lsn", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_oid", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_text", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_aclitem", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_float4", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_float8", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_int2", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_real", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "_char", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "pg_dependencies", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "pg_ndistinct", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "anyarray", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "xid", TDS_TYPE_INTEGER, 4, 1, TDS_SEND_INTEGER, TDS_RECV_INVALID},
	{"pg_catalog", "cid", TDS_TYPE_INTEGER, 4, 1, TDS_SEND_INTEGER, TDS_RECV_INVALID},
	{"pg_catalog", "tid", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "inet", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "interval", TDS_TYPE_VARCHAR, -1, 2, TDS_SEND_VARCHAR, TDS_RECV_INVALID},
	{"pg_catalog", "bytea", TDS_TYPE_VARBINARY, -1, 2, TDS_SEND_VARBINARY, TDS_RECV_INVALID}
};

size_t		TdsIoFunctionRawData_datasize = lengthof(TdsIoFunctionRawData_data);
