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

DROP TABLE MoneyTestTable1
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
UNION ALL
SELECT ID, SmallMoneyVal, 'SMALLMONEY' as Type
FROM MoneyComparisonTest
WHERE SmallMoneyVal > 0
ORDER BY MoneyVal, ID, Type;
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
    END
ORDER BY ValueRange;
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

-- Create test table with various MONEY values
CREATE TABLE money_aggregate_test (
    id INT IDENTITY(1,1),
    money_small MONEY,
    money_large MONEY,
    money_negative MONEY,
    money_zero MONEY,
    money_null MONEY,
    smallmoney_small SMALLMONEY,
    smallmoney_large SMALLMONEY,
    smallmoney_negative SMALLMONEY,
    smallmoney_zero SMALLMONEY,
    smallmoney_null SMALLMONEY,
    category VARCHAR(10)
);

-- Insert test data
INSERT INTO money_aggregate_test (
    money_small, money_large, money_negative, money_zero, money_null,
    smallmoney_small, smallmoney_large, smallmoney_negative, smallmoney_zero, smallmoney_null,
    category
)
VALUES
    (123.45, 922337203685477.00, -123.45, 0.00, NULL,
     123.45, 214748.3647, -123.45, 0.00, NULL,
     'A'),
    (234.56, 922337203685400.00, -234.56, 0.00, NULL,
     234.56, 214748.3640, -234.56, 0.00, NULL,
     'A'),
    (345.67, 922337203685300.00, -345.67, 0.00, NULL,
     345.67, 214748.3630, -345.67, 0.00, NULL,
     'B'),
    (456.78, 922337203685200.00, -456.78, 0.00, NULL,
     456.78, 214748.3620, -456.78, 0.00, NULL,
     'B'),
    (567.89, 922337203685100.00, -567.89, 0.00, NULL,
     567.89, 214748.3610, -567.89, 0.00, NULL,
     'C'),
    (NULL, NULL, NULL, NULL, NULL,
     NULL, NULL, NULL, NULL, NULL,
     'C');

-- SUM function tests
SELECT 'SUM Function Tests' AS test_description;
GO

-- SUM with MONEY types
SELECT 
    SUM(money_small) AS sum_money_small,
    SUM(money_large) AS sum_money_large,
    SUM(money_negative) AS sum_money_negative,
    SUM(money_zero) AS sum_money_zero,
    SUM(money_null) AS sum_money_null
FROM money_aggregate_test;
GO

-- SUM with SMALLMONEY types
SELECT 
    SUM(smallmoney_small) AS sum_smallmoney_small,
    SUM(smallmoney_large) AS sum_smallmoney_large,
    SUM(smallmoney_negative) AS sum_smallmoney_negative,
    SUM(smallmoney_zero) AS sum_smallmoney_zero,
    SUM(smallmoney_null) AS sum_smallmoney_null
FROM money_aggregate_test;
GO

-- SUM with GROUP BY
SELECT 
    category,
    SUM(money_small) AS sum_money_small,
    SUM(smallmoney_small) AS sum_smallmoney_small
FROM money_aggregate_test
GROUP BY category;
GO

-- AVG function tests
SELECT 'AVG Function Tests' AS test_description;
GO

-- AVG with MONEY types
SELECT 
    AVG(money_small) AS avg_money_small,
    AVG(money_large) AS avg_money_large,
    AVG(money_negative) AS avg_money_negative,
    AVG(money_zero) AS avg_money_zero,
    AVG(money_null) AS avg_money_null
FROM money_aggregate_test;
GO

-- AVG with SMALLMONEY types
SELECT 
    AVG(smallmoney_small) AS avg_smallmoney_small,
    AVG(smallmoney_large) AS avg_smallmoney_large,
    AVG(smallmoney_negative) AS avg_smallmoney_negative,
    AVG(smallmoney_zero) AS avg_smallmoney_zero,
    AVG(smallmoney_null) AS avg_smallmoney_null
FROM money_aggregate_test;
GO


-- MIN function tests
SELECT 'MIN Function Tests' AS test_description;
GO

-- MIN with MONEY types
SELECT 
    MIN(money_small) AS min_money_small,
    MIN(money_large) AS min_money_large,
    MIN(money_negative) AS min_money_negative,
    MIN(money_zero) AS min_money_zero,
    MIN(money_null) AS min_money_null
FROM money_aggregate_test;
GO

-- MIN with SMALLMONEY types
SELECT 
    MIN(smallmoney_small) AS min_smallmoney_small,
    MIN(smallmoney_large) AS min_smallmoney_large,
    MIN(smallmoney_negative) AS min_smallmoney_negative,
    MIN(smallmoney_zero) AS min_smallmoney_zero,
    MIN(smallmoney_null) AS min_smallmoney_null
FROM money_aggregate_test;
GO

-- MAX function tests
SELECT 'MAX Function Tests' AS test_description;
GO

-- MAX with MONEY types
SELECT 
    MAX(money_small) AS max_money_small,
    MAX(money_large) AS max_money_large,
    MAX(money_negative) AS max_money_negative,
    MAX(money_zero) AS max_money_zero,
    MAX(money_null) AS max_money_null
FROM money_aggregate_test;
GO

-- MAX with SMALLMONEY types
SELECT 
    MAX(smallmoney_small) AS max_smallmoney_small,
    MAX(smallmoney_large) AS max_smallmoney_large,
    MAX(smallmoney_negative) AS max_smallmoney_negative,
    MAX(smallmoney_zero) AS max_smallmoney_zero,
    MAX(smallmoney_null) AS max_smallmoney_null
FROM money_aggregate_test;
GO

-- COUNT function tests
SELECT 'COUNT Function Tests' AS test_description;
GO

-- COUNT with MONEY types
SELECT 
    COUNT(money_small) AS count_money_small,
    COUNT(money_large) AS count_money_large,
    COUNT(money_negative) AS count_money_negative,
    COUNT(money_zero) AS count_money_zero,
    COUNT(money_null) AS count_money_null,
    COUNT(*) AS count_all_rows
FROM money_aggregate_test;
GO

-- COUNT with SMALLMONEY types
SELECT 
    COUNT(smallmoney_small) AS count_smallmoney_small,
    COUNT(smallmoney_large) AS count_smallmoney_large,
    COUNT(smallmoney_negative) AS count_smallmoney_negative,
    COUNT(smallmoney_zero) AS count_smallmoney_zero,
    COUNT(smallmoney_null) AS count_smallmoney_null,
    COUNT(*) AS count_all_rows
FROM money_aggregate_test;
GO


-- COUNT DISTINCT tests
SELECT 
    COUNT(DISTINCT money_small) AS count_distinct_money_small,
    COUNT(DISTINCT money_zero) AS count_distinct_money_zero,
    COUNT(DISTINCT smallmoney_small) AS count_distinct_smallmoney_small,
    COUNT(DISTINCT smallmoney_zero) AS count_distinct_smallmoney_zero
FROM money_aggregate_test;
GO

-- STDEV and STDEVP function tests
SELECT 'STDEV and STDEVP Function Tests' AS test_description;
GO

-- TODO: File JIRA, Output Difference
-- STDEV with MONEY types
SELECT 
    STDEV(money_small) AS stdev_money_small,
    STDEV(money_large) AS stdev_money_large,
    STDEV(money_negative) AS stdev_money_negative,
    STDEV(money_zero) AS stdev_money_zero
FROM money_aggregate_test;
GO

-- TODO: File JIRA, Output Difference
-- STDEV with SMALLMONEY types
SELECT 
    STDEV(smallmoney_small) AS stdev_smallmoney_small,
    STDEV(smallmoney_large) AS stdev_smallmoney_large,
    STDEV(smallmoney_negative) AS stdev_smallmoney_negative,
    STDEV(smallmoney_zero) AS stdev_smallmoney_zero
FROM money_aggregate_test;
GO

-- TODO: File JIRA, Output Difference
-- STDEVP with MONEY types
SELECT 
    STDEVP(money_small) AS stdevp_money_small,
    STDEVP(money_large) AS stdevp_money_large,
    STDEVP(money_negative) AS stdevp_money_negative,
    STDEVP(money_zero) AS stdevp_money_zero
FROM money_aggregate_test;
GO

-- TODO: File JIRA, Output Difference
-- STDEVP with SMALLMONEY types
SELECT 
    STDEVP(smallmoney_small) AS stdevp_smallmoney_small,
    STDEVP(smallmoney_large) AS stdevp_smallmoney_large,
    STDEVP(smallmoney_negative) AS stdevp_smallmoney_negative,
    STDEVP(smallmoney_zero) AS stdevp_smallmoney_zero
FROM money_aggregate_test;
GO


-- VAR and VARP function tests
SELECT 'VAR and VARP Function Tests' AS test_description;
GO

-- TODO: File JIRA, Output Difference
-- VAR with MONEY types
SELECT 
    VAR(money_small) AS var_money_small,
    VAR(money_large) AS var_money_large,
    VAR(money_negative) AS var_money_negative,
    VAR(money_zero) AS var_money_zero
FROM money_aggregate_test;
GO

-- TODO: File JIRA, Output Difference
-- VAR with SMALLMONEY types
SELECT 
    VAR(smallmoney_small) AS var_smallmoney_small,
    VAR(smallmoney_large) AS var_smallmoney_large,
    VAR(smallmoney_negative) AS var_smallmoney_negative,
    VAR(smallmoney_zero) AS var_smallmoney_zero
FROM money_aggregate_test;
GO

-- TODO: File JIRA, Output Difference
-- VARP with MONEY types
SELECT 
    VARP(money_small) AS varp_money_small,
    VARP(money_large) AS varp_money_large,
    VARP(money_negative) AS varp_money_negative,
    VARP(money_zero) AS varp_money_zero
FROM money_aggregate_test;
GO

-- TODO: File JIRA, Output Difference
-- VARP with SMALLMONEY types
SELECT 
    VARP(smallmoney_small) AS varp_smallmoney_small,
    VARP(smallmoney_large) AS varp_smallmoney_large,
    VARP(smallmoney_negative) AS varp_smallmoney_negative,
    VARP(smallmoney_zero) AS varp_smallmoney_zero
FROM money_aggregate_test;
GO

-- STRING_AGG function tests
SELECT 'STRING_AGG Function Tests' AS test_description;
GO

