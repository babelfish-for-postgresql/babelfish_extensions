/*
 * T-SQL transaction isolation level mapping is as follows for dm_exec_sessions:
 *
 * 1 = READ UNCOMMITTED
 * 2 = READ COMMITTED
 * 3 = REPEATABLE READ
 * 4 = SERIALIZABLE
 * 5 = SNAPSHOT
 */


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

-- Isolation level not supported so will reflect same value as before
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
GO
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

-- Isolation level not supported so will reflect same value as before
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

-- Isolation level internally mapped to PG repeatable read so
-- current_setting will show "repeatable read" but
-- dm_exec_sessions will show code for snapshot isolation
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

SELECT set_config('babelfishpg_tsql.isolation_level_repeatable_read','pg_isolation',false);
SELECT set_config('babelfishpg_tsql.isolation_level_serializable','pg_isolation',false);
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
GO
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO
