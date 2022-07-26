create database schema_res_proc
go
	 
use schema_res_proc
go
	 
create schema sch1;
go

create schema sch2;
go

create table sch1.table1(a int)
go

create table sch2.table1(a int, b char)
go

create procedure sch1.p1
as
exec sch2.p2;
insert into table1 values(10);
go

create proc sch2.p2
as
select * from table1;
go

create table table1(c int);
go

create proc sch1.p3
as
execute sp_executesql N'insert into table1 values(2)'
go
	 
create proc sch1.create_tab 
as 
create table t1(dbo_t1 int);
create table sch1.t1(sch1_t1 char, b int);
insert into t1 values('a', 1);
insert into dbo.t1 values(1);
go
	 
create proc sch1.select_tab 
as 
select * from dbo.t1;
select * from t1;
go
