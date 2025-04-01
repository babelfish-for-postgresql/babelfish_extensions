-- Test datetime default value
select a from babel_datetime_vu_prepare_testing_1 where b = 1
go

-- Testing inserting into the table
select * from babel_datetime_vu_prepare_testing
go

-- Test comparision with datetime/smalldatetime/date
select * from babel_datetime_vu_prepare_testing where dt >= smalldatetime('2000-01-01 00:00:59')
go
select * from babel_datetime_vu_prepare_testing where dt >= datetime('1992-05-23 23:40:00') 
                    and dt < datetime('1992-05-23 23:41:00')
go
select * from babel_datetime_vu_prepare_testing where dt < date('1992-05-24')
go

-- Test rounding (datetime rounds milliseconds to 0.000, 0.003, 0.007)
-- TODO

-- Test type cast to/from other time formats
-- Test datetime2
select CAST(CAST('2020-03-15 23:59:29.99' AS datetime) AS datetime2)
go
select CAST(CAST('2079-06-06 23:59:29.99' AS datetime2) AS datetime)
go
select CAST(CAST('2079-06-06 23:59:29.992343' AS datetime2) AS datetime)
go

-- Test date
select CAST(CAST('1999-12-31' AS date) AS datetime)
go
select CAST(CAST('2000-01-01 23:59:59.999' AS datetime) AS date)
go
-- out of range
select CAST(CAST('1752-12-31' AS date) AS datetime)
go

-- Test time
select CAST(CAST('00:00:00.000' AS time) AS datetime)
go
select CAST(CAST('23:59:59.999' AS time) AS datetime)
go 
select CAST(CAST('23:59:59.123456' AS time) AS datetime)
go
select CAST(CAST('1900-05-06 23:59:29.998' AS datetime) AS time)
go
select CAST(CAST('2050-05-06 00:00:00' AS datetime) AS time)
go
select CAST(CAST('2050-05-06 23:59:29.998' AS datetime) AS time)
go

-- Test smalldatetime
select CAST(CAST('2000-06-06 23:59:29.998' AS datetime) AS smalldatetime)
go
select CAST(CAST('2020-03-15 23:59:29.997' AS smalldatetime) AS datetime)
go
select CAST(CAST('2020-03-15 23:59:29.999' AS smalldatetime) AS datetime)
go
-- out of range
select CAST(CAST('3000-06-06 23:59:29.998' AS datetime) AS smalldatetime)
go

-- Test datetimeoffset
select CAST(CAST('2020-03-15 23:59:29.99' AS datetime) AS datetimeoffset)
go
select CAST(CAST('2079-06-06 23:59:29.998 +8:00' AS datetimeoffset) AS datetime)
go
select CAST(CAST('2079-06-06 23:59:29.998 -9:30' AS datetimeoffset) AS datetime)
go
select CAST(CAST('2079-06-06 23:59:12.345678 -9:30' AS datetimeoffset) AS datetime)
go
-- out of range
select CAST(CAST('0001-06-06 23:59:12.345678 -9:30' AS datetimeoffset) AS datetime)
go

-- Test datetime value ranges
select cast('1753-01-01' as datetime)
go
select cast('9999-12-31' as datetime)
go
select cast('1753-01-01 00:00:00' as datetime)
go
select cast('9999-12-31 23:59:29.998' as datetime)
go
-- out of range
select cast('1752-12-31' as datetime)
go
-- out of range
select cast('10000-00-00' as datetime)
go
select cast('9999-12-31 23:59:29.999' as datetime)
go
-- out of range
select cast('1752-12-31 23:59:29.999' as datetime)
go 
-- out of range
select cast('2021-12-31 23:59:29.1234567' as datetime)
go 

