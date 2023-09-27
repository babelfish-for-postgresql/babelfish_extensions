-- Escape hatch disabled

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
EXEC sp_babelfish_configure 'escape_hatch_set_transaction_isolation_level', 'strict'
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO


BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
ROLLBACK
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
COMMIT
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
BEGIN TRANSACTION
GO
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
ROLLBACK
GO


SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SAVE TRANSACTION sp1
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
BEGIN TRANSACTION
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
COMMIT
GO
COMMIT
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
COMMIT
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO


-- Escape hatch enabled

EXEC sp_babelfish_configure 'escape_hatch_set_transaction_isolation_level', 'ignore'
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
COMMIT
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO
ROLLBACK
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SAVE TRANSACTION sp1
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
GO
COMMIT
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO