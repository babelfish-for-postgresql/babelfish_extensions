-- bigint : Int 8(int64) : -9223372036854775808 to 9223372036854775807
-- int : int 4(int32) : -2147483648 to 2147483647
-- smallint : int 2(int16) : -32768 to 32767
-- tinyint : int 1(int8) : 0 to 255
-- money: -922337203685477.5808 to 922337203685477.5807
-- Smallmoney: -214748.3648 to 214748.3647

CREATE TYPE babel_5899_MoneyUDT FROM MONEY;
GO
CREATE TYPE babel_5899_SmallMoneyUDT FROM SMALLMONEY;
GO

CREATE TABLE babel_5899_t1(
        numeric_col NUMERIC(15,5),
        money_col MONEY,
        smallmoney_col SMALLMONEY,
        bigint_col BIGINT,
        int_col INT,
        smallint_col SMALLINT,
        tinyint_col TINYINT,
        bit_col BIT,
        money_udt babel_5899_MoneyUDT,
        smallmoney_udt babel_5899_SmallMoneyUDT
)
GO

INSERT INTO babel_5899_t1 VALUES
(123.45678, 922337203685477.5807, 214748.3647, 9223372036854775807,  2147483647, 32767, 255, 1, 922337203685477.5807, 214748.3647 );
GO
INSERT INTO babel_5899_t1 VALUES
(987.65432, -922337203685477.5808, -214748.3648, -9223372036854775808, -2147483648, -32768, 0, 0,  -922337203685477.5808, -214748.3648);
GO

INSERT INTO babel_5899_t1 VALUES
(0.00001, 0.01, 0.01, 1, 1, 1, 1, 0, 0.01, 0.01);
GO

