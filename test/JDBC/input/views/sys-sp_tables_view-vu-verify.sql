USE sys_sp_tables_view_vu_prepare_db1
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'sys_sp_tables_view_vu_prepare_t1';
GO

exec sys.sp_tables @table_name = 'sys_sp_tables_view_vu_prepare_t1';
GO

USE master
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'sys_sp_tables_view_vu_prepare_t1';
GO

exec sys.sp_tables @table_name = 'sys_sp_tables_view_vu_prepare_t1';
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'sys_sp_tables_view_vu_prepare_t2';
GO

exec sys.sp_tables @table_name = 'sys_sp_tables_view_vu_prepare_t2';
GO

USE sys_sp_tables_view_vu_prepare_db1
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'sys_sp_tables_view_vu_prepare_t2';
GO

exec sys.sp_tables @table_name = 'sys_sp_tables_view_vu_prepare_t2';
GO
