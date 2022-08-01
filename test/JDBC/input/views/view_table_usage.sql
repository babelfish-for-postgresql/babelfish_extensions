drop database if exists db_view_table_usage;
go
create database db_view_table_usage;
go

use db_view_table_usage;
go



select * from information_schema.view_table_usage where table_name not like 'sys%';
go


drop table if exists view_table_usage_tb1;
go
create table view_table_usage_tb1(arg1 int, arg2 char, arg3 varchar);
go

drop view if exists view_table_usage_v1;
go
create view view_table_usage_v1 as select * from view_table_usage_tb1;
go


select * from information_schema.view_table_usage where table_name not like 'sys%';
go




drop view view_table_usage_v1
go

drop table view_table_usage_tb1
go

use master;
go

drop database db_view_table_usage;
go

