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
