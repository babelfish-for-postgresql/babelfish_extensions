create database schema_res_proc
go
	 
use schema_res_proc
go
	 
create schema sch1;
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
