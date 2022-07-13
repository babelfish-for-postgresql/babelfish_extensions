create database db1;
go

Use db1;
go

create table tbl1(a int, b int, primary key(a));
go

create table tbl2(a int, b int, primary key(a), foreign key(b) references tbl1(a));
go

create schema sc1;
go

create table tbl3 (a int, b int, primary key (a,b));
go

create table sc1.tbl4 (a int, b int, check ( a > 0  and b < 0));
go

create table tbl5 (a int, b int, c int, foreign key(b,c) references tbl3(a,b));
go

