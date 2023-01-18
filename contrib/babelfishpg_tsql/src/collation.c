#include "postgres.h"
#include "src/collation.h"

#include "collation.h"
#include "fmgr.h"
#include "guc.h"
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


#include "pltsql.h"

#define SORT_KEY_STR "\357\277\277\0"

#define NOT_FOUND -1

Tsql_collation_callbacks collation_callbacks = {NULL, NULL, NULL, NULL};

Oid get_tsql_collation_oid(int persist_coll_id);
int get_persist_collation_id(Oid coll_oid);

/*  Memory context  */
extern MemoryContext TransMemoryContext;

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
  { "latin1_general_100_bin2", "bbf_unicode_bin2", 1252 },
  { "latin1_general_140_bin2", "bbf_unicode_bin2", 1252 },
  { "latin1_general_90_bin2", "bbf_unicode_bin2", 1252 },
  { "latin1_general_bin2", "bbf_unicode_bin2", 1252 },
  { "latin1_general_ci_ai", "bbf_unicode_cp1_ci_ai", 1252 },
  { "latin1_general_ci_as", "bbf_unicode_cp1_ci_as", 1252 },
  { "latin1_general_cs_ai", "bbf_unicode_cp1_cs_ai", 1252 },
  { "latin1_general_cs_as", "bbf_unicode_cp1_cs_as", 1252 },
  { "sql_latin1_general_cp1250_ci_as", "bbf_unicode_cp1250_ci_as", 1250 },
  { "sql_latin1_general_cp1250_cs_as", "bbf_unicode_cp1250_cs_as", 1250 },
  { "sql_latin1_general_cp1251_ci_as", "bbf_unicode_cp1_ci_as", 1251 },
  { "sql_latin1_general_cp1251_cs_as", "bbf_unicode_cp1_cs_as", 1251 },
  { "sql_latin1_general_cp1253_ci_as", "bbf_unicode_cp1253_ci_as", 1253 },
  { "sql_latin1_general_cp1253_cs_as", "bbf_unicode_cp1253_cs_as", 1253 },
  { "sql_latin1_general_cp1254_ci_as", "bbf_unicode_cp1254_ci_as", 1254 },
  { "sql_latin1_general_cp1254_cs_as", "bbf_unicode_cp1254_cs_as", 1254 },
  { "sql_latin1_general_cp1255_ci_as", "bbf_unicode_cp1255_ci_as", 1255 },
  { "sql_latin1_general_cp1255_cs_as", "bbf_unicode_cp1255_cs_as", 1255 },
  { "sql_latin1_general_cp1256_ci_as", "bbf_unicode_cp1256_ci_as", 1256 },
  { "sql_latin1_general_cp1256_cs_as", "bbf_unicode_cp1256_cs_as", 1256 },
  { "sql_latin1_general_cp1257_ci_as", "bbf_unicode_cp1257_ci_as", 1257 },
  { "sql_latin1_general_cp1257_cs_as", "bbf_unicode_cp1257_cs_as", 1257 },
  { "sql_latin1_general_cp1258_ci_as", "bbf_unicode_cp1258_ci_as", 1258 },
  { "sql_latin1_general_cp1258_cs_as", "bbf_unicode_cp1258_cs_as", 1258 },
  { "sql_latin1_general_cp1_ci_ai", "bbf_unicode_cp1_ci_ai", 1252 },
  { "sql_latin1_general_cp1_ci_as", "bbf_unicode_cp1_ci_as", 1252 }, /* default */
  { "sql_latin1_general_cp1_cs_ai", "bbf_unicode_cp1_cs_ai", 1252 },
  { "sql_latin1_general_cp1_cs_as", "bbf_unicode_cp1_cs_as", 1252 },
  
  //  { "sql_latin1_general_cp850_ci_as", "bbf_unicode_cp850_ci_as", 850 },
  //  { "sql_latin1_general_cp850_cs_as", "bbf_unicode_cp850_cs_as", 850 },
  
  { "sql_latin1_general_cp874_ci_as", "bbf_unicode_cp874_ci_as", 874 },
  { "sql_latin1_general_cp874_cs_as", "bbf_unicode_cp874_cs_as", 874 },
  { "sql_latin1_general_pref_cp1_cs_as", "bbf_unicode_cp1_pref_cs_as", 1252 }
};
#define TOTAL_COLL_TRANSLATION_COUNT (sizeof(coll_translations)/sizeof(coll_translations[0]))