-- STRING_AGG with MONEY types
SELECT 
    STRING_AGG(CAST(money_small AS VARCHAR(50)), ', ') AS string_agg_money_small,
    STRING_AGG(CAST(money_large AS VARCHAR(50)), ', ') AS string_agg_money_large
FROM money_aggregate_test
WHERE money_small IS NOT NULL;
GO

-- STRING_AGG with SMALLMONEY types
SELECT 
    STRING_AGG(CAST(smallmoney_small AS VARCHAR(50)), ', ') AS string_agg_smallmoney_small,
    STRING_AGG(CAST(smallmoney_large AS VARCHAR(50)), ', ') AS string_agg_smallmoney_large
FROM money_aggregate_test
WHERE smallmoney_small IS NOT NULL;
GO

-- STRING_AGG with GROUP BY
SELECT 
    category,
    STRING_AGG(CAST(money_small AS VARCHAR(50)), ', ') AS string_agg_money,
    STRING_AGG(CAST(smallmoney_small AS VARCHAR(50)), ', ') AS string_agg_smallmoney
FROM money_aggregate_test
WHERE money_small IS NOT NULL
GROUP BY category;
GO

-- STRING_AGG with ORDER BY
SELECT 
    STRING_AGG(CAST(money_small AS VARCHAR(50)), ', ') 
        WITHIN GROUP (ORDER BY money_small) AS ordered_string_agg_money,
    STRING_AGG(CAST(smallmoney_small AS VARCHAR(50)), ', ') 
        WITHIN GROUP (ORDER BY smallmoney_small) AS ordered_string_agg_smallmoney
FROM money_aggregate_test
WHERE money_small IS NOT NULL;
GO

SELECT 'Aggregate Functions with DISTINCT' AS test_description;
GO

-- SUM with DISTINCT
SELECT 
    SUM(DISTINCT money_small) AS sum_distinct_money_small,
    SUM(DISTINCT money_zero) AS sum_distinct_money_zero,
    SUM(DISTINCT smallmoney_small) AS sum_distinct_smallmoney_small,
    SUM(DISTINCT smallmoney_zero) AS sum_distinct_smallmoney_zero
FROM money_aggregate_test;
GO

-- AVG with DISTINCT
SELECT 
    AVG(DISTINCT money_small) AS avg_distinct_money_small,
    AVG(DISTINCT money_zero) AS avg_distinct_money_zero,
    AVG(DISTINCT smallmoney_small) AS avg_distinct_smallmoney_small,
    AVG(DISTINCT smallmoney_zero) AS avg_distinct_smallmoney_zero
FROM money_aggregate_test;
GO

-- MIN with DISTINCT
SELECT 
    MIN(DISTINCT money_small) AS min_distinct_money_small,
    MIN(DISTINCT smallmoney_small) AS min_distinct_smallmoney_small
FROM money_aggregate_test;
GO

-- MAX with DISTINCT
SELECT 
    MAX(DISTINCT money_small) AS max_distinct_money_small,
    MAX(DISTINCT smallmoney_small) AS max_distinct_smallmoney_small
FROM money_aggregate_test;
GO

SELECT 'Aggregate Functions with Filtering' AS test_description;
GO

-- SUM with WHERE clause
SELECT 
    SUM(money_small) AS sum_money_small,
    SUM(smallmoney_small) AS sum_smallmoney_small
FROM money_aggregate_test
WHERE money_small > 300.00;
GO

-- AVG with WHERE clause
SELECT 
    AVG(money_small) AS avg_money_small,
    AVG(smallmoney_small) AS avg_smallmoney_small
FROM money_aggregate_test
WHERE money_small > 300.00;
GO

-- MIN/MAX with WHERE clause
SELECT 
    MIN(money_small) AS min_money_small,
    MIN(smallmoney_small) AS min_smallmoney_small,
    MAX(money_small) AS max_money_small,
    MAX(smallmoney_small) AS max_smallmoney_small
FROM money_aggregate_test
WHERE category = 'A';
GO

-- COUNT with WHERE clause
SELECT 
    COUNT(money_small) AS count_money_small,
    COUNT(smallmoney_small) AS count_smallmoney_small,
    COUNT(*) AS count_all
FROM money_aggregate_test
WHERE money_small BETWEEN 200.00 AND 400.00;
GO

-- Aggregate with HAVING clause
SELECT 
    category,
    SUM(money_small) AS sum_money_small,
    AVG(money_small) AS avg_money_small
FROM money_aggregate_test
GROUP BY category
HAVING SUM(money_small) > 500.00;
GO

SELECT 'Aggregate Functions with Expressions' AS test_description;
GO

-- SUM with expressions
SELECT 
    SUM(money_small * 2) AS sum_double_money,
    SUM(money_small + smallmoney_small) AS sum_money_plus_smallmoney,
    SUM(money_small - money_negative) AS sum_money_minus_negative,
    SUM(CASE WHEN category = 'A' THEN money_small ELSE 0 END) AS sum_category_a,
    SUM(ABS(money_negative)) AS sum_absolute_negative
FROM money_aggregate_test
WHERE money_small IS NOT NULL;
GO

-- AVG with expressions
SELECT 
    AVG(money_small * 2) AS avg_double_money,
    AVG(money_small + smallmoney_small) AS avg_money_plus_smallmoney,
    AVG(CASE WHEN money_small > 300 THEN money_small ELSE NULL END) AS avg_conditional,
    AVG(CAST(money_small AS FLOAT) / 100.0) AS avg_percentage
FROM money_aggregate_test
WHERE money_small IS NOT NULL;
GO

-- Complex calculations
SELECT 
    category,
    SUM(money_small) AS total_amount,
    AVG(money_small) AS average_amount,
    SUM(money_small) / COUNT(*) AS computed_average,
    MAX(money_small) - MIN(money_small) AS amount_range,
    SUM(CASE WHEN money_small > AVG(money_small) OVER() 
             THEN money_small ELSE 0 END) AS sum_above_average
FROM money_aggregate_test
GROUP BY category;
GO

-- Create table for extreme value tests
CREATE TABLE money_extreme_test (
    id INT IDENTITY(1,1),
    max_money MONEY,
    min_money MONEY,
    max_smallmoney SMALLMONEY,
    min_smallmoney SMALLMONEY
);
GO

-- Insert extreme values
INSERT INTO money_extreme_test (
    max_money, min_money, 
    max_smallmoney, min_smallmoney
)
VALUES 
    (922337203685477.5807, -922337203685477.5808,
     214748.3647, -214748.3648),
    (922337203685477.5806, -922337203685477.5807,
     214748.3646, -214748.3647),
    (922337203685477.5805, -922337203685477.5806,
     214748.3645, -214748.3646);

-- Test aggregates with extreme values
SELECT 
    SUM(max_money) AS sum_max_money,
    SUM(min_money) AS sum_min_money,
    SUM(max_smallmoney) AS sum_max_smallmoney,
    SUM(min_smallmoney) AS sum_min_smallmoney,
    AVG(max_money) AS avg_max_money,
    AVG(min_money) AS avg_min_money,
    AVG(max_smallmoney) AS avg_max_smallmoney,
    AVG(min_smallmoney) AS avg_min_smallmoney
FROM money_extreme_test;
GO

-- Test statistical functions with extreme values
SELECT 
    STDEV(max_money) AS stdev_max_money,
    STDEV(min_money) AS stdev_min_money,
    VAR(max_money) AS var_max_money,
    VAR(min_money) AS var_min_money,
    STDEVP(max_smallmoney) AS stdevp_max_smallmoney,
    STDEVP(min_smallmoney) AS stdevp_min_smallmoney,
    VARP(max_smallmoney) AS varp_max_smallmoney,
    VARP(min_smallmoney) AS varp_min_smallmoney
FROM money_extreme_test;
GO

SELECT 'Error Condition and Edge Case Tests' AS test_description;
GO

-- Create table for error testing
CREATE TABLE money_error_test (
    id INT IDENTITY(1,1),
    test_case VARCHAR(100),
    money_val MONEY,
    smallmoney_val SMALLMONEY
);
GO

-- Insert test cases for overflow conditions
INSERT INTO money_error_test (test_case) VALUES 
('Overflow Test - Addition'),
('Overflow Test - Multiplication'),
('Overflow Test - Type Conversion'),
('Division by Zero Test'),
('NULL Aggregation Test');
GO

-- Test overflow conditions with TRY_CONVERT
BEGIN TRY
    -- Attempt to overflow MONEY
    UPDATE money_error_test
    SET money_val = TRY_CONVERT(MONEY, 922337203685477.5808)
    WHERE test_case = 'Overflow Test - Type Conversion';

    -- Attempt to overflow SMALLMONEY
    UPDATE money_error_test
    SET smallmoney_val = TRY_CONVERT(SMALLMONEY, 214748.3648)
    WHERE test_case = 'Overflow Test - Type Conversion';
END TRY
BEGIN CATCH
    INSERT INTO money_error_test (test_case, money_val)
    VALUES ('Error: ' + ERROR_MESSAGE(), NULL);
END CATCH;
GO

-- Test arithmetic overflow conditions
BEGIN TRY
    -- Test MONEY overflow through addition
    WITH MaxValues AS (
        SELECT CAST(922337203685477.5807 AS MONEY) AS max_money
    )
    SELECT SUM(max_money) 
    FROM MaxValues CROSS JOIN (SELECT TOP 2 1 AS n FROM sys.objects) t;
END TRY
BEGIN CATCH
    INSERT INTO money_error_test (test_case, money_val)
    VALUES ('Error in Addition: ' + ERROR_MESSAGE(), NULL);
END CATCH;
GO

-- Test multiplication overflow
BEGIN TRY
    WITH LargeValues AS (
        SELECT CAST(922337203685477.5807 AS MONEY) AS large_money
    )
    SELECT large_money * 2
    FROM LargeValues;
END TRY
BEGIN CATCH
    INSERT INTO money_error_test (test_case, money_val)
    VALUES ('Error in Multiplication: ' + ERROR_MESSAGE(), NULL);
END CATCH;
GO

-- Edge case tests with aggregate functions
SELECT 'Edge Case Aggregate Tests' AS test_description;
GO

-- Test aggregates with single row
SELECT
    SUM(money_val) AS single_sum,
    AVG(money_val) AS single_avg,
    MIN(money_val) AS single_min,
    MAX(money_val) AS single_max,
    COUNT(money_val) AS single_count
