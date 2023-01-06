create function f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create schema a
go

create function a.f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create database test_sp_volatility_db1
go
use test_sp_volatility_db1
go
create function f2() returns int begin declare @a int; set @a = 1; return @a; end
go

CREATE LOGIN test_user WITH PASSWORD = 'abc';
GO
CREATE DATABASE test_db
GO
USE test_db
GO
CREATE USER test_user FOR LOGIN test_user
GO

CREATE SCHEMA test_schema
GO
ALTER USER test_user WITH DEFAULT_SCHEMA=test_schema
GO
create function test_schema.f1() returns int begin declare @a int; set @a = 1; return @a; end
GO
use master
