-- Comprehensive test for all INSERT EXEC issues
-- Tests the query rewriting approach for INSERT EXEC

-- ============================================================================
-- BABEL-4306: EXEC() inside procedure - rows not inserted
-- EXPECTED: Query rewriting should FIX this
-- ============================================================================
CREATE TABLE babel_4306_t (a int, b varchar(10));
GO

CREATE PROC babel_4306_p AS 
    SELECT 123, cast('abc' as varchar(10));
GO

CREATE PROC babel_4306_p2 AS 
    EXEC('SELECT 456, cast(''def'' as varchar(10))');
GO

-- Test direct procedure
INSERT INTO babel_4306_t EXEC babel_4306_p;
GO

SELECT * FROM babel_4306_t;
GO

-- Test procedure with EXEC() inside
DELETE FROM babel_4306_t;
GO

INSERT INTO babel_4306_t EXEC babel_4306_p2;
GO

SELECT * FROM babel_4306_t;
GO

DROP PROC babel_4306_p;
DROP PROC babel_4306_p2;
DROP TABLE babel_4306_t;
GO

-- ============================================================================
-- BABEL-4533: IDENTITY column crash/hang
-- EXPECTED: Query rewriting should FIX this
-- ============================================================================
CREATE TABLE babel_4533_custdata (
    id VARCHAR(100),
    cust_name VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100),
    phone VARCHAR(100)
);
GO

INSERT INTO babel_4533_custdata VALUES 
    (N'GREAL', N'Great Lakes Food Market', N'Eugene', N'USA', N'(503) 555-7555');
GO

CREATE PROCEDURE babel_4533_p AS
    SELECT id, cust_name, city, country, phone FROM babel_4533_custdata;
GO

CREATE TABLE babel_4533_t (
    idcol INT IDENTITY,
    id VARCHAR(100),
    cust_name VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100),
    phone VARCHAR(100)
);
GO

INSERT INTO babel_4533_t EXEC babel_4533_p;
GO

SELECT * FROM babel_4533_t;
GO

DROP PROCEDURE babel_4533_p;
DROP TABLE babel_4533_custdata;
DROP TABLE babel_4533_t;
GO

-- ============================================================================
-- Wrong column insertion
-- EXPECTED: Query rewriting should FIX this
-- ============================================================================
CREATE TABLE wrongcol_t (id int, id1 int);
GO

CREATE PROC wrongcol_p AS SELECT 1;
GO

INSERT INTO wrongcol_t (id1) EXEC wrongcol_p;
GO

-- Expected: id=NULL, id1=1
SELECT * FROM wrongcol_t;
GO

DROP PROC wrongcol_p;
DROP TABLE wrongcol_t;
GO

-- ============================================================================
-- Multiple SELECT statements
-- EXPECTED: Query rewriting should FIX this
-- ============================================================================
CREATE TABLE multi_t (a INT);
GO

CREATE PROC multi_p AS 
    SELECT 1;
    SELECT 2;
    SELECT 3;
GO

INSERT INTO multi_t EXEC multi_p;
GO

-- Should have 3 rows: 1, 2, 3
SELECT * FROM multi_t;
GO

DROP PROC multi_p;
DROP TABLE multi_t;
GO

-- ============================================================================
-- Nested procedure calls
-- EXPECTED: Query rewriting should FIX this
-- ============================================================================
CREATE TABLE nested_t (a INT);
GO

CREATE PROC nested_inner AS SELECT 10;
GO

CREATE PROC nested_middle AS EXEC nested_inner; SELECT 20;
GO

CREATE PROC nested_outer AS EXEC nested_middle; SELECT 30;
GO

INSERT INTO nested_t EXEC nested_outer;
GO

-- Should have 3 rows: 10, 20, 30
SELECT * FROM nested_t;
GO

DROP PROC nested_outer;
DROP PROC nested_middle;
DROP PROC nested_inner;
DROP TABLE nested_t;
GO

-- ============================================================================
-- BABEL-5921: OUTPUT clause goes to client
-- EXPECTED: Query rewriting should FIX this
-- ============================================================================
CREATE TABLE babel_5921_t (id INT);
GO

