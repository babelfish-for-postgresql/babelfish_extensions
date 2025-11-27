/*   Jira - BABEL-6023
 * ======================================================================================================================
 *                                    CONVERT TO BINARY TEST CASES SUMMARY
 * ======================================================================================================================
 *
 * |  #  |                    Test Case                    |        Type         |                    Remark                     |
 * |-----|-------------------------------------------------|---------------------|-----------------------------------------------|
 * |  1  | Basic string to BINARY(5)                       | Basic               | Tests 'ABC' conversion                        |
 * |  2  | Basic string to BINARY (no size)                | Basic               | Tests default BINARY size                     |
 * |  3  | Empty string to BINARY(5)                       | Edge Case           | Tests empty string conversion                 |
 * |  4  | NULL value to BINARY(5)                         | NULL Handling       | Tests NULL conversion                         |
 * |  5  | Integer to BINARY(4)                            | Data Types          | Tests numeric conversion                      |
 * |  6  | Date to BINARY(8)                               | Data Types          | Tests datetime conversion                     |
 * |  7  | String truncation to BINARY(3)                  | Truncation          | Tests 'ABCDE' truncated to 3 bytes            |
 * |  8  | Exact length string to BINARY(3)                | Exact Fit           | Tests 'ABC' exact fit                         |
 * |  9  | Special characters to BINARY(5)                 | Special Chars       | Tests '!@#$%' conversion                      |
 * | 10  | Unicode characters to BINARY(10)                | Unicode             | Tests N'Hello世界' conversion                 |
 * | 11  | Variable conversion to BINARY(5)                | Variables           | Tests VARCHAR variable conversion             |
 * | 12  | Expression conversion to BINARY(10)             | Expressions         | Tests string concatenation conversion         |
 * | 13  | Complex string concatenation                    | Complex             | Tests CONCAT with employee data               |
 * | 14  | Nested conversions with math                    | Complex             | Tests nested CONVERT with calculations        |
 * | 15  | Unicode string processing                       | Unicode Complex     | Tests complex Unicode string operations       |
 * | 16  | Version history with binary comparison          | Complex CTE         | Tests CTE with binary operations              |
 * | 17  | Binary manipulation test                        | Binary Operations   | Tests binary AND operations                   |
 * | 18  | Performance test with large data                | Performance         | Tests 4000 character conversion               |
 * | 19  | VARBINARY to BINARY conversion                  | Type Conversion     | Tests VARBINARY(10) to BINARY(10)             |
 * | 20  | NULL VARBINARY conversion                       | NULL Handling       | Tests NULL VARBINARY conversion               |
 * | 21  | Empty VARBINARY conversion                      | Edge Case           | Tests empty VARBINARY conversion              |
 * | 22  | VARBINARY truncation test                       | Truncation          | Tests longer VARBINARY to shorter BINARY      |
 * | 23  | VARBINARY padding test                          | Padding             | Tests shorter VARBINARY to longer BINARY      |
 * | 24  | VARBINARY special characters                    | Special Chars       | Tests special chars in VARBINARY              |
 * | 25  | VARBINARY numeric conversion                    | Data Types          | Tests numeric VARBINARY conversion            |
 * | 26  | VARBINARY Unicode conversion                    | Unicode             | Tests Unicode VARBINARY conversion            |
 * | 27  | VARBINARY max length test                       | Max Length          | Tests 8000 byte VARBINARY conversion          |
 * | 28  | Style 0 default conversion                      | Style Parameters    | Tests default style parameter                 |
 * | 29  | Style 1 hex with 0x prefix                      | Style Parameters    | Tests hex string with 0x prefix               |
 * | 30  | Style 2 hex without 0x prefix                   | Style Parameters    | Tests hex string without 0x prefix            |
 * | 31  | Invalid hex string with style 1                 | Error Handling      | Tests invalid hex format error                |
 * | 32  | 0x prefix with style 2 error                    | Error Handling      | Tests incompatible style/format error         |
 * | 33  | View DocumentBinaryInfo test                    | Dependent Objects   | Tests view with binary operations             |
 * | 34  | View DocumentVersionComparison test             | Dependent Objects   | Tests version comparison view                 |
 * | 35  | Function ConvertAndCompare test                 | Dependent Objects   | Tests table-valued function                   |
 * | 36  | Function GetBinaryHash test                     | Dependent Objects   | Tests scalar function                         |
 * | 37  | Stored Procedure InsertDocument test            | Dependent Objects   | Tests procedure with binary parameter         |
 * | 38  | Stored Procedure UpdateDocument test            | Dependent Objects   | Tests procedure with binary update            |
 * | 39  | Trigger error handling test                     | Dependent Objects   | Tests trigger with size validation            |
 * | 40  | VARBINARY style 0 conversion                    | Style Parameters    | Tests VARBINARY with style 0                  |
 * | 41  | VARBINARY style 1 hex conversion                | Style Parameters    | Tests VARBINARY with style 1                  |
 * | 42  | VARBINARY style 2 hex conversion                | Style Parameters    | Tests VARBINARY with style 2                  |
 * | 43  | CONVERT vs CAST integer difference              | Comparison          | Tests CONVERT vs CAST behavior                |
 * | 44+ | All data types to BINARY conversion             | Comprehensive       | Tests all SQL Server data types               |
 *
 * ======================================================================================================================
 */

