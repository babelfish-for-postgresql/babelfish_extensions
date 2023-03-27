-- Simple SET
DECLARE @lc_messages VARCHAR(20);
SELECT @lc_messages = 'fr_FR.utf8';
SELECT @lc_messages;
GO

-- Inside transaction with commit
BEGIN TRANSACTION;
    DECLARE @lc_messages VARCHAR(20);
SELECT @lc_messages = 'fr_FR.utf8';
COMMIT TRANSACTION;
SELECT @lc_messages;
SET @lc_messages = NULL;
GO
-- Inside transaction with rollback
DECLARE @lc_messages VARCHAR(20);
SET @lc_messages = 'fr_FR.utf8';
BEGIN TRANSACTION;
    SET @lc_messages = 'fr_FR.utf8';
ROLLBACK TRANSACTION;
SELECT @lc_messages;
SET @lc_messages = NULL;
GO

-- Inside transaction with rollback to savepoint
DECLARE @lc_messages VARCHAR(20);
SET @lc_messages = 'en_GB.utf8';
BEGIN TRANSACTION;
    SET @lc_messages = 'en_GB.utf8';
    SAVE TRANSACTION SP1;
    SET @lc_messages = 'fr_FR.utf8';
    SELECT @lc_messages;
    ROLLBACK TRANSACTION SP1;
    SELECT @lc_messages;
ROLLBACK TRANSACTION;
SELECT @lc_messages;
SET @lc_messages = NULL;
GO
