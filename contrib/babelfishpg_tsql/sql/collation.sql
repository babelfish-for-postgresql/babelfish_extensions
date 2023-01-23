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
LANGUAGE 'plpgsql' STABLE;
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

INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_ci_ai', N'Estonian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_ci_as', N'Estonian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_cs_as', N'Estonian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_cs_as', N'Finnish-Swedish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_ci_as', N'Finnish-Swedish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_ci_ai', N'Finnish-Swedish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'french_cs_as', N'French, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'french_ci_as', N'French, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'french_ci_ai', N'French, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_ci_ai', N'Greek, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_ci_as', N'Greek, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_cs_as', N'Greek, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_ci_ai', N'Hebrew, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_ci_as', N'Hebrew, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitives');
INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_cs_as', N'Hebrew, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_ci_ai', N'Japanese, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_ci_as', N'Japanese, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_cs_as', N'Japanese, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

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

INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_ci_ai', N'Mongolian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_ci_as', N'Mongolian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_cs_as', N'Mongolian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

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

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp874_ci_as', N'Virtual, default locale, code page 874, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp874_cs_as', N'Virtual, default locale, code page 874, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

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

