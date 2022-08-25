-- Test setup
CREATE TABLE ma1 (a int)
GO

-- CREATE DATABASE testdb1
-- GO
-- USE testdb1
-- CREATE TABLE t1 (z int)
-- GO

-- CREATE DATABASE testdb2
-- GO
-- USE testdb2
-- CREATE table t2
-- GO

-- CREATE DATABASE testdb3
-- GO
-- USE testdb3
-- CREATE table t3
-- GO

SET babelfish_showplan_all on
GO

--Test cases for print
--basic
PRINT 'hi'
GO

--function
PRINT pg_backend_pid()
GO

--expression
PRINT 20 + 20
GO

--Invalid statement
PRINT SELECT 1
GO

-- variables
DECLARE @a INT
SET @a = 100
PRINT @a
GO

-- exceptions
PRINT 1/0
GO

---- Test cases for USE DB ----

--happy path
SELECT * FROM ma1 
USE testdb1
SELECT * FROM t1
GO
SET babelfish_showplan_all off
SELECT DB_NAME()
GO

--test multiple switches tests run in single user mode
-- SET babelfish_showplan_all on
-- USE testdb1
-- USE testdb2
-- USE testdb3
-- SELECT * FROM t3
-- USE testdb2
-- GO
-- SET babelfish_showplan_all off
-- SELECT DB_NAME()
-- GO

--Test invalid statements
SET babelfish_showplan_all on
USE testdb1
SELECT * FROM ma1
SET babelfish_showplan_all off
SELECT DB_NAME()

SET babelfish_showplan_all on
USE testdb1
SELECT * FROM t1
USE NOT_A_REAL_DATABASE
SET babelfish_showplan_all off
SELECT DB_NAME()

---- TEST RAISEERROR ----
-- note that during explain SQL Server does very limited no validation on inputs to raiserror 
-- This means that normally invalid cases such as using error code that are too low, too high
-- or are non existant do not result in an error. Similarly, things like argument counts are 
-- not validated, nor are variables checked for existance, so long as it is syntactically correct
-- explain will accept the raiserror statements
SET babelfish_showplan_all ON
GO
--happy path--
RAISERROR (N'TEST %s %d.',1,1,N'testing',9);
GO
--system error message, note message code validation is NOT done during explain--
RAISERROR (10000,1,1,N'testing',9);
GO
--variables, note that variable substitution is NOT done during explain --
DECLARE @testMsg VARCHAR(100)
SET @testMsg = 'a: %s b: %s c :%s'
RAISERROR (@testMsg, 1, 1, 'a', 'b', 'c')
GO
-- TEST THROW --
-- Throw is similar to RAISERROR in that during explain it is lax in enforcement of validation
-- However it does validate two cases in particular. First if it is invoked without parameters
-- you must be inside a catch block. arguments must be of the correct types

--happy path--
THROW 51000, 'test', 1
GO
-- invalid argument types --
THROW 'a', 'test', 1
GO
THROW 51000, 1, 1
GO
THROW 51000, 1, 'test'
GO
-- try catch --
THROW
GO

BEGIN TRY
    SELECT 1/0
END TRY
BEGIN CATCH
    PRINT 'test'
    THROW
END CATCH
GO