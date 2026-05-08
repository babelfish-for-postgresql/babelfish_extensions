-- Test from tables
SELECT test_value, style_number, 
       CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS converted_value,
       TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS try_converted_value,
       description
FROM money_style_conversion_test
ORDER BY id;
GO

SELECT test_value, style_number,
       CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS converted_value,
       TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS try_converted_value,
       description
FROM smallmoney_style_conversion_test
ORDER BY id;
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

-- Test decimal style (should fail)
SELECT CONVERT(VARCHAR, CAST(123376736.12345678923456789 AS MONEY), 1.8);
GO

SELECT 'style 1' AS test_case, CONVERT(VARCHAR, CAST(123.123 AS MONEY), 1) AS result;
GO

SELECT 'style -1 ' AS test_case, CONVERT(VARCHAR, CAST(123.344 AS MONEY), -1) AS result;
GO

SELECT 'style 2' AS test_case, CONVERT(VARCHAR, CAST(123.345 AS MONEY), 2) AS result;
GO

-- Test negative styles
SELECT 'Negative style -126' AS test_case, CONVERT(VARCHAR, CAST(123 AS MONEY), -126) AS result;
GO

SELECT 'Negative style -126' AS test_case, CONVERT(VARCHAR, CONVERT(MONEY,123), -126) AS result;
GO

SELECT 'Negative style -1' AS test_case, CONVERT(VARCHAR, CAST(123 AS MONEY), -1) AS result;
GO

SELECT 'Negative style -1' AS test_case, CONVERT(VARCHAR, CONVERT(MONEY,123), -1) AS result;
GO

-- Test style 16
SELECT 'Style 16' AS test_case, CONVERT(VARCHAR, CAST($23.12 AS MONEY), 16) AS result;
GO

SELECT 'Style 16' AS test_case, CONVERT(VARCHAR, CONVERT(MONEY,23.12), 16) AS result;
GO

-- Test MONEY conversion with different styles
DECLARE @val MONEY = 1234.1357;
SELECT 'Default style' AS test_case, CONVERT(VARCHAR, @val) AS result;
SELECT 'Style 0' AS test_case, CONVERT(VARCHAR, @val, 0) AS result;
SELECT 'Style 1' AS test_case, CONVERT(VARCHAR, @val, 1) AS result;
SELECT 'Style 2' AS test_case, CONVERT(VARCHAR, @val, 2) AS result;
SELECT 'Style 126' AS test_case, CONVERT(VARCHAR, @val, 126) AS result;
SELECT 'Style -1' AS test_case, CONVERT(VARCHAR, @val, -1) AS result;
SELECT 'Style -126' AS test_case, CONVERT(VARCHAR, @val, -126) AS result;
SELECT 'Style 16' AS test_case, CONVERT(VARCHAR, @val, 16) AS result;
GO

DECLARE @val MONEY = 1234.1357;
SELECT 'Style 1.8' AS test_case, CONVERT(VARCHAR, @val, 1.8) AS result;
GO

-- Test SMALLMONEY conversion with different styles
DECLARE @val SMALLMONEY = 1234.1357;
SELECT 'Default style' AS test_case, CONVERT(VARCHAR, @val) AS result;
SELECT 'Style 0' AS test_case, CONVERT(VARCHAR, @val, 0) AS result;
SELECT 'Style 1' AS test_case, CONVERT(VARCHAR, @val, 1) AS result;
SELECT 'Style 2' AS test_case, CONVERT(VARCHAR, @val, 2) AS result;
SELECT 'Style 126' AS test_case, CONVERT(VARCHAR, @val, 126) AS result;
SELECT 'Style -1' AS test_case, CONVERT(VARCHAR, @val, -1) AS result;
SELECT 'Style -126' AS test_case, CONVERT(VARCHAR, @val, -126) AS result;
SELECT 'Style 16' AS test_case, CONVERT(VARCHAR, @val, 16) AS result;
GO

DECLARE @val SMALLMONEY = 1234.1357;
SELECT 'Style 1.8' AS test_case, CONVERT(VARCHAR, @val, 1.8) AS result;
GO