INSERT INTO babel_5899_t1 VALUES
(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
GO

-- Basic Money Operations * numeric
SELECT (CAST(1000.50 AS MONEY) + CAST(500.25 AS MONEY)) * 1.13;
GO
SELECT (CAST(1000.50 AS MONEY) - CAST(500.25 AS MONEY)) * 2.5;
GO
SELECT (CAST(1000.50 AS MONEY) * CAST(2.0 AS MONEY)) * 0.5;
GO
SELECT (CAST(1000.50 AS MONEY) / CAST(2.0 AS MONEY)) * 3.14;
GO

-- Basic Smallmoney Operations * numeric
SELECT (CAST(100.50 AS SMALLMONEY) + CAST(50.25 AS SMALLMONEY)) * 1.13;
GO
SELECT (CAST(100.50 AS SMALLMONEY) - CAST(50.25 AS SMALLMONEY)) * 2.5;
GO
SELECT (CAST(100.50 AS SMALLMONEY) * CAST(2.0 AS SMALLMONEY)) * 0.5;
GO
SELECT (CAST(100.50 AS SMALLMONEY) / CAST(2.0 AS SMALLMONEY)) * 3.14;
GO

-- Integer Operations * numeric
SELECT (CAST(1000 AS INT) + CAST(500 AS INT)) * 1.13;
GO
SELECT (CAST(1000 AS INT) - CAST(500 AS INT)) * 2.5;
GO
SELECT (CAST(1000 AS INT) * CAST(2 AS INT)) * 0.5;
GO
SELECT (CAST(1000 AS INT) / CAST(2 AS INT)) * 3.14;
GO

-- Smallint Operations * numeric
SELECT (CAST(1000 AS SMALLINT) + CAST(500 AS SMALLINT)) * 1.13;
GO
SELECT (CAST(1000 AS SMALLINT) - CAST(500 AS SMALLINT)) * 2.5;
GO
SELECT (CAST(1000 AS SMALLINT) * CAST(2 AS SMALLINT)) * 0.5;
GO
SELECT (CAST(1000 AS SMALLINT) / CAST(2 AS SMALLINT)) * 3.14;
GO

-- Tinyint Operations * numeric
SELECT (CAST(100 AS TINYINT) + CAST(50 AS TINYINT)) * 1.13;
GO
SELECT (CAST(100 AS TINYINT) - CAST(50 AS TINYINT)) * 2.5;
GO
SELECT (CAST(100 AS TINYINT) * CAST(2 AS TINYINT)) * 0.5;
GO
SELECT (CAST(100 AS TINYINT) / CAST(2 AS TINYINT)) * 3.14;
GO

-- Bigint Operations * numeric
SELECT (CAST(1000 AS BIGINT) + CAST(500 AS BIGINT)) * 1.13;
GO
SELECT (CAST(1000 AS BIGINT) - CAST(500 AS BIGINT)) * 2.5;
GO
SELECT (CAST(1000 AS BIGINT) * CAST(2 AS BIGINT)) * 0.5;
GO
SELECT (CAST(1000 AS BIGINT) / CAST(2 AS BIGINT)) * 3.14;
GO

-- Mixed Type Operations * numeric
SELECT (CAST(1000.50 AS MONEY) + CAST(50 AS INT)) * 1.13;
GO
SELECT (CAST(100.50 AS SMALLMONEY) - CAST(50 AS SMALLINT)) * 2.5;
GO
SELECT (CAST(1000 AS BIGINT) * CAST(100.50 AS MONEY)) * 0.5;
GO
SELECT (CAST(100 AS TINYINT) / CAST(2.0 AS SMALLMONEY)) * 3.14;
GO

-- Money + Smallmoney
SELECT (CAST(1000.50 AS MONEY) + CAST(100.25 AS SMALLMONEY)) * 1.13;
GO
SELECT (CAST(1000.50 AS MONEY) - CAST(100.25 AS SMALLMONEY)) * 2.5;
GO
SELECT (CAST(1000.50 AS MONEY) * CAST(100.25 AS SMALLMONEY)) * 0.5;
GO
SELECT (CAST(1000.50 AS MONEY) / CAST(100.25 AS SMALLMONEY)) * 1.13;
GO
SELECT (CAST(1000.50 AS MONEY) % CAST(100.25 AS SMALLMONEY)) * 2.5;
GO

-- Fixed length between themselves
SELECT (CAST(1000 AS BIGINT) + CAST(500 AS INT)) * 1.13;
GO
SELECT (CAST(500 AS INT) - CAST(100 AS SMALLINT)) * 2.5;
GO
SELECT (CAST(100 AS SMALLINT) * CAST(50 AS TINYINT)) * 0.5;
GO
SELECT (CAST(1000 AS BIGINT) / CAST(50 AS TINYINT)) * 1.13;
GO
SELECT (CAST(1000 AS INT) % CAST(100 AS SMALLINT)) * 2.5;
GO

-- Money + Fixed lengths
SELECT (CAST(1000.50 AS MONEY) + CAST(1000 AS BIGINT)) * 1.13;
GO
SELECT (CAST(1000.50 AS MONEY) - CAST(500 AS INT)) * 2.5;
GO
SELECT (CAST(1000.50 AS MONEY) * CAST(100 AS SMALLINT)) * 0.5;
GO
SELECT (CAST(1000.50 AS MONEY) / CAST(50 AS TINYINT)) * 1.13;
GO
SELECT (CAST(1000.50 AS MONEY) % CAST(3 AS INT)) * 2.5;
GO

-- Smallmoney + Fixed lengths
SELECT (CAST(100.25 AS SMALLMONEY) + CAST(1000 AS BIGINT)) * 1.13;
GO
SELECT (CAST(100.25 AS SMALLMONEY) - CAST(500 AS INT)) * 2.5;
GO
SELECT (CAST(100.25 AS SMALLMONEY) * CAST(100 AS SMALLINT)) * 0.5;
GO
SELECT (CAST(100.25 AS SMALLMONEY) / CAST(50 AS TINYINT)) * 1.13;
GO
SELECT (CAST(100.25 AS SMALLMONEY) % CAST(3 AS INT)) * 2.5;
GO

-- UDT Combinations
-- UDT + Normal types
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) + CAST(500.25 AS MONEY)) * 1.13;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) - CAST(100.25 AS SMALLMONEY)) * 2.5;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) * CAST(1000 AS BIGINT)) * 0.5;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) / CAST(500 AS INT)) * 1.13;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) % CAST(100 AS SMALLINT)) * 2.5;
GO

