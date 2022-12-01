CREATE EXTENSION IF NOT EXISTS "babelfishpg_tsql" CASCADE;

-- The default scale is 2 in PG.
select CAST('$100,123.4567' AS money);
-- Currency symbol followed by number without being quoted is not recognized
-- as Money in postgres dialect.
select CAST($100123.4567 AS money);

-- Scale changes to the sql server default 4 in tsql dialect
-- Currency symbol followed by number without being quoted is recognized
-- as Money type in tsql dialect.
set babelfishpg_tsql.sql_dialect = "tsql";
select CAST($100123.4567 AS money);
select CAST($100123. AS money);
select CAST($.4567 AS money);
select CAST('$100,123.4567' AS money);

-- Test numeric types with brackets
create table testing1 (a [tinyint]);
drop table testing1;
create table testing1 (a [smallint]);
drop table testing1;
create table testing1 (a [int]);
drop table testing1;
create table testing1 (a [bigint]);
drop table testing1;
create table testing1 (a [real]);
drop table testing1;
create table testing1 (a [float]);
drop table testing1;

-- Comma separated format without quote is not allowed in sql server
select CAST($100,123.4567 AS money);

-- Smallmoney in tsql dialect
select CAST($100123.4567 AS smallmoney);
select CAST('$100,123.4567' AS smallmoney);
-- Comma separated format without quote is not allowed in sql server
select CAST($100,123.4567 AS smallmoney);

create table testing1(mon money, smon smallmoney);
insert into testing1 (mon, smon) values ('$100,123.4567', '$123.9999');
insert into testing1 (mon, smon) values ($100123.4567, $123.9999);
select * from testing1;
select avg(CAST(mon AS numeric(38,4))), avg(CAST(smon AS numeric(38,4))) from testing1;
select mon+smon as total from testing1;
-- Comma separated format without quote is not allowed in sql server
insert into testing1 (mon, smon) values ($100,123.4567, $123.9999);

-- Test other allowed currency symbols with/without quote
select CAST(€100.123 AS money);
select CAST('€100.123' AS money);
select CAST(¢100.123 AS money);
select CAST(£100.123 AS money);
select CAST('£100.123' AS money);
select CAST(¤100.123 AS money);
select CAST(¥100.123 AS money);
select CAST(৲100.123 AS money);
select CAST(৳100.123 AS money);
select CAST(฿100.123 AS money);
select CAST(៛100.123 AS money);
select CAST(₠100.123 AS money);
select CAST(₡100.123 AS money);
select CAST(₢100.123 AS money);
select CAST(₣100.123 AS money);
select CAST(₤100.123 AS money);
select CAST(₥100.123 AS money);
select CAST(₦100.123 AS money);
select CAST(₧100.123 AS money);
select CAST(₨100.123 AS money);
select CAST(₩100.123 AS money);
select CAST(₪100.123 AS money);
select CAST(₫100.123 AS money);
select CAST(₭100.123 AS money);
select CAST(₮100.123 AS money);
select CAST(₯100.123 AS money);
select CAST(₰100.123 AS money);
select CAST(₱100.123 AS money);
select CAST(﷼100.123 AS money);
select CAST(﹩100.123 AS money);
select CAST(＄100.123 AS money);
select CAST(￠100.123 AS money);
select CAST(￡100.123 AS money);
select CAST(￥100.123 AS money);
select CAST('￥100.123' AS money);
select CAST(￦100.123 AS money);

-- Test unsupoorted currency symbol
select CAST(￩100.123 AS money);
select CAST('￩100.123' AS money);

-- Test that space is allowed between currency symbol and number, this is
-- a TSQL behavior
select CAST($   123.5 AS money);
select CAST('$    123.5' AS money);

-- Test inexact result mutliply/divide money with money, to match
-- SQL Server behavior
select CAST(100 AS money)/CAST(339 AS money)*CAST(10000 AS money);

-- Test postgres dialect
-- Test currency symbol without quote is not allowed in postgres dialect
reset babelfishpg_tsql.sql_dialect;
select CAST(€100.123 AS money);

-- Test exact result multiply/divide money with money in postgres dialect
select CAST(100 AS money)/CAST(339 AS money)*CAST(10000 AS money);

-- Clean up
drop table testing1;

-- BABEL-109 test no more not unique operator error caused by fixeddeciaml
select CAST(2 AS numeric) > 1;
select CAST(2 AS decimal) > 1;

-- Test that numeric > int and fixeddecimal > int is different
select CAST(2.00001 AS numeric) > 2;
select CAST(2.00001 AS sys.fixeddecimal) > 2;

-- test TSQL Money (based on fixeddecimal) cross datatype operators
set babelfishpg_tsql.sql_dialect = "tsql";
select CAST(2 AS money) > 1;
select CAST(2 AS money) > CAST(1 AS int);
select CAST(2 AS money) > CAST(1 AS int2);
select CAST(2 AS money) > CAST(1 AS int4);
select CAST(2 AS money) > CAST(1 AS numeric);
select CAST(2 AS money) > CAST(1 AS decimal);

select CAST(2 AS money) >= 1;
select CAST(2 AS money) >= CAST(1 AS int);
select CAST(2 AS money) >= CAST(1 AS int2);
select CAST(2 AS money) >= CAST(1 AS int4);
select CAST(2 AS money) >= CAST(1 AS numeric);
select CAST(2 AS money) >= CAST(1 AS decimal);

select CAST(2 AS money) < 1;
select CAST(2 AS money) < CAST(1 AS int);
select CAST(2 AS money) < CAST(1 AS int2);
select CAST(2 AS money) < CAST(1 AS int4);
select CAST(2 AS money) < CAST(1 AS numeric);
select CAST(2 AS money) < CAST(1 AS decimal);

select CAST(2 AS money) <= 1;
select CAST(2 AS money) <= CAST(1 AS int);
select CAST(2 AS money) <= CAST(1 AS int2);
select CAST(2 AS money) <= CAST(1 AS int4);
select CAST(2 AS money) <= CAST(1 AS numeric);
select CAST(2 AS money) <= CAST(1 AS decimal);

select CAST(2 AS money) <> 1;
select CAST(2 AS money) <> CAST(1 AS int);
select CAST(2 AS money) <> CAST(1 AS int2);
select CAST(2 AS money) <> CAST(1 AS int4);
select CAST(2 AS money) <> CAST(1 AS numeric);
select CAST(2 AS money) <> CAST(1 AS decimal);

select CAST(2 AS money) + 1;
select CAST(2 AS money) + CAST(1 AS int);
select CAST(2 AS money) + CAST(1 AS int2);
select CAST(2 AS money) + CAST(1 AS int4);
select CAST(2 AS money) + CAST(1 AS numeric);
select CAST(2 AS money) + CAST(1 AS decimal);

select CAST(2 AS money) - 1;
select CAST(2 AS money) - CAST(1 AS int);
select CAST(2 AS money) - CAST(1 AS int2);
select CAST(2 AS money) - CAST(1 AS int4);
select CAST(2 AS money) - CAST(1 AS numeric);
select CAST(2 AS money) - CAST(1 AS decimal);

select CAST(2 AS money) * 2;
select CAST(2 AS money) * CAST(2 AS int);
select CAST(2 AS money) * CAST(2 AS int2);
select CAST(2 AS money) * CAST(2 AS int4);
select CAST(2 AS money) * CAST(2 AS numeric);
select CAST(2 AS money) * CAST(2 AS decimal);

select CAST(2 AS money) / 0.5;
select CAST(2 AS money) / CAST(2 AS int);
select CAST(2 AS money) / CAST(2 AS int2);
select CAST(2 AS money) / CAST(2 AS int4);
select CAST(2 AS money) / CAST(0.5 AS numeric(4,2));
select CAST(2 AS money) / CAST(0.5 AS decimal(4,2));

reset babelfishpg_tsql.sql_dialect;

-- Test DATE, DATETIME, DATETIMEOFFSET, DATETIME2
set babelfishpg_tsql.sql_dialect = "tsql";

-- DATE DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME are defined in tsql dialect
select CAST('2020-03-15' AS date);
select CAST('2020-03-15 09:00:00+8' AS datetimeoffset);
select CAST('2020-03-15 09:00:00' AS datetime2);
select CAST('2020-03-15 09:00:00' AS smalldatetime);
-- test the range of date
select CAST('0001-01-01' AS date);
select CAST('9999-12-31' AS date);
-- test the range of datetime2
select CAST('0001-01-01 12:00:00.12345' AS datetime2);
select CAST('9999-12-31 12:00:00.12345' AS datetime2);
-- precision
select CAST('2020-03-15 09:00:00+8' AS datetimeoffset(7)) ;
create table testing1(ts DATETIME, tstz DATETIMEOFFSET(7));
insert into testing1 (ts, tstz) values ('2020-03-15 09:00:00', '2020-03-15 09:00:00+8');
select * from testing1;
drop table testing1;

select CAST('2020-03-15 09:00:00' AS datetime2(7));
select CAST('2020-03-15 09:00:00.123456' AS datetime2(3));
select CAST('2020-03-15 09:00:00.123456' AS datetime2(0));
select CAST('2020-03-15 09:00:00.123456' AS datetime2(-1));
create table testing1(ts DATETIME, tstz DATETIME2(7));
insert into testing1 (ts, tstz) values ('2020-03-15 09:00:00', '2020-03-15 09:00:00');
select * from testing1;
drop table testing1;

-- DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME are not defined in
-- postgres dialect
SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
select CAST('2020-03-15 09:00:00+8' AS datetimeoffset);
create table testing1(ts DATETIME);
create table testing1(tstz DATETIMEOFFSET);
select CAST('2020-03-15 09:00:00' AS datetime2);
create table testing1(ts SMALLDATETIME);
create table testing1(tstz DATETIME2);

-- Test DATETIME, DATETIMEOFFSET, DATETIME2 and SMALLDATETIME can be used as identifier
create table testing1(DATETIME int);
insert into testing1 (DATETIME) values (1);
select * from testing1;
drop table testing1;

create table testing1(DATETIMEOFFSET int);
insert into testing1 (DATETIMEOFFSET) values (1);
select * from testing1;
drop table testing1;

create table testing1(DATETIME2 int);
insert into testing1 (DATETIME2) values (1);
select * from testing1;
drop table testing1;

