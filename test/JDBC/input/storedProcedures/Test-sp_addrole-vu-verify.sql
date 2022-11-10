-- tsql
CREATE ROLE sp_addrole_r1;
GO

CREATE LOGIN sp_addrole_login WITH PASSWORD = '123';
GO

CREATE USER sp_addrole_user FOR LOGIN sp_addrole_login;
GO

-- Throws an error if the argument is empty or contains backslash(\)
EXEC sp_addrole NULL;
GO

EXEC sp_addrole '';
GO

EXEC sp_addrole '\';
GO

-- Throw error if rolename is empty after removing trailing spaces
EXEC sp_addrole '     ';
GO

-- Throw error if no argument or more than 2 arguments are passed to sp_addrole procedure
EXEC sp_addrole;
GO

EXEC sp_addrole '','','';
GO

-- @ownername is not yet supported in babelfish
EXEC sp_addrole 'sp_addrole_r1', '';
GO

EXEC sp_addrole 'sp_addrole_r1', 'sp_addrole_owner1';
GO

-- The addrole procedure doesnot consider ownername if we pass NULL
-- Throws an error when role exists in DB
EXEC sp_addrole 'sp_addrole_r1', NULL;
GO

EXEC sp_addrole 'sp_addrole_user';
GO

-- Creates role even if rolename contains leading/trailing spaces, special characters(except \) by removing trailing spaces
EXEC sp_addrole '   @sp_addrole_r2   ';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = '   @sp_addrole_r2   '
GO

-- sp_addrole is case sensitive while storing the original username and stores the rolname in lowercase
EXEC sp_addrole 'SP_ADDROLE_R3';
GO

select name from sys.database_principals where name = 'SP_ADDROLE_R3';
GO

-- Throws an error when role exists
EXEC sp_addrole 'SP_ADDROLE_R3';
GO

EXEC sp_addrole 'sp_addrole_r3';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_addrole_r3'
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'SP_ADDROLE_R3'
GO