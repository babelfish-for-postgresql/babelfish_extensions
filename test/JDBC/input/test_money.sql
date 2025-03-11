-- Create test tables
CREATE TABLE MoneyTestTable1 (
    ID INT IDENTITY(1,1),
    MoneyVal MONEY,
    SmallMoneyVal SMALLMONEY,
    Description VARCHAR(100)
);

-- =============================================
-- 1. Data Type Range Tests
-- =============================================

-- Test default values
INSERT INTO MoneyTestTable1 DEFAULT VALUES;
GO

INSERT INTO MoneyTestTable1 (MoneyVal, SmallMoneyVal, Description)
VALUES 
    (-922337203685477.5808, -214748.3648, 'MIN values'),
    (922337203685477.5807, 214748.3647, 'MAX values'),
    (NULL, NULL, 'NULL values'),
    (CAST(RAND() * 1000000 AS MONEY), 
     CAST(RAND() * 10000 AS SMALLMONEY), 'Random values'),
    (0.0001, 0.0001, 'Small positive values'),
    (-0.0001, -0.0001, 'Small negative values'),
    (0,0, 'Zero Values');

-- Display results
SELECT 'Range Test Results' AS TestName, * FROM MoneyTestTable1 where Description NOT LIKE 'Random values';
GO



-- =============================================
-- 2.Overflow Tests
-- =============================================
INSERT INTO MoneyTestTable1 (MoneyVal, Description) VALUES (922337203685477.5808, 'Overflow MONEY test'); -- Exceeds maximum
GO

INSERT INTO MoneyTestTable1 (SmallMoneyVal, Description) VALUES (214748.3648, 'Overflow SMALLMONEY test'); -- Exceeds maximum
GO

INSERT INTO MoneyTestTable1 (MoneyVal, Description) VALUES (-922337203685477.5809, 'Underflow MONEY test'); -- Below minimum
GO

INSERT INTO MoneyTestTable1 (SmallMoneyVal, Description) VALUES (-214748.3649, 'Underflow SMALLMONEY test'); -- Below minimum
GO

-- Try Overflow with Arithematic Operators
-- +
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS SMALLMONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS TINYINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS SMALLINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS INT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS BIGINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS REAL);
GO
SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS FLOAT);
GO
-- TODO: File JIRA, TDS Protocol Error for MONEY + NUMERIC
-- SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS NUMERIC);
-- GO
-- SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS DECIMAL);
-- GO
-- SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(922337203685477.5807 AS MONEY) + CAST(1 AS DECIMAL(5,2));
-- GO

-- -
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS MONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS TINYINT);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS SMALLINT);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS INT);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS BIGINT);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS REAL);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS FLOAT);
GO
-- TODO: File JIRA, TDS Protocol Error for MONEY -  NUMERIC
-- SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS NUMERIC);
-- GO
-- SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS DECIMAL);
-- GO
-- SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(-922337203685477.5808 AS MONEY) - CAST(1 AS DECIMAL(5,2));
-- GO

-- *
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS MONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS SMALLMONEY);
GO
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(2 AS TINYINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(2 AS SMALLINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(2 AS INT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(2 AS BIGINT);
GO
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS REAL);
GO
SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS FLOAT);
GO
-- TODO: File JIRA, TDS Protocol Error for MONEY *  NUMERIC
-- SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS NUMERIC);
-- GO
-- SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS DECIMAL);
-- GO
-- SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(922337203685477.5807 AS MONEY) * CAST(1.1 AS DECIMAL(5,2));
-- GO

-- /
SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS MONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS SMALLMONEY);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS REAL);
GO
SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS FLOAT);
GO

-- TODO: File JIRA, TDS Protocol Error for MONEY /  NUMERIC
-- SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS NUMERIC);
-- GO
-- SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS DECIMAL);
-- GO
-- SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(-922337203685477.5808 AS MONEY) / CAST(0.9 AS DECIMAL(5,2));
-- GO


-- +
-- TODO: File JIRA , Smallmoney + Smallmoney Doesnt follow bound checks
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS SMALLMONEY);
GO
-- TODO: File JIRA , Smallmoney + money Doesnt follow bound checks
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS MONEY);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS TINYINT);
GO
-- TODO: File JIRA , Smallmoney + smallint Doesnt follow bound checks
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS SMALLINT);
GO
-- TODO: File JIRA , Smallmoney + int Doesnt follow bound checks
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS INT);
GO
-- TODO: File JIRA , Smallmoney + bigint Doesnt follow bound checks
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS BIGINT);
GO
-- TODO: File JIRA , Smallmoney + real Doesnt follow bound checks
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS REAL);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS FLOAT);
GO
-- TODO: File JIRA, TDS Protocol Error for SMALLMONEY + NUMERIC
-- SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS NUMERIC);
-- GO
-- SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS DECIMAL);
-- GO
-- SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(214748.3647 AS SMALLMONEY) + CAST(1 AS DECIMAL(5,2));
-- GO

-- - 
-- TODO: File JIRA , Smallmoney - Smallmoney Doesnt follow bound checks
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS MONEY);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS TINYINT);
GO
-- TODO: File JIRA , Smallmoney - smallint Doesnt follow bound checks
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS SMALLINT);
GO
-- TODO: File JIRA , Smallmoney - int Doesnt follow bound checks
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS INT);
GO
-- TODO: File JIRA , Smallmoney - bigint Doesnt follow bound checks
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS BIGINT);
GO
-- TODO: File JIRA , Smallmoney - real Doesnt follow bound checks
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS REAL);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS FLOAT);
GO
-- TODO: File JIRA, TDS Protocol Error for SMALLMONEY - NUMERIC
-- SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS NUMERIC);
-- GO
-- SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS DECIMAL);
-- GO
-- SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(-214748.3648 AS SMALLMONEY) - CAST(1 AS DECIMAL(5,2));
-- GO

-- *
-- TODO: File JIRA , Smallmoney * Smallmoney Doesnt follow bound checks
SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS SMALLMONEY);
GO
-- TODO: File JIRA output diff: Smallmoney * Money Output Diff
SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS MONEY);
GO
-- TODO: File JIRA output diff: Smallmoney * TinyInt Doesnt Follow Bound Checks
SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS TINYINT);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS SMALLINT);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS INT);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS REAL);
GO
SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS FLOAT);
GO
-- TODO: File JIRA, TDS Protocol Error for SMALLMONEY * NUMERIC
-- SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS NUMERIC);
-- GO
-- SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS DECIMAL);
-- GO
-- SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(214748.3647 AS SMALLMONEY) * CAST(1.1 AS DECIMAL(5,2));
-- GO

-- /
-- TODO: File JIRA , Smallmoney / Smallmoney Doesnt follow bound checks
SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS SMALLMONEY);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS MONEY);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS REAL);
GO
SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS FLOAT);
GO
-- TODO: File JIRA, TDS Protocol Error for SMALLMONEY /  NUMERIC
-- SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS NUMERIC);
-- GO
-- SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS DECIMAL);
-- GO
-- SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS NUMERIC(5,2));
-- GO
-- SELECT CAST(-214748.3648 AS SMALLMONEY) / CAST(0.9 AS DECIMAL(5,2));
-- GO

-- TODO:Try Overflow With Aggregates

------------------------------------------------------------------------
---- 3. Arithmetic Operations Tests
------------------------------------------------------------------------
-- Addition (+) operator tests with MONEY
-- MONEY + MONEY
SELECT CAST(123.45 AS MONEY) + CAST(678.90 AS MONEY) AS result;
GO

-- MONEY + SMALLMONEY
SELECT CAST(123.45 AS MONEY) + CAST(678.90 AS SMALLMONEY) AS result;
GO

-- MONEY + TINYINT
SELECT CAST(123.45 AS MONEY) + CAST(255 AS TINYINT) AS result;
GO

-- MONEY + SMALLINT
SELECT CAST(123.45 AS MONEY) + CAST(32767 AS SMALLINT) AS result;
GO

-- MONEY + INT
SELECT CAST(123.45 AS MONEY) + CAST(2147483647 AS INT) AS result;
GO

-- TODO: File Jira, MONEY+BIGINT Doesnt Follow Bound Checks
-- MONEY + BIGINT
SELECT CAST(123.45 AS MONEY) + CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- TODO: File JIRA, Money+REAL Precision Difference
-- MONEY + REAL
SELECT CAST(123.45 AS MONEY) + CAST(678.90 AS REAL) AS result;
GO

-- MONEY + FLOAT
SELECT CAST(123.45 AS MONEY) + CAST(678.90 AS FLOAT) AS result;
GO

-- MONEY + NUMERIC(5,2)
SELECT CAST(123.45 AS MONEY) + CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- MONEY + NUMERIC(10,4)
SELECT CAST(123.45 AS MONEY) + CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- MONEY + NUMERIC(18,6)
SELECT CAST(123.45 AS MONEY) + CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- MONEY + BIT
SELECT CAST(123.45 AS MONEY) + CAST(1 AS BIT) AS result;
GO

-- Subtraction (-) operator tests with MONEY
-- MONEY - MONEY
SELECT CAST(123.45 AS MONEY) - CAST(678.90 AS MONEY) AS result;
GO

-- MONEY - SMALLMONEY
SELECT CAST(123.45 AS MONEY) - CAST(678.90 AS SMALLMONEY) AS result;
GO

-- MONEY - TINYINT
SELECT CAST(123.45 AS MONEY) - CAST(255 AS TINYINT) AS result;
GO

-- MONEY - SMALLINT
SELECT CAST(123.45 AS MONEY) - CAST(32767 AS SMALLINT) AS result;
GO

-- MONEY - INT
SELECT CAST(123.45 AS MONEY) - CAST(2147483647 AS INT) AS result;
GO

-- TODO: File Jira, MONEY-BIGINT Doesnt Follow Bound Checks
-- MONEY - BIGINT
SELECT CAST(123.45 AS MONEY) - CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- TODO: File JIRA, Money-REAL Precision Difference
-- MONEY - REAL
SELECT CAST(123.45 AS MONEY) - CAST(678.90 AS REAL) AS result;
GO

-- MONEY - FLOAT
SELECT CAST(123.45 AS MONEY) - CAST(678.90 AS FLOAT) AS result;
GO

-- MONEY - NUMERIC(5,2)
SELECT CAST(123.45 AS MONEY) - CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- MONEY - NUMERIC(10,4)
SELECT CAST(123.45 AS MONEY) - CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- MONEY - NUMERIC(18,6)
SELECT CAST(123.45 AS MONEY) - CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- MONEY - BIT
SELECT CAST(123.45 AS MONEY) - CAST(1 AS BIT) AS result;
GO

-- Multiplication (*) operator tests with MONEY
-- MONEY * MONEY
SELECT CAST(123.45 AS MONEY) * CAST(678.90 AS MONEY) AS result;
GO

-- MONEY * SMALLMONEY
SELECT CAST(123.45 AS MONEY) * CAST(678.90 AS SMALLMONEY) AS result;
GO

-- MONEY * TINYINT
SELECT CAST(123.45 AS MONEY) * CAST(255 AS TINYINT) AS result;
GO

-- MONEY * SMALLINT
SELECT CAST(123.45 AS MONEY) * CAST(32767 AS SMALLINT) AS result;
GO

-- MONEY * INT
SELECT CAST(123.45 AS MONEY) * CAST(2147483647 AS INT) AS result;
GO

-- TODO: File Jira, MONEY*BIGINT Doesnt Follow Bound Checks
-- MONEY * BIGINT
SELECT CAST(123.45 AS MONEY) * CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- TODO: File JIRA, Money*REAL Precision Difference
-- MONEY * REAL
SELECT CAST(123.45 AS MONEY) * CAST(678.90 AS REAL) AS result;
GO

-- MONEY * FLOAT
SELECT CAST(123.45 AS MONEY) * CAST(678.90 AS FLOAT) AS result;
GO

-- MONEY * NUMERIC(5,2)
SELECT CAST(123.45 AS MONEY) * CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- MONEY * NUMERIC(10,4)
SELECT CAST(123.45 AS MONEY) * CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- TODO: File JIRA, Money*NUMERIC Precision Difference
-- MONEY * NUMERIC(18,6)
SELECT CAST(123.45 AS MONEY) * CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- MONEY * BIT
SELECT CAST(123.45 AS MONEY) * CAST(1 AS BIT) AS result;
GO

-- Division (/) operator tests with MONEY
-- MONEY / MONEY
SELECT CAST(123.45 AS MONEY) / CAST(678.90 AS MONEY) AS result;
GO

-- MONEY / SMALLMONEY
SELECT CAST(123.45 AS MONEY) / CAST(678.90 AS SMALLMONEY) AS result;
GO

-- MONEY / TINYINT
SELECT CAST(123.45 AS MONEY) / CAST(255 AS TINYINT) AS result;
GO

-- MONEY / SMALLINT
SELECT CAST(123.45 AS MONEY) / CAST(32767 AS SMALLINT) AS result;
GO

-- MONEY / INT
SELECT CAST(123.45 AS MONEY) / CAST(2147483647 AS INT) AS result;
GO

-- TODO: File Jira, MONEY/BIGINT Doesnt Follow Bound Checks
-- MONEY / BIGINT
SELECT CAST(123.45 AS MONEY) / CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- MONEY / REAL
SELECT CAST(123.45 AS MONEY) / CAST(678.90 AS REAL) AS result;
GO

-- MONEY / FLOAT
SELECT CAST(123.45 AS MONEY) / CAST(678.90 AS FLOAT) AS result;
GO

-- TODO: File JIRA, Money/NUMERIC Precision Difference
-- MONEY / NUMERIC(5,2)
SELECT CAST(123.45 AS MONEY) / CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- TODO: File JIRA, Money/NUMERIC Precision Difference
-- MONEY / NUMERIC(10,4)
SELECT CAST(123.45 AS MONEY) / CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- TODO: File JIRA, Money/NUMERIC Precision Difference
-- MONEY / NUMERIC(18,6)
SELECT CAST(123.45 AS MONEY) / CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- MONEY / BIT
SELECT CAST(123.45 AS MONEY) / CAST(1 AS BIT) AS result;
GO

-- Modulo (%) operator tests with MONEY
-- MONEY % MONEY
SELECT CAST(123.45 AS MONEY) % CAST(678.90 AS MONEY) AS result;
GO

-- MONEY % SMALLMONEY
SELECT CAST(123.45 AS MONEY) % CAST(678.90 AS SMALLMONEY) AS result;
GO

-- MONEY % TINYINT
SELECT CAST(123.45 AS MONEY) % CAST(255 AS TINYINT) AS result;
GO

-- MONEY % SMALLINT
SELECT CAST(123.45 AS MONEY) % CAST(32767 AS SMALLINT) AS result;
GO

-- MONEY % INT
SELECT CAST(123.45 AS MONEY) % CAST(2147483647 AS INT) AS result;
GO

-- MONEY % BIGINT
SELECT CAST(123.45 AS MONEY) % CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- TODO: File JIRA, Money%REAL is incompatible in T-SQL
-- MONEY % REAL
SELECT CAST(123.45 AS MONEY) % CAST(678.90 AS REAL) AS result;
GO

-- TODO: File JIRA, Money%FLOAT is incompatible in T-SQL
-- MONEY % FLOAT
SELECT CAST(123.45 AS MONEY) % CAST(678.90 AS FLOAT) AS result;
GO

-- TODO: File JIRA, Money%NUMERIC Precision Difference
-- MONEY % NUMERIC(5,2)
SELECT CAST(123.45 AS MONEY) % CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- MONEY % NUMERIC(10,4)
SELECT CAST(123.45 AS MONEY) % CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- MONEY % NUMERIC(18,6)
SELECT CAST(123.45 AS MONEY) % CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- MONEY % BIT
SELECT CAST(123.45 AS MONEY) % CAST(1 AS BIT) AS result;
GO


-- Addition (+) operator tests with SMALLMONEY
-- SMALLMONEY + MONEY
SELECT CAST(123.45 AS SMALLMONEY) + CAST(678.90 AS MONEY) AS result;
GO

-- SMALLMONEY + SMALLMONEY
SELECT CAST(123.45 AS SMALLMONEY) + CAST(678.90 AS SMALLMONEY) AS result;
GO

-- SMALLMONEY + TINYINT
SELECT CAST(123.45 AS SMALLMONEY) + CAST(255 AS TINYINT) AS result;
GO

-- SMALLMONEY + SMALLINT
SELECT CAST(123.45 AS SMALLMONEY) + CAST(32767 AS SMALLINT) AS result;
GO

-- SMALLMONEY + INT
-- TODO: File JIRA , TDS Protocal error in case of overflow for smallmoney
-- SELECT CAST(123.45 AS SMALLMONEY) + CAST(2147483647 AS INT) AS result;
-- GO

-- TODO: File Jira, SMALLMONEY+BIGINT Doesnt Follow Bound Checks
-- SMALLMONEY + BIGINT
SELECT CAST(123.45 AS SMALLMONEY) + CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- SMALLMONEY + REAL
SELECT CAST(123.45 AS SMALLMONEY) + CAST(678.90 AS REAL) AS result;
GO

-- SMALLMONEY + FLOAT
SELECT CAST(123.45 AS SMALLMONEY) + CAST(678.90 AS FLOAT) AS result;
GO

-- TODO: File JIRA, SmallMoney+NUMERIC Precision Difference
-- SMALLMONEY + NUMERIC(5,2)
SELECT CAST(123.45 AS SMALLMONEY) + CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- SMALLMONEY + NUMERIC(10,4)
SELECT CAST(123.45 AS SMALLMONEY) + CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- SMALLMONEY + NUMERIC(18,6)
SELECT CAST(123.45 AS SMALLMONEY) + CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- TODO: File JIRA, SmallMoney+Bit Output Datatype Difference
-- SMALLMONEY + BIT
SELECT CAST(123.45 AS SMALLMONEY) + CAST(1 AS BIT) AS result;
GO

-- Subtraction (-) operator tests with SMALLMONEY
-- SMALLMONEY - MONEY
SELECT CAST(123.45 AS SMALLMONEY) - CAST(678.90 AS MONEY) AS result;
GO

-- SMALLMONEY - SMALLMONEY
SELECT CAST(123.45 AS SMALLMONEY) - CAST(678.90 AS SMALLMONEY) AS result;
GO

-- SMALLMONEY - TINYINT
SELECT CAST(123.45 AS SMALLMONEY) - CAST(255 AS TINYINT) AS result;
GO

-- SMALLMONEY - SMALLINT
SELECT CAST(123.45 AS SMALLMONEY) - CAST(32767 AS SMALLINT) AS result;
GO

-- SMALLMONEY - INT
-- TODO: File JIRA, TDS Protocol Error in case of smallmoney overflow
-- SELECT CAST(123.45 AS SMALLMONEY) - CAST(2147483647 AS INT) AS result;
-- GO

-- TODO: File Jira, SMALLMONEY-BIGINT Doesnt Follow Bound Checks
-- SMALLMONEY - BIGINT
SELECT CAST(123.45 AS SMALLMONEY) - CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- SMALLMONEY - REAL
SELECT CAST(123.45 AS SMALLMONEY) - CAST(678.90 AS REAL) AS result;
GO

-- SMALLMONEY - FLOAT
SELECT CAST(123.45 AS SMALLMONEY) - CAST(678.90 AS FLOAT) AS result;
GO

-- TODO: File JIRA, SmallMoney-NUMERIC Precision Difference
-- SMALLMONEY - NUMERIC(5,2)
SELECT CAST(123.45 AS SMALLMONEY) - CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- SMALLMONEY - NUMERIC(10,4)
SELECT CAST(123.45 AS SMALLMONEY) - CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- SMALLMONEY - NUMERIC(18,6)
SELECT CAST(123.45 AS SMALLMONEY) - CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- TODO: File JIRA, SmallMoney-Bit Output Datatype Difference
-- SMALLMONEY - BIT
SELECT CAST(123.45 AS SMALLMONEY) - CAST(1 AS BIT) AS result;
GO

-- Multiplication (*) operator tests with SMALLMONEY
-- SMALLMONEY * MONEY
SELECT CAST(123.45 AS SMALLMONEY) * CAST(678.90 AS MONEY) AS result;
GO

-- SMALLMONEY * SMALLMONEY
SELECT CAST(123.45 AS SMALLMONEY) * CAST(678.90 AS SMALLMONEY) AS result;
GO

-- SMALLMONEY * TINYINT
SELECT CAST(123.45 AS SMALLMONEY) * CAST(255 AS TINYINT) AS result;
GO

-- SMALLMONEY * SMALLINT
-- TODO: File JIRA, TDS Protocol Error in case of smallmoney overflowa
-- SELECT CAST(123.45 AS SMALLMONEY) * CAST(32767 AS SMALLINT) AS result;
-- GO

-- SMALLMONEY * INT
-- TODO: File JIRA, TDS Protocol Error in case of smallmoney overflowa
-- SELECT CAST(123.45 AS SMALLMONEY) * CAST(2147483647 AS INT) AS result;
-- GO

-- TODO: File Jira, SMALLMONEY*BIGINT Doesnt Follow Bound Checks
-- SMALLMONEY * BIGINT
SELECT CAST(123.45 AS SMALLMONEY) * CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- SMALLMONEY * REAL
SELECT CAST(123.45 AS SMALLMONEY) * CAST(678.90 AS REAL) AS result;
GO

-- SMALLMONEY * FLOAT
SELECT CAST(123.45 AS SMALLMONEY) * CAST(678.90 AS FLOAT) AS result;
GO

-- TODO: File JIRA, SmallMoney*NUMERIC Precision Difference
-- SMALLMONEY * NUMERIC(5,2)
SELECT CAST(123.45 AS SMALLMONEY) * CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- SMALLMONEY * NUMERIC(10,4)
SELECT CAST(123.45 AS SMALLMONEY) * CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- TODO: File JIRA, SmallMoney*NUMERIC Precision Difference
-- SMALLMONEY * NUMERIC(18,6)
SELECT CAST(123.45 AS SMALLMONEY) * CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- TODO: File JIRA, SmallMoney*Bit Output Datatype Difference
-- SMALLMONEY * BIT
SELECT CAST(123.45 AS SMALLMONEY) * CAST(1 AS BIT) AS result;
GO

-- Division (/) operator tests with SMALLMONEY
-- SMALLMONEY / MONEY
SELECT CAST(123.45 AS SMALLMONEY) / CAST(678.90 AS MONEY) AS result;
GO

-- SMALLMONEY / SMALLMONEY
SELECT CAST(123.45 AS SMALLMONEY) / CAST(678.90 AS SMALLMONEY) AS result;
GO

-- SMALLMONEY / TINYINT
SELECT CAST(123.45 AS SMALLMONEY) / CAST(255 AS TINYINT) AS result;
GO

-- SMALLMONEY / SMALLINT
SELECT CAST(123.45 AS SMALLMONEY) / CAST(32767 AS SMALLINT) AS result;
GO

-- TODO: File Jira, SMALLMONEY/INT Doesnt Follow Bound Checks
-- SMALLMONEY / INT
SELECT CAST(123.45 AS SMALLMONEY) / CAST(2147483647 AS INT) AS result;
GO

-- TODO: File Jira, SMALLMONEY/BIGINT Doesnt Follow Bound Checks
-- SMALLMONEY / BIGINT
SELECT CAST(123.45 AS SMALLMONEY) / CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- SMALLMONEY / REAL
SELECT CAST(123.45 AS SMALLMONEY) / CAST(678.90 AS REAL) AS result;
GO

-- SMALLMONEY / FLOAT
SELECT CAST(123.45 AS SMALLMONEY) / CAST(678.90 AS FLOAT) AS result;
GO

-- TODO: File JIRA, SmallMoney/NUMERIC Precision Difference
-- SMALLMONEY / NUMERIC(5,2)
SELECT CAST(123.45 AS SMALLMONEY) / CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- TODO: File JIRA, SmallMoney/NUMERIC Precision Difference
-- SMALLMONEY / NUMERIC(10,4)
SELECT CAST(123.45 AS SMALLMONEY) / CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- TODO: File JIRA, SmallMoney/NUMERIC Precision Difference
-- SMALLMONEY / NUMERIC(18,6)
SELECT CAST(123.45 AS SMALLMONEY) / CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- TODO: File JIRA, SmallMoney/Bit Output Datatype Difference
-- SMALLMONEY / BIT
SELECT CAST(123.45 AS SMALLMONEY) / CAST(1 AS BIT) AS result;
GO

-- Modulo (%) operator tests with SMALLMONEY
SELECT 'Modulo (%) Operator Tests with SMALLMONEY' AS test_description;
GO

-- SMALLMONEY % MONEY
SELECT CAST(123.45 AS SMALLMONEY) % CAST(678.90 AS MONEY) AS result;
GO

-- SMALLMONEY % SMALLMONEY
SELECT CAST(123.45 AS SMALLMONEY) % CAST(678.90 AS SMALLMONEY) AS result;
GO

-- SMALLMONEY % TINYINT
SELECT CAST(123.45 AS SMALLMONEY) % CAST(255 AS TINYINT) AS result;
GO

-- SMALLMONEY % SMALLINT
SELECT CAST(123.45 AS SMALLMONEY) % CAST(32767 AS SMALLINT) AS result;
GO

-- SMALLMONEY % INT
SELECT CAST(123.45 AS SMALLMONEY) % CAST(2147483647 AS INT) AS result;
GO

-- SMALLMONEY % BIGINT
SELECT CAST(123.45 AS SMALLMONEY) % CAST(9223372036854775807 AS BIGINT) AS result;
GO

-- TODO: File JIRA, SmallMoney%REAL is incompatible in T-SQL
-- SMALLMONEY % REAL
SELECT CAST(123.45 AS SMALLMONEY) % CAST(678.90 AS REAL) AS result;
GO

-- TODO: File JIRA, SmallMoney%FLOAT is incompatible in T-SQL
-- SMALLMONEY % FLOAT
SELECT CAST(123.45 AS SMALLMONEY) % CAST(678.90 AS FLOAT) AS result;
GO

-- TODO: File JIRA, SmallMoney%NUMERIC Precision Difference
-- SMALLMONEY % NUMERIC(5,2)
SELECT CAST(123.45 AS SMALLMONEY) % CAST(678.90 AS NUMERIC(5,2)) AS result;
GO

-- SMALLMONEY % NUMERIC(10,4)
SELECT CAST(123.45 AS SMALLMONEY) % CAST(678.9012 AS NUMERIC(10,4)) AS result;
GO

-- SMALLMONEY % NUMERIC(18,6)
SELECT CAST(123.45 AS SMALLMONEY) % CAST(678.901234 AS NUMERIC(18,6)) AS result;
GO

-- SMALLMONEY % BIT
SELECT CAST(123.45 AS SMALLMONEY) % CAST(1 AS BIT) AS result;
GO

-- Unary minus (-) operator tests
-- Unary Minus MONEY
SELECT -CAST(123.45 AS MONEY) AS result;
GO

-- Unary Minus SMALLMONEY
SELECT -CAST(123.45 AS SMALLMONEY) AS result;
GO

-- Complex Arithmetic Tests for MONEY
-- Multiple operators in single expression
SELECT (CAST(1234.56 AS MONEY) + CAST(789.12 AS MONEY)) * CAST(2 AS INT) / CAST(3 AS INT) AS result;
GO

-- Nested calculations
SELECT CAST(100.00 AS MONEY) + (CAST(200.00 AS MONEY) * CAST(3 AS INT)) + (CAST(400.00 AS MONEY) / CAST(2 AS INT)) AS result;
GO

-- Mixed money types calculations
SELECT (CAST(1000.00 AS MONEY) + CAST(500.00 AS SMALLMONEY)) * 
       (CAST(250.00 AS MONEY) + CAST(125.00 AS SMALLMONEY)) AS result;
GO

-- Complex percentage calculations
SELECT CAST(1000.00 AS MONEY) + 
       (CAST(1000.00 AS MONEY) * CAST(0.10 AS FLOAT)) + -- Add 10%
       (CAST(1000.00 AS MONEY) * CAST(0.05 AS FLOAT))   -- Add 5%
AS result;
GO

-- Mixed numeric type operations
SELECT (CAST(1000.00 AS MONEY) * CAST(1.5 AS FLOAT)) +
       (CAST(500.00 AS MONEY) * CAST(2.5 AS NUMERIC(5,2))) +
       (CAST(250.00 AS MONEY) / CAST(2 AS INT))
AS result;
GO

-- Nested modulo operations
SELECT (CAST(1000.00 AS MONEY) % CAST(300 AS INT)) +
       (CAST(500.00 AS MONEY) % CAST(200 AS INT)) AS result;
GO

-- Compound interest calculation
SELECT CAST(1000.00 AS MONEY) * 
       POWER(CAST(1.05 AS FLOAT), 3) -- 5% interest compounded for 3 periods
AS result;
GO

-- Tax calculation with multiple rates
SELECT CAST(1000.00 AS MONEY) +
       (CAST(1000.00 AS MONEY) * CAST(0.05 AS FLOAT)) + -- State tax 5%
       (CAST(1000.00 AS MONEY) * CAST(0.08 AS FLOAT)) + -- County tax 8%
       (CAST(1000.00 AS MONEY) * CAST(0.02 AS FLOAT))   -- Special tax 2%
AS total_with_taxes;
GO

-- Complex discount calculation
SELECT CAST(1000.00 AS MONEY) -
       (CAST(1000.00 AS MONEY) * CAST(0.20 AS FLOAT)) - -- 20% off
       (CAST(50.00 AS MONEY)) +                         -- Less $50
       (CAST(1000.00 AS MONEY) * CAST(0.05 AS FLOAT))   -- Plus 5% fee
AS final_price;
GO

-- Complex division and modulo
SELECT (CAST(1234.56 AS MONEY) / CAST(2 AS INT)) +
       (CAST(1234.56 AS MONEY) % CAST(500 AS INT)) +
       (CAST(1234.56 AS MONEY) * CAST(0.10 AS FLOAT))
AS result;
GO

-- Complex SMALLMONEY Arithmetic Tests
-- Multiple operators in single expression
SELECT (CAST(123.45 AS SMALLMONEY) + CAST(78.91 AS SMALLMONEY)) * 
       CAST(2 AS INT) / CAST(3 AS INT) AS result;
GO

-- Nested calculations
SELECT CAST(100.00 AS SMALLMONEY) + 
       (CAST(200.00 AS SMALLMONEY) * CAST(3 AS INT)) + 
       (CAST(400.00 AS SMALLMONEY) / CAST(2 AS INT)) AS result;
GO

-- Mixed money types calculations
SELECT (CAST(1000.00 AS SMALLMONEY) + CAST(500.00 AS SMALLMONEY)) * 
       (CAST(250.00 AS MONEY) + CAST(125.00 AS SMALLMONEY)) AS result;
GO

-- Complex percentage calculations with SMALLMONEY
SELECT CAST(1000.00 AS SMALLMONEY) + 
       (CAST(1000.00 AS SMALLMONEY) * CAST(0.10 AS FLOAT)) + -- Add 10%
       (CAST(1000.00 AS SMALLMONEY) * CAST(0.05 AS FLOAT))   -- Add 5%
AS result;
GO

-- Mixed numeric type operations
SELECT (CAST(1000.00 AS SMALLMONEY) * CAST(1.5 AS FLOAT)) +
       (CAST(500.00 AS SMALLMONEY) * CAST(2.5 AS NUMERIC(5,2))) +
       (CAST(250.00 AS SMALLMONEY) / CAST(2 AS INT))
AS result;
GO

-- Price adjustment calculation
SELECT CAST(100.00 AS SMALLMONEY) +
       (CAST(100.00 AS SMALLMONEY) * 
        CASE 
            WHEN CAST(100.00 AS SMALLMONEY) > CAST(50.00 AS SMALLMONEY) 
            THEN CAST(0.10 AS FLOAT)
            ELSE CAST(0.05 AS FLOAT)
        END)
AS adjusted_price;
GO

-- Multi-step calculation
SELECT (CAST(100.00 AS SMALLMONEY) * 
        CAST(1.10 AS FLOAT) +                -- Add 10%
        CAST(25.00 AS SMALLMONEY)) *        -- Add fixed amount
        CAST(0.95 AS FLOAT)                 -- Apply 5% discount
AS result;
GO

-- Weighted average price calculation
SELECT (CAST(100.00 AS SMALLMONEY) * CAST(0.7 AS FLOAT)) +
       (CAST(200.00 AS SMALLMONEY) * CAST(0.3 AS FLOAT))
AS weighted_average;
GO

-- Complex rounding test
SELECT CAST(
    (CAST(123.456 AS FLOAT) * 
     CAST(100.00 AS SMALLMONEY)) / 
     CAST(3 AS INT)
AS SMALLMONEY) AS rounded_result;
GO

-- Mathematical formula implementation
SELECT CAST(100.00 AS SMALLMONEY) * 
       POWER(CAST(1 AS FLOAT) + CAST(0.05 AS FLOAT), 4) -- Compound interest
AS future_value;
GO

-- Complex marginal calculation
SELECT CASE
    WHEN CAST(1000.00 AS SMALLMONEY) <= CAST(500.00 AS SMALLMONEY)
    THEN CAST(1000.00 AS SMALLMONEY) * CAST(1.10 AS FLOAT)
    WHEN CAST(1000.00 AS SMALLMONEY) <= CAST(1000.00 AS SMALLMONEY)
    THEN CAST(1000.00 AS SMALLMONEY) * CAST(1.20 AS FLOAT)
    ELSE CAST(1000.00 AS SMALLMONEY) * CAST(1.30 AS FLOAT)
END AS tiered_pricing;
GO

-- Mixed arithmetic with multiple data types
SELECT (CAST(100.00 AS SMALLMONEY) * CAST(1.1 AS FLOAT)) +
       (CAST(50.00 AS SMALLMONEY) / CAST(2 AS INT)) +
       (CAST(25.00 AS SMALLMONEY) * CAST(0.8 AS NUMERIC(3,1))) +
       CAST(10 AS TINYINT)
AS mixed_calculation;
GO

------------------------------------------------------------------------
---- 4. Mathematical Functions Tests
------------------------------------------------------------------------

-- ABS Function
-- MONEY tests
SELECT ABS(CAST(123.45 AS MONEY)) AS result;      -- Positive MONEY
GO
SELECT ABS(CAST(-123.45 AS MONEY)) AS result;     -- Negative MONEY
GO
SELECT ABS(CAST(0 AS MONEY)) AS result;           -- Zero MONEY
GO
SELECT ABS(CAST(922337203685477.5807 AS MONEY)) AS result;  -- Maximum MONEY value
GO
SELECT ABS(CAST(-922337203685477.5808 AS MONEY)) AS result; -- Minimum MONEY value
GO
SELECT ABS(CAST(NULL AS MONEY)) AS result;        -- NULL MONEY value
GO
SELECT ABS(CAST(-0.0001 AS MONEY)) AS result;     -- Small negative MONEY value
GO
SELECT ABS(CAST(-0.00 AS MONEY)) AS result;       -- Negative zero MONEY
GO

-- SMALLMONEY tests
SELECT ABS(CAST(123.45 AS SMALLMONEY)) AS result;      -- Positive SMALLMONEY
GO
SELECT ABS(CAST(-123.45 AS SMALLMONEY)) AS result;     -- Negative SMALLMONEY
GO
SELECT ABS(CAST(0 AS SMALLMONEY)) AS result;           -- Zero SMALLMONEY
GO
SELECT ABS(CAST(214748.3647 AS SMALLMONEY)) AS result; -- Maximum SMALLMONEY value
GO
SELECT ABS(CAST(-214748.3648 AS SMALLMONEY)) AS result; -- Minimum SMALLMONEY value
GO
SELECT ABS(CAST(NULL AS SMALLMONEY)) AS result;        -- NULL SMALLMONEY value
GO
SELECT ABS(CAST(-0.0001 AS SMALLMONEY)) AS result;     -- Small negative SMALLMONEY value
GO
SELECT ABS(CAST(-0.00 AS SMALLMONEY)) AS result;       -- Negative zero SMALLMONEY
GO

-- CEILING tests for MONEY
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(123.45 AS MONEY)) AS result;  -- Positive MONEY
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(-123.45 AS MONEY)) AS result; -- Negative MONEY
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(0 AS MONEY)) AS result;       -- Zero MONEY
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(123.00 AS MONEY)) AS result;  -- Integer value MONEY
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(NULL AS MONEY)) AS result;    -- NULL MONEY value
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(999.999 AS MONEY)) AS result; -- Value close to next integer
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(-999.001 AS MONEY)) AS result; -- Negative value close to integer
GO
-- TODO: File JIRA, Ceiling with Money Doesnt value Out of Bounds
SELECT CEILING(CAST(922337203685477.5807 AS MONEY)) AS result; -- Maximum MONEY value
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(-922337203685477.5808 AS MONEY)) AS result; -- Minimum MONEY value
GO
-- TODO: File JIRA, Ceiling with Money Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(0.0001 AS MONEY)) AS result;  -- Small positive value
GO

-- CEILING tests for SMALLMONEY
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(123.45 AS SMALLMONEY)) AS result;  -- Positive SMALLMONEY
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(-123.45 AS SMALLMONEY)) AS result; -- Negative SMALLMONEY
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(0 AS SMALLMONEY)) AS result;       -- Zero SMALLMONEY
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(123.00 AS SMALLMONEY)) AS result;  -- Integer value SMALLMONEY
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(NULL AS SMALLMONEY)) AS result;    -- NULL SMALLMONEY value
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(999.999 AS SMALLMONEY)) AS result; -- Value close to next integer
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(-999.001 AS SMALLMONEY)) AS result; -- Negative value close to integer
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(214748.3647 AS SMALLMONEY)) AS result; -- Maximum SMALLMONEY value
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(-214748.3648 AS SMALLMONEY)) AS result; -- Minimum SMALLMONEY value
GO
-- TODO: File JIRA, Ceiling with SmallMoney Precision Difference + Return Datatype Diff
SELECT CEILING(CAST(0.0001 AS SMALLMONEY)) AS result;  -- Small positive value
GO

-- FLOOR tests for MONEY
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(123.45 AS MONEY)) AS result;    -- Positive MONEY
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(-123.45 AS MONEY)) AS result;   -- Negative MONEY
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(0 AS MONEY)) AS result;         -- Zero MONEY
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(123.00 AS MONEY)) AS result;    -- Integer value MONEY
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(NULL AS MONEY)) AS result;      -- NULL MONEY value
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(999.999 AS MONEY)) AS result;   -- Value close to integer
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(-999.001 AS MONEY)) AS result;  -- Negative value close to next integer
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(922337203685477.5807 AS MONEY)) AS result; -- Maximum MONEY value
GO
-- TODO: File JIRA, Floor with Money Doesnt consider Out of Bounds
SELECT FLOOR(CAST(-922337203685477.5808 AS MONEY)) AS result; -- Minimum MONEY value
GO
-- TODO: File JIRA, Floor with Money Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(0.0001 AS MONEY)) AS result;    -- Small positive value
GO

-- FLOOR tests for SMALLMONEY
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(123.45 AS SMALLMONEY)) AS result;    -- Positive SMALLMONEY
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(-123.45 AS SMALLMONEY)) AS result;   -- Negative SMALLMONEY
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(0 AS SMALLMONEY)) AS result;         -- Zero SMALLMONEY
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(123.00 AS SMALLMONEY)) AS result;    -- Integer value SMALLMONEY
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(NULL AS SMALLMONEY)) AS result;      -- NULL SMALLMONEY value
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(999.999 AS SMALLMONEY)) AS result;   -- Value close to integer
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(-999.001 AS SMALLMONEY)) AS result;  -- Negative value close to next integer
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(214748.3647 AS SMALLMONEY)) AS result; -- Maximum SMALLMONEY value
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(-214748.3648 AS SMALLMONEY)) AS result; -- Minimum SMALLMONEY value
GO
-- TODO: File JIRA, Floor with SmallMoney Precision Difference + Return Datatype Diff
SELECT FLOOR(CAST(0.0001 AS SMALLMONEY)) AS result;    -- Small positive value
GO

-- ROUND tests for MONEY
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), 0) AS result;     -- MONEY 0 decimals
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.45 AS MONEY), 0) AS result;    -- Negative MONEY 0 decimals
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), 1) AS result;     -- MONEY 1 decimal
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.45 AS MONEY), 1) AS result;    -- Negative MONEY 1 decimal
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), 2) AS result;     -- MONEY 2 decimals
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), 3) AS result;     -- MONEY 3 decimals
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), -1) AS result;    -- MONEY negative digits (round to tens)
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), -2) AS result;    -- MONEY negative digits (round to hundreds)
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(NULL AS MONEY), 1) AS result;       -- NULL MONEY value
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.456 AS MONEY), 2) AS result;    -- Round up
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.454 AS MONEY), 2) AS result;    -- Round down
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.455 AS MONEY), 2) AS result;    -- Round half (banker's rounding)
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.456 AS MONEY), 2) AS result;   -- Negative round up
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.454 AS MONEY), 2) AS result;   -- Negative round down
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.455 AS MONEY), 2) AS result;   -- Negative round half
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), 2, 0) AS result;  -- Explicit round (default)
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS MONEY), 2, 1) AS result;  -- Explicit truncate
GO
-- TODO: File JIRA, Round with Money Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(555.55 AS MONEY), -2, 1) AS result; -- Truncate to hundreds
GO

-- ROUND tests for SMALLMONEY
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), 0) AS result;     -- SMALLMONEY 0 decimals
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.45 AS SMALLMONEY), 0) AS result;    -- Negative SMALLMONEY 0 decimals
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), 1) AS result;     -- SMALLMONEY 1 decimal
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.45 AS SMALLMONEY), 1) AS result;    -- Negative SMALLMONEY 1 decimal
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), 2) AS result;     -- SMALLMONEY 2 decimals
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), 3) AS result;     -- SMALLMONEY 3 decimals
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), -1) AS result;    -- SMALLMONEY negative digits (round to tens)
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), -2) AS result;    -- SMALLMONEY negative digits (round to hundreds)
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(NULL AS SMALLMONEY), 1) AS result;       -- NULL SMALLMONEY value
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.456 AS SMALLMONEY), 2) AS result;    -- Round up
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.454 AS SMALLMONEY), 2) AS result;    -- Round down
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.455 AS SMALLMONEY), 2) AS result;    -- Round half (banker's rounding)
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.456 AS SMALLMONEY), 2) AS result;   -- Negative round up
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.454 AS SMALLMONEY), 2) AS result;   -- Negative round down
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(-123.455 AS SMALLMONEY), 2) AS result;   -- Negative round half
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), 2, 0) AS result;  -- Explicit round (default)
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(123.45 AS SMALLMONEY), 2, 1) AS result;  -- Explicit truncate
GO
-- TODO: File JIRA, Round with SmallMoney Precision Difference + Return Datatype Diff
SELECT ROUND(CAST(555.55 AS SMALLMONEY), -2, 1) AS result; -- Truncate to hundreds
GO