create table testing1(SMALLDATETIME int);
insert into testing1 (SMALLDATETIME) values (1);
select * from testing1;

set babelfishpg_tsql.sql_dialect = 'tsql';
insert into testing1 (SMALLDATETIME) values (2);
select * from testing1;

-- Test conversion between DATE and other date/time types
select CAST(CAST('2020-03-15' AS date) AS datetime);
select CAST(CAST('2020-03-15' AS date) AS smalldatetime);
select CAST(CAST('2020-03-15' AS date) AS datetimeoffset(3));
select CAST(CAST('2020-03-15' AS date) AS datetime2(3));

-- Clean up
reset babelfishpg_tsql.sql_dialect;
drop table testing1;

-- Test SYS.NCHAR, SYS.NVARCHAR and SYS.VARCHAR
-- nchar is already available in postgres dialect
select CAST('£' AS nchar(1));
-- nvarchar is not available in postgres dialect
select CAST('£' AS nvarchar);

-- both are available in tsql dialect
set babelfishpg_tsql.sql_dialect = 'tsql';
select CAST('£' AS nchar(2));
select CAST('£' AS nvarchar(2));

-- multi-byte character doesn't fit in nchar(1) in tsql if it
-- would require a UTF16-surrogate-pair on output
select CAST('£' AS char(1));			-- allowed
select CAST('£' AS sys.nchar(1));		-- allowed
select CAST('£' AS sys.nvarchar(1));	-- allowed
select CAST('£' AS sys.varchar(1));		-- allowed

-- Check that things work the same in postgres dialect
reset babelfishpg_tsql.sql_dialect;
select CAST('£' AS char(1));
select CAST('£' AS sys.nchar(1));
select CAST('£' AS sys.nvarchar(1));
select CAST('£' AS sys.varchar(1));
set babelfishpg_tsql.sql_dialect = 'tsql';

-- truncate input on explicit cast
select CAST('ab' AS char(1));
select CAST('ab' AS nchar(1));
select CAST('ab' AS nvarchar(1));
select CAST('ab' AS sys.varchar(1));


-- default length of nchar/char is 1 in tsql (and pg)
create table testing1(col nchar);
reset babelfishpg_tsql.sql_dialect;
\d testing1;
set babelfishpg_tsql.sql_dialect = "tsql";

-- check length at insert
insert into testing1 (col) select 'a';
insert into testing1 (col) select '£';
insert into testing1 (col) select 'ab';
-- space is automatically truncated
insert into testing1 (col) select 'c ';
select * from testing1;

-- default length of nvarchar in tsql is 1
create table testing2(col nvarchar);

insert into testing2 (col) select 'a';
insert into testing2 (col) select '£';
insert into testing2 (col) select 'ab';
-- space is automatically truncated
insert into testing2 (col) select 'c ';
select * from testing2;

-- default length of varchar in tsql is 1
create table testing4(col sys.varchar);

insert into testing4 (col) select 'a';
insert into testing4 (col) select '£';
insert into testing4 (col) select 'ab';
-- space is automatically truncated
insert into testing4 (col) select 'c ';
insert into testing2 (col) select '£ ';
select * from testing4;

-- test sys.varchar(max) and sys.nvarchar(max) syntax is allowed in tsql dialect
select CAST('abcdefghijklmn' AS sys.varchar(max));
select CAST('abcdefghijklmn' AS varchar(max));
select CAST('abcdefghijklmn' AS sys.nvarchar(max));
select CAST('abcdefghijklmn' AS nvarchar(max));

-- test char(max), nchar(max) is invalid syntax in tsql dialect
select cast('abc' as char(max));
select cast('abc' as nchar(max));

-- test max can still be used as an identifier
create table max (max int);
insert into max (max) select 100;
select * from max;
drop table max;

-- test sys.varchar(max) and nvarchar(max) syntax is not allowed in postgres dialect
reset babelfishpg_tsql.sql_dialect;
select CAST('abcdefghijklmn' AS sys.varchar(max));
select CAST('abcdefghijklmn' AS varchar(max));
select CAST('abcdefghijklmn' AS sys.nvarchar(max));
select CAST('abcdefghijklmn' AS nvarchar(max));

-- test max max character length is (10 * 1024 * 1024) = 10485760
select CAST('abc' AS varchar(10485761));
select CAST('abc' AS varchar(10485760));

-- test column type nvarchar(max)
set babelfishpg_tsql.sql_dialect = 'tsql';
create table testing5(col nvarchar(max));
reset babelfishpg_tsql.sql_dialect;
\d testing5
set babelfishpg_tsql.sql_dialect = "tsql";
insert into testing5 (col) select 'ab';
insert into testing5 (col) select 'abcdefghijklmn';
select * from testing5;

--test COPY command works with sys.nvarchar
COPY public.testing5 (col) FROM stdin;
c
ab
abcdefghijk
\.
select * from testing5;

-- [BABEL-220] test varchar(max) as a column
drop table testing5;
create table testing5(col varchar(max));
reset babelfishpg_tsql.sql_dialect;
\d testing5
set babelfishpg_tsql.sql_dialect = "tsql";
insert into testing5 (col) select 'ab';
insert into testing5 (col) select 'abcdefghijklmn';
select * from testing5;

-- test type modifer persist if babelfishpg_tsql.sql_dialect changes
create table testing3(col nvarchar(2));
insert into testing3 (col) select 'ab';
insert into testing3 (col) select 'a£';
insert into testing3 (col) select 'a😀';
insert into testing3 (col) select 'abc';

reset babelfishpg_tsql.sql_dialect;
insert into testing3 (col) select 'ab';
insert into testing3 (col) select 'a£';
insert into testing3 (col) select 'a😀';
insert into testing3 (col) select 'abc';

set babelfishpg_tsql.sql_dialect = 'tsql';
insert into testing3 (col) select 'ab';
insert into testing3 (col) select 'a£';
insert into testing3 (col) select 'a😀';
insert into testing3 (col) select 'abc';

-- test normal create domain works when apg_enable_domain_typmod is enabled
set apg_enable_domain_typmod true;
create domain varchar3 as varchar(3);
select CAST('abc' AS varchar3);
select CAST('ab£' AS varchar3);
select CAST('abcd' AS varchar3);
reset apg_enable_domain_typmod;

-- [BABEL-191] test typmod of sys.varchar/nvarchar engages when the input
-- is casted multiple times
select CAST(CAST('abc' AS text) AS sys.varchar(3));
select CAST(CAST('abc' AS pg_catalog.varchar(3)) AS sys.varchar(3));

select CAST(CAST('abc' AS text) AS sys.nvarchar(3));
select CAST(CAST('abc' AS text) AS sys.nchar(3));

select CAST(CAST(CAST(CAST('abc' AS text) AS sys.varchar(3)) AS sys.nvarchar(3)) AS sys.nchar(3));

-- test truncation on explicit cast through multiple levels
select CAST(CAST(CAST(CAST('abcde' AS text) AS sys.varchar(5)) AS sys.nvarchar(4)) AS sys.nchar(3));
select CAST(CAST(CAST(CAST('abcde' AS text) AS sys.varchar(3)) AS sys.nvarchar(4)) AS sys.nchar(5));

-- test sys.ntext is available
select CAST('abc£' AS sys.ntext);
-- pg_catalog.text
select CAST('abc£' AS text);

-- [BABEL-218] test varchar defaults to sys.varchar in tsql dialect
-- test default length of sys.varchar is 30 in CAST/CONVERT
-- expect the last 'e' to be truncated
select cast('abcdefghijklmnopqrstuvwxyzabcde' as varchar);
select cast('abcdefghijklmnopqrstuvwxyzabcde' as sys.varchar);
select convert(varchar, 'abcdefghijklmnopqrstuvwxyzabcde');
select convert(sys.varchar, 'abcdefghijklmnopqrstuvwxyzabcde');

-- default length of pg_catalog.varchar is unlimited, no truncation in output
select cast('abcdefghijklmnopqrstuvwxyzabcde' as pg_catalog.varchar);

-- varchar defaults to pg_catalog.varchar in PG dialect
reset babelfishpg_tsql.sql_dialect;
select cast('abcdefghijklmnopqrstuvwxyzabcde' as pg_catalog.varchar); -- default length of pg_catalog.varchar is unlimited, no truncation
set babelfishpg_tsql.sql_dialect = 'tsql';

-- [BABEL-255] test nchar defaults to sys.nchar in tsql dialect
create table test_nchar (col1 nchar);
reset babelfishpg_tsql.sql_dialect;
\d test_nchar
set babelfishpg_tsql.sql_dialect = "tsql";
drop table test_nchar;
-- test nchar defaults to bpchar in pg dialect
reset babelfishpg_tsql.sql_dialect;
create table test_nchar (col1 nchar);
\d test_nchar
drop table test_nchar;
set babelfishpg_tsql.sql_dialect = 'tsql';

-- [BABEL-257] test varchar defaults to sys.varchar in new
-- database and new schema
SELECT current_database();

SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
CREATE DATABASE demo;
\c demo
CREATE EXTENSION IF NOT EXISTS "babelfishpg_tsql" CASCADE;
-- Reconnect to make sure CLUSTER_COLLATION_OID is initialized
\c postgres
\c demo
set babelfishpg_tsql.sql_dialect = 'tsql';
-- Test varchar is mapped to sys.varchar
-- Expect truncated output because sys.varchar defaults to sys.varchar(30) in CAST function
select cast('abcdefghijklmnopqrstuvwxyzabcde' as varchar);
-- Expect non-truncated output because pg_catalog.varchar has unlimited length
select cast('abcdefghijklmnopqrstuvwxyzabcde' as pg_catalog.varchar);

-- Test bit is mapped to sys.bit
-- sys.bit allows numeric input
select CAST(1.5 AS bit);
-- pg_catalog.bit doesn't allow numeric input
select CAST(1.5 AS pg_catalog.bit);

-- Test varchar is mapped to sys.varchar in a new schema and a new table
CREATE SCHEMA s1;
create table s1.test1 (col varchar);
-- Test sys.varchar is created for test1.col, expect an error
-- because sys.varchar defaults to sys.varchar(1)
insert into s1.test1 values('abc');
insert into s1.test1 values('a');
select * from s1.test1;
drop schema s1 cascade;
SELECT set_config('babelfishpg_tsql.sql_dialect', 'postgres', false);
\c regression
drop database demo;
set babelfishpg_tsql.sql_dialect = 'tsql';

