USE key_column_usage_vu_prepare_db;
GO

SELECT * FROM information_schema.key_column_usage WHERE TABLE_NAME LIKE 'key_column_usage_vu_prepare%' ORDER BY table_name, ordinal_position;
GO

USE master;
GO

SELECT * FROM information_schema.key_column_usage WHERE TABLE_NAME LIKE 'key_column_usage_vu_prepare%' ORDER BY table_name, ordinal_position;
GO
