-- check catalogs
select * from pg_catalog.pg_proc where proname = 'p1_declare_atatglobalvars_upgrade'
go
select * from sysobjects where name = 'p1_declare_atatglobalvars_upgrade'
go

exec p1_declare_atatglobalvars_upgrade
go
select dbo.f1_declare_atatglobalvars_upgrade() 
go
insert into t1_declare_atatglobalvars_upgrade values(4)
go
