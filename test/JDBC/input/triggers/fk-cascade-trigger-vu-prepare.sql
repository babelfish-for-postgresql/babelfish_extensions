-- TEST 1: Basic CASCADE DELETE
CREATE TABLE babel7022_parent (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_history (id int, parent_id int)
GO

-- One row is inserted here per trigger firing, so its row count == number of firings
CREATE TABLE babel7022_fire_count (rows_seen int)
GO

CREATE TRIGGER babel7022_child_del_trg
  ON babel7022_child
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_fire_count (rows_seen) SELECT COUNT(*) FROM deleted;
  INSERT INTO babel7022_history (id, parent_id)
    SELECT id, parent_id FROM deleted;
END
GO

-- TEST 2: Single parent, multiple children
CREATE TABLE babel7022_parent2 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child2 (
  id int IDENTITY(1,1) PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent2(id) ON DELETE CASCADE,
  val varchar(20)
)
GO

CREATE TABLE babel7022_history2 (child_id int, parent_id int, val varchar(20))
GO

CREATE TRIGGER babel7022_child2_del_trg
  ON babel7022_child2
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_history2 (child_id, parent_id, val)
    SELECT id, parent_id, val FROM deleted;
END
GO

-- TEST 3: CASCADE UPDATE
CREATE TABLE babel7022_parent3 (id int PRIMARY KEY, name varchar(50))
GO

CREATE TABLE babel7022_child3 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent3(id) ON UPDATE CASCADE,
  data varchar(50)
)
GO

CREATE TABLE babel7022_update_log (child_id int, old_parent_id int, new_parent_id int)
GO

CREATE TRIGGER babel7022_child3_upd_trg
  ON babel7022_child3
  AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_update_log (child_id, old_parent_id, new_parent_id)
    SELECT d.id, d.parent_id, i.parent_id
    FROM deleted d JOIN inserted i ON d.id = i.id;
END
GO

