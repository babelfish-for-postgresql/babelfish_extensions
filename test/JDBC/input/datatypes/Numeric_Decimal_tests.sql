------------------------------------------------------------------------
---- 1. Basic Tests
------------------------------------------------------------------------
-- parallel_query_expected

-- Create a comprehensive test table with various NUMERIC and DECIMAL data types
CREATE TABLE numeric_decimal_test_suite (
    id INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Small precision/scale
    numeric_1_0 NUMERIC(1,0),
    decimal_1_0 DECIMAL(1,0),
    numeric_2_1 NUMERIC(2,1),
    decimal_2_1 DECIMAL(2,1),
    numeric_3_2 NUMERIC(3,2),
    decimal_3_2 DECIMAL(3,2),
    
    -- Medium precision/scale
    numeric_5_2 NUMERIC(5,2),
    decimal_5_2 DECIMAL(5,2),
    numeric_9_4 NUMERIC(9,4),
    decimal_9_4 DECIMAL(9,4),
    numeric_10_5 NUMERIC(10,5),
    decimal_10_5 DECIMAL(10,5),
    
    -- High precision
    numeric_17_2 NUMERIC(17,2),
    decimal_17_2 DECIMAL(17,2),
    numeric_18_2 NUMERIC(18,2),
    decimal_18_2 DECIMAL(18,2),
    numeric_19_2 NUMERIC(19,2),
    decimal_19_2 DECIMAL(19,2),
    numeric_28_10 NUMERIC(28,10),
    decimal_28_10 DECIMAL(28,10),
    
    -- Maximum precision
    numeric_38_0 NUMERIC(38,0),
    decimal_38_0 DECIMAL(38,0),
    numeric_38_10 NUMERIC(38,10),
    decimal_38_10 DECIMAL(38,10),
    numeric_38_38 NUMERIC(38,38),
    decimal_38_38 DECIMAL(38,38),
    
    -- Default precision/scale (18,0)
    numeric_default NUMERIC,
    decimal_default DECIMAL
);
GO

-- Test default values (NULL)
INSERT INTO numeric_decimal_test_suite DEFAULT VALUES;
GO

-- Test zero values
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0
);
GO

-- Test small positive values
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    1, 1, 0.1, 0.1, 0.01, 0.01,
    1.23, 1.23, 1.2345, 1.2345, 1.23456, 1.23456,
    12345.67, 12345.67, 12345.67, 12345.67, 12345.67, 12345.67,
    12345.1234567890, 12345.1234567890, 12345, 12345, 12345.1234567890, 12345.1234567890,
    0.00000000000000000000000000000000000001, 0.00000000000000000000000000000000000001, 1, 1
);
GO

-- Test small negative values
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    -1, -1, -0.1, -0.1, -0.01, -0.01,
    -1.23, -1.23, -1.2345, -1.2345, -1.23456, -1.23456,
    -12345.67, -12345.67, -12345.67, -12345.67, -12345.67, -12345.67,
    -12345.1234567890, -12345.1234567890, -12345, -12345, -12345.1234567890, -12345.1234567890,
    -0.00000000000000000000000000000000000001, -0.00000000000000000000000000000000000001, -1, -1
);
GO

-- Test smallest positive values
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    0, 0, 0.1, 0.1, 0.01, 0.01,
    0.01, 0.01, 0.0001, 0.0001, 0.00001, 0.00001,
    0.01, 0.01, 0.01, 0.01, 0.01, 0.01,
    0.0000000001, 0.0000000001, 1, 1, 0.0000000001, 0.0000000001,
    0.00000000000000000000000000000000000001, 0.00000000000000000000000000000000000001, 0, 0
);
GO


-- Test rounding behavior
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    5, 5, 1.5, 1.5, 1.55, 1.55,
    123.45, 123.45, 1234.5678, 1234.5678, 1234.56789, 1234.56789,
    12345678901234.56, 12345678901234.56, 123456789012345.67, 123456789012345.67, 1234567890123456.78, 1234567890123456.78,
    1234567890123.4567890123, 1234567890123.4567890123, 12345678901234567890, 12345678901234567890, 
    12345678901234567890.1234567890, 12345678901234567890.1234567890,
    0.12345678901234567890123456789012345678, 0.12345678901234567890123456789012345678, 5, 5
);
GO

-- Test largest negative values (closest to zero)
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    -1, -1, -0.1, -0.1, -0.01, -0.01,
    -0.01, -0.01, -0.0001, -0.0001, -0.00001, -0.00001,
    -0.01, -0.01, -0.01, -0.01, -0.01, -0.01,
    -0.0000000001, -0.0000000001, -1, -1, -0.0000000001, -0.0000000001,
    -0.00000000000000000000000000000000000001, -0.00000000000000000000000000000000000001, -0.1, -0.1
);
GO

-- Verify all inserted values
SELECT * FROM numeric_decimal_test_suite ORDER BY id;
GO

TRUNCATE TABLE numeric_decimal_test_suite
GO


------------------------------------------------------------------------
---- 2. Maximum and Minimum values Tests
------------------------------------------------------------------------

-- Test maximum values for each precision
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    9, 9, 9.9, 9.9, 9.99, 9.99,
    999.99, 999.99, 99999.9999, 99999.9999, 99999.99999, 99999.99999,
    999999999999999.99, 999999999999999.99, 9999999999999999.99, 9999999999999999.99, 99999999999999999.99, 99999999999999999.99,
    99999999999999999.9999999999, 99999999999999999.9999999999, 99999999999999999999999999999999999999, 99999999999999999999999999999999999999, 
    9999999999999999999999999999.9999999999, 9999999999999999999999999999.9999999999,
    0.99999999999999999999999999999999999999, 0.99999999999999999999999999999999999999, 9, 9
);
GO


-- Test minimum values for each precision
INSERT INTO numeric_decimal_test_suite (
    numeric_1_0, decimal_1_0, numeric_2_1, decimal_2_1, numeric_3_2, decimal_3_2,
    numeric_5_2, decimal_5_2, numeric_9_4, decimal_9_4, numeric_10_5, decimal_10_5,
    numeric_17_2, decimal_17_2, numeric_18_2, decimal_18_2, numeric_19_2, decimal_19_2,
    numeric_28_10, decimal_28_10, numeric_38_0, decimal_38_0, numeric_38_10, decimal_38_10,
    numeric_38_38, decimal_38_38, numeric_default, decimal_default
) VALUES (
    -9, -9, -0.9, -0.9, -0.09, -0.09,
    -999.99, -999.99, -99999.9999, -99999.9999, -99999.99999, -99999.99999,
    -999999999999999.99, -999999999999999.99, -9999999999999999.99, -9999999999999999.99, -99999999999999999.99, -99999999999999999.99,
    -99999999999999999.9999999999, -99999999999999999.9999999999, -99999999999999999999999999999999999999, -99999999999999999999999999999999999999, 
    -9999999999999999999999999999.9999999999, -9999999999999999999999999999.9999999999,
    -0.99999999999999999999999999999999999999, -0.99999999999999999999999999999999999999, -9, -9
);
GO


-- Verify all inserted values
SELECT * FROM numeric_decimal_test_suite ORDER BY id;
GO

-- Cleanup
DROP TABLE numeric_decimal_test_suite
GO


------------------------------------------------------------------------
---- 3. Overflow and Precision Loss Tests
------------------------------------------------------------------------

------------------------------------------------------------------------
---- 3.1 Using Constant values and table columns
------------------------------------------------------------------------

-- Testing addition overflow with NUMERIC(1,0) - Expects overflow error when adding 9 + 1
SELECT CAST(9 AS NUMERIC(1,0)) + CAST(1 AS NUMERIC(1,0)) AS result;
GO

-- Testing addition with NUMERIC(5,2) - Verifies correct handling when result reaches maximum precision (999.99 + 0.01 = 1000.00)
SELECT CAST(999.99 AS NUMERIC(5,2)) + CAST(0.01 AS NUMERIC(5,2)) AS result;
GO

-- Testing addition with NUMERIC(19,2) - Tests behavior near maximum value limits
SELECT CAST(99999999999999999.99 AS NUMERIC(19,2)) + CAST(0.01 AS NUMERIC(19,2)) AS result;
GO

-- Testing addition with maximum NUMERIC(38,0) - Verifies overflow at absolute maximum precision
SELECT CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0)) + CAST(1 AS NUMERIC(38,0)) AS result;
GO

-- Testing subtraction with NUMERIC(1,0) - Expects overflow error when result exceeds negative range
SELECT CAST(-9 AS NUMERIC(1,0)) - CAST(1 AS NUMERIC(1,0)) AS result;
GO

-- Testing subtraction with NUMERIC(5,2) - Verifies handling of negative results with decimal places
SELECT CAST(-999.99 AS NUMERIC(5,2)) - CAST(0.01 AS NUMERIC(5,2)) AS result;
GO

-- Testing subtraction with NUMERIC(19,2) - Tests behavior with large negative numbers
SELECT CAST(-99999999999999999.99 AS NUMERIC(19,2)) - CAST(0.01 AS NUMERIC(19,2)) AS result;
GO

-- Testing multiplication with NUMERIC(1,0) - Expects overflow error when multiplying 9 * 2
SELECT CAST(9 AS NUMERIC(1,0)) * CAST(2 AS NUMERIC(1,0)) AS result;
GO

-- Testing multiplication with NUMERIC(5,2) - Verifies handling of decimal multiplication near limits
SELECT CAST(999.99 AS NUMERIC(5,2)) * CAST(2 AS NUMERIC(5,2)) AS result;
GO

-- Testing multiplication with NUMERIC(19,2) - Tests overflow with large numbers
SELECT CAST(99999999999999999.99 AS NUMERIC(19,2)) * CAST(2 AS NUMERIC(19,2)) AS result;
GO

-- Testing multiplication scale expansion - Verifies correct decimal place handling (99.99 * 99.99)
SELECT CAST(99.99 AS NUMERIC(4,2)) * CAST(99.99 AS NUMERIC(4,2)) AS result;
GO

-- Testing maximum precision multiplication - Tests behavior at maximum allowed precision
SELECT CAST(9999999999999999999 AS NUMERIC(19,0)) * CAST(9999999999999999999 AS NUMERIC(19,0)) AS result;
GO

-- Testing simple division with potential precision loss (1/3)
SELECT CAST(1 AS NUMERIC(5,2)) / CAST(3 AS NUMERIC(5,2)) AS result;
GO

-- Testing division with scale expansion - Verifies decimal place handling in division
SELECT CAST(10 AS NUMERIC(2,0)) / CAST(3 AS NUMERIC(2,0)) AS result;
GO

-- Testing division by zero - Verifies error handling for divide by zero operation
SELECT CAST(1 AS NUMERIC(5,2)) / CAST(0 AS NUMERIC(5,2)) AS result;
GO

-- Testing casting with truncation - Verifies behavior when reducing decimal places
SELECT CAST(CAST(123.456 AS NUMERIC(6,3)) AS NUMERIC(5,2)) AS result;
GO

-- Testing casting with different rounding behaviors - Compares truncation vs rounding results
SELECT CAST(CAST(123.456 AS NUMERIC(6,3)) AS NUMERIC(5,2)) AS result_truncated,
       ROUND(CAST(123.456 AS NUMERIC(6,3)), 2) AS result_rounded;
GO

-- Testing casting from larger to smaller precision - Verifies overflow handling
SELECT CAST(CAST(12345.6789 AS NUMERIC(10,4)) AS NUMERIC(6,2)) AS result;
GO

-- Testing power function overflow - Tests behavior with large exponents
SELECT POWER(CAST(10 AS NUMERIC(2,0)), CAST(38 AS NUMERIC(2,0))) AS result;
GO

-- Testing exponential function overflow - Verifies handling of large exponential results
SELECT EXP(CAST(100 AS NUMERIC(3,0))) AS result;
GO

-- Testing aggregate function precision - Tests SUM and AVG with values near precision limits
CREATE TABLE numeric_aggregate_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    value_a NUMERIC(9,2),
    value_b NUMERIC(9,2)
);
GO

-- Insert test data for aggregate function testing
INSERT INTO numeric_aggregate_test (value_a, value_b)
VALUES 
(9999999.99, 0.01),
(9999999.99, 0.01),
(9999999.99, 0.01),
(9999999.99, 0.01),
(9999999.99, 0.01);
GO

-- Testing SUM aggregate function with values near precision limits
SELECT SUM(value_a) AS sum_result FROM numeric_aggregate_test;
GO

-- Testing AVG aggregate function with potential precision loss
SELECT AVG(value_a) AS avg_result FROM numeric_aggregate_test;
GO


-- Testing precision loss in product calculation and aggregation
SELECT value_a,
       value_b,
       value_a * value_b AS individual_product,
       SUM(value_a * value_b) OVER () AS sum_of_products
FROM numeric_aggregate_test;
GO

-- Testing overflow in complex expressions with multiple operations (multiplication, power, and division)
SELECT CAST(9999999.99 AS NUMERIC(9,2)) * 
       POWER(CAST(10 AS NUMERIC(2,0)), CAST(10 AS NUMERIC(2,0))) / 
       CAST(0.01 AS NUMERIC(3,2)) AS result;
GO

-- Testing precision loss in addition with different scales (NUMERIC(5,2) + NUMERIC(5,3))
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(67.891 AS NUMERIC(5,3)) AS result;
GO

-- Testing precision loss in multiplication with different scales (NUMERIC(4,2) * NUMERIC(5,3))
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(56.789 AS NUMERIC(5,3)) AS result;
GO

-- Testing precision loss in division with different scales (NUMERIC(5,2) / NUMERIC(4,4))
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(0.0067 AS NUMERIC(4,4)) AS result;
GO

-- Testing boundary case for maximum precision addition with DECIMAL(38,0)
SELECT CAST(9999999999999999999999999999999999999 AS DECIMAL(38,0)) + 
       CAST(0 AS DECIMAL(38,0)) AS result;
GO

-- Testing boundary case for maximum scale multiplication with DECIMAL(38,37)
SELECT CAST(0.9999999999999999999999999999999999999 AS DECIMAL(38,37)) * 
       CAST(0.9999999999999999999999999999999999999 AS DECIMAL(38,37)) AS result;
GO

-- Testing scale change behavior in multiplication of DECIMAL values
SELECT CAST(123.45 AS DECIMAL(5,2)) * CAST(67.89 AS DECIMAL(4,2)) AS result;
GO

-- Testing scale change behavior in division of DECIMAL values
SELECT CAST(123.45 AS DECIMAL(5,2)) / CAST(67.89 AS DECIMAL(4,2)) AS result;
GO

-- Testing mixed type arithmetic between INTEGER and DECIMAL
SELECT CAST(2147483647 AS INT) * CAST(1.1 AS DECIMAL(2,1)) AS result;
GO

-- Testing mixed type arithmetic between FLOAT and DECIMAL
SELECT CAST(1.79E+308 AS FLOAT) * CAST(1.1 AS DECIMAL(2,1)) AS result;
GO

-- Testing mixed type arithmetic between MONEY and DECIMAL
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS DECIMAL(2,1)) AS result;
GO

-- Cleanup test table
DROP TABLE numeric_aggregate_test;
GO


------------------------------------------------------------------------
---- 3.2 Using variables
------------------------------------------------------------------------

-- Testing addition overflow with NUMERIC(1,0) - Expects overflow error when adding 9 + 1
DECLARE @num1 NUMERIC(1,0) = 9, @num2 NUMERIC(1,0) = 1;
SELECT @num1 + @num2 AS result;
GO

-- Testing addition with NUMERIC(5,2) - Verifies correct handling when result reaches maximum precision (999.99 + 0.01 = 1000.00)
DECLARE @num1 NUMERIC(5,2) = 999.99, @num2 NUMERIC(5,2) = 0.01;
SELECT @num1 + @num2 AS result;
GO

-- Testing addition with NUMERIC(19,2) - Tests behavior near maximum value limits
DECLARE @num1 NUMERIC(19,2) = 99999999999999999.99, @num2 NUMERIC(19,2) = 0.01;
SELECT @num1 + @num2 AS result;
GO

-- Testing addition with maximum NUMERIC(38,0) - Verifies overflow at absolute maximum precision
DECLARE @num1 NUMERIC(38,0) = 99999999999999999999999999999999999999, @num2 NUMERIC(38,0) = 1;
SELECT @num1 + @num2 AS result;
GO

-- Testing subtraction with NUMERIC(1,0) - Expects overflow error when result exceeds negative range
DECLARE @num1 NUMERIC(1,0) = -9, @num2 NUMERIC(1,0) = 1;
SELECT @num1 - @num2 AS result;
GO

-- Testing subtraction with NUMERIC(5,2) - Verifies handling of negative results with decimal places
DECLARE @num1 NUMERIC(5,2) = -999.99, @num2 NUMERIC(5,2) = 0.01;
SELECT @num1 - @num2 AS result;
GO

-- Testing subtraction with NUMERIC(19,2) - Tests behavior with large negative numbers
DECLARE @num1 NUMERIC(19,2) = -99999999999999999.99, @num2 NUMERIC(19,2) = 0.01;
SELECT @num1 - @num2 AS result;
GO

-- Testing multiplication with NUMERIC(1,0) - Expects overflow error when multiplying 9 * 2
DECLARE @num1 NUMERIC(1,0) = 9, @num2 NUMERIC(1,0) = 2;
SELECT @num1 * @num2 AS result;
GO

-- Testing multiplication with NUMERIC(5,2) - Verifies handling of decimal multiplication near limits
DECLARE @num1 NUMERIC(5,2) = 999.99, @num2 NUMERIC(5,2) = 2;
SELECT @num1 * @num2 AS result;
GO

-- Testing multiplication with NUMERIC(19,2) - Tests overflow with large numbers
DECLARE @num1 NUMERIC(19,2) = 99999999999999999.99, @num2 NUMERIC(19,2) = 2;
SELECT @num1 * @num2 AS result;
GO

-- Testing multiplication scale expansion - Verifies correct decimal place handling (99.99 * 99.99)
DECLARE @num1 NUMERIC(4,2) = 99.99, @num2 NUMERIC(4,2) = 99.99;
SELECT @num1 * @num2 AS result;
GO

-- Testing maximum precision multiplication - Tests behavior at maximum allowed precision
DECLARE @num1 NUMERIC(19,0) = 9999999999999999999, @num2 NUMERIC(19,0) = 9999999999999999999;
SELECT @num1 * @num2 AS result;
GO

-- Testing simple division with potential precision loss (1/3)
DECLARE @num1 NUMERIC(5,2) = 1, @num2 NUMERIC(5,2) = 3;
SELECT @num1 / @num2 AS result;
GO

-- Testing division with scale expansion - Verifies decimal place handling in division
DECLARE @num1 NUMERIC(2,0) = 10, @num2 NUMERIC(2,0) = 3;
SELECT @num1 / @num2 AS result;
GO

-- Testing division by zero - Verifies error handling for divide by zero operation
DECLARE @num1 NUMERIC(5,2) = 1, @num2 NUMERIC(5,2) = 0;
SELECT @num1 / @num2 AS result;
GO

-- Testing casting with truncation - Verifies behavior when reducing decimal places
DECLARE @num NUMERIC(6,3) = 123.456;
SELECT CAST(@num AS NUMERIC(5,2)) AS result;
GO

-- Testing casting with different rounding behaviors - Compares truncation vs rounding results
DECLARE @num NUMERIC(6,3) = 123.456;
SELECT
CAST(@num AS NUMERIC(5,2)) AS result_truncated,
ROUND(@num, 2) AS result_rounded;
GO

-- Testing casting from larger to smaller precision - Verifies overflow handling
DECLARE @num NUMERIC(10,4) = 12345.6789;
SELECT CAST(@num AS NUMERIC(6,2)) AS result;
GO

-- TODO: CREATE JIRA
-- Testing power function overflow - Tests behavior with large exponents
-- DECLARE @base NUMERIC(2,0) = 10, @exp NUMERIC(2,0) = 38;
-- SELECT POWER(@base, @exp) AS result;
-- GO

-- Testing exponential function overflow - Verifies handling of large exponential results
DECLARE @num NUMERIC(3,0) = 100;
SELECT EXP(@num) AS result;
GO

-- Testing overflow in complex expressions with multiple operations (multiplication, power, and division)
DECLARE @num1 NUMERIC(9,2) = 9999999.99, @num2 NUMERIC(2,0) = 10, @num3 NUMERIC(3,2) = 0.01;
SELECT @num1 * POWER(@num2, @num2) / @num3 AS result;
GO

-- Testing precision loss in addition with different scales (NUMERIC(5,2) + NUMERIC(5,3))
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,3) = 67.891;
SELECT @num1 + @num2 AS result;
GO

-- Testing precision loss in multiplication with different scales (NUMERIC(4,2) * NUMERIC(5,3))
DECLARE @num1 NUMERIC(4,2) = 12.34, @num2 NUMERIC(5,3) = 56.789;
SELECT @num1 * @num2 AS result;
GO

-- Testing precision loss in division with different scales (NUMERIC(5,2) / NUMERIC(4,4))
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(4,4) = 0.0067;
SELECT @num1 / @num2 AS result;
GO

-- Testing boundary case for maximum precision addition with DECIMAL(38,0)
DECLARE @num1 DECIMAL(38,0) = 9999999999999999999999999999999999999, @num2 DECIMAL(38,0) = 0;
SELECT @num1 + @num2 AS result;
GO

-- Testing boundary case for maximum scale multiplication with DECIMAL(38,37)
DECLARE @num1 DECIMAL(38,37) = 0.9999999999999999999999999999999999999, @num2 DECIMAL(38,37) = 0.9999999999999999999999999999999999999;
SELECT @num1 * @num2 AS result;
GO

-- Testing scale change behavior in multiplication of DECIMAL values
DECLARE @num1 DECIMAL(5,2) = 123.45, @num2 DECIMAL(4,2) = 67.89;
SELECT @num1 * @num2 AS result;
GO

-- Testing scale change behavior in division of DECIMAL values
DECLARE @num1 DECIMAL(5,2) = 123.45, @num2 DECIMAL(4,2) = 67.89;
SELECT @num1 / @num2 AS result;
GO

-- Testing mixed type arithmetic between INTEGER and DECIMAL
DECLARE @num1 INT = 2147483647, @num2 DECIMAL(2,1) = 1.1;
SELECT @num1 * @num2 AS result;
GO

-- Testing mixed type arithmetic between FLOAT and DECIMAL
DECLARE @num1 FLOAT = 1.79E+308, @num2 DECIMAL(2,1) = 1.1;
SELECT @num1 * @num2 AS result;
GO

-- Testing mixed type arithmetic between MONEY and DECIMAL
DECLARE @num1 MONEY = 922337203685477.5807, @num2 DECIMAL(2,1) = 1.1;
SELECT @num1 * @num2 AS result;
GO


------------------------------------------------------------------------
---- 4. Arithmetic Operations Tests
------------------------------------------------------------------------

------------------------------------------------------------------------
---- 4.1 Using Constant values 
------------------------------------------------------------------------
-- Addition (+) operator tests
SELECT 'Addition (+) Operator Tests' AS test_description;
GO

-- NUMERIC + NUMERIC (Same Type)
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- DECIMAL + DECIMAL (Same Type)
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(678.90 AS DECIMAL(5,2)) AS result;
GO

-- NUMERIC + NUMERIC (Different Precision/Scale)
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(6789.012 AS NUMERIC(8,3)) AS result;
GO

-- DECIMAL + DECIMAL (Different Precision/Scale)
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(6789.012 AS DECIMAL(8,3)) AS result;
GO

-- NUMERIC + NUMERIC (Maximum Precision)
SELECT CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0)) + CAST(1 AS NUMERIC(38,0)) AS NUMERIC(38,0) AS result;
GO

-- DECIMAL + DECIMAL (Maximum Precision)
SELECT CAST(9999999999999999999999999999999999999 AS DECIMAL(38,0)) + CAST(1 AS DECIMAL(38,0)) AS DECIMAL(38,0) AS result;
GO

-- NUMERIC + NUMERIC (Maximum Scale)
SELECT CAST(0.9999999999999999999999999999999999999 AS NUMERIC(38,37)) + CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,37)) AS result;
GO

-- NUMERIC + INT
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678 AS INT) AS result;
GO

-- DECIMAL + BIGINT
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- NUMERIC + SMALLINT
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(32767 AS SMALLINT) AS result;
GO

-- DECIMAL + TINYINT
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(255 AS TINYINT) AS result;
GO

-- NUMERIC + FLOAT
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS FLOAT) AS result;
GO

-- DECIMAL + REAL
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(678.90 AS REAL) AS result;
GO

-- NUMERIC + MONEY
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS MONEY) AS result;
GO

-- DECIMAL + SMALLMONEY
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(678.90 AS SMALLMONEY) AS result;
GO

-- NUMERIC + BIT
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(1 AS BIT) AS result;
GO

-- Subtraction (-) operator tests
SELECT 'Subtraction (-) Operator Tests' AS test_description;
GO

-- NUMERIC - NUMERIC (Same Type)
SELECT CAST(678.90 AS NUMERIC(5,2)) - CAST(123.45 AS NUMERIC(5,2)) AS result;
GO

-- DECIMAL - DECIMAL (Same Type)
SELECT CAST(678.90 AS DECIMAL(5,2)) - CAST(123.45 AS DECIMAL(5,2)) AS result;
GO

-- NUMERIC - NUMERIC (Different Precision/Scale)
SELECT CAST(6789.012 AS NUMERIC(8,3)) - CAST(123.45 AS NUMERIC(5,2)) AS result;
GO

-- NUMERIC - INT
SELECT CAST(678.90 AS NUMERIC(5,2)) - CAST(123 AS INT) AS result;
GO

-- DECIMAL - FLOAT
SELECT CAST(678.90 AS DECIMAL(5,2)) - CAST(123.45 AS FLOAT) AS result;
GO

-- NUMERIC - MONEY
SELECT CAST(678.90 AS NUMERIC(5,2)) - CAST(123.45 AS MONEY) AS result;
GO

-- Multiplication (*) operator tests
SELECT 'Multiplication (*) Operator Tests' AS test_description;
GO

-- NUMERIC * NUMERIC (Same Type)
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(56.78 AS NUMERIC(4,2)) AS result;
GO

-- DECIMAL * DECIMAL (Same Type)
SELECT CAST(12.34 AS DECIMAL(4,2)) * CAST(56.78 AS DECIMAL(4,2)) AS result;
GO

-- NUMERIC * NUMERIC (Different Precision/Scale)
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(567.890 AS NUMERIC(6,3)) AS result;
GO

-- NUMERIC * NUMERIC (Potential Overflow)
SELECT TRY_CAST(CAST(9999999999 AS NUMERIC(10,0)) * CAST(9999999999 AS NUMERIC(10,0)) AS NUMERIC(20,0)) AS result;
GO

-- NUMERIC * INT
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(56 AS INT) AS result;
GO

-- DECIMAL * FLOAT
SELECT CAST(12.34 AS DECIMAL(4,2)) * CAST(56.78 AS FLOAT) AS result;
GO

-- NUMERIC * MONEY
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(56.78 AS MONEY) AS result;
GO

-- Division (/) operator tests
SELECT 'Division (/) Operator Tests' AS test_description;
GO

-- NUMERIC / NUMERIC (Same Type)
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(2.50 AS NUMERIC(5,2)) AS result;
GO

-- DECIMAL / DECIMAL (Same Type)
SELECT CAST(123.45 AS DECIMAL(5,2)) / CAST(2.50 AS DECIMAL(5,2)) AS result;
GO

-- NUMERIC / NUMERIC (Different Precision/Scale)
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(0.25 AS NUMERIC(3,2)) AS result;
GO

-- NUMERIC / NUMERIC (Small Divisor)
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(0.01 AS NUMERIC(3,2)) AS result;
GO

-- NUMERIC / NUMERIC (Division by Zero)
SELECT TRY_CAST(CAST(123.45 AS NUMERIC(5,2)) / CAST(0.00 AS NUMERIC(3,2)) AS NUMERIC(10,2)) AS result;
GO

-- NUMERIC / INT
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(5 AS INT) AS result;
GO

-- DECIMAL / FLOAT
SELECT CAST(123.45 AS DECIMAL(5,2)) / CAST(5.0 AS FLOAT) AS result;
GO

-- NUMERIC / MONEY
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(5.0 AS MONEY) AS result;
GO

-- Modulo (%) operator tests
SELECT 'Modulo (%) Operator Tests' AS test_description;
GO

-- NUMERIC % NUMERIC (Same Type)
SELECT CAST(123.45 AS NUMERIC(5,2)) % CAST(10.00 AS NUMERIC(5,2)) AS result;
GO

-- DECIMAL % DECIMAL (Same Type)
SELECT CAST(123.45 AS DECIMAL(5,2)) % CAST(10.00 AS DECIMAL(5,2)) AS result;
GO

-- NUMERIC % NUMERIC (Different Precision/Scale)
SELECT CAST(123.45 AS NUMERIC(5,2)) % CAST(10.500 AS NUMERIC(5,3)) AS result;
GO

-- NUMERIC % NUMERIC (Modulo by Zero)
SELECT TRY_CAST(CAST(123.45 AS NUMERIC(5,2)) % CAST(0.00 AS NUMERIC(3,2)) AS NUMERIC(5,2)) AS result;
GO

-- NUMERIC % INT
SELECT CAST(123.45 AS NUMERIC(5,2)) % CAST(10 AS INT) AS result;
GO

-- DECIMAL % FLOAT
SELECT CAST(123.45 AS DECIMAL(5,2)) % CAST(10.0 AS FLOAT) AS result;
GO

-- NUMERIC % MONEY
SELECT CAST(123.45 AS NUMERIC(5,2)) % CAST(10.0 AS MONEY) AS result;
GO

-- Unary minus (-) operator tests
SELECT 'Unary Minus (-) Operator Tests' AS test_description;
GO

-- Unary Minus NUMERIC
SELECT -CAST(123.45 AS NUMERIC(5,2)) AS result;
GO

-- Unary Minus DECIMAL
SELECT -CAST(123.45 AS DECIMAL(5,2)) AS result;
GO

-- Unary Minus Maximum Negative NUMERIC
SELECT -CAST(-9999999999999999999999999999999999999 AS NUMERIC(38,0)) AS result;
GO

-- Complex arithmetic expressions
SELECT 'Complex Arithmetic Expressions' AS test_description;
GO

-- Complex Expression 1: NUMERIC + (NUMERIC * INT)
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS NUMERIC(5,2)) * CAST(2 AS INT) AS result;
GO

