-- sla_for_parallel_query_enforced 60000
create database db1
go


create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int, primary key(b, c))
go
create table t3(a int, b int, c int, primary key(c, b))
go
create table t4(a int)
go

-- syntax error: @table_name is required
exec sp_pkeys
go

exec sp_pkeys @table_name = 't1'
go

exec sp_pkeys @table_name = 't2', @table_qualifier = 'master'
go

exec sp_pkeys @table_name = 't3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_pkeys 't1', 'dbo', 'master'
go

-- cross reference schema 
create schema spkeys
go
create table spkeys.t1(a int, primary key(a))
go
exec sp_pkeys @table_name = 't1'
go


-- cross reference database 
use db1
go
create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int, primary key(b, c))
go
create table t3(a int, b int, c int, primary key(c, b))
go
create table t4(a int)
go

-- syntax error: @table_name is required
exec sp_pkeys
go

exec sp_pkeys @table_name = 't1'
go

exec sp_pkeys @table_name = 't2', @table_qualifier = 'db1'
go

exec sp_pkeys @table_name = 't2', @table_qualifier = 'master'
go

exec sp_pkeys @table_name = 't3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_pkeys 't1', 'dbo', 'db1'
go

-- case-insensative invocation
EXEC SP_PKEYS @TABLE_NAME = 't2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'db1'
GO

drop table t1
go
drop table t2
go
drop table t3
go
drop table t4
go
use master
go
drop table t1
go
drop table t2
go
drop table t3
go
drop table t4
go
drop table spkeys.t1
go
drop schema spkeys
go
drop database db1
go

create database db1 COLLATE bbf_unicode_cp1_ci_ai;
go


create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int, primary key(b, c))
go
create table t3(a int, b int, c int, primary key(c, b))
go
create table t4(a int)
go

-- syntax error: @table_name is required
exec sp_pkeys
go

exec sp_pkeys @table_name = 't1'
go

exec sp_pkeys @table_name = 't2', @table_qualifier = 'master'
go

exec sp_pkeys @table_name = 't3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_pkeys 't1', 'dbo', 'master'
go

-- cross reference schema 
create schema spkeys
go
create table spkeys.t1(a int, primary key(a))
go
exec sp_pkeys @table_name = 't1'
go


-- cross reference database 
use db1
go
create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int, primary key(b, c))
go
create table t3(a int, b int, c int, primary key(c, b))
go
create table t4(a int)
go

-- syntax error: @table_name is required
exec sp_pkeys
go

exec sp_pkeys @table_name = 't1'
go

exec sp_pkeys @table_name = 't2', @table_qualifier = 'db1'
go

exec sp_pkeys @table_name = 't2', @table_qualifier = 'master'
go

exec sp_pkeys @table_name = 't3', @table_owner = 'dbo'
go

-- unnamed invocation
exec sp_pkeys 't1', 'dbo', 'db1'
go

-- case-insensative invocation
EXEC SP_PKEYS @TABLE_NAME = 't2', @TABLE_OWNER = 'dbo', @TABLE_QUALIFIER = 'db1'
GO

drop table t1
go
drop table t2
go
drop table t3
go
drop table t4
go
use master
go
drop table t1
go
drop table t2
go
drop table t3
go
drop table t4
go
drop table spkeys.t1
go
drop schema spkeys
go
drop database db1
go
