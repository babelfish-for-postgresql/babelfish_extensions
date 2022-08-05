-- select would resolve to schema_resolution_proc_sch2.schema_resolution_proc_table1, insert would resolve to schema_resolution_proc_sch1.schema_resolution_proc_table1
exec schema_resolution_proc_sch1.schema_resolution_proc_p1
go

drop proc schema_resolution_proc_sch2.schema_resolution_proc_p2
go

drop proc schema_resolution_proc_sch1.schema_resolution_proc_p1
go

drop table schema_resolution_proc_sch1.schema_resolution_proc_table1;
drop table schema_resolution_proc_sch2.schema_resolution_proc_table1;
go

drop schema schema_resolution_proc_sch2;
go

-- insert is inside exec_batch, so it would be resolved to dbo.schema_resolution_proc_table1
exec schema_resolution_proc_sch1.schema_resolution_proc_p3
go

select * from dbo.schema_resolution_proc_table1;
go

drop proc schema_resolution_proc_sch1.schema_resolution_proc_p3
go

drop table schema_resolution_proc_table1;
go

create schema schema_resolution_proc_sch2;
create table schema_resolution_proc_sch2.schema_resolution_proc_t1(a int, b char);
go

-- Without schema specified, insert takes place in "schema_resolution_proc_sch1" while create takes place in default schema["dbo" in this case] 
exec schema_resolution_proc_sch1.schema_resolution_proc_create_tab;
go
	 
-- Without schema specified, select for t1 takes place in "schema_resolution_proc_sch1"
exec schema_resolution_proc_sch1.schema_resolution_proc_select_tab
go

drop table schema_resolution_proc_sch1.schema_resolution_proc_t1
go

-- searches for t1 in "schema_resolution_proc_sch1" first, if not found then searches in default schema
exec schema_resolution_proc_sch1.schema_resolution_proc_select_tab
go

drop table schema_resolution_proc_sch2.schema_resolution_proc_t1;
drop schema schema_resolution_proc_sch2;
go

drop proc schema_resolution_proc_sch1.schema_resolution_proc_select_tab
go
	 
drop proc schema_resolution_proc_sch1.schema_resolution_proc_create_tab
go
	 
drop table schema_resolution_proc_t1
go

use schema_resolution_proc_d1;
go

exec master.schema_resolution_proc_sch1.schema_resolution_proc_create_insert
go

use master;
go

select * from schema_resolution_proc_sch1.schema_resolution_proc_table1;
select * from schema_resolution_proc_table1;
go
	 
drop table schema_resolution_proc_sch1.schema_resolution_proc_table1;
drop table schema_resolution_proc_table1;
go

drop procedure schema_resolution_proc_sch1.schema_resolution_proc_create_insert
drop schema schema_resolution_proc_sch1
drop database schema_resolution_proc_d1
go
