declare @string1 nvarchar(30) = N'比尔·拉',@string2 nvarchar(30) = N'斯', @pat nvarchar(10) = N'尔'
select REPLACE(@string1, @pat, @string2)
GO

-- NULL
SELECT replace(NULL, 'acs', 'scd')
GO

SELECT replace('scd', NULL, 'scd')
GO

SELECT replace('scd', 'scd', NULL)
GO

SELECT replace(NULL, NULL, NULL)
GO

SELECT replace(NULL, 'aces', 'scdwe')
GO

-- different no. of arguments
SELECT replace('aceds', 'aces', 'scdwe', 'acsdes')
GO

SELECT replace('aces', 'scdwe')
GO

-- input type char
DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '🙂de', 'x🙂y')
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '?de', 'x🙂y')
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '😎de', 'x🙂y')
GO

DECLARE @inputString CHAR(50) = '比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比')
GO

DECLARE @inputString CHAR(50) = '比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比') COLLATE CHINESE_PRC_CI_AS
GO

DECLARE @inputString CHAR(50) = '比尔·拉莫斯', @pattern CHAR(10) = '拉莫', @replacement CHAR(10) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = '比尔·拉莫斯', @pattern CHAR(10) = '拉莫', @replacement CHAR(10) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement) COLLATE CHINESE_PRC_CI_AS
GO

-- input type varchar
DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '🙂de', 'x🙂y')
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '?de', 'x🙂y')
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '😎de', 'x🙂y')
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比')
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比') COLLATE CHINESE_PRC_CI_AS
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯', @pattern VARCHAR(10) = '拉莫', @replacement VARCHAR(10) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯', @pattern VARCHAR(10) = '拉莫', @replacement VARCHAR(10) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement) COLLATE CHINESE_PRC_CI_AS
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯', @pattern VARCHAR(MAX) = '拉莫', @replacement VARCHAR(MAX) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯', @pattern VARCHAR(MAX) = '拉莫', @replacement VARCHAR(MAX) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement) COLLATE CHINESE_PRC_CI_AS
GO

-- with table column of type varchar with collation chinese_prc_ci_as
SELECT replace(a, b, c) FROM babel_4836_replace_chinese_prc_ci_as
GO

SELECT replace(a, b, c) COLLATE CHINESE_PRC_CI_AS FROM babel_4836_replace_chinese_prc_ci_as
GO

-- with table column of type varchar with collation chinese_prc_cs_as
SELECT replace(a, b, c) FROM babel_4836_replace_chinese_prc_cs_as
GO

SELECT replace(a, b, c) COLLATE CHINESE_PRC_CS_AS FROM babel_4836_replace_chinese_prc_cs_as
GO

-- with table column of type varchar with collation arabic_prc_ci_as
SELECT replace(a, b, c) FROM babel_4836_replace_arabic_ci_as
GO

SELECT replace(a, b, c) COLLATE ARABIC_CI_AS FROM babel_4836_replace_arabic_ci_as
GO

-- with table column of type varchar with collation arabic_prc_cs_as
SELECT replace(a, b, c) FROM babel_4836_replace_arabic_cs_as
GO

SELECT replace(a, b, c) COLLATE ARABIC_CS_AS FROM babel_4836_replace_arabic_cs_as
GO

-- input type nchar
DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '🙂de', 'x🙂y')
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '?de', 'x🙂y')
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '😎de', 'x🙂y')
GO

DECLARE @inputString NCHAR(50) = N'比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比')
GO

DECLARE @inputString NCHAR(50) = N'比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比') COLLATE CHINESE_PRC_CI_AS
GO

DECLARE @inputString NCHAR(50) = N'比尔·拉莫斯', @pattern NCHAR(10) = N'拉莫', @replacement NCHAR(10) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'比尔·拉莫斯', @pattern NCHAR(10) = N'拉莫', @replacement NCHAR(10) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement) COLLATE CHINESE_PRC_CI_AS
GO

-- with table column of type nchar
SELECT replace(a, b, c) FROM babel_4836_replace_t1 
GO

