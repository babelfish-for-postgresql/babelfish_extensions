SELECT vd.schema_name, vd.object_name, vd.definition FROM babelfish_view_def vd WHERE vd.object_name LIKE '%bbf_view_def_upgrade_vu_prepare%' ORDER BY vd.schema_name, vd.object_name, vd.definition;
GO

SELECT * FROM bbf_view_def_upgrade_vu_prepare_dep_view WHERE "TABLE_NAME" LIKE '%bbf_view_def_upgrade_vu_prepare%';
GO

DROP VIEW bbf_view_def_upgrade_vu_prepare_view;
GO

DROP VIEW bbf_view_def_upgrade_vu_prepare_dep_view;
GO

