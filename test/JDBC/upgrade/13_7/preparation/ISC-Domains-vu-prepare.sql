create schema isc_domains_vu_prepare_s
go

-- Create UDTS
create type isc_domains_vu_prepare_s.char_t from char(10)
go
create type isc_domains_vu_prepare_s.nchar_t from char(9)
go
create type isc_domains_vu_prepare_s.varchar_t from nvarchar(8)
go
create type isc_domains_vu_prepare_s.nvarchar_t from nvarchar(8)
go
create type isc_domains_vu_prepare_s.text_t from text
go
create type isc_domains_vu_prepare_s.ntext_t from ntext
go
create type isc_domains_vu_prepare_s.varbinary_t from varbinary(10)
go
create type isc_domains_vu_prepare_s.binary_t from binary(8)
go
create type isc_domains_vu_prepare_s.image_t from image
go
create type isc_domains_vu_prepare_s.int_t from int
go
create type isc_domains_vu_prepare_s.smallint_t from smallint
go
create type isc_domains_vu_prepare_s.tinyint_t from tinyint
go
create type isc_domains_vu_prepare_s.bigint_t from bigint
go
create type isc_domains_vu_prepare_s.bit_t from bit
go
create type isc_domains_vu_prepare_s.real_t from real
go
create type isc_domains_vu_prepare_s.numeric_t from numeric(5,3)
go
create type isc_domains_vu_prepare_s.money_t from money
go
create type isc_domains_vu_prepare_s.smallmoney_t from smallmoney
go
create type isc_domains_vu_prepare_s.date_t from date
go
create type isc_domains_vu_prepare_s.time_t from time(5)
go
create type isc_domains_vu_prepare_s.datetime_t from datetime
go
create type isc_domains_vu_prepare_s.datetime2_t from datetime2(5)
go
create type isc_domains_vu_prepare_s.smalldatetime_t from smalldatetime
go
create type isc_domains_vu_prepare_s.datetimeoffset_t from datetimeoffset(5)
go
create type isc_domains_vu_prepare_s.sql_variant_t from sql_variant
go

-- Create table type
CREATE TYPE isc_domains_vu_prepare_s.my_tbl_type AS TABLE(a INT)
go

-- Test cross db references
Create database isc_domains_vu_prepare_db
go

