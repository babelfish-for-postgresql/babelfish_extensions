create table var(a char(10), b nchar(9), c nvarchar(8), d varchar(7), e text, f ntext, g varbinary(10), h binary(9), i image, j xml)
go

create table dates(a date, b time(5), c datetime, d datetime2(5), e smalldatetime, f sql_variant)
go

create table nums(a int, b smallint, c tinyint, d bigint, e bit, f float, g real, h numeric(5,3), i money, j smallmoney)
go

Select * from information_schema.tables WHERE TABLE_NAME in ('nums', 'dates', 'var')  ORDER BY TABLE_NAME
go

-- Testing generic columns for columns schema
Select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, COLUMN_DEFAULT, IS_NULLABLE, DATA_TYPE, DOMAIN_CATALOG, DOMAIN_SCHEMA, DOMAIN_NAME from information_schema.columns where table_name in ('nums') ORDER BY DATA_TYPE
go

-- Testing with most of the datatypes for columns schema
Select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('var') ORDER BY DATA_TYPE
go

Select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('dates') ORDER BY DATA_TYPE
go

Select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('nums') ORDER BY DATA_TYPE
go

-- Testing User Defined Types
create type int_a from int
create type varchar_a from varchar(10)
go

create table isc_udt(a int_a, b varchar_a)
go

Select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('isc_udt') ORDER BY DATA_TYPE
go

-- Testing Cross Database refences
Create database isc_db
go

Use isc_db
go

Select * from information_schema.tables
go

-- Will only include sysdatabases view
select count(*) from information_schema.tables WHERE TABLE_NAME != 'sysdatabases'
select count(*) from information_schema.columns WHERE TABLE_NAME != 'sysdatabases'
go

Use master
go

-- clean-up
DROP TABLE nums
DROP TABLE dates
DROP TABLE var
DROP TABLE isc_udt
DROP TYPE int_a
DROP TYPE varchar_a
DROP DATABASE isc_db
go