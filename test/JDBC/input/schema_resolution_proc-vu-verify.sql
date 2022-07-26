use schema_res_proc
go

-- select would resolve to sch2.table1, insert would resolve to sch1.table1
exec sch1.p1
go

drop proc sch2.p2
go

drop proc sch1.p1
go

drop table sch1.table1;
drop table sch2.table1;
go

drop schema sch2;
go

-- insert is inside exec_batch, so it would be resolved to dbo.table1
exec sch1.p3
go

select * from dbo.table1;
go

drop proc sch1.p3
go

drop table table1;
go

-- Without schema specified, insert takes place in "sch1" while create takes place in default schema["dbo" in this case] 
exec sch1.create_tab;
go
	 
-- Without schema specified, select for t1 takes place in "sch1"
exec sch1.select_tab
go

drop table sch1.t1
go

-- searches for t1 in "sch1" first, if not found then searches in default schema
exec sch1.select_tab
go
	 
drop proc sch1.select_tab
go
	 
drop proc sch1.create_tab
go
	 
drop table t1
go
	 
drop schema sch1
go
	 
use master
go
	 
drop database schema_res_proc
go