-- Test edge cases
-- Max SMALLMONEY tests
SELECT 'Max SMALLMONEY Style 1' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), 1) AS result;
SELECT 'Max SMALLMONEY Style 2' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), 2) AS result;
SELECT 'Max SMALLMONEY Style 0' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), 0) AS result;
SELECT 'Max SMALLMONEY Default Style' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY)) AS result;
SELECT 'Max SMALLMONEY Style 126' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), 126) AS result;
SELECT 'Max SMALLMONEY Style -126' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), -126) AS result;
SELECT 'Max SMALLMONEY Style -1' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), -1) AS result;
GO

SELECT 'Max SMALLMONEY Invalid Style -1.8' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), -1.8) AS result;
GO

SELECT 'Max SMALLMONEY Invalid Style 0.23' AS test_case, CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), 0.23) AS result;
GO

-- Min SMALLMONEY tests
SELECT 'Min SMALLMONEY Style 1' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), 1) AS result;
SELECT 'Min SMALLMONEY Style 2' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), 2) AS result;
SELECT 'Min SMALLMONEY Style 0' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), 0) AS result;
SELECT 'Min SMALLMONEY Default Style' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY)) AS result;
SELECT 'Min SMALLMONEY Style 126' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), 126) AS result;
SELECT 'Min SMALLMONEY Style -126' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), -126) AS result;
SELECT 'Min SMALLMONEY Style -1' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), -1) AS result;
GO

SELECT 'Min SMALLMONEY Invalid Style -1.8' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), -1.8) AS result;
GO

SELECT 'Min SMALLMONEY Invalid Style 0.23' AS test_case, CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), 0.23) AS result;
GO


-- Max MONEY tests
SELECT 'Max MONEY Style 1' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), 1) AS result;
SELECT 'Max MONEY Style 2' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), 2) AS result;
SELECT 'Max MONEY Style 0' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), 0) AS result;
SELECT 'Max MONEY Default Style' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY)) AS result;
SELECT 'Max MONEY Style 126' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), 126) AS result;
SELECT 'Max MONEY Style -126' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), -126) AS result;
SELECT 'Max MONEY Style -1' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), -1) AS result;
GO

SELECT 'Max MONEY Invalid Style -1.8' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), -1.8) AS result;
GO

SELECT 'Max MONEY Invalid Style 0.23' AS test_case, CONVERT(VARCHAR, CAST(922337203685477.5807 AS MONEY), 0.23) AS result;
GO


-- Min MONEY tests
SELECT 'Min MONEY Style 1' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), 1) AS result;
SELECT 'Min MONEY Style 2' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), 2) AS result;
SELECT 'Min MONEY Style 0' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), 0) AS result;
SELECT 'Min MONEY Default Style' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY)) AS result;
SELECT 'Min MONEY Style 126' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), 126) AS result;
SELECT 'Min MONEY Style -126' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), -126) AS result;
SELECT 'Min MONEY Style -1' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), -1) AS result;
GO

SELECT 'Min MONEY Invalid Style -1.8' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), -1.8) AS result;
GO

SELECT 'Min MONEY Invalid Style 0.23' AS test_case, CONVERT(VARCHAR, CAST(-922337203685477.5808 AS MONEY), 0.23) AS result;
GO

