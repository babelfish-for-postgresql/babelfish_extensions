-- NULL
SELECT substring(NULL, 2, 1)
GO

SELECT substring(CAST(NULL AS int), 2, 1)
GO

SELECT substring(CAST(NULL AS varbinary), 2, 1)
GO

SELECT substring(CAST(NULL AS decimal), 2, 1)
GO

SELECT substring('abc', NULL, 1)
GO

SELECT substring('abc', CAST(NULL AS text), 1)
GO

SELECT substring('abc', CAST(NULL AS varchar), 1)
GO

SELECT substring('abc', CAST(NULL AS int), 1)
GO

SELECT substring('abc', 2, NULL)
GO

SELECT substring('abc', 2, CAST(NULL AS text))
GO

SELECT substring('abc', 2, CAST(NULL AS varchar))
GO

SELECT substring('abc', 2, CAST(NULL AS int))
GO

SELECT substring(NULL, 2, NULL)
GO

SELECT substring('abc', NULL, NULL)
GO

SELECT substring(NULL, NULL, 1)
GO

SELECT substring(NULL, NULL, NULL)
GO

-- Different no. of arguments
SELECT substring('abc', 1)
GO

SELECT substring('abc', 1, 1, 1)
GO

-- edge case values for second parameter
SELECT substring('AbdefGhi', 0, 1)
GO

SELECT '|' + substring('AbdefGhi', -1, 1) + '|'
GO

SELECT substring('AbdefGhi', 1, 1)
GO

SELECT substring('AbdefGhi', 8, 1)
GO

SELECT substring('AbdefGhi', 9, 1)
GO

SELECT substring('AbdefGhi', 2147483648, 1)
GO

-- edge case values for third parameter
SELECT substring('AbdefGhi', 1, 0)
GO

SELECT substring('AbdefGhi', 8, 0)
GO

SELECT substring('AbdefGhi', 1, -1)
GO

SELECT substring('AbdefGhi', 8, -1)
GO

SELECT substring('AbdefGhi', 2, 9)
GO

SELECT substring('AbdefGhi', 2, 2147483648)
GO

-- input type char
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, 15)
GO

DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 2, 15)
GO

DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 4, 2) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 0, 1) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 13, 1) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 2, -1) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 2, 15) COLLATE CHINESE_PRC_CI_AS
GO

-- input type varchar
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, 15)
GO

DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 2, 15)
GO

DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 4, 2) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 0, 1) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 13, 1) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT substring(@inputString, 2, -1) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯' 
SELECT substring(@inputString, 2, 15) COLLATE CHINESE_PRC_CI_AS
GO

-- with table column of type varchar with collation chinese_prc_ci_as
SELECT substring(a, 4, 2) FROM babel_3658_substring_chinese_prc_ci_as
GO

SELECT substring(a, 4, 2) COLLATE CHINESE_PRC_CI_AS FROM babel_3658_substring_chinese_prc_ci_as
GO

-- with table column of type varchar with collation chinese_prc_cs_as
SELECT substring(a, 4, 2) FROM babel_3658_substring_chinese_prc_cs_as
GO

SELECT substring(a, 4, 2) COLLATE CHINESE_PRC_CS_AS FROM babel_3658_substring_chinese_prc_cs_as
GO

-- with table column of type varchar with collation chinese_prc_ci_ai
SELECT substring(a, 4, 2) FROM babel_3658_substring_chinese_prc_ci_ai
GO

SELECT substring(a, 4, 2) COLLATE CHINESE_PRC_CI_AI FROM babel_3658_substring_chinese_prc_ci_ai
GO

-- with table column of type varchar with collation arabic_prc_ci_as
SELECT substring(a, 4, 2) FROM babel_3658_substring_arabic_ci_as
GO

SELECT substring(a, 4, 2) COLLATE ARABIC_CI_AS FROM babel_3658_substring_arabic_ci_as
GO

-- with table column of type varchar with collation arabic_prc_cs_as
SELECT substring(a, 4, 2) FROM babel_3658_substring_arabic_cs_as
GO

SELECT substring(a, 4, 2) COLLATE ARABIC_CS_AS FROM babel_3658_substring_arabic_cs_as
GO

