CREATE VIEW bbf_view_def_upgrade_vu_prepare_view AS SELECT 1;
GO

-- Won't fail because it will refer PG's information_schema
CREATE VIEW bbf_view_def_upgrade_vu_prepare_dep_view AS SELECT * FROM information_schema.views;
GO

