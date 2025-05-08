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
SELECT LTRIM(NULL)
GO

-- input type char
DECLARE @inputString CHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

DECLARE @inputString CHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + LTRIM(@inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- input type varchar
DECLARE @inputString VARCHAR(50) = '  abc🙂defghi🙂🙂    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

DECLARE @inputString VARCHAR(50) = '  比尔·拉莫斯    '
SELECT '|' + LTRIM(@inputString) COLLATE CHINESE_PRC_CI_AS + '|'
GO

-- with table column of type varchar with collation chinese_prc_ci_as
SELECT '|' + LTRIM(a) + '|' FROM babel_4489_ltrim_chinese_prc_ci_as
GO

SELECT '|' + LTRIM(a) COLLATE CHINESE_PRC_CI_AS + '|' FROM babel_4489_ltrim_chinese_prc_ci_as
GO

-- with table column of type varchar with collation chinese_prc_cs_as
SELECT '|' + LTRIM(a) + '|' FROM babel_4489_ltrim_chinese_prc_cs_as
GO

SELECT '|' + LTRIM(a) COLLATE CHINESE_PRC_CS_AS + '|' FROM babel_4489_ltrim_chinese_prc_cs_as
GO

-- with table column of type varchar with collation chinese_prc_ci_ai
SELECT '|' + LTRIM(a) + '|' FROM babel_4489_ltrim_chinese_prc_ci_ai
GO

SELECT '|' + LTRIM(a) COLLATE CHINESE_PRC_CI_AI + '|' FROM babel_4489_ltrim_chinese_prc_ci_ai
GO

-- with table column of type varchar with collation arabic_prc_ci_as
SELECT '|' + LTRIM(a) + '|' FROM babel_4489_ltrim_arabic_ci_as
GO

SELECT '|' + LTRIM(a) COLLATE ARABIC_CI_AS + '|' FROM babel_4489_ltrim_arabic_ci_as
GO

-- with table column of type varchar with collation arabic_prc_cs_as
SELECT '|' + LTRIM(a) + '|' FROM babel_4489_ltrim_arabic_cs_as
GO

SELECT '|' + LTRIM(a) COLLATE ARABIC_CS_AS + '|' FROM babel_4489_ltrim_arabic_cs_as
GO

-- with table column of type varchar with collation arabic_prc_ci_ai
SELECT '|' + LTRIM(a) + '|' FROM babel_4489_ltrim_arabic_ci_ai
GO

SELECT '|' + LTRIM(a) COLLATE ARABIC_CI_AI + '|' FROM babel_4489_ltrim_arabic_ci_ai
GO

-- input type nchar
DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

DECLARE @inputString NCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

-- with table column of type nchar
SELECT '|' + LTRIM(a) + '|' FROM babel_4489_ltrim_t1 
GO

-- input type nvarchar
DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

DECLARE @inputString NVARCHAR(50) = N'  比尔·拉莫斯    '
SELECT '|' + LTRIM(@inputString) + '|'
GO

-- input type binary
DECLARE @inputString BINARY(10) = 0x202061626364656667682020
SELECT '|' + LTRIM(@inputString) + '|'
GO

-- input type varbinary
DECLARE @inputString VARBINARY(10) = 0x202061626364656667682020
SELECT '|' + LTRIM(@inputString) + '|'
GO

-- dependent objects
SELECT * FROM babel_4489_ltrim_dep_view
GO

EXEC babel_4489_ltrim_dep_proc
GO

SELECT * FROM babel_4489_ltrim_dep_func()
GO

SELECT * FROM babel_4489_ltrim_itvf_func()
GO

SELECT * FROM babel_4489_ltrim_dep_view_1
GO

SELECT * FROM babel_4489_ltrim_dep_view_2
GO

SELECT * FROM babel_4489_ltrim_dep_view_3
GO

SELECT * FROM babel_4489_ltrim_dep_view_4
GO

SELECT * FROM babel_4489_ltrim_dep_view_5
GO

SELECT * FROM babel_4489_ltrim_dep_view_6
GO

SELECT * FROM babel_4489_ltrim_dep_view_7
GO

-- input type UDT
-- -- in table babel_4489_ltrim_UDT, col 'a' has basetype image and col 'b' has basetype varchar
SELECT LTRIM(a) FROM babel_4489_ltrim_UDT
GO

SELECT LTRIM(b) FROM babel_4489_ltrim_UDT
GO

-- other different datatypes, datatypes that are not implicitly coercible to varchar/nvarchar should throw error
DECLARE @inputString date = '2016-12-21';
SELECT LTRIM(@inputString)
GO

DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT LTRIM(@inputString)
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT LTRIM(@inputString)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT LTRIM(@inputString)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT LTRIM(@inputString)
GO

DECLARE @inputString decimal = 123456;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString numeric = 12345.12;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString float = 12345.1;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString real = 12345.1;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString bigint = 12345678;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString int = 12345678;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString smallint = 12356;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString tinyint = 235;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString money = 12356;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString smallmoney = 12356;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString bit = 1;
SELECT LTRIM(@inputString)
GO

DECLARE @inputString uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT LTRIM(@inputString)
GO

SELECT LTRIM(a) from babel_4489_ltrim_image;
GO

-- input datatype text
SELECT LTRIM(a) FROM babel_4489_ltrim_text
GO

-- input datatype ntext
SELECT LTRIM(b) FROM babel_4489_ltrim_text
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT LTRIM(@inputString)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT LTRIM(@inputString)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT LTRIM(@inputString)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT LTRIM(@inputString)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT LTRIM(CAST(@inputString AS VARCHAR(50)))
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT LTRIM(CAST(@inputString AS VARCHAR(50)))
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT LTRIM(CAST(@inputString AS VARCHAR(50)))
GO
