USE key_column_usage_vu_prepare_db;
GO

SELECT * FROM information_schema.key_column_usage WHERE TABLE_NAME LIKE 'key_column_usage_vu_prepare%' ORDER BY constraint_name, column_name;
GO

SELECT * FROM key_column_usage_vu_prepare_v1;
GO

EXECUTE key_column_usage_vu_prepare_p1;
GO

USE master;
GO

SELECT * FROM information_schema.key_column_usage WHERE TABLE_NAME LIKE 'key_column_usage_vu_prepare%' ORDER BY constraint_name, column_name;
GO

