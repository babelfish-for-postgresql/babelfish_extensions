
-- babel-1149
create function tv_itvf_1(@number int) returns table as return (select 1 as a, 2 as b);
GO

create function tv_mstvf_1(@i int) returns @tableVar table (a nvarchar(10), b int, c int)
as
begin
insert into @tableVar values('hello1', 1, 100);
insert into @tableVar values('hello2', 2, 200);
insert into @tableVar values('hello3', 3, 300);
update @tableVar set b = 2 where b = 3;
delete @tableVar where b = 2;
return;
end;
GO

create function tv_func_1(@i int) returns int as begin
declare @a as table (a int, b int)
insert into @a values (100, 200)
return 1;
end;
GO

create procedure tv_proc_1 as
declare @a table (a int, b int);
insert into @a values(1, 100);
update @a set b = 200;
GO

-- babel-2647
CREATE FUNCTION dbo.tv_mstvf_2() RETURNS @tv TABLE (a int NULL)
AS
BEGIN
	INSERT @tv VALUES(0);
	RETURN;
END;
go

--babel-2903
use master;
go

drop table if exists tv_t1;
go
create table tv_t1 (a int, b int);
go
insert into tv_t1 values (1, 1);
go
insert into tv_t1 values (2, 2);
go

drop procedure if exists tv_inner_proc;
go
create procedure tv_inner_proc @b int
as
    set @b = (select top 1 a+b from tv_t1 order by b);
    insert into tv_t1 values (@b, @b);
go

drop procedure if exists tv_outer_proc;
go
create procedure tv_outer_proc @a int, @b int
as
    declare @t table (a int, b int);
    set @a = 3;
    insert into tv_t1 values (@a, @b);
    exec tv_inner_proc @b;
    insert into @t select * from tv_t1;
    select * from @t;
go

-- babel-3101
CREATE FUNCTION tv_my_splitstring ( @stringToSplit VARCHAR(MAX) )
RETURNS
@returnList TABLE ([Value] [nvarchar] (50))
AS
BEGIN
	DECLARE @name NVARCHAR(255)
	DECLARE @pos INT

	WHILE CHARINDEX(',', @stringToSplit) > 0
		BEGIN
			SELECT @pos  = CHARINDEX(',', @stringToSplit)
			SELECT @name = SUBSTRING(@stringToSplit, 1, @pos-1)

			INSERT INTO @returnList SELECT @name

			SELECT @stringToSplit = SUBSTRING(@stringToSplit, @pos+1, LEN(@stringToSplit)-@pos)
		END

		INSERT INTO @returnList SELECT @stringToSplit

		RETURN
END
GO

-- babel-3088
create database tv_db
go
use tv_db
go

create table tv_t2(a nvarchar(50));
insert into tv_t2 values ('aaa');
go

create procedure tv_proc_2 (@a int)
as
  declare @tv TABLE(a nvarchar(50))
  insert into @tv select * from tv_t2;
  select * from @tv; 
go

use master
go

--babel-2034
CREATE TABLE tv_EasDateTime (EasDateTime pg_catalog.timestamp, LastUpdDateTime pg_catalog.timestamp, LastCompressionMaxDate pg_catalog.timestamp, CompressionRate real);
GO

-- Test ITVF - column references such as "easdatetime" in the query collides
-- with the column names of the returned rows - should not throw error
CREATE FUNCTION tv_CalculateEasDateTime (  @InputDate DATETIME = NULL ) RETURNS TABLE AS  RETURN (
WITH
RawValues  AS (SELECT EasDateTime,  LastUpdDateTime,  LastCompressionMaxDate,  ISNULL(CompressionRate, 1.0) AS compressionrate,  ISNULL(NULL, CURRENT_TIMESTAMP) AS currdatetime  FROM tv_EasDateTime),

RawValues2  AS (SELECT ISNULL(EasDateTime, currdatetime) AS easdatetime,  ISNULL(LastUpdDateTime, currdatetime) AS lastupddatetime,  LastCompressionMaxDate,  currdatetime,  compressionrate  FROM RawValues),

Calcs  AS (SELECT easdatetime,  lastupddatetime,  LastCompressionMaxDate,  compressionrate,  currdatetime,  CASE  WHEN easdatetime IS NULL THEN  currdatetime  ELSE  DATEADD(s, DATEDIFF(s, lastupddatetime, currdatetime) * compressionrate, easdatetime)  END AS adjeasdatetime  FROM RawValues2),

UnionedWithDefaults  AS (SELECT easdatetime,  lastupddatetime,  LastCompressionMaxDate,  compressionrate,  currdatetime,  adjeasdatetime AdjDatetimeWithoutCap,  2 WeightToForceDefault  FROM Calcs  UNION  SELECT GETDATE() easdatetime,  GETDATE() lastupddatetime,  GETDATE() LastCompressionMaxDate,  1.0 compressionrate,  GETDATE() currdatetime,  GETDATE() AdjDatetimeWithoutCap,  1 WeightToForceDefault)

SELECT TOP 1  easdatetime,  lastupddatetime,  LastCompressionMaxDate,  compressionrate,  currdatetime,  AdjDatetimeWithoutCap  FROM UnionedWithDefaults  ORDER BY WeightToForceDefault DESC
);
GO

create function tv_mstvf_3(@i int) returns @tableVar table
(
	a text not null,
	b int primary key,
	c int
)
as
begin
	insert into @tableVar values('hello1', 1, 100);
	insert into @tableVar values('hello2', 2, 200);
	return;
end;
GO

-- Duplicate parameter name - should throw error
create function tv_mstvf_dup_input_arg(@tableVar int) returns @tableVar table
(
	a text not null,
	b int primary key,
	c int
)
as
begin
	insert into @tableVar values('hello1', 1, 100);
	insert into @tableVar values('hello2', 2, 200);
	return;
end;
GO

-- Duplicate variable name - should throw error
create function tv_mstvf_dup_local_arg(@i int) returns @tableVar table
(
	a text not null,
	b int primary key,
	c int
)
as
begin
	declare @tableVar int;
	insert into @tableVar values('hello1', 1, 100);
	insert into @tableVar values('hello2', 2, 200);
	return;
end;
GO

--babel-2676
create function tv_mstvf_conditional(@i int) returns @tableVar table
(
a text not null
)
begin
	insert into @tableVar values('hello1')
	if @i > 0
		return
	insert into @tableVar values('hello2')
	return
end
go


