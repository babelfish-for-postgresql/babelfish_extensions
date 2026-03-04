-- [BABEL-1627, 2827] Support DATETIME2FROMPARTS Transact-SQL function
select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 0 );
GO

select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 7 );
GO

select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 8 );
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, 0, 0 ) AS Result;
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, 1, 6 ) AS Result;
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, 4567890, 7 ) AS Result;
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, 9999999, 6 ) AS Result;
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, 9999999, 7 ) AS Result;
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, NULL, 7 ) AS Result;
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, 9999999, NULL ) AS Result;
GO

DECLARE @year DECIMAL(4,0) = 2023;
DECLARE @month DECIMAL(2,0) = 3;
DECLARE @day DECIMAL(2,0) = 15;
DECLARE @hour DECIMAL(2,0) = 10;
DECLARE @minute DECIMAL(2,0) = 30;
DECLARE @second DECIMAL(2,0) = 45;
DECLARE @fraction DECIMAL(7,0) = 123456;
DECLARE @precision DECIMAL(1,0) = 6;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS DecimalWholeNumbers;
GO

DECLARE @year NUMERIC(4,0) = 2024;
DECLARE @month NUMERIC(2,0) = 6;
DECLARE @day NUMERIC(2,0) = 20;
DECLARE @hour NUMERIC(2,0) = 14;
DECLARE @minute NUMERIC(2,0) = 25;
DECLARE @second NUMERIC(2,0) = 30;
DECLARE @fraction NUMERIC(7,0) = 987654;
DECLARE @precision NUMERIC(1,0) = 6;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS NumericWholeNumbers;
GO

DECLARE @year DECIMAL(5,1) = 2023.0;
DECLARE @month DECIMAL(3,1) = 3.0;
DECLARE @day DECIMAL(3,1) = 15.0;
DECLARE @hour DECIMAL(3,1) = 10.0;
DECLARE @minute DECIMAL(3,1) = 30.0;
DECLARE @second DECIMAL(3,1) = 45.0;
DECLARE @fraction DECIMAL(8,1) = 123456.0;
DECLARE @precision DECIMAL(2,1) = 6.0;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS DecimalWithZeroScale;
GO

DECLARE @year NUMERIC(6,2) = 2024.00;
DECLARE @month NUMERIC(3,2) = 6.00;
DECLARE @day NUMERIC(4,2) = 20.00;
DECLARE @hour NUMERIC(4,2) = 14.00;
DECLARE @minute NUMERIC(4,2) = 25.00;
DECLARE @second NUMERIC(4,2) = 30.00;
DECLARE @fraction NUMERIC(8,2) = 987654.00;
DECLARE @precision NUMERIC(3,2) = 6.00;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS NumericWithZeroDecimals;
GO

DECLARE @year FLOAT = 2023.0;
DECLARE @month FLOAT = 7.0;
DECLARE @day FLOAT = 10.0;
DECLARE @hour FLOAT = 16.0;
DECLARE @minute FLOAT = 45.0;
DECLARE @second FLOAT = 50.0;
DECLARE @fraction FLOAT = 555555.0;
DECLARE @precision FLOAT = 6.0;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS FloatWholeNumbers;
GO

DECLARE @year REAL = 2025.0;
DECLARE @month REAL = 1.0;
DECLARE @day REAL = 5.0;
DECLARE @hour REAL = 9.0;
DECLARE @minute REAL = 15.0;
DECLARE @second REAL = 20.0;
DECLARE @fraction REAL = 111111.0;
DECLARE @precision REAL = 6.0;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS RealWholeNumbers;
GO

DECLARE @year INT = 2023;
DECLARE @month TINYINT = 8;
DECLARE @day SMALLINT = 25;
DECLARE @hour BIGINT = 18;
DECLARE @minute DECIMAL(2,0) = 40;
DECLARE @second NUMERIC(2,0) = 55;
DECLARE @fraction FLOAT = 777777.0;
DECLARE @precision REAL = 6.0;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS MixedTypesWholeNumbers;
GO

SELECT DATETIME2FROMPARTS(2023.0, 4.0, 18.0, 12.0, 35.0, 40.0, 888888.0, 6.0) AS DirectLiteralsWithZero;
GO

DECLARE @year NUMERIC(10,0) = 2023;
DECLARE @month NUMERIC(10,0) = 11;
DECLARE @day NUMERIC(10,0) = 30;
DECLARE @hour NUMERIC(10,0) = 23;
DECLARE @minute NUMERIC(10,0) = 59;
DECLARE @second NUMERIC(10,0) = 59;
DECLARE @fraction NUMERIC(10,0) = 9999999;
DECLARE @precision NUMERIC(10,0) = 7;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS HighPrecisionZeroScale;
GO

DECLARE @year MONEY = 2023.0000;
DECLARE @month MONEY = 5.0000;
DECLARE @day MONEY = 12.0000;
DECLARE @hour MONEY = 8.0000;
DECLARE @minute MONEY = 30.0000;
DECLARE @second MONEY = 15.0000;
DECLARE @fraction MONEY = 654321.0000;
DECLARE @precision MONEY = 6.0000;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS MoneyTypeWholeNumbers;
GO

