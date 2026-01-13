-- Create a table to test convert function with various inputs and styles for MONEY and SMALLMONEY types
CREATE TABLE money_style_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value MONEY,
    style_number SQL_VARIANT,
    description VARCHAR(100)
);

INSERT INTO money_style_conversion_test (test_value, style_number, description) VALUES
-- Basic test cases
(1234.1357, 0, 'Basic decimal - style 0'),
(1234.1357, 1, 'Basic decimal - style 1'),
(1234.1357, 2, 'Basic decimal - style 2'),
(1234.1357, 126, 'Basic decimal - style 126'),
(1234.1357, NULL, 'Basic decimal - NULL style'),

-- Negative numbers
(-1234.1357, 0, 'Negative decimal - style 0'),
(-1234.1357, 1, 'Negative decimal - style 1'),
(-1234.1357, 2, 'Negative decimal - style 2'),

-- Edge cases for MONEY
(922337203685477.5807, 0, 'Maximum MONEY value'),
(-922337203685477.5808, 0, 'Minimum MONEY value'),
(922337203685477.5807, 1, 'Maximum MONEY value with comma format'),
(-922337203685477.5808, 1, 'Minimum MONEY value with comma format'),

-- Zero values
(0.00, 0, 'Zero value - style 0'),
(0.00, 1, 'Zero value - style 1'),
(0.00, 2, 'Zero value - style 2'),

-- Decimal places variations
(1234.10, 0, 'Two decimal places'),
(1234.1, 0, 'One decimal place'),
(1234.0000, 0, 'Four trailing zeros'),
(0.1234, 0, 'Leading zero decimal'),

-- Negative styles
(123.45, -1, 'Negative style -1'),
(123.45, -126, 'Negative style -126'),

-- Float-like values
(123.45678901234, 0, 'Float-like decimal'),
(-123.45678901234, 0, 'Negative float-like decimal'),

-- Large numbers with decimals
(123456789.1234, 0, 'Large number with decimals'),
(-123456789.1234, 1, 'Large negative with comma format'),

-- Currency symbol values
($123.45, 0, 'Currency symbol value'),
(-$123.45, 1, 'Negative currency symbol value');
GO

CREATE TABLE smallmoney_style_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value SMALLMONEY,
    style_number SQL_VARIANT,
    description VARCHAR(100)
);

INSERT INTO smallmoney_style_conversion_test (test_value, style_number, description) VALUES
-- Basic test cases
(1234.1357, 0, 'Basic decimal - style 0'),
(1234.1357, 1, 'Basic decimal - style 1'),
(1234.1357, 2, 'Basic decimal - style 2'),
(1234.1357, 126, 'Basic decimal - style 126'),
(1234.1357, NULL, 'Basic decimal - NULL style'),

-- Negative numbers
(-1234.1357, 0, 'Negative decimal - style 0'),
(-1234.1357, 1, 'Negative decimal - style 1'),
(-1234.1357, 2, 'Negative decimal - style 2'),

-- Edge cases for SMALLMONEY
(214748.3647, 0, 'Maximum SMALLMONEY value'),
(-214748.3648, 0, 'Minimum SMALLMONEY value'),
(214748.3647, 1, 'Maximum SMALLMONEY with comma format'),
(-214748.3648, 1, 'Minimum SMALLMONEY with comma format'),

-- Zero values
(0.00, 0, 'Zero value - style 0'),
(0.00, 1, 'Zero value - style 1'),
(0.00, 2, 'Zero value - style 2'),

-- Decimal places variations
(1234.10, 0, 'Two decimal places'),
(1234.1, 0, 'One decimal place'),
(1234.0000, 0, 'Four trailing zeros'),
(0.1234, 0, 'Leading zero decimal'),

-- Negative styles
(123.45, -1, 'Negative style -1'),
(123.45, -126, 'Negative style -126'),

-- Float-like values
(123.4567, 0, 'Float-like decimal'),
(-123.4567, 0, 'Negative float-like decimal'),

-- Currency symbol values
($123.45, 0, 'Currency symbol value'),
(-$123.45, 1, 'Negative currency symbol value');
GO

-- Create views for MONEY tests
CREATE VIEW money_style_test_v1 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY)) AS converted_value;
GO

CREATE VIEW money_style_test_v2 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 0) AS converted_value;
GO

