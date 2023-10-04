EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- Test casting functions
-- (var)binary <-> timestamp
SELECT CAST(CAST(0xfe AS binary(8)) AS timestamp),
       CAST(CAST(0xfe AS varbinary(8)) AS timestamp),
       CAST(CAST(0xfe AS timestamp) AS binary(8)),
       CAST(CAST(0xfe AS timestamp) AS varbinary(8));
GO

-- varchar -> timestamp
SELECT CAST(CAST('abc' AS varchar) AS timestamp),
       CAST(CAST('abc' AS char(3)) AS timestamp);
GO

-- int <-> timestamp
SELECT CAST(CAST(20 AS tinyint) AS timestamp),
       CAST(CAST(20 AS smallint) AS timestamp),
       CAST(CAST(20 AS int) AS timestamp),
       CAST(CAST(20 AS bigint) AS timestamp),
       CAST(CAST(20 AS timestamp) AS tinyint),
       CAST(CAST(20 AS timestamp) AS smallint),
       CAST(CAST(20 AS timestamp) AS int),
       CAST(CAST(20 AS timestamp) AS bigint);
GO

-- Create table with timestamp column
create table t1(id int, timestamp timestamp);
go

drop table t1;
go

-- Create timestamp column without column name
create table t1(id int, timestamp);
go

-- A table can only have one timestamp column
create table t2(id int, timestamp, timestamp);
go

-- Insert into a timestamp column is not allowed
insert into t1(id, timestamp) values(1,2);
go

-- Valid insert
insert into t1(id) values(1);
insert into t1(id) values(2);
go

-- Varify that rowversion column value is not null
select IIF(timestamp = NULL, 'null', 'not null') from t1;
go

-- Test with CTE
with mycte (a, b)
as (select t1.* from t1)
select case when x.b = y.timestamp then 'equal' else 'not-equal' end
				from mycte x inner join t1 y on x.a = y.id;
go

-- Test view
create view v1 as select id, timestamp from t1;
go
select case when x.timestamp = y.timestamp then 'equal' else 'not-equal' end
				from v1 x inner join t1 y on x.id = y.id;
go

drop view v1;
go

-- Test with tvf
create function tvf(@x int) returns table as return select id, timestamp from t1;
go

select case when f.timestamp = t.timestamp then 'equal' else 'not-equal' end
                from tvf(1) f inner join t1 t on f.id = t.id;
go

drop function tvf;
go

-- function return type can not be timestamp
create function tvf(@x int) returns timestamp as begin return cast(@x as timestamp) end;
go

-- function parameter types can not be timestamp
create function tvf(@x int, @y timestamp) returns int as begin return @x end;
go

-- Updating a timestamp column is not allowed
update t1 set timestamp = 2 where id = 1;
go

-- Updating a row should result in a new value for the timestamp column
declare @prev_timestamp timestamp;
select @prev_timestamp = timestamp from t1 where id = 2;
update t1 set id = 3 where id = 2;
select case when timestamp > @prev_timestamp then 'ok' else 'not ok' end from t1 where id = 3;
go

-- Test SELECT INTO
select * into t2 from t1;
go
select case when x.timestamp = y.timestamp then 'equal' else 'not-equal' end
                from t1 x inner join t2 y on x.id = y.id;
go

-- SELECT INTO should not result in multiple timestamp columns in new table
select * into t3 from t1, t2;
go

-- Cleanup
drop table t1;
drop table t2;
go

-- NULL, NOT-NULL, check constraints are allowed on rowversion column
create table t1(id int, timestamp null);
go
drop table t1;
go

create table t1(id int, timestamp not null);
go
drop table t1;
go

create table t1(id int, timestamp check(timestamp > 50));
go
drop table t1;
go

-- All other constraints should not be allowed
create table t1(id int, timestamp default 50);
go

create table t1(id int, timestamp primary key);
go

create table t1(a int primary key);
go

create table t2(id int, timestamp, foreign key(timestamp) references t1(a));
go

drop table t1;
go

create table t1(id int, timestamp not null unique);
go

create table t1(id int, timestamp);
go

-- Can't add default constraint on timestamp column.
alter table t1 add constraint df DEFAULT 2 for timestamp;
go

drop table t1;
go

-- creating computed column from rowversion column is allowed
create table t1(id int, timestamp, timestamp2 as (timestamp+2));
go

drop table t1;
go

create table t1(id int, timestamp);
go

-- Changing type of a column to timestamp should not be allowed
alter table t1 alter column id timestamp;
go

-- Changing type of a timestamp column is not allowed
alter table t1 alter column timestamp int;
go

drop table t1;
go

-- Test timestamp column in create type statement
create type tbl_type as table (id int, timestamp timestamp);
go

drop type tbl_type;
go

-- without column name
create type tbl_type as table (id int, timestamp);
go

drop type tbl_type;
go

-- Test timestamp column in declare table type statment
declare @tbl table (a int, timestamp timestamp);
go

-- without column name
declare @tbl table (a int, timestamp);
go

-- Test dbts
create table t1(id int, timestamp);
go
declare @last_dbts timestamp, @cur_dbts timestamp;
set @last_dbts = @@dbts;
insert into t1(id) values(1);
set @cur_dbts = @@dbts;
select case when (timestamp >= @last_dbts) and (@cur_dbts > timestamp) then 'ok'
                else 'not-ok' end from t1 where id = 1;
go

drop table t1;
go

-- Test BABEL-4433
CREATE TABLE t( c timestamp NOT NULL, PRIMARY KEY ( [ID] ASC))
GO


EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
