USE TestConvertForBinary;
GO

-- 1. String conversions
SELECT 'Test 1: Basic string' as TestCase,
    CONVERT(BINARY(5), 'ABC') as Result;
GO

SELECT 'Test 1: Basic string' as TestCase,
    CONVERT(BINARY, 'ABC') as Result;
GO

SELECT 'Test 2: Empty string' as TestCase,
    CONVERT(BINARY(5), '') as Result;
GO

SELECT 'Test 3: NULL value' as TestCase,
    CONVERT(BINARY(5), NULL) as Result;
GO

-- 2. Number conversions
SELECT 'Test 4: Integer' as TestCase,
    CONVERT(BINARY(4), 123) as Result;
GO

-- 3. Date conversion
SELECT 'Test 6: Date' as TestCase,
    CONVERT(BINARY(8), '2023-01-01 10:00:00') as Result;
GO

-- 4. Different lengths
SELECT 'Test 7: Short length' as TestCase,
    CONVERT(BINARY(3), 'ABCDE') as Result;
GO

SELECT 'Test 8: Exact length' as TestCase,
    CONVERT(BINARY(3), 'ABC') as Result;
GO

-- 5. Special characters
SELECT 'Test 9: Special chars' as TestCase,
    CONVERT(BINARY(5), '!@#$%') as Result;
GO

-- 6. Unicode Tests
SELECT 'Test 7.1: Unicode Characters' as TestCase,
    CONVERT(BINARY(10), N'Hello世界') as Result;
GO

-- 7. Variable Tests
DECLARE @var1 VARCHAR(10) = 'Test';
SELECT 'Test 8.1: Variable Conversion' as TestCase,
    CONVERT(BINARY(5), @var1) as Result;
GO

-- 8. Expression Tests
SELECT 'Test 9.1: Expression' as TestCase,
    CONVERT(BINARY(10), 'Hello' + ' World') as Result;
GO

-- 9. Complex String Concatenation and Conversion
SELECT 'Test 1: Complex String Concatenation' as TestCase,
    CONVERT(BINARY(20), 
        CONCAT(
            e.FirstName, 
            '_',
            e.LastName, 
            '_',
            FORMAT(e.Salary, 'C')
        )
    ) as Result
FROM Employee e
WHERE e.EmployeeID = 1;
GO

-- 11. Nested Conversions with Mathematical Operations
SELECT 'Test 3: Nested Conversions' as TestCase,
    CONVERT(BINARY(10),
        CONVERT(VARCHAR(20),
            ROUND(
                e.Salary * 1.15 + 
                (DATEDIFF(day, e.HireDate, '2023-01-01 10:00:00') * 10),
                2
            )
        )
    ) as Result
FROM Employee e;
GO

-- 12. Unicode String Processing
SELECT 'Test 4: Unicode Processing' as TestCase,
    CONVERT(BINARY(50),
        CONCAT(
            N'Employee: ',
            FirstName,
            N' - Department: ',
            Department,
            N' - Salary Range: ',
            CASE 
                WHEN Salary > 80000 THEN N'High'
                WHEN Salary > 70000 THEN N'Medium'
                ELSE N'Standard'
            END
        )
    ) as Result
FROM Employee
WHERE FirstName LIKE N'%[^a-zA-Z]%';
GO

-- 13. Test Complex Scenarios
-- Test Version History with Binary Comparison
WITH VersionChanges AS (
    SELECT 
        d.DocName,
        dv.VersionNumber,
        CONVERT(BINARY(50), dv.BinaryContent) as ConvertedContent,
        dbo.fn_GetBinaryHash(dv.BinaryContent) as VersionHash
    FROM Documents d
    JOIN DocumentVersions dv ON d.DocID = dv.DocID
)
SELECT 'Test 5.1: Complex Version Analysis' as TestCase,
    DocName,
    VersionNumber,
    ConvertedContent,
    VersionHash
FROM VersionChanges
ORDER BY DocName, VersionNumber;
GO

-- 14. Binary Manipulation Test
SELECT 'Test 8: Binary Manipulation' as TestCase,
    CONVERT(BINARY(20),
        dbo.GenerateRandomBinary(10)
    ) & 
    CONVERT(BINARY(20),
        CAST('Test' AS BINARY(10))
    ) as Result;
GO

-- 15. Performance Test with Large Data
DECLARE @largeText VARCHAR(MAX) = REPLICATE('A', 4000);
DECLARE @startTime DATETIME = '2023-01-01 10:00:00';

SELECT 'Test 9: Performance Test' as TestCase,
    DATALENGTH(
        CONVERT(BINARY(4000),
            @largeText
        )
    ) as Result,
    DATEDIFF(millisecond, @startTime, '2023-01-01 10:00:01') as ExecutionTime;
GO

-- 16. from varbianry to binary
-- Test case for converting VARBINARY to BINARY
SELECT 'Test 16.1: VARBINARY to BINARY conversion' as TestCase,
    CONVERT(BINARY(10), CAST('Hello' AS VARBINARY(10))) as Result;
GO

-- Test case for NULL VARBINARY
SELECT 'Test 16.2: NULL VARBINARY conversion' as TestCase, 
    CONVERT(BINARY(5), CAST(NULL AS VARBINARY(5))) as Result;
GO

-- Test case for empty VARBINARY
SELECT 'Test 16.3: Empty VARBINARY conversion' as TestCase,
    CONVERT(BINARY(5), CAST('' AS VARBINARY(5))) as Result; 
GO

-- Test case for VARBINARY longer than target BINARY length
SELECT 'Test 16.4: Truncation test' as TestCase,
    CONVERT(BINARY(3), CAST('Testing' AS VARBINARY(10))) as Result;
GO

