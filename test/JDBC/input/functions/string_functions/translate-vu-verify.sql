DECLARE @string1 nvarchar(30) = N'比尔·拉'
DECLARE @characters nvarchar(10) = N'尔', @translation nvarchar(10) = N'莫'
SELECT TRANSLATE(@string1, @characters, @translation)
GO

-- NULL
SELECT TRANSLATE(NULL, 'acs', 'scd')
GO

SELECT TRANSLATE('scd', NULL, 'scd')
GO

SELECT TRANSLATE('scd', 'scd', NULL)
GO

SELECT TRANSLATE(NULL, NULL, NULL)
GO

SELECT TRANSLATE(NULL, 'aces', 'scdwe')
GO

-- different no. of arguments
SELECT TRANSLATE('aceds', 'aces', 'scdwe', 'acsdes')
GO

SELECT TRANSLATE('aces', 'scdwe')
GO

-- input type char
DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab🙂', 'x🙂y') + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab?', 'x🙂y') + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab😎', 'x🙂y') + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @characters CHAR(10) = '比拉斯 ', @translations CHAR(10) = '比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @characters CHAR(10) = '比拉斯 ', @translations CHAR(10) = '比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- input type varchar
DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab🙂', 'x🙂y') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab?', 'x🙂y') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab😎', 'x🙂y') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @characters VARCHAR(10) = '比拉斯 ', @translations VARCHAR(10) = '比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @characters VARCHAR(10) = '比拉斯 ', @translations VARCHAR(10) = '比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @characters VARCHAR(MAX) = '比拉斯 ', @translations VARCHAR(MAX) = '比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @characters VARCHAR(MAX) = '比拉斯 ', @translations VARCHAR(MAX) = '比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- with table column of type varchar with collation chinese_prc_ci_as
SELECT '|' + TRANSLATE(a, b, c) + '|' FROM babel_4837_translate_chinese_prc_ci_as
GO

SELECT '|' + TRANSLATE(a, b, c) COLLATE CHINESE_PRC_CI_AS + '|' FROM babel_4837_translate_chinese_prc_ci_as
GO

-- with table column of type varchar with collation chinese_prc_cs_as
SELECT '|' + TRANSLATE(a, b, c) + '|' FROM babel_4837_translate_chinese_prc_cs_as
GO

SELECT '|' + TRANSLATE(a, b, c) COLLATE CHINESE_PRC_CS_AS + '|' FROM babel_4837_translate_chinese_prc_cs_as
GO

-- with table column of type varchar with collation chinese_prc_ci_ai
SELECT '|' + TRANSLATE(a, b, c) + '|' FROM babel_4837_translate_chinese_prc_ci_ai
GO

SELECT '|' + TRANSLATE(a, b, c) COLLATE CHINESE_PRC_CI_AI + '|' FROM babel_4837_translate_chinese_prc_ci_ai
GO

-- with table column of type varchar with collation arabic_prc_ci_as
SELECT '|' + TRANSLATE(a, b, c) + '|' FROM babel_4837_translate_arabic_ci_as
GO

SELECT '|' + TRANSLATE(a, b, c) COLLATE ARABIC_CI_AS + '|' FROM babel_4837_translate_arabic_ci_as
GO

-- with table column of type varchar with collation arabic_prc_cs_as
SELECT '|' + TRANSLATE(a, b, c) + '|' FROM babel_4837_translate_arabic_cs_as
GO

SELECT '|' + TRANSLATE(a, b, c) COLLATE ARABIC_CS_AS + '|' FROM babel_4837_translate_arabic_cs_as
GO

-- with table column of type varchar with collation arabic_prc_ci_ai
SELECT '|' + TRANSLATE(a, b, c) + '|' FROM babel_4837_translate_arabic_ci_ai
GO

SELECT '|' + TRANSLATE(a, b, c) COLLATE ARABIC_CI_AI + '|' FROM babel_4837_translate_arabic_ci_ai
GO

-- input type nchar
DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab🙂', 'x🙂y') + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab?', 'x🙂y') + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab😎', 'x🙂y') + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @characters NCHAR(10) = N'比拉斯 ', @translations NCHAR(10) = N'比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @characters NCHAR(10) = N'比拉斯 ', @translations NCHAR(10) = N'比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- with table column of type nchar
SELECT '|' + TRANSLATE(a, b, c) + '|' FROM babel_4837_translate_t1 
GO

