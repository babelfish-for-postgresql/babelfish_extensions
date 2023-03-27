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
create table testing1 (a [tinyint]);
GO
drop table testing1;
GO
create table testing1 (a [smallint]);
GO
drop table testing1;
GO
create table testing1 (a [int]);
GO
drop table testing1;
GO
create table testing1 (a [bigint]);
GO
drop table testing1;
GO
create table testing1 (a [real]);
GO
drop table testing1;
GO
create table testing1 (a [float]);
GO
drop table testing1;
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

create table testing1(mon money, smon smallmoney);
GO
insert into testing1 (mon, smon) values ('$100,123.4567', '$123.9999');
insert into testing1 (mon, smon) values ($100123.4567, $123.9999);
GO
select * from testing1;
GO
select avg(CAST(mon AS numeric(38,4))), avg(CAST(smon AS numeric(38,4))) from testing1;
GO
select mon+smon as total from testing1;
GO
-- Comma separated format without quote is not allowed in sql server
insert into testing1 (mon, smon) values ($100,123.4567, $123.9999);
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
drop table testing1;
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
create table testing1(ts DATETIME, tstz DATETIMEOFFSET(7));
GO

insert into testing1 (ts, tstz) values ('2020-03-15 09:00:00', '2020-03-15 09:00:00+8');
select * from testing1;
drop table testing1;
GO

select CAST('2020-03-15 09:00:00' AS datetime2(7));
GO
select CAST('2020-03-15 09:00:00.123456' AS datetime2(3));
GO
select CAST('2020-03-15 09:00:00.123456' AS datetime2(0));
GO
select CAST('2020-03-15 09:00:00.123456' AS datetime2(-1));
GO
create table testing1(ts DATETIME, tstz DATETIME2(7));
insert into testing1 (ts, tstz) values ('2020-03-15 09:00:00', '2020-03-15 09:00:00');
select * from testing1;
GO
drop table testing1;
GO

-- DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME are not defined in
-- postgres dialect
SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
GO
select CAST('2020-03-15 09:00:00+8' AS datetimeoffset);
GO
create table testing1(ts DATETIME);
GO
create table testing1(tstz DATETIMEOFFSET);
GO
select CAST('2020-03-15 09:00:00' AS datetime2);
GO
create table testing1(ts SMALLDATETIME);
GO
create table testing1(tstz DATETIME2);
GO

-- Test DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME can be used as identifier
create table testing1(DATETIME int);
GO
insert into testing1 (DATETIME) values (1);
GO
select * from testing1;
GO
drop table testing1;
GO

create table testing1(DATETIMEOFFSET int);
GO
insert into testing1 (DATETIMEOFFSET) values (1);
GO
select * from testing1;
GO
drop table testing1;
GO

create table testing1(DATETIME2 int);
GO
insert into testing1 (DATETIME2) values (1);
GO
select * from testing1;
GO
drop table testing1;
GO

create table testing1(SMALLDATETIME int);
GO
insert into testing1 (SMALLDATETIME) values (1);
GO
select * from testing1;
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
insert into testing1 (SMALLDATETIME) values (2);
GO
select * from testing1;
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
drop table testing1;
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
create table testing1(col nchar);
GO
reset babelfishpg_tsql.sql_dialect;
GO
SELECT * FROM testing1;
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- check length at insert
insert into testing1 (col) select 'a';
insert into testing1 (col) select '£';
insert into testing1 (col) select 'ab';
GO

-- space is automatically truncated
insert into testing1 (col) select 'c ';
select * from testing1;
GO

-- default length of nvarchar in tsql is 1
create table testing2(col nvarchar);
GO

insert into testing2 (col) select 'a';
insert into testing2 (col) select '£';
insert into testing2 (col) select 'ab';
GO

-- space is automatically truncated
insert into testing2 (col) select 'c ';
select * from testing2;
GO

-- default length of varchar in tsql is 1
create table testing4(col sys.varchar);
GO

