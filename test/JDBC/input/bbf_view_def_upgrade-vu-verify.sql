SELECT vd.schema_name, vd.object_name, vd.definition FROM babelfish_view_def vd WHERE vd.object_name LIKE '%view_3135%' ORDER BY vd.schema_name, vd.object_name, vd.definition;
GO

SELECT vd.schema_name, vd.object_name, vd.definition FROM dep_view_3135 vd WHERE vd.object_name LIKE '%view_3135%' ORDER BY vd.schema_name, vd.object_name, vd.definition;
GO

SELECT * FROM dep_view_3135_2 WHERE "TABLE_NAME" LIKE '%view_3135%';
GO

DROP VIEW view_3135_upd;
GO

DROP VIEW dep_view_3135;
GO

DROP VIEW dep_view_3135_2;
GO
