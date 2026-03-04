
-- babel-1149
create function table_variable_vu_prepareitvf_1(@number int) returns table as return (select 1 as a, 2 as b);
GO

create function table_variable_vu_preparemstvf_1(@i int) returns @tableVar table (a nvarchar(10), b int, c int)
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

create function table_variable_vu_preparefunc_1(@i int) returns int as begin
declare @a as table (a int, b int)
insert into @a values (100, 200)
return 1;
end;
GO

create procedure table_variable_vu_prepareproc_1 as
declare @a table (a int, b int);
insert into @a values(1, 100);
update @a set b = 200;
GO

-- babel-2647
CREATE FUNCTION dbo.table_variable_vu_preparemstvf_2() RETURNS @tv TABLE (a int NULL)
AS
BEGIN
	INSERT @tv VALUES(0);
	RETURN;
END;
go

--babel-2903
use master;
go

drop table if exists table_variable_vu_preparet1;
go
create table table_variable_vu_preparet1 (a int, b int);
go
insert into table_variable_vu_preparet1 values (1, 1);
go
insert into table_variable_vu_preparet1 values (2, 2);
go

drop procedure if exists table_variable_vu_prepareinner_proc;
go
create procedure table_variable_vu_prepareinner_proc @b int
as
    set @b = (select top 1 a+b from table_variable_vu_preparet1 order by b);
    insert into table_variable_vu_preparet1 values (@b, @b);
go

drop procedure if exists table_variable_vu_prepareouter_proc;
go
create procedure table_variable_vu_prepareouter_proc @a int, @b int
as
    declare @t table (a int, b int);
    set @a = 3;
    insert into table_variable_vu_preparet1 values (@a, @b);
    exec table_variable_vu_prepareinner_proc @b;
    insert into @t select * from table_variable_vu_preparet1;
    select * from @t;
go

-- babel-3101
CREATE FUNCTION table_variable_vu_preparemy_splitstring ( @stringToSplit VARCHAR(MAX) )
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
create database table_variable_vu_preparedb
go
use table_variable_vu_preparedb
go

create table table_variable_vu_preparet2(a nvarchar(50));
insert into table_variable_vu_preparet2 values ('aaa');
go

create procedure table_variable_vu_prepareproc_2 (@a int)
as
  declare @tv TABLE(a nvarchar(50))
  insert into @tv select * from table_variable_vu_preparet2;
  select * from @tv; 
go

use master
go

--babel-2034
CREATE TABLE table_variable_vu_prepareEasDateTime (EasDateTime pg_catalog.timestamp, LastUpdDateTime pg_catalog.timestamp, LastCompressionMaxDate pg_catalog.timestamp, CompressionRate real);
GO

-- Test ITVF - column references such as "easdatetime" in the query collides
-- with the column names of the returned rows - should not throw error
CREATE FUNCTION table_variable_vu_prepareCalculateEasDateTime (  @InputDate DATETIME = NULL ) RETURNS TABLE AS  RETURN (
WITH
RawValues  AS (SELECT EasDateTime,  LastUpdDateTime,  LastCompressionMaxDate,  ISNULL(CompressionRate, 1.0) AS compressionrate,  ISNULL(NULL, CURRENT_TIMESTAMP) AS currdatetime  FROM table_variable_vu_prepareEasDateTime),

RawValues2  AS (SELECT ISNULL(EasDateTime, currdatetime) AS easdatetime,  ISNULL(LastUpdDateTime, currdatetime) AS lastupddatetime,  LastCompressionMaxDate,  currdatetime,  compressionrate  FROM RawValues),

Calcs  AS (SELECT easdatetime,  lastupddatetime,  LastCompressionMaxDate,  compressionrate,  currdatetime,  CASE  WHEN easdatetime IS NULL THEN  currdatetime  ELSE  DATEADD(s, DATEDIFF(s, lastupddatetime, currdatetime) * compressionrate, easdatetime)  END AS adjeasdatetime  FROM RawValues2),

UnionedWithDefaults  AS (SELECT easdatetime,  lastupddatetime,  LastCompressionMaxDate,  compressionrate,  currdatetime,  adjeasdatetime AdjDatetimeWithoutCap,  2 WeightToForceDefault  FROM Calcs  UNION  SELECT GETDATE() easdatetime,  GETDATE() lastupddatetime,  GETDATE() LastCompressionMaxDate,  1.0 compressionrate,  GETDATE() currdatetime,  GETDATE() AdjDatetimeWithoutCap,  1 WeightToForceDefault)

SELECT TOP 1  easdatetime,  lastupddatetime,  LastCompressionMaxDate,  compressionrate,  currdatetime,  AdjDatetimeWithoutCap  FROM UnionedWithDefaults  ORDER BY WeightToForceDefault DESC
);
GO