insert into testing4 (col) select 'a';
insert into testing4 (col) select '£';
insert into testing4 (col) select 'ab';
GO
-- space is automatically truncated
insert into testing4 (col) select 'c ';
insert into testing2 (col) select '£ ';
select * from testing4;
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
create table testing5(col nvarchar(max));
GO
SELECT * FROM testing5
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
insert into testing5 (col) select 'ab';
insert into testing5 (col) select 'abcdefghijklmn';
select * from testing5;
GO

--test COPY command works with sys.nvarchar
COPY public.testing5 (col) FROM stdin;
c
ab
abcdefghijk
\.
select * from testing5;
GO

-- [BABEL-220] test varchar(max) as a column
drop table testing5;
GO

create table testing5(col varchar(max));
GO
reset babelfishpg_tsql.sql_dialect;
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
insert into testing5 (col) select 'ab';
insert into testing5 (col) select 'abcdefghijklmn';
select * from testing5;
GO

-- test type modifer persist if babelfishpg_tsql.sql_dialect changes
create table testing3(col nvarchar(2));
GO

insert into testing3 (col) select 'ab';
insert into testing3 (col) select 'a£';
insert into testing3 (col) select 'a😀';
insert into testing3 (col) select 'abc';
GO

reset babelfishpg_tsql.sql_dialect;
GO
insert into testing3 (col) select 'ab';
insert into testing3 (col) select 'a£';
insert into testing3 (col) select 'a😀';
insert into testing3 (col) select 'abc';
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
insert into testing3 (col) select 'ab';
insert into testing3 (col) select 'a£';
insert into testing3 (col) select 'a😀';
insert into testing3 (col) select 'abc';
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

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- test tinyint data type
select CAST(100 AS tinyint);
GO
select CAST(10 AS tinyint) / CAST(3 AS tinyint);
GO
select CAST(256 AS tinyint);
GO
select CAST((-1) AS tinyint);
GO

-- test bit data type, bit defaults to sys.bit in tsql dialect
-- test 'true'/'false' input is allowed. 't'/'f' is not allowed.
select CAST('true' AS bit);
GO
select CAST('True' AS bit);
GO
select CAST('TRUE' AS bit);
GO
select CAST('t' AS bit);
GO
select CAST('T' AS bit);
GO
select CAST('false' AS bit);
GO
select CAST('False' AS bit);
GO
select CAST('FALSE' AS bit);
GO
select CAST('f' AS bit);
GO
select CAST('F' AS bit);
GO

-- test '1'/'0'
select CAST('1' AS bit);
GO
select CAST('0' AS bit);
GO
select CAST('000' AS bit);
GO
select CAST('010' AS bit);
GO

-- test 'abc' is not allowed
select CAST('abc' AS bit);
GO

-- test NULL is allowed
select CAST(NULL AS bit);
GO

-- bit defaults to pg_catalog.bit in pg dialect
reset babelfishpg_tsql.sql_dialect;
GO
-- pg_catalog.bit doesn't recognize 'true'
select CAST('true' AS bit);
GO
select CAST('true' AS pg_catalog.bit);
GO
select CAST('1' AS bit);
GO
select CAST('1' AS pg_catalog.bit);
GO

-- test numeric and integer input
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
select CAST(1 AS bit);
GO
select CAST(2 AS bit);
GO
select CAST(0 AS bit);
GO
select CAST(000 AS bit);
GO
select CAST(0.0 AS bit);
GO
select CAST(0.00 AS bit);
GO
select CAST(0.5 AS bit);
GO

-- test negative operator
select CAST(-1 AS bit);
GO
select CAST(-0.5 AS bit);
GO

-- test int2 int4 int8 input
select CAST(CAST(2 AS int2) AS bit);
GO
select CAST(CAST(0 AS int2) AS bit);
GO
select CAST(CAST(2 AS int4) AS bit);
GO
select CAST(CAST(0 AS int4) AS bit);
GO
select CAST(CAST(2 AS int8) AS bit);
GO
select CAST(CAST(0 AS int8) AS bit);
GO

-- test real, double precision input
select CAST(CAST(1.5 AS real) AS bit);
GO
select CAST(CAST(0.0 AS real) AS bit);
GO
select CAST(CAST(1.5 AS double precision) AS bit);
GO
select CAST(CAST(0.0 AS double precision) AS bit);
GO

