-- tsql stype create function/procedure is not supported in postgres dialect
CREATE FUNCTION hi_func("@message" varchar(20)) RETURNS VOID AS BEGIN PRINT @message END;
CREATE PROCEDURE hi_proc("@message" varchar(20)) AS BEGIN PRINT @message END;

set babelfishpg_tsql.sql_dialect = "tsql";
-- it's supported in tsql dialect
CREATE FUNCTION hi_func("@message" varchar(20)) RETURNS VOID AS BEGIN PRINT @message END;
CREATE PROCEDURE hi_proc("@message" varchar(20)) AS BEGIN PRINT @message END;
-- PROC is also supported in tsql dialect
create proc proc_1 as print 'Hello World from Babel';
-- BABEL-219 typmod/length of sys.varchar works correctly in procudure parameter
call hi_proc('Hello World');
call proc_1();

-- clean up
drop function hi_func;
drop procedure hi_proc;
drop proc proc_1;

-- test executing pltsql function in postgres dialect
reset babelfishpg_tsql.sql_dialect;

CREATE OR REPLACE FUNCTION test_func() RETURNS int AS $$
BEGIN
	DECLARE @a int = 1;
	RETURN @a
END;
$$ LANGUAGE pltsql;

-- should be able execute a pltsql function in postgres dialect
show babelfishpg_tsql.sql_dialect;
select test_func();
show babelfishpg_tsql.sql_dialect;

-- test executing pltsql trigger in postgres dialect
CREATE TABLE employees(
   id SERIAL PRIMARY KEY,
   first_name VARCHAR(40) NOT NULL,
   last_name VARCHAR(40) NOT NULL
);

CREATE TABLE employee_audits (
   id SERIAL PRIMARY KEY,
   employee_id INT NOT NULL,
   last_name VARCHAR(40) NOT NULL
);

CREATE OR REPLACE FUNCTION log_last_name_changes() RETURNS trigger AS $$
BEGIN
    IF NEW.last_name <> OLD.last_name THEN
         INSERT INTO employee_audits(employee_id,last_name)
         VALUES(OLD.id,OLD.last_name);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER last_name_changes
BEFORE UPDATE
ON employees
FOR EACH ROW
EXECUTE PROCEDURE log_last_name_changes();

INSERT INTO employees (first_name, last_name) VALUES ('A', 'B');
INSERT INTO employees (first_name, last_name) VALUES ('C', 'D');
SELECT * FROM employees;
show babelfishpg_tsql.sql_dialect;
UPDATE employees SET last_name = 'E' WHERE ID = 2;
show babelfishpg_tsql.sql_dialect;
SELECT * FROM employees;
SELECT * FROM employee_audits;

-- cleanup
drop function test_func;
drop table employees;
drop table employee_audits;
drop function log_last_name_changes;


-- test executing a plpgsql function in tsql dialect
CREATE OR REPLACE FUNCTION test_increment(i integer) RETURNS integer AS $$
BEGIN
	RETURN i + "1";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_increment1(i integer) RETURNS integer AS $$
BEGIN
	RETURN i + CAST(n'1' AS varchar);
END;
$$ LANGUAGE plpgsql;

-- test that sql_dialect is restored even when the function has error in it
set babelfishpg_tsql.sql_dialect = "tsql";
show babelfishpg_tsql.sql_dialect;
select test_increment(1);
show babelfishpg_tsql.sql_dialect;
select test_increment1(1);
show babelfishpg_tsql.sql_dialect;

-- test OBJECT_NAME function
select OBJECT_NAME('sys.columns'::regclass::Oid::int);
select OBJECT_NAME('boolin'::regproc::Oid::int);
select OBJECT_NAME('int4'::regtype::Oid::int);
select OBJECT_NAME(1);

-- test SYSDATETIME function
-- Returns of type datetime2
select pg_typeof(SYSDATETIME());
-- test GETDATE function
-- Returns of type datetime
select pg_typeof(GETDATE());

-- test current_timestamp function
select pg_typeof(current_timestamp);
-- test calling with parenthesis, should fail
select current_timestamp();

