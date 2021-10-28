-- Simple SET
SET XACT_ABORT ON;
SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
GO
SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
SET XACT_ABORT OFF;
GO

-- Inside transaction with commit
BEGIN TRANSACTION 
    SET XACT_ABORT ON;
COMMIT TRANSACTION
GO
SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
SET XACT_ABORT OFF;
GO

-- Inside transaction with rollback
BEGIN TRANSACTION
    SET XACT_ABORT ON;
ROLLBACK TRANSACTION
GO
SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
SET XACT_ABORT OFF;
GO

-- Inside transaction with rollback to savepoint
BEGIN TRANSACTION;
    SET XACT_ABORT OFF;
    SAVE TRAN SP1;
    SET XACT_ABORT ON;
    SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
    ROLLBACK TRAN SP1;
    SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
ROLLBACK TRANSACTION
GO
SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
SET XACT_ABORT OFF;
GO

-- Inside procedure
CREATE PROCEDURE xact_proc
AS
BEGIN
    SET XACT_ABORT ON;
    SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
END
GO
EXEC xact_proc;
SELECT name, setting FROM pg_settings WHERE name = 'babelfishpg_tsql.xact_abort';
SET XACT_ABORT OFF;
GO