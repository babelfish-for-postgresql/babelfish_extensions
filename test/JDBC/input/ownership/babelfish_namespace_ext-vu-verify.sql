SELECT * FROM test_babelfish_namespace_ext_view
GO

EXEC test_babelfish_namespace_ext_proc
GO

SELECT test_babelfish_namespace_ext_func()
GO

SELECT nspname FROM sys.babelfish_namespace_ext WHERE nspname LIKE 'test_babelfish_namespace_sch%'
GO
