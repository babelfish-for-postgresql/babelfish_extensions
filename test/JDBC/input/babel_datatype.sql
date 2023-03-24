-- The default scale is 2 in PG.
select CAST('$100,123.4567' AS money);
GO
-- Currency symbol followed by number without being quoted is not recognized
-- as Money in postgres dialect.
select CAST($100123.4567 AS money);
GO

-- Scale changes to the sql server default 4 in tsql dialect
-- Currency symbol followed by number without being quoted is recognized
-- as Money type in tsql dialect.
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
select CAST($100123.4567 AS money);
GO
select CAST($100123. AS money);
GO
select CAST($.4567 AS money);
GO
select CAST('$100,123.4567' AS money);
GO

-- Test numeric types with brackets
create table testing_1 (a [tinyint]);
GO
drop table testing_1;
GO
create table testing_1 (a [smallint]);
GO
drop table testing_1;
GO
create table testing_1 (a [int]);
GO
drop table testing_1;
GO
create table testing_1 (a [bigint]);
GO
drop table testing_1;
GO
create table testing_1 (a [real]);
GO
drop table testing_1;
GO
create table testing_1 (a [float]);
GO
drop table testing_1;
GO

-- Comma separated format without quote is not allowed in sql server
select CAST($100,123.4567 AS money);
GO

-- Smallmoney in tsql dialect
select CAST($100123.4567 AS smallmoney);
GO
select CAST('$100,123.4567' AS smallmoney);
GO
-- Comma separated format without quote is not allowed in sql server
select CAST($100,123.4567 AS smallmoney);
GO

create table testing_1(mon money, smon smallmoney);
GO
insert into testing_1 (mon, smon) values ('$100,123.4567', '$123.9999');
insert into testing_1 (mon, smon) values ($100123.4567, $123.9999);
GO
select * from testing_1;
GO
select avg(CAST(mon AS numeric(38,4))), avg(CAST(smon AS numeric(38,4))) from testing_1;
GO
select mon+smon as total from testing_1;
GO
-- Comma separated format without quote is not allowed in sql server
insert into testing_1 (mon, smon) values ($100,123.4567, $123.9999);
GO

-- Test other allowed currency symbols with/without quote
select CAST(€100.123 AS money);
GO
select CAST('€100.123' AS money);
GO
select CAST(¢100.123 AS money);
GO
select CAST(£100.123 AS money);
GO
select CAST('£100.123' AS money);
GO
select CAST(¤100.123 AS money);
GO
select CAST(¥100.123 AS money);
GO
select CAST(৲100.123 AS money);
GO
select CAST(৳100.123 AS money);
GO
select CAST(฿100.123 AS money);
GO
select CAST(៛100.123 AS money);
GO
select CAST(₠100.123 AS money);
GO
select CAST(₡100.123 AS money);
GO
select CAST(₢100.123 AS money);
GO
select CAST(₣100.123 AS money);
GO
select CAST(₤100.123 AS money);
GO
select CAST(₥100.123 AS money);
GO
select CAST(₦100.123 AS money);
GO
select CAST(₧100.123 AS money);
GO
select CAST(₨100.123 AS money);
GO
select CAST(₩100.123 AS money);
GO
select CAST(₪100.123 AS money);
GO
select CAST(₫100.123 AS money);
GO
select CAST(₭100.123 AS money);
GO
select CAST(₮100.123 AS money);
GO
select CAST(₯100.123 AS money);
GO
select CAST(₰100.123 AS money);
GO
select CAST(₱100.123 AS money);
GO
select CAST(﷼100.123 AS money);
GO
select CAST(﹩100.123 AS money);
GO
select CAST(＄100.123 AS money);
GO
select CAST(￠100.123 AS money);
GO
select CAST(￡100.123 AS money);
GO
select CAST(￥100.123 AS money);
GO
select CAST('￥100.123' AS money);
GO
select CAST(￦100.123 AS money);
GO

-- Test unsupoorted currency symbol
select CAST(￩100.123 AS money);
GO
select CAST('￩100.123' AS money);
GO

-- Test that space is allowed between currency symbol and number, this is
-- a TSQL behavior
select CAST($   123.5 AS money);
GO
select CAST('$    123.5' AS money);
GO

-- Test inexact result mutliply/divide money with money, to match
-- SQL Server behavior
select CAST(100 AS money)/CAST(339 AS money)*CAST(10000 AS money);
GO