USE TestConvertForBinary;
GO

-- Test Case 1: Basic string to BINARY(5)
SELECT 'Test 1: Basic string' as TestCase,
    CONVERT(BINARY(5), 'ABC') as Result;
GO

-- Test Case 2: Basic string to BINARY (no size)
SELECT 'Test 2: Basic string no size' as TestCase,
    CONVERT(BINARY, 'ABC') as Result;
GO

-- Test Case 3: Empty string to BINARY(5)
SELECT 'Test 3: Empty string' as TestCase,
    CONVERT(BINARY(5), '') as Result;
GO

-- Test Case 4: NULL value to BINARY(5)
SELECT 'Test 4: NULL value' as TestCase,
    CONVERT(BINARY(5), NULL) as Result;
GO

-- Test Case 5: Integer to BINARY(4)
SELECT 'Test 5: Integer' as TestCase,
    CONVERT(BINARY(4), 123) as Result;
GO

-- Test Case 6: Date to BINARY(8)
SELECT 'Test 6: Date' as TestCase,
    CONVERT(BINARY(8), '2023-01-01 10:00:00') as Result;
GO

-- Test Case 7: String truncation to BINARY(3)
SELECT 'Test 7: Short length' as TestCase,
    CONVERT(BINARY(3), 'ABCDE') as Result;
GO

-- Test Case 8: Exact length string to BINARY(3)
SELECT 'Test 8: Exact length' as TestCase,
    CONVERT(BINARY(3), 'ABC') as Result;
GO

-- Test Case 9: Special characters to BINARY(5)
SELECT 'Test 9: Special chars' as TestCase,
    CONVERT(BINARY(5), '!@#$%') as Result;
GO

-- Test Case 10: Unicode characters to BINARY(10)
SELECT 'Test 10: Unicode Characters' as TestCase,
    CONVERT(BINARY(10), N'Hello世界') as Result;
GO

-- Test Case 11: Variable conversion to BINARY(5)
DECLARE @var1 VARCHAR(10) = 'Test';
SELECT 'Test 11: Variable Conversion' as TestCase,
    CONVERT(BINARY(5), @var1) as Result;
GO

-- Test Case 12: Expression conversion to BINARY(10)
SELECT 'Test 12: Expression' as TestCase,
    CONVERT(BINARY(10), 'Hello' + ' World') as Result;
GO

-- Test Case 13: Complex string concatenation
SELECT 'Test 13: Complex String Concatenation' as TestCase,
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

-- Test Case 14: Nested conversions with mathematical operations
SELECT 'Test 14: Nested Conversions' as TestCase,
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

-- Test Case 15: Unicode string processing
SELECT 'Test 15: Unicode Processing' as TestCase,
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

-- Test Case 16: Version history with binary comparison
WITH VersionChanges AS (
    SELECT 
        d.DocName,
        dv.VersionNumber,
        CONVERT(BINARY(50), dv.BinaryContent) as ConvertedContent,
        dbo.fn_GetBinaryHash(dv.BinaryContent) as VersionHash
    FROM Documents d
    JOIN DocumentVersions dv ON d.DocID = dv.DocID
)
SELECT 'Test 16: Complex Version Analysis' as TestCase,
    DocName,
    VersionNumber,
    ConvertedContent,
    VersionHash
