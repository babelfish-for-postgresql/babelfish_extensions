DROP DATABASE IF EXISTS my_test_database;
GO

CREATE DATABASE my_test_database;
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.databases');
GO

SELECT name FROM sys.databases where name = 'my_test_database';
GO

DROP DATABASE IF EXISTS my_test_database;
GO
