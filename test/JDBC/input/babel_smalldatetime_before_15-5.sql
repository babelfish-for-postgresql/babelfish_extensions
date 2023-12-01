-- Testing rounding behaviour when inserting into the table
create table smalldatetime_testing ( sm smalldatetime );
INSERT INTO smalldatetime_testing VALUES('23:40:29.998');
INSERT INTO smalldatetime_testing VALUES('1992-05-23 23:40:29.998');
INSERT INTO smalldatetime_testing VALUES('1992-05-23 23:40:29.998');
INSERT INTO smalldatetime_testing VALUES('1992-05-23 23:40:29.999');
INSERT INTO smalldatetime_testing VALUES('1992-05-23 23:40:30.000');
INSERT INTO smalldatetime_testing VALUES('2002-05-23 23:41:29.998');
INSERT INTO smalldatetime_testing VALUES('2002-05-23 23:41:29.999');
INSERT INTO smalldatetime_testing VALUES('2002-05-23 23:41:30.000');
INSERT INTO smalldatetime_testing VALUES('2000-01-01 00:00:29.998');
INSERT INTO smalldatetime_testing VALUES('2000-01-01 00:00:29.999');
INSERT INTO smalldatetime_testing VALUES('1999-12-31 23:59:30.000');
INSERT INTO smalldatetime_testing VALUES('1999-12-31 23:59:29.999');
INSERT INTO smalldatetime_testing VALUES('1999-12-31 23:59:29.998');
select * from smalldatetime_testing;
go

-- Test comparision with datetime/smalldatetime/date
select * from smalldatetime_testing where sm >= cast('2000-01-01 00:00:59' as smalldatetime);
select * from smalldatetime_testing where sm >= cast('1992-05-23 23:40:00' as datetime) 
                    and sm < cast('1992-05-23 23:41:00' as datetime);
select * from smalldatetime_testing where sm < cast(cast('1992-05-24' as date) as smalldatetime);
go

-- Test rounding for 23:59:59
SELECT CAST('1992-05-09 23:59:59' AS SMALLDATETIME);
SELECT CAST('2002-05-09 23:59:59' AS SMALLDATETIME);
SELECT CAST('1999-12-31 23:59:59' AS SMALLDATETIME);
go

-- Test type cast to/from other time formats
-- Cast to smalldatetime
select CAST(CAST('00:00:00.234' AS time) AS smalldatetime);
select CAST(CAST('01:02:03.456' AS time) AS smalldatetime);
select CAST(CAST('2020-03-15' AS date) AS smalldatetime);
select CAST(CAST('2020-03-15' AS datetime) AS smalldatetime);
select CAST(CAST('2010-07-08 23:59:29.998' AS datetime) AS smalldatetime);
select CAST(CAST('1980-07-08 23:59:29.123456 +8:00' AS datetimeoffset) AS smalldatetime);
select CAST(CAST('2010-07-08 23:59:29.123456 +8:00' AS datetimeoffset) AS smalldatetime);
select CAST(CAST('1980-07-08 23:59:29.123456 -8:00' AS datetimeoffset) AS smalldatetime);
select CAST(CAST('2010-07-08 23:59:29.123456 -8:00' AS datetimeoffset) AS smalldatetime);
go
-- Cast from smalldatetime
select CAST(CAST('2010-07-08' AS smalldatetime) AS time);
select CAST(CAST('2010-07-08 23:59:29.998' AS smalldatetime) AS time);
select CAST(CAST('2010-07-08 23:59:31.998' AS smalldatetime) AS time);
select CAST(CAST('1980-07-08 23:59:29.998' AS smalldatetime) AS time);
select CAST(CAST('1980-07-08 23:59:31.998' AS smalldatetime) AS time);
select CAST(CAST('2020-03-15' AS smalldatetime) AS date);
select CAST(CAST('2010-07-08 23:59:29.998' AS smalldatetime) AS date);
select CAST(CAST('2010-07-08 23:59:30.000' AS smalldatetime) AS date);
select CAST(CAST('2010-07-08 23:59:29.998' AS smalldatetime) AS datetime);
select CAST(CAST('1992-07-08 23:59:29.998' AS smalldatetime) AS datetime);
select CAST(CAST('2010-07-08 23:59:29.998' AS smalldatetime) AS datetimeoffset);
select CAST(CAST('1990-07-08 23:59:29.998' AS smalldatetime) AS datetimeoffset);
go

-- Test smalldatetime value ranges
select cast('1900-01-01' as smalldatetime);
select cast('2079-06-06' as smalldatetime);
select cast('1899-12-31 23:59:29.999' as smalldatetime);
select cast('2079-06-06 23:59:29.998' as smalldatetime);
select CAST(CAST('1899-12-31 23:59:30.000' AS datetime) AS smalldatetime);
select CAST(CAST('1899-12-31 23:59:30.000 +0:00' AS datetimeoffset) AS smalldatetime);
select CAST(CAST('2079-06-06 23:59:30.000 +1:00' AS datetimeoffset) AS smalldatetime);
select cast('1899-12-31' as smalldatetime); -- out of range
select cast('2079-06-07' as smalldatetime); -- out of range
select cast('2079-06-06 23:59:29.999' as smalldatetime); -- out of range
select CAST(CAST('2099-03-15' AS date) AS smalldatetime); -- out of range
select CAST(CAST('1800-03-15 23:59:29.998' AS datetime) AS smalldatetime);-- out of range
select CAST(CAST('2099-03-15 23:59:29.998' AS datetime) AS smalldatetime);-- out of range
select CAST(CAST('1899-12-31 23:59:30.000 +1:00' AS datetimeoffset) AS smalldatetime);-- out of range
select CAST(CAST('2099-03-15 23:59:29.998 +6:00' AS datetimeoffset) AS smalldatetime);-- out of range
go

-- Test smalldatetime default value
create table t1 (a smalldatetime, b int);
insert into t1 (b) values (1);
select a from t1 where b = 1;
go

-- Test smalldatetime as parameter for time related functions
select day(cast('2002-05-23 23:41:29.998' as smalldatetime));
select month(cast('2002-05-23 23:41:29.998' as smalldatetime));
select year(cast('2002-05-23 23:41:29.998' as smalldatetime));
select datepart(quarter, cast('2002-05-23 23:41:29.998' as smalldatetime));
select datepart(hour, cast('2002-05-23 23:41:29.998' as smalldatetime));
select datepart(dayofyear, cast('2002-05-23 23:41:29.998' as smalldatetime));
select datepart(second, cast('2002-05-23 23:41:29.998' as smalldatetime));
select datename(year, cast('2002-05-23 23:41:29.998' as smalldatetime));
select datename(dw, cast('2002-05-23 23:41:29.998' as smalldatetime));
select datename(month, cast('2002-05-23 23:41:29.998' as smalldatetime));
select dateadd(second, 56, cast('2016-12-26 23:29:29' as smalldatetime));
select dateadd(minute, 56, cast('2016-12-26 23:29:29' as smalldatetime));
select dateadd(year, 150, cast('2016-12-26 23:29:29' as smalldatetime)); -- Expect error
go

-- Clean up
drop table smalldatetime_testing;
drop table t1;
go