-- test tinyint data type
select CAST(100 AS tinyint);
select CAST(10 AS tinyint) / CAST(3 AS tinyint);
select CAST(256 AS tinyint);
select CAST((-1) AS tinyint);

-- test bit data type, bit defaults to sys.bit in tsql dialect
-- test 'true'/'false' input is allowed. 't'/'f' is not allowed.
select CAST('true' AS bit);
select CAST('True' AS bit);
select CAST('TRUE' AS bit);
select CAST('t' AS bit);
select CAST('T' AS bit);
select CAST('false' AS bit);
select CAST('False' AS bit);
select CAST('FALSE' AS bit);
select CAST('f' AS bit);
select CAST('F' AS bit);

-- test '1'/'0'
select CAST('1' AS bit);
select CAST('0' AS bit);
select CAST('000' AS bit);
select CAST('010' AS bit);

-- test 'abc' is not allowed
select CAST('abc' AS bit);

-- test NULL is allowed
select CAST(NULL AS bit);

-- bit defaults to pg_catalog.bit in pg dialect
reset babelfishpg_tsql.sql_dialect;
-- pg_catalog.bit doesn't recognize 'true'
select CAST('true' AS bit);
select CAST('true' AS pg_catalog.bit);
select CAST('1' AS bit);
select CAST('1' AS pg_catalog.bit);

-- test numeric and integer input
set babelfishpg_tsql.sql_dialect = 'tsql';
select CAST(1 AS bit);
select CAST(2 AS bit);
select CAST(0 AS bit);
select CAST(000 AS bit);
select CAST(0.0 AS bit);
select CAST(0.00 AS bit);
select CAST(0.5 AS bit);

-- test negative operator
select CAST(-1 AS bit);
select CAST(-0.5 AS bit);

-- test int2 int4 int8 input
select CAST(CAST(2 AS int2) AS bit);
select CAST(CAST(0 AS int2) AS bit);
select CAST(CAST(2 AS int4) AS bit);
select CAST(CAST(0 AS int4) AS bit);
select CAST(CAST(2 AS int8) AS bit);
select CAST(CAST(0 AS int8) AS bit);

-- test real, double precision input
select CAST(CAST(1.5 AS real) AS bit);
select CAST(CAST(0.0 AS real) AS bit);
select CAST(CAST(1.5 AS double precision) AS bit);
select CAST(CAST(0.0 AS double precision) AS bit);

-- test decimal, numeric input
select CAST(CAST(1.5 AS decimal(4,2)) AS bit);
select CAST(CAST(0.0 AS decimal(4,2)) AS bit);
select CAST(CAST(1.5 AS numeric(4,2)) AS bit);
select CAST(CAST(0.0 AS numeric(4,2)) AS bit);

-- test operators of bit
create table testing6 (col1 bit, col2 bit);
insert into testing6 (col1, col2) select 'true', 'false';
insert into testing6 (col1, col2) select 0, 1;
insert into testing6 (col1, col2) select '1', '2';
insert into testing6 (col1, col2) select 0.5, -1.5;
select * from testing6;
select count(*) from testing6 where col1 = col2;
select count(*) from testing6 where col1 <> col2;
select count(*) from testing6 where col1 > col2;
select count(*) from testing6 where col1 >= col2;
select count(*) from testing6 where col1 < col2;
select count(*) from testing6 where col1 <= col2;

-- test casting of bits to other numeric types
select cast(cast (1 as bit) as tinyint);
select cast(cast (1 as bit) as smallint);
select cast(cast (1 as bit) as int);
select cast(cast (1 as bit) as bigint);
select cast(cast (1 as bit) as numeric(2,1));
select cast(cast (1 as bit) as money);
select cast(cast (1 as bit) as smallmoney);

-- test comparisions
select 1 = cast (1 as bit);

-- test varbinary is available
select cast('abc' as varbinary(3));
-- test not throwing error if input would be truncated
select cast('abc' as varbinary(2));

-- test throwing error when not explicit casting
drop table testing6;
create table testing6(col varbinary(2));
insert into testing6 values(cast('ab' as varchar));
insert into testing6 values(cast('ab' as varbinary(2)));
-- test throwing error if input would be truncated during table insert
insert into testing6 values(cast('abc' as varbinary(3)));
select * from testing6;

-- test casting varbinary to varchar
select cast(cast('a' AS varchar(10)) as varbinary(2));
select cast(cast(cast('a' AS varchar(10)) as varbinary(2)) as varchar(2));
select cast(cast('ab' AS varchar(10)) as varbinary(2));
select cast(cast(cast('ab' AS varchar(10)) as varbinary(2)) as varchar(2));
select cast(cast('abc' AS varchar(10)) as varbinary(2));
select cast(cast(cast('abc' AS varchar(10)) as varbinary(2)) as varchar(2));

-- test casting varbinary to nvarchar
select cast(cast('a' AS nvarchar(10)) as varbinary(2));
select cast(cast(cast('a' AS nvarchar(10)) as varbinary(2)) as nvarchar(2));
select cast(cast('ab' AS nvarchar(10)) as varbinary(2));
select cast(cast(cast('ab' AS nvarchar(10)) as varbinary(2)) as nvarchar(2));
select cast(cast('abc' AS nvarchar(10)) as varbinary(2));
select cast(cast(cast('abc' AS nvarchar(10)) as varbinary(2)) as nvarchar(2));