-- SIGN tests for MONEY
SELECT SIGN(CAST(123.45 AS MONEY)) AS result;     -- Positive MONEY
GO
SELECT SIGN(CAST(-123.45 AS MONEY)) AS result;    -- Negative MONEY
GO
SELECT SIGN(CAST(0 AS MONEY)) AS result;          -- Zero MONEY
GO
-- TODO: File JIRA, Sign with money output difference
SELECT SIGN(CAST(NULL AS MONEY)) AS result;       -- NULL MONEY value
GO
-- TODO: File JIRA, Sign with money output difference
SELECT SIGN(CAST(922337203685477.5807 AS MONEY)) AS result;  -- Maximum MONEY value
GO
SELECT SIGN(CAST(-922337203685477.5808 AS MONEY)) AS result; -- Minimum MONEY value
GO
SELECT SIGN(CAST(0.0001 AS MONEY)) AS result;     -- Small positive value
GO
SELECT SIGN(CAST(-0.0001 AS MONEY)) AS result;    -- Small negative value
GO

-- SIGN tests for SMALLMONEY
SELECT SIGN(CAST(123.45 AS SMALLMONEY)) AS result;     -- Positive SMALLMONEY
GO
SELECT SIGN(CAST(-123.45 AS SMALLMONEY)) AS result;    -- Negative SMALLMONEY
GO
SELECT SIGN(CAST(0 AS SMALLMONEY)) AS result;          -- Zero SMALLMONEY
GO
SELECT SIGN(CAST(NULL AS SMALLMONEY)) AS result;       -- NULL SMALLMONEY value
GO
SELECT SIGN(CAST(214748.3647 AS SMALLMONEY)) AS result;  -- Maximum SMALLMONEY value
GO
SELECT SIGN(CAST(-214748.3648 AS SMALLMONEY)) AS result; -- Minimum SMALLMONEY value
GO
SELECT SIGN(CAST(0.0001 AS SMALLMONEY)) AS result;     -- Small positive value
GO
SELECT SIGN(CAST(-0.0001 AS SMALLMONEY)) AS result;    -- Small negative value
GO

-- POWER tests for MONEY
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS MONEY), 2) AS result;          -- Positive MONEY, Integer Power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS MONEY), 0.5) AS result;        -- Positive MONEY, Decimal Power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(-12.34 AS MONEY), 2) AS result;         -- Negative MONEY, Even Integer Power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(-12.34 AS MONEY), 3) AS result;         -- Negative MONEY, Odd Integer Power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(0 AS MONEY), 2) AS result;              -- Zero MONEY, Positive Power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS MONEY), 0) AS result;          -- MONEY, Zero Power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS MONEY), -2) AS result;         -- MONEY, Negative Power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(NULL AS MONEY), 2) AS result;           -- NULL MONEY base
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS MONEY), NULL) AS result;       -- NULL exponent
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(0 AS MONEY), 0) AS result;              -- Zero raised to zero power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(0 AS MONEY), -1) AS result;             -- Zero raised to negative power
GO
-- TODO: File JIRA, Power with Money Precision Difference + Return Datatype Diff
SELECT POWER(CAST(-12.34 AS MONEY), 0.5) AS result;       -- Negative base, fractional power
GO

-- POWER tests for SMALLMONEY
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS SMALLMONEY), 2) AS result;          -- Positive SMALLMONEY, Integer Power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS SMALLMONEY), 0.5) AS result;        -- Positive SMALLMONEY, Decimal Power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(-12.34 AS SMALLMONEY), 2) AS result;         -- Negative SMALLMONEY, Even Integer Power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(-12.34 AS SMALLMONEY), 3) AS result;         -- Negative SMALLMONEY, Odd Integer Power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(0 AS SMALLMONEY), 2) AS result;              -- Zero SMALLMONEY, Positive Power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS SMALLMONEY), 0) AS result;          -- SMALLMONEY, Zero Power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS SMALLMONEY), -2) AS result;         -- SMALLMONEY, Negative Power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(NULL AS SMALLMONEY), 2) AS result;           -- NULL SMALLMONEY base
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(12.34 AS SMALLMONEY), NULL) AS result;       -- NULL exponent
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(0 AS SMALLMONEY), 0) AS result;              -- Zero raised to zero power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(0 AS SMALLMONEY), -1) AS result;             -- Zero raised to negative power
GO
-- TODO: File JIRA, Power with SmallMoney Precision Difference + Return Datatype Diff
SELECT POWER(CAST(-12.34 AS SMALLMONEY), 0.5) AS result;       -- Negative base, fractional power
GO

-- SQRT tests for MONEY
SELECT SQRT(CAST(144.00 AS MONEY)) AS result;                -- Positive MONEY
GO
SELECT SQRT(CAST(0 AS MONEY)) AS result;                     -- Zero MONEY
GO
SELECT SQRT(CAST(12.25 AS MONEY)) AS result;                -- Decimal MONEY
GO
SELECT SQRT(CAST(-144.00 AS MONEY)) AS result;              -- Negative MONEY (should return NULL)
GO
SELECT SQRT(CAST(NULL AS MONEY)) AS result;                 -- NULL MONEY value
GO
SELECT SQRT(CAST(2.00 AS MONEY)) AS result;                 -- Irrational result
GO
SELECT SQRT(CAST(922337203685477.5807 AS MONEY)) AS result; -- Maximum MONEY value
GO
SELECT SQRT(CAST(0.0001 AS MONEY)) AS result;               -- Small positive value
GO

-- SQRT tests for SMALLMONEY
SELECT SQRT(CAST(144.00 AS SMALLMONEY)) AS result;          -- Positive SMALLMONEY
GO
SELECT SQRT(CAST(0 AS SMALLMONEY)) AS result;               -- Zero SMALLMONEY
GO
SELECT SQRT(CAST(12.25 AS SMALLMONEY)) AS result;          -- Decimal SMALLMONEY
GO
SELECT SQRT(CAST(-144.00 AS SMALLMONEY)) AS result;        -- Negative SMALLMONEY (should return NULL)
GO
SELECT SQRT(CAST(NULL AS SMALLMONEY)) AS result;           -- NULL SMALLMONEY value
GO
SELECT SQRT(CAST(2.00 AS SMALLMONEY)) AS result;           -- Irrational result
GO
SELECT SQRT(CAST(214748.3647 AS SMALLMONEY)) AS result;    -- Maximum SMALLMONEY value
GO
SELECT SQRT(CAST(0.0001 AS SMALLMONEY)) AS result;         -- Small positive value
GO

-- LOG tests for MONEY
SELECT LOG(CAST(100.00 AS MONEY)) AS result;              -- Positive MONEY
GO
SELECT LOG(CAST(0.5 AS MONEY)) AS result;                -- MONEY between 0 and 1
GO
SELECT LOG(CAST(0 AS MONEY)) AS result;                  -- Zero MONEY (should return error or NULL)
GO
SELECT LOG(CAST(-100.00 AS MONEY)) AS result;            -- Negative MONEY (should return error or NULL)
GO
SELECT LOG(CAST(1.00 AS MONEY)) AS result;               -- LOG of 1 (should be 0)
GO
SELECT LOG(CAST(2.718281828459045 AS MONEY)) AS result;  -- LOG of e (should be 1)
GO
SELECT LOG(CAST(NULL AS MONEY)) AS result;               -- NULL MONEY value
GO
SELECT LOG(CAST(0.0001 AS MONEY)) AS result;             -- Very small positive number
GO
SELECT LOG(CAST(922337203685477.5807 AS MONEY)) AS result; -- Maximum MONEY value
GO

-- LOG tests for SMALLMONEY
SELECT LOG(CAST(100.00 AS SMALLMONEY)) AS result;              -- Positive SMALLMONEY
GO
SELECT LOG(CAST(0.5 AS SMALLMONEY)) AS result;                -- SMALLMONEY between 0 and 1
GO
SELECT LOG(CAST(0 AS SMALLMONEY)) AS result;                  -- Zero SMALLMONEY (should return error or NULL)
GO
SELECT LOG(CAST(-100.00 AS SMALLMONEY)) AS result;            -- Negative SMALLMONEY (should return error or NULL)
GO
SELECT LOG(CAST(1.00 AS SMALLMONEY)) AS result;               -- LOG of 1 (should be 0)
GO
SELECT LOG(CAST(2.718281828459045 AS SMALLMONEY)) AS result;  -- LOG of e (should be 1)
GO
SELECT LOG(CAST(NULL AS SMALLMONEY)) AS result;               -- NULL SMALLMONEY value
GO
SELECT LOG(CAST(0.0001 AS SMALLMONEY)) AS result;             -- Very small positive number
GO
SELECT LOG(CAST(214748.3647 AS SMALLMONEY)) AS result;        -- Maximum SMALLMONEY value
GO

-- LOG10 tests for MONEY
SELECT LOG10(CAST(100.00 AS MONEY)) AS result;               -- Positive MONEY
GO
SELECT LOG10(CAST(0.5 AS MONEY)) AS result;                 -- MONEY between 0 and 1
GO
SELECT LOG10(CAST(0 AS MONEY)) AS result;                   -- Zero MONEY (should return error or NULL)
GO
SELECT LOG10(CAST(-100.00 AS MONEY)) AS result;             -- Negative MONEY (should return error or NULL)
GO
SELECT LOG10(CAST(1.00 AS MONEY)) AS result;                -- LOG10 of 1 (should be 0)
GO
SELECT LOG10(CAST(10.00 AS MONEY)) AS result;               -- LOG10 of 10 (should be 1)
GO
SELECT LOG10(CAST(NULL AS MONEY)) AS result;                -- NULL MONEY value
GO
SELECT LOG10(CAST(0.0001 AS MONEY)) AS result;              -- Very small positive number
GO
SELECT LOG10(CAST(922337203685477.5807 AS MONEY)) AS result; -- Maximum MONEY value
GO

-- LOG10 tests for SMALLMONEY
SELECT LOG10(CAST(100.00 AS SMALLMONEY)) AS result;         -- Positive SMALLMONEY
GO
SELECT LOG10(CAST(0.5 AS SMALLMONEY)) AS result;           -- SMALLMONEY between 0 and 1
GO
SELECT LOG10(CAST(0 AS SMALLMONEY)) AS result;             -- Zero SMALLMONEY (should return error or NULL)
GO
SELECT LOG10(CAST(-100.00 AS SMALLMONEY)) AS result;       -- Negative SMALLMONEY (should return error or NULL)
GO
SELECT LOG10(CAST(1.00 AS SMALLMONEY)) AS result;          -- LOG10 of 1 (should be 0)
GO
SELECT LOG10(CAST(10.00 AS SMALLMONEY)) AS result;         -- LOG10 of 10 (should be 1)
GO
SELECT LOG10(CAST(NULL AS SMALLMONEY)) AS result;          -- NULL SMALLMONEY value
GO
SELECT LOG10(CAST(0.0001 AS SMALLMONEY)) AS result;        -- Very small positive number
GO
SELECT LOG10(CAST(214748.3647 AS SMALLMONEY)) AS result;   -- Maximum SMALLMONEY value
GO

-- EXP tests for MONEY
SELECT EXP(CAST(1.00 AS MONEY)) AS result;                   -- Positive MONEY
GO
SELECT EXP(CAST(-1.00 AS MONEY)) AS result;                  -- Negative MONEY
GO
SELECT EXP(CAST(0 AS MONEY)) AS result;                      -- Zero MONEY
GO
SELECT TRY_CAST(EXP(CAST(1000.00 AS MONEY)) AS FLOAT) AS result;  -- Large value causing overflow
GO
SELECT EXP(CAST(NULL AS MONEY)) AS result;                   -- NULL MONEY value
GO
SELECT EXP(CAST(0.5 AS MONEY)) AS result;                    -- Fractional value
GO
SELECT EXP(CAST(-0.5 AS MONEY)) AS result;                   -- Negative fractional value
GO
SELECT EXP(CAST(10.00 AS MONEY)) AS result;                  -- Larger positive value
GO
SELECT EXP(CAST(-10.00 AS MONEY)) AS result;                 -- Larger negative value
GO

-- EXP tests for SMALLMONEY
SELECT EXP(CAST(1.00 AS SMALLMONEY)) AS result;             -- Positive SMALLMONEY
GO
SELECT EXP(CAST(-1.00 AS SMALLMONEY)) AS result;            -- Negative SMALLMONEY
GO
SELECT EXP(CAST(0 AS SMALLMONEY)) AS result;                -- Zero SMALLMONEY
GO
SELECT TRY_CAST(EXP(CAST(1000.00 AS SMALLMONEY)) AS FLOAT) AS result;  -- Large value causing overflow
GO
SELECT EXP(CAST(NULL AS SMALLMONEY)) AS result;             -- NULL SMALLMONEY value
GO
SELECT EXP(CAST(0.5 AS SMALLMONEY)) AS result;              -- Fractional value
GO
SELECT EXP(CAST(-0.5 AS SMALLMONEY)) AS result;             -- Negative fractional value
GO
SELECT EXP(CAST(10.00 AS SMALLMONEY)) AS result;            -- Larger positive value
GO
SELECT EXP(CAST(-10.00 AS SMALLMONEY)) AS result;           -- Larger negative value
GO

-- SIN tests for MONEY
SELECT SIN(CAST(1.0 AS MONEY)) AS result;                 -- MONEY
GO
SELECT SIN(CAST(0 AS MONEY)) AS result;                   -- Zero
GO
SELECT SIN(CAST(PI() AS MONEY)) AS result;                -- PI
GO
SELECT SIN(CAST(PI()/2 AS MONEY)) AS result;              -- PI/2 (90 degrees)
GO
SELECT SIN(CAST(PI()/6 AS MONEY)) AS result;              -- PI/6 (30 degrees)
GO
SELECT SIN(CAST(NULL AS MONEY)) AS result;                -- NULL value
GO
SELECT SIN(CAST(-PI()/2 AS MONEY)) AS result;             -- -PI/2 (-90 degrees)
GO
SELECT SIN(CAST(2*PI() AS MONEY)) AS result;              -- 2*PI (360 degrees)
GO
SELECT SIN(CAST(100.00 AS MONEY)) AS result;              -- Large value
GO

-- SIN tests for SMALLMONEY
SELECT SIN(CAST(1.0 AS SMALLMONEY)) AS result;                 -- SMALLMONEY
GO
SELECT SIN(CAST(0 AS SMALLMONEY)) AS result;                   -- Zero
GO
SELECT SIN(CAST(PI() AS SMALLMONEY)) AS result;                -- PI
GO
SELECT SIN(CAST(PI()/2 AS SMALLMONEY)) AS result;              -- PI/2 (90 degrees)
GO
SELECT SIN(CAST(PI()/6 AS SMALLMONEY)) AS result;              -- PI/6 (30 degrees)
GO
SELECT SIN(CAST(NULL AS SMALLMONEY)) AS result;                -- NULL value
GO
SELECT SIN(CAST(-PI()/2 AS SMALLMONEY)) AS result;             -- -PI/2 (-90 degrees)
GO
SELECT SIN(CAST(2*PI() AS SMALLMONEY)) AS result;              -- 2*PI (360 degrees)
GO
SELECT SIN(CAST(100.00 AS SMALLMONEY)) AS result;              -- Large value
GO

-- COS tests for MONEY
-- TODO: File JIRA, Cos with Money Output Diff
SELECT COS(CAST(1.0 AS MONEY)) AS result;                 -- MONEY
GO
SELECT COS(CAST(0 AS MONEY)) AS result;                   -- Zero
GO
SELECT COS(CAST(PI() AS MONEY)) AS result;                -- PI
GO
SELECT COS(CAST(PI()/2 AS MONEY)) AS result;              -- PI/2 (90 degrees)
GO
SELECT COS(CAST(PI()/3 AS MONEY)) AS result;              -- PI/3 (60 degrees)
GO
SELECT COS(CAST(NULL AS MONEY)) AS result;                -- NULL value
GO
SELECT COS(CAST(-PI() AS MONEY)) AS result;               -- -PI (-180 degrees)
GO
SELECT COS(CAST(2*PI() AS MONEY)) AS result;              -- 2*PI (360 degrees)
GO
SELECT COS(CAST(100.00 AS MONEY)) AS result;              -- Large value
GO

-- COS tests for SMALLMONEY
-- TODO: File JIRA, Cos with SmallMoney Output Diff
SELECT COS(CAST(1.0 AS SMALLMONEY)) AS result;                 -- SMALLMONEY
GO
SELECT COS(CAST(0 AS SMALLMONEY)) AS result;                   -- Zero
GO
SELECT COS(CAST(PI() AS SMALLMONEY)) AS result;                -- PI
GO
SELECT COS(CAST(PI()/2 AS SMALLMONEY)) AS result;              -- PI/2 (90 degrees)
GO
SELECT COS(CAST(PI()/3 AS SMALLMONEY)) AS result;              -- PI/3 (60 degrees)
GO
SELECT COS(CAST(NULL AS SMALLMONEY)) AS result;                -- NULL value
GO
SELECT COS(CAST(-PI() AS SMALLMONEY)) AS result;               -- -PI (-180 degrees)
GO
SELECT COS(CAST(2*PI() AS SMALLMONEY)) AS result;              -- 2*PI (360 degrees)
GO
SELECT COS(CAST(100.00 AS SMALLMONEY)) AS result;              -- Large value
GO

-- TAN tests for MONEY
SELECT TAN(CAST(1.0 AS MONEY)) AS result;                 -- MONEY
GO
SELECT TAN(CAST(0 AS MONEY)) AS result;                   -- Zero
GO
SELECT TAN(CAST(PI()/4 AS MONEY)) AS result;              -- PI/4 (45 degrees)
GO
SELECT TAN(CAST(PI() AS MONEY)) AS result;                -- PI (180 degrees)
GO
SELECT TAN(CAST(NULL AS MONEY)) AS result;                -- NULL value
GO
SELECT TAN(CAST(-PI()/4 AS MONEY)) AS result;             -- -PI/4 (-45 degrees)
GO
SELECT TAN(CAST(PI()/2 - 0.000001 AS MONEY)) AS result;   -- Near PI/2 (near 90 degrees)
GO
SELECT TAN(CAST(3*PI()/2 - 0.000001 AS MONEY)) AS result; -- Near 3*PI/2 (near 270 degrees)
GO

-- TAN tests for SMALLMONEY
SELECT TAN(CAST(1.0 AS SMALLMONEY)) AS result;                 -- SMALLMONEY
GO
SELECT TAN(CAST(0 AS SMALLMONEY)) AS result;                   -- Zero
GO
SELECT TAN(CAST(PI()/4 AS SMALLMONEY)) AS result;              -- PI/4 (45 degrees)
GO
SELECT TAN(CAST(PI() AS SMALLMONEY)) AS result;                -- PI (180 degrees)
GO
SELECT TAN(CAST(NULL AS SMALLMONEY)) AS result;                -- NULL value
GO
SELECT TAN(CAST(-PI()/4 AS SMALLMONEY)) AS result;             -- -PI/4 (-45 degrees)
GO
SELECT TAN(CAST(PI()/2 - 0.000001 AS SMALLMONEY)) AS result;   -- Near PI/2 (near 90 degrees)
GO
SELECT TAN(CAST(3*PI()/2 - 0.000001 AS SMALLMONEY)) AS result; -- Near 3*PI/2 (near 270 degrees)
GO

-- ASIN tests for MONEY
SELECT ASIN(CAST(0.5 AS MONEY)) AS result;                -- MONEY
GO
SELECT ASIN(CAST(0 AS MONEY)) AS result;                  -- Zero
GO
SELECT ASIN(CAST(1 AS MONEY)) AS result;                  -- One
GO
SELECT ASIN(CAST(-1 AS MONEY)) AS result;                 -- Negative one
GO
SELECT ASIN(CAST(2 AS MONEY)) AS result;                  -- Out of range (should return NULL)
GO
SELECT ASIN(CAST(-2 AS MONEY)) AS result;                 -- Out of range negative (should return NULL)
GO
SELECT ASIN(CAST(NULL AS MONEY)) AS result;               -- NULL value
GO
SELECT ASIN(CAST(0.7071067811865475 AS MONEY)) AS result; -- sin(PI/4)
GO
SELECT ASIN(CAST(0.8660254037844386 AS MONEY)) AS result; -- sin(PI/3)
GO

-- ASIN tests for SMALLMONEY
SELECT ASIN(CAST(0.5 AS SMALLMONEY)) AS result;                -- SMALLMONEY
GO
SELECT ASIN(CAST(0 AS SMALLMONEY)) AS result;                  -- Zero
GO
SELECT ASIN(CAST(1 AS SMALLMONEY)) AS result;                  -- One
GO
SELECT ASIN(CAST(-1 AS SMALLMONEY)) AS result;                 -- Negative one
GO
SELECT ASIN(CAST(2 AS SMALLMONEY)) AS result;                  -- Out of range (should return NULL)
GO
SELECT ASIN(CAST(-2 AS SMALLMONEY)) AS result;                 -- Out of range negative (should return NULL)
GO
SELECT ASIN(CAST(NULL AS SMALLMONEY)) AS result;               -- NULL value
GO
SELECT ASIN(CAST(0.7071067811865475 AS SMALLMONEY)) AS result; -- sin(PI/4)
GO
SELECT ASIN(CAST(0.8660254037844386 AS SMALLMONEY)) AS result; -- sin(PI/3)
GO

