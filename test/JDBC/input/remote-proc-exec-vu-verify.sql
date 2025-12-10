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

-- ========================================
-- SECTION 9: ERROR AND NEGATIVE TESTS
-- ========================================

-- Test 51: Invalid server name
-- Expected: Should throw error - server not found
EXEC invalid_server.master.dbo.sp_NoParams;
GO

-- Test 52: Invalid database name
-- Expected: Should throw error - database not found
EXEC bbf_rpe_server.invalid_db.dbo.sp_NoParams;
GO

-- Test 53: Invalid schema name
-- Expected: Should throw error - schema not found
EXEC bbf_rpe_server.master.invalid_schema.sp_NoParams;
GO

-- Test 54: Invalid procedure name
-- Expected: Should throw error - procedure not found
EXEC bbf_rpe_server.master.dbo.sp_NonExistent;
GO

-- Test 55: Procedure with INSERT statement (violates SELECT-only)
-- Expected: Should throw error - INSERT not allowed
EXEC bbf_rpe_server.master.dbo.sp_WithInsert;
GO

-- Test 56: Procedure with UPDATE statement (violates SELECT-only)
-- Expected: Should throw error - UPDATE not allowed
EXEC bbf_rpe_server.master.dbo.sp_WithUpdate;
GO

-- Test 57: Procedure with DELETE statement (violates SELECT-only)
-- Expected: Should throw error - DELETE not allowed
EXEC bbf_rpe_server.master.dbo.sp_WithDelete;
GO

-- Test 58: Procedure with dynamic SQL (violates SELECT-only)
-- Expected: Should throw error - dynamic SQL not allowed
EXEC bbf_rpe_server.master.dbo.sp_WithDynamicSQL;
GO

-- Test 59: RPC out disabled test setup
-- Temporarily disable RPC out
EXEC sp_serveroption 'bbf_rpe_server', 'rpc out', 'false';
GO

-- Test 60: Execute with RPC out disabled
-- Expected: Should throw error with hint to enable RPC out
EXEC bbf_rpe_server.master.dbo.sp_NoParams;
GO

-- Test 61: Re-enable RPC out for remaining tests
EXEC sp_serveroption 'bbf_rpe_server', 'rpc out', 'true';
GO

-- ========================================
-- SECTION 10: PARAMETER VARIATIONS
-- ========================================

-- Test 62: Named parameters in different order
-- Expected: Should match by name, not position
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_tinyint=10, @p_int=100, @p_smallint=20, @p_bigint=1000;
GO

-- Test 63: Mixed positional and named parameters
-- Expected: Positional must come first
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers 1000, 2000, @p_smallint=30, @p_tinyint=40;
GO

-- Test 64: NULL parameter value
-- Expected: Should pass NULL to procedure
DECLARE @null_var VARCHAR(50) = NULL;
EXEC bbf_rpe_server.master.dbo.sp_NullableParam @p=@null_var;
GO

-- Test 65: Zero values
-- Expected: Should distinguish zero from NULL
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=0, @p_bigint=0, @p_smallint=0, @p_tinyint=0;
GO

-- Test 66: Negative numbers
-- Expected: Should handle negative values
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=-100, @p_bigint=-999999, @p_smallint=-500, @p_tinyint=0;
GO

-- ========================================
-- SECTION 11: RETURN CODE HANDLING
-- ========================================

-- Test 67: Procedure with RETURN code (positive)
-- Expected: Should capture return code = 1
DECLARE @ret INT;
EXEC @ret = bbf_rpe_server.master.dbo.sp_ReturnCode @value=10;
SELECT @ret AS return_code;
GO

-- Test 68: Procedure with RETURN code (negative)
-- Expected: Should capture return code = -1
DECLARE @ret2 INT;
EXEC @ret2 = bbf_rpe_server.master.dbo.sp_ReturnCode @value=-10;
SELECT @ret2 AS return_code;
GO

-- Test 69: Procedure with RETURN code (zero)
-- Expected: Should capture return code = 0
DECLARE @ret3 INT;
EXEC @ret3 = bbf_rpe_server.master.dbo.sp_ReturnCode @value=0;
SELECT @ret3 AS return_code;
GO

