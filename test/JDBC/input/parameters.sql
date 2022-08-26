drop database if exists db_parameters;
go

create database db_parameters;
go

Use db_parameters;
go

select * from information_schema.parameters where specific_schema not like 'sys';
go

drop table if exists parameters_tb1;
go

create table parameters_tb1(arg1 int, arg2 char, arg3 varchar);
go

drop view if exists parameters_v1;
go

create view parameters_v1 as select * from parameters_tb1;
go

select * from information_schema.parameters where specific_schema not like 'sys';
go

drop view parameters_v1
go

drop table parameters_tb1
go

use master;
go

drop database db_parameters;
go 