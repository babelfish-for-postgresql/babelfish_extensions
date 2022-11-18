-- Tests that using SET with dynamic SQL will not cause the change to persist

-- EXECUTE
EXEC (N'SET DATEFIRST 1; SELECT DATE_FIRST FROM sys.dm_exec_sessions;');
GO

SELECT DATE_FIRST FROM sys.dm_exec_sessions;
GO

EXECUTE (N'SET NOCOUNT ON; SELECT current_setting(''babelfishpg_tsql.nocount'', true)');
GO

SELECT current_setting('babelfishpg_tsql.nocount', true);
GO


-- sp_executesql
sp_executesql N'SET CONCAT_NULL_YIELDS_NULL off; SELECT CONCAT_NULL_YIELDS_NULL FROM sys.dm_exec_sessions;';
GO

SELECT CONCAT_NULL_YIELDS_NULL FROM sys.dm_exec_sessions;
GO


-- Errors in EXEC / sp_execute sql. Ensure stack level is removed
DECLARE @v NVARCHAR(10);
EXEC (@v);
GO

sp_executesql NULL;
GO

-- FMTONLY 
CREATE TABLE t_3092_fmtonly(a INT);
GO
INSERT INTO t_3092_fmtonly (a) VALUES (1);
GO

EXEC (N'SET FMTONLY ON; SELECT * FROM t_3092_fmtonly;')
GO

SELECT * FROM t_3092_fmtonly;
GO

DROP TABLE t_3092_fmtonly;
GO

-- PARSEONLY
sp_executesql N'SET PARSEONLY ON; SELECT 1;';
GO

SELECT 1;
GO


-- ANSI_NULLS
EXEC (N'SET ANSI_NULLS OFF; SELECT ansi_nulls FROM sys.dm_exec_sessions;');
GO
SELECT ansi_nulls FROM sys.dm_exec_sessions;
GO


-- IMPLICIT_TRANSACTIONS
sp_executesql N'SET IMPLICIT_TRANSACTIONS ON;
DECLARE @IMPLICIT_TRANSACTIONS VARCHAR(3) = ''OFF'';  
IF ( (2 & @@OPTIONS) = 2 ) SET @IMPLICIT_TRANSACTIONS = ''ON'';  
SELECT @IMPLICIT_TRANSACTIONS AS IMPLICIT_TRANSACTIONS;'
GO

DECLARE @IMPLICIT_TRANSACTIONS VARCHAR(3) = 'OFF';  
IF ( (2 & @@OPTIONS) = 2 ) SET @IMPLICIT_TRANSACTIONS = 'ON';  
SELECT @IMPLICIT_TRANSACTIONS AS IMPLICIT_TRANSACTIONS;
GO

-- Do this with transacton blocks?


-- XACT_ABORT
EXEC (N' SET XACT_ABORT ON; 
    DECLARE @XACT_ABORT VARCHAR(3) = ''OFF'';
    IF ( (16384 & @@OPTIONS) = 16384 ) SET @XACT_ABORT = ''ON'';
    SELECT @XACT_ABORT AS XACT_ABORT;'
);
GO

DECLARE @XACT_ABORT VARCHAR(3) = 'OFF';
IF ( (16384 & @@OPTIONS) = 16384 ) SET @XACT_ABORT = 'ON';
SELECT @XACT_ABORT AS XACT_ABORT;
GO


-- Multiple SETs 
EXECUTE (N'SET LOCK_TIMEOUT 1500; SET DATEFIRST 5; SELECT LOCK_TIMEOUT, DATE_FIRST FROM sys.dm_exec_sessions;');
GO

SELECT LOCK_TIMEOUT, DATE_FIRST FROM sys.dm_exec_sessions;
GO

sp_executesql N'SET TEXTSIZE 0; SET QUOTED_IDENTIFIER OFF; SELECT TEXT_SIZE, QUOTED_IDENTIFIER FROM sys.dm_exec_sessions; ';
GO

SELECT TEXT_SIZE, QUOTED_IDENTIFIER FROM sys.dm_exec_sessions;
GO


-- Nested
DECLARE @Nested NVARCHAR(500);
SET @Nested = N'SET DATEFIRST 3; 
    EXEC (N''SET DATEFIRST 4; SELECT DATE_FIRST FROM sys.dm_exec_sessions;''); 
SELECT DATE_FIRST FROM sys.dm_exec_sessions;'
  
EXECUTE sp_executesql N'sp_executesql @level; 
    SELECT DATE_FIRST FROM sys.dm_exec_sessions;', N'@level NVARCHAR(500)', @level = @Nested;  