-- Test datetime as parameter for time related functions
select day(cast('2002-05-23 23:41:29.998' as datetime))
go
select month(cast('2002-05-23 23:41:29.998' as datetime))
go
select year(cast('2002-05-23 23:41:29.998' as datetime))
go
select datepart(quarter, cast('2002-05-23 23:41:29.998' as datetime))
go
select datepart(hour, cast('2002-05-23 23:41:29.998' as datetime))
go
select datepart(dayofyear, cast('2002-05-23 23:41:29.998' as datetime))
go
select datepart(second, cast('2002-05-23 23:41:29.998' as datetime))
go
select datename(year, cast('2002-05-23 23:41:29.998' as datetime))
go
select datename(dw, cast('2002-05-23 23:41:29.998' as datetime))
go
select datename(month, cast('2002-05-23 23:41:29.998' as datetime))
go
select dateadd(second, 56, cast('2016-12-26 23:29:29' as datetime))
go
select dateadd(millisecond, 56, cast('2016-12-26 23:29:29' as datetime))
go
select dateadd(minute, 56, cast('2016-12-26 23:29:29' as datetime))
go
-- out of range
select dateadd(year, 150, cast('9900-12-26 23:29:29' as datetime))
go
-- Test data type precedence TODO Fix [BABEL-883] missing TDS support for type regtype (was pg_typeof produces error in sqlcmd)
select pg_typeof(c1) FROM (SELECT cast('2016-12-26 23:30:05' as datetime) as C1 UNION SELECT cast('2016-12-26 23:30:05' as smalldatetime) as C1) T
go
select pg_typeof(c1) FROM (SELECT '2016-12-26 23:30:05'::datetime as C1 UNION SELECT '2016-12-26 23:30:05'::datetime2 as C1) T
go
select pg_typeof(c1) FROM (SELECT '2016-12-26 23:30:05'::datetime as C1 UNION SELECT '2016-12-26 23:30:05 +08:00:00'::datetimeoffset as C1) T
go
select pg_typeof(c1) FROM (SELECT '2016-12-26 23:30:05'::datetime as C1 UNION SELECT '23:30:05'::time as C1) T
go
select pg_typeof(c1) FROM (SELECT '2016-12-26 23:30:05'::datetime as C1 UNION SELECT '2016-12-26'::date as C1) T
go

-- Test Varbinary to Datetime conversion using CAST
-- Min value
SELECT CAST(0xFFFF2E4600000000 AS DateTime);
GO

-- Max value
SELECT CAST(0x002D247F018B81FF AS DateTime);
GO

-- One tick after min value
SELECT CAST(0xFFFF2E4600000001 AS DateTime);
GO

-- One tick before max value
SELECT CAST(0x002D247F018B81FE AS DateTime);
GO

-- Early date
SELECT CAST(0x00000C8F00000000 AS DateTime);
GO

-- Late date
SELECT CAST(0x0000BC1E00000000 AS DateTime);
GO

-- FractionalSecond
SELECT CAST(0x0000B02200000001 AS DateTime);
GO

SELECT CAST(0x0000B0220000007F AS DateTime);
GO

SELECT CAST(0x0000B022000000FF AS DateTime);
GO

-- 4-byte varbinary
SELECT CAST(0x0000B022 AS DateTime);
GO

-- 12-byte varbinary
SELECT CAST(0x0000B022018B81FF0000B022 AS DateTime);
GO

-- Before min value
SELECT CAST(0xFFFF2E4500000000 AS DateTime);
GO

-- After max value
SELECT CAST(0x002D247F018B8200 AS DateTime);
GO

-- February 28th on a leap year
SELECT CAST(0x00008EE600C5C100 AS DateTime);
GO

-- February 29th on a leap year
SELECT CAST(0x00008EE700C5C100 AS DateTime);
GO

-- March 1st on a leap year
SELECT CAST(0x00008F0600C5C100 AS DateTime);
GO

-- Last moment of 1999
SELECT CAST(0x00008EAB018B81FF AS DateTime);
GO

-- First moment of 2000
SELECT CAST(0x00008EAC00000001 AS DateTime);
GO

-- time precision
SELECT CAST(0x0000B02200EF28C1 AS DateTime);
GO
SELECT CAST(0x0000B02200EF28C0 AS DateTime);
GO
SELECT CAST(0x00008EE700C5C100 AS DateTime);
GO

-- basic tests
SELECT CAST(0x002D247F018B81FF AS DateTime);
GO
SELECT CAST(0x0000B022018B81FF AS DateTime);
GO
SELECT CAST(0x0000B0E9018B81FF AS DateTime);
GO

-- different input size for cast
SELECT CAST(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF2E4600000000 AS DateTime);
GO

SELECT CAST(0x1018B81FF AS DateTime);
GO

SELECT CAST(0x11018B81FF AS DateTime);
GO

SELECT CAST(0xFFF AS DateTime);
GO

SELECT CAST(0xF AS DateTime);
GO

SELECT CAST(0xFFFF AS DateTime);
GO

SELECT CAST(0xFFFFFF  AS DateTime);
GO

SELECT CAST(0x1FFFFFF AS DateTime);
GO

SELECT CAST(0x100FFFFFF AS DateTime);
GO

SELECT CAST(CAST(0x100FFFFFF AS VARBINARY(MAX)) AS DateTime);
GO

SELECT CAST(0xFFFF235FFF0000000100FFFFFF AS DateTime);
GO

SELECT CAST(CAST(0xFFFF235FFF0000000100FFFFFF AS VARBINARY(MAX)) AS DateTime);
GO

SELECT CAST(CAST(0x0 as VARBINARY(MAX)) AS DateTime);
GO

