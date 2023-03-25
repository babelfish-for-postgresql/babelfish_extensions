-- tsql stype create function/procedure is not supported in postgres dialect
CREATE FUNCTION hi_func("@message" varchar(20)) RETURNS VOID AS BEGIN PRINT @message END;
GO
CREATE PROCEDURE hi_proc("@message" varchar(20)) AS BEGIN PRINT @message END;
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
-- it's supported in tsql dialect
CREATE FUNCTION hi_func("@message" varchar(20)) RETURNS VOID AS BEGIN PRINT @message END;
GO
CREATE PROCEDURE hi_proc("@message" varchar(20)) AS BEGIN PRINT @message END;
GO

-- PROC is also supported in tsql dialect
create proc proc_1 as print 'Hello World from Babel';
GO
-- BABEL-219 typmod/length of sys.varchar works correctly in procudure parameter
EXEC hi_proc('Hello World');
GO
EXEC proc_1();
GO

-- clean up
drop function hi_func;
GO
drop procedure hi_proc;
GO
drop proc proc_1;
GO

-- test executing pltsql function in postgres dialect
reset babelfishpg_tsql.sql_dialect;
GO

CREATE FUNCTION test_func()
RETURNS INT
AS
BEGIN
    DECLARE @a int = 1;
    RETURN @a;
END;
GO

-- should be able execute a pltsql function in postgres dialect
SELECT @@babelfishpg_tsql_sql_dialect;
GO
select test_func();
GO
SELECT @@babelfishpg_tsql.sql_dialect;
GO

-- test executing pltsql trigger in postgres dialect
CREATE TABLE employees(
   id SERIAL PRIMARY KEY,
   first_name VARCHAR(40) NOT NULL,
   last_name VARCHAR(40) NOT NULL
);
GO

CREATE TABLE employee_audits (
   id SERIAL PRIMARY KEY,
   employee_id INT NOT NULL,
   last_name VARCHAR(40) NOT NULL
);
GO

CREATE FUNCTION log_last_name_changes() RETURNS trigger AS $$
BEGIN
    IF NEW.last_name <> OLD.last_name THEN
         INSERT INTO employee_audits(employee_id,last_name)
         VALUES(OLD.id,OLD.last_name);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
GO

CREATE TRIGGER last_name_changes
BEFORE UPDATE
ON employees
FOR EACH ROW
EXECUTE PROCEDURE log_last_name_changes();
GO

INSERT INTO employees (first_name, last_name) VALUES ('A', 'B');
INSERT INTO employees (first_name, last_name) VALUES ('C', 'D');
SELECT * FROM employees;
GO
SELECT @@babelfishpg_tsql.sql_dialect;
GO
UPDATE employees SET last_name = 'E' WHERE ID = 2;
GO
SELECT @@babelfishpg_tsql.sql_dialect;
GO
SELECT * FROM employees;
GO
SELECT * FROM employee_audits;
GO

-- cleanup
drop function test_func;
GO
drop table employees;
GO
drop table employee_audits;
GO
drop function log_last_name_changes;
GO


-- test executing a plpgsql function in tsql dialect
CREATE OR REPLACE FUNCTION test_increment(i integer) RETURNS integer AS $$
BEGIN
	RETURN i + "1";
END;
$$ LANGUAGE plpgsql;
GO

CREATE OR REPLACE FUNCTION test_increment1(i integer) RETURNS integer AS $$
BEGIN
	RETURN i + CAST(n'1' AS varchar);
END;
$$ LANGUAGE plpgsql;
GO

-- test that sql_dialect is restored even when the function has error in it
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
SELECT @@babelfishpg_tsql.sql_dialect;
GO
select test_increment(1);
GO
SELECT @@babelfishpg_tsql.sql_dialect;
GO
select test_increment1(1);
GO
SELECT @@babelfishpg_tsql.sql_dialect;
GO

-- test OBJECT_NAME function
select OBJECT_NAME('sys.columns'::regclass::Oid::int);
GO
select OBJECT_NAME('boolin'::regproc::Oid::int);
GO
select OBJECT_NAME('int4'::regtype::Oid::int);
GO
select OBJECT_NAME(1);
GO

-- test SYSDATETIME function
-- Returns of type datetime2
select pg_typeof(SYSDATETIME());
GO
-- test GETDATE function
-- Returns of type datetime
select pg_typeof(GETDATE());
GO

-- test current_timestamp function
select pg_typeof(current_timestamp);
GO
-- test calling with parenthesis, should fail
select current_timestamp();
GO

-- test CONVERT function
-- Conversion between varchar and date/time/datetime
select CONVERT(varchar(30), CAST('2017-08-25' AS date), 102);
GO
select CONVERT(varchar(30), CAST('13:01:59' AS time), 8);
GO
select CONVERT(varchar(30), CAST('13:01:59' AS time), 22);
GO
select CONVERT(varchar(30), CAST('13:01:59' AS time), 22);
GO
select CONVERT(varchar(30), CAST('2017-08-25 13:01:59' AS datetime), 100);
GO
select CONVERT(varchar(30), CAST('2017-08-25 13:01:59' AS datetime), 109);
GO
select CONVERT(date, '08/25/2017', 101);
GO
select CONVERT(time, '12:01:59', 101);
GO
select CONVERT(datetime, '2017-08-25 01:01:59PM', 120);
GO
select CONVERT(varchar, CONVERT(datetime2(7), '9999-12-31 23:59:59.9999999'));
GO

