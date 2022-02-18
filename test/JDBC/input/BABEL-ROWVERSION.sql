EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- Test casting functions
-- (var)binary <-> rowversion
SELECT CAST(CAST(0xfe AS binary(8)) AS rowversion),
       CAST(CAST(0xfe AS varbinary(8)) AS rowversion),
       CAST(CAST(0xfe AS rowversion) AS binary(8)),
       CAST(CAST(0xfe AS rowversion) AS varbinary(8));
GO

-- varchar -> rowversion
SELECT CAST(CAST('abc' AS varchar) AS rowversion),
       CAST(CAST('abc' AS char(3)) AS rowversion);
GO

-- int <-> rowversion
SELECT CAST(CAST(20 AS tinyint) AS rowversion),
       CAST(CAST(20 AS smallint) AS rowversion),
       CAST(CAST(20 AS int) AS rowversion),
       CAST(CAST(20 AS bigint) AS rowversion),
       CAST(CAST(20 AS rowversion) AS tinyint),
       CAST(CAST(20 AS rowversion) AS smallint),
       CAST(CAST(20 AS rowversion) AS int),
       CAST(CAST(20 AS rowversion) AS bigint);
GO

-- Create table with rowversion column
create table t1(id int, rv rowversion);
go

-- A table can only have one rowversion column
create table t2(id int, rv1 rowversion, rv2 rowversion);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

-- Insert into a rowversion column is not allowed
insert into t1(id, rv) values(1,2);
go

-- Valid insert
insert into t1(id) values(1);
insert into t1(id) values(2);
go

-- Varify that rowversion column value is not null
select IIF(rv = NULL, 'null', 'not-null') from t1;
go

-- Test with CTE
with mycte (a, b)
as (select t1.* from t1)
select case when x.b = y.rv then 'equal' else 'not-equal' end
				from mycte x inner join t1 y on x.a = y.id;
go

-- Test view
create view v1 as select id, rv from t1;
go
select case when x.rv = y.rv then 'equal' else 'not-equal' end
				from v1 x inner join t1 y on x.id = y.id;
go

drop view v1;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- Test with tvf
create function tvf(@x int) returns table as return select id, rv from t1;
go

select case when f.rv = t.rv then 'equal' else 'not-equal' end
                from tvf(1) f inner join t1 t on f.id = t.id;
go

drop function tvf;
go

-- function return type can not be rowversion
create function tvf(@x int) returns rowversion as begin return cast(@x as rowversion) end;
go

-- function parameter types can not be rowversion
create function tvf(@x int, @y rowversion) returns int as begin return @x end;
go

-- Updating a rowversion column is not allowed
update t1 set rv = 2 where id = 1;
go

-- Updating a row should result in a new value for the rowversion column
declare @prev_rv rowversion;
select @prev_rv = rv from t1 where id = 2;
update t1 set id = 3 where id = 2;
select case when rv > @prev_rv then 'ok' else 'not-ok' end from t1 where id = 3;
go

-- Test SELECT-INTO
select * into t2 from t1;
go
select case when x.rv = y.rv then 'equal' else 'not-equal' end
                from t1 x inner join t2 y on x.id = y.id;
go

-- SELECT INTO should not result in multiple rowversion columns in new table
select * into t3 from t1, t2;
go

-- Cleanup
drop table t1;
drop table t2;
go

-- NULL, NOT-NULL, check constraints are allowed on rowversion column
create table t1(id int, rv rowversion null);
go
drop table t1;
go

create table t1(id int, rv rowversion not null);
go
drop table t1;
go

create table t1(id int, rv rowversion check(rv > 50));
go
drop table t1;
go

-- All other constraints should not be allowed
create table t1(id int, rv rowversion default 50);
go

create table t1(id int, rv rowversion primary key);
go

create table t1(a int primary key);
go

create table t2(id int, [RV] rowversion, foreign key(rv) references t1(a));
go

drop table t1;
go

create table t1(id int, rv rowversion not null unique);
go

create table t1(id int, rv rowversion);
go

-- Can't add default constraint on rowversion column.
alter table t1 add constraint df DEFAULT 2 for rv;
go

drop table t1;
go

-- creating computed column from rowversion column is allowed
create table t1(id int, rv rowversion, rv2 as (rv+2));
go
drop table t1;
go

create table t1([ID] int, [RV] rowversion);
go

-- Changing type of a column to rowversion should not be allowed
alter table t1 alter column id rowversion;
go

-- Changing type of a rowversion column is not allowed
alter table t1 alter column rv int;
go

drop table t1;
go

-- Test dbts
create table t1(id int, rv rowversion);
go
declare @last_dbts rowversion, @cur_dbts rowversion;
set @last_dbts = @@dbts;
insert into t1(id) values(1);
set @cur_dbts = @@dbts;
select case when (rv >= @last_dbts) and (@cur_dbts > rv) then 'ok'
                else 'not-ok' end from t1 where id = 1;
go

drop table t1;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
