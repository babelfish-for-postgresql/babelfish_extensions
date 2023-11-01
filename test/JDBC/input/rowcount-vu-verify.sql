
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