-- test decimal, numeric input
select CAST(CAST(1.5 AS decimal(4,2)) AS bit);
GO
select CAST(CAST(0.0 AS decimal(4,2)) AS bit);
GO
select CAST(CAST(1.5 AS numeric(4,2)) AS bit);
GO
select CAST(CAST(0.0 AS numeric(4,2)) AS bit);
GO

-- test operators of bit
create table testing6 (col1 bit, col2 bit);
GO
insert into testing6 (col1, col2) select 'true', 'false';
insert into testing6 (col1, col2) select 0, 1;
insert into testing6 (col1, col2) select '1', '2';
insert into testing6 (col1, col2) select 0.5, -1.5;
select * from testing6;
GO
select count(*) from testing6 where col1 = col2;
GO
select count(*) from testing6 where col1 <> col2;
GO
select count(*) from testing6 where col1 > col2;
GO
select count(*) from testing6 where col1 >= col2;
GO
select count(*) from testing6 where col1 < col2;
GO
select count(*) from testing6 where col1 <= col2;
GO

-- test casting of bits to other numeric types
select cast(cast (1 as bit) as tinyint);
GO
select cast(cast (1 as bit) as smallint);
GO
select cast(cast (1 as bit) as int);
GO
select cast(cast (1 as bit) as bigint);
GO
select cast(cast (1 as bit) as numeric(2,1));
GO
select cast(cast (1 as bit) as money);
GO
select cast(cast (1 as bit) as smallmoney);
GO

-- test comparisions
select 1 = cast (1 as bit);
GO

-- test varbinary is available
select cast('abc' as varbinary(3));
GO
-- test not throwing error if input would be truncated
select cast('abc' as varbinary(2));
GO

-- test throwing error when not explicit casting
drop table testing6;
GO
create table testing6(col varbinary(2));
GO
insert into testing6 values(cast('ab' as varchar));
GO
insert into testing6 values(cast('ab' as varbinary(2)));
GO
-- test throwing error if input would be truncated during table insert
insert into testing6 values(cast('abc' as varbinary(3)));
GO
select * from testing6;
GO

-- test casting varbinary to varchar
select cast(cast('a' AS varchar(10)) as varbinary(2));
GO
select cast(cast(cast('a' AS varchar(10)) as varbinary(2)) as varchar(2));
GO
select cast(cast('ab' AS varchar(10)) as varbinary(2));
GO
select cast(cast(cast('ab' AS varchar(10)) as varbinary(2)) as varchar(2));
GO
select cast(cast('abc' AS varchar(10)) as varbinary(2));
GO
select cast(cast(cast('abc' AS varchar(10)) as varbinary(2)) as varchar(2));
GO

-- test casting varbinary to nvarchar
select cast(cast('a' AS nvarchar(10)) as varbinary(2));
GO
select cast(cast(cast('a' AS nvarchar(10)) as varbinary(2)) as nvarchar(2));
GO
select cast(cast('ab' AS nvarchar(10)) as varbinary(2));
GO
select cast(cast(cast('ab' AS nvarchar(10)) as varbinary(2)) as nvarchar(2));
GO
select cast(cast('abc' AS nvarchar(10)) as varbinary(2));
GO
select cast(cast(cast('abc' AS nvarchar(10)) as varbinary(2)) as nvarchar(2));
GO

-- test sys.image is available
select cast('abc' as image);
GO

-- test sys.binary is available
select cast('abc' as binary(3));
GO
-- test not throwing error if input would be truncated
select cast('abc' as binary(2));
GO

drop table testing6;
GO
create table testing6(col binary(2));
GO
-- test throwing error when not explicit casting
insert into testing6 values (cast('ab' as varchar));
GO
insert into testing6 values (cast('ab' as binary(2)));
GO
-- test throwing error if input would be truncated
insert into testing6 values (cast('abc' as binary(3)));
GO
-- test null padding extra space for binary type
insert into testing6 values (cast('a' as binary(2)));
GO
select * from testing6;
GO

