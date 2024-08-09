-- NULL
SELECT stuff(NULL, 2, 1, 'ab')
GO
SELECT stuff('ab', 2, 1, NULL)
GO
SELECT stuff('ab', NULL, 1, 'bc')
GO
SELECT stuff('ab', 2, NULL, 'bc')
GO
SELECT stuff('ab', NULL, '1', 'bc')
GO
SELECT stuff('ab', '2', NULL, 'bc')
GO
SELECT stuff('ab', NULL, NULL, 'bc')
GO

-- Different no. of arguments
SELECT stuff('abc', 1, 2)
GO

SELECT stuff('abc', 1, 1, 'xy', 1)
GO

-- edge case values for second parameter
SELECT stuff('AbdefGhi', 0, 1, 'xy')
GO

SELECT '|' + stuff('AbdefGhi', -1, 1, 'xy') + '|'
GO

SELECT stuff('AbdefGhi', 1, 1, 'xy')
GO

SELECT stuff('AbdefGhi', 8, 1, 'xy')
GO

SELECT stuff('AbdefGhi', 9, 1, 'xy')
GO

SELECT stuff('AbdefGhi', 2147483648, 1, 'xy')
GO

-- edge case values for third parameter
SELECT stuff('AbdefGhi', 1, 0, 'xy')
GO

SELECT stuff('AbdefGhi', 8, 0, 'xy')
GO

SELECT stuff('AbdefGhi', 1, -1, 'xy')
GO

SELECT stuff('AbdefGhi', 8, -1, 'xy')
GO

SELECT stuff('AbdefGhi', 2, 9, 'xy')
GO

SELECT stuff('AbdefGhi', 2, 2147483648, 'xy')
GO

-- input type char
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString CHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString NCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString NVARCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString VARCHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 4, 2, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 0, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 26, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, -1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString CHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, 25, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比')
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比')
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比')
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比')
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比')
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString CHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO

-- input type varchar
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString CHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString NCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString NVARCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString VARCHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 4, 2, 'xyz🙂🙂wuytgdy🙂')
GO
SELECT stuff('abc🙂defghi🙂🙂', 4, 2, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 0, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 26, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, -1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString VARCHAR(25) = 'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, 25, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比')
GO
SELECT stuff('比尔·拉莫斯', 4, 2, '拉·比')
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比')
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比')
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比')
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比')
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
SELECT stuff('比尔·拉莫斯', 4, 2, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARCHAR(25) = '比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO

-- with table column of type varchar with collation chinese_prc_ci_as
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_chinese_prc_ci_as
GO
SELECT stuff(a, 4, 2, '拉·比') FROM babel_4838_stuff_chinese_prc_ci_as
GO

SELECT stuff(a, 4, 2, a) COLLATE CHINESE_PRC_CI_AS FROM babel_4838_stuff_chinese_prc_ci_as
GO
SELECT stuff(a, 4, 2, '拉·比') COLLATE CHINESE_PRC_CI_AS FROM babel_4838_stuff_chinese_prc_ci_as
GO

-- with table column of type varchar with collation chinese_prc_cs_as
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_chinese_prc_cs_as
GO
SELECT stuff(a, 4, 2, '拉·比') FROM babel_4838_stuff_chinese_prc_cs_as
GO

SELECT stuff(a, 4, 2, a) COLLATE CHINESE_PRC_CS_AS FROM babel_4838_stuff_chinese_prc_cs_as
GO
SELECT stuff(a, 4, 2, '拉·比') COLLATE CHINESE_PRC_CS_AS FROM babel_4838_stuff_chinese_prc_cs_as
GO

-- with table column of type varchar with collation chinese_prc_ci_ai
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_chinese_prc_ci_ai
GO
SELECT stuff(a, 4, 2, '拉·比') FROM babel_4838_stuff_chinese_prc_ci_ai
GO

SELECT stuff(a, 4, 2, a) COLLATE CHINESE_PRC_CI_AI FROM babel_4838_stuff_chinese_prc_ci_ai
GO
SELECT stuff(a, 4, 2, '拉·比') COLLATE CHINESE_PRC_CI_AI FROM babel_4838_stuff_chinese_prc_ci_ai
GO

-- with table column of type varchar with collation arabic_prc_ci_as
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_arabic_ci_as
GO
SELECT stuff(a, 4, 2, 'معقيال') FROM babel_4838_stuff_arabic_ci_as
GO

SELECT stuff(a, 4, 2, a) COLLATE ARABIC_CI_AS FROM babel_4838_stuff_arabic_ci_as
GO
SELECT stuff(a, 4, 2, 'معقيال') COLLATE ARABIC_CI_AS FROM babel_4838_stuff_arabic_ci_as
GO

-- with table column of type varchar with collation arabic_prc_cs_as
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_arabic_cs_as
GO
SELECT stuff(a, 4, 2, 'معقيال') FROM babel_4838_stuff_arabic_cs_as
GO

SELECT stuff(a, 4, 2, a) COLLATE ARABIC_CS_AS FROM babel_4838_stuff_arabic_cs_as
GO
SELECT stuff(a, 4, 2, 'معقيال') COLLATE ARABIC_CS_AS FROM babel_4838_stuff_arabic_cs_as
GO

-- with table column of type varchar with collation arabic_prc_ci_ai
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_arabic_ci_ai
GO
SELECT stuff(a, 4, 2, 'معقيال') FROM babel_4838_stuff_arabic_ci_ai
GO

SELECT stuff(a, 4, 2, a) COLLATE ARABIC_CI_AI FROM babel_4838_stuff_arabic_ci_ai
GO
SELECT stuff(a, 4, 2, 'معقيال') COLLATE ARABIC_CI_AI FROM babel_4838_stuff_arabic_ci_ai
GO

-- input type nchar
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString CHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString NCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString NVARCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString VARCHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 4, 2, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 0, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 26, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, -1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, 25, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比')
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比')
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比')
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比')
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比')
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO

-- with table column of type nchar
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_t1 
GO

-- input type nvarchar
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString CHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString NCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString NVARCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString VARCHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 4, 2, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 0, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 26, 1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, -1, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NVARCHAR(25) = N'abc🙂defghi🙂🙂'
SELECT stuff(@inputString, 2, 25, 'xyz🙂🙂wuytgdy🙂')
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比')
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比')
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比')
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比')
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比')
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString CHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString NVARCHAR(25) = N'拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARCHAR(25) = '拉·比'
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString) COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 4, 2, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 0, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 26, 1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, -1, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString NVARCHAR(25) = N'比尔·拉莫斯'
SELECT stuff(@inputString, 2, 25, '拉·比') COLLATE CHINESE_PRC_CI_AS
GO

