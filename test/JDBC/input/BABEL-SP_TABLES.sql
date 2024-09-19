create table t_sptables(a int)
go
create database db1
go
use db1
go
create table t_sptables(a int)
go
create table t_sptables2(b int)
go
create table t_sotables2(c int)
go
create table t_s_tables2(c int)
go
create table t__tables2(c int)
go
create table test_escape_chars_sp_tables(c int)
go
create table MyTable1 (a int, b int, c int)
go
create table [MyTable2] ([a] int, [b] int, [c] int)
go
create view t_sptables5
as
select a from MyTable1
go

-- provided name of database we are not currently in, should return error
exec sys.sp_tables @table_qualifier = 'master'
go

-- Related to BABEL-2953, sp_tables does not require @table_type argument (should not produce error)
exec sys.sp_tables @table_owner = 'Not_A_Real_Owner'
go

-- Mix-cased table tests
exec sp_tables @TABLE_NAME = 'mytable1'
go

exec sp_tables @TABLE_NAME = 'MYTABLE1'
go

exec sp_tables @TABLE_NAME = 'mytable2'
go

exec sp_tables @TABLE_NAME = 'MYTABLE2'
go

-- Delimiter table tests
exec sp_tables @TABLE_NAME = [mytable1]
go

exec sp_tables @TABLE_NAME = [MYTABLE1]
go

exec sp_tables @TABLE_NAME = [mytable2]
go

exec sp_tables @TABLE_NAME = [MYTABLE2]
go

-- should only get table within current database
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

exec sp_tables @table_name = 't_sptable%', @table_type = "'TABLE','VIEW'"
go

exec sp_tables @table_name = 't_sptable%', @table_type = "'TABLE','VIEW','TABLE','VIEW'"
go

-- pattern matching is default to be ON
exec sp_tables @table_name = 't_spt%'
go

-- pattern matching set to OFF
exec sp_tables @table_name = 't_spt%', @fUsePattern = '0'
go

exec sp_tables @table_name = 't_sptables_nonexist'
go

-- wildcard patterns
exec sp_tables @table_name = 't_sptabl%'
go

exec sp_tables @table_name = 't_s_tables2'
go

-- NOTE: Incorrect output with [] wildcards, see BABEL-2452 -- Fixed in BABEL-4128
exec sp_tables @table_name = 't_s[op]tables2'
go

exec sp_tables @table_name = 't_s[^o]tables2'
go

exec sp_tables @table_name = 't_s[o-p]tables2'
go

exec sp_tables @table_name = 't[_]sptables', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't[_]sptables2', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't[_]sotables2', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't[_]sptables5', @table_type = "'VIEW'"
go

exec sp_tables @table_name = 't_s[_]tables2', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't[_]s[_]tables2', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't[_][_]tables2', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't[__]tables2', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 't[[_]]sptables', @table_type = "'TABLE'"
go

exec sp_tables @table_name = 'test\_escape_chars\_sp_tables', @table_type = "'TABLE'"
GO

exec sp_tables @table_name = 'test\_escape\_chars\_sp\_tables', @table_type = "'TABLE'"
GO

exec sp_tables @table_name = 'test_escape_chars_sp_tables', @table_type = "'TABLE'"
GO

-- table type with mixed case
exec sp_tables @table_name = 't_s[_]tables2', @table_type = "'Table'"
go

exec sp_tables @table_name = 't_s[_]tables2', @table_type = "'tAbLe'"
go

exec sp_tables @table_name = 't_s[_]tables2', @table_type = "'table'"
go

-- unnamed invocation
exec sp_tables 't_sptables', 'dbo', 'db1'
go

-- case-insensitive invocation
exec sp_tables 'T_SPTABLES', 'DBO', 'DB1'
go

-- case-insensitive invocation
EXEC SP_TABLES @TABLE_NAME = 't_sptables', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'db1'
GO

-- [] delimiter invocation
exec [sp_tables] 't_sptables', 'dbo', 'db1'
go

exec [sys].[sp_tables] 't_sptables', 'dbo', 'db1'
go

exec [sys].sp_tables 't_sptables', 'dbo', 'db1'
go

-- BABEL-1782 (fixed)
exec [sys].sp_tables N't_sptables',N'dbo',NULL,N'''TABLE''',@fUsePattern=1;
go

-- table_type list
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''TABLE'',''VIEW'''
go
-- table_type list with unsupported type
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''TABLE'',''VIEW'',''SYSTEM TABLE'''
go
-- table_type list without tables
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''VIEW'',''SYSTEM TABLE'''
go
-- table_type list without views
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''TABLE'',''SYSTEM TABLE'''
go
-- table_type list with double-escaping
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''''''TABLE'''',''''VIEW'''',''''SYSTEM TABLE'''''''
go
-- table_type list with unbalanced quotes
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''TABLE'''''',''''VIEW'',''SYSTEM TABLE'''
go
-- table_type list with spaces
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''TABLE '','' VIEW'',''SYSTEM TABLE'''
go
-- table_type list with mixed case
exec [sys].sp_tables 't_sptable%','dbo',NULL,'''Table'',''View'',''System Table'''
go

drop view t_sptables5
go
drop table t_sptables
go
drop table MyTable1
go
drop table [MyTable2]
go
drop table t_sptables2
go
drop table t_sotables2
go
drop table t_s_tables2
go
drop table t__tables2
go
drop table test_escape_chars_sp_tables
go
use master
go
drop table t_sptables
go
drop database db1
go
