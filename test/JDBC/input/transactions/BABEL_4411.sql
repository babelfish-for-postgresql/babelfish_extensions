SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
SELECT set_config('babelfishpg_tsql.escape_hatch_set_transaction_isolation_level', 'strict', false)
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
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
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
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
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

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO


