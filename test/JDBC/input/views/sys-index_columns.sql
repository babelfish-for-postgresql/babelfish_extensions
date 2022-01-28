DROP TABLE IF EXISTS sys_index_columns
GO

CREATE TABLE sys_index_columns (
	sic_name VARCHAR (50),
	sic_surname VARCHAR (50)
)
GO

CREATE INDEX sic_test_index
ON sys_index_columns (sic_name)
GO

SELECT COUNT(*) FROM sys.index_columns WHERE object_id = OBJECT_ID('sys_index_columns')
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.index_columns')
GO

DROP TABLE IF EXISTS sys_index_columns
GO
