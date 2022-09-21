use sys_sp_statistics_vu_prepare_db1
go

-- syntax error: @table_name is required
exec sp_statistics
go

exec sp_statistics @table_name = 'sys_sp_statistics_vu_prepare_t1'
go

exec sp_statistics @table_name = 'sys_sp_statistics_vu_prepare_t2', @table_qualifier = 'sys_sp_statistics_vu_prepare_db1'
go

exec sp_statistics @table_name = 'sys_sp_statistics_vu_prepare_t3', @table_owner = 'dbo'
go

exec sp_statistics @table_name = 'sys_sp_statistics_vu_prepare_t4'
go

exec sp_statistics @table_name = 'sys_sp_statistics_vu_prepare_t4', @is_unique = 'Y'
go

exec [sys].sp_statistics @table_name = 'sys_sp_statistics_vu_prepare_t5'
go

-- unnamed invocation
exec sp_statistics 'sys_sp_statistics_vu_prepare_t1', 'dbo', 'sys_sp_statistics_vu_prepare_db1'
go

-- case-insensative invocation
EXEC sp_statistics @TABLE_NAME = 'sys_sp_statistics_vu_prepare_t2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'sys_sp_statistics_vu_prepare_db1'
GO

exec sp_statistics N'sys_sp_statistics_vu_prepare_t1',N'dbo',NULL,N'%',N'Y',N'Q'
go

-- sp_statistics_100 is implemented as same as sp_statistics
exec sp_statistics_100 @table_name = 'sys_sp_statistics_vu_prepare_t3' 
go