
-- create a new table select_into 1
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- create table with multiple columns with both mixed case names 2
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- create a table when the column name is already in lowercase 3
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- create table with multiple columns using * with both mixed case names 4
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- create a new table select_into with changing the name of column while making new table 5
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- create a new table select_into with changing the name of column while making new table(testing compatibility of function query in select into statement) 6
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go
drop function if exists select_into_double_function;
go

-- create a new table select_into 7
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

--dependent objects
create index IDX_REPRODUCTION on select_into_pre_exist_repro(select_into_pre_exist_COL);
go
drop table if exists select_into_pre_exist;
go
drop table if exists select_into_pre_exist_repro;
go
-- column length >=64 todo
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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go

-- test for IDENTITY Function

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
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute join pg_class on pg_attribute.attrelid=pg_class.oid where pg_class.relname='select_into_repo' and attname like '%select_into%'order by attname asc;
go
-- dropping the table select_into
drop table if exists select_into;
go
-- dropping the table select_into_REPO
drop table if exists select_into_REPO;
go