-- Test postgres dialect
-- Test currency symbol without quote is not allowed in postgres dialect
reset babelfishpg_tsql.sql_dialect;
select CAST(€100.123 AS money);
GO

-- Test exact result multiply/divide money with money in postgres dialect
select CAST(100 AS money)/CAST(339 AS money)*CAST(10000 AS money);
GO

-- Clean up
drop table testing_1;
GO

-- BABEL-109 test no more not unique operator error caused by fixeddeciaml
select CAST(2 AS numeric) > 1;
GO
select CAST(2 AS decimal) > 1;
GO

-- Test that numeric > int and fixeddecimal > int is different
select CAST(2.00001 AS numeric) > 2;
GO
select CAST(2.00001 AS sys.fixeddecimal) > 2;
GO

-- test TSQL Money (based on fixeddecimal) cross datatype operators
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
select CAST(2 AS money) > 1;
GO
select CAST(2 AS money) > CAST(1 AS int);
GO
select CAST(2 AS money) > CAST(1 AS int2);
GO
select CAST(2 AS money) > CAST(1 AS int4);
GO
select CAST(2 AS money) > CAST(1 AS numeric);
GO
select CAST(2 AS money) > CAST(1 AS decimal);
GO

select CAST(2 AS money) >= 1;
GO
select CAST(2 AS money) >= CAST(1 AS int);
GO
select CAST(2 AS money) >= CAST(1 AS int2);
GO
select CAST(2 AS money) >= CAST(1 AS int4);
GO
select CAST(2 AS money) >= CAST(1 AS numeric);
GO
select CAST(2 AS money) >= CAST(1 AS decimal);
GO

select CAST(2 AS money) < 1;
GO
select CAST(2 AS money) < CAST(1 AS int);
GO
select CAST(2 AS money) < CAST(1 AS int2);
GO
select CAST(2 AS money) < CAST(1 AS int4);
GO
select CAST(2 AS money) < CAST(1 AS numeric);
GO
select CAST(2 AS money) < CAST(1 AS decimal);
GO

select CAST(2 AS money) <= 1;
GO
select CAST(2 AS money) <= CAST(1 AS int);
GO
select CAST(2 AS money) <= CAST(1 AS int2);
GO
select CAST(2 AS money) <= CAST(1 AS int4);
GO
select CAST(2 AS money) <= CAST(1 AS numeric);
GO
select CAST(2 AS money) <= CAST(1 AS decimal);
GO

select CAST(2 AS money) <> 1;
GO
select CAST(2 AS money) <> CAST(1 AS int);
GO
select CAST(2 AS money) <> CAST(1 AS int2);
GO
select CAST(2 AS money) <> CAST(1 AS int4);
GO
select CAST(2 AS money) <> CAST(1 AS numeric);
GO
select CAST(2 AS money) <> CAST(1 AS decimal);

select CAST(2 AS money) + 1;
GO
select CAST(2 AS money) + CAST(1 AS int);
GO
select CAST(2 AS money) + CAST(1 AS int2);
GO
select CAST(2 AS money) + CAST(1 AS int4);
GO
select CAST(2 AS money) + CAST(1 AS numeric);
GO
select CAST(2 AS money) + CAST(1 AS decimal);
GO

select CAST(2 AS money) - 1;
GO
select CAST(2 AS money) - CAST(1 AS int);
GO
select CAST(2 AS money) - CAST(1 AS int2);
GO
select CAST(2 AS money) - CAST(1 AS int4);
GO
select CAST(2 AS money) - CAST(1 AS numeric);
GO
select CAST(2 AS money) - CAST(1 AS decimal);
GO

select CAST(2 AS money) * 2;
GO
select CAST(2 AS money) * CAST(2 AS int);
GO
select CAST(2 AS money) * CAST(2 AS int2);
GO
select CAST(2 AS money) * CAST(2 AS int4);
GO
select CAST(2 AS money) * CAST(2 AS numeric);
GO
select CAST(2 AS money) * CAST(2 AS decimal);
GO

select CAST(2 AS money) / 0.5;
GO
select CAST(2 AS money) / CAST(2 AS int);
GO
select CAST(2 AS money) / CAST(2 AS int2);
GO
select CAST(2 AS money) / CAST(2 AS int4);
GO
select CAST(2 AS money) / CAST(0.5 AS numeric(4,2));
GO
select CAST(2 AS money) / CAST(0.5 AS decimal(4,2));
GO

reset babelfishpg_tsql.sql_dialect;
GO

