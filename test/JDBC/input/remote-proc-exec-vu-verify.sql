-- sla 60000
-- ========================================
-- SECTION 1: BASIC EXECUTION TESTS
-- ========================================

-- Test 1: Procedure with no parameters
-- Expected: Should execute successfully and return result set
EXEC bbf_rpe_server.master.dbo.sp_NoParams;
GO

-- Test 2: Procedure with single INT parameter
-- Expected: Should pass parameter correctly and return doubled value
EXEC bbf_rpe_server.master.dbo.sp_SingleInt @value=42;
GO

-- Test 3: Positional parameter (no name)
-- Expected: Should work with positional syntax
EXEC bbf_rpe_server.master.dbo.sp_SingleInt 99;
GO

-- ========================================
-- SECTION 2: NUMERIC DATA TYPES
-- ========================================

-- Test 4: Integer types with literals
-- Expected: All integer types should pass correctly
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=100, @p_bigint=999999, @p_smallint=500, @p_tinyint=255;
GO

-- Test 5: Integer types with variables
-- Expected: Should handle typed variables correctly
DECLARE @i INT = 2147483647;
DECLARE @bi BIGINT = 9223372036854775807;
DECLARE @si SMALLINT = 32767;
DECLARE @ti TINYINT = 255;
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=@i, @p_bigint=@bi, @p_smallint=@si, @p_tinyint=@ti;
GO

-- Test 6: FLOAT and REAL types
-- Expected: Should preserve floating point values
EXEC bbf_rpe_server.master.dbo.sp_TestFloat @p_float=3.14159265359, @p_real=2.71828;
GO

-- Test 7: FLOAT and REAL with variables
-- Expected: Should handle typed FLOAT/REAL variables
DECLARE @f FLOAT = 123.456;
DECLARE @r REAL = 78.90;
EXEC bbf_rpe_server.master.dbo.sp_TestFloat @p_float=@f, @p_real=@r;
GO

-- Test 8: DECIMAL and NUMERIC with literals
-- Expected: Should preserve precision and scale
EXEC bbf_rpe_server.master.dbo.sp_TestDecimal @p_decimal=1234.5678, @p_numeric=98.76;
GO

-- Test 9: DECIMAL with typed variable (regression test for OID issue)
-- Expected: Should correctly handle DECIMAL typed variables
DECLARE @d DECIMAL(18,4) = 9999.9999;
DECLARE @n NUMERIC(10,2) = 12345.67;
EXEC bbf_rpe_server.master.dbo.sp_TestDecimal @p_decimal=@d, @p_numeric=@n;
GO

-- Test 10: MONEY and SMALLMONEY types
-- Expected: Should handle money types correctly
EXEC bbf_rpe_server.master.dbo.sp_TestMoney @p_money=1234.5678, @p_smallmoney=99.99;
GO

-- Test 11: MONEY with variables
-- Expected: Should handle MONEY typed variables
DECLARE @m MONEY = 99999.9999;
DECLARE @sm SMALLMONEY = 214748.3647;
EXEC bbf_rpe_server.master.dbo.sp_TestMoney @p_money=@m, @p_smallmoney=@sm;
GO

-- ========================================
-- SECTION 3: STRING DATA TYPES
-- ========================================

-- Test 12: VARCHAR parameter
-- Expected: Should pass string correctly
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p='Hello World';
GO

-- Test 13: VARCHAR with variable
-- Expected: Should handle VARCHAR variable
DECLARE @str VARCHAR(100) = 'Testing VARCHAR parameter';
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p=@str;
GO

-- Test 14: NVARCHAR parameter
-- Expected: Should handle Unicode string
EXEC bbf_rpe_server.master.dbo.sp_TestNvarchar @p=N'Unicode Test String';
GO

-- Test 15: NVARCHAR with special characters
-- Expected: Should preserve special characters
DECLARE @nstr NVARCHAR(100) = N'Special: !@#$%^&*()_+-={}[]|:;<>?,./';
EXEC bbf_rpe_server.master.dbo.sp_TestNvarchar @p=@nstr;
GO

