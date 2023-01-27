-- Testing bbf_original_table_name with special characters (BABEL-3398)
SET QUOTED_IDENTIFIER ON;
go

select * from information_schema.tables WHERE TABLE_NAME in ('nums', 'dates', 'var', 'CUSTOM.[CustomTable') ORDER BY TABLE_NAME
go

drop table [CUSTOM\schema].[CUSTOM.[CustomTable];
drop schema [CUSTOM\schema];
go

-- Testing generic columns for columns schema
select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, COLUMN_DEFAULT, IS_NULLABLE, DATA_TYPE, DOMAIN_CATALOG, DOMAIN_SCHEMA, DOMAIN_NAME from information_schema.columns where table_name in ('nums') ORDER BY DATA_TYPE
go

-- Testing with most of the datatypes for columns schema
select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('var') ORDER BY DATA_TYPE
go

select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('dates') ORDER BY DATA_TYPE
go

select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('nums') ORDER BY DATA_TYPE
go

-- Testing User Defined Types
select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from information_schema.columns where table_name in ('isc_udt_1') ORDER BY DATA_TYPE
go

-- Testing delimited schema name
select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from [information_schema].columns where table_name in ('isc_udt_1') ORDER BY DATA_TYPE
select DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, CHARACTER_SET_CATALOG, CHARACTER_SET_NAME, collation_catalog, collation_schema, collation_name from "information_schema".columns where table_name in ('isc_udt_1') ORDER BY DATA_TYPE
go

-- Testing Cross Database refences
use isc_db
go

select * from information_schema.tables
go

-- Will only include sysdatabases view
select count(*) from information_schema.tables WHERE TABLE_NAME != 'sysdatabases'
select count(*) from information_schema.columns WHERE TABLE_NAME != 'sysdatabases'
go

-- Cross db ref testing for ISC.Views view
use isc_db
go

select table_catalog, table_schema, table_name from information_schema.views
go

-- Will only include sysdatabases view
select count(*) from information_schema.views WHERE TABLE_NAME != 'sysdatabases'
go

