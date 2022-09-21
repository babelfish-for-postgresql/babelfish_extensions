-- syntax error: @table_name is required
exec [sys].sp_statistics_100
go

exec [sys].sp_statistics_100 @table_name = 'sys_sp_statistics_100_vu_prepare_t1'
go

exec [sys].sp_statistics_100 @table_name = 'sys_sp_statistics_100_vu_prepare_t2', @table_owner = 'dbo'
go

exec [sys].sp_statistics_100 @table_name = 'sys_sp_statistics_100_vu_prepare_t2', @table_qualifier = 'master'
go

exec [sys].sp_statistics_100 'sys_sp_statistics_100_vu_prepare_t1', 'dbo'
go

exec sp_statistics_100 N'sys_sp_statistics_100_vu_prepare_t1',N'dbo',NULL,N'%',N'Y',N'Q'
go

exec sp_statistics_100 N'sys_sp_statistics_100_vu_prepare_t2',N'dbo',NULL,N'%',N'Y',N'Q'
go

exec [sys].sp_statistics_100 @table_name = 'sys_sp_statistics_100_vu_prepare_t3'
go

use sys_sp_statistics_100_vu_prepare_db1
go

exec [sys].sp_statistics_100 @table_name = 'sys_sp_statistics_100_vu_prepare_t2', @table_owner = 'dbo'
go

exec [sys].sp_statistics_100 @table_name = 'sys_sp_statistics_100_vu_prepare_t1', @table_qualifier = 'master'
go
