-- TEST CASE 1: Basic rounding with different data types
INSERT INTO TestRound (numeric_data, int_data, bigint_data, decimal_data, float_data, money_data) 
VALUES (3.14159, 3, 3, 3.14159, 3.14159, 3.14);
GO

SELECT * FROM TestRound;
GO

-- TEST CASE 2: Testing ROUND with different data types and decimal places
SELECT 
    ROUND(3.14159, 0) as float_round_0,
    ROUND(3.14159, 2) as float_round_2,
    ROUND(CAST(3.14159 AS DECIMAL(10,5)), 2) as decimal_round_2,
    ROUND(CAST(3 AS INT), 2) as int_round_2,
    ROUND(CAST(3.14159 AS MONEY), 2) as money_round_2,
    ROUND(CAST(3.14159 AS NUMERIC(10,5)), 2) as numeric_round_2;
GO

-- TEST CASE 3: Testing negative decimal places
SELECT 
    ROUND(1234.5678, -1) as round_tens,
    ROUND(1234.5678, -2) as round_hundreds,
    ROUND(1234.5678, -3) as round_thousands;
GO

-- TEST CASE 4: Testing rounding with .5 cases for different types
SELECT 
    ROUND(3.5, 0) as round_up_35_float,
    ROUND(CAST(3.5 AS DECIMAL(10,4)), 0) as round_up_35_decimal,
    ROUND(CAST(3.5 AS MONEY), 0) as round_up_35_money,
    ROUND(CAST(3.5 AS NUMERIC(10,4)), 0) as round_up_35_numeric;
GO

-- TEST CASE 5: Testing NULL values for different types
SELECT 
    ROUND(CAST(NULL AS FLOAT), 2) as null_round_float,
    ROUND(CAST(NULL AS DECIMAL(10,4)), 2) as null_round_decimal,
    ROUND(CAST(NULL AS MONEY), 2) as null_round_money,
    ROUND(CAST(NULL AS NUMERIC(10,4)), 2) as null_round_numeric;
GO

-- TEST CASE 6: Testing extreme values
SELECT 
    ROUND(9999999.99999, 2) as large_number,
    ROUND(0.000000001, 8) as small_number,
    ROUND(-9999999.99999, 2) as large_negative;
GO

-- TEST CASE 7: Testing the RoundFloat function
SELECT 
    dbo.RoundFloat(3.14159, 2) as pi_rounded,
    dbo.RoundFloat(2.71828, 3) as e_rounded;
GO

-- TEST CASE 8: Testing the RoundDecimal function
SELECT 
    dbo.RoundDecimal(3.14159, 2) as pi_rounded,
    dbo.RoundDecimal(2.71828, 3) as e_rounded;
GO

-- TEST CASE 9: Testing views
SELECT * FROM dbo.RoundDemoView;
GO

SELECT * FROM dbo.TestRoundView;
GO

-- TEST CASE 10: Testing RoundMultipleTypes function
SELECT * FROM dbo.RoundMultipleTypes(3.14159, 3.14159, 3, 2);
GO

-- TEST CASE 11: Testing with expressions
SELECT 
    ROUND(1.0/3.0, 2) as division_rounded,
    ROUND(SQRT(2), 4) as sqrt_rounded,
    ROUND(PI(), 4) as pi_rounded;
GO

-- TEST CASE 12: Testing with different numeric types
DECLARE @float_val FLOAT = 3.14159;
DECLARE @decimal_val DECIMAL(10,5) = 3.14159;
DECLARE @money_val MONEY = 3.14159;
DECLARE @numeric_val NUMERIC(10,5) = 3.14159;
DECLARE @bigint_val BIGINT = 3;
SELECT 
    ROUND(@float_val, 2) as float_round,
    ROUND(@decimal_val, 2) as decimal_round,
    ROUND(@money_val, 2) as money_round,
    ROUND(@numeric_val, 2) as numeric_round,
    ROUND(CAST(@bigint_val AS FLOAT), 2) as bigint_round;
GO

-- TEST CASE 13: Testing edge cases for all types
SELECT 
    ROUND(CAST(0.0 AS NUMERIC(10,4)), 2) as zero_round_numeric,
    ROUND(0.0, 2) as zero_round_float,
    ROUND(CAST(0.0 AS MONEY), 2) as zero_round_money,
    ROUND(CAST(0.0 AS DECIMAL(10,4)), 2) as zero_round_decimal;
GO

-- TEST CASE 14: Testing with computed columns
SELECT 
    numeric_data,
    decimal_data,
    float_data,
    money_data,
    round_float_2,
    round_decimal_2,
    round_int_2
FROM TestRound;
GO

-- TEST CASE 15: Testing type conversion with ROUND
SELECT 
    ROUND(CAST('3.14159' AS FLOAT), 2) as string_to_float_round,
    ROUND(CAST('3.14159' AS DECIMAL(10,5)), 2) as string_to_decimal_round,
    ROUND(CAST('3.14159' AS MONEY), 2) as string_to_money_round,
    ROUND(CAST('3.14159' AS NUMERIC(10,5)), 2) as string_to_numeric_round;
GO

-- TEST: Testing unsupported data types from sql server documentation
select round(cast ('abc' as binary), 1)
go

select round(cast ('abc' as varbinary), 1)
go

select round(cast ('abc' as char(3)), 1)
go

select round(cast ('abc' as nchar(3)), 1)
go

select round(cast ('abc' as varchar(3)), 1)
go

select round(cast ('abc' as nvarchar(3)), 1)
go

select round(cast ('11-11-2025' as datetime), 1)
go

select round(cast ('11-11-2025' as smalldatetime), 1)
go

select round(cast ('11-11-2025' as date), 1)
go

select round(cast ('11:30:30' as time), 1)
go

select round(cast ('11-11-2025' as datetimeoffset), 1)
go

select round(cast ('11-11-2025' as datetime2), 1)
go

select round(cast (2.51 as decimal), 1)
go

select round(cast (1.67 as numeric), 1)
go

select round(cast (1.77 as float), 1)
go

select round(cast (1.77 as real), 1)
go

select round(cast (1.77 as bigint), 1)
go

select round(cast (2 as int), 1)
go

select round(cast (2 as smallint), 1)
go

select round(cast (2 as tinyint), 1)
go

select round(cast (5 as money), 1)
go

select round(cast (5 as smallmoney), 1)
go

select round(cast (0 as bit), 1)
go

select round(NEWID(), 1)
go

select round(cast ('abc' as image), 1)
go

select round(cast ('abc' as ntext), 1)
go

select round(cast ('abc' as text), 1)
go

select round(cast ('abc' as sql_variant), 1)
go

select round(cast ('<body><fruit/></body>' as xml), 1)
go

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
select round(@inputString, 1)
go

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
select round(@inputString, 1)
go

select round(0.0, -1)
go

