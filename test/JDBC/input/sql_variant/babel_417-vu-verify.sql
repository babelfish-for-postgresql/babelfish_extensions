-- Test cast from SQL_Variant returns correct base type
-- datetime2
select SQL_VARIANT_PROPERTY(cast(cast('2020-10-20 09:00:00' as datetime2) as sql_variant), 'BaseType');
go
select cast(cast(cast('2020-10-20 09:00:00' as datetime2) as sql_variant) as datetime2);
go
-- datetime
select SQL_VARIANT_PROPERTY(cast(cast('2020-10-20 09:00:00' as datetime) as sql_variant), 'BaseType');
go
select cast(cast(cast('2020-10-20 09:00:00' as datetime) as sql_variant) as datetime);
go
-- smalldatetime
select SQL_VARIANT_PROPERTY(cast(cast('2020-10-20 09:00:00' as smalldatetime) as sql_variant), 'BaseType');
go
select cast(cast(cast('2020-10-20 09:00:00' as smalldatetime) as sql_variant) as smalldatetime);
go
-- money
select SQL_VARIANT_PROPERTY(cast(cast('$123.123' as money) as sql_variant), 'BaseType');
go
select cast(cast(cast('$123.123' as money) as sql_variant) as money);
go
-- smallmoney
select SQL_VARIANT_PROPERTY(cast(cast('$123.123' as smallmoney) as sql_variant), 'BaseType');
go
select cast(cast(cast('$123.123' as smallmoney) as sql_variant) as smallmoney);
go
-- smallint
select SQL_VARIANT_PROPERTY(cast(cast('256' as smallint) as sql_variant), 'BaseType');
go
select cast(cast(cast('256' as smallint) as sql_variant) as smallint);
go
-- tinyint
select SQL_VARIANT_PROPERTY(cast(cast('255' as tinyint) as sql_variant), 'BaseType');
go
select cast(cast(cast('255' as tinyint) as sql_variant) as tinyint);
go
-- nvarchar
select SQL_VARIANT_PROPERTY(cast(cast('£' as nvarchar) as sql_variant), 'BaseType');
go
select cast(cast(cast('£' as nvarchar(1)) as sql_variant) as nvarchar(1));
go
-- varchar
select SQL_VARIANT_PROPERTY(cast(cast('£' as varchar) as sql_variant), 'BaseType');
go
select cast(cast(cast('£' as varchar(1)) as sql_variant) as varchar(1));
go
-- nchar
select SQL_VARIANT_PROPERTY(cast(cast('£' as nchar(1)) as sql_variant), 'BaseType');
go
select cast(cast(cast('£' as nchar(1)) as sql_variant) as nchar(1));
go
-- char
select SQL_VARIANT_PROPERTY(cast(cast('£' as char(1)) as sql_variant), 'BaseType');
go
select cast(cast(cast('£' as char(1)) as sql_variant) as char(1));
go
