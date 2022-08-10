drop database if exists db_view_column_usage;
go
create database db_view_column_usage;
go

use db_view_column_usage;
go



select * from information_schema.view_column_usage where table_name not like 'sys%';
go


drop table if exists view_column_usage_tb1;
go
create table view_column_usage_tb1(view_column_usage_c1 int, 
view_column_usage_c2 char, view_column_usage_c3 varchar);
go

drop view if exists view_column_usage_v1;
go
create view view_column_usage_v1 as select * from view_column_usage_tb1;
go


select * from information_schema.view_column_usage where table_name not like 'sys%';
go




drop view view_column_usage_v1
go

drop table view_column_usage_tb1
go

use master;
go

drop database db_view_column_usage;
go