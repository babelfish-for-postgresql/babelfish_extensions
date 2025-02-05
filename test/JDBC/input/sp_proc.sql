create proc sp_hello as select 1
go

exec sp_hello
go

exec dbo.sp_hello
go

exec master.dbo.sp_hello
go

exec master..sp_hello
go

create database db1
go

use db1
go

exec master.dbo.sp_hello
go

exec master..sp_hello
go

exec sp_hello
go

exec .sp_hello
go

exec ..sp_hello
go

exec dbo.sp_hello
go

exec .dbo.sp_hello
go

exec ..dbo.sp_hello
go

sp_hello
go

.sp_hello
go

..sp_hello
go

dbo.sp_hello
go

.dbo.sp_hello
go

..dbo.sp_hello
go

create proc call_sp_helllo as exec sp_hello
go

exec call_sp_helllo
go

create proc sp_hello as select 2
go

--Executes the sp_hello in db1
exec sp_hello
go

exec dbo.sp_hello
go

exec call_sp_helllo
go

drop proc sp_hello
go

drop proc call_sp_helllo
go

create proc sp_hello as select 1/0;
go

exec sp_hello;
go

exec @a;
go

use master
go
create table sometableinmaster(somecolumn INT)
go
use db1
go
create schema s1
go

-- should resolve to db1.dbo.sp_hello
exec db1.dbo.sp_hello
go
exec db1..sp_hello
go

-- should throw an error
exec db1.sys.sp_hello
go

-- should thorw an error
exec db1.s1.sp_hello
go

drop proc sp_hello;
go

-- should resolve to master.dbo.sp_hello since proc does not exists in db1
-- special behaviour for sp_ procs
exec db1.dbo.sp_hello
go
exec db1..sp_hello
go

-- should resolve to sys sp_tables
exec db1.dbo.sp_tables
go
exec db1..sp_tables
go
-- procedure should be executed as if current db was master
exec master..sp_tables @table_name = N'sometableinmaster'
go
exec master.dbo.sp_tables @table_name = N'sometableinmaster'
go

use master
go

drop database db1
go

-- Using Collation BBF_Unicode_CP1_CI_AI
create database db1 collate BBF_Unicode_CP1_CI_AI
go

use db1
go

exec master.dbo.sp_hello
go

exec master..sp_hello
go

exec sp_hello
go

exec .sp_hello
go

exec ..sp_hello
go

exec dbo.sp_hello
go

exec .dbo.sp_hello
go

exec ..dbo.sp_hello
go

sp_hello
go

.sp_hello
go

..sp_hello
go

dbo.sp_hello
go

.dbo.sp_hello
go

..dbo.sp_hello
go

create proc call_sp_helllo as exec sp_hello
go

exec call_sp_helllo
go

create proc sp_hello as select 2
go

--Executes the sp_hello in db1
exec sp_hello
go

exec dbo.sp_hello
go

exec call_sp_helllo
go

drop proc sp_hello
go

drop proc call_sp_helllo
go

create proc sp_hello as select 1/0;
go

exec sp_hello;
go

exec @a;
go

drop proc sp_hello;
go

use master
go

drop table sometableinmaster
go
drop proc sp_hello
go

drop database db1
go
