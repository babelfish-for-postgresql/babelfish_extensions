-- [BABEL-448] Test support of unquoted hexadecimal string input
select 0x1a2b3c4f;
go
select 0X1A2B3C4F;
go
select pg_typeof(0X1A2B3C4F);
go

-- BABEL-631 Test odd number of hex digigts is allowed
select 0xF;
go
select 0x1;
go
select 0x0;
go
select 0x1F1;
go

-- invalid hex input
select 0x1G2A;
go

-- test insert of hex string
create table t1(a varbinary(8), b binary(8));
insert into t1 values(0x1a2b3c4f, cast('1a2b3c4f' as binary(8)));
insert into t1 values(cast('1a2b3c4f' as varbinary(8)), cast('1a2b3c4f' as binary(8)));
go

-- 0x1a2b3c4f and '1a2b3c4f' are different as varbinary
select * from t1;
go

-- test bitwise operators on hex string and int
select 0x1F & 10;
go
select 10 & 0x1F;
go
select 0x1F | 10;
go
select 10 | 0x1F;
go
select 0x1F ^ 10;
go
select 10 ^ 0x1F;
go
select 0x1F * 10;
go
select 10 * 0x1F;
go
select 0x1F / 10;
go
select 100 / 0x1F;
go

-- division by 0
select 0x1F / 0;
go
select 10 / 0x00;
go

--division between varbinary and int4 datatype, vice-versa
select @@microsoftversion / 0x1000000
go
Select 2147483647 / 0x7FFFFFFF
go
Select 2147483647 / 0x80000000
go
Select 2147483647 / 0x80000001
go
Select 2147483647 / 0xC0000005
go
Select -2147483647 / 0xC0000005
go
Select -2147483648 / 0xC0000005
go
SELECT (12345 / CAST(12 AS varbinary(4)))
go
Select (cast(0x100 as int) / 0x10)
go
Select cast(0x100 as int)/cast(0x10 as varbinary)
go
create table int4var(a varbinary,b int)
go
insert into int4var values (0x23 , 2147563)
go
insert into int4var values (0xFF ,-2147483647 )
go
Select b/a from int4var
go
Select cast(b as int)/a from int4var
go
Select (12345+3543647)/(543210 & CAST(12345 AS varbinary(4)))
go
Select cast(0x4567 as int)/(543210 & CAST(12345 AS varbinary(4)))
go

select 0x1000000 / @@microsoftversion
go
Select 0x7FFFFFFF / 2147483647
go
Select 0x80000000 / 2147483647
go
Select 0x80000001 / 2147483647
go
Select 0xC0000005 / 2147483647
go
Select 0xC0000005 / -2147483647
go
Select 0xC0000005 / -2147483648
go
SELECT (CAST(123456 AS varbinary(4)) / 1234)
go
Select (0x1110 / cast(0x100 as int) )
go
Select cast(0x1234 as varbinary) / cast(0x100 as int)
go
Select a/b from int4var
go
Select a/cast(b as int) from int4var
go
Select (543210565 & CAST(12345 AS varbinary(4)))/(12345+3543647)
go
Select (543210458 & CAST(12345 AS varbinary(4)))/cast(0x4567 as int)
go
select 0x101 / 0
go
select 123 / 0x00
go
select 0 / 0x00
go
select 0x00 / 0
go
select 424748364 / 0x101
go
select 0x404 / 424748364
go
select -424748364 / 0x101
go
select 0x404 / -424748364
go

drop table int4var
go

-- test hex string in procedure
create procedure test_hex_bitop as
begin
	select 0x1A2B3C4F ^ 101;
end;
go

execute test_hex_bitop;
go

create procedure test_hex_insert as
begin
	insert into t1 values(0x1f, cast('1f' as binary(2)));
end;
go

execute test_hex_insert;
go
select * from t1;
go

-- clean up
drop table t1;
drop procedure test_hex_bitop;
drop procedure test_hex_insert;
go