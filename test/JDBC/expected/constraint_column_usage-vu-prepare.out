create database constraint_column_usage_vu_prepare_db;
go

Use constraint_column_usage_vu_prepare_db;
go

create table constraint_column_usage_vu_prepare_tbl1(arg1 int, arg2 int, primary key(arg1));
go

create table constraint_column_usage_vu_prepare_tbl2(arg3 int, arg4 int, primary key(arg3), foreign key(arg4) references constraint_column_usage_vu_prepare_tbl1(arg1));
go

create schema constraint_column_usage_vu_prepare_sc1;
go

create table constraint_column_usage_vu_prepare_tbl3 (arg5 int, arg6 int, primary key (arg5,arg6));
go

create table constraint_column_usage_vu_prepare_sc1.constraint_column_usage_vu_prepare_tbl4 (arg7 int, arg8 int, check ( arg7 > 0  and arg8 < 0));
go

create table constraint_column_usage_vu_prepare_tbl5 (arg9 int, arg10 int, arg11 int, foreign key(arg10,arg11) references constraint_column_usage_vu_prepare_tbl3(arg5,arg6));
go
