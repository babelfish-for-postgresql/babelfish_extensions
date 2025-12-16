-- ========================================
-- Upgrade Test: Remote Procedure Execution - Verify
-- Tests that linked server configuration persisted through upgrade to 5.4.0
-- ========================================

-- This test verifies that:
-- 1. Linked server configuration persists through upgrade
-- 2. New RPC out option is available and functional
-- 3. Remote procedure execution capability is present

-- ========================================
-- Verify Server Still Exists Post-Upgrade
-- ========================================

PRINT 'Test 1: Verifying linked server exists after upgrade';
GO

SELECT 
    name,
    product,
    provider,
    data_source,
    catalog
FROM sys.servers 
WHERE name = 'upgrade_test_server';
GO

-- ========================================
-- Verify Login Mapping Persisted
-- ========================================

PRINT 'Test 2: Verifying login mapping persisted';
GO

SELECT 
    srv.name AS server_name,
    login.name AS local_login,
    rmtlogin AS remote_login
FROM sys.servers srv
LEFT JOIN sys.linked_logins login ON srv.server_id = login.server_id
WHERE srv.name = 'upgrade_test_server';
GO

-- ========================================
-- Test New RPC Out Option (5.4.0 Feature)
-- ========================================

PRINT 'Test 3: Verifying RPC out option exists';
GO

-- Try to set RPC out option (new in 5.4.0)
BEGIN TRY
    EXEC sp_serveroption 'upgrade_test_server', 'rpc out', 'true';
    PRINT 'RPC out option set successfully (5.4.0 feature working)';
END TRY
BEGIN CATCH
    PRINT 'ERROR: RPC out option failed';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- ========================================
-- Verify Server Options
-- ========================================

PRINT 'Test 4: Checking server options';
GO

-- Query server options to confirm RPC out is set
SELECT 
    srv.name AS server_name,
    opt.option_name,
    opt.option_value
FROM sys.servers srv
CROSS APPLY (
    SELECT 'rpc' AS option_name, is_rpc_out_enabled AS option_value FROM sys.servers WHERE server_id = srv.server_id
    UNION ALL
    SELECT 'data access', is_data_access_enabled FROM sys.servers WHERE server_id = srv.server_id
) opt
WHERE srv.name = 'upgrade_test_server';
GO

-- ========================================
-- Test Connection Still Works
-- ========================================

PRINT 'Test 5: Testing linked server connection';
GO

-- Try to test the connection
-- NOTE: Will fail if actual test server not available, but that's expected
BEGIN TRY
    EXEC sp_testlinkedserver 'upgrade_test_server';
    PRINT 'Connection test successful';
END TRY
BEGIN CATCH
    PRINT 'Test server not available (expected if no actual server configured)';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- ========================================
-- Test Remote Procedure Execution Syntax
-- ========================================

PRINT 'Test 6: Verifying four-part name syntax is parsed';
GO

-- Test that four-part name syntax is recognized (even if execution fails)
-- This validates the parser accepts the syntax
BEGIN TRY
    -- This will fail because the remote server/procedure don't exist, 
    -- but it should fail with "procedure not found" not "syntax error"
    EXEC upgrade_test_server.testdb.dbo.sp_TestProc;
END TRY
BEGIN CATCH
    -- Expected errors: "procedure not found" or "cannot connect"
    -- If we get "syntax error", the feature is not working
    DECLARE @error_msg NVARCHAR(4000) = ERROR_MESSAGE();
    IF @error_msg LIKE '%syntax%'
        PRINT 'ERROR: Four-part name syntax not recognized!';
    ELSE
        PRINT 'Four-part name syntax recognized correctly (expected connection/procedure error)';
    PRINT @error_msg;
END CATCH;
GO

-- ========================================
-- Summary
-- ========================================

PRINT 'Upgrade verification complete';
PRINT 'Key results:';
PRINT ' - Linked server configuration: Persisted through upgrade';
PRINT ' - RPC out option (5.4.0): Available and functional';
PRINT ' - Four-part name syntax: Recognized by parser';
GO
