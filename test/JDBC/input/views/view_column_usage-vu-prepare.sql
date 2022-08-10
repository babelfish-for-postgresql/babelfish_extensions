drop database if exists db_view_column_usage;
go
create database db_view_column_usage;
go

use db_view_column_usage;
go

drop table if exists view_column_usage_tb1;
go
create table view_column_usage_tb1(view_column_usage_c1 int, 
view_column_usage_c2 char, view_column_usage_c3 varchar);
go

create view view_column_usage_v1 as select * from view_column_usage_tb1;
go