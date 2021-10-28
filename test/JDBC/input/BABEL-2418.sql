USE master
go

CREATE DATABASE babel_2418_db
go

USE babel_2418_db
go

CREATE SCHEMA babel_2418_schema1
go

CREATE SCHEMA babel_2418_schema2
go

SELECT nspname FROM sys.babelfish_namespace_ext;
go

USE master
go

DROP DATABASE babel_2418_db
go

SELECT nspname FROM sys.babelfish_namespace_ext;
go
