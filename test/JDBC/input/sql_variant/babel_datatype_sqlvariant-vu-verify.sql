-- DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select a from babel_datatype_sqlvariant_vu_prepare_t1 order by id;
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
select datalength(a), a from babel_datatype_sqlvariant_vu_prepare_t1;
go

-- no such property
select sql_variant_property(v, 'nothing') from babel_datatype_sqlvariant_vu_prepare_t2;
go

select sql_variant_property(a, 'basetype') as 'basetype',
       sql_variant_property(a, 'precision') as 'precision',
       sql_variant_property(a, 'scale') as 'scale',
       sql_variant_property(a, 'collation') as 'collation',
       sql_variant_property(a, 'totalbytes') as 'totalbytes',
       sql_variant_property(a, 'maxlength') as 'maxlength' from babel_datatype_sqlvariant_vu_prepare_t3;
go

-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from babel_datatype_sqlvariant_vu_prepare_t4 where a = b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from babel_datatype_sqlvariant_vu_prepare_t4 where a <> b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from babel_datatype_sqlvariant_vu_prepare_t4 where a > b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from babel_datatype_sqlvariant_vu_prepare_t4 where a < b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from babel_datatype_sqlvariant_vu_prepare_t4 where a >= b order by id;
go
-- TODO: DATETIMEOFFSETN error expected using JDBC - see https://github.com/microsoft/mssql-jdbc/issues/1670
select * from babel_datatype_sqlvariant_vu_prepare_t4 where a <= b order by id;
go

select * from babel_datatype_sqlvariant_vu_prepare_t5 where a = b order by id;
go
select * from babel_datatype_sqlvariant_vu_prepare_t5 where a <> b order by id;
go
select * from babel_datatype_sqlvariant_vu_prepare_t5 where a > b order by id;
go
select * from babel_datatype_sqlvariant_vu_prepare_t5 where a < b order by id;
go
select * from babel_datatype_sqlvariant_vu_prepare_t5 where a >= b order by id;
go
select * from babel_datatype_sqlvariant_vu_prepare_t5 where a <= b order by id;
go

select count(*) from babel_datatype_sqlvariant_vu_prepare_t7 where a > b;
go

select * from babel_datatype_sqlvariant_vu_prepare_t8 where a = b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t8 where a > b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t8 where a < b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t8 where a <> b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t8 where a >= b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t8 where a <= b order by 1,2;
go

select * from babel_datatype_sqlvariant_vu_prepare_t9 where a = b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t9 where a > b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t9 where a < b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t9 where a <> b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t9 where a >= b order by 1,2;
go
select * from babel_datatype_sqlvariant_vu_prepare_t9 where a <= b order by 1,2;
go

select * from babel_4036_t1 order by a;
go

select * from babel_4036_t2 order by a;
go