WITH style_series AS (
    -- Range -130 to -120
    SELECT -130 AS style_num
    UNION ALL SELECT -129 UNION ALL SELECT -128 UNION ALL SELECT -127 UNION ALL SELECT -126
    UNION ALL SELECT -125 UNION ALL SELECT -124 UNION ALL SELECT -123 UNION ALL SELECT -122
    UNION ALL SELECT -121 UNION ALL SELECT -120
    
    -- Range -10 to 10
    UNION ALL SELECT -10 UNION ALL SELECT -9 UNION ALL SELECT -8 UNION ALL SELECT -7
    UNION ALL SELECT -6 UNION ALL SELECT -5 UNION ALL SELECT -4 UNION ALL SELECT -3
    UNION ALL SELECT -2 UNION ALL SELECT -1 UNION ALL SELECT 0 UNION ALL SELECT 1
    UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10
    
    -- Range 120 to 130
    UNION ALL SELECT 120 UNION ALL SELECT 121 UNION ALL SELECT 122 UNION ALL SELECT 123
    UNION ALL SELECT 124 UNION ALL SELECT 125 UNION ALL SELECT 126 UNION ALL SELECT 127
    UNION ALL SELECT 128 UNION ALL SELECT 129 UNION ALL SELECT 130
    
    -- Max and Min INT
    UNION ALL SELECT 32767  -- MAX INT
    UNION ALL SELECT -32767 -- MIN INT
)
SELECT 
    'Style ' + CAST(style_num AS VARCHAR) AS test_case,
    style_num,
    CONVERT(VARCHAR, CAST(1234.5678 AS MONEY), style_num) AS result
FROM style_series
ORDER BY style_num;
GO

WITH style_series AS (
    -- Range -130 to -120
    SELECT -130 AS style_num
    UNION ALL SELECT -129 UNION ALL SELECT -128 UNION ALL SELECT -127 UNION ALL SELECT -126
    UNION ALL SELECT -125 UNION ALL SELECT -124 UNION ALL SELECT -123 UNION ALL SELECT -122
    UNION ALL SELECT -121 UNION ALL SELECT -120
    
    -- Range -10 to 10
    UNION ALL SELECT -10 UNION ALL SELECT -9 UNION ALL SELECT -8 UNION ALL SELECT -7
    UNION ALL SELECT -6 UNION ALL SELECT -5 UNION ALL SELECT -4 UNION ALL SELECT -3
    UNION ALL SELECT -2 UNION ALL SELECT -1 UNION ALL SELECT 0 UNION ALL SELECT 1
    UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10
    
    -- Range 120 to 130
    UNION ALL SELECT 120 UNION ALL SELECT 121 UNION ALL SELECT 122 UNION ALL SELECT 123
    UNION ALL SELECT 124 UNION ALL SELECT 125 UNION ALL SELECT 126 UNION ALL SELECT 127
    UNION ALL SELECT 128 UNION ALL SELECT 129 UNION ALL SELECT 130
    
    -- Max and Min INT
    UNION ALL SELECT 32767  -- MAX INT
    UNION ALL SELECT -32767 -- MIN INT
)
SELECT 
    'Style ' + CAST(style_num AS VARCHAR) AS test_case,
    style_num,
    CONVERT(VARCHAR, CAST(5678.1234 AS SMALLMONEY), style_num) AS result
FROM style_series
ORDER BY style_num;
GO

select convert(varchar, cast(123 as money), NULL)
GO

-- Test DATETIME conversions
SELECT 
    test_value,
    style_number,
    TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS TRY_CONVERT_RESULTS,
    CASE 
        WHEN style_number IS NULL THEN 'NULL style'
        WHEN style_number < 0 OR style_number > 25 THEN 
            CAST(style_number AS VARCHAR) + ' is not a valid style number when converting from DATETIME to a character string.'
        ELSE CONVERT(VARCHAR, test_value, CAST(style_number AS INT))
    END AS CONVERT_RESULTS,
    description
FROM datetime_style_conversion_test
ORDER BY id;
GO

-- Test DATE conversions
SELECT 
    test_value,
    style_number,
    TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS TRY_CONVERT_RESULTS,
    CASE 
        WHEN style_number IS NULL THEN 'NULL style'
        WHEN style_number < 0 OR style_number NOT IN (0,1,2,3,4,5,6,7,10,11,12,23) THEN 
            CAST(style_number AS VARCHAR) + ' is not a valid style number when converting from DATE to a character string.'
        ELSE CONVERT(VARCHAR, test_value, CAST(style_number AS INT))
    END AS CONVERT_RESULTS,
    description
FROM date_style_conversion_test
ORDER BY id;
GO

