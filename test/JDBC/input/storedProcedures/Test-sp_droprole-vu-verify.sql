-- tsql
DROP ROLE sp_droprole_r1;
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_r1';
GO

EXEC sp_droprole 'sp_droprole_r2';
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_r2';
GO

-- Throws an error when the role doesn't exist
EXEC sp_droprole 'sp_droprole_r3';
GO
