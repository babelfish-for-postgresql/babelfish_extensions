SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.indexes');
GO

-- should return 3, two rows for NONCLUSTERED indexes and one for HEAP on table
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_vu_prepare_t1')
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'sys_indexes_vu_prepare_i1%';
GO

SELECT type, type_desc FROM sys.indexes WHERE name LIKE 'sys_indexes_vu_prepare_i1%';
GO

SELECT type, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_vu_prepare_t1');
GO

-- should return 1, one row for HEAP on table
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_vu_prepare_t2')
GO

SELECT type, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_vu_prepare_t2');
GO

USE sys_indexes_vu_prepare_db1
GO

-- index "sys_indexes_vu_prepare_t1" should not be visible here
SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_vu_prepare_t1')
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'sys_indexes_vu_prepare_i1%';
GO

USE master
GO

SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'sys_indexes_vu_prepare_i%';
GO

-- should return two results, one for HEAP and one for NONCLUSTERED
-- is_unique_constraint should be 0 for both cases
SELECT type_desc, is_unique_constraint FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_vu_prepare_t_pkey')
GO

-- should return two results, one for HEAP and one for NONCLUSTERED
-- is_unique_constraint should be 1 for NONCLUSTERED case
SELECT type_desc, is_unique_constraint FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_vu_prepare_t_unique')
GO
