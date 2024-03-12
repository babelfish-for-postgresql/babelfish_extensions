-- database
EXEC sp_addextendedproperty 'database property1', 'database property1 value'
GO

SELECT * FROM fn_listextendedproperty() ORDER BY objtype, objname, name, value;
GO

-- schema
CREATE SCHEMA babel_extended_property_v3_schema
GO

EXEC sp_addextendedproperty 'schema property1', 'schema property1 value', 'schema', 'babel_extended_property_v3_schema'
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', NULL, NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- table
CREATE TABLE babel_extended_property_v3_schema.babel_extended_property_v3_table(id int);
GO

EXEC sp_addextendedproperty 'table property1', 'table property1 value', 'schema', 'babel_extended_property_v3_schema', 'table', 'babel_extended_property_v3_table'
GO

EXEC sp_addextendedproperty 'table property2', 'table property2 value', 'schema', 'babel_extended_property_v3_schema', 'table', 'babel_extended_property_v3_table'
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'table', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- table column
EXEC sp_addextendedproperty 'column property1   ', 'column property1 value', 'schema   ', 'babel_extended_property_v3_schema   ', 'table   ', 'babel_extended_property_v3_table   ', 'column   ', 'id   '
GO

EXEC sp_addextendedproperty 'COLUMN PROPERTY2 "{\)  ', 'COLUMN PROPERTY2 VALUE "{\)   ', 'SCHEMA   ', 'BABEL_EXTENDED_PROPERTY_V3_SCHEMA   ', 'TABLE   ', 'BABEL_EXTENDED_PROPERTY_V3_TABLE   ', 'COLUMN   ', 'id   '
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'table', 'babel_extended_property_v3_table', 'column', NULL) ORDER BY objtype, objname, name, value;
GO

-- view
CREATE VIEW babel_extended_property_v3_schema.babel_extended_property_v3_view AS
    SELECT * FROM fn_listextendedproperty() ORDER BY objtype, objname, name, value;
GO

EXEC sp_addextendedproperty 'view property1', 'view property1 value', 'schema', 'babel_extended_property_v3_schema', 'view', 'babel_extended_property_v3_view'
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'view', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- sequence
CREATE SEQUENCE babel_extended_property_v3_schema.babel_extended_property_v3_seq
GO

EXEC sp_addextendedproperty 'sequence property1', 'sequence property1 value', 'schema', 'babel_extended_property_v3_schema', 'sequence', 'babel_extended_property_v3_seq'
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'sequence', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- procedure
CREATE PROCEDURE babel_extended_property_v3_schema.babel_extended_property_v3_proc
AS
BEGIN
    RETURN 1
END
GO

EXEC sp_addextendedproperty 'procedure property1', 'procedure property1 value', 'schema', 'babel_extended_property_v3_schema', 'procedure', 'babel_extended_property_v3_proc'
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'procedure', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- function
CREATE FUNCTION babel_extended_property_v3_schema.babel_extended_property_v3_func()
RETURNS INT AS
BEGIN
    RETURN 1
END
GO

EXEC sp_addextendedproperty 'function property1', 'function property1 value', 'schema', 'babel_extended_property_v3_schema', 'function', 'babel_extended_property_v3_func'
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'function', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- type
CREATE TYPE babel_extended_property_v3_schema.babel_extended_property_v3_type
    AS TABLE(id int)
GO

EXEC sp_addextendedproperty 'type property1', 'type property1 before', 'schema', 'babel_extended_property_v3_schema', 'type', 'babel_extended_property_v3_type'
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'type', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- list all extended properties
SELECT class, class_desc, IIF(major_id > 0, 1, 0) AS major_id, minor_id, name, value FROM sys.extended_properties ORDER BY class, class_desc, name, value;
GO