-- test sys.image is available
select cast('abc' as image);

-- test sys.binary is available
select cast('abc' as binary(3));
-- test not throwing error if input would be truncated
select cast('abc' as binary(2));

drop table testing6;
create table testing6(col binary(2));
-- test throwing error when not explicit casting
insert into testing6 values (cast('ab' as varchar));
insert into testing6 values (cast('ab' as binary(2)));
-- test throwing error if input would be truncated
insert into testing6 values (cast('abc' as binary(3)));
-- test null padding extra space for binary type
insert into testing6 values (cast('a' as binary(2)));
select * from testing6;

-- test casting binary to varchar
select cast(cast('a' AS varchar(10)) as binary(2));
-- BABEL-1030
select cast(cast(cast('a' AS varchar(10)) as binary(2)) as varchar(2));
select cast(cast('ab' AS varchar(10)) as binary(2));
select cast(cast(cast('ab' AS varchar(10)) as binary(2)) as varchar(2));
select cast(cast('abc' AS varchar(10)) as binary(2));
select cast(cast(cast('abc' AS varchar(10)) as binary(2)) as varchar(2));

-- test casting binary to nvarchar
select cast(cast('a' AS nvarchar(10)) as binary(2));
-- BABEL-1030
select cast(cast(cast('a' AS nvarchar(10)) as binary(2)) as nvarchar(2));
select cast(cast('ab' AS nvarchar(10)) as binary(2));
select cast(cast(cast('ab' AS nvarchar(10)) as binary(2)) as nvarchar(2));
select cast(cast('abc' AS nvarchar(10)) as binary(2));
select cast(cast(cast('abc' AS nvarchar(10)) as binary(2)) as nvarchar(2));

-- test varbinary(max) syntax
select CAST('010 ' AS varbinary(max));
select CAST('010' AS varbinary(max));

-- test binary(max) is invalid syntax
select cast('abc' as binary(max));

-- test varbinary(max) as a column
drop table testing6;
create table testing6(col varbinary(max));
insert into testing6 values ('abc');
select * from testing6;

-- test binary max length is 8000
select CAST('010' AS binary(8001));

-- test default length is 1
drop table testing6;
create table testing6(col varbinary);
insert into testing6 values (cast('a' as varbinary));
insert into testing6 values (cast('ab' as varbinary));
select * from testing6;
drop table testing6;
create table testing6(col binary);
insert into testing6 values (cast('a' as varbinary));
insert into testing6 values (cast('ab' as varbinary));
select * from testing6;

-- test default length of varbinary in cast/convert is 30
-- truncation silently
select cast('abcdefghijklmnopqrstuvwxyzabcde' as varbinary);
-- no truncation
select cast('abcdefghijklmnopqrstuvwxyzabcd' as varbinary);

-- truncation silently
select convert(varbinary, 'abcdefghijklmnopqrstuvwxyzabcde');
-- no truncation
select convert(varbinary, 'abcdefghijklmnopqrstuvwxyzabcd');


