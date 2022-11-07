SELECT * FROM babelfish_authid_user_ext_vu_prepare_view
GO

EXEC babelfish_authid_user_ext_vu_prepare_proc
GO

SELECT babelfish_authid_user_ext_vu_prepare_func()
GO

SELECT rolname FROM sys.babelfish_authid_user_ext
WHERE rolname LIKE '%babelfish_authid_user_ext_vu_prepare_%'
ORDER BY rolname
GO
