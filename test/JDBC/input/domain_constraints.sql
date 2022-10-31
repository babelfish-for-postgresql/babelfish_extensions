drop database if exists db_domain_constraints;
go

create database db_domain_constraints;
go

Use db_domain_constraints;
go

select * from information_schema.domain_constraints where domain_schema not like 'sys';
go

drop table if exists domain_constraints_tb1;
go

create table domain_constraints_tb1(arg1 int, arg2 char, arg3 varchar);
go

drop view if exists domain_constraints_v1;
go

create view domain_constraints_v1 as select * from domain_constraints_tb1;
go

select * from information_schema.domain_constraints where domain_schema not like 'sys';
go

drop view domain_constraints_v1
go

drop table domain_constraints_tb1
go

use master;
go

drop database db_domain_constraints;
go