-- TEST CASE 1: Basic rounding with different decimal places
INSERT INTO TestRound (float_data, decimal_data, int_data) 
VALUES (3.14159, 3.14159, 3);
GO

SELECT * FROM TestRound;
GO

-- TEST CASE 2: Testing ROUND with different data types and decimal places
SELECT 
    ROUND(3.14159, 0) as float_round_0,
    ROUND(3.14159, 2) as float_round_2,
    ROUND(CAST(3.14159 AS DECIMAL(10,5)), 2) as decimal_round_2,
    ROUND(CAST(3 AS INT), 2) as int_round_2;
GO

-- TEST CASE 3: Testing negative decimal places
SELECT 
    ROUND(1234.5678, -1) as round_tens,
    ROUND(1234.5678, -2) as round_hundreds,
    ROUND(1234.5678, -3) as round_thousands;
GO

-- TEST CASE 4: Testing rounding with .5 cases
SELECT 
    ROUND(3.5, 0) as round_up_35,
    ROUND(4.5, 0) as round_up_45,
    ROUND(-3.5, 0) as round_down_neg35,
    ROUND(-4.5, 0) as round_down_neg45;
GO

-- TEST CASE 5: Testing NULL values
SELECT ROUND(NULL, 2) as null_round;
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
SELECT 
    ROUND(@float_val, 2) as float_round,
    ROUND(@decimal_val, 2) as decimal_round,
    ROUND(@money_val, 2) as money_round;
GO

-- TEST CASE 13: Testing edge cases
SELECT 
    ROUND(0.0, 2) as zero_round,
    ROUND(9.99999999, 2) as nine_round,
    ROUND(-0.00001, 2) as neg_small_round;
GO

-- TEST CASE 14: Testing with computed columns
SELECT 
    id,
    float_data,
    round_float_2,
    round_float_2 - float_data as difference
FROM TestRound;
GO

-- TEST CASE 15: Testing type conversion with ROUND
SELECT 
    ROUND(CAST('3.14159' AS FLOAT), 2) as string_to_float_round,
    ROUND(CAST('3.14159' AS DECIMAL(10,5)), 2) as string_to_decimal_round;
GO

-- Clean up
/*
DROP VIEW IF EXISTS dbo.RoundMultipleTypesView;
DROP FUNCTION IF EXISTS dbo.RoundMultipleTypes;
DROP VIEW IF EXISTS dbo.TestRoundView;
DROP VIEW IF EXISTS dbo.RoundDemoView;
DROP FUNCTION IF EXISTS dbo.RoundDecimal;
DROP FUNCTION IF EXISTS dbo.RoundFloat;
DROP TABLE IF EXISTS TestRound;
*/

    