-- input type binary
DECLARE @inputString BINARY(10) = 0x6162636465666768
DECLARE @replaceString CHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
DECLARE @replaceString NCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
DECLARE @replaceString NVARCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
DECLARE @replaceString VARCHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 4, 2, 0x6566)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 4, 2, '拉·比')
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 4, 2, '拉·比')  COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 0, 1, 0x6566)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 13, 1, 0x6566)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 2, -1, 0x6566)
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 2, 15, 0x6566)
GO

-- input type varbinary
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
DECLARE @replaceString CHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
DECLARE @replaceString NCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
DECLARE @replaceString NVARCHAR(25) = N'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
DECLARE @replaceString VARCHAR(25) = 'xyz🙂🙂wuytgdy🙂'
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
DECLARE @replaceString BINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
DECLARE @replaceString VARBINARY(10) = 0x6566
SELECT stuff(@inputString, 4, 2, @replaceString)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 4, 2, 0x6566)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 4, 2, '拉·比')
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 4, 2, '拉·比')  COLLATE CHINESE_PRC_CI_AS
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 0, 1, 0x6566)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 13, 1, 0x6566)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 2, -1, 0x6566)
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768
SELECT stuff(@inputString, 2, 15, 0x6566)
GO

-- dependent objects
SELECT * FROM babel_4838_stuff_dep_view
GO

EXEC babel_4838_stuff_dep_proc
GO

SELECT * FROM babel_4838_stuff_dep_func()
GO

SELECT * FROM babel_4838_stuff_itvf_func()
GO

SELECT * FROM babel_4838_stuff_dep_view_1
GO

SELECT * FROM babel_4838_stuff_dep_view_2
GO

SELECT * FROM babel_4838_stuff_dep_view_3
GO

SELECT * FROM babel_4838_stuff_dep_view_4
GO

SELECT * FROM babel_4838_stuff_dep_view_5
GO

-- input type UDT
-- in table babel_4838_stuff_UDT, col 'a' has basetype image and col 'b' has basetype varchar
SELECT stuff(a, 4, 2, a) FROM babel_4838_stuff_UDT
GO

SELECT stuff(b, 4, 2, b) FROM babel_4838_stuff_UDT
GO

