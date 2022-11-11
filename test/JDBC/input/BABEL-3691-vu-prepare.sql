-- DIFFERENT CASES TO CHECK DATATYPES
-- EXACT NUMERICS
create table dt01(a bigint, b bit, c decimal, d int, e money, f numeric, g smallint, h smallmoney, i tinyint)
go
insert dt01 values(9223372036854775807, 1, 123.2, 2147483647, 3148.29, 12345.12, 32767, 3148.29, 255)
go

-- Approximate numerics
create table dt02(a float, b real)
go
insert dt02 values(12.05, 120.53)
go

-- Date and time
create table dt03(a time, b date, c smalldatetime, d datetime, e datetime2, f datetimeoffset)
go
insert dt03 values('2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560','2022-11-11 23:17:08.560')
go

-- Character strings
create table dt04(a char, b varchar(3), c text)
go
insert dt04 values('a','abc','abc')
go

-- Unicode character strings
drop table if exists dt05
create table dt05(a nchar(5), b nvarchar(5), c ntext)
go
insert dt05 values('abc','abc','abc')
go

-- Binary strings
create table dt06(a binary, b varbinary(10))
go
insert dt06 values(123456,0x0a0b0c0d0e)
go

-- Return null string
create table t01 (MyColumn int)
go
