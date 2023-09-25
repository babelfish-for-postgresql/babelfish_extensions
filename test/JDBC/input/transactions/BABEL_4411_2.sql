-- Check isolation levels inside procedure and functions

-- CREATE PROCEDURES
CREATE PROCEDURE BABEL_4411_P_1
AS
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

CREATE PROCEDURE BABEL_4411_P_2
AS
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

-- PROCEDURES #### ESCAPE HATCH DISABLED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
EXEC sp_babelfish_configure 'escape_hatch_set_transaction_isolation_level', 'strict'
GO

BEGIN TRANSACTION
GO
EXEC BABEL_4411_P_1
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
EXEC BABEL_4411_P_2
GO
ROLLBACK
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
EXEC BABEL_4411_P_2
GO
ROLLBACK
GO

-- PROCEDURES #### ESCAPE HATCH ENABLED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
EXEC sp_babelfish_configure 'escape_hatch_set_transaction_isolation_level', 'ignore'
GO

BEGIN TRANSACTION
GO
EXEC BABEL_4411_P_1
GO
COMMIT
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
EXEC BABEL_4411_P_2
GO
ROLLBACK
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
EXEC BABEL_4411_P_2
GO
ROLLBACK
GO

-- CLEANUP PROCEDURES
DROP PROCEDURE IF EXISTS BABEL_4411_P_1, BABEL_4411_P_2
GO


-- CREATE FUNCTIONS
CREATE FUNCTION BABEL_4367_F1() RETURNS varchar(16) AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
RETURN CAST(current_setting('transaction_isolation') as varchar(16))
END
GO

CREATE FUNCTION BABEL_4367_F2() RETURNS varchar(16) AS
BEGIN
RETURN CAST(current_setting('transaction_isolation') as varchar(16))
END
GO


-- FUNCTIONS #### ESCAPE HATCH DISABLED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
EXEC sp_babelfish_configure 'escape_hatch_set_transaction_isolation_level', 'strict'
GO

BEGIN TRANSACTION
GO
SELECT BABEL_4367_F1()
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SELECT BABEL_4367_F2()
GO
COMMIT
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
SELECT BABEL_4367_F2()
GO
COMMIT
GO

-- FUNCTIONS #### ESCAPE HATCH ENABLED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
EXEC sp_babelfish_configure 'escape_hatch_set_transaction_isolation_level', 'ignore'
GO

BEGIN TRANSACTION
GO
SELECT BABEL_4367_F1()
GO

SELECT @@trancount
SELECT current_setting('transaction_isolation')
SELECT current_setting('default_transaction_isolation')
GO

BEGIN TRANSACTION
GO
SELECT BABEL_4367_F2()
GO
COMMIT
GO

BEGIN TRANSACTION
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
SELECT BABEL_4367_F2()
GO
COMMIT
GO

-- CLEANUP FUNCTIONS
DROP FUNCTION IF EXISTS BABEL_4367_F1, BABEL_4367_F2
GO
