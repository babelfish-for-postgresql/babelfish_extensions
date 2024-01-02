-- length > 57532 for varchar
declare @babel4547Varchar varchar(max) = REPLICATE('a', 60000);
select @babel4547Varchar
GO

select cast(REPLICATE('a', 60000) as varchar(max));
GO

CREATE TABLE babel4547t1(a varchar(max))
go

insert into babel4547t1 values (REPLICATE('b', 60000))
go

insert into babel4547t1 values (CAST(REPLICATE('c', 60000) as varchar(max)))
go

declare @vrchrt1 varchar(max) = REPLICATE('d', 60000)
insert into babel4547t1 values (@vrchrt1)
go

select a from babel4547t1;
go

DROP table babel4547t1
GO

-- length > 24764 for nvarchar
DECLARE @babel4547NVarchar NVARCHAR(max) = REPLICATE('a', 30000);
select @babel4547NVarchar;
go

select cast(REPLICATE('a', 30000) as nvarchar(max));
GO

CREATE TABLE babel4547t2(b nvarchar(max))
go

insert into babel4547t2 values (REPLICATE('b', 30000))
go

insert into babel4547t2 values (cast(REPLICATE('c', 30000) as nvarchar(max)))
go

declare @nvrchrt2 nvarchar(max) = REPLICATE('d', 30000)
insert into babel4547t2 values (@nvrchrt2)
go

select b from babel4547t2;
go

DROP table babel4547t2
GO

-- length > 57532 for varbinary
declare @b varbinary(max) = convert(varbinary(max), replicate(0x01, 60001));
select @b;
go

select cast(REPLICATE(0x01, 60001) as varbinary(max));
GO

CREATE TABLE babel4547t3(c varbinary(max))
go

insert into babel4547t3 values (convert(varbinary(max), replicate(0x01, 60001)))
go

insert into babel4547t3 values (cast(REPLICATE(0x01, 60001) as varbinary(max)))
go

declare @vrbnrt3 varbinary(max) = convert(varbinary(max), replicate(0x01, 60001));
insert into babel4547t3 values (@vrbnrt3)
go

select c from babel4547t3;
go

DROP table babel4547t3
GO

-- Test the limit of scale specified in char, nchar, varchar, nvarchar, binary, varbinary
-- char
declare @char1 char(8001) = 'abc';
go
declare @char1     char     (8001) = 'abc';
go
declare @char2 char(8000) = 'abc';
select @char2
go
select cast('abc' as char(8001));
go

-- varchar
declare @varchar1 varchar(8001) = 'abc';
go
declare @varchar1  varchar    (8001)   = 'abc';
go
declare @varchar2 varchar(8000) = 'abc';
select @varchar2
go
select cast('abc' as varchar(8001));
go

-- nchar
declare @nchar1 nchar(4001) = 'abc';
go
declare @nchar1    nchar   (4001) = 'abc';
go
declare @nchar2 nchar(4000) = 'abc';
select @nchar2
go
select cast('abc' as nchar(4001));
go

-- nvarchar
declare @nvarchar1 nvarchar(4001) = 'abc';
go
declare @nvarchar1   nvarchar    (4001) = 'abc';
go
declare @nvarchar2 nvarchar(4000) = 'abc';
select @nvarchar2
go
select cast('abc' as nvarchar(4001));
go

-- Binary
declare @binary1 binary(8001) = 1;
go
declare @binary1     binary   (8001) = 1;
go
declare @binary2 binary(8000) = 1;
select @binary2;
go
select cast(1 as binary(8001));
go
create table test_binary_t1 (a binary(8001))
go
drop table if exists test_binary_t1
go
create table test_binary_t2 (a binary(8000))
go
insert into test_binary_t2 values (123)
go
select * from test_binary_t2
go
drop table if exists test_binary_t2
go


-- Varbinary
declare @varbinary1 varbinary(8001) = 1;
go
declare @varbinary1    varbinary    (8001) = 1;
go
declare @varbinary2 varbinary(8000) = 1;
select @varbinary2;
go
select cast(1 as varbinary(8001));
go
create table test_varbinary_t1 (a varbinary(8001))
go
drop table if exists test_varbinary_t1
go
create table test_varbinary_t2 (a varbinary(8000))
go
insert into test_varbinary_t2 values (123)
go
select * from test_varbinary_t2
go
drop table if exists test_varbinary_t2
go

-- test without specifing scale
declare @test_variable varchar = 'aaaaaa';
select @test_variable
go

declare @test_variable char = 'aaaaaa';
select @test_variable
go

declare @test_variable nvarchar = 'aaaaaa';
select @test_variable
go

declare @test_variable nchar = 'aaaaaa';
select @test_variable
go

declare @test_variable varbinary = 1234552;
select @test_variable
go

declare @test_variable binary = 1234552;
select @test_variable
go