-- Conversion from float to varchar
SELECT CONVERT(varchar(30), CAST(11234561231231.234 AS float), 0);
GO
select CONVERT(varchar(30), CAST(11234561231231.234 AS float), 1);
GO
select CONVERT(varchar(30), CAST(11234561231231.234 AS float), 2);
GO
select CONVERT(varchar(30), CAST(11234561231231.234 AS float), 3);
GO

-- Conversion from money to varchar
select CONVERT(varchar(10), CAST(4936.56 AS MONEY), 0);
GO
select CONVERT(varchar(10), CAST(4936.56 AS MONEY), 1);
GO
select CONVERT(varchar(10), CAST(4936.56 AS MONEY), 2);
GO
select CONVERT(varchar(10), CAST(-4936.56 AS MONEY), 0);

-- Floor conversion to smallint, int, bigint
SELECT CONVERT(int, 99.9);
GO
SELECT CONVERT(smallint, 99.9);
GO
SELECT CONVERT(bigint, 99.9);
GO
SELECT CONVERT(int, -99.9);
GO
SELECT CONVERT(int, '99');
GO
SELECT CONVERT(int, CAST(99.9 AS double precision));
GO
SELECT CONVERT(int, CAST(99.9 AS real));
GO

-- test TRY_CONVERT function
-- Conversion between different types and varchar
select TRY_CONVERT(varchar(30), CAST('2017-08-25' AS date), 102);
GO
select TRY_CONVERT(varchar(30), CAST('13:01:59' AS time), 8);
GO
select TRY_CONVERT(varchar(30), CAST('13:01:59' AS time), 22);
GO
select TRY_CONVERT(varchar(30), CAST('2017-08-25 13:01:59' AS datetime), 109);
GO
select TRY_CONVERT(varchar(30), CAST('11234561231231.234' AS float), 0);
GO
select TRY_CONVERT(varchar(30), CAST('11234561231231.234'AS float, 1);
GO
select TRY_CONVERT(varchar(10), CAST(4936.56 AS MONEY), 0);
GO

-- Wrong conversions that return NULL
select TRY_CONVERT(date, 123);
GO
select TRY_CONVERT(time, 123);
GO
select TRY_CONVERT(datetime, 123);
GO
select TRY_CONVERT(money, 'asdf');
GO

-- test PARSE function
-- Conversion from string to date/time/datetime
select PARSE('2017-08-25' AS date);
GO
select PARSE('2017-08-25' AS date USING 'Cs-CZ');
GO
select PARSE('08/25/2017' AS date USING 'en-US');
GO
select PARSE('25/08/2017' AS date USING 'de-DE');
GO
select PARSE('13:01:59' AS time);
GO
select PARSE('13:01:59' AS time USING 'en-US');
GO
select PARSE('13:01:59' AS time USING 'zh-CN');
GO
select PARSE('2017-08-25 13:01:59' AS datetime);
GO
select PARSE('2017-08-25 13:01:59' AS datetime USING 'zh-CN');
GO
select PARSE('12:01:59' AS time);
GO
select PARSE('2017-08-25 01:01:59PM' AS datetime);
GO

-- Test if unnecessary culture arg given
select PARSE('123' AS int USING 'de-DE');
GO

-- test TRY_PARSE function
-- Expect null return on error
-- Conversion from string to date/time/datetime
select TRY_PARSE('2017-08-25' AS date);
GO
select TRY_PARSE('2017-08-25' AS date USING 'Cs-CZ');
GO
select TRY_PARSE('789' AS date USING 'en-US');
GO
select TRY_PARSE('asdf' AS date USING 'de-DE');
GO
select TRY_PARSE('13:01:59' AS time);
GO
select TRY_PARSE('asdf' AS time USING 'en-US');
GO
select TRY_PARSE('13-12-21' AS time USING 'zh-CN');
GO
select TRY_PARSE('2017-08-25 13:01:59' AS datetime);
GO
select TRY_PARSE('20asdf17' AS datetime USING 'de-DE');
GO

-- Wrong conversions that return NULL
select TRY_PARSE('asdf' AS numeric(3,2));
GO
select TRY_PARSE('123' AS datetime2);
GO
select TRY_PARSE('asdf' AS MONEY);
GO
select TRY_PARSE('asdf' AS int USING 'de-DE');
GO

-- test serverproperty() function
-- invalid property name, should reutnr NULL
select serverproperty(n'invalid property');
GO
-- valid supported properties
select serverproperty(n'collation');
GO
select serverproperty(n'collationId');
GO
select serverproperty(n'IsSingleUser');
GO
select serverproperty(n'ServerName') = aurora_db_instance_identifier() as condition;
GO

-- test ISDATE function
-- test valid argument
SELECT ISDATE('12/26/2016');
GO
SELECT ISDATE('12-26-2016');
GO
SELECT ISDATE('12.26.2016');
GO
SELECT ISDATE('2016-12-26 23:30:05.523456');
GO
-- test invalid argument
SELECT ISDATE('02/30/2016');
GO
SELECT ISDATE('12/32/2016');
GO
SELECT ISDATE('1995-10-1a');
GO
SELECT ISDATE(NULL);
GO

-- test DATEFROMPARTS function
-- test valid arguments
select datefromparts(2020,12,31);
GO
-- test invalid arguments, should fail
select datefromparts(2020, 2, 30);
GO
select datefromparts(2020, 13, 1);
GO
select datefromparts(-4, 3, 150);
GO
select datefromparts(10, 55, 10.1);
GO
select datefromparts('2020', 55, 100.1);
GO

-- test DATETIMEFROMPARTS function
-- test valid arguments
select datetimefromparts(2016, 12, 26, 23, 30, 5, 32);
GO
select datetimefromparts(2016.0, 12, 26, 23, 30, 5, 32);
GO
select datetimefromparts(2016.1, 12, 26, 23, 30, 5, 32);
GO
select datetimefromparts(2016, 12, 26.99, 23, 30, 5, 32);
GO
select datetimefromparts(2016, 12.90, 26, 23, 30, 5, 32);
GO
-- test invalid arguments
select datetimefromparts(2016, 2, 30, 23, 30, 5, 32);
GO
select datetimefromparts(2016, 12, 26, 23, 30, 5);
GO
select datetimefromparts(2016, 12, 26, 23, 30, 5, NULL);
GO

-- test DATEPART function
-- test all valid datepart arguments
SELECT DATEPART(YEAR, CAST('2016-12-26 23:30:05.523456 -08:00' AS DATETIMEOFFSET));
GO
select datepart(yyyy, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(yy, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(quarter, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(qq, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(qq, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(q, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(month, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(mm, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(m, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(dayofyear, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(dy, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(day, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(dd, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(d,CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(week, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(wk, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(ww, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(weekday, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(dw, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(hour, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(hh, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(minute, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(n, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(second, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(ss, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(s, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(millisecond, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(ms, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(microsecond, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(mcs,CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(nanosecond, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(ns, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(tzoffset, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(tz, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(iso_week, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(isowk, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
select datepart(isoww, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset));
GO
-- test different types of date/time arguments
select datepart(month, CAST('2016-12-26 23:30:05.523'AS sys.datetime));
GO
select datepart(quarter, CAST('2016-12-26 23:30:05.523456'AS datetime2));
GO
select datepart(hour, CAST('2016-12-26 23:30:05'AS smalldatetime));
GO
select datepart(dayofyear,CAST('2016-12-26'AS date));
GO
select datepart(second,CAST ('04:12:34.876543'AS time));
GO
-- test edge cases: try to get datepart that does not exist in the argument
select datepart(year, cast('12:10:30.123' as time));
GO
select datepart(yyyy, cast('12:10:30.123' as time));
GO
select datepart(yy, cast('12:10:30.123' as time));
GO
select datepart(quarter, cast('12:10:30.123' as time));
GO
select datepart(qq, cast('12:10:30.123' as time));
GO
select datepart(q, cast('12:10:30.123' as time));
GO
select datepart(month, cast('12:10:30.123' as time));
GO
select datepart(mm, cast('12:10:30.123' as time));
GO
select datepart(m, cast('12:10:30.123' as time));
GO
select datepart(dayofyear, cast('12:10:30.123' as time));
GO
select datepart(dy, cast('12:10:30.123' as time));
GO
select datepart(y, cast('12:10:30.123' as time));
GO
select datepart(day, cast('12:10:30.123' as time));
GO
select datepart(dd, cast('12:10:30.123' as time));
GO
select datepart(d, cast('12:10:30.123' as time));
GO
select datepart(week, cast('12:10:30.123' as time));
GO
select datepart(wk, cast('12:10:30.123' as time));
GO
select datepart(ww, cast('12:10:30.123' as time));
GO
select datepart(weekday, cast('12:10:30.123' as time));
GO
select datepart(dw, cast('12:10:30.123' as time));
GO
select datepart(tzoffset, cast('12:10:30.123' as time));
GO
select datepart(tz, cast('12:10:30.123' as time));
GO
select datepart(iso_week, cast('12:10:30.123' as time));
GO
select datepart(isowk, cast('12:10:30.123' as time));
GO
select datepart(isoww, cast('12:10:30.123' as time));
GO
select datepart(hour, cast('2016-12-26' as date));
GO
select datepart(hh, cast('2016-12-26' as date));
GO
select datepart(minute, cast('2016-12-26' as date));
GO
select datepart(n, cast('2016-12-26' as date));
GO
select datepart(second, cast('2016-12-26' as date));
GO
select datepart(ss, cast('2016-12-26' as date));
GO
select datepart(s, cast('2016-12-26' as date));
GO
select datepart(millisecond, cast('2016-12-26' as date));
GO
select datepart(ms, cast('2016-12-26' as date));
GO
select datepart(microsecond, cast('2016-12-26' as date));
GO
select datepart(mcs, cast('2016-12-26' as date));
GO
select datepart(nanosecond, cast('2016-12-26' as date));
GO
select datepart(ns, cast('2016-12-26' as date));
GO
-- test invalid interval, expect error
select datepart(invalid_interval, cast('2016-12-26 23:30:05.523456' as date));
GO
select datepart(invalidinterval, cast('12:10:30.123' as time));
GO

-- test DATENAME function
select datename(year, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select datename(dd, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select datename(weekday, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select datename(dw, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select datename(month, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select datename(mm, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select datename(m, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select datename(isowk, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
-- test invalid argument, expect error
select datename(invalid_interval, cast('2016-12-26 23:30:05.523456' as date));
GO

-- test DATEFIRST option, together DATEPART function
-- This shows the return value for the week and weekday datepart for '2007-04-21' for each SET DATEFIRST argument.
-- January 1, 2007 falls on a Monday. April 21, 2007 falls on a Saturday.
-- DATEFIRST week weekday
-- 1	16	6
-- 2	17	5
-- 3	17	4
-- 4	17	3
-- 5	17	2
-- 6	17	1
-- 7	16	7
select @@datefirst;
GO
set datefirst 1;
select datepart(week, CAST('2007-04-21'AS date)), datepart(weekday, CAST('2007-04-21'AS date));
GO

set datefirst 2;
select datepart(week, CAST('2007-04-21'AS date)), datepart(weekday, CAST('2007-04-21'AS date));
GO
set datefirst 3;
select datepart(week, CAST('2007-04-21'AS date)), datepart(weekday, CAST('2007-04-21'AS date));
GO
set datefirst 4;
select datepart(week, CAST('2007-04-21'AS date)), datepart(weekday, CAST('2007-04-21'AS date));
GO
set datefirst 5;
select datepart(week, CAST('2007-04-21'AS date)), datepart(weekday, CAST('2007-04-21'AS date));
GO
set datefirst 6;
select datepart(week, CAST('2007-04-21'AS date)), datepart(weekday, CAST('2007-04-21'AS date));
GO
set datefirst 7;
select datepart(week, CAST('2007-04-21'AS date)), datepart(weekday, CAST('2007-04-21'AS date));
GO
-- test edge case: date within the week of Jan. 1st
select datepart(week, CAST('2007-01-01'AS date)), datepart(weekday, CAST('2007-01-01'AS date));
GO
select datepart(week, CAST('2007-01-02'AS date)), datepart(weekday, CAST('2007-01-02'AS date));
GO
select datepart(week, CAST('2007-01-03'AS date)), datepart(weekday, CAST('2007-01-03'AS date));
GO
select datepart(week, CAST('2007-01-04'AS date)), datepart(weekday, CAST('2007-01-04'AS date));
GO
select datepart(week, CAST('2007-01-05'AS date)), datepart(weekday, CAST('2007-01-05'AS date));
GO
select datepart(week, CAST('2007-01-06'AS date)), datepart(weekday, CAST('2007-01-06'AS date));
GO
-- test edge case: date just outside the week of Jan. 1st
select datepart(week, CAST('2007-01-07'AS date)), datepart(weekday, CAST('2007-01-07'AS date));
GO

-- test DATEDIFF function
select datediff(year, CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(quarter, CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(month, CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(dayofyear, CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(day, CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(week,CAST('2037-03-01 23:30:05.523'AS sys.datetime),CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(hour, CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(minute,CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(second, CAST('2037-03-01 23:30:05.523'AS sys.datetime), CAST('2036-02-28 23:30:05.523'AS sys.datetime));
GO
select datediff(millisecond, CAST('2036-02-28 01:23:45.234'AS sys.datetime), CAST('2036-02-28 01:23:45.123'AS sys.datetime));
GO
select datediff(microsecond, CAST('2036-02-28 01:23:45.234'AS sys.datetime), CAST('2036-02-28 01:23:45.123'AS sys.datetime));
GO
select datediff(nanosecond, CAST('2036-02-28 01:23:45.234'AS sys.datetime), CAST('2036-02-28 01:23:45.123'AS sys.datetime));
GO
-- test different types of date/time arguments
select datediff(minute, CAST('2016-12-26 23:30:05.523456+8'AS datetimeoffset), CAST('2016-12-31 23:30:05.523456+8'AS datetimeoffset));
GO
select datediff(quarter,CAST('2016-12-26 23:30:05.523456'AS datetime2), CAST('2018-08-31 23:30:05.523456'AS datetime2));
GO
select datediff(hour, CAST('2016-12-26 23:30:05'AS smalldatetime), CAST('2016-12-28 21:29:05'AS smalldatetime));
GO
select datediff(year, CAST('2037-03-01'AS date), CAST('2036-02-28'AS date));
GO

-- test DATEADD function
select dateadd(year, 2, '20060830');
GO
select dateadd(quarter, 2, '20060830');
GO
select dateadd(month, 1, '20060831');
GO
select dateadd(dayofyear, 2, '20060830');
GO
select dateadd(day, 2, '20060830');
GO
select dateadd(week, 2, '20060830');
GO
select dateadd(weekday, 2, '20060830');
GO
select dateadd(hour, 2, '20060830');
GO
select dateadd(minute, 2, '20060830');
GO
select dateadd(second, 2, '20060830');
GO
select dateadd(millisecond, 123, '20060830');
GO
select dateadd(microsecond, 123456, '20060830');
GO
select dateadd(nanosecond, 123456, '20060830');
GO
-- test different types of date/time arguments
select dateadd(hour, 2, '23:12:34.876543');
GO
select dateadd(quarter, 3, '2037-03-01');
GO
select dateadd(minute, 70, '2016-12-26 23:30:05.523456+8');
GO
select dateadd(month, 2, '2016-12-26 23:30:05.523456');
GO
select dateadd(second, 56, '2016-12-26 23:30:05');
GO
-- test negative argument
select dateadd(year, -2, '20060830'::datetime);
GO
select dateadd(month, -20, '2016-12-26 23:30:05.523456'::datetime2);
GO
select dateadd(hour, -2, '01:12:34.876543'::time);
GO
select dateadd(minute, -70, '2016-12-26 00:30:05.523456+8'::datetimeoffset);
GO
select dateadd(second, -56, '2016-12-26 00:00:55'::smalldatetime);
GO
-- test return type
select pg_typeof(dateadd(hour, -2, '01:12:34.876543'::time));
GO
select pg_typeof(dateadd(second, -56, '2016-12-26 00:00:55'::smalldatetime));
GO
select pg_typeof(dateadd(year, -2, '20060830'::datetime));
GO
select pg_typeof(dateadd(month, -20, '2016-12-26 23:30:05.523456'::datetime2));
GO
select pg_typeof(dateadd(minute, -70, '2016-12-26 00:30:05.523456+8'::datetimeoffset));
GO
-- test illegal usage
select dateadd(minute, 2, '2037-03-01'::date);
GO
select dateadd(day, 4, '04:12:34.876543'::time);
GO
-- test using variables, instead of constants, for the second parameter
create table dateadd_table(a int, b datetime);
GO
insert into dateadd_table values(1, '2020-10-29'::datetime);
select * from dateadd_table;
GO
update dateadd_table set b = dateadd(dd, a, '2020-10-30'::datetime);
GO
select * from dateadd_table;
GO
create procedure dateadd_procedure as
begin
	declare @d int = 1
	update dateadd_table set b = dateadd(dd, @d, CAST('2020-10-31' AS datetime))
end;
GO
EXEC dateadd_procedure();
GO
select * from dateadd_table;
GO

-- test CHARINDEX function
select CHARINDEX('hello', 'hello world');
GO
select CHARINDEX('hello  ', 'hello world');
GO
select CHARINDEX('hello world', 'hello');
GO
-- test NULL input
select CHARINDEX(NULL, NULL);
GO
select CHARINDEX(NULL, 'string');
GO
select CHARINDEX('pattern', NULL);
GO
select CHARINDEX('pattern', 'string', NULL);
GO
-- test start_location parameter
select CHARINDEX('hello', 'hello world', -1);
GO
select CHARINDEX('hello', 'hello world', 0);
GO
select CHARINDEX('hello', 'hello world', 1);
GO
select CHARINDEX('hello', 'hello world', 2);
GO
select CHARINDEX('world', 'hello world', 6);
GO
select CHARINDEX('world', 'hello world', 7);
GO
select CHARINDEX('world', 'hello world', 8);
GO
select CHARINDEX('is', 'This is a string');
GO
select CHARINDEX('is', 'This is a string', 4);
GO

-- test STUFF function
select STUFF(n'abcdef', 2, 3, n'ijklmn');  
GO
select STUFF(N' abcdef', 2, 3, N'ijklmn ');
GO
select STUFF(N'abcdef', 2, 3, N' ijklmn ');
GO
select STUFF(N'abcdef', 2, 3, N'ijklmn  ');
GO
-- test corner cases
-- when start is negative or zero or longer than expr, return NULL
select STUFF(n'abcdef', -1, 3, n'ijklmn');  
GO
select STUFF(n'abcdef', 0, 3, n'ijklmn');  
GO
select STUFF(n'abcdef', 7, 3, n'ijklmn');  
GO
-- when length is negative, return NULL
select STUFF(n'abcdef', 2, -3, n'ijklmn');  
GO
-- when length is zero, just insert without deleting
select STUFF(n'abcdef', 2, 0, n'ijklmn');  
GO
-- when length is longer than expr, delete up to the last character in expr
select STUFF(n'abcdef', 2, 7, n'ijklmn');
GO
-- when replace_expr is NULL, just delete without inserting
select STUFF(n'abcdef', 2, 3, NULL);
GO
-- when argument are type unknown
select STUFF('abcdef', 2, 3, 'ijklmn');
GO
select STUFF('abcdef', 2, 3, n'ijklmn');
GO
select STUFF(n'abcdef', 2, 3, 'ijklmn');
GO
-- when argument are type text
SELECT STUFF(CAST('abcdef' as text), 2, 3, CAST('ijklmn' as text));
GO
SELECT STUFF(CAST('abcdef' as text), 2, 3, 'ijklmn');
GO
SELECT STUFF('abcdef', 2, 3, CAST('ijklmn' as text));
GO
-- when argument are type sys.varchar
SELECT STUFF(CAST('abcdef' as sys.varchar), 2, 3, CAST('ijklmn' as sys.varchar));
GO
SELECT STUFF('abcdef', 2, 3, CAST('ijklmn' as sys.varchar));
GO
SELECT STUFF(CAST('abcdef' as sys.varchar), 2, 3, 'ijklmn');
GO

-- test ROUND function
-- test rounding to the left of decimal point
select ROUND(748.58, -1);
GO
select ROUND(748.58, -2);
GO
select ROUND(748.58, -3);
GO
select ROUND(748.58, -4);
GO
select ROUND(-648.1234, -2);
GO
select ROUND(-648.1234, -3);
GO
select ROUND(-1548.1234, -3);
GO
select ROUND(-1548.1234, -4);
GO
-- test NULL input
select ROUND(NULL, -3);
GO
select ROUND(748.58, NULL);
GO
-- test rounding
SELECT ROUND(123.9994, 3);
GO
SELECT ROUND(123.9995, 3);
GO
SELECT ROUND(123.4545, 2);
GO
SELECT ROUND(123.45, -2);
GO
-- test function parameter, i.e. truncation when not NULL or 0
SELECT ROUND(150.75, 0);
GO
SELECT ROUND(150.75, 0, 0);
GO
SELECT ROUND(150.75, 0, NULL);
GO
SELECT ROUND(150.75, 0, 1);
GO
-- test negative numbers
SELECT ROUND(-150.49, 0);
GO
SELECT ROUND(-150.75, 0);
GO
SELECT ROUND(-150.49, 0, 1);
GO
SELECT ROUND(-150.75, 0, 1);
GO

-- test SELECT ROUND(col, )
create table t1 (col numeric(4,2));
GO
insert into t1 values (64.24);
insert into t1 values (79.65);
insert into t1 values (NULL);
GO
select ROUND(col, 3) from t1;
GO
select ROUND(col, 2) from t1;
GO
select ROUND(col, 1) from t1;
GO
select ROUND(col, 0) from t1;
GO
select ROUND(col, -1) from t1;
GO
select ROUND(col, -2) from t1;
GO
select ROUND(col, -3) from t1;
GO
select ROUND(col, 1, 1) from t1;
GO
drop table t1;
GO

-- test DAY function
select DAY(CAST('2016-12-26 23:30:05.523456+8' AS datetimeoffset));
GO
select DAY(CAST('2016-12-26 23:30:05.523456' AS datetime2));
GO
select DAY(CAST('2016-12-26 23:30:05' AS smalldatetime));
GO
select DAY(CAST('04:12:34.876543' AS time));
GO
select DAY(CAST('2037-03-01' AS date));
GO
select DAY(CAST('2037-03-01 23:30:05.523' AS sys.datetime));
GO
-- test MONTH function
select MONTH('2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select MONTH('2016-12-26 23:30:05.523456'::datetime2);
GO
select MONTH('2016-12-26 23:30:05'::smalldatetime);
GO
select MONTH('04:12:34.876543'::time);
GO
select MONTH('2037-03-01'::date);
GO
select MONTH('2037-03-01 23:30:05.523'::sys.datetime);
GO
-- test YEAR function
select YEAR('2016-12-26 23:30:05.523456+8'::datetimeoffset);
GO
select YEAR('2016-12-26 23:30:05.523456'::datetime2);
GO
select YEAR('2016-12-26 23:30:05'::smalldatetime);
GO
select YEAR('04:12:34.876543'::time);
GO
select YEAR('2037-03-01'::date);
GO
select YEAR('2037-03-01 23:30:05.523'::sys.datetime);
GO

-- test SPACE function
select SPACE(NULL);
GO
select SPACE(2);
GO
select LEN(SPACE(5));
GO
select DATALENGTH(SPACE(5));
GO

-- test COUNT and COUNT_BIG aggregate function
CREATE TABLE t2(a int, b int);
GO
INSERT INTO t2 VALUES(1, 100);
INSERT INTO t2 VALUES(2, 200);
INSERT INTO t2 VALUES(NULL, 300);
INSERT INTO t2 VALUES(2, 400);
GO
CREATE TABLE t3(a varchar(255), b varchar(255),c int);
GO
INSERT INTO t3 VALUES('xyz', 'a',1);
INSERT INTO t3 VALUES('xyz', 'b',1);
INSERT INTO t3 VALUES('abc', 'a',2);
INSERT INTO t3 VALUES('abc', 'b',2);
INSERT INTO t3 VALUES('efg', 'a',3);
INSERT INTO t3 VALUES('efg', 'b',3);
INSERT INTO t3 VALUES(NULL, NULL, 1);
GO

-- Aggregation Function Syntax
-- COUNT[_BIG] ( { [ [ ALL | DISTINCT ] expression ] | * } )
-- should return all rows - 4
SELECT COUNT(*) from t2;
GO
SELECT pg_typeof(COUNT(*)) from t2;
GO
SELECT COUNT_BIG(*) from t2;
GO
SELECT pg_typeof(COUNT_BIG(*)) from t2;
GO
-- should return all rows where a is not NULL - 3
SELECT COUNT(a) from t2;
GO
SELECT pg_typeof(COUNT(a)) from t2;
GO
SELECT COUNT_BIG(a) from t2;
GO
SELECT pg_typeof(COUNT_BIG(a)) from t2;
GO
-- should return all rows where a is not NULL - 3
SELECT COUNT(ALL a) from t2;
GO
SELECT pg_typeof(COUNT(ALL a)) from t2;
GO
SELECT COUNT_BIG(ALL a) from t2;
GO
SELECT pg_typeof(COUNT_BIG(ALL a)) from t2;
GO
-- should return all rows where a is distinct - 2
SELECT COUNT(DISTINCT a) from t2;
GO
SELECT pg_typeof(COUNT(DISTINCT a)) from t2;
GO
SELECT COUNT_BIG(DISTINCT a) from t2;
GO
SELECT pg_typeof(COUNT_BIG(DISTINCT a)) from t2;
GO

-- Analytic Function Syntax
-- COUNT[_BIG] ( [ ALL ]  { expression | * } ) OVER ( [ <partition_by_clause> ] )
SELECT pg_typeof(COUNT(*) OVER (PARTITION BY a)) from t2;
GO
SELECT pg_typeof(COUNT_BIG(*) OVER (PARTITION BY a)) from t2;
GO
SELECT pg_typeof(COUNT(a) OVER (PARTITION BY a)) from t2;
GO
SELECT pg_typeof(COUNT_BIG(a) OVER (PARTITION BY a)) from t2;
GO
SELECT pg_typeof(COUNT(ALL a) OVER (PARTITION BY a)) from t2;
GO
SELECT pg_typeof(COUNT_BIG(ALL a) OVER (PARTITION BY a)) from t2;
GO
SELECT COUNT(*) from t3;
GO
SELECT a, b, COUNT(*) OVER () from t3;
GO
-- The result for order by is different in sql server because we have
-- an ordering issue for null type (JIRA: BABEL-788)
SELECT a, b, COUNT(*) OVER (ORDER BY a) from t3;
GO
SELECT a, b, COUNT(*) OVER (ORDER BY a DESC) from t3;
GO
SELECT a, b, COUNT(*) OVER(PARTITION BY a) from t3;
GO
SELECT a, b, COUNT(*) OVER(PARTITION BY a ORDER BY b) from t3;
GO
SELECT a, b, COUNT(*) OVER(PARTITION BY a ORDER BY b ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)  from t3;
GO
SELECT COUNT_BIG(*) from t3;
GO
SELECT a, b, COUNT_BIG(*) OVER () from t3;
GO
SELECT a, b, COUNT_BIG(*) OVER (ORDER BY a) from t3;
GO
SELECT a, b, COUNT_BIG(*) OVER (ORDER BY a DESC) from t3;
GO
SELECT a, b, COUNT_BIG(*) OVER(PARTITION BY a) from t3;
GO
SELECT a, b, COUNT_BIG(*) OVER(PARTITION BY a ORDER BY b) from t3;
GO
SELECT a, b, COUNT_BIG(*) OVER(PARTITION BY a ORDER BY b ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)  from t3;
GO

-- COUNT(*) takes no parameters and does not support the use of DISTINC, expect error
SELECT COUNT(DISTINCT *) from t3;
GO
SELECT COUNT(ALL *) from t3;
GO
DROP TABLE t2;
GO
DROP TABLE t3;
GO

-- clean up
drop function test_increment;
GO
drop function test_increment1;
GO
drop table dateadd_table;
GO
drop procedure dateadd_procedure;
GO

-- test inline table-valued functions
-- simple case
create function itvf1 (@number int) returns table as return (select 1 as a, 2 as b);
GO
select * from itvf1(5);
GO
-- should fail because column names are not specified
create function itvf2 (@number int) returns table as return (select 1, 2);
GO

-- select from a table
create table example_table(name text, age int);
GO
insert into example_table values('hello', 3);
GO
-- should have 'a' and 'b' as result column names
create function itvf3 (@number int) returns table as return (select name as a, age as b from example_table);
GO
select * from itvf3(5);
GO
-- test returning multiple rows
insert into example_table values('hello1', 4);
insert into example_table values('hello2', 5);
insert into example_table values('hello3', 6);
select * from itvf3(5);
GO

-- invoke a function
create function itvf4 (@number int) returns table as
GO
return (select sys.serverproperty(N'collation') as property1, sys.serverproperty(N'IsSingleUser') as property2);
GO
select * from itvf4(5);
GO

-- case where the return table has only one column - Postgres considers these as
-- scalar functions
create or replace function itvf5 (@number int) returns table as return (select 1 as a);
GO
select * from itvf5(5);
GO
create or replace function itvf6 (@number int) returns table as
GO
return (select sys.serverproperty(N'collation') as property);
GO
select * from itvf6(5);
GO

-- complex queries with use of function parameter
create table id_name(id int, name text);
GO
insert into id_name values(1001, 'adam');
insert into id_name values(1002, 'bob');
insert into id_name values(1003, 'chaz');
insert into id_name values(1004, 'dave');
insert into id_name values(1005, 'ed');
GO

create table id_score(id int, score int);
GO
insert into id_score values(1001, 90);
insert into id_score values(1001, 70);
insert into id_score values(1002, 90);
insert into id_score values(1002, 80);
insert into id_score values(1003, 80);
insert into id_score values(1003, 70);
insert into id_score values(1004, 80);
insert into id_score values(1004, 60);
insert into id_score values(1005, 80);
insert into id_score values(1005, 100);
GO

create function itvf7 (@number int) returns table as return (
GO
select n.id, n.name as first_name, sum(s.score) as total_score
from id_name as n
join id_score as s
on n.id = s.id
where s.id <= @number
group by n.id, n.name
order by n.id
);
GO

select * from itvf7(1004);
GO

-- test inline table-valued function with table-valued parameter
create type tableType as table(
	a text not null,
	b int primary key,
	c int);
GO

create function itvf8 (@number int, @tableVar tableType READONLY) returns table as return (
select n.id, n.name as first_name, sum(s.score) as total_score
from id_name as n
join id_score as s
on n.id = s.id
where s.id <= @number and s.id in (select c from @tableVar)
group by n.id, n.name
order by n.id
);
GO

create procedure itvf8_proc as
begin
	declare @tableVariable tableType
	insert into @tableVariable values('hello1', 1, 1001)
	insert into @tableVariable values('hello2', 2, 1002)
	select * from itvf8(1004, @tableVariable)
end;
GO

EXEC itvf8_proc();
GO

-- test using parameter in projection list
create function itvf9(@number int) returns table as return (
select @number as a from id_name
);
GO

select * from itvf9(1);
GO

-- test invalid ITVFs
-- function does not have RETURN QUERY
create function itvf10(@number int) returns table as BEGIN select * from id_name END;
GO
-- function has more than one RETURN QUERY
create function itvf11(@number int) returns table as
BEGIN
	return select * from id_name
	return select id from id_name
END;
GO

-- test creating ITVF in a transaction and rollback - should still work as
-- normal despite the function validator's modification of the pg_proc entry
begin transaction;
create function itvf12(@number int) returns table as return (
select @number as a from id_name
);
rollback;
select * from itvf12(1);
GO

-- "AS" keyword is optional in TSQL function
\tsql on
create function babel651_f() returns int
begin
  return 1
end
go
create table babel651_t(a int);
go
create function babel651_itvf() returns table
  return (select * from babel651_t)
go
create function babel651_mstvf(@i int) returns @tableVar table
(
	a text not null
)
begin
	insert into @tableVar values('hello1');
end;
go

select babel651_f();
go
select * from babel651_itvf();
go
select * from babel651_mstvf(1);
go
\tsql off

-- clean up
drop function itvf1;
GO
drop table example_table;
GO
drop function itvf3;
GO
drop function itvf4;
GO
drop function itvf5;
GO
drop function itvf6;
GO
drop table id_name;
GO
drop table id_score;
GO
drop function itvf7;
GO
drop procedure itvf8_proc;
GO
drop function itvf8;
GO
drop type tableType;
GO
drop function itvf9;
GO
drop table babel651_t;
GO
drop function babel651_f;
GO
drop function babel651_itvf;
GO
drop function babel651_mstvf;
GO

-- test RETURN not followed by a semicolon
\tsql on
create function test_return1(@stringToSplit VARCHAR(MAX))
RETURNS @returnList TABLE([Name] [nvarchar] (500))
AS
BEGIN
	RETURN
END
GO
select * from test_return1('test');
GO
drop function test_return1;
GO
create function test_return2(@stringToSplit VARCHAR(MAX))
RETURNS @returnList TABLE([Name] [nvarchar] (500))
AS
BEGIN
	RETURN;
END
GO
select * from test_return2('test');
GO
drop function test_return2;
GO
create function test_return3(@a int)
RETURNS @returnList TABLE([Name] [nvarchar] (500))
AS
BEGIN
	IF @a = 1
		RETURN
	SELECT @a = 2
	INSERT into @returnList values('abc')
	RETURN
END
GO
select * from test_return3(1);
GO
select * from test_return3(2);
GO
drop function test_return3;
GO
create function test_return4(@a int)
RETURNS @returnList TABLE([Name] [nvarchar] (500))
AS
BEGIN
	IF @a = 1
		RETURN
	ELSE
		SELECT @a = 2
		INSERT into @returnList values('abc')
		RETURN
END
GO
select * from test_return4(1);
GO
select * from test_return4(2);
GO
drop function test_return4;
GO