-- Complex Expression 2: (NUMERIC + NUMERIC) * INT
SELECT (CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS NUMERIC(5,2))) * CAST(2 AS INT) AS result;
GO

-- Complex Expression 3: NUMERIC + (NUMERIC / INT) - INT
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS NUMERIC(5,2)) / CAST(2 AS INT) - CAST(50 AS INT) AS result;
GO

-- Complex Expression 4: (NUMERIC * NUMERIC) / (INT + INT)
SELECT CAST(123.45 AS NUMERIC(5,2)) * CAST(678.90 AS NUMERIC(5,2)) / (CAST(2 AS INT) + CAST(3 AS INT)) AS result;
GO

-- Complex Expression 5: (NUMERIC % INT) + (NUMERIC * FLOAT)
SELECT CAST(123.45 AS NUMERIC(5,2)) % CAST(10 AS INT) + CAST(678.90 AS NUMERIC(5,2)) * CAST(0.5 AS FLOAT) AS result;
GO

-- Mixed NUMERIC and DECIMAL operations
SELECT 'Mixed NUMERIC and DECIMAL Operations' AS test_description;
GO

-- NUMERIC + DECIMAL
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS DECIMAL(5,2)) AS result;
GO

-- NUMERIC - DECIMAL
SELECT CAST(678.90 AS NUMERIC(5,2)) - CAST(123.45 AS DECIMAL(5,2)) AS result;
GO

-- NUMERIC * DECIMAL
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(56.78 AS DECIMAL(4,2)) AS result;
GO

-- NUMERIC / DECIMAL
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(2.50 AS DECIMAL(5,2)) AS result;
GO

-- NUMERIC % DECIMAL
SELECT CAST(123.45 AS NUMERIC(5,2)) % CAST(10.00 AS DECIMAL(5,2)) AS result;
GO

-- Operations with extreme values
SELECT 'Operations with Extreme Values' AS test_description;
GO

-- Smallest Positive NUMERIC + Smallest Positive NUMERIC
SELECT CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,37)) + 
       CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,37)) AS result;
GO

-- Largest NUMERIC - Smallest Positive NUMERIC
SELECT CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0)) - 
       CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,37)) AS result;
GO

-- Largest NUMERIC / Largest NUMERIC
SELECT CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0)) / 
       CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0)) AS result;
GO

------------------------------------------------------------------------
---- 4.2 Using variables
------------------------------------------------------------------------

-- NUMERIC + NUMERIC (Same Type)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 678.90;
SELECT @num1 + @num2 AS result;
GO

-- DECIMAL + DECIMAL (Same Type)
DECLARE @dec1 DECIMAL(5,2) = 123.45, @dec2 DECIMAL(5,2) = 678.90;
SELECT @dec1 + @dec2 AS result;
GO

-- NUMERIC + NUMERIC (Different Precision/Scale)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(8,3) = 6789.012;
SELECT @num1 + @num2 AS result;
GO

-- DECIMAL + DECIMAL (Different Precision/Scale)
DECLARE @dec1 DECIMAL(5,2) = 123.45, @dec2 DECIMAL(8,3) = 6789.012;
SELECT @dec1 + @dec2 AS result;
GO

-- NUMERIC + NUMERIC (Maximum Precision)
DECLARE @num1 NUMERIC(38,0) = 9999999999999999999999999999999999999, @num2 NUMERIC(38,0) = 1;
SELECT @num1 + @num2 AS NUMERIC(38,0) AS result;
GO

-- DECIMAL + DECIMAL (Maximum Precision)
DECLARE @dec1 DECIMAL(38,0) = 9999999999999999999999999999999999999, @dec2 DECIMAL(38,0) = 1;
SELECT @dec1 + @dec2 AS DECIMAL(38,0) AS result;
GO

-- NUMERIC + NUMERIC (Maximum Scale)
DECLARE @num1 NUMERIC(38,37) = 0.9999999999999999999999999999999999999, @num2 NUMERIC(38,37) = 0.0000000000000000000000000000000000001;
SELECT @num1 + @num2 AS result;
GO

-- NUMERIC + INT
DECLARE @num NUMERIC(5,2) = 123.45, @int INT = 678;
SELECT @num + @int AS result;
GO

-- DECIMAL + BIGINT
DECLARE @dec DECIMAL(5,2) = 123.45, @bigint BIGINT = 9223372036854775807;
SELECT @dec + @bigint AS result;
GO

-- NUMERIC + SMALLINT
DECLARE @num NUMERIC(5,2) = 123.45, @smallint SMALLINT = 32767;
SELECT @num + @smallint AS result;
GO

-- DECIMAL + TINYINT
DECLARE @dec DECIMAL(5,2) = 123.45, @tinyint TINYINT = 255;
SELECT @dec + @tinyint AS result;
GO

-- NUMERIC + FLOAT
DECLARE @num NUMERIC(5,2) = 123.45, @float FLOAT = 678.90;
SELECT @num + @float AS result;
GO

-- DECIMAL + REAL
DECLARE @dec DECIMAL(5,2) = 123.45, @real REAL = 678.90;
SELECT @dec + @real AS result;
GO

-- NUMERIC + MONEY
DECLARE @num NUMERIC(5,2) = 123.45, @money MONEY = 678.90;
SELECT @num + @money AS result;
GO

-- DECIMAL + SMALLMONEY
DECLARE @dec DECIMAL(5,2) = 123.45, @smallmoney SMALLMONEY = 678.90;
SELECT @dec + @smallmoney AS result;
GO

-- NUMERIC + BIT
DECLARE @num NUMERIC(5,2) = 123.45, @bit BIT = 1;
SELECT @num + @bit AS result;
GO

-- Subtraction (-) operator tests
SELECT 'Subtraction (-) Operator Tests' AS test_description;
GO

-- NUMERIC - NUMERIC (Same Type)
DECLARE @num1 NUMERIC(5,2) = 678.90, @num2 NUMERIC(5,2) = 123.45;
SELECT @num1 - @num2 AS result;
GO

-- DECIMAL - DECIMAL (Same Type)
DECLARE @dec1 DECIMAL(5,2) = 678.90, @dec2 DECIMAL(5,2) = 123.45;
SELECT @dec1 - @dec2 AS result;
GO

-- NUMERIC - NUMERIC (Different Precision/Scale)
DECLARE @num1 NUMERIC(8,3) = 6789.012, @num2 NUMERIC(5,2) = 123.45;
SELECT @num1 - @num2 AS result;
GO

-- NUMERIC - INT
DECLARE @num NUMERIC(5,2) = 678.90, @int INT = 123;
SELECT @num - @int AS result;
GO

-- DECIMAL - FLOAT
DECLARE @dec DECIMAL(5,2) = 678.90, @float FLOAT = 123.45;
SELECT @dec - @float AS result;
GO

-- NUMERIC - MONEY
DECLARE @num NUMERIC(5,2) = 678.90, @money MONEY = 123.45;
SELECT @num - @money AS result;
GO

-- Multiplication (*) operator tests
SELECT 'Multiplication (*) Operator Tests' AS test_description;
GO

-- NUMERIC * NUMERIC (Same Type)
DECLARE @num1 NUMERIC(4,2) = 12.34, @num2 NUMERIC(4,2) = 56.78;
SELECT @num1 * @num2 AS result;
GO

-- DECIMAL * DECIMAL (Same Type)
DECLARE @dec1 DECIMAL(4,2) = 12.34, @dec2 DECIMAL(4,2) = 56.78;
SELECT @dec1 * @dec2 AS result;
GO

-- NUMERIC * NUMERIC (Different Precision/Scale)
DECLARE @num1 NUMERIC(4,2) = 12.34, @num2 NUMERIC(6,3) = 567.890;
SELECT @num1 * @num2 AS result;
GO

-- NUMERIC * NUMERIC (Potential Overflow)
DECLARE @num1 NUMERIC(10,0) = 9999999999, @num2 NUMERIC(10,0) = 9999999999;
SELECT TRY_CAST(@num1 * @num2 AS NUMERIC(20,0)) AS result;
GO

-- NUMERIC * INT
DECLARE @num NUMERIC(4,2) = 12.34, @int INT = 56;
SELECT @num * @int AS result;
GO

-- DECIMAL * FLOAT
DECLARE @dec DECIMAL(4,2) = 12.34, @float FLOAT = 56.78;
SELECT @dec * @float AS result;
GO

-- NUMERIC * MONEY
DECLARE @num NUMERIC(4,2) = 12.34, @money MONEY = 56.78;
SELECT @num * @money AS result;
GO

-- Division (/) operator tests
SELECT 'Division (/) Operator Tests' AS test_description;
GO

-- NUMERIC / NUMERIC (Same Type)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 2.50;
SELECT @num1 / @num2 AS result;
GO

-- DECIMAL / DECIMAL (Same Type)
DECLARE @dec1 DECIMAL(5,2) = 123.45, @dec2 DECIMAL(5,2) = 2.50;
SELECT @dec1 / @dec2 AS result;
GO

-- NUMERIC / NUMERIC (Different Precision/Scale)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(3,2) = 0.25;
SELECT @num1 / @num2 AS result;
GO

-- NUMERIC / NUMERIC (Small Divisor)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(3,2) = 0.01;
SELECT @num1 / @num2 AS result;
GO

-- NUMERIC / NUMERIC (Division by Zero)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(3,2) = 0.00;
SELECT TRY_CAST(@num1 / @num2 AS NUMERIC(10,2)) AS result;
GO

-- NUMERIC / INT
DECLARE @num NUMERIC(5,2) = 123.45, @int INT = 5;
SELECT @num / @int AS result;
GO

-- DECIMAL / FLOAT
DECLARE @dec DECIMAL(5,2) = 123.45, @float FLOAT = 5.0;
SELECT @dec / @float AS result;
GO

-- NUMERIC / MONEY
DECLARE @num NUMERIC(5,2) = 123.45, @money MONEY = 5.0;
SELECT @num / @money AS result;
GO

-- Modulo (%) operator tests
SELECT 'Modulo (%) Operator Tests' AS test_description;
GO

-- NUMERIC % NUMERIC (Same Type)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 10.00;
SELECT @num1 % @num2 AS result;
GO

-- DECIMAL % DECIMAL (Same Type)
DECLARE @dec1 DECIMAL(5,2) = 123.45, @dec2 DECIMAL(5,2) = 10.00;
SELECT @dec1 % @dec2 AS result;
GO

-- NUMERIC % NUMERIC (Different Precision/Scale)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,3) = 10.500;
SELECT @num1 % @num2 AS result;
GO

-- NUMERIC % NUMERIC (Modulo by Zero)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(3,2) = 0.00;
SELECT TRY_CAST(@num1 % @num2 AS NUMERIC(5,2)) AS result;
GO

-- NUMERIC % INT
DECLARE @num NUMERIC(5,2) = 123.45, @int INT = 10;
SELECT @num % @int AS result;
GO

-- DECIMAL % FLOAT
DECLARE @dec DECIMAL(5,2) = 123.45, @float FLOAT = 10.0;
SELECT @dec % @float AS result;
GO

-- NUMERIC % MONEY
DECLARE @num NUMERIC(5,2) = 123.45, @money MONEY = 10.0;
SELECT @num % @money AS result;
GO

-- Unary minus (-) operator tests
SELECT 'Unary Minus (-) Operator Tests' AS test_description;
GO

-- Unary Minus NUMERIC
DECLARE @num NUMERIC(5,2) = 123.45;
SELECT -@num AS result;
GO

-- Unary Minus DECIMAL
DECLARE @dec DECIMAL(5,2) = 123.45;
SELECT -@dec AS result;
GO

-- Unary Minus Maximum Negative NUMERIC
DECLARE @num NUMERIC(38,0) = -9999999999999999999999999999999999999;
SELECT -@num AS result;
GO

-- Complex arithmetic expressions
SELECT 'Complex Arithmetic Expressions' AS test_description;
GO

-- Complex Expression 1: NUMERIC + (NUMERIC * INT)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 678.90, @int INT = 2;
SELECT @num1 + @num2 * @int AS result;
GO

-- Complex Expression 2: (NUMERIC + NUMERIC) * INT
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 678.90, @int INT = 2;
SELECT (@num1 + @num2) * @int AS result;
GO

-- Complex Expression 3: NUMERIC + (NUMERIC / INT) - INT
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 678.90, @int INT = 2, @int2 INT = 50;
SELECT @num1 + @num2 / @int - @int2 AS result;
GO

-- Complex Expression 4: (NUMERIC * NUMERIC) / (INT + INT)
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 678.90, @int1 INT = 2, @int2 INT = 3;
SELECT (@num1 * @num2) / (@int1 + @int2) AS result;
GO

-- Complex Expression 5: (NUMERIC % INT) + (NUMERIC * FLOAT)
DECLARE @num1 NUMERIC(5,2) = 123.45, @int INT = 10, @float FLOAT = 0.5;
SELECT @num1 % @int + @num1 * @float AS result;
GO

-- Mixed NUMERIC and DECIMAL operations
SELECT 'Mixed NUMERIC and DECIMAL Operations' AS test_description;
GO

-- NUMERIC + DECIMAL
DECLARE @num NUMERIC(5,2) = 123.45, @dec DECIMAL(5,2) = 678.90;
SELECT @num + @dec AS result;
GO

-- NUMERIC - DECIMAL
DECLARE @num NUMERIC(5,2) = 678.90, @dec DECIMAL(5,2) = 123.45;
SELECT @num - @dec AS result;
GO

-- NUMERIC * DECIMAL
DECLARE @num NUMERIC(4,2) = 12.34, @dec DECIMAL(4,2) = 56.78;
SELECT @num * @dec AS result;
GO

-- NUMERIC / DECIMAL
DECLARE @num NUMERIC(5,2) = 123.45, @dec DECIMAL(5,2) = 2.50;
SELECT @num / @dec AS result;
GO

-- NUMERIC % DECIMAL
DECLARE @num NUMERIC(5,2) = 123.45, @dec DECIMAL(5,2) = 10.00;
SELECT @num % @dec AS result;
GO

-- Operations with extreme values
SELECT 'Operations with Extreme Values' AS test_description;
GO

-- Smallest Positive NUMERIC + Smallest Positive NUMERIC
DECLARE @num1 NUMERIC(38,37) = 0.0000000000000000000000000000000000001, @num2 NUMERIC(38,37) = 0.0000000000000000000000000000000000001;
SELECT @num1 + @num2 AS result;
GO

-- Largest NUMERIC - Smallest Positive NUMERIC
DECLARE @num1 NUMERIC(38,0) = 9999999999999999999999999999999999999, @num2 NUMERIC(38,37) = 0.0000000000000000000000000000000000001;
SELECT @num1 - @num2 AS result;
GO

-- Largest NUMERIC / Largest NUMERIC
DECLARE @num1 NUMERIC(38,0) = 9999999999999999999999999999999999999, @num2 NUMERIC(38,0) = 9999999999999999999999999999999999999;
SELECT @num1 / @num2 AS result;
GO

------------------------------------------------------------------------
---- 5. Mathematical Functions Tests
------------------------------------------------------------------------

------------------------------------------------------------------------
---- 5.1 ABS Function Tests
------------------------------------------------------------------------

SELECT ABS(CAST(123.45 AS NUMERIC(5,2))) AS result;      -- Positive NUMERIC
GO
SELECT ABS(CAST(-123.45 AS NUMERIC(5,2))) AS result;     -- Negative NUMERIC
GO
SELECT ABS(CAST(0 AS NUMERIC(5,2))) AS result;           -- Zero NUMERIC
GO
SELECT ABS(CAST(123.45 AS DECIMAL(5,2))) AS result;      -- Positive DECIMAL
GO
SELECT ABS(CAST(-123.45 AS DECIMAL(5,2))) AS result;     -- Negative DECIMAL
GO
SELECT ABS(CAST(-9999999999999999999999999999999999999 AS NUMERIC(38,0))) AS result;  -- Maximum negative value
GO
SELECT ABS(CAST(NULL AS NUMERIC(5,2))) AS result;        -- NULL value
GO
SELECT ABS(CAST(-0.0000000000000000000000000000000000001 AS NUMERIC(38,37))) AS result;  -- Smallest negative value
GO
SELECT ABS(CAST(-0.00 AS NUMERIC(3,2))) AS result;       -- Negative zero
GO

------------------------------------------------------------------------
---- 5.2 CEILING and FLOOR Function Tests
------------------------------------------------------------------------

-- CEILING tests
SELECT CEILING(CAST(123.45 AS NUMERIC(5,2))) AS result;  -- Positive NUMERIC
GO
SELECT CEILING(CAST(-123.45 AS NUMERIC(5,2))) AS result; -- Negative NUMERIC
GO
SELECT CEILING(CAST(0 AS NUMERIC(5,2))) AS result;       -- Zero NUMERIC
GO
SELECT CEILING(CAST(123.45 AS DECIMAL(5,2))) AS result;  -- Positive DECIMAL
GO
SELECT CEILING(CAST(-123.45 AS DECIMAL(5,2))) AS result; -- Negative DECIMAL
GO
SELECT CEILING(CAST(123.00 AS NUMERIC(5,2))) AS result;  -- Integer value NUMERIC
GO
SELECT CEILING(CAST(NULL AS NUMERIC(5,2))) AS result;    -- NULL value
GO
SELECT CEILING(CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0))) AS result;  -- Maximum value
GO
SELECT CEILING(CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,37))) AS result;  -- Smallest positive value
GO
SELECT CEILING(CAST(999.999 AS NUMERIC(6,3))) AS result; -- Value close to next integer
GO
SELECT CEILING(CAST(-999.001 AS NUMERIC(6,3))) AS result; -- Negative value close to integer
GO

-- FLOOR tests
SELECT FLOOR(CAST(123.45 AS NUMERIC(5,2))) AS result;    -- Positive NUMERIC
GO
SELECT FLOOR(CAST(-123.45 AS NUMERIC(5,2))) AS result;   -- Negative NUMERIC
GO
SELECT FLOOR(CAST(0 AS NUMERIC(5,2))) AS result;         -- Zero NUMERIC
GO
SELECT FLOOR(CAST(123.45 AS DECIMAL(5,2))) AS result;    -- Positive DECIMAL
GO
SELECT FLOOR(CAST(-123.45 AS DECIMAL(5,2))) AS result;   -- Negative DECIMAL
GO
SELECT FLOOR(CAST(123.00 AS DECIMAL(5,2))) AS result;    -- Integer value DECIMAL
GO
SELECT FLOOR(CAST(NULL AS NUMERIC(5,2))) AS result;      -- NULL value
GO
SELECT FLOOR(CAST(-9999999999999999999999999999999999999 AS NUMERIC(38,0))) AS result;  -- Minimum value
GO
SELECT FLOOR(CAST(0.9999999999999999999999999999999999999 AS NUMERIC(38,37))) AS result;  -- Value close to 1
GO
SELECT FLOOR(CAST(999.999 AS NUMERIC(6,3))) AS result;   -- Value close to integer
GO
SELECT FLOOR(CAST(-999.001 AS NUMERIC(6,3))) AS result;  -- Negative value close to next integer
GO

------------------------------------------------------------------------
---- 5.3 ROUND Function Tests
------------------------------------------------------------------------

SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), 0) AS result;     -- Positive NUMERIC 0 decimals
GO
SELECT ROUND(CAST(-123.45 AS NUMERIC(5,2)), 0) AS result;    -- Negative NUMERIC 0 decimals
GO
SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), 1) AS result;     -- Positive NUMERIC 1 decimal
GO
SELECT ROUND(CAST(-123.45 AS NUMERIC(5,2)), 1) AS result;    -- Negative NUMERIC 1 decimal
GO
SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), 2) AS result;     -- Positive NUMERIC 2 decimals
GO
SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), 3) AS result;     -- Positive NUMERIC 3 decimals (more than available)
GO
SELECT ROUND(CAST(123.45 AS DECIMAL(5,2)), 1, 1) AS result;  -- Positive DECIMAL with truncate
GO
SELECT ROUND(CAST(-123.45 AS DECIMAL(5,2)), 1, 1) AS result; -- Negative DECIMAL with truncate
GO
SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), -1) AS result;    -- Positive NUMERIC negative digits (round to tens)
GO
SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), -2) AS result;    -- Positive NUMERIC negative digits (round to hundreds)
GO
SELECT ROUND(CAST(1234.56 AS NUMERIC(6,2)), -3) AS result;   -- Positive NUMERIC negative digits (round to thousands)
GO
SELECT ROUND(CAST(NULL AS NUMERIC(5,2)), 1) AS result;       -- NULL value
GO
SELECT ROUND(CAST(9999999999999999999999999999.9999999999 AS NUMERIC(38,10)), 5) AS result;  -- Maximum precision
GO
SELECT ROUND(CAST(123.456 AS NUMERIC(6,3)), 2) AS result;    -- Round up
GO
SELECT ROUND(CAST(123.454 AS NUMERIC(6,3)), 2) AS result;    -- Round down
GO
SELECT ROUND(CAST(123.455 AS NUMERIC(6,3)), 2) AS result;    -- Round half (banker's rounding)
GO
SELECT ROUND(CAST(-123.456 AS NUMERIC(6,3)), 2) AS result;   -- Negative round up
GO
SELECT ROUND(CAST(-123.454 AS NUMERIC(6,3)), 2) AS result;   -- Negative round down
GO
SELECT ROUND(CAST(-123.455 AS NUMERIC(6,3)), 2) AS result;   -- Negative round half (banker's rounding)
GO
SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), 2, 0) AS result;  -- Explicit round (default)
GO
SELECT ROUND(CAST(123.45 AS NUMERIC(5,2)), 2, 1) AS result;  -- Explicit truncate
GO
SELECT ROUND(CAST(555.55 AS NUMERIC(5,2)), -2, 1) AS result; -- Truncate to hundreds
GO

------------------------------------------------------------------------
---- 5.4 SIGN Function Tests
------------------------------------------------------------------------

SELECT SIGN(CAST(123.45 AS NUMERIC(5,2))) AS result;     -- Positive NUMERIC
GO
SELECT SIGN(CAST(-123.45 AS NUMERIC(5,2))) AS result;    -- Negative NUMERIC
GO
SELECT SIGN(CAST(0 AS NUMERIC(5,2))) AS result;          -- Zero NUMERIC
GO
SELECT SIGN(CAST(123.45 AS DECIMAL(5,2))) AS result;     -- Positive DECIMAL
GO
SELECT SIGN(CAST(-123.45 AS DECIMAL(5,2))) AS result;    -- Negative DECIMAL
GO
SELECT SIGN(CAST(0 AS DECIMAL(5,2))) AS result;          -- Zero DECIMAL
GO
SELECT SIGN(CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,37))) AS result;    -- Smallest positive NUMERIC
GO
SELECT SIGN(CAST(-0.0000000000000000000000000000000000001 AS NUMERIC(38,37))) AS result;   -- Smallest negative NUMERIC
GO
SELECT SIGN(CAST(NULL AS NUMERIC(5,2))) AS result;       -- NULL value
GO
SELECT SIGN(CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0))) AS result;       -- Maximum positive value
GO
SELECT SIGN(CAST(-9999999999999999999999999999999999999 AS NUMERIC(38,0))) AS result;      -- Maximum negative value
GO
SELECT SIGN(CAST(0.00 AS NUMERIC(3,2))) AS result;       -- Zero with decimal places
GO

------------------------------------------------------------------------
---- 5.5 POWER and SQRT Function Tests
------------------------------------------------------------------------

-- POWER tests
SELECT POWER(CAST(12.34 AS NUMERIC(4,2)), 2) AS result;          -- Positive NUMERIC, Integer Power
GO
SELECT POWER(CAST(12.34 AS DECIMAL(4,2)), 2) AS result;          -- Positive DECIMAL, Integer Power
GO
SELECT POWER(CAST(12.34 AS NUMERIC(4,2)), 0.5) AS result;        -- Positive NUMERIC, Decimal Power
GO
SELECT POWER(CAST(12.34 AS DECIMAL(4,2)), 0.5) AS result;        -- Positive DECIMAL, Decimal Power
GO
SELECT POWER(CAST(-12.34 AS NUMERIC(4,2)), 2) AS result;         -- Negative NUMERIC, Even Integer Power
GO
SELECT POWER(CAST(-12.34 AS NUMERIC(4,2)), 3) AS result;         -- Negative NUMERIC, Odd Integer Power
GO
SELECT POWER(CAST(0 AS NUMERIC(4,2)), 2) AS result;              -- Zero NUMERIC, Positive Power
GO
SELECT POWER(CAST(12.34 AS NUMERIC(4,2)), 0) AS result;          -- NUMERIC, Zero Power
GO
SELECT POWER(CAST(12.34 AS NUMERIC(4,2)), -2) AS result;         -- NUMERIC, Negative Power
GO
SELECT TRY_CAST(POWER(CAST(10 AS NUMERIC(2,0)), 38) AS NUMERIC(38,0)) AS result;  -- Large NUMERIC, causing overflow
GO
SELECT POWER(CAST(NULL AS NUMERIC(5,2)), 2) AS result;           -- NULL base
GO
SELECT POWER(CAST(12.34 AS NUMERIC(4,2)), NULL) AS result;       -- NULL exponent
GO
SELECT POWER(CAST(0 AS NUMERIC(1,0)), 0) AS result;              -- Zero raised to zero power
GO
SELECT POWER(CAST(0 AS NUMERIC(1,0)), -1) AS result;             -- Zero raised to negative power (should error)
GO
SELECT POWER(CAST(-12.34 AS NUMERIC(4,2)), 0.5) AS result;       -- Negative base, fractional power (should error)
GO
SELECT POWER(CAST(0.5 AS NUMERIC(2,1)), 100) AS result;          -- Fractional base, large power (approaches zero)
GO
SELECT POWER(CAST(1.5 AS NUMERIC(2,1)), 100) AS result;          -- Fractional base > 1, large power
GO

-- SQRT tests
SELECT SQRT(CAST(144 AS NUMERIC(3,0))) AS result;                -- Positive NUMERIC
GO
SELECT SQRT(CAST(144 AS DECIMAL(3,0))) AS result;                -- Positive DECIMAL
GO
SELECT SQRT(CAST(0 AS NUMERIC(3,0))) AS result;                  -- Zero NUMERIC
GO
SELECT SQRT(CAST(12.25 AS NUMERIC(4,2))) AS result;              -- Decimal NUMERIC
GO
SELECT SQRT(CAST(-144 AS NUMERIC(3,0))) AS result;               -- Negative NUMERIC (should return NULL)
GO
SELECT SQRT(CAST(NULL AS NUMERIC(5,2))) AS result;               -- NULL value
GO
SELECT SQRT(CAST(2 AS NUMERIC(1,0))) AS result;                  -- Irrational result
GO
SELECT SQRT(CAST(9999999999999999 AS NUMERIC(16,0))) AS result;  -- Large number
GO
SELECT SQRT(CAST(0.0000000001 AS NUMERIC(11,10))) AS result;     -- Small number
GO

-- SQUARE tests
SELECT SQUARE(CAST(12.34 AS NUMERIC(4,2))) AS result;            -- NUMERIC
GO
SELECT SQUARE(CAST(12.34 AS DECIMAL(4,2))) AS result;            -- DECIMAL
GO
SELECT SQUARE(CAST(-12.34 AS NUMERIC(4,2))) AS result;           -- Negative value
GO
SELECT SQUARE(CAST(0 AS NUMERIC(1,0))) AS result;                -- Zero
GO
SELECT SQUARE(CAST(NULL AS NUMERIC(4,2))) AS result;             -- NULL value
GO
SELECT SQUARE(CAST(9999 AS NUMERIC(4,0))) AS result;             -- Large number
GO
SELECT SQUARE(CAST(0.0001 AS NUMERIC(5,4))) AS result;           -- Small number
GO

------------------------------------------------------------------------
---- 5.6 LOG, LOG10, EXP Function Tests
------------------------------------------------------------------------

-- LOG tests
SELECT LOG(CAST(100 AS NUMERIC(3,0))) AS result;                 -- Positive NUMERIC
GO
SELECT LOG(CAST(100 AS DECIMAL(3,0))) AS result;                 -- Positive DECIMAL
GO
SELECT LOG(CAST(0.5 AS NUMERIC(2,1))) AS result;                 -- NUMERIC between 0 and 1
GO
SELECT LOG(CAST(0 AS NUMERIC(1,0))) AS result;                   -- Zero NUMERIC (should return error or NULL)
GO
SELECT LOG(CAST(-100 AS NUMERIC(3,0))) AS result;                -- Negative NUMERIC (should return error or NULL)
GO
SELECT LOG(CAST(1 AS NUMERIC(1,0))) AS result;                   -- LOG of 1 (should be 0)
GO
SELECT LOG(CAST(2.718281828459045 AS NUMERIC(16,15))) AS result; -- LOG of e (should be 1)
GO
SELECT LOG(CAST(NULL AS NUMERIC(3,0))) AS result;                -- NULL value
GO
SELECT LOG(CAST(0.0000000001 AS NUMERIC(11,10))) AS result;      -- Very small positive number
GO
SELECT LOG(CAST(9999999999 AS NUMERIC(10,0))) AS result;         -- Very large number
GO

-- LOG10 tests
SELECT LOG10(CAST(100 AS NUMERIC(3,0))) AS result;               -- Positive NUMERIC
GO
SELECT LOG10(CAST(100 AS DECIMAL(3,0))) AS result;               -- Positive DECIMAL
GO
SELECT LOG10(CAST(0.5 AS NUMERIC(2,1))) AS result;               -- NUMERIC between 0 and 1
GO
SELECT LOG10(CAST(0 AS NUMERIC(1,0))) AS result;                 -- Zero NUMERIC (should return error or NULL)
GO
SELECT LOG10(CAST(-100 AS NUMERIC(3,0))) AS result;              -- Negative NUMERIC (should return error or NULL)
GO
SELECT LOG10(CAST(1 AS NUMERIC(1,0))) AS result;                 -- LOG10 of 1 (should be 0)
GO
SELECT LOG10(CAST(10 AS NUMERIC(2,0))) AS result;                -- LOG10 of 10 (should be 1)
GO
SELECT LOG10(CAST(NULL AS NUMERIC(3,0))) AS result;              -- NULL value
GO
SELECT LOG10(CAST(0.0000000001 AS NUMERIC(11,10))) AS result;    -- Very small positive number
GO
SELECT LOG10(CAST(9999999999 AS NUMERIC(10,0))) AS result;       -- Very large number
GO

