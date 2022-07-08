-- Global setup for tests
CREATE DATABASE db2
GO
USE db2
GO

-- Setup
CREATE SCHEMA ownerid_schema
GO

CREATE TABLE ownerid_schema.ownerid_table(a int) 
GO

-- =============== BaseType ===============
-- Setup
CREATE TABLE basetype_table(a int)
GO

CREATE VIEW basetype_view AS
SELECT 1
GO

CREATE FUNCTION basetype_function()
RETURNS INTEGER
AS
BEGIN
RETURN 1;
END
GO

CREATE PROC basetype_proc
AS
SELECT 1
GO

-- =============== Special Input Cases ===============

-- Setup
CREATE TABLE specialinput_table(a int)
GO