CREATE VIEW money_style_test_v3 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 1) AS converted_value;
GO

CREATE VIEW money_style_test_v4 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 2) AS converted_value;
GO

CREATE VIEW money_style_test_v5 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 126) AS converted_value;
GO

-- Create views for SMALLMONEY tests
CREATE VIEW smallmoney_style_test_v1 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY)) AS converted_value;
GO

CREATE VIEW smallmoney_style_test_v2 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 0) AS converted_value;
GO

CREATE VIEW smallmoney_style_test_v3 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 1) AS converted_value;
GO

CREATE VIEW smallmoney_style_test_v4 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 2) AS converted_value;
GO

CREATE VIEW smallmoney_style_test_v5 AS 
    SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 126) AS converted_value;
GO

-- Create procedures for MONEY tests
CREATE PROCEDURE money_style_test_p1 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY));
GO

CREATE PROCEDURE money_style_test_p2 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), -1);
GO

CREATE PROCEDURE money_style_test_p3 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), -126);
GO

CREATE PROCEDURE money_style_test_p4 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 1.8);
GO

CREATE PROCEDURE money_style_test_p5 AS SELECT CONVERT(VARCHAR, CAST($23.12 AS MONEY), 16);
GO

-- Create procedures for SMALLMONEY tests
CREATE PROCEDURE smallmoney_style_test_p1 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), -2);
GO

CREATE PROCEDURE smallmoney_style_test_p2 AS SELECT CONVERT(VARCHAR, CAST(-1234.1357 AS SMALLMONEY), -126);
GO

CREATE PROCEDURE smallmoney_style_test_p3 AS SELECT CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY), -1);
GO

CREATE PROCEDURE smallmoney_style_test_p4 AS SELECT CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY), -1.8);
GO

CREATE PROCEDURE smallmoney_style_test_p5 AS SELECT CONVERT(VARCHAR, CAST(0.00 AS SMALLMONEY));
GO

--datetime to string conversion with style

CREATE TABLE datetime_style_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value DATETIME,
    style_number SQL_VARIANT,
    description VARCHAR(200)
);
GO

-- Insert test cases for DATETIME
INSERT INTO datetime_style_conversion_test (test_value, style_number, description) VALUES
-- Default style
(CAST('2023-09-25 14:30:45.123' AS DATETIME), NULL, 'Default style (NULL)'),

-- Standard styles
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 0, 'Style 0 - Default'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 1, 'Style 1 - USA mm/dd/yy'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 2, 'Style 2 - ANSI yy.mm.dd'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 3, 'Style 3 - British dd/mm/yy'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 4, 'Style 4 - German dd.mm.yy'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 5, 'Style 5 - Italian dd-mm-yy'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 6, 'Style 6 - dd mon yy'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 7, 'Style 7 - Mon dd, yy'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 8, 'Style 8 - hh:mm:ss'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 9, 'Style 9 - Jan 1 1900'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 10, 'Style 10 - mm-dd-yy'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 11, 'Style 11 - yy/mm/dd'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 12, 'Style 12 - yymmdd'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 13, 'Style 13 - dd mon yyyy hh:mm:ss:mmm(24h)'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 14, 'Style 14 - hh:mm:ss:mmm(24h)'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 20, 'Style 20 - yyyy-mm-dd hh:mm:ss(24h)'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 21, 'Style 21 - yyyy-mm-dd hh:mm:ss.mmm(24h)'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 22, 'Style 22 - mm/dd/yy hh:mm:ss PM'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 23, 'Style 23 - yyyy-mm-dd'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 24, 'Style 24 - hh:mm:ss'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), 25, 'Style 25 - yyyy-mm-dd hh:mm:ss.mmm'),

-- Negative styles
(CAST('2023-09-25 14:30:45.123' AS DATETIME), -1, 'Style -1'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), -2, 'Style -2'),
(CAST('2023-09-25 14:30:45.123' AS DATETIME), -3, 'Style -3'),

-- Edge cases
(CAST('1753-01-01 00:00:00.000' AS DATETIME), 0, 'Min DATETIME value'),
(CAST('9999-12-31 23:59:59.997' AS DATETIME), 0, 'Max DATETIME value'),
(CAST('2023-09-25 23:59:59.997' AS DATETIME), 0, 'Near midnight'),
(CAST('2023-09-25 00:00:00.000' AS DATETIME), 0, 'Midnight exactly'),
(CAST('2024-02-29 14:30:45.123' AS DATETIME), 0, 'Valid leap year date');
GO

