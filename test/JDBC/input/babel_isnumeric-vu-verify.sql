SELECT * FROM babel_isnumeric_vu_prepare_t1
GO
-- Test bigint
SELECT ISNUMERIC(bigint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test int
SELECT ISNUMERIC(int_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test smallint
SELECT ISNUMERIC(smallint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test tinyint
SELECT ISNUMERIC(tinyint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test bit
SELECT ISNUMERIC(bit_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test decimal
SELECT ISNUMERIC(decimal_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test numeric
SELECT ISNUMERIC(numeric_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test float
SELECT ISNUMERIC(float_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test real
SELECT ISNUMERIC(real_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test money
SELECT ISNUMERIC(money_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test smallmoney
SELECT ISNUMERIC(smallmoney_type)
FROM babel_isnumeric_vu_prepare_t1
GO

-- Test valid and invalid operators and literals
select isnumeric(1234567890)
GO
select isnumeric('28903')
GO
select isnumeric('+')
GO
select isnumeric('+ ')
GO
-- Blocked due to BABEL-2853
--select isnumeric($)
--GO
select isnumeric('$24,23.43')
GO
-- Blocked due to BABEL-2853
--select isnumeric(€)
--GO
select isnumeric('+ 1')
GO
select isnumeric('$+1.1234')
GO
select isnumeric('+$1.1234')
GO
select isnumeric(' $ + 1.1234')
GO
select isnumeric(' + $ 1.1234')
GO

select isnumeric('abcdefghijklmnop')
GO
select isnumeric('24.89.43')
GO
select isnumeric('€24,2.3.43')
GO
select isnumeric('+-')
GO
select isnumeric('23$')
GO
select isnumeric(null)
GO
select isnumeric(' ')
GO
select isnumeric('1 .1234')
GO
select isnumeric('+1 .1234')
GO
select isnumeric('$1 .1234')
GO

-- Test different datatypes as local variables
DECLARE @int_var int = 12345
select isnumeric(@int_var)
GO

DECLARE @bigint_var bigint = 9223372036854775807
select isnumeric(@bigint_var)
GO

DECLARE @smallint_var smallint = -32768
select isnumeric(@smallint_var)
GO

DECLARE @tinyint_var tinyint = 255
select isnumeric(@tinyint_var)
GO

DECLARE @bit_var bit = 1
select isnumeric(@bit_var)
GO

DECLARE @decimal_var decimal(10,5) = 12345.67890
select isnumeric(@decimal_var)
GO

DECLARE @numeric_var numeric(18,9) = 123456789.987654321
select isnumeric(@numeric_var)
GO

DECLARE @float_var float = 1.79E+308
select isnumeric(@float_var)
GO

DECLARE @real_var real = 3.40E+38
select isnumeric(@real_var)
GO

DECLARE @money_var money = 922337203685477.5807
select isnumeric(@money_var)
GO

DECLARE @smallmoney_var smallmoney = 214748.3647
select isnumeric(@smallmoney_var)
GO

DECLARE @char_var char(20) = '12345.6789'
select isnumeric(@char_var)
GO

DECLARE @varchar_var varchar(50) = '$1,234,567.89'
select isnumeric(@varchar_var)
GO

DECLARE @nchar_var nchar(20) = N'12345.6789'
select isnumeric(@nchar_var)
GO

DECLARE @nvarchar_var nvarchar(50) = N'-9876.54321'
select isnumeric(@nvarchar_var)
GO

DECLARE @datetime_var datetime = '2023-01-01 12:34:56'
select isnumeric(@datetime_var)
GO

DECLARE @date_var date = '2023-01-01'
select isnumeric(@date_var)
GO

-- Test text values exceeding numeric(38,0)
select isnumeric('9999999999999999999999999999999999999999')
GO

select isnumeric('10000000000000000000000000000000000000000')
GO

select isnumeric('-9999999999999999999999999999999999999999')
GO

select isnumeric('999999999999999999999999999999999999999.99999')
GO

select isnumeric('1' + REPLICATE('0', 38))
GO

select isnumeric('1' + REPLICATE('0', 100))
GO

select isnumeric('0.' + REPLICATE('9', 38))
GO

select isnumeric('1E+38')
GO

select isnumeric('1E+100')
GO

select isnumeric('1E-100')
GO

-- Test invalid conversions to numeric
select isnumeric('abc')
GO

select isnumeric('123abc')
GO

select isnumeric('abc123')
GO

select isnumeric('12.34.56')
GO

select isnumeric('12,34,56')
GO

select isnumeric('$123$456')
GO

select isnumeric('123..456')
GO

select isnumeric('++123')
GO

select isnumeric('--123')
GO

select isnumeric('+-123')
GO

select isnumeric('123-')
GO

select isnumeric('123+')
GO

select isnumeric('123.456.789')
GO

select isnumeric('1,23,456')
GO

select isnumeric('1.2e3.4')
GO

select isnumeric('1.2e')
GO

select isnumeric('e1.2')
GO

select isnumeric('1.2D')
GO


select isnumeric('€')
GO

select isnumeric('¥')
GO

select isnumeric('£')
GO

-- Test expressions with mixed valid/invalid inputs
select isnumeric('123' + 'abc')
GO

DECLARE @valid varchar(10) = '123', @invalid varchar(10) = 'abc'
select isnumeric(@valid + @invalid)
GO

DECLARE @overflow varchar(50) = '1' + REPLICATE('0', 38)
select isnumeric(@overflow)
GO

-- Test with expressions that might cause overflow
DECLARE @big_decimal decimal(38,0) = 99999999999999999999999999999999999999
select isnumeric(@big_decimal)
GO

DECLARE @big_float float = 1.79E+308
select isnumeric(@big_float)
GO

-- Test with CAST that might cause overflow
select isnumeric(CAST(1.79E+308 AS varchar(50)))
GO

-- Test with computed expressions
select isnumeric(CAST(POWER(10, 3) AS varchar(50)))
GO