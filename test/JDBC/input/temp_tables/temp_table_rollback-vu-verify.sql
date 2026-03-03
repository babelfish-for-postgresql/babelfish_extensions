-- pg_class, pg_type, pg_depend, pg_attribute, pg_constraint, pg_index, pg_sequence are all covered by below tests. 

-------------------------------
-- Temp Table CREATE + ROLLBACK
-------------------------------
BEGIN TRAN
CREATE TABLE #temp_table_rollback_t1(a int identity primary key, b int)
select * from enr_view
ROLLBACK
GO

-- Should be empty
select * from enr_view
GO

-- Should not exist
SELECT * FROM #temp_table_rollback_t1
GO

BEGIN TRAN
CREATE TABLE #t1(a int)
INSERT INTO #t1 VALUES (1)
SELECT * FROM #t1
ROLLBACK
GO

CREATE TABLE #t1(a int, b int)
GO

INSERT INTO #t1 VALUES (1, 1)
INSERT INTO #t1 VALUES (2, 1)
GO

INSERT INTO #t1 VALUES (3, 1)
GO

SELECT * FROM #t1
GO

BEGIN TRAN
UPDATE #t1 SET a = a + 1 WHERE b = 1
SELECT * FROM #t1
ROLLBACK
GO

SELECT * FROM #t1

DROP TABLE #t1
GO

-----------------------------
-- Temp Table DROP + ROLLBACK
-----------------------------
CREATE TABLE #temp_table_rollback_t1(a int identity primary key, b int)
go

INSERT INTO #temp_table_rollback_t1 VALUES (1)
GO

BEGIN TRAN
DROP TABLE #temp_table_rollback_t1
ROLLBACK
go

-- Should still exist
select * from enr_view
GO

-- Should show results
BEGIN TRAN
select * from #temp_table_rollback_t1
COMMIT
go

-- Should not error
BEGIN TRAN
DROP TABLE #temp_table_rollback_t1
COMMIT
GO

----------------------------------------------------------
-- ALTER TABLE (BABEL-4912)
----------------------------------------------------------
CREATE TABLE #temp_table_rollback_t1 (a int, b int)
GO

BEGIN TRAN
ALTER TABLE #temp_table_rollback_t1 DROP COLUMN b
ROLLBACK
GO

BEGIN TRAN
ALTER TABLE #temp_table_rollback_t1 ALTER COLUMN b VARCHAR
ROLLBACK
GO

BEGIN TRAN
ALTER TABLE #temp_table_rollback_t1 ALTER COLUMN b VARCHAR
COMMIT
GO

BEGIN TRAN
ALTER TABLE #temp_table_rollback_t1 DROP COLUMN b
COMMIT
GO

DROP TABLE #temp_table_rollback_t1
GO

----------------------------------------------------------
-- Multiple tables in one transaction
----------------------------------------------------------
CREATE TABLE #temp_table_rollback_t1(a int identity primary key, b int, c varchar)
GO

create table #temp_table_rollback_t2(a varchar)
GO

BEGIN TRAN
DROP TABLE #temp_table_rollback_t1
DROP TABLE #temp_table_rollback_t2
ROLLBACK
GO

-- Tables are still visible and usable
select * from enr_view
GO

INSERT INTO #temp_table_rollback_t1 values (1, 'b')
GO

INSERT INTO #temp_table_rollback_t2 values ('c')
GO

SELECT * FROM #temp_table_rollback_t1
GO

SELECT * FROM #temp_table_rollback_t2
GO

BEGIN TRAN
DROP TABLE #temp_table_rollback_t1
DROP TABLE #temp_table_rollback_t2
COMMIT
GO

BEGIN TRAN
    CREATE TABLE #t1(a int)
    ROLLBACK
GO

SELECT * FROM enr_view
go

CREATE TABLE #t1(a int, b int)
GO

CREATE TABLE #t2(c varchar(20), d int)
GO

INSERT INTO #t1 VALUES (1, 1)
INSERT INTO #t1 VALUES (2, 1)
INSERT INTO #t2 VALUES ('abc', 1)
GO

INSERT INTO #t1 VALUES (3, 1)
INSERT INTO #t2 VALUES ('def', 1)
GO

SELECT * FROM #t1
GO

BEGIN TRAN
UPDATE #t1 SET a = a + 1 WHERE b = 1
UPDATE #t2 SET c = 'qed' WHERE d = 1
SELECT * FROM #t1
SELECT * FROM #t2
ROLLBACK
GO

SELECT * FROM #t1
SELECT * FROM #t2
GO

DROP TABLE #t1
DROP TABLE #t2
GO

----------------------------------------------------------
-- Implicit rollback due to error
----------------------------------------------------------
CREATE TABLE #temp_table_rollback_t1(a int primary key, b int, c varchar)
CREATE TABLE #temp_table_rollback_t2(a int)
GO

INSERT INTO #temp_table_rollback_t2 VALUES (1)
GO

-- Transaction will error out
BEGIN TRAN
drop table #temp_table_rollback_t2
insert into #temp_table_rollback_t1 values (1, 1, 1, 1) -- Too many columns, should error out
GO

-- Table + data should still exist, due to implicit rollback. 
SELECT * FROM #temp_table_rollback_t2
GO

-- Duplicate key doesn't cause implicit rollback, so the drop will succeed here. 
BEGIN TRAN
drop table #temp_table_rollback_t2
insert into #temp_table_rollback_t1 values (1, 1, 'a')
insert into #temp_table_rollback_t1 values (1, 1, 'a')
GO

SELECT * FROM #temp_table_rollback_t2
GO

BEGIN TRAN
DROP TABLE #temp_table_rollback_t1
DROP TABLE #temp_table_rollback_t2
COMMIT
GO

SELECT * FROM enr_view;
GO

---------------------------------------------------------------------------
-- Same temp table name in one transaction
---------------------------------------------------------------------------

CREATE TABLE #temp_table_rollback_t3(c1 INT, c2 INT)
GO

BEGIN TRANSACTION
    ALTER TABLE #temp_table_rollback_t3 ADD C3 INT;
    INSERT INTO #temp_table_rollback_t3 VALUES (1, 2, 3)
    DROP TABLE #temp_table_rollback_t3
    CREATE TABLE #temp_table_rollback_t3(c1 INT, c2 INT)
COMMIT
GO

DROP TABLE #temp_table_rollback_t3
GO

CREATE TABLE #temp_table_rollback_t4(c1 INT, c2 CHAR(10))
GO

