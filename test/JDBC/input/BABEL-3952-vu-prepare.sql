-- Test with invalid number argument
-- Should Throw Error - 'Invalid bucket width value passed to date_bucket function. Only positive values are allowed.'
CREATE VIEW DATE_BUCKET_vu_prepare_v3 AS (
    select 
        date_bucket(year, -2, cast('2020-01-01' as date)) as db1,
        date_bucket(year, 0, cast('2020-01-01' as date)) as db2
    );
GO
-- Should throw - Argument data type text is invalid for argument 3 of date_bucket function.
CREATE VIEW DATE_BUCKET_vu_prepare_v4 AS (
    select 
        date_bucket(year, -2, '2020-01-01') as db1, 
        date_bucket(year, 0, '2020-01-01') as db2
    );
GO
-- Should Throw Error - 'Argument data type NULL is invalid for argument 3 of date_bucket function.'
CREATE VIEW DATE_BUCKET_vu_prepare_v5 AS (
    select 
        date_bucket(year, -2, null) as db,
        date_bucket(year, 0, null) as db1
    );
GO

-- Test with null value for number argument
-- Should Throw Error - 'Argument data type NULL is invalid for argument 2 of date_bucket function.'
CREATE VIEW DATE_BUCKET_vu_prepare_v6 AS (
    select 
        date_bucket(year, null, cast('2020-01-01' as date)) as db1
    );
GO
CREATE VIEW DATE_BUCKET_vu_prepare_v7 AS (
    select 
        date_bucket(year, null, '2020-01-01') as db2
    );
GO
CREATE VIEW DATE_BUCKET_vu_prepare_v8 AS (
    select 
        date_bucket(year, null, null) as db2
    );
GO

-- Test with null or invalid datatype for date argument
-- Should Throw Error - 'Argument data type NULL is invalid for argument 3 of date_bucket function.'
CREATE VIEW DATE_BUCKET_vu_prepare_v9 AS (
    select 
        date_bucket(year, 1, null) as db1,
        date_bucket(year, 2, null, '2020-01-01') as db2,
        date_bucket(year, 2, null, cast('2020-01-01' as date)) as db3,
        date_bucket(year, 1, null, null) as db4
    );
GO
-- Should throw Error - Argument data type varchar is invalid for argument 3 of date_bucket function.
CREATE VIEW DATE_BUCKET_vu_prepare_v10 AS (
    select 
        date_bucket(year, 2, '2020-01-01') as db1,
		date_bucket(year,2, '2020-01-01', cast('2020-01-01' as date)) as db2,
		date_bucket(year, 2, '2020-01-01', '2020-01-01') as db3,
		date_bucket(year, 2, '2020-01-01', 3242) as db4
    );
GO
-- Should throw Error - Argument data type varchar is invalid for argument 3 of Date_Bucket function.
CREATE VIEW DATE_BUCKET_vu_prepare_v11 AS (
    select 
        date_bucket(year, 2, 432) as db1,
		date_bucket(year,2, 643, cast('2020-01-01' as date)) as db2,
		date_bucket(year, 2, 432, '2020-01-01') as db3,
		date_bucket(year, 2, 947, 3242) as db4
    );
GO

CREATE VIEW DATE_BUCKET_vu_prepare_v11_2 AS (
    select 
        date_bucket(dayofyear, 2, 6473) as db
    );
GO

-- Test with invalid origin date
-- Should throw - Argument data type integer is invalid for argument 4 of Date_Bucket function
CREATE VIEW DATE_BUCKET_vu_prepare_v12 AS (
    select 
        date_bucket(year, 2, cast('2020-01-01' as date), '2020-01-01') as db2,
		date_bucket(year, 2, cast('2020-01-01' as date), 534) as db3,
        date_bucket(year, 2, cast('2020-09-12' as date), cast('2005-09-12' as datetime)) as db4
    );
GO
-- Should return valid date_bucket - 2023-01-01
CREATE VIEW DATE_BUCKET_vu_prepare_v12_origin_IS_NULL AS (
    SELECT 
        date_bucket(year, 3, CAST('2023-03-24' as date), null) as db1
    );
GO

