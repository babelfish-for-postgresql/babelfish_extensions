-- Test with date datatype
CREATE VIEW DATETRUNC_vu_prepare_v1 AS (
    select 
        datetrunc(year, cast('2020-04-15' as date)) as dt1,
        datetrunc(yy, cast('2020-04-15' as date)) as dt2,
        datetrunc(yyyy, cast('2020-04-15' as date)) as dt3,
        datetrunc(quarter, cast('2020-04-15' as date)) as dt4,
        datetrunc(qq, cast('2020-04-15' as date)) as dt5,
        datetrunc(q, cast('2020-04-15' as date)) as dt6,
        datetrunc(month, cast('2020-04-15' as date)) as dt7,
        datetrunc(mm, cast('2020-04-15' as date)) as dt8,
        datetrunc(m, cast('2020-04-15' as date)) as dt9,
        datetrunc(dayofyear, cast('2020-04-15' as date)) as dt10,
        datetrunc(dy, cast('2020-04-15' as date)) as dt11,
        datetrunc(y, cast('2020-04-15' as date)) as dt12,
        datetrunc(day, cast('2020-04-15' as date)) as dt13,
        datetrunc(dd, cast('2020-04-15' as date)) as dt14,
        datetrunc(d, cast('2020-04-15' as date)) as dt15,
        datetrunc(week, cast('2020-04-15' as date)) as dt16,
        datetrunc(wk, cast('2020-04-15' as date)) as dt17,
        datetrunc(ww, cast('2020-04-15' as date)) as dt18,
        datetrunc(iso_week, cast('2020-04-15' as date)) as dt19,
        datetrunc(isowk, cast('2020-04-15' as date)) as dt20,
        datetrunc(isoww, cast('2020-04-15' as date)) as dt21
    );
GO

-- Test with time datatype
CREATE VIEW DATETRUNC_vu_prepare_v2 AS (
    select 
        datetrunc(hour, cast('12:32:45.5647311' as time)) as dt1,
        datetrunc(hh, cast('12:32:45.5647311' as time)) as dt2,
        datetrunc(minute, cast('12:32:45.5647311' as time)) as dt3,
        datetrunc(mi, cast('12:32:45.5647311' as time)) as dt4,
        datetrunc(n, cast('12:32:45.5647311' as time)) as dt5,
        datetrunc(second, cast('12:32:45.5647311' as time)) as dt6,
        datetrunc(ss, cast('12:32:45.5647311' as time)) as dt7,
        datetrunc(s, cast('12:32:45.5647311' as time)) as dt8,
        datetrunc(millisecond, cast('12:32:45.5647311' as time)) as dt9,
        datetrunc(ms, cast('12:32:45.5647311' as time)) as dt10,
        datetrunc(microsecond, cast('12:32:45.5647311' as time)) as dt11,
        datetrunc(mcs, cast('12:32:45.5647311' as time)) as dt12
    );
GO


-- Test with datetime datatype
CREATE VIEW DATETRUNC_vu_prepare_v3 AS (
    select 
        datetrunc(year, cast('2004-06-17 09:32:42.566' as datetime)) as dt1,
        datetrunc(quarter, cast('2004-06-17 09:32:42.566' as datetime)) as dt2,
        datetrunc(month, cast('2004-06-17 09:32:42.566' as datetime)) as dt3,
        datetrunc(dayofyear, cast('2004-06-17 09:32:42.566' as datetime)) as dt4,
        datetrunc(day, cast('2004-06-17 09:32:42.566' as datetime)) as dt5,
        datetrunc(week, cast('2004-06-17 09:32:42.566' as datetime)) as dt6,
        datetrunc(hour, cast('2004-06-17 09:32:42.566' as datetime)) as dt7,
        datetrunc(minute, cast('2004-06-17 09:32:42.566' as datetime)) as dt8,
        datetrunc(second, cast('2004-06-17 09:32:42.566' as datetime)) as dt9,
        datetrunc(millisecond, cast('2004-06-17 09:32:42.566' as datetime)) as dt10
    );
GO
-- Should throw exception - 'datepart 'microsecond' is not supported by date function datetrunc for data type ''datetime''.
CREATE VIEW DATETRUNC_vu_prepare_v4 AS (
    select 
        datetrunc(microsecond, cast('2004-06-17 09:32:42.566' as datetime)) as dt1
);
GO

