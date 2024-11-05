#include "postgres.h"
#include "varatt.h"

#include "utils/guc.h"
#include "utils/hsearch.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/memutils.h"
#include "utils/builtins.h"
#include "catalog/pg_type.h"
#include "catalog/pg_collation.h"
#include "catalog/namespace.h"
#include "tsearch/ts_locale.h"
#include "parser/parser.h"
#include "parser/parse_type.h"
#include "parser/parse_oper.h"
#include "nodes/makefuncs.h"

#include "collation.h"
#include "encoding/encoding.h"
#include "typecode.h"
#include "sqlvariant.h"

#define NOT_FOUND -1

#define DATABASE_DEFAULT "database_default"
#define CATALOG_DEFAULT "catalog_default"

collation_callbacks collation_callbacks_var = {NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};

/* Cached values derived from server_collation_name */
static int	server_collation_collidx = NOT_FOUND;
static Oid	server_collation_oid = InvalidOid;
static bool db_collation_is_CI = true;

static Oid database_collation_oid = InvalidOid;
static int database_collation_collidx = NOT_FOUND;

/*
 * Below two vars are defined to store the value of the babelfishpg_tsql.server_collation_name
 * and babelfishpg_tsql.default_locale.
 * We only need to lookup and store once because they can not be changed once babelfish db is initialised.
 */
static char *server_collation_name = NULL;
static const char *bbf_default_locale = NULL;

/* Hash tables to help backward searching (from OID to Persist ID) */
HTAB	   *ht_like2ilike = NULL;
HTAB	   *ht_oid2collid = NULL;



/* This table is storing the necessary info for
 * LIKE to ILIKE transformation(BABEL-1529)
 * we query the oid from the operator name(column 2 and 3)
 * and operand type(colume 4,5,6 and 7)
 */
like_ilike_info like_ilike_table[] =
{
	{0, "~~", "~~*", "pg_catalog", "name", "pg_catalog", "text", false, 0},
	{0, "!~~", "!~~*", "pg_catalog", "name", "pg_catalog", "text", true, 0},
	{0, "~~", "~~*", "pg_catalog", "text", "pg_catalog", "text", false, 0},
	{0, "!~~", "!~~*", "pg_catalog", "text", "pg_catalog", "text", true, 0},
	{0, "~~", "~~*", "pg_catalog", "bpchar", "pg_catalog", "text", false, 0},
	{0, "!~~", "!~~*", "pg_catalog", "bpchar", "pg_catalog", "text", true, 0},
	{0, "~~", "~~*", "sys", "bpchar", "pg_catalog", "text", false, 0},
	{0, "!~~", "!~~*", "sys", "bpchar", "pg_catalog", "text", true, 0},
};

#define TOTAL_LIKE_OP_COUNT (sizeof(like_ilike_table)/sizeof(like_ilike_table[0]))

/* Important point to note while adding new collations to the structure below:
 * We need to make sure that any newly introduced collation should keep the
 * below structure for coll_infos sorted lexicographically by collname.
 * Otherwise it will break collationproperty().
 *
 * In addition, all collations in this list must have a suffix of the form Cx_Ay,
 * which implies that the CS_AS collation sorts last among collations with the
 * same collation name prefix.
*/

/* Automatic collation translation table.  This must be sorted by the first column,
 * which contains the name of the collation to be translated from.  The second
 * column is the name of the collation to translate to.
 */
coll_translate_t coll_translations[] =
{
	{"latin1_general_100_bin2", "bbf_unicode_bin2", 1252},
	{"latin1_general_140_bin2", "bbf_unicode_bin2", 1252},
	{"latin1_general_90_bin2", "bbf_unicode_bin2", 1252},
	{"latin1_general_bin2", "bbf_unicode_bin2", 1252},
	{"latin1_general_ci_ai", "bbf_unicode_cp1_ci_ai", 1252},
	{"latin1_general_ci_as", "bbf_unicode_cp1_ci_as", 1252},
	{"latin1_general_cs_ai", "bbf_unicode_cp1_cs_ai", 1252},
	{"latin1_general_cs_as", "bbf_unicode_cp1_cs_as", 1252},
	{"sql_latin1_general_cp1250_ci_as", "bbf_unicode_cp1250_ci_as", 1250},
	{"sql_latin1_general_cp1250_cs_as", "bbf_unicode_cp1250_cs_as", 1250},
	{"sql_latin1_general_cp1251_ci_as", "bbf_unicode_cp1_ci_as", 1251},
	{"sql_latin1_general_cp1251_cs_as", "bbf_unicode_cp1_cs_as", 1251},
	{"sql_latin1_general_cp1253_ci_as", "bbf_unicode_cp1253_ci_as", 1253},
	{"sql_latin1_general_cp1253_cs_as", "bbf_unicode_cp1253_cs_as", 1253},
	{"sql_latin1_general_cp1254_ci_as", "bbf_unicode_cp1254_ci_as", 1254},
	{"sql_latin1_general_cp1254_cs_as", "bbf_unicode_cp1254_cs_as", 1254},
	{"sql_latin1_general_cp1255_ci_as", "bbf_unicode_cp1255_ci_as", 1255},
	{"sql_latin1_general_cp1255_cs_as", "bbf_unicode_cp1255_cs_as", 1255},
	{"sql_latin1_general_cp1256_ci_as", "bbf_unicode_cp1256_ci_as", 1256},
	{"sql_latin1_general_cp1256_cs_as", "bbf_unicode_cp1256_cs_as", 1256},
	{"sql_latin1_general_cp1257_ci_as", "bbf_unicode_cp1257_ci_as", 1257},
	{"sql_latin1_general_cp1257_cs_as", "bbf_unicode_cp1257_cs_as", 1257},
	{"sql_latin1_general_cp1258_ci_as", "bbf_unicode_cp1258_ci_as", 1258},
	{"sql_latin1_general_cp1258_cs_as", "bbf_unicode_cp1258_cs_as", 1258},
	{"sql_latin1_general_cp1_ci_ai", "bbf_unicode_cp1_ci_ai", 1252},
	{"sql_latin1_general_cp1_ci_as", "bbf_unicode_cp1_ci_as", 1252},	/* default */
	{"sql_latin1_general_cp1_cs_ai", "bbf_unicode_cp1_cs_ai", 1252},
	{"sql_latin1_general_cp1_cs_as", "bbf_unicode_cp1_cs_as", 1252},

	/* { "sql_latin1_general_cp850_ci_as", "bbf_unicode_cp850_ci_as", 850 }, */
	/* { "sql_latin1_general_cp850_cs_as", "bbf_unicode_cp850_cs_as", 850 }, */

	{"sql_latin1_general_cp874_ci_as", "bbf_unicode_cp874_ci_as", 874},
	{"sql_latin1_general_cp874_cs_as", "bbf_unicode_cp874_cs_as", 874},
	{"sql_latin1_general_pref_cp1_cs_as", "bbf_unicode_pref_cp1_cs_as", 1252}

};
#define TOTAL_COLL_TRANSLATION_COUNT (sizeof(coll_translations)/sizeof(coll_translations[0]))

/*
 * Reverse Collation translation table.  The first column (BBF collation) contains
 * the name of the collation to be translated from.  The second column
 * (TSQL Collation) is the name of the collation to translate to.
 */
coll_translate_t reverse_coll_translations[] =
{
	{"bbf_unicode_cp1_ci_as", "latin1_general_ci_as", 1252},	/* default */
	{"bbf_unicode_cp1_ci_ai", "latin1_general_ci_ai", 1252},
	{"bbf_unicode_cp1_cs_ai", "latin1_general_cs_ai", 1252},
	{"bbf_unicode_cp1_cs_as", "latin1_general_cs_as", 1252},
	{"bbf_unicode_bin2", "latin1_general_bin2", 1252},
	{"bbf_unicode_cp1250_ci_as", "sql_latin1_general_cp1250_ci_as", 1250},
	{"bbf_unicode_cp1250_cs_as", "sql_latin1_general_cp1250_cs_as", 1250},
	{"bbf_unicode_cp1253_ci_as", "sql_latin1_general_cp1253_ci_as", 1253},
	{"bbf_unicode_cp1253_cs_as", "sql_latin1_general_cp1253_cs_as", 1253},
	{"bbf_unicode_cp1254_ci_as", "sql_latin1_general_cp1254_ci_as", 1254},
	{"bbf_unicode_cp1254_cs_as", "sql_latin1_general_cp1254_cs_as", 1254},
	{"bbf_unicode_cp1255_ci_as", "sql_latin1_general_cp1255_ci_as", 1255},
	{"bbf_unicode_cp1255_cs_as", "sql_latin1_general_cp1255_cs_as", 1255},
	{"bbf_unicode_cp1256_ci_as", "sql_latin1_general_cp1256_ci_as", 1256},
	{"bbf_unicode_cp1256_cs_as", "sql_latin1_general_cp1256_cs_as", 1256},
	{"bbf_unicode_cp1257_ci_as", "sql_latin1_general_cp1257_ci_as", 1257},
	{"bbf_unicode_cp1257_cs_as", "sql_latin1_general_cp1257_cs_as", 1257},
	{"bbf_unicode_cp1258_ci_as", "sql_latin1_general_cp1258_ci_as", 1258},
	{"bbf_unicode_cp1258_cs_as", "sql_latin1_general_cp1258_cs_as", 1258},
	{"bbf_unicode_cp874_ci_as", "sql_latin1_general_cp874_ci_as", 874},
	{"bbf_unicode_cp874_cs_as", "sql_latin1_general_cp874_cs_as", 874},
	{"bbf_unicode_pref_cp1_cs_as", "sql_latin1_general_pref_cp1_cs_as", 1252}
};