--date to string conversion with style
CREATE TABLE date_style_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value DATE,
    style_number SQL_VARIANT,
    description VARCHAR(200)
);
GO

-- Insert test cases for DATE
INSERT INTO date_style_conversion_test (test_value, style_number, description) VALUES
-- Default style
(CAST('2023-09-25' AS DATE), NULL, 'Default style (NULL)'),

-- Standard styles
(CAST('2023-09-25' AS DATE), 0, 'Style 0 - Default'),
(CAST('2023-09-25' AS DATE), 1, 'Style 1 - USA mm/dd/yy'),
(CAST('2023-09-25' AS DATE), 2, 'Style 2 - ANSI yy.mm.dd'),
(CAST('2023-09-25' AS DATE), 3, 'Style 3 - British dd/mm/yy'),
(CAST('2023-09-25' AS DATE), 4, 'Style 4 - German dd.mm.yy'),
(CAST('2023-09-25' AS DATE), 5, 'Style 5 - Italian dd-mm-yy'),
(CAST('2023-09-25' AS DATE), 6, 'Style 6 - dd mon yy'),
(CAST('2023-09-25' AS DATE), 7, 'Style 7 - Mon dd, yy'),
(CAST('2023-09-25' AS DATE), 10, 'Style 10 - mm-dd-yy'),
(CAST('2023-09-25' AS DATE), 11, 'Style 11 - yy/mm/dd'),
(CAST('2023-09-25' AS DATE), 12, 'Style 12 - yymmdd'),
(CAST('2023-09-25' AS DATE), 23, 'Style 23 - yyyy-mm-dd'),

-- Negative styles
(CAST('2023-09-25' AS DATE), -1, 'Style -1'),
(CAST('2023-09-25' AS DATE), -2, 'Style -2'),
(CAST('2023-09-25' AS DATE), -3, 'Style -3'),

-- Edge cases
(CAST('0001-01-01' AS DATE), 0, 'Min DATE value'),
(CAST('9999-12-31' AS DATE), 0, 'Max DATE value'),
(CAST('2024-02-29' AS DATE), 0, 'Valid leap year date');
GO

--time to string conversion with style
CREATE TABLE time_style_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value TIME,
    style_number SQL_VARIANT,
    description VARCHAR(200)
);
GO

INSERT INTO time_style_conversion_test (test_value, style_number, description) VALUES
-- Default style
('14:30:45.1234567', NULL, 'Default style (NULL)'),

-- Standard styles
(CAST('14:30:45.1234511' AS TIME(6)), 0, 'Style 0 - Default'),
(CAST('14:30:45.1234511' AS TIME(6)), 8, 'Style 8 - hh:mm:ss'),
(CAST('14:30:45.1234511' AS TIME(6)), 14, 'Style 14 - hh:mm:ss:mmm(24h)'),
(CAST('14:30:45.1234511' AS TIME(6)), 24, 'Style 24 - hh:mm:ss'),
(CAST('14:30:45.1234511' AS TIME(6)), 108, 'Style 108 - hh:mm:ss'),
(CAST('14:30:45.1234511' AS TIME(6)), 114, 'Style 114 - hh:mm:ss:mmm(24h)'),

-- Negative styles
(CAST('14:30:45.1234511' AS TIME(6)), -1, 'Style -1'),
(CAST('14:30:45.1234511' AS TIME(6)), -2, 'Style -2'),
(CAST('14:30:45.1234511' AS TIME(6)), -3, 'Style -3');
GO

-- Create views for DATETIME tests
CREATE VIEW datetime_style_test_v1 AS 
    SELECT CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME)) AS default_style,
           CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME), 0) AS style_0,
           CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME), 1) AS style_1;
GO

CREATE VIEW datetime_style_test_v2 AS 
    SELECT CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME), 20) AS style_20,
           CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME), 21) AS style_21,
           CONVERT(VARCHAR, CAST('2023-09-25 14:30:45.123' AS DATETIME), 22) AS style_22;
GO

