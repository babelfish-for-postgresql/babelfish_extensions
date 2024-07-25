-- customer case, mentioned in the jira description
DECLARE @custname NVARCHAR(50) = N'比尔·拉莫斯'
SELECT @custname, 
    TRIM(@custname) as [TRIM]
    , LTRIM(@custname) as [LTRIM]
    , RTRIM(@custname) as [RTRIM]
    , LEFT(@custname, 4) as [LEFT4]
    , RIGHT(@custname, 4) as [RIGHT4]
    , SUBSTRING(@custname, 2, 4) as [SUBSTRING_2_4]
;
GO

-- NULL
SELECT TRIM(NULL)
GO

SELECT TRIM(NULL FROM NULL)
GO

SELECT TRIM('' FROM NULL)
GO

SELECT TRIM(NULL FROM '')
GO

-- input type char
DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM(@inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab? ' FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab🙂 ' FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab😎 ' FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM('比拉斯 ' FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM('比拉斯 ' FROM @inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @charSet CHAR(10) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @charSet CHAR(10) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- input type varchar
DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM(@inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab? ' FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab🙂 ' FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab😎 ' FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM('比拉斯 ' FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM('比拉斯 ' FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + TRIM('比拉斯 ' FROM @inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @charSet VARCHAR(10) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @charSet VARCHAR(10) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @charSet VARCHAR(MAX) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @charSet VARCHAR(MAX) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- with table column of type varchar with collation chinese_prc_ci_as
SELECT '|' + TRIM(b FROM a) + '|' FROM babel_4489_trim_chinese_prc_ci_as
GO

SELECT '|' + TRIM(b FROM a) COLLATE CHINESE_PRC_CI_AS + '|' FROM babel_4489_trim_chinese_prc_ci_as
GO

-- with table column of type varchar with collation chinese_prc_cs_as
SELECT '|' + TRIM(b FROM a) + '|' FROM babel_4489_trim_chinese_prc_cs_as
GO

SELECT '|' + TRIM(b FROM a) COLLATE CHINESE_PRC_CS_AS + '|' FROM babel_4489_trim_chinese_prc_cs_as
GO

-- with table column of type varchar with collation chinese_prc_ci_ai
SELECT '|' + TRIM(b FROM a) + '|' FROM babel_4489_trim_chinese_prc_ci_ai
GO

SELECT '|' + TRIM(b FROM a) COLLATE CHINESE_PRC_CI_AI + '|' FROM babel_4489_trim_chinese_prc_ci_ai
GO

-- with table column of type varchar with collation arabic_prc_ci_as
SELECT '|' + TRIM(b FROM a) + '|' FROM babel_4489_trim_arabic_ci_as
GO

SELECT '|' + TRIM(b FROM a) COLLATE ARABIC_CI_AS + '|' FROM babel_4489_trim_arabic_ci_as
GO

-- with table column of type varchar with collation arabic_prc_cs_as
SELECT '|' + TRIM(b FROM a) + '|' FROM babel_4489_trim_arabic_cs_as
GO

SELECT '|' + TRIM(b FROM a) COLLATE ARABIC_CS_AS + '|' FROM babel_4489_trim_arabic_cs_as
GO

-- with table column of type varchar with collation arabic_prc_ci_ai
SELECT '|' + TRIM(b FROM a) + '|' FROM babel_4489_trim_arabic_ci_ai
GO

SELECT '|' + TRIM(b FROM a) COLLATE ARABIC_CI_AI + '|' FROM babel_4489_trim_arabic_ci_ai
GO

-- input type nchar
DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  ab😎c🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab🙂😎 ' FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRIM('比拉斯 ' FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @charSet NCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

-- with table column of type nchar
SELECT '|' + TRIM(b FROM a) + '|' FROM babel_4489_trim_t1 
GO

-- input type nvarchar
DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRIM(@inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  ab😎c🙂defghi🙂🙂    '
SELECT '|' + TRIM('ab🙂😎 ' FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + TRIM('比拉斯 ' FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @charSet NVARCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO
DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @charSet NVARCHAR(MAX) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

-- dependent objects
SELECT * FROM babel_4489_trim_dep_view
GO

EXEC babel_4489_trim_dep_proc
GO

SELECT * FROM babel_4489_trim_dep_func()
GO

SELECT * FROM babel_4489_trim_itvf_func()
GO

SELECT * FROM babel_4489_trim_dep_view_1
GO

SELECT * FROM babel_4489_trim_dep_view_2
GO

SELECT * FROM babel_4489_trim_dep_view_3
GO

SELECT * FROM babel_4489_trim_dep_view_4
GO

SELECT * FROM babel_4489_trim_dep_view_5
GO

SELECT * FROM babel_4489_trim_dep_view_6
GO

-- different datatypes of inputString and charSet
DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @charSet VARCHAR(20) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @charSet NCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    ', @charSet NVARCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @charSet CHAR(20) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @charSet NCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    ', @charSet NVARCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @charSet CHAR(20) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @charSet VARCHAR(20) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet NVARCHAR(20) = N'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    ', @charSet NVARCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet CHAR(20) = 'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @charSet CHAR(20) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab? '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet VARCHAR(20) = 'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @charSet VARCHAR(20) = '比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab🙂 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    ', @charSet NCHAR(20) = N'ab😎 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    ', @charSet NCHAR(20) = N'比拉斯 '
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  ABCDEF    ', @charSet BINARY(4) = 0x414243
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

DECLARE @inputString VARBINARY(50) = 0x41424344, @charSet VARBINARY(2) = 0x4144
SELECT '|' + TRIM(@charSet FROM @inputString) + '|'
GO

-- input type UDT
-- -- in table babel_4489_trim_UDT, col 'a' has basetype image and col 'b' has basetype varchar
SELECT TRIM(a) FROM babel_4489_trim_UDT
GO

SELECT TRIM(b) FROM babel_4489_trim_UDT
GO

DECLARE @charSet VARCHAR(10) = 'ab'
SELECT TRIM(@charSet FROM a) FROM babel_4489_trim_UDT
GO

DECLARE @charSet VARCHAR(10) = 'ab'
SELECT TRIM(@charSet FROM b) FROM babel_4489_trim_UDT
GO

-- other different datatypes, all of these should be blocked
DECLARE @inputString date = '2016-12-21'
SELECT TRIM('12' FROM @inputString)
GO

DECLARE @inputString date = '2016-12-21', @charSet VARCHAR(10) = '12';
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString date = '2016-12-21'
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date, @charSet VARCHAR(10) = '12';
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10', @charSet VARCHAR(10) = '12';
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString time(4) = '12:10:05.1237', @charSet VARCHAR(10) = '10';
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0', @charSet VARCHAR(10) = '23';
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237', @charSet VARCHAR(10) = '23';
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString decimal = 123456, @charSet decimal = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString numeric = 12345.12, @charSet numeric = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString float = 12345.1, @charSet float = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString real = 12345.1, @charSet real = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString bigint = 12345678, @charSet bigint = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString int = 12345678, @charSet int = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString smallint = 12356, @charSet smallint = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString tinyint = 235, @charSet tinyint = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString money = 12356, @charSet money = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString smallmoney = 12356, @charSet smallmoney = 12;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString bit = 1, @charSet bit = 1;
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER)
DECLARE @charSet VARCHAR(10) = '6F';
SELECT TRIM(@charSet FROM @inputString)
GO
DECLARE @inputString UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER)
DECLARE @charSet VARCHAR(10) = '6F';
SELECT TRIM(@inputString FROM @inputString)
GO

SELECT TRIM(a FROM a) FROM babel_4489_trim_image;
GO

DECLARE @charSet VARCHAR(10) = '6F';
SELECT TRIM(@charSet FROM a) from babel_4489_trim_image;
GO

SELECT TRIM(a FROM b) FROM babel_4489_trim_text
GO
SELECT TRIM(b FROM a) FROM babel_4489_trim_text
GO

DECLARE @charSet VARCHAR(20) = 'ab? '
SELECT TRIM(@charSet FROM a) FROM babel_4489_trim_text
GO

DECLARE @charSet VARCHAR(20) = 'ab? '
SELECT TRIM(@charSet FROM b) FROM babel_4489_trim_text
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @charSet VARCHAR(10) = '6F';
SELECT TRIM(@charSet FROM @inputString)
GO
DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @charSet VARCHAR(10) = '6F';
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
DECLARE @charSet xml = CAST ('<fruit/>' AS xml);
SELECT TRIM(@charSet FROM @inputString)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0), @charSet VARCHAR(10) = '(1 2)';
SELECT TRIM(@charSet FROM @inputString)
GO
DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0), @charSet VARCHAR(10) = '(1 2)';
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326), @charSet VARCHAR(10) = '2';
SELECT TRIM(@charSet FROM @inputString)
GO
DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326), @charSet VARCHAR(10) = '2';
SELECT TRIM(@inputString FROM @inputString)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @charSet VARCHAR(10) = '6F';
SELECT TRIM(@charSet FROM CAST(@inputString AS VARCHAR(50)))
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
DECLARE @charSet xml = CAST ('<fruit/>' AS xml);
SELECT TRIM(CAST(@charSet AS VARCHAR) FROM CAST(@inputString AS VARCHAR(50)))
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0), @charSet VARCHAR(10) = '(1 2)';
SELECT TRIM(@charSet FROM CAST(@inputString AS VARCHAR(50)))
GO
