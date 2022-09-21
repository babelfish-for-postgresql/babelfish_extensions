-- Testing only PG base types since system_type_id keeps changing for others
-- UDT tests cannot be added because user_type_id keeps changing as well

-- create table var(a char(10), b nchar(9), c nvarchar(8), d varchar(7), e text, f ntext, g varbinary(10), h binary(9), i image, j xml)
create table babel_3000_vu_prepare_var(a text, b xml)
go

-- create table dates(a date, b time(5), c datetime, d datetime2(5), e smalldatetime, f sql_variant)
create table babel_3000_vu_prepare_dates(a date, b time(5))
go

-- create table nums(a int, b smallint, c tinyint, d bigint, e bit, f float, g real, h numeric(5,3), i money, j smallmoney)
create table babel_3000_vu_prepare_nums(a int, b smallint, c bigint, d float, e real, f numeric(5,3))
go

create table babel_3000_vu_prepare_num_identity(a int identity, b int) 
go

create table babel_3000_vu_prepare_t1(a int)
go

-- cross schema testing
create schema babel_3000_vu_prepare_s1
go

create table babel_3000_vu_prepare_s1.babel_3000_vu_prepare_nums(a int, b smallint, c bigint, d float, e real, f numeric(5,3))
go

-- cross db testing
create database babel_3000_vu_prepare_db1
go