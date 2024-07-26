DECLARE @class NCHAR(30) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE (@class) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE upper(@class) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE upper(@class) = N'ANIKAIT AGRAWAL'
SELECT '[' + @class + ']' WHERE upper(@class) = N'Anikait Agrawal '
SELECT '[' + @class + ']' WHERE lower(@class) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE lower(@class) = N'anikait agrawal'
SELECT '[' + @class + ']' WHERE lower(@class) = N'Anikait Agrawal '
GO

DECLARE @class CHAR(30) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE (@class) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE upper(@class) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE upper(@class) = N'ANIKAIT AGRAWAL'
SELECT '[' + @class + ']' WHERE upper(@class) = N'Anikait Agrawal '
SELECT '[' + @class + ']' WHERE lower(@class) = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE lower(@class) = N'anikait agrawal'
SELECT '[' + @class + ']' WHERE lower(@class) = N'Anikait Agrawal '
GO

DECLARE @class NCHAR = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE upper(@class) = N'ANIKAIT AGRAWAL'
SELECT '[' + @class + ']' WHERE lower(@class) = N'anikait agrawal'
GO

DECLARE @class CHAR = N'Anikait Agrawal'
SELECT '[' + @class + ']' WHERE upper(@class) = N'ANIKAIT AGRAWAL'
SELECT '[' + @class + ']' WHERE lower(@class) = N'anikait agrawal'
GO

-- different result from TSQL, should be fixed under BABEL-4807
declare @string1 varchar(30) = N'比尔·拉' COLLATE chinese_prc_ci_as
SELECT UPPER(@string1)
SELECT UPPER(@string1) COLLATE chinese_prc_ci_as
SELECT LOWER(@string1)
SELECT LOWER(@string1) COLLATE chinese_prc_ci_as
go

declare @string1 char(30) = N'比尔·拉' COLLATE chinese_prc_ci_as
SELECT '|' + UPPER(@string1) + '|'
SELECT '|' + UPPER(@string1) + '|' COLLATE chinese_prc_ci_as
SELECT '|' + LOWER(@string1) + '|'
SELECT '|' + LOWER(@string1) + '|' COLLATE chinese_prc_ci_as
go

SELECT UPPER(NULL)
SELECT LOWER(NULL)
GO

DECLARE @inputString BINARY(30) = 0x4142434445
SELECT UPPER(@inputString)
SELECT LOWER(@inputString)
SELECT CONVERT(BINARY(50), UPPER(@inputString));
SELECT CONVERT(BINARY(50), LOWER(@inputString));
GO

DECLARE @inputString VARBINARY(30) = 0x4142434445
SELECT UPPER(@inputString)
SELECT LOWER(@inputString)
SELECT CONVERT(VARBINARY(50), UPPER(@inputString));
SELECT CONVERT(VARBINARY(50), LOWER(@inputString));
GO

-- different result from TSQL, should be fixed under BABEL-4803
declare @string1 nchar(30) = N'比尔·拉';
select '|' + UPPER(@string1) + '|'
select '|' + LOWER(@string1) + '|'
GO

-- different result from TSQL, should be fixed under BABEL-1664
DECLARE @date date = '12-21-16';  
DECLARE @datetime datetime = @date; 
SELECT UPPER(@datetime)
SELECT LOWER(@datetime)
GO

-- different result from TSQL, should be fixed under BABEL-1664
DECLARE @smalldatetime smalldatetime = '1955-12-13 12:43:10';
SELECT UPPER(@smalldatetime)
SELECT LOWER(@smalldatetime)
GO

DECLARE @date date = '2016-12-21';
SELECT UPPER(@date)
SELECT LOWER(@date)
GO

DECLARE @time time(4) = '12:10:05.1237';
SELECT UPPER(@time)
SELECT LOWER(@time)
GO

DECLARE @datetimeoffset datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT UPPER(@datetimeoffset)
SELECT LOWER(@datetimeoffset)
GO

DECLARE @datetime2 datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT UPPER(@datetime2)
SELECT LOWER(@datetime2)
GO

DECLARE @decimal decimal = 123;
SELECT UPPER(@decimal)
SELECT LOWER(@decimal)
GO

DECLARE @numeric numeric = 12345.12;
SELECT UPPER(@numeric)
SELECT LOWER(@numeric)
GO

DECLARE @float float = 12345.1;
SELECT UPPER(@float)
SELECT LOWER(@float)
GO

