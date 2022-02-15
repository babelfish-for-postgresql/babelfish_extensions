create database db1
go
use db1
go
create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int)
go
create table t3(a int, b int, c int)
go
create table t4(a int)
go
create table MyTable5 (a int, b int, c int)
go
create table [MyTable6] ([a] int, [b] int, [c] int)
go
create table foobar1(a int)
go
create table foobar2(b int)
go
create table folbar1(c int)
go

-- syntax error: @table_name is required
exec sp_table_privileges
go

exec sp_table_privileges @table_name = 't1'
go

exec sp_table_privileges @table_name = 't2', @table_qualifier = 'db1'
go

exec sp_table_privileges @table_name = 't3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_table_privileges 't1', 'dbo', 'db1'
go

-- case-insensitive invocation
EXEC SP_TABLE_PRIVILEGES @TABLE_NAME = 't2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'db1'
GO

-- case-insensitive tables
exec sp_table_privileges @TABLE_NAME = 'T2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'db1'
go

-- delimiter invocation
exec [sp_table_privileges] @TABLE_NAME = 't2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'db1'
go

-- Mix-cased table tests
exec [sp_table_privileges] @TABLE_NAME = 'mytable5'
go

exec sp_table_privileges @TABLE_NAME = 'MYTABLE5'
go

exec sp_table_privileges @TABLE_NAME = 'mytable6'
go

exec sp_table_privileges @TABLE_NAME = 'MYTABLE6'
go

-- Delimiter table tests NOTE: These to do not produce correct output due to BABEL-2883
exec sp_table_privileges @TABLE_NAME = [mytable5]
go

exec sp_table_privileges @TABLE_NAME = [MYTABLE5]
go

exec sp_table_privileges @TABLE_NAME = [mytable6]
go

exec sp_table_privileges @TABLE_NAME = [MYTABLE6]
go

-- tests fUsePattern = 0
exec sp_table_privileges @TABLE_NAME = 'foobar%', @fUsePattern=0
go

-- tests wildcard patterns
exec sp_table_privileges @TABLE_NAME = 'foobar%', @fUsePattern=1
go

exec sp_table_privileges @table_name = 'fo_bar1'
go

-- NOTE: Incorrect output with [] wildcards, see BABEL-2452
exec sp_table_privileges @table_name = 'fo[ol]bar1'
go

exec sp_table_privileges @table_name = 'fo[^o]bar1'
go

exec sp_table_privileges @table_name = 'fo[a-l]bar1'
go

-- provided name of database we are not currently in, should return error
exec sp_table_privileges @table_name = 't2', @table_qualifier = 'master'
go

-- ensure that only tables from the same database are retrieved
use master
go
create table t4(a int)
go
exec sp_table_privileges @table_name = 't4';
go

-- cleanup
use db1
go
drop table t1
go
drop table t2
go
drop table t3
go
drop table t4
go
drop table MyTable5 
go
drop table [MyTable6]
go
drop table foobar1
go
drop table foobar2
go
drop table folbar1
go
use master
go
drop table t4
go
drop database db1
go