-- Test TIME conversions
SELECT 
    test_value,
    style_number,
    TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS TRY_CONVERT_RESULTS,
    CASE 
        WHEN style_number IS NULL THEN 'NULL style'
        WHEN style_number < 0 OR style_number NOT IN (0,8,14,24,108,114) THEN 
            CAST(style_number AS VARCHAR) + ' is not a valid style number when converting from TIME to a character string.'
        ELSE CONVERT(VARCHAR, test_value, CAST(style_number AS INT))
    END AS CONVERT_RESULTS,
    description
FROM time_style_conversion_test
ORDER BY id;
GO

-- Test invalid style numbers
SELECT TRY_CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME), 999) AS invalid_style_datetime;
SELECT TRY_CONVERT(VARCHAR, CAST('2023-09-25' AS DATE), 999) AS invalid_style_date;
SELECT TRY_CONVERT(VARCHAR, CAST('14:30:45.1234567' AS TIME), 999) AS invalid_style_time;
GO

SELECT CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME), 999) AS invalid_style_datetime;
GO
SELECT CONVERT(VARCHAR, CAST('2023-09-25' AS DATE), 999) AS invalid_style_date;
GO
SELECT CONVERT(VARCHAR, CAST('14:30:45.1234567' AS TIME), 999) AS invalid_style_time;
GO

-- Test invalid input strings
SELECT TRY_CONVERT(DATETIME, 'invalid_datetime', 0) AS invalid_datetime;
SELECT TRY_CONVERT(DATE, 'invalid_date', 0) AS invalid_date;
SELECT TRY_CONVERT(TIME, 'invalid_time', 0) AS invalid_time;
GO

SELECT CONVERT(DATETIME, 'invalid_datetime', 0) AS invalid_datetime;
GO
SELECT CONVERT(DATE, 'invalid_date', 0) AS invalid_date;
GO
SELECT CONVERT(TIME, 'invalid_time', 0) AS invalid_time;
GO

-- Test DATETIME procedures
EXEC datetime_style_test_p1 '2023-09-25 14:30:45.123', 0;
GO

EXEC datetime_style_test_p1 '2023-09-25 14:30:45.123', -1;
GO

-- Test DATE procedures
EXEC date_style_test_p1 '2023-09-25', 0;
GO

EXEC date_style_test_p1 '2023-09-25', -1;
GO

-- Test TIME procedures
EXEC time_style_test_p1 '14:30:45.1234510', 0;
GO

EXEC time_style_test_p1 '14:30:45.1234510', -1;
GO

-- Test views
SELECT * FROM datetime_style_test_v1;
GO

SELECT * FROM datetime_style_test_v2;
GO

SELECT * FROM datetime_style_test_v3;
GO

SELECT * FROM date_style_test_v1;
GO

SELECT * FROM date_style_test_v2;
GO

SELECT * FROM time_style_test_v1;
GO

SELECT CONVERT(VARCHAR(10),CAST(1234.1234 AS MONEY),1.8);
GO

SELECT TRY_CONVERT(VARCHAR(10),CAST(1234.1234 AS MONEY),1.8);
GO
-- Test NULL values
SELECT 'NULL Money' as test_case, CONVERT(VARCHAR(30), CAST(NULL AS MONEY)) as result;
GO
SELECT 'NULL SmallMoney' as test_case, CONVERT(VARCHAR(30), CAST(NULL AS SMALLMONEY)) as result;
GO
SELECT 'NULL DateTime' as test_case, CONVERT(VARCHAR(30), CAST(NULL AS DATETIME)) as result;
GO
SELECT 'NULL Date' as test_case, CONVERT(VARCHAR(30), CAST(NULL AS DATE)) as result;
GO
SELECT 'NULL Time' as test_case, CONVERT(VARCHAR(30), CAST(NULL AS TIME)) as result;
GO

-- Test extreme values for MONEY
SELECT 'Max MONEY' as test_case, CONVERT(VARCHAR(30), CAST(922337203685477.5807 AS MONEY)) as result;
GO
SELECT 'Min MONEY' as test_case, CONVERT(VARCHAR(30), CAST(-922337203685477.5808 AS MONEY)) as result;
GO
SELECT 'Max MONEY with style 1' as test_case, CONVERT(VARCHAR(30), CAST(922337203685477.5807 AS MONEY), 1) as result;
GO
SELECT 'Min MONEY with style 2' as test_case, CONVERT(VARCHAR(30), CAST(-922337203685477.5808 AS MONEY), 2) as result;
GO