BEGIN TRANSACTION
    DROP TABLE #temp_table_rollback_t4

    CREATE TABLE #temp_table_rollback_t4(c1 INT, c2 CHAR(10))
    INSERT INTO #temp_table_rollback_t4 VALUES (1, 'one')
    SELECT * FROM #temp_table_rollback_t4 -- should return 1, 'one'
    DROP TABLE #temp_table_rollback_t4

    INSERT INTO #temp_table_rollback_t4 VALUES (2, 'two')
    SELECT * FROM #temp_table_rollback_t4
COMMIT
GO

SELECT * FROM #temp_table_rollback_t4
GO

DROP TABLE #temp_table_rollback_t4
GO

CREATE TABLE #temp_table_rollback_t4(c1 INT, c2 CHAR(10))
GO

BEGIN TRANSACTION T1
ALTER TABLE #temp_table_rollback_t4 ADD C3 INT
DROP TABLE #temp_table_rollback_t4

CREATE TABLE #temp_table_rollback_t4(c1 INT, c2 CHAR(10))
DROP  TABLE #temp_table_rollback_t4

INSERT INTO #temp_table_rollback_t4 VALUES (2, 'two')
COMMIT
GO

DROP TABLE #temp_table_rollback_t4
GO

---------------------------------------------------------------------------
-- Index creation
---------------------------------------------------------------------------
-- Created index in transaction

CREATE TABLE #temp_table_rollback_t5(a int, b varchar, c int, d int)
GO

BEGIN TRAN
    CREATE INDEX #temp_table_rollback_t5_idx1 ON #temp_table_rollback_t5(a)
    INSERT INTO #temp_table_rollback_t5 VALUES (1, 'a', 2, 3)
ROLLBACK
GO

SELECT * FROM #temp_table_rollback_t5
GO

INSERT INTO #temp_table_rollback_t5 VALUES (2, 'b', 3, 4)
GO

BEGIN TRAN
    CREATE INDEX #temp_table_rollback_t5_idx1 ON #temp_table_rollback_t5(a)
    UPDATE #temp_table_rollback_t5 SET b = 'd' WHERE d = 4
    SELECT * FROM #temp_table_rollback_t5
COMMIT
GO

BEGIN TRAN
    UPDATE #temp_table_rollback_t5 SET b = 'e' WHERE d = 4
    SELECT * FROM #temp_table_rollback_t5
ROLLBACK
GO

SELECT * FROM #temp_table_rollback_t5
GO

DROP INDEX #temp_table_rollback_t5_idx1 ON #temp_table_rollback_t5
GO

SELECT * FROM #temp_table_rollback_t5
GO

SELECT * FROM enr_view
GO

-- Drop index in transaction

CREATE INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5(b)
GO

BEGIN TRAN
    DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
    INSERT INTO #temp_table_rollback_t5 VALUES (3, 'c', 4, 5)
COMMIT
GO

SELECT * FROM #temp_table_rollback_t5
GO

BEGIN TRAN
    DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
ROLLBACK
GO

SELECT * FROM #temp_table_rollback_t5
GO

DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
GO

CREATE INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5(b)
GO

DROP INDEX #temp_table_rollback_t5_idx2 ON #temp_table_rollback_t5
GO

SELECT * FROM #temp_table_rollback_t5
GO

-- Create and drop in transaction
BEGIN TRAN
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

-- Drop - Create
CREATE INDEX #temp_table_rollback_t5_idx4 ON #temp_table_rollback_t5(d)
GO

BEGIN TRAN
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

-- DELETE, TRUNCATE

CREATE TABLE #t1(a int identity primary key, b int)
INSERT INTO #t1 VALUES (0)
INSERT INTO #t1 VALUES (1)
INSERT INTO #t1 VALUES (2)
INSERT INTO #t1 VALUES (3)
GO

BEGIN TRAN
    DELETE FROM #t1
    SELECT * FROM #t1
ROLLBACK
GO

SELECT * FROM #t1
GO

-- Truncate should reset IDENTITY. But it should be restored on ROLLBACK.
BEGIN TRAN
    TRUNCATE TABLE #t1
    INSERT INTO #t1 VALUES (1)
    SELECT * FROM #t1
ROLLBACK
GO

INSERT INTO #t1 VALUES (4)
GO

SELECT * FROM #t1
DROP TABLE #t1
GO

---------------------------------------------------------------------------
-- Procedures
---------------------------------------------------------------------------

exec test_rollback_in_proc
GO

BEGIN TRANSACTION
    CREATE TABLE #outer_tab1(a int)
    SELECT * FROM enr_view
    exec implicit_rollback_in_proc
    select * from #outer_tab1
ROLLBACK
GO

CREATE TABLE temp_tab_rollback_mytab(a int)
GO

BEGIN TRAN
CREATE TABLE #t1(a int)
INSERT INTO #t1 VALUES (1)
EXEC tv_base_rollback
DROP TABLE temp_tab_rollback_mytab
ROLLBACK
SELECT * FROM temp_tab_rollback_mytab
GO

BEGIN TRAN
INSERT INTO temp_tab_rollback_mytab VALUES (2)
EXEC tv_tt_no_error
SELECT * FROM temp_tab_rollback_mytab
DROP TABLE temp_tab_rollback_mytab
ROLLBACK
GO

SELECT * FROM temp_tab_rollback_mytab
GO

BEGIN TRAN
INSERT INTO temp_tab_rollback_mytab VALUES (2)
CREATE TABLE #outer_table (a int)
INSERT INTO #outer_table VALUES (1)
EXEC tv_tt_no_error
SELECT * FROM temp_tab_rollback_mytab
DROP TABLE temp_tab_rollback_mytab
ROLLBACK
GO

SELECT * FROM temp_tab_rollback_mytab
GO

SELECT * FROM #outer_table
GO

DROP TABLE temp_tab_rollback_mytab
GO

-- Everything should be rolled back due to error
-- Nothing from the proc should be here either
SELECT * FROM enr_view
GO

---------------------------------------------------------------------------
-- Mixed permanent, TV, temp tables in/out of ENR.
---------------------------------------------------------------------------
-- Mixed create rollback
BEGIN TRAN
    DECLARE @tv TABLE (a1 int)
    CREATE TABLE #temp_table(a2 int)
    CREATE TABLE #temp_table_nonenr(a3 temp_table_type)
ROLLBACK
GO

SELECT * FROM enr_view
GO

-- Mixed insert rollback
DECLARE @tv TABLE (a1 int)
CREATE TABLE perm_table(a2 int)
CREATE TABLE #temp_table(a3 int)
CREATE TABLE #temp_table_nonenr(a3 temp_table_type)
BEGIN TRAN
    INSERT INTO @tv VALUES (1)
    INSERT INTO perm_table VALUES(2)
    INSERT INTO #temp_table VALUES(3)
    INSERT INTO #temp_table_nonenr VALUES (4)
    SELECT * FROM @tv
    SELECT * FROM perm_table
    SELECT * FROM #temp_table
    SELECT * FROM #temp_table_nonenr
