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

drop proc sp_hello;
go

use master
go

drop proc sp_hello
go

drop database db1
go

