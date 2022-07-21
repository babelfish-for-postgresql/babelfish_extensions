USE db1_sys_sp_tables_view
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_1';
GO

exec sys.sp_tables @table_name = 'tbl_1';
GO

USE master
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_1';
GO

exec sys.sp_tables @table_name = 'tbl_1';
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_2';
GO

exec sys.sp_tables @table_name = 'tbl_2';
GO

USE db1_sys_sp_tables_view
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_2';
GO

exec sys.sp_tables @table_name = 'tbl_2';
GO
