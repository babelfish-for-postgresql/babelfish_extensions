IF OBJECT_ID('dbo.SomeNonExistentTable', 'U') IS NOT NULL
    DROP TABLE dbo.SomeNonExistentTable
GO


IF OBJECT_ID('dbo.NonExistentTableView', 'V') IS NOT NULL
    DROP VIEW dbo.NonExistentTableView
GO

IF OBJECT_ID('dbo.NonExistentTableFunc', 'IF') IS NOT NULL
    DROP FUNCTION dbo.NonExistentTableFunc
GO

IF OBJECT_ID('dbo.CallNonExistentProc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CallNonExistentProc
GO

IF OBJECT_ID('dbo.TestTable', 'U') IS NOT NULL
    DROP TABLE dbo.TestTable
GO

IF OBJECT_ID('dbo.NonExistentTable', 'U') IS NOT NULL
    DROP TABLE dbo.NonExistentTable
GO

IF OBJECT_ID('dbo.DropNonExistentUser', 'P') IS NOT NULL
    DROP PROCEDURE dbo.DropNonExistentUser
GO

IF OBJECT_ID('dbo.NonExistentProc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.NonExistentProc
GO

IF OBJECT_ID('nonexistent_schema.TestFunc', 'FN') IS NOT NULL
    DROP FUNCTION nonexistent_schema.TestFunc
GO
