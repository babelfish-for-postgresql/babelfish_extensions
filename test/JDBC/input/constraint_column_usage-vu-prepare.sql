create database db_constraint_column_usage;
go

Use db_constraint_column_usage;
go

create table tbl1(arg1 int, arg2 int, primary key(arg1));
go

create table tbl2(arg3 int, arg4 int, primary key(arg3), foreign key(arg4) references tbl1(arg1));
go

create schema sc1;
go

create table tbl3 (arg5 int, arg6 int, primary key (arg5,arg6));
go

create table sc1.tbl4 (arg7 int, arg8 int, check ( arg7 > 0  and arg8 < 0));
go

create table tbl5 (arg9 int, arg10 int, arg11 int, foreign key(arg10,arg11) references tbl3(arg5,arg6));
go
