-- create a new table BABEL_4926 1
create table BABEL_4926(babel_4926_COL int);
go
select babel_4926_COL from BABEL_4926;
go
-- Create a new table BABEL_4926_REPO with column babel_4926_COL 
select babel_4926_COL into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column babel_4926_COL
create index IDX_REPRODUCTION on BABEL_4926_REPO(babel_4926_COL);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attname like '%babel_4926%' and attrelid = (select oid from pg_class where relname = 'babel_4926_repo') order by attname asc;
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go



-- create table with multiple columns with both mixed case names 2
create table BABEL_4926(babel_4926_col1 int,babel_4926_Col2 int,babel_4926_COL int);
go
-- select the columns from the table
select babel_4926_col1,babel_4926_Col2,babel_4926_COL from BABEL_4926;
go
-- create the BABEL_4926_REPO and select the column from BABEL_4926 
select babel_4926_col1,babel_4926_Col2,babel_4926_COL into BABEL_4926_REPO from BABEL_4926;
go
-- indexing over the columns of BABEL_4926_REPO
create index IDX_REPRODUCTION on BABEL_4926_REPO(babel_4926_col1,babel_4926_Col2,babel_4926_COL);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attname like '%babel_4926%' and attrelid = (select oid from pg_class where relname = 'babel_4926_repo') order by attname asc;
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go

-- create a table when the column name is already in lowercase 3
create table BABEL_4926(babel_4926_col int);
go
select babel_4926_col from BABEL_4926;
go
-- Create a new table BABEL_4926_REPO with column babel_4926_col
select babel_4926_col into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column babel_4926_col
create index IDX_REPRODUCTION on BABEL_4926_REPO(babel_4926_col);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attname like '%babel_4926%' and attrelid = (select oid from pg_class where relname = 'babel_4926_repo') order by attname asc;
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go

-- create table with multiple columns using * with both mixed case names 4
create table BABEL_4926(babel_4926_col1 int,babel_4926_Col2 int,babel_4926_COL int);
go
-- select the columns from the table
select babel_4926_col1,babel_4926_Col2,babel_4926_COL from BABEL_4926;
go
-- create the BABEL_4926_REPO and select the column from BABEL_4926 using *
select * into BABEL_4926_REPO from BABEL_4926;
go
-- indexing over the columns of BABEL_4926_REPO
create index IDX_REPRODUCTION on BABEL_4926_REPO(babel_4926_col1,babel_4926_Col2,babel_4926_COL);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attname like '%babel_4926%' and attrelid = (select oid from pg_class where relname = 'babel_4926_repo') order by attname asc;
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go

-- create a new table BABEL_4926 with changing the name of column while making new table 5
create table BABEL_4926(babel_4926_COL int);
go
select babel_4926_COL from BABEL_4926;
go
-- Create a new table BABEL_4926_REPO with column babel_4926_COL
select babel_4926_COL as babel_4926_COl1 into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column babel_4926_COL1
create index IDX_REPRODUCTION on BABEL_4926_REPO(babel_4926_COl1);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attname like '%babel_4926%' and attrelid = (select oid from pg_class where relname = 'babel_4926_repo') order by attname asc;
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go
-- create a new table BABEL_4926 with changing the name of column while making new table(testing compatibility of function query in select into statement) 6
create table BABEL_4926(babel_4926_COL int);
go
select babel_4926_COL from BABEL_4926;
go
-- create a new function to double the value
CREATE FUNCTION dbo.babel_4926_double_function (@in INT) RETURNS INT
AS
BEGIN
    RETURN (2 * @in);
END;
go
-- Create a new table BABEL_4926_REPO with column babel_4926_COL1 using function
select babel_4926_double_function(babel_4926_COL) as babel_4926_COL1 into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column babel_4926_COL1
create index IDX_REPRODUCTION on BABEL_4926_REPO(babel_4926_COl1);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attname like '%babel_4926%' and attrelid = (select oid from pg_class where relname = 'babel_4926_repo') order by attname asc;
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go
drop function babel_4926_double_function;
go

-- create a new table BABEL_4926 7
create table BABEL_4926([babel_4926_COL$] int);
go
select [babel_4926_COL$] from BABEL_4926; 
go
-- Create a new table BABEL_4926_REPO with column babel_4926_COL 
select [babel_4926_COL$] as [babel_4926_COL1$] into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column babel_4926_COL
create index IDX_REPRODUCTION on BABEL_4926_REPO([babel_4926_COL1$]);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attname like '%babel_4926%' and attrelid = (select oid from pg_class where relname = 'babel_4926_repo') order by attname asc;
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go