-- Test cast from SQL_Variant with no pg_cast functions (implicit casting)
-- datetime2
select cast(cast(cast('2020-10-20 09:00:00' as varchar) as sql_variant) as datetime2);
go
select cast(cast(cast('2020-10-20 09:00:00' as datetime2) as sql_variant) as varchar);
go
-- datetime
select cast(cast(cast('2020-10-20 09:00:00' as varchar) as sql_variant) as datetime);
go
select cast(cast(cast('2020-10-20 09:00:00' as datetime) as sql_variant) as varchar);
go
-- smalldatetime
select cast(cast(cast('2020-10-20 09:00:00' as varchar) as sql_variant) as smalldatetime);
go
select cast(cast(cast('2020-10-20 09:00:00' as smalldatetime) as sql_variant) as varchar);
go
-- date
select cast(cast(cast('2020-10-20' as varchar) as sql_variant) as date);
go
select cast(cast(cast('2020-10-20' as date) as sql_variant) as varchar);
go
-- time
select cast(cast(cast('09:00:00' as varchar) as sql_variant) as time);
go
select cast(cast(cast('09:00:00' as time) as sql_variant) as varchar);
go
-- float
select cast(cast(cast('3.1415926' as varchar) as sql_variant) as float);
go
select cast(cast(cast('3.1415926' as float) as sql_variant) as varchar);
go
-- real
select cast(cast(cast('3.1415926' as varchar) as sql_variant) as real);
go
select cast(cast(cast('3.1415926' as real) as sql_variant) as varchar);
go
-- numeric
select cast(cast(cast('3.1415926' as varchar) as sql_variant) as numeric(4, 3));
go
select cast(cast(cast('3.1415926' as numeric(4, 3)) as sql_variant) as varchar);
go
-- money
select cast(cast(cast('$123.123' as varchar) as sql_variant) as money);
go
select cast(cast(cast('$123.123' as money) as sql_variant) as varchar);
go
-- smallmoney
select cast(cast(cast('$123.123' as varchar) as sql_variant) as smallmoney);
go
select cast(cast(cast('$123.123' as smallmoney) as sql_variant) as varchar);
go
-- bigint
select cast(cast(cast('2147483648' as varchar) as sql_variant) as bigint);
go
select cast(cast(cast('2147483648' as bigint) as sql_variant) as varchar);
go
-- int
select cast(cast(cast('32768' as varchar) as sql_variant) as int);
go
select cast(cast(cast('32768' as int) as sql_variant) as varchar);
go
-- smallint
select cast(cast(cast('256' as varchar) as sql_variant) as smallint);
go
select cast(cast(cast('256' as smallint) as sql_variant) as varchar);
go
-- tinyint
select cast(cast(cast('255' as varchar) as sql_variant) as tinyint);
go
select cast(cast(cast('255' as tinyint) as sql_variant) as varchar);
go
-- bit
select cast(cast(cast('1' as varchar) as sql_variant) as bit);
go
select cast(cast(cast('1' as bit) as sql_variant) as varchar);
go
-- nvarchar
select cast(cast(cast('£' as varchar) as sql_variant) as nvarchar(1));
go
select cast(cast(cast('£' as nvarchar(1)) as sql_variant) as varchar);
go
-- varchar
select cast(cast(cast('£' as varchar) as sql_variant) as varchar(1));
go
select cast(cast(cast('£' as varchar(1)) as sql_variant) as varchar);
go
-- nchar
select cast(cast(cast('£' as varchar) as sql_variant) as nchar(1));
go
select cast(cast(cast('£' as nchar(1)) as sql_variant) as varchar);
go
-- char
select cast(cast(cast('£' as varchar) as sql_variant) as char(1));
go
select cast(cast(cast('£' as char(1)) as sql_variant) as varchar);
go
-- varbinary
select cast(cast(cast('abc' as varchar) as sql_variant) as varbinary(3));
go
select cast(cast(cast('abc' as varbinary(3)) as sql_variant) as varchar);
go
-- binary
select cast(cast(cast('abc' as varchar) as sql_variant) as binary(3));
go
select cast(cast(cast('abc' as binary(3)) as sql_variant) as varchar);
go
-- uniqueidentifier
select cast(cast(cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0' as varchar(36))
                as sql_variant) as uniqueidentifier);
go
select cast(cast(cast('0E984725-C51C-4BF4-9960-E1C80E27ABA0' as uniqueidentifier)
                as sql_variant) as varchar(36));
go