
-- Test Case 1: create a new table select_into 1
create table select_into(select_into_COL int);
go
select select_into_COL from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL 
select select_into_COL into select_into_REPO from select_into;
go
-- Indexing over column select_into_COL
create index IDX_REPRODUCTION on select_into_REPO(select_into_COL);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 2: create table with multiple columns with both mixed case names 2
create table select_into(select_into_col1 int,select_into_Col2 int,select_into_COL int);
go
-- select the columns from the table
select select_into_col1,select_into_Col2,select_into_COL from select_into;
go
-- create the select_into_REPO and select the column from select_into 
select select_into_col1,select_into_Col2,select_into_COL into select_into_REPO from select_into;
go
-- indexing over the columns of select_into_REPO
create index IDX_REPRODUCTION on select_into_REPO(select_into_col1,select_into_Col2,select_into_COL);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 3: create a table when the column name is already in lowercase 3
create table select_into(select_into_col int);
go
select select_into_col from select_into;
go
-- Create a new table select_into_REPO with column select_into_col
select select_into_col into select_into_REPO from select_into;
go
-- Indexing over column select_into_col
create index IDX_REPRODUCTION on select_into_REPO(select_into_col);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 4: create table with multiple columns using * with both mixed case names 4
create table select_into(select_into_col1 int,select_into_Col2 int,select_into_COL int);
go
-- select the columns from the table
select select_into_col1,select_into_Col2,select_into_COL from select_into;
go
-- create the select_into_REPO and select the column from select_into using *
select * into select_into_REPO from select_into;
go
-- indexing over the columns of select_into_REPO
create index IDX_REPRODUCTION on select_into_REPO(select_into_col1,select_into_Col2,select_into_COL);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 5: create a new table select_into with changing the name of column while making new table 5
create table select_into(select_into_COL int);
go
select select_into_COL from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL
select select_into_COL as select_into_COl1 into select_into_REPO from select_into;
go
-- Indexing over column select_into_COL1
create index IDX_REPRODUCTION on select_into_REPO(select_into_COl1);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 6: create a new table select_into with changing the name of column while making new table(testing compatibility of function query in select into statement) 6
create table select_into(select_into_COL int);
go
select select_into_COL from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL1 using function
select select_into_double_function(select_into_COL) as select_into_COL1 into select_into_REPO from select_into;
go
-- Indexing over column select_into_COL1
create index IDX_REPRODUCTION on select_into_REPO(select_into_COl1);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go
drop function if exists select_into_double_function;
go

-- Test Case 7: create a new table select_into 
create table select_into([select_into_COL$] int);
go
select [select_into_COL$] from select_into; 
go
-- Create a new table select_into_REPO with column select_into_COL 
select [select_into_COL$] as [select_into_COL1$] into select_into_REPO from select_into;
go
-- Indexing over column select_into_COL
create index IDX_REPRODUCTION on select_into_REPO([select_into_COL1$]);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

--Test Case 8: dependent objects
create index IDX_REPRODUCTION on select_into_pre_exist_repro(select_into_pre_exist_COL);
go
drop table if exists select_into_pre_exist;
go
drop table if exists select_into_pre_exist_repro;
go
-- Test Case 9: column length >=64 todo
create table select_into(select_into_COL_select_into_COL_select_into_COL_select_into_COL_ int);
go
select select_into_COL_select_into_COL_select_into_COL_select_into_COL_ from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL 
select select_into_COL_select_into_COL_select_into_COL_select_into_COL_ into select_into_REPO from select_into;
go
-- Indexing over column select_into_COL
create index IDX_REPRODUCTION on select_into_REPO(select_into_COL_select_into_COL_select_into_COL_select_into_COL_);
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 10: test for IDENTITY Function

sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_identity_function','ignore'
go
-- create a new table select_into 1
create table select_into(select_into_COL int);
go
select select_into_COL from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL -- throws error
select identity(int,1,1) as select_into_COL,* into select_into_REPO from select_into
go
-- adding column sto repro -- should work
select identity(int,1,1) as select_into_COL1,* into select_into_REPO from select_into
go
select * from select_into_REPO
go
-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 11: ALTER TABLE...ALTER COLUMN
create table select_into(select_into_COL int);
go
select select_into_COL from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL
select select_into_COL into select_into_REPO from select_into;
go
-- Alter the column data type
alter table select_into_REPO alter column select_into_COL varchar(10);
go
-- view columns of select_into_REPO
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 12: ALTER TABLE...ADD CONSTRAINT
create table select_into(select_into_COL int);
go
select select_into_COL from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL
select select_into_COL into select_into_REPO from select_into;
go
-- Add a check constraint
alter table select_into_REPO add constraint CHK_SelectIntoCol check (select_into_COL > 0);
go
-- view columns of select_into_REPO
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 13: CREATE UNIQUE INDEX
create table select_into(select_into_COL int);
go
select select_into_COL from select_into;
go
-- Create a new table select_into_REPO with column select_into_COL
select select_into_COL into select_into_REPO from select_into;
go
-- Create a unique index
create unique index UNQ_SelectIntoCol on select_into_REPO(select_into_COL);
go
-- view columns of select_into_REPO
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 14: ALTER TABLE...DROP COLUMN
create table select_into(select_into_COL int, select_into_COL2 int);
go
select select_into_COL, select_into_COL2 from select_into;
go
-- Create a new table select_into_REPO with columns select_into_COL and select_into_COL2
select select_into_COL, select_into_COL2 into select_into_REPO from select_into;
go
-- Drop the column select_into_COL2
alter table select_into_REPO drop column select_into_COL2;
go
-- view columns of select_into_REPO
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go
-- Test Case 15: Table-Returning Function
create table select_into(select_into_COL int);
go
insert into select_into values (1), (2), (3);
go