-- input type nvarchar
DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '🙂de', 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '?de', 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂'
SELECT replace(@inputString, '😎de', 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比')
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯'
SELECT replace(@inputString, '拉莫', '尔·比') COLLATE CHINESE_PRC_CI_AS
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯', @pattern NVARCHAR(10) = N'拉莫', @replacement NVARCHAR(10) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯', @pattern NVARCHAR(10) = N'拉莫', @replacement NVARCHAR(10) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement) COLLATE CHINESE_PRC_CI_AS
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯', @pattern NVARCHAR(MAX) = N'拉莫', @replacement NVARCHAR(MAX) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯', @pattern NVARCHAR(MAX) = N'拉莫', @replacement NVARCHAR(MAX) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement) COLLATE CHINESE_PRC_CI_AS
GO

-- input type binary
DECLARE @inputString BINARY(10) = 0x61626364656667
SELECT replace(@inputString, 0x6364, 0x737475)
GO

DECLARE @inputString BINARY(10) = 0x61626364656667, @pattern BINARY(10) = 0x6364, @replacement BINARY(10) = 0x737475
SELECT replace(@inputString, @pattern, @replacement)
GO

-- with table column of type binary
SELECT replace(a, b, c) FROM babel_4836_replace_t4
GO

-- input type varbinary
DECLARE @inputString VARBINARY(10) = 0x61626364656667
SELECT replace(@inputString, 0x6364, 0x737475)
GO

DECLARE @inputString VARBINARY(10) = 0x61626364656667, @pattern VARBINARY(10) = 0x6364, @replacement VARBINARY(10) = 0x737475
SELECT replace(@inputString, @pattern, @replacement)
GO

-- with table column of type varbinary
SELECT replace(a, b, c) FROM babel_4836_replace_t5
GO


-- input type text
SELECT replace(a, b, c) FROM babel_4836_replace_text
GO

DECLARE @pattern VARCHAR(20) = '?de', @replacement VARCHAR(10) = 'x?y';
SELECT replace(a, @pattern, @replacement) FROM babel_4836_replace_text
GO

-- input type ntext
SELECT replace(a, b, c) FROM babel_4836_replace_ntext
GO

DECLARE @pattern NVARCHAR(20) = N'🙂de', @replacement NVARCHAR(10) = N'x🙂y';
SELECT replace(a, @pattern, @replacement) FROM babel_4836_replace_ntext
GO

-- dependent objects
SELECT * FROM babel_4836_replace_dep_view
GO

SELECT * FROM babel_4836_replace_dep_view1
GO

EXEC babel_4836_replace_dep_proc
GO

SELECT * FROM babel_4836_replace_dep_func()
GO

SELECT * FROM babel_4836_replace_itvf_func()
GO

-- different datatypes of inputString and pattern/replacement
DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '🙂de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '😎de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = '比尔·拉莫斯', @pattern VARCHAR(20) = '拉莫', @replacement VARCHAR(20) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'🙂de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'😎de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = '比尔·拉莫斯', @pattern NCHAR(20) = N'拉莫', @replacement NCHAR(20) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'🙂de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'😎de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = '比尔·拉莫斯', @pattern NVARCHAR(20) = N'拉莫', @replacement NVARCHAR(20) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO
 
DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement NCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement NVARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement VARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement VARCHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement CHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement CHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = N'?de', @replacement CHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = N'?de', @replacement CHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @replacement VARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @replacement NVARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @replacement CHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @replacement NCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString CHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '🙂de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '😎de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯', @pattern CHAR(20) = '拉莫', @replacement CHAR(20) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'🙂de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'😎de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯', @pattern NCHAR(20) = N'拉莫', @replacement NCHAR(20) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)+ '|'
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'🙂de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'😎de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '比尔·拉莫斯', @pattern NVARCHAR(20) = N'拉莫', @replacement NVARCHAR(20) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement NCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement NVARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(40) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement VARCHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement CHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement VARCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement VARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement VARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement NVARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement CHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement NCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString VARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern CHAR(20) = '🙂de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern CHAR(20) = '😎de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'比尔·拉莫斯', @pattern CHAR(20) = '拉莫', @replacement CHAR(20) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '🙂de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '😎de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'比尔·拉莫斯', @pattern VARCHAR(20) = '拉莫', @replacement VARCHAR(20) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'🙂de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'😎de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = N'比尔·拉莫斯', @pattern NVARCHAR(20) = N'拉莫', @replacement NVARCHAR(20) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement NCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement NVARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(40) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement NVARCHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement CHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement VARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement VARCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement VARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @replacement VARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @replacement NVARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @replacement CHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @replacement NCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern CHAR(20) = '🙂de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern CHAR(20) = '😎de', @replacement CHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯', @pattern CHAR(20) = '拉莫', @replacement CHAR(20) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '?de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '🙂de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = '😎de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯', @pattern VARCHAR(20) = '拉莫', @replacement VARCHAR(20) = '尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'🙂de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'😎de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = N'比尔·拉莫斯', @pattern NCHAR(20) = N'拉莫', @replacement NCHAR(20) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement VARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement NCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement NVARCHAR(20) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(40) = 'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement CHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(20) = '?de', @replacement VARCHAR(40) = 'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement VARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(20) = N'?de', @replacement CHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement CHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NVARCHAR(20) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement VARCHAR(40) = N'x🙂y'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement VARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(20) = N'?de', @replacement NVARCHAR(40) = N'x🙂yw'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement VARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement NVARCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement CHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @replacement NCHAR(40) = 'x🙂y'
SELECT replace(@inputString, '?de', @replacement)
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern VARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NVARCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern CHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = 'abc🙂defghi🙂🙂', @pattern NCHAR(40) = '?de'
SELECT replace(@inputString, @pattern, 'x🙂y')
GO

DECLARE @inputString NVARCHAR(50) = N'ABCDEF', @pattern BINARY(4) = 0x414243, @replacement NCHAR(20) = N'尔·比'
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARBINARY(50) = 0x41424344, @pattern NCHAR(20) = N'尔·比', @replacement VARBINARY(2) = 0x4144
SELECT replace(@inputString, @pattern, @replacement)
GO

-- input type UDT
-- in table babel_4836_replace_image_UDT_t, col 'a', 'b' and 'c' has basetype image
SELECT replace(a, b, c) FROM babel_4836_replace_image_UDT_t
GO

-- in table babel_4836_replace_var_UDT_t, col 'a', 'b' and 'c' has basetype varchar
SELECT replace(b, b, c) FROM babel_4836_replace_var_UDT_t
GO

-- other different datatypes, all of these should be blocked
DECLARE @inputString date = '2016-12-21'
SELECT replace(@inputString, '12', '06');
GO

