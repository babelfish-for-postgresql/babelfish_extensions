-- Simple CASE tests with SMALLMONEY/MONEY
-------------------------
-- Basic CAST in ELSE
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) end
GO

-- Multiplication with integers
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else 2 * cast(6.43 as smallmoney) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) * 100 end
GO

-- Addition with integers
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) + 10 end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) + 10 end
GO

-- Operations with NUMERIC
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) * cast(2.5 as numeric(10,2)) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) + cast(2.5 as numeric(10,2)) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) / cast(2.5 as numeric(10,2)) end
GO

select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) * cast(2.5 as numeric(10,2)) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) + cast(2.5 as numeric(10,2)) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) / cast(2.5 as numeric(10,2)) end
GO

-- Mixed MONEY and SMALLMONEY operations
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) * cast(2.5 as money) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) * cast(2.5 as smallmoney) end
GO

-- Edge cases with large numbers
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(214748.3647 as smallmoney) * 2 end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(922337203685477.5807 as money) * 2 end
GO


-- Operations with different numeric precisions
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) * cast(2.5555 as numeric(10,4)) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) * cast(2.5555 as numeric(10,4)) end
GO


-- Division operations
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) / 2 end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) / 2 end
GO

-- Operations with negative numbers
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(-6.43 as smallmoney) * -2 end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(-6.43 as money) * -2 end
GO

-- Operations with zero
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) * 0 end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) * 0 end
GO

-- Operations with very small numbers
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) * 0.0001 end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) * 0.0001 end
GO

-- Operations with large numbers
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as smallmoney) * 10000 end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(6.43 as money) * 10000 end
GO

-- Basic CASE using declare
DECLARE @money1 SMALLMONEY = 1000.00123123, @money2 SMALLMONEY = 1000.00123123;
SELECT CASE WHEN @money2 <= 0 THEN 0.0001 ELSE @money2 END;
GO

-- JIRA query 
declare @money1 money = 1000.00123123;
declare @money2 money = 1000.00123123;
select CASE
WHEN @money2 <= 0
    THEN 0.0001
ELSE @money2
END  
GO

-- Basic CASE with declared money variables
DECLARE @money1 MONEY = 1000.00123123;
DECLARE @money2 MONEY = 1000.00123123;
SELECT CASE
    WHEN @money2 <= 0 THEN 0.0001
    WHEN @money2 < @money1 THEN @money1 * 0.5
    WHEN @money2 = @money1 THEN @money1 * 1.1
    ELSE @money2
END
GO

-- Testing with smallmoney
DECLARE @sm1 SMALLMONEY = 214748.3647; -- Max value for smallmoney
DECLARE @sm2 SMALLMONEY = -214748.3648; -- Min value for smallmoney
SELECT CASE
    WHEN @sm1 > 0 THEN @sm1 * 0.5
    WHEN @sm2 < 0 THEN @sm2 * 0.5
    ELSE 0.0
END
GO

-- Multiple variables and conditions
DECLARE @price1 MONEY = 500.25
DECLARE @price2 MONEY = 600.75
DECLARE @discount SMALLMONEY = 0.10
SELECT CASE
    WHEN @price1 >= @price2 THEN @price1 * (1 - @discount)
    WHEN @price1 < @price2 THEN @price2 * (1 - @discount)
    ELSE @price1
END
GO

-- Testing NULL conditions
DECLARE @amount1 MONEY = NULL
DECLARE @amount2 MONEY = 1000.00
SELECT CASE
    WHEN @amount1 IS NULL THEN COALESCE(@amount2, 0.00)
    WHEN @amount2 IS NULL THEN COALESCE(@amount1, 0.00)
    ELSE @amount1 + @amount2
END
GO

-- Testing with arithmetic operations
DECLARE @val1 SMALLMONEY = 100.50
DECLARE @val2 SMALLMONEY = 200.75
DECLARE @multiplier SMALLMONEY = 1.15
SELECT CASE
    WHEN @val1 * @multiplier > @val2 THEN @val1 * @multiplier
    WHEN @val2 / @multiplier < @val1 THEN @val2 / @multiplier
    ELSE (@val1 + @val2) / 2
END
GO

-- Testing with multiple variables and nested CASE
-- FIXME : value mismatch
DECLARE @cost MONEY = 1500.00
DECLARE @margin SMALLMONEY = 0.25
DECLARE @tax SMALLMONEY = 0.08
SELECT CASE
    WHEN @cost <= 1000 THEN
        CASE
            WHEN @margin < 0.2 THEN @cost * (1 + @margin + @tax)
            ELSE @cost * (1 + @margin)
        END
    ELSE
        CASE
            WHEN @margin > 0.3 THEN @cost * (1 + @margin - 0.05)
            ELSE @cost * (1 + @margin + @tax)
        END
END
GO

