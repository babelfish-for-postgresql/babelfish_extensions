-- NULL
SELECT replicate(NULL, -2)
GO

SELECT replicate(NULL, 0)
GO

SELECT replicate(NULL, 2)
GO

SELECT replicate('abc', NULL)
GO

SELECT replicate(NULL, NULL)
GO

-- edge case values for second parameter
SELECT replicate('AbdefGhi', -2)
GO

SELECT '|' + replicate('AbdefGhi', 0) + '|'
GO

SELECT replicate('AbdefGhi', 2)
GO

SELECT replicate('AbdefGhi', 1001)
GO

-- input type char
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT replicate(@inputString, 4) COLLATE CHINESE_PRC_CI_AS
GO

-- input type varchar
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT replicate(@inputString, 4) COLLATE CHINESE_PRC_CI_AS
GO

-- with table column of type varchar with collation chinese_prc_ci_as
SELECT replicate(a, 4) FROM babel_862_replicate_chinese_prc_ci_as
GO

SELECT replicate(a, 4) COLLATE CHINESE_PRC_CI_AS FROM babel_862_replicate_chinese_prc_ci_as
GO

-- with table column of type varchar with collation chinese_prc_cs_as
SELECT replicate(a, 4) FROM babel_862_replicate_chinese_prc_cs_as
GO

SELECT replicate(a, 4) COLLATE CHINESE_PRC_CS_AS FROM babel_862_replicate_chinese_prc_cs_as
GO

-- with table column of type varchar with collation chinese_prc_ci_ai
SELECT replicate(a, 4) FROM babel_862_replicate_chinese_prc_ci_ai
GO

SELECT replicate(a, 4) COLLATE CHINESE_PRC_CI_AI FROM babel_862_replicate_chinese_prc_ci_ai
GO

-- with table column of type varchar with collation arabic_prc_ci_as
SELECT replicate(a, 4) FROM babel_862_replicate_arabic_ci_as
GO

SELECT replicate(a, 4) COLLATE ARABIC_CI_AS FROM babel_862_replicate_arabic_ci_as
GO

-- with table column of type varchar with collation arabic_prc_cs_as
SELECT replicate(a, 4) FROM babel_862_replicate_arabic_cs_as
GO

SELECT replicate(a, 4) COLLATE ARABIC_CS_AS FROM babel_862_replicate_arabic_cs_as
GO

-- with table column of type varchar with collation arabic_prc_ci_ai
SELECT replicate(a, 4) FROM babel_862_replicate_arabic_ci_ai
GO

SELECT replicate(a, 4) COLLATE ARABIC_CI_AI FROM babel_862_replicate_arabic_ci_ai
GO

-- input type nchar
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT replicate(@inputString, 4)
GO

-- with table column of type nchar
SELECT replicate(a, 4) FROM babel_862_replicate_t1 
GO

-- input type nvarchar
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT replicate(@inputString, 4)
GO

-- input type binary
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT replicate(@inputString, 4)
GO

-- input type varbinary
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT replicate(@inputString, 4)
GO

-- dependent objects
SELECT * FROM babel_862_replicate_dep_view
GO

EXEC babel_862_replicate_dep_proc
GO

SELECT * FROM babel_862_replicate_dep_func()
GO

SELECT * FROM babel_862_replicate_itvf_func()
GO

SELECT * FROM babel_862_replicate_dep_view_1
GO

SELECT * FROM babel_862_replicate_dep_view_2
GO

SELECT * FROM babel_862_replicate_dep_view_3
GO

SELECT * FROM babel_862_replicate_dep_view_4
GO

SELECT * FROM babel_862_replicate_dep_view_5
GO

SELECT * FROM babel_862_replicate_dep_view_6
GO

SELECT * FROM babel_862_replicate_dep_view_7
GO

-- input type UDT
-- -- in table babel_862_replicate_UDT, col 'a' has basetype image and col 'b' has basetype varchar
SELECT replicate(a, 4) FROM babel_862_replicate_UDT
GO

SELECT replicate(b, 4) FROM babel_862_replicate_UDT
GO

-- other different datatypes, datatypes that are not implicitly coercible to varchar/nvarchar should throw error
DECLARE @inputString date = '2016-12-21';
SELECT replicate(@inputString, 4)
GO

DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString decimal = 123456;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString numeric = 12345.12;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString float = 12345.1;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString real = 12345.1;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString bigint = 12345678;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString int = 12345678;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString smallint = 12356;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString tinyint = 235;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString money = 12356;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString smallmoney = 12356;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString bit = 1;
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT replicate(@inputString, 4)
GO

SELECT replicate(a, 4) from babel_862_replicate_image;
GO

-- input datatype text
SELECT replicate(a, 4) FROM babel_862_replicate_text
GO

-- input datatype ntext
SELECT replicate(b, 4) FROM babel_862_replicate_text
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT replicate(@inputString, 4)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT replicate(CAST(@inputString AS VARCHAR(50)), 4)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT replicate(CAST(@inputString AS VARCHAR(50)), 4)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT replicate(CAST(@inputString AS VARCHAR(50)), 4)
GO