-- Test DATE, DATETIME, DATETIMEOFFSET, DATETIME2
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- DATE DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME are defined in tsql dialect
select CAST('2020-03-15' AS date);
GO
select CAST('2020-03-15 09:00:00+8' AS datetimeoffset);
GO
select CAST('2020-03-15 09:00:00' AS datetime2);
GO
select CAST('2020-03-15 09:00:00' AS smalldatetime);
GO
-- test the range of date
select CAST('0001-01-01' AS date);
GO
select CAST('9999-12-31' AS date);
GO
-- test the range of datetime2
select CAST('0001-01-01 12:00:00.12345' AS datetime2);
GO
select CAST('9999-12-31 12:00:00.12345' AS datetime2);
GO
-- precision
select CAST('2020-03-15 09:00:00+8' AS datetimeoffset(7)) ;
GO
create table testing_1(ts DATETIME, tstz DATETIMEOFFSET(7));
GO

insert into testing_1 (ts, tstz) values ('2020-03-15 09:00:00', '2020-03-15 09:00:00+8');
select * from testing_1;
drop table testing_1;
GO

select CAST('2020-03-15 09:00:00' AS datetime2(7));
GO
select CAST('2020-03-15 09:00:00.123456' AS datetime2(3));
GO
select CAST('2020-03-15 09:00:00.123456' AS datetime2(0));
GO
select CAST('2020-03-15 09:00:00.123456' AS datetime2(-1));
GO
create table testing_1(ts DATETIME, tstz DATETIME2(7));
insert into testing_1 (ts, tstz) values ('2020-03-15 09:00:00', '2020-03-15 09:00:00');
select * from testing_1;
GO
drop table testing_1;
GO

-- DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME are not defined in
-- postgres dialect
SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
GO
select CAST('2020-03-15 09:00:00+8' AS datetimeoffset);
GO
create table testing_1(ts DATETIME);
GO
create table testing_1(tstz DATETIMEOFFSET);
GO
select CAST('2020-03-15 09:00:00' AS datetime2);
GO
create table testing_1(ts SMALLDATETIME);
GO
create table testing_1(tstz DATETIME2);
GO

-- Test DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME can be used as identifier
create table testing_1(DATETIME int);
GO
insert into testing_1 (DATETIME) values (1);
GO
select * from testing_1;
GO
drop table testing_1;
GO

create table testing_1(DATETIMEOFFSET int);
GO
insert into testing_1 (DATETIMEOFFSET) values (1);
GO
select * from testing_1;
GO
drop table testing_1;
GO

create table testing_1(DATETIME2 int);
GO
insert into testing_1 (DATETIME2) values (1);
GO
select * from testing_1;
GO
drop table testing_1;
GO

create table testing_1(SMALLDATETIME int);
GO
insert into testing_1 (SMALLDATETIME) values (1);
GO
select * from testing_1;
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
insert into testing_1 (SMALLDATETIME) values (2);
GO
select * from testing_1;
GO

-- Test conversion between DATE and other date/time types
select CAST(CAST('2020-03-15' AS date) AS datetime);
GO
select CAST(CAST('2020-03-15' AS date) AS smalldatetime);
GO
select CAST(CAST('2020-03-15' AS date) AS datetimeoffset(3));
GO
select CAST(CAST('2020-03-15' AS date) AS datetime2(3));
GO

-- Clean up
reset babelfishpg_tsql.sql_dialect;
GO
drop table testing_1;
GO

-- Test SYS.NCHAR, SYS.NVARCHAR and SYS.VARCHAR
-- nchar is already available in postgres dialect
select CAST('£' AS nchar(1));
GO
-- nvarchar is not available in postgres dialect
select CAST('£' AS nvarchar);
GO

-- both are available in tsql dialect
set babelfishpg_tsql.sql_dialect = 'tsql';
GO
select CAST('£' AS nchar(2));
GO
select CAST('£' AS nvarchar(2));
GO

-- multi-byte character doesn't fit in nchar(1) in tsql if it
-- would require a UTF16-surrogate-pair on output
select CAST('£' AS char(1));			-- allowed
GO
select CAST('£' AS sys.nchar(1));		-- allowed
GO
select CAST('£' AS sys.nvarchar(1));	-- allowed
GO
select CAST('£' AS sys.varchar(1));		-- allowed
GO

-- Check that things work the same in postgres dialect
reset babelfishpg_tsql.sql_dialect;
GO
select CAST('£' AS char(1));
GO
select CAST('£' AS sys.nchar(1));
GO
select CAST('£' AS sys.nvarchar(1));
GO
select CAST('£' AS sys.varchar(1));
GO
set babelfishpg_tsql.sql_dialect = 'tsql';
GO

