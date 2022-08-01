SELECT * FROM test_babelfish_authid_user_ext_view
GO

EXEC test_babelfish_authid_user_ext_proc
GO

SELECT test_babelfish_authid_user_ext_func()
GO

SELECT rolname FROM sys.babelfish_authid_user_ext
WHERE rolname LIKE '%test_babelfish_authid_user_ext_%'
GO
