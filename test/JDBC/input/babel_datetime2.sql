-- Testing inserting into the table
create table datetime2_testing ( dt DATETIME2 );
INSERT INTO datetime2_testing VALUES('1753-1-1 00:00:00.000');
INSERT INTO datetime2_testing VALUES('9999-12-31 23:59:59.998');
INSERT INTO datetime2_testing VALUES('1992-05-23 23:40:29.999');
INSERT INTO datetime2_testing VALUES('1992-05-23 23:40:30.000');
INSERT INTO datetime2_testing VALUES('1999-12-31 23:59:59.998');
INSERT INTO datetime2_testing VALUES('1999-12-31 23:59:59.999');
INSERT INTO datetime2_testing VALUES('23:40:29.999');
INSERT INTO datetime2_testing VALUES('23:40:30.000');
INSERT INTO datetime2_testing VALUES('2020-03-14');
select * from datetime2_testing;
go

-- Test comparision with datetimeoffset/datetime/smalldatetime/date/time
select * from datetime2_testing where dt > cast('2079-06-06 23:59:12.345678 -9:30' as datetimeoffset);
go
select * from datetime2_testing where dt >= cast('2000-01-01 00:00:59' as smalldatetime);
go
select * from datetime2_testing where dt >= cast('1992-05-23 23:40:00' as datetime) 
                    and dt < cast('1992-05-23 23:41:00' as datetime);
go
select * from datetime2_testing where dt < cast('1992-05-24' as date);
go
select * from datetime2_testing where dt < cast('12:34:56.789' as time);
go

-- Testing rounding for different typmod
select CAST('2079-06-06 23:59:29.123456' AS datetime2);
go
select CAST('2079-06-06 23:59:29.123456' AS datetime2(0));
go
select CAST('2079-06-06 23:59:29.123456' AS datetime2(1));
go
select CAST('2079-06-06 23:59:29.123456' AS datetime2(2));
go
select CAST('2079-06-06 23:59:29.123456' AS datetime2(3));
go
select CAST('2079-06-06 23:59:29.123456' AS datetime2(4));
go
select CAST('2079-06-06 23:59:29.123456' AS datetime2(5));
go
select CAST('2079-06-06 23:59:29.123456' AS datetime2(6));
go

-- Testing rounding for different typmod edge cases
select CAST('2000-12-31 23:59:29.99' AS datetime2(5));
go
select CAST('1500-12-31 23:59:29.99' AS datetime2(1));
go
select CAST('2020-12-31 23:59:29.99' AS datetime2(5));
go
select CAST('2020-12-31 23:59:29.99' AS datetime2(1));
go
select CAST('9999-12-31 23:59:59.999999' AS datetime2(4));
go
select CAST('9999-12-31 23:59:59.99999' AS datetime2(6));
go
select CAST('1500-12-31 23:59:30.0001' AS datetime2(5));
go
select CAST('1500-12-31 23:59:30.0001' AS datetime2(3));
go
select CAST('0001-01-01 00:00:00.000000' AS datetime2(5));
go
-- out of range
select CAST('10000-01-01 00:00:00.000000' AS datetime2(5));
go
-- out of range
select CAST('0000-12-31 23:59:59.9999' AS datetime2(1));
go
select cast('9999-12-31 23:59:59.9999999' as datetime2(7));
go
select cast('9999-12-31 23:59:59.9999999' as datetime2(5));
go
select cast('8888-12-31 23:59:59.9999999' as datetime2(4));
go
select cast('9999-12-31 23:59:59.999' as datetime2(5));
go
select cast('9999-12-31 23:59:59.999999999' as datetime2(3));
go


-- Test type cast to/from other time formats
-- Test date
select CAST(CAST('1999-12-31' AS date) AS datetime2);
go
select CAST(CAST('2000-01-01 23:59:59.99932' AS datetime2) AS date);
go
select CAST(CAST('0001-12-31' AS date) AS datetime2);
go
select CAST(CAST('2000-12-31' AS date) AS datetime2(2));
go

-- Test time
select CAST(CAST('00:00:00.000' AS time) AS datetime2);
go
select CAST(CAST('23:59:59.999' AS time) AS datetime2);
go
select CAST(CAST('23:59:59.123456' AS time) AS datetime2);
go
select CAST(CAST('23:59:59.123456' AS time) AS datetime2(1));
go
select CAST(CAST('1900-05-06 23:59:29.998123' AS datetime2) AS time);
go
select CAST(CAST('2050-05-06 00:00:00' AS datetime2) AS time);
go
select CAST(CAST('2050-05-06 23:59:29.998' AS datetime2) AS time);
go

-- Test smalldatetime
select CAST(CAST('2000-06-06 23:59:29.998123' AS datetime2) AS smalldatetime);
go
select CAST(CAST('2020-03-15 23:59:29.99722' AS smalldatetime) AS datetime2);
go
select CAST(CAST('2020-03-15 23:59:12.99722' AS smalldatetime) AS datetime2(4));
go
select CAST(CAST('2020-03-15 23:59:29.999' AS smalldatetime) AS datetime2);
go
-- out of range
select CAST(CAST('3000-06-06 23:59:29.998' AS datetime2) AS smalldatetime);
go