-- input type nvarchar
DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab🙂', 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab?', 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRANSLATE(@inputString, 'ab😎', 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRANSLATE(@inputString, '比拉斯 ', '尔·比?') COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @characters NVARCHAR(10) = N'比拉斯 ', @translations NVARCHAR(10) = N'比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @characters NVARCHAR(10) = N'比拉斯 ', @translations NVARCHAR(10) = N'比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @characters NVARCHAR(MAX) = N'比拉斯 ', @translations NVARCHAR(MAX) = N'比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @characters NVARCHAR(MAX) = N'比拉斯 ', @translations NVARCHAR(MAX) = N'比拉斯 '
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- dependent objects
SELECT * FROM babel_4837_translate_dep_view
GO

SELECT * FROM babel_4837_translate_dep_view1
GO

EXEC babel_4837_translate_dep_proc
GO

SELECT * FROM babel_4837_translate_dep_func()
GO

SELECT * FROM babel_4837_translate_itvf_func()
GO

-- different datatypes of inputString and characters/translations
DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab🙂', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab😎', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @characters VARCHAR(20) = '比拉斯 ', @translations VARCHAR(20) = '尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab🙂', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab😎', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @characters NCHAR(20) = N'比拉斯 ', @translations NCHAR(20) = N'尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab🙂', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab😎', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @characters NVARCHAR(20) = N'比拉斯 ', @translations NVARCHAR(20) = N'尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO
 
DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations NCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations NVARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations VARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations VARCHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations CHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations CHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = N'ab?', @translations CHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = N'ab?', @translations CHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @translations VARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NVARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @translations CHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab🙂', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab😎', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @characters CHAR(20) = '比拉斯 ', @translations CHAR(20) = '尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab🙂', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab😎', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @characters NCHAR(20) = N'比拉斯 ', @translations NCHAR(20) = N'尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations)+ '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab🙂', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab😎', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @characters NVARCHAR(20) = N'比拉斯 ', @translations NVARCHAR(20) = N'尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations NCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations NVARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations VARCHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations CHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations VARCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations VARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations VARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NVARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations CHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab🙂', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab😎', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @characters CHAR(20) = '比拉斯 ', @translations CHAR(20) = '尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab🙂', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab😎', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @characters VARCHAR(20) = '比拉斯 ', @translations VARCHAR(20) = '尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab🙂', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab😎', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @characters NVARCHAR(20) = N'比拉斯 ', @translations NVARCHAR(20) = N'尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations NCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations NVARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations NVARCHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations CHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations VARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations VARCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations VARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations VARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NVARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations CHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab🙂', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab😎', @translations CHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @characters CHAR(20) = '比拉斯 ', @translations CHAR(20) = '尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab?', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab🙂', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = 'ab😎', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @characters VARCHAR(20) = '比拉斯 ', @translations VARCHAR(20) = '尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab🙂', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab😎', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @characters NCHAR(20) = N'比拉斯 ', @translations NCHAR(20) = N'尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations VARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations NCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations NVARCHAR(20) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations CHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(20) = 'ab?', @translations VARCHAR(40) = 'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations VARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(20) = N'ab?', @translations CHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations CHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NVARCHAR(20) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations VARCHAR(40) = N'x🙂y'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations VARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(20) = N'ab?', @translations NVARCHAR(40) = N'x🙂yw'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations VARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NVARCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations CHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @translations NCHAR(40) = 'x🙂y'
SELECT '|' + TRANSLATE(@inputString, 'ab?', @translations) + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters VARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NVARCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters CHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = '  abc🙂defghi🙂🙂    ', @characters NCHAR(40) = 'ab?'
SELECT '|' + TRANSLATE(@inputString, @characters, 'x🙂y') + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  ABCDEF    ', @characters BINARY(4) = 0x414243, @translations NCHAR(20) = N'尔·比?'
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

DECLARE @inputString VARBINARY(50) = 0x41424344, @characters NCHAR(20) = N'尔·比?', @translations VARBINARY(2) = 0x4144
SELECT '|' + TRANSLATE(@inputString, @characters, @translations) + '|'
GO

-- input type UDT
-- in table babel_4837_translate_UDT, col 'a' has basetype image and col 'b' and 'c' have basetype varchar
SELECT TRANSLATE(a, b, c) FROM babel_4837_translate_UDT
GO

SELECT TRANSLATE(b, b, c) FROM babel_4837_translate_UDT
GO

-- other different datatypes, all of these should be blocked
DECLARE @inputString date = '2016-12-21'
SELECT TRANSLATE(@inputString, '12', '06');
GO

