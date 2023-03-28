#ifndef DATATYPE_INFO_TABLE
#define DATATYPE_INFO_TABLE

#define NULLVAL		PG_INT32_MIN
#define NULLVAL_STR	"NULL"

#define DATATYPE_INFO_TABLE_ROWS 37

typedef struct DatatypeInfo
{
	const char *type_name;

	/* data_type is OdbcVer and procedure dependent */
	int			data_type_2;
	int			data_type_3;
	int			data_type_2_100;
	int			data_type_3_100;
	uint64		precision;
	const char *literal_prefix;
	const char *literal_suffix;
	const char *create_params;
	int			nullable;
	int			case_sensitive;
	int			searchable;
	int			unsigned_attribute;
	int			money;
	int			auto_increment;
	const char *local_type_name;
	int			minimum_scale;
	int			maximum_scale;
	int			sql_data_type;
	int			sql_datetime_sub;
	int			num_prec_radix;
	int			interval_precision;
	int			usertype;
	int			length;
	int			ss_data_type;
	const char *pg_type_name;
} DatatypeInfo;

/*
 * instead of having a NULL flag for every integer and string
 * member type variable, we just set such variables to NULLVAL
 * and NULLVAL_STR respectively, if we want to treat them as NULL
 */
static const DatatypeInfo datatype_info_table[DATATYPE_INFO_TABLE_ROWS] = {
	{
		"datetimeoffset",
		-9, -9, -155, -155,
		34,
		"'",
		"'",
		"scale               ",
		1, 0, 3, NULLVAL, 0, NULLVAL,
		"datetimeoffset",
		0, 7, -155, 0, NULLVAL, NULLVAL, 0, 68, 0,
		"datetimeoffset"
	},
	{
		"time",
		-9, -9, -154, -154,
		16,
		"'",
		"'",
		"scale               ",
		1, 0, 3, NULLVAL, 0, NULLVAL,
		"time",
		0, 7, -154, 0, NULLVAL, NULLVAL, 0, 32, 0,
		"time"
	},
	{
		"xml",
		-10, -10, -152, -152,
		0,
		"N'",
		"'",
		NULLVAL_STR,
		1, 1, 0, NULLVAL, 0, NULLVAL,
		"xml",
		NULLVAL, NULLVAL, -152, NULLVAL, NULLVAL, NULLVAL, 0, 2147483646, 0,
		"xml"
	},
	{
		"sql_variant",
		-150, -150, -150, -150,
		8000,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, NULLVAL, 0, NULLVAL,
		"sql_variant",
		0, 0, -150, NULLVAL, 10, NULLVAL, 0, 8000, 39,
		"sql_variant"
	},
	{
		"uniqueidentifier",
		-11, -11, -11, -11,
		36,
		"'",
		"'",
		NULLVAL_STR,
		1, 0, 2, NULLVAL, 0, NULLVAL,
		"uniqueidentifier",
		NULLVAL, NULLVAL, -11, NULLVAL, NULLVAL, NULLVAL, 0, 16, 37,
		"uniqueidentifier"
	},
	{
		"ntext",
		-10, -10, -10, -10,
		1073741823,
		"N'",
		"'",
		NULLVAL_STR,
		1, 1, 1, NULLVAL, 0, NULLVAL,
		"ntext",
		NULLVAL, NULLVAL, -10, NULLVAL, NULLVAL, NULLVAL, 0, 2147483646, 35,
		NULLVAL_STR
	},
	{
		"nvarchar",
		-9, -9, -9, -9,
		4000,
		"N'",
		"'",
		"max length          ",
		1, 1, 3, NULLVAL, 0, NULLVAL,
		"nvarchar",
		NULLVAL, NULLVAL, -9, NULLVAL, NULLVAL, NULLVAL, 0, 2, 39,
		NULLVAL_STR
	},
	{
		"sysname",
		-9, -9, -9, -9,
		128,
		"N'",
		"'",
		NULLVAL_STR,
		0, 1, 3, NULLVAL, 0, NULLVAL,
		"sysname",
		NULLVAL, NULLVAL, -9, NULLVAL, NULLVAL, NULLVAL, 18, 256, 39,
		NULLVAL_STR
	},
	{
		"nchar",
		-8, -8, -8, -8,
		4000,
		"N'",
		"'",
		"length              ",
		1, 1, 3, NULLVAL, 0, NULLVAL,
		"nchar",
		NULLVAL, NULLVAL, -8, NULLVAL, NULLVAL, NULLVAL, 0, 2, 39,
		NULLVAL_STR
	},
	{
		"bit",
		-7, -7, -7, -7,
		1,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, NULLVAL, 0, NULLVAL,
		"bit",
		0, 0, -7, NULLVAL, NULLVAL, NULLVAL, 16, 1, 50,
		"bit"
	},
	{
		"tinyint",
		-6, -6, -6, -6,
		3,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 1, 0, 0,
		"tinyint",
		0, 0, -6, NULLVAL, 10, NULLVAL, 5, 1, 38,
		NULLVAL_STR
	},
	{
		"tinyint identity",
		-6, -6, -6, -6,
		3,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		0, 0, 2, 1, 0, 1,
		"tinyint identity",
		0, 0, -6, NULLVAL, 10, NULLVAL, 5, 1, 38,
		NULLVAL_STR
	},
	{
		"bigint",
		-5, -5, -5, -5,
		19,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 0, 0, 0,
		"bigint",
		0, 0, -5, NULLVAL, 10, NULLVAL, 0, 8, 108,
		"int8"
	},
	{
		"bigint identity",
		-5, -5, -5, -5,
		19,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		0, 0, 2, 0, 0, 1,
		"bigint identity",
		0, 0, -5, NULLVAL, 10, NULLVAL, 0, 8, 108,
		NULLVAL_STR
	},
	{
		"image",
		-4, -4, -4, -4,
		2147483647,
		"0x",
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 0, NULLVAL, 0, NULLVAL,
		"image",
		NULLVAL, NULLVAL, -4, NULLVAL, NULLVAL, NULLVAL, 20, 2147483647, 4,
		NULLVAL_STR
	},
	{
		"varbinary",
		-3, -3, -3, -3,
		8000,
		"0x",
		NULLVAL_STR,
		"max length          ",
		1, 0, 2, NULLVAL, 0, NULLVAL,
		"varbinary",
		NULLVAL, NULLVAL, -3, NULLVAL, NULLVAL, NULLVAL, 4, 1, 37,
		NULLVAL_STR
	},
	{
		"binary",
		-2, -2, -2, -2,
		8000,
		"0x",
		NULLVAL_STR,
		"length              ",
		1, 0, 2, NULLVAL, 0, NULLVAL,
		"binary",
		NULLVAL, NULLVAL, -2, NULLVAL, NULLVAL, NULLVAL, 3, 1, 37,
		NULLVAL_STR
	},
	{
		"timestamp",
		-2, -2, -2, -2,
		8,
		"0x",
		NULLVAL_STR,
		NULLVAL_STR,
		0, 0, 2, NULLVAL, 0, NULLVAL,
		"timestamp",
		NULLVAL, NULLVAL, -2, NULLVAL, NULLVAL, NULLVAL, 80, 8, 45,
		"timestamp"
	},
	{
		"text",
		-1, -1, -1, -1,
		2147483647,
		"'",
		"'",
		NULLVAL_STR,
		1, 1, 1, NULLVAL, 0, NULLVAL,
		"text",
		NULLVAL, NULLVAL, -1, NULLVAL, NULLVAL, NULLVAL, 19, 2147483647, 35,
		NULLVAL_STR
	},
	{
		"char",
		1, 1, 1, 1,
		8000,
		"'",
		"'",
		"length              ",
		1, 1, 3, NULLVAL, 0, NULLVAL,
		"char",
		NULLVAL, NULLVAL, 1, NULLVAL, NULLVAL, NULLVAL, 1, 1, 39,
		"bpchar"
	},
	{
		"numeric",
		2, 2, 2, 2,
		38,
		NULLVAL_STR,
		NULLVAL_STR,
		"precision,scale     ",
		1, 0, 2, 0, 0, 0,
		"numeric",
		0, 38, 2, NULLVAL, 10, NULLVAL, 10, 20, 108,
		"numeric"
	},
	{
		"numeric() identity",
		2, 2, 2, 2,
		38,
		NULLVAL_STR,
		NULLVAL_STR,
		"precision           ",
		0, 0, 2, 0, 0, 1,
		"numeric() identity",
		0, 0, 2, NULLVAL, 10, NULLVAL, 10, 20, 108,
		NULLVAL_STR
	},
	{
		"decimal",
		3, 3, 3, 3,
		38,
		NULLVAL_STR,
		NULLVAL_STR,
		"precision,scale     ",
		1, 0, 2, 0, 0, 0,
		"decimal",
		0, 38, 3, NULLVAL, 10, NULLVAL, 24, 20, 106,
		NULLVAL_STR
	},
	{
		"money",
		3, 3, 3, 3,
		19,
		"$",
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 0, 1, 0,
		"money",
		4, 4, 3, NULLVAL, 10, NULLVAL, 11, 21, 110,
		NULLVAL_STR
	},
	{
		"smallmoney",
		3, 3, 3, 3,
		10,
		"$",
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 0, 1, 0,
		"smallmoney",
		4, 4, 3, NULLVAL, 10, NULLVAL, 21, 12, 110,
		NULLVAL_STR
	},
	{
		"decimal() identity",
		3, 3, 3, 3,
		38,
		NULLVAL_STR,
		NULLVAL_STR,
		"precision           ",
		0, 0, 2, 0, 0, 1,
		"decimal() identity",
		0, 0, 3, NULLVAL, 10, NULLVAL, 24, 20, 106,
		NULLVAL_STR
	},
	{
		"int",
		4, 4, 4, 4,
		10,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 0, 0, 0,
		"int",
		0, 0, 4, NULLVAL, 10, NULLVAL, 7, 4, 38,
		"int4"
	},
	{
		"int identity",
		4, 4, 4, 4,
		10,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		0, 0, 2, 0, 0, 1,
		"int identity",
		0, 0, 4, NULLVAL, 10, NULLVAL, 7, 4, 38,
		""
	},
	{
		"smallint",
		5, 5, 5, 5,
		5,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 0, 0, 0,
		"smallint",
		0, 0, 5, NULLVAL, 10, NULLVAL, 6, 2, 38,
		"int2"
	},
	{
		"smallint identity",
		5, 5, 5, 5,
		5,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		0, 0, 2, 0, 0, 1,
		"smallint identity",
		0, 0, 5, NULLVAL, 10, NULLVAL, 6, 2, 38,
		NULLVAL_STR
	},
	{
		"float",
		6, 6, 6, 6,
		53,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 0, 0, 0,
		"float",
		NULLVAL, NULLVAL, 6, NULLVAL, 2, NULLVAL, 8, 8, 109,
		"float8"
	},
	{
		"real",
		7, 7, 7, 7,
		24,
		NULLVAL_STR,
		NULLVAL_STR,
		NULLVAL_STR,
		1, 0, 2, 0, 0, 0,
		"real",
		NULLVAL, NULLVAL, 7, NULLVAL, 2, NULLVAL, 23, 4, 109,
		"float4"
	},
	{
		"varchar",
		12, 12, 12, 12,
		8000,
		"'",
		"'",
		"max length          ",
		1, 1, 3, NULLVAL, 0, NULLVAL,
		"varchar",
		NULLVAL, NULLVAL, 12, NULLVAL, NULLVAL, NULLVAL, 2, 1, 39,
		NULLVAL_STR
	},
	{
		"date",
		-9, -9, 9, 91,
		10,
		"'",
		"'",
		NULLVAL_STR,
		1, 0, 3, NULLVAL, 0, NULLVAL,
		"date",
		NULLVAL, 0, 9, 1, NULLVAL, NULLVAL, 0, 20, 0,
		"date"
	},
	{
		"datetime2",
		-9, -9, 11, 93,
		27,
		"'",
		"'",
		"scale               ",
		1, 0, 3, NULLVAL, 0, NULLVAL,
		"datetime2",
		0, 7, 9, 3, NULLVAL, NULLVAL, 0, 54, 0,
		"datetime2"
	},
	{
		"datetime",
		11, 93, 11, 93,
		23,
		"'",
		"'",
		NULLVAL_STR,
		1, 0, 3, NULLVAL, 0, NULLVAL,
		"datetime",
		3, 3, 9, 3, NULLVAL, NULLVAL, 12, 16, 111,
		"datetime"
	},
	{
		"smalldatetime",
		11, 93, 11, 93,
		16,
		"'",
		"'",
		NULLVAL_STR,
		1, 0, 3, NULLVAL, 0, NULLVAL,
		"smalldatetime",
		0, 0, 9, 3, NULLVAL, NULLVAL, 22, 16, 111,
		"smalldatetime"
	}
};

#endif							/* DATATYPE_INFO_TABLE */
