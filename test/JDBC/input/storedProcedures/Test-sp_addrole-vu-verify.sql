-- tsql
CREATE ROLE sp_addrole_r1;
GO

--Throws an error if the argument is empty or contains backslash(\)
Exec sp_addrole '';
GO

Exec sp_addrole '\';
GO

-- Throws an error when role exists
Exec sp_addrole 'sp_addrole_r1';
GO

-- Creates role even if it contains leading/trailing spaces, special characters(except \)
Exec sp_addrole '   @sp_addrole_r2   ';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = '   @sp_addrole_r2   '
GO

-- sp_addrole is case insensitive, storing all role values in lower case in DB
EXEC sp_addrole 'SP_ADDROLE_R3';
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
