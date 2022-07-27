-- select would resolve to schema_resolution_proc-vu-prepare_sch2.proc-vu-prepare_table1, insert would resolve to schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_table1
exec schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_p1
go

drop proc schema_resolution_proc-vu-prepare_sch2.proc-vu-prepare_p2
go

drop proc schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_p1
go

drop table schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_table1;
drop table schema_resolution_proc-vu-prepare_sch2.proc-vu-prepare_table1;
go

drop schema schema_resolution_proc-vu-prepare_sch2;
go

-- insert is inside exec_batch, so it would be resolved to dbo.proc-vu-prepare_table1
exec schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_p3
go

select * from dbo.proc-vu-prepare_table1;
go

drop proc schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_p3
go

drop table proc-vu-prepare_table1;
go

-- Without schema specified, insert takes place in "schema_resolution_proc-vu-prepare_sch1" while create takes place in default schema["dbo" in this case] 
exec schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_create_tab;
go
	 
-- Without schema specified, select for t1 takes place in "schema_resolution_proc-vu-prepare_sch1"
exec schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_select_tab
go

drop table schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_t1
go

-- searches for t1 in "schema_resolution_proc-vu-prepare_sch1" first, if not found then searches in default schema
exec schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_select_tab
go
	 
drop proc schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_select_tab
go
	 
drop proc schema_resolution_proc-vu-prepare_sch1.proc-vu-prepare_create_tab
go
	 
drop table proc-vu-prepare_t1
go
	 
drop schema schema_resolution_proc-vu-prepare_sch1
go
