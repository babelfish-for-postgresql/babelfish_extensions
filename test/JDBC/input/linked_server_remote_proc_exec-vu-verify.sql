-- tsql
USE master;
GO

SELECT name, data_source FROM sys.servers WHERE name = 'ls_svr';
GO

EXEC ls_svr.master.dbo.rp_basic;
GO

EXECUTE ls_svr.master.dbo.rp_basic;
GO

DECLARE @out int;
EXEC ls_svr.master.dbo.rp_out @x=41, @y=@out OUTPUT;
SELECT @out AS out_value;
GO

DECLARE @out_positional int;
EXEC ls_svr.master.dbo.rp_out 5, @out_positional OUTPUT;
SELECT @out_positional AS out_value_positional;
GO

DECLARE @input_only int = 7;
DECLARE @out_from_input int;
EXEC ls_svr.master.dbo.rp_out @input_only, @out_from_input OUTPUT;
SELECT @input_only AS input_value_after_call, @out_from_input AS out_value_from_input;
GO

DECLARE @status_exec int;
DECLARE @status_execute int;
EXEC @status_exec = ls_svr.master.dbo.rp_status @x=11;
EXECUTE @status_execute = ls_svr.master.dbo.rp_status @x=11;
SELECT @status_exec AS status_exec, @status_execute AS status_execute;
GO

EXEC ls_svr.master.dbo.rp_bit @flag=1;
GO

EXEC ls_svr.master.dbo.rp_varchar_param @val='benchmark-test-string';
GO

EXEC ls_svr.master.dbo.rp_datetime_param @val='2025-01-15 10:30:00.000';
GO

EXEC ls_svr.master.dbo.rp_float_param @val=3.14159;
GO

EXEC ls_svr.master.dbo.rp_null_param @p1=NULL, @p2=NULL, @p3=NULL, @p4=NULL;
GO

DECLARE @large_string varchar(max) = REPLICATE('A', 4000);
EXEC ls_svr.master.dbo.rp_large_string @val=@large_string;
GO

EXEC ls_svr.master.dbo.rp_multi;
GO

EXEC ls_svr.master.dbo.rp_multi_mismatch;
GO

DECLARE @multi_out int;
DECLARE @multi_rc int;
EXEC @multi_rc = ls_svr.master.dbo.rp_multi_out_status @x=41, @y=@multi_out OUTPUT;
SELECT @multi_out AS out_value_after_multi, @multi_rc AS return_status_after_multi;
GO

BEGIN TRANSACTION;
EXEC ls_svr.master.dbo.rp_txn_insert @tag=5001;
COMMIT TRANSACTION;
SELECT COUNT(*) AS count_after_local_commit
FROM dbo.rp_txn_log
WHERE tag = 5001;
GO

BEGIN TRANSACTION;
EXEC ls_svr.master.dbo.rp_txn_insert @tag=5002;
ROLLBACK TRANSACTION;
SELECT COUNT(*) AS count_after_local_rollback
FROM dbo.rp_txn_log
WHERE tag = 5002;
GO

BEGIN DISTRIBUTED TRANSACTION;
EXEC ls_svr.master.dbo.rp_txn_insert @tag=5003;
COMMIT TRANSACTION;
GO

BEGIN DISTRIBUTED TRANSACTION;
EXEC ls_svr.master.dbo.rp_txn_insert @tag=5004;
ROLLBACK TRANSACTION;
GO

EXEC sp_serveroption @server='ls_svr', @optname='rpc out', @optvalue='false'
GO

EXEC ls_svr.master.sys.sp_helpdb;
GO

EXEC ls_svr.master.dbo.rp_basic;
GO

EXEC sp_serveroption @server='ls_svr', @optname='rpc out', @optvalue='true'
GO

EXEC sp_serveroption @server='ls_svr', @optname='rpc', @optvalue='false'
GO

EXEC ls_svr.master.dbo.rp_basic;
GO

EXEC sp_serveroption @server='ls_svr', @optname='rpc', @optvalue='true'
GO

EXEC sp_serveroption @server='ls_svr', @optname='rpc out', @optvalue='false'
GO

DECLARE @rc_blocked int;
EXEC @rc_blocked = ls_svr.master.dbo.rp_status @x=7;
SELECT @rc_blocked AS return_status_when_rpc_out_false;
GO

DECLARE @out_blocked int;
EXEC ls_svr.master.dbo.rp_out @x=41, @y=@out_blocked OUTPUT;
SELECT @out_blocked AS out_value_when_rpc_out_false;
GO

EXECUTE ls_svr.master.dbo.rp_basic;
GO

EXEC sp_serveroption @server='ls_svr', @optname='rpc out', @optvalue='true'
GO

EXEC sp_serveroption @server='ls_svr', @optname='query timeout', @optvalue='1'
GO

EXEC ls_svr.master.dbo.rp_sleep;
GO

EXEC sp_serveroption @server='ls_svr', @optname='query timeout', @optvalue='0'
GO

EXEC ls_svr.master.dbo.rp_basic;
GO

EXEC sp_droplinkedsrvlogin @rmtsrvname = 'ls_svr', @locallogin = NULL
GO

-- psql
SELECT COUNT(*) AS linked_server_rows_after_drop
FROM pg_dblink l
WHERE l.dblname = 'ls_svr';
GO

-- tsql
EXEC sp_helplinkedsrvlogin @rmtsrvname = 'ls_svr';
GO

SELECT name, data_source FROM sys.servers WHERE name = 'ls_svr';
GO

EXEC ls_svr.master.dbo.rp_basic;
GO

EXEC ls_svr_missing.master.dbo.rp_basic;
GO
