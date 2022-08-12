SELECT COUNT(*) FROM sys.index_columns WHERE object_id = OBJECT_ID('sys_index_columns_vu_prepare_t1')
GO

USE sys_index_columns_vu_prepare_db1
GO

SELECT count(*) FROM  sys.index_columns idx JOIN sys.tables tab ON idx.object_id = tab.object_id WHERE tab.name = 'sys_index_columns_vu_prepare_t2';
GO

USE master;
GO

SELECT count(*) FROM  sys.index_columns idx JOIN sys.tables tab ON idx.object_id = tab.object_id WHERE tab.name = 'sys_index_columns_vu_prepare_t2';
GO

SELECT count(*) FROM  sys.index_columns idx JOIN sys.tables tab ON idx.object_id = tab.object_id WHERE tab.name = 'sys_index_columns_vu_prepare_t3';
GO
