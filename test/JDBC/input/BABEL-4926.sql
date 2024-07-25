-- create a new table PROB
create table PROB(ID int);
go
select ID from PROB;
go
-- Create a new table REPRO with column ID 
select ID into REPRO from PROB;
go
-- Indexing over column ID
create index IDX_REPRODUCTION on REPRO(ID);
go
--extract the oid using pg_class
select attname as ID from pg_attribute where attrelid = (select oid from pg_class where relname = 'repro');
go
-- dropping the table PROB
drop table PROB;
go
-- dropping the table REPRO
drop table REPRO;
go



-- create table with multiple columns with both mixed case names
create table PROB(numb int,Numb1 int,ColuM int);
go
-- select the columns from the table
select numb,Numb1,ColuM from prob;
go
-- create the REPRO and select the column from PROB 
select numb,Numb1,ColuM into REPRO from PROB;
go
-- indexing over the columns of REPRO
create index IDX_REPRODUCTION on REPRO(numb,Numb1,ColuM);
go
--extract the oid using pg_class
select attname as numb from pg_attribute where attrelid = (select oid from pg_class where relname = 'repro');
go
-- dropping the table PROB
drop table PROB;
go
-- dropping the table REPRO
drop table REPRO;
go

-- create a table when the column name is already in lowercase
create table PROB(numb int);
go
select numb from PROB;
go
-- Create a new table REPRO with column ID 
select numb into REPRO from PROB;
go
-- Indexing over column ID
create index IDX_REPRODUCTION on REPRO(numb);
go
-- dropping the table PROB
drop table PROB;
go
-- dropping the table REPRO
drop table REPRO;
go
