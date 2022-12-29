CREATE TABLE sys_check_constraints_vu_prepare_t1 (
	sck_date_col DATETIME CHECK (sck_date_col IS NOT NULL)
)
GO

CREATE TABLE sys_check_constraints_vu_prepare_t2
(
column_a bit default 0,
column_b varchar(5) CHECK (column_b <> 'wrong'),
column_c datetime2 check(column_c < cast('2020-10-20 09:00:00' as datetime2)),
CHECK (column_a = 0)
)
GO
