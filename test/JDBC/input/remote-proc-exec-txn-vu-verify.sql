-- ========================================
-- Transaction Behavior and Error Handling Tests
-- for Remote Procedure Execution (PR #4292)
-- ========================================
-- These tests validate:
--   1. Transaction isolation (remote calls don't participate in local txns)
--   2. Error propagation from remote procedures
--   3. Transaction + error interaction
--   4. RPC out configuration interaction
--   5. Implicit transaction mode
--   6. Edge cases
--
-- NOTE: Remote procedure errors use ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION
-- which is unmapped in Babelfish error mapping. This means errors bypass
-- T-SQL TRY/CATCH (pre-existing linked server behavior, not specific to RPC).
-- Error tests verify the error IS raised with correct message content.

-- ========================================
-- SECTION 1: TRANSACTION ISOLATION
-- Remote calls execute over independent TDS connections.
-- Local ROLLBACK cannot undo remote procedure execution.
-- ========================================

-- Test 1.1: Remote call within explicit transaction — COMMIT
-- Both local rows committed, remote call executes independently
CREATE TABLE #local_txn_commit (id INT, val VARCHAR(50));
BEGIN TRANSACTION;
    INSERT INTO #local_txn_commit VALUES (1, 'before_remote');
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
    INSERT INTO #local_txn_commit VALUES (2, 'after_remote');
COMMIT;
SELECT * FROM #local_txn_commit ORDER BY id;
DROP TABLE #local_txn_commit;
GO

-- Test 1.2: Remote call within explicit transaction — ROLLBACK
-- Local rows rolled back, remote call already executed over separate connection
CREATE TABLE #local_txn_rollback (id INT, val VARCHAR(50));
BEGIN TRANSACTION;
    INSERT INTO #local_txn_rollback VALUES (1, 'before_remote');
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
    INSERT INTO #local_txn_rollback VALUES (2, 'after_remote');
ROLLBACK;
SELECT COUNT(*) AS cnt FROM #local_txn_rollback;
DROP TABLE #local_txn_rollback;
GO

-- Test 1.3: Return value capture survives ROLLBACK
-- Variable lives in PLtsql estate, not affected by transaction rollback
DECLARE @ret INT;
BEGIN TRANSACTION;
    EXEC @ret = bbf_rpe_txn.master.dbo.rpe_txn_sp_ReturnCode @value=5;
ROLLBACK;
SELECT @ret AS return_after_rollback;
GO

-- Test 1.4: OUTPUT parameter capture survives ROLLBACK
DECLARE @out INT;
BEGIN TRANSACTION;
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_OutputSingle @input=25, @output=@out OUTPUT;
ROLLBACK;
SELECT @out AS output_after_rollback;
GO

-- Test 1.5: Multiple remote calls in single transaction
-- All calls succeed independently (each opens separate TDS connection)
BEGIN TRANSACTION;
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_SingleInt @value=1;
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_SingleInt @value=2;
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_SingleInt @value=3;
COMMIT;
GO

-- Test 1.6: SAVE TRANSACTION (savepoints) with remote calls
-- Rows 1 and 3 committed; row 2 rolled back; remote call unaffected
CREATE TABLE #savepoint_test (id INT);
BEGIN TRANSACTION;
    SAVE TRANSACTION sp1;
    INSERT INTO #savepoint_test VALUES (1);
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
    SAVE TRANSACTION sp2;
    INSERT INTO #savepoint_test VALUES (2);
    ROLLBACK TRANSACTION sp2;
    INSERT INTO #savepoint_test VALUES (3);
COMMIT;
SELECT * FROM #savepoint_test ORDER BY id;
DROP TABLE #savepoint_test;
GO

-- ========================================
-- SECTION 2: ERROR PROPAGATION
-- Remote errors surface as TDS client library errors.
-- Due to unmapped ERRCODE_FDW_UNABLE_TO_CREATE_EXECUTION,
-- errors propagate directly to the client (pre-existing behavior).
-- ========================================

-- Test 2.1: Nonexistent procedure — validation error
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_nonexistent_proc;
GO

-- Test 2.2: Remote RAISERROR (severity 16) — propagated as TDS error
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_Raiserror16;
GO

-- Test 2.3: Remote division by zero — runtime error propagated
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_DivByZero;
GO

-- Test 2.4: Remote conversion error — propagated
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_ConversionError;
GO

-- Test 2.5: SELECT-only validation failure — INSERT in procedure rejected
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_WithInsert;
GO

-- Test 2.6: Parameter type mismatch — remote server rejects invalid value
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_IntParam @id = 'not_a_number';
GO

-- Test 2.8: Connection recovery after error — next call gets fresh connection
-- Previous error should not corrupt connection state
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
GO

-- Test 2.9: Second recovery call after multiple errors
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_SingleInt @value=42;
GO

-- ========================================
-- SECTION 3: TRANSACTION + ERROR INTERACTION
-- When remote error occurs inside transaction, the batch aborts.
-- ========================================

-- Test 3.1: Error aborts the batch (transaction is rolled back)
-- The INSERT before the error and the error itself are in one batch.
CREATE TABLE #txn_error_test (id INT);
INSERT INTO #txn_error_test VALUES (1);
GO

-- This batch will fail — error from remote proc aborts the batch
BEGIN TRANSACTION;
    INSERT INTO #txn_error_test VALUES (2);
    EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_Raiserror16;
    INSERT INTO #txn_error_test VALUES (3);
COMMIT;
GO

-- Verify: transaction was rolled back (@@TRANCOUNT = 0) and only row 1 survives
SELECT @@TRANCOUNT AS txn_count_after_error;
SELECT * FROM #txn_error_test ORDER BY id;
DROP TABLE #txn_error_test;
GO

-- Test 3.2: Successful call followed by failed call — return code from first
DECLARE @ret1 INT = -999;
EXEC @ret1 = bbf_rpe_txn.master.dbo.rpe_txn_sp_ReturnCode @value=5;
SELECT @ret1 AS successful_return_code;
GO

-- Test 3.3: OUTPUT parameter from successful call persists
DECLARE @out1 INT = -999;
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_OutputSingle @input=5, @output=@out1 OUTPUT;
SELECT @out1 AS output_from_success;
GO

-- ========================================
-- SECTION 4: RPC OUT CONFIGURATION
-- sp_serveroption 'rpc out' must be enabled for remote proc execution.
-- ========================================

-- Test 4.1: RPC out disabled — error raised
EXEC sp_serveroption 'bbf_rpe_txn', 'rpc out', 'false';
GO
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
GO
-- Restore
EXEC sp_serveroption 'bbf_rpe_txn', 'rpc out', 'true';
GO

-- Test 4.2: RPC out re-enabled — call succeeds
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
GO

-- ========================================
-- SECTION 5: IMPLICIT TRANSACTIONS
-- ========================================

-- Test 5.1: Autocommit mode (default) — sequential calls
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
GO
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_SingleInt @value=42;
GO

-- Test 5.2: Implicit transactions ON
SET IMPLICIT_TRANSACTIONS ON;
GO
CREATE TABLE #impl_txn_test (id INT);
INSERT INTO #impl_txn_test VALUES (1);
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
COMMIT;
SELECT * FROM #impl_txn_test;
DROP TABLE #impl_txn_test;
GO
SET IMPLICIT_TRANSACTIONS OFF;
GO

-- ========================================
-- SECTION 6: EDGE CASES
-- ========================================

-- Test 6.1: Nested error from inner procedure — propagated through outer
-- NOTE: The outer procedure does SELECT before calling inner proc that errors.
-- The partial result set from the SELECT is lost when the error aborts execution —
-- this is expected because linked_server_msg_handler throws ERROR (severity > 10)
-- which triggers PG error handling that discards any buffered/unsent results.
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NestedError;
GO

-- Test 6.2: Procedure that returns result then errors
-- Same behavior as 6.1: the SELECT result before RAISERROR is lost.
-- The error handler aborts the entire RPC, discarding partial results.
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_ReturnAfterError;
GO

-- Test 6.3: PRINT-only procedure (no result set, no error)
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_PrintOnly;
GO

-- ========================================
-- SECTION 7: TRANSACTION CONTROL STATEMENT BLOCKING
-- Remote procedures containing BEGIN TRAN, COMMIT, ROLLBACK,
-- or SAVE TRAN are blocked by ANTLR SELECT-only validation.
-- ========================================

-- Test 7.1: Procedure with BEGIN TRAN — blocked
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_WithBeginTran;
GO

-- Test 7.2: Procedure with COMMIT TRANSACTION — blocked
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_WithCommit;
GO

-- Test 7.3: Procedure with ROLLBACK TRANSACTION — blocked
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_WithRollback;
GO

-- Test 7.4: Procedure with SAVE TRANSACTION — blocked
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_WithSaveTran;
GO

-- ========================================
-- SECTION 8: GUC FEATURE GATE
-- babelfishpg_tsql.enable_remote_proc_exec controls RPC execution.
-- This GUC is PGC_SUSET (superuser-only), so T-SQL users cannot change it.
-- Test verifies the permission restriction and that calls still work after
-- a failed set_config attempt (GUC remains unchanged).
-- ========================================

-- Test 8.1: Non-superuser cannot disable the GUC — permission denied
SELECT set_config('babelfishpg_tsql.enable_remote_proc_exec', 'false', false);
GO

-- Test 8.2: Remote call still works (GUC was not actually changed)
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_NoParams;
GO

-- Test 6.4: Final sanity check — normal operation after all error tests
DECLARE @final_out INT;
EXEC bbf_rpe_txn.master.dbo.rpe_txn_sp_OutputSingle @input=100, @output=@final_out OUTPUT;
SELECT @final_out AS final_output_value;
GO