-- test CONVERT function
-- Conversion between varchar and date/time/datetime
select CONVERT(varchar(30), CAST('2017-08-25' AS date), 102);
select CONVERT(varchar(30), CAST('13:01:59' AS time), 8);
select CONVERT(varchar(30), CAST('13:01:59' AS time), 22);
select CONVERT(varchar(30), CAST('13:01:59' AS time), 22);
select CONVERT(varchar(30), CAST('2017-08-25 13:01:59' AS datetime), 100);
select CONVERT(varchar(30), CAST('2017-08-25 13:01:59' AS datetime), 109);
select CONVERT(date, '08/25/2017', 101);
select CONVERT(time, '12:01:59', 101);
select CONVERT(datetime, '2017-08-25 01:01:59PM', 120);
select CONVERT(varchar, CONVERT(datetime2(7), '9999-12-31 23:59:59.9999999'));

-- Conversion from float to varchar
select CONVERT(varchar(30), 11234561231231.234::float, 0);
select CONVERT(varchar(30), 11234561231231.234::float, 1);
select CONVERT(varchar(30), 11234561231231.234::float, 2);
select CONVERT(varchar(30), 11234561231231.234::float, 3);

-- Conversion from money to varchar
select CONVERT(varchar(10), CAST(4936.56 AS MONEY), 0);
select CONVERT(varchar(10), CAST(4936.56 AS MONEY), 1);
select CONVERT(varchar(10), CAST(4936.56 AS MONEY), 2);
select CONVERT(varchar(10), CAST(-4936.56 AS MONEY), 0);

-- Floor conversion to smallint, int, bigint
SELECT CONVERT(int, 99.9);
SELECT CONVERT(smallint, 99.9);
SELECT CONVERT(bigint, 99.9);
SELECT CONVERT(int, -99.9);
SELECT CONVERT(int, '99');
SELECT CONVERT(int, CAST(99.9 AS double precision));
SELECT CONVERT(int, CAST(99.9 AS real));

-- test TRY_CONVERT function
-- Conversion between different types and varchar
select TRY_CONVERT(varchar(30), CAST('2017-08-25' AS date), 102);
select TRY_CONVERT(varchar(30), CAST('13:01:59' AS time), 8);
select TRY_CONVERT(varchar(30), CAST('13:01:59' AS time), 22);
select TRY_CONVERT(varchar(30), CAST('2017-08-25 13:01:59' AS datetime), 109);
select TRY_CONVERT(varchar(30), 11234561231231.234::float, 0);
select TRY_CONVERT(varchar(30), 11234561231231.234::float, 1);
select TRY_CONVERT(varchar(10), CAST(4936.56 AS MONEY), 0);

-- Wrong conversions that return NULL
select TRY_CONVERT(date, 123);
select TRY_CONVERT(time, 123);
select TRY_CONVERT(datetime, 123);
select TRY_CONVERT(money, 'asdf');

-- test PARSE function
-- Conversion from string to date/time/datetime
select PARSE('2017-08-25' AS date);
select PARSE('2017-08-25' AS date USING 'Cs-CZ');
select PARSE('08/25/2017' AS date USING 'en-US');
select PARSE('25/08/2017' AS date USING 'de-DE');
select PARSE('13:01:59' AS time);
select PARSE('13:01:59' AS time USING 'en-US');
select PARSE('13:01:59' AS time USING 'zh-CN');
select PARSE('2017-08-25 13:01:59' AS datetime);
select PARSE('2017-08-25 13:01:59' AS datetime USING 'zh-CN');
select PARSE('12:01:59' AS time);
select PARSE('2017-08-25 01:01:59PM' AS datetime);

-- Test if unnecessary culture arg given
select PARSE('123' AS int USING 'de-DE');

-- test TRY_PARSE function
-- Expect null return on error
-- Conversion from string to date/time/datetime
select TRY_PARSE('2017-08-25' AS date);
select TRY_PARSE('2017-08-25' AS date USING 'Cs-CZ');
select TRY_PARSE('789' AS date USING 'en-US');
select TRY_PARSE('asdf' AS date USING 'de-DE');
select TRY_PARSE('13:01:59' AS time);
select TRY_PARSE('asdf' AS time USING 'en-US');
select TRY_PARSE('13-12-21' AS time USING 'zh-CN');
select TRY_PARSE('2017-08-25 13:01:59' AS datetime);
select TRY_PARSE('20asdf17' AS datetime USING 'de-DE');

