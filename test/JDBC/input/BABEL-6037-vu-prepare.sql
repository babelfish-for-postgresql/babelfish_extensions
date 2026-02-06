-- BABEL-6037 POC Test - Prepare
-- Creates test procedures for parse tree serialization/deserialization testing

SELECT set_config('babelfishpg_tsql.enable_routine_parse_cache', 'on', false);
GO

-- Test 1: Simple procedure without arguments
-- This tests basic serialization with minimal complexity
CREATE PROCEDURE dbo.small_proc
AS
BEGIN
    DECLARE @var1 INT = 1;
    SELECT @var1;
END;
GO

-- Test 2: Simple procedure with arguments (from focused revision doc)
-- This tests parameter handling and variable serialization
CREATE PROCEDURE dbo.small_proc_param 
    @param1 INT, 
    @param2 VARCHAR(50)
AS
BEGIN
    DECLARE @var1 INT = 1;
    SELECT @var1, @param1, @param2;
    CREATE TABLE #test(id int);
END;
GO

-- Test 3: Procedure with supported node types (PRINT, WHILE, GOTO, TRY-CATCH, CASE, BREAK, CONTINUE)
-- This tests various statement types within a BLOCK statement
CREATE PROCEDURE dbo.proc_param_supported  
@input_val INT = 10 
AS 
BEGIN
    DECLARE @counter INT = 0;
    DECLARE @result VARCHAR(100) = '';
    DECLARE @status INT = 0;
    
    -- Test PRINT statement
    PRINT 'Starting test procedure';
    
    -- Test WHILE loop with BREAK and CONTINUE
    WHILE @counter < 3
    BEGIN
        SET @counter = @counter + 1;
        
        -- Test IF with EXECSQL
        IF @counter = 2
        BEGIN
            SELECT @result = 'Found two';
        END
    END
    
    -- Test WHILE with BREAK and CONTINUE
    SET @counter = 0;
    WHILE 1 = 1
    BEGIN
        SET @counter = @counter + 1;
        
        -- Test BREAK statement
        IF @counter > 5
            BREAK;
            
        -- Test CONTINUE statement
        IF @counter = 3
            CONTINUE;
            
        SET @result = @result + CAST(@counter AS VARCHAR);
    END
    
    -- Test CASE statement
    SET @status = CASE @input_val
        WHEN 10 THEN 1
        WHEN 20 THEN 2
        WHEN 30 THEN 3
        ELSE 0
    END;
    
    -- Test GOTO and LABEL
    IF @status = 0
        GOTO skip_section;
    
    skip_section:
    PRINT 'Skipped or continued';
    
    -- Test TRY-CATCH block
    BEGIN TRY
        -- Test EXECSQL with potential error
        DECLARE @test_val INT;
        SELECT @test_val = 100 / @input_val;
        
        -- Test ASSIGN statement
        SET @result = 'Success: ' + CAST(@test_val AS VARCHAR);
    END TRY
    BEGIN CATCH
        -- Error handling
        SET @result = 'Error handled';
    END CATCH
    
    -- Test RETURN statement
    IF @input_val < 0
        RETURN;
    
    -- Final output
    SELECT @result AS FinalResult, @status AS Status, @counter AS Counter;
END;
GO


-- Test 4: Procedure with unsupported node type (EXEC_SP / sp_executesql)
-- PLTSQL_STMT_EXEC_SP is not in pltsql_is_serializable; triggers PLTSQL_SERIAL_UNSUPPORTED
-- Each new session falls back to full ANTLR recompile instead of using persistent cache
CREATE PROCEDURE dbo.proc_param_unsupported
    @max INT
AS
BEGIN
    DECLARE @sql NVARCHAR(100) = N'SELECT ' + CAST(@max AS NVARCHAR);
    EXEC sp_executesql @sql;
END;
GO


-- Test 5: Complex procedure that may lead to serialize error
-- Tests nested blocks, multiple statement types, and IF conditions
CREATE PROCEDURE dbo.complex_proc
    @input INT,
    @flag BIT
