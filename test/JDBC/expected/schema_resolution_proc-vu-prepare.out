create schema schema_resolution_proc_sch1;
go

create schema schema_resolution_proc_sch2;
go

create table schema_resolution_proc_sch1.schema_resolution_proc_table1(a int)
go

create table schema_resolution_proc_sch2.schema_resolution_proc_table1(a int, b char)
go

create procedure schema_resolution_proc_sch1.schema_resolution_proc_p1
as
exec schema_resolution_proc_sch2.schema_resolution_proc_p2;
insert into schema_resolution_proc_table1 values(10);
go

create proc schema_resolution_proc_sch2.schema_resolution_proc_p2
as
select * from schema_resolution_proc_table1;
go

create table schema_resolution_proc_table1(c int);
go

create proc schema_resolution_proc_sch1.schema_resolution_proc_p3
as
execute sp_executesql N'insert into schema_resolution_proc_table1 values(2)'
go
	 
create proc schema_resolution_proc_sch1.schema_resolution_proc_create_tab
as 
create table schema_resolution_proc_t1(dbo_t1 int);
create table schema_resolution_proc_sch1.schema_resolution_proc_t1(sch1_t1 char, b int);
insert into schema_resolution_proc_t1 values('a', 1);
insert into dbo.schema_resolution_proc_t1 values(1);
insert into schema_resolution_proc_sch2.schema_resolution_proc_t1 values(1, 'a');
go
	 
create proc schema_resolution_proc_sch1.schema_resolution_proc_select_tab
as 
select * from dbo.schema_resolution_proc_t1;
select * from schema_resolution_proc_t1;
select * from schema_resolution_proc_sch2.schema_resolution_proc_t1;
go

create proc schema_resolution_proc_sch1.schema_resolution_proc_create_insert
as
create table schema_resolution_proc_table1(a int);
create table schema_resolution_proc_sch1.schema_resolution_proc_table1(a int);
insert into schema_resolution_proc_table1 values(1);
insert into schema_resolution_proc_sch1.schema_resolution_proc_table1 values(2);
insert into dbo.schema_resolution_proc_table1 values(3);
select * from schema_resolution_proc_table1;
select * from dbo.schema_resolution_proc_table1;
select * from schema_resolution_proc_sch1.schema_resolution_proc_table1;
go

create database schema_resolution_proc_d1;
go
