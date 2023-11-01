
-- test "SET ROWCOUNT value"
exec rowcount_vu_prepare_insert_proc;
GO

exec rowcount_vu_prepare_select_proc;
GO

exec rowcount_vu_prepare_update_proc;
GO

exec rowcount_vu_prepare_delete_proc;
GO


--  test "SET ROWCOUNT @variable"
exec rowcount_vu_prepare_insert_proc_var;
GO

exec rowcount_vu_prepare_select_proc_var;
GO

exec rowcount_vu_prepare_update_proc_var;
GO

exec rowcount_vu_prepare_delete_proc_var;
GO


set rowcount -1
GO

set rowcount NULL
go

declare @v smallint = NULL
set rowcount @v
GO

-- invalid set should throw error
DECLARE @value date = '2006-01-02'
SET ROWCOUNT @value
GO

DECLARE @value varchar(10) = 'abc'
SET ROWCOUNT @value
GO

-- set int/bigint/smallint
DECLARE @value int = 2147483647
SET ROWCOUNT @value
GO

DECLARE @value bigint = 922337203685477580
SET ROWCOUNT @value
GO

DECLARE @value smallint = 3276
SET ROWCOUNT @value
GO