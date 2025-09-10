-- 1. Test binary, varbinary, char, varchar combinations
UPDATE ascii_function_binary_test
SET CharASCII = ASCII(CharCol),
    VarcharASCII = ASCII(VarcharCol),
    BinaryASCII = ASCII(BinaryCol),
    VarbinaryASCII = ASCII(VarbinaryCol),
    TestResult = CASE 
        WHEN ASCII(CharCol) = ASCII(VarcharCol) 
             AND ASCII(CharCol) = ASCII(BinaryCol)
             AND ASCII(CharCol) = ASCII(VarbinaryCol)
        THEN 'Pass' 
        ELSE 'Fail' 
    END;

SELECT * FROM ascii_function_binary_test ORDER BY ID;
GO

-- 2. Test empty strings
UPDATE ascii_function_empty_test
SET CharASCII = ASCII(CharCol),
    VarcharASCII = ASCII(VarcharCol),
    IsNull = CASE 
        WHEN ASCII(CharCol) IS NULL AND ASCII(VarcharCol) IS NULL THEN 1
        ELSE 0 
    END;

SELECT * FROM ascii_function_empty_test ORDER BY ID;
GO

-- 3. Test CHAR(n) range
SELECT 
    ID,
    CharValue,
    ASCII(CHAR(CharValue)) AS ComputedASCII,
    Description
FROM ascii_function_char_range
ORDER BY CharValue;
GO

-- 4. Test CAST and CONVERT functions
SELECT 
    InputValue,
    ASCII(CAST(InputValue AS CHAR(10))) AS CastToChar,
    ASCII(CAST(InputValue AS VARCHAR(50))) AS CastToVarchar,
    ASCII(CAST(InputValue AS NCHAR(10))) AS CastToNChar,
    ASCII(CAST(InputValue AS NVARCHAR(50))) AS CastToNVarchar
FROM ascii_function_conversion_test;
GO

-- 5. Test negative numbers
SELECT 
    NegativeNum,
    ASCII(NegativeNum) AS ASCIIValue,
    Description
FROM ascii_function_negative_test;
GO

-- Test money types 
SELECT 
    ID,
    ASCII(CAST(MoneyValue AS VARCHAR)) AS MoneyASCII,
    ASCII(CAST(SmallMoneyValue AS VARCHAR)) AS SmallMoneyASCII,
    Description
FROM ascii_function_special_types;
GO

-- Test NULL handling for different types

SELECT ASCII(CAST(NULL AS CHAR)) AS NullChar,
       ASCII(CAST(NULL AS VARCHAR)) AS NullVarchar,
       ASCII(CAST(NULL AS NCHAR)) AS NullNchar,
       ASCII(CAST(NULL AS NVARCHAR)) AS NullNvarchar,
       ASCII(CAST(NULL AS BINARY)) AS NullBinary,
       ASCII(CAST(NULL AS VARBINARY)) AS NullVarbinary,
       ASCII(CAST(NULL AS DATETIME)) AS NullDateTime,
       ASCII(CAST(NULL AS MONEY)) AS NullMoney,
       ASCII(CAST(NULL AS SMALLMONEY)) AS NullSmallMoney;
GO

-- Test empty string and zero value handling
SELECT ASCII('') AS EmptyString,
       ASCII(CAST('' AS NVARCHAR)) AS EmptyNVarchar,
       ASCII(CAST(0x00 AS VARBINARY)) AS ZeroBinary,
       ASCII(CAST(0 AS VARCHAR)) AS ZeroNumber,
       ASCII(CAST(0.00 AS MONEY)) AS ZeroMoney;
GO

-- Test date formats
SELECT ASCII(CONVERT(VARCHAR, GETDATE(), 101)) AS USDate,
       ASCII(CONVERT(VARCHAR, GETDATE(), 103)) AS BritishDate,
       ASCII(CONVERT(VARCHAR, GETDATE(), 120)) AS ISODate;
GO

