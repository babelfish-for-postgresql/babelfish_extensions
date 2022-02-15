create schema isc_domains
go

-- Create UDTS
create type isc_domains.char_t from char(10)
go
create type isc_domains.nchar_t from char(9)
go
create type isc_domains.varchar_t from nvarchar(8)
go
create type isc_domains.nvarchar_t from nvarchar(8)
go
create type isc_domains.text_t from text
go
create type isc_domains.ntext_t from ntext
go
create type isc_domains.varbinary_t from varbinary(10)
go
create type isc_domains.binary_t from binary(8)
go
create type isc_domains.image_t from image
go
create type isc_domains.int_t from int
go
create type isc_domains.smallint_t from smallint
go
create type isc_domains.tinyint_t from tinyint
go
create type isc_domains.bigint_t from bigint
go
create type isc_domains.bit_t from bit
go
create type isc_domains.real_t from real
go
create type isc_domains.numeric_t from numeric(5,3)
go
create type isc_domains.money_t from money
go
create type isc_domains.smallmoney_t from smallmoney
go
create type isc_domains.date_t from date
go
create type isc_domains.time_t from time(5)
go
create type isc_domains.datetime_t from datetime
go
create type isc_domains.datetime2_t from datetime2(5)
go
create type isc_domains.smalldatetime_t from smalldatetime
go
create type isc_domains.datetimeoffset_t from datetimeoffset(5)
go
create type isc_domains.sql_variant_t from sql_variant
go

-- Create table type
CREATE TYPE isc_domains.my_tbl_type AS TABLE(a INT)
go

select * from information_schema.domains where DOMAIN_SCHEMA = 'isc_domains' ORDER BY DOMAIN_NAME
go

-- Test cross db references
Create database isc_domain_db
go

use isc_domain_db
go

select COUNT(*) from information_schema.domains
go

USE master
go

-- cleanup
DROP TYPE isc_domains.char_t
DROP TYPE isc_domains.nchar_t
DROP TYPE isc_domains.varchar_t
DROP TYPE isc_domains.nvarchar_t
DROP TYPE isc_domains.text_t
DROP TYPE isc_domains.ntext_t
DROP TYPE isc_domains.varbinary_t
DROP TYPE isc_domains.binary_t
DROP TYPE isc_domains.image_t
DROP TYPE isc_domains.int_t
DROP TYPE isc_domains.smallint_t
DROP TYPE isc_domains.tinyint_t
DROP TYPE isc_domains.bigint_t
DROP TYPE isc_domains.bit_t
DROP TYPE isc_domains.real_t
DROP TYPE isc_domains.numeric_t
DROP TYPE isc_domains.money_t
DROP TYPE isc_domains.smallmoney_t
DROP TYPE isc_domains.date_t
DROP TYPE isc_domains.time_t
DROP TYPE isc_domains.datetime_t
DROP TYPE isc_domains.datetime2_t
DROP TYPE isc_domains.smalldatetime_t
DROP TYPE isc_domains.datetimeoffset_t
DROP TYPE isc_domains.sql_variant_t
DROP TYPE isc_domains.my_tbl_type 
DROP SCHEMA isc_domains
DROP DATABASE isc_domain_db
go