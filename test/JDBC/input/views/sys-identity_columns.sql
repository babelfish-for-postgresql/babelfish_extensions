DROP TABLE IF EXISTS sys_identity_columns
go

CREATE TABLE sys_identity_columns (c1 int, c2 int IDENTITY(1,1))
go

SELECT seed_value, increment_value, last_value FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns');
go

SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns');
go

CREATE DATABASE db1
go

USE db1
go

-- should not be visible here
SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns');
go

USE master
go

DROP TABLE IF EXISTS sys_identity_columns
go

DROP DATABASE db1
go
