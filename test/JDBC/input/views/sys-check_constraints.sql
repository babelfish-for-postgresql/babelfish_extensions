DROP TABLE IF EXISTS sys_check_constraints
GO

CREATE TABLE sys_check_constraints (
	sck_date_col DATETIME CHECK (sck_date_col IS NOT NULL),
	sck_datetime_2 datetime2 check(sck_datetime_2 < cast('2020-10-20 09:00:00' as datetime2))
)
GO

SELECT name, definition FROM sys.check_constraints WHERE NAME IN ('sys_check_constraints_sck_date_col_check', 'sys_check_constraints_sck_datetime_2_check') ORDER BY NAME
GO

DROP TABLE IF EXISTS sys_check_constraints
GO