-- test casting binary to varchar
select cast(cast('a' AS varchar(10)) as binary(2));
GO
-- BABEL-1030
select cast(cast(cast('a' AS varchar(10)) as binary(2)) as varchar(2));
GO
select cast(cast('ab' AS varchar(10)) as binary(2));
GO
select cast(cast(cast('ab' AS varchar(10)) as binary(2)) as varchar(2));
GO
select cast(cast('abc' AS varchar(10)) as binary(2));
GO
select cast(cast(cast('abc' AS varchar(10)) as binary(2)) as varchar(2));
GO

-- test casting binary to nvarchar
select cast(cast('a' AS nvarchar(10)) as binary(2));
GO
-- BABEL-1030
select cast(cast(cast('a' AS nvarchar(10)) as binary(2)) as nvarchar(2));
GO
select cast(cast('ab' AS nvarchar(10)) as binary(2));
GO
select cast(cast(cast('ab' AS nvarchar(10)) as binary(2)) as nvarchar(2));
GO
select cast(cast('abc' AS nvarchar(10)) as binary(2));
GO
select cast(cast(cast('abc' AS nvarchar(10)) as binary(2)) as nvarchar(2));
GO

-- test varbinary(max) syntax
select CAST('010 ' AS varbinary(max));
GO
select CAST('010' AS varbinary(max));
GO

-- test binary(max) is invalid syntax
select cast('abc' as binary(max));
GO

-- test varbinary(max) as a column
drop table testing6;
GO
create table testing6(col varbinary(max));
GO
insert into testing6 values ('abc');
GO
select * from testing6;
GO

-- test default length is 1
drop table testing6;
GO
create table testing6(col varbinary);
GO
insert into testing6 values (cast('a' as varbinary));
GO
insert into testing6 values (cast('ab' as varbinary));
GO
select * from testing6;
GO
drop table testing6;
GO
create table testing6(col binary);
GO
insert into testing6 values (cast('a' as varbinary));
GO
insert into testing6 values (cast('ab' as varbinary));
GO
select * from testing6;
GO

-- test default length of varbinary in cast/convert is 30
-- truncation silently
select cast('abcdefghijklmnopqrstuvwxyzabcde' as varbinary);
GO
-- no truncation
select cast('abcdefghijklmnopqrstuvwxyzabcd' as varbinary);
GO

-- truncation silently
select convert(varbinary, 'abcdefghijklmnopqrstuvwxyzabcde');
GO
-- no truncation
select convert(varbinary, 'abcdefghijklmnopqrstuvwxyzabcd');
GO


