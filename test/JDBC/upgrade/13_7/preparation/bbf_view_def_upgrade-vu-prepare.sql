CREATE VIEW bbf_view_def_upgrade_vu_prepare_view AS SELECT 1;
GO

-- Will fail because isc.views(TSQL version) is not implemented
CREATE VIEW bbf_view_def_upgrade_vu_prepare_dep_view AS SELECT * FROM information_schema.views;
GO

