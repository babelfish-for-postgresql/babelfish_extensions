-- Basic call with no parameters
EXEC bbf_loopback.master.dbo.rpe_loopback_no_params;
GO

-- INT parameter with literal
EXEC bbf_loopback.master.dbo.rpe_loopback_int_param @x=42;
GO

-- INT parameter with variable
DECLARE @v INT = 100;
EXEC bbf_loopback.master.dbo.rpe_loopback_int_param @x=@v;
GO

-- Positional parameter
EXEC bbf_loopback.master.dbo.rpe_loopback_int_param 7;
GO

-- VARCHAR parameter
EXEC bbf_loopback.master.dbo.rpe_loopback_varchar_param @s='Hello World';
GO

-- Multiple parameters of different types
EXEC bbf_loopback.master.dbo.rpe_loopback_multi_params @a=10, @b='test', @c=9999999999;
GO

-- OUTPUT parameter
DECLARE @out INT;
EXEC bbf_loopback.master.dbo.rpe_loopback_output @input=5, @result=@out OUTPUT;
SELECT @out AS output_value;
GO

-- Multiple OUTPUT parameters
DECLARE @s INT;
DECLARE @p INT;
EXEC bbf_loopback.master.dbo.rpe_loopback_output_multi @x=3, @y=4, @sum=@s OUTPUT, @product=@p OUTPUT;
SELECT @s AS sum_val, @p AS product_val;
GO

-- Return code capture (positive)
DECLARE @rc INT;
EXEC @rc = bbf_loopback.master.dbo.rpe_loopback_return_code @val=10;
SELECT @rc AS return_code;
GO

-- Return code capture (negative)
DECLARE @rc INT;
EXEC @rc = bbf_loopback.master.dbo.rpe_loopback_return_code @val=-5;
SELECT @rc AS return_code;
GO

-- Return code capture (zero)
DECLARE @rc INT;
EXEC @rc = bbf_loopback.master.dbo.rpe_loopback_return_code @val=0;
SELECT @rc AS return_code;
GO

-- Four-part-name: omit database (server..schema.proc)
EXEC bbf_loopback..dbo.rpe_loopback_no_params;
GO

-- Four-part-name: omit schema (server.database..proc)
EXEC bbf_loopback.master..rpe_loopback_no_params;
GO

-- Four-part-name: omit both (server...proc)
EXEC bbf_loopback...rpe_loopback_no_params;
GO

-- Error: invalid procedure name
EXEC bbf_loopback.master.dbo.nonexistent_proc;
GO

-- Error: invalid server name
EXEC invalid_server_xyz.master.dbo.rpe_loopback_no_params;
GO

-- =============================================================================
-- Multi-result-set tests (E1)
-- Procs that emit multiple result sets must have EVERY set drained and shipped
-- to the client. If only the first set is consumed, the TDS tail bytes
-- (DONEPROC / return-status / OUTPUT-param payload) arrive after the
-- undrained COLMETADATA and the return code/OUTPUT params are corrupted.
-- =============================================================================

-- Two distinct result sets, no OUTPUT / no return status
EXEC bbf_loopback.master.dbo.rpe_loopback_multi_resultset;
GO

-- Multi-result-set + OUTPUT param + RETURN status round-trip
DECLARE @rc INT;
DECLARE @rows INT;
EXEC @rc = bbf_loopback.master.dbo.rpe_loopback_multi_resultset_with_output
         @seed = 10, @row_count = @rows OUTPUT;
SELECT @rc AS return_code, @rows AS row_count;
GO

-- Error: RPC out disabled
EXEC sp_serveroption 'bbf_loopback', 'rpc out', 'false';
GO

EXEC bbf_loopback.master.dbo.rpe_loopback_no_params;
GO

-- Re-enable RPC out
EXEC sp_serveroption 'bbf_loopback', 'rpc out', 'true';
GO

-- Verify works again after re-enable
EXEC bbf_loopback.master.dbo.rpe_loopback_no_params;
GO

-- =============================================================================
-- Errno preservation (Item 1)
-- The captured remote errno must surface through the caller's ERROR_NUMBER()
-- instead of the user-defined-error default of 50000.
-- Matches SQL Server's behavior: THROW 50001 surfaces 50001; engine errors
-- (3903 from a bare ROLLBACK boundary, etc.) surface their original errno.
-- =============================================================================

-- I1.A: THROW 50001 from remote proc → ERROR_NUMBER() must be 50001
BEGIN TRY
    EXEC bbf_loopback.master.dbo.rpe_loopback_throw50001;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS errno, ERROR_SEVERITY() AS severity, ERROR_STATE() AS state;
END CATCH;
GO

-- I1.B: BEGIN-no-COMMIT in remote proc → engine error 266 must surface
-- through ERROR_NUMBER() as 266 (not 50000). Same plumbing as I1.A/I1.C;
-- pinning here prevents silent regression of the engine-error path.
BEGIN TRY
    EXEC bbf_loopback.master.dbo.rpe_loopback_begin_no_commit;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS errno, ERROR_SEVERITY() AS severity, ERROR_STATE() AS state;
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- I1.C: bare ROLLBACK on remote with caller XACT_ABORT ON → ERROR_NUMBER()
-- must be 3903 (engine error). Requires ignore mode for the BEGIN TRAN path.
SELECT set_config('babelfishpg_tsql.escape_hatch_remote_proc_transaction', 'ignore', 'false');
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRAN;
    EXEC bbf_loopback.master.dbo.rpe_loopback_bare_rollback;
    COMMIT;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS errno, ERROR_SEVERITY() AS severity, ERROR_STATE() AS state;
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
SET XACT_ABORT OFF;
GO

-- Restore strict mode for the transaction-check assertion below.
SELECT set_config('babelfishpg_tsql.escape_hatch_remote_proc_transaction', 'strict', 'false');
GO

-- I5.A: No-TRY/CATCH default-customer pattern.
-- Most production T-SQL has no TRY/CATCH wrapper. Pin that a remote
-- RAISERROR sev 16 surfaces as an error AND the batch continues past the
-- EXEC, matching SQL Server's no-wrapper behavior. The "after exec"
-- marker MUST execute; if a future change aborts the batch at the
-- cross-server boundary on remote RAISERROR, this cell catches it.
EXEC bbf_loopback.master.dbo.rpe_loopback_raiserror;
SELECT 'after exec' AS marker;
GO

-- Transaction check: strict mode (default) should ERROR when called inside
-- a transaction. @@TRANCOUNT behavior after this error is NOT asserted here
-- because Babelfish does not create internal savepoints for EXEC-dispatch-level
-- errors (PLTSQL_STMT_EXEC → is_batch_command()=true in iterative_exec.c).
-- This causes the entire transaction to abort (@@TRANCOUNT→0), unlike errors
-- inside a proc body which are savepoint-protected. This is pre-existing
-- Babelfish behavior, not specific to remote proc exec.
-- Confirmed: BEGIN TRAN; EXEC nonexistent_proc; also yields @@TRANCOUNT=0.
BEGIN TRANSACTION;
EXEC bbf_loopback.master.dbo.rpe_loopback_no_params;
GO

IF @@TRANCOUNT > 0 ROLLBACK;
GO
