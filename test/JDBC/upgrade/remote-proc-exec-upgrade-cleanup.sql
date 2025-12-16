-- ========================================
-- Upgrade Test: Remote Procedure Execution - Cleanup
-- Removes test linked server created for upgrade validation
-- ========================================

PRINT 'Starting upgrade test cleanup';
GO

-- ========================================
-- Remove Test Linked Server
-- ========================================

PRINT 'Removing test linked server';
GO

-- Drop the server (this also removes associated logins)
BEGIN TRY
    EXEC sp_dropserver 'upgrade_test_server', 'droplogins';
    PRINT 'Test linked server removed successfully';
END TRY
BEGIN CATCH
    PRINT 'Warning: Could not remove test server';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- ========================================
-- Verify Cleanup Complete
-- ========================================

PRINT 'Verifying cleanup';
GO

-- Check that server no longer exists
SELECT COUNT(*) AS remaining_test_servers
FROM sys.servers 
WHERE name = 'upgrade_test_server';
GO

PRINT 'Upgrade test cleanup complete';
GO
