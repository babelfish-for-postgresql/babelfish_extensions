CREATE VIEW enr_view AS
    SELECT
        CASE
            WHEN relname LIKE '#pg_toast%' AND relname LIKE '%index%' THEN '#pg_toast_#oid_masked#_index'
            WHEN relname LIKE '#pg_toast%' THEN '#pg_toast_#oid_masked#'
            ELSE relname
        END AS relname
    FROM sys.babelfish_get_enr_list()
GO

CREATE TYPE temp_table_type FROM int
GO

CREATE PROCEDURE test_rollback_in_proc AS
BEGIN
    CREATE TABLE #t1(a int)
    INSERT INTO #t1 values (6)
    BEGIN TRAN;
        ALTER TABLE #t1 ADD b varchar(50)
        TRUNCATE TABLE #t1
        INSERT INTO #t1 VALUES (1, 'two')
        select * from #t1
        DROP TABLE #t1
        CREATE TABLE #t1(a varchar(100))
        INSERT INTO #t1 VALUES ('three')
        select * from #t1

        CREATE TABLE #t2(b varchar(50), a int identity primary key, )
        INSERT INTO #t2 VALUES ('four')
        SELECT * FROM #t2
        DROP TABLE #t2
    ROLLBACK;
    SELECT * FROM #t1
    SELECT * FROM #t2
END
GO

CREATE PROCEDURE implicit_rollback_in_proc AS 
BEGIN
    CREATE TABLE #t1(a int)
    ALTER TABLE #t1 ADD b varchar(50)
    INSERT INTO #t1 VALUES (1, 'two')
    select * from #t1
    DROP TABLE #t1
    CREATE TABLE #t1(a varchar(100))
    INSERT INTO #t1 VALUES ('three')
    select * from #t1

    CREATE TABLE #t2(b varchar(50), a int identity primary key, )
    INSERT INTO #t2 VALUES ('four')
    SELECT * FROM #t2
    DROP TABLE #t2

    INSERT INTO #t1 values (1, 2, 3)
    SELECT * FROM #t1
    SELECT * FROM #t2
END
GO

CREATE PROCEDURE tv_base_rollback AS
BEGIN
    DECLARE @tv TABLE (a int)
    INSERT INTO temp_tab_rollback_mytab VALUES (1)
    INSERT INTO @tv VALUES (1)
END
GO

CREATE PROCEDURE tv_tt_no_error AS
BEGIN
    DECLARE @tv TABLE (a int)
    CREATE TABLE #t1 (a int)
    INSERT INTO temp_tab_rollback_mytab VALUES (1)
    INSERT INTO @tv VALUES (1)
    INSERT INTO #t1 VALUES (1)
END
GO

CREATE PROCEDURE tv_mapped_error AS 
BEGIN 
    BEGIN TRAN 
        CREATE TABLE #t1 (a INT, b AS a + 1) 
        INSERT INTO #t1 (a) VALUES (1) 
        ALTER TABLE #t1 ADD CONSTRAINT constraint1 DEFAULT 1 FOR b 
    COMMIT TRAN 
END
GO

CREATE PROCEDURE tv_unmapped_error AS 
BEGIN 
    BEGIN TRAN 
        CREATE TABLE #t1 (a INT, b AS a + 1) 
        INSERT INTO #t1 (a) VALUES (1) 
        SELECT * FROM t2 
    COMMIT TRAN 
END
GO

CREATE FUNCTION func_get_sum_temp(@max_a int)
RETURNS int
AS
BEGIN
    DECLARE @result int;
    SELECT @result = SUM(c) FROM #t_func_idx WHERE a <= @max_a;
    RETURN @result;
END
GO

-- Function with COUNT aggregation
CREATE FUNCTION func_get_count_temp(@min_b int)
RETURNS int
AS
BEGIN
    DECLARE @result int;
    SELECT @result = COUNT(*) FROM #t_func_idx WHERE b >= @min_b;
    RETURN @result;
END
GO

-- Function with MIN/MAX aggregation
CREATE FUNCTION func_get_min_max_temp(@col char(1))
RETURNS int
AS
BEGIN
    DECLARE @result int;
    IF @col = 'a'
        SELECT @result = MAX(a) - MIN(a) FROM #t_func_idx;
    ELSE IF @col = 'b'
        SELECT @result = MAX(b) - MIN(b) FROM #t_func_idx;
    ELSE
        SELECT @result = MAX(c) - MIN(c) FROM #t_func_idx;
    RETURN @result;
END
GO

CREATE PROCEDURE test_temp_table_drop_intermediate_idx AS
BEGIN
    CREATE TABLE #t_procedure(a int default 1, b bigint primary key, c int);
    CREATE INDEX #idx1 ON #t_procedure(a);
    CREATE INDEX #idx2 ON #t_procedure(a,b);
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
    DROP INDEX #idx1 ON #t_procedure;
    INSERT INTO #t_procedure(a, b, c) VALUES (4, 100, 2);
    SELECT * FROM #t_procedure;
END
GO

-- Procedure to test ALTER TABLE + INDEX + TRUNCATE (cache lookup fix)
CREATE PROCEDURE test_alter_index_truncate_cache_fix
AS
BEGIN
    SET XACT_ABORT ON

    CREATE TABLE #t0_qdomqw (id int, name varchar(100) COLLATE polish_cs_as)

    INSERT INTO #t0_qdomqw (id, name) VALUES (1282566819, 'geskxo')

    BEGIN TRANSACTION
        ALTER TABLE #t0_qdomqw ADD col_def_estp int DEFAULT 4
        UPDATE #t0_qdomqw SET name = 'slukgofiuazhigik' WHERE id IS NOT NULL
        SELECT * FROM #t0_qdomqw
        CREATE INDEX idx_eefi ON #t0_qdomqw (id)
        CREATE INDEX idx_eipj ON #t0_qdomqw (id)
    COMMIT TRANSACTION

    TRUNCATE TABLE #t0_qdomqw

    SELECT * FROM #t0_qdomqw

    DROP TABLE #t0_qdomqw

    SET XACT_ABORT OFF
END
GO
