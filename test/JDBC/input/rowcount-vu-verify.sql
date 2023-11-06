
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

-- nested proc
exec rowcount_vu_prepare_select_nested_proc_var
go

-- should throw syntax error
set rowcount -1
GO

set rowcount NULL
go

-- should throw error
declare @v smallint = NULL
set rowcount @v
GO

-- check value 
select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
go

-- invalid set should throw error
DECLARE @value date = '2006-01-02'
SET ROWCOUNT @value
GO

-- invalid set should throw error
DECLARE @value varchar(10) = 'abc'
SET ROWCOUNT @value
GO

select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
go

-- implicit cast is allowed
DECLARE @value varchar(10) = '123'
SET ROWCOUNT @value
GO

select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
go

-- set int/bigint/smallint
DECLARE @value int = 2147483647
SET ROWCOUNT @value
GO

select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
go


-- overflow should throw error
DECLARE @value bigint = 922337203685477580
SET ROWCOUNT @value
GO

SET ROWCOUNT 2147483649
go

select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
go

DECLARE @value smallint = 3276
SET ROWCOUNT @value
GO

select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
go