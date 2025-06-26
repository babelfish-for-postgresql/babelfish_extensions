-- Test the view
SELECT * FROM binary_lengths
GO

-- Test the function
SELECT get_binary_length(0x0102030405)
GO

-- Test the stored procedure
EXEC check_binary_length 0x01020304050607
GO

-- Test computed column
SELECT * FROM binary_computed
GO

-- Test the trigger with various binary values
INSERT INTO binary_trigger_source (id, bin_data) VALUES 
(1, 0x01),
(2, 0x0102),
(3, 0x010203),
(4, 0x01020304),
(5, NULL)
GO
-- Verify the trigger correctly calculated lengths
SELECT * FROM binary_trigger_dest ORDER BY id
GO


-- Basic test case
select len(bin_data) from binary_len_test;
GO

-- BINARY INPUTS
declare @vb binary(10) = NULL
select len(@vb)
go

declare @vb binary(5)
set @vb = 0x90a;
select len(@vb)
go

declare @vb binary(1)
set @vb = 0x90a;
select len(@vb)
go

declare @vb binary(100)
set @vb = 0x90a;
select len(@vb)
go

-- checking max size
declare @vb binary(8000)
set @vb = 0x010a1a1a1a;
select len(@vb)
go

declare @vb binary(10)
set @vb = 0x0102030405060708090a021321321a321a3a213a21a;
select len(@vb)
go

declare @vb binary(10)
set @vb = 0x0102030405060708090a021a31321a321a321a321a321a3a213a21a;
select len(@vb)
go

-- no typmod
DECLARE @vb_no_typmod binary
SET @vb_no_typmod = 0x0102030405
SELECT LEN(@vb_no_typmod)
GO

-- Test case with explicit casting to binary
SELECT LEN(CAST(0x0102030405 AS BINARY(8))) as 'explicit_cast'
GO
SELECT LEN(CAST('abc' AS BINARY(8))) as 'explicit_cast'
GO

/* ----------------------------- UDT test case  --------------------------- */

-- Test LEN() with UDT based on BINARY
DECLARE @bin_udt BinaryUDT;
SET @bin_udt = 0x0102030405;
SELECT LEN(@bin_udt) AS [LEN of BinaryUDT];
GO

-- Test LEN() with NULL UDT based on BINARY
DECLARE @bin_udt BinaryUDT = NULL;
SELECT LEN(@bin_udt) AS [LEN of NULL BinaryUDT];
GO

-- Test LEN() with UDT based on BINARY with full size
DECLARE @bin_udt BinaryUDT;
SET @bin_udt = 0x01020304050607080910;
SELECT LEN(@bin_udt) AS [LEN of full BinaryUDT];
GO

-------------------------- Added all below test from len.sql -----------------------

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