FROM money_error_test
WHERE id = 1;
GO

-- Test aggregates with all NULL values
SELECT
    SUM(money_val) AS null_sum,
    AVG(money_val) AS null_avg,
    MIN(money_val) AS null_min,
    MAX(money_val) AS null_max,
    COUNT(money_val) AS null_count,
    COUNT(*) AS total_rows
FROM money_error_test
WHERE money_val IS NULL;
GO

-- Test aggregates with mixed NULL and non-NULL values
SELECT
    COUNT(*) AS total_count,
    COUNT(money_val) AS non_null_count,
    COUNT(CASE WHEN money_val IS NULL THEN 1 END) AS null_count,
    ISNULL(SUM(money_val), 0) AS sum_with_default,
    COALESCE(AVG(money_val), 0) AS avg_with_default
FROM money_error_test;
GO

-- Test boundary conditions
CREATE TABLE money_boundary_test (
    id INT IDENTITY(1,1),
    test_case VARCHAR(100),
    money_val MONEY,
    smallmoney_val SMALLMONEY
);
GO

-- Insert boundary test cases
INSERT INTO money_boundary_test (test_case, money_val, smallmoney_val)
VALUES
('Maximum MONEY', 922337203685477.5807, 214748.3647),
('Minimum MONEY', -922337203685477.5808, -214748.3648),
('Near Maximum MONEY', 922337203685477.5806, 214748.3646),
('Near Minimum MONEY', -922337203685477.5807, -214748.3647),
('Zero', 0.0000, 0.0000),
('Small Positive', 0.0001, 0.0001),
('Small Negative', -0.0001, -0.0001);

-- Test aggregates with boundary values
SELECT
    SUM(money_val) AS boundary_sum_money,
    SUM(smallmoney_val) AS boundary_sum_smallmoney,
    AVG(money_val) AS boundary_avg_money,
    AVG(smallmoney_val) AS boundary_avg_smallmoney,
    MIN(money_val) AS boundary_min_money,
    MIN(smallmoney_val) AS boundary_min_smallmoney,
    MAX(money_val) AS boundary_max_money,
    MAX(smallmoney_val) AS boundary_max_smallmoney
FROM money_boundary_test;
GO

-- Test precision handling
SELECT
    AVG(CAST(money_val AS FLOAT)) AS float_avg,
    CAST(AVG(money_val) AS MONEY) AS money_avg,
    AVG(CAST(smallmoney_val AS FLOAT)) AS float_avg_small,
    CAST(AVG(smallmoney_val) AS SMALLMONEY) AS smallmoney_avg
FROM money_boundary_test;
GO

-- Cleanup operations
DROP TABLE IF EXISTS money_aggregate_test;
GO
DROP TABLE IF EXISTS money_extreme_test;
GO
DROP TABLE IF EXISTS money_error_test;
GO
DROP TABLE IF EXISTS money_boundary_test;
GO


------------------------------------------------------------------------
---- 8. User Defined Type Tests for Money Types
------------------------------------------------------------------------

-- Create user-defined types based on MONEY and SMALLMONEY
CREATE TYPE StandardMoneyUDT FROM MONEY;
GO

CREATE TYPE LimitedMoneyUDT FROM SMALLMONEY;
GO

CREATE TYPE BusinessMoneyUDT FROM MONEY;
GO

CREATE TYPE RetailMoneyUDT FROM SMALLMONEY;
GO

CREATE TYPE PriceUDT FROM MONEY;
GO

CREATE TYPE DiscountUDT FROM SMALLMONEY;
GO

CREATE TYPE CostUDT FROM MONEY;
GO

CREATE TYPE TaxUDT FROM SMALLMONEY;
GO


-- Basic UDT Tests
CREATE TABLE udt_money_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    standard_amount StandardMoneyUDT,
    limited_amount LimitedMoneyUDT,
    business_amount BusinessMoneyUDT,
    retail_amount RetailMoneyUDT
);
GO

-- Test NULL values
INSERT INTO udt_money_test (standard_amount, limited_amount, business_amount, retail_amount)
VALUES (NULL, NULL, NULL, NULL);
GO

-- Validate NULL insertions
SELECT CASE 
    WHEN standard_amount IS NULL AND limited_amount IS NULL 
    AND business_amount IS NULL AND retail_amount IS NULL THEN 'NULL test passed'
    ELSE 'NULL test failed'
END AS null_test_result
FROM udt_money_test WHERE id = 1;
GO

-- Test zero values
INSERT INTO udt_money_test (standard_amount, limited_amount, business_amount, retail_amount)
VALUES (0.00, 0.00, 0.00, 0.00);
GO

-- Validate zero insertions
SELECT CASE 
    WHEN standard_amount = 0.00 AND limited_amount = 0.00 
    AND business_amount = 0.00 AND retail_amount = 0.00 THEN 'Zero test passed'
    ELSE 'Zero test failed'
END AS zero_test_result
FROM udt_money_test WHERE id = 2;
GO

-- Test positive values within range
INSERT INTO udt_money_test (standard_amount, limited_amount, business_amount, retail_amount)
VALUES (123456.7890, 123.4567, 987654.3210, 214.7483);
GO

-- Validate positive value insertions
SELECT CASE 
    WHEN standard_amount = 123456.7890 AND limited_amount = 123.4567 
    AND business_amount = 987654.3210 AND retail_amount = 214.7483 THEN 'Positive value test passed'
    ELSE 'Positive value test failed'
END AS positive_test_result
FROM udt_money_test WHERE id = 3;
GO

-- Test negative values
INSERT INTO udt_money_test (standard_amount, limited_amount, business_amount, retail_amount)
VALUES (-123456.7890, -123.4567, -987654.3210, -214.7483);
GO

-- Validate negative value insertions
SELECT CASE 
    WHEN standard_amount = -123456.7890 AND limited_amount = -123.4567 
    AND business_amount = -987654.3210 AND retail_amount = -214.7483 THEN 'Negative value test passed'
    ELSE 'Negative value test failed'
END AS negative_test_result
FROM udt_money_test WHERE id = 4;
GO

-- Complex UDT Scenarios
CREATE TABLE udt_complex_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    price PriceUDT,
    discount DiscountUDT,
    cost CostUDT,
    tax TaxUDT,
    description VARCHAR(100)
);
GO

-- Test maximum values
INSERT INTO udt_complex_test (price, discount, cost, tax, description)
VALUES 
    (922337203685477.5807, 214748.3647, 922337203685477.5807, 214748.3647, 'Maximum values test');
GO

-- Test minimum values
INSERT INTO udt_complex_test (price, discount, cost, tax, description)
VALUES 
    (-922337203685477.5808, -214748.3648, -922337203685477.5808, -214748.3648, 'Minimum values test');
GO

-- Validate boundary value tests
SELECT 
    CASE 
        WHEN price = 922337203685477.5807 AND discount = 214748.3647 
        AND cost = 922337203685477.5807 AND tax = 214748.3647 
        THEN 'Maximum values test passed'
        ELSE 'Maximum values test failed'
    END AS max_value_test_result,
    CASE 
        WHEN price = -922337203685477.5808 AND discount = -214748.3648 
        AND cost = -922337203685477.5808 AND tax = -214748.3648 
        THEN 'Minimum values test passed'
        ELSE 'Minimum values test failed'
    END AS min_value_test_result
FROM udt_complex_test 
WHERE description IN ('Maximum values test', 'Minimum values test');
GO

-- Test precision handling
INSERT INTO udt_complex_test (price, discount, cost, tax, description)
VALUES 
    (1234.5678, 123.4567, 1234.5678, 123.4567, 'Precision test');
GO

-- Validate precision handling
SELECT 
    CASE 
        WHEN CAST(price AS VARCHAR(20)) = '1234.5678' 
        AND CAST(discount AS VARCHAR(20)) = '123.4567'
        AND CAST(cost AS VARCHAR(20)) = '1234.5678'
        AND CAST(tax AS VARCHAR(20)) = '123.4567' 
        THEN 'Precision test passed'
        ELSE 'Precision test failed'
    END AS precision_test_result
FROM udt_complex_test 
WHERE description = 'Precision test';
GO

-- Test rounding behavior
INSERT INTO udt_complex_test (price, discount, cost, tax, description)
VALUES 
    (1234.56789, 123.45678, 1234.56789, 123.45678, 'Rounding test');
GO

-- Validate rounding behavior
SELECT 
    CASE 
        WHEN price = 1234.5679 AND discount = 123.4568 
        AND cost = 1234.5679 AND tax = 123.4568 
        THEN 'Rounding test passed'
        ELSE 'Rounding test failed'
    END AS rounding_test_result
FROM udt_complex_test 
WHERE description = 'Rounding test';
GO

-- UDT Function Tests
-- Create function to calculate total price with tax
CREATE FUNCTION calculate_total_price
(
    @base_price PriceUDT,
    @tax_rate TaxUDT
)
RETURNS PriceUDT
AS
BEGIN
    RETURN @base_price + (@base_price * (@tax_rate / 100));
END;
GO

-- Create function to calculate discounted price
CREATE FUNCTION calculate_discounted_price
(
    @original_price PriceUDT,
    @discount_amount DiscountUDT
)
RETURNS PriceUDT
AS
BEGIN
    RETURN @original_price - @discount_amount;
END;
GO

-- Test functions with various scenarios
DECLARE @test_price PriceUDT = 100.00;
DECLARE @test_tax TaxUDT = 10.00;
DECLARE @test_discount DiscountUDT = 20.00;

-- Test total price calculation
SELECT 
    CASE 
        WHEN dbo.calculate_total_price(@test_price, @test_tax) = 110.00 
        THEN 'Total price calculation test passed'
        ELSE 'Total price calculation test failed'
    END AS total_price_test_result;
GO

-- Test discount calculation
SELECT 
    CASE 
        WHEN dbo.calculate_discounted_price(100.00, 20.00) = 80.00 
        THEN 'Discount calculation test passed'
        ELSE 'Discount calculation test failed'
    END AS discount_test_result;
GO

-- Test functions with edge cases
DECLARE @max_price PriceUDT = 922337203685477.5807;
DECLARE @max_tax TaxUDT = 214748.3647;

-- Test boundary conditions
BEGIN TRY
    DECLARE @result PriceUDT = dbo.calculate_total_price(@max_price, @max_tax);
    PRINT 'Edge case test failed - Should have thrown overflow error';