#define TOTAL_REVERSE_COLL_TRANSLATION_COUNT (sizeof(reverse_coll_translations)/sizeof(reverse_coll_translations[0]))

coll_info	coll_infos[] =
{
	{0, "arabic_ci_ai", 1025, 0, 196608, 0, 0x000f, 1256, PG_WIN1256,},
	{0, "arabic_ci_as", 1025, 0, 196608, 0, 0x000d, 1256, PG_WIN1256,},
	{0, "arabic_cs_as", 1025, 0, 196608, 0, 0x000c, 1256, PG_WIN1256,},

	{0, "bbf_unicode_bin2", 1033, 0, 196608, 54, 0x0220, 1252, PG_WIN1252},

	{0, "bbf_unicode_cp1250_ci_ai", 1045, 0, 196608, 0, 0x000f, 1250, PG_WIN1250,},
	{0, "bbf_unicode_cp1250_ci_as", 1045, 0, 196608, 0, 0x000d, 1250, PG_WIN1250,},
	{0, "bbf_unicode_cp1250_cs_ai", 1045, 0, 196608, 0, 0x000e, 1250, PG_WIN1250,},
	{0, "bbf_unicode_cp1250_cs_as", 1045, 0, 196608, 0, 0x000c, 1250, PG_WIN1250,},

	{0, "bbf_unicode_cp1251_ci_ai", 1049, 0, 196608, 0, 0x000f, 1251, PG_WIN1251},
	{0, "bbf_unicode_cp1251_ci_as", 1049, 0, 196608, 0, 0x000d, 1251, PG_WIN1251},
	{0, "bbf_unicode_cp1251_cs_ai", 1049, 0, 196608, 0, 0x000e, 1251, PG_WIN1251},
	{0, "bbf_unicode_cp1251_cs_as", 1049, 0, 196608, 0, 0x000c, 1251, PG_WIN1251},

	/*
	 * {0, "bbf_unicode_cp1252_ci_ai",      1033, 0, 196608, 54, 0x000f, 1252,
	 * PG_WIN1252},
	 */

	/*
	 * {0, "bbf_unicode_cp1252_ci_as",      1033, 0, 196608, 52, 0x000d, 1252,
	 * PG_WIN1252},
	 */

	/*
	 * {0, "bbf_unicode_cp1252_cs_ai",      1033, 0, 196608, 51, 0x000e, 1252,
	 * PG_WIN1252},
	 */

	/*
	 * {0, "bbf_unicode_cp1252_cs_as",      1033, 0, 196608, 51, 0x000c, 1252,
	 * PG_WIN1252},
	 */

	{0, "bbf_unicode_cp1253_ci_ai", 1032, 0, 196608, 0, 0x000f, 1253, PG_WIN1253},
	{0, "bbf_unicode_cp1253_ci_as", 1032, 0, 196608, 0, 0x000d, 1253, PG_WIN1253},
	{0, "bbf_unicode_cp1253_cs_ai", 1032, 0, 196608, 0, 0x000e, 1253, PG_WIN1253},
	{0, "bbf_unicode_cp1253_cs_as", 1032, 0, 196608, 0, 0x000c, 1253, PG_WIN1253},

	{0, "bbf_unicode_cp1254_ci_ai", 1055, 0, 196608, 0, 0x000f, 1254, PG_WIN1254},
	{0, "bbf_unicode_cp1254_ci_as", 1055, 0, 196608, 0, 0x000d, 1254, PG_WIN1254},
	{0, "bbf_unicode_cp1254_cs_ai", 1055, 0, 196608, 0, 0x000e, 1254, PG_WIN1254},
	{0, "bbf_unicode_cp1254_cs_as", 1055, 0, 196608, 0, 0x000c, 1254, PG_WIN1254},

	{0, "bbf_unicode_cp1255_ci_ai", 1037, 0, 196608, 0, 0x000f, 1255, PG_WIN1255},
	{0, "bbf_unicode_cp1255_ci_as", 1037, 0, 196608, 0, 0x000d, 1255, PG_WIN1255},
	{0, "bbf_unicode_cp1255_cs_ai", 1037, 0, 196608, 0, 0x000e, 1255, PG_WIN1255},
	{0, "bbf_unicode_cp1255_cs_as", 1037, 0, 196608, 0, 0x000c, 1255, PG_WIN1255},

	{0, "bbf_unicode_cp1256_ci_ai", 1025, 0, 196608, 0, 0x000f, 1256, PG_WIN1256,},
	{0, "bbf_unicode_cp1256_ci_as", 1025, 0, 196608, 0, 0x000d, 1256, PG_WIN1256,},
	{0, "bbf_unicode_cp1256_cs_ai", 1025, 0, 196608, 0, 0x000e, 1256, PG_WIN1256,},
	{0, "bbf_unicode_cp1256_cs_as", 1025, 0, 196608, 0, 0x000c, 1256, PG_WIN1256,},

	{0, "bbf_unicode_cp1257_ci_ai", 1061, 0, 196608, 0, 0x000f, 1257, PG_WIN1257},
	{0, "bbf_unicode_cp1257_ci_as", 1061, 0, 196608, 0, 0x000d, 1257, PG_WIN1257},
	{0, "bbf_unicode_cp1257_cs_ai", 1061, 0, 196608, 0, 0x000e, 1257, PG_WIN1257},
	{0, "bbf_unicode_cp1257_cs_as", 1061, 0, 196608, 0, 0x000c, 1257, PG_WIN1257},

	{0, "bbf_unicode_cp1258_ci_ai", 1066, 0, 196608, 0, 0x000f, 1258, PG_WIN1258},
	{0, "bbf_unicode_cp1258_ci_as", 1066, 0, 196608, 0, 0x000d, 1258, PG_WIN1258},
	{0, "bbf_unicode_cp1258_cs_ai", 1066, 0, 196608, 0, 0x000e, 1258, PG_WIN1258},
	{0, "bbf_unicode_cp1258_cs_as", 1066, 0, 196608, 0, 0x000c, 1258, PG_WIN1258},

	{0, "bbf_unicode_cp1_ci_ai", 1033, 0, 196608, 54, 0x000f, 1252, PG_WIN1252},
	{0, "bbf_unicode_cp1_ci_as", 1033, 0, 196608, 52, 0x000d, 1252, PG_WIN1252},	/* default */
	{0, "bbf_unicode_cp1_cs_ai", 1033, 0, 196608, 51, 0x000e, 1252, PG_WIN1252},
	{0, "bbf_unicode_cp1_cs_as", 1033, 0, 196608, 51, 0x000c, 1252, PG_WIN1252},

	/* {0, "bbf_unicode_cp850_ci_ai",      1033, 0, 196608, 54, 0x000f, 850}, */
	/* {0, "bbf_unicode_cp850_ci_as",      1033, 0, 196608, 52, 0x000d, 850}, */
	/* {0, "bbf_unicode_cp850_cs_ai",      1033, 0, 196608, 51, 0x000e, 850}, */
	/* {0, "bbf_unicode_cp850_cs_as",      1033, 0, 196608, 51, 0x000c, 850}, */

	{0, "bbf_unicode_cp874_ci_ai", 1054, 0, 196608, 0, 0x000f, 874, PG_WIN874},
	{0, "bbf_unicode_cp874_ci_as", 1054, 0, 196608, 0, 0x000d, 874, PG_WIN874},
	{0, "bbf_unicode_cp874_cs_ai", 1054, 0, 196608, 0, 0x000e, 874, PG_WIN874},
	{0, "bbf_unicode_cp874_cs_as", 1054, 0, 196608, 0, 0x000c, 874, PG_WIN874},

	/*
	 * For the bbf_unicode_general collations, set lcid and codepage based on
	 * babelfishpg_tsql.default_locale
	 */
	{0, "bbf_unicode_general_ci_ai", 1033, 0, 196608, 0, 0x000f, 0},
	{0, "bbf_unicode_general_ci_as", 1033, 0, 196608, 0, 0x000d, 0},
	{0, "bbf_unicode_general_cs_ai", 1033, 0, 196608, 0, 0x000e, 0},
	{0, "bbf_unicode_general_cs_as", 1033, 0, 196608, 0, 0x000c, 0},

	/* pref collations */
	{0, "bbf_unicode_general_pref_cs_as", 1033, 0, 196608, 0, 0x000c, 0},
	{0, "bbf_unicode_pref_cp1250_cs_as", 1045, 0, 196608, 0, 0x000c, 1250, PG_WIN1250,},
	{0, "bbf_unicode_pref_cp1251_cs_as", 1049, 0, 196608, 0, 0x000c, 1251, PG_WIN1251},
	{0, "bbf_unicode_pref_cp1253_cs_as", 1032, 0, 196608, 0, 0x000c, 1253, PG_WIN1253},
	{0, "bbf_unicode_pref_cp1254_cs_as", 1055, 0, 196608, 0, 0x000c, 1254, PG_WIN1254},
	{0, "bbf_unicode_pref_cp1255_cs_as", 1037, 0, 196608, 0, 0x000c, 1255, PG_WIN1255},
	{0, "bbf_unicode_pref_cp1256_cs_as", 1025, 0, 196608, 0, 0x000c, 1256, PG_WIN1256,},
	{0, "bbf_unicode_pref_cp1257_cs_as", 1061, 0, 196608, 0, 0x000c, 1257, PG_WIN1257},
	{0, "bbf_unicode_pref_cp1258_cs_as", 1066, 0, 196608, 0, 0x000c, 1258, PG_WIN1258},
	{0, "bbf_unicode_pref_cp1_cs_as", 1033, 0, 196608, 51, 0x000c, 1252, PG_WIN1252,},
	/* {0, "bbf_unicode_pref_cp850_cs_as", 1033, 0, 196608, 51, 0x000c, 850}, */
	{0, "bbf_unicode_pref_cp874_cs_as", 1054, 0, 196608, 0, 0x000c, 874, PG_WIN874},

	{0, "chinese_prc_ci_ai", 2052, 0, 196608, 0, 0x000f, 936, PG_GBK},
	{0, "chinese_prc_ci_as", 2052, 0, 196608, 0, 0x000d, 936, PG_GBK},
	{0, "chinese_prc_cs_as", 2052, 0, 196608, 0, 0x000c, 936, PG_GBK},

	{0, "cyrillic_general_ci_ai", 1049, 0, 196608, 0, 0x000f, 1251, PG_WIN1251},
	{0, "cyrillic_general_ci_as", 1049, 0, 196608, 0, 0x000d, 1251, PG_WIN1251},
	{0, "cyrillic_general_cs_as", 1049, 0, 196608, 0, 0x000c, 1251, PG_WIN1251},

	{0, "estonian_ci_ai", 1061, 0, 196608, 0, 0x000f, 1257, PG_WIN1257},
	{0, "estonian_ci_as", 1061, 0, 196608, 0, 0x000d, 1257, PG_WIN1257},
	{0, "estonian_cs_as", 1061, 0, 196608, 0, 0x000c, 1257, PG_WIN1257},

	{0, "finnish_swedish_ci_ai", 1035, 0, 196608, 0, 0x000f, 1252, PG_WIN1252,},
	{0, "finnish_swedish_ci_as", 1035, 0, 196608, 0, 0x000d, 1252, PG_WIN1252,},
	{0, "finnish_swedish_cs_as", 1035, 0, 196608, 0, 0x000c, 1252, PG_WIN1252,},

	{0, "french_ci_ai", 1036, 0, 196608, 0, 0x000f, 1252, PG_WIN1252,},
	{0, "french_ci_as", 1036, 0, 196608, 0, 0x000d, 1252, PG_WIN1252,},
	{0, "french_cs_as", 1036, 0, 196608, 0, 0x000c, 1252, PG_WIN1252,},

	{0, "greek_ci_ai", 1032, 0, 196608, 0, 0x000f, 1253, PG_WIN1253},
	{0, "greek_ci_as", 1032, 0, 196608, 0, 0x000d, 1253, PG_WIN1253},
	{0, "greek_cs_as", 1032, 0, 196608, 0, 0x000c, 1253, PG_WIN1253},

	{0, "hebrew_ci_ai", 1037, 0, 196608, 0, 0x000f, 1255, PG_WIN1255},
	{0, "hebrew_ci_as", 1037, 0, 196608, 0, 0x000d, 1255, PG_WIN1255},
	{0, "hebrew_cs_as", 1037, 0, 196608, 0, 0x000c, 1255, PG_WIN1255},

	{0, "japanese_ci_ai", 1041, 0, 196608, 0, 0x000f, 932, PG_SJIS},
	{0, "japanese_ci_as", 1041, 0, 196608, 0, 0x000d, 932, PG_SJIS},
	{0, "japanese_cs_as", 1041, 0, 196608, 0, 0x000c, 932, PG_SJIS},

	{0, "korean_wansung_ci_ai", 1042, 0, 196608, 0, 0x000f, 949, PG_UHC},
	{0, "korean_wansung_ci_as", 1042, 0, 196608, 0, 0x000d, 949, PG_UHC},
	{0, "korean_wansung_cs_as", 1042, 0, 196608, 0, 0x000c, 949, PG_UHC},

	{0, "modern_spanish_ci_ai", 3082, 0, 196608, 0, 0x000f, 1252, PG_WIN1252,},
	{0, "modern_spanish_ci_as", 3082, 0, 196608, 0, 0x000d, 1252, PG_WIN1252,},
	{0, "modern_spanish_cs_as", 3082, 0, 196608, 0, 0x000c, 1252, PG_WIN1252,},

	{0, "mongolian_ci_ai", 1104, 0, 196608, 0, 0x000f, 1251, PG_WIN1251},
	{0, "mongolian_ci_as", 1104, 0, 196608, 0, 0x000d, 1251, PG_WIN1251},
	{0, "mongolian_cs_as", 1104, 0, 196608, 0, 0x000c, 1251, PG_WIN1251},

	{0, "polish_ci_ai", 1045, 0, 196608, 0, 0x000f, 1250, PG_WIN1250,},
	{0, "polish_ci_as", 1045, 0, 196608, 0, 0x000d, 1250, PG_WIN1250,},
	{0, "polish_cs_as", 1045, 0, 196608, 0, 0x000c, 1250, PG_WIN1250,},

	{0, "thai_ci_ai", 1054, 0, 196608, 0, 0x000f, 874, PG_WIN874},
	{0, "thai_ci_as", 1054, 0, 196608, 0, 0x000d, 874, PG_WIN874},
	{0, "thai_cs_as", 1054, 0, 196608, 0, 0x000c, 874, PG_WIN874},

	{0, "traditional_spanish_ci_ai", 1034, 0, 196608, 0, 0x000f, 1252, PG_WIN1252,},
	{0, "traditional_spanish_ci_as", 1034, 0, 196608, 0, 0x000d, 1252, PG_WIN1252,},
	{0, "traditional_spanish_cs_as", 1034, 0, 196608, 0, 0x000c, 1252, PG_WIN1252,},

	{0, "turkish_ci_ai", 1055, 0, 196608, 0, 0x000f, 1254, PG_WIN1254},
	{0, "turkish_ci_as", 1055, 0, 196608, 0, 0x000d, 1254, PG_WIN1254},
	{0, "turkish_cs_as", 1055, 0, 196608, 0, 0x000c, 1254, PG_WIN1254},

	{0, "ukrainian_ci_ai", 1058, 0, 196608, 0, 0x000f, 1251, PG_WIN1251},
	{0, "ukrainian_ci_as", 1058, 0, 196608, 0, 0x000d, 1251, PG_WIN1251},
	{0, "ukrainian_cs_as", 1058, 0, 196608, 0, 0x000c, 1251, PG_WIN1251},

	{0, "vietnamese_ci_ai", 1066, 0, 196608, 0, 0x000f, 1258, PG_WIN1258},
	{0, "vietnamese_ci_as", 1066, 0, 196608, 0, 0x000d, 1258, PG_WIN1258},
	{0, "vietnamese_cs_as", 1066, 0, 196608, 0, 0x000c, 1258, PG_WIN1258},
};

