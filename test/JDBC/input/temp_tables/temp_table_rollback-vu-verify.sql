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

CREATE FUNCTION #fn_get_sum(@max_a int)
RETURNS int
AS
BEGIN
    DECLARE @result int;
    SELECT @result = SUM(c) FROM #t_func_idx WHERE a <= @max_a;
    RETURN @result;
END
GO

SELECT #fn_get_sum(3) AS sum_before;
GO

DROP INDEX #idx_f2 ON #t_func_idx;
GO

SELECT relname FROM sys.babelfish_get_enr_list() ORDER BY relname;
GO

SELECT #fn_get_sum(3) AS sum_after;
GO

INSERT INTO #t_func_idx VALUES (4, 40, 400);
GO

SELECT #fn_get_sum(4) AS sum_final;
GO

SELECT * FROM #t_func_idx ORDER BY a;
GO

DROP FUNCTION #fn_get_sum;
GO

DROP TABLE #t_func_idx;
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