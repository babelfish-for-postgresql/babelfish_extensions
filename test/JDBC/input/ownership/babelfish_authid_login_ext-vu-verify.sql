SELECT * FROM test_babelfish_authid_login_ext_view
GO

EXEC test_babelfish_authid_login_ext_proc
GO

SELECT test_babelfish_authid_login_ext_func()
GO

SELECT rolname FROM sys.babelfish_authid_login_ext 
WHERE rolname LIKE 'test_babelfish_authid_login_ext_login%'
GO