-- Test case for VARBINARY shorter than target BINARY length
SELECT 'Test 16.5: Padding test' as TestCase, 
    CONVERT(BINARY(10), CAST('Test' AS VARBINARY(5))) as Result;
GO

-- Test case with special characters
SELECT 'Test 16.6: Special characters' as TestCase,
    CONVERT(BINARY(5), CAST('!@#$%' AS VARBINARY(5))) as Result;
GO

-- Test case with numbers
SELECT 'Test 16.7: Numeric conversion' as TestCase,
    CONVERT(BINARY(4), CAST(12345 AS VARBINARY(4))) as Result;
GO

-- Test case with Unicode
SELECT 'Test 16.8: Unicode conversion' as TestCase,
    CONVERT(BINARY(10), CAST(N'Hello世界' AS VARBINARY(10))) as Result;
GO

-- Test case with maximum length
SELECT 'Test 16.9: Max length test' as TestCase,
    CONVERT(BINARY(8000), CAST(REPLICATE('X', 8000) AS VARBINARY(8000))) as Result;
GO

----- 17. Style parameter tests for string to binary conversion
-- Test style 0 (default)
SELECT 'Test 17.1: Style 0 default' as TestCase,
    CONVERT(BINARY(10), 'Hello', 0) as Result;
GO

-- Test style 1 (hex with 0x prefix)
SELECT 'Test 17.2: Style 1 hex with 0x' as TestCase,
    CONVERT(BINARY(5), '0x48656C6C6F', 1) as Result;
GO

-- Test style 2 (hex without 0x prefix)
SELECT 'Test 17.3: Style 2 hex without 0x' as TestCase,
    CONVERT(BINARY(5), '48656C6C6F', 2) as Result;
GO

-- Test invalid hex string with style 1
BEGIN TRY
    SELECT 'Test 17.4: Invalid hex style 1' as TestCase,
        CONVERT(BINARY(5), '0x48656C6C6', 1) as Result;
END TRY
BEGIN CATCH
    SELECT 'Test 17.4: Invalid hex style 1 error' as TestCase,
        ERROR_MESSAGE() as ErrorMessage;
END CATCH;
GO

-- Test hex string with 0x prefix using style 2 (should error)
BEGIN TRY
    SELECT 'Test 17.5: 0x prefix with style 2' as TestCase,
        CONVERT(BINARY(5), '0x48656C6C6F', 2) as Result;
END TRY
BEGIN CATCH
    SELECT 'Test 17.5: 0x prefix with style 2 error' as TestCase,
        ERROR_MESSAGE() as ErrorMessage;
END CATCH;
GO

-------------------------------------------------- Dependent objects test --------------------------------------------------------

-- 1. Test Views
-- Test vw_DocumentBinaryInfo
SELECT 'Test 1.1: View DocumentBinaryInfo' as TestCase, * FROM vw_DocumentBinaryInfo;
GO

-- Test vw_DocumentVersionComparison
SELECT 'Test 1.2: View DocumentVersionComparison' as TestCase, * FROM vw_DocumentVersionComparison;
GO

-- 2. Test Functions
-- Test fn_ConvertAndCompare
SELECT 'Test 2.1: Function ConvertAndCompare' as TestCase,
    *
FROM fn_ConvertAndCompare(
    CAST('Test Content 1' AS VARBINARY(MAX)),
    CAST('Test Content 2' AS VARBINARY(MAX))
);
GO

-- Test fn_GetBinaryHash
SELECT 'Test 2.2: Function GetBinaryHash' as TestCase,
    DocName,
    dbo.fn_GetBinaryHash(DocContent) as ContentHash
FROM Documents;
GO

-- 3. Test Stored Procedures
-- Test sp_InsertDocument
EXEC sp_InsertDocument 
    @docID = 3,
    @docName = 'TestDoc3.pdf',
    @content = 0x48656C6C6F,  -- 'Hello' in hex
    @docType = 'PDF';
GO

SELECT 'Test 3.1: Procedure InsertDocument' as TestCase,
    DocName, DocContent
FROM Documents 
WHERE DocName = 'TestDoc3.pdf';
GO

-- Test sp_UpdateDocument
EXEC sp_UpdateDocument
    @docID = 1,
    @newContent = 0x576F726C64;  -- 'World' in hex
GO

SELECT 'Test 3.2: Procedure UpdateDocument' as TestCase,
    d.DocName,
    d.DocContent,
    v.VersionNumber
FROM Documents d
JOIN DocumentVersions v ON d.DocID = v.DocID
WHERE d.DocID = 1
ORDER BY v.VersionNumber;
GO

-- 4. Test Trigger
BEGIN TRY
    INSERT INTO Documents (DocID, DocName, DocContent, DocType, CreatedDate)
    VALUES (4, 'LargeDoc.txt', CONVERT(VARBINARY(MAX), REPLICATE('A', 1048577)), 'TXT', '2023-01-01 10:00:00');
    
    SELECT 'Test 4.1: Trigger - Should Not See This' as TestCase;
END TRY
BEGIN CATCH
    SELECT 
        'Test 4.1: Trigger Error Handling' as TestCase,
        ERROR_MESSAGE() as ErrorMessage;
END CATCH;
GO

-- 18. Additional style parameter tests with VARBINARY
-- Test VARBINARY conversion with style parameters
SELECT 'Test 18.1: VARBINARY style 0' as TestCase,
    CONVERT(VARBINARY(10), 'Test', 0) as Result;
GO

SELECT 'Test 18.2: VARBINARY style 1 hex' as TestCase,
    CONVERT(VARBINARY(10), '0x54657374', 1) as Result;
GO

SELECT 'Test 18.3: VARBINARY style 2 hex' as TestCase,
    CONVERT(VARBINARY(10), '54657374', 2) as Result;
GO
