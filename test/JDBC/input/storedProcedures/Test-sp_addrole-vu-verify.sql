USE master
GO

-- Throws an error when role exists
Exec sp_addrole 'sp_addrole_r1';
GO

EXEC sp_addrole 'sp_addrole_r2';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_addrole_r2'
GO

-- Throws an error when role exists
EXEC sp_addrole 'sp_addrole_r2';
GO
