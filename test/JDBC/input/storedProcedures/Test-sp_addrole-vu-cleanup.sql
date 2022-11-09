-- tsql
DROP ROLE sp_addrole_r3;
GO

-- Cannot drop the role name contains leading/trailing whitespaces, special characters using DROP ROLE cmd
-- sp_droprole procedure removes trailing spaces
Exec sp_droprole '   @sp_addrole_r2   ';
GO

DROP USER sp_addrole_user;
GO

DROP LOGIN sp_addrole_login;
GO

DROP ROLE sp_addrole_r1;
GO

-- Check if catalog is cleaned up
SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username LIKE 'sp_addrole_r%'
GO

SELECT rolname, type
FROM sys.babelfish_authid_login_ext
WHERE rolname LIKE 'sp_addrole_r%'
GO

DROP TABLE tmp_sp_addrole;
GO
