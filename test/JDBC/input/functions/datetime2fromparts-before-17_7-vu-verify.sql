-- [BABEL-1627, 2827] Support DATETIME2FROMPARTS Transact-SQL function
-- Verify datetime2fromparts OLD behavior after upgrade
-- Objects created before upgrade should retain old behavior with fractions <= 32767

SELECT * FROM datetime2fromparts_before_17_7_v1;
GO

SELECT * FROM datetime2fromparts_before_17_7_v2;
GO

SELECT * FROM datetime2fromparts_before_17_7_v3;
GO

SELECT * FROM datetime2fromparts_before_17_7_v4;
GO

EXEC datetime2fromparts_before_17_7_p1;
GO

EXEC datetime2fromparts_before_17_7_p2;
GO

SELECT datetime2fromparts_before_17_7_f1();
GO

SELECT datetime2fromparts_before_17_7_f2();
GO

-- Verify old behavior in table operations (fractions <= 32767 work correctly)
SELECT 
    ID,
    Fraction,
    DATETIME2FROMPARTS(Year, Month, Day, Hour, Minute, Second, Fraction, Precision) AS ConstructedDateTime
FROM datetime2fromparts_before_17_7_t1
ORDER BY ID;
GO

-- Test that small fraction values still work in new queries after upgrade
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 123, 3) AS test_small_fraction;
GO

SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 32767, 5) AS test_smallint_max;
GO
