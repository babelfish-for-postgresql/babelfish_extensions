-- Without any transaction
SELECT XACT_STATE()
GO

-- Inside a transaction 
BEGIN TRANSACTION 
    SELECT XACT_STATE()
COMMIT TRANSACTION
GO