-- EXP tests
SELECT EXP(CAST(1 AS NUMERIC(1,0))) AS result;                   -- Positive NUMERIC
GO
SELECT EXP(CAST(-1 AS NUMERIC(1,0))) AS result;                  -- Negative NUMERIC
GO
SELECT EXP(CAST(0 AS NUMERIC(1,0))) AS result;                   -- Zero NUMERIC
GO
SELECT EXP(CAST(1 AS DECIMAL(1,0))) AS result;                   -- Positive DECIMAL
GO
SELECT TRY_CAST(EXP(CAST(1000 AS NUMERIC(4,0))) AS FLOAT) AS result;  -- Large value causing overflow
GO
SELECT EXP(CAST(NULL AS NUMERIC(1,0))) AS result;                -- NULL value
GO
SELECT EXP(CAST(0.5 AS NUMERIC(2,1))) AS result;                 -- Fractional value
GO
SELECT EXP(CAST(-0.5 AS NUMERIC(2,1))) AS result;                -- Negative fractional value
GO
SELECT EXP(CAST(10 AS NUMERIC(2,0))) AS result;                  -- Larger positive value
GO
SELECT EXP(CAST(-10 AS NUMERIC(2,0))) AS result;                 -- Larger negative value
GO

------------------------------------------------------------------------
---- 5.7 Trigonometric Function Tests
------------------------------------------------------------------------

-- SIN tests
SELECT SIN(CAST(1.0 AS NUMERIC(2,1))) AS result;                 -- NUMERIC
GO
SELECT SIN(CAST(1.0 AS DECIMAL(2,1))) AS result;                 -- DECIMAL
GO
SELECT SIN(CAST(0 AS NUMERIC(1,0))) AS result;                   -- Zero
GO
SELECT SIN(CAST(PI() AS NUMERIC(5,4))) AS result;                -- PI
GO
SELECT SIN(CAST(PI()/2 AS NUMERIC(5,4))) AS result;              -- PI/2 (90 degrees)
GO
SELECT SIN(CAST(PI()/6 AS NUMERIC(5,4))) AS result;              -- PI/6 (30 degrees)
GO
SELECT SIN(CAST(NULL AS NUMERIC(2,1))) AS result;                -- NULL value
GO
SELECT SIN(CAST(-PI()/2 AS NUMERIC(5,4))) AS result;             -- -PI/2 (-90 degrees)
GO
SELECT SIN(CAST(2*PI() AS NUMERIC(5,4))) AS result;              -- 2*PI (360 degrees)
GO
SELECT SIN(CAST(100 AS NUMERIC(3,0))) AS result;                 -- Large value
GO

-- COS tests
SELECT COS(CAST(1.0 AS NUMERIC(2,1))) AS result;                 -- NUMERIC
GO
SELECT COS(CAST(1.0 AS DECIMAL(2,1))) AS result;                 -- DECIMAL
GO
SELECT COS(CAST(0 AS NUMERIC(1,0))) AS result;                   -- Zero
GO
SELECT COS(CAST(PI() AS NUMERIC(5,4))) AS result;                -- PI
GO
SELECT COS(CAST(PI()/2 AS NUMERIC(5,4))) AS result;              -- PI/2 (90 degrees)
GO
SELECT COS(CAST(PI()/3 AS NUMERIC(5,4))) AS result;              -- PI/3 (60 degrees)
GO
SELECT COS(CAST(NULL AS NUMERIC(2,1))) AS result;                -- NULL value
GO
SELECT COS(CAST(-PI() AS NUMERIC(5,4))) AS result;               -- -PI (-180 degrees)
GO
SELECT COS(CAST(2*PI() AS NUMERIC(5,4))) AS result;              -- 2*PI (360 degrees)
GO
SELECT COS(CAST(100 AS NUMERIC(3,0))) AS result;                 -- Large value
GO

-- TAN tests
SELECT TAN(CAST(1.0 AS NUMERIC(2,1))) AS result;                 -- NUMERIC
GO
SELECT TAN(CAST(1.0 AS DECIMAL(2,1))) AS result;                 -- DECIMAL
GO
SELECT TAN(CAST(0 AS NUMERIC(1,0))) AS result;                   -- Zero
GO
SELECT TAN(CAST(PI()/4 AS NUMERIC(5,4))) AS result;              -- PI/4 (45 degrees)
GO
SELECT TAN(CAST(PI() AS NUMERIC(5,4))) AS result;                -- PI (180 degrees)
GO
SELECT TAN(CAST(NULL AS NUMERIC(2,1))) AS result;                -- NULL value
GO
SELECT TAN(CAST(-PI()/4 AS NUMERIC(5,4))) AS result;             -- -PI/4 (-45 degrees)
GO
SELECT TAN(CAST(PI()/2 - 0.000001 AS NUMERIC(8,6))) AS result;   -- Near PI/2 (near 90 degrees)
GO
SELECT TAN(CAST(3*PI()/2 - 0.000001 AS NUMERIC(8,6))) AS result; -- Near 3*PI/2 (near 270 degrees)
GO

------------------------------------------------------------------------
---- 5.8 Inverse Trigonometric Function Tests
------------------------------------------------------------------------

-- ASIN tests
SELECT ASIN(CAST(0.5 AS NUMERIC(2,1))) AS result;                -- NUMERIC
GO
SELECT ASIN(CAST(0.5 AS DECIMAL(2,1))) AS result;                -- DECIMAL
GO
SELECT ASIN(CAST(0 AS NUMERIC(1,0))) AS result;                  -- Zero
GO
SELECT ASIN(CAST(1 AS NUMERIC(1,0))) AS result;                  -- One
GO
SELECT ASIN(CAST(-1 AS NUMERIC(1,0))) AS result;                 -- Negative one
GO
SELECT ASIN(CAST(2 AS NUMERIC(1,0))) AS result;                  -- Out of range (should return error or NULL)
GO
SELECT ASIN(CAST(-2 AS NUMERIC(1,0))) AS result;                 -- Out of range negative (should return error or NULL)
GO
SELECT ASIN(CAST(NULL AS NUMERIC(2,1))) AS result;               -- NULL value
GO
SELECT ASIN(CAST(0.7071067811865475 AS NUMERIC(17,16))) AS result; -- sin(PI/4)
GO
SELECT ASIN(CAST(0.8660254037844386 AS NUMERIC(17,16))) AS result; -- sin(PI/3)
GO

-- ACOS tests
SELECT ACOS(CAST(0.5 AS NUMERIC(2,1))) AS result;                -- NUMERIC
GO
SELECT ACOS(CAST(0.5 AS DECIMAL(2,1))) AS result;                -- DECIMAL
GO
SELECT ACOS(CAST(0 AS NUMERIC(1,0))) AS result;                  -- Zero
GO
SELECT ACOS(CAST(1 AS NUMERIC(1,0))) AS result;                  -- One
GO
SELECT ACOS(CAST(-1 AS NUMERIC(1,0))) AS result;                 -- Negative one
GO
SELECT ACOS(CAST(2 AS NUMERIC(1,0))) AS result;                  -- Out of range (should return error or NULL)
GO
SELECT ACOS(CAST(-2 AS NUMERIC(1,0))) AS result;                 -- Out of range negative (should return error or NULL)
GO
SELECT ACOS(CAST(NULL AS NUMERIC(2,1))) AS result;               -- NULL value
GO
SELECT ACOS(CAST(0.7071067811865475 AS NUMERIC(17,16))) AS result; -- cos(PI/4)
GO
SELECT ACOS(CAST(0.5 AS NUMERIC(2,1))) AS result;                -- cos(PI/3)
GO

-- ATAN tests
SELECT ATAN(CAST(1.0 AS NUMERIC(2,1))) AS result;                -- NUMERIC
GO
SELECT ATAN(CAST(1.0 AS DECIMAL(2,1))) AS result;                -- DECIMAL
GO
SELECT ATAN(CAST(0 AS NUMERIC(1,0))) AS result;                  -- Zero
GO
SELECT ATAN(CAST(1000000 AS NUMERIC(7,0))) AS result;            -- Large value
GO
SELECT ATAN(CAST(-1.0 AS NUMERIC(2,1))) AS result;               -- Negative value
GO
SELECT ATAN(CAST(NULL AS NUMERIC(2,1))) AS result;               -- NULL value
GO
SELECT ATAN(CAST(1.7320508075688772 AS NUMERIC(17,16))) AS result; -- tan(PI/3)
GO
SELECT ATAN(CAST(-1.7320508075688772 AS NUMERIC(17,16))) AS result; -- tan(-PI/3)
GO
SELECT ATAN(CAST(POWER(10, 10) AS NUMERIC(11,0))) AS result;     -- Very large value (approaches PI/2)
GO
SELECT ATAN(CAST(-POWER(10, 10) AS NUMERIC(11,0))) AS result;    -- Very large negative value (approaches -PI/2)
GO

-- ATAN2 tests
SELECT ATAN2(CAST(1.0 AS NUMERIC(2,1)), CAST(1.0 AS NUMERIC(2,1))) AS result;    -- NUMERIC/NUMERIC
GO
SELECT ATAN2(CAST(1.0 AS DECIMAL(2,1)), CAST(1.0 AS DECIMAL(2,1))) AS result;    -- DECIMAL/DECIMAL
GO
SELECT ATAN2(CAST(0 AS NUMERIC(1,0)), CAST(1 AS NUMERIC(1,0))) AS result;        -- Zero Y, Positive X
GO
SELECT ATAN2(CAST(1 AS NUMERIC(1,0)), CAST(0 AS NUMERIC(1,0))) AS result;        -- Positive Y, Zero X
GO
SELECT ATAN2(CAST(0 AS NUMERIC(1,0)), CAST(-1 AS NUMERIC(1,0))) AS result;       -- Zero Y, Negative X
GO
SELECT ATAN2(CAST(-1 AS NUMERIC(1,0)), CAST(0 AS NUMERIC(1,0))) AS result;       -- Negative Y, Zero X
GO
SELECT ATAN2(CAST(0 AS NUMERIC(1,0)), CAST(0 AS NUMERIC(1,0))) AS result;        -- Zero Y, Zero X (undefined)
GO
SELECT ATAN2(CAST(NULL AS NUMERIC(2,1)), CAST(1.0 AS NUMERIC(2,1))) AS result;   -- NULL Y
GO
SELECT ATAN2(CAST(1.0 AS NUMERIC(2,1)), CAST(NULL AS NUMERIC(2,1))) AS result;   -- NULL X
GO
SELECT ATAN2(CAST(1.0 AS NUMERIC(2,1)), CAST(-1.0 AS NUMERIC(2,1))) AS result;   -- Positive Y, Negative X (Quadrant 2)
GO
SELECT ATAN2(CAST(-1.0 AS NUMERIC(2,1)), CAST(-1.0 AS NUMERIC(2,1))) AS result;  -- Negative Y, Negative X (Quadrant 3)
GO
SELECT ATAN2(CAST(-1.0 AS NUMERIC(2,1)), CAST(1.0 AS NUMERIC(2,1))) AS result;   -- Negative Y, Positive X (Quadrant 4)
GO
SELECT ATAN2(CAST(100 AS NUMERIC(3,0)), CAST(0.001 AS NUMERIC(4,3))) AS result;  -- Large Y, Small X (approaches PI/2)
GO
SELECT ATAN2(CAST(0.001 AS NUMERIC(4,3)), CAST(100 AS NUMERIC(3,0))) AS result;  -- Small Y, Large X (approaches 0)
GO

------------------------------------------------------------------------
---- 5.9 Additional Mathematical Functions
------------------------------------------------------------------------

-- Angle conversion functions
SELECT DEGREES(CAST(PI() AS NUMERIC(5,4))) AS result;            -- Convert radians to degrees (PI)
GO
SELECT DEGREES(CAST(PI()/2 AS NUMERIC(5,4))) AS result;          -- Convert radians to degrees (PI/2)
GO
SELECT DEGREES(CAST(PI()/4 AS NUMERIC(5,4))) AS result;          -- Convert radians to degrees (PI/4)
GO
SELECT DEGREES(CAST(2*PI() AS NUMERIC(5,4))) AS result;          -- Convert radians to degrees (2*PI)
GO
SELECT DEGREES(CAST(0 AS NUMERIC(1,0))) AS result;               -- Convert radians to degrees (0)
GO
SELECT DEGREES(CAST(NULL AS NUMERIC(5,4))) AS result;            -- NULL value
GO

SELECT RADIANS(CAST(180 AS NUMERIC(3,0))) AS result;             -- Convert degrees to radians (180)
GO
SELECT RADIANS(CAST(90 AS NUMERIC(2,0))) AS result;              -- Convert degrees to radians (90)
GO
SELECT RADIANS(CAST(45 AS NUMERIC(2,0))) AS result;              -- Convert degrees to radians (45)
GO
SELECT RADIANS(CAST(360 AS NUMERIC(3,0))) AS result;             -- Convert degrees to radians (360)
GO
SELECT RADIANS(CAST(0 AS NUMERIC(1,0))) AS result;               -- Convert degrees to radians (0)
GO
SELECT RADIANS(CAST(NULL AS NUMERIC(3,0))) AS result;            -- NULL value
GO

SELECT PI() AS result;                                           -- PI constant
GO

------------------------------------------------------------------------
---- 6. Type Conversion Tests
------------------------------------------------------------------------

------------------------------------------------------------------------
---- 6.1 Conversion using CAST()
------------------------------------------------------------------------
-- BIT -> NUMERIC(3,1)
SELECT CAST(0 AS NUMERIC(3,1)), CAST(1 AS NUMERIC(3,1));
GO

-- BIT -> DECIMAL(5,2)
SELECT CAST(0 AS DECIMAL(5,2)), CAST(1 AS DECIMAL(5,2));
GO

-- TINYINT -> NUMERIC(5,2)
SELECT CAST(0 AS NUMERIC(5,2)), CAST(127 AS NUMERIC(5,2)), CAST(255 AS NUMERIC(5,2));
GO

-- TINYINT -> DECIMAL(8,4)
SELECT CAST(0 AS DECIMAL(8,4)), CAST(127 AS DECIMAL(8,4)), CAST(255 AS DECIMAL(8,4));
GO

-- SMALLINT -> NUMERIC(8,2)
SELECT CAST(-32768 AS NUMERIC(8,2)), CAST(0 AS NUMERIC(8,2)), CAST(32767 AS NUMERIC(8,2));
GO

-- SMALLINT -> DECIMAL(10,5)
SELECT CAST(-32768 AS DECIMAL(10,5)), CAST(0 AS DECIMAL(10,5)), CAST(32767 AS DECIMAL(10,5));
GO

-- INT -> NUMERIC(12,2)
SELECT CAST(-2147483648 AS NUMERIC(12,2)), CAST(0 AS NUMERIC(12,2)), CAST(2147483647 AS NUMERIC(12,2));
GO

-- INT -> DECIMAL(15,6)
SELECT CAST(-2147483648 AS DECIMAL(15,6)), CAST(0 AS DECIMAL(15,6)), CAST(2147483647 AS DECIMAL(15,6));
GO

-- BIGINT -> NUMERIC(20,0)
SELECT CAST(-9223372036854775808 AS NUMERIC(20,0)), CAST(0 AS NUMERIC(20,0)), CAST(9223372036854775807 AS NUMERIC(20,0));
GO

-- BIGINT -> DECIMAL(25,5)
SELECT CAST(-9223372036854775808 AS DECIMAL(25,5)), CAST(0 AS DECIMAL(25,5)), CAST(9223372036854775807 AS DECIMAL(25,5));
GO

-- FLOAT -> NUMERIC(10,5)
SELECT CAST(-1234.56789 AS NUMERIC(10,5)), CAST(0 AS NUMERIC(10,5)), CAST(1234.56789 AS NUMERIC(10,5));
GO

-- FLOAT -> DECIMAL(18,10)
SELECT CAST(-1234.56789 AS DECIMAL(18,10)), CAST(0 AS DECIMAL(18,10)), CAST(1234.56789 AS DECIMAL(18,10));
GO

-- REAL -> NUMERIC(10,5)
SELECT CAST(CAST(-1234.56789 AS REAL) AS NUMERIC(10,5)), CAST(CAST(0 AS REAL) AS NUMERIC(10,5)), CAST(CAST(1234.56789 AS REAL) AS NUMERIC(10,5));
GO

-- REAL -> DECIMAL(16,8)
SELECT CAST(CAST(-1234.56789 AS REAL) AS DECIMAL(16,8)), CAST(CAST(0 AS REAL) AS DECIMAL(16,8)), CAST(CAST(1234.56789 AS REAL) AS DECIMAL(16,8));
GO

-- MONEY -> NUMERIC(19,4)
SELECT CAST(CAST(-922337203685477.5808 AS MONEY) AS NUMERIC(19,4)), CAST(CAST(0 AS MONEY) AS NUMERIC(19,4)), CAST(CAST(922337203685477.5807 AS MONEY) AS NUMERIC(19,4));
GO

-- MONEY -> DECIMAL(22,6)
SELECT CAST(CAST(-922337203685477.5808 AS MONEY) AS DECIMAL(22,6)), CAST(CAST(0 AS MONEY) AS DECIMAL(22,6)), CAST(CAST(922337203685477.5807 AS MONEY) AS DECIMAL(22,6));
GO

-- SMALLMONEY -> NUMERIC(10,4)
SELECT CAST(CAST(-214748.3648 AS SMALLMONEY) AS NUMERIC(10,4)), CAST(CAST(0 AS SMALLMONEY) AS NUMERIC(10,4)), CAST(CAST(214748.3647 AS SMALLMONEY) AS NUMERIC(10,4));
GO

-- SMALLMONEY -> DECIMAL(12,6)
SELECT CAST(CAST(-214748.3648 AS SMALLMONEY) AS DECIMAL(12,6)), CAST(CAST(0 AS SMALLMONEY) AS DECIMAL(12,6)), CAST(CAST(214748.3647 AS SMALLMONEY) AS DECIMAL(12,6));
GO

-- CHAR -> NUMERIC(10,2)
SELECT CAST('123.45' AS NUMERIC(10,2)), CAST('0' AS NUMERIC(10,2)), CAST('-987.65' AS NUMERIC(10,2));
GO

-- CHAR -> DECIMAL(15,5)
SELECT CAST('123.45' AS DECIMAL(15,5)), CAST('0' AS DECIMAL(15,5)), CAST('-987.65' AS DECIMAL(15,5));
GO

-- VARCHAR -> NUMERIC(10,2)
SELECT CAST('123.45' AS NUMERIC(10,2)), CAST('0' AS NUMERIC(10,2)), CAST('-987.65' AS NUMERIC(10,2));
GO

-- VARCHAR -> DECIMAL(18,9)
SELECT CAST('123.45' AS DECIMAL(18,9)), CAST('0' AS DECIMAL(18,9)), CAST('-987.65' AS DECIMAL(18,9));
GO

-- NCHAR -> NUMERIC(10,2)
SELECT CAST(N'123.45' AS NUMERIC(10,2)), CAST(N'0' AS NUMERIC(10,2)), CAST(N'-987.65' AS NUMERIC(10,2));
GO

-- NCHAR -> DECIMAL(20,10)
SELECT CAST(N'123.45' AS DECIMAL(20,10)), CAST(N'0' AS DECIMAL(20,10)), CAST(N'-987.65' AS DECIMAL(20,10));
GO

-- NVARCHAR -> NUMERIC(10,2)
SELECT CAST(N'123.45' AS NUMERIC(10,2)), CAST(N'0' AS NUMERIC(10,2)), CAST(N'-987.65' AS NUMERIC(10,2));
GO

-- NVARCHAR -> DECIMAL(22,12)
SELECT CAST(N'123.45' AS DECIMAL(22,12)), CAST(N'0' AS DECIMAL(22,12)), CAST(N'-987.65' AS DECIMAL(22,12));
GO

-- DATE -> NUMERIC(8,0)
SELECT CAST(CAST('2023-01-01' AS DATE) AS NUMERIC(8,0)), CAST(CAST('2023-06-15' AS DATE) AS NUMERIC(8,0)), CAST(CAST('2023-12-31' AS DATE) AS NUMERIC(8,0));
GO

-- DATE -> DECIMAL(10,0)
SELECT CAST(CAST('2023-01-01' AS DATE) AS DECIMAL(10,0)), CAST(CAST('2023-06-15' AS DATE) AS DECIMAL(10,0)), CAST(CAST('2023-12-31' AS DATE) AS DECIMAL(10,0));
GO

-- TIME -> NUMERIC(10,7)
SELECT CAST(CAST('00:00:00' AS TIME) AS NUMERIC(10,7)), CAST(CAST('12:30:45' AS TIME) AS NUMERIC(10,7)), CAST(CAST('23:59:59' AS TIME) AS NUMERIC(10,7));
GO

-- TIME -> DECIMAL(12,9)
SELECT CAST(CAST('00:00:00' AS TIME) AS DECIMAL(12,9)), CAST(CAST('12:30:45' AS TIME) AS DECIMAL(12,9)), CAST(CAST('23:59:59' AS TIME) AS DECIMAL(12,9));
GO

-- DATETIME -> NUMERIC(20,3)
SELECT CAST(CAST('2023-01-01 00:00:00' AS DATETIME) AS NUMERIC(20,3)), CAST(CAST('2023-06-15 12:30:45' AS DATETIME) AS NUMERIC(20,3)), CAST(CAST('2023-12-31 23:59:59' AS DATETIME) AS NUMERIC(20,3));
GO

-- DATETIME -> DECIMAL(22,5)
SELECT CAST(CAST('2023-01-01 00:00:00' AS DATETIME) AS DECIMAL(22,5)), CAST(CAST('2023-06-15 12:30:45' AS DATETIME) AS DECIMAL(22,5)), CAST(CAST('2023-12-31 23:59:59' AS DATETIME) AS DECIMAL(22,5));
GO

-- DATETIME2 -> NUMERIC(20,7)
SELECT CAST(CAST('2023-01-01 00:00:00' AS DATETIME2) AS NUMERIC(20,7)), CAST(CAST('2023-06-15 12:30:45.1234567' AS DATETIME2) AS NUMERIC(20,7)), CAST(CAST('2023-12-31 23:59:59.9999999' AS DATETIME2) AS NUMERIC(20,7));
GO

-- DATETIME2 -> DECIMAL(24,9)
SELECT CAST(CAST('2023-01-01 00:00:00' AS DATETIME2) AS DECIMAL(24,9)), CAST(CAST('2023-06-15 12:30:45.1234567' AS DATETIME2) AS DECIMAL(24,9)), CAST(CAST('2023-12-31 23:59:59.9999999' AS DATETIME2) AS DECIMAL(24,9));
GO

-- SMALLDATETIME -> NUMERIC(20,0)
SELECT CAST(CAST('2023-01-01 00:00:00' AS SMALLDATETIME) AS NUMERIC(20,0)), CAST(CAST('2023-06-15 12:30:00' AS SMALLDATETIME) AS NUMERIC(20,0)), CAST(CAST('2023-12-31 23:59:00' AS SMALLDATETIME) AS NUMERIC(20,0));
GO

-- SMALLDATETIME -> DECIMAL(18,0)
SELECT CAST(CAST('2023-01-01 00:00:00' AS SMALLDATETIME) AS DECIMAL(18,0)), CAST(CAST('2023-06-15 12:30:00' AS SMALLDATETIME) AS DECIMAL(18,0)), CAST(CAST('2023-12-31 23:59:00' AS SMALLDATETIME) AS DECIMAL(18,0));
GO

-- BINARY -> NUMERIC(10,0)
SELECT TRY_CAST(CONVERT(VARBINARY(4), 123) AS NUMERIC(10,0)), TRY_CAST(CONVERT(VARBINARY(4), 456) AS NUMERIC(10,0)), TRY_CAST(CONVERT(VARBINARY(4), 789) AS NUMERIC(10,0));
GO

-- BINARY -> DECIMAL(12,0)
SELECT TRY_CAST(CONVERT(VARBINARY(4), 123) AS DECIMAL(12,0)), TRY_CAST(CONVERT(VARBINARY(4), 456) AS DECIMAL(12,0)), TRY_CAST(CONVERT(VARBINARY(4), 789) AS DECIMAL(12,0));
GO

-- SCIENTIFIC NOTATION -> NUMERIC(20,10)
SELECT CAST('1.23E+3' AS NUMERIC(20,10)), CAST('4.56E-2' AS NUMERIC(20,10)), CAST('7.89E+0' AS NUMERIC(20,10));
GO

-- SCIENTIFIC NOTATION -> DECIMAL(25,15)
SELECT CAST('1.23E+3' AS DECIMAL(25,15)), CAST('4.56E-2' AS DECIMAL(25,15)), CAST('7.89E+0' AS DECIMAL(25,15));
GO

-- DECIMAL FORMATS -> NUMERIC(10,2)
SELECT TRY_CAST('123.45' AS NUMERIC(10,2)), TRY_CAST('123,45' AS NUMERIC(10,2)), TRY_CAST('$123.45' AS NUMERIC(10,2));
GO

-- DECIMAL FORMATS -> DECIMAL(15,5)
SELECT TRY_CAST('123.45' AS DECIMAL(15,5)), TRY_CAST('123,45' AS DECIMAL(15,5)), TRY_CAST('$123.45' AS DECIMAL(15,5));
GO

-- SQL_VARIANT -> NUMERIC(10,2)
SELECT CAST(CAST(123.45 AS SQL_VARIANT) AS NUMERIC(10,2)), CAST(CAST(0 AS SQL_VARIANT) AS NUMERIC(10,2)), CAST(CAST(-987.65 AS SQL_VARIANT) AS NUMERIC(10,2));
GO

-- SQL_VARIANT -> DECIMAL(16,8)
SELECT CAST(CAST(123.45 AS SQL_VARIANT) AS DECIMAL(16,8)), CAST(CAST(0 AS SQL_VARIANT) AS DECIMAL(16,8)), CAST(CAST(-987.65 AS SQL_VARIANT) AS DECIMAL(16,8));
GO

-- ERROR CASES -> NUMERIC(10,2)
SELECT TRY_CAST('abc' AS NUMERIC(10,2)), TRY_CAST('123.45.67' AS NUMERIC(10,2)), TRY_CAST('' AS NUMERIC(10,2)), TRY_CAST(NULL AS NUMERIC(10,2));
GO

-- ERROR CASES -> DECIMAL(12,4)
SELECT TRY_CAST('abc' AS DECIMAL(12,4)), TRY_CAST('123.45.67' AS DECIMAL(12,4)), TRY_CAST('' AS DECIMAL(12,4)), TRY_CAST(NULL AS DECIMAL(12,4));
GO

-- OVERFLOW -> NUMERIC(5,2)
SELECT TRY_CAST('12345.67' AS NUMERIC(5,2)), TRY_CAST('-12345.67' AS NUMERIC(5,2)), TRY_CAST('999.999' AS NUMERIC(5,2));
GO

-- OVERFLOW -> DECIMAL(4,1)
SELECT TRY_CAST('12345.67' AS DECIMAL(4,1)), TRY_CAST('-12345.67' AS DECIMAL(4,1)), TRY_CAST('999.999' AS DECIMAL(4,1));
GO

-- MAX PRECISION -> NUMERIC(38,10)
SELECT CAST('9999999999999999999999999999.9999999999' AS NUMERIC(38,10));
GO

-- MAX PRECISION -> DECIMAL(38,10)
SELECT CAST('9999999999999999999999999999.9999999999' AS DECIMAL(38,10));
GO

-- NUMERIC -> NUMERIC (different precision/scale)
SELECT CAST(CAST(123.456789 AS NUMERIC(10,6)) AS NUMERIC(8,2)), CAST(CAST(123.456789 AS NUMERIC(10,6)) AS NUMERIC(12,8));
GO

-- DECIMAL -> DECIMAL (different precision/scale)
SELECT CAST(CAST(123.456789 AS DECIMAL(10,6)) AS DECIMAL(8,2)), CAST(CAST(123.456789 AS DECIMAL(10,6)) AS DECIMAL(12,8));
GO

-- NUMERIC -> DECIMAL
SELECT CAST(CAST(123.456789 AS NUMERIC(10,6)) AS DECIMAL(8,2)), CAST(CAST(123.456789 AS NUMERIC(10,6)) AS DECIMAL(12,8));
GO

-- DECIMAL -> NUMERIC
SELECT CAST(CAST(123.456789 AS DECIMAL(10,6)) AS NUMERIC(8,2)), CAST(CAST(123.456789 AS DECIMAL(10,6)) AS NUMERIC(12,8));
GO

-- NUMERIC with MIN/MAX scale -> NUMERIC/DECIMAL
SELECT CAST(CAST(123.456789 AS NUMERIC(10,0)) AS NUMERIC(12,5)), CAST(CAST(123.456789 AS NUMERIC(10,9)) AS DECIMAL(15,4));
GO

-- DECIMAL with MIN/MAX scale -> NUMERIC/DECIMAL
SELECT CAST(CAST(123.456789 AS DECIMAL(10,0)) AS NUMERIC(12,5)), CAST(CAST(123.456789 AS DECIMAL(10,9)) AS DECIMAL(15,4));
GO

-- NUMERIC with MIN/MAX precision -> NUMERIC/DECIMAL
SELECT CAST(CAST(123.456789 AS NUMERIC(1,0)) AS NUMERIC(5,2)), CAST(CAST(123.456789 AS NUMERIC(38,10)) AS DECIMAL(20,5));
GO

-- DECIMAL with MIN/MAX precision -> NUMERIC/DECIMAL
SELECT CAST(CAST(123.456789 AS DECIMAL(1,0)) AS NUMERIC(5,2)), CAST(CAST(123.456789 AS DECIMAL(38,10)) AS DECIMAL(20,5));
GO

-- Edge case: precision = scale
SELECT CAST(0.123456 AS NUMERIC(6,6)), CAST(0.123456 AS DECIMAL(6,6));
GO

-- Edge case: precision - scale = 1 (one digit before decimal)
SELECT CAST(9.12345 AS NUMERIC(6,5)), CAST(9.12345 AS DECIMAL(6,5));
GO

-- Edge case: scale = 0 (integer only)
SELECT CAST(12345 AS NUMERIC(5,0)), CAST(12345 AS DECIMAL(5,0));
GO

-- Edge case: minimum precision (1)
SELECT CAST(1 AS NUMERIC(1,0)), CAST(1 AS DECIMAL(1,0));
GO

-- Edge case: maximum precision (38)
SELECT CAST(1234567890123456789012345678901234567 AS NUMERIC(38,0)), CAST(1234567890123456789012345678901234567 AS DECIMAL(38,0));
GO

-- Edge case: maximum scale (38 with precision 38)
SELECT CAST(0.12345678901234567890123456789012345678 AS NUMERIC(38,38)), CAST(0.12345678901234567890123456789012345678 AS DECIMAL(38,38));
GO

