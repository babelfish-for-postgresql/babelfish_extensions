exec p1_declare_atatglobalvars_upgrade
go
select dbo.f1_declare_atatglobalvars_upgrade() 
go
insert into t1_declare_atatglobalvars_upgrade values(4)
go