CREATE VIEW datetime_style_test_v3 AS 
    SELECT CONVERT(VARCHAR, CAST('9999-12-31 23:59:59.997' AS DATETIME), 0) AS max_datetime,
           CONVERT(VARCHAR, CAST('1753-01-01 00:00:00.000' AS DATETIME), 0) AS min_datetime;
GO

-- Create views for DATE tests
CREATE VIEW date_style_test_v1 AS 
    SELECT CONVERT(VARCHAR, CAST('2023-09-25' AS DATE)) AS default_style,
           CONVERT(VARCHAR, CAST('2023-09-25' AS DATE), 0) AS style_0,
           CONVERT(VARCHAR, CAST('2023-09-25' AS DATE), 1) AS style_1;
GO

CREATE VIEW date_style_test_v2 AS 
    SELECT CONVERT(VARCHAR, CAST('2023-09-25' AS DATE), 23) AS style_23,
           CONVERT(VARCHAR, CAST('2024-02-29' AS DATE), 23) AS leap_year;
GO

-- Create views for TIME tests
CREATE VIEW time_style_test_v1 AS 
    SELECT CONVERT(VARCHAR, CAST('14:30:45.123451' AS TIME(6)), 8) AS style_8;
GO

-- For DATETIME
CREATE PROCEDURE datetime_style_test_p1
    @input DATETIME,
    @style INT = NULL
AS
BEGIN
    SELECT 
        'Original' AS type,
        @input AS value,
        NULL AS try_convert_result,
        NULL AS convert_result;

    SELECT 
        'Converted' AS type,
        @input AS value,
        TRY_CONVERT(VARCHAR, @input, @style) AS try_convert_result,
        CASE 
            WHEN @style IS NULL THEN 'NULL style'
            ELSE
                TRY_CAST((
                    SELECT CONVERT(VARCHAR, @input, @style)
                ) AS VARCHAR)
        END AS convert_result;
END;
GO

-- For DATE
CREATE PROCEDURE date_style_test_p1
    @input DATE,
    @style INT = NULL
AS
BEGIN
    SELECT 
        'Original' AS type,
        @input AS value,
        NULL AS try_convert_result,
        NULL AS convert_result;

    SELECT 
        'Converted' AS type,
        @input AS value,
        TRY_CONVERT(VARCHAR, @input, @style) AS try_convert_result,
        CASE 
            WHEN @style IS NULL THEN 'NULL style'
            WHEN @style < 0 OR @style NOT IN (0,1,2,3,4,5,6,7,10,11,12,23) THEN 
                CAST(@style AS VARCHAR) + ' is not a valid style number when converting from DATE to a character string.'
            ELSE
                TRY_CAST((
                    SELECT CONVERT(VARCHAR, @input, @style)
                ) AS VARCHAR)
        END AS convert_result;
END;
GO

-- For TIME
CREATE PROCEDURE time_style_test_p1
    @input TIME,
    @style INT = NULL
AS
BEGIN
    SELECT 
        'Original' AS type,
        @input AS value,
        NULL AS try_convert_result,
        NULL AS convert_result;

    SELECT 
        'Converted' AS type,
        @input AS value,
        TRY_CONVERT(VARCHAR, @input, @style) AS try_convert_result,
        CASE 
            WHEN @style IS NULL THEN 'NULL style'
            WHEN @style < 0 OR @style NOT IN (0,8,14,24,108,114) THEN 
                CAST(@style AS VARCHAR) + ' is not a valid style number when converting from TIME to a character string.'
            ELSE
                TRY_CAST((
                    SELECT CONVERT(VARCHAR, @input, @style)
                ) AS VARCHAR)
        END AS convert_result;
END;
GO

-- dependent tests

-- Create User-Defined Types
CREATE TYPE MoneyRange AS TABLE (
    min_value MONEY,
    max_value MONEY,
    style INT
);
GO

CREATE TYPE DateTimeRange AS TABLE (
    start_date DATETIME,
    end_date DATETIME,
    style INT
);
GO

-- Create base tables for views
CREATE TABLE money_smallmoney_table (
    id INT PRIMARY KEY,
    money_val MONEY,
    smallmoney_val SMALLMONEY,
    description VARCHAR(50)
);
GO

INSERT INTO money_smallmoney_table (id, money_val, smallmoney_val, description) VALUES
(1, 1234.56, 123.45, 'Test case 1'),
(2, -5678.90, -234.56, 'Test case 2'),
(3, 0.00, 0.00, 'Zero values');
GO

