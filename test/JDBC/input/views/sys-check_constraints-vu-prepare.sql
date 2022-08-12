CREATE TABLE sys_check_constraints_vu_prepare_t1 (
	sck_date_col DATETIME CHECK (sck_date_col IS NOT NULL)
)
GO