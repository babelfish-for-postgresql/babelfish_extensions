-- create a new table BABEL_4926 1
create table BABEL_4926(ID int);
go
select ID from BABEL_4926;
go
-- Create a new table BABEL_4926_REPO with column ID 
select ID into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column ID
create index IDX_REPRODUCTION on BABEL_4926_REPO(ID);
go
-- output is the lowercase name,original_name
select attname,attoptions as ID from pg_attribute where attrelid = (select oid from pg_class where relname = 'babel_4926_repo');
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go



-- create table with multiple columns with both mixed case names 2
create table BABEL_4926(numb int,Numb1 int,ColuM int);
go
-- select the columns from the table
select numb,Numb1,ColuM from BABEL_4926;
go
-- create the BABEL_4926_REPO and select the column from BABEL_4926 
select numb,Numb1,ColuM into BABEL_4926_REPO from BABEL_4926;
go
-- indexing over the columns of BABEL_4926_REPO
create index IDX_REPRODUCTION on BABEL_4926_REPO(numb,Numb1,ColuM);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attrelid = (select oid from pg_class where relname = 'babel_4926_repo');
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go

-- create a table when the column name is already in lowercase 3
create table BABEL_4926(numb int);
go
select numb from BABEL_4926;
go
-- Create a new table BABEL_4926_REPO with column ID 
select numb into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column ID
create index IDX_REPRODUCTION on BABEL_4926_REPO(numb);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attrelid = (select oid from pg_class where relname = 'babel_4926_repo');
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go

-- create table with multiple columns using * with both mixed case names 4
create table BABEL_4926(numb int,Numb1 int,ColuM int);
go
-- select the columns from the table
select numb,Numb1,ColuM from BABEL_4926;
go
-- create the BABEL_4926_REPO and select the column from BABEL_4926 using *
select * into BABEL_4926_REPO from BABEL_4926;
go
-- indexing over the columns of BABEL_4926_REPO
create index IDX_REPRODUCTION on BABEL_4926_REPO(numb,Numb1,ColuM);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attrelid = (select oid from pg_class where relname = 'babel_4926_repo');
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go

-- create a new table BABEL_4926 with changing the name of column while making new table 5
create table BABEL_4926(ID int);
go
select ID from BABEL_4926;
go
-- Create a new table BABEL_4926_REPO with column ID 
select ID as COlumn__1 into BABEL_4926_REPO from BABEL_4926;
go
-- Indexing over column ID
create index IDX_REPRODUCTION on BABEL_4926_REPO(COlumn__1);
go
-- output is the lowercase name,original_name
select attname,attoptions from pg_attribute where attrelid = (select oid from pg_class where relname = 'babel_4926_repo');
go
-- dropping the table BABEL_4926
drop table BABEL_4926;
go
-- dropping the table BABEL_4926_REPO
drop table BABEL_4926_REPO;
go