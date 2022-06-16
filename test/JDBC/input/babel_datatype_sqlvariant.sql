drop table if exists t1;
go

-- Test CAST to SQL_VARIANT
create sequence t1_sec start with 1;
go
create table t1 (id int default nextval('t1_sec'), a sql_variant);
go

-- datetime2
insert into t1 (a) values ( cast('2020-10-05 09:00:00' as datetime2) );
go
-- datetime
insert into t1 (a) values ( cast('2020-10-05 09:00:00' as datetime) );
go
-- datetimeoffset
insert into t1 (a) values ( cast('2020-10-05 09:00:00.123456-9:00' as datetimeoffset) );
go
insert into t1 (a) values ( cast('2020-10-05 09:00:00.123456-9:00' as datetimeoffset(3)) );
go
-- exceeding range error
insert into t1 (a) values ( cast('10000-10-05 09:00:00.123456-9:00' as datetimeoffset(3)) );
go
-- smalldatetime
-- exceeding range error
insert into t1 (a) values ( cast('2079-10-05 09:00:00' as smalldatetime) );
go
insert into t1 (a) values ( cast('2020-10-05 09:00:00' as smalldatetime) );
go
-- date
insert into t1 (a) values ( cast('0001-01-01' as date) );
go
insert into t1 (a) values ( cast('9999-12-31' as date) );
go
-- time
insert into t1 (a) values ( cast('00:00:00' as time) );
go
insert into t1 (a) values ( cast('23:59:59' as time) );
go
-- float
-- float4
insert into t1 (a) values ( cast(3.1415926 as float(24)) );
go
-- float8
insert into t1 (a) values ( cast(3.1415926 as float(53)) );
go
-- real
insert into t1 (a) values ( cast(3.1415926 as real) );
go
-- numeric
insert into t1 (a) values ( cast(3.1415926 as numeric(4,3)) );
go
insert into t1 (a) values ( cast(3.1415926 as numeric(4,2)) );
go
-- money
insert into t1 (a) values ( cast($100.123 as money) );
go
insert into t1 (a) values ( cast('100.123' as money) );
go
-- smallmoney
insert into t1 (a) values ( cast($100.123 as smallmoney) );
go
insert into t1 (a) values ( cast('100.123' as smallmoney) );
go
-- bigint
insert into t1 (a) values ( cast(2147483648 as bigint) );
go
-- int
-- exceeding range error
insert into t1 (a) values ( cast(2147483648 as int) );
go
insert into t1 (a) values ( cast(2147483647 as int) );
go
-- smallint
-- exceeding range error
insert into t1 (a) values ( cast(32768 as smallint) );
go
insert into t1 (a) values ( cast(32767 as smallint) );
go
-- tinyint
-- exceeding range error
insert into t1 (a) values ( cast(256 as tinyint) );
go
insert into t1 (a) values ( cast(255 as tinyint) );
go
-- bit
insert into t1 (a) values ( cast(1.5 as bit) );
go
insert into t1 (a) values ( cast(0 as bit) );
go
insert into t1 (a) values ( cast(NULL as bit) );
go
-- nvarchar
insert into t1 (a) values ( cast('£' as nvarchar(1)) );
go
-- varchar
insert into t1 (a) values ( cast('£' as varchar(1)) );
go
-- nchar
insert into t1 (a) values ( cast('£' as nchar(1)) );
go
-- char
insert into t1 (a) values ( cast('£' as char(1)) );
go
-- varbinary
insert into t1 (a) values ( cast('abc' as varbinary(3)) );
go
-- binary
insert into t1 (a) values ( cast('abc' as binary(3)) );
go
-- uniqueidentifier
insert into t1 (a) values ( cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0' as uniqueidentifier) );
go
insert into t1 (a) values ( cast('0e984725-c51c-4bf4-9960-e1c80e27aba0' as uniqueidentifier) );
go
-- truncation succeed
insert into t1 (a) values ( cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0wrong' as uniqueidentifier) );
go

-- DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select a from t1 order by id;
go

-- Test CAST from SQL_VARIANT
-- datetime2
select cast(cast(cast('2020-10-20 09:00:00' as datetime2) as sql_variant) as datetime2);
go
-- datetimeoffset
select cast(cast(cast('2020-10-05 09:00:00-9:00' as datetimeoffset) as sql_variant) as datetimeoffset);
go
-- datetime
select cast(cast(cast('2020-10-20 09:00:00' as datetime) as sql_variant) as datetime);
go
-- smalldatetime
select cast(cast(cast('2020-10-20 09:00:00' as smalldatetime) as sql_variant) as smalldatetime);
go
-- date
select cast(cast(cast('2020-10-20' as date) as sql_variant) as date);
go
-- time
select cast(cast(cast('09:00:00' as time) as sql_variant) as time);
go
-- float
select cast(cast(cast(3.1415926 as float) as sql_variant) as float);
go
-- real
select cast(cast(cast(3.1415926 as real) as sql_variant) as real);
go
-- numeric
select cast(cast(cast(3.1415926 as numeric(4, 3)) as sql_variant) as numeric(4, 3));
go
select cast(cast(cast(3.1415926 as numeric(4, 3)) as sql_variant) as numeric(4, 2));
go
-- money
select cast(cast(cast('$123.123' as money) as sql_variant) as money);
go
-- smallmoney
select cast(cast(cast('$123.123' as smallmoney) as sql_variant) as smallmoney);
go
-- bigint
select cast(cast(cast(2147483648 as bigint) as sql_variant) as bigint);
go
-- int
select cast(cast(cast(32768 as int) as sql_variant) as int);
go
-- smallint
select cast(cast(cast(256 as smallint) as sql_variant) as smallint);
go
-- tinyint
select cast(cast(cast(255 as tinyint) as sql_variant) as tinyint);
go
-- bit
select cast(cast(cast(1.5 as bit) as sql_variant) as bit);
go
select cast(cast(cast(0 as bit) as sql_variant) as bit);
go
select cast(cast(cast(NULL as bit) as sql_variant) as bit);
go
-- nvarchar
select cast(cast(cast('£' as nvarchar(1)) as sql_variant) as nvarchar(1));
go
-- varchar
select cast(cast(cast('£' as varchar(1)) as sql_variant) as varchar(1));
go
-- nchar
select cast(cast(cast('£' as nchar(1)) as sql_variant) as nchar(1));
go
-- char
select cast(cast(cast('£' as char(1)) as sql_variant) as char(1));
go
-- varbinary
select cast(cast(cast('abc' as varbinary(3)) as sql_variant) as varbinary(3));
go
-- binary
select cast(cast(cast('abc' as binary(3)) as sql_variant) as binary(3));
go
-- uniqueidentifier
select cast(cast(cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0' as uniqueidentifier) 
                 as sql_variant) as uniqueidentifier);
go

select cast(cast(cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0wrong' as uniqueidentifier) 
                 as sql_variant) as uniqueidentifier);
go

-- CAST examples already supported
-- datetime to date
select cast(cast(cast('2020-10-20 09:00:00' as datetime) as sql_variant) as date);
go
-- date to datetime2
select cast(cast(cast('2020-10-20' as date) as sql_variant) as datetime2);
go
-- datetimeoffset 2 datetime2
select cast(cast(cast('2020-10-05 09:00:00-9:00' as datetimeoffset) as sql_variant) as datetime2);
go
-- datetime2 2 datetimeoffset
select cast(cast(cast('2020-10-20 09:00:00' as datetime2) as sql_variant) as datetimeoffset);
go
-- float to numeric
select cast(cast(cast(3.1415926 as float) as sql_variant) as numeric(4, 3));
go
-- float to money
select cast(cast(cast(3.1415926 as float) as sql_variant) as money);
go
-- float to int
select cast(cast(cast(3.1415926 as float) as sql_variant) as int);
go
-- money to int
select cast(cast(cast('$123.123' as money) as sql_variant) as int);
go
-- int to varbinary
select cast(cast(cast(123 as int) as sql_variant) as varbinary(4));
go
-- varchar to varbinary
select cast(cast(cast('abc' as varchar(3)) as sql_variant) as varbinary(3));
go
-- varbinary to int
select cast(cast(cast('abc' as varbinary(3)) as sql_variant) as int);
go
-- varbinary to varchar
select cast(cast(cast('abc' as varbinary(3)) as sql_variant) as varchar(3));
go

-- CAST examples not supported yet
-- datetime to float
select cast(cast(cast('2020-10-20 09:00:00' as datetime) as sql_variant) as float);
go
-- time to datetime
select cast(cast(cast('09:00:00' as time) as sql_variant) as datetime);
go
-- float to datetime
select cast(cast(cast(3.1415926 as float) as sql_variant) as datetime);
go
-- int to datetime2
select cast(cast(cast(123 as int) as sql_variant) as datetime2);
go
-- numeric to varbinary
select cast(cast(cast(3.1415926 as numeric(4, 3)) as sql_variant) as varbinary(6));
go
-- money to bigint
select cast(cast(cast('$123.123' as money) as sql_variant) as bigint);
go
-- money to bit
select cast(cast(cast('$123.123' as money) as sql_variant) as bit);
go
-- bigint to money
select cast(cast(cast(12345 as bigint) as sql_variant) as money);
go
-- bit to float
select cast(cast(cast(1.5 as bit) as sql_variant) as float);
go
-- varbinary to money
select cast(cast(cast('abc' as varbinary(3)) as sql_variant) as money);
go
-- uniqueidentifier to varbinary
select cast(cast(cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0' as uniqueidentifier)
                 as sql_variant) as varbinary(36));
go

-- Test DATALENGTH for SQL_VARIANT TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select datalength(a), a from t1;
go

-- SQL_VARAINT_PROPERTY function
CREATE SEQUENCE t2_sec start with 1 increment by 1;
go
create table t2 (id int default nextval('t2_sec'), testcase varchar(50), v sql_variant);
go
insert into t2 (testcase, v) values ('datetime2 basic', cast('2020-10-05 09:00:00' as datetime2));
go
-- no such property
select sql_variant_property(v, 'nothing') from t2;
go

-- type-wise property check
insert into t2 (testcase, v) values ('datetime2 w/ typmode', cast('2020-10-05 09:00:00' as datetime2(3)));
go
insert into t2 (testcase, v) values ('datetime basic', cast('2020-10-05 09:00:00' as datetime));
go
insert into t2 (testcase, v) values ('datetimeoffset', cast('2020-10-05 09:00:00.123456+8:00' as datetimeoffset));
go
insert into t2 (testcase, v) values ('datetimeoffset w/ typmod', cast('2020-10-05 09:00:00.123456+8:00' as datetimeoffset(3)));
go
insert into t2 (testcase, v) values ('smalldatetime basic', cast('2020-10-05 09:00:00' as smalldatetime));
go
insert into t2 (testcase, v) values ('date basic', cast('0001-01-01' as date));
go
insert into t2 (testcase, v) values ('time basic', cast('00:00:00' as time));
go
insert into t2 (testcase, v) values ('time basic w/ typmod', cast('00:00:00' as time(3)));
go
-- float8
insert into t2 (testcase, v) values ('float basic', cast(3.1415926 as float(53)));
go
insert into t2 (testcase, v) values ('real basic', cast(3.1415926 as real));
go
insert into t2 (testcase, v) values ('numeric basic', cast(93.1415926 as numeric(4,2)));
go
insert into t2 (testcase, v) values ('numeric basic2', cast(93.1415926 as numeric(5,1)));
go
insert into t2 (testcase, v) values ('money basic', cast('100.123' as money));
go
insert into t2 (testcase, v) values ('smallmoney basic', cast('100.123' as smallmoney));
go
insert into t2 (testcase, v) values ('bigint basic', cast(2147483648 as bigint));
go
insert into t2 (testcase, v) values ('int basic', cast(2147483647 as int));
go
insert into t2 (testcase, v) values ('smallint basic', cast(32767 as smallint));
go
insert into t2 (testcase, v) values ('tinyint basic', cast(255 as tinyint));
go
insert into t2 (testcase, v) values ('bit basic', cast(0 as bit));
go
insert into t2 (testcase, v) values ('nvarchar basic', cast('£' as nvarchar(1)));
go
insert into t2 (testcase, v) values ('varchar basic', cast('£' as varchar(1)));
go
insert into t2 (testcase, v) values ('nchar basic', cast('£' as nchar(1)));
go
insert into t2 (testcase, v) values ('char basic', cast('£' as char(1)));
go
insert into t2 (testcase, v) values ('varbinary basic', cast('abc' as varbinary(3)));
go
insert into t2 (testcase, v) values ('binary basic', cast('abc' as binary(3)));
go
insert into t2 (testcase, v) values ('uniqueidentifier basic', cast('0e984725-c51c-4bf4-9960-e1c80e27aba0' as uniqueidentifier));
go

-- TODO fix crash
-- select id, testcase, 
--        sql_variant_property(v, 'basetype') as 'basetype',
--        sql_variant_property(v, 'precision') as 'precision',
--        sql_variant_property(v, 'scale') as 'scale',
--        sql_variant_property(v, 'collation') as 'collation',
--        sql_variant_property(v, 'totalbytes') as 'totalbytes',
--        sql_variant_property(v, 'maxlength') as 'maxlength' from t2 order by id;
-- go

-- test null value
CREATE table t3 ( a sql_variant);
go
insert into t3 values (null);
go

select sql_variant_property(a, 'basetype') as 'basetype',
       sql_variant_property(a, 'precision') as 'precision',
       sql_variant_property(a, 'scale') as 'scale',
       sql_variant_property(a, 'collation') as 'collation',
       sql_variant_property(a, 'totalbytes') as 'totalbytes',
       sql_variant_property(a, 'maxlength') as 'maxlength' from t3;
go

-- Comparision functions
CREATE SEQUENCE t4_sec START WITH 1;
go
create table t4 (id int default nextval('t4_sec'), a sql_variant, b sql_variant);
go

-- datetime2
insert into t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime2), cast('2020-10-05 09:00:00' as datetime2));
go
insert into t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime2), cast('2020-10-05 06:00:00' as datetime2));
go
insert into t4 (a , b) values (cast('2020-10-05 06:00:00' as datetime2), cast('2020-10-05 09:00:00' as datetime2));
go
-- datetime
insert into t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime), cast('2020-10-05 09:00:00' as datetime));
go
insert into t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime), cast('2020-10-05 01:00:00' as datetime));
go
insert into t4 (a , b) values (cast('2020-10-05 01:00:00' as datetime), cast('2020-10-05 09:00:00' as datetime));
go
-- datetimeoffset
insert into t4 (a , b) values (cast('2020-10-05 09:00:00-8:00' as datetimeoffset), cast('2020-10-05 09:00:00-8:00' as datetimeoffset));
go
insert into t4 (a , b) values (cast('2020-10-05 09:00:00-8:00' as datetimeoffset), cast('2020-10-05 06:00:00-8:00' as datetimeoffset));
go
insert into t4 (a , b) values (cast('2020-10-05 06:00:00-8:00' as datetimeoffset), cast('2020-10-05 09:00:00-8:00' as datetimeoffset));
go
-- smalldatetime
insert into t4 (a , b) values (cast('2020-10-05 09:00:00' as smalldatetime), cast('2020-10-05 09:00:00' as smalldatetime));
go
insert into t4 (a , b) values (cast('2020-10-05 09:00:00' as smalldatetime), cast('2020-10-05 03:00:00' as smalldatetime));
go
insert into t4 (a , b) values (cast('2020-10-05 03:00:00' as smalldatetime), cast('2020-10-05 09:00:00' as smalldatetime));
go
-- date
insert into t4 (a , b) values (cast('0001-01-01' as date), cast('0001-01-01' as date));
go
insert into t4 (a , b) values (cast('9999-12-31' as date), cast('0001-01-01' as date));
go
insert into t4 (a , b) values (cast('0001-01-01' as date), cast('9999-12-31' as date));
go
-- time
insert into t4 (a , b) values (cast('00:00:00' as time), cast('00:00:00' as time));
go
insert into t4 (a , b) values (cast('23:59:59' as time), cast('00:00:00' as time));
go
insert into t4 (a , b) values (cast('00:00:00' as time), cast('23:59:59' as time));
go
-- float
insert into t4 (a , b) values (cast(3.1415926 as float(53)), cast(3.1415926 as float(53)));
go
insert into t4 (a , b) values (cast(3.1415926 as float(53)), cast(3.1415921 as float(53)));
go
insert into t4 (a , b) values (cast(3.1415921 as float(53)), cast(3.1415926 as float(53)));
go
-- real
insert into t4 (a , b) values (cast(3.141 as real), cast(3.141 as real));
go
insert into t4 (a , b) values (cast(3.141 as real), cast(2.141 as real));
go
insert into t4 (a , b) values (cast(2.141 as real), cast(3.141 as real));
go
-- numeric
insert into t4 (a , b) values (cast(3.141 as numeric(4,3)), cast(3.141 as numeric(4,3)));
go
insert into t4 (a , b) values (cast(3.141 as numeric(4,3)), cast(3.142 as numeric(4,3)));
go
insert into t4 (a , b) values (cast(3.142 as numeric(4,3)), cast(3.141 as numeric(4,3)));
go
-- money
insert into t4 (a , b) values (cast('$100.123' as money), cast('$100.123' as money));
go
insert into t4 (a , b) values (cast('$100.123' as money), cast('$100.121' as money));
go
insert into t4 (a , b) values (cast('$100.121' as money), cast('$100.123' as money));
go
-- smallmoney
insert into t4 (a , b) values (cast('$100.123' as smallmoney), cast('$100.123' as smallmoney));
go
insert into t4 (a , b) values (cast('$100.123' as smallmoney), cast('$100.121' as smallmoney));
go
insert into t4 (a , b) values (cast('$100.121' as smallmoney), cast('$100.123' as smallmoney));
go
-- bigint
insert into t4 (a , b) values (cast(2147483648 as bigint), cast(2147483648 as bigint));
go
insert into t4 (a , b) values (cast(2147483648 as bigint), cast(2147483641 as bigint));
go
insert into t4 (a , b) values (cast(2147483641 as bigint), cast(2147483648 as bigint));
go
-- int
insert into t4 (a , b) values (cast(2147483647 as int), cast(2147483647 as int));
go
insert into t4 (a , b) values (cast(2147483647 as int), cast(2147483641 as int));
go
insert into t4 (a , b) values (cast(2147483641 as int), cast(2147483647 as int));
go
-- smallint
insert into t4 (a , b) values (cast(32767 as smallint), cast(32767 as smallint));
go
insert into t4 (a , b) values (cast(32767 as smallint), cast(32761 as smallint));
go
insert into t4 (a , b) values (cast(32761 as smallint), cast(32767 as smallint));
go
-- tinyint
insert into t4 (a , b) values (cast(255 as tinyint), cast(255 as tinyint));
go
insert into t4 (a , b) values (cast(255 as tinyint), cast(251 as tinyint));
go
insert into t4 (a , b) values (cast(251 as tinyint), cast(255 as tinyint));
go
-- bit
--insert into t4 (a , b) values (0::bit, 0::bit);
go
--insert into t4 (a , b) values (1::bit, 0::bit);
go
--insert into t4 (a , b) values (1::bit, 1::bit);
go
-- nvarchar 
insert into t4 (a , b) values (cast('nvarchar' as nvarchar(10)), cast('nvarchar' as nvarchar(10)));
go
insert into t4 (a , b) values (cast('nvarchar' as nvarchar(10)), cast('nvarchar1' as nvarchar(10)));
go
insert into t4 (a , b) values (cast('nvarchar1' as nvarchar(10)), cast('nvarchar' as nvarchar(10)));
go
-- varchar 
insert into t4 (a , b) values (cast('varchar' as varchar(10)), cast('varchar' as varchar(10)));
go
insert into t4 (a , b) values (cast('varchar' as varchar(10)), cast('varchar1' as varchar(10)));
go
insert into t4 (a , b) values (cast('varchar1' as varchar(10)), cast('varchar' as varchar(10)));
go
-- varbinary 
--insert into t4 (a , b) values ('varbinary'::varbinary(10), 'varbinary'::varbinary(10));
go
--insert into t4 (a , b) values ('varbinary'::varbinary(10), 'varbinary1'::varbinary(10));
go
--insert into t4 (a , b) values ('varbinary1'::varbinary(10), 'varbinary'::varbinary(10));
go
-- binary 
--insert into t4 (a , b) values ('binary'::binary(10), 'binary'::binary(10));
go
--insert into t4 (a , b) values ('binary'::binary(10), 'binary1'::binary(10));
go
--insert into t4 (a , b) values ('binary1'::binary(10), 'binary'::binary(10));
go

