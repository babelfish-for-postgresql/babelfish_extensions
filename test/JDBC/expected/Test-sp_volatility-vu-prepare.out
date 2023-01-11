create function test_sp_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create schema test_sp_volatility_schema1
go

create function test_sp_volatility_schema1.test_sp_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create schema [test_sp_volatility_schema1 with .dot and spaces]
go

create function [test_sp_volatility_schema1 with .dot and spaces].test_sp_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
go

CREATE LOGIN test_sp_volatility_login WITH PASSWORD = 'abc';
GO

CREATE DATABASE test_sp_volatility_db1
GO

USE test_sp_volatility_db1
GO

CREATE SCHEMA test_sp_volatility_schema2
GO

create function test_sp_volatility_f2() returns int begin declare @a int; set @a = 1; return @a; end
GO

create function test_sp_volatility_schema2.test_sp_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
GO

CREATE USER test_sp_volatility_user FOR LOGIN test_sp_volatility_login
GO

ALTER USER test_sp_volatility_user WITH DEFAULT_SCHEMA=test_sp_volatility_schema2
GO
