-- Cleanup script for datetime storage rounding version upgrade tests

SELECT 'CLEANUP PHASE - Removing test objects' as cleanup_phase;
GO

-- Drop triggers first (to avoid dependency issues)
IF OBJECT_ID('tr_datetime_storage_test_audit', 'TR') IS NOT NULL
    DROP TRIGGER tr_datetime_storage_test_audit;
GO

-- Drop views
IF OBJECT_ID('datetime_view', 'V') IS NOT NULL
    DROP VIEW datetime_view;
GO

-- Drop functions
IF OBJECT_ID('get_rounded_datetime', 'FN') IS NOT NULL
    DROP FUNCTION get_rounded_datetime;
GO

-- Drop stored procedures
IF OBJECT_ID('test_datetime_parameter', 'P') IS NOT NULL
    DROP PROCEDURE test_datetime_parameter;
GO

-- Drop tables (in reverse dependency order)
IF OBJECT_ID('datetime_audit_log', 'U') IS NOT NULL
    DROP TABLE datetime_audit_log;
GO

IF OBJECT_ID('datetime_index_test', 'U') IS NOT NULL
    DROP TABLE datetime_index_test;
GO

IF OBJECT_ID('datetime_aggregation_test', 'U') IS NOT NULL
    DROP TABLE datetime_aggregation_test;
GO

IF OBJECT_ID('datetime_comparison_test', 'U') IS NOT NULL
    DROP TABLE datetime_comparison_test;
GO

IF OBJECT_ID('datetime_storage_test', 'U') IS NOT NULL
    DROP TABLE datetime_storage_test;
GO

SELECT 'CLEANUP COMPLETE - All test objects removed' as cleanup_status;
GO

-- BASIC UPGRADE TESTING
DROP TABLE dbo.datetime_test;
GO
