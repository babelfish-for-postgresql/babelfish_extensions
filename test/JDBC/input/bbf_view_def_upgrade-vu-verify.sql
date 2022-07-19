SELECT sb.name, vd.schema_name, vd.object_name, vd.definition FROM babelfish_view_def vd LEFT JOIN sys.sysdatabases sb ON vd.dbid=sb.dbid WHERE vd.object_name='view_3135_upd' ORDER BY vd.dbid, vd.schema_name, vd.object_name, vd.definition;
GO

SELECT sb.name, vd.schema_name, vd.object_name, vd.definition FROM dep_view_3135 vd LEFT JOIN sys.sysdatabases sb ON vd.dbid=sb.dbid WHERE vd.object_name='view_3135_upd' ORDER BY vd.dbid, vd.schema_name, vd.object_name, vd.definition;
GO

DROP VIEW view_3135_upd;
GO

DROP VIEW dep_view_3135;
GO