-- truncate input on explicit cast
select CAST('ab' AS char(1));
GO
select CAST('ab' AS nchar(1));
GO
select CAST('ab' AS nvarchar(1));
GO
select CAST('ab' AS sys.varchar(1));
GO


-- default length of nchar/char is 1 in tsql (and pg)
create table testing_1(col nchar);
GO
reset babelfishpg_tsql.sql_dialect;
GO
SELECT * FROM testing_1;
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- check length at insert
insert into testing_1 (col) select 'a';
insert into testing_1 (col) select '£';
insert into testing_1 (col) select 'ab';
GO

-- space is automatically truncated
insert into testing_1 (col) select 'c ';
select * from testing_1;
GO

-- default length of nvarchar in tsql is 1
create table testing_2(col nvarchar);
GO

insert into testing_2 (col) select 'a';
insert into testing_2 (col) select '£';
insert into testing_2 (col) select 'ab';
GO

-- space is automatically truncated
insert into testing_2 (col) select 'c ';
select * from testing_2;
GO

-- default length of varchar in tsql is 1
create table testing_4(col sys.varchar);
GO

insert into testing_4 (col) select 'a';
insert into testing_4 (col) select '£';
insert into testing_4 (col) select 'ab';
GO
-- space is automatically truncated
insert into testing_4 (col) select 'c ';
insert into testing_2 (col) select '£ ';
select * from testing_4;
GO

-- test sys.varchar(max) and sys.nvarchar(max) syntax is allowed in tsql dialect
select CAST('abcdefghijklmn' AS sys.varchar(max));
GO
select CAST('abcdefghijklmn' AS varchar(max));
GO
select CAST('abcdefghijklmn' AS sys.nvarchar(max));
GO
select CAST('abcdefghijklmn' AS nvarchar(max));
GO

-- test char(max), nchar(max) is invalid syntax in tsql dialect
select cast('abc' as char(max));
GO
select cast('abc' as nchar(max));
GO

-- test max can still be used as an identifier
create table max (max int);
insert into max (max) select 100;
select * from max;
GO
drop table max;
GO

-- test sys.varchar(max) and nvarchar(max) syntax is not allowed in postgres dialect
reset babelfishpg_tsql.sql_dialect;
GO
select CAST('abcdefghijklmn' AS sys.varchar(max));
GO
select CAST('abcdefghijklmn' AS varchar(max));
GO
select CAST('abcdefghijklmn' AS sys.nvarchar(max));
GO
select CAST('abcdefghijklmn' AS nvarchar(max));
GO

-- test max max character length is (10 * 1024 * 1024) = 10485760
select CAST('abc' AS varchar(10485761));
GO
select CAST('abc' AS varchar(10485760));
GO

-- test column type nvarchar(max)
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
create table testing_5(col nvarchar(max));
GO
SELECT * FROM testing_5
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
insert into testing_5 (col) select 'ab';
insert into testing_5 (col) select 'abcdefghijklmn';
select * from testing_5;
GO

--test COPY command works with sys.nvarchar
COPY public.testing_5 (col) FROM stdin;
c
ab
abcdefghijk
\.
select * from testing_5;
GO

-- [BABEL-220] test varchar(max) as a column
drop table testing_5;
GO

create table testing_5(col varchar(max));
GO
reset babelfishpg_tsql.sql_dialect;
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
insert into testing_5 (col) select 'ab';
insert into testing_5 (col) select 'abcdefghijklmn';
select * from testing_5;
GO

-- test type modifer persist if babelfishpg_tsql.sql_dialect changes
create table testing_3(col nvarchar(2));
GO

insert into testing_3 (col) select 'ab';
insert into testing_3 (col) select 'a£';
insert into testing_3 (col) select 'a😀';
insert into testing_3 (col) select 'abc';
GO

reset babelfishpg_tsql.sql_dialect;
GO
insert into testing_3 (col) select 'ab';
insert into testing_3 (col) select 'a£';
insert into testing_3 (col) select 'a😀';
insert into testing_3 (col) select 'abc';
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
insert into testing_3 (col) select 'ab';
insert into testing_3 (col) select 'a£';
insert into testing_3 (col) select 'a😀';
insert into testing_3 (col) select 'abc';
GO

