create database db1
go
use db1
go
create table t_sptables(a int)
go

-- syntax error: @table_name is required
exec sys.sp_tables
go

exec sp_tables @table_name = 't_sptables'
go

exec sp_tables @table_name = 't_sptables', @table_owner = 'dbo'
go

exec sp_tables @table_name = 't_sptables', @table_qualifier = 'db1'
go

exec sp_tables @table_name = 't_sptables', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't_sptables', @table_type = "'TABLE','VIEW'"
go

-- pattern matching is default to be ON
exec sp_tables @table_name = 't_spt%'
go

-- pattern matching set to OFF
exec sp_tables @table_name = 't_spt%', @fUsePattern = '0'
go

exec sp_tables @table_name = 't_sptables_nonexist'
go

-- unnamed invocation
exec sp_tables 't_sptables', 'dbo', 'db1'
go

-- case-insensative invocation
EXEC SP_TABLES @TABLE_NAME = 't_sptables', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'db1'
GO

-- failed query in BABEL-1782
exec [sys].sp_tables N't23',N'dbo',NULL,N'''TABLE''',@fUsePattern=1;
go

drop table t_sptables
go
use master
go
drop database db1
go
