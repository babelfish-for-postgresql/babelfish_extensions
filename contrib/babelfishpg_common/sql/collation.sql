-- create babelfish collations

CREATE COLLATION IF NOT EXISTS sys.Arabic_CS_AS (provider = icu, locale = 'ar_SA');
CREATE COLLATION sys.Arabic_CI_AS (provider = icu, locale = 'ar_SA@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.Arabic_CI_AI (provider = icu, locale = 'ar_SA@colStrength=primary', deterministic = false);

CREATE COLLATION sys.BBF_Unicode_BIN2 FROM "C";

CREATE COLLATION sys.BBF_Unicode_General_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_General_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_General_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_General_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_General_Pref_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1250_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1250_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1250_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1250_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1250_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1251_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1251_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1251_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1251_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1251_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1253_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1253_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1253_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1253_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1253_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1254_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1254_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1254_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1254_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1254_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1255_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1255_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1255_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1255_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1255_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1256_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1256_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1256_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1256_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1256_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1257_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1257_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1257_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1257_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1257_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1258_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1258_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1258_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1258_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1258_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP874_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP874_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP874_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP874_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP874_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION IF NOT EXISTS sys.Chinese_PRC_CS_AS (provider = icu, locale = 'zh_CN');
CREATE COLLATION sys.Chinese_PRC_CI_AS (provider = icu, locale = 'zh_CN@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.Chinese_PRC_CI_AI (provider = icu, locale = 'zh_CN@colStrength=primary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Cyrillic_General_CS_AS (provider = icu, locale='ru_RU');
CREATE COLLATION sys.Cyrillic_General_CI_AS (provider = icu, locale='ru_RU@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.Cyrillic_General_CI_AI (provider = icu, locale='ru_RU@colStrength=primary', deterministic = false);

CREATE COLLATION sys.Estonian_CS_AS (provider = icu, locale='et_EE');
CREATE COLLATION sys.Estonian_CI_AI (provider = icu, locale='et_EE@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Estonian_CI_AS (provider = icu, locale='et_EE@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Finnish_Swedish_CS_AS (provider = icu, locale = 'sv_SE');
CREATE COLLATION sys.Finnish_Swedish_CI_AI (provider = icu, locale = 'sv_SE@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Finnish_Swedish_CI_AS (provider = icu, locale = 'sv_SE@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.French_CS_AS (provider = icu, locale = 'fr_FR');
CREATE COLLATION sys.French_CI_AI (provider = icu, locale = 'fr_FR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.French_CI_AS (provider = icu, locale = 'fr_FR@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Greek_CS_AS (provider = icu, locale = 'el_GR');
CREATE COLLATION sys.Greek_CI_AI (provider = icu, locale = 'el_GR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Greek_CI_AS (provider = icu, locale = 'el_GR@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Hebrew_CS_AS (provider = icu, locale = 'he_IL');
CREATE COLLATION sys.Hebrew_CI_AI (provider = icu, locale = 'he_IL@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Hebrew_CI_AS (provider = icu, locale = 'he_IL@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Japanese_CS_AS (provider = icu, locale = 'ja_JP');
CREATE COLLATION sys.Japanese_CI_AI (provider = icu, locale = 'ja_JP@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Japanese_CI_AS (provider = icu, locale = 'ja_JP@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Korean_Wansung_CS_AS (provider = icu, locale = 'ko_KR');
CREATE COLLATION sys.Korean_Wansung_CI_AI (provider = icu, locale = 'ko_KR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Korean_Wansung_CI_AS (provider = icu, locale = 'ko_KR@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Modern_Spanish_CS_AS (provider = icu, locale = 'en_ES');
CREATE COLLATION sys.Modern_Spanish_CI_AI (provider = icu, locale='es_ES@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Modern_Spanish_CI_AS (provider = icu, locale='es_ES@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Mongolian_CS_AS (provider = icu, locale = 'mn_MN');
CREATE COLLATION sys.Mongolian_CI_AI (provider = icu, locale = 'mn_MN@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Mongolian_CI_AS (provider = icu, locale = 'mn_MN@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Polish_CS_AS (provider = icu, locale = 'pl_PL');
CREATE COLLATION sys.Polish_CI_AI (provider = icu, locale = 'pl_PL@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Polish_CI_AS (provider = icu, locale = 'pl_PL@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Thai_CS_AS (provider = icu, locale = 'th_TH');
CREATE COLLATION sys.Thai_CI_AI (provider = icu, locale = 'th_TH@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Thai_CI_AS (provider = icu, locale = 'th_TH@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Traditional_Spanish_CS_AS (provider = icu, locale = 'es_TRADITIONAL');
CREATE COLLATION sys.Traditional_Spanish_CI_AI (provider = icu, locale = 'es_TRADITIONAL@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Traditional_Spanish_CI_AS (provider = icu, locale = 'es_TRADITIONAL@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Turkish_CS_AS (provider = icu, locale = 'tr_TR');
CREATE COLLATION sys.Turkish_CI_AI (provider = icu, locale = 'tr_TR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Turkish_CI_AS (provider = icu, locale = 'tr_TR@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Ukrainian_CS_AS (provider = icu, locale = 'uk_UA');
CREATE COLLATION sys.Ukrainian_CI_AI (provider = icu, locale = 'uk_UA@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Ukrainian_CI_AS (provider = icu, locale = 'uk_UA@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Vietnamese_CS_AS (provider = icu, locale = 'vi_VN');
CREATE COLLATION sys.Vietnamese_CI_AI (provider = icu, locale = 'vi_VN@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Vietnamese_CI_AS (provider = icu, locale = 'vi_VN@colStrength=secondary', deterministic = false);

DROP FUNCTION IF EXISTS sys.babelfishpg_common_get_babel_server_collation_oid;
CREATE OR REPLACE FUNCTION sys.babelfishpg_common_get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_common', 'get_babel_server_collation_oid';
