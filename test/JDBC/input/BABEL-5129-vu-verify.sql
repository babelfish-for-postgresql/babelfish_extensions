-- Tests for ISNUMERIC function with varchar and nvarchar variables

SELECT * FROM babel_5129
GO
-- Test int
SELECT ISNUMERIC(int_type)
FROM babel_5129
GO
-- Test numeric
SELECT ISNUMERIC(numeric_type)
FROM babel_5129
GO
-- Test money
SELECT ISNUMERIC(money_type)
FROM babel_5129
GO
-- Test varchar
SELECT ISNUMERIC(varchar_type)
FROM babel_5129
GO
-- Test nvarchar
SELECT ISNUMERIC(nvarchar_type)
FROM babel_5129
GO

-- Test numeric variable
DECLARE @a numeric(24,6);
SELECT @a = 12.3420000000;
SELECT ISNUMERIC(@a), LEN(@a), DATALENGTH(@a)
GO

-- Test varchar variable
DECLARE @v varchar(20);
SELECT @v = '12.3420000000';
SELECT ISNUMERIC(@v), LEN(@v), DATALENGTH(@v)
GO

-- Test nvarchar variable
DECLARE @nv nvarchar(10);
SELECT @nv = '12.3420000000';
SELECT ISNUMERIC(@nv), LEN(@nv), DATALENGTH(@nv)
GO

-- Test empty varchar variable
DECLARE @v varchar(20);
SELECT @v = '';
SELECT ISNUMERIC(@v), LEN(@v), DATALENGTH(@v)
GO

-- Test empty nvarchar variable
DECLARE @nv nvarchar(10);
SELECT @nv = '';
SELECT ISNUMERIC(@nv), LEN(@nv), DATALENGTH(@nv)
GO

-- Test varchar variable with invalid numeric
DECLARE @v varchar(20);
SELECT @v = '12.34.20000000';
SELECT ISNUMERIC(@v), LEN(@v), DATALENGTH(@v)
GO

-- Test nvarchar variable with invalid numeric
DECLARE @nv nvarchar(10);
SELECT @nv = '12.34.20000000';
SELECT ISNUMERIC(@nv), LEN(@nv), DATALENGTH(@nv)
GO