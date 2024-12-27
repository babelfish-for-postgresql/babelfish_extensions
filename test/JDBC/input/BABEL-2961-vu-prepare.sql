-- Create a view that attempts to select from a non-existent table
CREATE VIEW dbo.NonExistentTableView AS
SELECT * FROM dbo.SomeNonExistentTable
GO


-- Create a function that attempts to select from a non-existent table
CREATE FUNCTION dbo.NonExistentTableFunc()
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM dbo.SomeNonExistentTable
)
GO

-- Create a procedure that attempts to execute a non-existent procedure
CREATE PROCEDURE dbo.CallNonExistentProc
AS
BEGIN
    EXEC dbo.NonExistentProc
END
GO


-- Create a function that attempts to use a non-existent schema
CREATE FUNCTION nonexistent_schema.TestFunc()
RETURNS INT
AS
BEGIN
    RETURN 1
END
GO


-- Create a procedure that attempts to drop a non-existent user
CREATE PROCEDURE dbo.DropNonExistentUser
AS
BEGIN
    DROP USER NonExistentUser
END
GO
