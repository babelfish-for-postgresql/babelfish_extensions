use babel_sp_tables_vu_prepare_db1
go

-- provided name of database we are not currently in, should return error
exec sys.sp_tables @table_qualifier = 'master'
go

-- Related to BABEL-2953, sp_tables does not require @table_type argument (should not produce error)
exec sys.sp_tables @table_owner = 'Not_A_Real_Owner'
go

-- Mix-cased table tests
exec sp_tables @TABLE_NAME = 'babel_sp_tables_vu_prepare_mytable1'
go

exec sp_tables @TABLE_NAME = 'babel_sp_tables_vu_prepare_MYTABLE1'
go

exec sp_tables @TABLE_NAME = 'babel_sp_tables_vu_prepare_mytable2'
go

exec sp_tables @TABLE_NAME = 'babel_sp_tables_vu_prepare_MYTABLE2'
go

-- Delimiter table tests
exec sp_tables @TABLE_NAME = [babel_sp_tables_vu_prepare_mytable1]
go

exec sp_tables @TABLE_NAME = [babel_sp_tables_vu_prepare_MYTABLE1]
go

exec sp_tables @TABLE_NAME = [babel_sp_tables_vu_prepare_mytable2]
go

exec sp_tables @TABLE_NAME = [babel_sp_tables_vu_prepare_MYTABLE2]
go

-- should only get table within current database
exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptables'
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptables', @table_owner = 'dbo'
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptables', @table_qualifier = 'babel_sp_tables_vu_prepare_db1'
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptables', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptables', @table_type = "'TABLE','VIEW'"
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptable%', @table_type = "'TABLE','VIEW'"
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptable%', @table_type = "'TABLE','VIEW','TABLE','VIEW'"
go

-- pattern matching is default to be ON
exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_spt%'
go

-- pattern matching set to OFF
exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_spt%', @fUsePattern = '0'
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptables_nonexist'
go

-- wildcard patterns
exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_sptabl%'
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_s_tables2'
go

-- NOTE: Incorrect output with [] wildcards, see BABEL-2452
exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_s[op]tables2'
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_s[^o]tables2'
go

exec sp_tables @table_name = 'babel_sp_tables_vu_prepare_t_s[o-p]tables2'
go

-- unnamed invocation
exec sp_tables 'babel_sp_tables_vu_prepare_t_sptables', 'dbo', 'babel_sp_tables_vu_prepare_db1'
go

-- case-insensitive invocation
exec sp_tables 'babel_sp_tables_vu_prepare_T_SPTABLES', 'DBO', 'babel_sp_tables_vu_prepare_db1'
go

-- case-insensitive invocation
EXEC SP_TABLES @TABLE_NAME = 'babel_sp_tables_vu_prepare_t_sptables', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'babel_sp_tables_vu_prepare_db1'
GO

-- [] delimiter invocation
exec [sp_tables] 'babel_sp_tables_vu_prepare_t_sptables', 'dbo', 'babel_sp_tables_vu_prepare_db1'
go

exec [sys].[sp_tables] 'babel_sp_tables_vu_prepare_t_sptables', 'dbo', 'babel_sp_tables_vu_prepare_db1'
go

exec [sys].sp_tables 'babel_sp_tables_vu_prepare_t_sptables', 'dbo', 'babel_sp_tables_vu_prepare_db1'
go

-- BABEL-1782 (fixed)
exec [sys].sp_tables N'babel_sp_tables_vu_prepare_t_sptables',N'dbo',NULL,N'''TABLE''',@fUsePattern=1;
go