-- UDT + UDT
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) + CAST(500.25 AS babel_5899_MoneyUDT)) * 1.13;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) - CAST(500.25 AS babel_5899_MoneyUDT)) * 2.5;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) * CAST(2.0 AS babel_5899_MoneyUDT)) * 0.5;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) / CAST(2.0 AS babel_5899_MoneyUDT)) * 1.13;
GO
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) % CAST(3.0 AS babel_5899_MoneyUDT)) * 2.5;
GO

-- Different Numeric Multipliers
SELECT (CAST(1000.50 AS MONEY) + CAST(500.25 AS MONEY)) * 0.001;
GO
SELECT (CAST(1000.50 AS MONEY) + CAST(500.25 AS MONEY)) * 999.999;
GO
SELECT (CAST(1000.50 AS MONEY) + CAST(500.25 AS MONEY)) * (-1.13);
GO
SELECT (CAST(1000.50 AS MONEY) + CAST(500.25 AS MONEY)) * 0;
GO

-- Edge Cases * numeric
SELECT (CAST(922337203685477.5807 AS MONEY) - CAST(0.0001 AS MONEY)) * 1.13;
GO
SELECT (CAST(214748.3647 AS SMALLMONEY) - CAST(0.0001 AS SMALLMONEY)) * 2.5;
GO
SELECT (CAST(2147483647 AS INT) * CAST(1 AS INT)) * 0.5;
GO
SELECT (CAST(32767 AS SMALLINT) / CAST(2 AS SMALLINT)) * 3.14;
GO
SELECT (CAST(255 AS TINYINT) + CAST(0 AS TINYINT)) * 1.13;
GO
SELECT (CAST(9223372036854775807 AS BIGINT) - CAST(1 AS BIGINT)) * 0.5;
GO

-- Multiple Arithmetic Operations * numeric
SELECT (
    CAST(1000.50 AS MONEY) +
    CAST(100.25 AS SMALLMONEY) -
    CAST(50 AS INT) *
    CAST(2 AS SMALLINT) /
    CAST(4 AS TINYINT) +
    CAST(1000 AS BIGINT)
) * 1.13;
GO

-- Nested Operations * numeric
SELECT (
    (CAST(1000.50 AS MONEY) + CAST(500.25 AS MONEY)) /
    (CAST(2.0 AS MONEY) * CAST(1.5 AS MONEY))
) * 1.13;
GO


-- Testing declare

-- Declare Variables * numeric
DECLARE @m1 MONEY = 1000.50;
DECLARE @m2 SMALLMONEY = 100.25;
DECLARE @bi BIGINT = 1000;
DECLARE @i INT = 500;
DECLARE @si SMALLINT = 100;
DECLARE @ti TINYINT = 50;
DECLARE @udt1 babel_5899_MoneyUDT = 1500.75;

SELECT (@m1 + @m2) * 1.13;
SELECT (@m1 - @bi) * 2.5;
SELECT (@m2 * @i) * 0.5;
SELECT (@m1 / @si) * 1.13;
SELECT (@m1 % @ti) * 2.5;
GO

-- declare with UDT
DECLARE @udt1 babel_5899_MoneyUDT = 1000.50;
DECLARE @udt2 babel_5899_MoneyUDT = 500.25;
SELECT (@udt1 + @udt2) * 1.13;
SELECT (CAST(1000.50 AS babel_5899_MoneyUDT) + CAST(500.25 AS babel_5899_MoneyUDT)) * 2.5;
GO