END TRY
BEGIN CATCH
    PRINT 'Edge case test passed - Overflow error caught as expected';
END CATCH;
GO

-- UDT Arithmetic Tests
CREATE TABLE udt_arithmetic_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    value1 StandardMoneyUDT,
    value2 LimitedMoneyUDT,
    business_val BusinessMoneyUDT,
    retail_val RetailMoneyUDT
);
GO

-- Insert test values
INSERT INTO udt_arithmetic_test (value1, value2, business_val, retail_val) 
VALUES (1000.00, 100.00, 2000.00, 200.00);
GO

-- Test basic arithmetic operations
SELECT 
    -- Addition tests
    CASE WHEN value1 + value2 = 1100.00 THEN 'Addition test 1 passed'
         ELSE 'Addition test 1 failed' END AS addition_test_1,
    CASE WHEN business_val + retail_val = 2200.00 THEN 'Addition test 2 passed'
         ELSE 'Addition test 2 failed' END AS addition_test_2,

    -- Subtraction tests
    CASE WHEN value1 - value2 = 900.00 THEN 'Subtraction test 1 passed'
         ELSE 'Subtraction test 1 failed' END AS subtraction_test_1,
    CASE WHEN business_val - retail_val = 1800.00 THEN 'Subtraction test 2 passed'
         ELSE 'Subtraction test 2 failed' END AS subtraction_test_2,

    -- Multiplication tests
    CASE WHEN value1 * 2 = 2000.00 THEN 'Multiplication test 1 passed'
         ELSE 'Multiplication test 1 failed' END AS multiplication_test_1,
    CASE WHEN value2 * 0.5 = 50.00 THEN 'Multiplication test 2 passed'
         ELSE 'Multiplication test 2 failed' END AS multiplication_test_2,

    -- Division tests
    CASE WHEN value1 / 2 = 500.00 THEN 'Division test 1 passed'
         ELSE 'Division test 1 failed' END AS division_test_1,
    CASE WHEN business_val / 4 = 500.00 THEN 'Division test 2 passed'
         ELSE 'Division test 2 failed' END AS division_test_2
FROM udt_arithmetic_test;
GO

-- Test arithmetic overflow conditions
CREATE TABLE udt_arithmetic_overflow_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    result_money StandardMoneyUDT,
    result_smallmoney LimitedMoneyUDT
);
GO

-- Test overflow scenarios
BEGIN TRY
    INSERT INTO udt_arithmetic_overflow_test (result_money, result_smallmoney)
    SELECT 
        CAST(922337203685477.5807 AS StandardMoneyUDT) + CAST(0.0001 AS StandardMoneyUDT),
        CAST(214748.3647 AS LimitedMoneyUDT) + CAST(0.0001 AS LimitedMoneyUDT);
    PRINT 'Overflow test failed - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Overflow test passed - Error caught as expected';
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- UDT Constraint Tests
CREATE TABLE udt_constraint_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    retail_price RetailMoneyUDT,
    wholesale_price BusinessMoneyUDT,
    discount_amt DiscountUDT,
    tax_amt TaxUDT,
    CONSTRAINT valid_retail_price CHECK (retail_price > 0),
    CONSTRAINT valid_discount CHECK (discount_amt >= 0 AND discount_amt <= retail_price),
    CONSTRAINT valid_wholesale CHECK (wholesale_price <= retail_price),
    CONSTRAINT valid_tax CHECK (tax_amt >= 0 AND tax_amt <= retail_price * 0.25)
);
GO

-- Test valid constraints
BEGIN TRY
    INSERT INTO udt_constraint_test (retail_price, wholesale_price, discount_amt, tax_amt)
    VALUES (100.00, 80.00, 20.00, 10.00);
    PRINT 'Valid constraint test passed';
END TRY
BEGIN CATCH
    PRINT 'Valid constraint test failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test invalid constraints
BEGIN TRY
    -- Test negative retail price
    INSERT INTO udt_constraint_test (retail_price, wholesale_price, discount_amt, tax_amt)
    VALUES (-100.00, 80.00, 20.00, 10.00);
    PRINT 'Negative retail price constraint test failed';
END TRY
BEGIN CATCH
    PRINT 'Negative retail price constraint test passed';
END CATCH;
GO

BEGIN TRY
    -- Test discount greater than retail price
    INSERT INTO udt_constraint_test (retail_price, wholesale_price, discount_amt, tax_amt)
    VALUES (100.00, 80.00, 120.00, 10.00);
    PRINT 'Invalid discount constraint test failed';
END TRY
BEGIN CATCH
    PRINT 'Invalid discount constraint test passed';
END CATCH;
GO

BEGIN TRY
    -- Test wholesale price greater than retail price
    INSERT INTO udt_constraint_test (retail_price, wholesale_price, discount_amt, tax_amt)
    VALUES (100.00, 120.00, 20.00, 10.00);
    PRINT 'Invalid wholesale price constraint test failed';
END TRY
BEGIN CATCH
    PRINT 'Invalid wholesale price constraint test passed';
END CATCH;
GO

BEGIN TRY
    -- Test tax amount too high
    INSERT INTO udt_constraint_test (retail_price, wholesale_price, discount_amt, tax_amt)
    VALUES (100.00, 80.00, 20.00, 30.00);
    PRINT 'Invalid tax amount constraint test failed';
END TRY
BEGIN CATCH
    PRINT 'Invalid tax amount constraint test passed';
END CATCH;
GO

-- UDT Computed Column Tests
CREATE TABLE udt_computed_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    base_price PriceUDT,
    discount_rate DiscountUDT,
    tax_rate TaxUDT,
    discount_amount AS (base_price * (discount_rate / 100)) PERSISTED,
    tax_amount AS (base_price * (tax_rate / 100)) PERSISTED,
    net_price AS (base_price - (base_price * (discount_rate / 100))) PERSISTED,
    final_price AS (
        (base_price - (base_price * (discount_rate / 100))) * (1 + (tax_rate / 100))
    ) PERSISTED
);
GO

-- Test computed columns with different scenarios
INSERT INTO udt_computed_test (base_price, discount_rate, tax_rate)
VALUES 
    (100.00, 10.00, 20.00),  -- Standard case
    (1000.00, 0.00, 20.00),  -- No discount
    (500.00, 50.00, 0.00),   -- No tax
    (200.00, 0.00, 0.00);    -- No discount and no tax
GO

-- Validate computed columns
SELECT 
    id,
    base_price,
    discount_rate,
    tax_rate,
    discount_amount,
    tax_amount,
    net_price,
    final_price,
    CASE 
        WHEN discount_amount = base_price * (discount_rate / 100) 
        AND tax_amount = base_price * (tax_rate / 100)
        AND net_price = base_price - (base_price * (discount_rate / 100))
        AND final_price = (base_price - (base_price * (discount_rate / 100))) * (1 + (tax_rate / 100))
        THEN 'Computed columns test passed'
        ELSE 'Computed columns test failed'
    END AS computation_test_result
FROM udt_computed_test;
GO

-- UDT Conversion Tests
-- Test explicit conversions between money UDTs
CREATE TABLE udt_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    original_price PriceUDT,
    converted_standard StandardMoneyUDT,
    converted_limited LimitedMoneyUDT,
    converted_business BusinessMoneyUDT,
    converted_retail RetailMoneyUDT
);
GO

-- Test various conversion scenarios
INSERT INTO udt_conversion_test (
    original_price,
    converted_standard,
    converted_limited,
    converted_business,
    converted_retail
)
VALUES
    -- Standard conversion within range
    (123.45, 
     CAST(123.45 AS StandardMoneyUDT),
     CAST(123.45 AS LimitedMoneyUDT),
     CAST(123.45 AS BusinessMoneyUDT),
     CAST(123.45 AS RetailMoneyUDT)),
    
    -- Test maximum values for SMALLMONEY types
    (214748.3647,
     CAST(214748.3647 AS StandardMoneyUDT),
     TRY_CAST(214748.3647 AS LimitedMoneyUDT),
     CAST(214748.3647 AS BusinessMoneyUDT),
     TRY_CAST(214748.3647 AS RetailMoneyUDT));
GO

-- Test conversions from string
BEGIN TRY
    DECLARE @string_price VARCHAR(20) = '1234.56';
    INSERT INTO udt_conversion_test (
        original_price,
        converted_standard,
        converted_limited,
        converted_business,
        converted_retail
    )
    VALUES (
        CAST(@string_price AS PriceUDT),
        CAST(@string_price AS StandardMoneyUDT),
        CAST(@string_price AS LimitedMoneyUDT),
        CAST(@string_price AS BusinessMoneyUDT),
        CAST(@string_price AS RetailMoneyUDT)
    );
    PRINT 'String conversion test passed';
END TRY
BEGIN CATCH
    PRINT 'String conversion test failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test conversions from numeric types
BEGIN TRY
    DECLARE @int_val INT = 1234;
    DECLARE @decimal_val DECIMAL(10,2) = 1234.56;
    DECLARE @float_val FLOAT = 1234.56;
    
    INSERT INTO udt_conversion_test (
        original_price,
        converted_standard,
        converted_limited,
        converted_business,
        converted_retail
    )
    VALUES
    -- From INT
    (CAST(@int_val AS PriceUDT),
     CAST(@int_val AS StandardMoneyUDT),
     CAST(@int_val AS LimitedMoneyUDT),
     CAST(@int_val AS BusinessMoneyUDT),
     CAST(@int_val AS RetailMoneyUDT)),
    
    -- From DECIMAL
    (CAST(@decimal_val AS PriceUDT),
     CAST(@decimal_val AS StandardMoneyUDT),
     CAST(@decimal_val AS LimitedMoneyUDT),
     CAST(@decimal_val AS BusinessMoneyUDT),
     CAST(@decimal_val AS RetailMoneyUDT)),
    
    -- From FLOAT
    (CAST(@float_val AS PriceUDT),
     CAST(@float_val AS StandardMoneyUDT),
     CAST(@float_val AS LimitedMoneyUDT),
     CAST(@float_val AS BusinessMoneyUDT),
     CAST(@float_val AS RetailMoneyUDT));
    
    PRINT 'Numeric conversion tests passed';
END TRY
BEGIN CATCH
    PRINT 'Numeric conversion tests failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Cleanup
