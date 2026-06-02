-- Setup
CREATE SCHEMA objectpropertyex_ownerid_schema
GO

CREATE TABLE objectpropertyex_ownerid_schema.objectpropertyex_ownerid_table(a int) 
GO

-- =============== BaseType ===============
-- Setup
CREATE TABLE objectpropertyex_basetype_table(a int)
GO

CREATE TYPE objectpropertyex_basetype_tt AS TABLE(a int)
GO

CREATE VIEW objectpropertyex_basetype_view AS
SELECT 1
GO

CREATE FUNCTION objectpropertyex_basetype_function()
RETURNS INTEGER
AS
BEGIN
RETURN 1;
END
GO

CREATE PROC objectpropertyex_basetype_proc
AS
SELECT 1
GO

-- =============== Special Input Cases ===============

-- Setup
CREATE TABLE objectpropertyex_specialinput_table(a int)
GO

-- =============== BaseType - additional object types ===============

-- Trigger
CREATE TABLE objectpropertyex_trigger_table(a int)
GO

CREATE TRIGGER objectpropertyex_test_trigger ON objectpropertyex_trigger_table
AFTER INSERT AS
BEGIN
    SELECT 1
END
GO

-- Constraints: PK, FK, CHECK, DEFAULT
CREATE TABLE objectpropertyex_constraint_table(
    a int,
    b int DEFAULT 42,
    c int CHECK (c > 0),
    CONSTRAINT objectpropertyex_pk PRIMARY KEY (a)
)
GO

CREATE TABLE objectpropertyex_fk_table(
    x int,
    CONSTRAINT objectpropertyex_fk FOREIGN KEY (x) REFERENCES objectpropertyex_constraint_table(a)
)
GO

-- Sequence
CREATE SEQUENCE objectpropertyex_test_seq START WITH 1
GO

-- Inline table-valued function
CREATE FUNCTION objectpropertyex_itvf()
RETURNS TABLE
AS
RETURN (SELECT 1 AS col1)
GO

-- Multi-statement table-valued function
CREATE FUNCTION objectpropertyex_tvf()
RETURNS @result TABLE (col1 int)
AS
BEGIN
    INSERT @result VALUES (1)
    RETURN
END
GO

-- =============== Properties test objects ===============

-- IsSchemaBound
CREATE FUNCTION objectpropertyex_schemabound_fn()
RETURNS int
WITH SCHEMABINDING
BEGIN
    RETURN 1
END
GO

CREATE FUNCTION objectpropertyex_noschemabound_fn()
RETURNS int
BEGIN
    RETURN 1
END
GO

-- IsIndexed
CREATE TABLE objectpropertyex_indexed_table(a int)
GO

CREATE INDEX objectpropertyex_idx ON objectpropertyex_indexed_table(a)
GO

CREATE TABLE objectpropertyex_noindex_table(a int)
GO

-- IsDefaultCnst
CREATE TABLE objectpropertyex_default_table(a int DEFAULT 10)
GO

-- IsMSShipped
CREATE TABLE objectpropertyex_notshipped_table(a int)
GO

-- =============== IsSchemaBound - schema-bound view ===============

CREATE VIEW objectpropertyex_schemabound_view
WITH SCHEMABINDING
AS
SELECT 1 AS col1
GO

-- =============== Cross-database scoping ===============
CREATE DATABASE objectpropertyex_otherdb
GO

USE objectpropertyex_otherdb
GO

CREATE TABLE objectpropertyex_otherdb_table(a int)
GO

USE master
GO

-- =============== Permission edge cases (OID helper) ===============
CREATE TABLE objectpropertyex_perm_table(a int)
GO

CREATE TRIGGER objectpropertyex_perm_trigger ON objectpropertyex_perm_table INSTEAD OF INSERT
AS
BEGIN
    SELECT * FROM objectpropertyex_perm_table
END
GO
-- Store OIDs so restricted users can bypass OBJECT_ID() limitation
CREATE TABLE objectpropertyex_oid_helper(name varchar(100), oid_val int)
GO
INSERT INTO objectpropertyex_oid_helper VALUES
('basetype_table', OBJECT_ID('objectpropertyex_basetype_table')),
('specialinput_table', OBJECT_ID('objectpropertyex_specialinput_table')),
('trigger_table', OBJECT_ID('objectpropertyex_trigger_table')),
('noindex_table', OBJECT_ID('objectpropertyex_noindex_table')),
('basetype_view', OBJECT_ID('objectpropertyex_basetype_view')),
('perm_table', OBJECT_ID('objectpropertyex_perm_table')),
('perm_trigger', OBJECT_ID('objectpropertyex_perm_trigger', 'TR'))
GO

-- psql
-- Store otherdb table OID via psql
INSERT INTO objectpropertyex_oid_helper VALUES
('otherdb_table', (SELECT oid FROM pg_class WHERE relname = 'objectpropertyex_otherdb_table'));
GO

-- tsql