-- JIRA query
DECLARE @revenue MONEY = 10000.00; DECLARE @costs MONEY = 6000.00; DECLARE @targetMargin money = 0.40;
select (@revenue - @costs) * 1.13
go

-- JIRA query
DECLARE @num1 NUMERIC(5,2) = 123.45, @num2 NUMERIC(5,2) = 678.90, @int1 INT = 2, @int2 INT = 3;
SELECT (@num1 * @num2) / (@int1 + @int2) AS result;
GO

-- edge cases
-- Basic Money and SmallMoney Declarations
DECLARE @m1 MONEY = 922337203685477.5807; -- Max
DECLARE @m2 MONEY = -922337203685477.5808; -- Min
DECLARE @sm1 SMALLMONEY = 214748.3647; -- Max
DECLARE @sm2 SMALLMONEY = -214748.3648; -- Min
SELECT (@m1 - @sm1) * 1.13;
SELECT (@m2 - @sm2) * 2.5;
SELECT (@m2 / @sm2) * 1.13;
GO

-- Integer Type Edge Cases
-- Basic Integer Operations
DECLARE @bi1 BIGINT = 9223372036854775807;  -- Max
DECLARE @bi2 BIGINT = -9223372036854775808; -- Min
DECLARE @i1 INT = 2147483647;               -- Max
DECLARE @i2 INT = -2147483648;              -- Min
DECLARE @si1 SMALLINT = 32767;              -- Max
DECLARE @si2 SMALLINT = -32768;             -- Min
DECLARE @ti1 TINYINT = 255;                 -- Max
DECLARE @ti2 TINYINT = 0;                   -- Min

-- Addition Operations
SELECT (@bi1 + cast(-123 as int)) * 1.13;
SELECT (@bi1 * 1.13);
SELECT (@bi2 + cast(123 as smallint)) * 2.5;
SELECT (@i1 + cast(-123 as bigint)) * 0.5;
SELECT (@si1 + cast(123 as tinyint)) * 1.13;

-- Subtraction Operations
SELECT (@bi1 - @i1) * 1.13;
SELECT (@bi2 - @si1) * 2.5;
SELECT (@i2 - @ti1) * 0.5;
SELECT (@si2 - @ti2) * 1.13;
SELECT (@si2 * 1.13);

-- Multiplication Operations
SELECT (@i1 * cast(1 as smallint)) * 2.5;
SELECT (@si1 * cast(1 as tinyint)) * 0.5;
SELECT (@ti1 * cast(1 as int)) * 1.13;

-- Division Operations
SELECT (@bi1 / @i1) * 1.13;
SELECT (@bi2 / @si1) * 2.5;
SELECT (@i1 / @ti1) * 0.5;
SELECT (@si1 / @ti1) * 1.13;

-- Modulus Operations
SELECT (@bi1 % @i1) * 1.13;
SELECT (@bi2 % @si1) * 2.5;
SELECT (@i1 % @ti1) * 0.5;
SELECT (@si1 % @ti1) * 1.13;

-- Mixed Operations
SELECT (@bi1 - @i1 - @si1) * 1.13;
SELECT (@bi2 + @i2 + @ti1) * 2.5;
SELECT (@i1 / @si1 / @ti1) * 0.5;
SELECT (@si2 / @ti1 + @bi1) * 1.13;

-- Complex Combinations
SELECT (@bi1 - @i1 * @si1 / @ti1) * 1.13;
SELECT (@bi2 - @i2 / @si2 * @ti1) * 2.5;
SELECT (@i1 / @si1 - @ti1 + @bi1) * 0.5;
SELECT (@si2 + @ti1 * @i1 / @bi2) * 1.13;

-- Operations with Zero
SELECT (@bi1 + @ti2) * 1.13;  -- with zero
SELECT (@i1 - @ti2) * 2.5;    -- with zero
SELECT (@si1 * @ti2) * 0.5;   -- with zero