DECLARE @real real = 12345.1;
SELECT UPPER(@real)
SELECT LOWER(@real)
GO

DECLARE @bigint bigint = 2;
SELECT UPPER(@bigint)
SELECT LOWER(@bigint)
GO

DECLARE @int int = 2;
SELECT UPPER(@int)
SELECT LOWER(@int)
GO

DECLARE @smallint smallint = 2;
SELECT UPPER(@smallint)
SELECT LOWER(@smallint)
GO

DECLARE @tinyint tinyint = 2;
SELECT UPPER(@tinyint)
SELECT LOWER(@tinyint)
GO

DECLARE @money money = 2;
SELECT UPPER(@money)
SELECT LOWER(@money)
GO

DECLARE @smallmoney smallmoney = 2;
SELECT UPPER(@smallmoney)
SELECT LOWER(@smallmoney)
GO

DECLARE @bit bit = 1;
SELECT UPPER(@bit)
SELECT LOWER(@bit)
GO

DECLARE @myid uniqueidentifier = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier)
SELECT UPPER(@myid)
SELECT LOWER(@myid)
GO

DECLARE @myid sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT UPPER(@myid)
SELECT LOWER(@myid)
GO

DECLARE @myid xml = CAST ('<body/>' AS xml)
SELECT UPPER(@myid)
SELECT LOWER(@myid)
GO

DECLARE @myid geometry = geometry::STGeomFromText('POINT (1 2)', 0)
SELECT UPPER(@myid)
SELECT LOWER(@myid)
GO

DECLARE @myid sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
SELECT UPPER(CAST (@myid AS VARCHAR))
SELECT LOWER(CAST (@myid AS VARCHAR))
GO

DECLARE @myid xml = CAST ('<body/>' AS xml)
SELECT UPPER(CAST (@myid AS VARCHAR))
SELECT LOWER(CAST (@myid AS VARCHAR))
GO

DECLARE @myid geometry = geometry::STGeomFromText('POINT (1 2)', 0)
SELECT UPPER(CAST (@myid AS VARCHAR))
SELECT LOWER(CAST (@myid AS VARCHAR))
GO

Select UPPER(a), LOWER(a) from upper_lower_text
GO
Select UPPER(a), LOWER(a) from upper_lower_ntext
GO
Select UPPER(a), LOWER(a) from upper_lower_image
GO

declare @string1 nvarchar(30) = N'比尔·拉';
select '|' + UPPER(@string1) + '|'
select '|' + LOWER(@string1) + '|'
GO

declare @string1 char(30) = N'比尔·拉';
select '|' + UPPER(@string1) + '|'
select '|' + LOWER(@string1) + '|'
GO

declare @string1 varchar(30) = N'比尔·拉';
select UPPER(@string1)
select LOWER(@string1)
GO

SELECT upper(a), lower(b), lower(c), upper(d) from upper_lower_dt;
GO
SELECT * from upper_lower_dt where UPPER(a) = N'Anikait';
GO
SELECT * from upper_lower_dt where LOWER(c) = N'比尔·拉';
GO
SELECT * from upper_lower_dt where LOWER(d) = N'比尔·拉';
GO

SELECT * from dep_view_upper
GO
SELECT upper(col), lower(col) FROM tab_arabic_ci_ai;
GO
SELECT upper(col), lower(col) FROM tab_arabic_ci_as;
GO
SELECT upper(col), lower(col) FROM tab_arabic_cs_as;
GO
SELECT upper(col), lower(col) FROM tab_chinese_ci_ai;
GO
SELECT upper(col), lower(col) FROM tab_chinese_ci_as;
GO
SELECT upper(col), lower(col) FROM tab_chinese_cs_as;
GO
EXEC dep_proc_upper
GO
select dbo.dep_func_upper()
GO

SELECT * from dep_view_lower
GO
EXEC dep_proc_lower
GO
SELECT * from dep_view_upper_lower
GO
EXEC dep_proc_upper_lower
GO
SELECT * from dep_view_upper_lower1
GO
EXEC dep_proc_upper_lower1
GO
select dbo.dep_func_lower()
GO
select dbo.tvp_func_upper_lower()
GO
SELECT * from dep_view_lower1
GO
declare @b dbo.MyUDT = CAST('scsdc' AS dbo.MyUDT)
select upper(@b)
GO
