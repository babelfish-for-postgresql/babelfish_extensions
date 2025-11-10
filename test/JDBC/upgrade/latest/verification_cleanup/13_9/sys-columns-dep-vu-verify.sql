-- sla 20500

select count(*) from sys.columns;
GO

exec sys_columns_dep_vu_prepare_p1
go

select * from sys_columns_dep_vu_prepare_v1
go

select * from sys_columns_dep_vu_prepare_f1()
go
