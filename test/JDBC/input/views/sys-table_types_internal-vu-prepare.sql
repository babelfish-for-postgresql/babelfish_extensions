DROP TYPE IF EXISTS table_types_internal_test1;
GO

DROP TYPE IF EXISTS table_types_internal_test2;
GO

CREATE TYPE table_types_internal_test1 AS TABLE (Id INT, Name VARCHAR(100));
GO

CREATE TYPE table_types_internal_test2 AS TABLE (Id INT, Name VARCHAR(100), floatNum float, someDate date);
GO

CREATE DATABASE table_types_internal_db1;
GO

USE table_types_internal_db1;

CREATE TYPE table_types_internal_test1_db1 AS TABLE (Id INT, Name VARCHAR(100));
GO

CREATE TYPE table_types_internal_test2_db1 AS TABLE (Id INT, Name VARCHAR(100), floatNum float, someDate date);
GO

CREATE SCHEMA table_types_internal_schema1;

GO
CREATE TYPE table_types_internal_schema1.table_types_internal_test1_db1 AS TABLE (Id INT, Name VARCHAR(100));
GO

CREATE TYPE table_types_internal_schema1.table_types_internal_test2_db1 AS TABLE (Id INT, Name VARCHAR(100), floatNum float, someDate date);
GO