-- Test Varbinary to Datetime conversion using CONVERT
-- Min value
SELECT CONVERT(DateTime, 0xFFFF2E4600000000);
GO

-- Max value
SELECT CONVERT(DateTime, 0x002D247F018B81FF);
GO

-- One tick after min value
SELECT CONVERT(DateTime, 0xFFFF2E4600000001);
GO

-- One tick before max value
SELECT CONVERT(DateTime, 0x002D247F018B81FE);
GO

-- Early date
SELECT CONVERT(DateTime, 0x00000C8F00000000);
GO

-- Late date
SELECT CONVERT(DateTime, 0x0000BC1E00000000);
GO

-- FractionalSecond
SELECT CONVERT(DateTime, 0x0000B02200000001);
GO

SELECT CONVERT(DateTime, 0x0000B0220000007F);
GO

SELECT CONVERT(DateTime, 0x0000B022000000FF);
GO

-- 4-byte varbinary
SELECT CONVERT(DateTime, 0x0000B022);
GO

-- 12-byte varbinary
SELECT CONVERT(DateTime, 0x0000B022018B81FF0000B022);
GO

-- Before min value
SELECT CONVERT(DateTime, 0xFFFF2E4500000000);
GO

-- After max value
SELECT CONVERT(DateTime, 0x002D247F018B8200);
GO

-- February 28th on a leap year
SELECT CONVERT(DateTime, 0x00008EE600C5C100);
GO

-- February 29th on a leap year
SELECT CONVERT(DateTime, 0x00008EE700C5C100);
GO

-- March 1st on a leap year
SELECT CONVERT(DateTime, 0x00008F0600C5C100);
GO

-- Last moment of 1999
SELECT CONVERT(DateTime, 0x00008EAB018B81FF);
GO

-- First moment of 2000
SELECT CONVERT(DateTime, 0x00008EAC00000001);
GO

-- time precision
SELECT CONVERT(DateTime, 0x0000B02200EF28C1);
GO

SELECT CONVERT(DateTime, 0x0000B02200EF28C0);
GO

SELECT CONVERT(DateTime, 0x00008EE700C5C100);
GO

-- basic tests
SELECT CONVERT(DateTime, 0x002D247F018B81FF);
GO

SELECT CONVERT(DateTime, 0x0000B022018B81FF);
GO

SELECT CONVERT(DateTime, 0x0000B0E9018B81FF);
GO

-- different input size for convert
SELECT CONVERT(DateTime, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF2E4600000000);
GO

SELECT CONVERT(DateTime, 0x1018B81FF);
GO

SELECT CONVERT(DateTime, 0x11018B81FF);
GO

SELECT CONVERT(DateTime, 0xFFF);
GO

SELECT CONVERT(DateTime, 0xF);
GO

SELECT CONVERT(DateTime, 0xFFFF);
GO

SELECT CONVERT(DateTime, 0xFFFFFF);
GO

SELECT CONVERT(DateTime, 0x1FFFFFF);
GO

SELECT CONVERT(DateTime, 0x100FFFFFF);
GO

SELECT CONVERT(DateTime, CAST(0x100FFFFFF AS VARBINARY(MAX)));
GO

SELECT CONVERT(DateTime, 0xFFFF235FFF0000000100FFFFFF);
GO

SELECT CONVERT(DateTime, CAST(0xFFFF235FFF0000000100FFFFFF AS VARBINARY(MAX)));
GO

SELECT CONVERT(DateTime, CAST(0x0 as VARBINARY(MAX)));
GO

-- NULL tests
SELECT CAST(NULL AS DateTime);
GO

SELECT CONVERT(DateTime, NULL);
GO

-- negative tests
SELECT CAST(0x11111111 AS Datetime);
GO

SELECT CAST(0xFFFFFFFF AS Datetime);
GO

SELECT CAST(0x0101010101010101 AS Datetime);
GO

SELECT CAST(CAST(0x00008EE600C5C100 AS VARBINARY(0)) AS DateTime);
GO

SELECT * from babel_datetime_vu_view1;
GO

SELECT * from babel_datetime_vu_view2;
GO

SELECT CONVERT(DateTime, cast(0x0 as binary));
GO

EXEC babel_datetime_vu_procedure
GO

SELECT babel_datetime_vu_function1(0x0000B02200EF28C1)
GO

-- convert string to datetime test
DECLARE @emptyString VARCHAR(10) = '';
SELECT CONVERT(datetime, @emptyString) AS EmptyStringResult;
GO

SELECT * FROM babel_datetime_empty_string_vw
GO
EXEC babel_datetime_empty_string_p
GO
SELECT babel_datetime_empty_string_f()
GO