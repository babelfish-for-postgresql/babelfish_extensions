drop table if exists babel_datatype_sqlvariant_vu_prepare_t1;
go

-- Test CAST to SQL_VARIANT
create sequence babel_datatype_sqlvariant_vu_prepare_t1_sec start with 1;
go
create table babel_datatype_sqlvariant_vu_prepare_t1 (id int default nextval('babel_datatype_sqlvariant_vu_prepare_t1_sec'), a sql_variant);
go

-- datetime2
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('2020-10-05 09:00:00' as datetime2) );
go
-- datetime
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('2020-10-05 09:00:00' as datetime) );
go
-- datetimeoffset
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('2020-10-05 09:00:00.123456-9:00' as datetimeoffset) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('2020-10-05 09:00:00.123456-9:00' as datetimeoffset(3)) );
go
-- exceeding range error
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('10000-10-05 09:00:00.123456-9:00' as datetimeoffset(3)) );
go
-- smalldatetime
-- exceeding range error
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('2079-10-05 09:00:00' as smalldatetime) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('2020-10-05 09:00:00' as smalldatetime) );
go
-- date
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('0001-01-01' as date) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('9999-12-31' as date) );
go
-- time
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('00:00:00' as time) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('23:59:59' as time) );
go
-- float
-- floababel_datatype_sqlvariant_vu_prepare_t4
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(3.1415926 as float(24)) );
go
-- float8
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(3.1415926 as float(53)) );
go
-- real
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(3.1415926 as real) );
go
-- numeric
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(3.1415926 as numeric(4,3)) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(3.1415926 as numeric(4,2)) );
go
-- money
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast($100.123 as money) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('100.123' as money) );
go
-- smallmoney
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast($100.123 as smallmoney) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('100.123' as smallmoney) );
go
-- bigint
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(2147483648 as bigint) );
go
-- int
-- exceeding range error
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(2147483648 as int) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(2147483647 as int) );
go
-- smallint
-- exceeding range error
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(32768 as smallint) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(32767 as smallint) );
go
-- tinyint
-- exceeding range error
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(256 as tinyint) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(255 as tinyint) );
go
-- bit
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(1.5 as bit) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(0 as bit) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast(NULL as bit) );
go
-- nvarchar
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('£' as nvarchar(1)) );
go
-- varchar
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('£' as varchar(1)) );
go
-- nchar
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('£' as nchar(1)) );
go
-- char
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('£' as char(1)) );
go
-- varbinary
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('abc' as varbinary(3)) );
go
-- binary
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('abc' as binary(3)) );
go
-- uniqueidentifier
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0' as uniqueidentifier) );
go
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('0e984725-c51c-4bf4-9960-e1c80e27aba0' as uniqueidentifier) );
go
-- truncation succeed
insert into babel_datatype_sqlvariant_vu_prepare_t1 (a) values ( cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0wrong' as uniqueidentifier) );
go

-- SQL_VARAINT_PROPERTY function
CREATE SEQUENCE babel_datatype_sqlvariant_vu_prepare_t2_sec start with 1 increment by 1;
go
create table babel_datatype_sqlvariant_vu_prepare_t2 (id int default nextval('babel_datatype_sqlvariant_vu_prepare_t2_sec'), testcase varchar(50), v sql_variant);
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('datetime2 basic', cast('2020-10-05 09:00:00' as datetime2));
go

-- type-wise property check
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('datetime2 w/ typmode', cast('2020-10-05 09:00:00' as datetime2(3)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('datetime basic', cast('2020-10-05 09:00:00' as datetime));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('datetimeoffset', cast('2020-10-05 09:00:00.123456+8:00' as datetimeoffset));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('datetimeoffset w/ typmod', cast('2020-10-05 09:00:00.123456+8:00' as datetimeoffset(3)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('smalldatetime basic', cast('2020-10-05 09:00:00' as smalldatetime));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('date basic', cast('0001-01-01' as date));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('time basic', cast('00:00:00' as time));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('time basic w/ typmod', cast('00:00:00' as time(3)));
go
-- float8
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('float basic', cast(3.1415926 as float(53)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('real basic', cast(3.1415926 as real));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('numeric basic', cast(93.1415926 as numeric(4,2)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('numeric basic2', cast(93.1415926 as numeric(5,1)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('money basic', cast('100.123' as money));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('smallmoney basic', cast('100.123' as smallmoney));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('bigint basic', cast(2147483648 as bigint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('int basic', cast(2147483647 as int));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('smallint basic', cast(32767 as smallint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('tinyint basic', cast(255 as tinyint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('bit basic', cast(0 as bit));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('nvarchar basic', cast('£' as nvarchar(1)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('varchar basic', cast('£' as varchar(1)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('nchar basic', cast('£' as nchar(1)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('char basic', cast('£' as char(1)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('varbinary basic', cast('abc' as varbinary(3)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('binary basic', cast('abc' as binary(3)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t2 (testcase, v) values ('uniqueidentifier basic', cast('0e984725-c51c-4bf4-9960-e1c80e27aba0' as uniqueidentifier));
go

-- test null value
CREATE table babel_datatype_sqlvariant_vu_prepare_t3 ( a sql_variant);
go
insert into babel_datatype_sqlvariant_vu_prepare_t3 values (null);
go


-- Comparision functions
CREATE SEQUENCE babel_datatype_sqlvariant_vu_prepare_t4_sec START WITH 1;
go
create table babel_datatype_sqlvariant_vu_prepare_t4 (id int default nextval('babel_datatype_sqlvariant_vu_prepare_t4_sec'), a sql_variant, b sql_variant);
go

-- datetime2
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime2), cast('2020-10-05 09:00:00' as datetime2));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime2), cast('2020-10-05 06:00:00' as datetime2));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 06:00:00' as datetime2), cast('2020-10-05 09:00:00' as datetime2));
go
-- datetime
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime), cast('2020-10-05 09:00:00' as datetime));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00' as datetime), cast('2020-10-05 01:00:00' as datetime));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 01:00:00' as datetime), cast('2020-10-05 09:00:00' as datetime));
go
-- datetimeoffset
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00-8:00' as datetimeoffset), cast('2020-10-05 09:00:00-8:00' as datetimeoffset));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00-8:00' as datetimeoffset), cast('2020-10-05 06:00:00-8:00' as datetimeoffset));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 06:00:00-8:00' as datetimeoffset), cast('2020-10-05 09:00:00-8:00' as datetimeoffset));
go
-- smalldatetime
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00' as smalldatetime), cast('2020-10-05 09:00:00' as smalldatetime));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 09:00:00' as smalldatetime), cast('2020-10-05 03:00:00' as smalldatetime));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('2020-10-05 03:00:00' as smalldatetime), cast('2020-10-05 09:00:00' as smalldatetime));
go
-- date
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('0001-01-01' as date), cast('0001-01-01' as date));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('9999-12-31' as date), cast('0001-01-01' as date));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('0001-01-01' as date), cast('9999-12-31' as date));
go
-- time
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('00:00:00' as time), cast('00:00:00' as time));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('23:59:59' as time), cast('00:00:00' as time));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('00:00:00' as time), cast('23:59:59' as time));
go
-- float
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.1415926 as float(53)), cast(3.1415926 as float(53)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.1415926 as float(53)), cast(3.1415921 as float(53)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.1415921 as float(53)), cast(3.1415926 as float(53)));
go
-- real
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.141 as real), cast(3.141 as real));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.141 as real), cast(2.141 as real));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(2.141 as real), cast(3.141 as real));
go
-- numeric
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.141 as numeric(4,3)), cast(3.141 as numeric(4,3)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.141 as numeric(4,3)), cast(3.142 as numeric(4,3)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(3.142 as numeric(4,3)), cast(3.141 as numeric(4,3)));
go
-- money
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('$100.123' as money), cast('$100.123' as money));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('$100.123' as money), cast('$100.121' as money));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('$100.121' as money), cast('$100.123' as money));
go
-- smallmoney
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('$100.123' as smallmoney), cast('$100.123' as smallmoney));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('$100.123' as smallmoney), cast('$100.121' as smallmoney));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('$100.121' as smallmoney), cast('$100.123' as smallmoney));
go
-- bigint
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(2147483648 as bigint), cast(2147483648 as bigint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(2147483648 as bigint), cast(2147483641 as bigint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(2147483641 as bigint), cast(2147483648 as bigint));
go
-- int
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(2147483647 as int), cast(2147483647 as int));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(2147483647 as int), cast(2147483641 as int));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(2147483641 as int), cast(2147483647 as int));
go
-- smallint
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(32767 as smallint), cast(32767 as smallint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(32767 as smallint), cast(32761 as smallint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(32761 as smallint), cast(32767 as smallint));
go
-- tinyint
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(255 as tinyint), cast(255 as tinyint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(255 as tinyint), cast(251 as tinyint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast(251 as tinyint), cast(255 as tinyint));
go
-- bit
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (0::bit, 0::bit);
go
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (1::bit, 0::bit);
go
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (1::bit, 1::bit);
go
-- nvarchar 
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('nvarchar' as nvarchar(10)), cast('nvarchar' as nvarchar(10)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('nvarchar' as nvarchar(10)), cast('nvarchar1' as nvarchar(10)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('nvarchar1' as nvarchar(10)), cast('nvarchar' as nvarchar(10)));
go
-- varchar 
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('varchar' as varchar(10)), cast('varchar' as varchar(10)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('varchar' as varchar(10)), cast('varchar1' as varchar(10)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values (cast('varchar1' as varchar(10)), cast('varchar' as varchar(10)));
go
-- varbinary 
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values ('varbinary'::varbinary(10), 'varbinary'::varbinary(10));
go
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values ('varbinary'::varbinary(10), 'varbinary1'::varbinary(10));
go
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values ('varbinary1'::varbinary(10), 'varbinary'::varbinary(10));
go
-- binary 
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values ('binary'::binary(10), 'binary'::binary(10));
go
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values ('binary'::binary(10), 'binary1'::binary(10));
go
--insert into babel_datatype_sqlvariant_vu_prepare_t4 (a , b) values ('binary1'::binary(10), 'binary'::binary(10));
go

-- comparison between different types
CREATE SEQUENCE babel_datatype_sqlvariant_vu_prepare_t5_sec START WITH 1;
go
create table babel_datatype_sqlvariant_vu_prepare_t5 (id int default nextval('babel_datatype_sqlvariant_vu_prepare_t5_sec'), a sql_variant, b sql_variant);
go

insert into babel_datatype_sqlvariant_vu_prepare_t5 ( a, b) values (cast(1234 as int), cast('5678' as varchar(10)));
go
insert into babel_datatype_sqlvariant_vu_prepare_t5 ( a, b) values (cast(1234 as int), cast('2020-10-05 09:00:00' as datetime2));
go

create table babel_datatype_sqlvariant_vu_prepare_t6 (a sql_variant, b sql_variant);
go
create index babel_datatype_sqlvariant_vu_prepare_t6_idx1 on babel_datatype_sqlvariant_vu_prepare_t5 (a);
go
create index babel_datatype_sqlvariant_vu_prepare_t6_idx2 on babel_datatype_sqlvariant_vu_prepare_t5 (b);
go
-- datetime2
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('2020-10-05 09:00:00' as datetime2), cast('2020-10-05 09:00:00' as datetime2));
go
-- datetime
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('2021-10-05 09:00:00' as datetime), cast('2021-10-05 09:00:00' as datetime));
go
-- datetimeoffset
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('2020-10-05 09:00:00-8:00' as datetimeoffset), cast('2020-10-05 09:00:00-8:00' as datetimeoffset));
go
-- smalldatetime
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('2022-10-05 09:00:00' as smalldatetime), cast('2022-10-05 09:00:00' as smalldatetime));
go
-- date
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('1991-01-01' as date), cast('1991-01-01' as date));
go
-- time
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('23:59:59' as time), cast('23:59:59' as time));
go
-- float
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(3.1415926 as float(53)), cast(3.1415926 as float(53)));
go
-- real
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(3.141 as real), cast(3.141 as real));
go
-- numeric
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(3.142 as numeric(4,3)), cast(3.142 as numeric(4,3)));
go
-- money
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('$100.123' as money), cast('$100.123' as money));
go
-- smallmoney
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('$99.121' as smallmoney), cast('$99.121' as smallmoney));
go
-- bigint
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(2147483648 as bigint), cast(2147483648 as bigint));
go
-- int
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(2147483647 as int), cast(2147483647 as int));
go
-- smallint
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(32767 as smallint), cast(32767 as smallint));
go
-- tinyint
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(255 as tinyint), cast(255 as tinyint));
go
-- bit
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast(1 as bit), cast(1 as bit));
go
-- nvarchar 
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('nvarchar' as nvarchar(10)), cast('nvarchar' as nvarchar(10)));
go
-- varchar 
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('varchar' as varchar(10)), cast('varchar' as varchar(10)));
go
-- uniqueidentifier
insert into babel_datatype_sqlvariant_vu_prepare_t6 (a , b) values (cast('123e4567-e89b-12d3-a456-426614174000' as uniqueidentifier), cast('123e4567-e89b-12d3-a456-426614174000' as uniqueidentifier));
go