coll_info_t coll_infos[] =
{
  {0, "arabic_ci_ai",                 1025, 0, 196608,  0, 0x000f, 1256},
  {0, "arabic_ci_as",                 1025, 0, 196608,  0, 0x000d, 1256},
  {0, "arabic_cs_as",                 1025, 0, 196608,  0, 0x000c, 1256},

  {0, "bbf_unicode_bin2",              1033, 0, 196608, 54, 0x0220, 1252},

  {0, "bbf_unicode_cp1250_ci_ai",      1045, 0, 196608, 54, 0x000f, 1250},
  {0, "bbf_unicode_cp1250_ci_as",      1045, 0, 196608, 52, 0x000d, 1250},
  {0, "bbf_unicode_cp1250_cs_ai",      1045, 0, 196608, 51, 0x000e, 1250},
  {0, "bbf_unicode_cp1250_cs_as",      1045, 0, 196608, 51, 0x000c, 1250},

  {0, "bbf_unicode_cp1251_ci_ai",      1049, 0, 196608, 54, 0x000f, 1251},
  {0, "bbf_unicode_cp1251_ci_as",      1049, 0, 196608, 52, 0x000d, 1251},
  {0, "bbf_unicode_cp1251_cs_ai",      1049, 0, 196608, 51, 0x000e, 1251},
  {0, "bbf_unicode_cp1251_cs_as",      1049, 0, 196608, 51, 0x000c, 1251},

  // {0, "bbf_unicode_cp1252_ci_ai",      1033, 0, 196608, 54, 0x000f, 1252},
  // {0, "bbf_unicode_cp1252_ci_as",      1033, 0, 196608, 52, 0x000d, 1252},
  // {0, "bbf_unicode_cp1252_cs_ai",      1033, 0, 196608, 51, 0x000e, 1252},
  // {0, "bbf_unicode_cp1252_cs_as",      1033, 0, 196608, 51, 0x000c, 1252},

  {0, "bbf_unicode_cp1253_ci_ai",      1032, 0, 196608, 54, 0x000f, 1253},
  {0, "bbf_unicode_cp1253_ci_as",      1032, 0, 196608, 52, 0x000d, 1253},
  {0, "bbf_unicode_cp1253_cs_ai",      1032, 0, 196608, 51, 0x000e, 1253},
  {0, "bbf_unicode_cp1253_cs_as",      1032, 0, 196608, 51, 0x000c, 1253},

  {0, "bbf_unicode_cp1254_ci_ai",      1055, 0, 196608, 54, 0x000f, 1254},
  {0, "bbf_unicode_cp1254_ci_as",      1055, 0, 196608, 52, 0x000d, 1254},
  {0, "bbf_unicode_cp1254_cs_ai",      1055, 0, 196608, 51, 0x000e, 1254},
  {0, "bbf_unicode_cp1254_cs_as",      1055, 0, 196608, 51, 0x000c, 1254},

  {0, "bbf_unicode_cp1255_ci_ai",      1037, 0, 196608, 54, 0x000f, 1255},
  {0, "bbf_unicode_cp1255_ci_as",      1037, 0, 196608, 52, 0x000d, 1255},
  {0, "bbf_unicode_cp1255_cs_ai",      1037, 0, 196608, 51, 0x000e, 1255},
  {0, "bbf_unicode_cp1255_cs_as",      1037, 0, 196608, 51, 0x000c, 1255},

  {0, "bbf_unicode_cp1256_ci_ai",      1025, 0, 196608, 54, 0x000f, 1256},
  {0, "bbf_unicode_cp1256_ci_as",      1025, 0, 196608, 52, 0x000d, 1256},
  {0, "bbf_unicode_cp1256_cs_ai",      1025, 0, 196608, 51, 0x000e, 1256},
  {0, "bbf_unicode_cp1256_cs_as",      1025, 0, 196608, 51, 0x000c, 1256},

  {0, "bbf_unicode_cp1257_ci_ai",      1061, 0, 196608, 54, 0x000f, 1257},
  {0, "bbf_unicode_cp1257_ci_as",      1061, 0, 196608, 52, 0x000d, 1257},
  {0, "bbf_unicode_cp1257_cs_ai",      1061, 0, 196608, 51, 0x000e, 1257},
  {0, "bbf_unicode_cp1257_cs_as",      1061, 0, 196608, 51, 0x000c, 1257},

  {0, "bbf_unicode_cp1258_ci_ai",      1066, 0, 196608, 54, 0x000f, 1258},
  {0, "bbf_unicode_cp1258_ci_as",      1066, 0, 196608, 52, 0x000d, 1258},
  {0, "bbf_unicode_cp1258_cs_ai",      1066, 0, 196608, 51, 0x000e, 1258},
  {0, "bbf_unicode_cp1258_cs_as",      1066, 0, 196608, 51, 0x000c, 1258},

  {0, "bbf_unicode_cp1_ci_ai",      1033, 0, 196608, 54, 0x000f, 1252},
  {0, "bbf_unicode_cp1_ci_as",      1033, 0, 196608, 52, 0x000d, 1252},  /* default */
  {0, "bbf_unicode_cp1_cs_ai",      1033, 0, 196608, 51, 0x000e, 1252},
  {0, "bbf_unicode_cp1_cs_as",      1033, 0, 196608, 51, 0x000c, 1252},

  // {0, "bbf_unicode_cp850_ci_ai",      1033, 0, 196608, 54, 0x000f, 850},
  // {0, "bbf_unicode_cp850_ci_as",      1033, 0, 196608, 52, 0x000d, 850},
  // {0, "bbf_unicode_cp850_cs_ai",      1033, 0, 196608, 51, 0x000e, 850},
  // {0, "bbf_unicode_cp850_cs_as",      1033, 0, 196608, 51, 0x000c, 850},

  {0, "bbf_unicode_cp874_ci_ai",      1054, 0, 196608, 54, 0x000f, 874},
  {0, "bbf_unicode_cp874_ci_as",      1054, 0, 196608, 52, 0x000d, 874},
  {0, "bbf_unicode_cp874_cs_ai",      1054, 0, 196608, 51, 0x000e, 874},
  {0, "bbf_unicode_cp874_cs_as",      1054, 0, 196608, 51, 0x000c, 874},

  /* For the bbf_unicode_general collations, set lcid and codepage based on pltsql_default_locale */
  {0, "bbf_unicode_general_ci_ai",      1033, 0, 196608, 54, 0x000f, 0},
  {0, "bbf_unicode_general_ci_as",      1033, 0, 196608, 52, 0x000d, 0},
  {0, "bbf_unicode_general_cs_ai",      1033, 0, 196608, 51, 0x000e, 0},
  {0, "bbf_unicode_general_cs_as",      1033, 0, 196608, 51, 0x000c, 0},

  /* pref collations */
  {0, "bbf_unicode_general_pref_cs_as", 1033, 0, 196608, 51, 0x000c, 0},
  {0, "bbf_unicode_pref_cp1250_cs_as", 1045, 0, 196608, 51, 0x000c, 1250},
  {0, "bbf_unicode_pref_cp1251_cs_as", 1049, 0, 196608, 51, 0x000c, 1251},
  {0, "bbf_unicode_pref_cp1253_cs_as", 1032, 0, 196608, 51, 0x000c, 1253},
  {0, "bbf_unicode_pref_cp1254_cs_as", 1055, 0, 196608, 51, 0x000c, 1254},
  {0, "bbf_unicode_pref_cp1255_cs_as", 1037, 0, 196608, 51, 0x000c, 1255},
  {0, "bbf_unicode_pref_cp1256_cs_as", 1025, 0, 196608, 51, 0x000c, 1256},
  {0, "bbf_unicode_pref_cp1257_cs_as", 1061, 0, 196608, 51, 0x000c, 1257},
  {0, "bbf_unicode_pref_cp1258_cs_as", 1066, 0, 196608, 51, 0x000c, 1258},
  {0, "bbf_unicode_pref_cp1_cs_as", 1033, 0, 196608, 51, 0x000c, 1252},
  // {0, "bbf_unicode_pref_cp850_cs_as", 1033, 0, 196608, 51, 0x000c, 850},
  {0, "bbf_unicode_pref_cp874_cs_as", 1054, 0, 196608, 51, 0x000c, 874},
  
  {0, "chinese_prc_ci_ai",            2052, 0, 196608,  0, 0x000f, 936},
  {0, "chinese_prc_ci_as",            2052, 0, 196608,  0, 0x000d, 936},
  {0, "chinese_prc_cs_as",            2052, 0, 196608,  0, 0x000c, 936},

  {0, "cyrillic_general_ci_ai",       1049, 0, 196608,  0, 0x000f, 1251},
  {0, "cyrillic_general_ci_as",       1049, 0, 196608,  0, 0x000d, 1251},
  {0, "cyrillic_general_cs_as",       1049, 0, 196608,  0, 0x000c, 1251},

  {0, "estonian_ci_ai",               1061, 0, 196608,  0, 0x000f, 1257},
  {0, "estonian_ci_as",               1061, 0, 196608,  0, 0x000d, 1257},
  {0, "estonian_cs_as",               1061, 0, 196608,  0, 0x000c, 1257},

  {0, "finnish_swedish_ci_ai",        1035, 0, 196608,  0, 0x000f, 1252},
  {0, "finnish_swedish_ci_as",        1035, 0, 196608,  0, 0x000d, 1252},
  {0, "finnish_swedish_cs_as",        1035, 0, 196608,  0, 0x000c, 1252},

  {0, "french_ci_ai",                 1036, 0, 196608,  0, 0x000f, 1252},
  {0, "french_ci_as",                 1036, 0, 196608,  0, 0x000d, 1252},
  {0, "french_cs_as",                 1036, 0, 196608,  0, 0x000c, 1252},

  {0, "greek_ci_ai",                  1032, 0, 196608,  0, 0x000f, 1253},
  {0, "greek_ci_as",                  1032, 0, 196608,  0, 0x000d, 1253},
  {0, "greek_cs_as",                  1032, 0, 196608,  0, 0x000c, 1253},

  {0, "hebrew_ci_ai",                 1037, 0, 196608,  0, 0x000f, 1255},
  {0, "hebrew_ci_as",                 1037, 0, 196608,  0, 0x000d, 1255},
  {0, "hebrew_cs_as",                 1037, 0, 196608,  0, 0x000c, 1255},

  {0, "korean_wansung_ci_ai",         1042, 0, 196608,  0, 0x000f, 949},
  {0, "korean_wansung_ci_as",         1042, 0, 196608,  0, 0x000d, 949},
  {0, "korean_wansung_cs_as",         1042, 0, 196608,  0, 0x000c, 949},

  {0, "modern_spanish_ci_ai",         3082, 0, 196608,  0, 0x000f, 1252},
  {0, "modern_spanish_ci_as",         3082, 0, 196608,  0, 0x000d, 1252},
  {0, "modern_spanish_cs_as",         3082, 0, 196608,  0, 0x000c, 1252},

  {0, "mongolian_ci_ai",              1104, 0, 196608,  0, 0x000f, 1251},
  {0, "mongolian_ci_as",              1104, 0, 196608, 52, 0x000d, 1251},
  {0, "mongolian_cs_as",              1104, 0, 196608, 51, 0x000c, 1251},

  {0, "polish_ci_ai",                 1045, 0, 196608,  0, 0x000f, 1250},
  {0, "polish_ci_as",                 1045, 0, 196608,  0, 0x000d, 1250},
  {0, "polish_cs_as",                 1045, 0, 196608,  0, 0x000c, 1250},

  {0, "thai_ci_ai",                   1054, 0, 196608,  0, 0x000f, 874},
  {0, "thai_ci_as",                   1054, 0, 196608,  0, 0x000d, 874},
  {0, "thai_cs_as",                   1054, 0, 196608,  0, 0x000c, 874},

  {0, "traditional_spanish_ci_ai",    1034, 0, 196608,  0, 0x000f, 1252},
  {0, "traditional_spanish_ci_as",    1034, 0, 196608,  0, 0x000d, 1252},
  {0, "traditional_spanish_cs_as",    1034, 0, 196608,  0, 0x000c, 1252},

  {0, "turkish_ci_ai",                1055, 0, 196608,  0, 0x000f, 1254},
  {0, "turkish_ci_as",                1055, 0, 196608,  0, 0x000d, 1254},
  {0, "turkish_cs_as",                1055, 0, 196608,  0, 0x000c, 1254},

  {0, "ukrainian_ci_ai",              1058, 0, 196608,  0, 0x000f, 1251},
  {0, "ukrainian_ci_as",              1058, 0, 196608,  0, 0x000d, 1251},
  {0, "ukrainian_cs_as",              1058, 0, 196608,  0, 0x000c, 1251},

  {0, "vietnamese_ci_ai",             1066, 0, 196608,  0, 0x000f, 1258},
  {0, "vietnamese_ci_as",             1066, 0, 196608,  0, 0x000d, 1258},
  {0, "vietnamese_cs_as",             1066, 0, 196608,  0, 0x000c, 1258},
};

