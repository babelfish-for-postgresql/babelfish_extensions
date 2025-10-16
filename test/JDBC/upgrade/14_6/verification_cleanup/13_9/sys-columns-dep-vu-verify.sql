-- sla 20000
exec sys_columns_dep_vu_prepare_p1
go

select * from sys_columns_dep_vu_prepare_v1
go

select * from sys_columns_dep_vu_prepare_f1()
go
