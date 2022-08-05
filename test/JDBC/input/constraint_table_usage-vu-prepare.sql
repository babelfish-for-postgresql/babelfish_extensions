use master;
go

create database constraint_table_usage_vu_prepare_db;
go

use constraint_table_usage_vu_prepare_db;
go

create table constraint_table_usage_vu_prepare_tb1(name char(10) NOT NULL, id char(10) NOT NULL, UNIQUE(name,id));
go

create table constraint_table_usage_vu_prepare_tb2(book char(10), subject char(10) NOT NULL CONSTRAINT TEST_CONST PRIMARY KEY);
go

create table constraint_table_usage_vu_prepare_tb3(name char(10) NOT NULL, id char(10) NOT NULL, PRIMARY KEY(name, id));
go

create table constraint_table_usage_vu_prepare_tb4(movie char(10), description char(1000));
go

use master;
go