-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from t4 where a = b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from t4 where a <> b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from t4 where a > b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from t4 where a < b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from t4 where a >= b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from t4 where a <= b order by id;
go

-- comparison between different types
truncate table t4;
go
insert into t4 ( a, b) values (cast(1234 as int), cast('5678' as varchar(10)));
go
insert into t4 ( a, b) values (cast(1234 as int), cast('2020-10-05 09:00:00' as datetime2));
go
select * from t4 where a = b order by id;
go
select * from t4 where a <> b order by id;
go
select * from t4 where a > b order by id;
go
select * from t4 where a < b order by id;
go
select * from t4 where a >= b order by id;
go
select * from t4 where a <= b order by id;
go

-- Index 
create table t5 (a sql_variant, b sql_variant);
go
create index t5_idx1 on t5 (a);
go
create index t5_idx2 on t5 (b);
go
-- datetime2
insert into t5 (a , b) values (cast('2020-10-05 09:00:00' as datetime2), cast('2020-10-05 09:00:00' as datetime2));
go
-- datetime
insert into t5 (a , b) values (cast('2021-10-05 09:00:00' as datetime), cast('2021-10-05 09:00:00' as datetime));
go
-- datetimeoffset
insert into t5 (a , b) values (cast('2020-10-05 09:00:00-8:00' as datetimeoffset), cast('2020-10-05 09:00:00-8:00' as datetimeoffset));
go
-- smalldatetime
insert into t5 (a , b) values (cast('2022-10-05 09:00:00' as smalldatetime), cast('2022-10-05 09:00:00' as smalldatetime));
go
-- date
insert into t5 (a , b) values (cast('1991-01-01' as date), cast('1991-01-01' as date));
go
-- time
insert into t5 (a , b) values (cast('23:59:59' as time), cast('23:59:59' as time));
go
-- float
insert into t5 (a , b) values (cast(3.1415926 as float(53)), cast(3.1415926 as float(53)));
go
-- real
insert into t5 (a , b) values (cast(3.141 as real), cast(3.141 as real));
go
-- numeric
insert into t5 (a , b) values (cast(3.142 as numeric(4,3)), cast(3.142 as numeric(4,3)));
go
-- money
insert into t5 (a , b) values (cast('$100.123' as money), cast('$100.123' as money));
go
-- smallmoney
insert into t5 (a , b) values (cast('$99.121' as smallmoney), cast('$99.121' as smallmoney));
go
-- bigint
insert into t5 (a , b) values (cast(2147483648 as bigint), cast(2147483648 as bigint));
go
-- int
insert into t5 (a , b) values (cast(2147483647 as int), cast(2147483647 as int));
go
-- smallint
insert into t5 (a , b) values (cast(32767 as smallint), cast(32767 as smallint));
go
-- tinyint
insert into t5 (a , b) values (cast(255 as tinyint), cast(255 as tinyint));
go
-- bit
insert into t5 (a , b) values (cast(1 as bit), cast(1 as bit));
go
-- nvarchar 
insert into t5 (a , b) values (cast('nvarchar' as nvarchar(10)), cast('nvarchar' as nvarchar(10)));
go
-- varchar 
insert into t5 (a , b) values (cast('varchar' as varchar(10)), cast('varchar' as varchar(10)));
go
-- uniqueidentifier
insert into t5 (a , b) values (cast('123e4567-e89b-12d3-a456-426614174000' as uniqueidentifier), cast('123e4567-e89b-12d3-a456-426614174000' as uniqueidentifier));
go