#define TOTAL_COLL_COUNT (sizeof(coll_infos)/sizeof(coll_infos[0]))

/*
 * ICU locales:
 *     https://www.localeplanet.com/icu/
 *
 * The default code page is 0 for Unicode-only locales.
 */
locale_info locales[] =
{
	{0x0436, 1252, PG_WIN1252, "af-ZA"}, //Afrikaans:South Africa
	{0x041c, 1250, PG_WIN1250, "sq-AL"}, //Albanian:Albania
	{0x1401, 1256, PG_WIN1256, "ar-DZ"}, //Arabic:Algeria
	{0x3c01, 1256, PG_WIN1256, "ar-BH"}, //Arabic:Bahrain
	{0x0c01, 1256, PG_WIN1256, "ar-EG"}, //Arabic:Egypt
	{0x0801, 1256, PG_WIN1256, "ar-IQ"}, //Arabic:Iraq
	{0x2c01, 1256, PG_WIN1256, "ar-JO"}, //Arabic:Jordan
	{0x3401, 1256, PG_WIN1256, "ar-KW"}, //Arabic:Kuwait
	{0x3001, 1256, PG_WIN1256, "ar-LB"}, //Arabic:Lebanon
	{0x1001, 1256, PG_WIN1256, "ar-LY"}, //Arabic:Libya
	{0x1801, 1256, PG_WIN1256, "ar-MA"}, //Arabic:Morocco
	{0x2001, 1256, PG_WIN1256, "ar-OM"}, //Arabic:Oman
	{0x4001, 1256, PG_WIN1256, "ar-QA"}, //Arabic:Qatar
	{0x0401, 1256, PG_WIN1256, "ar-SA"}, //Arabic:Saudi Arabia
	{0x2801, 1256, PG_WIN1256, "ar-SY"}, //Arabic:Syria
	{0x1c01, 1256, PG_WIN1256, "ar-TN"}, //Arabic:Tunisia
	{0x3801, 1256, PG_WIN1256, "ar-AE"}, //Arabic:U.A.E.
	{0x2401, 1256, PG_WIN1256, "ar-YE"}, //Arabic:Yemen
	/* {0x042b, 	0, 	"hy-AM"}, // Armenian: Armenia */
	{0x082c, 1251, PG_WIN1251, "az-Cyrl-AZ"}, //Azeri:Azerbaijan(Cyrillic)
	{0x042c, 1250, PG_WIN1250, "az-Latn-AZ"}, //Azeri:Azerbaijan(Latin)
	{0x042d, 1252, PG_WIN1252, "eu-ES"}, //Basque:Spain
	{0x0423, 1251, PG_WIN1251, "be-BY"}, //Belarusian:Belarus
	{0x0402, 1251, PG_WIN1251, "bg-BG"}, //Bulgarian:Bulgaria
	{0x0403, 1252, PG_WIN1252, "ca-ES"}, //Catalan:Spain
	{0x0c04, 950, PG_BIG5, "zh-HK"}, //Chinese:Hong Kong SAR, PRC(Traditional)
	{0x1404, 950, PG_BIG5, "zh-MO"}, //Chinese:Macao SAR(Traditional)
	{0x0804, 936, PG_GBK, "zh-CN"}, //Chinese:PRC(Simplified)
	{0x1004, 936, PG_GBK, "zh-SG"}, //Chinese:Singapore(Simplified)
	{0x0404, 950, PG_BIG5, "zh-TW"}, //Chinese:Taiwan(Traditional)
	/* {0x0827, 	1257, PG_WIN1257, 	Classic Lithuanian: Lithuania */
	{0x041a, 1250, PG_WIN1250, "hr-HR"}, //Croatian:Croatia
	{0x0405, 1250, PG_WIN1250, "cs-CZ"}, //Czech:Czech Republic
	{0x0406, 1252, PG_WIN1252, "da-DK"}, //Danish:Denmark
	{0x0813, 1252, PG_WIN1252, "nl-BE"}, //Dutch:Belgium
	{0x0413, 1252, PG_WIN1252, "nl-NL"}, //Dutch:Netherlands
	{0x0c09, 1252, PG_WIN1252, "en-AU"}, //English:Australia
	{0x2809, 1252, PG_WIN1252, "en-BZ"}, //English:Belize
	{0x1009, 1252, PG_WIN1252, "en-CA"}, //English:Canada
	/* {0x2409, 	1252, PG_WIN1252, 	English: Caribbean */
	{0x1809, 1252, PG_WIN1252, "en-IE"}, //English:Ireland
	{0x2009, 1252, PG_WIN1252, "en-JM"}, //English:Jamaica
	{0x1409, 1252, PG_WIN1252, "en-NZ"}, //English:New Zealand
	{0x3409, 1252, PG_WIN1252, "en-PH"}, //English:Philippines
	{0x1c09, 1252, PG_WIN1252, "en-ZA"}, //English:South Africa
	{0x2c09, 1252, PG_WIN1252, "en-TT"}, //English:Trinidad
	{0x0809, 1252, PG_WIN1252, "en-GB"}, //English:United Kingdom
	{0x0409, 1252, PG_WIN1252, "en-US"}, //English:United States
	{0x3009, 1252, PG_WIN1252, "en-ZW"}, //English:Zimbabwe
	{0x0425, 1257, PG_WIN1257, "et-EE"}, //Estonian:Estonia
	{0x0438, 1252, PG_WIN1252, "fo-FO"}, //Faeroese:Faeroe Islands
	{0x0429, 1256, PG_WIN1256, "fa-IR"}, //Farsi:Iran
	{0x040b, 1252, PG_WIN1252, "fi-FI"}, //Finnish:Finland
	{0x080c, 1252, PG_WIN1252, "fr-BE"}, //French:Belgium
	{0x0c0c, 1252, PG_WIN1252, "fr-CA"}, //French:Canada
	{0x040c, 1252, PG_WIN1252, "fr-FR"}, //French:France
	{0x140c, 1252, PG_WIN1252, "fr-LU"}, //French:Luxembourg
	{0x180c, 1252, PG_WIN1252, "fr-MC"}, //French:Monaco
	{0x100c, 1252, PG_WIN1252, "fr-CH"}, //French:Switzerland
	{0x042f, 1251, PG_WIN1251, "mk-MK"}, //Macedonian(FYROM)
	/* {0x0437, 	0, 	"ka-GE"}, // Georgian: Georgia */
	{0x0c07, 1252, PG_WIN1252, "de-AT"}, //German:Austria
	{0x0407, 1252, PG_WIN1252, "de-DE"}, //German:Germany
	{0x1407, 1252, PG_WIN1252, "de-LI"}, //German:Liechtenstein
	{0x1007, 1252, PG_WIN1252, "de-LU"}, //German:Luxembourg
	{0x0807, 1252, PG_WIN1252, "de-CH"}, //German:Switzerland
	{0x0408, 1253, PG_WIN1253, "el-GR"}, //Greek:Greece
	/* {0x0447, 	0, 	"gu-IN"}, // Gujarati: India */
	{0x040d, 1255, PG_WIN1255, "he-IL"}, //Hebrew:Israel
	/* {0x0439, 	0, 	"hi-IN"}, // Hindi: India */
	{0x040e, 1250, PG_WIN1250, "hu-HU"}, //Hungarian:Hungary
	{0x040f, 1252, PG_WIN1252, "is-IS"}, //Icelandic:Iceland
	{0x0421, 1252, PG_WIN1252, "id-ID"}, //Indonesian:Indonesia
	{0x0410, 1252, PG_WIN1252, "it-IT"}, //Italian:Italy
	{0x0810, 1252, PG_WIN1252, "it-CH"}, //Italian:Switzerland
	{0x0411, 932, PG_SJIS, "ja-JP"}, //Japanese:Japan
	/* {0x044b, 	0, 	"kn-IN"}, // Kannada: India */
	/* {0x0457, 	0, 	"kok-IN"}, // Konkani: India */
	{0x0412, 949, PG_UHC, "ko-KR"}, //Korean(Extended Wansung):Korea
	{0x0440, 1251, PG_WIN1251, "ky-KG"}, //Kyrgyz:Kyrgyzstan
	{0x0426, 1257, PG_WIN1257, "lv-LV"}, //Latvian:Latvia
	{0x0427, 1257, PG_WIN1257, "lt-LT"}, //Lithuanian:Lithuania
	{0x083e, 1252, PG_WIN1252, "ms-BN"}, //Malay:Brunei Darussalam
	{0x043e, 1252, PG_WIN1252, "ms-MY"}, //Malay:Malaysia
	/* {0x044e, 	0, 	"mr-IN"}, // Marathi: India */
	{0x0450, 1251, PG_WIN1251, "mn-MN"}, //Mongolian:Mongolia
	{0x0414, 1252, PG_WIN1252, "nb-NO"}, //Norwegian:Norway(bokmål)
	{0x0814, 1252, PG_WIN1252, "nn-NO"}, //Norwegian:Norway(Nynorsk)
	{0x0415, 1250, PG_WIN1250, "pl-PL"}, //Polish:Poland
	{0x0416, 1252, PG_WIN1252, "pt-BR"}, //Portuguese:Brazil
	{0x0816, 1252, PG_WIN1252, "pt-PT"}, //Portuguese:Portugal
	/* {0x0446, 	0, 	"pa-IN"}, // Punjabi: India */
	{0x0418, 1250, PG_WIN1250, "ro-RO"}, //Romanian:Romania
	{0x0419, 1251, PG_WIN1251, "ru-RU"}, //Russian:Russia
	/* {0x044f, 	0, 	"sa-IN"}, // Sanskrit: India */
	{0x0c1a, 1251, PG_WIN1251, "sr-Cyrl-RS"}, //Serbian:Serbia(Cyrillic)
	{0x081a, 1250, PG_WIN1250, "sr-Latn-RS"}, //Serbian:Serbia(Latin)
	{0x041b, 1250, PG_WIN1250, "sk-SK"}, //Slovak:Slovakia
	{0x0424, 1250, PG_WIN1250, "sl-SI"}, //Slovenian:Slovenia
	{0x2c0a, 1252, PG_WIN1252, "es-AR"}, //Spanish:Argentina
	{0x400a, 1252, PG_WIN1252, "es-BO"}, //Spanish:Bolivia
	{0x340a, 1252, PG_WIN1252, "es-CL"}, //Spanish:Chile
	{0x240a, 1252, PG_WIN1252, "es-CO"}, //Spanish:Colombia
	{0x140a, 1252, PG_WIN1252, "es-CR"}, //Spanish:Costa Rica
	{0x1c0a, 1252, PG_WIN1252, "es-DO"}, //Spanish:Dominican Republic
	{0x300a, 1252, PG_WIN1252, "es-EC"}, //Spanish:Ecuador
	{0x440a, 1252, PG_WIN1252, "es-SV"}, //Spanish:El Salvador
	{0x100a, 1252, PG_WIN1252, "es-GT"}, //Spanish:Guatemala
	{0x480a, 1252, PG_WIN1252, "es-HN"}, //Spanish:Honduras
	{0x080a, 1252, PG_WIN1252, "es-MX"}, //Spanish:Mexico
	{0x4c0a, 1252, PG_WIN1252, "es-NI"}, //Spanish:Nicaragua
	{0x180a, 1252, PG_WIN1252, "es-PA"}, //Spanish:Panama
	{0x3c0a, 1252, PG_WIN1252, "es-PY"}, //Spanish:Paraguay
	{0x280a, 1252, PG_WIN1252, "es-PE"}, //Spanish:Peru
	{0x500a, 1252, PG_WIN1252, "es-PR"}, //Spanish:Puerto Rico
	{0x0c0a, 1252, PG_WIN1252, "es-ES"}, //Spanish:Spain(Modern Sort)
	{0x040a, 1252, PG_WIN1252, "es-TRADITIONAL"}, //Spanish:Spain(International Sort)
	{0x380a, 1252, PG_WIN1252, "es-UY"}, //Spanish:Uruguay
	{0x200a, 1252, PG_WIN1252, "es-VE"}, //Spanish:Venezuela
	{0x0441, 1252, PG_WIN1252, "sw-KE"}, //Swahili:Kenya
	{0x081d, 1252, PG_WIN1252, "sv-FI"}, //Swedish:Finland
	{0x041d, 1252, PG_WIN1252, "sv-SE"}, //Swedish:Sweden
	{0x0444, 1251, PG_WIN1251, "tt-RU"}, //Tatar:Tatarstan
	/* {0x044a, 	0, 	"te-IN"}, // Telgu: India */
	{0x041e, 874, PG_WIN874, "th-TH"}, //Thai:Thailand
	{0x041f, 1254, PG_WIN1254, "tr-TR"}, //Turkish:Turkey
	{0x0422, 1251, PG_WIN1251, "uk-UA"}, //Ukrainian:Ukraine
	{0x0820, 1256, PG_WIN1256, "ur-IN"}, //Urdu:India
	{0x0420, 1256, PG_WIN1256, "ur-PK"}, //Urdu:Pakistan
	{0x0843, 1251, PG_WIN1251, "uz-Cyrl-UZ"}, //Uzbek:Uzbekistan(Cyrillic)
	{0x0443, 1250, PG_WIN1250, "uz-Latn-UZ"}, //Uzbek:Uzbekistan(Latin)
	{0x042a, 1258, PG_WIN1258, "vi-VN"}, //Vietnamese:Vietnam
};

