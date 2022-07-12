CREATE TABLE sys_check_constraints (
	sck_date_col DATETIME CHECK (sck_date_col IS NOT NULL)
)
GO