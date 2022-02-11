DROP TABLE IF EXISTS sys_check_constraints
GO

CREATE TABLE sys_check_constraints (
	sck_date_col DATETIME CHECK (sck_date_col IS NOT NULL)
)
GO

SELECT name FROM sys.check_constraints WHERE NAME IN ('sys_check_constraints_sck_date_col_check')
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.check_constraints');
GO

DROP TABLE IF EXISTS sys_check_constraints
GO