-- Test extreme values for SMALLMONEY
SELECT 'Max SMALLMONEY' as test_case, CONVERT(VARCHAR(30), CAST(214748.3647 AS SMALLMONEY)) as result;
GO
SELECT 'Min SMALLMONEY' as test_case, CONVERT(VARCHAR(30), CAST(-214748.3648 AS SMALLMONEY)) as result;
GO
SELECT 'Max SMALLMONEY with style 1' as test_case, CONVERT(VARCHAR(30), CAST(214748.3647 AS SMALLMONEY), 1) as result;
GO
SELECT 'Min SMALLMONEY with style 2' as test_case, CONVERT(VARCHAR(30), CAST(-214748.3648 AS SMALLMONEY), 2) as result;
GO

-- Test precision and scale
SELECT 'MONEY precision test' as test_case, 
    CONVERT(VARCHAR(30), CAST(0.0001 AS MONEY)) as small_decimal,
    CONVERT(VARCHAR(30), CAST(0.00001 AS MONEY)) as smaller_decimal,
    CONVERT(VARCHAR(30), CAST(0.000001 AS MONEY)) as smallest_decimal;
GO

SELECT 'SMALLMONEY precision test' as test_case, 
    CONVERT(VARCHAR(30), CAST(0.0001 AS SMALLMONEY)) as small_decimal,
    CONVERT(VARCHAR(30), CAST(0.00001 AS SMALLMONEY)) as smaller_decimal,
    CONVERT(VARCHAR(30), CAST(0.000001 AS SMALLMONEY)) as smallest_decimal;
GO

-- Test zero values with different formats
SELECT 'Zero MONEY values' as test_case,
    CONVERT(VARCHAR(30), CAST(0 AS MONEY)) as zero,
    CONVERT(VARCHAR(30), CAST(0.0 AS MONEY)) as zero_decimal,
    CONVERT(VARCHAR(30), CAST(0.00 AS MONEY)) as zero_two_decimal,
    CONVERT(VARCHAR(30), CAST(0.0000 AS MONEY)) as zero_four_decimal;
GO

SELECT 'Zero SMALLMONEY values' as test_case,
    CONVERT(VARCHAR(30), CAST(0 AS SMALLMONEY)) as zero,
    CONVERT(VARCHAR(30), CAST(0.0 AS SMALLMONEY)) as zero_decimal,
    CONVERT(VARCHAR(30), CAST(0.00 AS SMALLMONEY)) as zero_two_decimal,
    CONVERT(VARCHAR(30), CAST(0.0000 AS SMALLMONEY)) as zero_four_decimal;
GO

-- Test datetime extreme values
SELECT 'DateTime extremes' as test_case,
    CONVERT(VARCHAR(30), CAST('1753-01-01' AS DATETIME)) as min_datetime,
    CONVERT(VARCHAR(30), CAST('9999-12-31 23:59:59.997' AS DATETIME)) as max_datetime;
GO

-- Test date extreme values
SELECT 'Date extremes' as test_case,
    CONVERT(VARCHAR(30), CAST('0001-01-01' AS DATE)) as min_date,
    CONVERT(VARCHAR(30), CAST('9999-12-31' AS DATE)) as max_date;
GO

-- Test time extreme values
SELECT 'Time extremes' as test_case,
    CONVERT(VARCHAR(30), CAST('00:00:00.0000000' AS TIME)) as min_time,
    CONVERT(VARCHAR(30), CAST('23:59:59.9999999' AS TIME)) as max_time;
GO

-- Test invalid conversions (these should raise errors)
BEGIN TRY
    SELECT CONVERT(VARCHAR(30), CAST('invalid' AS MONEY));
END TRY
BEGIN CATCH
    SELECT 'Invalid MONEY conversion caught' as test_case, ERROR_MESSAGE() as error;
END CATCH
GO

