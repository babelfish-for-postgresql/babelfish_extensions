use sys_sp_databases_dep_vu_prepare_db1
go

exec sys_sp_databases_dep_vu_prepare_p1
go

select * from sys_sp_databases_dep_vu_prepare_f1()
go

select * from sys_sp_databases_dep_vu_prepare_v1
go

EXEC sp_databases_dep_vu_prepare_PROC1
GO