-- test normal create domain works when apg_enable_domain_typmod is enabled
select set_config('enable_seqscan','on','true');
GO
create domain varchar3 as varchar(3);
GO
select CAST('abc' AS varchar3);
GO
select CAST('ab£' AS varchar3);
GO
select CAST('abcd' AS varchar3);
GO
reset apg_enable_domain_typmod;
GO

-- [BABEL-191] test typmod of sys.varchar/nvarchar engages when the input
-- is casted multiple times
select CAST(CAST('abc' AS text) AS sys.varchar(3));
GO

select CAST(CAST('abc' AS pg_catalog.varchar(3)) AS sys.varchar(3));
GO

select CAST(CAST('abc' AS text) AS sys.nvarchar(3));
GO
select CAST(CAST('abc' AS text) AS sys.nchar(3));
GO

select CAST(CAST(CAST(CAST('abc' AS text) AS sys.varchar(3)) AS sys.nvarchar(3)) AS sys.nchar(3));
GO

-- test truncation on explicit cast through multiple levels
select CAST(CAST(CAST(CAST('abcde' AS text) AS sys.varchar(5)) AS sys.nvarchar(4)) AS sys.nchar(3));
GO
select CAST(CAST(CAST(CAST('abcde' AS text) AS sys.varchar(3)) AS sys.nvarchar(4)) AS sys.nchar(5));
GO

-- test sys.ntext is available
select CAST('abc£' AS sys.ntext);
GO
-- pg_catalog.text
select CAST('abc£' AS text);
GO

-- [BABEL-218] test varchar defaults to sys.varchar in tsql dialect
-- test default length of sys.varchar is 30 in CAST/CONVERT
-- expect the last 'e' to be truncated
select cast('abcdefghijklmnopqrstuvwxyzabcde' as varchar);
GO
select cast('abcdefghijklmnopqrstuvwxyzabcde' as sys.varchar);
GO
select convert(varchar, 'abcdefghijklmnopqrstuvwxyzabcde');
GO
select convert(sys.varchar, 'abcdefghijklmnopqrstuvwxyzabcde');
GO

-- default length of pg_catalog.varchar is unlimited, no truncation in output
select cast('abcdefghijklmnopqrstuvwxyzabcde' as pg_catalog.varchar);
GO

-- varchar defaults to pg_catalog.varchar in PG dialect
reset babelfishpg_tsql.sql_dialect;
GO
select cast('abcdefghijklmnopqrstuvwxyzabcde' as pg_catalog.varchar); -- default length of pg_catalog.varchar is unlimited, no truncation
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- [BABEL-255] test nchar defaults to sys.nchar in tsql dialect
create table test_nchar (col1 nchar);
GO

reset babelfishpg_tsql.sql_dialect;
GO
SELECT * FROM test_nchar
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
drop table test_nchar;
GO

-- test nchar defaults to bpchar in pg dialect
reset babelfishpg_tsql.sql_dialect;
GO
create table test_nchar (col1 nchar);
GO
SELECT * FROM test_nchar
drop table test_nchar;
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- [BABEL-257] test varchar defaults to sys.varchar in new
-- database and new schema
SELECT current_database();
GO

SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
GO

-- CREATE DATABASE demo;
-- USE demo
-- GO
CREATE EXTENSION IF NOT EXISTS "babelfishpg_tsql" CASCADE;
GO
-- Reconnect to make sure CLUSTER_COLLATION_OID is initialized
USE postgres
GO
USE demo
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
-- Test varchar is mapped to sys.varchar
-- Expect truncated output because sys.varchar defaults to sys.varchar(30) in CAST function
select cast('abcdefghijklmnopqrstuvwxyzabcde' as varchar);
GO
-- Expect non-truncated output because pg_catalog.varchar has unlimited length
select cast('abcdefghijklmnopqrstuvwxyzabcde' as pg_catalog.varchar);
GO

-- Test bit is mapped to sys.bit
-- sys.bit allows numeric input
select CAST(1.5 AS bit);
GO
-- pg_catalog.bit doesn't allow numeric input
select CAST(1.5 AS pg_catalog.bit);
GO

-- Test varchar is mapped to sys.varchar in a new schema and a new table
CREATE SCHEMA s1;
GO

create table s1.test1 (col varchar);
GO
-- Test sys.varchar is created for test1.col, expect an error
-- because sys.varchar defaults to sys.varchar(1)
insert into s1.test1 values('abc');
insert into s1.test1 values('a');
select * from s1.test1;
GO
drop schema s1 cascade;
GO
SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
GO

USE regression
GO

drop database demo;
GO