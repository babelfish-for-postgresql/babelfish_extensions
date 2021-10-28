-- schema
create schema schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;

-- table
create table schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij.table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij(
  col_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij integer
);
GO

insert into schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij.table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij values (42);
GO

-- accessed via original name
select * from schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij.table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;
GO

-- accessed via truncated name
select * from schema_longer_than_63_0abcdefgi2f5cbde477221faa47c8d08e1d6bbb27.table_longer_than_63_0abcdefgijc2ed7b983a352405e4e26c711bd071bf;
GO

-- monitoring with original name
select count(*) from pg_catalog.pg_class where relname = 'table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij';
GO

-- monitoring with truncated name
select count(*) from pg_catalog.pg_class where relname = 'table_longer_than_63_0abcdefgijc2ed7b983a352405e4e26c711bd071bf';
GO

-- object_id(<table_name>) for both original namd shortend name
select (case when object_id('table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij') is not null then 'exists' else 'error' end) result;
GO

select (case when object_id('table_longer_than_63_0abcdefgijc2ed7b983a352405e4e26c711bd071bf') is not null then 'exists' else 'error' end) result;
GO

select (case when object_id('table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij') = object_id('table_longer_than_63_0abcdefgijc2ed7b983a352405e4e26c711bd071bf') then 'correct' else 'error' end) result;
GO

-- object_id(<schema_name>.<table_name>) for both original namd shortend name
select (case when object_id('schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij.table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij') is not null then 'exists' else 'error' end) result;
GO

select (case when object_id('schema_longer_than_63_0abcdefgi2f5cbde477221faa47c8d08e1d6bbb27.table_longer_than_63_0abcdefgijc2ed7b983a352405e4e26c711bd071bf') is not null then 'exists' else 'error' end) result;
GO

select (case when object_id('schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij.table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij') = object_id('schema_longer_than_63_0abcdefgi2f5cbde477221faa47c8d08e1d6bbb27.table_longer_than_63_0abcdefgijc2ed7b983a352405e4e26c711bd071bf') then 'correct' else 'error' end) result;
GO

drop table schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij.table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;

drop schema schema_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;
GO

create table table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij(
  col_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij integer
);
GO

insert into table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij values (42);
GO

-- char/varchar/text -> name casting
create table table_name_t(c1 char(128) COLLATE C, c2 varchar(128) COLLATE C, c3 text COLLATE C);
GO
insert into table_name_t values (
  'table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij',
  'table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij',
  'table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij'
);
GO
-- note: use explicit cast here. since implicit cast is not added. there is the same issue in default PG truncation behavior
select count(*) from pg_catalog.pg_class where relname in (SELECT cast (c1 as name) from table_name_t);
GO
select count(*) from pg_catalog.pg_class where relname in (SELECT cast (c2 as name) from table_name_t);
GO
select count(*) from pg_catalog.pg_class where relname in (SELECT cast (c3 as name) from table_name_t);
GO
drop table table_name_t;
GO

-- function
create function func_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij(
  @argname_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij int)
RETURNS integer
AS
BEGIN
  return (select @argname_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij + 1);
END;
GO

-- view
create view view_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij as
select func_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij(
  col_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij)
from table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;
GO

select * from view_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;
GO

-- create table with the same name
create table table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij(
  col_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij integer
);
GO

-- create table with a different name but have same prefix
create table table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghik(
  col_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij integer
);
GO

-- disable multi-bytes test for now since it should depend on collation setting
-- table name with multi-byte characters
--create table tλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ(a int);
--GO
--insert into tλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ values (42);
--GO
--select * from tλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO

--create table ttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ(a int);
--GO
--insert into ttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ values (42);
--GO
--select * from ttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO

--create table tttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ(a int);
--GO
--insert into tttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ values (42);
--GO
--select * from tttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO

--create table ttttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ(a int);
--GO
--insert into ttttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ values (42);
--GO
--select * from ttttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO

drop view view_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;
GO

drop function func_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;
GO

drop table table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghij;
GO

drop table table_longer_than_63_0abcdefgij1abcdefgij2abcdefgij3abcdefgij4abcdefgij5abcdefgij6abcdefgij7abcdefgij8abcdefghij9abcdefghik;
GO

--drop table tλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO
--drop table ttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO
--drop table tttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO
--drop table ttttλλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ_λλλλλ;
--GO

create table babel_1200_t(id int, [BALA_#] varchar(40));
GO
insert into babel_1200_t values (42, 'aaa'), (666, 'bbb');
GO

create procedure babel_1200_proc
@balano as varchar(40)
as
begin
  select r.ID from babel_1200_t r where r.BALA_#=@balano
end
go

-- currently, syntax error
--exec babel_1200_proc 'aaa'
--GO

create procedure babel_1200_proc_quoted
@balano as varchar(40)
as
begin
  select r.ID from babel_1200_t r where r.[BALA_#]=@balano
end
go

exec babel_1200_proc_quoted 'aaa'
GO

drop procedure babel_1200_proc_quoted;
GO

drop procedure babel_1200_proc;
GO

drop table babel_1200_t;
GO