create function table_variable_vu_preparemstvf_3(@i int) returns @tableVar table
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
create function table_variable_vu_preparemstvf_dup_input_arg(@tableVar int) returns @tableVar table
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
create function table_variable_vu_preparemstvf_dup_local_arg(@i int) returns @tableVar table
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
create function table_variable_vu_preparemstvf_conditional(@i int) returns @tableVar table
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

-- BABEL-3967 - table variable in sp_executesql
create type table_variable_vu_type as table (a text not null, b int primary key, c int, d int)
go

create proc table_variable_vu_proc1 (@x table_variable_vu_type readonly) as
begin
	select tvp.b from @x tvp
end
go

create function table_variable_vu_tvp_function (@tvp table_variable_vu_type READONLY) returns int as 
begin 
	declare @result int 
	select @result = count(*) from @tvp 
	return @result 
end;
go

create schema table_variable_vu_schema
go

create type table_variable_vu_schema.table_variable_vu_type as table (a nvarchar, b ntext)
go

create function table_variable_vu_func2 () returns @SomeTable table (col1 int, col2 varchar(16))
AS
BEGIN
    INSERT @SomeTable SELECT 1234, 'abcd'
    RETURN
END
go

-- BABEL-4337 - nested TV, null check in tblname
CREATE TYPE tv_nested_type AS TABLE (a INT)
GO
CREATE FUNCTION tv_nested_func1 (@t tv_nested_type readonly) RETURNS @a TABLE (y INT) AS BEGIN; INSERT INTO @a SELECT x FROM @t; RETURN; END;
GO
CREATE FUNCTION tv_nested_func2 (@t tv_nested_type readonly) RETURNS @a TABLE (x INT) AS BEGIN; INSERT INTO @a SELECT y FROM tv_nested_func1(@t); RETURN; END;
GO

-- Cross Query Env Tests (BABEL-6268)
CREATE PROC p_tv_basic AS
BEGIN
    DECLARE @tv TABLE (id int, name varchar(30))
    INSERT INTO @tv VALUES (1, 'first')
    INSERT INTO @tv VALUES (2, 'second')
    UPDATE @tv SET name = 'updated' WHERE id = 1
    SELECT * FROM @tv
END
GO

CREATE PROC p_tv_delete AS
BEGIN
    DECLARE @tv TABLE (id int, status varchar(20), value int)
    INSERT INTO @tv VALUES (1, 'active', 100)
    INSERT INTO @tv VALUES (2, 'inactive', 200)
    INSERT INTO @tv VALUES (3, 'pending', 300)
    
    DELETE FROM @tv WHERE value > 250
    UPDATE @tv SET status = 'processed' WHERE id = 1
    INSERT INTO @tv VALUES (4, 'new', 150)
    
    SELECT * FROM @tv
END
GO

CREATE PROC p_tv_nested_inner AS
BEGIN
    DECLARE @inner_tv TABLE (id int, data varchar(50))
    INSERT INTO @inner_tv VALUES (1, 'from inner proc')
    INSERT INTO @inner_tv VALUES (2, 'inner data')
    SELECT 'Inner procedure:' as label
    SELECT * FROM @inner_tv
END
GO

CREATE PROC p_tv_nested_outer AS
BEGIN
    DECLARE @outer_tv TABLE (id int, info varchar(50))
    INSERT INTO @outer_tv VALUES (10, 'from outer proc')
    
    EXEC p_tv_nested_inner
    
    UPDATE @outer_tv SET info = 'updated in outer' WHERE id = 10
    INSERT INTO @outer_tv VALUES (20, 'outer data')
    
    SELECT 'Outer procedure:' as label
    SELECT * FROM @outer_tv
END
GO

CREATE PROC p_tv_transaction AS
BEGIN
    DECLARE @tv TABLE (id int, amount decimal(10,2))
    INSERT INTO @tv VALUES (1, 100.00)
    INSERT INTO @tv VALUES (2, 200.00)
    
    BEGIN TRAN
        UPDATE @tv SET amount = amount * 2
        INSERT INTO @tv VALUES (3, 300.00)
        DELETE FROM @tv WHERE id = 1
        SELECT 'Inside transaction:' as label
        SELECT * FROM @tv
    ROLLBACK
    
    -- Table variables are not affected by rollback
    SELECT 'After rollback (TV unaffected):' as label
    SELECT * FROM @tv
