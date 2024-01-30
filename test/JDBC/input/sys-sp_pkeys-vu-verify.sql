-- sla_for_parallel_query_enforced 45000
use master
go

-- syntax error: @table_name is required
exec sp_pkeys
go

exec sp_pkeys @table_name = 'sys_sp_pkeys_vu_prepare_t1'
go

exec sp_pkeys @table_name = 'sys_sp_pkeys_vu_prepare_t2', @table_qualifier = 'master'
go

exec sp_pkeys @table_name = 'sys_sp_pkeys_vu_prepare_t3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_pkeys 'sys_sp_pkeys_vu_prepare_t1', 'dbo', 'master'
go

-- cross reference database 
use sys_sp_pkeys_vu_prepare_db1
go

-- syntax error: @table_name is required
exec sp_pkeys
go

exec sp_pkeys @table_name = 'sys_sp_pkeys_vu_prepare_t1'
go

exec sp_pkeys @table_name = 'sys_sp_pkeys_vu_prepare_t2', @table_qualifier = 'sys_sp_pkeys_vu_prepare_db1'
go

exec sp_pkeys @table_name = 'sys_sp_pkeys_vu_prepare_t2', @table_qualifier = 'master'
go

exec sp_pkeys @table_name = 'sys_sp_pkeys_vu_prepare_t3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_pkeys 'sys_sp_pkeys_vu_prepare_t1', 'dbo', 'sys_sp_pkeys_vu_prepare_db1'
go

-- case-insensative invocation
EXEC SP_PKEYS @TABLE_NAME = 'sys_sp_pkeys_vu_prepare_t2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'sys_sp_pkeys_vu_prepare_db1'
GO