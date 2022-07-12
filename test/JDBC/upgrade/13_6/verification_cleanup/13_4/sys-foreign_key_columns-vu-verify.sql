USE db1_sys_foreign_key_columns;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_2_sys_foreign_key_columns');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2_sys_foreign_key_columns');
GO

USE master;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_2_sys_foreign_key_columns');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2_sys_foreign_key_columns');
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_4_sys_foreign_key_columns');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4_sys_foreign_key_columns');
GO

USE db1_sys_foreign_key_columns;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_4_sys_foreign_key_columns');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4_sys_foreign_key_columns');
GO

USE db1_sys_foreign_key_columns;
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

SELECT constraint_column_id, parent_column_id, referenced_column_id FROM sys.foreign_key_columns ORDER BY constraint_column_id, parent_column_id, referenced_column_id;