-- Test money formats
SELECT ASCII(CAST(CAST(1234.56 AS MONEY) AS VARCHAR)) AS PositiveMoney,
       ASCII(CAST(CAST(-1234.56 AS MONEY) AS VARCHAR)) AS NegativeMoney,
       ASCII(CAST(CAST(0.00 AS MONEY) AS VARCHAR)) AS ZeroMoney,
       ASCII(CAST(CAST(214748.3647 AS SMALLMONEY) AS VARCHAR)) AS MaxSmallMoney;
GO

-- Test type conversion combinations
SELECT ASCII(CAST(CAST(123.45 AS MONEY) AS NVARCHAR)) AS MoneyToNVarchar,
       ASCII(CAST(CAST(123.45 AS DECIMAL(10,2)) AS VARCHAR)) AS DecimalToVarchar;
GO

-- Test with different date parts
SELECT ASCII(CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR)) AS YearASCII,
       ASCII(CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR)) AS MonthASCII,
       ASCII(CAST(DATEPART(DAY, GETDATE()) AS VARCHAR)) AS DayASCII;
GO

-- Test with currency symbols
SELECT ASCII('$') AS DollarSign,
       ASCII('¥') AS YenSign,
       ASCII('£') AS PoundSign;
GO

-- Test with special money formats
SELECT ASCII(CAST(CAST(1234.56 AS MONEY) AS VARCHAR)) AS Standard,
       ASCII('$' + CAST(CAST(1234.56 AS MONEY) AS VARCHAR)) AS WithDollar,
       ASCII(CAST(CAST(-1234.56 AS MONEY) AS VARCHAR)) AS Negative;
GO

-- Test NULL in combinations
SELECT * FROM ascii_function_null_types
WHERE ID = 1;
GO

-- Additional edge cases
SELECT ASCII(CAST(CAST(NULL AS MONEY) AS VARCHAR)) AS NullMoneyToVarchar,
       ASCII(CAST(CAST(NULL AS DATETIME) AS NVARCHAR)) AS NullDateToNVarchar;
GO

-- 6. Test CHAR(0)-- give wrong output in babelfish as char(0) return empty string value [BABEL-6068]
SELECT ASCII(CHAR(0)) AS ASCIIofChar0;
GO

-- 7. Test Functions
SELECT * FROM ascii_function_analyze_pattern('Hello123!@#');
SELECT * FROM ascii_function_analyze_pattern('ABC   123');
GO

SELECT * FROM ascii_function_compare_types('A', 'A', 0x41, 0x41);
SELECT * FROM ascii_function_compare_types('1', '1', 0x31, 0x31);
GO

-- 8. Test Procedures
EXEC ascii_function_analyze_string 'Hello123!@#';
EXEC ascii_function_analyze_string 'ABC   123';
GO

EXEC ascii_function_validate_conversion '65', 'CHAR';
EXEC ascii_function_validate_conversion 'A', 'NCHAR';
EXEC ascii_function_validate_conversion '123', 'VARCHAR';
GO

-- 9. Test Views
SELECT * FROM ascii_function_v_empty_analysis;
GO

-- 10. Additional Edge Cases
SELECT ASCII('') AS EmptyString,
       ASCII(' ') AS SingleSpace,
       ASCII('  ') AS TwoSpaces,
       ASCII(CHAR(1)) AS Char1,
       ASCII(CHAR(127)) AS Char127,
       ASCII(CAST(NULL AS VARCHAR)) AS NullVarchar,
       ASCII(CAST('' AS NVARCHAR)) AS EmptyNVarchar;
GO

-- 11. Mixed Data Type Tests
SELECT ASCII(CAST(65 AS CHAR)) AS IntToChar,
       ASCII(CAST(97.0 AS VARCHAR)) AS FloatToVarchar,
       ASCII(CAST('A' AS NCHAR)) AS CharToNChar,
       ASCII(CONVERT(VARCHAR, 65)) AS IntToVarchar;
GO

-- 12. Special Character Tests
SELECT ASCII('+') AS Plus,
       ASCII('-') AS Minus,
       ASCII('.') AS Dot,
       ASCII('E') AS E_Char;
GO
