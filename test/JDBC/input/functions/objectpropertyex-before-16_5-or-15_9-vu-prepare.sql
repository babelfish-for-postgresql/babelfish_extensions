-- Setup
CREATE SCHEMA objectpropertyex_ownerid_schema
GO

CREATE TABLE objectpropertyex_ownerid_schema.objectpropertyex_ownerid_table(a int) 
GO

-- =============== BaseType ===============
-- Setup
CREATE TABLE objectpropertyex_basetype_table(a int)
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