-- Test 16: CHAR and NCHAR types
-- Expected: Should handle fixed-length strings
EXEC bbf_rpe_server.master.dbo.sp_TestChar @p_char='CHAR', @p_nchar=N'NCHAR';
GO

-- Test 17: Empty string parameter
-- Expected: Should handle empty string
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p='';
GO

-- Test 18: NULL string parameter
-- Expected: Should handle NULL
EXEC bbf_rpe_server.master.dbo.sp_NullableParam @p=NULL;
GO

-- Test 19: Large string (>8000 characters)
-- Expected: Should handle large VARCHAR(MAX)
DECLARE @large_str VARCHAR(MAX) = REPLICATE('A', 10000);
EXEC bbf_rpe_server.master.dbo.sp_LargeString @p=@large_str;
GO

-- ========================================
-- SECTION 4: BINARY AND SPECIAL TYPES
-- ========================================

-- Test 20: BIT type with TRUE
-- Expected: Should pass BIT value correctly
EXEC bbf_rpe_server.master.dbo.sp_TestBit @p=1;
GO

-- Test 21: BIT type with FALSE
-- Expected: Should handle FALSE
EXEC bbf_rpe_server.master.dbo.sp_TestBit @p=0;
GO

-- Test 22: BIT with variable
-- Expected: Should handle BIT variable
DECLARE @b BIT = 1;
EXEC bbf_rpe_server.master.dbo.sp_TestBit @p=@b;
GO

-- Test 23: VARBINARY parameter
-- Expected: Should handle binary data
EXEC bbf_rpe_server.master.dbo.sp_TestBinary @p=0xDEADBEEF;
GO

-- Test 24: VARBINARY with variable
-- Expected: Should handle VARBINARY variable
DECLARE @bin VARBINARY(100) = 0x0123456789ABCDEF;
EXEC bbf_rpe_server.master.dbo.sp_TestBinary @p=@bin;
GO

-- Test 25: UNIQUEIDENTIFIER parameter
-- Expected: Should handle GUID correctly
EXEC bbf_rpe_server.master.dbo.sp_TestUUID @p='6F9619FF-8B86-D011-B42D-00C04FC964FF';
GO

-- Test 26: UNIQUEIDENTIFIER with variable
-- Expected: Should handle GUID variable
DECLARE @guid UNIQUEIDENTIFIER = '87654321-4321-4321-4321-CBA987654321';
EXEC bbf_rpe_server.master.dbo.sp_TestUUID @p=@guid;
GO

-- ========================================
-- SECTION 5: DATE/TIME DATA TYPES
-- ========================================

-- Test 27: DATE parameter
-- Expected: Should handle DATE correctly
EXEC bbf_rpe_server.master.dbo.sp_TestDate @p='2023-12-25';
GO

-- Test 28: DATE with variable
-- Expected: Should handle DATE variable
DECLARE @dt DATE = '2024-01-01';
EXEC bbf_rpe_server.master.dbo.sp_TestDate @p=@dt;
GO

-- Test 29: DATETIME and DATETIME2
-- Expected: Should handle both datetime types
EXEC bbf_rpe_server.master.dbo.sp_TestDateTime @p_datetime='2023-12-25 14:30:00', @p_datetime2='2023-12-25 14:30:00.1234567';
GO

-- Test 30: DATETIME with variables
-- Expected: Should handle datetime variables
DECLARE @dt1 DATETIME = '2024-06-15 09:30:45';
DECLARE @dt2 DATETIME2 = '2024-06-15 09:30:45.123';
EXEC bbf_rpe_server.master.dbo.sp_TestDateTime @p_datetime=@dt1, @p_datetime2=@dt2;
GO

-- Test 31: TIME parameter
-- Expected: Should handle TIME type
EXEC bbf_rpe_server.master.dbo.sp_TestTime @p='14:30:00';
GO

-- Test 32: TIME with variable
-- Expected: Should handle TIME variable
DECLARE @t TIME = '23:59:59';
EXEC bbf_rpe_server.master.dbo.sp_TestTime @p=@t;
GO

-- ========================================
-- SECTION 6: OUTPUT PARAMETERS
-- ========================================

-- Test 33: Single OUTPUT parameter
-- Expected: Output variable should receive doubled value (10)
DECLARE @out1 INT;
EXEC bbf_rpe_server.master.dbo.sp_OutputSingle @input=5, @output=@out1 OUTPUT;
SELECT @out1 AS output_value;
GO

-- Test 34: Multiple OUTPUT parameters
-- Expected: Should receive both sum (7) and product (12)
DECLARE @sum INT;
DECLARE @prod INT;
EXEC bbf_rpe_server.master.dbo.sp_OutputMultiple @a=3, @b=4, @sum=@sum OUTPUT, @product=@prod OUTPUT;
SELECT @sum AS sum_value, @prod AS product_value;
GO

-- Test 35: OUTPUT parameter with no result set
-- Expected: Should set output even without SELECT
DECLARE @result INT;
EXEC bbf_rpe_server.master.dbo.sp_OutputNoResult @input=50, @output=@result OUTPUT;
SELECT @result AS output_value;
GO

-- Test 36: INOUT parameter (bidirectional)
-- Expected: Input 42, should return 142 (42+100)
DECLARE @counter INT = 42;
EXEC bbf_rpe_server.master.dbo.sp_InOut @counter=@counter OUTPUT;
SELECT @counter AS inout_value;
GO

-- Test 37: OUTPUT parameter not specified (should be IN only)
-- Expected: Should execute but not return OUTPUT value
DECLARE @out2 INT = -999;
EXEC bbf_rpe_server.master.dbo.sp_OutputSingle @input=10, @output=@out2;
SELECT @out2 AS still_unchanged;
GO

-- ========================================
-- SECTION 7: RESULT SET HANDLING
-- ========================================

-- Test 38: Multi-row result set (5 rows)
-- Expected: Should return all 5 rows
EXEC bbf_rpe_server.master.dbo.sp_MultiRow;
GO

-- Test 39: Mixed column types in result
-- Expected: Should handle different types in same result set
EXEC bbf_rpe_server.master.dbo.sp_MixedTypes;
GO

-- Test 40: Empty result set
-- Expected: Should return 0 rows but proper column structure
EXEC bbf_rpe_server.master.dbo.sp_EmptyResult;
GO

-- Test 41: Result set with NULL values
-- Expected: Should preserve NULLs in columns
EXEC bbf_rpe_server.master.dbo.sp_NullValues;
GO

-- Test 42: Conditional logic - mode 1
-- Expected: Should execute IF branch
EXEC bbf_rpe_server.master.dbo.sp_ConditionalLogic @mode=1;
GO

-- Test 43: Conditional logic - mode 2
-- Expected: Should execute ELSE IF branch
EXEC bbf_rpe_server.master.dbo.sp_ConditionalLogic @mode=2;
GO

-- Test 44: Conditional logic - default
-- Expected: Should execute ELSE branch
EXEC bbf_rpe_server.master.dbo.sp_ConditionalLogic @mode=999;
GO

-- Test 45: Parameter-based filtering
-- Expected: Should return rows 5-10 only
EXEC bbf_rpe_server.master.dbo.sp_FilterByParam @min_val=5, @max_val=10;
GO

-- Test 46: Combined INPUT/OUTPUT with result set
-- Expected: Should return result set AND set output parameter
DECLARE @count INT;
EXEC bbf_rpe_server.master.dbo.sp_CombinedIO @multiplier=3, @row_count=@count OUTPUT;
SELECT @count AS returned_count;
GO

-- ========================================
-- SECTION 8: FOUR-PART NAME VARIATIONS
-- ========================================

-- Test 47: Full four-part name (server.database.schema.procedure)
-- Expected: Should execute successfully
EXEC bbf_rpe_server.master.dbo.sp_NoParams;
GO

-- Test 48: Three-part with database omitted (server..schema.procedure)
-- Expected: Should use current/default database
EXEC bbf_rpe_server..dbo.sp_NoParams;
GO

-- Test 49: Three-part with schema omitted (server.database..procedure)
-- Expected: Should use default schema (dbo)
EXEC bbf_rpe_server.master..sp_NoParams;
GO

-- Test 50: Two-part (server...procedure)
-- Expected: Should use defaults for database and schema
EXEC bbf_rpe_server...sp_NoParams;
GO

