DROP DATABASE IF EXISTS db1
GO
CREATE DATABASE db1
GO
USE db1
GO

DROP TABLE IF EXISTS t1
GO
CREATE TABLE t1(a INT, PRIMARY KEY(a))
GO

DROP PROCEDURE IF EXISTS select_all
GO
CREATE PROCEDURE select_all
AS
SELECT * FROM t1
GO

DROP PROCEDURE IF EXISTS seluct_all
GO
CREATE PROCEDURE seluct_all
AS
SELECT * FROM t1
GO

DROP PROCEDURE IF EXISTS SelEct_AlL_Mixed
GO
CREATE PROCEDURE SelEct_AlL_Mixed
AS
SELECT * FROM t1
GO

CREATE SCHEMA s1
GO

DROP FUNCTION IF EXISTS s1.positive_or_negative
GO

CREATE FUNCTION s1.positive_or_negative (
	@long DECIMAL(9,6)
)
RETURNS CHAR(4) AS
BEGIN
	DECLARE @return_value CHAR(10);
	SET @return_value = 'zero';
    IF (@long > 0.00) SET @return_value = 'positive';
    IF (@long < 0.00) SET @return_value = 'negative';
 
    RETURN @return_value
END;
GO

-- error: provided name of database we are not currently in
EXEC sp_stored_procedures @sp_qualifier = 'master'
GO

EXEC sp_stored_procedures @sp_name = 'select_all'
GO

EXEC sp_stored_procedures @sp_name = 'positive_or_negative', @sp_owner = 's1'
GO

-- unnamed invocation
EXEC sp_stored_procedures 'select_all', 'dbo', 'db1'
GO

-- [] delimiter invocation
EXEC [sys].[sp_stored_procedures] 'select_all', 'dbo', 'db1'
GO

EXEC [sp_stored_procedures] 'select_all', 'dbo', 'db1'
GO

-- case-insensitive invocation
EXEC SP_STORED_PROCEDURES @SP_NAME = 'positive_or_negative', @SP_OWNER = 's1', @SP_QUALIFIER = 'db1'
GO

-- case-insensitive parameters
EXEC sp_stored_procedures 'SELECT_ALL', 'DBO', 'DB1'
GO

-- Mixed-case procedure
EXEC sp_stored_procedures 'SELECT_ALL_MIXED'
GO

EXEC sp_stored_procedures 'select_all_mixed'
GO

EXEC sp_stored_procedures 'sELecT_aLL_miXed'
GO

-- tests fUsePattern = 0
EXEC sp_stored_procedures @sp_name='select_a%', @fusepattern=0
GO

-- tests wildcard patterns
EXEC sp_stored_procedures @sp_name='select_a%', @fusepattern=1 
GO

EXEC sp_stored_procedures @sp_name='sel_ct_all'
GO

-- NOTE: Incorrect output with [] wildcards, see BABEL-2452
EXEC sp_stored_procedures @sp_name='sel[eu]ct_all'
GO

EXEC sp_stored_procedures @sp_name='sel[^u]ct_all'
GO

EXEC sp_stored_procedures @sp_name='sel[a-u]ct_all'
GO

DROP FUNCTION s1.positive_or_negative
GO
DROP PROCEDURE select_all
GO
DROP PROCEDURE seluct_all
GO
DROP PROCEDURE SelEct_AlL_Mixed
GO
DROP TABLE t1
GO
DROP SCHEMA s1
GO
USE master
GO
DROP DATABASE db1
GO