#define TOTAL_COLL_COUNT (sizeof(coll_infos)/sizeof(coll_infos[0]))

/* 
 * ICU locales:
 *     https://www.localeplanet.com/icu/
 *
 * The default code page is 0 for Unicode-only locales.
 */
locale_info_t locales[] =
{
  {0x0436, 	1252, 	"af-ZA"}, // Afrikaans: South Africa
  {0x041c, 	1250, 	"sq-AL"}, // Albanian: Albania
  {0x1401, 	1256, 	"ar-DZ"}, // Arabic: Algeria
  {0x3c01, 	1256, 	"ar-BH"}, // Arabic: Bahrain
  {0x0c01, 	1256, 	"ar-EG"}, // Arabic: Egypt
  {0x0801, 	1256, 	"ar-IQ"}, // Arabic: Iraq
  {0x2c01, 	1256, 	"ar-JO"}, // Arabic: Jordan
  {0x3401, 	1256, 	"ar-KW"}, // Arabic: Kuwait
  {0x3001, 	1256, 	"ar-LB"}, // Arabic: Lebanon
  {0x1001, 	1256, 	"ar-LY"}, // Arabic: Libya
  {0x1801, 	1256, 	"ar-MA"}, // Arabic: Morocco
  {0x2001, 	1256, 	"ar-OM"}, // Arabic: Oman
  {0x4001, 	1256, 	"ar-QA"}, // Arabic: Qatar
  {0x0401, 	1256, 	"ar-SA"}, // Arabic: Saudi Arabia
  {0x2801, 	1256, 	"ar-SY"}, //Arabic: Syria
  {0x1c01, 	1256, 	"ar-TN"}, // Arabic: Tunisia
  {0x3801, 	1256, 	"ar-AE"}, // Arabic: U.A.E.
  {0x2401, 	1256, 	"ar-YE"}, // Arabic: Yemen
  {0x042b, 	0, 	"hy-AM"}, // Armenian: Armenia
  {0x082c, 	1251, 	"az-Cyrl-AZ"}, // Azeri: Azerbaijan (Cyrillic)
  {0x042c, 	1250, 	"az-Latn-AZ"}, // Azeri: Azerbaijan (Latin)
  {0x042d, 	1252, 	"eu-ES"}, // Basque: Spain
  {0x0423, 	1251, 	"be-BY"}, // Belarusian: Belarus
  {0x0402, 	1251, 	"bg-BG"}, // Bulgarian: Bulgaria
  {0x0403, 	1252, 	"ca-ES"}, // Catalan: Spain
  {0x0c04, 	950, 	"zh-HK"}, // Chinese: Hong Kong SAR, PRC (Traditional)
  {0x1404, 	950, 	"zh-MO"}, // Chinese: Macao SAR (Traditional)
  {0x0804, 	936, 	"zh-CN"}, // Chinese: PRC (Simplified)
  {0x1004, 	936, 	"zh-SG"}, // Chinese: Singapore (Simplified)
  {0x0404, 	950, 	"zh-TW"}, // Chinese: Taiwan (Traditional)
  // {0x0827, 	1257, 	Classic Lithuanian: Lithuania
  {0x041a, 	1250, 	"hr-HR"}, // Croatian: Croatia
  {0x0405, 	1250, 	"cs-CZ"}, // Czech: Czech Republic
  {0x0406, 	1252, 	"da-DK"}, // Danish: Denmark
  {0x0813, 	1252, 	"nl-BE"}, // Dutch: Belgium
  {0x0413, 	1252, 	"nl-NL"}, // Dutch: Netherlands
  {0x0c09, 	1252, 	"en-AU"}, // English: Australia
  {0x2809, 	1252, 	"en-BZ"}, // English: Belize
  {0x1009, 	1252, 	"en-CA"}, // English: Canada
  // {0x2409, 	1252, 	English: Caribbean
  {0x1809, 	1252, 	"en-IE"}, // English: Ireland
  {0x2009, 	1252, 	"en-JM"}, // English: Jamaica
  {0x1409, 	1252, 	"en-NZ"}, // English: New Zealand
  {0x3409, 	1252, 	"en-PH"}, // English: Philippines
  {0x1c09, 	1252, 	"en-ZA"}, // English: South Africa
  {0x2c09, 	1252, 	"en-TT"}, // English: Trinidad
  {0x0809, 	1252, 	"en-GB"}, // English: United Kingdom
  {0x0409, 	1252, 	"en-US"}, // English: United States
  {0x3009, 	1252, 	"en-ZW"}, // English: Zimbabwe
  {0x0425, 	1257, 	"et-EE"}, // Estonian: Estonia
  {0x0438, 	1252, 	"fo-FO"}, // Faeroese: Faeroe Islands
  {0x0429, 	1256, 	"fa-IR"}, // Farsi: Iran
  {0x040b, 	1252, 	"fi-FI"}, // Finnish: Finland
  {0x080c, 	1252, 	"fr-BE"}, // French: Belgium
  {0x0c0c, 	1252, 	"fr-CA"}, // French: Canada
  {0x040c, 	1252, 	"fr-FR"}, // French: France
  {0x140c, 	1252, 	"fr-LU"}, // French: Luxembourg
  {0x180c, 	1252, 	"fr-MC"}, // French: Monaco
  {0x100c, 	1252, 	"fr-CH"}, // French: Switzerland
  {0x042f, 	1251, 	"mk-MK"}, // Macedonian (FYROM)
  {0x0437, 	0, 	"ka-GE"}, // Georgian: Georgia
  {0x0c07, 	1252, 	"de-AT"}, // German: Austria
  {0x0407, 	1252, 	"de-DE"}, // German: Germany
  {0x1407, 	1252, 	"de-LI"}, // German: Liechtenstein
  {0x1007, 	1252, 	"de-LU"}, // German: Luxembourg
  {0x0807, 	1252, 	"de-CH"}, // German: Switzerland
  {0x0408, 	1253, 	"el-GR"}, // Greek: Greece
  {0x0447, 	0, 	"gu-IN"}, // Gujarati: India
  {0x040d, 	1255, 	"he-IL"}, // Hebrew: Israel
  {0x0439, 	0, 	"hi-IN"}, // Hindi: India
  {0x040e, 	1250, 	"hu-HU"}, // Hungarian: Hungary
  {0x040f, 	1252, 	"is-IS"}, // Icelandic: Iceland
  {0x0421, 	1252, 	"id-ID"}, // Indonesian: Indonesia
  {0x0410, 	1252, 	"it-IT"}, // Italian: Italy
  {0x0810, 	1252, 	"it-CH"}, // Italian: Switzerland
  {0x0411, 	932, 	"ja-JP"}, // Japanese: Japan
  {0x044b, 	0, 	"kn-IN"}, // Kannada: India
  {0x0457, 	0, 	"kok-IN"}, // Konkani: India
  {0x0412, 	949, 	"ko-KR"}, // Korean (Extended Wansung): Korea
  {0x0440, 	1251, 	"ky-KG"}, // Kyrgyz: Kyrgyzstan
  {0x0426, 	1257, 	"lv-LV"}, // Latvian: Latvia
  {0x0427, 	1257, 	"lt-LT"}, // Lithuanian: Lithuania
  {0x083e, 	1252,   "ms-BN"}, // Malay: Brunei Darussalam
  {0x043e, 	1252, 	"ms-MY"}, // Malay: Malaysia
  {0x044e, 	0, 	"mr-IN"}, // Marathi: India
  {0x0450, 	1251, 	"mn-MN"}, // Mongolian: Mongolia
  {0x0414, 	1252, 	"nb-NO"}, // Norwegian: Norway (Bokmål)
  {0x0814, 	1252, 	"nn-NO"}, // Norwegian: Norway (Nynorsk)
  {0x0415, 	1250, 	"pl-PL"}, // Polish: Poland
  {0x0416, 	1252, 	"pt-BR"}, // Portuguese: Brazil
  {0x0816, 	1252, 	"pt-PT"}, // Portuguese: Portugal
  {0x0446, 	0, 	"pa-IN"}, // Punjabi: India
  {0x0418, 	1250, 	"ro-RO"}, // Romanian: Romania
  {0x0419, 	1251, 	"ru-RU"}, // Russian: Russia
  {0x044f, 	0, 	"sa-IN"}, // Sanskrit: India
  {0x0c1a, 	1251, 	"sr-Cyrl-RS"}, // Serbian: Serbia (Cyrillic)
  {0x081a, 	1250, 	"sr-Latn-RS"}, // Serbian: Serbia (Latin)
  {0x041b, 	1250, 	"sk-SK"}, // Slovak: Slovakia
  {0x0424, 	1250, 	"sl-SI"}, // Slovenian: Slovenia
  {0x2c0a, 	1252, 	"es-AR"}, // Spanish: Argentina
  {0x400a, 	1252, 	"es-BO"}, // Spanish: Bolivia
  {0x340a, 	1252, 	"es-CL"}, // Spanish: Chile
  {0x240a, 	1252, 	"es-CO"}, // Spanish: Colombia
  {0x140a, 	1252, 	"es-CR"}, // Spanish: Costa Rica
  {0x1c0a, 	1252, 	"es-DO"}, // Spanish: Dominican Republic
  {0x300a, 	1252, 	"es-EC"}, // Spanish: Ecuador
  {0x440a, 	1252, 	"es-SV"}, // Spanish: El Salvador
  {0x100a, 	1252, 	"es-GT"}, // Spanish: Guatemala
  {0x480a, 	1252, 	"es-HN"}, // Spanish: Honduras
  {0x080a, 	1252, 	"es-MX"}, // Spanish: Mexico
  {0x4c0a, 	1252, 	"es-NI"}, // Spanish: Nicaragua
  {0x180a, 	1252, 	"es-PA"}, // Spanish: Panama
  {0x3c0a, 	1252, 	"es-PY"}, // Spanish: Paraguay
  {0x280a, 	1252, 	"es-PE"}, // Spanish: Peru
  {0x500a, 	1252, 	"es-PR"}, // Spanish: Puerto Rico
  {0x0c0a, 	1252, 	"es-ES"}, // Spanish: Spain (Modern Sort)
  {0x040a, 	1252, 	"es-TRADITIONAL"}, // Spanish: Spain (International Sort)
  {0x380a, 	1252, 	"es-UY"}, // Spanish: Uruguay
  {0x200a, 	1252, 	"es-VE"}, // Spanish: Venezuela
  {0x0441, 	1252, 	"sw-KE"}, // Swahili: Kenya
  {0x081d, 	1252, 	"sv-FI"}, // Swedish: Finland
  {0x041d, 	1252, 	"sv-SE"}, // Swedish: Sweden
  {0x0444, 	1251, 	"tt-RU"}, // Tatar: Tatarstan
  {0x044a, 	0, 	"te-IN"}, // Telgu: India
  {0x041e, 	874, 	"th-TH"}, // Thai: Thailand
  {0x041f, 	1254, 	"tr-TR"}, // Turkish: Turkey
  {0x0422, 	1251, 	"uk-UA"}, // Ukrainian: Ukraine
  {0x0820, 	1256, 	"ur-IN"}, // Urdu: India
  {0x0420, 	1256, 	"ur-PK"}, // Urdu: Pakistan
  {0x0843, 	1251, 	"uz-Cyrl-UZ"}, // Uzbek: Uzbekistan (Cyrillic)
  {0x0443, 	1250, 	"uz-Latn-UZ"}, // Uzbek: Uzbekistan (Latin)
  {0x042a, 	1258, 	"vi-VN"}, // Vietnamese: Vietnam
};