#define TOTAL_LOCALES (sizeof(locales)/sizeof(locales[0]))

static void
init_default_locale(void)
{
	if (!bbf_default_locale)
	{
		const char *val = GetConfigOption("babelfishpg_tsql.default_locale", true, false);

		if (val)
		{
			MemoryContext oldContext = MemoryContextSwitchTo(TopMemoryContext);

			bbf_default_locale = pstrdup(val);
			MemoryContextSwitchTo(oldContext);
		}
	}

	/*
	 * babelfishpg_tsql.default_locale should not be changed once babelfish db
	 * is initialised.
	 */
	Assert(!bbf_default_locale || strcmp(bbf_default_locale, GetConfigOption("babelfishpg_tsql.default_locale", true, false)) == 0);

	return;
}

static void
init_server_collation_name(void)
{
	if (!server_collation_name)
	{
		const char *val = GetConfigOption("babelfishpg_tsql.server_collation_name", true, false);

		if (val)
		{
			MemoryContext oldContext = MemoryContextSwitchTo(TopMemoryContext);

			server_collation_name = pstrdup(val);
			MemoryContextSwitchTo(oldContext);
		}
	}
	return;
}

int
find_collation(const char *collation_name)
{
	int			first = 0;
	int			last = TOTAL_COLL_COUNT - 1;
	int			middle = 37;	/* optimization: usually it's the default
								 * collation (first + last) / 2; */
	int			compare;

	if (!collation_name)
		return NOT_FOUND;

	while (first <= last)
	{
		compare = pg_strcasecmp(coll_infos[middle].collname, collation_name);

		if (compare < 0)
			first = middle + 1;
		else if (compare == 0)
			return middle;
		else
			last = middle - 1;

		middle = (first + last) / 2;
	}

	return NOT_FOUND;
}

