-- Test datetime function `datename` with option `timezone offset`

-- Test case for NULL input
SELECT DATENAME(TZOFFSET, NULL);
GO
-- Test case for empty string
SELECT DATENAME(TZOFFSET, '');
GO
-- Test positive/negative offsets
SELECT DATENAME(TZOFFSET, '2025-06-03 14:30:15 +01:59');
GO
select datename(TZoffset, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
SELECT DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 +01:59' AS DATETIMEOFFSET));
GO
SELECT DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 -01:59' AS DATETIMEOFFSET));
GO

-- Test table insertion
INSERT INTO datename_tzoffset_test_cases (date_value, offset_value)
VALUES 
('2025-06-03 14:30:15 +01:30', DATENAME(TZOFFSET, '2025-06-03 14:30:15 +01:30')),
('2025-06-03 14:30:15 -05:00', DATENAME(TZOFFSET, '2025-06-03 14:30:15 -05:00')),
('2016-12-26 23:30:05.523456+08:00', DATENAME(TZOFFSET, '2016-12-26 23:30:05.523456+08:00')),
('2016-12-26 23:30:05.523456+8', DATENAME(TZOFFSET, CAST('2016-12-26 23:30:05.523456+8' AS DATETIMEOFFSET)));
GO
SELECT * FROM datename_tzoffset_test_cases;
GO

-- Test with other functions
SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15 +01:30' AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time');
GO
SELECT DATENAME(TZOFFSET, SWITCHOFFSET(CAST('2025-06-03 14:30:15 +01:30' AS DATETIMEOFFSET), '-08:00'));
GO
SELECT DATENAME(TZOFFSET, TODATETIMEOFFSET(CAST('2025-06-03 14:30:15' AS DATETIME2), '-03:30'));
GO
DECLARE @datestring NVARCHAR(50) = N'2025-06-03 14:30:15.1234567 +05:30';
SELECT DATENAME(TZOFFSET, @datestring);
GO

-- Test non-offset input values with view
SELECT * FROM datename_tzoffset_no_offset_tests_view;
GO

-- Boundary values
    -- min/max values
SELECT DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 +14:00' AS DATETIMEOFFSET));
GO
SELECT DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 -14:00' AS DATETIMEOFFSET));
GO
    -- out of range (BABEL-5827: should throw error)
SELECT DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 +14:01' AS DATETIMEOFFSET));
GO
SELECT DATENAME(TZOFFSET, '2025-06-03 14:30:15 -14:01');
GO

-- Supported date time datatype inputs
SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS DATETIME2)) AS datetime2_type;
GO
SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS DATETIMEOFFSET)) AS datetimeoffset_type;
GO


-- Checking stability of DATENAME for varying configs: 
SELECT * FROM datename_stability_test 
ORDER BY config_type, config_value;
GO

-- Check for any variations in results for same inputs under different settings
-- Expected: DATENAME with DATEFIRST setting
SELECT config_type, test_date, datepart, COUNT(DISTINCT result) as distinct_results
FROM datename_stability_test
GROUP BY config_type, test_date, datepart
HAVING COUNT(DISTINCT result) > 1;
GO

-- Error Scenarios
    -- Unsupported date time datatype inputs
SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15 +01:30' AS DATE)) AS date_type;
GO

SELECT datename(TZOFFSET, CAST('14:30:15' AS TIME)) AS time_type;
GO

SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS DATETIME)) AS datetime_type;
GO

SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS SMALLDATETIME)) AS smalldatetime_type;
GO


    -- Invalid date time inputs
SELECT DATENAME(TZOFFSET, '2025-06-0314:30:15+01:59');
GO

SELECT datename(TZOFFSET, CAST('2025-06-0314:30:15+130' AS DATETIMEOFFSET));
GO

SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15 -16:00' AS DATETIMEOFFSET));
GO

SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15 +10:60' AS DATETIMEOFFSET));
GO

SELECT datename(TZOFFSET, CAST('2025-06-03 14:30:15 +01:30' AS DATETIMEOFFSET) AT TIME ZONE 'Invalid Time Zone');
GO

SELECT datename(TZOFFSET, SWITCHOFFSET(CAST('2025-06-03 14:30:15 +01:30' AS DATETIMEOFFSET), 'Invalid Offset'));
GO

SELECT datename(TZOFFSET, TODATETIMEOFFSET(CAST('2025-06-03 14:30:15' AS DATETIME2), 'Invalid Offset'));
GO