DECLARE @year SMALLMONEY = 2024.0000;
DECLARE @month SMALLMONEY = 2.0000;
DECLARE @day SMALLMONEY = 29.0000;
DECLARE @hour SMALLMONEY = 12.0000;
DECLARE @minute SMALLMONEY = 0.0000;
DECLARE @second SMALLMONEY = 0.0000;
DECLARE @fraction SMALLMONEY = 0.0000;
DECLARE @precision SMALLMONEY = 0.0000;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS SmallMoneyTypeWholeNumbers;
GO

DECLARE @year DECIMAL(4,0) = 1;
DECLARE @month DECIMAL(2,0) = 1;
DECLARE @day DECIMAL(2,0) = 1;
DECLARE @hour DECIMAL(2,0) = 0;
DECLARE @minute DECIMAL(2,0) = 0;
DECLARE @second DECIMAL(2,0) = 0;
DECLARE @fraction DECIMAL(7,0) = 0;
DECLARE @precision DECIMAL(1,0) = 0;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS MinimumBoundary;
GO

DECLARE @year NUMERIC(4,0) = 9999;
DECLARE @month NUMERIC(2,0) = 12;
DECLARE @day NUMERIC(2,0) = 31;
DECLARE @hour NUMERIC(2,0) = 23;
DECLARE @minute NUMERIC(2,0) = 59;
DECLARE @second NUMERIC(2,0) = 59;
DECLARE @fraction NUMERIC(7,0) = 999999;
DECLARE @precision NUMERIC(1,0) = 6;

SELECT DATETIME2FROMPARTS(@year, @month, @day, @hour, @minute, @second, @fraction, @precision) AS MaximumBoundary;
GO

DECLARE @year DECIMAL(4,0) = NULL;
DECLARE @month NUMERIC(2,0) = 5;

SELECT DATETIME2FROMPARTS(@year, @month, 10, 12, 30, 45, 123456, 6) AS NullDecimal;
GO

SELECT DATETIME2FROMPARTS(cast(9999 as text ), cast(12 as text), cast(31 as text), cast(23 as text), cast(59 as text), cast(59 as text), cast(999999 as text), cast(6 as text)) AS TextInputs;
GO

SELECT 
    CAST(DATETIME2FROMPARTS(2023, 4, 10, 8, 30, 15, 250250,6) AS DATE) AS CastToDate,
    CAST(DATETIME2FROMPARTS(2023, 4, 10, 8, 30, 15, 250250,6) AS TIME) AS CastToTime,
    CAST(DATETIME2FROMPARTS(2023, 4, 10, 8, 30, 15, 250250,6) AS DATETIME2) AS CastToDatetime2,
    CAST(DATETIME2FROMPARTS(2023, 4, 10, 8, 30, 15, 250250,6) AS SMALLDATETIME) AS CastToSmallDatetime;
GO

SELECT 
    DATEADD(DAY, 1, DATETIME2FROMPARTS(2023, 5, 15, 10, 30, 45, 123123,6)) AS DateAddTest,
    DATEDIFF(DAY, DATETIME2FROMPARTS(2023, 1, 1, 0, 0, 0, 0, 0), DATETIME2FROMPARTS(2023, 12, 31, 23, 59, 59, 999999,6)) AS DateDiffTest;
GO

CREATE TABLE #TestDatetime (ID INT, TestDate DATETIME2);
GO

INSERT INTO #TestDatetime VALUES (1, '2023-06-15 14:30:45.500500');
INSERT INTO #TestDatetime VALUES (2, DATETIME2FROMPARTS(2023, 6, 16, 10, 15, 30, 250250,6));
GO

SELECT ID FROM #TestDatetime WHERE TestDate = DATETIME2FROMPARTS(2023, 6, 15, 14, 30, 45, 500500, 6);
GO

SELECT ID FROM #TestDatetime WHERE TestDate = '2023-06-16 10:15:30.250250';
GO

DROP TABLE #TestDatetime;
GO

SELECT * FROM datetime2fromparts_vu_prepare_v1
GO
DROP VIEW datetime2fromparts_vu_prepare_v1
GO

SELECT * FROM datetime2fromparts_vu_prepare_v2
GO
DROP VIEW datetime2fromparts_vu_prepare_v2
GO

SELECT * FROM datetime2fromparts_vu_prepare_v3
GO
DROP VIEW datetime2fromparts_vu_prepare_v3
GO

EXEC datetime2fromparts_vu_prepare_p1
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p1
GO

EXEC datetime2fromparts_vu_prepare_p2
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p2
GO

EXEC datetime2fromparts_vu_prepare_p3
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p3
GO

EXEC datetime2fromparts_vu_prepare_p4
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p4
GO

SELECT datetime2fromparts_vu_prepare_f1()
GO
DROP FUNCTION datetime2fromparts_vu_prepare_f1()
GO

SELECT datetime2fromparts_vu_prepare_f2()
GO
DROP FUNCTION datetime2fromparts_vu_prepare_f2()
GO