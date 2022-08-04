use master;
go

create database constraint_table_usage_db;
go

use constraint_table_usage_db;
go

create table constraint_table_usage_tb1(name char(10) NOT NULL, id char(10) NOT NULL, UNIQUE(name,id));
go

select * from information_schema.constraint_table_usage where table_name = 'constraint_table_usage_tb1';
go

create table constraint_table_usage_tb2(book char(10), subject char(10) NOT NULL CONSTRAINT TEST_CONST PRIMARY KEY);
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_tb%';
go

create table constraint_table_usage_tb3(name char(10) NOT NULL, id char(10) NOT NULL, PRIMARY KEY(name, id));
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_tb%';
go

create table constraint_table_usage_tb4(movie char(10), description char(1000));
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_tb%';
go

drop table constraint_table_usage_tb1;
go

drop table constraint_table_usage_tb2;
go

drop table constraint_table_usage_tb3;
go 

drop table constraint_table_usage_tb4;
go 

use master;
go 

drop database constraint_table_usage_db;
go 