use master;
go

create database column_privileges_vu_prepare_db;
go

use column_privileges_vu_prepare_db;
go

create table column_privileges_vu_prepare_tb1(arg1 int, arg2 int);
go

create table column_privileges_vu_prepare_tb2(arg3 int, arg4 int);
go

create login column_privileges_vu_prepare_log with password = 'EmptyPassword#';
go

create user column_privileges_vu_prepare_user for login column_privileges_vu_prepare_log;
go

grant SELECT on column_privileges_vu_prepare_tb1(arg1) to column_privileges_vu_prepare_user;
go

grant UPDATE on column_privileges_vu_prepare_tb1(arg2) to column_privileges_vu_prepare_user;
go

grant REFERENCES on column_privileges_vu_prepare_tb2(arg3) to column_privileges_vu_prepare_user;
go

grant INSERT on column_privileges_vu_prepare_tb2(arg4) to column_privileges_vu_prepare_user;
go

use master;
go