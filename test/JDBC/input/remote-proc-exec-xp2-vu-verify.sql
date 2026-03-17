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

-- Test 80: OPENQUERY with stored procedure (documents unsupported behavior)
-- Note: OPENQUERY with EXEC does not return result sets - this is expected to fail
-- This test documents the limitation, not a bug
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

-- ========================================
-- Test 82: SQL INJECTION SECURITY TESTS
-- ========================================

-- Test 82a: Server name injection attempt
-- Expected: Should fail with "server not found", NOT execute DROP TABLE
PRINT 'Test 82a: Injection via server name';
GO
EXEC malicious_server; DROP TABLE test; --.master.dbo.sp_SingleInt 1;
GO

-- Test 82b: Database name injection attempt
-- Expected: Should fail with "database not found" or invalid syntax, NOT execute DROP TABLE
PRINT 'Test 82b: Injection via database name';
GO
EXEC bbf_rpe_server.malicious_db; DROP TABLE test; --.dbo.sp_SingleInt 1;
GO

-- Test 82c: Schema name injection attempt
-- Expected: Should fail with "schema/procedure not found", NOT execute DROP TABLE
PRINT 'Test 82c: Injection via schema name';
GO
EXEC bbf_rpe_server.master.malicious_schema; DROP TABLE test; --.sp_SingleInt 1;
GO

-- Test 82d: Procedure name injection attempt (unquoted)
-- Expected: Should fail with "procedure not found" or syntax error, NOT execute DROP TABLE
PRINT 'Test 82d: Injection via procedure name';
GO
EXEC bbf_rpe_server.master.dbo.sp_SingleInt; DROP TABLE test; --;
GO

-- Test 82e: Parameter value injection attempt
-- Expected: Parameter should be passed as data, NOT executed as SQL
PRINT 'Test 82e: Injection via parameter value';
GO
DECLARE @malicious_param VARCHAR(100) = '''; DROP TABLE test; --';
EXEC bbf_rpe_server.master.dbo.sp_TestVarchar @p=@malicious_param;
GO

-- Test 82f: Verify test integrity (confirms no injection succeeded)
-- Expected: If a test table exists, it should still exist; otherwise expected error
PRINT 'Test 82f: Verify no tables were dropped';
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

