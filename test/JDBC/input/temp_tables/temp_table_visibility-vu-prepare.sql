-- This is the original case from BABEL-4788
-- Test Object ID called on inner proc then examine outer proc. 
CREATE PROCEDURE object_id_inner_proc
AS
    if OBJECT_ID('#tmp') is not null 
    begin
        print 'end inner_proc'
    end
go

CREATE VIEW enr_view AS
    SELECT
        CASE
            WHEN relname LIKE '#pg_toast%' AND relname LIKE '%index%' THEN '#pg_toast_#oid_masked#_index'
            WHEN relname LIKE '#pg_toast%' THEN '#pg_toast_#oid_masked#'
            ELSE relname
        END AS relname
    FROM sys.babelfish_get_enr_list()
    ORDER BY relname COLLATE pg_c_utf8
GO

CREATE PROCEDURE object_id_outer_proc
AS
    CREATE TABLE #tmp(i INT)    

    EXEC object_id_inner_proc 
    print 'after inner_proc'    

    SELECT * FROM #tmp
     
    print 'dropping #tmp'
    DROP TABLE #tmp
go

-- Test nested calls to sys.babelfish_get_enr_list since that calls get_namedRelList
CREATE PROCEDURE enr_list_inner_proc
as
    CREATE TABLE #tab_nest_level_0(a int)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname COLLATE pg_c_utf8;
go

-- Ensure to check before and after table is created.
CREATE PROCEDURE enr_list_outer_proc
AS
    EXEC enr_list_inner_proc
    CREATE TABLE #tab_nest_level_1(a int)
    EXEC enr_list_inner_proc
go

CREATE PROCEDURE enr_list_outer_outer_proc
AS
    CREATE TABLE #tab_nest_level_2(a int)
    EXEC enr_list_outer_proc
go

-- This is the case from BABEL-4122, which has the same root cause. 
create proc babel_4122_proc @tabname varchar(30) as
    if object_id(@tabname) is not null
    begin
        execute('select * from ' + @tabname)
    end
go

CREATE PROC p_truncate AS TRUNCATE TABLE #temptable5605
GO
CREATE PROC p_nested AS 
BEGIN
	CREATE TABLE #temptable5605(a INT);
	INSERT INTO #temptable5605 VALUES (GENERATE_SERIES(1,100));
	EXEC p_truncate
	SELECT COUNT(*) FROM #temptable5605;
	EXEC p_insert 100;
	SELECT COUNT(*) FROM #temptable5605;
END;
GO
CREATE PROC p_insert(@a INT) AS INSERT INTO #temptable5605 VALUES (@a);
GO
CREATE PROC p_alter_add_col AS ALTER TABLE #temptable5605 ADD newcol BIGINT DEFAULT 0;
GO
CREATE PROC p_nested_2 AS
BEGIN
	INSERT INTO #temptable5605 VALUES (GENERATE_SERIES(1,100)); -- inserts 100 tuples
	SELECT COUNT(*) FROM #temptable5605; 						-- shows 200 tuples
	EXEC p_insert 101										-- inserts 1 tuple
	SELECT COUNT(*) FROM #temptable5605;						-- shows 201 tuples
	CREATE TABLE #temptable5605(a INT, b INT IDENTITY(1,1));	-- noOp; creates temp table
	INSERT INTO #temptable5605(a) VALUES (1), (2);				-- inserts 2 tuple
	SELECT COUNT(*) FROM #temptable5605;						-- shows 2 tuples
	EXEC p_nested;
	SELECT COUNT(*) FROM #temptable5605;						-- shows 2 tuples
	EXEC p_alter_add_col									-- add newcol
	SELECT SUM(newcol) FROM #temptable5605						-- returns 0 as sum
END;
GO
CREATE PROC p_drop AS DROP TABLE #temptable5605;
GO
CREATE PROC p_index_create
AS 
BEGIN
	CREATE INDEX idx ON #temptable5605(generate_series);
	SELECT * FROM enr_view;
END;
GO

CREATE FUNCTION custom_adder(@a INT, @b INT)
RETURNS INT
BEGIN
	RETURN @a + @b;
END;
GO

CREATE PROCEDURE p_def_cons
AS
BEGIN
	DECLARE @tv_def_con TABLE(id INT PRIMARY KEY, a INT IDENTITY, b CHAR(1) DEFAULT 'F' CHECK (b IN ('T', 'F')));
	INSERT INTO @tv_def_con(id, b) VALUES (1, 'T');
	INSERT INTO @tv_def_con(id) VALUES (2);
	INSERT INTO @tv_def_con(id, b) VALUES (3, 'A');
	SELECT * FROM @tv_def_con;
END;
GO

-- SP_EXECUTESQL index creation on temp tables
CREATE PROCEDURE p_sp_executesql_index
AS
BEGIN
    CREATE TABLE #sp_exec_temp (a INT, b VARCHAR(50));
    INSERT INTO #sp_exec_temp VALUES (1, 'one'), (2, 'two'), (3, 'three');
    
    DECLARE @SQL NVARCHAR(MAX) = 'CREATE INDEX idx_sp_exec ON #sp_exec_temp(a)';
    EXEC SP_EXECUTESQL @SQL;
    
    SELECT * FROM #sp_exec_temp WHERE a = 2;
    
    DROP INDEX idx_sp_exec ON #sp_exec_temp;
    
    SELECT * FROM #sp_exec_temp ORDER BY a;
    
    DROP TABLE #sp_exec_temp;
END;
GO

-- SP_EXECUTESQL ALTER TABLE ADD column that creates toast table
CREATE PROCEDURE p_sp_executesql_toast
AS
BEGIN
    CREATE TABLE #sp_exec_toast_temp (a INT, b VARCHAR(10));
    INSERT INTO #sp_exec_toast_temp VALUES (1, 'test');
    
    DECLARE @SQL NVARCHAR(MAX) = 'ALTER TABLE #sp_exec_toast_temp ADD large_col VARCHAR(MAX)';
    EXEC SP_EXECUTESQL @SQL;
    
    UPDATE #sp_exec_toast_temp SET large_col = REPLICATE('x', 5000) WHERE a = 1;
    
    SELECT a, b, LEN(large_col) as large_col_len FROM #sp_exec_toast_temp;
    
    DROP TABLE #sp_exec_toast_temp;
END;
GO