#define TOTAL_LOCALES (sizeof(locales)/sizeof(locales[0]))

/* This table is storing the necessary info for
 * LIKE to ILIKE transformation(BABEL-1529)
 * we query the oid from the operator name(column 2 and 3)
 * and operand type(colume 4,5,6 and 7)
 */
like_ilike_info_t like_ilike_table[] =
{
    {0, "~~",   "~~*",  "pg_catalog", "name",   "pg_catalog", "text", false,  0},
    {0, "!~~",  "!~~*", "pg_catalog", "name",   "pg_catalog", "text", true,   0},
    {0, "~~",   "~~*",  "pg_catalog", "text",   "pg_catalog", "text", false,  0},
    {0, "!~~",  "!~~*", "pg_catalog", "text",   "pg_catalog", "text", true,   0},
    {0, "~~",   "~~*",  "pg_catalog", "bpchar", "pg_catalog", "text", false,  0},
    {0, "!~~",  "!~~*", "pg_catalog", "bpchar", "pg_catalog", "text", true,  0},
    {0, "~~",   "~~*",  "sys",        "bpchar", "pg_catalog", "text", false,  0},
    {0, "!~~",  "!~~*", "sys",        "bpchar", "pg_catalog", "text", true,  0},
};

#define TOTAL_LIKE_OP_COUNT (sizeof(like_ilike_table)/sizeof(like_ilike_table[0]))

