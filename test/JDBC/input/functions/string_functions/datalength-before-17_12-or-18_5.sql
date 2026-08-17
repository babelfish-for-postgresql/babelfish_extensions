CREATE TYPE EmailAddress FROM VARCHAR(255);
GO

CREATE TYPE PhoneNumber FROM CHAR(10);
GO

CREATE TYPE FullName FROM NVARCHAR(100);
GO

CREATE TYPE Description FROM TEXT;
GO

CREATE TYPE Unicode_Description FROM NTEXT;
GO

CREATE TYPE ShortCode FROM CHAR(5);
GO

CREATE TYPE LongText FROM VARCHAR(MAX);
GO

CREATE TYPE UnicodeCode FROM NCHAR(10);
GO

CREATE TABLE datalength_t5 (
    ID INT PRIMARY KEY,
    Email EmailAddress,
    Phone PhoneNumber,
    Name FullName,
    Desc1 Description,
    Desc2 Unicode_Description,
    Code ShortCode,
    Details LongText,
    UCode UnicodeCode
);
GO

INSERT INTO datalength_t5 VALUES
(1, 'test@example.com', '1234567890', N'John Doe', 'Simple description', 
 N'Unicode description', 'ABC12', 'Long text details', N'UNICODE123');
GO

-- Computed Column Tests with UDTs
CREATE TABLE datalength_t6 (
    ID INT PRIMARY KEY,
    Code ShortCode,
    CodeLength AS DATALENGTH(Code) PERSISTED
);
GO

INSERT INTO datalength_t6 (ID, Code) VALUES 
(1, 'ABC12'),
(2, 'XY');
GO

-- Create base table for dependent objects
CREATE TABLE datalength_t7 (
    ID INT PRIMARY KEY,
    Email VARCHAR(255),
    Code CHAR(10),
    Name NVARCHAR(100),
    Description TEXT,
    UnicodeDesc NTEXT
);
GO

INSERT INTO datalength_t7 VALUES
(1, 'test@example.com', 'CODE123456', N'John Doe', 'Simple description', N'Unicode description'),
(2, 'long.email@example.com', 'SHORT', N'Jane Smith', 'Another desc', N'Another unicode'),
(3, '', '', N'', '', N'');
GO

-- View using DATALENGTH
CREATE VIEW datalength_vw_DataLengthInfo AS
SELECT 
    ID,
    Email,
    DATALENGTH(Email) AS Email_Size,
    Code,
    DATALENGTH(Code) AS Code_Size,
    Name,
    DATALENGTH(Name) AS Name_Size,
    Description,
    DATALENGTH(Description) AS Desc_Size,
    UnicodeDesc,
    DATALENGTH(UnicodeDesc) AS UnicodeDesc_Size,
    DATALENGTH(Email) + DATALENGTH(Code) + DATALENGTH(Name) AS Total_Size
FROM datalength_t7;
GO

CREATE VIEW datalength_vw_DataSizeCategories AS
SELECT 
    ID,
    Email,
    CASE 
        WHEN DATALENGTH(Email) = 0 THEN 'Empty'
        WHEN DATALENGTH(Email) <= 20 THEN 'Small'
        ELSE 'Large'
    END AS Email_Category,
    Name,
    CASE 
        WHEN DATALENGTH(Name) = 0 THEN 'Empty'
        WHEN DATALENGTH(Name) <= 20 THEN 'Small'
        WHEN DATALENGTH(Name) <= 50 THEN 'Medium'
        ELSE 'Large'
    END AS Name_Category
FROM datalength_t7;
GO

-- Scalar Functions using DATALENGTH
CREATE FUNCTION datalength_fn_GetTotalSize
(
    @Email VARCHAR(255),
    @Code CHAR(10),
    @Name NVARCHAR(100)
)
RETURNS INT
AS
BEGIN
    RETURN ISNULL(DATALENGTH(@Email), 0) + 
           ISNULL(DATALENGTH(@Code), 0) + 
           ISNULL(DATALENGTH(@Name), 0);
END;
GO

-- Table-Valued Functions using DATALENGTH
CREATE FUNCTION datalength_fn_GetSizeAnalysis()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ID,
        Email,
        DATALENGTH(Email) AS EmailSize,
        Code,
        DATALENGTH(Code) AS CodeSize,
        Name,
        DATALENGTH(Name) AS NameSize,
        DATALENGTH(Description) AS DescSize,
        DATALENGTH(UnicodeDesc) AS UnicodeDescSize
    FROM datalength_t7
    WHERE DATALENGTH(Email) > 0 OR DATALENGTH(Name) > 0
);
GO

-- Stored Procedures using DATALENGTH
CREATE PROCEDURE datalength_sp_AnalyzeDataSizes
    @MinSize INT = 0
AS
BEGIN
    SELECT 
        ID,
        Email,
        DATALENGTH(Email) AS EmailSize,
        Name,
        DATALENGTH(Name) AS NameSize
    FROM datalength_t7
    WHERE DATALENGTH(Email) > @MinSize OR DATALENGTH(Name) > @MinSize
    ORDER BY DATALENGTH(Email) + DATALENGTH(Name) DESC;
END;
GO

CREATE PROCEDURE datalength_sp_ValidateAndInsert
    @Email VARCHAR(255),
    @Code CHAR(10),
    @Name NVARCHAR(100)
AS
BEGIN
    IF DATALENGTH(@Email) > 255 OR DATALENGTH(@Name) > 100
    BEGIN
        RAISERROR ('Data exceeds maximum length', 16, 1);
        RETURN;
    END

    INSERT INTO datalength_t7 (ID, Email, Code, Name, Description, UnicodeDesc)
    VALUES (
        (SELECT ISNULL(MAX(ID), 0) + 1 FROM datalength_t7),
        @Email, @Code, @Name, '', N''
    );
END;
GO