-- Drop all test tables
DROP TABLE IF EXISTS udt_money_test;
DROP TABLE IF EXISTS udt_complex_test;
DROP TABLE IF EXISTS udt_arithmetic_test;
DROP TABLE IF EXISTS udt_arithmetic_overflow_test;
DROP TABLE IF EXISTS udt_constraint_test;
DROP TABLE IF EXISTS udt_computed_test;
DROP TABLE IF EXISTS udt_conversion_test;
GO

-- Drop all functions
DROP FUNCTION IF EXISTS calculate_total_price;
DROP FUNCTION IF EXISTS calculate_discounted_price;
GO

-- Drop all user-defined types
DROP TYPE IF EXISTS StandardMoneyUDT;
DROP TYPE IF EXISTS LimitedMoneyUDT;
DROP TYPE IF EXISTS BusinessMoneyUDT;
DROP TYPE IF EXISTS RetailMoneyUDT;
DROP TYPE IF EXISTS PriceUDT;
DROP TYPE IF EXISTS DiscountUDT;
DROP TYPE IF EXISTS CostUDT;
DROP TYPE IF EXISTS TaxUDT;
GO

------------------------------------------------------------------------
---- 9. UNION Tests with Money Types
------------------------------------------------------------------------

---- 9.1 Create User-Defined Types for UNION testing
CREATE TYPE StandardMoneyUDT FROM MONEY;
GO

CREATE TYPE LimitedMoneyUDT FROM SMALLMONEY;
GO

CREATE TYPE BusinessMoneyUDT FROM MONEY;
GO

CREATE TYPE RetailMoneyUDT FROM SMALLMONEY;
GO

---- 9.2 Basic UNION Tests with Direct SELECT and CAST
-- Test: UNION between different money types
SELECT 'MONEY' as source_type, CAST(123456.7890 AS MONEY) as val
UNION
SELECT 'SMALLMONEY', CAST(123456.7890 AS SMALLMONEY)
UNION
SELECT 'MONEYUDT', CAST(123456.7890 AS StandardMoneyUDT)
UNION
SELECT 'SMALLMONEYUDT', CAST(123456.7890 AS LimitedMoneyUDT)
ORDER BY val;
GO

---- 9.3 Complex UNION Tests with Expressions
-- Test: UNION with complex expressions and different money types
SELECT 'EXPR1' as source_type, 
       CAST(1234.56 AS MONEY) * CAST(2.5 AS FLOAT) as val
UNION
SELECT 'EXPR2', 
       CAST(1234.56 AS SMALLMONEY) * CAST(1.5 AS FLOAT)
UNION
SELECT 'EXPR3', 
       CAST(1234.56 AS StandardMoneyUDT) * CAST(3.0 AS FLOAT)
UNION
SELECT 'EXPR4', 
       CAST(1234.56 AS LimitedMoneyUDT) * CAST(2.0 AS FLOAT)
ORDER BY val;
GO

---- 9.4 UNION with UDTs and Mixed Money Types
DECLARE @money_val MONEY = 123456.7890;
DECLARE @smallmoney_val SMALLMONEY = 123.4567;
DECLARE @moneyudt_val StandardMoneyUDT = 123456.7890;
DECLARE @smallmoneyudt_val LimitedMoneyUDT = 123.4567;

-- Test: UNION between money types and UDTs
SELECT 'MONEY_STD' as source_type, @money_val as val
UNION
SELECT 'SMALLMONEY', @smallmoney_val
UNION
SELECT 'MONEYUDT', @moneyudt_val
UNION
SELECT 'SMALLMONEYUDT', @smallmoneyudt_val
ORDER BY val;
GO

---- 9.5 UNION with Mathematical Operations
-- Test: UNION with mathematical operations on money types
SELECT 'MATH1' as source_type,
       CAST(CAST(1234.56 AS MONEY) * 2 AS MONEY) as val
UNION
SELECT 'MATH2',
       CAST(CAST(1234.56 AS SMALLMONEY) / 2 AS SMALLMONEY)
UNION
SELECT 'MATH3',
       CAST(CAST(1234.56 AS StandardMoneyUDT) + 500 AS StandardMoneyUDT)
UNION
SELECT 'MATH4',
       CAST(CAST(1234.56 AS LimitedMoneyUDT) - 500 AS LimitedMoneyUDT)
ORDER BY val;
GO

-- TODO: File JIRA, Output Difference
---- 9.6 UNION with Nested Calculations
-- Test: UNION with CASE expressions for money types
SELECT 'NESTED1' as source_type,
       CASE 
           WHEN CAST(1234.56 AS MONEY) > 1000 
           THEN CAST(1234.56 AS MONEY) * 1.1
           ELSE CAST(1234.56 AS MONEY) * 0.9
       END as val
UNION
SELECT 'NESTED2',
       CASE 
           WHEN CAST(123.45 AS SMALLMONEY) > 100 
           THEN CAST(123.45 AS SMALLMONEY) * 1.2
           ELSE CAST(123.45 AS SMALLMONEY) * 0.8
       END
ORDER BY val;
GO

---- 9.7 UNION with Extreme Values and Calculations
-- Test: UNION with boundary values for money types
SELECT 'MAX_MONEY' as source_type,
       CAST(922337203685477.5807 AS MONEY) as val
UNION
SELECT 'MIN_MONEY',
       CAST(-922337203685477.5808 AS MONEY)
UNION
SELECT 'MAX_SMALLMONEY',
       CAST(214748.3647 AS SMALLMONEY)
UNION
SELECT 'MIN_SMALLMONEY',
       CAST(-214748.3648 AS SMALLMONEY)
ORDER BY val;
GO

-- Test near-boundary values
SELECT 'NEAR_MAX_MONEY' as source_type,
       CAST(922337203685477.5806 AS MONEY) as val
UNION
SELECT 'NEAR_MIN_MONEY',
       CAST(-922337203685477.5807 AS MONEY)
UNION
SELECT 'NEAR_MAX_SMALLMONEY',
       CAST(214748.3646 AS SMALLMONEY)
UNION
SELECT 'NEAR_MIN_SMALLMONEY',
       CAST(-214748.3647 AS SMALLMONEY)
ORDER BY val;
GO

---- 9.8 UNION with Mixed Scale Calculations
-- Test: UNION with different scale calculations for money types
SELECT 'SCALE1' as source_type,
       CAST(CAST(123.45 AS MONEY) * 0.01 AS MONEY) as val
UNION
SELECT 'SCALE2',
       CAST(CAST(123.45 AS SMALLMONEY) * 0.001 AS SMALLMONEY)
UNION
SELECT 'SCALE3',
       CAST(CAST(123.45 AS StandardMoneyUDT) * 0.0001 AS StandardMoneyUDT)
UNION
SELECT 'SCALE4',
       CAST(CAST(123.45 AS LimitedMoneyUDT) * 0.00001 AS LimitedMoneyUDT)
ORDER BY val;
GO

---- 9.9 UNION with NULL and Zero Values
-- Test: UNION with NULL and zero values for money types
SELECT 'NULL_MONEY' as source_type, CAST(NULL AS MONEY) as val
UNION
SELECT 'NULL_SMALLMONEY', CAST(NULL AS SMALLMONEY)
UNION
SELECT 'ZERO_MONEY', CAST(0 AS MONEY)
UNION
SELECT 'ZERO_SMALLMONEY', CAST(0 AS SMALLMONEY)
UNION
SELECT 'ZERO_MONEYUDT', CAST(0 AS StandardMoneyUDT)
UNION
SELECT 'ZERO_SMALLMONEYUDT', CAST(0 AS LimitedMoneyUDT)
ORDER BY CASE WHEN val IS NULL THEN 1 ELSE 0 END, val;
GO

---- 9.10 UNION ALL vs UNION Tests with Money Types
-- Test: Compare UNION ALL with UNION for duplicate money values
SELECT 'MONEY_VAL' as source_type, CAST(123.45 AS MONEY) as val
UNION ALL
SELECT 'SMALLMONEY_VAL', CAST(123.45 AS SMALLMONEY)
UNION ALL
SELECT 'MONEYUDT_VAL', CAST(123.45 AS StandardMoneyUDT)
UNION ALL
SELECT 'SMALLMONEYUDT_VAL', CAST(123.45 AS LimitedMoneyUDT)
ORDER BY source_type;
GO

-- Compare with UNION (removes duplicates)
SELECT 'MONEY_VAL' as source_type, CAST(123.45 AS MONEY) as val
UNION
SELECT 'SMALLMONEY_VAL', CAST(123.45 AS SMALLMONEY)
UNION
SELECT 'MONEYUDT_VAL', CAST(123.45 AS StandardMoneyUDT)
UNION
SELECT 'SMALLMONEYUDT_VAL', CAST(123.45 AS LimitedMoneyUDT)
ORDER BY source_type;
GO

---- 9.11 UNION with Mixed Money and Numeric Types
-- Test: UNION between money types and other numeric types
SELECT 'MONEY_VAL' as source_type, CAST(123.456 AS MONEY) as val
UNION
SELECT 'INT_VAL', CAST(123 AS INT)
UNION
SELECT 'DECIMAL_VAL', CAST(123.456 AS DECIMAL(10,3))
UNION
SELECT 'FLOAT_VAL', CAST(123.456 AS FLOAT)
ORDER BY val;
GO

---- 9.12 UNION with Calculated Columns for Money Types
-- Test: UNION with arithmetic operations on money columns
SELECT 
    'CALC_MONEY' as source_type,
    val,
    val * 2 as doubled,
    val / 2 as halved,
    val + CAST(100 AS MONEY) as added,
    val - CAST(100 AS MONEY) as subtracted
FROM (
    SELECT CAST(123.45 AS MONEY) as val
    UNION
    SELECT CAST(456.78 AS MONEY)
    UNION
    SELECT CAST(123.45 AS SMALLMONEY)
    UNION
    SELECT CAST(456.78 AS StandardMoneyUDT)
) t
ORDER BY val;
GO

---- 9.13 UNION with Rounding Operations
-- Test: UNION with different rounding scenarios
SELECT 'ROUND_MONEY' as source_type, 
       ROUND(CAST(123.456 AS MONEY), 2) as val
UNION
SELECT 'ROUND_SMALLMONEY', 
       ROUND(CAST(123.456 AS SMALLMONEY), 2)