-- Test with upper/lower limit of every date/time datatype. 
CREATE VIEW DATE_BUCKET_vu_prepare_v13 As (
    select 
        date_bucket(day, 1, cast('9999-12-31' as date), cast('0001-01-01' as date)) as db1,
        date_bucket(day, 1, cast('0001-01-01' as date),cast('9999-12-31' as date)) as db2
    );
GO
CREATE VIEW DATE_BUCKET_vu_prepare_v14 As (
    select 
        date_bucket(day, 1, cast('9999-12-31 23:59:59.997' as datetime), cast('1753-01-01 00:00:00' as datetime)) as db1
    );
GO
-- Should throw - data out of range for datetime
CREATE VIEW DATE_BUCKET_vu_prepare_v15 As (
    select 
        date_bucket(day, 1, cast('1753-01-01 00:00:00' as datetime), cast('9999-12-31 23:59:59.997' as datetime)) as db2
    );
GO
CREATE VIEW DATE_BUCKET_vu_prepare_v16 As (
    select 
        date_bucket(day, 1, cast('9999-12-31 23:59:59.9999999' as datetime2), cast('0001-01-01 00:00:00' as datetime2)) as db1
    );
GO
-- Should throw - data out of range for datetime2
CREATE VIEW DATE_BUCKET_vu_prepare_v17 As (
    select 
        date_bucket(day, 1,  cast('0001-01-01 00:00:00' as datetime2), cast('9999-12-31 23:59:59.9999999' as datetime2)) as db1
    );
GO
CREATE VIEW DATE_BUCKET_vu_prepare_v18 As (
    select 
        date_bucket(day, 1, cast('9999-12-31 23:59:59.9999999 +14:00' as datetimeoffset), cast('0001-01-01 00:00:00 -14:00' as datetimeoffset)) as db1
    );
GO

CREATE VIEW DATE_BUCKET_vu_prepare_v20 As (
    select 
        date_bucket(day, 1, cast('2079-06-06' as smalldatetime), cast('1900-01-01' as smalldatetime)) as db1,
        date_bucket(day, 1, cast('2079-06-06' as smalldatetime), cast('1900-01-01' as smalldatetime)) as db2
    );
GO
CREATE VIEW DATE_BUCKET_vu_prepare_v21 As (
    select 
        date_bucket(minute, 1, cast('23:59:59.999999' as time), cast('00:00:00.0000000' as time)) as db1,
        date_bucket(minute, 1, cast('00:00:00.0000000' as time), cast('23:59:59.999999' as time)) as db2
    );
GO

-- test with time input with datepart IN (year, quarter, month, week, day)
-- Raise ERROR - The datepart 'year' is not supported by date function date_bucket for data type time.
CREATE VIEW DATE_BUCKET_vu_prepare_v22 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('23:58:59' AS TIME)) AS YEARS_BUCKET
    );
GO

-- test with date input with datepart IN (hour, minute, second, millisecond)
-- Raise ERROR - The datepart 'hour' is not supported by date function date_bucket for data type date.'
CREATE VIEW DATE_BUCKET_vu_prepare_v23 AS (
    SELECT 
        DATE_BUCKET(hour, 2, CAST('2000-01-01' AS DATE)) AS HOURS_BUCKET
    );
GO

-- test with un-supported datepart. 
-- RAISE ERROR - The datepart nanosecond is not supported by date function date_bucket for data type datetime2.
CREATE VIEW DATE_BUCKET_vu_prepare_v24 AS (
    SELECT 
        DATE_BUCKET(nanosecond, 2, CAST('2000-01-01 12:32:12.123' AS DATETIME2)) AS nanosecond_BUCKET
    );
GO
CREATE VIEW DATE_BUCKET_vu_prepare_invalid_datepart AS (
    SELECT 
        DATE_BUCKET(dayofmonth, 2, CAST('2000-01-01 12:32:12.123' AS DATETIME2)) AS nanosecond_BUCKET
    );
GO

-- test with number argument exceed range of positive int. 
-- RAISE ERROR - Integer out of range
CREATE VIEW DATE_BUCKET_vu_prepare_v25 AS (
    SELECT 
        DATE_BUCKET(DAY, 2147483648, CAST('2020-04-30 00:00:00' as datetime2)) AS DAYS_BUCKET
    );
