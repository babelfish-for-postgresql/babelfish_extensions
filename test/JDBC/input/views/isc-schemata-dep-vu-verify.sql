SELECT isc_schemata_dep_vu_prepare_func()
GO

EXEC isc_schemata_dep_vu_prepare_proc
GO

SELECT * FROM isc_schemata_dep_vu_prepare_view
GO