GO


-- showplan_all escape hatch: SHOWPLAN_ALL and STATISTICS PROFILE
select set_config('babelfishpg_tsql.explain_costs', 'off', false);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_showplan_all', 'ignore';
go

EXEC (N'set showplan_all on; select 1;');
go

SELECT 1;
GO

sp_executesql N'SET statistics profile ON; SELECT 1;'
go

SELECT 1;
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_showplan_all', 'strict';
go

select set_config('babelfishpg_tsql.explain_costs', 'on', false);
go


-- BABELFISH_SHOWPLAN_ALL
sp_executesql N'SET BABELFISH_SHOWPLAN_ALL ON; SELECT 1;';
GO

SELECT 1;
GO

SET BABELFISH_SHOWPLAN_ALL OFF;
GO


-- BABELFISH_STATSITCS PROFILE
sp_executesql N'SET BABELFISH_STATISTICS PROFILE ON; SELECT 1;';
GO

SELECT 1;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO


-- Identity Insert
-- Revert Off
CREATE TABLE table_3092_1 (test_id INT IDENTITY, test_col INT);

GO

sp_executesql N'SET IDENTITY_INSERT table_3092_1 ON; INSERT INTO table_3092_1 (test_id, test_col) VALUES (1, 1);';
GO

INSERT INTO table_3092_1 (test_id, test_col) VALUES (2, 2);
GO

SELECT * FROM table_3092_1;
GO

DROP TABLE table_3092_1;
GO

-- Revert On Case
CREATE TABLE table_3092_1 (test_id INT IDENTITY, test_col INT);
CREATE TABLE table_3092_2 (test_id INT IDENTITY, test_col INT);
GO

SET IDENTITY_INSERT table_3092_1 ON;
GO

INSERT INTO table_3092_1 (test_id, test_col) VALUES (1, 1);
GO

sp_executesql N'SET IDENTITY_INSERT table_3092_1 OFF; SET IDENTITY_INSERT table_3092_2 ON; INSERT INTO table_3092_2 (test_id, test_col) VALUES (2, 2);';
GO

INSERT INTO table_3092_1 (test_id, test_col) VALUES (3, 3);
GO
INSERT INTO table_3092_2 (test_id, test_col) VALUES (4, 4);
GO

SELECT * FROM table_3092_1;
GO
SELECT * FROM table_3092_2;
GO

DROP TABLE table_3092_1;
DROP TABLE table_3092_2;
GO

-- Add in changing PLTSQL settings. Make sure no regression. SET implementation quip doc goes over what should happen here from an interop perspective

-- TRANSACTION ISOLATION LEVEL
-- sp_executesql N'SET TRANSACTION ISOLATION LEVEL read uncommitted; SELECT transaction_isolation_level FROM sys.dm_exec_sessions;';
-- GO

-- SELECT transaction_isolation_level FROM sys.dm_exec_sessions;
-- GO

-- SET TRANSACTION ISOLATION LEVEL read committed;
-- GO


-- Settings to test:
-- SET DATEFIRST                    X
-- SET LOCK_TIMEOUT                 X
-- SET CONCAT_NULL_YIELDS_NULL      X
-- SET IDENTITY_INSERT              FAILING
-- SET QUOTED_IDENTIFIER            X
-- SET FMTONLY                      X
-- SET NOCOUNT                      X
-- SET PARSEONLY                    X
-- SET TEXTSIZE                     X
-- SET ANSI_NULLS                   X
-- SET SHOWPLAN_ALL                 X
-- SET SET STATISTICS PROFILE       X
-- SET IMPLICIT_TRANSACTIONS        X
-- SET TRANSACTION ISOLATION LEVEL  FAILING
-- SET XACT_ABORT                   X
-- SET BABELFISH_SHOWPLAN_ALL       X
-- SET BABELFISH_STATISTICS PROFILE X

-- TODO: Nested with non-GUCs


-- SELECT DATE_FIRST, DEADLOCK_PRIORITY, CONCAT_NULL_YIELDS_NULL, 
--     ROW_COUNT, ANSI_DEFAULTS
-- FROM sys.dm_exec_sessions;
-- DATE_FIRST DEADLOCK_PRIORITY CONCAT_NULL_YIELDS_NULL ROW_COUNT            ANSI_DEFAULTS
-- ---------- ----------------- ----------------------- -------------------- -------------
--          7                 0                       1                    1             1
-- Look into statistics, transactions