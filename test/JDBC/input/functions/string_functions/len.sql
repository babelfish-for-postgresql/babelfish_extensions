-- Create User-Defined Data Types
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

-- Create Base Tables
CREATE TABLE len_t1 (
    Col1 CHAR(10),
    Col2 VARCHAR(10),
    Col3 NCHAR(10),
    Col4 NVARCHAR(10),
    Col5 TEXT,
    Col6 NTEXT
);
GO

CREATE TABLE len_t2 (
    IntCol INT,
    DecimalCol DECIMAL(18,2),
    MoneyCol MONEY,
    DateCol DATE,
    BitCol BIT,
    GuidCol UNIQUEIDENTIFIER,
    ComputedCol AS IntCol * 2
);
GO

CREATE TABLE len_udt_t3 (
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

-- Populate Base Tables
INSERT INTO len_t1 VALUES
('Hello     ', 'Hello', N'Hello     ', N'Hello', 'Hello', N'Hello');
GO

INSERT INTO len_t2 (IntCol, DecimalCol, MoneyCol, DateCol, BitCol, GuidCol)
VALUES 
(123, 456.78, 789.01, '2024-01-01', 1, '9641D381-A27F-40A0-8FB9-42216F635D4A'),
(-123, -456.78, -789.01, '2024-12-31', 0, '9641D381-A27F-40A0-8FB9-42216F635D4A');
GO

INSERT INTO len_udt_t3 VALUES
(1, 'test@example.com', '1234567890', N'John Doe', 'Simple description', 
N'Unicode description', 'ABC12', 'Long text details', N'UNICODE123');
GO

-- Create Tables for Dependent Objects Testing
CREATE TABLE len_source_data (
    ID INT PRIMARY KEY,
    StringData VARCHAR(100),
    UnicodeData NVARCHAR(100),
    EmailData EmailAddress,
    CodeData ShortCode
);
GO

INSERT INTO len_source_data VALUES
(1, 'Regular String', N'Unicode String', 'test@example.com', 'CODE1'),
(2, 'Another String', N'Another Unicode', 'another@test.com', 'CODE2'),
(3, '', N'', '', '');
GO


-- 1. Basic String Length Tests
SELECT LEN('') AS EmptyString;
SELECT LEN('A') AS SingleCharacter;
SELECT LEN('Hello') AS MultipleCharacters;
SELECT LEN('Hello World') AS SentenceWithSpaces;
GO

-- 2. Special Characters Tests
SELECT LEN('Hello	World') AS StringWithTab;
SELECT LEN('Hello
World') AS StringWithNewline;
SELECT LEN('Hello' + CHAR(13) + 'World') AS StringWithCarriageReturn;
SELECT LEN('!@#$%^&*()') AS StringWithSpecialCharacters;
GO

-- 3. Unicode Character Tests
SELECT LEN(N'こんにちは') AS UnicodeCharacters;
SELECT LEN(N'Hello世界') AS MixedASCIIandUnicode;
SELECT LEN(N'🙂') AS EmojiCharacters;
GO

-- 4. Whitespace Tests
SELECT LEN('   Hello') AS LeadingSpaces;
SELECT LEN('Hello   ') AS TrailingSpaces;
SELECT LEN('Hello   World') AS MultipleSpacesBetweenWords;
SELECT LEN('     ') AS OnlySpaces;
GO

-- 5. NULL and Empty Value Tests
SELECT LEN(NULL) AS NULLValue;
SELECT LEN('') AS EmptyString;
SELECT LEN(CHAR(0)) AS StringWithNULLCharacter;
GO

-- 6. Numeric Value Tests
SELECT LEN('12345') AS IntegerAsString;
SELECT LEN('123.45') AS DecimalAsString;
SELECT LEN('1.23E-4') AS ScientificNotation;
GO

-- 7. Different Data Type Tests
SELECT 
    LEN(Col1) AS CHAR_Length,
    LEN(Col2) AS VARCHAR_Length,
    LEN(Col3) AS NCHAR_Length,
    LEN(Col4) AS NVARCHAR_Length,
    LEN(Col5) AS TEXT_Length,
    LEN(Col6) AS NTEXT_Length
FROM len_t1;
GO

-- 8. Maximum Length Tests
DECLARE @MaxVarchar VARCHAR(MAX) = REPLICATE('A', 8000);
DECLARE @MaxNVarchar NVARCHAR(MAX) = REPLICATE(N'A', 4000);

SELECT LEN(@MaxVarchar) AS MAXVARCHARTest;
SELECT LEN(@MaxNVarchar) AS MAXNVARCHARTest;
GO

-- 9. Concatenation Tests
SELECT LEN('Hello' + ' ' + 'World') AS ConcatenatedStrings;
SELECT LEN('Hello' + '') AS ConcatenatedWithEmptyString;
SELECT LEN('Hello' + NULL) AS ConcatenatedWithNULL;
GO

-- 10. Case Sensitivity Tests
SELECT LEN('hello') AS LowercaseString;
SELECT LEN('HELLO') AS UppercaseString;
SELECT LEN('HeLLo') AS MixedCaseString;
GO

-- 11. Test with Large String
DECLARE @LargeString VARCHAR(MAX) = REPLICATE('A', 1000000);
SELECT LEN(@LargeString) AS LargeStringLength;
GO

-- 12. Edge Cases with Mathematical Operations
SELECT LEN('Test') + LEN('String') AS CombinedLength;
GO

-- 13. Testing with different collations
SELECT LEN(N'Hello') AS DefaultCollation,
       LEN(N'Hello' COLLATE Latin1_General_CI_AS) AS CaseInsensitiveCollation,
       LEN(N'Hello' COLLATE Latin1_General_CS_AS) AS CaseSensitiveCollation;
GO

-- 14. Numeric Data Types
SELECT 
    LEN(123) AS Integer_Length,
    LEN(-123) AS NegativeInteger_Length,
    LEN(0) AS Zero_Length;
GO

SELECT 
    LEN(123.456) AS Decimal_Length,
    LEN(-123.456) AS NegativeDecimal_Length,
    LEN(0.123) AS DecimalLessThanOne_Length;
GO

SELECT
    LEN(1234567890.123456789) AS LongDecimal_Length,
    LEN(0.000000001) AS SmallDecimal_Length,
    LEN(1e10) AS ScientificNotation_Length;
GO

-- 15. Money Data Types
SELECT
    LEN(CAST(123.45 AS MONEY)) AS Money_Length,
    LEN(CAST(-123.45 AS MONEY)) AS NegativeMoney_Length,
    LEN(CAST(0.00 AS MONEY)) AS ZeroMoney_Length;
GO

-- 16. DateTime Data Types
SELECT 
    LEN(cast('2025-04-24 04:48:51.317' as sys.datetime)) AS DateTime_Length,
    LEN(CAST('2024-01-01' AS DATE)) AS Date_Length,
    LEN(CAST('12:34:56' AS TIME)) AS Time_Length;
GO

SELECT
    LEN(cast('2025-04-24 05:32:21.1605540' as sys.datetime2)) AS SysDateTime_Length,
    LEN(cast('2025-04-24 05:35:41.0922470 +00:00' as sys.datetimeoffset)) AS DateTimeOffset_Length;
GO

-- 17. Binary Data Types
SELECT
    LEN(CAST('Hello' AS BINARY(10))) AS Binary_Length,
    LEN(CAST('Hello' AS VARBINARY(10))) AS VarBinary_Length,
    LEN(CAST('Hello' AS VARBINARY(MAX))) AS VarBinaryMax_Length;
GO

-- 18. Uniqueidentifier
SELECT
    LEN('9641D381-A27F-40A0-8FB9-42216F635D4A') AS GUID_Length;
GO

-- 19. Bit Data Type
SELECT
    LEN(CAST(1 AS BIT)) AS BitTrue_Length,
    LEN(CAST(0 AS BIT)) AS BitFalse_Length;
GO

-- 20. Computed Values
SELECT
    LEN(1 + 2) AS Addition_Length,
    LEN(10 / 3) AS Division_Length,
    LEN(POWER(2, 10)) AS Power_Length;
GO

-- 21. Type Conversion Tests
SELECT
    LEN(CAST(123 AS VARCHAR)) AS IntToString_Length,
    LEN(CAST(123.456 AS VARCHAR)) AS DecimalToString_Length,
    LEN(CAST(cast('2025-04-24 04:48:51.317' as sys.datetime) AS VARCHAR)) AS DateTimeToString_Length;
GO

-- 22. XML Data Type
DECLARE @xml XML = '<root><item>Test</item></root>';
SELECT 
    LEN(@xml) AS XML_Length,
    LEN(CAST(@xml AS NVARCHAR(MAX))) AS XMLToString_Length;
GO

-- 23. Table Column Data Types
SELECT 
    LEN(IntCol) AS IntColumn_Length,
    LEN(DecimalCol) AS DecimalColumn_Length,
    LEN(MoneyCol) AS MoneyColumn_Length,
    LEN(DateCol) AS DateColumn_Length,
    LEN(BitCol) AS BitColumn_Length,
    LEN(GuidCol) AS GuidColumn_Length,
    LEN(ComputedCol) AS ComputedColumn_Length
FROM len_t2;
GO

-- 24. System Functions
SELECT
    LEN(@@VERSION) AS SQLVersion_Length,
    LEN(@@SERVERNAME) AS ServerName_Length,
    LEN(DB_NAME()) AS DatabaseName_Length;
GO

-- 25. Mathematical Functions
SELECT
    LEN(SIN(1)) AS Sin_Length,
    LEN(PI()) AS PI_Length,
    LEN(SQRT(100)) AS Sqrt_Length;
GO

-- =============================================
-- PART 2: CONTINUED TESTS AND DEPENDENT OBJECTS
-- =============================================

-- 26. Aggregate Functions with Numbers
CREATE TABLE len_number_test (ID INT);
INSERT INTO len_number_test VALUES (1), (22), (333), (4444);
GO

SELECT
    LEN(SUM(ID)) AS Sum_Length,
    LEN(AVG(ID)) AS Avg_Length,
    LEN(MAX(ID)) AS Max_Length
FROM len_number_test;
GO

-- 27. NULL handling with different data types
SELECT
    LEN(CAST(NULL AS INT)) AS NullInt_Length,
    LEN(CAST(NULL AS DECIMAL)) AS NullDecimal_Length,
    LEN(CAST(NULL AS DATETIME)) AS NullDateTime_Length,
    LEN(CAST(NULL AS BIT)) AS NullBit_Length;
GO

-- 28. Expressions and Case Statements
SELECT
    LEN(CASE WHEN 1=1 THEN 123 ELSE 456 END) AS Case_Length,
    LEN(IIF(1=1, 123, 456)) AS IIF_Length,
    LEN(COALESCE(NULL, 123, 456)) AS Coalesce_Length;
GO

-- 29. Basic Length Tests with UDTs
SELECT 
    LEN(Email) AS Email_Length,
    LEN(Phone) AS Phone_Length,
    LEN(Name) AS Name_Length,
    LEN(Desc1) AS Desc1_Length,
    LEN(Desc2) AS Desc2_Length,
    LEN(Code) AS Code_Length,
    LEN(Details) AS Details_Length,
    LEN(UCode) AS UCode_Length
FROM len_udt_t3;
GO

-- 30. Length Tests with UDTs and NULL
SELECT 
    LEN(Email) AS Email_Length,
    LEN(Phone) AS Phone_Length,
    LEN(Name) AS Name_Length,
    LEN(Desc1) AS Desc1_Length,
    LEN(Desc2) AS Desc2_Length,
    LEN(Code) AS Code_Length,
    LEN(Details) AS Details_Length,
    LEN(UCode) AS UCode_Length
FROM len_udt_t3
WHERE Email IS NOT NULL OR Phone IS NOT NULL OR Name IS NOT NULL;
GO

-- 31. Length Tests with UDTs and Empty Strings
SELECT 
    LEN(Email) AS Email_Length,
    LEN(Phone) AS Phone_Length,
    LEN(Name) AS Name_Length,
    LEN(Desc1) AS Desc1_Length,
    LEN(Desc2) AS Desc2_Length,
    LEN(Code) AS Code_Length,
    LEN(Details) AS Details_Length,
    LEN(UCode) AS UCode_Length
FROM len_udt_t3
WHERE Email <> '' OR Phone <> '' OR Name <> '';
GO

-- 32. Length Tests with UDTs and Special Characters
SELECT 
    LEN(Email) AS Email_Length,
    LEN(Phone) AS Phone_Length,
    LEN(Name) AS Name_Length,
    LEN(Desc1) AS Desc1_Length,
    LEN(Desc2) AS Desc2_Length,
    LEN(Code) AS Code_Length,
    LEN(Details) AS Details_Length,
    LEN(UCode) AS UCode_Length
FROM len_udt_t3
WHERE Email LIKE '%@%' OR Phone LIKE '%-%' OR Name LIKE '% %';
GO

-- 33. Length Tests with UDTs and Numeric Values
SELECT 
    LEN(Email) AS Email_Length,
    LEN(Phone) AS Phone_Length,
    LEN(Name) AS Name_Length,
    LEN(Desc1) AS Desc1_Length,
    LEN(Desc2) AS Desc2_Length,
    LEN(Code) AS Code_Length,
    LEN(Details) AS Details_Length,
    LEN(UCode) AS UCode_Length
FROM len_udt_t3
WHERE Email LIKE '%[0-9]%' OR Phone LIKE '%[0-9]%' OR Name LIKE '%[0-9]%'; 
GO

-- 34. Length Tests with UDTs and Whitespace
SELECT 
    LEN(Email) AS Email_Length,
    LEN(Phone) AS Phone_Length,
    LEN(Name) AS Name_Length,
    LEN(Desc1) AS Desc1_Length,
    LEN(Desc2) AS Desc2_Length,
    LEN(Code) AS Code_Length,
    LEN(Details) AS Details_Length,
    LEN(UCode) AS UCode_Length
FROM len_udt_t3
WHERE Email LIKE '% %' OR Phone LIKE '% %' OR Name LIKE '% %';
GO

-- =============================================
-- DEPENDENT OBJECT TESTS
-- =============================================

-- 35. Create Views
CREATE VIEW len_basic_view AS
SELECT 
    ID,
    StringData,
    LEN(StringData) AS StringLength,
    UnicodeData,
    LEN(UnicodeData) AS UnicodeLength,
    LEN(EmailData) AS EmailLength
FROM len_source_data;
GO

CREATE VIEW len_udt_view AS
SELECT
    ID,
    Email,
    LEN(Email) AS EmailLength,
    Name,
    LEN(Name) AS NameLength,
    CASE 
        WHEN LEN(Email) > LEN(Name) THEN 'Email Longer'
        ELSE 'Name Longer'
    END AS Comparison
FROM len_udt_t3;
GO

-- 36. Create Indexed View
CREATE VIEW len_indexed_view WITH SCHEMABINDING AS
SELECT 
    ID,
    LEN(StringData) AS StringLength,
    LEN(UnicodeData) AS UnicodeLength
FROM dbo.len_source_data;
GO

CREATE UNIQUE CLUSTERED INDEX IX_len_indexed_view ON len_indexed_view(ID);
GO

-- 37. Create Scalar Functions
CREATE FUNCTION len_fn_GetTotalLength
(
    @String VARCHAR(100),
    @Unicode NVARCHAR(100)
)
RETURNS INT
AS
BEGIN
    RETURN ISNULL(LEN(@String), 0) + ISNULL(LEN(@Unicode), 0);
END;
GO

CREATE FUNCTION len_fn_GetLengthCategory
(
    @Text NVARCHAR(MAX)
)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CASE 
        WHEN @Text IS NULL THEN 'NULL'
        WHEN LEN(@Text) = 0 THEN 'Empty'
        WHEN LEN(@Text) <= 10 THEN 'Short'
        WHEN LEN(@Text) <= 50 THEN 'Medium'
        ELSE 'Long'
    END;
END;
GO

-- 38. Create Table-Valued Function
CREATE FUNCTION len_fn_GetAnalysis()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ID,
        Email,
        LEN(Email) AS EmailLength,
        Name,
        LEN(Name) AS NameLength,
        LEN(Email) + LEN(Name) AS TotalLength
    FROM len_udt_t3
    WHERE LEN(Email) > 0 OR LEN(Name) > 0
);
GO

-- 39. Create Stored Procedures
CREATE PROCEDURE len_sp_AnalyzeLengths
    @MinLength INT = 0
AS
BEGIN
    SELECT 
        ID,
        Email,
        LEN(Email) AS EmailLength,
        Name,
        LEN(Name) AS NameLength
    FROM len_udt_t3
    WHERE LEN(Email) > @MinLength 
       OR LEN(Name) > @MinLength;
END;
GO

CREATE PROCEDURE len_sp_ValidateAndInsert
    @Email EmailAddress,
    @Name FullName
AS
BEGIN
    IF LEN(@Email) < 5 OR LEN(@Name) < 2
    BEGIN
        RAISERROR ('Invalid length for email or name', 16, 1);
        RETURN;
    END

    INSERT INTO len_udt_t3 (
        ID, 
        Email, 
        Name,
        Phone,
        Code,
        Details,
        UCode
    )
    VALUES (
        ISNULL((SELECT MAX(ID) FROM len_udt_t3), 0) + 1,
        @Email,
        @Name,
        '',
        '',
        '',
        ''
    );
END;
GO

-- 40. Create Tables with Computed Columns
CREATE TABLE len_computed_test (
    ID INT PRIMARY KEY,
    Email EmailAddress,
    Name FullName,
    EmailLength AS LEN(Email) PERSISTED,
    NameLength AS LEN(Name) PERSISTED,
    TotalLength AS LEN(Email) + LEN(Name) PERSISTED,
    LengthCategory AS CASE 
                        WHEN LEN(Email) + LEN(Name) = 0 THEN 'Empty'
                        WHEN LEN(Email) + LEN(Name) <= 20 THEN 'Short'
                        ELSE 'Long'
                     END PERSISTED
);
GO

-- 41. Create Table with Check Constraints
CREATE TABLE len_constrained_test (
    ID INT PRIMARY KEY,
    Email EmailAddress
        CONSTRAINT CHK_Email_Length CHECK (LEN(Email) BETWEEN 5 AND 255),
    Name FullName
        CONSTRAINT CHK_Name_Length CHECK (LEN(Name) > 0),
    Code ShortCode
        CONSTRAINT CHK_Code_Length CHECK (LEN(Code) = 5)
);
GO

-- 42. Create Trigger
CREATE TRIGGER len_tr_ValidateLength
ON len_udt_t3
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE LEN(Email) > 255 
           OR LEN(Name) > 100
           OR LEN(Code) > 5
    )
    BEGIN
        RAISERROR ('Data length exceeds maximum allowed', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 43. Test Dependent Objects
-- Test Views
SELECT * FROM len_basic_view;
SELECT * FROM len_udt_view;
SELECT * FROM len_indexed_view;
GO

-- Test Functions
SELECT dbo.len_fn_GetTotalLength('Test', N'Test') AS TotalLength;
SELECT dbo.len_fn_GetLengthCategory('Short text') AS Category;
SELECT * FROM dbo.len_fn_GetAnalysis();
GO

-- Test Procedures
EXEC len_sp_AnalyzeLengths @MinLength = 5;
EXEC len_sp_ValidateAndInsert 'test@example.com', N'John Doe';
GO

-- Test Computed Columns
INSERT INTO len_computed_test (ID, Email, Name)
VALUES (1, 'test@example.com', N'John Doe');
SELECT * FROM len_computed_test;
GO

-- Test Check Constraints
BEGIN TRY
    INSERT INTO len_constrained_test 
    VALUES (1, 'test@example.com', N'John Doe', 'CODE1');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMsg;
END CATCH;
GO


-- Drop Triggers
DROP TRIGGER len_tr_ValidateLength;
GO

-- Drop Views
DROP VIEW len_basic_view;
DROP VIEW len_udt_view;
DROP VIEW len_indexed_view;
GO

-- Drop Functions
DROP FUNCTION len_fn_GetTotalLength;
DROP FUNCTION len_fn_GetLengthCategory;
DROP FUNCTION len_fn_GetAnalysis;
GO

-- Drop Stored Procedures
DROP PROCEDURE len_sp_AnalyzeLengths;
DROP PROCEDURE len_sp_ValidateAndInsert;
GO

-- Drop Tables
DROP TABLE len_constrained_test;
DROP TABLE len_computed_test;
DROP TABLE len_source_data;
DROP TABLE len_number_test;
DROP TABLE len_udt_t3;
DROP TABLE len_t2;
DROP TABLE len_t1;
GO

-- Drop User-Defined Types (after dropping all dependent objects)
DROP TYPE EmailAddress;
DROP TYPE PhoneNumber;
DROP TYPE FullName;
DROP TYPE Description;
DROP TYPE Unicode_Description;
DROP TYPE ShortCode;
DROP TYPE LongText;
DROP TYPE UnicodeCode;
GO
