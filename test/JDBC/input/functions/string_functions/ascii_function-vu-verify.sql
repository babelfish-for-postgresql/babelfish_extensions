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

-- String Types
DECLARE @inputString sysname = N'  abc🙂defghi🙂🙂    ';
SELECT ASCII(@inputString);
GO

-- Date and Time Types
DECLARE @inputString date = '2016-12-21';
SELECT ASCII(@inputString);
GO

-- Test ASCII with datetime  --> will give incorrect results in babelfish [BABEL-1664]
DECLARE @date date = '12-21-16';  
DECLARE @inputString datetime = @date;
SELECT ASCII(@inputString);
GO

DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
SELECT ASCII(@inputString);
GO

DECLARE @inputString time(4) = '12:10:05.1237';
SELECT ASCII(@inputString);
GO

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
SELECT ASCII(@inputString);
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
SELECT ASCII(@inputString);
GO

-- Numeric Types
DECLARE @inputString decimal = 123456;
SELECT ASCII(@inputString);
GO

DECLARE @inputString numeric = 12345.12;
SELECT ASCII(@inputString);
GO

DECLARE @inputString float = 12345.1;
SELECT ASCII(@inputString);
GO

DECLARE @inputString real = 12345.1;
SELECT ASCII(@inputString);
GO

DECLARE @inputString bigint = 12345678;
SELECT ASCII(@inputString);
GO

DECLARE @inputString int = 12345678;
SELECT ASCII(@inputString);
GO

DECLARE @inputString smallint = 12356;
SELECT ASCII(@inputString);
GO

DECLARE @inputString tinyint = 235;
SELECT ASCII(@inputString);
GO

-- Money Types
DECLARE @inputString money = 12356;
SELECT ASCII(@inputString);
GO

DECLARE @inputString smallmoney = 12356;
SELECT ASCII(@inputString);
GO

-- Bit Type
DECLARE @inputString bit = 1;
SELECT ASCII(@inputString);
GO

-- Special Types
DECLARE @inputString uniqueidentifier = CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier);
SELECT ASCII(@inputString);
GO

-- Complex Types
DECLARE @inputString sql_variant = CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant);
SELECT ASCII(@inputString);
GO

DECLARE @inputString xml = CAST('<body><fruit/></body>' AS xml);
SELECT ASCII(@inputString);
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT ASCII(@inputString);
GO

DECLARE @inputString geography = geography::STGeomFromText('POINT(-122.34900 47.65100)', 4326);
SELECT ASCII(@inputString);
GO

-- Complex Types with Explicit Casting
DECLARE @inputString sql_variant = CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant);
SELECT ASCII(CAST(@inputString AS VARCHAR(50)));
GO

DECLARE @inputString xml = CAST('<body><fruit/></body>' AS xml);
SELECT ASCII(CAST(@inputString AS VARCHAR(50)));
GO

DECLARE @inputString geometry = geometry::STGeomFromText('POINT (1 2)', 0);
SELECT ASCII(CAST(@inputString AS VARCHAR(50)));
GO

-- Test IMAGE type
SELECT ASCII(a) AS image_ascii FROM ascii_function_image;
GO

-- Test TEXT and NTEXT types
SELECT ASCII(a) AS text_ascii, ASCII(b) AS ntext_ascii 
FROM ascii_function_text;
GO

-- Test VARBINARY(MAX) and TEXT types with various data
SELECT ID, ASCII(a) AS varbinary_ascii 
FROM ascii_function_test_image 
ORDER BY ID;
GO

SELECT 
    ID,
    ASCII(a) AS text_ascii,
    ASCII(b) AS ntext_ascii
FROM ascii_function_test_text;
GO

-- Test NULL and empty string handling
SELECT 
    ASCII(CAST(NULL AS IMAGE)) AS null_image,
    ASCII(CAST(NULL AS TEXT)) AS null_text,
    ASCII(CAST(NULL AS NTEXT)) AS null_ntext,
    ASCII(CAST('' AS TEXT)) AS empty_text,
    ASCII(CAST(N'' AS NTEXT)) AS empty_ntext;
GO

-- Test ASCII with UDTs
SELECT 
    ID,
    ASCII(char_col) as char_ascii,
    ASCII(varchar_col) as varchar_ascii,
    ASCII(nchar_col) as nchar_ascii,
    ASCII(nvarchar_col) as nvarchar_ascii,
    ASCII(text_col) as text_ascii,
    ASCII(ntext_col) as ntext_ascii,
    ASCII(binary_col) as binary_ascii,
    ASCII(varbinary_col) as varbinary_ascii
FROM ascii_function_UDT_test;
GO

