-- Create test database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TestConvertForBinary')
BEGIN
    CREATE DATABASE TestConvertForBinary;
END
GO

USE TestConvertForBinary;
GO

-- Create complex test tables
CREATE TABLE Employee (
    EmployeeID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Salary DECIMAL(15,2),
    HireDate DATETIME,
    Department VARCHAR(50),
    EncryptedData VARBINARY(MAX)
);
GO

INSERT INTO Employee (EmployeeID, FirstName, LastName, Salary, HireDate, Department)
VALUES 
(1, N'John', N'Doe', 75000.50, '2023-01-15 09:00:00', 'IT'),
(2, N'Jane', N'Smith', 82000.75, '2022-11-30 10:30:00', 'HR'),
(3, N'张', N'伟', 95000.00, '2023-03-20 14:15:00', 'Engineering'),
(4, N'José', N'García', 68000.25, '2023-02-28 11:45:00', 'Sales');
GO

-- Create helper functions
CREATE FUNCTION dbo.GenerateRandomBinary(@length INT)
RETURNS VARBINARY(MAX)
AS
BEGIN
    DECLARE @result VARBINARY(MAX) = 0x;
    DECLARE @counter INT = 0;
    
    WHILE @counter < @length
    BEGIN
        SET @result = @result + CAST(CAST(RAND() * 255 AS INT) AS BINARY(1));
        SET @counter = @counter + 1;
    END
    
    RETURN @result;
END;
GO

-- Create main tables
CREATE TABLE Documents (
    DocID INT PRIMARY KEY,
    DocName NVARCHAR(100),
    DocContent VARBINARY(MAX),
    CreatedDate DATETIME DEFAULT '2023-01-01 10:00:00',
    ModifiedDate DATETIME,
    DocType VARCHAR(50)
);
GO

CREATE TABLE DocumentVersions (
    VersionID INT,
    DocID INT ,
    VersionNumber INT,
    BinaryContent VARBINARY(MAX),
    CreatedDate DATETIME DEFAULT '2023-01-01 10:00:00'
);
GO

-------- Create Views
CREATE VIEW vw_DocumentBinaryInfo
AS
SELECT 
    d.DocID,
    d.DocName,
    CONVERT(BINARY(100), d.DocContent) AS ConvertedContent,
    d.DocType
FROM Documents d;
GO

CREATE VIEW vw_DocumentVersionComparison
AS
SELECT 
    d.DocID,
    d.DocName,
    CONVERT(BINARY(50), dv1.BinaryContent) AS CurrentVersion,
    CONVERT(BINARY(50), dv2.BinaryContent) AS PreviousVersion
FROM Documents d
JOIN DocumentVersions dv1 ON d.DocID = dv1.DocID
LEFT JOIN DocumentVersions dv2 ON d.DocID = dv2.DocID 
    AND dv1.VersionNumber = dv2.VersionNumber + 1;
GO

---------- Create Functions
CREATE FUNCTION fn_ConvertAndCompare
(
    @binary1 VARBINARY(MAX),
    @binary2 VARBINARY(MAX)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        CONVERT(BINARY(100), @binary1) AS FirstBinary,
        CONVERT(BINARY(100), @binary2) AS SecondBinary,
        CASE 
            WHEN CONVERT(BINARY(100), @binary1) = CONVERT(BINARY(100), @binary2) 
            THEN 'Equal' 
            ELSE 'Different'
        END AS ComparisonResult
);
GO

CREATE FUNCTION fn_GetBinaryHash
(
    @input VARBINARY(MAX)
)
RETURNS BINARY(32)
AS
BEGIN
    RETURN CONVERT(BINARY(32), HASHBYTES('SHA2_256', @input));
END;
GO

---------- Create Stored Procedures
CREATE PROCEDURE sp_InsertDocument
    @docID INT,
    @docName NVARCHAR(100),
    @content VARBINARY(MAX),
    @docType VARCHAR(50)
AS
BEGIN
    SELECT CONVERT(BINARY(50), @content) as ConvertedContent, @docType as DocType, '2023-01-01 10:00:00' as ModifiedDate;
END;
GO

CREATE PROCEDURE sp_UpdateDocument
    @docID INT,
    @newContent VARBINARY(MAX)
AS
BEGIN
    DECLARE @currentVersion INT;
    
    SELECT @currentVersion = MAX(VersionNumber)
    FROM DocumentVersions
    WHERE DocID = @docID;

    SELECT @docID as DocID, CONVERT(BINARY(50), @newContent) as ConvertedNewContent;
END;
GO

-- Insert Initial Test Data
INSERT INTO Documents (DocID, DocName, DocContent, DocType, CreatedDate)
VALUES 
(1, 'Test1.txt', CAST('Initial Content 1' AS VARBINARY(MAX)), 'TXT', '2023-01-01 10:00:00'),
(2, 'Test2.doc', CAST('Initial Content 2' AS VARBINARY(MAX)), 'DOC', '2023-01-01 10:00:00');
GO

INSERT INTO DocumentVersions (VersionID, DocID, VersionNumber, BinaryContent, CreatedDate)
VALUES 
(11, 1, 1, CAST('Initial Content 1' AS VARBINARY(MAX)), '2023-01-01 10:00:00'),
(21, 2, 1, CAST('Initial Content 2' AS VARBINARY(MAX)), '2023-01-01 10:00:00');
GO

-- Create Triggers
CREATE TRIGGER tr_DocumentBinaryValidation
ON Documents
AFTER INSERT, UPDATE
AS
BEGIN
    SELECT 
        DocID,
        DocName,
        CONVERT(BINARY(50), DocContent) as ConvertedContent
    FROM inserted;
END;
GO
