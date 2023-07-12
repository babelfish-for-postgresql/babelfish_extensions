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
select 0x1000000 / @@microsoftversion
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