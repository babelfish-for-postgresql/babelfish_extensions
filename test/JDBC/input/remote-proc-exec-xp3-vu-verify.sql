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

-- Test 92: Named parameters in reverse order with OUTPUT
-- Expected: Should match by name, not position (sum=10, product=21)
DECLARE @sum92 INT, @product92 INT;
EXEC bbf_rpe_server.master.dbo.sp_OutputMultiple @a=3, @b=7, @sum=@sum92 OUTPUT, @product=@product92 OUTPUT;
SELECT @sum92 AS sum_value, @product92 AS product_value;
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

-- ========================================
-- SECTION 22: NESTED PROCEDURE VALIDATION
-- Tests for recursive SELECT-only validation
-- Streamlined to essential coverage while staying within connection limits
-- ========================================

-- Test 101: Nested procedure - both SELECT-only (should PASS)
-- Expected: Should execute successfully, returning results from outer and inner
PRINT 'Test 101: Nested SELECT-only procedures - should pass';
GO
EXEC bbf_rpe_server.master.dbo.sp_Outer_CallsSelectOnly;
GO

-- Test 102: Nested procedure - outer SELECT, inner INSERT (should FAIL)
-- Expected: Should fail with error about INSERT in nested procedure
PRINT 'Test 102: Outer calls inner with INSERT - should fail';
GO
EXEC bbf_rpe_server.master.dbo.sp_Outer_CallsInsert;
GO

-- Test 103: Two-level nesting - all SELECT-only (should PASS)
-- Expected: Should execute both levels successfully
PRINT 'Test 103: Two-level nesting all SELECT - should pass';
GO
EXEC bbf_rpe_server.master.dbo.sp_Level1_DeepNesting;
GO

-- Test 104: Two-level nesting - DML at level 2 (should FAIL)
-- Expected: Should fail - INSERT found at level 2
PRINT 'Test 104: Two-level nesting with DML at level 2 - should fail';
GO
EXEC bbf_rpe_server.master.dbo.sp_Level1_DeepWithDML;
GO

-- Test 105: Circular reference detection (A calls B, B calls A)
-- Expected: Should fail with circular reference error
PRINT 'Test 105: Circular reference A->B->A - should fail';
GO
EXEC bbf_rpe_server.master.dbo.sp_CircularA;
GO

-- Test 106: Multiple inner procedure calls (all SELECT-only)
-- Expected: Should pass - calling same inner proc multiple times
PRINT 'Test 106: Multiple inner procedure calls - should pass';
GO
EXEC bbf_rpe_server.master.dbo.sp_Outer_MultipleInner;
GO

-- Test 107: Outer procedure with dynamic SQL (sp_executesql)
-- Expected: Should fail - dynamic SQL blocked
PRINT 'Test 107: Outer with dynamic SQL - should fail';
GO
EXEC bbf_rpe_server.master.dbo.sp_Outer_WithDynamicSQL;
GO

-- Test 108: Nested procedure with UPDATE in inner (should FAIL)
-- Expected: Should fail with error about UPDATE in nested procedure
PRINT 'Test 108: Outer calls inner with UPDATE - should fail';
GO
EXEC bbf_rpe_server.master.dbo.sp_Outer_CallsUpdate;
GO

-- Test 109: Nested procedure with DELETE in inner (should FAIL)
-- Expected: Should fail with error about DELETE in nested procedure
PRINT 'Test 109: Outer calls inner with DELETE - should fail';
GO
EXEC bbf_rpe_server.master.dbo.sp_Outer_CallsDelete;
GO

-- ========================================
-- SECTION 23: ERROR MESSAGE COMPATIBILITY
-- Tests that validate SQL Server error code compatibility
-- when errors occur during remote procedure execution.
-- These cover the error scenarios from the RPC error comparison suite.
-- ========================================

-- Test 110: Missing required parameter
-- Expected: Should return error 201 (missing parameter)
EXEC bbf_rpe_server.master.dbo.sp_err_SingleInt;
GO

-- Test 111: Wrong parameter name
-- Expected: Should return error 201 (missing parameter - @value not supplied)
EXEC bbf_rpe_server.master.dbo.sp_err_SingleInt @wrong_name=42;
GO