-- test escape format '\' is not specially handled for varbinary
-- but it is escaped handled for bytea
select CAST('\13' AS varbinary(5));
GO
select CAST('\13' AS bytea);
GO
select CAST('\x13' AS varbinary(5));
GO
select CAST('\x13' AS bytea);
GO
select CAST('\\' AS varbinary(5));
GO
select CAST('\\' AS bytea);
GO
select CAST('\' AS varbinary);
GO
select CAST('\' AS bytea);
GO

-- test NULL pad extra space for binary type, not for varbinary and image
select CAST('\\' AS binary(3));
GO
select CAST('\\' AS varbinary(3));
GO
select CAST('\\' AS image);
GO

-- [BABEL-254] test integer input is allowed for varbinary
select cast(16 as varbinary(4));
GO
select cast(16*16 as varbinary(4));
GO
select cast(16*16*16 as varbinary(4));
GO
select cast(511 as varbinary(4));
GO
-- test truncation to the left if the number input is too large
select cast(16*16*16*16 as varbinary(2));
GO
-- test same behavior on table insert
drop table testing6;
GO
create table testing6 (col varbinary(2));
GO
insert into testing6 values (16);
GO
insert into testing6 values (16*16);
GO
insert into testing6 values (16*16*16);
GO
insert into testing6 values (16*16*16*16);
GO
select * from testing6;
GO

-- test int2, int4, int8 to varbinary
select cast(16*CAST(16 AS int2) as varbinary(2));
GO
select cast(16*CAST(16 AS int4) as varbinary(4));
GO
select cast(16*CAST(16 AS int8) as varbinary(8));
GO

-- test truncation to the left if maxlen is shorter than the input
select cast(CAST(16 AS int2) as varbinary(1));
GO
select cast(CAST(16 AS int2) as varbinary(2));
GO
-- test varbinary will only use 2 bytes (the size of the input) rather
-- than maxlen
select cast(CAST(16 AS int2) as varbinary(3));
GO
select cast(CAST(16 AS int2) as varbinary(4));
GO
select cast(CAST(16 AS int2) as varbinary(8));
GO

select cast(CAST(16 AS int4) as varbinary(1));
GO
select cast(CAST(16 AS int4) as varbinary(2));
GO
select cast(CAST(16 AS int4) as varbinary(3));
GO
select cast(CAST(16 AS int4) as varbinary(4));
GO
select cast(CAST(16 AS int4) as varbinary(8));
GO

select cast(CAST(16 AS int8) as varbinary(1));
GO
select cast(CAST(16 AS int8) as varbinary(2));
GO
select cast(CAST(16 AS int8) as varbinary(3));
GO
select cast(CAST(16 AS int8) as varbinary(4));
GO
select cast(CAST(16 AS int8) as varbinary(8));
GO

-- [BABEL-254] test integer iput is allowed for binary
select cast(16 as binary(2));
GO
select cast(16*16 as binary(2));
GO
select cast(16*16*16 as binary(2));
GO
-- test truncation to the left if the number input is too large
select cast(16*16*16*16 as binary(2));
GO
-- test same behavior on table insert
drop table testing6;
GO
create table testing6 (col binary(2));
GO
insert into testing6 values (16);
GO
insert into testing6 values (16*16);
GO
insert into testing6 values (16*16*16);
GO
insert into testing6 values (16*16*16*16);
GO
select * from testing6;
GO

-- test int2, int4, int8 to binary
select cast(16*CAST(16 AS int2) as binary(2));
GO
select cast(16*CAST(16 AS int4) as binary(4));
GO
select cast(16*CAST(16 AS int8) as binary(8));
GO

-- test truncation to the left if maxlen is shorter than the input
select cast(CAST(16 AS int2) as binary(1));
GO
select cast(CAST(16 AS int2) as binary(2));
GO
select cast(CAST(16 AS int2) as binary(3));
GO
-- test 0 padding to the left if maxlen is longer than the input
select cast(CAST(16 AS int2) as binary(4));
GO
select cast(CAST(16 AS int2) as binary(8));
GO

select cast(CAST(16 AS int4) as binary(1));
GO
select cast(CAST(16 AS int4) as binary(2));
GO
select cast(CAST(16 AS int4) as binary(3));
GO
select cast(CAST(16 AS int4) as binary(4));
GO
-- test 0 padding to the left if maxlen is longer than the input
select cast(CAST(16 AS int4) as binary(8));
GO

select cast(CAST(16 AS int8) as binary(1));
GO
select cast(CAST(16 AS int8) as binary(2));
GO
select cast(CAST(16 AS int8) as binary(3));
GO
select cast(CAST(16 AS int8) as binary(4));
GO
select cast(CAST(16 AS int8) as binary(8));
GO
-- test 0 padding to the left if maxlen is longer than the input
select cast(CAST(16 AS int8) as binary(10));
GO

-- test casting varbinary to int4
CREATE PROCEDURE cast_varbinary(@val int) AS
BEGIN
  DECLARE @BinaryVariable varbinary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;
GO

EXEC cast_varbinary(16);
GO
EXEC cast_varbinary(16*16);
GO
EXEC cast_varbinary(511);
GO
drop procedure cast_varbinary;
GO

-- test casting varbinary to int4 when the varbinary size is longer than 4
CREATE PROCEDURE cast_varbinary(@val int) AS
BEGIN
  DECLARE @BinaryVariable varbinary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;
GO

EXEC cast_varbinary(16);
GO
EXEC cast_varbinary(16*16);
GO
drop procedure cast_varbinary;
GO

-- test truncation varbinary to int4
CREATE PROCEDURE cast_varbinary(@val int) AS
BEGIN
  DECLARE @BinaryVariable varbinary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;
GO

EXEC cast_varbinary(16);
GO

EXEC cast_varbinary(16*16);
GO

drop procedure cast_varbinary;
GO


-- test casting varbinary to int2
CREATE PROCEDURE cast_varbinary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable varbinary(2) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;
GO

EXEC cast_varbinary(CAST(16 AS int2));
GO

EXEC cast_varbinary(CAST(256 AS int2));
GO

drop procedure cast_varbinary;
GO

-- test truncation varbinary to int2
CREATE PROCEDURE cast_varbinary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable varbinary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;
GO

EXEC cast_varbinary(CAST(16 AS int2));
GO
EXEC cast_varbinary(CAST(256 AS int2));
GO
drop procedure cast_varbinary;
GO

-- test casting varbinary to int8
CREATE PROCEDURE cast_varbinary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable varbinary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;
GO

EXEC cast_varbinary(CAST(16 AS int8));
GO
EXEC cast_varbinary(16*CAST(16 AS int8));
GO
drop procedure cast_varbinary;
GO

-- test truncation varbinary to int8
CREATE PROCEDURE cast_varbinary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable varbinary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;
GO

EXEC cast_varbinary(CAST(16 AS int8));
GO
EXEC cast_varbinary(16*CAST(16 AS int8));
GO
drop procedure cast_varbinary;
GO

-- test casting binary to int4
CREATE PROCEDURE cast_binary(@val int) AS
BEGIN
  DECLARE @BinaryVariable binary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;
GO

EXEC cast_binary(16);
GO
EXEC cast_binary(256);
GO
drop procedure cast_binary;
GO

-- test casting binary to int4 when the binary size is greater than 4
CREATE PROCEDURE cast_binary(@val int) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;
GO

EXEC cast_binary(16);
GO
EXEC cast_binary(256);
GO
drop procedure cast_binary;
GO

-- test truncation binary to int4
CREATE PROCEDURE cast_binary(@val int) AS
BEGIN
  DECLARE @BinaryVariable binary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;
GO

EXEC cast_binary(16);
GO
EXEC cast_binary(256);
GO
drop procedure cast_binary;
GO

-- test casting binary to int2
CREATE PROCEDURE cast_binary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable binary(2) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;
GO

EXEC cast_binary(CAST(16 AS int2));
GO
EXEC cast_binary(CAST(256 AS int2));
GO
drop procedure cast_binary;
GO

-- test casting binary to int2 when the binary size is greater than 2
CREATE PROCEDURE cast_binary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;
GO

EXEC cast_binary(CAST(16 AS int2));
GO
EXEC cast_binary(CAST(256 AS int2));
GO
drop procedure cast_binary;
GO

-- test truncation binary to int2
CREATE PROCEDURE cast_binary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable binary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;
GO

EXEC cast_binary(CAST(16 AS int2));
GO
EXEC cast_binary(CAST(256 AS int2));
GO
drop procedure cast_binary;
GO

-- test casting binary to int8
CREATE PROCEDURE cast_binary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;
GO

EXEC cast_binary(CAST(16 AS int8));
GO
EXEC cast_binary(CAST(256 AS int8));
GO
drop procedure cast_binary;
GO

-- test casting binary to int8 when the binary size is greater than 8
CREATE PROCEDURE cast_binary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable binary(12) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;
GO

EXEC cast_binary(CAST(16 AS int8));
GO
EXEC cast_binary(CAST(256 AS int8));
GO
drop procedure cast_binary;
GO

-- test truncation binary to int8
CREATE PROCEDURE cast_binary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable binary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;
GO

EXEC cast_binary(CAST(16 AS int8));
GO
EXEC cast_binary(CAST(256 AS int8));
GO
drop procedure cast_binary;
GO

-- test real to varbinary
select cast(CAST(0.125 AS real) as varbinary(4));
GO
drop table testing6;
GO
create table testing6 (col varbinary(4));
GO
insert into testing6 values (CAST(0.125 AS real));
insert into testing6 values (CAST(3.125 AS real));
select * from testing6;
GO

-- test truncation rule when input is too long/varbinary length is too short
select cast(CAST(0.125 AS real) as varbinary(2));
GO
select cast(CAST(0.125 AS real) as varbinary(4));
GO

-- test casting varbinary back to real
CREATE PROCEDURE cast_varbinary(@val real) AS
BEGIN
  DECLARE @BinaryVariable varbinary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as real)
END;
EXEC cast_varbinary(0.125);
GO
EXEC cast_varbinary(3.125);
GO
drop procedure cast_varbinary;
GO

-- test dobule precision to varbinary
select cast(CAST(0.123456789 AS double precision) as varbinary(8));
GO
drop table testing6;
GO
create table testing6 (col varbinary(8));
GO
insert into testing6 values (CAST(0.123456789 AS double precision));
insert into testing6 values (CAST(3.123456789 AS double precision));
select * from testing6;
GO

-- test truncation rule when input is too long/varbinary length is too short
select cast(CAST(0.123456789 AS double precision) as varbinary(2));
GO
select cast(CAST(0.123456789 AS double precision) as varbinary(8));
GO

-- test casting varbinary back to double precision
CREATE PROCEDURE cast_varbinary(@val double precision) AS
BEGIN
  DECLARE @BinaryVariable varbinary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as double precision)
