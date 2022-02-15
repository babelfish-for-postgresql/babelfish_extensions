create database db1
go
use db1
go
CREATE TYPE eyedees FROM int not NULL
go
CREATE TYPE Phone_Num FROM varchar(11) NOT NULL 
go
create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int, primary key(b, c))
go
create table t3(a int not null unique, b int, c int, primary key(c, b))
go
create table t4(a int not null unique)
go
create table t5(Id eyedees, Cellphone phone_num, primary key(Id, Cellphone));
go
create table MyTable1(ColA eyedees, ColB phone_num, primary key(ColA, ColB))
go
create table [MyTable2]([ColA] phone_num, [ColB] eyedees, primary key([ColA], [ColB]))
go

-- syntax error: @table_name is required
exec sp_special_columns
go

exec sp_special_columns @table_name = 't1'
go

exec sp_special_columns @table_name = 't2', @qualifier = 'db1', @scope = 'C'
go

exec sp_special_columns @table_name = 't3', @table_owner = 'dbo', @col_type = 'R'
go

exec sp_special_columns @table_name = 't4', @nullable = 'O'
go

-- Test table with user-defined type
exec sp_special_columns @table_name = 't5'
go

-- Mix-cased table tests
exec sp_special_columns @table_name = 'mytable1'
go

exec sp_special_columns @table_name = 'MYTABLE1'
go

exec sp_special_columns @table_name = 'mytable2'
go

exec sp_special_columns @table_name = 'MYTABLE2'
go

-- Delimiter table tests NOTE: These to do not produce correct output due to BABEL-2883
exec sp_special_columns @table_name = [mytable1]
go

exec sp_special_columns @table_name = [MYTABLE1]
go

exec sp_special_columns @table_name = [mytable2]
go

exec sp_special_columns @table_name = [MYTABLE2]
go

-- unnamed invocation
exec sp_special_columns 't1', 'dbo', 'db1'
go

-- case-insensitive invocation
EXEC SP_SPECIAL_COLUMNS @TABLE_NAME = 't2', @TABLE_OWNER = 'dbo', @QUALIFIER = 'db1'
GO

-- square-delimiter invocation
EXEC [sys].[sp_special_columns] @table_name = 't2', @table_owner = 'dbo', @qualifier = 'db1'
GO

drop table t1
go
drop table t2
go
drop table t3
go
drop table t4
go
drop table t5
go
drop table MyTable1
go
drop table [MyTable2]
go
drop type eyedees
go
drop type phone_num
go
use master
go
drop database db1
go