DECLARE @inputString date = '2016-12-21', @characters VARCHAR(10) = '12', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @characters date = '2016-12-21', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @characters VARCHAR(20) = '2016-12-21', @translations date = '2016-12-21';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString date = '2016-12-21'
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @date date = '12-21-16';
DECLARE @inputString datetime = @date, @characters VARCHAR(10) = '12', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @date date = '12-21-16';
DECLARE @inputString datetime = @date;
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @date date = '2016-12-21', @translations VARCHAR(10) = '06';
DECLARE @characters datetime = @date;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @characters VARCHAR(20) = '2016-12-21', @date date = '2016-12-21';
DECLARE @translations datetime = @date;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10', @characters VARCHAR(10) = '12', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(30) = '2016-12-21 12:43:10', @characters smalldatetime = '2016-12-21 12:43:10', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(30) = '2016-12-21 12:43:10', @characters VARCHAR(30) = '2016-12-21 12:43:10', @translations smalldatetime = '2016-12-21 12:43:10';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString time(4) = '12:10:05.1237', @characters VARCHAR(10) = '12', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(30) = '12:10:05.1237', @characters time(4) = '12:10:05.1237', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(30) = '12:10:05.1237', @characters VARCHAR(30) = '12:10:05.1237', @translations time(4) = '12:10:05.1237';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0', @characters VARCHAR(10) = '12', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1234 +10:0', @characters datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1234 +10:0', @characters VARCHAR(50) = '1968-10-23 12:45:37.1234 +10:0', @translations datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237', @characters VARCHAR(10) = '12', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1237', @characters datetime2(4) = '1968-10-23 12:45:37.1237', @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1237', @characters VARCHAR(50) = '1968-10-23 12:45:37.1237', @translations datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString decimal = 123456, @characters decimal = 12, @translations decimal = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters decimal = 12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations decimal = 12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString numeric = 12345.12, @characters numeric = 12, @translations numeric = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters numeric = 12.12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations numeric = 12.12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString float = 12345.1, @characters float = 12, @translations float = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters float = 12.1, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations float = 12.1;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString real = 12345.1, @characters real = 12, @translations real = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters real = 12.1, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations real = 12.1;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString bigint = 12345678, @characters bigint = 12, @translations bigint = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters bigint = 12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations bigint = 12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString int = 12345678, @characters int = 12, @translations int = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters int = 12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations int = 12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString smallint = 12356, @characters smallint = 12, @translations smallint = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters smallint = 12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations smallint = 12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString tinyint = 235, @characters tinyint = 12, @translations tinyint = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters tinyint = 12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations tinyint = 12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString money = 12356, @characters money = 12, @translations money = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters money = 12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations money = 12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString smallmoney = 12356, @characters smallmoney = 12, @translations smallmoney = 06;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters smallmoney = 12, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations smallmoney = 12;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString bit = 1, @characters bit = 1, @translations bit = 0;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters bit = 1, @translations VARCHAR(10) = '06';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '1234', @translations bit = 0;
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER)
DECLARE @characters VARCHAR(10) = '6F', @translations VARCHAR(10) = '5A';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER), @translations VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @translations UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER);
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER)
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

SELECT TRANSLATE(a, a, a) FROM babel_4837_translate_image;
GO

SELECT TRANSLATE('a', a, 'a') FROM babel_4837_translate_image;
GO

SELECT TRANSLATE('a', 'a', a) FROM babel_4837_translate_image;
GO

DECLARE @characters VARCHAR(10) = '6F', @translations VARCHAR(10) = '5A';
SELECT TRANSLATE(a, @characters, @translations) from babel_4837_translate_image;
GO

SELECT TRANSLATE(a, b, c) FROM babel_4837_translate_text
GO
SELECT TRANSLATE('qw', a, 'cd') FROM babel_4837_translate_text
GO
SELECT TRANSLATE('qw', 'ab', a) FROM babel_4837_translate_text
GO
SELECT TRANSLATE(b, a, c) FROM babel_4837_translate_text
GO
SELECT TRANSLATE('qw', c, 'cd') FROM babel_4837_translate_text
GO
SELECT TRANSLATE('qw', 'ab', b) FROM babel_4837_translate_text
GO

DECLARE @characters VARCHAR(20) = 'ab?', @translations VARCHAR(10) = 'x?y';
SELECT TRANSLATE(a, @characters, @translations) FROM babel_4837_translate_text
GO

DECLARE @characters VARCHAR(20) = 'ab?', @translations VARCHAR(10) = 'x?y';
SELECT TRANSLATE(b, @characters, @translations) FROM babel_4837_translate_text
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @characters VARCHAR(10) = '6F', @translations VARCHAR(10) = '5A';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant), @translations VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @translations sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant);
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
DECLARE @characters xml = CAST ('<fruit/>' AS xml), @translations xml = CAST ('<vegetables/>' AS xml);
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters xml = CAST ('<body><fruit/></body>' AS xml), @translations VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @translations xml = CAST ('<body><fruit/></body>' AS xml);
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0), @characters VARCHAR(10) = '(1 2)', @translations VARCHAR(10) = '(4 5)';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters geometry = geometry::STGeomFromText('POINT (1 2)', 0), @translations VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @translations geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326), @characters VARCHAR(10) = '(1 2)', @translations VARCHAR(10) = '(4 5)';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters geography = geography::STGeomFromText('POINT (1 2)', 4326), @translations VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString VARCHAR(50) = '1234', @characters VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @translations geography = geography::STGeomFromText('POINT (1 2)', 4326);
SELECT TRANSLATE(@inputString, @characters, @translations)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT TRANSLATE(@inputString, @inputString, @inputString)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @characters VARCHAR(10) = '6F', @translations VARCHAR(10) = '5A';
SELECT TRANSLATE(CAST (@inputString AS VARCHAR(50)), @characters, @translations)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
DECLARE @characters xml = CAST ('<fruit/>' AS xml), @translations xml = CAST ('<veget/>' AS xml);
SELECT TRANSLATE(CAST (@inputString AS VARCHAR(50)), CAST (@characters AS VARCHAR(50)), CAST (@translations AS VARCHAR(50)))
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0), @characters VARCHAR(10) = '(1 2)', @translations VARCHAR(10) = '(4 5)';
SELECT TRANSLATE(CAST (@inputString AS VARCHAR(50)), @characters, @translations)
GO