-- Complex Nested CASE with Aggregates
SELECT 
    CASE 
        WHEN CustomerType = 'PREMIUM' THEN
            CASE 
                WHEN AVG(Amount) > 200 THEN MAX(Amount) * CAST(0.8 AS SMALLMONEY)
                ELSE MIN(Amount) * CAST(0.9 AS SMALLMONEY)
            END
        ELSE
            CASE 
                WHEN SUM(Amount) > 500 THEN AVG(Amount) * CAST(0.95 AS SMALLMONEY)
                ELSE AVG(Amount)
            END
    END AS AdjustedAmount
FROM babel_5512_t3
GROUP BY CustomerType
GO

-- Testing with aggregate functions and variables
DECLARE @threshold MONEY = 5000.00
DECLARE @commission SMALLMONEY = 0.03
SELECT CASE
    WHEN SUM(Amount) > @threshold THEN SUM(Amount) * @commission
    ELSE SUM(Amount) * (@commission / 2)
END
FROM babel_5512_t3
GO

-- Testing with string conversions
DECLARE @moneyStr MONEY = CAST('1234.56' AS MONEY)
DECLARE @moneyVal SMALLMONEY = 1234.56
SELECT CASE
    WHEN CAST(@moneyStr AS VARCHAR) = CAST(@moneyVal AS VARCHAR) THEN @moneyStr
    ELSE @moneyVal
END
GO


-- Testing with multiple currency conversions
DECLARE @usdAmount MONEY = 1000.00
DECLARE @exchangeRate1 SMALLMONEY = 1.15 -- EUR
DECLARE @exchangeRate2 SMALLMONEY = 0.85 -- GBP
SELECT CASE
    WHEN @exchangeRate1 > @exchangeRate2 THEN @usdAmount * @exchangeRate1
    WHEN @exchangeRate1 < @exchangeRate2 THEN @usdAmount * @exchangeRate2
    ELSE @usdAmount
END AS ConvertedAmount
GO

-- Basic operations between MONEY and SMALLMONEY
DECLARE @m MONEY = 123456.7890
DECLARE @sm SMALLMONEY = 214748.3647
SELECT @m + @sm AS Addition,
       @m - @sm AS Subtraction,
       @m * @sm AS Multiplication,
       @m / @sm AS Division
GO

-- Edge cases with maximum values
DECLARE @maxMoney MONEY = 922337203685477.5807  -- Max MONEY value
DECLARE @maxSmallMoney SMALLMONEY = 214748.3647  -- Max SMALLMONEY value
SELECT CASE 
    WHEN @maxMoney > @maxSmallMoney THEN @maxMoney
    ELSE @maxSmallMoney
END AS MaxComparison
GO

-- Edge cases with minimum values
DECLARE @minMoney MONEY = -922337203685477.5808  -- Min MONEY value
DECLARE @minSmallMoney SMALLMONEY = -214748.3648  -- Min SMALLMONEY value
SELECT @minMoney + @minSmallMoney AS MinAddition  -- Should cause overflow
GO


-- Testing arithmetic overflow scenarios
DECLARE @largeMoney MONEY = 922337203685477
DECLARE @largeSmallMoney SMALLMONEY = 214748.3647
SELECT @largeMoney * @largeSmallMoney AS ShouldOverflow
GO

-- Testing precision and rounding
DECLARE @precisionMoney MONEY = 123.4567891
DECLARE @precisionSmallMoney SMALLMONEY = 123.4567891
SELECT 
    @precisionMoney AS MoneyPrecision,
    @precisionSmallMoney AS SmallMoneyPrecision,
    @precisionMoney - @precisionSmallMoney AS PrecisionDifference
GO

-- SMALLMONEY with SMALLMONEY combinations
-------------------------
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(2.5 as smallmoney) * cast(2.5 as smallmoney) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(10000.00 as smallmoney) * cast(0.02 as smallmoney) end
GO

-- Rounding instead of truncation
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(2.5 as smallmoney) * cast(2.4999 as smallmoney) end
GO

-- MONEY with MONEY combinations
-------------------------
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(2.5 as money) * cast(2.5 as money) end
GO
select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(1000000.5 as money) * cast(2.0 as money) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(1000000.5 as money) * cast(2.0 as money) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(100000000.00 as money) * cast(0.02 as money) end
GO

-- Overflow cases
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(922337203685477.5807 as money) * cast(1.0001 as money) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(922337203685477.00 as money) * cast(1.1 as money) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(900000000000000.00 as money) * cast(1.5 as money) end
GO

-- SMALLMONEY with MONEY combinations
-------------------------
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(2.5 as smallmoney) * cast(2.5 as money) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(10000.00 as smallmoney) * cast(0.02 as money) end
GO
-- round
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(2.5 as smallmoney) * cast(2.4999 as money) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(214748.3647 as smallmoney) * cast(1.0001 as money) end
GO

-- Addition cases
-------------------------
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(100000.00 as smallmoney) + cast(100000.00 as smallmoney) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(1000000.00 as money) + cast(1000000.00 as money) end
GO

-- Overflow
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(922337203685477.00 as money) + cast(922337203685477.00 as money) end
GO

-- Division cases
-------------------------
-- No overflow
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(100000.00 as smallmoney) / cast(2.0 as smallmoney) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(1000000.00 as money) / cast(2.0 as money) end
GO

-- Overflow or division by small numbers
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(922337203685477.5807 as money) / cast(0.5 as money) end
GO

-- Edge cases with negative numbers
-------------------------
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(-100000.00 as smallmoney) * cast(-2.0 as smallmoney) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(-1000000.00 as money) * cast(-2.0 as money) end
GO

-- Overflow
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else cast(-922337203685477.5808 as money) * cast(1.0001 as money) end
GO

-- Mixed operations
-------------------------
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else (cast(100.00 as smallmoney) * cast(2.0 as money)) / cast(2.0 as smallmoney) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else (cast(1000.00 as money) + cast(100.00 as smallmoney)) * cast(0.5 as money) end
GO

-- Overflow
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else (cast(214748.00 as smallmoney) * cast(1.5 as money)) + cast(100.00 as smallmoney) end
GO
select case 2 when 1 then cast(5.5 as DECIMAL(10,2)) else (cast(922337203685477.00 as money) * cast(1.1 as smallmoney)) end
GO

-- rounding 
SELECT CAST(2.8571 AS SMALLMONEY) * CAST(2.4999 AS SMALLMONEY)
GO

SELECT CAST(2.8571 AS MONEY) * CAST(2.4999 AS MONEY)
GO

-- Various INT ranges
-- treated as int8 by us, and numeric by sqlserver
select 7378697629483820646 * cast(99999.9999 as money)
GO
select 9223372036854775807 * cast(99999.9999 as money)
GO
select cast(99999.9999 as money) * 7378697629483820646
GO


-- beyond int64, treated as numeric by both bff and sqlserver
select 73786976294838206461 * cast(99999.9999 as smallmoney)
GO
select 9223372036854775808  * CAST(2.4999 AS SMALLMONEY)
GO

select 73786976294838206461 * cast(99999.9999 as money)
GO
select 9223372036854775808  * CAST(2.4999 AS MONEY)
GO

-- overflow issue, BABEL-5689
select cast(7378697629483820646 as numeric(30,0))*cast(99999.9999 as smallmoney)
GO

-- explicit casting to numeric
select cast(7378697629483820646 as numeric(20,0)) * cast(99999.9999 as smallmoney)
GO

-- smallint
select 32767 * CAST(2.4999 AS SMALLMONEY)
GO

-- tinyint
select 255  * CAST(2.4999 AS SMALLMONEY)
GO

-- tinyint
select 255  * cast(1 as smallmoney)
GO

select 21474836 * CAST(1 AS MONEY)
GO

-- fixeddecimal multiplication
select cast(922337203685477.5807 as money) * cast(922337203685477.5807 as money)
GO

select cast(922337203685477.5807 as money) * cast(214748.3647 as smallmoney)
GO

-- Int 8(int64) : -9223372036854775808 to 9223372036854775807
-- int 4(int32) : -2147483648 to 2147483647
-- int 2(int16) : -32768 to 32767
-- int 1(int8) : 0 to 255
-- money: -922337203685477.5808 to 922337203685477.5807
-- Smallmoney: -214748.3648 to 214748.3647

-- INT8 (BIGINT) Combinations
-- INT8 * MONEY
SELECT CAST(9223372036854775807 AS bigint) * CAST(2.4999 AS MONEY) AS res1
GO
SELECT CAST(9223372036854775807 AS bigint) * CAST(922337203685477.5807 AS MONEY) AS res1
GO

-- MONEY * INT8
SELECT CAST(2.4999 AS MONEY) * 9223372036854775807 AS res1
GO
SELECT CAST(922337203685477.5807 AS MONEY) * 9223372036854775807 AS res1
GO

-- INT4 (INT) Combinations
-- INT4 * MONEY
SELECT 2147483647 * CAST(2.4999 AS MONEY) AS res1
GO
SELECT 2147483647 * CAST(922337203685477.5807 AS MONEY) AS res1
GO

-- MONEY * INT4
SELECT CAST(2.4999 AS MONEY) * 2147483647 AS res1
GO
SELECT CAST(922337203685477.5807 AS MONEY) * 2147483647 AS res1
GO

-- INT2 (SMALLINT) Combinations
-- INT2 * MONEY
SELECT 32767 * CAST(2.4999 AS MONEY) AS res1
GO
SELECT 32767 * CAST(922337203685477.5807 AS MONEY) AS res1
GO

-- MONEY * INT2
SELECT CAST(2.4999 AS MONEY) * 32767 AS res1
GO
SELECT CAST(922337203685477.5807 AS MONEY) * 32767 AS res1
GO

-- INT1 (TINYINT) Combinations
-- INT1 * MONEY
SELECT 255 * CAST(2.4999 AS MONEY) AS res1
GO
SELECT 255 * CAST(922337203685477.5807 AS MONEY) AS res1
GO