-- Test datetime
select CAST(CAST('2020-03-15 23:59:29.99' AS datetime) AS datetime2);
go
select CAST(CAST('2020-03-15 23:59:29.45' AS datetime) AS datetime2(1));
go
select CAST(CAST('2079-06-06 23:59:29.99' AS datetime2) AS datetime);
go
select CAST(CAST('2079-06-06 23:59:29.992343' AS datetime2) AS datetime);
go

-- Test datetimeoffset
select CAST(CAST('2020-03-15 23:59:29.99' AS datetime2) AS datetimeoffset);
go
select CAST(CAST('2079-06-06 23:59:29.998 +8:00' AS datetimeoffset) AS datetime2);
go
select CAST(CAST('2079-06-06 23:59:29.998 -9:30' AS datetimeoffset) AS datetime2);
go
select CAST(CAST('2079-06-06 23:59:12.345678 -9:30' AS datetimeoffset) AS datetime2);
go
select CAST(CAST('0001-06-06 23:59:12.345678 -9:30' AS datetimeoffset) AS datetime2);
go
select CAST(CAST('0001-06-06 23:59:12.345678 -9:30' AS datetimeoffset) AS datetime2(5));
go

-- Test datetime value ranges
select cast('9999-12-31' as datetime2);
go
select cast('9999-12-31 23:59:59.998' as datetime2);
go
-- out of range
select cast('10000-00-00' as datetime2);
go
-- out of range
select cast('0000-12-31 23:59:59.999999' as datetime2);
go
select cast('0001-01-01 00:00:00.000000' as datetime2);
go
select cast('9999-12-31 23:59:59.999999' as datetime2);
go
select cast('2021-12-31 23:59:29.1234567' as datetime2);
go
select cast('9999-12-31 23:59:59.9999999' as datetime2);
go
select cast('8888-12-31 23:59:59.9999999' as datetime2);
go
select cast('9999-12-31 23:59:59.99999999' as datetime2);
go
select cast('8888-12-31 23:59:59.99999999' as datetime2);
go
select cast('9999-12-31 23:59:59.999999' as datetime2);
go
select cast('8888-12-31 23:59:59.999999' as datetime2);
go

-- Test datetime2 default value
create table t1 (a datetime2, b int);
go
insert into t1 (b) values (1);
go
select a from t1 where b = 1;
go

-- Test datetime2 as parameter for time related functions
select day(cast('2002-05-23 23:41:29.998' as datetime2));
go
select month(cast('2002-05-23 23:41:29.998' as datetime2));
go
select year(cast('2002-05-23 23:41:29.998' as datetime2));
go
select datepart(quarter, cast('2002-05-23 23:41:29.998' as datetime2));
go
select datepart(hour, cast('2002-05-23 23:41:29.998' as datetime2));
go
select datepart(dayofyear, cast('2002-05-23 23:41:29.998' as datetime2));
go
select datepart(second, cast('2002-05-23 23:41:29.998' as datetime2));
go
select datename(year, cast('2002-05-23 23:41:29.998' as datetime2));
go
select datename(dw, cast('2002-05-23 23:41:29.998' as datetime2));
go
select datename(month, cast('2002-05-23 23:41:29.998' as datetime2));
go
select dateadd(second, 56, cast('2016-12-26 23:29:29' as datetime2));
go
-- TODO Fix BABEL-2822
select dateadd(millisecond, 56, cast('2016-12-26 23:29:29' as datetime2));
go
select dateadd(minute, 56, cast('2016-12-26 23:29:29' as datetime2));
go
-- out of range
select dateadd(year, 150, cast('9900-12-26 23:29:29' as datetime2));
go

-- Test data type precedence TODO Fix [BABEL-883] missing TDS support for type regtype (was pg_typeof produces error in sqlcmd)
select pg_typeof(c1) FROM (SELECT cast('2016-12-26 23:30:05' as datetime2) as C1 UNION SELECT cast('2016-12-26 23:30:05' as smalldatetime) as C1) T;
go
select pg_typeof(c1) FROM (SELECT cast('2016-12-26 23:30:05' as datetime2) as C1 UNION SELECT cast('2016-12-26 23:30:05' as datetime) as C1) T;
go
select pg_typeof(c1) FROM (SELECT cast('2016-12-26 23:30:05' as datetime2) as C1 UNION SELECT cast('2016-12-26 23:30:05 +08:00:00' as datetimeoffset) as C1) T;
go
select pg_typeof(c1) FROM (SELECT cast('2016-12-26 23:30:05' as datetime2) as C1 UNION SELECT cast('23:30:05' as time) as C1) T;
go
select pg_typeof(c1) FROM (SELECT cast('2016-12-26 23:30:05' as datetime2) as C1 UNION SELECT cast('2016-12-26' as date) as C1) T;
go

-- Clean up
drop table datetime2_testing;
go
drop table t1;
go