GO

-- test with float type of number 
CREATE VIEW DATE_BUCKET_vu_prepare_v26 AS (
    select 
        date_bucket(day, 2.5, CAST('2020-04-30 00:00:00' as datetime2)) as db1
);
GO

-- TEST WITH DATE TYPE INPUT
-- 1. without optional argument 'origin'
CREATE VIEW DATE_BUCKET_vu_prepare_v27 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01' AS DATE)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01' AS DATE)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01' AS DATE)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01' AS DATE)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01' AS DATE)) AS WEEKS_BUCKET
    );
GO
-- 2. with optional argument 'origin' < 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v28 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01' AS DATE), CAST('1905-09-12' AS DATE)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01' AS DATE), CAST('1905-09-12' AS DATE)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01' AS DATE), CAST('1905-09-12' AS DATE)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01' AS DATE), CAST('1905-09-12' AS DATE)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01' AS DATE), CAST('1905-09-12' AS DATE)) AS WEEKS_BUCKET
    );
GO
-- 3. with optional argument 'origin' > 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v29 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01' AS DATE), CAST('2010-09-21' AS DATE)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01' AS DATE), CAST('2010-09-21' AS DATE)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01' AS DATE), CAST('2010-09-21' AS DATE)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01' AS DATE), CAST('2010-09-21' AS DATE)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01' AS DATE), CAST('2010-09-21' AS DATE)) AS WEEKS_BUCKET
    );
GO

-- TEST WITH DATETIME INPUT
-- 1. without optional argument 'origin'
CREATE VIEW DATE_BUCKET_vu_prepare_v30 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS MILLISECONDS_BUCKET
    );
GO
-- 2. with optional argument 'origin' < 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v31 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('1910-09-12 23:45:10.432' AS DATETIME)) AS MILLISECONDS_BUCKET
    );
GO
-- 3. with optional argument 'origin' > 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v32 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('1910-09-12 23:45:10.432' AS DATETIME), CAST('2000-01-01 23:30:05.523' AS DATETIME)) AS MILLISECONDS_BUCKET
    );
GO

-- TEST WITH datetime2 input
-- 1. without optional argument 'origin'
CREATE VIEW DATE_BUCKET_vu_prepare_v33 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS MILLISECONDS_BUCKET
    );
GO
-- 2. with optional argument 'origin' < 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v34 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 23:30:05.523456' AS DATETIME2), CAST('1915-08-15 22:35:05.422456' AS DATETIME2)) AS MILLISECONDS_BUCKET
    );
GO
--  3. with optional argument 'origin' > 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v35 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS MILLISECONDS_BUCKET
    );
GO

--  4. when millisecond trunc is required. 
CREATE VIEW DATE_BUCKET_vu_prepare_v36 AS (
    SELECT 
        date_bucket(year, 1, cast('2020-08-02 02:12:30.4463' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS YEARS_BUCKET,
        date_bucket(month, 1, cast('2020-08-02 02:12:30.4463' as datetime2), cast('2020-07-02 02:12:30.4467' as datetime2)) AS month_BUCKET,
        date_bucket(quarter, 1, cast('2020-05-02 02:12:30.4463' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS quarter_bucket,
        date_bucket(week, 1, cast('2020-06-30 02:12:30.4463' as datetime2), cast('2019-07-02 02:12:30.4467' as datetime2)) AS week_BUCKET,
        date_bucket(day, 1, cast('2020-08-02 02:12:30.4463' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS day_BUCKET,
        date_bucket(hour, 1, cast('2020-08-02 02:12:30.4463' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS hour_BUCKET,
        date_bucket(minute, 1, cast('2020-08-02 02:12:30.4463' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS minute_BUCKET,
        date_bucket(second, 1, cast('2020-08-02 02:12:30.4463' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS second_BUCKET,
        date_bucket(millisecond, 1, cast('2020-08-02 02:12:30.4463' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS millisecond_BUCKET1,
        date_bucket(millisecond, 1, cast('2020-08-02 02:12:30.4443' as datetime2), cast('2019-08-02 02:12:30.4467' as datetime2)) AS millisecond_BUCKET2
    );
GO

-- TEST WITH datetimeoffset input
-- 1. without optional argument 'origin'
CREATE VIEW DATE_BUCKET_vu_prepare_v37 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 12:25:32 +02:00' AS DATETIMEOFFSET)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 12:25:32 +09:20' AS DATETIMEOFFSET)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 12:25:32 +13:10' AS DATETIMEOFFSET)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 12:25:32 +10:23' AS DATETIMEOFFSET)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 12:25:32 -10:32' AS DATETIMEOFFSET)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 12:25:32 +12:08' AS DATETIMEOFFSET)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 12:25:32 -08:10' AS DATETIMEOFFSET)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 12:25:32 +00:00' AS DATETIMEOFFSET)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 12:25:32 +11:00' AS DATETIMEOFFSET)) AS MILLISECONDS_BUCKET
    );
GO
-- 2. with optional argument 'origin' < 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v38 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 12:25:32 +02:12' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 +02:12' AS DATETIMEOFFSET)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 12:25:32 +01:11' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 +01:10' AS DATETIMEOFFSET)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 12:25:32 +04:10' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 +03:15' AS DATETIMEOFFSET)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 12:25:32 -03:00' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 +12:02' AS DATETIMEOFFSET)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 12:25:32 -05:02' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 -02:24' AS DATETIMEOFFSET)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 12:25:32 -01:05' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 +03:29' AS DATETIMEOFFSET)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 12:25:32 +00:09' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 -06:45' AS DATETIMEOFFSET)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 12:25:32 +10:17' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 +05:10' AS DATETIMEOFFSET)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 12:25:32 +07:20' AS DATETIMEOFFSET), CAST('1920-03-22 13:20:31 +12:32' AS DATETIMEOFFSET)) AS MILLISECONDS_BUCKET
    );
GO
-- 3. with optional argument 'origin' > 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v39 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('1920-03-22 13:20:31 +02:12' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 -01:05' AS DATETIMEOFFSET)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('1920-03-22 13:20:31 +01:10' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 -03:00' AS DATETIMEOFFSET)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('1920-03-22 13:20:31 +03:15'  AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 -05:02' AS DATETIMEOFFSET)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('1920-03-22 13:20:31 +12:02' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:17' AS DATETIMEOFFSET)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('1920-03-22 13:20:31 -02:24' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +01:11' AS DATETIMEOFFSET)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('1920-03-22 13:20:31 +03:29' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 -05:02' AS DATETIMEOFFSET)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('1920-03-22 13:20:31 -06:45' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +04:10'  AS DATETIMEOFFSET)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('1920-03-22 13:20:31 +05:10' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +12:08' AS DATETIMEOFFSET)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('1920-03-22 13:20:31 +12:32' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +07:20' AS DATETIMEOFFSET)) AS MILLISECONDS_BUCKET
    );
GO
--  4. when millisecond trunc is required. 
CREATE VIEW DATE_BUCKET_vu_prepare_v40 AS (
    SELECT 
        date_bucket(year, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS YEARS_BUCKET,
        date_bucket(month, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2020-07-02 02:12:30.4467 +00:00' as datetimeoffset)) AS month_BUCKET,
        date_bucket(quarter, 1, cast('2020-05-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS quarter_bucket,
        date_bucket(week, 1, cast('2020-06-30 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-07-02 02:12:30.4467 +00:00' as datetimeoffset)) AS week_BUCKET,
        date_bucket(day, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS day_BUCKET,
        date_bucket(hour, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS hour_BUCKET,
        date_bucket(minute, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS minute_BUCKET,
        date_bucket(second, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS second_BUCKET,
        date_bucket(millisecond, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS millisecond_BUCKET1,
        date_bucket(millisecond, 1, cast('2020-08-02 02:12:30.4443 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS millisecond_BUCKET2
    );
GO

-- TEST WITH smalldatetime input
-- 1. without optional argument 'origin'
CREATE VIEW DATE_BUCKET_vu_prepare_v41 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS MILLISECONDS_BUCKET
    );
GO
-- 2. with optional argument 'origin' < 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v42 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS MILLISECONDS_BUCKET
    );
GO
-- 3. with optional argument 'origin' > 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v43 AS (
    SELECT 
        DATE_BUCKET(year, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS YEARS_BUCKET,
        DATE_BUCKET(quarter, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS QUARTER_BUCKET,
        DATE_BUCKET(month, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS MONTHS_BUCKET,
        DATE_BUCKET(day, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS DAYS_BUCKET,
        DATE_BUCKET(week, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS WEEKS_BUCKET,
        DATE_BUCKET(hour, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('1911-02-11 21:55:56' AS SMALLDATETIME), CAST('2000-01-01 23:58:59' AS SMALLDATETIME)) AS MILLISECONDS_BUCKET
    );
GO

-- test with time input
-- postgresql support time datatype till 6 digits after decimal point. 
-- select DATE_BUCKET(hour, 2, CAST('23:58:59.5464469' AS TIME), CAST('12:23:56.8463639' AS TIME)) AS HOURS_BUCKET output of this query will differ from SQL server at the last digit
-- SQL server output - 22:23:56.8463639 and babelfish output of T-sql endpoint = 22:23:56.8463640
-- 1. Without optiona argument 'origin'
CREATE VIEW DATE_BUCKET_vu_prepare_v44 AS (
    SELECT 
        DATE_BUCKET(hour, 2, CAST('23:58:59' AS TIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('23:58:59' AS TIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('23:58:59' AS TIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('23:58:59' AS TIME)) AS MILLISECONDS_BUCKET
    );
GO
-- 2. With optional argument 'origin' < 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v45 AS (
    SELECT 
        DATE_BUCKET(hour, 2, CAST('23:58:59.546446' AS TIME), CAST('12:23:56.846363' AS TIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('23:58:59.546446' AS TIME), CAST('12:23:56.846363' AS TIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('23:58:59.546446' AS TIME), CAST('12:23:56.846363' AS TIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('23:58:59.546446' AS TIME), CAST('12:23:56.846363' AS TIME)) AS MILLISECONDS_BUCKET
    );
GO
-- 3. With optional argument 'origin' > 'date'
CREATE VIEW DATE_BUCKET_vu_prepare_v46 AS (
    SELECT 
        DATE_BUCKET(hour, 2, CAST('12:23:56.846363' AS TIME), CAST('23:58:59.546446' AS TIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 2, CAST('12:23:56.846363' AS TIME), CAST('23:58:59.546446' AS TIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 2, CAST('12:23:56.846363' AS TIME), CAST('23:58:59.546446' AS TIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 2, CAST('12:23:56.846363' AS TIME), CAST('23:58:59.546446' AS TIME)) AS MILLISECONDS_BUCKET
    );
GO

-- 4. Test when trunc is required
CREATE VIEW DATE_BUCKET_vu_prepare_v47 AS (
    SELECT 
        DATE_BUCKET(hour, 11, CAST('23:23:56.846362' AS TIME), CAST('12:23:56.846363' AS TIME)) AS HOURS_BUCKET,
        DATE_BUCKET(minute, 11, CAST('01:23:56.846362' AS TIME), CAST('01:12:56.846363' AS TIME)) AS MINUTES_BUCKET,
        DATE_BUCKET(second, 10, CAST('01:23:50.846362' AS TIME), CAST('01:23:40.846363' AS TIME)) AS SECONDS_BUCKET,
        DATE_BUCKET(millisecond, 10,CAST('01:23:50.846362' AS TIME), CAST('01:23:40.846363' AS TIME)) AS MILLISECONDS_BUCKET
    );
GO

-- Test case when casting of datetime datatype round to fixed bins (e.g. .000, .003, .007)
CREATE VIEW DATE_BUCKET_vu_prepare_v48 AS (
    SELECT 
        date_bucket(month, 1, cast('2020-09-02 02:12:30.448' as datetime), cast('2010-09-02 02:12:30.451' as datetime)) as db1,
        date_bucket(month, 1, cast('2020-09-02 02:12:30.449' as datetime), cast('2010-09-02 02:12:30.451' as datetime)) as db2
    );
GO

-- Test when datepart is Abbreviations
CREATE VIEW DATE_BUCKET_vu_prepare_v49  AS (
    SELECT 
        DATE_BUCKET(dd, 3, cast('2028-02-23' as date), cast('1970-09-23' as date)) as db1,
        DATE_BUCKET(d, 5, CAST('2034-09-23 08:34:32.432' as datetime)) as db2,
        DATE_BUCKET(wk, 2, cast('2023-09-23' as datetime2),  cast('1965-09-25' as datetime2)) as db3,
        DATE_BUCKET(ww, 2, cast('2023-09-23' as datetime2),  cast('1965-09-25' as datetime2)) as db4,
        DATE_BUCKET(mm, 3, cast('2028-02-06' as date), cast('1970-09-23' as date)) as db5,
        DATE_BUCKET(m, 5, CAST('2034-09-23 08:34:32.432' as datetime)) as db6,
        DATE_BUCKET(qq, 2, cast('2023-09-23' as date),  cast('1965-09-25' as date)) as db7,
        DATE_BUCKET(q, 2, cast('2023-09-23' as datetime),  cast('1965-09-25' as datetime)) as db8,
        DATE_BUCKET(yy, 3, cast('2028-02-15' as date), cast('1970-09-23' as date)) as db9,
        DATE_BUCKET(yyyy, 5, CAST('2034-09-23 08:34:32.432' as datetime)) as db10,
        DATE_BUCKET(hh, 2, cast('2023-09-23 23:43:53.947' as datetime2),  cast('1965-09-25 02:43:46.83' as datetime2)) as db11,
        DATE_BUCKET(mi, 2, cast('2023-09-23 14:43:56.54 +01:34' as datetimeoffset),  cast('1965-09-25 09:43:23.323 +09:10' as datetimeoffset)) as db12,
        DATE_BUCKET(n, 2, cast('19:43:56.8362' as time),  cast('12:43:56.3223' as time)) as db13,
        DATE_BUCKET(ss, 10, cast('2023-09-23 12:32:43.234' as datetime),  cast('1965-09-25 09:33:43.847' as datetime)) as db14,
        DATE_BUCKET(s, 10, cast('2023-09-23 05:35:12' as smalldatetime),  cast('1965-09-25 09:32:32' as smalldatetime)) as db15,
		DATE_BUCKET(ms, 2, cast('2023-09-23 11:12:32.64537' as datetime2),  cast('1965-09-25 09:32:43.343' as datetime2)) as db16
    );
GO

-- Procedures
CREATE PROCEDURE BABEL_3952_vu_prepare_p1 as (
	SELECT
		date_bucket(month, 2, cast('2015-10-11' as date)) as db1,
		date_bucket(month, 3, cast('2012-04-09' as date)) as db2
	);
GO

CREATE PROCEDURE BABEL_3952_vu_prepare_p2 as (
	SELECT
		date_bucket(year, 12, cast('2030-01-01 00:00:00 ' as datetime)) as db1,
		date_bucket(year, 15, cast('2019-12-23 23:59:59.997' as datetime)) as db2
	);
GO

CREATE PROCEDURE BABEL_3952_vu_prepare_p3 as (
	SELECT
		date_bucket(hour, 5, cast('2000-01-01 00:00:00' as datetime2)) as dt1,
		date_bucket(hour, 5, cast('2020-09-23 12:43:43.43' as datetime2)) as dt2
	);
GO

-- Functions
CREATE FUNCTION BABEL_3952_vu_prepare_f1()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT date_bucket(week, 7, cast('2012-01-23 12:32:23.324' as datetime2)));
END
GO

CREATE FUNCTION BABEL_3952_vu_prepare_f2()
RETURNS time AS
BEGIN
RETURN (select date_bucket(second, 19, cast('12:32:53.23' as time), cast('02:12:53.32' as time)));
END
GO

CREATE FUNCTION BABEL_3952_vu_prepare_f3()
RETURNS date AS
BEGIN
RETURN (select date_bucket(day, 23, cast('2001-11-14' as date), cast('1980-09-10' as date)));
END
GO