-- MONEY * INT1
SELECT CAST(2.4999 AS MONEY) * 255 AS res1
GO
SELECT CAST(922337203685477.5807 AS MONEY) * 255 AS res1
GO

-- -- SMALLMONEY * INT1
SELECT CAST(2.4999 AS SMALLMONEY) * 255 AS res1
GO
SELECT CAST(214748.3647 AS MONEY) * 255 AS res1
GO


-- INT64 Edge Cases
-------------------------
-- INT64_MAX = 9223372036854775807
-- INT64_MIN = -9223372036854775808

-- Multiplication edge cases
SELECT CAST(9223372036854775807 AS BIGINT) * CAST(1.0000 AS MONEY)
GO
SELECT CAST(9223372036854775807 AS BIGINT) * CAST(1.0001 AS SMALLMONEY)
GO
SELECT CAST(9223372036854775807 AS BIGINT) * CAST(1.0001 AS MONEY)
GO
SELECT CAST(-9223372036854775808 AS BIGINT) * CAST(1.0000 AS SMALLMONEY)
GO
SELECT CAST(-9223372036854775808 AS BIGINT) * CAST(1.0001 AS MONEY)
GO

-------------------------
-- Testing with very large numbers
SELECT CAST(9999999999999999999999999999999 AS DECIMAL(38,0)) * CAST(1.0000 AS SMALLMONEY)
GO
SELECT CAST(9999999999999999999999999999999 AS DECIMAL(38,0)) / CAST(1.0000 AS SMALLMONEY)
GO

-- Testing with intermediate values
 SELECT CAST(1073741824 AS INT) * CAST(2.0000 AS money) -- 2^30 * 2
GO
SELECT CAST(4611686018427387904 AS BIGINT) * CAST(2.0000 AS MONEY) -- 2^62 * 2
GO

-- Testing with negative powers of 2
SELECT CAST(-1073741824 AS INT) * CAST(2.0000 AS MONEY) -- -2^30 * 2
GO
SELECT CAST(-4611686018427387904 AS BIGINT) * CAST(2.0000 AS MONEY) -- -2^62 * 2
GO

-- Testing with decimal fractions
SELECT CAST(2147483647 AS INT) * CAST(0.5000 AS MONEY)
GO
SELECT CAST(9223372036854775807 AS BIGINT) * CAST(0.5000 AS MONEY)
GO

-- Testing with very small decimal values
SELECT CAST(2147483647 AS INT) * CAST(0.0001 AS MONEY)
GO
SELECT CAST(9223372036854775807 AS BIGINT) * CAST(0.0001 AS MONEY)
GO

-- Testing with CASE statements and edge cases
SELECT CASE 
    WHEN CAST(2147483647 AS INT) * CAST(1.0000 AS MONEY) > 0
    THEN CAST(9223372036854775807 AS BIGINT) * CAST(0.5000 AS MONEY)
    ELSE CAST('170141183460469231731687303715884105727' AS DECIMAL(38,0)) * CAST(0.0001 AS MONEY)
END
GO

-- JIRA queries
-- DECIMAL + SMALLMONEY
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(678.90 AS SMALLMONEY) AS result;
GO

-- DECIMAL + SMALLMONEY
SELECT CAST(123.45 AS DECIMAL(5,2)) + CAST(678.90 AS SMALLMONEY) AS result;
GO

-- numeric * smallmoney
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(56.78 AS SMALLMONEY) AS result;
GO
-- numeric / smallmoney
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(5.0 AS SMALLMONEY) AS result;
GO

-- NUMERIC * MONEY
SELECT CAST(12.34 AS NUMERIC(4,2)) * CAST(56.78 AS MONEY) AS result;
GO

-- NUMERIC + MONEY
SELECT CAST(123.45 AS NUMERIC(5,2)) + CAST(678.90 AS MONEY) AS result;
GO

-- NUMERIC / MONEY
SELECT CAST(123.45 AS NUMERIC(5,2)) / CAST(5.0 AS MONEY) AS result;
GO

-- Multiplication near limits
SELECT CAST(10000.00 AS SMALLMONEY) * CAST(21.4748 AS SMALLMONEY)
GO

-- Nested CASE queries
-- 1. (first condition is true)
SELECT 
CASE WHEN 1=1 THEN CAST(5.5 AS decimal(10,2)) 
ELSE 
    CASE WHEN 2=2 THEN 2 * CAST(6.43 AS SMALLMONEY) 
    ELSE 
        CASE WHEN 3=3 THEN CAST(8.75 AS INT) 
        ELSE 5 * CAST(10.25 AS SMALLMONEY) 
        END 
    END 
END AS Result;
GO

-- 2. (Second condition is true)
SELECT 
CASE WHEN 4=1 THEN CAST(5.5 AS decimal(10,2))
ELSE 
    CASE WHEN 2=2 THEN 2 * CAST(6.43 AS SMALLMONEY)
    ELSE 
         CASE WHEN 3=3 THEN CAST(8.75 AS INT)
         ELSE 5 * CAST(10.25 AS SMALLMONEY)
         END
    END
