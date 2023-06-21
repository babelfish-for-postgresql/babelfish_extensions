CREATE DATABASE db1_sys_types;
GO

USE db1_sys_types
GO

CREATE TYPE my_type FROM int;
GO

CREATE TYPE my_type2 FROM varchar(20);
GO

CREATE TYPE tbl_type_sys_types AS TABLE(a INT);
GO

USE master;
GO

CREATE TYPE my_type1 FROM int;
GO

CREATE TYPE tbl_type_sys_types1 AS TABLE(a INT);
GO