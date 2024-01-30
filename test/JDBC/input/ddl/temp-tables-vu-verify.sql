use master
GO

EXEC temp_table_vu_prepare_sp;
GO

EXEC temp_table_vu_prepare_sp_drop;
GO

EXEC temp_table_vu_prepare_sp_exception;
GO

-- Test temp table creation with toast is cleaned up properly.
CREATE TABLE #temp_table_create(a int, b nvarchar(200))
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%'
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%_index'
GO

DROP TABLE #temp_table_create
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%'
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%_index'
GO

-- Test temp table alter with toast
CREATE TABLE #temp_table_alter1(col1 int)
GO
ALTER TABLE #temp_table_alter1 ADD col2 varchar(20)
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%'
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%_index'
GO

DROP TABLE #temp_table_alter1
GO

CREATE TABLE #temp_table_alter2(col1 int, col2 varchar(20))
GO
ALTER TABLE #temp_table_alter2 ADD col3 int IDENTITY(1, 1)
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%'
GO

select count(*) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#pg_toast_%_index'
GO