END;
GO
EXEC cast_varbinary(0.123456789);
GO
EXEC cast_varbinary(3.123456789);
GO
drop procedure cast_varbinary;
GO

-- test real to binary
select cast(CAST(0.125 AS real) as binary(4));
GO
drop table testing6;
GO
create table testing6 (col binary(4));
GO
insert into testing6 values (CAST(0.125 AS real));
insert into testing6 values (CAST(3.125 AS real));
select * from testing6;
GO

-- test truncation rule when input is too long/binary length is too short
select cast(CAST(0.125 AS real) as binary(2));
GO
select cast(CAST(0.125 AS real) as binary(4));
GO

-- test casting binary back to real
CREATE PROCEDURE cast_binary(@val real) AS
BEGIN
  DECLARE @BinaryVariable binary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as real)
END;
GO
EXEC cast_binary(0.125);
GO
EXEC cast_binary(3.125);
GO
drop procedure cast_binary;
GO

-- test dobule precision to binary
select cast(CAST(0.123456789 AS double precision) as binary(8));
GO
drop table testing6;
GO
create table testing6 (col binary(8));
GO
insert into testing6 values (CAST(0.123456789 AS double precision));
insert into testing6 values (CAST(3.123456789 AS double precision));
select * from testing6;
GO

-- test truncation rule when input is too long/binary length is too short
select cast(CAST(0.123456789 AS double precision) as binary(2));
GO
select cast(CAST(0.123456789 AS double precision) as binary(8));
GO

