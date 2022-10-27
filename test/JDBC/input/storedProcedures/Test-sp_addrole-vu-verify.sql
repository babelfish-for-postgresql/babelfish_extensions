-- tsql
CREATE ROLE sp_addrole_r1;
GO

-- Throws an error when role exists
Exec sp_addrole 'sp_addrole_r1';
GO

-- Creates role by removing leading and trailing whitespaces
Exec sp_addrole '   sp_addrole_r2   ';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_addrole_r2'
GO

-- Throw an error if rolname contains whitespaces or \ in it
Exec sp_addrole 'sp_addrole_\r3';
GO

-- Throw an error if rolname contains whitespaces or \ in it
Exec sp_addrole 'sp_addrole_ r3';
GO

EXEC sp_addrole 'sp_addrole_r3';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_addrole_r3'
GO

-- Throws an error when role exists
EXEC sp_addrole 'sp_addrole_r3';
GO
