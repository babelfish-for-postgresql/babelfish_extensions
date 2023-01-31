
create database db1
go
use db1
go
create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int, foreign key(b) references t1(a))
go
create table t3(a int, b int, c int, primary key(c, b))
go
create table t4(d int, e int, foreign key(d, e) references t3(c, b))
go
create table MyTable5(cOlUmN_a int, CoLuMn_b int, primary key(cOlUmN_a , CoLuMn_b))
go
create table MyTable6(cOlUmN_c int, CoLuMn_d int, foreign key(cOlUmN_c, CoLuMn_d) references MyTable5(cOlUmN_a, CoLuMn_b))
go
create table [MyTable7] ([MyColumn_a] int, [MyColumn_b] int, foreign key([MyColumn_a], [MyColumn_b]) references MyTable5(cOlUmN_a, CoLuMn_b))
go

-- error: @pktable_name and/or @fktable_name must be provided
exec sp_fkeys
go

-- error: provided name of database we are not currently in
exec sp_fkeys @fktable_name = 't2', @pktable_qualifier = 'master'
go

exec sp_fkeys @pktable_name = 't1'
go

exec sys.sp_fkeys @pktable_name = 't1'
go

exec sp_fkeys @fktable_name = 't2', @pktable_qualifier = 'db1'
go

exec sp_fkeys @pktable_name = 't3', @pktable_owner = 'dbo'
go

-- case-insensitive invocation
EXEC SP_FKEYS @FKTABLE_NAME = 't4', @PKTABLE_NAME = 't3', @PKTABLE_OWNER = 'dbo', @FKTABLE_QUALIFIER = 'db1'
GO

-- case-insensitive parameter calls
exec sp_fkeys @fktable_name = 'T4', @pktable_name = 'T3', @pktable_owner = 'dbo', @fktable_qualifier = 'db1'
go

-- [] delimiter invocation
EXEC [sys].[sp_fkeys] @FKTABLE_NAME = 't4', @PKTABLE_NAME = 't3', @PKTABLE_OWNER = 'dbo', @FKTABLE_QUALIFIER = 'db1'
GO

-- Mix-cased table tests
exec sp_fkeys @pktable_name = 'mytable5'
go

exec sp_fkeys @pktable_name = 'MYTABLE5'
go

exec sp_fkeys @fktable_name = 'mytable6'
go

exec sp_fkeys @fktable_name = 'MYTABLE6'
go

exec sp_fkeys @fktable_name = 'mytable7'
go

exec sp_fkeys @fktable_name = 'MYTABLE7'
go
-- Delimiter table tests NOTE: THese do not procude correct output due to BABEL-2883
exec sp_fkeys @pktable_name = [mytable5]
go

exec sp_fkeys @pktable_name = [MYTABLE5]
go

exec sp_fkeys @fktable_name = [mytable6]
go

exec sp_fkeys @fktable_name = [MYTABLE6]
go

exec sp_fkeys @fktable_name = [mytable7]
go

exec sp_fkeys @fktable_name = [MYTABLE7]
go

-- ensure that only tables from the same database are retrieved
use master
go
create table t3(a int, b int, c int, primary key(c, b))
go
create table t4(d int, e int, foreign key(d, e) references t3(c, b))
go
EXEC SP_FKEYS @FKTABLE_NAME = 't4'
go

use db1
go
drop table t2
go
drop table t1
go
drop table t4
go
drop table [MyTable7]
go
drop table MyTable6
go
drop table MyTable5
go
drop table t3
go
use master
go
drop table t4
go
drop table t3
go
drop database db1
go
