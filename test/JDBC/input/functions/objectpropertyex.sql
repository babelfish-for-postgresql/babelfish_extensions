-- Global setup for tests
CREATE DATABASE db1
GO
USE db1
GO

-- Test to see if the underlying OBJECTPROPERTY function call is working

-- Setup
CREATE SCHEMA ownerid_schema
GO

CREATE TABLE ownerid_schema.ownerid_table(a int) 
GO

-- Check for correct case
SELECT CASE
    WHEN OBJECTPROPERTY(OBJECT_ID('ownerid_schema.ownerid_table'), 'OwnerId')  = (SELECT principal_id 
            FROM sys.database_principals
            WHERE name = CURRENT_USER)
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

-- Invalid property ID (should return NULL)
SELECT OBJECTPROPERTY(0, 'OwnerId')
GO

-- Cleanup
DROP TABLE ownerid_schema.ownerid_table
GO

DROP SCHEMA ownerid_schema
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

-- Tests valid cases

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_table'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_view'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_function'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_proc'), 'BaseType')
GO

-- Tests invalid object
SELECT OBJECTPROPERTYEX(0, 'BaseType')
GO

-- Cleanup
DROP TABLE basetype_table
GO

DROP VIEW basetype_view
GO

DROP FUNCTION basetype_function
GO

DROP PROC basetype_proc
GO

-- =============== Special Input Cases ===============

-- Setup
CREATE TABLE specialinput_table(a int)
GO

-- Tests special input cases
SELECT OBJECTPROPERTYEX(OBJECT_ID('specialinput_table'), 'BASETYPE')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('specialinput_table'), 'basetype')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('specialinput_table'), 'BASETYPE       ')
GO

-- Cleanup
DROP TABLE specialinput_table
GO

-- Global cleanup for tests
USE master
GO
DROP DATABASE db1
GO