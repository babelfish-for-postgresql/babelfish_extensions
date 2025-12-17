-- [BABEL-1627, 2827] Support DATETIME2FROMPARTS Transact-SQL function
-- Verify NEW behavior - test high fraction values (>32767) work correctly

SELECT * FROM datetime2fromparts_vu_prepare_v1;
GO

SELECT * FROM datetime2fromparts_vu_prepare_v2;
GO

SELECT * FROM datetime2fromparts_vu_prepare_v3;
GO

SELECT * FROM datetime2fromparts_vu_prepare_v4;
GO

SELECT * FROM datetime2fromparts_vu_prepare_v5;
GO

EXEC datetime2fromparts_vu_prepare_p1;
GO

EXEC datetime2fromparts_vu_prepare_p2;
GO

SELECT datetime2fromparts_vu_prepare_f1();
GO

SELECT datetime2fromparts_vu_prepare_f2();
GO

-- Verify high fraction values from table
SELECT 
    ID,
    Fraction,
    DATETIME2FROMPARTS(Year, Month, Day, Hour, Minute, Second, Fraction, Precision) AS ConstructedDateTime,
    Precision AS ExpectedPrecision
FROM datetime2fromparts_vu_prepare_t1
ORDER BY ID;
GO

-- Direct tests for the bug fix - fractions > 32767
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 32768, 5) AS test_32768;
GO

SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 100000, 6) AS test_100000;
GO

SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 1234567, 7) AS test_1234567;
GO

SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 9999999, 7) AS test_9999999_max;
GO

-- Test various precision levels with high fractions
SELECT 
    DATETIME2FROMPARTS(2023, 1, 1, 12, 0, 0, 99999, 5) AS precision_5_frac_99999,
    DATETIME2FROMPARTS(2023, 1, 1, 12, 0, 0, 999999, 6) AS precision_6_frac_999999,
    DATETIME2FROMPARTS(2023, 1, 1, 12, 0, 0, 9999999, 7) AS precision_7_frac_9999999;
GO

-- Test that result string representation is correct
SELECT 
    DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 9999999, 7) AS dt,
    CAST(DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 9999999, 7) AS VARCHAR(30)) AS dt_string;
GO

-- Test edge case: precision 7 with max fractions
SELECT DATETIME2FROMPARTS(2023, 12, 31, 23, 59, 59, 9999999, 7) AS max_datetime_max_fractions;
GO
