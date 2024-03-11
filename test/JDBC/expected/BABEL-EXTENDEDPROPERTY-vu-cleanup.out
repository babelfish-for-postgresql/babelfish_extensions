USE master
GO

-- database
EXEC sp_dropextendedproperty 'database property1'
GO

-- view
EXEC sp_dropextendedproperty 'view property1', 'schema', 'babel_extended_property_v3_schema', 'view', 'babel_extended_property_v3_view'
GO

DROP VIEW babel_extended_property_v3_schema.babel_extended_property_v3_view;
GO

-- table column
EXEC sp_dropextendedproperty 'column property1   ', 'schema   ', 'babel_extended_property_v3_schema   ', 'table   ', 'babel_extended_property_v3_table   ', 'column   ', 'id   '
GO

EXEC sp_dropextendedproperty 'COLUMN PROPERTY2 "{\)  ', 'SCHEMA   ', 'BABEL_EXTENDED_PROPERTY_V3_SCHEMA   ', 'TABLE   ', 'BABEL_EXTENDED_PROPERTY_V3_TABLE   ', 'COLUMN   ', 'id   '
GO

-- table
EXEC sp_dropextendedproperty 'table property1', 'schema', 'babel_extended_property_v3_schema', 'table', 'babel_extended_property_v3_table'
GO

EXEC sp_dropextendedproperty 'table property2', 'schema', 'babel_extended_property_v3_schema', 'table', 'babel_extended_property_v3_table'
GO

DROP TABLE babel_extended_property_v3_schema.babel_extended_property_v3_table;
GO

-- sequence
EXEC sp_dropextendedproperty 'sequence property1', 'schema', 'babel_extended_property_v3_schema', 'sequence', 'babel_extended_property_v3_seq'
GO

DROP SEQUENCE babel_extended_property_v3_schema.babel_extended_property_v3_seq;
GO

-- procedure
EXEC sp_dropextendedproperty 'procedure property1', 'schema', 'babel_extended_property_v3_schema', 'procedure', 'babel_extended_property_v3_proc'
GO

DROP PROCEDURE babel_extended_property_v3_schema.babel_extended_property_v3_proc;
GO

-- function
EXEC sp_dropextendedproperty 'function property1', 'schema', 'babel_extended_property_v3_schema', 'function', 'babel_extended_property_v3_func'
GO

DROP FUNCTION babel_extended_property_v3_schema.babel_extended_property_v3_func;
GO

-- type
EXEC sp_dropextendedproperty 'type property1', 'schema', 'babel_extended_property_v3_schema', 'type', 'babel_extended_property_v3_type'
GO

DROP TYPE babel_extended_property_v3_schema.babel_extended_property_v3_type;
GO

-- schema
EXEC sp_dropextendedproperty 'schema property1', 'schema', 'babel_extended_property_v3_schema'
GO

DROP SCHEMA babel_extended_property_v3_schema
GO
