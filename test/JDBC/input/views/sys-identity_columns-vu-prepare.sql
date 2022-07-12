DROP TABLE IF EXISTS sys_identity_columns
go

CREATE TABLE sys_identity_columns (c1 int, c2 int IDENTITY(1,1))
go

CREATE DATABASE sys_identity_columns_db1
go