FROM VersionChanges
ORDER BY DocName, VersionNumber;
GO

-- Test Case 17: Binary manipulation test
SELECT 'Test 17: Binary Manipulation' as TestCase,
    CONVERT(BINARY(20),
        dbo.GenerateRandomBinary(10)
    ) & 
    CONVERT(BINARY(20),
        CAST('Test' AS BINARY(10))
    ) as Result;
GO

-- Test Case 18: Performance test with large data
DECLARE @largeText VARCHAR(MAX) = REPLICATE('A', 4000);
DECLARE @startTime DATETIME = '2023-01-01 10:00:00';

SELECT 'Test 18: Performance Test' as TestCase,
    DATALENGTH(
        CONVERT(BINARY(4000),
            @largeText
        )
    ) as Result,
    DATEDIFF(millisecond, @startTime, '2023-01-01 10:00:01') as ExecutionTime;
GO

-- Test Case 19: VARBINARY to BINARY conversion
SELECT 'Test 19: VARBINARY to BINARY conversion' as TestCase,
    CONVERT(BINARY(10), CAST('Hello' AS VARBINARY(10))) as Result;
GO

-- Test Case 20: NULL VARBINARY conversion
SELECT 'Test 20: NULL VARBINARY conversion' as TestCase, 
    CONVERT(BINARY(5), CAST(NULL AS VARBINARY(5))) as Result;
GO

-- Test Case 21: Empty VARBINARY conversion
SELECT 'Test 21: Empty VARBINARY conversion' as TestCase,
    CONVERT(BINARY(5), CAST('' AS VARBINARY(5))) as Result; 
GO

-- Test Case 22: VARBINARY truncation test
SELECT 'Test 22: Truncation test' as TestCase,
    CONVERT(BINARY(3), CAST('Testing' AS VARBINARY(10))) as Result;
GO

-- Test Case 23: VARBINARY padding test
SELECT 'Test 23: Padding test' as TestCase, 
    CONVERT(BINARY(10), CAST('Test' AS VARBINARY(5))) as Result;
GO

-- Test Case 24: VARBINARY special characters
SELECT 'Test 24: Special characters' as TestCase,
    CONVERT(BINARY(5), CAST('!@#$%' AS VARBINARY(5))) as Result;
GO

-- Test Case 25: VARBINARY numeric conversion
SELECT 'Test 25: Numeric conversion' as TestCase,
    CONVERT(BINARY(4), CAST(12345 AS VARBINARY(4))) as Result;
GO

-- Test Case 26: VARBINARY Unicode conversion
SELECT 'Test 26: Unicode conversion' as TestCase,
    CONVERT(BINARY(10), CAST(N'Hello世界' AS VARBINARY(10))) as Result;
GO

-- Test Case 27: VARBINARY max length test
SELECT 'Test 27: Max length test' as TestCase,
    CONVERT(BINARY(8000), CAST(REPLICATE('X', 8000) AS VARBINARY(8000))) as Result;
GO

-- Test Case 28: Style 0 default conversion
SELECT 'Test 28: Style 0 default' as TestCase,
    CONVERT(BINARY(10), 'Hello', 0) as Result;
GO

-- Test Case 29: Style 1 hex with 0x prefix
SELECT 'Test 29: Style 1 hex with 0x' as TestCase,
    CONVERT(BINARY(5), '0x48656C6C6F', 1) as Result;
GO

-- Test Case 30: Style 2 hex without 0x prefix
SELECT 'Test 30: Style 2 hex without 0x' as TestCase,
    CONVERT(BINARY(5), '48656C6C6F', 2) as Result;
GO

-- Test Case 31: Invalid hex string with style 1
BEGIN TRY
    SELECT 'Test 31: Invalid hex style 1' as TestCase,
        CONVERT(BINARY(5), '0x48656C6C6', 1) as Result;
END TRY
BEGIN CATCH
    SELECT 'Test 31: Invalid hex style 1 error' as TestCase,
        ERROR_MESSAGE() as ErrorMessage;
END CATCH;
GO

-- Test Case 32: 0x prefix with style 2 error
BEGIN TRY
    SELECT 'Test 32: 0x prefix with style 2' as TestCase,
        CONVERT(BINARY(5), '0x48656C6C6F', 2) as Result;
