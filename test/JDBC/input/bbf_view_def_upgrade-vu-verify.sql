SELECT vd.schema_name, vd.object_name, vd.definition FROM babelfish_view_def vd ORDER BY vd.schema_name, vd.object_name, vd.definition;
GO

SELECT vd.schema_name, vd.object_name, vd.definition FROM dep_view_3135 vd ORDER BY vd.schema_name, vd.object_name, vd.definition;
GO

SELECT * FROM dep_view_3135_2;
GO

DROP VIEW view_3135_upd;
GO

DROP VIEW dep_view_3135;
GO

DROP VIEW dep_view_3135_2;
GO
