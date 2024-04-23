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
-- ALTER TABLE (should fail due to BABEL-4912)
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
ALTER TABLE #temp_table_rollback_t1 DROP COLUMN b
COMMIT
GO

BEGIN TRAN
ALTER TABLE #temp_table_rollback_t1 ALTER COLUMN b VARCHAR
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
insert into #temp_table_rollback_t1 values (1, 1, 1) -- Wrong should error out 
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

----------------------------------------------------------
-- Savepoint CREATE and DROP
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
GO