UNION
SELECT 'ROUND_MONEYUDT', 
       ROUND(CAST(123.456 AS StandardMoneyUDT), 2)
UNION
SELECT 'ROUND_SMALLMONEYUDT', 
       ROUND(CAST(123.456 AS LimitedMoneyUDT), 2)
ORDER BY val;
GO

---- 9.14 UNION with Mixed Data Types Resolution
-- Test: Complex type resolution scenarios
DECLARE @money_val MONEY = 123.45;
DECLARE @smallmoney_val SMALLMONEY = 123.45;
DECLARE @moneyudt_val StandardMoneyUDT = 123.45;
DECLARE @smallmoneyudt_val LimitedMoneyUDT = 123.45;

-- Test with different numeric types
SELECT 'MONEY_CONV' as source_type, 
       @money_val as val
UNION
SELECT 'INT_CONV', 
       CAST(123 AS INT)
UNION
SELECT 'DECIMAL_CONV', 
       CAST(123.45 AS DECIMAL(10,2))
UNION
SELECT 'FLOAT_CONV', 
       CAST(123.45 AS FLOAT)
UNION
SELECT 'SMALLMONEY_CONV',
       @smallmoney_val
UNION
SELECT 'MONEYUDT_CONV',
       @moneyudt_val
UNION
SELECT 'SMALLMONEYUDT_CONV',
       @smallmoneyudt_val
ORDER BY val;
GO

-- Test with mathematical functions
SELECT 'MATH_MONEY' as source_type,
       ABS(CAST(-123.45 AS MONEY)) as val
UNION
SELECT 'MATH_SMALLMONEY',
       ABS(CAST(-123.45 AS SMALLMONEY))
UNION
SELECT 'MATH_MONEYUDT',
       ABS(CAST(-123.45 AS StandardMoneyUDT))
UNION
SELECT 'MATH_SMALLMONEYUDT',
       ABS(CAST(-123.45 AS LimitedMoneyUDT))
ORDER BY val;
GO

---- 9.15 UNION with Aggregate Functions
-- Create temporary table for aggregate testing
CREATE TABLE MoneyAggregateTest (
    id INT IDENTITY(1,1),
    money_val MONEY,
    smallmoney_val SMALLMONEY,
    moneyudt_val StandardMoneyUDT,
    smallmoneyudt_val LimitedMoneyUDT
);

INSERT INTO MoneyAggregateTest (money_val, smallmoney_val, moneyudt_val, smallmoneyudt_val)
VALUES 
    (100.00, 100.00, 100.00, 100.00),
    (200.00, 200.00, 200.00, 200.00),
    (300.00, 300.00, 300.00, 300.00);

-- Test aggregates with UNION
SELECT 'SUM' as agg_type,
       SUM(val) as result
FROM (
    SELECT money_val as val FROM MoneyAggregateTest
    UNION
    SELECT smallmoney_val FROM MoneyAggregateTest
    UNION
    SELECT moneyudt_val FROM MoneyAggregateTest
    UNION
    SELECT smallmoneyudt_val FROM MoneyAggregateTest
) t
UNION
SELECT 'AVG',
       AVG(val)
FROM (
    SELECT money_val as val FROM MoneyAggregateTest
    UNION
    SELECT smallmoney_val FROM MoneyAggregateTest
    UNION
    SELECT moneyudt_val FROM MoneyAggregateTest
    UNION
    SELECT smallmoneyudt_val FROM MoneyAggregateTest
) t
ORDER BY agg_type;
GO

DROP TABLE MoneyAggregateTest;
GO

---- 9.16 UNION with Currency Conversions and Calculations
-- Test: Currency conversion scenarios
CREATE TABLE CurrencyRates (
    currency_code VARCHAR(3),
    exchange_rate MONEY
);

INSERT INTO CurrencyRates VALUES 
('USD', 1.00),
('EUR', 0.85),
('GBP', 0.73),
('JPY', 110.25);

-- Test currency conversions with different money types
SELECT 'USD_MONEY' as conversion_type,
       CAST(100.00 AS MONEY) * exchange_rate as converted_amount
FROM CurrencyRates WHERE currency_code = 'EUR'
UNION
SELECT 'USD_SMALLMONEY',
       CAST(100.00 AS SMALLMONEY) * exchange_rate
FROM CurrencyRates WHERE currency_code = 'EUR'
UNION
SELECT 'USD_MONEYUDT',
       CAST(100.00 AS StandardMoneyUDT) * exchange_rate
FROM CurrencyRates WHERE currency_code = 'EUR'
UNION
SELECT 'USD_SMALLMONEYUDT',
       CAST(100.00 AS LimitedMoneyUDT) * exchange_rate
FROM CurrencyRates WHERE currency_code = 'EUR'
ORDER BY converted_amount;
GO

DROP TABLE CurrencyRates;
GO

---- 9.17 UNION with Complex Financial Calculations
-- Test: Financial calculations with different money types
-- Create table for financial calculations
CREATE TABLE FinancialData (
    product_id INT,
    base_price MONEY,
    discount_rate SMALLMONEY,
    tax_rate SMALLMONEY
);

INSERT INTO FinancialData VALUES
(1, 1000.00, 0.10, 0.08),
(2, 2000.00, 0.15, 0.08),
(3, 3000.00, 0.20, 0.08);

-- Complex calculations with UNION
SELECT 'MONEY_CALC' as calc_type,
       (base_price * (1 - discount_rate) * (1 + tax_rate)) as final_price
FROM FinancialData
UNION
SELECT 'SMALLMONEY_CALC',
       CAST((CAST(base_price AS SMALLMONEY) * (1 - discount_rate) * (1 + tax_rate)) AS MONEY)
FROM FinancialData
UNION
SELECT 'MONEYUDT_CALC',
       CAST((CAST(base_price AS StandardMoneyUDT) * (1 - discount_rate) * (1 + tax_rate)) AS MONEY)
FROM FinancialData
UNION
SELECT 'SMALLMONEYUDT_CALC',
       CAST((CAST(base_price AS LimitedMoneyUDT) * (1 - discount_rate) * (1 + tax_rate)) AS MONEY)
FROM FinancialData
ORDER BY final_price;
GO

DROP TABLE FinancialData;
GO

---- 9.18 UNION with Error Handling and Edge Cases
-- Test: Error handling scenarios
BEGIN TRY
    SELECT 'OVERFLOW_TEST' as test_type,
           CAST(922337203685477.5807 AS MONEY) + CAST(0.0001 AS MONEY) as result
    UNION
    SELECT 'NORMAL_TEST',
           CAST(100.00 AS MONEY)
    ORDER BY result;
END TRY
BEGIN CATCH
    SELECT 'OVERFLOW_ERROR' as test_type,
           ERROR_MESSAGE() as result;
END CATCH;
GO

-- Test smallmoney overflow
BEGIN TRY
    SELECT 'SMALLMONEY_OVERFLOW' as test_type,
           CAST(214748.3647 AS SMALLMONEY) + CAST(0.0001 AS SMALLMONEY) as result
    UNION
    SELECT 'NORMAL_TEST',
           CAST(100.00 AS SMALLMONEY)
    ORDER BY result;
END TRY
BEGIN CATCH
    SELECT 'SMALLMONEY_ERROR' as test_type,
           ERROR_MESSAGE() as result;
END CATCH;
GO

---- 9.19 UNION with Dynamic SQL and Money Types
-- Test: Dynamic SQL scenarios
DECLARE @sql NVARCHAR(MAX);
DECLARE @money_val MONEY = 123.45;
DECLARE @smallmoney_val SMALLMONEY = 123.45;

SET @sql = N'
SELECT ''DYNAMIC_MONEY'' as source_type, CAST(' + CAST(@money_val AS NVARCHAR(20)) + ' AS MONEY) as val
UNION
SELECT ''DYNAMIC_SMALLMONEY'', CAST(' + CAST(@smallmoney_val AS NVARCHAR(20)) + ' AS SMALLMONEY)
UNION
SELECT ''STATIC_MONEY'', CAST(123.45 AS MONEY)
ORDER BY val;
';

EXEC sp_executesql @sql;
GO

---- 9.20 UNION with Conditional Aggregates
-- Create test table for conditional aggregates
CREATE TABLE MoneyConditionalTest (
    id INT IDENTITY(1,1),
    money_val MONEY,
    smallmoney_val SMALLMONEY,
    category CHAR(1)
);

INSERT INTO MoneyConditionalTest (money_val, smallmoney_val, category)
VALUES 
(100.00, 100.00, 'A'),
(200.00, 200.00, 'A'),
(300.00, 300.00, 'B'),
(400.00, 400.00, 'B'),
(500.00, 500.00, 'C');

-- Test conditional aggregates with UNION
SELECT 'MONEY_AGG' as agg_type,
       category,
       SUM(money_val) as total
FROM MoneyConditionalTest
GROUP BY category
UNION
SELECT 'SMALLMONEY_AGG',
       category,
       SUM(smallmoney_val)
FROM MoneyConditionalTest
GROUP BY category
ORDER BY category, agg_type;
GO

DROP TABLE MoneyConditionalTest;
GO

---- 9.21 UNION with Window Functions and Money Types
-- Create test table for window functions
CREATE TABLE MoneyWindowTest (
    transaction_id INT IDENTITY(1,1),
    transaction_date DATE,
    money_amount MONEY,
    smallmoney_amount SMALLMONEY,
    moneyudt_amount StandardMoneyUDT,
    smallmoneyudt_amount LimitedMoneyUDT,
    department VARCHAR(10)
);

INSERT INTO MoneyWindowTest (
    transaction_date, 
    money_amount, 
    smallmoney_amount, 
    moneyudt_amount, 
    smallmoneyudt_amount, 
    department
)
VALUES 
('2024-01-01', 1000.00, 100.00, 1000.00, 100.00, 'Sales'),
('2024-01-02', 2000.00, 200.00, 2000.00, 200.00, 'Sales'),
('2024-01-03', 3000.00, 300.00, 3000.00, 300.00, 'IT'),
('2024-01-04', 4000.00, 400.00, 4000.00, 400.00, 'IT'),
('2024-01-05', 5000.00, 500.00, 5000.00, 500.00, 'HR');

-- Test window functions with different money types
SELECT 'MONEY_WINDOW' as window_type,
       department,
       money_amount as amount,
       SUM(money_amount) OVER(PARTITION BY department) as dept_total,
       money_amount / SUM(money_amount) OVER(PARTITION BY department) as percentage
