use sys_sp_databases_vu_prepare_db1;
go

select database_name, remarks from sys.sp_databases_view where database_name='sys_sp_databases_vu_prepare_db1';
go