-- Test with smalldatetime datatype
CREATE VIEW DATETRUNC_vu_prepare_v5 AS (
    select 
        datetrunc(year, cast('2004-08-14 22:34:20' as smalldatetime)) as dt1,
        datetrunc(quarter, cast('2004-08-14 22:34:20' as smalldatetime)) as dt2,
        datetrunc(month, cast('2004-08-14 22:34:20' as smalldatetime)) as dt3,
        datetrunc(dayofyear, cast('2004-08-14 22:34:20' as smalldatetime)) as dt4,
        datetrunc(day, cast('2004-08-14 22:34:20' as smalldatetime)) as dt5,
        datetrunc(week, cast('2004-08-14 22:34:20' as smalldatetime)) as dt6,
        datetrunc(hour, cast('2004-08-14 22:34:20' as smalldatetime)) as dt7,
        datetrunc(minute, cast('2004-08-14 22:34:20' as smalldatetime)) as dt8,
        datetrunc(second, cast('2004-08-14 22:34:20' as smalldatetime)) as dt9
    );
GO

-- Should throw exception - 'datepart 'microsecond' is not supported by date function datetrunc for data type ''smalldatetime''.
CREATE VIEW DATETRUNC_vu_prepare_v6 AS (
    select 
        datetrunc(microsecond, cast('2004-08-14 22:34:20' as smalldatetime)) as dt1,
        datetrunc(millisecond, cast('2004-08-14 22:34:20' as smalldatetime)) as dt2
);
GO