ROLLBACK
-- Unaffected by rollback
SELECT * FROM @tv
-- Correctly rolled back
SELECT * FROM perm_table
-- Correctly rolled back
SELECT * FROM #temp_table
SELECT * FROM #temp_table_nonenr
SELECT * FROM enr_view
GO

SELECT * FROM enr_view
DROP TABLE #temp_table
DROP TABLE #temp_table_nonenr
DROP TABLE perm_table
GO

-- Mixed drop rollback
CREATE TABLE #temp_table(a int)
CREATE TABLE perm_table(a int)
CREATE TABLE #temp_table_nonenr(a3 temp_table_type)
GO

BEGIN TRAN
    DECLARE @tv TABLE(a int)
    SELECT * FROM enr_view
    DROP TABLE #temp_table
    DROP TABLE perm_table
    DROP TABLE #temp_table_nonenr
    SELECT * FROM enr_view
ROLLBACK
GO

SELECT * FROM enr_view
GO

DROP TABLE #temp_table
DROP TABLE perm_table
DROP TABLE #temp_table_nonenr
GO

-- Mixed rollback with mapped and unmapped errors
CREATE TABLE temp_table_rollback_t6 (a int)
GO

BEGIN TRY 
    BEGIN TRAN 
        DROP TABLE temp_table_rollback_t6 
        EXEC tv_mapped_error 
    ROLLBACK 
END TRY 
BEGIN CATCH 
    ROLLBACK 
END CATCH
GO

SELECT @@trancount
SELECT * FROM temp_table_rollback_t6
GO

BEGIN TRY 
    BEGIN TRAN 
        DROP TABLE temp_table_rollback_t6 
        EXEC tv_unmapped_error 
    ROLLBACK 
END TRY 
BEGIN CATCH 
    ROLLBACK 
END CATCH
GO

SELECT @@trancount
SELECT * FROM temp_table_rollback_t6
GO

DROP TABLE temp_table_rollback_t6
GO

---------------------------------------------------------------------------
-- Multiple COMMIT/ROLLBACK
---------------------------------------------------------------------------

CREATE TABLE #t1(a int)
GO

BEGIN TRAN
INSERT INTO #t1 VALUES (1)
COMMIT

BEGIN TRAN
UPDATE #t1 SET a = 2 WHERE a = 1
COMMIT

BEGIN TRAN
DROP TABLE #t1
ROLLBACK
GO

SELECT * FROM #t1
DROP TABLE #t1
GO

------------------------

BEGIN TRAN
CREATE TABLE #t1(a int)
COMMIT

BEGIN TRAN
INSERT INTO #t1 VALUES (1)
CREATE TABLE #t2(a int identity primary key, b varchar)
COMMIT

BEGIN TRAN
DROP TABLE #t1
CREATE INDEX #t2_idx ON #t2(b)
INSERT INTO #t2 VALUES ('a')
ROLLBACK

BEGIN TRAN
CREATE INDEX #t2_idx ON #t2(b)
INSERT INTO #t2 VALUES ('b')
SELECT * FROM #t1
SELECT * FROM #t2
DROP TABLE #t1
DROP TABLE #t2
COMMIT
GO

----------------------------

BEGIN TRAN 
CREATE TABLE #t1(a int)
CREATE TABLE #t2(a int)
ROLLBACK

BEGIN TRAN
CREATE TABLE #t1(a varchar)
CREATE TABLE #t2(a varchar)
COMMIT

BEGIN TRAN
DROP TABLE #t1
DROP TABLE #t2
COMMIT

BEGIN TRAN
CREATE TABLE #t1(a int)
CREATE TABLE #t2(a int)
INSERT INTO #t1 VALUES (1)
ROLLBACK

SELECT * FROM enr_view
GO

----------------------------

BEGIN TRAN
CREATE TABLE #t1 (a int)
COMMIT

BEGIN TRAN
DROP TABLE #t1 
ROLLBACK

BEGIN TRAN
DROP TABLE #t1
ROLLBACK

BEGIN TRAN
DROP TABLE #t1
ROLLBACK

BEGIN TRAN
INSERT INTO #t1 VALUES (1)
SELECT * FROM #t1
COMMIT
GO

DROP TABLE #t1
GO

---------------------------------------------------------------------------
-- Cursor
---------------------------------------------------------------------------

-- Temp into permanent
DECLARE @v int
CREATE TABLE #t(a int)
insert into #t values (1)
insert into #t values (2)
insert into #t values (3)
CREATE TABLE perm_tab(a int)