-- NUMERIC(5,2) -> NUMERIC(8,4) (increase both precision and scale)
SELECT CAST(CAST(123.45 AS NUMERIC(5,2)) AS NUMERIC(8,4));
GO

-- NUMERIC(8,4) -> NUMERIC(5,2) (decrease both precision and scale)
SELECT CAST(CAST(123.4567 AS NUMERIC(8,4)) AS NUMERIC(5,2));
GO

-- NUMERIC(5,2) -> NUMERIC(8,2) (increase precision, same scale)
SELECT CAST(CAST(123.45 AS NUMERIC(5,2)) AS NUMERIC(8,2));
GO

-- NUMERIC(8,2) -> NUMERIC(5,2) (decrease precision, same scale)
SELECT CAST(CAST(123.45 AS NUMERIC(8,2)) AS NUMERIC(5,2));
GO

-- NUMERIC(5,2) -> NUMERIC(5,4) (same precision, increase scale)
SELECT CAST(CAST(12.34 AS NUMERIC(5,2)) AS NUMERIC(5,4));
GO

-- NUMERIC(5,4) -> NUMERIC(5,2) (same precision, decrease scale)
SELECT CAST(CAST(1.2345 AS NUMERIC(5,4)) AS NUMERIC(5,2));
GO

-- NUMERIC(10,5) -> NUMERIC(5,2) (decrease precision, decrease scale)
SELECT CAST(CAST(12345.67890 AS NUMERIC(10,5)) AS NUMERIC(5,2));
GO

-- NUMERIC(5,2) -> NUMERIC(10,5) (increase precision, increase scale)
SELECT CAST(CAST(123.45 AS NUMERIC(5,2)) AS NUMERIC(10,5));
GO

-- NUMERIC(10,2) -> NUMERIC(5,4) (decrease precision, increase scale)
SELECT CAST(CAST(123.45 AS NUMERIC(10,2)) AS NUMERIC(5,4));
GO

-- NUMERIC(5,4) -> NUMERIC(10,2) (increase precision, decrease scale)
SELECT CAST(CAST(1.2345 AS NUMERIC(5,4)) AS NUMERIC(10,2));
GO

-- DECIMAL(5,2) -> DECIMAL(8,4) (increase both precision and scale)
SELECT CAST(CAST(123.45 AS DECIMAL(5,2)) AS DECIMAL(8,4));
GO

-- DECIMAL(8,4) -> DECIMAL(5,2) (decrease both precision and scale)
SELECT CAST(CAST(123.4567 AS DECIMAL(8,4)) AS DECIMAL(5,2));
GO

-- DECIMAL(5,2) -> DECIMAL(8,2) (increase precision, same scale)
SELECT CAST(CAST(123.45 AS DECIMAL(5,2)) AS DECIMAL(8,2));
GO

-- DECIMAL(8,2) -> DECIMAL(5,2) (decrease precision, same scale)
SELECT CAST(CAST(123.45 AS DECIMAL(8,2)) AS DECIMAL(5,2));
GO

-- JIRA: BABEL-5662
-- DECIMAL(5,2) -> DECIMAL(5,4) (same precision, increase scale)
-- SELECT CAST(CAST(12.34 AS DECIMAL(5,2)) AS DECIMAL(5,4));
-- GO

-- DECIMAL(5,4) -> DECIMAL(5,2) (same precision, decrease scale)
SELECT CAST(CAST(1.2345 AS DECIMAL(5,4)) AS DECIMAL(5,2));
GO

-- JIRA: BABEL-5662
-- DECIMAL(10,5) -> DECIMAL(5,2) (decrease precision, decrease scale)
-- SELECT CAST(CAST(12345.67890 AS DECIMAL(10,5)) AS DECIMAL(5,2));
-- GO

-- DECIMAL(5,2) -> DECIMAL(10,5) (increase precision, increase scale)
SELECT CAST(CAST(123.45 AS DECIMAL(5,2)) AS DECIMAL(10,5));
GO

-- JIRA: BABEL-5662
-- DECIMAL(10,2) -> DECIMAL(5,4) (decrease precision, increase scale)
-- SELECT CAST(CAST(123.45 AS DECIMAL(10,2)) AS DECIMAL(5,4));
-- GO

-- DECIMAL(5,4) -> DECIMAL(10,2) (increase precision, decrease scale)
SELECT CAST(CAST(1.2345 AS DECIMAL(5,4)) AS DECIMAL(10,2));
GO

-- NUMERIC(5,2) -> DECIMAL(8,4) (NUMERIC to DECIMAL, increase both precision and scale)
SELECT CAST(CAST(123.45 AS NUMERIC(5,2)) AS DECIMAL(8,4));
GO

-- DECIMAL(8,4) -> NUMERIC(5,2) (DECIMAL to NUMERIC, decrease both precision and scale)
SELECT CAST(CAST(123.4567 AS DECIMAL(8,4)) AS NUMERIC(5,2));
GO

-- NUMERIC(5,2) -> DECIMAL(8,2) (NUMERIC to DECIMAL, increase precision, same scale)
SELECT CAST(CAST(123.45 AS NUMERIC(5,2)) AS DECIMAL(8,2));
GO

-- DECIMAL(8,2) -> NUMERIC(5,2) (DECIMAL to NUMERIC, decrease precision, same scale)
SELECT CAST(CAST(123.45 AS DECIMAL(8,2)) AS NUMERIC(5,2));
GO

-- NUMERIC(5,2) -> DECIMAL(5,4) (NUMERIC to DECIMAL, same precision, increase scale)
SELECT CAST(CAST(12.34 AS NUMERIC(5,2)) AS DECIMAL(5,4));
GO

-- DECIMAL(5,4) -> NUMERIC(5,2) (DECIMAL to NUMERIC, same precision, decrease scale)
SELECT CAST(CAST(1.2345 AS DECIMAL(5,4)) AS NUMERIC(5,2));
GO

-- Edge cases with rounding
-- NUMERIC(5,2) -> NUMERIC(5,1) (rounding needed)
SELECT CAST(CAST(123.45 AS NUMERIC(5,2)) AS NUMERIC(5,1));
GO

-- DECIMAL(5,2) -> DECIMAL(5,1) (rounding needed)
SELECT CAST(CAST(123.45 AS DECIMAL(5,2)) AS DECIMAL(5,1));
GO

-- NUMERIC(5,2) -> NUMERIC(4,0) (significant rounding needed)
SELECT CAST(CAST(123.45 AS NUMERIC(5,2)) AS NUMERIC(4,0));
GO

-- DECIMAL(5,2) -> DECIMAL(4,0) (significant rounding needed)
SELECT CAST(CAST(123.45 AS DECIMAL(5,2)) AS DECIMAL(4,0));
GO

-- Edge cases with potential overflow
-- NUMERIC(5,2) -> NUMERIC(4,1) (potential overflow)
SELECT TRY_CAST(CAST(999.99 AS NUMERIC(5,2)) AS NUMERIC(4,1));
GO

-- DECIMAL(5,2) -> DECIMAL(4,1) (potential overflow)
SELECT TRY_CAST(CAST(999.99 AS DECIMAL(5,2)) AS DECIMAL(4,1));
GO

-- Edge cases with negative numbers
-- NUMERIC(5,2) -> NUMERIC(5,1) (negative number rounding)
SELECT CAST(CAST(-123.45 AS NUMERIC(5,2)) AS NUMERIC(5,1));
GO

-- DECIMAL(5,2) -> DECIMAL(5,1) (negative number rounding)
SELECT CAST(CAST(-123.45 AS DECIMAL(5,2)) AS DECIMAL(5,1));
GO

-- Edge cases with zero
-- NUMERIC(5,2) -> NUMERIC(3,1) (zero value)
SELECT CAST(CAST(0.00 AS NUMERIC(5,2)) AS NUMERIC(3,1));
GO

-- DECIMAL(5,2) -> DECIMAL(3,1) (zero value)
SELECT CAST(CAST(0.00 AS DECIMAL(5,2)) AS DECIMAL(3,1));
GO

-- Edge cases with maximum precision
-- NUMERIC(38,10) -> NUMERIC(20,5) (from max precision)
SELECT CAST(CAST(12345678901234567890.1234567890 AS NUMERIC(38,10)) AS NUMERIC(20,5));
GO

-- JIRA : BABEL-5662
-- DECIMAL(38,10) -> DECIMAL(20,5) (from max precision)
-- SELECT CAST(CAST(12345678901234567890.1234567890 AS DECIMAL(38,10)) AS DECIMAL(20,5));
-- GO

-- NUMERIC(20,5) -> NUMERIC(38,10) (to max precision)
SELECT CAST(CAST(12345678901234567.12345 AS NUMERIC(20,5)) AS NUMERIC(38,10));
GO

-- DECIMAL(20,5) -> DECIMAL(38,10) (to max precision)
SELECT CAST(CAST(12345678901234567.12345 AS DECIMAL(20,5)) AS DECIMAL(38,10));
GO

-- Edge cases with minimum precision
-- NUMERIC(2,1) -> NUMERIC(1,0) (to min precision)
SELECT CAST(CAST(1.5 AS NUMERIC(2,1)) AS NUMERIC(1,0));
GO

-- DECIMAL(2,1) -> DECIMAL(1,0) (to min precision)
SELECT CAST(CAST(1.5 AS DECIMAL(2,1)) AS DECIMAL(1,0));
GO

-- Edge cases with scale = precision
-- NUMERIC(5,5) -> NUMERIC(3,2) (from all decimal digits)
SELECT CAST(CAST(0.12345 AS NUMERIC(5,5)) AS NUMERIC(3,2));
GO

-- DECIMAL(5,5) -> DECIMAL(3,2) (from all decimal digits)
SELECT CAST(CAST(0.12345 AS DECIMAL(5,5)) AS DECIMAL(3,2));
GO

-- NUMERIC(3,2) -> NUMERIC(5,5) (to all decimal digits)
SELECT CAST(CAST(1.23 AS NUMERIC(3,2)) AS NUMERIC(5,5));
GO

-- JIRA: BABEL-5662
-- DECIMAL(3,2) -> DECIMAL(5,5) (to all decimal digits)
-- SELECT CAST(CAST(1.23 AS DECIMAL(3,2)) AS DECIMAL(5,5));
-- GO

-- Extreme precision differences
-- NUMERIC(38,19) -> NUMERIC(19,0) (halving precision, removing decimals)
SELECT CAST(CAST(1234567890123456789.1234567890123456789 AS NUMERIC(38,19)) AS NUMERIC(19,0));
GO

-- DECIMAL(38,19) -> DECIMAL(19,0) (halving precision, removing decimals)
SELECT CAST(CAST(1234567890123456789.1234567890123456789 AS DECIMAL(38,19)) AS DECIMAL(19,0));
GO

-- NUMERIC(19,0) -> NUMERIC(38,19) (doubling precision, adding decimals)
SELECT CAST(CAST(1234567890123456789 AS NUMERIC(19,0)) AS NUMERIC(38,19));
GO

-- DECIMAL(19,0) -> DECIMAL(38,19) (doubling precision, adding decimals)
SELECT CAST(CAST(1234567890123456789 AS DECIMAL(19,0)) AS DECIMAL(38,19));
GO

-- Extreme scale differences
-- NUMERIC(38,30) -> NUMERIC(38,2) (same precision, large scale reduction)
SELECT CAST(CAST(12345678.123456789012345678901234567890 AS NUMERIC(38,30)) AS NUMERIC(38,2));
GO

-- DECIMAL(38,30) -> DECIMAL(38,2) (same precision, large scale reduction)
SELECT CAST(CAST(12345678.123456789012345678901234567890 AS DECIMAL(38,30)) AS DECIMAL(38,2));
GO

-- NUMERIC(38,2) -> NUMERIC(38,30) (same precision, large scale increase)
SELECT CAST(CAST(12345678.12 AS NUMERIC(38,2)) AS NUMERIC(38,30));
GO

-- DECIMAL(38,2) -> DECIMAL(38,30) (same precision, large scale increase)
SELECT CAST(CAST(12345678.12 AS DECIMAL(38,2)) AS DECIMAL(38,30));
GO

-- UNIQUEIDENTIFIER -> NUMERIC/DECIMAL
-- UNIQUEIDENTIFIER -> NUMERIC
SELECT CAST(CAST('A972C577-DFB0-064E-1189-0154C99310DABC12' AS UNIQUEIDENTIFIER) AS NUMERIC(38,0));
GO

-- UNIQUEIDENTIFIER -> DECIMAL
SELECT CAST(CAST('A972C577-DFB0-064E-1189-0154C99310DABC12' AS UNIQUEIDENTIFIER) AS DECIMAL(38,0));
GO

-- XML -> NUMERIC/DECIMAL
-- XML -> NUMERIC
SELECT CAST(CAST('<root>123</root>' AS XML).value('/root[1]', 'varchar(10)') AS NUMERIC(10,2));
GO

-- XML -> DECIMAL
SELECT CAST(CAST('<root>123.45</root>' AS XML).value('/root[1]', 'varchar(10)') AS DECIMAL(10,2));
GO

-- DATETIMEOFFSET -> NUMERIC/DECIMAL
-- DATETIMEOFFSET -> NUMERIC
SELECT CAST(CAST('2023-01-01 12:30:45 +01:00' AS DATETIMEOFFSET) AS NUMERIC(20,0));
GO

-- DATETIMEOFFSET -> DECIMAL
SELECT CAST(CAST('2023-01-01 12:30:45 +01:00' AS DATETIMEOFFSET) AS DECIMAL(20,0));
GO

-- HIERARCHYID -> NUMERIC/DECIMAL
-- HIERARCHYID -> NUMERIC
SELECT CAST(CAST('/1/2/3/' AS HIERARCHYID) AS NUMERIC(10,0));
GO

-- HIERARCHYID -> DECIMAL
SELECT CAST(CAST('/1/2/3/' AS HIERARCHYID) AS DECIMAL(10,0));
GO

-- GEOMETRY -> NUMERIC/DECIMAL (using STNumPoints() method)
-- GEOMETRY -> NUMERIC
SELECT CAST(GEOMETRY::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 0).STNumPoints() AS NUMERIC(10,0));
GO

-- GEOMETRY -> DECIMAL
SELECT CAST(GEOMETRY::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 0).STNumPoints() AS DECIMAL(10,0));
GO

-- GEOGRAPHY -> NUMERIC/DECIMAL (using STNumPoints() method)
-- GEOGRAPHY -> NUMERIC
SELECT CAST(GEOGRAPHY::STGeomFromText('LINESTRING(-122.34 47.65, -122.35 47.66)', 4326).STNumPoints() AS NUMERIC(10,0));
GO

-- GEOGRAPHY -> DECIMAL
SELECT CAST(GEOGRAPHY::STGeomFromText('LINESTRING(-122.34 47.65, -122.35 47.66)', 4326).STNumPoints() AS DECIMAL(10,0));
GO

-- ROWVERSION/TIMESTAMP -> NUMERIC/DECIMAL
-- Create a temp table with rowversion
CREATE TABLE #temp_rowversion (id INT, rv ROWVERSION);
INSERT INTO #temp_rowversion (id) VALUES (1);
-- ROWVERSION -> NUMERIC
SELECT CAST(rv AS NUMERIC(20,0)) FROM #temp_rowversion;
GO

-- ROWVERSION -> DECIMAL
SELECT CAST(rv AS DECIMAL(20,0)) FROM #temp_rowversion;
DROP TABLE #temp_rowversion;
GO

-- IMAGE -> NUMERIC/DECIMAL (using DATALENGTH)
-- IMAGE -> NUMERIC
SELECT CAST(DATALENGTH(CAST('test' AS IMAGE)) AS NUMERIC(10,0));
GO

-- IMAGE -> DECIMAL
SELECT CAST(DATALENGTH(CAST('test' AS IMAGE)) AS DECIMAL(10,0));
GO

-- TEXT -> NUMERIC/DECIMAL
-- TEXT -> NUMERIC
SELECT CAST(CAST('123.45' AS TEXT) AS NUMERIC(10,2));
GO

-- TEXT -> DECIMAL
SELECT CAST(CAST('123.45' AS TEXT) AS DECIMAL(10,2));
GO

-- NTEXT -> NUMERIC/DECIMAL
-- NTEXT -> NUMERIC
SELECT CAST(CAST(N'123.45' AS NTEXT) AS NUMERIC(10,2));
GO

-- NTEXT -> DECIMAL
SELECT CAST(CAST(N'123.45' AS NTEXT) AS DECIMAL(10,2));
GO

-- SYSNAME -> NUMERIC/DECIMAL
-- SYSNAME -> NUMERIC
SELECT CAST(CAST('123.45' AS SYSNAME) AS NUMERIC(10,2));
GO

-- SYSNAME -> DECIMAL
SELECT CAST(CAST('123.45' AS SYSNAME) AS DECIMAL(10,2));
GO

-- VARBINARY with different precision/scale combinations
-- VARBINARY -> NUMERIC with different precision/scale
SELECT CAST(CONVERT(VARBINARY(4), 123) AS NUMERIC(10,0)), CAST(CONVERT(VARBINARY(4), 123) AS NUMERIC(10,2)), CAST(CONVERT(VARBINARY(4), 123) AS NUMERIC(38,10));
GO

-- VARBINARY -> DECIMAL with different precision/scale
SELECT CAST(CONVERT(VARBINARY(4), 123) AS DECIMAL(10,0)), CAST(CONVERT(VARBINARY(4), 123) AS DECIMAL(10,2)), CAST(CONVERT(VARBINARY(4), 123) AS DECIMAL(38,10));
GO

-- Very small decimal values
SELECT CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,38));
GO

SELECT CAST(0.0000000000000000000000000000000000001 AS DECIMAL(38,38));
GO


-- Casting with precision = scale (all decimal digits)
SELECT CAST(0.12345 AS NUMERIC(5,5)), CAST(0.12345 AS NUMERIC(10,10)), CAST(0.12345 AS NUMERIC(38,38));
GO

SELECT CAST(0.12345 AS DECIMAL(5,5)), CAST(0.12345 AS DECIMAL(10,10)), CAST(0.12345 AS DECIMAL(38,38));
GO

-- Casting with precision - scale = 1 (one digit before decimal)
SELECT CAST(9.12345 AS NUMERIC(6,5)), CAST(9.12345 AS NUMERIC(11,10)), CAST(9.12345 AS NUMERIC(38,37));
GO

SELECT CAST(9.12345 AS DECIMAL(6,5)), CAST(9.12345 AS DECIMAL(11,10)), CAST(9.12345 AS DECIMAL(38,37));
GO


------------------------------------------------------------------------
---- 6.2 Conversion using CONVERT()
------------------------------------------------------------------------
-- BIT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(3,1), 0), CONVERT(NUMERIC(3,1), 1);
GO

-- BIT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(5,2), 0), CONVERT(DECIMAL(5,2), 1);
GO

-- TINYINT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(5,2), 0), CONVERT(NUMERIC(5,2), 127), CONVERT(NUMERIC(5,2), 255);
GO

-- TINYINT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(8,4), 0), CONVERT(DECIMAL(8,4), 127), CONVERT(DECIMAL(8,4), 255);
GO

-- SMALLINT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(8,2), -32768), CONVERT(NUMERIC(8,2), 0), CONVERT(NUMERIC(8,2), 32767);
GO

-- SMALLINT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,5), -32768), CONVERT(DECIMAL(10,5), 0), CONVERT(DECIMAL(10,5), 32767);
GO

-- INT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(12,2), -2147483648), CONVERT(NUMERIC(12,2), 0), CONVERT(NUMERIC(12,2), 2147483647);
GO

-- INT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(15,6), -2147483648), CONVERT(DECIMAL(15,6), 0), CONVERT(DECIMAL(15,6), 2147483647);
GO

-- BIGINT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(20,0), -9223372036854775808), CONVERT(NUMERIC(20,0), 0), CONVERT(NUMERIC(20,0), 9223372036854775807);
GO

-- BIGINT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(25,5), -9223372036854775808), CONVERT(DECIMAL(25,5), 0), CONVERT(DECIMAL(25,5), 9223372036854775807);
GO

-- FLOAT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,5), -1234.56789), CONVERT(NUMERIC(10,5), 0), CONVERT(NUMERIC(10,5), 1234.56789);
GO

-- FLOAT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(18,10), -1234.56789), CONVERT(DECIMAL(18,10), 0), CONVERT(DECIMAL(18,10), 1234.56789);
GO

-- REAL -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,5), CAST(-1234.56789 AS REAL)), CONVERT(NUMERIC(10,5), CAST(0 AS REAL)), CONVERT(NUMERIC(10,5), CAST(1234.56789 AS REAL));
GO

-- REAL -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(16,8), CAST(-1234.56789 AS REAL)), CONVERT(DECIMAL(16,8), CAST(0 AS REAL)), CONVERT(DECIMAL(16,8), CAST(1234.56789 AS REAL));
GO

-- MONEY -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(19,4), CAST(-922337203685477.5808 AS MONEY)), CONVERT(NUMERIC(19,4), CAST(0 AS MONEY)), CONVERT(NUMERIC(19,4), CAST(922337203685477.5807 AS MONEY));
GO

-- MONEY -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(22,6), CAST(-922337203685477.5808 AS MONEY)), CONVERT(DECIMAL(22,6), CAST(0 AS MONEY)), CONVERT(DECIMAL(22,6), CAST(922337203685477.5807 AS MONEY));
GO

-- SMALLMONEY -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,4), CAST(-214748.3648 AS SMALLMONEY)), CONVERT(NUMERIC(10,4), CAST(0 AS SMALLMONEY)), CONVERT(NUMERIC(10,4), CAST(214748.3647 AS SMALLMONEY));
GO

-- SMALLMONEY -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(12,6), CAST(-214748.3648 AS SMALLMONEY)), CONVERT(DECIMAL(12,6), CAST(0 AS SMALLMONEY)), CONVERT(DECIMAL(12,6), CAST(214748.3647 AS SMALLMONEY));
GO

-- CHAR -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), '123.45'), CONVERT(NUMERIC(10,2), '0'), CONVERT(NUMERIC(10,2), '-987.65');
GO

-- CHAR -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(15,5), '123.45'), CONVERT(DECIMAL(15,5), '0'), CONVERT(DECIMAL(15,5), '-987.65');
GO

-- VARCHAR -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), '123.45'), CONVERT(NUMERIC(10,2), '0'), CONVERT(NUMERIC(10,2), '-987.65');
GO

-- VARCHAR -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(18,9), '123.45'), CONVERT(DECIMAL(18,9), '0'), CONVERT(DECIMAL(18,9), '-987.65');
GO

-- NCHAR -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), N'123.45'), CONVERT(NUMERIC(10,2), N'0'), CONVERT(NUMERIC(10,2), N'-987.65');
GO

-- NCHAR -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(20,10), N'123.45'), CONVERT(DECIMAL(20,10), N'0'), CONVERT(DECIMAL(20,10), N'-987.65');
GO

-- NVARCHAR -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), N'123.45'), CONVERT(NUMERIC(10,2), N'0'), CONVERT(NUMERIC(10,2), N'-987.65');
GO

-- NVARCHAR -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(22,12), N'123.45'), CONVERT(DECIMAL(22,12), N'0'), CONVERT(DECIMAL(22,12), N'-987.65');
GO

-- DATE -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(8,0), CONVERT(DATE, '2023-01-01')), CONVERT(NUMERIC(8,0), CONVERT(DATE, '2023-06-15')), CONVERT(NUMERIC(8,0), CONVERT(DATE, '2023-12-31'));
GO

-- DATE -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,0), CONVERT(DATE, '2023-01-01')), CONVERT(DECIMAL(10,0), CONVERT(DATE, '2023-06-15')), CONVERT(DECIMAL(10,0), CONVERT(DATE, '2023-12-31'));
GO

-- TIME -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,7), CONVERT(TIME, '00:00:00')), CONVERT(NUMERIC(10,7), CONVERT(TIME, '12:30:45')), CONVERT(NUMERIC(10,7), CONVERT(TIME, '23:59:59'));
GO

-- TIME -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(12,9), CONVERT(TIME, '00:00:00')), CONVERT(DECIMAL(12,9), CONVERT(TIME, '12:30:45')), CONVERT(DECIMAL(12,9), CONVERT(TIME, '23:59:59'));
GO

-- DATETIME -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(20,3), CONVERT(DATETIME, '2023-01-01 00:00:00')), CONVERT(NUMERIC(20,3), CONVERT(DATETIME, '2023-06-15 12:30:45')), CONVERT(NUMERIC(20,3), CONVERT(DATETIME, '2023-12-31 23:59:59'));
GO

-- DATETIME -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(22,5), CONVERT(DATETIME, '2023-01-01 00:00:00')), CONVERT(DECIMAL(22,5), CONVERT(DATETIME, '2023-06-15 12:30:45')), CONVERT(DECIMAL(22,5), CONVERT(DATETIME, '2023-12-31 23:59:59'));
GO

-- DATETIME2 -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(20,7), CONVERT(DATETIME2, '2023-01-01 00:00:00')), CONVERT(NUMERIC(20,7), CONVERT(DATETIME2, '2023-06-15 12:30:45.1234567')), CONVERT(NUMERIC(20,7), CONVERT(DATETIME2, '2023-12-31 23:59:59.9999999'));
GO

-- DATETIME2 -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(24,9), CONVERT(DATETIME2, '2023-01-01 00:00:00')), CONVERT(DECIMAL(24,9), CONVERT(DATETIME2, '2023-06-15 12:30:45.1234567')), CONVERT(DECIMAL(24,9), CONVERT(DATETIME2, '2023-12-31 23:59:59.9999999'));
GO

-- SMALLDATETIME -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(20,0), CONVERT(SMALLDATETIME, '2023-01-01 00:00:00')), CONVERT(NUMERIC(20,0), CONVERT(SMALLDATETIME, '2023-06-15 12:30:00')), CONVERT(NUMERIC(20,0), CONVERT(SMALLDATETIME, '2023-12-31 23:59:00'));
GO

-- SMALLDATETIME -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(18,0), CONVERT(SMALLDATETIME, '2023-01-01 00:00:00')), CONVERT(DECIMAL(18,0), CONVERT(SMALLDATETIME, '2023-06-15 12:30:00')), CONVERT(DECIMAL(18,0), CONVERT(SMALLDATETIME, '2023-12-31 23:59:00'));
GO

-- BINARY -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,0), CONVERT(VARBINARY(4), 123)), CONVERT(NUMERIC(10,0), CONVERT(VARBINARY(4), 456)), CONVERT(NUMERIC(10,0), CONVERT(VARBINARY(4), 789));
GO

-- BINARY -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(12,0), CONVERT(VARBINARY(4), 123)), CONVERT(DECIMAL(12,0), CONVERT(VARBINARY(4), 456)), CONVERT(DECIMAL(12,0), CONVERT(VARBINARY(4), 789));
GO

-- SCIENTIFIC NOTATION -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(20,10), '1.23E+3'), CONVERT(NUMERIC(20,10), '4.56E-2'), CONVERT(NUMERIC(20,10), '7.89E+0');
GO

-- SCIENTIFIC NOTATION -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(25,15), '1.23E+3'), CONVERT(DECIMAL(25,15), '4.56E-2'), CONVERT(DECIMAL(25,15), '7.89E+0');
GO

-- DECIMAL FORMATS -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), '123.45'), CONVERT(NUMERIC(10,2), '123,45'), CONVERT(NUMERIC(10,2), '$123.45');
GO

-- DECIMAL FORMATS -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(15,5), '123.45'), CONVERT(DECIMAL(15,5), '123,45'), CONVERT(DECIMAL(15,5), '$123.45');
GO

-- SQL_VARIANT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), CAST(123.45 AS SQL_VARIANT)), CONVERT(NUMERIC(10,2), CAST(0 AS SQL_VARIANT)), CONVERT(NUMERIC(10,2), CAST(-987.65 AS SQL_VARIANT));
GO

-- SQL_VARIANT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(16,8), CAST(123.45 AS SQL_VARIANT)), CONVERT(DECIMAL(16,8), CAST(0 AS SQL_VARIANT)), CONVERT(DECIMAL(16,8), CAST(-987.65 AS SQL_VARIANT));
GO

-- MAX PRECISION -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(38,10), '9999999999999999999999999999.9999999999');
GO

-- MAX PRECISION -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(38,10), '9999999999999999999999999999.9999999999');
GO

-- NUMERIC -> NUMERIC (different precision/scale) using CONVERT
SELECT CONVERT(NUMERIC(8,2), CONVERT(NUMERIC(10,6), 123.456789)), CONVERT(NUMERIC(12,8), CONVERT(NUMERIC(10,6), 123.456789));
GO

-- DECIMAL -> DECIMAL (different precision/scale) using CONVERT
SELECT CONVERT(DECIMAL(8,2), CONVERT(DECIMAL(10,6), 123.456789)), CONVERT(DECIMAL(12,8), CONVERT(DECIMAL(10,6), 123.456789));
GO

-- NUMERIC -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(8,2), CONVERT(NUMERIC(10,6), 123.456789)), CONVERT(DECIMAL(12,8), CONVERT(NUMERIC(10,6), 123.456789));
GO

-- DECIMAL -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(8,2), CONVERT(DECIMAL(10,6), 123.456789)), CONVERT(NUMERIC(12,8), CONVERT(DECIMAL(10,6), 123.456789));
GO

-- NUMERIC with MIN/MAX scale -> NUMERIC/DECIMAL using CONVERT
SELECT CONVERT(NUMERIC(12,5), CONVERT(NUMERIC(10,0), 123.456789)), CONVERT(DECIMAL(15,4), CONVERT(NUMERIC(10,9), 123.456789));
GO

-- DECIMAL with MIN/MAX scale -> NUMERIC/DECIMAL using CONVERT
SELECT CONVERT(NUMERIC(12,5), CONVERT(DECIMAL(10,0), 123.456789)), CONVERT(DECIMAL(15,4), CONVERT(DECIMAL(10,9), 123.456789));
GO

-- NUMERIC with MIN/MAX precision -> NUMERIC/DECIMAL using CONVERT
SELECT CONVERT(NUMERIC(5,2), CONVERT(NUMERIC(1,0), 1)), CONVERT(DECIMAL(20,5), CONVERT(NUMERIC(38,10), 123.456789));
GO

-- DECIMAL with MIN/MAX precision -> NUMERIC/DECIMAL using CONVERT
SELECT CONVERT(NUMERIC(5,2), CONVERT(DECIMAL(1,0), 1)), CONVERT(DECIMAL(20,5), CONVERT(DECIMAL(38,10), 123.456789));
GO