/* Hash tables to help backward searching (from OID to Persist ID) */
HTAB *ht_oid2collid = NULL;
HTAB *ht_like2ilike = NULL;

/* Cached values derived from server_collation_name */
static int server_collation_collidx = NOT_FOUND;
static Oid server_collation_oid = InvalidOid;
static bool pltsql_db_collation_is_CI_AS = true;

/* storing CS_AS collation id for LIKE to ILIKE transformation */
Oid bbf_unicode_general_cs_as_collid;

static int
find_collation(const char *collation_name);
static int
translate_collation(const char *collation_name);
static Node *
pgtsql_like_to_ilike_mutator(Node *node, void* context);

static Node* like2ilike_transformer(Node *expr);
/* transform LIKE node to ILIKE */
static Node* transform_likenode(Node* expr);

static Expr *
make_op_with_func(Oid opno, Oid opresulttype, bool opretset,
			  Expr *leftop, Expr *rightop,
			  Oid opcollid, Oid inputcollid, Oid oprfuncid);

static Node *
make_or_qual(Node *qual1, Node *qual2);

extern int pattern_fixed_prefix_wrapper(Const *patt,
                                        int ptype,
                                        Oid collation,
                                        Const **prefix,
                                        Selectivity *rest_selec);

/* pattern prefix status for pattern_fixed_prefix_wrapper
 * Pattern_Prefix_None: no prefix found, this means the first character is a wildcard character
 * Pattern_Prefix_Exact: the pattern doesn't include any wildcard character
 * Pattern_Prefix_Partial: the pattern has a constant prefix
 */ 
typedef enum
{
	Pattern_Prefix_None, Pattern_Prefix_Partial, Pattern_Prefix_Exact
} Pattern_Prefix_Status;

PG_FUNCTION_INFO_V1(init_collid_trans_tab);
PG_FUNCTION_INFO_V1(init_like_ilike_table);
PG_FUNCTION_INFO_V1(get_server_collation_oid); 
 
/* this function is no longer needed and is only a placeholder for upgrade script */
PG_FUNCTION_INFO_V1(init_server_collation);
Datum init_server_collation(PG_FUNCTION_ARGS) 
{
    PG_RETURN_INT32(0);
}
/* this function is no longer needed and is only a placeholder for upgrade script */
PG_FUNCTION_INFO_V1(init_server_collation_oid);
Datum init_server_collation_oid(PG_FUNCTION_ARGS)
{
    PG_RETURN_INT32(0);
}

bool
is_server_collation_CI_AS()
{
    get_server_collation_oid_internal();
    return pltsql_db_collation_is_CI_AS;
}

/* Given a coll_infos index, return the CS_AS or BIN2 collation with
 * the same lcid. A cs_as collation exists for every distinct lcid.
 */
int
find_cs_as_collation(int collidx)
{
    int cur_collidx = collidx;

    if (NOT_FOUND == collidx)
	return collidx;

    while (cur_collidx < TOTAL_COLL_COUNT &&
	   coll_infos[cur_collidx].lcid == coll_infos[collidx].lcid)
    {
	if ( coll_infos[cur_collidx].collateflags == 0x000c /* CS_AS  */ ||
	     coll_infos[cur_collidx].collateflags == 0x0220 /* BIN2 */ )
	    return cur_collidx;

	cur_collidx++;
    }

    return NOT_FOUND;
}

int
find_any_collation(const char *collation_name)
{
    int collidx = translate_collation(collation_name);

    if (NOT_FOUND == collidx)
	collidx = find_collation(collation_name);

    return collidx;
}

