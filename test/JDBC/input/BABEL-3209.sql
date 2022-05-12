-- Boot Value for transaction isolation level should be "read committed" i.e. 2
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO

-- Explicitly setting transaction isolation level should be reflected in the view
SET transaction isolation level snapshot;
SELECT CAST(current_setting('transaction_isolation') AS VARCHAR);
SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID;
GO