END AS Result;
GO

-- 3. (Third condition is true) 
SELECT 
CASE WHEN 4=1 THEN CAST(5.5 AS decimal(10,2))
ELSE 
    CASE WHEN 5=2 THEN 2 * CAST(6.43 AS SMALLMONEY)
    ELSE 
         CASE WHEN 3=3 THEN CAST(8.75 AS INT)
         ELSE 5 * CAST(10.25 AS SMALLMONEY)
         END
    END
END AS Result;
GO

-- 4. (All conditions false, executes final ELSE)
SELECT 
CASE WHEN 4=1 THEN CAST(5.5 AS decimal(10,2))
ELSE 
    CASE WHEN 5=2 THEN 2 * CAST(6.43 AS SMALLMONEY)
    ELSE 
         CASE WHEN 4=3 THEN CAST(8.75 AS INT)
         ELSE 5 * CAST(10.25 AS SMALLMONEY)
         END
    END
END AS Result;
GO

-- 5. (Else case has final common type as numeric but nested has smallmoney)
SELECT
CASE WHEN 1=1 THEN CAST(5.5 AS decimal(10,2))
ELSE
    CASE WHEN 2=2 THEN 2 * CAST(6.43 AS decimal(10,2))
    ELSE
         CASE WHEN 3=3 THEN CAST(8.75 AS INT)
         ELSE 5 * CAST(10.25 AS SMALLMONEY)
         END
    END
END AS Result;
GO

SELECT CASE 
    WHEN 1=1 THEN 
        CASE 
            WHEN CAST(100.50 AS SMALLMONEY) > 50 THEN CAST(200.75 AS SMALLMONEY)
            ELSE CAST(50.25 AS SMALLMONEY)
        END
    ELSE CAST(25.00 AS SMALLMONEY)
END AS Result
GO

-- Edge cases with numeric and smallmoney
SELECT CASE 
    WHEN 1=1 THEN CAST(214748.3647 AS SMALLMONEY) -- Max value
    ELSE CAST(-214748.3648 AS SMALLMONEY) -- Min value
END
GO

-- implicit casting with table
SELECT CASE 1  WHEN 1 THEN CAST(5.5 AS DECIMAL(10,2))   ELSE  (SELECT a FROM babel_5512_t1) end 
GO
SELECT CASE 1  WHEN 1 THEN CAST(5.5 AS DECIMAL(10,2))   ELSE 2 * (SELECT a FROM babel_5512_t1) end 
GO

-- Aggregate function with smallmoney
SELECT CASE 
    WHEN AVG(Price) > 200 THEN MAX(Price)
    ELSE MIN(Price)
END AS Result
FROM babel_5512_t2
GO

-- Simple CASE with multiple smallmoney values
SELECT CASE Price
    WHEN CAST(100.50 AS SMALLMONEY) THEN 'Low'
    WHEN CAST(200.75 AS SMALLMONEY) THEN 'Medium'
    WHEN CAST(300.25 AS SMALLMONEY) THEN 'High'
    ELSE 'Unknown'
END AS PriceRange
FROM babel_5512_t2
GO

-- Complex calculations
SELECT CASE 
    WHEN 1=1 THEN 
        (SELECT AVG(Price) FROM babel_5512_t2) * CAST(1.5 AS SMALLMONEY)
    ELSE 
        (SELECT MAX(Price) FROM babel_5512_t2) / CAST(2.0 AS SMALLMONEY)
END
GO

-- Testing function babel_5512_f1
-------------------------
-- Basic test cases
SELECT babel_5512_f1(100.50, 1.1) AS Result1  -- Normal case
GO
SELECT babel_5512_f1(200.75, 0.5) AS Result2  -- Reduction
GO
SELECT babel_5512_f1(0.00, 1.5) AS Result3    -- Zero input
GO

-- Edge cases
SELECT babel_5512_f1(214748.3647, 1.0) AS Result4  -- Max SMALLMONEY
GO
SELECT babel_5512_f1(214748.3647, 1.1) AS Result5  -- Should overflow
GO
SELECT babel_5512_f1(-214748.3648, 1.0) AS Result6 -- Min SMALLMONEY
GO

-- Decimal multiplier variations
SELECT babel_5512_f1(100.50, 1.99) AS Result7
GO
SELECT babel_5512_f1(100.50, 0.01) AS Result8
GO



-- Testing babel_5512_f2 function
-------------------------
-- Basic test cases
SELECT babel_5512_f2(100.00, 'PREMIUM') AS PremiumPrice  -- 20% discount
GO

-- Edge cases
SELECT babel_5512_f2(214748.3647, 'PREMIUM') AS MaxPremiumPrice  -- Max SMALLMONEY with discount
GO
SELECT babel_5512_f2(0.00, 'PREMIUM') AS ZeroPremiumPrice       -- Zero price
GO

DECLARE @total1 SMALLMONEY
EXEC babel_5512_p1
    @basePrice = 100.00,
    @quantity = 2,
    @discountPercent = 10.00,
    @taxRate = 8.00,
    @totalPrice = @total1 OUTPUT
SELECT @total1 AS BasicTotalPrice
GO

-- Edge cases
-- Maximum values
DECLARE @total2 SMALLMONEY
EXEC babel_5512_p1
    @basePrice = 214748.3647,
    @quantity = 1,
    @discountPercent = 0.00,
    @taxRate = 0.00,
    @totalPrice = @total2 OUTPUT
SELECT @total2 AS MaxTotalPrice
GO

-- Small values
DECLARE @total3 SMALLMONEY
EXEC babel_5512_p1
    @basePrice = 0.01,
    @quantity = 1,
    @discountPercent = 1.00,
    @taxRate = 1.00,
    @totalPrice = @total3 OUTPUT
SELECT @total3 AS SmallTotalPrice
GO


-- Negative values
DECLARE @total7 SMALLMONEY
EXEC babel_5512_p1
    @basePrice = -100.00,
    @quantity = 2,
    @discountPercent = 10.00,
    @taxRate = 8.00,
    @totalPrice = @total7 OUTPUT
SELECT @total7 AS NegativeBasePrice
GO

-- Complex scenario
DECLARE @total8 SMALLMONEY
EXEC babel_5512_p1
    @basePrice = 999.99,
    @quantity = 5,
    @discountPercent = 15.00,
    @taxRate = 8.50,
    @totalPrice = @total8 OUTPUT
SELECT @total8 AS ComplexScenarioPrice
GO

-- Testing both function and procedure together
DECLARE @total9 SMALLMONEY
DECLARE @discountedPrice SMALLMONEY
SET @discountedPrice = babel_5512_f2(100.00, 'PREMIUM')
EXEC babel_5512_p1
    @basePrice = @discountedPrice,
    @quantity = 2,
    @discountPercent = 5.00,
    @taxRate = 8.00,
    @totalPrice = @total9 OUTPUT
SELECT @total9 AS CombinedFunctionProcedurePrice
GO


-- Testing with NULL values
SELECT CASE 
    WHEN CAST(NULL AS SMALLMONEY) IS NULL THEN CAST(100.00 AS SMALLMONEY)
    ELSE CAST(200.00 AS SMALLMONEY)
END
GO

-- Testing precision
SELECT CAST(1.23456 AS SMALLMONEY) * CAST(1.23456 AS SMALLMONEY)
GO

-- Testing with different data type combinations
SELECT CASE 
    WHEN 1=1 THEN CAST(100 AS INT) * CAST(1.5 AS SMALLMONEY)
    ELSE CAST(200.50 AS DECIMAL(10,2)) * CAST(2.5 AS SMALLMONEY)
END
GO

-- Complex Calculations with Multiple Operations
SELECT 
    (CAST(100.00 AS SMALLMONEY) * CAST(1.1 AS SMALLMONEY) + 
     CAST(50.00 AS SMALLMONEY)) / CAST(2 AS SMALLMONEY) AS ComplexCalc
GO

-- Testing with decimal multiplication
SELECT 
    CAST(99999.99999 AS MONEY) * CAST(99999.99999 AS SMALLMONEY) AS LargeMultiplication,
    CAST(0.00001 AS MONEY) * CAST(0.00001 AS SMALLMONEY) AS SmallMultiplication
GO

-- Testing with integer division
SELECT 
    CAST(1000.00 AS MONEY) / CAST(3 AS SMALLMONEY) AS MoneyDivision,
    CAST(1000.00 AS SMALLMONEY) / CAST(3 AS MONEY) AS SmallMoneyDivision
GO

-------------------------
-- Scalar UDT Test Cases
-------------------------

-- 2. Basic Usage
-- Variables with UDTs
DECLARE @sm SmallMoneyType = 123.45
DECLARE @m MoneyType = 1234.5678
SELECT @sm AS SmallMoneyValue, @m AS MoneyValue
GO
-- 1. Basic CASE with UDTs
DECLARE @sm1 SmallMoneyType = 100.50
DECLARE @sm2 SmallMoneyType = 200.75
SELECT CASE 
    WHEN @sm1 < @sm2 THEN CAST(150.25 AS SmallMoneyType)
    ELSE CAST(250.75 AS SmallMoneyType)
END AS BasicUdtCase
GO

-- 2. Nested CASE with Multiple UDT Variables
DECLARE @sm SmallMoneyType = 100.50
DECLARE @m MoneyType = 1000.75
SELECT CASE 
    WHEN @sm > CAST(50 AS SmallMoneyType) THEN
        CASE 
            WHEN @m < CAST(2000 AS MoneyType) THEN CAST(75.25 AS SmallMoneyType)
            ELSE CAST(125.50 AS SmallMoneyType)
        END
    ELSE
        CASE 
            WHEN @m > CAST(500 AS MoneyType) THEN CAST(175.75 AS SmallMoneyType)
            ELSE CAST(225.25 AS SmallMoneyType)
        END
END AS NestedUdtCase
GO

-- 3. CASE with UDT Calculations
DECLARE @price1 SmallMoneyType = 150.25
DECLARE @price2 MoneyType = 1500.75
SELECT CASE 
    WHEN @price1 * CAST(1.1 AS SmallMoneyType) > CAST(160 AS SmallMoneyType) THEN
        @price1 * CAST(1.2 AS SmallMoneyType)
    WHEN @price2 * CAST(0.9 AS MoneyType) < CAST(1400 AS MoneyType) THEN
        CAST(@price2 * CAST(0.8 AS MoneyType) AS SmallMoneyType)
    ELSE
        @price1 * CAST(1.5 AS SmallMoneyType)
END AS CalculatedUdtCase
GO

-- Testing UDTs
-- Basic operations
SELECT 
    SmallMoneyCol + CAST(10 AS SmallMoneyType) AS SmallMoneyAdd,
    MoneyCol + CAST(10 AS MoneyType) AS MoneyAdd
FROM babel_5512_t4
GO

-- CASE expressions with UDTs
SELECT CASE 
    WHEN SmallMoneyCol > CAST(200 AS SmallMoneyType)
    THEN SmallMoneyCol * CAST(1.1 AS SmallMoneyType)
    ELSE SmallMoneyCol
END AS AdjustedSmallMoney
FROM babel_5512_t4
GO

select case 1 when 1 then cast(5.5 as DECIMAL(10,2)) else 2 * cast(6.43 as SmallMoneyType) end
GO

-- Testing NULL handling
DECLARE @nullSm SmallMoneyType = NULL
DECLARE @nullM MoneyType = NULL
SELECT 
    ISNULL(@nullSm, CAST(0 AS SmallMoneyType)) AS SmallMoneyNull,
    ISNULL(@nullM, CAST(0 AS MoneyType)) AS MoneyNull
GO

-- Testing conversions
DECLARE @sm SmallMoneyType = 123.45
DECLARE @m MoneyType = 1234.5678
SELECT 
    CAST(@sm AS DECIMAL(10,4)) AS SmallMoneyToDecimal,
    CAST(@m AS DECIMAL(10,4)) AS MoneyToDecimal
GO

-- Testing arithmetic operations
DECLARE @sm1 SmallMoneyType = 100.00
DECLARE @sm2 SmallMoneyType = 200.00
DECLARE @m1 MoneyType = 1000.00
DECLARE @m2 MoneyType = 2000.00
SELECT 
    @sm1 + @sm2 AS SmallMoneySum,
    @m1 + @m2 AS MoneySum,
    @sm1 * CAST(1.1 AS SmallMoneyType) AS SmallMoneyMultiply,
    @m1 * CAST(1.1 AS MoneyType) AS MoneyMultiply
GO

--  Testing edge cases
DECLARE @maxSm SmallMoneyType = 214748.3647  -- Max SMALLMONEY value
DECLARE @maxM MoneyType = 922337203685477.5807  -- Max MONEY value
SELECT 
    @maxSm AS MaxSmallMoney,
    @maxM AS MaxMoney
GO

-- 13. Testing procedure execution
DECLARE @outSm SmallMoneyType; DECLARE @outM MoneyType
EXEC babel_5512_p2  @sm1 = 100.00, @sm2 = 200.00,@m1 = 1000.00, @m2 = 2000.00, @resultSm = @outSm OUTPUT, @resultM = @outM OUTPUT SELECT @outSm AS SmallMoneyResult, @outM AS MoneyResult
GO

-- 14. Aggregate functions with UDTs
SELECT 
    SUM(CAST(SmallMoneyCol AS SmallMoneyType)) AS SmallMoneySum,
    AVG(CAST(MoneyCol AS MoneyType)) AS MoneyAvg
FROM babel_5512_t4
GO

-- 8. Complex CASE with Multiple UDT Operations
DECLARE @basePrice SmallMoneyType = 100.50
DECLARE @maxPrice MoneyType = 1000.75
SELECT CASE 
    WHEN @basePrice * CAST(1.5 AS SmallMoneyType) < CAST(200 AS SmallMoneyType) AND
         @maxPrice * CAST(0.8 AS MoneyType) > CAST(750 AS MoneyType) THEN
        @basePrice * CAST(2.0 AS SmallMoneyType)
    WHEN @basePrice / CAST(2.0 AS SmallMoneyType) > CAST(45 AS SmallMoneyType) OR
         @maxPrice / CAST(2.0 AS MoneyType) < CAST(600 AS MoneyType) THEN
        @basePrice * CAST(1.5 AS SmallMoneyType)
    ELSE
        @basePrice * CAST(1.1 AS SmallMoneyType)
END AS ComplexUdtCase
GO

-- 9. CASE with UDT Type Conversions
DECLARE @smPrice SmallMoneyType = 150.25
DECLARE @mPrice MoneyType = 1500.75
SELECT CASE 
    WHEN CAST(@smPrice AS DECIMAL(10,2)) > 100 THEN
        CAST(CAST(@smPrice AS DECIMAL(10,2)) * 1.1 AS SmallMoneyType)
    WHEN CAST(@mPrice AS DECIMAL(10,2)) > 1000 THEN
        CAST(CAST(@mPrice AS DECIMAL(10,2)) * 0.9 AS SmallMoneyType)
    ELSE
        CAST(200 AS SmallMoneyType)
END AS ConvertedUdtCase
GO

-- smallmoney to money conversion
DECLARE @total1 smallmoney; EXEC babel_5512_p3 @basePrice = 100.00,@quantity = 2, @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO

-- money to money
DECLARE @total1 money; EXEC babel_5512_p3 @basePrice = 100.00,@quantity = 2, @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO

-- procedure executions with UDT
-- MoneyType -> money
DECLARE @total1 MoneyType; EXEC babel_5512_p3 @basePrice = 100.00,@quantity = 2, @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO

-- MoneyType -> MoneyType
DECLARE @total1 MoneyType; EXEC babel_5512_p4 @basePrice = 100.00,@quantity = 2, @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO

-- money -> MoneyType
DECLARE @total1 money; EXEC babel_5512_p4 @basePrice = 100.00,@quantity = 2, @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO

-- varchar -> babel_5512_varcharudt
DECLARE @total1 varchar; EXEC babel_5512_p4_varchar @basePrice = 'abc',@quantity = 'def', @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO

-- decimal -> babel_5512_decimaludt
DECLARE @total1 decimal; EXEC babel_5512_p4_dec @basePrice = 100.00, @quantity = 2, @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO

-- money -> MoneyType (all other args also MoneyType)
DECLARE @total1 money; EXEC babel_5512_p5 @basePrice = 100.00,@quantity = 2, @totalPrice = @total1 OUTPUT SELECT @total1 AS BasicTotalPrice
GO


-- declare variables
declare @var1 money = 678.90;
declare @var2 numeric(5,2) = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 money = 678.90;
declare @var2 decimal(5,2) = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 money = 678.90;
declare @var2 decimal = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 smallmoney = 678.90;
declare @var2 numeric(5,2) = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 smallmoney = 678.90;
declare @var2 decimal(5,2) = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 smallmoney = 678.90;
declare @var2 decimal = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 money = 678.90;
declare @var2 money = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 smallmoney = 678.90;
declare @var2 smallmoney = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 money = 678.90;
declare @var2 smallmoney = 123.45;
select @var1 + @var2 as result;
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
declare @var2 smallmoney = 123.45;
select @inputString + @var2
GO

-- UDT with declare
declare @var1 MoneyType = 678.90;
declare @var2 numeric(5,2) = 123.45;
select @var1 + @var2 as result;
go

declare @var1 MoneyType = 678.90;
declare @var2 decimal(5,2) = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 MoneyType = 678.90;
declare @var2 decimal = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 SmallMoneyType = 678.90;
declare @var2 numeric(5,2) = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 SmallMoneyType = 678.90;
declare @var2 decimal(5,2) = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 SmallMoneyType = 678.90;
declare @var2 decimal = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 MoneyType = 678.90;
declare @var2 MoneyType = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 SmallMoneyType = 678.90;
declare @var2 SmallMoneyType = 123.45;
select @var1 + @var2 as result;
GO

declare @var1 MoneyType = 678.90;
declare @var2 SmallMoneyType = 123.45;
select @var1 + @var2 as result;
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
declare @var2 SmallMoneyType = 123.45;
select @inputString + @var2
GO

-- table variable, working after my fix only handling in t_scaler
declare @tableVar2 table(a smallmoney, b numeric(5,2));
insert into @tableVar2 values(678.90, 123.45);
select a +b from @tableVar2
GO

-- scale/precion with aggregate
EXEC babel_5512_get_column_info_p1 'babel_5512_t6'
GO

-- T_Param tests for fixed length numeric dataypes
DECLARE @num NUMERIC(5,2) = 123.45, @tinyint TINYINT = 255;
SELECT @num + @tinyint AS result;
GO

DECLARE @num NUMERIC(5,2) = 123.45, @smallint SMALLINT = 32767;
SELECT @num + @smallint AS result;
GO

DECLARE @num NUMERIC(5,2) = 123.45, @int INT = 2147483647;
SELECT @num + @int AS result;
GO

DECLARE @num NUMERIC(5,2) = 123.45, @bigint BIGINT = 9223372036854775807;
SELECT @num + @bigint AS result;
GO

select 2.00 * (select 1)
GO

-- tinyint
select 2.00 * (select 255)
GO

-- smallint
select 2.00 * (select 32767)
GO

-- int
select 2.00 * (select 2147483647)
GO

-- bigint
select 2.00 * (select 9223372036854775807)
GO
