-- Verify linked server persists through upgrade
SELECT name, is_rpc_out_enabled FROM sys.servers WHERE name = 'bbf_server'
GO

-- Test OPENQUERY still works after upgrade
SELECT * FROM OPENQUERY(bbf_server, 'SELECT 123 AS test_value')
GO