DECLARE cur CURSOR FOR (select a from #t)
OPEN cur
WHILE @@fetch_status = 0
BEGIN
    fetch cur into @v
    insert into perm_tab values (@v)
END
CLOSE cur
DEALLOCATE cur

SELECT * FROM perm_tab
GO

-- Permanent into temp
DECLARE @v int
CREATE TABLE #t2(b int)
DECLARE cur CURSOR FOR (select a from perm_tab)
OPEN cur
WHILE @@fetch_status = 0
BEGIN
    fetch cur into @v
    insert into #t2 values (@v)
END
CLOSE cur
DEALLOCATE cur

SELECT * FROM #t2
GO

DROP TABLE perm_tab
GO

---------------------------------------------------------------------------
-- Trigger (can't be created on temp tables)
---------------------------------------------------------------------------

CREATE TABLE basetab(a int, b int)
GO

CREATE TRIGGER basetrig_insert ON basetab 
    FOR INSERT, UPDATE, DELETE
AS
    INSERT INTO #t1 VALUES (1)
GO

CREATE TABLE #t1(a int)
GO

BEGIN TRAN
    INSERT INTO basetab VALUES (1, 2)
    SELECT * FROM #t1
ROLLBACK
GO

SELECT * FROM basetab
SELECT * FROM #t1
GO

CREATE TRIGGER basetrig_rollback ON basetab
    FOR INSERT, UPDATE, DELETE
AS
    INSERT INTO #t1 VALUES (2)
    ROLLBACK
GO

INSERT INTO basetab VALUES (3, 4)
GO

SELECT * FROM #t1
GO

DROP TRIGGER basetrig_insert
GO

DROP TABLE basetab
GO

--------------------------------------------
-- DROPPING INTERMEDIATE INDEXES
--------------------------------------------

-- Setup with PRIMARY KEY 
CREATE TABLE #t_intermediate(a int PRIMARY KEY, b int, c int);
go

CREATE INDEX #idx1_intermediate ON #t_intermediate(b);
go

CREATE INDEX #idx2_intermediate ON #t_intermediate(c);
go

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
go

DROP INDEX #idx1_intermediate ON #t_intermediate;
go

INSERT INTO #t_intermediate VALUES (1, 2, 3);
go

SELECT * FROM #t_intermediate;
go

DROP TABLE #t_intermediate;
go

-- Create temp table with multiple indexes including composite
CREATE TABLE #t1_intermediate(a int, b int, c int);
go

CREATE INDEX #idx1_intermediate ON #t1_intermediate(a);
go

CREATE INDEX #idx2_intermediate ON #t1_intermediate(a, b);
go

CREATE INDEX #idx3_intermediate ON #t1_intermediate(c);
go

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
go

-- Drop intermediate composite index
DROP INDEX #idx2_intermediate ON #t1_intermediate;
go

INSERT INTO #t1_intermediate VALUES (1, 2, 3), (4, 5, 6), (7, 8, 9);
go

INSERT INTO #t1_intermediate VALUES (10, 20, 30);
go

INSERT INTO #t1_intermediate (a, b, c) VALUES (100, 200, 300);
go

INSERT INTO #t1_intermediate (a, c, b) VALUES (11, 33, 22);
go

SELECT * FROM #t1_intermediate;
go

SELECT * FROM #t1_intermediate WHERE a = 4;
go

SELECT * FROM #t1_intermediate WHERE b = 20;
go

SELECT * FROM #t1_intermediate WHERE c = 33;
go

SELECT * FROM #t1_intermediate ORDER BY a;
go

SELECT COUNT(*) AS total_rows, SUM(a) AS sum_a, AVG(b) AS avg_b, MAX(c) AS max_c FROM #t1_intermediate;
go

UPDATE #t1_intermediate SET b = 999 WHERE a = 1;
go

SELECT * FROM #t1_intermediate WHERE a = 1;
go

UPDATE #t1_intermediate SET c = c + 1000 WHERE a > 5;
go

SELECT * FROM #t1_intermediate WHERE a > 5 ORDER BY a;
go

UPDATE #t1_intermediate SET a = 111 WHERE a = 100;
go

SELECT * FROM #t1_intermediate ORDER BY a;
go

DELETE FROM #t1_intermediate WHERE a = 4;
go

SELECT * FROM #t1_intermediate ORDER BY a;
go

DELETE FROM #t1_intermediate WHERE c > 1000;
go

SELECT * FROM #t1_intermediate ORDER BY a;
go

INSERT INTO #t1_intermediate VALUES (50, 60, 70), (80, 90, 100);
go

SELECT * FROM #t1_intermediate ORDER BY a;
go

SELECT a, b FROM #t1_intermediate WHERE c < 100 ORDER BY b DESC;
go

SELECT COUNT(*) FROM #t1_intermediate;
go

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
go

DROP TABLE #t1_intermediate;
go

---------------------------------------------------------------------------
-- Drop Index Inside Transaction (ROLLBACK/COMMIT scenarios)
---------------------------------------------------------------------------
CREATE TABLE #t_drop_idx_txn(a int, b int, c int, d int);
GO

CREATE INDEX #idx_a ON #t_drop_idx_txn(a);
GO

CREATE INDEX #idx_b ON #t_drop_idx_txn(b);
GO

CREATE INDEX #idx_c ON #t_drop_idx_txn(c);
GO

INSERT INTO #t_drop_idx_txn VALUES (1, 10, 100, 1000), (2, 20, 200, 2000), (3, 30, 300, 3000);
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop single index and ROLLBACK
BEGIN TRAN
    DROP INDEX #idx_a ON #t_drop_idx_txn
    INSERT INTO #t_drop_idx_txn VALUES (4, 40, 400, 4000)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
ROLLBACK
GO

SELECT * FROM #t_drop_idx_txn ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop single index and COMMIT
BEGIN TRAN
    DROP INDEX #idx_a ON #t_drop_idx_txn
    INSERT INTO #t_drop_idx_txn VALUES (4, 40, 400, 4000)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
COMMIT
GO

SELECT * FROM #t_drop_idx_txn ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop multiple indexes and ROLLBACK
BEGIN TRAN
    DROP INDEX #idx_b ON #t_drop_idx_txn
    DROP INDEX #idx_c ON #t_drop_idx_txn
    UPDATE #t_drop_idx_txn SET b = 999 WHERE a = 1
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
ROLLBACK
GO

SELECT * FROM #t_drop_idx_txn ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop multiple indexes and COMMIT
BEGIN TRAN
    DROP INDEX #idx_b ON #t_drop_idx_txn
    DROP INDEX #idx_c ON #t_drop_idx_txn
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
COMMIT
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

DROP TABLE #t_drop_idx_txn;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

---------------------------------------------------------------------------
-- Create Index Inside Transaction (ROLLBACK/COMMIT scenarios)
---------------------------------------------------------------------------
CREATE TABLE #t_create_idx_txn(a int, b int, c int);
GO

INSERT INTO #t_create_idx_txn VALUES (1, 10, 100), (2, 20, 200), (3, 30, 300);
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Create single index and ROLLBACK
BEGIN TRAN
    CREATE INDEX #idx_create_a ON #t_create_idx_txn(a)
    INSERT INTO #t_create_idx_txn VALUES (4, 40, 400)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
ROLLBACK
GO

SELECT * FROM #t_create_idx_txn ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Create index and COMMIT
BEGIN TRAN
    CREATE INDEX #idx_create_a ON #t_create_idx_txn(a)
    INSERT INTO #t_create_idx_txn VALUES (4, 40, 400)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
COMMIT
GO

SELECT * FROM #t_create_idx_txn ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

DROP TABLE #t_create_idx_txn;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

---------------------------------------------------------------------------
-- Create and Drop Index Combinations in Transactions
---------------------------------------------------------------------------
CREATE TABLE #t_idx_combo(a int, b int, c int);
GO

INSERT INTO #t_idx_combo VALUES (1, 10, 100), (2, 20, 200), (3, 30, 300);
GO

CREATE INDEX #idx_combo_b ON #t_idx_combo(b);
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop existing index, create new one, ROLLBACK
BEGIN TRAN
    DROP INDEX #idx_combo_b ON #t_idx_combo
    CREATE INDEX #idx_combo_c ON #t_idx_combo(c)
    INSERT INTO #t_idx_combo VALUES (4, 40, 400)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
ROLLBACK
GO

SELECT * FROM #t_idx_combo ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop existing index, create new one, COMMIT
BEGIN TRAN
    DROP INDEX #idx_combo_b ON #t_idx_combo
    CREATE INDEX #idx_combo_c ON #t_idx_combo(c)
    INSERT INTO #t_idx_combo VALUES (4, 40, 400)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
COMMIT
GO

SELECT * FROM #t_idx_combo ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

DROP TABLE #t_idx_combo;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

---------------------------------------------------------------------------
-- Drop Index with DML Operations in Transaction
---------------------------------------------------------------------------
CREATE TABLE #t_idx_dml(a int, b int, c int);
GO

CREATE INDEX #idx_dml_a ON #t_idx_dml(a);
GO

INSERT INTO #t_idx_dml VALUES (1, 10, 100), (2, 20, 200), (3, 30, 300);
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop index with DML and ROLLBACK
BEGIN TRAN
    DROP INDEX #idx_dml_a ON #t_idx_dml
    INSERT INTO #t_idx_dml VALUES (4, 40, 400)
    UPDATE #t_idx_dml SET c = 999 WHERE a = 1
    DELETE FROM #t_idx_dml WHERE a = 2
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
ROLLBACK
GO

SELECT * FROM #t_idx_dml ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Drop index with DML and COMMIT
BEGIN TRAN
    DROP INDEX #idx_dml_a ON #t_idx_dml
    INSERT INTO #t_idx_dml VALUES (4, 40, 400)
    UPDATE #t_idx_dml SET c = 999 WHERE a = 1
    DELETE FROM #t_idx_dml WHERE a = 2
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
COMMIT
GO

SELECT * FROM #t_idx_dml ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

DROP TABLE #t_idx_dml;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

---------------------------------------------------------------------------
-- Subtransaction Rollback with Index Operations
---------------------------------------------------------------------------
CREATE TABLE #t_idx_subtxn(a int, b int, c int);
GO

INSERT INTO #t_idx_subtxn VALUES (1, 10, 100), (2, 20, 200);
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

-- Nested savepoints with index operations
BEGIN TRAN
    CREATE INDEX #idx_subtxn_a ON #t_idx_subtxn(a)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
    
    SAVE TRANSACTION sp1
    
    CREATE INDEX #idx_subtxn_b ON #t_idx_subtxn(b)
    INSERT INTO #t_idx_subtxn VALUES (3, 30, 300)
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
    
    ROLLBACK TRANSACTION sp1
    
    SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
    
    INSERT INTO #t_idx_subtxn VALUES (4, 40, 400)
COMMIT
GO

SELECT * FROM #t_idx_subtxn ORDER BY a;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

DROP TABLE #t_idx_subtxn;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO


---------------------------------------------------------------------------
-- FUNCTION: Read from Temp Table After Dropping Intermediate Index
-- Note: DDL not allowed inside functions, drop happens outside
---------------------------------------------------------------------------
CREATE TABLE #t_func_idx(a int, b int, c int);
GO

CREATE INDEX #idx_f1 ON #t_func_idx(a);
GO

CREATE INDEX #idx_f2 ON #t_func_idx(b);
GO

CREATE INDEX #idx_f3 ON #t_func_idx(c);
GO

INSERT INTO #t_func_idx VALUES (1, 10, 100), (2, 20, 200), (3, 30, 300);
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

SELECT func_get_sum_temp(3) AS sum_before;
GO

SELECT func_get_count_temp(10) AS count_before;
GO

SELECT func_get_min_max_temp('a') AS minmax_a_before;
GO

SELECT func_get_min_max_temp('c') AS minmax_c_before;
GO

DROP INDEX #idx_f2 ON #t_func_idx;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

SELECT func_get_sum_temp(3) AS sum_after;
GO

SELECT func_get_count_temp(10) AS count_after;
GO

SELECT func_get_min_max_temp('a') AS minmax_a_after;
GO

SELECT func_get_min_max_temp('c') AS minmax_c_after;
GO

INSERT INTO #t_func_idx VALUES (4, 40, 400);
GO

SELECT func_get_sum_temp(4) AS sum_final;
GO

SELECT func_get_count_temp(20) AS count_final;
GO

SELECT func_get_min_max_temp('a') AS minmax_a_final;
GO

SELECT func_get_min_max_temp('c') AS minmax_c_final;
GO

SELECT * FROM #t_func_idx ORDER BY a;
GO

DROP TABLE #t_func_idx;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

---------------------------------------------------------------------------
-- PROCEDURE: Create temp table with indexes and drop intermediate index
---------------------------------------------------------------------------
EXEC test_temp_table_drop_intermediate_idx;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

---------------------------------------------------------------------------
-- Temp Tables with multiple defaults
---------------------------------------------------------------------------

CREATE TABLE #test1_defaults (
col1 INT DEFAULT 10,
col2 INT DEFAULT 20,
col3 INT DEFAULT 30,
col4 INT DEFAULT 40 );
go

INSERT INTO #test1_defaults (col1) VALUES (1);
go

SELECT * FROM #test1_defaults;
go

INSERT INTO #test1_defaults DEFAULT VALUES;
go

SELECT * FROM #test1_defaults;
go

INSERT INTO #test1_defaults (col1, col3) VALUES (100, 300);
go

INSERT INTO #test1_defaults (col2, col4) VALUES (200, 400);
go

SELECT * FROM #test1_defaults ORDER BY col1;
go

INSERT INTO #test1_defaults (col1) VALUES (5), (6), (7);
go

SELECT * FROM #test1_defaults ORDER BY col1;
go

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
go

ALTER TABLE #test1_defaults ADD DEFAULT NULL FOR col2;
go

INSERT INTO #test1_defaults (col1) VALUES (2);
go

SELECT * FROM #test1_defaults WHERE col1 = 2;
go

INSERT INTO #test1_defaults (col1, col2) VALUES (3, 3);
go

SELECT * FROM #test1_defaults ORDER BY col1;
go

SELECT * FROM #test1_defaults WHERE col2 IS NULL;
go

SELECT * FROM #test1_defaults WHERE col2 = 20;
go

SELECT COUNT(*) AS total_rows FROM #test1_defaults;
go

SELECT col1, col2, col3, col4 FROM #test1_defaults ORDER BY col1 DESC;
go

SELECT 
    SUM(col1) AS sum_col1, 
    AVG(col2) AS avg_col2, 
    MIN(col3) AS min_col3, 
    MAX(col4) AS max_col4 
FROM #test1_defaults;
go

UPDATE #test1_defaults SET col2 = 999 WHERE col1 = 1;
go

SELECT * FROM #test1_defaults WHERE col1 = 1;
go

UPDATE #test1_defaults SET col3 = col3 + 1000 WHERE col2 IS NOT NULL;
go

SELECT * FROM #test1_defaults ORDER BY col1;
go

UPDATE #test1_defaults SET col4 = NULL WHERE col1 = 5;
go

SELECT * FROM #test1_defaults WHERE col1 = 5;
go

DELETE FROM #test1_defaults WHERE col1 = 6;
go

SELECT COUNT(*) AS rows_after_delete FROM #test1_defaults;
go

DELETE FROM #test1_defaults WHERE col2 IS NULL;
go

SELECT * FROM #test1_defaults ORDER BY col1;
go

INSERT INTO #test1_defaults (col1) VALUES (1000);
go

INSERT INTO #test1_defaults DEFAULT VALUES;
go

SELECT * FROM #test1_defaults ORDER BY col1;
go

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
go

ALTER TABLE #test1_defaults ADD DEFAULT 999 FOR col3;
go

INSERT INTO #test1_defaults (col1, col2) VALUES (2000, 2000);
go

SELECT * FROM #test1_defaults WHERE col1 = 2000;
go

SELECT * FROM #test1_defaults ORDER BY col1;
go

SELECT COUNT(*) AS final_count FROM #test1_defaults;
go

DROP TABLE #test1_defaults;
go

---------------------------------------------------------------------------
-- ALTER TABLE ADD COLUMN with INDEX operations in transaction (cache lookup fix)
---------------------------------------------------------------------------
CREATE TABLE #t_alter_idx(id int, name varchar(100))
GO

INSERT INTO #t_alter_idx (id, name) VALUES (1, 'test1')
GO

-- ALTER TABLE ADD COLUMN + multiple CREATE INDEX + SELECT in transaction
BEGIN TRANSACTION
    ALTER TABLE #t_alter_idx ADD col_def int DEFAULT 4
    UPDATE #t_alter_idx SET name = 'updated' WHERE id IS NOT NULL
    SELECT * FROM #t_alter_idx
    CREATE INDEX idx_alter1 ON #t_alter_idx (id)
    CREATE INDEX idx_alter2 ON #t_alter_idx (id)
COMMIT TRANSACTION
GO

SELECT * FROM #t_alter_idx
GO

SELECT * FROM enr_view ORDER BY relname
GO

-- TRUNCATE after index creation should work
TRUNCATE TABLE #t_alter_idx
GO

SELECT * FROM #t_alter_idx
GO

DROP TABLE #t_alter_idx
GO

SELECT * FROM enr_view ORDER BY relname
GO

---------------------------------------------------------------------------
-- ALTER TABLE ADD COLUMN + INDEX + TRUNCATE with ROLLBACK
---------------------------------------------------------------------------
CREATE TABLE #t_alter_idx_rollback(id int, name varchar(100))
GO

INSERT INTO #t_alter_idx_rollback (id, name) VALUES (1, 'original')
GO

BEGIN TRANSACTION
    ALTER TABLE #t_alter_idx_rollback ADD new_col int DEFAULT 10
    CREATE INDEX idx_rb1 ON #t_alter_idx_rollback (id)
    CREATE INDEX idx_rb2 ON #t_alter_idx_rollback (name)
    UPDATE #t_alter_idx_rollback SET name = 'modified'
    SELECT * FROM #t_alter_idx_rollback
ROLLBACK
GO

-- Should have original data, no new column, no indexes
SELECT * FROM #t_alter_idx_rollback
GO

SELECT * FROM enr_view ORDER BY relname
GO

-- Operations should work after rollback
INSERT INTO #t_alter_idx_rollback VALUES (2, 'second')
GO

SELECT * FROM #t_alter_idx_rollback ORDER BY id
GO

DROP TABLE #t_alter_idx_rollback
GO

---------------------------------------------------------------------------
-- Multiple ALTER TABLE + INDEX operations in single transaction
---------------------------------------------------------------------------
CREATE TABLE #t_multi_alter(a int, b int)
GO

INSERT INTO #t_multi_alter VALUES (1, 10), (2, 20)
GO

BEGIN TRANSACTION
    ALTER TABLE #t_multi_alter ADD c int DEFAULT 100
    ALTER TABLE #t_multi_alter ADD d varchar(50) DEFAULT 'default'
    CREATE INDEX idx_ma1 ON #t_multi_alter (a)
    CREATE INDEX idx_ma2 ON #t_multi_alter (b)
    CREATE INDEX idx_ma3 ON #t_multi_alter (c)
    INSERT INTO #t_multi_alter VALUES (3, 30, 300, 'inserted')
    SELECT * FROM #t_multi_alter ORDER BY a
COMMIT
GO

SELECT * FROM #t_multi_alter ORDER BY a
GO

SELECT * FROM enr_view ORDER BY relname
GO

-- TRUNCATE should work with all the indexes
TRUNCATE TABLE #t_multi_alter
GO

SELECT * FROM #t_multi_alter
GO

-- Insert after truncate should work
INSERT INTO #t_multi_alter VALUES (5, 50, 500, 'after_truncate')
GO

SELECT * FROM #t_multi_alter
GO

DROP TABLE #t_multi_alter
GO

---------------------------------------------------------------------------
-- ALTER TABLE + INDEX + DML operations with implicit rollback
---------------------------------------------------------------------------
SET XACT_ABORT ON
GO

CREATE TABLE #t_xact_abort(id int PRIMARY KEY, val varchar(50))
GO

INSERT INTO #t_xact_abort VALUES (1, 'one')
GO

-- This should cause implicit rollback due to duplicate key
BEGIN TRANSACTION
    ALTER TABLE #t_xact_abort ADD extra_col int DEFAULT 5
    CREATE INDEX idx_xa1 ON #t_xact_abort (val)
    INSERT INTO #t_xact_abort (id, val, extra_col) VALUES (2, 'two', 10)
    INSERT INTO #t_xact_abort (id, val, extra_col) VALUES (1, 'duplicate', 20) -- Should fail - duplicate key
COMMIT
GO

-- Table should be in original state (only the first row with default extra_col)
SELECT * FROM #t_xact_abort
GO

SELECT * FROM enr_view ORDER BY relname
GO

SET XACT_ABORT OFF
GO

DROP TABLE #t_xact_abort
GO

---------------------------------------------------------------------------
-- ALTER TABLE ADD COLUMN + INDEX + TRUNCATE in nested transactions
---------------------------------------------------------------------------
CREATE TABLE #t_nested_alter(x int, y int)
GO

INSERT INTO #t_nested_alter VALUES (1, 100)
GO

BEGIN TRAN
    ALTER TABLE #t_nested_alter ADD z int DEFAULT 999
    CREATE INDEX idx_nested1 ON #t_nested_alter (x)
    
    SAVE TRANSACTION sp1
    
    CREATE INDEX idx_nested2 ON #t_nested_alter (y)
    INSERT INTO #t_nested_alter VALUES (2, 200, 2000)
    SELECT * FROM #t_nested_alter ORDER BY x
    
    ROLLBACK TRANSACTION sp1
    
    SELECT * FROM #t_nested_alter ORDER BY x
    INSERT INTO #t_nested_alter VALUES (3, 300, 3000)
COMMIT
GO

SELECT * FROM #t_nested_alter ORDER BY x
GO

SELECT * FROM enr_view ORDER BY relname
GO

TRUNCATE TABLE #t_nested_alter
GO

SELECT * FROM #t_nested_alter
GO

DROP TABLE #t_nested_alter
GO

---------------------------------------------------------------------------
-- Repeated ALTER + INDEX + TRUNCATE cycles
---------------------------------------------------------------------------
CREATE TABLE #t_cycle(id int)
GO

-- Cycle 1
BEGIN TRANSACTION
    ALTER TABLE #t_cycle ADD col1 int DEFAULT 1
    CREATE INDEX idx_cyc1 ON #t_cycle (id)
    INSERT INTO #t_cycle VALUES (1, 10)
COMMIT
GO

SELECT * FROM #t_cycle
GO

TRUNCATE TABLE #t_cycle
GO

-- Cycle 2
BEGIN TRANSACTION
    ALTER TABLE #t_cycle ADD col2 int DEFAULT 2
    CREATE INDEX idx_cyc2 ON #t_cycle (col1)
    INSERT INTO #t_cycle VALUES (2, 20, 200)
COMMIT
GO

SELECT * FROM #t_cycle
GO

TRUNCATE TABLE #t_cycle
GO

-- Cycle 3
BEGIN TRANSACTION
    ALTER TABLE #t_cycle ADD col3 int DEFAULT 3
    CREATE INDEX idx_cyc3 ON #t_cycle (col2)
    INSERT INTO #t_cycle VALUES (3, 30, 300, 3000)
COMMIT
GO

SELECT * FROM #t_cycle
GO

SELECT * FROM enr_view ORDER BY relname
GO

DROP TABLE #t_cycle
GO

SELECT * FROM enr_view ORDER BY relname
GO

---------------------------------------------------------------------------
-- ALTER TABLE with collation + INDEX + TRUNCATE
---------------------------------------------------------------------------
CREATE TABLE #t_collation(id int, name varchar(100) COLLATE Latin1_General_CI_AS)
GO

INSERT INTO #t_collation VALUES (1, 'TestName')
GO

BEGIN TRANSACTION
    ALTER TABLE #t_collation ADD extra int DEFAULT 42
    UPDATE #t_collation SET name = 'UpdatedName' WHERE id IS NOT NULL
    SELECT * FROM #t_collation
    CREATE INDEX idx_coll1 ON #t_collation (id)
    CREATE INDEX idx_coll2 ON #t_collation (name)
COMMIT TRANSACTION
GO

SELECT * FROM #t_collation
GO

TRUNCATE TABLE #t_collation
GO

INSERT INTO #t_collation VALUES (2, 'AfterTruncate', 100)
GO

SELECT * FROM #t_collation
GO

DROP TABLE #t_collation
GO

SELECT * FROM enr_view ORDER BY relname
GO


---------------------------------------------------------------------------
-- PROCEDURE: Test ALTER TABLE + INDEX + TRUNCATE (cache lookup fix)
---------------------------------------------------------------------------
EXEC test_alter_index_truncate_cache_fix
GO

SELECT * FROM enr_view ORDER BY relname
GO

---------------------------------------------------------------------------
-- Cross-QueryEnv ENR Tests - Procedure Drop Table Fix (BABEL-6268)
---------------------------------------------------------------------------

-- Test 1: Basic procedure drop table scenario
CREATE TABLE #test(a int) 
GO

EXEC p_drop
GO

CREATE TABLE #test(a int)         -- should not crash
GO

DROP TABLE #test
GO

-- Test 2: Multiple procedure calls with same temp table name
CREATE TABLE #temp_proc_test(id int, name varchar(50)) 
INSERT INTO #temp_proc_test VALUES (1, 'test1') 
GO

EXEC p_drop_multi
GO

CREATE TABLE #temp_proc_test(id int, data varchar(100)) 
INSERT INTO #temp_proc_test VALUES (2, 'test2') 
SELECT * FROM #temp_proc_test 
GO

DROP TABLE #temp_proc_test
GO

-- Test 3: Nested procedure calls
CREATE TABLE #nested_test(val int)
INSERT INTO #nested_test VALUES (100)
GO

EXEC p_outer
GO

CREATE TABLE #nested_test(val int, descr varchar(20)) 
INSERT INTO #nested_test VALUES (200, 'after fix') 
SELECT * FROM #nested_test 
GO

DROP TABLE #nested_test
GO

-- Test 4: Procedure with transaction and temp table drop
CREATE TABLE #trans_test(a int, b varchar(10)) 
INSERT INTO #trans_test VALUES (1, 'before') 
GO

EXEC p_trans_drop
GO

CREATE TABLE #trans_test(c int) 
INSERT INTO #trans_test VALUES (999)  
SELECT * FROM #trans_test  
GO

DROP TABLE #trans_test
GO

-- Test 5: Execute CREATE and INSERT operations
EXEC p_create_insert
GO

-- Test 6: Execute UPDATE and DELETE operations
CREATE TABLE #update_delete_test(id int, status varchar(20), value int)
INSERT INTO #update_delete_test VALUES (1, 'active', 100)
INSERT INTO #update_delete_test VALUES (2, 'inactive', 200)
INSERT INTO #update_delete_test VALUES (3, 'pending', 300)
GO

EXEC p_update_delete
GO

SELECT * FROM #update_delete_test
GO

DROP TABLE #update_delete_test
GO

-- Test 7: Execute nested procedures with mixed operations
CREATE TABLE #nested_ops_test(id int, data varchar(50))
INSERT INTO #nested_ops_test VALUES (1, 'initial')
GO

EXEC p_nested_outer
GO

SELECT * FROM #nested_ops_test
GO

DROP TABLE #nested_ops_test
GO

-- Test 8: Execute transaction rollback and operations
CREATE TABLE #rollback_ops_test(id int, amount decimal(10,2))
INSERT INTO #rollback_ops_test VALUES (1, 100.00)
GO

EXEC p_rollback_ops
GO

SELECT * FROM #rollback_ops_test
GO

DROP TABLE #rollback_ops_test
GO

-- Test 9: Execute multiple temp tables with cross-operations
EXEC p_multi_temp_ops
GO

-- Test 10: Execute error handling and operations
CREATE TABLE #error_ops_test(id int primary key, data varchar(20))
INSERT INTO #error_ops_test VALUES (1, 'original')
GO

EXEC p_error_ops
GO

SELECT * FROM #error_ops_test
GO

DROP TABLE #error_ops_test
GO

-- Test 11: Execute TRUNCATE operation
CREATE TABLE #truncate_test(id int identity(1,1), data varchar(20))
INSERT INTO #truncate_test VALUES ('first')
INSERT INTO #truncate_test VALUES ('second')
INSERT INTO #truncate_test VALUES ('third')
GO

EXEC p_truncate_ops
GO

SELECT * FROM #truncate_test
GO

DROP TABLE #truncate_test
GO

-- Test 12: Execute conditional operations
CREATE TABLE #conditional_test(id int, status varchar(10), value int)
INSERT INTO #conditional_test VALUES (1, 'active', 50)
INSERT INTO #conditional_test VALUES (2, 'inactive', 150)
INSERT INTO #conditional_test VALUES (3, 'pending', 75)
GO

EXEC p_conditional_ops
GO

SELECT * FROM #conditional_test
GO

DROP TABLE #conditional_test
GO

-- INSERT INTO EXEC Tests
-- Test 13: Basic INSERT INTO EXEC with temp table
CREATE TABLE #insert_exec_target(id int, name varchar(30))
GO

INSERT INTO #insert_exec_target EXEC p_insert_exec_basic
GO

SELECT * FROM #insert_exec_target
GO

DROP TABLE #insert_exec_target
GO

-- Test 14: INSERT INTO EXEC with nested procedure calls
CREATE TABLE #insert_exec_nested(id int, data varchar(50))
GO

INSERT INTO #insert_exec_nested EXEC p_insert_exec_nested_outer
GO

SELECT * FROM #insert_exec_nested
GO

DROP TABLE #insert_exec_nested
GO

-- Test 15: INSERT INTO EXEC with temp table operations inside procedure
CREATE TABLE #insert_exec_ops(id int, status varchar(20), value int)
GO

INSERT INTO #insert_exec_ops EXEC p_insert_exec_temp_ops
GO

SELECT * FROM #insert_exec_ops
GO

DROP TABLE #insert_exec_ops
GO

-- Test 16: INSERT INTO EXEC with transaction and rollback
CREATE TABLE #insert_exec_trans(id int, amount decimal(10,2))
GO

INSERT INTO #insert_exec_trans EXEC p_insert_exec_transaction
GO

SELECT * FROM #insert_exec_trans
GO

DROP TABLE #insert_exec_trans
GO

-- Test 17: INSERT INTO EXEC with multiple result sets (only first is inserted)
CREATE TABLE #insert_exec_multi(id int, info varchar(30))
GO

INSERT INTO #insert_exec_multi EXEC p_insert_exec_multi_results
GO

SELECT * FROM #insert_exec_multi
GO

DROP TABLE #insert_exec_multi
GO

-- Test 18: INSERT INTO EXEC with error handling
CREATE TABLE #insert_exec_error(id int, data varchar(20))
GO

INSERT INTO #insert_exec_error EXEC p_insert_exec_error_handling
GO

SELECT * FROM #insert_exec_error
GO

DROP TABLE #insert_exec_error
GO

-- Test 19: INSERT INTO EXEC with table variable in procedure
CREATE TABLE #insert_exec_tv(id int, tv_data varchar(30))
GO

INSERT INTO #insert_exec_tv EXEC p_insert_exec_table_var
GO

SELECT * FROM #insert_exec_tv
GO

DROP TABLE #insert_exec_tv
GO

-- Test 20: INSERT INTO EXEC where procedure attempts to drop the target table
CREATE TABLE #insert_exec_drop_target(id int, data varchar(30))
INSERT INTO #insert_exec_drop_target VALUES (1, 'initial data')
GO

-- Should fail
INSERT INTO #insert_exec_drop_target EXEC p_insert_exec_drop_table
GO

-- Table should still exist with original data since DROP failed
SELECT * FROM #insert_exec_drop_target
GO

DROP TABLE #insert_exec_drop_target
GO

DROP TABLE #t
DROP TABLE #t1
DROP TABLE #t2
GO

---------------------------------------------------------------------------
-- DROP TABLE IF EXISTS + CREATE TABLE in procedures (BABEL-6097)
---------------------------------------------------------------------------

-- Basic DROP IF EXISTS + CREATE pattern
CREATE TABLE #t(a int)
GO

EXEC p_drop_if_exists_create
GO

CREATE TABLE #t(a int)  -- Should not crash
GO

DROP TABLE #t
GO

-- Multiple DROP IF EXISTS + CREATE cycles
CREATE TABLE #t(x varchar(10))
INSERT INTO #t VALUES ('original')
GO

EXEC p_multi_drop_create
GO

CREATE TABLE #t(c int)
INSERT INTO #t VALUES (999)
SELECT * FROM #t
GO

DROP TABLE #t
GO

-- DROP IF EXISTS + CREATE with different schemas
EXEC p_drop_create_schema_change
GO

CREATE TABLE #t(final_col int)
INSERT INTO #t VALUES (777)
SELECT * FROM #t
GO

DROP TABLE #t
GO

-- DROP IF EXISTS + CREATE in transaction
EXEC p_trans_drop_create
GO

-- DROP IF EXISTS + CREATE with rollback
EXEC p_rollback_drop_create
GO

-- Multiple temp tables with DROP IF EXISTS + CREATE
EXEC p_multi_tables_drop_create
GO

-- DROP IF EXISTS + CREATE with indexes
EXEC p_drop_create_with_index
GO

-- DROP IF EXISTS + CREATE with constraints
EXEC p_drop_create_constraints
GO

-- DROP IF EXISTS + CREATE with ALTER TABLE
EXEC p_drop_create_alter
GO

-- Conditional DROP IF EXISTS + CREATE
EXEC p_conditional_drop_create
GO

-- DROP IF EXISTS + CREATE with TRUNCATE
EXEC p_drop_create_truncate
GO

-- Error handling with DROP IF EXISTS + CREATE
EXEC p_error_drop_create
GO

-- Repeated calls to same procedure
CREATE TABLE #t(a int)
GO

EXEC p_drop_if_exists_create
GO

EXEC p_drop_if_exists_create  -- Second call
GO

EXEC p_drop_if_exists_create  -- Third call
GO

CREATE TABLE #t(final int)  -- Should not crash
GO

DROP TABLE #t
GO

-- Interleaved procedure calls
CREATE TABLE #t(a int)
CREATE TABLE #t1(a int)
GO

EXEC p_drop_if_exists_create
GO

EXEC p_multi_tables_drop_create
GO

CREATE TABLE #t(x int)
CREATE TABLE #t1(y int)
GO

DROP TABLE #t
DROP TABLE #t1
GO