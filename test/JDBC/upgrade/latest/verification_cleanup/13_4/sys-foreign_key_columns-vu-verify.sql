USE sys_foreign_key_columns_vu_prepare_db;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk2');
GO

USE master;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk2');
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk4');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk4');
GO

USE sys_foreign_key_columns_vu_prepare_db;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk4');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_foreign_key_columns_vu_prepare_fk4');
GO

USE sys_foreign_key_columns_vu_prepare_db;
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