-- Create a table-returning function
create function dbo.GetSelectIntoData()
returns @result table
(
    select_into_COL int
)
as
begin
    insert into @result
    select select_into_COL
    from select_into;
    return;
end
go

-- Create a new table select_into_REPO with column select_into_COL using the table-returning function
select select_into_COL into select_into_REPO from dbo.GetSelectIntoData();
go

-- Check the data in select_into_REPO
select * from select_into_REPO;
go

-- Indexing over column select_into_COL
create index IDX_REPRODUCTION on select_into_REPO(select_into_COL);
go

-- output is the lowercase name
select attname from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go
-- dropping the table select_into
drop table if exists select_into;
go

-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- dropping the function
drop function if exists dbo.GetSelectIntoData;
go
-- Test Case 16: Multibyte Column Name (Chinese)
create table select_into(中文_COL int);
go
insert into select_into values (1), (2), (3);
go
select 中文_COL from select_into;
go

-- Create a new table select_into_REPO with column 中文_COL
select 中文_COL into select_into_REPO from select_into;
go

-- Check the data in select_into_REPO
select * from select_into_REPO;
go

-- Indexing over column 中文_COL
create index IDX_REPRODUCTION on select_into_REPO(中文_COL);
go

-- output is the lowercase name
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go
-- dropping the table select_into
drop table if exists select_into;
go

-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go
-- Test Case 17: Multibyte Column Name (Chinese) more then 64 characters
create table select_into(中文_COL_select_into_select_into_select_into_select_into_select_into_select_into_select_into_select_into int);
go
insert into select_into values (1), (2), (3);
go
select 中文_COL_select_into_select_into_select_into_select_into_select_into_select_into_select_into_select_into from select_into;
go

-- Create a new table select_into_REPO with column 中文_COL_select_into_select_into_select_into_select_into_select_into_select_into_select_into_select_into
select 中文_COL_select_into_select_into_select_into_select_into_select_into_select_into_select_into_select_into into select_into_REPO from select_into;
go

-- Check the data in select_into_REPO
select * from select_into_REPO;
go

-- Indexing over column 中文_COL_select_into_select_into_select_into_select_into_select_into_select_into_select_into_select_into
create index IDX_REPRODUCTION on select_into_REPO(中文_COL_select_into_select_into_select_into_select_into_select_into_select_into_select_into_select_into);
go

-- output is the lowercase name
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go
-- dropping the table select_into
drop table if exists select_into;
go

-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 17: table with multi-part names
create table dbo.select_into(select_into_COL int);
go
insert into dbo.select_into values (1), (2), (3);
go
select select_into_COL from dbo.select_into;
go
-- Create a new table select_into_REPO with column select_into_COL using multi-part name
select dbo.select_into.select_into_COL into select_into_REPO from dbo.select_into;
go

-- Check the data in select_into_REPO
select * from select_into_REPO;
go

-- Indexing over column select_into_COL
create index IDX_REPRODUCTION on select_into_REPO(select_into_COL);
go

-- output is the lowercase name
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go

-- dropping the table dbo.select_into
drop table if exists dbo.select_into;
go

-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- Test Case 18: table with multi-part names and clumn name length > 64
create table dbo.select_into(select_into_COL_select_into_COL_Col_length_greater_then_sixty_four int);
go
insert into dbo.select_into values (1), (2), (3);
go
select select_into_COL_select_into_COL_Col_length_greater_then_sixty_four from dbo.select_into;
go
-- Create a new table select_into_REPO with column select_into_COL_select_into_COL_Col_length_greater_then_sixty_four using multi-part name
select dbo.select_into.select_into_COL_select_into_COL_Col_length_greater_then_sixty_four into select_into_REPO from dbo.select_into;
go

-- Check the data in select_into_REPO
select * from select_into_REPO;
go

-- Indexing over column select_into_COL_select_into_COL_Col_length_greater_then_sixty_four
create index IDX_REPRODUCTION on select_into_REPO(select_into_COL_select_into_COL_Col_length_greater_then_sixty_four);
go

-- output is the lowercase name
select column_name from information_schema.columns where table_name = 'select_into_REPO'
go

-- dropping the table dbo.select_into
drop table if exists dbo.select_into;
go

-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go