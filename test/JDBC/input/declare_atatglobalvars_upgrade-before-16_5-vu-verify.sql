-- check catalogs
select * from pg_catalog.pg_proc where proname = 'myproc29'
go
select * from sysobjects where name = 'myproc29'
go

exec p1_declare_atatglobalvars_upgrade
go
select dbo.f1_declare_atatglobalvars_upgrade() 
go
insert into t1_declare_atatglobalvars_upgrade values(4)
go