BEGIN TRY
    SELECT CONVERT(VARCHAR(30), CAST('invalid' AS SMALLMONEY));
END TRY
BEGIN CATCH
    SELECT 'Invalid SMALLMONEY conversion caught' as test_case, ERROR_MESSAGE() as error;
END CATCH
GO

-- Test boundary values near zero
SELECT 'Near-zero values' as test_case,
    CONVERT(VARCHAR(30), CAST(0.0001 AS MONEY)) as small_positive_money,
    CONVERT(VARCHAR(30), CAST(-0.0001 AS MONEY)) as small_negative_money,
    CONVERT(VARCHAR(30), CAST(0.0001 AS SMALLMONEY)) as small_positive_smallmoney,
    CONVERT(VARCHAR(30), CAST(-0.0001 AS SMALLMONEY)) as small_negative_smallmoney;
GO

-- Test rounding behavior
SELECT 'Rounding tests' as test_case,
    CONVERT(VARCHAR(30), CAST(123.4545 AS MONEY)) as money_round,
    CONVERT(VARCHAR(30), CAST(123.4545 AS SMALLMONEY)) as smallmoney_round,
    CONVERT(VARCHAR(30), CAST(123.4555 AS MONEY)) as money_round_up,
    CONVERT(VARCHAR(30), CAST(123.4555 AS SMALLMONEY)) as smallmoney_round_up;
GO

-- Test with different styles for zero and near-zero values
SELECT 'Style tests with zero/near-zero' as test_case,
    CONVERT(VARCHAR(30), CAST(0.00 AS MONEY), 0) as style_0,
    CONVERT(VARCHAR(30), CAST(0.00 AS MONEY), 1) as style_1,
    CONVERT(VARCHAR(30), CAST(0.00 AS MONEY), 2) as style_2,
    CONVERT(VARCHAR(30), CAST(0.0001 AS MONEY), 0) as near_zero_style_0,
    CONVERT(VARCHAR(30), CAST(0.0001 AS MONEY), 1) as near_zero_style_1,
    CONVERT(VARCHAR(30), CAST(0.0001 AS MONEY), 2) as near_zero_style_2;
GO

-- Test datetime precision
SELECT 'DateTime precision tests' as test_case,
    CONVERT(VARCHAR(30), CAST('2023-12-31 23:59:59.997' AS DATETIME)) as max_precision,
    CONVERT(VARCHAR(30), CAST('2023-12-31 23:59:59.993' AS DATETIME)) as near_max_precision,
    CONVERT(VARCHAR(30), CAST('2023-12-31 23:59:59.000' AS DATETIME)) as zero_precision;
GO

-- Test time precision
SELECT 'Time precision tests' as test_case,
    CONVERT(VARCHAR(30), CAST('23:59:59.9999999' AS TIME)) as max_precision,
    CONVERT(VARCHAR(30), CAST('23:59:59.9999990' AS TIME)) as near_max_precision,
    CONVERT(VARCHAR(30), CAST('23:59:59.0000000' AS TIME)) as zero_precision;
GO

-- Test negative decimal style parameters
SELECT 
    test_value,
    style_number,
    TRY_CONVERT(VARCHAR, test_value, CAST(style_number AS INT)) AS try_convert_result,
    description
FROM negative_decimal_style_test
ORDER BY id;
GO

SELECT 
    id,
    money_val,
    CONVERT(VARCHAR(30), money_val) AS money_convert_default,
    TRY_CONVERT(VARCHAR(30), money_val) AS money_try_convert_default,
    CONVERT(VARCHAR(30), money_val, 0) AS money_convert_style0,
    TRY_CONVERT(VARCHAR(30), money_val, 0) AS money_try_convert_style0,
    CONVERT(VARCHAR(30), money_val, 1) AS money_convert_style1,
    TRY_CONVERT(VARCHAR(30), money_val, 1) AS money_try_convert_style1,
    smallmoney_val,
    CONVERT(VARCHAR(30), smallmoney_val) AS smallmoney_convert_default,
    TRY_CONVERT(VARCHAR(30), smallmoney_val) AS smallmoney_try_convert_default,
    CONVERT(VARCHAR(30), smallmoney_val, 0) AS smallmoney_convert_style0,
    TRY_CONVERT(VARCHAR(30), smallmoney_val, 0) AS smallmoney_try_convert_style0,
    description
