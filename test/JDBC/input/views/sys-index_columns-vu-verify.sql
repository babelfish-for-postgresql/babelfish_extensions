SELECT COUNT(*) FROM sys.index_columns WHERE object_id = OBJECT_ID('sys_index_columns')
GO

USE db1_sys_index_columns
GO

SELECT count(*) FROM  sys.index_columns idx JOIN sys.tables tab ON idx.object_id = tab.object_id WHERE tab.name = 'rand_name1_sys_index_columns';
GO

USE master;
GO

SELECT count(*) FROM  sys.index_columns idx JOIN sys.tables tab ON idx.object_id = tab.object_id WHERE tab.name = 'rand_name1_sys_index_columns';
GO

SELECT count(*) FROM  sys.index_columns idx JOIN sys.tables tab ON idx.object_id = tab.object_id WHERE tab.name = 'rand_name2_sys_index_columns';
GO