-- test sql_variant specific comparison rules
create table t7 (a sql_variant, b sql_variant);
go
insert into t7 values(cast('01-01-01 00:00:00' as datetime2), cast('23:59:59' as time));
go
insert into t7 values(cast('01-01-01 00:00:00' as datetime), cast('23:59:59' as time));
go
insert into t7 values(cast('01-01-01 00:00:00' as smalldatetime), cast('23:59:59' as time));
go
insert into t7 values(cast('01-01-01' as date), cast('23:59:59' as time));
go
select count(*) from t7 where a > b;
go

truncate table t7;
go
insert into t7 values (cast('$922337203685477.5807' as money), cast(922337203685478 as bigint));
go
insert into t7 values (cast(922337203685478 as bigint), cast('$922337203685477.5807' as money));
go
insert into t7 values (cast('-922337203685477.5807' as money), cast(-922337203685478 as bigint));
go
insert into t7 values (cast(-922337203685478 as bigint), cast('-922337203685477.5807' as money));
go
select * from t7 where a = b order by 1,2;
go
select * from t7 where a > b order by 1,2;
go
select * from t7 where a < b order by 1,2;
go
select * from t7 where a <> b order by 1,2;
go
select * from t7 where a >= b order by 1,2;
go
select * from t7 where a <= b order by 1,2;
go

truncate table t7;
go
insert into t7 values (cast('$200' as money), cast(200 as bigint));
go
insert into t7 values (cast('$200' as money), cast(100 as bigint));
go
insert into t7 values (cast('$200' as money), cast(300 as bigint));
go
select * from t7 where a = b order by 1,2;
go
select * from t7 where a > b order by 1,2;
go
select * from t7 where a < b order by 1,2;
go
select * from t7 where a <> b order by 1,2;
go
select * from t7 where a >= b order by 1,2;
go
select * from t7 where a <= b order by 1,2;
go

-- Clean up
drop table t1;
go
drop table t2;
go
drop table t3;
go
drop table t4;
go
drop table t5;
go
drop table t7;
go
drop sequence t1_sec;
go
drop sequence t2_sec;
go
drop sequence t4_sec;
go
