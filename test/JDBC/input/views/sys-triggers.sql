-- Setup
CREATE TABLE master_table(a int)
GO

CREATE TRIGGER master_trig ON master_table AFTER INSERT
AS
BEGIN
SELECT 1
END
GO

CREATE DATABASE db1
GO

USE db1
GO

CREATE TABLE t1(a int)
GO

CREATE TABLE t2(b int)
GO

CREATE TRIGGER trig1 ON t1 INSTEAD OF INSERT
AS
BEGIN
SELECT 1
END
GO

CREATE TRIGGER trig2 ON t2 AFTER INSERT
AS
BEGIN
SELECT 1
END
GO

-- test instead of insert trigger
SELECT 
    name,
    parent_class,
    parent_class_desc,
    type,
    type_desc,
    is_ms_shipped,
    is_disabled,
    is_not_for_replication,
    is_instead_of_trigger
FROM sys.triggers
WHERE name = 'trig1'
GO

-- test after insert trigger
SELECT 
    name,
    parent_class,
    parent_class_desc,
    type,
    type_desc,
    is_ms_shipped,
    is_disabled,
    is_not_for_replication,
    is_instead_of_trigger
FROM sys.triggers
WHERE name = 'trig2'
GO

-- test schema-scoped visibility of view
SELECT 
    name,
    parent_class,
    parent_class_desc,
    type,
    type_desc,
    is_ms_shipped,
    is_disabled,
    is_not_for_replication,
    is_instead_of_trigger
FROM sys.triggers
WHERE name = 'master_trig'
GO

-- Cleanup
DROP TRIGGER trig1
GO

DROP TRIGGER trig2
GO

DROP table t1
GO

DROP table t2
GO

USE master
GO

DROP TRIGGER master_trig
GO

DROP table master_table
GO

DROP database db1
GO