-- Edge case: precision = scale using CONVERT
SELECT CONVERT(NUMERIC(6,6), 0.123456), CONVERT(DECIMAL(6,6), 0.123456);
GO

-- Edge case: precision - scale = 1 (one digit before decimal) using CONVERT
SELECT CONVERT(NUMERIC(6,5), 9.12345), CONVERT(DECIMAL(6,5), 9.12345);
GO

-- Edge case: scale = 0 (integer only) using CONVERT
SELECT CONVERT(NUMERIC(5,0), 12345), CONVERT(DECIMAL(5,0), 12345);
GO

-- Edge case: minimum precision (1) using CONVERT
SELECT CONVERT(NUMERIC(1,0), 1), CONVERT(DECIMAL(1,0), 1);
GO

-- Edge case: maximum precision (38) using CONVERT
SELECT CONVERT(NUMERIC(38,0), 1234567890123456789012345678901234567), CONVERT(DECIMAL(38,0), 1234567890123456789012345678901234567);
GO

-- Edge case: maximum scale (38 with precision 38) using CONVERT
SELECT CONVERT(NUMERIC(38,38), 0.12345678901234567890123456789012345678), CONVERT(DECIMAL(38,38), 0.12345678901234567890123456789012345678);
GO

-- CONVERT with style parameter for strings (style 1: with commas)
SELECT CONVERT(NUMERIC(10,2), '1,234.56', 1), CONVERT(DECIMAL(10,2), '1,234.56', 1);
GO

-- CONVERT with style parameter for strings (style 2: with decimal point)
SELECT CONVERT(NUMERIC(10,2), '1234.56', 2), CONVERT(DECIMAL(10,2), '1234.56', 2);
GO

-- CONVERT with style parameter for currency (style 1: with currency symbol)
SELECT CONVERT(NUMERIC(10,2), '$1,234.56', 1), CONVERT(DECIMAL(10,2), '$1,234.56', 1);
GO

-- CONVERT with style parameter for currency (style 2: with currency symbol)
SELECT CONVERT(NUMERIC(10,2), '$1234.56', 2), CONVERT(DECIMAL(10,2), '$1234.56', 2);
GO

-- CONVERT with style parameter for scientific notation
SELECT CONVERT(NUMERIC(15,5), '1.23456E+3', 2), CONVERT(DECIMAL(15,5), '1.23456E+3', 2);
GO

-- CONVERT with style parameter for date formats
SELECT CONVERT(NUMERIC(8,0), CONVERT(VARCHAR, '2025-04-17', 101)), CONVERT(DECIMAL(8,0), CONVERT(VARCHAR, '2025-04-17', 101));
GO

-- CONVERT between NUMERIC types with extreme precision differences
SELECT CONVERT(NUMERIC(38,19), CONVERT(NUMERIC(19,0), 1234567890123456789)), CONVERT(NUMERIC(19,0), CONVERT(NUMERIC(38,19), 1234567890123456789.1234567890123456789));
GO

-- CONVERT between DECIMAL types with extreme precision differences
SELECT CONVERT(DECIMAL(38,19), CONVERT(DECIMAL(19,0), 1234567890123456789)), CONVERT(DECIMAL(19,0), CONVERT(DECIMAL(38,19), 1234567890123456789.1234567890123456789));
GO

-- CONVERT between NUMERIC types with extreme scale differences
SELECT CONVERT(NUMERIC(38,30), CONVERT(NUMERIC(38,2), 12345678.12)), CONVERT(NUMERIC(38,2), CONVERT(NUMERIC(38,30), 12345678.123456789012345678901234567890));
GO

-- CONVERT between DECIMAL types with extreme scale differences
SELECT CONVERT(DECIMAL(38,30), CONVERT(DECIMAL(38,2), 12345678.12)), CONVERT(DECIMAL(38,2), CONVERT(DECIMAL(38,30), 12345678.123456789012345678901234567890));
GO

-- CONVERT with different styles for numeric strings
SELECT CONVERT(NUMERIC(10,2), '1234.56', 0),   -- Default
       CONVERT(NUMERIC(10,2), '1,234.56', 1),  -- With commas
       CONVERT(NUMERIC(10,2), '1234.56', 2);   -- With decimal point
GO

-- CONVERT with different styles for decimal strings
SELECT CONVERT(DECIMAL(10,2), '1234.56', 0),   -- Default
       CONVERT(DECIMAL(10,2), '1,234.56', 1),  -- With commas
       CONVERT(DECIMAL(10,2), '1234.56', 2);   -- With decimal point
GO

-- CONVERT with different styles for currency strings
SELECT CONVERT(NUMERIC(10,2), '$1,234.56', 1),  -- With currency symbol and commas
       CONVERT(DECIMAL(10,2), '$1,234.56', 1);  -- With currency symbol and commas
GO

-- CONVERT with different styles for scientific notation
SELECT CONVERT(NUMERIC(15,5), '1.23456E+3', 0),  -- Default
       CONVERT(DECIMAL(15,5), '1.23456E+3', 0);  -- Default
GO

-- UNIQUEIDENTIFIER -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(38,0), CAST('A972C577-DFB0-064E-1189-0154C99310DABC12' AS UNIQUEIDENTIFIER));
GO

-- UNIQUEIDENTIFIER -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(38,0), CAST('A972C577-DFB0-064E-1189-0154C99310DABC12' AS UNIQUEIDENTIFIER));
GO

-- XML -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), CAST('<root>123</root>' AS XML).value('/root[1]', 'varchar(10)'));
GO

-- XML -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,2), CAST('<root>123.45</root>' AS XML).value('/root[1]', 'varchar(10)'));
GO

-- DATETIMEOFFSET -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(20,0), CAST('2023-01-01 12:30:45 +01:00' AS DATETIMEOFFSET));
GO

-- DATETIMEOFFSET -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(20,0), CAST('2023-01-01 12:30:45 +01:00' AS DATETIMEOFFSET));
GO

-- HIERARCHYID -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,0), CAST('/1/2/3/' AS HIERARCHYID));
GO

-- HIERARCHYID -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,0), CAST('/1/2/3/' AS HIERARCHYID));
GO

-- GEOMETRY -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,0), GEOMETRY::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 0).STNumPoints());
GO

-- GEOMETRY -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,0), GEOMETRY::STGeomFromText('LINESTRING(0 0, 1 1, 2 2)', 0).STNumPoints());
GO

-- GEOGRAPHY -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,0), GEOGRAPHY::STGeomFromText('LINESTRING(-122.34 47.65, -122.35 47.66)', 4326).STNumPoints());
GO

-- GEOGRAPHY -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,0), GEOGRAPHY::STGeomFromText('LINESTRING(-122.34 47.65, -122.35 47.66)', 4326).STNumPoints());
GO

-- ROWVERSION/TIMESTAMP -> NUMERIC/DECIMAL using CONVERT
-- Create a temp table with rowversion
CREATE TABLE #temp_rowversion (id INT, rv ROWVERSION);
INSERT INTO #temp_rowversion (id) VALUES (1);
-- ROWVERSION -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(20,0), rv) FROM #temp_rowversion;
GO

-- ROWVERSION -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(20,0), rv) FROM #temp_rowversion;
DROP TABLE #temp_rowversion;
GO

-- IMAGE -> NUMERIC/DECIMAL using CONVERT (using DATALENGTH)
-- IMAGE -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,0), DATALENGTH(CAST('test' AS IMAGE)));
GO

-- IMAGE -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,0), DATALENGTH(CAST('test' AS IMAGE)));
GO

-- TEXT -> NUMERIC/DECIMAL using CONVERT
-- TEXT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), CAST('123.45' AS TEXT));
GO

-- TEXT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,2), CAST('123.45' AS TEXT));
GO

-- NTEXT -> NUMERIC/DECIMAL using CONVERT
-- NTEXT -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), CAST(N'123.45' AS NTEXT));
GO

-- NTEXT -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,2), CAST(N'123.45' AS NTEXT));
GO

-- SYSNAME -> NUMERIC/DECIMAL using CONVERT
-- SYSNAME -> NUMERIC using CONVERT
SELECT CONVERT(NUMERIC(10,2), CAST('123.45' AS SYSNAME));
GO

-- SYSNAME -> DECIMAL using CONVERT
SELECT CONVERT(DECIMAL(10,2), CAST('123.45' AS SYSNAME));
GO

-- VARBINARY with different precision/scale combinations using CONVERT
-- VARBINARY -> NUMERIC with different precision/scale using CONVERT
SELECT CONVERT(NUMERIC(10,0), CONVERT(VARBINARY(4), 123)), 
       CONVERT(NUMERIC(10,2), CONVERT(VARBINARY(4), 123)), 
       CONVERT(NUMERIC(38,10), CONVERT(VARBINARY(4), 123));
GO

-- VARBINARY -> DECIMAL with different precision/scale using CONVERT
SELECT CONVERT(DECIMAL(10,0), CONVERT(VARBINARY(4), 123)), 
       CONVERT(DECIMAL(10,2), CONVERT(VARBINARY(4), 123)), 
       CONVERT(DECIMAL(38,10), CONVERT(VARBINARY(4), 123));
GO

-- Very small decimal values using CONVERT
SELECT CONVERT(NUMERIC(38,38), 0.0000000000000000000000000000000000001);
GO

SELECT CONVERT(DECIMAL(38,38), 0.0000000000000000000000000000000000001);
GO

-- CONVERT with precision = scale (all decimal digits)
SELECT CONVERT(NUMERIC(5,5), 0.12345), CONVERT(NUMERIC(10,10), 0.12345), CONVERT(NUMERIC(38,38), 0.12345);
GO

SELECT CONVERT(DECIMAL(5,5), 0.12345), CONVERT(DECIMAL(10,10), 0.12345), CONVERT(DECIMAL(38,38), 0.12345);
GO

-- CONVERT with precision - scale = 1 (one digit before decimal)
SELECT CONVERT(NUMERIC(6,5), 9.12345), CONVERT(NUMERIC(11,10), 9.12345), CONVERT(NUMERIC(38,37), 9.12345);
GO

SELECT CONVERT(DECIMAL(6,5), 9.12345), CONVERT(DECIMAL(11,10), 9.12345), CONVERT(DECIMAL(38,37), 9.12345);
GO

-- CONVERT with different styles for numeric strings
SELECT CONVERT(NUMERIC(10,2), '1234.56', 0),   -- Default
       CONVERT(NUMERIC(10,2), '1,234.56', 1),  -- With commas
       CONVERT(NUMERIC(10,2), '1234.56', 2);   -- With decimal point
GO

-- CONVERT with different styles for decimal strings
SELECT CONVERT(DECIMAL(10,2), '1234.56', 0),   -- Default
       CONVERT(DECIMAL(10,2), '1,234.56', 1),  -- With commas
       CONVERT(DECIMAL(10,2), '1234.56', 2);   -- With decimal point
GO

-- CONVERT with different styles for currency strings
SELECT CONVERT(NUMERIC(10,2), '$1,234.56', 1),  -- With currency symbol and commas
       CONVERT(DECIMAL(10,2), '$1,234.56', 1);  -- With currency symbol and commas
GO

-- CONVERT with different styles for scientific notation
SELECT CONVERT(NUMERIC(15,5), '1.23456E+3', 0),  -- Default
       CONVERT(DECIMAL(15,5), '1.23456E+3', 0);  -- Default
GO


------------------------------------------------------------------------
---- 7. Comparison Operators
------------------------------------------------------------------------

-- Equality (=) operator tests with various types
SELECT 'Equality (=) Operator Tests' AS test_description;
GO

-- NUMERIC/DECIMAL with same type
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.45 AS NUMERIC(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = NUMERIC];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) = CAST(123.45 AS DECIMAL(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [DECIMAL = DECIMAL];
GO

-- NUMERIC/DECIMAL with different precision/scale
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.450 AS NUMERIC(6,3)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(5,2) = NUMERIC(6,3)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) = CAST(123.450 AS DECIMAL(6,3)) THEN 'Equal' ELSE 'Not Equal' END AS [DECIMAL(5,2) = DECIMAL(6,3)];
GO

-- NUMERIC/DECIMAL with other numeric types
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = 123.45 THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = Literal];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.45 AS FLOAT) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = FLOAT];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.45 AS REAL) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = REAL];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.45 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = MONEY];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123 AS INT) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = INT];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123 AS BIGINT) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = BIGINT];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123 AS SMALLINT) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = SMALLINT];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123 AS TINYINT) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = TINYINT];
GO

-- NUMERIC/DECIMAL with string types
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST('123.45' AS VARCHAR(10)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = VARCHAR];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST('123.45' AS CHAR(10)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = CHAR];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST('123.45' AS NVARCHAR(10)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = NVARCHAR];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST('123.45' AS NCHAR(10)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = NCHAR];
GO

-- NUMERIC/DECIMAL with other types
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(CAST(123.45 AS NUMERIC(5,2)) AS SQL_VARIANT) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = SQL_VARIANT];
GO

-- Cross-type equality tests
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.45 AS DECIMAL(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = DECIMAL];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) = CAST(123.45 AS NUMERIC(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [DECIMAL = NUMERIC];
GO

-- Equality with extreme precision/scale differences
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.45000000000000000000 AS NUMERIC(25,20)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(5,2) = NUMERIC(25,20)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) = CAST(123.45000000000000000000 AS DECIMAL(25,20)) THEN 'Equal' ELSE 'Not Equal' END AS [DECIMAL(5,2) = DECIMAL(25,20)];
GO

-- Equality with negative values
SELECT CASE WHEN CAST(-123.45 AS NUMERIC(5,2)) = CAST(-123.45 AS NUMERIC(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(-) = NUMERIC(-)];
GO
SELECT CASE WHEN CAST(-123.45 AS DECIMAL(5,2)) = CAST(-123.45 AS DECIMAL(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [DECIMAL(-) = DECIMAL(-)];
GO

-- Inequality (<>) operator tests with various types
SELECT 'Inequality (<>) Operator Tests' AS test_description;
GO

-- NUMERIC/DECIMAL with same type
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(123.46 AS NUMERIC(5,2)) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> NUMERIC];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) <> CAST(123.46 AS DECIMAL(5,2)) THEN 'Not Equal' ELSE 'Equal' END AS [DECIMAL <> DECIMAL];
GO

-- NUMERIC/DECIMAL with different precision/scale
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(123.451 AS NUMERIC(6,3)) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC(5,2) <> NUMERIC(6,3)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) <> CAST(123.451 AS DECIMAL(6,3)) THEN 'Not Equal' ELSE 'Equal' END AS [DECIMAL(5,2) <> DECIMAL(6,3)];
GO

-- NUMERIC/DECIMAL with other numeric types
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> 123.46 THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> Literal];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(123.46 AS FLOAT) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> FLOAT];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(123.46 AS REAL) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> REAL];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(123.46 AS MONEY) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> MONEY];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(124 AS INT) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> INT];
GO

-- Cross-type inequality tests
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(123.46 AS DECIMAL(5,2)) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> DECIMAL];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) <> CAST(123.46 AS NUMERIC(5,2)) THEN 'Not Equal' ELSE 'Equal' END AS [DECIMAL <> NUMERIC];
GO

-- Inequality with extreme precision/scale differences
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> CAST(123.45000000000000000001 AS NUMERIC(25,20)) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC(5,2) <> NUMERIC(25,20)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) <> CAST(123.45000000000000000001 AS DECIMAL(25,20)) THEN 'Not Equal' ELSE 'Equal' END AS [DECIMAL(5,2) <> DECIMAL(25,20)];
GO

-- Inequality with negative values
SELECT CASE WHEN CAST(-123.45 AS NUMERIC(5,2)) <> CAST(-123.46 AS NUMERIC(5,2)) THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC(-) <> NUMERIC(-)];
GO
SELECT CASE WHEN CAST(-123.45 AS DECIMAL(5,2)) <> CAST(-123.46 AS DECIMAL(5,2)) THEN 'Not Equal' ELSE 'Equal' END AS [DECIMAL(-) <> DECIMAL(-)];
GO

-- Greater than (>) operator tests
SELECT 'Greater Than (>) Operator Tests' AS test_description;
GO

-- NUMERIC/DECIMAL with same type
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123.45 AS NUMERIC(5,2)) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > NUMERIC];
GO
SELECT CASE WHEN CAST(123.46 AS DECIMAL(5,2)) > CAST(123.45 AS DECIMAL(5,2)) THEN 'Greater' ELSE 'Not Greater' END AS [DECIMAL > DECIMAL];
GO

-- NUMERIC/DECIMAL with different precision/scale
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123.451 AS NUMERIC(6,3)) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC(5,2) > NUMERIC(6,3)];
GO
SELECT CASE WHEN CAST(123.46 AS DECIMAL(5,2)) > CAST(123.451 AS DECIMAL(6,3)) THEN 'Greater' ELSE 'Not Greater' END AS [DECIMAL(5,2) > DECIMAL(6,3)];
GO

-- NUMERIC/DECIMAL with other numeric types
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > 123.45 THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > Literal];
GO
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123.45 AS FLOAT) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > FLOAT];
GO
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123.45 AS REAL) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > REAL];
GO
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123.45 AS MONEY) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > MONEY];
GO
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123 AS INT) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > INT];
GO

-- Cross-type greater than tests
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123.45 AS DECIMAL(5,2)) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > DECIMAL];
GO
SELECT CASE WHEN CAST(123.46 AS DECIMAL(5,2)) > CAST(123.45 AS NUMERIC(5,2)) THEN 'Greater' ELSE 'Not Greater' END AS [DECIMAL > NUMERIC];
GO

-- Greater than with extreme precision/scale differences
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) > CAST(123.45000000000000000000 AS NUMERIC(25,20)) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC(5,2) > NUMERIC(25,20)];
GO
SELECT CASE WHEN CAST(123.46 AS DECIMAL(5,2)) > CAST(123.45000000000000000000 AS DECIMAL(25,20)) THEN 'Greater' ELSE 'Not Greater' END AS [DECIMAL(5,2) > DECIMAL(25,20)];
GO

-- Greater than with negative values
SELECT CASE WHEN CAST(-123.45 AS NUMERIC(5,2)) > CAST(-123.46 AS NUMERIC(5,2)) THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC(-) > NUMERIC(-)];
GO
SELECT CASE WHEN CAST(-123.45 AS DECIMAL(5,2)) > CAST(-123.46 AS DECIMAL(5,2)) THEN 'Greater' ELSE 'Not Greater' END AS [DECIMAL(-) > DECIMAL(-)];
GO

-- Less than (<) operator tests
SELECT 'Less Than (<) Operator Tests' AS test_description;
GO

-- NUMERIC/DECIMAL with same type
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(123.46 AS NUMERIC(5,2)) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC < NUMERIC];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) < CAST(123.46 AS DECIMAL(5,2)) THEN 'Less' ELSE 'Not Less' END AS [DECIMAL < DECIMAL];
GO

-- NUMERIC/DECIMAL with different precision/scale
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(123.451 AS NUMERIC(6,3)) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC(5,2) < NUMERIC(6,3)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) < CAST(123.451 AS DECIMAL(6,3)) THEN 'Less' ELSE 'Not Less' END AS [DECIMAL(5,2) < DECIMAL(6,3)];
GO

-- NUMERIC/DECIMAL with other numeric types
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < 123.46 THEN 'Less' ELSE 'Not Less' END AS [NUMERIC < Literal];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(123.46 AS FLOAT) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC < FLOAT];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(123.46 AS REAL) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC < REAL];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(123.46 AS MONEY) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC < MONEY];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(124 AS INT) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC < INT];
GO

-- Cross-type less than tests
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(123.46 AS DECIMAL(5,2)) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC < DECIMAL];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) < CAST(123.46 AS NUMERIC(5,2)) THEN 'Less' ELSE 'Not Less' END AS [DECIMAL < NUMERIC];
GO

-- Less than with extreme precision/scale differences
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) < CAST(123.45000000000000000001 AS NUMERIC(25,20)) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC(5,2) < NUMERIC(25,20)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) < CAST(123.45000000000000000001 AS DECIMAL(25,20)) THEN 'Less' ELSE 'Not Less' END AS [DECIMAL(5,2) < DECIMAL(25,20)];
GO

-- Less than with negative values
SELECT CASE WHEN CAST(-123.46 AS NUMERIC(5,2)) < CAST(-123.45 AS NUMERIC(5,2)) THEN 'Less' ELSE 'Not Less' END AS [NUMERIC(-) < NUMERIC(-)];
GO
SELECT CASE WHEN CAST(-123.46 AS DECIMAL(5,2)) < CAST(-123.45 AS DECIMAL(5,2)) THEN 'Less' ELSE 'Not Less' END AS [DECIMAL(-) < DECIMAL(-)];
GO

-- Greater than or equal (>=) operator tests
SELECT 'Greater Than or Equal (>=) Operator Tests' AS test_description;
GO

-- NUMERIC/DECIMAL with same type
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) >= CAST(123.45 AS NUMERIC(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC >= NUMERIC (Equal)];
GO
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) >= CAST(123.45 AS NUMERIC(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC >= NUMERIC (Greater)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) >= CAST(123.45 AS DECIMAL(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [DECIMAL >= DECIMAL (Equal)];
GO
SELECT CASE WHEN CAST(123.46 AS DECIMAL(5,2)) >= CAST(123.45 AS DECIMAL(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [DECIMAL >= DECIMAL (Greater)];
GO

-- NUMERIC/DECIMAL with different precision/scale
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) >= CAST(123.450 AS NUMERIC(6,3)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC(5,2) >= NUMERIC(6,3) (Equal)];
GO
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) >= CAST(123.450 AS NUMERIC(6,3)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC(5,2) >= NUMERIC(6,3) (Greater)];
GO

-- Cross-type greater than or equal tests
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) >= CAST(123.45 AS DECIMAL(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC >= DECIMAL (Equal)];
GO
SELECT CASE WHEN CAST(123.46 AS NUMERIC(5,2)) >= CAST(123.45 AS DECIMAL(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC >= DECIMAL (Greater)];
GO

-- Greater than or equal with negative values
SELECT CASE WHEN CAST(-123.45 AS NUMERIC(5,2)) >= CAST(-123.45 AS NUMERIC(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC(-) >= NUMERIC(-) (Equal)];
GO
SELECT CASE WHEN CAST(-123.45 AS NUMERIC(5,2)) >= CAST(-123.46 AS NUMERIC(5,2)) THEN 'Greater or Equal' ELSE 'Less' END AS [NUMERIC(-) >= NUMERIC(-) (Greater)];
GO

-- Less than or equal (<=) operator tests
SELECT 'Less Than or Equal (<=) Operator Tests' AS test_description;
GO

-- NUMERIC/DECIMAL with same type
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <= CAST(123.45 AS NUMERIC(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC <= NUMERIC (Equal)];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <= CAST(123.46 AS NUMERIC(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC <= NUMERIC (Less)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) <= CAST(123.45 AS DECIMAL(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [DECIMAL <= DECIMAL (Equal)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) <= CAST(123.46 AS DECIMAL(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [DECIMAL <= DECIMAL (Less)];
GO

-- NUMERIC/DECIMAL with different precision/scale
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <= CAST(123.450 AS NUMERIC(6,3)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC(5,2) <= NUMERIC(6,3) (Equal)];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <= CAST(123.451 AS NUMERIC(6,3)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC(5,2) <= NUMERIC(6,3) (Less)];
GO

-- Cross-type less than or equal tests
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <= CAST(123.45 AS DECIMAL(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC <= DECIMAL (Equal)];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <= CAST(123.46 AS DECIMAL(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC <= DECIMAL (Less)];
GO

-- Less than or equal with negative values
SELECT CASE WHEN CAST(-123.45 AS NUMERIC(5,2)) <= CAST(-123.45 AS NUMERIC(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC(-) <= NUMERIC(-) (Equal)];
GO
SELECT CASE WHEN CAST(-123.46 AS NUMERIC(5,2)) <= CAST(-123.45 AS NUMERIC(5,2)) THEN 'Less or Equal' ELSE 'Greater' END AS [NUMERIC(-) <= NUMERIC(-) (Less)];
GO

-- Testing edge cases for comparisons
SELECT 'Edge Cases for Comparisons' AS test_description;
GO

-- Comparing with NULL
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = NULL THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = NULL];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) <> NULL THEN 'Not Equal' ELSE 'Equal' END AS [NUMERIC <> NULL];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) > NULL THEN 'Greater' ELSE 'Not Greater' END AS [NUMERIC > NULL];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) IS NULL THEN 'Is NULL' ELSE 'Is Not NULL' END AS [NUMERIC IS NULL];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) IS NOT NULL THEN 'Is Not NULL' ELSE 'Is NULL' END AS [NUMERIC IS NOT NULL];
GO
SELECT CASE WHEN CAST(NULL AS NUMERIC(5,2)) IS NULL THEN 'Is NULL' ELSE 'Is Not NULL' END AS [NULL NUMERIC IS NULL];
GO

-- Comparing with zero
SELECT CASE WHEN CAST(0 AS NUMERIC(5,2)) = CAST(0 AS NUMERIC(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(0) = NUMERIC(0)];
GO
SELECT CASE WHEN CAST(0 AS NUMERIC(5,2)) = CAST(0.0 AS NUMERIC(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(0) = NUMERIC(0.0)];
GO
SELECT CASE WHEN CAST(0 AS NUMERIC(5,2)) = CAST(0.00 AS NUMERIC(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(0) = NUMERIC(0.00)];
GO
SELECT CASE WHEN CAST(0 AS NUMERIC(5,2)) = 0 THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(0) = 0];
GO
SELECT CASE WHEN CAST(0 AS NUMERIC(5,2)) = 0.0 THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(0) = 0.0];
GO

-- Comparing with very small differences
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.451 AS NUMERIC(6,3)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(123.45) = NUMERIC(123.451)];
GO
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.449 AS NUMERIC(6,3)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC(123.45) = NUMERIC(123.449)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) = CAST(123.451 AS DECIMAL(6,3)) THEN 'Equal' ELSE 'Not Equal' END AS [DECIMAL(123.45) = DECIMAL(123.451)];
GO
SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) = CAST(123.449 AS DECIMAL(6,3)) THEN 'Equal' ELSE 'Not Equal' END AS [DECIMAL(123.45) = DECIMAL(123.449)];
GO

-- Comparing with maximum precision/scale values
SELECT CASE WHEN CAST(9999999999999999999999999999.99 AS NUMERIC(30,2)) = CAST(9999999999999999999999999999.99 AS NUMERIC(30,2)) THEN 'Equal' ELSE 'Not Equal' END AS [MAX NUMERIC = MAX NUMERIC];
GO
SELECT CASE WHEN CAST(9999999999999999999999999999.99 AS DECIMAL(30,2)) = CAST(9999999999999999999999999999.99 AS DECIMAL(30,2)) THEN 'Equal' ELSE 'Not Equal' END AS [MAX DECIMAL = MAX DECIMAL];
GO
SELECT CASE WHEN CAST(9999999999999999999999999999.99 AS NUMERIC(30,2)) > CAST(9999999999999999999999999999.98 AS NUMERIC(30,2)) THEN 'Greater' ELSE 'Not Greater' END AS [MAX NUMERIC > ALMOST MAX NUMERIC];
GO

-- Comparing with minimum precision/scale values
SELECT CASE WHEN CAST(1 AS NUMERIC(1,0)) = CAST(1 AS NUMERIC(1,0)) THEN 'Equal' ELSE 'Not Equal' END AS [MIN NUMERIC = MIN NUMERIC];
GO
SELECT CASE WHEN CAST(1 AS DECIMAL(1,0)) = CAST(1 AS DECIMAL(1,0)) THEN 'Equal' ELSE 'Not Equal' END AS [MIN DECIMAL = MIN DECIMAL];
GO
SELECT CASE WHEN CAST(1 AS NUMERIC(1,0)) < CAST(2 AS NUMERIC(1,0)) THEN 'Less' ELSE 'Not Less' END AS [MIN NUMERIC < ANOTHER MIN NUMERIC];
GO

-- Testing BETWEEN operator
SELECT 'BETWEEN Operator Tests' AS test_description;
GO

SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) BETWEEN CAST(123.40 AS NUMERIC(5,2)) AND CAST(123.50 AS NUMERIC(5,2)) 
            THEN 'In Range' ELSE 'Not In Range' END AS [NUMERIC BETWEEN];
GO

SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) BETWEEN CAST(123.40 AS DECIMAL(5,2)) AND CAST(123.50 AS DECIMAL(5,2)) 
            THEN 'In Range' ELSE 'Not In Range' END AS [DECIMAL BETWEEN];
GO

SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) BETWEEN 123.40 AND 123.50 
            THEN 'In Range' ELSE 'Not In Range' END AS [NUMERIC BETWEEN Literals];
GO

SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) BETWEEN 123.40 AND 123.50 
            THEN 'In Range' ELSE 'Not In Range' END AS [DECIMAL BETWEEN Literals];
GO

SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) BETWEEN CAST(123.40 AS DECIMAL(5,2)) AND CAST(123.50 AS DECIMAL(5,2)) 
            THEN 'In Range' ELSE 'Not In Range' END AS [NUMERIC BETWEEN DECIMAL];
GO

SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) BETWEEN CAST(123.40 AS NUMERIC(5,2)) AND CAST(123.50 AS NUMERIC(5,2)) 
            THEN 'In Range' ELSE 'Not In Range' END AS [DECIMAL BETWEEN NUMERIC];
GO

-- Edge cases for BETWEEN
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) BETWEEN CAST(123.45 AS NUMERIC(5,2)) AND CAST(123.45 AS NUMERIC(5,2)) 
            THEN 'In Range' ELSE 'Not In Range' END AS [NUMERIC BETWEEN Equal Values];
GO

SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) BETWEEN CAST(123.46 AS NUMERIC(5,2)) AND CAST(123.44 AS NUMERIC(5,2)) 
            THEN 'In Range' ELSE 'Not In Range' END AS [NUMERIC BETWEEN Reversed Range];
GO

-- Testing IN operator
SELECT 'IN Operator Tests' AS test_description;
GO

SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) IN (CAST(123.40 AS NUMERIC(5,2)), CAST(123.45 AS NUMERIC(5,2)), CAST(123.50 AS NUMERIC(5,2))) 
            THEN 'In List' ELSE 'Not In List' END AS [NUMERIC IN];
GO

SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) IN (CAST(123.40 AS DECIMAL(5,2)), CAST(123.45 AS DECIMAL(5,2)), CAST(123.50 AS DECIMAL(5,2))) 
            THEN 'In List' ELSE 'Not In List' END AS [DECIMAL IN];
