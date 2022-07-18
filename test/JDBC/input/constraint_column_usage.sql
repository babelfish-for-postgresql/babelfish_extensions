create database db_constraint_column_usage;
go

Use db_constraint_column_usage;
go

create table constraint_column_usage_tbl1(arg1 int, arg2 int, primary key(arg1));
go

create table constraint_column_usage_tbl2(arg3 int, arg4 int, primary key(arg3), foreign key(arg4) references constraint_column_usage_tbl1(arg1));
go

create schema constraint_column_usage_sc1;
go

create table constraint_column_usage_sc1.constraint_column_usage_tbl3 (arg5 int, arg6 int, primary key (arg5,arg6));
go

create table constraint_column_usage_sc1.constraint_column_usage_tbl4 (arg7 int, arg8 int, check ( arg7 > 0  and arg8 < 0));
go

create table constraint_column_usage_tbl5 (arg9 int, arg10 int, arg11 int, foreign key(arg10,arg11) references constraint_column_usage_sc1.constraint_column_usage_tbl3(arg5,arg6));
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

Use master;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

create table constraint_column_usage_tbl6 (arg12 int, arg13 int, UNIQUE(arg13));
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

drop table constraint_column_usage_tbl6;
go

use db_constraint_column_usage;
go

drop table constraint_column_usage_tbl2;
go
drop table constraint_column_usage_tbl1;
go
drop table constraint_column_usage_tbl5;
go
drop table constraint_column_usage_sc1.constraint_column_usage_tbl3;
go
drop table constraint_column_usage_sc1.constraint_column_usage_tbl4;
go
drop schema constraint_column_usage_sc1;
go

use master
go

drop database db_constraint_column_usage;
go
