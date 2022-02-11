USE master
GO

CREATE DATABASE db_2706
GO

USE db_2706
GO

CREATE SCHEMA [Babelfish]
GO

CREATE TYPE [Babelfish].[table_type] AS TABLE (a int)
GO

USE master
GO

DROP DATABASE db_2706
GO