FROM money_smallmoney_table 
ORDER BY id;
GO

SELECT 
    id,
    date_val,
    CONVERT(VARCHAR(30), date_val) AS date_convert_default,
    TRY_CONVERT(VARCHAR(30), date_val) AS date_try_convert_default,
    CONVERT(VARCHAR(30), date_val, 23) AS date_convert_style23,
    TRY_CONVERT(VARCHAR(30), date_val, 23) AS date_try_convert_style23,
    datetime_val,
    CONVERT(VARCHAR(30), datetime_val) AS datetime_convert_default,
    TRY_CONVERT(VARCHAR(30), datetime_val) AS datetime_try_convert_default,
    CONVERT(VARCHAR(30), datetime_val, 20) AS datetime_convert_style20,
    TRY_CONVERT(VARCHAR(30), datetime_val, 20) AS datetime_try_convert_style20,
    time_val,
    CONVERT(VARCHAR(30), time_val) AS time_convert_default,
    TRY_CONVERT(VARCHAR(30), time_val) AS time_try_convert_default,
    CONVERT(VARCHAR(30), time_val, 8) AS time_convert_style8,
    TRY_CONVERT(VARCHAR(30), time_val, 8) AS time_try_convert_style8,
    description
FROM datetime_date_time_data 
ORDER BY id;
GO

SELECT 
    id,
    money_val,
    CONVERT(CHAR(20), money_val) AS money_to_char,
    TRY_CONVERT(CHAR(20), money_val) AS money_try_to_char,
    CONVERT(NCHAR(20), money_val) AS money_to_nchar,
    TRY_CONVERT(NCHAR(20), money_val) AS money_try_to_nchar,
    CONVERT(NVARCHAR(20), money_val) AS money_to_nvarchar,
    TRY_CONVERT(NVARCHAR(20), money_val) AS money_try_to_nvarchar,
    datetime_val,
    CONVERT(CHAR(30), datetime_val) AS datetime_to_char,
    TRY_CONVERT(CHAR(30), datetime_val) AS datetime_try_to_char,
    CONVERT(NVARCHAR(30), datetime_val, 23) AS datetime_to_nvarchar_style23,
    TRY_CONVERT(NVARCHAR(30), datetime_val, 23) AS datetime_try_to_nvarchar_style23,
    description
FROM char_conversion_test 
ORDER BY id;
GO

-- Test edge style values
SELECT 
    test_value,
    style_number,
    TRY_CONVERT(VARCHAR, test_value, style_number) AS try_convert_result,
    description
FROM edge_style_test
ORDER BY id;
GO

-- Test combined conversions in same query
SELECT 
    id,
    CONVERT(VARCHAR(20), money_val, 0) AS money_style0,
    CONVERT(VARCHAR(20), smallmoney_val, 1) AS smallmoney_style1,
    CONVERT(VARCHAR(30), datetime_val, 20) AS datetime_style20,
    CONVERT(VARCHAR(30), date_val, 23) AS date_style23,
    CONVERT(VARCHAR(30), time_val, 8) AS time_style8,
    description
FROM combined_conversion_test
ORDER BY id;
GO

-- Test NULL style and overflow/underflow
SELECT 
    id,
    TRY_CONVERT(VARCHAR(20), money_val, CAST(style_number AS INT)) AS money_try_convert,
    TRY_CONVERT(VARCHAR(20), smallmoney_val, CAST(style_number AS INT)) AS smallmoney_try_convert,
    TRY_CONVERT(VARCHAR(30), datetime_val, CAST(style_number AS INT)) AS datetime_try_convert,
    TRY_CONVERT(VARCHAR(30), date_val, CAST(style_number AS INT)) AS date_try_convert,
    TRY_CONVERT(VARCHAR(30), time_val, CAST(style_number AS INT)) AS time_try_convert,
    description