END TRY
BEGIN CATCH
    SELECT 'Test 32: 0x prefix with style 2 error' as TestCase,
        ERROR_MESSAGE() as ErrorMessage;
END CATCH;
GO

-- Test Case 33: View DocumentBinaryInfo
SELECT 'Test 33: View DocumentBinaryInfo' as TestCase, * FROM vw_DocumentBinaryInfo;
GO

-- Test Case 34: View DocumentVersionComparison
SELECT 'Test 34: View DocumentVersionComparison' as TestCase, * FROM vw_DocumentVersionComparison;
GO

-- Test Case 35: Function ConvertAndCompare
SELECT 'Test 35: Function ConvertAndCompare' as TestCase,
    *
FROM fn_ConvertAndCompare(
    CAST('Test Content 1' AS VARBINARY(MAX)),
    CAST('Test Content 2' AS VARBINARY(MAX))
);
GO

-- Test Case 36: Function GetBinaryHash
SELECT 'Test 36: Function GetBinaryHash' as TestCase,
    DocName,
    dbo.fn_GetBinaryHash(DocContent) as ContentHash
FROM Documents;
GO

-- Test Case 37: Stored Procedure InsertDocument
EXEC sp_InsertDocument 
    @docID = 3,
    @docName = 'TestDoc3.pdf',
    @content = 0x48656C6C6F,  -- 'Hello' in hex
    @docType = 'PDF';
GO

SELECT 'Test 37: Procedure InsertDocument' as TestCase,
    DocName, DocContent
FROM Documents 
WHERE DocName = 'TestDoc3.pdf';
GO

-- Test Case 38: Stored Procedure UpdateDocument
EXEC sp_UpdateDocument
    @docID = 1,
    @newContent = 0x576F726C64;  -- 'World' in hex
GO

SELECT 'Test 38: Procedure UpdateDocument' as TestCase,
    d.DocName,
    d.DocContent,
    v.VersionNumber
FROM Documents d
JOIN DocumentVersions v ON d.DocID = v.DocID
WHERE d.DocID = 1
ORDER BY v.VersionNumber;
GO

-- Test Case 39: Trigger error handling
BEGIN TRY
    INSERT INTO Documents (DocID, DocName, DocContent, DocType, CreatedDate)
    VALUES (4, 'LargeDoc.txt', CONVERT(VARBINARY(MAX), REPLICATE('A', 1048577)), 'TXT', '2023-01-01 10:00:00');
    
    SELECT 'Test 39: Trigger - Should Not See This' as TestCase;
END TRY
BEGIN CATCH
    SELECT 
        'Test 39: Trigger Error Handling' as TestCase,
        ERROR_MESSAGE() as ErrorMessage;
END CATCH;
GO

-- Test Case 40: VARBINARY style 0 conversion
SELECT 'Test 40: VARBINARY style 0' as TestCase,
    CONVERT(VARBINARY(10), 'Test', 0) as Result;
GO

-- Test Case 41: VARBINARY style 1 hex conversion
SELECT 'Test 41: VARBINARY style 1 hex' as TestCase,
    CONVERT(VARBINARY(10), '0x54657374', 1) as Result;
GO

-- Test Case 42: VARBINARY style 2 hex conversion
SELECT 'Test 42: VARBINARY style 2 hex' as TestCase,
    CONVERT(VARBINARY(10), '54657374', 2) as Result;
GO

-- Test Case 43: CONVERT vs CAST integer to binary difference(jira query)
DECLARE @accId int = 100;
SELECT @accId, 
    CONVERT(BINARY(16), @accId), --0x64800000000000000000000000000000
    CAST(@accId AS BINARY(16));  --0x00000000000000000000000000000064
GO