-- test escape format '\' is not specially handled for varbinary
-- but it is escaped handled for bytea
select CAST('\13' AS varbinary(5));
select CAST('\13' AS bytea);
select CAST('\x13' AS varbinary(5));
select CAST('\x13' AS bytea);
select CAST('\\' AS varbinary(5));
select CAST('\\' AS bytea);
select CAST('\' AS varbinary);
select CAST('\' AS bytea);

-- test NULL pad extra space for binary type, not for varbinary and image
select CAST('\\' AS binary(3));
select CAST('\\' AS varbinary(3));
select CAST('\\' AS image);

-- [BABEL-254] test integer input is allowed for varbinary
select cast(16 as varbinary(4));
select cast(16*16 as varbinary(4));
select cast(16*16*16 as varbinary(4));
select cast(511 as varbinary(4));
-- test truncation to the left if the number input is too large
select cast(16*16*16*16 as varbinary(2));
-- test same behavior on table insert
drop table testing6;
create table testing6 (col varbinary(2));
insert into testing6 values (16);
insert into testing6 values (16*16);
insert into testing6 values (16*16*16);
insert into testing6 values (16*16*16*16);
select * from testing6;

-- test int2, int4, int8 to varbinary
select cast(16*CAST(16 AS int2) as varbinary(2));
select cast(16*CAST(16 AS int4) as varbinary(4));
select cast(16*CAST(16 AS int8) as varbinary(8));

-- test truncation to the left if maxlen is shorter than the input
select cast(CAST(16 AS int2) as varbinary(1));
select cast(CAST(16 AS int2) as varbinary(2));
-- test varbinary will only use 2 bytes (the size of the input) rather
-- than maxlen
select cast(CAST(16 AS int2) as varbinary(3));
select cast(CAST(16 AS int2) as varbinary(4));
select cast(CAST(16 AS int2) as varbinary(8));

select cast(CAST(16 AS int4) as varbinary(1));
select cast(CAST(16 AS int4) as varbinary(2));
select cast(CAST(16 AS int4) as varbinary(3));
select cast(CAST(16 AS int4) as varbinary(4));
select cast(CAST(16 AS int4) as varbinary(8));

select cast(CAST(16 AS int8) as varbinary(1));
select cast(CAST(16 AS int8) as varbinary(2));
select cast(CAST(16 AS int8) as varbinary(3));
select cast(CAST(16 AS int8) as varbinary(4));
select cast(CAST(16 AS int8) as varbinary(8));

-- [BABEL-254] test integer iput is allowed for binary
select cast(16 as binary(2));
select cast(16*16 as binary(2));
select cast(16*16*16 as binary(2));
-- test truncation to the left if the number input is too large
select cast(16*16*16*16 as binary(2));
-- test same behavior on table insert
drop table testing6;
create table testing6 (col binary(2));
insert into testing6 values (16);
insert into testing6 values (16*16);
insert into testing6 values (16*16*16);
insert into testing6 values (16*16*16*16);
select * from testing6;

-- test int2, int4, int8 to binary
select cast(16*CAST(16 AS int2) as binary(2));
select cast(16*CAST(16 AS int4) as binary(4));
select cast(16*CAST(16 AS int8) as binary(8));

-- test truncation to the left if maxlen is shorter than the input
select cast(CAST(16 AS int2) as binary(1));
select cast(CAST(16 AS int2) as binary(2));
select cast(CAST(16 AS int2) as binary(3));
-- test 0 padding to the left if maxlen is longer than the input
select cast(CAST(16 AS int2) as binary(4));
select cast(CAST(16 AS int2) as binary(8));

select cast(CAST(16 AS int4) as binary(1));
select cast(CAST(16 AS int4) as binary(2));
select cast(CAST(16 AS int4) as binary(3));
select cast(CAST(16 AS int4) as binary(4));
-- test 0 padding to the left if maxlen is longer than the input
select cast(CAST(16 AS int4) as binary(8));

select cast(CAST(16 AS int8) as binary(1));
select cast(CAST(16 AS int8) as binary(2));
select cast(CAST(16 AS int8) as binary(3));
select cast(CAST(16 AS int8) as binary(4));
select cast(CAST(16 AS int8) as binary(8));
-- test 0 padding to the left if maxlen is longer than the input
select cast(CAST(16 AS int8) as binary(10));

-- test casting varbinary to int4
CREATE PROCEDURE cast_varbinary(@val int) AS
BEGIN
  DECLARE @BinaryVariable varbinary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;

call cast_varbinary(16);
call cast_varbinary(16*16);
call cast_varbinary(511);
drop procedure cast_varbinary;

-- test casting varbinary to int4 when the varbinary size is longer than 4
CREATE PROCEDURE cast_varbinary(@val int) AS
BEGIN
  DECLARE @BinaryVariable varbinary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;

call cast_varbinary(16);
call cast_varbinary(16*16);
drop procedure cast_varbinary;

-- test truncation varbinary to int4
CREATE PROCEDURE cast_varbinary(@val int) AS
BEGIN
  DECLARE @BinaryVariable varbinary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;

call cast_varbinary(16);
call cast_varbinary(16*16);
drop procedure cast_varbinary;

-- test casting varbinary to int2
CREATE PROCEDURE cast_varbinary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable varbinary(2) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;

call cast_varbinary(CAST(16 AS int2));
call cast_varbinary(CAST(256 AS int2));
drop procedure cast_varbinary;

-- test truncation varbinary to int2
CREATE PROCEDURE cast_varbinary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable varbinary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;

call cast_varbinary(CAST(16 AS int2));
call cast_varbinary(CAST(256 AS int2));
drop procedure cast_varbinary;

-- test casting varbinary to int8
CREATE PROCEDURE cast_varbinary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable varbinary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;

call cast_varbinary(CAST(16 AS int8));
call cast_varbinary(16*CAST(16 AS int8));
drop procedure cast_varbinary;

-- test truncation varbinary to int8
CREATE PROCEDURE cast_varbinary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable varbinary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;

call cast_varbinary(CAST(16 AS int8));
call cast_varbinary(16*CAST(16 AS int8));
drop procedure cast_varbinary;

-- test casting binary to int4
CREATE PROCEDURE cast_binary(@val int) AS
BEGIN
  DECLARE @BinaryVariable binary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;

call cast_binary(16);
call cast_binary(256);
drop procedure cast_binary;

-- test casting binary to int4 when the binary size is greater than 4
CREATE PROCEDURE cast_binary(@val int) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;

call cast_binary(16);
call cast_binary(256);
drop procedure cast_binary;

-- test truncation binary to int4
CREATE PROCEDURE cast_binary(@val int) AS
BEGIN
  DECLARE @BinaryVariable binary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int)
END;

call cast_binary(16);
call cast_binary(256);
drop procedure cast_binary;

-- test casting binary to int2
CREATE PROCEDURE cast_binary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable binary(2) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;

call cast_binary(CAST(16 AS int2));
call cast_binary(CAST(256 AS int2));
drop procedure cast_binary;

-- test casting binary to int2 when the binary size is greater than 2
CREATE PROCEDURE cast_binary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;

call cast_binary(CAST(16 AS int2));
call cast_binary(CAST(256 AS int2));
drop procedure cast_binary;

-- test truncation binary to int2
CREATE PROCEDURE cast_binary(@val int2) AS
BEGIN
  DECLARE @BinaryVariable binary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int2)
