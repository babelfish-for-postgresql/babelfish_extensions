-- Testing only PG base types since system_type_id keeps changing for others
-- UDT tests cannot be added because user_type_id keeps changing as well

-- create table var(a char(10), b nchar(9), c nvarchar(8), d varchar(7), e text, f ntext, g varbinary(10), h binary(9), i image, j xml)
create table var(a text, b xml)
go

-- create table dates(a date, b time(5), c datetime, d datetime2(5), e smalldatetime, f sql_variant)
create table dates(a date, b time(5))
go

-- create table nums(a int, b smallint, c tinyint, d bigint, e bit, f float, g real, h numeric(5,3), i money, j smallmoney)
create table nums(a int, b smallint, c bigint, d float, e real, f numeric(5,3))
go

create table num_identity(a int identity, b int) 
go

create table sp_describe_t1(a int)
go

exec sp_describe_first_result_set N'select * from var'
go

exec sp_describe_first_result_set N'select * from dates'
go

exec sp_describe_first_result_set N'select * from dbo.nums'
go

exec sp_describe_first_result_set N'select * from isc_udt'
go

exec sp_describe_first_result_set N'select * from master..num_identity'
go

-- no result testing
exec sp_describe_first_result_set N'insert into sp_describe_t1 values(1)', NULL, 0
go

exec sp_describe_first_result_set
go

exec sp_describe_first_result_set N''
go

-- cross schema testing
create schema sc_result_set
go

exec sp_describe_first_result_set N'select * from sc_result_set.nums'
go

create table sc_result_set.nums(a int, b smallint, c bigint, d float, e real, f numeric(5,3))
go

exec sp_describe_first_result_set N'select * from sc_result_set.nums'
go

-- cross db testing
create database db_result_set
go

use db_result_set
go

exec sp_describe_first_result_set N'select * from nums'
go

-- clean-up
use master
go
drop table var
drop table dates
drop table nums
drop table num_identity
drop table sp_describe_t1
drop table sc_result_set.nums
drop schema sc_result_set
drop database db_result_set
go
