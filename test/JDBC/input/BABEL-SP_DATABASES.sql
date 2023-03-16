create database db1;
go
use db1;
go
create table t_spdatabases(a int);
go
insert into t_spdatabases(a) values(10);
go
insert into t_spdatabases(a) values(10);
go
insert into t_spdatabases(a) values(10);
go
insert into t_spdatabases(a) values(10);
go

select database_name, remarks from sys.sp_databases_view where database_name='db1';
go

select database_name, remarks from sys.sp_databases_view where database_name='DB1';
go

EXEC sp_databases;
GO

drop table t_spdatabases;
go
use master;
go
drop database db1;
go
