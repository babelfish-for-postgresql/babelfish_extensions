-- ========================================
-- Upgrade Test: Remote Procedure Execution
-- Tests upgrade from 5.3.0 to 5.4.0
-- ========================================

-- This test verifies that:
-- 1. Linked servers can be created before upgrade
-- 2. Configuration persists through upgrade
-- 3. RPC out option is properly handled

-- ========================================
-- Create Test Linked Server
-- ========================================

PRINT 'Creating test linked server for upgrade validation';
GO

EXEC sp_addlinkedserver 
    @server = 'upgrade_test_server',
    @srvproduct = '',
    @provider = 'SQLNCLI',
    @datasrc = 'test-server.example.com',
    @catalog = 'testdb';
GO

PRINT 'Adding login mapping for test server';
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'upgrade_test_server',
    @useself = 'FALSE',
    @rmtuser = 'testuser',
    @rmtpassword = 'testpass';
GO

-- ========================================
-- Verify Server Exists Pre-Upgrade
-- ========================================

PRINT 'Verifying linked server configuration';
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
-- Test Connection (if server available)
-- ========================================

-- NOTE: This will fail if test server is not available,
-- but that's expected. The key is that the server
-- definition persists through upgrade.

PRINT 'Attempting to test linked server connection';
GO

-- Wrapped in BEGIN TRY to handle unavailable test server gracefully
BEGIN TRY
    EXEC sp_testlinkedserver 'upgrade_test_server';
    PRINT 'Test server connection successful';
END TRY
BEGIN CATCH
    PRINT 'Test server not available (expected if no actual server configured)';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT 'Upgrade prepare complete - server configuration saved';
GO
