----------------------------------------------------------
-- Nested transactions
----------------------------------------------------------
BEGIN TRANSACTION T1
    CREATE TABLE #t1(a varchar(16))
    INSERT INTO #t1 VALUES ('t1')
    SAVE TRANSACTION T2
        INSERT INTO #t1 VALUES ('t2')
        SAVE TRANSACTION T3
            INSERT INTO #t1 VALUES ('t3')
            SAVE TRANSACTION T4
                INSERT INTO #t1 VALUES ('t4')
                SELECT * FROM #t1
            ROLLBACK TRANSACTION T4
            SELECT * FROM #t1
        ROLLBACK TRANSACTION T3
        SELECT * FROM #t1
    ROLLBACK TRANSACTION T2
    SELECT * FROM #t1
ROLLBACK TRANSACTION T1
SELECT * FROM #t1
GO

SELECT * FROM enr_view;
GO

BEGIN TRANSACTION T1
    SAVE TRANSACTION S2
        create table #t3(a int)
        create table #t4(a int identity primary key, b varchar(50))
        insert into #t3 values (5)
        insert into #t4 values ('six')
        SELECT * FROM #t3
        SELECT * FROM #t4
        SELECT * FROM enr_view;
    ROLLBACK TRANSACTION S2
    SELECT * FROM enr_view;
COMMIT
GO

BEGIN TRANSACTION T1
    CREATE TABLE #t1(a int)
    SAVE TRANSACTION S1
        DROP TABLE #t1
        CREATE TABLE #t2(a int)
        SAVE TRANSACTION S2
            DROP TABLE #t2
            CREATE TABLE #t3(a int)
            SAVE TRANSACTION S3
            DROP TABLE #t3
    ROLLBACK TRANSACTION S1
COMMIT
GO

-- Should be just #t1. 
SELECT * FROM enr_view;
GO

DROP TABLE #t1
GO

BEGIN TRANSACTION T1
    CREATE TABLE #t1(a int)
    SAVE TRANSACTION S1
        DROP TABLE #t1
        CREATE TABLE #t2(a int)
        SAVE TRANSACTION S2
            DROP TABLE #t2
            CREATE TABLE #t3(a int)
            SAVE TRANSACTION S3
            DROP TABLE #t3
    ROLLBACK TRANSACTION S1
ROLLBACK
GO

-- Should be empty. 
SELECT * FROM enr_view;
GO

CREATE TABLE #t1(a int)
GO
BEGIN TRANSACTION T1
    SAVE TRANSACTION s1
        DROP TABLE #t1
        CREATE TABLE #t1(a int identity primary key)  
        SAVE TRANSACTION s2
            DROP TABLE #t1
            CREATE TABLE #t1(a varchar(1000))
            SAVE TRANSACTION S3
                DROP TABLE #t1
    ROLLBACK TRANSACTION s1
COMMIT
GO

SELECT * FROM #t1
GO

DROP TABLE #t1
GO

----------------------------------------------------------
-- General Subtransaction tests
----------------------------------------------------------
BEGIN TRANSACTION T1
    CREATE TABLE #t1(a int primary key, b varchar(16))
    SAVE TRANSACTION T2
        INSERT INTO #t1 VALUES (1, 't2')
        SAVE TRANSACTION T3
            UPDATE #t1 SET a = 2 WHERE a = 1
            SELECT * FROM #t1
            SAVE TRANSACTION T4
                DROP TABLE #t1
            ROLLBACK TRANSACTION T4
        ROLLBACK TRANSACTION T3
        SELECT * FROM #t1
    ROLLBACK TRANSACTION T2
    select * from enr_view
    DROP TABLE #t1
GO

-- Simple nested savepoint rollback
BEGIN TRAN
    CREATE TABLE #t1_exists(a int)
    SAVE TRAN save1
        CREATE TABLE #t2(a int)
        SAVE TRAN save2
            CREATE TABLE #t3(a int)
    ROLLBACK TRAN save1
    CREATE TABLE #t2_exists(a int)
COMMIT
GO

SELECT * FROM enr_view
GO

DROP TABLE #t1_exists
DROP TABLE #t2_exists
GO