-- Operations with Negative Numbers
SELECT (@bi2 + @i2) * 1.13;   -- both negative
SELECT (@si2 - @i1) * 2.5;    -- mixed signs
SELECT (@i2 * @ti1) * 0.5;    -- negative and positive

-- Nested Operations
SELECT ((@bi1 - @i1) * (@si1 - @ti1)) * 1.13;
SELECT ((@bi2 - @i2) / (@si2 + @ti2)) * 2.5;
SELECT ((@i1 * @si1) % (@ti1 + 1)) * 0.5;
GO

-- Misc declare statements
DECLARE @bi1 BIGINT = 1234
SELECT (@bi1 + cast(-123 as int)) * 1.13;
SELECT (@bi1 * 1.13);
GO

-- UDT Combinations
DECLARE @udt1 babel_5899_MoneyUDT = 922337203685477.5807; -- Max
DECLARE @udt2 babel_5899_MoneyUDT = -922337203685477.5808; -- Min
DECLARE @sudt1 babel_5899_SmallMoneyUDT = 214748.3647; -- Max
DECLARE @sudt2 babel_5899_SmallMoneyUDT = -214748.3648; -- Min
SELECT (@udt1 - @sudt1) * 1.13;
SELECT (@udt2 - @sudt2) * 2.5;
GO

-- Complex Calculations
DECLARE @revenue MONEY = 100000.00;
DECLARE @cost BIGINT = 7500012300;
DECLARE @tax_rate INT = 20123;
DECLARE @profit_margin SMALLMONEY = 0.15;
SELECT (@revenue - @cost) * (1 + @tax_rate) * (1 + @profit_margin) * 1.13;
GO

-- Nested Calculations
DECLARE @base_amount MONEY = 1000.00;
DECLARE @multiplier1 SMALLMONEY = 1.5;
DECLARE @multiplier2 INT = 20;
DECLARE @divisor SMALLINT = 2;
SELECT ((@base_amount * @multiplier1) / CAST(@divisor AS MONEY) * @multiplier2) * 1.13;
GO

-- Multiple Operations
DECLARE @val1 MONEY = 1000.00;
DECLARE @val2 SMALLMONEY = 500.00;
DECLARE @val3 babel_5899_MoneyUDT = 250.00;
SELECT (@val1 + @val2) * 1.13;
SELECT (@val1 - @val2) * 2.5;
SELECT (@val1 * @val3) * 0.5;
SELECT (@val1 / @val2) * 1.13;
SELECT (@val1 % @val2) * 2.5;
GO


-- NULL Handling
DECLARE @null_money MONEY = NULL;
DECLARE @null_smallmoney SMALLMONEY = NULL;
DECLARE @null_udt babel_5899_MoneyUDT = NULL;
SELECT ISNULL((@null_money + @null_smallmoney) * 1.13, 0);
SELECT COALESCE((@null_money + @null_udt) * 2.5, 0);
GO