GO

SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) IN (123.40, 123.45, 123.50) 
            THEN 'In List' ELSE 'Not In List' END AS [NUMERIC IN Literals];
GO

SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) IN (123.40, 123.45, 123.50) 
            THEN 'In List' ELSE 'Not In List' END AS [DECIMAL IN Literals];
GO

SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) IN (CAST(123.40 AS DECIMAL(5,2)), CAST(123.45 AS DECIMAL(5,2)), CAST(123.50 AS DECIMAL(5,2))) 
            THEN 'In List' ELSE 'Not In List' END AS [NUMERIC IN DECIMAL List];
GO

SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) IN (CAST(123.40 AS NUMERIC(5,2)), CAST(123.45 AS NUMERIC(5,2)), CAST(123.50 AS NUMERIC(5,2))) 
            THEN 'In List' ELSE 'Not In List' END AS [DECIMAL IN NUMERIC List];
GO

-- Testing NOT IN operator
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) NOT IN (CAST(123.40 AS NUMERIC(5,2)), CAST(123.50 AS NUMERIC(5,2)), CAST(123.60 AS NUMERIC(5,2))) 
            THEN 'Not In List' ELSE 'In List' END AS [NUMERIC NOT IN];
GO

SELECT CASE WHEN CAST(123.45 AS DECIMAL(5,2)) NOT IN (CAST(123.40 AS DECIMAL(5,2)), CAST(123.50 AS DECIMAL(5,2)), CAST(123.60 AS DECIMAL(5,2))) 
            THEN 'Not In List' ELSE 'In List' END AS [DECIMAL NOT IN];
GO

-- Testing comparison with different data types
SELECT 'Mixed Data Type Comparisons' AS test_description;
GO

-- Compare NUMERIC with DECIMAL
SELECT CASE WHEN CAST(123.45 AS NUMERIC(5,2)) = CAST(123.45 AS DECIMAL(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC = DECIMAL];
GO

-- Compare with binary data
SELECT CASE WHEN CAST(CAST(123.45 AS NUMERIC(5,2)) AS VARBINARY(8)) = CAST(CAST(123.45 AS DECIMAL(5,2)) AS VARBINARY(8)) 
            THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC Binary = DECIMAL Binary];
GO

-- Compare with date (should fail or convert)
SELECT CASE WHEN CAST(CAST(20230616 AS NUMERIC(8,0)) AS DATE) = CAST('2023-06-16' AS DATE) 
            THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC as DATE = DATE];
GO

-- Compare with time (should fail or convert)
SELECT CASE WHEN CAST(CAST(131415 AS NUMERIC(6,0)) AS TIME) = CAST('13:14:15' AS TIME) 
            THEN 'Equal' ELSE 'Not Equal' END AS [NUMERIC as TIME = TIME];
GO


-- Testing comparison in WHERE clause
SELECT 'Comparison in WHERE Clause' AS test_description;
GO

-- Create a temporary table for testing
CREATE TABLE #numeric_comparison_test (
    id INT,
    numeric_val NUMERIC(10,2),
    decimal_val DECIMAL(10,2),
    numeric_small NUMERIC(5,2),
    numeric_large NUMERIC(20,5),
    decimal_small DECIMAL(5,2),
    decimal_large DECIMAL(20,5),
    numeric_negative NUMERIC(10,2),
    decimal_negative DECIMAL(10,2),
    numeric_zero NUMERIC(10,2),
    decimal_zero DECIMAL(10,2),
    numeric_null NUMERIC(10,2),
    decimal_null DECIMAL(10,2)
);

-- Insert test data
INSERT INTO #numeric_comparison_test (
    id, numeric_val, decimal_val, 
    numeric_small, numeric_large, decimal_small, decimal_large,
    numeric_negative, decimal_negative, numeric_zero, decimal_zero,
    numeric_null, decimal_null
)
VALUES 
    (1, 123.45, 123.45, 12.34, 12345.67890, 12.34, 12345.67890, -123.45, -123.45, 0.00, 0.00, NULL, NULL),
    (2, 234.56, 234.56, 23.45, 23456.78901, 23.45, 23456.78901, -234.56, -234.56, 0.00, 0.00, NULL, NULL),
    (3, 345.67, 345.67, 34.56, 34567.89012, 34.56, 34567.89012, -345.67, -345.67, 0.00, 0.00, NULL, NULL),
    (4, 456.78, 456.78, 45.67, 45678.90123, 45.67, 45678.90123, -456.78, -456.78, 0.00, 0.00, NULL, NULL),
    (5, 567.89, 567.89, 56.78, 56789.01234, 56.78, 56789.01234, -567.89, -567.89, 0.00, 0.00, NULL, NULL);

-- Test WHERE with equality
SELECT id, numeric_val FROM #numeric_comparison_test WHERE numeric_val = 234.56;
GO

-- Test WHERE with inequality
SELECT id, decimal_val FROM #numeric_comparison_test WHERE decimal_val <> 234.56;
GO

-- Test WHERE with greater than
SELECT id, numeric_val FROM #numeric_comparison_test WHERE numeric_val > 300;
GO

-- Test WHERE with less than
SELECT id, decimal_val FROM #numeric_comparison_test WHERE decimal_val < 300;
GO

-- Test WHERE with greater than or equal
SELECT id, numeric_val FROM #numeric_comparison_test WHERE numeric_val >= 345.67;
GO

-- Test WHERE with less than or equal
SELECT id, decimal_val FROM #numeric_comparison_test WHERE decimal_val <= 345.67;
GO

-- Test WHERE with BETWEEN
SELECT id, numeric_val FROM #numeric_comparison_test WHERE numeric_val BETWEEN 200 AND 400;
GO

-- Test WHERE with IN
SELECT id, decimal_val FROM #numeric_comparison_test WHERE decimal_val IN (123.45, 345.67, 567.89);
GO

-- Test WHERE with NOT IN
SELECT id, numeric_val FROM #numeric_comparison_test WHERE numeric_val NOT IN (123.45, 345.67, 567.89);
GO

-- Test WHERE with NULL comparison
SELECT id, numeric_null FROM #numeric_comparison_test WHERE numeric_null = 123.45;
GO

-- Test WHERE with IS NULL
SELECT id, numeric_null FROM #numeric_comparison_test WHERE numeric_null IS NULL;
GO

-- Test WHERE with IS NOT NULL
SELECT id, numeric_val FROM #numeric_comparison_test WHERE numeric_val IS NOT NULL;
GO

-- Test WHERE with zero comparison
SELECT id, numeric_zero FROM #numeric_comparison_test WHERE numeric_zero = 0;
GO

-- Test WHERE with negative values
SELECT id, numeric_negative FROM #numeric_comparison_test WHERE numeric_negative < 0;
GO

-- Test WHERE with complex conditions
SELECT id, numeric_val, decimal_val 
FROM #numeric_comparison_test 
WHERE numeric_val > 200 AND decimal_val < 500;
GO

-- Test WHERE with OR conditions
SELECT id, numeric_val, decimal_val 
FROM #numeric_comparison_test 
WHERE numeric_val < 200 OR decimal_val > 500;
GO

-- Test WHERE with different precision/scale
SELECT id, numeric_small, numeric_large 
FROM #numeric_comparison_test 
WHERE numeric_small = CAST(numeric_large AS NUMERIC(5,2));
GO

-- Test WHERE with mixed NUMERIC and DECIMAL
SELECT id, numeric_val, decimal_val 
FROM #numeric_comparison_test 
WHERE numeric_val = decimal_val;
GO

-- Test WHERE with calculations
SELECT id, numeric_val, decimal_val 
FROM #numeric_comparison_test 
WHERE numeric_val + 100 > decimal_val * 2;
GO

-- Test WHERE with CASE expression
SELECT id, numeric_val, decimal_val 
FROM #numeric_comparison_test 
WHERE CASE WHEN numeric_val > 300 THEN 1 ELSE 0 END = 1;
GO

-- Clean up
DROP TABLE #numeric_comparison_test;
GO

------------------------------------------------------------------------
---- 8. Aggregate Function Tests
------------------------------------------------------------------------
------------------------------------------------------------------------
---- 8. Aggregate Function Tests
------------------------------------------------------------------------

-- Create a test table with various NUMERIC and DECIMAL values
CREATE TABLE #numeric_aggregate_test (
    id INT IDENTITY(1,1),
    numeric_small NUMERIC(5,2),
    numeric_medium NUMERIC(10,4),
    numeric_large NUMERIC(20,8),
    numeric_negative NUMERIC(10,2),
    numeric_zero NUMERIC(10,2),
    numeric_null NUMERIC(10,2),
    decimal_small DECIMAL(5,2),
    decimal_medium DECIMAL(10,4),
    decimal_large DECIMAL(20,8),
    decimal_negative DECIMAL(10,2),
    decimal_zero DECIMAL(10,2),
    decimal_null DECIMAL(10,2),
    category VARCHAR(10)
);

-- Insert test data
INSERT INTO #numeric_aggregate_test (
    numeric_small, numeric_medium, numeric_large, numeric_negative, numeric_zero, numeric_null,
    decimal_small, decimal_medium, decimal_large, decimal_negative, decimal_zero, decimal_null,
    category
)
VALUES
    (12.34, 1234.5678, 123456.78901234, -123.45, 0.00, NULL, 
     12.34, 1234.5678, 123456.78901234, -123.45, 0.00, NULL, 'A'),
    (23.45, 2345.6789, 234567.89012345, -234.56, 0.00, NULL, 
     23.45, 2345.6789, 234567.89012345, -234.56, 0.00, NULL, 'A'),
    (34.56, 3456.7890, 345678.90123456, -345.67, 0.00, NULL, 
     34.56, 3456.7890, 345678.90123456, -345.67, 0.00, NULL, 'B'),
    (45.67, 4567.8901, 456789.01234567, -456.78, 0.00, NULL, 
     45.67, 4567.8901, 456789.01234567, -456.78, 0.00, NULL, 'B'),
    (56.78, 5678.9012, 567890.12345678, -567.89, 0.00, NULL, 
     56.78, 5678.9012, 567890.12345678, -567.89, 0.00, NULL, 'C'),
    (NULL, NULL, NULL, NULL, NULL, NULL, 
     NULL, NULL, NULL, NULL, NULL, NULL, 'C');

------------------------------------------------------------------------
---- 8.1 Basic Aggregate Functions
------------------------------------------------------------------------

-- SUM function tests
SELECT 'SUM Function Tests' AS test_description;
GO

-- SUM with NUMERIC types
SELECT 
    SUM(numeric_small) AS sum_numeric_small,
    SUM(numeric_medium) AS sum_numeric_medium,
    SUM(numeric_large) AS sum_numeric_large,
    SUM(numeric_negative) AS sum_numeric_negative,
    SUM(numeric_zero) AS sum_numeric_zero,
    SUM(numeric_null) AS sum_numeric_null
FROM #numeric_aggregate_test;
GO

-- SUM with DECIMAL types
SELECT 
    SUM(decimal_small) AS sum_decimal_small,
    SUM(decimal_medium) AS sum_decimal_medium,
    SUM(decimal_large) AS sum_decimal_large,
    SUM(decimal_negative) AS sum_decimal_negative,
    SUM(decimal_zero) AS sum_decimal_zero,
    SUM(decimal_null) AS sum_decimal_null
FROM #numeric_aggregate_test;
GO

-- SUM with GROUP BY
SELECT 
    category,
    SUM(numeric_small) AS sum_numeric_small,
    SUM(decimal_small) AS sum_decimal_small
FROM #numeric_aggregate_test
GROUP BY category
ORDER BY category;
GO

-- AVG function tests
SELECT 'AVG Function Tests' AS test_description;
GO

-- AVG with NUMERIC types
SELECT 
    AVG(numeric_small) AS avg_numeric_small,
    AVG(numeric_medium) AS avg_numeric_medium,
    AVG(numeric_large) AS avg_numeric_large,
    AVG(numeric_negative) AS avg_numeric_negative,
    AVG(numeric_zero) AS avg_numeric_zero,
    AVG(numeric_null) AS avg_numeric_null
FROM #numeric_aggregate_test;
GO

-- AVG with DECIMAL types
SELECT 
    AVG(decimal_small) AS avg_decimal_small,
    AVG(decimal_medium) AS avg_decimal_medium,
    AVG(decimal_large) AS avg_decimal_large,
    AVG(decimal_negative) AS avg_decimal_negative,
    AVG(decimal_zero) AS avg_decimal_zero,
    AVG(decimal_null) AS avg_decimal_null
FROM #numeric_aggregate_test;
GO

-- AVG with GROUP BY
SELECT 
    category,
    AVG(numeric_small) AS avg_numeric_small,
    AVG(decimal_small) AS avg_decimal_small
FROM #numeric_aggregate_test
GROUP BY category
ORDER BY category;
GO

-- MIN function tests
SELECT 'MIN Function Tests' AS test_description;
GO

-- MIN with NUMERIC types
SELECT 
    MIN(numeric_small) AS min_numeric_small,
    MIN(numeric_medium) AS min_numeric_medium,
    MIN(numeric_large) AS min_numeric_large,
    MIN(numeric_negative) AS min_numeric_negative,
    MIN(numeric_zero) AS min_numeric_zero,
    MIN(numeric_null) AS min_numeric_null
FROM #numeric_aggregate_test;
GO

-- MIN with DECIMAL types
SELECT 
    MIN(decimal_small) AS min_decimal_small,
    MIN(decimal_medium) AS min_decimal_medium,
    MIN(decimal_large) AS min_decimal_large,
    MIN(decimal_negative) AS min_decimal_negative,
    MIN(decimal_zero) AS min_decimal_zero,
    MIN(decimal_null) AS min_decimal_null
FROM #numeric_aggregate_test;
GO

-- MIN with GROUP BY
SELECT 
    category,
    MIN(numeric_small) AS min_numeric_small,
    MIN(decimal_small) AS min_decimal_small
FROM #numeric_aggregate_test
GROUP BY category
ORDER BY category;
GO

-- MAX function tests
SELECT 'MAX Function Tests' AS test_description;
GO

-- MAX with NUMERIC types
SELECT 
    MAX(numeric_small) AS max_numeric_small,
    MAX(numeric_medium) AS max_numeric_medium,
    MAX(numeric_large) AS max_numeric_large,
    MAX(numeric_negative) AS max_numeric_negative,
    MAX(numeric_zero) AS max_numeric_zero,
    MAX(numeric_null) AS max_numeric_null
FROM #numeric_aggregate_test;
GO

-- MAX with DECIMAL types
SELECT 
    MAX(decimal_small) AS max_decimal_small,
    MAX(decimal_medium) AS max_decimal_medium,
    MAX(decimal_large) AS max_decimal_large,
    MAX(decimal_negative) AS max_decimal_negative,
    MAX(decimal_zero) AS max_decimal_zero,
    MAX(decimal_null) AS max_decimal_null
FROM #numeric_aggregate_test;
GO

-- MAX with GROUP BY
SELECT 
    category,
    MAX(numeric_small) AS max_numeric_small,
    MAX(decimal_small) AS max_decimal_small
FROM #numeric_aggregate_test
GROUP BY category
ORDER BY category;
GO

-- COUNT function tests
SELECT 'COUNT Function Tests' AS test_description;
GO

-- COUNT with NUMERIC types
SELECT 
    COUNT(numeric_small) AS count_numeric_small,
    COUNT(numeric_medium) AS count_numeric_medium,
    COUNT(numeric_large) AS count_numeric_large,
    COUNT(numeric_negative) AS count_numeric_negative,
    COUNT(numeric_zero) AS count_numeric_zero,
    COUNT(numeric_null) AS count_numeric_null,
    COUNT(*) AS count_all
FROM #numeric_aggregate_test;
GO

-- COUNT with DECIMAL types
SELECT 
    COUNT(decimal_small) AS count_decimal_small,
    COUNT(decimal_medium) AS count_decimal_medium,
    COUNT(decimal_large) AS count_decimal_large,
    COUNT(decimal_negative) AS count_decimal_negative,
    COUNT(decimal_zero) AS count_decimal_zero,
    COUNT(decimal_null) AS count_decimal_null,
    COUNT(*) AS count_all
FROM #numeric_aggregate_test;
GO

-- COUNT with GROUP BY
SELECT 
    category,
    COUNT(numeric_small) AS count_numeric_small,
    COUNT(decimal_small) AS count_decimal_small,
    COUNT(*) AS count_all
FROM #numeric_aggregate_test
GROUP BY category
ORDER BY category;
GO

-- COUNT DISTINCT tests
SELECT 
    COUNT(DISTINCT numeric_small) AS count_distinct_numeric_small,
    COUNT(DISTINCT numeric_zero) AS count_distinct_numeric_zero,
    COUNT(DISTINCT decimal_small) AS count_distinct_decimal_small,
    COUNT(DISTINCT decimal_zero) AS count_distinct_decimal_zero
FROM #numeric_aggregate_test;
GO

------------------------------------------------------------------------
---- 8.2 Statistical Aggregate Functions
------------------------------------------------------------------------

-- STDEV and STDEVP function tests
SELECT 'STDEV and STDEVP Function Tests' AS test_description;
GO

-- STDEV with NUMERIC types
SELECT 
    STDEV(numeric_small) AS stdev_numeric_small,
    STDEV(numeric_medium) AS stdev_numeric_medium,
    STDEV(numeric_large) AS stdev_numeric_large,
    STDEV(numeric_negative) AS stdev_numeric_negative,
    STDEV(numeric_zero) AS stdev_numeric_zero
FROM #numeric_aggregate_test;
GO

-- STDEV with DECIMAL types
SELECT 
    STDEV(decimal_small) AS stdev_decimal_small,
    STDEV(decimal_medium) AS stdev_decimal_medium,
    STDEV(decimal_large) AS stdev_decimal_large,
    STDEV(decimal_negative) AS stdev_decimal_negative,
    STDEV(decimal_zero) AS stdev_decimal_zero
FROM #numeric_aggregate_test;
GO

-- STDEVP with NUMERIC types
SELECT 
    STDEVP(numeric_small) AS stdevp_numeric_small,
    STDEVP(numeric_medium) AS stdevp_numeric_medium,
    STDEVP(numeric_large) AS stdevp_numeric_large,
    STDEVP(numeric_negative) AS stdevp_numeric_negative,
    STDEVP(numeric_zero) AS stdevp_numeric_zero
FROM #numeric_aggregate_test;
GO

-- STDEVP with DECIMAL types
SELECT 
    STDEVP(decimal_small) AS stdevp_decimal_small,
    STDEVP(decimal_medium) AS stdevp_decimal_medium,
    STDEVP(decimal_large) AS stdevp_decimal_large,
    STDEVP(decimal_negative) AS stdevp_decimal_negative,
    STDEVP(decimal_zero) AS stdevp_decimal_zero
FROM #numeric_aggregate_test;
GO

-- VAR and VARP function tests
SELECT 'VAR and VARP Function Tests' AS test_description;
GO

-- VAR with NUMERIC types
SELECT 
    VAR(numeric_small) AS var_numeric_small,
    VAR(numeric_medium) AS var_numeric_medium,
    VAR(numeric_large) AS var_numeric_large,
    VAR(numeric_negative) AS var_numeric_negative,
    VAR(numeric_zero) AS var_numeric_zero
FROM #numeric_aggregate_test;
GO

-- VAR with DECIMAL types
SELECT 
    VAR(decimal_small) AS var_decimal_small,
    VAR(decimal_medium) AS var_decimal_medium,
    VAR(decimal_large) AS var_decimal_large,
    VAR(decimal_negative) AS var_decimal_negative,
    VAR(decimal_zero) AS var_decimal_zero
FROM #numeric_aggregate_test;
GO

-- VARP with NUMERIC types
SELECT 
    VARP(numeric_small) AS varp_numeric_small,
    VARP(numeric_medium) AS varp_numeric_medium,
    VARP(numeric_large) AS varp_numeric_large,
    VARP(numeric_negative) AS varp_numeric_negative,
    VARP(numeric_zero) AS varp_numeric_zero
FROM #numeric_aggregate_test;
GO

-- VARP with DECIMAL types
SELECT 
    VARP(decimal_small) AS varp_decimal_small,
    VARP(decimal_medium) AS varp_decimal_medium,
    VARP(decimal_large) AS varp_decimal_large,
    VARP(decimal_negative) AS varp_decimal_negative,
    VARP(decimal_zero) AS varp_decimal_zero
FROM #numeric_aggregate_test;
GO

------------------------------------------------------------------------
---- 8.3 Advanced Aggregate Functions
------------------------------------------------------------------------

-- STRING_AGG function tests (SQL Server 2017+)
SELECT 'STRING_AGG Function Tests' AS test_description;
GO

-- STRING_AGG with NUMERIC types
SELECT 
    STRING_AGG(CAST(numeric_small AS VARCHAR(20)), ', ') AS string_agg_numeric_small,
    STRING_AGG(CAST(numeric_medium AS VARCHAR(20)), ', ') AS string_agg_numeric_medium
FROM #numeric_aggregate_test
WHERE numeric_small IS NOT NULL;
GO

-- STRING_AGG with DECIMAL types
SELECT 
    STRING_AGG(CAST(decimal_small AS VARCHAR(20)), ', ') AS string_agg_decimal_small,
    STRING_AGG(CAST(decimal_medium AS VARCHAR(20)), ', ') AS string_agg_decimal_medium
FROM #numeric_aggregate_test
WHERE decimal_small IS NOT NULL;
GO

-- STRING_AGG with GROUP BY
SELECT 
    category,
    STRING_AGG(CAST(numeric_small AS VARCHAR(20)), ', ') AS string_agg_numeric_small,
    STRING_AGG(CAST(decimal_small AS VARCHAR(20)), ', ') AS string_agg_decimal_small
FROM #numeric_aggregate_test
WHERE numeric_small IS NOT NULL
GROUP BY category
ORDER BY category;
GO

-- STRING_AGG with ORDER BY
SELECT 
    STRING_AGG(CAST(numeric_small AS VARCHAR(20)), ', ') WITHIN GROUP (ORDER BY numeric_small) AS ordered_string_agg_numeric,
    STRING_AGG(CAST(decimal_small AS VARCHAR(20)), ', ') WITHIN GROUP (ORDER BY decimal_small) AS ordered_string_agg_decimal
FROM #numeric_aggregate_test
WHERE numeric_small IS NOT NULL;
GO

------------------------------------------------------------------------
---- 8.4 Aggregate Functions with DISTINCT
------------------------------------------------------------------------

SELECT 'Aggregate Functions with DISTINCT' AS test_description;
GO

-- SUM with DISTINCT
SELECT 
    SUM(DISTINCT numeric_small) AS sum_distinct_numeric_small,
    SUM(DISTINCT numeric_zero) AS sum_distinct_numeric_zero,
    SUM(DISTINCT decimal_small) AS sum_distinct_decimal_small,
    SUM(DISTINCT decimal_zero) AS sum_distinct_decimal_zero
FROM #numeric_aggregate_test;
GO

-- AVG with DISTINCT
SELECT 
    AVG(DISTINCT numeric_small) AS avg_distinct_numeric_small,
    AVG(DISTINCT numeric_zero) AS avg_distinct_numeric_zero,
    AVG(DISTINCT decimal_small) AS avg_distinct_decimal_small,
    AVG(DISTINCT decimal_zero) AS avg_distinct_decimal_zero
FROM #numeric_aggregate_test;
GO

-- MIN with DISTINCT (same as MIN without DISTINCT)
SELECT 
    MIN(DISTINCT numeric_small) AS min_distinct_numeric_small,
    MIN(DISTINCT decimal_small) AS min_distinct_decimal_small
FROM #numeric_aggregate_test;
GO

-- MAX with DISTINCT (same as MAX without DISTINCT)
SELECT 
    MAX(DISTINCT numeric_small) AS max_distinct_numeric_small,
    MAX(DISTINCT decimal_small) AS max_distinct_decimal_small
FROM #numeric_aggregate_test;
GO

------------------------------------------------------------------------
---- 8.5 Aggregate Functions with Filtering
------------------------------------------------------------------------

SELECT 'Aggregate Functions with Filtering' AS test_description;
GO

-- SUM with WHERE clause
SELECT 
    SUM(numeric_small) AS sum_numeric_small,
    SUM(decimal_small) AS sum_decimal_small
FROM #numeric_aggregate_test
WHERE numeric_small > 30;
GO

-- AVG with WHERE clause
SELECT 
    AVG(numeric_small) AS avg_numeric_small,
    AVG(decimal_small) AS avg_decimal_small
FROM #numeric_aggregate_test
WHERE numeric_small > 30;
GO

-- MIN with WHERE clause
SELECT 
    MIN(numeric_small) AS min_numeric_small,
    MIN(decimal_small) AS min_decimal_small
FROM #numeric_aggregate_test
WHERE numeric_small > 30;
GO

-- MAX with WHERE clause
SELECT 
    MAX(numeric_small) AS max_numeric_small,
    MAX(decimal_small) AS max_decimal_small
FROM #numeric_aggregate_test
WHERE numeric_small > 30;
GO

-- COUNT with WHERE clause
SELECT 
    COUNT(numeric_small) AS count_numeric_small,
    COUNT(decimal_small) AS count_decimal_small,
    COUNT(*) AS count_all
FROM #numeric_aggregate_test
WHERE numeric_small > 30;
GO

-- Aggregate with HAVING clause
SELECT 
    category,
    SUM(numeric_small) AS sum_numeric_small,
    AVG(numeric_small) AS avg_numeric_small
FROM #numeric_aggregate_test
GROUP BY category
HAVING SUM(numeric_small) > 50
ORDER BY category;
GO

------------------------------------------------------------------------
---- 8.7 Aggregate Functions with Expressions
------------------------------------------------------------------------

SELECT 'Aggregate Functions with Expressions' AS test_description;
GO

-- SUM with expressions
SELECT 
    SUM(numeric_small * 2) AS sum_double_numeric,
    SUM(numeric_small + decimal_small) AS sum_numeric_plus_decimal,
    SUM(numeric_small - numeric_negative) AS sum_numeric_minus_negative,
    SUM(POWER(numeric_small, 2)) AS sum_numeric_squared,
    SUM(CASE WHEN category = 'A' THEN numeric_small ELSE 0 END) AS sum_category_a
FROM #numeric_aggregate_test
WHERE numeric_small IS NOT NULL;
GO

-- AVG with expressions
SELECT 
    AVG(numeric_small * 2) AS avg_double_numeric,
    AVG(numeric_small + decimal_small) AS avg_numeric_plus_decimal,
    AVG(numeric_small - numeric_negative) AS avg_numeric_minus_negative,
    AVG(POWER(numeric_small, 2)) AS avg_numeric_squared,
    AVG(CASE WHEN category = 'A' THEN numeric_small ELSE 0 END) AS avg_category_a
FROM #numeric_aggregate_test
WHERE numeric_small IS NOT NULL;
GO

-- MIN with expressions
SELECT 
    MIN(numeric_small * 2) AS min_double_numeric,
    MIN(numeric_small + decimal_small) AS min_numeric_plus_decimal,
    MIN(numeric_small - numeric_negative) AS min_numeric_minus_negative,
    MIN(POWER(numeric_small, 2)) AS min_numeric_squared,
    MIN(CASE WHEN category = 'A' THEN numeric_small ELSE 999 END) AS min_category_a
FROM #numeric_aggregate_test
WHERE numeric_small IS NOT NULL;
GO

-- MAX with expressions
SELECT 
    MAX(numeric_small * 2) AS max_double_numeric,
    MAX(numeric_small + decimal_small) AS max_numeric_plus_decimal,
    MAX(numeric_small - numeric_negative) AS max_numeric_minus_negative,
    MAX(POWER(numeric_small, 2)) AS max_numeric_squared,
    MAX(CASE WHEN category = 'A' THEN numeric_small ELSE 0 END) AS max_category_a
FROM #numeric_aggregate_test
WHERE numeric_small IS NOT NULL;
GO

-- Clean up
DROP TABLE #numeric_aggregate_test;
GO


------------------------------------------------------------------------
---- 8.8 Aggregate Functions with Extreme Values
------------------------------------------------------------------------

SELECT 'Aggregate Functions with Extreme Values' AS test_description;
GO

-- Create a table with extreme values
CREATE TABLE #numeric_extreme_test (
    id INT IDENTITY(1,1),
    numeric_max NUMERIC(38,10),
    numeric_min NUMERIC(38,10),
    decimal_max DECIMAL(38,10),
    decimal_min DECIMAL(38,10),
    numeric_small_scale NUMERIC(38,38),
    decimal_small_scale DECIMAL(38,38)
);
GO

-- Insert extreme values
INSERT INTO #numeric_extreme_test (
    numeric_max, numeric_min, decimal_max, decimal_min,
    numeric_small_scale, decimal_small_scale
)
VALUES 
    (9999999999999999999999999999.9999999999, -9999999999999999999999999999.9999999999, 
     9999999999999999999999999999.9999999999, -9999999999999999999999999999.9999999999,
     0.0000000000000000000000000000000000001, 0.0000000000000000000000000000000000001),
    (1234567890123456789012345678.1234567890, -1234567890123456789012345678.1234567890, 
     1234567890123456789012345678.1234567890, -1234567890123456789012345678.1234567890,
     0.0000000000000000000000000000000000002, 0.0000000000000000000000000000000000002),
    (9876543210987654321098765432.0987654321, -9876543210987654321098765432.0987654321, 
     9876543210987654321098765432.0987654321, -9876543210987654321098765432.0987654321,
     0.0000000000000000000000000000000000003, 0.0000000000000000000000000000000000003);
GO

-- Aggregate maximum precision/scale values
SELECT 
    SUM(numeric_max) AS sum_numeric_max,
    SUM(numeric_min) AS sum_numeric_min,
    SUM(decimal_max) AS sum_decimal_max,
    SUM(decimal_min) AS sum_decimal_min,
    AVG(numeric_max) AS avg_numeric_max,
    AVG(numeric_min) AS avg_numeric_min,
    AVG(decimal_max) AS avg_decimal_max,
    AVG(decimal_min) AS avg_decimal_min,
    MIN(numeric_max) AS min_numeric_max,
    MIN(numeric_min) AS min_numeric_min,
    MIN(decimal_max) AS min_decimal_max,
    MIN(decimal_min) AS min_decimal_min,
    MAX(numeric_max) AS max_numeric_max,
    MAX(numeric_min) AS max_numeric_min,
    MAX(decimal_max) AS max_decimal_max,
    MAX(decimal_min) AS max_decimal_min
FROM #numeric_extreme_test;
GO

