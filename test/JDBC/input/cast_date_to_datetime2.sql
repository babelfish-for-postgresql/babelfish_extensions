-- Test DATE to DATETIME2 cast with out-of-range dates (BABEL-4527)

-- Out-of-range: year 999999 (exceeds datetime2 max of 9999-12-31)
SELECT CAST(CAST('999999-12-31' AS DATE) AS datetime2);
GO

-- Out-of-range: year 10000 (just past valid range)
SELECT CAST(CAST('10000-01-01' AS DATE) AS datetime2);
GO

-- Valid boundary: max datetime2 date
SELECT CAST(CAST('9999-12-31' AS DATE) AS datetime2);
GO

-- Out-of-range: date before datetime2 min (PostgreSQL min date, 4714-11-24 BC)
SELECT CAST(CAST('4714-11-24 BC' AS DATE) AS datetime2);
GO

-- Valid boundary: min datetime2 date
SELECT CAST(CAST('0001-01-01' AS DATE) AS datetime2);
GO