-- Test 112: Too many parameters
-- Expected: Should return error 8144 (too many arguments)
EXEC bbf_rpe_server.master.dbo.sp_err_SingleInt @value=42, @extra=99;
GO

-- Test 113: Wrong type - string to int (implicit conversion failure)
-- Expected: Should return error 245 (conversion failed) - validates 22P02 error mapping fix
EXEC bbf_rpe_server.master.dbo.sp_err_SingleInt @value='not_a_number';
GO

-- Test 114: NULL for INT parameter (should work - NULL is valid for INT)
-- Expected: Should succeed and return NULL
EXEC bbf_rpe_server.master.dbo.sp_err_SingleInt @value=NULL;
GO

-- Test 115: Missing one of two required parameters
-- Expected: Should return error 201 (missing parameter @b)
EXEC bbf_rpe_server.master.dbo.sp_err_TwoParams @a=10;
GO

-- Test 116: RAISERROR severity 16 (standard user error)
-- Expected: Should propagate error 50000 at severity 16
EXEC bbf_rpe_server.master.dbo.sp_err_Raiserror16;
GO

-- Test 117: RAISERROR severity 11 (lowest error severity)
-- Expected: Should propagate error 50000 at severity 11
EXEC bbf_rpe_server.master.dbo.sp_err_Raiserror11;
GO

-- Test 118: RAISERROR severity 10 (informational - should NOT error)
-- Expected: Execution should continue, return result set
EXEC bbf_rpe_server.master.dbo.sp_err_Raiserror10;
GO

-- Test 119: RAISERROR custom message
-- Expected: Should propagate error 50000 with custom message text
EXEC bbf_rpe_server.master.dbo.sp_err_RaiserrorCustomMsg;
GO

-- Test 120: Division by zero
-- Expected: Babelfish raises error 8134; SQL Server returns NULL with ANSI_WARNINGS OFF
-- Note: Known Babelfish limitation - ANSI_WARNINGS OFF is not supported
EXEC bbf_rpe_server.master.dbo.sp_err_DivByZero;
GO

-- Test 121: Arithmetic overflow (INT max + 1)
-- Expected: Babelfish raises error 8115; SQL Server returns NULL with ANSI_WARNINGS OFF
-- Note: Known Babelfish limitation - ANSI_WARNINGS OFF is not supported
EXEC bbf_rpe_server.master.dbo.sp_err_Overflow;
GO

-- Test 122: Conversion error (CAST string to INT)
-- Expected: Should return error 245 (conversion failed) - validates 22P02 error mapping fix
EXEC bbf_rpe_server.master.dbo.sp_err_ConversionError;
GO

-- Test 123: String truncation (long string to VARCHAR(5))
-- Expected: Should truncate to 5 characters
EXEC bbf_rpe_server.master.dbo.sp_err_StringTruncation;
GO

-- Test 124: NULL arithmetic (should return NULL, not error)
-- Expected: Should succeed and return NULL with ISNULL fallback
EXEC bbf_rpe_server.master.dbo.sp_err_NullDeref;
GO

-- Test 125: Outer calls inner that raises error
-- Expected: Should propagate error 50000 from inner procedure
EXEC bbf_rpe_server.master.dbo.sp_err_NestedError;
GO

-- Test 126: Procedure returns data THEN raises error
-- Expected: Should propagate error 50000 after partial result
EXEC bbf_rpe_server.master.dbo.sp_err_ReturnAfterError;
GO

-- Test 127: TRY/CATCH with re-raised error
-- Expected: Babelfish leaks the re-raised error (known limitation)
-- SQL Server TRY/CATCH swallows the error completely
EXEC bbf_rpe_server.master.dbo.sp_err_MultipleErrors;
GO

-- Test 128: PRINT followed by error
-- Expected: Should propagate error 50000
EXEC bbf_rpe_server.master.dbo.sp_err_PrintAndError;
GO

-- Test 129: PRINT only (no error, no result set)
-- Expected: Should complete without error
EXEC bbf_rpe_server.master.dbo.sp_err_PrintOnly;
GO