static bool
collation_is_case_insensitive_and_accent_sensitive(int collidx)
{
	if (collidx < 0 || collidx >= TOTAL_COLL_COUNT)
		return false;

	if (coll_infos[collidx].collateflags == 0x000d) /* CI_AS  */
		return true;

	return false;
}

/*
 * Return true if database collation is case insensitive
 * If database collation is invalid, determine whether
 * server level collation is case insensitive or not
 */
bool
is_database_or_server_collation_CI(void)
{
	get_database_or_server_collation_oid_internal(false);
	return db_collation_is_CI;
}

/* Given a coll_infos index, return the CS_AS or BIN2 collation with
 * the same lcid. A cs_as collation exists for every distinct lcid.
 */
int
find_cs_as_collation(int collidx)
{
	int			cur_collidx = collidx;

	if (NOT_FOUND == collidx)
		return collidx;

	while (cur_collidx < TOTAL_COLL_COUNT &&
		   coll_infos[cur_collidx].lcid == coll_infos[collidx].lcid)
	{
		if (coll_infos[cur_collidx].collateflags == 0x000c /* CS_AS  */ ||
			coll_infos[cur_collidx].collateflags == 0x0220 /* BIN2 */ )
			return cur_collidx;

		cur_collidx++;
	}

	return NOT_FOUND;
}

int
find_any_collation(const char *collation_name, bool check_for_server_collation_name_guc)
{
	int			collidx = translate_collation(collation_name, check_for_server_collation_name_guc);

	if (NOT_FOUND == collidx)
		collidx = find_collation(collation_name);

	return collidx;
}

/*
 * translate_collation_utility - utility to find index of babelfish collation corresponding to supplied collation_name
 * by looking into coll_translations array or returns NOT_FOUND.
 */
static int
translate_collation_utility(const char *collname)
{
	return find_collation(translate_tsql_collation_to_bbf_collation(collname));
}

/* 
 * Translate TSQL collation to it's closest BBF Collation. 
 */
const char *
translate_tsql_collation_to_bbf_collation(const char *collname)
{
	int			first = 0;
	int			last = TOTAL_COLL_TRANSLATION_COUNT - 1;
	int			middle = 25;	/* optimization: usually it's the default
								 * collation (first + last) / 2; */
	int			compare;

	while (first <= last)
	{
		compare = pg_strcasecmp(coll_translations[middle].from_collname, collname);
		if (compare < 0)
			first = middle + 1;
		else if (compare == 0)
		{
			return (coll_translations[middle].to_collname);
		}
		else
			last = middle - 1;

		middle = (first + last) / 2;
	}
	return collname;
}

/*
 * translate_collation - Returns index of babelfish collation corresponding to supplied collation_name
 * by looking into coll_translations array or returns NOT_FOUND.
 * Here, we handle DATABASE_DEFAULT and CATALOG_DEFAULT somewhat differently. If we encounter such collation
 * then we have to return index of server_collation_name setting either by translating server_collation_name to
 * actual collation or by looking into coll_infos table through find_collation().
 */
int
translate_collation(const char *collname, bool check_for_server_collation_name_guc)
{
	int			idx = NOT_FOUND;

	/*
	 * Special case handling for database_default and catalog_default
	 * collations which should be translated to server_collation_name.
	 */
	if (!check_for_server_collation_name_guc && (pg_strcasecmp(collname, DATABASE_DEFAULT) == 0 || pg_strcasecmp(collname, CATALOG_DEFAULT) == 0))
	{
		if (database_collation_collidx != NOT_FOUND)
		{
			return database_collation_collidx;
		}

		init_server_collation_name();
		if (server_collation_name)
		{
			idx = translate_collation_utility(server_collation_name);
			if (idx == NOT_FOUND)
				idx = find_collation(server_collation_name);
		}
		else
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("invalid setting detected for babelfishpg_tsql.server_collation_name")));
	}
	else
	{
		idx = translate_collation_utility(collname);
	}
	return idx;
}

/* Translate BBF collation to it's closest TSQL Collation. */
const char *
translate_bbf_collation_to_tsql_collation(const char *collname)
{
	for (int i = 0; i < TOTAL_REVERSE_COLL_TRANSLATION_COUNT; i++)
		if (pg_strcasecmp(reverse_coll_translations[i].from_collname, collname) == 0)
			return (reverse_coll_translations[i].to_collname);

	return NULL;
}

/*
 * find_locale - search for the locale in the locales array and returns its index
 * or returns NOT_FOUND.
 */
int
find_locale(const char *given_locale)
{
	int			i;
	char	   *normalized_locale = NULL;

	/*
	 * Normalize given_locale before searching the locales array
	 */
	if (NULL == given_locale ||
		0 == strlen(given_locale) ||
		strlen(given_locale) > MAX_ICU_LOCALE_LEN)
	{
		return NOT_FOUND;
	}
	else
	{
		char	   *underscore_pos;

		normalized_locale = palloc0(strlen(given_locale) + 1);
		memcpy(normalized_locale, given_locale, strlen(given_locale));
		underscore_pos = strstr(normalized_locale, "_");

		while (NULL != underscore_pos)
		{
			*underscore_pos = '-';
			underscore_pos = strstr(normalized_locale, "_");
		}

	}

	for (i = 0; i < TOTAL_LOCALES; ++i)
	{
		if (0 == pg_strcasecmp(normalized_locale, locales[i].icu_locale))
		{
			pfree(normalized_locale);
			return (i);
		}
	}

	pfree(normalized_locale);
	return NOT_FOUND;
}

/*
 * init_collid_trans_tab_internal - This would be called from init_collid_trans_tab (babelfishpg_tsql) to
 * load information from coll_infos array into hash table.
 */
