CREATE TABLE schema_2961.t(a int)
GO

EXEC dbo.myproc
GO

SELECT * FROM dbo.t14
GO

DROP USER smith
GO

EXEC dbo.CallNonExistentProc
GO

EXEC dbo.DropNonExistentUser
GO

-- Attempt multiple operations within a single transaction
BEGIN TRANSACTION
    CREATE TABLE dbo.TestTable (ID INT)
    INSERT INTO dbo.TestTable VALUES (1)
    SELECT * FROM dbo.NonExistentTable
COMMIT
GO

-- Verify if the transaction rolled back correctly
SELECT * FROM dbo.TestTable
GO

CREATE DATABASE TestDB2961
GO

USE TestDB2961
GO

CREATE TABLE schema_2961.t(a int)
GO

EXEC dbo.myproc
GO

SELECT * FROM dbo.t14
GO

DROP USER smith
GO

USE master
GO

DROP DATABASE TestDB2961
GO

