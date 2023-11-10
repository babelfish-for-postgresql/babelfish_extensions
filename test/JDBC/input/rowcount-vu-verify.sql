
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


-- check value 
select setting from pg_settings where name = 'babelfishpg_tsql.rowcount';
go

-- nested proc
exec rowcount_vu_prepare_select_nested_proc_var
go

-- should throw syntax error
set rowcount -1
GO

set rowcount NULL
go

-- should throw error
declare @v smallint = -1
set rowcount @v
GO

declare @v smallint = NULL
SET ROWCOUNT @v
GO

-- invalid set should throw error
DECLARE @value date = '2006-01-02'
SET ROWCOUNT @value
GO

-- invalid set should throw error
DECLARE @value varchar(10) = 'abc'
SET ROWCOUNT @value
GO

-- check value
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

-- while loop
DECLARE @value smallint = 1
set rowcount @value
go

while 1=1
begin
    SELECT * from rowcount_vu_prepare_testing3 where k = 1;
    UPDATE rowcount_vu_prepare_testing3 SET k = 2 where k = 1;
    SELECT * from rowcount_vu_prepare_testing3 where k = 2;
    DELETE rowcount_vu_prepare_testing3 where k = 2;
    if @@rowcount = 0 break
end
go


-- error message should be in uppercase for stmt
declare @v int = NULL;
SET rowCounT @v
go


-- parameter name should be in lowercase for stmt
declare @v int = -1;
SET rowCounT @v
go