int
init_collid_trans_tab_internal(void)
{
	HASHCTL		hashCtl;
	Oid			nspoid;
	ht_oid2collid_entry *entry;
	int			locale_pos = -1;
	char	   *atsign = NULL;
	char	   *locale;

	if (TransMemoryContext == NULL) /* initialize memory context */
	{
		TransMemoryContext = AllocSetContextCreateInternal(NULL,
														   "SQL Variant Memory Context",
														   ALLOCSET_DEFAULT_SIZES);
	}

	if (ht_oid2collid == NULL)	/* create hash table */
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(Oid);
		hashCtl.entrysize = sizeof(ht_oid2collid_entry);
		hashCtl.hcxt = TransMemoryContext;
		ht_oid2collid = hash_create("OID to Persist Collation ID Mapping",
									TOTAL_COLL_COUNT,
									&hashCtl,
									HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	nspoid = get_namespace_oid("sys", false);

	/* retrieve oid and setup hashtable */
	for (int i = 0; i < TOTAL_COLL_COUNT; i++)
	{
		/*
		 * Encoding can be either COLL_DEFAULT_ENCODING - in case of libc
		 * based collations or it can be -1 in case of icu based collations.
		 */
		coll_infos[i].oid = GetSysCacheOid3(COLLNAMEENCNSP,
											Anum_pg_collation_oid,
											PointerGetDatum(coll_infos[i].collname),
											Int32GetDatum(-1),
											ObjectIdGetDatum(nspoid));

		if (!OidIsValid(coll_infos[i].oid))
			coll_infos[i].oid = GetSysCacheOid3(COLLNAMEENCNSP,
												Anum_pg_collation_oid,
												PointerGetDatum(coll_infos[i].collname),
												Int32GetDatum(COLL_DEFAULT_ENCODING),
												ObjectIdGetDatum(nspoid));

		/*
		 * For the bbf_unicode_general_* collations, fill in the lcid and/or
		 * the code_page from the default_locale GUC
		 */
		if (0 == strncmp(coll_infos[i].collname, "bbf_unicode_general", strlen("bbf_unicode_general")))
		{
			init_default_locale();

			locale = pstrdup(bbf_default_locale);
			if (locale)
				atsign = strstr(locale, "@");
			if (atsign != NULL)
				*atsign = '\0';
			locale_pos = find_locale(locale);

			if (locale_pos < 0)
			{
				ereport(ERROR,
						(errcode(ERRCODE_INTERNAL_ERROR),
						 errmsg("invalid setting detected for babelfishpg_tsql.default_locale setting")));
			}
			coll_infos[i].lcid = locales[locale_pos].lcid;
			coll_infos[i].code_page = locales[locale_pos].code_page;
			coll_infos[i].enc = locales[locale_pos].enc;
			
			if (locale)
				pfree(locale);
		}
		if (OidIsValid(coll_infos[i].oid))
		{
			entry = hash_search(ht_oid2collid, &coll_infos[i].oid, HASH_ENTER, NULL);
			entry->persist_id = i;
		}
	}
	return 0;
}

/*
 * init_like_ilike_table_internal - This would be called by init_like_ilike_table (babelfishpg_tsql extension)
 * to load information from like_ilike_table into hash table.
 */
int
init_like_ilike_table_internal(void)
{
	HASHCTL		hashCtl;
	ht_like2ilike_entry_t *entry;

	if (TransMemoryContext == NULL) /* initialize memory context */
	{
		TransMemoryContext =
			AllocSetContextCreateInternal(NULL,
										  "SQL Variant Memory Context",
										  ALLOCSET_DEFAULT_SIZES);
	}

	if (ht_like2ilike == NULL)	/* create hash table */
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(Oid);
		hashCtl.entrysize = sizeof(ht_like2ilike_entry_t);
		hashCtl.hcxt = TransMemoryContext;
		ht_like2ilike = hash_create("OID to Persist like to ilike Mapping",
									TOTAL_LIKE_OP_COUNT,
									&hashCtl,
									HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	/* retrieve oid and setup hashtable */
	for (int i = 0; i < TOTAL_LIKE_OP_COUNT; i++)
	{
		char	   *like_opname = like_ilike_table[i].like_op_name;
		char	   *ilike_opname = like_ilike_table[i].ilike_op_name;
		const TypeName *typename;
		Type		tup;
		Oid			loid,
					roid;

		typename = makeTypeNameFromNameList(list_make2(makeString(like_ilike_table[i].op_left_schema), makeString(like_ilike_table[i].op_left_name)));
		tup = LookupTypeName(NULL, typename, NULL, true);
		if (!tup)
			continue;			/* this can happen when _PG_Init is called to
								 * verify C function before creating datatype */
		loid = ((Form_pg_type) GETSTRUCT(tup))->oid;
		ReleaseSysCache(tup);

		if (!OidIsValid(loid))
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("type %s.%s is invalid!",
							like_ilike_table[i].op_left_schema, like_ilike_table[i].op_left_name)));


		typename = makeTypeNameFromNameList(list_make2(makeString(like_ilike_table[i].op_right_schema), makeString(like_ilike_table[i].op_right_name)));
		tup = LookupTypeName(NULL, typename, NULL, true);
		if (!tup)
			continue;			/* this can happen when _PG_Init is called to
								 * verify C function before creating datatype */
		roid = ((Form_pg_type) GETSTRUCT(tup))->oid;
		ReleaseSysCache(tup);

		if (!OidIsValid(roid))
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("type %s.%s is invalid!",
							like_ilike_table[i].op_right_schema, like_ilike_table[i].op_right_name)));

		like_ilike_table[i].like_oid = OpernameGetOprid(list_make1(makeString(like_opname)),
														loid,
														roid);
		if (OidIsValid(like_ilike_table[i].like_oid))
		{
			entry = hash_search(ht_like2ilike, &like_ilike_table[i].like_oid, HASH_ENTER, NULL);
			entry->persist_id = i;
		}
		like_ilike_table[i].ilike_oid = OpernameGetOprid(list_make1(makeString(ilike_opname)),
														 loid,
														 roid);
		like_ilike_table[i].ilike_opfuncid = get_opcode(like_ilike_table[i].ilike_oid);
	}
	return 0;
}

/*
 * Helper for query the hash table using operator oid
 */
like_ilike_info
lookup_like_ilike_table(Oid opno)
{
	ht_like2ilike_entry_t *hinfo;
	bool		found;

	if (ht_like2ilike == NULL)
		init_like_ilike_table_internal();

	hinfo = (ht_like2ilike_entry_t *) hash_search(ht_like2ilike,
												  &opno,
												  HASH_FIND,
												  &found);
	/* return invalid oid when not found */
	if (!found)
	{
		like_ilike_info invalid = {
			InvalidOid,		/* like_oid */
			NULL,			/* like_op_name */
			NULL,			/* ilike_op_name */
			NULL,			/* op_left_schema */
			NULL,			/* the name of left operand */
			NULL,			/* op_left_name */
			NULL,			/* op_right_name */
			false,			/* is_not_match */
			InvalidOid,		/* ilike_oid */
			InvalidOid		/* ilike_opfuncid */
		};

		return invalid;
	}

	return like_ilike_table[hinfo->persist_id];
}

/*
 * lookup_collation_table - Query the hash table so that tds can send the right values for the
 * tsql collation on the wire.
 */
coll_info
lookup_collation_table(Oid coll_oid)
{
	ht_oid2collid_entry *hinfo;
	bool		found;

	if (ht_oid2collid == NULL)
		init_collid_trans_tab_internal();

	if (!OidIsValid(coll_oid))
	{
		int			collidx = get_database_or_server_collation_collidx();

		if (NOT_FOUND != collidx)
			return coll_infos[collidx];
	}

	hinfo = (ht_oid2collid_entry *) hash_search(ht_oid2collid,
												&coll_oid,
												HASH_FIND,
												&found);

	/*
	 * TODO: Change it to Error, and reload the cache again. If not found,
	 * raise the error. For now, silently return NULL, so that we can use the
	 * default values
	 */
	if (!found)
	{
		int			collidx;

		coll_info	invalid = {
			InvalidOid,		/* oid */
			NULL,			/* collname */
			-1,			/* lcid */
			-1,			/* ver */
			-1,			/* style */
			-1,			/* sortid */
			-1,			/* collateflags */
			-1,			/* code_page */
			PG_SQL_ASCII		/* enc */
		};

		collidx = get_database_or_server_collation_collidx();
		if (collidx == NOT_FOUND)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Encoding corresponding to default server collation could not be found.")));
		else
			invalid.enc = coll_infos[collidx].enc;
		elog(DEBUG2, "collation oid %d not found, using default collation", coll_oid);
		return invalid;
	}

	return coll_infos[hinfo->persist_id];
}

/*
 * get_database_or_server_collation_collidx -
 * Get the Index of default collation from coll_infos array, or return NOT_FOUND if not found
 * Firstly, we check whether database_collation_collidx (corresponds to database level collidx) 
 * is FOUND or not - which should have been set during USE command
 * If NOT_FOUND, then we fallback to server level collidx
 * It is caller's responsibility to check whether server level collidx is NOT_FOUND or not
 */
int
get_database_or_server_collation_collidx(void)
{
	if (database_collation_collidx != NOT_FOUND)
		return database_collation_collidx;
	init_server_collation_name();
	if (NOT_FOUND == server_collation_collidx)
	{
		server_collation_collidx = find_any_collation(server_collation_name, false);
	}
	
	return server_collation_collidx;
}

/*
 * cmp_collation - return -1 if coll1 < coll2, 0 if coll1 = coll2, 1 if coll1 > coll2
 */
int8_t
cmp_collation(uint16_t coll1, uint16_t coll2)
{
	coll_info  *coll_info1 = &coll_infos[coll1];
	coll_info  *coll_info2 = &coll_infos[coll2];

	if (coll_info1->lcid < coll_info2->lcid)
		return -1;
	else if (coll_info1->lcid > coll_info2->lcid)
		return 1;
	else if (coll_info1->ver < coll_info2->ver)
		return -1;
	else if (coll_info1->ver > coll_info2->ver)
		return 1;
	else if (coll_info1->style < coll_info2->style)
		return -1;
	else if (coll_info1->style > coll_info2->style)
		return 1;
	else if (coll_info1->sortid < coll_info2->sortid)
		return -1;
	else if (coll_info1->sortid > coll_info2->sortid)
		return 1;
	else
		return 0;
}


/*
 * collation_list_internal - would be called by collation_list to list the supported collations.
 */