-- using table columns
-- Basic Operations with Money Types
SELECT (money_col - smallmoney_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (money_udt - smallmoney_udt) * 2.5 FROM babel_5899_t1;
GO
SELECT (money_col + money_udt) * 0.5 FROM babel_5899_t1;
GO
SELECT (smallmoney_col / smallmoney_udt) * 1.13 FROM babel_5899_t1;
GO
SELECT (money_col % smallmoney_col) * 2.5 FROM babel_5899_t1;
GO

-- Money Types with Fixed Length Types
-- Money with Integer Types
SELECT (money_col + bigint_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (money_col - int_col) * 2.5 FROM babel_5899_t1;
GO
SELECT (money_col + smallint_col) * 0.5 FROM babel_5899_t1;
GO
SELECT (money_col / tinyint_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (money_col % bigint_col) * 2.5 FROM babel_5899_t1;
GO

-- Smallmoney with Integer Types
SELECT (smallmoney_col + bigint_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (smallmoney_col - int_col) * 2.5 FROM babel_5899_t1;
GO
SELECT (smallmoney_col * smallint_col) * 0.5 FROM babel_5899_t1;
GO
SELECT (smallmoney_col / tinyint_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (smallmoney_col % bigint_col) * 2.5 FROM babel_5899_t1;
GO

-- UDT Operations
-- UDT with Money Types
SELECT (money_udt + money_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (money_udt - smallmoney_col) * 2.5 FROM babel_5899_t1;
GO
SELECT (smallmoney_udt * money_col) * 0.5 FROM babel_5899_t1;
GO
SELECT (smallmoney_udt / smallmoney_col) * 1.13 FROM babel_5899_t1;
GO

-- UDT with Integer Types
SELECT (money_udt + bigint_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (money_udt - int_col) * 2.5 FROM babel_5899_t1;
GO
SELECT (smallmoney_udt * smallint_col) * 0.5 FROM babel_5899_t1;
GO
SELECT (smallmoney_udt / tinyint_col) * 1.13 FROM babel_5899_t1;
GO

-- Numeric Operations
SELECT (numeric_col + money_col) * 1.13 FROM babel_5899_t1;
GO
SELECT (numeric_col - smallmoney_col) * 2.5 FROM babel_5899_t1;
GO
SELECT (numeric_col * money_udt) * 0.5 FROM babel_5899_t1;
GO
SELECT (numeric_col / smallmoney_udt) * 1.13 FROM babel_5899_t1;
GO

-- Complex Combinations
SELECT (
    money_col + 
    smallmoney_col * 
    bigint_col /
    int_col
) * 1.13 FROM babel_5899_t1;
GO

SELECT (
    money_udt + 
    smallmoney_udt * 
    CAST(smallint_col AS MONEY) / 
    CAST(tinyint_col AS MONEY)
) * 2.5 FROM babel_5899_t1;
GO

--  COLAESCE Handling
SELECT COALESCE((money_udt - smallmoney_udt) * 2.5, 0) FROM babel_5899_t1;
GO

-- Edge Cases
-- Maximum Values
SELECT (
    CASE
        WHEN money_col = 922337203685477.5807
        THEN (money_col - cast(123.12 as money) * 1.0)
        ELSE 0
    END
) * 1.13 FROM babel_5899_t1;
GO

SELECT (
    CASE
        WHEN smallmoney_col = 214748.3647
        THEN (smallmoney_col - cast(12.333 as money) * 1.0)
        ELSE 0
    END
) * 2.5 FROM babel_5899_t1;
GO

-- Minimum Values
SELECT (
    CASE 
        WHEN money_col = -922337203685477.5808
        THEN (money_col + cast(123.12 as money) * 1.0)
        ELSE 0
    END
) * 1.13 FROM babel_5899_t1;
GO

SELECT (
    CASE
        WHEN smallmoney_col = -214748.3648
        THEN (smallmoney_col + cast(12.333 as money) * 1.0)
        ELSE 0
    END
) * 2.5 FROM babel_5899_t1;
GO

-- INT Edge Cases
-- Maximum Value (2147483647)
SELECT (
    CASE
        WHEN int_col = 2147483647
        THEN (CAST(int_col AS MONEY) - CAST(123.12 AS MONEY) * 1.0)
        ELSE 0
    END
) * 2.5 FROM babel_5899_t1;
GO

-- Minimum Value (-2147483648)
SELECT (
    CASE
        WHEN int_col = -2147483648
        THEN ((int_col + CAST(1233 AS smallint)) * 1.0)
        ELSE 0
    END
) * 2.5 FROM babel_5899_t1;
GO

-- SMALLINT Edge Cases
-- Maximum Value (32767)
SELECT (
    CASE
        WHEN smallint_col = 32767
        THEN ((smallint_col - CAST(1233 AS smallint)) * 1.0)
        ELSE 0
    END
) * 0.5 FROM babel_5899_t1;
GO

-- Minimum Value (-32768)
SELECT (
    CASE
        WHEN smallint_col = -32768
        THEN ((smallint_col + CAST(1233 AS smallint)) * 1.0)
        ELSE 0
    END
) * 0.5 FROM babel_5899_t1;
GO

-- TINYINT Edge Cases
-- Maximum Value (255)
SELECT (
    CASE
        WHEN tinyint_col = 255
        THEN ((tinyint_col - CAST(123 AS tinyint)) * 1.0)
        ELSE 0
    END
) * 1.13 FROM babel_5899_t1;
GO

-- Combined Edge Cases
-- Maximum Values Combined
SELECT (
    CASE
        WHEN bigint_col = 9223372036854775807 AND int_col = 2147483647
        THEN ((bigint_col - int_col - CAST(12.333 AS MONEY)) * 1.0)
        ELSE 0
    END
) * 1.13 FROM babel_5899_t1;
GO

SELECT (
    CASE
        WHEN smallint_col = 32767 AND tinyint_col = 255
        THEN ((smallint_col - tinyint_col - CAST(12.333 AS MONEY)) * 1.0)
        ELSE 0
    END
) * 2.5 FROM babel_5899_t1;
GO

-- Minimum Values Combined
SELECT (
    CASE
        WHEN bigint_col = -9223372036854775808 AND int_col = -2147483648
        THEN ((bigint_col - int_col + CAST(12.333 AS MONEY)) * 1.0)
        ELSE 0
    END
) * 0.5 FROM babel_5899_t1;
GO

SELECT (
    CASE
        WHEN smallint_col = -32768 AND tinyint_col = 0
        THEN ((smallint_col + tinyint_col + CAST(12.333 AS MONEY)) * 1.0)
        ELSE 0
    END
) * 1.13 FROM babel_5899_t1;
GO

-- Mixed Maximum and Minimum Values
SELECT (
    CASE
        WHEN bigint_col = 9223372036854775807 AND int_col = -2147483648
        THEN ((bigint_col + int_col + CAST(12.333 AS MONEY)) * 1.0)
        ELSE 0
    END
) * 2.5 FROM babel_5899_t1;
GO

SELECT (
    CASE
        WHEN smallint_col = -32768 AND tinyint_col = 255
        THEN ((smallint_col + tinyint_col) * 1.0)
        ELSE 0
    END
) * 1.13 FROM babel_5899_t1;
GO

-- All Integer Types Combined
SELECT (
    CASE
        WHEN int_col = 2147483647
             AND smallint_col = 32767
             AND tinyint_col = 255
        THEN (bigint_col - int_col - smallint_col - tinyint_col)* 1.0
        ELSE 0
    END
) * 1.13 FROM babel_5899_t1;
GO

-- Aggregate Functions
SELECT (SUM(money_col) + SUM(smallmoney_col)) * 1.13 FROM babel_5899_t1;
GO
SELECT (AVG(money_udt) - AVG(smallmoney_udt)) * 2.5 FROM babel_5899_t1;
GO
SELECT (MAX(money_col) * MIN(smallmoney_col)) * 0.5 FROM babel_5899_t1;
GO

-- Conditional Operations
SELECT (
    CASE 
        WHEN bit_col = 1 THEN (money_col + cast(123.12 as money) * 1.0) 
        ELSE (smallmoney_col - cast(123 as money)) * 1.0
    END
) * 1.13 FROM babel_5899_t1;
GO

-- Multiple Row Operations
SELECT (t1.money_col - t2.smallmoney_col) * 1.13
FROM babel_5899_t1 t1
JOIN babel_5899_t1 t2 ON t1.bit_col = t2.bit_col;
GO

-- Subqueries
SELECT (money_col - (SELECT AVG(smallmoney_col) FROM babel_5899_t1)) * 1.13
FROM babel_5899_t1;
GO

-- Different Numeric Multipliers
SELECT (money_col - smallmoney_col) * 0.001 FROM babel_5899_t1;
GO
SELECT (money_col - smallmoney_col) * 999.999 FROM babel_5899_t1;
GO
SELECT (money_col - smallmoney_col) * (-1.13) FROM babel_5899_t1;
GO
SELECT (money_col - smallmoney_col) * 0 FROM babel_5899_t1;
GO


-- Misc tests
select (122 + cast(123 as smallint))* 1.1
GO
select (123 + cast(123 as money)) * 1.1
GO
select cast(122 as tinyint) * 1.12
GO
-- Integer + Different Types
SELECT (122 + CAST(123 AS SMALLINT)) * 1.1;
GO
SELECT (122 + CAST(123 AS INT)) * 1.1;
GO
SELECT (122 + CAST(123 AS BIGINT)) * 1.1;
GO
SELECT (122 + CAST(123 AS TINYINT)) * 1.1;
GO
-- money * numeric
select cast(123 as money) * cast(123.23 as numeric(5,2))
GO
-- Constants with Different Types
SELECT (123.45 + CAST(123 AS MONEY)) * 1.1;
GO
SELECT (123.45 + CAST(123 AS SMALLMONEY)) * 1.1;
GO
SELECT (123.45 + CAST(123 AS INT)) * 1.1;
GO

-- scale/precision test for fixedlength operator expression
CREATE PROCEDURE babel_5899_get_column_info_p1 @table_name text AS BEGIN SELECT c.[name] AS column_name, t.[name] AS [type_name], c.[max_length], c.[precision],c.[scale] FROM sys.columns c INNER JOIN sys.types t ON c.user_type_id = t.user_type_id WHERE object_id = object_id(@table_name) ORDER BY c.[name];
END
GO

CREATE TABLE babel_5899_t2(ID INT IDENTITY(1,1), a_int Int, a_tiny tinyint, b_smallint smallint, c_big bigint, d_fl float, e_real real, f_mon money, g_smallmoney smallmoney);
GO

SELECT 
    (a_int + a_int) * 1.13 AS int_int,
    (a_int + a_tiny) * 1.13 AS int_tiny,
    (a_int + b_smallint) * 1.13 AS int_smallint,
    (a_int + c_big) * 1.13 AS int_bigint,
    (a_tiny + a_tiny) * 1.13 AS tiny_tiny,
    (a_tiny + b_smallint) * 1.13 AS tiny_smallint,
    (a_tiny + c_big) * 1.13 AS tiny_bigint,
    (b_smallint + b_smallint) * 1.13 AS smallint_smallint,
    (b_smallint + c_big) * 1.13 AS smallint_bigint,
    (c_big + c_big) * 1.13 AS bigint_bigint,
    (f_mon + f_mon) * 1.13 AS money_money,
    (f_mon + g_smallmoney) * 1.13 AS money_smallmoney,
    (g_smallmoney + g_smallmoney) * 1.13 AS smallmoney_smallmoney,
    (f_mon + a_int) * 1.13 AS money_int,
    (f_mon + a_tiny) * 1.13 AS money_tiny,
    (f_mon + b_smallint) * 1.13 AS money_smallint,
    (f_mon + c_big) * 1.13 AS money_bigint,
    (g_smallmoney + a_int) * 1.13 AS smallmoney_int,
    (g_smallmoney + a_tiny) * 1.13 AS smallmoney_tiny,
    (g_smallmoney + b_smallint) * 1.13 AS smallmoney_smallint,
    (g_smallmoney + c_big) * 1.13 AS smallmoney_bigint
INTO babel_5899_result_table
FROM babel_5899_t2;
GO

EXEC babel_5899_get_column_info_p1 'babel_5899_result_table'
GO

DROP TABLE babel_5899_t1
go
DROP TYPE babel_5899_MoneyUDT
GO
DROP TYPE babel_5899_SmallMoneyUDT
GO
DROP TABLE babel_5899_result_table
GO
DROP TABLE babel_5899_t2
GO
DROP PROCEDURE babel_5899_get_column_info_p1
go

