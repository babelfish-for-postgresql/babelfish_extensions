create table t1(a int)
go

create index i1 on t1(a)
go

create table t2(a int, b int not null primary key)
go

create index i2 on t2(a,b)
go

create table t3(a int)
go

-- syntax error: @table_name is required
exec [sys].sp_statistics_100
go

exec [sys].sp_statistics_100 @table_name = 't1'
go

exec [sys].sp_statistics_100 @table_name = 't2', @table_owner = 'dbo'
go

exec [sys].sp_statistics_100 @table_name = 't2', @table_qualifier = 'master'
go

exec [sys].sp_statistics_100 't1', 'dbo'
go

exec [sys].sp_statistics_100 @table_name = 't3'
go

create database db1
go

use db1
go

exec [sys].sp_statistics_100 @table_name = 't2', @table_owner = 'dbo'
go

exec [sys].sp_statistics_100 @table_name = 't1', @table_qualifier = 'master'
go

use master
go

--cleanup
drop index i1 on t1
go

drop index i2 on t2
go

drop table t1
go

drop table t2
go

drop table t3
go

drop database db1
go


