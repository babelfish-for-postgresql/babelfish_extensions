SELECT sb.name, vd.schema_name, vd.object_name, vd.definition FROM babelfish_view_def vd LEFT JOIN sys.sysdatabases sb ON vd.dbid=sb.dbid ORDER BY vd.dbid, vd.schema_name, vd.object_name, vd.definition WHERE vd.object_name='view_3135_upd';
GO

SELECT sb.name, vd.schema_name, vd.object_name, vd.definition FROM dep_view_3135 vd LEFT JOIN sys.sysdatabases sb ON vd.dbid=sb.dbid ORDER BY vd.dbid, vd.schema_name, vd.object_name, vd.definition WHERE vd.object_name='view_3135_upd';
GO

DROP VIEW view_3135_upd;
GO

DROP VIEW dep_view_3135;
GO