CREATE TABLE datetime_date_time_data (
    id INT PRIMARY KEY,
    date_val DATE,
    datetime_val DATETIME,
    time_val TIME,
    description VARCHAR(50)
);
GO

INSERT INTO datetime_date_time_data (id, date_val, datetime_val, time_val, description) VALUES
(1, '2023-12-25', '2023-12-25 12:34:56.789', '12:34:56.789', 'Christmas'),
(2, '2024-02-29', '2024-02-29 23:59:59.997', '23:59:59.997', 'Leap Year');
GO

-- Create views with conversion dependencies
CREATE VIEW money_smallmoney_conversions AS
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
    TRY_CONVERT(VARCHAR(30), smallmoney_val, 0) AS smallmoney_try_convert_style0
FROM money_smallmoney_table;
GO

CREATE VIEW datetime_date_time_conversions AS
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
    TRY_CONVERT(VARCHAR(30), time_val, 8) AS time_try_convert_style8
FROM datetime_date_time_data;
GO

-- Test negative decimal style parameters
CREATE TABLE negative_decimal_style_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value MONEY,
    style_number DECIMAL(5,2),
    description VARCHAR(200)
);
GO

INSERT INTO negative_decimal_style_test (test_value, style_number, description) VALUES
(CAST(1234.56 AS MONEY), -1.5, 'Negative decimal style -1.5'),
(CAST(1234.56 AS MONEY), -2.8, 'Negative decimal style -2.8'),
(CAST(1234.56 AS MONEY), 1.8, 'Positive decimal style 1.8'),
(CAST(1234.56 AS MONEY), 0.5, 'Decimal style 0.5');
GO

-- Test edge style values below -126 and beyond 126
CREATE TABLE edge_style_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value MONEY,
    style_number INT,
    description VARCHAR(200)
);
GO

INSERT INTO edge_style_test (test_value, style_number, description) VALUES
(CAST(1234.56 AS MONEY), -127, 'Style below -126: -127'),
(CAST(1234.56 AS MONEY), -200, 'Very negative style: -200'),
(CAST(1234.56 AS MONEY), -32768, 'Min INT style'),
(CAST(1234.56 AS MONEY), 127, 'Style above 126: 127'),
(CAST(1234.56 AS MONEY), 500, 'Very large style: 500'),
(CAST(1234.56 AS MONEY), 32767, 'Max INT style'),
(CAST(1234.56 AS MONEY), 2147483647, 'Max BIGINT style');
GO

-- Test combining money/smallmoney + datetime/date/time conversions in same query
CREATE TABLE combined_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    money_val MONEY,
    smallmoney_val SMALLMONEY,
    datetime_val DATETIME,
    date_val DATE,
    time_val TIME,
    description VARCHAR(200)
);
GO

INSERT INTO combined_conversion_test (money_val, smallmoney_val, datetime_val, date_val, time_val, description) VALUES
(CAST(1234.56 AS MONEY), CAST(123.45 AS SMALLMONEY), CAST('2023-12-25 14:30:45.123' AS DATETIME), CAST('2023-12-25' AS DATE), CAST('14:30:45.123' AS TIME), 'Combined test 1'),
(CAST(-5678.90 AS MONEY), CAST(-234.56 AS SMALLMONEY), CAST('2024-02-29 23:59:59.997' AS DATETIME), CAST('2024-02-29' AS DATE), CAST('23:59:59.997' AS TIME), 'Combined test 2'),
(CAST(0.00 AS MONEY), CAST(0.00 AS SMALLMONEY), CAST('1753-01-01 00:00:00.000' AS DATETIME), CAST('0001-01-01' AS DATE), CAST('00:00:00.000' AS TIME), 'Combined test 3');
GO

-- Test NULL style and style overflow/underflow with different datatypes
CREATE TABLE null_overflow_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    money_val MONEY,
    smallmoney_val SMALLMONEY,
    datetime_val DATETIME,
    date_val DATE,
    time_val TIME,
    style_number SQL_VARIANT,
    description VARCHAR(200)
);
GO