Datum
collation_list_internal(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not " \
						"allowed in this context")));

	/* need to build tuplestore in query context */
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	/*
	 * build tupdesc for result tuples.
	 */
	tupdesc = CreateTemplateTupleDesc(7);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "oid",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "collation_name",
					   TEXTOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "l1_priority",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "l2_priority",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "l3_priority",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "l4_priority",
					   INT4OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "l5_priority",
					   INT4OID, -1, 0);

	tupstore =
		tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
							  false, 1024);
	/* generate junk in short-term context */
	MemoryContextSwitchTo(oldcontext);

	/* scan all the variables in top estate */
	for (int i = 0; i < TOTAL_COLL_COUNT; i++)
	{
		coll_info  *info = &coll_infos[i];
		Datum		values[7];
		bool		nulls[7];

		MemSet(nulls, 0, sizeof(nulls));

		values[0] = info->oid;
		values[1] = CStringGetTextDatum(info->collname);
		values[2] = info->lcid;
		values[3] = info->ver;
		values[4] = info->style;
		values[5] = info->sortid;
		values[6] = info->collateflags;

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	PG_RETURN_NULL();
}

static Oid
get_collation_oid_internal(char *collation_name)
{
	Oid			nspoid;
	Oid			collation_oid;
	int			collidx;
	const char *collname;

	if (!collation_name)
		return DEFAULT_COLLATION_OID;

	/*
	 * The collation_name is permitted to be the name of a sql or windows
	 * collation that is translated into a bbf collation. If that's what it is
	 * then get the translated name.
	 */
	if (NOT_FOUND != (collidx = translate_collation(collation_name, false)))
		collname = coll_infos[collidx].collname;
	else
		collname = collation_name;

	nspoid = get_namespace_oid("sys", false);
	collation_oid = GetSysCacheOid3(COLLNAMEENCNSP, Anum_pg_collation_oid,
									PointerGetDatum(collname),
									Int32GetDatum(-1),
									ObjectIdGetDatum(nspoid));

	if (!OidIsValid(collation_oid))
		collation_oid = GetSysCacheOid3(COLLNAMEENCNSP, Anum_pg_collation_oid,
										PointerGetDatum(collname),
										Int32GetDatum(COLL_DEFAULT_ENCODING),
										ObjectIdGetDatum(nspoid));

	return collation_oid;
}

/*
 * Return database collation Oid if valid
 * Else return server collation Oid
 * We follow this mechanism to fall back to server level collation
 * if database level collation is invalid or not found
 */
Oid
get_database_or_server_collation_oid_internal(bool missingOk)
{
	if (OidIsValid(database_collation_oid))
		return database_collation_oid;
		
	if (OidIsValid(server_collation_oid))
		return server_collation_oid;

	init_server_collation_name();

	if (server_collation_name == NULL)
		return DEFAULT_COLLATION_OID;

	server_collation_oid = get_collation_oid_internal(server_collation_name);

	if (!OidIsValid(server_collation_oid))
	{
		if (!missingOk)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Server default collation sys.\"%s\" is not defined, using the cluster default collation",
							server_collation_name)));
		else
		{
			db_collation_is_CI = false;
			server_collation_collidx = NOT_FOUND;
			return DEFAULT_COLLATION_OID;
		}
	}
	else
	{
		db_collation_is_CI = collation_is_CI(server_collation_oid);
		server_collation_collidx = get_database_or_server_collation_collidx();
	}

	return server_collation_oid;
}

Oid
BABELFISH_CLUSTER_COLLATION_OID()
{
	if (sql_dialect == SQL_DIALECT_TSQL)
	{
		Oid db_coll = get_database_or_server_collation_oid_internal(false);	/* set and cache
													 * database or server_collation_oid */
		return db_coll;
	}
	return DEFAULT_COLLATION_OID;
}

/*
 * collation_is_CI - Returns true if collation with given colloid is CI.
 */
bool
collation_is_CI(Oid colloid)
{
	HeapTuple	tp;
	char	   *collcollate = NULL;
	char		collprovider;
	bool		collisdeterministic;
	Datum		datum;
	bool		isnull;

	if (InvalidOid == colloid)
		return false;

	if (GetDatabaseEncoding() != PG_UTF8)
		return false;

	tp = SearchSysCache1(COLLOID, ObjectIdGetDatum(colloid));
	if (!HeapTupleIsValid(tp))
		elog(ERROR, "cache lookup failed for collation %u", colloid);

	collprovider = ((Form_pg_collation) GETSTRUCT(tp))->collprovider;
	collisdeterministic = ((Form_pg_collation) GETSTRUCT(tp))->collisdeterministic;

	if (collisdeterministic == true || collprovider != COLLPROVIDER_ICU)
	{
		ReleaseSysCache(tp);
		return false;
	}
	datum = SysCacheGetAttr(COLLOID, tp, Anum_pg_collation_colllocale, &isnull);
	if (!isnull)
		collcollate = pstrdup(TextDatumGetCString(datum));
	ReleaseSysCache(tp);

	if (isnull)
		return false;

	/*
	 * colStrength secondary, or level2, corresponds to a CI_AS collation,
	 * colStrength primary, or level1, corresponds to a CI_AI collation,
	 * unless colCaseLevel=yes, or kc-true, is also specified.
	 */
	if ((strstr(lowerstr(collcollate), lowerstr("colStrength=secondary")) != NULL || strstr(lowerstr(collcollate), lowerstr("colStrength=primary")) != NULL) &&
		strstr(lowerstr(collcollate), lowerstr("colCaseLevel=yes")) == NULL)    /* without a colCaseLevel - not CS_AI */
			return true;
	 
	/* Starting from PG16, locale string is canonicalized to a language tag. */
	if ((strstr(lowerstr(collcollate), "level2") != NULL || strstr(lowerstr(collcollate), "level1") != NULL)  &&    /* CI_AS OR CI_AI */
		strstr(lowerstr(collcollate), "kc-true") == NULL)
		return true;

	return false;
}

bool
has_ilike_node(Node *expr)
{
	OpExpr	   *op;

	Assert(IsA(expr, OpExpr));

	op = (OpExpr *) expr;
	for (int i = 0; i < TOTAL_LIKE_OP_COUNT; i++)
	{
		if (strcmp(get_opname(op->opno), like_ilike_table[i].ilike_op_name) == 0)
		{
			return true;
		}
	}
	return false;
}

Datum
is_collated_ci_as_internal(PG_FUNCTION_ARGS)
{
	Oid			colloid = PG_GET_COLLATION();

	if (!OidIsValid(colloid))
		PG_RETURN_BOOL(false);

	if (collation_is_CI(colloid))
		PG_RETURN_BOOL(true);

	PG_RETURN_BOOL(false);
}

Datum
is_collated_ai_internal(PG_FUNCTION_ARGS)
{
	Oid  		colloid = PG_GET_COLLATION();
	HeapTuple	tp;
	char		*collcollate = NULL;
	char		collprovider;
	bool		collisdeterministic;
	Datum		datum;
	bool		isnull;

	if (!OidIsValid(colloid) || GetDatabaseEncoding() != PG_UTF8)
		PG_RETURN_BOOL(false);

	tp = SearchSysCache1(COLLOID, ObjectIdGetDatum(colloid));
	if (!HeapTupleIsValid(tp))
		elog(ERROR, "cache lookup failed for collation %u", colloid);

	collprovider = ((Form_pg_collation) GETSTRUCT(tp))->collprovider;
	collisdeterministic = ((Form_pg_collation) GETSTRUCT(tp))->collisdeterministic;

	if (collisdeterministic == true || collprovider != COLLPROVIDER_ICU)
	{
		ReleaseSysCache(tp);
		PG_RETURN_BOOL(false);
	}
	datum = SysCacheGetAttr(COLLOID, tp, Anum_pg_collation_colllocale, &isnull);

	if (isnull)
	{
		ReleaseSysCache(tp);
		PG_RETURN_BOOL(false);
	}

	collcollate = TextDatumGetCString(datum);
	ReleaseSysCache(tp);

	if (strstr(lowerstr(collcollate), lowerstr("colStrength=primary")) ||
		0 != strstr(lowerstr(collcollate), "level1"))    /* AI */
	{
		pfree(collcollate);
		PG_RETURN_BOOL(true);
	}

	pfree(collcollate);

	PG_RETURN_BOOL(false);
}

const char *
BabelfishTranslateCollation(const char *collname, Oid collnamespace, int32 encoding)
{
	if (prev_TranslateCollation_hook)
	{
		const char *newCollname = (*prev_TranslateCollation_hook) (collname, collnamespace, encoding);

		if (newCollname)
			return newCollname;
	}

	if (pltsql_case_insensitive_identifiers && strcmp(collname, "c") == 0)
	{
		return "C";				/* Special case for "C" collation */
	}
	else
	{
		int			collidx = translate_collation(collname, false);

		if (collidx >= 0)
		{
			return coll_infos[collidx].collname;
		}
	}

	return NULL;
}

bool
is_valid_server_collation_name(const char *collname)
{
	int			collidx = find_any_collation(collname, true);

	if (NOT_FOUND != collidx &&
		collation_is_case_insensitive_and_accent_sensitive(collidx))
		return true;

	return false;
}

Oid
get_tsql_collation_oid(int persist_coll_id)
{
	return coll_infos[persist_coll_id].oid;
}

int
get_persist_collation_id(Oid coll_oid)
{
	ht_oid2collid_entry *entry;
	bool		found_coll;
	int			collidx;

	if (ht_oid2collid == NULL)
		init_collid_trans_tab_internal();

	entry = hash_search(ht_oid2collid, &coll_oid, HASH_FIND, &found_coll);

	if (found_coll)
	{
		return entry->persist_id;
	}

	collidx = get_database_or_server_collation_collidx();
	Assert(collidx >= 0);
	return collidx;
}

