-- tsql
DROP ROLE sp_droprole_r1;
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_r1';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_droprole_r2'
GO

EXEC sp_droprole 'sp_droprole_r2';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_addrole_r2'
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_r2';
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
