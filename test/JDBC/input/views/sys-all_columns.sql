DROP TABLE IF EXISTS sys_all_columns_table
GO

CREATE TABLE sys_all_columns_table (
	sac_int_col INT PRIMARY KEY,
	sac_text_col_not_null VARCHAR(50) NOT NULL,
	sac_date_col DATETIME
)
GO

SELECT name, is_nullable, column_id 
FROM sys.all_columns 
WHERE name in ('sac_int_col', 'sac_text_col_not_null', 'sac_date_col')
ORDER BY name
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.all_columns');
GO

DROP TABLE IF EXISTS sys_all_columns_table
GO
