create schema schema_resolution_proc-vu-prepare_sch1;
go

create schema schema_resolution_proc-vu-prepare_sch2;
go

create table schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_table1(a int)
go

create table schema_resolution_proc-vu-prepare_sch2.proc-vu-prepare_table1(a int, b char)
go

create procedure schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_p1
as
exec schema_resolution_proc-vu-prepare_sch2.proc-vu-prepare_p2;
insert into proc-vu-prepare_table1 values(10);
go

create proc schema_resolution_proc-vu-prepare_sch2.proc-vu-prepare_p2
as
select * from proc-vu-prepare_table1;
go

create table proc-vu-prepare_table1(c int);
go

create proc schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_p3
as
execute sp_executesql N'insert into proc-vu-prepare_table1 values(2)'
go
	 
create proc schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_create_tab
as 
create table proc-vu-prepare_t1(dbo_t1 int);
create table schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_t1(sch1_t1 char, b int);
insert into proc-vu-prepare_t1 values('a', 1);
insert into dbo.proc-vu-prepare_t1 values(1);
go
	 
create proc schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_select_tab
as 
select * from dbo.proc-vu-prepare_t1;
select * from proc-vu-prepare_t1;
go
