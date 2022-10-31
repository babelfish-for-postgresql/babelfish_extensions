DROP USER sp_droprole_user;
GO

DROP LOGIN sp_droprole_login;
GO

-- Check if catalog is cleaned up
SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username LIKE 'sp_droprole_r%'
GO

SELECT rolname, type
FROM sys.babelfish_authid_login_ext
WHERE rolname LIKE 'sp_droprole_r%'
GO

DROP TABLE tmp_sp_droprole;
GO
