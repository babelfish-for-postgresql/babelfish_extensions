SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.databases');
GO

SELECT name FROM sys.databases where name = 'sys_databases_test_db';
GO
