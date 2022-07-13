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

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY CONSTRAINT_NAME;
go

Use master;
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY CONSTRAINT_NAME;
go

create table tbl6 (a int, b int, UNIQUE(b));
go

SELECT * FROM information_schema.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY CONSTRAINT_NAME;
go

drop table tbl6;
go

use db1;
go

drop table tbl2;
go
drop table tbl1;
go
drop table tbl5;
go
drop table tbl3;
go
drop table sc1.tbl4;
go
drop schema sc1;
go

use master
go

drop database db1;
go