AS
BEGIN
    DECLARE @result INT;
    DECLARE @temp VARCHAR(100);
    
    -- Test ASSIGN statement
    SET @result = @input * 2;
    
    -- Test IF statement with nested block
    IF @flag = 1
    BEGIN
        SET @temp = 'Flag is true';
        SELECT @result, @temp;
        
        -- Nested temp table operations
        CREATE TABLE #temp1(id INT, value VARCHAR(50));
        INSERT INTO #temp1 VALUES (@result, @temp);
        SELECT * FROM #temp1;
    END
    ELSE
    BEGIN
        SET @temp = 'Flag is false';
        SELECT @result, @temp;
    END;
    
    -- Test EXECSQL with UNPIVOT (complex SQL expression within serializable proc)
    SELECT col, val
    FROM (SELECT @input AS input_val, @result AS doubled_val) AS src
    UNPIVOT (val FOR col IN (input_val, doubled_val)) AS unpvt;

    -- Test RETURN statement
    RETURN @result;
END;
GO

-- Test 6: Procedure for same-session testing (procedure created in verify file)

-- Test 7: Procedure for new-session testing
-- This will be used to test ALTER and DROP in new session
CREATE PROCEDURE dbo.oldsession_proc
    @value VARCHAR(50)
AS
BEGIN
    DECLARE @num INT;
    SET @num = CAST(@value AS INT);
    SELECT @num AS original_value;
END;
GO

-- Test 8: Procedure for rename + GUC off/on testing
CREATE PROCEDURE dbo.rename_cache_proc
    @val INT
AS
BEGIN
    SELECT @val * 10 AS result;
END;
GO

-- Test 9: Procedure for ALTER with GUC off then EXEC with GUC on
CREATE PROCEDURE dbo.alter_guc_proc
    @val INT
AS
BEGIN
    SELECT @val + 1 AS incremented;
END;
GO

-- Test 10: Table + procedure for altered dependency testing
-- Procedure references a table; dropping/recreating the table tests cache staleness
CREATE TABLE dbo.dep_test_table (id INT, name VARCHAR(50));
GO
INSERT INTO dbo.dep_test_table VALUES (1, 'Alice'), (2, 'Bob');
GO

CREATE PROCEDURE dbo.dep_table_proc
AS
BEGIN
    SELECT * FROM dbo.dep_test_table;
END;
GO

-- Test 11: Procedure with single OUT parameter
-- Tests out_param_varno re-derivation for single OUT arg on a procedure
-- (validator builds PLtsql_row, serialized into cache).
CREATE PROCEDURE dbo.babel_6037_out_single
    @in_val INT,
    @out_val INT OUT
AS
BEGIN
    SET @out_val = @in_val * 10;
END;
GO

-- Test 12: Procedure with multiple OUT parameters
-- For procedures with >1 OUT args, the validator builds a PLtsql_row datum
-- that gets serialized into the cache. The cache-hit path must find it
-- and set function->out_param_varno.
CREATE PROCEDURE dbo.babel_6037_out_multi
    @in_val INT,
    @out_val INT OUT,
    @out_msg VARCHAR(100) OUT
AS
BEGIN
    SET @out_val = @in_val * 2;
    SET @out_msg = 'Result: ' + CAST(@out_val AS VARCHAR);
END;
GO

-- Test 13: Multi-statement table-valued function (MSTVF)
-- MSTVFs use out_param_varno at runtime (pl_exec-2.c:1445) to build the
-- result table. The cache must preserve the ROW datum so the runtime can
-- find it.
CREATE FUNCTION dbo.babel_6037_mstvf(@in_val INT)
RETURNS @result TABLE (id INT, val VARCHAR(50))
AS
BEGIN
    INSERT INTO @result VALUES (@in_val, 'row1');
    INSERT INTO @result VALUES (@in_val + 1, 'row2');
    RETURN;
END;
GO

SELECT set_config('babelfishpg_tsql.enable_routine_parse_cache', 'off', false);
GO

PRINT 'All test procedures created successfully';
GO