-- Aggregate very small scale values
SELECT 
    SUM(numeric_small_scale) AS sum_numeric_small_scale,
    SUM(decimal_small_scale) AS sum_decimal_small_scale,
    AVG(numeric_small_scale) AS avg_numeric_small_scale,
    AVG(decimal_small_scale) AS avg_decimal_small_scale,
    MIN(numeric_small_scale) AS min_numeric_small_scale,
    MIN(decimal_small_scale) AS min_decimal_small_scale,
    MAX(numeric_small_scale) AS max_numeric_small_scale,
    MAX(decimal_small_scale) AS max_decimal_small_scale
FROM #numeric_extreme_test;
GO

-- Statistical functions with extreme values
SELECT 
    STDEV(numeric_max) AS stdev_numeric_max,
    STDEV(numeric_min) AS stdev_numeric_min,
    STDEV(decimal_max) AS stdev_decimal_max,
    STDEV(decimal_min) AS stdev_decimal_min,
    VAR(numeric_max) AS var_numeric_max,
    VAR(numeric_min) AS var_numeric_min,
    VAR(decimal_max) AS var_decimal_max,
    VAR(decimal_min) AS var_decimal_min
FROM #numeric_extreme_test;
GO

-- Statistical functions with very small scale values
SELECT 
    STDEV(numeric_small_scale) AS stdev_numeric_small_scale,
    STDEV(decimal_small_scale) AS stdev_decimal_small_scale,
    VAR(numeric_small_scale) AS var_numeric_small_scale,
    VAR(decimal_small_scale) AS var_decimal_small_scale
FROM #numeric_extreme_test;
GO

-- Aggregate functions with expressions on extreme values
SELECT 
    SUM(numeric_max + numeric_min) AS sum_numeric_max_plus_min,
    AVG(numeric_max * 2) AS avg_numeric_max_doubled,
    MIN(numeric_max / 1000000000000000000000000000) AS min_numeric_max_divided,
    MAX(POWER(numeric_small_scale, 2)) AS max_numeric_small_scale_squared
FROM #numeric_extreme_test;
GO

-- Aggregate functions with DISTINCT on extreme values
SELECT 
    COUNT(DISTINCT numeric_max) AS count_distinct_numeric_max,
    COUNT(DISTINCT numeric_min) AS count_distinct_numeric_min,
    COUNT(DISTINCT decimal_max) AS count_distinct_decimal_max,
    COUNT(DISTINCT decimal_min) AS count_distinct_decimal_min,
    COUNT(DISTINCT numeric_small_scale) AS count_distinct_numeric_small_scale,
    COUNT(DISTINCT decimal_small_scale) AS count_distinct_decimal_small_scale
FROM #numeric_extreme_test;
GO

-- Aggregate functions with filtering on extreme values
SELECT 
    SUM(numeric_max) AS sum_numeric_max,
    AVG(numeric_max) AS avg_numeric_max
FROM #numeric_extreme_test
WHERE numeric_max > 5000000000000000000000000000;
GO

-- Clean up
DROP TABLE #numeric_extreme_test;
GO

------------------------------------------------------------------------
---- 9. Special Case Tests
------------------------------------------------------------------------
-- Testing with very small values (close to zero)
SELECT 'Very Small Values' AS special_case_test;
SELECT 
    CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,38)) AS tiny_numeric,
    CAST(0.0000000000000000000000000000000000001 AS DECIMAL(38,38)) AS tiny_decimal,
    CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,38)) * 2 AS tiny_numeric_doubled,
    CAST(0.0000000000000000000000000000000000001 AS DECIMAL(38,38)) * 2 AS tiny_decimal_doubled;
GO

-- Testing with very large values
SELECT 'Very Large Values' AS special_case_test;
SELECT 
    CAST(99999999999999999999999999999999999999 AS NUMERIC(38,0)) AS huge_numeric,
    CAST(99999999999999999999999999999999999999 AS DECIMAL(38,0)) AS huge_decimal,
    CAST(99999999999999999999999999999999999999 AS NUMERIC(38,0)) / 2 AS huge_numeric_halved,
    CAST(99999999999999999999999999999999999999 AS DECIMAL(38,0)) / 2 AS huge_decimal_halved;
GO

-- Testing with precision boundaries
SELECT 'Precision Boundary Tests' AS special_case_test;
SELECT 
    -- Precision 17 (special attention)
    CAST(99999999999999.99 AS NUMERIC(17,2)) AS numeric_17_2_max,
    CAST(99999999999999.99 AS DECIMAL(17,2)) AS decimal_17_2_max,
    
    -- Precision 18 (special attention)
    CAST(999999999999999.99 AS NUMERIC(18,2)) AS numeric_18_2_max,
    CAST(999999999999999.99 AS DECIMAL(18,2)) AS decimal_18_2_max,
    
    -- Precision 19 (special attention)
    CAST(9999999999999999.99 AS NUMERIC(19,2)) AS numeric_19_2_max,
    CAST(9999999999999999.99 AS DECIMAL(19,2)) AS decimal_19_2_max;
GO

-- Testing with scientific notation
SELECT 'Scientific Notation' AS special_case_test;
SELECT 
    CAST(1.23E+10 AS NUMERIC(20,2)) AS scientific_numeric_positive,
    CAST(1.23E+10 AS DECIMAL(20,2)) AS scientific_decimal_positive,
    CAST(1.23E-10 AS NUMERIC(20,19)) AS scientific_numeric_negative,
    CAST(1.23E-10 AS DECIMAL(20,19)) AS scientific_decimal_negative;
GO

-- Testing with special values
SELECT 'Special Values' AS special_case_test;
SELECT 
    -- PI value
    CAST(PI() AS NUMERIC(38,36)) AS pi_numeric,
    CAST(PI() AS DECIMAL(38,36)) AS pi_decimal,
    
    -- Euler's number (e)
    CAST(EXP(1) AS NUMERIC(38,36)) AS e_numeric,
    CAST(EXP(1) AS DECIMAL(38,36)) AS e_decimal;
GO

-- Testing with rounding issues
SELECT 'Rounding Issues' AS special_case_test;
SELECT 
    CAST(123.456 AS NUMERIC(5,2)) AS numeric_rounded,
    CAST(123.456 AS DECIMAL(5,2)) AS decimal_rounded,
    ROUND(123.456, 2) AS explicit_round_2,
    ROUND(123.456, 2, 1) AS explicit_truncate_2;
GO

-- Testing with currency values
SELECT 'Currency Values' AS special_case_test;
SELECT 
    CAST(1234.56 AS NUMERIC(10,2)) AS numeric_currency,
    CAST(1234.56 AS DECIMAL(10,2)) AS decimal_currency,
    CAST(1234.56 AS MONEY) AS money_value,
    CAST(CAST(1234.56 AS MONEY) AS NUMERIC(10,2)) AS money_to_numeric,
    CAST(CAST(1234.56 AS MONEY) AS DECIMAL(10,2)) AS money_to_decimal;
GO


------------------------------------------------------------------------
---- 11. Edge Case Tests
------------------------------------------------------------------------
-- Testing with NULL operations
SELECT 'NULL Operations' AS edge_case_test;
SELECT 
    NULL + CAST(1.23 AS NUMERIC(5,2)) AS null_plus_numeric,
    NULL * CAST(1.23 AS NUMERIC(5,2)) AS null_times_numeric,
    CAST(1.23 AS NUMERIC(5,2)) / NULL AS numeric_divided_by_null,
    COALESCE(NULL, CAST(1.23 AS NUMERIC(5,2))) AS coalesce_null_numeric;
GO

-- Testing with extreme precision differences
SELECT 'Extreme Precision Differences' AS edge_case_test;
SELECT 
    CAST(1 AS NUMERIC(1,0)) + CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,38)) AS add_tiny_to_small,
    CAST(99999999999999999999999999999999999999 AS NUMERIC(38,0)) + CAST(0.5 AS NUMERIC(2,1)) AS add_small_to_huge;
GO

-- Testing with precision loss in calculations
SELECT 'Precision Loss in Calculations' AS edge_case_test;
SELECT 
    CAST(1.23456789 AS NUMERIC(10,8)) AS original_value,
    CAST(CAST(1.23456789 AS NUMERIC(10,8)) AS NUMERIC(10,4)) AS direct_cast_loss,
    CAST(CAST(1.23456789 AS NUMERIC(10,8)) * 1 AS NUMERIC(10,4)) AS calculation_then_cast;
GO

-- Testing with division that results in repeating decimals
SELECT 'Repeating Decimals' AS edge_case_test;
SELECT 
    CAST(1 AS NUMERIC(38,36)) / CAST(3 AS NUMERIC(38,36)) AS one_third_numeric,
    CAST(1 AS DECIMAL(38,36)) / CAST(3 AS DECIMAL(38,36)) AS one_third_decimal,
    CAST(2 AS NUMERIC(38,36)) / CAST(3 AS NUMERIC(38,36)) AS two_thirds_numeric,
    CAST(2 AS DECIMAL(38,36)) / CAST(3 AS DECIMAL(38,36)) AS two_thirds_decimal;
GO

-- Testing with calculations that might cause overflow
SELECT 'Potential Overflow Calculations' AS edge_case_test;
SELECT 
    CAST(9999999999 AS NUMERIC(10,0)) * CAST(9999999999 AS NUMERIC(10,0)) AS large_multiplication_result,
    POWER(CAST(10 AS NUMERIC(2,0)), 38) AS power_to_max_precision;
GO

-- Testing with negative scales
SELECT 'Negative Scale Tests' AS edge_case_test;
SELECT 
    ROUND(CAST(1234.56789 AS NUMERIC(10,5)), -1) AS round_to_tens,
    ROUND(CAST(1234.56789 AS NUMERIC(10,5)), -2) AS round_to_hundreds,
    ROUND(CAST(1234.56789 AS NUMERIC(10,5)), -3) AS round_to_thousands;
GO

-- Testing with identity columns

-- Table with precision 18
CREATE TABLE identity_test_table1 (
    id_col DECIMAL(18,0) IDENTITY(1000,100),
    description VARCHAR(50)
);
GO

INSERT INTO identity_test_table1 (description) VALUES ('Test 1');
GO

INSERT INTO identity_test_table1 (description) VALUES ('Test 2');
GO

INSERT INTO identity_test_table1 (description) VALUES ('Test 3');
GO

SELECT * FROM identity_test_table1;
GO

DROP TABLE identity_test_table1;
GO

-- Table with precision greater than 18 
CREATE TABLE identity_test_table2 (
    id_col DECIMAL(20,0) IDENTITY(1000,100),
    description VARCHAR(50)
);
GO


------------------------------------------------------------------------
---- 12. User Defined Type Tests
------------------------------------------------------------------------

-- Create user-defined types with different precisions and scales
CREATE TYPE SmallAmount FROM NUMERIC(5,2);
GO

CREATE TYPE LargeAmount FROM NUMERIC(20,2);
GO

CREATE TYPE ExactDecimal FROM DECIMAL(10,5);
GO

CREATE TYPE WholeNumber FROM NUMERIC(18,0);
GO

CREATE TYPE MoneyAmount FROM DECIMAL(19,4);
GO

CREATE TYPE Percentage FROM NUMERIC(5,4);
GO

CREATE TYPE ScientificValue FROM NUMERIC(30,10);
GO

CREATE TYPE TinyValue FROM NUMERIC(3,2);
GO

------------------------------------------------------------------------
---- 12.1 Basic UDT Tests
------------------------------------------------------------------------

CREATE TABLE udt_numeric_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    small_amount SmallAmount,
    large_amount LargeAmount,
    exact_decimal ExactDecimal,
    whole_number WholeNumber
);
GO

-- Test NULL values
INSERT INTO udt_numeric_test (small_amount, large_amount, exact_decimal, whole_number)
VALUES (NULL, NULL, NULL, NULL);
GO

-- Validate NULL insertions
SELECT CASE 
    WHEN small_amount IS NULL AND large_amount IS NULL 
    AND exact_decimal IS NULL AND whole_number IS NULL THEN 'NULL test passed'
    ELSE 'NULL test failed'
END AS null_test_result
FROM udt_numeric_test WHERE id = 1;
GO

-- Test zero values
INSERT INTO udt_numeric_test (small_amount, large_amount, exact_decimal, whole_number)
VALUES (0, 0, 0, 0);
GO

-- Validate zero insertions
SELECT CASE 
    WHEN small_amount = 0 AND large_amount = 0 
    AND exact_decimal = 0 AND whole_number = 0 THEN 'Zero test passed'
    ELSE 'Zero test failed'
END AS zero_test_result
FROM udt_numeric_test WHERE id = 2;
GO

-- Test positive values within range
INSERT INTO udt_numeric_test (small_amount, large_amount, exact_decimal, whole_number)
VALUES (123.45, 123456789.12, 123.45678, 123456);
GO

-- Validate positive value insertions
SELECT CASE 
    WHEN small_amount = 123.45 AND large_amount = 123456789.12 
    AND exact_decimal = 123.45678 AND whole_number = 123456 THEN 'Positive value test passed'
    ELSE 'Positive value test failed'
END AS positive_test_result
FROM udt_numeric_test WHERE id = 3;
GO

-- Test negative values
INSERT INTO udt_numeric_test (small_amount, large_amount, exact_decimal, whole_number)
VALUES (-123.45, -123456789.12, -123.45678, -123456);
GO

-- Validate negative value insertions
SELECT CASE 
    WHEN small_amount = -123.45 AND large_amount = -123456789.12 
    AND exact_decimal = -123.45678 AND whole_number = -123456 THEN 'Negative value test passed'
    ELSE 'Negative value test failed'
END AS negative_test_result
FROM udt_numeric_test WHERE id = 4;
GO

------------------------------------------------------------------------
---- 12.2 Complex UDT Scenarios
------------------------------------------------------------------------

CREATE TABLE udt_complex_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    price MoneyAmount,
    discount_rate Percentage,
    scientific_measure ScientificValue,
    small_measure TinyValue,
    description VARCHAR(100)
);
GO

-- Test precision boundaries
INSERT INTO udt_complex_test (price, discount_rate, scientific_measure, small_measure, description)
VALUES 
    (9999999999999.9999, 0.9999, 12345678901234567890.1234567890, 9.99, 'Maximum values within precision');
GO

-- Validate precision boundary test
SELECT CASE 
    WHEN price = 9999999999999.9999 AND discount_rate = 0.9999 
    AND scientific_measure = 12345678901234567890.1234567890 
    AND small_measure = 9.99 THEN 'Precision boundary test passed'
    ELSE 'Precision boundary test failed'
END AS precision_test_result
FROM udt_complex_test WHERE id = 1;
GO

-- Test decimal alignment
INSERT INTO udt_complex_test (price, discount_rate, scientific_measure, small_measure, description)
VALUES 
    (1234.5000, 0.5000, 1234.0000000000, 1.20, 'Aligned decimals');
GO

-- Validate decimal alignment
SELECT CASE 
    WHEN CAST(price AS VARCHAR(20)) = '1234.5000' 
    AND CAST(discount_rate AS VARCHAR(20)) = '0.5000'
    AND CAST(scientific_measure AS VARCHAR(30)) = '1234.0000000000'
    AND CAST(small_measure AS VARCHAR(20)) = '1.20' THEN 'Decimal alignment test passed'
    ELSE 'Decimal alignment test failed'
END AS alignment_test_result
FROM udt_complex_test WHERE id = 2;
GO

------------------------------------------------------------------------
---- 12.3 UDT Function Tests
------------------------------------------------------------------------

CREATE FUNCTION calculate_discount
(
    @price MoneyAmount,
    @rate Percentage
)
RETURNS MoneyAmount
AS
BEGIN
    RETURN @price * @rate;
END;
GO

-- Test function with known values
DECLARE @test_price MoneyAmount = 100.0000;
DECLARE @test_rate Percentage = 0.2500;
DECLARE @expected_result MoneyAmount = 25.0000;
DECLARE @actual_result MoneyAmount;

SET @actual_result = dbo.calculate_discount(@test_price, @test_rate);

SELECT CASE 
    WHEN @actual_result = @expected_result THEN 'Function test passed'
    ELSE 'Function test failed: Expected ' + CAST(@expected_result AS VARCHAR) + 
         ', Got ' + CAST(@actual_result AS VARCHAR)
END AS function_test_result;
GO

------------------------------------------------------------------------
---- 12.4 UDT Arithmetic Tests
------------------------------------------------------------------------

CREATE TABLE udt_arithmetic_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    value1 MoneyAmount,
    value2 MoneyAmount
);
GO

INSERT INTO udt_arithmetic_test (value1, value2) VALUES (100.0000, 50.0000);
GO

-- Test and validate arithmetic operations
SELECT 
    CASE WHEN value1 + value2 = 150.0000 THEN 'Addition test passed'
         ELSE 'Addition test failed' END AS addition_test,
    CASE WHEN value1 - value2 = 50.0000 THEN 'Subtraction test passed'
         ELSE 'Subtraction test failed' END AS subtraction_test,
    CASE WHEN value1 * 2 = 200.0000 THEN 'Multiplication test passed'
         ELSE 'Multiplication test failed' END AS multiplication_test,
    CASE WHEN value1 / 2 = 50.0000 THEN 'Division test passed'
         ELSE 'Division test failed' END AS division_test
FROM udt_arithmetic_test;
GO

------------------------------------------------------------------------
---- 12.5 UDT Constraint Tests
------------------------------------------------------------------------

CREATE TABLE udt_constraint_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    price MoneyAmount CHECK (price >= 0),
    discount_rate Percentage CHECK (discount_rate BETWEEN 0 AND 1),
    CONSTRAINT valid_price_range CHECK (price <= 1000000)
);
GO

-- Test constraint violations (these should fail)
BEGIN TRY
    INSERT INTO udt_constraint_test (price, discount_rate)
    VALUES (-100, 0.5);
    PRINT 'Constraint test 1 failed - Negative price was accepted';
END TRY
BEGIN CATCH
    PRINT 'Constraint test 1 passed - Negative price was rejected';
END CATCH
GO

BEGIN TRY
    INSERT INTO udt_constraint_test (price, discount_rate)
    VALUES (100, 1.5);
    PRINT 'Constraint test 2 failed - Invalid discount rate was accepted';
END TRY
BEGIN CATCH
    PRINT 'Constraint test 2 passed - Invalid discount rate was rejected';
END CATCH
GO

------------------------------------------------------------------------
---- 12.6 UDT Computed Column Tests
------------------------------------------------------------------------

CREATE TABLE udt_computed_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    base_price MoneyAmount,
    tax_rate Percentage,
    tax_amount AS (base_price * tax_rate) PERSISTED,
    final_price AS (base_price + (base_price * tax_rate)) PERSISTED
);
GO

INSERT INTO udt_computed_test (base_price, tax_rate)
VALUES (100.0000, 0.2000);
GO

-- Validate computed columns
SELECT CASE 
    WHEN tax_amount = 20.0000 AND final_price = 120.0000 THEN 'Computed column test passed'
    ELSE 'Computed column test failed: Expected tax_amount=20.0000 and final_price=120.0000, Got tax_amount=' + 
         CAST(tax_amount AS VARCHAR) + ' and final_price=' + CAST(final_price AS VARCHAR)
END AS computed_column_test_result
FROM udt_computed_test;
GO

------------------------------------------------------------------------
---- 12.7 Cleanup
------------------------------------------------------------------------

-- Drop all test tables
DROP TABLE udt_numeric_test;
GO
DROP TABLE udt_complex_test;
GO
DROP TABLE udt_arithmetic_test;
GO
DROP TABLE udt_constraint_test;
GO
DROP TABLE udt_computed_test;
GO

-- Drop all functions
DROP FUNCTION calculate_discount;
GO

-- Drop all user-defined types
DROP TYPE SmallAmount;
GO
DROP TYPE LargeAmount;
GO
DROP TYPE ExactDecimal;
GO
DROP TYPE WholeNumber;
GO
DROP TYPE MoneyAmount;
GO
DROP TYPE Percentage;
GO
DROP TYPE ScientificValue;
GO
DROP TYPE TinyValue;
GO


------------------------------------------------------------------------
---- 13. UNION Tests with Different Types/Precision/Scales
------------------------------------------------------------------------

---- 13.1 Create User-Defined Types for UNION testing
CREATE TYPE SmallNumeric FROM NUMERIC(5,2);
GO

CREATE TYPE LargeNumeric FROM NUMERIC(18,4);
GO

CREATE TYPE ScientificNumeric FROM NUMERIC(38,10);
GO

---- 13.2 Basic UNION Tests with Direct SELECT and CAST
-- Test: UNION between different precisions/scales
SELECT 'NUMERIC_10_2' as source_type, CAST(123.456 AS NUMERIC(10,2)) as val
UNION
SELECT 'NUMERIC_15_3', CAST(123.456 AS NUMERIC(15,3))
UNION
SELECT 'NUMERIC_12_4', CAST(123.456 AS NUMERIC(12,4))
ORDER BY source_type;
GO

---- 13.3 Complex UNION Tests with Expressions
-- Test: UNION with complex expressions and different types
SELECT 'EXPR1' as source_type, 
       CAST(POWER(2, 10) AS NUMERIC(10,2)) * CAST(1.23456 AS NUMERIC(8,5)) as val
UNION
SELECT 'EXPR2', 
       CAST(EXP(5) AS NUMERIC(12,4)) * CAST(0.987654321 AS NUMERIC(10,9))
UNION
SELECT 'EXPR3', 
       CAST(PI() AS NUMERIC(15,10)) * CAST(100.5 AS NUMERIC(5,1))
ORDER BY source_type;
GO

---- 13.4 UNION with UDTs and Mixed Types
DECLARE @small_val SmallNumeric = 123.45;
DECLARE @large_val LargeNumeric = 123456.7890;
DECLARE @scientific_val ScientificNumeric = 123456789.0123456789;

-- Test: UNION between UDTs and built-in types
SELECT 'UDT_SMALL' as source_type, CAST(@small_val AS NUMERIC(5,2)) as val
UNION
SELECT 'UDT_LARGE', CAST(@large_val AS NUMERIC(18,4))
UNION
SELECT 'UDT_SCIENTIFIC', CAST(@scientific_val AS NUMERIC(38,10))
UNION
SELECT 'DIRECT_NUMERIC', CAST(123.456789 AS NUMERIC(20,6))
ORDER BY source_type;
GO

---- 13.5 UNION with Complex Mathematical Operations
-- Test: UNION with mathematical functions
SELECT 'MATH1' as source_type,
       CAST(SQRT(POWER(CAST(2 AS NUMERIC(10,5)), 10)) AS NUMERIC(15,5)) as val
UNION
SELECT 'MATH2',
       CAST(EXP(CAST(LN(10.5) AS NUMERIC(10,5))) AS NUMERIC(12,6))
UNION
SELECT 'MATH3',
       CAST(POWER(CAST(PI() AS NUMERIC(15,10)), 2) AS NUMERIC(20,10))
ORDER BY source_type;
GO

---- 13.6 UNION with Nested Calculations
-- Test: UNION with CASE expressions
SELECT 'NESTED1' as source_type,
       CAST(
           CASE 
               WHEN CAST(PI() AS NUMERIC(15,10)) > 3 
               THEN POWER(CAST(2.5 AS NUMERIC(5,2)), 3)
               ELSE SQRT(CAST(100 AS NUMERIC(10,2)))
           END AS NUMERIC(20,10)
       ) as val
UNION
SELECT 'NESTED2',
       CAST(
           CASE 
               WHEN CAST(EXP(1) AS NUMERIC(15,10)) > 2 
               THEN POWER(CAST(3.5 AS NUMERIC(5,2)), 2)
               ELSE SQRT(CAST(200 AS NUMERIC(10,2)))
           END AS NUMERIC(20,10)
       )
ORDER BY val;
GO

---- 13.7 UNION with Extreme Values and Calculations
-- Test: UNION with boundary values
SELECT 'EXTREME1' as source_type,
       CAST(9999999999999999.999999999999 AS NUMERIC(38,12)) as val
UNION
SELECT 'EXTREME2',
       CAST(0.000000000001 AS NUMERIC(38,12))
UNION
SELECT 'EXTREME3',
       CAST(
           POWER(CAST(10 AS NUMERIC(38,12)), 20) / 
           CAST(3 AS NUMERIC(38,12))
       AS NUMERIC(38,12))
ORDER BY source_type;
GO

---- 13.8 UNION with Mixed Scale Calculations
-- Test: UNION with different scale multiplications
SELECT 'MIXED1' as source_type,
       CAST(123.45 AS NUMERIC(10,2)) * CAST(0.0000000001 AS NUMERIC(20,10)) as val
UNION
SELECT 'MIXED2',
       CAST(9876.54321 AS NUMERIC(15,5)) * CAST(0.0000000001 AS NUMERIC(20,10))
UNION
SELECT 'MIXED3',
       CAST(
           CAST(1234567.89 AS NUMERIC(10,2)) * 
           CAST(0.0000000001 AS NUMERIC(20,10))
       AS NUMERIC(30,15))
ORDER BY val;
GO

---- 13.9 UNION with NULL and Zero Values
-- Test: UNION with NULL and zero values
SELECT 'NULL_VAL' as source_type, CAST(NULL AS NUMERIC(10,2)) as val
UNION
SELECT 'ZERO_NUMERIC', CAST(0 AS NUMERIC(10,2))
UNION
SELECT 'ZERO_SCIENTIFIC', CAST(0.0000000000 AS NUMERIC(20,10))
ORDER BY source_type;
GO

---- 13.10 UNION ALL vs UNION Tests
-- Test: Compare UNION ALL with UNION for duplicate handling
SELECT 'PRECISION_5_2' as source_type, CAST(123.45 AS NUMERIC(5,2)) as val
UNION ALL
SELECT 'PRECISION_10_2', CAST(123.45 AS NUMERIC(10,2))
UNION ALL
SELECT 'PRECISION_15_2', CAST(123.45 AS NUMERIC(15,2))
ORDER BY source_type;
GO

SELECT 'PRECISION_5_2' as source_type, CAST(123.45 AS NUMERIC(5,2)) as val
UNION
SELECT 'PRECISION_10_2', CAST(123.45 AS NUMERIC(10,2))
UNION
SELECT 'PRECISION_15_2', CAST(123.45 AS NUMERIC(15,2))
ORDER BY source_type;
GO

---- 13.11 UNION with Mixed NUMERIC and DECIMAL Types
-- Test: UNION between NUMERIC and DECIMAL types
SELECT 'NUMERIC_VAL' as source_type, CAST(123.456 AS NUMERIC(10,3)) as val
UNION
SELECT 'DECIMAL_VAL', CAST(123.456 AS DECIMAL(10,3))
UNION
SELECT 'NUMERIC_LARGER', CAST(123.456 AS NUMERIC(15,3))
UNION
SELECT 'DECIMAL_LARGER', CAST(123.456 AS DECIMAL(15,3))
ORDER BY source_type;
GO

-- 13.12 UNION with Calculated Columns
-- Test: UNION with arithmetic operations
SELECT 
    'CALC1' as source_type,
    val,
    val * 2 as doubled,
    val / 2 as halved,
    val + 100 as added,
    val - 100 as subtracted
FROM (
    SELECT CAST(123.45 AS NUMERIC(10,2)) as val
    UNION
    SELECT CAST(456.78 AS NUMERIC(10,2))
) t
ORDER BY val;
GO

---- 13.13 UNION with Negative Scale
-- Test: UNION with negative scale values
SELECT 'NEG_SCALE1' as source_type, 
       CAST(ROUND(12345.6789, -2) AS NUMERIC(10,2)) as val
UNION
SELECT 'NEG_SCALE2', 
       CAST(ROUND(67890.1234, -1) AS NUMERIC(10,2))
UNION
SELECT 'NEG_SCALE3', 
       CAST(ROUND(11111.2222, -3) AS NUMERIC(10,2))
ORDER BY source_type;
GO


---- 13.14 UNION with Mixed Data Types and UDTs Resolution
-- Test: UNION between INTEGER types, NUMERIC, and UDTs
DECLARE @small_num SmallNumeric = 123.45;
DECLARE @large_num LargeNumeric = 123.4567;

SELECT 'INT' as source_type, 
       CAST(123 AS INT) as val
UNION
SELECT 'BIGINT', 
       CAST(123 AS BIGINT)
UNION
SELECT 'SMALLINT', 
       CAST(123 AS SMALLINT)
UNION
SELECT 'TINYINT', 
       CAST(123 AS TINYINT)
UNION
SELECT 'NUMERIC', 
       CAST(123 AS NUMERIC(10,2))
UNION
SELECT 'UDT_SMALL',
       @small_num
UNION
SELECT 'UDT_LARGE',
       @large_num
ORDER BY source_type;
GO

-- Test: UNION between FLOAT/REAL, NUMERIC, and UDTs
DECLARE @scientific_num ScientificNumeric = 123.4567890123;

SELECT 'FLOAT' as source_type, 
       CAST(123.456 AS FLOAT) as val
UNION
SELECT 'REAL', 
       CAST(123.456 AS REAL)
UNION
SELECT 'NUMERIC_10_2', 
       CAST(123.456 AS NUMERIC(10,2))
UNION
SELECT 'UDT_SCIENTIFIC',
       @scientific_num
ORDER BY source_type;
GO

-- Test: Complex mixed type expressions with UDTs
DECLARE @small_num SmallNumeric = 123.45;
DECLARE @large_num LargeNumeric = 123.4567;

SELECT 'INT_FLOAT' as source_type,
       CAST(123 AS INT) * CAST(1.5 AS FLOAT) as val
UNION
SELECT 'UDT_SMALL_FLOAT',
       @small_num * CAST(1.5 AS FLOAT)
UNION
SELECT 'UDT_LARGE_INT',
       @large_num * CAST(2 AS INT)
UNION
SELECT 'REAL_NUMERIC',
       CAST(123.45 AS REAL) * CAST(1.5 AS NUMERIC(5,2))
ORDER BY source_type;
GO

-- Test: Mathematical functions with mixed types and UDTs
DECLARE @small_num SmallNumeric = 100.00;
DECLARE @large_num LargeNumeric = 2.5;

SELECT 'POWER_FLOAT' as source_type,
       POWER(CAST(2 AS FLOAT), CAST(10 AS INT)) as val
UNION
SELECT 'SQRT_UDT',
       SQRT(CAST(@small_num AS NUMERIC(10,2)))
UNION
SELECT 'POWER_UDT',
       POWER(@large_num, 2)
ORDER BY source_type;
GO

-- Test: Aggregate functions with mixed types and UDTs
DECLARE @small_num1 SmallNumeric = 100.00;
DECLARE @small_num2 SmallNumeric = 200.00;
DECLARE @large_num LargeNumeric = 300.00;

