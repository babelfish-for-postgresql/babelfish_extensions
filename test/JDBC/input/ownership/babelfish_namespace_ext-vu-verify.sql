SELECT * FROM babelfish_namespace_ext_vu_prepare_view
GO

EXEC babelfish_namespace_ext_vu_prepare_proc
GO

SELECT babelfish_namespace_ext_vu_prepare_func()
GO

SELECT nspname FROM sys.babelfish_namespace_ext WHERE nspname LIKE '%test_babelfish_namespace_sch%'
ORDER BY nspname
GO
