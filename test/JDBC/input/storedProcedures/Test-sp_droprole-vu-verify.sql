-- tsql
CREATE ROLE sp_droprole_r1;
GO

CREATE ROLE sp_droprole_r2;
GO

CREATE LOGIN sp_droprole_login WITH PASSWORD = '123';
GO

CREATE USER sp_droprole_user FOR LOGIN sp_droprole_login;
GO

ALTER ROLE SP_DROPROLE_R1 ADD MEMBER SP_DROPROLE_R2;
GO

-- Throw error if no argument or more than 1 argument are passed to sp_droprole procedure
EXEC sp_droprole;
GO

EXEC sp_droprole '','','';
GO

--Throws an error if the argument is empty or contains backslash(\)
EXEC sp_droprole '';
GO

EXEC sp_droprole NULL;
GO

--Throw an error when passed argument is not an role
EXEC sp_droprole 'sp_droprole_user';
GO

EXEC sp_droprole 'sp_droprole_login';
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_doesnot_exist';
GO

-- sp_droprole is case insensitive, drops the role when exists
-- Cannot drop the role if member exists for a role
EXEC sp_droprole 'SP_droprole_R1';
GO

ALTER ROLE SP_DROPROLE_R1 DROP MEMBER SP_DROPROLE_R2;
GO

EXEC sp_droprole 'sp_droprole_r1';
GO

-- Droprole procedure does not remove leading spaces but removes trailing spaces and check for the role in DB
EXEC sp_droprole ' sp_droprole_r2';
GO

EXEC sp_droprole 'SP_DROPROLE_R2 ';
GO

EXEC sp_droprole 'sp_droprole_r2';
GO

-- Check role is present in DB
SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_droprole_r1'
GO