static int
find_collation(const char *collation_name)
{
    int first = 0;
    int last = TOTAL_COLL_COUNT - 1;
    int middle = 37;  /* optimization: usually it's the default collation (first + last) / 2; */
    int compare;

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

static int
translate_collation(const char *collation_name)
{
    int first = 0;
    int last = TOTAL_COLL_TRANSLATION_COUNT - 1;
    int middle = 25; /* optimization: usually it's the default collation (first + last) / 2; */
    int compare;

    while (first <= last)
    {
	compare = pg_strcasecmp(coll_translations[middle].from_collname, collation_name);
	if (compare < 0)
	    first = middle + 1;
	else if (compare == 0)
	    return find_collation(coll_translations[middle].to_collname);
	else
	    last = middle - 1;

	middle = (first + last) / 2;
    }

    return NOT_FOUND;;
}

int
find_locale(const char *given_locale)
{
    int i;
    char *normalized_locale = NULL;

    /* Normalize given_locale before searching the locales array
     */
    if (NULL == given_locale ||
	0 == strlen(given_locale) ||
	strlen(given_locale) > MAX_ICU_LOCALE_LEN)
    {
      // normalized_locale = palloc0(strlen("en-US") + 1);
      // memmove(normalized_locale, "en-US", strlen("en-US"));
        return NOT_FOUND;
    }
    else
    {
        char *underscore_pos;

        normalized_locale = palloc0(strlen(given_locale) + 1);
	memcpy(normalized_locale, given_locale, strlen(given_locale));
	underscore_pos = strstr(normalized_locale, "_");	

        while (NULL != underscore_pos)
        {
	    *underscore_pos = '-';
	    underscore_pos = strstr(normalized_locale, "_");
	}

    }

    for (i=0; i < TOTAL_LOCALES; ++i)
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
 *                  Translation Table Initializers
 *  Load information from C arrays into hash tables
 *  Initializers are called right after shared library loading
 *  During "CREATE EXTENSION", data types are created after initialization call
 *  In this case, initializers do nothing
 *  After data types are created, initializers will be triggered again
 *  with a built-in procedure
 *
 */
Datum
init_collid_trans_tab(PG_FUNCTION_ARGS)
{
	HASHCTL hashCtl;
	Oid nspoid;
	ht_oid2collid_entry_t *entry;
	int locale_pos = -1;
	HeapTuple tp;
	char *atsign;
	char *locale;

	if (TransMemoryContext == NULL)  /* initialize memory context */
	{
		TransMemoryContext = AllocSetContextCreateInternal(NULL,
									"SQL Variant Memory Context",
									ALLOCSET_DEFAULT_SIZES);
	}

	if (ht_oid2collid == NULL)  /* create hash table */
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(Oid);
		hashCtl.entrysize = sizeof(ht_oid2collid_entry_t);
		hashCtl.hcxt = TransMemoryContext;
		ht_oid2collid = hash_create("OID to Persist Collation ID Mapping",
						TOTAL_COLL_COUNT,
						&hashCtl,
						HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	// locale_pos = find_locale(pltsql_default_locale);

	nspoid = get_namespace_oid("sys", false);

	/* retrieve oid and setup hashtable */
	for (int i=0; i<TOTAL_COLL_COUNT; i++)
	{
		/*
		 * Encoding can be either COLL_DEFAULT_ENCODING - in case of libc based collations
		 * or it can be -1 in case of icu based collations.
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

		/* For the bbf_unicode_general_* collations, fill in the lcid and/or the code_page from the default_locale GUC */
		if (0 == strncmp(coll_infos[i].collname, "bbf_unicode_general", strlen("bbf_unicode_general")))
		{
			locale = pstrdup(pltsql_default_locale);
			atsign = strstr(locale, "@");
			if (atsign != NULL)
				*atsign = '\0';
			locale_pos = find_locale(locale);

			if (locale_pos < 0)
				ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
						errmsg("invalid setting detected for babelfishpg_tsql.default_locale setting")));
			coll_infos[i].lcid = locales[locale_pos].lcid;
			coll_infos[i].code_page = locales[locale_pos].code_page;
			if (locale)
				pfree(locale);
		}
		
		if (OidIsValid(coll_infos[i].oid))
		{
			entry = hash_search(ht_oid2collid, &coll_infos[i].oid, HASH_ENTER, NULL);
			entry->persist_id = i;
		}
	}
    PG_RETURN_INT32(0);
}

/*
 * Get the Index of default collation from coll_infos array, or return NOT_FOUND if not found
 */
int
get_server_collation_collidx(void)
{
    if (NOT_FOUND == server_collation_collidx)
	server_collation_collidx = find_any_collation(pltsql_server_collation_name);

    return server_collation_collidx;
}

/*
 * Query the hash table so that tds can send the right values for the
 * tsql collation on the wire
 */
coll_info_t
lookup_collation_table(Oid coll_oid)
{
    ht_oid2collid_entry_t  *hinfo;
    bool					found;

    Assert(ht_oid2collid != NULL);

    if (!OidIsValid(coll_oid))
    {
	int collidx = get_server_collation_collidx();

	if (NOT_FOUND != collidx)
	    return coll_infos[collidx];
    }

    hinfo = (ht_oid2collid_entry_t *) hash_search(ht_oid2collid,
						  &coll_oid,
						  HASH_FIND,
						  &found);

    /*
     * TODO: Change it to Error, and reload the cache again.
     * If not found, raise the error.
     * For now, silently return NULL, so that we can use
     * the default values
     */
    if (!found)
    {
        coll_info_t invalid;
	invalid.oid = InvalidOid;
	elog(DEBUG2, "collation oid %d not found, using default collation", coll_oid);
	return invalid;
    }

    return coll_infos[hinfo->persist_id];
}

int8_t
cmp_collation(uint16_t coll1, uint16_t coll2){
    coll_info_t * coll_info1 = &coll_infos[coll1];
    coll_info_t * coll_info2 = &coll_infos[coll2];
    if (coll_info1->lcid < coll_info2-> lcid)
        return -1;
    else if (coll_info1->lcid > coll_info2-> lcid)
        return 1;
    else if (coll_info1->ver < coll_info2-> ver)
        return -1;
    else if (coll_info1->ver > coll_info2-> ver)
        return 1;
    else if (coll_info1->style < coll_info2-> style)
        return -1;
    else if (coll_info1->style > coll_info2-> style)
        return 1;
    else if (coll_info1->sortid < coll_info2-> sortid)
        return -1;
    else if (coll_info1->sortid > coll_info2-> sortid)
        return 1;
    else
        return 0;
}

PG_FUNCTION_INFO_V1(collation_list);

Datum
collation_list(PG_FUNCTION_ARGS)
{
    ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
    TupleDesc tupdesc;
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
        coll_info_t *info = &coll_infos[i];
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

Datum
get_server_collation_oid(PG_FUNCTION_ARGS)
{
    PG_RETURN_OID(get_server_collation_oid_internal());
}

Oid
get_server_collation_oid_internal(void)
{
    Oid nspoid;
    const char *collname = pltsql_server_collation_name;
    int collidx;

    if (OidIsValid(server_collation_oid))
        return server_collation_oid;;

    /* The server_collation_name is permitted to be the name of a sql
     * or windows collation that is translated into a bbf collation.
     * If that's what it is then get the translated name.
     */
    if (NOT_FOUND != (collidx = translate_collation(collname)))
        collname = coll_infos[collidx].collname;

    nspoid = get_namespace_oid("sys", false);
    server_collation_oid = GetSysCacheOid3(COLLNAMEENCNSP, Anum_pg_collation_oid,
					 PointerGetDatum(collname),
					 Int32GetDatum(-1),
					 ObjectIdGetDatum(nspoid));

    if (!OidIsValid(server_collation_oid))
	server_collation_oid = GetSysCacheOid3(COLLNAMEENCNSP, Anum_pg_collation_oid,
					 PointerGetDatum(collname),
					 Int32GetDatum(COLL_DEFAULT_ENCODING),
					 ObjectIdGetDatum(nspoid));

    if (!OidIsValid(server_collation_oid))
    {
	ereport(WARNING,
		(errcode(ERRCODE_INTERNAL_ERROR),
		 errmsg("Server default collation sys.\"%s\" is not defined, using the cluster default collation",
			pltsql_server_collation_name)));
	server_collation_oid = DEFAULT_COLLATION_OID;
	pltsql_db_collation_is_CI_AS = false;
	server_collation_collidx = NOT_FOUND;
    }
    else
    {
	pltsql_db_collation_is_CI_AS = collation_is_CI_AS(server_collation_oid);
	server_collation_collidx = get_server_collation_collidx();
    }

    return server_collation_oid;
}

Oid BABELFISH_CLUSTER_COLLATION_OID()
{
    get_server_collation_oid_internal(); /* set and cache server_collation_oid */
    
    if (sql_dialect == SQL_DIALECT_TSQL
        && OidIsValid(server_collation_oid))
    {
	return server_collation_oid;
    }
    else
	return DEFAULT_COLLATION_OID;
}

bool collation_is_CI_AS(Oid colloid)
{
    HeapTuple	tp;
    char       *collcollate = NULL;
    char        collprovider;
    bool        collisdeterministic;

    if (InvalidOid == colloid)
	return false;

    if (GetDatabaseEncoding() != PG_UTF8)
	return false;

    tp = SearchSysCache1(COLLOID, ObjectIdGetDatum(colloid));
    if (!HeapTupleIsValid(tp))
	elog(ERROR, "cache lookup failed for collation %u", colloid);

    collcollate = pstrdup(NameStr(((Form_pg_collation) GETSTRUCT(tp))->collcollate));
    collprovider = ((Form_pg_collation) GETSTRUCT(tp))->collprovider;
    collisdeterministic = ((Form_pg_collation) GETSTRUCT(tp))->collisdeterministic;
    ReleaseSysCache(tp);

    if (collisdeterministic == true || collprovider != COLLPROVIDER_ICU)
	return false;

    /* colStrength secondary, or level2, corresponds to a CI_AS collation, unless
     * colCaseLevel=yes is also specified
     */
    if(0 != strstr(lowerstr(collcollate), lowerstr("colStrength=secondary")) && /* CI_AS */
       0 == strstr(lowerstr(collcollate), lowerstr("colCaseLevel=yes"))) /* without a colCaseLevel - not CS_AI */
	return true;

    return false;
}
/*
 *                  Translation Table Initializers
 *  Load information from C arrays into hash tables
 *  Initializers are called right after shared library loading
 *  During "CREATE EXTENSION", data types are created after initialization call
 *  In this case, initializers do nothing
 *  After data types are created, initializers will be triggered again
 *  with a built-in procedure
 *
 */
Datum
init_like_ilike_table(PG_FUNCTION_ARGS)
{
    HASHCTL hashCtl;
    ht_like2ilike_entry_t *entry;
    if (TransMemoryContext == NULL)  /* initialize memory context */
    {
        TransMemoryContext =
        AllocSetContextCreateInternal(NULL,
                                    "SQL Variant Memory Context",
                                    ALLOCSET_DEFAULT_SIZES);
    }

    if (ht_like2ilike == NULL)  /* create hash table */
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
    for (int i=0; i<TOTAL_LIKE_OP_COUNT; i++)
    {
        char    *like_opname = like_ilike_table[i].like_op_name;
        char    *ilike_opname = like_ilike_table[i].ilike_op_name;
        const TypeName *typename;
        Type    tup;
        Oid     loid, roid;

        typename = makeTypeNameFromNameList(list_make2(makeString(like_ilike_table[i].op_left_schema), makeString(like_ilike_table[i].op_left_name)));
        tup = LookupTypeName(NULL, typename, NULL, true);
        if (!tup)
            continue; /* this can happen when _PG_Init is called to verify C function before creating datatype */
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
          continue; /* this can happen when _PG_Init is called to verify C function before creating datatype */
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
    PG_RETURN_INT32(0);
}


/*
 * Helper for query the hash table using operator oid
 */
like_ilike_info_t
lookup_like_ilike_table(Oid opno)
{	
	ht_like2ilike_entry_t  *hinfo;
	bool					found;

	Assert(ht_like2ilike != NULL);

	hinfo = (ht_like2ilike_entry_t *) hash_search(ht_like2ilike,
						      &opno,
						      HASH_FIND,
						      &found);
	/* return invalid oid when not found */
    if (!found)
	{
        like_ilike_info_t invalid;
		invalid.like_oid = InvalidOid;
		return invalid;
	}

	return like_ilike_table[hinfo->persist_id];
}

/* transform LIKE to ILIKE for any ci_as babelfish collation
 */
Node* pltsql_like_ilike_transformer(PlannerInfo *root,
                                    Node *expr,
                                    int kind)
{
    /*
    * Fall out quickly if expression is empty.
    */
    if (expr == NULL)
        return NULL;
    if (EXPRKIND_TARGET == kind)
    {
        /* If expr is NOT a Boolean expression then recurse through
        * its expresion tree
        */
        return expression_tree_mutator(
                expr,
                pgtsql_like_to_ilike_mutator,
                NULL);
    }
    return like2ilike_transformer(expr);
}

static Node* like2ilike_transformer(Node *expr)
{
    if(expr == NULL)
        return expr;
    if(IsA(expr, OpExpr))
    {
        /* Singleton predicate */
        return transform_likenode(expr);
    }
    else
    {
        /* Nonsingleton predicate, which could either a BoolExpr
         * with a list of predicates or a simple List of
         * predicates.
         */
        BoolExpr   *boolexpr = (BoolExpr *) expr;
        ListCell   *lc;
        List       *new_predicates = NIL;
        List       *predicates;

        if (IsA(expr, List))
        {
            predicates = (List *) expr;
        }
        else if (IsA(expr, BoolExpr))
        {
            if (boolexpr->boolop != AND_EXPR &&
                boolexpr->boolop != OR_EXPR)
                return expression_tree_mutator(
                        expr,
                        pgtsql_like_to_ilike_mutator,
                        NULL);

            predicates = boolexpr->args;
        }
        else
            return expr;

        /* Process each predicate, and recursively process
        * any nested predicate clauses of a toplevel predicate
        */
        foreach(lc, predicates)
        {
            Node *qual = (Node *) lfirst(lc);
            if (is_andclause(qual) || is_orclause(qual))
            {
                new_predicates = lappend(new_predicates,
                                    like2ilike_transformer(qual));
            }
            else if (IsA(qual, OpExpr))
            {
                new_predicates = lappend(new_predicates,
                                    transform_likenode(qual));
            }
            else
                new_predicates = lappend(new_predicates, qual);
        }

        if (IsA(expr, BoolExpr))
        {
            boolexpr->args = new_predicates;
            return expr;
        }
        else
        {
            return (Node *) new_predicates;
        }
    }
}

bool
collation_is_accent_insensitive(int collidx)
{
    if (collidx < 0 || collidx >= TOTAL_COLL_COUNT)
        return false;

    if (coll_infos[collidx].collateflags == 0x000f  || /* CI_AI  */
	coll_infos[collidx].collateflags == 0x000e)    /* CS_AI  */
        return true;

    return false;
}

/*
 * If the node is OpExpr and the colaltion is ci_as, then
 * transform the LIKE OpExpr to ILIKE OpExpr:
 *
 * Case 1: if the pattern is a constant stirng
 *         col LIKE PATTERN -> col = PATTERN
 * Case 2: if the pattern have a constant prefix
 *         col LIKE PATTERN -> 
 *              col LIKE PATTERN BETWEEN prefix AND prefix||E'\uFFFF'
 * Case 3: if the pattern doesn't have a constant prefix
 *         col LIKE PATTERN -> col ILIKE PATTERN
 */
static Node*
transform_likenode(Node* node)
{
    if (node && IsA(node, OpExpr))
    {
        OpExpr     *op = (OpExpr *) node;
        like_ilike_info_t like_entry = lookup_like_ilike_table(op->opno);
        coll_info_t coll_info_of_inputcollid = lookup_collation_table(op->inputcollid);
	
        /* check if this is LIKE expr, and collation is CI_AS */
        if (OidIsValid(like_entry.like_oid) &&
	    OidIsValid(coll_info_of_inputcollid.oid) &&
            coll_info_of_inputcollid.collateflags == 0x000d /* CI_AS  */ )
        {
            Node*       leftop = (Node *) linitial(op->args);
            Node*       rightop = (Node *) lsecond(op->args);
            Oid         ltypeId = exprType(leftop);
            Oid         rtypeId = exprType(rightop);
            char*       op_str;
            Node*       ret;
            Const*      patt;
            Const*      prefix;
            Operator    optup;
            Pattern_Prefix_Status pstatus;
	    int         collidx_of_cs_as;

            get_server_collation_oid_internal();

	    if (!OidIsValid(server_collation_oid))
	        return node;
	    
	    /* Find the CS_AS collation corresponding to the CI_AS collation
             * Change the collation of the ILIKE op to the CS_AS collation 
	     */
	    collidx_of_cs_as =
	        find_cs_as_collation(
		    find_collation(coll_info_of_inputcollid.collname));

	    /* A CS_AS collation should always exist unless a Babelfish
	     * CS_AS collation was dropped or the lookup tables were not
	     * defined in lexicographic order.  Program defensively here
	     * and just do no transformation in this case, which will
	     * generate a 'nondeterministic collation not supported' error.
	     */
	    if (NOT_FOUND == collidx_of_cs_as)
	        return node;
	    
	    /* Change the opno and oprfuncid to ILIKE */
            op->opno = like_entry.ilike_oid;
            op->opfuncid = like_entry.ilike_opfuncid;

	    op->inputcollid = coll_infos[collidx_of_cs_as].oid;

            /* no constant prefix found in pattern, or pattern is not constant */
            if (IsA(leftop, Const) || !IsA(rightop, Const) ||
                    ((Const *) rightop)->constisnull)
            {
                return node;
            }
	    
            patt = (Const *) rightop;

            /* extract pattern */
            pstatus = pattern_fixed_prefix_wrapper(patt, 1, server_collation_oid,
								   &prefix, NULL);

            /* If there is no constant prefix then there's nothing more to do */
            if (pstatus == Pattern_Prefix_None)
	    {
                return node;
	    }
	    
            /*
            * If we found an exact-match pattern, generate an "=" indexqual.
            */
            if (pstatus == Pattern_Prefix_Exact)
            {
                op_str = like_entry.is_not_match ? "<>" : "=";
                optup = compatible_oper(NULL, list_make1(makeString(op_str)), ltypeId, ltypeId,
							true, -1);
                if (optup == (Operator) NULL)
                    return node;

                ret = (Node*)(make_op_with_func(oprid(optup), BOOLOID, false,
                                    (Expr *) leftop, (Expr *) prefix,
                                    InvalidOid, server_collation_oid ,oprfuncid(optup)));

                ReleaseSysCache(optup);
                return ret;
            }
            else
            {
                Expr *greater_equal, *less_equal, *concat_expr;
                Node* constant_suffix;
                Const* highest_sort_key;
                /* construct leftop >= pattern */
                optup = compatible_oper(NULL, list_make1(makeString(">=")), ltypeId, ltypeId,
							true, -1);
                if (optup == (Operator) NULL)
                    return node;
                greater_equal = make_op_with_func(oprid(optup), BOOLOID, false,
                                    (Expr *) leftop, (Expr *) prefix,
                                    InvalidOid, server_collation_oid ,oprfuncid(optup));
                ReleaseSysCache(optup);
                /* construct pattern||E'\uFFFF' */
                highest_sort_key = makeConst(TEXTOID,-1, server_collation_oid, -1,
                                    PointerGetDatum(cstring_to_text(SORT_KEY_STR)), false, false);

                optup = compatible_oper(NULL, list_make1(makeString("||")), rtypeId, rtypeId,
							true, -1);
                if (optup == (Operator) NULL)
                    return node;
                concat_expr = make_op_with_func(oprid(optup), rtypeId, false,
                                    (Expr *) prefix, (Expr *) highest_sort_key,
                                    InvalidOid, server_collation_oid, oprfuncid(optup));
                ReleaseSysCache(optup);
                /* construct leftop < pattern */
                optup = compatible_oper(NULL, list_make1(makeString("<")), ltypeId, ltypeId,
							true, -1);
                if (optup == (Operator) NULL)
                    return node;

                less_equal = make_op_with_func(oprid(optup), BOOLOID, false,
                                    (Expr *) leftop, (Expr *) concat_expr,
                                    InvalidOid, server_collation_oid, oprfuncid(optup));
                constant_suffix = make_and_qual((Node*)greater_equal, (Node*)less_equal);
                if(like_entry.is_not_match)
                {
                    constant_suffix = (Node*)make_notclause((Expr*)constant_suffix);
                    ret = make_or_qual(node, constant_suffix);
                }
                else
                {
                    constant_suffix = make_and_qual((Node*)greater_equal, (Node*)less_equal);
                    ret = make_and_qual(node, constant_suffix);
                }
                ReleaseSysCache(optup);
                return ret;
            }
        }
    }
    return node;
}

static Node *
pgtsql_like_to_ilike_mutator(Node *node, void* context)
{
    if (NULL == node)
        return node;
    if(IsA(node, CaseExpr))
    {
        CaseExpr *caseexpr = (CaseExpr *) node;
        if (caseexpr->arg != NULL)  // CASE expression WHEN ...
        {
            like2ilike_transformer((Node*)caseexpr->arg);
        }
    }
    else if (IsA(node, CaseWhen)) //CASE WHEN expr
    {
        CaseWhen *casewhen = (CaseWhen *) node;
        like2ilike_transformer((Node*)casewhen->expr);
    }
    else if (IsA(node, TargetEntry)) //process target_entry expr
    {
        TargetEntry *targetentry = (TargetEntry *) node;
        like2ilike_transformer((Node*)targetentry->expr);
    }
    return expression_tree_mutator(node, pgtsql_like_to_ilike_mutator, NULL);
}

static Expr *
make_op_with_func(Oid opno, Oid opresulttype, bool opretset,
			  Expr *leftop, Expr *rightop,
			  Oid opcollid, Oid inputcollid, Oid oprfuncid)
{
	OpExpr  *expr = (OpExpr*)make_opclause(opno,
                                        opresulttype,
                                        opretset,
                                        leftop,
                                        rightop,
                                        opcollid,
                                        inputcollid);

	expr->opfuncid = oprfuncid;
	return (Expr *) expr;
}

/* helper fo make or qual, simialr to make_and_qual  */
static Node *
make_or_qual(Node *qual1, Node *qual2)
{
	if (qual1 == NULL)
		return qual2;
	if (qual2 == NULL)
		return qual1;
	return (Node *) make_orclause(list_make2(qual1, qual2));
}

void BabelfishPreCreateCollation_hook(
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
    
    if (NULL != prev_PreCreateCollation_hook)
    {
        (*prev_PreCreateCollation_hook)(collprovider,
					collisdeterministic,
					collencoding,
					&collcollate,
					&collctype,
					collversion);
	*pCollcollate = collcollate;
	*pCollctype = collctype;
    }
    
    if (strlen(pltsql_default_locale) > 0)
    {
        /* If the first character of the locale is '@' and if
         * a pltsql_default_locale override has been specified, then
         * prepend the pltsql_default_locale to the specified locale.
	 * Note that since the target is a const char *, we
	 * cannot modify the initial string, but we can modify
	 * the pointer to point somewhere else.
         */
        if (collcollate[0] == '@')
        {
            size_t totallen = strlen(pltsql_default_locale) + strlen(collcollate) + 1;
            char *catcollcollate = palloc0(totallen);
                
            memcpy(catcollcollate, pltsql_default_locale, strlen(pltsql_default_locale));
            strncat(catcollcollate, collcollate, totallen);
            *pCollcollate = catcollcollate;
	    }

        if (collctype[0] == '@')
	    {
            size_t totallen = strlen(pltsql_default_locale) + strlen(collctype) + 1;
            char *catcollctype = palloc0(totallen);
                
            memcpy(catcollctype, pltsql_default_locale, strlen(pltsql_default_locale));
            strncat(catcollctype, collcollate, totallen);
            *pCollctype = catcollctype;
	    }
    }
}

const char *
BabelfishTranslateCollation_hook(const char *collname, Oid collnamespace, int32 encoding)
{
    if (prev_TranslateCollation_hook)
    {
        const char *newCollname = (*prev_TranslateCollation_hook)(collname, collnamespace, encoding);

	if (newCollname)
	    return newCollname;
    }

    if (sql_dialect != SQL_DIALECT_TSQL)
        return NULL;
    
    if (pltsql_case_insensitive_identifiers && strcmp(collname, "c") == 0)
    {
        return "C";  /* Special case for "C" collation */
    }
    else
    {
        int collidx = translate_collation(collname);

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
    int collidx = find_any_collation(collname);

    if (NOT_FOUND != collidx &&
        !collation_is_accent_insensitive(collidx))
        return true;

    return false;
}

Oid get_tsql_collation_oid(int persist_coll_id)
{
	return coll_infos[persist_coll_id].oid;
}

int get_persist_collation_id(Oid coll_oid)
{
	ht_oid2collid_entry_t *entry;
	bool found_coll;

	entry = hash_search(ht_oid2collid, &coll_oid, HASH_FIND, &found_coll);

    if (found_coll)
	{
        return entry->persist_id;
	}

	coll_oid = get_server_collation_collidx();
	entry = hash_search(ht_oid2collid, &coll_oid, HASH_FIND, &found_coll);
	Assert(found_coll);
    return entry->persist_id;
}

Tsql_collation_callbacks *
get_collation_callbacks(void)
{
	if (!collation_callbacks.get_tsql_collation_oid_f)
	{
		collation_callbacks.get_tsql_collation_oid_f = &get_tsql_collation_oid;
		collation_callbacks.get_persist_collation_id_f = &get_persist_collation_id;
		collation_callbacks.get_server_collation_collidx_f = &get_server_collation_collidx;
		collation_callbacks.cmp_collation_f = &cmp_collation;
	}
	return &collation_callbacks;
}