INSERT INTO null_overflow_test (money_val, smallmoney_val, datetime_val, date_val, time_val, style_number, description) VALUES
(CAST(1234.56 AS MONEY), CAST(123.45 AS SMALLMONEY), CAST('2023-12-25 14:30:45.123' AS DATETIME), CAST('2023-12-25' AS DATE), CAST('14:30:45.123' AS TIME), NULL, 'NULL style test'),
(CAST(1234.56 AS MONEY), CAST(123.45 AS SMALLMONEY), CAST('2023-12-25 14:30:45.123' AS DATETIME), CAST('2023-12-25' AS DATE), CAST('14:30:45.123' AS TIME), 999999999, 'Overflow style test'),
(CAST(1234.56 AS MONEY), CAST(123.45 AS SMALLMONEY), CAST('2023-12-25 14:30:45.123' AS DATETIME), CAST('2023-12-25' AS DATE), CAST('14:30:45.123' AS TIME), -999999999, 'Underflow style test');
GO

-- Test convert to char/nchar/nvarchar
CREATE TABLE char_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    money_val MONEY,
    datetime_val DATETIME,
    description VARCHAR(200)
);
GO

INSERT INTO char_conversion_test (money_val, datetime_val, description) VALUES
(CAST(1234.56 AS MONEY), CAST('2023-12-25 14:30:45.123' AS DATETIME), 'Char conversion test 1'),
(CAST(-5678.90 AS MONEY), CAST('2024-02-29 23:59:59.997' AS DATETIME), 'Char conversion test 2'),
(CAST(0.00 AS MONEY), CAST('1753-01-01 00:00:00.000' AS DATETIME), 'Char conversion test 3');
GO

-- Create view for string conversions
CREATE VIEW string_conversions AS
SELECT 
    id,
    money_val,
    CONVERT(CHAR(20), money_val) AS money_to_char,
    CONVERT(NCHAR(20), money_val) AS money_to_nchar,
    CONVERT(NVARCHAR(20), money_val) AS money_to_nvarchar,
    CONVERT(CHAR(20), money_val, 0) AS money_to_char_style0,
    CONVERT(NCHAR(20), money_val, 1) AS money_to_nchar_style1,
    CONVERT(NVARCHAR(20), money_val, 2) AS money_to_nvarchar_style2,
    datetime_val,
    CONVERT(CHAR(30), datetime_val) AS datetime_to_char,
    CONVERT(NCHAR(30), datetime_val) AS datetime_to_nchar,
    CONVERT(NVARCHAR(30), datetime_val) AS datetime_to_nvarchar,
    CONVERT(CHAR(30), datetime_val, 20) AS datetime_to_char_style20,
    CONVERT(NCHAR(30), datetime_val, 21) AS datetime_to_nchar_style21,
    CONVERT(NVARCHAR(30), datetime_val, 23) AS datetime_to_nvarchar_style23,
    'Test String' AS input_string,
    CONVERT(VARCHAR(30), 'Test String', 0) AS convert_style0,
    TRY_CONVERT(VARCHAR(30), 'Test String', 0) AS try_convert_style0,
    CONVERT(VARCHAR(30), 'Invalid Date', 101) AS convert_style101,
    TRY_CONVERT(VARCHAR(30), 'Invalid Date', 101) AS try_convert_style101
FROM char_conversion_test;
GO

-- Create procedures for UDT testing
CREATE PROCEDURE convert_money_range
    @money_ranges MoneyRange READONLY
AS
BEGIN
    SELECT 
        min_value,
        max_value,
        style,
        CONVERT(VARCHAR(30), min_value, style) AS min_converted,
        CONVERT(VARCHAR(30), max_value, style) AS max_converted,
        TRY_CONVERT(VARCHAR(30), min_value, style) AS min_try_converted,
        TRY_CONVERT(VARCHAR(30), max_value, style) AS max_try_converted
    FROM @money_ranges;
END;
GO

CREATE PROCEDURE convert_datetime_range
    @datetime_ranges DateTimeRange READONLY
AS
BEGIN
    SELECT 
        start_date,
        end_date,
        style,
        CONVERT(VARCHAR(30), start_date, style) AS start_converted,
        CONVERT(VARCHAR(30), end_date, style) AS end_converted,
        TRY_CONVERT(VARCHAR(30), start_date, style) AS start_try_converted,
        TRY_CONVERT(VARCHAR(30), end_date, style) AS end_try_converted
    FROM @datetime_ranges;
END;
GO

CREATE PROCEDURE test_convert_with_style_all_types
    @money_val MONEY,
    @smallmoney_val SMALLMONEY,
    @date_val DATE,
    @datetime_val DATETIME,
    @time_val TIME,
    @style INT