-- Wrong conversions that return NULL
select TRY_PARSE('asdf' AS numeric(3,2));
select TRY_PARSE('123' AS datetime2);
select TRY_PARSE('asdf' AS MONEY);
select TRY_PARSE('asdf' AS int USING 'de-DE');

-- test serverproperty() function
-- invalid property name, should reutnr NULL
select serverproperty(n'invalid property');
-- valid supported properties
select serverproperty(n'collation');
select serverproperty(n'collationId');
select serverproperty(n'IsSingleUser');
select serverproperty(n'ServerName');

-- test ISDATE function
-- test valid argument
SELECT ISDATE('12/26/2016');
SELECT ISDATE('12-26-2016');
SELECT ISDATE('12.26.2016');
SELECT ISDATE('2016-12-26 23:30:05.523456');
-- test invalid argument
SELECT ISDATE('02/30/2016');
SELECT ISDATE('12/32/2016');
SELECT ISDATE('1995-10-1a');
SELECT ISDATE(NULL);

-- test DATEFROMPARTS function
-- test valid arguments
select datefromparts(2020,12,31);
-- test invalid arguments, should fail
select datefromparts(2020, 2, 30);
select datefromparts(2020, 13, 1);
select datefromparts(-4, 3, 150);
select datefromparts(10, 55, 10.1);
select datefromparts('2020', 55, 100.1);

-- test DATETIMEFROMPARTS function
-- test valid arguments
select datetimefromparts(2016, 12, 26, 23, 30, 5, 32);
select datetimefromparts(2016.0, 12, 26, 23, 30, 5, 32);
select datetimefromparts(2016.1, 12, 26, 23, 30, 5, 32);
select datetimefromparts(2016, 12, 26.99, 23, 30, 5, 32);
select datetimefromparts(2016, 12.90, 26, 23, 30, 5, 32);
-- test invalid arguments
select datetimefromparts(2016, 2, 30, 23, 30, 5, 32);
select datetimefromparts(2016, 12, 26, 23, 30, 5);
select datetimefromparts(2016, 12, 26, 23, 30, 5, NULL);