-- Test Case 44-70: CONVERT all data types to BINARY
-- Numeric Types
SELECT CONVERT(BINARY(1), CAST(255 AS TINYINT)) AS tinyint_binary;
GO
SELECT CONVERT(BINARY(2), CAST(32767 AS SMALLINT)) AS smallint_binary;
GO
SELECT CONVERT(BINARY(4), CAST(2147483647 AS INT)) AS int_binary;
GO
SELECT CONVERT(BINARY(8), CAST(9223372036854775807 AS BIGINT)) AS bigint_binary;
GO
SELECT CONVERT(BINARY(1), CAST(1 AS BIT)) AS bit_binary;
GO
SELECT CONVERT(BINARY(5), CAST(12345.67 AS DECIMAL(7,2))) AS decimal_binary;
GO
SELECT CONVERT(BINARY(9), CAST(123456789.12 AS NUMERIC(11,2))) AS numeric_binary;
GO
SELECT CONVERT(BINARY(8), CAST(123.456 AS FLOAT)) AS float_binary;
GO
SELECT CONVERT(BINARY(4), CAST(123.45 AS REAL)) AS real_binary;
GO
SELECT CONVERT(BINARY(8), CAST(922337203685477.5807 AS MONEY)) AS money_binary;
GO
SELECT CONVERT(BINARY(4), CAST(214748.3647 AS SMALLMONEY)) AS smallmoney_binary;
GO

-- Date/Time Types
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.123' AS DATETIME)) AS datetime_binary;
GO
SELECT CONVERT(BINARY(4), CAST('2023-01-01 12:30:45' AS SMALLDATETIME)) AS smalldatetime_binary;
GO
SELECT CONVERT(BINARY(3), CAST('2023-01-01' AS DATE)) AS date_binary;
GO
SELECT CONVERT(BINARY(5), CAST('12:30:45.1234567' AS TIME)) AS time_binary;
GO
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.123' AS DATETIME2)) AS datetime2_binary;
GO
SELECT CONVERT(BINARY(10), CAST('2023-01-01 12:30:45.123 +05:30' AS DATETIMEOFFSET)) AS datetimeoffset_binary;
GO

-- String Types
SELECT CONVERT(BINARY(10), CAST('Hello' AS CHAR(10))) AS char_binary;
GO
SELECT CONVERT(BINARY(10), CAST('Hello' AS VARCHAR(10))) AS varchar_binary;
GO
SELECT CONVERT(BINARY(20), CAST('Hello World' AS VARCHAR(MAX))) AS varchar_max_binary;
GO
SELECT CONVERT(BINARY(20), CAST(N'Hello' AS NCHAR(10))) AS nchar_binary;
GO
SELECT CONVERT(BINARY(20), CAST(N'Hello' AS NVARCHAR(10))) AS nvarchar_binary;
GO
SELECT CONVERT(BINARY(20), CAST(N'Hello World' AS NVARCHAR(MAX))) AS nvarchar_max_binary;
GO
SELECT CONVERT(BINARY(10), CAST('Hello' AS TEXT)) AS text_binary;
GO
SELECT CONVERT(BINARY(20), CAST(N'Hello' AS NTEXT)) AS ntext_binary;
GO

-- Binary Types
SELECT CONVERT(BINARY(10), CAST(0x48656C6C6F AS BINARY(10))) AS binary_to_binary;
GO
SELECT CONVERT(BINARY(10), CAST(0x48656C6C6F AS VARBINARY(10))) AS varbinary_binary;
GO
SELECT CONVERT(BINARY(20), CAST(0x48656C6C6F576F726C64 AS VARBINARY(MAX))) AS varbinary_max_binary;
GO
SELECT CONVERT(BINARY(10), CAST('Hello' AS IMAGE)) AS image_binary;
GO

-- NULL values for each type
SELECT CONVERT(BINARY(4), CAST(NULL AS INT)) AS null_int_binary;
GO
SELECT CONVERT(BINARY(8), CAST(NULL AS DATETIME)) AS null_datetime_binary;
GO
SELECT CONVERT(BINARY(10), CAST(NULL AS VARCHAR(10))) AS null_varchar_binary;
GO
SELECT CONVERT(BINARY(10), CAST(NULL AS VARBINARY(10))) AS null_varbinary_binary;
GO

