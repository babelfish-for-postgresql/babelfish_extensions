SELECT * FROM sys.lock_timeout()
GO

-- Setting of SET LOCK_TIMEOUT is set at execute or run time and not at parse time
-- Means will continue to display default value of 0 at next transaction
SET LOCK_TIMEOUT 100 
GO

SELECT @@LOCK_TIMEOUT
GO

SELECT sys.lock_timeout() 
GO