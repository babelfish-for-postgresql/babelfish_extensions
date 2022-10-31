-- tsql
CREATE ROLE sp_droprole_r1;
GO

CREATE LOGIN sp_droprole_login WITH PASSWORD = '123';
GO

CREATE USER sp_droprole_user FOR LOGIN sp_droprole_login;
GO

-- Throw error if no argument or more than 1 argument are passed to sp_droprole procedure
EXEC sp_droprole;
GO

EXEC sp_droprole '','','';
GO

--Throws an error if the argument is empty or contains backslash(\)
Exec sp_droprole '';
GO

--Throw an error when passed argument is not an role
EXEC sp_droprole 'sp_droprole_user';
GO

EXEC sp_droprole 'sp_droprole_login';
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_doesnot_exist';
GO

-- Drops the role when exists
EXEC sp_droprole 'sp_droprole_r1';
GO

-- Check role is present in DB
SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_droprole_r1'
GO