-- Test ASCII with numeric UDTs
SELECT 
    ID,
    ASCII(CAST(bigint_col AS VARCHAR)) as bigint_ascii,
    ASCII(CAST(int_col AS VARCHAR)) as int_ascii,
    ASCII(CAST(smallint_col AS VARCHAR)) as smallint_ascii,
    ASCII(CAST(tinyint_col AS VARCHAR)) as tinyint_ascii,
    ASCII(CAST(decimal_col AS VARCHAR)) as decimal_ascii,
    ASCII(CAST(numeric_col AS VARCHAR)) as numeric_ascii,
    ASCII(CAST(float_col AS VARCHAR)) as float_ascii,
    ASCII(CAST(real_col AS VARCHAR)) as real_ascii
FROM ascii_function_UDT_test;
GO

-- Test ASCII with datetime UDTs --> will give incorrect results in babelfish [BABEL-1664]
SELECT 
    ID,
    ASCII(CAST(datetime_col AS VARCHAR)) as datetime_ascii,
    ASCII(CAST(smalldatetime_col AS VARCHAR)) as smalldatetime_ascii,
    ASCII(CAST(date_col AS VARCHAR)) as date_ascii,
    ASCII(CAST(time_col AS VARCHAR)) as time_ascii,
    ASCII(CAST(datetime2_col AS VARCHAR)) as datetime2_ascii,
    ASCII(CAST(datetimeoffset_col AS VARCHAR)) as datetimeoffset_ascii
FROM ascii_function_UDT_test;
GO

-- Test ASCII with money
SELECT 
    ID,
    ASCII(CAST(money_col AS VARCHAR)) as money_ascii,
    ASCII(CAST(smallmoney_col AS VARCHAR)) as smallmoney_ascii
FROM ascii_function_UDT_test;
GO

SELECT ASCII(CAST('A' AS dbo.ascii_function_charUDT)) AS char_udt,
       ASCII(CAST(123 AS dbo.ascii_function_intUDT)) AS int_udt,
       ASCII(CAST(0x41 AS dbo.ascii_function_binaryUDT)) AS binary_udt;
GO

SELECT 'Testing NULL with UDTs' AS TestType;
SELECT ASCII(CAST(NULL AS dbo.ascii_function_charUDT)) AS null_char_udt,
       ASCII(CAST(NULL AS dbo.ascii_function_binaryUDT)) AS null_binary_udt;
GO

-- Test ASCII with special types
SELECT ASCII(a) as image_ascii FROM ascii_function_image;
GO

SELECT ASCII(a) as text_ascii, ASCII(b) as ntext_ascii FROM ascii_function_text;
GO

-- Test ASCII with NULL values
SELECT 
    ASCII(CAST(NULL as dbo.ascii_function_charUDT)) as null_char,
    ASCII(CAST(NULL as dbo.ascii_function_varcharUDT)) as null_varchar,
    ASCII(CAST(NULL as dbo.ascii_function_ncharUDT)) as null_nchar,
    ASCII(CAST(NULL as dbo.ascii_function_nvarcharUDT)) as null_nvarchar;
GO

-- Test ASCII with empty strings
SELECT 
    ASCII(CAST('' as dbo.ascii_function_charUDT)) as empty_char,
    ASCII(CAST('' as dbo.ascii_function_varcharUDT)) as empty_varchar,
    ASCII(CAST(N'' as dbo.ascii_function_ncharUDT)) as empty_nchar,
    ASCII(CAST(N'' as dbo.ascii_function_nvarcharUDT)) as empty_nvarchar;
GO

SELECT ASCII(CAST(0x AS VARBINARY)) AS empty_varbinary,
       ASCII(CAST(0x AS BINARY(1))) AS empty_binary;
GO

SELECT ASCII(CAST('A' as dbo.ascii_function_charUDT)) as char_udt_direct;
GO

SELECT ASCII(CAST(123 as dbo.ascii_function_intUDT)) as int_udt_direct;
GO

SELECT ASCII(CAST(CAST('123' AS dbo.ascii_function_intUDT) AS VARCHAR)) as int_udt_to_varchar;
GO

SELECT ASCII(CAST(0x20 as dbo.ascii_function_binaryUDT)) as binary_udt_direct;
GO

SELECT ASCII(CAST('0X20' as TEXT)) as text_ascii;
GO

DECLARE @temp TABLE (col TEXT);
INSERT INTO @temp VALUES ('Hello World');
SELECT ASCII(col) AS text_variable_ascii FROM @temp;
GO

--dependent test for ascii(text) function
EXEC ascii_function_text_validator 'A', 65;
EXEC ascii_function_text_validator 'B', 66;
EXEC ascii_function_text_validator '', 0;
GO

SELECT * FROM ascii_function_text_analysis;
GO

SELECT * FROM ascii_function_analysis ORDER BY ID;
GO
