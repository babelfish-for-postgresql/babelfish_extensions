SELECT * FROM babelfish_inconsistent_metadata_vu_prepare_view
GO

EXEC babelfish_inconsistent_metadata_vu_prepare_proc
GO

SELECT babelfish_inconsistent_metadata_vu_prepare_func()
GO