-- Test with datetime2 datatype
CREATE VIEW DATETRUNC_vu_prepare_v7 AS (
    select 
        datetrunc(year, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt1,
        datetrunc(quarter, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt2,
        datetrunc(month, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt3,
        datetrunc(dayofyear, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt4,
        datetrunc(day, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt5,
        datetrunc(week, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt6,
        datetrunc(hour, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt7,
        datetrunc(minute, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt8,
        datetrunc(second, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt9,
        datetrunc(millisecond, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt10,
        datetrunc(microsecond, cast('2015-11-30 09:34:56.6574893' as datetime2)) as dt11
    );
GO

-- Test with datetimeoffset datatype
CREATE VIEW DATETRUNC_vu_prepare_v8 AS (
    select 
        datetrunc(year, cast('2015-11-30 09:34:56.6574893 +12:42' as datetimeoffset)) as dt1,
        datetrunc(quarter, cast('2015-11-30 09:34:56.6574893 +10:42' as datetimeoffset)) as dt2,
        datetrunc(month, cast('2015-11-30 09:34:56.6574893 +02:42' as datetimeoffset)) as dt3,
        datetrunc(dayofyear, cast('2015-11-30 09:34:56.6574893 +05:42' as datetimeoffset)) as dt4,
        datetrunc(day, cast('2015-11-30 09:34:56.6574893 +12:42' as datetimeoffset)) as dt5,
        datetrunc(week, cast('2015-11-30 09:34:56.6574893 +13:42' as datetimeoffset)) as dt6,
        datetrunc(hour, cast('2015-11-30 09:34:56.6574893 +12:42' as datetimeoffset)) as dt7,
        datetrunc(minute, cast('2015-11-30 09:34:56.6574893 -12:43' as datetimeoffset)) as dt8,
        datetrunc(second, cast('2015-11-30 09:34:56.6574893 +12:22' as datetimeoffset)) as dt9,
        datetrunc(millisecond, cast('2015-11-30 09:34:56.6574893 -10:42' as datetimeoffset)) as dt10,
        datetrunc(microsecond, cast('2015-11-30 09:34:56.6574893 +12:42' as datetimeoffset)) as dt11
    );
GO

-- Test with expression input that can be converted to datetime2 datatype. 
CREATE VIEW DATETRUNC_vu_prepare_v9 AS (
    select 
        datetrunc(year, '2021-Jan-01') as dt1,
        datetrunc(year, '2021/Jan/01') as dt2,
        datetrunc(year, '2021-1-1') as dt3,
        datetrunc(year, '20210101') as dt4,
        datetrunc(hour, cast('2020-01-01' as varchar)) as dt5,
        datetrunc(minute, cast('1980-09-08' as char)) as dt6,
        datetrunc(day, '12:32:42') as dt7,
        datetrunc(day, '12:32:42.46378') as dt8,
        datetrunc(week, '1990-09-09 12:32:09.546') as dt9,
        datetrunc(week, '1990-09-09 12:32:09') as dt10,
        datetrunc(week, '1990-09-09 12:32:09.546788') as dt11
    );
GO

-- Test when time, datetime2, datetimeoffset casted to a specified fractional scale
-- babelfish will always give answer that will include fractional seconds till 7 digits. 
CREATE VIEW DATETRUNC_vu_prepare_v10 AS (
    select 
        datetrunc(hour, cast('12:32:43.4635' as time(3))) dt1,
        datetrunc(month, cast('2020-12-23 20:20:20.2222' as datetime2(2))) as dt2,
        datetrunc(week, cast('1989-09-23 05:36:43.2930 +12:37' as datetimeoffset(5))) as dt3,
        datetrunc(minute, cast('2027-12-13 10:13:20.12236' as datetime2(4))) as dt4,
        datetrunc(year, cast('2027-12-13 10:13:20.537478' as datetimeoffset(6))) as dt5
    );
GO

-- Test when time, datetime2, datetimeoffset casted to a specified fractional scale which is less then the specified datepart milliseocond, microsecond.
-- Babelfish always give answer to these with fractional seconds till 7 digits, babelfish do not throw an error similar to sql server in this case.
CREATE VIEW DATETRUNC_vu_prepare_v11 AS (
    select 
        datetrunc(millisecond, cast('2002-01-01 12:33:43.435354' as datetime2(2))) as dt1,
        datetrunc(millisecond, cast('2020-01-01 12:33:32.4324' as datetimeoffset(1))) as dt2,
        datetrunc(millisecond, cast('12:23:43.464774' as time(0))) as dt3,
        datetrunc(microsecond, cast('2002-01-01 12:33:43.435354' as datetime2(5))) as dt4,
        datetrunc(microsecond, cast('2020-01-01 12:33:32.437724' as datetimeoffset(4))) as dt5
    );
GO


-- Procedures
-- Test with upper/lower limit of date/time.
CREATE PROCEDURE BABEL_3953_vu_prepare_p1 as (
	SELECT
		datetrunc(month, cast('0001-01-01' as date)) as dt1,
		datetrunc(month, cast('9999-12-31' as date)) as dt2
	);
GO

CREATE PROCEDURE BABEL_3953_vu_prepare_p2 as (
	SELECT
		datetrunc(month, cast('1753-01-01 00:00:00 ' as datetime)) as dt1,
		datetrunc(month, cast('9999-12-31 23:59:59.997' as datetime)) as dt2
	);
GO

CREATE PROCEDURE BABEL_3953_vu_prepare_p3 as (
	SELECT
		datetrunc(month, cast('0001-01-01 00:00:00' as datetime2)) as dt1,
		datetrunc(month, cast('9999-12-31 23:59:59.9999999' as datetime2)) as dt2
	);
GO

CREATE PROCEDURE BABEL_3953_vu_prepare_p4 as (
	SELECT
		datetrunc(month, cast('0001-01-01 00:00:00 -14:00' as datetimeoffset)) as dt1,
		datetrunc(month, cast('9999-12-31 23:59:59.9999 +14:00' as datetimeoffset)) as dt2
	);
GO

CREATE PROCEDURE BABEL_3953_vu_prepare_p5 as (
	SELECT
		datetrunc(month, cast('1900-01-01 00:00:00' as smalldatetime)) as dt1,
		datetrunc(day, cast('2007-06-05 23:59:59' as smalldatetime)) as dt2
	);
GO

CREATE PROCEDURE BABEL_3953_vu_prepare_p6 as (
	SELECT
		datetrunc(hour, cast('00:00:00.0000000' as time)) as dt1,
		datetrunc(second, cast('23:59:59.999999' as time)) as dt2
	);
GO


-- functions
CREATE FUNCTION BABEL_3953_vu_prepare_f1()
RETURNS DATETIME2 AS
BEGIN
RETURN (SELECT datetrunc(iso_week, cast('2012-01-23 12:32:23.324' as datetime2)));
END
GO

CREATE FUNCTION BABEL_3953_vu_prepare_f2()
RETURNS time AS
BEGIN
RETURN (select datetrunc(second, cast('12:32:53.23' as time)));
END
GO

CREATE FUNCTION BABEL_3953_vu_prepare_f3()
RETURNS date AS
BEGIN
RETURN (select datetrunc(week, cast('2001-11-14' as date)));
END
GO