-- Multiple savepoint rollback in one xact
BEGIN TRAN 
    CREATE TABLE #t1(a int identity primary key)
    SAVE TRAN save1
        CREATE TABLE #t2(a int identity primary key, b varchar)
        SAVE TRAN save2
            DROP TABLE #t2
            DROP TABLE #t1
    ROLLBACK TRAN save1
    CREATE TABLE #t3(a varchar, b int identity primary key)
    SAVE TRAN save3
        CREATE TABLE #t4(a int identity primary key, b varchar)
        SAVE TRAN save4
            DROP TABLE #t4
            DROP TABLE #t3
    ROLLBACK TRAN save3
    CREATE TABLE #t5(a int)
COMMIT
GO

SELECT * FROM enr_view
GO

SELECT * FROM #t1
GO

SELECT * FROM #t3
GO

SELECT * FROM #t5
GO

DROP TABLE #t1
DROP TABLE #t3
DROP TABLE #t5
GO

-- Multiple savepoint rollback in one xact with entire rollback

BEGIN TRAN 
    CREATE TABLE #t1(a int identity primary key)
    SAVE TRAN save1
        CREATE TABLE #t2(a int identity primary key, b varchar)
        SAVE TRAN save2
            DROP TABLE #t2
            DROP TABLE #t1
    ROLLBACK TRAN save1
    CREATE TABLE #t3(a varchar, b int identity primary key)
    SAVE TRAN save3
        CREATE TABLE #t4(a int identity primary key, b varchar)
        SAVE TRAN save4
            DROP TABLE #t4
            DROP TABLE #t3
    ROLLBACK TRAN save3
    CREATE TABLE #t5(a int)
ROLLBACK
GO

SELECT * FROM enr_view
GO

-- Multiple savepoint rollback entire transaction to beginning

BEGIN TRAN 
    CREATE TABLE #t1(a int identity primary key)
    SAVE TRAN save1
        CREATE TABLE #t2(a int identity primary key, b varchar)
        SAVE TRAN save2
            DROP TABLE #t2
            DROP TABLE #t1
    ROLLBACK TRAN save1
    CREATE TABLE #t3(a varchar, b int identity primary key)
    SAVE TRAN save3
        CREATE TABLE #t4(a int identity primary key, b varchar)
        SAVE TRAN save4
            DROP TABLE #t4
            DROP TABLE #t3
    ROLLBACK
GO

SELECT * FROM enr_view
GO

----------------------------------------------------------
-- Index CREATE/DROP in subtransaction
----------------------------------------------------------

-- CREATE TABLE

CREATE TABLE #temp_table_rollback_t5(a int, b varchar, c int, d int)
GO

BEGIN TRAN T1
    SAVE TRANSACTION S2
        CREATE INDEX #temp_table_rollback_t5_idx1 ON #temp_table_rollback_t5(a)
        INSERT INTO #temp_table_rollback_t5 VALUES (1, 'a', 2, 3)
    ROLLBACK TRANSACTION S2
COMMIT
GO

SELECT * FROM #temp_table_rollback_t5
GO

INSERT INTO #temp_table_rollback_t5 VALUES (2, 'b', 3, 4)
GO

BEGIN TRAN
    CREATE INDEX #temp_table_rollback_t5_idx1 ON #temp_table_rollback_t5(a)
ROLLBACK
GO

SELECT * FROM #temp_table_rollback_t5
GO

CREATE INDEX #temp_table_rollback_t5_idx1 ON #temp_table_rollback_t5(a)
GO

SELECT * FROM #temp_table_rollback_t5
GO

DROP INDEX #temp_table_rollback_t5_idx1 ON #temp_table_rollback_t5
GO

SELECT * FROM enr_view
GO

-- DROP INDEX

CREATE INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5(b)
GO

BEGIN TRAN T1
    SAVE TRANSACTION S2
        DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
        INSERT INTO #temp_table_rollback_t5 VALUES (3, 'c', 4, 5)
    ROLLBACK TRANSACTION S2
COMMIT
GO

SELECT * FROM #temp_table_rollback_t5
GO

BEGIN TRAN
    DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
ROLLBACK
GO

DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
GO

CREATE INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5(b)
GO

DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
GO

-- CREATE + DROP

