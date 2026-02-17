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