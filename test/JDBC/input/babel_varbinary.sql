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
Select 100 / 0x
go
Select 256 / 0x10
go
Select 56457 / 0x82B0
go
Select 243534536 / 0x45A32D
go
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
Select cast(0x100 as int)/cast(2345 as varbinary)
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
Select (12345+3543647)/cast((543210 & CAST(12345 AS varbinary(4))) as varbinary)
go
Select (sys.isdate('2023-4-5')*34+64)/0x234
go
Select (sys.isdate('2023-4-5')*34+64)/cast(sys.isdate('2023-4-5') as varbinary)
go
Select cast((0x234 & 23) as int) / cast(sys.isdate('2023-4-5') as varbinary)
go
Select cast(0x4567 as int)/cast((543210 & CAST(12345 AS varbinary(4))) as varbinary(4))
go
select 123 / 0x00
go
select 0 / 0x00
go
select 424748364 / 0x101
go
select -424748364 / 0x101
go

Select 0x/100
go
Select 0x10 / 2
go
Select 0x82B0 / 3
go
Select 0x45A32D / 4
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
Select cast((5432105 & CAST(12345 AS varbinary(4)))as varbinary)/(12345+3543647)
go
Select cast((54321 & CAST(12345 AS varbinary(4))) as varbinary)/cast(0x4567 as int)
go
Select 0x23FF/sys.isdate('2023-4-5')
go
Select 0x233DF/(sys.isdate('2023-4-5')*34+64)
go
Select cast(sys.isdate('2023-4-5') as varbinary)/(sys.isdate('2023-4-5')*3+6)
go
Select cast(sys.isdate('2023-4-5') as varbinary)/cast((0x234 & 23) as int) 
go
select 0x101 / 0
go
select 0x00 / 0
go
select 0x404 / 424748364
go
select 0x404 / -424748364
go

-- testcases with binary for division operator between varbinary and int4 datatype, vice-versa 
-- TODO :- Update the following test once the fix for BABEL-4308  is available
select cast(cast(NULL as binary) as int)/0x10
go
select 0x100/cast(cast(NULL as binary) as int)
go
Select cast(cast(2147483648 as binary) as int) / 0x100
go
Select 0x100/cast(cast(2147483648 as binary) as int)
go
Select 100000000/cast(cast(2147483648 as binary) as varbinary)
go
Select cast(cast(2147483648 as binary) as varbinary) /1000000
go
Select 100000000/cast(cast(-2147483649 as binary) as varbinary)
go
Select cast(cast(-2147483649 as binary) as varbinary) /1000000
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

-- TODO : will fix in jira BABEL-5597
declare @random varbinary(5) = 0x4142434445
declare @result varbinary(max) = 0x
select @result + @random
GO

declare @random varbinary(5) = 0x4142434445
declare @result varbinary(max) = 0x
select @result - @random
GO

select 
cast(cast(9223372036854775807 as bigint) as varbinary(max)) 
+ 
cast(cast(9223372036854775807 as bigint) as varbinary(max));
GO

select 
cast(cast(9223372036854775807 as bigint) as varbinary(200)) 
+ 
cast(cast(9223372036854775807 as bigint) as varbinary(200));
GO

select 
cast(cast(9223372036854775807 as bigint) as varbinary(max)) 
-
cast(cast(9223372036854775807 as bigint) as varbinary(max));
GO

select 
cast(cast(9223372036854775807 as bigint) as varbinary(200)) 
-
cast(cast(9223372036854775807 as bigint) as varbinary(200));
GO

select cast(0x as varbinary(max)) + cast(0x as varbinary(max))
GO

select cast(0x0 as varbinary(max)) + cast(0x0 as varbinary(max))
GO

select cast(NULL as varbinary(max)) + cast(NULL as varbinary(max))
GO

select cast(0x as varbinary(max)) - cast(0x as varbinary(max))
GO

select cast(0x0 as varbinary(max)) - cast(0x0 as varbinary(max))
GO

select cast(NULL as varbinary(max)) - cast(NULL as varbinary(max))
GO

SELECT 
CAST(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AS VARBINARY(max)) 
+ 
CAST(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AS VARBINARY(max));
GO

SELECT 
CAST(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AS VARBINARY(max)) 
- 
CAST(0x0000000000000000000000000000FFFF AS VARBINARY(max));
GO

CREATE TABLE varbinary_test_table ( varbinary_test_col varbinary(max))
GO

INSERT INTO varbinary_test_table (varbinary_test_col) SELECT CAST(0x1 AS VARBINARY) FROM generate_series(1, 3);
GO

INSERT INTO varbinary_test_table (varbinary_test_col) SELECT CAST(0x4 AS VARBINARY) FROM generate_series(1, 3);
GO

INSERT INTO varbinary_test_table (varbinary_test_col) SELECT CAST(0x8 AS VARBINARY) FROM generate_series(1, 3);
GO

CREATE NONCLUSTERED INDEX ind ON varbinary_test_table(varbinary_test_col ASC)
GO

SELECT set_config('enable_seqscan', 'off', false);
GO

SET BABELFISH_SHOWPLAN_ALL ON
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col < cast(0x123 as varbinary(max)) + cast(0x123 as varbinary(max))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col > cast(0x123 as varbinary(max)) + cast(0x123 as varbinary(max))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col < cast(0x123 as varbinary(10)) + cast(0x123 as varbinary(10))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col > cast(0x123 as varbinary(10)) + cast(0x123 as varbinary(10))
GO

SET BABELFISH_SHOWPLAN_ALL OFF
GO

SELECT set_config('enable_seqscan', 'on', false);
GO

SET BABELFISH_SHOWPLAN_ALL ON
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col < cast(0x123 as varbinary(max)) + cast(0x123 as varbinary(max))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col > cast(0x123 as varbinary(max)) + cast(0x123 as varbinary(max))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col < cast(0x123 as varbinary(10)) + cast(0x123 as varbinary(10))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col > cast(0x123 as varbinary(10)) + cast(0x123 as varbinary(10))
GO

SET BABELFISH_SHOWPLAN_ALL OFF
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col < cast(0x123 as varbinary(max)) + cast(0x123 as varbinary(max))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col > cast(0x123 as varbinary(max)) + cast(0x123 as varbinary(max))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col < cast(0x123 as varbinary(10)) + cast(0x123 as varbinary(10))
GO

Select varbinary_test_col from varbinary_test_table where varbinary_test_col > cast(0x123 as varbinary(10)) + cast(0x123 as varbinary(10))
GO

drop table varbinary_test_table
go
