SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.indexes');
GO

-- should return 3, two rows for NONCLUSTERED indexes and one for HEAP on table
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_index_test1')
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'i_sys_index_test1%';
GO

SELECT type, type_desc FROM sys.indexes WHERE name LIKE 'i_sys_index_test1%';
GO

SELECT type, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_index_test1');
GO

-- should return 1, one row for HEAP on table
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_no_index')
GO

SELECT type, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_no_index');
GO

USE db1_sys_indexes
GO

-- index "t_sys_index_test1" should not be visible here
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('t_sys_index_test1')
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'i_sys_index_test1%';
GO

USE master
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'i_sys_index_test%';
GO

-- should return two results, one for HEAP and one for NONCLUSTERED
-- is_unique_constraint should be 0 for both cases
SELECT type_desc, is_unique_constraint FROM sys.indexes WHERE object_id = OBJECT_ID('t_pkey_table')
GO

-- should return two results, one for HEAP and one for NONCLUSTERED
-- is_unique_constraint should be 1 for NONCLUSTERED case
SELECT type_desc, is_unique_constraint FROM sys.indexes WHERE object_id = OBJECT_ID('t_unique_index')
GO
