-- tsql
CREATE ROLE sp_addrole_r1;
GO

CREATE LOGIN sp_addrole_login WITH PASSWORD = '123';
GO

CREATE USER sp_addrole_user FOR LOGIN sp_addrole_login;
GO

--Throws an error if the argument is empty or contains backslash(\)
EXEC sp_addrole '';
GO

EXEC sp_addrole '\';
GO

-- Throw error if no argument or more than 2 arguments are passed to sp_addrole procedure
EXEC sp_addrole;
GO

EXEC sp_addrole '','','';
GO

--If there are 2 arguments then the procedure first checks for whether argument1 name is empty or not
-- If argument is empty throw an error
EXEC sp_addrole '','';
GO

EXEC sp_addrole '','sp_addrole_doesnot_exist';
GO

-- Throw an error if 2nd argument is empty or does not exist
EXEC sp_addrole 'sp_addrole_doesnot_exist','';
GO

EXEC sp_addrole 'sp_addrole_r1','sp_addrole_doesnot_exist';
GO

-- If second argument is not empty and contains in database
-- Throws an error if first argument already exists in DB
EXEC sp_addrole 'sp_addrole_r1','sp_addrole_r1';
GO

-- Succesfully executes if first argument does not exist in DB
EXEC sp_addrole 'sp_addrole_r2','sp_addrole_r1';
GO

-- Throws an error when role exists in DB
EXEC sp_addrole 'sp_addrole_r1';
GO

EXEC sp_addrole 'sp_addrole_r2';
GO

EXEC sp_addrole 'sp_addrole_user';
GO

-- Creates role even if it contains leading/trailing spaces, special characters(except \)
EXEC sp_addrole '   @sp_addrole_r3   ';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = '   @sp_addrole_r3   '
GO

-- sp_addrole is case insensitive, storing all role values in lower case in DB
EXEC sp_addrole 'SP_ADDROLE_R4';
GO

-- Throws an error when role exists
EXEC sp_addrole 'SP_ADDROLE_R4';
GO

EXEC sp_addrole 'sp_addrole_r4';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_addrole_r4'
GO
