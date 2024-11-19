-- sla 160000
use babel_sp_table_priviliges_vu_prepare_db1
go

-- syntax error: @table_name is required
exec sp_table_privileges
go

exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_t1'
go

exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_t2', @table_qualifier = 'babel_sp_table_priviliges_vu_prepare_db1'
go

exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_t3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_table_privileges 'babel_sp_table_priviliges_vu_prepare_t1', 'dbo', 'babel_sp_table_priviliges_vu_prepare_db1'
go

-- case-insensitive invocation
EXEC SP_TABLE_PRIVILEGES @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_t2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'babel_sp_table_priviliges_vu_prepare_db1'
GO

-- case-insensitive tables
exec sp_table_privileges @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_T2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'babel_sp_table_priviliges_vu_prepare_db1'
go

-- delimiter invocation
exec [sp_table_privileges] @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_t2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'babel_sp_table_priviliges_vu_prepare_db1'
go

-- Mix-cased table tests
exec [sp_table_privileges] @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_mytable5'
go

exec sp_table_privileges @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_MYTABLE5'
go

exec sp_table_privileges @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_mytable6'
go

exec sp_table_privileges @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_MYTABLE6'
go

-- Delimiter table tests
exec sp_table_privileges @TABLE_NAME = [babel_sp_table_priviliges_vu_prepare_mytable5]
go

exec sp_table_privileges @TABLE_NAME = [babel_sp_table_priviliges_vu_prepare_MYTABLE5]
go

exec sp_table_privileges @TABLE_NAME = [babel_sp_table_priviliges_vu_prepare_mytable6]
go

exec sp_table_privileges @TABLE_NAME = [babel_sp_table_priviliges_vu_prepare_MYTABLE6]
go

-- tests fUsePattern = 0
exec sp_table_privileges @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_foobar%', @fUsePattern=0
go

-- tests wildcard patterns
exec sp_table_privileges @TABLE_NAME = 'babel_sp_table_priviliges_vu_prepare_foobar%', @fUsePattern=1
go

exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_fo_bar1'
go

-- NOTE: Incorrect output with [] wildcards, see BABEL-2452
exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_fo[ol]bar1'
go

exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_fo[^o]bar1'
go

exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_fo[a-l]bar1'
go

-- provided name of database we are not currently in, should return error
exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_t2', @table_qualifier = 'master'
go

use master
go

exec sp_table_privileges @table_name = 'babel_sp_table_priviliges_vu_prepare_t4';
go