-- with table column of type varchar with collation arabic_prc_ci_ai
SELECT substring(a, 4, 2) FROM babel_3658_substring_arabic_ci_ai
GO

SELECT substring(a, 4, 2) COLLATE ARABIC_CI_AI FROM babel_3658_substring_arabic_ci_ai
GO

-- input type nchar
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, 15)
GO

DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 2, 15)
GO

-- with table column of type nchar
SELECT substring(a, 4, 2) FROM babel_3658_substring_t1 
GO

-- input type nvarchar
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT substring(@inputString, 2, 15)
GO

DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT substring(@inputString, 2, 15)
GO

-- input type binary
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 2, 15)
GO

-- input type varbinary
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 4, 2)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 0, 1)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 13, 1)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 2, -1)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT substring(@inputString, 2, 15)
GO

SELECT substring(0x0a0b0c, 1,2), substring(0x0a0b0c,2,1)
GO

-- dependent objects
SELECT * FROM babel_3658_substring_dep_view
GO

EXEC babel_3658_substring_dep_proc
GO

SELECT * FROM babel_3658_substring_dep_func()
GO

SELECT * FROM babel_3658_substring_itvf_func()
GO

SELECT * FROM babel_3658_substring_dep_view_1
GO

SELECT * FROM babel_3658_substring_dep_view_2
GO

SELECT * FROM babel_3658_substring_dep_view_3
GO

SELECT * FROM babel_3658_substring_dep_view_4
GO

SELECT * FROM babel_3658_substring_dep_view_5
GO

SELECT * FROM babel_3658_substring_dep_view_6
GO

SELECT * FROM babel_3658_substring_dep_view_7
GO

SELECT * FROM babel_3658_substring_dep_view_8
GO

-- input type UDT
-- in table babel_3658_substring_UDT, col 'a' has basetype image and col 'b' has basetype varchar
SELECT substring(a, 4, 2) FROM babel_3658_substring_UDT
GO

SELECT substring(b, 4, 2) FROM babel_3658_substring_UDT
GO

-- other different datatypes, datatypes that are not implicitly coercible to varchar/nvarchar should throw error
DECLARE @inputString date = '2016-12-21';
SELECT substring(@inputString, 4, 1)
GO

DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString decimal = 123456;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString numeric = 12345.12;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString float = 12345.1;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString real = 12345.1;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString bigint = 12345678;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString int = 12345678;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString smallint = 12356;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString tinyint = 235;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString money = 12356;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString smallmoney = 12356;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString bit = 1;
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT substring(@inputString, 4, 1)
GO

SELECT substring(a, 4, 2) from babel_3658_substring_image;
GO
SELECT substring(a, 0, 1) from babel_3658_substring_image;
GO
SELECT substring(a, 13, 1) from babel_3658_substring_image;
GO
SELECT substring(a, 2, -1) from babel_3658_substring_image;
GO
SELECT substring(a, 2, 15) from babel_3658_substring_image;
GO

-- input datatype text
SELECT substring(a, 4, 2) FROM babel_3658_substring_text
GO
SELECT substring(a, 0, 1) from babel_3658_substring_text;
GO
SELECT substring(a, 13, 1) from babel_3658_substring_text;
GO
SELECT substring(a, 2, -1) from babel_3658_substring_text;
GO
SELECT substring(a, 2, 15) from babel_3658_substring_text;
GO

-- input datatype ntext
SELECT substring(b, 4, 2) FROM babel_3658_substring_text
GO
SELECT substring(b, 0, 1) from babel_3658_substring_text;
GO
SELECT substring(b, 13, 1) from babel_3658_substring_text;
GO
SELECT substring(b, 2, -1) from babel_3658_substring_text;
GO
SELECT substring(b, 2, 15) from babel_3658_substring_text;
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT substring(@inputString, 4, 1)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT substring(CAST(@inputString AS VARCHAR(50)), 4, 1)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT substring(CAST(@inputString AS VARCHAR(50)), 4, 1)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT substring(CAST(@inputString AS VARCHAR(50)), 4, 1)
GO