-- ACOS tests for MONEY
SELECT ACOS(CAST(0.5 AS MONEY)) AS result;                -- MONEY
GO
SELECT ACOS(CAST(0 AS MONEY)) AS result;                  -- Zero
GO
SELECT ACOS(CAST(1 AS MONEY)) AS result;                  -- One
GO
SELECT ACOS(CAST(-1 AS MONEY)) AS result;                 -- Negative one
GO
SELECT ACOS(CAST(2 AS MONEY)) AS result;                  -- Out of range (should return NULL)
GO
SELECT ACOS(CAST(-2 AS MONEY)) AS result;                 -- Out of range negative (should return NULL)
GO
SELECT ACOS(CAST(NULL AS MONEY)) AS result;               -- NULL value
GO
SELECT ACOS(CAST(0.7071067811865475 AS MONEY)) AS result; -- cos(PI/4)
GO
SELECT ACOS(CAST(0.5 AS MONEY)) AS result;                -- cos(PI/3)
GO

-- ACOS tests for SMALLMONEY
SELECT ACOS(CAST(0.5 AS SMALLMONEY)) AS result;                -- SMALLMONEY
GO
SELECT ACOS(CAST(0 AS SMALLMONEY)) AS result;                  -- Zero
GO
SELECT ACOS(CAST(1 AS SMALLMONEY)) AS result;                  -- One
GO
SELECT ACOS(CAST(-1 AS SMALLMONEY)) AS result;                 -- Negative one
GO
SELECT ACOS(CAST(2 AS SMALLMONEY)) AS result;                  -- Out of range (should return NULL)
GO
SELECT ACOS(CAST(-2 AS SMALLMONEY)) AS result;                 -- Out of range negative (should return NULL)
GO
SELECT ACOS(CAST(NULL AS SMALLMONEY)) AS result;               -- NULL value
GO
SELECT ACOS(CAST(0.7071067811865475 AS SMALLMONEY)) AS result; -- cos(PI/4)
GO
SELECT ACOS(CAST(0.5 AS SMALLMONEY)) AS result;                -- cos(PI/3)
GO

-- ATAN tests for MONEY
SELECT ATAN(CAST(1.0 AS MONEY)) AS result;                -- MONEY
GO
SELECT ATAN(CAST(0 AS MONEY)) AS result;                  -- Zero
GO
SELECT ATAN(CAST(1000000 AS MONEY)) AS result;            -- Large value
GO
SELECT ATAN(CAST(-1.0 AS MONEY)) AS result;               -- Negative value
GO
SELECT ATAN(CAST(NULL AS MONEY)) AS result;               -- NULL value
GO
SELECT ATAN(CAST(1.7320508075688772 AS MONEY)) AS result; -- tan(PI/3)
GO
SELECT ATAN(CAST(-1.7320508075688772 AS MONEY)) AS result; -- tan(-PI/3)
GO
SELECT ATAN(CAST(922337203685477.5807 AS MONEY)) AS result; -- Maximum MONEY value (approaches PI/2)
GO
SELECT ATAN(CAST(-922337203685477.5808 AS MONEY)) AS result; -- Minimum MONEY value (approaches -PI/2)
GO

-- ATAN tests for SMALLMONEY
SELECT ATAN(CAST(1.0 AS SMALLMONEY)) AS result;                -- SMALLMONEY
GO
SELECT ATAN(CAST(0 AS SMALLMONEY)) AS result;                  -- Zero
GO
SELECT ATAN(CAST(214748.3647 AS SMALLMONEY)) AS result;        -- Large value
GO
SELECT ATAN(CAST(-1.0 AS SMALLMONEY)) AS result;               -- Negative value
GO
SELECT ATAN(CAST(NULL AS SMALLMONEY)) AS result;               -- NULL value
GO
SELECT ATAN(CAST(1.7320508075688772 AS SMALLMONEY)) AS result; -- tan(PI/3)
GO
SELECT ATAN(CAST(-1.7320508075688772 AS SMALLMONEY)) AS result; -- tan(-PI/3)
GO
SELECT ATAN(CAST(214748.3647 AS SMALLMONEY)) AS result;         -- Maximum SMALLMONEY value (approaches PI/2)
GO
SELECT ATAN(CAST(-214748.3648 AS SMALLMONEY)) AS result;        -- Minimum SMALLMONEY value (approaches -PI/2)
GO

-- DEGREES tests for MONEY
-- TODO: File JIRA, Degress with Money Precision Diff + Return Datatype
SELECT DEGREES(CAST(PI() AS MONEY)) AS result;            -- Convert radians to degrees (PI)
GO
-- TODO: File JIRA, Degress with Money Precision Diff + Return Datatype
SELECT DEGREES(CAST(PI()/2 AS MONEY)) AS result;          -- Convert radians to degrees (PI/2)
GO
-- TODO: File JIRA, Degress with Money Precision Diff + Return Datatype
SELECT DEGREES(CAST(PI()/4 AS MONEY)) AS result;          -- Convert radians to degrees (PI/4)
GO
-- TODO: File JIRA, Degress with Money Precision Diff + Return Datatype
SELECT DEGREES(CAST(2*PI() AS MONEY)) AS result;          -- Convert radians to degrees (2*PI)
GO
-- TODO: File JIRA, Degress with Money Precision Diff + Return Datatype
SELECT DEGREES(CAST(0 AS MONEY)) AS result;               -- Convert radians to degrees (0)
GO
-- TODO: File JIRA, Degress with Money Precision Diff + Return Datatype
SELECT DEGREES(CAST(NULL AS MONEY)) AS result;            -- NULL value
GO
-- TODO: File JIRA, Degress with Money Precision Diff + Return Datatype
SELECT DEGREES(CAST(-PI() AS MONEY)) AS result;           -- Negative angle
GO

-- DEGREES tests for SMALLMONEY
-- TODO: File JIRA, Degress with SmallMoney Precision Diff + Return Datatype
SELECT DEGREES(CAST(PI() AS SMALLMONEY)) AS result;            -- Convert radians to degrees (PI)
GO
-- TODO: File JIRA, Degress with SmallMoney Precision Diff + Return Datatype
SELECT DEGREES(CAST(PI()/2 AS SMALLMONEY)) AS result;          -- Convert radians to degrees (PI/2)
GO
-- TODO: File JIRA, Degress with SmallMoney Precision Diff + Return Datatype
SELECT DEGREES(CAST(PI()/4 AS SMALLMONEY)) AS result;          -- Convert radians to degrees (PI/4)
GO
-- TODO: File JIRA, Degress with SmallMoney Precision Diff + Return Datatype
SELECT DEGREES(CAST(2*PI() AS SMALLMONEY)) AS result;          -- Convert radians to degrees (2*PI)
GO
-- TODO: File JIRA, Degress with SmallMoney Precision Diff + Return Datatype
SELECT DEGREES(CAST(0 AS SMALLMONEY)) AS result;               -- Convert radians to degrees (0)
GO
-- TODO: File JIRA, Degress with SmallMoney Precision Diff + Return Datatype
SELECT DEGREES(CAST(NULL AS SMALLMONEY)) AS result;            -- NULL value
GO
-- TODO: File JIRA, Degress with SmallMoney Precision Diff + Return Datatype
SELECT DEGREES(CAST(-PI() AS SMALLMONEY)) AS result;           -- Negative angle
GO

-- RADIANS tests for MONEY
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(180.00 AS MONEY)) AS result;             -- Convert degrees to radians (180)
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(90.00 AS MONEY)) AS result;              -- Convert degrees to radians (90)
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(45.00 AS MONEY)) AS result;              -- Convert degrees to radians (45)
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(360.00 AS MONEY)) AS result;             -- Convert degrees to radians (360)
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(0 AS MONEY)) AS result;                  -- Convert degrees to radians (0)
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(NULL AS MONEY)) AS result;               -- NULL value
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(-180.00 AS MONEY)) AS result;            -- Negative angle
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(922337203685477.5807 AS MONEY)) AS result; -- Maximum MONEY value
GO
-- TODO: File JIRA, Radians with Money Precision Diff + Return Datatype
SELECT RADIANS(CAST(-922337203685477.5808 AS MONEY)) AS result; -- Minimum MONEY value
GO

-- RADIANS tests for SMALLMONEY
-- TODO: File JIRA, Radians with SmallMoney Precision Diff + Return Datatype
SELECT RADIANS(CAST(180.00 AS SMALLMONEY)) AS result;             -- Convert degrees to radians (180)
GO
SELECT RADIANS(CAST(90.00 AS SMALLMONEY)) AS result;              -- Convert degrees to radians (90)
GO
SELECT RADIANS(CAST(45.00 AS SMALLMONEY)) AS result;              -- Convert degrees to radians (45)
GO
SELECT RADIANS(CAST(360.00 AS SMALLMONEY)) AS result;             -- Convert degrees to radians (360)
GO
SELECT RADIANS(CAST(0 AS SMALLMONEY)) AS result;                  -- Convert degrees to radians (0)
GO
SELECT RADIANS(CAST(NULL AS SMALLMONEY)) AS result;               -- NULL value
GO
SELECT RADIANS(CAST(-180.00 AS SMALLMONEY)) AS result;            -- Negative angle
GO
SELECT RADIANS(CAST(214748.3647 AS SMALLMONEY)) AS result;        -- Maximum SMALLMONEY value
GO
SELECT RADIANS(CAST(-214748.3648 AS SMALLMONEY)) AS result;       -- Minimum SMALLMONEY value
GO

------------------------------------------------------------------------
---- 5. Comparison Operators
------------------------------------------------------------------------
-- Equality (=) operator tests
-- MONEY = MONEY
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123.45 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = MONEY];
GO
SELECT CASE WHEN CAST(922337203685477.5807 AS MONEY) = CAST(922337203685477.5807 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MAX MONEY = MAX MONEY];
GO
SELECT CASE WHEN CAST(-922337203685477.5808 AS MONEY) = CAST(-922337203685477.5808 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MIN MONEY = MIN MONEY];
GO
SELECT CASE WHEN CAST(0.0000 AS MONEY) = CAST(0.0000 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [ZERO MONEY = ZERO MONEY];
GO
SELECT CASE WHEN CAST(-123.45 AS MONEY) = CAST(-123.45 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [NEG MONEY = NEG MONEY];
GO

-- SMALLMONEY = SMALLMONEY
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) = CAST(123.45 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [SMALLMONEY = SMALLMONEY];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) = CAST(214748.3647 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MAX SMALLMONEY = MAX SMALLMONEY];
GO
SELECT CASE WHEN CAST(-214748.3648 AS SMALLMONEY) = CAST(-214748.3648 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MIN SMALLMONEY = MIN SMALLMONEY];
GO
SELECT CASE WHEN CAST(0.0000 AS SMALLMONEY) = CAST(0.0000 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [ZERO SMALLMONEY = ZERO SMALLMONEY];
GO
SELECT CASE WHEN CAST(-123.45 AS SMALLMONEY) = CAST(-123.45 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [NEG SMALLMONEY = NEG SMALLMONEY];
GO



-- Cross money-type comparisons
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123.45 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = SMALLMONEY];
GO

-- Money types with other numeric types
SELECT CASE WHEN CAST(123.45 AS MONEY) = 123.45 THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = Literal];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123.45 AS FLOAT) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = FLOAT];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123.45 AS REAL) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = REAL];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123.45 AS NUMERIC(5,2)) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = NUMERIC];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123 AS INT) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = INT];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123 AS BIGINT) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = BIGINT];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123 AS SMALLINT) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = SMALLINT];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(123 AS TINYINT) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = TINYINT];
GO

-- Money types with string types
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST('123.45' AS VARCHAR(20)) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = VARCHAR];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST('123.45' AS CHAR(20)) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = CHAR];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST('123.45' AS NVARCHAR(20)) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = NVARCHAR];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST('123.45' AS NCHAR(20)) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = NCHAR];
GO

-- Money types with SQL_VARIANT
SELECT CASE WHEN CAST(123.45 AS MONEY) = CAST(CAST(123.45 AS MONEY) AS SQL_VARIANT) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY = SQL_VARIANT];
GO
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) = CAST(CAST(123.45 AS SMALLMONEY) AS SQL_VARIANT) THEN 'Equal' ELSE 'Not Equal' END AS [SMALLMONEY = SQL_VARIANT];
GO

-- Inequality (<>) operator tests
-- MONEY <> MONEY
SELECT CASE WHEN CAST(123.45 AS MONEY) <> CAST(123.46 AS MONEY) THEN 'Not Equal' ELSE 'Equal' END AS [MONEY <> MONEY];
GO
SELECT CASE WHEN CAST(922337203685477.5807 AS MONEY) <> CAST(922337203685477.5806 AS MONEY) THEN 'Not Equal' ELSE 'Equal' END AS [MAX MONEY <> NEAR MAX];
GO
SELECT CASE WHEN CAST(-922337203685477.5808 AS MONEY) <> CAST(-922337203685477.5807 AS MONEY) THEN 'Not Equal' ELSE 'Equal' END AS [MIN MONEY <> NEAR MIN];
GO

-- SMALLMONEY <> SMALLMONEY
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) <> CAST(123.46 AS SMALLMONEY) THEN 'Not Equal' ELSE 'Equal' END AS [SMALLMONEY <> SMALLMONEY];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) <> CAST(214748.3646 AS SMALLMONEY) THEN 'Not Equal' ELSE 'Equal' END AS [MAX SMALLMONEY <> NEAR MAX];
GO
SELECT CASE WHEN CAST(-214748.3648 AS SMALLMONEY) <> CAST(-214748.3647 AS SMALLMONEY) THEN 'Not Equal' ELSE 'Equal' END AS [MIN SMALLMONEY <> NEAR MIN];
GO

-- Cross money-type inequalities
SELECT CASE WHEN CAST(123.45 AS MONEY) <> CAST(123.46 AS SMALLMONEY) THEN 'Not Equal' ELSE 'Equal' END AS [MONEY <> SMALLMONEY];
GO

-- Greater than (>) operator tests

-- MONEY > MONEY
SELECT CASE WHEN CAST(123.46 AS MONEY) > CAST(123.45 AS MONEY) THEN 'Greater' ELSE 'Not Greater' END AS [MONEY > MONEY];
GO
SELECT CASE WHEN CAST(922337203685477.5807 AS MONEY) > CAST(922337203685477.5806 AS MONEY) THEN 'Greater' ELSE 'Not Greater' END AS [MAX MONEY > NEAR MAX];
GO
SELECT CASE WHEN CAST(-922337203685477.5807 AS MONEY) > CAST(-922337203685477.5808 AS MONEY) THEN 'Greater' ELSE 'Not Greater' END AS [NEAR MIN > MIN MONEY];
GO

-- SMALLMONEY > SMALLMONEY
SELECT CASE WHEN CAST(123.46 AS SMALLMONEY) > CAST(123.45 AS SMALLMONEY) THEN 'Greater' ELSE 'Not Greater' END AS [SMALLMONEY > SMALLMONEY];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) > CAST(214748.3646 AS SMALLMONEY) THEN 'Greater' ELSE 'Not Greater' END AS [MAX SMALLMONEY > NEAR MAX];
GO
SELECT CASE WHEN CAST(-214748.3647 AS SMALLMONEY) > CAST(-214748.3648 AS SMALLMONEY) THEN 'Greater' ELSE 'Not Greater' END AS [NEAR MIN > MIN SMALLMONEY];
GO

-- Cross money-type greater than
SELECT CASE WHEN CAST(123.46 AS MONEY) > CAST(123.45 AS SMALLMONEY) THEN 'Greater' ELSE 'Not Greater' END AS [MONEY > SMALLMONEY];
GO

-- Money types greater than other numeric types
SELECT CASE WHEN CAST(123.46 AS MONEY) > 123.45 THEN 'Greater' ELSE 'Not Greater' END AS [MONEY > Literal];
GO
SELECT CASE WHEN CAST(123.46 AS MONEY) > CAST(123.45 AS FLOAT) THEN 'Greater' ELSE 'Not Greater' END AS [MONEY > FLOAT];
GO
SELECT CASE WHEN CAST(123.46 AS MONEY) > CAST(123.45 AS REAL) THEN 'Greater' ELSE 'Not Greater' END AS [MONEY > REAL];
GO
SELECT CASE WHEN CAST(123.46 AS MONEY) > CAST(123.45 AS NUMERIC(5,2)) THEN 'Greater' ELSE 'Not Greater' END AS [MONEY > NUMERIC];
GO
SELECT CASE WHEN CAST(123.46 AS MONEY) > CAST(123 AS INT) THEN 'Greater' ELSE 'Not Greater' END AS [MONEY > INT];
GO

-- Less than (<) operator tests
SELECT 'Less Than (<) Operator Tests' AS test_description;
GO

-- MONEY < MONEY
SELECT CASE WHEN CAST(123.45 AS MONEY) < CAST(123.46 AS MONEY) THEN 'Less' ELSE 'Not Less' END AS [MONEY < MONEY];
GO
SELECT CASE WHEN CAST(922337203685477.5806 AS MONEY) < CAST(922337203685477.5807 AS MONEY) THEN 'Less' ELSE 'Not Less' END AS [NEAR MAX < MAX MONEY];
GO
SELECT CASE WHEN CAST(-922337203685477.5808 AS MONEY) < CAST(-922337203685477.5807 AS MONEY) THEN 'Less' ELSE 'Not Less' END AS [MIN MONEY < NEAR MIN];
GO

-- SMALLMONEY < SMALLMONEY
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) < CAST(123.46 AS SMALLMONEY) THEN 'Less' ELSE 'Not Less' END AS [SMALLMONEY < SMALLMONEY];
GO
SELECT CASE WHEN CAST(214748.3646 AS SMALLMONEY) < CAST(214748.3647 AS SMALLMONEY) THEN 'Less' ELSE 'Not Less' END AS [NEAR MAX < MAX SMALLMONEY];
GO
SELECT CASE WHEN CAST(-214748.3648 AS SMALLMONEY) < CAST(-214748.3647 AS SMALLMONEY) THEN 'Less' ELSE 'Not Less' END AS [MIN SMALLMONEY < NEAR MIN];
GO

-- Cross money-type less than
SELECT CASE WHEN CAST(123.45 AS MONEY) < CAST(123.46 AS SMALLMONEY) THEN 'Less' ELSE 'Not Less' END AS [MONEY < SMALLMONEY];
GO

-- Money types less than other numeric types
SELECT CASE WHEN CAST(123.45 AS MONEY) < 123.46 THEN 'Less' ELSE 'Not Less' END AS [MONEY < Literal];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) < CAST(123.46 AS FLOAT) THEN 'Less' ELSE 'Not Less' END AS [MONEY < FLOAT];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) < CAST(123.46 AS REAL) THEN 'Less' ELSE 'Not Less' END AS [MONEY < REAL];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) < CAST(123.46 AS NUMERIC(5,2)) THEN 'Less' ELSE 'Not Less' END AS [MONEY < NUMERIC];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) < CAST(124 AS INT) THEN 'Less' ELSE 'Not Less' END AS [MONEY < INT];
GO

