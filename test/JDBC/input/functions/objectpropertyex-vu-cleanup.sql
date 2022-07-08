USE db2
GO

DROP TABLE ownerid_schema.ownerid_table
GO

DROP SCHEMA ownerid_schema
GO

-- =============== BaseType ===============

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

-- Cleanup
DROP TABLE specialinput_table
GO

-- Global cleanup for tests
USE master
GO
DROP DATABASE db2
GO