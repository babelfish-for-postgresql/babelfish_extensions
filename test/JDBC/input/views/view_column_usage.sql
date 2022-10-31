use master;
go

select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

create table view_column_usage_tb1(view_column_usage_c1 int, 
view_column_usage_c2 char, view_column_usage_c3 varchar);
go

create table view_column_usage_tb2(view_column_usage_c4 char, 
view_column_usage_c5 char, view_column_usage_c6 int);
go

create view view_column_usage_v1 as select * from view_column_usage_tb1;
go

create view view_column_usage_v2 as select * from view_column_usage_tb2;
go

create database view_column_usage_test_db;
go

select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

create procedure view_column_usag_proc as select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

create function view_column_usag_func() returns table as return(select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name);
go

select * from information_schema.view_column_usage where view_name like 'view_column_usage_v%' order by view_name;
go

create schema view_column_usage_test_sc;
go

create table view_column_usage_test_sc.view_column_usage_sc_tb(arg3 char(10));
go

create view view_column_usage_sc_v as select * from view_column_usage_test_sc.view_column_usage_sc_tb;
go

select * from information_schema.view_column_usage where view_name like 'view_column_usage_sc%' order by view_name;
go

drop view view_column_usage_sc_v;
go

drop table view_column_usage_test_sc.view_column_usage_sc_tb;
go

drop schema view_column_usage_test_sc;
go

drop function view_column_usag_func;
go

drop procedure view_column_usag_proc;
go

drop view view_column_usage_v2;
go

drop view view_column_usage_v1;
go

drop table view_column_usage_tb2;
go

drop table view_column_usage_tb1;
go