END
GO

CREATE PROC p_tv_multiple AS
BEGIN
    DECLARE @tv1 TABLE (id int, name varchar(20))
    DECLARE @tv2 TABLE (id int, ref_id int, value varchar(30))
    
    INSERT INTO @tv1 VALUES (1, 'first')
    INSERT INTO @tv1 VALUES (2, 'second')
    
    INSERT INTO @tv2 VALUES (10, 1, 'ref to first')
    INSERT INTO @tv2 VALUES (20, 2, 'ref to second')
    
    UPDATE @tv1 SET name = 'updated first' WHERE id = 1
    DELETE FROM @tv2 WHERE ref_id = 2
    
    SELECT 'Table Variable 1:' as label
    SELECT * FROM @tv1
    SELECT 'Table Variable 2:' as label
    SELECT * FROM @tv2
END
GO

CREATE PROC p_tv_error_handling AS
BEGIN
    DECLARE @tv TABLE (id int primary key, data varchar(20))
    INSERT INTO @tv VALUES (1, 'original')
    INSERT INTO @tv VALUES (2, 'valid insert')
    
    UPDATE @tv SET data = 'updated' WHERE id = 1
    
    BEGIN TRY
        INSERT INTO @tv VALUES (1, 'duplicate key') -- Should fail
    END TRY
    BEGIN CATCH
        INSERT INTO @tv VALUES (3, 'error handled')
        SELECT 'Error caught: ' + ERROR_MESSAGE() as error_info
    END CATCH
    
    SELECT * FROM @tv
END
GO

CREATE PROC p_tv_conditional AS
BEGIN
    DECLARE @tv TABLE (id int, status varchar(10), value int)
    INSERT INTO @tv VALUES (1, 'active', 50)
    INSERT INTO @tv VALUES (2, 'inactive', 150)
    INSERT INTO @tv VALUES (3, 'pending', 75)
    
    DECLARE @count int
    SELECT @count = COUNT(*) FROM @tv WHERE value > 100
    
    IF @count > 0
    BEGIN
        UPDATE @tv SET status = 'high_value' WHERE value > 100
        INSERT INTO @tv VALUES (4, 'new_high', 200)
    END
    ELSE
    BEGIN
        DELETE FROM @tv WHERE value < 60
    END
    
    SELECT * FROM @tv
END
GO

CREATE PROC p_tv_mixed_with_temp AS
BEGIN
    DECLARE @tv TABLE (id int, tv_data varchar(20))
    CREATE TABLE #temp_mixed (id int, temp_data varchar(20))
    
    INSERT INTO @tv VALUES (1, 'table variable')
    INSERT INTO #temp_mixed VALUES (1, 'temp table')
    
    UPDATE @tv SET tv_data = 'updated TV' WHERE id = 1
    UPDATE #temp_mixed SET temp_data = 'updated temp' WHERE id = 1
    
    INSERT INTO @tv VALUES (2, 'TV second')
    INSERT INTO #temp_mixed VALUES (2, 'temp second')
    
    SELECT 'Table Variable:' as label
    SELECT * FROM @tv
    SELECT 'Temp Table:' as label
    SELECT * FROM #temp_mixed
    
    DROP TABLE #temp_mixed
END
GO

CREATE PROC p_tv_scope_inner (@param int) AS
BEGIN
    DECLARE @inner_tv TABLE (id int, scope_info varchar(30))
    INSERT INTO @inner_tv VALUES (@param, 'inner scope')
    INSERT INTO @inner_tv VALUES (@param + 1, 'inner scope 2')
    SELECT 'Inner scope TV:' as label
    SELECT * FROM @inner_tv
END
GO

CREATE PROC p_tv_scope_outer AS
BEGIN
    DECLARE @outer_tv TABLE (id int, scope_info varchar(30))
    INSERT INTO @outer_tv VALUES (100, 'outer scope')
    
    SELECT 'Outer scope TV before inner call:' as label
    SELECT * FROM @outer_tv
    
    EXEC p_tv_scope_inner 200
    
    INSERT INTO @outer_tv VALUES (101, 'after inner call')
    SELECT 'Outer scope TV after inner call:' as label
    SELECT * FROM @outer_tv
END
GO