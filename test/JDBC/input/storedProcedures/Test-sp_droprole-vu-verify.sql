-- tsql
CREATE ROLE sp_droprole_r1;
GO

CREATE ROLE sp_droprole_r2;
GO

DROP ROLE sp_droprole_r1;
GO

-- Throw an error if rolname contains whitespaces or \ in it
Exec sp_droprole 'sp_droprole_\r1';
GO

-- Throw an error if rolname contains whitespaces or \ in it
Exec sp_droprole 'sp_droprole_ r1';
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_r1';
GO

-- Drops role by removing leading and trailing whitespaces
EXEC sp_droprole '   sp_droprole_r2   ';
GO

SELECT rolname, type, orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'sp_droprole_r2'
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_r2';
GO