DECLARE @inputString date = '2016-12-21', @pattern VARCHAR(10) = '12', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @pattern date = '2016-12-21', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @pattern VARCHAR(20) = '2016-12-21', @replacement date = '2016-12-21';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString date = '2016-12-21'
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @date date = '12-21-16';
DECLARE @inputString datetime = @date, @pattern VARCHAR(10) = '12', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @date date = '12-21-16';
DECLARE @inputString datetime = @date;
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @date date = '2016-12-21', @replacement VARCHAR(10) = '06';
DECLARE @pattern datetime = @date;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(20) = '2016-12-21', @pattern VARCHAR(20) = '2016-12-21', @date date = '2016-12-21';
DECLARE @replacement datetime = @date;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10', @pattern VARCHAR(10) = '12', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(30) = '2016-12-21 12:43:10', @pattern smalldatetime = '2016-12-21 12:43:10', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(30) = '2016-12-21 12:43:10', @pattern VARCHAR(30) = '2016-12-21 12:43:10', @replacement smalldatetime = '2016-12-21 12:43:10';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString time(4) = '12:10:05.1237', @pattern VARCHAR(10) = '12', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(30) = '12:10:05.1237', @pattern time(4) = '12:10:05.1237', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(30) = '12:10:05.1237', @pattern VARCHAR(30) = '12:10:05.1237', @replacement time(4) = '12:10:05.1237';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0', @pattern VARCHAR(10) = '12', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1234 +10:0', @pattern datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1234 +10:0', @pattern VARCHAR(50) = '1968-10-23 12:45:37.1234 +10:0', @replacement datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237', @pattern VARCHAR(10) = '12', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1237', @pattern datetime2(4) = '1968-10-23 12:45:37.1237', @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1968-10-23 12:45:37.1237', @pattern VARCHAR(50) = '1968-10-23 12:45:37.1237', @replacement datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString decimal = 123456, @pattern decimal = 12, @replacement decimal = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern decimal = 12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement decimal = 12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString numeric = 12345.12, @pattern numeric = 12, @replacement numeric = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern numeric = 12.12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement numeric = 12.12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString float = 12345.1, @pattern float = 12, @replacement float = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern float = 12.1, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement float = 12.1;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString real = 12345.1, @pattern real = 12, @replacement real = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern real = 12.1, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement real = 12.1;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString bigint = 12345678, @pattern bigint = 12, @replacement bigint = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern bigint = 12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement bigint = 12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString int = 12345678, @pattern int = 12, @replacement int = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern int = 12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement int = 12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString smallint = 12356, @pattern smallint = 12, @replacement smallint = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern smallint = 12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement smallint = 12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString tinyint = 235, @pattern tinyint = 12, @replacement tinyint = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern tinyint = 12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement tinyint = 12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString money = 12356, @pattern money = 12, @replacement money = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern money = 12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement money = 12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString smallmoney = 12356, @pattern smallmoney = 12, @replacement smallmoney = 06;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern smallmoney = 12, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement smallmoney = 12;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString bit = 1, @pattern bit = 1, @replacement bit = 0;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern bit = 1, @replacement VARCHAR(10) = '06';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '1234', @replacement bit = 0;
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER)
DECLARE @pattern VARCHAR(10) = '6F', @replacement VARCHAR(10) = '5A';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER), @replacement VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @replacement UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER);
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString UNIQUEIDENTIFIER = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UNIQUEIDENTIFIER)
SELECT replace(@inputString, @inputString, @inputString)
GO

SELECT replace(a, a, a) FROM babel_4836_replace_image;
GO

SELECT replace('a', a, 'a') FROM babel_4836_replace_image;
GO

SELECT replace('a', 'a', a) FROM babel_4836_replace_image;
GO

DECLARE @pattern VARCHAR(10) = '6F', @replacement VARCHAR(10) = '5A';
SELECT replace(a, @pattern, @replacement) from babel_4836_replace_image;
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @pattern VARCHAR(10) = '6F', @replacement VARCHAR(10) = '5A';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant), @replacement VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @replacement sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant);
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
DECLARE @pattern xml = CAST ('<fruit/>' AS xml), @replacement xml = CAST ('<vegetables/>' AS xml);
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern xml = CAST ('<body><fruit/></body>' AS xml), @replacement VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @replacement xml = CAST ('<body><fruit/></body>' AS xml);
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0), @pattern VARCHAR(10) = '(1 2)', @replacement VARCHAR(10) = '(4 5)';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern geometry = geometry::STGeomFromText('POINT (1 2)', 0), @replacement VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @replacement geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326), @pattern VARCHAR(10) = '(1 2)', @replacement VARCHAR(10) = '(4 5)';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern geography = geography::STGeomFromText('POINT (1 2)', 4326), @replacement VARCHAR(10) = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString VARCHAR(50) = '1234', @pattern VARCHAR(50) = '6F9619FF-8B86-D011-B42D-00C04FC964FF', @replacement geography = geography::STGeomFromText('POINT (1 2)', 4326);
SELECT replace(@inputString, @pattern, @replacement)
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT replace(@inputString, @inputString, @inputString)
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @pattern VARCHAR(10) = '6F', @replacement VARCHAR(10) = '5A';
SELECT replace(CAST (@inputString AS VARCHAR(50)), @pattern, @replacement)
GO

DECLARE @inputString xml = CAST ('<body><fruit/></body>' AS xml)
DECLARE @pattern xml = CAST ('<fruit/>' AS xml), @replacement xml = CAST ('<veget/>' AS xml);
SELECT replace(CAST (@inputString AS VARCHAR(50)), CAST (@pattern AS VARCHAR(50)), CAST (@replacement AS VARCHAR(50)))
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0), @pattern VARCHAR(10) = '(1 2)', @replacement VARCHAR(10) = '(4 5)';
SELECT replace(CAST (@inputString AS VARCHAR(50)), @pattern, @replacement)
GO