END;

call cast_binary(CAST(16 AS int2));
call cast_binary(CAST(256 AS int2));
drop procedure cast_binary;

-- test casting binary to int8
CREATE PROCEDURE cast_binary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;

call cast_binary(CAST(16 AS int8));
call cast_binary(CAST(256 AS int8));
drop procedure cast_binary;

-- test casting binary to int8 when the binary size is greater than 8
CREATE PROCEDURE cast_binary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable binary(12) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;

call cast_binary(CAST(16 AS int8));
call cast_binary(CAST(256 AS int8));
drop procedure cast_binary;

-- test truncation binary to int8
CREATE PROCEDURE cast_binary(@val int8) AS
BEGIN
  DECLARE @BinaryVariable binary(1) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as int8)
END;

call cast_binary(CAST(16 AS int8));
call cast_binary(CAST(256 AS int8));
drop procedure cast_binary;

-- test real to varbinary
select cast(CAST(0.125 AS real) as varbinary(4));
drop table testing6;
create table testing6 (col varbinary(4));
insert into testing6 values (CAST(0.125 AS real));
insert into testing6 values (CAST(3.125 AS real));
select * from testing6;

-- test truncation rule when input is too long/varbinary length is too short
select cast(CAST(0.125 AS real) as varbinary(2));
select cast(CAST(0.125 AS real) as varbinary(4));

-- test casting varbinary back to real
CREATE PROCEDURE cast_varbinary(@val real) AS
BEGIN
  DECLARE @BinaryVariable varbinary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as real)
END;
call cast_varbinary(0.125);
call cast_varbinary(3.125);
drop procedure cast_varbinary;

-- test dobule precision to varbinary
select cast(CAST(0.123456789 AS double precision) as varbinary(8));
drop table testing6;
create table testing6 (col varbinary(8));
insert into testing6 values (CAST(0.123456789 AS double precision));
insert into testing6 values (CAST(3.123456789 AS double precision));
select * from testing6;

-- test truncation rule when input is too long/varbinary length is too short
select cast(CAST(0.123456789 AS double precision) as varbinary(2));
select cast(CAST(0.123456789 AS double precision) as varbinary(8));

-- test casting varbinary back to double precision
CREATE PROCEDURE cast_varbinary(@val double precision) AS
BEGIN
  DECLARE @BinaryVariable varbinary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as double precision)
END;
call cast_varbinary(0.123456789);
call cast_varbinary(3.123456789);
drop procedure cast_varbinary;

-- test real to binary
select cast(CAST(0.125 AS real) as binary(4));
drop table testing6;
create table testing6 (col binary(4));
insert into testing6 values (CAST(0.125 AS real));
insert into testing6 values (CAST(3.125 AS real));
select * from testing6;

-- test truncation rule when input is too long/binary length is too short
select cast(CAST(0.125 AS real) as binary(2));
select cast(CAST(0.125 AS real) as binary(4));

-- test casting binary back to real
CREATE PROCEDURE cast_binary(@val real) AS
BEGIN
  DECLARE @BinaryVariable binary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as real)
END;
call cast_binary(0.125);
call cast_binary(3.125);
drop procedure cast_binary;

-- test dobule precision to binary
select cast(CAST(0.123456789 AS double precision) as binary(8));
drop table testing6;
create table testing6 (col binary(8));
insert into testing6 values (CAST(0.123456789 AS double precision));
insert into testing6 values (CAST(3.123456789 AS double precision));
select * from testing6;

-- test truncation rule when input is too long/binary length is too short
select cast(CAST(0.123456789 AS double precision) as binary(2));
select cast(CAST(0.123456789 AS double precision) as binary(8));

-- test casting binary back to double precision
CREATE PROCEDURE cast_binary(@val double precision) AS
BEGIN
  DECLARE @BinaryVariable binary(8) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as double precision)
END;
call cast_binary(0.123456789);
call cast_binary(3.123456789);
drop procedure cast_binary;

-- sys.sysname
select CAST('£' AS sysname);             -- allowed
select CAST(NULL AS sysname);            -- not allowed

-- sys.sysname is working in both dialects
select CAST('£' AS sys.sysname);         -- allowed
select CAST(NULL AS sys.sysname);        -- not allowed
reset babelfishpg_tsql.sql_dialect;
select CAST('£' AS sys.sysname);         -- allowed
select CAST(NULL AS sys.sysname);        -- not allowed

set babelfishpg_tsql.sql_dialect = 'tsql';
create table test_sysname (col sys.sysname);
insert into test_sysname values (repeat('£', 128));  -- allowed
insert into test_sysname values (repeat('😀', 128)); -- not allowed due to UTF check
reset babelfishpg_tsql.sql_dialect;
insert into test_sysname values (repeat('😀', 128)); -- not allowed due to UTF check

set babelfishpg_tsql.sql_dialect = 'tsql';

-- clean up
drop table testing1;
drop table testing2;
drop table testing3;
drop table testing4;
drop table testing5;
drop table testing6;
drop table test_sysname;
reset babelfishpg_tsql.sql_dialect;