-- test sql_variant specific comparison rules
create table babel_datatype_sqlvariant_vu_prepare_t7 (a sql_variant, b sql_variant);
go
insert into babel_datatype_sqlvariant_vu_prepare_t7 values(cast('01-01-01 00:00:00' as datetime2), cast('23:59:59' as time));
go
insert into babel_datatype_sqlvariant_vu_prepare_t7 values(cast('01-01-01 00:00:00' as datetime), cast('23:59:59' as time));
go
insert into babel_datatype_sqlvariant_vu_prepare_t7 values(cast('01-01-01 00:00:00' as smalldatetime), cast('23:59:59' as time));
go
insert into babel_datatype_sqlvariant_vu_prepare_t7 values(cast('01-01-01' as date), cast('23:59:59' as time));
go

create table babel_datatype_sqlvariant_vu_prepare_t8 (a sql_variant, b sql_variant);
go

insert into babel_datatype_sqlvariant_vu_prepare_t8 values (cast('$922337203685477.5807' as money), cast(922337203685478 as bigint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t8 values (cast(922337203685478 as bigint), cast('$922337203685477.5807' as money));
go
insert into babel_datatype_sqlvariant_vu_prepare_t8 values (cast('-922337203685477.5807' as money), cast(-922337203685478 as bigint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t8 values (cast(-922337203685478 as bigint), cast('-922337203685477.5807' as money));
go

create table babel_datatype_sqlvariant_vu_prepare_t9 (a sql_variant, b sql_variant);
go


insert into babel_datatype_sqlvariant_vu_prepare_t9 values (cast('$200' as money), cast(200 as bigint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t9 values (cast('$200' as money), cast(100 as bigint));
go
insert into babel_datatype_sqlvariant_vu_prepare_t9 values (cast('$200' as money), cast(300 as bigint));
go