-- ========================================
-- SECTION 12: ERROR HANDLING
-- ========================================

-- Test 70: Procedure that succeeds
-- Expected: Should return success message
EXEC bbf_rpe_server.master.dbo.sp_WithError @should_error=0;
GO

-- Test 71: Procedure that raises error
-- Expected: Should propagate error to caller
EXEC bbf_rpe_server.master.dbo.sp_WithError @should_error=1;
GO

-- ========================================
-- SECTION 13: EDGE CASES
-- ========================================

-- Test 72: Very small numbers
-- Expected: Should handle smallest values
DECLARE @tiny_int TINYINT = 0;
DECLARE @small_int SMALLINT = -32768;
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=1, @p_bigint=1, @p_smallint=@small_int, @p_tinyint=@tiny_int;
GO

-- Test 73: Very large numbers
-- Expected: Should handle maximum values
DECLARE @max_int INT = 2147483647;
DECLARE @max_bigint BIGINT = 9223372036854775807;
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=@max_int, @p_bigint=@max_bigint, @p_smallint=32767, @p_tinyint=255;
GO

-- Test 74: Precision boundary for DECIMAL
-- Expected: Should handle maximum precision
DECLARE @max_decimal DECIMAL(18,4) = 99999999999999.9999;
EXEC bbf_rpe_server.master.dbo.sp_TestDecimal @p_decimal=@max_decimal, @p_numeric=99999999.99;
GO

-- Test 75: String with only spaces
-- Expected: Should preserve spaces
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p='     ';
GO

-- Test 76: String with quotes inside
-- Expected: Should handle escaped quotes
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p='It''s a test';
GO

-- Test 77: NVARCHAR with Unicode characters (if supported)
-- Expected: Should preserve Unicode
DECLARE @unicode NVARCHAR(100) = N'Hello 世界 مرحبا';
EXEC bbf_rpe_server.master.dbo.sp_TestNvarchar @p=@unicode;
GO

-- ========================================
-- SECTION 14: COMPLEX SCENARIOS
-- ========================================

-- Test 78: OUTPUT with conditional logic
-- Expected: Should set different output based on input
DECLARE @cond_out INT;
EXEC bbf_rpe_server.master.dbo.sp_OutputSingle @input=100, @output=@cond_out OUTPUT;
SELECT @cond_out AS conditional_output;
GO

-- Test 79: Multiple sequential remote calls
-- Expected: Each should execute independently
EXEC bbf_rpe_server.master.dbo.sp_SingleInt @value=1;
EXEC bbf_rpe_server.master.dbo.sp_SingleInt @value=2;
EXEC bbf_rpe_server.master.dbo.sp_SingleInt @value=3;
GO

-- Test 80: Remote procedure in variable assignment
-- Expected: Should be able to use result in variable
DECLARE @val INT;
SELECT @val = (SELECT TOP 1 number FROM OPENQUERY(bbf_rpe_server, 'EXEC sp_NoParams'));
SELECT @val AS assigned_value;
GO

-- ========================================
-- SECTION 15: SECURITY VALIDATION
-- ========================================

-- Test 81: Verify SELECT-only procedure works
-- Expected: Should execute successfully
EXEC bbf_rpe_server.master.dbo.sp_OnlySelect;
GO

