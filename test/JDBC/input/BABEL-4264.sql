select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

create table babel4264(name1 varchar(42), flag1 bit)
go

insert into babel4264 values ('true', 1)
insert into babel4264 values ('false', 0)
go

select * from babel4264 where flag1 = CAST('true' as VARCHAR(20))
go

select * from babel4264 where CAST('true' as VARCHAR(20)) = flag1
go

select * from babel4264 where -flag1 = CAST('true' as VARCHAR(20))
go

select * from babel4264 where CAST('true' as VARCHAR(20)) = ~flag1
go

set babelfish_showplan_all on
go

select * from babel4264 where flag1 = CAST('true' as VARCHAR(20))
go

set babelfish_showplan_all off
go

drop table babel4264
go

create table babel4264(date1 date)
go

set babelfish_showplan_all on
go

SELECT * from babel4264 where date1 = '1955-12-13 12:43:10'
go

SELECT * from babel4264 where date1 = cast('1955-12-13 12:43:10' as datetime2)
go

SELECT * from babel4264 where date1 = cast('1955-12-13 12:43:10' as smalldatetime)
go

set babelfish_showplan_all off
go

drop table babel4264
go

create table babel4264(dollars money)
go

set babelfish_showplan_all on
go

SELECT * from babel4264 where dollars = 10
go

SELECT * from babel4264 where dollars = 10.0
go

SELECT * from babel4264 where dollars = 2147483650
go

SELECT * from babel4264 where dollars = '10.12'
go

SELECT * from babel4264 where dollars = '10.123512341234'
go

SELECT * from babel4264 where dollars = cast('10' as varchar(30))
go

set babelfish_showplan_all off
go

drop table babel4264
go

-- Not allowed
SELECT cast(cast('true' as varchar(20)) as INT)
go

-- Note, negative varbinary not allowed in T-SQL
SELECT (123 + (-0x42));
GO
SELECT ((-0x42) + 123);
GO

SELECT (123 - 0x42);
GO
SELECT (0x42 - 123);
GO

-- Return type of int const and varbinary is now INT, not BIGINT. This can
-- result in overflows that didn't previously occur, but overflow matches T-SQL
SELECT (2147483640 + 0x10)
GO
SELECT (0x10 + 2147483640)
GO

SELECT (cast(2147483640 as bigint) + 0x10)
GO
SELECT (0x10 + cast(2147483640 as bigint))
GO

SELECT (-2147483640 - 0x10)
GO
SELECT (-0x10 - 2147483640)
GO

SELECT (cast(-2147483640 as bigint) - 0x10)
GO
SELECT (-0x10 - cast(2147483640 as bigint))
GO
