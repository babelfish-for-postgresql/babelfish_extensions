CREATE VIEW datediff_big_vu_prepare_v1 AS (
    SELECT 
        DATEDIFF_BIG(year, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Years,
        DATEDIFF_BIG(quarter, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Quarters,
        DATEDIFF_BIG(month, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Months,
        DATEDIFF_BIG(dayofyear, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS DayofYears,
        DATEDIFF_BIG(day, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Days,
        DATEDIFF_BIG(week, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Weeks,
        DATEDIFF_BIG(hour, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Hours,
        DATEDIFF_BIG(minute, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Minutes,
        DATEDIFF_BIG(second, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Seconds,
        DATEDIFF_BIG(millisecond, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Millisecond,
        DATEDIFF_BIG(microsecond, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Microsecond,
        DATEDIFF_BIG(nanosecond, '2000-01-01 00:00:00.0000000', '2200-01-01 00:00:00.0000000') AS Nanosecond
    );
GO

-- result out of range of BIGINT, throw out of range error
CREATE VIEW datediff_big_vu_prepare_v2 AS (
    SELECT 
        DATEDIFF_BIG(nanosecond, '2000-01-01 00:00:00.0000000', '2500-01-01 00:00:00.0000000') AS Nanosecond
    );
GO

-- test with date input 
CREATE VIEW datediff_big_vu_prepare_v3 AS (
    SELECT 
        DATEDIFF_BIG(year, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Years,
        DATEDIFF_BIG(quarter, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Quarters,
        DATEDIFF_BIG(month, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Months,
        DATEDIFF_BIG(dayofyear, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS DayofYears,
        DATEDIFF_BIG(day, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Days,
        DATEDIFF_BIG(week, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Weeks,
        DATEDIFF_BIG(hour, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Hours,
        DATEDIFF_BIG(minute, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Minutes,
        DATEDIFF_BIG(second, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Seconds,
        DATEDIFF_BIG(millisecond, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Millisecond,
        DATEDIFF_BIG(microsecond, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Microsecond,
        DATEDIFF_BIG(nanosecond, CAST('2000-01-01' AS DATE), CAST('2200-12-31' AS DATE)) AS Nanosecond
    );
GO

-- test with datetime input
CREATE VIEW datediff_big_vu_prepare_v4 AS (
    SELECT 
        DATEDIFF_BIG(year, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Years,
        DATEDIFF_BIG(quarter, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Quarters,
        DATEDIFF_BIG(month, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Months,
        DATEDIFF_BIG(dayofyear, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS DayofYears,
        DATEDIFF_BIG(day, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Days,
        DATEDIFF_BIG(week, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Weeks,
        DATEDIFF_BIG(hour, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Hours,
        DATEDIFF_BIG(minute, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Minutes,
        DATEDIFF_BIG(second, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Seconds,
        DATEDIFF_BIG(millisecond, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Millisecond,
        DATEDIFF_BIG(microsecond, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Microsecond,
        DATEDIFF_BIG(nanosecond, CAST('2000-01-01 23:30:05.523' AS DATETIME), CAST('2200-12-31 23:30:05.523' AS DATETIME)) AS Nanosecond
    );
GO

-- test with datetimeoffset input
CREATE VIEW datediff_big_vu_prepare_v5 AS (
    SELECT 
        DATEDIFF_BIG(year, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Years,
        DATEDIFF_BIG(quarter, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Quarters,
        DATEDIFF_BIG(month, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Months,
        DATEDIFF_BIG(dayofyear, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS DayofYears,
        DATEDIFF_BIG(day, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Days,
        DATEDIFF_BIG(week, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Weeks,
        DATEDIFF_BIG(hour, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Hours,
        DATEDIFF_BIG(minute, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Minutes,
        DATEDIFF_BIG(second, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Seconds,
        DATEDIFF_BIG(millisecond, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Millisecond,
        DATEDIFF_BIG(microsecond, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Microsecond,
        DATEDIFF_BIG(nanosecond, CAST('1900-12-31 12:24:32 +10:0' AS DATETIMEOFFSET), CAST('2000-01-01 12:25:32 +10:0' AS DATETIMEOFFSET)) AS Nanosecond
    );
GO


-- test with datetime2 input
CREATE VIEW datediff_big_vu_prepare_v6 AS (
    SELECT 
        DATEDIFF_BIG(year, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Years,
        DATEDIFF_BIG(quarter, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Quarters,
        DATEDIFF_BIG(month, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Months,
        DATEDIFF_BIG(dayofyear, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS DayofYears,
        DATEDIFF_BIG(day, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Days,
        DATEDIFF_BIG(week, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Weeks,
        DATEDIFF_BIG(hour, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Hours,
        DATEDIFF_BIG(minute, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Minutes,
        DATEDIFF_BIG(second, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Seconds,
        DATEDIFF_BIG(millisecond, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Millisecond,
        DATEDIFF_BIG(microsecond, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Microsecond,
        DATEDIFF_BIG(nanosecond, CAST('2016-12-26 23:30:05.523456' AS DATETIME2), CAST('2216-12-26 23:30:05.523456' AS DATETIME2)) AS Nanosecond
    );
GO


-- test with smalldatetime input
-- cast('2002-05-23 23:41:29.998' as smalldatetime)
-- 1900-01-01 through 2079-06-06
CREATE VIEW datediff_big_vu_prepare_v7 AS (
    SELECT 
        DATEDIFF_BIG(year, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Years,
        DATEDIFF_BIG(quarter, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Quarters,
        DATEDIFF_BIG(month, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Months,
        DATEDIFF_BIG(dayofyear, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS DayofYears,
        DATEDIFF_BIG(day, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Days,
        DATEDIFF_BIG(week, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Weeks,
        DATEDIFF_BIG(hour, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Hours,
        DATEDIFF_BIG(minute, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Minutes,
        DATEDIFF_BIG(second, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Seconds,
        DATEDIFF_BIG(millisecond, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Millisecond,
        DATEDIFF_BIG(microsecond, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Microsecond,
        DATEDIFF_BIG(nanosecond, CAST('1900-01-01 00:00:00' AS SMALLDATETIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Nanosecond
    );
GO


-- test with time input
-- DATEDIFF() and DATEDIFF_BIG() currently does not work when both inputs are in time datatype
-- need to be fixed: 
-- Raise error: unit "year" not supported for type time without time zone
CREATE VIEW datediff_big_vu_prepare_v8 AS (
    SELECT 
        DATEDIFF_BIG(year, CAST('12:10:30.123' AS TIME), CAST('13:01:59.456' AS TIME)) AS Years
    );
GO

-- need to be fixed:
-- Raise error:  Line 1: operator is not unique: time without time zone sys.- time without time zone
CREATE VIEW datediff_big_vu_prepare_v9 AS (
    SELECT 
        DATEDIFF_BIG(minute, CAST('12:10:30.123' AS TIME), CAST('13:01:59.456' AS TIME)) AS Minutes
    );
GO

-- works fine when only one of the inputs is in time datatype
CREATE VIEW datediff_big_vu_prepare_v10 AS (
    SELECT 
        DATEDIFF_BIG(year, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Years,
        DATEDIFF_BIG(quarter, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Quarters,
        DATEDIFF_BIG(month, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Months,
        DATEDIFF_BIG(dayofyear, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS DayofYears,
        DATEDIFF_BIG(day, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Days,
        DATEDIFF_BIG(week, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Weeks,
        DATEDIFF_BIG(hour, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Hours,
        DATEDIFF_BIG(minute, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Minutes,
        DATEDIFF_BIG(second, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Seconds,
        DATEDIFF_BIG(millisecond, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Millisecond,
        DATEDIFF_BIG(microsecond, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Microsecond,
        DATEDIFF_BIG(nanosecond, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Nanosecond
    );
GO

-- NULL input
CREATE VIEW datediff_big_vu_prepare_v11 AS (
    SELECT 
        DATEDIFF_BIG(year, NULL, NULL) AS res1,
        DATEDIFF_BIG(year, '2000-01-01 00:00:00.0000000', NULL) AS res2,
        DATEDIFF_BIG(year, NULL, '2000-01-01 00:00:00.0000000') AS res3
    );
GO

-- throws error
CREATE VIEW datediff_big_vu_prepare_v12 AS (
    SELECT 
        DATEDIFF_BIG(NULL, NULL, NULL) AS res1
);
GO

-- test internal function num_days_in_date()
CREATE VIEW datediff_big_vu_prepare_v13 AS (
    SELECT
        num_days_in_date(CAST(0 AS BIGINT), CAST(0 AS BIGINT), CAST(0 AS BIGINT)) AS res1,
        num_days_in_date(CAST(1 AS BIGINT), CAST(1 AS BIGINT), CAST(1 AS BIGINT)) AS res2,
        num_days_in_date(CAST(8 AS BIGINT), CAST(5 AS BIGINT), CAST(2023 AS BIGINT)) AS res3,
        num_days_in_date(CAST(31 AS BIGINT), CAST(12 AS BIGINT), CAST(9999 AS BIGINT)) AS res4
);
GO

-- test in procedures
CREATE PROCEDURE datediff_big_vu_prepare_p1 AS 
BEGIN
    SELECT 
        DATEDIFF_BIG(year, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Years,
        DATEDIFF_BIG(quarter, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Quarters,
        DATEDIFF_BIG(month, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Months,
        DATEDIFF_BIG(dayofyear, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS DayofYears,
        DATEDIFF_BIG(day, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Days,
        DATEDIFF_BIG(week, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Weeks,
        DATEDIFF_BIG(hour, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Hours,
        DATEDIFF_BIG(minute, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Minutes,
        DATEDIFF_BIG(second, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Seconds,
        DATEDIFF_BIG(millisecond, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Millisecond,
        DATEDIFF_BIG(microsecond, '2000-01-01 00:00:00.0000000', '3000-01-01 00:00:00.0000000') AS Microsecond,
        DATEDIFF_BIG(nanosecond, '2000-01-01 00:00:00.0000000', '2200-01-01 00:00:00.0000000') AS Nanosecond;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p2 AS 
BEGIN
    SELECT 
        DATEDIFF_BIG(nanosecond, '2000-01-01 00:00:00.0000000', '2500-01-01 00:00:00.0000000') AS Nanosecond;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p3
    @x DATE = '2000-01-01', @y DATE = '2200-12-31'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, @x, @y) AS Years,
        DATEDIFF_BIG(quarter, @x, @y) AS Quarters,
        DATEDIFF_BIG(month, @x, @y) AS Months,
        DATEDIFF_BIG(dayofyear, @x, @y) AS DayofYears,
        DATEDIFF_BIG(day, @x, @y) AS Days,
        DATEDIFF_BIG(week, @x, @y) AS Weeks,
        DATEDIFF_BIG(hour, @x, @y) AS Hours,
        DATEDIFF_BIG(minute, @x, @y) AS Minutes,
        DATEDIFF_BIG(second, @x, @y) AS Seconds,
        DATEDIFF_BIG(millisecond, @x, @y) AS Millisecond,
        DATEDIFF_BIG(microsecond, @x, @y) AS Microsecond,
        DATEDIFF_BIG(nanosecond, @x, @y) AS Nanosecond;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p4
    @x DATETIME = '2000-01-01 23:30:05.523', @y DATETIME = '2200-12-31 23:30:05.523'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, @x, @y) AS Years,
        DATEDIFF_BIG(quarter, @x, @y) AS Quarters,
        DATEDIFF_BIG(month, @x, @y) AS Months,
        DATEDIFF_BIG(dayofyear, @x, @y) AS DayofYears,
        DATEDIFF_BIG(day, @x, @y) AS Days,
        DATEDIFF_BIG(week, @x, @y) AS Weeks,
        DATEDIFF_BIG(hour, @x, @y) AS Hours,
        DATEDIFF_BIG(minute, @x, @y) AS Minutes,
        DATEDIFF_BIG(second, @x, @y) AS Seconds,
        DATEDIFF_BIG(millisecond, @x, @y) AS Millisecond,
        DATEDIFF_BIG(microsecond, @x, @y) AS Microsecond,
        DATEDIFF_BIG(nanosecond, @x, @y) AS Nanosecond;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p5
    @x DATETIMEOFFSET = '1900-12-31 12:24:32 +10:0', @y DATETIMEOFFSET = '2000-01-01 12:25:32 +10:0'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, @x, @y) AS Years,
        DATEDIFF_BIG(quarter, @x, @y) AS Quarters,
        DATEDIFF_BIG(month, @x, @y) AS Months,
        DATEDIFF_BIG(dayofyear, @x, @y) AS DayofYears,
        DATEDIFF_BIG(day, @x, @y) AS Days,
        DATEDIFF_BIG(week, @x, @y) AS Weeks,
        DATEDIFF_BIG(hour, @x, @y) AS Hours,
        DATEDIFF_BIG(minute, @x, @y) AS Minutes,
        DATEDIFF_BIG(second, @x, @y) AS Seconds,
        DATEDIFF_BIG(millisecond, @x, @y) AS Millisecond,
        DATEDIFF_BIG(microsecond, @x, @y) AS Microsecond,
        DATEDIFF_BIG(nanosecond, @x, @y) AS Nanosecond;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p6
    @x DATETIME2 = '2016-12-26 23:30:05.523456', @y DATETIME2 = '2216-12-26 23:30:05.523456'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, @x, @y) AS Years,
        DATEDIFF_BIG(quarter, @x, @y) AS Quarters,
        DATEDIFF_BIG(month, @x, @y) AS Months,
        DATEDIFF_BIG(dayofyear, @x, @y) AS DayofYears,
        DATEDIFF_BIG(day, @x, @y) AS Days,
        DATEDIFF_BIG(week, @x, @y) AS Weeks,
        DATEDIFF_BIG(hour, @x, @y) AS Hours,
        DATEDIFF_BIG(minute, @x, @y) AS Minutes,
        DATEDIFF_BIG(second, @x, @y) AS Seconds,
        DATEDIFF_BIG(millisecond, @x, @y) AS Millisecond,
        DATEDIFF_BIG(microsecond, @x, @y) AS Microsecond,
        DATEDIFF_BIG(nanosecond, @x, @y) AS Nanosecond;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p7
    @x SMALLDATETIME = '1900-01-01 00:00:00', @y SMALLDATETIME = '2079-06-06 23:58:59'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, @x, @y) AS Years,
        DATEDIFF_BIG(quarter, @x, @y) AS Quarters,
        DATEDIFF_BIG(month, @x, @y) AS Months,
        DATEDIFF_BIG(dayofyear, @x, @y) AS DayofYears,
        DATEDIFF_BIG(day, @x, @y) AS Days,
        DATEDIFF_BIG(week, @x, @y) AS Weeks,
        DATEDIFF_BIG(hour, @x, @y) AS Hours,
        DATEDIFF_BIG(minute, @x, @y) AS Minutes,
        DATEDIFF_BIG(second, @x, @y) AS Seconds,
        DATEDIFF_BIG(millisecond, @x, @y) AS Millisecond,
        DATEDIFF_BIG(microsecond, @x, @y) AS Microsecond,
        DATEDIFF_BIG(nanosecond, @x, @y) AS Nanosecond;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p8
    @x TIME = '12:10:30.123', @y TIME = '13:01:59.456'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, @x, @y) AS Years;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p9
    @x TIME = '12:10:30.123', @y TIME = '13:01:59.456'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, @x, @y) AS Years;
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p10
    @x TIME = '12:10:30.123', @y SMALLDATETIME = '2079-06-06 23:58:59'
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Years,
        DATEDIFF_BIG(quarter, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Quarters,
        DATEDIFF_BIG(month, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Months,
        DATEDIFF_BIG(dayofyear, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS DayofYears,
        DATEDIFF_BIG(day, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Days,
        DATEDIFF_BIG(week, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Weeks,
        DATEDIFF_BIG(hour, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Hours,
        DATEDIFF_BIG(minute, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Minutes,
        DATEDIFF_BIG(second, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Seconds,
        DATEDIFF_BIG(millisecond, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Millisecond,
        DATEDIFF_BIG(microsecond, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Microsecond,
        DATEDIFF_BIG(nanosecond, CAST('12:10:30.123' AS TIME), CAST('2079-06-06 23:58:59' AS SMALLDATETIME)) AS Nanosecond
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p11
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(year, NULL, NULL) AS res1,
        DATEDIFF_BIG(year, '2000-01-01 00:00:00.0000000', NULL) AS res2,
        DATEDIFF_BIG(year, NULL, '2000-01-01 00:00:00.0000000') AS res3
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p12
AS
BEGIN
    SELECT 
        DATEDIFF_BIG(NULL, NULL, NULL) AS res1
END
GO

CREATE PROCEDURE datediff_big_vu_prepare_p13
AS
BEGIN
    SELECT
        num_days_in_date(CAST(0 AS BIGINT), CAST(0 AS BIGINT), CAST(0 AS BIGINT)) AS res1,
        num_days_in_date(CAST(1 AS BIGINT), CAST(1 AS BIGINT), CAST(1 AS BIGINT)) AS res2,
        num_days_in_date(CAST(8 AS BIGINT), CAST(5 AS BIGINT), CAST(2023 AS BIGINT)) AS res3,
        num_days_in_date(CAST(31 AS BIGINT), CAST(12 AS BIGINT), CAST(9999 AS BIGINT)) AS res4
END
GO