-- TEST 4: Multiple triggers on same table
CREATE TABLE babel7022_parent4 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child4 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent4(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_audit4a (cnt int)
GO

CREATE TABLE babel7022_audit4b (cnt int)
GO

CREATE TRIGGER babel7022_child4_del_trg_a
  ON babel7022_child4
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_audit4a (cnt) SELECT COUNT(*) FROM deleted;
END
GO

CREATE TRIGGER babel7022_child4_del_trg_b
  ON babel7022_child4
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_audit4b (cnt) SELECT COUNT(*) FROM deleted;
END
GO

-- TEST 5: Nested CASCADE (grandparent -> parent -> child)
CREATE TABLE babel7022_gp (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_p (
  id int PRIMARY KEY,
  gp_id int NOT NULL REFERENCES babel7022_gp(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_c (
  id int PRIMARY KEY,
  p_id int NOT NULL REFERENCES babel7022_p(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_gp_log (tbl varchar(10), del_count int)
GO

CREATE TRIGGER babel7022_p_del_trg
  ON babel7022_p
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_gp_log (tbl, del_count) SELECT 'parent', COUNT(*) FROM deleted;
END
GO

CREATE TRIGGER babel7022_c_del_trg
  ON babel7022_c
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_gp_log (tbl, del_count) SELECT 'child', COUNT(*) FROM deleted;
END
GO

-- TEST 6: Direct DELETE (non-CASCADE) - regression test
CREATE TABLE babel7022_standalone (id int PRIMARY KEY, val varchar(50))
GO

CREATE TABLE babel7022_standalone_log (id int, val varchar(50))
GO

CREATE TRIGGER babel7022_standalone_del_trg
  ON babel7022_standalone
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_standalone_log (id, val)
    SELECT id, val FROM deleted;
END
GO

-- TEST 7: INSERT trigger unaffected by CASCADE DELETE
CREATE TABLE babel7022_parent7 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child7 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent7(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_ins_log (id int, parent_id int)
GO

CREATE TRIGGER babel7022_child7_ins_trg
  ON babel7022_child7
  AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_ins_log (id, parent_id)
    SELECT id, parent_id FROM inserted;
END
GO

-- TEST 8: Non-cascade UPDATE trigger - regression test
CREATE TABLE babel7022_t8 (id int PRIMARY KEY, val int)
GO

CREATE TABLE babel7022_t8_log (id int, old_val int, new_val int)
GO

CREATE TRIGGER babel7022_t8_upd_trg
  ON babel7022_t8
  AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_t8_log (id, old_val, new_val)
    SELECT d.id, d.val, i.val FROM deleted d JOIN inserted i ON d.id = i.id;
END
GO

-- TEST 9: CASCADE DELETE with no matching children
CREATE TABLE babel7022_parent9 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child9 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent9(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_log9 (cnt int)
GO

CREATE TRIGGER babel7022_child9_del_trg
  ON babel7022_child9
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_log9 (cnt) SELECT COUNT(*) FROM deleted;
END
GO

-- TEST 10: CASCADE DELETE inside explicit transaction
CREATE TABLE babel7022_parent10 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child10 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent10(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_log10 (id int, parent_id int)
GO

CREATE TRIGGER babel7022_child10_del_trg
  ON babel7022_child10
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_log10 (id, parent_id)
    SELECT id, parent_id FROM deleted;
END
GO

-- TEST 11: Individual DELETEs - trigger fires independently per statement
CREATE TABLE babel7022_parent11 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child11 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent11(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_log11 (firing_num int IDENTITY(1,1), del_count int)
GO

CREATE TRIGGER babel7022_child11_del_trg
  ON babel7022_child11
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_log11 (del_count) SELECT COUNT(*) FROM deleted;
END
GO

-- TEST 12: CASCADE DELETE with rollback / savepoint scenarios
CREATE TABLE babel7022_parent12 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child12 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent12(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_log12 (id int, parent_id int)
GO

CREATE TRIGGER babel7022_child12_del_trg
  ON babel7022_child12
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_log12 (id, parent_id)
    SELECT id, parent_id FROM deleted;
END
GO

-- TEST 13: Transaction commands inside the trigger body during CASCADE (BABEL-1416)

-- 13a: trigger body with SAVE TRANSACTION
CREATE TABLE babel7022_parent13a (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child13a (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent13a(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_history13a (id int, parent_id int)
GO

CREATE TRIGGER babel7022_child13a_del_trg
  ON babel7022_child13a
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  SAVE TRANSACTION trg_sp;
  INSERT INTO babel7022_history13a (id, parent_id) SELECT id, parent_id FROM deleted;
END
GO

-- 13b: trigger body inserts a marker, saves, inserts, then rolls back to savepoint
CREATE TABLE babel7022_parent13b (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child13b (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent13b(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_history13b (id int, parent_id int)
GO

CREATE TRIGGER babel7022_child13b_del_trg
  ON babel7022_child13b
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_history13b (id, parent_id) SELECT id, -1 FROM deleted;
  SAVE TRANSACTION trg_sp;
  INSERT INTO babel7022_history13b (id, parent_id) SELECT id, parent_id FROM deleted;
  ROLLBACK TRANSACTION trg_sp;
END
GO

-- 13c: trigger body with BEGIN TRANSACTION / COMMIT
CREATE TABLE babel7022_parent13c (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child13c (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent13c(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_history13c (id int, parent_id int)
GO

CREATE TRIGGER babel7022_child13c_del_trg
  ON babel7022_child13c
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;
  INSERT INTO babel7022_history13c (id, parent_id) SELECT id, parent_id FROM deleted;
  COMMIT TRANSACTION;
END
GO

-- 13d: trigger body with full ROLLBACK (aborts the batch)
CREATE TABLE babel7022_parent13d (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child13d (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent13d(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_history13d (id int, parent_id int)
GO

CREATE TRIGGER babel7022_child13d_del_trg
  ON babel7022_child13d
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_history13d (id, parent_id) SELECT id, parent_id FROM deleted;
  ROLLBACK TRANSACTION;
END
GO


-- TEST 14: Multi-row INSERT without cascade - statement trigger fires once
CREATE TABLE babel7022_t14 (id int PRIMARY KEY, val int)
GO

CREATE TABLE babel7022_fire14 (rows_seen int)
GO

CREATE TRIGGER babel7022_t14_ins_trg
  ON babel7022_t14
  AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_fire14 (rows_seen) SELECT COUNT(*) FROM inserted;
END
GO

-- TEST 15: Multi-row UPDATE without cascade - statement trigger fires once
CREATE TABLE babel7022_t15 (id int PRIMARY KEY, val int)
GO

CREATE TABLE babel7022_fire15 (rows_seen int)
GO

CREATE TRIGGER babel7022_t15_upd_trg
  ON babel7022_t15
  AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_fire15 (rows_seen) SELECT COUNT(*) FROM inserted;
END
GO

-- TEST 16: Multi-row DELETE without cascade - statement trigger fires once
CREATE TABLE babel7022_t16 (id int PRIMARY KEY, val int)
GO

CREATE TABLE babel7022_fire16 (rows_seen int)
GO

CREATE TRIGGER babel7022_t16_del_trg
  ON babel7022_t16
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_fire16 (rows_seen) SELECT COUNT(*) FROM deleted;
END
GO

-- TEST 17: Chained triggers - CASCADE delete trigger writes to an audit table
-- that has its own AFTER INSERT trigger; each trigger fires once
CREATE TABLE babel7022_parent17 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child17 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent17(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_audit17 (id int, parent_id int)
GO

CREATE TABLE babel7022_audit17_fire (rows_seen int)
GO

CREATE TRIGGER babel7022_child17_del_trg
  ON babel7022_child17
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_audit17 (id, parent_id) SELECT id, parent_id FROM deleted;
END
GO

CREATE TRIGGER babel7022_audit17_ins_trg
  ON babel7022_audit17
  AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_audit17_fire (rows_seen) SELECT COUNT(*) FROM inserted;
END
GO

-- TEST 18: ON DELETE SET NULL - parent delete cascades as UPDATE on children, trigger fires once
CREATE TABLE babel7022_parent18 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child18 (
  id int PRIMARY KEY,
  parent_id int NULL REFERENCES babel7022_parent18(id) ON DELETE SET NULL
)
GO

CREATE TABLE babel7022_fire18 (rows_seen int)
GO

CREATE TRIGGER babel7022_child18_upd_trg
  ON babel7022_child18
  AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_fire18 (rows_seen) SELECT COUNT(*) FROM inserted;
END
GO

-- TEST 19: ON DELETE SET DEFAULT - parent delete cascades as UPDATE setting FK to default, trigger fires once
CREATE TABLE babel7022_parent19 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child19 (
  id int PRIMARY KEY,
  parent_id int NOT NULL DEFAULT 99 REFERENCES babel7022_parent19(id) ON DELETE SET DEFAULT
)
GO

CREATE TABLE babel7022_fire19 (rows_seen int)
GO

CREATE TRIGGER babel7022_child19_upd_trg
  ON babel7022_child19
  AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_fire19 (rows_seen) SELECT COUNT(*) FROM inserted;
END
GO

-- TEST 20: THROW (batch-terminating) inside trigger during CASCADE - operation rolls back
CREATE TABLE babel7022_parent20 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child20 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent20(id) ON DELETE CASCADE
)
GO

CREATE TRIGGER babel7022_child20_del_trg
  ON babel7022_child20
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  THROW 51000, 'batch terminating error from trigger', 1;
END
GO

-- TEST 21: TRY/CATCH around a CASCADE whose trigger errors - error is caught, batch continues
CREATE TABLE babel7022_parent21 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child21 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent21(id) ON DELETE CASCADE
)
GO

CREATE TRIGGER babel7022_child21_del_trg
  ON babel7022_child21
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  THROW 51001, 'error caught by outer try/catch', 1;
END
GO

-- TEST 22: recovery after error - a poison CASCADE that aborts, then a good CASCADE that still fires once
CREATE TABLE babel7022_parent22p (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child22p (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent22p(id) ON DELETE CASCADE
)
GO

CREATE TRIGGER babel7022_child22p_del_trg
  ON babel7022_child22p
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  THROW 51002, 'poison trigger', 1;
END
GO

CREATE TABLE babel7022_parent22g (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child22g (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent22g(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_fire22g (rows_seen int)
GO

CREATE TRIGGER babel7022_child22g_del_trg
  ON babel7022_child22g
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_fire22g (rows_seen) SELECT COUNT(*) FROM deleted;
END
GO

-- TEST 23: runtime DML error (PK violation) inside trigger during CASCADE - operation rolls back
CREATE TABLE babel7022_parent23 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child23 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent23(id) ON DELETE CASCADE
)
GO

CREATE TABLE babel7022_audit23 (k int CONSTRAINT babel7022_audit23_pk PRIMARY KEY)
GO

CREATE TRIGGER babel7022_child23_del_trg
  ON babel7022_child23
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO babel7022_audit23 (k) VALUES (99);
END
GO

-- TEST 24: TRY/CATCH inside the trigger body - catching an error dooms the transaction,
-- so on trigger completion the batch is aborted and the operation rolled back
-- (Msg 3616, matches SQL Server)
CREATE TABLE babel7022_parent24 (id int PRIMARY KEY)
GO

CREATE TABLE babel7022_child24 (
  id int PRIMARY KEY,
  parent_id int NOT NULL REFERENCES babel7022_parent24(id) ON DELETE CASCADE
)
GO

CREATE TRIGGER babel7022_child24_del_trg
  ON babel7022_child24
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    DECLARE @x int = 1 / 0;
  END TRY
  BEGIN CATCH
    DECLARE @e int = ERROR_NUMBER();
  END CATCH
END
GO
