SELECT * FROM babel_extended_property_v3_schema.babel_extended_property_v3_view;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', NULL, NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'table', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'table', 'babel_extended_property_v3_table', 'column', NULL) ORDER BY objtype, objname, name, value;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'view', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'sequence', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'procedure', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'function', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

SELECT * FROM fn_listextendedproperty(NULL, 'schema', 'babel_extended_property_v3_schema', 'type', NULL, NULL, NULL) ORDER BY objtype, objname, name, value;
GO

-- list all extended properties
SELECT class, class_desc, IIF(major_id > 0, 1, 0) AS major_id, minor_id, name, value FROM sys.extended_properties ORDER BY class, class_desc, name, value;
GO