-- Test Case 71+: CONVERT all data types to VARBINARY
-- Numeric Types to VARBINARY
SELECT CONVERT(VARBINARY(1), CAST(255 AS TINYINT)) AS tinyint_varbinary;
GO
SELECT CONVERT(VARBINARY(2), CAST(32767 AS SMALLINT)) AS smallint_varbinary;
GO
SELECT CONVERT(VARBINARY(4), CAST(2147483647 AS INT)) AS int_varbinary;
GO
SELECT CONVERT(VARBINARY(8), CAST(9223372036854775807 AS BIGINT)) AS bigint_varbinary;
GO
SELECT CONVERT(VARBINARY(1), CAST(1 AS BIT)) AS bit_varbinary;
GO
SELECT CONVERT(VARBINARY(5), CAST(12345.67 AS DECIMAL(7,2))) AS decimal_varbinary;
GO
SELECT CONVERT(VARBINARY(9), CAST(123456789.12 AS NUMERIC(11,2))) AS numeric_varbinary;
GO
SELECT CONVERT(VARBINARY(8), CAST(123.456 AS FLOAT)) AS float_varbinary;
GO
SELECT CONVERT(VARBINARY(4), CAST(123.45 AS REAL)) AS real_varbinary;
GO
SELECT CONVERT(VARBINARY(8), CAST(922337203685477.5807 AS MONEY)) AS money_varbinary;
GO
SELECT CONVERT(VARBINARY(4), CAST(214748.3647 AS SMALLMONEY)) AS smallmoney_varbinary;
GO

-- Date/Time Types to VARBINARY
SELECT CONVERT(VARBINARY(8), CAST('2023-01-01 12:30:45.123' AS DATETIME)) AS datetime_varbinary;
GO
SELECT CONVERT(VARBINARY(4), CAST('2023-01-01 12:30:45' AS SMALLDATETIME)) AS smalldatetime_varbinary;
GO
SELECT CONVERT(VARBINARY(3), CAST('2023-01-01' AS DATE)) AS date_varbinary;
GO
SELECT CONVERT(VARBINARY(5), CAST('12:30:45.1234567' AS TIME)) AS time_varbinary;
GO
SELECT CONVERT(VARBINARY(8), CAST('2023-01-01 12:30:45.123' AS DATETIME2)) AS datetime2_varbinary;
GO
SELECT CONVERT(VARBINARY(10), CAST('2023-01-01 12:30:45.123 +05:30' AS DATETIMEOFFSET)) AS datetimeoffset_varbinary;
GO

-- String Types to VARBINARY
SELECT CONVERT(VARBINARY(10), CAST('Hello' AS CHAR(10))) AS char_varbinary;
GO
SELECT CONVERT(VARBINARY(10), CAST('Hello' AS VARCHAR(10))) AS varchar_varbinary;
GO
SELECT CONVERT(VARBINARY(20), CAST('Hello World' AS VARCHAR(MAX))) AS varchar_max_varbinary;
GO
SELECT CONVERT(VARBINARY(20), CAST(N'Hello' AS NCHAR(10))) AS nchar_varbinary;
GO
SELECT CONVERT(VARBINARY(20), CAST(N'Hello' AS NVARCHAR(10))) AS nvarchar_varbinary;
GO
SELECT CONVERT(VARBINARY(20), CAST(N'Hello World' AS NVARCHAR(MAX))) AS nvarchar_max_varbinary;
GO
SELECT CONVERT(VARBINARY(10), CAST('Hello' AS TEXT)) AS text_varbinary;
GO
SELECT CONVERT(VARBINARY(20), CAST(N'Hello' AS NTEXT)) AS ntext_varbinary;
GO

-- Binary Types to VARBINARY
SELECT CONVERT(VARBINARY(10), CAST(0x48656C6C6F AS BINARY(10))) AS binary_to_varbinary;
GO
SELECT CONVERT(VARBINARY(10), CAST(0x48656C6C6F AS VARBINARY(10))) AS varbinary_to_varbinary;
GO
SELECT CONVERT(VARBINARY(20), CAST(0x48656C6C6F576F726C64 AS VARBINARY(MAX))) AS varbinary_max_to_varbinary;
GO
SELECT CONVERT(VARBINARY(10), CAST('Hello' AS IMAGE)) AS image_varbinary;
GO


-- NULL values to VARBINARY
SELECT CONVERT(VARBINARY(4), CAST(NULL AS INT)) AS null_int_varbinary;
GO
SELECT CONVERT(VARBINARY(8), CAST(NULL AS DATETIME)) AS null_datetime_varbinary;
GO
SELECT CONVERT(VARBINARY(10), CAST(NULL AS VARCHAR(10))) AS null_varchar_varbinary;
GO
SELECT CONVERT(VARBINARY(10), CAST(NULL AS VARBINARY(10))) AS null_varbinary_varbinary;
GO