-- other different datatypes, should throw error
DECLARE @inputString date = '2016-12-21';
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString date = '2016-12-21';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString date = '2016-12-21';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString date = '2016-12-21';
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString time(4) = '12:10:05.1237';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString time(4) = '12:10:05.1237';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString time(4) = '12:10:05.1237';
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString decimal = 123456;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString decimal = 123456;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString decimal = 123456;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString decimal = 123456;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString numeric = 12345.12;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString numeric = 12345.12;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString numeric = 12345.12;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString numeric = 12345.12;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString float = 12345.1;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString float = 12345.1;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString float = 12345.1;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString float = 12345.1;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString real = 12345.1;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString real = 12345.1;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString real = 12345.1;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString real = 12345.1;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString bigint = 12345678;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString bigint = 12345678;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString bigint = 12345678;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString bigint = 12345678;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString int = 12345678;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString int = 12345678;
SELECT stuff('abcd', 4, 1, @inputString)
GO
DECLARE @inputString int = 1;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString int = 12345678;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString CHAR(25) = 'xyzd';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString CHAR(25) = 'xyzd';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString VARCHAR(25) = 'xyzd';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString VARCHAR(25) = 'xyzd';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO

DECLARE @inputString smallint = 12356;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString smallint = 12356;
SELECT stuff('abcd', 4, 1, @inputString)
GO
DECLARE @inputString smallint = 1;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString smallint = 12356;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString NCHAR(25) = N'xyzd';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString NCHAR(25) = N'xyzd';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString NVARCHAR(25) = N'xyzd';
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString NVARCHAR(25) = N'xyzd';
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO

DECLARE @inputString tinyint = 235;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString tinyint = 235;
SELECT stuff('abcd', 4, 1, @inputString)
GO
DECLARE @inputString tinyint = 1;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString tinyint = 235;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString BINARY(10) = 0x6162636465666768;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString VARBINARY(10) = 0x6162636465666768;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO

DECLARE @inputString money = 12356;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString money = 12356;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString money = 12356;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString money = 12356;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString smallmoney = 12356;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString smallmoney = 12356;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString smallmoney = 12356;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString smallmoney = 12356;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString bit = 1;
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString bit = 1;
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString bit = 1;
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString bit = 1;
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT stuff('abcd', 4, 1, @inputString)
GO

SELECT stuff(a, 4, 2, 'abcd') from babel_4838_stuff_image;
GO
SELECT stuff('abcd', a, 2, 'abcd') from babel_4838_stuff_image;
GO
SELECT stuff('abcd', 4, a, 'abcd') from babel_4838_stuff_image;
GO
SELECT stuff('abcd', 4, 2, a) from babel_4838_stuff_image;
GO

-- input datatype text
SELECT stuff(a, 4, 2, 'abcd') FROM babel_4838_stuff_text
GO
SELECT stuff('abcd', a, 2, 'abcd') FROM babel_4838_stuff_text
GO
SELECT stuff('abcd', 4, a, 'abcd') FROM babel_4838_stuff_text
GO
SELECT stuff('abcd', 4, 2, a) FROM babel_4838_stuff_text
GO

-- input datatype ntext
SELECT stuff(b, 4, 2, 'abcd') FROM babel_4838_stuff_text
GO
SELECT stuff('abcd', b, 2, 'abcd') FROM babel_4838_stuff_text
GO
SELECT stuff('abcd', 4, b, 'abcd') FROM babel_4838_stuff_text
GO
SELECT stuff('abcd', 4, 2, b) FROM babel_4838_stuff_text
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT stuff(@inputString, 4, 1, 'abcd')
GO
DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT stuff('xysd', @inputString, 1, 'abcd')
GO
DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT stuff('xysd', 1, @inputString, 'abcd')
GO
DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT stuff('abcd', 4, 1, @inputString)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT stuff(CAST(@inputString AS VARCHAR(50)), 4, 1, 'abcd')
GO
DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT stuff('abcd', 4, 1, CAST(@inputString AS VARCHAR(50)))
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT stuff(CAST(@inputString AS VARCHAR(50)), 4, 1, 'abcd')
GO
DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
SELECT stuff('abcd', 4, 1, CAST(@inputString AS VARCHAR(50)))
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT stuff(CAST(@inputString AS VARCHAR(50)), 4, 1, 'abcd')
GO
DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT stuff('abcd', 4, 1, CAST(@inputString AS VARCHAR(50)))
GO