-- Greater than or equal to (>=) operator tests
-- MONEY >= MONEY
SELECT CASE WHEN CAST(123.45 AS MONEY) >= CAST(123.45 AS MONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [MONEY >= MONEY (Equal)];
GO
SELECT CASE WHEN CAST(123.46 AS MONEY) >= CAST(123.45 AS MONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [MONEY >= MONEY (Greater)];
GO
SELECT CASE WHEN CAST(922337203685477.5807 AS MONEY) >= CAST(922337203685477.5807 AS MONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [MAX MONEY >= MAX MONEY];
GO

-- SMALLMONEY >= SMALLMONEY
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) >= CAST(123.45 AS SMALLMONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [SMALLMONEY >= SMALLMONEY (Equal)];
GO
SELECT CASE WHEN CAST(123.46 AS SMALLMONEY) >= CAST(123.45 AS SMALLMONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [SMALLMONEY >= SMALLMONEY (Greater)];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) >= CAST(214748.3647 AS SMALLMONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [MAX SMALLMONEY >= MAX SMALLMONEY];
GO

-- Cross money-type greater than or equal
SELECT CASE WHEN CAST(123.45 AS MONEY) >= CAST(123.45 AS SMALLMONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [MONEY >= SMALLMONEY (Equal)];
GO
SELECT CASE WHEN CAST(123.46 AS MONEY) >= CAST(123.45 AS SMALLMONEY) THEN 'Greater or Equal' ELSE 'Less' END AS [MONEY >= SMALLMONEY (Greater)];
GO

-- Less than or equal to (<=) operator tests
-- MONEY <= MONEY
SELECT CASE WHEN CAST(123.45 AS MONEY) <= CAST(123.45 AS MONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [MONEY <= MONEY (Equal)];
GO
SELECT CASE WHEN CAST(123.45 AS MONEY) <= CAST(123.46 AS MONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [MONEY <= MONEY (Less)];
GO
SELECT CASE WHEN CAST(922337203685477.5807 AS MONEY) <= CAST(922337203685477.5807 AS MONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [MAX MONEY <= MAX MONEY];
GO
SELECT CASE WHEN CAST(-922337203685477.5808 AS MONEY) <= CAST(-922337203685477.5808 AS MONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [MIN MONEY <= MIN MONEY];
GO

-- SMALLMONEY <= SMALLMONEY
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) <= CAST(123.45 AS SMALLMONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [SMALLMONEY <= SMALLMONEY (Equal)];
GO
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) <= CAST(123.46 AS SMALLMONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [SMALLMONEY <= SMALLMONEY (Less)];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) <= CAST(214748.3647 AS SMALLMONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [MAX SMALLMONEY <= MAX SMALLMONEY];
GO
SELECT CASE WHEN CAST(-214748.3648 AS SMALLMONEY) <= CAST(-214748.3648 AS SMALLMONEY) THEN 'Less or Equal' ELSE 'Greater' END AS [MIN SMALLMONEY <= MIN SMALLMONEY];
GO

-- BETWEEN operator tests
-- MONEY BETWEEN
SELECT CASE WHEN CAST(123.45 AS MONEY) BETWEEN CAST(123.44 AS MONEY) AND CAST(123.46 AS MONEY) 
            THEN 'In Range' ELSE 'Not In Range' END AS [MONEY BETWEEN];
GO
SELECT CASE WHEN CAST(0.00 AS MONEY) BETWEEN CAST(-1.00 AS MONEY) AND CAST(1.00 AS MONEY) 
            THEN 'In Range' ELSE 'Not In Range' END AS [MONEY BETWEEN (Zero)];
GO
SELECT CASE WHEN CAST(922337203685477.5807 AS MONEY) BETWEEN CAST(922337203685477.5806 AS MONEY) AND CAST(922337203685477.5807 AS MONEY) 
            THEN 'In Range' ELSE 'Not In Range' END AS [MONEY BETWEEN (Max)];
GO

-- SMALLMONEY BETWEEN
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) BETWEEN CAST(123.44 AS SMALLMONEY) AND CAST(123.46 AS SMALLMONEY) 
            THEN 'In Range' ELSE 'Not In Range' END AS [SMALLMONEY BETWEEN];
GO
SELECT CASE WHEN CAST(0.00 AS SMALLMONEY) BETWEEN CAST(-1.00 AS SMALLMONEY) AND CAST(1.00 AS SMALLMONEY) 
            THEN 'In Range' ELSE 'Not In Range' END AS [SMALLMONEY BETWEEN (Zero)];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) BETWEEN CAST(214748.3646 AS SMALLMONEY) AND CAST(214748.3647 AS SMALLMONEY) 
            THEN 'In Range' ELSE 'Not In Range' END AS [SMALLMONEY BETWEEN (Max)];
GO

-- Cross type BETWEEN
SELECT CASE WHEN CAST(123.45 AS MONEY) BETWEEN CAST(123.44 AS SMALLMONEY) AND CAST(123.46 AS SMALLMONEY) 
            THEN 'In Range' ELSE 'Not In Range' END AS [MONEY BETWEEN SMALLMONEY];
GO

-- IN operator tests
-- MONEY IN
SELECT CASE WHEN CAST(123.45 AS MONEY) IN (CAST(123.44 AS MONEY), CAST(123.45 AS MONEY), CAST(123.46 AS MONEY)) 
            THEN 'In List' ELSE 'Not In List' END AS [MONEY IN];
GO
SELECT CASE WHEN CAST(0.00 AS MONEY) IN (CAST(-1.00 AS MONEY), CAST(0.00 AS MONEY), CAST(1.00 AS MONEY)) 
            THEN 'In List' ELSE 'Not In List' END AS [MONEY IN (Zero)];
GO

-- SMALLMONEY IN
SELECT CASE WHEN CAST(123.45 AS SMALLMONEY) IN (CAST(123.44 AS SMALLMONEY), CAST(123.45 AS SMALLMONEY), CAST(123.46 AS SMALLMONEY)) 
            THEN 'In List' ELSE 'Not In List' END AS [SMALLMONEY IN];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) IN (CAST(214748.3646 AS SMALLMONEY), CAST(214748.3647 AS SMALLMONEY)) 
            THEN 'In List' ELSE 'Not In List' END AS [SMALLMONEY IN (Max)];
GO

-- Cross type IN
SELECT CASE WHEN CAST(123.45 AS MONEY) IN (CAST(123.44 AS SMALLMONEY), CAST(123.45 AS SMALLMONEY), CAST(123.46 AS SMALLMONEY)) 
            THEN 'In List' ELSE 'Not In List' END AS [MONEY IN SMALLMONEY];
GO

-- NULL comparison tests
-- MONEY NULL comparisons
SELECT CASE WHEN CAST(NULL AS MONEY) = CAST(123.45 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [NULL MONEY = MONEY];
GO
SELECT CASE WHEN CAST(NULL AS MONEY) <> CAST(123.45 AS MONEY) THEN 'Not Equal' ELSE 'Equal' END AS [NULL MONEY <> MONEY];
GO
SELECT CASE WHEN CAST(NULL AS MONEY) > CAST(123.45 AS MONEY) THEN 'Greater' ELSE 'Not Greater' END AS [NULL MONEY > MONEY];
GO
SELECT CASE WHEN CAST(NULL AS MONEY) < CAST(123.45 AS MONEY) THEN 'Less' ELSE 'Not Less' END AS [NULL MONEY < MONEY];
GO
SELECT CASE WHEN CAST(NULL AS MONEY) IS NULL THEN 'Is NULL' ELSE 'Is Not NULL' END AS [MONEY IS NULL];
GO
SELECT CASE WHEN CAST(NULL AS MONEY) IS NOT NULL THEN 'Is Not NULL' ELSE 'Is NULL' END AS [MONEY IS NOT NULL];
GO

-- SMALLMONEY NULL comparisons
SELECT CASE WHEN CAST(NULL AS SMALLMONEY) = CAST(123.45 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [NULL SMALLMONEY = SMALLMONEY];
GO
SELECT CASE WHEN CAST(NULL AS SMALLMONEY) <> CAST(123.45 AS SMALLMONEY) THEN 'Not Equal' ELSE 'Equal' END AS [NULL SMALLMONEY <> SMALLMONEY];
GO
SELECT CASE WHEN CAST(NULL AS SMALLMONEY) > CAST(123.45 AS SMALLMONEY) THEN 'Greater' ELSE 'Not Greater' END AS [NULL SMALLMONEY > SMALLMONEY];
GO
SELECT CASE WHEN CAST(NULL AS SMALLMONEY) < CAST(123.45 AS SMALLMONEY) THEN 'Less' ELSE 'Not Less' END AS [NULL SMALLMONEY < SMALLMONEY];
GO
SELECT CASE WHEN CAST(NULL AS SMALLMONEY) IS NULL THEN 'Is NULL' ELSE 'Is Not NULL' END AS [SMALLMONEY IS NULL];
GO
SELECT CASE WHEN CAST(NULL AS SMALLMONEY) IS NOT NULL THEN 'Is Not NULL' ELSE 'Is NULL' END AS [SMALLMONEY IS NOT NULL];
GO

-- Edge cases and special values
-- Zero comparisons
SELECT CASE WHEN CAST(0 AS MONEY) = CAST(0.0000 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY Zero = Zero];
GO
SELECT CASE WHEN CAST(0 AS MONEY) = CAST(-0.0000 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY Zero = Negative Zero];
GO
SELECT CASE WHEN CAST(0 AS SMALLMONEY) = CAST(0.0000 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [SMALLMONEY Zero = Zero];
GO
SELECT CASE WHEN CAST(0 AS SMALLMONEY) = CAST(-0.0000 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [SMALLMONEY Zero = Negative Zero];
GO

-- Maximum and minimum value comparisons
SELECT CASE WHEN CAST(922337203685477.5807 AS MONEY) > CAST(922337203685477.5806 AS MONEY) THEN 'True' ELSE 'False' END AS [MAX MONEY > NEAR MAX];
GO
SELECT CASE WHEN CAST(-922337203685477.5808 AS MONEY) < CAST(-922337203685477.5807 AS MONEY) THEN 'True' ELSE 'False' END AS [MIN MONEY < NEAR MIN];
GO
SELECT CASE WHEN CAST(214748.3647 AS SMALLMONEY) > CAST(214748.3646 AS SMALLMONEY) THEN 'True' ELSE 'False' END AS [MAX SMALLMONEY > NEAR MAX];
GO
SELECT CASE WHEN CAST(-214748.3648 AS SMALLMONEY) < CAST(-214748.3647 AS SMALLMONEY) THEN 'True' ELSE 'False' END AS [MIN SMALLMONEY < NEAR MIN];
GO

-- Precision comparison tests
SELECT CASE WHEN CAST(123.4500 AS MONEY) = CAST(123.45 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [MONEY Precision Test];
GO
SELECT CASE WHEN CAST(123.4500 AS SMALLMONEY) = CAST(123.45 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [SMALLMONEY Precision Test];
GO

-- Create test table
CREATE TABLE MoneyComparisonTest
(
    ID INT PRIMARY KEY,
    MoneyVal MONEY,
    SmallMoneyVal SMALLMONEY,
    MoneyNull MONEY NULL,
    SmallMoneyNull SMALLMONEY NULL
);
GO

-- Insert test data
INSERT INTO MoneyComparisonTest (ID, MoneyVal, SmallMoneyVal, MoneyNull, SmallMoneyNull)
VALUES 
(1, 100.00, 100.00, NULL, NULL),
(2, 200.00, 200.00, 200.00, 200.00),
(3, -100.00, -100.00, -100.00, -100.00),
(4, 922337203685477.5807, 214748.3647, NULL, NULL),
(5, -922337203685477.5808, -214748.3648, NULL, NULL),
(6, 0.00, 0.00, 0.00, 0.00),
(7, 123.45, 123.45, 123.45, 123.45);
GO

-- WHERE clause tests
-- Equality tests
SELECT ID, MoneyVal FROM MoneyComparisonTest WHERE MoneyVal = CAST(100.00 AS MONEY);
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest WHERE SmallMoneyVal = CAST(100.00 AS SMALLMONEY);
GO

-- Inequality tests
SELECT ID, MoneyVal FROM MoneyComparisonTest WHERE MoneyVal <> CAST(100.00 AS MONEY);
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest WHERE SmallMoneyVal <> CAST(100.00 AS SMALLMONEY);
GO

-- Greater than tests
SELECT ID, MoneyVal FROM MoneyComparisonTest WHERE MoneyVal > CAST(100.00 AS MONEY);
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest WHERE SmallMoneyVal > CAST(100.00 AS SMALLMONEY);
GO

-- Less than tests
SELECT ID, MoneyVal FROM MoneyComparisonTest WHERE MoneyVal < CAST(100.00 AS MONEY);
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest WHERE SmallMoneyVal < CAST(100.00 AS SMALLMONEY);
GO

-- BETWEEN tests
SELECT ID, MoneyVal FROM MoneyComparisonTest 
WHERE MoneyVal BETWEEN CAST(100.00 AS MONEY) AND CAST(200.00 AS MONEY);
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest 
WHERE SmallMoneyVal BETWEEN CAST(100.00 AS SMALLMONEY) AND CAST(200.00 AS SMALLMONEY);
GO

-- IN tests
SELECT ID, MoneyVal FROM MoneyComparisonTest 
WHERE MoneyVal IN (CAST(100.00 AS MONEY), CAST(200.00 AS MONEY));
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest 
WHERE SmallMoneyVal IN (CAST(100.00 AS SMALLMONEY), CAST(200.00 AS SMALLMONEY));
GO

-- NULL tests
SELECT ID, MoneyNull FROM MoneyComparisonTest WHERE MoneyNull IS NULL;
GO
SELECT ID, SmallMoneyNull FROM MoneyComparisonTest WHERE SmallMoneyNull IS NULL;
GO
SELECT ID, MoneyNull FROM MoneyComparisonTest WHERE MoneyNull IS NOT NULL;
GO
SELECT ID, SmallMoneyNull FROM MoneyComparisonTest WHERE SmallMoneyNull IS NOT NULL;
GO

-- JOIN tests
-- Create second test table
CREATE TABLE MoneyComparisonTest2
(
    ID INT PRIMARY KEY,
    MoneyVal MONEY,
    SmallMoneyVal SMALLMONEY
);
GO

-- Insert test data
INSERT INTO MoneyComparisonTest2 (ID, MoneyVal, SmallMoneyVal)
VALUES 
(1, 100.00, 100.00),
(2, 200.00, 200.00),
(3, 300.00, 300.00);
GO

-- INNER JOIN tests
SELECT t1.ID, t1.MoneyVal, t2.MoneyVal AS MoneyVal2
FROM MoneyComparisonTest t1
INNER JOIN MoneyComparisonTest2 t2 ON t1.MoneyVal = t2.MoneyVal;
GO

SELECT t1.ID, t1.SmallMoneyVal, t2.SmallMoneyVal AS SmallMoneyVal2
FROM MoneyComparisonTest t1
INNER JOIN MoneyComparisonTest2 t2 ON t1.SmallMoneyVal = t2.SmallMoneyVal;
GO

-- LEFT JOIN tests
SELECT t1.ID, t1.MoneyVal, t2.MoneyVal AS MoneyVal2
FROM MoneyComparisonTest t1
LEFT JOIN MoneyComparisonTest2 t2 ON t1.MoneyVal = t2.MoneyVal;
GO

SELECT t1.ID, t1.SmallMoneyVal, t2.SmallMoneyVal AS SmallMoneyVal2
FROM MoneyComparisonTest t1
LEFT JOIN MoneyComparisonTest2 t2 ON t1.SmallMoneyVal = t2.SmallMoneyVal;
GO

-- ORDER BY tests
-- Basic ORDER BY
SELECT ID, MoneyVal FROM MoneyComparisonTest ORDER BY MoneyVal;
GO
SELECT ID, MoneyVal FROM MoneyComparisonTest ORDER BY MoneyVal DESC;
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest ORDER BY SmallMoneyVal;
GO
SELECT ID, SmallMoneyVal FROM MoneyComparisonTest ORDER BY SmallMoneyVal DESC;
GO

-- Multiple column ORDER BY
SELECT ID, MoneyVal, SmallMoneyVal 
FROM MoneyComparisonTest 
ORDER BY MoneyVal, SmallMoneyVal;
GO

SELECT ID, MoneyVal, SmallMoneyVal 
FROM MoneyComparisonTest 
ORDER BY MoneyVal DESC, SmallMoneyVal ASC;
GO

-- ORDER BY with NULL values
SELECT ID, MoneyNull 
FROM MoneyComparisonTest 
ORDER BY MoneyNull;
GO

SELECT ID, SmallMoneyNull 
FROM MoneyComparisonTest 
ORDER BY SmallMoneyNull DESC;
GO

-- GROUP BY tests
-- Basic GROUP BY
SELECT MoneyVal, COUNT(*) as Count 
FROM MoneyComparisonTest 
GROUP BY MoneyVal;
GO

SELECT SmallMoneyVal, COUNT(*) as Count 
FROM MoneyComparisonTest 
GROUP BY SmallMoneyVal;
GO

-- GROUP BY with aggregates
SELECT 
    CASE 
        WHEN MoneyVal >= 0 THEN 'Positive'
        ELSE 'Negative'
    END AS ValueType,
    COUNT(*) as Count,
    MIN(MoneyVal) as MinValue,
    MAX(MoneyVal) as MaxValue,
    AVG(CAST(MoneyVal AS FLOAT)) as AvgValue
FROM MoneyComparisonTest 
GROUP BY CASE 
    WHEN MoneyVal >= 0 THEN 'Positive'
    ELSE 'Negative'
END;
GO

-- HAVING clause tests
SELECT MoneyVal, COUNT(*) as Count 
FROM MoneyComparisonTest 
GROUP BY MoneyVal
HAVING MoneyVal > 0;
GO

SELECT SmallMoneyVal, COUNT(*) as Count 
FROM MoneyComparisonTest 
GROUP BY SmallMoneyVal
HAVING SmallMoneyVal < 0;
GO

-- Complex comparison scenarios
-- Case expression comparisons
SELECT ID,
    CASE 
        WHEN MoneyVal > 0 THEN 'Positive'
        WHEN MoneyVal < 0 THEN 'Negative'
        ELSE 'Zero'
    END AS MoneyCategory,
    CASE 
        WHEN SmallMoneyVal > 0 THEN 'Positive'
        WHEN SmallMoneyVal < 0 THEN 'Negative'
        ELSE 'Zero'
    END AS SmallMoneyCategory
FROM MoneyComparisonTest;
GO

-- Nested comparisons
SELECT ID, MoneyVal
FROM MoneyComparisonTest
WHERE MoneyVal > (
    SELECT AVG(CAST(MoneyVal AS FLOAT))
    FROM MoneyComparisonTest
    WHERE MoneyVal > 0
);
GO

-- Multiple conditions
SELECT ID, MoneyVal, SmallMoneyVal
FROM MoneyComparisonTest
WHERE MoneyVal > 0 
AND SmallMoneyVal > 0 
AND MoneyVal = SmallMoneyVal;
GO

-- Exists with comparison
SELECT ID, MoneyVal
FROM MoneyComparisonTest t1
WHERE EXISTS (
    SELECT 1 
    FROM MoneyComparisonTest2 t2 
    WHERE t2.MoneyVal = t1.MoneyVal
);
GO

-- Union with comparisons
SELECT ID, MoneyVal, 'MONEY' as Type
FROM MoneyComparisonTest
WHERE MoneyVal > 0
UNION
SELECT ID, SmallMoneyVal, 'SMALLMONEY' as Type
FROM MoneyComparisonTest
WHERE SmallMoneyVal > 0
ORDER BY MoneyVal;
GO

-- Intersection test
SELECT MoneyVal
FROM MoneyComparisonTest
WHERE MoneyVal > 0
INTERSECT
SELECT MoneyVal
FROM MoneyComparisonTest2
WHERE MoneyVal > 0;
GO

-- Except test
SELECT MoneyVal
FROM MoneyComparisonTest
WHERE MoneyVal > 0
EXCEPT
SELECT MoneyVal
FROM MoneyComparisonTest2
WHERE MoneyVal > 0;
GO

-- Additional complex scenarios
-- Subquery comparisons
SELECT ID, MoneyVal
FROM MoneyComparisonTest t1
WHERE MoneyVal = (
    SELECT MAX(MoneyVal)
    FROM MoneyComparisonTest
    WHERE ID < t1.ID
);
GO

-- Correlated subqueries
SELECT ID, MoneyVal
FROM MoneyComparisonTest t1
WHERE MoneyVal > (
    SELECT AVG(CAST(t2.MoneyVal AS FLOAT))
    FROM MoneyComparisonTest t2
    WHERE t2.ID < t1.ID
);
GO

-- Window functions with comparisons
SELECT 
    ID,
    MoneyVal,
    LAG(MoneyVal) OVER (ORDER BY ID) as PrevValue,
    CASE 
        WHEN MoneyVal > LAG(MoneyVal) OVER (ORDER BY ID) THEN 'Increased'
        WHEN MoneyVal < LAG(MoneyVal) OVER (ORDER BY ID) THEN 'Decreased'
        WHEN MoneyVal = LAG(MoneyVal) OVER (ORDER BY ID) THEN 'No Change'
        ELSE 'First Row'
    END as ValueChange
FROM MoneyComparisonTest;
GO

-- Running totals with comparisons
SELECT 
    ID,
    MoneyVal,
    SUM(MoneyVal) OVER (ORDER BY ID) as RunningTotal,
    CASE 
        WHEN SUM(MoneyVal) OVER (ORDER BY ID) > 0 THEN 'Positive Balance'
        ELSE 'Negative Balance'
    END as BalanceStatus
FROM MoneyComparisonTest;
GO

-- Pivot operations
-- Create sample data for pivot
CREATE TABLE MoneyPivotTest (
    ID INT,
    Category VARCHAR(10),
    Amount MONEY
);
GO

INSERT INTO MoneyPivotTest (ID, Category, Amount)
VALUES 
(1, 'A', 100.00),
(1, 'B', 200.00),
(2, 'A', 300.00),
(2, 'B', 400.00);
GO

-- Pivot query
SELECT *
FROM (
    SELECT ID, Category, Amount
    FROM MoneyPivotTest
) AS SourceTable
PIVOT (
    SUM(Amount)
    FOR Category IN ([A], [B])
) AS PivotTable;
GO

-- Complex conditional aggregation
SELECT 
    CASE 
        WHEN MoneyVal BETWEEN -1000 AND 1000 THEN 'Normal Range'
        WHEN MoneyVal > 1000 THEN 'High Range'
        ELSE 'Low Range'
    END AS ValueRange,
    COUNT(*) AS Count,
    MIN(MoneyVal) AS MinValue,
    MAX(MoneyVal) AS MaxValue,
    SUM(CASE WHEN MoneyVal > 0 THEN 1 ELSE 0 END) AS PositiveCount,
    SUM(CASE WHEN MoneyVal < 0 THEN 1 ELSE 0 END) AS NegativeCount
FROM MoneyComparisonTest
GROUP BY 
    CASE 
        WHEN MoneyVal BETWEEN -1000 AND 1000 THEN 'Normal Range'
        WHEN MoneyVal > 1000 THEN 'High Range'
        ELSE 'Low Range'
    END;
GO

-- String formatting and comparison tests
SELECT 
    ID,
    MoneyVal,
    CAST(MoneyVal AS VARCHAR(20)) AS StringValue,
    CASE 
        WHEN CAST(MoneyVal AS VARCHAR(20)) LIKE '%-%.%' THEN 'Negative Decimal'
        WHEN CAST(MoneyVal AS VARCHAR(20)) LIKE '%.%' THEN 'Positive Decimal'
        ELSE 'Whole Number'
    END AS FormatType
FROM MoneyComparisonTest;
GO

-- Rounding comparison tests
SELECT 
    ID,
    MoneyVal,
    ROUND(MoneyVal, 0) AS RoundedToInteger,
    CASE 
        WHEN MoneyVal = ROUND(MoneyVal, 0) THEN 'Whole Number'
        ELSE 'Decimal Number'
    END AS NumberType
FROM MoneyComparisonTest;
GO

-- Boundary value analysis
-- Test near-boundary values for MONEY
SELECT 
    CASE WHEN CAST(922337203685477.5807 AS MONEY) = CAST(922337203685477.5807 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [Max_Money_Equal],
    CASE WHEN CAST(-922337203685477.5808 AS MONEY) = CAST(-922337203685477.5808 AS MONEY) THEN 'Equal' ELSE 'Not Equal' END AS [Min_Money_Equal];
GO

-- Test near-boundary values for SMALLMONEY
SELECT 
    CASE WHEN CAST(214748.3647 AS SMALLMONEY) = CAST(214748.3647 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [Max_SmallMoney_Equal],
    CASE WHEN CAST(-214748.3648 AS SMALLMONEY) = CAST(-214748.3648 AS SMALLMONEY) THEN 'Equal' ELSE 'Not Equal' END AS [Min_SmallMoney_Equal];
GO

-- Cleanup
DROP TABLE MoneyComparisonTest;
DROP TABLE MoneyComparisonTest2;
DROP TABLE MoneyPivotTest;
GO

------------------------------------------------------------------------
---- 6. Datatype Conversion
------------------------------------------------------------------------
---- Conversion using CAST()

-- BIT to Money types
SELECT 'BIT to Money Types Conversion' AS test_description;
GO

-- BIT -> MONEY
SELECT CAST(0 AS MONEY) AS [BIT_0_TO_MONEY], CAST(1 AS MONEY) AS [BIT_1_TO_MONEY];
GO

-- BIT -> SMALLMONEY
SELECT CAST(0 AS SMALLMONEY) AS [BIT_0_TO_SMALLMONEY], CAST(1 AS SMALLMONEY) AS [BIT_1_TO_SMALLMONEY];
GO

-- Integer types to Money types
SELECT 'Integer Types to Money Types Conversion' AS test_description;
GO

-- TINYINT -> MONEY
SELECT CAST(CAST(0 AS TINYINT) AS MONEY) AS [TINYINT_MIN_TO_MONEY], 
       CAST(CAST(255 AS TINYINT) AS MONEY) AS [TINYINT_MAX_TO_MONEY],
       CAST(CAST(128 AS TINYINT) AS MONEY) AS [TINYINT_MID_TO_MONEY];
GO

-- TINYINT -> SMALLMONEY
SELECT CAST(CAST(0 AS TINYINT) AS SMALLMONEY) AS [TINYINT_MIN_TO_SMALLMONEY],
       CAST(CAST(255 AS TINYINT) AS SMALLMONEY) AS [TINYINT_MAX_TO_SMALLMONEY],
       CAST(CAST(128 AS TINYINT) AS SMALLMONEY) AS [TINYINT_MID_TO_SMALLMONEY];
GO

-- SMALLINT -> MONEY
SELECT CAST(CAST(-32768 AS SMALLINT) AS MONEY) AS [SMALLINT_MIN_TO_MONEY],
       CAST(CAST(32767 AS SMALLINT) AS MONEY) AS [SMALLINT_MAX_TO_MONEY],
       CAST(CAST(0 AS SMALLINT) AS MONEY) AS [SMALLINT_ZERO_TO_MONEY];
GO

-- SMALLINT -> SMALLMONEY
SELECT CAST(CAST(-32768 AS SMALLINT) AS SMALLMONEY) AS [SMALLINT_MIN_TO_SMALLMONEY],
       CAST(CAST(32767 AS SMALLINT) AS SMALLMONEY) AS [SMALLINT_MAX_TO_SMALLMONEY],
       CAST(CAST(0 AS SMALLINT) AS SMALLMONEY) AS [SMALLINT_ZERO_TO_SMALLMONEY];
GO

-- INT -> MONEY
SELECT CAST(CAST(-2147483648 AS INT) AS MONEY) AS [INT_MIN_TO_MONEY],
       CAST(CAST(2147483647 AS INT) AS MONEY) AS [INT_MAX_TO_MONEY],
       CAST(CAST(0 AS INT) AS MONEY) AS [INT_ZERO_TO_MONEY];
GO

-- INT -> SMALLMONEY
SELECT TRY_CAST(CAST(-2147483648 AS INT) AS SMALLMONEY) AS [INT_MIN_TO_SMALLMONEY],
       TRY_CAST(CAST(2147483647 AS INT) AS SMALLMONEY) AS [INT_MAX_TO_SMALLMONEY],
       CAST(CAST(0 AS INT) AS SMALLMONEY) AS [INT_ZERO_TO_SMALLMONEY];
GO

-- BIGINT -> MONEY
SELECT CAST(CAST(-9223372036854775808 AS BIGINT) AS MONEY) AS [BIGINT_MIN_TO_MONEY],
       CAST(CAST(9223372036854775807 AS BIGINT) AS MONEY) AS [BIGINT_MAX_TO_MONEY],
       CAST(CAST(0 AS BIGINT) AS MONEY) AS [BIGINT_ZERO_TO_MONEY];
GO

-- BIGINT -> SMALLMONEY
SELECT TRY_CAST(CAST(-9223372036854775808 AS BIGINT) AS SMALLMONEY) AS [BIGINT_MIN_TO_SMALLMONEY],
       TRY_CAST(CAST(9223372036854775807 AS BIGINT) AS SMALLMONEY) AS [BIGINT_MAX_TO_SMALLMONEY],
       CAST(CAST(0 AS BIGINT) AS SMALLMONEY) AS [BIGINT_ZERO_TO_SMALLMONEY];
GO

-- Floating point types to Money types
-- FLOAT -> MONEY
SELECT CAST(CAST(-1234.56789 AS FLOAT) AS MONEY) AS [FLOAT_NEG_TO_MONEY],
       CAST(CAST(1234.56789 AS FLOAT) AS MONEY) AS [FLOAT_POS_TO_MONEY],
       CAST(CAST(0.0 AS FLOAT) AS MONEY) AS [FLOAT_ZERO_TO_MONEY],
       CAST(CAST(922337203685477.5807 AS FLOAT) AS MONEY) AS [FLOAT_MAX_TO_MONEY],
       CAST(CAST(-922337203685477.5808 AS FLOAT) AS MONEY) AS [FLOAT_MIN_TO_MONEY];
GO

-- FLOAT -> SMALLMONEY
SELECT CAST(CAST(-214748.3648 AS FLOAT) AS SMALLMONEY) AS [FLOAT_NEG_TO_SMALLMONEY],
       CAST(CAST(214748.3647 AS FLOAT) AS SMALLMONEY) AS [FLOAT_POS_TO_SMALLMONEY],
       CAST(CAST(0.0 AS FLOAT) AS SMALLMONEY) AS [FLOAT_ZERO_TO_SMALLMONEY];
GO

-- REAL -> MONEY
SELECT CAST(CAST(-1234.56789 AS REAL) AS MONEY) AS [REAL_NEG_TO_MONEY],
       CAST(CAST(1234.56789 AS REAL) AS MONEY) AS [REAL_POS_TO_MONEY],
       CAST(CAST(0.0 AS REAL) AS MONEY) AS [REAL_ZERO_TO_MONEY];
GO

-- REAL -> SMALLMONEY
SELECT CAST(CAST(-214748.3648 AS REAL) AS SMALLMONEY) AS [REAL_NEG_TO_SMALLMONEY],
       CAST(CAST(214748.3647 AS REAL) AS SMALLMONEY) AS [REAL_POS_TO_SMALLMONEY],
       CAST(CAST(0.0 AS REAL) AS SMALLMONEY) AS [REAL_ZERO_TO_SMALLMONEY];
GO

-- String types to Money types
-- CHAR -> MONEY
SELECT CAST(CAST('123.45' AS CHAR(40)) AS MONEY) AS [CHAR_POS_TO_MONEY],
       CAST(CAST('-123.45' AS CHAR(40)) AS MONEY) AS [CHAR_NEG_TO_MONEY],
       CAST(CAST('0' AS CHAR(40)) AS MONEY) AS [CHAR_ZERO_TO_MONEY],
       CAST(CAST('922337203685477.5807' AS CHAR(40)) AS MONEY) AS [CHAR_MAX_TO_MONEY],
       CAST(CAST('-922337203685477.5808' AS CHAR(40)) AS MONEY) AS [CHAR_MIN_TO_MONEY];
GO

-- CHAR -> SMALLMONEY
SELECT CAST(CAST('214748.3647' AS CHAR(40)) AS SMALLMONEY) AS [CHAR_POS_TO_SMALLMONEY],
       CAST(CAST('-214748.3648' AS CHAR(40)) AS SMALLMONEY) AS [CHAR_NEG_TO_SMALLMONEY],
       CAST(CAST('0' AS CHAR(40)) AS SMALLMONEY) AS [CHAR_ZERO_TO_SMALLMONEY];
GO

-- TODO: File JIRA, Strings with dollar/comma not parsed to money in BBF
-- VARCHAR -> MONEY
SELECT CAST(CAST('123.45' AS VARCHAR(40)) AS MONEY) AS [VARCHAR_POS_TO_MONEY],
       CAST(CAST('-123.45' AS VARCHAR(40)) AS MONEY) AS [VARCHAR_NEG_TO_MONEY],
       CAST(CAST('0' AS VARCHAR(40)) AS MONEY) AS [VARCHAR_ZERO_TO_MONEY],
       CAST(CAST('922337203685477.5807' AS VARCHAR(40)) AS MONEY) AS [VARCHAR_MAX_TO_MONEY],
       CAST(CAST('-922337203685477.5808' AS VARCHAR(40)) AS MONEY) AS [VARCHAR_MIN_TO_MONEY],
       TRY_CAST(CAST('$123.45' AS VARCHAR(40)) AS MONEY) AS [VARCHAR_CURRENCY_TO_MONEY],
       TRY_CAST(CAST('1,234.56' AS VARCHAR(40)) AS MONEY) AS [VARCHAR_COMMA_TO_MONEY];
GO

-- TODO: File JIRA, Strings with dollar/comma not parsed to smallmoney in BBF
-- VARCHAR -> SMALLMONEY
SELECT CAST(CAST('214748.3647' AS VARCHAR(40)) AS SMALLMONEY) AS [VARCHAR_POS_TO_SMALLMONEY],
       CAST(CAST('-214748.3648' AS VARCHAR(40)) AS SMALLMONEY) AS [VARCHAR_NEG_TO_SMALLMONEY],
       CAST(CAST('0' AS VARCHAR(40)) AS SMALLMONEY) AS [VARCHAR_ZERO_TO_SMALLMONEY],
       TRY_CAST(CAST('$123.45' AS VARCHAR(40)) AS SMALLMONEY) AS [VARCHAR_CURRENCY_TO_SMALLMONEY],
       TRY_CAST(CAST('1,234.56' AS VARCHAR(40)) AS SMALLMONEY) AS [VARCHAR_COMMA_TO_SMALLMONEY];
GO

-- NCHAR -> MONEY
SELECT CAST(CAST(N'123.45' AS NCHAR(40)) AS MONEY) AS [NCHAR_POS_TO_MONEY],
       CAST(CAST(N'-123.45' AS NCHAR(40)) AS MONEY) AS [NCHAR_NEG_TO_MONEY],
       CAST(CAST(N'0' AS NCHAR(40)) AS MONEY) AS [NCHAR_ZERO_TO_MONEY],
       CAST(CAST(N'922337203685477.5807' AS NCHAR(40)) AS MONEY) AS [NCHAR_MAX_TO_MONEY],
       CAST(CAST(N'-922337203685477.5808' AS NCHAR(40)) AS MONEY) AS [NCHAR_MIN_TO_MONEY],
       TRY_CAST(CAST(N'$123.45' AS NCHAR(40)) AS MONEY) AS [NCHAR_CURRENCY_TO_MONEY],
       TRY_CAST(CAST(N'1,234.56' AS NCHAR(40)) AS MONEY) AS [NCHAR_COMMA_TO_MONEY];
GO

-- NCHAR -> SMALLMONEY
SELECT CAST(CAST(N'214748.3647' AS NCHAR(40)) AS SMALLMONEY) AS [NCHAR_POS_TO_SMALLMONEY],
       CAST(CAST(N'-214748.3648' AS NCHAR(40)) AS SMALLMONEY) AS [NCHAR_NEG_TO_SMALLMONEY],
       CAST(CAST(N'0' AS NCHAR(40)) AS SMALLMONEY) AS [NCHAR_ZERO_TO_SMALLMONEY],
       TRY_CAST(CAST(N'$123.45' AS NCHAR(40)) AS SMALLMONEY) AS [NCHAR_CURRENCY_TO_SMALLMONEY],
       TRY_CAST(CAST(N'1,234.56' AS NCHAR(40)) AS SMALLMONEY) AS [NCHAR_COMMA_TO_SMALLMONEY];
GO

-- TODO: File JIRA, Strings with dollar/comma not parsed to money in BBF
-- NVARCHAR -> MONEY
SELECT CAST(CAST(N'123.45' AS NVARCHAR(40)) AS MONEY) AS [NVARCHAR_POS_TO_MONEY],
       CAST(CAST(N'-123.45' AS NVARCHAR(40)) AS MONEY) AS [NVARCHAR_NEG_TO_MONEY],
       CAST(CAST(N'0' AS NVARCHAR(40)) AS MONEY) AS [NVARCHAR_ZERO_TO_MONEY],
       CAST(CAST(N'922337203685477.5807' AS NVARCHAR(40)) AS MONEY) AS [NVARCHAR_MAX_TO_MONEY],
       CAST(CAST(N'-922337203685477.5808' AS NVARCHAR(40)) AS MONEY) AS [NVARCHAR_MIN_TO_MONEY],
       TRY_CAST(CAST(N'$123.45' AS NVARCHAR(40)) AS MONEY) AS [NVARCHAR_CURRENCY_TO_MONEY],
       TRY_CAST(CAST(N'1,234.56' AS NVARCHAR(40)) AS MONEY) AS [NVARCHAR_COMMA_TO_MONEY];
GO

-- TODO: File JIRA, Strings with dollar/comma not parsed to money in BBF
-- NVARCHAR -> SMALLMONEY
SELECT CAST(CAST(N'214748.3647' AS NVARCHAR(40)) AS SMALLMONEY) AS [NVARCHAR_POS_TO_SMALLMONEY],
       CAST(CAST(N'-214748.3648' AS NVARCHAR(40)) AS SMALLMONEY) AS [NVARCHAR_NEG_TO_SMALLMONEY],
       CAST(CAST(N'0' AS NVARCHAR(40)) AS SMALLMONEY) AS [NVARCHAR_ZERO_TO_SMALLMONEY],
       TRY_CAST(CAST(N'$123.45' AS NVARCHAR(40)) AS SMALLMONEY) AS [NVARCHAR_CURRENCY_TO_SMALLMONEY],
       TRY_CAST(CAST(N'1,234.56' AS NVARCHAR(40)) AS SMALLMONEY) AS [NVARCHAR_COMMA_TO_SMALLMONEY];
GO

-- Date/Time types to Money types
-- DATE -> Money types
SELECT CAST(CAST('2023-12-31' AS DATE) AS MONEY) AS [DATE_TO_MONEY],
       TRY_CAST(CAST('2023-12-31' AS DATE) AS SMALLMONEY) AS [DATE_TO_SMALLMONEY];
GO

-- TIME -> Money types
SELECT CAST(CAST('12:34:56.789' AS TIME) AS MONEY) AS [TIME_TO_MONEY],
       TRY_CAST(CAST('12:34:56.789' AS TIME) AS SMALLMONEY) AS [TIME_TO_SMALLMONEY];
GO

-- DATETIME -> Money types
SELECT CAST(CAST('2023-12-31 23:59:59.997' AS DATETIME) AS MONEY) AS [DATETIME_TO_MONEY],
       TRY_CAST(CAST('2023-12-31 23:59:59.997' AS DATETIME) AS SMALLMONEY) AS [DATETIME_TO_SMALLMONEY];
GO

-- DATETIME2 -> Money types
SELECT CAST(CAST('2023-12-31 23:59:59.9999999' AS DATETIME2) AS MONEY) AS [DATETIME2_TO_MONEY],
       TRY_CAST(CAST('2023-12-31 23:59:59.9999999' AS DATETIME2) AS SMALLMONEY) AS [DATETIME2_TO_SMALLMONEY];
GO

-- SMALLDATETIME -> Money types
SELECT CAST(CAST('2023-12-31 23:59:00' AS SMALLDATETIME) AS MONEY) AS [SMALLDATETIME_TO_MONEY],
       TRY_CAST(CAST('2023-12-31 23:59:00' AS SMALLDATETIME) AS SMALLMONEY) AS [SMALLDATETIME_TO_SMALLMONEY];
GO

-- DATETIMEOFFSET -> Money types
SELECT CAST(CAST('2023-12-31 23:59:59.9999999 +00:00' AS DATETIMEOFFSET) AS MONEY) AS [DATETIMEOFFSET_TO_MONEY],
       TRY_CAST(CAST('2023-12-31 23:59:59.9999999 +00:00' AS DATETIMEOFFSET) AS SMALLMONEY) AS [DATETIMEOFFSET_TO_SMALLMONEY];
GO

-- Binary types to Money types
-- BINARY -> Money types
SELECT CAST(CAST(123.45 AS BINARY(8)) AS MONEY) AS [BINARY_TO_MONEY],
       TRY_CAST(CAST(123.45 AS BINARY(8)) AS SMALLMONEY) AS [BINARY_TO_SMALLMONEY];
GO

-- VARBINARY -> Money types
SELECT CAST(CAST(123.45 AS VARBINARY(8)) AS MONEY) AS [VARBINARY_TO_MONEY],
       TRY_CAST(CAST(123.45 AS VARBINARY(8)) AS SMALLMONEY) AS [VARBINARY_TO_SMALLMONEY];
GO

-- Special types to Money types
-- TODO: File JIRA, explicit conversion to money from UUID not allowed in TSQL
-- UNIQUEIDENTIFIER -> Money types (using TRY_CAST to handle potential errors)
DECLARE @uid UNIQUEIDENTIFIER = NEWID();
SELECT TRY_CAST(@uid AS MONEY) AS [UNIQUEIDENTIFIER_TO_MONEY],
       TRY_CAST(@uid AS SMALLMONEY) AS [UNIQUEIDENTIFIER_TO_SMALLMONEY];
GO

-- XML -> Money types (using value method)
DECLARE @xml XML = '<root>123.45</root>';
SELECT CAST(@xml.value('/root[1]', 'MONEY') AS MONEY) AS [XML_TO_MONEY],
       TRY_CAST(@xml.value('/root[1]', 'SMALLMONEY') AS SMALLMONEY) AS [XML_TO_SMALLMONEY];
GO

-- HIERARCHYID -> Money types
DECLARE @hid HIERARCHYID = '/1/2/3/';
SELECT TRY_CAST(CAST(@hid AS VARCHAR(20)) AS MONEY) AS [HIERARCHYID_TO_MONEY],
       TRY_CAST(CAST(@hid AS VARCHAR(20)) AS SMALLMONEY) AS [HIERARCHYID_TO_SMALLMONEY];
GO

-- GEOMETRY -> Money types (using STX and STY methods)
DECLARE @geom GEOMETRY = GEOMETRY::STGeomFromText('POINT(123.45 678.90)', 0);
SELECT CAST(@geom.STX AS MONEY) AS [GEOMETRY_X_TO_MONEY],
       TRY_CAST(@geom.STX AS SMALLMONEY) AS [GEOMETRY_X_TO_SMALLMONEY];
GO

-- GEOGRAPHY -> Money types (using Lat and Long methods)
DECLARE @geog GEOGRAPHY = GEOGRAPHY::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT CAST(@geog.Lat AS MONEY) AS [GEOGRAPHY_LAT_TO_MONEY],
       TRY_CAST(@geog.Lat AS SMALLMONEY) AS [GEOGRAPHY_LAT_TO_SMALLMONEY];
GO

-- ROWVERSION/TIMESTAMP -> Money types
CREATE TABLE #TempRowVersion (Id INT IDENTITY(1,1), RowVer ROWVERSION);
INSERT INTO #TempRowVersion DEFAULT VALUES;
SELECT CAST(RowVer AS MONEY) AS [ROWVERSION_TO_MONEY],
       TRY_CAST(RowVer AS SMALLMONEY) AS [ROWVERSION_TO_SMALLMONEY]
FROM #TempRowVersion;
DROP TABLE #TempRowVersion;
GO

-- Error Cases and Edge Cases
-- NULL value conversions
SELECT CAST(NULL AS MONEY) AS [NULL_TO_MONEY],
       CAST(NULL AS SMALLMONEY) AS [NULL_TO_SMALLMONEY];
GO

-- Invalid string conversions (using TRY_CAST to handle errors)
SELECT TRY_CAST('abc' AS MONEY) AS [INVALID_STRING_TO_MONEY],
       TRY_CAST('abc' AS SMALLMONEY) AS [INVALID_STRING_TO_SMALLMONEY];
GO

-- Overflow tests for SMALLMONEY (using TRY_CAST)
SELECT TRY_CAST(214748.3648 AS SMALLMONEY) AS [OVERFLOW_POS_TO_SMALLMONEY],
       TRY_CAST(-214748.3649 AS SMALLMONEY) AS [OVERFLOW_NEG_TO_SMALLMONEY];
GO

-- Maximum and minimum values
SELECT 
    -- MONEY max/min
    CAST(922337203685477.5807 AS MONEY) AS [MONEY_MAX],
    CAST(-922337203685477.5808 AS MONEY) AS [MONEY_MIN],
    
    -- SMALLMONEY max/min
    CAST(214748.3647 AS SMALLMONEY) AS [SMALLMONEY_MAX],
    CAST(-214748.3648 AS SMALLMONEY) AS [SMALLMONEY_MIN];
GO

-- Rounding behavior tests
SELECT 
    -- MONEY rounding
    CAST(123.4549 AS MONEY) AS [MONEY_ROUND_DOWN],
    CAST(123.4550 AS MONEY) AS [MONEY_ROUND_UP],
    
    -- SMALLMONEY rounding
    CAST(123.4549 AS SMALLMONEY) AS [SMALLMONEY_ROUND_DOWN],
    CAST(123.4550 AS SMALLMONEY) AS [SMALLMONEY_ROUND_UP];
GO

-- Scientific notation tests
SELECT 
    TRY_CAST('1.23E+3' AS MONEY) AS [SCIENTIFIC_TO_MONEY],
    TRY_CAST('1.23E+3' AS SMALLMONEY) AS [SCIENTIFIC_TO_SMALLMONEY];
GO

-- Currency symbol and format tests
SELECT 
    TRY_CAST('$123.45' AS MONEY) AS [CURRENCY_TO_MONEY],
    TRY_CAST('$123.45' AS SMALLMONEY) AS [CURRENCY_TO_SMALLMONEY],
    
    TRY_CAST('123.45€' AS MONEY) AS [EURO_TO_MONEY],
    TRY_CAST('£123.45' AS MONEY) AS [POUND_TO_MONEY],
    
    TRY_CAST('1,234.56' AS MONEY) AS [COMMA_TO_MONEY],
    TRY_CAST('1.234,56' AS MONEY) AS [EUROPEAN_TO_MONEY];
GO

---- Conversion using CONVERT()

-- Style 0 (default) tests
SELECT CONVERT(MONEY, '1234.56', 0) AS [DEFAULT_TO_MONEY],
       CONVERT(SMALLMONEY, '1234.56', 0) AS [DEFAULT_TO_SMALLMONEY];
GO

-- Style 1 (with commas) tests
SELECT CONVERT(MONEY, '1,234.56', 1) AS [STYLE1_TO_MONEY],
       CONVERT(SMALLMONEY, '1,234.56', 1) AS [STYLE1_TO_SMALLMONEY];
GO

-- Style 2 (with decimal point) tests
SELECT CONVERT(MONEY, '1234.56', 2) AS [STYLE2_TO_MONEY],
       CONVERT(SMALLMONEY, '1234.56', 2) AS [STYLE2_TO_SMALLMONEY];
GO

-- Currency symbol tests with different styles
SELECT CONVERT(MONEY, '$1,234.56', 1) AS [DOLLAR_TO_MONEY],
       CONVERT(SMALLMONEY, '$1,234.56', 1) AS [DOLLAR_TO_SMALLMONEY];
GO

-- Convert from different numeric types using CONVERT
-- INTEGER types
SELECT CONVERT(MONEY, CAST(1234 AS INT)) AS [INT_TO_MONEY],
       CONVERT(SMALLMONEY, CAST(1234 AS INT)) AS [INT_TO_SMALLMONEY];
GO

-- DECIMAL types
SELECT CONVERT(MONEY, CAST(1234.56 AS DECIMAL(10,2))) AS [DECIMAL_TO_MONEY],
       CONVERT(SMALLMONEY, CAST(1234.56 AS DECIMAL(10,2))) AS [DECIMAL_TO_SMALLMONEY];
GO

-- FLOAT types
SELECT CONVERT(MONEY, CAST(1234.56 AS FLOAT)) AS [FLOAT_TO_MONEY],
       CONVERT(SMALLMONEY, CAST(1234.56 AS FLOAT)) AS [FLOAT_TO_SMALLMONEY];
GO

-- Convert from temporal types using CONVERT
-- DATE
SELECT CONVERT(MONEY, GETDATE()) AS [DATE_TO_MONEY],
       CONVERT(SMALLMONEY, GETDATE()) AS [DATE_TO_SMALLMONEY];
GO

-- DATETIME2
SELECT CONVERT(MONEY, SYSDATETIME()) AS [DATETIME2_TO_MONEY],
       CONVERT(SMALLMONEY, SYSDATETIME()) AS [DATETIME2_TO_SMALLMONEY];
GO

-- Convert between money types using CONVERT
-- MONEY conversions
SELECT CONVERT(SMALLMONEY, CAST(1234.56 AS MONEY)) AS [MONEY_TO_SMALLMONEY];
GO

-- SMALLMONEY conversions
SELECT CONVERT(MONEY, CAST(1234.56 AS SMALLMONEY)) AS [SMALLMONEY_TO_MONEY];
GO

-- Special number format tests using CONVERT
-- Scientific notation
SELECT TRY_CONVERT(MONEY, '1.23E+3') AS [SCIENTIFIC_TO_MONEY],
       TRY_CONVERT(SMALLMONEY, '1.23E+3') AS [SCIENTIFIC_TO_SMALLMONEY];
GO

-- Negative values
SELECT CONVERT(MONEY, '-1234.56') AS [NEGATIVE_TO_MONEY],
       CONVERT(SMALLMONEY, '-1234.56') AS [NEGATIVE_TO_SMALLMONEY];
GO

-- Different decimal separators
SELECT TRY_CONVERT(MONEY, '1234,56') AS [COMMA_TO_MONEY],
       TRY_CONVERT(SMALLMONEY, '1234,56') AS [COMMA_TO_SMALLMONEY];
GO

-- Edge cases with CONVERT
-- Maximum and minimum values

-- MONEY max/min
SELECT CONVERT(MONEY, 922337203685477.5807) AS [MONEY_MAX],
       CONVERT(MONEY, -922337203685477.5808) AS [MONEY_MIN],
       TRY_CONVERT(MONEY, 922337203685477.5808) AS [MONEY_OVERFLOW_POS], -- Should fail
       TRY_CONVERT(MONEY, -922337203685477.5809) AS [MONEY_OVERFLOW_NEG]; -- Should fail
GO

-- SMALLMONEY max/min
SELECT CONVERT(SMALLMONEY, 214748.3647) AS [SMALLMONEY_MAX],
       CONVERT(SMALLMONEY, -214748.3648) AS [SMALLMONEY_MIN],
       TRY_CONVERT(SMALLMONEY, 214748.3648) AS [SMALLMONEY_OVERFLOW_POS], -- Should fail
       TRY_CONVERT(SMALLMONEY, -214748.3649) AS [SMALLMONEY_OVERFLOW_NEG]; -- Should fail
GO

-- Rounding behavior tests with CONVERT
-- Regular rounding tests
SELECT CONVERT(MONEY, 123.4549) AS [MONEY_ROUND_DOWN],
       CONVERT(MONEY, 123.4550) AS [MONEY_ROUND_UP],
       CONVERT(SMALLMONEY, 123.4549) AS [SMALLMONEY_ROUND_DOWN],
       CONVERT(SMALLMONEY, 123.4550) AS [SMALLMONEY_ROUND_UP];
GO

-- Rounding with more decimal places
SELECT CONVERT(MONEY, 123.45494949) AS [MONEY_ROUND_MANY_DECIMALS],
       CONVERT(SMALLMONEY, 123.45494949) AS [SMALLMONEY_ROUND_MANY_DECIMALS];
GO

-- Special value conversions
-- Zero value tests
SELECT CONVERT(MONEY, 0) AS [ZERO_TO_MONEY],
       CONVERT(MONEY, 0.0) AS [ZERO_DECIMAL_TO_MONEY],
       CONVERT(MONEY, '0') AS [ZERO_STRING_TO_MONEY],
       CONVERT(MONEY, '0.0') AS [ZERO_DECIMAL_STRING_TO_MONEY],
       CONVERT(MONEY, '$0.00') AS [ZERO_CURRENCY_TO_MONEY];
GO

-- NULL value tests
SELECT CONVERT(MONEY, NULL) AS [NULL_TO_MONEY],
       CONVERT(SMALLMONEY, NULL) AS [NULL_TO_SMALLMONEY];
GO

-- Currency format tests with different styles
-- Style 0 (default)
SELECT TRY_CONVERT(MONEY, '$1234.56', 0) AS [CURRENCY_DEFAULT_STYLE],
       TRY_CONVERT(MONEY, '£1234.56', 0) AS [POUND_DEFAULT_STYLE],
       TRY_CONVERT(MONEY, '€1234.56', 0) AS [EURO_DEFAULT_STYLE],
       TRY_CONVERT(MONEY, '¥1234.56', 0) AS [YEN_DEFAULT_STYLE];
GO

-- Style 1 (with commas)
SELECT TRY_CONVERT(MONEY, '$1,234.56', 1) AS [CURRENCY_STYLE_1],
       TRY_CONVERT(MONEY, '£1,234.56', 1) AS [POUND_STYLE_1],
       TRY_CONVERT(MONEY, '€1,234.56', 1) AS [EURO_STYLE_1],
       TRY_CONVERT(MONEY, '¥1,234.56', 1) AS [YEN_STYLE_1];
GO

-- Style 2 (with decimal point)
SELECT TRY_CONVERT(MONEY, '$1234.56', 2) AS [CURRENCY_STYLE_2],
       TRY_CONVERT(MONEY, '£1234.56', 2) AS [POUND_STYLE_2],
       TRY_CONVERT(MONEY, '€1234.56', 2) AS [EURO_STYLE_2],
       TRY_CONVERT(MONEY, '¥1234.56', 2) AS [YEN_STYLE_2];
GO

-- Invalid format tests
-- Invalid string formats
SELECT TRY_CONVERT(MONEY, 'abc') AS [INVALID_STRING_MONEY],
       TRY_CONVERT(SMALLMONEY, 'abc') AS [INVALID_STRING_SMALLMONEY];
GO

-- Invalid numeric formats
SELECT TRY_CONVERT(MONEY, '123.45.67') AS [INVALID_NUMBER_MONEY],
       TRY_CONVERT(SMALLMONEY, '123.45.67') AS [INVALID_NUMBER_SMALLMONEY];
GO

-- Empty string tests
SELECT TRY_CONVERT(MONEY, '') AS [EMPTY_STRING_MONEY],
       TRY_CONVERT(SMALLMONEY, '') AS [EMPTY_STRING_SMALLMONEY];
GO

-- Whitespace tests
SELECT TRY_CONVERT(MONEY, ' ') AS [WHITESPACE_MONEY],
       TRY_CONVERT(SMALLMONEY, ' ') AS [WHITESPACE_SMALLMONEY];
GO

-- Mixed format tests
SELECT TRY_CONVERT(MONEY, ' $1,234.56 ') AS [MIXED_FORMAT_MONEY],
       TRY_CONVERT(SMALLMONEY, ' $1,234.56 ') AS [MIXED_FORMAT_SMALLMONEY];
GO

-- Specialized conversion scenarios
-- Decimal precision tests

-- Testing different decimal places
SELECT CONVERT(MONEY, '123.4') AS [ONE_DECIMAL],
       CONVERT(MONEY, '123.45') AS [TWO_DECIMALS],
       CONVERT(MONEY, '123.456') AS [THREE_DECIMALS],
       CONVERT(MONEY, '123.4567') AS [FOUR_DECIMALS],
       CONVERT(MONEY, '123.45678') AS [FIVE_DECIMALS];
GO

-- Testing with SMALLMONEY
SELECT CONVERT(SMALLMONEY, '123.4') AS [SM_ONE_DECIMAL],
       CONVERT(SMALLMONEY, '123.45') AS [SM_TWO_DECIMALS],
       CONVERT(SMALLMONEY, '123.456') AS [SM_THREE_DECIMALS],
       CONVERT(SMALLMONEY, '123.4567') AS [SM_FOUR_DECIMALS],
       CONVERT(SMALLMONEY, '123.45678') AS [SM_FIVE_DECIMALS];
GO

-- Conversion with calculations
-- Basic arithmetic during conversion
SELECT CONVERT(MONEY, 123.45 + 678.90) AS [ADD_THEN_CONVERT],
       CONVERT(MONEY, 123.45) + CONVERT(MONEY, 678.90) AS [CONVERT_THEN_ADD],
       CONVERT(SMALLMONEY, 123.45 + 678.90) AS [SM_ADD_THEN_CONVERT],
       CONVERT(SMALLMONEY, 123.45) + CONVERT(SMALLMONEY, 678.90) AS [SM_CONVERT_THEN_ADD];
GO

-- Complex calculations
SELECT CONVERT(MONEY, (123.45 * 2 + 678.90) / 3) AS [COMPLEX_CALC_MONEY],
       CONVERT(SMALLMONEY, (123.45 * 2 + 678.90) / 3) AS [COMPLEX_CALC_SMALLMONEY];
GO

-- Unicode string conversion tests
-- Unicode numbers
SELECT CONVERT(MONEY, N'123.45') AS [UNICODE_BASIC],
       CONVERT(MONEY, N'１２３.４５') AS [UNICODE_FULL_WIDTH],
       TRY_CONVERT(MONEY, N'①②③.④⑤') AS [UNICODE_CIRCLED],
       TRY_CONVERT(MONEY, N'壹貳叁.肆伍') AS [UNICODE_CHINESE];
GO

-- Special character handling
-- TODO: File JIRA, Output Difference with T-SQL
-- Testing various currency symbols
SELECT TRY_CONVERT(MONEY, '₹123.45') AS [RUPEE],
       TRY_CONVERT(MONEY, '₱123.45') AS [PESO],
       TRY_CONVERT(MONEY, '₩123.45') AS [WON],
       TRY_CONVERT(MONEY, '₴123.45') AS [HRYVNIA];
GO

-- Comprehensive error handling tests
-- Create table for error logging
CREATE TABLE #ConversionErrors (
    TestName VARCHAR(100),
    TestValue VARCHAR(100),
    ErrorMessage VARCHAR(1000)
);
GO

-- Test procedure for safe conversion
CREATE PROCEDURE #TestMoneyConversion
    @TestName VARCHAR(100),
    @TestValue VARCHAR(100),
    @TargetType VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(1000);
        SET @SQL = 'SELECT CONVERT(' + @TargetType + ', ''' + @TestValue + ''')';
        EXEC(@SQL);
    END TRY
    BEGIN CATCH
        INSERT INTO #ConversionErrors (TestName, TestValue, ErrorMessage)
        VALUES (@TestName, @TestValue, ERROR_MESSAGE());
    END CATCH
END;
GO

-- Test various problematic conversions
EXEC #TestMoneyConversion 'Invalid Characters', 'ABC', 'MONEY';
EXEC #TestMoneyConversion 'Multiple Decimal Points', '123.45.67', 'MONEY';
EXEC #TestMoneyConversion 'Multiple Currency Symbols', '$$123.45', 'MONEY';
EXEC #TestMoneyConversion 'Invalid Position Currency', '123.45$', 'MONEY';
EXEC #TestMoneyConversion 'Mixed Separators', '1,234.567,89', 'MONEY';
EXEC #TestMoneyConversion 'Overflow Value', '922337203685477.5808', 'MONEY';
EXEC #TestMoneyConversion 'Underflow Value', '-922337203685477.5809', 'MONEY';
GO

-- TODO: File JIRA, Output Difference with Dynamic SQL
-- Display error results
SELECT * FROM #ConversionErrors ORDER BY TestName;
GO

-- Cleanup
DROP TABLE #ConversionErrors;
DROP PROCEDURE #TestMoneyConversion;
GO

-- Conversion with different number systems
-- Binary string to money
SELECT TRY_CONVERT(MONEY, '0b1111011') AS [BINARY_STRING_CONVERSION];
GO

-- Hexadecimal string to money
SELECT TRY_CONVERT(MONEY, '0x7B') AS [HEX_STRING_CONVERSION];
GO

-- Scientific notation
SELECT TRY_CONVERT(MONEY, '1.2345e3') AS [SCIENTIFIC_NOTATION_POSITIVE],
       TRY_CONVERT(MONEY, '1.2345e-3') AS [SCIENTIFIC_NOTATION_NEGATIVE];
GO

-- Testing conversion of special values
-- Testing with various forms of zero
SELECT CONVERT(MONEY, 0) AS [ZERO_INT],
       CONVERT(MONEY, 0.0) AS [ZERO_DECIMAL],
       CONVERT(MONEY, '0') AS [ZERO_STRING],
       CONVERT(MONEY, '+0') AS [PLUS_ZERO],
       CONVERT(MONEY, '-0') AS [MINUS_ZERO],
       CONVERT(MONEY, '0.0000') AS [ZERO_MULTI_DECIMAL];
GO

-- Testing with international formatting
-- Create temporary table for various international formats
CREATE TABLE #InternationalFormats (
    CountryFormat VARCHAR(50),
    MoneyString VARCHAR(50)
);
GO

-- Insert various international formats
INSERT INTO #InternationalFormats VALUES
('US', '$1,234.56'),
('UK', '£1,234.56'),
('EU', '1.234,56€'),
('JP', '¥1,234.56'),
('IN', '₹1,234.56'),
('CH', '¥1,234.56'),
('RU', '1 234,56₽'),
('BR', 'R$1.234,56'),
('MX', 'MX$1,234.56'),
('KR', '₩1,234.56');
GO

-- Test conversions with TRY_CONVERT
SELECT CountryFormat,
       MoneyString,
       TRY_CONVERT(MONEY, MoneyString) AS ConvertedToMoney,
       TRY_CONVERT(SMALLMONEY, MoneyString) AS ConvertedToSmallMoney
FROM #InternationalFormats;
GO

-- Cleanup
DROP TABLE #InternationalFormats;
GO

-- Testing with various decimal separator positions
SELECT TRY_CONVERT(MONEY, '1234.5678') AS [NORMAL_POSITION],
       TRY_CONVERT(MONEY, '12345.678') AS [ONE_RIGHT],
       TRY_CONVERT(MONEY, '123.45678') AS [ONE_LEFT],
       TRY_CONVERT(MONEY, '1.2345678') AS [FAR_LEFT],
       TRY_CONVERT(MONEY, '12345678.') AS [FAR_RIGHT];
GO

-- Testing with different spacing patterns
SELECT TRY_CONVERT(MONEY, '1234.56') AS [NO_SPACES],
       TRY_CONVERT(MONEY, ' 1234.56') AS [LEADING_SPACE],
       TRY_CONVERT(MONEY, '1234.56 ') AS [TRAILING_SPACE],
       TRY_CONVERT(MONEY, ' 1234.56 ') AS [BOTH_SPACES],
       TRY_CONVERT(MONEY, '1 234.56') AS [MIDDLE_SPACE];
GO

-- Testing with parentheses (negative numbers)
SELECT TRY_CONVERT(MONEY, '(1234.56)') AS [PARENTHESES_BASIC],
       TRY_CONVERT(MONEY, '$(1234.56)') AS [PARENTHESES_WITH_SYMBOL],
       TRY_CONVERT(MONEY, '(£1234.56)') AS [PARENTHESES_WITH_POUND],
       TRY_CONVERT(MONEY, '(1,234.56)') AS [PARENTHESES_WITH_COMMA];
GO

-- Testing with different grouping separator patterns
SELECT TRY_CONVERT(MONEY, '1,234,567.89') AS [STANDARD_GROUPING],
       TRY_CONVERT(MONEY, '1234,567.89') AS [PARTIAL_GROUPING],
       TRY_CONVERT(MONEY, '12,34,567.89') AS [IRREGULAR_GROUPING],
       TRY_CONVERT(MONEY, '1.234.567,89') AS [EUROPEAN_GROUPING];
GO

-- Testing with mixed notation types
SELECT TRY_CONVERT(MONEY, '$-1234.56') AS [SYMBOL_THEN_NEGATIVE],
       TRY_CONVERT(MONEY, '-$1234.56') AS [NEGATIVE_THEN_SYMBOL],
       TRY_CONVERT(MONEY, '$ (1234.56)') AS [SYMBOL_AND_PARENTHESES],
       TRY_CONVERT(MONEY, '($1234.56)') AS [PARENTHESES_WITH_INTERNAL_SYMBOL];
GO

-- Testing with precision boundary cases
-- Maximum precision tests
SELECT TRY_CONVERT(MONEY, '922337203685477.5807') AS [MAX_MONEY_PRECISE],
       TRY_CONVERT(MONEY, '922337203685477.5806999999') AS [NEAR_MAX_MONEY],
       TRY_CONVERT(SMALLMONEY, '214748.3647') AS [MAX_SMALLMONEY_PRECISE],
       TRY_CONVERT(SMALLMONEY, '214748.3646999999') AS [NEAR_MAX_SMALLMONEY];
GO

-- Minimum precision tests
SELECT TRY_CONVERT(MONEY, '-922337203685477.5808') AS [MIN_MONEY_PRECISE],
       TRY_CONVERT(MONEY, '-922337203685477.5807999999') AS [NEAR_MIN_MONEY],
       TRY_CONVERT(SMALLMONEY, '-214748.3648') AS [MIN_SMALLMONEY_PRECISE],
       TRY_CONVERT(SMALLMONEY, '-214748.3647999999') AS [NEAR_MIN_SMALLMONEY];
GO

-- Testing with exponential notation variations
SELECT TRY_CONVERT(MONEY, '1.23456E+3') AS [STANDARD_EXP],
       TRY_CONVERT(MONEY, '1.23456E3') AS [NO_PLUS_EXP],
       TRY_CONVERT(MONEY, '1.23456e+3') AS [LOWERCASE_E],
       TRY_CONVERT(MONEY, '1.23456D+3') AS [D_NOTATION],
       TRY_CONVERT(MONEY, '123.456E+1') AS [SHIFTED_EXP],
       TRY_CONVERT(MONEY, '12345.6E-1') AS [NEGATIVE_EXP];
GO

-- Testing with currency symbol positions
SELECT TRY_CONVERT(MONEY, '$1234.56') AS [LEADING_SYMBOL],
       TRY_CONVERT(MONEY, '1234.56$') AS [TRAILING_SYMBOL],
       TRY_CONVERT(MONEY, '$ 1234.56') AS [LEADING_SYMBOL_SPACE],
       TRY_CONVERT(MONEY, '1234.56 $') AS [TRAILING_SYMBOL_SPACE];
GO

-- Edge case conversion tests with trailing zeros
-- Testing different trailing zero patterns
SELECT CONVERT(MONEY, '1234.00') AS [BASIC_TRAILING_ZEROS],
       CONVERT(MONEY, '1234.000') AS [EXTRA_TRAILING_ZEROS],
       CONVERT(MONEY, '1234.0000000') AS [MANY_TRAILING_ZEROS],
       CONVERT(MONEY, '1234.') AS [DECIMAL_NO_ZEROS],
       CONVERT(MONEY, '1234') AS [NO_DECIMAL_NO_ZEROS];
GO

-- Leading zeros tests
SELECT CONVERT(MONEY, '00001234.56') AS [LEADING_ZEROS],
       CONVERT(MONEY, '000000.12') AS [LEADING_ZEROS_DECIMAL],
       CONVERT(MONEY, '00000.00') AS [ALL_ZEROS],
       CONVERT(MONEY, '-00001234.56') AS [NEGATIVE_LEADING_ZEROS];
GO

-- Testing with alternative negative notations
SELECT TRY_CONVERT(MONEY, '-1234.56') AS [STANDARD_NEGATIVE],
       TRY_CONVERT(MONEY, '(1234.56)') AS [PARENTHESES],
       TRY_CONVERT(MONEY, '- 1234.56') AS [NEGATIVE_WITH_SPACE],
       TRY_CONVERT(MONEY, '-$1234.56') AS [NEGATIVE_WITH_SYMBOL],
       TRY_CONVERT(MONEY, '$-1234.56') AS [SYMBOL_WITH_NEGATIVE],
       TRY_CONVERT(MONEY, '($1234.56)') AS [PARENTHESES_WITH_SYMBOL];
GO

-- Fractional value edge cases
SELECT CONVERT(MONEY, '0.12345678901234') AS [MANY_DECIMALS],
       CONVERT(MONEY, '0.00000000000001') AS [VERY_SMALL_POSITIVE],
       CONVERT(MONEY, '-0.00000000000001') AS [VERY_SMALL_NEGATIVE],
       CONVERT(MONEY, '0.99999999999999') AS [NEAR_ONE_POSITIVE],
       CONVERT(MONEY, '-0.99999999999999') AS [NEAR_ONE_NEGATIVE];
GO


-- Testing with unusual string formats
-- Mixed format strings
SELECT TRY_CONVERT(MONEY, '+$1,234.56') AS [PLUS_SIGN_DOLLAR],
       TRY_CONVERT(MONEY, '$ +1,234.56') AS [DOLLAR_PLUS_SIGN],
       TRY_CONVERT(MONEY, '1234.56+ $') AS [TRAILING_PLUS_DOLLAR],
       TRY_CONVERT(MONEY, '++1234.56') AS [MULTIPLE_PLUS],
       TRY_CONVERT(MONEY, '--1234.56') AS [MULTIPLE_MINUS];
GO

-- Testing with special characters
SELECT TRY_CONVERT(MONEY, '1␣234.56') AS [WITH_SPECIAL_SPACE],
       TRY_CONVERT(MONEY, '1⁄234.56') AS [WITH_FRACTION_SLASH],
       TRY_CONVERT(MONEY, '1−234.56') AS [WITH_MINUS_SIGN],
       TRY_CONVERT(MONEY, '1·234.56') AS [WITH_MIDDLE_DOT];
GO

-- Boundary condition tests
-- Maximum value variations
SELECT TRY_CONVERT(MONEY, '922337203685477.5807') AS [MAX_MONEY],
       TRY_CONVERT(MONEY, '922337203685477.5808') AS [MAX_MONEY_PLUS_POINT0001],
       TRY_CONVERT(MONEY, '922337203685477.5806') AS [MAX_MONEY_MINUS_POINT0001];
GO

-- Minimum value variations
SELECT TRY_CONVERT(MONEY, '-922337203685477.5808') AS [MIN_MONEY],
       TRY_CONVERT(MONEY, '-922337203685477.5809') AS [MIN_MONEY_MINUS_POINT0001],
       TRY_CONVERT(MONEY, '-922337203685477.5807') AS [MIN_MONEY_PLUS_POINT0001];
GO

-- SmallMoney boundary tests
SELECT TRY_CONVERT(SMALLMONEY, '214748.3647') AS [MAX_SMALLMONEY],
       TRY_CONVERT(SMALLMONEY, '214748.3648') AS [MAX_SMALLMONEY_PLUS_POINT0001],
       TRY_CONVERT(SMALLMONEY, '-214748.3648') AS [MIN_SMALLMONEY],
       TRY_CONVERT(SMALLMONEY, '-214748.3649') AS [MIN_SMALLMONEY_MINUS_POINT0001];
GO

-- Testing with mathematical expressions
-- Create function to evaluate string expressions
CREATE FUNCTION dbo.EvaluateExpression (@expr VARCHAR(100))
RETURNS MONEY
AS
BEGIN
    DECLARE @result MONEY
    BEGIN TRY
        DECLARE @sql NVARCHAR(200) = N'SELECT @result = ' + @expr
        EXEC sp_executesql @sql, N'@result MONEY OUTPUT', @result OUTPUT
    END TRY
    BEGIN CATCH
        RETURN NULL
    END CATCH
    RETURN @result
END;
GO

-- Test mathematical expressions
SELECT dbo.EvaluateExpression('CONVERT(MONEY, 100 + 200)') AS [SIMPLE_ADDITION],
       dbo.EvaluateExpression('CONVERT(MONEY, 500 - 200)') AS [SIMPLE_SUBTRACTION],
       dbo.EvaluateExpression('CONVERT(MONEY, 100 * 1.5)') AS [MULTIPLICATION_DECIMAL],
       dbo.EvaluateExpression('CONVERT(MONEY, 1000 / 2)') AS [DIVISION];
GO

-- Cleanup
DROP FUNCTION dbo.EvaluateExpression;
GO

-- Complex type interaction scenarios
-- Create temporary tables for testing
CREATE TABLE SourceValues (
    IntVal INT,
    FloatVal FLOAT,
    DecimalVal DECIMAL(18,4),
    VarcharVal VARCHAR(50),
    DateVal DATE
);

CREATE TABLE ResultsMoney (
    TestName VARCHAR(100),
    MoneyResult MONEY,
    SmallMoneyResult SMALLMONEY
);
GO

-- Insert test data
INSERT INTO SourceValues VALUES
(1234, 1234.5678, 1234.5678, '1234.5678', '2024-01-01'),
(-1234, -1234.5678, -1234.5678, '-1234.5678', '2024-12-31'),
(0, 0.0, 0.0, '0.0', '2024-06-15');
GO

-- Complex conversion scenarios
INSERT INTO ResultsMoney (TestName, MoneyResult, SmallMoneyResult)
SELECT 
    'Mixed Addition' AS TestName,
    CAST(IntVal AS MONEY) + CAST(FloatVal AS MONEY),
    CAST(IntVal AS SMALLMONEY) + CAST(FloatVal AS SMALLMONEY)
FROM SourceValues
WHERE IntVal > 0;
GO

-- Nested conversion tests
INSERT INTO ResultsMoney (TestName, MoneyResult, SmallMoneyResult)
SELECT 
    'Nested Conversion' AS TestName,
    CAST(CAST(CAST(FloatVal AS VARCHAR(20)) AS DECIMAL(18,4)) AS MONEY),
    CAST(CAST(CAST(FloatVal AS VARCHAR(20)) AS DECIMAL(18,4)) AS SMALLMONEY)
FROM SourceValues
WHERE FloatVal IS NOT NULL;
GO

-- Mathematical function interactions
INSERT INTO ResultsMoney (TestName, MoneyResult, SmallMoneyResult)
SELECT 
    'Math Functions' AS TestName,
    CAST(ROUND(FloatVal, 2) AS MONEY),
    CAST(ROUND(FloatVal, 2) AS SMALLMONEY)
FROM SourceValues
WHERE FloatVal IS NOT NULL;
GO

-- Date arithmetic conversions
INSERT INTO ResultsMoney (TestName, MoneyResult, SmallMoneyResult)
SELECT 
    'Date Conversion' AS TestName,
    CAST(DATEDIFF(DAY, '2024-01-01', DateVal) AS MONEY),
    CAST(DATEDIFF(DAY, '2024-01-01', DateVal) AS SMALLMONEY)
FROM SourceValues;
GO

-- Complex arithmetic expressions
INSERT INTO ResultsMoney (TestName, MoneyResult, SmallMoneyResult)
SELECT 
    'Complex Arithmetic' AS TestName,
    CAST((IntVal * 2 + SQRT(ABS(FloatVal))) AS MONEY),
    CAST((IntVal * 2 + SQRT(ABS(FloatVal))) AS SMALLMONEY)
FROM SourceValues
WHERE IntVal != 0;
GO

-- String manipulation then conversion
INSERT INTO ResultsMoney (TestName, MoneyResult, SmallMoneyResult)
SELECT 
    'String Manipulation' AS TestName,
    CAST(REPLACE(VarcharVal, '.', '') AS MONEY) / 10000,
    CAST(REPLACE(VarcharVal, '.', '') AS SMALLMONEY) / 10000
FROM SourceValues
WHERE VarcharVal != '0.0';
GO

-- Conditional conversion tests
INSERT INTO ResultsMoney (TestName, MoneyResult, SmallMoneyResult)
SELECT 
    'Conditional Conversion' AS TestName,
    CASE 
        WHEN IntVal > 0 THEN CAST(FloatVal AS MONEY)
        WHEN IntVal < 0 THEN CAST(DecimalVal AS MONEY)
        ELSE CAST(0 AS MONEY)
    END,
    CASE 
        WHEN IntVal > 0 THEN CAST(FloatVal AS SMALLMONEY)
        WHEN IntVal < 0 THEN CAST(DecimalVal AS SMALLMONEY)
        ELSE CAST(0 AS SMALLMONEY)
    END
FROM SourceValues;
GO

-- Aggregate function conversions
SELECT 
    'Aggregate Conversions' AS TestName,
    CAST(AVG(CAST(FloatVal AS MONEY)) AS MONEY) AS AvgMoney,
    CAST(AVG(CAST(FloatVal AS SMALLMONEY)) AS SMALLMONEY) AS AvgSmallMoney
FROM SourceValues
WHERE FloatVal IS NOT NULL;
GO

-- Display results
SELECT * FROM ResultsMoney ORDER BY TestName;
GO

-- Cleanup
DROP TABLE SourceValues;
DROP TABLE ResultsMoney;
GO

-- BABEL-5664, Renable test after fixing
-- -- Testing with computed columns
-- CREATE TABLE #ComputedColumns (
--     ID INT IDENTITY(1,1),
--     BaseValue DECIMAL(18,4),
--     ComputedMoney AS CAST(BaseValue AS MONEY),
--     ComputedSmallMoney AS CAST(BaseValue AS SMALLMONEY)
-- );
-- GO

-- -- Insert test data
-- INSERT INTO #ComputedColumns (BaseValue)
-- VALUES (1234.5678), (-1234.5678), (0.0), (9999.9999);

-- -- Display computed results
-- SELECT * FROM #ComputedColumns;
-- GO

-- -- Cleanup
-- DROP TABLE #ComputedColumns;
-- GO

-- Advanced scenarios and error handling
-- Create error logging table
CREATE TABLE ConversionErrorLog (
    TestID INT IDENTITY(1,1),
    TestName VARCHAR(100),
    TestValue VARCHAR(MAX),
    TargetType VARCHAR(50),
    ErrorMessage VARCHAR(MAX),
    ErrorNumber INT,
    ErrorSeverity INT,
    ErrorState INT,
    TestTimestamp DATETIME DEFAULT GETDATE()
);
GO

-- Create procedure for safe conversion testing
CREATE PROCEDURE TestMoneyConversionWithErrorHandling
    @TestName VARCHAR(100),
    @TestValue VARCHAR(MAX),
    @TargetType VARCHAR(50)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX) = N'
            SELECT CAST(@TestValue AS ' + @TargetType + ') AS ConversionResult;
        ';
        EXEC sp_executesql @SQL, N'@TestValue VARCHAR(MAX)', @TestValue;
    END TRY
    BEGIN CATCH
        INSERT INTO ConversionErrorLog 
            (TestName, TestValue, TargetType, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
        VALUES 
            (@TestName, @TestValue, @TargetType,
             ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE());
    END CATCH
END;
GO

-- Test various edge cases and error conditions
-- Overflow tests
EXEC TestMoneyConversionWithErrorHandling 
    'Overflow MONEY Max', '922337203685477.5808', 'MONEY';
GO
EXEC TestMoneyConversionWithErrorHandling 
    'Overflow MONEY Min', '-922337203685477.5809', 'MONEY';
GO
EXEC TestMoneyConversionWithErrorHandling 
    'Overflow SMALLMONEY Max', '214748.3648', 'SMALLMONEY';
GO
EXEC TestMoneyConversionWithErrorHandling 
    'Overflow SMALLMONEY Min', '-214748.3649', 'SMALLMONEY';
GO

-- Invalid format tests
EXEC TestMoneyConversionWithErrorHandling 
    'Invalid Characters', 'ABC123', 'MONEY';
GO
EXEC TestMoneyConversionWithErrorHandling 
    'Multiple Decimal Points', '123.45.67', 'MONEY';
GO
EXEC TestMoneyConversionWithErrorHandling 
    'Invalid Currency Format', '$$123.45', 'MONEY';
GO
EXEC TestMoneyConversionWithErrorHandling 
    'Mixed Separators', '1.234,56', 'MONEY';
GO

DROP PROCEDURE TestMoneyConversionWithErrorHandling
GO

DROP TABLE ConversionErrorLog
GO

-- Create table for testing conversions with different collations
CREATE TABLE CollationTest (
    ID INT IDENTITY(1,1),
    StringValue NVARCHAR(50) COLLATE Latin1_General_CI_AI,
    StringValue_CS_AS NVARCHAR(50) COLLATE Latin1_General_CS_AS
);
GO

-- Insert test data with different formats
INSERT INTO CollationTest (StringValue, StringValue_CS_AS)
VALUES 
('$123.45', '$123.45'),
('€123,45', '€123,45'),
('£123.45', '£123.45'),
('¥123.45', '¥123.45');

-- Test conversions with different collations
SELECT 
    ID,
    TRY_CAST(StringValue AS MONEY) AS Money_CI_AI,
    TRY_CAST(StringValue_CS_AS AS MONEY) AS Money_CS_AS
FROM CollationTest;
GO

DROP TABLE CollationTest
GO

-- Test with various number formats and precisions
CREATE TABLE NumberFormatTest (
    ID INT IDENTITY(1,1),
    TestCase VARCHAR(50),
    InputValue VARCHAR(50),
    MoneyResult MONEY NULL,
    SmallMoneyResult SMALLMONEY NULL,
    ConversionSuccess BIT DEFAULT 0
);
GO

-- Insert test cases
INSERT INTO NumberFormatTest (TestCase, InputValue) VALUES
('Standard Format', '1234.56'),
('Scientific Notation', '1.23456E+3'),
('Negative Scientific', '-1.23456E+3'),
('Leading Zeros', '00001234.56'),
('Trailing Zeros', '1234.5600'),
('No Decimal', '1234'),
('Only Decimal', '.56'),
('European Format', '1.234,56'),
('Parentheses Negative', '(1234.56)'),
('Currency Symbol', '$1,234.56'),
('Multiple Grouping', '1,234,567.89'),
('Zero Padded Decimal', '1234.560000000');

-- Perform conversions with error handling
UPDATE NumberFormatTest
SET 
    MoneyResult = TRY_CAST(InputValue AS MONEY),
    SmallMoneyResult = TRY_CAST(InputValue AS SMALLMONEY),
    ConversionSuccess = CASE 
        WHEN TRY_CAST(InputValue AS MONEY) IS NOT NULL 
        OR TRY_CAST(InputValue AS SMALLMONEY) IS NOT NULL 
        THEN 1 
        ELSE 0 
    END;

-- Display results
SELECT * FROM NumberFormatTest ORDER BY ID;
GO

DROP TABLE NumberFormatTest
GO

-- Test arithmetic operations with conversion
CREATE TABLE ArithmeticTest (
    ID INT IDENTITY(1,1),
    Operation VARCHAR(50),
    Value1 VARCHAR(50),
    Value2 VARCHAR(50),
    MoneyResult MONEY NULL,
    SmallMoneyResult SMALLMONEY NULL,
    CalculationSuccess BIT DEFAULT 0
);
GO

-- Insert test cases
INSERT INTO ArithmeticTest (Operation, Value1, Value2) VALUES
('Addition', '123.45', '678.90'),
('Subtraction', '1000.00', '123.45'),
('Multiplication', '123.45', '2'),
('Division', '1000.00', '2'),
('Complex', '123.45', '1.1');

-- Perform calculations with error handling
UPDATE ArithmeticTest
SET 
    MoneyResult = 
        CASE Operation
            WHEN 'Addition' THEN TRY_CAST(Value1 AS MONEY) + TRY_CAST(Value2 AS MONEY)
            WHEN 'Subtraction' THEN TRY_CAST(Value1 AS MONEY) - TRY_CAST(Value2 AS MONEY)
            WHEN 'Multiplication' THEN TRY_CAST(Value1 AS MONEY) * TRY_CAST(Value2 AS MONEY)
            WHEN 'Division' THEN TRY_CAST(Value1 AS MONEY) / TRY_CAST(Value2 AS MONEY)
            WHEN 'Complex' THEN TRY_CAST(Value1 AS MONEY) * TRY_CAST(Value2 AS MONEY) + 
                                TRY_CAST(Value1 AS MONEY)
        END,
    SmallMoneyResult = 
        CASE Operation
            WHEN 'Addition' THEN TRY_CAST(Value1 AS SMALLMONEY) + TRY_CAST(Value2 AS SMALLMONEY)
            WHEN 'Subtraction' THEN TRY_CAST(Value1 AS SMALLMONEY) - TRY_CAST(Value2 AS SMALLMONEY)
            WHEN 'Multiplication' THEN TRY_CAST(Value1 AS SMALLMONEY) * TRY_CAST(Value2 AS SMALLMONEY)
            WHEN 'Division' THEN TRY_CAST(Value1 AS SMALLMONEY) / TRY_CAST(Value2 AS SMALLMONEY)
            WHEN 'Complex' THEN TRY_CAST(Value1 AS SMALLMONEY) * TRY_CAST(Value2 AS SMALLMONEY) + 
                                TRY_CAST(Value1 AS SMALLMONEY)
        END,
    CalculationSuccess = 1;

-- Display results
SELECT * FROM ArithmeticTest ORDER BY ID;
GO

DROP TABLE ArithmeticTest
GO

-- Testing with XML conversions
CREATE TABLE XMLTest (
    ID INT IDENTITY(1,1),
    XMLData XML,
    MoneyValue MONEY,
    SmallMoneyValue SMALLMONEY
);
GO

-- Insert test data
INSERT INTO XMLTest (XMLData)
VALUES 
('<money><value>123.45</value></money>'),
('<money><value>-123.45</value></money>'),
('<money><value>0.00</value></money>'),
('<money><value>922337203685477.5807</value></money>');

-- Update with converted values
UPDATE XMLTest
SET 
    MoneyValue = t.XMLData.value('(//value)[1]', 'MONEY'),
    SmallMoneyValue = t.XMLData.value('(//value)[1]', 'SMALLMONEY')
FROM XMLTest t
WHERE t.XMLData IS NOT NULL;

-- Display results
SELECT * FROM XMLTest;
GO

-- Testing with JSON conversions
CREATE TABLE JSONTest (
    ID INT IDENTITY(1,1),
    JSONData NVARCHAR(MAX),
    MoneyValue MONEY,
    SmallMoneyValue SMALLMONEY
);
GO

-- Insert test data
INSERT INTO JSONTest (JSONData)
VALUES 
('{"value": 123.45}'),
('{"value": -123.45}'),
('{"value": 0.00}'),
('{"value": 922337203685477.5807}');

-- Update with converted values
UPDATE JSONTest
SET 
    MoneyValue = JSON_VALUE(JSONData, '$.value'),
    SmallMoneyValue = JSON_VALUE(JSONData, '$.value')
WHERE JSONData IS NOT NULL;

-- Display results
SELECT * FROM JSONTest;
GO

-- Cleanup
DROP TABLE IF EXISTS XMLTest;
DROP TABLE IF EXISTS JSONTest;
GO

------------------------------------------------------------------------
---- 7. Aggregate Function Tests
------------------------------------------------------------------------







-- CLEANUP
DROP TABLE MoneyTestTable1
GO

-- FK-PK testing

-- delete pkey which is referenced by fkey

-- partitioned table testing on money/smallmoney

-- money/smallmoney as default, check constraints

-- ability to use money/smallmoney as part of table variable

-- select into testing
