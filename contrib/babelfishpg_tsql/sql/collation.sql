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

-- collation catalog
create table sys.babelfish_helpcollation(
    Name VARCHAR(128) NOT NULL,
    Description VARCHAR(1000) NOT NULL
);
GRANT SELECT ON sys.babelfish_helpcollation TO PUBLIC;

create or replace function sys.fn_helpcollations()
returns table (Name VARCHAR(128), Description VARCHAR(1000))
AS
$$
BEGIN
    return query select * from sys.babelfish_helpcollation;
END
$$
LANGUAGE 'plpgsql';
INSERT INTO sys.babelfish_helpcollation VALUES (N'arabic_cs_as', N'Arabic, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'arabic_ci_ai', N'Arabic, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'arabic_ci_as', N'Arabic, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_bin2', N'Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_ci_ai', N'Default locale, code page 1250, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_ci_as', N'Default locale, code page 1250, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_cs_ai', N'Default locale, code page 1250, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_cs_as', N'Default locale, code page 1250, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1250_cs_as', N'Default locale, code page 1250, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_ci_ai', N'Default locale, code page 1251, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_ci_as', N'Default locale, code page 1251, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_cs_ai', N'Default locale, code page 1251, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_cs_as', N'Default locale, code page 1251, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1251_cs_as', N'Default locale, code page 1251, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_ci_ai', N'Default locale, code page 1253, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_ci_as', N'Default locale, code page 1253, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_cs_ai', N'Default locale, code page 1253, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_cs_as', N'Default locale, code page 1253, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1253_cs_as', N'Default locale, code page 1253, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_ci_ai', N'Default locale, code page 1254, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_ci_as', N'Default locale, code page 1254, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_cs_ai', N'Default locale, code page 1254, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_cs_as', N'Default locale, code page 1254, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1254_cs_as', N'Default locale, code page 1254, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_ci_ai', N'Default locale, code page 1255, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_ci_as', N'Default locale, code page 1255, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_cs_ai', N'Default locale, code page 1255, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_cs_as', N'Default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1255_cs_as', N'Default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_ci_ai', N'Default locale, code page 1256, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_ci_as', N'Default locale, code page 1256, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_cs_ai', N'Default locale, code page 1256, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_cs_as', N'Default locale, code page 1256, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1256_cs_as', N'Default locale, code page 1256, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_ci_ai', N'Default locale, code page 1257, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_ci_as', N'Default locale, code page 1257, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_cs_ai', N'Default locale, code page 1257, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_cs_as', N'Default locale, code page 1257, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1257_cs_as', N'Default locale, code page 1257, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_ci_ai', N'Default locale, code page 1258, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_ci_as', N'Default locale, code page 1258, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_cs_ai', N'Default locale, code page 1258, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_cs_as', N'Default locale, code page 1258, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1258_cs_as', N'Default locale, code page 1258, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_ci_ai', N'Default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_ci_as', N'Default locale, code page 1252, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_cs_ai', N'Default locale, code page 1252, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_cs_as', N'Default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1_cs_as', N'Default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_ci_ai', N'Default locale, code page 847, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_ci_as', N'Default locale, code page 847, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_cs_ai', N'Default locale, code page 847, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_cs_as', N'Default locale, code page 847, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp847_cs_as', N'Default locale, code page 847, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_ci_ai', N'Default locale, default code page, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_ci_as', N'Default locale, default code page, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_cs_ai', N'Default locale, default code page, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_cs_as', N'Default locale, default code page, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_pref_cs_as', N'Default locale, default code page, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'chinese_prc_cs_as', N'Chinese-PRC, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'chinese_prc_ci_ai', N'Chinese-PRC, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'chinese_prc_ci_as', N'Chinese-PRC, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'cyrillic_general_cs_as', N'Cyrillic-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'cyrillic_general_ci_ai', N'Cyrillic-General, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'cyrillic_general_ci_as', N'Cyrillic-General, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_cs_as', N'Finnish-Swedish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_ci_as', N'Finnish-Swedish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_ci_ai', N'Finnish-Swedish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'french_cs_as', N'French, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'french_ci_as', N'French, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'french_ci_ai', N'French, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'korean_wansung_cs_as', N'Korean-Wansung, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'korean_wansung_ci_as', N'Korean-Wansung, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'korean_wansung_ci_ai', N'Korean-Wansung, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_90_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_100_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_140_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_ci_ai', N'Virtual, default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_ci_as', N'Virtual, default locale, code page 1252, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_cs_ai', N'Virtual, default locale, code page 1252, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_cs_as', N'Virtual, default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'modern_spanish_cs_as', N'Traditional-Spanish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'modern_spanish_ci_as', N'Traditional-Spanish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'modern_spanish_ci_ai', N'Traditional-Spanish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'polish_cs_as', N'Polish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'polish_ci_as', N'Polish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'polish_ci_ai', N'Polish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1250_ci_as', N'Virtual, default locale, code page 1250, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1250_cs_as', N'Virtual, default locale, code page 1250, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1251_ci_as', N'Virtual, default locale, code page 1251, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1251_cs_as', N'Virtual, default locale, code page 1251, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_ci_ai', N'Virtual, default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_ci_as', N'Virtual, default locale, code page 1252, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_ci_ai', N'Virtual, default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_cs_as', N'Virtual, default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_pref_cp1_cs_as', N'Virtual, default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1253_ci_as', N'Virtual, default locale, code page 1253, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1253_cs_as', N'Virtual, default locale, code page 1253, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1254_ci_as', N'Virtual, default locale, code page 1254, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1254_cs_as', N'Virtual, default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1255_ci_as', N'Virtual, default locale, code page 1255, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1255_cs_as', N'Virtual, default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1256_ci_as', N'Virtual, default locale, code page 1256, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1256_cs_as', N'Virtual, default locale, code page 1256, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1257_ci_as', N'Virtual, default locale, code page 1257, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1257_cs_as', N'Virtual, default locale, code page 1257, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1258_ci_as', N'Virtual, default locale, code page 1258, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1258_cs_as', N'Virtual, default locale, code page 1258, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'thai_cs_as', N'Thai, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'thai_ci_as', N'Thai, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'thai_ci_ai', N'Thai, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'traditional_spanish_cs_as', N'Traditional-Spanish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'traditional_spanish_ci_as', N'Traditional-Spanish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'traditional_spanish_ci_ai', N'Traditional-Spanish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'turkish_cs_as', N'Turkish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'turkish_ci_as', N'Turkish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'turkish_ci_ai', N'Turkish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'ukrainian_cs_as', N'Ukrainian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'ukrainian_ci_as', N'Ukrainian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'ukrainian_ci_ai', N'Ukrainian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'vietnamese_cs_as', N'Vietnamese, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'vietnamese_ci_as', N'Vietnamese, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'vietnamese_ci_ai', N'Vietnamese, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

DROP FUNCTION IF EXISTS sys.get_babel_server_collation_oid;
CREATE OR REPLACE FUNCTION sys.get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_tsql', 'get_server_collation_oid';

DROP PROCEDURE IF EXISTS sys.init_database_collation_oid;
CREATE OR REPLACE PROCEDURE sys.init_server_collation_oid()
AS $$
DECLARE
    server_colloid OID;
BEGIN
    server_colloid = sys.get_babel_server_collation_oid();
    perform pg_catalog.set_config('babelfishpg_tsql.server_collation_oid', server_colloid::text, false);
    execute format('ALTER DATABASE %I SET babelfishpg_tsql.server_collation_oid FROM CURRENT', current_database());
END;
$$
LANGUAGE plpgsql;

CALL sys.init_server_collation_oid();

-- Fill in the oids in coll_infos
CREATE OR REPLACE PROCEDURE sys.babel_collation_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_collid_trans_tab';
CALL sys.babel_collation_initializer();
DROP PROCEDURE sys.babel_collation_initializer;

-- Manually initialize like mapping table
CREATE OR REPLACE PROCEDURE sys.babel_like_ilike_info_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_like_ilike_table';
CALL sys.babel_like_ilike_info_initializer();
DROP PROCEDURE sys.babel_like_ilike_info_initializer;