-- test DATEPART function
-- test all valid datepart arguments
select datepart(year, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(yyyy, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(yy, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(quarter, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(qq, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(q, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(month, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(mm, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(m, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(dayofyear, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(dy, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(day, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(dd, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(d, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(week, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(wk, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(ww, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(weekday, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(dw, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(hour, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(hh, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(minute, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(n, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(second, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(ss, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(s, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(millisecond, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(ms, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(microsecond, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(mcs, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(nanosecond, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(ns, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(tzoffset, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(tz, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(iso_week, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(isowk, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datepart(isoww, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
-- test different types of date/time arguments
select datepart(month, '2016-12-26 23:30:05.523'::sys.datetime);
select datepart(quarter, '2016-12-26 23:30:05.523456'::datetime2);
select datepart(hour, '2016-12-26 23:30:05'::smalldatetime);
select datepart(dayofyear, '2016-12-26'::date);
select datepart(second, '04:12:34.876543'::time);
-- test edge cases: try to get datepart that does not exist in the argument
select datepart(year, cast('12:10:30.123' as time));
select datepart(yyyy, cast('12:10:30.123' as time));
select datepart(yy, cast('12:10:30.123' as time));
select datepart(quarter, cast('12:10:30.123' as time));
select datepart(qq, cast('12:10:30.123' as time));
select datepart(q, cast('12:10:30.123' as time));
select datepart(month, cast('12:10:30.123' as time));
select datepart(mm, cast('12:10:30.123' as time));
select datepart(m, cast('12:10:30.123' as time));
select datepart(dayofyear, cast('12:10:30.123' as time));
select datepart(dy, cast('12:10:30.123' as time));
select datepart(y, cast('12:10:30.123' as time));
select datepart(day, cast('12:10:30.123' as time));
select datepart(dd, cast('12:10:30.123' as time));
select datepart(d, cast('12:10:30.123' as time));
select datepart(week, cast('12:10:30.123' as time));
select datepart(wk, cast('12:10:30.123' as time));
select datepart(ww, cast('12:10:30.123' as time));
select datepart(weekday, cast('12:10:30.123' as time));
select datepart(dw, cast('12:10:30.123' as time));
select datepart(tzoffset, cast('12:10:30.123' as time));
select datepart(tz, cast('12:10:30.123' as time));
select datepart(iso_week, cast('12:10:30.123' as time));
select datepart(isowk, cast('12:10:30.123' as time));
select datepart(isoww, cast('12:10:30.123' as time));
select datepart(hour, cast('2016-12-26' as date));
select datepart(hh, cast('2016-12-26' as date));
select datepart(minute, cast('2016-12-26' as date));
select datepart(n, cast('2016-12-26' as date));
select datepart(second, cast('2016-12-26' as date));
select datepart(ss, cast('2016-12-26' as date));
select datepart(s, cast('2016-12-26' as date));
select datepart(millisecond, cast('2016-12-26' as date));
select datepart(ms, cast('2016-12-26' as date));
select datepart(microsecond, cast('2016-12-26' as date));
select datepart(mcs, cast('2016-12-26' as date));
select datepart(nanosecond, cast('2016-12-26' as date));
select datepart(ns, cast('2016-12-26' as date));
-- test invalid interval, expect error
select datepart(invalid_interval, cast('2016-12-26 23:30:05.523456' as date));
select datepart(invalidinterval, cast('12:10:30.123' as time));

-- test DATENAME function
select datename(year, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datename(dd, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datename(weekday, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datename(dw, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datename(month, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datename(mm, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datename(m, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select datename(isowk, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
-- test invalid argument, expect error
select datename(invalid_interval, cast('2016-12-26 23:30:05.523456' as date));

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
set datefirst 1;
select datepart(week, '2007-04-21'::date), datepart(weekday, '2007-04-21'::date);
set datefirst 2;
select datepart(week, '2007-04-21'::date), datepart(weekday, '2007-04-21'::date);
set datefirst 3;
select datepart(week, '2007-04-21'::date), datepart(weekday, '2007-04-21'::date);
set datefirst 4;
select datepart(week, '2007-04-21'::date), datepart(weekday, '2007-04-21'::date);
set datefirst 5;
select datepart(week, '2007-04-21'::date), datepart(weekday, '2007-04-21'::date);
set datefirst 6;
select datepart(week, '2007-04-21'::date), datepart(weekday, '2007-04-21'::date);
set datefirst 7;
select datepart(week, '2007-04-21'::date), datepart(weekday, '2007-04-21'::date);
-- test edge case: date within the week of Jan. 1st
select datepart(week, '2007-01-01'::date), datepart(weekday, '2007-01-01'::date);
select datepart(week, '2007-01-02'::date), datepart(weekday, '2007-01-02'::date);
select datepart(week, '2007-01-03'::date), datepart(weekday, '2007-01-03'::date);
select datepart(week, '2007-01-04'::date), datepart(weekday, '2007-01-04'::date);
select datepart(week, '2007-01-05'::date), datepart(weekday, '2007-01-05'::date);
select datepart(week, '2007-01-06'::date), datepart(weekday, '2007-01-06'::date);
-- test edge case: date just outside the week of Jan. 1st
select datepart(week, '2007-01-07'::date), datepart(weekday, '2007-01-07'::date);

-- test DATEDIFF function
select datediff(year, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(quarter, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(month, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(dayofyear, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(day, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(week, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(hour, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(minute, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(second, '2037-03-01 23:30:05.523'::sys.datetime, '2036-02-28 23:30:05.523'::sys.datetime);
select datediff(millisecond, '2036-02-28 01:23:45.234'::sys.datetime, '2036-02-28 01:23:45.123'::sys.datetime);
select datediff(microsecond, '2036-02-28 01:23:45.234'::sys.datetime, '2036-02-28 01:23:45.123'::sys.datetime);
select datediff(nanosecond, '2036-02-28 01:23:45.234'::sys.datetime, '2036-02-28 01:23:45.123'::sys.datetime);
-- test different types of date/time arguments
select datediff(minute, '2016-12-26 23:30:05.523456+8'::datetimeoffset, '2016-12-31 23:30:05.523456+8'::datetimeoffset);
select datediff(quarter, '2016-12-26 23:30:05.523456'::datetime2, '2018-08-31 23:30:05.523456'::datetime2);
select datediff(hour, '2016-12-26 23:30:05'::smalldatetime, '2016-12-28 21:29:05'::smalldatetime);
select datediff(year, '2037-03-01'::date, '2036-02-28'::date);

-- test DATEADD function
select dateadd(year, 2, '20060830'::datetime);
select dateadd(quarter, 2, '20060830'::datetime);
select dateadd(month, 1, '20060831'::datetime);
select dateadd(dayofyear, 2, '20060830'::datetime);
select dateadd(day, 2, '20060830'::datetime);
select dateadd(week, 2, '20060830'::datetime);
select dateadd(weekday, 2, '20060830'::datetime);
select dateadd(hour, 2, '20060830'::datetime);
select dateadd(minute, 2, '20060830'::datetime);
select dateadd(second, 2, '20060830'::datetime);
select dateadd(millisecond, 123, '20060830'::datetime);
select dateadd(microsecond, 123456, '20060830'::datetime);
select dateadd(nanosecond, 123456, '20060830'::datetime);
-- test different types of date/time arguments
select dateadd(hour, 2, '23:12:34.876543'::time);
select dateadd(quarter, 3, '2037-03-01'::date);
select dateadd(minute, 70, '2016-12-26 23:30:05.523456+8'::datetimeoffset);
select dateadd(month, 2, '2016-12-26 23:30:05.523456'::datetime2);
select dateadd(second, 56, '2016-12-26 23:30:05'::smalldatetime);
-- test negative argument
select dateadd(year, -2, '20060830'::datetime);
select dateadd(month, -20, '2016-12-26 23:30:05.523456'::datetime2);
select dateadd(hour, -2, '01:12:34.876543'::time);
select dateadd(minute, -70, '2016-12-26 00:30:05.523456+8'::datetimeoffset);
select dateadd(second, -56, '2016-12-26 00:00:55'::smalldatetime);
-- test return type
select pg_typeof(dateadd(hour, -2, '01:12:34.876543'::time));
select pg_typeof(dateadd(second, -56, '2016-12-26 00:00:55'::smalldatetime));
select pg_typeof(dateadd(year, -2, '20060830'::datetime));
select pg_typeof(dateadd(month, -20, '2016-12-26 23:30:05.523456'::datetime2));
select pg_typeof(dateadd(minute, -70, '2016-12-26 00:30:05.523456+8'::datetimeoffset));
-- test illegal usage
select dateadd(minute, 2, '2037-03-01'::date);
select dateadd(day, 4, '04:12:34.876543'::time);
-- test using variables, instead of constants, for the second parameter
create table dateadd_table(a int, b datetime);
insert into dateadd_table values(1, '2020-10-29'::datetime);
select * from dateadd_table;
update dateadd_table set b = dateadd(dd, a, '2020-10-30'::datetime);
select * from dateadd_table;
create procedure dateadd_procedure as
begin
	declare @d int = 1
	update dateadd_table set b = dateadd(dd, @d, CAST('2020-10-31' AS datetime))
end;
call dateadd_procedure();
select * from dateadd_table;

-- test CHARINDEX function
select CHARINDEX('hello', 'hello world');
select CHARINDEX('hello  ', 'hello world');
select CHARINDEX('hello world', 'hello');
-- test NULL input
select CHARINDEX(NULL, NULL);
select CHARINDEX(NULL, 'string');
select CHARINDEX('pattern', NULL);
select CHARINDEX('pattern', 'string', NULL);
-- test start_location parameter
select CHARINDEX('hello', 'hello world', -1);
select CHARINDEX('hello', 'hello world', 0);
select CHARINDEX('hello', 'hello world', 1);
select CHARINDEX('hello', 'hello world', 2);
select CHARINDEX('world', 'hello world', 6);
select CHARINDEX('world', 'hello world', 7);
select CHARINDEX('world', 'hello world', 8);
select CHARINDEX('is', 'This is a string');
select CHARINDEX('is', 'This is a string', 4);

-- test STUFF function
select STUFF(n'abcdef', 2, 3, n'ijklmn');  
select STUFF(N' abcdef', 2, 3, N'ijklmn ');
select STUFF(N'abcdef', 2, 3, N' ijklmn ');
select STUFF(N'abcdef', 2, 3, N'ijklmn  ');
-- test corner cases
-- when start is negative or zero or longer than expr, return NULL
select STUFF(n'abcdef', -1, 3, n'ijklmn');  
select STUFF(n'abcdef', 0, 3, n'ijklmn');  
select STUFF(n'abcdef', 7, 3, n'ijklmn');  
-- when length is negative, return NULL
select STUFF(n'abcdef', 2, -3, n'ijklmn');  
-- when length is zero, just insert without deleting
select STUFF(n'abcdef', 2, 0, n'ijklmn');  
-- when length is longer than expr, delete up to the last character in expr
select STUFF(n'abcdef', 2, 7, n'ijklmn');
-- when replace_expr is NULL, just delete without inserting
select STUFF(n'abcdef', 2, 3, NULL);
-- when argument are type unknown
select STUFF('abcdef', 2, 3, 'ijklmn');
select STUFF('abcdef', 2, 3, n'ijklmn');
select STUFF(n'abcdef', 2, 3, 'ijklmn');
-- when argument are type text
SELECT STUFF(CAST('abcdef' as text), 2, 3, CAST('ijklmn' as text));
SELECT STUFF(CAST('abcdef' as text), 2, 3, 'ijklmn');
SELECT STUFF('abcdef', 2, 3, CAST('ijklmn' as text));
-- when argument are type sys.varchar
SELECT STUFF(CAST('abcdef' as sys.varchar), 2, 3, CAST('ijklmn' as sys.varchar));
SELECT STUFF('abcdef', 2, 3, CAST('ijklmn' as sys.varchar));
SELECT STUFF(CAST('abcdef' as sys.varchar), 2, 3, 'ijklmn');

-- test ROUND function
-- test rounding to the left of decimal point
select ROUND(748.58, -1);
select ROUND(748.58, -2);
select ROUND(748.58, -3);
select ROUND(748.58, -4);
select ROUND(-648.1234, -2);
select ROUND(-648.1234, -3);
select ROUND(-1548.1234, -3);
select ROUND(-1548.1234, -4);
-- test NULL input
select ROUND(NULL, -3);
select ROUND(748.58, NULL);
-- test rounding
SELECT ROUND(123.9994, 3);
SELECT ROUND(123.9995, 3);
SELECT ROUND(123.4545, 2);
SELECT ROUND(123.45, -2);
-- test function parameter, i.e. truncation when not NULL or 0
SELECT ROUND(150.75, 0);
SELECT ROUND(150.75, 0, 0);
SELECT ROUND(150.75, 0, NULL);
SELECT ROUND(150.75, 0, 1);
-- test negative numbers
SELECT ROUND(-150.49, 0);
SELECT ROUND(-150.75, 0);
SELECT ROUND(-150.49, 0, 1);
SELECT ROUND(-150.75, 0, 1);

-- test SELECT ROUND(col, )
create table t1 (col numeric(4,2));
insert into t1 values (64.24);
insert into t1 values (79.65);
insert into t1 values (NULL);
select ROUND(col, 3) from t1;
select ROUND(col, 2) from t1;
select ROUND(col, 1) from t1;
select ROUND(col, 0) from t1;
select ROUND(col, -1) from t1;
select ROUND(col, -2) from t1;
select ROUND(col, -3) from t1;
select ROUND(col, 1, 1) from t1;
drop table t1;

-- test DAY function
select DAY(CAST('2016-12-26 23:30:05.523456+8' AS datetimeoffset));
select DAY(CAST('2016-12-26 23:30:05.523456' AS datetime2));
select DAY(CAST('2016-12-26 23:30:05' AS smalldatetime));
select DAY(CAST('04:12:34.876543' AS time));
select DAY(CAST('2037-03-01' AS date));
select DAY(CAST('2037-03-01 23:30:05.523' AS sys.datetime));
-- test MONTH function
select MONTH('2016-12-26 23:30:05.523456+8'::datetimeoffset);
select MONTH('2016-12-26 23:30:05.523456'::datetime2);
select MONTH('2016-12-26 23:30:05'::smalldatetime);
select MONTH('04:12:34.876543'::time);
select MONTH('2037-03-01'::date);
select MONTH('2037-03-01 23:30:05.523'::sys.datetime);
-- test YEAR function
select YEAR('2016-12-26 23:30:05.523456+8'::datetimeoffset);
select YEAR('2016-12-26 23:30:05.523456'::datetime2);
select YEAR('2016-12-26 23:30:05'::smalldatetime);
select YEAR('04:12:34.876543'::time);
select YEAR('2037-03-01'::date);
select YEAR('2037-03-01 23:30:05.523'::sys.datetime);

-- test SPACE function
select SPACE(NULL);
select SPACE(2);
select LEN(SPACE(5));
select DATALENGTH(SPACE(5));

-- test COUNT and COUNT_BIG aggregate function
CREATE TABLE t2(a int, b int);
INSERT INTO t2 VALUES(1, 100);
INSERT INTO t2 VALUES(2, 200);
INSERT INTO t2 VALUES(NULL, 300);
INSERT INTO t2 VALUES(2, 400);
CREATE TABLE t3(a varchar(255), b varchar(255),c int);
INSERT INTO t3 VALUES('xyz', 'a',1);
INSERT INTO t3 VALUES('xyz', 'b',1);
INSERT INTO t3 VALUES('abc', 'a',2);
INSERT INTO t3 VALUES('abc', 'b',2);
INSERT INTO t3 VALUES('efg', 'a',3);
INSERT INTO t3 VALUES('efg', 'b',3);
INSERT INTO t3 VALUES(NULL, NULL, 1);

-- Aggregation Function Syntax
-- COUNT[_BIG] ( { [ [ ALL | DISTINCT ] expression ] | * } )
-- should return all rows - 4
SELECT COUNT(*) from t2;
SELECT pg_typeof(COUNT(*)) from t2;
SELECT COUNT_BIG(*) from t2;
SELECT pg_typeof(COUNT_BIG(*)) from t2;
-- should return all rows where a is not NULL - 3
SELECT COUNT(a) from t2;
SELECT pg_typeof(COUNT(a)) from t2;
SELECT COUNT_BIG(a) from t2;
SELECT pg_typeof(COUNT_BIG(a)) from t2;
-- should return all rows where a is not NULL - 3
SELECT COUNT(ALL a) from t2;
SELECT pg_typeof(COUNT(ALL a)) from t2;
SELECT COUNT_BIG(ALL a) from t2;
SELECT pg_typeof(COUNT_BIG(ALL a)) from t2;
-- should return all rows where a is distinct - 2
SELECT COUNT(DISTINCT a) from t2;
SELECT pg_typeof(COUNT(DISTINCT a)) from t2;
SELECT COUNT_BIG(DISTINCT a) from t2;
SELECT pg_typeof(COUNT_BIG(DISTINCT a)) from t2;

-- Analytic Function Syntax
-- COUNT[_BIG] ( [ ALL ]  { expression | * } ) OVER ( [ <partition_by_clause> ] )
SELECT pg_typeof(COUNT(*) OVER (PARTITION BY a)) from t2;
SELECT pg_typeof(COUNT_BIG(*) OVER (PARTITION BY a)) from t2;
SELECT pg_typeof(COUNT(a) OVER (PARTITION BY a)) from t2;
SELECT pg_typeof(COUNT_BIG(a) OVER (PARTITION BY a)) from t2;
SELECT pg_typeof(COUNT(ALL a) OVER (PARTITION BY a)) from t2;
SELECT pg_typeof(COUNT_BIG(ALL a) OVER (PARTITION BY a)) from t2;
SELECT COUNT(*) from t3;
SELECT a, b, COUNT(*) OVER () from t3;
-- The result for order by is different in sql server because we have
-- an ordering issue for null type (JIRA: BABEL-788)
SELECT a, b, COUNT(*) OVER (ORDER BY a) from t3;
SELECT a, b, COUNT(*) OVER (ORDER BY a DESC) from t3;
SELECT a, b, COUNT(*) OVER(PARTITION BY a) from t3;
SELECT a, b, COUNT(*) OVER(PARTITION BY a ORDER BY b) from t3;
SELECT a, b, COUNT(*) OVER(PARTITION BY a ORDER BY b ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)  from t3;
SELECT COUNT_BIG(*) from t3;
SELECT a, b, COUNT_BIG(*) OVER () from t3;
SELECT a, b, COUNT_BIG(*) OVER (ORDER BY a) from t3;
SELECT a, b, COUNT_BIG(*) OVER (ORDER BY a DESC) from t3;
SELECT a, b, COUNT_BIG(*) OVER(PARTITION BY a) from t3;
SELECT a, b, COUNT_BIG(*) OVER(PARTITION BY a ORDER BY b) from t3;
SELECT a, b, COUNT_BIG(*) OVER(PARTITION BY a ORDER BY b ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)  from t3;

-- COUNT(*) takes no parameters and does not support the use of DISTINC, expect error
SELECT COUNT(DISTINCT *) from t3;
SELECT COUNT(ALL *) from t3;
DROP TABLE t2;
DROP TABLE t3;

-- clean up
drop function test_increment;
drop function test_increment1;
drop table dateadd_table;
drop procedure dateadd_procedure;

-- test inline table-valued functions
-- simple case
create function itvf1 (@number int) returns table as return (select 1 as a, 2 as b);
select * from itvf1(5);
-- should fail because column names are not specified
create function itvf2 (@number int) returns table as return (select 1, 2);

-- select from a table
create table example_table(name text, age int);
insert into example_table values('hello', 3);
-- should have 'a' and 'b' as result column names
create function itvf3 (@number int) returns table as return (select name as a, age as b from example_table);
select * from itvf3(5);
-- test returning multiple rows
insert into example_table values('hello1', 4);
insert into example_table values('hello2', 5);
insert into example_table values('hello3', 6);
select * from itvf3(5);

-- invoke a function
create function itvf4 (@number int) returns table as
return (select sys.serverproperty(N'collation') as property1, sys.serverproperty(N'IsSingleUser') as property2);
select * from itvf4(5);

-- case where the return table has only one column - Postgres considers these as
-- scalar functions
create or replace function itvf5 (@number int) returns table as return (select 1 as a);
select * from itvf5(5);
create or replace function itvf6 (@number int) returns table as
return (select sys.serverproperty(N'collation') as property);
select * from itvf6(5);

-- complex queries with use of function parameter
create table id_name(id int, name text);
insert into id_name values(1001, 'adam');
insert into id_name values(1002, 'bob');
insert into id_name values(1003, 'chaz');
insert into id_name values(1004, 'dave');
insert into id_name values(1005, 'ed');

create table id_score(id int, score int);
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

create function itvf7 (@number int) returns table as return (
select n.id, n.name as first_name, sum(s.score) as total_score
from id_name as n
join id_score as s
on n.id = s.id
where s.id <= @number
group by n.id, n.name
order by n.id
);

select * from itvf7(1004);

-- test inline table-valued function with table-valued parameter
create type tableType as table(
	a text not null,
	b int primary key,
	c int);

create function itvf8 (@number int, @tableVar tableType READONLY) returns table as return (
select n.id, n.name as first_name, sum(s.score) as total_score
from id_name as n
join id_score as s
on n.id = s.id
where s.id <= @number and s.id in (select c from @tableVar)
group by n.id, n.name
order by n.id
);

create procedure itvf8_proc as
begin
	declare @tableVariable tableType
	insert into @tableVariable values('hello1', 1, 1001)
	insert into @tableVariable values('hello2', 2, 1002)
	select * from itvf8(1004, @tableVariable)
end;

call itvf8_proc();

-- test using parameter in projection list
create function itvf9(@number int) returns table as return (
select @number as a from id_name
);

select * from itvf9(1);

-- test invalid ITVFs
-- function does not have RETURN QUERY
create function itvf10(@number int) returns table as BEGIN select * from id_name END;
-- function has more than one RETURN QUERY
create function itvf11(@number int) returns table as
BEGIN
	return select * from id_name
	return select id from id_name
END;

-- test creating ITVF in a transaction and rollback - should still work as
-- normal despite the function validator's modification of the pg_proc entry
begin transaction;
create function itvf12(@number int) returns table as return (
select @number as a from id_name
);
rollback;
select * from itvf12(1);

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
drop table example_table;
drop function itvf3;
drop function itvf4;
drop function itvf5;
drop function itvf6;
drop table id_name;
drop table id_score;
drop function itvf7;
drop procedure itvf8_proc;
drop function itvf8;
drop type tableType;
drop function itvf9;
drop table babel651_t;
drop function babel651_f;
drop function babel651_itvf;
drop function babel651_mstvf;

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
\tsql off