bytea *
tdscollationproperty_helper(const char *collationname, const char *property)
{
	int			collidx = find_any_collation(collationname, false);

	if (collidx >= 0)
	{
		coll_info	coll = coll_infos[collidx];

		if (strcasecmp(property, "tdscollation") == 0)
		{
			/*
			 * ret here is of 8 bytes tdscollation should return 5 bytes Below
			 * code converts ret into 5 bytes
			 */
			int64_t		ret = ((int64_t) ((int64_t) coll.lcid | ((int64_t) coll.collateflags << 20) | ((int64_t) coll.sortid << 32)));
			int			maxlen = 5;
			char	   *rp;
			bytea	   *result;
			svhdr_3B_t *svhdr;
			bytea	   *bytea_data = (bytea *) palloc(maxlen + VARHDRSZ);


			SET_VARSIZE(bytea_data, maxlen + VARHDRSZ);
			rp = VARDATA(bytea_data);

			memcpy(rp, (char *) &ret, maxlen);

			result = gen_sqlvariant_bytea_from_type_datum(BINARY_T, PointerGetDatum(bytea_data));

			/* Type Specific Header */
			svhdr = SV_HDR_3B(result);
			SV_SET_METADATA(svhdr, BINARY_T, HDR_VER);
			svhdr->typmod = VARSIZE_ANY_EXHDR(bytea_data);

			return result;
		}
	}

	return NULL;				/* Invalid collation. */
}

int
collationproperty_helper(const char *collationname, const char *property)
{
	int			collidx = find_any_collation(collationname, false);

	if (collidx >= 0)
	{
		coll_info	coll = coll_infos[collidx];

		if (strcasecmp(property, "CodePage") == 0)
			return coll.code_page;
		else if (strcasecmp(property, "LCID") == 0)
			return coll.lcid;
		else if (strcasecmp(property, "ComparisonStyle") == 0)
			return coll.style;
		else if (strcasecmp(property, "Version") == 0)
			return coll.ver;

		/*
		 * Below properties are added for internal usage with
		 * sp_describe_first_result_set to return correct tds_collation_id and
		 * tds_collation_sort_id fields.
		 */
		else if (strcasecmp(property, "CollationId") == 0)
			return ((coll.collateflags << 20) | coll.lcid);
		else if (strcasecmp(property, "SortId") == 0)
			return coll.sortid;
		else
			return -1;			/* Invalid property. */
	}
	else
		return -1;				/* Invalid collation. */
}

void
BabelfishPreCreateCollation_hook(
								 char collprovider,
								 bool collisdeterministic,
								 int32 collencoding,
								 const char **pCollcollate,
								 const char **pCollctype,
								 const char *collversion
)
{
	const char *collcollate = *pCollcollate;
	const char *collctype = *pCollctype;

	/* This hook should only be called when dialect is tsql. */
	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	if (NULL != prev_PreCreateCollation_hook)
	{
		(*prev_PreCreateCollation_hook) (collprovider,
										 collisdeterministic,
										 collencoding,
										 &collcollate,
										 &collctype,
										 collversion);
		*pCollcollate = collcollate;
		*pCollctype = collctype;
	}

	init_default_locale();

	if (bbf_default_locale && strlen(bbf_default_locale) > 0)
	{
		/*
		 * If the first character of the locale is '@' and if a
		 * babelfishpg_tsql_default_locale override has been specified, then
		 * prepend the babelfishpg_tsql_default_locale to the specified
		 * locale. Note that since the target is a const char *, we cannot
		 * modify the initial string, but we can modify the pointer to point
		 * somewhere else.
		 */
		if (collcollate[0] == '@')
		{
			size_t		totallen = strlen(bbf_default_locale) + strlen(collcollate) + 1;
			char	   *catcollcollate = palloc0(totallen);

			memcpy(catcollcollate, bbf_default_locale, strlen(bbf_default_locale));
			strncat(catcollcollate, collcollate, totallen);
			*pCollcollate = catcollcollate;
		}

		if (collctype[0] == '@')
		{
			size_t		totallen = strlen(bbf_default_locale) + strlen(collctype) + 1;
			char	   *catcollctype = palloc0(totallen);

			memcpy(catcollctype, bbf_default_locale, strlen(bbf_default_locale));
			strncat(catcollctype, collcollate, totallen);
			*pCollctype = catcollctype;
		}
	}
}

Oid
get_oid_from_collidx(int collidx)
{
	if (collidx == NOT_FOUND)
		return InvalidOid;
	return coll_infos[collidx].oid;
}

collation_callbacks *
get_collation_callbacks(void)
{
	if (!collation_callbacks_var.get_database_or_server_collation_oid_internal)
	{
		collation_callbacks_var.get_database_or_server_collation_oid_internal = &get_database_or_server_collation_oid_internal;
		collation_callbacks_var.collation_list_internal = &collation_list_internal;
		collation_callbacks_var.is_collated_ci_as_internal = &is_collated_ci_as_internal;
		collation_callbacks_var.is_collated_ai_internal = &is_collated_ai_internal;
		collation_callbacks_var.collationproperty_helper = &collationproperty_helper;
		collation_callbacks_var.tdscollationproperty_helper = &tdscollationproperty_helper;
		collation_callbacks_var.lookup_collation_table_callback = &lookup_collation_table;
		collation_callbacks_var.lookup_like_ilike_table = &lookup_like_ilike_table;
		collation_callbacks_var.is_database_or_server_collation_CI = &is_database_or_server_collation_CI;
		collation_callbacks_var.is_valid_server_collation_name = &is_valid_server_collation_name;
		collation_callbacks_var.find_locale = &find_locale;
		collation_callbacks_var.EncodingConversion = &encoding_conv_util;
		collation_callbacks_var.get_oid_from_collidx_internal = &get_oid_from_collidx;
		collation_callbacks_var.find_cs_as_collation_internal = &find_cs_as_collation;
		collation_callbacks_var.find_collation_internal = &find_collation;
		collation_callbacks_var.has_ilike_node = &has_ilike_node;
		collation_callbacks_var.translate_bbf_collation_to_tsql_collation = &translate_bbf_collation_to_tsql_collation;
		collation_callbacks_var.translate_tsql_collation_to_bbf_collation = &translate_tsql_collation_to_bbf_collation;
		collation_callbacks_var.set_db_collation = &set_db_collation;
	}
	return &collation_callbacks_var;
}

/*
 * babelfish_define_type_default_collation - would be used to update default collation of Babelfish data types
 * to correct tsql collation.
 */
Oid
babelfish_define_type_default_collation(Oid typeNamespace)
{
	const char *babelfish_dump_restore = GetConfigOption("babelfishpg_tsql.dump_restore", true, false);

	/* We should only override the default collation for Babelfish data types. */
	if (strcmp(get_namespace_name(typeNamespace), "sys") != 0)
		return DEFAULT_COLLATION_OID;

	/*
	 * If upgrade is going on then we should use oid corresponding to
	 * babelfishpg_tsql.restored_server_collation_name.
	 */
	if ((babelfish_dump_restore &&
		 strncmp(babelfish_dump_restore, "on", 2) == 0) &&
		babelfish_restored_server_collation_name)
		return get_collation_oid_internal(babelfish_restored_server_collation_name);

	get_database_or_server_collation_oid_internal(false);	/* set and cache
												 * server_collation_oid */

	Assert(OidIsValid(server_collation_oid));

	return server_collation_oid;
}

PG_FUNCTION_INFO_V1(get_babel_server_collation_oid);

Datum
get_babel_server_collation_oid(PG_FUNCTION_ARGS)
{
	PG_RETURN_OID(get_database_or_server_collation_oid_internal(false));
}

PG_FUNCTION_INFO_V1(babelfish_update_server_collation_name);

/*
 * babelfish_update_server_collation_name - corresponding to sys.babelfish_update_server_collation_name() function
 * which would be available and strictly be used during 1.x->2.3 and 2.3->3.0  upgrade.
 */
Datum
babelfish_update_server_collation_name(PG_FUNCTION_ARGS)
{
	MemoryContext oldContext;

	/* If babelfish_restored_server_collation_name is set then use it. */
	if (babelfish_restored_server_collation_name == NULL)
	{
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Invalid use of function babelfish_update_server_collation_name is detected.")));
	}

	if (!is_valid_server_collation_name(babelfish_restored_server_collation_name))
	{
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Invalid value of babelfishpg_tsql.restored_server_collation_name GUC is detected.")));
	}

	oldContext = MemoryContextSwitchTo(TopMemoryContext);
	if (server_collation_name)
		pfree(server_collation_name);
	server_collation_name = pstrdup(babelfish_restored_server_collation_name);
	MemoryContextSwitchTo(oldContext);
	PG_RETURN_VOID();
}

Oid like_cid = InvalidOid;

void bbf_set_like_collation(Oid collation)
{
	like_cid = collation;
}

Oid bbf_get_like_collation(void)
{
	return like_cid;
}

/*
 * The following function expects a valid collation Oid
 * Caller is reponsible to supply valid Oid
 */
void
set_db_collation(Oid db_coll)
{
	if (!OidIsValid(db_coll))
		ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_DATABASE),
			 errmsg("Could not find database with collation oid \"%u\"", db_coll)));
	database_collation_oid = db_coll;
	database_collation_collidx = find_any_collation((lookup_collation_table(database_collation_oid).collname), false);
	db_collation_is_CI = collation_is_CI(database_collation_oid);
}