-- 1. Test resets GUC variables
SET lock_timeout 0;
GO
SELECT @@lock_timeout;
GO
EXEC sys.sp_reset_connection
-- TODO: GUC is not resetting
SELECT @@lock_timeout;
GO

-- 2. Test open transactions are aborted on reset
DROP TABLE IF EXISTS sp_reset_connection_test_table;
CREATE TABLE sp_reset_connection_test_table(id int);
BEGIN TRANSACTION
INSERT INTO sp_reset_connection_test_table VALUES(1)
GO
EXEC sys.sp_reset_connection
GO
COMMIT TRANSACTION
GO
SELECT * FROM sp_reset_connection_test_table
GO

-- 3. Test temp tables are deleted on reset
CREATE TABLE #babel_temp_table (ID INT identity(1,1), Data INT)
INSERT INTO #babel_temp_table (Data) VALUES (100), (200), (300)
GO
SELECT * from #babel_temp_table
GO
EXEC sys.sp_reset_connection
GO
SELECT * from #babel_temp_table
GO

-- 4. Test isolation level is reset
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
select transaction_isolation_level from sys.dm_exec_sessions where session_id=@@SPID
GO
EXEC sys.sp_reset_connection
GO
select transaction_isolation_level from sys.dm_exec_sessions where session_id=@@SPID
GO

-- 5. Test sp_reset_connection called with sp_prepexec
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
select transaction_isolation_level from sys.dm_exec_sessions where session_id=@@SPID
GO
DECLARE @handle int;
EXEC SP_PREPARE @handle output, NULL, N'exec sys.sp_reset_connection'
EXEC SP_EXECUTE @handle
GO
GO
select transaction_isolation_level from sys.dm_exec_sessions where session_id=@@SPID
GO