-- Computed Columns using DATALENGTH
CREATE TABLE datalength_ComputedColumnsTest (
    ID INT PRIMARY KEY,
    Email VARCHAR(255),
    Name NVARCHAR(100),
    EmailSize AS DATALENGTH(Email) PERSISTED,
    NameSize AS DATALENGTH(Name) PERSISTED,
    TotalSize AS DATALENGTH(Email) + DATALENGTH(Name) PERSISTED,
    SizeCategory AS CASE 
                    WHEN DATALENGTH(Email) + DATALENGTH(Name) = 0 THEN 'Empty'
                    WHEN DATALENGTH(Email) + DATALENGTH(Name) <= 20 THEN 'Small'
                    WHEN DATALENGTH(Email) + DATALENGTH(Name) <= 50 THEN 'Medium'
                    ELSE 'Large'
                   END PERSISTED
);
GO

INSERT INTO datalength_ComputedColumnsTest (ID, Email, Name) VALUES
(1, 'test@example.com', N'John Doe'),
(2, 'short@ex.com', N'Jane'),
(3, '', N'');

-- Check Constraints using DATALENGTH
CREATE TABLE datalength_ConstrainedTable (
    ID INT PRIMARY KEY,
    Email VARCHAR(255) CONSTRAINT CHK_Email_Size 
        CHECK (DATALENGTH(Email) BETWEEN 5 AND 255),
    Code CHAR(10) CONSTRAINT CHK_Code_Size 
        CHECK (DATALENGTH(Code) <= 10),
    Name NVARCHAR(100) CONSTRAINT CHK_Name_NotEmpty 
        CHECK (DATALENGTH(Name) > 0)
);
GO