FROM null_overflow_test
ORDER BY id;
GO

-- Test CONVERT with NULL and overflow styles (should fail)
SELECT CONVERT(VARCHAR, CAST(1234.56 AS MONEY), NULL) AS null_style_test;
GO

SELECT CONVERT(VARCHAR, CAST(1234.56 AS MONEY), 999999999) AS overflow_style_test;
GO

SELECT CONVERT(VARCHAR, CAST(1234.56 AS MONEY), -999999999) AS underflow_style_test;
GO


-- Test views
SELECT * FROM money_smallmoney_conversions ORDER BY id;
GO

SELECT * FROM datetime_date_time_conversions ORDER BY id;
GO

SELECT * FROM string_conversions ;
GO

-- Test procedures with UDT
DECLARE @money_ranges MoneyRange;
INSERT INTO @money_ranges VALUES 
(0.00, 1000.00, 0),
(-1000.00, 0.00, 1),
(1000.00, 2000.00, 2);

EXEC convert_money_range @money_ranges;
GO

DECLARE @datetime_ranges DateTimeRange;
INSERT INTO @datetime_ranges VALUES 
('2023-01-01', '2023-12-31', 20),
('2024-01-01', '2024-12-31', 21),
('2025-01-01', '2025-12-31', 23);

EXEC convert_datetime_range @datetime_ranges;
GO

-- Test comprehensive conversion procedure
EXEC test_convert_with_style_all_types 
    @money_val = 1234.56,
    @smallmoney_val = 123.45,
    @date_val = '2023-12-25',
    @datetime_val = '2023-12-25 12:34:56.789',
    @time_val = '12:34:56.789',
    @style = 0;
GO

-- Test error cases
EXEC test_convert_with_style_all_types 
    @money_val = 1234.56,
    @smallmoney_val = 123.45,
    @date_val = '2023-12-25',
    @datetime_val = '2023-12-25 12:34:56.789',
    @time_val = '12:34:56.789',
    @style = 999;
GO
-- Test insufficient result space scenarios
SELECT CONVERT(VARCHAR(1), CAST($23.12 AS MONEY), 0);
GO

SELECT CONVERT(CHAR(1), CAST($23345657.12 AS MONEY), 0);
GO

SELECT CONVERT(CHAR(2), CAST($23345657.12 AS MONEY), 0);
GO

SELECT CONVERT(VARCHAR(MAX), CAST($23345657.12 AS MONEY), 0);
GO

-- Test TRY_CONVERT with insufficient space (should return NULL)
SELECT TRY_CONVERT(VARCHAR(1), CAST($23.12 AS MONEY), 0) AS insufficient_space_try_convert;
GO

SELECT TRY_CONVERT(CHAR(1), CAST($23345657.12 AS MONEY), 0) AS insufficient_space_char_try_convert;
GO

-- Test various small lengths with MONEY
SELECT TRY_CONVERT(VARCHAR(3), CAST($1.23 AS MONEY), 0) AS varchar3_result;
GO

SELECT TRY_CONVERT(VARCHAR(5), CAST($12.34 AS MONEY), 0) AS varchar5_result;
GO

-- Test various small lengths with SMALLMONEY
SELECT TRY_CONVERT(VARCHAR(1), CAST(1.23 AS SMALLMONEY), 0) AS smallmoney_varchar1;
GO

SELECT TRY_CONVERT(CHAR(3), CAST(12.34 AS SMALLMONEY), 0) AS smallmoney_char3;
GO

EXEC test_all_conversions 
    @money_val = 1234.56,
    @smallmoney_val = 123.45,
    @date_val = '2023-12-25',
    @datetime_val = '2023-12-25 12:34:56.789',
    @time_val = '12:34:56.789',
    @style = 1;
GO

EXEC test_all_conversions 
    @money_val = -5678.90,
    @smallmoney_val = -234.56,
    @date_val = '2024-02-29',
    @datetime_val = '2024-02-29 23:59:59.997',
    @time_val = '23:59:59.997';
GO

SELECT * FROM string_conversions;
GO
