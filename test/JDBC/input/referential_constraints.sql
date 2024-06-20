drop database if exists db_referential_constraints;
go

create database db_referential_constraints;
go

Use db_referential_constraints;
go

select * from information_schema.referential_constraints where constraint_schema not like 'sys%';
go

drop table if exists referential_constraints_tb1;
go

create table referential_constraints_tb1(arg1 int, arg2 char, arg3 varchar);
go

drop view if exists referential_constraints_v1;
go

create view referential_constraints_v1 as select * from referential_constraints_tb1;
go

select * from information_schema.referential_constraints where constraint_schema not like 'sys';
go

drop view referential_constraints_v1
go

drop table referential_constraints_tb1
go

use master;
go

drop database db_referential_constraints;
go 