-- Test 82: SQL Injection attempt in procedure name (should fail safely)
-- Expected: Should throw error - procedure not found (not SQL injection)
EXEC bbf_rpe_server.master.dbo.[sp_NoParams'; DROP TABLE test; --];
GO

-- ========================================
-- SECTION 16: PARAMETER TYPE COERCION
-- ========================================

-- Test 83: INT literal to BIGINT parameter
-- Expected: Should implicitly convert
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=100, @p_bigint=200, @p_smallint=10, @p_tinyint=5;
GO

-- Test 84: SMALLINT variable to INT parameter
-- Expected: Should upcast successfully
DECLARE @small SMALLINT = 999;
EXEC bbf_rpe_server.master.dbo.sp_SingleInt @value=@small;
GO

-- Test 85: VARCHAR to NVARCHAR
-- Expected: Should convert string types
DECLARE @v VARCHAR(50) = 'ASCII String';
EXEC bbf_rpe_server.master.dbo.sp_TestNvarchar @p=@v;
GO

-- ========================================
-- SECTION 17: BOUNDARY CONDITIONS
-- ========================================

-- Test 86: Minimum and maximum VARCHAR lengths
-- Expected: Should handle 1-character and MAX strings
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p='X';
GO

-- Test 87: DECIMAL with zero
-- Expected: Should handle zero precisely
EXEC bbf_rpe_server.master.dbo.sp_TestDecimal @p_decimal=0.0000, @p_numeric=0.00;
GO

-- Test 88: DATETIME at epoch
-- Expected: Should handle minimum datetime
EXEC bbf_rpe_server.master.dbo.sp_TestDateTime @p_datetime='1753-01-01 00:00:00', @p_datetime2='0001-01-01 00:00:00';
GO

-- Test 89: Empty VARBINARY
-- Expected: Should handle zero-length binary
EXEC bbf_rpe_server.master.dbo.sp_TestBinary @p=0x;
GO

-- ========================================
-- SECTION 18: NAMED VS POSITIONAL PARAMETERS
-- ========================================

-- Test 90: All positional parameters
-- Expected: Should match by position
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers 10, 20, 30, 40;
GO

-- Test 91: All named parameters
-- Expected: Should match by name
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=100, @p_bigint=200, @p_smallint=50, @p_tinyint=25;
GO

-- Test 92: Named parameters in reverse order
-- Expected: Should match by name, not position
EXEC bbf_rpe_server.master.dbo.sp_OutputMultiple @product=0, @sum=0, @b=7, @a=3;
GO

-- ========================================
-- SECTION 19: SPECIAL CHARACTERS & ENCODING
-- ========================================

-- Test 93: String with newlines
-- Expected: Should preserve newlines
DECLARE @multiline VARCHAR(100) = 'Line1
Line2
Line3';
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p=@multiline;
GO

-- Test 94: String with tabs
-- Expected: Should preserve tabs
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p='Col1	Col2	Col3';
GO

-- Test 95: NVARCHAR with emoji/symbols (if supported)
-- Expected: Should preserve Unicode symbols
EXEC bbf_rpe_server.master.dbo.sp_TestNvarchar @p=N'Test ★ ♥ ✓ ⚡';
GO

-- ========================================
-- SECTION 20: TRANSACTION BEHAVIOR
-- ========================================

-- Test 96: Remote procedure call within transaction
-- Expected: Should execute within transaction context
BEGIN TRANSACTION;
EXEC bbf_rpe_server.master.dbo.sp_SingleInt @value=123;
COMMIT;
GO

-- Test 97: Rollback after remote call
-- Expected: Local transaction should rollback (remote already committed)
BEGIN TRANSACTION;
EXEC bbf_rpe_server.master.dbo.sp_SingleInt @value=456;
ROLLBACK;
GO

-- ========================================
-- SECTION 21: STRESS & PERFORMANCE
-- ========================================

-- Test 98: Large result set with filtering
-- Expected: Should handle many rows efficiently
EXEC bbf_rpe_server.master.dbo.sp_FilterByParam @min_val=1, @max_val=20;
GO

-- Test 99: Multiple OUTPUT parameters with computation
-- Expected: Should handle complex calculations
DECLARE @s INT, @p INT;
EXEC bbf_rpe_server.master.dbo.sp_OutputMultiple @a=999, @b=888, @sum=@s OUTPUT, @product=@p OUTPUT;
SELECT @s AS sum_val, @p AS product_val;
GO

-- Test 100: Remote call with all data types combined
-- Expected: Comprehensive type handling
DECLARE @int_param INT = 42;
DECLARE @bigint_param BIGINT = 9999;
DECLARE @small_param SMALLINT = 100;
DECLARE @tiny_param TINYINT = 10;
EXEC bbf_rpe_server.master.dbo.sp_TestIntegers @p_int=@int_param, @p_bigint=@bigint_param, @p_smallint=@small_param, @p_tinyint=@tiny_param;
GO