-- Triggers using DATALENGTH
CREATE TRIGGER datalength_tr_ValidateDataLength
ON datalength_t7
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE DATALENGTH(Email) > 255 
           OR DATALENGTH(Code) > 10
           OR DATALENGTH(Name) > 100
    )
    BEGIN
        RAISERROR ('Data length exceeds maximum allowed size', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Indexed Views using DATALENGTH
CREATE VIEW datalength_vw_DataLengthSummary
WITH SCHEMABINDING
AS
SELECT 
    ID,
    DATALENGTH(Email) AS EmailSize,
    DATALENGTH(Code) AS CodeSize,
    DATALENGTH(Name) AS NameSize
FROM dbo.datalength_t7;
GO

CREATE UNIQUE CLUSTERED INDEX IX_DataLengthSummary 
ON datalength_vw_DataLengthSummary(ID);
GO


-- 1. Basic String Types Tests
SELECT 
    DATALENGTH('') AS EmptyString_Length,
    DATALENGTH('A') AS SingleChar_Length,
    DATALENGTH('Hello') AS String_Length,
    DATALENGTH('Hello World') AS StringWithSpace_Length;
GO

-- 2. Unicode vs Non-Unicode Tests
SELECT 
    DATALENGTH('Hello') AS ASCII_Length,
    DATALENGTH(N'Hello') AS Unicode_Length,
    DATALENGTH('こんにちは') AS Japanese_ASCII_Length,
    DATALENGTH(N'こんにちは') AS Japanese_Unicode_Length,
    DATALENGTH('🌟') AS Emoji_ASCII_Length,
    DATALENGTH(N'🌟') AS Emoji_Unicode_Length;
GO

-- 3. Fixed vs Variable Length Types
CREATE TABLE datalength_t1 (
    CharCol CHAR(10),
    VarcharCol VARCHAR(10),
    NCharCol NCHAR(10),
    NVarcharCol NVARCHAR(10),
    TextCol TEXT,
    NTextCol NTEXT
);
GO

INSERT INTO datalength_t1 VALUES
    ('Hello', 'Hello', N'Hello', N'Hello', 'Hello', N'Hello');
GO

SELECT 
    DATALENGTH(CharCol) AS Char_DataLength,
    DATALENGTH(VarcharCol) AS Varchar_DataLength,
    DATALENGTH(NCharCol) AS NChar_DataLength,
    DATALENGTH(NVarcharCol) AS NVarchar_DataLength,
    DATALENGTH(TextCol) AS Text_DataLength,
    DATALENGTH(NTextCol) AS NText_DataLength
FROM datalength_t1;
GO

-- 4. Numeric Data Types
SELECT 
    DATALENGTH(CAST(123 AS TINYINT)) AS TinyInt_Length,
    DATALENGTH(CAST(123 AS SMALLINT)) AS SmallInt_Length,
    DATALENGTH(CAST(123 AS INT)) AS Int_Length,
    DATALENGTH(CAST(123 AS BIGINT)) AS BigInt_Length;
GO

SELECT
    DATALENGTH(CAST(123.45 AS DECIMAL(10,2))) AS Decimal_Length,
    DATALENGTH(CAST(123.45 AS NUMERIC(10,2))) AS Numeric_Length,
    DATALENGTH(CAST(123.45 AS FLOAT)) AS Float_Length,
    DATALENGTH(CAST(123.45 AS REAL)) AS Real_Length;
GO

-- 5. DateTime Data Types
SELECT 
    DATALENGTH(CAST('2024-01-01' AS DATE)) AS Date_Length,
    DATALENGTH(CAST('2024-01-01 12:34:56' AS DATETIME)) AS DateTime_Length,
    DATALENGTH(CAST('2024-01-01 12:34:56' AS DATETIME2)) AS DateTime2_Length,
    DATALENGTH(CAST('2024-01-01 12:34:56' AS SMALLDATETIME)) AS SmallDateTime_Length,
    DATALENGTH(CAST('12:34:56' AS TIME)) AS Time_Length,
    DATALENGTH(CAST('2024-01-01 12:34:56 +00:00' AS DATETIMEOFFSET)) AS DateTimeOffset_Length;
GO

-- 6. Binary Data Types
SELECT 
    DATALENGTH(CAST('Hello' AS BINARY(10))) AS Binary_Length,
    DATALENGTH(CAST('Hello' AS VARBINARY(10))) AS VarBinary_Length,
    DATALENGTH(CAST('Hello' AS VARBINARY(MAX))) AS VarBinaryMax_Length,
    DATALENGTH(CAST('Hello' AS IMAGE)) AS Image_Length;
GO

-- empty string 
SELECT  
    DATALENGTH(CAST('' AS BINARY(10))) as binary_10,  
    DATALENGTH(CAST('' AS BINARY)) as binary_default, 
    DATALENGTH(CAST(0x00 AS BINARY)) as binary_0_default, 
    DATALENGTH(CAST('0x00' AS BINARY)) as binary_str0_default, 
    DATALENGTH(CAST('  ' AS BINARY(10))) as binary_space_10,  
    DATALENGTH(CAST('  ' AS BINARY)) as binary__space_default, 
    DATALENGTH(CAST('' AS VARBINARY(10))) as varbinary_10,  
    DATALENGTH(CAST('' AS VARBINARY)) as varbinary_default  
GO

-- NULL testing
SELECT  
    DATALENGTH(CAST(NULL AS BINARY(10))) as binary_10,  
    DATALENGTH(CAST(NULL AS BINARY)) as binary_default, 
    DATALENGTH(CAST('NULL' AS BINARY)) as binary_str0_default,  
    DATALENGTH(CAST(' NULL  ' AS BINARY)) as binary_space_default,
    DATALENGTH(CAST(NULL AS VARBINARY(10))) as varbinary_10,  
    DATALENGTH(CAST(NULL AS VARBINARY)) as varbinary_default,
    DATALENGTH(CAST('NULL' AS VARBINARY)) as varbinary_str_default,
    DATALENGTH(CAST(' NULL ' AS VARBINARY)) as varbinary_space_default   
GO

-- binary to varbinary, empty string
select 
    DATALENGTH(CAST(CAST(0x00 AS BINARY) as varbinary)),
    DATALENGTH(cast(CAST('0x00' AS BINARY) as varbinary)),
    DATALENGTH(cast(CAST('' AS BINARY(10)) as varbinary(10))),
    DATALENGTH(cast(CAST('' AS BINARY(10)) as varbinary(max))),
    DATALENGTH(cast(CAST('' AS BINARY) as varbinary))
GO

-- varbinary to binary, empty string
select 
    DATALENGTH(CAST(CAST(0x00 AS varbinary) as BINARY)),
    DATALENGTH(cast(CAST('0x00' AS varbinary) as BINARY)),
    DATALENGTH(cast(CAST('' AS varbinary(10)) as BINARY(10))),
    DATALENGTH(cast(CAST('' AS varbinary(max)) as BINARY(10))),
    DATALENGTH(cast(CAST('' AS varbinary) as BINARY))
GO

-- 7. Other Data Types
SELECT 
    DATALENGTH(CAST(1 AS BIT)) AS Bit_Length,
    DATALENGTH(NEWID()) AS UniqueIdentifier_Length,
    DATALENGTH(CAST('true' AS SQL_VARIANT)) AS SqlVariant_Length,
    DATALENGTH(CAST('<root>test</root>' AS XML)) AS XML_Length;
GO

-- rowversion, no regression
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
GO

select datalength(cast(cast('a' as rowversion) as varchar))
GO
select datalength(cast('' as rowversion))
GO
select datalength(cast(cast('' as rowversion) as varchar))
GO
select datalength(cast(NULL as rowversion))
GO
select datalength(cast(cast('NULL' as rowversion) as varchar))
GO

-- timestamp, no regression
select 
    datalength(cast('' as TIMESTAMP)),
    datalength(cast(' ' as TIMESTAMP)),
    datalength(cast(cast('' as TIMESTAMP) as varbinary)),
    datalength(cast(NULL as TIMESTAMP)),
    datalength(cast('NULL' as TIMESTAMP)),
    datalength(cast('NULL ' as TIMESTAMP)),
    datalength(cast(cast('NULL' as TIMESTAMP) as varbinary))
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
GO

-- 8. NULL Values
SELECT 
    DATALENGTH(NULL) AS Null_Length,
    DATALENGTH(CAST(NULL AS VARCHAR(10))) AS NullVarchar_Length,
    DATALENGTH(CAST(NULL AS INT)) AS NullInt_Length,
    DATALENGTH(CAST(NULL AS DATETIME)) AS NullDateTime_Length;
GO

-- 9. Empty vs Space Tests
SELECT 
    DATALENGTH('') AS EmptyString_Length,
    DATALENGTH(' ') AS SingleSpace_Length,
    DATALENGTH('   ') AS MultipleSpaces_Length,
    DATALENGTH(CHAR(9)) AS Tab_Length,
    DATALENGTH(CHAR(13) + CHAR(10)) AS CRLF_Length;
GO

-- 10. MAX Types with Large Data
DECLARE @LargeVarchar VARCHAR(MAX) = REPLICATE('A', 8000);
DECLARE @LargeNVarchar NVARCHAR(MAX) = REPLICATE(N'A', 4000);
DECLARE @LargeVarbinary VARBINARY(MAX) = CAST(REPLICATE('A', 8000) AS VARBINARY(MAX));

SELECT 
    DATALENGTH(@LargeVarchar) AS LargeVarchar_Length,
    DATALENGTH(@LargeNVarchar) AS LargeNVarchar_Length,
    DATALENGTH(@LargeVarbinary) AS LargeVarbinary_Length;
GO

-- 11. Computed Columns
CREATE TABLE datalength_t4 (
    Col1 VARCHAR(100),
    Col2 AS DATALENGTH(Col1 + 'suffix')
);
GO

INSERT INTO datalength_t4 (Col1) VALUES ('test');

SELECT Col2 FROM datalength_t4;
GO

-- 12. Special Characters
SELECT 
    DATALENGTH(CHAR(1)) AS StartOfHeading_Length,
    DATALENGTH(CHAR(32)) AS Space_Length,
    DATALENGTH(CHAR(255)) AS ExtendedASCII_Length;
GO

SELECT DATALENGTH(CHAR(0)) AS NullChar_Length
GO

-- 13. Collation Impact
SELECT 
    DATALENGTH('Hello' COLLATE Latin1_General_CI_AS) AS Latin1_Length,
    DATALENGTH('Hello' COLLATE Japanese_CI_AS) AS Japanese_Length,
    DATALENGTH(N'Hello' COLLATE Latin1_General_CI_AS) AS UnicodeLatina1_Length,
    DATALENGTH(N'Hello' COLLATE Japanese_CI_AS) AS UnicodeJapanese_Length;
GO

-- 14. Concatenation
SELECT 
    DATALENGTH('Hello' + 'World') AS Concat_Length,
    DATALENGTH(CONCAT('Hello', 'World')) AS ConcatFunc_Length,
    DATALENGTH('Hello' + NULL) AS ConcatNull_Length,
    DATALENGTH(CONCAT('Hello', NULL)) AS ConcatFuncNull_Length;
GO

-- 15. Money and Decimal Types with Different Precisions
SELECT 
    DATALENGTH(CAST(123.45 AS MONEY)) AS Money_Length,
    DATALENGTH(CAST(123.45 AS SMALLMONEY)) AS SmallMoney_Length,
    DATALENGTH(CAST(123.45 AS DECIMAL(5,2))) AS Decimal5_2_Length,
    DATALENGTH(CAST(123.45 AS DECIMAL(10,2))) AS Decimal10_2_Length,
    DATALENGTH(CAST(123.45 AS DECIMAL(20,2))) AS Decimal20_2_Length;
GO

-- 16. Mathematical Functions and Expressions
SELECT
    DATALENGTH(PI()) AS PI_Length,
    DATALENGTH(SIN(1)) AS Sin_Length,
    DATALENGTH(COS(1)) AS Cos_Length,
    DATALENGTH(SQUARE(2)) AS Square_Length,
    DATALENGTH(POWER(2, 10)) AS Power_Length;
GO

-- 17. Aggregate Functions
CREATE TABLE datalength_t2 (
    ID INT,
    DecimalNum DECIMAL(18,2),
    FloatNum FLOAT
);
GO

INSERT INTO datalength_t2 VALUES 
    (1, 123.45, 123.45),
    (2, 456.78, 456.78),
    (3, 789.01, 789.01);
GO

SELECT
    DATALENGTH(SUM(ID)) AS Sum_Int_Length,
    DATALENGTH(SUM(DecimalNum)) AS Sum_Decimal_Length,
    DATALENGTH(SUM(FloatNum)) AS Sum_Float_Length,
    DATALENGTH(AVG(ID)) AS Avg_Int_Length,
    DATALENGTH(AVG(DecimalNum)) AS Avg_Decimal_Length,
    DATALENGTH(AVG(FloatNum)) AS Avg_Float_Length
FROM datalength_t2;
GO

-- 18. Case Statements and Control Flow Functions
SELECT
    DATALENGTH(CASE WHEN 1=1 THEN 'TRUE' ELSE 'FALSE' END) AS Case_Length,
    DATALENGTH(IIF(1=1, 'TRUE', 'FALSE')) AS IIF_Length,
    DATALENGTH(CHOOSE(2, 'First', 'Second', 'Third')) AS Choose_Length,
    DATALENGTH(COALESCE(NULL, 'Test', 'Backup')) AS Coalesce_Length;
GO

-- 19. String Functions Results
SELECT
    DATALENGTH(UPPER('hello')) AS Upper_Length,
    DATALENGTH(LOWER('HELLO')) AS Lower_Length,
    DATALENGTH(REVERSE('hello')) AS Reverse_Length,
    DATALENGTH(RTRIM('hello  ')) AS RTrim_Length,
    DATALENGTH(LTRIM('  hello')) AS LTrim_Length,
    DATALENGTH(SUBSTRING('hello world', 1, 5)) AS Substring_Length;
GO

-- 20. Testing with Different Row Sizes
CREATE TABLE datalength_t3 (
    SmallRow CHAR(80),
    MediumRow CHAR(800),
    LargeRow CHAR(8000)
);
GO

INSERT INTO datalength_t3 VALUES
    ('Small', REPLICATE('M', 800), REPLICATE('L', 8000));

SELECT
    DATALENGTH(SmallRow) AS SmallRow_Length,
    DATALENGTH(MediumRow) AS MediumRow_Length,
    DATALENGTH(LargeRow) AS LargeRow_Length
FROM datalength_t3;
GO

-- 21. Testing with Different Collations in Same Query
SELECT
    DATALENGTH(N'Hello' COLLATE Latin1_General_CS_AS) AS Case_Sensitive_Length,
    DATALENGTH(N'Hello' COLLATE Latin1_General_CI_AS) AS Case_Insensitive_Length,
    DATALENGTH(N'Hello' COLLATE Japanese_CI_AS) AS Japanese_Collation_Length;
GO

-- 22. Basic DATALENGTH Tests with UDTs
SELECT 
    DATALENGTH(Email) AS Email_DataLength,
    DATALENGTH(Phone) AS Phone_DataLength,
    DATALENGTH(Name) AS Name_DataLength,
    DATALENGTH(Desc1) AS Desc1_DataLength,
    DATALENGTH(Desc2) AS Desc2_DataLength,
    DATALENGTH(Code) AS Code_DataLength,
    DATALENGTH(Details) AS Details_DataLength,
    DATALENGTH(UCode) AS UCode_DataLength
FROM datalength_t5;
GO

-- 23. Special Characters Tests with UDTs
INSERT INTO datalength_t5 (ID, Email, Name, Code) 
VALUES (7, 'test!@#$%', N'Name!@#$%', '!@#$%');
SELECT 
    DATALENGTH(Email) AS SpecialChar_Email_DataLength,
    DATALENGTH(Name) AS SpecialChar_Name_DataLength,
    DATALENGTH(Code) AS SpecialChar_Code_DataLength
FROM datalength_t5 WHERE ID = 7;
GO

-- 24. Collation Tests with UDTs
SELECT 
    DATALENGTH(Name COLLATE Latin1_General_CI_AS) AS CI_Name_DataLength,
    DATALENGTH(Name COLLATE Latin1_General_CS_AS) AS CS_Name_DataLength
FROM datalength_t5 
WHERE ID = 1;
GO

-- 25. NULL Value Tests with UDTs
INSERT INTO datalength_t5 (ID) VALUES (2);
SELECT 
    DATALENGTH(Email) AS Null_Email_DataLength,
    DATALENGTH(Phone) AS Null_Phone_DataLength,
    DATALENGTH(Name) AS Null_Name_DataLength
FROM datalength_t5 WHERE ID = 2;
GO

-- 26. Empty String Tests with UDTs
INSERT INTO datalength_t5 (ID, Email, Phone, Name, Code) 
VALUES (3, '', '', '', '');
SELECT 
    DATALENGTH(Email) AS Empty_Email_DataLength,
    DATALENGTH(Phone) AS Empty_Phone_DataLength,
    DATALENGTH(Name) AS Empty_Name_DataLength,
    DATALENGTH(Code) AS Empty_Code_DataLength
FROM datalength_t5 WHERE ID = 3;
GO

-- 27. Space Character Tests with UDTs
INSERT INTO datalength_t5 (ID, Email, Phone, Name, Code) 
VALUES (4, '   ', '          ', N'   ', '     ');
SELECT 
    DATALENGTH(Email) AS Space_Email_DataLength,
    DATALENGTH(Phone) AS Space_Phone_DataLength,
    DATALENGTH(Name) AS Space_Name_DataLength,
    DATALENGTH(Code) AS Space_Code_DataLength
FROM datalength_t5 WHERE ID = 4;
GO

-- 28. Maximum Length Tests with UDTs
DECLARE @MaxEmail EmailAddress = REPLICATE('a', 255);
DECLARE @MaxName FullName = REPLICATE(N'a', 100);
DECLARE @MaxCode ShortCode = REPLICATE('A', 5);

SELECT 
    DATALENGTH(@MaxEmail) AS MaxEmail_DataLength,
    DATALENGTH(@MaxName) AS MaxName_DataLength,
    DATALENGTH(@MaxCode) AS MaxCode_DataLength;
GO

-- 29. Unicode Character Tests with UDTs
INSERT INTO datalength_t5 (ID, Name, Desc2, UCode) 
VALUES (5, N'こんにちは', N'こんにちは世界', N'こんにちは');
SELECT 
    DATALENGTH(Name) AS Unicode_Name_DataLength,
    DATALENGTH(Desc2) AS Unicode_Desc_DataLength,
    DATALENGTH(UCode) AS Unicode_Code_DataLength
FROM datalength_t5 WHERE ID = 5;
GO

-- 30. Concatenation Tests with UDTs
DECLARE @Email1 EmailAddress = 'test';
DECLARE @Email2 EmailAddress = '@example.com';
SELECT DATALENGTH(@Email1 + @Email2) AS Concat_Email_DataLength;
GO

-- 31. Large Text Tests with UDTs
DECLARE @LongDetails LongText = REPLICATE('A', 10000);
SELECT DATALENGTH(@LongDetails) AS LongText_DataLength;
GO

-- 32. Mixed Content Tests with UDTs
INSERT INTO datalength_t5 (ID, Email, Name, Code) 
VALUES (6, 'test123@example.com', N'John123', 'A1B2C');
SELECT 
    DATALENGTH(Email) AS Mixed_Email_DataLength,
    DATALENGTH(Name) AS Mixed_Name_DataLength,
    DATALENGTH(Code) AS Mixed_Code_DataLength
FROM datalength_t5 WHERE ID = 6;
GO

-- 33. Function Results with UDTs
DECLARE @Email EmailAddress = 'test@example.com';
SELECT 
    DATALENGTH(UPPER(@Email)) AS Upper_Email_DataLength,
    DATALENGTH(LOWER(@Email)) AS Lower_Email_DataLength,
    DATALENGTH(REVERSE(@Email)) AS Reverse_Email_DataLength;
GO

-- 34. Computed Column Tests with UDTs
SELECT * FROM datalength_t6;
GO

-- 35. Test the view using DATALENGTH
SELECT * FROM datalength_vw_DataLengthInfo;
GO

-- 36. Test the categorization view
SELECT * FROM datalength_vw_DataSizeCategories;
GO


-- 37. Scalar Functions using DATALENGTH
SELECT ID, dbo.datalength_fn_GetTotalSize(Email, Code, Name) AS TotalSize
FROM datalength_t7;
GO

CREATE FUNCTION datalength_fn_GetSizeCategory
(
    @Text NVARCHAR(MAX)
)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CASE 
        WHEN @Text IS NULL THEN 'NULL'
        WHEN DATALENGTH(@Text) = 0 THEN 'Empty'
        WHEN DATALENGTH(@Text) <= 10 THEN 'Small'
        WHEN DATALENGTH(@Text) <= 50 THEN 'Medium'
        ELSE 'Large'
    END;
END;
GO

-- 38. Test the category function
SELECT Email, dbo.datalength_fn_GetSizeCategory(Email) AS EmailCategory,
       Name, dbo.datalength_fn_GetSizeCategory(Name) AS NameCategory
FROM datalength_t7;
GO

-- 39. Test the table-valued function
SELECT * FROM datalength_fn_GetSizeAnalysis();
GO

-- 40. Test the stored procedures
EXEC datalength_sp_AnalyzeDataSizes @MinSize = 10;
GO

-- 41. Test the data validation procedure
EXEC datalength_sp_ValidateAndInsert 'new@example.com', 'CODE123', N'New User';
GO

-- 42. Computed Columns using DATALENGTH
SELECT * FROM datalength_ComputedColumnsTest;
GO

-- 43. Test Check Constraints using DATALENGTH
-- Should succeed
INSERT INTO datalength_ConstrainedTable VALUES (1, 'test@example.com', 'CODE123', N'John');

-- Should fail (email too short)
BEGIN TRY
    INSERT INTO datalength_ConstrainedTable VALUES (2, 'a@b', 'CODE123', N'Jane');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;

-- Should fail (empty name)
BEGIN TRY
    INSERT INTO datalength_ConstrainedTable VALUES (3, 'test@example.com', 'CODE123', N'');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- 44. Triggers using DATALENGTH
-- Test trigger
-- Should succeed
INSERT INTO datalength_t7 VALUES (5, 'valid@example.com', 'CODE123', N'Test User', '', N'');

-- Should fail
BEGIN TRY
    INSERT INTO datalength_t7 VALUES (6, REPLICATE('a', 300), 'CODE123', N'Test User', '', N'');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- 45. Test Indexed Views using DATALENGTH
SELECT * FROM datalength_vw_DataLengthSummary;
GO

-- Extra test cases 
-- UDT
create type tinyint_babel_6120 from tinyint;
create type date_babel_6120 from date;
create type smalldatetime_babel_6120 from smalldatetime;
create type time_babel_6120 from time;
create type smallmoney_babel_6120 from smallmoney;
create type numeric_babel_6120 from numeric(21,5);
create type decimal_babel_6120 from decimal(21,5);
GO

create type smallint_babel_6120 from smallint;
create type int_babel_6120 from int;
create type bigint_babel_6120 from bigint;
create type datetime_babel_6120 from datetime;
create type datetime2_babel_6120 from datetime2;
create type datetimeoffset_babel_6120 from datetimeoffset;
create type money_babel_6120 from money;
go


-- tinyint
-- JIRA query
SELECT DATALENGTH(CAST(123 AS TINYINT))
GO

SELECT DATALENGTH(CAST('123' AS TINYINT))
GO

SELECT DATALENGTH(CAST('' AS TINYINT))
GO

SELECT DATALENGTH(CAST(123.33 AS TINYINT))
GO

SELECT DATALENGTH(CAST(123 AS tinyint_babel_6120))
GO

-- smallint : 2 (as expected)
SELECT DATALENGTH(CAST(123 AS SMALLINT))
GO

SELECT DATALENGTH(CAST('123' AS SMALLINT))
GO

SELECT DATALENGTH(CAST('' AS SMALLINT))
GO

SELECT DATALENGTH(CAST(123.33 AS SMALLINT))
GO

SELECT DATALENGTH(CAST(123 AS smallint_babel_6120))
GO


-- INT : 4 (as expected)
SELECT DATALENGTH(CAST(123 AS INT))
GO

SELECT DATALENGTH(CAST('123' AS INT))
GO

SELECT DATALENGTH(CAST('' AS INT))
GO

SELECT DATALENGTH(CAST(123.33 AS INT))
GO

SELECT DATALENGTH(123)
go

SELECT DATALENGTH(CAST(123 AS int_babel_6120))
GO

-- bitint : 8 (as expected)

SELECT DATALENGTH(CAST(123 AS bigint))
GO

SELECT DATALENGTH(CAST('123' AS bigint))
GO

SELECT DATALENGTH(CAST('' AS bigint))
GO

SELECT DATALENGTH(CAST(123.33 AS bigint))
GO

SELECT DATALENGTH(CAST(123 AS bigint_babel_6120))
GO

-- numeric, testing for different precision range for actual input
SELECT DATALENGTH(CAST(123.45 AS NUMERIC(10,2)))
GO

SELECT DATALENGTH(123.45) 
go

SELECT DATALENGTH(CAST(123.451234 AS NUMERIC(10,2))) 
go

SELECT DATALENGTH(CAST(123.451234 AS NUMERIC(5,2))) 
Go

SELECT DATALENGTH(CAST(123.451234 AS NUMERIC(1,0))) -- over flow
go

SELECT DATALENGTH(CAST(1 AS NUMERIC(1,0)))
go

SELECT DATALENGTH(CAST(1.0 AS NUMERIC(1,0)))
go

SELECT DATALENGTH(CAST(1.0 AS NUMERIC(5,3))) 
go

SELECT DATALENGTH(CAST(12.346 AS NUMERIC(5,3))) 
go

SELECT DATALENGTH(CAST(12345.6789 AS NUMERIC(9,3))) 
go

SELECT DATALENGTH(CAST(12345.6789 AS NUMERIC(10,3)))  
Go

SELECT DATALENGTH(CAST(12345.6789 AS NUMERIC(11,3))) 
go

SELECT DATALENGTH(CAST(123456789123456789.679 AS NUMERIC(21,3))) 
go

SELECT DATALENGTH(CAST(123456789123456789123456789123.12345678 AS NUMERIC(38,8))) 
go

Select datalength(123456789123456789123456789123.12345678) 
GO

SELECT DATALENGTH(CAST(0.679 AS NUMERIC(21,3))) 
go

SELECT DATALENGTH(CAST(0.1234567891 AS NUMERIC(21,3))) 
go

SELECT DATALENGTH(CAST(0.1234567234567891 AS NUMERIC(21,3)))
go

SELECT DATALENGTH(CAST(0.1234567234567891 AS NUMERIC(21,11))) 
go

SELECT DATALENGTH(CAST(1.1234567234567891 AS NUMERIC(38,5))) 
go

SELECT DATALENGTH(CAST(123456789123.679 AS numeric_babel_6120)) 
go

-- extra 0 is appended and hence 21 precision, 13 result
SELECT DATALENGTH(CAST(0.12345678912345678912 AS NUMERIC(38,21))) 
go

-- When significant digit is 0, 
-- we have divergance between TSQL doc and actual functionality
-- we are matching TSQL doc.

-- Even though precision is 10, returns 5 byte according to 1-9 precision range
SELECT DATALENGTH(CAST(0.1234567234567891 AS NUMERIC(21,10)))
go

-- Even though precision is 20, returns 9 byte according to 10-28 precision range
SELECT DATALENGTH(CAST(0.12345678912345678912 AS NUMERIC(38,20))) 
go

-- Even though precision is 20, returns 9 byte according to 10-28 precision range
SELECT DATALENGTH(CAST(0.123456789123456789121 AS NUMERIC(38,20))) 
go

-- decimal
-- JIRA query
SELECT DATALENGTH(CAST(123.45 AS DECIMAL(10,2)))
GO

SELECT DATALENGTH(123.45)
go

SELECT DATALENGTH(CAST(123.451234 AS DECIMAL(10,2)))
go

SELECT DATALENGTH(CAST(123.451234 AS DECIMAL(5,2))) 
Go

SELECT DATALENGTH(CAST(123.451234 AS DECIMAL(1,0))) -- over flow
go

SELECT DATALENGTH(CAST(1 AS DECIMAL(1,0)))
go

SELECT DATALENGTH(CAST(1.0 AS DECIMAL(5,3))) 
go

SELECT DATALENGTH(CAST(12.346 AS DECIMAL(5,3))) 
go

SELECT DATALENGTH(CAST(12345678.679 AS DECIMAL(21,3))) 
go

SELECT DATALENGTH(CAST(123456789123456789.679 AS DECIMAL(21,3))) 
go

SELECT DATALENGTH(CAST(123456789123456789123456789123.12345678 AS DECIMAL(38,8))) 
go

Select datalength(123456789123456789123456789123.12345678) 
GO

SELECT DATALENGTH(CAST(123456789123.679 AS decimal_babel_6120)) 
go

-- money
select DATALENGTH(CAST(123.45 AS MONEY))
go

SELECT DATALENGTH(CAST(123 AS MONEY))
GO

SELECT DATALENGTH(CAST('123' AS MONEY))
GO

SELECT DATALENGTH(CAST('' AS MONEY))
GO

SELECT DATALENGTH(CAST(NULL AS MONEY)) -- NULL
go

select DATALENGTH(CAST(123.45 AS money_babel_6120))
go

-- smallmoney
-- JIRA query
select DATALENGTH(CAST(123.45 AS SMALLMONEY))
go

SELECT DATALENGTH(CAST(123 AS SMALLMONEY))
GO

SELECT DATALENGTH(CAST('123' AS SMALLMONEY))
GO

SELECT DATALENGTH(CAST('' AS SMALLMONEY))
GO

SELECT DATALENGTH(CAST(NULL AS SMALLMONEY))
GO

select DATALENGTH(CAST(123.45 AS smallmoney_babel_6120))
go

-- date
-- JIRA query
SELECT DATALENGTH(CAST('2024-01-01' AS DATE))
go

select datalength(CAST('' AS DATE))
go

SELECT DATALENGTH(CAST('2024-01-01' AS date_babel_6120))
go

-- smalldatetime
-- JIRA query
SELECT DATALENGTH(CAST('2024-01-01 12:34:56' AS SMALLDATETIME))
GO

select datalength(CAST('' AS SMALLDATETIME))
go

SELECT DATALENGTH(CAST('2024-01-01 12:34:56' AS smalldatetime_babel_6120))
GO


-- time
-- JIRA query
SELECT DATALENGTH(CAST('12:34:56' AS TIME))
go

SELECT DATALENGTH(CAST('12:10:30.123' AS TIME))
go

SELECT DATALENGTH(CAST('12:10:30.123' AS TIME(5)))
go

select datalength(CAST('' AS TIME))
go

SELECT DATALENGTH(CAST('12:10:30.123' AS time_babel_6120))
go

-- datetime
select datalength(cast('01/02/03' as datetime))
go

select datalength(CAST('' AS datetime))
go

select datalength(cast('01/02/03' as datetime_babel_6120))
go

-- datetime2
select datalength(cast('Apr 1 2000 14:30' as datetime2))
Go

select datalength(CAST('' AS DATETIME2))
go

select datalength(cast('Apr 1 2000 14:30' as datetime2_babel_6120))
Go

-- datetimeoffset
select datalength(cast('3/12/24 14:30 +8:00' as datetimeoffset))
go

select datalength(CAST('' AS datetimeoffset))
go

select datalength(cast('3/12/24 14:30 +8:00' as datetimeoffset_babel_6120))
go

-- XML
SELECT DATALENGTH(CAST('<root>test</root>' AS XML)) AS XML_Length;
Go

SELECT DATALENGTH(CAST(N'<root>test</root>' AS XML)) AS XML_Length;
go

SELECT DATALENGTH(CAST('<root>te界t</root>' AS XML)) AS XML_Length;
go

-- String datatypes : FIX with BABEL-1520/BABEL-1516
-- char
select datalength(char(0))
go

select datalength(cast('' as char))
go

select datalength(cast('' as char(10)))
go

select datalength(cast('asdfg' as char(10)))
go

select datalength(cast('asdfg' as char))
go

select datalength(cast(N'asdfg' as char))
go

select datalength(cast(N'asdfg' as char(10)))
go

select datalength(cast(NULL as char(10)))
go

select datalength(cast(NULL as char))
go

select DATALENGTH(cast('🌟' as char)) 
go

select DATALENGTH(cast(N'🌟' as char)) 
go

select DATALENGTH(cast(N'🌟' as char(10)))
go

-- varchar
-- VARCHAR
select datalength(cast('' as varchar))
go

select datalength(cast('' as varchar(10)))
go

select datalength(cast('asdfg' as varchar(10)))
go

select datalength(cast('asdfg' as varchar))
go

select datalength(cast(N'asdfg' as varchar))
go

select datalength(cast(N'asdfg' as varchar(10)))
go

select datalength(cast(NULL as varchar(10)))
go

select datalength(cast(NULL as varchar))
go

select DATALENGTH(cast('🌟' as varchar)) 
go

select DATALENGTH(cast(N'🌟' as varchar)) 
go

select DATALENGTH(cast(N'🌟' as varchar(10)))
go

select datalength(cast('世界' as varchar)) 
Go

select datalength(cast(N'世界' as varchar)) 
go

select datalength(cast(N'世界' as varchar(10))) 
go

-- VARCHAR(MAX)
select datalength(cast('' as varchar(max)))
go

select datalength(cast('asdfg' as varchar(max)))
go

select datalength(cast(N'asdfg' as varchar(max)))
go

select datalength(cast(NULL as varchar(max)))
go

select DATALENGTH(cast('🌟' as varchar(max))) 
go

select DATALENGTH(cast(N'🌟' as varchar(max))) 
go

select datalength(cast(N'世界' as varchar(max))) 
go

-- NCHAR
select datalength(nchar(0))
go

select datalength(cast('' as nchar))
go

select datalength(cast('' as nchar(10)))
go

select datalength(cast('asdfg' as nchar(10)))
go

select datalength(cast('asdfg' as nchar))
go

select datalength(cast(N'asdfg' as nchar))
go

select datalength(cast(N'asdfg' as nchar(10)))
go

select datalength(cast(NULL as nchar(10)))
go

select datalength(cast(NULL as nchar))
go

select DATALENGTH(cast('🌟' as nchar)) 
go

select DATALENGTH(cast(N'🌟' as nchar)) 
go

select DATALENGTH(cast(N'🌟' as nchar(10)))
go

select datalength(cast(N'世界' as nchar)) 
go

select datalength(cast(N'世界' as nchar(10))) 
go

-- NVARCHAR
select datalength(cast('' as nvarchar))
go

select datalength(cast('' as nvarchar(10)))
go

select datalength(cast('asdfg' as nvarchar(10)))
go

select datalength(cast('asdfg' as nvarchar))
go

select datalength(cast(N'asdfg' as nvarchar))
go

select datalength(cast(N'asdfg' as nvarchar(10)))
go

select datalength(cast(NULL as nvarchar(10)))
go

select datalength(cast(NULL as nvarchar))
go

select DATALENGTH(cast('🌟' as nvarchar)) 
go

select DATALENGTH(cast(N'🌟' as nvarchar)) 
go

select DATALENGTH(cast(N'🌟' as nvarchar(10)))
go

select datalength(cast(N'世界' as nvarchar)) 
go

select datalength(cast(N'世界' as nvarchar(10))) 
go

-- NVARCHAR(MAX)
select datalength(cast('' as nvarchar(max)))
go

select datalength(cast('asdfg' as nvarchar(max)))
go

select datalength(cast(N'asdfg' as nvarchar(max)))
go

select datalength(cast(NULL as nvarchar(max)))
go

select DATALENGTH(cast('🌟' as nvarchar(max))) 
go

select DATALENGTH(cast(N'🌟' as nvarchar(max))) 
go

select datalength(cast(N'世界' as nvarchar(max))) 
go

-- combination  - multibyte/accented/surroagte

select DATALENGTH('Hello') , DATALENGTH(N'Hello')
go

select DATALENGTH('こんにちは'), DATALENGTH(N'こんにちは')
GO

select DATALENGTH('Hàáâ') , DATALENGTH(N'Hàáâ')
go

select DATALENGTH('こàáâは'), DATALENGTH(N'こàáâは')
go

select DATALENGTH('🌟🌟🌟'), DATALENGTH(N'🌟🌟🌟')
go

-- truncation
declare @a varchar(2) = 'hello'
select DATALENGTH(@a)
go

declare @a Nvarchar(2) = N'hello'
select DATALENGTH(@a)
go


-- text 
select datalength(cast('abd' as text))
Go

select datalength(cast(N'abd' as text))
Go

select DATALENGTH(cast('こんにちは' as text)), DATALENGTH(cast(N'こんにちは' as text))
GO

-- ntext
select datalength(cast('abd' as ntext))
Go

select datalength(cast(N'abd' as ntext))
Go

select DATALENGTH(cast('こんにちは' as ntext)), DATALENGTH(cast(N'こんにちは' as ntext))
GO

-- binary
select datalength(CAST('0x65' AS BINARY(10)))
GO

select datalength(CAST(0x65 AS BINARY(10)))
go

select datalength(CAST(0x65 AS BINARY))
go

select datalength(CAST('' AS BINARY(10)))
go

select datalength(CAST('' AS BINARY))
GO

-- varbinary
select datalength(CAST(0x65 AS varbinary))
go


select datalength(CAST(0x65 AS varbinary(max)))
go


select datalength(CAST(0x65 AS varbinary(10)))
go


select datalength(CAST('0x65' AS VARBINARY(10)))
go


select datalength(CAST('' AS VARBINARY(10)))
go


select datalength(CAST('' AS VARBINARY))
go

-- Cleanup
DROP TABLE datalength_t2;
DROP TABLE datalength_t3;
DROP TABLE datalength_t1;
GO

DROP TABLE datalength_t4;
GO

DROP TABLE datalength_t5;
DROP TABLE datalength_t6;
GO

DROP TYPE EmailAddress;
DROP TYPE PhoneNumber;
DROP TYPE FullName;
DROP TYPE Description;
DROP TYPE Unicode_Description;
DROP TYPE ShortCode;
DROP TYPE LongText;
DROP TYPE UnicodeCode;
GO

DROP TRIGGER datalength_tr_ValidateDataLength;
DROP VIEW datalength_vw_DataLengthSummary;
DROP VIEW datalength_vw_DataLengthInfo;
DROP VIEW datalength_vw_DataSizeCategories;
DROP FUNCTION datalength_fn_GetTotalSize;
DROP FUNCTION datalength_fn_GetSizeCategory;
DROP FUNCTION datalength_fn_GetSizeAnalysis;
DROP PROCEDURE datalength_sp_AnalyzeDataSizes;
DROP PROCEDURE datalength_sp_ValidateAndInsert;
DROP TABLE datalength_ComputedColumnsTest;
DROP TABLE datalength_ConstrainedTable;
DROP TABLE datalength_t7;
GO

drop type tinyint_babel_6120;
drop type date_babel_6120;
drop type smalldatetime_babel_6120;
drop type time_babel_6120;
drop type smallmoney_babel_6120;
drop type numeric_babel_6120;
drop type decimal_babel_6120;
GO

drop type smallint_babel_6120;
drop type int_babel_6120;
drop type bigint_babel_6120;
drop type datetime_babel_6120;
drop type datetime2_babel_6120;
drop type datetimeoffset_babel_6120;
drop type money_babel_6120;
go