CREATE PROC babel_5921_p AS
    DROP TABLE IF EXISTS #temp;
    CREATE TABLE #temp (id INT);
    INSERT INTO #temp OUTPUT INSERTED.* VALUES (1);
GO

INSERT INTO babel_5921_t EXEC babel_5921_p;
GO

-- Should have 1 row with id=1
SELECT * FROM babel_5921_t;
GO

DROP PROC babel_5921_p;
DROP TABLE babel_5921_t;
GO

-- ============================================================================
-- BABEL-5922: Transaction behavior
-- ============================================================================
CREATE TABLE babel_5922_t (id INT, id1 INT);
GO

CREATE PROC babel_5922_p AS
BEGIN TRY
    SELECT 1, 1;
    SELECT 1/0;  -- This will cause an error
END TRY
BEGIN CATCH
    -- Do nothing
END CATCH
GO

INSERT INTO babel_5922_t EXEC babel_5922_p;
GO

-- SQL Server: 0 rows (try block rolled back)
SELECT count(*) as row_count FROM babel_5922_t;
GO

DROP PROC babel_5922_p;
DROP TABLE babel_5922_t;
GO

-- ============================================================================
-- TRY/CATCH with successful transaction
-- ============================================================================
CREATE TABLE trycatch_t (a INT);
GO

CREATE PROC trycatch_p AS 
BEGIN TRY
    BEGIN TRANSACTION;
    SELECT 555;
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH
GO

INSERT INTO trycatch_t EXEC trycatch_p;
GO

-- Should have 1 row with 555
SELECT * FROM trycatch_t;
GO

DROP PROC trycatch_p;
DROP TABLE trycatch_t;
GO

-- ============================================================================
-- Type coercion
-- ============================================================================
CREATE TABLE coerce_t (val varchar(10));
GO

CREATE PROC coerce_p AS SELECT 12345;
GO

INSERT INTO coerce_t EXEC coerce_p;
GO

-- Should have 1 row with "12345"
SELECT * FROM coerce_t;
GO

DROP PROC coerce_p;
DROP TABLE coerce_t;
GO

-- ============================================================================
-- NULL values
-- ============================================================================
CREATE TABLE null_t (id int, name varchar(50));
GO

CREATE PROC null_p AS
    SELECT 1, NULL;
    SELECT NULL, 'test';
    SELECT 3, 'value';
GO

INSERT INTO null_t EXEC null_p;
GO

-- Should have 3 rows
SELECT * FROM null_t;
GO

DROP PROC null_p;
DROP TABLE null_t;
GO

-- ============================================================================
-- sp_executesql inside procedure
-- ============================================================================
CREATE TABLE spexec_t (a INT);
GO

CREATE PROC spexec_p AS 
    EXEC sp_executesql N'SELECT 777';
GO

INSERT INTO spexec_t EXEC spexec_p;
GO

-- Should have 1 row with 777
SELECT * FROM spexec_t;
GO

DROP PROC spexec_p;
DROP TABLE spexec_t;
GO

-- ============================================================================
-- Large result set (100 rows)
-- ============================================================================
CREATE TABLE large_t (id int);
GO

CREATE PROC large_p AS
    DECLARE @i int = 1;
    WHILE @i <= 100
    BEGIN
        SELECT @i;
        SET @i = @i + 1;
    END
GO

INSERT INTO large_t EXEC large_p;
GO

-- Should have 100 rows
SELECT COUNT(*) as row_count FROM large_t;
GO

DROP PROC large_p;
DROP TABLE large_t;
GO

-- ============================================================================
-- UNION ALL in procedure
-- ============================================================================
CREATE TABLE union_t (a INT);
GO

CREATE PROC union_p AS 
    SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3;
GO

INSERT INTO union_t EXEC union_p;
GO

-- Should have 3 rows
SELECT * FROM union_t;
GO

DROP PROC union_p;
DROP TABLE union_t;
GO

-- ============================================================================
-- Temp table target
-- ============================================================================
CREATE TABLE #temp_target (a INT);
GO

CREATE PROC temp_p AS SELECT 999;
GO

INSERT INTO #temp_target EXEC temp_p;
GO

-- Should have 1 row with 999
SELECT * FROM #temp_target;
GO

DROP PROC temp_p;
DROP TABLE #temp_target;
GO
