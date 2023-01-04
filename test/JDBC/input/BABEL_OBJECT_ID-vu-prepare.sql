
-- To test table, procedure, function
CREATE TABLE babel_object_id_t1 (a int);
GO

CREATE PROCEDURE babel_object_id_proc1 AS SELECT 1;
GO

CREATE FUNCTION babel_object_id_func1() returns int BEGIN RETURN 1; END
GO

CREATE VIEW babel_object_id_v1 AS SELECT 1;
GO

-- To test schema and object name containing spaces and dots
CREATE TABLE [babel_object_id_t2 .with .dot_an_spaces] (a int);
GO

CREATE SCHEMA [babel_object_id_schema .with .dot_and_spaces]
GO

CREATE TABLE [babel_object_id_schema .with .dot_and_spaces]."babel_object_id_t3 .with .dot_and_spaces" (a int);
GO

-- To test lookup in different database
CREATE DATABASE babel_object_id_db;
GO

USE babel_object_id_db;
GO

CREATE TABLE babel_object_id_t1 (a int);
GO

USE master;
GO