BEGIN TRAN T1
    SAVE TRANSACTION S2
        CREATE INDEX #temp_table_rollback_t5_idx3 ON #temp_table_rollback_t5(c)
        DROP INDEX #temp_table_rollback_t5_idx3 ON #temp_table_rollback_t5
    ROLLBACK TRANSACTION S2
COMMIT
GO

SELECT * FROM #temp_table_rollback_t5
GO

BEGIN TRAN T1
    CREATE INDEX #temp_table_rollback_t5_idx3 ON #temp_table_rollback_t5(c)
    DROP INDEX #temp_table_rollback_t5_idx3 ON #temp_table_rollback_t5
ROLLBACK
GO

SELECT * FROM #temp_table_rollback_t5
GO

CREATE INDEX #temp_table_rollback_t5_idx3 ON #temp_table_rollback_t5(c)
DROP INDEX #temp_table_rollback_t5_idx3 ON #temp_table_rollback_t5
GO

SELECT * FROM #temp_table_rollback_t5
GO

-- DROP + CREATE

CREATE INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5(d)
GO

BEGIN TRAN T1
    SAVE TRANSACTION S2
        DROP INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5
        CREATE INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5(c)
    ROLLBACK TRANSACTION S2
COMMIT
GO

SELECT * FROM #temp_table_rollback_t5
GO

BEGIN TRAN T1
    DROP INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5
    CREATE INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5(c)
ROLLBACK
GO

SELECT * FROM #temp_table_rollback_t5
GO

DROP INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5
CREATE INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5(c)
GO

SELECT * FROM #temp_table_rollback_t5
GO

DROP TABLE #temp_table_rollback_t5
GO

SELECT * FROM enr_view
GO

-- Nested index creation

BEGIN TRAN 
    CREATE TABLE #t1(a int identity primary key, b int)
    SAVE TRAN save1
        CREATE TABLE #t2(a int identity primary key, b int)
        CREATE INDEX #idx1 ON #t1(b)
        SAVE TRAN save2
            CREATE INDEX #idx2 ON #t2(b)
    ROLLBACK TRAN save1
    SELECT * FROM #t1
    CREATE TABLE #t3(a varchar, b int identity primary key)
    SAVE TRAN save3
        CREATE TABLE #t4(a int identity primary key, b varchar)
        CREATE INDEX #idx3 ON #t3(b)
        SAVE TRAN save4
            CREATE INDEX #idx4 ON #t4(b)
            DROP INDEX #idx4 ON #t4
            DROP INDEX #idx3 ON #t3
        ROLLBACK TRAN save4
    ROLLBACK TRAN save3
    COMMIT
GO

SELECT * FROM enr_view
GO

DROP TABLE #t1
DROP TABLE #t3
GO

SELECT * FROM enr_view
GO

----------------------------------------------------------
-- Subtransactions with procedures
----------------------------------------------------------

exec test_nested_rollback_in_proc
GO

SELECT * FROM enr_view
GO

-- Implicit rollback to top level transaction
BEGIN TRANSACTION
    CREATE TABLE #outer_tab1(a int)
    SELECT * FROM enr_view
    exec implicit_rollback_in_proc
COMMIT
GO

-- This table is rolled back due to error in procedure
select * from #outer_tab1
GO

SELECT * FROM enr_view
GO

----------------------------------------------------------
-- implicit rollback with postgres builtin procedures
----------------------------------------------------------
BEGIN TRANSACTION
    CREATE TABLE #t1(a int)
    SELECT UPPER(abc) -- Should fail 
COMMIT
GO

BEGIN TRANSACTION
    CREATE TABLE #t2(a int)
    SAVE TRAN s1
        SELECT UPPER(abc)
COMMIT
GO

CREATE PROCEDURE my_bad_proc AS
BEGIN
    SELECT UPPER(abc)
END
GO

BEGIN TRANSACTION
    CREATE TABLE #t3(a int)
    SAVE TRAN s1
        exec my_bad_proc
COMMIT
GO

DROP PROCEDURE my_bad_proc
GO

SELECT * FROM #t1
GO

SELECT * FROM #t2
GO

SELECT * FROM #t3
GO

SELECT * FROM enr_view
GO