FROM MoneyWindowTest
UNION
SELECT 'SMALLMONEY_WINDOW',
       department,
       smallmoney_amount,
       SUM(smallmoney_amount) OVER(PARTITION BY department),
       smallmoney_amount / SUM(smallmoney_amount) OVER(PARTITION BY department)
FROM MoneyWindowTest
UNION
SELECT 'MONEYUDT_WINDOW',
       department,
       moneyudt_amount,
       SUM(moneyudt_amount) OVER(PARTITION BY department),
       moneyudt_amount / SUM(moneyudt_amount) OVER(PARTITION BY department)
FROM MoneyWindowTest
ORDER BY department, window_type;
GO

---- 9.22 UNION with Pivot Operations
-- Test pivot operations with different money types
SELECT * FROM (
    SELECT 'MONEY' as money_type, department, money_amount
    FROM MoneyWindowTest
    UNION
    SELECT 'SMALLMONEY', department, smallmoney_amount
    FROM MoneyWindowTest
    UNION
    SELECT 'MONEYUDT', department, moneyudt_amount
    FROM MoneyWindowTest
    UNION
    SELECT 'SMALLMONEYUDT', department, smallmoneyudt_amount
    FROM MoneyWindowTest
) AS SourceTable
PIVOT (
    SUM(money_amount)
    FOR department IN ([Sales], [IT], [HR])
) AS PivotTable;
GO

---- 9.23 UNION with Running Totals
-- Test running totals with different money types
SELECT 'MONEY_RUNNING' as total_type,
       transaction_date,
       money_amount as amount,
       SUM(money_amount) OVER(ORDER BY transaction_date) as running_total
FROM MoneyWindowTest
UNION
SELECT 'SMALLMONEY_RUNNING',
       transaction_date,
       smallmoney_amount,
       SUM(smallmoney_amount) OVER(ORDER BY transaction_date)
FROM MoneyWindowTest
ORDER BY transaction_date, total_type;
GO

---- 9.24 UNION with String Formatting and Conversion
-- Test string formatting and conversion scenarios
SELECT 'MONEY_FORMAT' as format_type,
       CAST(money_amount AS VARCHAR(20)) as string_amount,
       CAST(CAST(money_amount AS VARCHAR(20)) AS MONEY) as converted_back
FROM MoneyWindowTest
UNION
SELECT 'SMALLMONEY_FORMAT',
       CAST(smallmoney_amount AS VARCHAR(20)),
       CAST(CAST(smallmoney_amount AS VARCHAR(20)) AS SMALLMONEY)
FROM MoneyWindowTest
UNION
SELECT 'MONEYUDT_FORMAT',
       CAST(moneyudt_amount AS VARCHAR(20)),
       CAST(CAST(moneyudt_amount AS VARCHAR(20)) AS StandardMoneyUDT)
FROM MoneyWindowTest
ORDER BY string_amount;
GO

---- 9.25 UNION with Complex Type Comparisons
-- Test various type comparison scenarios
SELECT 'TYPE_COMPARE' as compare_type,
       CASE 
           WHEN money_amount = CAST(smallmoney_amount AS MONEY) THEN 'Equal'
           WHEN money_amount > CAST(smallmoney_amount AS MONEY) THEN 'Greater'
           ELSE 'Less'
       END as comparison_result,
       money_amount,
       smallmoney_amount
FROM MoneyWindowTest
UNION
SELECT 'UDT_COMPARE',
       CASE 
           WHEN moneyudt_amount = CAST(smallmoneyudt_amount AS StandardMoneyUDT) THEN 'Equal'
           WHEN moneyudt_amount > CAST(smallmoneyudt_amount AS StandardMoneyUDT) THEN 'Greater'
           ELSE 'Less'
       END,
       CAST(moneyudt_amount AS MONEY),
       CAST(smallmoneyudt_amount AS MONEY)
FROM MoneyWindowTest
ORDER BY money_amount;
GO

DROP TABLE MoneyWindowTest;
GO

---- 9.26 Cleanup Operations
-- Drop all user-defined types
DROP TYPE IF EXISTS StandardMoneyUDT;
GO
DROP TYPE IF EXISTS LimitedMoneyUDT;
GO
DROP TYPE IF EXISTS BusinessMoneyUDT;
GO
DROP TYPE IF EXISTS RetailMoneyUDT;
GO


------------------------------------------------------------------------
---- 10.FK-PK Tests for Money Types
------------------------------------------------------------------------

CREATE TABLE MONEY_dt_pkey(
    amount MONEY PRIMARY KEY
);
GO

INSERT INTO MONEY_dt_pkey(amount) VALUES (NULL);
GO
INSERT INTO MONEY_dt_pkey(amount) VALUES (1234.56);
GO
INSERT INTO MONEY_dt_pkey(amount) VALUES (0.00);
GO
INSERT INTO MONEY_dt_pkey(amount) VALUES (-9876.54);
GO

CREATE TABLE MONEY_dt_fkey (
    amount MONEY,
    FOREIGN KEY (amount) REFERENCES MONEY_dt_pkey(amount)
);
GO

INSERT INTO MONEY_dt_fkey(amount) VALUES (NULL);
GO
INSERT INTO MONEY_dt_fkey(amount) VALUES (1234.56);
GO
INSERT INTO MONEY_dt_fkey(amount) VALUES (0.00);
GO
INSERT INTO MONEY_dt_fkey(amount) VALUES (-9876.54);
GO

SELECT * FROM MONEY_dt_fkey ORDER BY amount;
GO

SELECT t1.amount, t2.amount 
FROM MONEY_dt_pkey t1 
JOIN MONEY_dt_fkey t2 ON t1.amount = t2.amount 
ORDER BY t1.amount;
GO

-- Delete pkey which is referenced by fkey
DELETE FROM MONEY_dt_pkey WHERE amount = 1234.56;
GO

DELETE FROM MONEY_dt_fkey WHERE amount = -9876.54;
GO

SELECT * FROM MONEY_dt_fkey ORDER BY amount;
GO

-- FK-PK testing for SMALLMONEY
CREATE TABLE SMALLMONEY_dt_pkey(
    amount SMALLMONEY PRIMARY KEY
);
GO

INSERT INTO SMALLMONEY_dt_pkey(amount) VALUES (NULL);
GO
INSERT INTO SMALLMONEY_dt_pkey(amount) VALUES (123.45);
GO
INSERT INTO SMALLMONEY_dt_pkey(amount) VALUES (0.00);
GO
INSERT INTO SMALLMONEY_dt_pkey(amount) VALUES (-987.65);
GO

CREATE TABLE SMALLMONEY_dt_fkey (
    amount SMALLMONEY,
    FOREIGN KEY (amount) REFERENCES SMALLMONEY_dt_pkey(amount)
);
GO

INSERT INTO SMALLMONEY_dt_fkey(amount) VALUES (NULL);
GO
INSERT INTO SMALLMONEY_dt_fkey(amount) VALUES (123.45);
GO
INSERT INTO SMALLMONEY_dt_fkey(amount) VALUES (0.00);
GO
INSERT INTO SMALLMONEY_dt_fkey(amount) VALUES (-987.65);
GO

SELECT * FROM SMALLMONEY_dt_fkey ORDER BY amount;
GO

SELECT t1.amount, t2.amount 
FROM SMALLMONEY_dt_pkey t1 
JOIN SMALLMONEY_dt_fkey t2 ON t1.amount = t2.amount 
ORDER BY t1.amount;
GO

DROP TABLE MONEY_dt_fkey;
DROP TABLE MONEY_dt_pkey;
DROP TABLE SMALLMONEY_dt_fkey;
DROP TABLE SMALLMONEY_dt_pkey;
GO

------------------------------------------------------------------------
---- 11.Partition Table Tests for Money Types
------------------------------------------------------------------------
CREATE PARTITION FUNCTION MONEY_dt_partition_func (MONEY)
    AS RANGE RIGHT FOR VALUES(
        0.00,
        1000.00,
        10000.00,
        100000.00
    );
GO

CREATE PARTITION SCHEME MONEY_dt_partition_scheme
    AS PARTITION MONEY_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE MONEY_dt_partition(
    amount MONEY,
    category VARCHAR(20)
)
ON MONEY_dt_partition_scheme(amount);
GO

-- Insert test data for different ranges
INSERT INTO MONEY_dt_partition (amount, category) VALUES 
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
       $PARTITION.MONEY_dt_partition_func(amount) AS PartitionNumber
FROM MONEY_dt_partition 
ORDER BY PartitionNumber;
GO

-- Query to show count by partition
SELECT $PARTITION.MONEY_dt_partition_func(amount) AS PartitionNumber, 
       category, 
       COUNT(*) AS AmountCount
FROM MONEY_dt_partition
GROUP BY $PARTITION.MONEY_dt_partition_func(amount), category
ORDER BY PartitionNumber;
GO

-- Partitioned table testing for SMALLMONEY
CREATE PARTITION FUNCTION SMALLMONEY_dt_partition_func (SMALLMONEY)
    AS RANGE RIGHT FOR VALUES(
        0.00,
        100.00,
        1000.00,
        10000.00
    );
GO

CREATE PARTITION SCHEME SMALLMONEY_dt_partition_scheme
    AS PARTITION SMALLMONEY_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE SMALLMONEY_dt_partition(
    amount SMALLMONEY,
    category VARCHAR(20)
)
ON SMALLMONEY_dt_partition_scheme(amount);
GO

-- Insert test data for different ranges
INSERT INTO SMALLMONEY_dt_partition (amount, category) VALUES 
(-100.00, 'Negative'),
(-50.00, 'Negative'),
(0.00, 'Zero'),
(50.00, 'Small'),
(150.00, 'Medium'),
(500.00, 'Medium'),
(1500.00, 'Large'),
(5000.00, 'Large'),
(15000.00, 'Extra Large'),
(20000.00, 'Extra Large');
GO

-- Query to show amounts in each partition
SELECT amount, category, 
       $PARTITION.SMALLMONEY_dt_partition_func(amount) AS PartitionNumber
FROM SMALLMONEY_dt_partition 
ORDER BY PartitionNumber;
GO

-- Query to show count by partition
SELECT $PARTITION.SMALLMONEY_dt_partition_func(amount) AS PartitionNumber, 
       category, 
       COUNT(*) AS AmountCount
