-- BABEL-6813: Fix infinite CAST recursion and DATETRUNC regtype resolution

-- Test CAST(numeric AS INT) in CHECK constraint ( uses _trunc_numeric_to_int*)
CREATE TABLE babel_6813_t1 (
    id int,
    val DECIMAL(10,2),
    CONSTRAINT chk_val CHECK (CAST(val AS INT) > 0)
)
GO

INSERT INTO babel_6813_t1 VALUES (1, 5.7)
GO

-- Test CAST to different integer sizes
CREATE TABLE babel_6813_t2 (
    id int,
    val DECIMAL(10,2),
    CONSTRAINT chk_val_int2 CHECK (CAST(val AS SMALLINT) > 0)
)
GO

INSERT INTO babel_6813_t2 VALUES (1, 3.9)
GO

CREATE TABLE babel_6813_t3 (
    id int,
    val DECIMAL(10,2),
    CONSTRAINT chk_val_int8 CHECK (CAST(val AS BIGINT) > 0)
)
GO

INSERT INTO babel_6813_t3 VALUES (1, 10.5)
GO

-- DATETRUNC tests with various datetime types
SELECT DATETRUNC(year, CAST('2023-06-15 10:30:00' AS datetime))
GO

SELECT DATETRUNC(month, CAST('2023-06-15 10:30:00' AS smalldatetime))
GO

SELECT DATETRUNC(day, CAST('2023-06-15 10:30:00.1234567' AS datetime2))
GO

SELECT DATETRUNC(hour, CAST('2023-06-15 10:30:00.1234567 +05:30' AS datetimeoffset))
GO

--datetime, date, time, money, 
SELECT sys.babelfish_conv_date_to_string('VARCHAR(10)', CAST('2024-01-15' AS DATE), 101);
GO

SELECT sys.babelfish_conv_datetime_to_string('VARCHAR(30)', 'DATETIME', CAST('2024-01-15 10:30:45' AS DATETIME2), 121);
GO

SELECT sys.babelfish_conv_time_to_string('VARCHAR(30)', 'TIME(3)', CAST('10:30:45.123' AS TIME), 121);
GO

SELECT sys.babelfish_conv_money_to_string('VARCHAR(30)', 1234.56, 1);
GO

SELECT sys.babelfish_conv_float_to_string('VARCHAR(30)', CAST(1234.56 AS FLOAT), 2);
GO