-- test casting binary back to double precision
CREATE PROCEDURE cast_binary(@val double precision) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as double precision)
END;
GO
call cast_binary(0.123456789);
GO
call cast_binary(3.123456789);
GO
drop procedure cast_binary;
GO

-- sys.sysname
select CAST('£' AS sysname);             -- allowed
GO
select CAST(NULL AS sysname);            -- not allowed
GO

-- sys.sysname is working in both dialects
select CAST('£' AS sys.sysname);         -- allowed
GO
select CAST(NULL AS sys.sysname);        -- not allowed
GO
reset babelfishpg_tsql.sql_dialect;
GO
select CAST('£' AS sys.sysname);         -- allowed
GO
select CAST(NULL AS sys.sysname);        -- not allowed
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
create table test_sysname (col sys.sysname);
GO
insert into test_sysname values (repeat('£', 128));  -- allowed
GO
insert into test_sysname values (repeat('😀', 128)); -- not allowed due to UTF check
GO
reset babelfishpg_tsql.sql_dialect;
GO
insert into test_sysname values (repeat('😀', 128)); -- not allowed due to UTF check
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- clean up
drop table testing1;
GO
drop table testing2;
GO
drop table testing3;
GO
drop table testing4;
GO
drop table testing5;
GO
drop table testing6;
GO
drop table test_sysname;
GO
reset babelfishpg_tsql.sql_dialect;
GO