SELECT 'SUM' as source_type,
       SUM(val) as val
FROM (
    SELECT CAST(100 AS INT) as val
    UNION ALL
    SELECT CAST(200.5 AS FLOAT)
    UNION ALL
    SELECT @small_num1
    UNION ALL
    SELECT @large_num
) t
UNION
SELECT 'AVG',
       AVG(val)
FROM (
    SELECT CAST(100 AS INT) as val
    UNION ALL
    SELECT CAST(200.5 AS FLOAT)
    UNION ALL
    SELECT @small_num2
    UNION ALL
    SELECT @large_num
) t
ORDER BY source_type;
GO

-- Test: CASE expressions with mixed types and UDTs
DECLARE @small_num SmallNumeric = 100.00;
DECLARE @large_num LargeNumeric = 200.00;

SELECT 'CASE1' as source_type,
       CASE 
           WHEN CAST(1 AS BIT) = 1 THEN @small_num
           WHEN CAST(0 AS BIT) = 1 THEN CAST(200.5 AS FLOAT)
           ELSE CAST(300.99 AS NUMERIC(10,2))
       END as val
UNION
SELECT 'CASE2',
       CASE 
           WHEN CAST(0 AS BIT) = 1 THEN CAST(100 AS MONEY)
           WHEN CAST(1 AS BIT) = 1 THEN @large_num
           ELSE CAST(300.99 AS NUMERIC(10,2))
       END
ORDER BY source_type;
GO

-- Test: Mixed types with NULL values including UDTs
SELECT 'NULL_INT' as source_type,
       CAST(NULL AS INT) as val
UNION
SELECT 'NULL_FLOAT',
       CAST(NULL AS FLOAT)
UNION
SELECT 'NULL_UDT_SMALL',
       CAST(NULL AS SmallNumeric)
UNION
SELECT 'NULL_UDT_LARGE',
       CAST(NULL AS LargeNumeric)
ORDER BY source_type;
GO

-- Test: Arithmetic operations with mixed types and UDTs
DECLARE @small_num SmallNumeric = 100.00;
DECLARE @large_num LargeNumeric = 200.00;

SELECT 'ADD_UDT' as source_type,
       @small_num + CAST(200.5 AS FLOAT) as val
UNION
SELECT 'SUBTRACT_UDT',
       @large_num - CAST(100 AS INT)
UNION
SELECT 'MULTIPLY_UDT',
       @small_num * CAST(2.5 AS MONEY)
UNION
SELECT 'DIVIDE_UDT',
       @large_num / CAST(2.5 AS FLOAT)
ORDER BY source_type;
GO

-- Test: Mixed precision with UDTs
DECLARE @scientific_num ScientificNumeric = 123.4567890123;

SELECT 'FLOAT_24' as source_type,
       CAST(123.456 AS FLOAT(24)) as val
UNION
SELECT 'UDT_SCIENTIFIC',
       @scientific_num
UNION
SELECT 'NUMERIC_EQUIV',
       CAST(123.456 AS NUMERIC(17,3))
ORDER BY source_type;
GO

-- Test: Extreme values with UDTs
DECLARE @large_num LargeNumeric = 9999999999.9999;
DECLARE @scientific_num ScientificNumeric = 9999999999.9999999999;

SELECT 'MAX_INT' as source_type,
       CAST(2147483647 AS INT) as val
UNION
SELECT 'UDT_LARGE',
       @large_num
UNION
SELECT 'UDT_SCIENTIFIC',
       @scientific_num
UNION
SELECT 'NUMERIC_EQUIV',
       CAST(2147483647 AS NUMERIC(10,0))
ORDER BY source_type;
GO

-- Test: Decimal places in mixed type operations with UDTs
DECLARE @small_num SmallNumeric = 100.00;
DECLARE @scientific_num ScientificNumeric = 1.23456789;

SELECT 'PRECISE1' as source_type,
       CAST(100 AS INT) * @scientific_num as val
UNION
SELECT 'PRECISE2',
       @small_num * CAST(1.23456789 AS FLOAT)
UNION
SELECT 'PRECISE3',
       CAST(100 AS MONEY) * @scientific_num
ORDER BY source_type;
GO

-- Cleanup
DROP TYPE SmallNumeric;
GO

DROP TYPE LargeNumeric;
GO

DROP TYPE ScientificNumeric;
GO

------------------------------------------------------------------------
---- 14. Index Tests with NUMERIC and Binary-Coercible Types
------------------------------------------------------------------------

-- Create test tables with different numeric types and indexes
CREATE TABLE numeric_index_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    num_col NUMERIC(18,2),
    num_precise_col NUMERIC(38,10),
    decimal_col DECIMAL(18,2),
    int_col INT,
    bigint_col BIGINT,
    smallint_col SMALLINT,
    float_col FLOAT,
    money_col MONEY,
    category VARCHAR(10)
);
GO

-- Create indexes on numeric columns
CREATE INDEX idx_numeric ON numeric_index_test(num_col);
CREATE INDEX idx_numeric_precise ON numeric_index_test(num_precise_col);
CREATE INDEX idx_decimal ON numeric_index_test(decimal_col);
CREATE INDEX idx_composite_num_cat ON numeric_index_test(num_col, category);
GO

-- Store some specific values for testing
INSERT INTO numeric_index_test (
    num_col, num_precise_col, decimal_col, int_col, 
    bigint_col, smallint_col, float_col, money_col, category
) VALUES 
(123.45, 123.4567890123, 123.45, 123, 123000, 123, 123.45, 123.45, 'CAT-1'),
(500.00, 500.0000000000, 500.00, 500, 500000, 500, 500.00, 500.00, 'CAT-2'),
(999.99, 999.9999999999, 999.99, 999, 999999, 999, 999.99, 999.99, 'CAT-3');
GO

SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_timing', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_summary', 'off', false)
SELECT set_config('enable_seqscan', 'off', false);
SELECT set_config('enable_bitmapscan', 'off', false);
SET BABELFISH_STATISTICS PROFILE ON;
go

-- Test 1: Direct NUMERIC comparison (baseline)

-- Should use idx_numeric
SELECT * FROM numeric_index_test 
WHERE num_col = 123.45;
GO

-- Test 2: NUMERIC compared with INTEGER
SELECT * FROM numeric_index_test 
WHERE num_col = 500;
GO

-- Test 3: NUMERIC compared with DECIMAL
SELECT * FROM numeric_index_test 
WHERE num_col = CAST(999.99 AS DECIMAL(18,2));
GO

-- Test 4: NUMERIC compared with FLOAT
SELECT * FROM numeric_index_test 
WHERE num_col = CAST(123.45 AS FLOAT);
GO

-- Test 5: NUMERIC compared with MONEY
SELECT * FROM numeric_index_test 
WHERE num_col = CAST(500.00 AS MONEY);
GO

-- Test 6: Range queries with different types
SELECT * FROM numeric_index_test 
WHERE num_col BETWEEN 100 AND CAST(200 AS INT);
GO

SELECT * FROM numeric_index_test 
WHERE num_col BETWEEN 400.00 AND CAST(600.00 AS DECIMAL(18,2));
GO

-- Test 7: JOIN conditions with different numeric types
SELECT a.*, b.* 
FROM numeric_index_test a
JOIN numeric_index_test b ON a.num_col = b.decimal_col;
GO

-- Test 8: Complex conditions mixing types
SELECT * FROM numeric_index_test 
WHERE num_col = int_col 
   OR num_col = CAST(float_col AS NUMERIC(18,2))
   OR num_col = CAST(money_col AS NUMERIC(18,2));
GO

-- Test 9: Composite index tests with type mixing
SELECT * FROM numeric_index_test 
WHERE num_col = CAST(500 AS INT)
  AND category = 'CAT-2';
GO

-- Test 10: Index usage with calculations
SELECT * FROM numeric_index_test 
WHERE num_col = int_col + 0.45;
GO

-- Test 11: Index usage with CAST operations
SELECT * FROM numeric_index_test 
WHERE CAST(num_col AS DECIMAL(18,2)) = decimal_col;
GO

-- Test 12: Implicit conversions
SELECT * FROM numeric_index_test 
WHERE num_col IN (123, 123.45, 123.45678);
GO

-- Test 13: Different precision/scale comparisons
SELECT * FROM numeric_index_test 
WHERE num_precise_col = CAST(123.4567890123 AS NUMERIC(38,10));
GO

-- Test 14: Index intersection possibilities
SELECT * FROM numeric_index_test 
WHERE num_col = 123.45
  AND decimal_col = 123.45;
GO

-- Test 15: ORDER BY with different types
SELECT * FROM numeric_index_test 
WHERE num_col > 100
ORDER BY decimal_col;
GO

-- Test 16: GROUP BY with different types
SELECT CAST(num_col AS DECIMAL(18,2)) as num_group, 
       COUNT(*) as cnt
FROM numeric_index_test 
GROUP BY CAST(num_col AS DECIMAL(18,2));
GO

-- Test 17: Covering index scenarios
SELECT num_col, category 
FROM numeric_index_test 
WHERE num_col = 500.00;
GO

-- Test 18: Index usage with NULL values
INSERT INTO numeric_index_test (
    num_col, decimal_col, int_col, category
) VALUES (NULL, NULL, NULL, 'CAT-N');
GO

SELECT * FROM numeric_index_test 
WHERE num_col IS NULL;
GO

-- Test 19: Index usage with arithmetic operations
SELECT * FROM numeric_index_test 
WHERE num_col * 2 = decimal_col;
GO

-- Reset
SET BABELFISH_STATISTICS PROFILE OFF;
SELECT set_config('babelfishpg_tsql.explain_costs', 'on', false)
SELECT set_config('babelfishpg_tsql.explain_timing', 'on', false)
SELECT set_config('babelfishpg_tsql.explain_summary', 'on', false)
SELECT set_config('enable_seqscan', 'on', false);
SELECT set_config('enable_bitmapscan', 'on', false);
go

-- Cleanup
DROP TABLE numeric_index_test;
GO


------------------------------------------------------------------------
---- 15.Partition Table Tests for Numeric Types
------------------------------------------------------------------------
CREATE PARTITION FUNCTION NUMERIC_dt_partition_func (NUMERIC(18,2))
    AS RANGE RIGHT FOR VALUES(
        0.00,
        1000.00,
        10000.00,
        100000.00
    );
GO

CREATE PARTITION SCHEME NUMERIC_dt_partition_scheme
    AS PARTITION NUMERIC_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE NUMERIC_dt_partition(
    amount NUMERIC(18,2),
    category VARCHAR(20)
)
ON NUMERIC_dt_partition_scheme(amount);
GO

-- Insert test data for different ranges
INSERT INTO NUMERIC_dt_partition (amount, category) VALUES 
(-1000.00, 'Negative'),
(-500.00, 'Negative'),
(0.00, 'Zero'),
(500.00, 'Small'),
(1500.00, 'Medium'),
(5000.00, 'Medium'),
(15000.00, 'Large'),
(50000.00, 'Large'),
(150000.00, 'Extra Large'),
(200000.00, 'Extra Large');
GO

-- Query to show amounts in each partition
SELECT amount, category, 
       $PARTITION.NUMERIC_dt_partition_func(amount) AS PartitionNumber
FROM NUMERIC_dt_partition 
ORDER BY PartitionNumber;
GO

-- Query to show count by partition
SELECT $PARTITION.NUMERIC_dt_partition_func(amount) AS PartitionNumber, 
       category, 
       COUNT(*) AS AmountCount
FROM NUMERIC_dt_partition
GROUP BY $PARTITION.NUMERIC_dt_partition_func(amount), category
ORDER BY PartitionNumber, category;
GO

-- Partitioned table testing for DECIMAL
CREATE PARTITION FUNCTION DECIMAL_dt_partition_func (DECIMAL(18,2))
    AS RANGE RIGHT FOR VALUES(
        0.00,
        1000.00,
        10000.00,
        100000.00
    );
GO

CREATE PARTITION SCHEME DECIMAL_dt_partition_scheme
    AS PARTITION DECIMAL_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE DECIMAL_dt_partition(
    amount DECIMAL(18,2),
    category VARCHAR(20)
)
ON DECIMAL_dt_partition_scheme(amount);
GO

-- Insert test data for different ranges
INSERT INTO DECIMAL_dt_partition (amount, category) VALUES 
(-1000.00, 'Negative'),
(-500.00, 'Negative'),
(0.00, 'Zero'),
(500.00, 'Small'),
(1500.00, 'Medium'),
(5000.00, 'Medium'),
(15000.00, 'Large'),
(50000.00, 'Large'),
(150000.00, 'Extra Large'),
(200000.00, 'Extra Large');
GO

-- Query to show amounts in each partition
SELECT amount, category, 
       $PARTITION.DECIMAL_dt_partition_func(amount) AS PartitionNumber
FROM DECIMAL_dt_partition 
ORDER BY PartitionNumber;
GO

-- Query to show count by partition
SELECT $PARTITION.DECIMAL_dt_partition_func(amount) AS PartitionNumber, 
       category, 
       COUNT(*) AS AmountCount
FROM DECIMAL_dt_partition
GROUP BY $PARTITION.DECIMAL_dt_partition_func(amount), category
ORDER BY PartitionNumber;
GO

-- Additional test for precision and scale variations
CREATE PARTITION FUNCTION NUMERIC_PRECISE_dt_partition_func (NUMERIC(38,10))
    AS RANGE RIGHT FOR VALUES(
        0.0000000000,
        1000.0000000000,
        10000.0000000000,
        100000.0000000000
    );
GO

CREATE PARTITION SCHEME NUMERIC_PRECISE_dt_partition_scheme
    AS PARTITION NUMERIC_PRECISE_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE NUMERIC_PRECISE_dt_partition(
    amount NUMERIC(38,10),
    category VARCHAR(20)
)
ON NUMERIC_PRECISE_dt_partition_scheme(amount);
GO

-- Insert test data with high precision
INSERT INTO NUMERIC_PRECISE_dt_partition (amount, category) VALUES 
(-1000.1234567890, 'Negative'),
(-500.0987654321, 'Negative'),
(0.0000000001, 'Zero'),
(500.1111111111, 'Small'),
(1500.2222222222, 'Medium'),
(5000.3333333333, 'Medium'),
(15000.4444444444, 'Large'),
(50000.5555555555, 'Large'),
(150000.6666666666, 'Extra Large'),
(200000.7777777777, 'Extra Large');
GO

-- Query to show high precision amounts in each partition
SELECT amount, category, 
       $PARTITION.NUMERIC_PRECISE_dt_partition_func(amount) AS PartitionNumber
FROM NUMERIC_PRECISE_dt_partition 
ORDER BY PartitionNumber;
GO

-- Query to show count by partition for high precision
SELECT $PARTITION.NUMERIC_PRECISE_dt_partition_func(amount) AS PartitionNumber, 
       category, 
       COUNT(*) AS AmountCount
FROM NUMERIC_PRECISE_dt_partition
GROUP BY $PARTITION.NUMERIC_PRECISE_dt_partition_func(amount), category
ORDER BY PartitionNumber;
GO

-- Cleanup
DROP TABLE NUMERIC_dt_partition;
DROP TABLE DECIMAL_dt_partition;
DROP TABLE NUMERIC_PRECISE_dt_partition;
DROP PARTITION SCHEME NUMERIC_dt_partition_scheme;
DROP PARTITION SCHEME DECIMAL_dt_partition_scheme;
DROP PARTITION SCHEME NUMERIC_PRECISE_dt_partition_scheme;
DROP PARTITION FUNCTION NUMERIC_dt_partition_func;
DROP PARTITION FUNCTION DECIMAL_dt_partition_func;
DROP PARTITION FUNCTION NUMERIC_PRECISE_dt_partition_func;
GO


------------------------------------------------------------------------
---- 16. Numeric types as default and check constraints
------------------------------------------------------------------------
CREATE TABLE NUMERIC_dt(
    a NUMERIC(18,2) DEFAULT 100.00, 
    b NUMERIC(18,2), 
    c INT, 
    CHECK (b > 1000.00)
);
GO

INSERT INTO NUMERIC_dt (b,c) VALUES (1500.00, 1);
GO
INSERT INTO NUMERIC_dt (b,c) VALUES (500.00, 2);  -- Should fail check constraint
GO

SELECT * FROM NUMERIC_dt;
GO

DROP TABLE NUMERIC_dt;
GO

CREATE TABLE DECIMAL_dt(
    a DECIMAL(18,2) DEFAULT 100.00, 
    b DECIMAL(18,2), 
    c INT, 
    CHECK (b > 100.00)
);
GO

INSERT INTO DECIMAL_dt (b,c) VALUES (150.00, 1);
GO
INSERT INTO DECIMAL_dt (b,c) VALUES (50.00, 2);  -- Should fail check constraint
GO

SELECT * FROM DECIMAL_dt;
GO

DROP TABLE DECIMAL_dt;
GO

------------------------------------------------------------------------
---- 17. Ability to use numeric types as part of table variable
------------------------------------------------------------------------
DECLARE @NUMERIC_dt TABLE (
    a NUMERIC(18,2),
    b DECIMAL(10,4),
    c NUMERIC(38,10)
);

INSERT INTO @NUMERIC_dt VALUES 
(0.00, 0.0000, 0.0000000000),
(NULL, NULL, NULL),
(100.00, 100.0000, 100.0000000000),
(999999999999999.99, 999999.9999, 9999999999999999999999999999.9999999999);

SELECT * FROM @NUMERIC_dt;
GO

-- Select into testing
CREATE TABLE NUMERIC_dt (
    a NUMERIC(18,2),
    b DECIMAL(10,4),
    c NUMERIC(20,4),
    d DECIMAL(12,4),
    e NUMERIC(38,10)
);
GO

INSERT INTO NUMERIC_dt (a, b, c, d, e)
VALUES
(NULL, NULL, NULL, NULL, NULL),
(0.00, 0.0000, 0.0000, 0.0000, 0.0000000000),
(NULL, 0.0000, NULL, 0.0000, NULL),
(0.00, NULL, 0.0000, NULL, 0.0000000000),
(100.00, 100.0000, 1000.0000, 100.0000, 10000.0000000000),
(250.50, 200.5000, 2500.5000, 200.5000, 25000.5000000000),
(500.75, 300.7500, 5000.7500, 300.7500, 50000.7500000000),
(750.25, 400.2500, 7500.2500, 400.2500, 75000.2500000000),
(1000.00, 500.0000, 10000.0000, 500.0000, 100000.0000000000),
(-100.00, -100.0000, -1000.0000, -100.0000, -10000.0000000000),
(999999999999999.99, 9999.9999, 99999999.9999, 99999.9999, 9999999999999999999999999999.9999999999),
(-999999999999999.99, -9999.9999, -99999999.9999, -99999.9999, -9999999999999999999999999999.9999999999),
(1234.56, 123.4567, 12345.6789, 123.4567, 123456.7890000000),
(9999.99, 999.9999, 99999.9999, 999.9999, 999999.9999000000);
GO

SELECT * INTO NUMERIC_dt_derived FROM NUMERIC_dt;
GO

-- Check column attributes for derived table
SELECT 
    c.name AS column_name,
    t.name AS data_type,
    c.precision,
    c.scale
FROM sys.columns c
JOIN sys.types t ON c.system_type_id = t.system_type_id
WHERE object_id = OBJECT_ID('NUMERIC_dt_derived')
ORDER BY column_id;
GO

-- Check column attributes for original table
SELECT 
    c.name AS column_name,
    t.name AS data_type,
    c.precision,
    c.scale
FROM sys.columns c
JOIN sys.types t ON c.system_type_id = t.system_type_id
WHERE object_id = OBJECT_ID('NUMERIC_dt')
ORDER BY column_id;
GO

-- Additional precision/scale tests
CREATE TABLE NUMERIC_precision_test (
    -- Test different precision/scale combinations
    col1 NUMERIC(5,2),   -- Small precision, standard scale
    col2 NUMERIC(38,10), -- Maximum precision, large scale
    col3 DECIMAL(18,0),  -- No decimal places
    col4 DECIMAL(38,38)  -- Maximum precision and scale
);
GO

INSERT INTO NUMERIC_precision_test VALUES
(123.45, 12345678901234567890.1234567890, 123456789, 0.12345678901234567890123456789012345678),
(999.99, 9999999999999999999.9999999999, 999999999, 0.99999999999999999999999999999999999999);

SELECT * FROM NUMERIC_precision_test;
GO

-- Test arithmetic operations maintaining precision
SELECT 
    col1 * 2 AS doubled_col1,
    col2 / 3 AS divided_col2,
    col3 + 1 AS incremented_col3
FROM NUMERIC_precision_test;
GO

-- Cleanup
DROP TABLE NUMERIC_dt_derived;
DROP TABLE NUMERIC_dt;
DROP TABLE NUMERIC_precision_test;
GO


------------------------------------------------------------------------
---- 18. Test Scenarios for COALESCE, INTERSECT, EXCEPT, VALUES, ISNULL
------------------------------------------------------------------------

-- Create test tables with varied precision/scale combinations
CREATE TABLE numeric_test1 (
    id INT,
    val1 NUMERIC(5,2),    -- Small precision/scale
    val2 NUMERIC(10,4),   -- Medium precision/scale
    val3 NUMERIC(18,6),   -- Large precision/scale
    val4 DECIMAL(28,8),   -- Larger precision/scale
    val5 NUMERIC(38,10)   -- Maximum precision with large scale
);

CREATE TABLE numeric_test2 (
    id INT,
    val1 NUMERIC(5,2),
    val2 NUMERIC(10,4),
    val3 NUMERIC(18,6),
    val4 DECIMAL(28,8),
    val5 NUMERIC(38,10)
);
GO

-- Insert varied test data including edge cases
INSERT INTO numeric_test1 
VALUES 
    (1, 123.45, 1234.5678, 123456.789012, 12345678.90123456, 1234567890.1234567890),
    (2, NULL, 2345.6789, NULL, 23456789.01234567, NULL),
    (3, 345.67, NULL, 345678.901234, NULL, 3456789012.3456789012),
    (4, -999.99, -9999.9999, -999999.999999, -99999999.99999999, -9999999999.9999999999),
    (5, 999.99, 9999.9999, 999999.999999, 99999999.99999999, 9999999999.9999999999),
    (6, 0.01, 0.0001, 0.000001, 0.00000001, 0.0000000001),
    (7, NULL, NULL, NULL, NULL, NULL),
    (8, 555.55, 5555.5555, 555555.555555, 55555555.55555555, 5555555555.5555555555);
GO

INSERT INTO numeric_test2 
VALUES 
    (1, 123.45, 1234.5678, 123456.789012, 12345678.90123456, 1234567890.1234567890),
    (3, 345.67, 3456.7890, 345678.901234, 34567890.12345678, 3456789012.3456789012),
    (5, 999.99, 9999.9999, 999999.999999, 99999999.99999999, 9999999999.9999999999),
    (9, 777.77, 7777.7777, 777777.777777, 77777777.77777777, 7777777777.7777777777),
    (10, -888.88, -8888.8888, -888888.888888, -88888888.88888888, -8888888888.8888888888);
GO

-- 1. Extended COALESCE Tests
-- Test COALESCE with multiple precision combinations
SELECT 
    id,
    COALESCE(val1, val2, val3, val4, val5, 0) AS coalesce_all,
    COALESCE(val1, CAST(0 AS NUMERIC(5,2))) AS coalesce_small,
    COALESCE(val3, CAST(0 AS NUMERIC(18,6))) AS coalesce_medium,
    COALESCE(val5, CAST(0 AS NUMERIC(38,10))) AS coalesce_large,
    COALESCE(val1 * 2, val2 * 2, val3 * 2) AS coalesce_arithmetic
FROM numeric_test1
ORDER BY id;
GO

-- 2. Extended ISNULL Tests
-- Test ISNULL with various combinations and calculations
SELECT 
    id,
    ISNULL(val1, val2) AS isnull_basic,
    ISNULL(val1, ISNULL(val2, ISNULL(val3, 0))) AS isnull_nested,
    ISNULL(val1 * val2, val3 * val4) AS isnull_multiplication,
    ISNULL(val1 / NULLIF(val2, 0), 0) AS isnull_division_safe
FROM numeric_test1
ORDER BY id;
GO

-- 3. Extended INTERSECT Tests
-- Test INTERSECT with various combinations
SELECT id, val1, val2 FROM numeric_test1
INTERSECT
SELECT id, val1, val2 FROM numeric_test2
ORDER BY id;
GO

SELECT id, val3, val4, val5 FROM numeric_test1
INTERSECT
SELECT id, val3, val4, val5 FROM numeric_test2
ORDER BY id;
GO

-- Test INTERSECT with calculations
SELECT id, val1 * 2, val2 / 2 FROM numeric_test1
INTERSECT
SELECT id, val1 * 2, val2 / 2 FROM numeric_test2
ORDER BY id;
GO

-- 4. Extended EXCEPT Tests
-- Test EXCEPT with various combinations
SELECT id, val1, val2 FROM numeric_test1
EXCEPT
SELECT id, val1, val2 FROM numeric_test2
ORDER BY id;
GO

SELECT id, val3, val4, val5 FROM numeric_test1
EXCEPT
SELECT id, val3, val4, val5 FROM numeric_test2
ORDER BY id;
GO

-- Test EXCEPT with calculations
SELECT id, val1 * 2, val2 / 2 FROM numeric_test1
EXCEPT
SELECT id, val1 * 2, val2 / 2 FROM numeric_test2
ORDER BY id;
GO

-- 5. Extended VALUES Tests
-- Test VALUES with different precision/scale combinations
SELECT 
    id,
    n1,
    n2,
    n3,
    n1 + n2 + n3 AS sum_all,
    n1 * n2 / NULLIF(n3, 0) AS complex_calc
FROM (
    VALUES 
        (1, CAST(11.11 AS NUMERIC(5,2)), CAST(11.1111 AS NUMERIC(10,4)), CAST(11.111111 AS NUMERIC(18,6))),
        (2, CAST(22.22 AS NUMERIC(5,2)), CAST(22.2222 AS NUMERIC(10,4)), CAST(22.222222 AS NUMERIC(18,6))),
        (3, CAST(33.33 AS NUMERIC(5,2)), CAST(33.3333 AS NUMERIC(10,4)), CAST(33.333333 AS NUMERIC(18,6))),
        (4, CAST(-44.44 AS NUMERIC(5,2)), CAST(-44.4444 AS NUMERIC(10,4)), CAST(-44.444444 AS NUMERIC(18,6))),
        (5, CAST(0.01 AS NUMERIC(5,2)), CAST(0.0001 AS NUMERIC(10,4)), CAST(0.000001 AS NUMERIC(18,6)))
) AS number_variations(id, n1, n2, n3)
ORDER BY id;
GO

-- 6. Combined Operations Tests
-- Test complex combinations of operations
WITH combined_calcs AS (
    SELECT 
        t1.id,
        COALESCE(t1.val1, t2.val1) AS c1,
        ISNULL(t1.val2, t2.val2) AS c2,
        CASE 
            WHEN t1.val3 IS NULL THEN t2.val3
            WHEN t2.val3 IS NULL THEN t1.val3
            ELSE (t1.val3 + t2.val3) / 2
        END AS c3
    FROM numeric_test1 t1
    FULL OUTER JOIN numeric_test2 t2 ON t1.id = t2.id
)
SELECT 
    id,
    c1,
    c2,
    c3,
    COALESCE(c1, c2, c3) AS final_result,
    CASE 
        WHEN c1 IS NOT NULL AND c2 IS NOT NULL THEN c1 * c2
        ELSE NULL
    END AS multiplication_result
FROM combined_calcs
ORDER BY id;
GO

-- 7. Mathematical Function Tests with COALESCE/ISNULL
SELECT 
    id,
    COALESCE(val1, 0) AS safe_sqrt,
    ISNULL(val1, 0) AS safe_power,
    COALESCE(LOG10(ABS(NULLIF(val1, 0))), 0) AS safe_log,
    ISNULL(EXP(CASE WHEN val1 < 10 THEN val1 ELSE NULL END), 0) AS safe_exp
FROM numeric_test1
ORDER BY id;
GO

-- 8. Aggregate Functions with COALESCE/ISNULL
SELECT 
    COALESCE(SUM(val1), 0) AS sum_val1,
    ISNULL(AVG(val1), 0) AS avg_val1,
    COALESCE(MIN(val1), 0) AS min_val1,
    ISNULL(MAX(val1), 0) AS max_val1,
    COUNT(COALESCE(val1, val2)) AS count_either,
    SUM(ISNULL(val1, 0) + ISNULL(val2, 0)) AS sum_both
FROM numeric_test1;
GO

-- 9. Window Functions with COALESCE/ISNULL
SELECT 
    id,
    val1,
    val2,
    COALESCE(val1, LAG(val1) OVER (ORDER BY id), 0) AS coalesce_lag,
    ISNULL(val2, LEAD(val2) OVER (ORDER BY id)) AS isnull_lead,
    SUM(COALESCE(val1, 0)) OVER (ORDER BY id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS running_sum
FROM numeric_test1
ORDER BY id;
GO

-- 10. Complex Calculations with Multiple Operations
WITH calc_cte AS (
    SELECT 
        t1.id,
        COALESCE(t1.val1, t2.val1) AS c1,
        ISNULL(t1.val2, t2.val2) AS c2,
        COALESCE(t1.val3, t2.val3) AS c3
    FROM numeric_test1 t1
    FULL OUTER JOIN numeric_test2 t2 ON t1.id = t2.id
)
SELECT 
    id,
    c1,
    c2,
    c3,
    POWER(COALESCE(c1, 0), 2) + POWER(ISNULL(c2, 0), 2) AS pythagoras,
    CASE 
        WHEN c1 IS NOT NULL AND c2 IS NOT NULL AND c3 IS NOT NULL 
        THEN (c1 + c2 + c3) / 3
        ELSE COALESCE(c1, c2, c3, 0)
    END AS complex_avg
FROM calc_cte
ORDER BY id;
GO

-- 11. String Conversion Tests
SELECT 
    id,
    CAST(COALESCE(val1, 0) AS VARCHAR(20)) AS string_val1,
    CAST(ISNULL(val2, 0) AS VARCHAR(20)) AS string_val2,
    CAST(COALESCE(val3, 0) AS VARCHAR(30)) AS string_val3,
    TRY_CAST(COALESCE(val4, 0) AS VARCHAR(40)) AS safe_string_val4
FROM numeric_test1
ORDER BY id;
GO

-- Cleanup
DROP TABLE numeric_test1;
DROP TABLE numeric_test2;
GO