AS
BEGIN
    SELECT 
        'Money conversions' AS test_type,
        CONVERT(VARCHAR(30), @money_val) AS default_convert,
        TRY_CONVERT(VARCHAR(30), @money_val) AS default_try_convert,
        CONVERT(VARCHAR(30), @money_val, @style) AS style_convert,
        TRY_CONVERT(VARCHAR(30), @money_val, @style) AS style_try_convert;
    
    SELECT 
        'SmallMoney conversions' AS test_type,
        CONVERT(VARCHAR(30), @smallmoney_val) AS default_convert,
        TRY_CONVERT(VARCHAR(30), @smallmoney_val) AS default_try_convert,
        CONVERT(VARCHAR(30), @smallmoney_val, @style) AS style_convert,
        TRY_CONVERT(VARCHAR(30), @smallmoney_val, @style) AS style_try_convert;
    
    SELECT 
        'DateTime conversions' AS test_type,
        CONVERT(VARCHAR(30), @datetime_val) AS default_convert,
        TRY_CONVERT(VARCHAR(30), @datetime_val) AS default_try_convert,
        CONVERT(VARCHAR(30), @datetime_val, @style) AS style_convert,
        TRY_CONVERT(VARCHAR(30), @datetime_val, @style) AS style_try_convert;
    
    SELECT 
        'Date conversions' AS test_type,
        CONVERT(VARCHAR(30), @date_val) AS default_convert,
        TRY_CONVERT(VARCHAR(30), @date_val) AS default_try_convert,
        CONVERT(VARCHAR(30), @date_val, @style) AS style_convert,
        TRY_CONVERT(VARCHAR(30), @date_val, @style) AS style_try_convert;
    
    SELECT 
        'Time conversions' AS test_type,
        CONVERT(VARCHAR(30), @time_val) AS default_convert,
        TRY_CONVERT(VARCHAR(30), @time_val) AS default_try_convert,
        CONVERT(VARCHAR(30), @time_val, @style) AS style_convert,
        TRY_CONVERT(VARCHAR(30), @time_val, @style) AS style_try_convert;

    SELECT 
        datetime_val,
        CONVERT(VARCHAR(30), datetime_val) AS datetime_convert_default,
        TRY_CONVERT(VARCHAR(30), datetime_val) AS datetime_try_convert_default,
        CONVERT(VARCHAR(30), datetime_val, 20) AS datetime_convert_style20,
        TRY_CONVERT(VARCHAR(30), datetime_val, 20) AS datetime_try_convert_style20,
        time_val,
        CONVERT(VARCHAR(30), time_val) AS time_convert_default,
        TRY_CONVERT(VARCHAR(30), time_val) AS time_try_convert_default
    FROM datetime_date_time_data;
END;
GO


CREATE PROCEDURE test_all_conversions
    @money_val MONEY,
    @smallmoney_val SMALLMONEY,
    @date_val DATE,
    @datetime_val DATETIME,
    @time_val TIME,
    @style INT = NULL
AS
BEGIN
    SELECT 'Money Conversions' AS test_type,
           CONVERT(VARCHAR(30), @money_val, ISNULL(@style, 0)) AS money_convert,
           TRY_CONVERT(VARCHAR(30), @money_val, ISNULL(@style, 0)) AS money_try_convert,
           CONVERT(VARCHAR(30), @smallmoney_val, ISNULL(@style, 0)) AS smallmoney_convert,
           TRY_CONVERT(VARCHAR(30), @smallmoney_val, ISNULL(@style, 0)) AS smallmoney_try_convert;

    SELECT 'Date/Time Conversions' AS test_type,
           CONVERT(VARCHAR(30), @date_val, ISNULL(@style, 23)) AS date_convert,
           TRY_CONVERT(VARCHAR(30), @date_val, ISNULL(@style, 23)) AS date_try_convert,
           CONVERT(VARCHAR(30), @datetime_val, ISNULL(@style, 20)) AS datetime_convert,
           TRY_CONVERT(VARCHAR(30), @datetime_val, ISNULL(@style, 20)) AS datetime_try_convert,
           TRY_CONVERT(VARCHAR(30), @time_val, ISNULL(@style, 8)) AS time_try_convert;
END;
GO

