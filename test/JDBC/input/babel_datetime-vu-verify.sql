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
-- TODO Fix BABEL-2822
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