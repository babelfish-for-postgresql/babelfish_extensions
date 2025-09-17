-- Test from tables
SELECT 'MONEY Conversions' AS test_type;
SELECT test_value, style_number, 
       TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS converted_value,
       description
FROM money_style_conversion_test
ORDER BY id;
GO

SELECT 'SMALLMONEY Conversions' AS test_type;
SELECT test_value, style_number,
       TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS converted_value,
       description
FROM smallmoney_style_conversion_test
ORDER BY id;
GO

-- Test MONEY conversion with different styles
DECLARE @val MONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val);
GO

DECLARE @val MONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 0);
GO

DECLARE @val MONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 1);
GO

DECLARE @val MONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 2);
GO

DECLARE @val MONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 126);
GO

-- Test SMALLMONEY conversion with different styles
DECLARE @val SMALLMONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val);
GO

DECLARE @val SMALLMONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 0);
GO

DECLARE @val SMALLMONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 1);
GO

DECLARE @val SMALLMONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 2);
GO

DECLARE @val SMALLMONEY = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 126);
GO

-- Test negative styles
SELECT CONVERT(VARCHAR, CAST(123 AS MONEY), -126);
GO

SELECT CONVERT(VARCHAR, CAST(123 AS MONEY), -1);
GO

-- Test decimal style (should fail)
SELECT CONVERT(VARCHAR, CAST(123376736.12345678923456789 AS MONEY), 1.8);
GO

-- Test style 16
SELECT CONVERT(VARCHAR, CAST($23.12 AS MONEY), 16);
GO

-- Test edge cases
SELECT CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY));
GO

SELECT CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY));
GO

SELECT CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY));
GO

SELECT CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY));
GO

-- Test views
SELECT * FROM money_style_test_v1;
GO

SELECT * FROM money_style_test_v2;
GO

SELECT * FROM money_style_test_v3;
GO

SELECT * FROM money_style_test_v4;
GO

SELECT * FROM money_style_test_v5;
GO

SELECT * FROM smallmoney_style_test_v1;
GO

SELECT * FROM smallmoney_style_test_v2;
GO

SELECT * FROM smallmoney_style_test_v3;
GO

SELECT * FROM smallmoney_style_test_v4;
GO

SELECT * FROM smallmoney_style_test_v5;
GO

-- Test procedures
EXECUTE money_style_test_p1;
GO

EXECUTE money_style_test_p2;
GO

EXECUTE money_style_test_p3;
GO

EXECUTE money_style_test_p4;
GO

EXECUTE money_style_test_p5;
GO

EXECUTE smallmoney_style_test_p1;
GO

EXECUTE smallmoney_style_test_p2;
GO

EXECUTE smallmoney_style_test_p3;
GO

EXECUTE smallmoney_style_test_p4;
GO

EXECUTE smallmoney_style_test_p5;
GO

-- Test MONEY direct conversions
DECLARE @val MONEY;

-- Basic style tests
SET @val = 1234.1357;
SELECT CONVERT(VARCHAR, @val);
GO

SET @val = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 0);
GO

SET @val = 1234.1357;
SELECT CONVERT(VARCHAR, @val, 1);
GO

-- Edge cases
SET @val = 922337203685477.5807;  -- Max MONEY
SELECT CONVERT(VARCHAR, @val, 0);
GO

SET @val = -922337203685477.5808;  -- Min MONEY
SELECT CONVERT(VARCHAR, @val, 0);
GO

-- Negative numbers
SET @val = -1234.1357;
SELECT CONVERT(VARCHAR, @val, 0);
GO

SET @val = -1234.1357;
SELECT CONVERT(VARCHAR, @val, 1);
GO

-- Float-like values
SET @val = 123.45678901234;
SELECT CONVERT(VARCHAR, @val, 0);
GO

SET @val = -123.45678901234;
SELECT CONVERT(VARCHAR, @val, 2);
GO

-- Zero values
SET @val = 0.00;
SELECT CONVERT(VARCHAR, @val, 0);
GO

SET @val = 0.00;
SELECT CONVERT(VARCHAR, @val, 1);
GO

-- Test SMALLMONEY direct conversions
DECLARE @sval SMALLMONEY;

-- Basic style tests
SET @sval = 1234.1357;
SELECT CONVERT(VARCHAR, @sval);
GO

SET @sval = 1234.1357;
SELECT CONVERT(VARCHAR, @sval, 0);
GO

-- Edge cases
SET @sval = 214748.3647;  -- Max SMALLMONEY
SELECT CONVERT(VARCHAR, @sval, 0);
GO

SET @sval = -214748.3648;  -- Min SMALLMONEY
SELECT CONVERT(VARCHAR, @sval, 0);
GO

-- Negative numbers
SET @sval = -1234.1357;
SELECT CONVERT(VARCHAR, @sval, 0);
GO

SET @sval = -1234.1357;
SELECT CONVERT(VARCHAR, @sval, 1);
GO

-- Test invalid conversions (should fail)
-- Decimal style
SELECT CONVERT(VARCHAR, CAST(123.45 AS MONEY), 1.8);
GO

-- Overflow tests
SELECT CONVERT(VARCHAR, CAST(214748.3648 AS SMALLMONEY));  -- SMALLMONEY overflow
GO

SELECT CONVERT(VARCHAR, CAST(-214748.3649 AS SMALLMONEY));  -- SMALLMONEY underflow
GO

-- Test NULL handling
SELECT CONVERT(VARCHAR, CAST(NULL AS MONEY));
GO

SELECT CONVERT(VARCHAR, CAST(NULL AS SMALLMONEY));
GO