FROM SMALLMONEY_dt_partition
GROUP BY $PARTITION.SMALLMONEY_dt_partition_func(amount), category
ORDER BY PartitionNumber;
GO

-- Cleanup

DROP TABLE MONEY_dt_partition;
DROP TABLE SMALLMONEY_dt_partition;
DROP PARTITION SCHEME MONEY_dt_partition_scheme;
DROP PARTITION SCHEME SMALLMONEY_dt_partition_scheme;
DROP PARTITION FUNCTION MONEY_dt_partition_func;
DROP PARTITION FUNCTION SMALLMONEY_dt_partition_func;
GO

------------------------------------------------------------------------
---- 12. Money types as default and check constraints
------------------------------------------------------------------------
CREATE TABLE MONEY_dt(
    a MONEY DEFAULT 100.00, 
    b MONEY, 
    c INT, 
    CHECK (b > 1000.00)
);
GO

INSERT INTO MONEY_dt (b,c) VALUES (1500.00, 1);
GO
INSERT INTO MONEY_dt (b,c) VALUES (500.00, 2);  -- Should fail check constraint
GO

SELECT * FROM MONEY_dt;
GO

DROP TABLE MONEY_dt;
GO

CREATE TABLE SMALLMONEY_dt(
    a SMALLMONEY DEFAULT 100.00, 
    b SMALLMONEY, 
    c INT, 
    CHECK (b > 100.00)
);
GO

INSERT INTO SMALLMONEY_dt (b,c) VALUES (150.00, 1);
GO
INSERT INTO SMALLMONEY_dt (b,c) VALUES (50.00, 2);  -- Should fail check constraint
GO

SELECT * FROM SMALLMONEY_dt;
GO

DROP TABLE SMALLMONEY_dt;
GO

------------------------------------------------------------------------
---- 13. Ability to use money types as part of table variable
------------------------------------------------------------------------
DECLARE @MONEY_dt TABLE (
    a MONEY,
    b SMALLMONEY,
    c MONEY
);

INSERT INTO @MONEY_dt VALUES 
(0.00, 0.00, 0.00),
(NULL, NULL, NULL),
(100.00, 100.00, 100.00),
(922337203685477.5807, 214748.3647, 922337203685477.5807);

SELECT * FROM @MONEY_dt;
GO

-- Select into testing
CREATE TABLE MONEY_dt (
    a MONEY,
    b SMALLMONEY,
    c MONEY,
    d SMALLMONEY,
    e MONEY
);
GO

INSERT INTO MONEY_dt (a, b, c, d, e)
VALUES
(NULL, NULL, NULL, NULL, NULL),
(0.00, 0.00, 0.00, 0.00, 0.00),
(NULL, 0.00, NULL, 0.00, NULL),
(0.00, NULL, 0.00, NULL, 0.00),
(100.00, 100.00, 1000.00, 100.00, 10000.00),
(250.50, 200.50, 2500.50, 200.50, 25000.50),
(500.75, 300.75, 5000.75, 300.75, 50000.75),
(750.25, 400.25, 7500.25, 400.25, 75000.25),
(1000.00, 500.00, 10000.00, 500.00, 100000.00),
(-100.00, -100.00, -1000.00, -100.00, -10000.00),
(922337203685477.5807, 214748.3647, 922337203685477.5807, 214748.3647, 922337203685477.5807),
(-922337203685477.5808, -214748.3648, -922337203685477.5808, -214748.3648, -922337203685477.5808),
(1234.5678, 123.4567, 12345.6789, 123.4567, 123456.7890),
(9999.9999, 999.9999, 99999.9999, 999.9999, 999999.9999);
GO

SELECT * INTO MONEY_dt_derived FROM MONEY_dt;
GO

-- Check column attributes for derived table
SELECT attname, atttypmod 
FROM pg_attribute 
WHERE attrelid = (SELECT oid FROM pg_class WHERE relname = 'money_dt_derived') 
AND attnum > 0;
GO

-- Check column attributes for original table
SELECT attname, atttypmod 
FROM pg_attribute 
WHERE attrelid = (SELECT oid FROM pg_class WHERE relname = 'money_dt') 
AND attnum > 0;
GO

-- Cleanup
DROP TABLE MONEY_dt_derived;
DROP TABLE MONEY_dt;
GO

------------------------------------------------------------------------
---- 14. Index Tests with MONEY and SMALLMONEY Types
------------------------------------------------------------------------

-- Create test tables with money types and indexes
CREATE TABLE money_index_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    money_col MONEY,
    smallmoney_col SMALLMONEY,
    int_col INT,
    decimal_col DECIMAL(19,4),
    float_col FLOAT,
    numeric_col NUMERIC(19,4),
    category VARCHAR(10)
);
GO

-- Create indexes on money columns
CREATE INDEX idx_money ON money_index_test(money_col);
CREATE INDEX idx_smallmoney ON money_index_test(smallmoney_col);
CREATE INDEX idx_composite_money_cat ON money_index_test(money_col, category);
GO

-- Store test values
INSERT INTO money_index_test (
    money_col, smallmoney_col, int_col, decimal_col, float_col, numeric_col, category
) VALUES 
(123.4567, 123.4567, 123, 123.4567, 123.4567, 123.4567, 'CAT-1'),
(500.0000, 500.0000, 500, 500.0000, 500.0000, 500.0000, 'CAT-2'),
(9999.99, 9999.99, 9999, 9999.99, 9999.99, 9999.99, 'CAT-3'),
(100000.00, 100000.00, 100000, 100000.00, 100000.00, 100000.00, 'CAT-4');
GO

SELECT set_config('babelfishpg_tsql.enable_pg_hint', 'on', false);
GO
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false);
GO
SELECT set_config('enable_seqscan', 'off', false);
GO
SELECT set_config('enable_bitmapscan', 'off', false);
GO
SET babelfish_showplan_all ON;
GO

-- Test 1: Direct MONEY comparison (baseline)
SELECT * FROM money_index_test 
WHERE money_col = 123.4567;
GO

-- Test 2: MONEY compared with INTEGER
SELECT * FROM money_index_test 
WHERE money_col = 500;
GO

-- Test 3: MONEY compared with DECIMAL
SELECT * FROM money_index_test 
WHERE money_col = CAST(9999.99 AS DECIMAL(19,4));
GO

-- Test 4: MONEY compared with SMALLMONEY
SELECT * FROM money_index_test 
WHERE money_col = CAST(123.4567 AS SMALLMONEY);
GO


-- Test 5: Range queries with different types
SELECT * FROM money_index_test 
WHERE money_col BETWEEN 100.00 AND 1000.00;
GO

SELECT * FROM money_index_test 
WHERE smallmoney_col BETWEEN CAST(100.00 AS SMALLMONEY) AND CAST(1000.00 AS SMALLMONEY);
GO

-- Test 6: JOIN conditions with different money types
SELECT a.*, b.* 
FROM money_index_test a
JOIN money_index_test b ON a.money_col = b.smallmoney_col;
GO

-- Test 7: Complex conditions mixing types
SELECT * FROM money_index_test 
WHERE money_col = smallmoney_col 
   OR money_col = CAST(float_col AS MONEY)
   OR money_col = CAST(decimal_col AS MONEY);
GO

-- Test 8: Composite index tests
SELECT * FROM money_index_test 
WHERE money_col = 500.00
  AND category = 'CAT-2';
GO

-- Test 9: Index usage with calculations
SELECT * FROM money_index_test 
WHERE money_col = smallmoney_col * 2;
GO

-- Test 10: Index usage with CAST operations
SELECT * FROM money_index_test 
WHERE CAST(money_col AS DECIMAL(19,4)) = decimal_col;
GO

-- Test 11: Implicit conversions
SELECT * FROM money_index_test 
WHERE money_col IN (123.4567, 500.0000, 9999.99);
GO

-- Test 12: SMALLMONEY range tests
SELECT * FROM money_index_test 
WHERE smallmoney_col BETWEEN -214748.3648 AND 214748.3647;
GO

-- Test 13: Index intersection possibilities
SELECT * FROM money_index_test 
WHERE money_col = 123.4567
  AND smallmoney_col = 123.4567;
GO

-- Test 14: ORDER BY with different money types
SELECT * FROM money_index_test 
WHERE money_col > 100
ORDER BY smallmoney_col;
GO

-- Test 15: GROUP BY with money types
SELECT money_col, 
       COUNT(*) as cnt
FROM money_index_test 
GROUP BY money_col;
GO

-- Test 16: Covering index scenarios
SELECT money_col, category 
FROM money_index_test 
WHERE money_col = 500.00;
GO

-- Test 17: Index usage with NULL values
INSERT INTO money_index_test (
    money_col, smallmoney_col, category
) VALUES (NULL, NULL, 'CAT-N');
GO

SELECT * FROM money_index_test 
WHERE money_col IS NULL;
GO

-- Test 18: Index usage with arithmetic operations
SELECT * FROM money_index_test 
WHERE money_col * 2 = smallmoney_col;
GO

-- Test 19: Index usage with string conversions
SELECT * FROM money_index_test 
WHERE CAST(money_col AS VARCHAR(20)) LIKE '123.%';
GO

-- Test 20: Maximum/Minimum value tests
SELECT * FROM money_index_test 
WHERE money_col = 922337203685477.5807;  -- Max MONEY value
GO

SELECT * FROM money_index_test 
WHERE smallmoney_col = 214748.3647;      -- Max SMALLMONEY value
GO

-- Test 21: Rounding behavior tests
SELECT * FROM money_index_test 
WHERE money_col = 123.4567891;           -- Should round to 123.4568
GO

-- Test 22: Aggregate function index usage
SELECT 
    MAX(money_col) as max_money,
    MIN(smallmoney_col) as min_smallmoney,
    AVG(CAST(money_col AS FLOAT)) as avg_money
FROM money_index_test;
GO

-- Reset settings
SET babelfish_showplan_all OFF;
GO
SELECT set_config('babelfishpg_tsql.enable_pg_hint', 'off', false);
GO
SELECT set_config('babelfishpg_tsql.explain_costs', 'on', false);
GO
SELECT set_config('enable_seqscan', 'on', false);
GO
SELECT set_config('enable_bitmapscan', 'on', false);
GO

-- Cleanup
DROP TABLE money_index_test;
GO
