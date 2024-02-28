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
SELECT UPPER(@string1)
SELECT UPPER(@string1) COLLATE chinese_prc_ci_as
SELECT LOWER(@string1)
SELECT LOWER(@string1) COLLATE chinese_prc_ci_as
go

SELECT UPPER(NULL)
SELECT LOWER(NULL)
GO

DECLARE @inputString BINARY(30) = 0x4142434445
SELECT UPPER(@inputString)
SELECT LOWER(@inputString)
GO

DECLARE @inputString VARBINARY(30) = 0x4142434445
SELECT UPPER(@inputString)
SELECT LOWER(@inputString)
GO

-- different result from TSQL, should be fixed under BABEL-4803
declare @string1 nchar(30) = N'比尔·拉';
select UPPER(@string1)
select LOWER(@string1)
GO

declare @string1 nvarchar(30) = N'比尔·拉';
select UPPER(@string1)
select LOWER(@string1)
GO

declare @string1 char(30) = N'比尔·拉';
select UPPER(@string1)
select LOWER(@string1)
GO

declare @string1 varchar(30) = N'比尔·拉';
select UPPER(@string1)
select LOWER(@string1)
GO

SELECT * from upper_lower_dt;
GO
SELECT * from upper_lower_dt where UPPER(a) = N'Anikait';
GO
SELECT * from upper_lower_dt where LOWER(c) = N'比尔·拉';
GO
SELECT * from upper_lower_dt where LOWER(d) = N'比尔·拉';
GO
